<#
.SYNOPSIS
    Update one typed native text/date/checkbox control in the isolated renderer.
.DESCRIPTION
    Requires the reviewed Open XML SDK in the child only; no XML string replacement.
.FILECREATED
    2026-10-24
.FILELASTUPDATED
    2026-10-24
#>
function Set-AutopilotDocumentControl {
    <#
    .SYNOPSIS
        Keep native checkbox state, visible glyph and font consistent.
    .PARAMETER Control
        One matched SDK content control, never a whole arbitrary document story.
    .PARAMETER Text
        Text/date display value. Dates require an explicit ISO DateValue.
    .PARAMETER Checked
        Boolean checkbox value; null selects text/date handling.
    .PARAMETER DateValue
        ISO date for a native date control, independent of display formatting.
    .OUTPUTS
        None; throws on missing/ambiguous content or unsupported bindings.
    #>
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'None')]
    param(
        [Parameter(Mandatory)][ValidateNotNull()][object]$Control,
        [AllowEmptyString()][string]$Text = '',
        [Nullable[bool]]$Checked = $null,
        [string]$DateValue
    )
    $properties = $Control.ChildElements | Where-Object LocalName -EQ 'sdtPr' | Select-Object -First 1
    $texts = @($Control.Descendants() | Where-Object { $_.LocalName -eq 't' -and $_.NamespaceUri -eq 'http://schemas.openxmlformats.org/wordprocessingml/2006/main' })
    if ($null -eq $properties -or -not $texts.Count -or @($properties.ChildElements | Where-Object LocalName -EQ 'dataBinding').Count) { throw 'Control content is missing or externally data-bound.' }
    if (@($Control.Descendants() | Where-Object { $_.LocalName -in @('sdt','drawing','pict','fldChar','instrText','tab','br','hyperlink') }).Count -or @($texts | Where-Object { $_.Parent.LocalName -ne 'r' }).Count) { throw 'Nested or mixed native-control content is not supported.' }
    if ($Text -match '[\x00-\x08\x0B\x0C\x0E-\x1F\r\n]') { throw 'Native control text contains unsupported control characters.' }
    $checkboxes = @($properties.ChildElements | Where-Object LocalName -EQ 'checkbox')
    $dates = @($properties.ChildElements | Where-Object LocalName -EQ 'date')
    if ($null -ne $Checked -and $checkboxes.Count -ne 1) { throw 'Expected exactly one native checkbox.' }
    if ($null -eq $Checked -and $checkboxes.Count) { throw 'A checkbox must be mapped as a Boolean, not text.' }
    if ($dates.Count -and -not $DateValue) { throw 'Native date controls require an explicit ISO date.' }
    if (-not $PSCmdlet.ShouldProcess('Owned content control', 'Update typed content and native state')) { return }
    if ($null -ne $Checked) {
        $checkbox = $checkboxes[0]
        if ($null -eq $checkbox.Checked -or $null -eq $checkbox.CheckedState -or $null -eq $checkbox.UncheckedState) { throw 'Checkbox states/glyph definitions are incomplete.' }
        $checkbox.Checked.Val = [DocumentFormat.OpenXml.Office2010.Word.OnOffValues]::Zero
        if ($Checked) { $checkbox.Checked.Val = [DocumentFormat.OpenXml.Office2010.Word.OnOffValues]::One }
        $state = $checkbox.UncheckedState
        if ($Checked) { $state = $checkbox.CheckedState }
        $Text = [char]::ConvertFromUtf32([Convert]::ToInt32([string]$state.Val, 16))
        $run = $texts[0].Parent
        if ($null -eq $run.RunProperties) { $run.RunProperties = [DocumentFormat.OpenXml.Wordprocessing.RunProperties]::new() }
        if ($null -eq $run.RunProperties.RunFonts) { $run.RunProperties.RunFonts = [DocumentFormat.OpenXml.Wordprocessing.RunFonts]::new() }
        $run.RunProperties.RunFonts.Ascii = [string]$state.Font; $run.RunProperties.RunFonts.HighAnsi = [string]$state.Font
    }
    if ($dates.Count) { $dates[0].FullDate = [DateTimeOffset]::Parse($DateValue, [Globalization.CultureInfo]::InvariantCulture).UtcDateTime }
    $texts[0].Text = $Text; $texts[0].Space = [DocumentFormat.OpenXml.SpaceProcessingModeValues]::Preserve
    for ($index = 1; $index -lt $texts.Count; $index++) { $texts[$index].Text = '' }
}