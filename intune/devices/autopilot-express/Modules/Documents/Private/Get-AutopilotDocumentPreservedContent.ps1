<#
.SYNOPSIS
    Snapshot opaque objects and existing image bytes without activating content.
.DESCRIPTION
    Uses only ZIP, cryptography and DTD-disabled XML APIs. The caller supplies an
    already bounded package stream; no extraction, Office or external resolution.
.FILECREATED
    2026-10-24
.FILELASTUPDATED
    2026-10-24
#>
function Get-AutopilotDocumentPreservedContent {
    <#
    .SYNOPSIS
        Record binary hashes and semantic OLE attributes/relationships for preservation.
    .PARAMETER Stream
        Seekable DOCX memory stream; left open and reset after inspection.
    .OUTPUTS
        Ordered dictionaries/arrays, independent of ZIP compression and XML prefixes.
    #>
    [CmdletBinding()]
    [OutputType([Collections.Specialized.OrderedDictionary])]
    param([Parameter(Mandatory)][ValidateNotNull()][IO.Stream]$Stream)
    $assets = [ordered]@{}; $relations = [Collections.Generic.List[string]]::new(); $objects = [Collections.Generic.List[string]]::new()
    $Stream.Position = 0
    $zip = [IO.Compression.ZipArchive]::new($Stream, [IO.Compression.ZipArchiveMode]::Read, $true)
    try {
        foreach ($entry in $zip.Entries | Sort-Object FullName) {
            if ($entry.FullName -match '^word/(embeddings|media)/' -and -not $entry.FullName.EndsWith('/')) {
                $inputStream = $entry.Open(); $sha = [Security.Cryptography.SHA256]::Create()
                try { $assets[$entry.FullName] = [BitConverter]::ToString($sha.ComputeHash($inputStream)).Replace('-', '') }
                finally { $sha.Dispose(); $inputStream.Dispose() }
            }
            if ($entry.FullName -notmatch '\.(xml|rels)$') { continue }
            $inputStream = $entry.Open(); $reader = $null
            try {
                $settings = [Xml.XmlReaderSettings]::new(); $settings.DtdProcessing = [Xml.DtdProcessing]::Prohibit
                $settings.XmlResolver = $null; $settings.MaxCharactersInDocument = 33554432
                $reader = [Xml.XmlReader]::Create($inputStream, $settings)
                $xml = [Xml.XmlDocument]::new(); $xml.XmlResolver = $null; $xml.Load($reader)
                foreach ($node in $xml.SelectNodes('//*[local-name()="Relationship"]')) {
                    if ($node.GetAttribute('Type') -notmatch '/(oleObject|package)$') { continue }
                    $relations.Add((@($entry.FullName, $node.GetAttribute('Id'), $node.GetAttribute('Type'), $node.GetAttribute('Target'), $node.GetAttribute('TargetMode')) | ConvertTo-Json -Compress))
                }
                foreach ($node in $xml.SelectNodes('//*[local-name()="OLEObject"]')) {
                    $attributes = @($node.Attributes | Where-Object NamespaceURI -NE 'http://www.w3.org/2000/xmlns/' | ForEach-Object { '{0}|{1}|{2}' -f $_.NamespaceURI, $_.LocalName, $_.Value } | Sort-Object)
                    $objects.Add((@($entry.FullName) + $attributes | ConvertTo-Json -Compress))
                }
            }
            finally { if ($null -ne $reader) { $reader.Dispose() }; $inputStream.Dispose() }
        }
        return [ordered]@{ Assets = $assets; Relationships = @($relations.ToArray() | Sort-Object); Objects = @($objects.ToArray() | Sort-Object) }
    }
    finally { $zip.Dispose(); $Stream.Position = 0 }
}