<#
.SYNOPSIS
    Export opt-in document contracts and isolated job/delivery APIs.
.DESCRIPTION
    Requires PowerShell 5.1 or later. Import remains inert: no package acquisition,
    SDK loads, Word activation, document rendering or filesystem writes.
.FILECREATED
    2026-10-23
.FILELASTUPDATED
    2026-10-25
#>
@{
    RootModule = 'AutopilotExpress.Documents.psm1'
    ModuleVersion = '0.1.0'
    GUID = '72b0b858-37aa-47c7-ab58-38f64f937f6a'
    Author = 'Michael Harris'
    Description = 'Opt-in detached document jobs, isolated rendering and durable delivery receipts; inert module import.'
    PowerShellVersion = '5.1'
    FunctionsToExport = @('Resolve-AutopilotDocumentSettings', 'Test-AutopilotDocumentTick', 'New-AutopilotDocumentJob', 'Get-AutopilotDocumentOutputName', 'New-AutopilotDocumentResult', 'Get-AutopilotDocumentDependencyManifest', 'Get-AutopilotDocumentHostCapability', 'Test-AutopilotDocumentDependencyBundle', 'Install-AutopilotDocumentDependencyBundle', 'Invoke-AutopilotDocumentDependencySelfTest', 'Test-AutopilotDocumentPrerequisite', 'Get-AutopilotDocumentBarcodeLayout', 'Invoke-AutopilotDocumentPopulation', 'Get-AutopilotDocumentTemplateProfile', 'Invoke-AutopilotDocumentPdfExport', 'Invoke-AutopilotDocumentDelivery', 'Invoke-AutopilotDocumentCleanup', 'Start-AutopilotDocumentJob', 'Receive-AutopilotDocumentJob')
    CmdletsToExport = @()
    VariablesToExport = @()
    AliasesToExport = @()
}