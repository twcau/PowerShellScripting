<#
.SYNOPSIS
    Control a single local read-only Word export behind a testable private adapter.
.DESCRIPTION
    Called only by the fixed worker. Request JSON cannot supply an adapter or code.
    Ownership is durably recorded before Open; external supervision owns deadlines.
.FILECREATED
    2026-10-24
.FILELASTUPDATED
    2026-11-03
#>
function Invoke-AutopilotDocumentWordExport {
    <#
    .SYNOPSIS
        Validate data, export one owned copy and report cleanup without publishing.
    .PARAMETER Request
        SchemaVersion/JobId/JobDirectory/SourcePath/SourceSHA256/PendingPdfPath/OwnershipPath.
    .PARAMETER Adapter
        Private test-only operation dictionary; never accepted from job JSON.
    .PARAMETER KeepWordOpen
        Prepared-worker mode: close only the exported document and leave the owned Word instance for reuse;
        an existing ownership record is then expected. Without it, cleanup closes Word.
    .OUTPUTS
        Exported/Failed result, digest and explicit cleanup state. Not a print receipt.
    #>
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'None')]
    [OutputType([Collections.Specialized.OrderedDictionary])]
    param(
        [Parameter(Mandatory)][ValidateNotNull()][Collections.IDictionary]$Request,
        [Collections.IDictionary]$Adapter,
        [switch]$KeepWordOpen
    )
    $result = [ordered]@{ Status = 'Failed'; Diagnostic = ''; Cleanup = 'NotStarted'; WordLaunchAttempted = $false; WordProcessId = 0; Pdf = $null }
    $result.Timings = [ordered]@{ StartMilliseconds = 0L; OpenMilliseconds = 0L; ExportMilliseconds = 0L; CloseMilliseconds = 0L }
    $phaseClock = [Diagnostics.Stopwatch]::StartNew()
    $source = $null; $sha = $null
    try {
        $jobGuid = [guid]::Empty
        if ($Request['SchemaVersion'] -ne 1 -or -not [guid]::TryParse([string]$Request['JobId'], [ref]$jobGuid) -or $jobGuid -eq [guid]::Empty -or $Request['SourceSHA256'] -cnotmatch '^[A-F0-9]{64}$') { throw 'Invalid Word export identity/schema or source digest.' }
        $root = Resolve-AutopilotDocumentLocalPath -Path ([string]$Request['JobDirectory'])
        if (-not (Test-Path -LiteralPath $root -PathType Container)) { throw 'Word job directory must already exist.' }
        $paths = @{}
        foreach ($key in @('SourcePath','PendingPdfPath','OwnershipPath')) {
            $path = [string]$Request[$key]; $leaf = [IO.Path]::GetFileName($path)
            if ([string]::IsNullOrWhiteSpace($leaf) -or $leaf.IndexOfAny([IO.Path]::GetInvalidFileNameChars()) -ge 0) { throw 'Invalid Word job leaf name.' }
            $parent = Resolve-AutopilotDocumentLocalPath -Path ([IO.Path]::GetDirectoryName($path))
            if ($parent -ine $root) { throw 'Word job files must belong to the explicit local job directory.' }
            $paths[$key] = Join-Path $parent $leaf
        }
        if ([IO.Path]::GetExtension($paths.SourcePath) -ine '.docx' -or [IO.Path]::GetExtension($paths.PendingPdfPath) -ine '.pdf' -or [IO.Path]::GetExtension($paths.OwnershipPath) -ine '.json' -or (Test-Path -LiteralPath $paths.PendingPdfPath) -or ((Test-Path -LiteralPath $paths.OwnershipPath) -and -not $KeepWordOpen)) { throw 'Export requires a DOCX and new, distinct PDF/ownership paths.' }
        $file = Get-Item -LiteralPath $paths.SourcePath -Force -ErrorAction Stop
        if ($file.Length -gt 33554432 -or ($file.Attributes -band [IO.FileAttributes]::ReparsePoint)) { throw 'Invalid owned DOCX size or attributes.' }
        $source = [IO.File]::Open($paths.SourcePath, [IO.FileMode]::Open, [IO.FileAccess]::Read, [IO.FileShare]::Read)
        $sha = [Security.Cryptography.SHA256]::Create()
        if ([BitConverter]::ToString($sha.ComputeHash($source)).Replace('-', '') -cne $Request['SourceSHA256']) { throw 'Owned DOCX digest changed before Word export.' }
        if (-not $PSCmdlet.ShouldProcess($paths.SourcePath, 'Export the owned local copy through desktop Word; no printing')) { $result.Status = 'WhatIf'; return $result }
        if ($null -eq $Adapter) { $Adapter = New-AutopilotDocumentWordAdapter }
        foreach ($name in @('Start','Open','Export','Close')) { if ($Adapter[$name] -isnot [scriptblock]) { throw 'Invalid private Word adapter.' } }
        $result.WordLaunchAttempted = $true
        $phaseClock.Restart()
        $identity = & $Adapter.Start
        $result.Timings.StartMilliseconds = $phaseClock.ElapsedMilliseconds
        if ($identity.WordProcessId -le 0 -or $identity.StartTimeUtcTicks -le 0 -or $identity.ProcessName -ine 'WINWORD') { throw 'Invalid owned Word identity.' }
        $result.WordProcessId = $identity.WordProcessId
        $ownership = [ordered]@{ SchemaVersion = 1; JobId = $jobGuid.ToString('D'); WorkerPid = $PID; WordProcessId = $identity.WordProcessId; StartTimeUtcTicks = $identity.StartTimeUtcTicks; ProcessName = 'WINWORD' }
        if (Test-Path -LiteralPath $paths.OwnershipPath) {
            $priorOwner = Get-Content -LiteralPath $paths.OwnershipPath -Raw -Encoding UTF8 | ConvertFrom-Json -ErrorAction Stop
            foreach ($key in @('JobId','WorkerPid','WordProcessId','StartTimeUtcTicks','ProcessName')) { if ([string]$priorOwner.$key -cne [string]$ownership[$key]) { throw 'Shared Word ownership record differs from this job instance.' } }
        }
        else {
            $record = [IO.File]::Open($paths.OwnershipPath, [IO.FileMode]::CreateNew, [IO.FileAccess]::Write, [IO.FileShare]::Read)
            try { $bytes = [Text.Encoding]::UTF8.GetBytes(($ownership | ConvertTo-Json -Compress)); $record.Write($bytes, 0, $bytes.Length); $record.Flush($true) } finally { $record.Dispose() }
        }
        $phaseClock.Restart()
        & $Adapter.Open $paths.SourcePath
        $result.Timings.OpenMilliseconds = $phaseClock.ElapsedMilliseconds
        $phaseClock.Restart()
        & $Adapter.Export $paths.PendingPdfPath ([int]$Request['ExpectedPageCount'])
        $result.Timings.ExportMilliseconds = $phaseClock.ElapsedMilliseconds
        $result.Pdf = Get-AutopilotDocumentPdfInfo -Path $paths.PendingPdfPath
        $result.Status = 'Exported'
    }
    catch { $result.Diagnostic = 'Word export failed: {0}' -f $_.Exception.Message }
    finally {
        if ($result.WordLaunchAttempted) {
            try {
                $phaseClock.Restart()
                if ($KeepWordOpen) { & $Adapter.CloseDocument }
                else { & $Adapter.Close }
                $result.Timings.CloseMilliseconds = $phaseClock.ElapsedMilliseconds
                $result.Cleanup = 'Complete'
            }
            catch { $result.Status = 'Failed'; $result.Cleanup = 'Uncertain'; $result.Diagnostic = '{0} Cleanup: {1}' -f $result.Diagnostic, $_.Exception.Message }
        }
        if ($null -ne $sha) { $sha.Dispose() }; if ($null -ne $source) { $source.Dispose() }
    }
    return $result
}