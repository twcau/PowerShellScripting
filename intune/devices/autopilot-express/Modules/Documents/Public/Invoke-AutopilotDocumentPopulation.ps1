<#
.SYNOPSIS
    Populate a DOCX through the fixed isolated worker, without application integration.
.DESCRIPTION
    Requires a previously verified local bundle and explicit output path. Parent never
    loads Open XML/ZXing; retains the local request as diagnostic job data. No Word,
    PDF, printing, tenant access, preference save or cleanup is performed.
.FILECREATED
    2026-10-24
.FILELASTUPDATED
    2026-10-24
#>
function Invoke-AutopilotDocumentPopulation {
    <#
    .SYNOPSIS
        Run structural population with an external 60-second default deadline.
    .PARAMETER Request
        Schema-one Job/Profile/TemplatePath/OutputPath/ReviewOnly dictionary.
    .PARAMETER DependencyRoot
        Previously approved feature-owned dependency cache, never auto-acquired here.
    .PARAMETER TimeoutSeconds
        External deadline; only the owned child may be stopped.
    .OUTPUTS
        Structured result/diagnostic; a populated DOCX is not a PDF or print.
    #>
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'None')]
    [OutputType([Collections.Specialized.OrderedDictionary])]
    param(
        [Parameter(Mandatory)][ValidateNotNull()][Collections.IDictionary]$Request,
        [Parameter(Mandatory)][ValidateNotNullOrEmpty()][string]$DependencyRoot,
        [ValidateRange(1, 3600)][int]$TimeoutSeconds = 60
    )
    $result = [ordered]@{ Status = 'Failed'; Diagnostic = ''; WorkerPid = 0; Output = $null; RequestPath = ''; WordLaunched = $false }
    $process = $null; $started = $false
    try {
        $root = Resolve-AutopilotDocumentLocalPath -Path $DependencyRoot
        $bundle = Test-AutopilotDocumentDependencyBundle -DependencyRoot $root
        if (-not $bundle.Valid) { $result.Status = 'BundleUnavailable'; $result.Diagnostic = $bundle.Diagnostic; return $result }
        $hostState = Get-AutopilotDocumentHostCapability
        if (-not $hostState.WorkerAvailable) { $result.Status = 'WorkerUnavailable'; return $result }
        $output = Resolve-AutopilotDocumentLocalPath -Path ([string]$Request['OutputPath'])
        $directory = Resolve-AutopilotDocumentLocalPath -Path (Split-Path -Parent $output)
        if (-not (Test-Path -LiteralPath $directory -PathType Container)) { throw 'Create an explicit feature-owned local job/output directory before population.' }
        $json = $Request | ConvertTo-Json -Depth 30 -Compress
        if ([Text.Encoding]::UTF8.GetByteCount($json) -gt 1048576) { throw 'Structural document request exceeds the one MiB limit.' }
        if (-not $PSCmdlet.ShouldProcess($output, 'Run isolated DOCX population; no Word or printing')) { $result.Status = 'WhatIf'; return $result }
        $result.RequestPath = Join-Path $directory ('document-request-{0}.json' -f [guid]::NewGuid().ToString('N'))
        $file = [IO.File]::Open($result.RequestPath, [IO.FileMode]::CreateNew, [IO.FileAccess]::Write, [IO.FileShare]::None)
        try { $bytes = [Text.Encoding]::UTF8.GetBytes($json); $file.Write($bytes, 0, $bytes.Length) } finally { $file.Dispose() }
        $start = [Diagnostics.ProcessStartInfo]::new(); $start.FileName = $hostState.WorkerExecutable
        $start.Arguments = '-NoProfile -NonInteractive -Sta -File "{0}" -DependencyRoot "{1}" -RequestPath "{2}"' -f (Join-Path $moduleRoot 'Workers/Populate-Document.ps1'), $root, $result.RequestPath
        $start.EnvironmentVariables['PSModulePath'] = Join-Path (Split-Path -Parent $hostState.WorkerExecutable) 'Modules'
        $start.UseShellExecute = $false; $start.CreateNoWindow = $true; $start.RedirectStandardOutput = $true; $start.RedirectStandardError = $true
        $process = [Diagnostics.Process]::new(); $process.StartInfo = $start
        $started = $process.Start()
        if (-not $started) { throw 'Cannot start the structural document worker.' }
        $result.WorkerPid = $process.Id
        $stdout = $process.StandardOutput.ReadToEndAsync(); $stderr = $process.StandardError.ReadToEndAsync()
        if (-not $process.WaitForExit($TimeoutSeconds * 1000)) { $process.Kill(); $null = $process.WaitForExit(5000); $result.Status = 'TimedOut'; return $result }
        $text = $stdout.GetAwaiter().GetResult(); $errorText = $stderr.GetAwaiter().GetResult()
        if ($text.Length -gt 65536 -or $errorText) { throw 'Unexpected structural worker output.' }
        $payload = $text | ConvertFrom-Json -ErrorAction Stop
        if ($payload.SchemaVersion -ne 1 -or $payload.WorkerPid -ne $process.Id) { throw 'Invalid structural worker protocol.' }
        if ($process.ExitCode -ne 0 -or $payload.Status -cne 'Passed') { $result.Diagnostic = [string]$payload.Diagnostic; return $result }
        if ($payload.Result.Status -cne 'Populated' -or $payload.Result.OutputPath -ine $output -or -not (Test-Path -LiteralPath $output -PathType Leaf)) { throw 'Worker did not publish the expected new DOCX.' }
        $result.Status = 'Populated'; $result.Output = $payload.Result
    }
    catch { $result.Diagnostic = 'Structural document population failed: {0}' -f $_.Exception.Message }
    finally {
        if ($null -ne $process) {
            try { if ($started -and -not $process.HasExited) { $process.Kill() } }
            catch { $result.Status = 'CleanupFailed'; $result.Diagnostic = 'Cannot stop the owned document worker; investigate its WorkerPid without terminating Word.' }
            finally { $process.Dispose() }
        }
    }
    return $result
}