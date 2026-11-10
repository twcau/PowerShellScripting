<#
.SYNOPSIS
    Export one owned DOCX through an externally bounded Desktop STA Word child.
.DESCRIPTION
    Explicitly callable API, not integrated with dispatch. No document libraries load
    in the parent. No printing, viewer, Graph, network or preference actions occur.
    Real Word execution requires the separately approved technician environment.
.FILECREATED
    2026-10-24
.FILELASTUPDATED
    2026-10-24
#>
function Invoke-AutopilotDocumentPdfExport {
    <#
    .SYNOPSIS
        Publish a new local PDF only after verified export and owned cleanup.
    .PARAMETER Request
        SchemaVersion=1, JobId, JobDirectory, SourcePath, SourceSHA256, OutputPath.
        Source must be an already populated owned copy, never an original template.
    .PARAMETER TimeoutSeconds
        External worker deadline (default 60); owned cleanup adds at most two 5s waits.
    .OUTPUTS
        Exported/Failed/TimedOut/Unavailable receipt; never a physical print claim.
    #>
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'None')]
    [OutputType([Collections.Specialized.OrderedDictionary])]
    param(
        [Parameter(Mandatory)][ValidateNotNull()][Collections.IDictionary]$Request,
        [ValidateRange(1, 3600)][int]$TimeoutSeconds = 60
    )
    $result = [ordered]@{ Status = 'Failed'; Diagnostic = ''; WorkerPid = 0; WordLaunchAttempted = $false; Cleanup = 'NotStarted'; Pdf = $null; OutputPath = ''; RequestPath = ''; OwnershipPath = '' }
    $process = $null; $started = $false; $workerStopped = $true; $existingWordIds = @(); $jobGuid = [guid]::Empty; $pending = ''; $output = ''
    try {
        if ($Request['SchemaVersion'] -ne 1 -or -not [guid]::TryParse([string]$Request['JobId'], [ref]$jobGuid) -or $jobGuid -eq [guid]::Empty) { throw 'Invalid PDF job identity or schema.' }
        $root = Resolve-AutopilotDocumentLocalPath -Path ([string]$Request['JobDirectory'])
        $output = [string]$Request['OutputPath']; $leaf = [IO.Path]::GetFileName($output)
        if ($leaf.IndexOfAny([IO.Path]::GetInvalidFileNameChars()) -ge 0 -or [IO.Path]::GetExtension($leaf) -ine '.pdf' -or (Resolve-AutopilotDocumentLocalPath -Path ([IO.Path]::GetDirectoryName($output))) -ine $root -or (Test-Path -LiteralPath $output)) { throw 'PDF output must be a new file inside the explicit local job directory.' }
        $hostState = Get-AutopilotDocumentHostCapability
        if (-not $hostState.WorkerAvailable -or -not $hostState.WordRegistrationDetected) { $result.Status = 'Unavailable'; $result.Diagnostic = 'Desktop worker/.NET/Word registration unavailable; core workflow remains available.'; return $result }
        if (-not $PSCmdlet.ShouldProcess($output, 'Launch isolated desktop Word export; no printing or network save')) { $result.Status = 'WhatIf'; return $result }
        $token = [guid]::NewGuid().ToString('N')
        $pending = Join-Path $root ('pdf-pending-{0}.pdf' -f $token)
        $result.RequestPath = Join-Path $root ('pdf-request-{0}.json' -f $token)
        $result.OwnershipPath = Join-Path $root ('word-owner-{0}.json' -f $token)
        $workerRequest = [ordered]@{ SchemaVersion = 1; JobId = $jobGuid.ToString('D'); JobDirectory = $root; SourcePath = $Request['SourcePath']; SourceSHA256 = $Request['SourceSHA256']; PendingPdfPath = $pending; OwnershipPath = $result.OwnershipPath }
        $workerRequest.ExpectedPageCount = [int]$Request['ExpectedPageCount']
        $bytes = [Text.Encoding]::UTF8.GetBytes(($workerRequest | ConvertTo-Json -Compress))
        if ($bytes.Length -gt 16384) { throw 'PDF request exceeds the bounded protocol limit.' }
        $file = [IO.File]::Open($result.RequestPath, [IO.FileMode]::CreateNew, [IO.FileAccess]::Write, [IO.FileShare]::None)
        try { $file.Write($bytes, 0, $bytes.Length); $file.Flush($true) } finally { $file.Dispose() }
        $existingWordIds = @(Get-Process -Name WINWORD -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Id)
        $start = [Diagnostics.ProcessStartInfo]::new(); $start.FileName = $hostState.WorkerExecutable
        $start.Arguments = '-NoProfile -NonInteractive -Sta -File "{0}" -RequestPath "{1}"' -f (Join-Path $moduleRoot 'Workers/Export-DocumentPdf.ps1'), $result.RequestPath
        $start.EnvironmentVariables['PSModulePath'] = Join-Path (Split-Path -Parent $hostState.WorkerExecutable) 'Modules'
        $start.UseShellExecute = $false; $start.CreateNoWindow = $true; $start.RedirectStandardOutput = $true; $start.RedirectStandardError = $true
        $start.StandardOutputEncoding = [Text.Encoding]::UTF8; $start.StandardErrorEncoding = [Text.Encoding]::UTF8
        $process = [Diagnostics.Process]::new(); $process.StartInfo = $start; $started = $process.Start()
        if (-not $started) { throw 'Cannot start the isolated Word worker.' }
        $result.WorkerPid = $process.Id; $result.WordLaunchAttempted = $true; $result.Cleanup = 'Uncertain'
        $stdout = $process.StandardOutput.ReadToEndAsync(); $stderr = $process.StandardError.ReadToEndAsync()
        if (-not $process.WaitForExit($TimeoutSeconds * 1000)) { $result.Status = 'TimedOut'; $result.Diagnostic = 'Word export exceeded its external deadline; dispatch remains committed.'; return $result }
        $text = $stdout.GetAwaiter().GetResult(); $errorText = $stderr.GetAwaiter().GetResult()
        if ($text.Length -gt 65536 -or $errorText) { throw 'Unexpected Word worker output.' }
        $payload = $text | ConvertFrom-Json -ErrorAction Stop
        if ($payload.SchemaVersion -ne 1 -or $payload.WorkerPid -ne $process.Id -or $payload.JobId -ine $jobGuid.ToString('D') -or $payload.Result.WordLaunchAttempted -isnot [bool]) { throw 'Invalid Word worker result protocol.' }
        $result.WordLaunchAttempted = $payload.Result.WordLaunchAttempted
        if (-not $result.WordLaunchAttempted) { $result.Cleanup = 'NotStarted' }
        if ($process.ExitCode -ne 0 -or $payload.Status -cne 'Passed' -or $payload.Result.Status -cne 'Exported' -or $payload.Result.Cleanup -cne 'Complete' -or -not $result.WordLaunchAttempted) { $result.Diagnostic = [string]$payload.Result.Diagnostic; return $result }
        $result.Pdf = Get-AutopilotDocumentPdfInfo -Path $pending
        if ($result.Pdf.SHA256 -cne $payload.Result.Pdf.SHA256 -or $result.Pdf.Length -ne $payload.Result.Pdf.Length) { throw 'Word worker PDF differs from its result digest.' }
        $result.Status = 'Exported'
    }
    catch { $result.Status = 'Failed'; $result.Diagnostic = 'Isolated PDF export failed: {0}' -f $_.Exception.Message }
    finally {
        if ($null -ne $process) {
            try { if ($started -and -not $process.HasExited) { $process.Kill(); $null = $process.WaitForExit(5000) } }
            catch { $workerStopped = $false; $result.Status = 'Failed'; $result.Cleanup = 'Uncertain'; $result.Diagnostic = 'Cannot stop the owned Word worker; no PDF was published.' }
            finally { $process.Dispose() }
        }
        if ($started -and $result.WordLaunchAttempted) {
            $result.Cleanup = Stop-AutopilotDocumentOwnedWord -OwnershipPath $result.OwnershipPath -JobId $jobGuid -WorkerPid $result.WorkerPid -ExcludedProcessIds $existingWordIds
            if (-not $workerStopped) { $result.Cleanup = 'Uncertain' }
            if ($result.Cleanup -eq 'Uncertain') { if ($result.Status -eq 'Exported') { $result.Status = 'Failed' }; $result.Diagnostic = '{0} Word cleanup is uncertain; investigate the ownership record, never terminate Word by name.' -f $result.Diagnostic }
        }
    }
    if ($result.Status -eq 'Exported') {
        try { [IO.File]::Move($pending, $output); $result.OutputPath = $output }
        catch { $result.Status = 'Failed'; $result.Diagnostic = 'PDF publication failed or destination was occupied; existing files were not overwritten.' }
    }
    return $result
}