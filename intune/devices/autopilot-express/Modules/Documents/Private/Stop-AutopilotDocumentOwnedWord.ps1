<#
.SYNOPSIS
    Stop only the exact newly owned Word process recorded by the fixed worker.
.DESCRIPTION
    Missing/malformed identity is uncertainty, never permission to kill by name.
    A process handle and start time guard against PID reuse; existing instances
    and any process in another interactive session are explicitly excluded.
.FILECREATED
    2026-10-24
.FILELASTUPDATED
    2026-10-24
#>
function Stop-AutopilotDocumentOwnedWord {
    <#
    .SYNOPSIS
        Independently verify cleanup identity after worker exit or timeout.
    .PARAMETER OwnershipPath
        Worker-created local bounded JSON ownership record.
    .PARAMETER JobId
        Expected job identity, not taken from the record.
    .PARAMETER WorkerPid
        Expected owned child process, not taken from the record.
    .PARAMETER ExcludedProcessIds
        All Word processes observed before launching this child.
    .OUTPUTS
        NotRunning, Stopped or Uncertain. Never terminates an unproved process.
    #>
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'None')]
    [OutputType([string])]
    param(
        [Parameter(Mandatory)][ValidateNotNullOrEmpty()][string]$OwnershipPath,
        [Parameter(Mandatory)][guid]$JobId,
        [Parameter(Mandatory)][ValidateRange(1, 2147483647)][int]$WorkerPid,
        [AllowEmptyCollection()][int[]]$ExcludedProcessIds = @()
    )
    $process = $null
    try {
        $file = Get-Item -LiteralPath $OwnershipPath -Force -ErrorAction Stop
        if ($file.Length -gt 8192 -or ($file.Attributes -band [IO.FileAttributes]::ReparsePoint)) { return 'Uncertain' }
        $record = Get-Content -LiteralPath $OwnershipPath -Raw -Encoding UTF8 -ErrorAction Stop | ConvertFrom-Json -ErrorAction Stop
        $wordProcessId = 0
        if ($record.SchemaVersion -ne 1 -or $record.JobId -ine $JobId.ToString('D') -or $record.WorkerPid -ne $WorkerPid -or $record.ProcessName -ine 'WINWORD' -or -not [int]::TryParse([string]$record.WordProcessId, [ref]$wordProcessId) -or $wordProcessId -le 0 -or $wordProcessId -in $ExcludedProcessIds -or $wordProcessId -eq $PID -or $wordProcessId -eq $WorkerPid -or $record.StartTimeUtcTicks -le 0) { return 'Uncertain' }
        try { $process = Get-Process -Id $wordProcessId -ErrorAction Stop }
        catch { if ($_.CategoryInfo.Category -eq 'ObjectNotFound') { return 'NotRunning' }; return 'Uncertain' }
        $null = $process.Handle
        if ($process.ProcessName -ine 'WINWORD' -or $process.StartTime.ToUniversalTime().Ticks -ne [long]$record.StartTimeUtcTicks -or $process.SessionId -ne [Diagnostics.Process]::GetCurrentProcess().SessionId) { return 'Uncertain' }
        if (-not $PSCmdlet.ShouldProcess(('Owned WINWORD PID {0}' -f $wordProcessId), 'Stop the identity-verified document worker instance only')) { return 'Uncertain' }
        $process.Kill()
        if (-not $process.WaitForExit(5000)) { return 'Uncertain' }
        return 'Stopped'
    }
    catch { return 'Uncertain' }
    finally { if ($null -ne $process) { $process.Dispose() } }
}