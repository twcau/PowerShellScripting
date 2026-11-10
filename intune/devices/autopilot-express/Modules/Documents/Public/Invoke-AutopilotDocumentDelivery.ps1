<#
.SYNOPSIS
    Request one independent document's policy-authorised PDF delivery.
.DESCRIPTION
    Intended for the bounded document worker. Persists intent and suppresses
    automatic replay; explicit retry is document-only. Never uses Word to print,
    installs a handler, changes printers or saves to a remote location.
.FILECREATED
    2026-10-24
.FILELASTUPDATED
    2026-10-29
#>
function Invoke-AutopilotDocumentDelivery {
    <#
    .SYNOPSIS
        Publish and request PDF print/open with an immutable durable receipt.
    .PARAMETER Job
        Detached committed job. Enabled profiles independently own delivery modes.
    .PARAMETER DocumentType
        BirthCertificate or Checklist; errors never alter operational completion.
    .PARAMETER PdfPath
        Already-exported, locally verified PDF, not the DOCX source.
    .PARAMETER ReceiptDirectory
        Owned local job directory outside operational record discovery.
    .PARAMETER ReviewOnly
        True by default; an explicit review-only request never prints.
    .PARAMETER PrintApproved
        Foreground GenerateAndAsk consent. Absence does not prompt in a worker.
    .PARAMETER ExplicitRetry
        Explicit document-only repeat; may intentionally request a second print.
    .PARAMETER AllowDemoPrint
        Testing override allowing Demo print requests when ReviewOnly is false.
    .OUTPUTS
        Receipt dictionary, never a physical Printed or remote Saved claim.
    #>
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'None')]
    [OutputType([Collections.Specialized.OrderedDictionary])]
    param(
        [Parameter(Mandatory)][Collections.IDictionary]$Job,
        [Parameter(Mandatory)][ValidateSet('BirthCertificate','Checklist')][string]$DocumentType,
        [Parameter(Mandatory)][ValidateNotNullOrEmpty()][string]$PdfPath,
        [Parameter(Mandatory)][ValidateNotNullOrEmpty()][string]$ReceiptDirectory,
        [bool]$ReviewOnly = $true,
        [switch]$PrintApproved,
        [switch]$ExplicitRetry,
        [switch]$AllowDemoPrint
    )
    if (-not $PSCmdlet.ShouldProcess($PdfPath, 'Persist PDF delivery intent and request configured shell operation')) { return [ordered]@{ Status = 'WhatIf' } }
    $adapter = New-AutopilotDocumentDeliveryAdapter
    return Invoke-AutopilotDocumentDeliveryCore -Job $Job -DocumentType $DocumentType -PdfPath $PdfPath -ReceiptDirectory $ReceiptDirectory -Adapter $adapter -ReviewOnly $ReviewOnly -PrintApproved:$PrintApproved -ExplicitRetry:$ExplicitRetry -AllowDemoPrint:$AllowDemoPrint
}