<#
.SYNOPSIS
    Execute a detached local document job in one isolated Desktop STA child.
.DESCRIPTION
    Loads verified document libraries only here. Serialises Word jobs per Windows
    user, populates copied templates, exports owned DOCX files and applies durable
    independent delivery policies. No Graph, prompts or operational record writes.
.FILECREATED
    2026-10-24
.FILELASTUPDATED
    2026-10-29
#>
#Requires -Version 5.1
[CmdletBinding()]
param([Parameter(Mandatory)][ValidateNotNullOrEmpty()][string]$RequestPath, [switch]$Prepare)
$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
[Console]::OutputEncoding = [Text.UTF8Encoding]::new($false)
$mutex = $null; $ownsMutex = $false
try {
    if ($PSVersionTable.PSEdition -ne 'Desktop' -or [Threading.Thread]::CurrentThread.ApartmentState -ne 'STA') { throw 'Document jobs require Desktop STA.' }
    $root = Split-Path -Parent $PSScriptRoot
    Import-Module (Join-Path $root 'AutopilotExpress.Documents.psd1') -Force -ErrorAction Stop
    if ($Prepare) {
        $preparation = Get-Content -LiteralPath $RequestPath -Raw -Encoding UTF8 | ConvertFrom-Json -ErrorAction Stop
        & (Get-Module AutopilotExpress.Documents) {
            param($Preparation)
            $verified = Test-AutopilotDocumentDependencyBundle -DependencyRoot $Preparation.DependencyRoot
            if (-not $verified.Valid) { throw 'Preparation dependencies are not verified.' }
            Add-Type -AssemblyName WindowsBase, System.Drawing, System.IO.Compression -ErrorAction Stop
            foreach ($package in (Get-AutopilotDocumentDependencyManifest).Packages) {
                $path = Join-Path $verified.BundlePath $package.FileName
                if ([Reflection.Assembly]::LoadFrom($path).Location -ine $path) { throw 'Preparation assembly location drift.' }
            }
            $failures = @()
            foreach ($documentProfile in $Preparation.Profiles) {
                try {
                    $mapping = Get-AutopilotDocumentTemplateProfile -DocumentType $documentProfile.DocumentType
                    $fields = @{}
                    foreach ($field in $mapping.RequiredFields) { $fields[$field] = 'Preparation' }
                    $job = @{ SchemaVersion = 1; Fields = $fields; Steps = @{}; Mode = 'Demo'; IsAdministrativeOverride = $false; AssignedUserRequired = $false }
                    $null = New-AutopilotDocumentCopy -PrepareOnly -Request @{ SchemaVersion = 1; Job = $job; Profile = $mapping; ReviewOnly = $true; TemplatePath = Join-Path $Preparation.Directory ('{0}.template.docx' -f $documentProfile.DocumentType); OutputPath = Join-Path $Preparation.Directory ('{0}.prepared.docx' -f $documentProfile.DocumentType) }
                }
                catch { $failures += '{0}: {1}' -f $documentProfile.DocumentType, $_.Exception.Message }
            }
            $script:PreparedWordAdapter = New-AutopilotDocumentWordAdapter
            $identity = & $script:PreparedWordAdapter.Start
            $ownership = @{ SchemaVersion = 1; JobId = $Preparation.PreparationId; WorkerPid = $PID; WordProcessId = $identity.WordProcessId; StartTimeUtcTicks = $identity.StartTimeUtcTicks; ProcessName = 'WINWORD' }
            [IO.File]::WriteAllText((Join-Path $Preparation.Directory 'WordOwner.json'), ($ownership | ConvertTo-Json -Compress), [Text.UTF8Encoding]::new($false))
            foreach ($documentProfile in $Preparation.Profiles) {
                try { & $script:PreparedWordAdapter.Open (Join-Path $Preparation.Directory ('{0}.template.docx' -f $documentProfile.DocumentType)) }
                catch { $failures += '{0}: Word preparation failed: {1}' -f $documentProfile.DocumentType, $_.Exception.Message }
                finally { & $script:PreparedWordAdapter.CloseDocument }
            }
            $readyPath = Join-Path $Preparation.Directory 'Ready.json'
            [IO.File]::WriteAllText(($readyPath + '.pending'), (@{ SchemaVersion = 1; PreparationId = $Preparation.PreparationId; WorkerPid = $PID; Failures = $failures } | ConvertTo-Json -Compress), [Text.UTF8Encoding]::new($false))
            [IO.File]::Move(($readyPath + '.pending'), $readyPath)
        } $preparation
        $command = [Console]::In.ReadLine()
        if ($command -ceq 'Stop' -or [string]::IsNullOrWhiteSpace($command)) { return }
        $RequestPath = $command
    }
    $file = Get-Item -LiteralPath $RequestPath -Force -ErrorAction Stop
    if ($file.Length -gt 1048576 -or ($file.Attributes -band [IO.FileAttributes]::ReparsePoint)) { throw 'Invalid detached document job file.' }
    $decoded = Get-Content -LiteralPath $RequestPath -Raw -Encoding UTF8 | ConvertFrom-Json -ErrorAction Stop
    $result = & (Get-Module AutopilotExpress.Documents) {
        param($Decoded)
        $request = ConvertTo-AutopilotDocumentDictionary -Value $Decoded
        $job = $request['Job']; $directory = Resolve-AutopilotDocumentLocalPath -Path $request['JobDirectory']
        if ($request['SchemaVersion'] -ne 1 -or $job['SchemaVersion'] -ne 1 -or -not (Test-AutopilotDocumentJobDirectory -Directory $directory -JobId $job['JobId'])) { throw 'Invalid job directory/identity.' }
        $verified = Test-AutopilotDocumentDependencyBundle -DependencyRoot $request['DependencyRoot']
        if (-not $verified.Valid) { throw 'Document dependencies are not verified.' }
        Add-Type -AssemblyName WindowsBase, System.Drawing, System.IO.Compression -ErrorAction Stop
        foreach ($package in (Get-AutopilotDocumentDependencyManifest).Packages) {
            $path = Join-Path $verified.BundlePath $package.FileName
            $assembly = [Reflection.Assembly]::LoadFrom($path)
            if ($assembly.Location -ine $path) { throw 'Document assembly location drift.' }
        }
        $outputs = [Collections.Generic.List[object]]::new()
        $deliveries = [Collections.Generic.List[object]]::new()
        $receiptUpdates = [Collections.Generic.List[object]]::new()
        $docxNames = [Collections.Generic.List[string]]::new()
        # Requests without the key (older retained jobs) keep the guarded behaviour.
        # False lifts the unapproved-profile DRAFT/print block and the Demo print block.
        if ($request.Contains('EnforceDocumentGuards') -and $request['EnforceDocumentGuards'] -isnot [bool]) { throw 'Document guard enforcement must be Boolean.' }
        $enforceGuards = -not $request.Contains('EnforceDocumentGuards') -or $request['EnforceDocumentGuards']
        $wordAdapter = if (Get-Variable -Name PreparedWordAdapter -Scope Script -ErrorAction SilentlyContinue) { $script:PreparedWordAdapter } else { New-AutopilotDocumentWordAdapter }
        try {
        foreach ($documentProfile in $job['Profiles']) {
            $type = [string]$documentProfile['DocumentType']
            $phaseTimer = [Diagnostics.Stopwatch]::StartNew()
            $timings = [ordered]@{ PopulationMilliseconds = 0L; WordExportMilliseconds = 0L; DeliveryMilliseconds = 0L }
            $exportResult = $null
            $populationResult = $null
            try {
                if ($type -cnotin @('BirthCertificate','Checklist')) { throw 'Unknown job profile.' }
                $mapping = Get-AutopilotDocumentTemplateProfile -DocumentType $type
                $review = ($enforceGuards -and -not $mapping.ApprovedForLive) -or [bool]$request['ReviewOnly']
                $docxName = Get-AutopilotDocumentOutputName -Job $job -DocumentType $type -Extension docx -OccupiedFileNames $docxNames.ToArray()
                $docxNames.Add($docxName)
                $receiptPath = Join-Path $directory ('{0}-{1}.receipt.json' -f $job['JobId'], $type)
                if (Test-Path -LiteralPath $receiptPath) {
                    $receiptFile = Get-Item -LiteralPath $receiptPath -Force
                    if ($receiptFile.Length -gt 65536 -or ($receiptFile.Attributes -band [IO.FileAttributes]::ReparsePoint)) { throw 'Unsafe retained delivery receipt.' }
                    $savedReceipt = ConvertTo-AutopilotDocumentDictionary -Value (Get-Content -LiteralPath $receiptPath -Raw -Encoding UTF8 | ConvertFrom-Json -ErrorAction Stop)
                    if ($savedReceipt['PdfPath']) {
                        $retainedReview = $review -or $savedReceipt['ReviewOnly'] -isnot [bool] -or $savedReceipt['ReviewOnly']
                        $deliveries.Add(@{ DocumentType = $type; PdfPath = $savedReceipt['PdfPath']; Review = $retainedReview; Population = $null; Timings = $timings; ReceiptPath = $receiptPath })
                        continue
                    }
                }
                $docx = Join-Path $directory $docxName
                if ((Test-Path -LiteralPath $docx) -and -not $request['ExplicitRetry']) { throw 'Named DOCX already exists; an explicit document-only retry is required.' }
                if (-not (Test-Path -LiteralPath $docx)) {
                    $population = @{ SchemaVersion = 1; Job = $job; Profile = $mapping; ReviewOnly = $review; EnforceDocumentGuards = $enforceGuards; TemplatePath = Join-Path $directory ('{0}.template.docx' -f $type); OutputPath = $docx }
                    $populationResult = New-AutopilotDocumentCopy -Request $population
                    $timings.PopulationMilliseconds = $phaseTimer.ElapsedMilliseconds
                }
                $pdf = Join-Path $directory ('{0}.exported.pdf' -f $type)
                if (-not (Test-Path -LiteralPath $pdf)) {
                    $export = @{ SchemaVersion = 1; JobId = $job['JobId']; JobDirectory = $directory; SourcePath = $docx; SourceSHA256 = (Get-FileHash -LiteralPath $docx -Algorithm SHA256).Hash; PendingPdfPath = $pdf; OwnershipPath = Join-Path $directory 'WordOwner.json' }
                    $export.ExpectedPageCount = if ($type -eq 'BirthCertificate') { 2 } else { 0 }
                    $phaseTimer.Restart()
                    $exportResult = Invoke-AutopilotDocumentWordExport -Request $export -Adapter $wordAdapter -KeepWordOpen
                    $timings.WordExportMilliseconds = $phaseTimer.ElapsedMilliseconds
                    $timings['WordDetail'] = $exportResult.Timings
                    if ($exportResult.Status -ne 'Exported' -or $exportResult.Cleanup -ne 'Complete') { throw ('PDF export failed: {0}' -f $exportResult.Diagnostic) }
                }
                $deliveries.Add(@{ DocumentType = $type; PdfPath = $pdf; Review = $review; Population = $populationResult; Timings = $timings; ReceiptPath = $receiptPath })
            }
            catch { $outputs.Add([ordered]@{ DocumentType = $type; Status = 'Failed'; Message = $_.Exception.Message; Cleanup = if ($null -ne $exportResult) { $exportResult.Cleanup } else { 'NotStarted' } }) }
        }
        foreach ($delivery in $deliveries) {
            try {
                $phaseTimer.Restart()
                $deliveryResult = Invoke-AutopilotDocumentDelivery -Job $job -DocumentType $delivery.DocumentType -PdfPath $delivery.PdfPath -ReceiptDirectory $directory -ReviewOnly:$delivery.Review -PrintApproved:([bool]$request['PrintApproved']) -ExplicitRetry:([bool]$request['ExplicitRetry']) -AllowDemoPrint:(-not $enforceGuards)
                $delivery.Timings.DeliveryMilliseconds = $phaseTimer.ElapsedMilliseconds
                $deliveryResult['Timings'] = $delivery.Timings
                if ($null -ne $delivery.Population) {
                    $delivery.Timings['PopulationDetail'] = $delivery.Population.Timings
                    $deliveryResult['TemplateFingerprint'] = $delivery.Population.TemplateSHA256
                    $deliveryResult['TemplateRevalidated'] = $delivery.Population.TemplateChanged
                    $deliveryResult['ValidationWarnings'] = @($delivery.Population.ValidationWarnings)
                    $receiptUpdates.Add(@{ Path = $delivery.ReceiptPath; Receipt = $deliveryResult })
                }
                $outputs.Add($deliveryResult)
            }
            catch { $outputs.Add([ordered]@{ DocumentType = $delivery.DocumentType; Status = 'Failed'; Message = $_.Exception.Message; Cleanup = 'Complete' }) }
        }
        foreach ($update in $receiptUpdates) {
            try { Write-AutopilotDocumentReceipt -Path $update.Path -Receipt $update.Receipt }
            catch { $update.Receipt['Message'] = 'Delivery outcome is saved; supplementary timing/template metadata could not be updated.' }
        }
        }
        finally {
            try { & $wordAdapter.Close }
            catch {
                foreach ($output in $outputs) { $output['Status'] = 'Failed'; $output['Cleanup'] = 'Uncertain'; $output['Message'] = 'Owned Word shutdown was uncertain; retain this job for diagnosis.' }
                if (-not $outputs.Count) { throw }
            }
        }
        return $outputs.ToArray()
    } $decoded
    $sid = [Security.Principal.WindowsIdentity]::GetCurrent().User.Value
    [ordered]@{ SchemaVersion = 1; WorkerPid = $PID; JobId = [string]$decoded.Job.JobId; Status = 'Completed'; Results = @($result); ActorSid = $sid } | ConvertTo-Json -Depth 12 -Compress
}
catch {
    [ordered]@{ SchemaVersion = 1; WorkerPid = $PID; Status = 'Failed'; Diagnostic = $_.Exception.Message } | ConvertTo-Json -Compress
    exit 1
}
finally {
    $loaded = Get-Module AutopilotExpress.Documents
    if ($null -ne $loaded) { & $loaded { if (Get-Variable -Name PreparedWordAdapter -Scope Script -ErrorAction SilentlyContinue) { & $script:PreparedWordAdapter.Close } } }
    if ($ownsMutex) { $mutex.ReleaseMutex() }; if ($null -ne $mutex) { $mutex.Dispose() }
}