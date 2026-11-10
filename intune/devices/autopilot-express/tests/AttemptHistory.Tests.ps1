<#
.SYNOPSIS
    Verifies durable, detached handler-outcome history without live calls.
.DESCRIPTION
    Extracts source functions without starting the CLI. All persistence uses
    Pester TestDrive. Checks retries, legacy evidence, dependency invalidation,
    recovery resets, strict history loading and nested checkpoint/audit payloads.
    Requires Pester 5; supports PowerShell 5.1 and 7 in FullLanguage.
.FILECREATED
    2026-10-08
.FILELASTUPDATED
    2026-10-11
#>
BeforeAll {
    $sourcePath = Join-Path (Split-Path -Parent $PSScriptRoot) 'autopilot-express.ps1'
    $tokens = $null
    $parseErrors = $null
    $sourceAst = [System.Management.Automation.Language.Parser]::ParseFile($sourcePath, [ref]$tokens, [ref]$parseErrors)
    if ($parseErrors.Count) { throw ($parseErrors.Message -join '; ') }
    foreach ($functionName in @(
            'New-EmptyDeviceRecord', 'New-OperationResult', 'ConvertTo-NormalisedValue',
            'ConvertTo-StepHashtable', 'ConvertTo-RecordDate', 'ConvertTo-PersistedDate',
            'ConvertTo-PersistedDeviceRecord', 'Get-AffectedWorkflowStepId', 'Write-ManifestStepResult', 'Get-ManifestActionStepId',
            'Test-ManifestStepAttempted', 'Test-ManifestStepCompleted', 'Test-CompletionStateComplete', 'Enter-DeviceRecoveryMode',
            'Get-UserDeviceRecords', 'Assert-DeviceRecordIdentity', 'Write-UserDeviceRecords',
            'Get-MasterAuditProposal', 'Get-VerifiedSaveCopy', 'Update-MasterAuditLedger', 'Get-LocalCheckpointPath',
            'Assert-AttemptHistory', 'Test-AttemptEvidenceEqual', 'Assert-AttemptHistoryPreserved',
            'Save-DeviceLedgerEntry', 'Get-RecoverySubmissionEvidence', 'Save-RecoverySubmissionEvidence',
            'Assert-LocalCheckpointState', 'Get-LocalCheckpointInspection',
            'New-ParentDirectory', 'Get-StorageFileEncoding', 'Write-Utf8File', 'Assert-FileWriteRecoveryState'
        )) {
        $definition = $sourceAst.Find({ param($node) $node -is [System.Management.Automation.Language.FunctionDefinitionAst] -and $node.Name -eq $functionName }, $true)
        if ($null -eq $definition) { throw ('Missing source function: {0}' -f $functionName) }
        Set-Item -Path ('Function:{0}' -f $definition.Name) -Value $definition.Body.GetScriptBlock()
    }
    function Get-EnabledManifestSteps {
        [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseSingularNouns', '', Justification = 'Matches the extracted production collection API for isolated tests.')]
        [CmdletBinding()]
        param()
        return $script:historyManifestSteps
    }
    function Test-DeviceReadyForDispatch { param($Device) return @{ Ready = ($Device.Serial -eq 'never-ready') } }
    function Show-ChecklistHandoffGuide { param($Device) throw ('Unexpected handoff: {0}' -f $Device.Serial) }
    function Read-ValidatedInput { param($Prompt, $Default) throw ('Unexpected prompt: {0}; {1}' -f $Prompt, $Default) }
    function Write-AutopilotExpressLog { param($Message, $Level) throw ('Unexpected log: {0}; {1}' -f $Level, $Message) }
    function Get-DataFolderPath { return $script:stateRoot }
    function Get-UserDataFilePath { return Join-Path $script:stateRoot 'records.json' }
    function Get-BuildBenchStatePath { return Join-Path $script:stateRoot 'bench.json' }
    function Get-MasterAuditFilePath { return Join-Path $script:stateRoot 'audit.json' }
}

Describe 'Independent append-only attempt snapshots' {
    BeforeEach {
        $script:Runtime = @{ IsDemoMode = $false; ModeDisplayName = 'Live' }
        $script:device = New-EmptyDeviceRecord
        $script:device.RecordId = 'synthetic-record'
        $script:device.Serial = 'HISTORY-01'
        $script:device.AutopilotDeviceId = 'synthetic-autopilot-id'
        $script:device.TenantId = '11111111-2222-3333-4444-555555555555'
        $script:historyManifestSteps = @(
            @{ Id = 'A'; ActionName = 'ResolveAutopilotDevice'; PrerequisiteStepIds = @() }
            @{ Id = 'B'; ActionName = 'SyntheticMiddle'; PrerequisiteStepIds = @('A') }
            @{ Id = 'C'; ActionName = 'SyntheticLeaf'; PrerequisiteStepIds = @('B') }
            @{ Id = 'F'; ActionName = 'ClearUserlessEnrollmentStatus'; PrerequisiteStepIds = @() }
            @{ Id = 'Q'; ActionName = 'ConfirmRecoveryReadiness'; PrerequisiteStepIds = @() }
        )
        $script:step = $script:historyManifestSteps[0]
        $script:result = New-OperationResult -ActionName $script:step.ActionName -Success $true -CompletionState Verified -Summary 'original' -Notes 'synthetic evidence' -Data @{ Serial = 'HISTORY-01'; ObservedSerial = 'HISTORY-01'; AutopilotDeviceId = 'synthetic-autopilot-id'; VerificationAttempts = 1; Nested = @{ Items = @(@{ Value = 'original' }) }; Empty = @() }
        $script:stateRoot = Join-Path $TestDrive ([guid]::NewGuid().Guid)
        New-Item -ItemType Directory -Path $script:stateRoot | Out-Null
        $script:LocalCheckpointToken = $null
        Remove-Variable -Name BuildBench -Scope Script -ErrorAction SilentlyContinue
        Mock Write-AutopilotExpressLog {}
        Mock Write-Host {}
    }

    It 'initialises a real empty history array' {
        $script:device.AttemptHistory -is [array] | Should -BeTrue
        $script:device.AttemptHistory.Count | Should -Be 0
    }

    It 'captures complete <State> outcomes with identity and ISO timestamp' -ForEach @(
        @{ State = 'Verified'; Success = $true }
        @{ State = 'TechnicianConfirmed'; Success = $true }
        @{ State = 'Submitted'; Success = $false }
        @{ State = 'Failed'; Success = $false }
        @{ State = 'Blocked'; Success = $false }
        @{ State = 'AuditedException'; Success = $true }
        @{ State = 'Simulated'; Success = $true }
        @{ State = 'LegacyCompleted'; Success = $true }
    ) {
        $script:result.CompletionState = $State
        $script:result.Success = $Success
        $returned = Write-ManifestStepResult -Device $script:device -StepDefinition $script:step -Result $script:result
        $returned | Should -BeNullOrEmpty
        $entry = $script:device.AttemptHistory[0]
        $entry.Sequence | Should -Be 1
        { [guid]::Parse($entry.AttemptId) } | Should -Not -Throw
        $entry.StepId | Should -Be 'A'
        $entry.ActionName | Should -Be $script:step.ActionName
        $entry.Actor | Should -Be $env:USERNAME
        $entry.Timestamp | Should -Match '^\d{4}-\d{2}-\d{2}T'
        { [datetime]::Parse($entry.Timestamp) } | Should -Not -Throw
        $entry.Mode | Should -Be 'Live'
        $entry.TenantId | Should -Be $script:device.TenantId
        $entry.Serial | Should -Be 'HISTORY-01'
        $entry.RecordId | Should -Be 'synthetic-record'
        $entry.EvidenceKind | Should -Be 'HandlerOutcome'
        foreach ($field in $script:result.Keys) {
            Test-AttemptEvidenceEqual -Left $entry.Result[$field] -Right $script:result[$field] | Should -BeTrue -Because ('captured {0} evidence must match structurally' -f $field)
        }
    }

    It 'appends unique contiguous retries without changing prior snapshots' {
        Write-ManifestStepResult -Device $script:device -StepDefinition $script:step -Result $script:result
        $before = $script:device.AttemptHistory[0] | ConvertTo-Json -Depth 100 -Compress
        $script:result.Success = $false
        $script:result.CompletionState = 'Failed'
        $script:result.Summary = 'retry'
        Write-ManifestStepResult -Device $script:device -StepDefinition $script:step -Result $script:result
        $script:device.AttemptHistory.Count | Should -Be 2
        $script:device.AttemptHistory[1].Sequence | Should -Be 2
        $script:device.AttemptHistory[1].AttemptId | Should -Not -Be $script:device.AttemptHistory[0].AttemptId
        ($script:device.AttemptHistory[0] | ConvertTo-Json -Depth 100 -Compress) | Should -BeExactly $before
        $script:device.Steps.A.CompletionState | Should -Be 'Failed'
    }

    It 'records blocked retries but retains the original early-return behaviour' {
        Write-ManifestStepResult -Device $script:device -StepDefinition $script:step -Result $script:result
        $stepsBefore = $script:device.Steps | ConvertTo-Json -Depth 100 -Compress
        $updatedBefore = $script:device.LastUpdatedAt
        $script:result = New-OperationResult -ActionName $script:step.ActionName -Success $false -CompletionState Blocked -Data @{ Blocked = $true; MissingStepIds = @('B') }
        Write-ManifestStepResult -Device $script:device -StepDefinition $script:step -Result $script:result | Should -BeNullOrEmpty
        $script:device.AttemptHistory.Count | Should -Be 2
        $script:device.AttemptHistory[1].Result.Data.Blocked | Should -BeTrue
        ($script:device.Steps | ConvertTo-Json -Depth 100 -Compress) | Should -BeExactly $stepsBefore
        $script:device.LastUpdatedAt | Should -Be $updatedBefore
    }

    It 'deep clones result maps, objects and arrays independently of current steps' {
        $script:result.Data.Object = [pscustomobject]@{ Values = @(@{ Flag = 'old' }) }
        Write-ManifestStepResult -Device $script:device -StepDefinition $script:step -Result $script:result
        $script:result.Data.Nested.Items[0].Value = 'caller mutation'
        $script:result.Data.Object.Values[0].Flag = 'caller mutation'
        $script:device.Steps.A.Data.Nested.Items[0].Value = 'step mutation'
        $script:device.Steps.A.Data.Object.Values[0].Flag = 'step mutation'
        $entry = $script:device.AttemptHistory[0]
        $entry.Result.Data.Nested.Items[0].Value | Should -Be 'original'
        $entry.Result.Data.Object.Values[0].Flag | Should -Be 'old'
        $entry.Result.Data.Nested.Items -is [array] | Should -BeTrue
        $entry.Result.Data.Empty -is [array] | Should -BeTrue
    }

    It 'captures prior legacy evidence once before a retry with <TimestampKind> time' -ForEach @(
        @{ TimestampKind = 'recorded'; Recorded = '2026-09-01T09:00:00.0000000Z' }
        @{ TimestampKind = 'unknown'; Recorded = $null }
    ) {
        $script:device.Steps.A = @{ Completed = $true; Success = $true; CompletionState = 'Verified'; Data = @{ Items = @('old') } }
        if ($null -ne $Recorded) { $script:device.Steps.A.Timestamp = $Recorded }
        Write-ManifestStepResult -Device $script:device -StepDefinition $script:step -Result $script:result
        $legacy = $script:device.AttemptHistory[0]
        $legacy.EvidenceKind | Should -Be 'LegacyEvidence'
        $legacy.Actor | Should -BeNullOrEmpty
        if ($null -eq $Recorded) { $legacy.Timestamp | Should -BeNullOrEmpty }
        else { [datetime]$legacy.Timestamp | Should -Be ([datetime]$Recorded) }
        $legacy.Result.Data.Items[0] | Should -Be 'old'
        $script:device.AttemptHistory[1].EvidenceKind | Should -Be 'HandlerOutcome'
        $script:device.AttemptHistory[1].Sequence | Should -Be 2
        Write-ManifestStepResult -Device $script:device -StepDefinition $script:step -Result $script:result
        @($script:device.AttemptHistory | Where-Object EvidenceKind -eq LegacyEvidence).Count | Should -Be 1
    }

    It 'preserves legacy transitive dependants before invalidating their evidence' {
        foreach ($definition in $script:historyManifestSteps[0..2]) {
            $script:device.Steps[$definition.Id] = @{ Completed = $true; Success = $true; CompletionState = 'Verified'; ActionName = $definition.ActionName; Data = @{ Nested = @{ Value = $definition.Id } } }
        }
        Write-ManifestStepResult -Device $script:device -StepDefinition $script:step -Result $script:result
        $script:device.AttemptHistory.Count | Should -Be 4
        foreach ($stepId in @('B', 'C')) {
            $legacy = $script:device.AttemptHistory | Where-Object StepId -eq $stepId
            $legacy.EvidenceKind | Should -Be 'LegacyEvidence'
            $legacy.Result.CompletionState | Should -Be 'Verified'
            $legacy.Result.Success | Should -BeTrue
            $legacy.Result.Contains('InvalidatedBy') | Should -BeFalse
            $script:device.Steps[$stepId].CompletionState | Should -Be 'Blocked'
            $script:device.Steps[$stepId].Data.Nested.Value = 'changed'
            $legacy.Result.Data.Nested.Value | Should -Be $stepId
        }
        ($script:device.AttemptHistory.Sequence -join ',') | Should -Be '1,2,3,4'
    }

    It 'does not synthesise legacy duplicates for dependants already represented in history' {
        foreach ($definition in $script:historyManifestSteps[0..2]) {
            $outcome = New-OperationResult -ActionName $definition.ActionName -Success $true -CompletionState Verified
            Write-ManifestStepResult -Device $script:device -StepDefinition $definition -Result $outcome
        }
        $prefix = $script:device.AttemptHistory | ConvertTo-Json -Depth 100 -Compress
        Write-ManifestStepResult -Device $script:device -StepDefinition $script:step -Result $script:result
        $script:device.AttemptHistory.Count | Should -Be 4
        ($script:device.AttemptHistory[0..2] | ConvertTo-Json -Depth 100 -Compress) | Should -BeExactly $prefix
        @($script:device.AttemptHistory | Where-Object EvidenceKind -eq LegacyEvidence).Count | Should -Be 0
    }

    It 'retains all attempts outside Steps across recovery entry and close-out resets' {
        foreach ($definition in $script:historyManifestSteps[0..3]) {
            $state = if ($definition.Id -eq 'A') { 'Verified' } elseif ($definition.Id -eq 'F') { 'Submitted' } else { 'TechnicianConfirmed' }
            $outcome = New-OperationResult -ActionName $definition.ActionName -Success $true -CompletionState $state -Data $script:result.Data
            Write-ManifestStepResult -Device $script:device -StepDefinition $definition -Result $outcome
        }
        $prefix = $script:device.AttemptHistory | ConvertTo-Json -Depth 100 -Compress
        Mock Read-ValidatedInput { return 'Y' } -ParameterFilter { $Default -eq 'N' }
        Mock Read-ValidatedInput { return 'synthetic recovery' } -ParameterFilter { $Default -ne 'N' }
        Enter-DeviceRecoveryMode -Device $script:device
        $script:device.Steps.Contains('F') | Should -BeFalse
        ($script:device.AttemptHistory | ConvertTo-Json -Depth 100 -Compress) | Should -BeExactly $prefix
        $close = New-OperationResult -ActionName 'ConfirmRecoveryReadiness' -Success $true -CompletionState TechnicianConfirmed
        Write-ManifestStepResult -Device $script:device -StepDefinition $script:historyManifestSteps[4] -Result $close
        $script:device.AttemptHistory.Count | Should -Be 5
        ($script:device.AttemptHistory[0..3] | ConvertTo-Json -Depth 100 -Compress) | Should -BeExactly $prefix
        $script:device.Steps.Contains('B') | Should -BeFalse
        $script:device.Steps.Contains('C') | Should -BeFalse
        $script:device.RecoveryHistory.Count | Should -Be 2
        $script:device.RecoveryHistory[1].Steps.B.CompletionState | Should -Be 'TechnicianConfirmed'
    }

    It 'preserves nested history through records, audit and an unresolved checkpoint' {
        $script:result.Data.Deep = @{ Level1 = @{ Level2 = @{ Level3 = @{ Level4 = @{ Level5 = @{ Values = @(@{ Text = 'deep evidence' }) } } } } } }
        Write-ManifestStepResult -Device $script:device -StepDefinition $script:step -Result $script:result
        Write-UserDeviceRecords -Records @($script:device)
        $loaded = Get-UserDeviceRecords
        $loaded[0].AttemptHistory -is [array] | Should -BeTrue
        $loaded[0].AttemptHistory.Count | Should -Be 1
        $loaded[0].AttemptHistory[0].AttemptId | Should -Be $script:device.AttemptHistory[0].AttemptId
        $loaded[0].AttemptHistory[0].Result.Data.Deep.Level1.Level2.Level3.Level4.Level5.Values[0].Text | Should -Be 'deep evidence'
        $audit = Get-Content -LiteralPath (Get-MasterAuditFilePath) -Raw | ConvertFrom-Json
        $audit.AttemptHistory[0].Result.Data.Deep.Level1.Level2.Level3.Level4.Level5.Values[0].Text | Should -Be 'deep evidence'
        Mock Update-MasterAuditLedger { throw 'synthetic audit save failure' }
        { Write-UserDeviceRecords -Records @($script:device) } | Should -Throw '*synthetic audit save failure*'
        $inspection = Get-LocalCheckpointInspection
        foreach ($payload in @($inspection.Proposal.RecordsJson, $inspection.Proposal.AuditJson)) {
            $proposed = $payload | ConvertFrom-Json
            $proposed.AttemptHistory[0].Result.Data.Deep.Level1.Level2.Level3.Level4.Level5.Values[0].Text | Should -Be 'deep evidence'
        }
    }

    It 'round trips recovery intent and <Kind> through the real record and audit writers' -ForEach @(
        @{ Kind = 'RecoveryAccepted' }
        @{ Kind = 'RecoveryAllowedObserved' }
    ) {
        $script:device.RecoveryActive = $true
        $script:device.RecoveryStartedAt = (Get-Date).AddMinutes(-5)
        $script:InventoryRecords = @{ Value = @($script:device) }
        $unblock = $script:historyManifestSteps | Where-Object ActionName -eq 'ClearUserlessEnrollmentStatus'
        [void](Save-RecoverySubmissionEvidence -Device $script:device -StepDefinition $unblock -Kind 'RecoveryIntent')
        $terminal = Save-RecoverySubmissionEvidence -Device $script:device -StepDefinition $unblock -Kind $Kind
        $loaded = Get-UserDeviceRecords
        ($loaded[0].AttemptHistory.EvidenceKind -join ',') | Should -Be ('RecoveryIntent,{0}' -f $Kind)
        $recovered = Get-RecoverySubmissionEvidence -Device $loaded[0] -StepDefinition $unblock
        $recovered.Kind | Should -Be $Kind
        $recovered.RecordedAt | Should -BeExactly $terminal.Timestamp
        $audit = Get-Content -LiteralPath (Get-MasterAuditFilePath) -Raw | ConvertFrom-Json
        ($audit.AttemptHistory.EvidenceKind -join ',') | Should -Be ('RecoveryIntent,{0}' -f $Kind)
    }

    It 'retains a failed recovery intent save in checkpoint evidence without leaving it in memory' {
        $script:device.RecoveryActive = $true
        $script:device.RecoveryStartedAt = (Get-Date).AddMinutes(-5)
        $script:InventoryRecords = @{ Value = @($script:device) }
        $unblock = $script:historyManifestSteps | Where-Object ActionName -eq 'ClearUserlessEnrollmentStatus'
        Mock Update-MasterAuditLedger { throw 'synthetic audit save failure' }
        { Save-RecoverySubmissionEvidence -Device $script:device -StepDefinition $unblock -Kind 'RecoveryIntent' } | Should -Throw '*synthetic audit save failure*'
        $script:device.AttemptHistory.Count | Should -Be 0
        $inspection = Get-LocalCheckpointInspection
        $proposed = $inspection.Proposal.RecordsJson | ConvertFrom-Json
        $proposed.AttemptHistory[0].EvidenceKind | Should -Be 'RecoveryIntent'
    }

    It 'accepts absent legacy history without replacing other evidence' {
        $script:device.Remove('AttemptHistory')
        $script:device.Steps.A = @{ Completed = $true; Data = @{ Text = 'legacy' } }
        Write-Utf8File -Path (Get-UserDataFilePath) -Content ($script:device | ConvertTo-Json -Depth 100)
        $loaded = Get-UserDeviceRecords
        $loaded[0].AttemptHistory.Count | Should -Be 0
        $loaded[0].Steps.A.Data.Text | Should -Be 'legacy'
    }

    It 'rejects structural <Shape> history instead of dropping evidence' -ForEach @(
        @{ Shape = 'null'; Bad = $null }
        @{ Shape = 'scalar'; Bad = 'damaged' }
        @{ Shape = 'dictionary'; Bad = @{ Sequence = 1 } }
        @{ Shape = 'null entry'; Bad = @($null) }
        @{ Shape = 'scalar entry'; Bad = @('damaged') }
    ) {
        $script:device.AttemptHistory = $Bad
        Write-Utf8File -Path (Get-UserDataFilePath) -Content ($script:device | ConvertTo-Json -Depth 100)
        $before = Get-Content -LiteralPath (Get-UserDataFilePath) -Raw
        { Get-UserDeviceRecords } | Should -Throw '*attempt history*'
        Get-Content -LiteralPath (Get-UserDataFilePath) -Raw | Should -BeExactly $before
    }

    It 'rejects malformed <Field> without altering saved evidence' -ForEach @(
        @{ Field = 'Sequence'; Bad = 2 }
        @{ Field = 'AttemptId'; Bad = 'not-a-guid' }
        @{ Field = 'Timestamp'; Bad = $null }
        @{ Field = 'Mode'; Bad = $true }
        @{ Field = 'EvidenceKind'; Bad = 'invented' }
        @{ Field = 'Result'; Bad = 'damaged' }
    ) {
        Write-ManifestStepResult -Device $script:device -StepDefinition $script:step -Result $script:result
        $script:device.AttemptHistory[0][$Field] = $Bad
        Write-Utf8File -Path (Get-UserDataFilePath) -Content ($script:device | ConvertTo-Json -Depth 100)
        { Get-UserDeviceRecords } | Should -Throw '*Saved*'
    }

    It 'rejects duplicate attempt IDs on load' {
        Write-ManifestStepResult -Device $script:device -StepDefinition $script:step -Result $script:result
        Write-ManifestStepResult -Device $script:device -StepDefinition $script:step -Result $script:result
        $script:device.AttemptHistory[1].AttemptId = $script:device.AttemptHistory[0].AttemptId
        Write-Utf8File -Path (Get-UserDataFilePath) -Content ($script:device | ConvertTo-Json -Depth 100)
        { Get-UserDeviceRecords } | Should -Throw '*unique GUID*'
    }
}