<#
.SYNOPSIS
    Retain a compact successful-job receipt and remove proven owned staging files.
.DESCRIPTION
    Permanent successful-job temporary cleanup was explicitly approved on
    25 October 2026. Unknown files, failed/uncertain delivery, unsafe paths and
    active leases prevent cleanup. Final PDFs remain outside the working folder.
.FILECREATED
    2026-10-25
.FILELASTUPDATED
    2026-10-25
#>
function Complete-AutopilotDocumentJob {
    <#
    .SYNOPSIS
        Verify publication before removing a terminal job's exact temporary files.
    .PARAMETER Directory
        Owned working directory whose lifecycle has been durably finalised.
    .PARAMETER Job
        Detached job, including final local OutputRoot and profile identities.
    .PARAMETER Summary
        Successful supervisor result with independently verified Word cleanup.
    .PARAMETER RetainReviewCopies
        Preserve named populated DOCX files beside final PDFs for explicit review.
    .PARAMETER RemoveReviewImages
        Explicit legacy-review migration only: discard named page renders and
        duplicate staged final PDFs after retaining verified final outputs.
    .OUTPUTS
        Compact receipt path and removed-file count. Failures retain diagnostics.
    #>
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'None')]
    [OutputType([Collections.Specialized.OrderedDictionary])]
    param(
        [Parameter(Mandatory)][string]$Directory,
        [Parameter(Mandatory)][Collections.IDictionary]$Job,
        [Parameter(Mandatory)][Collections.IDictionary]$Summary,
        [switch]$RetainReviewCopies,
        [switch]$RemoveReviewImages
    )
    $directory = Resolve-AutopilotDocumentLocalPath -Path $Directory
    if (-not (Test-AutopilotDocumentJobDirectory -Directory $directory -JobId $Job['JobId'])) { throw 'Successful cleanup directory identity mismatch.' }
    if ($Summary['Status'] -cne 'Completed' -or $Summary['Cleanup'] -cne 'Complete' -or @($Summary['Results']).Count -ne @($Job['Profiles']).Count) { throw 'Only fully successful, independently closed jobs qualify for temporary cleanup.' }
    $outputRoot = Resolve-AutopilotDocumentLocalPath -Path $Job['OutputRoot']
    if ($outputRoot -ieq $directory -or $outputRoot.StartsWith(($directory + [IO.Path]::DirectorySeparatorChar), [StringComparison]::OrdinalIgnoreCase)) { throw 'Final output cannot be inside the temporary job directory.' }
    $lease = $null
    try {
        $lockPath = Join-Path $directory 'job.lock'
        if ((Get-Item -LiteralPath $lockPath -Force).Attributes -band [IO.FileAttributes]::ReparsePoint) { throw 'Unsafe job lease.' }
        if (-not $PSCmdlet.ShouldProcess($directory, 'Compact successful receipt and permanently remove owned temporary files')) { return [ordered]@{ Removed = 0; ReceiptPath = '' } }
        $lease = [IO.File]::Open($lockPath, [IO.FileMode]::Open, [IO.FileAccess]::ReadWrite, [IO.FileShare]::None)
        $lifecyclePath = Join-Path $directory 'job-lifecycle.json'
        $lifecycleFile = Get-Item -LiteralPath $lifecyclePath -Force
        if ($lifecycleFile.PSIsContainer -or $lifecycleFile.Length -gt 65536 -or ($lifecycleFile.Attributes -band [IO.FileAttributes]::ReparsePoint)) { throw 'Lifecycle exceeds its ownership bound or is unsafe.' }
        $metadata = Get-Content -LiteralPath $lifecyclePath -Raw -Encoding UTF8 | ConvertFrom-Json -ErrorAction Stop
        if ($metadata.Owner -cne 'AutopilotExpress.Documents' -or $metadata.JobId -cne $Job['JobId'] -or $metadata.Active -ne $false -or $metadata.State -cne 'Succeeded') { throw 'Job is not a terminal owned success.' }
        foreach ($output in $Summary['Results']) {
            if ($output['Status'] -cnotin @('Generated','OpenRequested','PrintRequested') -or $output['DeliveryState'] -eq 'Uncertain') { throw 'Delivery still requires attention; preserve its full evidence.' }
            if ((Resolve-AutopilotDocumentLocalPath -Path (Split-Path -Parent $output['PdfPath'])) -ine $outputRoot) { throw 'Published PDF is outside this job output root.' }
            if ((Get-AutopilotDocumentPdfInfo -Path $output['PdfPath']).SHA256 -cne $output['OutputSHA256']) { throw 'Published PDF differs from its receipt; nothing will be removed.' }
        }
        $names = [Collections.Generic.List[string]]::new()
        foreach ($documentProfile in $Job['Profiles']) { $names.Add((Get-AutopilotDocumentOutputName -Job $Job -DocumentType $documentProfile['DocumentType'] -Extension docx -OccupiedFileNames $names.ToArray())) }
        $files = @(Get-ChildItem -LiteralPath $directory -Force)
        foreach ($file in $files) {
            if ($file.PSIsContainer -or ($file.Attributes -band [IO.FileAttributes]::ReparsePoint)) { throw 'Unknown directory or reparse entry prevents successful-job deletion.' }
            $known = $file.Name -cin $names -or $file.Name -cmatch '^(WordOwner\.json|job\.lock|job-lifecycle\.json(?:\.previous-[a-f0-9]{32})?|job-request-[a-f0-9]{32}\.json|(?:BirthCertificate|Checklist)\.(?:template\.docx|exported\.pdf|word-owner\.json))$'
            $receiptPattern = '^{0}-(BirthCertificate|Checklist)\.receipt\.json(?:\.lock|\.previous-[a-f0-9]{{32}})?$' -f [regex]::Escape($Job['JobId'])
            if ($RemoveReviewImages) {
                foreach ($output in $Summary['Results']) {
                    $pdfName = [IO.Path]::GetFileName($output['PdfPath'])
                    if ($file.Name -ceq $pdfName) {
                        if ((Get-AutopilotDocumentPdfInfo -Path $file.FullName).SHA256 -cne $output['OutputSHA256']) { throw 'Staged review PDF differs from the retained output.' }
                        $known = $true
                    }
                    if ($file.Name -cmatch ('^{0}-[1-9][0-9]{{0,3}}\.png$' -f [regex]::Escape([IO.Path]::GetFileNameWithoutExtension($pdfName)))) { $known = $true }
                }
            }
            if (-not $known -and $file.Name -cnotmatch $receiptPattern) { throw ('Unknown file retained; cleanup refused: {0}' -f $file.Name) }
        }
        if ($RetainReviewCopies) {
            for ($index = 0; $index -lt $names.Count; $index++) {
                $source = Join-Path $directory $names[$index]
                if (-not (Test-Path -LiteralPath $source)) { continue }
                $documentType = $Job['Profiles'][$index]['DocumentType']
                $published = @($Summary['Results'] | Where-Object { $_['DocumentType'] -ceq $documentType })
                if ($published.Count -ne 1) { throw 'Review copy requires one uniquely matched published PDF.' }
                $destination = Join-Path $outputRoot ([IO.Path]::ChangeExtension([IO.Path]::GetFileName($published[0]['PdfPath']), '.docx'))
                if (Test-Path -LiteralPath $destination) {
                    if ((Get-Item -LiteralPath $destination -Force).Attributes -band [IO.FileAttributes]::ReparsePoint) { throw 'Unsafe review DOCX destination.' }
                    if ((Get-FileHash -LiteralPath $source).Hash -cne (Get-FileHash -LiteralPath $destination).Hash) { throw 'Review DOCX destination already contains different content.' }
                }
                else { [IO.File]::Copy($source, $destination, $false) }
            }
        }
        $receipt = [ordered]@{ SchemaVersion = 1; Owner = 'AutopilotExpress.Documents'; JobId = $Job['JobId']; RecordId = $Job['RecordId']; BuildCycleId = $Job['BuildCycleId']; Mode = $Job['Mode']; TenantId = $Job['TenantId']; Serial = $Job['Fields']['SerialNumberOrServiceTag']; ConfigurationItem = $Job['Fields']['ConfigurationItem']; DispatchedAt = $Job['DispatchedAt']; Results = @($Summary['Results']); AutomaticReplayAllowed = $false; Cleanup = 'Verified'; UpdatedAtUtc = [DateTimeOffset]::UtcNow.ToString('o') }
        $receiptPath = Join-Path $outputRoot ('Job-{0}.receipt.json' -f $Job['JobId'])
        if (Test-Path -LiteralPath $receiptPath) {
            $priorFile = Get-Item -LiteralPath $receiptPath -Force
            if ($priorFile.PSIsContainer -or $priorFile.Length -gt 65536 -or ($priorFile.Attributes -band [IO.FileAttributes]::ReparsePoint)) { throw 'Unsafe compact receipt.' }
            $prior = Get-Content -LiteralPath $receiptPath -Raw -Encoding UTF8 | ConvertFrom-Json -ErrorAction Stop
            foreach ($key in @('Owner','JobId','RecordId','BuildCycleId','Mode','TenantId')) { if ([string]$prior.$key -cne [string]$receipt[$key]) { throw 'Compact receipt identity mismatch.' } }
        }
        $bytes = [Text.UTF8Encoding]::new($false).GetBytes(($receipt | ConvertTo-Json -Depth 14 -Compress))
        if ($bytes.Length -gt 65536) { throw 'Compact receipt exceeds its bound.' }
        $pending = '{0}.pending-{1}' -f $receiptPath, [guid]::NewGuid().ToString('N')
        $stream = [IO.File]::Open($pending, [IO.FileMode]::CreateNew, [IO.FileAccess]::Write, [IO.FileShare]::None)
        try { $stream.Write($bytes, 0, $bytes.Length); $stream.Flush($true) } finally { $stream.Dispose() }
        if (Test-Path -LiteralPath $receiptPath) { [IO.File]::Replace($pending, $receiptPath, [NullString]::Value) }
        else { [IO.File]::Move($pending, $receiptPath) }
        foreach ($file in $files | Where-Object { $_.Name -cnotin @('job.lock','job-lifecycle.json') -and $_.Name -cnotmatch '^job-request-[a-f0-9]{32}\.json$' }) { [IO.File]::Delete($file.FullName) }
        foreach ($file in $files | Where-Object Name -CMatch '^job-request-[a-f0-9]{32}\.json$') { [IO.File]::Delete($file.FullName) }
        [IO.File]::Delete($lifecyclePath)
        $lease.Dispose(); $lease = $null
        [IO.File]::Delete($lockPath)
        [IO.Directory]::Delete($directory, $false)
        if ([IO.Path]::GetFileName($Job['JobRoot']) -ceq 'Working' -and -not @(Get-ChildItem -LiteralPath $Job['JobRoot'] -Force).Count) { [IO.Directory]::Delete($Job['JobRoot'], $false) }
        return [ordered]@{ Removed = $files.Count; ReceiptPath = $receiptPath }
    }
    finally { if ($null -ne $lease) { $lease.Dispose() } }
}