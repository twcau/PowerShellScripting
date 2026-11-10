<#
.SYNOPSIS
    Reorganise only legacy local review artifacts with a durable migration log.
.DESCRIPTION
    Explicit maintenance operation approved on 25 October 2026. Does not inspect
    operational data, run Word, change templates, print or replay delivery.
.FILECREATED
    2026-10-25
.FILELASTUPDATED
    2026-10-25
#>
function Move-AutopilotDocumentReviewArtifacts {
    <#
    .SYNOPSIS
        Compact proven review successes and preserve other attempts intact.
    .PARAMETER DocumentRoot
        Feature-owned local Documents directory, not the application data root.
    .OUTPUTS
        Individual completed, retained or skipped migration actions and log path.
    #>
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'None')]
    [OutputType([Collections.Specialized.OrderedDictionary])]
    param([Parameter(Mandatory)][string]$DocumentRoot)
    $root = Resolve-AutopilotDocumentLocalPath -Path $DocumentRoot
    if ([IO.Path]::GetFileName($root) -cne 'Documents') { throw 'Migration is restricted to the feature Documents root.' }
    $logPath = Join-Path $root 'MigrationLog.json'
    $actions = [Collections.Generic.List[object]]::new()
    if (Test-Path -LiteralPath $logPath) {
        $logFile = Get-Item -LiteralPath $logPath -Force
        if ($logFile.Length -gt 1048576 -or ($logFile.Attributes -band [IO.FileAttributes]::ReparsePoint)) { throw 'Unsafe migration log.' }
        $prior = ConvertTo-AutopilotDocumentDictionary -Value (Get-Content -LiteralPath $logPath -Raw -Encoding UTF8 | ConvertFrom-Json -ErrorAction Stop)
        if ($prior['Owner'] -cne 'AutopilotExpress.Documents') { throw 'Foreign migration log.' }
        foreach ($action in @($prior['Actions'])) { $actions.Add($action) }
    }
    $saveLog = {
        $content = [ordered]@{ SchemaVersion = 1; Owner = 'AutopilotExpress.Documents'; UpdatedAtUtc = [DateTimeOffset]::UtcNow.ToString('o'); Actions = $actions.ToArray() }
        $bytes = [Text.UTF8Encoding]::new($false).GetBytes(($content | ConvertTo-Json -Depth 16 -Compress))
        if ($bytes.Length -gt 1048576) { throw 'Migration log exceeds its bound.' }
        $pending = '{0}.pending-{1}' -f $logPath, [guid]::NewGuid().ToString('N')
        $stream = [IO.File]::Open($pending, [IO.FileMode]::CreateNew, [IO.FileAccess]::Write, [IO.FileShare]::None)
        try { $stream.Write($bytes, 0, $bytes.Length); $stream.Flush($true) } finally { $stream.Dispose() }
        if (Test-Path -LiteralPath $logPath) { [IO.File]::Replace($pending, $logPath, [NullString]::Value) } else { [IO.File]::Move($pending, $logPath) }
    }
    foreach ($reviewRoot in Get-ChildItem -LiteralPath $root -Directory -Force | Where-Object Name -CMatch '^review-(?:corrected-)?[a-f0-9]{32}$') {
        $null = Resolve-AutopilotDocumentLocalPath -Path $reviewRoot.FullName
        $jobsRoot = Join-Path $reviewRoot.FullName 'Demo/jobs'
        $null = Resolve-AutopilotDocumentLocalPath -Path $jobsRoot
        $directories = if (Test-Path -LiteralPath $jobsRoot) { @(Get-ChildItem -LiteralPath $jobsRoot -Directory -Force) } else { @() }
        foreach ($directory in $directories) {
            $action = [ordered]@{ Source = $directory.FullName; Destination = ''; Status = 'Planned'; Reason = ''; Removed = 0; OriginalPdfs = @(); UpdatedAtUtc = [DateTimeOffset]::UtcNow.ToString('o') }
            $actions.Add($action)
            $success = $false; $job = $null; $oldPdfs = @()
            try {
                $null = Resolve-AutopilotDocumentLocalPath -Path $directory.FullName
                $requests = @(Get-ChildItem -LiteralPath $directory.FullName -File -Filter 'job-request-*.json')
                if ($requests.Count -ne 1 -or $requests[0].Length -gt 1048576 -or ($requests[0].Attributes -band [IO.FileAttributes]::ReparsePoint)) { throw 'No unique bounded detached job request; preserve in place.' }
                $request = ConvertTo-AutopilotDocumentDictionary -Value (Get-Content -LiteralPath $requests[0].FullName -Raw -Encoding UTF8 | ConvertFrom-Json -ErrorAction Stop)
                $job = $request['Job']
                if ($request['SchemaVersion'] -ne 1 -or $job['Mode'] -cne 'Demo' -or -not (Test-AutopilotDocumentJobDirectory -Directory $directory.FullName -JobId $job['JobId'])) { throw 'Review request ownership or Demo scope mismatch.' }
                $labels = @()
                foreach ($value in @($job['Fields']['SerialNumberOrServiceTag'], $job['Fields']['ConfigurationItem'])) {
                    $label = [regex]::Replace([string]$value, '[^A-Za-z0-9._-]', '_').Trim('.')
                    if (-not $label) { $label = 'Unknown' }
                    $labels += $label.Substring(0, [Math]::Min(24, $label.Length))
                }
                $device = 'Serial-{0}_CI-{1}' -f $labels[0], $labels[1]
                $metadataPath = Join-Path $directory.FullName 'job-lifecycle.json'; $metadata = $null
                if (Test-Path -LiteralPath $metadataPath) {
                    $metadataFile = Get-Item -LiteralPath $metadataPath -Force
                    if ($metadataFile.Length -gt 65536 -or ($metadataFile.Attributes -band [IO.FileAttributes]::ReparsePoint)) { throw 'Unsafe lifecycle; retain in place.' }
                    $metadata = ConvertTo-AutopilotDocumentDictionary -Value (Get-Content -LiteralPath $metadataPath -Raw -Encoding UTF8 | ConvertFrom-Json -ErrorAction Stop)
                    if ($metadata['Owner'] -cne 'AutopilotExpress.Documents' -or $metadata['JobId'] -cne $job['JobId'] -or $metadata['Active'] -ne $false) { throw 'Active, uncertain or foreign review; retain in place.' }
                }
                $success = $null -ne $metadata -and $metadata['State'] -ceq 'Succeeded' -and $metadata['Result']['Cleanup'] -ceq 'Complete'
                $destination = if ($success) { Join-Path (Join-Path (Join-Path $root 'Demo/Review') $device) $job['JobId'] } else { Join-Path (Join-Path $root 'Demo/FailedJobs') ('{0}_{1}' -f $device, $job['JobId']) }
                $action.Destination = Resolve-AutopilotDocumentLocalPath -Path $destination
                if (-not $PSCmdlet.ShouldProcess($directory.FullName, ('Migrate document-only review artifacts to {0}' -f $destination))) { $action.Status = 'WhatIf'; continue }
                & $saveLog
                if ($success) {
                    $summary = $metadata['Result']; $oldPdfs = @()
                    $null = [IO.Directory]::CreateDirectory($destination)
                    foreach ($output in $summary['Results']) {
                        $sourcePdf = [IO.Path]::GetFullPath($output['PdfPath'])
                        if (-not $sourcePdf.StartsWith(($reviewRoot.FullName + [IO.Path]::DirectorySeparatorChar), [StringComparison]::OrdinalIgnoreCase)) { throw 'Review PDF lies outside its owned legacy root.' }
                        $null = Resolve-AutopilotDocumentLocalPath -Path (Split-Path -Parent $sourcePdf)
                        if ((Get-AutopilotDocumentPdfInfo -Path $sourcePdf).SHA256 -cne $output['OutputSHA256']) { throw 'Review PDF digest changed; migration stopped.' }
                        $targetPdf = Join-Path $destination ([IO.Path]::GetFileName($sourcePdf))
                        if (Test-Path -LiteralPath $targetPdf) {
                            if ((Get-AutopilotDocumentPdfInfo -Path $targetPdf).SHA256 -cne $output['OutputSHA256']) { throw 'Migration destination contains different output.' }
                        }
                        else { [IO.File]::Copy($sourcePdf, $targetPdf, $false) }
                        $oldPdfs += ,@{ Path = $sourcePdf; SHA256 = $output['OutputSHA256']; Destination = $targetPdf }
                        $output['PdfPath'] = $targetPdf
                    }
                    $action.OriginalPdfs = $oldPdfs; & $saveLog
                    $job['OutputRoot'] = $destination
                    $compacted = Complete-AutopilotDocumentJob -Directory $directory.FullName -Job $job -Summary $summary -RetainReviewCopies -RemoveReviewImages
                    $action.Removed = $compacted.Removed
                    foreach ($original in $oldPdfs) {
                        if (Test-Path -LiteralPath $original.Path) {
                            if ((Get-AutopilotDocumentPdfInfo -Path $original.Path).SHA256 -cne $original.SHA256 -or (Get-AutopilotDocumentPdfInfo -Path $original.Destination).SHA256 -cne $original.SHA256) { throw 'Migrated PDF digest changed; retain the original.' }
                            [IO.File]::Delete($original.Path)
                        }
                    }
                    $action.Status = 'Compacted'
                }
                else {
                    $null = [IO.Directory]::CreateDirectory((Split-Path -Parent $destination))
                    if (Test-Path -LiteralPath $destination) { throw 'Retained failure destination already exists.' }
                    [IO.Directory]::Move($directory.FullName, $destination)
                    $action.Status = 'Retained'
                }
            }
            catch {
                $action.Status = 'Skipped'; $action.Reason = $_.Exception.Message
                if ($success -and (Test-Path -LiteralPath $directory.FullName)) {
                    try {
                        $retainedPath = Resolve-AutopilotDocumentLocalPath -Path (Join-Path (Join-Path $root 'Demo/FailedJobs') ('{0}_{1}' -f $device, $job['JobId']))
                        if (Test-Path -LiteralPath $retainedPath) { throw 'Diagnostic destination already exists; leave the original in place.' }
                        $action['ReviewOutput'] = $action.Destination; $action.Destination = $retainedPath
                        $action.Status = 'RetainingDiagnostics'; & $saveLog
                        $null = [IO.Directory]::CreateDirectory((Split-Path -Parent $retainedPath))
                        [IO.Directory]::Move($directory.FullName, $retainedPath)
                        foreach ($original in $oldPdfs) {
                            if (Test-Path -LiteralPath $original.Path) {
                                if ((Get-AutopilotDocumentPdfInfo -Path $original.Path).SHA256 -cne $original.SHA256 -or (Get-AutopilotDocumentPdfInfo -Path $original.Destination).SHA256 -cne $original.SHA256) { throw 'Retained PDF digest changed; keep original output.' }
                                [IO.File]::Delete($original.Path)
                            }
                        }
                        $action.Status = 'Retained'
                    }
                    catch { $action.Status = 'Skipped'; $action.Reason = '{0}; diagnostic retention: {1}' -f $action.Reason, $_.Exception.Message }
                }
            }
            finally { if (-not $WhatIfPreference) { & $saveLog } }
        }
        if (-not $WhatIfPreference) {
            $imageRoot = Join-Path $reviewRoot.FullName 'Demo/output'
            if (Test-Path -LiteralPath $imageRoot) {
                $null = Resolve-AutopilotDocumentLocalPath -Path $imageRoot
                $published = @($actions | Where-Object { $_['Source'].StartsWith(($reviewRoot.FullName + [IO.Path]::DirectorySeparatorChar), [StringComparison]::OrdinalIgnoreCase) -and $_['Status'] -in @('Compacted','Retained') } | ForEach-Object { $_['OriginalPdfs'] })
                foreach ($image in Get-ChildItem -LiteralPath $imageRoot -File -Filter '*.png') {
                    if ($image.Attributes -band [IO.FileAttributes]::ReparsePoint) { continue }
                    $matchingPdfs = @($published | Where-Object { $image.Name -cmatch ('^{0}-[1-9][0-9]{{0,3}}\.png$' -f [regex]::Escape([IO.Path]::GetFileNameWithoutExtension($_['Path']))) })
                    if (-not $matchingPdfs.Count) { continue }
                    foreach ($pdf in $matchingPdfs) { if ((Get-AutopilotDocumentPdfInfo -Path $pdf['Destination']).SHA256 -cne $pdf['SHA256']) { throw 'Retained PDF changed; keep its review images.' } }
                    $imageAction = [ordered]@{ Source = $image.FullName; Destination = ''; Status = 'RemovingOwnedReviewImage'; Removed = 0; Reason = ''; OriginalPdfs = @(); UpdatedAtUtc = [DateTimeOffset]::UtcNow.ToString('o') }
                    $actions.Add($imageAction); & $saveLog
                    [IO.File]::Delete($image.FullName)
                    $imageAction.Status = 'RemovedOwnedReviewImage'; $imageAction.Removed = 1
                    & $saveLog
                }
            }
            foreach ($candidate in @($jobsRoot, (Join-Path $reviewRoot.FullName 'Demo/output'), (Join-Path $reviewRoot.FullName 'Demo'), $reviewRoot.FullName)) {
                if ((Test-Path -LiteralPath $candidate) -and -not @(Get-ChildItem -LiteralPath $candidate -Force).Count) { [IO.Directory]::Delete($candidate, $false) }
            }
        }
    }
    foreach ($canonicalName in @('Dependencies','Preferences')) {
        $existing = @(Get-ChildItem -LiteralPath $root -Directory -Force | Where-Object { $_.Name -ieq $canonicalName -and $_.Name -cne $canonicalName })
        foreach ($entry in $existing) {
            $null = Resolve-AutopilotDocumentLocalPath -Path $entry.FullName
            $destination = Join-Path $root $canonicalName
            if (-not $PSCmdlet.ShouldProcess($entry.FullName, ('Normalise document-only folder casing to {0}' -f $canonicalName))) { continue }
            $temporary = Join-Path $root ('{0}-CaseRename-{1}' -f $canonicalName, [guid]::NewGuid().ToString('N'))
            $caseAction = [ordered]@{ Source = $entry.FullName; Destination = $destination; Temporary = $temporary; Status = 'PlannedCaseRename'; Removed = 0; Reason = ''; OriginalPdfs = @(); UpdatedAtUtc = [DateTimeOffset]::UtcNow.ToString('o') }
            $actions.Add($caseAction); & $saveLog
            try {
                [IO.Directory]::Move($entry.FullName, $temporary)
                [IO.Directory]::Move($temporary, $destination)
                $caseAction.Status = 'NormalisedCase'
            }
            catch {
                $caseAction.Status = 'Skipped'; $caseAction.Reason = $_.Exception.Message
                if ((Test-Path -LiteralPath $temporary) -and -not (Test-Path -LiteralPath $destination)) { [IO.Directory]::Move($temporary, $entry.FullName) }
            }
            & $saveLog
        }
    }
    return [ordered]@{ LogPath = $logPath; Actions = $actions.ToArray() }
}