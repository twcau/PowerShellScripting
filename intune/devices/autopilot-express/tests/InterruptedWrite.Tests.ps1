<#
.SYNOPSIS
    Validates recoverable single-file saves using isolated temporary storage.
.DESCRIPTION
    Extracts the actual writer. Faults are injected at staging, backup and promotion
    boundaries. No operational session data or tenant actions are used.
#>
BeforeAll {
    $sourcePath = Join-Path (Split-Path -Parent $PSScriptRoot) 'autopilot-express.ps1'
    $tokens = $null
    $parseErrors = $null
    $sourceAst = [System.Management.Automation.Language.Parser]::ParseFile($sourcePath, [ref]$tokens, [ref]$parseErrors)
    if ($parseErrors.Count) { throw ($parseErrors.Message -join '; ') }
    foreach ($functionName in @('New-ParentDirectory', 'Get-StorageFileEncoding', 'Write-Utf8File', 'Assert-FileWriteRecoveryState', 'Get-LocalCheckpointPath', 'Assert-LocalCheckpointState', 'Assert-LocalStorageWriteState', 'Copy-StateFileIfNeeded', 'Move-SessionFileToArchive', 'Reset-CurrentSessionState', 'Get-DefaultBuildBenchState')) {
        $definition = $sourceAst.Find({ param($node) $node -is [System.Management.Automation.Language.FunctionDefinitionAst] -and $node.Name -eq $functionName }, $true)
        if (-not $definition) { throw ('Missing function: {0}' -f $functionName) }
        Set-Item -Path ('Function:{0}' -f $definition.Name) -Value $definition.Body.GetScriptBlock()
    }
    function Write-AutopilotExpressLog { param($Message, $Level) throw ('Unexpected log: {0}, {1}' -f $Level, $Message) }
    function Get-ArchiveFolderPath {
        New-Item -ItemType Directory -Path $script:archiveRoot -Force | Out-Null
        return $script:archiveRoot
    }
    function Get-UserDataFilePath { return (Join-Path $script:stateRoot 'devices.json') }
    function Get-BuildBenchStatePath { return (Join-Path $script:stateRoot 'bench.json') }
    function Get-RecentUsersFilePath { return (Join-Path $script:stateRoot 'recent.json') }
    function Get-MasterAuditFilePath { return (Join-Path $script:stateRoot 'audit.json') }
    function Get-DataFolderPath { return $script:stateRoot }
}

Describe 'Recoverable file save' {
    BeforeEach {
        $script:path = Join-Path $TestDrive ('record-{0}.json' -f [guid]::NewGuid().Guid)
        $script:oldContent = '{"Serial":"OLD"}'
        $script:newContent = '{"Serial":"NEW"}'
        $script:archiveRoot = Join-Path $TestDrive ('archive-{0}' -f [guid]::NewGuid().Guid)
        $script:Runtime = @{ IsDemoMode = $true }
        Set-Content -LiteralPath $script:path -Value $script:oldContent -NoNewline
    }

    It 'promotes the full content and preserves the previous version' {
        Write-Utf8File -Path $script:path -Content $script:newContent
        Get-Content -LiteralPath $script:path -Raw | Should -BeExactly $script:newContent
        Get-Content -LiteralPath ('{0}.previous' -f $script:path) -Raw | Should -BeExactly $script:oldContent
        Test-Path -LiteralPath ('{0}.pending' -f $script:path) | Should -BeFalse
        Test-Path -LiteralPath ('{0}.write-in-progress' -f $script:path) | Should -BeFalse
    }

    It 'creates a first file without requiring a previous version' {
        Remove-Item -LiteralPath $script:path
        Write-Utf8File -Path $script:path -Content '[]'
        Get-Content -LiteralPath $script:path -Raw | Should -BeExactly '[]'
        Test-Path -LiteralPath ('{0}.previous' -f $script:path) | Should -BeFalse
    }

    It 'preserves the target when staging fails' {
        Mock Set-Content { throw 'Synthetic staging failure' }
        { Write-Utf8File -Path $script:path -Content $script:newContent } | Should -Throw '*staging failure*'
        Get-Content -LiteralPath $script:path -Raw | Should -BeExactly $script:oldContent
        Test-Path -LiteralPath ('{0}.write-in-progress' -f $script:path) | Should -BeTrue
    }

    It 'does not promote unreadable staged content' {
        Mock Get-Content { return 'different' } -ParameterFilter { $LiteralPath -like '*.pending' }
        Mock Move-Item {}
        { Write-Utf8File -Path $script:path -Content $script:newContent } | Should -Throw '*Staged save verification*'
        Get-Content -LiteralPath $script:path -Raw | Should -BeExactly $script:oldContent
        Should -Invoke Move-Item -Times 0 -Exactly
    }

    It 'preserves the target when backup creation fails' {
        Mock Copy-Item { throw 'Synthetic backup failure' }
        Mock Move-Item {}
        { Write-Utf8File -Path $script:path -Content $script:newContent } | Should -Throw '*backup failure*'
        Get-Content -LiteralPath $script:path -Raw | Should -BeExactly $script:oldContent
        Should -Invoke Move-Item -Times 0 -Exactly
    }

    It 'retains previous and pending content when promotion fails' {
        Mock Move-Item { throw 'Synthetic promotion failure' }
        { Write-Utf8File -Path $script:path -Content $script:newContent } | Should -Throw '*promotion failure*'
        Get-Content -LiteralPath ('{0}.previous' -f $script:path) -Raw | Should -BeExactly $script:oldContent
        Get-Content -LiteralPath ('{0}.pending' -f $script:path) -Raw | Should -BeExactly $script:newContent
        Test-Path -LiteralPath ('{0}.write-in-progress' -f $script:path) | Should -BeTrue
    }

    It 'does not overwrite an unresolved save marker' {
        New-Item -ItemType File -Path ('{0}.write-in-progress' -f $script:path) -Value 'interrupted' | Out-Null
        { Write-Utf8File -Path $script:path -Content $script:newContent } | Should -Throw '*Interrupted save recovery*'
        Get-Content -LiteralPath $script:path -Raw | Should -BeExactly $script:oldContent
    }

    It 'does not overwrite an orphaned pending file' {
        New-Item -ItemType File -Path ('{0}.pending' -f $script:path) -Value 'interrupted' | Out-Null
        { Write-Utf8File -Path $script:path -Content $script:newContent } | Should -Throw '*Interrupted save recovery*'
        Get-Content -LiteralPath ('{0}.pending' -f $script:path) -Raw | Should -BeExactly 'interrupted'
    }

    It 'retains the verified backup if promotion removes the target before failing' {
        Mock Move-Item { Remove-Item -LiteralPath $script:path; throw 'Synthetic target loss during promotion' }
        { Write-Utf8File -Path $script:path -Content $script:newContent } | Should -Throw '*target loss*'
        Test-Path -LiteralPath $script:path | Should -BeFalse
        Get-Content -LiteralPath ('{0}.previous' -f $script:path) -Raw | Should -BeExactly $script:oldContent
        { Assert-FileWriteRecoveryState -Path $script:path } | Should -Throw '*recovery is required*'
    }

    It 'retains the marker after the target changed but verification failed' {
        $script:targetReadCount = 0
        Mock Get-Content {
            $script:targetReadCount++
            if ($script:targetReadCount -eq 1) { return $script:oldContent }
            return 'different'
        } -ParameterFilter { $LiteralPath -eq $script:path }
        { Write-Utf8File -Path $script:path -Content $script:newContent } | Should -Throw '*Promoted save verification*'
        Test-Path -LiteralPath ('{0}.write-in-progress' -f $script:path) | Should -BeTrue
    }

    It 'blocks recovery even when only an orphaned pending file remains' {
        New-Item -ItemType File -Path ('{0}.pending' -f $script:path) -Value 'interrupted' | Out-Null
        { Assert-FileWriteRecoveryState -Path $script:path } | Should -Throw '*recovery is required*'
    }

    It 'accepts a completed previous-file backup without a marker' {
        Write-Utf8File -Path $script:path -Content $script:newContent
        { Assert-FileWriteRecoveryState -Path $script:path } | Should -Not -Throw
    }

    It 'does not migrate an interrupted source into a clean destination' {
        New-Item -ItemType File -Path ('{0}.pending' -f $script:path) -Value 'interrupted' | Out-Null
        $destination = Join-Path $TestDrive 'migration.json'
        { Copy-StateFileIfNeeded -SourcePath $script:path -DestinationPath $destination } | Should -Throw '*recovery is required*'
        Test-Path -LiteralPath $destination | Should -BeFalse
    }

    It 'propagates a migration save failure' {
        Mock Write-AutopilotExpressLog {}
        Mock Write-Utf8File { throw 'Synthetic migration write failure' }
        $destination = Join-Path $TestDrive 'failed-migration.json'
        { Copy-StateFileIfNeeded -SourcePath $script:path -DestinationPath $destination } | Should -Throw '*migration write failure*'
    }

    It 'does not promote an unverified previous-file backup' {
        Mock Get-Content { return 'different' } -ParameterFilter { $LiteralPath -like '*.previous' }
        Mock Move-Item {}
        { Write-Utf8File -Path $script:path -Content $script:newContent } | Should -Throw '*Previous-file verification*'
        Should -Invoke Move-Item -Times 0 -Exactly
        Get-Content -LiteralPath $script:path -Raw | Should -BeExactly $script:oldContent
    }

    It 'retains recovery evidence when marker cleanup fails' {
        Mock Remove-Item { throw 'Synthetic marker cleanup failure' } -ParameterFilter { $LiteralPath -like '*.write-in-progress' }
        { Write-Utf8File -Path $script:path -Content $script:newContent } | Should -Throw '*marker cleanup failure*'
        Get-Content -LiteralPath $script:path -Raw | Should -BeExactly $script:newContent
        { Assert-FileWriteRecoveryState -Path $script:path } | Should -Throw '*recovery is required*'
    }

    It 'blocks a missing target with a previous-file backup' {
        Write-Utf8File -Path $script:path -Content $script:newContent
        Remove-Item -LiteralPath $script:path
        { Assert-FileWriteRecoveryState -Path $script:path } | Should -Throw '*target is missing*'
        { Write-Utf8File -Path $script:path -Content '[]' } | Should -Throw '*target is missing*'
        Get-Content -LiteralPath ('{0}.previous' -f $script:path) -Raw | Should -BeExactly $script:oldContent
    }

    It 'archives the live and previous files together on an intentional reset' {
        Write-Utf8File -Path $script:path -Content $script:newContent
        Move-SessionFileToArchive -Path $script:path
        Test-Path -LiteralPath $script:path | Should -BeFalse
        Test-Path -LiteralPath ('{0}.previous' -f $script:path) | Should -BeFalse
        $archivedFiles = @(Get-ChildItem -LiteralPath $script:archiveRoot -File)
        $archivedFiles.Count | Should -Be 2
        $archivedContent = @($archivedFiles | ForEach-Object { Get-Content -LiteralPath $_.FullName -Raw })
        $archivedContent | Should -Contain $script:oldContent
        $archivedContent | Should -Contain $script:newContent
    }

    It 'saves and verifies both versions in a fresh constrained process' {
        $definitions = foreach ($functionName in @('New-ParentDirectory', 'Get-StorageFileEncoding', 'Write-Utf8File', 'Assert-FileWriteRecoveryState')) {
            $sourceAst.Find({ param($node) $node -is [System.Management.Automation.Language.FunctionDefinitionAst] -and $node.Name -eq $functionName }, $true).Extent.Text
        }
        $body = @(
            ('$path = ''{0}''' -f $script:path.Replace("'", "''"))
            ($definitions -join [Environment]::NewLine)
            'Write-Utf8File -Path $path -Content ''{"Serial":"NEW"}''; Assert-FileWriteRecoveryState -Path $path; if ((Get-Content -LiteralPath $path -Raw) -cne ''{"Serial":"NEW"}'') { throw "TARGET_MISMATCH" }; if ((Get-Content -LiteralPath (''{0}.previous'' -f $path) -Raw) -cne ''{"Serial":"OLD"}'') { throw "BACKUP_MISMATCH" }; Write-Output "CONSTRAINED_WRITE_PASS"'
        ) -join [Environment]::NewLine
        $bootstrap = '$ErrorActionPreference = ''Stop''; $body = [Text.Encoding]::Unicode.GetString([Convert]::FromBase64String(''{0}'')); $ExecutionContext.SessionState.LanguageMode = ''ConstrainedLanguage''; Invoke-Expression $body' -f [Convert]::ToBase64String([Text.Encoding]::Unicode.GetBytes($body))
        $output = $bootstrap | & powershell.exe -NoProfile -NonInteractive -Command - 2>&1
        $LASTEXITCODE | Should -Be 0
        $output | Should -Contain 'CONSTRAINED_WRITE_PASS'
    }

    It 'preserves an explicitly empty text payload' {
        Write-Utf8File -Path $script:path -Content ''
        $expectedBytes = if ($PSVersionTable.PSVersion.Major -ge 6) { 0 } else { 3 }
        (Get-Item -LiteralPath $script:path).Length | Should -Be $expectedBytes
        Test-Path -LiteralPath ('{0}.write-in-progress' -f $script:path) | Should -BeFalse
    }

    It 'round-trips non-ASCII text using UTF-8' {
        $content = 'Name: {0}' -f [char]0x00e9
        Write-Utf8File -Path $script:path -Content $content
        Get-Content -LiteralPath $script:path -Raw -Encoding UTF8 | Should -BeExactly $content
    }
}

Describe 'Mode-aware startup recovery checks' {
    BeforeEach {
        $script:stateRoot = Join-Path $TestDrive ([guid]::NewGuid().Guid)
        New-Item -ItemType Directory -Path $script:stateRoot | Out-Null
        $script:Runtime = @{ IsDemoMode = $false }
    }

    It 'blocks an interrupted <FileName> before startup' -TestCases @(
        @{ FileName = 'devices.json' }
        @{ FileName = 'bench.json' }
        @{ FileName = 'recent.json' }
        @{ FileName = 'audit.json' }
    ) {
        param($FileName)
        New-Item -ItemType File -Path (Join-Path $script:stateRoot ('{0}.write-in-progress' -f $FileName)) -Value 'interrupted' | Out-Null
        { Assert-LocalStorageWriteState } | Should -Throw '*recovery is required*'
    }

    It 'blocks an interrupted archive before any session reuse' {
        New-Item -ItemType File -Path ('{0}.archive-in-progress' -f (Get-UserDataFilePath)) -Value 'interrupted' | Out-Null
        { Assert-LocalStorageWriteState } | Should -Throw '*Interrupted session archive*recovery is required*'
    }

    It 'blocks fallback migration from a source with an interrupted archive' {
        $sourcePath = Get-UserDataFilePath
        $destinationPath = Join-Path $TestDrive 'archive-migration-target.json'
        New-Item -ItemType File -Path ('{0}.archive-in-progress' -f $sourcePath) -Value 'interrupted' | Out-Null
        { Copy-StateFileIfNeeded -SourcePath $sourcePath -DestinationPath $destinationPath } | Should -Throw '*Interrupted session archive*'
        Test-Path -LiteralPath $destinationPath | Should -BeFalse
    }

    It 'does not make Demo startup consume Live audit recovery state' {
        $script:Runtime.IsDemoMode = $true
        New-Item -ItemType File -Path (Join-Path $script:stateRoot 'audit.json.write-in-progress') -Value 'interrupted' | Out-Null
        { Assert-LocalStorageWriteState } | Should -Not -Throw
    }
}

Describe 'Current session archive file safety' {
    BeforeEach {
        $script:stateRoot = Join-Path $TestDrive ([guid]::NewGuid().Guid)
        $script:archiveRoot = Join-Path $TestDrive ([guid]::NewGuid().Guid)
        New-Item -ItemType Directory -Path $script:stateRoot | Out-Null
        $script:Runtime = @{ IsDemoMode = $true; Mode = 'Demo' }
        $script:BuildBench = @{ Active = $true }
        foreach ($fileName in @('devices.json', 'bench.json', 'devices.json.previous', 'bench.json.previous', 'recent.json', 'audit.json', 'sync-receipts.json', 'other-user.json', 'live-devices.json')) {
            New-Item -ItemType File -Path (Join-Path $script:stateRoot $fileName) -Value $fileName | Out-Null
        }
        Mock Write-AutopilotExpressLog {}
    }
    It 'archives current and previous pairs without touching other state' {
        $records = Reset-CurrentSessionState
        $records.Count | Should -Be 0
        $script:BuildBench.Active | Should -BeFalse
        @(Get-ChildItem -LiteralPath $script:archiveRoot -File).Count | Should -Be 4
        foreach ($fileName in @('recent.json', 'audit.json', 'sync-receipts.json', 'other-user.json', 'live-devices.json')) {
            Get-Content -LiteralPath (Join-Path $script:stateRoot $fileName) -Raw | Should -BeExactly $fileName
        }
        Test-Path -LiteralPath ('{0}.archive-in-progress' -f (Get-UserDataFilePath)) | Should -BeFalse
    }
    It 'leaves a blocking marker and active bench on partial move failure' {
        Mock Move-SessionFileToArchive { throw 'Synthetic second move failure' } -ParameterFilter { $Path -eq (Get-BuildBenchStatePath) }
        { Reset-CurrentSessionState } | Should -Throw '*second move failure*'
        $script:BuildBench.Active | Should -BeTrue
        Test-Path -LiteralPath ('{0}.archive-in-progress' -f (Get-UserDataFilePath)) | Should -BeTrue
        { Assert-LocalStorageWriteState } | Should -Throw '*Interrupted session archive*'
    }
    It 'does not overwrite an earlier archive when reset is repeated in the same second' {
        Mock Get-Date { return 'same-second' } -ParameterFilter { $Format -eq 'yyyyMMdd-HHmmss' }
        Reset-CurrentSessionState | Out-Null
        New-Item -ItemType File -Path (Get-UserDataFilePath) -Value 'second session' | Out-Null
        Reset-CurrentSessionState | Out-Null
        @(Get-ChildItem -LiteralPath $script:archiveRoot -File).Count | Should -Be 5
    }
}