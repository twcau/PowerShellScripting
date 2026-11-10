<#
.SYNOPSIS
    Self-test verified document DLLs in an isolated Windows PowerShell process.
.DESCRIPTION
    PowerShell 5.1/.NET Framework 4.8 only. Synthetic DOCX and PNG remain in memory.
    This is not Word/PDF/print acceptance. The parent supervises the deadline.
.FILECREATED
    2026-10-24
.FILELASTUPDATED
    2026-10-24
#>
#Requires -Version 5.1
[CmdletBinding()]
param([Parameter(Mandatory)][ValidateNotNullOrEmpty()][string]$DependencyRoot)
$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
$memory = $null; $readMemory = $null; $document = $null; $png = $null; $bitmap = $null; $decodedBitmap = $null
try {
    if ($PSVersionTable.PSEdition -ne 'Desktop') { throw 'The reviewed library assets require the isolated Desktop worker.' }
    $moduleRoot = Split-Path -Parent $PSScriptRoot
    Import-Module (Join-Path $moduleRoot 'AutopilotExpress.Documents.psd1') -Force -ErrorAction Stop
    $verified = Test-AutopilotDocumentDependencyBundle -DependencyRoot $DependencyRoot
    if (-not $verified.Valid) { throw 'Dependency bundle is not verified.' }
    $manifest = Get-AutopilotDocumentDependencyManifest
    Add-Type -AssemblyName WindowsBase, System.Drawing -ErrorAction Stop
    foreach ($package in $manifest.Packages) {
        $path = Join-Path $verified.BundlePath $package.FileName
        $expected = [Reflection.AssemblyName]::GetAssemblyName($path)
        if (@([AppDomain]::CurrentDomain.GetAssemblies() | Where-Object { $_.GetName().Name -eq $expected.Name }).Count) { throw 'A document assembly was unexpectedly preloaded in the fresh worker.' }
        $loaded = [Reflection.Assembly]::LoadFrom($path)
        if ($loaded.Location -ine $path -or $loaded.FullName -cne $expected.FullName) { throw 'Document assembly location/version drift.' }
    }
    $memory = [IO.MemoryStream]::new()
    $document = [DocumentFormat.OpenXml.Packaging.WordprocessingDocument]::Create($memory, [DocumentFormat.OpenXml.WordprocessingDocumentType]::Document, $true)
    $main = $document.AddMainDocumentPart()
    $main.Document = [DocumentFormat.OpenXml.Wordprocessing.Document]::new()
    $body = [DocumentFormat.OpenXml.Wordprocessing.Body]::new()
    $paragraph = [DocumentFormat.OpenXml.Wordprocessing.Paragraph]::new()
    $run = [DocumentFormat.OpenXml.Wordprocessing.Run]::new()
    $text = [DocumentFormat.OpenXml.Wordprocessing.Text]::new('DOCGEN3-SYNTHETIC')
    $run.Append([DocumentFormat.OpenXml.OpenXmlElement[]](,$text))
    $paragraph.Append([DocumentFormat.OpenXml.OpenXmlElement[]](,$run))
    $body.Append([DocumentFormat.OpenXml.OpenXmlElement[]](,$paragraph))
    $main.Document.Append([DocumentFormat.OpenXml.OpenXmlElement[]](,$body))
    $main.Document.Save()
    $document.Dispose(); $document = $null
    $readMemory = [IO.MemoryStream]::new($memory.ToArray())
    $document = [DocumentFormat.OpenXml.Packaging.WordprocessingDocument]::Open($readMemory, $false)
    if ($document.MainDocumentPart.Document.InnerText -cne 'DOCGEN3-SYNTHETIC') { throw 'Open XML round trip failed.' }
    $validator = [DocumentFormat.OpenXml.Validation.OpenXmlValidator]::new()
    if (@($validator.Validate($document)).Count) { throw 'Synthetic Open XML package failed validation.' }
    $writer = [ZXing.BarcodeWriter]::new()
    $writer.Format = [ZXing.BarcodeFormat]::CODE_128
    $writer.Options = [ZXing.Common.EncodingOptions]::new()
    $writer.Options.Width = 420; $writer.Options.Height = 100; $writer.Options.Margin = 12; $writer.Options.PureBarcode = $true
    $bitmap = $writer.Write('DOCGEN3-CI00123')
    $png = [IO.MemoryStream]::new()
    $bitmap.Save($png, [Drawing.Imaging.ImageFormat]::Png)
    $png.Position = 0
    $decodedBitmap = [Drawing.Bitmap]::new($png)
    $reader = [ZXing.BarcodeReader]::new()
    $decoded = $reader.Decode($decodedBitmap)
    if ($null -eq $decoded -or $decoded.Text -cne 'DOCGEN3-CI00123' -or $decoded.BarcodeFormat -ne [ZXing.BarcodeFormat]::CODE_128) { throw 'Code 128 PNG round trip failed.' }
    [ordered]@{ SchemaVersion = 1; Status = 'Passed'; BundleId = $manifest.BundleId; WorkerPid = $PID; OpenXmlRoundTrip = $true; Code128PngRoundTrip = $true; WordLaunched = $false } | ConvertTo-Json -Compress
}
catch {
    [ordered]@{ SchemaVersion = 1; Status = 'Failed'; Diagnostic = ('Synthetic library probe failed: {0}' -f $_.Exception.Message) } | ConvertTo-Json -Compress
    exit 1
}
finally {
    foreach ($resource in @($decodedBitmap, $bitmap, $png, $document, $readMemory, $memory)) { if ($null -ne $resource) { $resource.Dispose() } }
}