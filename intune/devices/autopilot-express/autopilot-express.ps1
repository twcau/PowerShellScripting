# <!-- omit from toc -->
# .SYNOPSIS
#    Command line framework for streamlining Intune Autopilot device preparation and tracking.
# .DESCRIPTION
#    This script provides an accessible, menu-driven UI for technicians performing Autopilot builds.
#    It captures device metadata, tracks progress across Autopilot steps, and implements selected live
#    Microsoft Graph / Intune / Entra ID actions while keeping tenant-specific or uncertain flows guided.
# .FILECREATED     2025-12-01
# .FILELASTUPDATED 2026-05-02
# .AUTHOR          Michael Harris (Framework generated collaboratively)
# .VERSION         0.1.0-framework
# .LICENSE         Refer to root LICENSE (MIT)
# .DOCUMENTATION   README.md, .website/ (canonical)
# .ACCESSIBILITY   All prompts support screen readers (no colour-only cues)
# .NOTES
#    Root-resolution pattern, logging, validation, and menu structure follow project standards.
#    EN-AU spelling is used for documentation and comments.
#
# ==============================================================================================
# Targeted ScriptAnalyzer suppressions for intentional interactive CLI and internal helper patterns.
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingWriteHost', '', Justification = 'Autopilot Express is an interactive technician CLI and intentionally writes prompts and menu output directly to the host.')]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseBOMForUnicodeEncodedFile', '', Justification = 'This repository keeps PowerShell source in UTF-8 without BOM.')]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseSingularNouns', '', Scope = 'Function', Target = 'Get-UserDeviceRecords', Justification = 'Internal helper returns a collection by design.')]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseSingularNouns', '', Scope = 'Function', Target = 'Write-UserDeviceRecords', Justification = 'Internal helper persists a collection by design.')]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseSingularNouns', '', Scope = 'Function', Target = 'Get-UserStats', Justification = 'Interactive report helper intentionally summarises plural device stats.')]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseSingularNouns', '', Scope = 'Function', Target = 'Show-EnhancementsQuestions', Justification = 'Interactive helper intentionally presents multiple enhancement questions.')]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseSingularNouns', '', Scope = 'Function', Target = 'Get-ConfiguredTechnicianPrefixes', Justification = 'Internal helper returns the configured prefix collection.')]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseSingularNouns', '', Scope = 'Function', Target = 'Get-ConfiguredGraphScopes', Justification = 'Internal helper returns the configured Graph scope collection.')]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseSingularNouns', '', Scope = 'Function', Target = 'Get-ConfiguredGraphModules', Justification = 'Internal helper returns the configured module collection.')]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseSingularNouns', '', Scope = 'Function', Target = 'Get-EnabledManifestSteps', Justification = 'Internal helper returns the enabled manifest-step collection.')]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseSingularNouns', '', Scope = 'Function', Target = 'Initialize-AutopilotExpressDefinitions', Justification = 'Initialisation intentionally loads multiple external definitions.')]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseSingularNouns', '', Scope = 'Function', Target = 'Import-RequiredGraphModules', Justification = 'Internal helper imports multiple Graph modules by design.')]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseSingularNouns', '', Scope = 'Function', Target = 'Test-DirectoryUserMatchesConfiguredPrefixes', Justification = 'Internal validation intentionally checks multiple configured prefixes.')]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseSingularNouns', '', Scope = 'Function', Target = 'Get-EligibleDirectoryUsers', Justification = 'Internal helper returns a filtered user collection by design.')]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseSingularNouns', '', Scope = 'Function', Target = 'Get-RecentUsers', Justification = 'Internal helper returns the recent-user collection by design.')]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseSingularNouns', '', Scope = 'Function', Target = 'Save-RecentUsers', Justification = 'Internal helper persists a recent-user collection by design.')]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseSingularNouns', '', Scope = 'Function', Target = 'Search-DemoDirectoryUsers', Justification = 'Internal search helper returns multiple possible user matches by design.')]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseSingularNouns', '', Scope = 'Function', Target = 'Search-LiveDirectoryUsers', Justification = 'Internal search helper returns multiple possible user matches by design.')]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseSingularNouns', '', Scope = 'Function', Target = 'Select-UserFromResults', Justification = 'Interactive selection helper intentionally presents multiple user results.')]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseSingularNouns', '', Scope = 'Function', Target = 'Get-LiveManagedDevicePrimaryUsers', Justification = 'Internal helper returns multiple managed-device primary-user relationships when present.')]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseSingularNouns', '', Scope = 'Function', Target = 'Invoke-StepRetryFailedApps', Justification = 'Manifest step intentionally retries multiple failed applications.')]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseSingularNouns', '', Scope = 'Function', Target = 'Sync-BenchRecords', Justification = 'Internal helper synchronises multiple bench-backed records by design.')]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseSingularNouns', '', Scope = 'Function', Target = 'Select-DeviceFromRecords', Justification = 'Interactive selection helper intentionally presents multiple device records.')]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '', Scope = 'Function', Target = 'New-DeviceRecordObject', Justification = 'Internal object factory only constructs in-memory state for this interactive script.')]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '', Scope = 'Function', Target = 'New-ParentDirectory', Justification = 'Internal file helper is not exposed as a user-invoked cmdlet.')]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '', Scope = 'Function', Target = 'Reset-CurrentSessionState', Justification = 'Internal session-reset helper is driven by explicit menu confirmation rather than -WhatIf semantics.')]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '', Scope = 'Function', Target = 'Update-MasterAuditLedger', Justification = 'Internal ledger writer is called from controlled persistence paths only.')]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '', Scope = 'Function', Target = 'New-DeviceLock', Justification = 'Internal lock helper is not exposed as a user-invoked cmdlet.')]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '', Scope = 'Function', Target = 'Remove-DeviceLock', Justification = 'Internal lock helper is not exposed as a user-invoked cmdlet.')]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '', Scope = 'Function', Target = 'Start-NewDeviceWorkflow', Justification = 'This interactive workflow is already confirmation-driven and not intended for cmdlet-style WhatIf support.')]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '', Scope = 'Function', Target = 'Update-DeviceStatus', Justification = 'This interactive workflow is already confirmation-driven and not intended for cmdlet-style WhatIf support.')]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '', Scope = 'Function', Target = 'New-OperationResult', Justification = 'Internal result factory only constructs in-memory objects.')]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '', Scope = 'Function', Target = 'New-BuildBench', Justification = 'This internal workflow initialiser is menu-driven and not intended for cmdlet-style WhatIf support.')]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '', Scope = 'Function', Target = 'Remove-DeviceFromBenchPosition', Justification = 'This internal bench helper is menu-driven and not intended for cmdlet-style WhatIf support.')]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', '', Scope = 'Function', Target = 'Invoke-StepValidateDeploymentProfile', Justification = 'Manifest step handlers share a standard signature even when a specific step does not currently need every argument.')]
param(
    [ValidateSet('Live', 'Demo')][string]$Mode = 'Live'
)

# ==============================================================================================
# MENU STRUCTURE (ASCII, Accessible) - Draft
# (Annotations reflect intent; several Graph-backed functions are implemented while some flows remain guided.)
#
# Main Menu:
#   1. Start work on a new device        (Capture metadata, confirm site, assign group tag, add to groups)
#   2. Autopilot the device              (Sub-menu: reseal prep, shared device, assign primary user, apps check, fix app, manufacturer update)
#   3. What's outstanding for a device   (Query by Serial or Configuration Item; show progress, suggest next steps)
#   4. Maintain my device list           (Update status: new | in-progress | completed | removed)
#   5. My stats and progress             (Per-user and roll-up stats; site/device type breakdown)
#   6. Enhancements & questions          (Show potential future ideas; gather clarification needs)
#   7. Change current site               (Select a different site mid-run)
#   0. Exit                              (Clean shutdown, save state)
#
# Autopilot Sub-Menu (Option 2):
#   A. Prepare for reseal                (Future: Trigger device sync, ensure apps baseline)
#   B. Shared device provisioning        (Future: Add to specific Entra groups, enforce shared profile policies)
#   C. Assign primary user               (Future: Fuzzy search; validate managerial relationship if shared groups present)
#   D. Application check                 (Future: Graph DeviceManagedAppStatus + sync if stale)
#   E. Fix specific application          (Zenworks White file copy stub)
#   F. Manufacturer software update      (Invoke vendor CLI; confirm install)
#   R. Return to main menu               (Return w/o changes)
#
# ==============================================================================================
# GRAPH / INTUNE / ENTRA REQUIREMENTS (Implemented + Reference)
# PERMISSIONS (least privilege starting point; refine as implementation evolves):
#   Device Onboarding / Autopilot:
#     - Device.Read.All (Application) / Device.ReadWrite.All for tagging operations
#     - DeviceManagementServiceConfig.ReadWrite.All (manage Autopilot profiles & tags)
#     - DeviceManagementManagedDevices.Read.All (query device state, apps, sync)
#     - Group.ReadWrite.All (adding/removing device to support groups)
#     - User.Read.All + Directory.Read.All (primary user assignment, managerial checks)
#     - DeviceManagementConfiguration.Read.All (verify configuration policies) *Potential*
# GRAPH ENDPOINTS (illustrative):
#   List Autopilot devices:   GET https://graph.microsoft.com/beta/deviceManagement/windowsAutopilotDeviceIdentities
#   Get device by serial:     GET .../windowsAutopilotDeviceIdentities?$filter=serialNumber eq '{serial}'
#   Update group tag:         PATCH .../windowsAutopilotDeviceIdentities/{id} { "groupTag": "TAG" }
#   Remove Autopilot record:  DELETE .../windowsAutopilotDeviceIdentities/{id}
#   Get Entra device:         GET https://graph.microsoft.com/v1.0/devices?$filter=deviceId eq '{guid}'
#   Add device to group:      POST .../groups/{groupId}/members/$ref { "@odata.id": "https://graph.microsoft.com/v1.0/devices/{id}" }
#   List managed apps:        GET https://graph.microsoft.com/beta/deviceManagement/managedDevices/{id}/detectedApps
#   Trigger device sync:      POST .../managedDevices/{id}/syncDevice
#   Set primary user:         POST .../managedDevices('{id}')/users/$ref (raw Graph fallback; SDK has no writer)
#   Manufacturer updates:     Vendor-specific CLI (outside Graph) – ensure elevation & remote execution rights.
#
# SECURITY & AUDIT CONSIDERATIONS:
#   - All future API calls must implement retry, timeout (-TimeoutSec), logging of request correlation IDs.
#   - Handle 429 throttling via Retry-After headers.
#   - Avoid storing secrets locally; use Managed Identity or secure token cache approach.
#
# ==============================================================================================
# ROOT RESOLUTION (Robust) & ENV VAR SETUP
try {
    if (-not $env:PowerShellScriptingNewRoot) {
        $scriptDir = Split-Path -Parent $PSCommandPath
        # Traverse upwards until we find an anchor file (README.md | LICENSE | .git)
        $current = $scriptDir
        $maxDepth = 10
        for ($i = 0; $i -lt $maxDepth; $i++) {
            $anchorReadme = Test-Path (Join-Path $current 'README.md')
            $anchorLicense = Test-Path (Join-Path $current 'LICENSE')
            $anchorGit = Test-Path (Join-Path $current '.git')
            if ($anchorReadme -or $anchorLicense -or $anchorGit) { $env:PowerShellScriptingNewRoot = $current; break }
            $parent = Split-Path -Parent $current
            if ($parent -eq $current) { break }
            $current = $parent
        }
        if (-not $env:PowerShellScriptingNewRoot) { $env:PowerShellScriptingNewRoot = $scriptDir }
    }
}
catch {
    Write-Information -MessageData ('Failed to resolve project root: {0}' -f $_.Exception.Message) -InformationAction Continue
}

# LOGGING (Simple placeholder; project may have central logging module to leverage later)
function Write-AutopilotExpressLog {
    <#
		.SYNOPSIS
			Writes a timestamped message to console and (future) log file.
		.PARAMETER Message
			The message text.
		.PARAMETER Level
			Log level (INFO, WARN, ERROR, DEBUG)
	#>
    param(
        [Parameter(Mandatory)][string]$Message,
        [ValidateSet('INFO', 'WARN', 'ERROR', 'DEBUG')][string]$Level = 'INFO'
    )
    $ts = (Get-Date).ToString('yyyy-MM-dd HH:mm:ss')
    Write-Information -MessageData ('[{0}] [{1}] {2}' -f $ts, $Level, $Message) -InformationAction Continue
}

# CONFIGURATION TOGGLES & NOMENCLATURE
$Script:Config = [ordered]@{
    OrganisationName              = 'Example Health Network'
    Nomenclature                  = [ordered]@{ Serial = 'Serial'; ConfigItem = 'Configuration Item'; Site = 'Site'; DeviceType = 'Device Type'; GroupTag = 'Group Tag' }
    EnableSharedDeviceFlow        = $true
    EnablePrimaryUserAssignment   = $true
    EnableManufacturerUpdate      = $true
    EnableApplicationCheck        = $true
    EnableZenworksWhiteFix        = $true
    RequireManagerForSharedAssign = $true
    SupportAutopilotGroupAdd      = $true
    SupportAutopilotDeleteRecord  = $true
    DataFolderRelative            = 'data'
    UserDataFilePrefix            = 'autopilot-devices'
    DemoUserDataFilePrefix        = 'autopilot-devices-demo'
    RecentUsersFilePrefix         = 'autopilot-recent-users'
    DemoRecentUsersFilePrefix     = 'autopilot-recent-users-demo'
    BuildBenchFilePrefix          = 'build-bench'
    DemoBuildBenchFilePrefix      = 'build-bench-demo'
    ArchiveFolderRelative         = 'archive/autopilot-express'
    MasterAuditFileName           = 'autopilot-master-audit.json'
    RuntimeConfigFileName         = 'autopilot-express.runtime.json'
    ManifestFileName              = 'autopilot-express.manifest.json'
    ManufacturerUpdateCommand     = 'VendorUpdateTool.exe'
    ManufacturerUpdateArgs        = '--silent --acceptEula'
    MaxRetryAttempts              = 5
    RetryBackoffSeconds           = 3
    LockFolderRelative            = 'locks'
}

$Script:Runtime = [ordered]@{
    Mode            = $Mode
    IsDemoMode      = $Mode -eq 'Demo'
    ModeDisplayName = if ($Mode -eq 'Demo') { 'demo' } else { 'normal' }
}

$Script:RuntimeConfig = @{}
$Script:GraphSession = [ordered]@{
    Connected   = $false
    IsSimulated = $Script:Runtime.IsDemoMode
    Account     = ''
    DisplayName = ''
    UserId      = ''
    Scopes      = @()
}

$Script:Storage = [ordered]@{
    BasePath      = ''
    DataPath      = ''
    UsingFallback = $false
    Initialised   = $false
}

# HARD-CODED SITE LIST (Extendable)
$Script:Sites = @(
    [ordered]@{ Code = 'MI'; Name = 'Midland' }
    [ordered]@{ Code = 'MU'; Name = 'Murdoch' }
    [ordered]@{ Code = 'SU'; Name = 'Subiaco' }
    [ordered]@{ Code = 'GE'; Name = 'Geraldton' }
    [ordered]@{ Code = 'AL'; Name = 'Albany' }
)

# HARD-CODED DEVICE TYPES (Extendable)
$Script:DeviceTypes = @('Desktop', 'Laptop', 'WOW', 'NUC')

# STEP MANIFEST (loaded from JSON definition file)
$Script:StepManifest = @()

# ENHANCEMENT MANIFEST (drives dynamic enhancements list)
$Script:EnhancementManifest = @(
    [ordered]@{ Id = 1; Title = 'Concurrent device locking'; Description = 'Prevent duplicate work across technicians.'; Status = 'Planned' }
    [ordered]@{ Id = 2; Title = 'Service Management integration'; Description = 'Update ITIL CMDB with device build events.'; Status = 'Planned' }
    [ordered]@{ Id = 3; Title = 'Fuzzy user search + manager check'; Description = 'Assist primary user assignment, validate manager chain for shared.'; Status = 'Planned' }
    [ordered]@{ Id = 4; Title = 'Baseline policy compliance scan'; Description = 'Check devices for required policies before reseal.'; Status = 'Planned' }
    [ordered]@{ Id = 5; Title = 'Offline caching for field techs'; Description = 'Queue updates when offline, sync later.'; Status = 'Planned' }
    [ordered]@{ Id = 6; Title = 'Export CSV & HTML reports'; Description = 'One-click exports for management reporting.'; Status = 'Planned' }
    [ordered]@{ Id = 7; Title = 'Pester tests'; Description = 'Unit tests for each workflow path.'; Status = 'Planned' }
    [ordered]@{ Id = 8; Title = 'Localisation'; Description = 'Multi-language prompts and messages.'; Status = 'Planned' }
    [ordered]@{ Id = 9; Title = 'Telemetry dashboard'; Description = 'Optional Power BI ingestion for trend analysis.'; Status = 'Planned' }
    [ordered]@{ Id = 10; Title = 'Secure token cache & refresh'; Description = 'Hardened auth flow for Graph integration.'; Status = 'Planned' }
)

# DATA SCHEMA (Class for device tracking)
class AutopilotDeviceRecord {
    [string]$RecordId
    [string]$AutopilotDeviceId
    [string]$ManagedDeviceId
    [string]$AzureAdDeviceId
    [string]$IntuneDeviceName
    [string]$Serial
    [string]$EntraDeviceId
    [string]$ConfigItem
    [string]$SiteCode
    [string]$DeviceType
    [string]$GroupTag
    [string]$Status               # new | in-progress | completed | removed
    [hashtable]$Steps             # stepName => @{ Success = $true/$false; Timestamp = [DateTime]; Notes = 'string' }
    [DateTime]$StartedAt
    [string]$StartedBy
    [DateTime]$LastUpdatedAt
    [string]$LastUpdatedBy
    [DateTime]$CompletedAt
    [string]$CompletedBy
    [bool]$IsCompletionVerified
    [string]$TechnicianUserPrincipalName
    [string]$FinalPrimaryUserId
    [string]$FinalPrimaryUserPrincipalName
    [string]$FinalPrimaryUserDisplayName
    AutopilotDeviceRecord() {}
}

function Get-DefaultBuildBenchState {
    return [ordered]@{ Positions = @(); Active = $false; SiteCode = $null; DeviceType = $null; Faults = @() }
}

function ConvertTo-NormalisedValue {
    param($Value)
    if ($null -eq $Value) { return $null }
    if ($Value -is [hashtable]) {
        $normalisedMap = @{}
        foreach ($key in $Value.Keys) {
            $normalisedMap[$key] = ConvertTo-NormalisedValue -Value $Value[$key]
        }
        return $normalisedMap
    }
    if ($Value -is [System.Collections.IDictionary]) {
        $normalisedMap = @{}
        foreach ($entry in $Value.GetEnumerator()) {
            $normalisedMap[$entry.Key] = ConvertTo-NormalisedValue -Value $entry.Value
        }
        return $normalisedMap
    }
    if ($Value -is [pscustomobject]) {
        $normalisedMap = @{}
        foreach ($property in $Value.PSObject.Properties) {
            $normalisedMap[$property.Name] = ConvertTo-NormalisedValue -Value $property.Value
        }
        return $normalisedMap
    }
    if ($Value -is [System.Collections.IEnumerable] -and $Value -isnot [string]) {
        $items = @()
        foreach ($item in $Value) {
            $items += , (ConvertTo-NormalisedValue -Value $item)
        }
        return $items
    }
    return $Value
}

function ConvertTo-StepHashtable {
    param($Value)
    $convertedValue = ConvertTo-NormalisedValue -Value $Value
    if ($convertedValue -is [hashtable]) { return $convertedValue }
    return @{}
}

function New-DeviceRecordObject {
    param(
        [Parameter(Mandatory)][string]$Serial,
        [Parameter(Mandatory)][string]$ConfigItem,
        [string]$SiteCode,
        [string]$DeviceType,
        [string]$EntraDeviceId,
        [string]$GroupTag
    )
    $record = [AutopilotDeviceRecord]::new()
    $record.RecordId = [guid]::NewGuid().Guid
    $record.AutopilotDeviceId = ''
    $record.ManagedDeviceId = ''
    $record.AzureAdDeviceId = ''
    $record.IntuneDeviceName = ''
    $record.Serial = $Serial
    $record.EntraDeviceId = if ($EntraDeviceId) { $EntraDeviceId } else { '' }
    $record.ConfigItem = $ConfigItem
    $record.SiteCode = $SiteCode
    $record.DeviceType = $DeviceType
    $record.GroupTag = $GroupTag
    $record.Status = 'new'
    $record.Steps = @{}
    $record.StartedAt = Get-Date
    $record.StartedBy = $env:USERNAME
    $record.LastUpdatedAt = $record.StartedAt
    $record.LastUpdatedBy = $record.StartedBy
    $record.CompletedAt = [DateTime]::MinValue
    $record.CompletedBy = ''
    $record.IsCompletionVerified = $false
    $record.TechnicianUserPrincipalName = ''
    $record.FinalPrimaryUserId = ''
    $record.FinalPrimaryUserPrincipalName = ''
    $record.FinalPrimaryUserDisplayName = ''
    return $record
}

# Safely append a device record to the records collection
function Add-DeviceRecord {
    param(
        [Parameter(Mandatory)][ref]$Records,
        [Parameter(Mandatory)][AutopilotDeviceRecord]$Record
    )
    if ($null -eq $Records.Value) {
        $Records.Value = [System.Collections.ArrayList]::new()
    }
    if ($Records.Value -isnot [System.Collections.ArrayList]) {
        $normalisedRecords = [System.Collections.ArrayList]::new()
        foreach ($existingRecord in @($Records.Value)) {
            [void]$normalisedRecords.Add($existingRecord)
        }
        $Records.Value = $normalisedRecords
    }
    [void]$Records.Value.Add($Record)
}

function Get-RepoStorageBasePath {
    return $env:PowerShellScriptingNewRoot
}

function Get-FallbackStorageBasePath {
    return Join-Path $env:LOCALAPPDATA 'PowerShellScriptingNew\AutopilotExpress'
}

function Test-DirectoryWritable {
    param([Parameter(Mandatory)][string]$Path)

    try {
        if (-not (Test-Path $Path)) {
            New-Item -ItemType Directory -Path $Path -Force -ErrorAction Stop | Out-Null
        }

        $probePath = Join-Path $Path ('.write-probe-{0}.tmp' -f [guid]::NewGuid().Guid)
        Set-Content -Path $probePath -Value 'probe' -Encoding utf8NoBOM -NoNewline -Force -ErrorAction SilentlyContinue
        if (-not (Test-Path $probePath)) { return $false }
        Remove-Item -Path $probePath -Force -ErrorAction Stop
        return $true
    }
    catch {
        return $false
    }
}

function Initialize-StorageLocation {
    if ($Script:Storage.Initialised) { return }

    $repoBasePath = Get-RepoStorageBasePath
    $repoDataPath = Join-Path $repoBasePath $Script:Config.DataFolderRelative
    $fallbackBasePath = Get-FallbackStorageBasePath
    $fallbackDataPath = Join-Path $fallbackBasePath $Script:Config.DataFolderRelative

    if (Test-DirectoryWritable -Path $repoDataPath) {
        $Script:Storage.BasePath = $repoBasePath
        $Script:Storage.DataPath = $repoDataPath
        $Script:Storage.UsingFallback = $false
        $storageLevel = 'INFO'
        $storageMode = 'repository data'
    }
    elseif (Test-DirectoryWritable -Path $fallbackDataPath) {
        $Script:Storage.BasePath = $fallbackBasePath
        $Script:Storage.DataPath = $fallbackDataPath
        $Script:Storage.UsingFallback = $true
        $storageLevel = 'WARN'
        $storageMode = 'LocalAppData fallback'
    }
    else {
        throw ('Autopilot Express could not find a writable storage location. Checked {0} and {1}.' -f $repoDataPath, $fallbackDataPath)
    }

    $Script:Storage.Initialised = $true
    Write-AutopilotExpressLog -Message ('Autopilot Express storage root: {0} ({1})' -f $Script:Storage.DataPath, $storageMode) -Level $storageLevel
}

function Get-StorageBasePath {
    Initialize-StorageLocation
    return $Script:Storage.BasePath
}

function Get-DataFolderPath {
    param([string]$BasePath)

    $resolvedBasePath = if ($BasePath) { $BasePath } else { Get-StorageBasePath }
    $dataFolder = Join-Path $resolvedBasePath $Script:Config.DataFolderRelative
    if (-not (Test-Path $dataFolder)) {
        New-Item -ItemType Directory -Path $dataFolder -Force -ErrorAction Stop | Out-Null
    }
    return $dataFolder
}

function Get-ArchiveFolderPath {
    param([string]$BasePath)

    $archiveFolder = Join-Path (Get-DataFolderPath -BasePath $BasePath) $Script:Config.ArchiveFolderRelative
    if (-not (Test-Path $archiveFolder)) {
        New-Item -ItemType Directory -Path $archiveFolder -Force -ErrorAction Stop | Out-Null
    }
    return $archiveFolder
}

function New-ParentDirectory {
    param([Parameter(Mandatory)][string]$Path)
    $parentPath = Split-Path -Parent $Path
    if (-not [string]::IsNullOrWhiteSpace($parentPath) -and -not (Test-Path $parentPath)) {
        New-Item -ItemType Directory -Path $parentPath -Force -ErrorAction Stop | Out-Null
    }
}

function Write-Utf8File {
    param(
        [Parameter(Mandatory)][string]$Path,
        [Parameter(Mandatory)][string]$Content
    )
    New-ParentDirectory -Path $Path
    Set-Content -Path $Path -Value $Content -Encoding utf8NoBOM -NoNewline -Force -ErrorAction Stop
}

function Copy-StateFileIfNeeded {
    param(
        [Parameter(Mandatory)][string]$SourcePath,
        [Parameter(Mandatory)][string]$DestinationPath
    )

    if (-not (Test-Path $SourcePath) -or (Test-Path $DestinationPath)) { return }

    try {
        $content = Get-Content -Raw -Path $SourcePath -ErrorAction Stop
        Write-Utf8File -Path $DestinationPath -Content $content
        Write-AutopilotExpressLog -Message ('Migrated Autopilot Express state from {0} to {1}.' -f $SourcePath, $DestinationPath) -Level 'WARN'
    }
    catch {
        Write-AutopilotExpressLog -Message ('Failed to migrate Autopilot Express state file {0}: {1}' -f $SourcePath, $_.Exception.Message) -Level 'WARN'
    }
}

function Get-ModeUserDataFilePrefix {
    if ($Script:Runtime.IsDemoMode) { return $Script:Config.DemoUserDataFilePrefix }
    return $Script:Config.UserDataFilePrefix
}

function Get-ModeRecentUsersFilePrefix {
    if ($Script:Runtime.IsDemoMode) { return $Script:Config.DemoRecentUsersFilePrefix }
    return $Script:Config.RecentUsersFilePrefix
}

function Get-ModeBuildBenchFilePrefix {
    if ($Script:Runtime.IsDemoMode) { return $Script:Config.DemoBuildBenchFilePrefix }
    return $Script:Config.BuildBenchFilePrefix
}

function Get-UserDataFilePath {
    param([string]$BasePath)

    $user = $env:USERNAME
    return Join-Path (Get-DataFolderPath -BasePath $BasePath) ("{0}-{1}.json" -f (Get-ModeUserDataFilePrefix), $user)
}

function Get-BuildBenchStatePath {
    param([string]$BasePath)

    return Join-Path (Get-DataFolderPath -BasePath $BasePath) ("{0}-{1}.json" -f (Get-ModeBuildBenchFilePrefix), $env:USERNAME)
}

function Get-RecentUsersFilePath {
    param([string]$BasePath)

    return Join-Path (Get-DataFolderPath -BasePath $BasePath) ("{0}-{1}.json" -f (Get-ModeRecentUsersFilePrefix), $env:USERNAME)
}

function Get-AutopilotExpressDefinitionPath {
    param([Parameter(Mandatory)][string]$FileName)
    return Join-Path (Split-Path -Parent $PSCommandPath) $FileName
}

function Get-RuntimeConfigFilePath {
    return Get-AutopilotExpressDefinitionPath -FileName $Script:Config.RuntimeConfigFileName
}

function Get-ManifestFilePath {
    return Get-AutopilotExpressDefinitionPath -FileName $Script:Config.ManifestFileName
}

function Get-MasterAuditFilePath {
    param([string]$BasePath)

    return Join-Path (Get-DataFolderPath -BasePath $BasePath) $Script:Config.MasterAuditFileName
}

function Sync-RepoStateFilesToActiveStorage {
    if (-not $Script:Storage.UsingFallback) { return }

    $repoBasePath = Get-RepoStorageBasePath
    $activeBasePath = Get-StorageBasePath

    Copy-StateFileIfNeeded -SourcePath (Get-UserDataFilePath -BasePath $repoBasePath) -DestinationPath (Get-UserDataFilePath -BasePath $activeBasePath)
    Copy-StateFileIfNeeded -SourcePath (Get-BuildBenchStatePath -BasePath $repoBasePath) -DestinationPath (Get-BuildBenchStatePath -BasePath $activeBasePath)
    Copy-StateFileIfNeeded -SourcePath (Get-RecentUsersFilePath -BasePath $repoBasePath) -DestinationPath (Get-RecentUsersFilePath -BasePath $activeBasePath)

    if (-not $Script:Runtime.IsDemoMode) {
        Copy-StateFileIfNeeded -SourcePath (Get-MasterAuditFilePath -BasePath $repoBasePath) -DestinationPath (Get-MasterAuditFilePath -BasePath $activeBasePath)
    }
}

function Get-SessionLastUpdated {
    $sessionPaths = @((Get-UserDataFilePath), (Get-BuildBenchStatePath)) | Where-Object { Test-Path $_ }
    if (-not $sessionPaths -or $sessionPaths.Count -eq 0) { return $null }
    $latestItem = $sessionPaths | ForEach-Object { Get-Item -Path $_ } | Sort-Object LastWriteTime -Descending | Select-Object -First 1
    return $latestItem.LastWriteTime
}

function Move-SessionFileToArchive {
    param([Parameter(Mandatory)][string]$Path)
    if (-not (Test-Path $Path)) { return }
    $archiveFolder = Get-ArchiveFolderPath
    $timestamp = Get-Date -Format 'yyyyMMdd-HHmmss'
    $modeSlug = if ($Script:Runtime.IsDemoMode) { 'demo' } else { 'live' }
    $archiveName = ('{0}-{1}-{2}{3}' -f [System.IO.Path]::GetFileNameWithoutExtension($Path), $modeSlug, $timestamp, [System.IO.Path]::GetExtension($Path))
    Move-Item -Path $Path -Destination (Join-Path $archiveFolder $archiveName) -Force
}

function Reset-CurrentSessionState {
    Move-SessionFileToArchive -Path (Get-UserDataFilePath)
    Move-SessionFileToArchive -Path (Get-BuildBenchStatePath)
    $Script:BuildBench = Get-DefaultBuildBenchState
    return , ([System.Collections.ArrayList]::new())
}

function Update-MasterAuditLedger {
    param([Parameter(Mandatory)][System.Collections.IEnumerable]$Records)
    if ($Script:Runtime.IsDemoMode) { return }
    $auditPath = Get-MasterAuditFilePath
    $existingEntries = @()
    if (Test-Path $auditPath) {
        try {
            $rawEntries = Get-Content -Raw -Path $auditPath | ConvertFrom-Json
            if ($null -ne $rawEntries) { $existingEntries = @($rawEntries) }
        }
        catch {
            Write-AutopilotExpressLog -Message ('Failed to load master audit ledger: {0}' -f $_.Exception.Message) -Level 'WARN'
            $existingEntries = @()
        }
    }

    $entryMap = @{}
    foreach ($entry in $existingEntries) {
        if ($entry.RecordId) { $entryMap[$entry.RecordId] = $entry }
    }

    foreach ($record in @($Records)) {
        if (-not $record.RecordId) { continue }
        $completedAt = if ($record.CompletedAt -and $record.CompletedAt -gt [DateTime]::MinValue) { $record.CompletedAt } else { $null }
        $entryMap[$record.RecordId] = [pscustomobject]@{
            RecordId             = $record.RecordId
            AutopilotDeviceId    = $record.AutopilotDeviceId
            ManagedDeviceId      = $record.ManagedDeviceId
            AzureAdDeviceId      = $record.AzureAdDeviceId
            Serial               = $record.Serial
            ConfigItem           = $record.ConfigItem
            SiteCode             = $record.SiteCode
            DeviceType           = $record.DeviceType
            GroupTag             = $record.GroupTag
            StartedAt            = $record.StartedAt
            CompletedAt          = $completedAt
            StartedBy            = $record.StartedBy
            LastUpdatedAt        = $record.LastUpdatedAt
            LastUpdatedBy        = $record.LastUpdatedBy
            Status               = $record.Status
            Result               = $record.Status
            IsCompletionVerified = $record.IsCompletionVerified
            IntuneDeviceName     = $record.IntuneDeviceName
            EntraDeviceId        = $record.EntraDeviceId
            TechnicianUser       = $record.TechnicianUserPrincipalName
            FinalPrimaryUserId   = $record.FinalPrimaryUserId
            FinalPrimaryUser     = $record.FinalPrimaryUserPrincipalName
            FinalPrimaryUserName = $record.FinalPrimaryUserDisplayName
            Steps                = ConvertTo-NormalisedValue -Value $record.Steps
        }
    }

    $serialisedEntries = @($entryMap.Values | Sort-Object Serial, StartedAt)
    $auditJson = if ($serialisedEntries.Count -gt 0) { $serialisedEntries | ConvertTo-Json -Depth 8 } else { '[]' }
    Write-Utf8File -Path $auditPath -Content $auditJson
}

function Get-UserDeviceRecords {
    $path = Get-UserDataFilePath
    $records = [System.Collections.ArrayList]::new()
    if (-not (Test-Path $path)) {
        return , $records
    }
    try {
        $json = Get-Content -Raw -Path $path
        $data = $json | ConvertFrom-Json
        $items = if ($null -eq $data) { @() } else { @($data) }
        foreach ($r in $items) {
            if ($null -eq $r) { continue }
            $obj = [AutopilotDeviceRecord]::new()
            $obj.RecordId = if ($r.RecordId) { $r.RecordId } else { [guid]::NewGuid().Guid }
            $obj.AutopilotDeviceId = if ($null -ne $r.AutopilotDeviceId) { [string]$r.AutopilotDeviceId } else { '' }
            $obj.ManagedDeviceId = if ($null -ne $r.ManagedDeviceId) { [string]$r.ManagedDeviceId } else { '' }
            $obj.AzureAdDeviceId = if ($null -ne $r.AzureAdDeviceId) { [string]$r.AzureAdDeviceId } else { '' }
            $obj.IntuneDeviceName = if ($null -ne $r.IntuneDeviceName) { [string]$r.IntuneDeviceName } else { '' }
            $obj.Serial = $r.Serial
            $obj.EntraDeviceId = if ($null -ne $r.EntraDeviceId) { [string]$r.EntraDeviceId } else { '' }
            $obj.ConfigItem = $r.ConfigItem
            $obj.SiteCode = $r.SiteCode
            $obj.DeviceType = $r.DeviceType
            $obj.GroupTag = $r.GroupTag
            $obj.Status = if ($r.Status) { $r.Status } else { 'new' }
            $obj.Steps = ConvertTo-StepHashtable -Value $r.Steps
            $obj.StartedAt = if ($r.StartedAt) { [DateTime]$r.StartedAt } else { [DateTime]::MinValue }
            $obj.StartedBy = if ($r.StartedBy) { $r.StartedBy } else { '' }
            $obj.LastUpdatedAt = if ($r.LastUpdatedAt) { [DateTime]$r.LastUpdatedAt } else { $obj.StartedAt }
            $obj.LastUpdatedBy = if ($r.LastUpdatedBy) { $r.LastUpdatedBy } else { $obj.StartedBy }
            $obj.CompletedAt = if ($r.CompletedAt) { [DateTime]$r.CompletedAt } else { [DateTime]::MinValue }
            $obj.CompletedBy = if ($r.CompletedBy) { $r.CompletedBy } else { '' }
            $obj.IsCompletionVerified = [bool]$r.IsCompletionVerified
            $obj.TechnicianUserPrincipalName = if ($r.TechnicianUserPrincipalName) { [string]$r.TechnicianUserPrincipalName } elseif ($r.TechnicianUser) { [string]$r.TechnicianUser } else { '' }
            $obj.FinalPrimaryUserId = if ($r.FinalPrimaryUserId) { [string]$r.FinalPrimaryUserId } else { '' }
            $obj.FinalPrimaryUserPrincipalName = if ($r.FinalPrimaryUserPrincipalName) { [string]$r.FinalPrimaryUserPrincipalName } elseif ($r.FinalPrimaryUser) { [string]$r.FinalPrimaryUser } else { '' }
            $obj.FinalPrimaryUserDisplayName = if ($r.FinalPrimaryUserDisplayName) { [string]$r.FinalPrimaryUserDisplayName } elseif ($r.FinalPrimaryUserName) { [string]$r.FinalPrimaryUserName } else { '' }
            [void]$records.Add($obj)
        }
        return , $records
    }
    catch {
        Write-AutopilotExpressLog -Message ('Failed to load user data file: {0}' -f $_.Exception.Message) -Level 'ERROR'
        return , ([System.Collections.ArrayList]::new())
    }
}

function Write-UserDeviceRecords {
    param([Parameter(Mandatory)][System.Collections.IEnumerable]$Records)
    $path = Get-UserDataFilePath
    try {
        $serialisableRecords = @($Records)
        $json = if ($serialisableRecords.Count -gt 0) { $serialisableRecords | ConvertTo-Json -Depth 8 } else { '[]' }
        Write-Utf8File -Path $path -Content $json
        Write-AutopilotExpressLog -Message ('Saved {0} device record(s) to {1}' -f $serialisableRecords.Count, $path) -Level 'INFO'
        Update-MasterAuditLedger -Records $serialisableRecords
    }
    catch {
        Write-AutopilotExpressLog -Message ('Failed to save user device records: {0}' -f $_.Exception.Message) -Level 'ERROR'
    }
}

function Get-LockFilePath {
    param([Parameter(Mandatory)][string]$Serial)
    $lockFolder = Join-Path (Get-DataFolderPath) $Script:Config.LockFolderRelative
    if (-not (Test-Path $lockFolder)) { New-Item -ItemType Directory -Path $lockFolder -Force -ErrorAction Stop | Out-Null }
    return Join-Path $lockFolder ("{0}.lock" -f $Serial)
}

function New-DeviceLock {
    param([Parameter(Mandatory)][string]$Serial)
    $lockPath = Get-LockFilePath -Serial $Serial
    if (Test-Path $lockPath) {
        Write-AutopilotExpressLog -Message ('Device {0} appears locked; proceeding without exclusive lock but will avoid destructive writes.' -f $Serial) -Level 'WARN'
        return $false
    }
    Write-Utf8File -Path $lockPath -Content ('{0}|{1}' -f (Get-Date).ToString('o'), $env:USERNAME)
    return $true
}

function Remove-DeviceLock {
    param([Parameter(Mandatory)][string]$Serial)
    $lockPath = Get-LockFilePath -Serial $Serial
    if (Test-Path $lockPath) { Remove-Item -Path $lockPath -Force }
}

# INPUT VALIDATION UTILITIES
function Read-ValidatedInput {
    param(
        [Parameter(Mandatory)][string]$Prompt,
        [string]$Default,
        [ValidateSet('String', 'Int', 'Choice')][string]$Type = 'String',
        [string[]]$Choices,
        [switch]$AllowEmpty
    )
    while ($true) {
        # Do not append colon here; Read-Host will add ':' automatically
        $renderPrompt = if ($Default) { ('{0} (default: {1})' -f $Prompt, $Default) } else { ('{0}' -f $Prompt) }
        $response = Read-Host -Prompt $renderPrompt
        if ([string]::IsNullOrWhiteSpace($response)) { $response = $Default }
        if (-not $response -and -not $AllowEmpty) { Write-Host 'Input cannot be empty.'; continue }
        switch ($Type) {
            'Int' {
                if (-not [int]::TryParse($response, [ref]$null)) { Write-Host 'Please enter a valid number.'; continue }
            }
            'Choice' {
                if ($Choices -and -not ($Choices | ForEach-Object { $_.ToLower() } | Where-Object { $_ -eq $response.ToLower() })) { Write-Host ('Please choose one of: {0}' -f ($Choices -join ', ')); continue }
            }
        }
        return $response
    }
}

function Select-Site {
    param([string]$CurrentSiteCode)
    Write-Host 'Select site:'
    $defaultSiteIndex = 0
    for ($i = 0; $i -lt $Script:Sites.Count; $i++) {
        $s = $Script:Sites[$i]
        if ($s.Code -eq $CurrentSiteCode) { $defaultSiteIndex = $i }
        $marker = if ($s.Code -eq $CurrentSiteCode) { '*' } else { ' ' }
        Write-Host ('{0} [{1}] {2} {3}' -f ($i + 1), $s.Code, $s.Name, $marker)
    }
    $choice = Read-ValidatedInput -Prompt 'Enter number of site' -Type 'Int' -Default ($defaultSiteIndex + 1)
    $index = [int]$choice - 1
    if ($index -lt 0 -or $index -ge $Script:Sites.Count) { Write-Host 'Invalid site selection.'; return $CurrentSiteCode }
    return $Script:Sites[$index].Code
}

function Show-MainMenu {
    param([string]$CurrentSiteCode)
    $siteObj = $Script:Sites | Where-Object { $_.Code -eq $CurrentSiteCode }
    $siteDisplay = if ($siteObj) { ('{0} - {1}' -f $siteObj.Code, $siteObj.Name) } else { 'Not Set' }
    $graphSessionDisplay = if ($Script:GraphSession.Connected) { $Script:GraphSession.Account } else { 'Not Connected' }
    Write-Host ''
    Write-Host ('Session Mode: {0}' -f ((Get-Culture).TextInfo.ToTitleCase($Script:Runtime.ModeDisplayName)))
    Write-Host ('Graph Session: {0}' -f $graphSessionDisplay)
    Write-Host ('Current Site: {0}' -f $siteDisplay)
    Write-Host '================ MAIN MENU ================'
    Write-Host '1. Start work on a new device'
    Write-Host '2. Autopilot the device'
    Write-Host "3. What's outstanding for a device"
    Write-Host '4. Maintain my device list'
    Write-Host '5. My stats and progress'
    Write-Host '6. Enhancements & questions'
    Write-Host '7. Change current site'
    Write-Host '8. Build bench view'
    Write-Host '0. Exit'
    Write-Host '==========================================='
    return Read-ValidatedInput -Prompt 'Choose an option' -Default '0'
}

# STUB FUNCTIONS WITH PERMISSION NOTES
function Start-NewDeviceWorkflow {
    <#
		.SYNOPSIS
			Begin tracking a new device (metadata capture, tag assignment, optional group membership).
		.NOTES
			Required future permissions: DeviceManagementServiceConfig.ReadWrite.All, Device.ReadWrite.All, Group.ReadWrite.All.
			Steps:
			  1. Confirm / change current site.
			  2. Capture Serial & Config Item (barcode scanner friendly).
			  3. Query Autopilot devices by serial (Graph).
			  4. Retrieve/Store Entra device ID.
			  5. Confirm or set Group Tag.
			  6. Add device to support group(s) if enabled.
			  7. Optionally delete stale Autopilot record before re-import.
	#>
    param([string]$CurrentSiteCode, [ref]$Records)
    $siteCode = $CurrentSiteCode
    $confirm = Read-ValidatedInput -Prompt ('Working at site {0}. Change? (Y/N)' -f $siteCode) -Default 'N' -Type 'Choice' -Choices @('Y', 'N')
    if ($confirm.ToUpper() -eq 'Y') { $siteCode = Select-Site -CurrentSiteCode $siteCode }

    while ($true) {
        $serial = Read-ValidatedInput -Prompt ('Enter {0}' -f $Script:Config.Nomenclature.Serial)
        $configItem = Read-ValidatedInput -Prompt ('Enter {0}' -f $Script:Config.Nomenclature.ConfigItem)
        $deviceType = Select-DeviceType -Default $Script:DeviceTypes[0]
        # Enforce Group Tag pattern (SITECODE-Devicetype, preserve case); no override permitted
        $expectedTag = ('{0}-{1}' -f $siteCode, ($deviceType -replace '\s', ''))
        Write-Host ''
        Write-Host 'Please confirm the details:'
        Write-Host ('  {0}: {1}' -f $Script:Config.Nomenclature.Serial, $serial)
        Write-Host ('  {0}: {1}' -f $Script:Config.Nomenclature.ConfigItem, $configItem)
        Write-Host ('  {0}: {1}' -f $Script:Config.Nomenclature.Site, $siteCode)
        Write-Host ('  {0}: {1}' -f $Script:Config.Nomenclature.DeviceType, $deviceType)
        Write-Host ('  {0}: {1}' -f $Script:Config.Nomenclature.GroupTag, $expectedTag)
        $proceed = Read-ValidatedInput -Prompt 'Proceed with these details? (Y/N)' -Default 'Y' -Type 'Choice' -Choices @('Y', 'N')
        if ($proceed.ToUpper() -eq 'Y') {
            $record = New-DeviceRecordObject -Serial $serial -ConfigItem $configItem -SiteCode $siteCode -DeviceType $deviceType -GroupTag $expectedTag
            Add-DeviceRecord -Records $Records -Record $record
            Write-UserDeviceRecords -Records $Records.Value
            Write-AutopilotExpressLog -Message ('Added new device Serial={0} CI={1} Site={2} DeviceType={3}' -f $serial, $configItem, $siteCode, $deviceType) -Level 'INFO'
            break
        }
        else {
            Write-Host "Let's correct the details. You will be re-prompted."
        }
    }
    return $siteCode
}

function Invoke-AutopilotSequence {
    <#
		.SYNOPSIS
			Perform Autopilot sequence steps for a device.
		.NOTES
			Future endpoints: managedDevices sync, device user assignment, group membership checks, detectedApps.
			Permissions: DeviceManagementManagedDevices.ReadWrite.All, Group.Read.All, User.Read.All.
	#>
    param([ref]$Records)
    $device = Select-DeviceFromRecords -Records $Records -Purpose 'autopilot'
    if (-not $device) { Write-Host 'Returning to main menu...'; return }
    Write-Host 'Autopilot Sub-Menu (manifest-driven)'
    foreach ($step in (Get-EnabledManifestSteps)) {
        if (Test-ManifestStepCompleted -Device $device -StepId $step.Id) {
            $stepState = '[Done]'
        }
        elseif (Test-ManifestStepAttempted -Device $device -StepId $step.Id) {
            $stepState = '[Retry]'
        }
        else {
            $stepState = '[Todo]'
        }
        Write-Host ("{0}. {1} {2}" -f $step.Id, $step.DisplayName, $stepState)
    }
    Write-Host 'R. Return (0 exits)'
    $opt = Read-ValidatedInput -Prompt 'Choose option' -Default 'R'
    if ($opt -ne 'R' -and $opt -ne '0') {
        $sel = Get-ManifestStepDefinition -StepId $opt
        if ($sel) {
            $result = Invoke-AutopilotManifestStep -Device $device -StepDefinition $sel
            Write-ManifestStepResult -Device $device -StepDefinition $sel -Result $result
            Write-Host $result.Summary
            if ($result.Notes) { Write-Host $result.Notes }
            Write-AutopilotExpressLog -Message ('Recorded step {0} ({1}) for Serial={2} Success={3}' -f $opt, $sel.DisplayName, $device.Serial, $result.Success) -Level 'INFO'
        }
        else { Write-Host 'Invalid step selection.' }
    }
    Write-UserDeviceRecords -Records $Records.Value  # Save updated records after step selection
}

function Get-DeviceOutstanding {
    <# .SYNOPSIS Display outstanding steps for a device. #>
    param([ref]$Records)
    $device = Select-DeviceFromRecords -Records $Records -Purpose 'outstanding'
    if (-not $device) { Write-Host 'Returning to main menu...'; return }
    Write-Host ('Device Serial={0} CI={1} Status={2}' -f $device.Serial, $device.ConfigItem, $device.Status)
    $completedSteps = @()
    $retrySteps = @()
    $outstandingSteps = @()
    foreach ($step in (Get-EnabledManifestSteps)) {
        if (Test-ManifestStepCompleted -Device $device -StepId $step.Id) {
            $completedSteps += ('{0} {1}' -f $step.Id, $step.DisplayName)
        }
        elseif (Test-ManifestStepAttempted -Device $device -StepId $step.Id) {
            $retrySteps += ('{0} {1}' -f $step.Id, $step.DisplayName)
        }
        else {
            $outstandingSteps += ('{0} {1}' -f $step.Id, $step.DisplayName)
        }
    }
    Write-Host ('Completed Steps: {0}' -f $(if ($completedSteps.Count -gt 0) { $completedSteps -join ', ' } else { 'None' }))
    Write-Host ('Retry Steps: {0}' -f $(if ($retrySteps.Count -gt 0) { $retrySteps -join ', ' } else { 'None' }))
    Write-Host ('Outstanding Steps: {0}' -f $(if ($outstandingSteps.Count -gt 0) { $outstandingSteps -join ', ' } else { 'None' }))
}

function Update-DeviceStatus {
    <# .SYNOPSIS Update device status (new|in-progress|completed|removed). #>
    param([ref]$Records)
    $device = Select-DeviceFromRecords -Records $Records -Purpose 'update status'
    if (-not $device) { Write-Host 'Returning to main menu...'; return }
    $status = Read-ValidatedInput -Prompt 'Enter status (new,in-progress,completed,removed)' -Type 'Choice' -Choices @('new', 'in-progress', 'completed', 'removed') -Default $device.Status
    $device.Status = $status
    if ($status -eq 'completed') { $device.CompletedAt = Get-Date; $device.CompletedBy = $env:USERNAME }
    $device.LastUpdatedAt = Get-Date; $device.LastUpdatedBy = $env:USERNAME
    Write-UserDeviceRecords -Records $Records.Value
    Write-AutopilotExpressLog -Message ('Updated status {0} for Serial={1}' -f $status, $device.Serial) -Level 'INFO'
}

function Get-UserStats {
    <# .SYNOPSIS Show per-user stats as tables (overall and by site), newest date first. #>
    param([ref]$Records)
    $recordsLocal = $Records.Value
    if (-not $recordsLocal -or $recordsLocal.Count -eq 0) { Write-Host 'No records to display.'; return }
    $deviceTypes = $Script:DeviceTypes
    function Show-StatsTable {
        param([object[]]$Rows, [string]$Title)
        Write-Host ('--- {0} ---' -f $Title)
        $header = ('| {0,-10} | {1,-7} | {2,-7} | {3,-7} | {4,-7} | {5,-7} |' -f 'Date', 'Desktop', 'Laptop', 'WOW', 'NUC', 'Total')
        $rule = '-' * $header.Length
        Write-Host $header
        Write-Host $rule
        foreach ($r in $Rows) {
            Write-Host ('| {0,-10} | {1,-7} | {2,-7} | {3,-7} | {4,-7} | {5,-7} |' -f $r.Date, $r.Desktop, $r.Laptop, $r.WOW, $r.NUC, $r.Total)
        }
        Write-Host $rule
        $totDesktop = ($Rows | Measure-Object -Property Desktop -Sum).Sum
        $totLaptop = ($Rows | Measure-Object -Property Laptop -Sum).Sum
        $totWOW = ($Rows | Measure-Object -Property WOW -Sum).Sum
        $totNUC = ($Rows | Measure-Object -Property NUC -Sum).Sum
        $totAll = ($Rows | Measure-Object -Property Total -Sum).Sum
        Write-Host ('| {0,-10} | {1,-7} | {2,-7} | {3,-7} | {4,-7} | {5,-7} |' -f 'Total', $totDesktop, $totLaptop, $totWOW, $totNUC, $totAll)
        Write-Host ''
    }
    # Group by date
    $byDate = $recordsLocal | Group-Object { $_.StartedAt.ToString('d/M/yyyy') }
    $tableRows = @()
    foreach ($g in $byDate) {
        $date = $g.Name
        $counts = @{ Desktop = 0; Laptop = 0; WOW = 0; NUC = 0 }
        foreach ($rec in $g.Group) { if ($counts.ContainsKey($rec.DeviceType)) { $counts[$rec.DeviceType]++ } }
        $total = $counts['Desktop'] + $counts['Laptop'] + $counts['WOW'] + $counts['NUC']
        $tableRows += [pscustomobject]@{ Date = $date; Desktop = $counts['Desktop']; Laptop = $counts['Laptop']; WOW = $counts['WOW']; NUC = $counts['NUC']; Total = $total }
    }
    $tableRows = $tableRows | Sort-Object { [datetime]::ParseExact($_.Date, 'd/M/yyyy', $null) } -Descending
    Show-StatsTable -Rows $tableRows -Title 'Overall'
    # By site
    $bySite = $recordsLocal | Group-Object -Property SiteCode
    foreach ($site in $bySite) {
        $siteRows = @()
        $byDateSite = $site.Group | Group-Object { $_.StartedAt.ToString('d/M/yyyy') }
        foreach ($gd in $byDateSite) {
            $date = $gd.Name
            $counts = @{ Desktop = 0; Laptop = 0; WOW = 0; NUC = 0 }
            foreach ($rec in $gd.Group) { if ($counts.ContainsKey($rec.DeviceType)) { $counts[$rec.DeviceType]++ } }
            $total = $counts['Desktop'] + $counts['Laptop'] + $counts['WOW'] + $counts['NUC']
            $siteRows += [pscustomobject]@{ Date = $date; Desktop = $counts['Desktop']; Laptop = $counts['Laptop']; WOW = $counts['WOW']; NUC = $counts['NUC']; Total = $total }
        }
        $siteRows = $siteRows | Sort-Object { [datetime]::ParseExact($_.Date, 'd/M/yyyy', $null) } -Descending
        Show-StatsTable -Rows $siteRows -Title ('By site: {0}' -f $site.Name)
    }
}

function Show-EnhancementsQuestions {
    <# .SYNOPSIS Display potential enhancements & ask clarifying questions. #>
    Write-Host '--- Potential Enhancements ---'
    foreach ($e in $Script:EnhancementManifest) {
        Write-Host ("{0}. {1} [{2}]" -f $e.Id, $e.Title, $e.Status)
        if ($e.Description) { Write-Host ('    - {0}' -f $e.Description) }
    }
    Write-Host ''
    Write-Host '--- Clarifying Questions ---'
    Write-Host 'A. Should manager validation exclude certain role titles?'
    Write-Host 'B. Required retention period for device build history?'
    Write-Host 'C. Need encryption at rest for JSON data files?'
    Write-Host 'D. External CMDB column mapping examples?'
    Write-Host 'E. Preferred approach for roll-up (central share vs Graph storage)?'
}

# ===== Build Bench (scaffold) =====
$Script:BuildBench = Get-DefaultBuildBenchState

function Save-BuildBenchState {
    try {
        $json = $Script:BuildBench | ConvertTo-Json -Depth 6
        Write-Utf8File -Path (Get-BuildBenchStatePath) -Content $json
    }
    catch {
        Write-AutopilotExpressLog -Message ('Failed to save build bench: {0}' -f $_.Exception.Message) -Level 'ERROR'
    }
}

function Get-BuildBenchState {
    $path = Get-BuildBenchStatePath
    if (Test-Path $path) {
        try {
            $state = Get-Content -Raw -Path $path | ConvertFrom-Json
            $normalisedState = Get-DefaultBuildBenchState
            $normalisedState.Active = [bool]$state.Active
            $normalisedState.SiteCode = $state.SiteCode
            $normalisedState.DeviceType = $state.DeviceType
            $normalisedState.Faults = @()
            foreach ($fault in @($state.Faults)) {
                if ($null -ne $fault) { $normalisedState.Faults += [string]$fault }
            }
            $normalisedState.Positions = @()
            foreach ($position in @($state.Positions)) {
                if ($null -eq $position) { continue }
                $normalisedState.Positions += [ordered]@{
                    Index      = [int]$position.Index
                    Serial     = $position.Serial
                    ConfigItem = $position.ConfigItem
                }
            }
            return $normalisedState
        }
        catch {
            Write-AutopilotExpressLog -Message ('Failed to load build bench state: {0}' -f $_.Exception.Message) -Level 'ERROR'
            return Get-DefaultBuildBenchState
        }
    }
    return Get-DefaultBuildBenchState
}

function Initialize-SessionState {
    Sync-RepoStateFilesToActiveStorage
    $hasUserData = Test-Path (Get-UserDataFilePath)
    $hasBenchData = Test-Path (Get-BuildBenchStatePath)
    if (-not $hasUserData -and -not $hasBenchData) {
        $Script:BuildBench = Get-DefaultBuildBenchState
        return , ([System.Collections.ArrayList]::new())
    }
    $lastUpdated = Get-SessionLastUpdated
    $resumePrompt = ('Resume existing {0} session last updated {1}? (Y/N)' -f $Script:Runtime.ModeDisplayName, $lastUpdated.ToString('yyyy-MM-dd HH:mm:ss'))
    $resumeExisting = Read-ValidatedInput -Prompt $resumePrompt -Default 'Y' -Type 'Choice' -Choices @('Y', 'N')
    if ($resumeExisting.ToUpper() -ne 'Y') {
        Write-AutopilotExpressLog -Message ('Archiving existing {0} session and starting a clean session.' -f $Script:Runtime.ModeDisplayName) -Level 'INFO'
        return , (Reset-CurrentSessionState)
    }
    $Script:BuildBench = Get-BuildBenchState
    return , (Get-UserDeviceRecords)
}

function Get-SessionDefaultSiteCode {
    param([System.Collections.IEnumerable]$Records)
    if ($Script:BuildBench.Active -and $Script:BuildBench.SiteCode) { return $Script:BuildBench.SiteCode }
    $recordArray = @($Records)
    if ($recordArray.Count -gt 0) {
        $latestRecord = $recordArray | Sort-Object LastUpdatedAt -Descending | Select-Object -First 1
        if ($latestRecord -and $latestRecord.SiteCode) { return $latestRecord.SiteCode }
    }
    return $Script:Sites[0].Code
}

function Get-ConfiguredSearchLimit {
    if ($Script:RuntimeConfig.autopilot.directorySearchLimit) { return [int]$Script:RuntimeConfig.autopilot.directorySearchLimit }
    return 15
}

function Get-ConfiguredRecentUserLimit {
    if ($Script:RuntimeConfig.autopilot.recentUsersLimit) { return [int]$Script:RuntimeConfig.autopilot.recentUsersLimit }
    return 8
}

function Get-ConfiguredDeploymentProfileDisplayName {
    if ($Script:RuntimeConfig.autopilot.deploymentProfileDisplayName) { return [string]$Script:RuntimeConfig.autopilot.deploymentProfileDisplayName }
    return ''
}

function Get-ConfiguredPreProvisioningGroupDisplayName {
    if ($Script:RuntimeConfig.autopilot.preProvisioningGroupDisplayName) { return [string]$Script:RuntimeConfig.autopilot.preProvisioningGroupDisplayName }
    return ''
}

function Get-ConfiguredMissingSerialHandoffNote {
    if ($Script:RuntimeConfig.autopilot.missingSerialHandoffNote) { return [string]$Script:RuntimeConfig.autopilot.missingSerialHandoffNote }
    return 'Use the external Autopilot upload guide when the serial is not yet present in Autopilot.'
}

function Get-ConfiguredTechnicianPrefixes {
    $prefixes = @($Script:RuntimeConfig.autopilot.technicianUpnPrefixes)
    if ($prefixes.Count -gt 0) { return $prefixes }
    return @('C', 'E')
}

function Get-ConfiguredGraphScopes {
    $scopes = @($Script:RuntimeConfig.graph.requiredScopes)
    if ($scopes.Count -gt 0) { return $scopes }
    return @(
        'DeviceManagementServiceConfig.ReadWrite.All',
        'DeviceManagementManagedDevices.ReadWrite.All',
        'Group.ReadWrite.All',
        'GroupMember.ReadWrite.All',
        'User.Read.All',
        'Directory.Read.All'
    )
}

function Get-ConfiguredGraphModules {
    $modules = @($Script:RuntimeConfig.graph.requiredModules)
    if ($modules.Count -gt 0) { return $modules }
    return @('Microsoft.Graph.Authentication', 'Microsoft.Graph.DeviceManagement.Enrollment')
}

function Get-EmptyGraphSession {
    return [ordered]@{
        Connected   = $false
        IsSimulated = $Script:Runtime.IsDemoMode
        Account     = ''
        DisplayName = ''
        UserId      = ''
        Scopes      = @()
    }
}

function Get-EnabledManifestSteps {
    return @($Script:StepManifest | Where-Object { $_.Enabled })
}

function Get-ManifestStepDefinition {
    param([Parameter(Mandatory)][string]$StepId)
    return $Script:StepManifest | Where-Object { $_.Id -eq $StepId } | Select-Object -First 1
}

function Read-JsonDefinitionFile {
    param(
        [Parameter(Mandatory)][string]$Path,
        [Parameter(Mandatory)][string]$Description
    )
    if (-not (Test-Path $Path)) { throw ('{0} file not found: {1}' -f $Description, $Path) }
    $rawContent = Get-Content -Raw -Path $Path
    if ([string]::IsNullOrWhiteSpace($rawContent)) { throw ('{0} file is empty: {1}' -f $Description, $Path) }
    $parsedContent = $rawContent | ConvertFrom-Json
    return ConvertTo-NormalisedValue -Value $parsedContent
}

function Initialize-AutopilotExpressDefinitions {
    try {
        $runtimeConfig = Read-JsonDefinitionFile -Path (Get-RuntimeConfigFilePath) -Description 'Runtime configuration'
        $manifestConfig = Read-JsonDefinitionFile -Path (Get-ManifestFilePath) -Description 'Manifest'
    }
    catch {
        Write-AutopilotExpressLog -Message ('Failed to load Autopilot Express definitions: {0}' -f $_.Exception.Message) -Level 'ERROR'
        throw
    }

    $Script:RuntimeConfig = $runtimeConfig
    if ($runtimeConfig.organisationName) { $Script:Config.OrganisationName = [string]$runtimeConfig.organisationName }

    $loadedSteps = [System.Collections.ArrayList]::new()
    foreach ($step in @($manifestConfig.steps)) {
        if (-not $step.id -or -not $step.displayName -or -not $step.actionName) { continue }
        [void]$loadedSteps.Add([ordered]@{
                Id                  = [string]$step.id
                DisplayName         = [string]$step.displayName
                Enabled             = if ($null -ne $step.enabled) { [bool]$step.enabled } else { $true }
                ActionName          = [string]$step.actionName
                ExecutionType       = if ($step.executionType) { [string]$step.executionType } else { 'graph' }
                RequiredPermissions = @($step.requiredPermissions)
                GraphEndpoints      = @($step.graphEndpoints)
                Summary             = if ($step.summary) { [string]$step.summary } else { '' }
                Notes               = if ($step.notes) { [string]$step.notes } else { '' }
            })
    }

    $Script:StepManifest = @($loadedSteps)
    if ($Script:StepManifest.Count -eq 0) { throw 'No enabled steps were loaded from the manifest definition.' }

    Write-AutopilotExpressLog -Message ('Loaded {0} manifest step(s) and runtime settings from JSON definitions.' -f $Script:StepManifest.Count) -Level 'INFO'
}

function Test-LiveRuntimeConfiguration {
    $issues = [System.Collections.ArrayList]::new()

    if (-not $Script:RuntimeConfig.graph) { [void]$issues.Add('Runtime configuration is missing the graph block.') }
    if (-not $Script:RuntimeConfig.autopilot) { [void]$issues.Add('Runtime configuration is missing the autopilot block.') }

    if ($Script:RuntimeConfig.graph.authMode -and $Script:RuntimeConfig.graph.authMode -ne 'Browser') {
        [void]$issues.Add(('Only Browser auth mode is supported. Current value: {0}' -f $Script:RuntimeConfig.graph.authMode))
    }
    if ([string]::IsNullOrWhiteSpace((Get-ConfiguredDeploymentProfileDisplayName))) {
        [void]$issues.Add('deploymentProfileDisplayName is required in autopilot settings.')
    }
    if ([string]::IsNullOrWhiteSpace((Get-ConfiguredPreProvisioningGroupDisplayName))) {
        [void]$issues.Add('preProvisioningGroupDisplayName is required in autopilot settings.')
    }
    if ((Get-ConfiguredTechnicianPrefixes).Count -eq 0) {
        [void]$issues.Add('At least one technician UPN prefix is required in autopilot settings.')
    }
    if ((Get-ConfiguredGraphScopes).Count -eq 0) {
        [void]$issues.Add('At least one Microsoft Graph scope is required in graph settings.')
    }

    return @($issues)
}

function Import-RequiredGraphModules {
    $requiredModules = Get-ConfiguredGraphModules
    foreach ($moduleName in $requiredModules) {
        if (-not (Get-Module -ListAvailable -Name $moduleName)) {
            Write-AutopilotExpressLog -Message ('Required Microsoft Graph module is not installed: {0}' -f $moduleName) -Level 'ERROR'
            return $false
        }
        try {
            Import-Module $moduleName -ErrorAction Stop | Out-Null
        }
        catch {
            Write-AutopilotExpressLog -Message ('Failed to import Microsoft Graph module {0}: {1}' -f $moduleName, $_.Exception.Message) -Level 'ERROR'
            return $false
        }
    }
    return $true
}

function Invoke-GraphApiRequest {
    param(
        [Parameter(Mandatory)][ValidateSet('GET', 'POST', 'DELETE')][string]$Method,
        [Parameter(Mandatory)][string]$Uri,
        $Body,
        [hashtable]$Headers
    )

    if (-not $Script:GraphSession.Connected) { throw 'Microsoft Graph session is not connected.' }

    $invokeParameters = @{ Method = $Method; Uri = $Uri; ErrorAction = 'Stop' }
    if ($Headers -and $Headers.Count -gt 0) { $invokeParameters.Headers = $Headers }
    if ($null -ne $Body) {
        $invokeParameters.Body = if ($Body -is [string]) { $Body } else { $Body | ConvertTo-Json -Depth 8 }
        $invokeParameters.ContentType = 'application/json'
    }

    return Invoke-MgGraphRequest @invokeParameters
}

function Initialize-GraphSession {
    if ($Script:Runtime.IsDemoMode) {
        $demoUpn = if ($Script:RuntimeConfig.demo.technicianUserPrincipalName) { [string]$Script:RuntimeConfig.demo.technicianUserPrincipalName } else { 'c.demo.tech@examplehealth.network' }
        $demoDisplayName = if ($Script:RuntimeConfig.demo.technicianDisplayName) { [string]$Script:RuntimeConfig.demo.technicianDisplayName } else { 'Demo Technician' }
        $Script:GraphSession = [ordered]@{
            Connected   = $true
            IsSimulated = $true
            Account     = $demoUpn
            DisplayName = $demoDisplayName
            UserId      = [guid]::NewGuid().Guid
            Scopes      = Get-ConfiguredGraphScopes
        }
        Write-AutopilotExpressLog -Message ('Demo mode: simulated browser login completed for {0}.' -f $demoUpn) -Level 'INFO'
        return $true
    }

    $configIssues = Test-LiveRuntimeConfiguration
    if ($configIssues.Count -gt 0) {
        foreach ($issue in $configIssues) {
            Write-AutopilotExpressLog -Message $issue -Level 'ERROR'
        }
        return $false
    }

    if (-not (Import-RequiredGraphModules)) { return $false }

    try {
        Write-AutopilotExpressLog -Message 'Opening browser-based Microsoft Graph sign-in...' -Level 'INFO'
        Connect-MgGraph -Scopes (Get-ConfiguredGraphScopes) -ContextScope ([string]$Script:RuntimeConfig.graph.contextScope) -NoWelcome | Out-Null
        $me = Invoke-GraphApiRequest -Method 'GET' -Uri 'https://graph.microsoft.com/v1.0/me?$select=id,displayName,userPrincipalName,mail'
        $graphAccount = if ($me.userPrincipalName) { [string]$me.userPrincipalName } else { [string](Get-MgContext).Account }
        $Script:GraphSession = [ordered]@{
            Connected   = $true
            IsSimulated = $false
            Account     = $graphAccount
            DisplayName = if ($me.displayName) { [string]$me.displayName } else { $graphAccount }
            UserId      = if ($me.id) { [string]$me.id } else { '' }
            Scopes      = Get-ConfiguredGraphScopes
        }
        Write-AutopilotExpressLog -Message ('Authenticated to Microsoft Graph as {0}.' -f $Script:GraphSession.Account) -Level 'INFO'
        return $true
    }
    catch {
        Write-AutopilotExpressLog -Message ('Microsoft Graph authentication failed: {0}' -f $_.Exception.Message) -Level 'ERROR'
        return $false
    }
}

function Close-GraphSession {
    if (-not $Script:Runtime.IsDemoMode -and $Script:GraphSession.Connected) {
        try { Disconnect-MgGraph | Out-Null } catch { Write-Verbose ('Disconnect-MgGraph returned a non-blocking error: {0}' -f $_.Exception.Message) }
    }
    $Script:GraphSession = Get-EmptyGraphSession
}

function New-OperationResult {
    param(
        [Parameter(Mandatory)][string]$ActionName,
        [Parameter(Mandatory)][bool]$Success,
        [string]$Summary,
        [string]$Notes,
        [hashtable]$Data
    )
    return [pscustomobject]@{
        ActionName  = $ActionName
        Success     = $Success
        Summary     = if ($Summary) { $Summary } else { '' }
        Notes       = if ($Notes) { $Notes } else { '' }
        Data        = if ($Data) { $Data } else { @{} }
        IsSimulated = $Script:Runtime.IsDemoMode
    }
}

function Get-UserLocalPart {
    param([string]$UserPrincipalName)
    if ([string]::IsNullOrWhiteSpace($UserPrincipalName)) { return '' }
    $normalisedUserPrincipalName = $UserPrincipalName.Trim().ToLower()
    if ($normalisedUserPrincipalName.Contains('@')) { return $normalisedUserPrincipalName.Split('@')[0] }
    return $normalisedUserPrincipalName
}

function Test-DirectoryUserMatchesConfiguredPrefixes {
    param([string]$UserPrincipalName)
    $localPart = Get-UserLocalPart -UserPrincipalName $UserPrincipalName
    if ([string]::IsNullOrWhiteSpace($localPart)) { return $false }
    foreach ($configuredPrefix in (Get-ConfiguredTechnicianPrefixes)) {
        if ($localPart.StartsWith($configuredPrefix.ToLower())) { return $true }
    }
    return $false
}

function Get-DirectoryUserEligibilityMessage {
    param($User)
    if ($null -eq $User) { return 'No directory user was supplied.' }
    if ([string]::IsNullOrWhiteSpace([string]$User.UserPrincipalName)) { return 'The selected user does not have a user principal name.' }

    $hasAccountEnabledProperty = $User.PSObject.Properties.Name -contains 'AccountEnabled'
    if ($hasAccountEnabledProperty -and $null -ne $User.AccountEnabled -and -not [bool]$User.AccountEnabled) {
        return ('{0} is not an active account.' -f $User.UserPrincipalName)
    }

    if (-not (Test-DirectoryUserMatchesConfiguredPrefixes -UserPrincipalName $User.UserPrincipalName)) {
        return ('{0} does not begin with one of the permitted prefixes: {1}.' -f $User.UserPrincipalName, ((Get-ConfiguredTechnicianPrefixes) -join ', '))
    }

    return ''
}

function Test-EligibleDirectoryUser {
    param($User)
    return [string]::IsNullOrWhiteSpace((Get-DirectoryUserEligibilityMessage -User $User))
}

function Get-EligibleDirectoryUsers {
    param([Parameter(Mandatory)][System.Collections.IEnumerable]$Users)
    return @($Users | Where-Object { $null -ne $_ -and (Test-EligibleDirectoryUser -User $_) } | Sort-Object DisplayName, UserPrincipalName)
}

function Resolve-LiveDirectoryUserRecord {
    param($User)
    if ($null -eq $User) { return $null }

    try {
        if ($User.Id) {
            $resolvedUser = Invoke-GraphApiRequest -Method 'GET' -Uri ('https://graph.microsoft.com/v1.0/users/{0}?$select=id,displayName,userPrincipalName,accountEnabled' -f $User.Id)
            return ConvertTo-DirectoryUserRecord -User $resolvedUser
        }

        if ($User.UserPrincipalName) {
            $escapedUserPrincipalName = ([string]$User.UserPrincipalName).Replace("'", "''")
            $response = Invoke-GraphApiRequest -Method 'GET' -Uri ('https://graph.microsoft.com/v1.0/users?$filter=userPrincipalName eq ''{0}''&$select=id,displayName,userPrincipalName,accountEnabled&$top=1' -f $escapedUserPrincipalName)
            return @($response.value | ForEach-Object { ConvertTo-DirectoryUserRecord -User $_ }) | Where-Object { $null -ne $_ } | Select-Object -First 1
        }
    }
    catch {
        $userIdentity = if ($User.UserPrincipalName) { [string]$User.UserPrincipalName } elseif ($User.Id) { [string]$User.Id } else { 'unknown user' }
        Write-AutopilotExpressLog -Message ('Failed to revalidate directory user {0}: {1}' -f $userIdentity, $_.Exception.Message) -Level 'WARN'
    }

    return $null
}

function Resolve-EligibleDirectoryUser {
    param($User)
    if ($null -eq $User) { return $null }

    $candidateUser = if ($Script:Runtime.IsDemoMode) { $User } else { Resolve-LiveDirectoryUserRecord -User $User }
    if ($null -eq $candidateUser) {
        Write-Host 'The selected directory user could not be revalidated.'
        return $null
    }

    $eligibilityMessage = Get-DirectoryUserEligibilityMessage -User $candidateUser
    if (-not [string]::IsNullOrWhiteSpace($eligibilityMessage)) {
        Write-Host $eligibilityMessage
        return $null
    }

    return $candidateUser
}

function Get-RecentUsers {
    $recentUsersPath = Get-RecentUsersFilePath
    $recentUsers = @()

    if (Test-Path $recentUsersPath) {
        try {
            $storedUsers = Get-Content -Raw -Path $recentUsersPath | ConvertFrom-Json
            foreach ($storedUser in @($storedUsers)) {
                if ($null -eq $storedUser) { continue }
                $recentUsers += [pscustomobject]@{
                    Id                = if ($storedUser.id) { [string]$storedUser.id } elseif ($storedUser.Id) { [string]$storedUser.Id } else { '' }
                    DisplayName       = if ($storedUser.displayName) { [string]$storedUser.displayName } elseif ($storedUser.DisplayName) { [string]$storedUser.DisplayName } else { '' }
                    UserPrincipalName = if ($storedUser.userPrincipalName) { [string]$storedUser.userPrincipalName } elseif ($storedUser.UserPrincipalName) { [string]$storedUser.UserPrincipalName } else { '' }
                    AccountEnabled    = if ($null -ne $storedUser.accountEnabled) { [bool]$storedUser.accountEnabled } elseif ($null -ne $storedUser.AccountEnabled) { [bool]$storedUser.AccountEnabled } else { $true }
                }
            }
        }
        catch {
            Write-AutopilotExpressLog -Message ('Failed to load recent users file: {0}' -f $_.Exception.Message) -Level 'WARN'
        }
    }

    if ($recentUsers.Count -eq 0 -and $Script:Runtime.IsDemoMode) {
        foreach ($demoUser in @($Script:RuntimeConfig.demo.defaultUsers)) {
            if ($null -eq $demoUser) { continue }
            $userRecord = ConvertTo-DirectoryUserRecord -User $demoUser
            if ($null -ne $userRecord) { $recentUsers += $userRecord }
        }
    }

    $eligibleRecentUsers = @(Get-EligibleDirectoryUsers -Users (@($recentUsers | Where-Object { $_.UserPrincipalName } | Select-Object -First (Get-ConfiguredRecentUserLimit))))
    return , $eligibleRecentUsers
}

function Save-RecentUsers {
    param([Parameter(Mandatory)][System.Collections.IEnumerable]$Users)
    $recentUsersPath = Get-RecentUsersFilePath
    $serialisableUsers = @($Users | Select-Object Id, DisplayName, UserPrincipalName)
    $json = if ($serialisableUsers.Count -gt 0) { $serialisableUsers | ConvertTo-Json -Depth 5 } else { '[]' }
    Write-Utf8File -Path $recentUsersPath -Content $json
}

function Add-RecentUser {
    param([Parameter(Mandatory)]$User)
    $allUsers = [System.Collections.ArrayList]::new()
    [void]$allUsers.Add([pscustomobject]@{
            Id                = [string]$User.Id
            DisplayName       = [string]$User.DisplayName
            UserPrincipalName = [string]$User.UserPrincipalName
        })

    foreach ($existingUser in (Get-RecentUsers)) {
        $sameId = $existingUser.Id -and $User.Id -and $existingUser.Id -eq $User.Id
        $sameUpn = $existingUser.UserPrincipalName -and $User.UserPrincipalName -and $existingUser.UserPrincipalName.ToLower() -eq $User.UserPrincipalName.ToLower()
        if ($sameId -or $sameUpn) { continue }
        [void]$allUsers.Add($existingUser)
    }

    Save-RecentUsers -Users (@($allUsers | Select-Object -First (Get-ConfiguredRecentUserLimit)))
}

function ConvertTo-DirectoryUserRecord {
    param($User)
    if ($null -eq $User) { return $null }
    $id = if ($null -ne $User.id) { [string]$User.id } elseif ($null -ne $User.Id) { [string]$User.Id } else { '' }
    $displayName = if ($null -ne $User.displayName) { [string]$User.displayName } elseif ($null -ne $User.DisplayName) { [string]$User.DisplayName } else { '' }
    $upn = if ($null -ne $User.userPrincipalName) { [string]$User.userPrincipalName } elseif ($null -ne $User.UserPrincipalName) { [string]$User.UserPrincipalName } else { '' }
    $accountEnabled = if ($null -ne $User.accountEnabled) { [bool]$User.accountEnabled } elseif ($null -ne $User.AccountEnabled) { [bool]$User.AccountEnabled } else { $true }
    if ([string]::IsNullOrWhiteSpace($upn)) { return $null }
    return [pscustomobject]@{ Id = $id; DisplayName = $displayName; UserPrincipalName = $upn; AccountEnabled = $accountEnabled }
}

function Search-DemoDirectoryUsers {
    param(
        [Parameter(Mandatory)][ValidateSet('ExactUpn', 'DisplayName')][string]$SearchMode,
        [Parameter(Mandatory)][string]$Query
    )
    $allUsers = [System.Collections.ArrayList]::new()
    foreach ($demoUser in (Get-RecentUsers)) { [void]$allUsers.Add($demoUser) }
    foreach ($demoUser in @($Script:RuntimeConfig.demo.defaultUsers)) {
        $userRecord = ConvertTo-DirectoryUserRecord -User $demoUser
        if ($null -eq $userRecord) { continue }
        $isDuplicate = @($allUsers | Where-Object { $_.UserPrincipalName.ToLower() -eq $userRecord.UserPrincipalName.ToLower() }).Count -gt 0
        if (-not $isDuplicate) { [void]$allUsers.Add($userRecord) }
    }

    $normalisedQuery = $Query.Trim().ToLower()
    switch ($SearchMode) {
        'ExactUpn' {
            $matchedUsers = @(Get-EligibleDirectoryUsers -Users (@($allUsers | Where-Object {
                            $upn = $_.UserPrincipalName.ToLower()
                            $localPart = $upn.Split('@')[0]
                            $upn -eq $normalisedQuery -or $localPart -eq $normalisedQuery
                        })))
            return , $matchedUsers
        }
        'DisplayName' {
            $matchedUsers = @(Get-EligibleDirectoryUsers -Users (@($allUsers | Where-Object {
                            $_.DisplayName.ToLower().Contains($normalisedQuery) -or $_.UserPrincipalName.ToLower().Contains($normalisedQuery)
                        })))
            return , $matchedUsers
        }
    }
}

function Search-LiveDirectoryUsers {
    param(
        [Parameter(Mandatory)][ValidateSet('ExactUpn', 'DisplayName')][string]$SearchMode,
        [Parameter(Mandatory)][string]$Query
    )

    $searchLimit = Get-ConfiguredSearchLimit
    $escapedQuery = $Query.Trim().Replace("'", "''")

    if ([string]::IsNullOrWhiteSpace($escapedQuery)) { return @() }

    switch ($SearchMode) {
        'ExactUpn' {
            $uri = ('https://graph.microsoft.com/v1.0/users?$filter=startswith(userPrincipalName,''{0}'')&$select=id,displayName,userPrincipalName,accountEnabled&$top={1}' -f $escapedQuery, $searchLimit)
        }
        'DisplayName' {
            $firstToken = ($escapedQuery -split '\s+')[0]
            $uri = ('https://graph.microsoft.com/v1.0/users?$filter=startswith(displayName,''{0}'') or startswith(givenName,''{0}'') or startswith(surname,''{0}'') or startswith(userPrincipalName,''{0}'')&$select=id,displayName,userPrincipalName,accountEnabled&$top={1}' -f $firstToken, $searchLimit)
        }
    }

    $response = Invoke-GraphApiRequest -Method 'GET' -Uri $uri
    $users = @(Get-EligibleDirectoryUsers -Users (@($response.value | ForEach-Object { ConvertTo-DirectoryUserRecord -User $_ }) | Where-Object { $null -ne $_ }))

    $normalisedQuery = $Query.Trim().ToLower()
    if ($SearchMode -eq 'ExactUpn') {
        $matchedUsers = @($users | Where-Object {
                $upn = $_.UserPrincipalName.ToLower()
                $localPart = $upn.Split('@')[0]
                $upn -eq $normalisedQuery -or $localPart -eq $normalisedQuery -or $upn -like ('{0}@*' -f $normalisedQuery)
            } | Sort-Object DisplayName, UserPrincipalName)
        return , $matchedUsers
    }

    $matchedUsers = @($users | Sort-Object {
            if ($_.DisplayName.ToLower().Contains($normalisedQuery)) { 0 }
            elseif ($_.UserPrincipalName.ToLower().Contains($normalisedQuery)) { 1 }
            else { 2 }
        }, DisplayName, UserPrincipalName)
    return , $matchedUsers
}

function Select-UserFromResults {
    param(
        [AllowNull()]
        [AllowEmptyCollection()]
        [object[]]$Users,
        [Parameter(Mandatory)][string]$Heading
    )
    $sortedUsers = if ($null -eq $Users) { @() } else { @($Users | Where-Object { $null -ne $_ } | Sort-Object DisplayName, UserPrincipalName) }
    if ($sortedUsers.Count -eq 0) {
        Write-Host 'No active C/E user accounts matched that selection.'
        return $null
    }

    Write-Host ''
    Write-Host $Heading
    for ($index = 0; $index -lt $sortedUsers.Count; $index++) {
        Write-Host ('{0}. {1} <{2}>' -f ($index + 1), $sortedUsers[$index].DisplayName, $sortedUsers[$index].UserPrincipalName)
    }

    $selection = Read-ValidatedInput -Prompt 'Choose user number (0 to cancel)' -Default '0' -Type 'Int'
    if ([int]$selection -eq 0) { return $null }
    $selectedIndex = [int]$selection - 1
    if ($selectedIndex -lt 0 -or $selectedIndex -ge $sortedUsers.Count) {
        Write-Host 'Invalid user selection.'
        return $null
    }
    return $sortedUsers[$selectedIndex]
}

function Select-DirectoryUser {
    while ($true) {
        Write-Host ''
        Write-Host 'Final primary user search (active C/E accounts only):'
        Write-Host '1. Recent users'
        Write-Host '2. Exact username search'
        Write-Host '3. Display name search'
        Write-Host '0. Cancel'

        $selectionMode = Read-ValidatedInput -Prompt 'Choose a search mode' -Default '0' -Type 'Choice' -Choices @('1', '2', '3', '0')
        switch ($selectionMode) {
            '0' { return $null }
            '1' {
                $selectedRecentUser = Resolve-EligibleDirectoryUser -User (Select-UserFromResults -Users (Get-RecentUsers) -Heading 'Recent active C/E users')
                if ($selectedRecentUser) { return $selectedRecentUser }
            }
            '2' {
                $usernameQuery = Read-ValidatedInput -Prompt 'Enter username or full UPN'
                $results = if ($Script:Runtime.IsDemoMode) { Search-DemoDirectoryUsers -SearchMode 'ExactUpn' -Query $usernameQuery } else { Search-LiveDirectoryUsers -SearchMode 'ExactUpn' -Query $usernameQuery }
                $selectedUser = Resolve-EligibleDirectoryUser -User (Select-UserFromResults -Users $results -Heading 'Exact username results')
                if ($selectedUser) { return $selectedUser }
            }
            '3' {
                $nameQuery = Read-ValidatedInput -Prompt 'Enter part of the display name'
                $results = if ($Script:Runtime.IsDemoMode) { Search-DemoDirectoryUsers -SearchMode 'DisplayName' -Query $nameQuery } else { Search-LiveDirectoryUsers -SearchMode 'DisplayName' -Query $nameQuery }
                $selectedUser = Resolve-EligibleDirectoryUser -User (Select-UserFromResults -Users $results -Heading 'Display name results')
                if ($selectedUser) { return $selectedUser }
            }
        }
    }
}

function Resolve-LiveAutopilotDeviceBySerial {
    param([Parameter(Mandatory)][string]$Serial)
    $escapedSerial = $Serial.Replace("'", "''")
    $uri = ('https://graph.microsoft.com/beta/deviceManagement/windowsAutopilotDeviceIdentities?$filter=serialNumber eq ''{0}''' -f $escapedSerial)
    $response = Invoke-GraphApiRequest -Method 'GET' -Uri $uri
    return @($response.value) | Select-Object -First 1
}

function Resolve-LiveManagedDeviceBySerial {
    param([Parameter(Mandatory)][string]$Serial)
    $escapedSerial = $Serial.Replace("'", "''")
    $uri = ('https://graph.microsoft.com/v1.0/deviceManagement/managedDevices?$filter=serialNumber eq ''{0}''&$select=id,deviceName,serialNumber,userPrincipalName,azureADDeviceId' -f $escapedSerial)
    $response = Invoke-GraphApiRequest -Method 'GET' -Uri $uri
    return @($response.value) | Select-Object -First 1
}

function Resolve-LiveEntraDeviceObject {
    param([Parameter(Mandatory)][string]$AzureAdDeviceId)
    $escapedDeviceId = $AzureAdDeviceId.Replace("'", "''")
    $uri = ('https://graph.microsoft.com/v1.0/devices?$filter=deviceId eq ''{0}''&$select=id,displayName,deviceId' -f $escapedDeviceId)
    $response = Invoke-GraphApiRequest -Method 'GET' -Uri $uri
    return @($response.value) | Select-Object -First 1
}

function Get-LiveManagedDevicePrimaryUsers {
    param([Parameter(Mandatory)][string]$ManagedDeviceId)
    $response = Invoke-GraphApiRequest -Method 'GET' -Uri ('https://graph.microsoft.com/v1.0/deviceManagement/managedDevices/{0}/users?$select=id,displayName,userPrincipalName' -f $ManagedDeviceId)
    return @($response.value | ForEach-Object { ConvertTo-DirectoryUserRecord -User $_ }) | Where-Object { $null -ne $_ }
}

function Resolve-LiveAutopilotContext {
    param([Parameter(Mandatory)][AutopilotDeviceRecord]$Device)

    $autopilotDevice = Resolve-LiveAutopilotDeviceBySerial -Serial $Device.Serial
    $managedDevice = Resolve-LiveManagedDeviceBySerial -Serial $Device.Serial
    $entraDevice = $null

    if ($null -ne $autopilotDevice) {
        $Device.AutopilotDeviceId = if ($autopilotDevice.id) { [string]$autopilotDevice.id } else { $Device.AutopilotDeviceId }
        if ($autopilotDevice.groupTag) { $Device.GroupTag = [string]$autopilotDevice.groupTag }
        if ($autopilotDevice.managedDeviceId) { $Device.ManagedDeviceId = [string]$autopilotDevice.managedDeviceId }
        if ($autopilotDevice.displayName) { $Device.IntuneDeviceName = [string]$autopilotDevice.displayName }
        if ($autopilotDevice.azureActiveDirectoryDeviceId) { $Device.AzureAdDeviceId = [string]$autopilotDevice.azureActiveDirectoryDeviceId }
    }

    if ($null -ne $managedDevice) {
        $Device.ManagedDeviceId = if ($managedDevice.id) { [string]$managedDevice.id } else { $Device.ManagedDeviceId }
        if ($managedDevice.deviceName) { $Device.IntuneDeviceName = [string]$managedDevice.deviceName }
        if ($managedDevice.azureADDeviceId) { $Device.AzureAdDeviceId = [string]$managedDevice.azureADDeviceId }
    }

    if ($Device.AzureAdDeviceId) {
        $entraDevice = Resolve-LiveEntraDeviceObject -AzureAdDeviceId $Device.AzureAdDeviceId
        if ($null -ne $entraDevice -and $entraDevice.id) { $Device.EntraDeviceId = [string]$entraDevice.id }
    }

    return [pscustomobject]@{ Autopilot = $autopilotDevice; Managed = $managedDevice; Entra = $entraDevice }
}

function Get-LivePreProvisioningGroup {
    $groupName = Get-ConfiguredPreProvisioningGroupDisplayName
    $escapedGroupName = $groupName.Replace("'", "''")
    $uri = ('https://graph.microsoft.com/v1.0/groups?$filter=displayName eq ''{0}''&$select=id,displayName' -f $escapedGroupName)
    $response = Invoke-GraphApiRequest -Method 'GET' -Uri $uri
    $groups = @($response.value)
    if ($groups.Count -eq 0) { throw ('Group not found: {0}' -f $groupName) }
    if ($groups.Count -gt 1) { throw ('Multiple groups matched display name: {0}' -f $groupName) }
    return $groups[0]
}

function Invoke-LivePrimaryUserAssignment {
    param(
        [Parameter(Mandatory)][AutopilotDeviceRecord]$Device,
        [Parameter(Mandatory)]$User
    )

    [void](Resolve-LiveAutopilotContext -Device $Device)

    $assignmentNotes = [System.Collections.ArrayList]::new()
    $assignmentErrors = [System.Collections.ArrayList]::new()
    $autopilotAssigned = $false
    $managedDeviceAssigned = $false
    $managedDeviceConfirmed = $false
    $resolvedUser = if ($User.Id) { $User } else { Resolve-LiveDirectoryUserRecord -User $User }

    if ($Device.AutopilotDeviceId) {
        try {
            $body = @{ userPrincipalName = [string]$User.UserPrincipalName; addressableUserName = if ($User.DisplayName) { [string]$User.DisplayName } else { [string]$User.UserPrincipalName } }
            Invoke-GraphApiRequest -Method 'POST' -Uri ('https://graph.microsoft.com/v1.0/deviceManagement/windowsAutopilotDeviceIdentities/{0}/assignUserToDevice' -f $Device.AutopilotDeviceId) -Body $body | Out-Null
            $autopilotAssigned = $true
            [void]$assignmentNotes.Add(('Autopilot assigned user set to {0}.' -f $User.UserPrincipalName))
        }
        catch {
            [void]$assignmentErrors.Add(('Autopilot user assignment failed: {0}' -f $_.Exception.Message))
        }
    }
    else {
        [void]$assignmentNotes.Add('Autopilot device identity was not available for assignUserToDevice.')
    }

    if ($Device.ManagedDeviceId) {
        if ($null -eq $resolvedUser -or [string]::IsNullOrWhiteSpace([string]$resolvedUser.Id)) {
            [void]$assignmentNotes.Add('Managed-device primary-user association was skipped because the selected user ID could not be resolved.')
        }
        else {
            try {
                $existingUsers = @(Get-LiveManagedDevicePrimaryUsers -ManagedDeviceId $Device.ManagedDeviceId)
                $alreadyAssigned = @($existingUsers | Where-Object {
                        ($_.Id -and $resolvedUser.Id -and $_.Id -eq $resolvedUser.Id) -or
                        ($_.UserPrincipalName -and $resolvedUser.UserPrincipalName -and $_.UserPrincipalName.ToLower() -eq $resolvedUser.UserPrincipalName.ToLower())
                    }).Count -gt 0

                if ($alreadyAssigned) {
                    $managedDeviceAssigned = $true
                    $managedDeviceConfirmed = $true
                    [void]$assignmentNotes.Add(('Managed-device primary-user relationship already included {0}.' -f $resolvedUser.UserPrincipalName))
                }
                else {
                    $body = @{ '@odata.id' = ('https://graph.microsoft.com/v1.0/users/{0}' -f $resolvedUser.Id) }
                    Invoke-GraphApiRequest -Method 'POST' -Uri ('https://graph.microsoft.com/v1.0/deviceManagement/managedDevices(''{0}'')/users/$ref' -f $Device.ManagedDeviceId) -Body $body | Out-Null
                    $managedDeviceAssigned = $true

                    $updatedUsers = @(Get-LiveManagedDevicePrimaryUsers -ManagedDeviceId $Device.ManagedDeviceId)
                    $managedDeviceConfirmed = @($updatedUsers | Where-Object {
                            ($_.Id -and $resolvedUser.Id -and $_.Id -eq $resolvedUser.Id) -or
                            ($_.UserPrincipalName -and $resolvedUser.UserPrincipalName -and $_.UserPrincipalName.ToLower() -eq $resolvedUser.UserPrincipalName.ToLower())
                        }).Count -gt 0

                    if ($managedDeviceConfirmed) {
                        [void]$assignmentNotes.Add(('Managed-device primary-user relationship updated to include {0}.' -f $resolvedUser.UserPrincipalName))
                    }
                    else {
                        [void]$assignmentNotes.Add(('Managed-device primary-user update for {0} was submitted and may take several minutes to appear.' -f $resolvedUser.UserPrincipalName))
                    }
                }
            }
            catch {
                [void]$assignmentErrors.Add(('Managed-device primary-user update failed: {0}' -f $_.Exception.Message))
            }
        }
    }
    else {
        [void]$assignmentNotes.Add('Managed device record was not available yet, so only the Autopilot user assignment surface was attempted.')
    }

    return [pscustomobject]@{
        User                   = $resolvedUser
        AutopilotAssigned      = $autopilotAssigned
        ManagedDeviceAssigned  = $managedDeviceAssigned
        ManagedDeviceConfirmed = $managedDeviceConfirmed
        AnyAssignmentApplied   = ($autopilotAssigned -or $managedDeviceAssigned)
        Notes                  = @($assignmentNotes)
        Errors                 = @($assignmentErrors)
    }
}

function Invoke-StepResolveAutopilotDevice {
    param([Parameter(Mandatory)][AutopilotDeviceRecord]$Device, [Parameter(Mandatory)]$StepDefinition)

    if ($Script:Runtime.IsDemoMode) {
        $Device.AutopilotDeviceId = [guid]::NewGuid().Guid
        $Device.ManagedDeviceId = [guid]::NewGuid().Guid
        $Device.AzureAdDeviceId = [guid]::NewGuid().Guid
        $Device.EntraDeviceId = [guid]::NewGuid().Guid
        $Device.IntuneDeviceName = ('DEMO-{0}' -f $Device.Serial)
        return New-OperationResult -ActionName $StepDefinition.ActionName -Success $true -Summary 'Simulated Autopilot lookup completed.' -Notes 'Demo mode created synthetic Autopilot, Intune, and Entra identifiers.' -Data @{ Serial = $Device.Serial; IntuneDeviceName = $Device.IntuneDeviceName }
    }

    $context = Resolve-LiveAutopilotContext -Device $Device
    if ($null -ne $context.Autopilot) {
        return New-OperationResult -ActionName $StepDefinition.ActionName -Success $true -Summary 'Autopilot device context loaded.' -Notes ('Resolved Autopilot device and refreshed associated Intune/Entra identifiers for serial {0}.' -f $Device.Serial) -Data @{ AutopilotDeviceId = $Device.AutopilotDeviceId; ManagedDeviceId = $Device.ManagedDeviceId; EntraDeviceId = $Device.EntraDeviceId }
    }

    Write-Host (Get-ConfiguredMissingSerialHandoffNote)
    $handoffConfirmed = Read-ValidatedInput -Prompt 'Autopilot serial not found. Has the external upload-guide hand-off been completed? (Y/N)' -Default 'N' -Type 'Choice' -Choices @('Y', 'N')
    if ($handoffConfirmed.ToUpper() -eq 'Y') {
        return New-OperationResult -ActionName $StepDefinition.ActionName -Success $true -Summary 'Autopilot serial not found; hand-off recorded.' -Notes (Get-ConfiguredMissingSerialHandoffNote) -Data @{ Serial = $Device.Serial }
    }

    return New-OperationResult -ActionName $StepDefinition.ActionName -Success $false -Summary 'Autopilot serial could not be resolved.' -Notes 'Complete the external upload-guide hand-off before continuing.' -Data @{ Serial = $Device.Serial }
}

function Invoke-StepRemoveAssociatedManagedDevice {
    param([Parameter(Mandatory)][AutopilotDeviceRecord]$Device, [Parameter(Mandatory)]$StepDefinition)

    if ($Script:Runtime.IsDemoMode) {
        $Device.ManagedDeviceId = ''
        $Device.IntuneDeviceName = ''
        return New-OperationResult -ActionName $StepDefinition.ActionName -Success $true -Summary 'Simulated Intune device removal completed.' -Notes 'Demo mode cleared the associated Intune device context.' -Data @{ Serial = $Device.Serial }
    }

    if (-not $Device.ManagedDeviceId) {
        $context = Resolve-LiveAutopilotContext -Device $Device
        if ($null -eq $context.Managed) {
            return New-OperationResult -ActionName $StepDefinition.ActionName -Success $true -Summary 'No associated Intune device was present.' -Notes 'Nothing needed to be deleted for this serial.' -Data @{ Serial = $Device.Serial }
        }
    }

    $managedDeviceDisplay = if ($Device.IntuneDeviceName) { $Device.IntuneDeviceName } else { $Device.ManagedDeviceId }
    $confirmDelete = Read-ValidatedInput -Prompt ('Delete associated Intune device {0}? (Y/N)' -f $managedDeviceDisplay) -Default 'Y' -Type 'Choice' -Choices @('Y', 'N')
    if ($confirmDelete.ToUpper() -ne 'Y') {
        return New-OperationResult -ActionName $StepDefinition.ActionName -Success $false -Summary 'Managed-device deletion cancelled.' -Notes 'The associated Intune device was not deleted.' -Data @{ ManagedDeviceId = $Device.ManagedDeviceId }
    }

    try {
        if (Get-Command -Name Remove-MgDeviceManagementManagedDevice -ErrorAction SilentlyContinue) {
            Remove-MgDeviceManagementManagedDevice -ManagedDeviceId $Device.ManagedDeviceId -ErrorAction Stop
        }
        else {
            Invoke-GraphApiRequest -Method 'DELETE' -Uri ('https://graph.microsoft.com/v1.0/deviceManagement/managedDevices/{0}' -f $Device.ManagedDeviceId) | Out-Null
        }
        $Device.ManagedDeviceId = ''
        $Device.IntuneDeviceName = ''
        return New-OperationResult -ActionName $StepDefinition.ActionName -Success $true -Summary 'Associated Intune device deleted.' -Notes 'The existing managed device record was removed successfully.' -Data @{ Serial = $Device.Serial }
    }
    catch {
        return New-OperationResult -ActionName $StepDefinition.ActionName -Success $false -Summary 'Failed to delete associated Intune device.' -Notes $_.Exception.Message -Data @{ ManagedDeviceId = $Device.ManagedDeviceId }
    }
}

function Invoke-StepApplyGroupTag {
    param([Parameter(Mandatory)][AutopilotDeviceRecord]$Device, [Parameter(Mandatory)]$StepDefinition)

    $expectedTag = ('{0}-{1}' -f $Device.SiteCode, ($Device.DeviceType -replace '\s', ''))
    if ($Script:Runtime.IsDemoMode) {
        $Device.GroupTag = $expectedTag
        return New-OperationResult -ActionName $StepDefinition.ActionName -Success $true -Summary 'Simulated Group Tag update completed.' -Notes ('Demo mode applied the expected Group Tag {0}.' -f $expectedTag) -Data @{ GroupTag = $expectedTag }
    }

    if (-not $Device.AutopilotDeviceId) {
        $context = Resolve-LiveAutopilotContext -Device $Device
        if ($null -eq $context.Autopilot) {
            return New-OperationResult -ActionName $StepDefinition.ActionName -Success $false -Summary 'Autopilot device context is required before updating Group Tag.' -Notes 'Run the resolve step first.' -Data @{}
        }
    }

    try {
        if (Get-Command -Name Update-MgDeviceManagementWindowsAutopilotDeviceIdentityDeviceProperty -ErrorAction SilentlyContinue) {
            Update-MgDeviceManagementWindowsAutopilotDeviceIdentityDeviceProperty -WindowsAutopilotDeviceIdentityId $Device.AutopilotDeviceId -BodyParameter @{ groupTag = $expectedTag } -ErrorAction Stop | Out-Null
        }
        else {
            Invoke-GraphApiRequest -Method 'POST' -Uri ('https://graph.microsoft.com/beta/deviceManagement/windowsAutopilotDeviceIdentities/{0}/updateDeviceProperties' -f $Device.AutopilotDeviceId) -Body @{ groupTag = $expectedTag } | Out-Null
        }
        $Device.GroupTag = $expectedTag
        return New-OperationResult -ActionName $StepDefinition.ActionName -Success $true -Summary 'Group Tag updated.' -Notes ('Applied Group Tag {0} to the Autopilot device.' -f $expectedTag) -Data @{ GroupTag = $expectedTag }
    }
    catch {
        return New-OperationResult -ActionName $StepDefinition.ActionName -Success $false -Summary 'Failed to update Group Tag.' -Notes $_.Exception.Message -Data @{ GroupTag = $expectedTag }
    }
}

function Invoke-StepValidateDeploymentProfile {
    param([Parameter(Mandatory)][AutopilotDeviceRecord]$Device, [Parameter(Mandatory)]$StepDefinition)

    $profileName = Get-ConfiguredDeploymentProfileDisplayName
    if ($Script:Runtime.IsDemoMode) {
        return New-OperationResult -ActionName $StepDefinition.ActionName -Success $true -Summary 'Simulated deployment-profile validation completed.' -Notes ('Demo mode validated profile {0}.' -f $profileName) -Data @{ DeploymentProfile = $profileName }
    }

    Write-Host ('Validate in Intune that deployment profile "{0}" is assigned to this device.' -f $profileName)
    $confirmed = Read-ValidatedInput -Prompt 'Was the required deployment profile confirmed? (Y/N)' -Default 'Y' -Type 'Choice' -Choices @('Y', 'N')
    return New-OperationResult -ActionName $StepDefinition.ActionName -Success ($confirmed.ToUpper() -eq 'Y') -Summary 'Deployment-profile validation recorded.' -Notes ('Technician confirmation for profile {0}: {1}' -f $profileName, $confirmed.ToUpper()) -Data @{ DeploymentProfile = $profileName }
}

function Invoke-StepAddPreProvisioningGroup {
    param([Parameter(Mandatory)][AutopilotDeviceRecord]$Device, [Parameter(Mandatory)]$StepDefinition)

    $groupName = Get-ConfiguredPreProvisioningGroupDisplayName
    if ($Script:Runtime.IsDemoMode) {
        return New-OperationResult -ActionName $StepDefinition.ActionName -Success $true -Summary 'Simulated pre-provisioning group add completed.' -Notes ('Demo mode added the device to {0}.' -f $groupName) -Data @{ Group = $groupName }
    }

    if (-not $Device.EntraDeviceId) {
        [void](Resolve-LiveAutopilotContext -Device $Device)
    }
    if (-not $Device.EntraDeviceId) {
        return New-OperationResult -ActionName $StepDefinition.ActionName -Success $false -Summary 'Entra device object ID could not be resolved.' -Notes 'Resolve the Autopilot device before changing group membership.' -Data @{}
    }

    try {
        $group = Get-LivePreProvisioningGroup
        $body = @{ '@odata.id' = ('https://graph.microsoft.com/v1.0/directoryObjects/{0}' -f $Device.EntraDeviceId) }
        Invoke-GraphApiRequest -Method 'POST' -Uri ('https://graph.microsoft.com/v1.0/groups/{0}/members/$ref' -f $group.id) -Body $body | Out-Null
        return New-OperationResult -ActionName $StepDefinition.ActionName -Success $true -Summary 'Device added to pre-provisioning group.' -Notes ('Added Entra device object {0} to {1}.' -f $Device.EntraDeviceId, $group.displayName) -Data @{ Group = $group.displayName }
    }
    catch {
        if ($_.Exception.Message -match 'already exist') {
            return New-OperationResult -ActionName $StepDefinition.ActionName -Success $true -Summary 'Device was already in the pre-provisioning group.' -Notes $_.Exception.Message -Data @{ Group = $groupName }
        }
        return New-OperationResult -ActionName $StepDefinition.ActionName -Success $false -Summary 'Failed to add device to pre-provisioning group.' -Notes $_.Exception.Message -Data @{ Group = $groupName }
    }
}

function Invoke-StepClearUserlessEnrollmentStatus {
    param([Parameter(Mandatory)][AutopilotDeviceRecord]$Device, [Parameter(Mandatory)]$StepDefinition)

    if ($Script:Runtime.IsDemoMode) {
        return New-OperationResult -ActionName $StepDefinition.ActionName -Success $true -Summary 'Simulated userless-enrolment unblock completed.' -Notes 'Demo mode cleared the userless-enrolment status gate.' -Data @{}
    }

    if (-not $Device.AutopilotDeviceId) {
        [void](Resolve-LiveAutopilotContext -Device $Device)
    }
    if (-not $Device.AutopilotDeviceId) {
        return New-OperationResult -ActionName $StepDefinition.ActionName -Success $false -Summary 'Autopilot device context is required before clearing Userless Enrolment Status.' -Notes 'Run the resolve step first so the Autopilot device identity is available.' -Data @{}
    }

    try {
        Invoke-GraphApiRequest -Method 'POST' -Uri ('https://graph.microsoft.com/beta/deviceManagement/windowsAutopilotDeviceIdentities/{0}/allowNextEnrollment' -f $Device.AutopilotDeviceId) | Out-Null
        return New-OperationResult -ActionName $StepDefinition.ActionName -Success $true -Summary 'Userless-enrolment status block cleared.' -Notes ('Invoked allowNextEnrollment for Autopilot device {0}.' -f $Device.AutopilotDeviceId) -Data @{ AutopilotDeviceId = $Device.AutopilotDeviceId }
    }
    catch {
        return New-OperationResult -ActionName $StepDefinition.ActionName -Success $false -Summary 'Failed to clear Userless Enrolment Status block.' -Notes $_.Exception.Message -Data @{ AutopilotDeviceId = $Device.AutopilotDeviceId }
    }
}

function Invoke-StepAssignTechnicianPrimaryUser {
    param([Parameter(Mandatory)][AutopilotDeviceRecord]$Device, [Parameter(Mandatory)]$StepDefinition)

    $technicianUpn = $Script:GraphSession.Account
    $technicianUser = [pscustomobject]@{
        Id                = [string]$Script:GraphSession.UserId
        DisplayName       = [string]$Script:GraphSession.DisplayName
        UserPrincipalName = [string]$technicianUpn
        AccountEnabled    = $true
    }
    $eligibilityMessage = Get-DirectoryUserEligibilityMessage -User $technicianUser

    if (-not [string]::IsNullOrWhiteSpace($eligibilityMessage)) {
        return New-OperationResult -ActionName $StepDefinition.ActionName -Success $false -Summary 'The authenticated technician account is not permitted for technician-primary-user assignment.' -Notes ('Current account {0} does not match the configured prefixes: {1}' -f $technicianUpn, ((Get-ConfiguredTechnicianPrefixes) -join ', ')) -Data @{}
    }

    $Device.TechnicianUserPrincipalName = $technicianUpn
    if ($Script:Runtime.IsDemoMode) {
        return New-OperationResult -ActionName $StepDefinition.ActionName -Success $true -Summary 'Simulated technician primary-user assignment completed.' -Notes ('Demo mode assigned technician {0} on both Autopilot and managed-device surfaces.' -f $technicianUpn) -Data @{ Technician = $technicianUpn; AutopilotAssigned = $true; ManagedDeviceAssigned = $true }
    }

    $assignment = Invoke-LivePrimaryUserAssignment -Device $Device -User $technicianUser
    if (-not $assignment.AnyAssignmentApplied) {
        return New-OperationResult -ActionName $StepDefinition.ActionName -Success $false -Summary 'No technician primary-user assignment target was available.' -Notes ((@($assignment.Notes) + @($assignment.Errors)) -join ' ') -Data @{ Technician = $technicianUpn }
    }

    if ($assignment.Errors.Count -gt 0) {
        return New-OperationResult -ActionName $StepDefinition.ActionName -Success $false -Summary 'Technician primary-user assignment failed.' -Notes ((@($assignment.Notes) + @($assignment.Errors)) -join ' ') -Data @{ Technician = $technicianUpn; AutopilotAssigned = $assignment.AutopilotAssigned; ManagedDeviceAssigned = $assignment.ManagedDeviceAssigned }
    }

    if ($assignment.ManagedDeviceAssigned -and -not $assignment.ManagedDeviceConfirmed) {
        $confirmed = Read-ValidatedInput -Prompt 'Managed-device primary-user update was submitted. Has Intune reflected the technician yet? (Y/N)' -Default 'Y' -Type 'Choice' -Choices @('Y', 'N')
        $success = $confirmed.ToUpper() -eq 'Y'
        $summary = if ($success) { 'Technician primary-user assignment completed.' } else { 'Technician primary-user assignment submitted but not yet confirmed.' }
        $notes = @($assignment.Notes)
        $notes += ('Technician confirmation: {0}' -f $confirmed.ToUpper())
        return New-OperationResult -ActionName $StepDefinition.ActionName -Success $success -Summary $summary -Notes ($notes -join ' ') -Data @{ Technician = $technicianUpn; AutopilotAssigned = $assignment.AutopilotAssigned; ManagedDeviceAssigned = $assignment.ManagedDeviceAssigned }
    }

    return New-OperationResult -ActionName $StepDefinition.ActionName -Success $true -Summary 'Technician primary-user assignment completed.' -Notes (@($assignment.Notes) -join ' ') -Data @{ Technician = $technicianUpn; AutopilotAssigned = $assignment.AutopilotAssigned; ManagedDeviceAssigned = $assignment.ManagedDeviceAssigned }
}

function Invoke-StepRetryFailedApps {
    param([Parameter(Mandatory)][AutopilotDeviceRecord]$Device, [Parameter(Mandatory)]$StepDefinition)

    if ($Script:Runtime.IsDemoMode) {
        return New-OperationResult -ActionName $StepDefinition.ActionName -Success $true -Summary 'Simulated app retry completed.' -Notes 'Demo mode simulated Intune app remediation and retry.' -Data @{}
    }

    if (-not $Device.ManagedDeviceId) {
        [void](Resolve-LiveAutopilotContext -Device $Device)
    }
    if (-not $Device.ManagedDeviceId) {
        return New-OperationResult -ActionName $StepDefinition.ActionName -Success $false -Summary 'Managed device context is required before retrying app installations.' -Notes 'Resolve the device first, or confirm the managed device exists in Intune.' -Data @{}
    }

    try {
        Invoke-GraphApiRequest -Method 'POST' -Uri ('https://graph.microsoft.com/v1.0/deviceManagement/managedDevices/{0}/syncDevice' -f $Device.ManagedDeviceId) | Out-Null
        $confirmed = Read-ValidatedInput -Prompt 'Was the failed application retry/remediation successful? (Y/N)' -Default 'Y' -Type 'Choice' -Choices @('Y', 'N')
        return New-OperationResult -ActionName $StepDefinition.ActionName -Success ($confirmed.ToUpper() -eq 'Y') -Summary 'App retry workflow recorded.' -Notes ('Issued syncDevice for managed device {0}; technician confirmation {1}.' -f $Device.ManagedDeviceId, $confirmed.ToUpper()) -Data @{ ManagedDeviceId = $Device.ManagedDeviceId }
    }
    catch {
        return New-OperationResult -ActionName $StepDefinition.ActionName -Success $false -Summary 'Failed to trigger managed-device sync.' -Notes $_.Exception.Message -Data @{ ManagedDeviceId = $Device.ManagedDeviceId }
    }
}

function Invoke-StepRemovePreProvisioningGroup {
    param([Parameter(Mandatory)][AutopilotDeviceRecord]$Device, [Parameter(Mandatory)]$StepDefinition)

    $groupName = Get-ConfiguredPreProvisioningGroupDisplayName
    if ($Script:Runtime.IsDemoMode) {
        return New-OperationResult -ActionName $StepDefinition.ActionName -Success $true -Summary 'Simulated pre-provisioning group removal completed.' -Notes ('Demo mode removed the device from {0}.' -f $groupName) -Data @{ Group = $groupName }
    }

    if (-not $Device.EntraDeviceId) {
        [void](Resolve-LiveAutopilotContext -Device $Device)
    }
    if (-not $Device.EntraDeviceId) {
        return New-OperationResult -ActionName $StepDefinition.ActionName -Success $false -Summary 'Entra device object ID could not be resolved.' -Notes 'Resolve the Autopilot device before changing group membership.' -Data @{}
    }

    try {
        $group = Get-LivePreProvisioningGroup
        Invoke-GraphApiRequest -Method 'DELETE' -Uri ('https://graph.microsoft.com/v1.0/groups/{0}/members/{1}/$ref' -f $group.id, $Device.EntraDeviceId) | Out-Null
        return New-OperationResult -ActionName $StepDefinition.ActionName -Success $true -Summary 'Device removed from pre-provisioning group.' -Notes ('Removed Entra device object {0} from {1}.' -f $Device.EntraDeviceId, $group.displayName) -Data @{ Group = $group.displayName }
    }
    catch {
        if ($_.Exception.Message -match 'does not exist' -or $_.Exception.Message -match 'Resource .* was not found') {
            return New-OperationResult -ActionName $StepDefinition.ActionName -Success $true -Summary 'Device was not present in the pre-provisioning group.' -Notes $_.Exception.Message -Data @{ Group = $groupName }
        }
        return New-OperationResult -ActionName $StepDefinition.ActionName -Success $false -Summary 'Failed to remove device from pre-provisioning group.' -Notes $_.Exception.Message -Data @{ Group = $groupName }
    }
}

function Invoke-StepAssignFinalPrimaryUser {
    param([Parameter(Mandatory)][AutopilotDeviceRecord]$Device, [Parameter(Mandatory)]$StepDefinition)

    $selectedUser = Select-DirectoryUser
    if (-not $selectedUser) {
        return New-OperationResult -ActionName $StepDefinition.ActionName -Success $false -Summary 'Final primary-user selection was cancelled.' -Notes 'No user was selected.' -Data @{}
    }

    $Device.FinalPrimaryUserId = [string]$selectedUser.Id
    $Device.FinalPrimaryUserPrincipalName = [string]$selectedUser.UserPrincipalName
    $Device.FinalPrimaryUserDisplayName = [string]$selectedUser.DisplayName
    Add-RecentUser -User $selectedUser

    if ($Script:Runtime.IsDemoMode) {
        return New-OperationResult -ActionName $StepDefinition.ActionName -Success $true -Summary 'Simulated final primary-user assignment completed.' -Notes ('Demo mode assigned final primary user {0} on both Autopilot and managed-device surfaces.' -f $selectedUser.UserPrincipalName) -Data @{ FinalPrimaryUser = $selectedUser.UserPrincipalName; AutopilotAssigned = $true; ManagedDeviceAssigned = $true }
    }

    $assignment = Invoke-LivePrimaryUserAssignment -Device $Device -User $selectedUser
    if (-not $assignment.AnyAssignmentApplied) {
        return New-OperationResult -ActionName $StepDefinition.ActionName -Success $false -Summary 'No final primary-user assignment target was available.' -Notes ((@($assignment.Notes) + @($assignment.Errors)) -join ' ') -Data @{ FinalPrimaryUser = $selectedUser.UserPrincipalName }
    }

    if ($assignment.Errors.Count -gt 0) {
        return New-OperationResult -ActionName $StepDefinition.ActionName -Success $false -Summary 'Final primary-user assignment failed.' -Notes ((@($assignment.Notes) + @($assignment.Errors)) -join ' ') -Data @{ FinalPrimaryUser = $selectedUser.UserPrincipalName; AutopilotAssigned = $assignment.AutopilotAssigned; ManagedDeviceAssigned = $assignment.ManagedDeviceAssigned }
    }

    if ($assignment.ManagedDeviceAssigned -and -not $assignment.ManagedDeviceConfirmed) {
        $confirmed = Read-ValidatedInput -Prompt 'Managed-device primary-user update was submitted. Has Intune reflected the final user yet? (Y/N)' -Default 'Y' -Type 'Choice' -Choices @('Y', 'N')
        $success = $confirmed.ToUpper() -eq 'Y'
        $summary = if ($success) { 'Final primary-user assignment completed.' } else { 'Final primary-user assignment submitted but not yet confirmed.' }
        $notes = @($assignment.Notes)
        $notes += ('Technician confirmation: {0}' -f $confirmed.ToUpper())
        return New-OperationResult -ActionName $StepDefinition.ActionName -Success $success -Summary $summary -Notes ($notes -join ' ') -Data @{ FinalPrimaryUser = $selectedUser.UserPrincipalName; AutopilotAssigned = $assignment.AutopilotAssigned; ManagedDeviceAssigned = $assignment.ManagedDeviceAssigned }
    }

    return New-OperationResult -ActionName $StepDefinition.ActionName -Success $true -Summary 'Final primary-user assignment completed.' -Notes (@($assignment.Notes) -join ' ') -Data @{ FinalPrimaryUser = $selectedUser.UserPrincipalName; AutopilotAssigned = $assignment.AutopilotAssigned; ManagedDeviceAssigned = $assignment.ManagedDeviceAssigned }
}

function Invoke-AutopilotManifestStep {
    param(
        [Parameter(Mandatory)][AutopilotDeviceRecord]$Device,
        [Parameter(Mandatory)]$StepDefinition
    )

    switch ($StepDefinition.ActionName) {
        'ResolveAutopilotDevice' { return Invoke-StepResolveAutopilotDevice -Device $Device -StepDefinition $StepDefinition }
        'RemoveAssociatedManagedDevice' { return Invoke-StepRemoveAssociatedManagedDevice -Device $Device -StepDefinition $StepDefinition }
        'ApplyGroupTag' { return Invoke-StepApplyGroupTag -Device $Device -StepDefinition $StepDefinition }
        'ValidateDeploymentProfile' { return Invoke-StepValidateDeploymentProfile -Device $Device -StepDefinition $StepDefinition }
        'AddToPreProvisioningGroup' { return Invoke-StepAddPreProvisioningGroup -Device $Device -StepDefinition $StepDefinition }
        'ClearUserlessEnrollmentStatus' { return Invoke-StepClearUserlessEnrollmentStatus -Device $Device -StepDefinition $StepDefinition }
        'AssignTechnicianPrimaryUser' { return Invoke-StepAssignTechnicianPrimaryUser -Device $Device -StepDefinition $StepDefinition }
        'RetryFailedApplications' { return Invoke-StepRetryFailedApps -Device $Device -StepDefinition $StepDefinition }
        'RemoveFromPreProvisioningGroup' { return Invoke-StepRemovePreProvisioningGroup -Device $Device -StepDefinition $StepDefinition }
        'AssignFinalPrimaryUser' { return Invoke-StepAssignFinalPrimaryUser -Device $Device -StepDefinition $StepDefinition }
        default {
            return New-OperationResult -ActionName $StepDefinition.ActionName -Success $false -Summary 'Manifest action is not yet implemented.' -Notes ('No step handler exists for action {0}.' -f $StepDefinition.ActionName) -Data @{}
        }
    }
}

function Write-ManifestStepResult {
    param(
        [Parameter(Mandatory)][AutopilotDeviceRecord]$Device,
        [Parameter(Mandatory)]$StepDefinition,
        [Parameter(Mandatory)]$Result
    )

    $stepWasPreviouslyCompleted = Test-ManifestStepCompleted -Device $Device -StepId $StepDefinition.Id

    $Device.Steps[$StepDefinition.Id] = @{
        Completed   = ($stepWasPreviouslyCompleted -or $Result.Success)
        Success     = $Result.Success
        Timestamp   = Get-Date
        Summary     = $Result.Summary
        Notes       = $Result.Notes
        Mode        = $Script:Runtime.ModeDisplayName
        ActionName  = $Result.ActionName
        IsSimulated = $Result.IsSimulated
        Data        = ConvertTo-NormalisedValue -Value $Result.Data
    }

    if ($Result.Success -and $Device.Status -eq 'new') { $Device.Status = 'in-progress' }
    $Device.LastUpdatedAt = Get-Date
    $Device.LastUpdatedBy = $env:USERNAME

    if (-not (Get-NextStepId -Device $Device)) {
        $Device.Status = 'completed'
        if (-not $Device.CompletedAt -or $Device.CompletedAt -eq [DateTime]::MinValue) { $Device.CompletedAt = Get-Date }
        if (-not $Device.CompletedBy) { $Device.CompletedBy = $env:USERNAME }
    }
}

function New-BuildBench {
    param([int]$Positions)
    if ($Positions -lt 1 -or $Positions -gt 50) { Write-Host 'Positions must be between 1 and 50.'; return }
    $Script:BuildBench.Positions = @(); for ($i = 1; $i -le $Positions; $i++) { $Script:BuildBench.Positions += [ordered]@{ Index = $i; Serial = $null; ConfigItem = $null } }
    $Script:BuildBench.Active = $true
    Write-AutopilotExpressLog -Message ('Build bench initialised with {0} positions.' -f $Positions) -Level 'INFO'
}

function Test-ManifestStepAttempted {
    param(
        [Parameter(Mandatory)][AutopilotDeviceRecord]$Device,
        [Parameter(Mandatory)][string]$StepId
    )
    return $Device.Steps.ContainsKey($StepId)
}

function Test-ManifestStepCompleted {
    param(
        [Parameter(Mandatory)][AutopilotDeviceRecord]$Device,
        [Parameter(Mandatory)][string]$StepId
    )

    if (-not (Test-ManifestStepAttempted -Device $Device -StepId $StepId)) { return $false }
    $stepRecord = $Device.Steps[$StepId]
    if ($null -eq $stepRecord) { return $false }

    if ($stepRecord -is [System.Collections.IDictionary]) {
        if ($stepRecord.Contains('Completed') -and $null -ne $stepRecord['Completed']) { return [bool]$stepRecord['Completed'] }
        if ($stepRecord.Contains('Success') -and $null -ne $stepRecord['Success']) { return [bool]$stepRecord['Success'] }
    }

    if ($stepRecord.PSObject.Properties.Name -contains 'Completed' -and $null -ne $stepRecord.Completed) { return [bool]$stepRecord.Completed }
    if ($stepRecord.PSObject.Properties.Name -contains 'Success' -and $null -ne $stepRecord.Success) { return [bool]$stepRecord.Success }
    return $false
}

function Get-NextStepId {
    param([AutopilotDeviceRecord]$Device)
    $enabledStepIds = Get-EnabledManifestSteps | ForEach-Object { $_.Id }
    foreach ($stepId in $enabledStepIds) {
        if (-not (Test-ManifestStepCompleted -Device $Device -StepId $stepId)) { return $stepId }
    }
    return $null
}

function Add-DeviceToBenchPosition {
    param([int]$Position, [string]$Serial, [string]$ConfigItem, [ref]$Records, [string]$SiteCode, [string]$DeviceType)
    $slot = $Script:BuildBench.Positions | Where-Object { $_.Index -eq $Position }; if (-not $slot) { Write-Host 'Invalid position.'; return }
    $existing = $Records.Value | Where-Object { $_.Serial -eq $Serial }
    if (-not $existing) {
        $expectedTag = ('{0}-{1}' -f $SiteCode, ($DeviceType -replace '\s', ''))
        $rec = New-DeviceRecordObject -Serial $Serial -ConfigItem $ConfigItem -SiteCode $SiteCode -DeviceType $DeviceType -GroupTag $expectedTag
        Add-DeviceRecord -Records $Records -Record $rec
    }
    $slot.Serial = $Serial; $slot.ConfigItem = $ConfigItem
    Write-UserDeviceRecords -Records $Records.Value
    Save-BuildBenchState
}

function Remove-DeviceFromBenchPosition { param([int]$Position) $slot = $Script:BuildBench.Positions | Where-Object { $_.Index -eq $Position }; if (-not $slot) { Write-Host 'Invalid position.'; return }; $slot.Serial = $null; $slot.ConfigItem = $null }

# Ensure that any devices shown in the bench positions exist in the per-user records
function Sync-BenchRecords {
    param([ref]$Records)
    if (-not $Script:BuildBench -or -not $Script:BuildBench.Positions) { return }
    $site = $Script:BuildBench.SiteCode
    $dtype = $Script:BuildBench.DeviceType
    foreach ($slot in $Script:BuildBench.Positions) {
        if (-not $slot.Serial) { continue }
        $existing = $Records.Value | Where-Object { $_.Serial -eq $slot.Serial }
        if (-not $existing) {
            $expectedTag = if ($site -and $dtype) { ('{0}-{1}' -f $site, ($dtype -replace '\s', '')) } else { $null }
            $rec = New-DeviceRecordObject -Serial $slot.Serial -ConfigItem $slot.ConfigItem -SiteCode $site -DeviceType $dtype -GroupTag $expectedTag
            Add-DeviceRecord -Records $Records -Record $rec
        }
    }
    Write-UserDeviceRecords -Records $Records.Value
}

function Show-BuildBenchTable {
    param([ref]$Records)
    # Column widths to preserve alignment; ellipsise long content
    $labelWidth = 10
    $colWidth = 14
    function FormatCell([string]$text, [int]$width) {
        if ($null -eq $text) { $text = '' }
        $t = [string]$text
        if ($t.Length -gt $width) { $t = $t.Substring(0, $width - 1) + '…' }
        return $t.PadRight($width)
    }
    function CenterCell([string]$text, [int]$width) {
        if ($null -eq $text) { $text = '' }
        $t = [string]$text
        if ($t.Length -gt $width) { $t = $t.Substring(0, $width - 1) + '…' }
        $padTotal = $width - $t.Length
        if ($padTotal -le 0) { return $t }
        $left = [math]::Floor($padTotal / 2)
        $right = $padTotal - $left
        return ('{0}{1}{2}' -f (' ' * $left), $t, (' ' * $right))
    }
    function BuildRow([string]$label, [string[]]$values, [bool]$centerValues) {
        $row = '|' + ' ' + ($label.PadRight($labelWidth)) + ' '
        foreach ($v in $values) {
            $cellText = if ($centerValues) { CenterCell -text $v -width $colWidth } else { FormatCell -text $v -width $colWidth }
            $row += ('| {0} ' -f $cellText)
        }
        $row += '|'
        return $row
    }
    # Determine how many columns fit the current window
    $winWidth = 120
    try { if ($Host -and $Host.UI -and $Host.UI.RawUI) { $winWidth = [math]::Max(50, $Host.UI.RawUI.WindowSize.Width) } } catch { $winWidth = 120 }
    $baseLen = $labelWidth + 3 + 1  # label plus separators and final '|'
    $perCol = $colWidth + 3         # "| {col} " per column
    $maxCols = [math]::Floor(($winWidth - $baseLen) / $perCol)
    if ($maxCols -lt 1) { $maxCols = 1 }
    $colsPerRow = [math]::Min(8, $maxCols)
    $positions = $Script:BuildBench.Positions
    $chunks = @()
    for ($i = 0; $i -lt $positions.Count; $i += $colsPerRow) { $chunks += , (@($positions[$i..([Math]::Min($i + $colsPerRow - 1, $positions.Count - 1))])) }
    foreach ($chunk in $chunks) {
        $posLabels = $chunk | ForEach-Object { $_.Index.ToString() }
        $lineSample = BuildRow -label 'Position' -values $posLabels -centerValues $true
        $rule = '-' * $lineSample.Length
        Write-Host $rule
        Write-Host $lineSample
        Write-Host $rule
        $serialVals = $chunk | ForEach-Object { if ($_.Serial) { $_.Serial } else { '' } }
        Write-Host (BuildRow -label 'Serial' -values $serialVals -centerValues $false)
        $ciVals = $chunk | ForEach-Object { if ($_.ConfigItem) { $_.ConfigItem } else { '' } }
        Write-Host (BuildRow -label 'CI' -values $ciVals -centerValues $false)
        Write-Host $rule
        $currentVals = @()
        foreach ($slot in $chunk) {
            $val = ''
            if ($slot.Serial) {
                $rec = $Records.Value | Where-Object { $_.Serial -eq $slot.Serial }
                if ($rec -and $rec.Steps.Keys.Count -gt 0) { $val = ($rec.Steps.Keys | Select-Object -Last 1) } else { $val = '' }
            }
            $currentVals += $val
        }
        Write-Host (BuildRow -label 'Current' -values $currentVals -centerValues $false)
        $nextVals = @()
        foreach ($slot in $chunk) {
            $val = ''
            if ($slot.Serial) {
                $rec = $Records.Value | Where-Object { $_.Serial -eq $slot.Serial }
                if ($rec) { $val = Get-NextStepId -Device $rec }
            }
            $nextVals += $val
        }
        Write-Host (BuildRow -label 'Next' -values $nextVals -centerValues $false)
        Write-Host $rule
        Write-Host ''
    }
}

function Show-BuildBenchView {
    param([ref]$Records)
    if (-not $Script:BuildBench.Active) { Write-Host 'Build bench not initialised.'; return }
    function Show-BenchScreen {
        Clear-Host
        # Determine window width for header centring and full-width background
        $winWidth = 120
        try { if ($Host -and $Host.UI -and $Host.UI.RawUI) { $winWidth = [math]::Max(50, $Host.UI.RawUI.WindowSize.Width) } } catch { $winWidth = 120 }
        $title = 'BUILD BENCH MANAGER'
        $padTotal = $winWidth - $title.Length
        if ($padTotal -lt 0) { $padTotal = 0 }
        $left = [math]::Floor($padTotal / 2)
        $right = $padTotal - $left
        $paddedTitle = ('{0}{1}{2}' -f (' ' * $left), $title, (' ' * $right))
        Write-Host $paddedTitle -BackgroundColor DarkBlue -ForegroundColor White
        Write-Host ''
        Show-BuildBenchTable -Records $Records
        if ($Script:BuildBench.Faults -and $Script:BuildBench.Faults.Count -gt 0) {
            Write-Host 'Current faults:'
            foreach ($f in $Script:BuildBench.Faults) { Write-Host $f }
            Write-Host ''
        }
        Write-Host 'Actions:'
        Write-Host '[I]nduct new device   [S]tart Next Step for a device   [V]iew all actions for a device'
        Write-Host '[D]ispatch and finish a device   [R]emove from position   [M]ove device   [E]xit Build Bench view'
        Write-Host ''
        # Hints for open positions
        $open = @($Script:BuildBench.Positions | Where-Object { -not $_.Serial })
        $nextOpen = if ($open.Count -gt 0) { $open[0].Index } else { 'None' }
        $openList = if ($open.Count -gt 0) { @($open | ForEach-Object { $_.Index }) } else { @() }
        $openPreview = if ($openList.Count -gt 0) { ($openList | Select-Object -First 10) -join ', ' } else { 'None' }
        $moreCount = if ($openList.Count -gt 10) { $openList.Count - 10 } else { 0 }
        Write-Host ('Hint: Next open position: {0}' -f $nextOpen)
        if ($moreCount -gt 0) {
            Write-Host ('Open positions: {0} (and {1} more)' -f $openPreview, $moreCount)
        }
        else {
            Write-Host ('Open positions: {0}' -f $openPreview)
        }
        Write-Host 'You can enter a position number, or scan/paste a device Serial/CI at any prompt.'
    }
    Show-BenchScreen
    while ($true) {
        $cmd = Read-ValidatedInput -Prompt 'Command' -AllowEmpty -Default 'E'
        $u = if ([string]::IsNullOrWhiteSpace($cmd)) { 'E' } else { $cmd.Trim().ToUpper() }
        switch ($u) {
            'E' { Save-BuildBenchState; return }
            'I' {
                Clear-Host; Write-Host 'INDUCT NEW DEVICE'
                $max = ($Script:BuildBench.Positions | Measure-Object).Count
                $openSlots = @($Script:BuildBench.Positions | Where-Object { -not $_.Serial })
                if ($openSlots.Count -eq 0) {
                    Write-Host 'All bench positions are occupied. Remove or dispatch a device, then try again.'
                    Show-BenchScreen
                    continue
                }
                $defaultPos = $openSlots[0].Index
                while ($true) {
                    $prompt = ('Position number (1-{0}, 0 to cancel)' -f $max)
                    $ans = Read-ValidatedInput -Prompt $prompt -AllowEmpty -Default $defaultPos -Type 'Int'
                    $posNum = [int]$ans
                    if ($posNum -eq 0) { Show-BenchScreen; break }
                    if ($posNum -lt 1 -or $posNum -gt $max) { Write-Host ('Invalid position. Choose between 1 and {0}.' -f $max); continue }
                    $slot = $Script:BuildBench.Positions | Where-Object { $_.Index -eq $posNum }
                    if ($slot -and $slot.Serial) { Write-Host ('Position {0} is occupied. Choose an empty position.' -f $posNum); continue }

                    $useCurrent = Read-ValidatedInput -Prompt ('Use current site {0}? (Y/N)' -f $Script:BuildBench.SiteCode) -Default 'Y' -Type 'Choice' -Choices @('Y', 'N')
                    $site = if ($useCurrent.ToUpper() -eq 'Y') { $Script:BuildBench.SiteCode } else { Select-Site -CurrentSiteCode $Script:BuildBench.SiteCode }
                    $dtype = Select-DeviceType -Default $Script:BuildBench.DeviceType
                    $serial = Read-ValidatedInput -Prompt ('Enter {0}' -f $Script:Config.Nomenclature.Serial)
                    $ci = Read-ValidatedInput -Prompt ('Enter {0}' -f $Script:Config.Nomenclature.ConfigItem)
                    Add-DeviceToBenchPosition -Position $posNum -Serial $serial -ConfigItem $ci -Records $Records -SiteCode $site -DeviceType $dtype
                    Show-BenchScreen
                    break
                }
            }
            'R' {
                # Remove a device by position or identifier
                $hasAny = (($Script:BuildBench.Positions | Where-Object { $_.Serial }) | Measure-Object).Count -gt 0
                if (-not $hasAny) { Write-Host 'No devices are currently on the bench.'; Show-BenchScreen; continue }
                $max = ($Script:BuildBench.Positions | Measure-Object).Count
                $occupied = @($Script:BuildBench.Positions | Where-Object { $_.Serial })
                $defaultPos = if ($occupied.Count -gt 0) { $occupied[0].Index } else { 1 }
                $ans = Read-ValidatedInput -Prompt ('Position number (1-{0}) or Serial/CI (0 to cancel)' -f $max) -AllowEmpty -Default $defaultPos
                if ($ans -eq '0') { Show-BenchScreen; continue }
                $posNum = $null
                if ([int]::TryParse($ans, [ref]$posNum) -and $posNum -ge 1 -and $posNum -le $max) { $slot = $Script:BuildBench.Positions | Where-Object { $_.Index -eq [int]$posNum } }
                else { $slot = $Script:BuildBench.Positions | Where-Object { $_.Serial -eq $ans -or $_.ConfigItem -eq $ans } }
                if (-not $slot -or -not $slot.Serial) { Write-Host 'No device at that position or identifier.'; continue }
                Remove-DeviceFromBenchPosition -Position ([int]$slot.Index)
                Save-BuildBenchState
                Show-BenchScreen
            }
            'S' {
                # Action next step for a device by position or identifier
                $max = ($Script:BuildBench.Positions | Measure-Object).Count
                $ans = Read-ValidatedInput -Prompt ('Position number (1-{0}) or Serial/CI (0 to cancel)' -f $max)
                if ($ans -eq '0') { Show-BenchScreen; continue }
                $posNum = $null
                if ([int]::TryParse($ans, [ref]$posNum) -and $posNum -ge 1 -and $posNum -le $max) { $slot = $Script:BuildBench.Positions | Where-Object { $_.Index -eq [int]$posNum } }
                else { $slot = $Script:BuildBench.Positions | Where-Object { $_.Serial -eq $ans -or $_.ConfigItem -eq $ans } }
                if (-not $slot -or -not $slot.Serial) { Write-Host 'No device at that position or identifier.'; continue }
                $rec = $Records.Value | Where-Object { $_.Serial -eq $slot.Serial }
                if (-not $rec) {
                    $expectedTag = if ($Script:BuildBench.SiteCode -and $Script:BuildBench.DeviceType) { ('{0}-{1}' -f $Script:BuildBench.SiteCode, ($Script:BuildBench.DeviceType -replace '\s', '')) } else { $null }
                    $rec = New-DeviceRecordObject -Serial $slot.Serial -ConfigItem $slot.ConfigItem -SiteCode $Script:BuildBench.SiteCode -DeviceType $Script:BuildBench.DeviceType -GroupTag $expectedTag
                    Add-DeviceRecord -Records $Records -Record $rec
                    Write-UserDeviceRecords -Records $Records.Value
                }
                $next = Get-NextStepId -Device $rec
                if ($next) {
                    $stepDefinition = Get-ManifestStepDefinition -StepId $next
                    if ($stepDefinition) {
                        $result = Invoke-AutopilotManifestStep -Device $rec -StepDefinition $stepDefinition
                        Write-ManifestStepResult -Device $rec -StepDefinition $stepDefinition -Result $result
                        Write-UserDeviceRecords -Records $Records.Value
                        Write-Host $result.Summary
                        if ($result.Notes) { Write-Host $result.Notes }
                        Show-BenchScreen
                    }
                }
                else { Write-Host 'All steps completed.' }
            }
            'D' {
                # Dispatch and finish a device by position or identifier
                $max = ($Script:BuildBench.Positions | Measure-Object).Count
                $ans = Read-ValidatedInput -Prompt ('Position number (1-{0}) or Serial/CI (0 to cancel)' -f $max)
                if ($ans -eq '0') { Show-BenchScreen; continue }
                $posNum = $null
                if ([int]::TryParse($ans, [ref]$posNum) -and $posNum -ge 1 -and $posNum -le $max) { $slot = $Script:BuildBench.Positions | Where-Object { $_.Index -eq [int]$posNum } }
                else { $slot = $Script:BuildBench.Positions | Where-Object { $_.Serial -eq $ans -or $_.ConfigItem -eq $ans } }
                if (-not $slot -or -not $slot.Serial) { Write-Host 'No device at that position or identifier.'; continue }
                $rec = $Records.Value | Where-Object { $_.Serial -eq $slot.Serial }
                if (-not $rec) {
                    $expectedTag = if ($Script:BuildBench.SiteCode -and $Script:BuildBench.DeviceType) { ('{0}-{1}' -f $Script:BuildBench.SiteCode, ($Script:BuildBench.DeviceType -replace '\s', '')) } else { $null }
                    $rec = New-DeviceRecordObject -Serial $slot.Serial -ConfigItem $slot.ConfigItem -SiteCode $Script:BuildBench.SiteCode -DeviceType $Script:BuildBench.DeviceType -GroupTag $expectedTag
                    Add-DeviceRecord -Records $Records -Record $rec
                }
                if ($rec) { $rec.Status = 'completed'; $rec.CompletedAt = Get-Date; $rec.CompletedBy = $env:USERNAME; $rec.LastUpdatedAt = Get-Date; $rec.LastUpdatedBy = $env:USERNAME; Write-UserDeviceRecords -Records $Records.Value }
                Remove-DeviceFromBenchPosition -Position ([int]$slot.Index)
                Save-BuildBenchState
                Show-BenchScreen
            }
            'V' {
                # View a device details by position or identifier
                $max = ($Script:BuildBench.Positions | Measure-Object).Count
                $ans = Read-ValidatedInput -Prompt ('Position number (1-{0}) or Serial/CI (0 to cancel)' -f $max)
                if ($ans -eq '0') { Show-BenchScreen; continue }
                $posNum = $null
                if ([int]::TryParse($ans, [ref]$posNum) -and $posNum -ge 1 -and $posNum -le $max) { $slot = $Script:BuildBench.Positions | Where-Object { $_.Index -eq [int]$posNum } }
                else { $slot = $Script:BuildBench.Positions | Where-Object { $_.Serial -eq $ans -or $_.ConfigItem -eq $ans } }
                if (-not $slot -or -not $slot.Serial) { Write-Host 'No device at that position or identifier.'; continue }
                $rec = $Records.Value | Where-Object { $_.Serial -eq $slot.Serial }
                if (-not $rec) {
                    $expectedTag = if ($Script:BuildBench.SiteCode -and $Script:BuildBench.DeviceType) { ('{0}-{1}' -f $Script:BuildBench.SiteCode, ($Script:BuildBench.DeviceType -replace '\s', '')) } else { $null }
                    $rec = New-DeviceRecordObject -Serial $slot.Serial -ConfigItem $slot.ConfigItem -SiteCode $Script:BuildBench.SiteCode -DeviceType $Script:BuildBench.DeviceType -GroupTag $expectedTag
                    Add-DeviceRecord -Records $Records -Record $rec
                    Write-UserDeviceRecords -Records $Records.Value
                }
                if ($rec) { Write-Host ('Serial={0} CI={1} Status={2} Steps=[{3}]' -f $rec.Serial, $rec.ConfigItem, $rec.Status, ($rec.Steps.Keys -join ', ')) }
            }
            'M' {
                # Move device between positions; source can be pos/serial/ci, destination must be empty; default destination = next open
                $hasAny = (($Script:BuildBench.Positions | Where-Object { $_.Serial }) | Measure-Object).Count -gt 0
                if (-not $hasAny) { Write-Host 'No devices are currently on the bench.'; Show-BenchScreen; continue }
                $max = ($Script:BuildBench.Positions | Measure-Object).Count
                $srcAns = Read-ValidatedInput -Prompt ('Source position (1-{0}) or Serial/CI (0 to cancel)' -f $max)
                if ($srcAns -eq '0') { Show-BenchScreen; continue }
                $srcNum = $null
                if ([int]::TryParse($srcAns, [ref]$srcNum) -and $srcNum -ge 1 -and $srcNum -le $max) { $srcSlot = $Script:BuildBench.Positions | Where-Object { $_.Index -eq [int]$srcNum } }
                else { $srcSlot = $Script:BuildBench.Positions | Where-Object { $_.Serial -eq $srcAns -or $_.ConfigItem -eq $srcAns } }
                if (-not $srcSlot -or -not $srcSlot.Serial) { Write-Host 'No device found at that source position or identifier.'; continue }

                $openSlots = @($Script:BuildBench.Positions | Where-Object { -not $_.Serial })
                if ($openSlots.Count -eq 0) { Write-Host 'There are no empty positions to move the device to.'; Show-BenchScreen; continue }
                $defaultDest = $openSlots[0].Index
                while ($true) {
                    $destAns = Read-ValidatedInput -Prompt ('Destination position (1-{0}, 0 to cancel)' -f $max) -AllowEmpty -Default $defaultDest
                    if ($destAns -eq '0') { Show-BenchScreen; break }
                    $destNum = $null
                    if (-not [int]::TryParse($destAns, [ref]$destNum) -or $destNum -lt 1 -or $destNum -gt $max) { Write-Host ('Invalid position. Choose between 1 and {0}.' -f $max); continue }
                    $destSlot = $Script:BuildBench.Positions | Where-Object { $_.Index -eq [int]$destNum }
                    if ($destSlot.Serial) { Write-Host ('Position {0} is occupied. Choose an empty position.' -f $destNum); continue }
                    # Move
                    $destSlot.Serial = $srcSlot.Serial; $destSlot.ConfigItem = $srcSlot.ConfigItem
                    $srcSlot.Serial = $null; $srcSlot.ConfigItem = $null
                    Save-BuildBenchState
                    Show-BenchScreen
                    break
                }
            }
            default {
                # Treat as Serial or CI scanned
                $str = if ($cmd) { $cmd.Trim() } else { '' }
                $rec = $Records.Value | Where-Object { $_.Serial -eq $str -or $_.ConfigItem -eq $str }
                if ($rec) { Write-Host ('Scanned device Serial={0} CI={1} Status={2}' -f $rec.Serial, $rec.ConfigItem, $rec.Status) }
                else { Write-Host 'Unknown command or device. Use I/S/V/D/R/E or scan a known Serial/CI.' }
            }
        }
    }
}

# ===== Selection helpers =====
function Select-DeviceFromRecords {
    param([ref]$Records, [string]$Purpose)
    $list = $Records.Value | Where-Object { $_.Status -ne 'removed' }
    if (-not $list -or $list.Count -eq 0) { Write-Host 'No devices currently being worked on.'; return $null }
    Write-Host ('Select a device to {0} (enter number, Serial, CI, or 0 to exit):' -f $Purpose)
    $idx = 1
    foreach ($d in $list) { Write-Host ('  {0}. Serial={1} CI={2} Status={3}' -f $idx, $d.Serial, $d.ConfigItem, $d.Status); $idx++ }
    $sel = Read-ValidatedInput -Prompt 'Your selection (0 exits)'
    if ($sel -eq '0') { return $null }
    if ([int]::TryParse($sel, [ref]$null)) { $i = [int]$sel; if ($i -ge 1 -and $i -le $list.Count) { return $list[$i - 1] } }
    $d2 = $list | Where-Object { $_.Serial -eq $sel -or $_.ConfigItem -eq $sel }
    if ($d2) { return $d2 }
    Write-Host 'No matching device'; return $null
}

function Select-DeviceType {
    param([string]$Default)
    # Compute unique hotkey letter for each type and present a concise chooser
    $types = $Script:DeviceTypes
    $hotkeys = @{}
    foreach ($t in $types) {
        $clean = ($t -replace '[^A-Za-z0-9]', '')
        if ([string]::IsNullOrWhiteSpace($clean)) { continue }
        $assigned = $false
        for ($i = 0; $i -lt $clean.Length; $i++) {
            $upper = $clean[$i].ToString().ToUpper()
            if (-not ($hotkeys.Values | Where-Object { $_.Key -eq $upper })) {
                $hotkeys[$t] = @{ Index = $i; Key = $upper }
                $assigned = $true
                break
            }
        }
        if (-not $assigned) { $hotkeys[$t] = @{ Index = 0; Key = ($clean[0].ToString().ToUpper()) } }
    }
    Write-Host 'Select Device Type:'
    $i = 1
    foreach ($name in $types) {
        $marker = if ($name -eq $Default) { '*' } else { ' ' }
        $hk = $hotkeys[$name].Key
        Write-Host ('  {0}. {1} (hotkey: {2}) {3}' -f $i, $name, $hk, $marker)
        $i++
    }
    $ans = Read-ValidatedInput -Prompt 'Enter number, hotkey letter, or full name' -Default $Default
    # Try number
    $num = $null
    if ([int]::TryParse($ans, [ref]$num)) {
        if ($num -ge 1 -and $num -le $types.Count) { return $types[$num - 1] }
    }
    # Try hotkey
    $match = $hotkeys.Keys | Where-Object { $hotkeys[$_].Key -eq $ans.ToUpper() }
    if ($match) { return $match }
    # Try exact name
    $exact = $types | Where-Object { $_ -eq $ans }
    if ($exact) { return $exact }
    Write-Host 'Invalid selection; defaulting.'
    return $Default
}

function Show-ReturnToMainMenu {
    # Pause so the technician can read/copy output before returning
    [void](Read-Host 'Press Enter to return to the main menu')
    Clear-Host
}

function Show-ReturnToPreviousMenu {
    # Generic pause helper for sub-menus that return to their caller
    [void](Read-Host 'Press Enter to return to the previous menu')
    Clear-Host
}

# INITIALISATION & MAIN LOOP
Initialize-AutopilotExpressDefinitions
$records = Initialize-SessionState
# Prompt for startup site selection (issue 1)
$currentSiteCode = Select-Site -CurrentSiteCode (Get-SessionDefaultSiteCode -Records $records)
if (-not (Initialize-GraphSession)) {
    Write-AutopilotExpressLog -Message 'Autopilot Express cannot continue without a valid Graph session or demo simulation.' -Level 'ERROR'
    return
}
Write-AutopilotExpressLog -Message ('Autopilot Express Framework Initialised in {0} mode' -f $Script:Runtime.ModeDisplayName) -Level 'INFO'

while ($true) {
    $option = Show-MainMenu -CurrentSiteCode $currentSiteCode
    switch ($option) {
        '1' { $currentSiteCode = Start-NewDeviceWorkflow -CurrentSiteCode $currentSiteCode -Records ([ref]$records); Show-ReturnToMainMenu }
        '2' { Invoke-AutopilotSequence -Records ([ref]$records); Show-ReturnToMainMenu }
        '3' { Get-DeviceOutstanding -Records ([ref]$records); Show-ReturnToMainMenu }
        '4' { Update-DeviceStatus -Records ([ref]$records); Show-ReturnToMainMenu }
        '5' { Get-UserStats -Records ([ref]$records); Show-ReturnToMainMenu }
        '6' { Show-EnhancementsQuestions; Show-ReturnToMainMenu }
        '7' { $currentSiteCode = Select-Site -CurrentSiteCode $currentSiteCode; Show-ReturnToMainMenu }
        '8' {
            if (-not $Script:BuildBench.Active) {
                $benchCount = Read-ValidatedInput -Prompt 'Number of bench positions' -Type 'Int'
                New-BuildBench -Positions ([int]$benchCount)
                $Script:BuildBench.SiteCode = $currentSiteCode
                $Script:BuildBench.DeviceType = Select-DeviceType -Default $Script:DeviceTypes[0]
                Sync-BenchRecords -Records ([ref]$records)
            }
            Sync-BenchRecords -Records ([ref]$records)
            Show-BuildBenchView -Records ([ref]$records)
            Show-ReturnToMainMenu
        }
        '0' { Write-AutopilotExpressLog -Message 'Exiting framework.' -Level 'INFO'; Close-GraphSession; break }
        default { Write-Information -MessageData 'Invalid selection.' -InformationAction Continue }
    }
    if ($option -eq '0') { break }
}
