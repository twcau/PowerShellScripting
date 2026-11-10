<#
.SYNOPSIS
    Counts the Microsoft Graph requests each workflow action makes, against a simulated tenant.
.DESCRIPTION
    Loads every function from autopilot-express.ps1 without starting the menu, then
    replaces the Graph SDK call (Invoke-MgGraphRequest) with an in-memory tenant. Each
    HTTP request that would leave the PC is counted; a JSON batch counts as one request,
    because that is what Graph receives over the network.

    Every scenario also checks its outcome, so a lower count can never come from
    skipping work. The expected counts are the agreed call budget: if a change adds a
    Graph request, the matching test fails and shows the new number.

    Set GRAPH_BUDGET_OUT to a file path to also save the measured counts as JSON.
    No tenant, file or saved record is touched. Requires Pester 5.
#>

BeforeAll {
    $sourcePath = Join-Path (Split-Path -Parent $PSScriptRoot) 'autopilot-express.ps1'
    $tokens = $null
    $parseErrors = $null
    $sourceAst = [System.Management.Automation.Language.Parser]::ParseFile($sourcePath, [ref]$tokens, [ref]$parseErrors)
    if ($parseErrors.Count) { throw ($parseErrors.Message -join '; ') }
    # Load every top-level function so the real call paths are measured, not copies.
    foreach ($definition in $sourceAst.FindAll({ param($node) $node -is [System.Management.Automation.Language.FunctionDefinitionAst] }, $false)) {
        Set-Item -Path ('Function:{0}' -f $definition.Name) -Value $definition.Body.GetScriptBlock()
    }

    # Logging, prompts and storage are replaced; none of them reach Graph. Host output
    # and pauses are Pester mocks in the Describe block, so no built-in is redefined.
    function Write-AutopilotExpressLog { param($Message, $Level) $script:logLines.Add(('{0}: {1}' -f $Level, $Message)) }
    function Read-ValidatedInput {
        param($Prompt, $Default, $Type, $Choices)
        $script:prompts.Add(('{0} (default {1}; {2}: {3})' -f $Prompt, $Default, $Type, ($Choices -join '/')))
        return $script:promptAnswer
    }
    function Get-ConfiguredMissingSerialHandoffNote { return 'Upload the hardware hash.' }
    function Get-ArchivedDeviceRecordFile { return , @() }
    function Write-UserDeviceRecords { param($Records) $script:savedRecords = @($Records) }
    # Every caller of the step lookup in these scenarios needs the primary-user step ID.
    function Get-ManifestActionStepId { return 'R' }
    function Get-MgContext { return @{ TenantId = $script:tenant } }
    function Set-MgRequestContext {
        [CmdletBinding(SupportsShouldProcess)]
        param($MaxRetry, $ClientTimeout)
        if ($PSCmdlet.ShouldProcess('Simulated Graph transport', ('Set retry {0} and timeout {1}' -f $MaxRetry, $ClientTimeout))) { $script:transportSettings = @{ MaxRetry = $MaxRetry; ClientTimeout = $ClientTimeout } }
    }
    # The SDK delete cmdlet sends exactly one DELETE request, so it is counted like one.
    function Remove-MgDeviceManagementManagedDevice {
        [CmdletBinding(SupportsShouldProcess)]
        param([string]$ManagedDeviceId)
        if ($PSCmdlet.ShouldProcess($ManagedDeviceId, 'Delete simulated managed device')) {
            $path = '/v1.0/deviceManagement/managedDevices/{0}' -f $ManagedDeviceId
            $script:calls.Add(('DELETE {0}' -f $path))
            $null = Invoke-SimulatedGraph -Method 'DELETE' -Path $path
        }
    }

    function Get-SimulatedGroup {
        <#
        .SYNOPSIS
            Return an assigned security group object shaped like a Graph group.
        .PARAMETER Id
            Group object ID.
        .PARAMETER Name
            Group display name.
        #>
        param([string]$Id, [string]$Name)
        return @{ id = $Id; displayName = $Name; '@odata.type' = '#microsoft.graph.group'; securityEnabled = $true; mailEnabled = $false; groupTypes = @(); isAssignableToRole = $false }
    }

    function Invoke-SimulatedGraph {
        <#
        .SYNOPSIS
            Answer one Graph request from the in-memory tenant.
        .PARAMETER Method
            GET, POST or DELETE.
        .PARAMETER Path
            Path and query relative to the Graph host, for example /v1.0/devices/obj-1/memberOf.
        .PARAMETER Body
            Request body; JSON text for writes and batches.
        .OUTPUTS
            Response dictionary, or a terminating error for unknown requests.
        #>
        param([string]$Method, [string]$Path, $Body)
        $sim = $script:sim
        $decoded = [uri]::UnescapeDataString($Path)
        if ($Method -eq 'POST' -and $decoded -eq '/v1.0/$batch') {
            $requestSet = if ($Body -is [string]) { $Body | ConvertFrom-Json } else { $Body }
            if (@($requestSet.requests).Count -gt 20) { throw 'A Graph JSON batch accepts at most 20 requests.' }
            $responses = foreach ($request in @($requestSet.requests)) {
                try { @{ id = [string]$request.id; status = 200; body = (Invoke-SimulatedGraph -Method ([string]$request.method) -Path ('/v1.0' + [string]$request.url)) } }
                catch { @{ id = [string]$request.id; status = 404; body = @{ error = @{ code = 'NotFound' } } } }
            }
            return @{ responses = @($responses) }
        }
        if ($Method -eq 'GET') {
            if ($decoded -match '^/v1\.0/organization\?') { return @{ value = @(@{ id = $script:tenant; displayName = 'Contoso' }) } }
            if ($decoded -match '^/v1\.0/(deviceManagement/windowsAutopilotDeviceIdentities|deviceManagement/managedDevices|devices|users)\?\$top=1') { return @{ value = @() } }
            if ($decoded -match "^/v1\.0/groups\?\`$filter=displayName eq '(.+?)'&") {
                $name = $Matches[1]
                return @{ value = @($sim.Groups.Values | Where-Object { $_.displayName -ceq $name }) }
            }
            if ($decoded -match "^/v1\.0/deviceManagement/windowsAutopilotDeviceIdentities\?\`$filter=contains\(serialNumber,'(.+?)'\)") {
                $sim.AutopilotSearches++
                $record = $sim.Autopilot[$Matches[1]]
                if ($null -eq $record -or $sim.AutopilotSearches -lt $sim.AutopilotVisibleFrom) { return @{ value = @() } }
                return @{ value = @($record) }
            }
            if ($decoded -match '^/v1\.0/deviceManagement/windowsAutopilotDeviceIdentities/([^/?]+)$') {
                $id = $Matches[1]
                $record = @($sim.Autopilot.Values | Where-Object { $_.id -eq $id })
                if ($record.Count -ne 1) { throw 'Simulated Autopilot identity not found.' }
                return $record[0]
            }
            if ($decoded -match "^/v1\.0/deviceManagement/managedDevices\?\`$filter=serialNumber eq '(.+?)'&") {
                $record = $sim.Managed[$Matches[1]]
                return @{ value = @(if ($record) { $record }) }
            }
            if ($decoded -match '^/v1\.0/deviceManagement/managedDevices/([^/?]+)/users\?') {
                return @{ value = @($sim.PrimaryUsers[$Matches[1]]) }
            }
            if ($decoded -match '^/v1\.0/deviceManagement/managedDevices/([^/?]+)\?\$select=') {
                $id = $Matches[1]
                $record = @($sim.Managed.Values | Where-Object { $_.id -eq $id })
                if ($record.Count -ne 1) { throw 'Simulated managed device not found.' }
                return $record[0]
            }
            if ($decoded -match "^/v1\.0/devices\?\`$filter=deviceId eq '(.+?)'&") {
                $record = $sim.Entra[$Matches[1]]
                return @{ value = @(if ($record) { $record }) }
            }
            if ($decoded -match '^/v1\.0/devices/([^/]+)/memberOf$') {
                return @{ value = @($sim.MemberOf[$Matches[1]] | ForEach-Object { $sim.Groups[$_] }) }
            }
            if ($decoded -match '^/v1\.0/groups/([^/?]+)\?\$select=id$') {
                if (-not $sim.Groups.ContainsKey($Matches[1])) { throw 'Simulated group not found.' }
                return @{ id = $Matches[1] }
            }
        }
        if ($Method -eq 'POST') {
            $payload = if ($Body -is [string]) { $Body | ConvertFrom-Json } else { $Body }
            if ($decoded -match '^/v1\.0/groups/([^/]+)/members/\$ref$') {
                $sim.MemberOf[([string]$payload.'@odata.id').Split('/')[-1]] += @($Matches[1])
                return $null
            }
            if ($decoded -match '^/v1\.0/deviceManagement/windowsAutopilotDeviceIdentities/([^/]+)/assignUserToDevice$') {
                $id = $Matches[1]
                @($sim.Autopilot.Values | Where-Object { $_.id -eq $id })[0].userPrincipalName = [string]$payload.userPrincipalName
                return $null
            }
            if ($decoded -match "^/v1\.0/deviceManagement/managedDevices\('([^']+)'\)/users/\`$ref$") {
                $userId = ([string]$payload.'@odata.id').Split('/')[-1]
                $sim.PrimaryUsers[$Matches[1]] = @(@{ id = $userId; displayName = 'Technician'; userPrincipalName = 'tech@contoso.com' })
                return $null
            }
        }
        if ($Method -eq 'DELETE') {
            if ($decoded -match '^/v1\.0/groups/([^/]+)/members/([^/]+)/\$ref$') {
                $groupId = $Matches[1]
                $sim.MemberOf[$Matches[2]] = @($sim.MemberOf[$Matches[2]] | Where-Object { $_ -ne $groupId })
                return $null
            }
            if ($decoded -match '^/v1\.0/deviceManagement/managedDevices/([^/?]+)$') {
                $id = $Matches[1]
                foreach ($serial in @($sim.Managed.Keys)) { if ($sim.Managed[$serial].id -eq $id) { $sim.Managed.Remove($serial) } }
                return $null
            }
        }
        throw ('Unexpected simulated Graph request: {0} {1}' -f $Method, $decoded)
    }

    function Invoke-MgGraphRequest {
        [CmdletBinding()]
        param($Method, $Uri, $Body, $ContentType, [System.Collections.IDictionary]$Headers)
        if ($null -ne $Body -and $ContentType -ne 'application/json') { throw ('Request body sent without a JSON content type: {0}' -f $ContentType) }
        foreach ($key in @(if ($Headers) { $Headers.Keys })) {
            if ($key -ne 'ConsistencyLevel' -or $Headers[$key] -ne 'eventual') { throw ('Unexpected request header: {0}' -f $key) }
        }
        $script:calls.Add(('{0} {1}' -f $Method, [uri]::UnescapeDataString([string]$Uri)))
        return Invoke-SimulatedGraph -Method $Method -Path $Uri -Body $Body
    }

    function Get-TestDevice {
        <#
        .SYNOPSIS
            Return a tenant-bound workflow record for the simulated device SERIAL1.
        .PARAMETER Fresh
            Return a record that has not been resolved yet (no saved identifiers).
        #>
        param([switch]$Fresh)
        $device = @{ Serial = 'SERIAL1'; TenantId = $script:tenant; AutopilotDeviceId = 'auto-1'; ManagedDeviceId = 'man-1'; AzureAdDeviceId = 'reg-1'; EntraDeviceId = 'obj-1'; IntuneDeviceName = 'PC1'; GroupTag = 'TAG'; Steps = @{}; AttemptHistory = @(); RecoveryHistory = @(); RecordId = 'rec-1'; BuildCycleId = 'cycle-1'; StartedAt = (Get-Date).ToString('o'); Status = 'active' }
        if ($Fresh) { foreach ($name in 'AutopilotDeviceId', 'ManagedDeviceId', 'AzureAdDeviceId', 'EntraDeviceId', 'IntuneDeviceName') { $device[$name] = '' } }
        return $device
    }

    function Invoke-StartupReadSequence {
        <#
        .SYNOPSIS
            Run the post-sign-in startup reads the same way Initialize-GraphSession does.
        #>
        if (Get-Command -Name Invoke-LiveStartupRead -CommandType Function -ErrorAction SilentlyContinue) { return @(Invoke-LiveStartupRead) }
        Initialize-LiveTenantContext
        return @(Test-GraphCapabilities)
    }

    function Measure-GraphCall {
        <#
        .SYNOPSIS
            Run one scenario and return how many Graph requests it sent.
        .PARAMETER Name
            Scenario label used in the saved results.
        .PARAMETER Action
            Script block holding the workflow action to measure.
        #>
        param([string]$Name, [scriptblock]$Action)
        $script:calls.Clear()
        $script:lastResult = & $Action
        $script:results[$Name] = [ordered]@{ Calls = $script:calls.Count; Requests = @($script:calls) }
        return $script:calls.Count
    }

    $script:results = [ordered]@{}
}

AfterAll {
    if ($env:GRAPH_BUDGET_OUT) { $script:results | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath $env:GRAPH_BUDGET_OUT -Encoding UTF8 }
}

Describe 'Graph call budget' {
    BeforeAll {
        Mock Write-Host {}
        Mock Write-Progress {}
        Mock Start-Sleep {}
    }
    BeforeEach {
        $script:logLines = [System.Collections.Generic.List[string]]::new()
        $script:prompts = [System.Collections.Generic.List[string]]::new()
        $script:savedRecords = @()
        $script:tenant = '11111111-1111-1111-1111-111111111111'
        $script:Runtime = @{ IsDemoMode = $false }
        $script:RuntimeConfig = @{ graph = @{ expectedTenantId = $script:tenant }; autopilot = @{ deploymentProfileDisplayName = 'Standard profile'; preProvisioningGroupDisplayName = 'Test pre-provisioning'; preProvisioningGroupPrefix = 'Test '; hashImport = @{ enabled = $false } } }
        $script:GraphSession = [ordered]@{ Connected = $true; RequiresReconnect = $false; IsSimulated = $false; TenantId = $script:tenant; TransportTimeoutSeconds = 60 }
        $script:Config = @{ MaxRetryAttempts = 5; RetryBackoffSeconds = 0; TransportMaxAttempts = 3; TransportBackoffSeconds = 2; TransportMaxDelaySeconds = 60; TransportTimeoutSeconds = 60; InventoryPollingMinutes = 5; GroupConflictExclusions = @() }
        $script:promptAnswer = 'Y'
        $script:calls = [System.Collections.Generic.List[string]]::new()
        $script:sim = @{
            AutopilotSearches    = 0
            AutopilotVisibleFrom = 0
            Autopilot            = @{ SERIAL1 = @{ id = 'auto-1'; serialNumber = 'SERIAL1'; azureActiveDirectoryDeviceId = 'reg-1'; managedDeviceId = 'man-1'; groupTag = 'TAG'; displayName = 'PC1'; userPrincipalName = '' } }
            Managed              = @{ SERIAL1 = @{ id = 'man-1'; deviceName = 'PC1'; serialNumber = 'SERIAL1'; userPrincipalName = ''; azureADDeviceId = 'reg-1'; ethernetMacAddress = '001122334455'; wiFiMacAddress = ''; operatingSystem = 'Windows'; osVersion = '10.0.26100.1'; lastSyncDateTime = '2025-11-07T00:00:00Z' } }
            Entra                = @{ 'reg-1' = @{ id = 'obj-1'; deviceId = 'reg-1'; displayName = 'PC1' } }
            Groups               = @{ 'group-1' = (Get-SimulatedGroup -Id 'group-1' -Name 'Test pre-provisioning'); 'conf-a' = (Get-SimulatedGroup -Id 'conf-a' -Name 'Test old site A'); 'conf-b' = (Get-SimulatedGroup -Id 'conf-b' -Name 'Test old site B') }
            MemberOf             = @{ 'obj-1' = @() }
            PrimaryUsers         = @{ 'man-1' = @() }
        }
        $script:user = @{ Id = 'user-1'; UserPrincipalName = 'tech@contoso.com'; DisplayName = 'Technician' }
    }

    Context 'Startup after sign-in' {
        It 'reads organisation, permissions and the pre-provisioning group in one request' {
            $count = Measure-GraphCall -Name 'Startup reads after sign-in' -Action { Invoke-StartupReadSequence }
            @($script:lastResult | Where-Object { -not $_.Success }).Count | Should -Be 0
            $script:Config.OrganisationName | Should -Be 'Contoso'
            $count | Should -Be 1
        }
    }

    Context 'Device identity refresh' {
        It 'refreshes a known device without re-reading its unchanged Entra object' {
            $device = Get-TestDevice
            $count = Measure-GraphCall -Name 'Identity refresh (known device)' -Action { Resolve-LiveAutopilotContext -Device $device }
            $device.EntraDeviceId | Should -Be 'obj-1'
            $device.ManagedDeviceId | Should -Be 'man-1'
            $count | Should -Be 2
        }
        It 'still reads the Entra object when the device registration has changed' {
            $device = Get-TestDevice
            $device.AzureAdDeviceId = 'reg-old'
            $device.EntraDeviceId = 'obj-old'
            $count = Measure-GraphCall -Name 'Identity refresh (registration changed)' -Action { Resolve-LiveAutopilotContext -Device $device }
            $device.EntraDeviceId | Should -Be 'obj-1'
            $count | Should -Be 3
        }
    }

    Context 'Step A: find the device in Autopilot after upload' {
        It 'polls Autopilot only until the upload appears, then completes the identity once' {
            $script:sim.Autopilot.SERIAL1.azureActiveDirectoryDeviceId = 'reg-1'
            $script:sim.Managed.Clear()
            $script:sim.AutopilotVisibleFrom = 4
            $device = Get-TestDevice -Fresh
            $count = Measure-GraphCall -Name 'Step A (upload appears on third poll)' -Action { Invoke-StepResolveAutopilotDevice -Device $device -StepDefinition @{ Id = 'A'; ActionName = 'ResolveAutopilotDevice' } }
            $script:lastResult.Success | Should -BeTrue
            $device.AutopilotDeviceId | Should -Be 'auto-1'
            $device.EntraDeviceId | Should -Be 'obj-1'
            $count | Should -Be 7
        }
    }

    Context 'Step B: remove the old Intune record' {
        It 'deletes and verifies an existing managed device' {
            $device = Get-TestDevice
            $count = Measure-GraphCall -Name 'Step B (delete existing record)' -Action { Invoke-StepRemoveAssociatedManagedDevice -Device $device -StepDefinition @{ Id = 'B'; ActionName = 'RemoveAssociatedManagedDevice' } }
            $script:lastResult.Success | Should -BeTrue
            $script:sim.Managed.ContainsKey('SERIAL1') | Should -BeFalse
            $count | Should -Be 4
        }
        It 'confirms there is nothing to delete without searching twice' {
            $script:sim.Managed.Clear()
            $device = Get-TestDevice
            $count = Measure-GraphCall -Name 'Step B (nothing to delete)' -Action { Invoke-StepRemoveAssociatedManagedDevice -Device $device -StepDefinition @{ Id = 'B'; ActionName = 'RemoveAssociatedManagedDevice' } }
            $script:lastResult.Success | Should -BeTrue
            $script:lastResult.Summary | Should -Match 'No associated Intune device'
            $count | Should -Be 2
        }
    }

    Context 'Steps I and O: primary user' {
        It 'only reads when the user is already assigned on both surfaces' {
            $script:sim.Autopilot.SERIAL1.userPrincipalName = 'tech@contoso.com'
            $script:sim.PrimaryUsers['man-1'] = @(@{ id = 'user-1'; displayName = 'Technician'; userPrincipalName = 'tech@contoso.com' })
            $device = Get-TestDevice
            $count = Measure-GraphCall -Name 'Primary user (already assigned)' -Action { Invoke-LivePrimaryUserAssignment -Device $device -User $script:user }
            $script:lastResult.AutopilotAssigned | Should -BeTrue
            $script:lastResult.ManagedDeviceConfirmed | Should -BeTrue
            $script:lastResult.Errors.Count | Should -Be 0
            $count | Should -Be 3
        }
        It 'assigns and verifies both surfaces for a new user' {
            $device = Get-TestDevice
            $count = Measure-GraphCall -Name 'Primary user (new assignment)' -Action { Invoke-LivePrimaryUserAssignment -Device $device -User $script:user }
            $script:lastResult.AutopilotAssigned | Should -BeTrue
            $script:lastResult.ManagedDeviceConfirmed | Should -BeTrue
            $count | Should -Be 7
        }
    }

    Context 'Steps D and J: pre-provisioning group membership' {
        BeforeEach {
            # Real sessions always run the startup reads first; measure the step on its own.
            $null = Invoke-StartupReadSequence
        }
        It 'adds the device to the group (step D)' {
            $device = Get-TestDevice
            $count = Measure-GraphCall -Name 'Step D (add to group)' -Action { Invoke-StepAddPreProvisioningGroup -Device $device -StepDefinition @{ Id = 'D'; ActionName = 'AddToPreProvisioningGroup' } }
            $script:lastResult.CompletionState | Should -Be 'Verified'
            $script:sim.MemberOf['obj-1'] | Should -Contain 'group-1'
            $count | Should -Be 4
        }
        It 'confirms an existing membership with reads only (step D repeated)' {
            $script:sim.MemberOf['obj-1'] = @('group-1')
            $device = Get-TestDevice
            $count = Measure-GraphCall -Name 'Step D (already a member)' -Action { Invoke-StepAddPreProvisioningGroup -Device $device -StepDefinition @{ Id = 'D'; ActionName = 'AddToPreProvisioningGroup' } }
            $script:lastResult.CompletionState | Should -Be 'Verified'
            $count | Should -Be 2
        }
        It 'removes the device from the group (step J)' {
            $script:sim.MemberOf['obj-1'] = @('group-1')
            $device = Get-TestDevice
            $count = Measure-GraphCall -Name 'Step J (remove from group)' -Action { Invoke-StepRemovePreProvisioningGroup -Device $device -StepDefinition @{ Id = 'J'; ActionName = 'RemoveFromPreProvisioningGroup' } }
            $script:lastResult.CompletionState | Should -Be 'Verified'
            $script:sim.MemberOf['obj-1'] | Should -Not -Contain 'group-1'
            $count | Should -Be 4
        }
        It 'removes two conflicting memberships, then adds the device (step D)' {
            $script:sim.MemberOf['obj-1'] = @('conf-a', 'conf-b')
            $device = Get-TestDevice
            $count = Measure-GraphCall -Name 'Step D (two conflicting groups)' -Action { Invoke-StepAddPreProvisioningGroup -Device $device -StepDefinition @{ Id = 'D'; ActionName = 'AddToPreProvisioningGroup' } }
            $script:lastResult.CompletionState | Should -Be 'Verified'
            @($script:sim.MemberOf['obj-1']) | Should -Be @('group-1')
            $count | Should -Be 7
        }
    }

    Context 'Intune device details (hostname and network addresses)' {
        BeforeEach {
            $script:records = @(for ($index = 1; $index -le 45; $index++) {
                    $serial = 'SER{0:D3}' -f $index
                    $script:sim.Managed[$serial] = @{ id = ('man-{0:D3}' -f $index); deviceName = ('PC{0:D3}' -f $index); serialNumber = $serial; userPrincipalName = ''; azureADDeviceId = ('reg-{0:D3}' -f $index); ethernetMacAddress = ('0011223344{0:X2}' -f $index); wiFiMacAddress = ''; operatingSystem = 'Windows'; osVersion = '10.0.26100.1'; lastSyncDateTime = '2025-11-07T00:00:00Z' }
                    # Five older records never saved their Intune ID, so they need a serial search first.
                    $managedId = if ($index -le 40) { 'man-{0:D3}' -f $index } else { '' }
                    @{ Serial = $serial; TenantId = $script:tenant; ManagedDeviceId = $managedId; AzureAdDeviceId = ('reg-{0:D3}' -f $index); RecordId = ('rec-{0:D3}' -f $index); BuildCycleId = 'cycle-1'; Status = 'completed'; Steps = @{}; IntuneInventory = @{} }
                })
        }
        It 'fills in missing details for 45 devices (Data Settings > 5)' {
            $container = @{ Value = $script:records }
            $count = Measure-GraphCall -Name 'Update device details (45 devices)' -Action { Update-DeviceInventoryFromIntune -Records $container }
            $script:lastResult.Checked | Should -Be 45
            $script:lastResult.Updated | Should -Be 45
            $script:lastResult.Errors | Should -Be 0
            $count | Should -Be 4
        }
        It 'collects details for 12 devices due in the automatic check' {
            $due = @($script:records | Select-Object -First 12)
            foreach ($record in $due) { $record.Status = 'active'; $record.Steps = @{ R = @{ Success = $true; CompletionState = 'Verified' } } }
            $container = @{ Value = $due }
            $count = Measure-GraphCall -Name 'Automatic detail check (12 devices due)' -Action { Invoke-DeviceInventoryPolling -Records $container }
            @($due | Where-Object { $_.IntuneInventory.Status -eq 'Available' }).Count | Should -Be 12
            $count | Should -Be 1
        }
    }
}
