<#
.SYNOPSIS
    Replace literal spans across adjacent typed Word text nodes without rewriting XML.
.DESCRIPTION
    Called only inside the dependency-isolated worker after SDK loading. Markers
    cannot cross paragraphs, fields, tabs, drawings, controls or hyperlink boundaries.
.FILECREATED
    2026-10-24
.FILELASTUPDATED
    2026-10-24
#>
function Set-AutopilotDocumentParagraphText {
    <#
    .SYNOPSIS
        Preserve runs and surrounding text while replacing all literal marker spans.
    .PARAMETER Paragraph
        Typed SDK paragraph in an owned document copy.
    .PARAMETER Replacements
        Literal marker/text dictionary; replacement values are not scanned as markers.
    .OUTPUTS
        Number of replaced spans. Invalid/overlapping markers fail before mutation.
    #>
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'None')]
    [OutputType([int])]
    param(
        [Parameter(Mandatory)][ValidateNotNull()][object]$Paragraph,
        [Parameter(Mandatory)][ValidateNotNull()][System.Collections.IDictionary]$Replacements
    )
    $segments = [Collections.Generic.List[object]]::new()
    $nodes = [Collections.Generic.List[object]]::new()
    foreach ($child in $Paragraph.ChildElements) {
        if ($child.LocalName -in @('proofErr','bookmarkStart','bookmarkEnd','commentRangeStart','commentRangeEnd')) { continue }
        if ($child.LocalName -ne 'r') {
            if ($nodes.Count) { $segments.Add($nodes.ToArray()); $nodes.Clear() }
            continue
        }
        foreach ($element in $child.ChildElements) {
            if ($element.LocalName -eq 'rPr') { continue }
            if ($element.LocalName -eq 't') { $nodes.Add($element) }
            elseif ($nodes.Count) { $segments.Add($nodes.ToArray()); $nodes.Clear() }
        }
    }
    if ($nodes.Count) { $segments.Add($nodes.ToArray()) }
    $operations = [Collections.Generic.List[object]]::new()
    foreach ($segment in $segments) {
        $text = ($segment | ForEach-Object { $_.Text }) -join ''
        $matchesFound = [Collections.Generic.List[object]]::new()
        foreach ($key in $Replacements.Keys) {
            if ($key -isnot [string] -or -not $key.Length -or $Replacements[$key] -isnot [string] -or $Replacements[$key] -match '[\x00-\x08\x0B\x0C\x0E-\x1F]') { throw 'Literal document mappings require nonempty marker keys and XML-safe text values.' }
            $offset = 0
            while ($offset -le $text.Length - $key.Length) {
                $start = $text.IndexOf($key, $offset, [StringComparison]::Ordinal)
                if ($start -lt 0) { break }
                $matchesFound.Add(@{ Start = $start; Length = $key.Length; Value = $Replacements[$key] })
                $offset = $start + $key.Length
            }
        }
        $ordered = @($matchesFound | Sort-Object { $_.Start })
        $end = -1
        foreach ($match in $ordered) {
            if ($match.Start -lt $end) { throw 'Overlapping literal document markers are ambiguous.' }
            $end = $match.Start + $match.Length
            $operations.Add(@{ Nodes = $segment; Match = $match })
        }
    }
    if (-not $PSCmdlet.ShouldProcess('Owned paragraph text nodes', 'Replace mapped literal spans')) { return 0 }
    for ($index = $operations.Count - 1; $index -ge 0; $index--) {
        $operation = $operations[$index]; $match = $operation.Match
        $position = 0; $inserted = $false
        foreach ($node in $operation.Nodes) {
            $length = $node.Text.Length
            $from = [Math]::Max(0, $match.Start - $position)
            $to = [Math]::Min($length, $match.Start + $match.Length - $position)
            if ($to -gt $from) {
                $value = if ($inserted) { '' } else { $match.Value }
                $node.Text = $node.Text.Substring(0, $from) + $value + $node.Text.Substring($to)
                $node.Space = [DocumentFormat.OpenXml.SpaceProcessingModeValues]::Preserve
                $inserted = $true
            }
            $position += $length
        }
    }
    return $operations.Count
}