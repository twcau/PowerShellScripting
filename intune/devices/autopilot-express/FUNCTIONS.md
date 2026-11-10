<!-- omit from toc -->
# Autopilot Express Function Reference

This reference covers every function defined in the active entry script and optional document module, including
nested helpers. It records source contracts, not a list of commands that technicians should run directly.
Read [TECHNICAL.md](TECHNICAL.md) for lifecycle, data and safety boundaries and [CUSTOMISATION.md](CUSTOMISATION.md)
before reusing or extending a handler. Daily operation belongs in [OPERATIONS.md](OPERATIONS.md).

## Reading the Reference

The catalogue is derived from the PowerShell abstract syntax tree and recognised comment-based help. Extraction
parses files without importing, dot-sourcing or executing them. Source links identify the actual definition;
parameters retain declared types, validation and defaults. Outputs and descriptions retain the source contract,
including side effects, cancellation and refusal boundaries where documented.

Function calls listed here are statically named PowerShell commands owned by that function. They exclude nested
function bodies, dynamic command names, member/.NET calls and callbacks whose runtime target cannot be resolved
statically. Caller links are navigation aids, not complete path coverage or a guarantee that a branch executes.
Nested helpers depend on their enclosing scope and are not independent extension APIs. Module Public functions
are exported; Private functions and workers remain implementation details.

Source line links will move when code changes. Regenerate the catalogue from the reviewed source and compare
definition identities/counts, help, signatures and fingerprints; do not refresh a count while leaving stale entries.
Test-fixture functions are intentionally outside this runtime catalogue; test ownership is in [TESTING.md](TESTING.md).

## Source Inventory

The following catalogue and inventory are generated from source. Readiness and historical release evidence remain
separate: a complete reference does not certify every host, tenant, branch or physical outcome.

| Source                                                                                                                                             | Definitions | SHA-256                                                            |
| -------------------------------------------------------------------------------------------------------------------------------------------------- | ----------: | ------------------------------------------------------------------ |
| [autopilot-express.ps1](autopilot-express.ps1)                                                                                                     |         353 | `E56D775422DFE1A6E41F0DBEC326724A9D8CD3566127533407955F9F211F7FF4` |
| [Modules/Documents/AutopilotExpress.Documents.psm1](Modules/Documents/AutopilotExpress.Documents.psm1)                                             |           0 | `097BE477007B79DF61CAC99D3DC199D3B07B5748A7AC34B0C976F245180C4846` |
| [Modules/Documents/Private/Add-AutopilotDocumentBarcode.ps1](Modules/Documents/Private/Add-AutopilotDocumentBarcode.ps1)                           |           1 | `039CAF12166DBB851263A132C71D7C21EF3CF7838CEDE89B9AD791596BEB4245` |
| [Modules/Documents/Private/Complete-AutopilotDocumentJob.ps1](Modules/Documents/Private/Complete-AutopilotDocumentJob.ps1)                         |           1 | `6471C2970BFB177D9BA31CCF8D58496EFAEB8A6C1E3682C0EF8D54D64EC7A141` |
| [Modules/Documents/Private/ConvertTo-AutopilotDocumentDictionary.ps1](Modules/Documents/Private/ConvertTo-AutopilotDocumentDictionary.ps1)         |           1 | `D8F5FC7840541B523558263E17E687EB9D845E76403129092A9FBA69B0289AE7` |
| [Modules/Documents/Private/Get-AutopilotDocumentCompletionRule.ps1](Modules/Documents/Private/Get-AutopilotDocumentCompletionRule.ps1)             |           1 | `B87121401F063A7498C0DEAFE1CF9DC5D63D5F45ED0AFEBC05BBB32ACB0A8AF7` |
| [Modules/Documents/Private/Get-AutopilotDocumentPdfInfo.ps1](Modules/Documents/Private/Get-AutopilotDocumentPdfInfo.ps1)                           |           1 | `6E2AA8CE50CF40BE565CEF053B9F8B3B56FA527B7BCC29383EA89D815E6F72CE` |
| [Modules/Documents/Private/Get-AutopilotDocumentPreservedContent.ps1](Modules/Documents/Private/Get-AutopilotDocumentPreservedContent.ps1)         |           1 | `EFD433F223B16D3EBD455A710F58A55ECFF9A641DDABED28A0E996BE6A02A570` |
| [Modules/Documents/Private/Get-AutopilotDocumentTemplateBindings.ps1](Modules/Documents/Private/Get-AutopilotDocumentTemplateBindings.ps1)         |           1 | `77D1A0C01C917B9F4053CEFB02D076B1E023A35100BAE55A87AC49B4480F5AA2` |
| [Modules/Documents/Private/Get-AutopilotDocumentValidationWarnings.ps1](Modules/Documents/Private/Get-AutopilotDocumentValidationWarnings.ps1)     |           1 | `127CFEB6559F6A352FABACBC81EF98382861D35BA97E26F3B837099084575D1E` |
| [Modules/Documents/Private/Invoke-AutopilotDocumentDeliveryCore.ps1](Modules/Documents/Private/Invoke-AutopilotDocumentDeliveryCore.ps1)           |           1 | `D41D409E7A39FF116E0915CA6FE43BF39FD0C4F234799B1FE03496363F6F824B` |
| [Modules/Documents/Private/Invoke-AutopilotDocumentWordExport.ps1](Modules/Documents/Private/Invoke-AutopilotDocumentWordExport.ps1)               |           1 | `4DB91D7A32C233EBC11098D7760B45BC3A0F9235A34E35D74394EDF3A89CA8C1` |
| [Modules/Documents/Private/Move-AutopilotDocumentReviewArtifacts.ps1](Modules/Documents/Private/Move-AutopilotDocumentReviewArtifacts.ps1)         |           1 | `E7575F3C3CF5B0E3FBC19B7B4AD14589E7D91AECCE1EA4799E8E74030EAB130E` |
| [Modules/Documents/Private/New-AutopilotDocumentCopy.ps1](Modules/Documents/Private/New-AutopilotDocumentCopy.ps1)                                 |           1 | `F15FD7308429CABB53F1672914196D615779C19FBEE37FE7C50FE972F23D02C3` |
| [Modules/Documents/Private/New-AutopilotDocumentDeliveryAdapter.ps1](Modules/Documents/Private/New-AutopilotDocumentDeliveryAdapter.ps1)           |           1 | `C828E8B6551F41A5D3456FCE052719B09470605E730C7BC3153172F804295ED2` |
| [Modules/Documents/Private/New-AutopilotDocumentWordAdapter.ps1](Modules/Documents/Private/New-AutopilotDocumentWordAdapter.ps1)                   |           1 | `241F700E76963CE6A5DCB2D774BF68E11262A2ADD08EC25D71AC71D4D97942C7` |
| [Modules/Documents/Private/Publish-AutopilotDocumentPdf.ps1](Modules/Documents/Private/Publish-AutopilotDocumentPdf.ps1)                           |           1 | `47BE7D27EC856124D1BD86863F303F2982B96FA5401AFB5F01EFA49ACA2EFFA9` |
| [Modules/Documents/Private/Resolve-AutopilotDocumentLocalPath.ps1](Modules/Documents/Private/Resolve-AutopilotDocumentLocalPath.ps1)               |           1 | `081F5094795FE2D1A300683641E0B0CF7548C9D054F246818E2DC8FE87765E3C` |
| [Modules/Documents/Private/Set-AutopilotDocumentControl.ps1](Modules/Documents/Private/Set-AutopilotDocumentControl.ps1)                           |           1 | `F8FC437402F64C074612C5C3C6A0E17EFB880E829811B9B714868CB2ECAAE935` |
| [Modules/Documents/Private/Set-AutopilotDocumentParagraphText.ps1](Modules/Documents/Private/Set-AutopilotDocumentParagraphText.ps1)               |           1 | `D7F65E4A07998A725031D6E1DB001A15F349A86C58C689DDD89A22D84BC788D2` |
| [Modules/Documents/Private/Stop-AutopilotDocumentOwnedWord.ps1](Modules/Documents/Private/Stop-AutopilotDocumentOwnedWord.ps1)                     |           1 | `36ABBDF55BBA3DC4969C9D9374BFD704857AF4696CA81DC695B53E4A5E8BF794` |
| [Modules/Documents/Private/Test-AutopilotDocumentJobDirectory.ps1](Modules/Documents/Private/Test-AutopilotDocumentJobDirectory.ps1)               |           1 | `146AAABEB4D568272046113527E06F8CE282BF009F1F555E36977005EBE42183` |
| [Modules/Documents/Private/Test-AutopilotDocumentPackage.ps1](Modules/Documents/Private/Test-AutopilotDocumentPackage.ps1)                         |           1 | `4E647D671C7E50E631F59701161F5B0C360EECA1F1E65D5677F92F0369B8FA93` |
| [Modules/Documents/Private/Write-AutopilotDocumentLifecycle.ps1](Modules/Documents/Private/Write-AutopilotDocumentLifecycle.ps1)                   |           1 | `19E5F9D8FFB5DA2039E25A5759ED4CA50159D221D8F32A83EA6C38985FE64A98` |
| [Modules/Documents/Private/Write-AutopilotDocumentReceipt.ps1](Modules/Documents/Private/Write-AutopilotDocumentReceipt.ps1)                       |           1 | `5C3BD1F5F5087BE8022C99817EA77504217F38FD611640CA69F9EF1183F15DCB` |
| [Modules/Documents/Public/Get-AutopilotDocumentBarcodeLayout.ps1](Modules/Documents/Public/Get-AutopilotDocumentBarcodeLayout.ps1)                 |           1 | `1FB95ECD55B03F114A0AF2B615B549D10DEC83AE8E3B72D3F740FA4F0DA44ADC` |
| [Modules/Documents/Public/Get-AutopilotDocumentDependencyManifest.ps1](Modules/Documents/Public/Get-AutopilotDocumentDependencyManifest.ps1)       |           1 | `DB6DD67421734795848F6C27BCAB1D074826D3FE9CAAF254AD5B04A1C47C576A` |
| [Modules/Documents/Public/Get-AutopilotDocumentHostCapability.ps1](Modules/Documents/Public/Get-AutopilotDocumentHostCapability.ps1)               |           1 | `244BC5C8E44A531DC85864A5C48822859854DFCF822B3BD778BCACC85C803396` |
| [Modules/Documents/Public/Get-AutopilotDocumentOutputName.ps1](Modules/Documents/Public/Get-AutopilotDocumentOutputName.ps1)                       |           1 | `5247955442A06BE5D1583B716D34E2983CC63AE05A47E789F49BD57024CF8D3C` |
| [Modules/Documents/Public/Get-AutopilotDocumentTemplateProfile.ps1](Modules/Documents/Public/Get-AutopilotDocumentTemplateProfile.ps1)             |           1 | `E2988340D9E3D2A225100A60940905DA46472AD367B9028A3AA28B4663366BC3` |
| [Modules/Documents/Public/Install-AutopilotDocumentDependencyBundle.ps1](Modules/Documents/Public/Install-AutopilotDocumentDependencyBundle.ps1)   |           1 | `50FD0CF2BF4DE1C2FC18353AE64247DA0EA6C1C6B68E2D1908A5584550DC33D5` |
| [Modules/Documents/Public/Invoke-AutopilotDocumentCleanup.ps1](Modules/Documents/Public/Invoke-AutopilotDocumentCleanup.ps1)                       |           1 | `E3408FD93EAE380FD43E648D8B5B6C13A3B4FD36C80B2608C432B7D9BEF31309` |
| [Modules/Documents/Public/Invoke-AutopilotDocumentDelivery.ps1](Modules/Documents/Public/Invoke-AutopilotDocumentDelivery.ps1)                     |           1 | `7FFF42AD78A7334048D372D2D8A815650480A5CCA1E985CBD368F296A6132639` |
| [Modules/Documents/Public/Invoke-AutopilotDocumentDependencySelfTest.ps1](Modules/Documents/Public/Invoke-AutopilotDocumentDependencySelfTest.ps1) |           1 | `459B3B10183086DFE863C0ABE85A2D143094AC2DC28455C5F4DCFE588130A076` |
| [Modules/Documents/Public/Invoke-AutopilotDocumentPdfExport.ps1](Modules/Documents/Public/Invoke-AutopilotDocumentPdfExport.ps1)                   |           1 | `3277D324D4D7F30EF3D7BBF3B90B23ED79B102FD144F3E8CE6531A6C52820502` |
| [Modules/Documents/Public/Invoke-AutopilotDocumentPopulation.ps1](Modules/Documents/Public/Invoke-AutopilotDocumentPopulation.ps1)                 |           1 | `7565F67A6728ABCE7E8B4B4ADAFACE25A58B90B10074B5D75BB6BF033A34CC7D` |
| [Modules/Documents/Public/New-AutopilotDocumentJob.ps1](Modules/Documents/Public/New-AutopilotDocumentJob.ps1)                                     |           1 | `B708C75D08BC97C9F3FAA1268F572615DD8ED1BC51D94BCD6A131DEDE935DD6E` |
| [Modules/Documents/Public/New-AutopilotDocumentResult.ps1](Modules/Documents/Public/New-AutopilotDocumentResult.ps1)                               |           1 | `9ABA977C99126B267D08910F12DA4479F054FA566DF030B23A2D8937D9FB1650` |
| [Modules/Documents/Public/Receive-AutopilotDocumentJob.ps1](Modules/Documents/Public/Receive-AutopilotDocumentJob.ps1)                             |           1 | `52981EA27E77D6E4BC2E3FC18DC2A8C84FCA9DBCDB9DCCB37AE58B3D9A18F014` |
| [Modules/Documents/Public/Resolve-AutopilotDocumentSettings.ps1](Modules/Documents/Public/Resolve-AutopilotDocumentSettings.ps1)                   |           1 | `F37BA324070716A7A9E1D52262988DFA317092F542000500A4B3B5F3D2E2436E` |
| [Modules/Documents/Public/Start-AutopilotDocumentJob.ps1](Modules/Documents/Public/Start-AutopilotDocumentJob.ps1)                                 |           1 | `2A5E9F24B114C6671295097DE1B0430D4635D99C5C4D429E5FCBE4AF1818E0F7` |
| [Modules/Documents/Public/Test-AutopilotDocumentDependencyBundle.ps1](Modules/Documents/Public/Test-AutopilotDocumentDependencyBundle.ps1)         |           1 | `A844E52967B447F94375DCF694D5936D6BBBC40552833F8A784CA9A3C9A2DD38` |
| [Modules/Documents/Public/Test-AutopilotDocumentPrerequisite.ps1](Modules/Documents/Public/Test-AutopilotDocumentPrerequisite.ps1)                 |           1 | `70D5D5CF215FE946633F116CBE619DF246A9295F53A45AC290A6E5227692C4D6` |
| [Modules/Documents/Public/Test-AutopilotDocumentTick.ps1](Modules/Documents/Public/Test-AutopilotDocumentTick.ps1)                                 |           1 | `5429259D5E3E35F61D2B3E4AACCCC6AE2EA6D0532554C586D6C58CB8585257AE` |
| [Modules/Documents/Workers/Export-DocumentPdf.ps1](Modules/Documents/Workers/Export-DocumentPdf.ps1)                                               |           0 | `FA7C9D7509829B353081E1EB4842BBF8AFE745D9BC8C58CD1CE589279E6F3499` |
| [Modules/Documents/Workers/Invoke-DocumentJob.ps1](Modules/Documents/Workers/Invoke-DocumentJob.ps1)                                               |           0 | `4A394CACD8E26208B7664AF55F2F34335989F491FFECB80C945D7705251224B1` |
| [Modules/Documents/Workers/Populate-Document.ps1](Modules/Documents/Workers/Populate-Document.ps1)                                                 |           0 | `044F3A6C6E33F7F5DDE168E57FD338D2CB900B5D973D1BB4B726A58DBE53E3D1` |
| [Modules/Documents/Workers/Run-DocumentJob.ps1](Modules/Documents/Workers/Run-DocumentJob.ps1)                                                     |           0 | `3B05A6DE8E7D51E4ACB9B2F409971A9D32E551D4EF2753A18ED46993EF19AF90` |
| [Modules/Documents/Workers/Test-DocumentLibraries.ps1](Modules/Documents/Workers/Test-DocumentLibraries.ps1)                                       |           0 | `9C633E7BE77C3C7B052FE96A51D50953E26D63599A7F7EF75128DBADFF07548C` |

Snapshot: 2026-11-07; 395 function definitions in 49 parsed source files.

## Generated Catalogue

Choose a source group:

- [Main Entry Script](#main-entry-script)
- [Modules/Documents/AutopilotExpress.Documents.psm1](#modulesdocumentsautopilotexpressdocumentspsm1)
- [Modules/Documents/Private/Add-AutopilotDocumentBarcode.ps1](#modulesdocumentsprivateadd-autopilotdocumentbarcodeps1)
- [Modules/Documents/Private/Complete-AutopilotDocumentJob.ps1](#modulesdocumentsprivatecomplete-autopilotdocumentjobps1)
- [Modules/Documents/Private/ConvertTo-AutopilotDocumentDictionary.ps1](#modulesdocumentsprivateconvertto-autopilotdocumentdictionaryps1)
- [Modules/Documents/Private/Get-AutopilotDocumentCompletionRule.ps1](#modulesdocumentsprivateget-autopilotdocumentcompletionruleps1)
- [Modules/Documents/Private/Get-AutopilotDocumentPdfInfo.ps1](#modulesdocumentsprivateget-autopilotdocumentpdfinfops1)
- [Modules/Documents/Private/Get-AutopilotDocumentPreservedContent.ps1](#modulesdocumentsprivateget-autopilotdocumentpreservedcontentps1)
- [Modules/Documents/Private/Get-AutopilotDocumentTemplateBindings.ps1](#modulesdocumentsprivateget-autopilotdocumenttemplatebindingsps1)
- [Modules/Documents/Private/Get-AutopilotDocumentValidationWarnings.ps1](#modulesdocumentsprivateget-autopilotdocumentvalidationwarningsps1)
- [Modules/Documents/Private/Invoke-AutopilotDocumentDeliveryCore.ps1](#modulesdocumentsprivateinvoke-autopilotdocumentdeliverycoreps1)
- [Modules/Documents/Private/Invoke-AutopilotDocumentWordExport.ps1](#modulesdocumentsprivateinvoke-autopilotdocumentwordexportps1)
- [Modules/Documents/Private/Move-AutopilotDocumentReviewArtifacts.ps1](#modulesdocumentsprivatemove-autopilotdocumentreviewartifactsps1)
- [Modules/Documents/Private/New-AutopilotDocumentCopy.ps1](#modulesdocumentsprivatenew-autopilotdocumentcopyps1)
- [Modules/Documents/Private/New-AutopilotDocumentDeliveryAdapter.ps1](#modulesdocumentsprivatenew-autopilotdocumentdeliveryadapterps1)
- [Modules/Documents/Private/New-AutopilotDocumentWordAdapter.ps1](#modulesdocumentsprivatenew-autopilotdocumentwordadapterps1)
- [Modules/Documents/Private/Publish-AutopilotDocumentPdf.ps1](#modulesdocumentsprivatepublish-autopilotdocumentpdfps1)
- [Modules/Documents/Private/Resolve-AutopilotDocumentLocalPath.ps1](#modulesdocumentsprivateresolve-autopilotdocumentlocalpathps1)
- [Modules/Documents/Private/Set-AutopilotDocumentControl.ps1](#modulesdocumentsprivateset-autopilotdocumentcontrolps1)
- [Modules/Documents/Private/Set-AutopilotDocumentParagraphText.ps1](#modulesdocumentsprivateset-autopilotdocumentparagraphtextps1)
- [Modules/Documents/Private/Stop-AutopilotDocumentOwnedWord.ps1](#modulesdocumentsprivatestop-autopilotdocumentownedwordps1)
- [Modules/Documents/Private/Test-AutopilotDocumentJobDirectory.ps1](#modulesdocumentsprivatetest-autopilotdocumentjobdirectoryps1)
- [Modules/Documents/Private/Test-AutopilotDocumentPackage.ps1](#modulesdocumentsprivatetest-autopilotdocumentpackageps1)
- [Modules/Documents/Private/Write-AutopilotDocumentLifecycle.ps1](#modulesdocumentsprivatewrite-autopilotdocumentlifecycleps1)
- [Modules/Documents/Private/Write-AutopilotDocumentReceipt.ps1](#modulesdocumentsprivatewrite-autopilotdocumentreceiptps1)
- [Modules/Documents/Public/Get-AutopilotDocumentBarcodeLayout.ps1](#modulesdocumentspublicget-autopilotdocumentbarcodelayoutps1)
- [Modules/Documents/Public/Get-AutopilotDocumentDependencyManifest.ps1](#modulesdocumentspublicget-autopilotdocumentdependencymanifestps1)
- [Modules/Documents/Public/Get-AutopilotDocumentHostCapability.ps1](#modulesdocumentspublicget-autopilotdocumenthostcapabilityps1)
- [Modules/Documents/Public/Get-AutopilotDocumentOutputName.ps1](#modulesdocumentspublicget-autopilotdocumentoutputnameps1)
- [Modules/Documents/Public/Get-AutopilotDocumentTemplateProfile.ps1](#modulesdocumentspublicget-autopilotdocumenttemplateprofileps1)
- [Modules/Documents/Public/Install-AutopilotDocumentDependencyBundle.ps1](#modulesdocumentspublicinstall-autopilotdocumentdependencybundleps1)
- [Modules/Documents/Public/Invoke-AutopilotDocumentCleanup.ps1](#modulesdocumentspublicinvoke-autopilotdocumentcleanupps1)
- [Modules/Documents/Public/Invoke-AutopilotDocumentDelivery.ps1](#modulesdocumentspublicinvoke-autopilotdocumentdeliveryps1)
- [Modules/Documents/Public/Invoke-AutopilotDocumentDependencySelfTest.ps1](#modulesdocumentspublicinvoke-autopilotdocumentdependencyselftestps1)
- [Modules/Documents/Public/Invoke-AutopilotDocumentPdfExport.ps1](#modulesdocumentspublicinvoke-autopilotdocumentpdfexportps1)
- [Modules/Documents/Public/Invoke-AutopilotDocumentPopulation.ps1](#modulesdocumentspublicinvoke-autopilotdocumentpopulationps1)
- [Modules/Documents/Public/New-AutopilotDocumentJob.ps1](#modulesdocumentspublicnew-autopilotdocumentjobps1)
- [Modules/Documents/Public/New-AutopilotDocumentResult.ps1](#modulesdocumentspublicnew-autopilotdocumentresultps1)
- [Modules/Documents/Public/Receive-AutopilotDocumentJob.ps1](#modulesdocumentspublicreceive-autopilotdocumentjobps1)
- [Modules/Documents/Public/Resolve-AutopilotDocumentSettings.ps1](#modulesdocumentspublicresolve-autopilotdocumentsettingsps1)
- [Modules/Documents/Public/Start-AutopilotDocumentJob.ps1](#modulesdocumentspublicstart-autopilotdocumentjobps1)
- [Modules/Documents/Public/Test-AutopilotDocumentDependencyBundle.ps1](#modulesdocumentspublictest-autopilotdocumentdependencybundleps1)
- [Modules/Documents/Public/Test-AutopilotDocumentPrerequisite.ps1](#modulesdocumentspublictest-autopilotdocumentprerequisiteps1)
- [Modules/Documents/Public/Test-AutopilotDocumentTick.ps1](#modulesdocumentspublictest-autopilotdocumenttickps1)
- [Modules/Documents/Workers/Export-DocumentPdf.ps1](#modulesdocumentsworkersexport-documentpdfps1)
- [Modules/Documents/Workers/Invoke-DocumentJob.ps1](#modulesdocumentsworkersinvoke-documentjobps1)
- [Modules/Documents/Workers/Populate-Document.ps1](#modulesdocumentsworkerspopulate-documentps1)
- [Modules/Documents/Workers/Run-DocumentJob.ps1](#modulesdocumentsworkersrun-documentjobps1)
- [Modules/Documents/Workers/Test-DocumentLibraries.ps1](#modulesdocumentsworkerstest-documentlibrariesps1)

## Main Entry Script

### Show-ScriptScreen

Clear the terminal and draw the shared blue header, including before mode selection.

Source: [autopilot-express.ps1:179](autopilot-express.ps1#L179). Internal entry-script function; source region: `Bootstrap and Diagnostics`.

| Parameter       | Declared Type                                  | Attributes                                                       | Default                        | Source Contract                                                            |
| --------------- | ---------------------------------------------- | ---------------------------------------------------------------- | ------------------------------ | -------------------------------------------------------------------------- |
| `Title`         | `System.String`                                | `[Parameter(Mandatory)]` `[ValidateNotNullOrEmpty()]` `[string]` | No explicit default expression | Screen purpose displayed with the current Demo/Live mode.                  |
| `ModeLabel`     | `System.String`                                | `[string]`                                                       | No explicit default expression | Optional bootstrap label; later screens use the selected runtime mode.     |
| `PromptFollows` | `System.Management.Automation.SwitchParameter` | `[switch]`                                                       | No explicit default expression | Reserve the shared blank-row boundary when the next operation reads input. |

Outputs and result contract:

Accessible host text only, with one blank row below the title.

Other named commands: `Clear-Host`, `Write-Host`.

Named callers: [Select-Site](#select-site), [Show-MainMenu](#show-mainmenu), [Start-NewDeviceWorkflow](#start-newdeviceworkflow), [Invoke-AutopilotSequence](#invoke-autopilotsequence), [Get-DeviceOutstanding](#get-deviceoutstanding), [Update-DeviceStatus](#update-devicestatus), [Show-ImagingWorkPatternEditor](#show-imagingworkpatterneditor), [Get-UserStats](#get-userstats), [Show-SessionReportExport](#show-sessionreportexport), [Read-PagedInformation](#read-pagedinformation), [Show-SessionArchive](#show-sessionarchive), [Select-RemediationMenuItem](#select-remediationmenuitem), [Show-RemediationQuickRunSettings](#show-remediationquickrunsettings), [Show-DeviceActions](#show-deviceactions), [Show-DeviceInventoryBackfill](#show-deviceinventorybackfill), [Show-BenchWorkflowGuide](#show-benchworkflowguide), [Show-BenchScreen](#show-benchscreen), [Show-RecoveryEvidenceReport](#show-recoveryevidencereport).

### Start-AutopilotDiagnostics

Start one owned transcript before bootstrap, storage reservation or authentication.

Source: [autopilot-express.ps1:209](autopilot-express.ps1#L209). Internal entry-script function; source region: `Bootstrap and Diagnostics`.

| Parameter    | Declared Type   | Attributes | Default          | Source Contract                                               |
| ------------ | --------------- | ---------- | ---------------- | ------------------------------------------------------------- |
| `SourcePath` | `System.String` | `[string]` | `$PSCommandPath` | Executing script path for a best-effort revision fingerprint. |

Outputs and result contract:

Unique log path outside operational data discovery. Falls back to TEMP;
refuses startup if neither location can retain diagnostics.

Other named commands: `Get-Date`, `Get-FileHash`, `Join-Path`, `New-Item`, `Out-Null`, `Start-Transcript`, `Write-Information`, `Write-Warning`.

No statically named function caller in this inventory. Top-level, dynamic and callback invocation remain possible.

### Complete-AutopilotDiagnostics

Close this invocation transcript without hiding the original workflow error.

Source: [autopilot-express.ps1:246](autopilot-express.ps1#L246). Internal entry-script function; source region: `Bootstrap and Diagnostics`.

| Parameter | Declared Type   | Attributes | Default                        | Source Contract                                                                   |
| --------- | --------------- | ---------- | ------------------------------ | --------------------------------------------------------------------------------- |
| `Path`    | `System.String` | `[string]` | No explicit default expression | Path returned only after successful transcript startup; null means none is owned. |

Outputs and result contract:

None. Stops only the owned transcript and reports its retained path.

Other named commands: `Out-Null`, `Stop-Transcript`, `Write-Information`, `Write-Warning`.

No statically named function caller in this inventory. Top-level, dynamic and callback invocation remain possible.

### Write-AutopilotExpressLog

Write a timestamped safe message to the information stream and console.

Source: [autopilot-express.ps1:359](autopilot-express.ps1#L359). Internal entry-script function; source region: `Runtime Defaults and Record Shapes`.

| Parameter | Declared Type   | Attributes                                                   | Default                        | Source Contract                                                                |
| --------- | --------------- | ------------------------------------------------------------ | ------------------------------ | ------------------------------------------------------------------------------ |
| `Message` | `System.String` | `[Parameter(Mandatory)]` `[string]`                          | No explicit default expression | Safe diagnostic text; callers must not supply credentials or raw SDK payloads. |
| `Level`   | `System.String` | `[ValidateSet('INFO', 'WARN', 'ERROR', 'DEBUG')]` `[string]` | `'INFO'`                       | INFO, WARN, ERROR or DEBUG severity included as text, not colour alone.        |

Outputs and result contract:

Information-stream output captured by the owned diagnostic transcript.

Other named commands: `Get-Date`, `Write-Information`.

Named callers: [Initialize-StorageLocation](#initialize-storagelocation), [Move-RecoveryEvidenceToOrganisedLayout](#move-recoveryevidencetoorganisedlayout), [Copy-StateFileIfNeeded](#copy-statefileifneeded), [Invoke-WorkflowEvidenceMigration](#invoke-workflowevidencemigration), [Initialize-LocalSessionForResume](#initialize-localsessionforresume), [Get-MasterAuditProposal](#get-masterauditproposal), [Get-UserDeviceRecords](#get-userdevicerecords), [Write-UserDeviceRecords](#write-userdevicerecords), [Start-NewDeviceWorkflow](#start-newdeviceworkflow), [Invoke-AutopilotSequence](#invoke-autopilotsequence), [Update-DeviceStatus](#update-devicestatus), [Show-SessionReportExport](#show-sessionreportexport), [Save-BuildBenchState](#save-buildbenchstate), [Get-BuildBenchState](#get-buildbenchstate), [Show-SessionArchive](#show-sessionarchive), [Initialize-SessionState](#initialize-sessionstate), [Initialize-AutopilotExpressDefinitions](#initialize-autopilotexpressdefinitions), [Request-GraphModuleScriptTrust](#request-graphmodulescripttrust), [Install-RequiredGraphModules](#install-requiredgraphmodules), [Import-RequiredGraphModules](#import-requiredgraphmodules), [Invoke-GraphApiRequest](#invoke-graphapirequest), [Invoke-GraphReadPrefetch](#invoke-graphreadprefetch), [Invoke-DeviceRemediation](#invoke-deviceremediation), [Initialize-LiveTenantContext](#initialize-livetenantcontext), [Initialize-GraphSession](#initialize-graphsession), [Resolve-LiveDirectoryUserRecord](#resolve-livedirectoryuserrecord), [Get-RecentUsers](#get-recentusers), [Invoke-DeviceInventoryCheck](#invoke-deviceinventorycheck), [Update-DeviceInventoryFromIntune](#update-deviceinventoryfromintune), [Show-DeviceInventoryBackfill](#show-deviceinventorybackfill), [Import-LegacySyncSubmissionEvidence](#import-legacysyncsubmissionevidence), [Import-LegacyAutopilotImportEvidence](#import-legacyautopilotimportevidence), [Invoke-StepRetryFailedApps](#invoke-stepretryfailedapps), [New-BuildBench](#new-buildbench), [Enter-DeviceRecoveryMode](#enter-devicerecoverymode), [Invoke-DeviceDocumentHousekeeping](#invoke-devicedocumenthousekeeping), [Request-DeviceDocumentReadiness](#request-devicedocumentreadiness), [Read-DeviceDocumentFailure](#read-devicedocumentfailure), [Read-DeviceDocumentHistory](#read-devicedocumenthistory), [Save-DeviceDocumentFailure](#save-devicedocumentfailure), [Receive-DeviceDocumentJob](#receive-devicedocumentjob), [Request-DeviceDocumentReprint](#request-devicedocumentreprint), [Show-DeviceDocumentSettings](#show-devicedocumentsettings).

### New-EmptyDeviceRecord

Create the initialised version-two workflow record shape.

Source: [autopilot-express.ps1:463](autopilot-express.ps1#L463). Internal entry-script function; source region: `Runtime Defaults and Record Shapes`.

No formal parameters declared. Captured state and enclosing scope may still be inputs.

Outputs and result contract:

Ordered dictionary of identity, state and evidence defaults; no storage or tenant access.

Named callers: [New-DeviceRecordObject](#new-devicerecordobject), [Get-UserDeviceRecords](#get-userdevicerecords), [Invoke-ExistingDeviceLifecycle](#invoke-existingdevicelifecycle).

### Get-DefaultBuildBenchState

Create an inactive bench with empty positions and faults.

Source: [autopilot-express.ps1:514](autopilot-express.ps1#L514). Internal entry-script function; source region: `Runtime Defaults and Record Shapes`.

No formal parameters declared. Captured state and enclosing scope may still be inputs.

Outputs and result contract:

Ordered dictionary; each call creates independent mutable state.

Named callers: [Reset-CurrentSessionState](#reset-currentsessionstate), [Get-BuildBenchState](#get-buildbenchstate), [Initialize-SessionState](#initialize-sessionstate).

### ConvertTo-NormalisedValue

Recursively detach JSON objects into dictionaries without collapsing arrays.

Source: [autopilot-express.ps1:524](autopilot-express.ps1#L524). Internal entry-script function; source region: `Runtime Defaults and Record Shapes`.

| Parameter | Declared Type   | Attributes    | Default                        | Source Contract                                                            |
| --------- | --------------- | ------------- | ------------------------------ | -------------------------------------------------------------------------- |
| `Value`   | `System.Object` | None declared | No explicit default expression | Scalar, dictionary, object or collection; dates become round-trip strings. |

Outputs and result contract:

Normalised value, preserving null and empty/singleton arrays. Does not edit the input.

Other named commands: `Get-Date`.

Named callers: [ConvertTo-NormalisedValue](#convertto-normalisedvalue), [ConvertTo-StepHashtable](#convertto-stephashtable), [Get-SharedStoreSnapshot](#get-sharedstoresnapshot), [Get-SharedStoreRecoveryInspection](#get-sharedstorerecoveryinspection), [Get-SharedStoreMigrationPreview](#get-sharedstoremigrationpreview), [Write-SharedStoreSnapshot](#write-sharedstoresnapshot), [Get-SessionFileIndex](#get-sessionfileindex), [ConvertTo-CanonicalWorkflowRecord](#convertto-canonicalworkflowrecord), [Invoke-WorkflowEvidenceMigration](#invoke-workflowevidencemigration), [Initialize-LocalSessionForResume](#initialize-localsessionforresume), [ConvertTo-PersistedDeviceRecord](#convertto-persisteddevicerecord), [Get-MasterAuditProposal](#get-masterauditproposal), [Get-UserDeviceRecords](#get-userdevicerecords), [Invoke-ExistingDeviceLifecycle](#invoke-existingdevicelifecycle), [Read-ImagingWorkPattern](#read-imagingworkpattern), [Read-JsonDefinitionFile](#read-jsondefinitionfile), [Get-DeviceActionState](#get-deviceactionstate), [Invoke-DeviceInventoryCheck](#invoke-deviceinventorycheck), [Invoke-DeviceInventoryPolling](#invoke-deviceinventorypolling), [Update-DeviceInventoryFromIntune](#update-deviceinventoryfromintune), [Import-LegacyAutopilotImportEvidence](#import-legacyautopilotimportevidence), [Invoke-AutopilotManifestStep](#invoke-autopilotmanifeststep), [Write-ManifestStepResult](#write-manifeststepresult), [Add-ManifestAttemptSnapshot](#add-manifestattemptsnapshot), [Enter-DeviceRecoveryMode](#enter-devicerecoverymode), [Undo-LatestTechnicianConfirmation](#undo-latesttechnicianconfirmation), [Initialize-DeviceDocumentSession](#initialize-devicedocumentsession), [Read-DeviceDocumentFailure](#read-devicedocumentfailure), [Read-DeviceDocumentHistory](#read-devicedocumenthistory), [Save-DeviceDocumentFailure](#save-devicedocumentfailure), [Request-DeviceDocumentReprint](#request-devicedocumentreprint), [Complete-DeviceDispatch](#complete-devicedispatch).

### ConvertTo-StepHashtable

Validate persisted step evidence and migrate typed legacy Boolean flags.

Source: [autopilot-express.ps1:568](autopilot-express.ps1#L568). Internal entry-script function; source region: `Runtime Defaults and Record Shapes`.

| Parameter | Declared Type   | Attributes    | Default                        | Source Contract                                                     |
| --------- | --------------- | ------------- | ------------------------------ | ------------------------------------------------------------------- |
| `Value`   | `System.Object` | None declared | No explicit default expression | Step dictionary, or null when a legacy record has no step evidence. |

Outputs and result contract:

Normalised validated dictionary; damaged evidence raises an error.

Other named commands: `Get-Date`.

Named callers: [Assert-AttemptHistory](#assert-attempthistory), [Get-UserDeviceRecords](#get-userdevicerecords).

### New-DeviceRecordObject

Initialise one inducted device with its identity and workflow defaults.

Source: [autopilot-express.ps1:611](autopilot-express.ps1#L611). Internal entry-script function; source region: `Runtime Defaults and Record Shapes`.

| Parameter       | Declared Type   | Attributes                          | Default                        | Source Contract                                                   |
| --------------- | --------------- | ----------------------------------- | ------------------------------ | ----------------------------------------------------------------- |
| `Serial`        | `System.String` | `[Parameter(Mandatory)]` `[string]` | No explicit default expression | Device serial supplied by the validated induction flow.           |
| `ConfigItem`    | `System.String` | `[Parameter(Mandatory)]` `[string]` | No explicit default expression | Configuration item identity supplied by the technician.           |
| `SiteCode`      | `System.String` | `[string]`                          | No explicit default expression | Selected configured site.                                         |
| `DeviceType`    | `System.String` | `[string]`                          | No explicit default expression | Selected configured hardware category.                            |
| `EntraDeviceId` | `System.String` | `[string]`                          | No explicit default expression | Optional known Entra identity; not proof of current tenant state. |
| `GroupTag`      | `System.String` | `[string]`                          | No explicit default expression | Optional initial tag; not evidence of a verified Graph write.     |

Outputs and result contract:

New dictionary record. The caller validates uniqueness and persists it separately.

Other named commands: `Get-Date`.

Named callers: [Start-NewDeviceWorkflow](#start-newdeviceworkflow), [Add-DeviceToBenchPosition](#add-devicetobenchposition), [Sync-BenchRecords](#sync-benchrecords), [Show-BuildBenchView](#show-buildbenchview).

### Assert-DeviceRecordIdentity

Reject ambiguous local workflow identities without changing existing history.

Source: [autopilot-express.ps1:675](autopilot-express.ps1#L675). Internal entry-script function; source region: `Runtime Defaults and Record Shapes`.

| Parameter | Declared Type                    | Attributes                                                    | Default | Source Contract                                             |
| --------- | -------------------------------- | ------------------------------------------------------------- | ------- | ----------------------------------------------------------- |
| `Records` | `System.Collections.IEnumerable` | `[AllowEmptyCollection()]` `[System.Collections.IEnumerable]` | `@()`   | Workflow records to validate; an empty collection is valid. |

Outputs and result contract:

None. Throws on conflicting identities without changing either record.

Named callers: [Add-DeviceRecord](#add-devicerecord), [Assert-SharedStoreSnapshot](#assert-sharedstoresnapshot), [Get-UserDeviceRecords](#get-userdevicerecords), [Invoke-ExistingDeviceLifecycle](#invoke-existingdevicelifecycle), [Start-NewDeviceWorkflow](#start-newdeviceworkflow), [Assert-BenchPositionIdentity](#assert-benchpositionidentity), [Sync-BenchRecords](#sync-benchrecords).

### Add-DeviceRecord

Validate identity uniqueness before appending to the caller's record container.

Source: [autopilot-express.ps1:720](autopilot-express.ps1#L720). Internal entry-script function; source region: `Runtime Defaults and Record Shapes`.

| Parameter | Declared Type                  | Attributes                             | Default                        | Source Contract                                                   |
| --------- | ------------------------------ | -------------------------------------- | ------------------------------ | ----------------------------------------------------------------- |
| `Records` | `System.Collections.Hashtable` | `[Parameter(Mandatory)]` `[hashtable]` | No explicit default expression | Mutable container whose Value holds the current record array.     |
| `Record`  | `System.Object`                | `[Parameter(Mandatory)]`               | No explicit default expression | Proposed device dictionary, checked against the existing records. |

Outputs and result contract:

None. Mutates Records.Value only; persistence remains the caller's responsibility.

Named callers: [Start-NewDeviceWorkflow](#start-newdeviceworkflow), [Add-DeviceToBenchPosition](#add-devicetobenchposition), [Sync-BenchRecords](#sync-benchrecords), [Show-BuildBenchView](#show-buildbenchview).

### Get-RepoStorageBasePath

Resolve the bootstrap-authorised repository storage base.

Source: [autopilot-express.ps1:743](autopilot-express.ps1#L743). Internal entry-script function; source region: `Storage Authority and Persisted Evidence`.

No formal parameters declared. Captured state and enclosing scope may still be inputs.

Outputs and result contract:

Root path from resolved script state or its environment fallback; no directory creation.

Named callers: [Initialize-StorageLocation](#initialize-storagelocation), [Sync-RepoStateFilesToActiveStorage](#sync-repostatefilestoactivestorage).

### Get-FallbackStorageBasePath

Locate the per-user LOCALAPPDATA fallback storage base.

Source: [autopilot-express.ps1:756](autopilot-express.ps1#L756). Internal entry-script function; source region: `Storage Authority and Persisted Evidence`.

No formal parameters declared. Captured state and enclosing scope may still be inputs.

Outputs and result contract:

Absolute Autopilot Express fallback path; does not choose storage authority.

Other named commands: `Join-Path`.

Named callers: [Initialize-StorageLocation](#initialize-storagelocation).

### Test-DirectoryWritable

Probe directory access with a disposable file rather than assuming writability.

Source: [autopilot-express.ps1:766](autopilot-express.ps1#L766). Internal entry-script function; source region: `Storage Authority and Persisted Evidence`.

| Parameter | Declared Type   | Attributes                          | Default                        | Source Contract                                                          |
| --------- | --------------- | ----------------------------------- | ------------------------------ | ------------------------------------------------------------------------ |
| `Path`    | `System.String` | `[Parameter(Mandatory)]` `[string]` | No explicit default expression | Candidate storage directory; no operational record is used as the probe. |

Outputs and result contract:

Boolean access result. Creates/removes the probe; failures return false.

Other named commands: `Join-Path`, `New-Item`, `Out-Null`, `Remove-Item`, `Set-Content`, `Test-Path`.

Named callers: [Initialize-StorageLocation](#initialize-storagelocation).

### Assert-StorageModeSupported

Reject unsupported storage modes before any operational store access.

Source: [autopilot-express.ps1:793](autopilot-express.ps1#L793). Internal entry-script function; source region: `Storage Authority and Persisted Evidence`.

No formal parameters declared. Captured state and enclosing scope may still be inputs.

Outputs and result contract:

None. Throws for unsupported storage modes, including deferred Shared operation.

Named callers: [Initialize-StorageLocation](#initialize-storagelocation).

### Get-OperationalStoragePath

Resolve current-mode state paths without creating or selecting a root.

Source: [autopilot-express.ps1:819](autopilot-express.ps1#L819). Internal entry-script function; source region: `Storage Authority and Persisted Evidence`.

| Parameter  | Declared Type   | Attributes                                                       | Default                        | Source Contract                                   |
| ---------- | --------------- | ---------------------------------------------------------------- | ------------------------------ | ------------------------------------------------- |
| `BasePath` | `System.String` | `[Parameter(Mandatory)]` `[ValidateNotNullOrEmpty()]` `[string]` | No explicit default expression | Repository or fallback base directory to inspect. |

Outputs and result contract:

Device, bench and recent-user paths, plus common Live audit and receipt
paths. Receipt recovery artefacts resolve to their canonical target paths.

Other named commands: `ForEach-Object`, `Get-ChildItem`, `Join-Path`, `Sort-Object`, `Test-Path`.

Named callers: [Initialize-StorageLocation](#initialize-storagelocation), [Sync-RepoStateFilesToActiveStorage](#sync-repostatefilestoactivestorage).

### Get-FallbackStorageAuthorityPath

Locate durable fallback authority for this user and operational mode.

Source: [autopilot-express.ps1:857](autopilot-express.ps1#L857). Internal entry-script function; source region: `Storage Authority and Persisted Evidence`.

| Parameter  | Declared Type   | Attributes                                                       | Default                        | Source Contract                                        |
| ---------- | --------------- | ---------------------------------------------------------------- | ------------------------------ | ------------------------------------------------------ |
| `BasePath` | `System.String` | `[Parameter(Mandatory)]` `[ValidateNotNullOrEmpty()]` `[string]` | No explicit default expression | Fallback base directory; this helper never creates it. |

Outputs and result contract:

Marker path, separate from operational user files and session locks.

Other named commands: `Join-Path`.

Named callers: [Test-FallbackStorageAuthority](#test-fallbackstorageauthority), [Sync-RepoStateFilesToActiveStorage](#sync-repostatefilestoactivestorage).

### Test-FallbackStorageAuthority

Validate completed migration authority without using file timestamps.

Source: [autopilot-express.ps1:871](autopilot-express.ps1#L871). Internal entry-script function; source region: `Storage Authority and Persisted Evidence`.

| Parameter  | Declared Type   | Attributes                                                       | Default                        | Source Contract                                        |
| ---------- | --------------- | ---------------------------------------------------------------- | ------------------------------ | ------------------------------------------------------ |
| `BasePath` | `System.String` | `[Parameter(Mandatory)]` `[ValidateNotNullOrEmpty()]` `[string]` | No explicit default expression | Fallback base directory whose marker is being checked. |

Outputs and result contract:

True only for the exact completed-migration marker.

Other named commands: `Get-Content`, `Join-Path`, `Test-Path`.

Named callers: [Initialize-StorageLocation](#initialize-storagelocation), [Sync-RepoStateFilesToActiveStorage](#sync-repostatefilestoactivestorage).

### Assert-ActiveStorageReservation

Require the current invocation's current-root lock before migration writes.

Source: [autopilot-express.ps1:898](autopilot-express.ps1#L898). Internal entry-script function; source region: `Storage Authority and Persisted Evidence`.

No formal parameters declared. Captured state and enclosing scope may still be inputs.

Outputs and result contract:

None. Throws unless the active process still owns the exact reservation.

Other named commands: `ConvertFrom-Json`, `Get-Content`, `Get-Variable`, `Join-Path`.

Named callers: [Sync-RepoStateFilesToActiveStorage](#sync-repostatefilestoactivestorage), [Save-ImagingWorkPatternChange](#save-imagingworkpatternchange), [Import-LegacySyncSubmissionEvidence](#import-legacysyncsubmissionevidence), [Import-LegacyAutopilotImportEvidence](#import-legacyautopilotimportevidence), [Invoke-StepRetryFailedApps](#invoke-stepretryfailedapps).

### Initialize-StorageLocation

Select one stable authoritative local root before reserving the session.

Source: [autopilot-express.ps1:922](autopilot-express.ps1#L922). Internal entry-script function; source region: `Storage Authority and Persisted Evidence`.

No formal parameters declared. Captured state and enclosing scope may still be inputs.

Outputs and result contract:

None. Selects validated storage authority; ambiguous or unrecovered evidence blocks startup.

Other named commands: `Join-Path`, `Test-Path`.

Named callers: [Get-StorageBasePath](#get-storagebasepath).

### Start-SharedStoreReservation

Reserve an existing filesystem root for offline snapshot development.

Source: [autopilot-express.ps1:977](autopilot-express.ps1#L977). Internal entry-script function; source region: `Storage Authority and Persisted Evidence`.

| Parameter | Declared Type   | Attributes                                                       | Default                        | Source Contract                                                       |
| --------- | --------------- | ---------------------------------------------------------------- | ------------------------------ | --------------------------------------------------------------------- |
| `Root`    | `System.String` | `[Parameter(Mandatory)]` `[ValidateNotNullOrEmpty()]` `[string]` | No explicit default expression | Existing isolated development directory; never created automatically. |

Outputs and result contract:

Reservation path and unique ownership token for snapshot helpers.

Other named commands: `ConvertTo-Json`, `Get-Date`, `Get-Item`, `Join-Path`, `New-Item`, `Out-Null`.

No statically named function caller in this inventory. Top-level, dynamic and callback invocation remain possible.

### Assert-SharedStoreReservation

Check that snapshot access owns this root's reservation.

Source: [autopilot-express.ps1:1002](autopilot-express.ps1#L1002). Internal entry-script function; source region: `Storage Authority and Persisted Evidence`.

| Parameter | Declared Type                  | Attributes                                                          | Default                        | Source Contract                                                        |
| --------- | ------------------------------ | ------------------------------------------------------------------- | ------------------------------ | ---------------------------------------------------------------------- |
| `Root`    | `System.String`                | `[Parameter(Mandatory)]` `[ValidateNotNullOrEmpty()]` `[string]`    | No explicit default expression | Existing filesystem directory containing the snapshot and reservation. |
| `Lock`    | `System.Collections.Hashtable` | `[Parameter(Mandatory)]` `[ValidateNotNullOrEmpty()]` `[hashtable]` | No explicit default expression | Ownership token and path returned by Start-SharedStoreReservation.     |

Outputs and result contract:

None. Retained safety guard; does not enable deferred Shared operation.

Other named commands: `ConvertFrom-Json`, `Get-Content`, `Get-Item`, `Join-Path`.

Named callers: [Get-SharedStoreSnapshot](#get-sharedstoresnapshot), [Get-SharedStoreRecoveryInspection](#get-sharedstorerecoveryinspection), [Get-SharedStoreMigrationPreview](#get-sharedstoremigrationpreview), [Write-SharedStoreSnapshot](#write-sharedstoresnapshot).

### Assert-SharedStoreSnapshot

Validate the offline snapshot envelope and cross-record bench identities.

Source: [autopilot-express.ps1:1025](autopilot-express.ps1#L1025). Internal entry-script function; source region: `Storage Authority and Persisted Evidence`.

| Parameter  | Declared Type                    | Attributes                                                                                                   | Default                        | Source Contract                                                              |
| ---------- | -------------------------------- | ------------------------------------------------------------------------------------------------------------ | ------------------------------ | ---------------------------------------------------------------------------- |
| `Snapshot` | `System.Collections.IDictionary` | `[Parameter(Mandatory)]` `[AllowEmptyCollection()]` `[ValidateNotNull()]` `[System.Collections.IDictionary]` | No explicit default expression | Normalised dictionary containing schema, revision, devices, bench and audit. |

Outputs and result contract:

None. Rejects changed shared snapshots rather than overwriting concurrent evidence.

Other named commands: `Where-Object`.

Named callers: [Get-SharedStoreSnapshot](#get-sharedstoresnapshot), [Get-SharedStoreRecoveryInspection](#get-sharedstorerecoveryinspection), [Get-SharedStoreMigrationPreview](#get-sharedstoremigrationpreview), [Write-SharedStoreSnapshot](#write-sharedstoresnapshot).

### Get-SharedStoreSnapshot

Read one complete offline snapshot under the caller's reservation.

Source: [autopilot-express.ps1:1071](autopilot-express.ps1#L1071). Internal entry-script function; source region: `Storage Authority and Persisted Evidence`.

| Parameter | Declared Type                  | Attributes                                                          | Default                        | Source Contract                                                        |
| --------- | ------------------------------ | ------------------------------------------------------------------- | ------------------------------ | ---------------------------------------------------------------------- |
| `Root`    | `System.String`                | `[Parameter(Mandatory)]` `[ValidateNotNullOrEmpty()]` `[string]`    | No explicit default expression | Isolated snapshot directory, not selected by runtime storage settings. |
| `Lock`    | `System.Collections.Hashtable` | `[Parameter(Mandatory)]` `[ValidateNotNullOrEmpty()]` `[hashtable]` | No explicit default expression | Reservation owned by the caller.                                       |

Outputs and result contract:

Normalised snapshot dictionary; arrays remain arrays on both hosts.

Other named commands: `ConvertFrom-Json`, `Get-Content`, `Join-Path`, `Test-Path`.

Named callers: [Get-SharedStoreMigrationPreview](#get-sharedstoremigrationpreview), [Write-SharedStoreSnapshot](#write-sharedstoresnapshot).

### Get-SharedStoreRecoveryInspection

Inspect retained snapshot copies without repairing or approving recovery.

Source: [autopilot-express.ps1:1103](autopilot-express.ps1#L1103). Internal entry-script function; source region: `Storage Authority and Persisted Evidence`.

| Parameter | Declared Type                  | Attributes                                                          | Default                        | Source Contract                                                           |
| --------- | ------------------------------ | ------------------------------------------------------------------- | ------------------------------ | ------------------------------------------------------------------------- |
| `Root`    | `System.String`                | `[Parameter(Mandatory)]` `[ValidateNotNullOrEmpty()]` `[string]`    | No explicit default expression | Isolated development root containing the snapshot and recovery artefacts. |
| `Lock`    | `System.Collections.Hashtable` | `[Parameter(Mandatory)]` `[ValidateNotNullOrEmpty()]` `[hashtable]` | No explicit default expression | Current reservation owned by the caller.                                  |

Outputs and result contract:

Read-only evidence report with copy summaries and validated snapshots.

Other named commands: `ConvertFrom-Json`, `Get-Content`, `Join-Path`, `Test-Path`, `Where-Object`.

No statically named function caller in this inventory. Top-level, dynamic and callback invocation remain possible.

### Get-SharedStoreMigrationPreview

Preview an initial snapshot import without changing either store.

Source: [autopilot-express.ps1:1156](autopilot-express.ps1#L1156). Internal entry-script function; source region: `Storage Authority and Persisted Evidence`.

| Parameter        | Declared Type                    | Attributes                                                                               | Default                        | Source Contract                                                                                                                                   |
| ---------------- | -------------------------------- | ---------------------------------------------------------------------------------------- | ------------------------------ | ------------------------------------------------------------------------------------------------------------------------------------------------- |
| `Root`           | `System.String`                  | `[Parameter(Mandatory)]` `[ValidateNotNullOrEmpty()]` `[string]`                         | No explicit default expression | Isolated development destination, not the configured runtime store.                                                                               |
| `Lock`           | `System.Collections.Hashtable`   | `[Parameter(Mandatory)]` `[ValidateNotNullOrEmpty()]` `[hashtable]`                      | No explicit default expression | Destination reservation owned by the caller throughout the preview.                                                                               |
| `SourceSnapshot` | `System.Collections.IDictionary` | `[Parameter(Mandatory)]` `[ValidateNotNullOrEmpty()]` `[System.Collections.IDictionary]` | No explicit default expression | Captured, normalised snapshot envelope for operator review. All record, history, bench and audit evidence is copied without rewriting identities. |

Outputs and result contract:

Detached proposal and counts; MigrationApproved is always false.

No statically named function caller in this inventory. Top-level, dynamic and callback invocation remain possible.

### Write-SharedStoreSnapshot

Save devices, bench and append-only audit together with a revision check.

Source: [autopilot-express.ps1:1197](autopilot-express.ps1#L1197). Internal entry-script function; source region: `Storage Authority and Persisted Evidence`.

| Parameter          | Declared Type                    | Attributes                                                                               | Default                        | Source Contract                                                            |
| ------------------ | -------------------------------- | ---------------------------------------------------------------------------------------- | ------------------------------ | -------------------------------------------------------------------------- |
| `Root`             | `System.String`                  | `[Parameter(Mandatory)]` `[ValidateNotNullOrEmpty()]` `[string]`                         | No explicit default expression | Isolated snapshot directory.                                               |
| `Lock`             | `System.Collections.Hashtable`   | `[Parameter(Mandatory)]` `[ValidateNotNullOrEmpty()]` `[hashtable]`                      | No explicit default expression | Reservation owned by the caller.                                           |
| `ExpectedRevision` | `System.Int32`                   | `[Parameter(Mandatory)]` `[ValidateRange(0, 2147483645)]` `[int]`                        | No explicit default expression | Revision read before the edit; stale callers are rejected without writing. |
| `Snapshot`         | `System.Collections.IDictionary` | `[Parameter(Mandatory)]` `[ValidateNotNullOrEmpty()]` `[System.Collections.IDictionary]` | No explicit default expression | Complete proposed envelope; caller revision must equal ExpectedRevision.   |

Outputs and result contract:

Committed revision, returned only after save verification succeeds.

Other named commands: `ConvertTo-Json`, `Get-Date`, `Join-Path`, `Where-Object`.

No statically named function caller in this inventory. Top-level, dynamic and callback invocation remain possible.

### Get-StorageBasePath

Return the initialised authoritative storage base.

Source: [autopilot-express.ps1:1247](autopilot-express.ps1#L1247). Internal entry-script function; source region: `Storage Authority and Persisted Evidence`.

No formal parameters declared. Captured state and enclosing scope may still be inputs.

Outputs and result contract:

Selected base path after storage initialisation; not an arbitrary newest-file selection.

Named callers: [Get-DataFolderPath](#get-datafolderpath), [Sync-RepoStateFilesToActiveStorage](#sync-repostatefilestoactivestorage).

### Get-DataFolderPath

Resolve and prepare the data directory under a selected base.

Source: [autopilot-express.ps1:1258](autopilot-express.ps1#L1258). Internal entry-script function; source region: `Storage Authority and Persisted Evidence`.

| Parameter  | Declared Type   | Attributes | Default                        | Source Contract                                                                        |
| ---------- | --------------- | ---------- | ------------------------------ | -------------------------------------------------------------------------------------- |
| `BasePath` | `System.String` | `[string]` | No explicit default expression | Optional explicit base for guarded storage preflight; otherwise use current authority. |

Outputs and result contract:

Data directory path. Directory preparation may throw on access failure.

Other named commands: `Join-Path`, `New-Item`, `Out-Null`, `Test-Path`.

Named callers: [Get-ArchiveFolderPath](#get-archivefolderpath), [Start-LocalSessionLock](#start-localsessionlock), [Request-LocalSessionLock](#request-localsessionlock), [Assert-LocalStorageWriteState](#assert-localstoragewritestate), [Initialize-SessionFileIndex](#initialize-sessionfileindex), [Get-UserDataFilePath](#get-userdatafilepath), [Get-BuildBenchStatePath](#get-buildbenchstatepath), [Get-RecentUsersFilePath](#get-recentusersfilepath), [Get-MasterAuditFilePath](#get-masterauditfilepath), [Reset-CurrentSessionState](#reset-currentsessionstate), [Get-LocalCheckpointPath](#get-localcheckpointpath), [Get-LocalCheckpointInspection](#get-localcheckpointinspection), [Write-UserDeviceRecords](#write-userdevicerecords), [Get-ImagingWorkPatternPath](#get-imagingworkpatternpath).

### Get-ArchiveFolderPath

Resolve and prepare the archive directory outside active record discovery.

Source: [autopilot-express.ps1:1277](autopilot-express.ps1#L1277). Internal entry-script function; source region: `Storage Authority and Persisted Evidence`.

| Parameter  | Declared Type   | Attributes | Default                        | Source Contract                                                  |
| ---------- | --------------- | ---------- | ------------------------------ | ---------------------------------------------------------------- |
| `BasePath` | `System.String` | `[string]` | No explicit default expression | Optional explicit storage base; otherwise use current authority. |

Outputs and result contract:

Archive directory path; does not move or remove any evidence.

Other named commands: `Join-Path`, `New-Item`, `Out-Null`, `Test-Path`.

Named callers: [Move-SessionFileToArchive](#move-sessionfiletoarchive), [Get-ArchivedDeviceRecordFile](#get-archiveddevicerecordfile).

### Start-LocalSessionLock

Exclusively reserve the resolved local store before session access.

Source: [autopilot-express.ps1:1295](autopilot-express.ps1#L1295). Internal entry-script function; source region: `Storage Authority and Persisted Evidence`.

No formal parameters declared. Captured state and enclosing scope may still be inputs.

Outputs and result contract:

Hashtable containing the metadata path, token and owned disposable handle.

Other named commands: `ConvertTo-Json`, `Get-Date`, `Join-Path`, `New-Item`, `Out-Null`, `Test-Path`.

Named callers: [Request-LocalSessionLock](#request-localsessionlock).

### Request-LocalSessionLock

Acquire a reservation or keep the technician in guarded startup recovery.

Source: [autopilot-express.ps1:1330](autopilot-express.ps1#L1330). Internal entry-script function; source region: `Storage Authority and Persisted Evidence`.

No formal parameters declared. Captured state and enclosing scope may still be inputs.

Outputs and result contract:

Owned lock dictionary, or null when the technician returns without starting.

Other named commands: `Join-Path`, `Test-Path`, `Write-Host`.

No statically named function caller in this inventory. Top-level, dynamic and callback invocation remain possible.

### Get-LocalSessionRecoveryInventory

Hash every saved file and recovery artefact without following reparse points.

Source: [autopilot-express.ps1:1391](autopilot-express.ps1#L1391). Internal entry-script function; source region: `Storage Authority and Persisted Evidence`.

| Parameter  | Declared Type   | Attributes                                                       | Default                        | Source Contract                                                                  |
| ---------- | --------------- | ---------------------------------------------------------------- | ------------------------------ | -------------------------------------------------------------------------------- |
| `DataPath` | `System.String` | `[Parameter(Mandatory)]` `[ValidateNotNullOrEmpty()]` `[string]` | No explicit default expression | Exact authoritative data directory; only the two OS lease sidecars are excluded. |

Outputs and result contract:

File inventory with relative names, sizes, source paths and SHA-256 hashes.

Other named commands: `Get-ChildItem`, `Get-FileHash`.

Named callers: [New-LocalSessionRecoverySnapshot](#new-localsessionrecoverysnapshot), [Invoke-LocalSessionLockRecovery](#invoke-localsessionlockrecovery).

### Get-RecoveryEvidenceTenantKey

Name the tenant folder used to organise retained recovery evidence (BACKUP-POLICY).

Source: [autopilot-express.ps1:1416](autopilot-express.ps1#L1416). Internal entry-script function; source region: `Storage Authority and Persisted Evidence`.

| Parameter | Declared Type   | Attributes                                                       | Default                        | Source Contract                                                  |
| --------- | --------------- | ---------------------------------------------------------------- | ------------------------------ | ---------------------------------------------------------------- |
| `Folder`  | `System.String` | `[Parameter(Mandatory)]` `[ValidateNotNullOrEmpty()]` `[string]` | No explicit default expression | Session data folder, or the files folder of a retained snapshot. |
| `Mode`    | `System.String` | `[ValidateSet('Live', 'Demo', 'Unknown')]` `[string]`            | `'Unknown'`                    | Live, Demo or Unknown. Demo evidence always files under 'demo'.  |

Outputs and result contract:

Lower-case tenant GUID, or 'demo', 'tenant-mixed', 'tenant-unbound' or 'tenant-unknown'.
Never throws; any read failure files the evidence under 'tenant-unknown'.

Other named commands: `Get-ChildItem`, `Where-Object`.

Named callers: [Move-RecoveryEvidenceToOrganisedLayout](#move-recoveryevidencetoorganisedlayout), [New-LocalSessionRecoverySnapshot](#new-localsessionrecoverysnapshot).

### Get-RecoveryEvidenceFolder

Resolve the organised date and tenant folder for one kind of recovery evidence.

Source: [autopilot-express.ps1:1461](autopilot-express.ps1#L1461). Internal entry-script function; source region: `Storage Authority and Persisted Evidence`.

| Parameter   | Declared Type     | Attributes                                                   | Default                        | Source Contract                                             |
| ----------- | ----------------- | ------------------------------------------------------------ | ------------------------------ | ----------------------------------------------------------- |
| `Kind`      | `System.String`   | `[ValidateSet('SessionSnapshots', 'CrashLocks')]` `[string]` | No explicit default expression | SessionSnapshots or CrashLocks; omit for the evidence root. |
| `TenantKey` | `System.String`   | `[string]`                                                   | `'tenant-unknown'`             | Value from Get-RecoveryEvidenceTenantKey.                   |
| `Timestamp` | `System.DateTime` | `[datetime]`                                                 | `(Get-Date)`                   | Evidence creation time used for the date folder.            |

Outputs and result contract:

Full folder path as text.

Other named commands: `Get-Date`, `Join-Path`.

Named callers: [Get-RecoveryEvidenceInventory](#get-recoveryevidenceinventory), [Move-RecoveryEvidenceToOrganisedLayout](#move-recoveryevidencetoorganisedlayout), [New-LocalSessionRecoverySnapshot](#new-localsessionrecoverysnapshot), [Invoke-LocalSessionLockRecovery](#invoke-localsessionlockrecovery), [Show-RecoveryEvidenceReport](#show-recoveryevidencereport).

### Get-RecoveryEvidenceInventory

List every retained recovery backup with its kind, layout, date, tenant and size.

Source: [autopilot-express.ps1:1490](autopilot-express.ps1#L1490). Internal entry-script function; source region: `Storage Authority and Persisted Evidence`.

No formal parameters declared. Captured state and enclosing scope may still be inputs.

Outputs and result contract:

PSCustomObjects: Kind, Layout (Organised, Legacy or Other), Date, Tenant, Path, Bytes, Files.

Other named commands: `Get-ChildItem`, `Measure-Object`, `Test-Path`.

Named callers: [Move-RecoveryEvidenceToOrganisedLayout](#move-recoveryevidencetoorganisedlayout), [Show-RecoveryEvidenceReport](#show-recoveryevidencereport).

### Move-RecoveryEvidenceToOrganisedLayout

Move older flat session snapshots and crash-lock evidence into date and tenant folders.

Source: [autopilot-express.ps1:1538](autopilot-express.ps1#L1538). Internal entry-script function; source region: `Storage Authority and Persisted Evidence`.

No formal parameters declared. Captured state and enclosing scope may still be inputs.

Outputs and result contract:

Hashtable: Moved, Skipped and Lines (one readable outcome per item, also logged).

Other named commands: `Get-Item`, `Join-Path`, `Move-Item`, `New-Item`, `Out-Null`, `Test-Path`, `Where-Object`.

Named callers: [Show-RecoveryEvidenceReport](#show-recoveryevidencereport).

### New-LocalSessionRecoverySnapshot

Retain and verify the complete saved store outside active discovery before recovery.

Source: [autopilot-express.ps1:1583](autopilot-express.ps1#L1583). Internal entry-script function; source region: `Storage Authority and Persisted Evidence`.

| Parameter  | Declared Type   | Attributes                                                       | Default                        | Source Contract                                                                    |
| ---------- | --------------- | ---------------------------------------------------------------- | ------------------------------ | ---------------------------------------------------------------------------------- |
| `DataPath` | `System.String` | `[Parameter(Mandatory)]` `[ValidateNotNullOrEmpty()]` `[string]` | No explicit default expression | Authoritative directory containing device, bench, audit, index and recovery files. |
| `Mode`     | `System.String` | `[ValidateSet('Live', 'Demo', 'Unknown')]` `[string]`            | `'Unknown'`                    | Live, Demo or Unknown; selects the tenant folder used by the BACKUP-POLICY layout. |

Outputs and result contract:

Verified backup path, tenant folder key and original inventory; failures retain the
reservation and partial backup.

Other named commands: `Compare-Object`, `ConvertTo-Json`, `Copy-Item`, `Get-Date`, `Get-FileHash`, `Join-Path`, `New-Item`, `Out-Null`, `Select-Object`, `Split-Path`.

Named callers: [Invoke-LocalSessionLockRecovery](#invoke-localsessionlockrecovery), [Invoke-WorkflowEvidenceMigration](#invoke-workflowevidencemigration).

### Get-LocalSessionOwnerState

Distinguish an absent legacy owner from a running host or a reused process ID.

Source: [autopilot-express.ps1:1623](autopilot-express.ps1#L1623). Internal entry-script function; source region: `Storage Authority and Persisted Evidence`.

| Parameter | Declared Type   | Attributes                                            | Default                        | Source Contract                                                          |
| --------- | --------------- | ----------------------------------------------------- | ------------------------------ | ------------------------------------------------------------------------ |
| `Owner`   | `System.Object` | `[Parameter(Mandatory)]` `[ValidateNotNullOrEmpty()]` | No explicit default expression | Parsed local lock metadata, including process ID and lock creation time. |

Outputs and result contract:

State, recovery eligibility and current process identity for operator review.

Other named commands: `Get-Process`.

Named callers: [Invoke-LocalSessionLockRecovery](#invoke-localsessionlockrecovery).

### Invoke-LocalSessionLockRecovery

Inspect a crashed local reservation or explicitly retire its verified stopped owner.

Source: [autopilot-express.ps1:1659](autopilot-express.ps1#L1659). Internal entry-script function; source region: `Storage Authority and Persisted Evidence`.

| Parameter        | Declared Type                                  | Attributes                                                       | Default                        | Source Contract                                                                    |
| ---------------- | ---------------------------------------------- | ---------------------------------------------------------------- | ------------------------------ | ---------------------------------------------------------------------------------- |
| `Path`           | `System.String`                                | `[Parameter(Mandatory)]` `[ValidateNotNullOrEmpty()]` `[string]` | No explicit default expression | Exact local session lock; no storage probing, fallback migration or tenant access. |
| `Recover`        | `System.Management.Automation.SwitchParameter` | `[switch]`                                                       | No explicit default expression | Archive the original only after owner-process absence and byte-level verification. |
| `ConfirmStopped` | `System.Management.Automation.SwitchParameter` | `[switch]`                                                       | No explicit default expression | Operator confirmation that every session using this store has stopped.             |

Outputs and result contract:

Inspection metadata or the retained evidence path. Other recovery artefacts are untouched.

Other named commands: `Compare-Object`, `ConvertFrom-Json`, `Copy-Item`, `Get-Content`, `Get-Date`, `Get-FileHash`, `Get-Item`, `Join-Path`, `New-Item`, `Out-Null`, `Remove-Item`, `Split-Path`, `Test-Path`.

Named callers: [Request-LocalSessionLock](#request-localsessionlock).

### Stop-LocalSessionLock

Release only the local lock acquired by this invocation.

Source: [autopilot-express.ps1:1742](autopilot-express.ps1#L1742). Internal entry-script function; source region: `Storage Authority and Persisted Evidence`.

| Parameter | Declared Type                  | Attributes                                                          | Default                        | Source Contract                                              |
| --------- | ------------------------------ | ------------------------------------------------------------------- | ------------------------------ | ------------------------------------------------------------ |
| `Lock`    | `System.Collections.Hashtable` | `[Parameter(Mandatory)]` `[ValidateNotNullOrEmpty()]` `[hashtable]` | No explicit default expression | Path and ownership token returned by Start-LocalSessionLock. |

Outputs and result contract:

None. Removes only an unchanged lock owned by this session; foreign evidence is retained.

Other named commands: `ConvertFrom-Json`, `Get-Content`, `Remove-Item`.

No statically named function caller in this inventory. Top-level, dynamic and callback invocation remain possible.

### New-ParentDirectory

Ensure the parent directory exists before a guarded file write.

Source: [autopilot-express.ps1:1765](autopilot-express.ps1#L1765). Internal entry-script function; source region: `Storage Authority and Persisted Evidence`.

| Parameter | Declared Type   | Attributes                          | Default                        | Source Contract                                  |
| --------- | --------------- | ----------------------------------- | ------------------------------ | ------------------------------------------------ |
| `Path`    | `System.String` | `[Parameter(Mandatory)]` `[string]` | No explicit default expression | Destination file path, not the directory itself. |

Outputs and result contract:

None. Creates a missing parent and propagates access failures.

Other named commands: `New-Item`, `Out-Null`, `Split-Path`, `Test-Path`.

Named callers: [Write-Utf8File](#write-utf8file), [Save-DeviceActionState](#save-deviceactionstate).

### Get-StorageFileEncoding

Select the UTF-8 encoding name supported by the executing PowerShell host.

Source: [autopilot-express.ps1:1781](autopilot-express.ps1#L1781). Internal entry-script function; source region: `Storage Authority and Persisted Evidence`.

No formal parameters declared. Captured state and enclosing scope may still be inputs.

Outputs and result contract:

utf8NoBOM on PowerShell 7, or UTF8 on Windows PowerShell 5.1.

Named callers: [Test-DirectoryWritable](#test-directorywritable), [Write-Utf8File](#write-utf8file).

### Write-Utf8File

Save verified staged content with recoverable previous-file evidence.

Source: [autopilot-express.ps1:1792](autopilot-express.ps1#L1792). Internal entry-script function; source region: `Storage Authority and Persisted Evidence`.

| Parameter      | Declared Type   | Attributes                                                       | Default                        | Source Contract                                                                                                                                                                              |
| -------------- | --------------- | ---------------------------------------------------------------- | ------------------------------ | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `Path`         | `System.String` | `[Parameter(Mandatory)]` `[ValidateNotNullOrEmpty()]` `[string]` | No explicit default expression | Target file; recovery artefacts are stored beside it on the same volume.                                                                                                                     |
| `Content`      | `System.String` | `[Parameter(Mandatory)]` `[AllowEmptyString()]` `[string]`       | No explicit default expression | Complete text to save with the host-appropriate UTF-8 encoding.                                                                                                                              |
| `PreviousPath` | `System.String` | `[string]`                                                       | No explicit default expression | Optional backup location for the replaced content. Defaults to the Path value with '.previous' appended. Archive updates pass a dated name so the archive's own .previous evidence survives. |

Outputs and result contract:

None. Guarded file promotion retains recovery evidence on failure; not a power-loss guarantee.

Other named commands: `ConvertTo-Json`, `Copy-Item`, `Get-Content`, `Get-Date`, `Move-Item`, `New-Item`, `Out-Null`, `Remove-Item`, `Set-Content`, `Test-Path`.

Named callers: [Write-SharedStoreSnapshot](#write-sharedstoresnapshot), [Copy-StateFileIfNeeded](#copy-statefileifneeded), [Initialize-SessionFileIndex](#initialize-sessionfileindex), [Sync-RepoStateFilesToActiveStorage](#sync-repostatefilestoactivestorage), [Update-MasterAuditLedger](#update-masterauditledger), [Write-UserDeviceRecords](#write-userdevicerecords), [Save-ImagingWorkPatternChange](#save-imagingworkpatternchange), [Export-SessionReport](#export-sessionreport), [Save-BuildBenchState](#save-buildbenchstate), [Save-DeviceActionState](#save-deviceactionstate), [Save-RecentUsers](#save-recentusers), [Update-DeviceInventoryFromIntune](#update-deviceinventoryfromintune), [Save-DeviceDocumentFailure](#save-devicedocumentfailure), [Show-DeviceDocumentSettings](#show-devicedocumentsettings).

### Assert-FileWriteRecoveryState

Stop before consuming or migrating a file with unresolved save evidence.

Source: [autopilot-express.ps1:1843](autopilot-express.ps1#L1843). Internal entry-script function; source region: `Storage Authority and Persisted Evidence`.

| Parameter | Declared Type   | Attributes                                                       | Default                        | Source Contract                                             |
| --------- | --------------- | ---------------------------------------------------------------- | ------------------------------ | ----------------------------------------------------------- |
| `Path`    | `System.String` | `[Parameter(Mandatory)]` `[ValidateNotNullOrEmpty()]` `[string]` | No explicit default expression | Target path to check even when the target itself is absent. |

Outputs and result contract:

None. Throws on unfinished writes without deleting markers or proposed evidence.

Other named commands: `Test-Path`.

Named callers: [Test-FallbackStorageAuthority](#test-fallbackstorageauthority), [Initialize-StorageLocation](#initialize-storagelocation), [Get-SharedStoreSnapshot](#get-sharedstoresnapshot), [Write-Utf8File](#write-utf8file), [Assert-LocalStorageWriteState](#assert-localstoragewritestate), [Copy-StateFileIfNeeded](#copy-statefileifneeded), [Get-SessionFileIndex](#get-sessionfileindex), [Sync-RepoStateFilesToActiveStorage](#sync-repostatefilestoactivestorage), [Move-SessionFileToArchive](#move-sessionfiletoarchive), [Assert-LocalCheckpointState](#assert-localcheckpointstate), [Read-ImagingWorkPattern](#read-imagingworkpattern), [Get-DeviceActionState](#get-deviceactionstate), [Update-DeviceInventoryFromIntune](#update-deviceinventoryfromintune), [Import-LegacySyncSubmissionEvidence](#import-legacysyncsubmissionevidence), [Import-LegacyAutopilotImportEvidence](#import-legacyautopilotimportevidence).

### Assert-LocalStorageWriteState

Validate current-mode operational save boundaries before resume or archive.

Source: [autopilot-express.ps1:1863](autopilot-express.ps1#L1863). Internal entry-script function; source region: `Storage Authority and Persisted Evidence`.

No formal parameters declared. Captured state and enclosing scope may still be inputs.

Outputs and result contract:

None. Blocks unsafe local writes; does not repair interrupted state automatically.

Other named commands: `Join-Path`, `Test-Path`.

Named callers: [Reset-CurrentSessionState](#reset-currentsessionstate), [Show-SessionArchive](#show-sessionarchive).

### Copy-StateFileIfNeeded

Migrate missing state without overwriting existing or interrupted copies.

Source: [autopilot-express.ps1:1886](autopilot-express.ps1#L1886). Internal entry-script function; source region: `Storage Authority and Persisted Evidence`.

| Parameter         | Declared Type                                  | Attributes                                                       | Default                        | Source Contract                                                         |
| ----------------- | ---------------------------------------------- | ---------------------------------------------------------------- | ------------------------------ | ----------------------------------------------------------------------- |
| `SourcePath`      | `System.String`                                | `[Parameter(Mandatory)]` `[ValidateNotNullOrEmpty()]` `[string]` | No explicit default expression | Repository state file, checked for recovery evidence even if absent.    |
| `DestinationPath` | `System.String`                                | `[Parameter(Mandatory)]` `[ValidateNotNullOrEmpty()]` `[string]` | No explicit default expression | Fallback state file; existing operational content is never overwritten. |
| `CheckOnly`       | `System.Management.Automation.SwitchParameter` | `[switch]`                                                       | No explicit default expression | Preflight all copies before beginning any multi-file migration.         |

Outputs and result contract:

None. Copies only validated migration candidates; conflicts stop promotion.

Other named commands: `Get-Content`, `Test-Path`.

Named callers: [Sync-RepoStateFilesToActiveStorage](#sync-repostatefilestoactivestorage).

### Get-ModeUserDataFilePrefix

Select the configured Demo or Live device-record prefix.

Source: [autopilot-express.ps1:1938](autopilot-express.ps1#L1938). Internal entry-script function; source region: `Storage Authority and Persisted Evidence`.

No formal parameters declared. Captured state and enclosing scope may still be inputs.

Outputs and result contract:

Prefix string from current runtime mode; no filesystem access.

Named callers: [Get-OperationalStoragePath](#get-operationalstoragepath), [Get-SessionFileIndex](#get-sessionfileindex), [Initialize-SessionFileIndex](#initialize-sessionfileindex), [Get-UserDataFilePath](#get-userdatafilepath).

### Get-ModeRecentUsersFilePrefix

Select the configured Demo or Live recent-user prefix.

Source: [autopilot-express.ps1:1949](autopilot-express.ps1#L1949). Internal entry-script function; source region: `Storage Authority and Persisted Evidence`.

No formal parameters declared. Captured state and enclosing scope may still be inputs.

Outputs and result contract:

Mode-specific prefix; does not mix simulated and Live account history.

Named callers: [Get-OperationalStoragePath](#get-operationalstoragepath), [Get-RecentUsersFilePath](#get-recentusersfilepath).

### Get-ModeBuildBenchFilePrefix

Select the configured Demo or Live bench-state prefix.

Source: [autopilot-express.ps1:1960](autopilot-express.ps1#L1960). Internal entry-script function; source region: `Storage Authority and Persisted Evidence`.

No formal parameters declared. Captured state and enclosing scope may still be inputs.

Outputs and result contract:

Mode-specific bench prefix; no filesystem access.

Named callers: [Get-OperationalStoragePath](#get-operationalstoragepath), [Get-SessionFileIndex](#get-sessionfileindex), [Initialize-SessionFileIndex](#initialize-sessionfileindex), [Get-BuildBenchStatePath](#get-buildbenchstatepath).

### Get-SessionFileIndexPath

Locate stable user/mode resume authority without selecting a storage root.

Source: [autopilot-express.ps1:1971](autopilot-express.ps1#L1971). Internal entry-script function; source region: `Storage Authority and Persisted Evidence`.

| Parameter  | Declared Type   | Attributes                          | Default                        | Source Contract                        |
| ---------- | --------------- | ----------------------------------- | ------------------------------ | -------------------------------------- |
| `DataPath` | `System.String` | `[Parameter(Mandatory)]` `[string]` | No explicit default expression | Explicit authoritative data directory. |

Outputs and result contract:

Index path for the current Windows user and runtime mode; no file access.

Other named commands: `Join-Path`.

Named callers: [Get-OperationalStoragePath](#get-operationalstoragepath), [Get-SessionFileIndex](#get-sessionfileindex), [Initialize-SessionFileIndex](#initialize-sessionfileindex), [Reset-CurrentSessionState](#reset-currentsessionstate).

### Get-SessionFileIndex

Read authoritative session paths; never choose the newest matching file.

Source: [autopilot-express.ps1:1985](autopilot-express.ps1#L1985). Internal entry-script function; source region: `Storage Authority and Persisted Evidence`.

| Parameter  | Declared Type   | Attributes                          | Default                        | Source Contract                                                                |
| ---------- | --------------- | ----------------------------------- | ------------------------------ | ------------------------------------------------------------------------------ |
| `DataPath` | `System.String` | `[Parameter(Mandatory)]` `[string]` | No explicit default expression | Explicit selected or preflight data root. Only safe, linked basenames qualify. |

Outputs and result contract:

Validated index, null for legacy/no session, or a recovery error.

Other named commands: `ConvertFrom-Json`, `Get-ChildItem`, `Get-Content`, `Get-Date`, `Test-Path`, `Where-Object`.

Named callers: [Get-OperationalStoragePath](#get-operationalstoragepath), [Initialize-SessionFileIndex](#initialize-sessionfileindex), [Get-UserDataFilePath](#get-userdatafilepath), [Get-BuildBenchStatePath](#get-buildbenchstatepath), [Reset-CurrentSessionState](#reset-currentsessionstate).

### Initialize-SessionFileIndex

Persist new-session identity once, retaining fixed legacy names until archive.

Source: [autopilot-express.ps1:2024](autopilot-express.ps1#L2024). Internal entry-script function; source region: `Storage Authority and Persisted Evidence`.

No formal parameters declared. Captured state and enclosing scope may still be inputs.

Outputs and result contract:

None. Persists new session authority through guarded storage before enabling indexed paths.

Other named commands: `ConvertTo-Json`, `Get-Date`, `Join-Path`, `Test-Path`.

Named callers: [Write-UserDeviceRecords](#write-userdevicerecords), [Save-BuildBenchState](#save-buildbenchstate).

### Get-UserDataFilePath

Resolve authoritative indexed or legacy device-record storage.

Source: [autopilot-express.ps1:2052](autopilot-express.ps1#L2052). Internal entry-script function; source region: `Storage Authority and Persisted Evidence`.

| Parameter  | Declared Type   | Attributes | Default                        | Source Contract                                               |
| ---------- | --------------- | ---------- | ------------------------------ | ------------------------------------------------------------- |
| `BasePath` | `System.String` | `[string]` | No explicit default expression | Optional selected storage base used during guarded preflight. |

Outputs and result contract:

Validated indexed path or fixed legacy path; refuses orphaned stamped evidence.

Other named commands: `Join-Path`.

Named callers: [Assert-LocalStorageWriteState](#assert-localstoragewritestate), [Get-SessionLastUpdated](#get-sessionlastupdated), [Reset-CurrentSessionState](#reset-currentsessionstate), [Get-LocalCheckpointInspection](#get-localcheckpointinspection), [Get-UserDeviceRecords](#get-userdevicerecords), [Write-UserDeviceRecords](#write-userdevicerecords), [Show-SessionArchive](#show-sessionarchive), [Initialize-SessionState](#initialize-sessionstate).

### Get-BuildBenchStatePath

Resolve the bench file linked to the current indexed or legacy session.

Source: [autopilot-express.ps1:2072](autopilot-express.ps1#L2072). Internal entry-script function; source region: `Storage Authority and Persisted Evidence`.

| Parameter  | Declared Type   | Attributes | Default                        | Source Contract                                               |
| ---------- | --------------- | ---------- | ------------------------------ | ------------------------------------------------------------- |
| `BasePath` | `System.String` | `[string]` | No explicit default expression | Optional selected storage base used during guarded preflight. |

Outputs and result contract:

Linked bench path. Invalid index authority throws rather than guessing a file.

Other named commands: `Join-Path`.

Named callers: [Assert-LocalStorageWriteState](#assert-localstoragewritestate), [Get-SessionLastUpdated](#get-sessionlastupdated), [Reset-CurrentSessionState](#reset-currentsessionstate), [Get-LocalCheckpointInspection](#get-localcheckpointinspection), [Save-BuildBenchState](#save-buildbenchstate), [Get-BuildBenchState](#get-buildbenchstate), [Show-SessionArchive](#show-sessionarchive), [Initialize-SessionState](#initialize-sessionstate).

### Get-RecentUsersFilePath

Locate current-user recent-account storage in the selected mode.

Source: [autopilot-express.ps1:2091](autopilot-express.ps1#L2091). Internal entry-script function; source region: `Storage Authority and Persisted Evidence`.

| Parameter  | Declared Type   | Attributes | Default                        | Source Contract                                                |
| ---------- | --------------- | ---------- | ------------------------------ | -------------------------------------------------------------- |
| `BasePath` | `System.String` | `[string]` | No explicit default expression | Optional selected storage base; defaults to current authority. |

Outputs and result contract:

Fixed recent-user JSON path; this helper does not load account data.

Other named commands: `Join-Path`.

Named callers: [Assert-LocalStorageWriteState](#assert-localstoragewritestate), [Get-RecentUsers](#get-recentusers), [Save-RecentUsers](#save-recentusers).

### Get-AutopilotExpressDefinitionPath

Resolve a definition relative to the bootstrap-authorised definition directory.

Source: [autopilot-express.ps1:2105](autopilot-express.ps1#L2105). Internal entry-script function; source region: `Storage Authority and Persisted Evidence`.

| Parameter  | Declared Type   | Attributes                          | Default                        | Source Contract                                   |
| ---------- | --------------- | ----------------------------------- | ------------------------------ | ------------------------------------------------- |
| `FileName` | `System.String` | `[Parameter(Mandatory)]` `[string]` | No explicit default expression | Internal runtime or manifest definition filename. |

Outputs and result contract:

Definition path; rejects missing bootstrap directory state.

Other named commands: `Join-Path`.

Named callers: [Get-RuntimeConfigFilePath](#get-runtimeconfigfilepath), [Get-ManifestFilePath](#get-manifestfilepath), [Show-SessionInformation](#show-sessioninformation), [Show-AboutScript](#show-aboutscript), [Test-DeviceDocumentScriptTrust](#test-devicedocumentscripttrust), [Initialize-DeviceDocumentSession](#initialize-devicedocumentsession).

### Get-RuntimeConfigFilePath

Locate the runtime configuration in the authorised definition directory.

Source: [autopilot-express.ps1:2121](autopilot-express.ps1#L2121). Internal entry-script function; source region: `Storage Authority and Persisted Evidence`.

No formal parameters declared. Captured state and enclosing scope may still be inputs.

Outputs and result contract:

Runtime JSON path using the configured internal filename.

Named callers: [Initialize-AutopilotExpressDefinitions](#initialize-autopilotexpressdefinitions), [Get-AutopilotHashCandidate](#get-autopilothashcandidate).

### Get-ManifestFilePath

Locate the workflow manifest in the authorised definition directory.

Source: [autopilot-express.ps1:2131](autopilot-express.ps1#L2131). Internal entry-script function; source region: `Storage Authority and Persisted Evidence`.

No formal parameters declared. Captured state and enclosing scope may still be inputs.

Outputs and result contract:

Manifest JSON path; no definition is loaded by this helper.

Named callers: [Initialize-AutopilotExpressDefinitions](#initialize-autopilotexpressdefinitions).

### Get-MasterAuditFilePath

Locate the root-wide audit ledger without creating or rewriting it.

Source: [autopilot-express.ps1:2141](autopilot-express.ps1#L2141). Internal entry-script function; source region: `Storage Authority and Persisted Evidence`.

| Parameter  | Declared Type   | Attributes | Default                        | Source Contract                                                 |
| ---------- | --------------- | ---------- | ------------------------------ | --------------------------------------------------------------- |
| `BasePath` | `System.String` | `[string]` | No explicit default expression | Optional selected storage base for guarded migration preflight. |

Outputs and result contract:

Master-audit JSON path under the selected data directory.

Other named commands: `Join-Path`.

Named callers: [Assert-LocalStorageWriteState](#assert-localstoragewritestate), [Get-MasterAuditProposal](#get-masterauditproposal), [Update-MasterAuditLedger](#update-masterauditledger), [Get-LocalCheckpointInspection](#get-localcheckpointinspection), [Write-UserDeviceRecords](#write-userdevicerecords).

### Sync-RepoStateFilesToActiveStorage

Establish fallback authority only after a reserved, verified migration.

Source: [autopilot-express.ps1:2155](autopilot-express.ps1#L2155). Internal entry-script function; source region: `Storage Authority and Persisted Evidence`.

No formal parameters declared. Captured state and enclosing scope may still be inputs.

Outputs and result contract:

None. Performs guarded fallback migration without selecting a newer file by timestamp.

Other named commands: `ForEach-Object`, `Join-Path`, `Sort-Object`, `Split-Path`.

Named callers: [Initialize-LocalSessionForResume](#initialize-localsessionforresume), [Initialize-SessionState](#initialize-sessionstate).

### Get-SessionLastUpdated

Inspect the latest modification time of the current session's tracked files.

Source: [autopilot-express.ps1:2198](autopilot-express.ps1#L2198). Internal entry-script function; source region: `Storage Authority and Persisted Evidence`.

No formal parameters declared. Captured state and enclosing scope may still be inputs.

Outputs and result contract:

File modification DateTime, or null. This is display metadata, not resume authority.

Other named commands: `ForEach-Object`, `Get-Item`, `Select-Object`, `Sort-Object`, `Test-Path`, `Where-Object`.

Named callers: [Initialize-SessionState](#initialize-sessionstate).

### Move-SessionFileToArchive

Move selected session evidence to a collision-safe archive destination.

Source: [autopilot-express.ps1:2211](autopilot-express.ps1#L2211). Internal entry-script function; source region: `Storage Authority and Persisted Evidence`.

| Parameter       | Declared Type   | Attributes                          | Default                        | Source Contract                                                    |
| --------------- | --------------- | ----------------------------------- | ------------------------------ | ------------------------------------------------------------------ |
| `Path`          | `System.String` | `[Parameter(Mandatory)]` `[string]` | No explicit default expression | Explicit current-session file selected by the archive coordinator. |
| `SessionPrefix` | `System.String` | `[string]`                          | No explicit default expression | Stable original-session prefix used in archive naming.             |

Outputs and result contract:

None. Moves existing evidence and propagates failures; does not provide atomic rollback.

Other named commands: `Get-Date`, `Join-Path`, `Move-Item`, `Split-Path`, `Test-Path`.

Named callers: [Reset-CurrentSessionState](#reset-currentsessionstate).

### Reset-CurrentSessionState

Archive the current user/mode session before initialising empty in-memory state.

Source: [autopilot-express.ps1:2240](autopilot-express.ps1#L2240). Internal entry-script function; source region: `Storage Authority and Persisted Evidence`.

No formal parameters declared. Captured state and enclosing scope may still be inputs.

Outputs and result contract:

Empty record array on success. Interrupted archive evidence blocks later reuse.

Other named commands: `ConvertTo-Json`, `Get-Date`, `New-Item`, `Out-Null`, `Remove-Item`.

Named callers: [Show-SessionArchive](#show-sessionarchive), [Initialize-SessionState](#initialize-sessionstate).

### ConvertTo-RecordDate

Parse persisted time values with the record loader's legacy-compatible fallback.

Source: [autopilot-express.ps1:2261](autopilot-express.ps1#L2261). Internal entry-script function; source region: `Storage Authority and Persisted Evidence`.

| Parameter | Declared Type   | Attributes    | Default                        | Source Contract                                                              |
| --------- | --------------- | ------------- | ------------------------------ | ---------------------------------------------------------------------------- |
| `Value`   | `System.Object` | None declared | No explicit default expression | DateTime or textual time; empty or invalid input is represented as MinValue. |

Outputs and result contract:

DateTime for record calculations. This conversion does not prove an event occurred.

Named callers: [ConvertTo-PersistedDate](#convertto-persisteddate), [Get-UserDeviceRecords](#get-userdevicerecords), [Invoke-DeviceWorkflowPlan](#invoke-deviceworkflowplan), [Get-DeviceDispatchDate](#get-devicedispatchdate), [Assert-ImagingWorkPattern](#assert-imagingworkpattern), [Get-ImagingWorkingMinutes](#get-imagingworkingminutes), [Get-DispatchStatsRows](#get-dispatchstatsrows), [Get-SessionReportRows](#get-sessionreportrows), [Invoke-DeviceInventoryCheck](#invoke-deviceinventorycheck), [Invoke-DeviceInventoryPolling](#invoke-deviceinventorypolling), [Invoke-StepRemoveAssociatedManagedDevice](#invoke-stepremoveassociatedmanageddevice), [Get-RecoverySubmissionEvidence](#get-recoverysubmissionevidence), [Invoke-StepConfirmRecoveryReadiness](#invoke-stepconfirmrecoveryreadiness), [Test-ApplicationNoFailureEvidence](#test-applicationnofailureevidence), [Write-ManifestStepResult](#write-manifeststepresult), [Test-ManifestStepEligibility](#test-manifeststepeligibility), [Undo-LatestTechnicianConfirmation](#undo-latesttechnicianconfirmation), [Show-BuildBenchTable](#show-buildbenchtable).

### ConvertTo-PersistedDate

Serialise a valid record timestamp in round-trip format.

Source: [autopilot-express.ps1:2290](autopilot-express.ps1#L2290). Internal entry-script function; source region: `Storage Authority and Persisted Evidence`.

| Parameter | Declared Type   | Attributes    | Default                        | Source Contract                                    |
| --------- | --------------- | ------------- | ------------------------------ | -------------------------------------------------- |
| `Value`   | `System.Object` | None declared | No explicit default expression | Record timestamp accepted by ConvertTo-RecordDate. |

Outputs and result contract:

ISO round-trip string, or null for an absent/invalid timestamp.

Other named commands: `Get-Date`.

Named callers: [ConvertTo-PersistedDeviceRecord](#convertto-persisteddevicerecord), [Get-MasterAuditProposal](#get-masterauditproposal), [Save-RecoverySubmissionEvidence](#save-recoverysubmissionevidence), [Get-ConfirmedApplicationBaseline](#get-confirmedapplicationbaseline).

### Get-LegacyWorkflowIdMap

Map version-one saved IDs to canonical checklist IDs simultaneously.

Source: [autopilot-express.ps1:2306](autopilot-express.ps1#L2306). Internal entry-script function; source region: `Storage Authority and Persisted Evidence`.

No formal parameters declared. Captured state and enclosing scope may still be inputs.

Outputs and result contract:

A bijective dictionary; never apply successive textual replacements.

Named callers: [ConvertTo-CanonicalWorkflowRecord](#convertto-canonicalworkflowrecord).

### ConvertTo-CanonicalWorkflowRecord

Stage an idempotent versioned conversion without changing caller evidence.

Source: [autopilot-express.ps1:2316](autopilot-express.ps1#L2316). Internal entry-script function; source region: `Storage Authority and Persisted Evidence`.

| Parameter | Declared Type                    | Attributes                                                  | Default                        | Source Contract                                                         |
| --------- | -------------------------------- | ----------------------------------------------------------- | ------------------------------ | ----------------------------------------------------------------------- |
| `Record`  | `System.Collections.IDictionary` | `[Parameter(Mandatory)]` `[System.Collections.IDictionary]` | No explicit default expression | Device or audit dictionary. Missing WorkflowIdVersion means legacy one. |

Outputs and result contract:

Detached dictionary with canonical WorkflowIdVersion two.

Named callers: [Invoke-WorkflowEvidenceMigration](#invoke-workflowevidencemigration).

### Convert-WorkflowReference

Resolve one typed workflow ID under the enclosing record's explicit version.

Source: [autopilot-express.ps1:2334](autopilot-express.ps1#L2334). Nested in `ConvertTo-CanonicalWorkflowRecord`; its enclosing scope is part of the contract.

| Parameter | Declared Type   | Attributes    | Default                        | Source Contract                                                |
| --------- | --------------- | ------------- | ------------------------------ | -------------------------------------------------------------- |
| `StepId`  | `System.Object` | None declared | No explicit default expression | Stored reference from current evidence or a retained snapshot. |

Outputs and result contract:

Canonical ID; unknown/ambiguous references throw rather than being dropped.

Named callers: [ConvertTo-CanonicalWorkflowRecord](#convertto-canonicalworkflowrecord), [Convert-WorkflowStepMap](#convert-workflowstepmap).

### Convert-WorkflowStepMap

Re-key a complete workflow snapshot without changing result evidence.

Source: [autopilot-express.ps1:2348](autopilot-express.ps1#L2348). Nested in `ConvertTo-CanonicalWorkflowRecord`; its enclosing scope is part of the contract.

| Parameter | Declared Type   | Attributes    | Default                        | Source Contract                                                    |
| --------- | --------------- | ------------- | ------------------------------ | ------------------------------------------------------------------ |
| `Steps`   | `System.Object` | None declared | No explicit default expression | Original step dictionary governed by the enclosing record version. |

Outputs and result contract:

Detached canonical step map; conflicting identities are refused.

Named callers: [ConvertTo-CanonicalWorkflowRecord](#convertto-canonicalworkflowrecord).

### Invoke-WorkflowEvidenceMigration

Rehearse or explicitly convert workspace current/previous workflow evidence.

Source: [autopilot-express.ps1:2393](autopilot-express.ps1#L2393). Internal entry-script function; source region: `Storage Authority and Persisted Evidence`.

| Parameter     | Declared Type                                  | Attributes    | Default                        | Source Contract                                                                                                                                           |
| ------------- | ---------------------------------------------- | ------------- | ------------------------------ | --------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `Apply`       | `System.Management.Automation.SwitchParameter` | `[switch]`    | No explicit default expression | Promote only after all proposals and external backups are verified.                                                                                       |
| `SessionLock` | `System.Collections.Hashtable`                 | `[hashtable]` | No explicit default expression | Optional version-two reservation already held by startup for the authoritative root/mode. Its live handle and ownership token must match this invocation. |
| `PassThru`    | `System.Management.Automation.SwitchParameter` | `[switch]`    | No explicit default expression | Return structured file/change counts instead of the operator summary text.                                                                                |

Outputs and result contract:

A concise file count and verified-originals location when applied.

Other named commands: `ConvertFrom-Json`, `ConvertTo-Json`, `Copy-Item`, `ForEach-Object`, `Get-ChildItem`, `Get-Command`, `Get-Content`, `Get-Date`, `Get-FileHash`, `Join-Path`, `New-Item`, `Out-Null`, `Remove-Item`, `Set-Content`, `Split-Path`, `Test-Path`, `Where-Object`.

Named callers: [Initialize-LocalSessionForResume](#initialize-localsessionforresume).

### Assert-WorkflowMigrationOwnership

Revalidate the enclosing startup reservation before reading or promoting evidence.

Source: [autopilot-express.ps1:2416](autopilot-express.ps1#L2416). Nested in `Invoke-WorkflowEvidenceMigration`; its enclosing scope is part of the contract.

No formal parameters declared. Captured state and enclosing scope may still be inputs.

Outputs and result contract:

None. Refuses a released handle or changed ownership without deleting recovery evidence.

Other named commands: `ConvertFrom-Json`, `Get-Content`.

Named callers: [Invoke-WorkflowEvidenceMigration](#invoke-workflowevidencemigration).

### Initialize-LocalSessionForResume

Prepare and validate saved work under the owned reservation before authentication.

Source: [autopilot-express.ps1:2514](autopilot-express.ps1#L2514). Internal entry-script function; source region: `Storage Authority and Persisted Evidence`.

| Parameter     | Declared Type                  | Attributes                                                          | Default                        | Source Contract                                              |
| ------------- | ------------------------------ | ------------------------------------------------------------------- | ------------------------------ | ------------------------------------------------------------ |
| `SessionLock` | `System.Collections.Hashtable` | `[Parameter(Mandatory)]` `[ValidateNotNullOrEmpty()]` `[hashtable]` | No explicit default expression | Current invocation's open version-two root/mode reservation. |

Outputs and result contract:

True when saved work is ready; false on declined conversion. Validation errors throw.

Other named commands: `ConvertFrom-Json`, `Get-ChildItem`, `Get-Content`, `Split-Path`, `Write-Host`.

No statically named function caller in this inventory. Top-level, dynamic and callback invocation remain possible.

### ConvertTo-PersistedDeviceRecord

Detach a device record and prepare its date fields for JSON persistence.

Source: [autopilot-express.ps1:2563](autopilot-express.ps1#L2563). Internal entry-script function; source region: `Storage Authority and Persisted Evidence`.

| Parameter | Declared Type   | Attributes               | Default                        | Source Contract                                                                    |
| --------- | --------------- | ------------------------ | ------------------------------ | ---------------------------------------------------------------------------------- |
| `Record`  | `System.Object` | `[Parameter(Mandatory)]` | No explicit default expression | Validated in-memory record; original objects are not rewritten by this conversion. |

Outputs and result contract:

Persistable dictionary. Storage and audit promotion are separate guarded operations.

Named callers: [Write-UserDeviceRecords](#write-userdevicerecords).

### Assert-AttemptHistory

Validate detached writer evidence without migrating or repairing history.

Source: [autopilot-express.ps1:2581](autopilot-express.ps1#L2581). Internal entry-script function; source region: `Storage Authority and Persisted Evidence`.

| Parameter | Declared Type                    | Attributes                                                  | Default                        | Source Contract                                                            |
| --------- | -------------------------------- | ----------------------------------------------------------- | ------------------------------ | -------------------------------------------------------------------------- |
| `Record`  | `System.Collections.IDictionary` | `[Parameter(Mandatory)]` `[System.Collections.IDictionary]` | No explicit default expression | Normalised record or audit dictionary. Absent legacy history is permitted. |

Outputs and result contract:

None. Throws on malformed histories without deleting or normalising away evidence.

Other named commands: `Get-Date`.

Named callers: [Invoke-WorkflowEvidenceMigration](#invoke-workflowevidencemigration), [Assert-AttemptHistoryPreserved](#assert-attempthistorypreserved), [Get-UserDeviceRecords](#get-userdevicerecords), [Get-RecoverySubmissionEvidence](#get-recoverysubmissionevidence).

### Test-AttemptEvidenceEqual

Compare normalised evidence structurally, never by dictionary JSON order.

Source: [autopilot-express.ps1:2650](autopilot-express.ps1#L2650). Internal entry-script function; source region: `Storage Authority and Persisted Evidence`.

| Parameter | Declared Type   | Attributes    | Default                        | Source Contract                                                           |
| --------- | --------------- | ------------- | ------------------------------ | ------------------------------------------------------------------------- |
| `Left`    | `System.Object` | None declared | No explicit default expression | Existing evidence, with dates normalised by the record staging helpers.   |
| `Right`   | `System.Object` | None declared | No explicit default expression | Proposed evidence. Arrays retain order; text and keys are case-sensitive. |

Outputs and result contract:

Boolean equality; ISO dates compare as UTC instants on either host.

Other named commands: `Get-Date`.

Named callers: [Write-SharedStoreSnapshot](#write-sharedstoresnapshot), [Invoke-WorkflowEvidenceMigration](#invoke-workflowevidencemigration), [Test-AttemptEvidenceEqual](#test-attemptevidenceequal), [Assert-AttemptHistoryPreserved](#assert-attempthistorypreserved), [Update-DeviceInventoryFromIntune](#update-deviceinventoryfromintune).

### Assert-AttemptHistoryPreserved

Refuse replacement, truncation or removal of previously saved attempts.

Source: [autopilot-express.ps1:2705](autopilot-express.ps1#L2705). Internal entry-script function; source region: `Storage Authority and Persisted Evidence`.

| Parameter               | Declared Type                                  | Attributes                                                    | Default                        | Source Contract                                                           |
| ----------------------- | ---------------------------------------------- | ------------------------------------------------------------- | ------------------------------ | ------------------------------------------------------------------------- |
| `Records`               | `System.Collections.IEnumerable`               | `[AllowEmptyCollection()]` `[System.Collections.IEnumerable]` | `@()`                          | Complete staged proposal, not mutated by validation.                      |
| `ExistingRecords`       | `System.Collections.IEnumerable`               | `[AllowEmptyCollection()]` `[System.Collections.IEnumerable]` | `@()`                          | Independently read persisted records; malformed evidence fails closed.    |
| `AllowUnmatchedRecords` | `System.Management.Automation.SwitchParameter` | `[switch]`                                                    | No explicit default expression | Audit-only historical records remain in the ledger, outside this session. |

Outputs and result contract:

None. Rejects history loss or evidence changes before persistence.

Other named commands: `Where-Object`.

Named callers: [Assert-SharedStoreSnapshot](#assert-sharedstoresnapshot), [Write-SharedStoreSnapshot](#write-sharedstoresnapshot), [Get-MasterAuditProposal](#get-masterauditproposal), [Get-UserDeviceRecords](#get-userdevicerecords), [Write-UserDeviceRecords](#write-userdevicerecords).

### Get-MasterAuditProposal

Stage the complete existing ledger merge without writing operational data.

Source: [autopilot-express.ps1:2772](autopilot-express.ps1#L2772). Internal entry-script function; source region: `Storage Authority and Persisted Evidence`.

| Parameter        | Declared Type                                  | Attributes                                                  | Default                        | Source Contract                                                                                                                      |
| ---------------- | ---------------------------------------------- | ----------------------------------------------------------- | ------------------------------ | ------------------------------------------------------------------------------------------------------------------------------------ |
| `Records`        | `System.Collections.IEnumerable`               | `[Parameter(Mandatory)]` `[System.Collections.IEnumerable]` | No explicit default expression | Persisted device records to merge; the caller's objects are not changed.                                                             |
| `IncludeEntries` | `System.Management.Automation.SwitchParameter` | `[switch]`                                                  | No explicit default expression | Also return the merged entries, so the record writer can keep them as its private copy for the next save (see Get-VerifiedSaveCopy). |

Outputs and result contract:

Exact proposed ledger JSON, or null in Demo mode. With IncludeEntries, a hashtable
with Json and Entries keys.

Other named commands: `ConvertFrom-Json`, `ConvertTo-Json`, `Get-Content`, `Sort-Object`, `Test-Path`, `Where-Object`.

Named callers: [Update-MasterAuditLedger](#update-masterauditledger), [Write-UserDeviceRecords](#write-userdevicerecords).

### Update-MasterAuditLedger

Persist the validated root-wide audit proposal using guarded UTF-8 writes.

Source: [autopilot-express.ps1:2864](autopilot-express.ps1#L2864). Internal entry-script function; source region: `Storage Authority and Persisted Evidence`.

| Parameter         | Declared Type                    | Attributes                                                  | Default                        | Source Contract                                                                |
| ----------------- | -------------------------------- | ----------------------------------------------------------- | ------------------------------ | ------------------------------------------------------------------------------ |
| `Records`         | `System.Collections.IEnumerable` | `[Parameter(Mandatory)]` `[System.Collections.IEnumerable]` | No explicit default expression | Current session records used when a precomputed proposal is not supplied.      |
| `ProposedContent` | `System.String`                  | `[string]`                                                  | No explicit default expression | Optional already-validated ledger JSON prepared by the checkpoint coordinator. |

Outputs and result contract:

None. Live audit write failures propagate; Demo does not update the Live ledger.

Named callers: [Write-UserDeviceRecords](#write-userdevicerecords).

### Get-LocalCheckpointPath

Locate a per-user, per-mode checkpoint proposal, not a migration candidate.

Source: [autopilot-express.ps1:2881](autopilot-express.ps1#L2881). Internal entry-script function; source region: `Storage Authority and Persisted Evidence`.

| Parameter  | Declared Type   | Attributes                              | Default                        | Source Contract                                                                                                                                      |
| ---------- | --------------- | --------------------------------------- | ------------------------------ | ---------------------------------------------------------------------------------------------------------------------------------------------------- |
| `BasePath` | `System.String` | `[ValidateNotNullOrEmpty()]` `[string]` | No explicit default expression | Explicit root for read-only preflight without root selection or directory creation. When omitted, use the active root for existing checkpoint saves. |

Outputs and result contract:

Checkpoint proposal path in the requested root and current mode.

Other named commands: `Join-Path`.

Named callers: [Assert-LocalCheckpointState](#assert-localcheckpointstate), [Get-LocalCheckpointInspection](#get-localcheckpointinspection), [Write-UserDeviceRecords](#write-userdevicerecords), [Save-BuildBenchState](#save-buildbenchstate).

### Assert-LocalCheckpointState

Reject checkpoint proposals and orphan writer evidence without changes.

Source: [autopilot-express.ps1:2897](autopilot-express.ps1#L2897). Internal entry-script function; source region: `Storage Authority and Persisted Evidence`.

| Parameter  | Declared Type   | Attributes                              | Default                        | Source Contract                                                                                                                                                                                       |
| ---------- | --------------- | --------------------------------------- | ------------------------------ | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `BasePath` | `System.String` | `[ValidateNotNullOrEmpty()]` `[string]` | No explicit default expression | Explicit root to inspect before probes, reservation or migration. Fallback authority does not establish lineage for an unfinished source checkpoint. When omitted, inspect the active root as before. |

Outputs and result contract:

None. Unfinished checkpoints block reuse; no automatic replay or rollback occurs.

Other named commands: `Test-Path`.

Named callers: [Initialize-StorageLocation](#initialize-storagelocation), [Assert-LocalStorageWriteState](#assert-localstoragewritestate), [Sync-RepoStateFilesToActiveStorage](#sync-repostatefilestoactivestorage), [Write-UserDeviceRecords](#write-userdevicerecords), [Save-BuildBenchState](#save-buildbenchstate).

### Get-LocalCheckpointInspection

Return read-only checkpoint proposal and file evidence for operator review.

Source: [autopilot-express.ps1:2916](autopilot-express.ps1#L2916). Internal entry-script function; source region: `Storage Authority and Persisted Evidence`.

No formal parameters declared. Captured state and enclosing scope may still be inputs.

Outputs and result contract:

Checkpoint envelope and the presence of each target and recovery artefact.

Other named commands: `ConvertFrom-Json`, `Get-Content`, `Test-Path`.

No statically named function caller in this inventory. Top-level, dynamic and callback invocation remain possible.

### Get-UserDeviceRecords

Load and validate current-user device evidence without repairing malformed files.

Source: [autopilot-express.ps1:2948](autopilot-express.ps1#L2948). Internal entry-script function; source region: `Storage Authority and Persisted Evidence`.

No formal parameters declared. Captured state and enclosing scope may still be inputs.

Outputs and result contract:

Record array with normalised dates, steps and histories. Invalid identities, state or
recovery evidence throw; the original file remains available for operator review.

Other named commands: `ConvertFrom-Json`, `ForEach-Object`, `Get-Content`, `Get-Date`, `Test-Path`.

Named callers: [Initialize-LocalSessionForResume](#initialize-localsessionforresume), [Write-UserDeviceRecords](#write-userdevicerecords), [Initialize-SessionState](#initialize-sessionstate).

### Get-VerifiedSaveCopy

Return this session's private copy of a file it saved, only while that file is unchanged.

Source: [autopilot-express.ps1:3117](autopilot-express.ps1#L3117). Internal entry-script function; source region: `Storage Authority and Persisted Evidence`.

| Parameter | Declared Type   | Attributes                                                       | Default                        | Source Contract                         |
| --------- | --------------- | ---------------------------------------------------------------- | ------------------------------ | --------------------------------------- |
| `Path`    | `System.String` | `[Parameter(Mandatory)]` `[ValidateNotNullOrEmpty()]` `[string]` | No explicit default expression | Full path of the records or audit file. |

Outputs and result contract:

Hashtable with Text and Value keys, or $null when there is no copy or the file differs.

Other named commands: `Get-Content`, `Get-Variable`, `Test-Path`.

Named callers: [Get-MasterAuditProposal](#get-masterauditproposal), [Write-UserDeviceRecords](#write-userdevicerecords).

### Write-UserDeviceRecords

Persist staged records, audit and initialised bench under one checkpoint.

Source: [autopilot-express.ps1:3146](autopilot-express.ps1#L3146). Internal entry-script function; source region: `Storage Authority and Persisted Evidence`.

| Parameter | Declared Type                    | Attributes                                                  | Default                        | Source Contract                                                            |
| --------- | -------------------------------- | ----------------------------------------------------------- | ------------------------------ | -------------------------------------------------------------------------- |
| `Records` | `System.Collections.IEnumerable` | `[Parameter(Mandatory)]` `[System.Collections.IEnumerable]` | No explicit default expression | Complete proposed record collection; staging never mutates caller objects. |

Outputs and result contract:

None. Validates and persists guarded record/audit proposals; failures remain fatal.

Other named commands: `ConvertTo-Json`, `ForEach-Object`, `Get-Date`, `Get-Variable`, `Remove-Item`, `Write-Verbose`.

Named callers: [Invoke-ExistingDeviceLifecycle](#invoke-existingdevicelifecycle), [Start-NewDeviceWorkflow](#start-newdeviceworkflow), [Invoke-AutopilotSequence](#invoke-autopilotsequence), [Invoke-DeviceWorkflowPlan](#invoke-deviceworkflowplan), [Update-DeviceStatus](#update-devicestatus), [Show-SessionArchive](#show-sessionarchive), [Initialize-SessionState](#initialize-sessionstate), [Invoke-DeviceInventoryPolling](#invoke-deviceinventorypolling), [Update-DeviceInventoryFromIntune](#update-deviceinventoryfromintune), [Save-DeviceLedgerEntry](#save-deviceledgerentry), [Import-LegacySyncSubmissionEvidence](#import-legacysyncsubmissionevidence), [Import-LegacyAutopilotImportEvidence](#import-legacyautopilotimportevidence), [Undo-LatestTechnicianConfirmation](#undo-latesttechnicianconfirmation), [Request-DeviceDocumentReprint](#request-devicedocumentreprint), [Complete-DeviceDispatch](#complete-devicedispatch), [Add-DeviceToBenchPosition](#add-devicetobenchposition), [Sync-BenchRecords](#sync-benchrecords), [Show-BuildBenchView](#show-buildbenchview).

### Read-ValidatedInput

Read accessible input with an explicit displayed default and one prompt boundary gap.

Source: [autopilot-express.ps1:3222](autopilot-express.ps1#L3222). Internal entry-script function; source region: `Console Input and Technician Navigation`.

| Parameter          | Declared Type                                  | Attributes                                            | Default                        | Source Contract                                                                         |
| ------------------ | ---------------------------------------------- | ----------------------------------------------------- | ------------------------------ | --------------------------------------------------------------------------------------- |
| `Prompt`           | `System.String`                                | `[Parameter(Mandatory)]` `[string]`                   | No explicit default expression | Technician-facing prompt text; existing default behaviour is retained.                  |
| `Default`          | `System.String`                                | `[string]`                                            | No explicit default expression | Value used when Enter is pressed.                                                       |
| `Type`             | `System.String`                                | `[ValidateSet('String', 'Int', 'Choice')]` `[string]` | `'String'`                     | String, integer or choice validation mode.                                              |
| `Choices`          | `System.String[]`                              | `[string[]]`                                          | No explicit default expression | Allowed values for choice mode, matched without case sensitivity.                       |
| `AllowEmpty`       | `System.Management.Automation.SwitchParameter` | `[switch]`                                            | No explicit default expression | Permit empty text when the calling workflow explicitly supports it.                     |
| `ServiceInventory` | `System.Management.Automation.SwitchParameter` | `[switch]`                                            | No explicit default expression | Permit idle metadata polling at a navigation boundary, never during an action proposal. |

Outputs and result contract:

Validated response string; invalid input re-prompts without advancing workflow state.

Other named commands: `ForEach-Object`, `Get-Variable`, `Read-Host`, `Where-Object`, `Write-Host`.

Named callers: [Request-LocalSessionLock](#request-localsessionlock), [Initialize-LocalSessionForResume](#initialize-localsessionforresume), [Read-NormalisedSerialInput](#read-normalisedserialinput), [Select-Site](#select-site), [Show-MainMenu](#show-mainmenu), [Read-NewDeviceIdentityField](#read-newdeviceidentityfield), [Invoke-ExistingDeviceLifecycle](#invoke-existingdevicelifecycle), [Select-ExistingDeviceWorkflowAction](#select-existingdeviceworkflowaction), [Select-EmptyBenchPosition](#select-emptybenchposition), [Start-NewDeviceWorkflow](#start-newdeviceworkflow), [Invoke-AutopilotSequence](#invoke-autopilotsequence), [Get-DeviceOutstanding](#get-deviceoutstanding), [Update-DeviceStatus](#update-devicestatus), [Show-ImagingWorkPatternEditor](#show-imagingworkpatterneditor), [Get-UserStats](#get-userstats), [Show-SessionReportExport](#show-sessionreportexport), [Read-PagedInformation](#read-pagedinformation), [Show-SessionArchive](#show-sessionarchive), [Initialize-SessionState](#initialize-sessionstate), [Request-GraphModuleScriptTrust](#request-graphmodulescripttrust), [Install-RequiredGraphModules](#install-requiredgraphmodules), [Import-RequiredGraphModules](#import-requiredgraphmodules), [Invoke-DeviceRemediation](#invoke-deviceremediation), [Select-RemediationMenuItem](#select-remediationmenuitem), [Show-RemediationQuickRunSettings](#show-remediationquickrunsettings), [Show-DeviceActions](#show-deviceactions), [Initialize-LiveTenantContext](#initialize-livetenantcontext), [Initialize-GraphSession](#initialize-graphsession), [Select-UserFromResults](#select-userfromresults), [Select-DirectoryUser](#select-directoryuser), [Show-DeviceInventoryBackfill](#show-deviceinventorybackfill), [Invoke-StepResolveAutopilotDevice](#invoke-stepresolveautopilotdevice), [Invoke-AutopilotHashImport](#invoke-autopilothashimport), [Select-AutopilotHashRow](#select-autopilothashrow), [Invoke-StepRemoveAssociatedManagedDevice](#invoke-stepremoveassociatedmanageddevice), [Invoke-StepValidateDeploymentProfile](#invoke-stepvalidatedeploymentprofile), [Invoke-PreProvisioningMembershipChange](#invoke-preprovisioningmembershipchange), [Invoke-StepClearUserlessEnrollmentStatus](#invoke-stepclearuserlessenrollmentstatus), [Invoke-StepConfirmRecoveryReadiness](#invoke-stepconfirmrecoveryreadiness), [Select-TechnicianDirectoryUser](#select-techniciandirectoryuser), [Invoke-StepAssignTechnicianPrimaryUser](#invoke-stepassigntechnicianprimaryuser), [Read-ApplicationRetryChoice](#read-applicationretrychoice), [Invoke-StepRetryFailedApps](#invoke-stepretryfailedapps), [Invoke-StepAssignFinalPrimaryUser](#invoke-stepassignfinalprimaryuser), [Invoke-StepConfirmPhysicalMilestone](#invoke-stepconfirmphysicalmilestone), [Enter-DeviceRecoveryMode](#enter-devicerecoverymode), [Undo-LatestTechnicianConfirmation](#undo-latesttechnicianconfirmation), [Request-DeviceDocumentReadiness](#request-devicedocumentreadiness), [Request-DeviceDocumentReprint](#request-devicedocumentreprint), [Show-DeviceDocumentSettings](#show-devicedocumentsettings), [Complete-DeviceDispatch](#complete-devicedispatch), [Show-BenchWorkflowGuide](#show-benchworkflowguide), [Read-BenchCommand](#read-benchcommand), [Show-BuildBenchView](#show-buildbenchview), [Select-DeviceFromRecords](#select-devicefromrecords), [Select-DeviceType](#select-devicetype), [Show-RecoveryEvidenceReport](#show-recoveryevidencereport), [Show-ReturnToMainMenu](#show-returntomainmenu).

### ConvertTo-OptionalInteger

Parse an optional integer without evaluating PowerShell expressions.

Source: [autopilot-express.ps1:3273](autopilot-express.ps1#L3273). Internal entry-script function; source region: `Console Input and Technician Navigation`.

| Parameter | Declared Type   | Attributes | Default                        | Source Contract                                            |
| --------- | --------------- | ---------- | ------------------------------ | ---------------------------------------------------------- |
| `Value`   | `System.String` | `[string]` | No explicit default expression | Textual or numeric candidate supplied by a selection flow. |

Outputs and result contract:

Integer on successful conversion, otherwise null.

Named callers: [Select-Site](#select-site), [Show-SessionReportExport](#show-sessionreportexport), [Select-RemediationMenuItem](#select-remediationmenuitem), [Initialize-LiveTenantContext](#initialize-livetenantcontext), [Show-BuildBenchView](#show-buildbenchview), [Resolve-DeviceSelection](#resolve-deviceselection), [Select-DeviceType](#select-devicetype).

### Get-ConfiguredSerialPattern

Return the configured serial validation pattern or the compatibility default.

Source: [autopilot-express.ps1:3288](autopilot-express.ps1#L3288). Internal entry-script function; source region: `Console Input and Technician Navigation`.

No formal parameters declared. Captured state and enclosing scope may still be inputs.

Outputs and result contract:

Regular-expression string used by serial input validation; no device lookup.

Named callers: [ConvertTo-NormalisedSerialInput](#convertto-normalisedserialinput).

### Get-ConfiguredScannerSerialRules

Return non-null scanner normalisation rules from runtime configuration.

Source: [autopilot-express.ps1:3300](autopilot-express.ps1#L3300). Internal entry-script function; source region: `Console Input and Technician Navigation`.

No formal parameters declared. Captured state and enclosing scope may still be inputs.

Outputs and result contract:

Rule collection, empty when absent; no rule is executed here.

Other named commands: `Where-Object`.

Named callers: [ConvertTo-NormalisedSerialInput](#convertto-normalisedserialinput).

### Get-UriQueryParameterValues

Decode matching URI query values for configured scanner transformations.

Source: [autopilot-express.ps1:3310](autopilot-express.ps1#L3310). Internal entry-script function; source region: `Console Input and Technician Navigation`.

| Parameter | Declared Type   | Attributes                                                 | Default                        | Source Contract                                                                |
| --------- | --------------- | ---------------------------------------------------------- | ------------------------------ | ------------------------------------------------------------------------------ |
| `Query`   | `System.String` | `[Parameter(Mandatory)]` `[AllowEmptyString()]` `[string]` | No explicit default expression | Query text from the scanned URI; never executed or requested over the network. |
| `Name`    | `System.String` | `[Parameter(Mandatory)]` `[string]`                        | No explicit default expression | Configured query parameter name to match.                                      |

Outputs and result contract:

Matching decoded values in input order; does not infer a unique serial.

Named callers: [ConvertTo-NormalisedSerialInput](#convertto-normalisedserialinput).

### ConvertTo-NormalisedSerialInput

Validate literal serial input or apply an explicitly configured scanner rule.

Source: [autopilot-express.ps1:3338](autopilot-express.ps1#L3338). Internal entry-script function; source region: `Console Input and Technician Navigation`.

| Parameter    | Declared Type   | Attributes                          | Default                        | Source Contract                                                                          |
| ------------ | --------------- | ----------------------------------- | ------------------------------ | ---------------------------------------------------------------------------------------- |
| `InputValue` | `System.String` | `[Parameter(Mandatory)]` `[string]` | No explicit default expression | Raw technician/scanner text; control characters and invalid transformations are refused. |

Outputs and result contract:

Dictionary with Success, Serial, WasTransformed, RuleName and actionable Message.
Does not query Graph or create device records.

Named callers: [New-DeviceRecordObject](#new-devicerecordobject), [Read-NormalisedSerialInput](#read-normalisedserialinput).

### Read-NormalisedSerialInput

Read and validate a serial while preserving correction and cancellation behaviour.

Source: [autopilot-express.ps1:3389](autopilot-express.ps1#L3389). Internal entry-script function; source region: `Console Input and Technician Navigation`.

| Parameter     | Declared Type                                  | Attributes                          | Default                        | Source Contract                                            |
| ------------- | ---------------------------------------------- | ----------------------------------- | ------------------------------ | ---------------------------------------------------------- |
| `Prompt`      | `System.String`                                | `[Parameter(Mandatory)]` `[string]` | No explicit default expression | Accessible serial prompt text.                             |
| `Default`     | `System.String`                                | `[string]`                          | No explicit default expression | Previously entered serial offered during correction.       |
| `AllowCancel` | `System.Management.Automation.SwitchParameter` | `[switch]`                          | No explicit default expression | Permit the calling workflow's explicit cancellation input. |

Outputs and result contract:

Normalised serial, or null on allowed cancellation; invalid input re-prompts.

Other named commands: `Write-Host`.

Named callers: [Read-NewDeviceIdentityField](#read-newdeviceidentityfield).

### Select-Site

Select a configured site while retaining the current site as the default.

Source: [autopilot-express.ps1:3421](autopilot-express.ps1#L3421). Internal entry-script function; source region: `Console Input and Technician Navigation`.

| Parameter         | Declared Type   | Attributes | Default                        | Source Contract                              |
| ----------------- | --------------- | ---------- | ------------------------------ | -------------------------------------------- |
| `CurrentSiteCode` | `System.String` | `[string]` | No explicit default expression | Current site code offered to the technician. |

Outputs and result contract:

Configured site code; no tenant or persisted device state is changed here.

Other named commands: `Write-Host`.

Named callers: [Start-NewDeviceWorkflow](#start-newdeviceworkflow).

### Get-ConsoleTextWidth

Obtain a usable text width without requiring a console RawUI implementation.

Source: [autopilot-express.ps1:3451](autopilot-express.ps1#L3451). Internal entry-script function; source region: `Console Input and Technician Navigation`.

No formal parameters declared. Captured state and enclosing scope may still be inputs.

Outputs and result contract:

Width in columns, with a deterministic fallback for non-console hosts.

Named callers: [Get-ScreenFeedbackLines](#get-screenfeedbacklines), [Show-StatsTable](#show-statstable), [Show-BuildBenchTable](#show-buildbenchtable), [Show-BenchSectionBar](#show-benchsectionbar), [Get-BenchOptionLines](#get-benchoptionlines).

### Get-ScreenFeedbackLines

Wrap complete events at the current width, newest event first.

Source: [autopilot-express.ps1:3464](autopilot-express.ps1#L3464). Internal entry-script function; source region: `Console Input and Technician Navigation`.

| Parameter | Declared Type                    | Attributes                                                  | Default                        | Source Contract                                              |
| --------- | -------------------------------- | ----------------------------------------------------------- | ------------------------------ | ------------------------------------------------------------ |
| `State`   | `System.Collections.IDictionary` | `[Parameter(Mandatory)]` `[System.Collections.IDictionary]` | No explicit default expression | Transient events, each owning its original context and text. |

Outputs and result contract:

Display lines in natural order within each event; no evidence changes.

Other named commands: `Select-Object`, `Where-Object`.

Named callers: [Add-ScreenFeedback](#add-screenfeedback), [Write-StatsLine](#write-statsline), [Show-BenchSectionBar](#show-benchsectionbar), [Read-BenchCommand](#read-benchcommand), [Show-BuildBenchView](#show-buildbenchview).

### Add-ScreenFeedback

Retain five complete contextual events, not five rendered lines.

Source: [autopilot-express.ps1:3505](autopilot-express.ps1#L3505). Internal entry-script function; source region: `Console Input and Technician Navigation`.

| Parameter         | Declared Type                                  | Attributes                                                  | Default                        | Source Contract                                                                                |
| ----------------- | ---------------------------------------------- | ----------------------------------------------------------- | ------------------------------ | ---------------------------------------------------------------------------------------------- |
| `State`           | `System.Collections.IDictionary`               | `[Parameter(Mandatory)]` `[System.Collections.IDictionary]` | No explicit default expression | Screen-owned dictionary, never persisted as workflow evidence.                                 |
| `Text`            | `System.String[]`                              | `[AllowEmptyCollection()]` `[string[]]`                     | `@()`                          | Each string is one complete event; internal newlines stay ordered.                             |
| `Context`         | `System.String`                                | `[string]`                                                  | `''`                           | Position, serial, CI and action captured when the event occurred.                              |
| `RenderedContext` | `System.String`                                | `[AllowEmptyString()]` `[string]`                           | No explicit default expression | Exact context already captured in host output, used only to avoid duplicate identity prefixes. |
| `ContextIncluded` | `System.Management.Automation.SwitchParameter` | `[switch]`                                                  | No explicit default expression | The generated event already includes its identity; retain context without printing it twice.   |

Outputs and result contract:

None. Updates bounded screen feedback only; never durable workflow evidence.

Other named commands: `Get-Date`, `Select-Object`.

Named callers: [Invoke-AutopilotSequence](#invoke-autopilotsequence), [Receive-DeviceDocumentJob](#receive-devicedocumentjob), [Write-BenchFeedback](#write-benchfeedback).

### Get-MainMenuDefinition

Define each navigation level's keys, labels and stable actions together.

Source: [autopilot-express.ps1:3539](autopilot-express.ps1#L3539). Internal entry-script function; source region: `Console Input and Technician Navigation`.

| Parameter | Declared Type   | Attributes                                                                       | Default  | Source Contract                                                                 |
| --------- | --------------- | -------------------------------------------------------------------------------- | -------- | ------------------------------------------------------------------------------- |
| `Menu`    | `System.String` | `[ValidateSet('Main', 'Devices', 'Settings', 'Data', 'Information')]` `[string]` | `'Main'` | Main or one of the four caller-owned submenus. Zero is handled by the renderer. |

Outputs and result contract:

Menu entries used for both rendering and dispatch; no action is executed.

Named callers: [Show-MainMenu](#show-mainmenu).

### Get-NavigationMenuTitle

Resolve caller-owned navigation state to a consistent screen and return label.

Source: [autopilot-express.ps1:3602](autopilot-express.ps1#L3602). Internal entry-script function; source region: `Console Input and Technician Navigation`.

| Parameter | Declared Type   | Attributes | Default                  | Source Contract                                                                  |
| --------- | --------------- | ---------- | ------------------------ | -------------------------------------------------------------------------------- |
| `Menu`    | `System.String` | `[string]` | `$Script:NavigationMenu` | Empty or unknown legacy state resolves to Main Menu without changing navigation. |

Outputs and result contract:

Plain display title; no workflow or storage changes.

Named callers: [Show-MainMenu](#show-mainmenu), [Get-DeviceOutstanding](#get-deviceoutstanding), [Update-DeviceStatus](#update-devicestatus), [Read-PagedInformation](#read-pagedinformation), [Show-ReturnToMainMenu](#show-returntomainmenu).

### Show-DiagnosticLogFolder

Open the actual current transcript directory without guessing its storage root.

Source: [autopilot-express.ps1:3621](autopilot-express.ps1#L3621). Internal entry-script function; source region: `Console Input and Technician Navigation`.

No formal parameters declared. Captured state and enclosing scope may still be inputs.

Outputs and result contract:

Accessible path and an actionable warning if Explorer cannot be opened.

Other named commands: `Out-Null`, `Split-Path`, `Start-Process`, `Test-Path`, `Write-Host`, `Write-Warning`.

No statically named function caller in this inventory. Top-level, dynamic and callback invocation remain possible.

### Show-SessionInformation

Show read-only working hours, basic documentation or actual entry-point flags.

Source: [autopilot-express.ps1:3638](autopilot-express.ps1#L3638). Internal entry-script function; source region: `Console Input and Technician Navigation`.

| Parameter | Declared Type   | Attributes                                                                                         | Default                        | Source Contract                                                                             |
| --------- | --------------- | -------------------------------------------------------------------------------------------------- | ------------------------------ | ------------------------------------------------------------------------------------------- |
| `View`    | `System.String` | `[Parameter(Mandatory)]` `[ValidateSet('WorkPattern', 'Documentation', 'CommandLine')]` `[string]` | No explicit default expression | Information to page. Work-pattern editing and operational recovery are never executed here. |

Outputs and result contract:

Host pages only; returns to the caller without changing saved evidence.

No statically named function caller in this inventory. Top-level, dynamic and callback invocation remain possible.

### Show-CurrentDeviceList

Page every current-session record without selecting or changing a workflow.

Source: [autopilot-express.ps1:3706](autopilot-express.ps1#L3706). Internal entry-script function; source region: `Console Input and Technician Navigation`.

| Parameter | Declared Type                  | Attributes                             | Default                        | Source Contract                                                     |
| --------- | ------------------------------ | -------------------------------------- | ------------------------------ | ------------------------------------------------------------------- |
| `Records` | `System.Collections.Hashtable` | `[Parameter(Mandatory)]` `[hashtable]` | No explicit default expression | Current-session container, including completed and removed records. |

Outputs and result contract:

Sorted host text with serial, configuration item, site, type and status.

Other named commands: `ForEach-Object`, `Sort-Object`, `Where-Object`.

No statically named function caller in this inventory. Top-level, dynamic and callback invocation remain possible.

### Show-MainMenu

Render the shared main menu and resolve a validated selection to its action.

Source: [autopilot-express.ps1:3723](autopilot-express.ps1#L3723). Internal entry-script function; source region: `Console Input and Technician Navigation`.

| Parameter         | Declared Type   | Attributes                                                                       | Default                        | Source Contract                                                                            |
| ----------------- | --------------- | -------------------------------------------------------------------------------- | ------------------------------ | ------------------------------------------------------------------------------------------ |
| `CurrentSiteCode` | `System.String` | `[string]`                                                                       | No explicit default expression | Selected site included in the current-session display.                                     |
| `Menu`            | `System.String` | `[ValidateSet('Main', 'Devices', 'Settings', 'Data', 'Information')]` `[string]` | `'Main'`                       | Navigation level to render; the outer dispatcher owns transitions and caller return state. |

Outputs and result contract:

Internal menu action, including Exit; the outer loop owns navigation and execution.

Other named commands: `Where-Object`, `Write-Host`.

No statically named function caller in this inventory. Top-level, dynamic and callback invocation remain possible.

### Read-NewDeviceIdentityField

Validate one new-device identifier before confirmation, retaining correction defaults.

Source: [autopilot-express.ps1:3758](autopilot-express.ps1#L3758). Internal entry-script function; source region: `Console Input and Technician Navigation`.

| Parameter             | Declared Type                                  | Attributes                                                                  | Default                        | Source Contract                                                                                        |
| --------------------- | ---------------------------------------------- | --------------------------------------------------------------------------- | ------------------------------ | ------------------------------------------------------------------------------------------------------ |
| `Field`               | `System.String`                                | `[Parameter(Mandatory)]` `[ValidateSet('Serial', 'ConfigItem')]` `[string]` | No explicit default expression | Serial uses configured scanner rules; CI remains a textual identifier, not an invented numeric schema. |
| `Records`             | `System.Collections.Hashtable`                 | `[Parameter(Mandatory)]` `[hashtable]`                                      | No explicit default expression | Current record container used for early serial/configuration-item conflict checks.                     |
| `Default`             | `System.String`                                | `[string]`                                                                  | No explicit default expression | Previously entered value retained during the correction loop.                                          |
| `AllowExistingSerial` | `System.Management.Automation.SwitchParameter` | `[switch]`                                                                  | No explicit default expression | Route an existing serial to explicit lifecycle selection instead of creating a duplicate.              |

Outputs and result contract:

Valid trimmed identifier, or null on explicit cancellation. Existing records are never modified.

Other named commands: `Write-Host`.

Named callers: [Start-NewDeviceWorkflow](#start-newdeviceworkflow).

### Invoke-ExistingDeviceLifecycle

Restore a removed workflow or start a fresh cycle without erasing prior evidence.

Source: [autopilot-express.ps1:3804](autopilot-express.ps1#L3804). Internal entry-script function; source region: `Console Input and Technician Navigation`.

| Parameter  | Declared Type                    | Attributes                                                                | Default                        | Source Contract                                                                              |
| ---------- | -------------------------------- | ------------------------------------------------------------------------- | ------------------------------ | -------------------------------------------------------------------------------------------- |
| `Records`  | `System.Collections.Hashtable`   | `[Parameter(Mandatory)]` `[hashtable]`                                    | No explicit default expression | Owning session collection; detached changes are published only after guarded persistence.    |
| `Device`   | `System.Collections.IDictionary` | `[Parameter(Mandatory)]` `[System.Collections.IDictionary]`               | No explicit default expression | Unique selected record. Existing tenant ownership and attempt identities remain protected.   |
| `Action`   | `System.String`                  | `[Parameter(Mandatory)]` `[ValidateSet('Restore', 'Restart')]` `[string]` | No explicit default expression | Restore retains progress; Restart snapshots the old cycle and resets only current progress.  |
| `Position` | `System.Int32`                   | `[int]`                                                                   | `0`                            | Optional empty bench position saved in the same checkpoint; zero leaves placement unchanged. |

Outputs and result contract:

Changed and Summary dictionary. No Graph request, remote rollback or automatic replay occurs.

Other named commands: `Get-Date`, `Select-Object`, `Where-Object`, `Write-Host`.

Named callers: [Select-ExistingDeviceWorkflowAction](#select-existingdeviceworkflowaction).

### Select-ExistingDeviceWorkflowAction

Offer explicit resume, restore or restart without creating a duplicate serial.

Source: [autopilot-express.ps1:3896](autopilot-express.ps1#L3896). Internal entry-script function; source region: `Console Input and Technician Navigation`.

| Parameter  | Declared Type                    | Attributes                                                  | Default                        | Source Contract                                       |
| ---------- | -------------------------------- | ----------------------------------------------------------- | ------------------------------ | ----------------------------------------------------- |
| `Records`  | `System.Collections.Hashtable`   | `[Parameter(Mandatory)]` `[hashtable]`                      | No explicit default expression | Current session records owning the selected device.   |
| `Device`   | `System.Collections.IDictionary` | `[Parameter(Mandatory)]` `[System.Collections.IDictionary]` | No explicit default expression | Existing workflow selected by number or exact serial. |
| `Position` | `System.Int32`                   | `[int]`                                                     | `0`                            | Empty bench position, or zero for standalone use.     |

Outputs and result contract:

Boolean indicating successful selection; cancellation defaults to zero.

Other named commands: `Write-Host`.

Named callers: [Start-NewDeviceWorkflow](#start-newdeviceworkflow).

### Get-OffBenchDeviceRecord

List eligible existing records that are not already occupying bench positions.

Source: [autopilot-express.ps1:3928](autopilot-express.ps1#L3928). Internal entry-script function; source region: `Console Input and Technician Navigation`.

| Parameter | Declared Type                  | Attributes                             | Default                        | Source Contract                                                                          |
| --------- | ------------------------------ | -------------------------------------- | ------------------------------ | ---------------------------------------------------------------------------------------- |
| `Records` | `System.Collections.Hashtable` | `[Parameter(Mandatory)]` `[hashtable]` | No explicit default expression | Current record container; incomplete identities and occupied bench records are excluded. |

Outputs and result contract:

Serial-sorted record array. Existing history and state are not reset.

Other named commands: `ForEach-Object`, `Sort-Object`, `Where-Object`.

Named callers: [Start-NewDeviceWorkflow](#start-newdeviceworkflow).

### Select-EmptyBenchPosition

Require an available bench position without overwriting an occupied slot.

Source: [autopilot-express.ps1:3944](autopilot-express.ps1#L3944). Internal entry-script function; source region: `Console Input and Technician Navigation`.

No formal parameters declared. Captured state and enclosing scope may still be inputs.

Outputs and result contract:

Selected position number, or zero on cancellation/no available position.

Other named commands: `ForEach-Object`, `Sort-Object`, `Where-Object`, `Write-Host`.

Named callers: [Start-NewDeviceWorkflow](#start-newdeviceworkflow).

### Start-NewDeviceWorkflow

Capture a new local workflow after field validation and explicit confirmation.

Source: [autopilot-express.ps1:3962](autopilot-express.ps1#L3962). Internal entry-script function; source region: `Console Input and Technician Navigation`.

| Parameter         | Declared Type                                  | Attributes    | Default                        | Source Contract                                                             |
| ----------------- | ---------------------------------------------- | ------------- | ------------------------------ | --------------------------------------------------------------------------- |
| `CurrentSiteCode` | `System.String`                                | `[string]`    | No explicit default expression | Current configured site offered during induction.                           |
| `Records`         | `System.Collections.Hashtable`                 | `[hashtable]` | No explicit default expression | Current record container, updated only after confirmed identity validation. |
| `BenchRequired`   | `System.Management.Automation.SwitchParameter` | `[switch]`    | No explicit default expression | Require placement on the active bench rather than standalone induction.     |

Outputs and result contract:

Selected site code; existing device evidence is not reset or reassigned.

Other named commands: `Where-Object`, `Write-Host`.

Named callers: [Show-BuildBenchView](#show-buildbenchview).

### Get-WorkflowDisplayCode

Read a manifest display code without changing persisted step IDs.

Source: [autopilot-express.ps1:4094](autopilot-express.ps1#L4094). Internal entry-script function; source region: `Console Input and Technician Navigation`.

| Parameter | Declared Type                    | Attributes                                                  | Default                        | Source Contract                                                 |
| --------- | -------------------------------- | ----------------------------------------------------------- | ------------------------------ | --------------------------------------------------------------- |
| `Step`    | `System.Collections.IDictionary` | `[Parameter(Mandatory)]` `[System.Collections.IDictionary]` | No explicit default expression | Manifest definition; custom actions retain their configured ID. |

Outputs and result contract:

Display/selection code only. Persisted evidence always uses Step.Id.

Named callers: [Get-WorkflowStepLabel](#get-workflowsteplabel), [Get-WorkflowStepReference](#get-workflowstepreference), [Invoke-AutopilotSequence](#invoke-autopilotsequence), [Show-BuildBenchTable](#show-buildbenchtable), [Show-BenchWorkflowGuide](#show-benchworkflowguide), [Show-BuildBenchView](#show-buildbenchview).

### Get-WorkflowStepLabel

Label displayed actions while distinguishing historical persisted IDs.

Source: [autopilot-express.ps1:4108](autopilot-express.ps1#L4108). Internal entry-script function; source region: `Console Input and Technician Navigation`.

| Parameter | Declared Type                    | Attributes                                                  | Default                        | Source Contract                |
| --------- | -------------------------------- | ----------------------------------------------------------- | ------------------------------ | ------------------------------ |
| `Step`    | `System.Collections.IDictionary` | `[Parameter(Mandatory)]` `[System.Collections.IDictionary]` | No explicit default expression | Unchanged manifest definition. |

Outputs and result contract:

Human-readable code and name; no evidence is rewritten.

Named callers: [Show-WorkflowOutcome](#show-workflowoutcome), [Invoke-AutopilotSequence](#invoke-autopilotsequence), [Show-DeviceWorkflowStatus](#show-deviceworkflowstatus), [Show-BenchWorkflowGuide](#show-benchworkflowguide), [Show-BuildBenchView](#show-buildbenchview).

### Get-WorkflowStepReference

Explain prerequisite IDs using display letters and explicit saved-ID labels.

Source: [autopilot-express.ps1:4127](autopilot-express.ps1#L4127). Internal entry-script function; source region: `Console Input and Technician Navigation`.

| Parameter | Declared Type     | Attributes                              | Default | Source Contract                                                             |
| --------- | ----------------- | --------------------------------------- | ------- | --------------------------------------------------------------------------- |
| `StepIds` | `System.String[]` | `[AllowEmptyCollection()]` `[string[]]` | `@()`   | Persisted IDs; missing/custom definitions remain readable without mutation. |

Outputs and result contract:

Comma-separated references, or None for an empty list.

Named callers: [Show-DeviceWorkflowStatus](#show-deviceworkflowstatus), [Show-BenchWorkflowGuide](#show-benchworkflowguide).

### Show-WorkflowOutcome

Separate the current device's last outcome with text and optional colour.

Source: [autopilot-express.ps1:4146](autopilot-express.ps1#L4146). Internal entry-script function; source region: `Console Input and Technician Navigation`.

| Parameter | Declared Type                    | Attributes                                                  | Default                        | Source Contract                                                                           |
| --------- | -------------------------------- | ----------------------------------------------------------- | ------------------------------ | ----------------------------------------------------------------------------------------- |
| `Device`  | `System.Collections.IDictionary` | `[Parameter(Mandatory)]` `[System.Collections.IDictionary]` | No explicit default expression | Record whose serial/configuration item provide the result context.                        |
| `Step`    | `System.Collections.IDictionary` | `[Parameter(Mandatory)]` `[System.Collections.IDictionary]` | No explicit default expression | Manifest definition used for the displayed action label, not a new action request.        |
| `Result`  | `System.Collections.IDictionary` | `[Parameter(Mandatory)]` `[System.Collections.IDictionary]` | No explicit default expression | Returned evidence, shown only after successful persistence; submission is not completion. |

Outputs and result contract:

Host output only; no record or evidence changes.

Other named commands: `Write-Host`.

Named callers: [Invoke-AutopilotSequence](#invoke-autopilotsequence).

### Invoke-AutopilotSequence

Perform guarded manifest steps while retaining the selected device workflow.

Source: [autopilot-express.ps1:4181](autopilot-express.ps1#L4181). Internal entry-script function; source region: `Console Input and Technician Navigation`.

| Parameter           | Declared Type                    | Attributes                                                                                    | Default                        | Source Contract                                                                    |
| ------------------- | -------------------------------- | --------------------------------------------------------------------------------------------- | ------------------------------ | ---------------------------------------------------------------------------------- |
| `Records`           | `System.Collections.Hashtable`   | `[hashtable]`                                                                                 | No explicit default expression | Shared record container persisted after each explicitly selected workflow outcome. |
| `Device`            | `System.Collections.IDictionary` | `[System.Collections.IDictionary]`                                                            | No explicit default expression | Optional existing record supplied by Outstanding Work to avoid reselection.        |
| `ReturnDestination` | `System.String`                  | `[ValidateSet('Main menu', 'Build bench', 'Device Commands', 'Outstanding Work')]` `[string]` | `'Main menu'`                  | Caller-specific heading and return label; bench and main share this loop.          |
| `FeedbackState`     | `System.Collections.IDictionary` | `[System.Collections.IDictionary]`                                                            | No explicit default expression | Optional transient bench events; only saved step outcomes are appended.            |

Outputs and result contract:

Host output only. Failed storage stops the sequence instead of replaying the action.

Other named commands: `ForEach-Object`, `Select-Object`, `Where-Object`, `Write-Host`.

Named callers: [Get-DeviceOutstanding](#get-deviceoutstanding), [Show-BuildBenchView](#show-buildbenchview).

### Invoke-DeviceWorkflowPlan

Run preparation or recovery for one device with per-action save gates.

Source: [autopilot-express.ps1:4321](autopilot-express.ps1#L4321). Internal entry-script function; source region: `Console Input and Technician Navigation`.

| Parameter | Declared Type                  | Attributes                                                                | Default                        | Source Contract                                                               |
| --------- | ------------------------------ | ------------------------------------------------------------------------- | ------------------------------ | ----------------------------------------------------------------------------- |
| `Records` | `System.Collections.Hashtable` | `[Parameter(Mandatory)]` `[ValidateNotNull()]` `[hashtable]`              | No explicit default expression | Current session container whose Value collection owns the selected device.    |
| `Device`  | `System.Object`                | `[Parameter(Mandatory)]` `[ValidateNotNull()]`                            | No explicit default expression | Active device record selected once by the calling menu.                       |
| `Plan`    | `System.String`                | `[Parameter(Mandatory)]` `[ValidateSet('Prepare', 'Recover')]` `[string]` | No explicit default expression | Prepare stops before physical milestones; Recover retains manual reset gates. |

Outputs and result contract:

Dictionary containing Completed, Summary, Step and Result for menu feedback.

Other named commands: `Write-Host`.

Named callers: [Invoke-AutopilotSequence](#invoke-autopilotsequence), [Invoke-BenchSelectedCommand](#invoke-benchselectedcommand).

### Show-DeviceWorkflowStatus

Display one action per line with truthful completion and eligibility.

Source: [autopilot-express.ps1:4420](autopilot-express.ps1#L4420). Internal entry-script function; source region: `Console Input and Technician Navigation`.

| Parameter | Declared Type                    | Attributes                                                  | Default                        | Source Contract                                                 |
| --------- | -------------------------------- | ----------------------------------------------------------- | ------------------------------ | --------------------------------------------------------------- |
| `Device`  | `System.Collections.IDictionary` | `[Parameter(Mandatory)]` `[System.Collections.IDictionary]` | No explicit default expression | Tracked record; this view does not mutate progress or evidence. |

Outputs and result contract:

Host status/step text only; opening the view does not execute an action.

Other named commands: `Write-Host`.

Named callers: [Invoke-AutopilotSequence](#invoke-autopilotsequence), [Get-DeviceOutstanding](#get-deviceoutstanding).

### Get-DeviceOutstanding

Display outstanding records and open the explicitly selected device workflow.

Source: [autopilot-express.ps1:4455](autopilot-express.ps1#L4455). Internal entry-script function; source region: `Console Input and Technician Navigation`.

| Parameter | Declared Type                  | Attributes    | Default                        | Source Contract                          |
| --------- | ------------------------------ | ------------- | ------------------------------ | ---------------------------------------- |
| `Records` | `System.Collections.Hashtable` | `[hashtable]` | No explicit default expression | Shared current-session record container. |

Outputs and result contract:

Host output only. Returns control to the caller after selection or cancellation.

Other named commands: `Write-Host`.

No statically named function caller in this inventory. Top-level, dynamic and callback invocation remain possible.

### Update-DeviceStatus

Maintain device status while enforcing completion and dispatch-evidence safeguards.

Source: [autopilot-express.ps1:4484](autopilot-express.ps1#L4484). Internal entry-script function; source region: `Console Input and Technician Navigation`.

| Parameter | Declared Type                  | Attributes    | Default                        | Source Contract                                                                     |
| --------- | ------------------------------ | ------------- | ------------------------------ | ----------------------------------------------------------------------------------- |
| `Records` | `System.Collections.Hashtable` | `[hashtable]` | No explicit default expression | Mutable current-session container to validate and persist after a confirmed change. |

Outputs and result contract:

None. A valid change uses guarded persistence; cancellation/no-op leaves records unchanged.

Other named commands: `Get-Date`, `Write-Host`.

No statically named function caller in this inventory. Top-level, dynamic and callback invocation remain possible.

### Get-DeviceDispatchDate

Return only a proven dispatch instant for a currently completed device.

Source: [autopilot-express.ps1:4525](autopilot-express.ps1#L4525). Internal entry-script function; source region: `Console Input and Technician Navigation`.

| Parameter | Declared Type                    | Attributes                                                  | Default                        | Source Contract                                                             |
| --------- | -------------------------------- | ----------------------------------------------------------- | ------------------------------ | --------------------------------------------------------------------------- |
| `Device`  | `System.Collections.IDictionary` | `[Parameter(Mandatory)]` `[System.Collections.IDictionary]` | No explicit default expression | Loaded record; legacy overrides need matching completion snapshot evidence. |

Outputs and result contract:

DateTime; MinValue means dispatch has not been proved.

Named callers: [Get-DispatchStatsRows](#get-dispatchstatsrows), [Get-UserStats](#get-userstats), [Get-SessionReportRows](#get-sessionreportrows).

### Format-BuildElapsedTime

Format elapsed minutes as days and a valid HH:mm remainder.

Source: [autopilot-express.ps1:4550](autopilot-express.ps1#L4550). Internal entry-script function; source region: `Console Input and Technician Navigation`.

| Parameter | Declared Type   | Attributes    | Default                        | Source Contract                                                        |
| --------- | --------------- | ------------- | ------------------------------ | ---------------------------------------------------------------------- |
| `Minutes` | `System.Object` | None declared | No explicit default expression | Duration to display; invalid/absent values are not fabricated as zero. |

Outputs and result contract:

Dd HH:mm string or N/A, truncating only the displayed whole minutes.

Named callers: [Get-BuildDurationSummary](#get-builddurationsummary).

### Get-ImagingWorkPatternPath

Resolve the current user's mode-isolated work-pattern file in the active store.

Source: [autopilot-express.ps1:4565](autopilot-express.ps1#L4565). Internal entry-script function; source region: `Console Input and Technician Navigation`.

No formal parameters declared. Captured state and enclosing scope may still be inputs.

Outputs and result contract:

Absolute JSON path; no directory or file is created.

Other named commands: `Join-Path`.

Named callers: [Read-ImagingWorkPattern](#read-imagingworkpattern), [Save-ImagingWorkPatternChange](#save-imagingworkpatternchange).

### Assert-ImagingWorkPattern

Reject malformed, foreign-user or cross-mode work-pattern history.

Source: [autopilot-express.ps1:4576](autopilot-express.ps1#L4576). Internal entry-script function; source region: `Console Input and Technician Navigation`.

| Parameter     | Declared Type                  | Attributes                             | Default                        | Source Contract                                         |
| ------------- | ------------------------------ | -------------------------------------- | ------------------------------ | ------------------------------------------------------- |
| `WorkPattern` | `System.Collections.Hashtable` | `[Parameter(Mandatory)]` `[hashtable]` | No explicit default expression | Versioned dictionary with append-only calendar changes. |

Outputs and result contract:

None; invalid stored history throws rather than silently reverting to defaults.

Named callers: [Read-ImagingWorkPattern](#read-imagingworkpattern), [Get-ImagingWorkPatternProposal](#get-imagingworkpatternproposal).

### Read-ImagingWorkPattern

Load guarded work-pattern history without creating a default file.

Source: [autopilot-express.ps1:4605](autopilot-express.ps1#L4605). Internal entry-script function; source region: `Console Input and Technician Navigation`.

No formal parameters declared. Captured state and enclosing scope may still be inputs.

Outputs and result contract:

Current-user/mode dictionary; absent history uses the original weekday policy.

Other named commands: `ConvertFrom-Json`, `Get-Content`, `Test-Path`.

Named callers: [Save-ImagingWorkPatternChange](#save-imagingworkpatternchange), [Show-ImagingWorkPatternEditor](#show-imagingworkpatterneditor).

### Get-ImagingWorkPatternProposal

Propose an append-only schedule or non-imaging-day change without mutation.

Source: [autopilot-express.ps1:4623](autopilot-express.ps1#L4623). Internal entry-script function; source region: `Console Input and Technician Navigation`.

| Parameter     | Declared Type                  | Attributes                                                                                         | Default                        | Source Contract                                                                           |
| ------------- | ------------------------------ | -------------------------------------------------------------------------------------------------- | ------------------------------ | ----------------------------------------------------------------------------------------- |
| `WorkPattern` | `System.Collections.Hashtable` | `[Parameter(Mandatory)]` `[hashtable]`                                                             | No explicit default expression | Existing history, retained in full in the detached proposal.                              |
| `Date`        | `System.DateTime`              | `[Parameter(Mandatory)]` `[datetime]`                                                              | No explicit default expression | Effective schedule date or exact calendar day to mark.                                    |
| `Kind`        | `System.String`                | `[Parameter(Mandatory)]` `[ValidateSet('Schedule', 'Sick', 'RDO', 'WFH', 'Scheduled')]` `[string]` | No explicit default expression | Schedule changes apply forwards; Sick/RDO/WFH alone are allowed in the past.              |
| `Days`        | `System.Int32[]`               | `[AllowEmptyCollection()]` `[int[]]`                                                               | `@(1, 2, 3, 4, 5)`             | Scheduled weekday numbers, Sunday zero through Saturday six; empty means no planned days. |
| `Start`       | `System.String`                | `[string]`                                                                                         | `'08:30'`                      | Local same-day start in strict 24-hour HH:mm notation.                                    |
| `End`         | `System.String`                | `[string]`                                                                                         | `'17:30'`                      | Local same-day finish, strictly later than Start; overnight shifts are not supported.     |
| `Now`         | `System.DateTime`              | `[datetime]`                                                                                       | `(Get-Date)`                   | Current local instant; supplied explicitly only for deterministic offline tests.          |

Outputs and result contract:

New dictionary; neither existing history nor device events are changed.

Other named commands: `Get-Date`, `Sort-Object`.

Named callers: [Save-ImagingWorkPatternChange](#save-imagingworkpatternchange), [Show-ImagingWorkPatternEditor](#show-imagingworkpatterneditor).

### Get-ImagingWorkWindow

Resolve the effective weekly schedule and latest exact-day marking.

Source: [autopilot-express.ps1:4656](autopilot-express.ps1#L4656). Internal entry-script function; source region: `Console Input and Technician Navigation`.

| Parameter     | Declared Type                  | Attributes                            | Default                        | Source Contract                                                             |
| ------------- | ------------------------------ | ------------------------------------- | ------------------------------ | --------------------------------------------------------------------------- |
| `Date`        | `System.DateTime`              | `[Parameter(Mandatory)]` `[datetime]` | No explicit default expression | Local calendar day; future revisions never affect an earlier date.          |
| `WorkPattern` | `System.Collections.Hashtable` | `[hashtable]`                         | No explicit default expression | Validated append-only history, or null for original Monday-Friday defaults. |

Outputs and result contract:

Working/Blocked flags, day kind and local start/end minute offsets.

Named callers: [Get-ImagingWorkPatternLines](#get-imagingworkpatternlines), [Get-ImagingWorkingMinutes](#get-imagingworkingminutes).

### Save-ImagingWorkPatternChange

Append an approved change under the active reservation and publish only after save.

Source: [autopilot-express.ps1:4684](autopilot-express.ps1#L4684). Internal entry-script function; source region: `Console Input and Technician Navigation`.

| Parameter | Declared Type                  | Attributes                             | Default                        | Source Contract                                                          |
| --------- | ------------------------------ | -------------------------------------- | ------------------------------ | ------------------------------------------------------------------------ |
| `Change`  | `System.Collections.Hashtable` | `[Parameter(Mandatory)]` `[hashtable]` | No explicit default expression | Validated date/kind/hours arguments passed to the pure proposal builder. |

Outputs and result contract:

None. Failed saves retain the old in-memory profile and recovery evidence.

Other named commands: `ConvertTo-Json`.

Named callers: [Show-ImagingWorkPatternEditor](#show-imagingworkpatterneditor).

### Get-ImagingWorkPatternLines

Render the current schedule and complete append-only change history.

Source: [autopilot-express.ps1:4704](autopilot-express.ps1#L4704). Internal entry-script function; source region: `Console Input and Technician Navigation`.

| Parameter     | Declared Type                  | Attributes    | Default                        | Source Contract                                                        |
| ------------- | ------------------------------ | ------------- | ------------------------------ | ---------------------------------------------------------------------- |
| `WorkPattern` | `System.Collections.Hashtable` | `[hashtable]` | No explicit default expression | Current-user schedule history; null retains original weekday defaults. |

Outputs and result contract:

Accessible text lines, with newest recorded changes first.

Other named commands: `ForEach-Object`, `Get-Date`, `Where-Object`.

Named callers: [Show-SessionInformation](#show-sessioninformation), [Show-ImagingWorkPatternEditor](#show-imagingworkpatterneditor).

### Show-ImagingWorkPatternEditor

Edit future/current schedules and append authorised past-day markings.

Source: [autopilot-express.ps1:4731](autopilot-express.ps1#L4731). Internal entry-script function; source region: `Console Input and Technician Navigation`.

No formal parameters declared. Captured state and enclosing scope may still be inputs.

Outputs and result contract:

Host screens only; returns to Settings without calling another menu.

Other named commands: `ForEach-Object`, `Get-Date`, `Write-Host`.

No statically named function caller in this inventory. Top-level, dynamic and callback invocation remain possible.

### Get-ImagingWorkingMinutes

Calculate schedule-adjusted elapsed imaging time using local calendar days.

Source: [autopilot-express.ps1:4790](autopilot-express.ps1#L4790). Internal entry-script function; source region: `Console Input and Technician Navigation`.

| Parameter | Declared Type                    | Attributes                                                  | Default                        | Source Contract                                                                      |
| --------- | -------------------------------- | ----------------------------------------------------------- | ------------------------------ | ------------------------------------------------------------------------------------ |
| `Device`  | `System.Collections.IDictionary` | `[Parameter(Mandatory)]` `[System.Collections.IDictionary]` | No explicit default expression | Record with original induction, attempts, current steps and optional session starts. |
| `End`     | `System.DateTime`                | `[Parameter(Mandatory)]` `[datetime]`                       | No explicit default expression | Proven dispatch instant; missing or negative intervals return null.                  |

Outputs and result contract:

Double minutes or null. Original records and timestamps are not changed.

Other named commands: `Select-Object`, `Sort-Object`, `Where-Object`.

Named callers: [Get-DispatchStatsRows](#get-dispatchstatsrows), [Get-SessionReportRows](#get-sessionreportrows).

### Register-ImagingSessionStart

Record this user's session load for every unfinished device without altering actions.

Source: [autopilot-express.ps1:4865](autopilot-express.ps1#L4865). Internal entry-script function; source region: `Console Input and Technician Navigation`.

| Parameter   | Declared Type     | Attributes                              | Default                        | Source Contract                                                              |
| ----------- | ----------------- | --------------------------------------- | ------------------------------ | ---------------------------------------------------------------------------- |
| `Records`   | `System.Object[]` | `[AllowEmptyCollection()]` `[object[]]` | `@()`                          | Loaded current-user records; completed and removed devices remain unchanged. |
| `Timestamp` | `System.DateTime` | `[Parameter(Mandatory)]` `[datetime]`   | No explicit default expression | Actual session-load instant, not inferred from file modification times.      |

Outputs and result contract:

Boolean indicating whether metadata changed; the caller performs the guarded save.

Other named commands: `Get-Date`, `Where-Object`.

Named callers: [Initialize-SessionState](#initialize-sessionstate).

### Get-BuildDurationSummary

Calculate duration aggregates before rounding display values.

Source: [autopilot-express.ps1:4889](autopilot-express.ps1#L4889). Internal entry-script function; source region: `Console Input and Technician Navigation`.

| Parameter | Declared Type     | Attributes                              | Default | Source Contract                                        |
| --------- | ----------------- | --------------------------------------- | ------- | ------------------------------------------------------ |
| `Minutes` | `System.Double[]` | `[AllowEmptyCollection()]` `[double[]]` | `@()`   | Valid duration samples from proven dispatched records. |

Outputs and result contract:

Average, Min and Max display strings; empty samples produce N/A fields.

Other named commands: `Measure-Object`.

Named callers: [Get-DispatchStatsRows](#get-dispatchstatsrows), [Show-StatsTable](#show-statstable).

### Get-DispatchStatsRows

Count distinct dispatched records by local dispatch day and retain valid duration samples.

Source: [autopilot-express.ps1:4904](autopilot-express.ps1#L4904). Internal entry-script function; source region: `Console Input and Technician Navigation`.

| Parameter | Declared Type     | Attributes                              | Default | Source Contract                                                               |
| --------- | ----------------- | --------------------------------------- | ------- | ----------------------------------------------------------------------------- |
| `Records` | `System.Object[]` | `[AllowEmptyCollection()]` `[object[]]` | `@()`   | Local records only; removed, incomplete and unproved dispatches are excluded. |

Outputs and result contract:

Newest-first daily dictionaries; no record or evidence is modified.

Other named commands: `Get-Date`, `Sort-Object`.

Named callers: [Get-StatsRows](#get-statsrows).

### Get-UserStats

Render dispatch-day statistics using the same eligible records for every breakdown.

Source: [autopilot-express.ps1:4942](autopilot-express.ps1#L4942). Internal entry-script function; source region: `Console Input and Technician Navigation`.

| Parameter         | Declared Type                  | Attributes    | Default                        | Source Contract                                                                        |
| ----------------- | ------------------------------ | ------------- | ------------------------------ | -------------------------------------------------------------------------------------- |
| `Records`         | `System.Collections.Hashtable` | `[hashtable]` | No explicit default expression | Current session record container; removed/incomplete/unproven dispatches are excluded. |
| `CurrentSiteCode` | `System.String`                | `[string]`    | `''`                           | Current session site for the opening week-to-date and all-time tables.                 |
| `AsOf`            | `System.DateTime`              | `[datetime]`  | `(Get-Date)`                   | Local reference date for Monday-to-Sunday weeks; defaults to today.                    |

Outputs and result contract:

Accessible wide tables or narrow labelled rows with duration/missing-data disclosure.
Does not infer historical dispatch dates from automatic completion.

Other named commands: `ForEach-Object`, `Get-Date`, `Sort-Object`, `Where-Object`.

No statically named function caller in this inventory. Top-level, dynamic and callback invocation remain possible.

### Write-StatsLine

Wrap statistics and menu choices without losing labels or disclosures.

Source: [autopilot-express.ps1:4972](autopilot-express.ps1#L4972). Nested in `Get-UserStats`; its enclosing scope is part of the contract.

| Parameter | Declared Type   | Attributes | Default                        | Source Contract                                                 |
| --------- | --------------- | ---------- | ------------------------------ | --------------------------------------------------------------- |
| `Text`    | `System.String` | `[string]` | No explicit default expression | Complete statistics line passed to the shared feedback wrapper. |

Outputs and result contract:

Host text split into readable terminal-width lines.

Other named commands: `Write-Host`.

Named callers: [Get-UserStats](#get-userstats), [Show-StatsTable](#show-statstable).

### Show-StatsTable

Render one date-sorted statistics group in wide or labelled narrow layout.

Source: [autopilot-express.ps1:4992](autopilot-express.ps1#L4992). Nested in `Get-UserStats`; its enclosing scope is part of the contract.

| Parameter | Declared Type   | Attributes    | Default                        | Source Contract                                  |
| --------- | --------------- | ------------- | ------------------------------ | ------------------------------------------------ |
| `Rows`    | `System.Object` | None declared | No explicit default expression | Precomputed daily counts and duration summaries. |
| `Title`   | `System.String` | `[string]`    | No explicit default expression | Overall or site group name shown above the rows. |

Outputs and result contract:

Host text only; display truncation does not change duration calculations.

Other named commands: `ForEach-Object`, `Measure-Object`, `Write-Host`.

Named callers: [Get-UserStats](#get-userstats).

### Get-StatsRows

Build daily aggregates from the enclosing already-eligible dispatched records.

Source: [autopilot-express.ps1:5035](autopilot-express.ps1#L5035). Nested in `Get-UserStats`; its enclosing scope is part of the contract.

| Parameter      | Declared Type     | Attributes    | Default                        | Source Contract                                             |
| -------------- | ----------------- | ------------- | ------------------------------ | ----------------------------------------------------------- |
| `InputRecords` | `System.Object`   | None declared | No explicit default expression | Overall or site-filtered proven dispatch records.           |
| `From`         | `System.DateTime` | `[datetime]`  | `[datetime]::MinValue`         | Inclusive local start date, with no lower bound by default. |
| `Until`        | `System.DateTime` | `[datetime]`  | `[datetime]::MaxValue`         | Exclusive local end date, with no upper bound by default.   |

Outputs and result contract:

Newest-first daily summary rows with matching counts and duration samples.

Other named commands: `Where-Object`.

Named callers: [Get-UserStats](#get-userstats).

### Get-SessionReportRows

Project current local records without changing workflow or dispatch evidence.

Source: [autopilot-express.ps1:5109](autopilot-express.ps1#L5109). Internal entry-script function; source region: `Console Input and Technician Navigation`.

| Parameter | Declared Type     | Attributes                              | Default | Source Contract                                                                              |
| --------- | ----------------- | --------------------------------------- | ------- | -------------------------------------------------------------------------------------------- |
| `Records` | `System.Object[]` | `[AllowEmptyCollection()]` `[object[]]` | `@()`   | Current-session records, including removed and unfinished work; stable IDs are deduplicated. |

Outputs and result contract:

Ordered report objects. Dispatch uses existing evidence guards, not completed status alone.

Other named commands: `Sort-Object`.

Named callers: [Show-SessionReportExport](#show-sessionreportexport).

### ConvertTo-SessionReportContent

Encode a detached report as spreadsheet-safe CSV or script-free accessible HTML.

Source: [autopilot-express.ps1:5163](autopilot-express.ps1#L5163). Internal entry-script function; source region: `Console Input and Technician Navigation`.

| Parameter | Declared Type     | Attributes                                | Default | Source Contract                                                                        |
| --------- | ----------------- | ----------------------------------------- | ------- | -------------------------------------------------------------------------------------- |
| `Rows`    | `System.Object[]` | `[AllowEmptyCollection()]` `[object[]]`   | `@()`   | Objects returned by Get-SessionReportRows; original property values are not changed.   |
| `Format`  | `System.String`   | `[ValidateSet('CSV', 'HTML')]` `[string]` | `'CSV'` | CSV prefixes potentially executable spreadsheet text; HTML encodes every dynamic cell. |

Outputs and result contract:

Complete document string, or empty text for an empty report. No files are written.

Other named commands: `ConvertTo-Csv`.

Named callers: [Export-SessionReport](#export-sessionreport).

### Export-SessionReport

Save a unique current-session report outside operational evidence storage.

Source: [autopilot-express.ps1:5206](autopilot-express.ps1#L5206). Internal entry-script function; source region: `Console Input and Technician Navigation`.

| Parameter | Declared Type     | Attributes                                | Default | Source Contract                                                                 |
| --------- | ----------------- | ----------------------------------------- | ------- | ------------------------------------------------------------------------------- |
| `Rows`    | `System.Object[]` | `[AllowEmptyCollection()]` `[object[]]`   | `@()`   | Detached report projection; empty input performs no directory or file creation. |
| `Format`  | `System.String`   | `[ValidateSet('CSV', 'HTML')]` `[string]` | `'CSV'` | Requested CSV or HTML document format.                                          |

Outputs and result contract:

Verified report path, or null for no data. Existing reports are not overwritten.

Other named commands: `Get-Date`, `Join-Path`, `Test-Path`.

Named callers: [Show-SessionReportExport](#show-sessionreportexport).

### Show-SessionReportExport

Preview and explicitly confirm a local export, then return to Data Settings.

Source: [autopilot-express.ps1:5233](autopilot-express.ps1#L5233). Internal entry-script function; source region: `Console Input and Technician Navigation`.

| Parameter | Declared Type                  | Attributes                             | Default                        | Source Contract                                                                      |
| --------- | ------------------------------ | -------------------------------------- | ------------------------------ | ------------------------------------------------------------------------------------ |
| `Records` | `System.Collections.Hashtable` | `[Parameter(Mandatory)]` `[hashtable]` | No explicit default expression | Current session container only; no tenant, archive or shared audit discovery occurs. |

Outputs and result contract:

Host output and a verified report file after confirmation. Workflow evidence is untouched.

Other named commands: `Write-Host`.

No statically named function caller in this inventory. Top-level, dynamic and callback invocation remain possible.

### Read-PagedInformation

Reuse the Steps List text pager for caller-owned information navigation.

Source: [autopilot-express.ps1:5278](autopilot-express.ps1#L5278). Internal entry-script function; source region: `Console Input and Technician Navigation`.

| Parameter           | Declared Type                    | Attributes                                                                                                                                                                      | Default                        | Source Contract                                                   |
| ------------------- | -------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------ | ----------------------------------------------------------------- |
| `Title`             | `System.String`                  | `[Parameter(Mandatory)]` `[ValidateNotNullOrEmpty()]` `[string]`                                                                                                                | No explicit default expression | Screen name retained across pages and window resizes.             |
| `Lines`             | `System.String[]`                | `[AllowEmptyCollection()]` `[string[]]`                                                                                                                                         | `@()`                          | Plain terminal text, not Markdown markup.                         |
| `Options`           | `System.Collections.Hashtable[]` | `[AllowEmptyCollection()]` `[hashtable[]]`                                                                                                                                      | `@()`                          | Additional command dictionaries containing Code and Label.        |
| `ReturnDestination` | `System.String`                  | `[ValidateSet('main menu', 'About', 'Build bench', 'Device Commands', 'Session and Script Settings', 'Data Settings', 'Script Information', 'Work Pattern Editor')]` `[string]` | `'main menu'`                  | Visible caller name; this helper never redirects to another menu. |

Outputs and result contract:

Selected command code; zero returns to the calling screen.

Other named commands: `ForEach-Object`, `Write-Host`.

Named callers: [Show-SessionInformation](#show-sessioninformation), [Show-CurrentDeviceList](#show-currentdevicelist), [Show-ImagingWorkPatternEditor](#show-imagingworkpatterneditor), [Show-AboutScript](#show-aboutscript), [Show-EnhancementsQuestions](#show-enhancementsquestions), [Show-BuildBenchView](#show-buildbenchview), [Show-RecoveryEvidenceReport](#show-recoveryevidencereport).

### Show-AboutScript

Display editable script information without accessing tenant services.

Source: [autopilot-express.ps1:5319](autopilot-express.ps1#L5319). Internal entry-script function; source region: `Console Input and Technician Navigation`.

No formal parameters declared. Captured state and enclosing scope may still be inputs.

Outputs and result contract:

Host pages only; the explicit README command opens the maintained guide without waiting.

Other named commands: `Start-Process`, `Test-Path`, `Where-Object`.

No statically named function caller in this inventory. Top-level, dynamic and callback invocation remain possible.

### Show-EnhancementsQuestions

Display the status-labelled enhancement catalogue through the shared pager.

Source: [autopilot-express.ps1:5379](autopilot-express.ps1#L5379). Internal entry-script function; source region: `Console Input and Technician Navigation`.

| Parameter           | Declared Type   | Attributes                                                             | Default       | Source Contract                                                                      |
| ------------------- | --------------- | ---------------------------------------------------------------------- | ------------- | ------------------------------------------------------------------------------------ |
| `ReturnDestination` | `System.String` | `[ValidateSet('main menu', 'About', 'Script Information')]` `[string]` | `'main menu'` | Caller name used for accessible return guidance; does not activate planned features. |

Outputs and result contract:

Host output only; returns to its caller, including About, after paging or cancellation.

Named callers: [Show-AboutScript](#show-aboutscript).

### Save-BuildBenchState

Save current bench state unless an unresolved checkpoint blocks it.

Source: [autopilot-express.ps1:5405](autopilot-express.ps1#L5405). Internal entry-script function; source region: `Session Setup, Definitions and Graph Transport`.

| Parameter         | Declared Type   | Attributes | Default                        | Source Contract                                                            |
| ----------------- | --------------- | ---------- | ------------------------------ | -------------------------------------------------------------------------- |
| `CheckpointToken` | `System.String` | `[string]` | No explicit default expression | Internal token accepted only within the owning record writer's save scope. |
| `ProposedContent` | `System.String` | `[string]` | No explicit default expression | Exact staged bench JSON; requires the active token and matching marker.    |

Outputs and result contract:

None. Validates/persists bench state through the guarded UTF-8 writer.

Other named commands: `ConvertFrom-Json`, `ConvertTo-Json`, `Get-Content`, `Get-Variable`.

Named callers: [Write-UserDeviceRecords](#write-userdevicerecords), [Show-BuildBenchView](#show-buildbenchview).

### Get-BuildBenchState

Load and validate the current session's linked bench state.

Source: [autopilot-express.ps1:5441](autopilot-express.ps1#L5441). Internal entry-script function; source region: `Session Setup, Definitions and Graph Transport`.

No formal parameters declared. Captured state and enclosing scope may still be inputs.

Outputs and result contract:

Normalised bench dictionary, or a fresh inactive default when no file exists.
Malformed or conflicting existing evidence throws instead of silently resetting it.

Other named commands: `ConvertFrom-Json`, `Get-Content`, `Test-Path`.

Named callers: [Initialize-LocalSessionForResume](#initialize-localsessionforresume), [Initialize-SessionState](#initialize-sessionstate).

### Show-SessionArchive

Select and archive this user's current-mode resumable session without deleting history.

Source: [autopilot-express.ps1:5481](autopilot-express.ps1#L5481). Internal entry-script function; source region: `Session Setup, Definitions and Graph Transport`.

| Parameter | Declared Type                  | Attributes                             | Default                        | Source Contract                                                                          |
| --------- | ------------------------------ | -------------------------------------- | ------------------------------ | ---------------------------------------------------------------------------------------- |
| `Records` | `System.Collections.Hashtable` | `[Parameter(Mandatory)]` `[hashtable]` | No explicit default expression | Current user/mode record container; other users, audit and recent accounts are retained. |

Outputs and result contract:

True only after the selected session was archived successfully. Errors propagate.

Other named commands: `Test-Path`, `Where-Object`, `Write-Host`.

No statically named function caller in this inventory. Top-level, dynamic and callback invocation remain possible.

### Initialize-SessionState

Offer guarded current-session resume or archive before loading records.

Source: [autopilot-express.ps1:5521](autopilot-express.ps1#L5521). Internal entry-script function; source region: `Session Setup, Definitions and Graph Transport`.

No formal parameters declared. Captured state and enclosing scope may still be inputs.

Outputs and result contract:

Current record array or empty new-session array. Never authenticates or replays actions.

Other named commands: `Get-Date`, `Test-Path`.

No statically named function caller in this inventory. Top-level, dynamic and callback invocation remain possible.

### Get-SessionDefaultSiteCode

Choose the initial site from bench, recent records or the configured first site.

Source: [autopilot-express.ps1:5564](autopilot-express.ps1#L5564). Internal entry-script function; source region: `Session Setup, Definitions and Graph Transport`.

| Parameter | Declared Type                    | Attributes                         | Default                        | Source Contract                                                    |
| --------- | -------------------------------- | ---------------------------------- | ------------------------------ | ------------------------------------------------------------------ |
| `Records` | `System.Collections.IEnumerable` | `[System.Collections.IEnumerable]` | No explicit default expression | Loaded record array used only when bench context supplies no site. |

Outputs and result contract:

Site code suggestion; no record or tenant mutation.

Other named commands: `Select-Object`, `Sort-Object`.

No statically named function caller in this inventory. Top-level, dynamic and callback invocation remain possible.

### Get-ConfiguredSearchLimit

Read the configured directory-result limit, defaulting to 15.

Source: [autopilot-express.ps1:5583](autopilot-express.ps1#L5583). Internal entry-script function; source region: `Session Setup, Definitions and Graph Transport`.

No formal parameters declared. Captured state and enclosing scope may still be inputs.

Outputs and result contract:

Integer search limit; runtime validation owns configuration acceptance.

Named callers: [Search-LiveDirectoryUsers](#search-livedirectoryusers).

### Get-ConfiguredDirectorySearchPageLimit

Returns the bounded number of Graph pages permitted per user search.

Source: [autopilot-express.ps1:5594](autopilot-express.ps1#L5594). Internal entry-script function; source region: `Session Setup, Definitions and Graph Transport`.

No formal parameters declared. Captured state and enclosing scope may still be inputs.

Outputs and result contract:

Integer from 1 to 100. Throws when a configured value is invalid.

Named callers: [Search-LiveDirectoryUsers](#search-livedirectoryusers).

### Get-ConfiguredRecentUserLimit

Read the configured recent-account limit, defaulting to eight.

Source: [autopilot-express.ps1:5612](autopilot-express.ps1#L5612). Internal entry-script function; source region: `Session Setup, Definitions and Graph Transport`.

No formal parameters declared. Captured state and enclosing scope may still be inputs.

Outputs and result contract:

Integer history limit; does not load or persist account identities.

Named callers: [Get-RecentUsers](#get-recentusers), [Add-RecentUser](#add-recentuser).

### Get-ConfiguredDeploymentProfileDisplayName

Read the required deployment-profile display name without guessing a tenant value.

Source: [autopilot-express.ps1:5623](autopilot-express.ps1#L5623). Internal entry-script function; source region: `Session Setup, Definitions and Graph Transport`.

No formal parameters declared. Captured state and enclosing scope may still be inputs.

Outputs and result contract:

Configured string, or empty string when absent.

Named callers: [Invoke-StepValidateDeploymentProfile](#invoke-stepvalidatedeploymentprofile).

### Get-ConfiguredPreProvisioningGroupDisplayName

Read the configured pre-provisioning group name for exact resolution.

Source: [autopilot-express.ps1:5634](autopilot-express.ps1#L5634). Internal entry-script function; source region: `Session Setup, Definitions and Graph Transport`.

No formal parameters declared. Captured state and enclosing scope may still be inputs.

Outputs and result contract:

Display-name string or empty string; name alone is not verified group identity.

Named callers: [Get-WorkflowStepLabel](#get-workflowsteplabel), [Invoke-LiveStartupRead](#invoke-livestartupread), [Get-LivePreProvisioningGroup](#get-livepreprovisioninggroup), [Invoke-PreProvisioningMembershipChange](#invoke-preprovisioningmembershipchange).

### Get-ConfiguredMissingSerialHandoffNote

Read missing-serial guidance without assuming an import completed.

Source: [autopilot-express.ps1:5645](autopilot-express.ps1#L5645). Internal entry-script function; source region: `Session Setup, Definitions and Graph Transport`.

No formal parameters declared. Captured state and enclosing scope may still be inputs.

Outputs and result contract:

Configured guidance, or the external-upload compatibility message.

Named callers: [Invoke-StepResolveAutopilotDevice](#invoke-stepresolveautopilotdevice).

### Get-ConfiguredTechnicianPrefixes

Read permitted account-name prefixes for technician selection.

Source: [autopilot-express.ps1:5656](autopilot-express.ps1#L5656). Internal entry-script function; source region: `Session Setup, Definitions and Graph Transport`.

No formal parameters declared. Captured state and enclosing scope may still be inputs.

Outputs and result contract:

Prefix collection, defaulting to C and E; not role or authorisation proof.

Named callers: [Test-DirectoryUserMatchesConfiguredPrefixes](#test-directoryusermatchesconfiguredprefixes), [Get-DirectoryUserEligibilityMessage](#get-directoryusereligibilitymessage).

### Get-ConfiguredGraphScopes

Read the configured delegated scope request without adding permissions at runtime.

Source: [autopilot-express.ps1:5668](autopilot-express.ps1#L5668). Internal entry-script function; source region: `Session Setup, Definitions and Graph Transport`.

No formal parameters declared. Captured state and enclosing scope may still be inputs.

Outputs and result contract:

Scope collection with legacy fallback; requested scopes do not prove consent.

Named callers: [Assert-DeviceRemediationAccess](#assert-deviceremediationaccess), [Initialize-GraphSession](#initialize-graphsession).

### Get-ConfiguredGraphModules

Read the Graph SDK modules needed by the configured workflow.

Source: [autopilot-express.ps1:5689](autopilot-express.ps1#L5689). Internal entry-script function; source region: `Session Setup, Definitions and Graph Transport`.

No formal parameters declared. Captured state and enclosing scope may still be inputs.

Outputs and result contract:

Module-name collection, defaulting to Authentication and Enrollment.

Named callers: [Import-RequiredGraphModules](#import-requiredgraphmodules).

### Get-EmptyGraphSession

Initialise disconnected Graph state without retaining tokens or SDK contexts.

Source: [autopilot-express.ps1:5701](autopilot-express.ps1#L5701). Internal entry-script function; source region: `Session Setup, Definitions and Graph Transport`.

No formal parameters declared. Captured state and enclosing scope may still be inputs.

Outputs and result contract:

Ordered session dictionary with empty account, tenant, scope and capability evidence.

Named callers: [Initialize-GraphSession](#initialize-graphsession), [Close-GraphSession](#close-graphsession).

### Get-EnabledManifestSteps

Return enabled steps in validated manifest order.

Source: [autopilot-express.ps1:5721](autopilot-express.ps1#L5721). Internal entry-script function; source region: `Session Setup, Definitions and Graph Transport`.

No formal parameters declared. Captured state and enclosing scope may still be inputs.

Outputs and result contract:

Step array; does not evaluate per-device eligibility or execute handlers.

Other named commands: `Where-Object`.

Named callers: [Invoke-ExistingDeviceLifecycle](#invoke-existingdevicelifecycle), [Invoke-AutopilotSequence](#invoke-autopilotsequence), [Show-DeviceWorkflowStatus](#show-deviceworkflowstatus), [Get-ManifestActionStepId](#get-manifestactionstepid), [Get-ConfirmedApplicationBaseline](#get-confirmedapplicationbaseline), [Write-ManifestStepResult](#write-manifeststepresult), [Test-ManifestStepCompleted](#test-manifeststepcompleted), [Get-EligibleManifestSteps](#get-eligiblemanifeststeps), [Get-DispatchBlockingManifestSteps](#get-dispatchblockingmanifeststeps), [Undo-LatestTechnicianConfirmation](#undo-latesttechnicianconfirmation), [Show-BenchWorkflowGuide](#show-benchworkflowguide).

### Get-ManifestStepDefinition

Resolve a manifest ID without confusing its display code with storage identity.

Source: [autopilot-express.ps1:5731](autopilot-express.ps1#L5731). Internal entry-script function; source region: `Session Setup, Definitions and Graph Transport`.

| Parameter | Declared Type   | Attributes                          | Default                        | Source Contract                              |
| --------- | --------------- | ----------------------------------- | ------------------------------ | -------------------------------------------- |
| `StepId`  | `System.String` | `[Parameter(Mandatory)]` `[string]` | No explicit default expression | Stored identity from the validated manifest. |

Outputs and result contract:

First matching step, or null; no workflow state changes.

Other named commands: `Select-Object`, `Where-Object`.

Named callers: [Get-WorkflowStepReference](#get-workflowstepreference), [Invoke-AutopilotSequence](#invoke-autopilotsequence), [Invoke-DeviceWorkflowPlan](#invoke-deviceworkflowplan), [Show-BuildBenchTable](#show-buildbenchtable), [Show-BuildBenchView](#show-buildbenchview).

### Get-ManifestActionStepId

Resolve a safety-critical action to its current enabled manifest step ID.

Source: [autopilot-express.ps1:5744](autopilot-express.ps1#L5744). Internal entry-script function; source region: `Session Setup, Definitions and Graph Transport`.

| Parameter    | Declared Type   | Attributes                                                       | Default                        | Source Contract                                                     |
| ------------ | --------------- | ---------------------------------------------------------------- | ------------------------------ | ------------------------------------------------------------------- |
| `ActionName` | `System.String` | `[Parameter(Mandatory)]` `[ValidateNotNullOrEmpty()]` `[string]` | No explicit default expression | Semantic action role, independent of technician-facing step labels. |

Outputs and result contract:

Unique step ID. Missing or ambiguous roles throw before state changes.

Other named commands: `Where-Object`.

Named callers: [Invoke-DeviceWorkflowPlan](#invoke-deviceworkflowplan), [Test-DeviceInventoryEligible](#test-deviceinventoryeligible), [Invoke-StepConfirmRecoveryReadiness](#invoke-stepconfirmrecoveryreadiness), [Write-ManifestStepResult](#write-manifeststepresult), [Test-ManifestStepEligibility](#test-manifeststepeligibility), [Enter-DeviceRecoveryMode](#enter-devicerecoverymode).

### Read-JsonDefinitionFile

Read a required JSON definition and normalise its object representation.

Source: [autopilot-express.ps1:5761](autopilot-express.ps1#L5761). Internal entry-script function; source region: `Session Setup, Definitions and Graph Transport`.

| Parameter     | Declared Type   | Attributes                          | Default                        | Source Contract                                 |
| ------------- | --------------- | ----------------------------------- | ------------------------------ | ----------------------------------------------- |
| `Path`        | `System.String` | `[Parameter(Mandatory)]` `[string]` | No explicit default expression | Authorised runtime or manifest file path.       |
| `Description` | `System.String` | `[Parameter(Mandatory)]` `[string]` | No explicit default expression | Definition name used in actionable load errors. |

Outputs and result contract:

Normalised definition; missing, empty or malformed content throws without rewriting it.

Other named commands: `ConvertFrom-Json`, `Get-Content`, `Test-Path`.

Named callers: [Initialize-AutopilotExpressDefinitions](#initialize-autopilotexpressdefinitions).

### Test-ManifestDependencyGraph

Reject duplicate, missing, self-referencing or cyclic workflow dependencies.

Source: [autopilot-express.ps1:5783](autopilot-express.ps1#L5783). Internal entry-script function; source region: `Session Setup, Definitions and Graph Transport`.

| Parameter | Declared Type     | Attributes                            | Default                        | Source Contract                                                            |
| --------- | ----------------- | ------------------------------------- | ------------------------------ | -------------------------------------------------------------------------- |
| `Steps`   | `System.Object[]` | `[Parameter(Mandatory)]` `[object[]]` | No explicit default expression | Complete proposed manifest step collection, including conditional actions. |

Outputs and result contract:

None. Invalid graphs throw before workflow execution or definition promotion.

Other named commands: `Group-Object`, `Select-Object`, `Where-Object`.

Named callers: [Initialize-AutopilotExpressDefinitions](#initialize-autopilotexpressdefinitions).

### Invoke-ManifestStepDependency

Visit one dependency using the enclosing graph and traversal state.

Source: [autopilot-express.ps1:5832](autopilot-express.ps1#L5832). Nested in `Test-ManifestDependencyGraph`; its enclosing scope is part of the contract.

| Parameter | Declared Type   | Attributes                          | Default                        | Source Contract                               |
| --------- | --------------- | ----------------------------------- | ------------------------------ | --------------------------------------------- |
| `StepId`  | `System.String` | `[Parameter(Mandatory)]` `[string]` | No explicit default expression | Identity currently inspected for a back-edge. |

Outputs and result contract:

None. Updates local traversal sets and throws on a cycle; no workflow action runs.

Named callers: [Test-ManifestDependencyGraph](#test-manifestdependencygraph), [Invoke-ManifestStepDependency](#invoke-manifeststepdependency).

### Assert-ManifestDefinition

Reject invalid raw workflow definitions before coercion or startup access.

Source: [autopilot-express.ps1:5854](autopilot-express.ps1#L5854). Internal entry-script function; source region: `Session Setup, Definitions and Graph Transport`.

| Parameter  | Declared Type   | Attributes                                                          | Default                        | Source Contract                                                |
| ---------- | --------------- | ------------------------------------------------------------------- | ------------------------------ | -------------------------------------------------------------- |
| `Manifest` | `System.Object` | `[Parameter(Mandatory)]` `[AllowNull()]` `[AllowEmptyCollection()]` | No explicit default expression | Normalised JSON dictionary, without any runtime state changes. |

Outputs and result contract:

No output. Throws an actionable error for an unsupported definition.

Named callers: [Initialize-AutopilotExpressDefinitions](#initialize-autopilotexpressdefinitions).

### Initialize-AutopilotExpressDefinitions

Validate runtime, site, device-type and manifest definitions before use.

Source: [autopilot-express.ps1:5960](autopilot-express.ps1#L5960). Internal entry-script function; source region: `Session Setup, Definitions and Graph Transport`.

No formal parameters declared. Captured state and enclosing scope may still be inputs.

Outputs and result contract:

None. Initialises script configuration or throws before authentication/workflow entry.

Other named commands: `ForEach-Object`, `Where-Object`.

No statically named function caller in this inventory. Top-level, dynamic and callback invocation remain possible.

### Test-IsPlaceholderConfigurationValue

Detect absent values and documented placeholder forms in Live configuration.

Source: [autopilot-express.ps1:6026](autopilot-express.ps1#L6026). Internal entry-script function; source region: `Session Setup, Definitions and Graph Transport`.

| Parameter | Declared Type   | Attributes                        | Default                        | Source Contract                                          |
| --------- | --------------- | --------------------------------- | ------------------------------ | -------------------------------------------------------- |
| `Value`   | `System.String` | `[AllowEmptyString()]` `[string]` | No explicit default expression | Configuration text to inspect without querying a tenant. |

Outputs and result contract:

Boolean; this syntax check cannot prove that a real tenant object exists.

Named callers: [Invoke-LiveStartupRead](#invoke-livestartupread), [Initialize-LiveTenantContext](#initialize-livetenantcontext).

### Test-LiveRuntimeConfiguration

Collect actionable Live configuration issues without authenticating.

Source: [autopilot-express.ps1:6041](autopilot-express.ps1#L6041). Internal entry-script function; source region: `Session Setup, Definitions and Graph Transport`.

No formal parameters declared. Captured state and enclosing scope may still be inputs.

Outputs and result contract:

Issue array, empty on local validation success; not tenant acceptance evidence.

Other named commands: `Where-Object`.

Named callers: [Initialize-GraphSession](#initialize-graphsession).

### Get-GraphLocalModuleRoot

Resolve the per-user SDK cache on a fixed local drive, without elevation.

Source: [autopilot-express.ps1:6094](autopilot-express.ps1#L6094). Internal entry-script function; source region: `Session Setup, Definitions and Graph Transport`.

No formal parameters declared. Captured state and enclosing scope may still be inputs.

Outputs and result contract:

Absolute module root. Network, redirected or unavailable local storage throws.

Other named commands: `Join-Path`.

Named callers: [Get-GraphModuleCandidate](#get-graphmodulecandidate), [Install-RequiredGraphModules](#install-requiredgraphmodules).

### Test-GraphModuleLocalPath

Distinguish fixed local SDK files from UNC and mapped-network deployments.

Source: [autopilot-express.ps1:6112](autopilot-express.ps1#L6112). Internal entry-script function; source region: `Session Setup, Definitions and Graph Transport`.

| Parameter | Declared Type   | Attributes                                                       | Default                        | Source Contract                                  |
| --------- | --------------- | ---------------------------------------------------------------- | ------------------------------ | ------------------------------------------------ |
| `Path`    | `System.String` | `[Parameter(Mandatory)]` `[ValidateNotNullOrEmpty()]` `[string]` | No explicit default expression | Absolute candidate manifest or module directory. |

Outputs and result contract:

Boolean fixed-local, non-redirected classification; no module code is loaded.

Named callers: [Get-GraphModuleCandidate](#get-graphmodulecandidate), [Install-RequiredGraphModules](#install-requiredgraphmodules), [Get-GraphModuleImportPlan](#get-graphmoduleimportplan), [Import-RequiredGraphModules](#import-requiredgraphmodules).

### Get-GraphModuleCandidate

Read SDK manifests as restricted data before module discovery can load code.

Source: [autopilot-express.ps1:6131](autopilot-express.ps1#L6131). Internal entry-script function; source region: `Session Setup, Definitions and Graph Transport`.

| Parameter         | Declared Type     | Attributes                                                         | Default                                                | Source Contract                                                                                                                                       |
| ----------------- | ----------------- | ------------------------------------------------------------------ | ------------------------------------------------------ | ----------------------------------------------------------------------------------------------------------------------------------------------------- |
| `RequiredModules` | `System.String[]` | `[Parameter(Mandatory)]` `[ValidateNotNullOrEmpty()]` `[string[]]` | No explicit default expression                         | Configured names; Authentication is always included for coherent selection.                                                                           |
| `ModuleRoots`     | `System.String[]` | `[AllowEmptyCollection()]` `[string[]]`                            | `@($env:PSModulePath -split [IO.Path]::PathSeparator)` | Explicit inspection roots. Default discovery uses the per-user cache and fixed-local PSModulePath entries only, never redirected network home drives. |

Outputs and result contract:

Name, Version, Path and ModuleBase metadata without imports or SDK execution.
Unreadable or redirected candidate paths fail closed rather than disappearing.

Other named commands: `Get-ChildItem`, `Get-Item`, `Join-Path`, `Select-Object`, `Sort-Object`, `Test-Path`, `Where-Object`.

Named callers: [Install-RequiredGraphModules](#install-requiredgraphmodules), [Get-GraphModuleImportPlan](#get-graphmoduleimportplan).

### Test-GraphModuleScriptTrust

Inspect the selected SDK deployment without loading its code or changing trust.

Source: [autopilot-express.ps1:6181](autopilot-express.ps1#L6181). Internal entry-script function; source region: `Session Setup, Definitions and Graph Transport`.

| Parameter | Declared Type     | Attributes                                                         | Default                        | Source Contract                                                     |
| --------- | ----------------- | ------------------------------------------------------------------ | ------------------------------ | ------------------------------------------------------------------- |
| `Plan`    | `System.Object[]` | `[Parameter(Mandatory)]` `[ValidateNotNullOrEmpty()]` `[object[]]` | No explicit default expression | Exact coherent SDK manifests selected by Get-GraphModuleImportPlan. |

Outputs and result contract:

Readiness and exact Internet-marked file paths with SHA-256 fingerprints.
Uncertain network trust fails closed; signature checks never approve publishers.

Other named commands: `Get-AuthenticodeSignature`, `Get-ChildItem`, `Get-Content`, `Get-ExecutionPolicy`, `Get-FileHash`, `Get-Item`, `Where-Object`.

Named callers: [Request-GraphModuleScriptTrust](#request-graphmodulescripttrust).

### Request-GraphModuleScriptTrust

Offer separately confirmed removal of Internet marks from reviewed SDK files.

Source: [autopilot-express.ps1:6218](autopilot-express.ps1#L6218). Internal entry-script function; source region: `Session Setup, Definitions and Graph Transport`.

| Parameter | Declared Type     | Attributes                                                         | Default                        | Source Contract                                                                  |
| --------- | ----------------- | ------------------------------------------------------------------ | ------------------------------ | -------------------------------------------------------------------------------- |
| `Plan`    | `System.Object[]` | `[Parameter(Mandatory)]` `[ValidateNotNullOrEmpty()]` `[object[]]` | No explicit default expression | Exact selected deployment, including explicitly inspected network installations. |

Outputs and result contract:

Boolean readiness. Default No makes no change. File lists and hashes are
rechecked before unblocking; callers handle retry or exit after any failure.

Other named commands: `Compare-Object`, `ForEach-Object`, `Get-FileHash`, `Sort-Object`, `Unblock-File`, `Write-Host`.

Named callers: [Import-RequiredGraphModules](#import-requiredgraphmodules).

### Install-RequiredGraphModules

Offer coherent SDK deployment to fixed local per-user storage without UAC.

Source: [autopilot-express.ps1:6248](autopilot-express.ps1#L6248). Internal entry-script function; source region: `Session Setup, Definitions and Graph Transport`.

| Parameter         | Declared Type     | Attributes                            | Default                        | Source Contract                                                            |
| ----------------- | ----------------- | ------------------------------------- | ------------------------------ | -------------------------------------------------------------------------- |
| `RequiredModules` | `System.String[]` | `[Parameter(Mandatory)]` `[string[]]` | No explicit default expression | Approved module names; network-only deployments also require a local copy. |

Outputs and result contract:

Boolean installation outcome. Declining or installation failure does not authorise Live use.

Other named commands: `Find-Module`, `ForEach-Object`, `New-Item`, `Save-Module`, `Select-Object`, `Sort-Object`, `Where-Object`, `Write-Host`.

Named callers: [Import-RequiredGraphModules](#import-requiredgraphmodules).

### Get-GraphModuleImportPlan

Select the newest installed common SDK version without changing modules.

Source: [autopilot-express.ps1:6297](autopilot-express.ps1#L6297). Internal entry-script function; source region: `Session Setup, Definitions and Graph Transport`.

| Parameter          | Declared Type     | Attributes                                                         | Default                        | Source Contract                                                                       |
| ------------------ | ----------------- | ------------------------------------------------------------------ | ------------------------------ | ------------------------------------------------------------------------------------- |
| `RequiredModules`  | `System.String[]` | `[Parameter(Mandatory)]` `[ValidateNotNullOrEmpty()]` `[string[]]` | No explicit default expression | Configured SDK module names; Authentication is always included first.                 |
| `InstalledModules` | `System.Object[]` | `[AllowEmptyCollection()]` `[object[]]`                            | No explicit default expression | Previously selected metadata for post-import checks without repeating disk discovery. |

Outputs and result contract:

Installed module metadata in import order. Conflicting loaded SDKs throw.

Other named commands: `ForEach-Object`, `Get-Module`, `Select-Object`, `Sort-Object`, `Where-Object`.

Named callers: [Install-RequiredGraphModules](#install-requiredgraphmodules), [Import-RequiredGraphModules](#import-requiredgraphmodules).

### Import-RequiredGraphModules

Discover/import configured SDK modules with guarded failure reporting.

Source: [autopilot-express.ps1:6338](autopilot-express.ps1#L6338). Internal entry-script function; source region: `Session Setup, Definitions and Graph Transport`.

No formal parameters declared. Captured state and enclosing scope may still be inputs.

Outputs and result contract:

Boolean readiness. Missing modules follow the explicit installation prompt;
Demo does not require Live dependencies.

Other named commands: `Import-Module`, `Out-Null`, `Write-Host`.

Named callers: [Initialize-GraphSession](#initialize-graphsession).

### Get-GraphTransportPolicy

Validates the bounded HTTP policy independently of state-verification polling.

Source: [autopilot-express.ps1:6380](autopilot-express.ps1#L6380). Internal entry-script function; source region: `Session Setup, Definitions and Graph Transport`.

No formal parameters declared. Captured state and enclosing scope may still be inputs.

Outputs and result contract:

Dictionary containing attempt, backoff, maximum-wait and per-request timeout limits.

Named callers: [Invoke-GraphApiRequest](#invoke-graphapirequest), [Initialize-GraphSession](#initialize-graphsession).

### Initialize-GraphTransport

Disables hidden SDK retries and applies the HTTP timeout before any Graph operation.

Source: [autopilot-express.ps1:6407](autopilot-express.ps1#L6407). Internal entry-script function; source region: `Session Setup, Definitions and Graph Transport`.

| Parameter | Declared Type                    | Attributes                                                  | Default                        | Source Contract                                                                           |
| --------- | -------------------------------- | ----------------------------------------------------------- | ------------------------------ | ----------------------------------------------------------------------------------------- |
| `Policy`  | `System.Collections.IDictionary` | `[Parameter(Mandatory)]` `[System.Collections.IDictionary]` | No explicit default expression | Validated timeout/retry policy; SDK retries remain disabled for explicit wrapper control. |

Outputs and result contract:

None. Configures transport once per session, recording success only after setup completes.

Other named commands: `Get-Command`, `Out-Null`, `Set-MgRequestContext`.

Named callers: [Invoke-GraphApiRequest](#invoke-graphapirequest), [Initialize-GraphSession](#initialize-graphsession).

### Get-GraphTransportFailure

Reads structured status and safe retry/correlation headers without inspecting error text.

Source: [autopilot-express.ps1:6430](autopilot-express.ps1#L6430). Internal entry-script function; source region: `Session Setup, Definitions and Graph Transport`.

| Parameter      | Declared Type   | Attributes               | Default                        | Source Contract                                        |
| -------------- | --------------- | ------------------------ | ------------------------------ | ------------------------------------------------------ |
| `RequestError` | `System.Object` | `[Parameter(Mandatory)]` | No explicit default expression | The terminating SDK ErrorRecord from a failed request. |

Outputs and result contract:

Dictionary of HTTP status, Retry-After text and validated request identifier.

Named callers: [Get-GraphOperationFailureMessage](#get-graphoperationfailuremessage), [Invoke-GraphApiRequest](#invoke-graphapirequest), [Get-DeviceRemediationCatalog](#get-deviceremediationcatalog), [Initialize-GraphSession](#initialize-graphsession), [Invoke-DeviceInventoryCheck](#invoke-deviceinventorycheck), [Invoke-StepRemoveAssociatedManagedDevice](#invoke-stepremoveassociatedmanageddevice).

### Get-GraphOperationFailureMessage

Format SDK failures without retaining response bodies or authentication material.

Source: [autopilot-express.ps1:6478](autopilot-express.ps1#L6478). Internal entry-script function; source region: `Session Setup, Definitions and Graph Transport`.

| Parameter      | Declared Type   | Attributes               | Default                        | Source Contract                                                                                   |
| -------------- | --------------- | ------------------------ | ------------------------------ | ------------------------------------------------------------------------------------------------- |
| `RequestError` | `System.Object` | `[Parameter(Mandatory)]` | No explicit default expression | Caught ErrorRecord; structured SDK evidence or the guarded-request tag identifies Graph failures. |

Outputs and result contract:

Validated HTTP/correlation/type diagnostics for Graph, otherwise the local validation message.

Named callers: [Invoke-GraphReadPrefetch](#invoke-graphreadprefetch), [Get-DeviceRemediationCatalog](#get-deviceremediationcatalog), [Invoke-DeviceRemediation](#invoke-deviceremediation), [Show-RemediationQuickRunSettings](#show-remediationquickrunsettings), [Show-DeviceActions](#show-deviceactions), [Initialize-LiveTenantContext](#initialize-livetenantcontext), [Test-GraphCapabilities](#test-graphcapabilities), [Initialize-GraphSession](#initialize-graphsession), [Resolve-LiveDirectoryUserRecord](#resolve-livedirectoryuserrecord), [Invoke-LivePrimaryUserAssignment](#invoke-liveprimaryuserassignment), [Invoke-StepRemoveAssociatedManagedDevice](#invoke-stepremoveassociatedmanageddevice), [Invoke-StepApplyGroupTag](#invoke-stepapplygrouptag), [Invoke-PreProvisioningMembershipChange](#invoke-preprovisioningmembershipchange), [Invoke-StepClearUserlessEnrollmentStatus](#invoke-stepclearuserlessenrollmentstatus), [Invoke-StepConfirmRecoveryReadiness](#invoke-stepconfirmrecoveryreadiness), [Invoke-StepRetryFailedApps](#invoke-stepretryfailedapps), [Invoke-AutopilotManifestStep](#invoke-autopilotmanifeststep).

### Invoke-GraphApiRequest

Sends a Graph request with bounded transient GET retries and no mutation replay.

Source: [autopilot-express.ps1:6498](autopilot-express.ps1#L6498). Internal entry-script function; source region: `Session Setup, Definitions and Graph Transport`.

| Parameter | Declared Type                  | Attributes                                                                   | Default                        | Source Contract                                                              |
| --------- | ------------------------------ | ---------------------------------------------------------------------------- | ------------------------------ | ---------------------------------------------------------------------------- |
| `Method`  | `System.String`                | `[Parameter(Mandatory)]` `[ValidateSet('GET', 'POST', 'DELETE')]` `[string]` | No explicit default expression | Validated HTTP method. Only approved transient GET failures may be retried.  |
| `Uri`     | `System.String`                | `[Parameter(Mandatory)]` `[string]`                                          | No explicit default expression | Approved Graph URI; unsafe hosts, paths and continuation routes are refused. |
| `Body`    | `System.Object`                | None declared                                                                | No explicit default expression | Optional request payload; never printed in transport diagnostics.            |
| `Headers` | `System.Collections.Hashtable` | `[hashtable]`                                                                | No explicit default expression | Explicit request headers; not copied into diagnostic output.                 |

Outputs and result contract:

The original SDK response, or the original terminating request error.

Other named commands: `ConvertTo-Json`, `Get-Date`, `Invoke-MgGraphRequest`, `Start-Sleep`, `Write-Verbose`.

Named callers: [Invoke-GraphReadPrefetch](#invoke-graphreadprefetch), [Resolve-DeviceActionTarget](#resolve-deviceactiontarget), [Invoke-DeviceRemediation](#invoke-deviceremediation), [Get-GraphDiscoveryCollection](#get-graphdiscoverycollection), [Test-GraphCapabilities](#test-graphcapabilities), [Resolve-LiveDirectoryUserRecord](#resolve-livedirectoryuserrecord), [Search-LiveDirectoryUsers](#search-livedirectoryusers), [Resolve-LiveManagedDeviceBySerial](#resolve-livemanageddevicebyserial), [Get-LiveDeviceInventory](#get-livedeviceinventory), [Resolve-LiveEntraDeviceObject](#resolve-liveentradeviceobject), [Get-LiveManagedDevicePrimaryUsers](#get-livemanageddeviceprimaryusers), [Get-LiveAutopilotDeviceById](#get-liveautopilotdevicebyid), [Test-LiveGroupMembership](#test-livegroupmembership), [Invoke-LivePrimaryUserAssignment](#invoke-liveprimaryuserassignment), [Invoke-AutopilotHashImport](#invoke-autopilothashimport), [Invoke-StepRemoveAssociatedManagedDevice](#invoke-stepremoveassociatedmanageddevice), [Invoke-StepApplyGroupTag](#invoke-stepapplygrouptag), [Invoke-PreProvisioningMembershipChange](#invoke-preprovisioningmembershipchange), [Invoke-StepClearUserlessEnrollmentStatus](#invoke-stepclearuserlessenrollmentstatus), [Invoke-StepRetryFailedApps](#invoke-stepretryfailedapps).

### Invoke-GraphReadPrefetch

Collect several Graph reads in one JSON batch request so later reads need no extra call.

Source: [autopilot-express.ps1:6614](autopilot-express.ps1#L6614). Internal entry-script function; source region: `Session Setup, Definitions and Graph Transport`.

| Parameter | Declared Type     | Attributes                                                       | Default                        | Source Contract                                                            |
| --------- | ----------------- | ---------------------------------------------------------------- | ------------------------------ | -------------------------------------------------------------------------- |
| `Uri`     | `System.String[]` | `[Parameter(Mandatory)]` `[AllowEmptyCollection()]` `[string[]]` | No explicit default expression | Absolute Graph v1.0 GET URIs exactly as the later reads will request them. |

Outputs and result contract:

Number of answers stored for later use.

Other named commands: `Where-Object`.

Named callers: [Invoke-LiveStartupRead](#invoke-livestartupread), [Invoke-DeviceInventoryPrefetch](#invoke-deviceinventoryprefetch).

### Clear-GraphReadPrefetch

Discard any batched reads that were not used, so they can never be served later.

Source: [autopilot-express.ps1:6669](autopilot-express.ps1#L6669). Internal entry-script function; source region: `Session Setup, Definitions and Graph Transport`.

No formal parameters declared. Captured state and enclosing scope may still be inputs.

Outputs and result contract:

None.

Named callers: [Invoke-LiveStartupRead](#invoke-livestartupread), [Invoke-DeviceInventoryPolling](#invoke-deviceinventorypolling), [Update-DeviceInventoryFromIntune](#update-deviceinventoryfromintune).

### Get-GraphCapabilityReadCheck

List the four read-permission probes run after sign-in.

Source: [autopilot-express.ps1:6679](autopilot-express.ps1#L6679). Internal entry-script function; source region: `Session Setup, Definitions and Graph Transport`.

No formal parameters declared. Captured state and enclosing scope may still be inputs.

Outputs and result contract:

Array of @{ Name; Uri } dictionaries.

Named callers: [Invoke-LiveStartupRead](#invoke-livestartupread), [Test-GraphCapabilities](#test-graphcapabilities).

### Get-PreProvisioningGroupLookupUri

Build the exact Graph search used to find the pre-provisioning group by name.

Source: [autopilot-express.ps1:6697](autopilot-express.ps1#L6697). Internal entry-script function; source region: `Session Setup, Definitions and Graph Transport`.

| Parameter   | Declared Type   | Attributes                                                       | Default                        | Source Contract                                                                |
| ----------- | --------------- | ---------------------------------------------------------------- | ------------------------------ | ------------------------------------------------------------------------------ |
| `GroupName` | `System.String` | `[Parameter(Mandatory)]` `[ValidateNotNullOrEmpty()]` `[string]` | No explicit default expression | Configured group display name; single quotes are escaped for the OData filter. |

Outputs and result contract:

Absolute Graph v1.0 URI string.

Named callers: [Invoke-LiveStartupRead](#invoke-livestartupread), [Get-LivePreProvisioningGroup](#get-livepreprovisioninggroup).

### Get-ManagedDeviceSerialLookupUri

Build the exact Graph search used to find a managed device by serial number.

Source: [autopilot-express.ps1:6710](autopilot-express.ps1#L6710). Internal entry-script function; source region: `Session Setup, Definitions and Graph Transport`.

| Parameter | Declared Type   | Attributes                                                       | Default                        | Source Contract                                                          |
| --------- | --------------- | ---------------------------------------------------------------- | ------------------------------ | ------------------------------------------------------------------------ |
| `Serial`  | `System.String` | `[Parameter(Mandatory)]` `[ValidateNotNullOrEmpty()]` `[string]` | No explicit default expression | Canonical serial number; single quotes are escaped for the OData filter. |

Outputs and result contract:

Absolute Graph v1.0 URI string.

Named callers: [Resolve-LiveManagedDeviceBySerial](#resolve-livemanageddevicebyserial), [Invoke-DeviceInventoryPrefetch](#invoke-deviceinventoryprefetch).

### Get-ManagedDeviceInventoryUri

Build the exact Graph read that returns every Intune detail the script saves.

Source: [autopilot-express.ps1:6723](autopilot-express.ps1#L6723). Internal entry-script function; source region: `Session Setup, Definitions and Graph Transport`.

| Parameter         | Declared Type   | Attributes                                                       | Default                        | Source Contract           |
| ----------------- | --------------- | ---------------------------------------------------------------- | ------------------------------ | ------------------------- |
| `ManagedDeviceId` | `System.String` | `[Parameter(Mandatory)]` `[ValidateNotNullOrEmpty()]` `[string]` | No explicit default expression | Intune managed-device ID. |

Outputs and result contract:

Absolute Graph v1.0 URI string.

Named callers: [Get-LiveDeviceInventory](#get-livedeviceinventory), [Invoke-DeviceInventoryPrefetch](#invoke-deviceinventoryprefetch).

### Invoke-LiveStartupRead

Run the after-sign-in organisation, permission and group checks with one Graph request.

Source: [autopilot-express.ps1:6736](autopilot-express.ps1#L6736). Internal entry-script function; source region: `Session Setup, Definitions and Graph Transport`.

| Parameter      | Declared Type                    | Attributes                         | Default | Source Contract                                                                                                    |
| -------------- | -------------------------------- | ---------------------------------- | ------- | ------------------------------------------------------------------------------------------------------------------ |
| `StageTracker` | `System.Collections.IDictionary` | `[System.Collections.IDictionary]` | `@{}`   | Optional dictionary whose Stage value is updated so the caller's failure message names the stage that was running. |

Outputs and result contract:

Capability results from Test-GraphCapabilities.

Other named commands: `ForEach-Object`.

Named callers: [Initialize-GraphSession](#initialize-graphsession).

### Get-DeviceActionContext

Bind device utilities to the Windows technician, mode and current tenant.

Source: [autopilot-express.ps1:6765](autopilot-express.ps1#L6765). Internal entry-script function; source region: `Session Setup, Definitions and Graph Transport`.

No formal parameters declared. Captured state and enclosing scope may still be inputs.

Outputs and result contract:

Context dictionary. Live validates the actual Graph context before reuse.

Named callers: [Get-DeviceActionState](#get-deviceactionstate), [Save-DeviceActionState](#save-deviceactionstate), [Get-DeviceRemediationCatalog](#get-deviceremediationcatalog), [Resolve-DeviceActionTarget](#resolve-deviceactiontarget), [Get-DeviceRemediationObservation](#get-deviceremediationobservation), [Invoke-DeviceRemediation](#invoke-deviceremediation), [Show-RemediationQuickRunSettings](#show-remediationquickrunsettings), [Show-DeviceActions](#show-deviceactions).

### Get-DeviceActionStatePath

Locate per-technician preferences and run evidence outside archived build sessions.

Source: [autopilot-express.ps1:6776](autopilot-express.ps1#L6776). Internal entry-script function; source region: `Session Setup, Definitions and Graph Transport`.

| Parameter | Declared Type                    | Attributes                                                  | Default                        | Source Contract                                                                   |
| --------- | -------------------------------- | ----------------------------------------------------------- | ------------------------------ | --------------------------------------------------------------------------------- |
| `Context` | `System.Collections.IDictionary` | `[Parameter(Mandatory)]` `[System.Collections.IDictionary]` | No explicit default expression | Validated mode/tenant context; no caller-controlled path components are accepted. |

Outputs and result contract:

Local-profile JSON path. Missing durable profile storage fails rather than using TEMP.

Other named commands: `Join-Path`.

Named callers: [Get-DeviceActionState](#get-deviceactionstate), [Save-DeviceActionState](#save-deviceactionstate).

### Assert-DeviceActionState

Refuse foreign, malformed or ambiguous preference/submission evidence.

Source: [autopilot-express.ps1:6793](autopilot-express.ps1#L6793). Internal entry-script function; source region: `Session Setup, Definitions and Graph Transport`.

| Parameter | Declared Type                    | Attributes                                                  | Default                        | Source Contract                                                                     |
| --------- | -------------------------------- | ----------------------------------------------------------- | ------------------------------ | ----------------------------------------------------------------------------------- |
| `State`   | `System.Collections.IDictionary` | `[Parameter(Mandatory)]` `[System.Collections.IDictionary]` | No explicit default expression | Detached JSON dictionary including complete arrays, revision and identity metadata. |
| `Context` | `System.Collections.IDictionary` | `[Parameter(Mandatory)]` `[System.Collections.IDictionary]` | No explicit default expression | Fresh Windows-user, mode and tenant binding.                                        |

Outputs and result contract:

None. Validation errors preserve the original file and do not start a run.

Other named commands: `Sort-Object`.

Named callers: [Get-DeviceActionState](#get-deviceactionstate), [Save-DeviceActionState](#save-deviceactionstate).

### Get-DeviceActionState

Load recovery-checked selections and submission history, initially enabling nothing.

Source: [autopilot-express.ps1:6825](autopilot-express.ps1#L6825). Internal entry-script function; source region: `Session Setup, Definitions and Graph Transport`.

No formal parameters declared. Captured state and enclosing scope may still be inputs.

Outputs and result contract:

Validated dictionary. Viewing defaults does not create files or alter workflow evidence.

Other named commands: `ConvertFrom-Json`, `Get-Command`, `Get-Content`, `Get-Item`, `Test-Path`.

Named callers: [Save-DeviceActionState](#save-deviceactionstate), [Invoke-DeviceRemediation](#invoke-deviceremediation), [Get-DeviceRemediationRunStatus](#get-deviceremediationrunstatus), [Show-RemediationQuickRunSettings](#show-remediationquickrunsettings), [Show-DeviceActions](#show-deviceactions).

### Save-DeviceActionState

Persist a revision-checked change with guarded writes and a short exclusive file handle.

Source: [autopilot-express.ps1:6848](autopilot-express.ps1#L6848). Internal entry-script function; source region: `Session Setup, Definitions and Graph Transport`.

| Parameter | Declared Type                    | Attributes                                                  | Default                        | Source Contract                                                                       |
| --------- | -------------------------------- | ----------------------------------------------------------- | ------------------------------ | ------------------------------------------------------------------------------------- |
| `State`   | `System.Collections.IDictionary` | `[Parameter(Mandatory)]` `[System.Collections.IDictionary]` | No explicit default expression | Detached state read at the current revision; updated only after verified persistence. |

Outputs and result contract:

None. Concurrent/stale changes and incomplete saves fail closed without deleting evidence.

Other named commands: `ConvertTo-Json`.

Named callers: [Invoke-DeviceRemediation](#invoke-deviceremediation), [Get-DeviceRemediationRunStatus](#get-deviceremediationrunstatus), [Show-RemediationQuickRunSettings](#show-remediationquickrunsettings).

### Assert-DeviceRemediationAccess

Distinguish missing requested permissions from missing granted remediation access.

Source: [autopilot-express.ps1:6877](autopilot-express.ps1#L6877). Internal entry-script function; source region: `Session Setup, Definitions and Graph Transport`.

| Parameter   | Declared Type   | Attributes                                | Default  | Source Contract                                                                       |
| ----------- | --------------- | ----------------------------------------- | -------- | ------------------------------------------------------------------------------------- |
| `Operation` | `System.String` | `[ValidateSet('Read', 'Run')]` `[string]` | `'Read'` | Read checks catalogue/report access; Run also checks privileged device-action access. |

Outputs and result contract:

None. Throws actionable guidance without changing configuration, consent or authentication.

Other named commands: `Get-MgContext`, `Where-Object`.

Named callers: [Get-DeviceRemediationCatalog](#get-deviceremediationcatalog), [Get-DeviceRemediationObservation](#get-deviceremediationobservation), [Invoke-DeviceRemediation](#invoke-deviceremediation), [Initialize-GraphSession](#initialize-graphsession).

### Get-DeviceRemediationCatalog

Retrieve complete remediation metadata without downloading script contents.

Source: [autopilot-express.ps1:6906](autopilot-express.ps1#L6906). Internal entry-script function; source region: `Session Setup, Definitions and Graph Transport`.

No formal parameters declared. Captured state and enclosing scope may still be inputs.

Outputs and result contract:

Alphabetically sorted package metadata array, including empty results.

Other named commands: `Sort-Object`.

Named callers: [Invoke-DeviceRemediation](#invoke-deviceremediation), [Show-RemediationQuickRunSettings](#show-remediationquickrunsettings), [Show-DeviceActions](#show-deviceactions).

### Resolve-DeviceActionTarget

Refresh a detached selected device without retargeting saved workflow evidence.

Source: [autopilot-express.ps1:6943](autopilot-express.ps1#L6943). Internal entry-script function; source region: `Session Setup, Definitions and Graph Transport`.

| Parameter | Declared Type                    | Attributes                                                  | Default                        | Source Contract                                                                  |
| --------- | -------------------------------- | ----------------------------------------------------------- | ------------------------------ | -------------------------------------------------------------------------------- |
| `Device`  | `System.Collections.IDictionary` | `[Parameter(Mandatory)]` `[System.Collections.IDictionary]` | No explicit default expression | Selected dictionary with RecordId and serial; cached object IDs are not trusted. |

Outputs and result contract:

Immutable target dictionary. Live requires a fresh Windows managed-device match.

Named callers: [Invoke-DeviceRemediation](#invoke-deviceremediation), [Get-DeviceRemediationRunStatus](#get-deviceremediationrunstatus), [Copy-DeviceIntuneOverviewLink](#copy-deviceintuneoverviewlink).

### Get-DeviceRemediationObservation

Read complete package execution reports and match the exact managed device locally.

Source: [autopilot-express.ps1:6971](autopilot-express.ps1#L6971). Internal entry-script function; source region: `Session Setup, Definitions and Graph Transport`.

| Parameter   | Declared Type                    | Attributes                                                                                                      | Default                        | Source Contract                                                                 |
| ----------- | -------------------------------- | --------------------------------------------------------------------------------------------------------------- | ------------------------------ | ------------------------------------------------------------------------------- |
| `PackageId` | `System.String`                  | `[Parameter(Mandatory)]` `[ValidatePattern('^[0-9a-fA-F]{8}(-[0-9a-fA-F]{4}){3}-[0-9a-fA-F]{12}$')]` `[string]` | No explicit default expression | Immutable remediation package GUID.                                             |
| `Target`    | `System.Collections.IDictionary` | `[Parameter(Mandatory)]` `[System.Collections.IDictionary]`                                                     | No explicit default expression | Fresh tenant/device binding; no display-name or serial report matching is used. |

Outputs and result contract:

Matching report or null. No script output/content is requested or logged.

Other named commands: `Where-Object`.

Named callers: [Invoke-DeviceRemediation](#invoke-deviceremediation), [Get-DeviceRemediationRunStatus](#get-deviceremediationrunstatus).

### Invoke-DeviceRemediation

Confirm one enabled package/Windows target and durably reserve one submission.

Source: [autopilot-express.ps1:6999](autopilot-express.ps1#L6999). Internal entry-script function; source region: `Session Setup, Definitions and Graph Transport`.

| Parameter   | Declared Type                    | Attributes                                                                                                      | Default                        | Source Contract                                                                        |
| ----------- | -------------------------------- | --------------------------------------------------------------------------------------------------------------- | ------------------------------ | -------------------------------------------------------------------------------------- |
| `Device`    | `System.Collections.IDictionary` | `[Parameter(Mandatory)]` `[System.Collections.IDictionary]`                                                     | No explicit default expression | Selected workflow record; the workflow and checklist remain unchanged.                 |
| `PackageId` | `System.String`                  | `[Parameter(Mandatory)]` `[ValidatePattern('^[0-9a-fA-F]{8}(-[0-9a-fA-F]{4}){3}-[0-9a-fA-F]{12}$')]` `[string]` | No explicit default expression | Tenant package identity explicitly enabled in this technician's quick-run preferences. |

Outputs and result contract:

Submission/evidence dictionary; acceptance never asserts device execution or success.

Other named commands: `Out-Null`, `Select-Object`, `Where-Object`, `Write-Host`.

Named callers: [Show-DeviceActions](#show-deviceactions).

### Get-DeviceRemediationRunStatus

Refresh execution evidence without resubmitting or asserting request correlation.

Source: [autopilot-express.ps1:7063](autopilot-express.ps1#L7063). Internal entry-script function; source region: `Session Setup, Definitions and Graph Transport`.

| Parameter | Declared Type                    | Attributes                                                  | Default                        | Source Contract                                                                        |
| --------- | -------------------------------- | ----------------------------------------------------------- | ------------------------------ | -------------------------------------------------------------------------------------- |
| `Device`  | `System.Collections.IDictionary` | `[Parameter(Mandatory)]` `[System.Collections.IDictionary]` | No explicit default expression | Original selected workflow; changed device/record identity refuses old evidence reuse. |
| `RunId`   | `System.String`                  | `[Parameter(Mandatory)]` `[string]`                         | No explicit default expression | Locally durable submission identity; it is not a Graph execution correlation ID.       |

Outputs and result contract:

Accepted/uncertain or fresh ExecutionObserved evidence, with separate script result states.

Other named commands: `Where-Object`.

Named callers: [Show-DeviceActions](#show-deviceactions).

### Copy-DeviceIntuneOverviewLink

Copy the fresh managed-device overview link to this technician PC's clipboard.

Source: [autopilot-express.ps1:7101](autopilot-express.ps1#L7101). Internal entry-script function; source region: `Session Setup, Definitions and Graph Transport`.

| Parameter | Declared Type                    | Attributes                                                  | Default                        | Source Contract                                                                     |
| --------- | -------------------------------- | ----------------------------------------------------------- | ------------------------------ | ----------------------------------------------------------------------------------- |
| `Device`  | `System.Collections.IDictionary` | `[Parameter(Mandatory)]` `[System.Collections.IDictionary]` | No explicit default expression | Selected device; Live identity is re-resolved before constructing the portal route. |

Outputs and result contract:

Link and copy outcome. Portal sign-in must use the displayed tenant; no remote clipboard action occurs.

Other named commands: `Get-Clipboard`, `Set-Clipboard`, `Write-Host`.

Named callers: [Show-DeviceActions](#show-deviceactions).

### Select-RemediationMenuItem

Page immutable package/request choices with zero/Enter cancellation.

Source: [autopilot-express.ps1:7124](autopilot-express.ps1#L7124). Internal entry-script function; source region: `Session Setup, Definitions and Graph Transport`.

| Parameter | Declared Type     | Attributes                              | Default                        | Source Contract                                                                   |
| --------- | ----------------- | --------------------------------------- | ------------------------------ | --------------------------------------------------------------------------------- |
| `Items`   | `System.Object[]` | `[AllowEmptyCollection()]` `[object[]]` | `@()`                          | Detached choices with id/displayName; empty collections offer no selection.       |
| `Title`   | `System.String`   | `[Parameter(Mandatory)]` `[string]`     | No explicit default expression | Caller-owned prompt context. N/P page; invalid or out-of-range choices re-prompt. |

Outputs and result contract:

One original item or null; duplicate names are distinguished by ID.

Other named commands: `Write-Host`.

Named callers: [Show-RemediationQuickRunSettings](#show-remediationquickrunsettings), [Show-DeviceActions](#show-deviceactions).

### Show-RemediationQuickRunSettings

Discover tenant packages and explicitly save this technician's quick-run selection.

Source: [autopilot-express.ps1:7153](autopilot-express.ps1#L7153). Internal entry-script function; source region: `Session Setup, Definitions and Graph Transport`.

| Parameter  | Declared Type                                  | Attributes | Default                        | Source Contract                                                                              |
| ---------- | ---------------------------------------------- | ---------- | ------------------------------ | -------------------------------------------------------------------------------------------- |
| `PassThru` | `System.Management.Automation.SwitchParameter` | `[switch]` | No explicit default expression | Return an initial load failure to the owning device screen instead of acknowledging it here. |

Outputs and result contract:

Host output, or a failure dictionary with PassThru. No remediation or workflow milestone changes.

Other named commands: `ForEach-Object`, `Sort-Object`, `Where-Object`, `Write-Host`.

Named callers: [Show-DeviceActions](#show-deviceactions).

### Show-DeviceActions

Share remediation run/status and clipboard commands between bench and device menus.

Source: [autopilot-express.ps1:7227](autopilot-express.ps1#L7227). Internal entry-script function; source region: `Session Setup, Definitions and Graph Transport`.

| Parameter           | Declared Type                    | Attributes                             | Default                        | Source Contract                                                               |
| ------------------- | -------------------------------- | -------------------------------------- | ------------------------------ | ----------------------------------------------------------------------------- |
| `Records`           | `System.Collections.Hashtable`   | `[Parameter(Mandatory)]` `[hashtable]` | No explicit default expression | Existing workflow records used only for explicit device selection.            |
| `Device`            | `System.Collections.IDictionary` | `[System.Collections.IDictionary]`     | No explicit default expression | Already selected bench record, or omit for the existing serial/CI picker.     |
| `ReturnDestination` | `System.String`                  | `[string]`                             | `'Device commands'`            | Actual caller shown on zero/Enter return; helpers never navigate recursively. |

Outputs and result contract:

Last structured utility result for bench feedback, or null. No checklist step is changed.

Other named commands: `ForEach-Object`, `Where-Object`, `Write-Host`.

Named callers: [Invoke-BenchSelectedCommand](#invoke-benchselectedcommand).

### Get-GraphDiscoveryCollection

Read complete, bounded Graph discovery pages without returning partial data.

Source: [autopilot-express.ps1:7289](autopilot-express.ps1#L7289). Internal entry-script function; source region: `Session Setup, Definitions and Graph Transport`.

| Parameter              | Declared Type   | Attributes                                                       | Default                        | Source Contract                                                                                                                            |
| ---------------------- | --------------- | ---------------------------------------------------------------- | ------------------------------ | ------------------------------------------------------------------------------------------------------------------------------------------ |
| `Uri`                  | `System.String` | `[Parameter(Mandatory)]` `[ValidateNotNullOrEmpty()]` `[string]` | No explicit default expression | Initial Microsoft Graph collection URI. Continuations must retain its path.                                                                |
| `RequiredTextProperty` | `System.String` | `[ValidateSet('displayName', 'serialNumber', 'id')]` `[string]`  | `'displayName'`                | Required identity field: displayName for discovery, serialNumber for Autopilot, or id for limited-information direct membership responses. |

Outputs and result contract:

Complete array of validated identities; no partial results on failure.

Named callers: [Get-DeviceRemediationCatalog](#get-deviceremediationcatalog), [Get-DeviceRemediationObservation](#get-deviceremediationobservation), [Initialize-LiveTenantContext](#initialize-livetenantcontext), [Resolve-LiveAutopilotDeviceBySerial](#resolve-liveautopilotdevicebyserial), [Get-LivePreProvisioningGroup](#get-livepreprovisioninggroup), [Test-LiveGroupMembership](#test-livegroupmembership), [Invoke-AutopilotHashImport](#invoke-autopilothashimport), [Get-LivePreProvisioningConflictGroup](#get-livepreprovisioningconflictgroup), [Get-LivePreProvisioningMembershipState](#get-livepreprovisioningmembershipstate).

### Initialize-LiveTenantContext

Resolve required profile/group context after validated Graph sign-in.

Source: [autopilot-express.ps1:7331](autopilot-express.ps1#L7331). Internal entry-script function; source region: `Session Setup, Definitions and Graph Transport`.

No formal parameters declared. Captured state and enclosing scope may still be inputs.

Outputs and result contract:

None. Populates runtime context or throws; group lookup errors omit raw SDK text.

Other named commands: `Sort-Object`, `Write-Host`.

Named callers: [Invoke-LiveStartupRead](#invoke-livestartupread).

### Test-GraphCapabilities

Probe read surfaces and reject malformed successful collection responses.

Source: [autopilot-express.ps1:7378](autopilot-express.ps1#L7378). Internal entry-script function; source region: `Session Setup, Definitions and Graph Transport`.

No formal parameters declared. Captured state and enclosing scope may still be inputs.

Outputs and result contract:

Capability results with safe failure diagnostics. Valid empty collections prove read
access only, not write permission, object absence or checklist acceptance.

Named callers: [Invoke-LiveStartupRead](#invoke-livestartupread).

### Initialize-GraphSession

Establish Demo context or a validated, stage-labelled Live Graph session.

Source: [autopilot-express.ps1:7414](autopilot-express.ps1#L7414). Internal entry-script function; source region: `Session Setup, Definitions and Graph Transport`.

No formal parameters declared. Captured state and enclosing scope may still be inputs.

Outputs and result contract:

Boolean readiness; retains identity, organisation and read-capability evidence.
Failure clears session state without logging SDK response bodies or tokens.

Other named commands: `Connect-MgGraph`, `Disconnect-MgGraph`, `ForEach-Object`, `Get-Command`, `Get-MgContext`, `Get-Module`, `Invoke-MgGraphRequest`, `Out-Host`, `Out-Null`, `Where-Object`, `Write-Host`, `Write-Verbose`.

No statically named function caller in this inventory. Top-level, dynamic and callback invocation remain possible.

### Close-GraphSession

Disconnect the owned Live Graph context and clear local session state.

Source: [autopilot-express.ps1:7582](autopilot-express.ps1#L7582). Internal entry-script function; source region: `Session Setup, Definitions and Graph Transport`.

No formal parameters declared. Captured state and enclosing scope may still be inputs.

Outputs and result contract:

None. Safely reported disconnect failures do not prevent local cleanup.

Other named commands: `Disconnect-MgGraph`, `Out-Null`, `Write-Verbose`.

Named callers: [Initialize-GraphSession](#initialize-graphsession).

### New-OperationResult

Build an honest outcome; Live request acceptance alone is Submitted.

Source: [autopilot-express.ps1:7595](autopilot-express.ps1#L7595). Internal entry-script function; source region: `Session Setup, Definitions and Graph Transport`.

| Parameter         | Declared Type                  | Attributes                                                                                                                                          | Default                        | Source Contract                                                                          |
| ----------------- | ------------------------------ | --------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------ | ---------------------------------------------------------------------------------------- |
| `ActionName`      | `System.String`                | `[Parameter(Mandatory)]` `[string]`                                                                                                                 | No explicit default expression | Manifest semantic action used to select the required evidence contract.                  |
| `Success`         | `System.Boolean`               | `[Parameter(Mandatory)]` `[bool]`                                                                                                                   | No explicit default expression | Handler outcome flag; not a substitute for explicit completion classification.           |
| `Summary`         | `System.String`                | `[string]`                                                                                                                                          | No explicit default expression | Concise technician-facing outcome.                                                       |
| `Notes`           | `System.String`                | `[string]`                                                                                                                                          | No explicit default expression | Safe actionable detail; raw SDK response text must not be supplied.                      |
| `Data`            | `System.Collections.Hashtable` | `[hashtable]`                                                                                                                                       | No explicit default expression | Target identities, expected/observed values and completed read attempts.                 |
| `CompletionState` | `System.String`                | `[ValidateSet('Verified', 'TechnicianConfirmed', 'Submitted', 'Blocked', 'Failed', 'AuditedException', 'Simulated', 'LegacyCompleted')]` `[string]` | No explicit default expression | Explicit evidence state; Submitted/Blocked remain incomplete despite request acceptance. |

Outputs and result contract:

Operation dictionary; inconsistent verification becomes non-completing Submitted.

Named callers: [Invoke-StepResolveAutopilotDevice](#invoke-stepresolveautopilotdevice), [Invoke-StepRemoveAssociatedManagedDevice](#invoke-stepremoveassociatedmanageddevice), [Invoke-StepApplyGroupTag](#invoke-stepapplygrouptag), [Invoke-StepValidateDeploymentProfile](#invoke-stepvalidatedeploymentprofile), [Invoke-PreProvisioningMembershipChange](#invoke-preprovisioningmembershipchange), [Save-RecoverySubmissionEvidence](#save-recoverysubmissionevidence), [Invoke-StepClearUserlessEnrollmentStatus](#invoke-stepclearuserlessenrollmentstatus), [Invoke-StepConfirmRecoveryReadiness](#invoke-stepconfirmrecoveryreadiness), [Invoke-StepAssignTechnicianPrimaryUser](#invoke-stepassigntechnicianprimaryuser), [Invoke-StepRetryFailedApps](#invoke-stepretryfailedapps), [Invoke-StepAssignFinalPrimaryUser](#invoke-stepassignfinalprimaryuser), [Invoke-StepConfirmPhysicalMilestone](#invoke-stepconfirmphysicalmilestone), [Invoke-AutopilotManifestStep](#invoke-autopilotmanifeststep), [Write-ManifestStepResult](#write-manifeststepresult), [Undo-LatestTechnicianConfirmation](#undo-latesttechnicianconfirmation).

### Get-UserLocalPart

Trim an account name and return the portion before the first at-sign.

Source: [autopilot-express.ps1:7660](autopilot-express.ps1#L7660). Internal entry-script function; source region: `Directory Selection and Tenant Workflow Actions`.

| Parameter           | Declared Type   | Attributes | Default                        | Source Contract                                          |
| ------------------- | --------------- | ---------- | ------------------------------ | -------------------------------------------------------- |
| `UserPrincipalName` | `System.String` | `[string]` | No explicit default expression | Directory account text; absent values become empty text. |

Outputs and result contract:

Local-part string; no account resolution or validation.

Named callers: [Test-DirectoryUserMatchesConfiguredPrefixes](#test-directoryusermatchesconfiguredprefixes), [Test-DirectoryUserSearchMatch](#test-directoryusersearchmatch), [Get-DirectoryUserSearchRank](#get-directoryusersearchrank), [Select-TechnicianDirectoryUser](#select-techniciandirectoryuser).

### Test-DirectoryUserMatchesConfiguredPrefixes

Match the account local part against permitted prefixes without case sensitivity.

Source: [autopilot-express.ps1:7676](autopilot-express.ps1#L7676). Internal entry-script function; source region: `Directory Selection and Tenant Workflow Actions`.

| Parameter           | Declared Type   | Attributes | Default                        | Source Contract                                                   |
| ------------------- | --------------- | ---------- | ------------------------------ | ----------------------------------------------------------------- |
| `UserPrincipalName` | `System.String` | `[string]` | No explicit default expression | Candidate account; domain text does not establish a prefix match. |

Outputs and result contract:

Boolean prefix eligibility, not tenant membership or enabled-account evidence.

Named callers: [Get-DirectoryUserEligibilityMessage](#get-directoryusereligibilitymessage).

### Get-DirectoryUserEligibilityMessage

Explain missing identity, disabled account or prefix rejection.

Source: [autopilot-express.ps1:7694](autopilot-express.ps1#L7694). Internal entry-script function; source region: `Directory Selection and Tenant Workflow Actions`.

| Parameter | Declared Type   | Attributes    | Default                        | Source Contract                                                       |
| --------- | --------------- | ------------- | ------------------------------ | --------------------------------------------------------------------- |
| `User`    | `System.Object` | None declared | No explicit default expression | Normalised candidate containing UserPrincipalName and AccountEnabled. |

Outputs and result contract:

Actionable rejection string, or empty string for an eligible candidate.

Named callers: [Test-EligibleDirectoryUser](#test-eligibledirectoryuser), [Resolve-EligibleDirectoryUser](#resolve-eligibledirectoryuser).

### Test-EligibleDirectoryUser

Apply the shared account-enabled and permitted-prefix selection rules.

Source: [autopilot-express.ps1:7719](autopilot-express.ps1#L7719). Internal entry-script function; source region: `Directory Selection and Tenant Workflow Actions`.

| Parameter | Declared Type   | Attributes    | Default                        | Source Contract                         |
| --------- | --------------- | ------------- | ------------------------------ | --------------------------------------- |
| `User`    | `System.Object` | None declared | No explicit default expression | Normalised directory account candidate. |

Outputs and result contract:

Boolean result; cached candidates still require fresh Live revalidation.

Named callers: [Get-EligibleDirectoryUsers](#get-eligibledirectoryusers), [Get-DirectoryUserSearchResult](#get-directoryusersearchresult), [Search-LiveDirectoryUsers](#search-livedirectoryusers).

### Get-EligibleDirectoryUsers

Filter candidates and sort by display name then principal name.

Source: [autopilot-express.ps1:7732](autopilot-express.ps1#L7732). Internal entry-script function; source region: `Directory Selection and Tenant Workflow Actions`.

| Parameter | Declared Type                    | Attributes                                                    | Default                        | Source Contract                                                 |
| --------- | -------------------------------- | ------------------------------------------------------------- | ------------------------------ | --------------------------------------------------------------- |
| `Users`   | `System.Collections.IEnumerable` | `[AllowEmptyCollection()]` `[System.Collections.IEnumerable]` | No explicit default expression | Candidate collection; null and ineligible entries are excluded. |

Outputs and result contract:

Eligible account array; no fresh tenant reads.

Other named commands: `Sort-Object`, `Where-Object`.

Named callers: [Get-RecentUsers](#get-recentusers).

### Resolve-LiveDirectoryUserRecord

Re-read an account by ID or escaped principal name in the current tenant.

Source: [autopilot-express.ps1:7745](autopilot-express.ps1#L7745). Internal entry-script function; source region: `Directory Selection and Tenant Workflow Actions`.

| Parameter | Declared Type   | Attributes    | Default                        | Source Contract                                                    |
| --------- | --------------- | ------------- | ------------------------------ | ------------------------------------------------------------------ |
| `User`    | `System.Object` | None declared | No explicit default expression | Cached or selected account; a known immutable ID takes precedence. |

Outputs and result contract:

Normalised account, or null on missing identity/read failure. SDK failures use
bounded diagnostics rather than retaining response messages in logs.

Named callers: [Resolve-EligibleDirectoryUser](#resolve-eligibledirectoryuser), [Invoke-LivePrimaryUserAssignment](#invoke-liveprimaryuserassignment).

### Resolve-EligibleDirectoryUser

Revalidate the selected account and enforce shared eligibility rules.

Source: [autopilot-express.ps1:7797](autopilot-express.ps1#L7797). Internal entry-script function; source region: `Directory Selection and Tenant Workflow Actions`.

| Parameter | Declared Type   | Attributes    | Default                        | Source Contract                                                        |
| --------- | --------------- | ------------- | ------------------------------ | ---------------------------------------------------------------------- |
| `User`    | `System.Object` | None declared | No explicit default expression | Candidate; Live performs a fresh read and Demo uses synthetic records. |

Outputs and result contract:

Eligible current account, or null with feedback; no assignment occurs.

Other named commands: `Write-Host`.

Named callers: [Select-DirectoryUser](#select-directoryuser), [Select-TechnicianDirectoryUser](#select-techniciandirectoryuser).

### Get-RecentUsers

Load recent accounts and exclude entries failing local selection rules.

Source: [autopilot-express.ps1:7824](autopilot-express.ps1#L7824). Internal entry-script function; source region: `Directory Selection and Tenant Workflow Actions`.

No formal parameters declared. Captured state and enclosing scope may still be inputs.

Outputs and result contract:

Eligible recent-account array; stored identities are convenience, not Live authority.

Other named commands: `ConvertFrom-Json`, `Get-Content`, `Select-Object`, `Test-Path`, `Where-Object`.

Named callers: [Add-RecentUser](#add-recentuser), [Search-DemoDirectoryUsers](#search-demodirectoryusers), [Select-DirectoryUser](#select-directoryuser), [Select-TechnicianDirectoryUser](#select-techniciandirectoryuser).

### Save-RecentUsers

Persist eligible recent accounts through guarded UTF-8 storage.

Source: [autopilot-express.ps1:7865](autopilot-express.ps1#L7865). Internal entry-script function; source region: `Directory Selection and Tenant Workflow Actions`.

| Parameter | Declared Type                    | Attributes                                                    | Default                        | Source Contract                                          |
| --------- | -------------------------------- | ------------------------------------------------------------- | ------------------------------ | -------------------------------------------------------- |
| `Users`   | `System.Collections.IEnumerable` | `[AllowEmptyCollection()]` `[System.Collections.IEnumerable]` | No explicit default expression | Recent-account collection for the current user and mode. |

Outputs and result contract:

None. Storage failures propagate; tokens and credentials are not stored.

Other named commands: `ConvertTo-Json`, `ForEach-Object`, `Where-Object`.

Named callers: [Add-RecentUser](#add-recentuser).

### Add-RecentUser

Deduplicate a selected account and persist the bounded recent-user list.

Source: [autopilot-express.ps1:7881](autopilot-express.ps1#L7881). Internal entry-script function; source region: `Directory Selection and Tenant Workflow Actions`.

| Parameter | Declared Type   | Attributes               | Default                        | Source Contract                                   |
| --------- | --------------- | ------------------------ | ------------------------------ | ------------------------------------------------- |
| `User`    | `System.Object` | `[Parameter(Mandatory)]` | No explicit default expression | Eligible account just selected by the technician. |

Outputs and result contract:

None. Updates convenience storage, not assignment evidence.

Other named commands: `Select-Object`.

Named callers: [Select-TechnicianDirectoryUser](#select-techniciandirectoryuser), [Invoke-StepAssignFinalPrimaryUser](#invoke-stepassignfinalprimaryuser).

### ConvertTo-DirectoryUserRecord

Reduce an SDK or JSON account to the fields required by account selection.

Source: [autopilot-express.ps1:7910](autopilot-express.ps1#L7910). Internal entry-script function; source region: `Directory Selection and Tenant Workflow Actions`.

| Parameter | Declared Type   | Attributes    | Default                        | Source Contract                                              |
| --------- | --------------- | ------------- | ------------------------------ | ------------------------------------------------------------ |
| `User`    | `System.Object` | None declared | No explicit default expression | Dictionary or object containing identity and enabled status. |

Outputs and result contract:

Identity, Windows username and enabled status, or null when unusable.

Named callers: [Resolve-LiveDirectoryUserRecord](#resolve-livedirectoryuserrecord), [Get-RecentUsers](#get-recentusers), [Save-RecentUsers](#save-recentusers), [Search-DemoDirectoryUsers](#search-demodirectoryusers), [Search-LiveDirectoryUsers](#search-livedirectoryusers), [Get-LiveManagedDevicePrimaryUsers](#get-livemanageddeviceprimaryusers).

### Test-NameWordApproximation

Checks one insertion, deletion or substitution in a complete name word.

Source: [autopilot-express.ps1:7929](autopilot-express.ps1#L7929). Internal entry-script function; source region: `Directory Selection and Tenant Workflow Actions`.

| Parameter  | Declared Type   | Attributes | Default                        | Source Contract                                        |
| ---------- | --------------- | ---------- | ------------------------------ | ------------------------------------------------------ |
| `Fragment` | `System.String` | `[string]` | No explicit default expression | Lower-case query fragment of at least four characters. |
| `Word`     | `System.String` | `[string]` | No explicit default expression | Lower-case complete display-name word.                 |

Outputs and result contract:

Boolean indicating a maximum of one character edit.

Named callers: [Test-DirectoryUserSearchMatch](#test-directoryusersearchmatch).

### Test-DirectoryUserSearchMatch

Matches an exact account identity or every supplied name fragment.

Source: [autopilot-express.ps1:7962](autopilot-express.ps1#L7962). Internal entry-script function; source region: `Directory Selection and Tenant Workflow Actions`.

| Parameter     | Declared Type                                  | Attributes                                                                     | Default                        | Source Contract                                                         |
| ------------- | ---------------------------------------------- | ------------------------------------------------------------------------------ | ------------------------------ | ----------------------------------------------------------------------- |
| `User`        | `System.Object`                                | None declared                                                                  | No explicit default expression | Dictionary-backed or object-backed directory user candidate.            |
| `SearchMode`  | `System.String`                                | `[Parameter(Mandatory)]` `[ValidateSet('ExactUpn', 'DisplayName')]` `[string]` | No explicit default expression | ExactUpn matches the full UPN or complete username, never a prefix.     |
| `Query`       | `System.String`                                | `[AllowEmptyString()]` `[string]`                                              | No explicit default expression | Technician-supplied account identity or whitespace-separated fragments. |
| `Approximate` | `System.Management.Automation.SwitchParameter` | `[switch]`                                                                     | No explicit default expression | Permit the explicit approximate-name matching pass.                     |

Outputs and result contract:

Boolean indicating whether the candidate matches the query.

Other named commands: `Where-Object`.

Named callers: [Get-DirectoryUserSearchRank](#get-directoryusersearchrank), [Get-DirectoryUserSearchResult](#get-directoryusersearchresult), [Search-LiveDirectoryUsers](#search-livedirectoryusers).

### Get-DirectoryUserSearchRank

Ranks a matching candidate by literal name or identity relevance.

Source: [autopilot-express.ps1:8006](autopilot-express.ps1#L8006). Internal entry-script function; source region: `Directory Selection and Tenant Workflow Actions`.

| Parameter | Declared Type   | Attributes                                                       | Default                        | Source Contract                                                 |
| --------- | --------------- | ---------------------------------------------------------------- | ------------------------------ | --------------------------------------------------------------- |
| `User`    | `System.Object` | `[Parameter(Mandatory)]`                                         | No explicit default expression | Eligible directory candidate already matched against the query. |
| `Query`   | `System.String` | `[Parameter(Mandatory)]` `[ValidateNotNullOrEmpty()]` `[string]` | No explicit default expression | Technician-supplied literal identity or name fragments.         |

Outputs and result contract:

Integer relevance tier from zero (strongest) to five (weakest).

Named callers: [Get-DirectoryUserSearchResult](#get-directoryusersearchresult).

### Get-DirectoryUserSearchResult

Returns eligible literal matches in deterministic relevance order.

Source: [autopilot-express.ps1:8048](autopilot-express.ps1#L8048). Internal entry-script function; source region: `Directory Selection and Tenant Workflow Actions`.

| Parameter     | Declared Type                                  | Attributes                                                                     | Default                        | Source Contract                                                          |
| ------------- | ---------------------------------------------- | ------------------------------------------------------------------------------ | ------------------------------ | ------------------------------------------------------------------------ |
| `Users`       | `System.Object[]`                              | `[AllowNull()]` `[AllowEmptyCollection()]` `[object[]]`                        | No explicit default expression | Candidate collection; null and empty collections return no results.      |
| `SearchMode`  | `System.String`                                | `[Parameter(Mandatory)]` `[ValidateSet('ExactUpn', 'DisplayName')]` `[string]` | No explicit default expression | Exact identity or display-name fragment search.                          |
| `Query`       | `System.String`                                | `[AllowEmptyString()]` `[string]`                                              | No explicit default expression | Literal technician query. Empty queries return no results.               |
| `Approximate` | `System.Management.Automation.SwitchParameter` | `[switch]`                                                                     | No explicit default expression | Request approximate matching only after the exact search path allows it. |

Outputs and result contract:

Directory candidates ordered by relevance, display name, then UPN.

Other named commands: `Sort-Object`, `Where-Object`.

Named callers: [Search-DemoDirectoryUsers](#search-demodirectoryusers), [Search-LiveDirectoryUsers](#search-livedirectoryusers).

### Search-DemoDirectoryUsers

Search synthetic accounts through the shared search modes without Graph access.

Source: [autopilot-express.ps1:8079](autopilot-express.ps1#L8079). Internal entry-script function; source region: `Directory Selection and Tenant Workflow Actions`.

| Parameter     | Declared Type                                  | Attributes                                                                     | Default                        | Source Contract                                               |
| ------------- | ---------------------------------------------- | ------------------------------------------------------------------------------ | ------------------------------ | ------------------------------------------------------------- |
| `SearchMode`  | `System.String`                                | `[Parameter(Mandatory)]` `[ValidateSet('ExactUpn', 'DisplayName')]` `[string]` | No explicit default expression | Supported account-name or display-name search mode.           |
| `Query`       | `System.String`                                | `[Parameter(Mandatory)]` `[string]`                                            | No explicit default expression | Literal search text; never executed as an expression.         |
| `Approximate` | `System.Management.Automation.SwitchParameter` | `[switch]`                                                                     | No explicit default expression | Enable approximate matching rather than exact-only selection. |

Outputs and result contract:

Bounded synthetic account array; never real-directory evidence.

Other named commands: `Where-Object`, `Write-Host`.

Named callers: [Search-DemoDirectoryUsers](#search-demodirectoryusers), [Select-DirectoryUser](#select-directoryuser), [Select-TechnicianDirectoryUser](#select-techniciandirectoryuser).

### Search-LiveDirectoryUsers

Retrieves bounded Graph candidate pages for technician-directed search.

Source: [autopilot-express.ps1:8115](autopilot-express.ps1#L8115). Internal entry-script function; source region: `Directory Selection and Tenant Workflow Actions`.

| Parameter     | Declared Type                                  | Attributes                                                                     | Default                        | Source Contract                                                                             |
| ------------- | ---------------------------------------------- | ------------------------------------------------------------------------------ | ------------------------------ | ------------------------------------------------------------------------------------------- |
| `SearchMode`  | `System.String`                                | `[Parameter(Mandatory)]` `[ValidateSet('ExactUpn', 'DisplayName')]` `[string]` | No explicit default expression | Exact account identity or order-independent name-fragment matching.                         |
| `Query`       | `System.String`                                | `[Parameter(Mandatory)]` `[string]`                                            | No explicit default expression | Technician-supplied search text; no ownership-role inference is performed.                  |
| `Approximate` | `System.Management.Automation.SwitchParameter` | `[switch]`                                                                     | No explicit default expression | Use bounded approximate suggestions; still require explicit account selection/revalidation. |

Outputs and result contract:

Array of eligible user dictionaries, bounded by directorySearchLimit.
Graph failures propagate rather than returning misleading partial success.

Other named commands: `ForEach-Object`, `Select-Object`, `Where-Object`, `Write-Host`, `Write-Warning`.

Named callers: [Search-LiveDirectoryUsers](#search-livedirectoryusers), [Select-DirectoryUser](#select-directoryuser), [Select-TechnicianDirectoryUser](#select-techniciandirectoryuser).

### Select-UserFromResults

Present eligible results and validate an explicit account selection.

Source: [autopilot-express.ps1:8204](autopilot-express.ps1#L8204). Internal entry-script function; source region: `Directory Selection and Tenant Workflow Actions`.

| Parameter       | Declared Type                                  | Attributes                                              | Default                        | Source Contract                                                 |
| --------------- | ---------------------------------------------- | ------------------------------------------------------- | ------------------------------ | --------------------------------------------------------------- |
| `Users`         | `System.Object[]`                              | `[AllowNull()]` `[AllowEmptyCollection()]` `[object[]]` | No explicit default expression | Candidate account collection to display.                        |
| `Heading`       | `System.String`                                | `[Parameter(Mandatory)]` `[string]`                     | No explicit default expression | Accessible search-result heading.                               |
| `PreserveOrder` | `System.Management.Automation.SwitchParameter` | `[switch]`                                              | No explicit default expression | Retain recent-account ranking instead of alphabetical ordering. |

Outputs and result contract:

Selected account or null on cancellation/empty results; no assignment.

Other named commands: `Sort-Object`, `Where-Object`, `Write-Host`.

Named callers: [Select-DirectoryUser](#select-directoryuser), [Select-TechnicianDirectoryUser](#select-techniciandirectoryuser).

### Select-DirectoryUser

Select and revalidate an account through recent users or directory searches.

Source: [autopilot-express.ps1:8249](autopilot-express.ps1#L8249). Internal entry-script function; source region: `Directory Selection and Tenant Workflow Actions`.

| Parameter | Declared Type   | Attributes | Default                                                  | Source Contract                                              |
| --------- | --------------- | ---------- | -------------------------------------------------------- | ------------------------------------------------------------ |
| `Heading` | `System.String` | `[string]` | `'Final primary user search (active C/E accounts only)'` | Workflow-specific selection context shown to the technician. |

Outputs and result contract:

Current eligible account or null on cancellation; retains the recent selection only.

Other named commands: `Write-Host`.

Named callers: [Select-TechnicianDirectoryUser](#select-techniciandirectoryuser), [Invoke-StepAssignFinalPrimaryUser](#invoke-stepassignfinalprimaryuser).

### Resolve-LiveAutopilotDeviceBySerial

Resolve one complete Autopilot serial match without choosing duplicates.

Source: [autopilot-express.ps1:8290](autopilot-express.ps1#L8290). Internal entry-script function; source region: `Directory Selection and Tenant Workflow Actions`.

| Parameter | Declared Type   | Attributes                                                       | Default                        | Source Contract                                                        |
| --------- | --------------- | ---------------------------------------------------------------- | ------------------------------ | ---------------------------------------------------------------------- |
| `Serial`  | `System.String` | `[Parameter(Mandatory)]` `[ValidateNotNullOrEmpty()]` `[string]` | No explicit default expression | Canonical serial; a valid empty collection means absent, not an error. |

Outputs and result contract:

Unique exact serial match or null after complete bounded filtered discovery.
Malformed, incomplete or ambiguous results throw.

Other named commands: `Where-Object`.

Named callers: [Get-LiveDeviceInventory](#get-livedeviceinventory), [Resolve-LiveAutopilotContext](#resolve-liveautopilotcontext), [Invoke-StepResolveAutopilotDevice](#invoke-stepresolveautopilotdevice), [Invoke-AutopilotHashImport](#invoke-autopilothashimport), [Resolve-LiveAutopilotTagContext](#resolve-liveautopilottagcontext).

### Resolve-LiveManagedDeviceBySerial

Resolves a unique managed device or confirms an empty serial search.

Source: [autopilot-express.ps1:8315](autopilot-express.ps1#L8315). Internal entry-script function; source region: `Directory Selection and Tenant Workflow Actions`.

| Parameter | Declared Type   | Attributes                                                       | Default                        | Source Contract                                          |
| --------- | --------------- | ---------------------------------------------------------------- | ------------------------------ | -------------------------------------------------------- |
| `Serial`  | `System.String` | `[Parameter(Mandatory)]` `[ValidateNotNullOrEmpty()]` `[string]` | No explicit default expression | Canonical serial number used for the exact Graph filter. |

Outputs and result contract:

One managed-device record, or null for a valid empty response.

Named callers: [Get-LiveDeviceInventory](#get-livedeviceinventory), [Resolve-LiveAutopilotContext](#resolve-liveautopilotcontext), [Wait-ManagedDeviceRemovalVerification](#wait-manageddeviceremovalverification), [Invoke-StepConfirmRecoveryReadiness](#invoke-stepconfirmrecoveryreadiness).

### ConvertTo-EthernetMacAddress

Normalise an optional Ethernet address without substituting another adapter.

Source: [autopilot-express.ps1:8341](autopilot-express.ps1#L8341). Internal entry-script function; source region: `Directory Selection and Tenant Workflow Actions`.

| Parameter     | Declared Type   | Attributes                                      | Default                        | Source Contract                                                                                                                                        |
| ------------- | --------------- | ----------------------------------------------- | ------------------------------ | ------------------------------------------------------------------------------------------------------------------------------------------------------ |
| `Value`       | `System.Object` | `[AllowNull()]` `[object]`                      | No explicit default expression | Intune adapter inventory value; null or blank means not yet available.                                                                                 |
| `AdapterName` | `System.String` | `[ValidateSet('Ethernet', 'Wi-Fi')]` `[string]` | `'Ethernet'`                   | Adapter named in error messages. Defaults to Ethernet; Wi-Fi reuses the same rules but is always stored separately and never substituted for Ethernet. |

Outputs and result contract:

Uppercase colon-separated unicast address, or an empty string. Invalid values throw.

Named callers: [Get-LiveDeviceInventory](#get-livedeviceinventory).

### ConvertTo-WindowsReleaseName

Turn an Intune Windows version (for example 10.0.26200.6584) into a release name.

Source: [autopilot-express.ps1:8364](autopilot-express.ps1#L8364). Internal entry-script function; source region: `Directory Selection and Tenant Workflow Actions`.

| Parameter   | Declared Type   | Attributes                 | Default                        | Source Contract                                                                |
| ----------- | --------------- | -------------------------- | ------------------------------ | ------------------------------------------------------------------------------ |
| `OsVersion` | `System.Object` | `[AllowNull()]` `[object]` | No explicit default expression | Intune osVersion text; null, blank or malformed values return an empty string. |

Outputs and result contract:

Release text such as 'Windows 11 25H2', or an empty string.

Named callers: [Get-LiveDeviceInventory](#get-livedeviceinventory).

### Get-LiveDeviceInventory

Read authoritative Intune hostname, adapter, user and Windows details for one bound device.

Source: [autopilot-express.ps1:8387](autopilot-express.ps1#L8387). Internal entry-script function; source region: `Directory Selection and Tenant Workflow Actions`.

| Parameter | Declared Type                    | Attributes                                                                               | Default                        | Source Contract                                                                    |
| --------- | -------------------------------- | ---------------------------------------------------------------------------------------- | ------------------------------ | ---------------------------------------------------------------------------------- |
| `Device`  | `System.Collections.IDictionary` | `[Parameter(Mandatory)]` `[ValidateNotNullOrEmpty()]` `[System.Collections.IDictionary]` | No explicit default expression | Current serial and tenant-bound device record, with an optional managed-device ID. |

Outputs and result contract:

Detached inventory dictionary, or null when no managed device exists yet.

Named callers: [Invoke-DeviceInventoryCheck](#invoke-deviceinventorycheck).

### Invoke-DeviceInventoryPrefetch

Collect Intune details for several devices in as few Graph requests as possible.

Source: [autopilot-express.ps1:8450](autopilot-express.ps1#L8450). Internal entry-script function; source region: `Directory Selection and Tenant Workflow Actions`.

| Parameter | Declared Type     | Attributes                                                       | Default                        | Source Contract                                                |
| --------- | ----------------- | ---------------------------------------------------------------- | ------------------------------ | -------------------------------------------------------------- |
| `Device`  | `System.Object[]` | `[Parameter(Mandatory)]` `[AllowEmptyCollection()]` `[object[]]` | No explicit default expression | Device records about to be checked; blank serials are ignored. |

Outputs and result contract:

None. The caller must call Clear-GraphReadPrefetch when it has finished.

Named callers: [Invoke-DeviceInventoryPolling](#invoke-deviceinventorypolling), [Update-DeviceInventoryFromIntune](#update-deviceinventoryfromintune).

### Get-DeviceInventoryInterval

Validate the central automatic-inventory interval, defaulting to five minutes.

Source: [autopilot-express.ps1:8487](autopilot-express.ps1#L8487). Internal entry-script function; source region: `Directory Selection and Tenant Workflow Actions`.

No formal parameters declared. Captured state and enclosing scope may still be inputs.

Outputs and result contract:

Positive whole-minute interval; malformed configuration throws before any read or save.

Named callers: [Invoke-DeviceInventoryCheck](#invoke-deviceinventorycheck), [Invoke-DeviceInventoryPolling](#invoke-deviceinventorypolling).

### Test-DeviceInventoryEligible

Identify active devices whose physical reseal milestone has been confirmed.

Source: [autopilot-express.ps1:8500](autopilot-express.ps1#L8500). Internal entry-script function; source region: `Directory Selection and Tenant Workflow Actions`.

| Parameter | Declared Type                    | Attributes                                                  | Default                        | Source Contract                                                             |
| --------- | -------------------------------- | ----------------------------------------------------------- | ------------------------------ | --------------------------------------------------------------------------- |
| `Device`  | `System.Collections.IDictionary` | `[Parameter(Mandatory)]` `[System.Collections.IDictionary]` | No explicit default expression | Current-cycle record; display codes are not used to identify the milestone. |

Outputs and result contract:

Boolean. Does not change steps or infer physical completion from inventory.

Named callers: [Invoke-DeviceInventoryCheck](#invoke-deviceinventorycheck), [Invoke-DeviceInventoryPolling](#invoke-deviceinventorypolling).

### Get-IntuneInventoryFieldSetVersion

Report which set of Intune details the current script captures.

Source: [autopilot-express.ps1:8516](autopilot-express.ps1#L8516). Internal entry-script function; source region: `Directory Selection and Tenant Workflow Actions`.

No formal parameters declared. Captured state and enclosing scope may still be inputs.

Outputs and result contract:

Version number as text, because saved inventory values are all text.

Named callers: [Test-DeviceInventoryDetailMissing](#test-deviceinventorydetailmissing), [Invoke-DeviceInventoryCheck](#invoke-deviceinventorycheck).

### Test-DeviceInventoryDetailMissing

Decide whether a saved device still needs details from Intune ("missing only").

Source: [autopilot-express.ps1:8531](autopilot-express.ps1#L8531). Internal entry-script function; source region: `Directory Selection and Tenant Workflow Actions`.

| Parameter         | Declared Type                                  | Attributes                                                  | Default                        | Source Contract                                                 |
| ----------------- | ---------------------------------------------- | ----------------------------------------------------------- | ------------------------------ | --------------------------------------------------------------- |
| `Device`          | `System.Collections.IDictionary`               | `[Parameter(Mandatory)]` `[System.Collections.IDictionary]` | No explicit default expression | Saved device dictionary from the current session or an archive. |
| `IncludeNotFound` | `System.Management.Automation.SwitchParameter` | `[switch]`                                                  | No explicit default expression | Recheck devices previously recorded as not found in Intune.     |

Outputs and result contract:

Boolean. Reads nothing and changes nothing.

Named callers: [Update-DeviceInventoryFromIntune](#update-deviceinventoryfromintune).

### Invoke-DeviceInventoryCheck

Stage missing Intune metadata on a detached record, with a five-minute retry interval.

Source: [autopilot-express.ps1:8557](autopilot-express.ps1#L8557). Internal entry-script function; source region: `Directory Selection and Tenant Workflow Actions`.

| Parameter               | Declared Type                                  | Attributes                                                  | Default                        | Source Contract                                                                                                                                                                                                                       |
| ----------------------- | ---------------------------------------------- | ----------------------------------------------------------- | ------------------------------ | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `Device`                | `System.Collections.IDictionary`               | `[Parameter(Mandatory)]` `[System.Collections.IDictionary]` | No explicit default expression | Detached record proposal; never pass an actively displayed record before saving.                                                                                                                                                      |
| `Force`                 | `System.Management.Automation.SwitchParameter` | `[switch]`                                                  | No explicit default expression | Make the final dispatch read despite the interval, milestone or completeness.                                                                                                                                                         |
| `Now`                   | `System.DateTime`                              | `[datetime]`                                                | `(Get-Date)`                   | Local clock used for scheduling and offline time-boundary tests.                                                                                                                                                                      |
| `MarkMissingAsNotFound` | `System.Management.Automation.SwitchParameter` | `[switch]`                                                  | No explicit default expression | Backfill only. A deleted (HTTP 404) bound device, or no managed device for the serial, is recorded as NotFound with saved values kept. Without this switch the live polling behaviour (Pending or Error, retried later) is unchanged. |

Outputs and result contract:

Boolean indicating a staged inventory check; transport failures become Error status.

Other named commands: `Get-Date`.

Named callers: [Invoke-DeviceInventoryPolling](#invoke-deviceinventorypolling), [Update-DeviceInventoryFromIntune](#update-deviceinventoryfromintune), [Complete-DeviceDispatch](#complete-devicedispatch).

### Invoke-DeviceInventoryPolling

Service due read-only inventory checks and publish only after a verified checkpoint save.

Source: [autopilot-express.ps1:8637](autopilot-express.ps1#L8637). Internal entry-script function; source region: `Directory Selection and Tenant Workflow Actions`.

| Parameter  | Declared Type                  | Attributes                             | Default                        | Source Contract                                                                                                                                     |
| ---------- | ------------------------------ | -------------------------------------- | ------------------------------ | --------------------------------------------------------------------------------------------------------------------------------------------------- |
| `Records`  | `System.Collections.Hashtable` | `[Parameter(Mandatory)]` `[hashtable]` | No explicit default expression | Active session container shared by all navigation paths.                                                                                            |
| `Schedule` | `System.Collections.Hashtable` | `[hashtable]`                          | No explicit default expression | Optional prompt-local scan deadline. Discard before executing any command; only the main runspace may update records while this schedule is in use. |
| `Now`      | `System.DateTime`              | `[datetime]`                           | `(Get-Date)`                   | Current clock for scheduling and deterministic offline boundary checks.                                                                             |

Outputs and result contract:

None. Announcements are emitted only after durable save; failures propagate.

Other named commands: `Get-Date`, `Where-Object`, `Write-Host`, `Write-Verbose`.

Named callers: [Read-DeviceInventoryInput](#read-deviceinventoryinput).

### Get-ArchivedDeviceRecordFile

List archived Live device-record files, oldest first.

Source: [autopilot-express.ps1:8709](autopilot-express.ps1#L8709). Internal entry-script function; source region: `Directory Selection and Tenant Workflow Actions`.

No formal parameters declared. Captured state and enclosing scope may still be inputs.

Outputs and result contract:

FileInfo array; empty when the archive folder does not exist yet.

Other named commands: `Get-ChildItem`, `Sort-Object`, `Test-Path`, `Where-Object`.

Named callers: [Update-DeviceInventoryFromIntune](#update-deviceinventoryfromintune).

### Update-DeviceInventoryFromIntune

Fill in missing Intune details for devices in the current session and all Live archives.

Source: [autopilot-express.ps1:8726](autopilot-express.ps1#L8726). Internal entry-script function; source region: `Directory Selection and Tenant Workflow Actions`.

| Parameter         | Declared Type                                  | Attributes                             | Default                        | Source Contract                                                             |
| ----------------- | ---------------------------------------------- | -------------------------------------- | ------------------------------ | --------------------------------------------------------------------------- |
| `Records`         | `System.Collections.Hashtable`                 | `[Parameter(Mandatory)]` `[hashtable]` | No explicit default expression | Current-session container (@{ Value = records }) shared with the main menu. |
| `IncludeNotFound` | `System.Management.Automation.SwitchParameter` | `[switch]`                             | No explicit default expression | Also recheck devices previously recorded as not found in Intune.            |

Outputs and result contract:

Ordered summary dictionary of counts and readable outcome lines.

Other named commands: `ConvertFrom-Json`, `ConvertTo-Json`, `ForEach-Object`, `Get-Command`, `Get-Content`, `Get-Date`, `Get-FileHash`, `Select-Object`, `Split-Path`, `Where-Object`, `Write-Progress`.

Named callers: [Show-DeviceInventoryBackfill](#show-deviceinventorybackfill).

### Show-DeviceInventoryBackfill

Data Settings option 5: fill in missing Intune details for devices already processed.

Source: [autopilot-express.ps1:8876](autopilot-express.ps1#L8876). Internal entry-script function; source region: `Directory Selection and Tenant Workflow Actions`.

| Parameter | Declared Type                  | Attributes                             | Default                        | Source Contract                                      |
| --------- | ------------------------------ | -------------------------------------- | ------------------------------ | ---------------------------------------------------- |
| `Records` | `System.Collections.Hashtable` | `[Parameter(Mandatory)]` `[hashtable]` | No explicit default expression | Current-session container shared with the main menu. |

Outputs and result contract:

Host text only; always returns control to the calling menu.

Other named commands: `Write-Host`.

No statically named function caller in this inventory. Top-level, dynamic and callback invocation remain possible.

### Read-DeviceInventoryInput

Keep the normal host prompt active while the main runspace services inventory.

Source: [autopilot-express.ps1:8929](autopilot-express.ps1#L8929). Internal entry-script function; source region: `Directory Selection and Tenant Workflow Actions`.

| Parameter | Declared Type                  | Attributes                             | Default                        | Source Contract                                                            |
| --------- | ------------------------------ | -------------------------------------- | ------------------------------ | -------------------------------------------------------------------------- |
| `Prompt`  | `System.String`                | `[Parameter(Mandatory)]` `[string]`    | No explicit default expression | Existing accessible prompt, including its existing default text.           |
| `Records` | `System.Collections.Hashtable` | `[Parameter(Mandatory)]` `[hashtable]` | No explicit default expression | Current session container; no credential or SDK context crosses runspaces. |

Outputs and result contract:

One response string, preserving ordinary host editing and scanner input.

Other named commands: `ForEach-Object`, `Select-Object`, `Write-Debug`, `Write-Error`, `Write-Host`, `Write-Information`, `Write-Verbose`, `Write-Warning`.

Named callers: [Read-ValidatedInput](#read-validatedinput).

### Resolve-LiveEntraDeviceObject

Resolve one Entra object for the exact device registration identifier.

Source: [autopilot-express.ps1:9001](autopilot-express.ps1#L9001). Internal entry-script function; source region: `Directory Selection and Tenant Workflow Actions`.

| Parameter         | Declared Type   | Attributes                                                       | Default                        | Source Contract                                                     |
| ----------------- | --------------- | ---------------------------------------------------------------- | ------------------------------ | ------------------------------------------------------------------- |
| `AzureAdDeviceId` | `System.String` | `[Parameter(Mandatory)]` `[ValidateNotNullOrEmpty()]` `[string]` | No explicit default expression | Device registration ID, distinct from the returned Entra object ID. |

Outputs and result contract:

Matching object or null. Malformed, paged or ambiguous results throw.

Named callers: [Resolve-LiveAutopilotContext](#resolve-liveautopilotcontext), [Resolve-LiveMembershipContext](#resolve-livemembershipcontext).

### Get-LiveManagedDevicePrimaryUsers

Read the complete validated primary-user relationship for one managed device.

Source: [autopilot-express.ps1:9028](autopilot-express.ps1#L9028). Internal entry-script function; source region: `Directory Selection and Tenant Workflow Actions`.

| Parameter         | Declared Type   | Attributes                          | Default                        | Source Contract                                       |
| ----------------- | --------------- | ----------------------------------- | ------------------------------ | ----------------------------------------------------- |
| `ManagedDeviceId` | `System.String` | `[Parameter(Mandatory)]` `[string]` | No explicit default expression | Freshly resolved Intune GUID, not an Entra device ID. |

Outputs and result contract:

Validated user collection; incomplete/malformed evidence throws.

Named callers: [Wait-PrimaryUserAssignmentVerification](#wait-primaryuserassignmentverification), [Invoke-LivePrimaryUserAssignment](#invoke-liveprimaryuserassignment).

### Test-ManagedDevicePrimaryUserMatch

Verifies that one observed primary-user relationship matches the target.

Source: [autopilot-express.ps1:9055](autopilot-express.ps1#L9055). Internal entry-script function; source region: `Directory Selection and Tenant Workflow Actions`.

| Parameter | Declared Type     | Attributes                                              | Default                        | Source Contract                                                |
| --------- | ----------------- | ------------------------------------------------------- | ------------------------------ | -------------------------------------------------------------- |
| `Users`   | `System.Object[]` | `[AllowNull()]` `[AllowEmptyCollection()]` `[object[]]` | No explicit default expression | Complete read-back collection; empty collections do not match. |
| `User`    | `System.Object`   | `[Parameter(Mandatory)]`                                | No explicit default expression | Selected target identity, not an inferred account role.        |

Outputs and result contract:

Boolean indicating an exclusive matching primary-user relationship.

Named callers: [Wait-PrimaryUserAssignmentVerification](#wait-primaryuserassignmentverification), [Invoke-LivePrimaryUserAssignment](#invoke-liveprimaryuserassignment).

### Get-LiveTenantBinding

Validate actual SDK tenant and optional record ownership without changing state.

Source: [autopilot-express.ps1:9082](autopilot-express.ps1#L9082). Internal entry-script function; source region: `Directory Selection and Tenant Workflow Actions`.

| Parameter      | Declared Type                                  | Attributes    | Default                        | Source Contract                                                           |
| -------------- | ---------------------------------------------- | ------------- | ------------------------------ | ------------------------------------------------------------------------- |
| `Device`       | `System.Object`                                | None declared | No explicit default expression | Optional device dictionary whose persisted tenant must match the session. |
| `AllowUnbound` | `System.Management.Automation.SwitchParameter` | `[switch]`    | No explicit default expression | Permit only clean new records; resolution stages binding after all reads. |

Outputs and result contract:

Authenticated tenant GUID text, or an actionable terminating refusal.

Other named commands: `Get-MgContext`.

Named callers: [Invoke-ExistingDeviceLifecycle](#invoke-existingdevicelifecycle), [Get-DeviceActionContext](#get-deviceactioncontext), [Resolve-DeviceActionTarget](#resolve-deviceactiontarget), [Initialize-LiveTenantContext](#initialize-livetenantcontext), [Get-LiveDeviceInventory](#get-livedeviceinventory), [Resolve-LiveAutopilotContext](#resolve-liveautopilotcontext), [Get-AutopilotImportReceipt](#get-autopilotimportreceipt), [Invoke-AutopilotHashImport](#invoke-autopilothashimport), [Resolve-LiveAutopilotTagContext](#resolve-liveautopilottagcontext), [Invoke-StepClearUserlessEnrollmentStatus](#invoke-stepclearuserlessenrollmentstatus), [Invoke-AutopilotManifestStep](#invoke-autopilotmanifeststep), [Undo-LatestTechnicianConfirmation](#undo-latesttechnicianconfirmation).

### Resolve-LiveAutopilotContext

Refresh device identifiers only after all identity reads succeed.

Source: [autopilot-express.ps1:9128](autopilot-express.ps1#L9128). Internal entry-script function; source region: `Directory Selection and Tenant Workflow Actions`.

| Parameter              | Declared Type   | Attributes               | Default                        | Source Contract                                                                                                                                                         |
| ---------------------- | --------------- | ------------------------ | ------------------------------ | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `Device`               | `System.Object` | `[Parameter(Mandatory)]` | No explicit default expression | Existing device dictionary to refresh from current Graph evidence.                                                                                                      |
| `KnownAutopilotDevice` | `System.Object` | None declared            | No explicit default expression | Autopilot identity already read by the caller in this operation (for example the poll that found it). Skips a second identical serial search; it must match the serial. |

Outputs and result contract:

Resolved Graph records. Failed reads leave the device unchanged;
absent records clear cached mutation identifiers on successful refresh.

Named callers: [Resolve-DeviceActionTarget](#resolve-deviceactiontarget), [Invoke-LivePrimaryUserAssignment](#invoke-liveprimaryuserassignment), [Invoke-StepResolveAutopilotDevice](#invoke-stepresolveautopilotdevice), [Invoke-StepRemoveAssociatedManagedDevice](#invoke-stepremoveassociatedmanageddevice), [Invoke-StepClearUserlessEnrollmentStatus](#invoke-stepclearuserlessenrollmentstatus), [Invoke-StepRetryFailedApps](#invoke-stepretryfailedapps).

### Get-StoredEntraDeviceObject

Reuse the saved Entra object ID when the device registration has not changed.

Source: [autopilot-express.ps1:9181](autopilot-express.ps1#L9181). Internal entry-script function; source region: `Directory Selection and Tenant Workflow Actions`.

| Parameter         | Declared Type   | Attributes                          | Default                        | Source Contract                                                            |
| ----------------- | --------------- | ----------------------------------- | ------------------------------ | -------------------------------------------------------------------------- |
| `Device`          | `System.Object` | `[Parameter(Mandatory)]`            | No explicit default expression | Workflow record holding the saved AzureAdDeviceId and EntraDeviceId.       |
| `AzureAdDeviceId` | `System.String` | `[Parameter(Mandatory)]` `[string]` | No explicit default expression | Registration ID freshly reported by Autopilot or Intune in this operation. |

Outputs and result contract:

Minimal identity (id, deviceId) or null when a fresh lookup is required.

Named callers: [Resolve-LiveAutopilotContext](#resolve-liveautopilotcontext), [Resolve-LiveMembershipContext](#resolve-livemembershipcontext).

### Get-LivePreProvisioningGroup

Resolve exactly one pre-provisioning group from its configured display name.

Source: [autopilot-express.ps1:9201](autopilot-express.ps1#L9201). Internal entry-script function; source region: `Directory Selection and Tenant Workflow Actions`.

No formal parameters declared. Captured state and enclosing scope may still be inputs.

Outputs and result contract:

Validated group; missing, duplicate or malformed matches throw before mutation.

Other named commands: `Get-Date`.

Named callers: [Initialize-LiveTenantContext](#initialize-livetenantcontext), [Test-GraphCapabilities](#test-graphcapabilities), [Invoke-PreProvisioningMembershipChange](#invoke-preprovisioningmembershipchange).

### Clear-PreProvisioningGroupCache

Forget the saved pre-provisioning group so the next lookup reads Graph again.

Source: [autopilot-express.ps1:9227](autopilot-express.ps1#L9227). Internal entry-script function; source region: `Directory Selection and Tenant Workflow Actions`.

No formal parameters declared. Captured state and enclosing scope may still be inputs.

Outputs and result contract:

None.

Named callers: [Invoke-PreProvisioningMembershipChange](#invoke-preprovisioningmembershipchange).

### Get-LiveAutopilotDeviceById

Read current tag and assigned-user properties for one Autopilot identity.

Source: [autopilot-express.ps1:9237](autopilot-express.ps1#L9237). Internal entry-script function; source region: `Directory Selection and Tenant Workflow Actions`.

| Parameter           | Declared Type   | Attributes                          | Default                        | Source Contract                                                             |
| ------------------- | --------------- | ----------------------------------- | ------------------------------ | --------------------------------------------------------------------------- |
| `AutopilotDeviceId` | `System.String` | `[Parameter(Mandatory)]` `[string]` | No explicit default expression | Resolved Autopilot GUID, distinct from managed-device and Entra identities. |

Outputs and result contract:

Matching identity from the stable v1.0 resource read; failures propagate.

Named callers: [Wait-PrimaryUserAssignmentVerification](#wait-primaryuserassignmentverification), [Wait-AutopilotGroupTagVerification](#wait-autopilotgrouptagverification), [Resolve-LiveAutopilotTagContext](#resolve-liveautopilottagcontext).

### Test-LiveGroupMembership

Reads direct membership, failing closed on ambiguous Graph errors.

Source: [autopilot-express.ps1:9254](autopilot-express.ps1#L9254). Internal entry-script function; source region: `Directory Selection and Tenant Workflow Actions`.

| Parameter           | Declared Type                                  | Attributes                                                       | Default                        | Source Contract                                                                                                                                          |
| ------------------- | ---------------------------------------------- | ---------------------------------------------------------------- | ------------------------------ | -------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `GroupId`           | `System.String`                                | `[Parameter(Mandatory)]` `[ValidateNotNullOrEmpty()]` `[string]` | No explicit default expression | Group object ID to inspect.                                                                                                                              |
| `DirectoryObjectId` | `System.String`                                | `[Parameter(Mandatory)]` `[ValidateNotNullOrEmpty()]` `[string]` | No explicit default expression | Device directory object ID to inspect.                                                                                                                   |
| `GroupConfirmed`    | `System.Management.Automation.SwitchParameter` | `[switch]`                                                       | No explicit default expression | The caller has just written to this exact group and Graph accepted it, which proves the group exists; the separate group existence read is then skipped. |

Outputs and result contract:

Boolean membership state, or a terminating read/identity error.

Other named commands: `Where-Object`.

Named callers: [Wait-GroupMembershipVerification](#wait-groupmembershipverification).

### Get-GraphVerificationPolicy

Validates the existing attempt and pause settings for read-back polling.

Source: [autopilot-express.ps1:9289](autopilot-express.ps1#L9289). Internal entry-script function; source region: `Directory Selection and Tenant Workflow Actions`.

No formal parameters declared. Captured state and enclosing scope may still be inputs.

Outputs and result contract:

Dictionary with MaxAttempts (1-20) and IntervalSeconds (0-60).

Named callers: [Invoke-LivePrimaryUserAssignment](#invoke-liveprimaryuserassignment), [Invoke-StepResolveAutopilotDevice](#invoke-stepresolveautopilotdevice), [Invoke-AutopilotHashImport](#invoke-autopilothashimport), [Invoke-StepRemoveAssociatedManagedDevice](#invoke-stepremoveassociatedmanageddevice), [Invoke-StepApplyGroupTag](#invoke-stepapplygrouptag), [Invoke-PreProvisioningMembershipChange](#invoke-preprovisioningmembershipchange).

### Wait-PrimaryUserAssignmentVerification

Polls one assignment surface without repeating its mutation.

Source: [autopilot-express.ps1:9311](autopilot-express.ps1#L9311). Internal entry-script function; source region: `Directory Selection and Tenant Workflow Actions`.

| Parameter         | Declared Type   | Attributes                                                                        | Default                        | Source Contract                                                     |
| ----------------- | --------------- | --------------------------------------------------------------------------------- | ------------------------------ | ------------------------------------------------------------------- |
| `Surface`         | `System.String` | `[Parameter(Mandatory)]` `[ValidateSet('Autopilot', 'ManagedDevice')]` `[string]` | No explicit default expression | Autopilot UPN or exclusive ManagedDevice primary-user relationship. |
| `DeviceId`        | `System.String` | `[Parameter(Mandatory)]` `[ValidateNotNullOrEmpty()]` `[string]`                  | No explicit default expression | Identity for the selected assignment surface.                       |
| `User`            | `System.Object` | `[Parameter(Mandatory)]`                                                          | No explicit default expression | Explicitly selected target identity.                                |
| `MaxAttempts`     | `System.Int32`  | `[Parameter(Mandatory)]` `[ValidateRange(1, 20)]` `[int]`                         | No explicit default expression | Total read-back attempts including the immediate first read.        |
| `IntervalSeconds` | `System.Int32`  | `[Parameter(Mandatory)]` `[ValidateRange(0, 60)]` `[int]`                         | No explicit default expression | Fixed pause between unsuccessful reads; zero is useful for tests.   |

Outputs and result contract:

Dictionary containing Confirmed and the number of Attempts performed.

Other named commands: `Start-Sleep`.

Named callers: [Invoke-LivePrimaryUserAssignment](#invoke-liveprimaryuserassignment).

### Invoke-LivePrimaryUserAssignment

Submit selected-user assignments once and verify each supported assignment surface.

Source: [autopilot-express.ps1:9357](autopilot-express.ps1#L9357). Internal entry-script function; source region: `Directory Selection and Tenant Workflow Actions`.

| Parameter | Declared Type   | Attributes               | Default                        | Source Contract                                                   |
| --------- | --------------- | ------------------------ | ------------------------------ | ----------------------------------------------------------------- |
| `Device`  | `System.Object` | `[Parameter(Mandatory)]` | No explicit default expression | Mutable workflow record with fresh validated device identities.   |
| `User`    | `System.Object` | `[Parameter(Mandatory)]` | No explicit default expression | Explicitly selected account revalidated before either assignment. |

Outputs and result contract:

Attempted/submitted/verified evidence with safe errors. Accepted or ambiguous writes
are not automatically replayed when read-back fails.

Other named commands: `Out-Null`, `Where-Object`.

Named callers: [Invoke-StepAssignTechnicianPrimaryUser](#invoke-stepassigntechnicianprimaryuser), [Invoke-StepAssignFinalPrimaryUser](#invoke-stepassignfinalprimaryuser).

### Invoke-StepResolveAutopilotDevice

Resolve the selected serial and associated identities, or offer guarded hash import.

Source: [autopilot-express.ps1:9481](autopilot-express.ps1#L9481). Internal entry-script function; source region: `Directory Selection and Tenant Workflow Actions`.

| Parameter        | Declared Type   | Attributes               | Default                        | Source Contract                                                               |
| ---------------- | --------------- | ------------------------ | ------------------------------ | ----------------------------------------------------------------------------- |
| `Device`         | `System.Object` | `[Parameter(Mandatory)]` | No explicit default expression | Selected record; successful resolution updates tenant-bound identity context. |
| `StepDefinition` | `System.Object` | `[Parameter(Mandatory)]` | No explicit default expression | Validated ResolveAutopilotDevice manifest entry.                              |

Outputs and result contract:

Operation result. Live uses serial-filtered exact matching; Demo remains synthetic.
Missing/pending imports do not establish verified Autopilot presence.

Other named commands: `Start-Sleep`, `Write-Host`.

Named callers: [Invoke-AutopilotManifestStep](#invoke-autopilotmanifeststep).

### ConvertTo-AutopilotImportReceipt

Validates and copies the eight hash-free fields of one import receipt.

Source: [autopilot-express.ps1:9566](autopilot-express.ps1#L9566). Internal entry-script function; source region: `Directory Selection and Tenant Workflow Actions`.

| Parameter           | Declared Type                                  | Attributes                               | Default                        | Source Contract                                           |
| ------------------- | ---------------------------------------------- | ---------------------------------------- | ------------------------------ | --------------------------------------------------------- |
| `Value`             | `System.Object`                                | `[Parameter(Mandatory)]` `[AllowNull()]` | No explicit default expression | Normalised ledger entry or legacy journal dictionary.     |
| `AllowLedgerFields` | `System.Management.Automation.SwitchParameter` | `[switch]`                               | No explicit default expression | Accept the ledger-only RecordedAt and Source text fields. |

Outputs and result contract:

Hashtable with exactly SchemaVersion, RecordId, TenantId, Serial, ImportId,
AutopilotImportId, State and SubmittedAt. Throws when the evidence is malformed.

Other named commands: `Get-Date`, `Where-Object`.

Named callers: [Get-AutopilotImportReceipt](#get-autopilotimportreceipt), [Import-LegacyAutopilotImportEvidence](#import-legacyautopilotimportevidence).

### Get-AutopilotImportReceipt

Validates ledger ownership before resuming an asynchronous import.

Source: [autopilot-express.ps1:9613](autopilot-express.ps1#L9613). Internal entry-script function; source region: `Directory Selection and Tenant Workflow Actions`.

| Parameter | Declared Type                    | Attributes                                                  | Default                        | Source Contract                                                         |
| --------- | -------------------------------- | ----------------------------------------------------------- | ------------------------------ | ----------------------------------------------------------------------- |
| `Device`  | `System.Collections.IDictionary` | `[Parameter(Mandatory)]` `[System.Collections.IDictionary]` | No explicit default expression | Selected workflow record whose tenant and serial must remain unchanged. |

Outputs and result contract:

Hash-free eight-field receipt hashtable, or null when no intent was persisted.

Other named commands: `Select-Object`, `Where-Object`.

Named callers: [Invoke-StepResolveAutopilotDevice](#invoke-stepresolveautopilotdevice), [Invoke-AutopilotHashImport](#invoke-autopilothashimport).

### Save-AutopilotImportLedgerEntry

Appends one hash-free import receipt to the record ledger and saves durably.

Source: [autopilot-express.ps1:9637](autopilot-express.ps1#L9637). Internal entry-script function; source region: `Directory Selection and Tenant Workflow Actions`.

| Parameter | Declared Type                    | Attributes                                                  | Default                        | Source Contract                                                         |
| --------- | -------------------------------- | ----------------------------------------------------------- | ------------------------------ | ----------------------------------------------------------------------- |
| `Device`  | `System.Collections.IDictionary` | `[Parameter(Mandatory)]` `[System.Collections.IDictionary]` | No explicit default expression | Session record that receives the entry.                                 |
| `Receipt` | `System.Collections.Hashtable`   | `[Parameter(Mandatory)]` `[hashtable]`                      | No explicit default expression | Validated eight-field receipt; it is copied, never stored by reference. |

Outputs and result contract:

None. Throws when the entry cannot be saved.

Other named commands: `Get-Date`.

Named callers: [Invoke-AutopilotHashImport](#invoke-autopilothashimport).

### Invoke-AutopilotHashImport

Submits a selected hash once and resumes by reading durable import state.

Source: [autopilot-express.ps1:9662](autopilot-express.ps1#L9662). Internal entry-script function; source region: `Directory Selection and Tenant Workflow Actions`.

| Parameter | Declared Type   | Attributes               | Default                        | Source Contract                                                       |
| --------- | --------------- | ------------------------ | ------------------------------ | --------------------------------------------------------------------- |
| `Device`  | `System.Object` | `[Parameter(Mandatory)]` | No explicit default expression | Current selected workflow, guarded against tenant and serial changes. |

Outputs and result contract:

Import outcome dictionary, or null when the import option is declined.

Other named commands: `Get-Date`, `Start-Sleep`, `Where-Object`, `Write-Host`.

Named callers: [Invoke-StepResolveAutopilotDevice](#invoke-stepresolveautopilotdevice).

### Get-AutopilotHashImportSettings

Validates opt-in hash discovery settings without opening files or Graph.

Source: [autopilot-express.ps1:9735](autopilot-express.ps1#L9735). Internal entry-script function; source region: `Directory Selection and Tenant Workflow Actions`.

No formal parameters declared. Captured state and enclosing scope may still be inputs.

Outputs and result contract:

Validated settings; older configurations keep the external upload flow.

Other named commands: `Split-Path`.

Named callers: [Test-LiveRuntimeConfiguration](#test-liveruntimeconfiguration), [Get-AutopilotHashCandidate](#get-autopilothashcandidate).

### Get-AutopilotHashCandidate

Lists bounded filename candidates without reading or uploading hashes.

Source: [autopilot-express.ps1:9763](autopilot-express.ps1#L9763). Internal entry-script function; source region: `Directory Selection and Tenant Workflow Actions`.

No formal parameters declared. Captured state and enclosing scope may still be inputs.

Outputs and result contract:

Array of unique full CSV paths, sorted for explicit technician selection.

Other named commands: `ForEach-Object`, `Get-ChildItem`, `Get-CimInstance`, `Join-Path`, `Select-Object`, `Sort-Object`, `Split-Path`, `Test-Path`, `Write-Host`.

Named callers: [Select-AutopilotHashRow](#select-autopilothashrow).

### Select-AutopilotHashRow

Requires explicit file selection and validates the workflow-matched row.

Source: [autopilot-express.ps1:9804](autopilot-express.ps1#L9804). Internal entry-script function; source region: `Directory Selection and Tenant Workflow Actions`.

| Parameter | Declared Type   | Attributes                                                       | Default                        | Source Contract                                           |
| --------- | --------------- | ---------------------------------------------------------------- | ------------------------------ | --------------------------------------------------------- |
| `Serial`  | `System.String` | `[Parameter(Mandatory)]` `[ValidateNotNullOrEmpty()]` `[string]` | No explicit default expression | Selected workflow serial, never inferred from a filename. |

Outputs and result contract:

Validated row dictionary, or null on cancellation. No upload is performed.

Other named commands: `Write-Host`.

Named callers: [Invoke-AutopilotHashImport](#invoke-autopilothashimport).

### Get-AutopilotHashRow

Reads one serial-matched hardware-hash row without exposing hash data.

Source: [autopilot-express.ps1:9833](autopilot-express.ps1#L9833). Internal entry-script function; source region: `Directory Selection and Tenant Workflow Actions`.

| Parameter | Declared Type   | Attributes                                                       | Default                        | Source Contract                                                             |
| --------- | --------------- | ---------------------------------------------------------------- | ------------------------------ | --------------------------------------------------------------------------- |
| `Path`    | `System.String` | `[Parameter(Mandatory)]` `[ValidateNotNullOrEmpty()]` `[string]` | No explicit default expression | Explicitly selected CSV file, accessed literally rather than as a wildcard. |
| `Serial`  | `System.String` | `[Parameter(Mandatory)]` `[ValidateNotNullOrEmpty()]` `[string]` | No explicit default expression | Current workflow serial which must match exactly one row, ignoring case.    |

Outputs and result contract:

Dictionary containing the matched serial and its base64 hardware identifier.

Other named commands: `Get-Item`, `Import-Csv`.

Named callers: [Select-AutopilotHashRow](#select-autopilothashrow).

### Wait-ManagedDeviceRemovalVerification

Polls the serial search until no managed device remains.

Source: [autopilot-express.ps1:9885](autopilot-express.ps1#L9885). Internal entry-script function; source region: `Directory Selection and Tenant Workflow Actions`.

| Parameter         | Declared Type   | Attributes                                                       | Default                        | Source Contract                                      |
| ----------------- | --------------- | ---------------------------------------------------------------- | ------------------------------ | ---------------------------------------------------- |
| `Serial`          | `System.String` | `[Parameter(Mandatory)]` `[ValidateNotNullOrEmpty()]` `[string]` | No explicit default expression | Canonical serial whose Intune record must be absent. |
| `MaxAttempts`     | `System.Int32`  | `[Parameter(Mandatory)]` `[ValidateRange(1, 20)]` `[int]`        | No explicit default expression | Total checks including the immediate first read.     |
| `IntervalSeconds` | `System.Int32`  | `[Parameter(Mandatory)]` `[ValidateRange(0, 60)]` `[int]`        | No explicit default expression | Pause only between unsuccessful checks.              |

Outputs and result contract:

Dictionary with Confirmed, Attempts and ObservedManagedDeviceId.

Other named commands: `Start-Sleep`.

Named callers: [Invoke-StepRemoveAssociatedManagedDevice](#invoke-stepremoveassociatedmanageddevice).

### Invoke-StepRemoveAssociatedManagedDevice

Confirm one managed-device deletion and verify absence with fresh reads.

Source: [autopilot-express.ps1:9914](autopilot-express.ps1#L9914). Internal entry-script function; source region: `Directory Selection and Tenant Workflow Actions`.

| Parameter        | Declared Type   | Attributes               | Default                        | Source Contract                                                           |
| ---------------- | --------------- | ------------------------ | ------------------------------ | ------------------------------------------------------------------------- |
| `Device`         | `System.Object` | `[Parameter(Mandatory)]` | No explicit default expression | Selected record whose target identity is freshly checked before deletion. |
| `StepDefinition` | `System.Object` | `[Parameter(Mandatory)]` | No explicit default expression | Validated removal manifest entry.                                         |

Outputs and result contract:

Operation result retaining target/submission evidence. Read errors are not absence;
accepted deletion is never automatically replayed.

Other named commands: `Get-Command`, `Out-Null`, `Remove-MgDeviceManagementManagedDevice`, `Sort-Object`, `Where-Object`.

Named callers: [Invoke-AutopilotManifestStep](#invoke-autopilotmanifeststep).

### Wait-AutopilotGroupTagVerification

Polls the Autopilot identity until its Group Tag matches exactly.

Source: [autopilot-express.ps1:10026](autopilot-express.ps1#L10026). Internal entry-script function; source region: `Directory Selection and Tenant Workflow Actions`.

| Parameter           | Declared Type   | Attributes                                                       | Default                        | Source Contract                                                         |
| ------------------- | --------------- | ---------------------------------------------------------------- | ------------------------------ | ----------------------------------------------------------------------- |
| `AutopilotDeviceId` | `System.String` | `[Parameter(Mandatory)]` `[ValidateNotNullOrEmpty()]` `[string]` | No explicit default expression | Autopilot identity whose tag must be observed.                          |
| `ExpectedTag`       | `System.String` | `[Parameter(Mandatory)]` `[ValidateNotNullOrEmpty()]` `[string]` | No explicit default expression | Enforced site/device-type tag, preserving its configured case.          |
| `MaxAttempts`       | `System.Int32`  | `[Parameter(Mandatory)]` `[ValidateRange(1, 20)]` `[int]`        | No explicit default expression | Total reads including the immediate first read.                         |
| `IntervalSeconds`   | `System.Int32`  | `[Parameter(Mandatory)]` `[ValidateRange(0, 60)]` `[int]`        | No explicit default expression | Pause between unsuccessful reads, never after success or the last read. |

Outputs and result contract:

Dictionary containing Confirmed, Attempts and ObservedGroupTag.

Other named commands: `Start-Sleep`.

Named callers: [Invoke-StepApplyGroupTag](#invoke-stepapplygrouptag).

### Resolve-LiveAutopilotTagContext

Refresh only the tenant-bound Autopilot identity needed for a tag action.

Source: [autopilot-express.ps1:10065](autopilot-express.ps1#L10065). Internal entry-script function; source region: `Directory Selection and Tenant Workflow Actions`.

| Parameter | Declared Type   | Attributes               | Default                        | Source Contract                                                   |
| --------- | --------------- | ------------------------ | ------------------------------ | ----------------------------------------------------------------- |
| `Device`  | `System.Object` | `[Parameter(Mandatory)]` | No explicit default expression | Workflow record whose saved identity must still match its serial. |

Outputs and result contract:

Fresh Autopilot identity or null; unrelated Intune and Entra IDs are preserved.

Named callers: [Invoke-StepApplyGroupTag](#invoke-stepapplygrouptag), [Resolve-LiveMembershipContext](#resolve-livemembershipcontext).

### Invoke-StepApplyGroupTag

Submit the expected Group Tag once or recheck a retained accepted submission.

Source: [autopilot-express.ps1:10089](autopilot-express.ps1#L10089). Internal entry-script function; source region: `Directory Selection and Tenant Workflow Actions`.

| Parameter        | Declared Type   | Attributes               | Default                        | Source Contract                                                             |
| ---------------- | --------------- | ------------------------ | ------------------------------ | --------------------------------------------------------------------------- |
| `Device`         | `System.Object` | `[Parameter(Mandatory)]` | No explicit default expression | Selected record with site/type-derived tag and retained submission context. |
| `StepDefinition` | `System.Object` | `[Parameter(Mandatory)]` | No explicit default expression | Validated tag entry used to locate previous pending evidence.               |

Outputs and result contract:

Verified, Submitted, Blocked or failed result. One immediate read follows submission
or recheck; read failure preserves Submitted without reposting or sleeping.

Other named commands: `Out-Null`.

Named callers: [Invoke-AutopilotManifestStep](#invoke-autopilotmanifeststep).

### Invoke-StepValidateDeploymentProfile

Record technician confirmation of the configured deployment profile.

Source: [autopilot-express.ps1:10155](autopilot-express.ps1#L10155). Internal entry-script function; source region: `Directory Selection and Tenant Workflow Actions`.

| Parameter        | Declared Type   | Attributes               | Default                        | Source Contract                                   |
| ---------------- | --------------- | ------------------------ | ------------------------------ | ------------------------------------------------- |
| `Device`         | `System.Object` | `[Parameter(Mandatory)]` | No explicit default expression | Selected record with resolved Autopilot identity. |
| `StepDefinition` | `System.Object` | `[Parameter(Mandatory)]` | No explicit default expression | Validated deployment-profile manifest entry.      |

Outputs and result contract:

Read-only operation result; profile name or a non-assigned state alone cannot complete it.

Other named commands: `Write-Host`.

Named callers: [Invoke-AutopilotManifestStep](#invoke-autopilotmanifeststep).

### Wait-GroupMembershipVerification

Polls membership presence or absence without repeating a mutation.

Source: [autopilot-express.ps1:10183](autopilot-express.ps1#L10183). Internal entry-script function; source region: `Directory Selection and Tenant Workflow Actions`.

| Parameter           | Declared Type                                  | Attributes                                                       | Default                        | Source Contract                                                                   |
| ------------------- | ---------------------------------------------- | ---------------------------------------------------------------- | ------------------------------ | --------------------------------------------------------------------------------- |
| `GroupId`           | `System.String`                                | `[Parameter(Mandatory)]` `[ValidateNotNullOrEmpty()]` `[string]` | No explicit default expression | Resolved pre-provisioning group object ID.                                        |
| `DirectoryObjectId` | `System.String`                                | `[Parameter(Mandatory)]` `[ValidateNotNullOrEmpty()]` `[string]` | No explicit default expression | Entra device object ID whose direct membership is checked.                        |
| `ExpectedMember`    | `System.Boolean`                               | `[Parameter(Mandatory)]` `[bool]`                                | No explicit default expression | True for addition, false for removal.                                             |
| `MaxAttempts`       | `System.Int32`                                 | `[Parameter(Mandatory)]` `[ValidateRange(1, 20)]` `[int]`        | No explicit default expression | Total read-back checks, including the immediate first check.                      |
| `IntervalSeconds`   | `System.Int32`                                 | `[Parameter(Mandatory)]` `[ValidateRange(0, 60)]` `[int]`        | No explicit default expression | Pause between mismatches, never after success or the last check.                  |
| `GroupConfirmed`    | `System.Management.Automation.SwitchParameter` | `[switch]`                                                       | No explicit default expression | Passed through to Test-LiveGroupMembership after an accepted write to this group. |

Outputs and result contract:

Dictionary containing Confirmed, Attempts and ObservedMember.

Other named commands: `Start-Sleep`.

Named callers: [Invoke-PreProvisioningMembershipChange](#invoke-preprovisioningmembershipchange).

### Test-AssignedSecurityGroup

Check complete metadata before changing a direct security-group membership.

Source: [autopilot-express.ps1:10224](autopilot-express.ps1#L10224). Internal entry-script function; source region: `Directory Selection and Tenant Workflow Actions`.

| Parameter | Declared Type   | Attributes               | Default                        | Source Contract                                                                     |
| --------- | --------------- | ------------------------ | ------------------------------ | ----------------------------------------------------------------------------------- |
| `Group`   | `System.Object` | `[Parameter(Mandatory)]` | No explicit default expression | Fresh group metadata; dynamic, mail-enabled and role-assignable groups are refused. |

Outputs and result contract:

Boolean permission to offer a membership change, not proof of Graph write access.

Named callers: [Invoke-PreProvisioningMembershipChange](#invoke-preprovisioningmembershipchange).

### Get-LivePreProvisioningConflictGroup

Read complete direct memberships and identify other pre-provisioning prefix groups.

Source: [autopilot-express.ps1:10240](autopilot-express.ps1#L10240). Internal entry-script function; source region: `Directory Selection and Tenant Workflow Actions`.

| Parameter           | Declared Type     | Attributes                              | Default                        | Source Contract                                                                 |
| ------------------- | ----------------- | --------------------------------------- | ------------------------------ | ------------------------------------------------------------------------------- |
| `DirectoryObjectId` | `System.String`   | `[Parameter(Mandatory)]` `[string]`     | No explicit default expression | Freshly resolved Entra device object ID.                                        |
| `TargetGroup`       | `System.Object`   | `[Parameter(Mandatory)]`                | No explicit default expression | Uniquely resolved configured target; never replaced by a discovered membership. |
| `Memberships`       | `System.Object[]` | `[AllowEmptyCollection()]` `[object[]]` | No explicit default expression | Complete fresh membership snapshot from this operation; omit to request one.    |

Outputs and result contract:

Array of conflicting groups. Incomplete or limited-information discovery fails closed.

Other named commands: `ForEach-Object`, `Sort-Object`, `Where-Object`.

Named callers: [Get-LivePreProvisioningMembershipState](#get-livepreprovisioningmembershipstate).

### Get-LivePreProvisioningMembershipState

Resolve target membership and conflicts from one complete device membership read.

Source: [autopilot-express.ps1:10285](autopilot-express.ps1#L10285). Internal entry-script function; source region: `Directory Selection and Tenant Workflow Actions`.

| Parameter           | Declared Type   | Attributes                          | Default                        | Source Contract                                                    |
| ------------------- | --------------- | ----------------------------------- | ------------------------------ | ------------------------------------------------------------------ |
| `DirectoryObjectId` | `System.String` | `[Parameter(Mandatory)]` `[string]` | No explicit default expression | Fresh validated Entra device object ID.                            |
| `TargetGroup`       | `System.Object` | `[Parameter(Mandatory)]`            | No explicit default expression | Fresh uniquely resolved configured group, including its object ID. |

Outputs and result contract:

ObservedMember Boolean and ConflictGroups array; partial or denied reads throw.

Other named commands: `Where-Object`.

Named callers: [Invoke-PreProvisioningMembershipChange](#invoke-preprovisioningmembershipchange).

### Resolve-LiveMembershipContext

Validate the selected Autopilot and Entra identities without an Intune lookup.

Source: [autopilot-express.ps1:10304](autopilot-express.ps1#L10304). Internal entry-script function; source region: `Directory Selection and Tenant Workflow Actions`.

| Parameter | Declared Type   | Attributes               | Default                        | Source Contract                                                                     |
| --------- | --------------- | ------------------------ | ------------------------------ | ----------------------------------------------------------------------------------- |
| `Device`  | `System.Object` | `[Parameter(Mandatory)]` | No explicit default expression | Tenant-bound workflow record whose serial and directory identity must be refreshed. |

Outputs and result contract:

Fresh Entra device or null; unrelated managed-device identity is preserved.

Named callers: [Invoke-PreProvisioningMembershipChange](#invoke-preprovisioningmembershipchange).

### Invoke-PreProvisioningMembershipChange

Applies and verifies one pre-provisioning membership state transition.

Source: [autopilot-express.ps1:10330](autopilot-express.ps1#L10330). Internal entry-script function; source region: `Directory Selection and Tenant Workflow Actions`.

| Parameter        | Declared Type    | Attributes                        | Default                        | Source Contract                                                   |
| ---------------- | ---------------- | --------------------------------- | ------------------------------ | ----------------------------------------------------------------- |
| `Device`         | `System.Object`  | `[Parameter(Mandatory)]`          | No explicit default expression | Mutable dictionary-backed workflow record.                        |
| `StepDefinition` | `System.Object`  | `[Parameter(Mandatory)]`          | No explicit default expression | Manifest action whose result must be recorded.                    |
| `ExpectedMember` | `System.Boolean` | `[Parameter(Mandatory)]` `[bool]` | No explicit default expression | True to add the device, false to remove its membership reference. |

Outputs and result contract:

Operation result with explicit outcome and read-back evidence.

Other named commands: `ForEach-Object`, `Out-Null`, `Where-Object`, `Write-Host`.

Named callers: [Invoke-StepAddPreProvisioningGroup](#invoke-stepaddpreprovisioninggroup), [Invoke-StepRemovePreProvisioningGroup](#invoke-stepremovepreprovisioninggroup).

### Invoke-StepAddPreProvisioningGroup

Delegate guarded group addition to the shared membership controller.

Source: [autopilot-express.ps1:10450](autopilot-express.ps1#L10450). Internal entry-script function; source region: `Directory Selection and Tenant Workflow Actions`.

| Parameter        | Declared Type   | Attributes               | Default                        | Source Contract                                                     |
| ---------------- | --------------- | ------------------------ | ------------------------------ | ------------------------------------------------------------------- |
| `Device`         | `System.Object` | `[Parameter(Mandatory)]` | No explicit default expression | Selected record whose directory identity must be freshly validated. |
| `StepDefinition` | `System.Object` | `[Parameter(Mandatory)]` | No explicit default expression | Validated group-add manifest entry.                                 |

Outputs and result contract:

Membership operation result; HTTP acceptance is not verified membership.

Named callers: [Invoke-AutopilotManifestStep](#invoke-autopilotmanifeststep).

### Get-RecoverySubmissionEvidence

Find the current recovery cycle's durable unblock evidence without replaying it.

Source: [autopilot-express.ps1:10466](autopilot-express.ps1#L10466). Internal entry-script function; source region: `Directory Selection and Tenant Workflow Actions`.

| Parameter        | Declared Type                    | Attributes                                                  | Default                        | Source Contract                                             |
| ---------------- | -------------------------------- | ----------------------------------------------------------- | ------------------------------ | ----------------------------------------------------------- |
| `Device`         | `System.Collections.IDictionary` | `[Parameter(Mandatory)]` `[System.Collections.IDictionary]` | No explicit default expression | Active recovery record and its append-only attempt history. |
| `StepDefinition` | `System.Object`                  | `[Parameter(Mandatory)]`                                    | No explicit default expression | Current semantic unblock action and displayed step ID.      |

Outputs and result contract:

Latest matching recovery evidence, or null when no intent has been recorded.

Other named commands: `Where-Object`.

Named callers: [Save-RecoverySubmissionEvidence](#save-recoverysubmissionevidence), [Invoke-StepClearUserlessEnrollmentStatus](#invoke-stepclearuserlessenrollmentstatus), [Invoke-StepConfirmRecoveryReadiness](#invoke-stepconfirmrecoveryreadiness), [Write-ManifestStepResult](#write-manifeststepresult).

### Save-RecoverySubmissionEvidence

Append and save intent, accepted response or technician-observed Allowed evidence.

Source: [autopilot-express.ps1:10523](autopilot-express.ps1#L10523). Internal entry-script function; source region: `Directory Selection and Tenant Workflow Actions`.

| Parameter        | Declared Type                    | Attributes                                                                                                           | Default                        | Source Contract                                                             |
| ---------------- | -------------------------------- | -------------------------------------------------------------------------------------------------------------------- | ------------------------------ | --------------------------------------------------------------------------- |
| `Device`         | `System.Collections.IDictionary` | `[Parameter(Mandatory)]` `[System.Collections.IDictionary]`                                                          | No explicit default expression | Active session record that owns the append-only attempt history.            |
| `StepDefinition` | `System.Object`                  | `[Parameter(Mandatory)]`                                                                                             | No explicit default expression | Current recovery unblock action.                                            |
| `Kind`           | `System.String`                  | `[Parameter(Mandatory)]` `[ValidateSet('RecoveryIntent', 'RecoveryAccepted', 'RecoveryAllowedObserved')]` `[string]` | No explicit default expression | Evidence stage; acceptance and observation each require an existing intent. |

Outputs and result contract:

Saved attempt entry. Throws if identity, ordering or durable storage is invalid.

Other named commands: `Get-Date`, `Where-Object`.

Named callers: [Invoke-StepClearUserlessEnrollmentStatus](#invoke-stepclearuserlessenrollmentstatus).

### Invoke-StepClearUserlessEnrollmentStatus

Submit an explicitly confirmed userless-enrolment unblock in active recovery mode.

Source: [autopilot-express.ps1:10578](autopilot-express.ps1#L10578). Internal entry-script function; source region: `Directory Selection and Tenant Workflow Actions`.

| Parameter        | Declared Type   | Attributes               | Default                        | Source Contract                                            |
| ---------------- | --------------- | ------------------------ | ------------------------------ | ---------------------------------------------------------- |
| `Device`         | `System.Object` | `[Parameter(Mandatory)]` | No explicit default expression | Selected record with current recovery/submission evidence. |
| `StepDefinition` | `System.Object` | `[Parameter(Mandatory)]` | No explicit default expression | Validated conditional recovery manifest entry.             |

Outputs and result contract:

Operation result. Durable intent prevents replay after an interrupted request.
A technician-observed Allowed status is distinct from an accepted response.

Other named commands: `Out-Null`, `Write-Host`.

Named callers: [Invoke-AutopilotManifestStep](#invoke-autopilotmanifeststep).

### Invoke-StepConfirmRecoveryReadiness

Confirms checklist recovery readiness without claiming Graph status proof.

Source: [autopilot-express.ps1:10649](autopilot-express.ps1#L10649). Internal entry-script function; source region: `Directory Selection and Tenant Workflow Actions`.

| Parameter        | Declared Type   | Attributes               | Default                        | Source Contract                                         |
| ---------------- | --------------- | ------------------------ | ------------------------------ | ------------------------------------------------------- |
| `Device`         | `System.Object` | `[Parameter(Mandatory)]` | No explicit default expression | Active recovery record with persisted unblock evidence. |
| `StepDefinition` | `System.Object` | `[Parameter(Mandatory)]` | No explicit default expression | Conditional recovery close-out manifest action.         |

Outputs and result contract:

Blocked, Submitted, Failed, TechnicianConfirmed or Simulated result.

Other named commands: `Get-Date`, `Where-Object`, `Write-Host`.

Named callers: [Invoke-AutopilotManifestStep](#invoke-autopilotmanifeststep).

### Get-RegularTechnicianUsername

Map the Windows process login to a presumed regular username.

Source: [autopilot-express.ps1:10732](autopilot-express.ps1#L10732). Internal entry-script function; source region: `Directory Selection and Tenant Workflow Actions`.

| Parameter         | Declared Type   | Attributes                        | Default         | Source Contract                                                        |
| ----------------- | --------------- | --------------------------------- | --------------- | ---------------------------------------------------------------------- |
| `WindowsUsername` | `System.String` | `[AllowEmptyString()]` `[string]` | `$env:USERNAME` | Windows login, not the Graph sign-in; uncertain patterns return empty. |

Outputs and result contract:

Lower-case username only, never a manufactured UPN or directory ID.

Named callers: [Select-TechnicianDirectoryUser](#select-techniciandirectoryuser).

### Select-TechnicianDirectoryUser

Resolve and positively confirm the technician's regular directory account.

Source: [autopilot-express.ps1:10749](autopilot-express.ps1#L10749). Internal entry-script function; source region: `Directory Selection and Tenant Workflow Actions`.

No formal parameters declared. Captured state and enclosing scope may still be inputs.

Outputs and result contract:

Revalidated eligible directory user, or null when cancelled.

Other named commands: `Where-Object`, `Write-Host`.

Named callers: [Invoke-StepAssignTechnicianPrimaryUser](#invoke-stepassigntechnicianprimaryuser).

### Invoke-StepAssignTechnicianPrimaryUser

Preview and confirm the regular technician account before guarded assignment.

Source: [autopilot-express.ps1:10796](autopilot-express.ps1#L10796). Internal entry-script function; source region: `Directory Selection and Tenant Workflow Actions`.

| Parameter        | Declared Type   | Attributes               | Default                        | Source Contract                                                              |
| ---------------- | --------------- | ------------------------ | ------------------------------ | ---------------------------------------------------------------------------- |
| `Device`         | `System.Object` | `[Parameter(Mandatory)]` | No explicit default expression | Selected record; unresolved previous assignment prevents silent retargeting. |
| `StepDefinition` | `System.Object` | `[Parameter(Mandatory)]` | No explicit default expression | Validated technician-assignment manifest entry.                              |

Outputs and result contract:

Operation result with actual account identity and per-surface evidence. Cancellation
retains submitted data and never invents a successful assignment.

Named callers: [Invoke-AutopilotManifestStep](#invoke-autopilotmanifeststep).

### Get-SyncSubmissionLedgerState

Read one build cycle's sync evidence from the device record ledger.

Source: [autopilot-express.ps1:10860](autopilot-express.ps1#L10860). Internal entry-script function; source region: `Directory Selection and Tenant Workflow Actions`.

| Parameter  | Declared Type                    | Attributes                                                  | Default                        | Source Contract                                                          |
| ---------- | -------------------------------- | ----------------------------------------------------------- | ------------------------------ | ------------------------------------------------------------------------ |
| `Device`   | `System.Collections.IDictionary` | `[Parameter(Mandatory)]` `[System.Collections.IDictionary]` | No explicit default expression | Live session record whose SyncSubmissions ledger is read, never changed. |
| `CycleKey` | `System.String`                  | `[AllowEmptyString()]` `[string]`                           | `''`                           | BuildCycleId of the current cycle, or empty for records without one.     |
| `Target`   | `System.Collections.Hashtable`   | `[Parameter(Mandatory)]` `[hashtable]`                      | No explicit default expression | Refreshed RecordId, Serial, ManagedDeviceId and optional TenantId.       |

Outputs and result contract:

Dictionary with Receipt (validated evidence or null), IntentExists and IntentAt.
Throws when an accepted receipt no longer matches the refreshed target.

Other named commands: `Select-Object`, `Where-Object`.

Named callers: [Invoke-StepRetryFailedApps](#invoke-stepretryfailedapps).

### Save-DeviceLedgerEntry

Append one submission or recovery-evidence entry and save all records durably.

Source: [autopilot-express.ps1:10919](autopilot-express.ps1#L10919). Internal entry-script function; source region: `Directory Selection and Tenant Workflow Actions`.

| Parameter    | Declared Type                    | Attributes                                                                                                    | Default                        | Source Contract                              |
| ------------ | -------------------------------- | ------------------------------------------------------------------------------------------------------------- | ------------------------------ | -------------------------------------------- |
| `Device`     | `System.Collections.IDictionary` | `[Parameter(Mandatory)]` `[System.Collections.IDictionary]`                                                   | No explicit default expression | Session record that receives the entry.      |
| `LedgerName` | `System.String`                  | `[Parameter(Mandatory)]` `[ValidateSet('SyncSubmissions', 'ImportSubmissions', 'AttemptHistory')]` `[string]` | No explicit default expression | Record field holding the append-only ledger. |
| `Entry`      | `System.Collections.Hashtable`   | `[Parameter(Mandatory)]` `[hashtable]`                                                                        | No explicit default expression | Validated ledger entry.                      |

Outputs and result contract:

None. Throws when the record cannot be located or saved.

Other named commands: `Get-Variable`, `Where-Object`.

Named callers: [Save-AutopilotImportLedgerEntry](#save-autopilotimportledgerentry), [Save-RecoverySubmissionEvidence](#save-recoverysubmissionevidence), [Invoke-StepRetryFailedApps](#invoke-stepretryfailedapps).

### Import-LegacySyncSubmissionEvidence

Fold legacy sync receipt and intent files into device records, then delete them.

Source: [autopilot-express.ps1:10962](autopilot-express.ps1#L10962). Internal entry-script function; source region: `Directory Selection and Tenant Workflow Actions`.

| Parameter | Declared Type                    | Attributes                                                                             | Default                        | Source Contract                                                       |
| --------- | -------------------------------- | -------------------------------------------------------------------------------------- | ------------------------------ | --------------------------------------------------------------------- |
| `Records` | `System.Collections.IEnumerable` | `[Parameter(Mandatory)]` `[AllowEmptyCollection()]` `[System.Collections.IEnumerable]` | No explicit default expression | Loaded session records; matched records gain ledger entries in place. |

Outputs and result contract:

Count of legacy files migrated and deleted.

Other named commands: `ConvertFrom-Json`, `Get-ChildItem`, `Get-Command`, `Get-Content`, `Get-Date`, `Remove-Item`, `Select-Object`, `Sort-Object`, `Where-Object`.

No statically named function caller in this inventory. Top-level, dynamic and callback invocation remain possible.

### Import-LegacyAutopilotImportEvidence

Fold legacy hash-import journal files into device records, then delete them.

Source: [autopilot-express.ps1:11045](autopilot-express.ps1#L11045). Internal entry-script function; source region: `Directory Selection and Tenant Workflow Actions`.

| Parameter | Declared Type                    | Attributes                                                                             | Default                        | Source Contract                                                       |
| --------- | -------------------------------- | -------------------------------------------------------------------------------------- | ------------------------------ | --------------------------------------------------------------------- |
| `Records` | `System.Collections.IEnumerable` | `[Parameter(Mandatory)]` `[AllowEmptyCollection()]` `[System.Collections.IEnumerable]` | No explicit default expression | Loaded session records; matched records gain ledger entries in place. |

Outputs and result contract:

Count of legacy files migrated and deleted.

Other named commands: `ConvertFrom-Json`, `Get-ChildItem`, `Get-Command`, `Get-Content`, `Get-Date`, `Remove-Item`, `Select-Object`, `Sort-Object`, `Where-Object`.

No statically named function caller in this inventory. Top-level, dynamic and callback invocation remain possible.

### Read-ApplicationRetryChoice

Ask whether a failed application needs a device sync.

Source: [autopilot-express.ps1:11109](autopilot-express.ps1#L11109). Internal entry-script function; source region: `Directory Selection and Tenant Workflow Actions`.

No formal parameters declared. Captured state and enclosing scope may still be inputs.

Outputs and result contract:

N for no failures, Y for sync, or 0 to cancel. Enter defaults to N.

Named callers: [Invoke-StepRetryFailedApps](#invoke-stepretryfailedapps).

### Get-ConfirmedApplicationBaseline

Find the current technician-confirmed application baseline for a no-sync outcome.

Source: [autopilot-express.ps1:11119](autopilot-express.ps1#L11119). Internal entry-script function; source region: `Directory Selection and Tenant Workflow Actions`.

| Parameter | Declared Type   | Attributes               | Default                        | Source Contract                                          |
| --------- | --------------- | ------------------------ | ------------------------------ | -------------------------------------------------------- |
| `Device`  | `System.Object` | `[Parameter(Mandatory)]` | No explicit default expression | Selected workflow record with its current step evidence. |

Outputs and result contract:

Baseline step ID and timestamp, or null when the required confirmation is absent.

Other named commands: `Where-Object`.

Named callers: [Test-ApplicationNoFailureEvidence](#test-applicationnofailureevidence), [Invoke-StepRetryFailedApps](#invoke-stepretryfailedapps).

### Test-ApplicationNoFailureEvidence

Match a no-failure outcome to its still-current application baseline.

Source: [autopilot-express.ps1:11143](autopilot-express.ps1#L11143). Internal entry-script function; source region: `Directory Selection and Tenant Workflow Actions`.

| Parameter | Declared Type                    | Attributes                                                  | Default                        | Source Contract                                                           |
| --------- | -------------------------------- | ----------------------------------------------------------- | ------------------------------ | ------------------------------------------------------------------------- |
| `Device`  | `System.Object`                  | `[Parameter(Mandatory)]`                                    | No explicit default expression | Selected workflow record containing the current baseline.                 |
| `Data`    | `System.Collections.IDictionary` | `[Parameter(Mandatory)]` `[System.Collections.IDictionary]` | No explicit default expression | Saved no-failure evidence, including its baseline identity and timestamp. |

Outputs and result contract:

Boolean. Stale, missing or mismatched evidence cannot complete the step.

Named callers: [Write-ManifestStepResult](#write-manifeststepresult), [Test-ManifestStepCompleted](#test-manifeststepcompleted).

### Invoke-StepRetryFailedApps

Record no failures, or submit sync for a failed application and confirm its outcome.

Source: [autopilot-express.ps1:11165](autopilot-express.ps1#L11165). Internal entry-script function; source region: `Directory Selection and Tenant Workflow Actions`.

| Parameter        | Declared Type   | Attributes               | Default                        | Source Contract                                                                |
| ---------------- | --------------- | ------------------------ | ------------------------------ | ------------------------------------------------------------------------------ |
| `Device`         | `System.Object` | `[Parameter(Mandatory)]` | No explicit default expression | Session workflow record whose managed-device identity is refreshed before use. |
| `StepDefinition` | `System.Object` | `[Parameter(Mandatory)]` | No explicit default expression | RetryFailedApplications manifest action.                                       |

Outputs and result contract:

Blocked, Submitted, TechnicianConfirmed, Failed or Simulated.

Other named commands: `Get-Date`, `Get-Variable`, `Out-Null`.

Named callers: [Invoke-AutopilotManifestStep](#invoke-autopilotmanifeststep).

### Invoke-StepRemovePreProvisioningGroup

Delegate membership removal without deleting the group or directory device.

Source: [autopilot-express.ps1:11287](autopilot-express.ps1#L11287). Internal entry-script function; source region: `Directory Selection and Tenant Workflow Actions`.

| Parameter        | Declared Type   | Attributes               | Default                        | Source Contract                                                |
| ---------------- | --------------- | ------------------------ | ------------------------------ | -------------------------------------------------------------- |
| `Device`         | `System.Object` | `[Parameter(Mandatory)]` | No explicit default expression | Selected record whose directory identity is freshly validated. |
| `StepDefinition` | `System.Object` | `[Parameter(Mandatory)]` | No explicit default expression | Validated group-removal manifest entry.                        |

Outputs and result contract:

Membership operation result; complete fresh absence evidence verifies removal.

Named callers: [Invoke-AutopilotManifestStep](#invoke-autopilotmanifeststep).

### Invoke-StepAssignFinalPrimaryUser

Select the final user and retain verified or pending assignment evidence separately.

Source: [autopilot-express.ps1:11303](autopilot-express.ps1#L11303). Internal entry-script function; source region: `Directory Selection and Tenant Workflow Actions`.

| Parameter        | Declared Type   | Attributes               | Default                        | Source Contract                                                                    |
| ---------------- | --------------- | ------------------------ | ------------------------------ | ---------------------------------------------------------------------------------- |
| `Device`         | `System.Object` | `[Parameter(Mandatory)]` | No explicit default expression | Selected record; current identities and previous submissions constrain assignment. |
| `StepDefinition` | `System.Object` | `[Parameter(Mandatory)]` | No explicit default expression | Validated final-user manifest entry.                                               |

Outputs and result contract:

Operation result; cancellation does not submit, and acceptance does not prove ownership.

Named callers: [Invoke-AutopilotManifestStep](#invoke-autopilotmanifeststep).

### Invoke-StepConfirmPhysicalMilestone

Guides and records a technician-observed physical milestone.

Source: [autopilot-express.ps1:11356](autopilot-express.ps1#L11356). Internal entry-script function; source region: `Directory Selection and Tenant Workflow Actions`.

| Parameter        | Declared Type   | Attributes               | Default                        | Source Contract                                                     |
| ---------------- | --------------- | ------------------------ | ------------------------------ | ------------------------------------------------------------------- |
| `Device`         | `System.Object` | `[Parameter(Mandatory)]` | No explicit default expression | Workflow record for the device being physically prepared.           |
| `StepDefinition` | `System.Object` | `[Parameter(Mandatory)]` | No explicit default expression | Manifest definition for pre-provisioning or post-login device work. |

Outputs and result contract:

TechnicianConfirmed, Submitted or Simulated operation result.

Other named commands: `Write-Host`.

Named callers: [Invoke-AutopilotManifestStep](#invoke-autopilotmanifeststep).

### Invoke-AutopilotManifestStep

Enforce tenant binding and prerequisites before dispatching a semantic manifest action.

Source: [autopilot-express.ps1:11453](autopilot-express.ps1#L11453). Internal entry-script function; source region: `Directory Selection and Tenant Workflow Actions`.

| Parameter        | Declared Type   | Attributes               | Default                        | Source Contract                                                             |
| ---------------- | --------------- | ------------------------ | ------------------------------ | --------------------------------------------------------------------------- |
| `Device`         | `System.Object` | `[Parameter(Mandatory)]` | No explicit default expression | Selected record; handlers own their explicit action confirmations.          |
| `StepDefinition` | `System.Object` | `[Parameter(Mandatory)]` | No explicit default expression | Validated entry; ActionName, not the displayed letter, selects the handler. |

Outputs and result contract:

Operation result, including Blocked when eligibility fails. Unknown actions fail closed;
recording and guarded persistence of results remain the caller's responsibility.

Named callers: [Invoke-AutopilotSequence](#invoke-autopilotsequence), [Invoke-DeviceWorkflowPlan](#invoke-deviceworkflowplan), [Show-BuildBenchView](#show-buildbenchview).

### Show-ChecklistHandoffGuide

Display checklist v1.4 steps 24-26 after final Intune ownership completes.

Source: [autopilot-express.ps1:11528](autopilot-express.ps1#L11528). Internal entry-script function; source region: `Directory Selection and Tenant Workflow Actions`.

| Parameter | Declared Type   | Attributes                                            | Default                        | Source Contract                                                                |
| --------- | --------------- | ----------------------------------------------------- | ------------------------------ | ------------------------------------------------------------------------------ |
| `Device`  | `System.Object` | `[Parameter(Mandatory)]` `[ValidateNotNullOrEmpty()]` | No explicit default expression | Workflow record used only to display device identity and captured Intune name. |

Outputs and result contract:

Host guidance only; no external-system update, confirmation or dispatch certification.

Other named commands: `Write-Host`.

Named callers: [Write-ManifestStepResult](#write-manifeststepresult).

### Get-AffectedWorkflowStepId

Find the current step and all evidence that depends on it.

Source: [autopilot-express.ps1:11563](autopilot-express.ps1#L11563). Internal entry-script function; source region: `Directory Selection and Tenant Workflow Actions`.

| Parameter     | Declared Type     | Attributes                                                       | Default                        | Source Contract                                            |
| ------------- | ----------------- | ---------------------------------------------------------------- | ------------------------------ | ---------------------------------------------------------- |
| `Device`      | `System.Object`   | `[Parameter(Mandatory)]`                                         | No explicit default expression | Workflow record containing the current step results.       |
| `RootStepId`  | `System.String`   | `[Parameter(Mandatory)]` `[string]`                              | No explicit default expression | Step whose confirmation or outcome is being replaced.      |
| `Definitions` | `System.Object[]` | `[Parameter(Mandatory)]` `[AllowEmptyCollection()]` `[object[]]` | No explicit default expression | Enabled manifest actions and their declared prerequisites. |

Outputs and result contract:

Step IDs in dependency order, including a no-failure outcome dependent on the baseline.

Other named commands: `ForEach-Object`, `Where-Object`.

Named callers: [Write-ManifestStepResult](#write-manifeststepresult), [Undo-LatestTechnicianConfirmation](#undo-latesttechnicianconfirmation).

### Write-ManifestStepResult

Append detached outcome evidence before replacing current workflow state.

Source: [autopilot-express.ps1:11600](autopilot-express.ps1#L11600). Internal entry-script function; source region: `Directory Selection and Tenant Workflow Actions`.

| Parameter        | Declared Type   | Attributes               | Default                        | Source Contract                                                              |
| ---------------- | --------------- | ------------------------ | ------------------------------ | ---------------------------------------------------------------------------- |
| `Device`         | `System.Object` | `[Parameter(Mandatory)]` | No explicit default expression | Mutable workflow record whose history owns independent normalised snapshots. |
| `StepDefinition` | `System.Object` | `[Parameter(Mandatory)]` | No explicit default expression | Manifest identity for the completed handler invocation.                      |
| `Result`         | `System.Object` | `[Parameter(Mandatory)]` | No explicit default expression | Complete handler outcome, including blocked and unsuccessful results.        |

Outputs and result contract:

None. Appends detached in-memory outcome evidence; caller owns guarded durable storage.

Other named commands: `Get-Date`.

Named callers: [Invoke-AutopilotSequence](#invoke-autopilotsequence), [Invoke-DeviceWorkflowPlan](#invoke-deviceworkflowplan), [Undo-LatestTechnicianConfirmation](#undo-latesttechnicianconfirmation), [Show-BuildBenchView](#show-buildbenchview).

### Add-ManifestAttemptSnapshot

Append a deep copy of supplied evidence with record identity and sequence.

Source: [autopilot-express.ps1:11623](autopilot-express.ps1#L11623). Nested in `Write-ManifestStepResult`; its enclosing scope is part of the contract.

| Parameter  | Declared Type                                  | Attributes                          | Default                        | Source Contract                                                           |
| ---------- | ---------------------------------------------- | ----------------------------------- | ------------------------------ | ------------------------------------------------------------------------- |
| `StepId`   | `System.String`                                | `[Parameter(Mandatory)]` `[string]` | No explicit default expression | Step owning the evidence; unrelated historical entries are never changed. |
| `Evidence` | `System.Object`                                | `[Parameter(Mandatory)]`            | No explicit default expression | Complete handler result or untouched legacy step evidence.                |
| `Legacy`   | `System.Management.Automation.SwitchParameter` | `[switch]`                          | No explicit default expression | Preserve prior evidence once without inventing its execution timestamp.   |

Outputs and result contract:

None. Appends one independent snapshot to the enclosing device record.

Other named commands: `Get-Date`, `Where-Object`.

Named callers: [Write-ManifestStepResult](#write-manifeststepresult).

### New-BuildBench

Initialise an empty bench with the selected capacity.

Source: [autopilot-express.ps1:11787](autopilot-express.ps1#L11787). Internal entry-script function; source region: `Bench Eligibility, Dispatch and Presentation`.

| Parameter   | Declared Type  | Attributes | Default                        | Source Contract                                            |
| ----------- | -------------- | ---------- | ------------------------------ | ---------------------------------------------------------- |
| `Positions` | `System.Int32` | `[int]`    | No explicit default expression | Position count supplied by the validated bench-setup flow. |

Outputs and result contract:

None. Replaces script bench state; its caller owns subsequent guarded persistence.

Other named commands: `Write-Host`.

No statically named function caller in this inventory. Top-level, dynamic and callback invocation remain possible.

### Test-ManifestStepAttempted

Test for a current step entry without treating an attempt as completion.

Source: [autopilot-express.ps1:11803](autopilot-express.ps1#L11803). Internal entry-script function; source region: `Bench Eligibility, Dispatch and Presentation`.

| Parameter | Declared Type   | Attributes                          | Default                        | Source Contract                                 |
| --------- | --------------- | ----------------------------------- | ------------------------------ | ----------------------------------------------- |
| `Device`  | `System.Object` | `[Parameter(Mandatory)]`            | No explicit default expression | Record containing the current Steps dictionary. |
| `StepId`  | `System.String` | `[Parameter(Mandatory)]` `[string]` | No explicit default expression | Stored manifest identity to inspect.            |

Outputs and result contract:

Boolean entry presence; pending and failed outcomes remain attempts.

Named callers: [Show-DeviceWorkflowStatus](#show-deviceworkflowstatus), [Test-ManifestStepCompleted](#test-manifeststepcompleted).

### Test-ManifestStepCompleted

Interpret explicit completion evidence with legacy-state compatibility.

Source: [autopilot-express.ps1:11821](autopilot-express.ps1#L11821). Internal entry-script function; source region: `Bench Eligibility, Dispatch and Presentation`.

| Parameter | Declared Type   | Attributes                          | Default                        | Source Contract                                           |
| --------- | --------------- | ----------------------------------- | ------------------------------ | --------------------------------------------------------- |
| `Device`  | `System.Object` | `[Parameter(Mandatory)]`            | No explicit default expression | Record containing current step evidence.                  |
| `StepId`  | `System.String` | `[Parameter(Mandatory)]` `[string]` | No explicit default expression | Stored manifest identity, not the terminal display alias. |

Outputs and result contract:

Boolean completion; explicit pending/blocked states override legacy success flags.

Other named commands: `Select-Object`, `Where-Object`.

Named callers: [Invoke-DeviceWorkflowPlan](#invoke-deviceworkflowplan), [Show-DeviceWorkflowStatus](#show-deviceworkflowstatus), [Write-ManifestStepResult](#write-manifeststepresult), [Test-ManifestStepEligibility](#test-manifeststepeligibility), [Enter-DeviceRecoveryMode](#enter-devicerecoverymode), [Get-EligibleManifestSteps](#get-eligiblemanifeststeps), [Get-DispatchBlockingManifestSteps](#get-dispatchblockingmanifeststeps).

### Test-CompletionStateComplete

Classify documented completion states without treating Submitted as complete.

Source: [autopilot-express.ps1:11863](autopilot-express.ps1#L11863). Internal entry-script function; source region: `Bench Eligibility, Dispatch and Presentation`.

| Parameter         | Declared Type   | Attributes                          | Default                        | Source Contract                              |
| ----------------- | --------------- | ----------------------------------- | ------------------------------ | -------------------------------------------- |
| `CompletionState` | `System.String` | `[Parameter(Mandatory)]` `[string]` | No explicit default expression | Recorded evidence classification to inspect. |

Outputs and result contract:

Boolean classification only; Simulated is not Live verification.

Named callers: [Invoke-DeviceWorkflowPlan](#invoke-deviceworkflowplan), [Write-ManifestStepResult](#write-manifeststepresult), [Test-ManifestStepCompleted](#test-manifeststepcompleted).

### Get-NextStepId

Find the first eligible incomplete manifest step for the selected device.

Source: [autopilot-express.ps1:11877](autopilot-express.ps1#L11877). Internal entry-script function; source region: `Bench Eligibility, Dispatch and Presentation`.

| Parameter | Declared Type   | Attributes    | Default                        | Source Contract                                         |
| --------- | --------------- | ------------- | ------------------------------ | ------------------------------------------------------- |
| `Device`  | `System.Object` | None declared | No explicit default expression | Record with current prerequisite and recovery evidence. |

Outputs and result contract:

Stored manifest ID or null; does not execute actions or infer sequential letters.

Named callers: [Invoke-AutopilotSequence](#invoke-autopilotsequence), [Show-BuildBenchTable](#show-buildbenchtable), [Show-BuildBenchView](#show-buildbenchview).

### Get-ManifestStepPrerequisiteIds

Read declared prerequisite identities from a validated manifest step.

Source: [autopilot-express.ps1:11892](autopilot-express.ps1#L11892). Internal entry-script function; source region: `Bench Eligibility, Dispatch and Presentation`.

| Parameter        | Declared Type   | Attributes               | Default                        | Source Contract                                        |
| ---------------- | --------------- | ------------------------ | ------------------------------ | ------------------------------------------------------ |
| `StepDefinition` | `System.Object` | `[Parameter(Mandatory)]` | No explicit default expression | Entry whose dependency graph was validated at startup. |

Outputs and result contract:

Prerequisite ID array, empty when none; no state evaluation.

Named callers: [Test-ManifestStepEligibility](#test-manifeststepeligibility).

### Test-ManifestStepEligibility

Evaluate prerequisite completion and recovery activation independently.

Source: [autopilot-express.ps1:11906](autopilot-express.ps1#L11906). Internal entry-script function; source region: `Bench Eligibility, Dispatch and Presentation`.

| Parameter        | Declared Type   | Attributes               | Default                        | Source Contract                                       |
| ---------------- | --------------- | ------------------------ | ------------------------------ | ----------------------------------------------------- |
| `Device`         | `System.Object` | `[Parameter(Mandatory)]` | No explicit default expression | Record with current completion/recovery context.      |
| `StepDefinition` | `System.Object` | `[Parameter(Mandatory)]` | No explicit default expression | Proposed action and declared dependencies/activation. |

Outputs and result contract:

Eligible, MissingStepIds, ActivationRequirement and ActivationSatisfied dictionary.

Other named commands: `Where-Object`.

Named callers: [Invoke-DeviceWorkflowPlan](#invoke-deviceworkflowplan), [Show-DeviceWorkflowStatus](#show-deviceworkflowstatus), [Invoke-AutopilotManifestStep](#invoke-autopilotmanifeststep), [Get-EligibleManifestSteps](#get-eligiblemanifeststeps).

### Enter-DeviceRecoveryMode

Confirm recovery entry and retain detached pre-reset evidence for accountability.

Source: [autopilot-express.ps1:11969](autopilot-express.ps1#L11969). Internal entry-script function; source region: `Bench Eligibility, Dispatch and Presentation`.

| Parameter | Declared Type   | Attributes               | Default                        | Source Contract                                                                   |
| --------- | --------------- | ------------------------ | ------------------------------ | --------------------------------------------------------------------------------- |
| `Device`  | `System.Object` | `[Parameter(Mandatory)]` | No explicit default expression | Mutable record; current-cycle gates prevent automatic replay of recovery actions. |

Outputs and result contract:

None. Updates in-memory recovery/history after confirmation; the caller persists it.

Other named commands: `Get-Date`, `Write-Host`.

Named callers: [Invoke-DeviceWorkflowPlan](#invoke-deviceworkflowplan).

### Get-EligibleManifestSteps

List enabled incomplete actions with satisfied prerequisites and activation.

Source: [autopilot-express.ps1:12014](autopilot-express.ps1#L12014). Internal entry-script function; source region: `Bench Eligibility, Dispatch and Presentation`.

| Parameter | Declared Type                                  | Attributes               | Default                        | Source Contract                                                                               |
| --------- | ---------------------------------------------- | ------------------------ | ------------------------------ | --------------------------------------------------------------------------------------------- |
| `Device`  | `System.Object`                                | `[Parameter(Mandatory)]` | No explicit default expression | Current record including pending recovery submissions.                                        |
| `First`   | `System.Management.Automation.SwitchParameter` | `[switch]`               | No explicit default expression | Stop after the first eligible action for next-step displays; omit for the complete menu list. |

Outputs and result contract:

Ordered step array; excludes inappropriate repeat recovery-unblock submission.

Named callers: [Get-NextStepId](#get-nextstepid), [Show-BuildBenchView](#show-buildbenchview).

### Get-DispatchBlockingManifestSteps

Identify unresolved enabled steps, excluding inactive conditional recovery actions.

Source: [autopilot-express.ps1:12041](autopilot-express.ps1#L12041). Internal entry-script function; source region: `Bench Eligibility, Dispatch and Presentation`.

| Parameter | Declared Type   | Attributes               | Default                        | Source Contract                                  |
| --------- | --------------- | ------------------------ | ------------------------------ | ------------------------------------------------ |
| `Device`  | `System.Object` | `[Parameter(Mandatory)]` | No explicit default expression | Current evidence to inspect without changing it. |

Outputs and result contract:

Blocking step array; does not waive failed or Submitted required actions.

Other named commands: `Where-Object`.

Named callers: [Test-DeviceReadyForDispatch](#test-devicereadyfordispatch).

### Get-DeviceFeedbackContext

Identify the selected device independently of later bench moves/removal.

Source: [autopilot-express.ps1:12058](autopilot-express.ps1#L12058). Internal entry-script function; source region: `Bench Eligibility, Dispatch and Presentation`.

| Parameter              | Declared Type                    | Attributes                                                  | Default                        | Source Contract                                                                   |
| ---------------------- | -------------------------------- | ----------------------------------------------------------- | ------------------------------ | --------------------------------------------------------------------------------- |
| `Device`               | `System.Collections.IDictionary` | `[Parameter(Mandatory)]` `[System.Collections.IDictionary]` | No explicit default expression | Workflow record or occupied bench slot.                                           |
| `TextAlreadyDisplayed` | `System.String`                  | `[AllowEmptyString()]` `[string]`                           | `''`                           | Identify context already present in captured host text without editing that text. |

Outputs and result contract:

Position when present, serial and Configuration Item in plain text.

Other named commands: `Where-Object`.

Named callers: [Invoke-AutopilotSequence](#invoke-autopilotsequence), [Get-DocumentJobFeedbackContext](#get-documentjobfeedbackcontext), [Complete-DeviceDispatch](#complete-devicedispatch), [Show-BuildBenchView](#show-buildbenchview), [Invoke-BenchSelectedCommand](#invoke-benchselectedcommand).

### Undo-LatestTechnicianConfirmation

Withdraw the latest physical confirmation without erasing evidence or reversing Graph writes.

Source: [autopilot-express.ps1:12080](autopilot-express.ps1#L12080). Internal entry-script function; source region: `Bench Eligibility, Dispatch and Presentation`.

| Parameter | Declared Type                    | Attributes                                                  | Default                        | Source Contract                                                                             |
| --------- | -------------------------------- | ----------------------------------------------------------- | ------------------------------ | ------------------------------------------------------------------------------------------- |
| `Records` | `System.Collections.Hashtable`   | `[Parameter(Mandatory)]` `[hashtable]`                      | No explicit default expression | Current session container; its guarded writer saves a detached proposal before publication. |
| `Device`  | `System.Collections.IDictionary` | `[Parameter(Mandatory)]` `[System.Collections.IDictionary]` | No explicit default expression | Active owned record. Dispatched, recovering and unbound Live records are refused.           |

Outputs and result contract:

Changed and Summary dictionary. Cancellation or unsafe later remote evidence makes no change.

Other named commands: `Select-Object`, `Sort-Object`, `Where-Object`, `Write-Host`.

Named callers: [Invoke-AutopilotSequence](#invoke-autopilotsequence), [Invoke-BenchSelectedCommand](#invoke-benchselectedcommand).

### Invoke-DeviceDocumentHousekeeping

Recover terminal document staging without touching active jobs or records.

Source: [autopilot-express.ps1:12126](autopilot-express.ps1#L12126). Internal entry-script function; source region: `Bench Eligibility, Dispatch and Presentation`.

No formal parameters declared. Captured state and enclosing scope may still be inputs.

Outputs and result contract:

Logged cleanup summary. Never imports the optional module when disabled.

Other named commands: `Get-Module`, `Get-Variable`, `Join-Path`.

Named callers: [Initialize-DeviceDocumentSession](#initialize-devicedocumentsession).

### Test-DeviceDocumentScriptTrust

Inspect local document scripts before optional import or worker execution.

Source: [autopilot-express.ps1:12146](autopilot-express.ps1#L12146). Internal entry-script function; source region: `Bench Eligibility, Dispatch and Presentation`.

No formal parameters declared. Captured state and enclosing scope may still be inputs.

Outputs and result contract:

Reviewed paths and SHA-256 fingerprints of files carrying Internet-zone marks.
This is not signature approval and never changes trust or execution policy.

Other named commands: `Get-AuthenticodeSignature`, `Get-ChildItem`, `Get-Content`, `Get-ExecutionPolicy`, `Get-FileHash`, `Get-Item`, `Where-Object`.

Named callers: [Initialize-DeviceDocumentSession](#initialize-devicedocumentsession), [Request-DeviceDocumentReadiness](#request-devicedocumentreadiness).

### Initialize-DeviceDocumentSession

Resolve optional document preferences without host probes when both outputs are off.

Source: [autopilot-express.ps1:12178](autopilot-express.ps1#L12178). Internal entry-script function; source region: `Bench Eligibility, Dispatch and Presentation`.

| Parameter    | Declared Type                                  | Attributes | Default                        | Source Contract                                                                 |
| ------------ | ---------------------------------------------- | ---------- | ------------------------------ | ------------------------------------------------------------------------------- |
| `LoadModule` | `System.Management.Automation.SwitchParameter` | `[switch]` | No explicit default expression | Load the inert optional module for an explicit settings visit even if disabled. |

Outputs and result contract:

Session-only state. Saved preferences remain separate from operational records.

Other named commands: `ConvertFrom-Json`, `Get-Content`, `Get-Item`, `Get-Variable`, `Import-Module`, `Join-Path`, `Test-Path`.

Named callers: [Request-DeviceDocumentReadiness](#request-devicedocumentreadiness).

### Request-DeviceDocumentReadiness

Resolve document readiness before work and after explicit configuration changes.

Source: [autopilot-express.ps1:12226](autopilot-express.ps1#L12226). Internal entry-script function; source region: `Bench Eligibility, Dispatch and Presentation`.

| Parameter    | Declared Type                                  | Attributes | Default                        | Source Contract                                                           |
| ------------ | ---------------------------------------------- | ---------- | ------------------------------ | ------------------------------------------------------------------------- |
| `LoadModule` | `System.Management.Automation.SwitchParameter` | `[switch]` | No explicit default expression | Permit the inert optional module to load for a foreground Settings visit. |

Outputs and result contract:

True to continue, false to exit through the caller's existing cleanup.
Failure defaults to continuing without documents for this session only.
Unblocking requires a separate default-No confirmation of unchanged files.

Other named commands: `ForEach-Object`, `Get-Variable`, `Group-Object`, `Sort-Object`, `Split-Path`, `Unblock-File`, `Where-Object`, `Write-Host`.

Named callers: [Request-DeviceDocumentReprint](#request-devicedocumentreprint), [Show-DeviceDocumentSettings](#show-devicedocumentsettings).

### Get-DeviceDocumentAttemptDirectory

Resolve the local document-only evidence directory without creating it.

Source: [autopilot-express.ps1:12337](autopilot-express.ps1#L12337). Internal entry-script function; source region: `Bench Eligibility, Dispatch and Presentation`.

| Parameter | Declared Type                    | Attributes                                           | Default                        | Source Contract                                                               |
| --------- | -------------------------------- | ---------------------------------------------------- | ------------------------------ | ----------------------------------------------------------------------------- |
| `State`   | `System.Collections.IDictionary` | `[Parameter(Mandatory)]` `[Collections.IDictionary]` | No explicit default expression | Current validated settings, mode and tenant; operational storage is not used. |

Outputs and result contract:

Absolute scoped directory. Redirected ancestors and invalid bindings throw.

Other named commands: `Join-Path`.

Named callers: [Read-DeviceDocumentFailure](#read-devicedocumentfailure), [Read-DeviceDocumentHistory](#read-devicedocumenthistory), [Save-DeviceDocumentFailure](#save-devicedocumentfailure).

### Read-DeviceDocumentFailure

Discover retained prequeue failures without launching workers or replaying delivery.

Source: [autopilot-express.ps1:12359](autopilot-express.ps1#L12359). Internal entry-script function; source region: `Bench Eligibility, Dispatch and Presentation`.

| Parameter | Declared Type                    | Attributes                                           | Default                        | Source Contract                                                                |
| --------- | -------------------------------- | ---------------------------------------------------- | ------------------------------ | ------------------------------------------------------------------------------ |
| `State`   | `System.Collections.IDictionary` | `[Parameter(Mandatory)]` `[Collections.IDictionary]` | No explicit default expression | Current Windows actor, mode and tenant determine the permitted evidence scope. |

Outputs and result contract:

Newest-first detached entries. Foreign, interrupted, oversized or malformed
evidence is retained on disk and reported, never executed or silently repaired.

Other named commands: `ConvertFrom-Json`, `Get-ChildItem`, `Get-Content`, `Sort-Object`, `Test-Path`.

No statically named function caller in this inventory. Top-level, dynamic and callback invocation remain possible.

### Read-DeviceDocumentHistory

Catalogue completed historical document jobs (DOC-HISTORY) without replaying them.

Source: [autopilot-express.ps1:12398](autopilot-express.ps1#L12398). Internal entry-script function; source region: `Bench Eligibility, Dispatch and Presentation`.

| Parameter | Declared Type                    | Attributes                                           | Default                        | Source Contract                                                 |
| --------- | -------------------------------- | ---------------------------------------------------- | ------------------------------ | --------------------------------------------------------------- |
| `State`   | `System.Collections.IDictionary` | `[Parameter(Mandatory)]` `[Collections.IDictionary]` | No explicit default expression | Current document session (validated settings, mode and tenant). |

Outputs and result contract:

Newest-first detached entries shaped like session job entries, with Handle.Status
'CompletedHistory' and the validated receipt under History.

Other named commands: `ConvertFrom-Json`, `Get-ChildItem`, `Get-Content`, `Join-Path`, `Sort-Object`, `Split-Path`, `Test-Path`.

No statically named function caller in this inventory. Top-level, dynamic and callback invocation remain possible.

### Save-DeviceDocumentFailure

Retain a prequeue document failure independently of committed workflow records.

Source: [autopilot-express.ps1:12439](autopilot-express.ps1#L12439). Internal entry-script function; source region: `Bench Eligibility, Dispatch and Presentation`.

| Parameter         | Declared Type                    | Attributes                                                       | Default                        | Source Contract                                                               |
| ----------------- | -------------------------------- | ---------------------------------------------------------------- | ------------------------------ | ----------------------------------------------------------------------------- |
| `State`           | `System.Collections.IDictionary` | `[Parameter(Mandatory)]` `[Collections.IDictionary]`             | No explicit default expression | Validated current mode/tenant document session and its local storage root.    |
| `Device`          | `System.Collections.IDictionary` | `[Parameter(Mandatory)]` `[Collections.IDictionary]`             | No explicit default expression | Already committed dispatch; only document-relevant fields are copied.         |
| `Job`             | `System.Object`                  | `[AllowNull()]` `[object]`                                       | No explicit default expression | Detached job when projection succeeded, otherwise null.                       |
| `DocumentContext` | `System.Collections.IDictionary` | `[Collections.IDictionary]`                                      | `@{}`                          | Original dispatch identity text, never replaced by a later retrying operator. |
| `Diagnostic`      | `System.String`                  | `[Parameter(Mandatory)]` `[ValidateNotNullOrEmpty()]` `[string]` | No explicit default expression | Bounded failure explanation, not an exception or process object.              |

Outputs and result contract:

Session job entry, retained even if durable storage fails. Durable records use
the existing guarded UTF-8 writer; no Graph, printing or workflow writes occur.

Other named commands: `ConvertTo-Json`, `ForEach-Object`, `Join-Path`, `Test-Path`, `Where-Object`.

Named callers: [Start-DeviceDocumentJob](#start-devicedocumentjob).

### Start-DeviceDocumentJob

Queue detached output after committed dispatch, never as part of its transaction.

Source: [autopilot-express.ps1:12490](autopilot-express.ps1#L12490). Internal entry-script function; source region: `Bench Eligibility, Dispatch and Presentation`.

| Parameter | Declared Type                    | Attributes                                           | Default                        | Source Contract                                                             |
| --------- | -------------------------------- | ---------------------------------------------------- | ------------------------------ | --------------------------------------------------------------------------- |
| `Device`  | `System.Collections.IDictionary` | `[Parameter(Mandatory)]` `[Collections.IDictionary]` | No explicit default expression | The successfully persisted and published workflow, not an unsaved proposal. |

Outputs and result contract:

Host diagnostic only. Failures never undo dispatch or replay tenant actions.

Other named commands: `Get-Variable`, `Join-Path`, `Where-Object`, `Write-Host`.

Named callers: [Request-DeviceDocumentReprint](#request-devicedocumentreprint), [Complete-DeviceDispatch](#complete-devicedispatch).

### Get-DocumentJobFeedbackContext

Identify the device and build cycle that a document job belongs to.

Source: [autopilot-express.ps1:12527](autopilot-express.ps1#L12527). Internal entry-script function; source region: `Bench Eligibility, Dispatch and Presentation`.

| Parameter | Declared Type                    | Attributes                                                  | Default                        | Source Contract                                                   |
| --------- | -------------------------------- | ----------------------------------------------------------- | ------------------------------ | ----------------------------------------------------------------- |
| `Job`     | `System.Collections.IDictionary` | `[Parameter(Mandatory)]` `[System.Collections.IDictionary]` | No explicit default expression | Detached document job (JobId, RecordId, BuildCycleId and Fields). |

Outputs and result contract:

Plain-text context string; read-only, no workflow state is changed.

Other named commands: `Get-Variable`, `Select-Object`, `Where-Object`.

Named callers: [Receive-DeviceDocumentJob](#receive-devicedocumentjob).

### Receive-DeviceDocumentJob

Collect completed optional jobs without blocking menu or scanner input.

Source: [autopilot-express.ps1:12553](autopilot-express.ps1#L12553). Internal entry-script function; source region: `Bench Eligibility, Dispatch and Presentation`.

| Parameter       | Declared Type                    | Attributes                         | Default                        | Source Contract                                                                                                                                                                                                                                                                                                                |
| --------------- | -------------------------------- | ---------------------------------- | ------------------------------ | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| `FeedbackState` | `System.Collections.IDictionary` | `[System.Collections.IDictionary]` | No explicit default expression | Optional screen-owned feedback dictionary (for example the build bench). When supplied, each finished job becomes one retained event (device, cycle, outcome and full detail) so the result survives screen redraws; nothing is written to the host directly. When omitted, results are written to the host exactly as before. |

Outputs and result contract:

Contextual feedback; no prompts, Graph calls or workflow writes.

Other named commands: `ForEach-Object`, `Get-Variable`, `Join-Path`, `Where-Object`, `Write-Host`.

Named callers: [Show-DeviceDocumentSettings](#show-devicedocumentsettings), [Show-BuildBenchView](#show-buildbenchview).

### Request-DeviceDocumentReprint

Generate fresh documents for a saved dispatch without redispatch or tenant writes.

Source: [autopilot-express.ps1:12607](autopilot-express.ps1#L12607). Internal entry-script function; source region: `Bench Eligibility, Dispatch and Presentation`.

| Parameter | Declared Type                    | Attributes                                           | Default                        | Source Contract                                                                           |
| --------- | -------------------------------- | ---------------------------------------------------- | ------------------------------ | ----------------------------------------------------------------------------------------- |
| `Device`  | `System.Collections.IDictionary` | `[Parameter(Mandatory)]` `[Collections.IDictionary]` | No explicit default expression | Explicitly selected completed record; original dispatch dates and evidence remain intact. |
| `Records` | `System.Collections.Hashtable`   | `[Parameter(Mandatory)]` `[hashtable]`               | No explicit default expression | Saved records, used only for separately confirmed legacy cycle-identity repair.           |

Outputs and result contract:

Accessible queue status. Output selection is session-local to this request.
Printing requires default-No consent; each request gets a new document job identity.

Other named commands: `Get-Date`, `Where-Object`, `Write-Host`.

Named callers: [Show-DeviceActions](#show-deviceactions), [Show-DeviceDocumentSettings](#show-devicedocumentsettings).

### Show-DeviceDocumentSettings

Edit session controls, release CLI pins or explicitly save per-tenant preferences.

Source: [autopilot-express.ps1:12691](autopilot-express.ps1#L12691). Internal entry-script function; source region: `Bench Eligibility, Dispatch and Presentation`.

| Parameter | Declared Type                  | Attributes    | Default                        | Source Contract                                                                                                                              |
| --------- | ------------------------------ | ------------- | ------------------------------ | -------------------------------------------------------------------------------------------------------------------------------------------- |
| `Records` | `System.Collections.Hashtable` | `[hashtable]` | No explicit default expression | Workflow record container used by [P] to list confirmed dispatches for reprint; when omitted, reprint reports that no records are available. |

Outputs and result contract:

Accessible settings and retained job paths; no automatic network save.

Other named commands: `ConvertTo-Json`, `ForEach-Object`, `Join-Path`, `Select-Object`, `Sort-Object`, `Where-Object`, `Write-Host`.

No statically named function caller in this inventory. Top-level, dynamic and callback invocation remain possible.

### Complete-DeviceDispatch

Save normal or administrative completion and bench removal together.

Source: [autopilot-express.ps1:12854](autopilot-express.ps1#L12854). Internal entry-script function; source region: `Bench Eligibility, Dispatch and Presentation`.

| Parameter  | Declared Type                                  | Attributes                                                  | Default                        | Source Contract                                                              |
| ---------- | ---------------------------------------------- | ----------------------------------------------------------- | ------------------------------ | ---------------------------------------------------------------------------- |
| `Records`  | `System.Collections.Hashtable`                 | `[Parameter(Mandatory)]` `[hashtable]`                      | No explicit default expression | Current session collection owning Device.                                    |
| `Device`   | `System.Collections.IDictionary`               | `[Parameter(Mandatory)]` `[System.Collections.IDictionary]` | No explicit default expression | Selected workflow record, retained after dispatch.                           |
| `Override` | `System.Management.Automation.SwitchParameter` | `[switch]`                                                  | No explicit default expression | Require a reason and explicit Y; active recovery may close administratively. |

Outputs and result contract:

Completed and contextual Summary, emitted only after persistence succeeds.

Other named commands: `Get-Date`, `Get-Variable`, `Select-Object`, `Where-Object`, `Write-Host`.

Named callers: [Invoke-AutopilotSequence](#invoke-autopilotsequence), [Show-BuildBenchView](#show-buildbenchview).

### Test-DeviceReadyForDispatch

Check completion evidence for all applicable dispatch requirements.

Source: [autopilot-express.ps1:12946](autopilot-express.ps1#L12946). Internal entry-script function; source region: `Bench Eligibility, Dispatch and Presentation`.

| Parameter | Declared Type   | Attributes               | Default                        | Source Contract                   |
| --------- | --------------- | ------------------------ | ------------------------------ | --------------------------------- |
| `Device`  | `System.Object` | `[Parameter(Mandatory)]` | No explicit default expression | Current selected workflow record. |

Outputs and result contract:

Ready and BlockingStepIds dictionary. Dispatch confirmation/override remain separate;
this check does not certify external checklist handoffs.

Other named commands: `ForEach-Object`.

Named callers: [Invoke-AutopilotSequence](#invoke-autopilotsequence), [Update-DeviceStatus](#update-devicestatus), [Write-ManifestStepResult](#write-manifeststepresult), [Complete-DeviceDispatch](#complete-devicedispatch), [Show-BuildBenchView](#show-buildbenchview).

### Add-DeviceToBenchPosition

Validate a free slot and identity before attaching a new or retained device record.

Source: [autopilot-express.ps1:12962](autopilot-express.ps1#L12962). Internal entry-script function; source region: `Bench Eligibility, Dispatch and Presentation`.

| Parameter    | Declared Type                  | Attributes    | Default                        | Source Contract                                                       |
| ------------ | ------------------------------ | ------------- | ------------------------------ | --------------------------------------------------------------------- |
| `Position`   | `System.Int32`                 | `[int]`       | No explicit default expression | Existing empty position number; occupied slots cannot be overwritten. |
| `Serial`     | `System.String`                | `[string]`    | No explicit default expression | Validated serial of the proposed device.                              |
| `ConfigItem` | `System.String`                | `[string]`    | No explicit default expression | Configuration item identity for the record.                           |
| `Records`    | `System.Collections.Hashtable` | `[hashtable]` | No explicit default expression | Shared current-session record container.                              |
| `SiteCode`   | `System.String`                | `[string]`    | No explicit default expression | Selected configured site.                                             |
| `DeviceType` | `System.String`                | `[string]`    | No explicit default expression | Selected configured hardware category.                                |

Outputs and result contract:

None. Persists a validated checkpoint before promoting state. Reused records retain
their original identity, timestamps and evidence.

Other named commands: `Where-Object`, `Write-Host`.

Named callers: [Select-ExistingDeviceWorkflowAction](#select-existingdeviceworkflowaction), [Start-NewDeviceWorkflow](#start-newdeviceworkflow).

### Remove-DeviceFromBenchPosition

Clear an existing in-memory slot without deleting its retained device record.

Source: [autopilot-express.ps1:13011](autopilot-express.ps1#L13011). Internal entry-script function; source region: `Bench Eligibility, Dispatch and Presentation`.

| Parameter  | Declared Type  | Attributes | Default                        | Source Contract                                                               |
| ---------- | -------------- | ---------- | ------------------------------ | ----------------------------------------------------------------------------- |
| `Position` | `System.Int32` | `[int]`    | No explicit default expression | Existing position number; an unknown position is reported and left unchanged. |

Outputs and result contract:

None. Clears Serial and ConfigItem only; caller owns persistence and dispatch checks.

Other named commands: `Where-Object`, `Write-Host`.

Named callers: [Show-BuildBenchView](#show-buildbenchview).

### Assert-BenchPositionIdentity

Reject ambiguous saved positions before serial or CI selection.

Source: [autopilot-express.ps1:13028](autopilot-express.ps1#L13028). Internal entry-script function; source region: `Bench Eligibility, Dispatch and Presentation`.

| Parameter   | Declared Type                    | Attributes                                                    | Default | Source Contract                                                            |
| ----------- | -------------------------------- | ------------------------------------------------------------- | ------- | -------------------------------------------------------------------------- |
| `Positions` | `System.Collections.IEnumerable` | `[AllowEmptyCollection()]` `[System.Collections.IEnumerable]` | `@()`   | Bench positions to validate; empty positions and an empty bench are valid. |

Outputs and result contract:

None. Rejects ambiguous or conflicting occupied-slot identity before a checkpoint write.

Named callers: [Assert-SharedStoreSnapshot](#assert-sharedstoresnapshot), [Invoke-ExistingDeviceLifecycle](#invoke-existingdevicelifecycle), [Get-BuildBenchState](#get-buildbenchstate), [Sync-BenchRecords](#sync-benchrecords).

### Sync-BenchRecords

Validate all bench links before creating missing workflow records or saving.

Source: [autopilot-express.ps1:13055](autopilot-express.ps1#L13055). Internal entry-script function; source region: `Bench Eligibility, Dispatch and Presentation`.

| Parameter   | Declared Type                                  | Attributes    | Default                        | Source Contract                                                                           |
| ----------- | ---------------------------------------------- | ------------- | ------------------------------ | ----------------------------------------------------------------------------------------- |
| `Records`   | `System.Collections.Hashtable`                 | `[hashtable]` | No explicit default expression | Caller-owned workflow collection; invalid links leave it unchanged.                       |
| `ForceSave` | `System.Management.Automation.SwitchParameter` | `[switch]`    | No explicit default expression | Persist an explicitly created or changed bench even when no workflow records are missing. |

Outputs and result contract:

None. Reconciles validated in-memory slot references without recreating record evidence.

Other named commands: `Write-Verbose`.

No statically named function caller in this inventory. Top-level, dynamic and callback invocation remain possible.

### Show-BuildBenchTable

Render bench positions in width-bounded chunks with current/next display codes.

Source: [autopilot-express.ps1:13118](autopilot-express.ps1#L13118). Internal entry-script function; source region: `Bench Eligibility, Dispatch and Presentation`.

| Parameter | Declared Type                  | Attributes    | Default                        | Source Contract                                           |
| --------- | ------------------------------ | ------------- | ------------------------------ | --------------------------------------------------------- |
| `Records` | `System.Collections.Hashtable` | `[hashtable]` | No explicit default expression | Current-session container used to resolve occupied slots. |

Outputs and result contract:

Host text only; clipping/padding never changes stored identities or step IDs.

Other named commands: `ForEach-Object`, `Select-Object`, `Sort-Object`, `Write-Host`, `Write-Verbose`.

Named callers: [Show-BenchScreen](#show-benchscreen).

### FormatCell

Clip and right-pad one left-aligned bench cell.

Source: [autopilot-express.ps1:13139](autopilot-express.ps1#L13139). Nested in `Show-BuildBenchTable`; its enclosing scope is part of the contract.

| Parameter | Declared Type   | Attributes | Default                        | Source Contract                                                       |
| --------- | --------------- | ---------- | ------------------------------ | --------------------------------------------------------------------- |
| `text`    | `System.String` | `[string]` | No explicit default expression | Display text; stored identity remains unchanged.                      |
| `width`   | `System.Int32`  | `[int]`    | No explicit default expression | Positive available column width calculated by the enclosing renderer. |

Outputs and result contract:

Fixed-width cell string.

Named callers: [BuildRow](#buildrow).

### CenterCell

Clip and centre one bench heading within its available width.

Source: [autopilot-express.ps1:13155](autopilot-express.ps1#L13155). Nested in `Show-BuildBenchTable`; its enclosing scope is part of the contract.

| Parameter | Declared Type   | Attributes | Default                        | Source Contract                  |
| --------- | --------------- | ---------- | ------------------------------ | -------------------------------- |
| `text`    | `System.String` | `[string]` | No explicit default expression | Heading text to display.         |
| `width`   | `System.Int32`  | `[int]`    | No explicit default expression | Positive available column width. |

Outputs and result contract:

Fixed-width centred string; no console state changes.

Named callers: [BuildRow](#buildrow).

### BuildRow

Compose a bench row using the enclosing renderer's stable column widths.

Source: [autopilot-express.ps1:13175](autopilot-express.ps1#L13175). Nested in `Show-BuildBenchTable`; its enclosing scope is part of the contract.

| Parameter      | Declared Type     | Attributes   | Default                        | Source Contract                                       |
| -------------- | ----------------- | ------------ | ------------------------------ | ----------------------------------------------------- |
| `label`        | `System.String`   | `[string]`   | No explicit default expression | Accessible row heading.                               |
| `values`       | `System.String[]` | `[string[]]` | No explicit default expression | Display values for the current position chunk.        |
| `centerValues` | `System.Boolean`  | `[bool]`     | No explicit default expression | Centre headings instead of left-aligning device text. |

Outputs and result contract:

Complete row string with separators; does not write to the host.

Named callers: [Show-BuildBenchTable](#show-buildbenchtable).

### Get-TerminalViewport

Read usable terminal dimensions without requiring RawUI support.

Source: [autopilot-express.ps1:13267](autopilot-express.ps1#L13267). Internal entry-script function; source region: `Bench Eligibility, Dispatch and Presentation`.

No formal parameters declared. Captured state and enclosing scope may still be inputs.

Outputs and result contract:

Width/Height dictionary; unavailable dimensions default to 120 by 40.

Named callers: [Read-PagedInformation](#read-pagedinformation), [Show-BenchWorkflowGuide](#show-benchworkflowguide).

### Get-ScreenTextPage

Wrap accessible text and reserve header, navigation and prompt rows before paging.

Source: [autopilot-express.ps1:13285](autopilot-express.ps1#L13285). Internal entry-script function; source region: `Bench Eligibility, Dispatch and Presentation`.

| Parameter  | Declared Type                  | Attributes                              | Default                        | Source Contract                                               |
| ---------- | ------------------------------ | --------------------------------------- | ------------------------------ | ------------------------------------------------------------- |
| `Lines`    | `System.String[]`              | `[AllowEmptyCollection()]` `[string[]]` | `@()`                          | Complete source text lines; an empty collection is supported. |
| `Viewport` | `System.Collections.Hashtable` | `[Parameter(Mandatory)]` `[hashtable]`  | No explicit default expression | Width/Height dictionary for the current terminal.             |
| `Title`    | `System.String`                | `[string]`                              | No explicit default expression | Screen title included in header-height calculations.          |

Outputs and result contract:

Array of page dictionaries, each containing a Lines array. No host output or workflow mutations.

Named callers: [Read-PagedInformation](#read-pagedinformation), [Show-BenchWorkflowGuide](#show-benchworkflowguide).

### Show-BenchWorkflowGuide

Explain manifest step codes without executing actions or changing records.

Source: [autopilot-express.ps1:13326](autopilot-express.ps1#L13326). Internal entry-script function; source region: `Bench Eligibility, Dispatch and Presentation`.

| Parameter           | Declared Type   | Attributes                                                      | Default         | Source Contract                                                              |
| ------------------- | --------------- | --------------------------------------------------------------- | --------------- | ---------------------------------------------------------------------------- |
| `ReturnDestination` | `System.String` | `[ValidateSet('Build bench', 'Script Information')]` `[string]` | `'Build bench'` | Calling bench or information menu; zero returns control without redirecting. |

Outputs and result contract:

Accessible host text only; no workflow evidence or files are changed.

Other named commands: `ForEach-Object`, `Select-Object`, `Where-Object`, `Write-Host`.

Named callers: [Show-BuildBenchView](#show-buildbenchview).

### Show-BenchSectionBar

Render a full-width labelled bar with blank lines and non-colour meaning.

Source: [autopilot-express.ps1:13399](autopilot-express.ps1#L13399). Internal entry-script function; source region: `Bench Eligibility, Dispatch and Presentation`.

| Parameter    | Declared Type   | Attributes                                   | Default                        | Source Contract                                              |
| ------------ | --------------- | -------------------------------------------- | ------------------------------ | ------------------------------------------------------------ |
| `Title`      | `System.String` | `[Parameter(Mandatory)]` `[string]`          | No explicit default expression | Accessible section name, wrapped when the console is narrow. |
| `Background` | `System.String` | `[ValidateSet('Gray', 'Yellow')]` `[string]` | No explicit default expression | Grey for results or yellow for options; text remains black.  |

Outputs and result contract:

Host section heading with a textual label; colour is not the only cue.

Other named commands: `Write-Host`.

Named callers: [Read-BenchCommand](#read-benchcommand).

### Get-BenchOptionLines

Align command keys across rows, wrapping whole cells on narrow terminals.

Source: [autopilot-express.ps1:13419](autopilot-express.ps1#L13419). Internal entry-script function; source region: `Bench Eligibility, Dispatch and Presentation`.

No formal parameters declared. Captured state and enclosing scope may still be inputs.

Outputs and result contract:

Display lines only; command bindings and workflow state are unchanged.

Other named commands: `ForEach-Object`, `Measure-Object`, `Where-Object`.

Named callers: [Read-BenchCommand](#read-benchcommand).

### Read-BenchCommand

Render complete recent events, options and finally the command prompt.

Source: [autopilot-express.ps1:13453](autopilot-express.ps1#L13453). Internal entry-script function; source region: `Bench Eligibility, Dispatch and Presentation`.

| Parameter      | Declared Type                                  | Attributes                              | Default                        | Source Contract                                                                    |
| -------------- | ---------------------------------------------- | --------------------------------------- | ------------------------------ | ---------------------------------------------------------------------------------- |
| `Lines`        | `System.String[]`                              | `[AllowEmptyCollection()]` `[string[]]` | `@()`                          | Already retained, transient bench feedback, not persisted workflow evidence.       |
| `LinearOutput` | `System.Management.Automation.SwitchParameter` | `[switch]`                              | No explicit default expression | Use append-only input when cursor placement is unavailable or explicitly disabled. |

Outputs and result contract:

Entered command text; parsing and action dispatch remain separate.

Other named commands: `Write-Host`, `Write-Verbose`.

Named callers: [Show-BuildBenchView](#show-buildbenchview).

### Show-BuildBenchView

Run the bench command loop while preserving feedback across redraws.

Source: [autopilot-express.ps1:13479](autopilot-express.ps1#L13479). Internal entry-script function; source region: `Bench Eligibility, Dispatch and Presentation`.

| Parameter | Declared Type                  | Attributes    | Default                        | Source Contract                                                 |
| --------- | ------------------------------ | ------------- | ------------------------------ | --------------------------------------------------------------- |
| `Records` | `System.Collections.Hashtable` | `[hashtable]` | No explicit default expression | Mutable record container shared with tracked-device navigation. |

Outputs and result contract:

Host output only. Explicit commands own confirmations and guarded saves; Enter refreshes,
and returning to the main menu does not silently dispatch or replay pending actions.

Other named commands: `ForEach-Object`, `Measure-Object`, `Select-Object`, `Where-Object`, `Write-Host`.

No statically named function caller in this inventory. Top-level, dynamic and callback invocation remain possible.

### Write-BenchFeedback

Retain a readable result or refusal across bench redraws.

Source: [autopilot-express.ps1:13492](autopilot-express.ps1#L13492). Nested in `Show-BuildBenchView`; its enclosing scope is part of the contract.

| Parameter         | Declared Type                                  | Attributes                                                 | Default                        | Source Contract                                                     |
| ----------------- | ---------------------------------------------- | ---------------------------------------------------------- | ------------------------------ | ------------------------------------------------------------------- |
| `Text`            | `System.String`                                | `[Parameter(Mandatory)]` `[AllowEmptyString()]` `[string]` | No explicit default expression | Complete feedback text; original wording is not stripped.           |
| `ContextIncluded` | `System.Management.Automation.SwitchParameter` | `[switch]`                                                 | No explicit default expression | Mark feedback already containing its exact device identity context. |

Outputs and result contract:

None. Appends a bounded event to the enclosing feedback state.

Other named commands: `Write-Host`.

Named callers: [Show-BuildBenchView](#show-buildbenchview), [Invoke-BenchSelectedCommand](#invoke-benchselectedcommand).

### Invoke-BenchActionOutput

Execute the selected action once; callers retain its structured result summary.

Source: [autopilot-express.ps1:13507](autopilot-express.ps1#L13507). Nested in `Show-BuildBenchView`; its enclosing scope is part of the contract.

| Parameter | Declared Type                              | Attributes                               | Default                        | Source Contract                                                                       |
| --------- | ------------------------------------------ | ---------------------------------------- | ------------------------------ | ------------------------------------------------------------------------------------- |
| `Action`  | `System.Management.Automation.ScriptBlock` | `[Parameter(Mandatory)]` `[scriptblock]` | No explicit default expression | Explicitly selected workflow scriptblock; invoked once, never automatically replayed. |
| `Device`  | `System.Collections.IDictionary`           | `[System.Collections.IDictionary]`       | No explicit default expression | Selected record for optional verbose diagnostic context.                              |

Outputs and result contract:

Original action results and host output; the transcript retains complete diagnostics.

Other named commands: `Write-Verbose`.

Named callers: [Show-BuildBenchView](#show-buildbenchview), [Invoke-BenchSelectedCommand](#invoke-benchselectedcommand).

### Invoke-BenchSelectedCommand

Run one T, X, U or A bench command for one occupied position.

Source: [autopilot-express.ps1:13522](autopilot-express.ps1#L13522). Nested in `Show-BuildBenchView`; its enclosing scope is part of the contract.

| Parameter | Declared Type   | Attributes                                                              | Default                        | Source Contract                                                                            |
| --------- | --------------- | ----------------------------------------------------------------------- | ------------------------------ | ------------------------------------------------------------------------------------------ |
| `Command` | `System.String` | `[Parameter(Mandatory)]` `[ValidateSet('T', 'X', 'U', 'A')]` `[string]` | No explicit default expression | T prepares (A-D), X recovers, U withdraws the latest confirmation, A opens device actions. |
| `Slot`    | `System.Object` | `[Parameter(Mandatory)]`                                                | No explicit default expression | Occupied bench position resolved by the caller.                                            |

Outputs and result contract:

Short outcome text for the batch summary; feedback is also retained on the bench.

Other named commands: `Where-Object`.

Named callers: [Show-BuildBenchView](#show-buildbenchview).

### Show-BenchScreen

Redraw bench state, aligned commands and retained feedback without executing actions.

Source: [autopilot-express.ps1:13566](autopilot-express.ps1#L13566). Nested in `Show-BuildBenchView`; its enclosing scope is part of the contract.

No formal parameters declared. Captured state and enclosing scope may still be inputs.

Outputs and result contract:

Host output only, using the enclosing records and feedback state.

Other named commands: `ForEach-Object`, `Select-Object`, `Where-Object`, `Write-Host`.

Named callers: [Show-BuildBenchView](#show-buildbenchview).

### Resolve-BenchBatchSelection

Parse a bench batch selection such as 1,3,5-7 or ALL into position numbers.

Source: [autopilot-express.ps1:13826](autopilot-express.ps1#L13826). Internal entry-script function; source region: `Bench Eligibility, Dispatch and Presentation`.

| Parameter   | Declared Type     | Attributes                                                       | Default                        | Source Contract                                        |
| ----------- | ----------------- | ---------------------------------------------------------------- | ------------------------------ | ------------------------------------------------------ |
| `Positions` | `System.Object[]` | `[Parameter(Mandatory)]` `[AllowEmptyCollection()]` `[object[]]` | No explicit default expression | Bench positions exposing Index, Serial and ConfigItem. |
| `Selection` | `System.String`   | `[Parameter(Mandatory)]` `[AllowEmptyString()]` `[string]`       | No explicit default expression | Technician text from the bench position prompt.        |

Outputs and result contract:

$null when the text is not batch syntax (callers use single selection); otherwise
a hashtable with Positions (unique ascending integers) and Error (empty when valid).

Other named commands: `ForEach-Object`, `Sort-Object`.

Named callers: [Show-BuildBenchView](#show-buildbenchview).

### Resolve-DeviceSelection

Resolve position, serial or CI input only when it identifies one device.

Source: [autopilot-express.ps1:13883](autopilot-express.ps1#L13883). Internal entry-script function; source region: `Bench Eligibility, Dispatch and Presentation`.

| Parameter   | Declared Type                                  | Attributes                                                    | Default                        | Source Contract                                                              |
| ----------- | ---------------------------------------------- | ------------------------------------------------------------- | ------------------------------ | ---------------------------------------------------------------------------- |
| `Items`     | `System.Collections.IEnumerable`               | `[AllowEmptyCollection()]` `[System.Collections.IEnumerable]` | `@()`                          | Display-ordered workflow records or bench positions; empty input is allowed. |
| `Selection` | `System.String`                                | `[Parameter(Mandatory)]` `[AllowEmptyString()]` `[string]`    | No explicit default expression | Bare position/identifier, or explicit P:, S: or CI: selection; zero cancels. |
| `Bench`     | `System.Management.Automation.SwitchParameter` | `[switch]`                                                    | No explicit default expression | Use stored bench indices instead of displayed workflow list numbers.         |

Outputs and result contract:

One original record, or null for cancelled, missing or ambiguous input.

Other named commands: `Write-Host`.

Named callers: [Show-BuildBenchView](#show-buildbenchview), [Select-DeviceFromRecords](#select-devicefromrecords).

### Select-DeviceFromRecords

Resolve an explicit serial, configuration item or permitted numeric selection.

Source: [autopilot-express.ps1:13925](autopilot-express.ps1#L13925). Internal entry-script function; source region: `Bench Eligibility, Dispatch and Presentation`.

| Parameter          | Declared Type                                  | Attributes    | Default                        | Source Contract                                                       |
| ------------------ | ---------------------------------------------- | ------------- | ------------------------------ | --------------------------------------------------------------------- |
| `Records`          | `System.Collections.Hashtable`                 | `[hashtable]` | No explicit default expression | Record container; ineligible statuses are excluded by default.        |
| `Purpose`          | `System.String`                                | `[string]`    | No explicit default expression | Accessible context used in selection prompts and refusals.            |
| `IncludeCompleted` | `System.Management.Automation.SwitchParameter` | `[switch]`    | No explicit default expression | Include completed records for explicitly requested maintenance views. |

Outputs and result contract:

One selected record or null; ambiguity is refused rather than guessed.

Other named commands: `Where-Object`, `Write-Host`.

Named callers: [Invoke-AutopilotSequence](#invoke-autopilotsequence), [Get-DeviceOutstanding](#get-deviceoutstanding), [Update-DeviceStatus](#update-devicestatus), [Show-DeviceActions](#show-deviceactions), [Show-DeviceDocumentSettings](#show-devicedocumentsettings).

### Select-DeviceType

Select a configured hardware type by validated number or name.

Source: [autopilot-express.ps1:13952](autopilot-express.ps1#L13952). Internal entry-script function; source region: `Bench Eligibility, Dispatch and Presentation`.

| Parameter | Declared Type   | Attributes | Default                        | Source Contract                                        |
| --------- | --------------- | ---------- | ------------------------------ | ------------------------------------------------------ |
| `Default` | `System.String` | `[string]` | No explicit default expression | Current configured type offered when Enter is pressed. |

Outputs and result contract:

Configured type string; invalid values re-prompt without changing the record.

Other named commands: `Where-Object`, `Write-Host`.

Named callers: [Start-NewDeviceWorkflow](#start-newdeviceworkflow).

### Show-RecoveryEvidenceReport

Data Settings option 4: page a size report of retained recovery backups and optionally organise them.

Source: [autopilot-express.ps1:14001](autopilot-express.ps1#L14001). Internal entry-script function; source region: `Bench Eligibility, Dispatch and Presentation`.

No formal parameters declared. Captured state and enclosing scope may still be inputs.

Outputs and result contract:

Host pages only; returns to Data Settings.

Other named commands: `Group-Object`, `Measure-Object`, `Sort-Object`, `Where-Object`, `Write-Host`, `Write-Warning`.

No statically named function caller in this inventory. Top-level, dynamic and callback invocation remain possible.

### Show-ReturnToMainMenu

Keep report/error output readable until one explicit return acknowledgement.

Source: [autopilot-express.ps1:14051](autopilot-express.ps1#L14051). Internal entry-script function; source region: `Bench Eligibility, Dispatch and Presentation`.

No formal parameters declared. Captured state and enclosing scope may still be inputs.

Outputs and result contract:

Host text only; no workflow records or persisted evidence are changed.

Other named commands: `Clear-Host`, `Write-Host`.

Named callers: [Start-NewDeviceWorkflow](#start-newdeviceworkflow), [Show-SessionReportExport](#show-sessionreportexport), [Show-SessionArchive](#show-sessionarchive), [Show-DeviceInventoryBackfill](#show-deviceinventorybackfill), [Select-DeviceFromRecords](#select-devicefromrecords), [Show-RecoveryEvidenceReport](#show-recoveryevidencereport).

## Modules/Documents/AutopilotExpress.Documents.psm1

This file declares no functions. [Read the executable entry point](Modules/Documents/AutopilotExpress.Documents.psm1#L1); see the document worker and module-loading lifecycle in [TECHNICAL.md](TECHNICAL.md). It is not an empty or unused component.

## Modules/Documents/Private/Add-AutopilotDocumentBarcode.ps1

### Add-AutopilotDocumentBarcode

Generate exact printable-ASCII Code 128 and add a typed inline image relation.

Source: [Modules/Documents/Private/Add-AutopilotDocumentBarcode.ps1:16](Modules/Documents/Private/Add-AutopilotDocumentBarcode.ps1#L16). Private document-module helper.

| Parameter   | Declared Type                    | Attributes                                                                 | Default                        | Source Contract                                                                 |
| ----------- | -------------------------------- | -------------------------------------------------------------------------- | ------------------------------ | ------------------------------------------------------------------------------- |
| `Paragraph` | `System.Object`                  | `[Parameter(Mandatory)]` `[ValidateNotNull()]` `[object]`                  | No explicit default expression | Dedicated mapped paragraph containing only the expected placement example.      |
| `Part`      | `System.Object`                  | `[Parameter(Mandatory)]` `[ValidateNotNull()]` `[object]`                  | No explicit default expression | Owning document/header/footer part, where the image relationship belongs.       |
| `Payload`   | `System.String`                  | `[Parameter(Mandatory)]` `[ValidateNotNullOrEmpty()]` `[string]`           | No explicit default expression | Exact identifier; never trim, case-fold, caption, URI-encode or truncate it.    |
| `Binding`   | `System.Collections.IDictionary` | `[Parameter(Mandatory)]` `[ValidateNotNull()]` `[Collections.IDictionary]` | No explicit default expression | Reviewed bounds WidthTwips/HeightTwips, each no larger than usable cell bounds. |
| `DrawingId` | `System.Int32`                   | `[Parameter(Mandatory)]` `[ValidateRange(1, 2147483647)]` `[int]`          | No explicit default expression | Document-wide unique positive drawing identifier supplied by the renderer.      |

Outputs and result contract:

None. Too-small or non-decodable symbols fail before the document is published.

Other named commands: `Select-Object`, `Where-Object`.

Named callers: [New-AutopilotDocumentCopy](#new-autopilotdocumentcopy).

## Modules/Documents/Private/Complete-AutopilotDocumentJob.ps1

### Complete-AutopilotDocumentJob

Verify publication before removing a terminal job's exact temporary files.

Source: [Modules/Documents/Private/Complete-AutopilotDocumentJob.ps1:13](Modules/Documents/Private/Complete-AutopilotDocumentJob.ps1#L13). Private document-module helper.

| Parameter            | Declared Type                                  | Attributes                                           | Default                        | Source Contract                                                                                                                           |
| -------------------- | ---------------------------------------------- | ---------------------------------------------------- | ------------------------------ | ----------------------------------------------------------------------------------------------------------------------------------------- |
| `Directory`          | `System.String`                                | `[Parameter(Mandatory)]` `[string]`                  | No explicit default expression | Owned working directory whose lifecycle has been durably finalised.                                                                       |
| `Job`                | `System.Collections.IDictionary`               | `[Parameter(Mandatory)]` `[Collections.IDictionary]` | No explicit default expression | Detached job, including final local OutputRoot and profile identities.                                                                    |
| `Summary`            | `System.Collections.IDictionary`               | `[Parameter(Mandatory)]` `[Collections.IDictionary]` | No explicit default expression | Successful supervisor result with independently verified Word cleanup.                                                                    |
| `RetainReviewCopies` | `System.Management.Automation.SwitchParameter` | `[switch]`                                           | No explicit default expression | Preserve named populated DOCX files beside final PDFs for explicit review.                                                                |
| `RemoveReviewImages` | `System.Management.Automation.SwitchParameter` | `[switch]`                                           | No explicit default expression | Explicit legacy-review migration only: discard named page renders and duplicate staged final PDFs after retaining verified final outputs. |

Outputs and result contract:

Compact receipt path and removed-file count. Failures retain diagnostics.

Other named commands: `ConvertFrom-Json`, `ConvertTo-Json`, `Get-ChildItem`, `Get-Content`, `Get-FileHash`, `Get-Item`, `Join-Path`, `Split-Path`, `Test-Path`, `Where-Object`.

Named callers: [Move-AutopilotDocumentReviewArtifacts](#move-autopilotdocumentreviewartifacts), [Invoke-AutopilotDocumentCleanup](#invoke-autopilotdocumentcleanup).

## Modules/Documents/Private/ConvertTo-AutopilotDocumentDictionary.ps1

### ConvertTo-AutopilotDocumentDictionary

Recursively copy serialised objects into dictionaries used by document contracts.

Source: [Modules/Documents/Private/ConvertTo-AutopilotDocumentDictionary.ps1:11](Modules/Documents/Private/ConvertTo-AutopilotDocumentDictionary.ps1#L11). Private document-module helper.

| Parameter | Declared Type   | Attributes                 | Default                        | Source Contract                                    |
| --------- | --------------- | -------------------------- | ------------------------------ | -------------------------------------------------- |
| `Value`   | `System.Object` | `[AllowNull()]` `[object]` | No explicit default expression | Parsed JSON value, never executable configuration. |

Outputs and result contract:

Detached dictionaries/scalars; arrays are returned without pipeline flattening.

Named callers: [ConvertTo-AutopilotDocumentDictionary](#convertto-autopilotdocumentdictionary), [Get-AutopilotDocumentTemplateBindings](#get-autopilotdocumenttemplatebindings), [Invoke-AutopilotDocumentDeliveryCore](#invoke-autopilotdocumentdeliverycore), [Move-AutopilotDocumentReviewArtifacts](#move-autopilotdocumentreviewartifacts), [Invoke-AutopilotDocumentCleanup](#invoke-autopilotdocumentcleanup), [Receive-AutopilotDocumentJob](#receive-autopilotdocumentjob), [Start-AutopilotDocumentJob](#start-autopilotdocumentjob).

## Modules/Documents/Private/Get-AutopilotDocumentCompletionRule.ps1

### Get-AutopilotDocumentCompletionRule

Require every listed tracked step, with the last step as the trigger.

Source: [Modules/Documents/Private/Get-AutopilotDocumentCompletionRule.ps1:11](Modules/Documents/Private/Get-AutopilotDocumentCompletionRule.ps1#L11). Private document-module helper.

| Parameter | Declared Type   | Attributes                                                       | Default                        | Source Contract                                                   |
| --------- | --------------- | ---------------------------------------------------------------- | ------------------------------ | ----------------------------------------------------------------- |
| `Marker`  | `System.String` | `[Parameter(Mandatory)]` `[ValidateNotNullOrEmpty()]` `[string]` | No explicit default expression | Complete cell text, for example {complete:C} or {complete:A,B,C}. |

Outputs and result contract:

Detached rule containing the exact marker, step identifiers and trigger.

Other named commands: `Select-Object`.

Named callers: [Get-AutopilotDocumentTemplateBindings](#get-autopilotdocumenttemplatebindings).

## Modules/Documents/Private/Get-AutopilotDocumentPdfInfo.ps1

### Get-AutopilotDocumentPdfInfo

Reject missing, truncated, reparse or non-PDF worker output.

Source: [Modules/Documents/Private/Get-AutopilotDocumentPdfInfo.ps1:12](Modules/Documents/Private/Get-AutopilotDocumentPdfInfo.ps1#L12). Private document-module helper.

| Parameter | Declared Type   | Attributes                                                       | Default                        | Source Contract                                                          |
| --------- | --------------- | ---------------------------------------------------------------- | ------------------------------ | ------------------------------------------------------------------------ |
| `Path`    | `System.String` | `[Parameter(Mandatory)]` `[ValidateNotNullOrEmpty()]` `[string]` | No explicit default expression | Existing absolute local PDF, never a network share or viewer executable. |

Outputs and result contract:

Length and SHA256; does not claim the document is visually correct.

Other named commands: `Get-Item`, `Join-Path`.

Named callers: [Complete-AutopilotDocumentJob](#complete-autopilotdocumentjob), [Invoke-AutopilotDocumentDeliveryCore](#invoke-autopilotdocumentdeliverycore), [Invoke-AutopilotDocumentWordExport](#invoke-autopilotdocumentwordexport), [Move-AutopilotDocumentReviewArtifacts](#move-autopilotdocumentreviewartifacts), [Publish-AutopilotDocumentPdf](#publish-autopilotdocumentpdf), [Invoke-AutopilotDocumentPdfExport](#invoke-autopilotdocumentpdfexport).

## Modules/Documents/Private/Get-AutopilotDocumentPreservedContent.ps1

### Get-AutopilotDocumentPreservedContent

Record binary hashes and semantic OLE attributes/relationships for preservation.

Source: [Modules/Documents/Private/Get-AutopilotDocumentPreservedContent.ps1:12](Modules/Documents/Private/Get-AutopilotDocumentPreservedContent.ps1#L12). Private document-module helper.

| Parameter | Declared Type      | Attributes                                                   | Default                        | Source Contract                                                    |
| --------- | ------------------ | ------------------------------------------------------------ | ------------------------------ | ------------------------------------------------------------------ |
| `Stream`  | `System.IO.Stream` | `[Parameter(Mandatory)]` `[ValidateNotNull()]` `[IO.Stream]` | No explicit default expression | Seekable DOCX memory stream; left open and reset after inspection. |

Outputs and result contract:

Ordered dictionaries/arrays, independent of ZIP compression and XML prefixes.

Other named commands: `ConvertTo-Json`, `ForEach-Object`, `Sort-Object`, `Where-Object`.

Named callers: [New-AutopilotDocumentCopy](#new-autopilotdocumentcopy).

## Modules/Documents/Private/Get-AutopilotDocumentTemplateBindings.ps1

### Get-AutopilotDocumentTemplateBindings

Locate semantic targets and reject ambiguous or malformed row directives.

Source: [Modules/Documents/Private/Get-AutopilotDocumentTemplateBindings.ps1:12](Modules/Documents/Private/Get-AutopilotDocumentTemplateBindings.ps1#L12). Private document-module helper.

| Parameter         | Declared Type                    | Attributes                                           | Default                        | Source Contract                                                           |
| ----------------- | -------------------------------- | ---------------------------------------------------- | ------------------------------ | ------------------------------------------------------------------------- |
| `Parts`           | `System.Collections.IDictionary` | `[Parameter(Mandatory)]` `[Collections.IDictionary]` | No explicit default expression | SDK-owned document stories keyed by package URI.                          |
| `TemplateProfile` | `System.Collections.IDictionary` | `[Parameter(Mandatory)]` `[Collections.IDictionary]` | No explicit default expression | Fixed reviewed baseline; live approval is never inferred from an edit.    |
| `Changed`         | `System.Boolean`                 | `[bool]`                                             | No explicit default expression | True requests structural revalidation rather than byte-identical pinning. |

Outputs and result contract:

Effective bindings and marker paragraphs to clear after population.

Other named commands: `Select-Object`, `Where-Object`.

Named callers: [New-AutopilotDocumentCopy](#new-autopilotdocumentcopy).

## Modules/Documents/Private/Get-AutopilotDocumentValidationWarnings.ps1

### Get-AutopilotDocumentValidationWarnings

Validate a source or populated package against the same narrow policy.

Source: [Modules/Documents/Private/Get-AutopilotDocumentValidationWarnings.ps1:13](Modules/Documents/Private/Get-AutopilotDocumentValidationWarnings.ps1#L13). Private document-module helper.

| Parameter              | Declared Type                                  | Attributes                                                                | Default                        | Source Contract                                                        |
| ---------------------- | ---------------------------------------------- | ------------------------------------------------------------------------- | ------------------------------ | ---------------------------------------------------------------------- |
| `Document`             | `System.Object`                                | `[Parameter(Mandatory)]` `[ValidateNotNull()]` `[object]`                 | No explicit default expression | Child-owned SDK document; never activates objects or launches Office.  |
| `TemplateSHA256`       | `System.String`                                | `[Parameter(Mandatory)]` `[ValidatePattern('^[A-F0-9]{64}$')]` `[string]` | No explicit default expression | Fingerprint already checked against the actual source bytes.           |
| `RevalidatedChecklist` | `System.Management.Automation.SwitchParameter` | `[switch]`                                                                | No explicit default expression | Fixed reviewed checklist undergoing full edited-template revalidation. |

Outputs and result contract:

No warnings for valid packages; only the exact approved set otherwise.

Other named commands: `Where-Object`.

Named callers: [New-AutopilotDocumentCopy](#new-autopilotdocumentcopy).

## Modules/Documents/Private/Invoke-AutopilotDocumentDeliveryCore.ps1

### Invoke-AutopilotDocumentDeliveryCore

Publish one independent profile and request its configured delivery once.

Source: [Modules/Documents/Private/Invoke-AutopilotDocumentDeliveryCore.ps1:13](Modules/Documents/Private/Invoke-AutopilotDocumentDeliveryCore.ps1#L13). Private document-module helper.

| Parameter          | Declared Type                                  | Attributes                                                                          | Default                        | Source Contract                                                                     |
| ------------------ | ---------------------------------------------- | ----------------------------------------------------------------------------------- | ------------------------------ | ----------------------------------------------------------------------------------- |
| `Job`              | `System.Collections.IDictionary`               | `[Parameter(Mandatory)]` `[Collections.IDictionary]`                                | No explicit default expression | Detached, already-committed job with enabled profile and local roots.               |
| `DocumentType`     | `System.String`                                | `[Parameter(Mandatory)]` `[ValidateSet('BirthCertificate','Checklist')]` `[string]` | No explicit default expression | Profile to deliver; the other profile's receipt/outcome is independent.             |
| `PdfPath`          | `System.String`                                | `[Parameter(Mandatory)]` `[ValidateNotNullOrEmpty()]` `[string]`                    | No explicit default expression | Verified staged PDF, or retained published PDF on an explicit retry.                |
| `ReceiptDirectory` | `System.String`                                | `[Parameter(Mandatory)]` `[ValidateNotNullOrEmpty()]` `[string]`                    | No explicit default expression | Owned local job directory, never operational data or a network destination.         |
| `Adapter`          | `System.Collections.IDictionary`               | `[Parameter(Mandatory)]` `[Collections.IDictionary]`                                | No explicit default expression | Private Probe(path), Open(path) and Print(path) scriptblocks; no job-supplied code. |
| `ReviewOnly`       | `System.Boolean`                               | `[bool]`                                                                            | `$true`                        | True keeps draft output out of automatic or confirmed printing.                     |
| `PrintApproved`    | `System.Management.Automation.SwitchParameter` | `[switch]`                                                                          | No explicit default expression | Foreground consent result for GenerateAndAsk; workers never prompt.                 |
| `ExplicitRetry`    | `System.Management.Automation.SwitchParameter` | `[switch]`                                                                          | No explicit default expression | Deliberate document-only retry/reprint, never a redispatch or Graph replay.         |
| `AllowDemoPrint`   | `System.Management.Automation.SwitchParameter` | `[switch]`                                                                          | No explicit default expression | Testing override supplied only when document guards are disabled; Demo may print.   |

Outputs and result contract:

Durable result dictionary. Requested/Uncertain never means physically printed.

Other named commands: `ConvertFrom-Json`, `Get-Content`, `Get-Item`, `Join-Path`, `Test-Path`, `Where-Object`.

Named callers: [Invoke-AutopilotDocumentDelivery](#invoke-autopilotdocumentdelivery).

## Modules/Documents/Private/Invoke-AutopilotDocumentWordExport.ps1

### Invoke-AutopilotDocumentWordExport

Validate data, export one owned copy and report cleanup without publishing.

Source: [Modules/Documents/Private/Invoke-AutopilotDocumentWordExport.ps1:12](Modules/Documents/Private/Invoke-AutopilotDocumentWordExport.ps1#L12). Private document-module helper.

| Parameter      | Declared Type                                  | Attributes                                                                 | Default                        | Source Contract                                                                                                                                                                     |
| -------------- | ---------------------------------------------- | -------------------------------------------------------------------------- | ------------------------------ | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `Request`      | `System.Collections.IDictionary`               | `[Parameter(Mandatory)]` `[ValidateNotNull()]` `[Collections.IDictionary]` | No explicit default expression | SchemaVersion/JobId/JobDirectory/SourcePath/SourceSHA256/PendingPdfPath/OwnershipPath.                                                                                              |
| `Adapter`      | `System.Collections.IDictionary`               | `[Collections.IDictionary]`                                                | No explicit default expression | Private test-only operation dictionary; never accepted from job JSON.                                                                                                               |
| `KeepWordOpen` | `System.Management.Automation.SwitchParameter` | `[switch]`                                                                 | No explicit default expression | Prepared-worker mode: close only the exported document and leave the owned Word instance for reuse; an existing ownership record is then expected. Without it, cleanup closes Word. |

Outputs and result contract:

Exported/Failed result, digest and explicit cleanup state. Not a print receipt.

Other named commands: `ConvertFrom-Json`, `ConvertTo-Json`, `Get-Content`, `Get-Item`, `Join-Path`, `Test-Path`.

No statically named function caller in this inventory. Top-level, dynamic and callback invocation remain possible.

## Modules/Documents/Private/Move-AutopilotDocumentReviewArtifacts.ps1

### Move-AutopilotDocumentReviewArtifacts

Compact proven review successes and preserve other attempts intact.

Source: [Modules/Documents/Private/Move-AutopilotDocumentReviewArtifacts.ps1:12](Modules/Documents/Private/Move-AutopilotDocumentReviewArtifacts.ps1#L12). Private document-module helper.

| Parameter      | Declared Type   | Attributes                          | Default                        | Source Contract                                                         |
| -------------- | --------------- | ----------------------------------- | ------------------------------ | ----------------------------------------------------------------------- |
| `DocumentRoot` | `System.String` | `[Parameter(Mandatory)]` `[string]` | No explicit default expression | Feature-owned local Documents directory, not the application data root. |

Outputs and result contract:

Individual completed, retained or skipped migration actions and log path.

Other named commands: `ConvertFrom-Json`, `ConvertTo-Json`, `ForEach-Object`, `Get-ChildItem`, `Get-Content`, `Get-Item`, `Join-Path`, `Split-Path`, `Test-Path`, `Where-Object`.

Named callers: [Invoke-AutopilotDocumentCleanup](#invoke-autopilotdocumentcleanup).

## Modules/Documents/Private/New-AutopilotDocumentCopy.ps1

### New-AutopilotDocumentCopy

Apply literal, paragraph, native-control and barcode bindings to an owned copy.

Source: [Modules/Documents/Private/New-AutopilotDocumentCopy.ps1:12](Modules/Documents/Private/New-AutopilotDocumentCopy.ps1#L12). Private document-module helper.

| Parameter     | Declared Type                                  | Attributes                                                                 | Default                        | Source Contract                                                                                                                                                                                                                                                                                                                         |
| ------------- | ---------------------------------------------- | -------------------------------------------------------------------------- | ------------------------------ | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `Request`     | `System.Collections.IDictionary`               | `[Parameter(Mandatory)]` `[ValidateNotNull()]` `[Collections.IDictionary]` | No explicit default expression | Schema-one dictionary with Job, Profile, TemplatePath, OutputPath and ReviewOnly. Profile bindings explicitly identify part, kind, expected count and field/steps. EnforceDocumentGuards=false permits unapproved mappings without changing their approval. Absent enforcement retains guarded behaviour for older population requests. |
| `PrepareOnly` | `System.Management.Automation.SwitchParameter` | `[switch]`                                                                 | No explicit default expression | Validate and cache immutable source metadata in this isolated worker without populating, publishing or supplying device completion evidence.                                                                                                                                                                                            |

Outputs and result contract:

Structured receipt only after SDK validation; failed copies remain unpublished
with a .pending GUID suffix for diagnosis. Existing outputs are never replaced.

Other named commands: `ConvertTo-Json`, `Get-Item`, `Get-Variable`, `Out-Null`, `Select-Object`, `Split-Path`, `Test-Path`, `Where-Object`.

No statically named function caller in this inventory. Top-level, dynamic and callback invocation remain possible.

## Modules/Documents/Private/New-AutopilotDocumentDeliveryAdapter.ps1

### New-AutopilotDocumentDeliveryAdapter

Return private Probe/Open/Print operations without starting a viewer.

Source: [Modules/Documents/Private/New-AutopilotDocumentDeliveryAdapter.ps1:13](Modules/Documents/Private/New-AutopilotDocumentDeliveryAdapter.ps1#L13). Private document-module helper.

No formal parameters declared. Captured state and enclosing scope may still be inputs.

Outputs and result contract:

Adapter dictionary. A successful shell request is not physical print proof.

Other named commands: `Get-CimInstance`.

Named callers: [Invoke-AutopilotDocumentDelivery](#invoke-autopilotdocumentdelivery).

## Modules/Documents/Private/New-AutopilotDocumentWordAdapter.ps1

### New-AutopilotDocumentWordAdapter

Keep COM references and prior settings inside one owned worker instance.

Source: [Modules/Documents/Private/New-AutopilotDocumentWordAdapter.ps1:16](Modules/Documents/Private/New-AutopilotDocumentWordAdapter.ps1#L16). Private document-module helper.

No formal parameters declared. Captured state and enclosing scope may still be inputs.

Outputs and result contract:

Start/Open/Export/Close operations; no side effects until Start is invoked.

Other named commands: `Add-Type`, `Get-Process`, `New-Object`, `Select-Object`.

Named callers: [Invoke-AutopilotDocumentWordExport](#invoke-autopilotdocumentwordexport).

## Modules/Documents/Private/Publish-AutopilotDocumentPdf.ps1

### Publish-AutopilotDocumentPdf

Reserve only the base name or the document-type suffix, never a counter.

Source: [Modules/Documents/Private/Publish-AutopilotDocumentPdf.ps1:13](Modules/Documents/Private/Publish-AutopilotDocumentPdf.ps1#L13). Private document-module helper.

| Parameter      | Declared Type                    | Attributes                                                                          | Default                        | Source Contract                                                               |
| -------------- | -------------------------------- | ----------------------------------------------------------------------------------- | ------------------------------ | ----------------------------------------------------------------------------- |
| `Job`          | `System.Collections.IDictionary` | `[Parameter(Mandatory)]` `[Collections.IDictionary]`                                | No explicit default expression | Detached job containing the approved output directory and naming settings.    |
| `DocumentType` | `System.String`                  | `[Parameter(Mandatory)]` `[ValidateSet('BirthCertificate','Checklist')]` `[string]` | No explicit default expression | BirthCertificate or Checklist, used for the single allowed collision suffix.  |
| `SourcePath`   | `System.String`                  | `[Parameter(Mandatory)]` `[ValidateNotNullOrEmpty()]` `[string]`                    | No explicit default expression | Existing verified local PDF. No rendering, printing or network access occurs. |

Outputs and result contract:

Published PDF path, length and SHA-256 after a no-overwrite move.

Other named commands: `ForEach-Object`, `Join-Path`, `Test-Path`.

Named callers: [Invoke-AutopilotDocumentDeliveryCore](#invoke-autopilotdocumentdeliverycore).

## Modules/Documents/Private/Resolve-AutopilotDocumentLocalPath.ps1

### Resolve-AutopilotDocumentLocalPath

Return a canonical local directory path or throw before dependency access.

Source: [Modules/Documents/Private/Resolve-AutopilotDocumentLocalPath.ps1:12](Modules/Documents/Private/Resolve-AutopilotDocumentLocalPath.ps1#L12). Private document-module helper.

| Parameter | Declared Type   | Attributes                                                       | Default                        | Source Contract                                                        |
| --------- | --------------- | ---------------------------------------------------------------- | ------------------------------ | ---------------------------------------------------------------------- |
| `Path`    | `System.String` | `[Parameter(Mandatory)]` `[ValidateNotNullOrEmpty()]` `[string]` | No explicit default expression | Absolute local Windows dependency directory; no UNC, providers or ADS. |

Outputs and result contract:

Canonical path. No directory is created.

Other named commands: `Get-Item`, `Split-Path`, `Test-Path`.

Named callers: [Complete-AutopilotDocumentJob](#complete-autopilotdocumentjob), [Get-AutopilotDocumentPdfInfo](#get-autopilotdocumentpdfinfo), [Invoke-AutopilotDocumentDeliveryCore](#invoke-autopilotdocumentdeliverycore), [Invoke-AutopilotDocumentWordExport](#invoke-autopilotdocumentwordexport), [Move-AutopilotDocumentReviewArtifacts](#move-autopilotdocumentreviewartifacts), [New-AutopilotDocumentCopy](#new-autopilotdocumentcopy), [Publish-AutopilotDocumentPdf](#publish-autopilotdocumentpdf), [Test-AutopilotDocumentJobDirectory](#test-autopilotdocumentjobdirectory), [Write-AutopilotDocumentLifecycle](#write-autopilotdocumentlifecycle), [Write-AutopilotDocumentReceipt](#write-autopilotdocumentreceipt), [Install-AutopilotDocumentDependencyBundle](#install-autopilotdocumentdependencybundle), [Invoke-AutopilotDocumentCleanup](#invoke-autopilotdocumentcleanup), [Invoke-AutopilotDocumentDependencySelfTest](#invoke-autopilotdocumentdependencyselftest), [Invoke-AutopilotDocumentPdfExport](#invoke-autopilotdocumentpdfexport), [Invoke-AutopilotDocumentPopulation](#invoke-autopilotdocumentpopulation), [Start-AutopilotDocumentJob](#start-autopilotdocumentjob), [Test-AutopilotDocumentDependencyBundle](#test-autopilotdocumentdependencybundle).

## Modules/Documents/Private/Set-AutopilotDocumentControl.ps1

### Set-AutopilotDocumentControl

Keep native checkbox state, visible glyph and font consistent.

Source: [Modules/Documents/Private/Set-AutopilotDocumentControl.ps1:11](Modules/Documents/Private/Set-AutopilotDocumentControl.ps1#L11). Private document-module helper.

| Parameter   | Declared Type                                                                                                                     | Attributes                                                | Default                        | Source Contract                                                          |
| ----------- | --------------------------------------------------------------------------------------------------------------------------------- | --------------------------------------------------------- | ------------------------------ | ------------------------------------------------------------------------ |
| `Control`   | `System.Object`                                                                                                                   | `[Parameter(Mandatory)]` `[ValidateNotNull()]` `[object]` | No explicit default expression | One matched SDK content control, never a whole arbitrary document story. |
| `Text`      | `System.String`                                                                                                                   | `[AllowEmptyString()]` `[string]`                         | `''`                           | Text/date display value. Dates require an explicit ISO DateValue.        |
| `Checked`   | `System.Nullable`1[[System.Boolean, System.Private.CoreLib, Version=10.0.0.0, Culture=neutral, PublicKeyToken=7cec85d7bea7798e]]` | `[Nullable[bool]]`                                        | `$null`                        | Boolean checkbox value; null selects text/date handling.                 |
| `DateValue` | `System.String`                                                                                                                   | `[string]`                                                | No explicit default expression | ISO date for a native date control, independent of display formatting.   |

Outputs and result contract:

None; throws on missing/ambiguous content or unsupported bindings.

Other named commands: `Select-Object`, `Where-Object`.

Named callers: [New-AutopilotDocumentCopy](#new-autopilotdocumentcopy).

## Modules/Documents/Private/Set-AutopilotDocumentParagraphText.ps1

### Set-AutopilotDocumentParagraphText

Preserve runs and surrounding text while replacing all literal marker spans.

Source: [Modules/Documents/Private/Set-AutopilotDocumentParagraphText.ps1:12](Modules/Documents/Private/Set-AutopilotDocumentParagraphText.ps1#L12). Private document-module helper.

| Parameter      | Declared Type                    | Attributes                                                                        | Default                        | Source Contract                                                                |
| -------------- | -------------------------------- | --------------------------------------------------------------------------------- | ------------------------------ | ------------------------------------------------------------------------------ |
| `Paragraph`    | `System.Object`                  | `[Parameter(Mandatory)]` `[ValidateNotNull()]` `[object]`                         | No explicit default expression | Typed SDK paragraph in an owned document copy.                                 |
| `Replacements` | `System.Collections.IDictionary` | `[Parameter(Mandatory)]` `[ValidateNotNull()]` `[System.Collections.IDictionary]` | No explicit default expression | Literal marker/text dictionary; replacement values are not scanned as markers. |

Outputs and result contract:

Number of replaced spans. Invalid/overlapping markers fail before mutation.

Other named commands: `ForEach-Object`, `Sort-Object`.

Named callers: [New-AutopilotDocumentCopy](#new-autopilotdocumentcopy).

## Modules/Documents/Private/Stop-AutopilotDocumentOwnedWord.ps1

### Stop-AutopilotDocumentOwnedWord

Independently verify cleanup identity after worker exit or timeout.

Source: [Modules/Documents/Private/Stop-AutopilotDocumentOwnedWord.ps1:13](Modules/Documents/Private/Stop-AutopilotDocumentOwnedWord.ps1#L13). Private document-module helper.

| Parameter            | Declared Type    | Attributes                                                        | Default                        | Source Contract                                          |
| -------------------- | ---------------- | ----------------------------------------------------------------- | ------------------------------ | -------------------------------------------------------- |
| `OwnershipPath`      | `System.String`  | `[Parameter(Mandatory)]` `[ValidateNotNullOrEmpty()]` `[string]`  | No explicit default expression | Worker-created local bounded JSON ownership record.      |
| `JobId`              | `System.Guid`    | `[Parameter(Mandatory)]` `[guid]`                                 | No explicit default expression | Expected job identity, not taken from the record.        |
| `WorkerPid`          | `System.Int32`   | `[Parameter(Mandatory)]` `[ValidateRange(1, 2147483647)]` `[int]` | No explicit default expression | Expected owned child process, not taken from the record. |
| `ExcludedProcessIds` | `System.Int32[]` | `[AllowEmptyCollection()]` `[int[]]`                              | `@()`                          | All Word processes observed before launching this child. |

Outputs and result contract:

NotRunning, Stopped or Uncertain. Never terminates an unproved process.

Other named commands: `ConvertFrom-Json`, `Get-Content`, `Get-Item`, `Get-Process`.

Named callers: [Invoke-AutopilotDocumentPdfExport](#invoke-autopilotdocumentpdfexport).

## Modules/Documents/Private/Test-AutopilotDocumentJobDirectory.ps1

### Test-AutopilotDocumentJobDirectory

Recognise only a GUID leaf or the fixed device-labelled job-name grammar.

Source: [Modules/Documents/Private/Test-AutopilotDocumentJobDirectory.ps1:9](Modules/Documents/Private/Test-AutopilotDocumentJobDirectory.ps1#L9). Private document-module helper.

| Parameter   | Declared Type   | Attributes                          | Default                        | Source Contract                                                     |
| ----------- | --------------- | ----------------------------------- | ------------------------------ | ------------------------------------------------------------------- |
| `Directory` | `System.String` | `[Parameter(Mandatory)]` `[string]` | No explicit default expression | Explicit local job directory; ancestors must not be reparse points. |
| `JobId`     | `System.Guid`   | `[Parameter(Mandatory)]` `[guid]`   | No explicit default expression | Immutable detached job identity, never inferred from a human label. |

Outputs and result contract:

Boolean identity check without creating files.

Named callers: [Complete-AutopilotDocumentJob](#complete-autopilotdocumentjob), [Move-AutopilotDocumentReviewArtifacts](#move-autopilotdocumentreviewartifacts), [Write-AutopilotDocumentLifecycle](#write-autopilotdocumentlifecycle), [Invoke-AutopilotDocumentCleanup](#invoke-autopilotdocumentcleanup), [Start-AutopilotDocumentJob](#start-autopilotdocumentjob).

## Modules/Documents/Private/Test-AutopilotDocumentPackage.ps1

### Test-AutopilotDocumentPackage

Fail closed on altered archives, assets, licences or framework closure.

Source: [Modules/Documents/Private/Test-AutopilotDocumentPackage.ps1:12](Modules/Documents/Private/Test-AutopilotDocumentPackage.ps1#L12). Private document-module helper.

| Parameter     | Declared Type   | Attributes                                                                                                                     | Default                        | Source Contract                                                              |
| ------------- | --------------- | ------------------------------------------------------------------------------------------------------------------------------ | ------------------------------ | ---------------------------------------------------------------------------- |
| `ArchivePath` | `System.String` | `[Parameter(Mandatory)]` `[ValidateNotNullOrEmpty()]` `[string]`                                                               | No explicit default expression | File in the feature-owned stage/cache; size is bounded before opening ZIP.   |
| `PackageId`   | `System.String` | `[Parameter(Mandatory)]` `[ValidateSet('DocumentFormat.OpenXml', 'DocumentFormat.OpenXml.Framework', 'ZXing.Net')]` `[string]` | No explicit default expression | Reviewed package identity; callers cannot supply alternative hashes or URLs. |

Outputs and result contract:

True after all checks; otherwise throws without executing package content.

Other named commands: `Add-Type`, `Get-Item`, `Select-Object`, `Where-Object`.

Named callers: [Install-AutopilotDocumentDependencyBundle](#install-autopilotdocumentdependencybundle), [Test-AutopilotDocumentDependencyBundle](#test-autopilotdocumentdependencybundle).

## Modules/Documents/Private/Write-AutopilotDocumentLifecycle.ps1

### Write-AutopilotDocumentLifecycle

Persist a small job-owned lifecycle without touching operational records.

Source: [Modules/Documents/Private/Write-AutopilotDocumentLifecycle.ps1:12](Modules/Documents/Private/Write-AutopilotDocumentLifecycle.ps1#L12). Private document-module helper.

| Parameter   | Declared Type                    | Attributes                                                       | Default                        | Source Contract                                                              |
| ----------- | -------------------------------- | ---------------------------------------------------------------- | ------------------------------ | ---------------------------------------------------------------------------- |
| `Directory` | `System.String`                  | `[Parameter(Mandatory)]` `[ValidateNotNullOrEmpty()]` `[string]` | No explicit default expression | Exclusive-leased GUID job directory, never an arbitrary file destination.    |
| `JobId`     | `System.Guid`                    | `[Parameter(Mandatory)]` `[guid]`                                | No explicit default expression | Expected detached job identity.                                              |
| `Active`    | `System.Boolean`                 | `[Parameter(Mandatory)]` `[bool]`                                | No explicit default expression | Keep true while running or whenever cleanup remains uncertain.               |
| `Result`    | `System.Collections.IDictionary` | `[Collections.IDictionary]`                                      | No explicit default expression | Fixed supervisor outcome. Null means running, not a successful terminal job. |

Outputs and result contract:

None. Failed persistence raises; previous metadata is retained.

Other named commands: `ConvertFrom-Json`, `ConvertTo-Json`, `Get-Content`, `Get-Item`, `Join-Path`, `Test-Path`, `Where-Object`.

No statically named function caller in this inventory. Top-level, dynamic and callback invocation remain possible.

## Modules/Documents/Private/Write-AutopilotDocumentReceipt.ps1

### Write-AutopilotDocumentReceipt

Flush an intent or outcome before a delivery operation can continue.

Source: [Modules/Documents/Private/Write-AutopilotDocumentReceipt.ps1:13](Modules/Documents/Private/Write-AutopilotDocumentReceipt.ps1#L13). Private document-module helper.

| Parameter | Declared Type                    | Attributes                                                       | Default                        | Source Contract                                                                   |
| --------- | -------------------------------- | ---------------------------------------------------------------- | ------------------------------ | --------------------------------------------------------------------------------- |
| `Path`    | `System.String`                  | `[Parameter(Mandatory)]` `[ValidateNotNullOrEmpty()]` `[string]` | No explicit default expression | Explicit local JSON leaf inside the caller's owned document job directory.        |
| `Receipt` | `System.Collections.IDictionary` | `[Parameter(Mandatory)]` `[Collections.IDictionary]`             | No explicit default expression | Version-one result with immutable job, record, cycle, scope and profile identity. |

Outputs and result contract:

None. Failure terminates before the caller may request delivery.

Other named commands: `ConvertFrom-Json`, `ConvertTo-Json`, `Get-Content`, `Get-Item`, `Join-Path`, `Split-Path`, `Test-Path`.

Named callers: [Invoke-AutopilotDocumentDeliveryCore](#invoke-autopilotdocumentdeliverycore), [Start-AutopilotDocumentJob](#start-autopilotdocumentjob).

## Modules/Documents/Public/Get-AutopilotDocumentBarcodeLayout.ps1

### Get-AutopilotDocumentBarcodeLayout

Fit within a supplied usable rectangle without cropping or changing aspect ratio.

Source: [Modules/Documents/Public/Get-AutopilotDocumentBarcodeLayout.ps1:13](Modules/Documents/Public/Get-AutopilotDocumentBarcodeLayout.ps1#L13). Exported document-module API.

| Parameter     | Declared Type  | Attributes                                                   | Default                        | Source Contract                                                               |
| ------------- | -------------- | ------------------------------------------------------------ | ------------------------------ | ----------------------------------------------------------------------------- |
| `ModuleCount` | `System.Int32` | `[Parameter(Mandatory)]` `[ValidateRange(35, 4096)]` `[int]` | No explicit default expression | Exact bar/space module count returned by the reviewed ZXing Code 128 encoder. |
| `WidthTwips`  | `System.Int32` | `[Parameter(Mandatory)]` `[ValidateRange(1, 31680)]` `[int]` | No explicit default expression | Positive available width after cell margins and paragraph indentation.        |
| `HeightTwips` | `System.Int32` | `[Parameter(Mandatory)]` `[ValidateRange(1, 31680)]` `[int]` | No explicit default expression | Positive available height after row/cell margins and paragraph spacing.       |

Outputs and result contract:

Ordered pixel/EMU geometry or an actionable too-small error. No files created.

Named callers: [Add-AutopilotDocumentBarcode](#add-autopilotdocumentbarcode).

## Modules/Documents/Public/Get-AutopilotDocumentDependencyManifest.ps1

### Get-AutopilotDocumentDependencyManifest

Pin one common .NET Framework 4.8 child-runtime bundle for both parent shells.

Source: [Modules/Documents/Public/Get-AutopilotDocumentDependencyManifest.ps1:13](Modules/Documents/Public/Get-AutopilotDocumentDependencyManifest.ps1#L13). Exported document-module API.

No formal parameters declared. Captured state and enclosing scope may still be inputs.

Outputs and result contract:

Fresh ordered dictionary. NuGet trust is HTTPS plus reviewed hashes, not
a claim that publisher signatures or future advisories were verified.

Named callers: [Test-AutopilotDocumentPackage](#test-autopilotdocumentpackage), [Install-AutopilotDocumentDependencyBundle](#install-autopilotdocumentdependencybundle), [Invoke-AutopilotDocumentDependencySelfTest](#invoke-autopilotdocumentdependencyselftest), [Test-AutopilotDocumentDependencyBundle](#test-autopilotdocumentdependencybundle).

## Modules/Documents/Public/Get-AutopilotDocumentHostCapability.ps1

### Get-AutopilotDocumentHostCapability

Report local prerequisites without loading document DLLs or Word COM.

Source: [Modules/Documents/Public/Get-AutopilotDocumentHostCapability.ps1:12](Modules/Documents/Public/Get-AutopilotDocumentHostCapability.ps1#L12). Exported document-module API.

No formal parameters declared. Captured state and enclosing scope may still be inputs.

Outputs and result contract:

Ordered dictionary. Errors become diagnostics; missing Office never installs it.

Other named commands: `Join-Path`, `Test-Path`.

Named callers: [Invoke-AutopilotDocumentDependencySelfTest](#invoke-autopilotdocumentdependencyselftest), [Invoke-AutopilotDocumentPdfExport](#invoke-autopilotdocumentpdfexport), [Invoke-AutopilotDocumentPopulation](#invoke-autopilotdocumentpopulation), [Start-AutopilotDocumentJob](#start-autopilotdocumentjob), [Test-AutopilotDocumentPrerequisite](#test-autopilotdocumentprerequisite).

## Modules/Documents/Public/Get-AutopilotDocumentOutputName.ps1

### Get-AutopilotDocumentOutputName

Preserve the exact serial payload, encoding unsafe filename characters only.

Source: [Modules/Documents/Public/Get-AutopilotDocumentOutputName.ps1:12](Modules/Documents/Public/Get-AutopilotDocumentOutputName.ps1#L12). Exported document-module API.

| Parameter           | Declared Type                    | Attributes                                                                           | Default                        | Source Contract                                                               |
| ------------------- | -------------------------------- | ------------------------------------------------------------------------------------ | ------------------------------ | ----------------------------------------------------------------------------- |
| `Job`               | `System.Collections.IDictionary` | `[Parameter(Mandatory)]` `[System.Collections.IDictionary]`                          | No explicit default expression | Detached version-one job with canonical Fields and validated Settings.        |
| `DocumentType`      | `System.String`                  | `[Parameter(Mandatory)]` `[ValidateSet('BirthCertificate', 'Checklist')]` `[string]` | No explicit default expression | Stable document-type name used only as a suffix when the base name collides.  |
| `Extension`         | `System.String`                  | `[ValidateSet('pdf', 'docx')]` `[string]`                                            | `'pdf'`                        | PDF output or retained populated DOCX; not an arbitrary executable extension. |
| `OccupiedFileNames` | `System.String[]`                | `[AllowEmptyCollection()]` `[string[]]`                                              | `@()`                          | Snapshot of occupied leaf names, compared case-insensitively on Windows.      |

Outputs and result contract:

Filename only. If both base and type-suffixed names are occupied, throws.

Named callers: [Complete-AutopilotDocumentJob](#complete-autopilotdocumentjob), [Publish-AutopilotDocumentPdf](#publish-autopilotdocumentpdf).

## Modules/Documents/Public/Get-AutopilotDocumentTemplateProfile.ps1

### Get-AutopilotDocumentTemplateProfile

Return detached review bindings; OUTPUT-CERTIFICATE remains held.

Source: [Modules/Documents/Public/Get-AutopilotDocumentTemplateProfile.ps1:12](Modules/Documents/Public/Get-AutopilotDocumentTemplateProfile.ps1#L12). Exported document-module API.

| Parameter      | Declared Type   | Attributes                                                                           | Default                        | Source Contract                                             |
| -------------- | --------------- | ------------------------------------------------------------------------------------ | ------------------------------ | ----------------------------------------------------------- |
| `DocumentType` | `System.String` | `[Parameter(Mandatory)]` `[ValidateSet('BirthCertificate', 'Checklist')]` `[string]` | No explicit default expression | Independent BirthCertificate or Checklist template profile. |

Outputs and result contract:

Fresh unapproved profile; unknown/manual actions cannot tick.

Other named commands: `ForEach-Object`.

Named callers: [Request-DeviceDocumentReadiness](#request-devicedocumentreadiness), [Get-AutopilotDocumentValidationWarnings](#get-autopilotdocumentvalidationwarnings).

## Modules/Documents/Public/Install-AutopilotDocumentDependencyBundle.ps1

### Install-AutopilotDocumentDependencyBundle

Require disclosed consent before acquisition; preserve core workflow on failure.

Source: [Modules/Documents/Public/Install-AutopilotDocumentDependencyBundle.ps1:13](Modules/Documents/Public/Install-AutopilotDocumentDependencyBundle.ps1#L13). Exported document-module API.

| Parameter          | Declared Type                                  | Attributes                                                       | Default                        | Source Contract                                                                |
| ------------------ | ---------------------------------------------- | ---------------------------------------------------------------- | ------------------------------ | ------------------------------------------------------------------------------ |
| `DependencyRoot`   | `System.String`                                | `[Parameter(Mandatory)]` `[ValidateNotNullOrEmpty()]` `[string]` | No explicit default expression | Explicit local document cache root, separated from operational data/.          |
| `Consent`          | `System.String`                                | `[ValidateSet('NotGranted', 'Approved', 'Declined')]` `[string]` | `'NotGranted'`                 | Approved is explicit prior consent, not inferred from NoPrompts. Default asks. |
| `NoPrompts`        | `System.Management.Automation.SwitchParameter` | `[switch]`                                                       | No explicit default expression | Missing consent returns ConsentRequired; never silently assumes Yes.           |
| `ArchiveDirectory` | `System.String`                                | `[string]`                                                       | No explicit default expression | Optional local, already acquired archives; every file is still hash-verified.  |

Outputs and result contract:

Status/Ready/BundlePath/Diagnostic; publication alone is not runtime readiness.

Other named commands: `Add-Type`, `ConvertTo-Json`, `Copy-Item`, `Get-FileHash`, `Get-Item`, `Invoke-WebRequest`, `Join-Path`, `New-Item`, `Read-Host`, `Test-Path`, `Write-Information`.

Named callers: [Test-AutopilotDocumentPrerequisite](#test-autopilotdocumentprerequisite).

## Modules/Documents/Public/Invoke-AutopilotDocumentCleanup.ps1

### Invoke-AutopilotDocumentCleanup

Reconcile successful leftovers and failed assets within one owned root.

Source: [Modules/Documents/Public/Invoke-AutopilotDocumentCleanup.ps1:14](Modules/Documents/Public/Invoke-AutopilotDocumentCleanup.ps1#L14). Exported document-module API.

| Parameter                | Declared Type                                  | Attributes                                                       | Default                        | Source Contract                                                                                                                                  |
| ------------------------ | ---------------------------------------------- | ---------------------------------------------------------------- | ------------------------------ | ------------------------------------------------------------------------------------------------------------------------------------------------ |
| `JobRoot`                | `System.String`                                | `[Parameter(Mandatory)]` `[ValidateNotNullOrEmpty()]` `[string]` | No explicit default expression | Feature-owned Working/jobs root with immutable GUID-bound child names.                                                                           |
| `FailedJobRetentionDays` | `System.Int32`                                 | `[ValidateRange(0,3650)]` `[int]`                                | `7`                            | Seven by default. Zero disables failed-asset expiry, not successful cleanup.                                                                     |
| `NowUtc`                 | `System.DateTimeOffset`                        | `[DateTimeOffset]`                                               | `[DateTimeOffset]::UtcNow`     | Trusted clock for deterministic offline tests.                                                                                                   |
| `ReorganiseReviews`      | `System.Management.Automation.SwitchParameter` | `[switch]`                                                       | No explicit default expression | Explicit legacy-review migration. JobRoot must be the feature Documents directory. Preserves final outputs and failure evidence with a path log. |

Outputs and result contract:

Removed temporary-file counts, reversible archive moves and retained skips.

Other named commands: `ConvertFrom-Json`, `Get-ChildItem`, `Get-Content`, `Get-Item`, `Join-Path`, `Test-Path`, `Where-Object`.

Named callers: [Invoke-DeviceDocumentHousekeeping](#invoke-devicedocumenthousekeeping), [Start-DeviceDocumentJob](#start-devicedocumentjob).

## Modules/Documents/Public/Invoke-AutopilotDocumentDelivery.ps1

### Invoke-AutopilotDocumentDelivery

Publish and request PDF print/open with an immutable durable receipt.

Source: [Modules/Documents/Public/Invoke-AutopilotDocumentDelivery.ps1:13](Modules/Documents/Public/Invoke-AutopilotDocumentDelivery.ps1#L13). Exported document-module API.

| Parameter          | Declared Type                                  | Attributes                                                                          | Default                        | Source Contract                                                            |
| ------------------ | ---------------------------------------------- | ----------------------------------------------------------------------------------- | ------------------------------ | -------------------------------------------------------------------------- |
| `Job`              | `System.Collections.IDictionary`               | `[Parameter(Mandatory)]` `[Collections.IDictionary]`                                | No explicit default expression | Detached committed job. Enabled profiles independently own delivery modes. |
| `DocumentType`     | `System.String`                                | `[Parameter(Mandatory)]` `[ValidateSet('BirthCertificate','Checklist')]` `[string]` | No explicit default expression | BirthCertificate or Checklist; errors never alter operational completion.  |
| `PdfPath`          | `System.String`                                | `[Parameter(Mandatory)]` `[ValidateNotNullOrEmpty()]` `[string]`                    | No explicit default expression | Already-exported, locally verified PDF, not the DOCX source.               |
| `ReceiptDirectory` | `System.String`                                | `[Parameter(Mandatory)]` `[ValidateNotNullOrEmpty()]` `[string]`                    | No explicit default expression | Owned local job directory outside operational record discovery.            |
| `ReviewOnly`       | `System.Boolean`                               | `[bool]`                                                                            | `$true`                        | True by default; an explicit review-only request never prints.             |
| `PrintApproved`    | `System.Management.Automation.SwitchParameter` | `[switch]`                                                                          | No explicit default expression | Foreground GenerateAndAsk consent. Absence does not prompt in a worker.    |
| `ExplicitRetry`    | `System.Management.Automation.SwitchParameter` | `[switch]`                                                                          | No explicit default expression | Explicit document-only repeat; may intentionally request a second print.   |
| `AllowDemoPrint`   | `System.Management.Automation.SwitchParameter` | `[switch]`                                                                          | No explicit default expression | Testing override allowing Demo print requests when ReviewOnly is false.    |

Outputs and result contract:

Receipt dictionary, never a physical Printed or remote Saved claim.

No statically named function caller in this inventory. Top-level, dynamic and callback invocation remain possible.

## Modules/Documents/Public/Invoke-AutopilotDocumentDependencySelfTest.ps1

### Invoke-AutopilotDocumentDependencySelfTest

Verify the bundle, then run real in-memory DOCX and PNG round trips.

Source: [Modules/Documents/Public/Invoke-AutopilotDocumentDependencySelfTest.ps1:12](Modules/Documents/Public/Invoke-AutopilotDocumentDependencySelfTest.ps1#L12). Exported document-module API.

| Parameter        | Declared Type   | Attributes                                                       | Default                        | Source Contract                                                           |
| ---------------- | --------------- | ---------------------------------------------------------------- | ------------------------------ | ------------------------------------------------------------------------- |
| `DependencyRoot` | `System.String` | `[Parameter(Mandatory)]` `[ValidateNotNullOrEmpty()]` `[string]` | No explicit default expression | Explicit local owned cache with a verified complete bundle.               |
| `TimeoutSeconds` | `System.Int32`  | `[ValidateRange(1, 3600)]` `[int]`                               | `60`                           | Positive bounded attempt deadline, defaulting to the approved 60 seconds. |

Outputs and result contract:

Ready/Status/Diagnostic and independent library probes, not Word readiness.

Other named commands: `ConvertFrom-Json`, `Join-Path`, `Split-Path`.

Named callers: [Test-AutopilotDocumentPrerequisite](#test-autopilotdocumentprerequisite).

## Modules/Documents/Public/Invoke-AutopilotDocumentPdfExport.ps1

### Invoke-AutopilotDocumentPdfExport

Publish a new local PDF only after verified export and owned cleanup.

Source: [Modules/Documents/Public/Invoke-AutopilotDocumentPdfExport.ps1:13](Modules/Documents/Public/Invoke-AutopilotDocumentPdfExport.ps1#L13). Exported document-module API.

| Parameter        | Declared Type                    | Attributes                                                                 | Default                        | Source Contract                                                                                                                                         |
| ---------------- | -------------------------------- | -------------------------------------------------------------------------- | ------------------------------ | ------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `Request`        | `System.Collections.IDictionary` | `[Parameter(Mandatory)]` `[ValidateNotNull()]` `[Collections.IDictionary]` | No explicit default expression | SchemaVersion=1, JobId, JobDirectory, SourcePath, SourceSHA256, OutputPath. Source must be an already populated owned copy, never an original template. |
| `TimeoutSeconds` | `System.Int32`                   | `[ValidateRange(1, 3600)]` `[int]`                                         | `60`                           | External worker deadline (default 60); owned cleanup adds at most two 5s waits.                                                                         |

Outputs and result contract:

Exported/Failed/TimedOut/Unavailable receipt; never a physical print claim.

Other named commands: `ConvertFrom-Json`, `ConvertTo-Json`, `Get-Process`, `Join-Path`, `Select-Object`, `Split-Path`, `Test-Path`.

No statically named function caller in this inventory. Top-level, dynamic and callback invocation remain possible.

## Modules/Documents/Public/Invoke-AutopilotDocumentPopulation.ps1

### Invoke-AutopilotDocumentPopulation

Run structural population with an external 60-second default deadline.

Source: [Modules/Documents/Public/Invoke-AutopilotDocumentPopulation.ps1:13](Modules/Documents/Public/Invoke-AutopilotDocumentPopulation.ps1#L13). Exported document-module API.

| Parameter        | Declared Type                    | Attributes                                                                 | Default                        | Source Contract                                                               |
| ---------------- | -------------------------------- | -------------------------------------------------------------------------- | ------------------------------ | ----------------------------------------------------------------------------- |
| `Request`        | `System.Collections.IDictionary` | `[Parameter(Mandatory)]` `[ValidateNotNull()]` `[Collections.IDictionary]` | No explicit default expression | Schema-one Job/Profile/TemplatePath/OutputPath/ReviewOnly dictionary.         |
| `DependencyRoot` | `System.String`                  | `[Parameter(Mandatory)]` `[ValidateNotNullOrEmpty()]` `[string]`           | No explicit default expression | Previously approved feature-owned dependency cache, never auto-acquired here. |
| `TimeoutSeconds` | `System.Int32`                   | `[ValidateRange(1, 3600)]` `[int]`                                         | `60`                           | External deadline; only the owned child may be stopped.                       |

Outputs and result contract:

Structured result/diagnostic; a populated DOCX is not a PDF or print.

Other named commands: `ConvertFrom-Json`, `ConvertTo-Json`, `Join-Path`, `Split-Path`, `Test-Path`.

No statically named function caller in this inventory. Top-level, dynamic and callback invocation remain possible.

## Modules/Documents/Public/New-AutopilotDocumentJob.ps1

### New-AutopilotDocumentJob

Snapshot allowlisted identity, document fields and individual step eligibility.

Source: [Modules/Documents/Public/New-AutopilotDocumentJob.ps1:13](Modules/Documents/Public/New-AutopilotDocumentJob.ps1#L13). Exported document-module API.

| Parameter              | Declared Type                    | Attributes                                                          | Default                        | Source Contract                                                                                                                                                                                                                                                                                                                                                                              |
| ---------------------- | -------------------------------- | ------------------------------------------------------------------- | ------------------------------ | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `Settings`             | `System.Collections.IDictionary` | `[Parameter(Mandatory)]` `[System.Collections.IDictionary]`         | No explicit default expression | Validated Resolve-AutopilotDocumentSettings output; absent enablement yields no job.                                                                                                                                                                                                                                                                                                         |
| `Device`               | `System.Collections.IDictionary` | `[Parameter(Mandatory)]` `[System.Collections.IDictionary]`         | No explicit default expression | Normalised current version-two record, never a path into operational data/.                                                                                                                                                                                                                                                                                                                  |
| `Mode`                 | `System.String`                  | `[Parameter(Mandatory)]` `[ValidateSet('Demo', 'Live')]` `[string]` | No explicit default expression | Explicit trusted parent-session mode, not inferred from template or device text.                                                                                                                                                                                                                                                                                                             |
| `TenantId`             | `System.String`                  | `[Parameter(Mandatory)]` `[ValidateNotNullOrEmpty()]` `[string]`    | No explicit default expression | Parent-session binding. Live requires a non-empty GUID matching the record.                                                                                                                                                                                                                                                                                                                  |
| `CreatedAtUtc`         | `System.DateTimeOffset`          | `[DateTimeOffset]`                                                  | `[DateTimeOffset]::UtcNow`     | Generation timestamp; filename date remains the original saved dispatch date.                                                                                                                                                                                                                                                                                                                |
| `DocumentContext`      | `System.Collections.IDictionary` | `[System.Collections.IDictionary]`                                  | `@{}`                          | Detached site and identity text supplied by the trusted dispatch caller. TechnicianGivenName, TechnicianSurname and TechnicianDisplayName describe the dispatching actor, never the earlier imaging account. AssignedUserGivenName and AssignedUserSurname describe the record's final assigned user. SiteName is the selected site's full name. Missing names never fall back to usernames. |
| `AssignedUserRequired` | `System.Boolean`                 | `[bool]`                                                            | `$true`                        | True for the normal final-user assignment workflow. A caller may explicitly declare no assigned user is required; this does not supply assignment evidence.                                                                                                                                                                                                                                  |

Outputs and result contract:

Detached serialisable job dictionary, or null when no output is enabled.

Other named commands: `Join-Path`, `Where-Object`.

Named callers: [Start-DeviceDocumentJob](#start-devicedocumentjob), [Show-DeviceDocumentSettings](#show-devicedocumentsettings).

## Modules/Documents/Public/New-AutopilotDocumentResult.ps1

### New-AutopilotDocumentResult

Initialise every result field before asynchronous delivery can update it.

Source: [Modules/Documents/Public/New-AutopilotDocumentResult.ps1:12](Modules/Documents/Public/New-AutopilotDocumentResult.ps1#L12). Exported document-module API.

| Parameter      | Declared Type                    | Attributes                                                                           | Default                        | Source Contract                                                          |
| -------------- | -------------------------------- | ------------------------------------------------------------------------------------ | ------------------------------ | ------------------------------------------------------------------------ |
| `Job`          | `System.Collections.IDictionary` | `[Parameter(Mandatory)]` `[System.Collections.IDictionary]`                          | No explicit default expression | Detached job identity and context; contains no live workflow references. |
| `DocumentType` | `System.String`                  | `[Parameter(Mandatory)]` `[ValidateSet('BirthCertificate', 'Checklist')]` `[string]` | No explicit default expression | Enabled profile owned by this job.                                       |

Outputs and result contract:

Pending result dictionary suitable for a future durable receipt; not saved here.

Other named commands: `Where-Object`.

Named callers: [Invoke-AutopilotDocumentDeliveryCore](#invoke-autopilotdocumentdeliverycore).

## Modules/Documents/Public/Receive-AutopilotDocumentJob.ps1

### Receive-AutopilotDocumentJob

Return Running immediately or collect and dispose a completed owned process.

Source: [Modules/Documents/Public/Receive-AutopilotDocumentJob.ps1:12](Modules/Documents/Public/Receive-AutopilotDocumentJob.ps1#L12). Exported document-module API.

| Parameter | Declared Type                    | Attributes                                           | Default                        | Source Contract                                                                |
| --------- | -------------------------------- | ---------------------------------------------------- | ------------------------------ | ------------------------------------------------------------------------------ |
| `Handle`  | `System.Collections.IDictionary` | `[Parameter(Mandatory)]` `[Collections.IDictionary]` | No explicit default expression | Live handle returned by Start-AutopilotDocumentJob, not deserialised job data. |

Outputs and result contract:

Status/results dictionary for the application's existing logging boundary.

Other named commands: `ConvertFrom-Json`.

Named callers: [Receive-DeviceDocumentJob](#receive-devicedocumentjob).

## Modules/Documents/Public/Resolve-AutopilotDocumentSettings.ps1

### Resolve-AutopilotDocumentSettings

Resolve each setting from defaults through explicit command-line overrides.

Source: [Modules/Documents/Public/Resolve-AutopilotDocumentSettings.ps1:12](Modules/Documents/Public/Resolve-AutopilotDocumentSettings.ps1#L12). Exported document-module API.

| Parameter              | Declared Type                    | Attributes                                                       | Default                        | Source Contract                                                                   |
| ---------------------- | -------------------------------- | ---------------------------------------------------------------- | ------------------------------ | --------------------------------------------------------------------------------- |
| `ScriptRoot`           | `System.String`                  | `[Parameter(Mandatory)]` `[ValidateNotNullOrEmpty()]` `[string]` | No explicit default expression | Absolute bootstrap-authorised application directory, never the current directory. |
| `LocalApplicationData` | `System.String`                  | `[Parameter(Mandatory)]` `[ValidateNotNullOrEmpty()]` `[string]` | No explicit default expression | Absolute local per-technician application-data directory; no temporary fallback.  |
| `RuntimeConfiguration` | `System.Collections.IDictionary` | `[System.Collections.IDictionary]`                               | `@{}`                          | Normalised documentGeneration dictionary, not the whole runtime configuration.    |
| `SavedPreferences`     | `System.Collections.IDictionary` | `[System.Collections.IDictionary]`                               | `@{}`                          | Previously validated technician/mode/tenant preference values; not written here.  |
| `SessionPreferences`   | `System.Collections.IDictionary` | `[System.Collections.IDictionary]`                               | `@{}`                          | In-memory settings; cannot supersede a command-line pin until it is removed.      |
| `CommandLineOverrides` | `System.Collections.IDictionary` | `[System.Collections.IDictionary]`                               | `@{}`                          | Explicit overrides. Null means absent, whereas false is an explicit disable.      |

Outputs and result contract:

Dictionary with SchemaVersion, detached Values and per-setting Sources.

Other named commands: `Join-Path`.

Named callers: [Initialize-DeviceDocumentSession](#initialize-devicedocumentsession), [Request-DeviceDocumentReadiness](#request-devicedocumentreadiness), [Show-DeviceDocumentSettings](#show-devicedocumentsettings).

## Modules/Documents/Public/Start-AutopilotDocumentJob.ps1

### Start-AutopilotDocumentJob

Start optional output only after committed dispatch or explicit document retry.

Source: [Modules/Documents/Public/Start-AutopilotDocumentJob.ps1:12](Modules/Documents/Public/Start-AutopilotDocumentJob.ps1#L12). Exported document-module API.

| Parameter               | Declared Type                                  | Attributes                                                       | Default                        | Source Contract                                                                                                                                |
| ----------------------- | ---------------------------------------------- | ---------------------------------------------------------------- | ------------------------------ | ---------------------------------------------------------------------------------------------------------------------------------------------- |
| `Job`                   | `System.Collections.IDictionary`               | `[AllowNull()]` `[Collections.IDictionary]`                      | No explicit default expression | Detached New-AutopilotDocumentJob output; null does nothing before host probes.                                                                |
| `DependencyRoot`        | `System.String`                                | `[Parameter(Mandatory)]` `[ValidateNotNullOrEmpty()]` `[string]` | No explicit default expression | Previously approved verified local bundle directory; acquisition is foreground-only.                                                           |
| `ReviewOnly`            | `System.Boolean`                               | `[bool]`                                                         | `$true`                        | Explicit draft review requests never print, even when testing guards are off.                                                                  |
| `PrintApproved`         | `System.Management.Automation.SwitchParameter` | `[switch]`                                                       | No explicit default expression | Explicit foreground consent for GenerateAndAsk, never a worker prompt.                                                                         |
| `ExplicitRetry`         | `System.Management.Automation.SwitchParameter` | `[switch]`                                                       | No explicit default expression | Reuse this job's retained outputs/receipt for deliberate document-only retry.                                                                  |
| `EnforceDocumentGuards` | `System.Boolean`                               | `[bool]`                                                         | `$false`                       | False (testing default) permits unapproved profiles and Demo printing. True restores DRAFT/non-printing guards. Demo page labels always apply. |
| `PreparationSettings`   | `System.Collections.IDictionary`               | `[Collections.IDictionary]`                                      | No explicit default expression | Validated settings for one device-free, one-use prepared SDK/Word worker.                                                                      |
| `PreparedWorker`        | `System.Collections.IDictionary`               | `[Collections.IDictionary]`                                      | No explicit default expression | Live preparation handle owned by this caller, never deserialised job input.                                                                    |
| `StopPreparation`       | `System.Management.Automation.SwitchParameter` | `[switch]`                                                       | No explicit default expression | Request graceful cancellation of an unused prepared worker.                                                                                    |

Outputs and result contract:

Supervisor handle dictionary for Receive-AutopilotDocumentJob; no waiting for Word.

Other named commands: `ConvertFrom-Json`, `ConvertTo-Json`, `Get-Content`, `Get-Item`, `Join-Path`, `Split-Path`, `Test-Path`, `Where-Object`, `Write-Verbose`.

Named callers: [Start-DeviceDocumentJob](#start-devicedocumentjob), [Receive-DeviceDocumentJob](#receive-devicedocumentjob), [Show-DeviceDocumentSettings](#show-devicedocumentsettings).

## Modules/Documents/Public/Test-AutopilotDocumentDependencyBundle.ps1

### Test-AutopilotDocumentDependencyBundle

Reverify the pinned DLLs, retained archives and publication marker.

Source: [Modules/Documents/Public/Test-AutopilotDocumentDependencyBundle.ps1:12](Modules/Documents/Public/Test-AutopilotDocumentDependencyBundle.ps1#L12). Exported document-module API.

| Parameter        | Declared Type   | Attributes                                                       | Default                        | Source Contract                                                             |
| ---------------- | --------------- | ---------------------------------------------------------------- | ------------------------------ | --------------------------------------------------------------------------- |
| `DependencyRoot` | `System.String` | `[Parameter(Mandatory)]` `[ValidateNotNullOrEmpty()]` `[string]` | No explicit default expression | Explicit feature-owned cache root; no current-directory or shared fallback. |

Outputs and result contract:

Valid, Status, BundlePath and Diagnostic; never loads code or modifies files.

Other named commands: `ConvertFrom-Json`, `Get-Content`, `Get-FileHash`, `Get-Item`, `Join-Path`, `Test-Path`.

Named callers: [Install-AutopilotDocumentDependencyBundle](#install-autopilotdocumentdependencybundle), [Invoke-AutopilotDocumentDependencySelfTest](#invoke-autopilotdocumentdependencyselftest), [Invoke-AutopilotDocumentPopulation](#invoke-autopilotdocumentpopulation), [Start-AutopilotDocumentJob](#start-autopilotdocumentjob).

## Modules/Documents/Public/Test-AutopilotDocumentPrerequisite.ps1

### Test-AutopilotDocumentPrerequisite

Return immediately when outputs are off; never install Office or Graph.

Source: [Modules/Documents/Public/Test-AutopilotDocumentPrerequisite.ps1:12](Modules/Documents/Public/Test-AutopilotDocumentPrerequisite.ps1#L12). Exported document-module API.

| Parameter          | Declared Type                                  | Attributes                                                                               | Default                        | Source Contract                                                                    |
| ------------------ | ---------------------------------------------- | ---------------------------------------------------------------------------------------- | ------------------------------ | ---------------------------------------------------------------------------------- |
| `Settings`         | `System.Collections.IDictionary`               | `[Parameter(Mandatory)]` `[ValidateNotNullOrEmpty()]` `[System.Collections.IDictionary]` | No explicit default expression | Resolved settings contract from Resolve-AutopilotDocumentSettings.                 |
| `Consent`          | `System.String`                                | `[ValidateSet('NotGranted', 'Approved', 'Declined')]` `[string]`                         | `'NotGranted'`                 | Explicit acquisition decision; default prompts only for an enabled feature.        |
| `NoPrompts`        | `System.Management.Automation.SwitchParameter` | `[switch]`                                                                               | No explicit default expression | Return ConsentRequired rather than inventing consent when packages are absent.     |
| `ArchiveDirectory` | `System.String`                                | `[string]`                                                                               | No explicit default expression | Optional already-approved offline package directory, still independently verified. |

Outputs and result contract:

Status/Ready/Diagnostic plus host, acquisition and library evidence. Ready
means library tests and Word registration only, not activation or PDF proof.

Other named commands: `Join-Path`.

Named callers: [Request-DeviceDocumentReadiness](#request-devicedocumentreadiness).

## Modules/Documents/Public/Test-AutopilotDocumentTick.ps1

### Test-AutopilotDocumentTick

Require admissible evidence for every represented step, never an empty group.

Source: [Modules/Documents/Public/Test-AutopilotDocumentTick.ps1:11](Modules/Documents/Public/Test-AutopilotDocumentTick.ps1#L11). Exported document-module API.

| Parameter         | Declared Type                    | Attributes                                                          | Default                        | Source Contract                                                                 |
| ----------------- | -------------------------------- | ------------------------------------------------------------------- | ------------------------------ | ------------------------------------------------------------------------------- |
| `Steps`           | `System.Collections.IDictionary` | `[Parameter(Mandatory)]` `[System.Collections.IDictionary]`         | No explicit default expression | Current-cycle saved results, not historical attempts or handoff instructions.   |
| `RequiredStepIds` | `System.String[]`                | `[AllowEmptyCollection()]` `[string[]]`                             | `@()`                          | Reviewed mapping's complete set of represented steps; empty means no tick.      |
| `Mode`            | `System.String`                  | `[Parameter(Mandatory)]` `[ValidateSet('Demo', 'Live')]` `[string]` | No explicit default expression | Demo cannot certify Live work, even if supplied synthetic results say Verified. |
| `BuildCycleId`    | `System.Guid`                    | `[Parameter(Mandatory)]` `[guid]`                                   | No explicit default expression | Expected cycle; explicitly different evidence-cycle metadata is rejected.       |
| `CycleStartedAt`  | `System.DateTimeOffset`          | `[Parameter(Mandatory)]` `[DateTimeOffset]`                         | No explicit default expression | Earliest admissible evidence timestamp for this cycle.                          |
| `DispatchedAt`    | `System.DateTimeOffset`          | `[Parameter(Mandatory)]` `[DateTimeOffset]`                         | No explicit default expression | Latest admissible evidence timestamp for this dispatch.                         |

Outputs and result contract:

Boolean. Broad workflow completion/override rules are deliberately not reused.

Named callers: [New-AutopilotDocumentJob](#new-autopilotdocumentjob).

## Modules/Documents/Workers/Export-DocumentPdf.ps1

This file declares no functions. [Read the executable entry point](Modules/Documents/Workers/Export-DocumentPdf.ps1#L1); see the document worker and module-loading lifecycle in [TECHNICAL.md](TECHNICAL.md). It is not an empty or unused component.

## Modules/Documents/Workers/Invoke-DocumentJob.ps1

This file declares no functions. [Read the executable entry point](Modules/Documents/Workers/Invoke-DocumentJob.ps1#L1); see the document worker and module-loading lifecycle in [TECHNICAL.md](TECHNICAL.md). It is not an empty or unused component.

## Modules/Documents/Workers/Populate-Document.ps1

This file declares no functions. [Read the executable entry point](Modules/Documents/Workers/Populate-Document.ps1#L1); see the document worker and module-loading lifecycle in [TECHNICAL.md](TECHNICAL.md). It is not an empty or unused component.

## Modules/Documents/Workers/Run-DocumentJob.ps1

This file declares no functions. [Read the executable entry point](Modules/Documents/Workers/Run-DocumentJob.ps1#L1); see the document worker and module-loading lifecycle in [TECHNICAL.md](TECHNICAL.md). It is not an empty or unused component.

## Modules/Documents/Workers/Test-DocumentLibraries.ps1

This file declares no functions. [Read the executable entry point](Modules/Documents/Workers/Test-DocumentLibraries.ps1#L1); see the document worker and module-loading lifecycle in [TECHNICAL.md](TECHNICAL.md). It is not an empty or unused component.
