<#
.SYNOPSIS
    Checks stable storage authority and fail-closed migration in real TestDrive roots.
.DESCRIPTION
    Extracts production storage functions without starting the CLI. Root resolution,
    writability and logging are mocked; state, locks, markers and recovery artefacts
    are real isolated files. No operational storage or tenant actions are accessed.
#>
BeforeAll {
    $sourcePath = Join-Path (Split-Path -Parent $PSScriptRoot) 'autopilot-express.ps1'
    $tokens = $null
    $parseErrors = $null
    $sourceAst = [System.Management.Automation.Language.Parser]::ParseFile($sourcePath, [ref]$tokens, [ref]$parseErrors)
    if ($parseErrors.Count) { throw ($parseErrors.Message -join '; ') }
    foreach ($functionName in @(
            'Get-RepoStorageBasePath', 'Get-FallbackStorageBasePath', 'Test-DirectoryWritable',
            'Assert-StorageModeSupported', 'Get-OperationalStoragePath', 'Get-FallbackStorageAuthorityPath',
            'Test-FallbackStorageAuthority', 'Assert-ActiveStorageReservation', 'Initialize-StorageLocation',
            'Get-StorageBasePath', 'Get-DataFolderPath', 'Start-LocalSessionLock', 'Stop-LocalSessionLock',
            'New-ParentDirectory', 'Get-StorageFileEncoding', 'Write-Utf8File', 'Assert-FileWriteRecoveryState',
            'Get-LocalCheckpointPath', 'Assert-LocalCheckpointState',
            'Copy-StateFileIfNeeded', 'Get-ModeUserDataFilePrefix', 'Get-ModeRecentUsersFilePrefix',
            'Get-ModeBuildBenchFilePrefix', 'Get-UserDataFilePath', 'Get-BuildBenchStatePath',
            'Get-RecentUsersFilePath', 'Get-MasterAuditFilePath', 'Sync-RepoStateFilesToActiveStorage'
        )) {
        $definition = $sourceAst.Find({ param($node) $node -is [System.Management.Automation.Language.FunctionDefinitionAst] -and $node.Name -eq $functionName }, $true)
        if (-not $definition) { throw ('Missing function: {0}' -f $functionName) }
        Set-Item -Path ('Function:{0}' -f $definition.Name) -Value $definition.Body.GetScriptBlock()
    }
    function Write-AutopilotExpressLog { param($Message, $Level) throw ('Unexpected log: {0}, {1}' -f $Level, $Message) }
}

Describe 'Stable authoritative storage roots' {
    BeforeEach {
        $script:repoRoot = Join-Path $TestDrive ('repo-{0}' -f [guid]::NewGuid().Guid)
        $script:fallbackRoot = Join-Path $TestDrive ('fallback-{0}' -f [guid]::NewGuid().Guid)
        $script:Config = @{
            DataFolderRelative = 'data'
            UserDataFilePrefix = 'autopilot-devices'; DemoUserDataFilePrefix = 'autopilot-devices-demo'
            BuildBenchFilePrefix = 'build-bench'; DemoBuildBenchFilePrefix = 'build-bench-demo'
            RecentUsersFilePrefix = 'autopilot-recent-users'; DemoRecentUsersFilePrefix = 'autopilot-recent-users-demo'
            MasterAuditFileName = 'autopilot-master-audit.json'
        }
        $script:Runtime = @{ IsDemoMode = $false }
        $script:RuntimeConfig = @{ storage = @{ mode = 'Local' } }
        $script:Storage = @{ Initialised = $false; BasePath = $null; DataPath = $null; UsingFallback = $false }
        $script:localSessionLock = $null
        $script:repoData = Join-Path $script:repoRoot 'data'
        $script:fallbackData = Join-Path $script:fallbackRoot 'data'
        New-Item -ItemType Directory -Path $script:repoData, $script:fallbackData | Out-Null
        Mock Get-RepoStorageBasePath { return $script:repoRoot }
        Mock Get-FallbackStorageBasePath { return $script:fallbackRoot }
        Mock Test-DirectoryWritable { return $true }
        Mock Write-AutopilotExpressLog {}
        $script:repoPaths = @(Get-OperationalStoragePath -BasePath $script:repoRoot)
        $script:fallbackPaths = @(Get-OperationalStoragePath -BasePath $script:fallbackRoot)
        $script:authorityPath = Get-FallbackStorageAuthorityPath -BasePath $script:fallbackRoot
    }

    AfterEach {
        if ($script:localSessionLock -and $script:localSessionLock.Handle) { $script:localSessionLock.Handle.Dispose() }
    }

    It 'uses the writable repository when fallback has no operational evidence' {
        Initialize-StorageLocation
        $script:Storage.BasePath | Should -Be $script:repoRoot
        $script:Storage.UsingFallback | Should -BeFalse
        Should -Invoke Test-DirectoryWritable -Times 0 -Exactly -ParameterFilter { $Path -eq $script:fallbackData }
    }

    It 'rejects a marker-only fallback before probing the writable repository or reserving a root' {
        $checkpointPath = Get-LocalCheckpointPath -BasePath $script:fallbackRoot
        Set-Content -LiteralPath $checkpointPath -Value '{"Root":"original-root","RecordsJson":"[]"}' -NoNewline
        { Start-LocalSessionLock } | Should -Throw '*Unresolved local checkpoint*'
        $script:Storage.Initialised | Should -BeFalse
        Should -Invoke Test-DirectoryWritable -Times 0 -Exactly
        Get-Content -LiteralPath $checkpointPath -Raw | Should -BeExactly '{"Root":"original-root","RecordsJson":"[]"}'
        @(Get-ChildItem -LiteralPath $script:repoData -Force).Count | Should -Be 0
        @(Get-ChildItem -LiteralPath $script:fallbackData -Force).Count | Should -Be 1
    }

    It 'rejects <Root> checkpoint <Suffix> before root selection with fallback preference <Preference>' -TestCases @(
        foreach ($root in @('repo', 'fallback')) {
            foreach ($suffix in @('', '.pending', '.previous', '.write-in-progress')) {
                foreach ($preference in @('none', 'state', 'authority')) {
                    @{ Root = $root; Suffix = $suffix; Preference = $preference }
                }
            }
        }
    ) {
        param($Root, $Suffix, $Preference)
        if ($Preference -eq 'state') {
            Set-Content -LiteralPath $script:fallbackPaths[0] -Value 'fallback-state' -NoNewline
        }
        elseif ($Preference -eq 'authority') {
            $authority = 'AutopilotExpressFallbackAuthority/1|live|{0}|{1}' -f $env:USERNAME, $script:fallbackData
            Set-Content -LiteralPath $script:authorityPath -Value $authority -NoNewline
        }
        $basePath = if ($Root -eq 'repo') { $script:repoRoot } else { $script:fallbackRoot }
        $checkpointPath = Get-LocalCheckpointPath -BasePath $basePath
        $proposal = @{ SchemaVersion = 1; Root = (Join-Path $basePath 'data'); Mode = 'live'; User = $env:USERNAME; Token = 'synthetic'; RecordsJson = '[]' } | ConvertTo-Json -Compress
        $evidencePath = '{0}{1}' -f $checkpointPath, $Suffix
        Set-Content -LiteralPath $evidencePath -Value $proposal -NoNewline
        $before = @(Get-ChildItem -LiteralPath $script:repoData, $script:fallbackData -Recurse -File -Force | Sort-Object FullName | ForEach-Object { '{0}|{1}' -f $_.FullName, (Get-FileHash -LiteralPath $_.FullName).Hash }) -join ';'
        Mock Write-Utf8File { throw 'Unexpected write' }
        Mock Copy-StateFileIfNeeded { throw 'Unexpected migration' }
        Mock New-Item { throw 'Unexpected directory or reservation' }
        $expectedError = if ($Suffix) { '*recovery is required*' } else { '*Unresolved local checkpoint*' }
        { Start-LocalSessionLock } | Should -Throw $expectedError
        $script:Storage.Initialised | Should -BeFalse
        Should -Invoke Test-DirectoryWritable -Times 0 -Exactly
        Should -Invoke Write-Utf8File -Times 0 -Exactly
        Should -Invoke Copy-StateFileIfNeeded -Times 0 -Exactly
        Should -Invoke New-Item -Times 0 -Exactly
        $after = @(Get-ChildItem -LiteralPath $script:repoData, $script:fallbackData -Recurse -File -Force | Sort-Object FullName | ForEach-Object { '{0}|{1}' -f $_.FullName, (Get-FileHash -LiteralPath $_.FullName).Hash }) -join ';'
        $after | Should -BeExactly $before
        Get-Content -LiteralPath $evidencePath -Raw | Should -BeExactly $proposal
        if ($Suffix) { Test-Path -LiteralPath $checkpointPath | Should -BeFalse }
        @(Get-OperationalStoragePath -BasePath $basePath) | Should -Not -Contain $checkpointPath
    }

    It 'rejects late <Root> checkpoint <Suffix> before migration even with authority <Authority>' -TestCases @(
        foreach ($root in @('repo', 'fallback')) {
            foreach ($suffix in @('', '.pending', '.previous', '.write-in-progress')) {
                foreach ($authority in @($false, $true)) {
                    @{ Root = $root; Suffix = $suffix; Authority = $authority }
                }
            }
        }
    ) {
        param($Root, $Suffix, $Authority)
        Set-Content -LiteralPath $script:repoPaths[0] -Value 'source-devices' -NoNewline
        Set-Content -LiteralPath (Join-Path $script:repoData 'sync-submission-record.json') -Value 'source-receipt' -NoNewline
        Mock Test-DirectoryWritable { return $false } -ParameterFilter { $Path -eq $script:repoData }
        $script:localSessionLock = Start-LocalSessionLock
        if ($Authority) {
            $marker = 'AutopilotExpressFallbackAuthority/1|live|{0}|{1}' -f $env:USERNAME, $script:fallbackData
            Set-Content -LiteralPath $script:authorityPath -Value $marker -NoNewline
        }
        $basePath = if ($Root -eq 'repo') { $script:repoRoot } else { $script:fallbackRoot }
        $checkpointPath = Get-LocalCheckpointPath -BasePath $basePath
        $evidencePath = '{0}{1}' -f $checkpointPath, $Suffix
        Set-Content -LiteralPath $evidencePath -Value 'unfinished-checkpoint' -NoNewline
        $before = @(Get-ChildItem -LiteralPath $script:repoData, $script:fallbackData -Recurse -File -Force | Where-Object FullName -ne ($script:localSessionLock.Path + '.lease') | Sort-Object FullName | ForEach-Object { '{0}|{1}' -f $_.FullName, (Get-FileHash -LiteralPath $_.FullName).Hash }) -join ';'
        Mock Write-Utf8File { throw 'Unexpected write' }
        Mock Copy-StateFileIfNeeded { throw 'Unexpected migration' }
        $expectedError = if ($Suffix) { '*recovery is required*' } else { '*Unresolved local checkpoint*' }
        { Sync-RepoStateFilesToActiveStorage } | Should -Throw $expectedError
        Should -Invoke Write-Utf8File -Times 0 -Exactly
        Should -Invoke Copy-StateFileIfNeeded -Times 0 -Exactly
        $after = @(Get-ChildItem -LiteralPath $script:repoData, $script:fallbackData -Recurse -File -Force | Where-Object FullName -ne ($script:localSessionLock.Path + '.lease') | Sort-Object FullName | ForEach-Object { '{0}|{1}' -f $_.FullName, (Get-FileHash -LiteralPath $_.FullName).Hash }) -join ';'
        $after | Should -BeExactly $before
        Test-Path -LiteralPath $script:fallbackPaths[0] | Should -BeFalse
        Test-Path -LiteralPath (Join-Path $script:fallbackData 'sync-submission-record.json') | Should -BeFalse
        Test-Path -LiteralPath $script:authorityPath | Should -Be $Authority
    }

    It 'inspects both absent roots without creating directories during checkpoint preflight' {
        Remove-Item -LiteralPath $script:repoData, $script:fallbackData
        foreach ($basePath in @($script:repoRoot, $script:fallbackRoot)) {
            { Assert-LocalCheckpointState -BasePath $basePath } | Should -Not -Throw
            Test-Path -LiteralPath (Join-Path $basePath 'data') | Should -BeFalse
        }
        $script:Storage.Initialised | Should -BeFalse
        Should -Invoke Test-DirectoryWritable -Times 0 -Exactly
    }

    It 'isolates current mode Demo=<Demo> from opposite-mode checkpoint evidence in both roots' -TestCases @(
        @{ Demo = $true }; @{ Demo = $false }
    ) {
        param($Demo)
        $script:Runtime.IsDemoMode = -not $Demo
        $oppositePaths = @()
        foreach ($basePath in @($script:repoRoot, $script:fallbackRoot)) {
            $checkpointPath = Get-LocalCheckpointPath -BasePath $basePath
            foreach ($suffix in @('', '.pending', '.previous', '.write-in-progress')) {
                $path = '{0}{1}' -f $checkpointPath, $suffix
                Set-Content -LiteralPath $path -Value 'opposite-mode-evidence' -NoNewline
                $oppositePaths += $path
            }
        }
        $before = @($oppositePaths | ForEach-Object { (Get-FileHash -LiteralPath $_).Hash }) -join ';'
        $script:Runtime.IsDemoMode = $Demo
        Initialize-StorageLocation
        $script:Storage.BasePath | Should -Be $script:repoRoot
        $currentRepoPaths = @(Get-OperationalStoragePath -BasePath $script:repoRoot)
        Set-Content -LiteralPath $currentRepoPaths[0] -Value 'current-mode-devices' -NoNewline
        $script:Storage.Initialised = $false
        Mock Test-DirectoryWritable { return $false } -ParameterFilter { $Path -eq $script:repoData }
        $script:localSessionLock = Start-LocalSessionLock
        { Sync-RepoStateFilesToActiveStorage } | Should -Not -Throw
        Test-FallbackStorageAuthority -BasePath $script:fallbackRoot | Should -BeTrue
        $currentFallbackPaths = @(Get-OperationalStoragePath -BasePath $script:fallbackRoot)
        Get-Content -LiteralPath $currentFallbackPaths[0] -Raw | Should -BeExactly 'current-mode-devices'
        Test-Path -LiteralPath (Get-LocalCheckpointPath -BasePath $script:fallbackRoot) | Should -BeFalse
        (@($oppositePaths | ForEach-Object { (Get-FileHash -LiteralPath $_).Hash }) -join ';') | Should -BeExactly $before
        foreach ($path in $oppositePaths) { Get-Content -LiteralPath $path -Raw | Should -BeExactly 'opposite-mode-evidence' }
    }

    It 'prefers fallback containing operational file <Index> even when the repository is writable' -TestCases @(
        @{ Index = 0 }; @{ Index = 1 }; @{ Index = 2 }; @{ Index = 3 }
    ) {
        param($Index)
        Set-Content -LiteralPath $script:fallbackPaths[$Index] -Value '[]' -NoNewline
        Initialize-StorageLocation
        $script:Storage.BasePath | Should -Be $script:fallbackRoot
        Should -Invoke Test-DirectoryWritable -Times 0 -Exactly -ParameterFilter { $Path -eq $script:repoData }
    }

    It 'selects repository without creating an absent fallback directory' {
        Remove-Item -LiteralPath $script:fallbackData
        Initialize-StorageLocation
        $script:Storage.BasePath | Should -Be $script:repoRoot
        Test-Path -LiteralPath $script:fallbackData | Should -BeFalse
    }

    It 'does not switch to stale repository state when authoritative fallback is unwritable' {
        Set-Content -LiteralPath $script:fallbackPaths[0] -Value 'fallback-state' -NoNewline
        Mock Test-DirectoryWritable { return $false } -ParameterFilter { $Path -eq $script:fallbackData }
        { Initialize-StorageLocation } | Should -Throw '*could not find a writable storage location*'
        $script:Storage.Initialised | Should -BeFalse
        Get-Content -LiteralPath $script:fallbackPaths[0] -Raw | Should -BeExactly 'fallback-state'
        Should -Invoke Test-DirectoryWritable -Times 0 -Exactly -ParameterFilter { $Path -eq $script:repoData }
    }

    It 'migrates all Live files then keeps fallback authoritative after restart and legitimate updates' {
        for ($index = 0; $index -lt $script:repoPaths.Count; $index++) {
            Set-Content -LiteralPath $script:repoPaths[$index] -Value ('state-{0}' -f $index) -NoNewline
        }
        Mock Test-DirectoryWritable { return $false } -ParameterFilter { $Path -eq $script:repoData }
        $script:localSessionLock = Start-LocalSessionLock
        Sync-RepoStateFilesToActiveStorage
        Test-FallbackStorageAuthority -BasePath $script:fallbackRoot | Should -BeTrue
        for ($index = 0; $index -lt $script:repoPaths.Count; $index++) {
            Get-Content -LiteralPath $script:fallbackPaths[$index] -Raw | Should -BeExactly ('state-{0}' -f $index)
            Get-Content -LiteralPath $script:repoPaths[$index] -Raw | Should -BeExactly ('state-{0}' -f $index)
            Write-Utf8File -Path $script:fallbackPaths[$index] -Content ('updated-{0}' -f $index)
        }
        Stop-LocalSessionLock -Lock $script:localSessionLock
        $script:Storage.Initialised = $false
        Mock Test-DirectoryWritable { return $true }
        $script:localSessionLock = Start-LocalSessionLock
        { Sync-RepoStateFilesToActiveStorage } | Should -Not -Throw
        $script:Storage.BasePath | Should -Be $script:fallbackRoot
        for ($index = 0; $index -lt $script:fallbackPaths.Count; $index++) {
            Get-Content -LiteralPath $script:fallbackPaths[$index] -Raw | Should -BeExactly ('updated-{0}' -f $index)
        }
    }

    It 'keeps marker authority when operational state was intentionally archived' {
        Mock Test-DirectoryWritable { return $false } -ParameterFilter { $Path -eq $script:repoData }
        $script:localSessionLock = Start-LocalSessionLock
        Sync-RepoStateFilesToActiveStorage
        Stop-LocalSessionLock -Lock $script:localSessionLock
        Set-Content -LiteralPath $script:repoPaths[0] -Value 'stale-ancestor' -NoNewline
        $script:Storage.Initialised = $false
        Mock Test-DirectoryWritable { return $true }
        $script:localSessionLock = Start-LocalSessionLock
        Sync-RepoStateFilesToActiveStorage
        $script:Storage.BasePath | Should -Be $script:fallbackRoot
        Test-Path -LiteralPath $script:fallbackPaths[0] | Should -BeFalse
    }

    It 'rejects a late-file conflict before copying any earlier file regardless of timestamps' {
        Set-Content -LiteralPath $script:repoPaths[0] -Value 'repo-devices' -NoNewline
        Set-Content -LiteralPath $script:repoPaths[3] -Value 'AUDIT' -NoNewline
        Set-Content -LiteralPath $script:fallbackPaths[3] -Value 'audit' -NoNewline
        (Get-Item -LiteralPath $script:repoPaths[3]).LastWriteTimeUtc = [datetime]'2020-01-01'
        (Get-Item -LiteralPath $script:fallbackPaths[3]).LastWriteTimeUtc = [datetime]'2030-01-01'
        $script:localSessionLock = Start-LocalSessionLock
        { Sync-RepoStateFilesToActiveStorage } | Should -Throw '*Conflicting storage copies*'
        Test-Path -LiteralPath $script:fallbackPaths[0] | Should -BeFalse
        Test-Path -LiteralPath $script:authorityPath | Should -BeFalse
        Get-Content -LiteralPath $script:repoPaths[3] -Raw | Should -BeExactly 'AUDIT'
        Get-Content -LiteralPath $script:fallbackPaths[3] -Raw | Should -BeExactly 'audit'
    }

    It 'accepts exact copies without overwriting them and establishes authority' {
        Set-Content -LiteralPath $script:repoPaths[0] -Value 'same-content' -NoNewline
        Set-Content -LiteralPath $script:fallbackPaths[0] -Value 'same-content' -NoNewline
        $script:localSessionLock = Start-LocalSessionLock
        Sync-RepoStateFilesToActiveStorage
        Test-FallbackStorageAuthority -BasePath $script:fallbackRoot | Should -BeTrue
        Test-Path -LiteralPath ('{0}.previous' -f $script:fallbackPaths[0]) | Should -BeFalse
        Get-Content -LiteralPath $script:repoPaths[0] -Raw | Should -BeExactly 'same-content'
    }

    It 'establishes authority for fallback-only state without creating repository state' {
        Set-Content -LiteralPath $script:fallbackPaths[0] -Value 'fallback-only' -NoNewline
        $script:localSessionLock = Start-LocalSessionLock
        Sync-RepoStateFilesToActiveStorage
        Test-FallbackStorageAuthority -BasePath $script:fallbackRoot | Should -BeTrue
        Get-Content -LiteralPath $script:fallbackPaths[0] -Raw | Should -BeExactly 'fallback-only'
        Test-Path -LiteralPath $script:repoPaths[0] | Should -BeFalse
    }

    It 'does not migrate or create authority without a current-root reservation' {
        Set-Content -LiteralPath $script:repoPaths[0] -Value 'source' -NoNewline
        Mock Test-DirectoryWritable { return $false } -ParameterFilter { $Path -eq $script:repoData }
        Initialize-StorageLocation
        { Sync-RepoStateFilesToActiveStorage } | Should -Throw '*current-root session reservation*'
        Test-Path -LiteralPath $script:fallbackPaths[0] | Should -BeFalse
        Test-Path -LiteralPath $script:authorityPath | Should -BeFalse
    }

    It 'rejects a lock belonging to another root' {
        Set-Content -LiteralPath $script:fallbackPaths[0] -Value 'fallback-only' -NoNewline
        $script:localSessionLock = Start-LocalSessionLock
        $script:localSessionLock.Path = Join-Path $script:repoData 'autopilot-express-live.session.lock'
        { Sync-RepoStateFilesToActiveStorage } | Should -Throw '*current-root session reservation*'
        Test-Path -LiteralPath $script:authorityPath | Should -BeFalse
    }

    It 'rechecks reservation ownership before writing authority after migration' {
        Set-Content -LiteralPath $script:repoPaths[0] -Value 'source' -NoNewline
        Mock Test-DirectoryWritable { return $false } -ParameterFilter { $Path -eq $script:repoData }
        $script:localSessionLock = Start-LocalSessionLock
        Mock Write-AutopilotExpressLog {
            Set-Content -LiteralPath $script:localSessionLock.Path -Value '{"Token":"replacement","ProcessId":0}' -NoNewline
        } -ParameterFilter { $Message -like 'Migrated Autopilot Express state*' }
        { Sync-RepoStateFilesToActiveStorage } | Should -Throw '*reservation ownership changed*'
        Get-Content -LiteralPath $script:fallbackPaths[0] -Raw | Should -BeExactly 'source'
        Test-Path -LiteralPath $script:authorityPath | Should -BeFalse
    }

    It 'rejects malformed authority without probing writability or changing state' {
        Set-Content -LiteralPath $script:authorityPath -Value 'invalid-marker' -NoNewline
        { Initialize-StorageLocation } | Should -Throw '*Invalid fallback storage authority*'
        Get-Content -LiteralPath $script:authorityPath -Raw | Should -BeExactly 'invalid-marker'
        Should -Invoke Test-DirectoryWritable -Times 0 -Exactly
    }

    It 'rejects a valid marker moved from another fallback root' {
        Mock Test-DirectoryWritable { return $false } -ParameterFilter { $Path -eq $script:repoData }
        $script:localSessionLock = Start-LocalSessionLock
        Sync-RepoStateFilesToActiveStorage
        $marker = Get-Content -LiteralPath $script:authorityPath -Raw
        $otherRoot = Join-Path $TestDrive 'other-root'
        New-Item -ItemType Directory -Path (Join-Path $otherRoot 'data') | Out-Null
        $otherPath = Get-FallbackStorageAuthorityPath -BasePath $otherRoot
        Set-Content -LiteralPath $otherPath -Value $marker -NoNewline
        { Test-FallbackStorageAuthority -BasePath $otherRoot } | Should -Throw '*Invalid fallback storage authority*'
        Get-Content -LiteralPath $otherPath -Raw | Should -BeExactly $marker
    }

    It 'preserves authority recovery evidence <Suffix> before any root probe' -TestCases @(
        @{ Suffix = '.pending' }; @{ Suffix = '.write-in-progress' }; @{ Suffix = '.previous' }
    ) {
        param($Suffix)
        $evidencePath = '{0}{1}' -f $script:authorityPath, $Suffix
        Set-Content -LiteralPath $evidencePath -Value 'marker-recovery-evidence' -NoNewline
        { Initialize-StorageLocation } | Should -Throw '*recovery is required*'
        Get-Content -LiteralPath $evidencePath -Raw | Should -BeExactly 'marker-recovery-evidence'
        Test-Path -LiteralPath $script:authorityPath | Should -BeFalse
        Should -Invoke Test-DirectoryWritable -Times 0 -Exactly
    }

    It 'does not claim authority after a failed copy and can resume after operator recovery' {
        Set-Content -LiteralPath $script:repoPaths[0] -Value 'source' -NoNewline
        Mock Test-DirectoryWritable { return $false } -ParameterFilter { $Path -eq $script:repoData }
        $script:localSessionLock = Start-LocalSessionLock
        Mock Move-Item { throw 'Synthetic migration promotion failure' } -ParameterFilter { $LiteralPath -eq ('{0}.pending' -f $script:fallbackPaths[0]) }
        { Sync-RepoStateFilesToActiveStorage } | Should -Throw '*promotion failure*'
        Test-Path -LiteralPath $script:authorityPath | Should -BeFalse
        Get-Content -LiteralPath $script:repoPaths[0] -Raw | Should -BeExactly 'source'
        Get-Content -LiteralPath ('{0}.pending' -f $script:fallbackPaths[0]) -Raw | Should -BeExactly 'source'
        { Sync-RepoStateFilesToActiveStorage } | Should -Throw '*recovery is required*'
        Rename-Item -LiteralPath ('{0}.pending' -f $script:fallbackPaths[0]) -NewName (Split-Path -Leaf $script:fallbackPaths[0])
        Remove-Item -LiteralPath ('{0}.write-in-progress' -f $script:fallbackPaths[0])
        { Sync-RepoStateFilesToActiveStorage } | Should -Not -Throw
        Test-FallbackStorageAuthority -BasePath $script:fallbackRoot | Should -BeTrue
    }

    It 'retains an interrupted authority save and blocks restart without replacing evidence' {
        Mock Test-DirectoryWritable { return $false } -ParameterFilter { $Path -eq $script:repoData }
        $script:localSessionLock = Start-LocalSessionLock
        Mock Move-Item { throw 'Synthetic authority promotion failure' } -ParameterFilter { $LiteralPath -eq ('{0}.pending' -f $script:authorityPath) }
        { Sync-RepoStateFilesToActiveStorage } | Should -Throw '*authority promotion failure*'
        Test-Path -LiteralPath $script:authorityPath | Should -BeFalse
        $pending = Get-Content -LiteralPath ('{0}.pending' -f $script:authorityPath) -Raw
        Stop-LocalSessionLock -Lock $script:localSessionLock
        $script:Storage.Initialised = $false
        { Initialize-StorageLocation } | Should -Throw '*recovery is required*'
        Get-Content -LiteralPath ('{0}.pending' -f $script:authorityPath) -Raw | Should -BeExactly $pending
        Test-Path -LiteralPath ('{0}.write-in-progress' -f $script:authorityPath) | Should -BeTrue
    }

    It 'checks active recovery evidence after authority but ignores stale repository artefacts' {
        Mock Test-DirectoryWritable { return $false } -ParameterFilter { $Path -eq $script:repoData }
        $script:localSessionLock = Start-LocalSessionLock
        Sync-RepoStateFilesToActiveStorage
        Set-Content -LiteralPath ('{0}.pending' -f $script:repoPaths[0]) -Value 'stale-source-evidence' -NoNewline
        { Sync-RepoStateFilesToActiveStorage } | Should -Not -Throw
        Set-Content -LiteralPath ('{0}.pending' -f $script:fallbackPaths[0]) -Value 'active-evidence' -NoNewline
        { Sync-RepoStateFilesToActiveStorage } | Should -Throw '*recovery is required*'
        Get-Content -LiteralPath ('{0}.pending' -f $script:fallbackPaths[0]) -Raw | Should -BeExactly 'active-evidence'
    }

    It 'isolates Demo authority and paths from Live state and audit' {
        $script:Runtime.IsDemoMode = $true
        Set-Content -LiteralPath $script:fallbackPaths[0] -Value 'live-only' -NoNewline
        Set-Content -LiteralPath ('{0}.pending' -f $script:repoPaths[3]) -Value 'live-audit-evidence' -NoNewline
        Initialize-StorageLocation
        $script:Storage.BasePath | Should -Be $script:repoRoot
        $demoPaths = @(Get-OperationalStoragePath -BasePath $script:repoRoot)
        $demoPaths.Count | Should -Be 4
        $demoPaths | Should -Contain (Join-Path $script:repoData ('autopilot-work-pattern-demo-{0}.json' -f $env:USERNAME))
        $demoPaths | Should -Not -Contain (Join-Path $script:repoData ('autopilot-work-pattern-live-{0}.json' -f $env:USERNAME))
        Set-Content -LiteralPath $demoPaths[0] -Value 'demo-state' -NoNewline
        $script:Storage.Initialised = $false
        Mock Test-DirectoryWritable { return $false } -ParameterFilter { $Path -eq $script:repoData }
        $script:localSessionLock = Start-LocalSessionLock
        Sync-RepoStateFilesToActiveStorage
        Test-FallbackStorageAuthority -BasePath $script:fallbackRoot | Should -BeTrue
        Get-Content -LiteralPath $script:fallbackPaths[0] -Raw | Should -BeExactly 'live-only'
        $script:Runtime.IsDemoMode = $false
        Test-FallbackStorageAuthority -BasePath $script:fallbackRoot | Should -BeFalse
    }

    It 'keeps <Prefix> receipt-only fallback authoritative when writable is <Writable>' -TestCases @(
        foreach ($prefix in @('sync-submission', 'autopilot-import-submission')) {
            @{ Writable = $true; Prefix = $prefix }; @{ Writable = $false; Prefix = $prefix }
        }
    ) {
        param($Writable, $Prefix)
        $receiptPath = Join-Path $script:fallbackData ('{0}-other-user-record.json' -f $Prefix)
        Set-Content -LiteralPath $receiptPath -Value 'durable-receipt' -NoNewline
        Mock Test-DirectoryWritable { return $Writable } -ParameterFilter { $Path -eq $script:fallbackData }
        if ($Writable) {
            Initialize-StorageLocation
            $script:Storage.BasePath | Should -Be $script:fallbackRoot
        }
        else {
            { Initialize-StorageLocation } | Should -Throw '*could not find a writable storage location*'
            $script:Storage.Initialised | Should -BeFalse
        }
        Should -Invoke Test-DirectoryWritable -Times 0 -Exactly -ParameterFilter { $Path -eq $script:repoData }
        Get-Content -LiteralPath $receiptPath -Raw | Should -BeExactly 'durable-receipt'
    }

    It 'migrates <Prefix> receipt <Copies> without overwriting or creating repository state' -TestCases @(
        foreach ($prefix in @('sync-submission', 'autopilot-import-submission')) {
            foreach ($copies in @('source-only', 'destination-only', 'identical')) {
                @{ Copies = $copies; Prefix = $prefix }
            }
        }
    ) {
        param($Copies, $Prefix)
        $sourcePath = Join-Path $script:repoData ('{0}-other-user-record.json' -f $Prefix)
        $destinationPath = Join-Path $script:fallbackData ('{0}-other-user-record.json' -f $Prefix)
        if ($Copies -ne 'destination-only') { Set-Content -LiteralPath $sourcePath -Value 'receipt' -NoNewline }
        if ($Copies -ne 'source-only') { Set-Content -LiteralPath $destinationPath -Value 'receipt' -NoNewline }
        Mock Test-DirectoryWritable { return $false } -ParameterFilter { $Path -eq $script:repoData }
        $script:localSessionLock = Start-LocalSessionLock
        Sync-RepoStateFilesToActiveStorage
        Get-Content -LiteralPath $destinationPath -Raw | Should -BeExactly 'receipt'
        Test-Path -LiteralPath $sourcePath | Should -Be ($Copies -ne 'destination-only')
        Test-Path -LiteralPath ('{0}.previous' -f $destinationPath) | Should -BeFalse
        Test-FallbackStorageAuthority -BasePath $script:fallbackRoot | Should -BeTrue
    }

    It 'pairs disjoint receipt filenames across roots without index-based substitutions' {
        $sourcePath = Join-Path $script:repoData 'sync-submission-source-record.json'
        $destinationOnlyPath = Join-Path $script:fallbackData 'sync-submission-destination-record.json'
        Set-Content -LiteralPath $sourcePath -Value 'source-receipt' -NoNewline
        Set-Content -LiteralPath $destinationOnlyPath -Value 'destination-receipt' -NoNewline
        $script:localSessionLock = Start-LocalSessionLock
        Sync-RepoStateFilesToActiveStorage
        Get-Content -LiteralPath (Join-Path $script:fallbackData 'sync-submission-source-record.json') -Raw | Should -BeExactly 'source-receipt'
        Get-Content -LiteralPath $destinationOnlyPath -Raw | Should -BeExactly 'destination-receipt'
        Test-Path -LiteralPath (Join-Path $script:repoData 'sync-submission-destination-record.json') | Should -BeFalse
        Test-FallbackStorageAuthority -BasePath $script:fallbackRoot | Should -BeTrue
    }

    It 'rejects receipt conflict with earlier copy candidate <EarlierCandidate> before any writes' -TestCases @(
        @{ EarlierCandidate = $false }; @{ EarlierCandidate = $true }
    ) {
        param($EarlierCandidate)
        $sourcePath = Join-Path $script:repoData 'sync-submission-z-conflict.json'
        $destinationPath = Join-Path $script:fallbackData 'sync-submission-z-conflict.json'
        Set-Content -LiteralPath $sourcePath -Value 'RECEIPT' -NoNewline
        Set-Content -LiteralPath $destinationPath -Value 'receipt' -NoNewline
        if ($EarlierCandidate) {
            Set-Content -LiteralPath $script:repoPaths[0] -Value 'devices' -NoNewline
            Set-Content -LiteralPath (Join-Path $script:repoData 'sync-submission-a-copy.json') -Value 'earlier-receipt' -NoNewline
        }
        $script:localSessionLock = Start-LocalSessionLock
        Mock Write-Utf8File { throw 'Unexpected migration write' }
        { Sync-RepoStateFilesToActiveStorage } | Should -Throw '*Conflicting storage copies*'
        Should -Invoke Write-Utf8File -Times 0 -Exactly
        Test-Path -LiteralPath $script:authorityPath | Should -BeFalse
        Test-Path -LiteralPath $script:fallbackPaths[0] | Should -BeFalse
        Test-Path -LiteralPath (Join-Path $script:fallbackData 'sync-submission-a-copy.json') | Should -BeFalse
        Get-Content -LiteralPath $sourcePath -Raw | Should -BeExactly 'RECEIPT'
        Get-Content -LiteralPath $destinationPath -Raw | Should -BeExactly 'receipt'
    }

    It 'discovers target-missing <Prefix> receipt recovery in <Root> with <Suffix> before migration' -TestCases @(
        foreach ($root in @('repo', 'fallback')) {
            foreach ($suffix in @('.pending', '.previous', '.write-in-progress')) {
                foreach ($prefix in @('sync-submission', 'autopilot-import-submission')) {
                    @{ Root = $root; Suffix = $suffix; Prefix = $prefix }
                }
            }
        }
    ) {
        param($Root, $Suffix, $Prefix)
        $dataPath = if ($Root -eq 'repo') { $script:repoData } else { $script:fallbackData }
        $receiptPath = Join-Path $dataPath ('{0}-other-user-record.json' -f $Prefix)
        $evidencePath = '{0}{1}' -f $receiptPath, $Suffix
        Set-Content -LiteralPath $evidencePath -Value 'recovery-evidence' -NoNewline
        Set-Content -LiteralPath $script:repoPaths[0] -Value 'earlier-state' -NoNewline
        Mock Test-DirectoryWritable { return $false } -ParameterFilter { $Path -eq $script:repoData }
        Mock Write-Utf8File { throw 'Unexpected migration write' }
        {
            $script:localSessionLock = Start-LocalSessionLock
            Sync-RepoStateFilesToActiveStorage
        } | Should -Throw '*recovery is required*'
        Should -Invoke Write-Utf8File -Times 0 -Exactly
        Test-Path -LiteralPath $receiptPath | Should -BeFalse
        Test-Path -LiteralPath $script:fallbackPaths[0] | Should -BeFalse
        Test-Path -LiteralPath $script:authorityPath | Should -BeFalse
        Get-Content -LiteralPath $evidencePath -Raw | Should -BeExactly 'recovery-evidence'
    }

    It 'ignores stale repository receipts after authority but still rejects active pending-only receipts' {
        Mock Test-DirectoryWritable { return $false } -ParameterFilter { $Path -eq $script:repoData }
        $script:localSessionLock = Start-LocalSessionLock
        Sync-RepoStateFilesToActiveStorage
        $sourcePath = Join-Path $script:repoData 'sync-submission-stale-record.json'
        $activePath = Join-Path $script:fallbackData 'sync-submission-active-record.json'
        Set-Content -LiteralPath $sourcePath -Value 'stale-receipt' -NoNewline
        Set-Content -LiteralPath ('{0}.pending' -f $sourcePath) -Value 'stale-evidence' -NoNewline
        { Sync-RepoStateFilesToActiveStorage } | Should -Not -Throw
        Test-Path -LiteralPath (Join-Path $script:fallbackData 'sync-submission-stale-record.json') | Should -BeFalse
        Set-Content -LiteralPath ('{0}.pending' -f $activePath) -Value 'active-evidence' -NoNewline
        { Sync-RepoStateFilesToActiveStorage } | Should -Throw '*recovery is required*'
        Stop-LocalSessionLock -Lock $script:localSessionLock
        $script:Storage.Initialised = $false
        { Initialize-StorageLocation } | Should -Throw '*recovery is required*'
        Get-Content -LiteralPath ('{0}.pending' -f $activePath) -Raw | Should -BeExactly 'active-evidence'
    }

    It 'retains completed receipt previous backups without migrating them' {
        $sourcePath = Join-Path $script:repoData 'sync-submission-record-123.json'
        $destinationPath = Join-Path $script:fallbackData 'sync-submission-record-123.json'
        Set-Content -LiteralPath $sourcePath -Value 'current-receipt' -NoNewline
        Set-Content -LiteralPath ('{0}.previous' -f $sourcePath) -Value 'previous-receipt' -NoNewline
        @(Get-OperationalStoragePath -BasePath $script:repoRoot | Where-Object { $_ -eq $sourcePath }).Count | Should -Be 1
        Mock Test-DirectoryWritable { return $false } -ParameterFilter { $Path -eq $script:repoData }
        $script:localSessionLock = Start-LocalSessionLock
        Sync-RepoStateFilesToActiveStorage
        Get-Content -LiteralPath $destinationPath -Raw | Should -BeExactly 'current-receipt'
        Get-Content -LiteralPath ('{0}.previous' -f $sourcePath) -Raw | Should -BeExactly 'previous-receipt'
        Test-Path -LiteralPath ('{0}.previous' -f $destinationPath) | Should -BeFalse
    }

    It 'ignores Live receipts and their recovery artefacts throughout Demo selection and migration' {
        Set-Content -LiteralPath (Join-Path $script:fallbackData 'sync-submission-other-user.json') -Value 'live-receipt' -NoNewline
        foreach ($dataPath in @($script:repoData, $script:fallbackData)) {
            foreach ($suffix in @('.pending', '.previous', '.write-in-progress')) {
                Set-Content -LiteralPath (Join-Path $dataPath ('sync-submission-record.json{0}' -f $suffix)) -Value 'live-evidence' -NoNewline
            }
        }
        $script:Runtime.IsDemoMode = $true
        Initialize-StorageLocation
        $script:Storage.BasePath | Should -Be $script:repoRoot
        @(Get-OperationalStoragePath -BasePath $script:fallbackRoot).Count | Should -Be 4
        $script:Storage.Initialised = $false
        Mock Test-DirectoryWritable { return $false } -ParameterFilter { $Path -eq $script:repoData }
        $script:localSessionLock = Start-LocalSessionLock
        { Sync-RepoStateFilesToActiveStorage } | Should -Not -Throw
        Test-FallbackStorageAuthority -BasePath $script:fallbackRoot | Should -BeTrue
        Get-Content -LiteralPath (Join-Path $script:fallbackData 'sync-submission-other-user.json') -Raw | Should -BeExactly 'live-receipt'
        Test-Path -LiteralPath (Join-Path $script:repoData 'sync-submission-other-user.json') | Should -BeFalse
    }

    It 'discovers only canonical receipt filenames without traversing directories or extra suffixes' {
        foreach ($fileName in @('sync-submission-bad_id.json.pending', 'sync-submission-record.json.pending.extra', 'sync-submission-.json')) {
            Set-Content -LiteralPath (Join-Path $script:fallbackData $fileName) -Value 'not-a-receipt' -NoNewline
        }
        $nestedPath = Join-Path $script:fallbackData 'sync-submission-directory.json'
        New-Item -ItemType Directory -Path $nestedPath | Out-Null
        Set-Content -LiteralPath (Join-Path $nestedPath 'sync-submission-nested.json.pending') -Value 'not-root-state' -NoNewline
        @(Get-OperationalStoragePath -BasePath $script:fallbackRoot).Count | Should -Be 5
        Initialize-StorageLocation
        $script:Storage.BasePath | Should -Be $script:repoRoot
    }

    It 'checks source recovery even when an identical destination already exists' {
        Set-Content -LiteralPath $script:repoPaths[0] -Value 'same' -NoNewline
        Set-Content -LiteralPath $script:fallbackPaths[0] -Value 'same' -NoNewline
        Set-Content -LiteralPath ('{0}.pending' -f $script:repoPaths[0]) -Value 'evidence' -NoNewline
        { Copy-StateFileIfNeeded -SourcePath $script:repoPaths[0] -DestinationPath $script:fallbackPaths[0] } | Should -Throw '*recovery is required*'
        Get-Content -LiteralPath $script:fallbackPaths[0] -Raw | Should -BeExactly 'same'
    }

    It 'preflights <Root> file <Index> with <Suffix> before any migration' -TestCases @(
        foreach ($root in @('repo', 'fallback')) {
            foreach ($index in 0..3) {
                foreach ($suffix in @('.pending', '.write-in-progress', '.previous')) {
                    @{ Root = $root; Index = $index; Suffix = $suffix }
                }
            }
        }
    ) {
        param($Root, $Index, $Suffix)
        for ($fileIndex = 0; $fileIndex -lt $script:repoPaths.Count; $fileIndex++) {
            Set-Content -LiteralPath $script:repoPaths[$fileIndex] -Value ('source-{0}' -f $fileIndex) -NoNewline
        }
        $blockedPath = if ($Root -eq 'repo') { $script:repoPaths[$Index] } else { $script:fallbackPaths[$Index] }
        if ($Suffix -eq '.previous' -and (Test-Path -LiteralPath $blockedPath)) { Remove-Item -LiteralPath $blockedPath }
        $evidencePath = '{0}{1}' -f $blockedPath, $Suffix
        Set-Content -LiteralPath $evidencePath -Value 'recovery-evidence' -NoNewline
        $sourceHashes = @(Get-ChildItem -LiteralPath $script:repoData -File | Get-FileHash | Select-Object -ExpandProperty Hash)
        Mock Test-DirectoryWritable { return $false } -ParameterFilter { $Path -eq $script:repoData }
        {
            $script:localSessionLock = Start-LocalSessionLock
            Sync-RepoStateFilesToActiveStorage
        } | Should -Throw '*recovery is required*'
        Get-Content -LiteralPath $evidencePath -Raw | Should -BeExactly 'recovery-evidence'
        @(Get-ChildItem -LiteralPath $script:repoData -File | Get-FileHash | Select-Object -ExpandProperty Hash) | Should -Be $sourceHashes
        @(Get-ChildItem -LiteralPath $script:fallbackData -Filter '*.json' -File).Count | Should -Be 0
        Test-Path -LiteralPath $script:authorityPath | Should -BeFalse
    }
}