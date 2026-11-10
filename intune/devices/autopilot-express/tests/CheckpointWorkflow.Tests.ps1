<#
.SYNOPSIS
    Rehearses TODO35 checkpoint fault recovery through the actual Demo CLI.
.DESCRIPTION
    Requires Pester 5 on Windows PowerShell 5.1 or PowerShell 7. Copies the full
    entry point and definitions into TestDrive and isolates LOCALAPPDATA. Only
    host interaction and narrowly selected filesystem cmdlets are mocked; the
    checkpoint guards, verified writer and CLI execute unchanged. Inspection
    alone uses native-parser-extracted functions with read-only path adapters.
    No authentication, tenant calls or operational storage outside TestDrive.
.FILECREATED
    2026-10-08
.FILELASTUPDATED
    2026-10-08
#>
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidGlobalVars', '', Justification = 'A uniquely named, restored test fixture crosses the actual entry point script scope, following WorkflowRehearsal.Tests.ps1.')]
param()

BeforeAll {
    $sourceFolder = Split-Path -Parent $PSScriptRoot
    $sourcePath = Join-Path $sourceFolder 'autopilot-express.ps1'
    $tokens = $null
    $parseErrors = $null
    $sourceAst = [System.Management.Automation.Language.Parser]::ParseFile($sourcePath, [ref]$tokens, [ref]$parseErrors)
    if ($parseErrors.Count) { throw ($parseErrors.Message -join '; ') }
    foreach ($functionName in @('Get-LocalCheckpointPath', 'Get-LocalCheckpointInspection')) {
        $definition = $sourceAst.Find({ param($node) $node -is [System.Management.Automation.Language.FunctionDefinitionAst] -and $node.Name -eq $functionName }, $true)
        if ($null -eq $definition) { throw ('Missing source function: {0}' -f $functionName) }
        . ([scriptblock]::Create($definition.Extent.Text))
    }

    function Get-DataFolderPath { return $global:AutopilotExpressCheckpointWorkflow.Data }
    function Get-UserDataFilePath { return $global:AutopilotExpressCheckpointWorkflow.Records }
    function Get-BuildBenchStatePath { return $global:AutopilotExpressCheckpointWorkflow.Bench }
    function Get-MasterAuditFilePath { throw 'Demo inspection must not request Live audit storage.' }
    function Connect-MgGraph { throw 'Unexpected authentication.' }
    function Invoke-MgGraphRequest { throw 'Unexpected tenant request.' }

    function Test-CheckpointWorkflowGuardedPath {
        <#
        .SYNOPSIS Decide whether a restart filesystem call targets guarded operational storage.
        .DESCRIPTION
            Every invocation must start its own diagnostic transcript (Start-AutopilotDiagnostics) before
            any storage check, so the isolated LOCALAPPDATA log folder is expected evidence, not a write
            the checkpoint refusal must prevent. Everything else under the fixture root stays guarded.
        .PARAMETER Path
            One or more candidate paths from the mocked cmdlet; null or empty never matches.
        .OUTPUTS
            True when any candidate is inside the fixture root but outside the diagnostic log folder.
        #>
        param([AllowNull()][object[]]$Path)
        $fixture = $global:AutopilotExpressCheckpointWorkflow
        foreach ($candidate in @($Path | Where-Object { -not [string]::IsNullOrWhiteSpace([string]$_) })) {
            $text = [string]$candidate
            if ($text -like ('{0}*' -f $fixture.Root) -and $text -notlike ('{0}*' -f $fixture.Logs)) { return $true }
        }
        return $false
    }

    function Get-CheckpointWorkflowSnapshot {
        <# .SYNOPSIS Return byte hashes for every isolated file, including fallback evidence. #>
        # Diagnostic transcripts are written by every invocation by design, so they are excluded.
        return (@(Get-ChildItem -LiteralPath $global:AutopilotExpressCheckpointWorkflow.Root -Recurse -File |
                Where-Object { $_.FullName -notlike ('{0}*' -f $global:AutopilotExpressCheckpointWorkflow.Logs) } |
                Sort-Object FullName | ForEach-Object {
                    @{ Path = $_.FullName; Hash = (Get-FileHash -LiteralPath $_.FullName -Algorithm SHA256).Hash }
                }) | ConvertTo-Json -Depth 4 -Compress)
    }

    function Assert-CheckpointWorkflowRestart {
        <# .SYNOPSIS Restart the full CLI and prove pre-prompt, pre-write refusal with byte preservation. #>
        $fixture = $global:AutopilotExpressCheckpointWorkflow
        $before = Get-CheckpointWorkflowSnapshot
        $promptCount = $fixture.Prompts.Count
        $fixture.Armed = $false
        $fixture.Restart = $true
        { & $fixture.EntryPoint -Mode Demo } | Should -Throw '*Unresolved local checkpoint*'
        $fixture.Prompts.Count | Should -Be $promptCount
        $fixture.RestartWrites | Should -Be 0
        Should -Invoke Read-Host -Times $promptCount -Exactly
        (Get-CheckpointWorkflowSnapshot) | Should -BeExactly $before
        Test-Path -LiteralPath $fixture.Lock | Should -BeFalse
        Test-Path -LiteralPath $fixture.Checkpoint | Should -BeTrue
    }

    function Assert-CheckpointWorkflowProposal {
        <# .SYNOPSIS Validate the real verified proposal and its read-only evidence inventory. #>
        $fixture = $global:AutopilotExpressCheckpointWorkflow
        $before = Get-CheckpointWorkflowSnapshot
        $metadata = Get-Content -LiteralPath $fixture.Checkpoint -Raw | ConvertFrom-Json
        $metadata.Root | Should -BeExactly $fixture.Data
        $metadata.Mode | Should -BeExactly 'demo'
        $metadata.User | Should -BeExactly $env:USERNAME
        $metadata.RecordsJson -is [string] | Should -BeTrue
        $metadata.BenchJson -is [string] | Should -BeTrue
        $metadata.AuditJson | Should -BeNullOrEmpty
        try { $inspection = Get-LocalCheckpointInspection }
        catch {
            throw ('Inspection failed: {0}; harnessDemo={1}; resolvedRoot={2}; metadataRoot={3}; auditNull={4}; schema={5}; token={6}' -f
                $_.Exception.Message, $script:Runtime.IsDemoMode, (Get-DataFolderPath), $metadata.Root, ($null -eq $metadata.AuditJson), $metadata.SchemaVersion, $metadata.Token)
        }
        $proposal = $inspection.Proposal
        $proposal.SchemaVersion | Should -Be 1
        $proposal.Root | Should -BeExactly $fixture.Data
        $proposal.User | Should -BeExactly $env:USERNAME
        $proposal.Mode | Should -BeExactly 'demo'
        { [guid]::Parse($proposal.Token) } | Should -Not -Throw
        $proposal.AuditJson | Should -BeNullOrEmpty
        $decodedRecords = $proposal.RecordsJson | ConvertFrom-Json
        $records = @($decodedRecords)
        $records.Count | Should -Be 2
        @($records.Serial) | Should -Contain 'CHECKPOINT-OLD'
        @($records.Serial) | Should -Contain 'CHECKPOINT-NEW'
        ($records | Where-Object Serial -eq 'CHECKPOINT-NEW').ConfigItem | Should -BeExactly 'CI-NEW'
        $bench = $proposal.BenchJson | ConvertFrom-Json
        $bench.Active | Should -BeTrue
        $bench.Positions[0].Serial | Should -BeExactly 'CHECKPOINT-OLD'
        $bench.Positions[1].Serial | Should -BeExactly 'CHECKPOINT-NEW'
        @($inspection.Evidence).Count | Should -Be 12
        foreach ($entry in $inspection.Evidence) {
            $entry.Exists | Should -Be (Test-Path -LiteralPath $entry.Path)
        }
        @($inspection.Evidence | Where-Object { $_.Path -eq $fixture.Checkpoint -and $_.Exists }).Count | Should -Be 1
        Test-Path -LiteralPath ('{0}.pending' -f $fixture.Checkpoint) | Should -BeFalse
        Test-Path -LiteralPath ('{0}.write-in-progress' -f $fixture.Checkpoint) | Should -BeFalse
        (Get-CheckpointWorkflowSnapshot) | Should -BeExactly $before
        Test-Path -LiteralPath $fixture.Lock | Should -BeFalse
        return $proposal
    }

    function ConvertTo-CheckpointWorkflowCanonical {
        <# .SYNOPSIS Serialise decoded JSON with sorted keys so member order cannot cause false differences. #>
        param([AllowNull()]$Value)
        if ($Value -is [System.Management.Automation.PSCustomObject]) {
            $ordered = [ordered]@{}
            foreach ($name in @($Value.PSObject.Properties.Name | Sort-Object)) { $ordered[$name] = ConvertTo-CheckpointWorkflowCanonical -Value $Value.$name }
            return $ordered
        }
        if ($Value -is [array]) { return , @($Value | ForEach-Object { ConvertTo-CheckpointWorkflowCanonical -Value $_ }) }
        return $Value
    }

    function Assert-CheckpointWorkflowResumedRecords {
        <#
        .SYNOPSIS Prove a resume preserved every record field apart from the intended session-load stamp.
        .DESCRIPTION
            Register-ImagingSessionStart appends one timestamp per session load to each unfinished
            device; that is required duration evidence, so it is the only difference permitted.
        .PARAMETER BeforeJson
            Device records captured before the restart.
        .PARAMETER AfterJson
            Device records read after the restart.
        #>
        param([Parameter(Mandatory)][string]$BeforeJson, [Parameter(Mandatory)][string]$AfterJson)
        $before = @($BeforeJson | ConvertFrom-Json | ForEach-Object { $_ })
        $after = @($AfterJson | ConvertFrom-Json | ForEach-Object { $_ })
        $after.Count | Should -Be $before.Count
        foreach ($old in $before) {
            $new = @($after | Where-Object RecordId -eq $old.RecordId)
            $new.Count | Should -Be 1
            $oldStarts = @($old.ImagingSessionStarts)
            $newStarts = @($new[0].ImagingSessionStarts)
            if ($old.Status -in @('completed', 'removed')) { $newStarts.Count | Should -Be $oldStarts.Count }
            else { $newStarts.Count | Should -Be ($oldStarts.Count + 1) }
            for ($i = 0; $i -lt $oldStarts.Count; $i++) { $newStarts[$i] | Should -BeExactly $oldStarts[$i] }
            foreach ($record in @($old, $new[0])) { $record.PSObject.Properties.Remove('ImagingSessionStarts') }
            (ConvertTo-CheckpointWorkflowCanonical -Value $new[0] | ConvertTo-Json -Depth 20 -Compress) |
                Should -BeExactly (ConvertTo-CheckpointWorkflowCanonical -Value $old | ConvertTo-Json -Depth 20 -Compress)
        }
    }

    function Assert-CheckpointWorkflowHistory {
        <# .SYNOPSIS Compare the seeded outcome fields independently of JSON member order. #>
        param([Parameter(Mandatory)][string]$RecordsJson)
        $decodedRecords = $RecordsJson | ConvertFrom-Json
        $record = @($decodedRecords) | Where-Object Serial -eq 'CHECKPOINT-OLD'
        $seed = $script:oldRecords | ConvertFrom-Json
        $record.RecordId | Should -BeExactly $seed.RecordId
        @($record.AttemptHistory).Count | Should -Be 1
        foreach ($field in @('Sequence', 'AttemptId', 'StepId', 'ActionName', 'Actor', 'Timestamp', 'Mode', 'TenantId', 'Serial', 'RecordId', 'EvidenceKind')) {
            $record.AttemptHistory[0].$field | Should -Be $seed.AttemptHistory[0].$field
        }
        foreach ($field in @('ActionName', 'Notes', 'Success', 'IsSimulated', 'CompletionState', 'Summary')) {
            $record.AttemptHistory[0].Result.$field | Should -Be $seed.AttemptHistory[0].Result.$field
        }
        foreach ($field in @('Serial', 'IntuneDeviceName')) {
            $record.AttemptHistory[0].Result.Data.$field | Should -BeExactly $seed.AttemptHistory[0].Result.Data.$field
        }
    }
}

Describe 'Actual Demo checkpoint save and restart workflow' {
    BeforeEach {
        $script:previousFixture = $global:AutopilotExpressCheckpointWorkflow
        $script:previousEnvironment = @{}
        foreach ($name in @('LOCALAPPDATA', 'PowerShellScriptingNewRoot', 'AutopilotExpressDefinitionDirectory')) {
            $script:previousEnvironment[$name] = [Environment]::GetEnvironmentVariable($name, 'Process')
        }
        $root = Join-Path $TestDrive ([guid]::NewGuid().Guid)
        $cliFolder = Join-Path $root 'cli'
        $localAppData = Join-Path $root 'local-app-data'
        New-Item -ItemType Directory -Path $cliFolder, $localAppData -ErrorAction Stop | Out-Null
        foreach ($fileName in @('autopilot-express.ps1', 'autopilot-express.manifest.json', 'autopilot-express.runtime.json')) {
            Copy-Item -LiteralPath (Join-Path $sourceFolder $fileName) -Destination $cliFolder -ErrorAction Stop
        }
        $data = Join-Path $cliFolder 'data'
        $global:AutopilotExpressCheckpointWorkflow = @{
            Root = $root; Data = $data; Logs = (Join-Path $localAppData 'AutopilotExpress'); EntryPoint = (Join-Path $cliFolder 'autopilot-express.ps1')
            # Records and Bench are replaced with the index-linked session paths once phase one has run.
            Records = (Join-Path $data ('autopilot-devices-demo-{0}.json' -f $env:USERNAME))
            Bench = (Join-Path $data ('build-bench-demo-{0}.json' -f $env:USERNAME))
            Checkpoint = (Join-Path $data ('autopilot-express-demo-{0}.checkpoint.json' -f $env:USERNAME))
            Lock = (Join-Path $data 'autopilot-express-demo.session.lock')
            # Site 1; main menu [1] Build Bench (formerly [8]); 2 positions; Desktop bench type; [I] induct at position 1:
            # keep site (N), serial, CI, device type, confirm (Y); then [C] run step A on position 1; [E] leave bench; [0] exit.
            Answers = @('1', '1', '2', 'Desktop', 'I', '1', 'N', 'CHECKPOINT-OLD', 'CI-OLD', 'Desktop', 'Y', 'C', '1', 'A', 'E', '0')
            Index = 0; Prompts = [System.Collections.Generic.List[string]]::new()
            Armed = $false; Restart = $false; RestartWrites = 0; Fault = ''; Target = ''
        }
        $env:LOCALAPPDATA = $localAppData
        $env:AutopilotExpressDefinitionDirectory = $cliFolder
        $env:PowerShellScriptingNewRoot = $cliFolder
        $script:Runtime = @{ IsDemoMode = $true }
        Mock Write-Host {}
        Mock Clear-Host {}
        Mock Invoke-RestMethod { throw 'Unexpected network request.' }
        Mock Invoke-WebRequest { throw 'Unexpected network request.' }
        Mock Connect-MgGraph { throw 'Unexpected authentication.' }
        Mock Invoke-MgGraphRequest { throw 'Unexpected tenant request.' }
        Mock Read-Host {
            $fixture = $global:AutopilotExpressCheckpointWorkflow
            $fixture.Prompts.Add([string]$Prompt)
            if ($fixture.Restart -or $fixture.Index -ge $fixture.Answers.Count) { throw ('Unexpected prompt: {0}' -f $Prompt) }
            $answer = $fixture.Answers[$fixture.Index]
            $fixture.Index++
            if ($answer -eq 'CI-NEW') {
                $fixture.BeforeRecords = Get-Content -LiteralPath $fixture.Records -Raw
                $fixture.BeforeBench = Get-Content -LiteralPath $fixture.Bench -Raw
                $fixture.Armed = $true
            }
            return $answer
        }
        Mock Set-Content {
            if ($global:AutopilotExpressCheckpointWorkflow.Restart) {
                $global:AutopilotExpressCheckpointWorkflow.RestartWrites++
                throw 'Unexpected restart data write.'
            }
            throw 'Synthetic operational staging fault'
        } -ParameterFilter {
            ($global:AutopilotExpressCheckpointWorkflow.Restart -and (Test-CheckpointWorkflowGuardedPath -Path $LiteralPath)) -or
            ($global:AutopilotExpressCheckpointWorkflow.Armed -and $global:AutopilotExpressCheckpointWorkflow.Fault -eq 'staging' -and
                $LiteralPath -eq ('{0}.pending' -f $global:AutopilotExpressCheckpointWorkflow.Target))
        }
        Mock Move-Item {
            if ($global:AutopilotExpressCheckpointWorkflow.Restart) {
                $global:AutopilotExpressCheckpointWorkflow.RestartWrites++
                throw 'Unexpected restart data promotion.'
            }
            throw 'Synthetic operational promotion fault'
        } -ParameterFilter {
            ($global:AutopilotExpressCheckpointWorkflow.Restart -and (Test-CheckpointWorkflowGuardedPath -Path $Destination)) -or
            ($global:AutopilotExpressCheckpointWorkflow.Armed -and $global:AutopilotExpressCheckpointWorkflow.Fault -eq 'promotion' -and
                $Destination -eq $global:AutopilotExpressCheckpointWorkflow.Target -and
                $LiteralPath -eq ('{0}.pending' -f $global:AutopilotExpressCheckpointWorkflow.Target))
        }
        Mock Remove-Item {
            if ($global:AutopilotExpressCheckpointWorkflow.Restart) {
                $global:AutopilotExpressCheckpointWorkflow.RestartWrites++
                throw 'Unexpected restart evidence removal.'
            }
            throw 'Synthetic checkpoint removal fault'
        } -ParameterFilter {
            ($global:AutopilotExpressCheckpointWorkflow.Restart -and (Test-CheckpointWorkflowGuardedPath -Path $LiteralPath)) -or
            ($global:AutopilotExpressCheckpointWorkflow.Armed -and $global:AutopilotExpressCheckpointWorkflow.Fault -eq 'removal' -and
                $LiteralPath -eq $global:AutopilotExpressCheckpointWorkflow.Checkpoint)
        }
        Mock Copy-Item {
            $global:AutopilotExpressCheckpointWorkflow.RestartWrites++
            throw 'Unexpected restart data copy.'
        } -ParameterFilter { $global:AutopilotExpressCheckpointWorkflow.Restart -and (Test-CheckpointWorkflowGuardedPath -Path $Destination) }
        Mock New-Item {
            $global:AutopilotExpressCheckpointWorkflow.RestartWrites++
            throw 'Unexpected restart data creation.'
        } -ParameterFilter { $global:AutopilotExpressCheckpointWorkflow.Restart -and (Test-CheckpointWorkflowGuardedPath -Path $Path) }

        & $global:AutopilotExpressCheckpointWorkflow.EntryPoint -Mode Demo
        $fixture = $global:AutopilotExpressCheckpointWorkflow
        $fixture.Index | Should -Be $fixture.Answers.Count
        Test-Path -LiteralPath $fixture.Checkpoint | Should -BeFalse
        Test-Path -LiteralPath $fixture.Lock | Should -BeFalse
        # New sessions write stamped, GUID-linked device and bench files; the per-user index is the only
        # authority for their names (the script never guesses the newest file), so the fixture follows it too.
        $sessionIndexPath = Join-Path $fixture.Data ('autopilot-session-demo-{0}.index.json' -f $env:USERNAME)
        Test-Path -LiteralPath $sessionIndexPath | Should -BeTrue
        $sessionIndex = Get-Content -LiteralPath $sessionIndexPath -Raw | ConvertFrom-Json
        $fixture.Records = Join-Path $fixture.Data $sessionIndex.DeviceFile
        $fixture.Bench = Join-Path $fixture.Data $sessionIndex.BenchFile
        $script:oldRecords = Get-Content -LiteralPath $fixture.Records -Raw
        $script:oldBench = Get-Content -LiteralPath $fixture.Bench -Raw
        # Resume (Y); site 1; main menu [1] Build Bench; [I] induct at position 2: keep site (N), serial, CI
        # (arms the fault), device type, confirm (Y) which performs the guarded writes; [E] leave bench; [0] exit.
        $fixture.Answers = @('Y', '1', '1', 'I', '2', 'N', 'CHECKPOINT-NEW', 'CI-NEW', 'Desktop', 'Y', 'E', '0')
        $fixture.Index = 0
    }

    AfterEach {
        try {
            Should -Invoke Invoke-RestMethod -Times 0 -Exactly
            Should -Invoke Invoke-WebRequest -Times 0 -Exactly
            Should -Invoke Connect-MgGraph -Times 0 -Exactly
            Should -Invoke Invoke-MgGraphRequest -Times 0 -Exactly
        }
        finally {
            foreach ($name in $script:previousEnvironment.Keys) {
                [Environment]::SetEnvironmentVariable($name, $script:previousEnvironment[$name], 'Process')
            }
            $global:AutopilotExpressCheckpointWorkflow = $script:previousFixture
        }
    }

    It 'retains verified proposal on <TargetName> <Fault> failure and blocks actual restart' -TestCases @(
        @{ TargetName = 'Records'; Fault = 'staging' }
        @{ TargetName = 'Records'; Fault = 'promotion' }
        @{ TargetName = 'Bench'; Fault = 'staging' }
        @{ TargetName = 'Bench'; Fault = 'promotion' }
    ) {
        param($TargetName, $Fault)
        $fixture = $global:AutopilotExpressCheckpointWorkflow
        $fixture.Target = $fixture[$TargetName]
        $fixture.Fault = $Fault
        { & $fixture.EntryPoint -Mode Demo } | Should -Throw ('*Synthetic operational {0} fault*' -f $Fault)
        # The confirmation answer (index 9) performs the faulted write, so ten answers are consumed.
        $fixture.Index | Should -Be 10
        $proposal = Assert-CheckpointWorkflowProposal
        Test-Path -LiteralPath ('{0}.write-in-progress' -f $fixture.Target) | Should -BeTrue
        Test-Path -LiteralPath ('{0}.pending' -f $fixture.Target) | Should -Be ($Fault -eq 'promotion')
        Get-Content -LiteralPath $fixture.Bench -Raw | Should -BeExactly $fixture.BeforeBench
        if ($TargetName -eq 'Records') {
            Get-Content -LiteralPath $fixture.Records -Raw | Should -BeExactly $fixture.BeforeRecords
        }
        else {
            Get-Content -LiteralPath $fixture.Records -Raw | Should -BeExactly $proposal.RecordsJson
            Get-Content -LiteralPath ('{0}.previous' -f $fixture.Records) -Raw | Should -BeExactly $fixture.BeforeRecords
        }
        if ($Fault -eq 'promotion') {
            Get-Content -LiteralPath ('{0}.pending' -f $fixture.Target) -Raw | Should -BeExactly $(if ($TargetName -eq 'Records') { $proposal.RecordsJson } else { $proposal.BenchJson })
            Get-Content -LiteralPath ('{0}.previous' -f $fixture.Target) -Raw | Should -BeExactly $(if ($TargetName -eq 'Records') { $fixture.BeforeRecords } else { $fixture.BeforeBench })
        }
        Assert-CheckpointWorkflowRestart
    }

    It 'retains checkpoint on removal failure after both operational writes without rollback' {
        $fixture = $global:AutopilotExpressCheckpointWorkflow
        $fixture.Fault = 'removal'
        { & $fixture.EntryPoint -Mode Demo } | Should -Throw '*Synthetic checkpoint removal fault*'
        $proposal = Assert-CheckpointWorkflowProposal
        Get-Content -LiteralPath $fixture.Records -Raw | Should -BeExactly $proposal.RecordsJson
        Get-Content -LiteralPath $fixture.Bench -Raw | Should -BeExactly $proposal.BenchJson
        Get-Content -LiteralPath ('{0}.previous' -f $fixture.Records) -Raw | Should -BeExactly $fixture.BeforeRecords
        Get-Content -LiteralPath ('{0}.previous' -f $fixture.Bench) -Raw | Should -BeExactly $fixture.BeforeBench
        foreach ($path in @($fixture.Records, $fixture.Bench)) {
            Test-Path -LiteralPath ('{0}.write-in-progress' -f $path) | Should -BeFalse
            Test-Path -LiteralPath ('{0}.pending' -f $path) | Should -BeFalse
        }
        Assert-CheckpointWorkflowRestart
    }

    It 'inspects actual retained proposal and evidence without writes or tenant calls' {
        $fixture = $global:AutopilotExpressCheckpointWorkflow
        $fixture.Target = $fixture.Bench
        $fixture.Fault = 'promotion'
        { & $fixture.EntryPoint -Mode Demo } | Should -Throw '*Synthetic operational promotion fault*'
        $fixture.Restart = $true
        $proposal = Assert-CheckpointWorkflowProposal
        $proposal.RecordsJson | Should -Not -BeNullOrEmpty
        $fixture.RestartWrites | Should -Be 0
    }

    It 'rejects damaged <Field> during read-only inspection and preserves all evidence' -TestCases @(
        @{ Field = 'Root'; Value = 'wrong-root' }
        @{ Field = 'RecordsJson'; Value = '{invalid-json' }
    ) {
        param($Field, $Value)
        $fixture = $global:AutopilotExpressCheckpointWorkflow
        $fixture.Fault = 'removal'
        { & $fixture.EntryPoint -Mode Demo } | Should -Throw '*Synthetic checkpoint removal fault*'
        $fixture.Armed = $false
        $proposal = Get-Content -LiteralPath $fixture.Checkpoint -Raw | ConvertFrom-Json
        $proposal.$Field = $Value
        $proposal | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $fixture.Checkpoint -Encoding UTF8 -NoNewline
        $before = Get-CheckpointWorkflowSnapshot
        $fixture.Restart = $true
        { Get-LocalCheckpointInspection } | Should -Throw
        $fixture.RestartWrites | Should -Be 0
        (Get-CheckpointWorkflowSnapshot) | Should -BeExactly $before
        Assert-CheckpointWorkflowRestart
    }

    It 'clears a successful actual CLI checkpoint and resumes the persisted bench and prior history' {
        $fixture = $global:AutopilotExpressCheckpointWorkflow
        & $fixture.EntryPoint -Mode Demo
        $fixture.Index | Should -Be $fixture.Answers.Count
        Test-Path -LiteralPath $fixture.Checkpoint | Should -BeFalse
        Test-Path -LiteralPath $fixture.Lock | Should -BeFalse
        $savedRecords = Get-Content -LiteralPath $fixture.Records -Raw
        $savedBench = Get-Content -LiteralPath $fixture.Bench -Raw
        $decodedRecords = $savedRecords | ConvertFrom-Json
        @($decodedRecords).Count | Should -Be 2
        ($savedBench | ConvertFrom-Json).Positions[1].Serial | Should -BeExactly 'CHECKPOINT-NEW'
        $fixture.Answers = @('Y', '1', '1', 'E', '0')
        $fixture.Index = 0
        & $fixture.EntryPoint -Mode Demo
        $fixture.Index | Should -Be $fixture.Answers.Count
        Assert-CheckpointWorkflowResumedRecords -BeforeJson $savedRecords -AfterJson (Get-Content -LiteralPath $fixture.Records -Raw)
        Get-Content -LiteralPath $fixture.Bench -Raw | Should -BeExactly $savedBench
        Assert-CheckpointWorkflowHistory -RecordsJson $savedRecords
        Test-Path -LiteralPath $fixture.Checkpoint | Should -BeFalse
        Test-Path -LiteralPath $fixture.Lock | Should -BeFalse
        Test-Path -LiteralPath (Join-Path $fixture.Data 'autopilot-master-audit.json') | Should -BeFalse
    }

    It 'retains prior history after a negative confirmation and actual restart' {
        $fixture = $global:AutopilotExpressCheckpointWorkflow
        # Resume (Y); site 1; [2] Devices submenu; [2] continue a current device; device 1; [X] then decline (N);
        # Enter to acknowledge; [0] back to Main Menu; [0] exit.
        $fixture.Answers = @('Y', '1', '2', '2', '1', 'X', 'N', '', '0', '0')
        $fixture.Index = 0
        & $fixture.EntryPoint -Mode Demo
        $fixture.Index | Should -Be $fixture.Answers.Count
        $after = Get-Content -LiteralPath $fixture.Records -Raw
        Assert-CheckpointWorkflowHistory -RecordsJson $after
        $fixture.Answers = @('Y', '1', '0')
        $fixture.Index = 0
        & $fixture.EntryPoint -Mode Demo
        $fixture.Index | Should -Be $fixture.Answers.Count
        Assert-CheckpointWorkflowResumedRecords -BeforeJson $after -AfterJson (Get-Content -LiteralPath $fixture.Records -Raw)
        Assert-CheckpointWorkflowHistory -RecordsJson (Get-Content -LiteralPath $fixture.Records -Raw)
        $record = $after | ConvertFrom-Json
        @($record.AttemptHistory).Count | Should -BeGreaterThan 0
        $record.RecoveryActive | Should -BeFalse
        Test-Path -LiteralPath $fixture.Checkpoint | Should -BeFalse
        Test-Path -LiteralPath $fixture.Lock | Should -BeFalse
    }
}