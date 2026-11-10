<#
.SYNOPSIS
    Normalise JSON objects at the isolated document boundary without evaluating text.
.DESCRIPTION
    PowerShell 5.1 or later; preserves arrays, Booleans, strings and null values.
.FILECREATED
    2026-10-24
.FILELASTUPDATED
    2026-10-24
#>
function ConvertTo-AutopilotDocumentDictionary {
    <#
    .SYNOPSIS
        Recursively copy serialised objects into dictionaries used by document contracts.
    .PARAMETER Value
        Parsed JSON value, never executable configuration.
    .OUTPUTS
        Detached dictionaries/scalars; arrays are returned without pipeline flattening.
    #>
    [CmdletBinding()]
    [OutputType([object], [Collections.Specialized.OrderedDictionary], [object[]])]
    param([AllowNull()][object]$Value)
    if ($null -eq $Value) { return $null }
    if ($Value -is [string] -or $Value -is [ValueType]) { return $Value }
    if ($Value -is [Collections.IDictionary] -or $Value -is [pscustomobject]) {
        $copy = [ordered]@{}
        if ($Value -is [Collections.IDictionary]) {
            foreach ($key in $Value.Keys) { $copy[$key] = ConvertTo-AutopilotDocumentDictionary -Value $Value[$key] }
        }
        else {
            foreach ($property in $Value.PSObject.Properties) { $copy[$property.Name] = ConvertTo-AutopilotDocumentDictionary -Value $property.Value }
        }
        return $copy
    }
    if ($Value -is [Collections.IEnumerable] -and $Value -isnot [string]) {
        $items = [Collections.Generic.List[object]]::new()
        foreach ($item in $Value) { $items.Add((ConvertTo-AutopilotDocumentDictionary -Value $item)) }
        return ,$items.ToArray()
    }
    return $Value
}