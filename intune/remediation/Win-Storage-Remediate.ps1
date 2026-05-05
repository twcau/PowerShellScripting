# region 0 - Header
<#
.SYNOPSIS
Win-Storage Intune Remediation - storage and disk cleanup passes used by Intune remediation scripts.

.DESCRIPTION
This script provides a collection of safe, configurable cleanup passes (user temp, global temp,
browser caches, Delivery Optimization, DISM component store cleanup and more). It is designed for
use as an Intune remediation script or run interactively by an administrator. The core functions are
dry-run aware and include safety checks to avoid destructive actions on protected or system paths.

.PARAMETER DryRun
Runs the script in a non-destructive mode where removal actions are only logged and not performed.

.PARAMETER SKIP_SLOW_IO
When set, the script avoids blocking or slow I/O operations so unit tests run quickly.

.PARAMETER ForceDISMWhenPending
When set, force DISM component store cleanup to run even if a pending reboot is detected.

.PARAMETER Verbosity
Controls logging verbosity. Allowed values: Silent, Normal, Verbose.

.EXAMPLE

.\Win-Storage-Remediate.ps1 -DryRun

.COPYRIGHT
Copyright (c) 2025, Michael Harris. All rights reserved.
#>

#endregion

# region 0A - Params
param(
    [switch]
    $DryRun,
    [switch]
    $SKIP_SLOW_IO,
    [switch]
    $ForceDISMWhenPending,
    [switch]
    $PreserveTempLog,
    [ValidateSet('Silent', 'Normal', 'Verbose')]
    [string]
    $Verbosity = 'Normal',
    [switch]
    $CleanMgrOnly,
    [switch]
    $Estimate
)

# Normalise switch parameters once so downstream helpers can rely on simple
# boolean semantics even when the script is AST-loaded or invoked via tests.
$DryRun = [bool]$DryRun
$SKIP_SLOW_IO = [bool]$SKIP_SLOW_IO
$ForceDISMWhenPending = [bool]$ForceDISMWhenPending
$PreserveTempLog = [bool]$PreserveTempLog
$CleanMgrOnly = [bool]$CleanMgrOnly
$Estimate = [bool]$Estimate

# Propagate SKIP_SLOW_IO into the environment so helper code can check it consistently
if ($SKIP_SLOW_IO) { $env:SKIP_SLOW_IO = '1' } else { if ($env:SKIP_SLOW_IO) { Remove-Item -Path Env:\SKIP_SLOW_IO -ErrorAction SilentlyContinue } }

# Prevent static analyzer warnings for parameters that are referenced indirectly
$null = $ForceDISMWhenPending, $SKIP_SLOW_IO

# endregion

# region 0B - Command variables

# Configure verbosity for Write-Verbose
if ($Verbosity -eq 'Verbose') { $VerbosePreference = 'Continue' } else { $VerbosePreference = 'SilentlyContinue' }
# Early verbose buffer and wrapper: capture verbose messages emitted before logging helpers are defined.
# Messages are buffered and flushed into the temporary log by Write-CustomMessage when it runs.
if (-not $script:VerboseBuffer) { $script:VerboseBuffer = @() }
function Write-Verbose {
    param([Parameter(ValueFromPipeline = $true, Position = 0)][string]$Message)
    process {
        try { if ($Message) { $script:VerboseBuffer += $Message } } catch {}
        & Microsoft.PowerShell.Utility\Write-Verbose -Message $Message
    }
}
# Wrapper around Start-Process to prevent destructive external invocations during DryRun.
# This function shadows the builtin Start-Process within the script scope and forwards
# to the real cmdlet for non-blocked processes. It specifically prevents starting
# cleanmgr.exe when DryRun or WhatIf are active and logs a DRYRUN line instead.
function Start-Process {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param(
        [Parameter(Position = 0, Mandatory = $true)][string]$FilePath,
        [Parameter(Position = 1)][Object]$ArgumentList,
        [switch]$NoNewWindow,
        [switch]$Wait,
        [switch]$PassThru,
        [string]$WindowStyle,
        [string]$WorkingDirectory
    )
    process {
        try {
            $whatIfRequested = $false
            if ($PSBoundParameters.ContainsKey('WhatIf')) { $whatIfRequested = $true }
            if ($whatIfRequested -or $DryRun) {
                if ($FilePath -match '(?i)cleanmgr(\.exe)?$') {
                    try { Write-CustomMessage ("DRYRUN: Would start process: {0} {1}" -f $FilePath, ($ArgumentList -join ' ')) -Level INFO } catch { }
                    if ($PassThru) { return [pscustomobject]@{ ExitCode = 0 } }
                    return
                }
            }
        }
        catch { }

        # Forward to the real Start-Process for non-intercepted commands
        $splat = @{
            FilePath = $FilePath
        }
        if ($PSBoundParameters.ContainsKey('ArgumentList')) { $splat.ArgumentList = $ArgumentList }
        if ($PSBoundParameters.ContainsKey('NoNewWindow')) { $splat.NoNewWindow = $NoNewWindow }
        if ($PSBoundParameters.ContainsKey('Wait')) { $splat.Wait = $Wait }
        if ($PSBoundParameters.ContainsKey('PassThru')) { $splat.PassThru = $PassThru }
        if ($PSBoundParameters.ContainsKey('WindowStyle')) { $splat.WindowStyle = $WindowStyle }
        if ($PSBoundParameters.ContainsKey('WorkingDirectory')) { $splat.WorkingDirectory = $WorkingDirectory }

        return & Microsoft.PowerShell.Management\Start-Process @splat
    }
}
# endregion

# region 0C - Configuration parameters

# Logging parameters
$scriptName = 'Win-Storage-Remediate'
$logFile = "$env:TEMP\${scriptName}.log"
$transcriptStarted = $false

# Safety/config flags for heavy cleanup behavior
# If existing temp log is larger than this (MB), archive it at startup
$tempLogSizeThresholdMB = 5
# If existing temp log is older than this (days), archive it at startup
$tempLogAgeDays = 7
# Max time to spend in recursive cleanup loops before breaking out
$MaxCleanupDurationMinutes = 20
# No-op reference for static analysis tools when the variable is unused in trimmed flows
$null = $MaxCleanupDurationMinutes

# Per-activity preferences
# Toggle these to enable or disable individual cleanup activities between Regions 2A and 7C.
# $true = activity will be performed, $false = activity will not be performed.
# Higher-risk overrides remain disabled unless explicitly enabled.
$Pref_RemoveOldUserProfiles = $true
$Pref_OneDriveAndBrowserCache = $true
$Pref_DeliveryOptimizationAndWU = $true
$Pref_StorageSense = $true
$Pref_DISMComponentStoreCleanup = $true
# Allow an explicit override to force DISM to run even when a pending reboot is detected
$Pref_ForceDISMWhenPendingOverride = $false
$Pref_EventLogCleanup = $true
$Pref_UserTempCleanup = $true
$Pref_GlobalTempCleanup = $true
$Pref_CleanMgrPrep = $true
$Pref_RunCleanMgr = $true
# Preference to optionally remove C:\Windows.old (disabled by default; dangerous)
$Pref_RemoveWindowsOld = $false

# Basic parameters
# Remove user profile where the profile has not logged into the device within the last X days
$userProfileRetentionDays = 180
# Remove OneDrive file caches where the file has not used within the last X days
$oneDriveCleanupThreshold = 30

# Suppress 'assigned but not used' warnings by referencing prefs in a no-op way
$null = $Pref_RemoveOldUserProfiles, $Pref_OneDriveAndBrowserCache, $Pref_DeliveryOptimizationAndWU, $Pref_StorageSense, $Pref_DISMComponentStoreCleanup, $Pref_EventLogCleanup, $Pref_UserTempCleanup, $Pref_GlobalTempCleanup, $Pref_CleanMgrPrep, $Pref_RunCleanMgr, $Pref_ForceDISMWhenPendingOverride, $Pref_RemoveWindowsOld

# The per-activity prefs are referenced directly where they gate each region below.
# Keep the $null suppression above to avoid false positive warnings from static analysis in trimmed flows.

# cleanmgr.exe - locations to target during this step
$cleanupTypeSelection = @(
    'Downloaded Program Files', 'GameNewsFiles', 'GameStatisticsFiles', 'GameUpdateFiles',
    'Memory Dump Files', 'Old ChkDsk Files', 'Recycle Bin',
    'System error memory dump files', 'System error minidump files',
    'Temporary Files', 'Temporary Sync Files', 'Update Cleanup',
    'Upgrade Discarded Files', 'Windows Error Reporting Archive Files',
    'Windows Error Reporting System Archive Files',
    'Windows ESD installation files', 'Windows Upgrade Log Files',
    'Internet Cache Files'
)

# Log cleanup - Logs to be cleared during htis step (e.g. NLTmpMnt mount points)
$logsToClear = @(
    # Standard Windows Logs
    'Application',
    'System',
    'Security',
    'Setup',
    'Forwarded Events',

    # PowerShell Logs
    'Microsoft-Windows-PowerShell/Operational',

    # Windows Update Logs
    'Microsoft-Windows-WindowsUpdateClient/Operational',

    # Remote Desktop Services Logs
    'Microsoft-Windows-TerminalServices-LocalSessionManager/Operational',
    'Microsoft-Windows-TerminalServices-RemoteConnectionManager/Operational',

    # Group Policy Logs
    'Microsoft-Windows-GroupPolicy/Operational',

    # Hardware Events
    'HardwareEvents',

    # Windows Defender Logs
    'Microsoft-Windows-Windows Defender/Operational',

    # Task Scheduler Logs
    'Microsoft-Windows-TaskScheduler/Operational',

    # Network Logs
    'Microsoft-Windows-NetworkProfile/Operational',
    'Microsoft-Windows-NetworkProvider/Operational',

    # Other Common Logs
    'Microsoft-Windows-User Profile Service/Operational',
    'Microsoft-Windows-Eventlog/Operational',
    'Microsoft-Windows-Diagnostics-Performance/Operational',
    'Microsoft-Windows-Application-Experience/Program-Inventory',
    'Microsoft-Windows-Application-Experience/Program-Telemetry'
)

# Path cleanup - Configurable skip patterns to avoid removing mounted images, reparse points and other special folders
$skipPathPatterns = @(
    # OneDrive and sync caches
    '(?i)\\Microsoft\\OneDrive\\',
    '(?i)\\OneDrive(\\b|\\s|\\.|$)',
    '(?i)\\OneDrive.*\\logs(\\|$)',
    '(?i)\\OneDrive.*\\listsync',
    '(?i)\\OneDrive.*\\sync[_-]?engine',
    '(?i)\\Microsoft\\.FilesOnDemand\\',
    '(?i)\\FileSyncFSCache\\.db',
    '(?i)SettingsDatabase\\.db',
    '(?i)SyncEngine|SyncEngineDb|SyncEngineCache',
    # OneDrive DB and sidecars
    '(?i)\\.db(-shm|-wal)?$',
    '(?i)\\.otc(-shm|-wal)?$',
    # requested OneDrive file types
    '(?i)\\.odl$',
    '(?i)\\.odlgz$',
    '(?i)\\.aodl$',
    # Office Document Cache
    '(?i)\\OfficeFileCache(\\|$)',
    # Windows apps / mounts / Program Files
    '(?i)\\NLTmpMnt(\\|$)',
    '(?i)\\WindowsApps(\\|$)',
    '(?i)\\Program Files( x86)?(\\|$)',
    '(?i)\\\bmountpoint\b|\\\bmounted\b|\\\bmnt\\',
    # Core system files and folders
    '(?i)^[a-zA-Z]:\\\\pagefile\\.sys$',
    '(?i)^[a-zA-Z]:\\\\hiberfil\\.sys$',
    '(?i)^[a-zA-Z]:\\\\swapfile\\.sys$',
    '(?i)\\\\System Volume Information(\\|$)',
    '(?i)\\\\\$Recycle\\.Bin(\\|$)',
    '(?i)\\\\Windows(\\|$)',
    '(?i)\\\\WinSxS(\\|$)',
    '(?i)\\\\Windows\\\\Installer(\\|$)',
    '(?i)\\\\ProgramData(\\|$)',
    '(?i)\\\\ProgramData\\\\Microsoft\\\\Crypto\\\\RSA\\\\MachineKeys(\\|$)',
    # Registry hives
    '(?i)\\\\System32\\\\config(\\|$)',
    '(?i)\\\\(SAM|SECURITY|SOFTWARE|SYSTEM|DEFAULT)$',
    '(?i)\\\\NTUSER\\.DAT(\\b|$)',
    # Event logs and traces
    '(?i)\\\\winevt\\\\Logs\\\\.*\\.evtx$',
    '(?i)\\.evtx$',
    '(?i)\\.etl$',
    '(?i)\\\\ProgramData\\\\Microsoft\\\\Windows\\\\WER(\\|$)',
    # Generic DB/lock/cache files (be conservative)
    '(?i)\\.ldb$',
    '(?i)\\.sqlite$',
    '(?i)\\.db-shm$',
    '(?i)\\.db-wal$',
    '(?i)\\.log$',
    '(?i)\\.dat$',
    # Crypto / keys
    '(?i)\\\\Microsoft\\\\Crypto(\\|$)',
    # Windows Update data
    '(?i)\\\\Windows\\\\SoftwareDistribution(\\|$)'
)
# Intentionally reference configuration variables to satisfy static analysers when unused in some code paths.
# These are consumed by Test-IsSkipPath; keep a no-op reference to avoid false positives from linters.
$null = $skipPathPatterns

# endregion

# region 0D - Functions
function Write-CustomMessage {
    param (
        [string]$Message,
        [ValidateSet('INFO', 'WARN', 'ERROR')]
        [string]$Level = 'INFO'
    )
    $timestamp = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
    $logEntry = "$timestamp - $Level - $Message"
    try {
        $tempLogPath = $null
        $mainLogPath = $null
        if (-not [string]::IsNullOrWhiteSpace($tempLogFile)) { $tempLogPath = $tempLogFile }
        if (-not [string]::IsNullOrWhiteSpace($logFile)) { $mainLogPath = $logFile }

        # Flush any buffered verbose messages that occurred before logging helpers were in place.
        if ($script:VerboseBuffer -and $script:VerboseBuffer.Count -gt 0) {
            foreach ($vb in $script:VerboseBuffer) {
                $vbEntry = "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') - INFO - $vb"
                if ($tempLogPath -and (Test-Path -Path $tempLogPath)) { Add-Content -Path $tempLogPath -Value $vbEntry -ErrorAction SilentlyContinue }
                elseif ($mainLogPath) { Add-Content -Path $mainLogPath -Value $vbEntry -ErrorAction SilentlyContinue }
            }
            $script:VerboseBuffer = @()
        }
        # Always append a canonical entry to the temporary log first when present. If the temp log has
        # already been removed (for example during consolidation), fall back to appending into the main
        # log so messages are not lost.
        if ($tempLogPath -and (Test-Path -Path $tempLogPath)) {
            Add-Content -Path $tempLogPath -Value $logEntry -ErrorAction SilentlyContinue
        }
        elseif ($mainLogPath) {
            # Ensure main log directory exists
            try {
                $mainLogDirectory = Split-Path -Path $mainLogPath -Parent
                if ($mainLogDirectory -and -not (Test-Path -Path $mainLogDirectory)) { New-Item -Path $mainLogDirectory -ItemType Directory -Force | Out-Null }
            }
            catch {}
            Add-Content -Path $mainLogPath -Value $logEntry -ErrorAction SilentlyContinue
        }

        # Emit minimal host output only when explicitly running in Verbose mode.
        if ($Verbosity -eq 'Verbose') {
            # Call the original Write-Verbose cmdlet directly to avoid any wrapper recursion
            & Microsoft.PowerShell.Utility\Write-Verbose -Message $logEntry
        }

        # When running a DryRun, surface a concise, non-PII host-visible summary for
        # important messages so interactive users know what the script would do.
        try {
            if ($DryRun) {
                $hostShow = $false
                # Always show explicit DRYRUN lines or "Would ..." style messages
                if ($Message -match '^DRYRUN:' -or $Message -match '\bWould\b' -or $Message -match '\bWould delete\b' -or $Message -match '\bWould remove\b') { $hostShow = $true }
                # Also surface high-level summaries and probe results during DryRun
                if ($Message -match 'Deleted \d+ items' -or $Message -match 'Skipped \d+ items' -or $Message -match 'Probe delta' -or $Message -match 'Initial free space' -or $Message -match '^Estimate:') { $hostShow = $true }
                if ($hostShow) { Write-Output ("DRYRUN: {0}" -f $Message) }
            }
        }
        catch {
            # Non-fatal - fail silently to avoid hiding the real log behaviour
        }
    }
    catch {
        # Best-effort: if temp log can't be written, surface a verbose diagnostic (won't be sent to Intune in normal mode)
        Write-Verbose "Failed to write to temporary log file: $_"
    }
}

# Wrapper for the built-in Write-Verbose to ensure verbose messages are also
# recorded into the temporary run log. This captures diagnostic output that
# would otherwise only appear on the host stream and not in the temp/archive
# logs. The wrapper calls the original cmdlet by fully-qualifying its module
# path to avoid recursion.
function Write-Verbose {
    [CmdletBinding()]
    param(
        [Parameter(ValueFromPipeline = $true, Position = 0)]
        [string]$Message
    )
    process {
        try {
            if ($Message) { Write-CustomMessage -Message $Message -Level INFO }
        }
        catch {
            # Non-fatal: fall through to emit host verbose output
        }
        # Call the original cmdlet directly to preserve host/verbosity semantics
        & Microsoft.PowerShell.Utility\Write-Verbose -Message $Message
    }
}

function Merge-Log {
    <#
    Append the temporary log into the main log file and remove the temp file.
    If the temp file is locked or missing, save it to a timestamped file in the archive directory.
    #>
    param()

    # Fast-path for test environments: when SKIP_SLOW_IO is set we avoid blocking I/O operations
    if ($env:SKIP_SLOW_IO) {
        Write-CustomMessage "SKIP_SLOW_IO set: Merge-Log fast-path active; simulating successful merge for tests." -Level INFO
        return $true
    }

    try {
        # Stop transcript only if we actually started one earlier. Stop-Transcript can throw when
        # the host is not currently transcribing (observed on some hosts) so handle that explicitly
        try {
            if ($transcriptStarted) { Stop-Transcript -ErrorAction Stop }
        }
        catch {
            # Not fatal for Merge-Log — record verbose and continue. This avoids Merge-Log failing
            # because Stop-Transcript reported "The host is not currently transcribing."
            Write-Verbose "Stop-Transcript returned an error but will be ignored: $_"
        }
        if (-not (Test-Path -Path $tempLogFile)) {
            Write-CustomMessage "No temporary log file found to merge: $tempLogFile"
            return $true
        }

        $backoff = @(2, 4, 8)
        foreach ($s in $backoff) {
            try {
                $tempStream = [System.IO.File]::Open($tempLogFile, [System.IO.FileMode]::Open, [System.IO.FileAccess]::Read, [System.IO.FileShare]::ReadWrite)
                $destStream = [System.IO.File]::Open($logFile, [System.IO.FileMode]::OpenOrCreate, [System.IO.FileAccess]::Write, [System.IO.FileShare]::ReadWrite)
                try {
                    $destStream.Seek(0, [System.IO.SeekOrigin]::End) | Out-Null
                    $buffer = New-Object byte[] 8192
                    while (($read = $tempStream.Read($buffer, 0, $buffer.Length)) -gt 0) {
                        $destStream.Write($buffer, 0, $read)
                    }
                    $destStream.Flush()
                }
                finally {
                    $tempStream.Close(); $destStream.Close()
                }

                $destSize = (Get-Item -Path $logFile -ErrorAction SilentlyContinue).Length
                if ($destSize -gt 0) {
                    if (-not $DryRun -and -not $PreserveTempLog) { Remove-Item -Path $tempLogFile -Force -ErrorAction Stop }
                    Write-CustomMessage "Temporary log file successfully merged into $logFile"
                    # ensure per-run archive placeholder is reset; Save-MainLogArchive will set it when archiving
                    $script:LastPerRunArchive = $null
                    return $true
                }
                else {
                    Write-CustomMessage "WARNING: Destination log file size unchanged after merge; preserving temp log: $tempLogFile"
                    return $false
                }
            }
            catch {
                Write-Verbose "Merge attempt failed: $_"
                Start-Sleep -Seconds $s
            }
        }

        # Final fallback: copy temp log to archive directory
        try {
            if (-not (Test-Path -Path $archiveDirectory)) { New-Item -Path $archiveDirectory -ItemType Directory -Force | Out-Null }
            $uniqueLogFile = Join-Path -Path $archiveDirectory -ChildPath "${scriptName}_temp_$(Get-Date -Format 'yyyyMMdd_HHmmss').log"
            Copy-Item -Path $tempLogFile -Destination $uniqueLogFile -Force -ErrorAction Stop
            Write-CustomMessage "Logs saved to fallback archive: $uniqueLogFile"
            return $true
        }
        catch {
            Write-CustomMessage "ERROR: Failed to save temp logs to fallback archive: $_"
            try {
                $diag = Join-Path -Path $archiveDirectory -ChildPath "${scriptName}_merge_error_$(Get-Date -Format 'yyyyMMdd_HHmmss').diag.txt"
                "Merge failure: $_" | Out-File -FilePath $diag -Encoding utf8 -Force
                Write-CustomMessage "Wrote diagnostic file: $diag"
            }
            catch { Write-Verbose "Failed to write diagnostic file: $_" }
            return $false
        }
    }
    catch {
        Write-CustomMessage "ERROR: Merge-Log encountered an exception: $_"
        return $false
    }
}

function Clear-DeliveryOptimizationCache {
    <#
    Safely clear Delivery Optimization download cache located under
    C:\Windows\SoftwareDistribution\DeliveryOptimization or the Delivery Optimization service
    caches. This is a non-rebooting, low-risk cleanup: we only remove files under
    the Download folder and guard against removing log/archive paths used by this script.
    #>
    try {
        if ($env:SKIP_SLOW_IO) {
            Write-CustomMessage "SKIP_SLOW_IO set: Skipping Delivery Optimization cache enumeration." -Level INFO
            return
        }
        $doPaths = @(
            "$env:SystemRoot\SoftwareDistribution\DeliveryOptimization",
            "$env:SystemRoot\SoftwareDistribution\Download",
            "$env:SystemRoot\System32\DeliveryOptimization"
        )
        foreach ($p in $doPaths) {
            if (-not (Test-Path -Path $p)) { continue }
            Write-CustomMessage "Clearing Delivery Optimization cache at: $p"
            # Use pruned enumerator so skip/protected branches are not traversed
            Get-SafeChildItems -Path $p | ForEach-Object {
                if (Test-IsProtectedPath -PathToTest $_.FullName) { continue }
                try {
                    if ($DryRun) { Write-CustomMessage "DRYRUN: Would delete DO item: $($_.FullName)" }
                    else { Remove-Item -Path $_.FullName -Recurse -Force -ErrorAction Stop; Write-CustomMessage "Deleted DO item: $($_.FullName)" }
                }
                catch { Write-CustomMessage "WARNING: Failed to delete DO item $($_.FullName): $($_.Exception.Message)" }
            }
        }
    }
    catch {
        Write-CustomMessage "ERROR: Failed to clear Delivery Optimization cache. $_"
    }
}

function Clear-OneDriveUserCache {
    <#
    Clear per-user OneDrive caches that are safe to remove (for example, temporary caches in
    %LocalAppData%\Microsoft\OneDrive). We avoid touching user documents or config files.
    #>
    try {
        $oneDriveCache = "$env:LOCALAPPDATA\Microsoft\OneDrive"
        if (-not (Test-Path -Path $oneDriveCache)) {
            Write-CustomMessage "OneDrive cache path not found: $oneDriveCache"
            return
        }

        Write-CustomMessage "Scanning OneDrive cache folder: $oneDriveCache"

        # Use an explicit stack-based directory walker to avoid Get-ChildItem -Recurse following reparse points
        $dirs = New-Object System.Collections.Stack
        $dirs.Push((Get-Item -LiteralPath $oneDriveCache -ErrorAction SilentlyContinue).FullName)

        while ($dirs.Count -gt 0) {
            $current = $dirs.Pop()
            try {
                $entries = Get-ChildItem -LiteralPath $current -Force -ErrorAction SilentlyContinue
            }
            catch {
                Write-CustomMessage ("WARNING: Failed to enumerate {0}: {1}" -f $current, $_)
                continue
            }

            foreach ($entry in $entries) {
                # If container, decide whether to recurse
                if ($entry.PSIsContainer) {
                    # Skip directories that are reparse points (junctions, mount points, symlinks)
                    if ($entry.Attributes -band [System.IO.FileAttributes]::ReparsePoint) {
                        Write-CustomMessage "Skipping reparse point in OneDrive cache: $($entry.FullName)"
                        continue
                    }
                    # Also skip any protected paths (logs, archives)
                    if (Test-IsProtectedPath -PathToTest $entry.FullName) {
                        Write-CustomMessage "Skipping protected directory in OneDrive cache: $($entry.FullName)"
                        continue
                    }
                    # Push directory for later enumeration
                    $dirs.Push($entry.FullName)
                }
                else {
                    # File entry
                    if (Test-IsProtectedPath -PathToTest $entry.FullName) { continue }
                    try {
                        if ($DryRun) { Write-CustomMessage "DRYRUN: Would delete OneDrive cache file: $($entry.FullName)" }
                        else { Remove-Item -Path $entry.FullName -Force -ErrorAction Stop; Write-CustomMessage "Deleted OneDrive cache file: $($entry.FullName)" }
                    }
                    catch { Write-CustomMessage "WARNING: Could not delete OneDrive cache file $($entry.FullName): $($_.Exception.Message)" }
                }
            }
        }
    }
    catch {
        Write-CustomMessage "ERROR: Failed to clear OneDrive cache. $_"
    }
}

function Test-FileLock {
    param (
        [string]$FilePath
    )
    try {
        $fileStream = [System.IO.File]::Open($FilePath, 'Open', 'ReadWrite', 'None')
        $fileStream.Close()
        return $false
    }
    catch {
        return $true
    }
}

function Clear-BrowserCache {
    <#
    Safely clear browser caches for common browsers (Edge, Chrome, Firefox) per-user.
    We only remove cache directories and avoid touching user profiles or settings.
    #>
    try {
        Clear-BrowserCacheAllUsers
    }
    catch {
        Write-CustomMessage "ERROR: Failed to clear browser caches. $_"
    }
}

# Read-only probe to gather candidate sizes for common cleanup areas. Returns a hashtable of sizes in bytes.
function Get-ProbeSnapshot {
    param(
        [string[]]$PathsToProbe = @(),
        [switch]$IgnorePrune
    )
    # Return hashtable: Path -> PSCustomObject { Bytes, MB, GB }
    $snapshot = @{}
    foreach ($p in $PathsToProbe) {
        try {
            if (-not (Test-Path -Path $p)) {
                $snapshot[$p] = [pscustomobject]@{ Bytes = 0; MB = 0; GB = 0 }
                continue
            }
            $total = 0
            if ($IgnorePrune) {
                # For trusted probe roots we intentionally ignore pruning to get accurate sizes.
                try {
                    Get-ChildItem -LiteralPath $p -File -Recurse -Force -ErrorAction SilentlyContinue | ForEach-Object { $total += ([int64]$_.Length) }
                }
                catch { Write-Verbose ("Probe (IgnorePrune): failed to recurse {0}: {1}" -f $p, $_) }
            }
            else {
                Get-SafeChildItems -Path $p -FilesOnly | ForEach-Object {
                    try {
                        if (Test-IsProtectedPath -PathToTest $_.FullName) { return }
                        $fi = Get-Item -LiteralPath $_.FullName -ErrorAction SilentlyContinue
                        if ($fi) { $total += [int64]$fi.Length }
                    }
                    catch { Write-Verbose "Probe: failed to stat $($_.FullName): $_" }
                }
            }
            $mb = [math]::Round($total / 1MB, 2)
            $gb = [math]::Round($total / 1GB, 2)
            $snapshot[$p] = [pscustomobject]@{ Bytes = [int64]$total; MB = $mb; GB = $gb }
        }
        catch {
            $snapshot[$p] = [pscustomobject]@{ Bytes = 0; MB = 0; GB = 0 }
        }
    }
    return $snapshot
}

# Helper: estimate Recycle Bin size via Shell.Application (falls back to 0 if not available)
function Get-RecycleBinSize {
    try {
        # Attempt COM approach first; this may not be available under SYSTEM or constrained hosts
        try {
            $shell = New-Object -ComObject Shell.Application
            $recycle = $shell.Namespace(0xA)
            if ($recycle) {
                $sizeObj = $recycle.ExtendedProperty('Size') 2>$null
                if ($sizeObj) {
                    [int64]$size = 0
                    if ([Int64]::TryParse($sizeObj.ToString(), [ref]$size)) { return $size }
                }
            }
        }
        catch {
            Write-Verbose "COM RecycleBin size query failed: $_"
        }

        # Fallback: enumerate per-user recycle bin folders (best-effort). This is conservative and may under-report.
        $total = [int64]0
        try {
            $users = Get-ChildItem -Path 'C:\Users' -Directory -ErrorAction SilentlyContinue | Where-Object { $_.Name -notin @('Default', 'Default User', 'Public', 'All Users') }
            foreach ($u in $users) {
                try {
                    $rbPath = Join-Path -Path $u.FullName -ChildPath '$Recycle.Bin'
                    if (-not (Test-Path -Path $rbPath)) { continue }
                    Get-ChildItem -Path $rbPath -Recurse -File -ErrorAction SilentlyContinue | ForEach-Object { $total += ([int64]($_.Length -as [int64])) }
                }
                catch { Write-Verbose "RecycleBin fallback enumeration failed for $($u.FullName): $_" }
            }
        }
        catch { Write-Verbose "RecycleBin fallback enumeration failed: $_" }

        return $total
    }
    catch {
        Write-Verbose "Get-RecycleBinSize encountered an unexpected error: $_"
        return 0
    }
}

# Helper: robustly export and clear event logs using wevtutil and return structured result
function Export-EventLog {
    param(
        [Parameter(Mandatory = $true)][string]$LogName,
        [Parameter(Mandatory = $true)][string]$ExportPath
    )
    try {
        $wevt = Join-Path -Path $env:WINDIR -ChildPath 'System32\wevtutil.exe'
        if (-not (Test-Path -Path $wevt)) { return @{ Success = $false; ExitCode = -1; Output = "wevtutil not found" } }

        # Ensure target directory exists
        $dir = Split-Path -Path $ExportPath -Parent
        if (-not (Test-Path -Path $dir)) { New-Item -Path $dir -ItemType Directory -Force | Out-Null }

        # Call wevtutil with native invocation to avoid Start-Process tokenisation issues
        # Some channel names include spaces or characters that cause wevtutil to return exit code 87.
        # Try a straightforward invocation first, then a quoted single-argument fallback.
        $output = & $wevt epl "$LogName" "$ExportPath" 2>&1
        $exit = $LASTEXITCODE
        if ($exit -ne 0 -and $output -match 'The parameter is incorrect') {
            Write-Verbose "wevtutil epl failed with parameter error for $LogName; retrying with cmd /c quoted args"
            try {
                # Use cmd /c with a single string argument to preserve quoting for problematic channel names
                $escapedWevt = $wevt
                # Build the command string by concatenation to avoid parser issues
                $cmdString = '"' + $escapedWevt + '" epl "' + $LogName + '" "' + $ExportPath + '"'
                $output = & cmd /c $cmdString 2>&1
                $exit = $LASTEXITCODE
            }
            catch { $output = "Fallback invocation exception: $_"; $exit = -1 }
        }
        return @{ Success = ($exit -eq 0); ExitCode = $exit; Output = $output }
    }
    catch {
        return @{ Success = $false; ExitCode = -1; Output = "Exception: $_" }
    }
}

function Clear-SoftwareDistributionDownload {
    <#
    Target the SoftwareDistribution\Download folder where Windows Update stores downloaded packages.
    This is a non-rebooting clean: we only remove files from the Download folder and skip archive/log paths.
    #>
    try {
        Clear-WindowsUpdateDownloadCache
    }
    catch {
        Write-CustomMessage "ERROR: Failed to clear SoftwareDistribution download folder. $_"
    }
}

function Clear-DeliveryOptimizationAdvanced {
    <#
    Additional Delivery Optimization cleanup: clear ContentCache and related leftover folders that may remain.
    This function intentionally avoids stopping services and only removes safe file content.
    #>
    try {
        if ($env:SKIP_SLOW_IO) {
            Write-CustomMessage "SKIP_SLOW_IO set: Skipping advanced Delivery Optimization enumeration." -Level INFO
            return
        }
        $doContent = Join-Path -Path $env:ProgramData -ChildPath 'DeliveryOptimization'
        if (-not (Test-Path -Path $doContent)) { Write-CustomMessage "DeliveryOptimization content folder not found: $doContent"; return }
        Write-CustomMessage "Clearing Delivery Optimization advanced content at: $doContent"
        # Pruned enumeration
        Get-SafeChildItems -Path $doContent | ForEach-Object {
            if (Test-IsProtectedPath -PathToTest $_.FullName) { continue }
            try {
                if ($DryRun) { Write-CustomMessage "DRYRUN: Would delete DO advanced item: $($_.FullName)" }
                else { Remove-Item -Path $_.FullName -Recurse -Force -ErrorAction Stop; Write-CustomMessage "Deleted DO advanced item: $($_.FullName)" }
            }
            catch { Write-CustomMessage "WARNING: Failed to delete DO advanced item $($_.FullName): $($_.Exception.Message)" }
        }
    }
    catch {
        Write-CustomMessage "ERROR: Failed to perform advanced Delivery Optimization cleanup. $_"
    }
}

function Resolve-FileLock {
    param (
        [Parameter(Mandatory = $true)][string]$DirectoryPath
    )
    # Use a safe stack-based walker that prunes branches matching skip/protected patterns
    if (-not (Test-Path -Path $DirectoryPath)) { return }
    $stack = New-Object System.Collections.Stack
    $stack.Push((Get-Item -LiteralPath $DirectoryPath -ErrorAction SilentlyContinue))
    while ($stack.Count -gt 0) {
        $node = $stack.Pop()
        if (-not $node) { continue }
        try {
            if ($node.PSIsContainer) {
                # If the directory itself should be skipped or protected, don't enter it
                if (Test-IsSkipPath -PathToTest $node.FullName -ErrorAction SilentlyContinue) {
                    try {
                        if ($VerbosePreference -eq 'Continue') { Write-CustomMessage "Pruned skip-path branch: $($node.FullName)" }
                        else {
                            if ($script:PrunedBranches -is [System.Collections.Generic.HashSet[string]]) {
                                if ($script:PrunedBranches.Add($node.FullName)) { Write-CustomMessage "Pruned skip-path branch: $($node.FullName)" }
                            }
                            else {
                                if (-not ($script:PrunedBranches -contains $node.FullName)) { $script:PrunedBranches.Add($node.FullName); Write-CustomMessage "Pruned skip-path branch: $($node.FullName)" }
                            }
                        }
                    }
                    catch { Write-CustomMessage "Pruned skip-path branch: $($node.FullName)" }
                    continue
                }

                if (Test-IsProtectedPath -PathToTest $node.FullName -ErrorAction SilentlyContinue) {
                    try {
                        if ($script:PrunedBranches -is [System.Collections.Generic.HashSet[string]]) {
                            if ($script:PrunedBranches.Add($node.FullName)) { Write-CustomMessage "Pruned protected branch: $($node.FullName)" }
                        }
                        else {
                            if (-not ($script:PrunedBranches -contains $node.FullName)) { $script:PrunedBranches.Add($node.FullName); Write-CustomMessage "Pruned protected branch: $($node.FullName)" }
                        }
                    }
                    catch { Write-CustomMessage "Pruned protected branch: $($node.FullName)" }
                    continue
                }

                # Push children for further inspection
                $children = Get-ChildItem -LiteralPath $node.FullName -Force -ErrorAction SilentlyContinue
                foreach ($child in $children) { $stack.Push($child) }
            }
            else {
                # file node: check lock status if helper exists
                try {
                    if (Get-Command -Name Test-FileLock -ErrorAction SilentlyContinue) {
                        if (Test-FileLock -FilePath $node.FullName) { Write-CustomMessage "WARNING: File is locked: $($node.FullName). Skipping." }
                        else { Write-CustomMessage "File is not locked: $($node.FullName)." }
                    }
                }
                catch { Write-Verbose "Resolve-FileLock: failed checking file lock for $($node.FullName): $_" }
            }
        }
        catch {
            Write-CustomMessage "WARNING: Error enumerating $($node.FullName): $_"
        }
    }
}

# Safe enumerator that walks a directory tree using an explicit stack and prunes branches
function Get-SafeChildItems {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [switch]$FilesOnly
    )
    if (-not (Test-Path -Path $Path)) { return }
    $stack = New-Object System.Collections.Stack
    $stack.Push((Get-Item -LiteralPath $Path -ErrorAction SilentlyContinue))
    while ($stack.Count -gt 0) {
        $node = $stack.Pop()
        if (-not $node) { continue }
        try {
            if ($node.PSIsContainer) {
                if (Test-IsSkipPath -PathToTest $node.FullName -ErrorAction SilentlyContinue) {
                    try {
                        if ($script:PrunedBranches -is [System.Collections.Generic.HashSet[string]]) {
                            if ($script:PrunedBranches.Add($node.FullName)) { Write-CustomMessage "Pruned skip-path branch: $($node.FullName)" }
                        }
                        else {
                            if (-not ($script:PrunedBranches -contains $node.FullName)) { $script:PrunedBranches.Add($node.FullName); Write-CustomMessage "Pruned skip-path branch: $($node.FullName)" }
                        }
                    }
                    catch { Write-CustomMessage "Pruned skip-path branch: $($node.FullName)" }
                    continue
                }
                if (Test-IsProtectedPath -PathToTest $node.FullName -ErrorAction SilentlyContinue) {
                    try {
                        if ($script:PrunedBranches -is [System.Collections.Generic.HashSet[string]]) {
                            if ($script:PrunedBranches.Add($node.FullName)) { Write-CustomMessage "Pruned protected branch: $($node.FullName)" }
                        }
                        else {
                            if (-not ($script:PrunedBranches -contains $node.FullName)) { $script:PrunedBranches.Add($node.FullName); Write-CustomMessage "Pruned protected branch: $($node.FullName)" }
                        }
                    }
                    catch { Write-CustomMessage "Pruned protected branch: $($node.FullName)" }
                    continue
                }

                # Push children: directories first to ensure depth-first style
                $children = Get-ChildItem -LiteralPath $node.FullName -Force -ErrorAction SilentlyContinue
                foreach ($child in $children) {
                    $stack.Push($child)
                }
            }
            else {
                if ($FilesOnly) { Write-Output $node } else { Write-Output $node }
            }
        }
        catch {
            Write-CustomMessage "WARNING: Error walking $($node.FullName): $_"
        }
    }
}

function Invoke-WithRetry {
    param (
        [scriptblock]$ScriptBlock,
        [int]$MaxRetries = 3,
        [int]$RetryDelay = 5
    )
    for ($attempt = 1; $attempt -le $MaxRetries; $attempt++) {
        try {
            $result = & $ScriptBlock
            return $result
        }
        catch {
            if ($attempt -lt $MaxRetries) {
                Write-CustomMessage "Attempt $attempt failed. Retrying in $RetryDelay seconds..."
                Start-Sleep -Seconds $RetryDelay
            }
            else {
                Write-CustomMessage "ERROR: All $MaxRetries attempts failed. $_"
                throw
            }
        }
    }
}

function Get-UserProfileCleanupCandidates {
    <#
    Enumerate stale user profiles using Win32_UserProfile so cleanup removes both
    filesystem content and profile registration metadata.
    #>
    [CmdletBinding()]
    [OutputType('System.Object[]')]
    param(
        [int]$RetentionDays = $userProfileRetentionDays
    )

    $cutoffDate = (Get-Date).AddDays(-$RetentionDays)
    $profilesRoot = ([IO.Path]::GetFullPath((Join-Path -Path $env:SystemDrive -ChildPath 'Users'))).TrimEnd('\')
    $excludedProfileNames = @('Administrator', 'All Users', 'Default', 'Default User', 'defaultuser0', 'Public', 'WDAGUtilityAccount')
    $candidates = New-Object System.Collections.Generic.List[object]

    try {
        $profiles = Get-CimInstance -ClassName Win32_UserProfile -ErrorAction Stop
    }
    catch {
        Write-CustomMessage ("ERROR: Failed to enumerate Win32_UserProfile instances. {0}" -f $_.Exception.Message)
        return @()
    }

    foreach ($userProfile in $profiles) {
        try {
            if (-not $userProfile.LocalPath) { continue }

            $resolvedPath = ([IO.Path]::GetFullPath($userProfile.LocalPath)).TrimEnd('\\')
            if (-not $resolvedPath.StartsWith($profilesRoot, [System.StringComparison]::OrdinalIgnoreCase)) { continue }

            $profileName = Split-Path -Path $resolvedPath -Leaf
            if ($profileName -in $excludedProfileNames) { continue }
            if ($userProfile.Special -or $userProfile.Loaded) { continue }

            $refCount = 0
            if ($null -ne $userProfile.RefCount) { $refCount = [int]$userProfile.RefCount }
            if ($refCount -gt 0) { continue }

            $lastUseTime = $null
            if ($userProfile.LastUseTime) {
                try { $lastUseTime = [datetime]$userProfile.LastUseTime } catch { $lastUseTime = $null }
            }

            if (-not $lastUseTime) {
                Write-CustomMessage ("Skipping user profile with no LastUseTime metadata: {0}" -f $resolvedPath) -Level WARN
                continue
            }

            if ($lastUseTime -ge $cutoffDate) { continue }

            $candidates.Add([pscustomobject]@{
                    CimInstance = $userProfile
                    LocalPath   = $resolvedPath
                    ProfileName = $profileName
                    SID         = $userProfile.SID
                    LastUseTime = $lastUseTime
                    RefCount    = $refCount
                }) | Out-Null
        }
        catch {
            Write-CustomMessage ("WARNING: Failed to assess candidate user profile {0}. {1}" -f $userProfile.LocalPath, $_.Exception.Message) -Level WARN
        }
    }

    return @($candidates | Sort-Object -Property LastUseTime, LocalPath)
}

function Invoke-OldUserProfileCleanup {
    <#
    Remove stale user profiles via Win32_UserProfile so registry and profile state
    are cleaned up together with on-disk content.
    #>
    [CmdletBinding(SupportsShouldProcess = $true)]
    [OutputType('System.Collections.Hashtable')]
    param(
        [int]$RetentionDays = $userProfileRetentionDays
    )

    $candidates = @(Get-UserProfileCleanupCandidates -RetentionDays $RetentionDays)
    $summary = @{
        CandidateCount   = $candidates.Count
        WouldRemoveCount = 0
        RemovedCount     = 0
        SkippedCount     = 0
        FailedCount      = 0
    }

    if ($candidates.Count -eq 0) {
        Write-CustomMessage ("No removable user profiles were identified using Win32_UserProfile older than {0} days." -f $RetentionDays)
        return $summary
    }

    foreach ($candidate in $candidates) {
        $targetDescription = "{0} (SID={1}; LastUseTime={2})" -f $candidate.LocalPath, $candidate.SID, ($candidate.LastUseTime.ToString('yyyy-MM-dd HH:mm:ss'))

        if ($DryRun) {
            Write-CustomMessage ("DRYRUN: Would remove user profile via Win32_UserProfile: {0}" -f $targetDescription)
            $summary.WouldRemoveCount++
            continue
        }

        if ($PSCmdlet -and -not $PSCmdlet.ShouldProcess($candidate.LocalPath, 'Remove stale user profile')) {
            Write-CustomMessage ("Skipped user profile removal because ShouldProcess declined: {0}" -f $targetDescription) -Level INFO
            $summary.SkippedCount++
            continue
        }

        try {
            Invoke-WithRetry -MaxRetries 2 -RetryDelay 2 -ScriptBlock {
                Remove-CimInstance -InputObject $candidate.CimInstance -ErrorAction Stop
                return $true
            } | Out-Null
            Write-CustomMessage ("Removed user profile via Win32_UserProfile: {0}" -f $targetDescription)
            $summary.RemovedCount++
        }
        catch {
            Write-CustomMessage ("ERROR: Failed to remove user profile via Win32_UserProfile: {0}. {1}" -f $targetDescription, $_.Exception.Message)
            $summary.FailedCount++
        }
    }

    if ($DryRun) {
        Write-CustomMessage ("User profile cleanup dry run completed. CandidateCount={0}; WouldRemoveCount={1}; SkippedCount={2}; FailedCount={3}" -f $summary.CandidateCount, $summary.WouldRemoveCount, $summary.SkippedCount, $summary.FailedCount)
    }
    else {
        Write-CustomMessage ("User profile cleanup completed. CandidateCount={0}; RemovedCount={1}; SkippedCount={2}; FailedCount={3}" -f $summary.CandidateCount, $summary.RemovedCount, $summary.SkippedCount, $summary.FailedCount)
    }

    return $summary
}

function Set-CleanMgrCategories {
    <#
    Configure the requested CleanMgr VolumeCaches categories in one place so both the
    standard flow and CleanMgrOnly mode use the same gating and dry-run semantics.
    #>
    [CmdletBinding(SupportsShouldProcess = $true)]
    [OutputType('System.Collections.Hashtable')]
    param(
        [string[]]$Types = $cleanupTypeSelection
    )

    $summary = @{
        ConfiguredCount     = 0
        MissingCount        = 0
        WouldConfigureCount = 0
        FailedCount         = 0
    }

    foreach ($keyName in $Types) {
        $keyPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\$keyName"
        if (-not (Test-Path $keyPath)) {
            Write-CustomMessage ("Skipped missing CleanMgr category: {0}." -f $keyName)
            $summary.MissingCount++
            continue
        }

        if ($DryRun) {
            Write-CustomMessage ("DRYRUN: Would configure CleanMgr category: {0}" -f $keyName)
            $summary.WouldConfigureCount++
            continue
        }

        if ($PSCmdlet -and -not $PSCmdlet.ShouldProcess($keyPath, 'Set StateFlags0001 to 2')) {
            Write-CustomMessage ("Skipped CleanMgr configuration because ShouldProcess declined: {0}" -f $keyName) -Level INFO
            continue
        }

        try {
            Set-ItemProperty -Path $keyPath -Name 'StateFlags0001' -Value 2 -Force -ErrorAction Stop
            Write-CustomMessage ("Configured CleanMgr for {0}." -f $keyName)
            $summary.ConfiguredCount++
        }
        catch {
            Write-CustomMessage ("ERROR: Failed to configure CleanMgr for {0}. {1}" -f $keyName, $_.Exception.Message)
            $summary.FailedCount++
        }
    }

    return $summary
}

# Helper: Remove an item with retry/backoff, timing and protected-path safety
function Invoke-RemoveWithRetry {
    param(
        [Parameter(Mandatory = $true)] [string]$Path,
        [int]$MaxRetries = 3,
        [int]$RetryDelaySeconds = 2
    )
    # Normalize and perform an early-bail safety check before any destructive operation
    try {
        $normalizedPath = [IO.Path]::GetFullPath($Path).TrimEnd('\')
    }
    catch {
        $normalizedPath = $Path
    }

    # Never operate on drive roots or empty paths
    try {
        $root = [IO.Path]::GetPathRoot($normalizedPath)
        if ($root -and ($normalizedPath -eq $root)) {
            Write-CustomMessage "Skipping drive root or invalid path: $Path" -Level WARN
            return $true
        }
    }
    catch {
        # If we can't determine root, be conservative and skip
        Write-CustomMessage "Skipping path due to inability to canonicalize: $Path" -Level WARN
        return $true
    }

    # Check configured skip patterns and protected paths before attempting Remove-Item
    if (Test-IsSkipPath -PathToTest $normalizedPath) {
        Write-CustomMessage "Skipping configured skip pattern (remove skipped): $normalizedPath"
        return $true
    }
    if (Test-IsProtectedPath -PathToTest $normalizedPath) {
        Write-CustomMessage "Skipping protected path (remove skipped): $normalizedPath"
        return $true
    }
    # If running under test harness, reduce retries/backoff to make tests fast
    if ($env:SKIP_SLOW_IO) { $MaxRetries = 1; $RetryDelaySeconds = 0 }

    # Honor DryRun: do not perform destructive actions, log what would have been done.
    if ($DryRun) {
        try {
            Write-CustomMessage ("DRYRUN: Would remove {0} (Invoke-RemoveWithRetry)" -f $Path) -Level INFO
        }
        catch { Write-Verbose "DryRun log failed for Invoke-RemoveWithRetry: $_" }
        return $true
    }

    $attempt = 0
    $start = Get-Date
    while ($attempt -lt $MaxRetries) {
        try {
            Remove-Item -Path $Path -Recurse -Force -ErrorAction Stop
            $duration = (Get-Date) - $start
            Write-CustomMessage ("Removed {0} in {1} seconds after {2} attempts" -f $Path, [math]::Round($duration.TotalSeconds, 2), ($attempt + 1))
            return $true
        }
        catch {
            $attempt++
            Write-CustomMessage ("Attempt {0} failed to remove {1}: {2}" -f $attempt, $Path, $_.Exception.Message)
            if ($attempt -lt $MaxRetries) { Start-Sleep -Seconds $RetryDelaySeconds }
            else { Write-CustomMessage ("ERROR: All attempts failed to remove {0}" -f $Path); return $false }
        }
    }
}

# Exposed cleanup pass for user-temp cleanup so tests can call it directly
function Invoke-UserTempCleanup {
    param(
        [string]$UserTempPath = "$env:USERPROFILE\AppData\Local\Temp",
        [int]$DurationMinutes = $MaxCleanupDurationMinutes
    )
    $startTime = Get-Date
    $deleted = 0
    $skipped = 0
    if (-not (Test-Path -Path $UserTempPath)) {
        Write-CustomMessage "User temp path not found: $UserTempPath"; return @{Deleted = 0; Skipped = 0 }
    }
    # Use Get-SafeChildItems to enumerate files and directories while pruning excluded branches
    $items = Get-SafeChildItems -Path $UserTempPath | Where-Object { -not ($_.Attributes -band [System.IO.FileAttributes]::ReparsePoint) }
    foreach ($item in $items) {
        if ((Get-Date) -gt $startTime.AddMinutes($DurationMinutes)) { Write-CustomMessage "Time budget reached for user temp cleanup"; break }
        if (Test-IsProtectedPath -PathToTest $item.FullName) { $skipped++; continue }
        if ($DryRun) { Write-CustomMessage "DRYRUN: Would remove user temp: $($item.FullName)"; $deleted++; continue }
        if (Invoke-RemoveWithRetry -Path $item.FullName -MaxRetries 3 -RetryDelaySeconds 2) { $deleted++ } else { $skipped++ }
    }
    Write-CustomMessage ("User temp cleanup: Deleted {0} items, Skipped {1} items" -f $deleted, $skipped)
    return @{Deleted = $deleted; Skipped = $skipped }
}

# Exposed cleanup pass for global TEMP cleanup
function Invoke-GlobalTempCleanup {
    param(
        [string]$GlobalTempPath = "$env:TEMP",
        [int]$DurationMinutes = $MaxCleanupDurationMinutes
    )
    $startTime = Get-Date
    $deleted = 0
    $skipped = 0
    # Use Get-SafeChildItems to enumerate files and directories while pruning excluded branches
    $items = Get-SafeChildItems -Path $GlobalTempPath | Where-Object { -not ($_.Attributes -band [System.IO.FileAttributes]::ReparsePoint) }
    foreach ($item in $items) {
        if ((Get-Date) -gt $startTime.AddMinutes($DurationMinutes)) { Write-CustomMessage "Time budget reached for global temp cleanup"; break }
        if (Test-IsProtectedPath -PathToTest $item.FullName) { $skipped++; continue }
        if ($DryRun) { Write-CustomMessage "DRYRUN: Would remove global temp: $($item.FullName)"; $deleted++; continue }
        if (Invoke-RemoveWithRetry -Path $item.FullName -MaxRetries 3 -RetryDelaySeconds 2) { $deleted++ } else { $skipped++ }
    }
    Write-CustomMessage ("Global temp cleanup: Deleted {0} items, Skipped {1} items" -f $deleted, $skipped)
    return @{Deleted = $deleted; Skipped = $skipped }
}

function Save-MainLogArchive {
    <#
    Appends the current main log into the archive file and truncates the main log to preserve the path.
    This function is declared early so other regions or functions can call it safely.
    #>
    param (
        [string]$MainLogPath = $logFile,
        [string]$ArchiveDir = $archiveDirectory,
        [string]$ArchivePath = $archiveFile
    )

    try {
        if (-not (Test-Path -Path $ArchiveDir)) { New-Item -ItemType Directory -Path $ArchiveDir -Force | Out-Null }
        if (Test-Path -Path $MainLogPath) {
            # Create a per-run timestamped archive file to preserve each run independently
            $timeStamp = Get-Date -Format 'yyyyMMdd_HHmmss'
            $perRunArchive = Join-Path -Path $ArchiveDir -ChildPath ("$scriptName-$timeStamp.log")
            try {
                # Prefer atomic move if possible
                Move-Item -Path $MainLogPath -Destination $perRunArchive -Force -ErrorAction Stop
                # Recreate an empty main log to preserve path
                New-Item -Path $MainLogPath -ItemType File -Force | Out-Null
                Write-CustomMessage "Moved main log to per-run archive: $perRunArchive and recreated main log path: $MainLogPath"
                # record the per-run archive path so callers can surface it to the host
                $script:LastPerRunArchive = $perRunArchive
                return $true
            }
            catch {
                Write-CustomMessage "ERROR: Move-Item failed for per-run archive $perRunArchive. Falling back to append: $_"
                try {
                    if (-not (Test-Path -Path $ArchivePath)) { New-Item -Path $ArchivePath -ItemType File -Force | Out-Null }
                    Get-Content -Path $MainLogPath -ErrorAction SilentlyContinue | Add-Content -Path $ArchivePath -ErrorAction Stop
                    # Truncate the main log while preserving the file path to avoid breaking handles
                    Set-Content -Path $MainLogPath -Value @() -ErrorAction Stop
                    Write-CustomMessage "Archived main log to fallback archive $ArchivePath and truncated main log at $MainLogPath"
                    $script:LastPerRunArchive = $ArchivePath
                    return $true
                }
                catch {
                    # As a last resort write diagnostic to archive dir and leave main log in place
                    try {
                        $diag = Join-Path -Path $ArchiveDir -ChildPath "${scriptName}_archive_error_$(Get-Date -Format 'yyyyMMdd_HHmmss').diag.txt"
                        "Archive failure: $_" | Out-File -FilePath $diag -Encoding utf8 -Force
                        Write-CustomMessage "ERROR: Failed to archive main log in fallback; wrote diagnostic: $diag"
                    }
                    catch { Write-Verbose "Failed to write archive diagnostic: $_" }
                    return $false
                }
            }
        }
        else {
            Write-CustomMessage "No main log found to archive ($MainLogPath). Skipping archive step."
            return $false
        }
    }
    catch {
        Write-CustomMessage "ERROR: Failed to archive logs safely. Exception: $_"
        return $false
    }
}

function Wait-ForDISM {
    <#
    Waits for any running DISM.exe process to exit, up to a configurable timeout.
    Declared early so other regions can call it after starting DISM when necessary.
    #>
    param (
        [int]$TimeoutInSeconds = 600
    )
    $startTime = Get-Date
    while ((Get-Process -Name DISM -ErrorAction SilentlyContinue) -and ((Get-Date) -lt $startTime.AddSeconds($TimeoutInSeconds))) {
        Start-Sleep -Seconds 5
    }
    if (Get-Process -Name DISM -ErrorAction SilentlyContinue) {
        throw "DISM did not complete within the timeout period."
    }
}

function Test-PendingReboot {
    <#
    Detects common pending reboot markers (registry keys used by Windows Update / Component Based Servicing).
    Returns $true if a reboot is pending, otherwise $false.
    #>
    try {
        # CBS/Component Based Servicing pending
        $cbsKey = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\RebootPending'
        if (Test-Path $cbsKey) { return $true }

        # Windows Update pending reboot marker
        $wuKey = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\RebootRequired'
        if (Test-Path $wuKey) { return $true }

        # PendingFileRenameOperations indicates files to be replaced on reboot
        $sessionKey = 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager'
        try {
            $val = (Get-ItemProperty -Path $sessionKey -Name 'PendingFileRenameOperations' -ErrorAction SilentlyContinue)
            if ($val -and $val.PendingFileRenameOperations) { return $true }
        }
        catch { Write-Verbose "PendingFileRenameOperations check failed: $_" }

        return $false
    }
    catch {
        Write-Verbose "Pending reboot check failed: $_"
        return $false
    }
}

# Wrapper that decides whether to run DISM based on pending reboot state and the new -ForceDISMWhenPending flag.
function Invoke-DISM-Safe {
    [CmdletBinding(SupportsShouldProcess = $true)]
    [OutputType('System.Collections.Hashtable')]
    param()

    # If a pending reboot is detected, only proceed when either the parameter
    # switch (-ForceDISMWhenPending) or the preference ($Pref_ForceDISMWhenPendingOverride)
    # is set. This gives callers (or automation) a way to opt-in to forced DISM runs.
    if (Test-PendingReboot) {
        if (-not $ForceDISMWhenPending -and -not $Pref_ForceDISMWhenPendingOverride) {
            Write-CustomMessage "Pending reboot detected; skipping DISM cleanup unless -ForceDISMWhenPending parameter or Pref_ForceDISMWhenPendingOverride is set." -Level WARN
            return @{ Ran = $false; Reason = 'PendingReboot' }
        }
        else {
            Write-CustomMessage "Pending reboot detected but proceeding with DISM because ForceDISMWhenPending was specified (parameter or preference)." -Level WARN
        }
    }

    # Respect DryRun mode or native ShouldProcess support
    $whatIfRequested = $false
    if ($PSBoundParameters.ContainsKey('WhatIf')) { $whatIfRequested = $true }
    if ($whatIfRequested -or $DryRun) {
        Write-CustomMessage "DRYRUN/WhatIf: Would run DISM /Online /Cleanup-Image /StartComponentCleanup" -Level INFO
        return @{ Ran = $false; Reason = 'DryRun' }
    }
    if ($PSCmdlet -and -not $PSCmdlet.ShouldProcess('DISM component store', 'StartComponentCleanup')) {
        Write-CustomMessage "ShouldProcess declined: skipping DISM component store cleanup." -Level INFO
        return @{ Ran = $false; Reason = 'ShouldProcessDeclined' }
    }

    try {
        Write-CustomMessage "Waiting for any active DISM process to finish before starting cleanup."
        Wait-ForDISM -TimeoutInSeconds 600

        # Revert pending actions first; wrap in Wait-ForDISM to avoid concurrent DISM runs
        try {
            $revert = Start-Process -FilePath 'dism.exe' -ArgumentList '/Online /Cleanup-Image /RevertPendingActions' -NoNewWindow -Wait -PassThru -ErrorAction Stop
            if ($revert.ExitCode -ne 0) { Write-CustomMessage "WARNING: DISM RevertPendingActions returned exit code $($revert.ExitCode)." -Level WARN }
            else { Write-CustomMessage "DISM RevertPendingActions completed successfully." }
        }
        catch { Write-CustomMessage "WARNING: DISM RevertPendingActions failed: $_" -Level WARN }

        Write-CustomMessage "Starting DISM component store cleanup (StartComponentCleanup)."
        $cleanup = Start-Process -FilePath 'dism.exe' -ArgumentList '/Online /Cleanup-Image /StartComponentCleanup' -NoNewWindow -Wait -PassThru -ErrorAction Stop
        if ($cleanup.ExitCode -eq 0) { Write-CustomMessage "DISM component store cleanup completed successfully."; return @{ Ran = $true; ExitCode = 0 } }
        else { Write-CustomMessage "ERROR: DISM cleanup failed with exit code $($cleanup.ExitCode)."; return @{ Ran = $true; ExitCode = $cleanup.ExitCode } }
    }
    catch {
        Write-CustomMessage ("ERROR: DISM cleanup encountered an exception: {0}" -f $_.Exception.Message)
        return @{ Ran = $false; Error = $_ }
    }
}

# Wrapper to run DISM cleanup with logging and error handling. This was previously accidentally
# pasted into the file header; moved here as a callable helper so the header remains documentation-only.
function Invoke-DISMCleanup {
    [CmdletBinding(SupportsShouldProcess = $true)]
    [OutputType('System.Collections.Hashtable')]
    param()

    try {
        Write-CustomMessage "Checking for pending operations before DISM cleanup."
        $dismResult = Invoke-DISM-Safe
        if ($dismResult.Ran -eq $false) {
            # Use a descriptive reason instead of a boolean. Avoid -or which returns a boolean in PowerShell.
            $reasonMsg = if ($dismResult.Reason) { $dismResult.Reason } elseif ($dismResult.Error) { $dismResult.Error } else { 'Unknown' }
            Write-CustomMessage ("DISM step skipped or dry-run: {0}" -f $reasonMsg)
        }
        else {
            if ($dismResult.ExitCode -eq 0) { Write-CustomMessage "DISM component store cleanup completed successfully." }
            else { Write-CustomMessage ("ERROR: DISM cleanup failed with exit code {0}." -f $dismResult.ExitCode) }
        }
    }
    catch {
        Write-CustomMessage (("ERROR: DISM cleanup encountered an exception: {0}" -f $($_.Exception.Message)))
    }
}


# Scaffold: Enumerate per-user browser cache paths and perform safe dry-run aware deletion
function Get-BrowserCachePathsForUser {
    param(
        [Parameter(Mandatory = $true)][string]$UserProfilePath
    )
    $paths = @()
    try {
        $localApp = Join-Path -Path $UserProfilePath -ChildPath 'AppData\Local'
        $paths += Join-Path -Path $localApp -ChildPath 'Google\Chrome\User Data\Default\Cache'
        $paths += Join-Path -Path $localApp -ChildPath 'Microsoft\Edge\User Data\Default\Cache'
        $paths += Join-Path -Path $localApp -ChildPath 'Mozilla\Firefox\Profiles'
        # Also include legacy IE/Edge WebCache locations (where present)
        $paths += Join-Path -Path $localApp -ChildPath 'Microsoft\Windows\INetCache'
    }
    catch { Write-Verbose ('Get-BrowserCachePathsForUser failed for {0}: {1}' -f $UserProfilePath, $_) }
    return $paths
}

function Clear-BrowserCacheAllUsers {
    [CmdletBinding(SupportsShouldProcess = $true)]
    [OutputType('void')]
    param()
    try {
        if ($env:SKIP_SLOW_IO) {
            Write-CustomMessage "SKIP_SLOW_IO set: Skipping browser cache enumeration for tests." -Level INFO
            return
        }
        # Enumerate users under C:\Users (skip common system profiles)
        $users = Get-ChildItem -Path 'C:\Users' -Directory -ErrorAction SilentlyContinue | Where-Object { $_.Name -notin @('Default', 'Default User', 'Public', 'All Users') }
        foreach ($u in $users) {
            $userPath = $u.FullName
            $browserPaths = Get-BrowserCachePathsForUser -UserProfilePath $userPath
            foreach ($bp in $browserPaths) {
                try {
                    if (-not (Test-Path -Path $bp -ErrorAction Stop)) { continue }
                }
                catch [System.UnauthorizedAccessException] {
                    Write-CustomMessage ("Skipping inaccessible browser cache path: {0}" -f $bp) -Level WARN
                    continue
                }
                catch {
                    Write-CustomMessage ("Skipping browser cache path due to probe failure: {0}. {1}" -f $bp, $_) -Level WARN
                    continue
                }
                Write-CustomMessage "Processing browser cache path: $bp"
                Get-SafeChildItems -Path $bp | ForEach-Object {
                    if (Test-IsProtectedPath -PathToTest $_.FullName) { Write-CustomMessage "Skipping protected browser cache entry: $($_.FullName)"; return }
                    $whatIfRequested = $false
                    if ($PSBoundParameters.ContainsKey('WhatIf')) { $whatIfRequested = $PSBoundParameters['WhatIf'] }
                    if ($whatIfRequested -or $DryRun) { Write-CustomMessage "DRYRUN: Would remove browser cache item: $($_.FullName)" }
                    else {
                        if ($PSCmdlet -and -not $PSCmdlet.ShouldProcess($_.FullName, 'Remove browser cache item')) { Write-CustomMessage "ShouldProcess declined for: $($_.FullName)"; return }
                        Invoke-RemoveWithRetry -Path $_.FullName -MaxRetries 2 -RetryDelaySeconds 1
                    }
                }
            }
        }
    }
    catch { Write-CustomMessage ('ERROR: Clear-BrowserCacheAllUsers failed: {0}' -f $_) }
}

function Clear-WindowsUpdateDownloadCache {
    <#
    Cautious clear of the Windows Update Download folder. Does not stop/start services.
    Only removes files in the Download folder, it does not alter DataStore or other update DB files.
    This is safe and non-rebooting.
    #>
    try {
        if ($env:SKIP_SLOW_IO) {
            Write-CustomMessage "SKIP_SLOW_IO set: Skipping Windows Update download cache enumeration." -Level INFO
            return
        }
        $wuDownload = Join-Path -Path $env:windir -ChildPath 'SoftwareDistribution\Download'
        if (Test-Path $wuDownload) {
            # Use pruned file-only enumeration to avoid traversing excluded branches
            Get-SafeChildItems -Path $wuDownload -FilesOnly | ForEach-Object {
                try {
                    if ($DryRun) { Write-CustomMessage ("DRYRUN: Would remove Windows Update download file: {0}" -f $_.FullName) }
                    else { Invoke-RemoveWithRetry -Path $_.FullName -MaxRetries 3 -RetryDelaySeconds 2; Write-CustomMessage ("Removed Windows Update download file: {0}" -f $_.FullName) }
                }
                catch { Write-CustomMessage ("WARNING: Could not remove update download file {0}: {1}" -f $_.FullName, $($_.Exception.Message)) }
            }
        }
    }
    catch {
        Write-CustomMessage ("ERROR: Clearing Windows Update download cache failed: {0}" -f $($_.Exception.Message))
    }
}
# endregion

# region 0E - Logging setup
# Single consolidated temporary log and safe merge behavior

$logFileDirectory = Join-Path -Path $env:TEMP -ChildPath 'LogFiles'
if (-not (Test-Path -Path $logFileDirectory)) { New-Item -Path $logFileDirectory -ItemType Directory -Force | Out-Null }

# Default script name and log paths (set only if not already provided by caller/tests)
if (-not $scriptName) { $scriptName = 'Win-Storage-Remediate' }
if (-not $logFile) { $logFile = Join-Path -Path $logFileDirectory -ChildPath ("${scriptName}.log") }

# Default operational parameters (non-invasive defaults)
if (-not $tempLogSizeThresholdMB) { $tempLogSizeThresholdMB = 50 }
if (-not $tempLogAgeDays) { $tempLogAgeDays = 7 }
if (-not $MaxCleanupDurationMinutes) { $MaxCleanupDurationMinutes = 10 }
if (-not $Verbosity) { $Verbosity = 'Silent' }

# Temporary log file for script execution (single file)
$tempLogFile = Join-Path -Path $env:TEMP -ChildPath "${scriptName}_temp.log"

# Archive directory and archive file used by the script. Define early so cleanup logic can exclude them.
$archiveDirectory = Join-Path -Path $env:TEMP -ChildPath 'ArchivedLogs'
$archiveFile = Join-Path -Path $archiveDirectory -ChildPath 'ArchivedLogFile.log'
# Ensure archive directory exists (idempotent)
if (-not (Test-Path -Path $archiveDirectory)) { New-Item -Path $archiveDirectory -ItemType Directory -Force | Out-Null }

# Ensure temp log exists early
if (-not (Test-Path -Path $tempLogFile)) { New-Item -Path $tempLogFile -ItemType File -Force | Out-Null }

# Track pruned branches to avoid duplicate noisy log messages during multiple passes
if (-not $script:PrunedBranches) { try { $script:PrunedBranches = [System.Collections.Generic.HashSet[string]]::new() } catch { $script:PrunedBranches = New-Object System.Collections.ArrayList } }

# If an existing temp log is large or old (likely from a previous incomplete run), archive it and start a fresh temp log
try {
    if (Test-Path -Path $tempLogFile) {
        $tempInfo = Get-Item -Path $tempLogFile
        $sizeMB = [math]::Round($tempInfo.Length / 1MB, 2)
        $ageDays = (Get-Date) - $tempInfo.LastWriteTime
        if ($sizeMB -ge $tempLogSizeThresholdMB -or $ageDays.TotalDays -ge $tempLogAgeDays) {
            $oldTempArchive = Join-Path -Path $archiveDirectory -ChildPath ("${scriptName}_temp_${(Get-Date).ToString('yyyyMMdd_HHmmss')}.log")
            Copy-Item -Path $tempLogFile -Destination $oldTempArchive -Force -ErrorAction SilentlyContinue
            # Truncate the temp log so current run starts fresh
            Set-Content -Path $tempLogFile -Value @() -ErrorAction SilentlyContinue
            Write-Verbose "Archived existing temp log to $oldTempArchive and started a fresh temp log."
        }
    }
}
catch {
    Write-Verbose "Failed to archive existing temp log at startup: $_"
}

# New: canonical protected-path check used throughout cleanup to avoid touching logs/archives
function Test-IsProtectedPath {
    param(
        [Parameter(Mandatory = $true)]
        [string]$PathToTest
    )
    if (-not $PathToTest) { return $false }
    try {
        $resolved = (Get-Item -LiteralPath $PathToTest -ErrorAction SilentlyContinue).FullName
    }
    catch {
        # If it can't be resolved, fallback to the input
        $resolved = $PathToTest
    }

    # Normalize for comparison
    try { $resolvedNorm = [IO.Path]::GetFullPath($resolved).TrimEnd('\') } catch { $resolvedNorm = $resolved }

    # Safely attempt to canonicalise script-level logging variables — these may not exist when loading functions via AST in tests
    $tempLogNorm = $null; $logFileNorm = $null; $logDirNorm = $null; $archiveDirNorm = $null; $archiveFileNorm = $null
    if ($tempLogFile) { try { $tempLogNorm = [IO.Path]::GetFullPath($tempLogFile).TrimEnd('\') } catch { $tempLogNorm = $null } }
    if ($logFile) { try { $logFileNorm = [IO.Path]::GetFullPath($logFile).TrimEnd('\') } catch { $logFileNorm = $null } }
    if ($logFileDirectory) { try { $logDirNorm = [IO.Path]::GetFullPath($logFileDirectory).TrimEnd('\') } catch { $logDirNorm = $null } }
    if ($archiveDirectory) { try { $archiveDirNorm = [IO.Path]::GetFullPath($archiveDirectory).TrimEnd('\') } catch { $archiveDirNorm = $null } }
    if ($archiveFile) { try { $archiveFileNorm = [IO.Path]::GetFullPath($archiveFile).TrimEnd('\') } catch { $archiveFileNorm = $null } }

    if ($tempLogNorm -and ($resolvedNorm -eq $tempLogNorm)) { return $true }
    if ($logFileNorm -and ($resolvedNorm -eq $logFileNorm)) { return $true }
    if ($archiveFileNorm -and ($resolvedNorm -eq $archiveFileNorm)) { return $true }
    if ($logDirNorm -and $resolvedNorm.StartsWith($logDirNorm, [System.StringComparison]::OrdinalIgnoreCase)) { return $true }
    if ($archiveDirNorm -and $resolvedNorm.StartsWith($archiveDirNorm, [System.StringComparison]::OrdinalIgnoreCase)) { return $true }

    # If the item is a reparse point (junction/mount/symlink) we must skip it
    try {
        $item = Get-Item -LiteralPath $resolved -ErrorAction SilentlyContinue
        if ($item -and ($item.Attributes -band [System.IO.FileAttributes]::ReparsePoint)) {
            return $true
        }
    }
    catch {
        # If we can't get attributes, be conservative and treat as protected
        return $true
    }

    # Also respect configured skip patterns
    if (Test-IsSkipPath -PathToTest $resolved) { return $true }

    return $false
}

# Helper: test path against configured skip regex patterns (fallback to containment)
function Test-IsSkipPath {
    param(
        [Parameter(Mandatory = $true)][string]$PathToTest
    )
    if (-not $PathToTest) { return $false }

    # Normalize path for pattern matching
    try {
        $normalized = [IO.Path]::GetFullPath($PathToTest).TrimEnd('\')
    }
    catch {
        $normalized = $PathToTest
    }

    # Fast deterministic checks for known tokens and extensions (helps in test and constrained environments)
    try {
        $ext = [IO.Path]::GetExtension($normalized)
        if ($ext) {
            if ($ext -match '(?i)\.odl$|\.odlgz$|\.aodl$') { return $true }
        }
    }
    catch {
        # Preserve conservative behaviour: log the parsing/canonicalization error for diagnostics but do not throw.
        Write-Verbose "Test-IsSkipPath normalization failed for path '$PathToTest': $_"
        Write-CustomMessage "Test-IsSkipPath normalization failed for path '$PathToTest': $_" -Level WARN
    }

    $lower = $normalized.ToLower()
    if ($lower -like '*\\onedrive*' -or $lower -like '*microsoft\\onedrive*' -or $lower -like '*filesondemand*') { return $true }
    # Additional robust token match for OneDrive that tolerates spaces and suffixes
    if ($normalized -match '(?i)\bonedrive\b' -or $normalized -match '(?i)onedrive') { return $true }

    foreach ($pattern in $skipPathPatterns) {
        if (-not $pattern) { continue }
        try {
            # Treat pattern as regex; anchor or partial matches are both valid depending on pattern authorship
            if ([regex]::IsMatch($normalized, $pattern, [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)) {
                return $true
            }
        }
        catch {
            # If pattern isn't a valid regex, fallback to case-insensitive containment check
            if ($normalized.ToLower().Contains($pattern.ToLower())) { return $true }
        }
    }
    # Additional fallback: some patterns are written as regex with escaped backslashes or tokens
    # If regex didn't match, attempt a sanitized containment check by removing common regex metacharacters
    foreach ($pattern in $skipPathPatterns) {
        if (-not $pattern) { continue }
        # Remove inline (?i) flags and common regex constructs to extract a token
        $token = $pattern -replace '\(\?i\)', '' -replace '[\\\^\$\.\|\?\*\+\(\)\[\]\{\}]', ''
        $token = $token.Trim()
        if ($token.Length -gt 1) {
            if ($normalized.ToLower().Contains($token.ToLower())) { return $true }
        }
    }

    return $false
}

# Ensure main log exists (do not delete previous logs)
if (-not (Test-Path -Path $logFile)) { New-Item -Path $logFile -ItemType File -Force | Out-Null }

# Robust early backup of any existing main log so later regions can rely on preserved logs.
# Uses exponential backoff retries and falls back to creating a unique timestamped backup if the direct copy fails.
try {
    if ((Test-Path -Path $logFile) -and ((Get-Item -Path $logFile).Length -gt 0)) {
        $backupLogFile = "${logFile}.bak"
        $copyBackoff = @(1, 2, 4)
        $copied = $false
        for ($i = 0; $i -lt $copyBackoff.Count; $i++) {
            try {
                Copy-Item -Path $logFile -Destination $backupLogFile -Force -ErrorAction Stop
                Write-CustomMessage "Previous log file backed up to: $backupLogFile"
                $copied = $true
                break
            }
            catch {
                Write-Verbose "Backup attempt $($i + 1) failed: $_"
                Start-Sleep -Seconds $copyBackoff[$i]
            }
        }
        if (-not $copied) {
            try {
                $unique = Join-Path -Path $logFileDirectory -ChildPath "${scriptName}_$(Get-Date -Format 'yyyyMMdd_HHmmss').bak"
                Copy-Item -Path $logFile -Destination $unique -Force -ErrorAction Stop
                Write-CustomMessage "Previous log saved to unique backup: $unique"
            }
            catch {
                Write-CustomMessage "ERROR: Failed to backup existing log file early: $_"
            }
        }
    }
}
catch {
    Write-CustomMessage "WARNING: Early log backup encountered an error: $_"
}
# endregion

# region 0F - Main Script Logic summary

# Group related sections together

# Order of operations
# 1. Get and display initial disk space
# 2. User data
#      a) Remove old user profiles
#      b) Additional non-rebooting cleanup (OneDrive, Browser caches)
# 3. Storage cleanup
#      a) Additional non-rebooting cleanup (Delivery Optimization,Windows Update downloads)
#      b) Run Storage Sense
# 4. DISM: WinSxS component store cleanup
# 5. Event logs
#      a) Clean up old event logs
#      b) Archive old event logs
# 6. Temporary files cleanup
#      a) Clean up user specific files
#      b) Remove user-specific temporary files
# 7. Cleanmgr
#      a) Prepare registry
#      b) Run cleanmgr
#      c) Remove windows.old
# 8. Final clean up
#      a) Ensure final disk space information is rendered
#      c) Resolve log export failures
#      d) Handle file locking issues during log consolidation
#      e) Call Resolve-FileLock for temporary files (Test-FileLock and Resolve-FileLock are defined earlier)
#      f) Handle access denied errors during cleanup
#      h) Enhanced error handling for Get-ChildItem
#      i) Enhanced error handling for Move-Item
#      j) Handle access denied errors in Get-ChildItem
#      k) Improve log export handling
# endregion

# region 0G - Start the script
Write-CustomMessage "Intune free space remediation script"
Write-CustomMessage "===================================="
Write-CustomMessage ""
Write-CustomMessage "Commencing script"
Write-CustomMessage ""

# Capture an initial probe snapshot and free space for later DryRun summaries.
try {
    $global:__InitialProbePaths = @(
        "$env:TEMP",
        "C:\Windows\Temp",
        "$env:SystemRoot\SoftwareDistribution\Download",
        "$env:SystemRoot\\Downloaded Program Files"
    )
    try { $global:__PreSnapshot = Get-ProbeSnapshot -PathsToProbe $global:__InitialProbePaths -IgnorePrune } catch { $global:__PreSnapshot = @{} }
    try { $global:__InitialFreeSpace = (Get-PSDrive -Name C).Free } catch { $global:__InitialFreeSpace = $null }
}
catch { Write-Verbose "Failed to capture initial probes: $_" }

# If -Estimate is requested, run size-only probes for common categories and exit
if ($Estimate) {
    Write-CustomMessage "ESTIMATE mode: producing size estimates for common cleanup categories (non-destructive)."
    $estimatePaths = @{}
    # Temp folders
    $estimatePaths['UserTemp'] = "$env:USERPROFILE\AppData\Local\Temp"
    $estimatePaths['WindowsTemp'] = "C:\Windows\Temp"
    # SoftwareDistribution
    $estimatePaths['SoftwareDistributionDownload'] = "$env:SystemRoot\SoftwareDistribution\Download"
    # Downloaded Program Files
    $estimatePaths['DownloadedProgramFiles'] = "$env:SystemRoot\Downloaded Program Files"
    # Recycle Bin (approximate): use Shell COM object to enumerate deletable items if available
    $estimatePaths['BrowserCaches'] = @( (Join-Path -Path $env:LOCALAPPDATA -ChildPath 'Google\Chrome\User Data\Default\Cache'), (Join-Path -Path $env:LOCALAPPDATA -ChildPath 'Microsoft\Edge\User Data\Default\Cache') )

    foreach ($k in $estimatePaths.Keys) {
        $val = $estimatePaths[$k]
        if ($val -is [System.Array]) {
            $sum = 0
            foreach ($p in $val) {
                if (-not (Test-Path -Path $p)) { continue }
                $snap = Get-ProbeSnapshot -PathsToProbe @($p)
                if ($snap.ContainsKey($p)) { $sum += $snap[$p].Bytes }
            }
            Write-CustomMessage ("Estimate: {0} = {1} bytes ({2} MB)" -f $k, $sum, ([math]::Round($sum / 1MB, 2)))
        }
        else {
            $snap = Get-ProbeSnapshot -PathsToProbe @($val)
            if ($snap.ContainsKey($val)) { $b = $snap[$val].Bytes } else { $b = 0 }
            Write-CustomMessage ("Estimate: {0} = {1} bytes ({2} MB)" -f $k, $b, ([math]::Round($b / 1MB, 2)))
        }
    }

    # Estimate Recycle Bin separately using Shell COM interface where available
    try {
        $rb = Get-RecycleBinSize
        if ($null -ne $rb) { Write-CustomMessage ("Estimate: RecycleBin = {0} bytes ({1} MB)" -f $rb, ([math]::Round($rb / 1MB, 2))) }
    }
    catch { Write-Verbose "RecycleBin estimate failed: $_" }
    Write-CustomMessage "ESTIMATE mode complete. No destructive actions performed."
    # Merge logs and exit gracefully
    try { Merge-Log | Out-Null } catch { Write-Verbose "Merge-Log failed during estimate/cleanup exit: $_" }
    exit 0
}

# If -CleanMgrOnly is requested, run only registry preparation, cleanmgr, and probes
if ($CleanMgrOnly) {
    Write-CustomMessage "CLEANMGR-ONLY mode: running prepare + /sagerun:1 and pre/post probes."
    $probePaths = @(
        "$env:TEMP",
        "C:\Windows\Temp",
        "$env:SystemRoot\SoftwareDistribution\Download",
        "$env:SystemRoot\Downloaded Program Files"
    )

    # Ensure cleanmgr path is known for this fast-path
    $cleanMgrPath = "${env:SystemRoot}\System32\cleanmgr.exe"

    try { $preSnapshot = Get-ProbeSnapshot -PathsToProbe $probePaths -IgnorePrune } catch { $preSnapshot = @{} }

    if (-not $Pref_CleanMgrPrep) {
        Write-CustomMessage "SKIPPED: CleanMgr registry preparation disabled by Pref_CleanMgrPrep." -Level INFO
    }
    else {
        try {
            Set-CleanMgrCategories -Types $cleanupTypeSelection | Out-Null
        }
        catch { Write-CustomMessage "WARNING: CleanMgr preparation encountered an issue: $_" }
    }

    # Invoke CleanMgr (respect DryRun / WhatIf / ShouldProcess)
    try {
        if (-not $Pref_RunCleanMgr) {
            Write-CustomMessage "SKIPPED: CleanMgr run disabled by Pref_RunCleanMgr." -Level INFO
        }
        elseif (Test-Path $cleanMgrPath) {
            $whatIfRequested = $false
            if ($PSBoundParameters.ContainsKey('WhatIf')) { $whatIfRequested = $true }
            if ($whatIfRequested -or $DryRun) {
                Write-CustomMessage "DRYRUN: Would invoke CleanMgr to apply configured categories (/sagerun:1)." -Level INFO
            }
            elseif ($PSCmdlet -and -not $PSCmdlet.ShouldProcess($cleanMgrPath, 'Run cleanmgr /sagerun:1')) {
                Write-CustomMessage "ShouldProcess declined: skipping CleanMgr run." -Level INFO
            }
            else {
                Write-CustomMessage "Invoking CleanMgr to apply configured categories (/sagerun:1)."
                $proc = Start-Process -FilePath $cleanMgrPath -ArgumentList '/sagerun:1' -NoNewWindow -Wait -PassThru -ErrorAction SilentlyContinue
                if ($proc -and $proc.ExitCode -eq 0) { Write-CustomMessage "CleanMgr completed with exit code 0." }
                elseif ($proc) { Write-CustomMessage (("WARNING: CleanMgr returned exit code {0}." -f $proc.ExitCode)) -Level WARN }
                else { Write-CustomMessage "WARNING: CleanMgr did not start successfully." -Level WARN }
            }
        }
        else { Write-CustomMessage "WARNING: cleanmgr.exe not found at expected path: $cleanMgrPath" -Level WARN }
    }
    catch { Write-CustomMessage "ERROR: Failed to invoke CleanMgr: $_" }

    # Post snapshots and report deltas
    try { $postSnapshot = Get-ProbeSnapshot -PathsToProbe $probePaths -IgnorePrune } catch { $postSnapshot = @{} }
    try {
        foreach ($p in $probePaths) {
            $preObj = $null; $postObj = $null
            if ($preSnapshot.ContainsKey($p)) { $preObj = $preSnapshot[$p] }
            if ($postSnapshot.ContainsKey($p)) { $postObj = $postSnapshot[$p] }
            if ($null -ne $preObj) { $preBytes = [int64]$preObj.Bytes } else { $preBytes = 0 }
            if ($null -ne $postObj) { $postBytes = [int64]$postObj.Bytes } else { $postBytes = 0 }
            $delta = $preBytes - $postBytes
            $deltaMB = [math]::Round($delta / 1MB, 2)
            $deltaGB = [math]::Round($delta / 1GB, 2)
            Write-CustomMessage ("Probe delta: Path='{0}', Before={1} bytes ({2} MB), After={3} bytes ({4} MB), Freed={5} MB ({6} GB)" -f $p, $preBytes, ([math]::Round($preBytes / 1MB, 2)), $postBytes, ([math]::Round($postBytes / 1MB, 2)), $deltaMB, $deltaGB)
        }
    }
    catch { Write-CustomMessage "WARNING: Failed to compute probe deltas: $_" }

    try { Merge-Log | Out-Null } catch { Write-Verbose "Merge-Log failed during CleanMgrOnly exit: $_" }
    Write-CustomMessage "CLEANMGR-ONLY mode complete. Exiting."; exit 0
}
# endregion

# region 1 - Get and display initial disk space
# Disk space initialization
$freeSpaceBytes = (Get-PSDrive -Name C).Free
$freeSpaceGB = [math]::Round($freeSpaceBytes / 1GB, 2)
Write-CustomMessage "Initial free space: $freeSpaceGB GB ($([math]::Round($freeSpaceBytes/1MB,2)) MB)"
# endregion

# region 2A - Remove old user profiles
if (-not $Pref_RemoveOldUserProfiles) {
    Write-CustomMessage "SKIPPED: Remove old user profiles is disabled via preferences (Pref_RemoveOldUserProfiles=$Pref_RemoveOldUserProfiles)." -Level INFO
}
else {
    try {
        Write-CustomMessage "Checking for stale Win32_UserProfile entries older than $userProfileRetentionDays days."
        Invoke-OldUserProfileCleanup -RetentionDays $userProfileRetentionDays | Out-Null
    }
    catch {
        Write-CustomMessage "ERROR: Failed to clean up old user profiles. $_"
    }
}
# endregion

# region 2B - Additional non-rebooting cleanup (OneDrive, Browser caches)
if (-not $Pref_OneDriveAndBrowserCache) {
    Write-CustomMessage "SKIPPED: OneDrive and browser cache cleanup disabled via Pref_OneDriveAndBrowserCache=$Pref_OneDriveAndBrowserCache." -Level INFO
}
else {
    try {
        Write-CustomMessage "Starting additional non-rebooting cleanup steps: OneDrive cache, and browser caches"

        # Per-user OneDrive caches (safe removals)
        Clear-OneDriveUserCache

        # Browser caches (Edge/Chrome/Firefox) per-user
        Clear-BrowserCache

        Write-CustomMessage "Additional non-rebooting cleanup completed: OneDrive cache, and browser caches."
    }
    catch {
        Write-CustomMessage ("ERROR: Additional non-rebooting cleanup encountered an error: {0}" -f $_.Exception.Message)
    }
}

## endregion

# region 3A - Additional non-rebooting cleanup (Delivery Optimization, Windows Update downloads)
if (-not $Pref_DeliveryOptimizationAndWU) {
    Write-CustomMessage "SKIPPED: Delivery Optimization and Windows Update download cleanup disabled via Pref_DeliveryOptimizationAndWU=$Pref_DeliveryOptimizationAndWU." -Level INFO
}
else {
    try {
        Write-CustomMessage "Starting additional non-rebooting cleanup steps: Delivery Optimization, and Windows Update download cache."

        # Delivery Optimization basic cache
        Clear-DeliveryOptimizationCache

        # Windows Update download cache (SoftwareDistribution\Download)
        Clear-SoftwareDistributionDownload

        # Additional Delivery Optimization content cleanup
        Clear-DeliveryOptimizationAdvanced

        Write-CustomMessage "Additional non-rebooting cleanup completed: Delivery Optimization, and Windows Update."
    }
    catch {
        Write-CustomMessage ("ERROR: Additional non-rebooting cleanup encountered an error: {0}" -f $_.Exception.Message)
    }
}

## endregion

# region 3B - Run Storage Sense
if (-not $Pref_StorageSense) {
    Write-CustomMessage "SKIPPED: Storage Sense configuration disabled via Pref_StorageSense=$Pref_StorageSense." -Level INFO
}
else {
    if (Get-Command -Name Set-StorageSense -ErrorAction SilentlyContinue) {
        try {
            if ($DryRun) {
                Write-CustomMessage "DRYRUN: Would enable Storage Sense."
            }
            else {
                Write-CustomMessage "Configuring Storage Sense."
                Set-StorageSense -Enable $true -ErrorAction Stop
                Write-CustomMessage "Storage Sense enabled successfully."
            }
        }
        catch {
            Write-CustomMessage "ERROR: Failed to enable Storage Sense. $_"
        }
    }
    else {
        Write-CustomMessage "WARNING: Set-StorageSense cmdlet not available. Skipping Storage Sense configuration."
    }

    if (Get-Command -Name Set-StorageSenseConfiguration -ErrorAction SilentlyContinue) {
        try {
            if ($DryRun) {
                Write-CustomMessage ("DRYRUN: Would configure Storage Sense temp-file cleanup and OneDrive content cleanup threshold to {0} days." -f $oneDriveCleanupThreshold)
            }
            else {
                Write-CustomMessage "Configuring OneDrive content cleanup threshold."
                Set-StorageSenseConfiguration -DeleteTempFiles $true -ConfigureOneDriveContentCleanupThreshold $oneDriveCleanupThreshold -ErrorAction Stop
                Write-CustomMessage "OneDrive content cleanup threshold configured successfully."
            }
        }
        catch {
            Write-CustomMessage "ERROR: Failed to configure OneDrive content cleanup threshold. $_" -Level Error
        }
    }
    else {
        Write-CustomMessage "WARNING: Set-StorageSenseConfiguration cmdlet not available. Skipping OneDrive content cleanup configuration."
    }
}
# endregion

# region 4 - DISM: WinSxS component store cleanup
if (-not $Pref_DISMComponentStoreCleanup) {
    Write-CustomMessage "SKIPPED: DISM component store cleanup disabled via Pref_DISMComponentStoreCleanup=$Pref_DISMComponentStoreCleanup." -Level INFO
}
else {
    try {
        Invoke-DISMCleanup | Out-Null
    }
    catch {
        Write-CustomMessage ("ERROR: DISM cleanup encountered an exception: {0}" -f $($_.Exception.Message))
    }
}
# endregion

# region 5A - Clean up old event logs
if (-not $Pref_EventLogCleanup) {
    Write-CustomMessage "SKIPPED: Event log cleanup disabled via Pref_EventLogCleanup=$Pref_EventLogCleanup." -Level INFO
}
else {
    try {
        Write-CustomMessage "Starting event log cleanup. Logs to process: $($logsToClear -join ', ')"

        # Define the archive directory for exported logs
        $archiveDir = "$env:TEMP\EventLogArchives"
        if (-not $DryRun -and -not (Test-Path $archiveDir)) {
            New-Item -Path $archiveDir -ItemType Directory -Force | Out-Null
            Write-CustomMessage "Created archive directory: $archiveDir"
        }

        # Cache available logs once to avoid repeated wevtutil el calls
        try {
            $availableLogs = wevtutil el 2>$null
        }
        catch {
            $availableLogs = @()
        }

        foreach ($log in $logsToClear) {
            try {
                if ($availableLogs -contains $log) {
                    # Unique export filename to avoid collisions
                    $safeName = ($log -replace '[\\/:*?"<>|]', '_')
                    $exportPath = Join-Path -Path $archiveDir -ChildPath ("{0}_{1}.evtx" -f $safeName, (Get-Date -Format 'yyyyMMdd_HHmmss'))
                    if ($DryRun) {
                        Write-CustomMessage ("DRYRUN: Would export log {0} to {1} and clear it afterwards." -f $log, $exportPath)
                    }
                    else {
                        Write-CustomMessage ("Exporting log: {0} to {1}" -f $log, $exportPath)

                        $res = Export-EventLog -LogName $log -ExportPath $exportPath
                        if ($res.Success) {
                            Write-CustomMessage ("Successfully exported log: {0} to {1}" -f $log, $exportPath)
                            try {
                                # Clear the log after successful export; pipe output to Out-Null to avoid unused variable warnings
                                & (Join-Path -Path $env:WINDIR -ChildPath 'System32\wevtutil.exe') cl "$log" 2>&1 | Out-Null
                                Write-CustomMessage ("Cleared log: {0}" -f $log)
                            }
                            catch {
                                Write-CustomMessage ("WARNING: Failed to clear log {0}: {1}" -f $log, $($_.Exception.Message)) -Level WARN
                            }
                        }
                        else {
                            Write-CustomMessage (("WARNING: wevtutil epl returned exit code {0} for {1}. Output: {2}" -f $res.ExitCode, $log, $res.Output)) -Level WARN
                        }
                    }
                }
                else {
                    Write-CustomMessage (("Log not found: {0}" -f $log))
                }
            }
            catch {
                Write-CustomMessage (("ERROR: Failed to process log: {0}. Exception: {1}" -f $log, $($_.Exception.Message)))
            }
        }

        Write-CustomMessage "Event log cleanup completed."
    }
    catch {
        Write-CustomMessage "ERROR: Failed to clean up event logs. $_"
    }
}
# endregion

# region 6A - Clean up user-specific temporary files
if (-not $Pref_UserTempCleanup) {
    Write-CustomMessage "SKIPPED: User-specific temp file cleanup disabled via Pref_UserTempCleanup=$Pref_UserTempCleanup." -Level INFO
}
else {
    try {
        $tempPath = "$env:USERPROFILE\AppData\Local\Temp"
        Write-CustomMessage "Cleaning user-specific temporary files at $tempPath"
        Invoke-UserTempCleanup -UserTempPath $tempPath -DurationMinutes $MaxCleanupDurationMinutes | Out-Null
    }
    catch {
        Write-CustomMessage "ERROR: Failed to clean user-specific temporary files. $_"
    }
}

if (-not $logFileDirectory) {
    $logFileDirectory = "$env:TEMP\LogFiles"
    if (-not (Test-Path -Path $logFileDirectory)) {
        New-Item -Path $logFileDirectory -ItemType Directory -Force | Out-Null
    }
}
# endregion

# region 6B - Remove user-specific temporary files
if (-not $Pref_GlobalTempCleanup) {
    Write-CustomMessage "SKIPPED: Global temp cleanup disabled via Pref_GlobalTempCleanup=$Pref_GlobalTempCleanup." -Level INFO
}
else {
    try {
        Invoke-GlobalTempCleanup -GlobalTempPath $env:TEMP -DurationMinutes $MaxCleanupDurationMinutes | Out-Null
        Write-CustomMessage "Completed temp cleanup pass for $env:TEMP (excluding log directory)."
    }
    catch {
        Write-CustomMessage ("ERROR: Failed to remove temporary files from {0}. Exception: {1}" -f $env:TEMP, $_.Exception.Message)
    }
    # Close the else block opened for Pref_GlobalTempCleanup
}
# endregion

# region 7A - CleanMgr registry preparation
if (-not $Pref_CleanMgrPrep) {
    Write-CustomMessage "SKIPPED: CleanMgr registry preparation disabled by Pref_CleanMgrPrep." -Level INFO
}
else {
    Set-CleanMgrCategories -Types $cleanupTypeSelection | Out-Null
}
#endregion

# region 7B - Run CleanMgr silently

if (-not $Pref_RunCleanMgr) {
    Write-CustomMessage "SKIPPED: CleanMgr run disabled by Pref_RunCleanMgr." -Level INFO
}
else {
    try {
        $cleanMgrPath = "$env:SystemRoot\System32\cleanmgr.exe"
        if (-not (Test-Path $cleanMgrPath)) {
            Write-CustomMessage "ERROR: cleanmgr.exe not found at $cleanMgrPath. Skipping CleanMgr step."
            throw "CleanMgr executable not found."
        }

        Write-CustomMessage "Prepared CleanMgr categories; CleanMgr run will be invoked using /sagerun:1 to apply configured categories."
        # Diagnostic: list which CleanMgr registry keys were set and their StateFlags0001 values (read-only)
        try {
            Write-CustomMessage "CleanMgr diagnostic: enumerating configured VolumeCaches keys and their StateFlags0001 values."
            $vcRoot = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches'
            if (Test-Path $vcRoot) {
                Get-ChildItem -Path $vcRoot -ErrorAction SilentlyContinue | ForEach-Object {
                    try {
                        $cat = $_.PSChildName
                        $props = Get-ItemProperty -Path $_.PSPath -Name 'StateFlags0001' -ErrorAction SilentlyContinue
                        $flag = if ($props -and $props.StateFlags0001 -ne $null) { $props.StateFlags0001 } else { '<not set>' }
                        Write-CustomMessage ("CleanMgr diagnostic: Category='{0}', StateFlags0001={1}" -f $cat, $flag)
                    }
                    catch {
                        Write-CustomMessage ("CleanMgr diagnostic: Failed reading {0}: {1}" -f $_.PSChildName, $_)
                    }
                }
            }
            else { Write-CustomMessage "CleanMgr diagnostic: VolumeCaches registry root not found: $vcRoot" }
        }
        catch { Write-CustomMessage "CleanMgr diagnostic: enumeration failed: $_" }
        finally {
            # Probe paths to capture before/after sizes for diagnostic purposes (read-only)
            $probePaths = @(
                "$env:TEMP",
                "C:\Windows\Temp",
                "$env:SystemRoot\SoftwareDistribution\Download",
                "$env:SystemRoot\\Downloaded Program Files"
            )

            try { $preSnapshot = Get-ProbeSnapshot -PathsToProbe $probePaths -IgnorePrune } catch { $preSnapshot = @{} }

            # Attempt to run cleanmgr in silent sagerun mode regardless of diagnostic/merge-log outcome.
            try {
                if (Test-Path $cleanMgrPath) {
                    $whatIfRequested = $false
                    if ($PSBoundParameters.ContainsKey('WhatIf')) { $whatIfRequested = $true }
                    if ($whatIfRequested -or $DryRun) {
                        Write-CustomMessage "DRYRUN: Would invoke CleanMgr to apply configured categories (/sagerun:1)." -Level INFO
                    }
                    elseif ($PSCmdlet -and -not $PSCmdlet.ShouldProcess($cleanMgrPath, 'Run cleanmgr /sagerun:1')) {
                        Write-CustomMessage "ShouldProcess declined: skipping CleanMgr run." -Level INFO
                    }
                    else {
                        Write-CustomMessage "Invoking CleanMgr to apply configured categories (/sagerun:1)."
                        try {
                            $proc = Start-Process -FilePath $cleanMgrPath -ArgumentList '/sagerun:1' -WindowStyle Hidden -Wait -PassThru -ErrorAction Stop
                            if ($proc -and $proc.ExitCode -eq 0) { Write-CustomMessage "CleanMgr completed with exit code 0." }
                            elseif ($proc) { Write-CustomMessage (("WARNING: CleanMgr returned exit code {0}." -f $proc.ExitCode)) -Level WARN }
                        }
                        catch { Write-CustomMessage (("ERROR: Failed to start or run CleanMgr: {0}" -f $_)) -Level ERROR }
                    }
                }
                else { Write-CustomMessage "WARNING: cleanmgr.exe not found at expected path: $cleanMgrPath" -Level WARN }
            }
            catch { Write-CustomMessage "ERROR: Failed to invoke CleanMgr: $_" }

            # Post-snapshot and compute delta (where possible)
            try { $postSnapshot = Get-ProbeSnapshot -PathsToProbe $probePaths -IgnorePrune } catch { $postSnapshot = @{} }
            try {
                foreach ($p in $probePaths) {
                    $preObj = $null; $postObj = $null
                    if ($preSnapshot.ContainsKey($p)) { $preObj = $preSnapshot[$p] }
                    if ($postSnapshot.ContainsKey($p)) { $postObj = $postSnapshot[$p] }
                    if ($null -ne $preObj) { $preBytes = [int64]($preObj.Bytes -as [int64]) } else { $preBytes = 0 }
                    if ($null -ne $postObj) { $postBytes = [int64]($postObj.Bytes -as [int64]) } else { $postBytes = 0 }
                    $delta = $preBytes - $postBytes
                    $deltaMB = [math]::Round($delta / 1MB, 2)
                    $deltaGB = [math]::Round($delta / 1GB, 2)
                    Write-CustomMessage ("Probe delta: Path='{0}', Before={1} bytes ({2} MB), After={3} bytes ({4} MB), Freed={5} MB ({6} GB)" -f $p, $preBytes, ([math]::Round($preBytes / 1MB, 2)), $postBytes, ([math]::Round($postBytes / 1MB, 2)), $deltaMB, $deltaGB)
                }
            }
            catch { Write-CustomMessage "WARNING: Failed to compute probe deltas: $_" }
        }
    }
    catch {
        Write-CustomMessage "ERROR: Failed to execute CleanMgr. $_"
    }
}

#endregion

# region 7C - Optional: Remove C:\Windows.old (pref-gated, dry-run-aware)
if (-not $Pref_RemoveWindowsOld) {
    Write-CustomMessage "SKIPPED: Removal of C:\Windows.old is disabled by Pref_RemoveWindowsOld." -Level INFO
}
else {
    try {
        $windowsOld = Join-Path -Path $env:SystemDrive -ChildPath 'Windows.old'
        if (-not (Test-Path -Path $windowsOld)) {
            Write-CustomMessage "C:\\Windows.old not present; nothing to remove." -Level INFO
        }
        else {
            # Ensure the path is strictly the system-drive root Windows.old to avoid accidental deletes
            $resolved = (Get-Item -LiteralPath $windowsOld -ErrorAction SilentlyContinue)
            if (-not $resolved) { Write-CustomMessage "Could not resolve C:\\Windows.old; skipping." -Level WARN }
            else {
                # Safety checks: ensure resolved path is on the system drive and exactly ends with 'Windows.old'
                if (($resolved.FullName -ne $windowsOld) -or ($resolved.PSDrive.Name -ne (Get-Item -Path $env:SystemDrive).PSDrive.Name)) {
                    Write-CustomMessage "Path mismatch or not on system drive; refusing to remove $($resolved.FullName)." -Level ERROR
                }
                else {
                    # Report size and contents in dry-run; only delete when not DryRun
                    try {
                        $size = (Get-ChildItem -LiteralPath $windowsOld -Recurse -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum
                        $sizeMB = if ($size) { [math]::Round($size / 1MB, 2) } else { 0 }
                        Write-CustomMessage ("C:\\Windows.old present: {0} bytes ({1} MB)." -f ($size -or 0), $sizeMB)
                    }
                    catch { Write-CustomMessage "WARNING: Could not compute Windows.old size: $_" -Level WARN }

                    $whatIfRequested = $false
                    if ($PSBoundParameters.ContainsKey('WhatIf')) { $whatIfRequested = $true }

                    if ($whatIfRequested -or $DryRun) {
                        Write-CustomMessage "DRYRUN/WhatIf: Would remove C:\\Windows.old (pref enabled)." -Level INFO
                    }
                    else {
                        Write-CustomMessage "Removing C:\\Windows.old as requested by Pref_RemoveWindowsOld." -Level WARN
                        # Use existing safe removal helper if available; otherwise fallback to Remove-Item with retries
                        if (Get-Command -Name Invoke-RemoveWithRetry -ErrorAction SilentlyContinue) {
                            Invoke-RemoveWithRetry -Path $windowsOld -MaxRetries 3 -RetryDelaySeconds 2
                        }
                        else {
                            try { Remove-Item -LiteralPath $windowsOld -Recurse -Force -ErrorAction Stop; Write-CustomMessage "Removed C:\\Windows.old." }
                            catch { Write-CustomMessage ("ERROR: Failed to remove C:\\Windows.old: {0}" -f $_) -Level ERROR }
                        }
                    }
                }
            }
        }
    }
    catch { Write-CustomMessage ("ERROR: Windows.old removal step failed: {0}" -f $_) -Level ERROR }
}

# endregion

# region 8 - Wrap up and exit
# --- Ensure Merge-Log is called at the end of the script ---
try {
    # Run Merge-Log first to consolidate logs before final cleanup steps
    $merged = Merge-Log
    if (-not $merged) { Write-CustomMessage "WARNING: Merge-Log reported failure; temp log preserved in place and fallback archive attempted." }
}
catch {
    Write-Verbose "Failed to consolidate logs: $_"
}

# --- Validate temp log state after consolidation ---
if (-not (Test-Path -Path $tempLogFile)) {
    if ($DryRun -or $PreserveTempLog) {
        Write-CustomMessage "WARNING: Temporary log file was expected to remain available during wrap-up but was not found: $tempLogFile" -Level WARN
    }
    else {
        Write-Verbose "Temporary log file already absent during wrap-up: $tempLogFile"
    }
}


if ($transcriptStarted) {
    try {
        Stop-Transcript | Out-Null
        Write-CustomMessage "Log file saved to: $logFile"
    }
    catch {
        # Some hosts can report that transcription is not active even when Stop-Transcript is called.
        # Ignore that specific failure and continue; log verbose for diagnostics.
        Write-Verbose "Stop-Transcript returned an error but will be ignored: $_"
    }
}

# --- Enhanced error handling for temporary file cleanup ---
try {
    if (Test-Path -Path $tempLogFile) {
        if ($DryRun -or $PreserveTempLog) {
            Write-CustomMessage "Preserving temporary log file: $tempLogFile"
        }
        elseif ($merged) {
            Remove-Item -Path $tempLogFile -Force -ErrorAction Stop
        }
        else {
            Write-CustomMessage "Preserving temp log because merge did not complete successfully: $tempLogFile"
        }
    }
}
catch {
    if ($_.Exception -is [System.UnauthorizedAccessException]) {
        Write-Verbose "Access denied while attempting to delete temporary log file: $tempLogFile"
        Write-CustomMessage "WARNING: Access denied while attempting to delete temporary log file: $tempLogFile"
    }
    else {
        Write-Verbose "Failed to delete temporary log file: $_"
        Write-CustomMessage "ERROR: Failed to delete temporary log file: $_"
    }
}
# endregion

# region 8A - Ensure final disk space information is rendered
function Format-Size {
    param([int64]$Bytes)
    $mb = [math]::Round($Bytes / 1MB, 2)
    $gb = [math]::Round($Bytes / 1GB, 2)
    return "${mb} MB (${gb} GB)"
}

# Emit prune-summary: number of unique pruned branches and a sample of entries
try {
    $prunedCount = 0
    $sample = @()
    if ($script:PrunedBranches) {
        if ($script:PrunedBranches -is [System.Collections.IEnumerable]) {
            $prunedList = @($script:PrunedBranches)
            $prunedCount = $prunedList.Count
            $sample = $prunedList | Select-Object -First 10
        }
    }
    Write-CustomMessage ("Prune summary: Unique pruned branches={0}" -f $prunedCount)
    if ($sample.Count -gt 0) {
        foreach ($s in $sample) { Write-CustomMessage ("Pruned sample: {0}" -f $s) }
    }
}
catch { Write-Verbose "Prune-summary failed: $_" }

$finalFreeSpaceBytes = (Get-PSDrive -Name C).Free
$finalFreeSpaceGB = [math]::Round($finalFreeSpaceBytes / 1GB, 2)
$spaceRecoveredBytes = $finalFreeSpaceBytes - $freeSpaceBytes
$spaceRecoveredGB = [math]::Round($spaceRecoveredBytes / 1GB, 2)
Write-CustomMessage "Final free space: $finalFreeSpaceGB GB ($([math]::Round($finalFreeSpaceBytes/1MB,2)) MB)"
Write-CustomMessage "Space recovered: $spaceRecoveredGB GB ($([math]::Round($spaceRecoveredBytes/1MB,2)) MB)"
# endregion

# region 8C - Resolve log export failures
Write-CustomMessage "Note: Event-log exports were performed earlier; skipping redundant export loop in region 8C to avoid duplicate operations." -Level INFO
#endregion

# region 8D - Handle file locking issues during log consolidation
# Merge-Log already ran once at the start of wrap-up. Subsequent messages now write directly to the main log.

#endregion

# region 8E - Call Resolve-FileLock for temporary files (Test-FileLock and Resolve-FileLock are defined earlier)

if ($Pref_UserTempCleanup -or $Pref_GlobalTempCleanup) {
    Resolve-FileLock -DirectoryPath "$env:TEMP"
}

# endregion

# region 8I - Enhanced error handling for Move-Item
try {
    # If DryRun, compute a concise interactive summary of probes and free-space deltas and print it to host
    if ($DryRun) {
        try {
            $probePaths = $global:__InitialProbePaths
            try { $postSnapshot = Get-ProbeSnapshot -PathsToProbe $probePaths -IgnorePrune } catch { $postSnapshot = @{} }
            # Use Write-Host for guaranteed interactive output in consoles
            Write-Host "DRYRUN SUMMARY: Probe deltas follow (concise):"
            foreach ($p in $probePaths) {
                $preObj = $null; $postObj = $null
                if ($global:__PreSnapshot -and $global:__PreSnapshot.ContainsKey($p)) { $preObj = $global:__PreSnapshot[$p] }
                if ($postSnapshot.ContainsKey($p)) { $postObj = $postSnapshot[$p] }
                if ($null -ne $preObj) { $preBytes = [int64]$preObj.Bytes } else { $preBytes = 0 }
                if ($null -ne $postObj) { $postBytes = [int64]$postObj.Bytes } else { $postBytes = 0 }
                $delta = $preBytes - $postBytes
                $deltaMB = [math]::Round($delta / 1MB, 2)
                Write-Host ("DRYRUN: Path={0}, Freed={1} MB" -f $p, $deltaMB)
            }
            try {
                if ($null -ne $global:__InitialFreeSpace) {
                    $finalFree = (Get-PSDrive -Name C).Free
                    $deltaFree = $finalFree - $global:__InitialFreeSpace
                    $deltaFreeMB = [math]::Round($deltaFree / 1MB, 2)
                    Write-Host ("DRYRUN: FreeSpace change on C: {0} MB" -f $deltaFreeMB)
                }
            }
            catch { Write-Verbose "DRYRUN summary free-space compute failed: $_" }
        }
        catch { Write-Verbose "Failed to compute DRYRUN interactive summary: $_" }

        # Always provide a guaranteed concise DryRun summary visible to both interactive users
        # and non-interactive capture systems. This writes both to the host/pipeline and
        # creates a small per-run summary file in the archive directory.
        try {
            $summaryLine = "DRYRUN: Detailed actions were recorded to the temp log; preserved at: $tempLogFile"
            try { Write-Host $summaryLine } catch {}
            try { Write-Output $summaryLine } catch {}

            # Write a small per-run summary file next to the archive for automation and auditing
            try {
                if (-not (Test-Path -Path $archiveDirectory)) { New-Item -ItemType Directory -Path $archiveDirectory -Force | Out-Null }
                $summaryFile = Join-Path -Path $archiveDirectory -ChildPath ("${scriptName}_dryrun_summary_{0}.txt" -f (Get-Date -Format 'yyyyMMdd_HHmmss'))
                $summaryContent = @()
                $summaryContent += $summaryLine
                foreach ($p in $probePaths) {
                    $preObj = $null; $postObj = $null
                    if ($global:__PreSnapshot -and $global:__PreSnapshot.ContainsKey($p)) { $preObj = $global:__PreSnapshot[$p] }
                    if ($postSnapshot.ContainsKey($p)) { $postObj = $postSnapshot[$p] }
                    if ($null -ne $preObj) { $preBytes = [int64]$preObj.Bytes } else { $preBytes = 0 }
                    if ($null -ne $postObj) { $postBytes = [int64]$postObj.Bytes } else { $postBytes = 0 }
                    $delta = $preBytes - $postBytes
                    $deltaMB = [math]::Round($delta / 1MB, 2)
                    $summaryContent += ("Path={0}, Freed={1} MB" -f $p, $deltaMB)
                }
                if ($null -ne $global:__InitialFreeSpace) {
                    try {
                        $finalFree = (Get-PSDrive -Name C).Free
                        $deltaFreeMB = [math]::Round((($finalFree - $global:__InitialFreeSpace) / 1MB), 2)
                        $summaryContent += ("FreeSpaceChangeMB={0}" -f $deltaFreeMB)
                    }
                    catch { $summaryContent += "FreeSpaceChangeMB=unknown" }
                }
                # Also append the concise summary into the main log so Save-MainLogArchive will include it
                try {
                    foreach ($line in $summaryContent) {
                        $ts = (Get-Date).ToString('yyyy-MM-dd HH:mm:ss')
                        Add-Content -Path $logFile -Value ("$ts - INFO - $line") -ErrorAction SilentlyContinue
                    }
                }
                catch { Write-Verbose "Failed to append DRYRUN summary to main log: $_" }

                $summaryContent | Out-File -FilePath $summaryFile -Encoding UTF8 -Force
                try { Write-Host ("DRYRUN SUMMARY FILE: {0}" -f $summaryFile) } catch {}
                try { Write-Output ("DRYRUN SUMMARY FILE: {0}" -f $summaryFile) } catch {}
            }
            catch { Write-Verbose "Failed to write DRYRUN summary file: $_" }
        }
        catch {}
    }

    $ok = Save-MainLogArchive -MainLogPath $logFile -ArchiveDir $archiveDirectory -ArchivePath $archiveFile
    if (-not $ok) {
        Write-CustomMessage "WARNING: Save-MainLogArchive returned false"
    }
    # Emit a single host-visible summary line so Intune and other capture mechanisms have a pointer to full logs.
    try {
        if ($script:LastPerRunArchive) {
            Write-Output ("Run complete. Full run log archived to: {0}" -f $script:LastPerRunArchive)
        }
        elseif (Test-Path -Path $logFile) {
            Write-Output ("Run complete. Main log path: {0} (may be truncated/rotated)." -f $logFile)
        }
        else {
            Write-Output "Run complete. No main log file could be located; check temp logs in $env:TEMP for details."
        }

        if (Test-Path -Path $tempLogFile) {
            Write-Output ("Note: temporary log preserved at: {0}" -f $tempLogFile)
        }
        elseif ($PreserveTempLog -or $DryRun) {
            Write-Output ("WARNING: Temporary log was expected to be preserved but was not found: {0}" -f $tempLogFile)
        }
    }
    catch {
        Write-Output "Run complete. (Failed to produce host summary: $_)"
    }
}
catch {
    Write-Verbose "Save-MainLogArchive threw an exception: $_"
}

#endregion

# Script complete