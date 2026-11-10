<#
.SYNOPSIS
    Stage a detached dispatched job and return promptly with an owned supervisor.
.DESCRIPTION
    No Graph or SDK loads in the caller. Templates are copied with shared read
    access, originals untouched. The fixed external supervisor owns deadlines.
.FILECREATED
    2026-10-24
.FILELASTUPDATED
    2026-10-29
#>
function Start-AutopilotDocumentJob {
    <#
    .SYNOPSIS
        Start optional output only after committed dispatch or explicit document retry.
    .PARAMETER Job
        Detached New-AutopilotDocumentJob output; null does nothing before host probes.
    .PARAMETER DependencyRoot
        Previously approved verified local bundle directory; acquisition is foreground-only.
    .PARAMETER ReviewOnly
        Explicit draft review requests never print, even when testing guards are off.
    .PARAMETER PrintApproved
        Explicit foreground consent for GenerateAndAsk, never a worker prompt.
    .PARAMETER ExplicitRetry
        Reuse this job's retained outputs/receipt for deliberate document-only retry.
    .PARAMETER EnforceDocumentGuards
        False (testing default) permits unapproved profiles and Demo printing.
        True restores DRAFT/non-printing guards. Demo page labels always apply.
    .PARAMETER PreparationSettings
        Validated settings for one device-free, one-use prepared SDK/Word worker.
    .PARAMETER PreparedWorker
        Live preparation handle owned by this caller, never deserialised job input.
    .PARAMETER StopPreparation
        Request graceful cancellation of an unused prepared worker.
    .OUTPUTS
        Supervisor handle dictionary for Receive-AutopilotDocumentJob; no waiting for Word.
    #>
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'None')]
    [OutputType([Collections.Specialized.OrderedDictionary])]
    param(
        [AllowNull()][Collections.IDictionary]$Job,
        [Parameter(Mandatory)][ValidateNotNullOrEmpty()][string]$DependencyRoot,
        [bool]$ReviewOnly = $true,
        [switch]$PrintApproved,
        [switch]$ExplicitRetry,
        [bool]$EnforceDocumentGuards = $false,
        [Collections.IDictionary]$PreparationSettings,
        [Collections.IDictionary]$PreparedWorker,
        [switch]$StopPreparation
    )
    if ($StopPreparation) {
        if (-not $PSCmdlet.ShouldProcess('Unused owned document preparation', 'Cancel preparation without delivery')) { return }
        if ($PreparedWorker -and $PreparedWorker['Status'] -in @('Preparing','Stopping')) {
            $process = $PreparedWorker['Process']
            if (-not $process.HasExited) {
                if ($process.StartTime.ToUniversalTime().Ticks -ne $PreparedWorker['ProcessStartTimeUtcTicks']) { throw 'Preparation process identity changed.' }
                if ($PreparedWorker['Status'] -eq 'Preparing') { $process.StandardInput.WriteLine('Stop'); $process.StandardInput.Flush(); $PreparedWorker['Status'] = 'Stopping' }
                if (-not $process.WaitForExit(15000)) { throw 'Preparation shutdown is pending; its supervisor retains exact ownership cleanup.' }
            }
            $process.Dispose()
            $PreparedWorker['Status'] = 'Stopped'
        }
        return
    }
    if ($PreparationSettings) {
        if ($PreparationSettings['SchemaVersion'] -ne 1) { throw 'Invalid preparation settings.' }
        $profiles = @()
        foreach ($type in @('BirthCertificate','Checklist')) {
            if ($PreparationSettings['Values'][('{0}Enabled' -f $type)] -and $PreparationSettings['Values'][('{0}Mode' -f $type)] -ne 'Disabled') {
                $profiles += @{ DocumentType = $type; TemplatePath = $PreparationSettings['Values'][('{0}TemplatePath' -f $type)] }
            }
        }
        if (-not $profiles.Count) { return }
        $capability = Get-AutopilotDocumentHostCapability
        if (-not $capability.WorkerAvailable -or -not $capability.WordRegistrationDetected -or -not (Test-AutopilotDocumentDependencyBundle -DependencyRoot $DependencyRoot).Valid) { throw 'Prepare documents only after successful prerequisite checks.' }
        $preparationId = [guid]::NewGuid().ToString('D')
        $directory = Resolve-AutopilotDocumentLocalPath -Path (Join-Path (Join-Path $PreparationSettings['Values']['LocalRoot'] 'Preparation') $preparationId)
        if (-not $PSCmdlet.ShouldProcess($directory, 'Prepare one owned SDK/Word worker without device data or delivery')) { return [ordered]@{ Status = 'WhatIf' } }
        $null = [IO.Directory]::CreateDirectory($directory)
        foreach ($documentProfile in $profiles) {
            $snapshot = Join-Path $directory ('{0}.template.docx' -f $documentProfile.DocumentType)
            $source = [IO.File]::Open($documentProfile.TemplatePath, [IO.FileMode]::Open, [IO.FileAccess]::Read, ([IO.FileShare]::ReadWrite -bor [IO.FileShare]::Delete))
            try { $target = [IO.File]::Open($snapshot, [IO.FileMode]::CreateNew, [IO.FileAccess]::Write, [IO.FileShare]::None); try { $source.CopyTo($target) } finally { $target.Dispose() } } finally { $source.Dispose() }
        }
        $owner = [Diagnostics.Process]::GetCurrentProcess()
        try { $ownerTicks = $owner.StartTime.ToUniversalTime().Ticks } finally { $owner.Dispose() }
        $requestPath = Join-Path $directory 'Preparation.json'
        $preparation = @{ SchemaVersion = 1; Owner = 'AutopilotExpress.Documents'; PreparationId = $preparationId; Directory = $directory; DependencyRoot = $DependencyRoot; Profiles = $profiles; OwnerPid = $PID; OwnerStartTimeUtcTicks = $ownerTicks }
        [IO.File]::WriteAllText($requestPath, ($preparation | ConvertTo-Json -Depth 6 -Compress), [Text.UTF8Encoding]::new($false))
        $start = [Diagnostics.ProcessStartInfo]::new()
        $start.FileName = $capability.WorkerExecutable
        $start.Arguments = '-NoProfile -NonInteractive -File "{0}" -RequestPath "{1}" -Prepare' -f (Join-Path $moduleRoot 'Workers/Run-DocumentJob.ps1'), $requestPath
        $start.UseShellExecute = $false; $start.CreateNoWindow = $true; $start.RedirectStandardInput = $true; $start.RedirectStandardOutput = $true; $start.RedirectStandardError = $true
        $start.StandardOutputEncoding = [Text.UTF8Encoding]::new($false); $start.StandardErrorEncoding = [Text.UTF8Encoding]::new($false)
        $start.EnvironmentVariables['PSModulePath'] = Join-Path $env:WINDIR 'System32/WindowsPowerShell/v1.0/Modules'
        $process = [Diagnostics.Process]::new(); $process.StartInfo = $start
        if (-not $process.Start()) { $process.Dispose(); throw 'Document preparation supervisor did not start.' }
        return [ordered]@{ Status = 'Preparing'; PreparationId = $preparationId; Process = $process; ProcessStartTimeUtcTicks = $process.StartTime.ToUniversalTime().Ticks; StandardOutput = $process.StandardOutput.ReadToEndAsync(); StandardError = $process.StandardError.ReadToEndAsync(); Directory = $directory; ReadyPath = Join-Path $directory 'Ready.json'; DependencyRoot = $DependencyRoot }
    }
    if ($null -eq $Job -or -not @($Job['Profiles'] | Where-Object { $_ }).Count) { return $null }
    $identifier = [guid]::Empty
    if ($Job['SchemaVersion'] -ne 1 -or -not [guid]::TryParseExact([string]$Job['JobId'], 'D', [ref]$identifier)) { throw 'Invalid document job identity.' }
    $completedReceipt = $null
    if ($Job.Contains('OutputRoot')) {
        $completedPath = Join-Path (Resolve-AutopilotDocumentLocalPath -Path $Job['OutputRoot']) ('Job-{0}.receipt.json' -f $identifier.ToString('D'))
        if (Test-Path -LiteralPath $completedPath) {
            $completedFile = Get-Item -LiteralPath $completedPath -Force
            if ($completedFile.PSIsContainer -or $completedFile.Length -gt 65536 -or ($completedFile.Attributes -band [IO.FileAttributes]::ReparsePoint)) { throw 'Unsafe compact completed-job receipt.' }
            $completedReceipt = ConvertTo-AutopilotDocumentDictionary -Value (Get-Content -LiteralPath $completedPath -Raw -Encoding UTF8 | ConvertFrom-Json -ErrorAction Stop)
            if ($completedReceipt['Owner'] -cne 'AutopilotExpress.Documents' -or $completedReceipt['SchemaVersion'] -ne 1 -or $completedReceipt['AutomaticReplayAllowed'] -isnot [bool] -or $completedReceipt['AutomaticReplayAllowed']) { throw 'Invalid completed-job no-replay contract.' }
            foreach ($key in @('JobId','RecordId','BuildCycleId','Mode','TenantId')) { if ([string]$completedReceipt[$key] -cne [string]$Job[$key]) { throw 'Completed receipt belongs to another job scope.' } }
            if (-not $ExplicitRetry) { return [ordered]@{ SchemaVersion = 1; JobId = $Job['JobId']; Status = 'Completed'; Results = @($completedReceipt['Results']); Cleanup = 'Complete'; JobDirectory = ''; ReceiptPath = $completedPath } }
        }
    }
    $hostCapability = Get-AutopilotDocumentHostCapability
    if (-not $hostCapability.WorkerAvailable -or -not $hostCapability.WordRegistrationDetected) { throw 'Optional documents unavailable: Desktop worker or Word registration missing.' }
    if (-not (Test-AutopilotDocumentDependencyBundle -DependencyRoot $DependencyRoot).Valid) { throw 'Optional document bundle must be approved and verified before dispatch.' }
    $leaf = if ($Job.Contains('JobDirectoryName')) { $Job['JobDirectoryName'] } else { $Job['JobId'] }
    $directory = Resolve-AutopilotDocumentLocalPath -Path (Join-Path $Job['JobRoot'] $leaf)
    if (-not (Test-AutopilotDocumentJobDirectory -Directory $directory -JobId $identifier)) { throw 'Readable job folder does not match its immutable identity.' }
    if (-not $PSCmdlet.ShouldProcess($directory, 'Stage detached job and start bounded document supervisor')) { return [ordered]@{ Status = 'WhatIf' } }
    $retryReceipts = @()
    if ($ExplicitRetry -and (Test-Path -LiteralPath $directory)) {
        $lifecyclePath = Join-Path $directory 'job-lifecycle.json'
        $lifecycleFile = Get-Item -LiteralPath $lifecyclePath -Force -ErrorAction Stop
        if ($lifecycleFile.Length -gt 65536 -or ($lifecycleFile.Attributes -band [IO.FileAttributes]::ReparsePoint)) { throw 'Unsafe retry lifecycle.' }
        $lifecycle = Get-Content -LiteralPath $lifecyclePath -Raw -Encoding UTF8 | ConvertFrom-Json -ErrorAction Stop
        if ($lifecycle.Owner -cne 'AutopilotExpress.Documents' -or $lifecycle.JobId -cne $Job['JobId'] -or $lifecycle.Active -ne $false) { throw 'Active or uncertain jobs cannot be automatically retried; retain and review their ownership evidence.' }
        $retryLease = [IO.File]::Open((Join-Path $directory 'job.lock'), [IO.FileMode]::Open, [IO.FileAccess]::ReadWrite, [IO.FileShare]::None)
        try {
            foreach ($documentProfile in $Job['Profiles']) {
                $path = Join-Path $directory ('{0}-{1}.receipt.json' -f $Job['JobId'], $documentProfile['DocumentType'])
                if (-not (Test-Path -LiteralPath $path)) { continue }
                $receiptFile = Get-Item -LiteralPath $path -Force
                if ($receiptFile.Length -gt 65536 -or ($receiptFile.Attributes -band [IO.FileAttributes]::ReparsePoint)) { throw 'Unsafe retry receipt.' }
                $receipt = ConvertTo-AutopilotDocumentDictionary -Value (Get-Content -LiteralPath $path -Raw -Encoding UTF8 | ConvertFrom-Json -ErrorAction Stop)
                foreach ($key in @('JobId','RecordId','BuildCycleId','Mode','TenantId')) { if ([string]$receipt[$key] -cne [string]$Job[$key]) { throw 'Retry receipt identity mismatch.' } }
                if ($receipt['PdfPath']) { $retryReceipts += ,$receipt }
            }
        }
        finally { $retryLease.Dispose() }
        $failedRoot = Resolve-AutopilotDocumentLocalPath -Path (Join-Path (Split-Path -Parent $Job['JobRoot']) 'FailedJobs')
        $null = [IO.Directory]::CreateDirectory($failedRoot)
        $retainedPath = Join-Path $failedRoot ('{0}_BeforeRetry-{1}' -f $leaf, [DateTime]::UtcNow.Ticks)
        [IO.Directory]::Move($directory, $retainedPath)
        Write-Verbose ('Previous attempt retained before explicit retry: {0}' -f $retainedPath)
    }
    $null = [IO.Directory]::CreateDirectory($directory)
    if ($null -ne $completedReceipt -or $retryReceipts.Count) {
        $receipts = if ($null -ne $completedReceipt) { @($completedReceipt['Results']) } else { $retryReceipts }
        foreach ($receipt in $receipts) {
            $receiptPath = Join-Path $directory ('{0}-{1}.receipt.json' -f $Job['JobId'], $receipt['DocumentType'])
            if (-not (Test-Path -LiteralPath $receiptPath)) { Write-AutopilotDocumentReceipt -Path $receiptPath -Receipt $receipt }
        }
    }
    foreach ($documentProfile in $Job['Profiles']) {
        $type = [string]$documentProfile['DocumentType']
        if ($type -cnotin @('BirthCertificate','Checklist')) { throw 'Invalid document job profile.' }
        $savedPath = Join-Path $directory ('{0}-{1}.receipt.json' -f $Job['JobId'], $type)
        if ($ExplicitRetry -and (Test-Path -LiteralPath $savedPath)) {
            $savedFile = Get-Item -LiteralPath $savedPath -Force
            if ($savedFile.Length -gt 65536 -or ($savedFile.Attributes -band [IO.FileAttributes]::ReparsePoint)) { throw 'Unsafe retry receipt.' }
            $savedReceipt = Get-Content -LiteralPath $savedPath -Raw -Encoding UTF8 | ConvertFrom-Json -ErrorAction Stop
            if ($savedReceipt.JobId -cne $Job['JobId'] -or $savedReceipt.DocumentType -cne $type) { throw 'Retry receipt identity mismatch.' }
            if ($savedReceipt.PdfPath) { continue }
        }
        $snapshot = Join-Path $directory ('{0}.template.docx' -f $type)
        $source = [IO.File]::Open([string]$documentProfile['TemplatePath'], [IO.FileMode]::Open, [IO.FileAccess]::Read, ([IO.FileShare]::ReadWrite -bor [IO.FileShare]::Delete))
        try {
            $target = [IO.File]::Open($snapshot, [IO.FileMode]::CreateNew, [IO.FileAccess]::Write, [IO.FileShare]::None)
            try { $source.CopyTo($target); $target.Flush($true) } finally { $target.Dispose() }
        }
        finally { $source.Dispose() }
    }
    $requestPath = Join-Path $directory ('job-request-{0}.json' -f [guid]::NewGuid().ToString('N'))
    $usePrepared = $null -ne $PreparedWorker -and $PreparedWorker['Status'] -eq 'Preparing' -and -not $PreparedWorker['Process'].HasExited -and $PreparedWorker['DependencyRoot'] -ieq $DependencyRoot -and $PreparedWorker['Process'].StartTime.ToUniversalTime().Ticks -eq $PreparedWorker['ProcessStartTimeUtcTicks']
    $request = @{ SchemaVersion = 1; Job = $Job; JobDirectory = $directory; DependencyRoot = $DependencyRoot; ReviewOnly = $ReviewOnly; PrintApproved = [bool]$PrintApproved; ExplicitRetry = [bool]$ExplicitRetry; EnforceDocumentGuards = $EnforceDocumentGuards; PreparationId = if ($usePrepared) { $PreparedWorker['PreparationId'] } else { '' } }
    $bytes = [Text.UTF8Encoding]::new($false).GetBytes(($request | ConvertTo-Json -Depth 20 -Compress))
    if ($bytes.Length -gt 1048576) { throw 'Detached document job exceeds its bound.' }
    $stream = [IO.File]::Open($requestPath, [IO.FileMode]::CreateNew, [IO.FileAccess]::Write, [IO.FileShare]::None)
    try { $stream.Write($bytes, 0, $bytes.Length); $stream.Flush($true) } finally { $stream.Dispose() }
    if ($usePrepared) {
        $PreparedWorker['Process'].StandardInput.WriteLine($requestPath)
        $PreparedWorker['Process'].StandardInput.Flush()
        $PreparedWorker['Status'] = 'Consumed'
        return [ordered]@{ Status = 'Running'; JobId = $Job['JobId']; Process = $PreparedWorker['Process']; StandardOutput = $PreparedWorker['StandardOutput']; StandardError = $PreparedWorker['StandardError']; JobDirectory = $directory; RequestPath = $requestPath; PreparedWorkerUsed = $true }
    }
    $start = [Diagnostics.ProcessStartInfo]::new()
    $start.FileName = $hostCapability.WorkerExecutable
    $start.Arguments = '-NoProfile -NonInteractive -File "{0}" -RequestPath "{1}"' -f (Join-Path $moduleRoot 'Workers/Run-DocumentJob.ps1'), $requestPath
    $start.UseShellExecute = $false; $start.CreateNoWindow = $true; $start.RedirectStandardOutput = $true; $start.RedirectStandardError = $true
    $start.StandardOutputEncoding = [Text.UTF8Encoding]::new($false); $start.StandardErrorEncoding = [Text.UTF8Encoding]::new($false)
    $start.EnvironmentVariables['PSModulePath'] = Join-Path $env:WINDIR 'System32/WindowsPowerShell/v1.0/Modules'
    $process = [Diagnostics.Process]::new(); $process.StartInfo = $start
    if (-not $process.Start()) { $process.Dispose(); throw 'Document supervisor did not start.' }
    return [ordered]@{ Status = 'Running'; JobId = $Job['JobId']; Process = $process; StandardOutput = $process.StandardOutput.ReadToEndAsync(); StandardError = $process.StandardError.ReadToEndAsync(); JobDirectory = $directory; RequestPath = $requestPath }
}