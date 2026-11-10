<#
.SYNOPSIS
    Collect a completed document supervisor without blocking scanner input.
.DESCRIPTION
    Reads the bounded fixed protocol only after process exit. Does not replay a
    job, print, use Graph or change committed workflow records.
.FILECREATED
    2026-10-24
.FILELASTUPDATED
    2026-10-24
#>
function Receive-AutopilotDocumentJob {
    <#
    .SYNOPSIS
        Return Running immediately or collect and dispose a completed owned process.
    .PARAMETER Handle
        Live handle returned by Start-AutopilotDocumentJob, not deserialised job data.
    .OUTPUTS
        Status/results dictionary for the application's existing logging boundary.
    #>
    [CmdletBinding()]
    [OutputType([Collections.IDictionary], [Collections.Specialized.OrderedDictionary])]
    param([Parameter(Mandatory)][Collections.IDictionary]$Handle)
    if ($Handle['Status'] -notin @('Running','Preparing')) { return $Handle }
    if (-not $Handle['Process'].HasExited) { return [ordered]@{ Status = $Handle['Status']; JobId = $Handle['JobId'] } }
    try {
        $text = $Handle['StandardOutput'].GetAwaiter().GetResult()
        $null = $Handle['StandardError'].GetAwaiter().GetResult()
        if ($text.Length -gt 262144) { throw 'Document supervisor response exceeds its bound.' }
        $response = ConvertTo-AutopilotDocumentDictionary -Value ($text | ConvertFrom-Json -ErrorAction Stop)
        if ($response['SchemaVersion'] -ne 1 -or $response['Status'] -cnotin @('Completed','Failed')) { throw 'Invalid document supervisor response.' }
        $Handle.Status = 'Collected'
        return $response
    }
    catch { $Handle.Status = 'Collected'; return [ordered]@{ Status = 'Failed'; Diagnostic = $_.Exception.Message; Results = @() } }
    finally { $Handle['Process'].Dispose() }
}