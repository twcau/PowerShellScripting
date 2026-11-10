<#
.SYNOPSIS
    Supervise one fixed document child independently of the CLI input loop.
.DESCRIPTION
    Never loads SDKs or activates Word. Enforces an external deadline and exact
    owned Word cleanup after stopping its child. Writes bounded local job results;
    uncertain intents are retained and are never automatically replayed.
.FILECREATED
    2026-10-24
.FILELASTUPDATED
    2026-10-24
#>
#Requires -Version 5.1
[CmdletBinding()]
param([Parameter(Mandatory)][ValidateNotNullOrEmpty()][string]$RequestPath, [switch]$Prepare)
$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
[Console]::OutputEncoding = [Text.UTF8Encoding]::new($false)
$child = $null; $started = $false; $mutex = $null; $ownsMutex = $false; $lease = $null
$preparation = $null; $jobReceived = $false; $ownerProcess = $null; $waitHandles = @()
$summary = [ordered]@{ SchemaVersion = 1; Status = 'Failed'; Diagnostic = ''; Results = @(); Cleanup = 'NotRequired' }
try {
    Import-Module (Join-Path (Split-Path -Parent $PSScriptRoot) 'AutopilotExpress.Documents.psd1') -Force -ErrorAction Stop
    $file = Get-Item -LiteralPath $RequestPath -Force -ErrorAction Stop
    if ($file.Length -gt 1048576 -or ($file.Attributes -band [IO.FileAttributes]::ReparsePoint)) { throw 'Invalid supervised job file.' }
    $request = Get-Content -LiteralPath $RequestPath -Raw -Encoding UTF8 | ConvertFrom-Json -ErrorAction Stop
    if ($Prepare) {
        $preparation = $request
        $directory = & (Get-Module AutopilotExpress.Documents) { param($Path) Resolve-AutopilotDocumentLocalPath -Path $Path } $preparation.Directory
        $preparationGuid = [guid]::Empty
        if ($preparation.SchemaVersion -ne 1 -or $preparation.Owner -cne 'AutopilotExpress.Documents' -or [IO.Path]::GetFileName($directory) -cne $preparation.PreparationId -or [IO.Path]::GetFileName((Split-Path -Parent $directory)) -cne 'Preparation' -or -not [guid]::TryParseExact([string]$preparation.PreparationId, 'D', [ref]$preparationGuid)) { throw 'Invalid preparation directory identity.' }
        $ownerProcess = [Diagnostics.Process]::GetProcessById([int]$preparation.OwnerPid)
        if ($ownerProcess.StartTime.ToUniversalTime().Ticks -ne $preparation.OwnerStartTimeUtcTicks -or $ownerProcess.SessionId -ne [Diagnostics.Process]::GetCurrentProcess().SessionId) { throw 'Preparation owner identity changed.' }
        $excluded = @(Get-Process -Name WINWORD -ErrorAction SilentlyContinue | ForEach-Object Id)
        $start = [Diagnostics.ProcessStartInfo]::new()
        $start.FileName = Join-Path $env:WINDIR 'System32/WindowsPowerShell/v1.0/powershell.exe'
        $start.Arguments = '-NoProfile -NonInteractive -STA -File "{0}" -RequestPath "{1}" -Prepare' -f (Join-Path $PSScriptRoot 'Invoke-DocumentJob.ps1'), $RequestPath
        $start.UseShellExecute = $false; $start.CreateNoWindow = $true; $start.RedirectStandardInput = $true; $start.RedirectStandardOutput = $true; $start.RedirectStandardError = $true
        $start.StandardOutputEncoding = [Text.UTF8Encoding]::new($false); $start.StandardErrorEncoding = [Text.UTF8Encoding]::new($false)
        $start.EnvironmentVariables['PSModulePath'] = Join-Path $env:WINDIR 'System32/WindowsPowerShell/v1.0/Modules'
        $child = [Diagnostics.Process]::new(); $child.StartInfo = $start; $started = $child.Start()
        if (-not $started) { throw 'Prepared child did not start.' }
        $stdout = $child.StandardOutput.ReadToEndAsync(); $stderr = $child.StandardError.ReadToEndAsync()
        Add-Type -TypeDefinition @'
using System;
using System.Threading.Tasks;
namespace AutopilotDocumentPreparation {
    public static class Input {
        public static Task<string> ReadLine() {
            return Task.Run(() => Console.In.ReadLine());
        }
    }
}
'@ -ErrorAction Stop
        $inputTask = [AutopilotDocumentPreparation.Input]::ReadLine()
        foreach ($process in @($child,$ownerProcess)) {
            $handle = [Threading.ManualResetEvent]::new($false)
            $handle.SafeWaitHandle = [Microsoft.Win32.SafeHandles.SafeWaitHandle]::new($process.Handle, $false)
            $waitHandles += $handle
        }
        $signal = [Threading.WaitHandle]::WaitAny(@(([IAsyncResult]$inputTask).AsyncWaitHandle) + $waitHandles, 3600000)
        if ($signal -ne 0) { throw 'Unused preparation ended: owner/child exited or idle lifetime expired.' }
        $command = $inputTask.GetAwaiter().GetResult()
        if ($command -ceq 'Stop' -or [string]::IsNullOrWhiteSpace($command)) { $summary.Status = 'Completed'; return }
        $commandFile = Get-Item -LiteralPath $command -Force -ErrorAction Stop
        if ($commandFile.Length -gt 1048576 -or ($commandFile.Attributes -band [IO.FileAttributes]::ReparsePoint)) { throw 'Unsafe prepared job hand-off.' }
        $request = Get-Content -LiteralPath $command -Raw -Encoding UTF8 | ConvertFrom-Json -ErrorAction Stop
        if ($request.PreparationId -cne $preparation.PreparationId -or $request.DependencyRoot -ine $preparation.DependencyRoot) { throw 'Prepared job hand-off scope mismatch.' }
        $RequestPath = $command; $jobReceived = $true
    }
    $directory = & (Get-Module AutopilotExpress.Documents) { param($Path) Resolve-AutopilotDocumentLocalPath -Path $Path } $request.JobDirectory
    $validDirectory = & (Get-Module AutopilotExpress.Documents) { param($Path, $JobId) Test-AutopilotDocumentJobDirectory -Directory $Path -JobId $JobId } $directory ([guid]$request.Job.JobId)
    if (-not $validDirectory) { throw 'Supervised job directory identity mismatch.' }
    $leasePath = Join-Path $directory 'job.lock'
    if ((Test-Path -LiteralPath $leasePath) -and ((Get-Item -LiteralPath $leasePath -Force).Attributes -band [IO.FileAttributes]::ReparsePoint)) { throw 'Unsafe job lease.' }
    $lease = [IO.File]::Open($leasePath, [IO.FileMode]::OpenOrCreate, [IO.FileAccess]::ReadWrite, [IO.FileShare]::None)
    & (Get-Module AutopilotExpress.Documents) { param($Path, $JobId) Write-AutopilotDocumentLifecycle -Directory $Path -JobId $JobId -Active $true } $directory ([guid]$request.Job.JobId)
    $timeout = [int]$request.Job.Settings.WorkerTimeoutSeconds
    if ($timeout -lt 1 -or $timeout -gt 3600) { throw 'Invalid job deadline.' }
    $mutex = [Threading.Mutex]::new($false, ('Local\AutopilotExpress.Documents.{0}' -f [Security.Principal.WindowsIdentity]::GetCurrent().User.Value))
    try { $ownsMutex = $mutex.WaitOne([TimeSpan]::FromSeconds($timeout)) } catch [Threading.AbandonedMutexException] { $ownsMutex = $true }
    if (-not $ownsMutex) { throw 'Another document job exceeded the queue deadline; no delivery was requested.' }
    if (-not $Prepare) {
    $excluded = @(Get-Process -Name WINWORD -ErrorAction SilentlyContinue | ForEach-Object Id)
    $start = [Diagnostics.ProcessStartInfo]::new()
    $start.FileName = Join-Path $env:WINDIR 'System32/WindowsPowerShell/v1.0/powershell.exe'
    $start.Arguments = '-NoProfile -NonInteractive -STA -File "{0}" -RequestPath "{1}"' -f (Join-Path $PSScriptRoot 'Invoke-DocumentJob.ps1'), $RequestPath
    $start.UseShellExecute = $false; $start.CreateNoWindow = $true; $start.RedirectStandardOutput = $true; $start.RedirectStandardError = $true
    $start.StandardOutputEncoding = [Text.UTF8Encoding]::new($false); $start.StandardErrorEncoding = [Text.UTF8Encoding]::new($false)
    $start.EnvironmentVariables['PSModulePath'] = Join-Path $env:WINDIR 'System32/WindowsPowerShell/v1.0/Modules'
    $child = [Diagnostics.Process]::new(); $child.StartInfo = $start; $started = $child.Start()
    if (-not $started) { throw 'Document child did not start.' }
    $stdout = $child.StandardOutput.ReadToEndAsync(); $stderr = $child.StandardError.ReadToEndAsync()
    }
    else { $child.StandardInput.WriteLine($RequestPath); $child.StandardInput.Flush() }
    if (-not $child.WaitForExit($timeout * 1000)) { throw 'Document job exceeded its external deadline; delivery outcome may be uncertain.' }
    $text = $stdout.GetAwaiter().GetResult(); $null = $stderr.GetAwaiter().GetResult()
    if ($text.Length -gt 262144) { throw 'Document child protocol exceeded its bound.' }
    $response = $text | ConvertFrom-Json -ErrorAction Stop
    if ($response.SchemaVersion -ne 1 -or $response.WorkerPid -ne $child.Id -or $response.Status -cne 'Completed' -or $response.JobId -cne $request.Job.JobId -or $child.ExitCode -ne 0) { throw 'Document child failed or returned an invalid protocol.' }
    $summary.Status = 'Completed'; $summary.Results = @($response.Results)
    if (@($response.Results | Where-Object { $_.Status -eq 'Failed' }).Count) { $summary.Status = 'Failed' }
    if (@($response.Results | Where-Object { $_.PSObject.Properties.Name -contains 'Cleanup' -and $_.Cleanup -eq 'Uncertain' }).Count) { $summary.Cleanup = 'Uncertain' }
}
catch { $summary.Diagnostic = $_.Exception.Message }
finally {
    if ($started) {
        if ($Prepare -and -not $jobReceived -and -not $child.HasExited) { $child.StandardInput.WriteLine('Stop'); $child.StandardInput.Flush(); $null = $child.WaitForExit(5000) }
        if (-not $child.HasExited) { $child.Kill(); $null = $child.WaitForExit(5000) }
        if ($summary.Cleanup -ne 'Uncertain') { $summary.Cleanup = 'Complete' }
        if (-not $Prepare -or $jobReceived) {
        foreach ($ownerFile in @('WordOwner.json','BirthCertificate.word-owner.json','Checklist.word-owner.json')) {
            $ownershipPath = Join-Path $directory $ownerFile
            if (-not (Test-Path -LiteralPath $ownershipPath)) {
                if ($summary.Status -eq 'Failed' -and -not $Prepare -and -not (Test-Path -LiteralPath (Join-Path $directory 'WordOwner.json'))) { $summary.Cleanup = 'Uncertain' }
                continue
            }
            $owned = & (Get-Module AutopilotExpress.Documents) {
                param($Path, $JobId, $WorkerId, $Excluded)
                Stop-AutopilotDocumentOwnedWord -OwnershipPath $Path -JobId $JobId -WorkerPid $WorkerId -ExcludedProcessIds $Excluded
            } $ownershipPath ([guid]$request.Job.JobId) $child.Id $excluded
            if ($owned -eq 'Uncertain') { $summary.Cleanup = 'Uncertain'; $summary.Status = 'Failed' }
        }
        }
        if ($Prepare) {
            $owned = & (Get-Module AutopilotExpress.Documents) { param($Path,$Id,$Worker,$Excluded) Stop-AutopilotDocumentOwnedWord -OwnershipPath $Path -JobId $Id -WorkerPid $Worker -ExcludedProcessIds $Excluded } (Join-Path $preparation.Directory 'WordOwner.json') ([guid]$preparation.PreparationId) $child.Id $excluded
            if ($owned -eq 'Uncertain') { $summary.Cleanup = 'Uncertain'; $summary.Status = 'Failed' }
            if ($summary.Cleanup -eq 'Complete') {
                $entries = @(Get-ChildItem -LiteralPath $preparation.Directory -Force)
                if (-not @($entries | Where-Object { $_.PSIsContainer -or ($_.Attributes -band [IO.FileAttributes]::ReparsePoint) -or $_.Name -cnotin @('Preparation.json','Ready.json','Ready.json.pending','WordOwner.json','BirthCertificate.template.docx','Checklist.template.docx') }).Count) {
                    foreach ($entry in $entries) { [IO.File]::Delete($entry.FullName) }
                    [IO.Directory]::Delete($preparation.Directory, $false)
                    $parent = Split-Path -Parent $preparation.Directory
                    if (-not @(Get-ChildItem -LiteralPath $parent -Force).Count) { [IO.Directory]::Delete($parent, $false) }
                }
            }
        }
        $child.Dispose()
    }
    if ($ownsMutex) { $mutex.ReleaseMutex() }
    if ($null -ne $mutex) { $mutex.Dispose() }
    foreach ($handle in $waitHandles) { $handle.Dispose() }
    if ($null -ne $ownerProcess) { $ownerProcess.Dispose() }
    if ($null -ne $lease) {
        try {
            & (Get-Module AutopilotExpress.Documents) {
                param($Path, $JobId, $Summary)
                Write-AutopilotDocumentLifecycle -Directory $Path -JobId $JobId -Active:($Summary.Cleanup -eq 'Uncertain') -Result $Summary
            } $directory ([guid]$request.Job.JobId) $summary
        }
        catch { $summary.Status = 'Failed'; $summary.Diagnostic = 'Durable lifecycle save failed; retain all job files and receipts for review.' }
        finally { $lease.Dispose() }
    }
}
if ($summary.Status -eq 'Completed' -and $summary.Cleanup -eq 'Complete') {
    try {
        $summary.Housekeeping = & (Get-Module AutopilotExpress.Documents) {
            param($Path, $Request, $Summary)
            $job = ConvertTo-AutopilotDocumentDictionary -Value $Request.Job
            $outcome = ConvertTo-AutopilotDocumentDictionary -Value $Summary
            Complete-AutopilotDocumentJob -Directory $Path -Job $job -Summary $outcome -RetainReviewCopies:([bool]$Request.ReviewOnly)
        } $directory $request $summary
    }
    catch { $summary.Diagnostic = 'Documents generated; temporary cleanup deferred: {0}' -f $_.Exception.Message }
}
$summary | ConvertTo-Json -Depth 12 -Compress