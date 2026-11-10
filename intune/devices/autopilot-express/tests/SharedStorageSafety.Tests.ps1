<#
.SYNOPSIS
    Offline checks for shared-storage development safety boundaries.
.DESCRIPTION
    Extracts production helpers without launching the CLI or accessing tenant
    services. Unsupported storage must fail before a directory probe or write.
    Requires Pester 5 and FullLanguage for source extraction.
#>
BeforeAll {
    $sourcePath = Join-Path (Split-Path -Parent $PSScriptRoot) 'autopilot-express.ps1'
    $tokens = $null
    $parseErrors = $null
    $sourceAst = [System.Management.Automation.Language.Parser]::ParseFile($sourcePath, [ref]$tokens, [ref]$parseErrors)
    if ($parseErrors.Count) { throw ($parseErrors.Message -join '; ') }
    foreach ($functionName in @('Assert-StorageModeSupported', 'Initialize-StorageLocation', 'Get-LocalCheckpointPath', 'Assert-LocalCheckpointState', 'Start-SharedStoreReservation', 'Assert-SharedStoreReservation', 'Assert-SharedStoreSnapshot', 'Get-SharedStoreSnapshot', 'Write-SharedStoreSnapshot', 'Stop-LocalSessionLock', 'Assert-DeviceRecordIdentity', 'Assert-BenchPositionIdentity', 'ConvertTo-NormalisedValue', 'Test-AttemptEvidenceEqual', 'Write-Utf8File', 'New-ParentDirectory', 'Get-StorageFileEncoding', 'Assert-FileWriteRecoveryState')) {
        $definition = $sourceAst.Find({ param($node) $node -is [System.Management.Automation.Language.FunctionDefinitionAst] -and $node.Name -eq $functionName }, $true)
        if (-not $definition) { throw ('Missing function: {0}' -f $functionName) }
        Set-Item -Path ('Function:{0}' -f $definition.Name) -Value $definition.Body.GetScriptBlock()
    }
    foreach ($functionName in @('Assert-AttemptHistory', 'Assert-AttemptHistoryPreserved', 'ConvertTo-StepHashtable', 'Get-SharedStoreRecoveryInspection', 'Get-SharedStoreMigrationPreview')) {
        $definition = $sourceAst.Find({ param($node) $node -is [System.Management.Automation.Language.FunctionDefinitionAst] -and $node.Name -eq $functionName }, $true)
        if (-not $definition) { throw ('Missing function: {0}' -f $functionName) }
        Set-Item -Path ('Function:{0}' -f $definition.Name) -Value $definition.Body.GetScriptBlock()
    }
    function Get-RepoStorageBasePath { return $TestDrive }
    function Get-FallbackStorageBasePath { return (Join-Path $TestDrive 'fallback') }
    function Test-DirectoryWritable { param($Path) throw ('Unexpected probe: {0}' -f $Path) }
    function Write-AutopilotExpressLog { param($Message, $Level) throw ('Unexpected log: {0} {1}' -f $Level, $Message) }
}

Describe 'Unsupported shared-mode entry-point guard' {
    BeforeEach {
        $script:RuntimeConfig = @{ storage = @{ mode = 'Local' } }
        $script:Config = @{ DataFolderRelative = 'data' }
        $script:Storage = @{ Initialised = $false; BasePath = ''; DataPath = ''; UsingFallback = $false }
        Mock Test-DirectoryWritable { return $true }
        Mock Write-AutopilotExpressLog {}
    }

    It 'retains explicit Local storage initialisation' {
        Initialize-StorageLocation
        $script:Storage.Initialised | Should -BeTrue
        Should -Invoke Test-DirectoryWritable -Times 1 -Exactly
    }

    It 'retains legacy missing storage settings and mode' {
        foreach ($settings in @(@{}, @{ storage = @{} })) {
            $script:RuntimeConfig = $settings
            { Assert-StorageModeSupported } | Should -Not -Throw
        }
    }

    It 'rejects Shared before probes and does not fall back locally' {
        $script:RuntimeConfig.storage = @{ mode = 'Shared'; sharedDataRoot = '\\example.invalid\bench' }
        { Initialize-StorageLocation } | Should -Throw '*Shared storage is disabled*'
        $script:Storage.Initialised | Should -BeFalse
        Should -Invoke Test-DirectoryWritable -Times 0 -Exactly
    }

    It 'checks the mode even when storage was already initialised' {
        $script:Storage.Initialised = $true
        $script:RuntimeConfig.storage.mode = 'Shared'
        { Initialize-StorageLocation } | Should -Throw '*Shared storage is disabled*'
        Should -Invoke Test-DirectoryWritable -Times 0 -Exactly
    }

    It 'rejects unknown empty and non-text modes before probes' {
        foreach ($mode in @('Network', '', ' ', $null, 1, @('Local', 'Shared'))) {
            $script:RuntimeConfig.storage.mode = $mode
            { Initialize-StorageLocation } | Should -Throw '*storage*'
        }
        Should -Invoke Test-DirectoryWritable -Times 0 -Exactly
    }

    It 'rejects malformed storage settings before probes' {
        $script:RuntimeConfig.storage = 'Shared'
        { Initialize-StorageLocation } | Should -Throw '*dictionary*'
        Should -Invoke Test-DirectoryWritable -Times 0 -Exactly
    }
}

Describe 'Read-only initial shared migration preview' {
    BeforeEach {
        $script:previewRoot = Join-Path $TestDrive ([guid]::NewGuid().Guid)
        New-Item -ItemType Directory -Path $script:previewRoot | Out-Null
        $script:previewLock = Start-SharedStoreReservation -Root $script:previewRoot
        $script:migrationSource = @{
            SchemaVersion = 1; Revision = 4
            Devices = @(@{ RecordId = 'source-one'; Serial = 'SOURCE-ONE'; ConfigItem = '123'; Status = 'in-progress'; AttemptHistory = @() })
            Bench = @{ Positions = @(@{ Index = 1; Serial = 'SOURCE-ONE'; ConfigItem = '123' }) }
            Audit = @(@{ RecordId = 'source-one'; Action = 'Inducted'; Data = @{ Values = @('first', 'second') } })
        }
    }
    AfterEach { Stop-LocalSessionLock -Lock $script:previewLock }

    It 'preserves captured evidence without writing or approving migration' {
        $script:migrationSource.Devices[0].AttemptHistory = @(@{
            AttemptId = '11111111-1111-1111-1111-111111111111'; Sequence = 1
            StepId = 'A'; ActionName = 'ResolveAutopilotDevice'; Timestamp = $null
            Actor = 'Synthetic technician'; Mode = 'Demo'; TenantId = ''
            Serial = 'SOURCE-ONE'; RecordId = 'source-one'; EvidenceKind = 'LegacyEvidence'
            Result = @{ Completed = $true; Success = $true; CompletionState = 'Simulated'; IsSimulated = $true; Data = @{}; Summary = 'Original'; Notes = '' }
        })
        $before = ConvertTo-NormalisedValue -Value $script:migrationSource
        Mock Write-Utf8File { throw 'Preview must not write' }
        $preview = Get-SharedStoreMigrationPreview -Root $script:previewRoot -Lock $script:previewLock -SourceSnapshot $script:migrationSource
        $preview.ExpectedRevision | Should -Be 0
        $preview.SourceRevision | Should -Be 4
        $preview.DeviceCount | Should -Be 1
        $preview.PositionCount | Should -Be 1
        $preview.AuditCount | Should -Be 1
        $preview.ReviewRequired | Should -BeTrue
        $preview.MigrationApproved | Should -BeFalse
        $preview.Snapshot.Revision | Should -Be 0
        Test-AttemptEvidenceEqual -Left $before -Right $script:migrationSource | Should -BeTrue
        Test-AttemptEvidenceEqual -Left $preview.Snapshot.Devices -Right $before.Devices | Should -BeTrue
        Test-AttemptEvidenceEqual -Left $preview.Snapshot.Bench -Right $before.Bench | Should -BeTrue
        Test-AttemptEvidenceEqual -Left $preview.Snapshot.Audit -Right $before.Audit | Should -BeTrue
        $preview.Snapshot.Devices[0].Serial = 'changed'
        $preview.Snapshot.Devices[0].AttemptHistory[0].Result.Summary = 'changed'
        $preview.Snapshot.Bench.Positions[0].Serial = 'changed'
        $preview.Snapshot.Audit[0].Data.Values[0] = 'changed'
        Test-AttemptEvidenceEqual -Left $before -Right $script:migrationSource | Should -BeTrue
        @(Get-ChildItem -LiteralPath $script:previewRoot).Count | Should -Be 1
        Should -Invoke Write-Utf8File -Times 0 -Exactly
    }

    It 'retains empty collection shapes without declaring migration complete' {
        $script:migrationSource.Devices = @()
        $script:migrationSource.Bench.Positions = @()
        $script:migrationSource.Audit = @()
        $preview = Get-SharedStoreMigrationPreview -Root $script:previewRoot -Lock $script:previewLock -SourceSnapshot $script:migrationSource
        $preview.DeviceCount | Should -Be 0
        $preview.PositionCount | Should -Be 0
        $preview.AuditCount | Should -Be 0
        $preview.Snapshot.Devices -is [array] | Should -BeTrue
        $preview.Snapshot.Bench.Positions -is [array] | Should -BeTrue
        $preview.Snapshot.Audit -is [array] | Should -BeTrue
        $preview.MigrationApproved | Should -BeFalse
    }

    It 'rejects destination <State> even at revision zero' -TestCases @(
        @{ State = 'devices' }
        @{ State = 'bench positions' }
        @{ State = 'audit' }
    ) {
        param($State)
        $destination = @{ SchemaVersion = 1; Revision = 0; Devices = @(); Bench = @{ Positions = @() }; Audit = @() }
        switch ($State) {
            'devices' { $destination.Devices = @(@{ RecordId = 'existing'; Serial = 'EXISTING' }) }
            'bench positions' { $destination.Bench.Positions = @(@{ Index = 1; Serial = ''; ConfigItem = '' }) }
            'audit' { $destination.Audit = @(@{ Action = 'Existing' }) }
        }
        $path = Join-Path $script:previewRoot 'autopilot-shared.snapshot.json'
        Set-Content -LiteralPath $path -Value ($destination | ConvertTo-Json -Depth 100) -Encoding UTF8
        $before = Get-Content -LiteralPath $path -Raw
        { Get-SharedStoreMigrationPreview -Root $script:previewRoot -Lock $script:previewLock -SourceSnapshot $script:migrationSource } | Should -Throw '*pristine destination*'
        (Get-Content -LiteralPath $path -Raw) | Should -BeExactly $before
    }

    It 'refuses an already committed empty destination' {
        $destination = Get-SharedStoreSnapshot -Root $script:previewRoot -Lock $script:previewLock
        Write-SharedStoreSnapshot -Root $script:previewRoot -Lock $script:previewLock -ExpectedRevision 0 -Snapshot $destination | Should -Be 1
        { Get-SharedStoreMigrationPreview -Root $script:previewRoot -Lock $script:previewLock -SourceSnapshot $script:migrationSource } | Should -Throw '*pristine destination*'
        (Get-SharedStoreSnapshot -Root $script:previewRoot -Lock $script:previewLock).Revision | Should -Be 1
    }

    It 'rejects malformed source <Kind> without creating destination content' -TestCases @(
        @{ Kind = 'envelope' }
        @{ Kind = 'duplicate identity' }
        @{ Kind = 'bench link' }
        @{ Kind = 'history' }
    ) {
        param($Kind)
        switch ($Kind) {
            'envelope' { $script:migrationSource.SchemaVersion = '1' }
            'duplicate identity' { $script:migrationSource.Devices += $script:migrationSource.Devices[0] }
            'bench link' { $script:migrationSource.Bench.Positions[0].Serial = 'NOT-IN-SOURCE' }
            'history' { $script:migrationSource.Devices[0].AttemptHistory = $null }
        }
        { Get-SharedStoreMigrationPreview -Root $script:previewRoot -Lock $script:previewLock -SourceSnapshot $script:migrationSource } | Should -Throw
        @(Get-ChildItem -LiteralPath $script:previewRoot).Count | Should -Be 1
    }

    It 'refuses interrupted destination evidence instead of proposing an import' {
        $path = Join-Path $script:previewRoot 'autopilot-shared.snapshot.json.pending'
        Set-Content -LiteralPath $path -Value '{}' -Encoding UTF8
        { Get-SharedStoreMigrationPreview -Root $script:previewRoot -Lock $script:previewLock -SourceSnapshot $script:migrationSource } | Should -Throw '*Interrupted save*'
        (Get-Content -LiteralPath $path -Raw).Trim() | Should -Be '{}'
    }

    It 'rechecks destination ownership before returning evidence' {
        $script:reservationChecks = 0
        Mock Assert-SharedStoreReservation {
            $script:reservationChecks++
            if ($script:reservationChecks -gt 1) { throw 'Synthetic changed ownership' }
        }
        { Get-SharedStoreMigrationPreview -Root $script:previewRoot -Lock $script:previewLock -SourceSnapshot $script:migrationSource } | Should -Throw '*changed ownership*'
        Should -Invoke Assert-SharedStoreReservation -Times 2 -Exactly
    }
}

Describe 'Offline revisioned shared snapshot primitive' {
    BeforeEach {
        $script:snapshotRoot = Join-Path $TestDrive ([guid]::NewGuid().Guid)
        New-Item -ItemType Directory -Path $script:snapshotRoot | Out-Null
        $script:snapshotLock = Start-SharedStoreReservation -Root $script:snapshotRoot
    }
    AfterEach { Stop-LocalSessionLock -Lock $script:snapshotLock }

    It 'round trips a device bench and audit as one revision without mutating the caller' {
        $snapshot = Get-SharedStoreSnapshot -Root $script:snapshotRoot -Lock $script:snapshotLock
        $snapshot.Devices = @(@{ RecordId = 'one'; Serial = 'SHARED-ONE'; ConfigItem = '123'; Status = 'in-progress' })
        $snapshot.Bench.Positions = @(@{ Index = 1; Serial = 'SHARED-ONE'; ConfigItem = '123' })
        $snapshot.Audit = @(@{ RecordId = 'one'; Action = 'Inducted' })
        Write-SharedStoreSnapshot -Root $script:snapshotRoot -Lock $script:snapshotLock -ExpectedRevision 0 -Snapshot $snapshot | Should -Be 1
        $snapshot.Revision | Should -Be 0
        $saved = Get-SharedStoreSnapshot -Root $script:snapshotRoot -Lock $script:snapshotLock
        $saved.Revision | Should -Be 1
        $saved.Devices.Count | Should -Be 1
        $saved.Bench.Positions[0].Serial | Should -Be 'SHARED-ONE'
        $saved.Audit[0].Action | Should -Be 'Inducted'
        $saved.LastWriter.User | Should -Be $env:USERNAME
    }

    It 'retains empty arrays in a saved snapshot' {
        $snapshot = Get-SharedStoreSnapshot -Root $script:snapshotRoot -Lock $script:snapshotLock
        Write-SharedStoreSnapshot -Root $script:snapshotRoot -Lock $script:snapshotLock -ExpectedRevision 0 -Snapshot $snapshot | Should -Be 1
        $saved = Get-SharedStoreSnapshot -Root $script:snapshotRoot -Lock $script:snapshotLock
        $saved.Devices -is [array] | Should -BeTrue
        $saved.Bench.Positions -is [array] | Should -BeTrue
        $saved.Audit -is [array] | Should -BeTrue
    }

    It 'rejects a second reservation and allows reacquisition after release' {
        { Start-SharedStoreReservation -Root $script:snapshotRoot } | Should -Throw
        Stop-LocalSessionLock -Lock $script:snapshotLock
        $script:snapshotLock = Start-SharedStoreReservation -Root $script:snapshotRoot
    }

    It 'reports missing initial copies without creating a snapshot or approving recovery' {
        $report = Get-SharedStoreRecoveryInspection -Root $script:snapshotRoot -Lock $script:snapshotLock
        $report.Copies.Count | Should -Be 3
        @($report.Copies | Where-Object { $_.State -eq 'Missing' }).Count | Should -Be 3
        $report.ReviewRequired | Should -BeFalse
        $report.RecoveryApproved | Should -BeFalse
        @(Get-ChildItem -LiteralPath $script:snapshotRoot).Count | Should -Be 1
    }

    It 'inspects interrupted pending evidence without promoting or removing files' {
        $snapshot = Get-SharedStoreSnapshot -Root $script:snapshotRoot -Lock $script:snapshotLock
        Write-SharedStoreSnapshot -Root $script:snapshotRoot -Lock $script:snapshotLock -ExpectedRevision 0 -Snapshot $snapshot | Should -Be 1
        $path = Join-Path $script:snapshotRoot 'autopilot-shared.snapshot.json'
        $before = Get-Content -LiteralPath $path -Raw
        Copy-Item -LiteralPath $path -Destination ('{0}.pending' -f $path)
        New-Item -ItemType File -Path ('{0}.write-in-progress' -f $path) | Out-Null
        $report = Get-SharedStoreRecoveryInspection -Root $script:snapshotRoot -Lock $script:snapshotLock
        $report.MarkerPresent | Should -BeTrue
        $report.ReviewRequired | Should -BeTrue
        $report.RecoveryApproved | Should -BeFalse
        $report.Copies[0].Revision | Should -Be 1
        $report.Copies[1].Revision | Should -Be 1
        $report.Copies[1].DeviceCount | Should -Be 0
        (Get-Content -LiteralPath $path -Raw) | Should -BeExactly $before
        (Get-Content -LiteralPath ('{0}.pending' -f $path) -Raw) | Should -BeExactly $before
        Test-Path -LiteralPath ('{0}.write-in-progress' -f $path) | Should -BeTrue
        { Get-SharedStoreSnapshot -Root $script:snapshotRoot -Lock $script:snapshotLock } | Should -Throw '*Interrupted save*'
    }

    It 'reports invalid copy content <Content> without replacing it' -TestCases @(
        @{ Content = '' }
        @{ Content = '{' }
        @{ Content = '{}' }
    ) {
        param($Content)
        $path = Join-Path $script:snapshotRoot 'autopilot-shared.snapshot.json.pending'
        Set-Content -LiteralPath $path -Value $Content -NoNewline -Encoding UTF8
        $report = Get-SharedStoreRecoveryInspection -Root $script:snapshotRoot -Lock $script:snapshotLock
        $report.Copies[1].State | Should -Be 'Invalid'
        $report.Copies[1].Snapshot | Should -BeNullOrEmpty
        $report.Copies[1].Revision | Should -BeNullOrEmpty
        $report.ReviewRequired | Should -BeTrue
        [string]$retained = Get-Content -LiteralPath $path -Raw
        $retained | Should -BeExactly $Content
    }

    It 'reports an orphan previous copy without making it authoritative' {
        $snapshot = Get-SharedStoreSnapshot -Root $script:snapshotRoot -Lock $script:snapshotLock
        Write-SharedStoreSnapshot -Root $script:snapshotRoot -Lock $script:snapshotLock -ExpectedRevision 0 -Snapshot $snapshot | Should -Be 1
        $path = Join-Path $script:snapshotRoot 'autopilot-shared.snapshot.json'
        Move-Item -LiteralPath $path -Destination ('{0}.previous' -f $path)
        $report = Get-SharedStoreRecoveryInspection -Root $script:snapshotRoot -Lock $script:snapshotLock
        $report.Copies[0].State | Should -Be 'Missing'
        $report.Copies[2].State | Should -Be 'Valid'
        $report.ReviewRequired | Should -BeTrue
        $report.RecoveryApproved | Should -BeFalse
        Test-Path -LiteralPath $path | Should -BeFalse
    }

    It 'rejects an incorrect reservation before inspecting any copy' {
        $wrongLock = @{ Path = $script:snapshotLock.Path; Token = 'not-owner' }
        Mock Get-Content { throw 'Copy must not be read' } -ParameterFilter { $LiteralPath -like '*snapshot.json*' }
        { Get-SharedStoreRecoveryInspection -Root $script:snapshotRoot -Lock $wrongLock } | Should -Throw '*ownership changed*'
        Should -Invoke Get-Content -Times 0 -Exactly -ParameterFilter { $LiteralPath -like '*snapshot.json*' }
    }

    It 'refuses to return inspection evidence when ownership changes during the read' {
        $snapshot = Get-SharedStoreSnapshot -Root $script:snapshotRoot -Lock $script:snapshotLock
        Write-SharedStoreSnapshot -Root $script:snapshotRoot -Lock $script:snapshotLock -ExpectedRevision 0 -Snapshot $snapshot | Should -Be 1
        $script:inspectionChecks = 0
        Mock Assert-SharedStoreReservation {
            $script:inspectionChecks++
            if ($script:inspectionChecks -eq 2) { throw 'Synthetic ownership changed' }
        }
        { Get-SharedStoreRecoveryInspection -Root $script:snapshotRoot -Lock $script:snapshotLock } | Should -Throw '*ownership changed*'
        Should -Invoke Assert-SharedStoreReservation -Times 2 -Exactly
    }

    It 'rejects another root or ownership token before snapshot access' {
        $other = Join-Path $TestDrive 'other-root'
        New-Item -ItemType Directory -Path $other -Force | Out-Null
        { Get-SharedStoreSnapshot -Root $other -Lock $script:snapshotLock } | Should -Throw '*this root*'
        $wrongLock = @{ Path = $script:snapshotLock.Path; Token = 'not-owner' }
        { Get-SharedStoreSnapshot -Root $script:snapshotRoot -Lock $wrongLock } | Should -Throw '*ownership changed*'
    }

    It 'rejects a stale writer without altering the committed snapshot' {
        $snapshot = Get-SharedStoreSnapshot -Root $script:snapshotRoot -Lock $script:snapshotLock
        Write-SharedStoreSnapshot -Root $script:snapshotRoot -Lock $script:snapshotLock -ExpectedRevision 0 -Snapshot $snapshot | Should -Be 1
        $path = Join-Path $script:snapshotRoot 'autopilot-shared.snapshot.json'
        $before = Get-Content -LiteralPath $path -Raw
        { Write-SharedStoreSnapshot -Root $script:snapshotRoot -Lock $script:snapshotLock -ExpectedRevision 0 -Snapshot $snapshot } | Should -Throw '*revision conflict*'
        (Get-Content -LiteralPath $path -Raw) | Should -BeExactly $before
    }

    It 'rejects mismatched bench links and duplicate workflow identities' {
        $snapshot = Get-SharedStoreSnapshot -Root $script:snapshotRoot -Lock $script:snapshotLock
        $snapshot.Bench.Positions = @(@{ Index = 1; Serial = 'MISSING'; ConfigItem = '123' })
        { Write-SharedStoreSnapshot -Root $script:snapshotRoot -Lock $script:snapshotLock -ExpectedRevision 0 -Snapshot $snapshot } | Should -Throw '*bench identity*'
        $snapshot.Bench.Positions = @()
        $snapshot.Devices = @(@{ RecordId = 'one'; Serial = 'DUPLICATE' }, @{ RecordId = 'two'; Serial = 'duplicate' })
        { Write-SharedStoreSnapshot -Root $script:snapshotRoot -Lock $script:snapshotLock -ExpectedRevision 0 -Snapshot $snapshot } | Should -Throw '*Duplicate serial*'
    }

    It 'rejects audit truncation and rewriting while allowing append' {
        $snapshot = Get-SharedStoreSnapshot -Root $script:snapshotRoot -Lock $script:snapshotLock
        $snapshot.Audit = @(@{ Action = 'First' })
        Write-SharedStoreSnapshot -Root $script:snapshotRoot -Lock $script:snapshotLock -ExpectedRevision 0 -Snapshot $snapshot | Should -Be 1
        $saved = Get-SharedStoreSnapshot -Root $script:snapshotRoot -Lock $script:snapshotLock
        $saved.Audit = @()
        { Write-SharedStoreSnapshot -Root $script:snapshotRoot -Lock $script:snapshotLock -ExpectedRevision 1 -Snapshot $saved } | Should -Throw '*truncated*'
        $saved.Audit = @(@{ Action = 'Changed' })
        { Write-SharedStoreSnapshot -Root $script:snapshotRoot -Lock $script:snapshotLock -ExpectedRevision 1 -Snapshot $saved } | Should -Throw '*rewritten*'
        $saved.Audit = @(@{ Action = 'First' }, @{ Action = 'Second' })
        Write-SharedStoreSnapshot -Root $script:snapshotRoot -Lock $script:snapshotLock -ExpectedRevision 1 -Snapshot $saved | Should -Be 2
    }

    It 'rejects record removal and retains the previous snapshot on valid updates' {
        $snapshot = Get-SharedStoreSnapshot -Root $script:snapshotRoot -Lock $script:snapshotLock
        $snapshot.Devices = @(@{ RecordId = 'one'; Serial = 'RETAINED'; Status = 'new' })
        Write-SharedStoreSnapshot -Root $script:snapshotRoot -Lock $script:snapshotLock -ExpectedRevision 0 -Snapshot $snapshot | Should -Be 1
        $saved = Get-SharedStoreSnapshot -Root $script:snapshotRoot -Lock $script:snapshotLock
        $saved.Devices = @()
        { Write-SharedStoreSnapshot -Root $script:snapshotRoot -Lock $script:snapshotLock -ExpectedRevision 1 -Snapshot $saved } | Should -Throw '*retained*'
        $saved.Devices = @(@{ RecordId = 'one'; Serial = 'RETAINED'; Status = 'removed' })
        Write-SharedStoreSnapshot -Root $script:snapshotRoot -Lock $script:snapshotLock -ExpectedRevision 1 -Snapshot $saved | Should -Be 2
        $previous = Get-Content -LiteralPath (Join-Path $script:snapshotRoot 'autopilot-shared.snapshot.json.previous') -Raw | ConvertFrom-Json
        $previous.Revision | Should -Be 1
    }

    It 'rejects serial reassignment for a retained <Status> workflow without writing' -TestCases @(
        @{ Status = 'in-progress' }
        @{ Status = 'removed' }
    ) {
        param($Status)
        $snapshot = Get-SharedStoreSnapshot -Root $script:snapshotRoot -Lock $script:snapshotLock
        $snapshot.Devices = @(@{ RecordId = 'one'; Serial = 'ORIGINAL'; Status = $Status })
        Write-SharedStoreSnapshot -Root $script:snapshotRoot -Lock $script:snapshotLock -ExpectedRevision 0 -Snapshot $snapshot | Should -Be 1
        $path = Join-Path $script:snapshotRoot 'autopilot-shared.snapshot.json'
        $before = Get-Content -LiteralPath $path -Raw
        $saved = Get-SharedStoreSnapshot -Root $script:snapshotRoot -Lock $script:snapshotLock
        $saved.Devices[0].Serial = 'REPLACEMENT'
        { Write-SharedStoreSnapshot -Root $script:snapshotRoot -Lock $script:snapshotLock -ExpectedRevision 1 -Snapshot $saved } | Should -Throw '*serial identity*'
        (Get-Content -LiteralPath $path -Raw) | Should -BeExactly $before
        Test-Path -LiteralPath ('{0}.pending' -f $path) | Should -BeFalse
        Test-Path -LiteralPath ('{0}.write-in-progress' -f $path) | Should -BeFalse
    }

    It 'rejects serial swaps between retained workflow IDs' {
        $snapshot = Get-SharedStoreSnapshot -Root $script:snapshotRoot -Lock $script:snapshotLock
        $snapshot.Devices = @(@{ RecordId = 'one'; Serial = 'FIRST' }, @{ RecordId = 'two'; Serial = 'SECOND' })
        Write-SharedStoreSnapshot -Root $script:snapshotRoot -Lock $script:snapshotLock -ExpectedRevision 0 -Snapshot $snapshot | Should -Be 1
        $saved = Get-SharedStoreSnapshot -Root $script:snapshotRoot -Lock $script:snapshotLock
        $saved.Devices[0].Serial = 'SECOND'
        $saved.Devices[1].Serial = 'FIRST'
        { Write-SharedStoreSnapshot -Root $script:snapshotRoot -Lock $script:snapshotLock -ExpectedRevision 1 -Snapshot $saved } | Should -Throw '*serial identity*'
        (Get-SharedStoreSnapshot -Root $script:snapshotRoot -Lock $script:snapshotLock).Revision | Should -Be 1
    }

    It 'allows serial formatting and mutable CI and status updates without changing identity' {
        $snapshot = Get-SharedStoreSnapshot -Root $script:snapshotRoot -Lock $script:snapshotLock
        $snapshot.Devices = @(@{ RecordId = 'one'; Serial = 'ORIGINAL'; ConfigItem = '123'; Status = 'new' })
        Write-SharedStoreSnapshot -Root $script:snapshotRoot -Lock $script:snapshotLock -ExpectedRevision 0 -Snapshot $snapshot | Should -Be 1
        $saved = Get-SharedStoreSnapshot -Root $script:snapshotRoot -Lock $script:snapshotLock
        $saved.Devices[0].Serial = ' original '
        $saved.Devices[0].ConfigItem = '456'
        $saved.Devices[0].Status = 'removed'
        Write-SharedStoreSnapshot -Root $script:snapshotRoot -Lock $script:snapshotLock -ExpectedRevision 1 -Snapshot $saved | Should -Be 2
        $reloaded = Get-SharedStoreSnapshot -Root $script:snapshotRoot -Lock $script:snapshotLock
        $reloaded.Devices[0].ConfigItem | Should -Be '456'
        $reloaded.Devices[0].Status | Should -Be 'removed'
    }

    It 'fails closed on malformed and interrupted snapshots instead of returning revision zero' {
        $path = Join-Path $script:snapshotRoot 'autopilot-shared.snapshot.json'
        Set-Content -LiteralPath $path -Value '{}' -Encoding UTF8
        { Get-SharedStoreSnapshot -Root $script:snapshotRoot -Lock $script:snapshotLock } | Should -Throw '*envelope*'
        New-Item -ItemType File -Path ('{0}.pending' -f $path) | Out-Null
        { Get-SharedStoreSnapshot -Root $script:snapshotRoot -Lock $script:snapshotLock } | Should -Throw '*Interrupted save*'
    }

    It 'rejects a coercible schema version <Value> without creating snapshot files' -TestCases @(
        @{ Value = $true }
        @{ Value = '1' }
        @{ Value = 1.0 }
    ) {
        param($Value)
        $snapshot = Get-SharedStoreSnapshot -Root $script:snapshotRoot -Lock $script:snapshotLock
        $snapshot.SchemaVersion = $Value
        { Write-SharedStoreSnapshot -Root $script:snapshotRoot -Lock $script:snapshotLock -ExpectedRevision 0 -Snapshot $snapshot } | Should -Throw '*envelope*'
        @(Get-ChildItem -LiteralPath $script:snapshotRoot -Filter 'autopilot-shared.snapshot.json*').Count | Should -Be 0
    }

    It 'rejects malformed device records <Label> before writing' -TestCases @(
        @{ Label = 'null'; Value = $null }
        @{ Label = 'scalar'; Value = 'device' }
        @{ Label = 'numeric ID'; Value = @{ RecordId = 7; Serial = 'VALID' } }
        @{ Label = 'numeric serial'; Value = @{ RecordId = 'one'; Serial = 1234 } }
        @{ Label = 'blank serial'; Value = @{ RecordId = 'one'; Serial = ' ' } }
    ) {
        param($Label, $Value)
        $Label | Should -Not -BeNullOrEmpty
        $snapshot = Get-SharedStoreSnapshot -Root $script:snapshotRoot -Lock $script:snapshotLock
        $snapshot.Devices = @($Value)
        { Write-SharedStoreSnapshot -Root $script:snapshotRoot -Lock $script:snapshotLock -ExpectedRevision 0 -Snapshot $snapshot } | Should -Throw '*textual record IDs and serials*'
        @(Get-ChildItem -LiteralPath $script:snapshotRoot -Filter 'autopilot-shared.snapshot.json*').Count | Should -Be 0
    }

    It 'refuses an occupied bench link to a <Status> record while retaining saved content' -TestCases @(
        @{ Status = 'completed' }
        @{ Status = 'removed' }
    ) {
        param($Status)
        $snapshot = Get-SharedStoreSnapshot -Root $script:snapshotRoot -Lock $script:snapshotLock
        $snapshot.Devices = @(@{ RecordId = 'one'; Serial = 'BENCH-01'; ConfigItem = '123'; Status = 'in-progress' })
        $snapshot.Bench.Positions = @(@{ Index = 1; Serial = 'BENCH-01'; ConfigItem = '123' })
        Write-SharedStoreSnapshot -Root $script:snapshotRoot -Lock $script:snapshotLock -ExpectedRevision 0 -Snapshot $snapshot | Should -Be 1
        $path = Join-Path $script:snapshotRoot 'autopilot-shared.snapshot.json'
        $before = Get-Content -LiteralPath $path -Raw
        $proposal = Get-SharedStoreSnapshot -Root $script:snapshotRoot -Lock $script:snapshotLock
        $proposal.Devices[0].Status = $Status
        { Write-SharedStoreSnapshot -Root $script:snapshotRoot -Lock $script:snapshotLock -ExpectedRevision 1 -Snapshot $proposal } | Should -Throw '*bench identity*'
        (Get-Content -LiteralPath $path -Raw) | Should -BeExactly $before
        Test-Path -LiteralPath ('{0}.pending' -f $path) | Should -BeFalse
        Test-Path -LiteralPath ('{0}.write-in-progress' -f $path) | Should -BeFalse
    }

    It 'rejects invalid supplied device status <Value>' -TestCases @(
        @{ Value = 'unknown' }
        @{ Value = $true }
        @{ Value = $null }
    ) {
        param($Value)
        $snapshot = Get-SharedStoreSnapshot -Root $script:snapshotRoot -Lock $script:snapshotLock
        $snapshot.Devices = @(@{ RecordId = 'one'; Serial = 'STATUS-01'; Status = $Value })
        { Write-SharedStoreSnapshot -Root $script:snapshotRoot -Lock $script:snapshotLock -ExpectedRevision 0 -Snapshot $snapshot } | Should -Throw '*device status*'
    }

    It 'refuses empty snapshot content without substituting or replacing state' -TestCases @(
        @{ Content = '' }
        @{ Content = '   ' }
    ) {
        param($Content)
        $path = Join-Path $script:snapshotRoot 'autopilot-shared.snapshot.json'
        Set-Content -LiteralPath $path -Value $Content -NoNewline -Encoding UTF8
        { Get-SharedStoreSnapshot -Root $script:snapshotRoot -Lock $script:snapshotLock } | Should -Throw '*file is empty*'
        [string]$retained = Get-Content -LiteralPath $path -Raw
        $retained | Should -BeExactly $Content
        Test-Path -LiteralPath ('{0}.pending' -f $path) | Should -BeFalse
    }

    It 'allows audit dictionary key ordering changes without changing evidence' {
        $snapshot = Get-SharedStoreSnapshot -Root $script:snapshotRoot -Lock $script:snapshotLock
        $snapshot.Audit = @([ordered]@{ Action = 'First'; Data = [ordered]@{ Outcome = 'Verified'; Attempts = @(1, 2) } })
        Write-SharedStoreSnapshot -Root $script:snapshotRoot -Lock $script:snapshotLock -ExpectedRevision 0 -Snapshot $snapshot | Should -Be 1
        $proposal = Get-SharedStoreSnapshot -Root $script:snapshotRoot -Lock $script:snapshotLock
        $proposal.Audit = @([ordered]@{ Data = [ordered]@{ Attempts = @(1, 2); Outcome = 'Verified' }; Action = 'First' })
        Write-SharedStoreSnapshot -Root $script:snapshotRoot -Lock $script:snapshotLock -ExpectedRevision 1 -Snapshot $proposal | Should -Be 2
        $proposal.Revision | Should -Be 1
    }

    It 'refuses audit entry or nested array reordering <Kind>' -TestCases @(
        @{ Kind = 'entries' }
        @{ Kind = 'nested array' }
    ) {
        param($Kind)
        $snapshot = Get-SharedStoreSnapshot -Root $script:snapshotRoot -Lock $script:snapshotLock
        $snapshot.Audit = @(@{ Action = 'First'; Data = @(1, 2) }, @{ Action = 'Second' })
        Write-SharedStoreSnapshot -Root $script:snapshotRoot -Lock $script:snapshotLock -ExpectedRevision 0 -Snapshot $snapshot | Should -Be 1
        $proposal = Get-SharedStoreSnapshot -Root $script:snapshotRoot -Lock $script:snapshotLock
        if ($Kind -eq 'entries') { $proposal.Audit = @($proposal.Audit[1], $proposal.Audit[0]) }
        else { $proposal.Audit[0].Data = @(2, 1) }
        { Write-SharedStoreSnapshot -Root $script:snapshotRoot -Lock $script:snapshotLock -ExpectedRevision 1 -Snapshot $proposal } | Should -Throw '*rewritten or reordered*'
        (Get-SharedStoreSnapshot -Root $script:snapshotRoot -Lock $script:snapshotLock).Revision | Should -Be 1
    }

    It 'retains failure artefacts and blocks another read after interrupted promotion' {
        $snapshot = Get-SharedStoreSnapshot -Root $script:snapshotRoot -Lock $script:snapshotLock
        Mock Move-Item { throw 'Synthetic promotion failure' }
        { Write-SharedStoreSnapshot -Root $script:snapshotRoot -Lock $script:snapshotLock -ExpectedRevision 0 -Snapshot $snapshot } | Should -Throw '*promotion failure*'
        $path = Join-Path $script:snapshotRoot 'autopilot-shared.snapshot.json'
        Test-Path -LiteralPath ('{0}.pending' -f $path) | Should -BeTrue
        Test-Path -LiteralPath ('{0}.write-in-progress' -f $path) | Should -BeTrue
        { Get-SharedStoreSnapshot -Root $script:snapshotRoot -Lock $script:snapshotLock } | Should -Throw '*Interrupted save*'
    }

    It 'refuses saved attempt history <Change> without changing committed content' -TestCases @(
        @{ Change = 'truncation' }
        @{ Change = 'removal' }
        @{ Change = 'rewrite' }
    ) {
        param($Change)
        $snapshot = Get-SharedStoreSnapshot -Root $script:snapshotRoot -Lock $script:snapshotLock
        $attempt = @{ AttemptId = '11111111-1111-1111-1111-111111111111'; Sequence = 1; StepId = 'A'; ActionName = 'ResolveAutopilotDevice'; Timestamp = $null; Actor = 'Synthetic technician'; Mode = 'Demo'; TenantId = ''; Serial = 'HISTORY-01'; RecordId = 'one'; EvidenceKind = 'LegacyEvidence'; Result = @{ Completed = $true; Success = $true; CompletionState = 'Simulated'; IsSimulated = $true; Data = @{}; Summary = 'Original'; Notes = '' } }
        $snapshot.Devices = @(@{ RecordId = 'one'; Serial = 'HISTORY-01'; Status = 'new'; AttemptHistory = @($attempt) })
        Write-SharedStoreSnapshot -Root $script:snapshotRoot -Lock $script:snapshotLock -ExpectedRevision 0 -Snapshot $snapshot | Should -Be 1
        $path = Join-Path $script:snapshotRoot 'autopilot-shared.snapshot.json'
        $before = Get-Content -LiteralPath $path -Raw
        $proposal = Get-SharedStoreSnapshot -Root $script:snapshotRoot -Lock $script:snapshotLock
        switch ($Change) {
            'truncation' { $proposal.Devices[0].AttemptHistory = @() }
            'removal' { $proposal.Devices[0].Remove('AttemptHistory') }
            'rewrite' { $proposal.Devices[0].AttemptHistory[0].Result.Summary = 'Rewritten' }
        }
        { Write-SharedStoreSnapshot -Root $script:snapshotRoot -Lock $script:snapshotLock -ExpectedRevision 1 -Snapshot $proposal } | Should -Throw '*Persisted attempt history*'
        (Get-Content -LiteralPath $path -Raw) | Should -BeExactly $before
        Test-Path -LiteralPath ('{0}.write-in-progress' -f $path) | Should -BeFalse
    }

    It 'rejects malformed present attempt history rather than discarding it' {
        $snapshot = Get-SharedStoreSnapshot -Root $script:snapshotRoot -Lock $script:snapshotLock
        $snapshot.Devices = @(@{ RecordId = 'one'; Serial = 'HISTORY-01'; AttemptHistory = $null })
        { Write-SharedStoreSnapshot -Root $script:snapshotRoot -Lock $script:snapshotLock -ExpectedRevision 0 -Snapshot $snapshot } | Should -Throw '*must be an array*'
        @(Get-ChildItem -LiteralPath $script:snapshotRoot -Filter 'autopilot-shared.snapshot.json*').Count | Should -Be 0
    }

    It 'rejects another process while preserving the owning reservation' {
        $definition = $sourceAst.Find({ param($node) $node -is [System.Management.Automation.Language.FunctionDefinitionAst] -and $node.Name -eq 'Start-SharedStoreReservation' }, $true).Extent.Text
        $body = @(
            $definition
            ('$root = ''{0}''' -f $script:snapshotRoot.Replace("'", "''"))
            'try { $null = Start-SharedStoreReservation -Root $root; throw "UNEXPECTED_RESERVATION" } catch { if ($_.Exception.Message -eq "UNEXPECTED_RESERVATION") { throw }; Write-Output "SHARED_CONTENTION_PASS" }'
        ) -join [Environment]::NewLine
        $bootstrap = '$body = [Text.Encoding]::Unicode.GetString([Convert]::FromBase64String(''{0}'')); $ExecutionContext.SessionState.LanguageMode = ''ConstrainedLanguage''; Invoke-Expression $body' -f [Convert]::ToBase64String([Text.Encoding]::Unicode.GetBytes($body))
        $output = $bootstrap | & powershell.exe -NoProfile -NonInteractive -Command - 2>&1
        $LASTEXITCODE | Should -Be 0
        $output | Should -Contain 'SHARED_CONTENTION_PASS'
        (Get-Content -LiteralPath $script:snapshotLock.Path -Raw | ConvertFrom-Json).Token | Should -Be $script:snapshotLock.Token
    }

    It 'commits and reloads from a fresh constrained process in a separate development root' {
        $childRoot = Join-Path $TestDrive 'constrained-snapshot'
        New-Item -ItemType Directory -Path $childRoot | Out-Null
        $definitions = foreach ($functionName in @('Start-SharedStoreReservation', 'Assert-SharedStoreReservation', 'Assert-SharedStoreSnapshot', 'Get-SharedStoreSnapshot', 'Write-SharedStoreSnapshot', 'Stop-LocalSessionLock', 'Assert-DeviceRecordIdentity', 'Assert-BenchPositionIdentity', 'ConvertTo-NormalisedValue', 'Test-AttemptEvidenceEqual', 'Write-Utf8File', 'New-ParentDirectory', 'Get-StorageFileEncoding', 'Assert-FileWriteRecoveryState')) {
            $sourceAst.Find({ param($node) $node -is [System.Management.Automation.Language.FunctionDefinitionAst] -and $node.Name -eq $functionName }, $true).Extent.Text
        }
        $body = @(
            ($definitions -join [Environment]::NewLine)
            (($sourceAst.FindAll({ param($node) $node -is [System.Management.Automation.Language.FunctionDefinitionAst] -and $node.Name -in @('Assert-AttemptHistory', 'Assert-AttemptHistoryPreserved', 'ConvertTo-StepHashtable') }, $true) | ForEach-Object { $_.Extent.Text }) -join [Environment]::NewLine)
            ('$root = ''{0}''' -f $childRoot.Replace("'", "''"))
            '$ErrorActionPreference = "Stop"'
            '$lock = Start-SharedStoreReservation -Root $root; try { $state = Get-SharedStoreSnapshot -Root $root -Lock $lock; $state.Devices = @(@{ RecordId = "one"; Serial = "CL-ONE"; ConfigItem = "123"; Status = "new" }); $state.Bench.Positions = @(@{ Index = 1; Serial = "CL-ONE"; ConfigItem = "123" }); $state.Audit = @(@{ Action = "First" }); $revision = Write-SharedStoreSnapshot -Root $root -Lock $lock -ExpectedRevision 0 -Snapshot $state; $saved = Get-SharedStoreSnapshot -Root $root -Lock $lock; if ($revision -ne 1 -or $saved.Devices.Count -ne 1 -or $saved.Audit[0].Action -ne "First") { throw "SNAPSHOT_MISMATCH" } } finally { Stop-LocalSessionLock -Lock $lock }; Write-Output "SHARED_CONSTRAINED_PASS"'
        ) -join [Environment]::NewLine
        $bootstrap = '$body = [Text.Encoding]::Unicode.GetString([Convert]::FromBase64String(''{0}'')); $ExecutionContext.SessionState.LanguageMode = ''ConstrainedLanguage''; Invoke-Expression $body' -f [Convert]::ToBase64String([Text.Encoding]::Unicode.GetBytes($body))
        $output = $bootstrap | & powershell.exe -NoProfile -NonInteractive -Command - 2>&1
        $LASTEXITCODE | Should -Be 0
        $output | Should -Contain 'SHARED_CONSTRAINED_PASS'
        Test-Path -LiteralPath (Join-Path $childRoot 'autopilot-shared.snapshot.lock') | Should -BeFalse
    }
}