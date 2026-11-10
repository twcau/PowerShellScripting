<#
.SYNOPSIS
    Resolve validated, independent document settings without side effects.
.DESCRIPTION
    This function collection requires PowerShell 5.1 or later only. It does not
    create paths, persist preferences, load document packages or start workers.
.FILECREATED
    2026-10-23
.FILELASTUPDATED
    2026-10-29
#>
function Resolve-AutopilotDocumentSettings {
    <#
    .SYNOPSIS
        Resolve each setting from defaults through explicit command-line overrides.
    .PARAMETER ScriptRoot
        Absolute bootstrap-authorised application directory, never the current directory.
    .PARAMETER LocalApplicationData
        Absolute local per-technician application-data directory; no temporary fallback.
    .PARAMETER RuntimeConfiguration
        Normalised documentGeneration dictionary, not the whole runtime configuration.
    .PARAMETER SavedPreferences
        Previously validated technician/mode/tenant preference values; not written here.
    .PARAMETER SessionPreferences
        In-memory settings; cannot supersede a command-line pin until it is removed.
    .PARAMETER CommandLineOverrides
        Explicit overrides. Null means absent, whereas false is an explicit disable.
    .OUTPUTS
        Dictionary with SchemaVersion, detached Values and per-setting Sources.
    #>
    [CmdletBinding()]
    [OutputType([System.Collections.Specialized.OrderedDictionary])]
    param(
        [Parameter(Mandatory)][ValidateNotNullOrEmpty()][string]$ScriptRoot,
        [Parameter(Mandatory)][ValidateNotNullOrEmpty()][string]$LocalApplicationData,
        [System.Collections.IDictionary]$RuntimeConfiguration = @{},
        [System.Collections.IDictionary]$SavedPreferences = @{},
        [System.Collections.IDictionary]$SessionPreferences = @{},
        [System.Collections.IDictionary]$CommandLineOverrides = @{}
    )
    foreach ($root in @($ScriptRoot, $LocalApplicationData)) {
        if ($root -notmatch '^[A-Za-z]:[\\/]' -or $root.IndexOfAny([IO.Path]::GetInvalidPathChars()) -ge 0 -or $root.Substring(2).Contains(':')) {
            throw 'Document roots must be absolute local Windows filesystem paths.'
        }
    }
    $values = [ordered]@{
        BirthCertificateEnabled = $false
        ChecklistEnabled = $false
        # False (testing-phase default): unapproved template profiles produce final,
        # printable output and Demo-mode PDFs may print (Demo page labels remain).
        # True restores the DRAFT watermark and print prohibition for both document types.
        EnforceDocumentGuards = $false
        BirthCertificateMode = 'AutoPrint'
        ChecklistMode = 'Review'
        BirthCertificateTemplatePath = 'templates/Autopilot Birth Certificate - v1.5.docx'
        ChecklistTemplatePath = 'templates/Autopilot Checklist - v1.5.docx'
        LocalRoot = Join-Path $LocalApplicationData 'PowerShellScriptingNew/AutopilotExpress/Documents'
        FileNamePattern = '{SerialNumberOrServiceTag}_{DispatchDate}'
        WorkerTimeoutSeconds = 60
        FailedJobRetentionDays = 7
    }
    $sources = [ordered]@{}
    foreach ($key in $values.Keys) { $sources[$key] = 'Default' }
    $layers = [ordered]@{
        RuntimeConfiguration = $RuntimeConfiguration; SavedPreferences = $SavedPreferences
        SessionPreferences = $SessionPreferences; CommandLineOverrides = $CommandLineOverrides
    }
    foreach ($layerName in $layers.Keys) {
        $layer = $layers[$layerName]
        if ($null -eq $layer) { continue }
        foreach ($key in $layer.Keys) {
            if ($key -notin @($values.Keys)) { throw ('Unknown document setting: {0}.' -f $key) }
            $value = $layer[$key]
            if ($null -eq $value -and $layerName -eq 'CommandLineOverrides') { continue }
            if ($key -in @('BirthCertificateEnabled', 'ChecklistEnabled', 'EnforceDocumentGuards')) {
                if ($value -isnot [bool]) { throw ('{0} must be a Boolean, not text or a number.' -f $key) }
            }
            elseif ($key -in @('WorkerTimeoutSeconds', 'FailedJobRetentionDays')) {
                if ($value -isnot [int] -and $value -isnot [long]) { throw ('{0} must be an integer.' -f $key) }
                $minimum = if ($key -eq 'WorkerTimeoutSeconds') { 1 } else { 0 }
                $maximum = if ($key -eq 'WorkerTimeoutSeconds') { 3600 } else { 3650 }
                if ($value -lt $minimum -or $value -gt $maximum) { throw ('{0} must be between {1} and {2}.' -f $key, $minimum, $maximum) }
            }
            else {
                if ($value -isnot [string] -or [string]::IsNullOrWhiteSpace($value)) { throw ('{0} must be non-empty text.' -f $key) }
                if ($key -in @('BirthCertificateMode', 'ChecklistMode') -and $value -cnotin @('Disabled', 'GenerateOnly', 'Review', 'GenerateAndAsk', 'AutoPrint')) {
                    throw ('Unsupported document mode for {0}.' -f $key)
                }
            }
            $values[$key] = $value
            $sources[$key] = $layerName
        }
    }
    $localRoot = [string]$values.LocalRoot
    if ($localRoot -notmatch '^[A-Za-z]:[\\/]' -or $localRoot.IndexOfAny([IO.Path]::GetInvalidPathChars()) -ge 0 -or $localRoot.Substring(2).Contains(':')) {
        throw 'LocalRoot must be an absolute local filesystem path, not a URI, provider or UNC path.'
    }
    $values.LocalRoot = [IO.Path]::GetFullPath($localRoot)
    foreach ($key in @('BirthCertificateTemplatePath', 'ChecklistTemplatePath')) {
        $path = [string]$values[$key]
        if ($path -match '(^[\\/]{2}|:)' -and $path -notmatch '^[A-Za-z]:[\\/]') { throw 'Template paths must be filesystem paths, not provider or web URLs.' }
        if ($path.IndexOfAny([IO.Path]::GetInvalidPathChars()) -ge 0 -or $path -match '[*?]' -or [IO.Path]::GetExtension($path) -ine '.docx') { throw 'Template paths must name a DOCX file without wildcards.' }
        if (-not [IO.Path]::IsPathRooted($path)) { $path = Join-Path $ScriptRoot $path }
        if ($path -notmatch '^[A-Za-z]:[\\/]' -or $path.Substring(2).Contains(':')) { throw 'Template paths must resolve to absolute local filesystem paths.' }
        $values[$key] = [IO.Path]::GetFullPath($path)
    }
    $pattern = [string]$values.FileNamePattern
    if ($pattern.IndexOfAny([IO.Path]::GetInvalidFileNameChars()) -ge 0 -or $pattern.EndsWith('.') -or $pattern.EndsWith(' ')) { throw 'FileNamePattern must be a filename stem, not a path.' }
    $literal = [regex]::Replace($pattern, '\{(SerialNumberOrServiceTag|DispatchDate|DocumentType|RecordId|BuildCycleId|JobId)\}', '')
    if ($literal -match '[{}]' -or $pattern -notmatch '\{SerialNumberOrServiceTag\}') { throw 'FileNamePattern requires the serial token and supports only documented literal tokens.' }
    return [ordered]@{ SchemaVersion = 1; Values = $values; Sources = $sources }
}