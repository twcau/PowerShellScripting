<#
.SYNOPSIS
    Calculate conservative caption-free Code 128 geometry without loading libraries.
.DESCRIPTION
    Uses 300 DPI, ten quiet modules on each side, integer modules at least 0.25 mm,
    and bar height at least 6.35 mm or 15 percent of symbol width. These engineering
    limits do not replace actual print/scan acceptance. One twip equals 635 EMU.
.FILECREATED
    2026-10-24
.FILELASTUPDATED
    2026-10-24
#>
function Get-AutopilotDocumentBarcodeLayout {
    <#
    .SYNOPSIS
        Fit within a supplied usable rectangle without cropping or changing aspect ratio.
    .PARAMETER ModuleCount
        Exact bar/space module count returned by the reviewed ZXing Code 128 encoder.
    .PARAMETER WidthTwips
        Positive available width after cell margins and paragraph indentation.
    .PARAMETER HeightTwips
        Positive available height after row/cell margins and paragraph spacing.
    .OUTPUTS
        Ordered pixel/EMU geometry or an actionable too-small error. No files created.
    #>
    [CmdletBinding()]
    [OutputType([Collections.Specialized.OrderedDictionary])]
    param(
        [Parameter(Mandatory)][ValidateRange(35, 4096)][int]$ModuleCount,
        [Parameter(Mandatory)][ValidateRange(1, 31680)][int]$WidthTwips,
        [Parameter(Mandatory)][ValidateRange(1, 31680)][int]$HeightTwips
    )
    $widthPixels = [int][Math]::Floor($WidthTwips * 300.0 / 1440)
    $heightPixels = [int][Math]::Floor($HeightTwips * 300.0 / 1440)
    $modulePixels = [int][Math]::Min([Math]::Floor($widthPixels / ($ModuleCount + 20.0)), [Math]::Floor($heightPixels / ($ModuleCount * 0.15)))
    if ($modulePixels -lt 3 -or $heightPixels -lt 75) {
        $exception = [InvalidOperationException]::new('Barcode cannot fit readable integer modules, height and quiet zones in the unchanged rectangle.')
        $PSCmdlet.ThrowTerminatingError([Management.Automation.ErrorRecord]::new($exception, 'AutopilotBarcodeDoesNotFit', [Management.Automation.ErrorCategory]::LimitsExceeded, $null))
    }
    $widthPixels = ($ModuleCount + 20) * $modulePixels
    $minimumHeight = [Math]::Max(75, [Math]::Ceiling($ModuleCount * $modulePixels * 0.15))
    if ($heightPixels -lt $minimumHeight) {
        $exception = [InvalidOperationException]::new('Barcode region is too short; preserve at least 6.35 mm or 15 percent of symbol width.')
        $PSCmdlet.ThrowTerminatingError([Management.Automation.ErrorRecord]::new($exception, 'AutopilotBarcodeDoesNotFit', [Management.Automation.ErrorCategory]::LimitsExceeded, $null))
    }
    return [ordered]@{ PixelWidth = $widthPixels; PixelHeight = $heightPixels; ModulePixels = $modulePixels; QuietZoneModules = 10; Dpi = 300; WidthEmu = [long]$widthPixels * 3048; HeightEmu = [long]$heightPixels * 3048 }
}