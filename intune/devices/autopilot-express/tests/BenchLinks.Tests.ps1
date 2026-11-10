<#
.SYNOPSIS
    Checks bench-to-workflow links before induction or persistence.
.DESCRIPTION
    Extracts actual functions through the syntax tree without launching the CLI.
    Construction and writes are mocked; no tenant or operational storage is used.
    Requires Pester 5 and PowerShell 7.
#>
BeforeAll {
    $sourcePath = Join-Path (Split-Path -Parent $PSScriptRoot) 'autopilot-express.ps1'
    $tokens = $null
    $parseErrors = $null
    $sourceAst = [System.Management.Automation.Language.Parser]::ParseFile($sourcePath, [ref]$tokens, [ref]$parseErrors)
    if ($parseErrors.Count) { throw ($parseErrors.Message -join '; ') }
    foreach ($functionName in @('Sync-BenchRecords', 'Assert-BenchPositionIdentity', 'Assert-DeviceRecordIdentity', 'Add-DeviceRecord', 'New-EmptyDeviceRecord', 'Get-EligibleManifestSteps', 'Get-NextStepId')) {
        $definition = $sourceAst.Find({ param($node) $node -is [System.Management.Automation.Language.FunctionDefinitionAst] -and $node.Name -eq $functionName }, $true)
        if (-not $definition) { throw ('Missing function: {0}' -f $functionName) }
        . ([scriptblock]::Create($definition.Extent.Text))
    }
    function New-DeviceRecordObject {
        [CmdletBinding(SupportsShouldProcess)]
        [OutputType([System.Collections.IDictionary])]
        param($Serial, $ConfigItem, $SiteCode, $DeviceType, $GroupTag)
        if ($PSCmdlet.ShouldProcess($Serial, 'Create synthetic record')) {
            $record = New-EmptyDeviceRecord
            $record.Serial = $Serial
            $record.ConfigItem = $ConfigItem
            $record.SiteCode = $SiteCode
            $record.DeviceType = $DeviceType
            $record.GroupTag = $GroupTag
            return $record
        }
    }
    function Write-UserDeviceRecords {
        [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseSingularNouns', '', Justification = 'The test stub must retain the production persistence command name for mocking.')]
        [CmdletBinding()]
        param($Records)
        throw ('Unexpected save: {0}' -f @($Records).Count)
    }
}

Describe 'Bench cross-link prevalidation' {
    BeforeEach {
        $script:BuildBench = @{ SiteCode = 'MI'; DeviceType = 'Desktop'; Positions = @(@{ Index = 1; Serial = 'BENCH-01'; ConfigItem = 'CI-01' }) }
        $script:records = @{ Value = @() }
        $script:record = New-EmptyDeviceRecord
        $script:record.Serial = 'BENCH-01'
        $script:record.ConfigItem = 'CI-01'
        $script:record.Status = 'in-progress'
        $script:record.Steps = @{ A = @{ CompletionState = 'Simulated' } }
        Mock Write-UserDeviceRecords {}
        Mock New-DeviceRecordObject {
            $record = New-EmptyDeviceRecord
            $record.Serial = $Serial
            $record.ConfigItem = $ConfigItem
            $record.SiteCode = $SiteCode
            $record.DeviceType = $DeviceType
            $record.GroupTag = $GroupTag
            return $record
        }
    }

    It 'creates an absent record with empty workflow defaults and bench metadata' {
        Sync-BenchRecords -Records $script:records
        $script:records.Value.Count | Should -Be 1
        $script:records.Value[0].Serial | Should -Be 'BENCH-01'
        $script:records.Value[0].ConfigItem | Should -Be 'CI-01'
        $script:records.Value[0].Status | Should -Be 'new'
        $script:records.Value[0].Steps.Count | Should -Be 0
        $script:records.Value[0].GroupTag | Should -Be 'MI-Desktop'
        Should -Invoke New-DeviceRecordObject -Times 1 -Exactly
        Should -Invoke Write-UserDeviceRecords -Times 1 -Exactly
    }

    It 'reuses a matching record without changing its progress or bench data' {
        $script:records.Value = @($script:record)
        $before = @{ Records = $script:records; Bench = $script:BuildBench } | ConvertTo-Json -Depth 20 -Compress
        Sync-BenchRecords -Records $script:records
        (@{ Records = $script:records; Bench = $script:BuildBench } | ConvertTo-Json -Depth 20 -Compress) | Should -BeExactly $before
        Should -Invoke New-DeviceRecordObject -Times 0 -Exactly
        Should -Invoke Write-UserDeviceRecords -Times 0 -Exactly
    }

    It 'matches case and surrounding whitespace without relabelling either identity' {
        $script:record.Serial = ' bench-01 '
        $script:record.ConfigItem = ' ci-01 '
        $script:BuildBench.Positions[0].Serial = ' BENCH-01 '
        $script:records.Value = @($script:record)
        Sync-BenchRecords -Records $script:records
        $script:records.Value.Count | Should -Be 1
        $script:record.Serial | Should -BeExactly ' bench-01 '
        $script:record.ConfigItem | Should -BeExactly ' ci-01 '
        $script:BuildBench.Positions[0].Serial | Should -BeExactly ' BENCH-01 '
        Should -Invoke New-DeviceRecordObject -Times 0 -Exactly
    }

    It 'rejects an invalid later slot before any creation mutation or write: <Scenario>' -TestCases @(
        @{ Scenario = 'mismatched CI'; Serial = 'BENCH-01'; ConfigItem = 'OTHER-CI'; Status = 'in-progress'; Message = '*position 2*does not match*' }
        @{ Scenario = 'CI owned by another record with no matching serial'; Serial = 'BENCH-02'; ConfigItem = ' ci-01 '; Status = 'in-progress'; Message = '*position 2*belongs to another workflow*' }
        @{ Scenario = 'removed record'; Serial = 'BENCH-01'; ConfigItem = 'CI-01'; Status = 'removed'; Message = '*position 2*removed workflow*' }
        @{ Scenario = 'missing CI'; Serial = 'BENCH-02'; ConfigItem = ''; Status = 'in-progress'; Message = '*position 2*no Configuration Item*' }
    ) {
        param($Scenario, $Serial, $ConfigItem, $Status, $Message)
        $Scenario | Should -Not -BeNullOrEmpty
        $script:record.Status = $Status
        $script:records.Value = @($script:record)
        $script:BuildBench.Positions = @(
            @{ Index = 1; Serial = 'NEW-01'; ConfigItem = 'NEW-CI' }
            @{ Index = 2; Serial = $Serial; ConfigItem = $ConfigItem }
        )
        $recordsReference = $script:records.Value
        $before = @{ Records = $script:records; Bench = $script:BuildBench } | ConvertTo-Json -Depth 20 -Compress
        { Sync-BenchRecords -Records $script:records } | Should -Throw $Message
        (@{ Records = $script:records; Bench = $script:BuildBench } | ConvertTo-Json -Depth 20 -Compress) | Should -BeExactly $before
        [object]::ReferenceEquals($recordsReference, $script:records.Value) | Should -BeTrue
        Should -Invoke New-DeviceRecordObject -Times 0 -Exactly
        Should -Invoke Write-UserDeviceRecords -Times 0 -Exactly
    }

    It 'resumes a completed bench link without reopening its workflow or changing evidence' {
        $script:record.Status = 'completed'
        $script:record.CompletedAt = '2026-10-08T22:29:26Z'
        $script:record.CompletedBy = 'synthetic-technician'
        $script:records.Value = @($script:record)
        $before = @{ Records = $script:records; Bench = $script:BuildBench } | ConvertTo-Json -Depth 20 -Compress
        { Sync-BenchRecords -Records $script:records } | Should -Not -Throw
        (@{ Records = $script:records; Bench = $script:BuildBench } | ConvertTo-Json -Depth 20 -Compress) | Should -BeExactly $before
        Should -Invoke New-DeviceRecordObject -Times 0 -Exactly
        Should -Invoke Write-UserDeviceRecords -Times 0 -Exactly
    }

    It 'never offers a next action for a terminal record with incomplete legacy step fields: <Status>' -TestCases @(
        @{ Status = 'completed' }
        @{ Status = 'removed' }
    ) {
        param($Status)
        $script:record.Status = $Status
        $script:record.Steps = @{}
        @(Get-EligibleManifestSteps -Device $script:record).Count | Should -Be 0
        Get-NextStepId -Device $script:record | Should -BeNullOrEmpty
        $script:record.Status | Should -Be $Status
        $script:record.Steps.Count | Should -Be 0
        Should -Invoke Write-UserDeviceRecords -Times 0 -Exactly
    }

    It 'retains records outside the bench without warning or deletion' {
        $script:record.Serial = 'RETAINED-01'
        $script:record.ConfigItem = 'RETAINED-CI'
        $script:records.Value = @($script:record)
        $before = $script:record | ConvertTo-Json -Depth 20 -Compress
        Mock Write-Warning { throw 'Unexpected retained-record warning' }
        Sync-BenchRecords -Records $script:records
        $script:records.Value.Count | Should -Be 2
        ($script:record | ConvertTo-Json -Depth 20 -Compress) | Should -BeExactly $before
        [object]::ReferenceEquals($script:record, $script:records.Value[0]) | Should -BeTrue
        Should -Invoke Write-Warning -Times 0 -Exactly
    }

    It 'preserves removed-record CI reuse for a different serial' {
        $script:record.Serial = 'REMOVED-01'
        $script:record.Status = 'removed'
        $script:records.Value = @($script:record)
        Sync-BenchRecords -Records $script:records
        $script:records.Value.Count | Should -Be 2
        $script:record.Status | Should -Be 'removed'
        Should -Invoke Write-UserDeviceRecords -Times 1 -Exactly
    }

    It 'propagates a save failure without retrying or hiding it' {
        $script:records.Value = @()
        Mock Write-UserDeviceRecords { throw 'Synthetic bench save failure' }
        { Sync-BenchRecords -Records $script:records } | Should -Throw '*Synthetic bench save failure*'
        Should -Invoke Write-UserDeviceRecords -Times 1 -Exactly
        Should -Invoke New-DeviceRecordObject -Times 1 -Exactly
    }
}