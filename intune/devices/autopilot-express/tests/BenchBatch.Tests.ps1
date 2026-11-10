<#
.SYNOPSIS
    Checks the BENCH-BATCH selection parser and a confirmed sequential bench batch.
.DESCRIPTION
    Extracts only Resolve-BenchBatchSelection from the source AST for unit cases, then
    rehearses the real Demo entry point in Pester temporary storage: a descending range
    is refused, a declined batch changes nothing and a confirmed ALL batch prepares
    every occupied position in order while skipping empty positions. Only host prompts
    and screen clearing are mocked; no Graph or physical actions occur. Requires Pester 5.
.FILECREATED
    2026-10-09
.FILELASTUPDATED
    2026-10-09
#>
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidGlobalVars', '', Justification = 'The real entry point has a separate script scope. This uniquely named test-only prompt fixture crosses that boundary and is restored in finally; no product global is introduced.')]
param()

BeforeAll {
    $sourcePath = Join-Path (Split-Path -Parent $PSScriptRoot) 'autopilot-express.ps1'
    $tokens = $null
    $parseErrors = $null
    $sourceAst = [System.Management.Automation.Language.Parser]::ParseFile($sourcePath, [ref]$tokens, [ref]$parseErrors)
    if ($parseErrors.Count) { throw ($parseErrors.Message -join '; ') }
    $definition = $sourceAst.Find({ param($node) $node -is [System.Management.Automation.Language.FunctionDefinitionAst] -and $node.Name -eq 'Resolve-BenchBatchSelection' }, $true)
    if ($null -eq $definition) { throw 'Missing function: Resolve-BenchBatchSelection' }
    . ([scriptblock]::Create($definition.Extent.Text))
}

Describe 'Bench batch selection parser' {
    BeforeEach {
        # Positions 1, 3 and 4 are occupied; 2 and 5 to 8 are empty.
        $script:positions = @(1..8 | ForEach-Object { @{ Index = $_; Serial = ''; ConfigItem = '' } })
        $script:positions[0].Serial = 'AAAA'; $script:positions[0].ConfigItem = '900'
        $script:positions[2].Serial = '1-3'; $script:positions[2].ConfigItem = '901'
        $script:positions[3].Serial = 'DDDD'; $script:positions[3].ConfigItem = '2,4'
    }

    It 'expands lists, ascending ranges and spaces into unique ascending positions' {
        $result = Resolve-BenchBatchSelection -Positions $script:positions -Selection ' 7, 5-6 ,1,5 '
        $result.Error | Should -BeNullOrEmpty
        $result.Positions | Should -Be @(1, 5, 6, 7)
    }

    It 'selects every position for ALL in any letter case' {
        (Resolve-BenchBatchSelection -Positions $script:positions -Selection 'ALL').Positions | Should -Be @(1..8)
        (Resolve-BenchBatchSelection -Positions $script:positions -Selection 'all').Positions | Should -Be @(1..8)
    }

    It 'leaves single selections to the existing resolver' -TestCases @(
        @{ Selection = '3' }, @{ Selection = 'P:1,2' }, @{ Selection = 'S:AAAA' }, @{ Selection = 'CI:900' },
        @{ Selection = 'AAAA' }, @{ Selection = '' }, @{ Selection = '1;2' }, @{ Selection = '1,' }
    ) {
        Resolve-BenchBatchSelection -Positions $script:positions -Selection $Selection | Should -BeNullOrEmpty
    }

    It 'keeps exact serial or Configuration Item matches as single selections' {
        Resolve-BenchBatchSelection -Positions $script:positions -Selection '1-3' | Should -BeNullOrEmpty
        Resolve-BenchBatchSelection -Positions $script:positions -Selection '2,4' | Should -BeNullOrEmpty
    }

    It 'refuses descending ranges with a corrective example' {
        $result = Resolve-BenchBatchSelection -Positions $script:positions -Selection '7-5'
        $result.Error | Should -Be 'Range 7-5 must run from low to high, for example 5-7.'
        $result.Positions.Count | Should -Be 0
    }

    It 'refuses positions outside the bench, including oversized numbers' -TestCases @(
        @{ Selection = '1,9'; Bad = '9' }, @{ Selection = '0-2'; Bad = '0' }, @{ Selection = '1,99999999999'; Bad = '99999999999' }
    ) {
        $result = Resolve-BenchBatchSelection -Positions $script:positions -Selection $Selection
        $result.Error | Should -Be ('Position {0} is not a bench position (1-8).' -f $Bad)
    }
}

Describe 'Bench batch Demo rehearsal' {
    BeforeEach {
        $script:previousLocalAppData = [Environment]::GetEnvironmentVariable('LOCALAPPDATA', 'Process')
        $isolatedLocalAppData = Join-Path $TestDrive ('local-app-data-{0}' -f [guid]::NewGuid().Guid)
        New-Item -ItemType Directory -Path $isolatedLocalAppData -ErrorAction Stop | Out-Null
        [Environment]::SetEnvironmentVariable('LOCALAPPDATA', $isolatedLocalAppData, 'Process')
    }

    AfterEach {
        [Environment]::SetEnvironmentVariable('LOCALAPPDATA', $script:previousLocalAppData, 'Process')
    }

    It 'refuses bad syntax, honours a declined confirmation and prepares occupied positions in order' {
        $sourceFolder = Split-Path -Parent $PSScriptRoot
        $rehearsalFolder = Join-Path $TestDrive 'batch'
        New-Item -ItemType Directory -Path $rehearsalFolder | Out-Null
        foreach ($fileName in @('autopilot-express.ps1', 'autopilot-express.manifest.json', 'autopilot-express.runtime.json')) {
            Copy-Item -LiteralPath (Join-Path $sourceFolder $fileName) -Destination $rehearsalFolder
        }
        $entryPoint = Join-Path $rehearsalFolder 'autopilot-express.ps1'
        $dataFolder = Join-Path $rehearsalFolder 'data'
        $previousDefinitions = $env:AutopilotExpressDefinitionDirectory
        $previousInputState = $global:AutopilotExpressRehearsalInput
        $global:AutopilotExpressRehearsalInput = @{
            Answers = @(
                # Site 1 (MI); main menu [1] Build Bench; three positions; Desktop bench default.
                '1', '1', '3', 'Desktop',
                # Induct positions 1 and 3; position 2 stays empty.
                'I', '1', 'N', 'DEMO-BATCH-01', 'CI-BATCH-01', 'Desktop', 'Y',
                'I', '3', 'N', 'DEMO-BATCH-03', 'CI-BATCH-03', 'Laptop', 'Y',
                # Descending range refused; out-of-range list refused; 1-3 previewed then declined (N).
                'T', '3-1', 'T', '1,4', 'T', '1-3', 'N',
                # ALL previewed and confirmed (Y); [E] Main Menu; [0] exit.
                'T', 'ALL', 'Y', 'E', '0'
            )
            Index   = 0
        }
        Mock Read-Host {
            if ($global:AutopilotExpressRehearsalInput.Index -ge $global:AutopilotExpressRehearsalInput.Answers.Count) { throw ('Unexpected batch prompt: {0}' -f $Prompt) }
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
            Should -Invoke Write-Host -ParameterFilter { $Object -like '*Range 3-1 must run from low to high*No devices were selected.' }
            Should -Invoke Write-Host -ParameterFilter { $Object -like '*Position 4 is not a bench position (1-3). No devices were selected.' }
            Should -Invoke Write-Host -Times 2 -Exactly -ParameterFilter { $Object -eq 'Prepare (T) will run on 2 device(s), one at a time in position order:' }
            Should -Invoke Write-Host -Times 2 -Exactly -ParameterFilter { $Object -eq '  Empty positions skipped: 2' }
            Should -Invoke Write-Host -ParameterFilter { $Object -like '*Batch cancelled; no devices were changed.' }
            Should -Invoke Write-Host -ParameterFilter { $Object -like "Bench | batch T: Batch Prepare (T) finished for 2 device(s):*[[]1] DEMO-BATCH-01:*[[]3] DEMO-BATCH-03:*" }
            $deviceIndex = Get-Content -LiteralPath (Join-Path $dataFolder ('autopilot-session-demo-{0}.index.json' -f $env:USERNAME)) -Raw | ConvertFrom-Json
            $savedRecords = @(Get-Content -LiteralPath (Join-Path $dataFolder $deviceIndex.DeviceFile) -Raw | ConvertFrom-Json | ForEach-Object { $_ })
            $savedRecords.Count | Should -Be 2
            foreach ($record in $savedRecords) { $record.Steps.A.CompletionState | Should -Be 'Simulated' }
        }
        finally {
            $env:AutopilotExpressDefinitionDirectory = $previousDefinitions
            $global:AutopilotExpressRehearsalInput = $previousInputState
        }
    }
}