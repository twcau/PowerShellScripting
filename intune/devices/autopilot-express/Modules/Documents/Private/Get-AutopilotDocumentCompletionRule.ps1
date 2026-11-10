<#
.SYNOPSIS
    Parse a document author's explicit tracked-step completion marker.
.DESCRIPTION
    Pure syntax validation; no template edits or completion evidence are inferred.
.FILECREATED
    2026-10-25
.FILELASTUPDATED
    2026-10-25
#>
function Get-AutopilotDocumentCompletionRule {
    <#
    .SYNOPSIS
        Require every listed tracked step, with the last step as the trigger.
    .PARAMETER Marker
        Complete cell text, for example {complete:C} or {complete:A,B,C}.
    .OUTPUTS
        Detached rule containing the exact marker, step identifiers and trigger.
    #>
    [CmdletBinding()]
    [OutputType([Collections.Specialized.OrderedDictionary])]
    param([Parameter(Mandatory)][ValidateNotNullOrEmpty()][string]$Marker)
    $match = [regex]::Match($Marker.Trim(), '^\{complete:([A-O](?:,[A-O])*)\}$', [Text.RegularExpressions.RegexOptions]::CultureInvariant)
    if (-not $match.Success) { throw 'Use {complete:C} or {complete:A,B,C}; only tracked steps A-O are allowed.' }
    $steps = [string[]]$match.Groups[1].Value.Split(',')
    if (@($steps | Select-Object -Unique).Count -ne $steps.Count) { throw 'Completion markers must not repeat a step.' }
    return [ordered]@{ Marker = $match.Value; StepIds = $steps; TriggerStepId = $steps[-1] }
}