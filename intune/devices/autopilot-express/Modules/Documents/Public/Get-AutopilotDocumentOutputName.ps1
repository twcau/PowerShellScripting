<#
.SYNOPSIS
    Calculate a safe filename using approved tokens and the collision suffix policy.
.DESCRIPTION
    PowerShell 5.1 or later; no directory enumeration, file reservation or writing.
    A future publisher must reserve the chosen name exclusively and recheck races.
.FILECREATED
    2026-10-23
.FILELASTUPDATED
    2026-10-23
#>
function Get-AutopilotDocumentOutputName {
    <#
    .SYNOPSIS
        Preserve the exact serial payload, encoding unsafe filename characters only.
    .PARAMETER Job
        Detached version-one job with canonical Fields and validated Settings.
    .PARAMETER DocumentType
        Stable document-type name used only as a suffix when the base name collides.
    .PARAMETER Extension
        PDF output or retained populated DOCX; not an arbitrary executable extension.
    .PARAMETER OccupiedFileNames
        Snapshot of occupied leaf names, compared case-insensitively on Windows.
    .OUTPUTS
        Filename only. If both base and type-suffixed names are occupied, throws.
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory)][System.Collections.IDictionary]$Job,
        [Parameter(Mandatory)][ValidateSet('BirthCertificate', 'Checklist')][string]$DocumentType,
        [ValidateSet('pdf', 'docx')][string]$Extension = 'pdf',
        [AllowEmptyCollection()][string[]]$OccupiedFileNames = @()
    )
    if ($Job['SchemaVersion'] -ne 1 -or $Job['Settings'] -isnot [System.Collections.IDictionary] -or $Job['Fields'] -isnot [System.Collections.IDictionary]) { throw 'Unsupported document job contract.' }
    $tokens = [ordered]@{ SerialNumberOrServiceTag = $Job['Fields']['SerialNumberOrServiceTag']; DispatchDate = $Job['Fields']['DispatchDate']; DocumentType = $DocumentType; RecordId = $Job['RecordId']; BuildCycleId = $Job['BuildCycleId']; JobId = $Job['JobId'] }
    $stem = [string]$Job['Settings']['FileNamePattern']
    foreach ($key in $tokens.Keys) {
        $value = $tokens[$key]
        if ($value -isnot [string] -or [string]::IsNullOrWhiteSpace($value)) { throw ('Missing filename field: {0}.' -f $key) }
        $encoded = [Uri]::EscapeDataString($value)
        $stem = $stem.Replace(('{{{0}}}' -f $key), $encoded)
    }
    if ([string]::IsNullOrWhiteSpace($stem) -or $stem -match '[{}]' -or $stem.IndexOfAny([IO.Path]::GetInvalidFileNameChars()) -ge 0 -or $stem.EndsWith('.') -or $stem.EndsWith(' ') -or $stem -match '^(CON|PRN|AUX|NUL|COM[1-9]|LPT[1-9])(?:\.|$)') { throw 'Unsafe document filename.' }
    $occupied = [System.Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
    foreach ($name in $OccupiedFileNames) { $null = $occupied.Add($name) }
    $name = '{0}.{1}' -f $stem, $Extension
    if ($occupied.Contains($name)) { $name = '{0}_{1}.{2}' -f $stem, $DocumentType, $Extension }
    if ($name.Length -gt 255 -or $occupied.Contains($name)) { throw 'Document filename is too long or both approved names already exist; no overwrite is permitted.' }
    return $name
}