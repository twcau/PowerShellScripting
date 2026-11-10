<#
.SYNOPSIS
    Initialise the result/receipt contract without claiming an output or print.
.DESCRIPTION
    Requires PowerShell 5.1 or later only. Receipt persistence and legal lifecycle
    transitions belong to the later delivery slice; this factory writes nothing.
.FILECREATED
    2026-10-23
.FILELASTUPDATED
    2026-10-23
#>
function New-AutopilotDocumentResult {
    <#
    .SYNOPSIS
        Initialise every result field before asynchronous delivery can update it.
    .PARAMETER Job
        Detached job identity and context; contains no live workflow references.
    .PARAMETER DocumentType
        Enabled profile owned by this job.
    .OUTPUTS
        Pending result dictionary suitable for a future durable receipt; not saved here.
    #>
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'None')]
    [OutputType([System.Collections.Specialized.OrderedDictionary])]
    param(
        [Parameter(Mandatory)][System.Collections.IDictionary]$Job,
        [Parameter(Mandatory)][ValidateSet('BirthCertificate', 'Checklist')][string]$DocumentType
    )
    if (-not $PSCmdlet.ShouldProcess('Detached document receipt only; no persistence or printing', 'Construct')) { return $null }
    if ($Job['SchemaVersion'] -ne 1 -or -not @($Job['Profiles'] | Where-Object { $_['DocumentType'] -ceq $DocumentType }).Count) { throw 'Result requires an enabled profile in a supported job.' }
    foreach ($key in @('JobId', 'RecordId', 'BuildCycleId')) {
        $parsed = [guid]::Empty
        if (-not [guid]::TryParse([string]$Job[$key], [ref]$parsed) -or $parsed -eq [guid]::Empty) { throw 'Result requires valid job and workflow identities.' }
    }
    return [ordered]@{
        SchemaVersion = 1; JobId = [string]$Job['JobId']; RecordId = [string]$Job['RecordId']; BuildCycleId = [string]$Job['BuildCycleId']
        Mode = [string]$Job['Mode']; TenantId = [string]$Job['TenantId']; DocumentType = $DocumentType
        Status = 'Pending'; PrintState = 'NotRequested'; AttemptCount = 0
        DocxPath = ''; PdfPath = ''; TemplateFingerprint = ''; ErrorCode = ''; Message = ''
        CreatedAtUtc = [string]$Job['CreatedAtUtc']; UpdatedAtUtc = [string]$Job['CreatedAtUtc']; PrintIntentAtUtc = ''
        DeliveryState = 'NotRequested'; OpenIntentAtUtc = ''; ManualSaveState = 'NotConfirmed'
        OutputSHA256 = ''; DefaultPrinter = ''; DeliveryMode = ''; ReviewOnly = $true
    }
}