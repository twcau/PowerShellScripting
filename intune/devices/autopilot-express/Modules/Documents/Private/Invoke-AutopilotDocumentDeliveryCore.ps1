<#
.SYNOPSIS
    Persist delivery intent before one policy-authorised PDF print/open request.
.DESCRIPTION
    Adapters are private test/host boundaries, never deserialised job code. Receipts
    suppress automatic replay, retain honest uncertainty and never claim paper
    output or a completed manual network save. No Graph or workflow writes occur.
.FILECREATED
    2026-10-24
.FILELASTUPDATED
    2026-10-29
#>
function Invoke-AutopilotDocumentDeliveryCore {
    <#
    .SYNOPSIS
        Publish one independent profile and request its configured delivery once.
    .PARAMETER Job
        Detached, already-committed job with enabled profile and local roots.
    .PARAMETER DocumentType
        Profile to deliver; the other profile's receipt/outcome is independent.
    .PARAMETER PdfPath
        Verified staged PDF, or retained published PDF on an explicit retry.
    .PARAMETER ReceiptDirectory
        Owned local job directory, never operational data or a network destination.
    .PARAMETER Adapter
        Private Probe(path), Open(path) and Print(path) scriptblocks; no job-supplied code.
    .PARAMETER ReviewOnly
        True keeps draft output out of automatic or confirmed printing.
    .PARAMETER PrintApproved
        Foreground consent result for GenerateAndAsk; workers never prompt.
    .PARAMETER ExplicitRetry
        Deliberate document-only retry/reprint, never a redispatch or Graph replay.
    .PARAMETER AllowDemoPrint
        Testing override supplied only when document guards are disabled; Demo may print.
    .OUTPUTS
        Durable result dictionary. Requested/Uncertain never means physically printed.
    #>
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'None')]
    [OutputType([Collections.Specialized.OrderedDictionary])]
    param(
        [Parameter(Mandatory)][Collections.IDictionary]$Job,
        [Parameter(Mandatory)][ValidateSet('BirthCertificate','Checklist')][string]$DocumentType,
        [Parameter(Mandatory)][ValidateNotNullOrEmpty()][string]$PdfPath,
        [Parameter(Mandatory)][ValidateNotNullOrEmpty()][string]$ReceiptDirectory,
        [Parameter(Mandatory)][Collections.IDictionary]$Adapter,
        [bool]$ReviewOnly = $true,
        [switch]$PrintApproved,
        [switch]$ExplicitRetry,
        [switch]$AllowDemoPrint
    )
    $receipt = New-AutopilotDocumentResult -Job $Job -DocumentType $DocumentType
    $profiles = @($Job['Profiles'] | Where-Object { $_['DocumentType'] -ceq $DocumentType })
    if ($profiles.Count -ne 1) { throw 'Delivery requires exactly one enabled profile.' }
    $policy = [string]$profiles[0]['DeliveryMode']
    if ($policy -cnotin @('Disabled','GenerateOnly','Review','GenerateAndAsk','AutoPrint')) { throw 'Unsupported PDF delivery mode.' }
    $receipt.DeliveryMode = $policy; $receipt.ReviewOnly = $ReviewOnly
    if ($policy -eq 'Disabled') { $receipt.Status = 'Disabled'; return $receipt }
    $directory = Resolve-AutopilotDocumentLocalPath -Path $ReceiptDirectory
    if (-not $PSCmdlet.ShouldProcess($PdfPath, 'Persist delivery intent and request authorised PDF delivery')) { $receipt.Status = 'WhatIf'; return $receipt }
    $null = [IO.Directory]::CreateDirectory($directory)
    $receiptPath = Join-Path $directory ('{0}-{1}.receipt.json' -f $receipt.JobId, $DocumentType)
    $lockPath = '{0}.lock' -f $receiptPath
    if (Test-Path -LiteralPath $lockPath) {
        if ((Get-Item -LiteralPath $lockPath -Force).Attributes -band [IO.FileAttributes]::ReparsePoint) { throw 'Receipt lock cannot be a reparse point.' }
    }
    $lease = [IO.File]::Open($lockPath, [IO.FileMode]::OpenOrCreate, [IO.FileAccess]::ReadWrite, [IO.FileShare]::None)
    try {
        if (Test-Path -LiteralPath $receiptPath) {
            $file = Get-Item -LiteralPath $receiptPath -Force -ErrorAction Stop
            if ($file.PSIsContainer -or $file.Length -gt 65536 -or ($file.Attributes -band [IO.FileAttributes]::ReparsePoint)) { throw 'Existing delivery receipt is unsafe.' }
            $saved = ConvertTo-AutopilotDocumentDictionary -Value (Get-Content -LiteralPath $receiptPath -Raw -Encoding UTF8 | ConvertFrom-Json -ErrorAction Stop)
            foreach ($key in @('JobId','RecordId','BuildCycleId','Mode','TenantId','DocumentType')) {
                if ([string]$saved[$key] -cne [string]$receipt[$key]) { throw 'Delivery receipt scope does not match this job.' }
            }
            if (-not $ExplicitRetry) { return $saved }
            $receipt = $saved
            $receipt.DeliveryMode = $policy; $receipt.ReviewOnly = $ReviewOnly
        }
        $receipt.UpdatedAtUtc = [DateTimeOffset]::UtcNow.ToString('o')
        Write-AutopilotDocumentReceipt -Path $receiptPath -Receipt $receipt
        if ($receipt.PdfPath) {
            $info = Get-AutopilotDocumentPdfInfo -Path $receipt.PdfPath
            if ($info.SHA256 -cne $receipt.OutputSHA256) { throw 'Retained published PDF differs from its durable receipt.' }
        }
        else {
            $published = Publish-AutopilotDocumentPdf -Job $Job -DocumentType $DocumentType -SourcePath $PdfPath
            $receipt.PdfPath = $published.Path; $receipt.OutputSHA256 = $published.SHA256
        }
        $receipt.Status = 'Generated'; $receipt.ErrorCode = ''; $receipt.Message = ''
        Write-AutopilotDocumentReceipt -Path $receiptPath -Receipt $receipt
        $requestPrint = $policy -eq 'AutoPrint' -or ($policy -eq 'GenerateAndAsk' -and $PrintApproved)
        if ($requestPrint -and ($ReviewOnly -or ($Job['Mode'] -eq 'Demo' -and -not $AllowDemoPrint))) {
            $receipt.Message = 'Draft/Demo PDF retained; printing is prohibited.'
            $receipt.DeliveryState = 'NotRequested'
        }
        elseif ($policy -eq 'GenerateOnly') { $receipt.DeliveryState = 'NotRequested' }
        elseif ($policy -eq 'GenerateAndAsk' -and -not $PrintApproved) {
            $receipt.Status = 'AwaitingPrintApproval'; $receipt.DeliveryState = 'NotRequested'
        }
        else {
            $capability = & $Adapter['Probe'] $receipt.PdfPath $requestPrint
            $available = if ($requestPrint) { $capability['CanPrint'] } else { $capability['CanOpen'] }
            if ($available -isnot [bool] -or -not $available) {
                $receipt.Status = 'DeliveryUnavailable'; $receipt.ErrorCode = 'PdfHandlerUnavailable'
                $receipt.Message = 'PDF retained; the required PDF handler/default printer is unavailable.'
            }
            else {
                $receipt.AttemptCount = [int]$receipt.AttemptCount + 1
                $receipt.DeliveryState = 'Requested'
                if ($requestPrint) {
                    $receipt.PrintState = 'Requested'; $receipt.PrintIntentAtUtc = [DateTimeOffset]::UtcNow.ToString('o')
                    $receipt.DefaultPrinter = [string]$capability['DefaultPrinter']
                }
                else { $receipt.OpenIntentAtUtc = [DateTimeOffset]::UtcNow.ToString('o') }
                Write-AutopilotDocumentReceipt -Path $receiptPath -Receipt $receipt
                try {
                    if ($requestPrint) { $null = & $Adapter['Print'] $receipt.PdfPath; $receipt.Status = 'PrintRequested' }
                    else { $null = & $Adapter['Open'] $receipt.PdfPath; $receipt.Status = 'OpenRequested' }
                    $receipt.DeliveryState = $receipt.Status
                }
                catch {
                    $receipt.Status = 'DeliveryUncertain'; $receipt.DeliveryState = 'Uncertain'
                    if ($requestPrint) { $receipt.PrintState = 'Uncertain' }
                    $receipt.ErrorCode = 'DeliveryUncertain'; $receipt.Message = 'Delivery was attempted; do not automatically replay it.'
                }
            }
        }
        $receipt.UpdatedAtUtc = [DateTimeOffset]::UtcNow.ToString('o')
        try { Write-AutopilotDocumentReceipt -Path $receiptPath -Receipt $receipt }
        catch {
            $receipt.Status = 'ReceiptUncertain'; $receipt.DeliveryState = 'Uncertain'
            if ($receipt.PrintState -eq 'Requested') { $receipt.PrintState = 'Uncertain' }
            $receipt.ErrorCode = 'OutcomeReceiptFailed'; $receipt.Message = 'Outcome persistence failed; retained intent prevents automatic replay.'
        }
        return $receipt
    }
    finally { $lease.Dispose() }
}