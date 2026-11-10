<#
.SYNOPSIS
    Supervise a fixed document-library test script outside the Graph runspace.
.DESCRIPTION
    PowerShell 5.1 or later. Only the newly owned child process may be terminated.
    No Word launch, encoded executable payload, execution-policy change or polling.
.FILECREATED
    2026-10-24
.FILELASTUPDATED
    2026-10-24
#>
function Invoke-AutopilotDocumentDependencySelfTest {
    <#
    .SYNOPSIS
        Verify the bundle, then run real in-memory DOCX and PNG round trips.
    .PARAMETER DependencyRoot
        Explicit local owned cache with a verified complete bundle.
    .PARAMETER TimeoutSeconds
        Positive bounded attempt deadline, defaulting to the approved 60 seconds.
    .OUTPUTS
        Ready/Status/Diagnostic and independent library probes, not Word readiness.
    #>
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'None')]
    [OutputType([System.Collections.Specialized.OrderedDictionary])]
    param(
        [Parameter(Mandatory)][ValidateNotNullOrEmpty()][string]$DependencyRoot,
        [ValidateRange(1, 3600)][int]$TimeoutSeconds = 60
    )
    $result = [ordered]@{ Ready = $false; Status = 'Failed'; Diagnostic = ''; Stage = 'Bundle'; ExitCode = $null; ErrorId = ''; OpenXmlRoundTrip = $false; Code128PngRoundTrip = $false; WordLaunched = $false; WorkerPid = 0 }
    $process = $null
    $started = $false
    try {
        $root = Resolve-AutopilotDocumentLocalPath -Path $DependencyRoot
        $bundle = Test-AutopilotDocumentDependencyBundle -DependencyRoot $root
        if (-not $bundle.Valid) { $result.Status = 'BundleUnavailable'; $result.Diagnostic = $bundle.Diagnostic; return $result }
        $hostState = Get-AutopilotDocumentHostCapability
        if (-not $hostState.WorkerAvailable) { $result.Status = 'WorkerUnavailable'; return $result }
        if (-not $PSCmdlet.ShouldProcess('Owned Windows PowerShell child; synthetic documents only', 'Run document library self-test')) { $result.Status = 'WhatIf'; return $result }
        $scriptPath = Join-Path $moduleRoot 'Workers/Test-DocumentLibraries.ps1'
        $start = [Diagnostics.ProcessStartInfo]::new()
        $start.FileName = $hostState.WorkerExecutable
        $start.Arguments = '-NoProfile -NonInteractive -Sta -File "{0}" -DependencyRoot "{1}"' -f $scriptPath, $root
        $start.EnvironmentVariables['PSModulePath'] = Join-Path (Split-Path -Parent $hostState.WorkerExecutable) 'Modules'
        $start.UseShellExecute = $false; $start.CreateNoWindow = $true
        $start.RedirectStandardOutput = $true; $start.RedirectStandardError = $true
        $process = [Diagnostics.Process]::new(); $process.StartInfo = $start
        $result.Stage = 'ProcessStart'
        if (-not $process.Start()) { throw 'Cannot start the isolated document probe.' }
        $started = $true
        $result.WorkerPid = $process.Id
        $result.Stage = 'WorkerExecution'
        $stdout = $process.StandardOutput.ReadToEndAsync(); $stderr = $process.StandardError.ReadToEndAsync()
        if (-not $process.WaitForExit($TimeoutSeconds * 1000)) {
            $result.Status = 'TimedOut'; $result.Diagnostic = 'Document dependency self-test exceeded its deadline.'
            if (-not $process.HasExited) { $process.Kill(); $null = $process.WaitForExit(5000) }
            return $result
        }
        $output = $stdout.GetAwaiter().GetResult(); $errorText = $stderr.GetAwaiter().GetResult()
        $result.ExitCode = $process.ExitCode
        if (-not [string]::IsNullOrWhiteSpace($errorText)) {
            $detail = [regex]::Replace($errorText.Substring(0, [Math]::Min(2048, $errorText.Length)), '[\x00-\x1F\x7F]+', ' ').Trim()
            if ($detail -match 'AuthorizationManager|UnauthorizedAccess|PSSecurityException|running scripts is disabled|not digitally signed') {
                $result.Status = 'ScriptAuthorizationFailed'
                $result.ErrorId = 'ScriptAuthorizationFailed'
                $result.Diagnostic = ('Windows rejected the document worker (exit {0}): {1} Review local file trust and effective execution policy; organisation controls may require administrator support. No policy change or elevation was attempted.' -f $result.ExitCode, $detail)
            }
            else { $result.Diagnostic = ('Document worker failed (exit {0}): {1}' -f $result.ExitCode, $detail) }
            return $result
        }
        $result.Stage = 'ResultValidation'
        if ($output.Length -gt 65536) { throw 'Document worker output exceeds the result limit.' }
        $payload = $output | ConvertFrom-Json -ErrorAction Stop
        if ($process.ExitCode -ne 0 -and $payload.Status -ceq 'Failed') { $result.Diagnostic = [string]$payload.Diagnostic; return $result }
        if ($process.ExitCode -ne 0) { throw 'Document worker exited unsuccessfully.' }
        $manifest = Get-AutopilotDocumentDependencyManifest
        if ($payload.SchemaVersion -ne 1 -or $payload.Status -cne 'Passed' -or $payload.BundleId -cne $manifest.BundleId -or $payload.WorkerPid -ne $process.Id -or $payload.OpenXmlRoundTrip -isnot [bool] -or -not $payload.OpenXmlRoundTrip -or $payload.Code128PngRoundTrip -isnot [bool] -or -not $payload.Code128PngRoundTrip -or $payload.WordLaunched -isnot [bool] -or $payload.WordLaunched) { throw 'Invalid document worker result contract.' }
        $result.Ready = $true; $result.Status = 'Passed'; $result.OpenXmlRoundTrip = $true; $result.Code128PngRoundTrip = $true
    }
    catch {
        $result.ErrorId = $_.FullyQualifiedErrorId
        $detail = [string]$_.Exception.Message
        $detail = [regex]::Replace($detail.Substring(0, [Math]::Min(2048, $detail.Length)), '[\x00-\x1F\x7F]+', ' ').Trim()
        $result.Diagnostic = ('Document dependency self-test failed at {0} (exit {1}): {2}' -f $result.Stage, $result.ExitCode, $detail)
    }
    finally {
        if ($null -ne $process) {
            try { if ($started -and -not $process.HasExited) { $process.Kill() } }
            catch { $result.Ready = $false; $result.Status = 'CleanupFailed'; $result.Diagnostic = 'Cannot stop the owned document probe. Record its WorkerPid for local investigation; do not terminate Word processes.' }
            finally { $process.Dispose() }
        }
    }
    return $result
}