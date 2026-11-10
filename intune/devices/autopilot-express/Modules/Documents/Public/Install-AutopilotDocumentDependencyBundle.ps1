<#
.SYNOPSIS
    Acquire only the consented, pinned document bundle into a local owned cache.
.DESCRIPTION
    PowerShell 5.1 or later. Uses HTTPS NuGet, bounded immediate retries, ZIP/XML
    verification and exclusive staging/publication; never loads package scripts.
    Failed stages are retained, not recursively deleted or silently repaired.
.FILECREATED
    2026-10-24
.FILELASTUPDATED
    2026-10-24
#>
function Install-AutopilotDocumentDependencyBundle {
    <#
    .SYNOPSIS
        Require disclosed consent before acquisition; preserve core workflow on failure.
    .PARAMETER DependencyRoot
        Explicit local document cache root, separated from operational data/.
    .PARAMETER Consent
        Approved is explicit prior consent, not inferred from NoPrompts. Default asks.
    .PARAMETER NoPrompts
        Missing consent returns ConsentRequired; never silently assumes Yes.
    .PARAMETER ArchiveDirectory
        Optional local, already acquired archives; every file is still hash-verified.
    .OUTPUTS
        Status/Ready/BundlePath/Diagnostic; publication alone is not runtime readiness.
    #>
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'None')]
    [OutputType([System.Collections.Specialized.OrderedDictionary])]
    param(
        [Parameter(Mandatory)][ValidateNotNullOrEmpty()][string]$DependencyRoot,
        [ValidateSet('NotGranted', 'Approved', 'Declined')][string]$Consent = 'NotGranted',
        [switch]$NoPrompts,
        [string]$ArchiveDirectory
    )
    $result = [ordered]@{ Status = 'Failed'; Ready = $false; BundlePath = ''; Diagnostic = '' }
    $lock = $null
    try {
        $root = Resolve-AutopilotDocumentLocalPath -Path $DependencyRoot
        $existing = Test-AutopilotDocumentDependencyBundle -DependencyRoot $root
        $result.BundlePath = $existing.BundlePath
        if ($existing.Valid) { $result.Status = 'Verified'; return $result }
        if ($existing.Status -ne 'Missing') { $result.Status = 'InvalidExistingBundle'; $result.Diagnostic = $existing.Diagnostic; return $result }
        if ($Consent -eq 'Declined') { $result.Status = 'Declined'; return $result }
        if (-not $PSCmdlet.ShouldProcess($root, 'Acquire and publish pinned document libraries only')) { $result.Status = 'WhatIf'; return $result }
        $manifest = Get-AutopilotDocumentDependencyManifest
        if ($Consent -ne 'Approved') {
            if ($NoPrompts) { $result.Status = 'ConsentRequired'; return $result }
            Write-Information ('Document packages from {0} to {1}. No Office/Graph installation. Archive SHA-512 and DLL SHA-256 checks are required.' -f $manifest.Source, $root) -InformationAction Continue
            foreach ($package in $manifest.Packages) { Write-Information ('{0} {1}, licence {2}' -f $package.Id, $package.Version, $package.Licence) -InformationAction Continue }
            do {
                $answer = (Read-Host 'Acquire these document libraries? [Y] Yes [N] No [0] Cancel (Default: Yes)').Trim()
                if ($answer -notin @('', 'Y', 'YES', 'N', 'NO', '0')) { Write-Information 'Enter Y or N, 0 to cancel, or press Enter for Yes.' -InformationAction Continue }
            } while ($answer -notin @('', 'Y', 'YES', 'N', 'NO', '0'))
            if ($answer -in @('N', 'NO', '0')) { $result.Status = 'Declined'; return $result }
        }
        if ($ArchiveDirectory) { $ArchiveDirectory = Resolve-AutopilotDocumentLocalPath -Path $ArchiveDirectory }
        $null = New-Item -ItemType Directory -Path $root -Force -ErrorAction Stop
        $null = Resolve-AutopilotDocumentLocalPath -Path $root
        $lockPath = Join-Path $root 'acquire.lock'
        if ((Test-Path -LiteralPath $lockPath) -and ((Get-Item -LiteralPath $lockPath -Force).Attributes -band [IO.FileAttributes]::ReparsePoint)) { throw 'Dependency lock must not be redirected.' }
        $lock = [IO.File]::Open($lockPath, [IO.FileMode]::OpenOrCreate, [IO.FileAccess]::ReadWrite, [IO.FileShare]::None)
        $existing = Test-AutopilotDocumentDependencyBundle -DependencyRoot $root
        if ($existing.Valid) { $result.Status = 'Verified'; return $result }
        if ($existing.Status -ne 'Missing') { throw 'Existing dependency bundle is invalid; no automatic replacement is permitted.' }
        $stage = Join-Path $root ('.staging-{0}' -f [guid]::NewGuid().ToString('N'))
        $null = New-Item -ItemType Directory -Path $stage -ErrorAction Stop
        Add-Type -AssemblyName System.IO.Compression.FileSystem -ErrorAction Stop
        foreach ($package in $manifest.Packages) {
            $name = '{0}.{1}.nupkg' -f $package.Id.ToLowerInvariant(), $package.Version
            $archive = Join-Path $stage $name
            if ($ArchiveDirectory) {
                $source = Get-Item -LiteralPath (Join-Path $ArchiveDirectory $name) -Force -ErrorAction Stop
                if ($source.PSIsContainer -or $source.Length -gt 33554432 -or ($source.Attributes -band [IO.FileAttributes]::ReparsePoint)) { throw 'Offline package source must be a bounded regular file.' }
                Copy-Item -LiteralPath $source.FullName -Destination $archive -ErrorAction Stop
            }
            else {
                $uri = '{0}/{1}/{2}/{1}.{2}.nupkg' -f $manifest.Source, $package.Id.ToLowerInvariant(), $package.Version
                for ($attempt = 1; $attempt -le 2; $attempt++) {
                    try { Invoke-WebRequest -Uri $uri -OutFile $archive -TimeoutSec 60 -UseBasicParsing -MaximumRedirection 0 -ErrorAction Stop; break }
                    catch { if ($attempt -eq 2) { throw }; Write-Information ('Retrying document package {0} after a failed request.' -f $package.Id) -InformationAction Continue }
                }
            }
            $null = Test-AutopilotDocumentPackage -ArchivePath $archive -PackageId $package.Id
            $zip = [IO.Compression.ZipFile]::OpenRead($archive)
            try {
                foreach ($entryName in @($package.Asset, ('{0}.nuspec' -f $package.Id))) {
                    $entry = $zip.GetEntry($entryName)
                    $leaf = if ($entryName -ceq $package.Asset) { $package.FileName } else { '{0}.nuspec' -f $package.Id }
                    $inputStream = $entry.Open(); $outputStream = $null
                    try { $outputStream = [IO.File]::Open((Join-Path $stage $leaf), [IO.FileMode]::CreateNew, [IO.FileAccess]::Write, [IO.FileShare]::None); $inputStream.CopyTo($outputStream) }
                    finally { if ($null -ne $outputStream) { $outputStream.Dispose() }; $inputStream.Dispose() }
                }
            }
            finally { $zip.Dispose() }
            if ((Get-FileHash -LiteralPath (Join-Path $stage $package.FileName) -Algorithm SHA256 -ErrorAction Stop).Hash -cne $package.AssetSHA256) { throw 'Staged dependency DLL failed verification before publication.' }
        }
        $marker = [ordered]@{ SchemaVersion = 1; BundleId = $manifest.BundleId; Source = $manifest.Source; AcquiredAtUtc = [DateTimeOffset]::UtcNow.ToString('o'); AdvisoryCheckedOn = $manifest.AdvisoryCheckedOn }
        [IO.File]::WriteAllText((Join-Path $stage 'bundle.json'), ($marker | ConvertTo-Json), [Text.UTF8Encoding]::new($false))
        [IO.Directory]::Move($stage, $result.BundlePath)
        $verified = Test-AutopilotDocumentDependencyBundle -DependencyRoot $root
        if (-not $verified.Valid) { throw 'Published bundle failed final verification; document output remains unavailable.' }
        $result.Status = 'InstalledVerified'
    }
    catch { $result.Diagnostic = 'Document library acquisition failed; core workflow is unaffected. {0}' -f $_.Exception.Message }
    finally { if ($null -ne $lock) { $lock.Dispose() } }
    return $result
}