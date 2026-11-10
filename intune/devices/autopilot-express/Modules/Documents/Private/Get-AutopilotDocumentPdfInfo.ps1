<#
.SYNOPSIS
    Check a bounded local PDF's signature, final marker and digest without a viewer.
.DESCRIPTION
    This transport check is not PDF conformance, layout or accessibility acceptance.
    A single read handle prevents mutation while its SHA-256 is computed.
.FILECREATED
    2026-10-24
.FILELASTUPDATED
    2026-10-24
#>
function Get-AutopilotDocumentPdfInfo {
    <#
    .SYNOPSIS
        Reject missing, truncated, reparse or non-PDF worker output.
    .PARAMETER Path
        Existing absolute local PDF, never a network share or viewer executable.
    .OUTPUTS
        Length and SHA256; does not claim the document is visually correct.
    #>
    [CmdletBinding()]
    [OutputType([Collections.Specialized.OrderedDictionary])]
    param([Parameter(Mandatory)][ValidateNotNullOrEmpty()][string]$Path)
    $leaf = [IO.Path]::GetFileName($Path)
    if ([string]::IsNullOrWhiteSpace($leaf) -or $leaf.IndexOfAny([IO.Path]::GetInvalidFileNameChars()) -ge 0) { throw 'Invalid PDF leaf name.' }
    $directory = Resolve-AutopilotDocumentLocalPath -Path ([IO.Path]::GetDirectoryName($Path))
    $localPath = Join-Path $directory $leaf
    $file = Get-Item -LiteralPath $localPath -Force -ErrorAction Stop
    if ($file.Length -lt 16 -or $file.Length -gt 134217728 -or $file.Extension -ine '.pdf' -or ($file.Attributes -band [IO.FileAttributes]::ReparsePoint)) { throw 'Invalid PDF path, size or attributes.' }
    $stream = [IO.File]::Open($localPath, [IO.FileMode]::Open, [IO.FileAccess]::Read, [IO.FileShare]::Read)
    $sha = [Security.Cryptography.SHA256]::Create()
    try {
        $header = [byte[]]::new(8); $null = $stream.Read($header, 0, $header.Length)
        if ([Text.Encoding]::ASCII.GetString($header) -cnotmatch '^%PDF-(1\.[0-7]|2\.0)') { throw 'Worker output has no supported PDF header.' }
        $tailLength = [int][Math]::Min(1024, $stream.Length); $stream.Position = $stream.Length - $tailLength
        $tail = [byte[]]::new($tailLength); $null = $stream.Read($tail, 0, $tail.Length)
        if ([Text.Encoding]::ASCII.GetString($tail) -cnotmatch '%%EOF[\x00\x09\x0A\x0C\x0D\x20]*\z') { throw 'Worker PDF is truncated or has unexpected trailing content.' }
        $stream.Position = 0
        return [ordered]@{ Length = $stream.Length; SHA256 = [BitConverter]::ToString($sha.ComputeHash($stream)).Replace('-', '') }
    }
    finally { $sha.Dispose(); $stream.Dispose() }
}