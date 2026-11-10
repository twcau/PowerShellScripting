<#
.SYNOPSIS
    Coordinate opt-in document prerequisites without touching the core workflow.
.DESCRIPTION
    Uses resolved DOCGEN settings, local cache verification/acquisition and the
    isolated synthetic worker. No preferences, tenant data, Word or printer writes.
.FILECREATED
    2026-10-24
.FILELASTUPDATED
    2026-10-24
#>
function Test-AutopilotDocumentPrerequisite {
    <#
    .SYNOPSIS
        Return immediately when outputs are off; never install Office or Graph.
    .PARAMETER Settings
        Resolved settings contract from Resolve-AutopilotDocumentSettings.
    .PARAMETER Consent
        Explicit acquisition decision; default prompts only for an enabled feature.
    .PARAMETER NoPrompts
        Return ConsentRequired rather than inventing consent when packages are absent.
    .PARAMETER ArchiveDirectory
        Optional already-approved offline package directory, still independently verified.
    .OUTPUTS
        Status/Ready/Diagnostic plus host, acquisition and library evidence. Ready
        means library tests and Word registration only, not activation or PDF proof.
    #>
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'None')]
    [OutputType([System.Collections.Specialized.OrderedDictionary])]
    param(
        [Parameter(Mandatory)][ValidateNotNullOrEmpty()][System.Collections.IDictionary]$Settings,
        [ValidateSet('NotGranted', 'Approved', 'Declined')][string]$Consent = 'NotGranted',
        [switch]$NoPrompts,
        [string]$ArchiveDirectory
    )
    $result = [ordered]@{ Status = 'Disabled'; Ready = $false; Diagnostic = ''; HostCapability = $null; Acquisition = $null; Libraries = $null }
    try {
        $values = $Settings['Values']
        if ($null -eq $values -or $values['BirthCertificateEnabled'] -isnot [bool] -or $values['ChecklistEnabled'] -isnot [bool]) { throw 'Resolved Boolean document settings are required.' }
        $birthActive = $values['BirthCertificateEnabled'] -and $values['BirthCertificateMode'] -ne 'Disabled'
        $checklistActive = $values['ChecklistEnabled'] -and $values['ChecklistMode'] -ne 'Disabled'
        if (-not $birthActive -and -not $checklistActive) { return $result }
        if (-not $PSCmdlet.ShouldProcess('Optional document prerequisites', 'Check host, acquire approved libraries and run isolated probes')) { $result.Status = 'WhatIf'; return $result }
        $result.HostCapability = Get-AutopilotDocumentHostCapability
        if (-not $result.HostCapability.WorkerAvailable) { $result.Status = 'WorkerUnavailable'; $result.Diagnostic = 'Install Windows PowerShell 5.1 and .NET Framework 4.8 before enabling document output.'; return $result }
        if (-not $result.HostCapability.WordRegistrationDetected) { $result.Status = 'WordUnavailable'; $result.Diagnostic = 'Desktop Word registration was not found. Repair/install licensed Desktop Word separately; core dispatch remains available.'; return $result }
        $root = Join-Path $values['LocalRoot'] 'Dependencies'
        $result.Acquisition = Install-AutopilotDocumentDependencyBundle -DependencyRoot $root -Consent $Consent -NoPrompts:$NoPrompts -ArchiveDirectory $ArchiveDirectory
        if ($result.Acquisition.Status -notin @('Verified', 'InstalledVerified')) { $result.Status = $result.Acquisition.Status; $result.Diagnostic = $result.Acquisition.Diagnostic; return $result }
        $result.Libraries = Invoke-AutopilotDocumentDependencySelfTest -DependencyRoot $root -TimeoutSeconds $values['WorkerTimeoutSeconds']
        $result.Ready = $result.Libraries.Ready; $result.Status = $result.Libraries.Status; $result.Diagnostic = $result.Libraries.Diagnostic
    }
    catch {
        $detail = [string]$_.Exception.Message
        $result.Status = 'Failed'
        $result.Diagnostic = ('Document prerequisites failed: {0}' -f [regex]::Replace($detail.Substring(0, [Math]::Min(2048, $detail.Length)), '[\x00-\x1F\x7F]+', ' ').Trim())
    }
    return $result
}