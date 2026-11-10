<#
.SYNOPSIS
    Verify a pinned archive, selected DLL and licence/dependency metadata.
.DESCRIPTION
    PowerShell 5.1 or later with platform ZIP/XML APIs. Does not extract or load
    third-party code. Reads only exact allowlisted entries, not archive paths.
.FILECREATED
    2026-10-24
.FILELASTUPDATED
    2026-10-24
#>
function Test-AutopilotDocumentPackage {
    <#
    .SYNOPSIS
        Fail closed on altered archives, assets, licences or framework closure.
    .PARAMETER ArchivePath
        File in the feature-owned stage/cache; size is bounded before opening ZIP.
    .PARAMETER PackageId
        Reviewed package identity; callers cannot supply alternative hashes or URLs.
    .OUTPUTS
        True after all checks; otherwise throws without executing package content.
    #>
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        [Parameter(Mandatory)][ValidateNotNullOrEmpty()][string]$ArchivePath,
        [Parameter(Mandatory)][ValidateSet('DocumentFormat.OpenXml', 'DocumentFormat.OpenXml.Framework', 'ZXing.Net')][string]$PackageId
    )
    $manifest = Get-AutopilotDocumentDependencyManifest
    $package = $manifest.Packages | Where-Object { $_.Id -ceq $PackageId } | Select-Object -First 1
    $file = Get-Item -LiteralPath $ArchivePath -Force -ErrorAction Stop
    if ($file.PSIsContainer -or $file.Length -gt 33554432 -or ($file.Attributes -band [IO.FileAttributes]::ReparsePoint)) { throw 'Invalid dependency archive file or size.' }
    $inputStream = [IO.File]::Open($file.FullName, [IO.FileMode]::Open, [IO.FileAccess]::Read, [IO.FileShare]::Read)
    $sha = [Security.Cryptography.SHA512]::Create(); $zip = $null
    try {
        if ([Convert]::ToBase64String($sha.ComputeHash($inputStream)) -cne $package.ArchiveSHA512) { throw 'Dependency archive SHA-512 mismatch.' }
        $inputStream.Position = 0
        Add-Type -AssemblyName System.IO.Compression -ErrorAction Stop
        $zip = [IO.Compression.ZipArchive]::new($inputStream, [IO.Compression.ZipArchiveMode]::Read, $true)
        $assetEntries = @($zip.Entries | Where-Object { $_.FullName -ceq $package.Asset })
        $specEntries = @($zip.Entries | Where-Object { $_.FullName -ceq ('{0}.nuspec' -f $package.Id) })
        if ($assetEntries.Count -ne 1 -or $assetEntries[0].Length -gt 16777216 -or $specEntries.Count -ne 1 -or $specEntries[0].Length -gt 1048576) { throw 'Missing, duplicate or excessive dependency package entries.' }
        $assetStream = $assetEntries[0].Open(); $assetHash = [Security.Cryptography.SHA256]::Create()
        try { $actual = [BitConverter]::ToString($assetHash.ComputeHash($assetStream)).Replace('-', '') } finally { $assetStream.Dispose(); $assetHash.Dispose() }
        if ($actual -cne $package.AssetSHA256) { throw 'Dependency DLL SHA-256 mismatch.' }
        $settings = [Xml.XmlReaderSettings]::new(); $settings.DtdProcessing = [Xml.DtdProcessing]::Prohibit; $settings.XmlResolver = $null; $settings.MaxCharactersInDocument = 1048576
        $specStream = $specEntries[0].Open(); $reader = [Xml.XmlReader]::Create($specStream, $settings)
        try { $spec = [Xml.XmlDocument]::new(); $spec.XmlResolver = $null; $spec.Load($reader) } finally { $reader.Dispose(); $specStream.Dispose() }
        $metadata = $spec.SelectSingleNode('//*[local-name()="metadata"]')
        if ($metadata.SelectSingleNode('*[local-name()="id"]').InnerText -cne $package.Id -or $metadata.SelectSingleNode('*[local-name()="version"]').InnerText -cne $package.Version -or $metadata.SelectSingleNode('*[local-name()="license"]').InnerText -cne $package.Licence) { throw 'Dependency identity, version or licence differs from the lock.' }
        $groups = @($metadata.SelectNodes('*[local-name()="dependencies"]/*[local-name()="group"]') | Where-Object { $_.GetAttribute('targetFramework') -ceq $package.Target })
        if ($groups.Count -ne 1) { throw 'The reviewed dependency target group is missing or ambiguous.' }
        $dependencies = @($groups[0].SelectNodes('*[local-name()="dependency"]'))
        if ($dependencies.Count -ne $package.Dependencies.Count) { throw 'Dependency closure differs from the reviewed lock.' }
        foreach ($dependency in $dependencies) {
            $locked = $manifest.Packages | Where-Object { $_.Id -ceq $dependency.GetAttribute('id') } | Select-Object -First 1
            if ($null -eq $locked -or $locked.Id -cnotin $package.Dependencies -or $dependency.GetAttribute('version') -cne $locked.Version) { throw 'Unexpected transitive package or version constraint.' }
        }
        return $true
    }
    finally { if ($null -ne $zip) { $zip.Dispose() }; $sha.Dispose(); $inputStream.Dispose() }
}