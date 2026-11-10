# .FILECREATED 2026-10-15
# .FILELASTUPDATED 2026-10-15
<#
.SYNOPSIS
    Run reproducible Autopilot Express offline static-analysis and regression gates.
.DESCRIPTION
    Resolves the product from this file, never the caller's working directory or
    operational storage environment. Requires approved Pester 5.7.1 and
    PSScriptAnalyzer 1.24.0; installs nothing and never authenticates. Tests use
    isolated fixtures. Reports and transcripts remain outside the repository.
.PARAMETER ReportDirectory
    External evidence directory. Defaults to a unique folder in temporary storage.
.PARAMETER Coverage
    Measure original-source command coverage in addition to the same mandatory
    executed-test gate. Measurement has no percentage acceptance implication.
.OUTPUTS
    Test summary object. Throws on prerequisites, static findings, discovery,
    failed containers, failed/skipped/unrun tests or incomplete execution.
.NOTES
    Run separately with approved FullLanguage PowerShell 7 and Windows PowerShell
    5.1. JSON schema and evidence contracts are exercised by the regression suites.
#>
[CmdletBinding()]
param(
    [ValidateNotNullOrEmpty()]
    [string]$ReportDirectory = (Join-Path $env:TEMP ('AutopilotOffline-{0}' -f [guid]::NewGuid().ToString('N'))),
    [switch]$Coverage
)

function Assert-OfflineTestResult {
    <#
    .SYNOPSIS
        Reject empty, malformed, partial or unsuccessful Pester execution summaries.
    .PARAMETER Result
        Pester result with non-negative integer execution and failed-container counts.
    .OUTPUTS
        None. Throws unless every discovered test was executed and passed.
    #>
    param([Parameter(Mandatory)][ValidateNotNull()][object]$Result)
    foreach ($field in @('TotalCount', 'PassedCount', 'FailedCount', 'SkippedCount', 'NotRunCount', 'FailedContainersCount')) {
        $count = $Result.$field
        if (($count -isnot [int] -and $count -isnot [long]) -or $count -lt 0) {
            throw ('Offline regression gate has an invalid or missing count: {0}.' -f $field)
        }
    }
    if ($Result.TotalCount -eq 0 -or $Result.PassedCount -ne $Result.TotalCount -or
        $Result.FailedCount -gt 0 -or $Result.SkippedCount -gt 0 -or
        $Result.NotRunCount -gt 0 -or $Result.FailedContainersCount -gt 0) {
        throw 'Offline regression gate failed. Every discovered test must execute and pass; inspect retained reports.'
    }
}

$ErrorActionPreference = 'Stop'
if ($ExecutionContext.SessionState.LanguageMode -ne 'FullLanguage') { throw 'Offline validation requires an approved FullLanguage host.' }
$productRoot = $PSScriptRoot
while ($productRoot -and -not (Test-Path -LiteralPath (Join-Path $productRoot 'autopilot-express.ps1') -PathType Leaf)) {
    $productRoot = Split-Path -Parent $productRoot
}
if (-not $productRoot) { throw 'Cannot resolve the Autopilot Express source root.' }
$repositoryRoot = $productRoot
while ($repositoryRoot -and -not (Test-Path -LiteralPath (Join-Path $repositoryRoot '.git'))) {
    $repositoryRoot = Split-Path -Parent $repositoryRoot
}
if (-not $repositoryRoot) { $repositoryRoot = $productRoot }
$reportRoot = [IO.Path]::GetFullPath($ReportDirectory).TrimEnd([IO.Path]::DirectorySeparatorChar)
if ($reportRoot -ieq $repositoryRoot -or $reportRoot.StartsWith(($repositoryRoot + [IO.Path]::DirectorySeparatorChar), [StringComparison]::OrdinalIgnoreCase)) {
    throw 'Offline reports must be outside the repository and operational discovery.'
}
New-Item -ItemType Directory -Path $reportRoot -Force -ErrorAction Stop | Out-Null
$transcriptStarted = $false
try {
    Start-Transcript -Path (Join-Path $reportRoot 'validation.log') -ErrorAction Stop | Out-Null
    $transcriptStarted = $true
    foreach ($requirement in @(@{ Name = 'Pester'; Version = '5.7.1' }, @{ Name = 'PSScriptAnalyzer'; Version = '1.24.0' })) {
        $module = Get-Module -ListAvailable -Name $requirement.Name |
            Where-Object { $_.Version -eq [version]$requirement.Version } |
            Select-Object -First 1
        if (-not $module) { throw ('Install the approved {0} {1} before offline validation; nothing was installed.' -f $requirement.Name, $requirement.Version) }
        Import-Module -Name $module.Path -Force -ErrorAction Stop
    }
    $testFiles = @(Get-ChildItem -LiteralPath (Join-Path $productRoot 'tests') -Filter '*.Tests.ps1' -File -ErrorAction Stop)
    if (-not $testFiles.Count) { throw 'Offline test discovery found no suites.' }
    $moduleFiles = @(Get-ChildItem -LiteralPath (Join-Path $productRoot 'Modules') -Recurse -File |
        Where-Object { $_.Extension -in @('.ps1', '.psm1', '.psd1') })
    $sourceFiles = @((Join-Path $productRoot 'autopilot-express.ps1'), $PSCommandPath) + @($testFiles.FullName) + @($moduleFiles.FullName)
    $findings = @(foreach ($path in $sourceFiles) {
        Invoke-ScriptAnalyzer -Path $path -ExcludeRule PSUseSingularNouns, PSAvoidUsingWriteHost
    })
    if ($findings.Count) {
        $findings | Format-Table ScriptName, Line, RuleName, Message -AutoSize | Out-Host
        throw 'Offline static-analysis gate failed; no tests were represented as passed.'
    }
    $templateFiles = @(Get-ChildItem -LiteralPath (Join-Path $productRoot 'templates') -Recurse -File)
    $provenanceFiles = $sourceFiles + @($templateFiles.FullName) + @((Join-Path $productRoot 'autopilot-express.manifest.json'), (Join-Path $productRoot 'autopilot-express.runtime.json'))
    $provenance = [ordered]@{
        HostVersion = [string]$PSVersionTable.PSVersion
        Edition = $PSVersionTable.PSEdition
        CreatedAt = (Get-Date -Format o)
        Files = @(foreach ($path in $provenanceFiles) {
            @{ Name = $path.Substring($productRoot.Length + 1); SHA256 = (Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash }
        })
    }
    $provenance | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath (Join-Path $reportRoot 'provenance.json') -Encoding UTF8
    $configuration = New-PesterConfiguration
    $configuration.Run.Path = @($testFiles.FullName)
    $configuration.Run.PassThru = $true
    $configuration.Should.ErrorAction = 'Stop'
    $configuration.Output.Verbosity = 'Normal'
    $configuration.TestResult.Enabled = $true
    $configuration.TestResult.OutputPath = Join-Path $reportRoot 'tests.xml'
    if ($Coverage) {
        $configuration.CodeCoverage.Enabled = $true
        $configuration.CodeCoverage.Path = Join-Path $productRoot 'autopilot-express.ps1'
        $configuration.CodeCoverage.OutputPath = Join-Path $reportRoot 'coverage.xml'
        $configuration.CodeCoverage.CoveragePercentTarget = 0
    }
    $result = Invoke-Pester -Configuration $configuration
    $summary = [pscustomobject]@{
        HostVersion = [string]$PSVersionTable.PSVersion
        Suites = $testFiles.Count
        Total = $result.TotalCount
        Passed = $result.PassedCount
        Failed = $result.FailedCount
        Skipped = $result.SkippedCount
        NotRun = $result.NotRunCount
        FailedContainers = $result.FailedContainersCount
        ReportDirectory = $reportRoot
    }
    $summary | ConvertTo-Json | Set-Content -LiteralPath (Join-Path $reportRoot 'summary.json') -Encoding UTF8
    Assert-OfflineTestResult -Result $result
    foreach ($entry in $provenance.Files) {
        if ((Get-FileHash -LiteralPath (Join-Path $productRoot $entry.Name) -Algorithm SHA256).Hash -cne $entry.SHA256) { throw 'Source changed during validation; the result is not a frozen-revision gate.' }
    }
    $summary
}
finally {
    if ($transcriptStarted) { Stop-Transcript | Out-Null }
    Write-Information -MessageData ('Offline validation evidence: {0}' -f $reportRoot) -InformationAction Continue
}