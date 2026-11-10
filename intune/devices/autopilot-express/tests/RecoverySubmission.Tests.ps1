<#
.SYNOPSIS
    Tests durable recovery-unblock intent and guided reconciliation.
.DESCRIPTION
    Uses the production handlers and an isolated JSON store. Graph requests,
    tenant validation and technician input are mocked; no tenant action occurs.
.FILECREATED
    2026-11-04
.FILELASTUPDATED
    2026-11-04
#>
BeforeAll {
    $sourcePath = Join-Path (Split-Path -Parent $PSScriptRoot) 'autopilot-express.ps1'
    $tokens = $null; $parseErrors = $null
    $sourceAst = [System.Management.Automation.Language.Parser]::ParseFile($sourcePath, [ref]$tokens, [ref]$parseErrors)
    if ($parseErrors.Count) { throw ($parseErrors.Message -join '; ') }
    foreach ($name in @(
            'New-EmptyDeviceRecord', 'New-OperationResult', 'ConvertTo-NormalisedValue', 'ConvertTo-StepHashtable',
            'ConvertTo-RecordDate', 'ConvertTo-PersistedDate', 'ConvertTo-PersistedDeviceRecord', 'Assert-AttemptHistory', 'Test-AttemptEvidenceEqual',
            'Assert-AttemptHistoryPreserved', 'Save-DeviceLedgerEntry', 'Get-RecoverySubmissionEvidence',
            'Save-RecoverySubmissionEvidence', 'Invoke-StepClearUserlessEnrollmentStatus',
            'Invoke-StepConfirmRecoveryReadiness', 'Get-AffectedWorkflowStepId', 'Write-ManifestStepResult', 'Test-CompletionStateComplete',
            'Get-GraphTransportFailure', 'Get-GraphOperationFailureMessage'
        )) {
        $definition = $sourceAst.Find({ param($node) $node -is [System.Management.Automation.Language.FunctionDefinitionAst] -and $node.Name -eq $name }, $true)
        if ($null -eq $definition) { throw ('Missing function: {0}' -f $name) }
        Set-Item -Path ('Function:{0}' -f $name) -Value $definition.Body.GetScriptBlock()
    }
    function Get-LiveTenantBinding { param($Device) throw ('Unexpected tenant validation: {0}' -f $Device.Serial) }
    function Resolve-LiveAutopilotContext { param($Device) throw ('Unexpected refresh: {0}' -f $Device.Serial) }
    function Resolve-LiveManagedDeviceBySerial { param($Serial) throw ('Unexpected lookup: {0}' -f $Serial) }
    function Invoke-GraphApiRequest { param($Method, $Uri) throw ('Unexpected request: {0} {1}' -f $Method, $Uri) }
    function Read-ValidatedInput { param($Prompt, $Default, $Type, $Choices) throw ('Unexpected input: {0} {1} {2} {3}' -f $Prompt, $Default, $Type, ($Choices -join ',')) }
    function Get-ManifestActionStepId { param($ActionName) if ($ActionName -eq 'ClearUserlessEnrollmentStatus') { return 'P' }; return 'B' }
    function Test-ManifestStepCompleted { param($Device, $StepId) $null = $Device, $StepId; return $false }
    function Test-DeviceReadyForDispatch { param($Device) $null = $Device; return @{ Ready = $false } }
    function Get-StoredRecoveryDevice {
        <# Return the detached record saved in the isolated test store. #>
        if (-not (Test-Path -LiteralPath $script:storePath)) { return $null }
        $items = @((Get-Content -LiteralPath $script:storePath -Raw | ConvertFrom-Json) | ForEach-Object { $_ })
        return ConvertTo-NormalisedValue -Value $items[0]
    }
    function Write-UserDeviceRecords {
        <# Simulate guarded persistence and reject changes to the saved history prefix. #>
        param($Records)
        $existing = Get-StoredRecoveryDevice
        if ($null -ne $existing) { Assert-AttemptHistoryPreserved -Records $Records -ExistingRecords @($existing) }
        $persisted = @(foreach ($record in $Records) { ConvertTo-PersistedDeviceRecord -Record $record })
        Set-Content -LiteralPath $script:storePath -Value (ConvertTo-Json -InputObject $persisted -Depth 30) -NoNewline
    }
    $script:saveRecoveryRecords = ${function:Write-UserDeviceRecords}
    function Restore-RecoveryTestDevice {
        <# Reload a detached record and make it the current session object. #>
        $script:device = Get-StoredRecoveryDevice
        $script:InventoryRecords = @{ Value = @($script:device) }
    }
}

Describe 'Durable recovery unblock' {
    BeforeEach {
        $script:Runtime = @{ IsDemoMode = $false; ModeDisplayName = 'Live' }
        $script:storePath = Join-Path $TestDrive ('{0}.json' -f [guid]::NewGuid().Guid)
        $script:device = New-EmptyDeviceRecord
        $script:device.RecordId = 'recovery-record'
        $script:device.Serial = 'SERIAL1'
        $script:device.TenantId = '11111111-2222-3333-4444-555555555555'
        $script:device.AutopilotDeviceId = 'auto-current'
        $script:device.RecoveryActive = $true
        $script:device.RecoveryStartedAt = (Get-Date).AddMinutes(-10)
        $script:device.Status = 'in-progress'
        $script:InventoryRecords = @{ Value = @($script:device) }
        $script:unblock = @{ Id = 'P'; ActionName = 'ClearUserlessEnrollmentStatus' }
        $script:readiness = @{ Id = 'Q'; ActionName = 'ConfirmRecoveryReadiness' }
        Mock Get-LiveTenantBinding { return $Device.TenantId }
        Mock Resolve-LiveAutopilotContext { $Device.AutopilotDeviceId = 'auto-current' }
        Mock Resolve-LiveManagedDeviceBySerial { return $null }
        Mock Write-UserDeviceRecords { & $script:saveRecoveryRecords -Records $Records }
        Mock Invoke-GraphApiRequest {
            $saved = Get-StoredRecoveryDevice
            $saved.AttemptHistory[-1].EvidenceKind | Should -BeExactly 'RecoveryIntent'
        }
        Mock Read-ValidatedInput { return 'N' }
        Mock Write-Host {}
    }

    It 'saves intent before POST and retains the original accepted time on repeat selection' {
        $result = Invoke-StepClearUserlessEnrollmentStatus -Device $script:device -StepDefinition $script:unblock
        $result.CompletionState | Should -Be 'Submitted'
        $saved = Get-StoredRecoveryDevice
        @($saved.AttemptHistory.EvidenceKind) | Should -Be @('RecoveryIntent', 'RecoveryAccepted')
        Write-ManifestStepResult -Device $script:device -StepDefinition $script:unblock -Result $result
        $savedTime = $script:device.Steps.P.Timestamp
        $repeat = Invoke-StepClearUserlessEnrollmentStatus -Device $script:device -StepDefinition $script:unblock
        $repeat.CompletionState | Should -Be 'Blocked'
        Write-ManifestStepResult -Device $script:device -StepDefinition $script:unblock -Result $repeat
        $script:device.Steps.P.Timestamp | Should -Be $savedTime
        Should -Invoke Invoke-GraphApiRequest -Times 1 -Exactly
    }

    It 'reviews a lost response after reload without another request and starts a fresh wait' {
        Mock Invoke-GraphApiRequest {
            (Get-StoredRecoveryDevice).AttemptHistory[-1].EvidenceKind | Should -Be 'RecoveryIntent'
            throw 'Synthetic lost response'
        }
        $first = Invoke-StepClearUserlessEnrollmentStatus -Device $script:device -StepDefinition $script:unblock
        $first.Data.OutcomeUnknown | Should -BeTrue
        Restore-RecoveryTestDevice
        $declined = Invoke-StepClearUserlessEnrollmentStatus -Device $script:device -StepDefinition $script:unblock
        $declined.CompletionState | Should -Be 'Blocked'
        Should -Invoke Read-ValidatedInput -Times 1 -Exactly -ParameterFilter { $Default -eq 'N' }
        Mock Read-ValidatedInput { return 'Y' }
        $observed = Invoke-StepClearUserlessEnrollmentStatus -Device $script:device -StepDefinition $script:unblock
        $observed.CompletionState | Should -Be 'TechnicianConfirmed'
        $observed.Data.RecoveryOutcome | Should -BeExactly 'AllowedObserved'
        $observed.Summary | Should -Match 'outcome remains unknown'
        Write-ManifestStepResult -Device $script:device -StepDefinition $script:unblock -Result $observed
        (Invoke-StepConfirmRecoveryReadiness -Device $script:device -StepDefinition $script:readiness).Summary | Should -Match 'two-minute wait'
        Should -Invoke Invoke-GraphApiRequest -Times 1 -Exactly
        Should -Invoke Resolve-LiveManagedDeviceBySerial -Times 0 -Exactly
    }

    It 'permits readiness after the complete observation wait without claiming an accepted response' {
        Mock Invoke-GraphApiRequest { throw 'Synthetic lost response' }
        [void](Invoke-StepClearUserlessEnrollmentStatus -Device $script:device -StepDefinition $script:unblock)
        Mock Read-ValidatedInput { return 'Y' }
        $observed = Invoke-StepClearUserlessEnrollmentStatus -Device $script:device -StepDefinition $script:unblock
        Write-ManifestStepResult -Device $script:device -StepDefinition $script:unblock -Result $observed
        $earlier = (Get-Date).AddMinutes(-3)
        $script:device.AttemptHistory[1].Timestamp = $earlier.ToString('o')
        $script:device.Steps.P.Timestamp = $earlier
        $script:device.Steps.P.Data.RecoveryRecordedAt = $earlier.ToString('o')
        $ready = Invoke-StepConfirmRecoveryReadiness -Device $script:device -StepDefinition $script:readiness
        $ready.CompletionState | Should -Be 'TechnicianConfirmed'
        $ready.Data.AllowedEvidence | Should -Be 'TechnicianConfirmedInIntune'
        @($script:device.AttemptHistory | Where-Object EvidenceKind -eq 'RecoveryAccepted').Count | Should -Be 0
        Should -Invoke Invoke-GraphApiRequest -Times 1 -Exactly
    }

    It 'does not send a request if intent persistence fails' {
        Mock Write-UserDeviceRecords { throw 'Synthetic intent save failure' }
        $result = Invoke-StepClearUserlessEnrollmentStatus -Device $script:device -StepDefinition $script:unblock
        $result.CompletionState | Should -Be 'Failed'
        $result.Notes | Should -Match 'No unblock request was sent'
        $script:device.AttemptHistory.Count | Should -Be 0
        Should -Invoke Invoke-GraphApiRequest -Times 0 -Exactly
    }

    It 'keeps the durable intent and refuses replay when accepted evidence cannot be saved' {
        $script:saveCount = 0
        Mock Write-UserDeviceRecords {
            $script:saveCount++
            if ($script:saveCount -eq 2) { throw 'Synthetic accepted save failure' }
            & $script:saveRecoveryRecords -Records $Records
        }
        $result = Invoke-StepClearUserlessEnrollmentStatus -Device $script:device -StepDefinition $script:unblock
        $result.Data.OutcomeUnknown | Should -BeTrue
        (Get-StoredRecoveryDevice).AttemptHistory[-1].EvidenceKind | Should -Be 'RecoveryIntent'
        Restore-RecoveryTestDevice
        (Invoke-StepClearUserlessEnrollmentStatus -Device $script:device -StepDefinition $script:unblock).CompletionState | Should -Be 'Blocked'
        Should -Invoke Invoke-GraphApiRequest -Times 1 -Exactly
    }

    It 'restores an accepted response after reload without resending or resetting its timestamp' {
        $first = Invoke-StepClearUserlessEnrollmentStatus -Device $script:device -StepDefinition $script:unblock
        Restore-RecoveryTestDevice
        $recovered = Invoke-StepClearUserlessEnrollmentStatus -Device $script:device -StepDefinition $script:unblock
        $recovered.CompletionState | Should -Be 'Submitted'
        $recovered.Data.RecoveryRecordedAt | Should -BeExactly $first.Data.RecoveryRecordedAt
        Write-ManifestStepResult -Device $script:device -StepDefinition $script:unblock -Result $recovered
        $script:device.Steps.P.Timestamp.ToUniversalTime() | Should -Be (ConvertTo-RecordDate -Value $first.Data.RecoveryRecordedAt).ToUniversalTime()
        Should -Invoke Invoke-GraphApiRequest -Times 1 -Exactly
    }

    It 'does not retain an observation if its save fails' {
        Mock Invoke-GraphApiRequest { throw 'Synthetic lost response' }
        [void](Invoke-StepClearUserlessEnrollmentStatus -Device $script:device -StepDefinition $script:unblock)
        Mock Read-ValidatedInput { return 'Y' }
        Mock Write-UserDeviceRecords { throw 'Synthetic observation save failure' }
        $result = Invoke-StepClearUserlessEnrollmentStatus -Device $script:device -StepDefinition $script:unblock
        $result.CompletionState | Should -Be 'Failed'
        $result.Data.OutcomeUnknown | Should -BeTrue
        $script:device.AttemptHistory.Count | Should -Be 1
        Should -Invoke Invoke-GraphApiRequest -Times 1 -Exactly
    }

    It 'does not send a request for a record outside the active session' {
        $script:InventoryRecords.Value = @()
        $result = Invoke-StepClearUserlessEnrollmentStatus -Device $script:device -StepDefinition $script:unblock
        $result.CompletionState | Should -Be 'Failed'
        $result.Notes | Should -Match 'active session records'
        Should -Invoke Invoke-GraphApiRequest -Times 0 -Exactly
    }

    It 'refuses a changed target before prompting or sending another request' {
        Mock Invoke-GraphApiRequest { throw 'Synthetic lost response' }
        [void](Invoke-StepClearUserlessEnrollmentStatus -Device $script:device -StepDefinition $script:unblock)
        $script:device.AutopilotDeviceId = 'different-auto'
        $result = Invoke-StepClearUserlessEnrollmentStatus -Device $script:device -StepDefinition $script:unblock
        $result.CompletionState | Should -Be 'Failed'
        $result.Notes | Should -Match 'target or step changed'
        Should -Invoke Read-ValidatedInput -Times 0 -Exactly
        Should -Invoke Invoke-GraphApiRequest -Times 1 -Exactly
    }

    It 'refuses an ambiguous cycle timestamp rather than treating saved intent as a new cycle' {
        Mock Invoke-GraphApiRequest { throw 'Synthetic lost response' }
        [void](Invoke-StepClearUserlessEnrollmentStatus -Device $script:device -StepDefinition $script:unblock)
        $script:device.RecoveryStartedAt = $script:device.RecoveryStartedAt.AddMilliseconds(1)
        $result = Invoke-StepClearUserlessEnrollmentStatus -Device $script:device -StepDefinition $script:unblock
        $result.CompletionState | Should -Be 'Failed'
        $result.Notes | Should -Match 'ambiguous cycle timestamp'
        Should -Invoke Read-ValidatedInput -Times 0 -Exactly
        Should -Invoke Invoke-GraphApiRequest -Times 1 -Exactly
    }

    It 'does not bypass an unresolved intent by changing the recovery start time' {
        Mock Invoke-GraphApiRequest { throw 'Synthetic lost response' }
        [void](Invoke-StepClearUserlessEnrollmentStatus -Device $script:device -StepDefinition $script:unblock)
        $script:device.AttemptHistory[0].Timestamp = (Get-Date).AddMinutes(-1).ToString('o')
        $script:device.RecoveryStartedAt = (Get-Date).AddSeconds(-30)
        $result = Invoke-StepClearUserlessEnrollmentStatus -Device $script:device -StepDefinition $script:unblock
        $result.CompletionState | Should -Be 'Failed'
        $result.Notes | Should -Match 'prior recovery intent has an unknown outcome'
        Should -Invoke Invoke-GraphApiRequest -Times 1 -Exactly
    }

    It 'rejects malformed or duplicate intent evidence without another request' {
        Mock Invoke-GraphApiRequest { throw 'Synthetic lost response' }
        [void](Invoke-StepClearUserlessEnrollmentStatus -Device $script:device -StepDefinition $script:unblock)
        $duplicate = ConvertTo-NormalisedValue -Value $script:device.AttemptHistory[0]
        $duplicate.Sequence = 2
        $duplicate.AttemptId = [guid]::NewGuid().Guid
        $script:device.AttemptHistory += , $duplicate
        $result = Invoke-StepClearUserlessEnrollmentStatus -Device $script:device -StepDefinition $script:unblock
        $result.CompletionState | Should -Be 'Failed'
        $result.Notes | Should -Match 'Duplicate recovery submission intent'
        Should -Invoke Invoke-GraphApiRequest -Times 1 -Exactly
    }

    It 'rejects a fabricated observation without saved technician evidence' {
        $script:device.Steps.P = @{ CompletionState = 'TechnicianConfirmed'; Timestamp = (Get-Date).AddMinutes(-3); Data = @{ RecoveryOutcome = 'AllowedObserved' } }
        $result = Invoke-StepConfirmRecoveryReadiness -Device $script:device -StepDefinition $script:readiness
        $result.CompletionState | Should -Be 'Failed'
        $result.Notes | Should -Match 'does not match saved recovery evidence'
        Should -Invoke Resolve-LiveManagedDeviceBySerial -Times 0 -Exactly
    }

    It 'rejects a fabricated acceptance without saved submission evidence' {
        $earlier = (Get-Date).AddMinutes(-3)
        $script:device.Steps.P = @{ CompletionState = 'Submitted'; Timestamp = $earlier; Data = @{ RecoveryOutcome = 'Accepted'; RecoveryRecordedAt = $earlier.ToString('o'); AutopilotDeviceId = $script:device.AutopilotDeviceId } }
        $result = Invoke-StepConfirmRecoveryReadiness -Device $script:device -StepDefinition $script:readiness
        $result.CompletionState | Should -Be 'Failed'
        $result.Notes | Should -Match 'does not match saved recovery evidence'
        Should -Invoke Resolve-LiveManagedDeviceBySerial -Times 0 -Exactly
    }

    It 'rejects a submitted step that hides an unresolved current-cycle intent' {
        Mock Invoke-GraphApiRequest { throw 'Synthetic lost response' }
        [void](Invoke-StepClearUserlessEnrollmentStatus -Device $script:device -StepDefinition $script:unblock)
        $script:device.Steps.P = @{ CompletionState = 'Submitted'; Timestamp = (Get-Date).AddMinutes(-3); Data = @{} }
        $result = Invoke-StepConfirmRecoveryReadiness -Device $script:device -StepDefinition $script:readiness
        $result.CompletionState | Should -Be 'Failed'
        $result.Notes | Should -Match 'does not match saved recovery evidence'
        Should -Invoke Resolve-LiveManagedDeviceBySerial -Times 0 -Exactly
        Should -Invoke Invoke-GraphApiRequest -Times 1 -Exactly
    }

    It 'permits readiness after the complete accepted-response wait with matching saved evidence' {
        Mock Read-ValidatedInput { return 'Y' }
        $accepted = Invoke-StepClearUserlessEnrollmentStatus -Device $script:device -StepDefinition $script:unblock
        $earlier = (Get-Date).AddMinutes(-3).ToString('o')
        $script:device.AttemptHistory[1].Timestamp = $earlier
        $accepted.Data.RecoveryRecordedAt = $earlier
        Write-ManifestStepResult -Device $script:device -StepDefinition $script:unblock -Result $accepted
        $ready = Invoke-StepConfirmRecoveryReadiness -Device $script:device -StepDefinition $script:readiness
        $ready.CompletionState | Should -Be 'TechnicianConfirmed'
        Should -Invoke Invoke-GraphApiRequest -Times 1 -Exactly
        Should -Invoke Resolve-LiveManagedDeviceBySerial -Times 1 -Exactly
    }

    It 'protects saved intent from truncation or modification' {
        Mock Invoke-GraphApiRequest { throw 'Synthetic lost response' }
        [void](Invoke-StepClearUserlessEnrollmentStatus -Device $script:device -StepDefinition $script:unblock)
        $saved = Get-StoredRecoveryDevice
        $changed = ConvertTo-NormalisedValue -Value $saved
        $changed.AttemptHistory[0].Result.Data.AutopilotDeviceId = 'different-auto'
        { Assert-AttemptHistoryPreserved -Records @($changed) -ExistingRecords @($saved) } | Should -Throw '*alteration*'
        $changed.AttemptHistory = @()
        { Assert-AttemptHistoryPreserved -Records @($changed) -ExistingRecords @($saved) } | Should -Throw '*truncation*'
    }
}
