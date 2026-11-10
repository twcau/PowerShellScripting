<#
.SYNOPSIS
    Check an installed document bundle without loading its assemblies.
.DESCRIPTION
    Requires PowerShell 5.1 or later and the module's private path/package validators.
    Missing/invalid bundles produce a structured non-critical result, not repair.
.FILECREATED
    2026-10-24
.FILELASTUPDATED
    2026-10-24
#>
function Test-AutopilotDocumentDependencyBundle {
    <#
    .SYNOPSIS
        Reverify the pinned DLLs, retained archives and publication marker.
    .PARAMETER DependencyRoot
        Explicit feature-owned cache root; no current-directory or shared fallback.
    .OUTPUTS
        Valid, Status, BundlePath and Diagnostic; never loads code or modifies files.
    #>
    [CmdletBinding()]
    [OutputType([System.Collections.Specialized.OrderedDictionary])]
    param([Parameter(Mandatory)][ValidateNotNullOrEmpty()][string]$DependencyRoot)
    $result = [ordered]@{ Valid = $false; Status = 'Invalid'; BundlePath = ''; Diagnostic = '' }
    try {
        $root = Resolve-AutopilotDocumentLocalPath -Path $DependencyRoot
        $manifest = Get-AutopilotDocumentDependencyManifest
        $bundle = Resolve-AutopilotDocumentLocalPath -Path (Join-Path $root $manifest.BundleId)
        $result.BundlePath = $bundle
        if (-not (Test-Path -LiteralPath $bundle)) { $result.Status = 'Missing'; return $result }
        $markerPath = Join-Path $bundle 'bundle.json'
        $markerFile = Get-Item -LiteralPath $markerPath -Force -ErrorAction Stop
        if ($markerFile.Length -gt 65536 -or ($markerFile.Attributes -band [IO.FileAttributes]::ReparsePoint)) { throw 'Invalid dependency publication marker.' }
        $marker = Get-Content -LiteralPath $markerPath -Raw -ErrorAction Stop | ConvertFrom-Json -ErrorAction Stop
        if ($marker.SchemaVersion -ne 1 -or $marker.BundleId -cne $manifest.BundleId) { throw 'Dependency bundle publication is incomplete or mismatched.' }
        foreach ($package in $manifest.Packages) {
            $archive = Join-Path $bundle ('{0}.{1}.nupkg' -f $package.Id.ToLowerInvariant(), $package.Version)
            $null = Test-AutopilotDocumentPackage -ArchivePath $archive -PackageId $package.Id
            $asset = Get-Item -LiteralPath (Join-Path $bundle $package.FileName) -Force -ErrorAction Stop
            if ($asset.PSIsContainer -or ($asset.Attributes -band [IO.FileAttributes]::ReparsePoint) -or (Get-FileHash -LiteralPath $asset.FullName -Algorithm SHA256 -ErrorAction Stop).Hash -cne $package.AssetSHA256) { throw 'Installed dependency DLL failed integrity verification.' }
        }
        $result.Valid = $true; $result.Status = 'Verified'
    }
    catch { $result.Diagnostic = 'Document dependency verification failed: {0}' -f $_.Exception.Message }
    return $result
}