<#
.SYNOPSIS
    Verifies append-only persisted attempts against real local TestDrive files.
.DESCRIPTION
    Extracts actual writer, loader and persistence functions without launching
    the CLI. No tenant actions occur. Refusals must precede every checkpoint,
    record, audit and bench write. Requires Pester 5 on PowerShell 5.1 or 7.
.FILECREATED
    2026-10-08
.FILELASTUPDATED
    2026-10-08
#>
BeforeAll {
    $sourcePath = Join-Path (Split-Path -Parent $PSScriptRoot) 'autopilot-express.ps1'
    $tokens = $null
    $parseErrors = $null
    $sourceAst = [System.Management.Automation.Language.Parser]::ParseFile($sourcePath, [ref]$tokens, [ref]$parseErrors)
    if ($parseErrors.Count) { throw ($parseErrors.Message -join '; ') }
    foreach ($functionName in @(
            'New-EmptyDeviceRecord', 'New-OperationResult', 'Get-AffectedWorkflowStepId', 'Write-ManifestStepResult',
            'Get-EnabledManifestSteps', 'Test-ManifestStepAttempted', 'Test-ManifestStepCompleted', 'Test-CompletionStateComplete',
            'ConvertTo-NormalisedValue', 'ConvertTo-StepHashtable', 'ConvertTo-RecordDate',
            'ConvertTo-PersistedDate', 'ConvertTo-PersistedDeviceRecord', 'Assert-DeviceRecordIdentity',
            'Assert-AttemptHistory', 'Test-AttemptEvidenceEqual', 'Assert-AttemptHistoryPreserved',
            'Get-UserDeviceRecords', 'Write-UserDeviceRecords', 'Get-MasterAuditProposal', 'Get-VerifiedSaveCopy', 'Update-MasterAuditLedger',
            'Get-LocalCheckpointPath', 'Assert-LocalCheckpointState', 'New-ParentDirectory',
            'Get-StorageFileEncoding', 'Write-Utf8File', 'Assert-FileWriteRecoveryState'
        )) {
        $definition = $sourceAst.Find({ param($node) $node -is [System.Management.Automation.Language.FunctionDefinitionAst] -and $node.Name -eq $functionName }, $true)
        if ($null -eq $definition) { throw ('Missing source function: {0}' -f $functionName) }
        Set-Item -Path ('Function:{0}' -f $definition.Name) -Value $definition.Body.GetScriptBlock()
    }
    function Get-DataFolderPath { return $script:stateRoot }
    function Get-UserDataFilePath { return Join-Path $script:stateRoot 'records.json' }
    function Get-MasterAuditFilePath { return Join-Path $script:stateRoot 'audit.json' }
    function Test-DeviceReadyForDispatch { param($Device) return @{ Ready = ($Device.Serial -eq 'never-ready') } }
    function Write-AutopilotExpressLog { param($Message, $Level) throw ('Unexpected log: {0}; {1}' -f $Level, $Message) }
    function Save-BuildBenchState { param($CheckpointToken, $ProposedContent) throw ('Unexpected bench save: {0}; {1}' -f $CheckpointToken, $ProposedContent) }
}

Describe 'Persisted attempt history protection' {
    BeforeEach {
        $script:stateRoot = Join-Path $TestDrive ([guid]::NewGuid().Guid)
        New-Item -ItemType Directory -Path $script:stateRoot | Out-Null
        $script:Runtime = @{ IsDemoMode = $false; ModeDisplayName = 'normal' }
        $script:LocalCheckpointToken = $null
        Remove-Variable -Name BuildBench -Scope Script -ErrorAction SilentlyContinue
        Mock Write-AutopilotExpressLog {}
        $script:device = New-EmptyDeviceRecord
        $script:device.RecordId = 'synthetic-persisted-record'
        $script:device.Serial = 'PERSISTED-HISTORY-01'
        $script:device.TenantId = '11111111-2222-3333-4444-555555555555'
        $script:step = @{ Id = 'renamed-step'; ActionName = 'SyntheticAction' }
        $script:StepManifest = @($script:step)
        $script:result = New-OperationResult -ActionName SyntheticAction -Success $false -CompletionState Failed -Summary 'original' -Notes 'evidence' -Data @{ Nested = @{ Items = @('first', 'second'); Flag = $true }; Empty = @() }
        Write-ManifestStepResult -Device $script:device -StepDefinition $script:step -Result $script:result
        Write-UserDeviceRecords -Records @($script:device)
        $script:beforeRecords = Get-Content -LiteralPath (Get-UserDataFilePath) -Raw
        $script:beforeAudit = Get-Content -LiteralPath (Get-MasterAuditFilePath) -Raw
    }

    It 'allows reordered keys, appends, round trips and does not mutate the caller' {
        $entry = $script:device.AttemptHistory[0]
        $reordered = [ordered]@{}
        foreach ($key in @($entry.Keys | Sort-Object -Descending)) { $reordered[$key] = $entry[$key] }
        $reordered.Result.Data.Nested = [ordered]@{ Flag = $true; Items = @('first', 'second') }
        $script:device.AttemptHistory[0] = $reordered
        Write-ManifestStepResult -Device $script:device -StepDefinition $script:step -Result $script:result
        $callerBefore = $script:device | ConvertTo-Json -Depth 100
        Write-UserDeviceRecords -Records @($script:device)
        ($script:device | ConvertTo-Json -Depth 100) | Should -BeExactly $callerBefore
        $loaded = Get-UserDeviceRecords
        $loaded[0].AttemptHistory.Count | Should -Be 2
        $loaded[0].AttemptHistory[1].Sequence | Should -Be 2
        $audit = Get-Content -LiteralPath (Get-MasterAuditFilePath) -Raw | ConvertFrom-Json
        $audit.AttemptHistory.Count | Should -Be 2
        Test-AttemptEvidenceEqual -Left $loaded[0].AttemptHistory[0] -Right (ConvertTo-NormalisedValue -Value (($script:beforeRecords | ConvertFrom-Json).AttemptHistory[0])) | Should -BeTrue
    }
    It 'preserves explicit dispatch metadata without inferring dispatch from completion: <Confirmed>' -ForEach @(
        @{ Confirmed = $true }, @{ Confirmed = $false }
    ) {
        $script:device.Status = 'completed'
        $script:device.CompletedAt = [datetime]'2026-10-15T12:00:00'
        $script:device.CompletedBy = 'synthetic-technician'
        $script:device.DispatchConfirmed = $Confirmed
        $script:device.DispatchedAt = if ($Confirmed) { [datetime]'2026-10-15T12:01:00' } else { $null }
        $proposal = Get-MasterAuditProposal -Records @($script:device) | ConvertFrom-Json
        $proposal.DispatchConfirmed | Should -Be $Confirmed
        $proposal.CompletedBy | Should -Be 'synthetic-technician'
        if ($Confirmed) { ([datetime]$proposal.DispatchedAt) | Should -Be $script:device.DispatchedAt }
        else { $proposal.DispatchedAt | Should -BeNullOrEmpty }
        Test-AttemptEvidenceEqual -Left (ConvertTo-NormalisedValue $proposal.AttemptHistory) -Right $script:device.AttemptHistory | Should -BeTrue
    }

    It 'refuses <Change> before any write' -ForEach @(
        @{ Change = 'truncate' }, @{ Change = 'missing history' }, @{ Change = 'edit' },
        @{ Change = 'scalar case' }, @{ Change = 'array order' }, @{ Change = 'remove record' },
        @{ Change = 'reforge record identity' }, @{ Change = 'reforge serial identity' },
        @{ Change = 'reforge tenant identity' }, @{ Change = 'reforge attempt identity' }
    ) {
        $proposal = @($script:device)
        switch ($Change) {
            'truncate' { $script:device.AttemptHistory = @() }
            'missing history' { $script:device.Remove('AttemptHistory') }
            'edit' { $script:device.AttemptHistory[0].Result.Summary = 'edited' }
            'scalar case' { $script:device.AttemptHistory[0].Result.Summary = 'Original' }
            'array order' { $script:device.AttemptHistory[0].Result.Data.Nested.Items = @('second', 'first') }
            'remove record' { $proposal = @() }
            'reforge record identity' { $script:device.RecordId = 'reforged-record'; $script:device.AttemptHistory[0].RecordId = 'reforged-record' }
            'reforge serial identity' { $script:device.Serial = 'REFORGED'; $script:device.AttemptHistory[0].Serial = 'REFORGED' }
            'reforge tenant identity' { $script:device.TenantId = 'aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee'; $script:device.AttemptHistory[0].TenantId = $script:device.TenantId }
            'reforge attempt identity' { $script:device.AttemptHistory[0].AttemptId = [guid]::NewGuid().Guid }
        }
        $callerBefore = $proposal | ConvertTo-Json -Depth 100
        Mock Write-Utf8File { throw 'Validation reached a write.' }
        { Write-UserDeviceRecords -Records $proposal } | Should -Throw '*Persisted attempt history*'
        Should -Invoke Write-Utf8File -Times 0 -Exactly
        Get-Content -LiteralPath (Get-UserDataFilePath) -Raw | Should -BeExactly $script:beforeRecords
        Get-Content -LiteralPath (Get-MasterAuditFilePath) -Raw | Should -BeExactly $script:beforeAudit
        ($proposal | ConvertTo-Json -Depth 100) | Should -BeExactly $callerBefore
        Test-Path -LiteralPath (Get-LocalCheckpointPath) | Should -BeFalse
    }

    It 'retains soft-removed history' {
        $script:device.Status = 'removed'
        Write-UserDeviceRecords -Records @($script:device)
        $loaded = Get-UserDeviceRecords
        $loaded[0].Status | Should -Be 'removed'
        $loaded[0].AttemptHistory.Count | Should -Be 1
    }

    It 'refuses an audit prefix longer than the session proposal before writes' {
        Write-ManifestStepResult -Device $script:device -StepDefinition $script:step -Result $script:result
        $longerAudit = Get-MasterAuditProposal -Records @($script:device)
        Write-Utf8File -Path (Get-MasterAuditFilePath) -Content $longerAudit
        $loaded = Get-UserDeviceRecords
        Mock Write-Utf8File { throw 'Validation reached a write.' }
        { Write-UserDeviceRecords -Records $loaded } | Should -Throw '*truncation*'
        Should -Invoke Write-Utf8File -Times 0 -Exactly
        Get-Content -LiteralPath (Get-UserDataFilePath) -Raw | Should -BeExactly $script:beforeRecords
        Get-Content -LiteralPath (Get-MasterAuditFilePath) -Raw | Should -BeExactly $longerAudit
    }

    It 'retains extra historical audit records and their original attempts' {
        $extra = ConvertTo-NormalisedValue -Value $script:device
        $extra.RecordId = 'audit-only-record'
        $extra.Serial = 'AUDIT-ONLY'
        $extra.AttemptHistory[0].RecordId = $extra.RecordId
        $extra.AttemptHistory[0].Serial = $extra.Serial
        $extra.AttemptHistory[0].AttemptId = [guid]::NewGuid().Guid
        $original = ConvertTo-NormalisedValue -Value $extra
        $ledger = @($script:device, $extra) | ConvertTo-Json -Depth 100
        Write-Utf8File -Path (Get-MasterAuditFilePath) -Content $ledger
        Write-UserDeviceRecords -Records @($script:device)
        $audit = Get-Content -LiteralPath (Get-MasterAuditFilePath) -Raw | ConvertFrom-Json
        @($audit).Count | Should -Be 2
        $retained = $audit | Where-Object RecordId -eq 'audit-only-record'
        Test-AttemptEvidenceEqual -Left $original -Right (ConvertTo-NormalisedValue -Value $retained) | Should -BeTrue
    }

    It 'fails closed on <File> <Damage> before writes' -ForEach @(
        @{ File = 'records'; Damage = 'invalid JSON'; Content = '{invalid' }
        @{ File = 'records'; Damage = 'null'; Content = 'null' }
        @{ File = 'records'; Damage = 'empty'; Content = '' }
        @{ File = 'audit'; Damage = 'invalid JSON'; Content = '{invalid' }
        @{ File = 'audit'; Damage = 'null'; Content = 'null' }
        @{ File = 'audit'; Damage = 'scalar'; Content = '42' }
        @{ File = 'audit'; Damage = 'empty'; Content = '' }
    ) {
        $path = if ($File -eq 'records') { Get-UserDataFilePath } else { Get-MasterAuditFilePath }
        Write-Utf8File -Path $path -Content $Content
        $damaged = Get-Content -LiteralPath $path -Raw
        Mock Write-Utf8File { throw 'Validation reached a write.' }
        { Write-UserDeviceRecords -Records @($script:device) } | Should -Throw
        Should -Invoke Write-Utf8File -Times 0 -Exactly
        Get-Content -LiteralPath $path -Raw | Should -BeExactly $damaged
    }

    It 'rejects malformed history <Field> on load and save' -ForEach @(
        @{ Field = 'Sequence'; Bad = 0 }, @{ Field = 'Sequence'; Bad = '1' },
        @{ Field = 'AttemptId'; Bad = 'not-a-guid' }, @{ Field = 'StepId'; Bad = 1 },
        @{ Field = 'ActionName'; Bad = $false }, @{ Field = 'Actor'; Bad = @() },
        @{ Field = 'Mode'; Bad = 'unknown' }, @{ Field = 'TenantId'; Bad = $false },
        @{ Field = 'TenantId'; Bad = 'aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee' },
        @{ Field = 'RecordId'; Bad = 'other-record' }, @{ Field = 'Serial'; Bad = 'OTHER' },
        @{ Field = 'Timestamp'; Bad = '2026-02-30T00:00:00Z' },
        @{ Field = 'Timestamp'; Bad = '2026-10-08Tgarbage' }, @{ Field = 'Timestamp'; Bad = $null },
        @{ Field = 'EvidenceKind'; Bad = 'Outcome' }, @{ Field = 'Result'; Bad = @() },
        @{ Field = 'Success'; Bad = 'false' }, @{ Field = 'IsSimulated'; Bad = 0 },
        @{ Field = 'CompletionState'; Bad = $true }, @{ Field = 'CompletionState'; Bad = 'complete' },
        @{ Field = 'Data'; Bad = @() }, @{ Field = 'Summary'; Bad = 42 }
    ) {
        if ($Field -in @('Success', 'IsSimulated', 'CompletionState', 'Data', 'Summary')) { $script:device.AttemptHistory[0].Result[$Field] = $Bad }
        else { $script:device.AttemptHistory[0][$Field] = $Bad }
        Write-Utf8File -Path (Get-UserDataFilePath) -Content ($script:device | ConvertTo-Json -Depth 100)
        Mock Write-Utf8File { throw 'Validation reached a write.' }
        { Get-UserDeviceRecords } | Should -Throw
        { Write-UserDeviceRecords -Records @($script:device) } | Should -Throw
        Should -Invoke Write-Utf8File -Times 0 -Exactly
    }

    It 'rejects duplicate IDs and sequence gaps on load' -ForEach @(
        @{ Damage = 'duplicate ID' }, @{ Damage = 'sequence gap' }
    ) {
        Write-ManifestStepResult -Device $script:device -StepDefinition $script:step -Result $script:result
        if ($Damage -eq 'duplicate ID') { $script:device.AttemptHistory[1].AttemptId = $script:device.AttemptHistory[0].AttemptId }
        else { $script:device.AttemptHistory[1].Sequence = 3 }
        Write-Utf8File -Path (Get-UserDataFilePath) -Content ($script:device | ConvertTo-Json -Depth 100)
        { Get-UserDeviceRecords } | Should -Throw
    }

    It 'preserves missing legacy dates without inventing execution times' {
        $script:device.AttemptHistory = @()
        $script:device.Steps[$script:step.Id] = @{ Success = $true; Timestamp = $null }
        Write-ManifestStepResult -Device $script:device -StepDefinition $script:step -Result $script:result
        Remove-Item -LiteralPath (Get-UserDataFilePath), (Get-MasterAuditFilePath)
        Write-UserDeviceRecords -Records @($script:device)
        $loaded = Get-UserDeviceRecords
        $loaded[0].AttemptHistory[0].Timestamp | Should -BeNullOrEmpty
        $loaded[0].AttemptHistory[0].Result.Timestamp | Should -BeNullOrEmpty
        $loaded[0].AttemptHistory[0].Result.Contains('CompletionState') | Should -BeFalse
    }

    It 'allows absent legacy history, empty history and empty JSON arrays' {
        $script:device.Remove('AttemptHistory')
        Write-Utf8File -Path (Get-UserDataFilePath) -Content ($script:device | ConvertTo-Json -Depth 100)
        Write-Utf8File -Path (Get-MasterAuditFilePath) -Content '[]'
        $loaded = Get-UserDeviceRecords
        $loaded[0].AttemptHistory -is [array] | Should -BeTrue
        $loaded[0].AttemptHistory.Count | Should -Be 0
        Write-UserDeviceRecords -Records $loaded
        Write-Utf8File -Path (Get-UserDataFilePath) -Content '[]'
        (Get-UserDeviceRecords).Count | Should -Be 0
        Write-UserDeviceRecords -Records @()
    }
}