<#
.SYNOPSIS
    Define the narrow Live document-tick evidence contract.
.DESCRIPTION
    Requires PowerShell 5.1 or later only; no external calls or state changes.
.FILECREATED
    2026-10-23
.FILELASTUPDATED
    2026-10-23
#>
function Test-AutopilotDocumentTick {
    <#
    .SYNOPSIS
        Require admissible evidence for every represented step, never an empty group.
    .PARAMETER Steps
        Current-cycle saved results, not historical attempts or handoff instructions.
    .PARAMETER RequiredStepIds
        Reviewed mapping's complete set of represented steps; empty means no tick.
    .PARAMETER Mode
        Demo cannot certify Live work, even if supplied synthetic results say Verified.
    .PARAMETER BuildCycleId
        Expected cycle; explicitly different evidence-cycle metadata is rejected.
    .PARAMETER CycleStartedAt
        Earliest admissible evidence timestamp for this cycle.
    .PARAMETER DispatchedAt
        Latest admissible evidence timestamp for this dispatch.
    .OUTPUTS
        Boolean. Broad workflow completion/override rules are deliberately not reused.
    #>
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        [Parameter(Mandatory)][System.Collections.IDictionary]$Steps,
        [AllowEmptyCollection()][string[]]$RequiredStepIds = @(),
        [Parameter(Mandatory)][ValidateSet('Demo', 'Live')][string]$Mode,
        [Parameter(Mandatory)][guid]$BuildCycleId,
        [Parameter(Mandatory)][DateTimeOffset]$CycleStartedAt,
        [Parameter(Mandatory)][DateTimeOffset]$DispatchedAt
    )
    if ($Mode -ne 'Live' -or -not $RequiredStepIds.Count -or $BuildCycleId -eq [guid]::Empty -or $CycleStartedAt -gt $DispatchedAt) { return $false }
    $seen = [System.Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
    foreach ($stepId in $RequiredStepIds) {
        if ([string]::IsNullOrWhiteSpace($stepId) -or -not $seen.Add($stepId) -or -not $Steps.Contains($stepId)) { return $false }
        $evidence = $Steps[$stepId]
        if ($evidence -isnot [System.Collections.IDictionary]) { return $false }
        if ($evidence['Success'] -isnot [bool] -or -not $evidence['Success'] -or $evidence['IsSimulated'] -isnot [bool] -or $evidence['IsSimulated']) { return $false }
        if ($evidence['CompletionState'] -cnotin @('Verified', 'TechnicianConfirmed') -or [string]::IsNullOrWhiteSpace([string]$evidence['ActionName'])) { return $false }
        if ($evidence['EvidenceKind'] -eq 'LegacyEvidence' -or ($evidence['Data'] -is [System.Collections.IDictionary] -and $evidence['Data']['Blocked'] -eq $true)) { return $false }
        if ($evidence.Contains('BuildCycleId') -and [string]$evidence['BuildCycleId'] -ine $BuildCycleId.ToString('D')) { return $false }
        $timestamp = [DateTimeOffset]::MinValue
        $value = $evidence['Timestamp']
        if ($value -is [DateTime] -or $value -is [DateTimeOffset]) { $value = $value.ToString('o') }
        if ($value -isnot [string] -or -not [DateTimeOffset]::TryParse($value, [Globalization.CultureInfo]::InvariantCulture, [Globalization.DateTimeStyles]::None, [ref]$timestamp)) { return $false }
        if ($timestamp -lt $CycleStartedAt -or $timestamp -gt $DispatchedAt) { return $false }
    }
    return $true
}