<#
.SYNOPSIS
    Tests guided recovery of a save checkpoint left behind by a crash.
.DESCRIPTION
    Uses real TestDrive files and the real recovery, backup and file-writer functions.
    Covers each state (checkpoint unfinished, nothing saved, all saved, partly saved)
    and every refusal: interrupted target writes, damaged checkpoint, wrong user,
    running session owner and missing -ConfirmStopped. No sign-in or tenant action.
#>
BeforeAll {
    $sourcePath = Join-Path (Split-Path -Parent $PSScriptRoot) 'autopilot-express.ps1'
    $tokens = $null
    $parseErrors = $null
    $sourceAst = [System.Management.Automation.Language.Parser]::ParseFile($sourcePath, [ref]$tokens, [ref]$parseErrors)
    if ($parseErrors.Count) { throw ($parseErrors.Message -join '; ') }
    foreach ($functionName in @('Invoke-LocalCheckpointRecovery', 'Invoke-LocalSessionLockRecovery', 'Get-LocalSessionOwnerState', 'New-LocalSessionRecoverySnapshot', 'Get-LocalSessionRecoveryInventory', 'Get-RecoveryEvidenceTenantKey', 'Get-RecoveryEvidenceFolder', 'Get-SessionFileIndex', 'Get-SessionFileIndexPath', 'Get-ModeUserDataFilePrefix', 'Get-ModeBuildBenchFilePrefix', 'ConvertTo-NormalisedValue', 'Assert-FileWriteRecoveryState', 'New-ParentDirectory', 'Get-StorageFileEncoding', 'Write-Utf8File')) {
        $definition = $sourceAst.Find({ param($node) $node -is [System.Management.Automation.Language.FunctionDefinitionAst] -and $node.Name -eq $functionName }, $true)
        if (-not $definition) { throw ('Missing function: {0}' -f $functionName) }
        Set-Item -Path ('Function:{0}' -f $definition.Name) -Value $definition.Body.GetScriptBlock()
    }
    function Write-AutopilotExpressLog { param($Message, $Level) $null = $Message, $Level }
    $script:Config = @{ DataFolderRelative = 'data'; UserDataFilePrefix = 'autopilot-devices'; DemoUserDataFilePrefix = 'autopilot-devices-demo'; BuildBenchFilePrefix = 'build-bench'; DemoBuildBenchFilePrefix = 'build-bench-demo'; MasterAuditFileName = 'autopilot-master-audit.json' }

    function New-CheckpointScenario {
        # Writes the previous good save, then a checkpoint proposing new content for every file.
        param([ValidateSet('Nothing', 'All', 'Records')][string]$AlreadySaved = 'Nothing')
        foreach ($name in $script:files.Keys) { Set-Content -LiteralPath $script:files[$name] -Value $script:old[$name] -NoNewline }
        $checkpoint = @{ SchemaVersion = 1; Token = [guid]::NewGuid().Guid; Root = $script:dataPath; User = $env:USERNAME; Mode = 'live'; StartedAt = (Get-Date -Format o)
            RecordsJson = $script:new.Records; AuditJson = $script:new.Audit; BenchJson = $script:new.Bench }
        Set-Content -LiteralPath $script:checkpointPath -Value ($checkpoint | ConvertTo-Json -Depth 8) -NoNewline
        $savedNames = switch ($AlreadySaved) { 'All' { @($script:files.Keys) } 'Records' { @('Records') } default { @() } }
        foreach ($name in $savedNames) { Set-Content -LiteralPath $script:files[$name] -Value $script:new[$name] -NoNewline }
    }
}

Describe 'Guided checkpoint recovery' {
    BeforeEach {
        $script:Runtime = @{ IsDemoMode = $true }
        $script:RuntimeConfig = $null
        $script:priorLocalAppData = $env:LOCALAPPDATA
        $env:LOCALAPPDATA = Join-Path $TestDrive ([guid]::NewGuid().Guid)
        $script:dataPath = Join-Path $TestDrive ([guid]::NewGuid().Guid)
        $null = New-Item -ItemType Directory -Path $script:dataPath
        $script:checkpointPath = Join-Path $script:dataPath ('autopilot-express-live-{0}.checkpoint.json' -f $env:USERNAME)
        $script:files = [ordered]@{
            Records = Join-Path $script:dataPath ('autopilot-devices-{0}.json' -f $env:USERNAME)
            Bench   = Join-Path $script:dataPath ('build-bench-{0}.json' -f $env:USERNAME)
            Audit   = Join-Path $script:dataPath 'autopilot-master-audit.json'
        }
        $script:old = @{ Records = '[{"Serial":"OLD"}]'; Bench = '{"Positions":[]}'; Audit = '[]' }
        $script:new = @{ Records = '[{"Serial":"NEW"}]'; Bench = '{"Positions":[1]}'; Audit = '[{"Serial":"NEW"}]' }
    }
    AfterEach { $env:LOCALAPPDATA = $script:priorLocalAppData }

    It 'inspects a <Saved> save as <State> without changing anything' -TestCases @(
        @{ Saved = 'Nothing'; State = 'NothingSaved' }
        @{ Saved = 'All'; State = 'AllSaved' }
        @{ Saved = 'Records'; State = 'PartlySaved' }
    ) {
        param($Saved, $State)
        New-CheckpointScenario -AlreadySaved $Saved
        $before = @($script:files.Values + $script:checkpointPath | ForEach-Object { (Get-FileHash -LiteralPath $_).Hash })
        $result = Invoke-LocalCheckpointRecovery -Path $script:checkpointPath
        $result.State | Should -BeExactly $State
        $result.Files.Count | Should -Be 3
        $result.Outcome | Should -BeLike 'Inspected only*'
        @($script:files.Values + $script:checkpointPath | ForEach-Object { (Get-FileHash -LiteralPath $_).Hash }) | Should -Be $before
        $script:Runtime.IsDemoMode | Should -BeTrue
    }

    It 'discards an unsaved proposal, keeping the previous good save and a verified backup' {
        New-CheckpointScenario -AlreadySaved Nothing
        $result = Invoke-LocalCheckpointRecovery -Path $script:checkpointPath -Resolve -ConfirmStopped -Confirm:$false
        $result.State | Should -BeExactly 'NothingSaved'
        Test-Path -LiteralPath $script:checkpointPath | Should -BeFalse
        foreach ($name in $script:files.Keys) { Get-Content -LiteralPath $script:files[$name] -Raw | Should -BeExactly $script:old[$name] }
        Test-Path -LiteralPath (Join-Path $result.BackupPath ('files\{0}' -f (Split-Path -Leaf $script:checkpointPath))) | Should -BeTrue
        Test-Path -LiteralPath (Join-Path $result.BackupPath 'manifest.json') | Should -BeTrue
    }

    It 'removes only the leftover checkpoint when every file was already saved' {
        New-CheckpointScenario -AlreadySaved All
        (Invoke-LocalCheckpointRecovery -Path $script:checkpointPath -Resolve -ConfirmStopped -Confirm:$false).State | Should -BeExactly 'AllSaved'
        Test-Path -LiteralPath $script:checkpointPath | Should -BeFalse
        foreach ($name in $script:files.Keys) { Get-Content -LiteralPath $script:files[$name] -Raw | Should -BeExactly $script:new[$name] }
    }

    It 'finishes a partly saved proposal so every file agrees' {
        New-CheckpointScenario -AlreadySaved Records
        (Invoke-LocalCheckpointRecovery -Path $script:checkpointPath -Resolve -ConfirmStopped -Confirm:$false).State | Should -BeExactly 'PartlySaved'
        Test-Path -LiteralPath $script:checkpointPath | Should -BeFalse
        foreach ($name in $script:files.Keys) {
            Get-Content -LiteralPath $script:files[$name] -Raw | Should -BeExactly $script:new[$name]
            Test-Path -LiteralPath ('{0}.write-in-progress' -f $script:files[$name]) | Should -BeFalse
        }
    }

    It 'clears an unfinished checkpoint write because no device file was touched' {
        foreach ($name in $script:files.Keys) { Set-Content -LiteralPath $script:files[$name] -Value $script:old[$name] -NoNewline }
        Set-Content -LiteralPath ('{0}.pending' -f $script:checkpointPath) -Value '{"partial'
        Set-Content -LiteralPath ('{0}.write-in-progress' -f $script:checkpointPath) -Value '{}'
        $result = Invoke-LocalCheckpointRecovery -Path $script:checkpointPath -Resolve -ConfirmStopped -Confirm:$false
        $result.State | Should -BeExactly 'CheckpointUnfinished'
        @(Get-ChildItem -LiteralPath $script:dataPath -Filter '*.checkpoint.json*').Count | Should -Be 0
        foreach ($name in $script:files.Keys) { Get-Content -LiteralPath $script:files[$name] -Raw | Should -BeExactly $script:old[$name] }
    }

    It 'treats a checkpoint whose marker removal failed as complete and compares it' {
        New-CheckpointScenario -AlreadySaved Nothing
        Set-Content -LiteralPath ('{0}.write-in-progress' -f $script:checkpointPath) -Value '{}'
        (Invoke-LocalCheckpointRecovery -Path $script:checkpointPath -Resolve -ConfirmStopped -Confirm:$false).State | Should -BeExactly 'NothingSaved'
        @(Get-ChildItem -LiteralPath $script:dataPath -Filter '*.checkpoint.json*').Count | Should -Be 0
    }

    It 'refuses <Case> and changes nothing' -TestCases @(
        @{ Case = 'an interrupted device-file write'; Expected = '*interrupted save*' }
        @{ Case = 'a damaged checkpoint'; Expected = '*checkpoint is damaged*' }
        @{ Case = 'resolve without -ConfirmStopped'; Expected = '*ConfirmStopped*' }
        @{ Case = 'a running session owner'; Expected = '*running or unverified owner*' }
    ) {
        param($Case, $Expected)
        New-CheckpointScenario -AlreadySaved Nothing
        switch ($Case) {
            'an interrupted device-file write' { Set-Content -LiteralPath ('{0}.write-in-progress' -f $script:files.Records) -Value '{}' }
            'a damaged checkpoint' { Set-Content -LiteralPath $script:checkpointPath -Value '{damaged' }
            'a running session owner' {
                $owner = @{ Token = 'live-token'; Computer = $env:COMPUTERNAME; User = $env:USERNAME; ProcessId = $PID; StartedAt = (Get-Date).AddDays(1).ToString('o') }
                Set-Content -LiteralPath (Join-Path $script:dataPath 'autopilot-express-live.session.lock') -Value ($owner | ConvertTo-Json)
            }
        }
        $before = (Get-FileHash -LiteralPath $script:checkpointPath).Hash
        { Invoke-LocalCheckpointRecovery -Path $script:checkpointPath -Resolve -ConfirmStopped:($Case -ne 'resolve without -ConfirmStopped') -Confirm:$false } | Should -Throw $Expected
        (Get-FileHash -LiteralPath $script:checkpointPath).Hash | Should -BeExactly $before
        Test-Path -LiteralPath $env:LOCALAPPDATA | Should -BeFalse
    }

    It 'refuses a checkpoint that belongs to another Windows user' {
        $foreign = Join-Path $script:dataPath 'autopilot-express-live-someoneelse.checkpoint.json'
        Set-Content -LiteralPath $foreign -Value '{}'
        { Invoke-LocalCheckpointRecovery -Path $foreign } | Should -Throw '*belongs to someoneelse*'
    }

    It 'refuses a path that is not a checkpoint' {
        { Invoke-LocalCheckpointRecovery -Path (Join-Path $script:dataPath 'autopilot-express-live.session.lock') } | Should -Throw '*exact autopilot-express*'
    }
}
