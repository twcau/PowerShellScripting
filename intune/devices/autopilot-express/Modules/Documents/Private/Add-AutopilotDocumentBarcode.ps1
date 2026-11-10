<#
.SYNOPSIS
    Insert a decode-verified PNG in a fingerprint-bound table paragraph.
.DESCRIPTION
    Child-only Open XML/ZXing/System.Drawing. Preserves all table/row dimensions.
    Bounds are conservative: minimum 120-twip cell insets and 240-twip line slack,
    increased by explicit margins/spacing. Unknown/merged/relative regions fail.
    Renders at 600 DPI inside the unchanged 300-DPI-planned physical rectangle.
    Word's observed 200-DPI PDF conversion then uses an integer sampling ratio,
    avoiding the damaged narrow modules seen with 300-DPI wired-MAC images.
.FILECREATED
    2026-10-24
.FILELASTUPDATED
    2026-10-24
#>
function Add-AutopilotDocumentBarcode {
    <#
    .SYNOPSIS
        Generate exact printable-ASCII Code 128 and add a typed inline image relation.
    .PARAMETER Paragraph
        Dedicated mapped paragraph containing only the expected placement example.
    .PARAMETER Part
        Owning document/header/footer part, where the image relationship belongs.
    .PARAMETER Payload
        Exact identifier; never trim, case-fold, caption, URI-encode or truncate it.
    .PARAMETER Binding
        Reviewed bounds WidthTwips/HeightTwips, each no larger than usable cell bounds.
    .PARAMETER DrawingId
        Document-wide unique positive drawing identifier supplied by the renderer.
    .OUTPUTS
        None. Too-small or non-decodable symbols fail before the document is published.
    #>
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'None')]
    param(
        [Parameter(Mandatory)][ValidateNotNull()][object]$Paragraph,
        [Parameter(Mandatory)][ValidateNotNull()][object]$Part,
        [Parameter(Mandatory)][ValidateNotNullOrEmpty()][string]$Payload,
        [Parameter(Mandatory)][ValidateNotNull()][Collections.IDictionary]$Binding,
        [Parameter(Mandatory)][ValidateRange(1, 2147483647)][int]$DrawingId
    )
    if ($Payload.Length -gt 80 -or $Payload -match '[^\x20-\x7E]') { throw 'Code 128 identifiers must be 1-80 printable ASCII characters; no substitution is permitted.' }
    $cell = $Paragraph.Parent
    while ($null -ne $cell -and $cell.LocalName -ne 'tc') { $cell = $cell.Parent }
    if ($null -eq $cell -or $cell.Parent.LocalName -ne 'tr') { throw 'A barcode requires a reviewed dedicated table-cell paragraph.' }
    $row = $cell.Parent; $table = $row.Parent
    $width = $cell.TableCellProperties.TableCellWidth
    $height = $row.TableRowProperties.ChildElements | Where-Object LocalName -EQ 'trHeight' | Select-Object -First 1
    if ($null -eq $width -or [string]$width.Type -ne 'dxa' -or $null -eq $height -or $null -ne $cell.TableCellProperties.VerticalMerge) { throw 'Barcode cell requires absolute width and an explicit non-merged row height.' }
    $insets = @{ top = 120; bottom = 120; left = 120; right = 120 }
    $lineSlack = 240
    if ($Binding.Contains('ReviewedInsetsTwips')) {
        foreach ($side in @('top', 'bottom', 'left', 'right')) {
            $inset = $Binding['ReviewedInsetsTwips'][$side]
            if ($inset -isnot [int] -and $inset -isnot [long] -or $inset -lt 0 -or $inset -gt 31680) { throw 'Invalid reviewed barcode inset.' }
            $insets[$side] = [int]$inset
        }
        $lineSlack = [int]$Binding['LineSlackTwips']
        if ($lineSlack -lt 120 -or $lineSlack -gt 31680) { throw 'Invalid reviewed barcode line slack.' }
    }
    $tableProperties = $table.ChildElements | Where-Object LocalName -EQ 'tblPr' | Select-Object -First 1
    foreach ($properties in @($tableProperties, $cell.TableCellProperties)) {
        if ($null -eq $properties) { continue }
        foreach ($margins in $properties.ChildElements | Where-Object { $_.LocalName -in @('tblCellMar', 'tcMar') }) {
            foreach ($margin in $margins.ChildElements) {
                if ($margin.LocalName -notin @('top', 'bottom', 'left', 'right')) { throw 'Unsupported directional barcode cell margin.' }
                if ([string]$margin.Type -ne 'dxa') { throw 'Barcode margins must have absolute units.' }
                $insets[$margin.LocalName] = [Math]::Max($insets[$margin.LocalName], [int]$margin.Width.Value)
            }
        }
    }
    $tableGrid = $table.ChildElements | Where-Object LocalName -EQ 'tblGrid' | Select-Object -First 1
    if ($null -eq $tableGrid) { throw 'Barcode table grid is missing.' }
    $grid = @($tableGrid.ChildElements)
    $column = 0
    foreach ($sibling in $row.ChildElements | Where-Object LocalName -EQ 'tc') {
        if ([object]::ReferenceEquals($sibling, $cell)) { break }
        $span = $sibling.TableCellProperties.GridSpan
        $column += $(if ($null -eq $span) { 1 } else { [int]$span.Val.Value })
    }
    $span = if ($null -eq $cell.TableCellProperties.GridSpan) { 1 } else { [int]$cell.TableCellProperties.GridSpan.Val.Value }
    if ($column + $span -gt $grid.Count) { throw 'Barcode grid span exceeds the table grid.' }
    $gridWidth = 0
    for ($index = $column; $index -lt $column + $span; $index++) { $gridWidth += [int]$grid[$index].Width.Value }
    $usableWidth = [Math]::Min([int]$width.Width.Value, $gridWidth) - $insets.left - $insets.right
    $usableHeight = [int]$height.Val.Value - $insets.top - $insets.bottom - $lineSlack
    $spacing = if ($null -ne $Paragraph.ParagraphProperties) { $Paragraph.ParagraphProperties.SpacingBetweenLines } else { $null }
    if ($null -ne $spacing) { $usableHeight -= [int][string]$spacing.Before + [int][string]$spacing.After }
    $indent = if ($null -ne $Paragraph.ParagraphProperties) { $Paragraph.ParagraphProperties.Indentation } else { $null }
    if ($null -ne $indent) { $usableWidth -= [int][string]$indent.Left + [int][string]$indent.Right }
    if ([int]$Binding['WidthTwips'] -le 0 -or [int]$Binding['HeightTwips'] -le 0) { throw 'Mapped barcode rectangle must have positive dimensions.' }
    if ($Binding['WidthTwips'] -gt $usableWidth -or $Binding['HeightTwips'] -gt $usableHeight) {
        $exception = [InvalidOperationException]::new('Mapped barcode rectangle exceeds unchanged table-cell bounds.')
        $PSCmdlet.ThrowTerminatingError([Management.Automation.ErrorRecord]::new($exception, 'AutopilotBarcodeDoesNotFit', [Management.Automation.ErrorCategory]::LimitsExceeded, $null))
    }
    $encoder = [ZXing.OneD.Code128Writer]::new(); $modules = $encoder.encode($Payload)
    $layout = Get-AutopilotDocumentBarcodeLayout -ModuleCount $modules.Length -WidthTwips $Binding['WidthTwips'] -HeightTwips $Binding['HeightTwips']
    if (-not $PSCmdlet.ShouldProcess('Owned document copy', 'Insert exact-payload decode-verified barcode PNG')) { return }
    $bitmap = $null; $png = $null; $decodedBitmap = $null
    try {
        $writer = [ZXing.BarcodeWriter]::new(); $writer.Format = [ZXing.BarcodeFormat]::CODE_128
        $writer.Options = [ZXing.Common.EncodingOptions]::new(); $writer.Options.PureBarcode = $true
        $writer.Options.Width = $layout.PixelWidth * 2; $writer.Options.Height = $layout.PixelHeight * 2; $writer.Options.Margin = 20
        $bitmap = $writer.Write($Payload); $bitmap.SetResolution(600, 600)
        if ($bitmap.Width -ne $layout.PixelWidth * 2 -or $bitmap.Height -ne $layout.PixelHeight * 2) { throw 'Barcode writer did not honour the integer-module dimensions.' }
        $png = [IO.MemoryStream]::new(); $bitmap.Save($png, [Drawing.Imaging.ImageFormat]::Png); $png.Position = 0
        $decodedBitmap = [Drawing.Bitmap]::new($png); $decoder = [ZXing.BarcodeReader]::new(); $decoded = $decoder.Decode($decodedBitmap)
        if ($null -eq $decoded -or $decoded.Text -cne $Payload -or $decoded.BarcodeFormat -ne [ZXing.BarcodeFormat]::CODE_128) { throw 'Saved Code 128 PNG does not decode exactly.' }
        $png.Position = 0
        $imageMethod = [DocumentFormat.OpenXml.Packaging.OpenXmlSupportedRelationshipExtensions].GetMethods() | Where-Object { $_.Name -eq 'AddImagePart' -and $_.GetParameters()[1].ParameterType -eq [DocumentFormat.OpenXml.Packaging.PartTypeInfo] } | Select-Object -First 1
        $image = $imageMethod.MakeGenericMethod([type[]]@($Part.GetType())).Invoke($null, [object[]]@($Part, [DocumentFormat.OpenXml.Packaging.ImagePartType]::Png, $null))
        $image.FeedData($png)
        $blip = [DocumentFormat.OpenXml.Drawing.Blip]::new(); $blip.Embed = $Part.GetIdOfPart($image)
        $blipFill = [DocumentFormat.OpenXml.Drawing.Pictures.BlipFill]::new(); $blipFill.Append([DocumentFormat.OpenXml.OpenXmlElement[]](,$blip))
        $stretch = [DocumentFormat.OpenXml.Drawing.Stretch]::new(); $stretch.Append([DocumentFormat.OpenXml.OpenXmlElement[]](,[DocumentFormat.OpenXml.Drawing.FillRectangle]::new())); $blipFill.Append([DocumentFormat.OpenXml.OpenXmlElement[]](,$stretch))
        $nonVisual = [DocumentFormat.OpenXml.Drawing.Pictures.NonVisualPictureProperties]::new()
        $pictureName = [DocumentFormat.OpenXml.Drawing.Pictures.NonVisualDrawingProperties]::new(); $pictureName.Id = [uint32]$DrawingId; $pictureName.Name = 'Code 128 identifier'
        $nonVisual.Append([DocumentFormat.OpenXml.OpenXmlElement[]]@($pictureName, [DocumentFormat.OpenXml.Drawing.Pictures.NonVisualPictureDrawingProperties]::new()))
        $shape = [DocumentFormat.OpenXml.Drawing.Pictures.ShapeProperties]::new(); $transform = [DocumentFormat.OpenXml.Drawing.Transform2D]::new()
        $offset = [DocumentFormat.OpenXml.Drawing.Offset]::new(); $offset.X = 0L; $offset.Y = 0L
        $extents = [DocumentFormat.OpenXml.Drawing.Extents]::new(); $extents.Cx = $layout.WidthEmu; $extents.Cy = $layout.HeightEmu
        $transform.Append([DocumentFormat.OpenXml.OpenXmlElement[]]@($offset, $extents)); $shape.Append([DocumentFormat.OpenXml.OpenXmlElement[]](,$transform))
        $geometry = [DocumentFormat.OpenXml.Drawing.PresetGeometry]::new(); $geometry.Preset = [DocumentFormat.OpenXml.Drawing.ShapeTypeValues]::Rectangle
        $geometry.Append([DocumentFormat.OpenXml.OpenXmlElement[]](,[DocumentFormat.OpenXml.Drawing.AdjustValueList]::new())); $shape.Append([DocumentFormat.OpenXml.OpenXmlElement[]](,$geometry))
        $picture = [DocumentFormat.OpenXml.Drawing.Pictures.Picture]::new(); $picture.Append([DocumentFormat.OpenXml.OpenXmlElement[]]@($nonVisual, $blipFill, $shape))
        $graphicData = [DocumentFormat.OpenXml.Drawing.GraphicData]::new(); $graphicData.Uri = 'http://schemas.openxmlformats.org/drawingml/2006/picture'; $graphicData.Append([DocumentFormat.OpenXml.OpenXmlElement[]](,$picture))
        $graphic = [DocumentFormat.OpenXml.Drawing.Graphic]::new(); $graphic.Append([DocumentFormat.OpenXml.OpenXmlElement[]](,$graphicData))
        $extent = [DocumentFormat.OpenXml.Drawing.Wordprocessing.Extent]::new(); $extent.Cx = $layout.WidthEmu; $extent.Cy = $layout.HeightEmu
        $docProperties = [DocumentFormat.OpenXml.Drawing.Wordprocessing.DocProperties]::new(); $docProperties.Id = [uint32]$DrawingId; $docProperties.Name = 'Code 128 identifier'; $docProperties.Description = 'Machine-readable identifier; exact text is supplied in the adjacent mapped text field.'
        $inline = [DocumentFormat.OpenXml.Drawing.Wordprocessing.Inline]::new(); $inline.Append([DocumentFormat.OpenXml.OpenXmlElement[]]@($extent, $docProperties, $graphic))
        $drawing = [DocumentFormat.OpenXml.Wordprocessing.Drawing]::new(); $drawing.Append([DocumentFormat.OpenXml.OpenXmlElement[]](,$inline))
        $run = [DocumentFormat.OpenXml.Wordprocessing.Run]::new(); $run.Append([DocumentFormat.OpenXml.OpenXmlElement[]](,$drawing))
        foreach ($child in @($Paragraph.ChildElements)) { if ($child.LocalName -ne 'pPr') { $child.Remove() } }
        if ($null -eq $Paragraph.ParagraphProperties) { $Paragraph.ParagraphProperties = [DocumentFormat.OpenXml.Wordprocessing.ParagraphProperties]::new() }
        $justification = [DocumentFormat.OpenXml.Wordprocessing.Justification]::new()
        $justification.Val = [DocumentFormat.OpenXml.Wordprocessing.JustificationValues]::Center
        $Paragraph.ParagraphProperties.Justification = $justification
        $Paragraph.Append([DocumentFormat.OpenXml.OpenXmlElement[]](,$run))
    }
    finally { foreach ($resource in @($decodedBitmap, $bitmap, $png)) { if ($null -ne $resource) { $resource.Dispose() } } }
}