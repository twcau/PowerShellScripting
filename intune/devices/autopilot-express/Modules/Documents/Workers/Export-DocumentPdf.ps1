<#
.SYNOPSIS
    Fixed data-only Desktop STA worker for explicit interactive Word export.
.DESCRIPTION
    Does not load Open XML/ZXing, print, open a viewer or contact Graph. The parent
    enforces the deadline and independently verifies owned process cleanup.
.FILECREATED
    2026-10-24
.FILELASTUPDATED
    2026-10-24
#>
#Requires -Version 5.1
[CmdletBinding()]
param([Parameter(Mandatory)][ValidateNotNullOrEmpty()][string]$RequestPath)
$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
[Console]::OutputEncoding = [Text.UTF8Encoding]::new($false)
$jobId = ''; $exportResult = [ordered]@{ Status = 'Failed'; Diagnostic = ''; Cleanup = 'NotStarted'; WordLaunchAttempted = $false; Pdf = $null }
try {
    if ($PSVersionTable.PSEdition -ne 'Desktop' -or [Threading.Thread]::CurrentThread.ApartmentState -ne 'STA') { throw 'PDF export requires the fixed Desktop STA worker.' }
    $root = Split-Path -Parent $PSScriptRoot
    Import-Module (Join-Path $root 'AutopilotExpress.Documents.psd1') -Force -ErrorAction Stop
    $file = Get-Item -LiteralPath $RequestPath -Force -ErrorAction Stop
    if ($file.Length -gt 16384 -or ($file.Attributes -band [IO.FileAttributes]::ReparsePoint)) { throw 'Invalid PDF request file.' }
    $value = Get-Content -LiteralPath $RequestPath -Raw -Encoding UTF8 -ErrorAction Stop | ConvertFrom-Json -ErrorAction Stop
    $jobId = [string]$value.JobId
    $exportResult = & (Get-Module AutopilotExpress.Documents) {
        param($Value)
        $request = ConvertTo-AutopilotDocumentDictionary -Value $Value
        Invoke-AutopilotDocumentWordExport -Request $request
    } $value
    $status = 'Failed'; if ($exportResult.Status -eq 'Exported') { $status = 'Passed' }
    [ordered]@{ SchemaVersion = 1; JobId = $jobId; WorkerPid = $PID; Status = $status; Result = $exportResult } | ConvertTo-Json -Depth 8 -Compress
    if ($status -ne 'Passed') { exit 1 }
}
catch {
    $exportResult.Diagnostic = $_.Exception.Message
    [ordered]@{ SchemaVersion = 1; JobId = $jobId; WorkerPid = $PID; Status = 'Failed'; Result = $exportResult } | ConvertTo-Json -Depth 8 -Compress
    exit 1
}