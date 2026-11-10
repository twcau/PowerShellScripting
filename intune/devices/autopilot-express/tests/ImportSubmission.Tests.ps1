<#
.SYNOPSIS
    Tests the append-only ImportSubmissions ledger and legacy import journal migration.
.DESCRIPTION
    IMPORT-RECEIPTS (owner decision 2026-11-03) keeps hash-free Autopilot import
    evidence in each device record's ImportSubmissions ledger, mirroring the
    SYNC-RECEIPTS sync ledger. Production functions are extracted without starting
    the CLI. A Write-UserDeviceRecords stand-in serialises the session records to a
    TestDrive JSON store, and legacy autopilot-import-submission-*.json files are
    real TestDrive files. No operational storage, tenant or Graph access is used.
.FILECREATED
    2026-11-03
.FILELASTUPDATED
    2026-11-03
#>
BeforeAll {
    $sourcePath = Join-Path (Split-Path -Parent $PSScriptRoot) 'autopilot-express.ps1'
    $tokens = $null
    $parseErrors = $null
    $sourceAst = [System.Management.Automation.Language.Parser]::ParseFile($sourcePath, [ref]$tokens, [ref]$parseErrors)
    if ($parseErrors.Count) { throw ($parseErrors.Message -join '; ') }
    foreach ($functionName in @('ConvertTo-NormalisedValue', 'ConvertTo-AutopilotImportReceipt', 'Get-AutopilotImportReceipt', 'Save-DeviceLedgerEntry', 'Import-LegacyAutopilotImportEvidence', 'Assert-FileWriteRecoveryState', 'Assert-AttemptHistory', 'Test-AttemptEvidenceEqual', 'Assert-AttemptHistoryPreserved')) {
        $definition = $sourceAst.Find({ param($node) $node -is [System.Management.Automation.Language.FunctionDefinitionAst] -and $node.Name -eq $functionName }, $true)
        if ($null -eq $definition) { throw ('Missing function: {0}' -f $functionName) }
        Set-Item -Path ('Function:{0}' -f $definition.Name) -Value $definition.Body.GetScriptBlock()
    }
    function Assert-ActiveStorageReservation { throw 'Unexpected reservation check' }
    function Write-AutopilotExpressLog { param($Message, $Level) $null = $Message, $Level }
    function Get-LiveTenantBinding { param($Device, [switch]$AllowUnbound) $null = $Device, $AllowUnbound; return $script:liveTenantId }
    # Durable-store stand-in for the production checkpointed records writer.
    function Write-UserDeviceRecords {
        param($Records)
        Set-Content -LiteralPath $script:storePath -Value (ConvertTo-Json -InputObject @($Records) -Depth 10) -NoNewline
    }
    $script:realSave = ${function:Write-UserDeviceRecords}

    function Get-StoredImportLedger {
        <# Read one record's import ledger back from the durable store as hashtables. #>
        param([string]$RecordId = 'record-1')
        if (-not (Test-Path -LiteralPath $script:storePath)) { return , @() }
        $jsonParameters = @{}
        if ((Get-Command ConvertFrom-Json).Parameters.ContainsKey('DateKind')) { $jsonParameters.DateKind = 'String' }
        $stored = @((Get-Content -LiteralPath $script:storePath -Raw | ConvertFrom-Json @jsonParameters) | ForEach-Object { $_ })
        $record = $stored | Where-Object { $_.RecordId -eq $RecordId } | Select-Object -First 1
        $entries = foreach ($entry in @($record.ImportSubmissions)) {
            if ($null -eq $entry) { continue }
            $map = @{}
            foreach ($property in $entry.PSObject.Properties) { $map[$property.Name] = $property.Value }
            $map
        }
        return , @($entries)
    }

    function Get-ImportJournalFixture {
        <# Build a valid eight-field legacy journal for a record. #>
        param([string]$RecordId = 'record-1', [string]$Serial = 'SERIAL1', [string]$State = 'Accepted')
        $autopilotImportId = if ($State -eq 'Accepted') { 'ffffffff-2222-3333-4444-555555555555' } else { '' }
        return [ordered]@{ SchemaVersion = 1; RecordId = $RecordId; TenantId = 'tenant-1'; Serial = $Serial; ImportId = 'aaaaaaaa-2222-3333-4444-555555555555'; AutopilotImportId = $autopilotImportId; State = $State; SubmittedAt = '2026-10-13T09:00:00.0000000Z' }
    }
}

Describe 'Import submission ledger saves' {
    BeforeEach {
        $script:storePath = Join-Path $TestDrive 'records-store.json'
        $script:device = @{ RecordId = 'record-1'; Serial = 'SERIAL1'; ImportSubmissions = @() }
        $script:InventoryRecords = @{ Value = @($script:device) }
        Mock Write-UserDeviceRecords { & $script:realSave -Records $Records }
        $script:entry = @{} + (Get-ImportJournalFixture -State 'Submitting')
    }

    It 'appends an entry to the import ledger and saves the session records durably' {
        Save-DeviceLedgerEntry -Device $script:device -LedgerName 'ImportSubmissions' -Entry $script:entry
        $script:device.ImportSubmissions.Count | Should -Be 1
        (Get-StoredImportLedger)[0].State | Should -BeExactly 'Submitting'
        Should -Invoke Write-UserDeviceRecords -Times 1 -Exactly
    }

    It 'restores the previous ledger when a Submitting save fails, because no upload follows' {
        Mock Write-UserDeviceRecords { throw 'Synthetic save failure' }
        { Save-DeviceLedgerEntry -Device $script:device -LedgerName 'ImportSubmissions' -Entry $script:entry } | Should -Throw '*Synthetic save failure*'
        @($script:device.ImportSubmissions).Count | Should -Be 0
    }

    It 'keeps an Accepted entry in memory when its save fails, so a later save records it' {
        Mock Write-UserDeviceRecords { throw 'Synthetic save failure' }
        $accepted = @{} + (Get-ImportJournalFixture -State 'Accepted')
        { Save-DeviceLedgerEntry -Device $script:device -LedgerName 'ImportSubmissions' -Entry $accepted } | Should -Throw '*Synthetic save failure*'
        @($script:device.ImportSubmissions).Count | Should -Be 1
    }

    It 'refuses a device that is not in the active session records' {
        $other = @{ RecordId = 'record-1'; Serial = 'SERIAL1'; ImportSubmissions = @() }
        { Save-DeviceLedgerEntry -Device $other -LedgerName 'ImportSubmissions' -Entry $script:entry } | Should -Throw '*active session records*'
        Should -Invoke Write-UserDeviceRecords -Times 0 -Exactly
    }

    It 'rejects an unknown ledger name' {
        { Save-DeviceLedgerEntry -Device $script:device -LedgerName 'OtherSubmissions' -Entry $script:entry } | Should -Throw
        Should -Invoke Write-UserDeviceRecords -Times 0 -Exactly
    }
}

Describe 'Submission ledgers are append-only before persistence' -ForEach @(
    @{ Ledger = 'ImportSubmissions'; Label = 'import submission' },
    @{ Ledger = 'SyncSubmissions'; Label = 'sync submission' }
) {
    BeforeEach {
        $first = @{ State = 'Submitting'; RecordId = 'record-1'; Serial = 'SERIAL1'; RecordedAt = '2026-10-13T09:00:00.0000000Z' }
        $script:existing = @{ RecordId = 'record-1'; Serial = 'SERIAL1'; $Ledger = @($first) }
        $script:proposed = @{ RecordId = 'record-1'; Serial = 'SERIAL1'; $Ledger = @(@{} + $first) }
    }

    It 'accepts an unchanged <Ledger> ledger and an appended entry' {
        { Assert-AttemptHistoryPreserved -Records @($script:proposed) -ExistingRecords @($script:existing) } | Should -Not -Throw
        $script:proposed[$Ledger] = @($script:proposed[$Ledger]) + , @{ State = 'Accepted'; RecordId = 'record-1'; Serial = 'SERIAL1'; RecordedAt = '2026-10-13T09:05:00.0000000Z' }
        { Assert-AttemptHistoryPreserved -Records @($script:proposed) -ExistingRecords @($script:existing) } | Should -Not -Throw
    }

    It 'refuses truncation of the <Ledger> ledger' {
        $script:proposed[$Ledger] = @()
        { Assert-AttemptHistoryPreserved -Records @($script:proposed) -ExistingRecords @($script:existing) } | Should -Throw ('Persisted {0} ledger truncation is refused.' -f $Label)
    }

    It 'refuses alteration of an earlier <Ledger> entry' {
        $script:proposed[$Ledger][0].State = 'Accepted'
        { Assert-AttemptHistoryPreserved -Records @($script:proposed) -ExistingRecords @($script:existing) } | Should -Throw ('Persisted {0} ledger alteration is refused.' -f $Label)
    }
}

Describe 'Legacy import evidence migration' {
    BeforeEach {
        $script:Runtime = @{ IsDemoMode = $false }
        $script:liveTenantId = 'tenant-1'
        $script:Storage = @{ DataPath = (Join-Path $TestDrive ([guid]::NewGuid().Guid)) }
        New-Item -ItemType Directory -Path $script:Storage.DataPath | Out-Null
        $script:storePath = Join-Path $script:Storage.DataPath 'records-store.json'
        $script:records = @(
            @{ RecordId = 'record-1'; Serial = 'SERIAL1'; TenantId = 'tenant-1'; ImportSubmissions = @() },
            @{ RecordId = 'record-2'; Serial = 'SERIAL2'; TenantId = ''; ImportSubmissions = @() }
        )
        Mock Assert-ActiveStorageReservation {}
        Mock Write-AutopilotExpressLog {}
        Mock Write-UserDeviceRecords { & $script:realSave -Records $Records }
        Set-Content -LiteralPath (Join-Path $script:Storage.DataPath 'autopilot-import-submission-record-1.json') -NoNewline -Value ((Get-ImportJournalFixture) | ConvertTo-Json -Compress)
        Set-Content -LiteralPath (Join-Path $script:Storage.DataPath 'autopilot-import-submission-record-2.json') -NoNewline -Value ((Get-ImportJournalFixture -RecordId 'record-2' -Serial 'SERIAL2' -State 'Submitting') | ConvertTo-Json -Compress)
    }

    It 'folds journal files into matching records, saves once, then deletes them' {
        Import-LegacyAutopilotImportEvidence -Records $script:records | Should -Be 2
        $accepted = (Get-StoredImportLedger -RecordId 'record-1')[0]
        $accepted.State | Should -BeExactly 'Accepted'
        $accepted.AutopilotImportId | Should -BeExactly 'ffffffff-2222-3333-4444-555555555555'
        $accepted.SubmittedAt | Should -BeExactly '2026-10-13T09:00:00.0000000Z'
        $accepted.Source | Should -BeExactly 'MigratedReceiptFile'
        $accepted.Contains('RecordedAt') | Should -BeTrue
        (Get-StoredImportLedger -RecordId 'record-2')[0].State | Should -BeExactly 'Submitting'
        @(Get-ChildItem -LiteralPath $script:Storage.DataPath -Filter 'autopilot-import-submission-*').Count | Should -Be 0
        Should -Invoke Write-UserDeviceRecords -Times 1 -Exactly
        Should -Invoke Write-AutopilotExpressLog -Times 1 -Exactly -ParameterFilter { $Level -eq 'INFO' -and $Message -match 'files=2; ledger entries added=2; files deleted=2; kept for review=0' }
    }

    It 'is idempotent: a second run finds nothing and does not save' {
        [void](Import-LegacyAutopilotImportEvidence -Records $script:records)
        Import-LegacyAutopilotImportEvidence -Records $script:records | Should -Be 0
        $script:records[0].ImportSubmissions.Count | Should -Be 1
        Should -Invoke Write-UserDeviceRecords -Times 1 -Exactly
    }

    It 'skips duplicate evidence already in the ledger but still removes the file' {
        [void](Import-LegacyAutopilotImportEvidence -Records $script:records)
        $path = Join-Path $script:Storage.DataPath 'autopilot-import-submission-record-1.json'
        Set-Content -LiteralPath $path -NoNewline -Value ((Get-ImportJournalFixture) | ConvertTo-Json -Compress)
        Import-LegacyAutopilotImportEvidence -Records $script:records | Should -Be 1
        $script:records[0].ImportSubmissions.Count | Should -Be 1
        Test-Path -LiteralPath $path | Should -BeFalse
        Should -Invoke Write-UserDeviceRecords -Times 1 -Exactly
    }

    It 'keeps <Label> files for review without changing records' -ForEach @(
        @{ Label = 'unmatched'; Name = 'autopilot-import-submission-record-9.json'; Change = @{ RecordId = 'record-9' } },
        @{ Label = 'serial-mismatched'; Name = 'autopilot-import-submission-record-1.json'; Change = @{ Serial = 'OTHER' } },
        @{ Label = 'tenant-mismatched'; Name = 'autopilot-import-submission-record-1.json'; Change = @{ TenantId = 'tenant-2' } },
        @{ Label = 'hash-bearing'; Name = 'autopilot-import-submission-record-1.json'; Change = @{ HardwareIdentifier = 'cHJpdmF0ZQ==' } },
        @{ Label = 'bad-identifier'; Name = 'autopilot-import-submission-record-1.json'; Change = @{ ImportId = 'not-a-guid' } },
        @{ Label = 'name-mismatched'; Name = 'autopilot-import-submission-record-2.json'; Change = @{} },
        @{ Label = 'unreadable'; Name = 'autopilot-import-submission-record-1.json'; Change = $null }
    ) {
        Get-ChildItem -LiteralPath $script:Storage.DataPath -Filter 'autopilot-import-submission-*' | Remove-Item
        $journal = Get-ImportJournalFixture
        if ($null -ne $Change) { foreach ($key in $Change.Keys) { $journal[$key] = $Change[$key] } }
        $content = if ($null -eq $Change) { '{' } else { $journal | ConvertTo-Json -Compress }
        $path = Join-Path $script:Storage.DataPath $Name
        Set-Content -LiteralPath $path -Value $content -NoNewline
        Import-LegacyAutopilotImportEvidence -Records $script:records | Should -Be 0
        Get-Content -LiteralPath $path -Raw | Should -BeExactly $content
        $script:records[0].ImportSubmissions.Count | Should -Be 0
        $script:records[1].ImportSubmissions.Count | Should -Be 0
        Should -Invoke Write-UserDeviceRecords -Times 0 -Exactly
        Should -Invoke Write-AutopilotExpressLog -Times 1 -Exactly -ParameterFilter { $Level -eq 'WARN' -and $Message -match 'kept for review' }
    }

    It 'keeps a file that has an interrupted-save artefact' {
        $path = Join-Path $script:Storage.DataPath 'autopilot-import-submission-record-1.json'
        Set-Content -LiteralPath ('{0}.pending' -f $path) -Value 'retained-evidence' -NoNewline
        [void](Import-LegacyAutopilotImportEvidence -Records $script:records)
        Test-Path -LiteralPath $path | Should -BeTrue
        $script:records[0].ImportSubmissions.Count | Should -Be 0
        Should -Invoke Write-AutopilotExpressLog -Times 1 -Exactly -ParameterFilter { $Level -eq 'WARN' -and $Message -match 'Interrupted save recovery' }
    }

    It 'deletes nothing when the records save fails' {
        Mock Write-UserDeviceRecords { throw 'Synthetic records save failure' }
        { Import-LegacyAutopilotImportEvidence -Records $script:records } | Should -Throw '*Synthetic records save failure*'
        @(Get-ChildItem -LiteralPath $script:Storage.DataPath -Filter 'autopilot-import-submission-*').Count | Should -Be 2
    }

    It 'does nothing in Demo mode' {
        $script:Runtime.IsDemoMode = $true
        Import-LegacyAutopilotImportEvidence -Records $script:records | Should -Be 0
        @(Get-ChildItem -LiteralPath $script:Storage.DataPath -Filter 'autopilot-import-submission-*').Count | Should -Be 2
        Should -Invoke Assert-ActiveStorageReservation -Times 0 -Exactly
        Should -Invoke Write-UserDeviceRecords -Times 0 -Exactly
    }

    It 'resumes a migrated receipt from the ledger so no repeat upload is offered' {
        [void](Import-LegacyAutopilotImportEvidence -Records $script:records)
        $receipt = Get-AutopilotImportReceipt -Device $script:records[0]
        $receipt.State | Should -BeExactly 'Accepted'
        $receipt.AutopilotImportId | Should -BeExactly 'ffffffff-2222-3333-4444-555555555555'
        $receipt.Count | Should -Be 8
    }
}