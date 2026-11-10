<#
.SYNOPSIS
    Checks that local storage failures stop work instead of discarding history.
.DESCRIPTION
    Extracts production record and audit helpers without starting the CLI. File
    reads and writes are mocked; no operational storage or tenant calls occur.
#>
BeforeAll {
    $sourcePath = Join-Path (Split-Path -Parent $PSScriptRoot) 'autopilot-express.ps1'
    $tokens = $null
    $parseErrors = $null
    $sourceAst = [System.Management.Automation.Language.Parser]::ParseFile($sourcePath, [ref]$tokens, [ref]$parseErrors)
    if ($parseErrors.Count) { throw ($parseErrors.Message -join '; ') }
    foreach ($functionName in @('Assert-AttemptHistory', 'Test-AttemptEvidenceEqual', 'Assert-AttemptHistoryPreserved', 'New-EmptyDeviceRecord', 'ConvertTo-NormalisedValue', 'ConvertTo-StepHashtable', 'ConvertTo-RecordDate', 'ConvertTo-PersistedDate', 'ConvertTo-PersistedDeviceRecord', 'Get-UserDeviceRecords', 'Write-UserDeviceRecords', 'Get-MasterAuditProposal', 'Get-VerifiedSaveCopy', 'Update-MasterAuditLedger', 'Get-DefaultBuildBenchState', 'Get-BuildBenchState', 'Save-BuildBenchState', 'Assert-DeviceRecordIdentity', 'Assert-BenchPositionIdentity')) {
        $definition = $sourceAst.Find({ param($node) $node -is [System.Management.Automation.Language.FunctionDefinitionAst] -and $node.Name -eq $functionName }, $true)
        if (-not $definition) { throw ('Missing function: {0}' -f $functionName) }
        Set-Item -Path ('Function:{0}' -f $definition.Name) -Value $definition.Body.GetScriptBlock()
    }
    function Get-UserDataFilePath { return 'synthetic-records.json' }
    function Get-MasterAuditFilePath { return 'synthetic-audit.json' }
    function Get-BuildBenchStatePath { return 'synthetic-bench.json' }
    function Get-LocalCheckpointPath { return 'synthetic-checkpoint.json' }
    function Get-DataFolderPath { return 'synthetic-root' }
    function Assert-LocalCheckpointState { }
    function Write-Utf8File { param($Path, $Content) throw ('Unexpected write: {0}, {1}' -f $Path, $Content) }
    function Write-AutopilotExpressLog { param($Message, $Level) throw ('Unexpected log: {0}, {1}' -f $Level, $Message) }
}

Describe 'Fail-closed local record and audit storage' {
    BeforeEach {
        $script:Runtime = @{ IsDemoMode = $false }
        $script:BuildBench = $null
        $script:record = New-EmptyDeviceRecord
        $script:record.RecordId = 'synthetic-record'
        $script:record.Serial = 'DEMO-STORAGE'
        Mock Test-Path { return $true }
        Mock Get-Content { return '[]' }
        Mock Write-Utf8File {}
        Mock Remove-Item {} -ParameterFilter { $LiteralPath -eq 'synthetic-checkpoint.json' }
        Mock Write-AutopilotExpressLog {}
    }

    It 'preserves missing-file startup as an empty collection' {
        Mock Test-Path { return $false }
        $records = Get-UserDeviceRecords
        $records.Count | Should -Be 0
    }

    It 'does not turn invalid session JSON into an empty session' {
        Mock Get-Content { return '{invalid-json' }
        { Get-UserDeviceRecords } | Should -Throw
        Should -Invoke Write-Utf8File -Times 0 -Exactly
    }

    It 'propagates session read errors' {
        Mock Get-Content { throw 'Synthetic read denied' }
        { Get-UserDeviceRecords } | Should -Throw 'Synthetic read denied'
    }

    It 'does not replace an unreadable audit with an empty ledger' {
        Mock Get-Content { return '{invalid-json' }
        { Update-MasterAuditLedger -Records @($script:record) } | Should -Throw
        Should -Invoke Write-Utf8File -Times 0 -Exactly
    }

    It 'propagates a failed device save without attempting the audit' {
        Mock Write-Utf8File { throw 'Synthetic write denied' } -ParameterFilter { $Path -eq 'synthetic-records.json' }
        Mock Update-MasterAuditLedger {}
        { Write-UserDeviceRecords -Records @($script:record) } | Should -Throw 'Synthetic write denied'
        Should -Invoke Update-MasterAuditLedger -Times 0 -Exactly
    }

    It 'stops further work when audit persistence fails after a device save' {
        Mock Update-MasterAuditLedger { throw 'Synthetic audit write denied' }
        { Write-UserDeviceRecords -Records @($script:record) } | Should -Throw 'Synthetic audit write denied'
        Should -Invoke Write-Utf8File -Times 1 -Exactly -ParameterFilter { $Path -eq 'synthetic-records.json' }
    }

    It 'still saves valid device state and updates its audit' {
        Mock Update-MasterAuditLedger {}
        { Write-UserDeviceRecords -Records @($script:record) } | Should -Not -Throw
        Should -Invoke Write-Utf8File -Times 1 -Exactly -ParameterFilter { $Path -eq 'synthetic-records.json' }
        Should -Invoke Update-MasterAuditLedger -Times 1 -Exactly
    }

    It 'does not replace malformed bench storage with an empty bench' {
        Mock Get-Content { return '{invalid-json' }
        { Get-BuildBenchState } | Should -Throw
        Should -Invoke Write-Utf8File -Times 0 -Exactly
    }

    It 'propagates bench read failures' {
        Mock Get-Content { throw 'Synthetic bench read denied' }
        { Get-BuildBenchState } | Should -Throw 'Synthetic bench read denied'
    }

    It 'propagates bench save failures' {
        $script:BuildBench = Get-DefaultBuildBenchState
        Mock Write-Utf8File { throw 'Synthetic bench write denied' }
        { Save-BuildBenchState } | Should -Throw 'Synthetic bench write denied'
    }

    It 'rejects duplicate serials loaded from saved records without writing' {
        Mock Get-Content { return '[{"Serial":"DUPLICATE","RecordId":"one"},{"Serial":"duplicate","RecordId":"two"}]' }
        { Get-UserDeviceRecords } | Should -Throw '*Duplicate serial*'
        Should -Invoke Write-Utf8File -Times 0 -Exactly
    }

    It 'rejects duplicate occupied positions loaded from the bench without writing' {
        Mock Get-Content { return '{"Positions":[{"Index":1,"Serial":"DUPLICATE"},{"Index":2,"Serial":"duplicate"}]}' }
        { Get-BuildBenchState } | Should -Throw '*Duplicate serial*'
        Should -Invoke Write-Utf8File -Times 0 -Exactly
    }
}