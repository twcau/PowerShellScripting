<#
.SYNOPSIS
    Checks the BACKUP-POLICY recovery evidence layout, size report and organise action.
.DESCRIPTION
    Extracts production helpers from autopilot-express.ps1 and redirects LOCALAPPDATA to the Pester
    TestDrive, so no real recovery evidence, session data or tenant service is read or changed.
    Owner policy under test: keep every backup, organise by date and tenant, never delete.
.FILECREATED
    2026-10-27
.FILELASTUPDATED
    2026-10-27
#>
BeforeAll {
    $sourcePath = Join-Path (Split-Path -Parent $PSScriptRoot) 'autopilot-express.ps1'
    $tokens = $null
    $parseErrors = $null
    $sourceAst = [System.Management.Automation.Language.Parser]::ParseFile($sourcePath, [ref]$tokens, [ref]$parseErrors)
    if ($parseErrors.Count) { throw ($parseErrors.Message -join '; ') }
    foreach ($functionName in @('Get-LocalSessionRecoveryInventory', 'Get-RecoveryEvidenceTenantKey', 'Get-RecoveryEvidenceFolder', 'Get-RecoveryEvidenceInventory', 'Move-RecoveryEvidenceToOrganisedLayout', 'New-LocalSessionRecoverySnapshot', 'Show-RecoveryEvidenceReport', 'Read-ValidatedInput', 'Read-PagedInformation')) {
        $definition = $sourceAst.Find({ param($node) $node -is [System.Management.Automation.Language.FunctionDefinitionAst] -and $node.Name -eq $functionName }, $true)
        if (-not $definition) { throw ('Missing function: {0}' -f $functionName) }
        Set-Item -Path ('Function:{0}' -f $definition.Name) -Value $definition.Body.GetScriptBlock()
    }
    function Write-AutopilotExpressLog { param([string]$Message, [string]$Level) $script:logLines.Add(('{0}|{1}' -f $Level, $Message)) }
    function Show-ScriptScreen { param([string]$Title) $script:lastScreenTitle = $Title }
    function Show-ReturnToMainMenu { }
    $script:tenantA = '11111111-2222-3333-4444-555555555555'
    $script:tenantB = 'AAAAAAAA-BBBB-CCCC-DDDD-EEEEEEEEEEEE'
    $script:originalLocalAppData = $env:LOCALAPPDATA
}

AfterAll { $env:LOCALAPPDATA = $script:originalLocalAppData }

Describe 'Recovery evidence tenant folder key' {
    BeforeEach {
        $script:data = Join-Path $TestDrive ([guid]::NewGuid().ToString('N'))
        New-Item -ItemType Directory -Path $script:data | Out-Null
        $Script:RuntimeConfig = @{ graph = @{ expectedTenantId = '' } }
    }

    It 'files demo evidence under demo regardless of content' {
        Set-Content -LiteralPath (Join-Path $script:data 'devices.json') -Value ('[{{"TenantId":"{0}"}}]' -f $script:tenantA)
        Get-RecoveryEvidenceTenantKey -Folder $script:data -Mode Demo | Should -BeExactly 'demo'
    }
    It 'uses the single persisted tenant in lower case' {
        Set-Content -LiteralPath (Join-Path $script:data 'devices.json') -Value ('[{{"TenantId" : "{0}"}},{{"TenantId":"{1}"}}]' -f $script:tenantB, $script:tenantB.ToLowerInvariant())
        Get-RecoveryEvidenceTenantKey -Folder $script:data -Mode Live | Should -BeExactly $script:tenantB.ToLowerInvariant()
    }
    It 'reports tenant-mixed when the store holds more than one tenant' {
        Set-Content -LiteralPath (Join-Path $script:data 'a.json') -Value ('{{"TenantId":"{0}"}}' -f $script:tenantA)
        Set-Content -LiteralPath (Join-Path $script:data 'b.json') -Value ('{{"TenantId":"{0}"}}' -f $script:tenantB)
        Get-RecoveryEvidenceTenantKey -Folder $script:data -Mode Live | Should -BeExactly 'tenant-mixed'
    }
    It 'falls back to the configured live tenant, then to tenant-unbound' {
        Set-Content -LiteralPath (Join-Path $script:data 'devices.json') -Value '[]'
        Get-RecoveryEvidenceTenantKey -Folder $script:data -Mode Live | Should -BeExactly 'tenant-unbound'
        $Script:RuntimeConfig.graph.expectedTenantId = $script:tenantB
        Get-RecoveryEvidenceTenantKey -Folder $script:data -Mode Live | Should -BeExactly $script:tenantB.ToLowerInvariant()
    }
    It 'recognises demo-only stores when the mode is unknown' {
        Set-Content -LiteralPath (Join-Path $script:data 'autopilot-session-demo-devices.json') -Value '[]'
        Get-RecoveryEvidenceTenantKey -Folder $script:data | Should -BeExactly 'demo'
    }
    It 'never throws for an unreadable folder' {
        Get-RecoveryEvidenceTenantKey -Folder (Join-Path $TestDrive 'missing-folder') -Mode Live | Should -BeExactly 'tenant-unknown'
    }
    It 'builds the date and tenant layout and rejects unexpected folder names' {
        $env:LOCALAPPDATA = Join-Path $TestDrive 'Local'
        $stamp = [datetime]'2026-10-27T09:15:00'
        Get-RecoveryEvidenceFolder -Kind CrashLocks -TenantKey 'demo' -Timestamp $stamp | Should -BeExactly (Join-Path $env:LOCALAPPDATA 'PowerShellScriptingNew\AutopilotExpressRecoveryEvidence\CrashLocks\2026-10-27\demo')
        Get-RecoveryEvidenceFolder -Kind SessionSnapshots -TenantKey '..\escape' -Timestamp $stamp | Should -Match 'SessionSnapshots\\2026-10-27\\tenant-unknown$'
    }
}

Describe 'Recovery evidence snapshot, report and organise' {
    BeforeEach {
        $env:LOCALAPPDATA = Join-Path $TestDrive ([guid]::NewGuid().ToString('N'))
        $script:logLines = [Collections.Generic.List[string]]::new()
        $Script:RuntimeConfig = @{ graph = @{ expectedTenantId = '' } }
        $script:root = Join-Path $env:LOCALAPPDATA 'PowerShellScriptingNew\AutopilotExpressRecoveryEvidence'
        # Legacy flat snapshot carrying tenant A, legacy crash lock, and a workflow-ID conversion backup.
        $script:legacySnapshot = Join-Path $script:root 'SessionSnapshots\20261020-101500-0123456789abcdef'
        New-Item -ItemType Directory -Path (Join-Path $script:legacySnapshot 'files') -Force | Out-Null
        Set-Content -LiteralPath (Join-Path $script:legacySnapshot 'files\devices.json') -Value ('[{{"TenantId":"{0}"}}]' -f $script:tenantA)
        Set-Content -LiteralPath (Join-Path $script:legacySnapshot 'manifest.json') -Value '{"Status":"Verified"}'
        $script:legacyLock = Join-Path $script:root 'CrashLocks\20261021-080000-fedcba9876543210.lock.evidence'
        New-Item -ItemType File -Path $script:legacyLock -Value '{"Token":"old"}' -Force | Out-Null
        $script:workflowBackup = Join-Path $script:root '20261019-0900-workflow-ids-0f0e0d0c-0b0a-0908-0706-050403020100'
        New-Item -ItemType File -Path (Join-Path $script:workflowBackup 'devices.json') -Value '[]' -Force | Out-Null
    }

    It 'writes new snapshots into the organised date and tenant folder' {
        $data = Join-Path $TestDrive ([guid]::NewGuid().ToString('N'))
        New-Item -ItemType Directory -Path $data | Out-Null
        Set-Content -LiteralPath (Join-Path $data 'devices.json') -Value ('[{{"TenantId":"{0}"}}]' -f $script:tenantB)
        $snapshot = New-LocalSessionRecoverySnapshot -DataPath $data -Mode Live -Confirm:$false
        $snapshot.TenantKey | Should -BeExactly $script:tenantB.ToLowerInvariant()
        (Split-Path -Parent $snapshot.Path) | Should -BeExactly (Join-Path $script:root ('SessionSnapshots\{0}\{1}' -f (Get-Date -Format 'yyyy-MM-dd'), $snapshot.TenantKey))
        Test-Path -LiteralPath (Join-Path $snapshot.Path 'manifest.json') | Should -BeTrue
    }
    It 'classifies organised, legacy and other evidence with sizes' {
        $inventory = @(Get-RecoveryEvidenceInventory)
        @($inventory | Where-Object Layout -eq 'Legacy').Count | Should -Be 2
        ($inventory | Where-Object Kind -eq 'CrashLocks').Date | Should -BeExactly '2026-10-21'
        ($inventory | Where-Object Layout -eq 'Other').Path | Should -BeExactly $script:workflowBackup
        ($inventory | Where-Object Kind -eq 'SessionSnapshots').Files | Should -Be 2
        @($inventory | Where-Object { $_.Bytes -le 0 }).Count | Should -Be 0
    }
    It 'organises legacy evidence by moving only, never deleting, and leaves workflow-ID backups in place' {
        $before = @(Get-ChildItem -LiteralPath $script:root -File -Recurse)
        $result = Move-RecoveryEvidenceToOrganisedLayout -Confirm:$false
        $result.Moved | Should -Be 2
        $result.Skipped | Should -Be 0
        Test-Path -LiteralPath (Join-Path $script:root ('SessionSnapshots\2026-10-20\{0}\20261020-101500-0123456789abcdef\manifest.json' -f $script:tenantA)) | Should -BeTrue
        Test-Path -LiteralPath (Join-Path $script:root 'CrashLocks\2026-10-21\tenant-unknown\20261021-080000-fedcba9876543210.lock.evidence') | Should -BeTrue
        Test-Path -LiteralPath (Join-Path $script:workflowBackup 'devices.json') | Should -BeTrue
        $after = @(Get-ChildItem -LiteralPath $script:root -File -Recurse)
        $after.Count | Should -Be $before.Count
        ($after | Measure-Object Length -Sum).Sum | Should -Be ($before | Measure-Object Length -Sum).Sum
        @(Get-RecoveryEvidenceInventory | Where-Object Layout -eq 'Legacy').Count | Should -Be 0
        @($script:logLines | Where-Object { $_ -like 'INFO|Recovery evidence organise*' }).Count | Should -Be 2
    }
    It 'skips a name collision instead of overwriting' {
        $existing = Join-Path $script:root 'CrashLocks\2026-10-21\tenant-unknown\20261021-080000-fedcba9876543210.lock.evidence'
        New-Item -ItemType File -Path $existing -Value 'newer evidence' -Force | Out-Null
        $result = Move-RecoveryEvidenceToOrganisedLayout -Confirm:$false
        $result.Skipped | Should -Be 1
        Get-Content -LiteralPath $existing -Raw | Should -BeExactly 'newer evidence'
        Test-Path -LiteralPath $script:legacyLock | Should -BeTrue
    }
    It 'changes nothing when the operator declines the default N confirmation' {
        $script:pagedAnswers = [Collections.Generic.Queue[string]]::new(); foreach ($answer in @('O', '0')) { $script:pagedAnswers.Enqueue($answer) }
        Mock Read-PagedInformation { return $script:pagedAnswers.Dequeue() }
        Mock Read-ValidatedInput { return $Default }
        Show-RecoveryEvidenceReport
        Should -Invoke Read-ValidatedInput -Times 1 -Exactly -ParameterFilter { $Default -eq 'N' -and $Prompt -like '*`[Y`] Yes `[N`] No*' }
        Should -Invoke Read-PagedInformation -Times 1 -ParameterFilter { $Options.Count -eq 1 -and $Options[0].Code -eq 'O' -and $ReturnDestination -eq 'Data Settings' }
        Test-Path -LiteralPath $script:legacyLock | Should -BeTrue
        Test-Path -LiteralPath $script:legacySnapshot | Should -BeTrue
    }
    It 'organises after an explicit Y and then offers no further organise action' {
        $script:pagedAnswers = [Collections.Generic.Queue[string]]::new(); foreach ($answer in @('O', '0')) { $script:pagedAnswers.Enqueue($answer) }
        Mock Read-PagedInformation { return $script:pagedAnswers.Dequeue() }
        Mock Read-ValidatedInput { return 'y' }
        Show-RecoveryEvidenceReport
        Test-Path -LiteralPath $script:legacyLock | Should -BeFalse
        Should -Invoke Read-PagedInformation -Times 1 -Exactly -ParameterFilter { $Options.Count -eq 0 }
    }
}