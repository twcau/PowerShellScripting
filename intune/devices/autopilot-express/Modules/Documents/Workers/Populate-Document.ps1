<#
.SYNOPSIS
    Fixed isolated structural DOCX/Code 128 worker; never starts Word.
.DESCRIPTION
    Windows PowerShell 5.1/.NET 4.8 only. Verifies the approved bundle before loading
    it; accepts bounded JSON data, not executable configuration or script arguments.
.FILECREATED
    2026-10-24
.FILELASTUPDATED
    2026-10-24
#>
#Requires -Version 5.1
[CmdletBinding()]
param(
    [Parameter(Mandatory)][ValidateNotNullOrEmpty()][string]$DependencyRoot,
    [Parameter(Mandatory)][ValidateNotNullOrEmpty()][string]$RequestPath
)
$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
try {
    if ($PSVersionTable.PSEdition -ne 'Desktop') { throw 'The document worker requires Desktop PowerShell.' }
    $root = Split-Path -Parent $PSScriptRoot
    Import-Module (Join-Path $root 'AutopilotExpress.Documents.psd1') -Force -ErrorAction Stop
    $verified = Test-AutopilotDocumentDependencyBundle -DependencyRoot $DependencyRoot
    if (-not $verified.Valid) { throw 'Document dependencies are not verified.' }
    Add-Type -AssemblyName WindowsBase, System.Drawing, System.IO.Compression -ErrorAction Stop
    foreach ($package in (Get-AutopilotDocumentDependencyManifest).Packages) {
        if (@([AppDomain]::CurrentDomain.GetAssemblies() | Where-Object { $_.GetName().Name -eq [IO.Path]::GetFileNameWithoutExtension($package.FileName) }).Count) { throw 'Document assembly unexpectedly preloaded.' }
        $path = Join-Path $verified.BundlePath $package.FileName
        $loaded = [Reflection.Assembly]::LoadFrom($path)
        if ($loaded.Location -ine $path) { throw 'Document dependency location drift.' }
    }
    $file = Get-Item -LiteralPath $RequestPath -Force -ErrorAction Stop
    if ($file.Length -gt 1048576 -or ($file.Attributes -band [IO.FileAttributes]::ReparsePoint)) { throw 'Invalid structural document request file.' }
    $value = Get-Content -LiteralPath $RequestPath -Raw -Encoding UTF8 -ErrorAction Stop | ConvertFrom-Json -ErrorAction Stop
    $result = & (Get-Module AutopilotExpress.Documents) {
        param($Value)
        $request = ConvertTo-AutopilotDocumentDictionary -Value $Value
        New-AutopilotDocumentCopy -Request $request
    } $value
    [ordered]@{ SchemaVersion = 1; Status = 'Passed'; WorkerPid = $PID; Result = $result } | ConvertTo-Json -Depth 8 -Compress
}
catch {
    [ordered]@{ SchemaVersion = 1; Status = 'Failed'; WorkerPid = $PID; Diagnostic = $_.Exception.Message } | ConvertTo-Json -Compress
    exit 1
}