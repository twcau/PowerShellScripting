<#
.SYNOPSIS
    Isolated pre-provisioning membership transition regression tests.
.DESCRIPTION
    Extracts only required functions without starting the CLI. Graph and pauses
    are mocked; no tenant or operational records are modified. Requires Pester 5.
#>

BeforeAll {
    $sourcePath = Join-Path (Split-Path -Parent $PSScriptRoot) 'autopilot-express.ps1'
    $tokens = $null
    $parseErrors = $null
    $sourceAst = [System.Management.Automation.Language.Parser]::ParseFile($sourcePath, [ref]$tokens, [ref]$parseErrors)
    if ($parseErrors.Count) { throw ($parseErrors.Message -join '; ') }
    foreach ($functionName in @('Get-GraphTransportFailure', 'Get-GraphOperationFailureMessage', 'New-OperationResult', 'Get-GraphVerificationPolicy', 'Test-AssignedSecurityGroup', 'Wait-GroupMembershipVerification', 'Invoke-PreProvisioningMembershipChange', 'Invoke-StepAddPreProvisioningGroup', 'Invoke-StepRemovePreProvisioningGroup', 'Clear-PreProvisioningGroupCache')) {
        $definition = $sourceAst.Find({ param($node) $node -is [System.Management.Automation.Language.FunctionDefinitionAst] -and $node.Name -eq $functionName }, $true)
        if ($null -eq $definition) { throw ('Missing function: {0}' -f $functionName) }
        Set-Item -Path ('Function:{0}' -f $definition.Name) -Value $definition.Body.GetScriptBlock()
    }
    function Get-ConfiguredPreProvisioningGroupDisplayName { return 'Test pre-provisioning' }
    function Get-LivePreProvisioningGroup { throw 'Unexpected group lookup.' }
    function Get-LivePreProvisioningConflictGroup { param($DirectoryObjectId, $TargetGroup) throw ('Unexpected conflicts: {0} {1}' -f $DirectoryObjectId, $TargetGroup.id) }
    function Read-ValidatedInput { param($Prompt, $Default, $Type, $Choices) throw ('Unexpected prompt: {0} {1} {2} {3}' -f $Prompt, $Default, $Type, $Choices) }
    function Resolve-LiveMembershipContext {
        param($Device)
        throw ('Unexpected context lookup for {0}.' -f $Device.Serial)
    }
    function Test-LiveGroupMembership {
        param([string]$GroupId, [string]$DirectoryObjectId)
        throw ('Unexpected membership read: {0}, {1}.' -f $GroupId, $DirectoryObjectId)
    }
    function Get-LivePreProvisioningMembershipState {
        param($DirectoryObjectId, $TargetGroup)
        return @{
            ObservedMember = Test-LiveGroupMembership -GroupId $TargetGroup.id -DirectoryObjectId $DirectoryObjectId
            ConflictGroups = Get-LivePreProvisioningConflictGroup -DirectoryObjectId $DirectoryObjectId -TargetGroup $TargetGroup
        }
    }
    function Invoke-GraphApiRequest {
        param([string]$Method, [string]$Uri, [hashtable]$Body)
        throw ('Unexpected Graph request: {0} {1}; body keys {2}.' -f $Method, $Uri, ($Body.Keys -join ','))
    }
}

Describe 'Membership SDK-boundary integration' {
    BeforeAll {
        foreach ($functionName in @('Get-GraphTransportPolicy', 'Initialize-GraphTransport', 'Invoke-GraphApiRequest', 'Get-GraphDiscoveryCollection', 'Get-LiveTenantBinding', 'Get-LiveAutopilotDeviceById', 'Resolve-LiveAutopilotTagContext', 'Resolve-LiveEntraDeviceObject', 'Resolve-LiveMembershipContext', 'Get-StoredEntraDeviceObject', 'Get-LivePreProvisioningGroup', 'Clear-PreProvisioningGroupCache', 'Get-PreProvisioningGroupLookupUri', 'Get-LivePreProvisioningConflictGroup', 'Get-LivePreProvisioningMembershipState', 'Test-LiveGroupMembership', 'Invoke-StepApplyGroupTag', 'Wait-AutopilotGroupTagVerification')) {
            $definition = $sourceAst.Find({ param($node) $node -is [System.Management.Automation.Language.FunctionDefinitionAst] -and $node.Name -eq $functionName }, $true)
            Set-Item -Path ('Function:{0}' -f $definition.Name) -Value $definition.Body.GetScriptBlock()
        }
        function Get-MgContext { throw 'Unexpected real context access.' }
        function Set-MgRequestContext {
            [CmdletBinding(SupportsShouldProcess)]
            param($MaxRetry, $ClientTimeout)
            if ($PSCmdlet.ShouldProcess('Offline fixture', 'Set')) { throw ('Unexpected transport setup: {0}/{1}' -f $MaxRetry, $ClientTimeout) }
        }
        function Invoke-MgGraphRequest {
            [CmdletBinding()]
            param($Method, $Uri, $Body, $ContentType)
            throw ('Unexpected real SDK access: {0}/{1}/{2}/{3}' -f $Method, $Uri, $Body, $ContentType)
        }
        function Write-AutopilotExpressLog { param($Message, $Level) throw ('Unexpected log: {0}/{1}' -f $Level, $Message) }
    }
    BeforeEach {
        $script:tenant = '11111111-1111-1111-1111-111111111111'
        $script:Runtime = @{ IsDemoMode = $false }
        $script:RuntimeConfig = @{ graph = @{ expectedTenantId = $script:tenant }; autopilot = @{ preProvisioningGroupPrefix = 'Test ' } }
        $script:GraphSession = @{ Connected = $true; IsSimulated = $false; TenantId = $script:tenant }
        $script:Config = @{ MaxRetryAttempts = 5; RetryBackoffSeconds = 3; TransportMaxAttempts = 3; TransportBackoffSeconds = 2; TransportMaxDelaySeconds = 60; TransportTimeoutSeconds = 60 }
        $script:wireDevice = @{ Serial = 'SERIAL1'; TenantId = $script:tenant; AutopilotDeviceId = 'auto-1'; ManagedDeviceId = 'retain-managed'; EntraDeviceId = 'stale-object'; Steps = @{}; SiteCode = 'SITE'; DeviceType = 'Desktop'; GroupTag = 'old-record' }
        $script:wireStep = @{ Id = 'D'; ActionName = 'AddToPreProvisioningGroup' }
        $script:wireGroup = @{ id = 'group-1'; displayName = 'Test pre-provisioning'; '@odata.type' = '#microsoft.graph.group'; securityEnabled = $true; mailEnabled = $false; groupTypes = @(); isAssignableToRole = $false }
        $script:wireMember = $false
        $script:wirePostAccepted = $false
        $script:wireTag = 'OLD'
        $script:wireTagPostAccepted = $false
        $script:wireDenyReadback = $false
        $script:wireCalls = [System.Collections.Generic.List[object]]::new()
        Mock Get-MgContext { return @{ TenantId = $script:tenant } }
        Mock Set-MgRequestContext {}
        Mock Write-AutopilotExpressLog {}
        Mock Start-Sleep { throw 'Unexpected foreground wait.' }
        Mock Read-ValidatedInput { throw 'Unexpected membership correction prompt.' }
        Mock Invoke-MgGraphRequest {
            $script:wireCalls.Add(@{ Method = [string]$Method; Uri = [string]$Uri; Body = $Body; ContentType = $ContentType })
            if ($Method -eq 'GET' -and $Uri -eq '/v1.0/deviceManagement/windowsAutopilotDeviceIdentities/auto-1') {
                return @{ id = 'auto-1'; serialNumber = 'SERIAL1'; azureActiveDirectoryDeviceId = 'registration-1'; groupTag = $script:wireTag }
            }
            if ($Method -eq 'GET' -and $Uri.StartsWith('/v1.0/devices?')) { return @{ value = @(@{ id = 'current-object'; deviceId = 'registration-1' }) } }
            if ($Method -eq 'GET' -and $Uri.StartsWith('/v1.0/groups?')) { return @{ value = @($script:wireGroup) } }
            if ($Method -eq 'GET' -and $Uri -eq '/v1.0/devices/current-object/memberOf') {
                if ($script:wireDenyReadback -and $script:wirePostAccepted) { throw [UnauthorizedAccessException]::new('Synthetic read-back denial.') }
                return @{ value = @(if ($script:wireMember) { $script:wireGroup }) }
            }
            if ($Method -eq 'GET' -and $Uri -eq '/v1.0/groups/group-1?$select=id') { return @{ id = 'group-1' } }
            if ($Method -eq 'POST' -and $Uri -eq '/v1.0/groups/group-1/members/$ref') { $script:wirePostAccepted = $true; return $null }
            if ($Method -eq 'POST' -and $Uri -eq '/v1.0/deviceManagement/windowsAutopilotDeviceIdentities/auto-1/updateDeviceProperties') { $script:wireTagPostAccepted = $true; return $null }
            throw ('Unexpected wire request: {0} {1}' -f $Method, $Uri)
        }
    }
    It 'submits the exact current object reference once and later verifies with two fresh GETs' {
        $pending = Invoke-StepAddPreProvisioningGroup -Device $script:wireDevice -StepDefinition $script:wireStep
        $pending.CompletionState | Should -Be Submitted
        $pending.Data.TargetSubmitted | Should -BeTrue
        # Six reads/writes: the successful POST itself confirms the change, so no extra membership read.
        $script:wireCalls.Count | Should -Be 6
        $write = @($script:wireCalls | Where-Object Method -eq POST)
        $write.Count | Should -Be 1
        ($write[0].Body | ConvertFrom-Json).'@odata.id' | Should -BeExactly 'https://graph.microsoft.com/v1.0/directoryObjects/current-object'
        $write[0].ContentType | Should -BeExactly 'application/json'
        $script:wireDevice.Steps.D = $pending
        $script:wireMember = $true
        $script:wireCalls.Clear()
        $verified = Invoke-StepAddPreProvisioningGroup -Device $script:wireDevice -StepDefinition $script:wireStep
        $verified.CompletionState | Should -Be Verified
        # Two fresh reads: the Autopilot record and the device's group memberships. The Entra
        # object ID is reused from the saved record (same registration) and the group from the
        # session's 15-minute group cache, which together previously cost two more reads.
        $script:wireCalls.Count | Should -Be 2
        @($script:wireCalls | ForEach-Object Uri) | Should -Be @('/v1.0/deviceManagement/windowsAutopilotDeviceIdentities/auto-1', '/v1.0/devices/current-object/memberOf')
        @($script:wireCalls | Where-Object Method -ne GET).Count | Should -Be 0
        $script:wireDevice.ManagedDeviceId | Should -BeExactly 'retain-managed'
        Should -Invoke Set-MgRequestContext -Times 1 -Exactly
        Should -Invoke Start-Sleep -Times 0 -Exactly
    }
    It 'changes only the configured target for <Operation> alongside the logged baseline membership' -ForEach @(
        @{ Operation = 'addition'; ExpectedMember = $true; Method = 'POST'; Handler = 'Invoke-StepAddPreProvisioningGroup' },
        @{ Operation = 'removal'; ExpectedMember = $false; Method = 'DELETE'; Handler = 'Invoke-StepRemovePreProvisioningGroup' }
    ) {
        $script:RuntimeConfig.autopilot.preProvisioningGroupPrefix = 'Intune-Autopilot-'
        $script:wireGroup.displayName = 'Intune-Autopilot-ESP-Prod'
        $manifest = Get-Content -LiteralPath (Join-Path (Split-Path -Parent $PSScriptRoot) 'autopilot-express.manifest.json') -Raw | ConvertFrom-Json
        $script:Config.GroupConflictExclusions = @($manifest.groupConflictExclusions)
        $script:wireMember = -not $ExpectedMember
        $script:expectedMember = $ExpectedMember
        $script:expectedMethod = $Method
        if (-not $ExpectedMember) { $script:wireStep = @{ Id = 'J'; ActionName = 'RemoveFromPreProvisioningGroup' } }
        Mock Get-ConfiguredPreProvisioningGroupDisplayName { return $script:wireGroup.displayName }
        Mock Invoke-MgGraphRequest {
            $script:wireCalls.Add(@{ Method = [string]$Method; Uri = [string]$Uri; Body = $Body })
            if ($Method -eq 'GET' -and $Uri -eq '/v1.0/deviceManagement/windowsAutopilotDeviceIdentities/auto-1') {
                return @{ id = 'auto-1'; serialNumber = 'SERIAL1'; azureActiveDirectoryDeviceId = 'registration-1' }
            }
            if ($Method -eq 'GET' -and $Uri.StartsWith('/v1.0/devices?')) { return @{ value = @(@{ id = 'current-object'; deviceId = 'registration-1' }) } }
            if ($Method -eq 'GET' -and $Uri.StartsWith('/v1.0/groups?')) { return @{ value = @($script:wireGroup) } }
            if ($Method -eq 'GET' -and $Uri -eq '/v1.0/devices/current-object/memberOf') {
                return @{ value = @(
                    @{ id = 'baseline'; displayName = 'Intune-Autopilot-AllDevices'; '@odata.type' = '#microsoft.graph.group'; groupTypes = @('DynamicMembership') }
                    if ($script:wireMember) { $script:wireGroup }
                ) }
            }
            if ($Method -eq 'GET' -and $Uri -eq '/v1.0/groups/group-1?$select=id') { return @{ id = 'group-1' } }
            $targetUri = if ($script:expectedMember) { '/v1.0/groups/group-1/members/$ref' } else { '/v1.0/groups/group-1/members/current-object/$ref' }
            if ($Method -eq $script:expectedMethod -and $Uri -eq $targetUri) { $script:wireMember = $script:expectedMember; return $null }
            throw ('Unexpected wire request: {0} {1}' -f $Method, $Uri)
        }
        $result = & $Handler -Device $script:wireDevice -StepDefinition $script:wireStep
        $result.CompletionState | Should -Be Verified -Because $result.Notes
        $result.Data.ObservedMember | Should -Be $ExpectedMember
        $result.Data.ConflictingGroups.Count | Should -Be 0
        @($script:wireCalls | Where-Object Method -ne GET).Count | Should -Be 1
        Should -Invoke Read-ValidatedInput -Times 0 -Exactly
        Should -Invoke Start-Sleep -Times 0 -Exactly
    }
    It 'retains accepted evidence and prevents replay after denied read-back and explicit reconnection' {
        $script:wireDenyReadback = $true
        $pending = Invoke-StepAddPreProvisioningGroup -Device $script:wireDevice -StepDefinition $script:wireStep
        $pending.CompletionState | Should -Be Submitted
        $pending.Data.TargetSubmitted | Should -BeTrue
        $script:wireDevice.Steps.D = $pending
        $script:wireDenyReadback = $false
        $script:GraphSession.RequiresReconnect = $false
        $again = Invoke-StepAddPreProvisioningGroup -Device $script:wireDevice -StepDefinition $script:wireStep
        $again.CompletionState | Should -Be Submitted
        @($script:wireCalls | Where-Object Method -eq POST).Count | Should -Be 1
        Should -Invoke Start-Sleep -Times 0 -Exactly
    }
    It 'rejects a changed actual tenant before any SDK request' {
        Mock Get-MgContext { return @{ TenantId = '22222222-2222-2222-2222-222222222222' } }
        $result = Invoke-StepAddPreProvisioningGroup -Device $script:wireDevice -StepDefinition $script:wireStep
        $result.CompletionState | Should -Be Failed
        $script:wireCalls.Count | Should -Be 0
    }
    It 'retains an accepted target when the subsequent <Stage> prerequisite fails' -ForEach @(
        @{ Stage = 'Autopilot'; PathPrefix = '/v1.0/deviceManagement/windowsAutopilotDeviceIdentities/' }
        @{ Stage = 'Entra'; PathPrefix = '/v1.0/devices?' }
        @{ Stage = 'group'; PathPrefix = '/v1.0/groups?' }
    ) {
        $pending = Invoke-StepAddPreProvisioningGroup -Device $script:wireDevice -StepDefinition $script:wireStep
        $pending.CompletionState | Should -Be Submitted
        $script:wireDevice.Steps.D = $pending
        $script:deniedPrefix = $PathPrefix
        Mock Invoke-MgGraphRequest { throw [IO.IOException]::new('Synthetic prerequisite failure.') } -ParameterFilter { $Uri.StartsWith($script:deniedPrefix) }
        $again = Invoke-StepAddPreProvisioningGroup -Device $script:wireDevice -StepDefinition $script:wireStep
        $again.CompletionState | Should -Be Submitted
        $again.Data.TargetSubmitted | Should -BeTrue
        $again.Data.GroupId | Should -BeExactly 'group-1'
        $again.Data.DirectoryObjectId | Should -BeExactly 'current-object'
        @($script:wireCalls | Where-Object Method -eq POST).Count | Should -Be 1
    }
    It 'detects an in-memory mutation that removes the accepted-write no-replay guard' {
        $pending = Invoke-StepAddPreProvisioningGroup -Device $script:wireDevice -StepDefinition $script:wireStep
        $script:wireDevice.Steps.D = $pending
        $definition = $sourceAst.Find({ param($node) $node -is [System.Management.Automation.Language.FunctionDefinitionAst] -and $node.Name -eq 'Invoke-PreProvisioningMembershipChange' }, $true)
        $body = $definition.Body.Extent.Text
        $originalGuard = '$evidence.TargetSubmitted -and $observedMember -ne $ExpectedMember'
        $body.Contains($originalGuard) | Should -BeTrue
        $mutated = $body.Substring(1, $body.Length - 2).Replace($originalGuard, '$false')
        try {
            Set-Item Function:Invoke-PreProvisioningMembershipChange -Value ([scriptblock]::Create($mutated))
            $result = Invoke-StepAddPreProvisioningGroup -Device $script:wireDevice -StepDefinition $script:wireStep
            $result.CompletionState | Should -Be Submitted
            @($script:wireCalls | Where-Object Method -eq POST).Count | Should -Be 2
        }
        finally { Set-Item Function:Invoke-PreProvisioningMembershipChange -Value $definition.Body.GetScriptBlock() }
    }
    It 'detects an in-memory mutation that accepts the wrong serial on a saved Autopilot ID' {
        Mock Invoke-MgGraphRequest { return @{ id = 'auto-1'; serialNumber = 'OTHER-SERIAL' } } -ParameterFilter { $Uri -eq '/v1.0/deviceManagement/windowsAutopilotDeviceIdentities/auto-1' }
        { Resolve-LiveAutopilotTagContext -Device $script:wireDevice } | Should -Throw '*serial*'
        $definition = $sourceAst.Find({ param($node) $node -is [System.Management.Automation.Language.FunctionDefinitionAst] -and $node.Name -eq 'Resolve-LiveAutopilotTagContext' }, $true)
        $body = $definition.Body.Extent.Text
        $originalGuard = '$identity.serialNumber -isnot [string] -or $identity.serialNumber -ine $Device.Serial'
        $body.Contains($originalGuard) | Should -BeTrue
        $mutated = $body.Substring(1, $body.Length - 2).Replace($originalGuard, '$false')
        try {
            Set-Item Function:Resolve-LiveAutopilotTagContext -Value ([scriptblock]::Create($mutated))
            (Resolve-LiveAutopilotTagContext -Device $script:wireDevice).serialNumber | Should -BeExactly 'OTHER-SERIAL'
        }
        finally { Set-Item Function:Resolve-LiveAutopilotTagContext -Value $definition.Body.GetScriptBlock() }
    }
    It 'detects an in-memory mutation that accepts absence against the wrong group identity' {
        Mock Invoke-MgGraphRequest { return @{ id = 'wrong-group' } } -ParameterFilter { $Uri -eq '/v1.0/groups/group-1?$select=id' }
        { Test-LiveGroupMembership -GroupId group-1 -DirectoryObjectId current-object } | Should -Throw '*expected group*'
        $definition = $sourceAst.Find({ param($node) $node -is [System.Management.Automation.Language.FunctionDefinitionAst] -and $node.Name -eq 'Test-LiveGroupMembership' }, $true)
        $body = $definition.Body.Extent.Text
        $originalGuard = '$group.id -isnot [string] -or $group.id -ine $GroupId'
        $body.Contains($originalGuard) | Should -BeTrue
        $mutated = $body.Substring(1, $body.Length - 2).Replace($originalGuard, '$false')
        try {
            Set-Item Function:Test-LiveGroupMembership -Value ([scriptblock]::Create($mutated))
            Test-LiveGroupMembership -GroupId group-1 -DirectoryObjectId current-object | Should -BeFalse
        }
        finally { Set-Item Function:Test-LiveGroupMembership -Value $definition.Body.GetScriptBlock() }
    }
    It 'serialises one exact tag update and rechecks pending and visible tags with one GET each' {
        $tagStep = @{ Id = 'C'; ActionName = 'ApplyGroupTag' }
        $pending = Invoke-StepApplyGroupTag -Device $script:wireDevice -StepDefinition $tagStep
        $pending.CompletionState | Should -Be Submitted
        $script:wireCalls.Count | Should -Be 3
        $write = @($script:wireCalls | Where-Object Method -eq POST)
        $write.Count | Should -Be 1
        ($write[0].Body | ConvertFrom-Json).groupTag | Should -BeExactly 'SITE-Desktop'
        $script:wireDevice.GroupTag | Should -BeExactly 'old-record'
        $script:wireDevice.Steps.C = $pending
        $script:wireCalls.Clear()
        (Invoke-StepApplyGroupTag -Device $script:wireDevice -StepDefinition $tagStep).CompletionState | Should -Be Submitted
        $script:wireCalls.Count | Should -Be 1
        $script:wireCalls[0].Method | Should -BeExactly 'GET'
        $script:wireTag = 'SITE-Desktop'
        $script:wireCalls.Clear()
        (Invoke-StepApplyGroupTag -Device $script:wireDevice -StepDefinition $tagStep).CompletionState | Should -Be Verified
        $script:wireCalls.Count | Should -Be 1
        $script:wireDevice.GroupTag | Should -BeExactly 'SITE-Desktop'
        $script:wireDevice.EntraDeviceId | Should -BeExactly 'stale-object'
        Should -Invoke Set-MgRequestContext -Times 1 -Exactly
        Should -Invoke Start-Sleep -Times 0 -Exactly
    }
    It 'retains a submitted tag without updating local state after a wrong-ID read-back' {
        Mock Invoke-MgGraphRequest {
            return @{ id = if ($script:wireTagPostAccepted) { 'wrong-auto' } else { 'auto-1' }; serialNumber = 'SERIAL1'; groupTag = 'SITE-Desktop-other' }
        } -ParameterFilter { $Method -eq 'GET' -and $Uri -eq '/v1.0/deviceManagement/windowsAutopilotDeviceIdentities/auto-1' }
        $pending = Invoke-StepApplyGroupTag -Device $script:wireDevice -StepDefinition @{ Id = 'C'; ActionName = 'ApplyGroupTag' }
        $pending.CompletionState | Should -Be Submitted
        $pending.Data.Submitted | Should -BeTrue
        $pending.Data.AutopilotDeviceId | Should -BeExactly 'auto-1'
        $script:wireDevice.GroupTag | Should -BeExactly 'old-record'
        @($script:wireCalls | Where-Object Method -eq POST).Count | Should -Be 1
    }
}

Describe 'Pre-provisioning membership transitions' {
    BeforeAll {
        function Get-LivePreProvisioningMembershipState {
            param($DirectoryObjectId, $TargetGroup)
            return @{
                ObservedMember = Test-LiveGroupMembership -GroupId $TargetGroup.id -DirectoryObjectId $DirectoryObjectId
                ConflictGroups = Get-LivePreProvisioningConflictGroup -DirectoryObjectId $DirectoryObjectId -TargetGroup $TargetGroup
            }
        }
    }
    BeforeEach {
        $script:Runtime = @{ IsDemoMode = $false }
        $script:Config = @{ MaxRetryAttempts = 3; RetryBackoffSeconds = 2 }
        $script:device = @{ Serial = 'SERIAL1'; EntraDeviceId = 'device-1' }
        $script:step = @{ ActionName = 'AddToPreProvisioningGroup' }
        $script:removeStep = @{ ActionName = 'RemoveFromPreProvisioningGroup' }
        $script:reads = 0
        Mock Start-Sleep {}
        Mock Resolve-LiveMembershipContext {}
        Mock Get-LivePreProvisioningGroup { return @{ id = 'group-1'; displayName = 'Test pre-provisioning'; securityEnabled = $true; mailEnabled = $false; groupTypes = @(); isAssignableToRole = $false } }
        Mock Get-LivePreProvisioningConflictGroup { return , @() }
        Mock Read-ValidatedInput { return 'N' }
        Mock Invoke-GraphApiRequest {}
        Mock Test-LiveGroupMembership { return $false }
    }

    It 'refreshes cached membership identity before reading or removing a relationship' {
        Mock Resolve-LiveMembershipContext { $Device.EntraDeviceId = 'current-device' }
        $result = Invoke-StepRemovePreProvisioningGroup -Device $script:device -StepDefinition $script:removeStep
        $result.CompletionState | Should -Be 'Verified'
        $result.Data.DirectoryObjectId | Should -Be 'current-device'
        Should -Invoke Test-LiveGroupMembership -Times 1 -Exactly -ParameterFilter { $DirectoryObjectId -eq 'current-device' }
    }
    It 'stops before membership access when cached identity refresh fails' {
        Mock Resolve-LiveMembershipContext { throw 'Identity read denied' }
        $result = Invoke-StepRemovePreProvisioningGroup -Device $script:device -StepDefinition $script:step
        $result.CompletionState | Should -Be 'Failed'
        Should -Invoke Test-LiveGroupMembership -Times 0 -Exactly
        Should -Invoke Invoke-GraphApiRequest -Times 0 -Exactly
    }
    It 'skips a write when addition is already verified' {
        Mock Test-LiveGroupMembership { return $true }
        $result = Invoke-StepAddPreProvisioningGroup -Device $script:device -StepDefinition $script:step
        $result.CompletionState | Should -Be 'Verified'
        $result.Data.Submitted | Should -BeFalse
        Should -Invoke Invoke-GraphApiRequest -Times 0 -Exactly
    }

    It 'refuses unsupported group eligibility before membership writes' {
        foreach ($metadata in @(
                @{ securityEnabled = $false; mailEnabled = $false; groupTypes = @() }
                @{ securityEnabled = $true; mailEnabled = $true; groupTypes = @() }
                @{ securityEnabled = $true; mailEnabled = $false; groupTypes = @('DynamicMembership') }
                @{ securityEnabled = $true; mailEnabled = $false; groupTypes = @(); isAssignableToRole = $true }
                @{ securityEnabled = $true; mailEnabled = $false }
            )) {
            $script:groupMetadata = $metadata
            Mock Get-LivePreProvisioningGroup { return (@{ id = 'group-1'; displayName = 'Test pre-provisioning' } + $script:groupMetadata) }
            $result = Invoke-StepAddPreProvisioningGroup -Device $script:device -StepDefinition $script:step
            $result.CompletionState | Should -Be Failed
        }
        Should -Invoke Test-LiveGroupMembership -Times 5 -Exactly
        Should -Invoke Invoke-GraphApiRequest -Times 0 -Exactly
    }

    It 'preserves read-only verified no-op outcomes for groups that cannot be mutated' {
        Mock Get-LivePreProvisioningGroup { return @{ id = 'group-1'; displayName = 'Test pre-provisioning'; groupTypes = @('DynamicMembership') } }
        Mock Test-LiveGroupMembership { return $true }
        (Invoke-StepAddPreProvisioningGroup -Device $script:device -StepDefinition $script:step).CompletionState | Should -Be Verified
        Should -Invoke Invoke-GraphApiRequest -Times 0 -Exactly
    }

    It 'refuses a non-Boolean membership observation without writing' {
        Mock Test-LiveGroupMembership { return $null }
        (Invoke-StepAddPreProvisioningGroup -Device $script:device -StepDefinition $script:step).CompletionState | Should -Be Failed
        Should -Invoke Invoke-GraphApiRequest -Times 0 -Exactly
    }

    It 'skips a write when removal is already verified' {
        $result = Invoke-StepRemovePreProvisioningGroup -Device $script:device -StepDefinition $script:removeStep
        $result.CompletionState | Should -Be 'Verified'
        $result.Data.ObservedMember | Should -BeFalse
        Should -Invoke Invoke-GraphApiRequest -Times 0 -Exactly
    }

    It 'returns delayed addition as Submitted after one immediate read and one POST' {
        Mock Test-LiveGroupMembership { $script:reads++; return $script:reads -ge 3 }
        $result = Invoke-StepAddPreProvisioningGroup -Device $script:device -StepDefinition $script:step
        $result.CompletionState | Should -Be 'Submitted'
        $result.Data.VerificationAttempts | Should -Be 1
        Should -Invoke Invoke-GraphApiRequest -Times 1 -Exactly -ParameterFilter {
            $Method -eq 'POST' -and $Uri -eq 'https://graph.microsoft.com/v1.0/groups/group-1/members/$ref' -and
            $Body.'@odata.id' -eq 'https://graph.microsoft.com/v1.0/directoryObjects/device-1'
        }
        Should -Invoke Start-Sleep -Times 0 -Exactly
    }

    It 'returns delayed removal as Submitted after one immediate read and one reference DELETE' {
        Mock Test-LiveGroupMembership { $script:reads++; return $script:reads -lt 3 }
        $result = Invoke-StepRemovePreProvisioningGroup -Device $script:device -StepDefinition $script:removeStep
        $result.CompletionState | Should -Be 'Submitted'
        $result.Data.VerificationAttempts | Should -Be 1
        Should -Invoke Invoke-GraphApiRequest -Times 1 -Exactly -ParameterFilter {
            $Method -eq 'DELETE' -and $Uri -eq 'https://graph.microsoft.com/v1.0/groups/group-1/members/device-1/$ref'
        }
        Should -Invoke Start-Sleep -Times 0 -Exactly
    }

    It 'keeps exhausted addition Submitted with absence evidence' {
        $result = Invoke-StepAddPreProvisioningGroup -Device $script:device -StepDefinition $script:step
        $result.CompletionState | Should -Be 'Submitted'
        $result.Success | Should -BeFalse
        $result.Data.Submitted | Should -BeTrue
        $result.Data.VerificationAttempts | Should -Be 1
        $result.Data.ObservedMember | Should -BeFalse
        Should -Invoke Start-Sleep -Times 0 -Exactly
    }

    It 'keeps exhausted removal Submitted with presence evidence' {
        Mock Test-LiveGroupMembership { return $true }
        $result = Invoke-StepRemovePreProvisioningGroup -Device $script:device -StepDefinition $script:step
        $result.CompletionState | Should -Be 'Submitted'
        $result.Success | Should -BeFalse
        $result.Data.ObservedMember | Should -BeTrue
        Should -Invoke Invoke-GraphApiRequest -Times 1 -Exactly
        Should -Invoke Start-Sleep -Times 0 -Exactly
    }

    It 'does not hide a membership read error as successful removal' {
        Mock Test-LiveGroupMembership { throw 'Permission denied: resource was not found' }
        $result = Invoke-StepRemovePreProvisioningGroup -Device $script:device -StepDefinition $script:step
        $result.CompletionState | Should -Be 'Failed'
        $result.Success | Should -BeFalse
        Should -Invoke Invoke-GraphApiRequest -Times 0 -Exactly
    }

    It 'retains submission evidence when post-write verification fails' {
        Mock Test-LiveGroupMembership { $script:reads++; if ($script:reads -gt 1) { throw 'Read denied' }; return $false }
        $result = Invoke-StepAddPreProvisioningGroup -Device $script:device -StepDefinition $script:step
        $result.CompletionState | Should -Be 'Submitted'
        $result.Data.Submitted | Should -BeTrue
        Should -Invoke Start-Sleep -Times 0 -Exactly
    }

    It 'does not replay an accepted target addition when a later read still shows absence' {
        $script:step.Id = 'D'
        $script:device.Steps = @{ D = @{ Data = @{ Submitted = $true; GroupId = 'group-1'; DirectoryObjectId = 'device-1'; ExpectedMember = $true } } }
        (Invoke-StepAddPreProvisioningGroup -Device $script:device -StepDefinition $script:step).CompletionState | Should -Be Submitted
        Should -Invoke Invoke-GraphApiRequest -Times 0 -Exactly
    }

    It 'verifies delayed addition on a later bench recheck without another POST or sleep' {
        $script:step.Id = 'D'
        $script:device.Steps = @{}
        Mock Test-LiveGroupMembership { $script:reads++; return $script:reads -ge 3 }
        $pending = Invoke-StepAddPreProvisioningGroup -Device $script:device -StepDefinition $script:step
        $pending.CompletionState | Should -Be Submitted
        $script:device.Steps.D = $pending
        $verified = Invoke-StepAddPreProvisioningGroup -Device $script:device -StepDefinition $script:step
        $verified.CompletionState | Should -Be Verified
        $verified.Data.Submitted | Should -BeTrue
        Should -Invoke Invoke-GraphApiRequest -Times 1 -Exactly -ParameterFilter { $Method -eq 'POST' }
        Should -Invoke Start-Sleep -Times 0 -Exactly
    }

    It 'shows conflicts and defaults to retaining memberships without writes' {
        Mock Get-LivePreProvisioningConflictGroup { return , @(@{ id = 'old-group'; displayName = 'Other group'; securityEnabled = $true; mailEnabled = $false; groupTypes = @() }) }
        (Invoke-StepAddPreProvisioningGroup -Device $script:device -StepDefinition $script:step).CompletionState | Should -Be Blocked
        Should -Invoke Read-ValidatedInput -Times 1 -Exactly -ParameterFilter { $Default -eq 'N' }
        Should -Invoke Invoke-GraphApiRequest -Times 0 -Exactly
    }

    It 'refuses a dynamic conflicting group before offering correction or writing' {
        Mock Get-LivePreProvisioningConflictGroup { return , @(@{ id = 'old-group'; displayName = 'Other group'; securityEnabled = $true; mailEnabled = $false; groupTypes = @('DynamicMembership') }) }
        (Invoke-StepAddPreProvisioningGroup -Device $script:device -StepDefinition $script:step).CompletionState | Should -Be Failed
        Should -Invoke Read-ValidatedInput -Times 0 -Exactly
        Should -Invoke Invoke-GraphApiRequest -Times 0 -Exactly
    }

    It 'removes only a confirmed conflicting reference then verifies the configured target' {
        $script:conflictReads = 0
        Mock Get-LivePreProvisioningConflictGroup {
            $script:conflictReads++
            if ($script:conflictReads -eq 1) { return , @(@{ id = 'old-group'; displayName = 'Other group'; securityEnabled = $true; mailEnabled = $false; groupTypes = @() }) }
            return , @()
        }
        Mock Read-ValidatedInput { return 'Y' }
        Mock Test-LiveGroupMembership { return $true } -ParameterFilter { $GroupId -eq 'group-1' }
        $result = Invoke-StepAddPreProvisioningGroup -Device $script:device -StepDefinition $script:step
        $result.CompletionState | Should -Be Verified
        $result.Data.ConflictChanges.Count | Should -Be 1
        Should -Invoke Invoke-GraphApiRequest -Times 1 -Exactly -ParameterFilter { $Method -eq 'DELETE' -and $Uri -eq 'https://graph.microsoft.com/v1.0/groups/old-group/members/device-1/$ref' }
        Should -Invoke Invoke-GraphApiRequest -Times 0 -Exactly -ParameterFilter { $Method -eq 'POST' }
    }

    It 'does not treat duplicate-error wording as read-back verification' {
        Mock Invoke-GraphApiRequest { throw 'Permission denied; relationship already exists' }
        $result = Invoke-StepAddPreProvisioningGroup -Device $script:device -StepDefinition $script:step
        $result.CompletionState | Should -Be 'Failed'
        $result.Data.Submitted | Should -BeFalse
    }

    It 'blocks a missing device identity without issuing a write' {
        $script:device.EntraDeviceId = ''
        $result = Invoke-StepAddPreProvisioningGroup -Device $script:device -StepDefinition $script:step
        $result.CompletionState | Should -Be 'Blocked'
        Should -Invoke Invoke-GraphApiRequest -Times 0 -Exactly
    }

    It 'resolves missing device context before checking membership' {
        $script:device.EntraDeviceId = ''
        Mock Resolve-LiveMembershipContext { $Device.EntraDeviceId = 'device-1' }
        $result = Invoke-StepRemovePreProvisioningGroup -Device $script:device -StepDefinition $script:removeStep
        $result.CompletionState | Should -Be 'Verified'
        Should -Invoke Resolve-LiveMembershipContext -Times 1 -Exactly
    }

    It 'rejects invalid policy before context lookup or mutation' {
        $script:Config.MaxRetryAttempts = 0
        $script:device.EntraDeviceId = ''
        $result = Invoke-StepAddPreProvisioningGroup -Device $script:device -StepDefinition $script:step
        $result.CompletionState | Should -Be 'Failed'
        Should -Invoke Resolve-LiveMembershipContext -Times 0 -Exactly
        Should -Invoke Get-LivePreProvisioningGroup -Times 0 -Exactly
    }

    It 'does not convert a missing-group error to successful removal' {
        Mock Get-LivePreProvisioningGroup { throw 'Resource group does not exist' }
        $result = Invoke-StepRemovePreProvisioningGroup -Device $script:device -StepDefinition $script:step
        $result.CompletionState | Should -Be 'Failed'
        Should -Invoke Invoke-GraphApiRequest -Times 0 -Exactly
    }

    It 'rejects a group response without an object ID' {
        Mock Get-LivePreProvisioningGroup { return @{ displayName = 'Unknown' } }
        $result = Invoke-StepRemovePreProvisioningGroup -Device $script:device -StepDefinition $script:step
        $result.CompletionState | Should -Be 'Failed'
        Should -Invoke Test-LiveGroupMembership -Times 0 -Exactly
    }

    It 'keeps Demo addition isolated from lookups, mutations and pauses' {
        $script:Runtime.IsDemoMode = $true
        $result = Invoke-StepAddPreProvisioningGroup -Device $script:device -StepDefinition $script:step
        $result.CompletionState | Should -Be 'Simulated'
        Should -Invoke Test-LiveGroupMembership -Times 0 -Exactly
        Should -Invoke Invoke-GraphApiRequest -Times 0 -Exactly
        Should -Invoke Start-Sleep -Times 0 -Exactly
    }

    It 'keeps Demo removal isolated from Graph' {
        $script:Runtime.IsDemoMode = $true
        $result = Invoke-StepRemovePreProvisioningGroup -Device $script:device -StepDefinition $script:step
        $result.CompletionState | Should -Be 'Simulated'
        Should -Invoke Get-LivePreProvisioningGroup -Times 0 -Exactly
        Should -Invoke Invoke-GraphApiRequest -Times 0 -Exactly
    }
}

Describe 'Complete prefix-related membership discovery' {
    BeforeAll {
        foreach ($functionName in @('Get-GraphDiscoveryCollection', 'Get-LivePreProvisioningConflictGroup', 'Get-LivePreProvisioningMembershipState')) {
            $definition = $sourceAst.Find({ param($node) $node -is [System.Management.Automation.Language.FunctionDefinitionAst] -and $node.Name -eq $functionName }, $true)
            Set-Item -Path ('Function:{0}' -f $definition.Name) -Value $definition.Body.GetScriptBlock()
        }
    }
    BeforeEach {
        $script:RuntimeConfig = @{ autopilot = @{ preProvisioningGroupPrefix = 'Intune-Autopilot-' } }
        $script:Config = @{}
        $script:targetGroup = @{ id = 'target'; displayName = 'Intune-Autopilot-Testing' }
        Mock Invoke-GraphApiRequest {
            if ($Uri -like '*skiptoken*') { return @{ value = @(@{ id = 'conflict'; displayName = 'Intune-Autopilot-PreProvisioning'; '@odata.type' = '#microsoft.graph.group' }) } }
            return @{ value = @(@{ id = 'target'; displayName = 'Intune-Autopilot-Testing'; '@odata.type' = '#microsoft.graph.group' }); '@odata.nextLink' = 'https://graph.microsoft.com/v1.0/devices/device-1/memberOf?$skiptoken=next' }
        }
    }
    It 'finds conflicts on later pages without selecting a different target' {
        $conflicts = Get-LivePreProvisioningConflictGroup -DirectoryObjectId device-1 -TargetGroup $script:targetGroup
        $conflicts.Count | Should -Be 1
        $conflicts[0].id | Should -Be conflict
        $script:targetGroup.id | Should -Be target
        Should -Invoke Invoke-GraphApiRequest -Times 2 -Exactly -ParameterFilter { $Method -eq 'GET' }
    }
    It 'excludes only the approved group prefixes while retaining genuine conflicts' {
        $script:RuntimeConfig.autopilot.preProvisioningGroupPrefix = 'Intune-'
        $memberships = @('Intune-Autopilot-All-Devices', 'intune-workstation-Site', 'Intune-Workstations-All', 'Intune-Autopilot-Other') | ForEach-Object { @{ id = $_; displayName = $_; '@odata.type' = '#microsoft.graph.group' } }
        $conflicts = Get-LivePreProvisioningConflictGroup -DirectoryObjectId device-1 -TargetGroup $script:targetGroup -Memberships $memberships
        $conflicts.Count | Should -Be 1
        $conflicts[0].displayName | Should -BeExactly 'Intune-Autopilot-Other'
    }
    It 'supports exact-name manifest rules without excluding similarly named groups' {
        $script:Config.GroupConflictExclusions = @(@{ match = 'Exact'; value = 'Intune-Autopilot-Exception' })
        $memberships = @('Intune-Autopilot-Exception', 'Intune-Autopilot-Exception-Other') | ForEach-Object { @{ id = $_; displayName = $_; '@odata.type' = '#microsoft.graph.group' } }
        $conflicts = Get-LivePreProvisioningConflictGroup -DirectoryObjectId device-1 -TargetGroup $script:targetGroup -Memberships $memberships
        $conflicts.Count | Should -Be 1
        $conflicts[0].displayName | Should -BeExactly 'Intune-Autopilot-Exception-Other'
    }
    It 'excludes the logged AllDevices baseline with <RulesSource> rules but retains lookalike conflicts' -ForEach @(
        @{ RulesSource = 'Manifest' }, @{ RulesSource = 'LegacyFallback' }
    ) {
        if ($RulesSource -eq 'Manifest') {
            $manifestPath = Join-Path (Split-Path -Parent $PSScriptRoot) 'autopilot-express.manifest.json'
            $manifest = Get-Content -LiteralPath $manifestPath -Raw | ConvertFrom-Json
            $script:Config.GroupConflictExclusions = @($manifest.groupConflictExclusions)
        }
        $memberships = @('Intune-Autopilot-AllDevices', 'Intune-Autopilot-AllDevices-Other') | ForEach-Object {
            @{ id = $_; displayName = $_; '@odata.type' = '#microsoft.graph.group'; groupTypes = @('DynamicMembership') }
        }
        $conflicts = Get-LivePreProvisioningConflictGroup -DirectoryObjectId device-1 -TargetGroup $script:targetGroup -Memberships $memberships
        $conflicts.Count | Should -Be 1
        $conflicts[0].displayName | Should -BeExactly 'Intune-Autopilot-AllDevices-Other'
        Should -Invoke Invoke-GraphApiRequest -Times 0 -Exactly
    }
    It 'derives both target membership and conflicts from the same complete paged response' {
        $state = Get-LivePreProvisioningMembershipState -DirectoryObjectId device-1 -TargetGroup $script:targetGroup
        $state.ObservedMember | Should -BeTrue
        $state.ConflictGroups.Count | Should -Be 1
        $state.ConflictGroups[0].id | Should -BeExactly 'conflict'
        Should -Invoke Invoke-GraphApiRequest -Times 2 -Exactly
        Should -Invoke Invoke-GraphApiRequest -Times 0 -Exactly -ParameterFilter { $Uri -like '*/groups/*/members*' }
    }
    It 'accepts a complete empty device snapshot without repeating discovery' {
        Mock Invoke-GraphApiRequest { return @{ value = @() } }
        $state = Get-LivePreProvisioningMembershipState -DirectoryObjectId device-1 -TargetGroup $script:targetGroup
        $state.ObservedMember | Should -BeFalse
        $state.ConflictGroups.Count | Should -Be 0
        Should -Invoke Invoke-GraphApiRequest -Times 1 -Exactly
    }
    It 'does not publish a membership snapshot after a later page fails' {
        Mock Invoke-GraphApiRequest { throw 'Synthetic snapshot page denial.' } -ParameterFilter { $Uri -like '*skiptoken*' }
        { Get-LivePreProvisioningMembershipState -DirectoryObjectId device-1 -TargetGroup $script:targetGroup } | Should -Throw '*snapshot page denial*'
    }
    It 'does not return a clean or partial result after a denied later page' {
        Mock Invoke-GraphApiRequest { throw 'Synthetic denied page' } -ParameterFilter { $Uri -like '*skiptoken*' }
        { Get-LivePreProvisioningConflictGroup -DirectoryObjectId device-1 -TargetGroup $script:targetGroup } | Should -Throw '*denied page*'
    }
    It 'refuses limited-information memberships rather than inferring no conflicts' {
        Mock Invoke-GraphApiRequest { return @{ value = @(@{ id = 'unknown'; displayName = $null; '@odata.type' = '#microsoft.graph.group' }) } }
        { Get-LivePreProvisioningConflictGroup -DirectoryObjectId device-1 -TargetGroup $script:targetGroup } | Should -Throw '*invalid identity*'
    }
}

Describe 'Direct membership absence evidence' {
    BeforeAll {
        $collectionDefinition = $sourceAst.Find({ param($node) $node -is [System.Management.Automation.Language.FunctionDefinitionAst] -and $node.Name -eq 'Get-GraphDiscoveryCollection' }, $true)
        . ([scriptblock]::Create($collectionDefinition.Extent.Text))
        $definition = $sourceAst.Find({ param($node) $node -is [System.Management.Automation.Language.FunctionDefinitionAst] -and $node.Name -eq 'Test-LiveGroupMembership' }, $true)
        Set-Item -Path ('Function:{0}' -f $definition.Name) -Value $definition.Body.GetScriptBlock()
    }
    BeforeEach {
        Mock Invoke-GraphApiRequest { return @{ value = @(@{ id = 'group-1' }) } }
    }

    It 'checks the device direct memberships without enumerating every group member' {
        Mock Invoke-GraphApiRequest { throw 'Unnecessary group-wide membership read.' }
        Mock Invoke-GraphApiRequest { return @{ value = @(@{ id = 'group-1' }) } } -ParameterFilter {
            $Method -eq 'GET' -and $Uri -eq 'https://graph.microsoft.com/v1.0/devices/device-1/memberOf'
        }
        Test-LiveGroupMembership -GroupId group-1 -DirectoryObjectId device-1 | Should -BeTrue
        Should -Invoke Invoke-GraphApiRequest -Times 1 -Exactly
    }

    It 'returns presence from a complete device direct-membership collection' {
        Test-LiveGroupMembership -GroupId 'group-1' -DirectoryObjectId 'device-1' | Should -BeTrue
        Should -Invoke Invoke-GraphApiRequest -Times 1 -Exactly -ParameterFilter {
            $Method -eq 'GET' -and $Uri -eq 'https://graph.microsoft.com/v1.0/devices/device-1/memberOf'
        }
    }

    It 'verifies presence on a later page with limited-information member IDs' {
        Mock Invoke-GraphApiRequest {
            if ($Uri -like '*skiptoken*') { return @{ value = @(@{ id = 'group-1'; displayName = $null }) } }
            return @{ value = @(@{ id = 'other-group' }); '@odata.nextLink' = 'https://graph.microsoft.com/v1.0/devices/device-1/memberOf?$skiptoken=next' }
        }
        Test-LiveGroupMembership -GroupId group-1 -DirectoryObjectId device-1 | Should -BeTrue
        Should -Invoke Invoke-GraphApiRequest -Times 2 -Exactly
    }

    It 'does not confirm absence after a failed later page' {
        Mock Invoke-GraphApiRequest {
            if ($Uri -like '*skiptoken*') { throw 'Later page denied' }
            return @{ value = @(); '@odata.nextLink' = 'https://graph.microsoft.com/v1.0/devices/device-1/memberOf?$skiptoken=next' }
        }
        { Test-LiveGroupMembership -GroupId group-1 -DirectoryObjectId device-1 } | Should -Throw '*Later page denied*'
        Should -Invoke Invoke-GraphApiRequest -Times 0 -Exactly -ParameterFilter { $Uri -like '*/directoryObjects/*' }
    }

    It 'rejects malformed member collections rather than confirming absence' {
        foreach ($response in @($null, @{}, @{ value = $null }, @{ value = 'invalid' }, @{ value = @(@{ id = '' }) })) {
            $script:membershipResponse = $response
            Mock Invoke-GraphApiRequest { return $script:membershipResponse }
            { Test-LiveGroupMembership -GroupId group-1 -DirectoryObjectId device-1 } | Should -Throw
        }
    }

    It 'rejects not-found text without a structured HTTP status' {
        Mock Invoke-GraphApiRequest { throw 'Resource not found; does not exist' }
        { Test-LiveGroupMembership -GroupId 'group-1' -DirectoryObjectId 'device-1' } | Should -Throw '*not found*'
        Should -Invoke Invoke-GraphApiRequest -Times 1 -Exactly
    }

    It 'rejects a structured permission failure even with not-found text' {
        Mock Invoke-GraphApiRequest {
            $exception = [System.Exception]::new('Permission denied: resource not found')
            $exception | Add-Member -NotePropertyName ResponseStatusCode -NotePropertyValue 403
            throw $exception
        }
        { Test-LiveGroupMembership -GroupId 'group-1' -DirectoryObjectId 'device-1' } | Should -Throw '*Permission denied*'
        Should -Invoke Invoke-GraphApiRequest -Times 1 -Exactly
    }

    It 'verifies absence from a complete device membership read and the group identity in two requests' {
        Mock Invoke-GraphApiRequest {
            if ($Uri -like '*/memberOf*') { return @{ value = @() } }
            return @{ id = 'group-1' }
        }
        Test-LiveGroupMembership -GroupId 'group-1' -DirectoryObjectId 'device-1' | Should -BeFalse
        Should -Invoke Invoke-GraphApiRequest -Times 2 -Exactly
    }

    It 'rejects 404 instead of interpreting it as absent membership' {
        Mock Invoke-GraphApiRequest {
            if ($Uri -like '*/memberOf*') {
                $exception = [System.Exception]::new('Membership absent')
                $exception | Add-Member -NotePropertyName Response -NotePropertyValue @{ StatusCode = 'NotFound' }
                throw $exception
            }
            if ($Uri -like '*/directoryObjects/*') { return @{ id = 'device-1' } }
            return @{ id = 'group-1' }
        }
        { Test-LiveGroupMembership -GroupId 'group-1' -DirectoryObjectId 'device-1' } | Should -Throw '*Membership absent*'
    }

    It 'rejects absence when the expected group identity is missing' {
        Mock Invoke-GraphApiRequest {
            if ($Uri -like '*/memberOf*') { return @{ value = @() } }
            return @{ id = 'other-group' }
        }
        { Test-LiveGroupMembership -GroupId 'group-1' -DirectoryObjectId 'device-1' } | Should -Throw '*expected group and device*'
    }

    It 'propagates identity lookup errors rather than confirming absence' {
        Mock Invoke-GraphApiRequest {
            if ($Uri -like '*/memberOf*') { return @{ value = @() } }
            throw 'Group lookup denied'
        }
        { Test-LiveGroupMembership -GroupId 'group-1' -DirectoryObjectId 'device-1' } | Should -Throw '*Group lookup denied*'
    }
}