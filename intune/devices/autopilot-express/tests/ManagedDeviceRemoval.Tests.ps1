<#
.SYNOPSIS
    Isolated managed-device deletion and serial lookup regression tests.
.DESCRIPTION
    Extracts functions without starting the CLI. No tenant writes, operational
    records or real pauses occur. Requires Pester 5 in FullLanguage.
#>
BeforeAll {
    $sourcePath = Join-Path (Split-Path -Parent $PSScriptRoot) 'autopilot-express.ps1'
    $tokens = $null
    $parseErrors = $null
    $sourceAst = [System.Management.Automation.Language.Parser]::ParseFile($sourcePath, [ref]$tokens, [ref]$parseErrors)
    if ($parseErrors.Count) { throw ($parseErrors.Message -join '; ') }
    foreach ($functionName in @('ConvertTo-RecordDate', 'Get-GraphTransportFailure', 'Get-GraphOperationFailureMessage', 'New-OperationResult', 'Get-GraphVerificationPolicy', 'Wait-ManagedDeviceRemovalVerification', 'Invoke-StepRemoveAssociatedManagedDevice', 'Get-ManagedDeviceSerialLookupUri')) {
        $definition = $sourceAst.Find({ param($node) $node -is [System.Management.Automation.Language.FunctionDefinitionAst] -and $node.Name -eq $functionName }, $true)
        if ($null -eq $definition) { throw ('Missing function: {0}' -f $functionName) }
        Set-Item -Path ('Function:{0}' -f $definition.Name) -Value $definition.Body.GetScriptBlock()
    }
    function Resolve-LiveManagedDeviceBySerial { param($Serial) throw ('Unexpected lookup: {0}' -f $Serial) }
    function Resolve-LiveAutopilotContext { param($Device) throw ('Unexpected context: {0}' -f $Device.Serial) }
    function Read-ValidatedInput { param($Prompt, $Default, $Type, $Choices) throw ('Unexpected prompt: {0}, {1}, {2}, {3}' -f $Prompt, $Default, $Type, ($Choices -join ',')) }
    function Invoke-GraphApiRequest { param($Method, $Uri) throw ('Unexpected Graph: {0} {1}' -f $Method, $Uri) }
    function Remove-MgDeviceManagementManagedDevice {
        [CmdletBinding(SupportsShouldProcess)]
        param([string]$ManagedDeviceId)
        if ($PSCmdlet.ShouldProcess($ManagedDeviceId, 'Delete test device')) { throw 'Unexpected SDK delete.' }
    }
}

Describe 'Managed-device removal outcomes' {
    BeforeEach {
        $script:Runtime = @{ IsDemoMode = $false }
        $script:Config = @{ MaxRetryAttempts = 3; RetryBackoffSeconds = 2 }
        $script:device = @{ Serial = 'SERIAL1'; ManagedDeviceId = 'managed-1'; IntuneDeviceName = 'Test device' }
        $script:step = @{ Id = 'B'; ActionName = 'RemoveAssociatedManagedDevice' }
        $script:reads = 0
        Mock Start-Sleep {}
        Mock Read-ValidatedInput { return 'Y' }
        Mock Get-Command { return $null } -ParameterFilter { $Name -eq 'Remove-MgDeviceManagementManagedDevice' }
        Mock Invoke-GraphApiRequest {}
        Mock Remove-MgDeviceManagementManagedDevice {}
        Mock Resolve-LiveManagedDeviceBySerial { return $null }
        Mock Resolve-LiveAutopilotContext { return @{ Managed = @{ id = 'managed-1' } } }
    }
    It 'verifies immediate absence with one REST deletion and no pause' {
        $result = Invoke-StepRemoveAssociatedManagedDevice -Device $script:device -StepDefinition $script:step
        $result.CompletionState | Should -Be 'Verified'
        $result.Data.ManagedDeviceId | Should -Be 'managed-1'
        $result.Data.Submitted | Should -BeTrue
        $script:device.ManagedDeviceId | Should -Be ''
        $script:device.IntuneDeviceName | Should -Be ''
        Should -Invoke Invoke-GraphApiRequest -Times 1 -Exactly -ParameterFilter { $Method -eq 'DELETE' -and $Uri -eq 'https://graph.microsoft.com/v1.0/deviceManagement/managedDevices/managed-1' }
        Should -Invoke Start-Sleep -Times 0 -Exactly
    }
    It 'polls delayed disappearance without repeating deletion' {
        Mock Resolve-LiveManagedDeviceBySerial { $script:reads++; if ($script:reads -lt 3) { return @{ id = 'managed-1' } }; return $null }
        $result = Invoke-StepRemoveAssociatedManagedDevice -Device $script:device -StepDefinition $script:step
        $result.CompletionState | Should -Be 'Verified'
        $result.Data.VerificationAttempts | Should -Be 3
        Should -Invoke Invoke-GraphApiRequest -Times 1 -Exactly
        Should -Invoke Start-Sleep -Times 2 -Exactly -ParameterFilter { $Seconds -eq 2 }
    }
    It 'preserves identifiers and submission evidence after exhaustion' {
        Mock Resolve-LiveManagedDeviceBySerial { return @{ id = 'managed-1' } }
        $result = Invoke-StepRemoveAssociatedManagedDevice -Device $script:device -StepDefinition $script:step
        $result.CompletionState | Should -Be 'Submitted'
        $result.Data.ObservedManagedDeviceId | Should -Be 'managed-1'
        $script:device.ManagedDeviceId | Should -Be 'managed-1'
        Should -Invoke Invoke-GraphApiRequest -Times 1 -Exactly
        Should -Invoke Start-Sleep -Times 2 -Exactly
    }
    It 'never deletes a replacement device observed during verification' {
        Mock Resolve-LiveManagedDeviceBySerial { return @{ id = 'replacement-2' } }
        $result = Invoke-StepRemoveAssociatedManagedDevice -Device $script:device -StepDefinition $script:step
        $result.CompletionState | Should -Be 'Submitted'
        $result.Data.ObservedManagedDeviceId | Should -Be 'replacement-2'
        Should -Invoke Invoke-GraphApiRequest -Times 1 -Exactly
    }
    It 'fails fast on post-write read errors with submission evidence' {
        Mock Resolve-LiveManagedDeviceBySerial { throw 'Read denied' }
        $result = Invoke-StepRemoveAssociatedManagedDevice -Device $script:device -StepDefinition $script:step
        $result.CompletionState | Should -Be 'Submitted'
        $result.Data.Submitted | Should -BeTrue
        $script:device.ManagedDeviceId | Should -Be 'managed-1'
        Should -Invoke Start-Sleep -Times 0 -Exactly
    }
    It 'rechecks an accepted deletion without prompting or deleting again' {
        $script:device.Steps = @{ B = @{ Data = @{ Serial = 'SERIAL1'; ManagedDeviceId = 'managed-1'; Submitted = $true } } }
        $result = Invoke-StepRemoveAssociatedManagedDevice -Device $script:device -StepDefinition $script:step
        $result.CompletionState | Should -Be Verified
        $result.Data.Submitted | Should -BeTrue
        Should -Invoke Invoke-GraphApiRequest -Times 0 -Exactly
        Should -Invoke Remove-MgDeviceManagementManagedDevice -Times 0 -Exactly
        Should -Invoke Resolve-LiveAutopilotContext -Times 0 -Exactly
        Should -Invoke Read-ValidatedInput -Times 0 -Exactly
    }
    It 'keeps a replacement unverified and never deletes it after an accepted deletion' {
        $script:device.Steps = @{ B = @{ Data = @{ Serial = 'SERIAL1'; ManagedDeviceId = 'managed-1'; Submitted = $true } } }
        Mock Resolve-LiveManagedDeviceBySerial { @{ id = 'replacement' } }
        $result = Invoke-StepRemoveAssociatedManagedDevice -Device $script:device -StepDefinition $script:step
        $result.CompletionState | Should -Be Submitted
        $result.Data.ObservedManagedDeviceId | Should -Be replacement
        Should -Invoke Invoke-GraphApiRequest -Times 0 -Exactly
    }
    It 'recovers accepted same-cycle history after a later failure lost its latest submission flag' {
        $script:device.RecordId = 'record-one'; $script:device.TenantId = 'tenant-one'; $script:device.StartedAt = [datetime]'2026-10-27T09:00:00'
        $script:device.Steps = @{ B = @{ Data = @{ Serial = 'SERIAL1'; ManagedDeviceId = 'managed-1'; Submitted = $false } } }
        $script:device.AttemptHistory = @(@{
                Sequence = 1; AttemptId = 'accepted-attempt'; StepId = 'B'; ActionName = 'RemoveAssociatedManagedDevice'; EvidenceKind = 'HandlerOutcome'
                RecordId = 'record-one'; TenantId = 'tenant-one'; Serial = 'SERIAL1'; Timestamp = '2026-10-27T10:00:00'
                Result = @{ ActionName = 'RemoveAssociatedManagedDevice'; IsSimulated = $false; Data = @{ Submitted = $true; Serial = 'SERIAL1'; ManagedDeviceId = 'managed-1' } }
            })
        $before = $script:device.AttemptHistory | ConvertTo-Json -Depth 10 -Compress
        $result = Invoke-StepRemoveAssociatedManagedDevice -Device $script:device -StepDefinition $script:step
        $result.CompletionState | Should -Be Verified
        $result.Data.RecoveredAttemptId | Should -BeExactly accepted-attempt
        $result.Data.Submitted | Should -BeTrue
        ($script:device.AttemptHistory | ConvertTo-Json -Depth 10 -Compress) | Should -BeExactly $before
        Should -Invoke Invoke-GraphApiRequest -Times 0 -Exactly
        Should -Invoke Read-ValidatedInput -Times 0 -Exactly
        Should -Invoke Resolve-LiveAutopilotContext -Times 0 -Exactly
    }
    It 'does not reuse accepted history from before the current start or recovery close' -ForEach @(
        @{ Boundary = 'start' }, @{ Boundary = 'recovery close' }
    ) {
        $script:device.RecordId = 'record-one'; $script:device.TenantId = 'tenant-one'; $script:device.StartedAt = [datetime]'2026-10-27T11:00:00'
        if ($Boundary -eq 'recovery close') { $script:device.StartedAt = [datetime]'2026-10-27T09:00:00'; $script:device.RecoveryHistory = @(@{ Stage = 'RecoveryClosed'; Timestamp = '2026-10-27T11:00:00' }) }
        $script:device.AttemptHistory = @(@{
                Sequence = 1; StepId = 'B'; ActionName = 'RemoveAssociatedManagedDevice'; EvidenceKind = 'HandlerOutcome'
                RecordId = 'record-one'; TenantId = 'tenant-one'; Serial = 'SERIAL1'; Timestamp = '2026-10-27T10:00:00'
                Result = @{ ActionName = 'RemoveAssociatedManagedDevice'; IsSimulated = $false; Data = @{ Submitted = $true; Serial = 'SERIAL1'; ManagedDeviceId = 'old-target' } }
            })
        $result = Invoke-StepRemoveAssociatedManagedDevice -Device $script:device -StepDefinition $script:step
        $result.CompletionState | Should -Be Verified
        $result.Data.ManagedDeviceId | Should -BeExactly managed-1
        Should -Invoke Invoke-GraphApiRequest -Times 1 -Exactly
        Should -Invoke Read-ValidatedInput -Times 1 -Exactly
    }
    It 'refuses a second delete when accepted history cannot be safely dated' {
        $script:device.RecordId = 'record-one'; $script:device.TenantId = 'tenant-one'
        $script:device.AttemptHistory = @(@{ StepId = 'B'; ActionName = 'RemoveAssociatedManagedDevice'; EvidenceKind = 'HandlerOutcome'; Result = @{ Data = @{ Submitted = $true } } })
        $result = Invoke-StepRemoveAssociatedManagedDevice -Device $script:device -StepDefinition $script:step
        $result.CompletionState | Should -Be Failed
        Should -Invoke Invoke-GraphApiRequest -Times 0 -Exactly
        Should -Invoke Read-ValidatedInput -Times 0 -Exactly
    }
    It 'reconciles an exact DELETE 404 only using a successful empty serial search' {
        Mock Invoke-GraphApiRequest { throw 'Structured synthetic DELETE failure' }
        Mock Get-GraphTransportFailure { @{ Status = '404'; RequestId = 'synthetic-request' } }
        $result = Invoke-StepRemoveAssociatedManagedDevice -Device $script:device -StepDefinition $script:step
        $result.CompletionState | Should -Be Verified
        $result.Data.Submitted | Should -BeFalse
        $result.Data.DeleteNotFound | Should -BeTrue
        Should -Invoke Resolve-LiveManagedDeviceBySerial -Times 1 -Exactly
        Should -Invoke Invoke-GraphApiRequest -Times 1 -Exactly
    }
    It 'does not turn a DELETE 404 followed by failed discovery into success' {
        Mock Invoke-GraphApiRequest { throw 'Structured synthetic DELETE failure' }
        Mock Get-GraphTransportFailure { @{ Status = '404'; RequestId = 'synthetic-request' } }
        Mock Resolve-LiveManagedDeviceBySerial { throw 'Discovery unavailable' }
        $result = Invoke-StepRemoveAssociatedManagedDevice -Device $script:device -StepDefinition $script:step
        $result.CompletionState | Should -Be Failed
        $script:device.ManagedDeviceId | Should -Be managed-1
    }
    It 'does not repeat a prior DELETE 404 while serial discovery remains stale' {
        $script:device.Steps = @{ B = @{ Data = @{ Serial = 'SERIAL1'; ManagedDeviceId = 'managed-1'; Submitted = $false; DeleteNotFound = $true; RequestId = 'original-request' } } }
        Mock Resolve-LiveManagedDeviceBySerial { @{ id = 'managed-1' } }
        $result = Invoke-StepRemoveAssociatedManagedDevice -Device $script:device -StepDefinition $script:step
        $result.CompletionState | Should -Be Submitted
        $result.Data.Submitted | Should -BeFalse
        $result.Data.DeleteNotFound | Should -BeTrue
        $result.Data.RequestId | Should -BeExactly original-request
        Should -Invoke Invoke-GraphApiRequest -Times 0 -Exactly
        Should -Invoke Read-ValidatedInput -Times 0 -Exactly
    }
    It 'does not delete a replacement when accepted intent is recovered from history' {
        $script:device.RecordId = 'record-one'; $script:device.TenantId = 'tenant-one'; $script:device.StartedAt = [datetime]'2026-10-27T09:00:00'
        $script:device.AttemptHistory = @(@{
                Sequence = 1; AttemptId = 'accepted-attempt'; StepId = 'B'; ActionName = 'RemoveAssociatedManagedDevice'; EvidenceKind = 'HandlerOutcome'
                RecordId = 'record-one'; TenantId = 'tenant-one'; Serial = 'SERIAL1'; Timestamp = '2026-10-27T10:00:00'
                Result = @{ ActionName = 'RemoveAssociatedManagedDevice'; IsSimulated = $false; Data = @{ Submitted = $true; Serial = 'SERIAL1'; ManagedDeviceId = 'managed-1' } }
            })
        Mock Resolve-LiveManagedDeviceBySerial { @{ id = 'replacement' } }
        $result = Invoke-StepRemoveAssociatedManagedDevice -Device $script:device -StepDefinition $script:step
        $result.CompletionState | Should -Be Submitted
        $result.Data.ObservedManagedDeviceId | Should -BeExactly replacement
        Should -Invoke Invoke-GraphApiRequest -Times 0 -Exactly
        Should -Invoke Read-ValidatedInput -Times 0 -Exactly
    }
    It 'refuses cross-tenant accepted history rather than deleting again' {
        $script:device.RecordId = 'record-one'; $script:device.TenantId = 'tenant-one'; $script:device.StartedAt = [datetime]'2026-10-27T09:00:00'
        $script:device.AttemptHistory = @(@{
                StepId = 'B'; ActionName = 'RemoveAssociatedManagedDevice'; EvidenceKind = 'HandlerOutcome'
                RecordId = 'record-one'; TenantId = 'different-tenant'; Serial = 'SERIAL1'; Timestamp = '2026-10-27T10:00:00'
                Result = @{ ActionName = 'RemoveAssociatedManagedDevice'; Data = @{ Submitted = $true } }
            })
        $result = Invoke-StepRemoveAssociatedManagedDevice -Device $script:device -StepDefinition $script:step
        $result.CompletionState | Should -Be Failed
        Should -Invoke Invoke-GraphApiRequest -Times 0 -Exactly
        Should -Invoke Read-ValidatedInput -Times 0 -Exactly
    }
    It 'compares workflow and historical boundaries by instant across UTC and offset dates' {
        $script:device.RecordId = 'record-one'; $script:device.TenantId = 'tenant-one'; $script:device.StartedAt = [datetime]'2026-10-27T09:00:00Z'
        $script:device.AttemptHistory = @(@{
                Sequence = 1; StepId = 'B'; ActionName = 'RemoveAssociatedManagedDevice'; EvidenceKind = 'HandlerOutcome'
                RecordId = 'record-one'; TenantId = 'tenant-one'; Serial = 'SERIAL1'; Timestamp = '2026-10-27T10:00:00+08:00'
                Result = @{ ActionName = 'RemoveAssociatedManagedDevice'; Data = @{ Submitted = $true; Serial = 'SERIAL1'; ManagedDeviceId = 'old-target' } }
            })
        $result = Invoke-StepRemoveAssociatedManagedDevice -Device $script:device -StepDefinition $script:step
        $result.CompletionState | Should -Be Verified
        $result.Data.ManagedDeviceId | Should -BeExactly managed-1
        Should -Invoke Invoke-GraphApiRequest -Times 1 -Exactly
    }
    It 'does not poll after a rejected delete' {
        Mock Invoke-GraphApiRequest { throw 'Delete denied' }
        $result = Invoke-StepRemoveAssociatedManagedDevice -Device $script:device -StepDefinition $script:step
        $result.CompletionState | Should -Be 'Failed'
        $result.Data.Submitted | Should -BeFalse
        Should -Invoke Resolve-LiveManagedDeviceBySerial -Times 0 -Exactly
    }
    It 'keeps the SDK path single-write and does not issue REST deletion' {
        Mock Get-Command { return @{ Name = 'Remove-MgDeviceManagementManagedDevice' } } -ParameterFilter { $Name -eq 'Remove-MgDeviceManagementManagedDevice' }
        $result = Invoke-StepRemoveAssociatedManagedDevice -Device $script:device -StepDefinition $script:step
        $result.CompletionState | Should -Be 'Verified'
        Should -Invoke Remove-MgDeviceManagementManagedDevice -Times 1 -Exactly -ParameterFilter { $ManagedDeviceId -eq 'managed-1' }
        Should -Invoke Invoke-GraphApiRequest -Times 0 -Exactly
    }
    It 'respects cancellation without writes or verification reads' {
        Mock Read-ValidatedInput { return 'n' }
        $result = Invoke-StepRemoveAssociatedManagedDevice -Device $script:device -StepDefinition $script:step
        $result.Success | Should -BeFalse
        $script:device.ManagedDeviceId | Should -Be 'managed-1'
        Should -Invoke Invoke-GraphApiRequest -Times 0 -Exactly
        Should -Invoke Resolve-LiveManagedDeviceBySerial -Times 0 -Exactly
    }
    It 'verifies an already-absent device without a prompt or write' {
        $script:device.ManagedDeviceId = ''
        Mock Resolve-LiveAutopilotContext { return @{ Managed = $null } }
        $result = Invoke-StepRemoveAssociatedManagedDevice -Device $script:device -StepDefinition $script:step
        $result.CompletionState | Should -Be 'Verified'
        $result.Data.Submitted | Should -BeFalse
        Should -Invoke Read-ValidatedInput -Times 0 -Exactly
        Should -Invoke Invoke-GraphApiRequest -Times 0 -Exactly
    }
    It 'trusts the one fresh identity read and never deletes a record it did not resolve' {
        # The identity refresh already includes the managed-device serial search, so a
        # second search (which could only disagree through a race) is no longer made.
        $script:device.ManagedDeviceId = ''
        Mock Resolve-LiveAutopilotContext { return @{ Managed = $null } }
        Mock Resolve-LiveManagedDeviceBySerial { return @{ id = 'unexpected' } }
        $result = Invoke-StepRemoveAssociatedManagedDevice -Device $script:device -StepDefinition $script:step
        $result.CompletionState | Should -Be 'Verified'
        $result.Data.Submitted | Should -BeFalse
        Should -Invoke Resolve-LiveManagedDeviceBySerial -Times 0 -Exactly
        Should -Invoke Invoke-GraphApiRequest -Times 0 -Exactly
    }
    It 'refreshes a cached deletion target before confirmation and deletes only the current ID' {
        Mock Resolve-LiveAutopilotContext { $Device.ManagedDeviceId = 'current-2'; return @{ Managed = @{ id = 'current-2' } } }
        $result = Invoke-StepRemoveAssociatedManagedDevice -Device $script:device -StepDefinition $script:step
        $result.CompletionState | Should -Be 'Verified'
        Should -Invoke Resolve-LiveAutopilotContext -Times 1 -Exactly
        Should -Invoke Invoke-GraphApiRequest -Times 1 -Exactly -ParameterFilter { $Uri -eq 'https://graph.microsoft.com/v1.0/deviceManagement/managedDevices/current-2' }
    }
    It 'does not prompt or delete a cached target after a failed identity refresh' {
        Mock Resolve-LiveAutopilotContext { throw 'Ambiguous current serial' }
        $result = Invoke-StepRemoveAssociatedManagedDevice -Device $script:device -StepDefinition $script:step
        $result.CompletionState | Should -Be 'Failed'
        Should -Invoke Read-ValidatedInput -Times 0 -Exactly
        Should -Invoke Invoke-GraphApiRequest -Times 0 -Exactly
    }
    It 'rejects invalid policy before prompting or looking up context' {
        $script:Config.MaxRetryAttempts = 0
        $result = Invoke-StepRemoveAssociatedManagedDevice -Device $script:device -StepDefinition $script:step
        $result.CompletionState | Should -Be 'Failed'
        Should -Invoke Read-ValidatedInput -Times 0 -Exactly
        Should -Invoke Resolve-LiveAutopilotContext -Times 0 -Exactly
    }
    It 'keeps Demo isolated and clears simulated context' {
        $script:Runtime.IsDemoMode = $true
        $result = Invoke-StepRemoveAssociatedManagedDevice -Device $script:device -StepDefinition $script:step
        $result.CompletionState | Should -Be 'Simulated'
        $script:device.ManagedDeviceId | Should -Be ''
        Should -Invoke Invoke-GraphApiRequest -Times 0 -Exactly
        Should -Invoke Read-ValidatedInput -Times 0 -Exactly
    }
}

Describe 'Managed-device serial lookup evidence' {
    BeforeAll {
        $definition = $sourceAst.FindAll({ param($node) $node -is [System.Management.Automation.Language.FunctionDefinitionAst] -and $node.Name -in @('Resolve-LiveManagedDeviceBySerial', 'Get-ManagedDeviceSerialLookupUri') }, $true)
        foreach ($item in @($definition)) { Set-Item -Path ('Function:{0}' -f $item.Name) -Value $item.Body.GetScriptBlock() }
    }
    It 'accepts only a valid empty response as absence' {
        Mock Invoke-GraphApiRequest { return @{ value = @() } }
        Resolve-LiveManagedDeviceBySerial -Serial 'SERIAL1' | Should -BeNullOrEmpty
    }
    It 'returns the uniquely matched identity' {
        Mock Invoke-GraphApiRequest { return @{ value = @(@{ id = 'managed-1'; serialNumber = 'SERIAL1' }) } }
        (Resolve-LiveManagedDeviceBySerial -Serial 'SERIAL1').id | Should -Be 'managed-1'
    }
    It 'rejects malformed, incomplete or inconsistent responses: <Label>' -TestCases @(
        @{ Label = 'null body'; Response = $null }
        @{ Label = 'missing value'; Response = @{} }
        @{ Label = 'null value'; Response = @{ value = $null } }
        @{ Label = 'continuation'; Response = @{ value = @(); '@odata.nextLink' = 'https://graph.microsoft.com/next' } }
        @{ Label = 'duplicate'; Response = @{ value = @(@{ id = 'one'; serialNumber = 'SERIAL1' }, @{ id = 'two'; serialNumber = 'SERIAL1' }) } }
        @{ Label = 'missing id'; Response = @{ value = @(@{ serialNumber = 'SERIAL1' }) } }
        @{ Label = 'wrong serial'; Response = @{ value = @(@{ id = 'one'; serialNumber = 'OTHER' }) } }
    ) {
        param($Response)
        $script:lookupResponse = $Response
        Mock Invoke-GraphApiRequest { return $script:lookupResponse }
        { Resolve-LiveManagedDeviceBySerial -Serial 'SERIAL1' } | Should -Throw
    }
}