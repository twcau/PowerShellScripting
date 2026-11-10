<#
.SYNOPSIS
    Tests local checkpoint detection and verified proposals in real TestDrive files.
.DESCRIPTION
    Extracts persistence helpers without CLI, authentication or tenant actions.
    Fault injection proves fail-closed boundaries, not atomic replacement or fsync.
#>
BeforeAll {
    $sourceFolder = Split-Path -Parent $PSScriptRoot
    $sourcePath = Join-Path $sourceFolder 'autopilot-express.ps1'
    $tokens = $null
    $parseErrors = $null
    $sourceAst = [System.Management.Automation.Language.Parser]::ParseFile($sourcePath, [ref]$tokens, [ref]$parseErrors)
    if ($parseErrors.Count) { throw ($parseErrors.Message -join '; ') }
    foreach ($functionName in @('Assert-AttemptHistory', 'Test-AttemptEvidenceEqual', 'Assert-AttemptHistoryPreserved', 'Get-UserDeviceRecords', 'Assert-DeviceRecordIdentity', 'ConvertTo-StepHashtable', 'New-ParentDirectory', 'Get-StorageFileEncoding', 'Write-Utf8File', 'Assert-FileWriteRecoveryState', 'Assert-LocalStorageWriteState', 'Get-LocalCheckpointPath', 'Assert-LocalCheckpointState', 'Get-LocalCheckpointInspection', 'New-EmptyDeviceRecord', 'Get-DefaultBuildBenchState', 'ConvertTo-NormalisedValue', 'ConvertTo-RecordDate', 'ConvertTo-PersistedDate', 'ConvertTo-PersistedDeviceRecord', 'Get-MasterAuditProposal', 'Get-VerifiedSaveCopy', 'Update-MasterAuditLedger', 'Write-UserDeviceRecords', 'Save-BuildBenchState')) {
        $definition = $sourceAst.Find({ param($node) $node -is [System.Management.Automation.Language.FunctionDefinitionAst] -and $node.Name -eq $functionName }, $true)
        if (-not $definition) { throw ('Missing function: {0}' -f $functionName) }
        Set-Item -Path ('Function:{0}' -f $definition.Name) -Value $definition.Body.GetScriptBlock()
    }
    function Get-DataFolderPath { return $script:stateRoot }
    function Get-UserDataFilePath { return Join-Path $script:stateRoot ('devices-{0}.json' -f $script:Runtime.IsDemoMode) }
    function Get-BuildBenchStatePath { return Join-Path $script:stateRoot ('bench-{0}.json' -f $script:Runtime.IsDemoMode) }
    function Get-MasterAuditFilePath { return Join-Path $script:stateRoot 'audit.json' }
    function Get-RecentUsersFilePath { return Join-Path $script:stateRoot 'recent.json' }
    function Write-AutopilotExpressLog { param($Message, $Level) throw ('Unexpected log: {0}, {1}' -f $Level, $Message) }
}

Describe 'Verified local checkpoint boundaries' {
    BeforeEach {
        $script:stateRoot = Join-Path $TestDrive ([guid]::NewGuid().Guid)
        New-Item -ItemType Directory -Path $script:stateRoot | Out-Null
        $script:Runtime = @{ IsDemoMode = $false }
        $script:LocalCheckpointToken = $null
        $script:LocalSaveCache = @{}
        $script:record = New-EmptyDeviceRecord
        $script:record.RecordId = 'checkpoint-device'
        $script:record.Serial = 'CHECKPOINT-01'
        $script:record.ConfigItem = 'CI-01'
        $script:record.StartedAt = Get-Date
        $script:record.Steps = @{ A = @{ Data = @{ Details = @('one', 'two') }; CompletionState = 'Verified' } }
        $script:BuildBench = Get-DefaultBuildBenchState
        $script:BuildBench.Active = $true
        $script:BuildBench.Positions = @(@{ Index = 1; Serial = 'CHECKPOINT-01'; ConfigItem = 'CI-01' })
        $script:checkpointPath = Get-LocalCheckpointPath
        $script:recordsPath = Get-UserDataFilePath
        $script:auditPath = Get-MasterAuditFilePath
        $script:benchPath = Get-BuildBenchStatePath
        Mock Write-AutopilotExpressLog {}
        Write-Utf8File -Path $script:recordsPath -Content '[]'
        Write-Utf8File -Path $script:auditPath -Content '[{"RecordId":"retained","Serial":"OLD"}]'
        Write-Utf8File -Path $script:benchPath -Content '{"Active":false,"Positions":[]}'
        $script:beforeRecords = Get-Content -LiteralPath $script:recordsPath -Raw
        $script:beforeAudit = Get-Content -LiteralPath $script:auditPath -Raw
        $script:beforeBench = Get-Content -LiteralPath $script:benchPath -Raw
        $script:callerBefore = @($script:record, $script:BuildBench) | ConvertTo-Json -Depth 100
    }

    It 'saves the complete proposal in order and clears only the successful checkpoint' {
        Mock Write-AutopilotExpressLog {
            $inspection = Get-LocalCheckpointInspection
            $inspection.Proposal.Root | Should -BeExactly $script:stateRoot
            $inspection.Proposal.User | Should -BeExactly $env:USERNAME
            $inspection.Proposal.Mode | Should -BeExactly 'live'
            Get-Content -LiteralPath $script:recordsPath -Raw | Should -BeExactly $inspection.Proposal.RecordsJson
            Get-Content -LiteralPath $script:auditPath -Raw | Should -BeExactly $script:beforeAudit
            Get-Content -LiteralPath $script:benchPath -Raw | Should -BeExactly $script:beforeBench
            $script:observedProposal = $inspection.Proposal
        } -ParameterFilter { $Message -like 'Saved *' }
        Write-UserDeviceRecords -Records @($script:record)
        Get-Content -LiteralPath $script:auditPath -Raw | Should -BeExactly $script:observedProposal.AuditJson
        Get-Content -LiteralPath $script:benchPath -Raw | Should -BeExactly $script:observedProposal.BenchJson
        (Get-Content -LiteralPath $script:recordsPath -Raw | ConvertFrom-Json).Serial | Should -BeExactly 'CHECKPOINT-01'
        $audit = Get-Content -LiteralPath $script:auditPath -Raw | ConvertFrom-Json
        @($audit).Count | Should -Be 2
        @($audit.RecordId) | Should -Contain 'retained'
        (Get-Content -LiteralPath $script:benchPath -Raw | ConvertFrom-Json).Positions[0].Serial | Should -BeExactly 'CHECKPOINT-01'
        Test-Path -LiteralPath $script:checkpointPath | Should -BeFalse
        $script:LocalCheckpointToken | Should -BeNullOrEmpty
        (@($script:record, $script:BuildBench) | ConvertTo-Json -Depth 100) | Should -BeExactly $script:callerBefore
    }

    It 'retains checkpoint writer evidence when marker staging fails before operational writes' {
        Mock Set-Content { throw 'Synthetic checkpoint staging fault' } -ParameterFilter { $LiteralPath -eq ('{0}.pending' -f $script:checkpointPath) }
        { Write-UserDeviceRecords -Records @($script:record) } | Should -Throw '*checkpoint staging fault*'
        Test-Path -LiteralPath $script:checkpointPath | Should -BeFalse
        Test-Path -LiteralPath ('{0}.write-in-progress' -f $script:checkpointPath) | Should -BeTrue
        Get-Content -LiteralPath $script:recordsPath -Raw | Should -BeExactly $script:beforeRecords
        Get-Content -LiteralPath $script:auditPath -Raw | Should -BeExactly $script:beforeAudit
        Get-Content -LiteralPath $script:benchPath -Raw | Should -BeExactly $script:beforeBench
        { Assert-LocalStorageWriteState } | Should -Throw '*recovery is required*'
    }

    It 'verifies <Boundary> checkpoint content before the first operational write' -TestCases @(
        @{ Boundary = 'staged'; Suffix = '.pending'; Expected = '*Staged save verification*' }
        @{ Boundary = 'promoted'; Suffix = ''; Expected = '*Promoted save verification*' }
    ) {
        param($Boundary, $Suffix, $Expected)
        $script:badReadPath = '{0}{1}' -f $script:checkpointPath, $Suffix
        Mock Get-Content { return 'different' } -ParameterFilter { $LiteralPath -eq $script:badReadPath }
        { Write-UserDeviceRecords -Records @($script:record) } | Should -Throw $Expected
        Get-Content -LiteralPath $script:recordsPath -Raw | Should -BeExactly $script:beforeRecords
        Test-Path -LiteralPath ('{0}.write-in-progress' -f $script:checkpointPath) | Should -BeTrue
        $Boundary | Should -Not -BeNullOrEmpty
    }

    It 'retains the complete proposal on <Target> save failure without changing caller state' -TestCases @(
        @{ Target = 'records' }
        @{ Target = 'audit' }
        @{ Target = 'bench' }
    ) {
        param($Target)
        $script:failedPath = switch ($Target) { 'records' { $script:recordsPath }; 'audit' { $script:auditPath }; 'bench' { $script:benchPath } }
        Mock Set-Content { throw 'Synthetic operational save fault' } -ParameterFilter { $LiteralPath -eq ('{0}.pending' -f $script:failedPath) }
        { Write-UserDeviceRecords -Records @($script:record) } | Should -Throw '*operational save fault*'
        $inspection = Get-LocalCheckpointInspection
        Get-Content -LiteralPath $script:checkpointPath -Raw | Should -Not -BeNullOrEmpty
        $proposedAudit = $inspection.Proposal.AuditJson | ConvertFrom-Json
        @($proposedAudit).Count | Should -Be 2
        ($inspection.Proposal.RecordsJson | ConvertFrom-Json).Steps.A.Data.Details[1] | Should -BeExactly 'two'
        ($inspection.Proposal.BenchJson | ConvertFrom-Json).Positions[0].Serial | Should -BeExactly 'CHECKPOINT-01'
        $script:LocalCheckpointToken | Should -BeNullOrEmpty
        { Save-BuildBenchState } | Should -Throw '*Unresolved local checkpoint*'
        { Save-BuildBenchState -CheckpointToken $inspection.Proposal.Token -ProposedContent $inspection.Proposal.BenchJson } | Should -Throw
        { Write-UserDeviceRecords -Records @($script:record) } | Should -Throw '*Unresolved local checkpoint*'
        { Assert-LocalStorageWriteState } | Should -Throw '*Unresolved local checkpoint*'
        (@($script:record, $script:BuildBench) | ConvertTo-Json -Depth 100) | Should -BeExactly $script:callerBefore
        if ($Target -eq 'records') { Get-Content -LiteralPath $script:auditPath -Raw | Should -BeExactly $script:beforeAudit }
        if ($Target -ne 'bench') { Get-Content -LiteralPath $script:benchPath -Raw | Should -BeExactly $script:beforeBench }
    }

    It 'fails closed if checkpoint deletion fails even after all three verified saves' {
        Mock Remove-Item { throw 'Synthetic checkpoint cleanup fault' } -ParameterFilter { $LiteralPath -eq $script:checkpointPath }
        { Write-UserDeviceRecords -Records @($script:record) } | Should -Throw '*checkpoint cleanup fault*'
        $inspection = Get-LocalCheckpointInspection
        Get-Content -LiteralPath $script:recordsPath -Raw | Should -BeExactly $inspection.Proposal.RecordsJson
        Get-Content -LiteralPath $script:auditPath -Raw | Should -BeExactly $inspection.Proposal.AuditJson
        Get-Content -LiteralPath $script:benchPath -Raw | Should -BeExactly $inspection.Proposal.BenchJson
        { Assert-LocalStorageWriteState } | Should -Throw '*Unresolved local checkpoint*'
    }

    It 'retains checkpoint evidence if checkpoint promotion fails' {
        Mock Move-Item { throw 'Synthetic checkpoint promotion fault' } -ParameterFilter { $LiteralPath -eq ('{0}.pending' -f $script:checkpointPath) }
        { Write-UserDeviceRecords -Records @($script:record) } | Should -Throw '*checkpoint promotion fault*'
        Test-Path -LiteralPath $script:checkpointPath | Should -BeFalse
        Test-Path -LiteralPath ('{0}.pending' -f $script:checkpointPath) | Should -BeTrue
        Get-Content -LiteralPath $script:recordsPath -Raw | Should -BeExactly $script:beforeRecords
        { Assert-LocalStorageWriteState } | Should -Throw '*recovery is required*'
    }

    It 'retains checkpoint evidence if its single-file writer cleanup fails' {
        Mock Remove-Item { throw 'Synthetic checkpoint writer cleanup fault' } -ParameterFilter { $LiteralPath -eq ('{0}.write-in-progress' -f $script:checkpointPath) }
        { Write-UserDeviceRecords -Records @($script:record) } | Should -Throw '*checkpoint writer cleanup fault*'
        Test-Path -LiteralPath $script:checkpointPath | Should -BeTrue
        Test-Path -LiteralPath ('{0}.write-in-progress' -f $script:checkpointPath) | Should -BeTrue
        Get-Content -LiteralPath $script:recordsPath -Raw | Should -BeExactly $script:beforeRecords
        { Assert-LocalStorageWriteState } | Should -Throw '*recovery is required*'
    }

    It 'refuses an internal bench save if checkpoint <Field> changed' -TestCases @(
        @{ Field = 'Token'; ChangedValue = 'changed-owner' }
        @{ Field = 'BenchJson'; ChangedValue = '{"Active":false,"Positions":[]}' }
    ) {
        param($Field, $ChangedValue)
        $script:changedField = $Field
        $script:changedValue = $ChangedValue
        Mock Write-AutopilotExpressLog {
            $marker = Get-Content -LiteralPath $script:checkpointPath -Raw | ConvertFrom-Json
            $marker.($script:changedField) = $script:changedValue
            Set-Content -LiteralPath $script:checkpointPath -Value ($marker | ConvertTo-Json -Depth 8) -NoNewline
        } -ParameterFilter { $Message -like 'Saved *' }
        { Write-UserDeviceRecords -Records @($script:record) } | Should -Throw '*ownership or bench proposal changed*'
        Get-Content -LiteralPath $script:benchPath -Raw | Should -BeExactly $script:beforeBench
        Test-Path -LiteralPath $script:checkpointPath | Should -BeTrue
        $script:LocalCheckpointToken | Should -BeNullOrEmpty
    }

    It 'rejects staged content or an old token outside the owning checkpoint scope' {
        { Save-BuildBenchState -CheckpointToken 'old-token' -ProposedContent '{}' } | Should -Throw '*active local checkpoint token*'
        { Save-BuildBenchState -ProposedContent '{}' } | Should -Throw '*active local checkpoint token*'
        Get-Content -LiteralPath $script:benchPath -Raw | Should -BeExactly $script:beforeBench
    }

    It 'permits standalone bench saves only when no checkpoint is unresolved' {
        Save-BuildBenchState
        (Get-Content -LiteralPath $script:benchPath -Raw | ConvertFrom-Json).Active | Should -BeTrue
        Test-Path -LiteralPath $script:checkpointPath | Should -BeFalse
    }

    It 'saves records and audit without inventing an uninitialised bench' {
        $script:BuildBench = $null
        Write-UserDeviceRecords -Records @($script:record)
        Get-Content -LiteralPath $script:benchPath -Raw | Should -BeExactly $script:beforeBench
        Test-Path -LiteralPath $script:checkpointPath | Should -BeFalse
    }

    It 'never writes Live audit in Demo and preserves mode isolation' {
        New-Item -ItemType File -Path $script:checkpointPath -Value 'Live crash evidence' | Out-Null
        $script:Runtime.IsDemoMode = $true
        Write-UserDeviceRecords -Records @($script:record)
        Get-Content -LiteralPath $script:auditPath -Raw | Should -BeExactly $script:beforeAudit
        Get-Content -LiteralPath $script:checkpointPath -Raw | Should -BeExactly 'Live crash evidence'
        { Assert-LocalStorageWriteState } | Should -Not -Throw
        $script:Runtime.IsDemoMode = $false
        { Assert-LocalStorageWriteState } | Should -Throw '*Unresolved local checkpoint*'
    }

    It 'rejects crash evidence <Suffix> with no operational targets present' -TestCases @(
        @{ Suffix = '' }
        @{ Suffix = '.pending' }
        @{ Suffix = '.write-in-progress' }
        @{ Suffix = '.previous' }
    ) {
        param($Suffix)
        Remove-Item -LiteralPath $script:recordsPath, $script:auditPath, $script:benchPath
        New-Item -ItemType File -Path ('{0}{1}' -f $script:checkpointPath, $Suffix) -Value 'crash evidence' | Out-Null
        { Assert-LocalStorageWriteState } | Should -Throw
        { Save-BuildBenchState } | Should -Throw
        { Write-UserDeviceRecords -Records @($script:record) } | Should -Throw
        Get-Content -LiteralPath ('{0}{1}' -f $script:checkpointPath, $Suffix) -Raw | Should -BeExactly 'crash evidence'
        Test-Path -LiteralPath $script:recordsPath | Should -BeFalse
    }

    It 'inspects valid proposals without promotion, deletion or caller mutation' {
        Mock Set-Content { throw 'Synthetic records fault' } -ParameterFilter { $LiteralPath -eq ('{0}.pending' -f $script:recordsPath) }
        { Write-UserDeviceRecords -Records @($script:record) } | Should -Throw
        $before = Get-Content -LiteralPath $script:checkpointPath -Raw
        $inspection = Get-LocalCheckpointInspection
        @($inspection.Evidence | Where-Object { $_.Path -eq $script:checkpointPath -and $_.Exists }).Count | Should -Be 1
        Get-Content -LiteralPath $script:checkpointPath -Raw | Should -BeExactly $before
        Get-Content -LiteralPath $script:recordsPath -Raw | Should -BeExactly $script:beforeRecords
        (@($script:record, $script:BuildBench) | ConvertTo-Json -Depth 100) | Should -BeExactly $script:callerBefore
    }

    It 'does not delete or repair a damaged marker' {
        New-Item -ItemType File -Path $script:checkpointPath -Value '{damaged' | Out-Null
        { Get-LocalCheckpointInspection } | Should -Throw
        Get-Content -LiteralPath $script:checkpointPath -Raw | Should -BeExactly '{damaged'
        { Assert-LocalStorageWriteState } | Should -Throw '*Unresolved local checkpoint*'
    }

    It 'rejects mismatched scope during read-only inspection' {
        Mock Set-Content { throw 'Synthetic records fault' } -ParameterFilter { $LiteralPath -eq ('{0}.pending' -f $script:recordsPath) }
        { Write-UserDeviceRecords -Records @($script:record) } | Should -Throw
        $marker = Get-Content -LiteralPath $script:checkpointPath -Raw | ConvertFrom-Json
        $marker.Root = 'another root'
        $damaged = $marker | ConvertTo-Json -Depth 8
        Set-Content -LiteralPath $script:checkpointPath -Value $damaged -NoNewline
        { Get-LocalCheckpointInspection } | Should -Throw '*Invalid local checkpoint*'
        Get-Content -LiteralPath $script:checkpointPath -Raw | Should -BeExactly $damaged
    }

    It 'uses only the active root and current user checkpoint path' {
        $otherRoot = Join-Path $TestDrive 'other-root'
        New-Item -ItemType Directory -Path $otherRoot | Out-Null
        $otherPath = Join-Path $otherRoot (Split-Path -Leaf $script:checkpointPath)
        New-Item -ItemType File -Path $otherPath -Value 'other root evidence' | Out-Null
        $otherUserPath = Join-Path $script:stateRoot 'autopilot-express-live-another-user.checkpoint.json'
        New-Item -ItemType File -Path $otherUserPath -Value 'other user evidence' | Out-Null
        { Assert-LocalStorageWriteState } | Should -Not -Throw
        Write-UserDeviceRecords -Records @($script:record)
        Get-Content -LiteralPath $otherPath -Raw | Should -BeExactly 'other root evidence'
        Get-Content -LiteralPath $otherUserPath -Raw | Should -BeExactly 'other user evidence'
    }

    It 'reuses the verified private copy for the next save while the records file is unchanged' {
        Write-UserDeviceRecords -Records @($script:record)
        Mock Get-UserDeviceRecords { throw 'Unexpected full re-read' }
        { Write-UserDeviceRecords -Records @($script:record) } | Should -Not -Throw
        Should -Invoke Get-UserDeviceRecords -Times 0 -Exactly
        $audit = Get-Content -LiteralPath $script:auditPath -Raw | ConvertFrom-Json
        @($audit).Count | Should -Be 2
    }

    It 'falls back to a full re-read when the records file changed outside this session' {
        Write-UserDeviceRecords -Records @($script:record)
        Write-Utf8File -Path $script:recordsPath -Content ('{0}{1}' -f (Get-Content -LiteralPath $script:recordsPath -Raw), [Environment]::NewLine)
        Mock Get-UserDeviceRecords { return , @() }
        Write-UserDeviceRecords -Records @($script:record)
        Should -Invoke Get-UserDeviceRecords -Times 1 -Exactly
    }

    It 'keeps an audit entry added outside this session' {
        Write-UserDeviceRecords -Records @($script:record)
        # Assign before wrapping: Windows PowerShell 5.1 emits a parsed JSON array as one object.
        $existing = Get-Content -LiteralPath $script:auditPath -Raw | ConvertFrom-Json
        $audit = @($existing) + [pscustomobject]@{ RecordId = 'external'; Serial = 'EXTERNAL-01' }
        Write-Utf8File -Path $script:auditPath -Content (ConvertTo-Json -InputObject $audit -Depth 100)
        Write-UserDeviceRecords -Records @($script:record)
        $saved = Get-Content -LiteralPath $script:auditPath -Raw | ConvertFrom-Json
        @($saved.RecordId) | Should -Contain 'external'
        @($saved.RecordId) | Should -Contain 'retained'
    }

    It 'clears the private copies after a failed save' {
        Write-UserDeviceRecords -Records @($script:record)
        $script:LocalSaveCache.Count | Should -Be 2
        Mock Set-Content { throw 'Synthetic records fault' } -ParameterFilter { $LiteralPath -eq ('{0}.pending' -f $script:recordsPath) }
        { Write-UserDeviceRecords -Records @($script:record) } | Should -Throw
        $script:LocalSaveCache.Count | Should -Be 0
    }

    It 'returns the same audit text with or without the entries' {
        $persisted = @(ConvertTo-PersistedDeviceRecord -Record $script:record)
        $plain = Get-MasterAuditProposal -Records $persisted
        $withEntries = Get-MasterAuditProposal -Records $persisted -IncludeEntries
        $withEntries.Json | Should -BeExactly $plain
        @($withEntries.Entries).Count | Should -Be 2
    }
}

Describe 'Actual checkpoint startup guard' {
    It 'rejects a checkpoint before resume prompts and releases its active-root reservation' {
        $rehearsalFolder = Join-Path $TestDrive 'checkpoint-startup'
        $dataFolder = Join-Path $rehearsalFolder 'data'
        New-Item -ItemType Directory -Path $dataFolder -Force | Out-Null
        foreach ($fileName in @('autopilot-express.ps1', 'autopilot-express.manifest.json', 'autopilot-express.runtime.json')) {
            Copy-Item -LiteralPath (Join-Path $sourceFolder $fileName) -Destination $rehearsalFolder
        }
        $markerPath = Join-Path $dataFolder ('autopilot-express-demo-{0}.checkpoint.json' -f $env:USERNAME)
        New-Item -ItemType File -Path $markerPath -Value 'crash evidence' | Out-Null
        $previousRoot = $env:PowerShellScriptingNewRoot
        $previousDefinitions = $env:AutopilotExpressDefinitionDirectory
        $previousLocalAppData = $env:LOCALAPPDATA
        Mock Read-Host { throw 'Unexpected resume prompt' }
        Mock Write-Host {}
        try {
            $env:AutopilotExpressDefinitionDirectory = $rehearsalFolder
            $env:LOCALAPPDATA = Join-Path $TestDrive 'isolated-local-app-data'
            { & (Join-Path $rehearsalFolder 'autopilot-express.ps1') -Mode Demo } | Should -Throw '*Unresolved local checkpoint*'
            Should -Invoke Read-Host -Times 0 -Exactly
            Get-Content -LiteralPath $markerPath -Raw | Should -BeExactly 'crash evidence'
            Test-Path -LiteralPath (Join-Path $dataFolder 'autopilot-express-demo.session.lock') | Should -BeFalse
            Test-Path -LiteralPath (Join-Path $dataFolder ('autopilot-devices-demo-{0}.json' -f $env:USERNAME)) | Should -BeFalse
        }
        finally {
            $env:PowerShellScriptingNewRoot = $previousRoot
            $env:AutopilotExpressDefinitionDirectory = $previousDefinitions
            $env:LOCALAPPDATA = $previousLocalAppData
        }
    }
}