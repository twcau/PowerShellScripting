<#
.SYNOPSIS
    Rehearses the actual Demo CLI through device creation, reload and completion.
.DESCRIPTION
    Copies the entry point and definitions into Pester temporary storage. Only host
    prompts and screen clearing are mocked. No Graph or physical actions occur.
    Requires Pester 5; preserves inherited root variables after the rehearsal.
#>
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidGlobalVars', '', Justification = 'The real entry point has a separate script scope. This uniquely named test-only prompt fixture crosses that boundary and is restored in finally; no product global is introduced.')]
param()

Describe 'Full Demo operator workflow' {
    BeforeAll {
        function Get-RehearsalSessionFilePath {
            <#
            .SYNOPSIS Resolve the stamped device or bench file linked by the per-user session index.
            .DESCRIPTION
                New sessions write yyyyMMdd-HHmm-<prefix>-<user>-<guid>.json files. The script treats the
                index as the only authority for their names and never guesses the newest file; so does this.
            .PARAMETER DataFolder
                Rehearsal data folder containing autopilot-session-demo-<user>.index.json.
            .PARAMETER Kind
                Device for the device-record file, or Bench for the bench-state file.
            .OUTPUTS
                Full linked path. Throws when the index is missing so a broken save cannot pass silently.
            #>
            param([Parameter(Mandatory)][string]$DataFolder, [Parameter(Mandatory)][ValidateSet('Device', 'Bench')][string]$Kind)
            $indexPath = Join-Path $DataFolder ('autopilot-session-demo-{0}.index.json' -f $env:USERNAME)
            if (-not (Test-Path -LiteralPath $indexPath)) { throw ('Session index not found: {0}' -f $indexPath) }
            $index = Get-Content -LiteralPath $indexPath -Raw | ConvertFrom-Json
            $fileName = if ($Kind -eq 'Device') { $index.DeviceFile } else { $index.BenchFile }
            return Join-Path $DataFolder $fileName
        }
    }

    BeforeEach {
        $script:previousLocalAppData = [Environment]::GetEnvironmentVariable('LOCALAPPDATA', 'Process')
        $isolatedLocalAppData = Join-Path $TestDrive ('local-app-data-{0}' -f [guid]::NewGuid().Guid)
        New-Item -ItemType Directory -Path $isolatedLocalAppData -ErrorAction Stop | Out-Null
        [Environment]::SetEnvironmentVariable('LOCALAPPDATA', $isolatedLocalAppData, 'Process')
    }

    AfterEach {
        [Environment]::SetEnvironmentVariable('LOCALAPPDATA', $script:previousLocalAppData, 'Process')
    }

    It 'stops before operational storage when bootstrap mode selection is interrupted' {
        $sourceFolder = Split-Path -Parent $PSScriptRoot
        $rehearsalFolder = Join-Path $TestDrive 'bootstrap-interrupted'
        New-Item -ItemType Directory -Path $rehearsalFolder | Out-Null
        foreach ($fileName in @('autopilot-express.ps1', 'autopilot-express.manifest.json', 'autopilot-express.runtime.json')) {
            Copy-Item -LiteralPath (Join-Path $sourceFolder $fileName) -Destination $rehearsalFolder
        }
        $previousRoot = $env:PowerShellScriptingNewRoot
        $previousDefinitions = $env:AutopilotExpressDefinitionDirectory
        Mock Read-Host { throw 'Synthetic bootstrap cancellation' }
        Mock Write-Host {}
        try {
            $env:AutopilotExpressDefinitionDirectory = $rehearsalFolder
            { & (Join-Path $rehearsalFolder 'autopilot-express.ps1') -Mode '' } | Should -Throw '*Synthetic bootstrap cancellation*'
            Should -Invoke Read-Host -Times 1 -Exactly -ParameterFilter { $Prompt -eq 'Select mode: Live or Demo (default: Demo)' }
            Test-Path -LiteralPath (Join-Path $rehearsalFolder 'data') | Should -BeFalse
        }
        finally {
            $env:PowerShellScriptingNewRoot = $previousRoot
            $env:AutopilotExpressDefinitionDirectory = $previousDefinitions
        }
    }

    It 'rejects an invalid manifest before prompts or operational storage' {
        $sourceFolder = Split-Path -Parent $PSScriptRoot
        $rehearsalFolder = Join-Path $TestDrive 'invalid-manifest'
        New-Item -ItemType Directory -Path $rehearsalFolder | Out-Null
        foreach ($fileName in @('autopilot-express.ps1', 'autopilot-express.manifest.json', 'autopilot-express.runtime.json')) {
            Copy-Item -LiteralPath (Join-Path $sourceFolder $fileName) -Destination $rehearsalFolder
        }
        $manifestPath = Join-Path $rehearsalFolder 'autopilot-express.manifest.json'
        $manifest = Get-Content -LiteralPath $manifestPath -Raw | ConvertFrom-Json
        $manifest.steps[0].actionName = 'UnsupportedAction'
        $manifest | ConvertTo-Json -Depth 100 | Set-Content -LiteralPath $manifestPath -Encoding UTF8
        $previousRoot = $env:PowerShellScriptingNewRoot
        $previousDefinitions = $env:AutopilotExpressDefinitionDirectory
        Mock Read-Host { throw 'Unexpected prompt before manifest validation' }
        Mock Write-Host {}
        try {
            $env:AutopilotExpressDefinitionDirectory = $rehearsalFolder
            { & (Join-Path $rehearsalFolder 'autopilot-express.ps1') -Mode Demo } | Should -Throw '*unsupported actionName*'
            Should -Invoke Read-Host -Times 0 -Exactly
            Test-Path -LiteralPath (Join-Path $rehearsalFolder 'data') | Should -BeFalse
        }
        finally {
            $env:PowerShellScriptingNewRoot = $previousRoot
            $env:AutopilotExpressDefinitionDirectory = $previousDefinitions
        }
    }

    It 'rejects configured Shared storage before prompts or operational files' {
        $sourceFolder = Split-Path -Parent $PSScriptRoot
        $rehearsalFolder = Join-Path $TestDrive 'unsupported-shared'
        New-Item -ItemType Directory -Path $rehearsalFolder | Out-Null
        foreach ($fileName in @('autopilot-express.ps1', 'autopilot-express.manifest.json', 'autopilot-express.runtime.json')) {
            Copy-Item -LiteralPath (Join-Path $sourceFolder $fileName) -Destination $rehearsalFolder
        }
        $runtimePath = Join-Path $rehearsalFolder 'autopilot-express.runtime.json'
        $runtime = Get-Content -LiteralPath $runtimePath -Raw | ConvertFrom-Json
        $runtime.storage.mode = 'Shared'
        $runtime | ConvertTo-Json -Depth 100 | Set-Content -LiteralPath $runtimePath -Encoding UTF8
        $previousRoot = $env:PowerShellScriptingNewRoot
        $previousDefinitions = $env:AutopilotExpressDefinitionDirectory
        Mock Read-Host { throw 'Unexpected prompt before storage-mode validation' }
        Mock Write-Host {}
        try {
            $env:AutopilotExpressDefinitionDirectory = $rehearsalFolder
            { & (Join-Path $rehearsalFolder 'autopilot-express.ps1') -Mode Demo } | Should -Throw '*Shared storage is disabled*'
            Should -Invoke Read-Host -Times 0 -Exactly
            Test-Path -LiteralPath (Join-Path $rehearsalFolder 'data') | Should -BeFalse
        }
        finally {
            $env:PowerShellScriptingNewRoot = $previousRoot
            $env:AutopilotExpressDefinitionDirectory = $previousDefinitions
        }
    }

    It 'stops before resume prompts for an interrupted device save' {
        $sourceFolder = Split-Path -Parent $PSScriptRoot
        $rehearsalFolder = Join-Path $TestDrive 'interrupted-save'
        $dataFolder = Join-Path $rehearsalFolder 'data'
        New-Item -ItemType Directory -Path $dataFolder -Force | Out-Null
        foreach ($fileName in @('autopilot-express.ps1', 'autopilot-express.manifest.json', 'autopilot-express.runtime.json')) {
            Copy-Item -LiteralPath (Join-Path $sourceFolder $fileName) -Destination $rehearsalFolder
        }
        $markerPath = Join-Path $dataFolder ('autopilot-devices-demo-{0}.json.write-in-progress' -f $env:USERNAME)
        New-Item -ItemType File -Path $markerPath -Value 'interrupted' | Out-Null
        $previousRoot = $env:PowerShellScriptingNewRoot
        $previousDefinitions = $env:AutopilotExpressDefinitionDirectory
        Mock Read-Host { throw 'Unexpected prompt before interrupted-save check' }
        Mock Write-Host {}
        try {
            $env:AutopilotExpressDefinitionDirectory = $rehearsalFolder
            { & (Join-Path $rehearsalFolder 'autopilot-express.ps1') -Mode Demo } | Should -Throw '*Interrupted save recovery is required*'
            Should -Invoke Read-Host -Times 0 -Exactly
            Get-Content -LiteralPath $markerPath -Raw | Should -BeExactly 'interrupted'
            Test-Path -LiteralPath (Join-Path $dataFolder 'autopilot-express-demo.session.lock') | Should -BeFalse
        }
        finally {
            $env:PowerShellScriptingNewRoot = $previousRoot
            $env:AutopilotExpressDefinitionDirectory = $previousDefinitions
        }
    }

    It 'releases its reservation when actual startup fails' {
        $sourceFolder = Split-Path -Parent $PSScriptRoot
        $rehearsalFolder = Join-Path $TestDrive 'interrupted'
        New-Item -ItemType Directory -Path $rehearsalFolder | Out-Null
        foreach ($fileName in @('autopilot-express.ps1', 'autopilot-express.manifest.json', 'autopilot-express.runtime.json')) {
            Copy-Item -LiteralPath (Join-Path $sourceFolder $fileName) -Destination $rehearsalFolder
        }
        $previousRoot = $env:PowerShellScriptingNewRoot
        $previousDefinitions = $env:AutopilotExpressDefinitionDirectory
        Mock Read-Host { throw 'Synthetic startup interruption' }
        Mock Write-Host {}
        try {
            $env:AutopilotExpressDefinitionDirectory = $rehearsalFolder
            { & (Join-Path $rehearsalFolder 'autopilot-express.ps1') -Mode Demo } | Should -Throw '*Synthetic startup interruption*'
            Test-Path -LiteralPath (Join-Path $rehearsalFolder 'data/autopilot-express-demo.session.lock') | Should -BeFalse
        }
        finally {
            $env:PowerShellScriptingNewRoot = $previousRoot
            $env:AutopilotExpressDefinitionDirectory = $previousDefinitions
        }
    }

    It 'offers only guarded reservation recovery before any other prompt when the local store is reserved' {
        $sourceFolder = Split-Path -Parent $PSScriptRoot
        $rehearsalFolder = Join-Path $TestDrive 'reserved'
        $dataFolder = Join-Path $rehearsalFolder 'data'
        New-Item -ItemType Directory -Path $dataFolder -Force | Out-Null
        foreach ($fileName in @('autopilot-express.ps1', 'autopilot-express.manifest.json', 'autopilot-express.runtime.json')) {
            Copy-Item -LiteralPath (Join-Path $sourceFolder $fileName) -Destination $rehearsalFolder
        }
        $lockPath = Join-Path $dataFolder 'autopilot-express-demo.session.lock'
        New-Item -ItemType File -Path $lockPath -Value '{"Token":"owning-session"}' | Out-Null
        $previousRoot = $env:PowerShellScriptingNewRoot
        $previousDefinitions = $env:AutopilotExpressDefinitionDirectory
        # Request-LocalSessionLock keeps startup in its recovery menu. An unverifiable owner must not be offered
        # [C] recovery, so the only valid choices are R and 0; answering 0 returns without starting a session.
        Mock Read-Host {
            if ($Prompt -notlike 'Choose R, 0*') { throw ('Unexpected prompt before storage reservation: {0}' -f $Prompt) }
            return '0'
        }
        Mock Write-Host {}
        try {
            $env:AutopilotExpressDefinitionDirectory = $rehearsalFolder
            { & (Join-Path $rehearsalFolder 'autopilot-express.ps1') -Mode Demo } | Should -Not -Throw
            Should -Invoke Read-Host -Times 1 -Exactly
            Should -Invoke Write-Host -ParameterFilter { $Object -like 'Returned without starting a session*' } -Times 1 -Exactly
            (Get-Content -LiteralPath $lockPath -Raw | ConvertFrom-Json).Token | Should -Be 'owning-session'
            @(Get-ChildItem -LiteralPath $dataFolder -File).Count | Should -Be 1
        }
        finally {
            $env:PowerShellScriptingNewRoot = $previousRoot
            $env:AutopilotExpressDefinitionDirectory = $previousDefinitions
        }
    }

    It 'persists incomplete work and completes only after every normal action' {
        $sourceFolder = Split-Path -Parent $PSScriptRoot
        $rehearsalFolder = Join-Path $TestDrive 'operator'
        New-Item -ItemType Directory -Path $rehearsalFolder | Out-Null
        foreach ($fileName in @('autopilot-express.ps1', 'autopilot-express.manifest.json', 'autopilot-express.runtime.json')) {
            Copy-Item -LiteralPath (Join-Path $sourceFolder $fileName) -Destination $rehearsalFolder
        }
        $entryPoint = Join-Path $rehearsalFolder 'autopilot-express.ps1'
        $dataFolder = Join-Path $rehearsalFolder 'data'
        $previousRoot = $env:PowerShellScriptingNewRoot
        $previousDefinitions = $env:AutopilotExpressDefinitionDirectory
        $previousInputState = $global:AutopilotExpressRehearsalInput
        # Site 1 (MI); main menu [2] Devices; [1] start a new device (no bench, so no placement prompt; no off-bench
        # workflows, so no source prompt); keep site (N); serial; CI; type; confirm (Y); Enter returns to Devices.
        $global:AutopilotExpressRehearsalInput = @{ Answers = @('1', '2', '1', 'N', 'DEMO-FULL-01', 'CI-DEMO-01', 'Desktop', 'Y', ''); Index = 0 }
        # Devices [2] continue a current device; device 1; step A, then [8] (run next eligible step) for B to N.
        # The step screen stays open after each action. Guided milestones E, G, H, K, L and N need a Y confirmation;
        # step I selects recent technician 1 (R, 1) and confirms it (Y). Enter at M selects no failures.
        $global:AutopilotExpressRehearsalInput.Answers += @(
            '2', '1', 'A', '8', '8', '8', # A-D
            '8', 'Y',                    # E
            '8',                         # F
            '8', 'Y',                    # G
            '8', 'Y',                    # H
            '8', 'R', '1', 'Y',          # I
            '8',                         # J
            '8', 'Y',                    # K
            '8', 'Y',                    # L
            '8', '',                     # M
            '8', 'Y'                     # N
        )
        # Step O ([8]) cancelled at its final-user search ([0]) leaves the device incomplete; [0] back to device
        # commands; [0] back to Main Menu; [0] exit.
        $global:AutopilotExpressRehearsalInput.Answers += @('8', '0', '0', '0', '0')
        Mock Read-Host {
            if ($global:AutopilotExpressRehearsalInput.Index -ge $global:AutopilotExpressRehearsalInput.Answers.Count) { throw ('Unexpected prompt: {0}' -f $Prompt) }
            $answer = $global:AutopilotExpressRehearsalInput.Answers[$global:AutopilotExpressRehearsalInput.Index]
            $global:AutopilotExpressRehearsalInput.Index++
            return $answer
        }
        Mock Clear-Host {}
        Mock Write-Host {}
        try {
            $env:AutopilotExpressDefinitionDirectory = $rehearsalFolder
            & $entryPoint -Mode Demo
            $global:AutopilotExpressRehearsalInput.Index | Should -Be $global:AutopilotExpressRehearsalInput.Answers.Count
            $recordPath = Get-RehearsalSessionFilePath -DataFolder $dataFolder -Kind Device
            Test-Path -LiteralPath $recordPath | Should -BeTrue
            $savedRecords = Get-Content -LiteralPath $recordPath -Raw | ConvertFrom-Json
            $savedRecords = @($savedRecords)
            $savedRecords.Count | Should -Be 1
            $savedRecords[0].Serial | Should -Be 'DEMO-FULL-01'
            $savedRecords[0].GroupTag | Should -Be 'MI-Desktop'
            $savedRecords[0].Status | Should -Be 'in-progress'
            $savedRecords[0].Steps.M.Data.NoApplicationFailures | Should -BeTrue
            $savedRecords[0].Steps.M.Data.SyncRequestedForOutcome | Should -BeFalse
            $savedRecords[0].Steps.N.CompletionState | Should -Be 'Simulated'
            $savedRecords[0].Steps.O.CompletionState | Should -Not -Be 'Simulated'

            # Resume (Y); site 1; [2] Devices; [2] continue device 1; O selects recent final user 1 (1, 1);
            # [0] back to device commands; [0] back to Main Menu; [0] exit.
            $global:AutopilotExpressRehearsalInput.Answers = @('Y', '1', '2', '2', '1', 'O', '1', '1', '0', '0', '0')
            $global:AutopilotExpressRehearsalInput.Index = 0
            & $entryPoint -Mode Demo
            $global:AutopilotExpressRehearsalInput.Index | Should -Be $global:AutopilotExpressRehearsalInput.Answers.Count
            $reloadedRecords = Get-Content -LiteralPath $recordPath -Raw | ConvertFrom-Json
            $reloadedRecords = @($reloadedRecords)
            $reloadedRecords[0].RecordId | Should -Be $savedRecords[0].RecordId
            $reloadedRecords[0].Status | Should -Be 'completed'
            $reloadedRecords[0].CompletedAt | Should -Not -BeNullOrEmpty
            $reloadedRecords[0].FinalPrimaryUserPrincipalName | Should -Not -BeNullOrEmpty
            $manifest = Get-Content -LiteralPath (Join-Path $rehearsalFolder 'autopilot-express.manifest.json') -Raw | ConvertFrom-Json
            foreach ($definition in @($manifest.steps | Where-Object { $_.enabled -and $_.activationRequirement -ne 'RecoveryMode' })) {
                $reloadedRecords[0].Steps.($definition.id).CompletionState | Should -Be 'Simulated'
            }
            Test-Path -LiteralPath (Join-Path $rehearsalFolder 'data/autopilot-master-audit.json') | Should -BeFalse
        }
        finally {
            $env:PowerShellScriptingNewRoot = $previousRoot
            $env:AutopilotExpressDefinitionDirectory = $previousDefinitions
            $global:AutopilotExpressRehearsalInput = $previousInputState
        }
    }

    It 'completes every normal task through bench selectors and retains outcomes across resumed bench sessions' {
        $sourceFolder = Split-Path -Parent $PSScriptRoot
        $rehearsalFolder = Join-Path $TestDrive 'next-action-bench'
        New-Item -ItemType Directory -Path $rehearsalFolder | Out-Null
        foreach ($fileName in @('autopilot-express.ps1', 'autopilot-express.manifest.json', 'autopilot-express.runtime.json')) {
            Copy-Item -LiteralPath (Join-Path $sourceFolder $fileName) -Destination $rehearsalFolder
        }
        $entryPoint = Join-Path $rehearsalFolder 'autopilot-express.ps1'
        $dataFolder = Join-Path $rehearsalFolder 'data'
        $previousRoot = $env:PowerShellScriptingNewRoot
        $previousDefinitions = $env:AutopilotExpressDefinitionDirectory
        $previousInputState = $global:AutopilotExpressRehearsalInput
        $global:AutopilotExpressRehearsalInput = @{
            Answers = @(
                # Site 1 (MI); main menu [1] Build Bench; two positions; Desktop bench default.
                '1', '1', '2', 'Desktop',
                # Induct position 1 and 2: position, keep site (N), serial, CI, type, confirm (Y).
                'I', '1', 'N', 'DEMO-NEXT-01', 'CI-NEXT-01', 'Desktop', 'Y',
                'I', '2', 'N', 'DEMO-NEXT-02', 'CI-NEXT-02', 'Laptop', 'Y',
                # Steps list guide ([0] returns to the bench); an unmatched T selector runs nothing.
                'W', '0', 'T', 'missing',
                # CI: selector opens position 1 and returns unchanged; S: selector runs A on position 2 only.
                'CI:CI-NEXT-01', '0',
                'S:DEMO-NEXT-02', 'A', '0',
                # P: selector opens position 1; A, then [8] for B to O with each guided confirmation:
                # E, G, H, K, L, N (Y); I recent technician 1 (R, 1, Y); M defaults to no failures;
                # O selects recent final user 1 (1, 1).
                'P:1', 'A', '8', '8', '8', # A-D
                '8', 'Y',                  # E
                '8',                       # F
                '8', 'Y',                  # G
                '8', 'Y',                  # H
                '8', 'R', '1', 'Y',        # I
                '8',                       # J
                '8', 'Y',                  # K
                '8', 'Y',                  # L
                '8', '',                   # M
                '8', 'Y',                  # N
                '8', '1', '1',             # O
                # [0] back to the bench; [E] Main Menu; [0] exit.
                '0', 'E', '0'
            )
            Index   = 0
        }
        Mock Read-Host {
            if ($global:AutopilotExpressRehearsalInput.Index -ge $global:AutopilotExpressRehearsalInput.Answers.Count) { throw ('Unexpected bench prompt: {0}' -f $Prompt) }
            $answer = $global:AutopilotExpressRehearsalInput.Answers[$global:AutopilotExpressRehearsalInput.Index]
            $global:AutopilotExpressRehearsalInput.Index++
            return $answer
        }
        Mock Clear-Host {}
        Mock Write-Host {}
        try {
            $env:AutopilotExpressDefinitionDirectory = $rehearsalFolder
            & $entryPoint -Mode Demo
            $global:AutopilotExpressRehearsalInput.Index | Should -Be $global:AutopilotExpressRehearsalInput.Answers.Count
            $recordPath = Get-RehearsalSessionFilePath -DataFolder $dataFolder -Kind Device
            $benchPath = Get-RehearsalSessionFilePath -DataFolder $dataFolder -Kind Bench
            $manifest = Get-Content -LiteralPath (Join-Path $rehearsalFolder 'autopilot-express.manifest.json') -Raw | ConvertFrom-Json
            $normalOrder = @($manifest.steps | Where-Object { $_.enabled -and $_.activationRequirement -ne 'RecoveryMode' } | ForEach-Object { $_.id })
            $recoveryOnly = @($manifest.steps | Where-Object { $_.enabled -and $_.activationRequirement -eq 'RecoveryMode' } | ForEach-Object { $_.id })
            $normalOrder.Count | Should -BeGreaterThan 0
            $recoveryOnly.Count | Should -BeGreaterThan 0
            $saved = @(Get-Content -LiteralPath $recordPath -Raw | ConvertFrom-Json | ForEach-Object { $_ })
            $finished = $saved | Where-Object { $_.Serial -eq 'DEMO-NEXT-01' }
            $finished.Status | Should -Be 'completed'
            $finished.FinalPrimaryUserPrincipalName | Should -Not -BeNullOrEmpty
            $finished.Steps.M.Data.NoApplicationFailures | Should -BeTrue
            $finished.Steps.M.Data.SyncRequestedForOutcome | Should -BeFalse
            foreach ($stepId in $normalOrder) { $finished.Steps.$stepId.CompletionState | Should -Be 'Simulated' }
            foreach ($stepId in $recoveryOnly) { $finished.Steps.$stepId | Should -BeNullOrEmpty }
            $other = $saved | Where-Object { $_.Serial -eq 'DEMO-NEXT-02' }
            $other.Steps.A.CompletionState | Should -Be 'Simulated'
            $other.Steps.B | Should -BeNullOrEmpty
            $bench = Get-Content -LiteralPath $benchPath -Raw | ConvertFrom-Json
            $bench.Positions[0].Serial | Should -Be 'DEMO-NEXT-01'
            $bench.Positions[1].Serial | Should -Be 'DEMO-NEXT-02'
            Should -Invoke Write-Host -ParameterFilter { $Object -like '*No unique device at that position or identifier*' }
            Should -Invoke Write-Host -Times 1 -Exactly -ParameterFilter { $Object -eq 'Remaining checklist handoffs (v1.4, steps 24-26)' }

            # Resume (Y); site 1; [1] Build Bench; dispatch position 1 (D, 1, confirm Y); [E] Main Menu; [0] exit.
            $global:AutopilotExpressRehearsalInput.Answers = @('Y', '1', '1', 'D', '1', 'Y', 'E', '0')
            $global:AutopilotExpressRehearsalInput.Index = 0
            & $entryPoint -Mode Demo
            $global:AutopilotExpressRehearsalInput.Index | Should -Be $global:AutopilotExpressRehearsalInput.Answers.Count
            $reloaded = @(Get-Content -LiteralPath $recordPath -Raw | ConvertFrom-Json | ForEach-Object { $_ })
            $finishedAgain = $reloaded | Where-Object { $_.Serial -eq 'DEMO-NEXT-01' }
            $remaining = $reloaded | Where-Object { $_.Serial -eq 'DEMO-NEXT-02' }
            $finishedAgain.RecordId | Should -Be $finished.RecordId
            $finishedAgain.Status | Should -Be 'completed'
            foreach ($stepId in $normalOrder) { $finishedAgain.Steps.$stepId.CompletionState | Should -Be 'Simulated' }
            $remaining.RecordId | Should -Be $other.RecordId
            $remaining.DeviceType | Should -Be 'Laptop'
            $remaining.Steps.A.CompletionState | Should -Be 'Simulated'
            $remaining.Steps.B | Should -BeNullOrEmpty
            $bench = Get-Content -LiteralPath $benchPath -Raw | ConvertFrom-Json
            $bench.Positions[0].Serial | Should -BeNullOrEmpty
            $bench.Positions[1].Serial | Should -Be 'DEMO-NEXT-02'
            Test-Path -LiteralPath (Join-Path $rehearsalFolder 'data/autopilot-master-audit.json') | Should -BeFalse
        }
        finally {
            $env:PowerShellScriptingNewRoot = $previousRoot
            $env:AutopilotExpressDefinitionDirectory = $previousDefinitions
            $global:AutopilotExpressRehearsalInput = $previousInputState
        }
    }

    It 'keeps two bench devices independent through induction, move, reload and dispatch' {
        $sourceFolder = Split-Path -Parent $PSScriptRoot
        $rehearsalFolder = Join-Path $TestDrive 'bench'
        New-Item -ItemType Directory -Path $rehearsalFolder | Out-Null
        foreach ($fileName in @('autopilot-express.ps1', 'autopilot-express.manifest.json', 'autopilot-express.runtime.json')) {
            Copy-Item -LiteralPath (Join-Path $sourceFolder $fileName) -Destination $rehearsalFolder
        }
        $entryPoint = Join-Path $rehearsalFolder 'autopilot-express.ps1'
        $dataFolder = Join-Path $rehearsalFolder 'data'
        $previousRoot = $env:PowerShellScriptingNewRoot
        $previousDefinitions = $env:AutopilotExpressDefinitionDirectory
        $previousInputState = $global:AutopilotExpressRehearsalInput
        $global:AutopilotExpressRehearsalInput = @{
            Answers = @(
                # Site 1 (MI); main menu [1] Build Bench; three positions; Desktop bench default.
                '1', '1', '3', 'Desktop',
                # Induct positions 1 and 2: position, keep site (N), serial, CI, type, confirm (Y).
                'I', '1', 'N', 'DEMO-BENCH-01', 'CI-BENCH-01', 'Desktop', 'Y',
                'I', '2', 'N', 'DEMO-BENCH-02', 'CI-BENCH-02', 'Laptop', 'Y',
                # A duplicate serial is refused on the bench; [0] cancels at the re-offered site prompt.
                'I', '3', 'N', 'DEMO-BENCH-01', '0',
                # S (next step) runs A on position 2 then position 1; C runs B on position 1 only.
                'S', '2', 'S', '1', 'C', '1', 'B',
                # Move position 1: occupied destination 2 is refused, then 3 is accepted.
                'M', '1', '2', '3',
                # Dispatch of the incomplete device at position 3 is refused.
                'D', '3',
                # V opens the device overview for position 2; [0] back to the bench; [E] Main Menu; [0] exit.
                'V', '2', '0', 'E', '0'
            )
            Index   = 0
        }
        Mock Read-Host {
            if ($global:AutopilotExpressRehearsalInput.Index -ge $global:AutopilotExpressRehearsalInput.Answers.Count) { throw ('Unexpected bench prompt: {0}' -f $Prompt) }
            $answer = $global:AutopilotExpressRehearsalInput.Answers[$global:AutopilotExpressRehearsalInput.Index]
            $global:AutopilotExpressRehearsalInput.Index++
            return $answer
        }
        Mock Clear-Host {}
        Mock Write-Host {}
        try {
            $env:AutopilotExpressDefinitionDirectory = $rehearsalFolder
            & $entryPoint -Mode Demo
            $global:AutopilotExpressRehearsalInput.Index | Should -Be $global:AutopilotExpressRehearsalInput.Answers.Count
            $recordPath = Get-RehearsalSessionFilePath -DataFolder $dataFolder -Kind Device
            $benchPath = Get-RehearsalSessionFilePath -DataFolder $dataFolder -Kind Bench
            $savedRecords = @(Get-Content -LiteralPath $recordPath -Raw | ConvertFrom-Json | ForEach-Object { $_ })
            $savedRecords.Count | Should -Be 2
            $desktop = $savedRecords | Where-Object { $_.Serial -eq 'DEMO-BENCH-01' }
            $laptop = $savedRecords | Where-Object { $_.Serial -eq 'DEMO-BENCH-02' }
            $desktop.GroupTag | Should -Be 'MI-Desktop'
            $laptop.GroupTag | Should -Be 'MI-Laptop'
            $desktop.Steps.B.CompletionState | Should -Be 'Simulated'
            $laptop.Steps.A.CompletionState | Should -Be 'Simulated'
            $laptop.Steps.B | Should -BeNullOrEmpty
            $bench = Get-Content -LiteralPath $benchPath -Raw | ConvertFrom-Json
            $bench.Positions[0].Serial | Should -BeNullOrEmpty
            $bench.Positions[1].Serial | Should -Be 'DEMO-BENCH-02'
            $bench.Positions[2].Serial | Should -Be 'DEMO-BENCH-01'
            Should -Invoke Write-Host -Times 1 -Exactly -ParameterFilter { $Object -like 'This serial is already on the bench*' }
            Should -Invoke Write-Host -Times 1 -Exactly -ParameterFilter { $Object -like '*Position 2 is occupied*' }
            Should -Invoke Write-Host -ParameterFilter { $Object -like '*Cannot dispatch device*' }

            # Resume (Y); site 1; [1] Build Bench; then S on position 3 for C to O with each guided confirmation:
            # E, G, H, K, L, N (Y); I recent technician 1 (R, 1, Y); M defaults to no failures;
            # O selects recent final user 1 (1, 1).
            $global:AutopilotExpressRehearsalInput.Answers = @(
                'Y', '1', '1',
                'S', '3', 'S', '3',      # C-D
                'S', '3', 'Y',           # E
                'S', '3',                # F
                'S', '3', 'Y',           # G
                'S', '3', 'Y',           # H
                'S', '3', 'R', '1', 'Y', # I
                'S', '3',                # J
                'S', '3', 'Y',           # K
                'S', '3', 'Y',           # L
                'S', '3', '',            # M
                'S', '3', 'Y',           # N
                'S', '3', '1', '1',      # O
                # Dispatch position 3 (D, 3, confirm Y); [E] Main Menu; [0] exit.
                'D', '3', 'Y', 'E', '0'
            )
            $global:AutopilotExpressRehearsalInput.Index = 0
            & $entryPoint -Mode Demo
            $global:AutopilotExpressRehearsalInput.Index | Should -Be $global:AutopilotExpressRehearsalInput.Answers.Count
            $reloadedRecords = @(Get-Content -LiteralPath $recordPath -Raw | ConvertFrom-Json | ForEach-Object { $_ })
            $finished = $reloadedRecords | Where-Object { $_.Serial -eq 'DEMO-BENCH-01' }
            $remaining = $reloadedRecords | Where-Object { $_.Serial -eq 'DEMO-BENCH-02' }
            $finished.RecordId | Should -Be $desktop.RecordId
            $finished.Status | Should -Be 'completed'
            $finished.Steps.M.Data.NoApplicationFailures | Should -BeTrue
            $finished.Steps.M.Data.SyncRequestedForOutcome | Should -BeFalse
            $remaining.RecordId | Should -Be $laptop.RecordId
            $remaining.Status | Should -BeIn @('new', 'in-progress')
            $remaining.Steps.A.CompletionState | Should -Be 'Simulated'
            $remaining.Steps.B | Should -BeNullOrEmpty
            Should -Invoke Write-Host -Times 1 -Exactly -ParameterFilter { $Object -eq 'Remaining checklist handoffs (v1.4, steps 24-26)' }
            $bench = Get-Content -LiteralPath $benchPath -Raw | ConvertFrom-Json
            $bench.Positions[2].Serial | Should -BeNullOrEmpty
            $bench.Positions[1].Serial | Should -Be 'DEMO-BENCH-02'

            # Resume (Y); site 1; [1] Build Bench; remove the laptop from the bench by CI (record retained); [E]; [0].
            $global:AutopilotExpressRehearsalInput.Answers = @('Y', '1', '1', 'R', 'CI-BENCH-02', 'E', '0')
            $global:AutopilotExpressRehearsalInput.Index = 0
            & $entryPoint -Mode Demo
            $global:AutopilotExpressRehearsalInput.Index | Should -Be $global:AutopilotExpressRehearsalInput.Answers.Count
            $bench = Get-Content -LiteralPath $benchPath -Raw | ConvertFrom-Json
            @($bench.Positions | Where-Object { $_.Serial }).Count | Should -Be 0
            @(Get-Content -LiteralPath $recordPath -Raw | ConvertFrom-Json | ForEach-Object { $_ }).Count | Should -Be 2
            Test-Path -LiteralPath (Join-Path $rehearsalFolder 'data/autopilot-master-audit.json') | Should -BeFalse
        }
        finally {
            $env:PowerShellScriptingNewRoot = $previousRoot
            $env:AutopilotExpressDefinitionDirectory = $previousDefinitions
            $global:AutopilotExpressRehearsalInput = $previousInputState
        }
    }
}