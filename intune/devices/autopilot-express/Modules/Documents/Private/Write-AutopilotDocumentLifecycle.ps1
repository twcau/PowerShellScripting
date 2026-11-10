<#
.SYNOPSIS
    Atomically retain owned job activity and terminal supervisor outcomes.
.DESCRIPTION
    Caller holds job.lock. Keeps previous revisions; uncertain Word ownership and
    open-review requests remain excluded from automatic reversible asset expiry.
.FILECREATED
    2026-10-24
.FILELASTUPDATED
    2026-10-24
#>
function Write-AutopilotDocumentLifecycle {
    <#
    .SYNOPSIS
        Persist a small job-owned lifecycle without touching operational records.
    .PARAMETER Directory
        Exclusive-leased GUID job directory, never an arbitrary file destination.
    .PARAMETER JobId
        Expected detached job identity.
    .PARAMETER Active
        Keep true while running or whenever cleanup remains uncertain.
    .PARAMETER Result
        Fixed supervisor outcome. Null means running, not a successful terminal job.
    .OUTPUTS
        None. Failed persistence raises; previous metadata is retained.
    #>
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'None')]
    param(
        [Parameter(Mandatory)][ValidateNotNullOrEmpty()][string]$Directory,
        [Parameter(Mandatory)][guid]$JobId,
        [Parameter(Mandatory)][bool]$Active,
        [Collections.IDictionary]$Result
    )
    $root = Resolve-AutopilotDocumentLocalPath -Path $Directory
    if (-not (Test-AutopilotDocumentJobDirectory -Directory $root -JobId $JobId)) { throw 'Lifecycle job directory mismatch.' }
    $path = Join-Path $root 'job-lifecycle.json'
    if (Test-Path -LiteralPath $path) {
        $file = Get-Item -LiteralPath $path -Force -ErrorAction Stop
        if ($file.Length -gt 262144 -or ($file.Attributes -band [IO.FileAttributes]::ReparsePoint)) { throw 'Unsafe lifecycle file.' }
        $prior = Get-Content -LiteralPath $path -Raw -Encoding UTF8 | ConvertFrom-Json -ErrorAction Stop
        if ($prior.Owner -cne 'AutopilotExpress.Documents' -or $prior.JobId -cne $JobId.ToString('D')) { throw 'Foreign lifecycle identity.' }
    }
    $state = if ($Active) { 'Running' } elseif ($null -ne $Result -and $Result['Status'] -eq 'Completed') { 'Succeeded' } else { 'Failed' }
    $openRequested = $null -ne $Result -and @($Result['Results'] | Where-Object { $_.Status -eq 'OpenRequested' }).Count -gt 0
    $metadata = [ordered]@{ SchemaVersion = 1; Owner = 'AutopilotExpress.Documents'; JobId = $JobId.ToString('D'); Active = $Active; ChecklistOpenRequested = [bool]$openRequested; State = $state; UpdatedAtUtc = [DateTimeOffset]::UtcNow.ToString('o'); DisposableAssets = @(); Result = $Result }
    $bytes = [Text.UTF8Encoding]::new($false).GetBytes(($metadata | ConvertTo-Json -Depth 14 -Compress))
    if ($bytes.Length -gt 65536) { throw 'Lifecycle exceeds the cleanup metadata bound.' }
    if (-not $PSCmdlet.ShouldProcess($path, 'Persist owned lifecycle with reversible previous revision')) { return }
    $pending = Join-Path $root ('lifecycle-pending-{0}.json' -f [guid]::NewGuid().ToString('N'))
    $stream = [IO.File]::Open($pending, [IO.FileMode]::CreateNew, [IO.FileAccess]::Write, [IO.FileShare]::None)
    try { $stream.Write($bytes, 0, $bytes.Length); $stream.Flush($true) } finally { $stream.Dispose() }
    if (Test-Path -LiteralPath $path) { [IO.File]::Replace($pending, $path, ('{0}.previous-{1}' -f $path, [guid]::NewGuid().ToString('N'))) }
    else { [IO.File]::Move($pending, $path) }
}