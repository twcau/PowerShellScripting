<#
.SYNOPSIS
    Persist a bounded document receipt atomically, retaining the previous revision.
.DESCRIPTION
    Platform-only local JSON persistence. The delivery caller holds an exclusive
    per-receipt lock. Replacements preserve a uniquely named previous receipt;
    no operational record, generated document or unrelated file is removed.
.FILECREATED
    2026-10-24
.FILELASTUPDATED
    2026-10-24
#>
function Write-AutopilotDocumentReceipt {
    <#
    .SYNOPSIS
        Flush an intent or outcome before a delivery operation can continue.
    .PARAMETER Path
        Explicit local JSON leaf inside the caller's owned document job directory.
    .PARAMETER Receipt
        Version-one result with immutable job, record, cycle, scope and profile identity.
    .OUTPUTS
        None. Failure terminates before the caller may request delivery.
    #>
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'None')]
    param(
        [Parameter(Mandatory)][ValidateNotNullOrEmpty()][string]$Path,
        [Parameter(Mandatory)][Collections.IDictionary]$Receipt
    )
    $directory = Resolve-AutopilotDocumentLocalPath -Path (Split-Path -Parent $Path)
    if ([IO.Path]::GetExtension($Path) -ine '.json' -or [IO.Path]::GetFileName($Path) -match '[:*?]') { throw 'Receipt must be a local JSON leaf.' }
    $target = Join-Path $directory ([IO.Path]::GetFileName($Path))
    if ($Receipt['SchemaVersion'] -ne 1) { throw 'Unsupported document receipt schema.' }
    foreach ($key in @('JobId','RecordId','BuildCycleId')) {
        $parsed = [guid]::Empty
        if (-not [guid]::TryParse([string]$Receipt[$key], [ref]$parsed) -or $parsed -eq [guid]::Empty) { throw 'Receipt requires valid immutable identities.' }
    }
    if ($Receipt['Mode'] -cnotin @('Live','Demo') -or $Receipt['DocumentType'] -cnotin @('BirthCertificate','Checklist')) { throw 'Receipt scope/profile is invalid.' }
    $exists = Test-Path -LiteralPath $target
    if ($exists) {
        $file = Get-Item -LiteralPath $target -Force -ErrorAction Stop
        if ($file.PSIsContainer -or $file.Length -gt 65536 -or ($file.Attributes -band [IO.FileAttributes]::ReparsePoint)) { throw 'Existing receipt is not a safe bounded file.' }
        $previous = Get-Content -LiteralPath $target -Raw -Encoding UTF8 -ErrorAction Stop | ConvertFrom-Json -ErrorAction Stop
        foreach ($key in @('JobId','RecordId','BuildCycleId','Mode','TenantId','DocumentType')) {
            if ([string]$previous.$key -cne [string]$Receipt[$key]) { throw 'Receipt identity cannot be replaced by another job or profile.' }
        }
    }
    $bytes = [Text.UTF8Encoding]::new($false).GetBytes(($Receipt | ConvertTo-Json -Depth 12 -Compress))
    if ($bytes.Length -gt 65536) { throw 'Document receipt exceeds its bounded protocol.' }
    if (-not $PSCmdlet.ShouldProcess($target, 'Persist document intent/outcome and retain previous revision')) { return }
    $pending = '{0}.pending-{1}' -f $target, [guid]::NewGuid().ToString('N')
    $stream = [IO.File]::Open($pending, [IO.FileMode]::CreateNew, [IO.FileAccess]::Write, [IO.FileShare]::None)
    try { $stream.Write($bytes, 0, $bytes.Length); $stream.Flush($true) } finally { $stream.Dispose() }
    if ($exists) { [IO.File]::Replace($pending, $target, ('{0}.previous-{1}' -f $target, [guid]::NewGuid().ToString('N')), $true) }
    else { [IO.File]::Move($pending, $target) }
}