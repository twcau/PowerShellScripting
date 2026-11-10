<#
.SYNOPSIS
    Load the side-effect-free document settings and job contract functions.
.DESCRIPTION
    Requires Windows PowerShell 5.1 or PowerShell 7. No document libraries,
    filesystem writes, network access, logging sessions or workers are started.
    The caller supplies the bootstrap-authorised application root explicitly.
.FILECREATED
    2026-10-23
.FILELASTUPDATED
    2026-10-23
#>
#Requires -Version 5.1
Set-StrictMode -Version Latest
$moduleRoot = $PSScriptRoot
. (Join-Path $moduleRoot 'Private/Get-AutopilotDocumentCompletionRule.ps1')
. (Join-Path $moduleRoot 'Private/Get-AutopilotDocumentTemplateBindings.ps1')
. (Join-Path $moduleRoot 'Private/Test-AutopilotDocumentJobDirectory.ps1')
. (Join-Path $moduleRoot 'Private/Complete-AutopilotDocumentJob.ps1')
. (Join-Path $moduleRoot 'Private/Move-AutopilotDocumentReviewArtifacts.ps1')
. (Join-Path $moduleRoot 'Private/Write-AutopilotDocumentReceipt.ps1')
. (Join-Path $moduleRoot 'Private/Publish-AutopilotDocumentPdf.ps1')
. (Join-Path $moduleRoot 'Private/Invoke-AutopilotDocumentDeliveryCore.ps1')
. (Join-Path $moduleRoot 'Private/New-AutopilotDocumentDeliveryAdapter.ps1')
foreach ($privateName in @('Resolve-AutopilotDocumentLocalPath', 'Test-AutopilotDocumentPackage', 'Set-AutopilotDocumentParagraphText', 'ConvertTo-AutopilotDocumentDictionary', 'Set-AutopilotDocumentControl', 'Get-AutopilotDocumentPreservedContent', 'Get-AutopilotDocumentValidationWarnings', 'Get-AutopilotDocumentPdfInfo', 'New-AutopilotDocumentWordAdapter', 'Invoke-AutopilotDocumentWordExport', 'Stop-AutopilotDocumentOwnedWord', 'New-AutopilotDocumentCopy', 'Add-AutopilotDocumentBarcode')) {
    . (Join-Path $moduleRoot ('Private/{0}.ps1' -f $privateName))
}
$publicFunctions = @('Resolve-AutopilotDocumentSettings', 'Test-AutopilotDocumentTick', 'New-AutopilotDocumentJob', 'Get-AutopilotDocumentOutputName', 'New-AutopilotDocumentResult', 'Get-AutopilotDocumentDependencyManifest', 'Get-AutopilotDocumentHostCapability', 'Test-AutopilotDocumentDependencyBundle', 'Install-AutopilotDocumentDependencyBundle', 'Invoke-AutopilotDocumentDependencySelfTest', 'Test-AutopilotDocumentPrerequisite', 'Get-AutopilotDocumentBarcodeLayout', 'Invoke-AutopilotDocumentPopulation')
$publicFunctions += @('Get-AutopilotDocumentTemplateProfile', 'Invoke-AutopilotDocumentPdfExport')
$publicFunctions += @('Invoke-AutopilotDocumentDelivery', 'Invoke-AutopilotDocumentCleanup')
$publicFunctions += @('Start-AutopilotDocumentJob', 'Receive-AutopilotDocumentJob')
. (Join-Path $moduleRoot 'Private/Write-AutopilotDocumentLifecycle.ps1')
foreach ($functionName in $publicFunctions) {
    . (Join-Path $moduleRoot ('Public/{0}.ps1' -f $functionName))
}
Export-ModuleMember -Function $publicFunctions