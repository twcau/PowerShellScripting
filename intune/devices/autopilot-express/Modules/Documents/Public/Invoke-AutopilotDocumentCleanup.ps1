<#
.SYNOPSIS
    Compact verified successful document jobs and retain failed-job evidence.
.DESCRIPTION
    Successful jobs keep published PDFs and one durable no-replay receipt, then
    permanently remove only proven owned staging under the explicit approval.
    Failed-job expiry remains reversible. Active, uncertain and unowned evidence
    is retained. Explicit legacy-review migration logs every move and removal.
.FILECREATED
    2026-10-24
.FILELASTUPDATED
    2026-10-25
#>
function Invoke-AutopilotDocumentCleanup {
    <#
    .SYNOPSIS
        Reconcile successful leftovers and failed assets within one owned root.
    .PARAMETER JobRoot
        Feature-owned Working/jobs root with immutable GUID-bound child names.
    .PARAMETER FailedJobRetentionDays
        Seven by default. Zero disables failed-asset expiry, not successful cleanup.
    .PARAMETER NowUtc
        Trusted clock for deterministic offline tests.
    .PARAMETER ReorganiseReviews
        Explicit legacy-review migration. JobRoot must be the feature Documents
        directory. Preserves final outputs and failure evidence with a path log.
    .OUTPUTS
        Removed temporary-file counts, reversible archive moves and retained skips.
    #>
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'None')]
    [OutputType([Collections.Specialized.OrderedDictionary])]
    param(
        [Parameter(Mandatory)][ValidateNotNullOrEmpty()][string]$JobRoot,
        [ValidateRange(0,3650)][int]$FailedJobRetentionDays = 7,
        [DateTimeOffset]$NowUtc = [DateTimeOffset]::UtcNow,
        [switch]$ReorganiseReviews
    )
    if ($ReorganiseReviews) { return Move-AutopilotDocumentReviewArtifacts -DocumentRoot $JobRoot -WhatIf:$WhatIfPreference }
    $result = [ordered]@{ Moved = 0; Removed = 0; Skipped = 0; Actions = [Collections.Generic.List[object]]::new() }
    $root = Resolve-AutopilotDocumentLocalPath -Path $JobRoot
    if (-not (Test-Path -LiteralPath $root -PathType Container)) { return $result }
    foreach ($directory in Get-ChildItem -LiteralPath $root -Directory -Force) {
        $lease = $null
        try {
            $identifier = [guid]::Empty
            if ($directory.Attributes -band [IO.FileAttributes]::ReparsePoint) { throw 'Reparse job directory is not owned staging.' }
            $null = Resolve-AutopilotDocumentLocalPath -Path $directory.FullName
            $metadataPath = Join-Path $directory.FullName 'job-lifecycle.json'
            $metadataFile = Get-Item -LiteralPath $metadataPath -Force -ErrorAction Stop
            if ($metadataFile.Length -gt 65536 -or ($metadataFile.Attributes -band [IO.FileAttributes]::ReparsePoint)) { throw 'Unsafe lifecycle metadata.' }
            $metadata = ConvertTo-AutopilotDocumentDictionary -Value (Get-Content -LiteralPath $metadataPath -Raw -Encoding UTF8 | ConvertFrom-Json -ErrorAction Stop)
            if (-not [guid]::TryParseExact([string]$metadata['JobId'], 'D', [ref]$identifier) -or -not (Test-AutopilotDocumentJobDirectory -Directory $directory.FullName -JobId $identifier) -or $metadata['SchemaVersion'] -ne 1 -or $metadata['Owner'] -cne 'AutopilotExpress.Documents' -or $metadata['Active'] -isnot [bool] -or $metadata['Active']) { throw 'Job is active or not owned.' }
            if ($metadata['State'] -ceq 'Succeeded' -and $metadata['Result'] -is [Collections.IDictionary]) {
                $requests = @(Get-ChildItem -LiteralPath $directory.FullName -Filter 'job-request-*.json' -File)
                if ($requests.Count -ne 1 -or $requests[0].Length -gt 1048576 -or ($requests[0].Attributes -band [IO.FileAttributes]::ReparsePoint)) { throw 'A single bounded owned request is required for restart cleanup.' }
                $request = ConvertTo-AutopilotDocumentDictionary -Value (Get-Content -LiteralPath $requests[0].FullName -Raw -Encoding UTF8 | ConvertFrom-Json -ErrorAction Stop)
                if ($request['SchemaVersion'] -ne 1 -or $request['Job']['JobId'] -cne $metadata['JobId'] -or $request['JobDirectory'] -ine $directory.FullName) { throw 'Restart cleanup request does not match its directory.' }
                $compacted = Complete-AutopilotDocumentJob -Directory $directory.FullName -Job $request['Job'] -Summary $metadata['Result'] -RetainReviewCopies:([bool]$request['ReviewOnly']) -WhatIf:$WhatIfPreference
                $result.Removed += $compacted.Removed
                $result.Actions.Add([ordered]@{ Job = $directory.Name; Status = 'Compacted'; ReceiptPath = $compacted.ReceiptPath })
                continue
            }
            if ($FailedJobRetentionDays -eq 0) { continue }
            if ($metadata['ChecklistOpenRequested'] -isnot [bool] -or $metadata['ChecklistOpenRequested']) { throw 'Open-checklist diagnostics remain protected.' }
            if ($metadata['State'] -cnotin @('Succeeded','Failed')) { throw 'Job is not terminal.' }
            $updated = [DateTimeOffset]::Parse([string]$metadata['UpdatedAtUtc'], [Globalization.CultureInfo]::InvariantCulture)
            if ($updated -gt $NowUtc -or ($metadata['State'] -eq 'Failed' -and $updated.AddDays($FailedJobRetentionDays) -gt $NowUtc)) { throw 'Job is not expired.' }
            $lockPath = Join-Path $directory.FullName 'job.lock'
            if ((Test-Path -LiteralPath $lockPath) -and ((Get-Item -LiteralPath $lockPath -Force).Attributes -band [IO.FileAttributes]::ReparsePoint)) { throw 'Unsafe job lease.' }
            if (-not $PSCmdlet.ShouldProcess($directory.FullName, 'Acquire exclusive lease for reversible asset expiry')) { continue }
            $lease = [IO.File]::Open($lockPath, [IO.FileMode]::OpenOrCreate, [IO.FileAccess]::ReadWrite, [IO.FileShare]::None)
            foreach ($leaf in @($metadata['DisposableAssets'] | Where-Object { $_ })) {
                if ($leaf -isnot [string] -or [IO.Path]::GetFileName($leaf) -cne $leaf -or $leaf -match '[:*?]' -or $leaf -cnotmatch '^(barcode-[a-f0-9-]+\.png|population-[a-f0-9-]+\.json|export-[a-f0-9-]+\.json)$') { throw 'Asset is not an explicitly disposable leaf.' }
                $path = Join-Path $directory.FullName $leaf
                if (-not (Test-Path -LiteralPath $path)) { continue }
                $file = Get-Item -LiteralPath $path -Force -ErrorAction Stop
                if ($file.PSIsContainer -or ($file.Attributes -band [IO.FileAttributes]::ReparsePoint)) { throw 'Asset is not a safe regular file.' }
                $archive = Join-Path $directory.FullName 'ExpiredAssets'
                $null = Resolve-AutopilotDocumentLocalPath -Path $archive
                if ($PSCmdlet.ShouldProcess($path, 'Move disposable asset to retained ExpiredAssets; no deletion')) {
                    $null = [IO.Directory]::CreateDirectory($archive)
                    $destination = Join-Path $archive $leaf
                    [IO.File]::Move($path, $destination)
                    $result.Moved++
                    $result.Actions.Add([ordered]@{ Source = $path; Destination = $destination; Status = 'Archived' })
                }
            }
        }
        catch { $result.Skipped++; $result.Actions.Add([ordered]@{ Job = $directory.Name; Status = 'Skipped'; Reason = $_.Exception.Message }) }
        finally { if ($null -ne $lease) { $lease.Dispose() } }
    }
    return $result
}