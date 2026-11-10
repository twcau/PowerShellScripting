# .CATEGORY
#    Intune Autopilot Express Technician CLI
# .SYNOPSIS
#    Technician CLI for Intune Autopilot device preparation and workflow tracking.
# .DESCRIPTION
#    This script provides an accessible, menu-driven UI for technicians performing Autopilot builds.
#    It captures device metadata, tracks progress across Autopilot steps, and implements selected live
#    Microsoft Graph / Intune / Entra ID actions while keeping tenant-specific or uncertain flows guided.
# .FILECREATED     2025-12-01
# .FILELASTUPDATED 2026-10-22
# .AUTHOR          Michael Harris (Developed collaboratively)
# .VERSION         0.3.1 (test release; not production-approved)
# .LICENSE         Refer to root LICENSE (GPLv3)
# .DOCUMENTATION   README.md, .website/ (canonical)
# .ACCESSIBILITY   All prompts support screen readers (no colour-only cues)
# .NOTES
#    Root-resolution pattern, logging, validation, and menu structure follow project standards.
#    EN-AU spelling is used for documentation and comments.
#    Supports PowerShell 7 and Windows PowerShell 5.1, including supported pasted execution.
#    Live tenant and physical-device pilot approval is still required before rollout.
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
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseSingularNouns', '', Scope = 'Function', Target = 'Get-ConfiguredScannerSerialRules', Justification = 'Internal helper returns the configured scanner serial-rule collection.')]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseSingularNouns', '', Scope = 'Function', Target = 'Get-UriQueryParameterValues', Justification = 'Internal helper returns all values for a repeated URI query parameter so ambiguity can be rejected.')]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseSingularNouns', '', Scope = 'Function', Target = 'Get-EnabledManifestSteps', Justification = 'Internal helper returns the enabled manifest-step collection.')]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseSingularNouns', '', Scope = 'Function', Target = 'Get-EligibleManifestSteps', Justification = 'Internal helper returns the eligible manifest-step collection.')]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseSingularNouns', '', Scope = 'Function', Target = 'Get-DispatchBlockingManifestSteps', Justification = 'Internal helper returns the incomplete steps that block build-bench dispatch.')]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseSingularNouns', '', Scope = 'Function', Target = 'Get-ManifestStepPrerequisiteIds', Justification = 'Internal helper returns the prerequisite step-ID collection.')]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseSingularNouns', '', Scope = 'Function', Target = 'Initialize-AutopilotExpressDefinitions', Justification = 'Initialisation intentionally loads multiple external definitions.')]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseSingularNouns', '', Scope = 'Function', Target = 'Install-RequiredGraphModules', Justification = 'Internal helper installs the configured module collection after explicit technician consent.')]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseSingularNouns', '', Scope = 'Function', Target = 'Import-RequiredGraphModules', Justification = 'Internal helper imports multiple Graph modules by design.')]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseSingularNouns', '', Scope = 'Function', Target = 'Test-GraphCapabilities', Justification = 'Internal preflight validates multiple required Graph read capabilities.')]
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
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '', Scope = 'Function', Target = 'New-EmptyDeviceRecord', Justification = 'Internal factory only constructs a ConstrainedLanguage-compatible in-memory record.')]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '', Scope = 'Function', Target = 'New-ParentDirectory', Justification = 'Internal file helper is not exposed as a user-invoked cmdlet.')]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '', Scope = 'Function', Target = 'Reset-CurrentSessionState', Justification = 'Internal session-reset helper is driven by explicit menu confirmation rather than -WhatIf semantics.')]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '', Scope = 'Function', Target = 'Update-MasterAuditLedger', Justification = 'Internal ledger writer is called from controlled persistence paths only.')]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '', Scope = 'Function', Target = 'Start-NewDeviceWorkflow', Justification = 'This interactive workflow is already confirmation-driven and not intended for cmdlet-style WhatIf support.')]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '', Scope = 'Function', Target = 'Update-DeviceStatus', Justification = 'This interactive workflow is already confirmation-driven and not intended for cmdlet-style WhatIf support.')]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '', Scope = 'Function', Target = 'Update-DeviceInventoryFromIntune', Justification = 'Started only from the confirmed Data Settings menu choice; archive files are backed up before any save.')]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '', Scope = 'Function', Target = 'New-OperationResult', Justification = 'Internal result factory only constructs in-memory objects.')]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '', Scope = 'Function', Target = 'New-BuildBench', Justification = 'This internal workflow initialiser is menu-driven and not intended for cmdlet-style WhatIf support.')]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '', Scope = 'Function', Target = 'Remove-DeviceFromBenchPosition', Justification = 'This internal bench helper is menu-driven and not intended for cmdlet-style WhatIf support.')]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', '', Scope = 'Function', Target = 'Invoke-StepValidateDeploymentProfile', Justification = 'Manifest step handlers share a standard signature even when a specific step does not currently need every argument.')]
[CmdletBinding()]
param(
    [string]$Mode,
    [ValidateSet('Browser', 'DeviceCode')][string]$AuthMode,
    [switch]$MigrateWorkflowIds,
    [switch]$ApplyWorkflowMigration,
    [ValidateSet('Inspect', 'Recover')][string]$SessionLockAction,
    [string]$SessionLockPath,
    [switch]$ConfirmStopped,
    [ValidateSet('Inspect', 'Resolve')][string]$CheckpointAction,
    [string]$CheckpointPath,
    [Nullable[bool]]$BirthCertificateEnabled,
    [Nullable[bool]]$ChecklistEnabled,
    [Nullable[bool]]$EnforceDocumentGuards,
    [ValidateSet('Disabled', 'GenerateOnly', 'Review', 'GenerateAndAsk', 'AutoPrint')][string]$BirthCertificateMode,
    [ValidateSet('Disabled', 'GenerateOnly', 'Review', 'GenerateAndAsk', 'AutoPrint')][string]$ChecklistMode,
    [Nullable[int]]$DocumentWorkerTimeoutSeconds,
    [Nullable[int]]$DocumentFailedJobRetentionDays
)

$Script:DocumentCommandLineOverrides = @{}
foreach ($documentKey in @('BirthCertificateEnabled', 'ChecklistEnabled', 'EnforceDocumentGuards', 'BirthCertificateMode', 'ChecklistMode', 'DocumentWorkerTimeoutSeconds', 'DocumentFailedJobRetentionDays')) {
    if ($PSBoundParameters.ContainsKey($documentKey)) { $Script:DocumentCommandLineOverrides[($documentKey -replace '^Document', '')] = $PSBoundParameters[$documentKey] }
}
$Script:AuthModeOverride = $AuthMode
$Script:ImagingSessionLoadedAt = Get-Date
$Script:EntryPointParameterNames = @($MyInvocation.MyCommand.ScriptBlock.Ast.ParamBlock.Parameters | ForEach-Object { $_.Name.VariablePath.UserPath })

# ==============================================================================================
# MENU STRUCTURE (ASCII, Accessible)
# The manifest supplies workflow labels, prerequisites and enabled actions.
#
# Main Menu:
# |-- 1. Build Bench                    (Induct, move, advance, reload and dispatch)
# |-- 2. Device Commands                (Caller-owned submenu)
# |   |-- 1. Start on a new device       (Capture or explicitly reuse a workflow)
# |   |-- 2. Continue current device    (Remain on its workflow after each action)
# |   |-- 3. Show current device list   (Read-only, includes completed/removed)
# |   |-- 4. Maintain current list      (Guarded status changes)
# |   |-- 5. Show outstanding work      (Retained existing action)
# |   |-- 6. Device actions             (Quick remediations, status and local Intune link)
# |   `-- 0. Main Menu                  (Explicit navigation)
# |-- 3. My Stats                       (Recorded working-time statistics)
# |-- 4. Session and Script Settings    (Session defaults only)
# |   |-- 1. Change current site        (No existing-device retagging)
# |   |-- 2. Change default device type (No active-bench change)
# |   |-- 3. View work pattern/hours    (Read-only default policy)
# |   |-- 4. Edit work pattern/hours    (Effective dates; protected history)
# |   |-- 5. Choose quick remediations  (Per technician/tenant; nothing initially enabled)
# |   |-- 6. Document output settings   (Session controls; separate default-No save)
# |   |-- 9. Reconnect Microsoft Graph  (Explicit sign-in; no workflow replay)
# |   `-- 0. Main Menu                  (Explicit navigation)
# |-- 5. Data Settings                  (Caller-owned submenu)
# |   |-- 1. Open script log folder     (Actual transcript folder in Explorer)
# |   |-- 2. Archive and start fresh    (Current user/mode; No/CANCEL defaults)
# |   |-- 3. Export session report      (CSV/HTML; explicit Yes, default No)
# |   |-- 4. Recovery backup report     (Sizes by kind/date/tenant; O organises with Y/default N; no deletion)
# |   `-- 0. Main Menu                  (Explicit navigation)
# |-- 6. Script Information             (Caller-owned submenu)
# |   |-- 1. About                     (Version, permissions and local README)
# |   |-- 2. Script steps list          (Manifest guide, no actions executed)
# |   |-- 3. Basic documentation        (Paged operator overview)
# |   |-- 4. Command-line flags         (Actual entry-point parameter names)
# |   |-- 8. Future enhancements        (Status-labelled catalogue)
# |   `-- 0. Main Menu                  (Explicit navigation)
# `-- 0. Exit                           (Close Graph and release reservation)
#
# Tracked Device Workflow (Device Commands > 2):
#   Canonical A-O; recovery P-Q           (WorkflowIdVersion 2; Graph or guided observation)
#     Preparation                        (Identity, managed-device cleanup, Group Tag and membership)
#     Physical build                     (Imaging/OOBE, profile confirmation, reseal and boot)
#     Post-provisioning                  (Technician assignment, membership removal and sign-in)
#     Device completion                  (Applications, sync, approved updates and shutdown)
#     Final ownership                    (Explicit eligible C/E selection and assignment evidence)
#     Conditional recovery               (Unblock submission and guided recovery close-out)
#   T. Prepare device                    (Guarded identity/cleanup/tag/membership plan)
#   X. Record Autopilot failure           (Default N; archive evidence and enter recovery)
#   DISPATCH / DO                        (Default N; override requires an audited reason)
#   8. Run next eligible step             (Alternative command if a manifest ID conflicts)
#   9. Select another device              (Alternative command if a manifest ID conflicts)
#   0. Return                            (Immediate return; R is a safe legacy alias)
#
# ==============================================================================================
# GRAPH / INTUNE / ENTRA REQUIREMENTS
# Delegated browser authentication uses the runtime JSON module and scope lists.
# Default scopes (tenant consent and operator permissions still require approval):
#   DeviceManagementServiceConfig.ReadWrite.All, DeviceManagementManagedDevices.ReadWrite.All,
#   DeviceManagementManagedDevices.PrivilegedOperations.All,
#   DeviceManagementScripts.Read.All,
#   Group.ReadWrite.All, GroupMember.ReadWrite.All, User.Read.All, Directory.Read.All.
# Active operations:
#   Resolve serial:           GET Autopilot and managed-device serial collections
#   Resolve Entra object:     GET /v1.0/devices filtered by registration deviceId
#   Remove managed device:    DELETE /v1.0/deviceManagement/managedDevices/{id}
#   Update Group Tag:         POST v1.0 Autopilot updateDeviceProperties (guarded REST)
#   Group membership:         POST members/$ref or DELETE members/{id}/$ref
#   Assign Autopilot user:    POST assignUserToDevice (guarded REST)
#   Assign managed user:      POST managedDevices('{id}')/users/$ref (raw Graph)
#   Request managed sync:     POST managedDevices/{id}/syncDevice
#   Remediation utilities:    Beta package metadata/run reports and confirmed on-demand POST
#   Intune overview link:     Fresh managedDevice ID; technician PC clipboard only
#   Recovery unblock:         POST Autopilot allowNextEnrollment
# No Autopilot-record deletion, manager inference or remote vendor command is performed.
# Application baseline and manufacturer procedures are guided physical observations.
#
# SECURITY & AUDIT CONSIDERATIONS:
#   - Graph wrapper bounds transient GET retries and SDK timeouts; writes are never replayed.
#   - Structured 429/503/504 failures honour bounded Retry-After; unknown outcomes fail closed.
#   - Never persist tokens or passwords. Automatic transcripts contain operational identities;
#     restrict access and review/redact them before sharing outside authorised support.
#   - Local reservation and recoverable saves are implemented; Shared mode remains disabled.
#
# ==============================================================================================
# ROOT RESOLUTION (Robust) & ENV VAR SETUP
#region Bootstrap and Diagnostics
function Show-ScriptScreen {
    <#
    .SYNOPSIS
        Clear the terminal and draw the shared blue header, including before mode selection.
    .PARAMETER ModeLabel
        Optional bootstrap label; later screens use the selected runtime mode.
    .OUTPUTS
        Accessible host text only, with one blank row below the title.
    .PARAMETER Title
        Screen purpose displayed with the current Demo/Live mode.
    .PARAMETER PromptFollows
        Reserve the shared blank-row boundary when the next operation reads input.
    #>
    param([Parameter(Mandatory)][ValidateNotNullOrEmpty()][string]$Title, [string]$ModeLabel, [switch]$PromptFollows)
    try { Clear-Host } catch { Write-Host '' }
    $width = 120
    try { if ($Host.UI.RawUI.WindowSize.Width -gt 1) { $width = $Host.UI.RawUI.WindowSize.Width - 1 } }
    catch { $width = 120 }
    $mode = if ($ModeLabel) { $ModeLabel } elseif ($Script:Runtime -and $Script:Runtime.IsDemoMode) { 'Demo' } else { 'Live' }
    $text = 'Autopilot Express - {0} | {1}' -f $Title, $mode
    while ($text.Length -gt 0) {
        $length = if ($text.Length -gt $width) { $width } else { $text.Length }
        $line = $text.Substring(0, $length)
        $padding = $width - $line.Length
        $left = [int](($padding - ($padding % 2)) / 2)
        Write-Host ($line.PadLeft($line.Length + $left).PadRight($width)) -BackgroundColor DarkBlue -ForegroundColor White
        $text = $text.Substring($length)
    }
    if (-not $PromptFollows) { Write-Host '' }
}
function Start-AutopilotDiagnostics {
    <#
    .SYNOPSIS
        Start one owned transcript before bootstrap, storage reservation or authentication.
    .PARAMETER SourcePath
        Executing script path for a best-effort revision fingerprint.
    .OUTPUTS
        Unique log path outside operational data discovery. Falls back to TEMP;
        refuses startup if neither location can retain diagnostics.
    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '', Justification = 'Mandatory internal diagnostics must start before tenant access; no business state is changed.')]
    [CmdletBinding()]
    [OutputType([string])]
    param([string]$SourcePath = $PSCommandPath)
    foreach ($root in @($env:LOCALAPPDATA, $env:TEMP)) {
        if ([string]::IsNullOrWhiteSpace($root)) { continue }
        try {
            $folder = Join-Path $root 'AutopilotExpress/logs'
            New-Item -ItemType Directory -Path $folder -Force -ErrorAction Stop | Out-Null
            $path = Join-Path $folder ('autopilot-express-{0}-{1}.log' -f (Get-Date -Format yyyyMMdd-HHmmss), [guid]::NewGuid().ToString('N'))
            Start-Transcript -LiteralPath $path -NoClobber -ErrorAction Stop | Out-Null
            Write-Information -MessageData ('Diagnostic log: {0}. Contains operational identities; protect this file.' -f $path) -InformationAction Continue
            Write-Information -MessageData ('Host={0}; edition={1}; language={2}.' -f $PSVersionTable.PSVersion, $PSVersionTable.PSEdition, $ExecutionContext.SessionState.LanguageMode) -InformationAction Continue
            if ($SourcePath) {
                try {
                    $sourceHash = (Get-FileHash -LiteralPath $SourcePath -Algorithm SHA256 -ErrorAction Stop).Hash
                    Write-Information -MessageData ('SourceSHA256={0}' -f $sourceHash) -InformationAction Continue
                }
                catch { Write-Warning 'Source fingerprint unavailable; keep the executing script with this log for revision comparison.' }
            }
            return $path
        }
        catch { Write-Warning 'Could not start diagnostics in this location; trying the fallback log folder.' }
    }
    throw 'Cannot create a diagnostic log in LOCALAPPDATA or TEMP. Check local folder access; startup stopped before storage or tenant access.'
}

function Complete-AutopilotDiagnostics {
    <#
    .SYNOPSIS
        Close this invocation transcript without hiding the original workflow error.
    .PARAMETER Path
        Path returned only after successful transcript startup; null means none is owned.
    .OUTPUTS
        None. Stops only the owned transcript and reports its retained path.
    #>
    param([string]$Path)
    if (-not $Path) { return }
    try { Stop-Transcript -ErrorAction Stop | Out-Null }
    catch { Write-Warning 'Could not close the diagnostic transcript cleanly; retain the partial log.' }
    Write-Information -MessageData ('Diagnostic log retained: {0}' -f $Path) -InformationAction Continue
}

$Script:DiagnosticLogPath = Start-AutopilotDiagnostics
if ($MigrateWorkflowIds -or $SessionLockAction -or $CheckpointAction) { $Mode = 'Demo' }
Show-ScriptScreen -Title 'Initial setup and testing' -ModeLabel 'Choose mode' -PromptFollows
try {
    $runtimeConfigFileName = 'autopilot-express.runtime.json'
    $manifestFileName = 'autopilot-express.manifest.json'
    $definitionDirectoryCandidates = @()

    foreach ($sourcePath in @($PSScriptRoot, $env:AutopilotExpressDefinitionDirectory)) {
        if (-not [string]::IsNullOrWhiteSpace([string]$sourcePath)) { $definitionDirectoryCandidates += [string]$sourcePath }
    }
    if (-not [string]::IsNullOrWhiteSpace($PSCommandPath)) {
        $definitionDirectoryCandidates += Split-Path -Parent $PSCommandPath
    }
    if (-not [string]::IsNullOrWhiteSpace($MyInvocation.MyCommand.Path)) {
        $definitionDirectoryCandidates += Split-Path -Parent $MyInvocation.MyCommand.Path
    }

    $currentDirectory = (Get-Location).Path
    $searchDirectory = $currentDirectory
    for ($searchDepth = 0; $searchDepth -lt 10; $searchDepth++) {
        $definitionDirectoryCandidates += $searchDirectory
        $definitionDirectoryCandidates += Join-Path $searchDirectory 'intune\devices\autopilot-express'
        $parentDirectory = Split-Path -Parent $searchDirectory
        if ([string]::IsNullOrWhiteSpace($parentDirectory) -or $parentDirectory -eq $searchDirectory) { break }
        $searchDirectory = $parentDirectory
    }

    $definitionDirectory = $null
    foreach ($candidateDirectory in @($definitionDirectoryCandidates | Select-Object -Unique)) {
        if ((Test-Path (Join-Path $candidateDirectory $runtimeConfigFileName)) -and (Test-Path (Join-Path $candidateDirectory $manifestFileName))) {
            $definitionDirectory = (Resolve-Path $candidateDirectory).Path
            break
        }
    }

    while ([string]::IsNullOrWhiteSpace($definitionDirectory)) {
        Write-Host ''
        $definitionDirectoryInput = Read-Host ('Enter the folder containing {0} and {1} (default: {2})' -f $runtimeConfigFileName, $manifestFileName, $currentDirectory)
        $candidateDirectory = if ([string]::IsNullOrWhiteSpace($definitionDirectoryInput)) { $currentDirectory } else { $definitionDirectoryInput.Trim() }
        if ((Test-Path (Join-Path $candidateDirectory $runtimeConfigFileName)) -and (Test-Path (Join-Path $candidateDirectory $manifestFileName))) {
            $definitionDirectory = (Resolve-Path $candidateDirectory).Path
            break
        }
        Write-Information -MessageData ('The selected folder does not contain both {0} and {1}.' -f $runtimeConfigFileName, $manifestFileName) -InformationAction Continue
    }

    $Script:AutopilotExpressScriptDirectory = $definitionDirectory

    # The resolved definition folder is authoritative for this run, even when an IDE inherited a stale project-root value.
    $projectRoot = $definitionDirectory
    $current = $definitionDirectory
    $maxDepth = 10
    for ($i = 0; $i -lt $maxDepth; $i++) {
        $anchorReadme = Test-Path (Join-Path $current 'README.md')
        $anchorLicense = Test-Path (Join-Path $current 'LICENSE')
        $anchorGit = Test-Path (Join-Path $current '.git')
        if ($anchorReadme -or $anchorLicense -or $anchorGit) {
            $projectRoot = $current
            break
        }
        $parent = Split-Path -Parent $current
        if ([string]::IsNullOrWhiteSpace($parent) -or $parent -eq $current) { break }
        $current = $parent
    }
    $Script:AutopilotExpressProjectRoot = $projectRoot
    $env:PowerShellScriptingNewRoot = $projectRoot

    while ($true) {
        $modeInput = if ([string]::IsNullOrWhiteSpace($Mode)) { Write-Host ''; Read-Host 'Select mode: Live or Demo (default: Demo)' } else { $Mode }
        if ([string]::IsNullOrWhiteSpace($modeInput)) {
            $Mode = 'Demo'
            break
        }
        elseif ($modeInput.Trim().ToUpperInvariant() -eq 'LIVE') {
            $Mode = 'Live'
            break
        }
        elseif ($modeInput.Trim().ToUpperInvariant() -eq 'DEMO') {
            $Mode = 'Demo'
            break
        }
        else {
            Write-Information -MessageData 'Enter Live or Demo.' -InformationAction Continue
            $Mode = $null
        }
    }
}
catch {
    Write-Information -MessageData ('Autopilot Express bootstrap failed; startup stopped: {0}' -f $_.Exception.Message) -InformationAction Continue
    Complete-AutopilotDiagnostics -Path $Script:DiagnosticLogPath
    throw
}

# LOGGING (timestamped information-stream output captured by this invocation transcript)
#endregion
#region Runtime Defaults and Record Shapes
function Write-AutopilotExpressLog {
    <#
    .SYNOPSIS
        Write a timestamped safe message to the information stream and console.
    .PARAMETER Message
        Safe diagnostic text; callers must not supply credentials or raw SDK payloads.
    .PARAMETER Level
        INFO, WARN, ERROR or DEBUG severity included as text, not colour alone.
    .OUTPUTS
        Information-stream output captured by the owned diagnostic transcript.
    #>
    param(
        [Parameter(Mandatory)][string]$Message,
        [ValidateSet('INFO', 'WARN', 'ERROR', 'DEBUG')][string]$Level = 'INFO'
    )
    $ts = (Get-Date).ToString('yyyy-MM-dd HH:mm:ss')
    # A lost console (for example a terminal closed by endpoint protection) must not abort a save
    # half-way and strand a checkpoint, so console write failures are tolerated here.
    try { Write-Information -MessageData ('[{0}] [{1}] {2}' -f $ts, $Level, $Message) -InformationAction Continue }
    catch [System.IO.IOException] { $null = $_ }
}

# INTERNAL DEFAULTS & NOMENCLATURE (workflow availability comes from the manifest)
$Script:Config = [ordered]@{
    OrganisationName          = 'Example Health Network'
    Nomenclature              = [ordered]@{ Serial = 'Serial'; ConfigItem = 'Configuration Item'; Site = 'Site'; DeviceType = 'Device Type'; GroupTag = 'Group Tag' }
    DataFolderRelative        = 'data'
    UserDataFilePrefix        = 'autopilot-devices'
    DemoUserDataFilePrefix    = 'autopilot-devices-demo'
    RecentUsersFilePrefix     = 'autopilot-recent-users'
    DemoRecentUsersFilePrefix = 'autopilot-recent-users-demo'
    BuildBenchFilePrefix      = 'build-bench'
    DemoBuildBenchFilePrefix  = 'build-bench-demo'
    ArchiveFolderRelative     = 'archive/autopilot-express'
    MasterAuditFileName       = 'autopilot-master-audit.json'
    RuntimeConfigFileName     = 'autopilot-express.runtime.json'
    ManifestFileName          = 'autopilot-express.manifest.json'
    MaxRetryAttempts          = 5
    RetryBackoffSeconds       = 3
    TransportMaxAttempts      = 3
    TransportBackoffSeconds   = 3
    TransportMaxDelaySeconds  = 60
    TransportTimeoutSeconds   = 60
    ReportWarningRowCount     = 1000
    InventoryPollingMinutes   = 5
}

$Script:Runtime = [ordered]@{
    Mode            = $Mode
    IsDemoMode      = $Mode -eq 'Demo'
    ModeDisplayName = if ($Mode -eq 'Demo') { 'demo' } else { 'normal' }
}

$Script:RuntimeConfig = @{}
$Script:GraphSession = [ordered]@{
    Connected         = $false
    RequiresReconnect = $false
    IsSimulated       = $Script:Runtime.IsDemoMode
    Account           = ''
    DisplayName       = ''
    UserId            = ''
    TenantId          = ''
    Scopes            = @()
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
$Script:WorkflowPhases = @()

# ENHANCEMENT MANIFEST (drives dynamic enhancements list)
$Script:EnhancementManifest = @(
    [ordered]@{ Id = 1; Title = 'Concurrent device locking'; Description = 'Local session reservation is implemented; shared cross-technician transactions remain disabled.'; Status = 'Local only' }
    [ordered]@{ Id = 2; Title = 'Service Management integration'; Description = 'Update ITIL CMDB with device build events.'; Status = 'Planned' }
    [ordered]@{ Id = 3; Title = 'Technician-directed name suggestions'; Description = 'Bounded one-edit suggestions after no literal matches; explicit active C/E selection and revalidation.'; Status = 'Implemented; Live pilot pending' }
    [ordered]@{ Id = 4; Title = 'Baseline policy compliance scan'; Description = 'Check devices for required policies before reseal.'; Status = 'Planned' }
    [ordered]@{ Id = 5; Title = 'Offline caching for field techs'; Description = 'Queue updates when offline, sync later.'; Status = 'Planned' }
    [ordered]@{ Id = 6; Title = 'Export CSV & HTML reports'; Description = 'Current-session device reports with explicit step evidence; no cross-machine audit search.'; Status = 'Implemented locally; operational acceptance pending' }
    [ordered]@{ Id = 7; Title = 'Pester tests'; Description = 'Offline unit and actual Demo CLI regressions are implemented; tenant and physical validation remain pending.'; Status = 'Implemented offline' }
    [ordered]@{ Id = 8; Title = 'Localisation'; Description = 'Multi-language prompts and messages.'; Status = 'Planned' }
    [ordered]@{ Id = 9; Title = 'Telemetry dashboard'; Description = 'Optional Power BI ingestion for trend analysis.'; Status = 'Planned' }
    [ordered]@{ Id = 10; Title = 'Secure token cache & refresh'; Description = 'Hardened auth flow for Graph integration.'; Status = 'Planned' }
    [ordered]@{ Id = 11; Title = 'Collaborative build bench'; Description = 'Multiple technicians sharing bench and preparation data across devices; Shared remains disabled.'; Status = 'Planned' }
    [ordered]@{ Id = 12; Title = 'Remote device operations'; Description = 'Approved remote manufacturer updates, Windows updates, Company Portal application installs and restarts.'; Status = 'Planned' }
    [ordered]@{ Id = 13; Title = 'Device build certificates'; Description = 'Produce a build certificate and remotely load its record onto the device.'; Status = 'Planned' }
    [ordered]@{ Id = 14; Title = 'Whitelisting exports'; Description = 'Export device information for approved whitelisting workflows with one command.'; Status = 'Planned' }
)

# DATA SCHEMA (ConstrainedLanguage-compatible device record factory)
function New-EmptyDeviceRecord {
    <#
    .SYNOPSIS
        Create the initialised version-two workflow record shape.
    .OUTPUTS
        Ordered dictionary of identity, state and evidence defaults; no storage or tenant access.
    #>
    return [ordered]@{
        RecordId                      = ''
        BuildCycleId                  = ''
        WorkflowIdVersion             = 2
        TenantId                      = ''
        AutopilotDeviceId             = ''
        ManagedDeviceId               = ''
        AzureAdDeviceId               = ''
        IntuneDeviceName              = ''
        IntuneInventory               = @{}
        Serial                        = ''
        EntraDeviceId                 = ''
        ConfigItem                    = ''
        SiteCode                      = ''
        DeviceType                    = ''
        GroupTag                      = ''
        Status                        = 'new'
        Steps                         = @{}
        AttemptHistory                = @()
        # SYNC-RECEIPTS: append-only Intent/Accepted ledger for syncDevice submissions.
        SyncSubmissions               = @()
        # IMPORT-RECEIPTS: append-only Submitting/Accepted ledger for hardware-hash imports.
        ImportSubmissions             = @()
        ImagingSessionStarts          = @()
        StartedAt                     = [DateTime]::MinValue
        StartedBy                     = ''
        LastUpdatedAt                 = [DateTime]::MinValue
        LastUpdatedBy                 = ''
        CompletedAt                   = [DateTime]::MinValue
        CompletedBy                   = ''
        DispatchConfirmed             = $false
        DispatchedAt                  = [DateTime]::MinValue
        IsCompletionVerified          = $false
        TechnicianUserPrincipalName   = ''
        FinalPrimaryUserId            = ''
        FinalPrimaryUserPrincipalName = ''
        FinalPrimaryUserDisplayName   = ''
        RecoveryActive                = $false
        RecoveryStartedAt             = [DateTime]::MinValue
        RecoveryReason                = ''
        RecoveryHistory               = @()
    }
}

function Get-DefaultBuildBenchState {
    <#
    .SYNOPSIS
        Create an inactive bench with empty positions and faults.
    .OUTPUTS
        Ordered dictionary; each call creates independent mutable state.
    #>
    return [ordered]@{ Positions = @(); Active = $false; SiteCode = $null; DeviceType = $null; Faults = @() }
}

function ConvertTo-NormalisedValue {
    <#
    .SYNOPSIS
        Recursively detach JSON objects into dictionaries without collapsing arrays.
    .PARAMETER Value
        Scalar, dictionary, object or collection; dates become round-trip strings.
    .OUTPUTS
        Normalised value, preserving null and empty/singleton arrays. Does not edit the input.
    .NOTES
        This runs on every field of every record during each load, save and audit, so it is
        written for speed. Text and plain values (other than dates) are copied directly
        rather than through another call, and arrays are collected straight from the loop.
        This avoids "+=", which copies the whole array for each item. It uses no .NET list
        types, so it still runs under constrained language mode. The output is unchanged.
    #>
    param($Value)
    if ($null -eq $Value) { return $null }
    if ($Value -is [DateTime]) { return Get-Date -Date $Value -Format o }
    if ($Value -is [string] -or $Value -is [ValueType]) { return $Value }
    if ($Value -is [System.Collections.IDictionary]) {
        $normalisedMap = @{}
        foreach ($key in $Value.Keys) {
            $child = $Value[$key]
            $normalisedMap[$key] = if ($child -is [string] -or ($child -is [ValueType] -and $child -isnot [DateTime])) { $child } else { ConvertTo-NormalisedValue -Value $child }
        }
        return $normalisedMap
    }
    if ($Value -is [pscustomobject]) {
        $normalisedMap = @{}
        foreach ($property in $Value.PSObject.Properties) {
            $child = $property.Value
            $normalisedMap[$property.Name] = if ($child -is [string] -or ($child -is [ValueType] -and $child -isnot [DateTime])) { $child } else { ConvertTo-NormalisedValue -Value $child }
        }
        return $normalisedMap
    }
    if ($Value -is [System.Collections.IEnumerable] -and $Value -isnot [string]) {
        # The leading comma emits each item whole, so nested and empty arrays stay single items.
        $items = @(foreach ($item in $Value) {
                if ($item -is [string] -or ($item -is [ValueType] -and $item -isnot [DateTime])) { , $item } else { , (ConvertTo-NormalisedValue -Value $item) }
            })
        return , $items
    }
    return $Value
}

function ConvertTo-StepHashtable {
    <#
    .SYNOPSIS
        Validate persisted step evidence and migrate typed legacy Boolean flags.
    .PARAMETER Value
        Step dictionary, or null when a legacy record has no step evidence.
    .OUTPUTS
        Normalised validated dictionary; damaged evidence raises an error.
    #>
    param($Value)
    if ($null -eq $Value) { return @{} }
    $convertedValue = ConvertTo-NormalisedValue -Value $Value
    if ($convertedValue -is [System.Collections.IDictionary]) {
        foreach ($stepId in @($convertedValue.Keys)) {
            if ($stepId -isnot [string] -or [string]::IsNullOrWhiteSpace($stepId)) { throw 'Saved step IDs must be non-empty strings.' }
            $stepRecord = $convertedValue[$stepId]
            if ($stepRecord -isnot [System.Collections.IDictionary]) { throw ('Saved step {0} must be a dictionary.' -f $stepId) }
            foreach ($flag in @('Completed', 'Success', 'IsSimulated')) {
                if ($stepRecord.Contains($flag) -and $stepRecord[$flag] -isnot [bool]) { throw ('Saved step {0} flag {1} must be a Boolean.' -f $stepId, $flag) }
            }
            if ($stepRecord.Contains('Data') -and $stepRecord.Data -isnot [System.Collections.IDictionary]) { throw ('Saved step {0} data must be a dictionary.' -f $stepId) }
            foreach ($dateField in @('Timestamp', 'InvalidatedAt')) {
                if ($null -ne $stepRecord[$dateField]) {
                    $dateInput = $stepRecord[$dateField]
                    if ($dateInput -is [System.Collections.IDictionary] -and $dateInput.Contains('value')) { $dateInput = $dateInput.value }
                    if ($dateInput -isnot [string] -and $dateInput -isnot [DateTime]) { throw ('Saved step {0} date {1} has an invalid type.' -f $stepId, $dateField) }
                    $null = Get-Date -Date $dateInput -ErrorAction Stop
                }
            }
            if ($stepRecord.Contains('CompletionState')) {
                if ($stepRecord.CompletionState -isnot [string] -or $stepRecord.CompletionState -notin @('Verified', 'TechnicianConfirmed', 'Submitted', 'Blocked', 'Failed', 'AuditedException', 'Simulated', 'LegacyCompleted')) {
                    throw ('Saved step {0} has an unsupported completion state.' -f $stepId)
                }
                continue
            }
            $legacyCompleted = if ($stepRecord.Contains('Completed')) { $stepRecord.Completed } elseif ($stepRecord.Contains('Success')) { $stepRecord.Success } else { $false }
            $stepRecord['CompletionState'] = if ($legacyCompleted) { 'LegacyCompleted' } else { 'Failed' }
        }
        return $convertedValue
    }
    throw 'Saved Steps must be a dictionary; damaged evidence cannot be replaced with empty state.'
}

function New-DeviceRecordObject {
    <#
    .SYNOPSIS
        Initialise one inducted device with its identity and workflow defaults.
    .PARAMETER Serial
        Device serial supplied by the validated induction flow.
    .PARAMETER ConfigItem
        Configuration item identity supplied by the technician.
    .PARAMETER SiteCode
        Selected configured site.
    .PARAMETER DeviceType
        Selected configured hardware category.
    .PARAMETER EntraDeviceId
        Optional known Entra identity; not proof of current tenant state.
    .PARAMETER GroupTag
        Optional initial tag; not evidence of a verified Graph write.
    .OUTPUTS
        New dictionary record. The caller validates uniqueness and persists it separately.
    #>
    param(
        [Parameter(Mandatory)][string]$Serial,
        [Parameter(Mandatory)][string]$ConfigItem,
        [string]$SiteCode,
        [string]$DeviceType,
        [string]$EntraDeviceId,
        [string]$GroupTag
    )
    $serialResult = ConvertTo-NormalisedSerialInput -InputValue $Serial
    if (-not $serialResult.Success) { throw ('Invalid serial input: {0}' -f $serialResult.Message) }

    $record = New-EmptyDeviceRecord
    $record.RecordId = [guid]::NewGuid().Guid
    $record.BuildCycleId = [guid]::NewGuid().Guid
    $record.AutopilotDeviceId = ''
    $record.ManagedDeviceId = ''
    $record.AzureAdDeviceId = ''
    $record.IntuneDeviceName = ''
    $record.Serial = $serialResult.Serial
    $record.EntraDeviceId = if ($EntraDeviceId) { $EntraDeviceId } else { '' }
    $record.ConfigItem = $ConfigItem
    $record.SiteCode = $SiteCode
    $record.DeviceType = $DeviceType
    $record.GroupTag = $GroupTag
    $record.Status = 'new'
    $record.Steps = @{}
    $record.StartedAt = Get-Date
    $record.ImagingSessionStarts = @(Get-Date -Date $record.StartedAt -Format o)
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
    $record.RecoveryActive = $false
    $record.RecoveryStartedAt = [DateTime]::MinValue
    $record.RecoveryReason = ''
    return $record
}

# Safely append a device record to the records collection
function Assert-DeviceRecordIdentity {
    <#
    .SYNOPSIS
        Reject ambiguous local workflow identities without changing existing history.
    .DESCRIPTION
        Validates a collection before insertion or session reuse. Serial and record
        identifiers must be unique, including removed records. Configuration Items
        must be unique among non-removed records. Comparisons are case-insensitive.
    .PARAMETER Records
        Workflow records to validate; an empty collection is valid.
    .OUTPUTS
        None. Throws on conflicting identities without changing either record.
    #>
    param([AllowEmptyCollection()][System.Collections.IEnumerable]$Records = @())
    $serials = @{}
    $recordIds = @{}
    $configItems = @{}
    $selectionTokens = @{}
    foreach ($record in $Records) {
        $serial = ([string]$record.Serial).Trim()
        if ([string]::IsNullOrWhiteSpace($serial)) { throw 'A workflow record has no serial. Correct the saved record before continuing.' }
        if ($serials.ContainsKey($serial)) { throw ('Duplicate serial {0}. Resume its existing workflow instead of creating another record.' -f $serial) }
        $serials[$serial] = $true
        $recordId = ([string]$record.RecordId).Trim()
        if ($recordId) {
            if ($recordIds.ContainsKey($recordId)) { throw 'Duplicate workflow record ID. Correct the saved records before continuing.' }
            $recordIds[$recordId] = $true
        }
        $configItem = ([string]$record.ConfigItem).Trim()
        if ($record.Status -ne 'removed' -and $configItem) {
            if ($configItems.ContainsKey($configItem)) { throw ('Configuration Item {0} belongs to more than one active workflow. Resolve the conflict before continuing.' -f $configItem) }
            $configItems[$configItem] = $true
        }
        $recordTokens = @($serial)
        if ($record.Status -ne 'removed' -and $configItem) { $recordTokens += $configItem }
        foreach ($selectionToken in $recordTokens) {
            if (-not $selectionToken) { continue }
            if ($selectionTokens.ContainsKey($selectionToken) -and $selectionTokens[$selectionToken] -ne $serial) {
                throw 'A serial matches another workflow Configuration Item. Resolve the ambiguous scan identifier before continuing.'
            }
            $selectionTokens[$selectionToken] = $serial
        }
    }
}

function Add-DeviceRecord {
    <#
    .SYNOPSIS
        Validate identity uniqueness before appending to the caller's record container.
    .PARAMETER Records
        Mutable container whose Value holds the current record array.
    .PARAMETER Record
        Proposed device dictionary, checked against the existing records.
    .OUTPUTS
        None. Mutates Records.Value only; persistence remains the caller's responsibility.
    #>
    param(
        [Parameter(Mandatory)][hashtable]$Records,
        [Parameter(Mandatory)]$Record
    )
    $existingRecords = if ($null -eq $Records.Value) { @() } else { @($Records.Value) }
    $updatedRecords = @($existingRecords) + , $Record
    Assert-DeviceRecordIdentity -Records $updatedRecords
    $Records.Value = $updatedRecords
}

#endregion
#region Storage Authority and Persisted Evidence
function Get-RepoStorageBasePath {
    <#
    .SYNOPSIS
        Resolve the bootstrap-authorised repository storage base.
    .OUTPUTS
        Root path from resolved script state or its environment fallback; no directory creation.
    #>
    if (-not [string]::IsNullOrWhiteSpace($Script:AutopilotExpressProjectRoot)) {
        return $Script:AutopilotExpressProjectRoot
    }
    return $env:PowerShellScriptingNewRoot
}

function Get-FallbackStorageBasePath {
    <#
    .SYNOPSIS
        Locate the per-user LOCALAPPDATA fallback storage base.
    .OUTPUTS
        Absolute Autopilot Express fallback path; does not choose storage authority.
    #>
    return Join-Path $env:LOCALAPPDATA 'PowerShellScriptingNew\AutopilotExpress'
}

function Test-DirectoryWritable {
    <#
    .SYNOPSIS
        Probe directory access with a disposable file rather than assuming writability.
    .PARAMETER Path
        Candidate storage directory; no operational record is used as the probe.
    .OUTPUTS
        Boolean access result. Creates/removes the probe; failures return false.
    #>
    param([Parameter(Mandatory)][string]$Path)

    try {
        if (-not (Test-Path $Path)) {
            New-Item -ItemType Directory -Path $Path -Force -ErrorAction Stop | Out-Null
        }

        $probePath = Join-Path $Path ('.write-probe-{0}.tmp' -f [guid]::NewGuid().Guid)
        Set-Content -Path $probePath -Value 'probe' -Encoding (Get-StorageFileEncoding) -NoNewline -Force -ErrorAction SilentlyContinue
        if (-not (Test-Path $probePath)) { return $false }
        Remove-Item -Path $probePath -Force -ErrorAction Stop
        return $true
    }
    catch {
        return $false
    }
}

function Assert-StorageModeSupported {
    <#
    .SYNOPSIS
        Reject unsupported storage modes before any operational store access.
    .DESCRIPTION
        Missing storage settings retain legacy Local behaviour. An explicit mode
        must be Local. Shared transactions remain offline development work; a
        configured shared root must never silently fall back to local records.
    .OUTPUTS
        None. Throws for unsupported storage modes, including deferred Shared operation.
    #>
    param()
    $storageSettings = $Script:RuntimeConfig.storage
    if ($null -eq $storageSettings) { return }
    if ($storageSettings -isnot [System.Collections.IDictionary]) {
        throw 'Storage settings must be a dictionary with mode Local. No storage was opened.'
    }
    if (-not $storageSettings.Contains('mode')) { return }
    if ($storageSettings.mode -isnot [string] -or [string]::IsNullOrWhiteSpace($storageSettings.mode)) {
        throw 'Storage mode must be Local. Empty or non-text modes are not supported. No storage was opened.'
    }
    if ($storageSettings.mode -ne 'Local') {
        throw 'Only Local storage is supported by this entry point. Shared storage is disabled until transaction and concurrent-writer validation is complete. No local fallback or shared access was attempted.'
    }
}

function Get-OperationalStoragePath {
    <#
    .SYNOPSIS
        Resolve current-mode state paths without creating or selecting a root.
    .PARAMETER BasePath
        Repository or fallback base directory to inspect.
    .OUTPUTS
        Device, bench and recent-user paths, plus common Live audit and receipt
        paths. Receipt recovery artefacts resolve to their canonical target paths.
    #>
    param([Parameter(Mandatory)][ValidateNotNullOrEmpty()][string]$BasePath)
    $dataPath = Join-Path $BasePath $Script:Config.DataFolderRelative
    foreach ($prefix in @((Get-ModeUserDataFilePrefix), (Get-ModeBuildBenchFilePrefix), (Get-ModeRecentUsersFilePrefix))) {
        Join-Path $dataPath ('{0}-{1}.json' -f $prefix, $env:USERNAME)
    }
    $patternMode = if ($Script:Runtime.IsDemoMode) { 'demo' } else { 'live' }
    Join-Path $dataPath ('autopilot-work-pattern-{0}-{1}.json' -f $patternMode, $env:USERNAME)
    if ($Script:SessionFileNamesEnabled) {
        Get-SessionFileIndexPath -DataPath $dataPath
        $index = Get-SessionFileIndex -DataPath $dataPath
        if ($index) {
            Join-Path $dataPath $index.DeviceFile
            Join-Path $dataPath $index.BenchFile
        }
    }
    if (-not $Script:Runtime.IsDemoMode) {
        Join-Path $dataPath $Script:Config.MasterAuditFileName
        if (Test-Path -LiteralPath $dataPath) {
            Get-ChildItem -LiteralPath $dataPath -Filter '*submission-*.json*' -File -Force -ErrorAction Stop |
            ForEach-Object {
                if ($_.Name -cmatch '^((?:sync-submission|sync-intent-submission|autopilot-import-submission)-[A-Za-z0-9-]+\.json)(?:\.(?:pending|previous|write-in-progress))?$') {
                    Join-Path $dataPath $Matches[1]
                }
            } | Sort-Object -Unique
        }
    }
}

function Get-FallbackStorageAuthorityPath {
    <#
    .SYNOPSIS
        Locate durable fallback authority for this user and operational mode.
    .PARAMETER BasePath
        Fallback base directory; this helper never creates it.
    .OUTPUTS
        Marker path, separate from operational user files and session locks.
    #>
    param([Parameter(Mandatory)][ValidateNotNullOrEmpty()][string]$BasePath)
    $modeName = if ($Script:Runtime.IsDemoMode) { 'demo' } else { 'live' }
    Join-Path (Join-Path $BasePath $Script:Config.DataFolderRelative) ('autopilot-express-{0}-{1}.storage-authority' -f $modeName, $env:USERNAME)
}

function Test-FallbackStorageAuthority {
    <#
    .SYNOPSIS
        Validate completed migration authority without using file timestamps.
    .DESCRIPTION
        The versioned marker must exactly identify this mode, user and data root.
        Missing markers return false; malformed or interrupted markers fail closed.
    .PARAMETER BasePath
        Fallback base directory whose marker is being checked.
    .OUTPUTS
        True only for the exact completed-migration marker.
    #>
    [OutputType([bool])]
    param([Parameter(Mandatory)][ValidateNotNullOrEmpty()][string]$BasePath)
    $path = Get-FallbackStorageAuthorityPath -BasePath $BasePath
    Assert-FileWriteRecoveryState -Path $path
    if (-not (Test-Path -LiteralPath $path)) { return $false }
    $modeName = if ($Script:Runtime.IsDemoMode) { 'demo' } else { 'live' }
    $dataPath = Join-Path $BasePath $Script:Config.DataFolderRelative
    $expected = 'AutopilotExpressFallbackAuthority/1|{0}|{1}|{2}' -f $modeName, $env:USERNAME, $dataPath
    $content = Get-Content -LiteralPath $path -Raw -Encoding UTF8 -ErrorAction Stop
    if ($content -cne $expected) {
        throw ('Invalid fallback storage authority at {0}. Preserve the marker and both roots for operator review; no migration was attempted.' -f $path)
    }
    return $true
}

function Assert-ActiveStorageReservation {
    <#
    .SYNOPSIS
        Require the current invocation's current-root lock before migration writes.
    .DESCRIPTION
        Validates the startup lock path, token and process against the selected
        root. Missing or changed ownership never authorises a copy or marker save.
    .OUTPUTS
        None. Throws unless the active process still owns the exact reservation.
    #>
    $lockVariable = Get-Variable -Name localSessionLock -Scope Script -ErrorAction SilentlyContinue
    $lock = if ($null -ne $lockVariable) { $lockVariable.Value } else { $null }
    $modeName = if ($Script:Runtime.IsDemoMode) { 'demo' } else { 'live' }
    $expectedPath = Join-Path $Script:Storage.DataPath ('autopilot-express-{0}.session.lock' -f $modeName)
    if (-not $Script:Storage.Initialised -or $lock -isnot [System.Collections.IDictionary] -or
        $lock.Path -ne $expectedPath -or [string]::IsNullOrWhiteSpace([string]$lock.Token)) {
        throw 'Storage migration requires the current-root session reservation. Nothing was written.'
    }
    $owner = Get-Content -LiteralPath $expectedPath -Raw -ErrorAction Stop | ConvertFrom-Json -ErrorAction Stop
    if ($owner.Token -cne $lock.Token -or $owner.ProcessId -ne $PID) {
        throw 'Storage migration reservation ownership changed. Nothing further was written.'
    }
}

function Initialize-StorageLocation {
    <#
    .SYNOPSIS
        Select one stable authoritative local root before reserving the session.
    .DESCRIPTION
        Existing fallback state or completed migration authority takes precedence
        over repository writability. An unavailable authoritative fallback is an
        error, never permission to resume an older repository copy. Both roots'
        current-mode checkpoint proposals must be absent before probing either
        root; migration authority cannot hide unfinished source writes.
    .OUTPUTS
        None. Selects validated storage authority; ambiguous or unrecovered evidence blocks startup.
    #>
    Assert-StorageModeSupported
    if ($Script:Storage.Initialised) { return }

    $repoBasePath = Get-RepoStorageBasePath
    $repoDataPath = Join-Path $repoBasePath $Script:Config.DataFolderRelative
    $fallbackBasePath = Get-FallbackStorageBasePath
    $fallbackDataPath = Join-Path $fallbackBasePath $Script:Config.DataFolderRelative

    Assert-LocalCheckpointState -BasePath $repoBasePath
    Assert-LocalCheckpointState -BasePath $fallbackBasePath

    $preferFallback = $false
    if (Test-Path -LiteralPath $fallbackDataPath) {
        $preferFallback = Test-FallbackStorageAuthority -BasePath $fallbackBasePath
        foreach ($path in @(Get-OperationalStoragePath -BasePath $fallbackBasePath)) {
            Assert-FileWriteRecoveryState -Path $path
            if (Test-Path -LiteralPath $path) { $preferFallback = $true }
        }
    }

    if (-not $preferFallback -and (Test-DirectoryWritable -Path $repoDataPath)) {
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

function Start-SharedStoreReservation {
    <#
    .SYNOPSIS
        Reserve an existing filesystem root for offline snapshot development.
    .DESCRIPTION
        Exclusive file creation has no timeout or automatic takeover. This helper
        is not wired into the CLI and does not certify network filesystem locking.
    .PARAMETER Root
        Existing isolated development directory; never created automatically.
    .OUTPUTS
        Reservation path and unique ownership token for snapshot helpers.
    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '', Justification = 'Mandatory offline reservation uses exclusive creation; WhatIf cannot establish ownership and ShouldProcess is unavailable in ConstrainedLanguage.')]
    [CmdletBinding()]
    [OutputType([hashtable])]
    param([Parameter(Mandatory)][ValidateNotNullOrEmpty()][string]$Root)
    $directory = Get-Item -LiteralPath $Root -ErrorAction Stop
    if ($directory.PSProvider.Name -ne 'FileSystem' -or -not $directory.PSIsContainer) { throw 'Snapshot root must be an existing filesystem directory.' }
    $path = Join-Path $directory.FullName 'autopilot-shared.snapshot.lock'
    $token = [guid]::NewGuid().Guid
    $owner = @{ Token = $token; User = $env:USERNAME; Computer = $env:COMPUTERNAME; ProcessId = $PID; StartedAt = (Get-Date -Format o) }
    New-Item -ItemType File -Path $path -Value ($owner | ConvertTo-Json -Compress) -ErrorAction Stop | Out-Null
    return @{ Path = $path; Token = $token }
}

function Assert-SharedStoreReservation {
    <#
    .SYNOPSIS
        Check that snapshot access owns this root's reservation.
    .PARAMETER Root
        Existing filesystem directory containing the snapshot and reservation.
    .PARAMETER Lock
        Ownership token and path returned by Start-SharedStoreReservation.
    .OUTPUTS
        None. Retained safety guard; does not enable deferred Shared operation.
    #>
    param(
        [Parameter(Mandatory)][ValidateNotNullOrEmpty()][string]$Root,
        [Parameter(Mandatory)][ValidateNotNullOrEmpty()][hashtable]$Lock
    )
    $directory = Get-Item -LiteralPath $Root -ErrorAction Stop
    if ($directory.PSProvider.Name -ne 'FileSystem' -or -not $directory.PSIsContainer) { throw 'Snapshot root must be an existing filesystem directory.' }
    $expectedPath = Join-Path $directory.FullName 'autopilot-shared.snapshot.lock'
    if ($Lock.Path -ne $expectedPath -or [string]::IsNullOrWhiteSpace([string]$Lock.Token)) { throw 'Snapshot reservation does not belong to this root.' }
    $owner = Get-Content -LiteralPath $expectedPath -Raw -ErrorAction Stop | ConvertFrom-Json -ErrorAction Stop
    if ($owner.Token -cne $Lock.Token) { throw 'Snapshot reservation ownership changed. No snapshot was accessed.' }
}

function Assert-SharedStoreSnapshot {
    <#
    .SYNOPSIS
        Validate the offline snapshot envelope and cross-record bench identities.
    .PARAMETER Snapshot
        Normalised dictionary containing schema, revision, devices, bench and audit.
    .OUTPUTS
        None. Rejects changed shared snapshots rather than overwriting concurrent evidence.
    #>
    param([Parameter(Mandatory)][AllowEmptyCollection()][ValidateNotNull()][System.Collections.IDictionary]$Snapshot)
    if (($Snapshot.SchemaVersion -isnot [int] -and $Snapshot.SchemaVersion -isnot [long]) -or $Snapshot.SchemaVersion -ne 1 -or
        ($Snapshot.Revision -isnot [int] -and $Snapshot.Revision -isnot [long]) -or
        $Snapshot.Revision -lt 0 -or $Snapshot.Revision -ge [int]::MaxValue -or
        $Snapshot.Devices -isnot [array] -or $Snapshot.Audit -isnot [array] -or
        $Snapshot.Bench -isnot [System.Collections.IDictionary] -or $Snapshot.Bench.Positions -isnot [array]) {
        throw 'Invalid shared snapshot envelope. No empty-state substitution is permitted.'
    }
    foreach ($device in $Snapshot.Devices) {
        if ($device -isnot [System.Collections.IDictionary] -or
            $device.RecordId -isnot [string] -or [string]::IsNullOrWhiteSpace($device.RecordId) -or
            $device.Serial -isnot [string] -or [string]::IsNullOrWhiteSpace($device.Serial)) {
            throw 'Shared snapshot devices require dictionary records with textual record IDs and serials.'
        }
        if ($device.Contains('Status') -and ($device.Status -isnot [string] -or
                $device.Status -notin @('new', 'in-progress', 'completed', 'removed'))) {
            throw 'Shared snapshot device status must be new, in-progress, completed or removed.'
        }
    }
    Assert-DeviceRecordIdentity -Records $Snapshot.Devices
    Assert-AttemptHistoryPreserved -Records $Snapshot.Devices
    Assert-BenchPositionIdentity -Positions $Snapshot.Bench.Positions
    foreach ($device in $Snapshot.Devices) {
        if ([string]::IsNullOrWhiteSpace([string]$device.RecordId)) { throw 'Shared snapshot devices require stable record IDs.' }
    }
    foreach ($position in $Snapshot.Bench.Positions) {
        if (-not $position.Serial) { continue }
        $benchMatches = @($Snapshot.Devices | Where-Object { $_.Serial -eq $position.Serial -and $_.Status -notin @('removed', 'completed') })
        if ($benchMatches.Count -ne 1 -or $benchMatches[0].ConfigItem -ne $position.ConfigItem) {
            throw 'Shared snapshot bench identity does not match one active device record.'
        }
    }
    foreach ($entry in $Snapshot.Audit) {
        if ($entry -isnot [System.Collections.IDictionary]) { throw 'Shared snapshot audit entries must be dictionaries.' }
    }
}

function Get-SharedStoreSnapshot {
    <#
    .SYNOPSIS
        Read one complete offline snapshot under the caller's reservation.
    .DESCRIPTION
        Missing initial storage returns revision zero. Malformed or interrupted
        saves fail closed. No migration, repair or tenant action is attempted.
    .PARAMETER Root
        Isolated snapshot directory, not selected by runtime storage settings.
    .PARAMETER Lock
        Reservation owned by the caller.
    .OUTPUTS
        Normalised snapshot dictionary; arrays remain arrays on both hosts.
    #>
    param(
        [Parameter(Mandatory)][ValidateNotNullOrEmpty()][string]$Root,
        [Parameter(Mandatory)][ValidateNotNullOrEmpty()][hashtable]$Lock
    )
    Assert-SharedStoreReservation -Root $Root -Lock $Lock
    $path = Join-Path $Root 'autopilot-shared.snapshot.json'
    Assert-FileWriteRecoveryState -Path $path
    if (-not (Test-Path -LiteralPath $path)) {
        return @{ SchemaVersion = 1; Revision = 0; Devices = @(); Bench = @{ Positions = @() }; Audit = @() }
    }
    $content = Get-Content -LiteralPath $path -Raw -Encoding UTF8 -ErrorAction Stop
    if ([string]::IsNullOrWhiteSpace([string]$content)) { throw 'Shared snapshot file is empty; no revision-zero substitution is permitted.' }
    $raw = $content | ConvertFrom-Json -ErrorAction Stop
    $snapshot = ConvertTo-NormalisedValue -Value $raw
    Assert-SharedStoreSnapshot -Snapshot $snapshot
    return $snapshot
}

function Get-SharedStoreRecoveryInspection {
    <#
    .SYNOPSIS
        Inspect retained snapshot copies without repairing or approving recovery.
    .DESCRIPTION
        Requires the caller's reservation before and after inspection. Each copy
        is validated independently; invalid content is reported, never substituted.
        No files are changed, and no candidate is selected for promotion.
    .PARAMETER Root
        Isolated development root containing the snapshot and recovery artefacts.
    .PARAMETER Lock
        Current reservation owned by the caller.
    .OUTPUTS
        Read-only evidence report with copy summaries and validated snapshots.
    #>
    param(
        [Parameter(Mandatory)][ValidateNotNullOrEmpty()][string]$Root,
        [Parameter(Mandatory)][ValidateNotNullOrEmpty()][hashtable]$Lock
    )
    Assert-SharedStoreReservation -Root $Root -Lock $Lock
    $path = Join-Path $Root 'autopilot-shared.snapshot.json'
    $copies = @()
    foreach ($suffix in @('', '.pending', '.previous')) {
        $copyPath = '{0}{1}' -f $path, $suffix
        $copy = @{ Path = $copyPath; Exists = $false; State = 'Missing'; Revision = $null; DeviceCount = $null; PositionCount = $null; AuditCount = $null; Snapshot = $null }
        if (Test-Path -LiteralPath $copyPath) {
            $copy.Exists = $true
            $copy.State = 'Invalid'
            try {
                $content = Get-Content -LiteralPath $copyPath -Raw -Encoding UTF8 -ErrorAction Stop
                if (-not [string]::IsNullOrWhiteSpace([string]$content)) {
                    $snapshot = ConvertTo-NormalisedValue -Value ($content | ConvertFrom-Json -ErrorAction Stop)
                    Assert-SharedStoreSnapshot -Snapshot $snapshot
                    $copy.State = 'Valid'
                    $copy.Revision = $snapshot.Revision
                    $copy.DeviceCount = $snapshot.Devices.Count
                    $copy.PositionCount = $snapshot.Bench.Positions.Count
                    $copy.AuditCount = $snapshot.Audit.Count
                    $copy.Snapshot = $snapshot
                }
            }
            catch { $copy.State = 'Invalid' }
        }
        $copies += $copy
    }
    $markerPresent = Test-Path -LiteralPath ('{0}.write-in-progress' -f $path)
    $reviewRequired = $markerPresent -or $copies[1].Exists -or
    (-not $copies[0].Exists -and $copies[2].Exists) -or
    @($copies | Where-Object { $_.State -eq 'Invalid' }).Count -gt 0
    Assert-SharedStoreReservation -Root $Root -Lock $Lock
    return @{ Root = $Root; MarkerPresent = $markerPresent; ReviewRequired = [bool]$reviewRequired; RecoveryApproved = $false; Copies = $copies }
}

function Get-SharedStoreMigrationPreview {
    <#
    .SYNOPSIS
        Preview an initial snapshot import without changing either store.
    .DESCRIPTION
        Offline development only. Validates captured source evidence and requires
        a pristine destination under the caller's reservation. Does not merge,
        approve migration, capture local files or certify source consistency.
    .PARAMETER Root
        Isolated development destination, not the configured runtime store.
    .PARAMETER Lock
        Destination reservation owned by the caller throughout the preview.
    .PARAMETER SourceSnapshot
        Captured, normalised snapshot envelope for operator review. All record,
        history, bench and audit evidence is copied without rewriting identities.
    .OUTPUTS
        Detached proposal and counts; MigrationApproved is always false.
    #>
    param(
        [Parameter(Mandatory)][ValidateNotNullOrEmpty()][string]$Root,
        [Parameter(Mandatory)][ValidateNotNullOrEmpty()][hashtable]$Lock,
        [Parameter(Mandatory)][ValidateNotNullOrEmpty()][System.Collections.IDictionary]$SourceSnapshot
    )
    $current = Get-SharedStoreSnapshot -Root $Root -Lock $Lock
    $proposal = ConvertTo-NormalisedValue -Value $SourceSnapshot
    Assert-SharedStoreSnapshot -Snapshot $proposal
    if ($current.Revision -ne 0 -or $current.Devices.Count -ne 0 -or
        $current.Bench.Positions.Count -ne 0 -or $current.Audit.Count -ne 0) {
        throw 'Shared migration preview requires a pristine destination; existing state cannot be merged or replaced.'
    }
    $sourceRevision = $proposal.Revision
    $proposal.Revision = $current.Revision
    Assert-SharedStoreReservation -Root $Root -Lock $Lock
    return @{
        ExpectedRevision = $current.Revision; SourceRevision = $sourceRevision
        DeviceCount = $proposal.Devices.Count; PositionCount = $proposal.Bench.Positions.Count
        AuditCount = $proposal.Audit.Count; ReviewRequired = $true
        MigrationApproved = $false; Snapshot = $proposal
    }
}

function Write-SharedStoreSnapshot {
    <#
    .SYNOPSIS
        Save devices, bench and append-only audit together with a revision check.
    .DESCRIPTION
        Offline development only. Requires the original reservation and current
        revision; preserves the audit prefix and retained workflow IDs and serials. Uses the
        recoverable single-file writer, not a claim of atomic network replacement.
    .PARAMETER Root
        Isolated snapshot directory.
    .PARAMETER Lock
        Reservation owned by the caller.
    .PARAMETER ExpectedRevision
        Revision read before the edit; stale callers are rejected without writing.
    .PARAMETER Snapshot
        Complete proposed envelope; caller revision must equal ExpectedRevision.
    .OUTPUTS
        Committed revision, returned only after save verification succeeds.
    #>
    param(
        [Parameter(Mandatory)][ValidateNotNullOrEmpty()][string]$Root,
        [Parameter(Mandatory)][ValidateNotNullOrEmpty()][hashtable]$Lock,
        [Parameter(Mandatory)][ValidateRange(0, 2147483645)][int]$ExpectedRevision,
        [Parameter(Mandatory)][ValidateNotNullOrEmpty()][System.Collections.IDictionary]$Snapshot
    )
    $current = Get-SharedStoreSnapshot -Root $Root -Lock $Lock
    $proposed = ConvertTo-NormalisedValue -Value $Snapshot
    Assert-SharedStoreSnapshot -Snapshot $proposed
    if ($current.Revision -ne $ExpectedRevision -or $proposed.Revision -ne $ExpectedRevision) { throw 'Shared snapshot revision conflict. Reload before editing; nothing was written.' }
    if ($proposed.Audit.Count -lt $current.Audit.Count) { throw 'Shared snapshot audit history cannot be truncated.' }
    for ($index = 0; $index -lt $current.Audit.Count; $index++) {
        if (-not (Test-AttemptEvidenceEqual -Left $current.Audit[$index] -Right $proposed.Audit[$index])) {
            throw 'Shared snapshot audit history cannot be rewritten or reordered.'
        }
    }
    foreach ($device in $current.Devices) {
        $retained = @($proposed.Devices | Where-Object { $_.RecordId -eq $device.RecordId })
        if ($retained.Count -ne 1) { throw 'Shared snapshot workflow records must be retained, including removed records.' }
        if (([string]$retained[0].Serial).Trim() -ine ([string]$device.Serial).Trim()) {
            throw 'Shared snapshot workflow serial identity cannot be reassigned to another device.'
        }
    }
    Assert-AttemptHistoryPreserved -Records $proposed.Devices -ExistingRecords $current.Devices
    $proposed.Revision = $ExpectedRevision + 1
    $proposed.LastWriter = @{ User = $env:USERNAME; Computer = $env:COMPUTERNAME; ProcessId = $PID; SavedAt = (Get-Date -Format o) }
    Assert-SharedStoreReservation -Root $Root -Lock $Lock
    Write-Utf8File -Path (Join-Path $Root 'autopilot-shared.snapshot.json') -Content ($proposed | ConvertTo-Json -Depth 100)
    return $proposed.Revision
}

function Get-StorageBasePath {
    <#
    .SYNOPSIS
        Return the initialised authoritative storage base.
    .OUTPUTS
        Selected base path after storage initialisation; not an arbitrary newest-file selection.
    #>
    Initialize-StorageLocation
    return $Script:Storage.BasePath
}

function Get-DataFolderPath {
    <#
    .SYNOPSIS
        Resolve and prepare the data directory under a selected base.
    .PARAMETER BasePath
        Optional explicit base for guarded storage preflight; otherwise use current authority.
    .OUTPUTS
        Data directory path. Directory preparation may throw on access failure.
    #>
    param([string]$BasePath)

    $resolvedBasePath = if ($BasePath) { $BasePath } else { Get-StorageBasePath }
    $dataFolder = Join-Path $resolvedBasePath $Script:Config.DataFolderRelative
    if (-not (Test-Path $dataFolder)) {
        New-Item -ItemType Directory -Path $dataFolder -Force -ErrorAction Stop | Out-Null
    }
    return $dataFolder
}

function Get-ArchiveFolderPath {
    <#
    .SYNOPSIS
        Resolve and prepare the archive directory outside active record discovery.
    .PARAMETER BasePath
        Optional explicit storage base; otherwise use current authority.
    .OUTPUTS
        Archive directory path; does not move or remove any evidence.
    #>
    param([string]$BasePath)

    $archiveFolder = Join-Path (Get-DataFolderPath -BasePath $BasePath) $Script:Config.ArchiveFolderRelative
    if (-not (Test-Path $archiveFolder)) {
        New-Item -ItemType Directory -Path $archiveFolder -Force -ErrorAction Stop | Out-Null
    }
    return $archiveFolder
}

function Start-LocalSessionLock {
    <#
    .SYNOPSIS
        Exclusively reserve the resolved local store before session access.
    .DESCRIPTION
        Holds an OS-exclusive sidecar handle for the complete invocation and creates
        readable version-two ownership metadata without Force. Windows releases the
        handle when the process dies; finally releases it when the script exits.
        A remaining metadata file requires backed-up recovery, not age-based expiry.
        FullLanguage is required; policy restrictions never downgrade exclusivity.
    .OUTPUTS
        Hashtable containing the metadata path, token and owned disposable handle.
    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '', Justification = 'Mandatory internal reservation cannot support WhatIf; PSCmdlet.ShouldProcess is blocked in ConstrainedLanguage. Exclusive file creation is the safety gate.')]
    [CmdletBinding()]
    [OutputType([hashtable])]
    param()
    $modeName = if ($Script:Runtime.IsDemoMode) { 'demo' } else { 'live' }
    $path = Join-Path (Get-DataFolderPath) ('autopilot-express-{0}.session.lock' -f $modeName)
    $token = [guid]::NewGuid().Guid
    $handle = $null
    try {
        if ($ExecutionContext.SessionState.LanguageMode -ne 'FullLanguage') { throw 'An OS-held reservation requires an approved FullLanguage host. Policy was not changed; no weaker reservation was created.' }
        if (Test-Path -LiteralPath $path) { throw 'Existing session ownership metadata requires guarded recovery before acquisition.' }
        $handle = [IO.File]::Open(($path + '.lease'), [IO.FileMode]::OpenOrCreate, [IO.FileAccess]::ReadWrite, [IO.FileShare]::None)
        $payload = @{ ReservationVersion = 2; Token = $token; User = $env:USERNAME; Computer = $env:COMPUTERNAME; ProcessId = $PID; ProcessStartedAt = [Diagnostics.Process]::GetCurrentProcess().StartTime.ToUniversalTime().ToString('o'); StartedAt = (Get-Date -Format o) }
        New-Item -ItemType File -Path $path -Value ($payload | ConvertTo-Json -Compress) -ErrorAction Stop | Out-Null
    }
    catch {
        if ($handle) { $handle.Dispose() }
        throw ('Cannot reserve local {0} storage. Another session or an unrecovered lock may exist at {1}. Inspect without authentication: .\autopilot-express.ps1 -SessionLockAction Inspect -SessionLockPath ''{1}''. After all sessions using this store have stopped, recover with -SessionLockAction Recover -SessionLockPath ''{1}'' -ConfirmStopped. Recovery refuses an active or unverified owner and preserves the lock as evidence; write/checkpoint markers are never removed. No session data or tenant actions were started. Detail: {2}' -f $modeName, $path, $_.Exception.Message)
    }
    return @{ Path = $path; Token = $token; Handle = $handle }
}

function Request-LocalSessionLock {
    <#
    .SYNOPSIS
        Acquire a reservation or keep the technician in guarded startup recovery.
    .DESCRIPTION
        Existing locks are inspected before authentication or session loading. Retry
        reattempts exclusive acquisition. Recovery requires explicit confirmation of
        stopped sessions, verified local ownership and an unchanged evidence copy.
        Return defaults to no changes; active, foreign and unreadable locks never
        authorise unlocked startup. No checkpoint or device evidence is repaired here.
    .OUTPUTS
        Owned lock dictionary, or null when the technician returns without starting.
    #>
    [OutputType([hashtable])]
    param()
    $modeName = if ($Script:Runtime.IsDemoMode) { 'demo' } else { 'live' }
    $path = Join-Path (Get-DataFolderPath) ('autopilot-express-{0}.session.lock' -f $modeName)
    while ($true) {
        try { return Start-LocalSessionLock }
        catch { $reservationMessage = $_.Exception.Message }
        Write-Host ''
        Write-Host 'Storage reservation requires attention. No session data or tenant actions have started.'
        Write-Host ('Lock: {0}' -f $path)
        $inspection = $null
        if (Test-Path -LiteralPath $path) {
            try {
                $inspection = Invoke-LocalSessionLockRecovery -Path $path
                Write-Host ('Owner: {0} on {1}; process: {2}; state: {3}' -f $inspection.User, $inspection.Computer, $inspection.ProcessId, $inspection.State)
                Write-Host ('Current executable: {0}; process started: {1}' -f $inspection.ProcessPath, $inspection.ProcessStartedAt)
                if ($inspection.State -eq 'ActiveOrReusedProcessId') { Write-Host 'Close the identified original PowerShell host before retrying. This script will not terminate it.' }
            }
            catch { Write-Host ('Lock inspection refused: {0}' -f $_.Exception.Message) }
        }
        else { Write-Host ('Reservation could not be created: {0}' -f $reservationMessage) }
        $choices = @('R', '0')
        Write-Host ''
        Write-Host '[R] Retry after the owning session has closed or the storage problem is resolved'
        if ($inspection -and $inspection.CanRecover) {
            $choices = @('R', 'C', '0')
            Write-Host '[C] Back up saved work, recover the released reservation, then resume'
        }
        else { Write-Host '    (Recovery is unavailable here: active, foreign, cloud-backed or unverified ownership must be resolved on the owning computer.)' }
        Write-Host '[0] Return without starting or changing session evidence'
        $choice = Read-ValidatedInput -Prompt ('Choose {0}' -f ($choices -join ', ')) -Default '0' -Type Choice -Choices $choices
        if ($choice -eq '0') { return $null }
        if ($choice -eq 'C') {
            $confirmation = Read-ValidatedInput -Prompt 'Have ALL scripts using this store stopped? Back up, recover and resume? [Y] Yes [N] No' -Default 'N' -Type Choice -Choices @('Y', 'N')
            if ($confirmation -ne 'Y') { continue }
            try {
                $recovered = Invoke-LocalSessionLockRecovery -Path $path -Recover -ConfirmStopped -Confirm:$false
                if ($recovered.State -ne 'Recovered') { throw 'Recovery did not release the reservation.' }
                Write-Host ('Stopped-lock evidence retained: {0}' -f $recovered.EvidencePath)
                Write-Host ('Verified complete session backup: {0}' -f $recovered.SessionBackupPath)
                $Script:ResumeRecoveredSession = $true
                Write-Host 'Acquiring a fresh reservation; remaining checkpoint/write markers will still be checked.'
            }
            catch { Write-Host ('Recovery refused; startup remains in reservation recovery: {0}' -f $_.Exception.Message) }
        }
    }
}

function Get-LocalSessionRecoveryInventory {
    <#
    .SYNOPSIS
        Hash every saved file and recovery artefact without following reparse points.
    .PARAMETER DataPath
        Exact authoritative data directory; only the two OS lease sidecars are excluded.
    .OUTPUTS
        File inventory with relative names, sizes, source paths and SHA-256 hashes.
    #>
    [OutputType([object[]])]
    param([Parameter(Mandatory)][ValidateNotNullOrEmpty()][string]$DataPath)
    $root = [IO.Path]::GetFullPath($DataPath).TrimEnd([IO.Path]::DirectorySeparatorChar)
    $pending = [System.Collections.Generic.Queue[string]]::new()
    $pending.Enqueue($root)
    while ($pending.Count) {
        $directory = $pending.Dequeue()
        foreach ($item in Get-ChildItem -LiteralPath $directory -Force -ErrorAction Stop) {
            if ($directory -eq $root -and $item.Name -match '^autopilot-express-(live|demo)\.session\.lock\.lease$' -and -not $item.PSIsContainer) { continue }
            if ($item.Attributes -band [IO.FileAttributes]::ReparsePoint) { throw ('Session backup refuses a reparse-backed artefact: {0}. No reservation was released.' -f $item.FullName) }
            if ($item.PSIsContainer) { $pending.Enqueue($item.FullName); continue }
            [pscustomobject]@{ RelativePath = $item.FullName.Substring($root.Length + 1); Length = $item.Length; SourcePath = $item.FullName; SHA256 = (Get-FileHash -LiteralPath $item.FullName -Algorithm SHA256 -ErrorAction Stop).Hash }
        }
    }
}

function Get-RecoveryEvidenceTenantKey {
    <#
    .SYNOPSIS
        Name the tenant folder used to organise retained recovery evidence (BACKUP-POLICY).
    .DESCRIPTION
        Reads only top-level JSON text in the given folder and extracts persisted TenantId GUIDs
        without parsing or validating workflow records, so a damaged store can still be backed up.
        Organisation is a filing aid only: it never authorises, binds or migrates a tenant.
    .PARAMETER Folder
        Session data folder, or the files folder of a retained snapshot.
    .PARAMETER Mode
        Live, Demo or Unknown. Demo evidence always files under 'demo'.
    .OUTPUTS
        Lower-case tenant GUID, or 'demo', 'tenant-mixed', 'tenant-unbound' or 'tenant-unknown'.
        Never throws; any read failure files the evidence under 'tenant-unknown'.
    #>
    [OutputType([string])]
    param(
        [Parameter(Mandatory)][ValidateNotNullOrEmpty()][string]$Folder,
        [ValidateSet('Live', 'Demo', 'Unknown')][string]$Mode = 'Unknown'
    )
    if ($Mode -eq 'Demo') { return 'demo' }
    $guidPattern = '[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}'
    try {
        $files = @(Get-ChildItem -LiteralPath $Folder -Filter '*.json' -File -ErrorAction Stop)
        $tenants = [Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
        # Files larger than 64 MB are not record stores; skipping them keeps the scan bounded.
        foreach ($file in @($files | Where-Object { $_.Length -le 64MB })) {
            $text = [IO.File]::ReadAllText($file.FullName)
            foreach ($match in [regex]::Matches($text, ('"TenantId"\s*:\s*"({0})"' -f $guidPattern))) { [void]$tenants.Add($match.Groups[1].Value.ToLowerInvariant()) }
        }
        if ($tenants.Count -gt 1) { return 'tenant-mixed' }
        if ($tenants.Count -eq 1) { return @($tenants)[0] }
        if ($Mode -eq 'Live') {
            $configured = [string]$Script:RuntimeConfig.graph.expectedTenantId
            if ($configured -match ('^{0}$' -f $guidPattern)) { return $configured.ToLowerInvariant() }
            return 'tenant-unbound'
        }
        $names = @($files.Name)
        if (@($names -like 'autopilot-session-demo-*').Count -and -not @($names -like 'autopilot-session-live-*').Count) { return 'demo' }
        return 'tenant-unbound'
    }
    catch { return 'tenant-unknown' }
}

function Get-RecoveryEvidenceFolder {
    <#
    .SYNOPSIS
        Resolve the organised date and tenant folder for one kind of recovery evidence.
    .DESCRIPTION
        BACKUP-POLICY layout: <LOCALAPPDATA>\PowerShellScriptingNew\AutopilotExpressRecoveryEvidence\
        <Kind>\<yyyy-MM-dd>\<TenantKey>. Without -Kind the evidence root is returned. Nothing is created.
    .PARAMETER Kind
        SessionSnapshots or CrashLocks; omit for the evidence root.
    .PARAMETER TenantKey
        Value from Get-RecoveryEvidenceTenantKey.
    .PARAMETER Timestamp
        Evidence creation time used for the date folder.
    .OUTPUTS
        Full folder path as text.
    #>
    [OutputType([string])]
    param(
        [ValidateSet('SessionSnapshots', 'CrashLocks')][string]$Kind,
        [string]$TenantKey = 'tenant-unknown',
        [datetime]$Timestamp = (Get-Date)
    )
    $root = Join-Path $env:LOCALAPPDATA 'PowerShellScriptingNew\AutopilotExpressRecoveryEvidence'
    if (-not $Kind) { return $root }
    # Only known key shapes become folder names; anything else is filed as unknown.
    if ($TenantKey -notmatch '^([0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}|demo|tenant-(mixed|unbound|unknown))$') { $TenantKey = 'tenant-unknown' }
    return Join-Path $root ('{0}\{1}\{2}' -f $Kind, $Timestamp.ToString('yyyy-MM-dd'), $TenantKey)
}

function Get-RecoveryEvidenceInventory {
    <#
    .SYNOPSIS
        List every retained recovery backup with its kind, layout, date, tenant and size.
    .DESCRIPTION
        Read-only. Organised entries sit at <Kind>\<date>\<tenant>\<item>. Older flat entries directly
        under SessionSnapshots or CrashLocks are reported as Legacy so they can be organised. Anything
        else under the evidence root (for example workflow-ID conversion backups, whose paths are
        recorded in migration markers) is reported as Other and is never moved.
    .OUTPUTS
        PSCustomObjects: Kind, Layout (Organised, Legacy or Other), Date, Tenant, Path, Bytes, Files.
    #>
    [OutputType([pscustomobject])]
    param()
    $root = Get-RecoveryEvidenceFolder
    if (-not (Test-Path -LiteralPath $root -PathType Container)) { return }
    foreach ($item in Get-ChildItem -LiteralPath $root -Force -ErrorAction Stop) {
        $entries = @()
        if ($item.PSIsContainer -and $item.Name -in @('SessionSnapshots', 'CrashLocks')) {
            foreach ($child in Get-ChildItem -LiteralPath $item.FullName -Force -ErrorAction Stop) {
                if ($child.PSIsContainer -and $child.Name -match '^\d{4}-\d{2}-\d{2}$') {
                    foreach ($tenantFolder in @(Get-ChildItem -LiteralPath $child.FullName -Directory -Force -ErrorAction Stop)) {
                        foreach ($evidence in Get-ChildItem -LiteralPath $tenantFolder.FullName -Force -ErrorAction Stop) {
                            $entries += @{ Kind = $item.Name; Layout = 'Organised'; Date = $child.Name; Tenant = $tenantFolder.Name; Item = $evidence }
                        }
                    }
                    continue
                }
                $date = if ($child.Name -match '^(\d{4})(\d{2})(\d{2})-') { '{0}-{1}-{2}' -f $Matches[1], $Matches[2], $Matches[3] } else { $child.LastWriteTime.ToString('yyyy-MM-dd') }
                $entries += @{ Kind = $item.Name; Layout = 'Legacy'; Date = $date; Tenant = ''; Item = $child }
            }
        }
        else { $entries += @{ Kind = 'Other'; Layout = 'Other'; Date = $item.LastWriteTime.ToString('yyyy-MM-dd'); Tenant = ''; Item = $item } }
        foreach ($entry in $entries) {
            $sizedFiles = if ($entry.Item.PSIsContainer) { @(Get-ChildItem -LiteralPath $entry.Item.FullName -File -Recurse -Force -ErrorAction Stop) } else { @($entry.Item) }
            [pscustomobject]@{
                Kind   = $entry.Kind
                Layout = $entry.Layout
                Date   = $entry.Date
                Tenant = $entry.Tenant
                Path   = $entry.Item.FullName
                Bytes  = [long](($sizedFiles | Measure-Object -Property Length -Sum).Sum)
                Files  = $sizedFiles.Count
            }
        }
    }
}

function Move-RecoveryEvidenceToOrganisedLayout {
    <#
    .SYNOPSIS
        Move older flat session snapshots and crash-lock evidence into date and tenant folders.
    .DESCRIPTION
        Owner policy (keep all, organise): nothing is deleted, renamed or rewritten. Each legacy item is
        moved whole, keeping its original name, to <Kind>\<date>\<tenant>. Snapshot tenants come from the
        snapshot's own files; crash-lock evidence carries no tenant and is filed as tenant-unknown.
        Reparse-backed items and name collisions are skipped and reported, never overwritten.
    .OUTPUTS
        Hashtable: Moved, Skipped and Lines (one readable outcome per item, also logged).
    #>
    [CmdletBinding(SupportsShouldProcess)]
    [OutputType([hashtable])]
    param()
    $result = @{ Moved = 0; Skipped = 0; Lines = [Collections.Generic.List[string]]::new() }
    foreach ($entry in @(Get-RecoveryEvidenceInventory | Where-Object Layout -eq 'Legacy')) {
        $item = Get-Item -LiteralPath $entry.Path -Force -ErrorAction Stop
        $tenantKey = 'tenant-unknown'
        if ($entry.Kind -eq 'SessionSnapshots' -and $item.PSIsContainer) {
            $snapshotFiles = Join-Path $item.FullName 'files'
            if (Test-Path -LiteralPath $snapshotFiles -PathType Container) { $tenantKey = Get-RecoveryEvidenceTenantKey -Folder $snapshotFiles }
        }
        $targetFolder = Get-RecoveryEvidenceFolder -Kind $entry.Kind -TenantKey $tenantKey -Timestamp ([datetime]::ParseExact($entry.Date, 'yyyy-MM-dd', [Globalization.CultureInfo]::InvariantCulture))
        $targetPath = Join-Path $targetFolder $item.Name
        $outcome = $null
        if ($item.Attributes -band [IO.FileAttributes]::ReparsePoint) { $outcome = 'Skipped (reparse-backed; review manually)' }
        elseif (Test-Path -LiteralPath $targetPath) { $outcome = 'Skipped (an item with that name already exists at the destination)' }
        elseif ($PSCmdlet.ShouldProcess($item.FullName, ('Move to {0}' -f $targetFolder))) {
            try {
                New-Item -ItemType Directory -Path $targetFolder -Force -ErrorAction Stop | Out-Null
                Move-Item -LiteralPath $item.FullName -Destination $targetPath -ErrorAction Stop
                $outcome = 'Moved to {0}' -f $targetPath
            }
            catch { $outcome = 'Skipped (move failed: {0})' -f $_.Exception.Message }
        }
        else { $outcome = 'Skipped (not confirmed)' }
        if ($outcome -like 'Moved*') { $result.Moved++ } else { $result.Skipped++ }
        $line = '{0}: {1}' -f $item.FullName, $outcome
        $result.Lines.Add($line)
        Write-AutopilotExpressLog -Message ('Recovery evidence organise - {0}' -f $line) -Level $(if ($outcome -like 'Moved*') { 'INFO' } else { 'WARN' })
    }
    return $result
}

function New-LocalSessionRecoverySnapshot {
    <#
    .SYNOPSIS
        Retain and verify the complete saved store outside active discovery before recovery.
    .PARAMETER DataPath
        Authoritative directory containing device, bench, audit, index and recovery files.
    .PARAMETER Mode
        Live, Demo or Unknown; selects the tenant folder used by the BACKUP-POLICY layout.
    .OUTPUTS
        Verified backup path, tenant folder key and original inventory; failures retain the
        reservation and partial backup.
    #>
    [CmdletBinding(SupportsShouldProcess)]
    [OutputType([hashtable])]
    param(
        [Parameter(Mandatory)][ValidateNotNullOrEmpty()][string]$DataPath,
        [ValidateSet('Live', 'Demo', 'Unknown')][string]$Mode = 'Unknown'
    )
    $root = [IO.Path]::GetFullPath($DataPath).TrimEnd([IO.Path]::DirectorySeparatorChar)
    $createdAt = Get-Date
    $tenantKey = Get-RecoveryEvidenceTenantKey -Folder $root -Mode $Mode
    $destination = Join-Path (Get-RecoveryEvidenceFolder -Kind SessionSnapshots -TenantKey $tenantKey -Timestamp $createdAt) ('{0}-{1}' -f $createdAt.ToString('yyyyMMdd-HHmmss'), [guid]::NewGuid().ToString('N'))
    $destination = [IO.Path]::GetFullPath($destination)
    if ($destination.StartsWith(($root + [IO.Path]::DirectorySeparatorChar), [StringComparison]::OrdinalIgnoreCase)) { throw 'Session backup destination is inside active discovery. No reservation was released.' }
    if (-not $PSCmdlet.ShouldProcess($root, 'Retain a verified complete session snapshot outside active discovery')) { return }
    $inventory = @(Get-LocalSessionRecoveryInventory -DataPath $root)
    if (-not $inventory.Count) { throw 'Session inventory is unexpectedly empty. No reservation was released.' }
    foreach ($file in $inventory) {
        $copyPath = Join-Path $destination ('files/{0}' -f $file.RelativePath)
        New-Item -ItemType Directory -Path (Split-Path -Parent $copyPath) -Force -ErrorAction Stop | Out-Null
        Copy-Item -LiteralPath $file.SourcePath -Destination $copyPath -ErrorAction Stop
        if ((Get-FileHash -LiteralPath $copyPath -Algorithm SHA256 -ErrorAction Stop).Hash -cne $file.SHA256) { throw 'Session backup evidence changed or hash mismatch. Originals and partial backup retained; no reservation was released.' }
    }
    $after = @(Get-LocalSessionRecoveryInventory -DataPath $root)
    if (@(Compare-Object -ReferenceObject $inventory -DifferenceObject $after -Property RelativePath, Length, SHA256).Count) { throw 'Saved session changed during backup. Partial backup retained; no reservation was released.' }
    $manifest = @{ SchemaVersion = 1; Status = 'Verified'; SourceRoot = $root; CreatedAt = (Get-Date -Format o); Files = @($inventory | Select-Object RelativePath, Length, SHA256) }
    New-Item -ItemType File -Path (Join-Path $destination 'manifest.json') -Value ($manifest | ConvertTo-Json -Depth 6) -ErrorAction Stop | Out-Null
    return @{ Path = $destination; TenantKey = $tenantKey; Inventory = $inventory }
}

function Get-LocalSessionOwnerState {
    <#
    .SYNOPSIS
        Distinguish an absent legacy owner from a running host or a reused process ID.
    .PARAMETER Owner
        Parsed local lock metadata, including process ID and lock creation time.
    .OUTPUTS
        State, recovery eligibility and current process identity for operator review.
    #>
    [OutputType([hashtable])]
    param([Parameter(Mandatory)][ValidateNotNullOrEmpty()]$Owner)
    $result = @{ State = 'OwnerProcessStopped'; CanRecover = $true; ProcessName = ''; ProcessPath = ''; ProcessStartedAt = $null }
    try { $process = Get-Process -Id $Owner.ProcessId -ErrorAction Stop }
    catch {
        if ($_.CategoryInfo.Category -ne 'ObjectNotFound') { throw 'Cannot verify owner process state. No lock was released.' }
        return $result
    }
    if (-not $process) { return $result }
    $result.State = 'ActiveOrReusedProcessId'
    $result.CanRecover = $false
    try { $result.ProcessName = $process.ProcessName; $result.ProcessPath = $process.Path } catch { $result.ProcessPath = 'Unavailable' }
    try {
        $processStart = $process.StartTime
        if ($processStart -isnot [datetime] -and $processStart -isnot [DateTimeOffset]) { return $result }
        $result.ProcessStartedAt = ([DateTimeOffset]$processStart).ToString('o')
        if (-not $Owner.StartedAt) { return $result }
        $lockStart = [DateTimeOffset]$Owner.StartedAt
        if ([DateTimeOffset]$processStart -gt $lockStart) {
            $result.State = 'ProcessIdReused'
            $result.CanRecover = $true
        }
    }
    catch { $result.CanRecover = $false }
    return $result
}

function Invoke-LocalSessionLockRecovery {
    <#
    .SYNOPSIS
        Inspect a crashed local reservation or explicitly retire its verified stopped owner.
    .PARAMETER Path
        Exact local session lock; no storage probing, fallback migration or tenant access.
    .PARAMETER Recover
        Archive the original only after owner-process absence and byte-level verification.
    .PARAMETER ConfirmStopped
        Operator confirmation that every session using this store has stopped.
    .OUTPUTS
        Inspection metadata or the retained evidence path. Other recovery artefacts are untouched.
    #>
    [CmdletBinding(SupportsShouldProcess)]
    [OutputType([hashtable])]
    param(
        [Parameter(Mandatory)][ValidateNotNullOrEmpty()][string]$Path,
        [switch]$Recover,
        [switch]$ConfirmStopped
    )
    if ((Split-Path -Leaf $Path) -notmatch '^autopilot-express-(live|demo)\.session\.lock$') { throw 'Select an exact Autopilot Express Live/Demo session lock, not a checkpoint or write marker.' }
    $item = Get-Item -LiteralPath $Path -ErrorAction Stop
    if ($item.PSIsContainer -or ($Recover -and ($item.Attributes -band [IO.FileAttributes]::ReparsePoint))) { throw 'Recovery requires a regular non-reparse-backed lock file. Cloud/symbolic-link reservations require owner review; read-only Inspect remains available.' }
    $hash = (Get-FileHash -LiteralPath $Path -Algorithm SHA256 -ErrorAction Stop).Hash
    $owner = Get-Content -LiteralPath $Path -Raw -ErrorAction Stop | ConvertFrom-Json -ErrorAction Stop
    if ($owner.Token -isnot [string] -or -not $owner.Token -or $owner.Computer -isnot [string] -or -not $owner.Computer -or
        ($owner.ProcessId -isnot [int] -and $owner.ProcessId -isnot [long]) -or $owner.ProcessId -lt 1 -or $owner.ProcessId -gt [int]::MaxValue) {
        throw 'Lock ownership is malformed. Preserve the file for manual review; recovery did not release it.'
    }
    if (-not $env:COMPUTERNAME -or $owner.Computer -ine $env:COMPUTERNAME) {
        if (-not $Recover) { return @{ Path = $item.FullName; Computer = $owner.Computer; User = $owner.User; ProcessId = $owner.ProcessId; StartedAt = $owner.StartedAt; State = 'ForeignOrUnknownComputer'; CanRecover = $false; SHA256 = $hash } }
        throw 'Lock belongs to another or unknown computer. Run inspection on its owning host; no lock was released.'
    }
    if ($Recover -and -not $ConfirmStopped) { throw 'Recovery requires explicit -ConfirmStopped. No reservation was released.' }
    if ($Recover -and -not $PSCmdlet.ShouldProcess($item.FullName, 'Back up the complete session and release its recoverable reservation')) { return }
    $lease = $null
    try {
        $leasePath = $Path + '.lease'
        if ($Recover -or (Test-Path -LiteralPath $leasePath)) {
            try {
                $fileMode = if ($Recover) { [IO.FileMode]::OpenOrCreate } else { [IO.FileMode]::Open }
                $lease = [IO.File]::Open($leasePath, $fileMode, [IO.FileAccess]::ReadWrite, [IO.FileShare]::None)
            }
            catch {
                if ($Recover) { throw 'The OS reservation is held or inaccessible. No session data or lock was changed.' }
                return @{ Path = $item.FullName; Computer = $owner.Computer; User = $owner.User; ProcessId = $owner.ProcessId; StartedAt = $owner.StartedAt; State = 'ActiveOrInaccessibleReservation'; CanRecover = $false; SHA256 = $hash; ProcessPath = 'Reservation is held or inaccessible'; ProcessStartedAt = $null }
            }
        }
        try { $ownerState = Get-LocalSessionOwnerState -Owner $owner }
        catch {
            if ($owner.ReservationVersion -ne 2 -or -not $lease) { throw }
            $ownerState = @{ State = 'OSReservationReleased'; CanRecover = $true; ProcessName = ''; ProcessPath = 'Process metadata unavailable; OS lease is exclusively acquired'; ProcessStartedAt = $null }
        }
        if ($owner.ReservationVersion -eq 2) {
            if (-not $lease) { throw 'Version-two lease sidecar is missing. Preserve the store for owner review; no reservation was released.' }
            $ownerState.State = 'OSReservationReleased'
            $ownerState.CanRecover = $true
        }
        if (-not $Recover) { return @{ Path = $item.FullName; Computer = $owner.Computer; User = $owner.User; ProcessId = $owner.ProcessId; StartedAt = $owner.StartedAt; State = $ownerState.State; ProcessName = $ownerState.ProcessName; ProcessPath = $ownerState.ProcessPath; ProcessStartedAt = $ownerState.ProcessStartedAt; CanRecover = ($ownerState.CanRecover -and -not ($item.Attributes -band [IO.FileAttributes]::ReparsePoint)); SHA256 = $hash } }
        if (-not $ownerState.CanRecover -or -not $ConfirmStopped) { throw 'Recovery requires a stopped owner process or verified reused PID and explicit -ConfirmStopped after all sessions using this store have stopped. No lock was released.' }
        # The lock name carries the mode; crash evidence is filed beside its paired session snapshot's tenant.
        $lockMode = if ($item.Name -like '*-demo.*') { 'Demo' } else { 'Live' }
        $snapshot = New-LocalSessionRecoverySnapshot -DataPath (Split-Path -Parent $item.FullName) -Mode $lockMode -Confirm:$false
        $evidenceTime = Get-Date
        $evidenceRoot = Get-RecoveryEvidenceFolder -Kind CrashLocks -TenantKey $snapshot.TenantKey -Timestamp $evidenceTime
        New-Item -ItemType Directory -Path $evidenceRoot -Force -ErrorAction Stop | Out-Null
        $evidencePath = Join-Path $evidenceRoot ('{0}-{1}.lock.evidence' -f $evidenceTime.ToString('yyyyMMdd-HHmmss'), [guid]::NewGuid().ToString('N'))
        Copy-Item -LiteralPath $Path -Destination $evidencePath -ErrorAction Stop
        if ((Get-FileHash -LiteralPath $evidencePath -Algorithm SHA256 -ErrorAction Stop).Hash -cne $hash -or
            (Get-FileHash -LiteralPath $Path -Algorithm SHA256 -ErrorAction Stop).Hash -cne $hash) { throw 'Lock evidence changed during recovery. Copies retained; reservation was not released.' }
        if ($owner.ReservationVersion -ne 2) {
            $ownerState = Get-LocalSessionOwnerState -Owner $owner
            if (-not $ownerState.CanRecover) { throw 'Owner process appeared during recovery. Reservation and evidence retained.' }
        }
        $currentInventory = @(Get-LocalSessionRecoveryInventory -DataPath (Split-Path -Parent $item.FullName))
        if (@(Compare-Object -ReferenceObject $snapshot.Inventory -DifferenceObject $currentInventory -Property RelativePath, Length, SHA256).Count) { throw 'Saved session changed at the final recovery check. Reservation and backups retained.' }
        if ((Get-FileHash -LiteralPath $Path -Algorithm SHA256 -ErrorAction Stop).Hash -cne $hash) { throw 'Lock changed at the final recovery check. Reservation and evidence retained.' }
        Remove-Item -LiteralPath $Path -ErrorAction Stop
        return @{ State = 'Recovered'; EvidencePath = $evidencePath; SessionBackupPath = $snapshot.Path; SHA256 = $hash; NextAction = 'Resume the existing session. Any remaining checkpoint/write markers require separate review; never replay an unknown tenant outcome.' }
    }
    finally { if ($lease) { $lease.Dispose() } }
}

function Stop-LocalSessionLock {
    <#
    .SYNOPSIS
        Release only the local lock acquired by this invocation.
    .PARAMETER Lock
        Path and ownership token returned by Start-LocalSessionLock.
    .DESCRIPTION
        Missing, unreadable or changed locks are not removed. Errors propagate so
        the operator can review the reserved store instead of assuming cleanup worked.
    .OUTPUTS
        None. Removes only an unchanged lock owned by this session; foreign evidence is retained.
    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '', Justification = 'Mandatory finally cleanup is ownership-checked and cannot support WhatIf; PSCmdlet.ShouldProcess is blocked in ConstrainedLanguage.')]
    [CmdletBinding()]
    param([Parameter(Mandatory)][ValidateNotNullOrEmpty()][hashtable]$Lock)
    try {
        $owner = Get-Content -LiteralPath $Lock.Path -Raw -ErrorAction Stop | ConvertFrom-Json -ErrorAction Stop
        if ($owner.Token -ne $Lock.Token) { throw 'Local session lock ownership changed. The lock was not removed; review this storage root before restarting.' }
        Remove-Item -LiteralPath $Lock.Path -ErrorAction Stop
    }
    finally { if ($Lock.Handle) { $Lock.Handle.Dispose() } }
}

function New-ParentDirectory {
    <#
    .SYNOPSIS
        Ensure the parent directory exists before a guarded file write.
    .PARAMETER Path
        Destination file path, not the directory itself.
    .OUTPUTS
        None. Creates a missing parent and propagates access failures.
    #>
    param([Parameter(Mandatory)][string]$Path)
    $parentPath = Split-Path -Parent $Path
    if (-not [string]::IsNullOrWhiteSpace($parentPath) -and -not (Test-Path $parentPath)) {
        New-Item -ItemType Directory -Path $parentPath -Force -ErrorAction Stop | Out-Null
    }
}

function Get-StorageFileEncoding {
    <#
    .SYNOPSIS
        Select the UTF-8 encoding name supported by the executing PowerShell host.
    .OUTPUTS
        utf8NoBOM on PowerShell 7, or UTF8 on Windows PowerShell 5.1.
    #>
    if ($PSVersionTable.PSVersion.Major -ge 6) { return 'utf8NoBOM' }
    return 'UTF8'
}

function Write-Utf8File {
    <#
    .SYNOPSIS
        Save verified staged content with recoverable previous-file evidence.
    .DESCRIPTION
        A marker reserves the save before touching the target. Staged and previous
        content are read back before promotion; the marker remains on any failure.
        Cmdlet replacement is not guaranteed atomic. Recovery artefacts block another
        write until reviewed; no failed tenant action is automatically replayed.
    .PARAMETER Path
        Target file; recovery artefacts are stored beside it on the same volume.
    .PARAMETER Content
        Complete text to save with the host-appropriate UTF-8 encoding.
    .PARAMETER PreviousPath
        Optional backup location for the replaced content. Defaults to the Path value with '.previous' appended.
        Archive updates pass a dated name so the archive's own .previous evidence survives.
    .OUTPUTS
        None. Guarded file promotion retains recovery evidence on failure; not a power-loss guarantee.
    #>
    param(
        [Parameter(Mandatory)][ValidateNotNullOrEmpty()][string]$Path,
        [Parameter(Mandatory)][AllowEmptyString()][string]$Content,
        [string]$PreviousPath
    )
    # File cmdlets must never touch the console mid-save; a lost console would otherwise strand the marker.
    $ProgressPreference = 'SilentlyContinue'
    New-ParentDirectory -Path $Path
    $pendingPath = '{0}.pending' -f $Path
    $previousPath = if ($PreviousPath) { $PreviousPath } else { '{0}.previous' -f $Path }
    $markerPath = '{0}.write-in-progress' -f $Path
    Assert-FileWriteRecoveryState -Path $Path
    $hadOriginal = Test-Path -LiteralPath $Path
    $marker = @{ Target = $Path; HadOriginal = $hadOriginal; User = $env:USERNAME; Computer = $env:COMPUTERNAME; StartedAt = (Get-Date -Format o) }
    New-Item -ItemType File -Path $markerPath -Value ($marker | ConvertTo-Json -Compress) -ErrorAction Stop | Out-Null
    Set-Content -LiteralPath $pendingPath -Value $Content -Encoding (Get-StorageFileEncoding) -NoNewline -ErrorAction Stop
    [string]$stagedContent = Get-Content -LiteralPath $pendingPath -Raw -ErrorAction Stop
    if ([string]::IsNullOrEmpty($stagedContent)) { $stagedContent = '' }
    if ($stagedContent -cne $Content) { throw ('Staged save verification failed for {0}. Recovery artefacts were retained.' -f $Path) }
    if ($hadOriginal) {
        [string]$originalContent = Get-Content -LiteralPath $Path -Raw -ErrorAction Stop
        if ([string]::IsNullOrEmpty($originalContent)) { $originalContent = '' }
        Copy-Item -LiteralPath $Path -Destination $previousPath -Force -ErrorAction Stop
        [string]$previousContent = Get-Content -LiteralPath $previousPath -Raw -ErrorAction Stop
        if ([string]::IsNullOrEmpty($previousContent)) { $previousContent = '' }
        if ($previousContent -cne $originalContent) { throw ('Previous-file verification failed for {0}. The target was not promoted.' -f $Path) }
    }
    Move-Item -LiteralPath $pendingPath -Destination $Path -Force -ErrorAction Stop
    [string]$savedContent = Get-Content -LiteralPath $Path -Raw -ErrorAction Stop
    if ([string]::IsNullOrEmpty($savedContent)) { $savedContent = '' }
    if ($savedContent -cne $Content) { throw ('Promoted save verification failed for {0}. Recovery artefacts were retained.' -f $Path) }
    Remove-Item -LiteralPath $markerPath -ErrorAction Stop
}

function Assert-FileWriteRecoveryState {
    <#
    .SYNOPSIS
        Stop before consuming or migrating a file with unresolved save evidence.
    .PARAMETER Path
        Target path to check even when the target itself is absent.
    .OUTPUTS
        None. Throws on unfinished writes without deleting markers or proposed evidence.
    #>
    param([Parameter(Mandatory)][ValidateNotNullOrEmpty()][string]$Path)
    foreach ($suffix in @('.write-in-progress', '.pending')) {
        if (Test-Path -LiteralPath ('{0}{1}' -f $Path, $suffix)) {
            throw ('Interrupted save recovery is required for {0}. Preserve the target, .pending, .previous and .write-in-progress files and review tenant state before resuming.' -f $Path)
        }
    }
    if (-not (Test-Path -LiteralPath $Path) -and (Test-Path -LiteralPath ('{0}.previous' -f $Path))) {
        throw ('Interrupted save recovery is required for {0}: a previous-file backup exists but the target is missing. Preserve the backup instead of starting an empty session.' -f $Path)
    }
}

function Assert-LocalStorageWriteState {
    <#
    .SYNOPSIS
        Validate current-mode operational save boundaries before resume or archive.
    .DESCRIPTION
        Checks device, bench and recent-user files plus the common Live audit file.
        Completed .previous backups alone are valid; incomplete saves fail closed.
    .OUTPUTS
        None. Blocks unsafe local writes; does not repair interrupted state automatically.
    #>
    if (Test-Path -LiteralPath (Join-Path (Get-DataFolderPath) 'workflow-id-migration.write-in-progress')) {
        throw 'Workflow evidence migration is incomplete; preserve the migration marker and verified originals before manual recovery.'
    }
    Assert-LocalCheckpointState
    $archiveMarker = '{0}.archive-in-progress' -f (Get-UserDataFilePath)
    if (Test-Path -LiteralPath $archiveMarker) {
        throw ('Interrupted session archive detected; manual recovery is required before reuse. Preserve and review the active files, archives and marker: {0}' -f $archiveMarker)
    }
    $paths = @((Get-UserDataFilePath), (Get-BuildBenchStatePath), (Get-RecentUsersFilePath))
    if (-not $Script:Runtime.IsDemoMode) { $paths += Get-MasterAuditFilePath }
    foreach ($path in $paths) { Assert-FileWriteRecoveryState -Path $path }
}

function Copy-StateFileIfNeeded {
    <#
    .SYNOPSIS
        Migrate missing state without overwriting existing or interrupted copies.
    .DESCRIPTION
        Before authority is established, existing copies must have exactly the
        same decoded UTF-8 content. Timestamps are not evidence of ancestry.
    .PARAMETER SourcePath
        Repository state file, checked for recovery evidence even if absent.
    .PARAMETER DestinationPath
        Fallback state file; existing operational content is never overwritten.
    .PARAMETER CheckOnly
        Preflight all copies before beginning any multi-file migration.
    .OUTPUTS
        None. Copies only validated migration candidates; conflicts stop promotion.
    #>
    param(
        [Parameter(Mandatory)][ValidateNotNullOrEmpty()][string]$SourcePath,
        [Parameter(Mandatory)][ValidateNotNullOrEmpty()][string]$DestinationPath,
        [switch]$CheckOnly
    )

    foreach ($path in @($SourcePath, $DestinationPath)) {
        $archiveMarker = '{0}.archive-in-progress' -f $path
        if (Test-Path -LiteralPath $archiveMarker) {
            throw ('Interrupted session archive detected; manual recovery is required before migration. Preserve the active files, archives and marker: {0}' -f $archiveMarker)
        }
    }
    Assert-FileWriteRecoveryState -Path $DestinationPath
    Assert-FileWriteRecoveryState -Path $SourcePath
    if (-not (Test-Path -LiteralPath $SourcePath)) { return }
    if (Test-Path -LiteralPath $DestinationPath) {
        $sourceContent = [string](Get-Content -LiteralPath $SourcePath -Raw -Encoding UTF8 -ErrorAction Stop)
        $destinationContent = [string](Get-Content -LiteralPath $DestinationPath -Raw -Encoding UTF8 -ErrorAction Stop)
        if ($sourceContent -cne $destinationContent) {
            throw ('Conflicting storage copies require operator review: {0} and {1}. Neither copy was changed.' -f $SourcePath, $DestinationPath)
        }
        return
    }
    if ($CheckOnly) { return }

    try {
        $content = [string](Get-Content -Raw -LiteralPath $SourcePath -Encoding UTF8 -ErrorAction Stop)
        Write-Utf8File -Path $DestinationPath -Content $content
        Write-AutopilotExpressLog -Message ('Migrated Autopilot Express state from {0} to {1}.' -f $SourcePath, $DestinationPath) -Level 'WARN'
    }
    catch {
        Write-AutopilotExpressLog -Message ('Failed to migrate Autopilot Express state file {0}: {1}' -f $SourcePath, $_.Exception.Message) -Level 'WARN'
        throw
    }
}

function Get-ModeUserDataFilePrefix {
    <#
    .SYNOPSIS
        Select the configured Demo or Live device-record prefix.
    .OUTPUTS
        Prefix string from current runtime mode; no filesystem access.
    #>
    if ($Script:Runtime.IsDemoMode) { return $Script:Config.DemoUserDataFilePrefix }
    return $Script:Config.UserDataFilePrefix
}

function Get-ModeRecentUsersFilePrefix {
    <#
    .SYNOPSIS
        Select the configured Demo or Live recent-user prefix.
    .OUTPUTS
        Mode-specific prefix; does not mix simulated and Live account history.
    #>
    if ($Script:Runtime.IsDemoMode) { return $Script:Config.DemoRecentUsersFilePrefix }
    return $Script:Config.RecentUsersFilePrefix
}

function Get-ModeBuildBenchFilePrefix {
    <#
    .SYNOPSIS
        Select the configured Demo or Live bench-state prefix.
    .OUTPUTS
        Mode-specific bench prefix; no filesystem access.
    #>
    if ($Script:Runtime.IsDemoMode) { return $Script:Config.DemoBuildBenchFilePrefix }
    return $Script:Config.BuildBenchFilePrefix
}

function Get-SessionFileIndexPath {
    <#
    .SYNOPSIS
        Locate stable user/mode resume authority without selecting a storage root.
    .PARAMETER DataPath
        Explicit authoritative data directory.
    .OUTPUTS
        Index path for the current Windows user and runtime mode; no file access.
    #>
    param([Parameter(Mandatory)][string]$DataPath)
    $modeName = if ($Script:Runtime.IsDemoMode) { 'demo' } else { 'live' }
    return Join-Path $DataPath ('autopilot-session-{0}-{1}.index.json' -f $modeName, $env:USERNAME)
}

function Get-SessionFileIndex {
    <#
    .SYNOPSIS
        Read authoritative session paths; never choose the newest matching file.
    .PARAMETER DataPath
        Explicit selected or preflight data root. Only safe, linked basenames qualify.
    .OUTPUTS
        Validated index, null for legacy/no session, or a recovery error.
    #>
    param([Parameter(Mandatory)][string]$DataPath)
    $path = Get-SessionFileIndexPath -DataPath $DataPath
    Assert-FileWriteRecoveryState -Path $path
    $modeName = if ($Script:Runtime.IsDemoMode) { 'demo' } else { 'live' }
    $devicePrefix = '{0}-{1}' -f (Get-ModeUserDataFilePrefix), $env:USERNAME
    if (-not (Test-Path -LiteralPath $path)) {
        if (Test-Path -LiteralPath $DataPath) {
            $orphanPattern = '^\d{{8}}-\d{{4}}-{0}-' -f [regex]::Escape($devicePrefix)
            $benchPattern = '^\d{{8}}-\d{{4}}-{0}-{1}-' -f [regex]::Escape((Get-ModeBuildBenchFilePrefix)), [regex]::Escape($env:USERNAME)
            if (@(Get-ChildItem -LiteralPath $DataPath -File | Where-Object { $_.Name -match $orphanPattern -or $_.Name -match $benchPattern }).Count) {
                throw 'Stamped session files exist without their authoritative resume index. Preserve evidence; no newest-file guess was made.'
            }
        }
        return $null
    }
    $index = ConvertTo-NormalisedValue -Value (Get-Content -LiteralPath $path -Raw -ErrorAction Stop | ConvertFrom-Json -ErrorAction Stop)
    if ($index -isnot [System.Collections.IDictionary] -or
        ($index.SchemaVersion -isnot [int] -and $index.SchemaVersion -isnot [long]) -or $index.SchemaVersion -ne 1 -or
        $index.User -cne $env:USERNAME -or $index.Mode -cne $modeName -or
        $index.StartedAt -isnot [string] -or [string]::IsNullOrWhiteSpace($index.StartedAt) -or
        $index.SessionId -isnot [string] -or $index.SessionId -cnotmatch '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$' -or
        $index.SessionPrefix -isnot [string] -or $index.SessionPrefix -cnotmatch '^\d{8}-\d{4}$') { throw 'Invalid or cross-user/mode session index; preserve it before recovery.' }
    $start = Get-Date -Date $index.StartedAt -ErrorAction Stop
    if ((Get-Date -Date $start -Format yyyyMMdd-HHmm) -cne $index.SessionPrefix) { throw 'Session index prefix disagrees with its original start time.' }
    $expectedDevice = '{0}-{1}-{2}.json' -f $index.SessionPrefix, $devicePrefix, $index.SessionId
    $expectedBench = '{0}-{1}-{2}-{3}.json' -f $index.SessionPrefix, (Get-ModeBuildBenchFilePrefix), $env:USERNAME, $index.SessionId
    if ($index.DeviceFile -cne $expectedDevice -or $index.BenchFile -cne $expectedBench) { throw 'Session index contains unsafe or mismatched linked filenames.' }
    return $index
}

function Initialize-SessionFileIndex {
    <#
    .SYNOPSIS
        Persist new-session identity once, retaining fixed legacy names until archive.
    .DESCRIPTION
        Called only inside guarded saves. An original start prefix and GUID link
        device/bench files; resume never renames them. Index writer failures retain
        the usual recoverable previous/pending markers.
    .OUTPUTS
        None. Persists new session authority through guarded storage before enabling indexed paths.
    #>
    if (-not $Script:SessionFileNamesEnabled) { return }
    $dataPath = Get-DataFolderPath
    if (Get-SessionFileIndex -DataPath $dataPath) { return }
    foreach ($prefix in @((Get-ModeUserDataFilePrefix), (Get-ModeBuildBenchFilePrefix))) {
        if (Test-Path -LiteralPath (Join-Path $dataPath ('{0}-{1}.json' -f $prefix, $env:USERNAME))) { return }
    }
    $startedAt = if ($Script:SessionStartedAt) { $Script:SessionStartedAt } else { Get-Date }
    $prefix = Get-Date -Date $startedAt -Format yyyyMMdd-HHmm
    $sessionId = [guid]::NewGuid().Guid
    $index = @{ SchemaVersion = 1; User = $env:USERNAME; Mode = if ($Script:Runtime.IsDemoMode) { 'demo' } else { 'live' }; StartedAt = Get-Date -Date $startedAt -Format o; SessionPrefix = $prefix; SessionId = $sessionId
        DeviceFile = '{0}-{1}-{2}-{3}.json' -f $prefix, (Get-ModeUserDataFilePrefix), $env:USERNAME, $sessionId
        BenchFile = '{0}-{1}-{2}-{3}.json' -f $prefix, (Get-ModeBuildBenchFilePrefix), $env:USERNAME, $sessionId
    }
    Write-Utf8File -Path (Get-SessionFileIndexPath -DataPath $dataPath) -Content ($index | ConvertTo-Json -Depth 3)
    $null = Get-SessionFileIndex -DataPath $dataPath
}

function Get-UserDataFilePath {
    <#
    .SYNOPSIS
        Resolve authoritative indexed or legacy device-record storage.
    .PARAMETER BasePath
        Optional selected storage base used during guarded preflight.
    .OUTPUTS
        Validated indexed path or fixed legacy path; refuses orphaned stamped evidence.
    #>
    param([string]$BasePath)

    $user = $env:USERNAME
    if ($Script:SessionFileNamesEnabled) {
        $dataPath = Get-DataFolderPath -BasePath $BasePath
        $index = Get-SessionFileIndex -DataPath $dataPath
        if ($index) { return Join-Path $dataPath $index.DeviceFile }
    }
    return Join-Path (Get-DataFolderPath -BasePath $BasePath) ("{0}-{1}.json" -f (Get-ModeUserDataFilePrefix), $user)
}

function Get-BuildBenchStatePath {
    <#
    .SYNOPSIS
        Resolve the bench file linked to the current indexed or legacy session.
    .PARAMETER BasePath
        Optional selected storage base used during guarded preflight.
    .OUTPUTS
        Linked bench path. Invalid index authority throws rather than guessing a file.
    #>
    param([string]$BasePath)

    if ($Script:SessionFileNamesEnabled) {
        $dataPath = Get-DataFolderPath -BasePath $BasePath
        $index = Get-SessionFileIndex -DataPath $dataPath
        if ($index) { return Join-Path $dataPath $index.BenchFile }
    }
    return Join-Path (Get-DataFolderPath -BasePath $BasePath) ("{0}-{1}.json" -f (Get-ModeBuildBenchFilePrefix), $env:USERNAME)
}

function Get-RecentUsersFilePath {
    <#
    .SYNOPSIS
        Locate current-user recent-account storage in the selected mode.
    .PARAMETER BasePath
        Optional selected storage base; defaults to current authority.
    .OUTPUTS
        Fixed recent-user JSON path; this helper does not load account data.
    #>
    param([string]$BasePath)

    return Join-Path (Get-DataFolderPath -BasePath $BasePath) ("{0}-{1}.json" -f (Get-ModeRecentUsersFilePrefix), $env:USERNAME)
}

function Get-AutopilotExpressDefinitionPath {
    <#
    .SYNOPSIS
        Resolve a definition relative to the bootstrap-authorised definition directory.
    .PARAMETER FileName
        Internal runtime or manifest definition filename.
    .OUTPUTS
        Definition path; rejects missing bootstrap directory state.
    #>
    param([Parameter(Mandatory)][string]$FileName)
    if ([string]::IsNullOrWhiteSpace($Script:AutopilotExpressScriptDirectory)) {
        throw 'The Autopilot Express script directory has not been resolved.'
    }
    return Join-Path $Script:AutopilotExpressScriptDirectory $FileName
}

function Get-RuntimeConfigFilePath {
    <#
    .SYNOPSIS
        Locate the runtime configuration in the authorised definition directory.
    .OUTPUTS
        Runtime JSON path using the configured internal filename.
    #>
    return Get-AutopilotExpressDefinitionPath -FileName $Script:Config.RuntimeConfigFileName
}

function Get-ManifestFilePath {
    <#
    .SYNOPSIS
        Locate the workflow manifest in the authorised definition directory.
    .OUTPUTS
        Manifest JSON path; no definition is loaded by this helper.
    #>
    return Get-AutopilotExpressDefinitionPath -FileName $Script:Config.ManifestFileName
}

function Get-MasterAuditFilePath {
    <#
    .SYNOPSIS
        Locate the root-wide audit ledger without creating or rewriting it.
    .PARAMETER BasePath
        Optional selected storage base for guarded migration preflight.
    .OUTPUTS
        Master-audit JSON path under the selected data directory.
    #>
    param([string]$BasePath)

    return Join-Path (Get-DataFolderPath -BasePath $BasePath) $Script:Config.MasterAuditFileName
}

function Sync-RepoStateFilesToActiveStorage {
    <#
    .SYNOPSIS
        Establish fallback authority only after a reserved, verified migration.
    .DESCRIPTION
        Preflights every relevant file before copying any state. Existing copies
        must agree exactly until authority exists. After authority, repository
        normal ancestors are ignored so legitimate fallback updates remain
        authoritative. Checkpoint proposals in either root always block migration;
        their embedded root metadata must never be copied to another root.
        Operational files are neither deleted nor overwritten by migration.
    .OUTPUTS
        None. Performs guarded fallback migration without selecting a newer file by timestamp.
    #>
    if (-not $Script:Storage.UsingFallback) { return }

    $repoBasePath = Get-RepoStorageBasePath
    $activeBasePath = Get-StorageBasePath
    Assert-LocalCheckpointState -BasePath $repoBasePath
    Assert-LocalCheckpointState -BasePath $activeBasePath
    $activePaths = @(Get-OperationalStoragePath -BasePath $activeBasePath)
    foreach ($path in $activePaths) { Assert-FileWriteRecoveryState -Path $path }
    if (Test-FallbackStorageAuthority -BasePath $activeBasePath) { return }

    Assert-ActiveStorageReservation
    $sourcePaths = @(Get-OperationalStoragePath -BasePath $repoBasePath)
    $fileNames = @(@($sourcePaths) + @($activePaths) | ForEach-Object { Split-Path -Leaf $_ } | Sort-Object -Unique)
    $sourceDataPath = Join-Path $repoBasePath $Script:Config.DataFolderRelative
    $activeDataPath = Join-Path $activeBasePath $Script:Config.DataFolderRelative
    foreach ($fileName in $fileNames) {
        Copy-StateFileIfNeeded -SourcePath (Join-Path $sourceDataPath $fileName) -DestinationPath (Join-Path $activeDataPath $fileName) -CheckOnly
    }
    foreach ($fileName in $fileNames) {
        Assert-ActiveStorageReservation
        Copy-StateFileIfNeeded -SourcePath (Join-Path $sourceDataPath $fileName) -DestinationPath (Join-Path $activeDataPath $fileName)
    }
    Assert-ActiveStorageReservation
    $modeName = if ($Script:Runtime.IsDemoMode) { 'demo' } else { 'live' }
    $marker = 'AutopilotExpressFallbackAuthority/1|{0}|{1}|{2}' -f $modeName, $env:USERNAME, $Script:Storage.DataPath
    Write-Utf8File -Path (Get-FallbackStorageAuthorityPath -BasePath $activeBasePath) -Content $marker
    if (-not (Test-FallbackStorageAuthority -BasePath $activeBasePath)) { throw 'Fallback storage authority was not saved.' }
}

function Get-SessionLastUpdated {
    <#
    .SYNOPSIS
        Inspect the latest modification time of the current session's tracked files.
    .OUTPUTS
        File modification DateTime, or null. This is display metadata, not resume authority.
    #>
    $sessionPaths = @((Get-UserDataFilePath), (Get-BuildBenchStatePath)) | Where-Object { Test-Path $_ }
    if (-not $sessionPaths -or $sessionPaths.Count -eq 0) { return $null }
    $latestItem = $sessionPaths | ForEach-Object { Get-Item -Path $_ } | Sort-Object LastWriteTime -Descending | Select-Object -First 1
    return $latestItem.LastWriteTime
}

function Move-SessionFileToArchive {
    <#
    .SYNOPSIS
        Move selected session evidence to a collision-safe archive destination.
    .PARAMETER Path
        Explicit current-session file selected by the archive coordinator.
    .PARAMETER SessionPrefix
        Stable original-session prefix used in archive naming.
    .OUTPUTS
        None. Moves existing evidence and propagates failures; does not provide atomic rollback.
    #>
    param([Parameter(Mandatory)][string]$Path, [string]$SessionPrefix)
    if (-not (Test-Path $Path)) { return }
    $archiveFolder = Get-ArchiveFolderPath
    $timestamp = '{0}-{1}' -f (Get-Date -Format 'yyyyMMdd-HHmmss'), [guid]::NewGuid().Guid
    $modeSlug = if ($Script:Runtime.IsDemoMode) { 'demo' } else { 'live' }
    $leafName = Split-Path -Leaf $Path
    $extension = if ($leafName -match '(\.[^.]+)$') { $Matches[1] } else { '' }
    $baseName = if ($extension) { $leafName.Substring(0, $leafName.Length - $extension.Length) } else { $leafName }
    $archiveName = ('{0}-{1}-{2}{3}' -f $baseName, $modeSlug, $timestamp, $extension)
    if ($SessionPrefix -and -not $archiveName.StartsWith($SessionPrefix)) { $archiveName = '{0}-{1}' -f $SessionPrefix, $archiveName }
    Assert-FileWriteRecoveryState -Path $Path
    Move-Item -LiteralPath $Path -Destination (Join-Path $archiveFolder $archiveName) -Force -ErrorAction Stop
    $previousPath = '{0}.previous' -f $Path
    if (Test-Path -LiteralPath $previousPath) {
        Move-Item -LiteralPath $previousPath -Destination (Join-Path $archiveFolder ('{0}.previous' -f $archiveName)) -Force -ErrorAction Stop
    }
}

function Reset-CurrentSessionState {
    <#
    .SYNOPSIS
        Archive the current user/mode session before initialising empty in-memory state.
    .OUTPUTS
        Empty record array on success. Interrupted archive evidence blocks later reuse.
    #>
    Assert-LocalStorageWriteState
    $sessionIndex = if ($Script:SessionFileNamesEnabled) { Get-SessionFileIndex -DataPath (Get-DataFolderPath) } else { $null }
    $archiveMarker = '{0}.archive-in-progress' -f (Get-UserDataFilePath)
    $archivePlan = @{ Devices = Get-UserDataFilePath; Bench = Get-BuildBenchStatePath; Actor = $env:USERNAME; Mode = $Script:Runtime.Mode; StartedAt = (Get-Date).ToString('o') } | ConvertTo-Json
    New-Item -ItemType File -Path $archiveMarker -Value $archivePlan -ErrorAction Stop | Out-Null
    Move-SessionFileToArchive -Path (Get-UserDataFilePath)
    Move-SessionFileToArchive -Path (Get-BuildBenchStatePath)
    if ($sessionIndex) { Move-SessionFileToArchive -Path (Get-SessionFileIndexPath -DataPath (Get-DataFolderPath)) -SessionPrefix $sessionIndex.SessionPrefix }
    Remove-Item -LiteralPath $archiveMarker -ErrorAction Stop
    $Script:BuildBench = Get-DefaultBuildBenchState
    $Script:SessionStartedAt = Get-Date
    return , @()
}

function ConvertTo-RecordDate {
    <#
    .SYNOPSIS
        Parse persisted time values with the record loader's legacy-compatible fallback.
    .PARAMETER Value
        DateTime or textual time; empty or invalid input is represented as MinValue.
    .OUTPUTS
        DateTime for record calculations. This conversion does not prove an event occurred.
    #>
    param($Value)

    if ($null -eq $Value) { return [DateTime]::MinValue }
    $dateValue = $Value
    if ($Value -is [hashtable] -and $null -ne $Value['value']) {
        $dateValue = $Value['value']
    }
    elseif ($Value -is [System.Collections.IDictionary] -and $null -ne $Value['value']) {
        $dateValue = $Value['value']
    }
    elseif ($null -ne $Value.value) {
        $dateValue = $Value.value
    }

    if ($dateValue -is [DateTime]) { return $dateValue }
    $parsed = [DateTime]::MinValue
    if ([DateTime]::TryParse([string]$dateValue, [Globalization.CultureInfo]::CurrentCulture, [Globalization.DateTimeStyles]::RoundtripKind, [ref]$parsed)) { return $parsed }
    return [DateTime]::MinValue
}

function ConvertTo-PersistedDate {
    <#
    .SYNOPSIS
        Serialise a valid record timestamp in round-trip format.
    .PARAMETER Value
        Record timestamp accepted by ConvertTo-RecordDate.
    .OUTPUTS
        ISO round-trip string, or null for an absent/invalid timestamp.
    #>
    param($Value)

    $dateValue = ConvertTo-RecordDate -Value $Value
    if ($dateValue -eq [DateTime]::MinValue) { return $null }
    return Get-Date -Date $dateValue -Format 'o'
}

function Get-LegacyWorkflowIdMap {
    <#
    .SYNOPSIS
        Map version-one saved IDs to canonical checklist IDs simultaneously.
    .OUTPUTS
        A bijective dictionary; never apply successive textual replacements.
    #>
    return @{ A = 'A'; B = 'B'; C = 'C'; D = 'F'; E = 'D'; F = 'P'; G = 'I'; H = 'M'; I = 'J'; J = 'O'; K = 'E'; L = 'G'; M = 'H'; N = 'K'; O = 'L'; P = 'N'; Q = 'Q' }
}

function ConvertTo-CanonicalWorkflowRecord {
    <#
    .SYNOPSIS
        Stage an idempotent versioned conversion without changing caller evidence.
    .PARAMETER Record
        Device or audit dictionary. Missing WorkflowIdVersion means legacy one.
    .DESCRIPTION
        Only owned ID fields change. Notes, dates, sequence, result payloads and
        identity are retained. Unknown versions, IDs and action conflicts fail closed.
    .OUTPUTS
        Detached dictionary with canonical WorkflowIdVersion two.
    #>
    param([Parameter(Mandatory)][System.Collections.IDictionary]$Record)
    $copy = ConvertTo-NormalisedValue -Value $Record
    $version = if ($copy.Contains('WorkflowIdVersion')) { $copy.WorkflowIdVersion } else { 1 }
    if (($version -isnot [int] -and $version -isnot [long]) -or $version -notin @(1, 2)) { throw 'Unsupported WorkflowIdVersion; preserve the original evidence.' }
    $map = Get-LegacyWorkflowIdMap
    $actions = @('ResolveAutopilotDevice', 'RemoveAssociatedManagedDevice', 'ApplyGroupTag', 'AddToPreProvisioningGroup', 'ConfirmImagingAndOobe', 'ValidateDeploymentProfile', 'ConfirmReseal', 'ConfirmBootToSignIn', 'AssignTechnicianPrimaryUser', 'RemoveFromPreProvisioningGroup', 'ConfirmFirstSignIn', 'ConfirmApplicationBaseline', 'RetryFailedApplications', 'ConfirmUpdatesAndShutdown', 'AssignFinalPrimaryUser', 'ClearUserlessEnrollmentStatus', 'ConfirmRecoveryReadiness')
    function Convert-WorkflowReference {
        <#
        .SYNOPSIS
            Resolve one typed workflow ID under the enclosing record's explicit version.
        .PARAMETER StepId
            Stored reference from current evidence or a retained snapshot.
        .OUTPUTS
            Canonical ID; unknown/ambiguous references throw rather than being dropped.
        #>
        param($StepId)
        if ($StepId -isnot [string] -or @($map.Keys) -cnotcontains $StepId) { throw 'Unknown workflow step ID; conversion refused.' }
        if ($version -eq 1) { return $map[$StepId] }
        return $StepId
    }
    function Convert-WorkflowStepMap {
        <#
        .SYNOPSIS
            Re-key a complete workflow snapshot without changing result evidence.
        .PARAMETER Steps
            Original step dictionary governed by the enclosing record version.
        .OUTPUTS
            Detached canonical step map; conflicting identities are refused.
        #>
        param($Steps)
        if ($Steps -isnot [System.Collections.IDictionary]) { throw 'Workflow Steps must be a dictionary.' }
        $converted = @{}
        foreach ($stepId in $Steps.Keys) {
            $canonicalId = Convert-WorkflowReference -StepId $stepId
            $evidence = $Steps[$stepId]
            $actionName = if ($evidence -is [System.Collections.IDictionary]) { [string]$evidence.ActionName } else { '' }
            if ($actionName -and $actionName -cne $actions[[int][char]$canonicalId - [int][char]'A']) { throw 'Workflow action and step ID disagree; conversion refused.' }
            if ($evidence -is [System.Collections.IDictionary] -and $evidence.Contains('InvalidatedBy')) {
                $evidence.InvalidatedBy = Convert-WorkflowReference -StepId $evidence.InvalidatedBy
            }
            $converted[$canonicalId] = $evidence
        }
        return $converted
    }
    if ($copy.Contains('Steps')) { $copy.Steps = Convert-WorkflowStepMap -Steps $copy.Steps }
    foreach ($attempt in $copy.AttemptHistory) {
        if ($attempt -isnot [System.Collections.IDictionary]) { throw 'Attempt history entry must be a dictionary.' }
        $attempt.StepId = Convert-WorkflowReference -StepId $attempt.StepId
        if ($attempt.Result -is [System.Collections.IDictionary] -and $attempt.Result.Contains('InvalidatedBy')) {
            $attempt.Result.InvalidatedBy = Convert-WorkflowReference -StepId $attempt.Result.InvalidatedBy
        }
        if ($attempt.ActionName -and $attempt.ActionName -cne $actions[[int][char]$attempt.StepId - [int][char]'A']) { throw 'Attempt action and step ID disagree; conversion refused.' }
    }
    foreach ($snapshot in $copy.RecoveryHistory) {
        if ($snapshot -isnot [System.Collections.IDictionary]) { throw 'Recovery history entry must be a dictionary.' }
        if ($snapshot.Contains('Steps')) { $snapshot.Steps = Convert-WorkflowStepMap -Steps $snapshot.Steps }
        if ($snapshot.Contains('UnresolvedStepIds')) {
            if ($snapshot.UnresolvedStepIds -isnot [array]) { throw 'UnresolvedStepIds must be an array.' }
            $snapshot.UnresolvedStepIds = @(foreach ($stepId in $snapshot.UnresolvedStepIds) { Convert-WorkflowReference -StepId $stepId })
        }
    }
    $copy.WorkflowIdVersion = 2
    return $copy
}

function Invoke-WorkflowEvidenceMigration {
    <#
    .SYNOPSIS
        Rehearse or explicitly convert workspace current/previous workflow evidence.
    .PARAMETER Apply
        Promote only after all proposals and external backups are verified.
    .PARAMETER SessionLock
        Optional version-two reservation already held by startup for the authoritative
        root/mode. Its live handle and ownership token must match this invocation.
    .PARAMETER PassThru
        Return structured file/change counts instead of the operator summary text.
    .DESCRIPTION
        PowerShell 7.5+ preserves JSON date strings exactly. Archives and fallback
        roots are excluded. Failure after reservation retains the marker and backup
        inventory; no rollback, action replay or multi-file atomicity is claimed.
    .OUTPUTS
        A concise file count and verified-originals location when applied.
    #>
    [CmdletBinding(SupportsShouldProcess)]
    [OutputType([string], [hashtable])]
    param([switch]$Apply, [hashtable]$SessionLock, [switch]$PassThru)
    if (-not (Get-Command ConvertFrom-Json).Parameters.ContainsKey('DateKind')) { throw 'Offline evidence conversion requires PowerShell 7.5 or later to preserve date strings.' }
    $dataPath = if ($SessionLock) { Split-Path -Parent $SessionLock.Path } else { Join-Path $Script:AutopilotExpressScriptDirectory 'data' }
    function Assert-WorkflowMigrationOwnership {
        <#
        .SYNOPSIS
            Revalidate the enclosing startup reservation before reading or promoting evidence.
        .OUTPUTS
            None. Refuses a released handle or changed ownership without deleting recovery evidence.
        #>
        if (-not $SessionLock) { return }
        $handle = $SessionLock.Handle
        if ($handle -isnot [IO.FileStream] -or -not $handle.CanWrite -or $handle.SafeFileHandle.IsClosed -or
            $handle.Name -ine [IO.Path]::GetFullPath(($SessionLock.Path + '.lease'))) { throw 'Workflow conversion requires the owned open OS reservation handle.' }
        $owner = Get-Content -LiteralPath $SessionLock.Path -Raw -ErrorAction Stop | ConvertFrom-Json -ErrorAction Stop
        if ($owner.Token -cne $SessionLock.Token -or $owner.ProcessId -ne $PID -or $owner.Computer -ine $env:COMPUTERNAME -or $owner.ReservationVersion -ne 2) { throw 'Workflow conversion reservation ownership changed. No evidence was converted.' }
    }
    Assert-WorkflowMigrationOwnership
    if (-not (Test-Path -LiteralPath $dataPath -PathType Container)) { throw 'Workspace data folder is missing; fallback roots are not migration targets.' }
    $markerPath = Join-Path $dataPath 'workflow-id-migration.write-in-progress'
    $allFiles = @(Get-ChildItem -LiteralPath $dataPath -File -ErrorAction Stop)
    if (@($allFiles | Where-Object { $_.Name -match '\.(lock|pending|write-in-progress|archive-in-progress)$|\.checkpoint\.json$' -and (-not $SessionLock -or $_.FullName -ine $SessionLock.Path) }).Count) {
        throw 'Active reservation or unresolved write/checkpoint/archive evidence blocks workflow migration. No marker was removed.'
    }
    $files = @($allFiles | Where-Object { $_.Name -match '^(?:\d{8}-\d{4}-)?(autopilot-devices(?:-demo)?-.+|autopilot-master-audit|build-bench(?:-demo)?-.+)\.json(?:\.previous)?$' })
    if ($SessionLock) {
        $demoReservation = (Split-Path -Leaf $SessionLock.Path) -ceq 'autopilot-express-demo.session.lock'
        $files = @($files | Where-Object {
                $isDemoFile = ($_.Name -replace '^\d{8}-\d{4}-', '') -match '^(autopilot-devices-demo-|build-bench-demo-)'
                $isDemoFile -eq $demoReservation
            })
    }
    $inventory = @()
    foreach ($file in $files) {
        $content = Get-Content -LiteralPath $file.FullName -Raw -ErrorAction Stop
        if ([string]::IsNullOrWhiteSpace($content)) { throw 'Empty operational JSON is not a migration candidate.' }
        $parsed = ConvertFrom-Json -InputObject $content -DateKind String -ErrorAction Stop
        $proposed = $content
        $logicalName = $file.Name -replace '^\d{8}-\d{4}-', ''
        if ($logicalName -notmatch '^build-bench') {
            if ($content.TrimStart()[0] -notin @('[', '{')) { throw 'Operational evidence must contain records, not scalar JSON.' }
            $records = @()
            $changed = $false
            foreach ($record in $parsed) {
                $normalised = ConvertTo-NormalisedValue -Value $record
                if ($normalised -isnot [System.Collections.IDictionary]) { throw 'Operational records must be dictionaries.' }
                Assert-AttemptHistory -Record $normalised
                $converted = ConvertTo-CanonicalWorkflowRecord -Record $normalised
                if (-not $normalised.Contains('WorkflowIdVersion') -or $normalised.WorkflowIdVersion -ne 2) { $changed = $true }
                Assert-AttemptHistory -Record $converted
                $records += , $converted
            }
            if ($changed) {
                $proposed = ConvertTo-Json -InputObject $records -Depth 100
                $roundTrip = ConvertTo-NormalisedValue -Value @(ConvertFrom-Json -InputObject $proposed -DateKind String -ErrorAction Stop)
                if (-not (Test-AttemptEvidenceEqual -Left $records -Right $roundTrip)) { throw 'Canonical evidence round-trip verification failed.' }
            }
        }
        $inventory += @{ Name = $file.Name; Path = $file.FullName; Hash = (Get-FileHash -LiteralPath $file.FullName -Algorithm SHA256).Hash; Proposed = $proposed; Changed = ($proposed -cne $content) }
    }
    $changedFiles = @($inventory | Where-Object { $_.Changed })
    if (-not $Apply -or $changedFiles.Count -eq 0) {
        if ($PassThru) { return @{ FileCount = $inventory.Count; ChangedCount = $changedFiles.Count; Applied = $false; BackupPath = $null } }
        return 'Workflow migration rehearsal: {0} linked files checked; {1} need conversion. No files changed.' -f $inventory.Count, $changedFiles.Count
    }
    if (-not $PSCmdlet.ShouldProcess($dataPath, 'Back up and convert canonical workflow evidence')) { return }
    if ($SessionLock) {
        $snapshotMode = if ($Script:Runtime.IsDemoMode) { 'Demo' } else { 'Live' }
        $sessionSnapshot = New-LocalSessionRecoverySnapshot -DataPath $dataPath -Mode $snapshotMode -Confirm:$false
        Write-AutopilotExpressLog -Message ('Verified pre-conversion session backup: {0}' -f $sessionSnapshot.Path) -Level INFO
    }
    $backupPath = Join-Path $env:LOCALAPPDATA ('PowerShellScriptingNew\AutopilotExpressRecoveryEvidence\{0}-workflow-ids-{1}' -f (Get-Date -Format yyyyMMdd-HHmm), [guid]::NewGuid().Guid)
    New-Item -ItemType Directory -Path $backupPath -ErrorAction Stop | Out-Null
    foreach ($entry in $inventory) {
        Copy-Item -LiteralPath $entry.Path -Destination (Join-Path $backupPath $entry.Name) -ErrorAction Stop
        if ((Get-FileHash -LiteralPath (Join-Path $backupPath $entry.Name) -Algorithm SHA256).Hash -cne $entry.Hash) { throw 'Original evidence backup verification failed; no promotion was attempted.' }
    }
    $marker = @{ WorkflowIdVersion = 2; BackupPath = $backupPath; Files = @($inventory | ForEach-Object { @{ Name = $_.Name; SHA256 = $_.Hash } }) }
    New-Item -ItemType File -Path $markerPath -Value ($marker | ConvertTo-Json -Depth 5) -ErrorAction Stop | Out-Null
    foreach ($entry in $changedFiles) {
        $stagedPath = Join-Path $backupPath ('canonical-{0}' -f $entry.Name)
        Set-Content -LiteralPath $stagedPath -Value $entry.Proposed -Encoding utf8NoBOM -NoNewline -ErrorAction Stop
        if ((Get-Content -LiteralPath $stagedPath -Raw -ErrorAction Stop) -cne $entry.Proposed) { throw 'Canonical staging verification failed; migration marker retained.' }
    }
    Assert-WorkflowMigrationOwnership
    if (@(Get-ChildItem -LiteralPath $dataPath -File | Where-Object {
                $_.Name -match '\.(lock|pending|write-in-progress|archive-in-progress)$|\.checkpoint\.json$' -and
                $_.FullName -ine $markerPath -and (-not $SessionLock -or $_.FullName -ine $SessionLock.Path)
            }).Count) { throw 'A reservation or unresolved write appeared during migration; no promotion was attempted. Migration marker and originals retained.' }
    foreach ($entry in $inventory) {
        if ((Get-FileHash -LiteralPath $entry.Path -Algorithm SHA256).Hash -cne $entry.Hash) { throw 'Operational evidence changed after rehearsal; migration marker and originals retained.' }
    }
    foreach ($entry in $changedFiles) {
        Copy-Item -LiteralPath (Join-Path $backupPath ('canonical-{0}' -f $entry.Name)) -Destination $entry.Path -Force -ErrorAction Stop
        if ((Get-Content -LiteralPath $entry.Path -Raw -ErrorAction Stop) -cne $entry.Proposed) { throw 'Canonical promotion verification failed; migration marker retained.' }
    }
    Remove-Item -LiteralPath $markerPath -ErrorAction Stop
    if ($PassThru) { return @{ FileCount = $inventory.Count; ChangedCount = $changedFiles.Count; Applied = $true; BackupPath = $backupPath } }
    return 'Converted {0} files. Verified originals and canonical staging: {1}' -f $changedFiles.Count, $backupPath
}

function Initialize-LocalSessionForResume {
    <#
    .SYNOPSIS
        Prepare and validate saved work under the owned reservation before authentication.
    .PARAMETER SessionLock
        Current invocation's open version-two root/mode reservation.
    .DESCRIPTION
        Legacy records use the existing action-aware converter after explicit default-No
        confirmation and verified backups. Unknown versions or malformed evidence refuse
        startup. Successful conversion resumes existing work without archive/reset or replay.
    .OUTPUTS
        True when saved work is ready; false on declined conversion. Validation errors throw.
    #>
    [OutputType([bool])]
    param([Parameter(Mandatory)][ValidateNotNullOrEmpty()][hashtable]$SessionLock)
    Sync-RepoStateFilesToActiveStorage
    $dataPath = Split-Path -Parent $SessionLock.Path
    $needsConversion = $false
    foreach ($file in Get-ChildItem -LiteralPath $dataPath -File -ErrorAction Stop) {
        $name = $file.Name -replace '^\d{8}-\d{4}-', ''
        if ($name -notmatch '^(autopilot-devices(?:-demo)?-.+|autopilot-master-audit)\.json(?:\.previous)?$') { continue }
        $demoFile = $name -match '^autopilot-devices-demo-'
        if ($demoFile -ne $Script:Runtime.IsDemoMode) { continue }
        $content = Get-Content -LiteralPath $file.FullName -Raw -ErrorAction Stop
        if ([string]::IsNullOrWhiteSpace($content) -or $content.TrimStart()[0] -notin @('[', '{')) { throw 'Saved operational evidence must contain JSON records before resume.' }
        $parsed = ConvertFrom-Json -InputObject $content -ErrorAction Stop
        foreach ($record in $parsed) {
            $normalised = ConvertTo-NormalisedValue -Value $record
            if ($normalised -isnot [System.Collections.IDictionary]) { throw 'Saved operational records must be dictionaries before resume.' }
            if (-not $normalised.Contains('WorkflowIdVersion') -or $normalised.WorkflowIdVersion -eq 1) { $needsConversion = $true }
            elseif (($normalised.WorkflowIdVersion -isnot [int] -and $normalised.WorkflowIdVersion -isnot [long]) -or $normalised.WorkflowIdVersion -ne 2) { throw 'Unsupported WorkflowIdVersion. Original evidence retained; no authentication or replay was attempted.' }
        }
    }
    if ($needsConversion) {
        $plan = Invoke-WorkflowEvidenceMigration -SessionLock $SessionLock -PassThru
        Write-Host ('Saved-session preparation: {0} linked files checked; {1} require workflow-ID conversion.' -f $plan.FileCount, $plan.ChangedCount)
        Write-Host 'Conversion preserves action history, identities, timestamps and statistics; verified originals are retained outside discovery.'
        $answer = Read-ValidatedInput -Prompt 'Back up and convert saved workflow evidence, then resume? [Y] Yes [N] No' -Default 'N' -Type Choice -Choices @('Y', 'N')
        if ($answer -ne 'Y') { return $false }
        $result = Invoke-WorkflowEvidenceMigration -SessionLock $SessionLock -Apply -PassThru -Confirm:$false
        if (-not $result.Applied) { throw 'Workflow evidence was not converted. No authentication or session reset was attempted.' }
        Write-AutopilotExpressLog -Message ('Prepared saved workflow evidence. Verified originals: {0}' -f $result.BackupPath) -Level INFO
        $Script:ResumeRecoveredSession = $true
    }
    $null = Get-UserDeviceRecords
    $null = Get-BuildBenchState
    return $true
}

function ConvertTo-PersistedDeviceRecord {
    <#
    .SYNOPSIS
        Detach a device record and prepare its date fields for JSON persistence.
    .PARAMETER Record
        Validated in-memory record; original objects are not rewritten by this conversion.
    .OUTPUTS
        Persistable dictionary. Storage and audit promotion are separate guarded operations.
    #>
    param([Parameter(Mandatory)]$Record)

    $persistedRecord = ConvertTo-NormalisedValue -Value $Record
    foreach ($dateProperty in @('StartedAt', 'LastUpdatedAt', 'CompletedAt', 'DispatchedAt', 'RecoveryStartedAt')) {
        $persistedRecord[$dateProperty] = ConvertTo-PersistedDate -Value $Record[$dateProperty]
    }
    return $persistedRecord
}

function Assert-AttemptHistory {
    <#
    .SYNOPSIS
        Validate detached writer evidence without migrating or repairing history.
    .PARAMETER Record
        Normalised record or audit dictionary. Absent legacy history is permitted.
    .DESCRIPTION
        Legacy results use the typed step validator on a copy; unknown execution
        dates remain null. Record IDs are text, not necessarily factory GUIDs.
    .OUTPUTS
        None. Throws on malformed histories without deleting or normalising away evidence.
    #>
    param([Parameter(Mandatory)][System.Collections.IDictionary]$Record)
    if (-not $Record.Contains('AttemptHistory')) { return }
    if ($Record.AttemptHistory -isnot [array]) { throw 'Saved attempt history must be an array; evidence cannot be discarded.' }
    $attemptIds = @{}
    $sequence = 0
    foreach ($attempt in $Record.AttemptHistory) {
        $sequence++
        if ($attempt -isnot [System.Collections.IDictionary]) { throw 'Saved attempt history entries must be dictionaries.' }
        if (($attempt.Sequence -isnot [int] -and $attempt.Sequence -isnot [long]) -or $attempt.Sequence -ne $sequence) { throw 'Saved attempt history sequences must be contiguous and ordered.' }
        foreach ($field in @('AttemptId', 'StepId', 'ActionName', 'Actor', 'Mode', 'TenantId', 'Serial', 'RecordId', 'EvidenceKind')) {
            if ($attempt[$field] -isnot [string]) { throw ('Saved attempt history requires text field {0}.' -f $field) }
        }
        if ($attempt.AttemptId -notmatch '^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$' -or $attemptIds.ContainsKey($attempt.AttemptId)) { throw 'Saved attempt IDs must be unique GUID strings.' }
        $attemptIds[$attempt.AttemptId] = $true
        if ([string]::IsNullOrWhiteSpace($attempt.StepId) -or $attempt.EvidenceKind -cnotin @('HandlerOutcome', 'LegacyEvidence', 'RecoveryIntent', 'RecoveryAccepted', 'RecoveryAllowedObserved')) { throw 'Saved attempt history has an invalid step or evidence kind.' }
        if ([string]::IsNullOrWhiteSpace($attempt.RecordId) -or $attempt.RecordId -cne $Record.RecordId -or $attempt.Serial -cne $Record.Serial) { throw 'Saved attempt history has cross-record identity context.' }
        if ($attempt.TenantId -cne '' -and ($attempt.TenantId -notmatch '^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$' -or $attempt.TenantId -cne $Record.TenantId)) { throw 'Saved attempt history has invalid tenant context.' }
        if (-not $attempt.Contains('Timestamp') -or ($attempt.EvidenceKind -ceq 'HandlerOutcome' -and $null -eq $attempt.Timestamp)) { throw 'Saved handler outcomes require a timestamp.' }
        if ($null -ne $attempt.Timestamp) {
            if ($attempt.Timestamp -isnot [string] -or $attempt.Timestamp -notmatch '^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(\.\d{1,7})?(Z|[+-]\d{2}:\d{2})?$') { throw 'Saved attempt timestamps must be ISO date strings.' }
            $null = Get-Date -Date $attempt.Timestamp -ErrorAction Stop
        }
        if ($attempt.Result -isnot [System.Collections.IDictionary]) { throw 'Saved attempt results must be dictionaries.' }
        if ($attempt.EvidenceKind -ceq 'LegacyEvidence') {
            $null = ConvertTo-StepHashtable -Value @{ $attempt.StepId = $attempt.Result }
            continue
        }
        if ($attempt.Mode -cnotin @('normal', 'demo', 'Live', 'Demo') -or [string]::IsNullOrWhiteSpace($attempt.Actor) -or [string]::IsNullOrWhiteSpace($attempt.ActionName)) { throw 'Saved handler outcome has invalid actor, mode or action context.' }
        foreach ($flag in @('Success', 'IsSimulated')) {
            if ($attempt.Result[$flag] -isnot [bool]) { throw ('Saved attempt result {0} must be a Boolean.' -f $flag) }
        }
        foreach ($field in @('ActionName', 'Summary', 'Notes', 'CompletionState')) {
            if ($attempt.Result[$field] -isnot [string]) { throw ('Saved attempt result {0} must be text.' -f $field) }
        }
        if ($attempt.Result.ActionName -cne $attempt.ActionName -or $attempt.Result.CompletionState -cnotin @('Verified', 'TechnicianConfirmed', 'Submitted', 'Blocked', 'Failed', 'AuditedException', 'Simulated', 'LegacyCompleted') -or $attempt.Result.Data -isnot [System.Collections.IDictionary]) { throw 'Saved attempt result has invalid completion evidence.' }
        if ($attempt.EvidenceKind -cin @('RecoveryIntent', 'RecoveryAccepted', 'RecoveryAllowedObserved')) {
            $expectedState = switch ($attempt.EvidenceKind) {
                RecoveryIntent { 'Blocked' }
                RecoveryAccepted { 'Submitted' }
                RecoveryAllowedObserved { 'TechnicianConfirmed' }
            }
            $recoveryData = $attempt.Result.Data
            if ($attempt.ActionName -cne 'ClearUserlessEnrollmentStatus' -or $attempt.Mode -cnotin @('normal', 'Live') -or
                $attempt.Result.CompletionState -cne $expectedState -or
                $attempt.Result.Success -ne ($attempt.EvidenceKind -ceq 'RecoveryAllowedObserved') -or $attempt.Result.IsSimulated -or
                $recoveryData.Count -ne 2 -or $recoveryData.RecoveryStartedAt -isnot [string] -or
                $recoveryData.RecoveryStartedAt -notmatch '^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(\.\d{1,7})?(Z|[+-]\d{2}:\d{2})?$' -or
                $recoveryData.AutopilotDeviceId -isnot [string] -or [string]::IsNullOrWhiteSpace($recoveryData.AutopilotDeviceId)) {
                throw 'Saved recovery submission evidence is malformed.'
            }
            $recoveryStarted = Get-Date -Date $recoveryData.RecoveryStartedAt -ErrorAction Stop
            $recordedAt = Get-Date -Date $attempt.Timestamp -ErrorAction Stop
            if ($recordedAt.ToUniversalTime() -lt $recoveryStarted.ToUniversalTime()) { throw 'Saved recovery submission evidence predates its recovery cycle.' }
        }
    }
}

function Test-AttemptEvidenceEqual {
    <#
    .SYNOPSIS
        Compare normalised evidence structurally, never by dictionary JSON order.
    .PARAMETER Left
        Existing evidence, with dates normalised by the record staging helpers.
    .PARAMETER Right
        Proposed evidence. Arrays retain order; text and keys are case-sensitive.
    .OUTPUTS
        Boolean equality; ISO dates compare as UTC instants on either host.
    #>
    param($Left, $Right)
    if ($null -eq $Left -or $null -eq $Right) { return ($null -eq $Left -and $null -eq $Right) }
    if ($Left -is [System.Collections.IDictionary] -or $Right -is [System.Collections.IDictionary]) {
        if ($Left -isnot [System.Collections.IDictionary] -or $Right -isnot [System.Collections.IDictionary] -or $Left.Count -ne $Right.Count) { return $false }
        # List the right-hand keys once per dictionary rather than once per left-hand key.
        # -cnotcontains keeps the exact, case-sensitive key match.
        $rightKeys = @($Right.Keys)
        foreach ($key in $Left.Keys) {
            if ($rightKeys -cnotcontains $key) { return $false }
            $leftValue = $Left[$key]
            $rightValue = $Right[$key]
            # Most saved fields are identical text or plain values; settle those here rather than
            # with another call. Mismatches and anything else still take the full comparison below.
            if ($leftValue -is [string] -and $rightValue -is [string] -and $leftValue -ceq $rightValue) { continue }
            if ($leftValue -is [ValueType] -and $rightValue -is [ValueType] -and ($leftValue -is [bool]) -eq ($rightValue -is [bool]) -and $leftValue -eq $rightValue) { continue }
            if (-not (Test-AttemptEvidenceEqual -Left $leftValue -Right $rightValue)) { return $false }
        }
        return $true
    }
    if ($Left -is [array] -or $Right -is [array]) {
        if ($Left -isnot [array] -or $Right -isnot [array] -or $Left.Count -ne $Right.Count) { return $false }
        for ($index = 0; $index -lt $Left.Count; $index++) {
            $leftValue = $Left[$index]
            $rightValue = $Right[$index]
            if ($leftValue -is [string] -and $rightValue -is [string] -and $leftValue -ceq $rightValue) { continue }
            if ($leftValue -is [ValueType] -and $rightValue -is [ValueType] -and ($leftValue -is [bool]) -eq ($rightValue -is [bool]) -and $leftValue -eq $rightValue) { continue }
            if (-not (Test-AttemptEvidenceEqual -Left $leftValue -Right $rightValue)) { return $false }
        }
        return $true
    }
    if ($Left -is [string] -or $Right -is [string]) {
        if ($Left -isnot [string] -or $Right -isnot [string]) { return $false }
        # Identical text is always equal, including identical dates, so skip date parsing.
        if ($Left -ceq $Right) { return $true }
        if ($Left -match '^\d{4}-\d{2}-\d{2}T' -and $Right -match '^\d{4}-\d{2}-\d{2}T') {
            try { return ((Get-Date -Date $Left -ErrorAction Stop).ToUniversalTime() -eq (Get-Date -Date $Right -ErrorAction Stop).ToUniversalTime()) }
            catch { return ($Left -ceq $Right) }
        }
        return ($Left -ceq $Right)
    }
    if ($Left -is [bool] -or $Right -is [bool]) { return ($Left -is [bool] -and $Right -is [bool] -and $Left -eq $Right) }
    return ($Left -eq $Right)
}

function Assert-AttemptHistoryPreserved {
    <#
    .SYNOPSIS
        Refuse replacement, truncation or removal of previously saved attempts.
    .PARAMETER Records
        Complete staged proposal, not mutated by validation.
    .PARAMETER ExistingRecords
        Independently read persisted records; malformed evidence fails closed.
    .PARAMETER AllowUnmatchedRecords
        Audit-only historical records remain in the ledger, outside this session.
    .OUTPUTS
        None. Rejects history loss or evidence changes before persistence.
    #>
    param(
        [AllowEmptyCollection()][System.Collections.IEnumerable]$Records = @(),
        [AllowEmptyCollection()][System.Collections.IEnumerable]$ExistingRecords = @(),
        [switch]$AllowUnmatchedRecords
    )
    $recordMap = @{}
    $attemptIds = @{}
    foreach ($record in $Records) {
        Assert-AttemptHistory -Record $record
        if ($record.RecordId -isnot [string] -or [string]::IsNullOrWhiteSpace($record.RecordId) -or $recordMap.ContainsKey($record.RecordId)) { throw 'Saved attempt history requires unique non-empty record IDs.' }
        $recordMap[$record.RecordId] = $record
        foreach ($attempt in $record.AttemptHistory) {
            if ($attemptIds.ContainsKey($attempt.AttemptId)) { throw 'Saved attempt IDs must be unique GUID strings across records.' }
            $attemptIds[$attempt.AttemptId] = $true
        }
    }
    $existingIds = @{}
    $existingAttemptIds = @{}
    foreach ($existing in $ExistingRecords) {
        Assert-AttemptHistory -Record $existing
        if ($existing.RecordId -isnot [string] -or [string]::IsNullOrWhiteSpace($existing.RecordId) -or $existingIds.ContainsKey($existing.RecordId)) { throw 'Saved attempt history requires unique non-empty record IDs.' }
        $existingIds[$existing.RecordId] = $true
        foreach ($attempt in $existing.AttemptHistory) {
            if ($existingAttemptIds.ContainsKey($attempt.AttemptId)) { throw 'Saved attempt IDs must be unique GUID strings across records.' }
            $existingAttemptIds[$attempt.AttemptId] = $true
        }
        $proposed = $recordMap[$existing.RecordId]
        $existingHistoryCount = 0
        if ($existing.Contains('AttemptHistory')) { $existingHistoryCount = $existing.AttemptHistory.Count }
        if ($null -eq $proposed) {
            if ($AllowUnmatchedRecords -or $existingHistoryCount -eq 0) { continue }
            throw 'Persisted attempt history record removal is refused; retain a soft-removed record.'
        }
        # SYNC-RECEIPTS and IMPORT-RECEIPTS: submission ledgers are append-only, exactly like
        # attempts. Re-read records can surface an empty ledger as $null; real entries are never
        # null (the loader validates them), so null placeholders are discarded before counting.
        foreach ($ledger in @(@{ Name = 'SyncSubmissions'; Label = 'sync submission' }, @{ Name = 'ImportSubmissions'; Label = 'import submission' })) {
            $existingLedger = @(@(if ($existing.Contains($ledger.Name)) { $existing[$ledger.Name] }) | Where-Object { $null -ne $_ })
            if ($existingLedger.Count -eq 0) { continue }
            $proposedLedger = @(@(if ($proposed.Contains($ledger.Name)) { $proposed[$ledger.Name] }) | Where-Object { $null -ne $_ })
            if ($proposedLedger.Count -lt $existingLedger.Count) { throw ('Persisted {0} ledger truncation is refused.' -f $ledger.Label) }
            for ($index = 0; $index -lt $existingLedger.Count; $index++) {
                if (-not (Test-AttemptEvidenceEqual -Left $existingLedger[$index] -Right $proposedLedger[$index])) { throw ('Persisted {0} ledger alteration is refused.' -f $ledger.Label) }
            }
        }
        if ($existingHistoryCount -eq 0) { continue }
        if ($proposed.RecordId -cne $existing.RecordId -or $proposed.Serial -cne $existing.Serial -or ($existing.TenantId -and $proposed.TenantId -cne $existing.TenantId)) { throw 'Persisted attempt history identity alteration is refused.' }
        if ($proposed.AttemptHistory -isnot [array] -or $proposed.AttemptHistory.Count -lt $existing.AttemptHistory.Count) { throw 'Persisted attempt history truncation is refused.' }
        for ($index = 0; $index -lt $existing.AttemptHistory.Count; $index++) {
            if (-not (Test-AttemptEvidenceEqual -Left $existing.AttemptHistory[$index] -Right $proposed.AttemptHistory[$index])) { throw 'Persisted attempt history prefix alteration is refused.' }
        }
    }
}

function Get-MasterAuditProposal {
    <#
    .SYNOPSIS
        Stage the complete existing ledger merge without writing operational data.
    .PARAMETER Records
        Persisted device records to merge; the caller's objects are not changed.
    .PARAMETER IncludeEntries
        Also return the merged entries, so the record writer can keep them as its private
        copy for the next save (see Get-VerifiedSaveCopy).
    .OUTPUTS
        Exact proposed ledger JSON, or null in Demo mode. With IncludeEntries, a hashtable
        with Json and Entries keys.
    #>
    param([Parameter(Mandatory)][System.Collections.IEnumerable]$Records, [switch]$IncludeEntries)
    if ($Script:Runtime.IsDemoMode) { return }
    $auditPath = Get-MasterAuditFilePath
    $existingEntries = @()
    $savedCopy = Get-VerifiedSaveCopy -Path $auditPath
    if ($null -ne $savedCopy) {
        $existingEntries = $savedCopy.Value
    }
    elseif (Test-Path $auditPath) {
        try {
            $auditContent = Get-Content -Raw -Path $auditPath -ErrorAction Stop
            if ([string]::IsNullOrWhiteSpace([string]$auditContent)) { throw 'Saved audit records must not be null or empty content.' }
            $rawEntries = $auditContent | ConvertFrom-Json -ErrorAction Stop
            if ($null -eq $rawEntries -and $auditContent -notmatch '^\s*\[\s*\]\s*$') { throw 'Saved audit records must not be null or empty content.' }
            if ($null -ne $rawEntries) { $existingEntries = ConvertTo-NormalisedValue -Value @($rawEntries) }
        }
        catch {
            Write-AutopilotExpressLog -Message ('Failed to load master audit ledger: {0}' -f $_.Exception.Message) -Level 'WARN'
            throw
        }
    }

    Assert-AttemptHistoryPreserved -Records $Records -ExistingRecords $existingEntries -AllowUnmatchedRecords
    $entryMap = @{}
    foreach ($entry in $existingEntries) {
        if ($entry.RecordId) { $entryMap[$entry.RecordId] = $entry }
    }

    foreach ($record in @($Records)) {
        if (-not $record.RecordId) { continue }
        $completedAt = ConvertTo-PersistedDate -Value $record.CompletedAt
        $entryMap[$record.RecordId] = [ordered]@{
            RecordId             = $record.RecordId
            BuildCycleId         = [string]$record.BuildCycleId
            WorkflowIdVersion    = $record.WorkflowIdVersion
            TenantId             = $record.TenantId
            AutopilotDeviceId    = $record.AutopilotDeviceId
            ManagedDeviceId      = $record.ManagedDeviceId
            AzureAdDeviceId      = $record.AzureAdDeviceId
            Serial               = $record.Serial
            ConfigItem           = $record.ConfigItem
            SiteCode             = $record.SiteCode
            DeviceType           = $record.DeviceType
            GroupTag             = $record.GroupTag
            StartedAt            = ConvertTo-PersistedDate -Value $record.StartedAt
            CompletedAt          = $completedAt
            DispatchConfirmed    = [bool]$record.DispatchConfirmed
            DispatchedAt         = ConvertTo-PersistedDate -Value $record.DispatchedAt
            CompletedBy          = $record.CompletedBy
            StartedBy            = $record.StartedBy
            LastUpdatedAt        = ConvertTo-PersistedDate -Value $record.LastUpdatedAt
            LastUpdatedBy        = $record.LastUpdatedBy
            Status               = $record.Status
            Result               = $record.Status
            IsCompletionVerified = $record.IsCompletionVerified
            IntuneDeviceName     = $record.IntuneDeviceName
            IntuneInventory      = ConvertTo-NormalisedValue -Value $record.IntuneInventory
            EntraDeviceId        = $record.EntraDeviceId
            TechnicianUser       = $record.TechnicianUserPrincipalName
            FinalPrimaryUserId   = $record.FinalPrimaryUserId
            FinalPrimaryUser     = $record.FinalPrimaryUserPrincipalName
            FinalPrimaryUserName = $record.FinalPrimaryUserDisplayName
            RecoveryActive       = $record.RecoveryActive
            RecoveryStartedAt    = ConvertTo-PersistedDate -Value $record.RecoveryStartedAt
            RecoveryReason       = $record.RecoveryReason
            RecoveryHistory      = ConvertTo-NormalisedValue -Value $record.RecoveryHistory
            AttemptHistory       = ConvertTo-NormalisedValue -Value $record.AttemptHistory
            SyncSubmissions      = ConvertTo-NormalisedValue -Value @($record.SyncSubmissions | Where-Object { $null -ne $_ })
            ImportSubmissions    = ConvertTo-NormalisedValue -Value @($record.ImportSubmissions | Where-Object { $null -ne $_ })
            Steps                 = ConvertTo-NormalisedValue -Value $record.Steps
        }
    }

    $serialisedEntries = @($entryMap.Values | Sort-Object Serial, StartedAt)
    $auditJson = if ($serialisedEntries.Count -gt 0) { $serialisedEntries | ConvertTo-Json -Depth 100 } else { '[]' }
    if ($IncludeEntries) { return @{ Json = $auditJson; Entries = $serialisedEntries } }
    return $auditJson
}

function Update-MasterAuditLedger {
    <#
    .SYNOPSIS
        Persist the validated root-wide audit proposal using guarded UTF-8 writes.
    .PARAMETER Records
        Current session records used when a precomputed proposal is not supplied.
    .PARAMETER ProposedContent
        Optional already-validated ledger JSON prepared by the checkpoint coordinator.
    .OUTPUTS
        None. Live audit write failures propagate; Demo does not update the Live ledger.
    #>
    param([Parameter(Mandatory)][System.Collections.IEnumerable]$Records, [string]$ProposedContent)
    if ($Script:Runtime.IsDemoMode) { return }
    if (-not $PSBoundParameters.ContainsKey('ProposedContent')) { $ProposedContent = Get-MasterAuditProposal -Records $Records }
    Write-Utf8File -Path (Get-MasterAuditFilePath) -Content $ProposedContent
}

function Get-LocalCheckpointPath {
    <#
    .SYNOPSIS
        Locate a per-user, per-mode checkpoint proposal, not a migration candidate.
    .PARAMETER BasePath
        Explicit root for read-only preflight without root selection or directory
        creation. When omitted, use the active root for existing checkpoint saves.
    .OUTPUTS
        Checkpoint proposal path in the requested root and current mode.
    #>
    param([ValidateNotNullOrEmpty()][string]$BasePath)
    $modeName = if ($Script:Runtime.IsDemoMode) { 'demo' } else { 'live' }
    $dataPath = if ($PSBoundParameters.ContainsKey('BasePath')) { Join-Path $BasePath $Script:Config.DataFolderRelative } else { Get-DataFolderPath }
    return Join-Path $dataPath ('autopilot-express-{0}-{1}.checkpoint.json' -f $modeName, $env:USERNAME)
}

function Assert-LocalCheckpointState {
    <#
    .SYNOPSIS
        Reject checkpoint proposals and orphan writer evidence without changes.
    .PARAMETER BasePath
        Explicit root to inspect before probes, reservation or migration. Fallback
        authority does not establish lineage for an unfinished source checkpoint.
        When omitted, inspect the active root as before.
    .OUTPUTS
        None. Unfinished checkpoints block reuse; no automatic replay or rollback occurs.
    #>
    param([ValidateNotNullOrEmpty()][string]$BasePath)
    $path = if ($PSBoundParameters.ContainsKey('BasePath')) { Get-LocalCheckpointPath -BasePath $BasePath } else { Get-LocalCheckpointPath }
    # Both messages name the guided recovery command so a stranded save never needs manual file surgery.
    $guidance = 'Check it without signing in: .\autopilot-express.ps1 -CheckpointAction Inspect -CheckpointPath ''{0}''. After every session using this store has stopped, resolve it with -CheckpointAction Resolve -CheckpointPath ''{0}'' -ConfirmStopped (a verified backup is taken first).' -f $path
    try { Assert-FileWriteRecoveryState -Path $path }
    catch { throw ('{0} {1}' -f $_.Exception.Message, $guidance) }
    if (Test-Path -LiteralPath $path) {
        throw ('Unresolved local checkpoint at {0}. Preserve all evidence and inspect local and tenant state before resuming; no automatic replay or rollback is permitted. {1}' -f $path, $guidance)
    }
}

function Invoke-LocalCheckpointRecovery {
    <#
    .SYNOPSIS
        Inspect, or explicitly resolve, a save checkpoint left behind by a crash.
    .DESCRIPTION
        A device-records save first writes a checkpoint holding the full proposed records,
        audit and bench content, then writes each real file, then deletes the checkpoint.
        If the process is killed part-way, the checkpoint stays and startup is refused.

        This function compares each real file with the checkpoint's proposal:
          - Not saved: the file still holds the previous good save.
          - Saved:     the file already matches the proposal.
        Resolve then takes a verified, hashed backup of the whole data folder and:
          - All not saved (or the checkpoint itself was never finished): discards the
            unfinished proposal; the previous good save stays in place.
          - All saved: removes the leftover checkpoint only.
          - Mixed: finishes writing the remaining files from the proposal, so all three
            files agree again, then removes the checkpoint.
        Local files only. No tenant action is replayed and no Graph sign-in occurs.
        Interrupted writes on the real files, an active session owner, or a damaged
        checkpoint are refused for manual review.
    .PARAMETER Path
        Exact autopilot-express-<live|demo>-<user>.checkpoint.json path from the startup error.
    .PARAMETER Resolve
        Apply the resolution described above. Without it, the function is read-only.
    .PARAMETER ConfirmStopped
        Operator confirmation that every session using this store has stopped.
    .OUTPUTS
        Summary object: state, per-file result, backup location and outcome.
    #>
    [CmdletBinding(SupportsShouldProcess)]
    [OutputType([pscustomobject])]
    param(
        [Parameter(Mandatory)][ValidateNotNullOrEmpty()][string]$Path,
        [switch]$Resolve,
        [switch]$ConfirmStopped
    )
    $fullPath = [IO.Path]::GetFullPath($Path)
    $leaf = Split-Path -Leaf $fullPath
    if ($leaf -notmatch '^autopilot-express-(live|demo)-(.+)\.checkpoint\.json$') { throw 'Select the exact autopilot-express-<live|demo>-<user>.checkpoint.json path shown in the startup error.' }
    $modeName = $Matches[1]
    if ($Matches[2] -ine $env:USERNAME) { throw ('This checkpoint belongs to {0}. Resolve it while signed in to Windows as that user; nothing was changed.' -f $Matches[2]) }
    $dataPath = Split-Path -Parent $fullPath
    $artefacts = @('', '.pending', '.previous', '.write-in-progress' | ForEach-Object { '{0}{1}' -f $fullPath, $_ } | Where-Object { Test-Path -LiteralPath $_ })
    if (-not $artefacts.Count) { throw ('No checkpoint or checkpoint artefact exists at {0}; nothing needs resolving.' -f $fullPath) }

    $previousDemoMode = $Script:Runtime.IsDemoMode
    $Script:Runtime.IsDemoMode = $modeName -eq 'demo'
    try {
        # Refuse while the session that owns this store may still be running.
        $lockPath = Join-Path $dataPath ('autopilot-express-{0}.session.lock' -f $modeName)
        if (Test-Path -LiteralPath $lockPath) {
            $lockState = Invoke-LocalSessionLockRecovery -Path $lockPath
            if (-not $lockState.CanRecover) { throw ('The session lock shows a running or unverified owner ({0}). Close every Autopilot Express window and try again; nothing was changed.' -f $lockState.State) }
        }

        # Resolve the real files exactly as the save wrote them (indexed session names first).
        $index = Get-SessionFileIndex -DataPath $dataPath
        $deviceFile = if ($index) { $index.DeviceFile } else { '{0}-{1}.json' -f (Get-ModeUserDataFilePrefix), $env:USERNAME }
        $benchFile = if ($index) { $index.BenchFile } else { '{0}-{1}.json' -f (Get-ModeBuildBenchFilePrefix), $env:USERNAME }
        $targets = [ordered]@{ Records = Join-Path $dataPath $deviceFile; Bench = Join-Path $dataPath $benchFile }
        if ($modeName -eq 'live') { $targets.Audit = Join-Path $dataPath $Script:Config.MasterAuditFileName }
        foreach ($name in $targets.Keys) {
            try { Assert-FileWriteRecoveryState -Path $targets[$name] }
            catch { throw ('The {0} file also has an interrupted save, so this needs manual review. Nothing was changed. Detail: {1}' -f $name, $_.Exception.Message) }
        }

        # A checkpoint that was never fully written means no real file was touched yet.
        $checkpointComplete = (Test-Path -LiteralPath $fullPath) -and -not (Test-Path -LiteralPath ('{0}.pending' -f $fullPath))
        $proposal = $null
        if ($checkpointComplete) {
            try {
                $proposal = Get-Content -LiteralPath $fullPath -Raw -ErrorAction Stop | ConvertFrom-Json -ErrorAction Stop
                $rootMatches = [string]::Equals([IO.Path]::GetFullPath([string]$proposal.Root).TrimEnd('\'), $dataPath.TrimEnd('\'), [StringComparison]::OrdinalIgnoreCase)
                if ($proposal.SchemaVersion -ne 1 -or -not $rootMatches -or $proposal.User -ine $env:USERNAME -or $proposal.Mode -cne $modeName -or
                    [string]::IsNullOrWhiteSpace([string]$proposal.Token) -or $proposal.RecordsJson -isnot [string] -or
                    ($null -ne $proposal.AuditJson -and $proposal.AuditJson -isnot [string]) -or ($null -ne $proposal.BenchJson -and $proposal.BenchJson -isnot [string])) { throw 'metadata does not match this store' }
                foreach ($content in @($proposal.RecordsJson, $proposal.AuditJson, $proposal.BenchJson)) { if ($null -ne $content) { $null = $content | ConvertFrom-Json -ErrorAction Stop } }
            }
            catch { throw ('The checkpoint is damaged ({0}), so it cannot be compared safely. Nothing was changed; keep the file for review.' -f $_.Exception.Message) }
        }

        $results = [ordered]@{}
        if ($proposal) {
            $proposed = @{ Records = $proposal.RecordsJson; Bench = $proposal.BenchJson; Audit = $proposal.AuditJson }
            foreach ($name in $targets.Keys) {
                if ($null -eq $proposed[$name]) { continue }
                $current = if (Test-Path -LiteralPath $targets[$name]) { [string](Get-Content -LiteralPath $targets[$name] -Raw -ErrorAction Stop) } else { $null }
                $results[$name] = if ($current -ceq $proposed[$name]) { 'Saved' } else { 'Not saved' }
            }
        }
        $savedCount = @($results.Values | Where-Object { $_ -eq 'Saved' }).Count
        $state = if (-not $proposal) { 'CheckpointUnfinished' } elseif ($savedCount -eq 0) { 'NothingSaved' } elseif ($savedCount -eq $results.Count) { 'AllSaved' } else { 'PartlySaved' }
        $plan = @{
            CheckpointUnfinished = 'The crash happened while the checkpoint itself was being written, so no device file was touched. Resolve keeps the previous good save and removes the unfinished checkpoint.'
            NothingSaved         = 'No device file was changed. Resolve keeps the previous good save and discards the unfinished proposal; any lost step is simply redone next time.'
            AllSaved             = 'Every device file already holds the new save. Resolve only removes the leftover checkpoint.'
            PartlySaved          = 'Some files hold the new save and some do not. Resolve finishes writing the remaining files from the checkpoint so all files agree, then removes it.'
        }[$state]
        $summary = [pscustomobject]@{
            CheckpointPath = $fullPath
            State          = $state
            Files          = @($results.Keys | ForEach-Object { '{0}: {1}' -f $_, $results[$_] })
            ResolveWill    = $plan
            BackupPath     = $null
            Outcome        = 'Inspected only; nothing was changed.'
        }
        if (-not $Resolve) { return $summary }
        if (-not $ConfirmStopped) { throw 'Resolve requires -ConfirmStopped after every session using this store has stopped. Nothing was changed.' }
        if (-not $PSCmdlet.ShouldProcess($fullPath, 'Back up the data folder and resolve the leftover checkpoint')) { return $summary }

        $snapshot = New-LocalSessionRecoverySnapshot -DataPath $dataPath -Mode $(if ($modeName -eq 'demo') { 'Demo' } else { 'Live' }) -Confirm:$false
        $summary.BackupPath = $snapshot.Path
        if ($state -eq 'PartlySaved') {
            foreach ($name in @($results.Keys | Where-Object { $results[$_] -eq 'Not saved' })) {
                Write-Utf8File -Path $targets[$name] -Content $proposed[$name]
                Write-AutopilotExpressLog -Message ('Checkpoint recovery finished saving the {0} file from the checkpoint proposal.' -f $name) -Level 'WARN'
            }
        }
        # Remove only checkpoint artefacts that are byte-identical to the verified backup.
        foreach ($artefact in $artefacts) {
            $backup = @($snapshot.Inventory | Where-Object { $_.SourcePath -eq $artefact })
            if ($backup.Count -ne 1 -or (Get-FileHash -LiteralPath $artefact -Algorithm SHA256 -ErrorAction Stop).Hash -cne $backup[0].SHA256) { throw ('Checkpoint evidence changed during recovery: {0}. Backup retained at {1}; nothing else was removed.' -f $artefact, $snapshot.Path) }
            Remove-Item -LiteralPath $artefact -ErrorAction Stop
        }
        $summary.Outcome = 'Resolved. Start Autopilot Express normally; if it reports a session lock, choose [C] to back it up and recover.'
        Write-AutopilotExpressLog -Message ('Checkpoint recovery resolved {0} as {1}; verified backup at {2}.' -f $fullPath, $state, $snapshot.Path) -Level 'WARN'
        return $summary
    }
    finally { $Script:Runtime.IsDemoMode = $previousDemoMode }
}

function Get-LocalCheckpointInspection {
    <#
    .SYNOPSIS
        Return read-only checkpoint proposal and file evidence for operator review.
    .DESCRIPTION
        Never promotes, repairs or deletes evidence and never invokes tenant actions.
        Damaged markers throw and remain untouched. This is not reconciliation approval.
    .OUTPUTS
        Checkpoint envelope and the presence of each target and recovery artefact.
    #>
    $path = Get-LocalCheckpointPath
    $proposal = Get-Content -LiteralPath $path -Raw -ErrorAction Stop | ConvertFrom-Json -ErrorAction Stop
    $modeName = if ($Script:Runtime.IsDemoMode) { 'demo' } else { 'live' }
    if ($proposal.SchemaVersion -ne 1 -or $proposal.Root -cne (Get-DataFolderPath) -or
        $proposal.User -cne $env:USERNAME -or $proposal.Mode -cne $modeName -or
        [string]::IsNullOrWhiteSpace([string]$proposal.Token) -or $proposal.RecordsJson -isnot [string] -or
        ($null -ne $proposal.AuditJson -and $proposal.AuditJson -isnot [string]) -or
        ($null -ne $proposal.BenchJson -and $proposal.BenchJson -isnot [string])) { throw 'Invalid local checkpoint metadata or proposal. Evidence was not changed.' }
    foreach ($content in @($proposal.RecordsJson, $proposal.AuditJson, $proposal.BenchJson)) {
        if ($null -ne $content) { $null = $content | ConvertFrom-Json -ErrorAction Stop }
    }
    $evidence = @()
    $paths = @($path, (Get-UserDataFilePath), (Get-BuildBenchStatePath))
    if (-not $Script:Runtime.IsDemoMode) { $paths += Get-MasterAuditFilePath }
    foreach ($target in $paths) {
        foreach ($suffix in @('', '.pending', '.previous', '.write-in-progress')) {
            $evidence += @{ Path = ('{0}{1}' -f $target, $suffix); Exists = (Test-Path -LiteralPath ('{0}{1}' -f $target, $suffix)) }
        }
    }
    return @{ Proposal = $proposal; Evidence = $evidence }
}

function Get-UserDeviceRecords {
    <#
    .SYNOPSIS
        Load and validate current-user device evidence without repairing malformed files.
    .OUTPUTS
        Record array with normalised dates, steps and histories. Invalid identities, state or
        recovery evidence throw; the original file remains available for operator review.
    #>
    $path = Get-UserDataFilePath
    $records = @()
    if (-not (Test-Path $path)) {
        return , $records
    }
    try {
        $json = Get-Content -Raw -Path $path -ErrorAction Stop
        if ([string]::IsNullOrWhiteSpace([string]$json)) { throw 'Saved device records must not be null or empty content.' }
        $data = $json | ConvertFrom-Json -ErrorAction Stop
        if ($null -eq $data -and $json -notmatch '^\s*\[\s*\]\s*$') { throw 'Saved device records must not be null or empty content.' }
        $items = @($data)
        if ($null -eq $data) { $items = @() }
        $recordIndex = 0
        foreach ($r in $items) {
            $recordIndex++
            $r = ConvertTo-NormalisedValue -Value $r
            if ($r -isnot [System.Collections.IDictionary]) { throw 'Every saved device record must be a dictionary.' }
            if ($Script:WorkflowIdVersion -eq 2 -and (($r.WorkflowIdVersion -isnot [int] -and $r.WorkflowIdVersion -isnot [long]) -or $r.WorkflowIdVersion -ne 2)) {
                throw 'Legacy or unknown WorkflowIdVersion requires explicit offline evidence conversion before resume. No evidence was relabelled or replayed.'
            }
            if ($r.Contains('TenantId') -and ($r.TenantId -isnot [string] -or
                    ($r.TenantId -cne '' -and $r.TenantId -notmatch '^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$'))) {
                throw 'Saved device TenantId must be empty legacy text or a GUID string.'
            }
            if ($r.Contains('BuildCycleId') -and ($r.BuildCycleId -isnot [string] -or ($r.BuildCycleId -ne '' -and $r.BuildCycleId -notmatch '^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$'))) { throw 'Saved BuildCycleId must be empty legacy text or a GUID string.' }
            foreach ($flag in @('IsCompletionVerified', 'RecoveryActive', 'DispatchConfirmed')) {
                if ($r.Contains($flag) -and $r[$flag] -isnot [bool]) { throw ('Saved device flag {0} must be a Boolean.' -f $flag) }
            }
            foreach ($textField in @('RecordId', 'Serial', 'ConfigItem', 'AutopilotDeviceId', 'ManagedDeviceId', 'AzureAdDeviceId', 'EntraDeviceId', 'IntuneDeviceName', 'SiteCode', 'DeviceType', 'GroupTag', 'Status', 'StartedBy', 'LastUpdatedBy', 'CompletedBy', 'RecoveryReason', 'TechnicianUserPrincipalName', 'TechnicianUser', 'FinalPrimaryUserId', 'FinalPrimaryUserPrincipalName', 'FinalPrimaryUser', 'FinalPrimaryUserDisplayName', 'FinalPrimaryUserName')) {
                if ($null -ne $r[$textField] -and $r[$textField] -isnot [string]) { throw ('Saved device field {0} must be text.' -f $textField) }
            }
            foreach ($dateField in @('StartedAt', 'LastUpdatedAt', 'CompletedAt', 'DispatchedAt', 'RecoveryStartedAt')) {
                if ($null -ne $r[$dateField]) {
                    $dateInput = $r[$dateField]
                    if ($dateInput -is [System.Collections.IDictionary] -and $dateInput.Contains('value')) { $dateInput = $dateInput.value }
                    if ($dateInput -isnot [string] -and $dateInput -isnot [DateTime]) { throw ('Saved device date {0} has an invalid type.' -f $dateField) }
                    $null = Get-Date -Date $dateInput -ErrorAction Stop
                }
            }
            if ($r.Contains('Steps') -and $null -eq $r.Steps) { throw 'Saved Steps cannot be null.' }
            Assert-AttemptHistory -Record $r
            if ($r.Contains('ImagingSessionStarts')) {
                if ($r.ImagingSessionStarts -isnot [array]) { throw 'Saved ImagingSessionStarts must be an array.' }
                foreach ($sessionDate in $r.ImagingSessionStarts) {
                    if (($sessionDate -isnot [string] -and $sessionDate -isnot [DateTime]) -or (ConvertTo-RecordDate -Value $sessionDate) -eq [DateTime]::MinValue) { throw 'Saved imaging session dates must be valid timestamps.' }
                }
            }
            if ($r.Contains('RecoveryHistory')) {
                if ($null -eq $r.RecoveryHistory) { $r.RecoveryHistory = @() }
                if ($r.RecoveryHistory -isnot [array]) { throw 'Saved recovery history must be an array.' }
                $historyEntryIndex = 0
                foreach ($entry in $r.RecoveryHistory) {
                    $historyEntryIndex++
                    if ($entry -isnot [System.Collections.IDictionary]) {
                        $entryType = if ($null -eq $entry) { 'null' } else { $entry.GetType().Name }
                        throw ('Saved recovery history entries must be dictionaries. Record {0}; history entry {1}; type {2}. Preserve the data file and recovery artefacts for review; no automatic repair or action replay was performed.' -f $recordIndex, $historyEntryIndex, $entryType)
                    }
                    foreach ($field in @('Stage', 'Actor', 'Timestamp')) {
                        if ($entry[$field] -isnot [string] -or [string]::IsNullOrWhiteSpace($entry[$field])) { throw ('Saved recovery history requires text field {0}.' -f $field) }
                    }
                    $null = Get-Date -Date $entry.Timestamp -ErrorAction Stop
                    if ($entry.Contains('Steps')) { $entry.Steps = ConvertTo-StepHashtable -Value $entry.Steps }
                }
            }
            if ($r.Contains('IntuneInventory')) {
                if ($r.IntuneInventory -isnot [System.Collections.IDictionary]) { throw 'Saved IntuneInventory must be a dictionary.' }
                foreach ($inventoryField in $r.IntuneInventory.Keys) {
                    if ($inventoryField -notin @('IntuneHostName', 'EthernetMacAddress', 'WiFiMacAddress', 'EntraDeviceId', 'PrimaryUser', 'OperatingSystem', 'OsVersion', 'OsRelease', 'FieldSetVersion', 'ManagedDeviceId', 'TenantId', 'BuildCycleId', 'CheckedAt', 'CapturedAt', 'LastSyncDateTime', 'Status', 'Mode') -or $r.IntuneInventory[$inventoryField] -isnot [string]) { throw 'Saved IntuneInventory contains an unknown field or non-text value.' }
                }
            }
            $obj = New-EmptyDeviceRecord
            $obj.TenantId = if ($r.Contains('TenantId')) { $r.TenantId } else { '' }
            $obj.RecordId = if ($r.RecordId) { $r.RecordId } else { [guid]::NewGuid().Guid }
            $obj.BuildCycleId = if ($r.BuildCycleId) { $r.BuildCycleId } else { '' }
            $obj.AutopilotDeviceId = if ($null -ne $r.AutopilotDeviceId) { [string]$r.AutopilotDeviceId } else { '' }
            $obj.ManagedDeviceId = if ($null -ne $r.ManagedDeviceId) { [string]$r.ManagedDeviceId } else { '' }
            $obj.AzureAdDeviceId = if ($null -ne $r.AzureAdDeviceId) { [string]$r.AzureAdDeviceId } else { '' }
            $obj.IntuneDeviceName = if ($null -ne $r.IntuneDeviceName) { [string]$r.IntuneDeviceName } else { '' }
            if ($r.Contains('IntuneInventory')) { $obj.IntuneInventory = ConvertTo-NormalisedValue -Value $r.IntuneInventory }
            $obj.Serial = $r.Serial
            $obj.EntraDeviceId = if ($null -ne $r.EntraDeviceId) { [string]$r.EntraDeviceId } else { '' }
            $obj.ConfigItem = $r.ConfigItem
            $obj.SiteCode = $r.SiteCode
            $obj.DeviceType = $r.DeviceType
            $obj.GroupTag = $r.GroupTag
            $obj.Status = if ($r.Status) { $r.Status } else { 'new' }
            $obj.Steps = ConvertTo-StepHashtable -Value $r.Steps
            $obj.StartedAt = ConvertTo-RecordDate -Value $r.StartedAt
            $obj.StartedBy = if ($r.StartedBy) { $r.StartedBy } else { '' }
            $obj.LastUpdatedAt = if ($r.LastUpdatedAt) { ConvertTo-RecordDate -Value $r.LastUpdatedAt } else { $obj.StartedAt }
            $obj.LastUpdatedBy = if ($r.LastUpdatedBy) { $r.LastUpdatedBy } else { $obj.StartedBy }
            $obj.CompletedAt = ConvertTo-RecordDate -Value $r.CompletedAt
            $obj.CompletedBy = if ($r.CompletedBy) { $r.CompletedBy } else { '' }
            $obj.DispatchConfirmed = if ($r.Contains('DispatchConfirmed')) { $r.DispatchConfirmed } else { $false }
            $obj.DispatchedAt = ConvertTo-RecordDate -Value $r.DispatchedAt
            if (-not $r.Contains('DispatchConfirmed') -and $obj.Status -eq 'completed' -and $obj.CompletedAt -ne [DateTime]::MinValue) {
                foreach ($snapshot in @($r.RecoveryHistory)) {
                    if ($snapshot.Stage -ne 'CompletionOverride') { continue }
                    $dispatchDate = ConvertTo-RecordDate -Value $snapshot.Timestamp
                    if ($dispatchDate -ne [DateTime]::MinValue -and $dispatchDate.ToUniversalTime() -eq $obj.CompletedAt.ToUniversalTime()) {
                        $obj.DispatchConfirmed = $true
                        $obj.DispatchedAt = $dispatchDate
                    }
                }
            }
            $obj.IsCompletionVerified = [bool]$r.IsCompletionVerified
            $obj.TechnicianUserPrincipalName = if ($r.TechnicianUserPrincipalName) { [string]$r.TechnicianUserPrincipalName } elseif ($r.TechnicianUser) { [string]$r.TechnicianUser } else { '' }
            $obj.FinalPrimaryUserId = if ($r.FinalPrimaryUserId) { [string]$r.FinalPrimaryUserId } else { '' }
            $obj.FinalPrimaryUserPrincipalName = if ($r.FinalPrimaryUserPrincipalName) { [string]$r.FinalPrimaryUserPrincipalName } elseif ($r.FinalPrimaryUser) { [string]$r.FinalPrimaryUser } else { '' }
            $obj.FinalPrimaryUserDisplayName = if ($r.FinalPrimaryUserDisplayName) { [string]$r.FinalPrimaryUserDisplayName } elseif ($r.FinalPrimaryUserName) { [string]$r.FinalPrimaryUserName } else { '' }
            $obj.RecoveryActive = [bool]$r.RecoveryActive
            $obj.RecoveryStartedAt = ConvertTo-RecordDate -Value $r.RecoveryStartedAt
            $obj.RecoveryReason = if ($r.RecoveryReason) { [string]$r.RecoveryReason } else { '' }
            $obj.RecoveryHistory = @()
            if ($r.RecoveryHistory) { $obj.RecoveryHistory = ConvertTo-NormalisedValue -Value $r.RecoveryHistory }
            if ($r.Contains('AttemptHistory')) { $obj.AttemptHistory = ConvertTo-NormalisedValue -Value $r.AttemptHistory }
            if ($r.Contains('SyncSubmissions') -and $null -ne $r.SyncSubmissions) {
                # Ledger entries are bound to their own record and carry text evidence only.
                # ConvertTo-NormalisedValue returns arrays whole (including empty ones); only a
                # lone legacy entry is wrapped. A plain variable assignment is used because
                # assigning an if-statement result would unroll an empty array to $null.
                $loadedLedger = ConvertTo-NormalisedValue -Value $r.SyncSubmissions
                if ($loadedLedger -isnot [array]) { $loadedLedger = @(, $loadedLedger) }
                $obj.SyncSubmissions = $loadedLedger
                foreach ($ledgerEntry in $obj.SyncSubmissions) {
                    if ($ledgerEntry -isnot [System.Collections.IDictionary] -or $ledgerEntry['State'] -notin @('Intent', 'Accepted') -or $ledgerEntry['RecordId'] -cne $obj.RecordId -or $ledgerEntry['Serial'] -cne $obj.Serial) { throw 'Saved SyncSubmissions entries must be Intent or Accepted evidence for their own record.' }
                    foreach ($ledgerField in $ledgerEntry.Keys) {
                        $ledgerValue = $ledgerEntry[$ledgerField]
                        if ($ledgerField -cnotin @('CycleKey', 'State', 'RecordedAt', 'RecordId', 'Serial', 'ManagedDeviceId', 'TenantId', 'SubmittedAt', 'IntentAt', 'Source', 'ResubmittedAfterUncertainIntent')) { throw 'Saved SyncSubmissions entries contain an unknown field.' }
                        if (($ledgerField -eq 'ResubmittedAfterUncertainIntent' -and $ledgerValue -isnot [bool]) -or ($ledgerField -ne 'ResubmittedAfterUncertainIntent' -and $ledgerValue -isnot [string])) { throw 'Saved SyncSubmissions entries contain an invalid value type.' }
                    }
                }
            }
            if ($r.Contains('ImportSubmissions') -and $null -ne $r.ImportSubmissions) {
                # IMPORT-RECEIPTS: hash-free import evidence bound to its own record. Field
                # values are checked fully by ConvertTo-AutopilotImportReceipt when read.
                $loadedImportLedger = ConvertTo-NormalisedValue -Value $r.ImportSubmissions
                if ($loadedImportLedger -isnot [array]) { $loadedImportLedger = @(, $loadedImportLedger) }
                $obj.ImportSubmissions = $loadedImportLedger
                foreach ($ledgerEntry in $obj.ImportSubmissions) {
                    if ($ledgerEntry -isnot [System.Collections.IDictionary] -or $ledgerEntry['State'] -notin @('Submitting', 'Accepted') -or $ledgerEntry['RecordId'] -cne $obj.RecordId -or $ledgerEntry['Serial'] -cne $obj.Serial) { throw 'Saved ImportSubmissions entries must be Submitting or Accepted evidence for their own record.' }
                    foreach ($ledgerField in $ledgerEntry.Keys) {
                        $ledgerValue = $ledgerEntry[$ledgerField]
                        if ($ledgerField -cnotin @('SchemaVersion', 'RecordId', 'TenantId', 'Serial', 'ImportId', 'AutopilotImportId', 'State', 'SubmittedAt', 'RecordedAt', 'Source')) { throw 'Saved ImportSubmissions entries contain an unknown field.' }
                        if (($ledgerField -eq 'SchemaVersion' -and $ledgerValue -isnot [int] -and $ledgerValue -isnot [long]) -or ($ledgerField -ne 'SchemaVersion' -and $ledgerValue -isnot [string])) { throw 'Saved ImportSubmissions entries contain an invalid value type.' }
                    }
                }
            }
            if ($r.Contains('ImagingSessionStarts')) { $obj.ImagingSessionStarts = @($r.ImagingSessionStarts | ForEach-Object { Get-Date -Date $_ -Format o }) }
            $records += , $obj
        }
        Assert-DeviceRecordIdentity -Records $records
        Assert-AttemptHistoryPreserved -Records $records
        return , $records
    }
    catch {
        Write-AutopilotExpressLog -Message ('Failed to load user data file: {0}' -f $_.Exception.Message) -Level 'ERROR'
        throw
    }
}

function Get-VerifiedSaveCopy {
    <#
    .SYNOPSIS
        Return this session's private copy of a file it saved, only while that file is unchanged.
    .DESCRIPTION
        Saves check history against the data already on disk. Parsing and validating the
        whole records file and all-time audit file again on every save was most of each
        save's time. After a successful save the writer keeps the exact text it wrote and
        a detached copy of the data. This returns that copy only when the file's current
        text is identical, character for character. Any difference (another tool, a manual
        edit, a sync conflict or a restore) returns nothing, so the caller does the full
        re-read. The history check itself always runs; only its source of "existing" data
        changes.
    .PARAMETER Path
        Full path of the records or audit file.
    .OUTPUTS
        Hashtable with Text and Value keys, or $null when there is no copy or the file differs.
    #>
    param([Parameter(Mandatory)][ValidateNotNullOrEmpty()][string]$Path)
    $cacheVariable = Get-Variable -Name LocalSaveCache -Scope Script -ErrorAction SilentlyContinue
    if ($null -eq $cacheVariable -or $cacheVariable.Value -isnot [hashtable] -or -not $cacheVariable.Value.ContainsKey($Path)) { return $null }
    if (-not (Test-Path -LiteralPath $Path)) { return $null }
    $entry = $cacheVariable.Value[$Path]
    [string]$currentText = Get-Content -LiteralPath $Path -Raw -ErrorAction Stop
    if ([string]::IsNullOrEmpty($currentText)) { $currentText = '' }
    if ($currentText -cne $entry.Text) { return $null }
    return $entry
}

function Write-UserDeviceRecords {
    <#
    .SYNOPSIS
        Persist staged records, audit and initialised bench under one checkpoint.
    .DESCRIPTION
        The recoverable writer verifies the checkpoint before any operational save.
        Every error propagates and retains checkpoint evidence until operator review.
        This detects interrupted local saves; it is not an atomic transaction, fsync,
        tenant-action replay mechanism or remote rollback.
    .PARAMETER Records
        Complete proposed record collection; staging never mutates caller objects.
    .OUTPUTS
        None. Validates and persists guarded record/audit proposals; failures remain fatal.
    #>
    param([Parameter(Mandatory)][System.Collections.IEnumerable]$Records)
    $saveTimer = [Diagnostics.Stopwatch]::StartNew()
    $saveSucceeded = $false
    $path = Get-UserDataFilePath
    $checkpointToken = $null
    try {
        Assert-LocalCheckpointState
        if ($Script:SessionFileNamesEnabled) {
            Initialize-SessionFileIndex
            $path = Get-UserDataFilePath
        }
        $serialisableRecords = @($Records | ForEach-Object { ConvertTo-PersistedDeviceRecord -Record $_ })
        # Use the private copy of the last save when the file is unchanged; otherwise re-read it.
        $savedCopy = Get-VerifiedSaveCopy -Path $path
        $existingRecords = if ($null -ne $savedCopy) { $savedCopy.Value } else { Get-UserDeviceRecords }
        Assert-AttemptHistoryPreserved -Records $serialisableRecords -ExistingRecords $existingRecords
        $json = if ($serialisableRecords.Count -gt 0) { $serialisableRecords | ConvertTo-Json -Depth 100 } else { '[]' }
        $auditJson = $null
        $auditEntries = $null
        if (-not $Script:Runtime.IsDemoMode) {
            $auditTimer = [Diagnostics.Stopwatch]::StartNew()
            $auditProposal = Get-MasterAuditProposal -Records $serialisableRecords -IncludeEntries
            $auditJson = $auditProposal.Json
            $auditEntries = $auditProposal.Entries
            Write-Verbose ('Master audit proposal: elapsed-ms={0:N2}.' -f $auditTimer.Elapsed.TotalMilliseconds)
        }
        $benchVariable = Get-Variable -Name BuildBench -Scope Script -ErrorAction SilentlyContinue
        $benchJson = if ($null -ne $benchVariable -and $null -ne $benchVariable.Value) { $benchVariable.Value | ConvertTo-Json -Depth 6 } else { $null }
        $checkpointPath = Get-LocalCheckpointPath
        $checkpointToken = [guid]::NewGuid().Guid
        $modeName = if ($Script:Runtime.IsDemoMode) { 'demo' } else { 'live' }
        $checkpoint = @{ SchemaVersion = 1; Token = $checkpointToken; Root = (Get-DataFolderPath); User = $env:USERNAME; Mode = $modeName; StartedAt = (Get-Date -Format o); RecordsJson = $json; AuditJson = $auditJson; BenchJson = $benchJson }
        Write-Verbose ('Checkpoint prepared: records={0}; elapsed-ms={1:N2}.' -f $serialisableRecords.Count, $saveTimer.Elapsed.TotalMilliseconds)
        Write-Utf8File -Path $checkpointPath -Content ($checkpoint | ConvertTo-Json -Depth 8)
        $Script:LocalCheckpointToken = $checkpointToken
        Write-Utf8File -Path $path -Content $json
        Write-AutopilotExpressLog -Message ('Saved {0} device record(s) to {1}' -f $serialisableRecords.Count, $path) -Level 'INFO'
        Update-MasterAuditLedger -Records $serialisableRecords -ProposedContent $auditJson
        if ($null -ne $benchJson) { Save-BuildBenchState -CheckpointToken $checkpointToken -ProposedContent $benchJson }
        Remove-Item -LiteralPath $checkpointPath -ErrorAction Stop
        # Every file is now saved and verified, so keep private copies for the next save's history check.
        # $serialisableRecords and the audit entries are detached copies nothing else references.
        $saveCopies = @{ $path = @{ Text = $json; Value = $serialisableRecords } }
        if ($null -ne $auditJson) { $saveCopies[(Get-MasterAuditFilePath)] = @{ Text = $auditJson; Value = $auditEntries } }
        $Script:LocalSaveCache = $saveCopies
        $saveSucceeded = $true
    }
    catch {
        # A failed save leaves the files uncertain, so the next save must fully re-read them.
        $Script:LocalSaveCache = @{}
        Write-AutopilotExpressLog -Message ('Failed to save user device records: {0}' -f $_.Exception.Message) -Level 'ERROR'
        throw
    }
    finally {
        if ($null -ne $checkpointToken) { $Script:LocalCheckpointToken = $null }
        # A lost console must not replace the save's own outcome.
        try { Write-Verbose ('Checkpoint save: succeeded={0}; elapsed-ms={1:N2}.' -f $saveSucceeded, $saveTimer.Elapsed.TotalMilliseconds) }
        catch [System.IO.IOException] { $null = $_ }
    }
}

# INPUT VALIDATION UTILITIES
#endregion
#region Console Input and Technician Navigation
function Read-ValidatedInput {
    <#
    .SYNOPSIS
        Read accessible input with an explicit displayed default and one prompt boundary gap.
    .PARAMETER Prompt
        Technician-facing prompt text; existing default behaviour is retained.
    .PARAMETER Default
        Value used when Enter is pressed.
    .PARAMETER Type
        String, integer or choice validation mode.
    .PARAMETER Choices
        Allowed values for choice mode, matched without case sensitivity.
    .PARAMETER AllowEmpty
        Permit empty text when the calling workflow explicitly supports it.
    .PARAMETER ServiceInventory
        Permit idle metadata polling at a navigation boundary, never during an action proposal.
    .OUTPUTS
        Validated response string; invalid input re-prompts without advancing workflow state.
    #>
    param(
        [Parameter(Mandatory)][string]$Prompt,
        [string]$Default,
        [ValidateSet('String', 'Int', 'Choice')][string]$Type = 'String',
        [string[]]$Choices,
        [switch]$AllowEmpty,
        [switch]$ServiceInventory
    )
    :inputValidation while ($true) {
        # Do not append colon here; Read-Host will add ':' automatically
        $renderPrompt = if ($Default) { ('{0} (default: {1})' -f $Prompt, $Default) } else { ('{0}' -f $Prompt) }
        Write-Host ''
        $inventorySession = Get-Variable -Name InventoryRecords -Scope Script -ErrorAction SilentlyContinue
        if ($ServiceInventory -and $inventorySession -and $null -ne $inventorySession.Value -and -not $Script:Runtime.IsDemoMode -and
            $Script:GraphSession.Connected -and -not $Script:GraphSession.RequiresReconnect) {
            $response = Read-DeviceInventoryInput -Prompt $renderPrompt -Records $inventorySession.Value
        }
        else { $response = Read-Host -Prompt $renderPrompt }
        if ([string]::IsNullOrWhiteSpace($response)) { $response = $Default }
        if (-not $response -and -not $AllowEmpty) { Write-Host 'Input cannot be empty.'; continue }
        switch ($Type) {
            'Int' {
                if ($response -notmatch '^-?[0-9]+$') { Write-Host 'Please enter a valid number.'; continue inputValidation }
            }
            'Choice' {
                if ($Choices -and -not ($Choices | ForEach-Object { $_.ToLower() } | Where-Object { $_ -eq $response.ToLower() })) { Write-Host ('Please choose one of: {0}' -f ($Choices -join ', ')); continue inputValidation }
            }
        }
        return $response
    }
}

function ConvertTo-OptionalInteger {
    <#
    .SYNOPSIS
        Parse an optional integer without evaluating PowerShell expressions.
    .PARAMETER Value
        Textual or numeric candidate supplied by a selection flow.
    .OUTPUTS
        Integer on successful conversion, otherwise null.
    #>
    param([string]$Value)

    if ([string]::IsNullOrWhiteSpace($Value) -or $Value -notmatch '^-?[0-9]+$') { return $null }
    try { return [int]$Value } catch { return $null }
}

function Get-ConfiguredSerialPattern {
    <#
    .SYNOPSIS
        Return the configured serial validation pattern or the compatibility default.
    .OUTPUTS
        Regular-expression string used by serial input validation; no device lookup.
    #>
    $pattern = [string]$Script:RuntimeConfig.scannerSerialNormalisation.serialPattern
    if ([string]::IsNullOrWhiteSpace($pattern)) { return '^[A-Za-z0-9-]{4,64}$' }
    return $pattern
}

function Get-ConfiguredScannerSerialRules {
    <#
    .SYNOPSIS
        Return non-null scanner normalisation rules from runtime configuration.
    .OUTPUTS
        Rule collection, empty when absent; no rule is executed here.
    #>
    return @($Script:RuntimeConfig.scannerSerialNormalisation.rules | Where-Object { $null -ne $_ })
}

function Get-UriQueryParameterValues {
    <#
    .SYNOPSIS
        Decode matching URI query values for configured scanner transformations.
    .PARAMETER Query
        Query text from the scanned URI; never executed or requested over the network.
    .PARAMETER Name
        Configured query parameter name to match.
    .OUTPUTS
        Matching decoded values in input order; does not infer a unique serial.
    #>
    param(
        [Parameter(Mandatory)][AllowEmptyString()][string]$Query,
        [Parameter(Mandatory)][string]$Name
    )

    $values = @()
    foreach ($pair in @($Query.TrimStart('?') -split '&')) {
        if ([string]::IsNullOrWhiteSpace($pair)) { continue }
        $parts = $pair -split '=', 2
        $key = [uri]::UnescapeDataString($parts[0].Replace('+', ' '))
        if ($key -ine $Name) { continue }
        $value = if ($parts.Count -gt 1) { [uri]::UnescapeDataString($parts[1].Replace('+', ' ')) } else { '' }
        $values += $value
    }
    return @($values)
}

function ConvertTo-NormalisedSerialInput {
    <#
    .SYNOPSIS
        Validate literal serial input or apply an explicitly configured scanner rule.
    .PARAMETER InputValue
        Raw technician/scanner text; control characters and invalid transformations are refused.
    .OUTPUTS
        Dictionary with Success, Serial, WasTransformed, RuleName and actionable Message.
        Does not query Graph or create device records.
    #>
    param([Parameter(Mandatory)][string]$InputValue)

    $rawValue = $InputValue.Trim()
    $serialPattern = Get-ConfiguredSerialPattern
    if ([string]::IsNullOrWhiteSpace($rawValue)) {
        return [ordered]@{ Success = $false; Serial = $null; WasTransformed = $false; RuleName = $null; Message = 'Serial input cannot be empty.' }
    }
    if ($rawValue -match $serialPattern) {
        return [ordered]@{ Success = $true; Serial = $rawValue.ToUpperInvariant(); WasTransformed = $false; RuleName = $null; Message = '' }
    }

    if ($rawValue -notmatch '^(?<scheme>https?)://(?<host>[^/?#:]+)(?::[0-9]+)?(?<path>/[^?#]*)?(?:\?(?<query>[^#]*))?/?$') {
        return [ordered]@{ Success = $false; Serial = $null; WasTransformed = $false; RuleName = $null; Message = 'Input is neither a valid serial nor a supported scanner URL.' }
    }
    $urlHost = $Matches['host']
    $urlPath = if ($Matches['path']) { $Matches['path'] } else { '/' }
    $urlQuery = $Matches['query']

    foreach ($rule in Get-ConfiguredScannerSerialRules) {
        $hostPattern = [string]$rule.hostPattern
        $pathPattern = [string]$rule.pathPattern
        $queryParameter = [string]$rule.queryParameter
        if ([string]::IsNullOrWhiteSpace($hostPattern) -or [string]::IsNullOrWhiteSpace($pathPattern) -or [string]::IsNullOrWhiteSpace($queryParameter)) { continue }
        if ($urlHost -notmatch $hostPattern -or $urlPath -notmatch $pathPattern) { continue }

        $values = @(Get-UriQueryParameterValues -Query $urlQuery -Name $queryParameter)
        if ($values.Count -ne 1 -or [string]::IsNullOrWhiteSpace([string]$values[0])) {
            return [ordered]@{ Success = $false; Serial = $null; WasTransformed = $true; RuleName = [string]$rule.name; Message = ('Scanner URL matched {0}, but query parameter {1} was missing or ambiguous.' -f $rule.name, $queryParameter) }
        }

        $candidateSerial = ([string]$values[0]).Trim().ToUpperInvariant()
        $valuePattern = if ($rule.valuePattern) { [string]$rule.valuePattern } else { $serialPattern }
        if ($candidateSerial -notmatch $valuePattern -or $candidateSerial -notmatch $serialPattern) {
            return [ordered]@{ Success = $false; Serial = $null; WasTransformed = $true; RuleName = [string]$rule.name; Message = ('Scanner URL matched {0}, but the extracted value is not a valid serial.' -f $rule.name) }
        }
        return [ordered]@{ Success = $true; Serial = $candidateSerial; WasTransformed = $true; RuleName = [string]$rule.name; Message = '' }
    }

    return [ordered]@{ Success = $false; Serial = $null; WasTransformed = $false; RuleName = $null; Message = 'Scanner URL does not match a configured serial-extraction rule.' }
}

function Read-NormalisedSerialInput {
    <#
    .SYNOPSIS
        Read and validate a serial while preserving correction and cancellation behaviour.
    .PARAMETER Prompt
        Accessible serial prompt text.
    .PARAMETER Default
        Previously entered serial offered during correction.
    .PARAMETER AllowCancel
        Permit the calling workflow's explicit cancellation input.
    .OUTPUTS
        Normalised serial, or null on allowed cancellation; invalid input re-prompts.
    #>
    param([Parameter(Mandatory)][string]$Prompt, [string]$Default, [switch]$AllowCancel)

    while ($true) {
        $rawValue = Read-ValidatedInput -Prompt $Prompt -Default $Default
        if ($AllowCancel -and $rawValue -eq '0') { return $null }
        $result = ConvertTo-NormalisedSerialInput -InputValue $rawValue
        if (-not $result.Success) {
            Write-Host ('Unable to determine a valid serial: {0}' -f $result.Message)
            continue
        }
        if ($result.WasTransformed) {
            Write-Host ('Scanner rule "{0}" extracted serial: {1}' -f $result.RuleName, $result.Serial)
            $confirmed = Read-ValidatedInput -Prompt 'Use this extracted serial? [Y] Yes [N] No' -Default 'Y' -Type 'Choice' -Choices @('Y', 'N')
            if ($confirmed.ToUpper() -ne 'Y') { continue }
        }
        return $result.Serial
    }
}

function Select-Site {
    <#
    .SYNOPSIS
        Select a configured site while retaining the current site as the default.
    .PARAMETER CurrentSiteCode
        Current site code offered to the technician.
    .OUTPUTS
        Configured site code; no tenant or persisted device state is changed here.
    #>
    param([string]$CurrentSiteCode)
    Show-ScriptScreen -Title 'Select Site'
    Write-Host 'Select site:'
    $defaultSiteIndex = 0
    for ($i = 0; $i -lt $Script:Sites.Count; $i++) {
        $s = $Script:Sites[$i]
        if ($s.Code -eq $CurrentSiteCode) { $defaultSiteIndex = $i }
        $marker = if ($s.Code -eq $CurrentSiteCode) { '*' } else { ' ' }
        Write-Host ('{0} [{1}] {2} {3}' -f ($i + 1), $s.Code, $s.Name, $marker)
    }
    Write-Host ''
    Write-Host '0. Return without changing site'
    while ($true) {
        $choice = Read-ValidatedInput -Prompt 'Enter number of site (0 returns)' -Type 'Int' -Default ($defaultSiteIndex + 1)
        if ($choice -eq '0') { return $CurrentSiteCode }
        $index = (ConvertTo-OptionalInteger -Value $choice) - 1
        if ($index -lt 0 -or $index -ge $Script:Sites.Count) { Write-Host ''; Write-Host 'Invalid site selection. Choose a displayed number or 0.'; continue }
        return $Script:Sites[$index].Code
    }
}

function Get-ConsoleTextWidth {
    <#
    .SYNOPSIS
        Obtain a usable text width without requiring a console RawUI implementation.
    .OUTPUTS
        Width in columns, with a deterministic fallback for non-console hosts.
    #>
    param()
    try { if ($Host.UI.RawUI.WindowSize.Width -gt 2) { return $Host.UI.RawUI.WindowSize.Width - 1 } }
    catch { return 118 }
    return 118
}

function Get-ScreenFeedbackLines {
    <#
    .SYNOPSIS
        Wrap complete events at the current width, newest event first.
    .PARAMETER State
        Transient events, each owning its original context and text.
    .OUTPUTS
        Display lines in natural order within each event; no evidence changes.
    #>
    param([Parameter(Mandatory)][System.Collections.IDictionary]$State)
    $width = Get-ConsoleTextWidth
    $lines = @()
    foreach ($feedbackEvent in $State.Events) {
        $context = if ($feedbackEvent.Contains('RenderedContext')) { $feedbackEvent.RenderedContext } else { $feedbackEvent.Context }
        $text = if ($context -and -not $feedbackEvent.ContextIncluded) { '{0}: {1}' -f $context, $feedbackEvent.Text } else { [string]$feedbackEvent.Text }
        if ($State.Compact) {
            $summary = @(([string]$feedbackEvent.Text) -split '\r?\n' | Where-Object { -not [string]::IsNullOrWhiteSpace($_) } | Select-Object -First 1) -join ''
            if ($context -and -not $feedbackEvent.ContextIncluded) {
                $contextWidth = [Math]::Max(1, [int]($width * 0.55))
                if ($context.Length -gt $contextWidth -and $text.Length -gt $width) { $context = $context.Substring(0, [Math]::Max(1, $contextWidth - 3)) + '...' }
                $summary = '{0}: {1}' -f $context, $summary
            }
            $summary = $summary -replace '\s+', ' '
            if ($summary.Length -gt $width) { $summary = $summary.Substring(0, [Math]::Max(1, $width - 3)) + '...' }
            $lines += $summary
            continue
        }
        foreach ($rawLine in @($text -split '\r?\n')) {
            $line = $rawLine.Trim()
            while ($line.Length -gt $width) {
                $length = $line.LastIndexOf(' ', $width)
                if ($length -le 0) { $length = $width }
                $lines += $line.Substring(0, $length)
                $line = $line.Substring($length).TrimStart()
            }
            if ($line) { $lines += $line }
        }
    }
    return , $lines
}

function Add-ScreenFeedback {
    <#
    .SYNOPSIS
        Retain five complete contextual events, not five rendered lines.
    .PARAMETER State
        Screen-owned dictionary, never persisted as workflow evidence.
    .PARAMETER Text
        Each string is one complete event; internal newlines stay ordered.
    .PARAMETER Context
        Position, serial, CI and action captured when the event occurred.
    .PARAMETER ContextIncluded
        The generated event already includes its identity; retain context without printing it twice.
    .PARAMETER RenderedContext
        Exact context already captured in host output, used only to avoid duplicate identity prefixes.
    .OUTPUTS
        None. Updates bounded screen feedback only; never durable workflow evidence.
    #>
    param(
        [Parameter(Mandatory)][System.Collections.IDictionary]$State,
        [AllowEmptyCollection()][string[]]$Text = @(),
        [string]$Context = '',
        [AllowEmptyString()][string]$RenderedContext,
        [switch]$ContextIncluded
    )
    if (-not $State.Contains('Events')) { $State['Events'] = @() }
    foreach ($message in $Text) {
        if ([string]::IsNullOrWhiteSpace($message)) { continue }
        $feedbackEvent = @{ Text = $message; Context = $Context; ContextIncluded = [bool]$ContextIncluded; Timestamp = Get-Date -Format o }
        if ($PSBoundParameters.ContainsKey('RenderedContext')) { $feedbackEvent.RenderedContext = $RenderedContext }
        $State.Events = @(@($feedbackEvent) + @($State.Events) | Select-Object -First 5)
    }
    $State['Lines'] = Get-ScreenFeedbackLines -State $State
}

function Get-MainMenuDefinition {
    <#
    .SYNOPSIS
        Define each navigation level's keys, labels and stable actions together.
    .PARAMETER Menu
        Main or one of the four caller-owned submenus. Zero is handled by the renderer.
    .OUTPUTS
        Menu entries used for both rendering and dispatch; no action is executed.
    #>
    param([ValidateSet('Main', 'Devices', 'Settings', 'Data', 'Information')][string]$Menu = 'Main')
    switch ($Menu) {
        'Main' {
            @(
                @{ Key = '1'; Action = 'Bench'; Label = 'Prepare and manage devices using Build Bench view' }
                @{ Key = '2'; Action = 'Devices'; Label = 'Prepare and manage devices using menu commands' }
                @{ Key = '3'; Action = 'Statistics'; Label = 'My stats' }
                @{ Key = '4'; Action = 'Settings'; Label = 'Session and script settings' }
                @{ Key = '5'; Action = 'Data'; Label = 'Data settings' }
                @{ Key = '6'; Action = 'Information'; Label = 'Script information' }
            )
        }
        'Devices' {
            @(
                @{ Key = '1'; Action = 'NewDevice'; Label = 'Start work on a new device' }
                @{ Key = '2'; Action = 'TrackedDevice'; Label = 'Continue work on a current device' }
                @{ Key = '3'; Action = 'DeviceList'; Label = 'Show current device list' }
                @{ Key = '4'; Action = 'Maintain'; Label = 'Maintain current device list' }
                @{ Key = '5'; Action = 'Outstanding'; Label = 'Show outstanding work for a device' }
                @{ Key = '6'; Action = 'DeviceActions'; Label = 'Device actions: quick remediations, status and Intune link' }
            )
        }
        'Settings' {
            @(
                @{ Key = '1'; Action = 'Site'; Label = 'Change current site' }
                @{ Key = '2'; Action = 'DeviceType'; Label = 'Change default device type' }
                @{ Key = '3'; Action = 'WorkPattern'; Label = 'View my default work pattern and hours' }
                @{ Key = '4'; Action = 'WorkPatternEdit'; Label = 'Edit my default work pattern and hours' }
                @{ Key = '5'; Action = 'RemediationSettings'; Label = 'Choose my quick-run device remediations' }
                @{ Key = '6'; Action = 'DocumentSettings'; Label = 'Document output settings and document-only retries' }
                @{ Key = '9'; Action = 'GraphReconnect'; Label = 'Reconnect to Microsoft Graph (no workflow replay)' }
            )
        }
        'Data' {
            @(
                @{ Key = '1'; Action = 'LogFolder'; Label = 'Open script log folder in Windows Explorer' }
                @{ Key = '2'; Action = 'ArchiveSession'; Label = 'Archive saved session and start fresh' }
                @{ Key = '3'; Action = 'SessionReports'; Label = 'Export current session report (CSV or HTML)' }
                @{ Key = '4'; Action = 'RecoveryEvidence'; Label = 'Recovery backup size report (organise older backups; nothing is deleted)' }
                                @{ Key = '5'; Action = 'IntuneDetails'; Label = 'Update device details from Intune (current and archived sessions; missing details only)' }
                            )
        }
        'Information' {
            @(
                @{ Key = '1'; Action = 'About'; Label = 'About this script' }
                @{ Key = '2'; Action = 'Steps'; Label = 'Show script steps list' }
                @{ Key = '3'; Action = 'Documentation'; Label = 'Show script basic documentation' }
                @{ Key = '4'; Action = 'CommandLine'; Label = 'Show script command-line flags' }
                @{ Key = '8'; Action = 'Enhancements'; Label = 'View future enhancements list' }
            )
        }
    }
}

function Get-NavigationMenuTitle {
    <#
    .SYNOPSIS
        Resolve caller-owned navigation state to a consistent screen and return label.
    .PARAMETER Menu
        Empty or unknown legacy state resolves to Main Menu without changing navigation.
    .OUTPUTS
        Plain display title; no workflow or storage changes.
    #>
    param([string]$Menu = $Script:NavigationMenu)
    switch ($Menu) {
        'Devices' { 'Device Commands' }
        'Settings' { 'Session and Script Settings' }
        'Data' { 'Data Settings' }
        'Information' { 'Script Information' }
        default { 'Main Menu' }
    }
}

function Show-DiagnosticLogFolder {
    <#
    .SYNOPSIS
        Open the actual current transcript directory without guessing its storage root.
    .OUTPUTS
        Accessible path and an actionable warning if Explorer cannot be opened.
    #>
    if ([string]::IsNullOrWhiteSpace($Script:DiagnosticLogPath)) { Write-Warning 'No diagnostic log path is available for this session.'; return }
    $folder = Split-Path -Parent $Script:DiagnosticLogPath
    Write-Host ('Diagnostic log folder: {0}' -f $folder)
    try {
        if (-not (Test-Path -LiteralPath $folder -PathType Container)) { throw 'The diagnostic directory is unavailable.' }
        Start-Process -FilePath 'explorer.exe' -ArgumentList ('"{0}"' -f $folder) -ErrorAction Stop | Out-Null
    }
    catch { Write-Warning ('Could not open the diagnostic folder. Open the displayed path manually. Error type: {0}' -f $_.Exception.GetType().FullName) }
}

function Show-SessionInformation {
    <#
    .SYNOPSIS
        Show read-only working hours, basic documentation or actual entry-point flags.
    .PARAMETER View
        Information to page. Work-pattern editing and operational recovery are never executed here.
    .OUTPUTS
        Host pages only; returns to the caller without changing saved evidence.
    #>
    param([Parameter(Mandatory)][ValidateSet('WorkPattern', 'Documentation', 'CommandLine')][string]$View)
    $title = 'Basic Documentation'
    $lines = @()
    switch ($View) {
        'WorkPattern' {
            $title = 'My Default Work Pattern and Hours'
            $lines = @(
                ('Technician: {0}' -f $env:USERNAME)
                'Default: Monday-Friday, 08:30-17:30; Saturday and Sunday are non-working days.'
                ('Time zone: {0} (this computer)' -f [TimeZoneInfo]::Local.DisplayName)
                'Statistics exclude idle nights and weekends unless recorded activity establishes exceptional work.'
                'After the last late action, time pauses until the next recorded script load or subsequent-date action.'
                'Original timestamps are retained. Historical sessions use available actions, not invented loads.'
                'Sick, RDO and WFH dates have no planned imaging hours. Recorded events are never deleted.'
                'Past hours are locked; only Sick/RDO/WFH markings may be added for an earlier date.'
            )
            $lines += @(Get-ImagingWorkPatternLines -WorkPattern $Script:ImagingWorkPattern)
        }
        'Documentation' {
            $lines = @(
                'Autopilot Express - technician device preparation and recorded workflow evidence.'
                'Build Bench manages positions, induction, workflow progress and dispatch.'
                'Device Commands provides the same guarded workflows without the bench view.'
                'My Stats reports dispatched builds using recorded working-time evidence.'
                'Settings changes apply to this session; site/type choices do not retag existing devices.'
                'Data Settings opens the active diagnostic folder or explicitly archives the current session.'
                'Use 0 or Enter to return to the caller. Only 0 on Main Menu exits the script.'
                'Demo simulates tenant actions. Live requires approved access, identity checks and physical acceptance.'
                'Submitted is not Verified. Accepted writes are not automatically replayed.'
                'Settings includes an effective-dated work-pattern editor and non-imaging-day markings.'
                'Shared storage remains unavailable.'
                ('Operator guide: {0}' -f (Get-AutopilotExpressDefinitionPath -FileName 'README.md'))
                'About this Script can open the local operator guide in Notepad.'
            )
        }
        'CommandLine' {
            $title = 'Script Command-Line Flags'
            $descriptions = @{
                Mode                   = '-Mode <Demo|Live>: choose the session mode; omitted mode is selected interactively.'
                AuthMode               = '-AuthMode <Browser|DeviceCode>: session-only sign-in override; does not rewrite configuration.'
                MigrateWorkflowIds     = '-MigrateWorkflowIds: offline workflow-evidence migration rehearsal; no Graph sign-in.'
                ApplyWorkflowMigration = '-ApplyWorkflowMigration: apply with -MigrateWorkflowIds only after separate approval and safety checks.'
                SessionLockAction      = '-SessionLockAction <Inspect|Recover>: inspect or explicitly recover a stopped local reservation.'
                SessionLockPath        = '-SessionLockPath <path>: reservation path for the selected inspection/recovery action.'
                ConfirmStopped         = '-ConfirmStopped: explicit stopped-session acknowledgement; never bypasses ownership or storage guards.'
                CheckpointAction       = '-CheckpointAction <Inspect|Resolve>: check, or back up and resolve, a save checkpoint left by a crash; no sign-in.'
                CheckpointPath         = '-CheckpointPath <path>: checkpoint file named in the startup error.'
            }
            $lines = @('Example: .\autopilot-express.ps1 -Mode Demo', '')
            foreach ($name in $Script:EntryPointParameterNames) {
                if ($descriptions.ContainsKey($name)) { $lines += $descriptions[$name] }
                else { $lines += ('-{0}: see Get-Help for the entry-point parameter contract.' -f $name) }
            }
            $lines += @('', 'Common PowerShell parameters include -Verbose, -Debug and -ErrorAction.',
                'These descriptions do not execute commands or authorise recovery, migration or tenant operations.',
                'Offline evidence conversion requires PowerShell 7.5 or later to preserve date strings.')
        }
    }
    [void](Read-PagedInformation -Title $title -Lines $lines)
}

function Show-CurrentDeviceList {
    <#
    .SYNOPSIS
        Page every current-session record without selecting or changing a workflow.
    .PARAMETER Records
        Current-session container, including completed and removed records.
    .OUTPUTS
        Sorted host text with serial, configuration item, site, type and status.
    #>
    param([Parameter(Mandatory)][hashtable]$Records)
    $lines = @($Records.Value | Where-Object { $null -ne $_ } | Sort-Object { [string]$_.Serial } | ForEach-Object {
            'Serial={0} | CI={1} | Site={2} | Type={3} | Status={4}' -f $_.Serial, $_.ConfigItem, $_.SiteCode, $_.DeviceType, $_.Status
        })
    if (-not $lines.Count) { $lines = @('No devices in the current session.') }
    [void](Read-PagedInformation -Title 'Current Device List' -Lines $lines)
}

function Show-MainMenu {
    <#
    .SYNOPSIS
        Render the shared main menu and resolve a validated selection to its action.
    .PARAMETER CurrentSiteCode
        Selected site included in the current-session display.
    .PARAMETER Menu
        Navigation level to render; the outer dispatcher owns transitions and caller return state.
    .OUTPUTS
        Internal menu action, including Exit; the outer loop owns navigation and execution.
    #>
    param(
        [string]$CurrentSiteCode,
        [ValidateSet('Main', 'Devices', 'Settings', 'Data', 'Information')][string]$Menu = 'Main'
    )
    Show-ScriptScreen -Title (Get-NavigationMenuTitle -Menu $Menu)
    $siteObj = $Script:Sites | Where-Object { $_.Code -eq $CurrentSiteCode }
    $siteDisplay = if ($siteObj) { ('{0} - {1}' -f $siteObj.Code, $siteObj.Name) } else { 'Not Set' }
    $graphSessionDisplay = if ($Script:GraphSession.Connected) { $Script:GraphSession.Account } else { 'Not Connected' }
    if ($Script:GraphSession.RequiresReconnect) { $graphSessionDisplay += ' (reconnect required)' }
    Write-Host ('Current Site: {0} | Graph Session: {1}' -f $siteDisplay, $graphSessionDisplay)
    Write-Host ''
    $entries = @(Get-MainMenuDefinition -Menu $Menu)
    foreach ($entry in $entries) {
        Write-Host ('{0}. {1}' -f $entry.Key, $entry.Label)
    }
    $returnLabel = if ($Menu -eq 'Main') { '0. Exit script' } else { '0. Return to Main Menu' }
    Write-Host $returnLabel
    $choice = Read-ValidatedInput -Prompt 'Choose an option' -Default '0' -Type Choice -Choices (@('0') + @($entries.Key)) -ServiceInventory
    Write-Host ''
    if ($choice -eq '0') { if ($Menu -eq 'Main') { return 'Exit' }; return 'Main' }
    return ($entries | Where-Object { $_.Key -eq $choice }).Action
}

# DEVICE WORKFLOW & STATUS MENUS
function Read-NewDeviceIdentityField {
    <#
    .SYNOPSIS
        Validate one new-device identifier before confirmation, retaining correction defaults.
    .PARAMETER Field
        Serial uses configured scanner rules; CI remains a textual identifier, not an invented numeric schema.
    .OUTPUTS
        Valid trimmed identifier, or null on explicit cancellation. Existing records are never modified.
    .PARAMETER Records
        Current record container used for early serial/configuration-item conflict checks.
    .PARAMETER Default
        Previously entered value retained during the correction loop.
    .PARAMETER AllowExistingSerial
        Route an existing serial to explicit lifecycle selection instead of creating a duplicate.
    #>
    param(
        [Parameter(Mandatory)][ValidateSet('Serial', 'ConfigItem')][string]$Field,
        [Parameter(Mandatory)][hashtable]$Records,
        [string]$Default,
        [switch]$AllowExistingSerial
    )
    while ($true) {
        $prompt = 'Enter {0} ([0] Cancel)' -f $Script:Config.Nomenclature[$Field]
        $value = if ($Field -eq 'Serial') { Read-NormalisedSerialInput -Prompt $prompt -Default $Default -AllowCancel } else { Read-ValidatedInput -Prompt $prompt -Default $Default }
        if ($null -eq $value -or $value -eq '0') { return $null }
        $value = $value.Trim()
        if (-not $value -or $value -match '[\x00-\x1F\x7F]') { Write-Host 'Enter a non-empty identifier without control characters.'; continue }
        $conflict = $null
        foreach ($record in @($Records.Value)) {
            $existingSerial = ([string]$record.Serial).Trim()
            $existingCI = ([string]$record.ConfigItem).Trim()
            if ($Field -eq 'Serial' -and $AllowExistingSerial -and $value -eq $existingSerial) { return $value }
            if ($Field -eq 'Serial' -and ($value -eq $existingSerial -or ($record.Status -ne 'removed' -and $value -eq $existingCI))) {
                $conflict = 'Serial {0} already identifies an existing workflow. Correct it or cancel to resume that device.' -f $value
                break
            }
            if ($Field -eq 'ConfigItem' -and ($value -eq $existingSerial -or ($record.Status -ne 'removed' -and $value -eq $existingCI))) {
                $conflict = 'Configuration Item {0} conflicts with an existing workflow. Enter the correct CI or 0 to cancel.' -f $value
                break
            }
        }
        if ($conflict) { Write-Host ''; Write-Host $conflict; $Default = $value; continue }
        return $value
    }
}

function Invoke-ExistingDeviceLifecycle {
    <#
    .SYNOPSIS
        Restore a removed workflow or start a fresh cycle without erasing prior evidence.
    .PARAMETER Records
        Owning session collection; detached changes are published only after guarded persistence.
    .PARAMETER Device
        Unique selected record. Existing tenant ownership and attempt identities remain protected.
    .PARAMETER Action
        Restore retains progress; Restart snapshots the old cycle and resets only current progress.
    .PARAMETER Position
        Optional empty bench position saved in the same checkpoint; zero leaves placement unchanged.
    .OUTPUTS
        Changed and Summary dictionary. No Graph request, remote rollback or automatic replay occurs.
    #>
    param([Parameter(Mandatory)][hashtable]$Records, [Parameter(Mandatory)][System.Collections.IDictionary]$Device,
        [Parameter(Mandatory)][ValidateSet('Restore', 'Restart')][string]$Action, [int]$Position = 0)
    Assert-DeviceRecordIdentity -Records $Records.Value
    if (@($Records.Value) -notcontains $Device) { throw 'Selected workflow is not in this session.' }
    if ($Action -eq 'Restore' -and ($Device.Status -ne 'removed' -or $Device.DispatchConfirmed)) { return @{ Changed = $false; Summary = 'Restore requires a removed, undispatched record; use Restart for a previously dispatched build.' } }
    if ($Action -eq 'Restart') {
        if ($Device.RecoveryActive) { return @{ Changed = $false; Summary = 'Finish or review active recovery before starting another build cycle.' } }
        foreach ($step in $Device.Steps.Values) {
            $accepted = @($step.Data.Keys | Where-Object { $_ -match '(Submitted|Accepted|OutcomeUnknown|DurableGap)' -and $step.Data[$_] -eq $true }).Count -gt 0
            if ($step.CompletionState -eq 'Submitted' -or ($accepted -and $step.CompletionState -notin @('Verified', 'TechnicianConfirmed', 'Simulated'))) {
                return @{ Changed = $false; Summary = 'Restart refused: a remote submission or unknown outcome needs review. Resume and reconcile it first; nothing was replayed.' }
            }
        }
    }
    $tenantId = [string]$Device.TenantId
    if (-not $Script:Runtime.IsDemoMode) {
        try {
            if ($tenantId -or $Action -eq 'Restore') { $tenantId = Get-LiveTenantBinding -Device $Device -AllowUnbound }
            else {
                $tenantId = Get-LiveTenantBinding
                $lookupIds = @((Get-EnabledManifestSteps | Where-Object { $_.ActionName -eq 'ResolveAutopilotDevice' }).Id)
                if ($Device.RecoveryHistory.Count -or $Device.DispatchConfirmed -or $Device.CompletedBy) { throw 'Unbound historical evidence requires deliberate tenant migration.' }
                foreach ($field in @('AutopilotDeviceId', 'ManagedDeviceId', 'AzureAdDeviceId', 'EntraDeviceId', 'FinalPrimaryUserId', 'TechnicianUserPrincipalName', 'FinalPrimaryUserPrincipalName')) { if ($Device[$field]) { throw 'Unbound cached identities require deliberate tenant migration.' } }
                foreach ($stepId in $Device.Steps.Keys) { if ($stepId -notin $lookupIds -or $Device.Steps[$stepId].CompletionState -notin @('Failed', 'Blocked') -or $Device.Steps[$stepId].Data.Count) { throw 'Only an unbound failed-discovery-only record can explicitly start a fresh cycle.' } }
                foreach ($attempt in $Device.AttemptHistory) { if ($attempt.TenantId -or $attempt.StepId -notin $lookupIds -or $attempt.Result.Success -or $attempt.Result.CompletionState -notin @('Failed', 'Blocked') -or $attempt.Result.Data.Count) { throw 'Unbound historical attempts require deliberate tenant migration.' } }
            }
        }
        catch { return @{ Changed = $false; Summary = $_.Exception.Message } }
    }
    Write-Host ('{0}: Serial={1} | CI={2} | current status={3} | tenant={4}' -f $Action, $Device.Serial, $Device.ConfigItem, $Device.Status, $tenantId)
    Write-Host 'Prior evidence is retained. No cloud state is reversed. Restart resets current-cycle statistics until a new dispatch.'
    $reason = Read-ValidatedInput -Prompt 'Reason ([0] Cancel)' -Default '0'
    if ($reason -eq '0') { return @{ Changed = $false; Summary = 'Cancelled; original workflow retained.' } }
    $confirmed = Read-ValidatedInput -Prompt ('Confirm {0}? [Y] Yes [N] No' -f $Action) -Default 'N' -Type Choice -Choices @('Y', 'N')
    if ($confirmed -ine 'Y') { return @{ Changed = $false; Summary = 'Cancelled; original workflow retained.' } }
    $proposedRecords = ConvertTo-NormalisedValue -Value @($Records.Value)
    $proposal = $proposedRecords | Where-Object { $_.Serial -eq $Device.Serial } | Select-Object -First 1
    $snapshot = ConvertTo-NormalisedValue -Value $Device
    $snapshot.Remove('RecoveryHistory')
    $now = Get-Date
    $history = @($proposal.RecoveryHistory) + , @{ Stage = ('Device{0}' -f $Action); Actor = $env:USERNAME; Timestamp = (Get-Date -Date $now -Format o); Reason = $reason; PreviousRecord = $snapshot }
    if ($Action -eq 'Restart') {
        $fresh = New-EmptyDeviceRecord
        foreach ($field in @('RecordId', 'WorkflowIdVersion', 'Serial', 'ConfigItem', 'SiteCode', 'DeviceType', 'GroupTag', 'AttemptHistory')) { $fresh[$field] = $proposal[$field] }
        if ($proposal.Contains('SyncSubmissions')) { $fresh.SyncSubmissions = $proposal.SyncSubmissions }
        if ($proposal.Contains('ImportSubmissions')) { $fresh.ImportSubmissions = $proposal.ImportSubmissions }
        $fresh.TenantId = $tenantId
        $fresh.BuildCycleId = [guid]::NewGuid().Guid
        $fresh.StartedAt = $now
        $fresh.ImagingSessionStarts = @(Get-Date -Date $now -Format o)
        $fresh.StartedBy = $env:USERNAME
        foreach ($field in @($fresh.Keys)) { $proposal[$field] = $fresh[$field] }
    }
    else { $proposal.Status = 'in-progress' }
    $proposal.RecoveryHistory = $history
    $proposal.LastUpdatedAt = $now
    $proposal.LastUpdatedBy = $env:USERNAME
    Assert-DeviceRecordIdentity -Records $proposedRecords
    $originalBench = $Script:BuildBench
    $saved = $false
    try {
        if ($Position -gt 0) {
            $bench = ConvertTo-NormalisedValue -Value $originalBench
            $slot = @($bench.Positions | Where-Object { $_.Index -eq $Position })
            if ($slot.Count -ne 1 -or $slot[0].Serial -or @($bench.Positions | Where-Object { $_.Serial -eq $Device.Serial }).Count) { throw 'Choose an empty bench position; the device must not already occupy another position.' }
            $slot[0].Serial = $Device.Serial; $slot[0].ConfigItem = $Device.ConfigItem
            Assert-BenchPositionIdentity -Positions $bench.Positions
            $Script:BuildBench = $bench
        }
        Write-UserDeviceRecords -Records $proposedRecords
        $saved = $true
    }
    finally { if (-not $saved) { $Script:BuildBench = $originalBench } }
    foreach ($field in @($proposal.Keys)) { $Device[$field] = $proposal[$field] }
    return @{ Changed = $true; Summary = '{0} saved; original attempts and prior-cycle evidence retained. No remote action was executed.' -f $Action }
}

function Select-ExistingDeviceWorkflowAction {
    <#
    .SYNOPSIS
        Offer explicit resume, restore or restart without creating a duplicate serial.
    .PARAMETER Records
        Current session records owning the selected device.
    .PARAMETER Device
        Existing workflow selected by number or exact serial.
    .PARAMETER Position
        Empty bench position, or zero for standalone use.
    .OUTPUTS
        Boolean indicating successful selection; cancellation defaults to zero.
    #>
    param([Parameter(Mandatory)][hashtable]$Records, [Parameter(Mandatory)][System.Collections.IDictionary]$Device, [int]$Position = 0)
    Write-Host ('Existing Serial={0} | CI={1} | Status={2}' -f $Device.Serial, $Device.ConfigItem, $Device.Status)
    $choices = @('0', 'RESTART')
    if ($Device.Status -in @('new', 'in-progress')) { Write-Host 'R. Resume current progress'; $choices += 'R' }
    if ($Device.Status -eq 'removed' -and -not $Device.DispatchConfirmed) { Write-Host 'RESTORE. Restore removed workflow with its progress'; $choices += 'RESTORE' }
    Write-Host 'RESTART. Start another build cycle; retain prior evidence'
    Write-Host '0. Cancel'
    $choice = Read-ValidatedInput -Prompt 'Existing device action' -Default '0' -Type Choice -Choices $choices
    if ($choice -eq '0') { return $false }
    if ($choice -eq 'R') {
        if ($Position -gt 0) { Add-DeviceToBenchPosition -Position $Position -Serial $Device.Serial -ConfigItem $Device.ConfigItem -SiteCode $Device.SiteCode -DeviceType $Device.DeviceType -Records $Records }
        Write-Host ('Existing workflow retained: Serial={0} | CI={1}. No progress or induction timestamp was reset.' -f $Device.Serial, $Device.ConfigItem)
        return $true
    }
    $result = Invoke-ExistingDeviceLifecycle -Records $Records -Device $Device -Action $choice -Position $Position
    Write-Host $result.Summary
    return [bool]$result.Changed
}

function Get-OffBenchDeviceRecord {
    <#
    .SYNOPSIS
        List eligible existing records that are not already occupying bench positions.
    .PARAMETER Records
        Current record container; incomplete identities and occupied bench records are excluded.
    .OUTPUTS
        Serial-sorted record array. Existing history and state are not reset.
    #>
    param([Parameter(Mandatory)][hashtable]$Records)
    $occupiedSerials = @($Script:BuildBench.Positions | Where-Object { $_.Serial } | ForEach-Object { $_.Serial })
    return , @($Records.Value | Where-Object {
            $_.Status -in @('new', 'in-progress', 'removed', 'completed') -and $_.Serial -and $_.ConfigItem -and $_.SiteCode -and $_.DeviceType -and $_.Serial -notin $occupiedSerials
        } | Sort-Object { $_.Serial })
}

function Select-EmptyBenchPosition {
    <#
    .SYNOPSIS
        Require an available bench position without overwriting an occupied slot.
    .OUTPUTS
        Selected position number, or zero on cancellation/no available position.
    #>
    $openSlots = @($Script:BuildBench.Positions | Where-Object { -not $_.Serial } | Sort-Object { [int]$_.Index })
    if (-not $openSlots.Count) { Write-Host 'All bench positions are occupied. Remove or dispatch a device, then try again.'; return 0 }
    while ($true) {
        Write-Host ('Empty positions: {0}' -f (($openSlots | ForEach-Object { $_.Index }) -join ', '))
        $choice = [int](Read-ValidatedInput -Prompt 'Position number ([0] Cancel)' -Default $openSlots[0].Index -Type Int)
        if ($choice -eq 0) { return 0 }
        if (@($openSlots | Where-Object { $_.Index -eq $choice }).Count -eq 1) { return $choice }
        Write-Host 'Choose one of the empty positions shown above, or 0 to cancel.'
    }
}

function Start-NewDeviceWorkflow {
    <#
    .SYNOPSIS
        Capture a new local workflow after field validation and explicit confirmation.
    .DESCRIPTION
        Declining retains site, serial, CI and type as editable defaults. Identifiers
        are checked during entry and again before insertion. Cancellation creates
        nothing; Graph operations run separately through the tracked manifest actions.
    .PARAMETER Records
        Current record container, updated only after confirmed identity validation.
    .OUTPUTS
        Selected site code; existing device evidence is not reset or reassigned.
    .PARAMETER CurrentSiteCode
        Current configured site offered during induction.
    .PARAMETER BenchRequired
        Require placement on the active bench rather than standalone induction.
    #>
    param([string]$CurrentSiteCode, [hashtable]$Records, [switch]$BenchRequired)
    Show-ScriptScreen -Title 'Start Work on a New Device'
    $placement = if ($BenchRequired) { 'B' } else { 'S' }
    if ($Script:BuildBench.Active -and -not $BenchRequired) {
        $hasSpace = @($Script:BuildBench.Positions | Where-Object { -not $_.Serial }).Count -gt 0
        Write-Host '[B] Place on the active bench'
        Write-Host '[S] Standalone tracked workflow'
        Write-Host '[0] Cancel induction'
        $placementDefault = if ($hasSpace) { 'B' } else { 'S' }
        $placement = Read-ValidatedInput -Prompt 'Device placement [B/S/0]' -Default $placementDefault -Type Choice -Choices @('B', 'S', '0')
        if ($placement -eq '0') { return $CurrentSiteCode }
    }
    $position = 0
    if ($placement -eq 'B') {
        $position = Select-EmptyBenchPosition
        if ($position -eq 0) { return $CurrentSiteCode }
    }
    $existing = Get-OffBenchDeviceRecord -Records $Records
    # Only ask for the source when a reusable off-bench workflow exists; otherwise a new
    # induction is the sole option and the serial prompt that follows still accepts cancellation.
    $source = 'N'
    if ($existing.Count) {
        Write-Host '[E] Reuse an existing off-bench workflow'
        Write-Host '[N] Induct a new device'
        Write-Host '[0] Cancel induction'
        $source = Read-ValidatedInput -Prompt 'Device source [E/N/0]' -Default 'E' -Type Choice -Choices @('E', 'N', '0')
    }
    if ($source -eq '0') { return $CurrentSiteCode }
    if ($source -eq 'E') {
        for ($index = 0; $index -lt $existing.Count; $index++) {
            $item = $existing[$index]
            Write-Host ('{0}. Serial={1} | CI={2} | {3} | {4}' -f ($index + 1), $item.Serial, $item.ConfigItem, $item.SiteCode, $item.DeviceType)
        }
        while ($true) {
            $selection = (Read-ValidatedInput -Prompt 'Existing device list number, serial or CI ([0] Cancel)' -Default '0').Trim()
            if ($selection -eq '0') { return $CurrentSiteCode }
            $listNumber = 0
            if ([int]::TryParse($selection, [ref]$listNumber) -and $listNumber -ge 1 -and $listNumber -le $existing.Count) {
                $record = $existing[$listNumber - 1]
                break
            }
            $matching = @($existing | Where-Object { $_.Serial -ieq $selection -or $_.ConfigItem -ieq $selection })
            if ($matching.Count -eq 1) { $record = $matching[0]; break }
            Write-Host ('Choose a unique displayed serial or CI, a list number 1-{0}, or 0 to cancel. No workflow was changed.' -f $existing.Count)
        }
        Assert-DeviceRecordIdentity -Records $Records.Value
        $selected = Select-ExistingDeviceWorkflowAction -Records $Records -Device $record -Position $position
        if ($selected -and -not $BenchRequired) { Show-ReturnToMainMenu }
        return $CurrentSiteCode
    }
    $siteCode = if ($placement -eq 'B' -and $Script:BuildBench.SiteCode) { $Script:BuildBench.SiteCode } else { $CurrentSiteCode }
    $serial = ''
    $configItem = ''
    $deviceType = if ($placement -eq 'B' -and $Script:BuildBench.DeviceType) { $Script:BuildBench.DeviceType } elseif ($Script:SessionDefaultDeviceType -in $Script:DeviceTypes) { $Script:SessionDefaultDeviceType } else { $Script:DeviceTypes[0] }
    while ($true) {
        $confirm = Read-ValidatedInput -Prompt ('Working at site {0}. Change? [Y] Yes [N] No [0] Cancel' -f $siteCode) -Default 'N' -Type 'Choice' -Choices @('Y', 'N', '0')
        if ($confirm -eq '0') { return $siteCode }
        if ($confirm.ToUpper() -eq 'Y') { $siteCode = Select-Site -CurrentSiteCode $siteCode; Show-ScriptScreen -Title 'Start Work on a New Device' }
        $serial = Read-NewDeviceIdentityField -Field Serial -Records $Records -Default $serial -AllowExistingSerial
        if (-not $serial) { return $siteCode }
        # A serial already occupying a bench position cannot be inducted again; refuse before offering
        # resume/restart choices that would only be rejected later, and re-prompt without a stale default.
        if ($placement -eq 'B' -and @($Script:BuildBench.Positions | Where-Object { $_.Serial -eq $serial }).Count -gt 0) {
            Write-Host 'This serial is already on the bench. Use Move to change its position, or enter a different serial.'
            $serial = ''
            continue
        }
        $matchingRecord = @($Records.Value | Where-Object { $_.Serial -eq $serial })
        if ($matchingRecord.Count) {
            Assert-DeviceRecordIdentity -Records $Records.Value
            [void](Select-ExistingDeviceWorkflowAction -Records $Records -Device $matchingRecord[0] -Position $position)
            return $siteCode
        }
        $configItem = Read-NewDeviceIdentityField -Field ConfigItem -Records $Records -Default $configItem
        if (-not $configItem) { return $siteCode }
        $deviceType = Select-DeviceType -Default $deviceType
        # Enforce Group Tag pattern (SITECODE-Devicetype, preserve case); no override permitted
        $expectedTag = ('{0}-{1}' -f $siteCode, ($deviceType -replace '\s', ''))
        Write-Host ''
        Write-Host 'Please confirm the details:'
        Write-Host ('  {0}: {1}' -f $Script:Config.Nomenclature.Serial, $serial)
        Write-Host ('  {0}: {1}' -f $Script:Config.Nomenclature.ConfigItem, $configItem)
        Write-Host ('  {0}: {1}' -f $Script:Config.Nomenclature.Site, $siteCode)
        Write-Host ('  {0}: {1}' -f $Script:Config.Nomenclature.DeviceType, $deviceType)
        Write-Host ('  {0}: {1}' -f $Script:Config.Nomenclature.GroupTag, $expectedTag)
        $proceed = Read-ValidatedInput -Prompt 'Proceed with these details? [Y] Yes [N] No [0] Cancel' -Default 'Y' -Type 'Choice' -Choices @('Y', 'N', '0')
        if ($proceed -eq '0') { return $siteCode }
        if ($proceed.ToUpper() -eq 'Y') {
            try {
                Assert-DeviceRecordIdentity -Records (@($Records.Value) + , @{ Serial = $serial; ConfigItem = $configItem; Status = 'new' })
            }
            catch {
                Write-Host $_.Exception.Message
                Write-Host 'Correct the identifiers below, or enter 0 to cancel and maintain the existing list.'
                continue
            }
            $record = New-DeviceRecordObject -Serial $serial -ConfigItem $configItem -SiteCode $siteCode -DeviceType $deviceType -GroupTag $expectedTag
            if ($placement -eq 'B') {
                Add-DeviceToBenchPosition -Position $position -Serial $serial -ConfigItem $configItem -SiteCode $siteCode -DeviceType $deviceType -Records $Records
            }
            else {
                Add-DeviceRecord -Records $Records -Record $record
                Write-UserDeviceRecords -Records $Records.Value
            }
            Write-AutopilotExpressLog -Message ('Added new device Serial={0} CI={1} Site={2} DeviceType={3}' -f $serial, $configItem, $siteCode, $deviceType) -Level 'INFO'
            if (-not $BenchRequired) { Show-ReturnToMainMenu }
            break
        }
        else {
            Write-Host "Let's correct the details. You will be re-prompted."
        }
    }
    return $siteCode
}

function Get-WorkflowDisplayCode {
    <#
    .SYNOPSIS
        Read a manifest display code without changing persisted step IDs.
    .PARAMETER Step
        Manifest definition; custom actions retain their configured ID.
    .OUTPUTS
        Display/selection code only. Persisted evidence always uses Step.Id.
    #>
    param([Parameter(Mandatory)][System.Collections.IDictionary]$Step)
    if ($Step.DisplayCode) { return [string]$Step.DisplayCode }
    return [string]$Step.Id
}

function Get-WorkflowStepLabel {
    <#
    .SYNOPSIS
        Label displayed actions while distinguishing historical persisted IDs.
    .PARAMETER Step
        Unchanged manifest definition.
    .OUTPUTS
        Human-readable code and name; no evidence is rewritten.
    #>
    param([Parameter(Mandatory)][System.Collections.IDictionary]$Step)
    $code = Get-WorkflowDisplayCode -Step $Step
    $suffix = if ($code -ne $Step.Id) { ' (saved ID {0})' -f $Step.Id } else { '' }
    if ($Step.ActionName -in @('AddToPreProvisioningGroup', 'RemoveFromPreProvisioningGroup')) {
        $groupName = Get-ConfiguredPreProvisioningGroupDisplayName
        if ($groupName) { $suffix += ' [Group: {0}]' -f $groupName }
    }
    return '{0}. {1}{2}' -f $code, $Step.DisplayName, $suffix
}

function Get-WorkflowStepReference {
    <#
    .SYNOPSIS
        Explain prerequisite IDs using display letters and explicit saved-ID labels.
    .PARAMETER StepIds
        Persisted IDs; missing/custom definitions remain readable without mutation.
    .OUTPUTS
        Comma-separated references, or None for an empty list.
    #>
    param([AllowEmptyCollection()][string[]]$StepIds = @())
    $references = foreach ($stepId in $StepIds) {
        $step = Get-ManifestStepDefinition -StepId $stepId
        $code = if ($step) { Get-WorkflowDisplayCode -Step $step } else { $stepId }
        if ($code -ne $stepId) { '{0} (saved ID {1})' -f $code, $stepId } else { $code }
    }
    if (@($references).Count) { return $references -join ', ' }
    return 'None'
}

function Show-WorkflowOutcome {
    <#
    .SYNOPSIS
        Separate the current device's last outcome with text and optional colour.
    .PARAMETER Result
        Returned evidence, shown only after successful persistence; submission is not completion.
    .OUTPUTS
        Host output only; no record or evidence changes.
    .PARAMETER Device
        Record whose serial/configuration item provide the result context.
    .PARAMETER Step
        Manifest definition used for the displayed action label, not a new action request.
    #>
    param(
        [Parameter(Mandatory)][System.Collections.IDictionary]$Device,
        [Parameter(Mandatory)][System.Collections.IDictionary]$Step,
        [Parameter(Mandatory)][System.Collections.IDictionary]$Result
    )
    $state = [string]$Result.CompletionState
    $background = 'DarkYellow'
    $label = 'PENDING'
    if (-not $Result.Success -or $state -in @('Failed', 'Blocked')) { $label = 'FAILED / NOT COMPLETED' }
    elseif ($state -eq 'Simulated' -or ($Result.IsSimulated -and $state -in @('Verified', 'TechnicianConfirmed'))) { $label = 'SIMULATED' }
    elseif ($Result.Success -and $state -in @('Verified', 'TechnicianConfirmed')) { $label = 'SUCCESS' }
    if ($label -in @('SUCCESS', 'SIMULATED')) { $background = 'DarkGreen' }
    elseif ($label -eq 'FAILED / NOT COMPLETED') { $background = 'DarkRed' }
    Write-Host ''
    Write-Host '---------------- LAST STEP RESULT ----------------'
    Write-Host ('{0}: Serial={1} | CI={2}' -f $label, $Device.Serial, $Device.ConfigItem) -BackgroundColor $background -ForegroundColor White
    Write-Host ('{0} [{1}]' -f (Get-WorkflowStepLabel -Step $Step), $state) -BackgroundColor $background -ForegroundColor White
    Write-Host ([string]$Result.Summary)
    if ($Result.Notes) { Write-Host ([string]$Result.Notes) }
    Write-Host '--------------------------------------------------'
}

function Invoke-AutopilotSequence {
    <#
    .SYNOPSIS
        Perform guarded manifest steps while retaining the selected device workflow.
    .PARAMETER Device
        Optional existing record supplied by Outstanding Work to avoid reselection.
    .PARAMETER ReturnDestination
        Caller-specific heading and return label; bench and main share this loop.
    .PARAMETER FeedbackState
        Optional transient bench events; only saved step outcomes are appended.
    .NOTES
        Evidence-labelled outcomes appear only after persistence succeeds. Live
        actions remain subject to configured scopes, tenant gates and confirmations.
    .PARAMETER Records
        Shared record container persisted after each explicitly selected workflow outcome.
    .OUTPUTS
        Host output only. Failed storage stops the sequence instead of replaying the action.
    #>
    param(
        [hashtable]$Records,
        [System.Collections.IDictionary]$Device,
        [ValidateSet('Main menu', 'Build bench', 'Device Commands', 'Outstanding Work')][string]$ReturnDestination = 'Main menu',
        [System.Collections.IDictionary]$FeedbackState
    )
    if ($ReturnDestination -eq 'Main menu' -and $Script:NavigationMenu -eq 'Devices') { $ReturnDestination = 'Device Commands' }
    if ($Device -and (@($Records.Value) -notcontains $Device -or $Device.Status -eq 'removed')) {
        Write-Host 'This device is no longer available in the current device list.'
        return
    }
    if (-not $Device) {
        Show-ScriptScreen -Title 'Select a Tracked Device'
        $Device = Select-DeviceFromRecords -Records $Records -Purpose 'work on'
    }
    if (-not $device) { return }
    $nextCommand = '8'
    $deviceCommand = '9'
    $prepareCommand = 'T'
    $recoverCommand = 'X'
    $undoCommand = 'U'
    $commandIds = @(Get-EnabledManifestSteps | ForEach-Object { Get-WorkflowDisplayCode -Step $_ })
    if (@($commandIds | Select-Object -Unique).Count -ne $commandIds.Count) { throw 'Workflow display codes are ambiguous; no action was selected.' }
    while ($commandIds -contains $nextCommand) { $nextCommand = 'NEXT-{0}' -f $nextCommand }
    while ($commandIds -contains $deviceCommand) { $deviceCommand = 'SELECT-{0}' -f $deviceCommand }
    while ($commandIds -contains $prepareCommand) { $prepareCommand = 'PREPARE-{0}' -f $prepareCommand }
    while ($commandIds -contains $recoverCommand) { $recoverCommand = 'RECOVER-{0}' -f $recoverCommand }
    while ($commandIds -contains $undoCommand) { $undoCommand = 'UNDO-{0}' -f $undoCommand }
    $feedback = @()
    $lastOutcome = $null
    while ($true) {
        $title = if ($ReturnDestination -eq 'Build bench') { 'Build Bench > Show Device overview' } else { 'Show Device overview' }
        Show-ScriptScreen -Title $title
        Write-Host ('Serial: {0}   CI: {1}   Status: {2}' -f $device.Serial, $device.ConfigItem, $device.Status)
        Write-Host 'Device overview (manifest-driven)'
        Write-Host ''
        Show-DeviceWorkflowStatus -Device $device
        Write-Host ('{0}. Prepare device (steps A-D)' -f $prepareCommand)
        Write-Host ('{0}. Recover from Autopilot failure (guided cleanup and readiness)' -f $recoverCommand)
        Write-Host ('{0}. Go back: withdraw the latest technician confirmation' -f $undoCommand)
        Write-Host ''
        Write-Host ('{0}. Run next eligible step' -f $nextCommand)
        Write-Host ('{0}. Select another device' -f $deviceCommand)
        Write-Host 'DISPATCH. Dispatch device; DO. Administrative completion override'
        Write-Host ('0. Return to {0}' -f $ReturnDestination.ToLowerInvariant())
        if ($lastOutcome) { Show-WorkflowOutcome -Device $device -Step $lastOutcome.Step -Result $lastOutcome.Result }
        if ($feedback.Count -gt 0) {
            Write-Host ''
            Write-Host 'Last action:'
            foreach ($line in $feedback) { Write-Host $line }
        }
        $opt = Read-ValidatedInput -Prompt 'Choose option' -Default '0'
        if ($opt -eq '0' -or ($opt -eq 'R' -and $commandIds -notcontains 'R')) { return }
        if ($opt -in @('DISPATCH', 'DO')) {
            $dispatchContext = if ($FeedbackState) { Get-DeviceFeedbackContext -Device $device } else { '' }
            $dispatch = Complete-DeviceDispatch -Records $Records -Device $device -Override:($opt -eq 'DO')
            if ($FeedbackState) { Add-ScreenFeedback -State $FeedbackState -Text @($dispatch.Summary) -Context $dispatchContext }
            $lastOutcome = $null
            $feedback = @($dispatch.Summary)
            if ($dispatch.Completed) { Write-Host $dispatch.Summary; return }
            continue
        }
        if ($opt -eq $undoCommand) {
            $correction = Undo-LatestTechnicianConfirmation -Records $Records -Device $device
            $lastOutcome = $null
            $feedback = @($correction.Summary)
            if ($FeedbackState) { Add-ScreenFeedback -State $FeedbackState -Text @($correction.Summary) -Context (Get-DeviceFeedbackContext -Device $device) }
            continue
        }
        if ($opt -eq $deviceCommand) {
            Show-ScriptScreen -Title 'Select a Tracked Device'
            $selected = Select-DeviceFromRecords -Records $Records -Purpose 'work on'
            if ($selected) { $device = $selected; $feedback = @(); $lastOutcome = $null }
            continue
        }
        if ($opt -eq $prepareCommand -or $opt -eq $recoverCommand) {
            $lastOutcome = $null
            $plan = if ($opt -eq $prepareCommand) { 'Prepare' } else { 'Recover' }
            $outcome = Invoke-DeviceWorkflowPlan -Records $Records -Device $device -Plan $plan
            if ($FeedbackState) {
                $state = if ($outcome.Result) { $outcome.Result.CompletionState } elseif ($outcome.Completed) { 'Complete' } else { 'Not completed' }
                $text = '{0} [{1}]: {2}' -f $plan, $state, $outcome.Summary
                if ($outcome.Result -and $outcome.Result.Notes) { $text += "`n" + $outcome.Result.Notes }
                Add-ScreenFeedback -State $FeedbackState -Text @($text) -Context (Get-DeviceFeedbackContext -Device $device)
            }
            if ($outcome.Step) { $lastOutcome = @{ Step = $outcome.Step; Result = $outcome.Result } }
            $feedback = @($outcome.Summary)
            continue
        }
        $sel = $null
        if ($opt -eq $nextCommand) {
            $lastOutcome = $null
            $opt = Get-NextStepId -Device $device
            if (-not $opt) {
                $readiness = Test-DeviceReadyForDispatch -Device $device
                $feedback = if ($readiness.Ready) { @('All required steps are complete.') } else { @('No next action is eligible. Required steps remain: {0}.' -f ($readiness.BlockingStepIds -join ', ')) }
                continue
            }
            $sel = Get-ManifestStepDefinition -StepId $opt
        }
        if ($opt) {
            if (-not $sel) {
                $sel = Get-EnabledManifestSteps | Where-Object { (Get-WorkflowDisplayCode -Step $_) -eq $opt } | Select-Object -First 1
            }
            if ($sel) {
                $result = Invoke-AutopilotManifestStep -Device $device -StepDefinition $sel
                Write-ManifestStepResult -Device $device -StepDefinition $sel -Result $result
                $lastOutcome = @{ Step = $sel; Result = $result }
                $feedback = @()
                Write-AutopilotExpressLog -Message ('Recorded step {0} ({1}) for Serial={2} Success={3}' -f $opt, $sel.DisplayName, $device.Serial, $result.Success) -Level 'INFO'
            }
            else { $feedback = @('Invalid step selection. Choose a displayed step, {0}, {1} or 0.' -f $nextCommand, $deviceCommand); continue }
        }
        Write-UserDeviceRecords -Records $Records.Value  # Save updated records after step selection
        if ($FeedbackState -and $sel) {
            $text = '{0} [{1}]: {2}' -f (Get-WorkflowStepLabel -Step $sel), $result.CompletionState, $result.Summary
            if ($result.Notes) { $text += "`n" + $result.Notes }
            Add-ScreenFeedback -State $FeedbackState -Text @($text) -Context (Get-DeviceFeedbackContext -Device $device)
        }
    }
}

function Invoke-DeviceWorkflowPlan {
    <#
    .SYNOPSIS
        Run preparation or recovery for one device with per-action save gates.
    .DESCRIPTION
        Resolves semantic manifest actions before making changes. Existing handlers
        own tenant checks, confirmations and physical observations. A save failure
        propagates immediately; incomplete results stop the plan except a scoped,
        persisted accepted tag may permit membership while remaining incomplete. Recovery cleanup
        requires current-cycle evidence, while an accepted current-cycle unblock
        resumes at readiness without another submission.
    .PARAMETER Records
        Current session container whose Value collection owns the selected device.
    .PARAMETER Device
        Active device record selected once by the calling menu.
    .PARAMETER Plan
        Prepare stops before physical milestones; Recover retains manual reset gates.
    .OUTPUTS
        Dictionary containing Completed, Summary, Step and Result for menu feedback.
    #>
    param(
        [Parameter(Mandatory)][ValidateNotNull()][hashtable]$Records,
        [Parameter(Mandatory)][ValidateNotNull()]$Device,
        [Parameter(Mandatory)][ValidateSet('Prepare', 'Recover')][string]$Plan
    )
    $outcome = @{ Completed = $false; Summary = ''; Step = $null; Result = $null }
    $pendingTagOutcome = $null
    if (@($Records.Value) -notcontains $Device -or $Device.Status -eq 'removed') {
        $outcome.Summary = 'The selected device is not active in this session.'
        return $outcome
    }
    $actions = if ($Plan -eq 'Prepare') {
        @('ResolveAutopilotDevice', 'RemoveAssociatedManagedDevice', 'ApplyGroupTag', 'AddToPreProvisioningGroup')
    }
    else {
        @('ResolveAutopilotDevice', 'RemoveAssociatedManagedDevice', 'ClearUserlessEnrollmentStatus', 'ConfirmRecoveryReadiness')
    }
    $definitions = @(foreach ($action in $actions) {
            $stepId = Get-ManifestActionStepId -ActionName $action
            $definition = Get-ManifestStepDefinition -StepId $stepId
            if ($null -eq $definition) { throw ('Missing plan action: {0}.' -f $action) }
            $definition
        })
    foreach ($definition in $definitions) {
        if ($Plan -eq 'Recover' -and $definition.ActionName -eq 'RemoveAssociatedManagedDevice' -and -not $Device.RecoveryActive) {
            Enter-DeviceRecoveryMode -Device $Device
            if (-not $Device.RecoveryActive) {
                $outcome.Summary = 'Recovery was not activated; no recovery actions were run.'
                return $outcome
            }
            Write-UserDeviceRecords -Records $Records.Value
        }
        $complete = Test-ManifestStepCompleted -Device $Device -StepId $definition.Id
        $evidence = $Device.Steps[$definition.Id]
        if ($Plan -eq 'Recover' -and $definition.ActionName -eq 'RemoveAssociatedManagedDevice') {
            $complete = $complete -and (ConvertTo-RecordDate -Value $evidence.Timestamp) -ge (ConvertTo-RecordDate -Value $Device.RecoveryStartedAt)
        }
        if ($Plan -eq 'Recover' -and $definition.ActionName -eq 'ClearUserlessEnrollmentStatus' -and $evidence.CompletionState -eq 'Submitted') {
            if ((ConvertTo-RecordDate -Value $evidence.Timestamp) -lt (ConvertTo-RecordDate -Value $Device.RecoveryStartedAt)) {
                $outcome.Summary = 'An earlier unblock submission requires review before continuing recovery.'
                return $outcome
            }
            continue
        }
        if ($complete) { continue }
        Write-Host ('{0}: Serial={1}; {2}. {3}' -f $Plan, $Device.Serial, $definition.Id, $definition.DisplayName)
        $result = Invoke-AutopilotManifestStep -Device $Device -StepDefinition $definition
        Write-ManifestStepResult -Device $Device -StepDefinition $definition -Result $result
        Write-UserDeviceRecords -Records $Records.Value
        $outcome.Step = $definition
        $outcome.Result = $result
        if (-not $result.Success -or -not (Test-CompletionStateComplete -CompletionState $result.CompletionState)) {
            if ($Plan -eq 'Prepare' -and $definition.ActionName -eq 'ApplyGroupTag' -and
                $result.CompletionState -eq 'Submitted' -and $result.Data.Submitted -eq $true -and
                (Test-ManifestStepEligibility -Device $Device -StepDefinition $definitions[-1]).Eligible) {
                $pendingTagOutcome = @{ Step = $definition; Result = $result }
                continue
            }
            $outcome.Summary = '{0} stopped at {1}: {2} [{3}]. {4}' -f $Plan, $definition.Id, $definition.DisplayName, $result.CompletionState, $result.Summary
            if ($pendingTagOutcome) { $outcome.Summary += ' Group Tag verification also remains pending.' }
            return $outcome
        }
    }
    if ($pendingTagOutcome) {
        $outcome.Step = $pendingTagOutcome.Step
        $outcome.Result = $pendingTagOutcome.Result
        $outcome.Summary = 'Membership is complete; Group Tag remains Submitted. Recheck {0} before physical provisioning.' -f $pendingTagOutcome.Step.Id
        return $outcome
    }
    $outcome.Completed = $true
    $outcome.Summary = if ($Plan -eq 'Prepare') {
        'Preparation actions are complete. Continue the physical checklist; deployment profile assignment still requires confirmation.'
    }
    else {
        'Recovery close-out is complete. Run Prepare to restart preparation before physical provisioning.'
    }
    return $outcome
}

function Show-DeviceWorkflowStatus {
    <#
    .SYNOPSIS
        Display one action per line with truthful completion and eligibility.
    .PARAMETER Device
        Tracked record; this view does not mutate progress or evidence.
    .OUTPUTS
        Host status/step text only; opening the view does not execute an action.
    #>
    param([Parameter(Mandatory)][System.Collections.IDictionary]$Device)
    Write-Host ('Device Serial={0} CI={1} Status={2}' -f $Device.Serial, $Device.ConfigItem, $Device.Status)
    $inventory = $Device.IntuneInventory
    $inventoryStatus = if ($inventory.Status) { [string]$inventory.Status } else { 'Not yet collected' }
    Write-Host ('Intune inventory: {0}; hostname: {1}; Ethernet MAC: {2}; last check: {3}' -f $inventoryStatus, $inventory.IntuneHostName, $inventory.EthernetMacAddress, $inventory.CheckedAt)
    foreach ($section in @('Completed', 'Retry', 'Outstanding', 'Conditional recovery')) {
        $lines = @()
        foreach ($step in (Get-EnabledManifestSteps)) {
            $completed = Test-ManifestStepCompleted -Device $Device -StepId $step.Id
            $attempted = Test-ManifestStepAttempted -Device $Device -StepId $step.Id
            $kind = if ($step.IsConditional) { 'Conditional recovery' } elseif ($completed) { 'Completed' } elseif ($attempted) { 'Retry' } else { 'Outstanding' }
            if ($kind -ne $section) { continue }
            $state = if ($completed -or $attempted) { [string]$Device.Steps[$step.Id].CompletionState } else { '' }
            if (-not $state) {
                $eligibility = Test-ManifestStepEligibility -Device $Device -StepDefinition $step
                $state = if ($eligibility.Eligible) { 'Eligible' } elseif ($eligibility.MissingStepIds.Count) { 'Requires: {0}' -f (Get-WorkflowStepReference -StepIds $eligibility.MissingStepIds) } else { '{0} required' -f $eligibility.ActivationRequirement }
            }
            $lines += '  {0} [{1}]' -f (Get-WorkflowStepLabel -Step $step), $state
        }
        Write-Host ''
        Write-Host ('{0} Steps:' -f $section)
        if ($lines.Count -eq 0) { Write-Host '  None' }
        foreach ($line in $lines) { Write-Host $line }
    }
}

function Get-DeviceOutstanding {
    <#
    .SYNOPSIS
        Display outstanding records and open the explicitly selected device workflow.
    .PARAMETER Records
        Shared current-session record container.
    .OUTPUTS
        Host output only. Returns control to the caller after selection or cancellation.
    #>
    param([hashtable]$Records)
    while ($true) {
        Show-ScriptScreen -Title 'Outstanding Work - Select Device'
        $device = Select-DeviceFromRecords -Records $Records -Purpose 'inspect outstanding work'
        if (-not $device) { return }
        while ($true) {
            Show-ScriptScreen -Title 'Outstanding Work'
            Show-DeviceWorkflowStatus -Device $device
            Write-Host ''
            Write-Host '1. Work on this device'
            Write-Host '2. Select another device'
            Write-Host ('0. Return to {0}' -f (Get-NavigationMenuTitle))
            $choice = Read-ValidatedInput -Prompt 'Choose option' -Default '0' -Type 'Choice' -Choices @('0', '1', '2')
            if ($choice -eq '0') { return }
            if ($choice -eq '2') { break }
            Invoke-AutopilotSequence -Records $Records -Device $device -ReturnDestination 'Outstanding Work'
        }
    }
}

function Update-DeviceStatus {
    <#
    .SYNOPSIS
        Maintain device status while enforcing completion and dispatch-evidence safeguards.
    .PARAMETER Records
        Mutable current-session container to validate and persist after a confirmed change.
    .OUTPUTS
        None. A valid change uses guarded persistence; cancellation/no-op leaves records unchanged.
    #>
    param([hashtable]$Records)
    while ($true) {
        Show-ScriptScreen -Title 'Maintain My Device List'
        $device = Select-DeviceFromRecords -Records $Records -Purpose 'update status' -IncludeCompleted
        if (-not $device) { return }
        $status = Read-ValidatedInput -Prompt 'Enter status (new,in-progress,completed,removed)' -Type 'Choice' -Choices @('new', 'in-progress', 'completed', 'removed') -Default $device.Status
        if ($status -eq 'completed') {
            $readiness = Test-DeviceReadyForDispatch -Device $device
            if (-not $readiness.Ready) {
                Write-Host ''
                Write-Host ('Cannot mark this device completed. Required steps remain: {0}.' -f ($readiness.BlockingStepIds -join ', '))
                Write-Host 'Choose another status or 0 to return to device selection.'
                $status = Read-ValidatedInput -Prompt 'Status' -Default $device.Status -Type Choice -Choices @('0', 'new', 'in-progress', 'removed')
                if ($status -eq '0') { continue }
            }
        }
        if ($status -ne $device.Status) {
            $device.Status = $status
            $device.DispatchConfirmed = $false
            $device.DispatchedAt = [DateTime]::MinValue
            if ($status -eq 'completed') { $device.CompletedAt = Get-Date; $device.CompletedBy = $env:USERNAME }
            $device.LastUpdatedAt = Get-Date; $device.LastUpdatedBy = $env:USERNAME
            Write-UserDeviceRecords -Records $Records.Value
            Write-AutopilotExpressLog -Message ('Updated status {0} for Serial={1}' -f $status, $device.Serial) -Level 'INFO'
        }
        Write-Host ''
        Write-Host ('Updated Serial={0} | CI={1} | Status={2}' -f $device.Serial, $device.ConfigItem, $device.Status)
        $choice = Read-ValidatedInput -Prompt ('1. Maintain another device; 0. Return to {0}' -f (Get-NavigationMenuTitle)) -Default '0' -Type Choice -Choices @('0', '1')
        if ($choice -eq '0') { return }
    }
}

function Get-DeviceDispatchDate {
    <#
    .SYNOPSIS
        Return only a proven dispatch instant for a currently completed device.
    .PARAMETER Device
        Loaded record; legacy overrides need matching completion snapshot evidence.
    .OUTPUTS
        DateTime; MinValue means dispatch has not been proved.
    #>
    param([Parameter(Mandatory)][System.Collections.IDictionary]$Device)
    if ($Device.Status -ne 'completed') { return [DateTime]::MinValue }
    if ($Device.DispatchConfirmed -is [bool] -and $Device.DispatchConfirmed) {
        return ConvertTo-RecordDate -Value $Device.DispatchedAt
    }
    if ($Device.Contains('DispatchConfirmed')) { return [DateTime]::MinValue }
    $completedAt = ConvertTo-RecordDate -Value $Device.CompletedAt
    if ($completedAt -eq [DateTime]::MinValue) { return [DateTime]::MinValue }
    foreach ($snapshot in @($Device.RecoveryHistory)) {
        if ($snapshot -isnot [System.Collections.IDictionary] -or $snapshot.Stage -ne 'CompletionOverride') { continue }
        $date = ConvertTo-RecordDate -Value $snapshot.Timestamp
        if ($date -ne [DateTime]::MinValue -and $date.ToUniversalTime() -eq $completedAt.ToUniversalTime()) { return $date }
    }
    return [DateTime]::MinValue
}

function Format-BuildElapsedTime {
    <#
    .SYNOPSIS
        Format elapsed minutes as days and a valid HH:mm remainder.
    .PARAMETER Minutes
        Duration to display; invalid/absent values are not fabricated as zero.
    .OUTPUTS
        Dd HH:mm string or N/A, truncating only the displayed whole minutes.
    #>
    param($Minutes)
    if ($null -eq $Minutes) { return 'N/A' }
    $wholeMinutes = [Math]::Floor([double]$Minutes)
    return '{0}d {1:00}:{2:00}' -f [int][Math]::Floor($wholeMinutes / 1440), [int][Math]::Floor(($wholeMinutes % 1440) / 60), [int]($wholeMinutes % 60)
}

function Get-ImagingWorkPatternPath {
    <#
    .SYNOPSIS
        Resolve the current user's mode-isolated work-pattern file in the active store.
    .OUTPUTS
        Absolute JSON path; no directory or file is created.
    #>
    $modeName = if ($Script:Runtime.IsDemoMode) { 'demo' } else { 'live' }
    return Join-Path (Get-DataFolderPath) ('autopilot-work-pattern-{0}-{1}.json' -f $modeName, $env:USERNAME)
}

function Assert-ImagingWorkPattern {
    <#
    .SYNOPSIS
        Reject malformed, foreign-user or cross-mode work-pattern history.
    .PARAMETER WorkPattern
        Versioned dictionary with append-only calendar changes.
    .OUTPUTS
        None; invalid stored history throws rather than silently reverting to defaults.
    #>
    param([Parameter(Mandatory)][hashtable]$WorkPattern)
    $modeName = if ($Script:Runtime.IsDemoMode) { 'demo' } else { 'live' }
    if ($WorkPattern.SchemaVersion -ne 1 -or $WorkPattern.User -cne $env:USERNAME -or $WorkPattern.Mode -cne $modeName -or $WorkPattern.Changes -isnot [array]) {
        throw 'Work-pattern history has an invalid schema, owner or mode.'
    }
    foreach ($change in $WorkPattern.Changes) {
        if ($change -isnot [System.Collections.IDictionary] -or $change.Kind -notin @('Schedule', 'Sick', 'RDO', 'WFH', 'Scheduled')) { throw 'Invalid work-pattern change.' }
        $date = [datetime]::ParseExact([string]$change.Date, 'yyyy-MM-dd', [Globalization.CultureInfo]::InvariantCulture)
        $recorded = ConvertTo-RecordDate -Value $change.RecordedAt
        if ($recorded -eq [datetime]::MinValue -or $change.Actor -cne $WorkPattern.User) { throw 'Work-pattern change is missing valid actor/time evidence.' }
        if ($recorded.Kind -eq [DateTimeKind]::Utc) { $recorded = $recorded.ToLocalTime() }
        if ($date -lt $recorded.Date -and $change.Kind -notin @('Sick', 'RDO', 'WFH')) { throw 'Backdated working-hour changes are not permitted.' }
        if ($change.Kind -eq 'Schedule') {
            if ($change.Start -notmatch '^(?:[01][0-9]|2[0-3]):[0-5][0-9]$' -or $change.End -notmatch '^(?:[01][0-9]|2[0-3]):[0-5][0-9]$' -or
                [timespan]::Parse($change.End) -le [timespan]::Parse($change.Start) -or $change.Days -isnot [array]) { throw 'Invalid scheduled hours.' }
            foreach ($weekday in $change.Days) { if ([string]$weekday -notmatch '^[0-6]$') { throw 'Invalid scheduled weekday.' } }
        }
    }
}

function Read-ImagingWorkPattern {
    <#
    .SYNOPSIS
        Load guarded work-pattern history without creating a default file.
    .OUTPUTS
        Current-user/mode dictionary; absent history uses the original weekday policy.
    #>
    $path = Get-ImagingWorkPatternPath
    Assert-FileWriteRecoveryState -Path $path
    if (-not (Test-Path -LiteralPath $path)) {
        return @{ SchemaVersion = 1; User = $env:USERNAME; Mode = if ($Script:Runtime.IsDemoMode) { 'demo' } else { 'live' }; Changes = @() }
    }
    $decoded = Get-Content -LiteralPath $path -Raw -Encoding UTF8 -ErrorAction Stop | ConvertFrom-Json
    $workPattern = ConvertTo-NormalisedValue -Value $decoded
    Assert-ImagingWorkPattern -WorkPattern $workPattern
    return $workPattern
}

function Get-ImagingWorkPatternProposal {
    <#
    .SYNOPSIS
        Propose an append-only schedule or non-imaging-day change without mutation.
    .PARAMETER WorkPattern
        Existing history, retained in full in the detached proposal.
    .PARAMETER Date
        Effective schedule date or exact calendar day to mark.
    .PARAMETER Kind
        Schedule changes apply forwards; Sick/RDO/WFH alone are allowed in the past.
    .PARAMETER Days
        Scheduled weekday numbers, Sunday zero through Saturday six; empty means no planned days.
    .PARAMETER Start
        Local same-day start in strict 24-hour HH:mm notation.
    .PARAMETER End
        Local same-day finish, strictly later than Start; overnight shifts are not supported.
    .PARAMETER Now
        Current local instant; supplied explicitly only for deterministic offline tests.
    .OUTPUTS
        New dictionary; neither existing history nor device events are changed.
    #>
    param([Parameter(Mandatory)][hashtable]$WorkPattern, [Parameter(Mandatory)][datetime]$Date,
        [Parameter(Mandatory)][ValidateSet('Schedule', 'Sick', 'RDO', 'WFH', 'Scheduled')][string]$Kind,
        [AllowEmptyCollection()][int[]]$Days = @(1, 2, 3, 4, 5), [string]$Start = '08:30', [string]$End = '17:30', [datetime]$Now = (Get-Date))
    Assert-ImagingWorkPattern -WorkPattern $WorkPattern
    if ($Date.Date -lt $Now.Date -and $Kind -notin @('Sick', 'RDO', 'WFH')) { throw 'Past work hours are locked. Only Sick, RDO or WFH markings are permitted.' }
    $change = @{ Date = $Date.ToString('yyyy-MM-dd'); Kind = $Kind; Actor = $env:USERNAME; RecordedAt = $Now.ToString('o') }
    if ($Kind -eq 'Schedule') { $change.Days = @($Days | Sort-Object -Unique); $change.Start = $Start; $change.End = $End }
    $proposal = @{ SchemaVersion = 1; User = $WorkPattern.User; Mode = $WorkPattern.Mode; Changes = @($WorkPattern.Changes) + @($change) }
    Assert-ImagingWorkPattern -WorkPattern $proposal
    return $proposal
}

function Get-ImagingWorkWindow {
    <#
    .SYNOPSIS
        Resolve the effective weekly schedule and latest exact-day marking.
    .PARAMETER Date
        Local calendar day; future revisions never affect an earlier date.
    .PARAMETER WorkPattern
        Validated append-only history, or null for original Monday-Friday defaults.
    .OUTPUTS
        Working/Blocked flags, day kind and local start/end minute offsets.
    #>
    param([Parameter(Mandatory)][datetime]$Date, [hashtable]$WorkPattern)
    $effective = '0001-01-01'
    $days = @(1, 2, 3, 4, 5)
    $start = '08:30'; $end = '17:30'; $kind = 'Scheduled'
    $key = $Date.ToString('yyyy-MM-dd')
    foreach ($change in @($WorkPattern.Changes)) {
        if ($null -eq $change) { continue }
        if ($change.Kind -eq 'Schedule' -and $change.Date -le $key -and $change.Date -ge $effective) {
            $effective = $change.Date; $days = @($change.Days); $start = $change.Start; $end = $change.End
        }
        if ($change.Kind -ne 'Schedule' -and $change.Date -eq $key) { $kind = $change.Kind }
    }
    return @{ Working = ([int]$Date.DayOfWeek -in $days); Blocked = ($kind -in @('Sick', 'RDO', 'WFH')); Kind = $kind;
        StartMinutes = [timespan]::Parse($start).TotalMinutes; EndMinutes = [timespan]::Parse($end).TotalMinutes
    }
}

function Save-ImagingWorkPatternChange {
    <#
    .SYNOPSIS
        Append an approved change under the active reservation and publish only after save.
    .PARAMETER Change
        Validated date/kind/hours arguments passed to the pure proposal builder.
    .OUTPUTS
        None. Failed saves retain the old in-memory profile and recovery evidence.
    #>
    param([Parameter(Mandatory)][hashtable]$Change)
    Assert-ActiveStorageReservation
    foreach ($key in $Change.Keys) {
        if ($key -notin @('Date', 'Kind', 'Days', 'Start', 'End')) { throw 'Unsupported work-pattern change field. The current date cannot be overridden when saving.' }
    }
    $current = Read-ImagingWorkPattern
    $proposal = Get-ImagingWorkPatternProposal -WorkPattern $current @Change
    Write-Utf8File -Path (Get-ImagingWorkPatternPath) -Content (ConvertTo-Json -InputObject $proposal -Depth 12)
    $Script:ImagingWorkPattern = $proposal
}

function Get-ImagingWorkPatternLines {
    <#
    .SYNOPSIS
        Render the current schedule and complete append-only change history.
    .PARAMETER WorkPattern
        Current-user schedule history; null retains original weekday defaults.
    .OUTPUTS
        Accessible text lines, with newest recorded changes first.
    #>
    param([hashtable]$WorkPattern)
    $window = Get-ImagingWorkWindow -Date (Get-Date) -WorkPattern $WorkPattern
    'Today: {0}; scheduled weekday={1}; {2}-{3}' -f $window.Kind, $window.Working,
    ([timespan]::FromMinutes($window.StartMinutes).ToString('hh\:mm')), ([timespan]::FromMinutes($window.EndMinutes).ToString('hh\:mm'))
    'Base policy before any revision: Monday-Friday, 08:30-17:30.'
    $changes = @($WorkPattern.Changes | Where-Object { $null -ne $_ })
    if (-not $changes.Count) { 'No custom changes recorded.' }
    for ($index = $changes.Count - 1; $index -ge 0; $index--) {
        $change = $changes[$index]
        $detail = if ($change.Kind -eq 'Schedule') {
            $dayNames = @($change.Days | ForEach-Object { ([DayOfWeek][int]$_).ToString() })
            '{0}; {1}-{2}' -f ($dayNames -join ', '), $change.Start, $change.End
        }
        else { 'Exact date only; Sick/RDO/WFH have zero planned imaging hours.' }
        '{0} | {1} | {2} | Recorded {3} by {4}' -f $change.Date, $change.Kind, $detail, $change.RecordedAt, $change.Actor
    }
}

function Show-ImagingWorkPatternEditor {
    <#
    .SYNOPSIS
        Edit future/current schedules and append authorised past-day markings.
    .DESCRIPTION
        Zero/Enter cancels. Every save requires explicit Y, default No. Earlier
        hours cannot be edited or reset, and original device events are untouched.
    .OUTPUTS
        Host screens only; returns to Settings without calling another menu.
    #>
    while ($true) {
        Show-ScriptScreen -Title 'Work Pattern Editor'
        Write-Host '1. Set weekly hours from an effective date'
        Write-Host '2. Mark a calendar day: Sick, RDO, WFH or scheduled'
        Write-Host '3. View current pattern and change history'
        Write-Host '0. Return to Session and Script Settings'
        $choice = Read-ValidatedInput -Prompt 'Choose an option' -Default '0' -Type Choice -Choices @('0', '1', '2', '3')
        if ($choice -eq '0') { return }
        if ($choice -eq '3') {
            [void](Read-PagedInformation -Title 'Work Pattern History' -Lines @(Get-ImagingWorkPatternLines -WorkPattern $Script:ImagingWorkPattern) -ReturnDestination 'Work Pattern Editor')
            continue
        }
        $text = Read-ValidatedInput -Prompt 'Date YYYY-MM-DD ([0] Cancel)' -Default '0'
        if ($text -eq '0') { continue }
        $date = [datetime]::MinValue
        if (-not [datetime]::TryParseExact($text, 'yyyy-MM-dd', [Globalization.CultureInfo]::InvariantCulture, [Globalization.DateTimeStyles]::None, [ref]$date)) {
            Write-Host 'Invalid date. Use YYYY-MM-DD.'; continue
        }
        $change = @{ Date = $date; Kind = 'Schedule' }
        if ($choice -eq '1') {
            if ($date.Date -lt (Get-Date).Date) { Write-Host 'Past work hours are locked. Only Sick, RDO or WFH markings are permitted.'; continue }
            $daysText = Read-ValidatedInput -Prompt 'Weekdays 1=Mon to 7=Sun, comma-separated; NONE for none ([0] Cancel)' -Default '0'
            if ($daysText -eq '0') { continue }
            if ($daysText -ieq 'NONE') { $change.Days = @() }
            elseif ($daysText -match '^[1-7](,[1-7])*$') { $change.Days = @($daysText -split ',' | ForEach-Object { [int]$_ % 7 }) }
            else { Write-Host 'Invalid weekdays. Enter comma-separated numbers from 1 to 7, or NONE.'; continue }
            $change.Start = Read-ValidatedInput -Prompt 'Start HH:mm, 24-hour time ([0] Cancel)' -Default '0'
            if ($change.Start -eq '0') { continue }
            $change.End = Read-ValidatedInput -Prompt 'Finish HH:mm, later on the same day ([0] Cancel)' -Default '0'
            if ($change.End -eq '0') { continue }
        }
        else {
            $kinds = if ($date.Date -lt (Get-Date).Date) { @('Sick', 'RDO', 'WFH') } else { @('Sick', 'RDO', 'WFH', 'Scheduled') }
            $change.Kind = Read-ValidatedInput -Prompt ('Day marking: {0} ([0] Cancel)' -f ($kinds -join ', ')) -Default '0' -Type Choice -Choices (@('0') + $kinds)
            if ($change.Kind -eq '0') { continue }
        }
        try {
            $current = Read-ImagingWorkPattern
            [void](Get-ImagingWorkPatternProposal -WorkPattern $current @change)
            Write-Host ('Proposed {0} from/on {1}; existing history and device timestamps will be retained.' -f $change.Kind, $text)
            if ($change.Kind -eq 'Schedule') { Write-Host ('Weekdays={0}; {1}-{2}' -f ($change.Days -join ','), $change.Start, $change.End) }
            $confirmed = Read-ValidatedInput -Prompt 'Save this work-pattern change? [Y] Yes [N] No' -Default 'N' -Type Choice -Choices @('Y', 'N')
            if ($confirmed -ieq 'Y') { Save-ImagingWorkPatternChange -Change $change; Write-Host 'Work-pattern change saved.' }
            else { Write-Host 'No changes saved.' }
        }
        catch { Write-Host ('Work-pattern change was not applied: {0}' -f $_.Exception.Message) }
    }
}

function Get-ImagingWorkingMinutes {
    <#
    .SYNOPSIS
        Calculate schedule-adjusted elapsed imaging time using local calendar days.
    .DESCRIPTION
        Counts Monday-Friday 08:30-17:30. Induction/action dates can enable a weekend
        and extend that date's window. Late work ends at its last recorded action;
        subsequent scheduled time resumes at the next recorded load or action.
        Historical records use available evidence without inventing session starts.
    .PARAMETER Device
        Record with original induction, attempts, current steps and optional session starts.
    .PARAMETER End
        Proven dispatch instant; missing or negative intervals return null.
    .OUTPUTS
        Double minutes or null. Original records and timestamps are not changed.
    #>
    param([Parameter(Mandatory)][System.Collections.IDictionary]$Device, [Parameter(Mandatory)][datetime]$End)
    $start = ConvertTo-RecordDate -Value $Device.StartedAt
    if ($start -eq [DateTime]::MinValue -or $End -eq [DateTime]::MinValue -or $End.ToUniversalTime() -lt $start.ToUniversalTime()) { return $null }
    if ($start.Kind -eq [DateTimeKind]::Utc) { $start = $start.ToLocalTime() }
    if ($End.Kind -eq [DateTimeKind]::Utc) { $End = $End.ToLocalTime() }
    $activities = @($start, $End)
    $stepValues = if ($Device.Steps -is [System.Collections.IDictionary]) { @($Device.Steps.Values) } else { @() }
    foreach ($entry in @($Device.AttemptHistory) + $stepValues) {
        if ($null -eq $entry) { continue }
        $date = ConvertTo-RecordDate -Value $entry.Timestamp
        if ($date -eq [DateTime]::MinValue) { continue }
        if ($date.Kind -eq [DateTimeKind]::Utc) { $date = $date.ToLocalTime() }
        if ($date -ge $start -and $date -le $End) { $activities += $date }
    }
    $activities = @($activities | Sort-Object -Unique)
    $loads = @(foreach ($value in @($Device.ImagingSessionStarts)) {
            $date = ConvertTo-RecordDate -Value $value
            if ($date -eq [DateTime]::MinValue) { continue }
            if ($date.Kind -eq [DateTimeKind]::Utc) { $date = $date.ToLocalTime() }
            if ($date -ge $start -and $date -le $End) { $date }
        })
    $byDay = @{}
    foreach ($date in $activities) {
        $key = $date.Date.Ticks
        if (-not $byDay.ContainsKey($key)) { $byDay[$key] = @() }
        $byDay[$key] += $date
    }
    $pauses = @(foreach ($dates in $byDay.Values) {
            $last = @($dates | Sort-Object)[-1]
            $window = Get-ImagingWorkWindow -Date $last -WorkPattern $Script:ImagingWorkPattern
            if ($window.Blocked -or $last.TimeOfDay -le [timespan]::FromMinutes($window.EndMinutes)) { continue }
            $resume = @(@($loads | Where-Object { $_ -gt $last }) + @($activities | Where-Object { $_.Date -gt $last.Date }) | Sort-Object | Select-Object -First 1)
            if ($resume.Count) { @{ Start = $last; End = $resume[0] } }
        })
    $minutes = 0.0
    for ($day = $start.Date; $day -le $End.Date; $day = $day.AddDays(1)) {
        $dates = @($byDay[$day.Ticks] | Where-Object { $null -ne $_ })
        $window = Get-ImagingWorkWindow -Date $day -WorkPattern $Script:ImagingWorkPattern
        if ($window.Blocked -or (-not $window.Working -and -not $dates.Count)) { continue }
        $from = $day.AddMinutes($window.StartMinutes)
        $until = $day.AddMinutes($window.EndMinutes)
        if ($dates.Count) {
            if ($dates[0] -lt $from) { $from = $dates[0] }
            if ($dates[-1] -gt $until) { $until = $dates[-1] }
        }
        if ($from -lt $start) { $from = $start }
        if ($until -gt $End) { $until = $End }
        if ($until -le $from) { continue }
        $dayMinutes = ($until.ToUniversalTime() - $from.ToUniversalTime()).TotalMinutes
        foreach ($pause in $pauses) {
            $pauseStart = if ($pause.Start -gt $from) { $pause.Start } else { $from }
            $pauseEnd = if ($pause.End -lt $until) { $pause.End } else { $until }
            if ($pauseEnd -gt $pauseStart) { $dayMinutes -= ($pauseEnd.ToUniversalTime() - $pauseStart.ToUniversalTime()).TotalMinutes }
        }
        $minutes += [Math]::Max(0, $dayMinutes)
    }
    return $minutes
}

function Register-ImagingSessionStart {
    <#
    .SYNOPSIS
        Record this user's session load for every unfinished device without altering actions.
    .PARAMETER Records
        Loaded current-user records; completed and removed devices remain unchanged.
    .PARAMETER Timestamp
        Actual session-load instant, not inferred from file modification times.
    .OUTPUTS
        Boolean indicating whether metadata changed; the caller performs the guarded save.
    #>
    param([AllowEmptyCollection()][object[]]$Records = @(), [Parameter(Mandatory)][datetime]$Timestamp)
    $changed = $false
    $text = Get-Date -Date $Timestamp -Format o
    foreach ($record in $Records) {
        if ($record.Status -in @('completed', 'removed')) { continue }
        if ($text -notin @($record.ImagingSessionStarts)) {
            $record.ImagingSessionStarts = @(@($record.ImagingSessionStarts) + @($text) | Where-Object { $null -ne $_ })
            $changed = $true
        }
    }
    return $changed
}

function Get-BuildDurationSummary {
    <#
    .SYNOPSIS
        Calculate duration aggregates before rounding display values.
    .PARAMETER Minutes
        Valid duration samples from proven dispatched records.
    .OUTPUTS
        Average, Min and Max display strings; empty samples produce N/A fields.
    #>
    param([AllowEmptyCollection()][double[]]$Minutes = @())
    if (-not $Minutes.Count) { return @{ Average = 'N/A'; Min = 'N/A'; Max = 'N/A' } }
    $summary = $Minutes | Measure-Object -Average -Minimum -Maximum
    return @{ Average = Format-BuildElapsedTime $summary.Average; Min = Format-BuildElapsedTime $summary.Minimum; Max = Format-BuildElapsedTime $summary.Maximum }
}

function Get-DispatchStatsRows {
    <#
    .SYNOPSIS
        Count distinct dispatched records by local dispatch day and retain valid duration samples.
    .PARAMETER Records
        Local records only; removed, incomplete and unproved dispatches are excluded.
    .OUTPUTS
        Newest-first daily dictionaries; no record or evidence is modified.
    #>
    param([AllowEmptyCollection()][object[]]$Records = @())
    $dailyRows = @{}
    $seen = @{}
    foreach ($record in $Records) {
        if ($record -isnot [System.Collections.IDictionary] -or -not $record.RecordId -or $seen.ContainsKey([string]$record.RecordId)) { continue }
        $date = Get-DeviceDispatchDate -Device $record
        if ($date -eq [DateTime]::MinValue) { continue }
        $seen[[string]$record.RecordId] = $true
        $localDate = if ($date.Kind -eq [DateTimeKind]::Utc) { $date.ToLocalTime() } else { $date }
        $dateKey = Get-Date -Date $localDate -Format 'd/M/yyyy'
        if (-not $dailyRows.ContainsKey($dateKey)) {
            $dailyRows[$dateKey] = @{ Date = $dateKey; SortDate = $localDate.Date; Desktop = 0; Laptop = 0; WOW = 0; NUC = 0; Total = 0; Durations = @(); MissingDuration = 0 }
        }
        $row = $dailyRows[$dateKey]
        if ([string]$record.DeviceType -in @('Desktop', 'Laptop', 'WOW', 'NUC')) { $row[[string]$record.DeviceType]++ }
        $row.Total++
        $startedAt = ConvertTo-RecordDate -Value $record.StartedAt
        if ($startedAt -ne [DateTime]::MinValue -and $date.ToUniversalTime() -ge $startedAt.ToUniversalTime()) {
            $row.Durations += Get-ImagingWorkingMinutes -Device $record -End $date
        }
        else { $row.MissingDuration++ }
    }
    foreach ($row in $dailyRows.Values) {
        $summary = Get-BuildDurationSummary -Minutes @($row.Durations)
        foreach ($field in @('Average', 'Min', 'Max')) { $row[$field] = $summary[$field] }
    }
    return , @($dailyRows.Values | Sort-Object { $_.SortDate } -Descending)
}

function Get-UserStats {
    <#
    .SYNOPSIS
        Render dispatch-day statistics using the same eligible records for every breakdown.
    .PARAMETER Records
        Current session record container; removed/incomplete/unproven dispatches are excluded.
    .PARAMETER CurrentSiteCode
        Current session site for the opening week-to-date and all-time tables.
    .PARAMETER AsOf
        Local reference date for Monday-to-Sunday weeks; defaults to today.
    .OUTPUTS
        Accessible wide tables or narrow labelled rows with duration/missing-data disclosure.
        Does not infer historical dispatch dates from automatic completion.
    #>
    param([hashtable]$Records, [string]$CurrentSiteCode = '', [datetime]$AsOf = (Get-Date))
    Show-ScriptScreen -Title 'My Stats and Progress'
    $recordsLocal = @()
    foreach ($record in @($Records['Value'])) {
        if ($record -is [System.Collections.IDictionary] -and $record['RecordId']) {
            $recordsLocal += , $record
        }
        elseif ($record -is [System.Collections.IEnumerable] -and $record -isnot [string]) {
            foreach ($nestedRecord in $record) {
                if ($nestedRecord -is [System.Collections.IDictionary] -and $nestedRecord['RecordId']) {
                    $recordsLocal += , $nestedRecord
                }
            }
        }
    }
    $recordsLocal = @($recordsLocal | Where-Object { (Get-DeviceDispatchDate -Device $_) -ne [DateTime]::MinValue })
    function Write-StatsLine {
        <#
        .SYNOPSIS
            Wrap statistics and menu choices without losing labels or disclosures.
        .PARAMETER Text
            Complete statistics line passed to the shared feedback wrapper.
        .OUTPUTS
            Host text split into readable terminal-width lines.
        #>
        param([string]$Text)
        $lines = Get-ScreenFeedbackLines -State @{ Events = @(@{ Text = $Text; Context = '' }) }
        foreach ($line in $lines) { Write-Host $line }
    }

    if (-not $recordsLocal.Count) {
        Write-StatsLine 'No dispatched devices to display.'
        $null = Read-ValidatedInput -Prompt '[0] Return to main menu' -Default '0' -Type Choice -Choices @('0')
        return
    }

    function Show-StatsTable {
        <#
        .SYNOPSIS
            Render one date-sorted statistics group in wide or labelled narrow layout.
        .PARAMETER Rows
            Precomputed daily counts and duration summaries.
        .PARAMETER Title
            Overall or site group name shown above the rows.
        .OUTPUTS
            Host text only; display truncation does not change duration calculations.
        #>
        param($Rows, [string]$Title)
        Write-StatsLine ('--- {0} ---' -f $Title)
        if (-not $Rows) { Write-StatsLine 'No dispatched devices for this site and date period.'; Write-Host ''; return }
        $format = '| {0,-10} | {1,-7} | {2,-6} | {3,-3} | {4,-3} | {5,-5} | {6,-12} | {7,-12} | {8,-12} |'
        $header = $format -f 'Date', 'Desktop', 'Laptop', 'WOW', 'NUC', 'Total', 'Average', 'Min', 'Max'
        $width = Get-ConsoleTextWidth
        $rule = '-' * [Math]::Min($width, $header.Length)
        if ($width -ge $header.Length) { Write-Host $header }
        else { $format = "{0}: Desktop={1}; Laptop={2}; WOW={3}; NUC={4}; Total={5}`nAverage={6}; Min={7}; Max={8}" }
        Write-Host $rule
        $totDesktop = 0
        $totLaptop = 0
        $totWOW = 0
        $totNUC = 0
        $totAll = 0
        foreach ($r in $Rows) {
            Write-StatsLine ($format -f $r['Date'], $r['Desktop'], $r['Laptop'], $r['WOW'], $r['NUC'], $r['Total'], $r['Average'], $r['Min'], $r['Max'])
            $totDesktop += $r['Desktop']
            $totLaptop += $r['Laptop']
            $totWOW += $r['WOW']
            $totNUC += $r['NUC']
            $totAll += $r['Total']
        }
        Write-Host $rule
        $durations = @($Rows | ForEach-Object { $_.Durations })
        $summary = Get-BuildDurationSummary -Minutes $durations
        Write-StatsLine ($format -f 'Total', $totDesktop, $totLaptop, $totWOW, $totNUC, $totAll, $summary.Average, $summary.Min, $summary.Max)
        $missing = ($Rows | ForEach-Object { $_.MissingDuration } | Measure-Object -Sum).Sum
        if ($missing -gt 0) { Write-StatsLine ('Working-time samples exclude {0} dispatched record(s) with missing or invalid induction times.' -f $missing) }
        Write-Host ''
    }

    function Get-StatsRows {
        <#
        .SYNOPSIS
            Build daily aggregates from the enclosing already-eligible dispatched records.
        .PARAMETER InputRecords
            Overall or site-filtered proven dispatch records.
        .PARAMETER From
            Inclusive local start date, with no lower bound by default.
        .PARAMETER Until
            Exclusive local end date, with no upper bound by default.
        .OUTPUTS
            Newest-first daily summary rows with matching counts and duration samples.
        #>
        param($InputRecords, [datetime]$From = [datetime]::MinValue, [datetime]$Until = [datetime]::MaxValue)
        $rows = @(Get-DispatchStatsRows -Records @($InputRecords) | Where-Object { $_.SortDate -ge $From -and $_.SortDate -lt $Until })
        return $rows
    }

    $siteCodes = @($recordsLocal | ForEach-Object { $_['SiteCode'] } | Where-Object { $_ } | Sort-Object -Unique)
    if (-not $CurrentSiteCode -and $siteCodes.Count -eq 1) { $CurrentSiteCode = $siteCodes[0] }
    if (-not $CurrentSiteCode) {
        Write-StatsLine 'No current site was supplied. Select a current site in Session and Script Settings before opening statistics.'
        $null = Read-ValidatedInput -Prompt '[0] Return to main menu' -Default '0' -Type Choice -Choices @('0')
        return
    }
    $currentMonday = $AsOf.Date.AddDays( - (([int]$AsOf.DayOfWeek + 6) % 7))
    $monday = $currentMonday
    $selectedSite = $CurrentSiteCode
    $view = 'Current'
    while ($true) {
        Show-ScriptScreen -Title 'My Stats and Progress'
        $period = '{0} to {1} (Monday-Sunday)' -f $monday.ToString('d/M/yyyy'), $monday.AddDays(6).ToString('d/M/yyyy')
        $siteRecords = @($recordsLocal | Where-Object { $_.SiteCode -eq $selectedSite })
        if ($view -eq 'Previous') {
            Show-StatsTable -Rows (Get-StatsRows -InputRecords $recordsLocal -From $monday -Until $monday.AddDays(7)) -Title ('Week overall, all sites: {0}' -f $period)
            foreach ($siteCode in $siteCodes) {
                $rows = @(Get-StatsRows -InputRecords @($recordsLocal | Where-Object { $_.SiteCode -eq $siteCode }) -From $monday -Until $monday.AddDays(7))
                if ($rows.Count) { Show-StatsTable -Rows $rows -Title ('Week by site: {0}; {1}' -f $siteCode, $period) }
            }
        }
        else {
            if ($view -ne 'SiteOverall') {
                Show-StatsTable -Rows (Get-StatsRows -InputRecords $siteRecords -From $currentMonday -Until $AsOf.Date.AddDays(1)) -Title ('Week to date, site {0}: {1}' -f $selectedSite, $period)
            }
            if ($view -ne 'SiteWeek') { Show-StatsTable -Rows (Get-StatsRows -InputRecords $siteRecords) -Title ('Overall, site {0} (all dispatch dates)' -f $selectedSite) }
        }
        Write-StatsLine 'P. Previous week (all sites, with site breakdown)'
        Write-StatsLine 'C. Current week and overall for the current site'
        $choices = @('0', 'P', 'C')
        if ($monday -lt $currentMonday) { Write-StatsLine 'N. Next week'; $choices += 'N' }
        if ($siteCodes.Count -ge 2) {
            Write-StatsLine 'S. Current week for a selected site'
            Write-StatsLine 'O. Overall for a selected site'
            $choices += @('S', 'O')
        }
        Write-StatsLine '0. Return to main menu'
        $choice = Read-ValidatedInput -Prompt 'Statistics view' -Default '0' -Type Choice -Choices $choices
        switch ($choice.ToUpperInvariant()) {
            '0' { return }
            'P' { $monday = $monday.AddDays(-7); $view = 'Previous' }
            'N' { $monday = $monday.AddDays(7); $view = if ($monday -eq $currentMonday) { 'Current' } else { 'Previous' }; $selectedSite = $CurrentSiteCode }
            'C' { $monday = $currentMonday; $selectedSite = $CurrentSiteCode; $view = 'Current' }
            { $_ -in @('S', 'O') } {
                foreach ($siteCode in $siteCodes) { Write-StatsLine ('{0}. Site {0}' -f $siteCode) }
                $site = Read-ValidatedInput -Prompt 'Site code, or 0 to return' -Default '0' -Type Choice -Choices (@('0') + $siteCodes)
                if ($site -ne '0') {
                    $selectedSite = $site; $monday = $currentMonday
                    $view = if ($choice -ieq 'S') { 'SiteWeek' } else { 'SiteOverall' }
                }
            }
        }
    }
}

function Get-SessionReportRows {
    <#
    .SYNOPSIS
        Project current local records without changing workflow or dispatch evidence.
    .PARAMETER Records
        Current-session records, including removed and unfinished work; stable IDs are deduplicated.
    .OUTPUTS
        Ordered report objects. Dispatch uses existing evidence guards, not completed status alone.
    #>
    param([AllowEmptyCollection()][object[]]$Records = @())
    $seen = @{}
    $rows = @()
    foreach ($record in $Records) {
        if ($record -isnot [System.Collections.IDictionary] -or -not $record.RecordId -or $seen.ContainsKey([string]$record.RecordId)) { continue }
        $seen[[string]$record.RecordId] = $true
        $dispatch = Get-DeviceDispatchDate -Device $record
        $started = ConvertTo-RecordDate -Value $record.StartedAt
        $minutes = ''
        if ($dispatch -ne [datetime]::MinValue -and $started -ne [datetime]::MinValue -and $dispatch.ToUniversalTime() -ge $started.ToUniversalTime()) {
            $minutes = (Get-ImagingWorkingMinutes -Device $record -End $dispatch).ToString('0.##', [Globalization.CultureInfo]::InvariantCulture)
        }
        $evidence = @()
        if ($record.Steps -is [System.Collections.IDictionary]) {
            foreach ($stepId in @($record.Steps.Keys | Sort-Object)) {
                $step = $record.Steps[$stepId]
                $state = if ($step -is [System.Collections.IDictionary] -and $step.CompletionState) { [string]$step.CompletionState } else { 'Unknown' }
                $evidence += '{0}={1}' -f $stepId, $state
            }
        }
        $rows += [pscustomobject][ordered]@{
            Mode = if ($Script:Runtime.IsDemoMode) { 'Demo' } else { 'Live' }
            RecordId = [string]$record.RecordId; Serial = [string]$record.Serial; ConfigItem = [string]$record.ConfigItem
            Site = [string]$record.SiteCode; DeviceType = [string]$record.DeviceType; Status = [string]$record.Status
            StartedAt = if ($started -eq [datetime]::MinValue) { '' } else { $started.ToString('o') }
            DispatchRecorded = ($dispatch -ne [datetime]::MinValue)
            DispatchedAt = if ($dispatch -eq [datetime]::MinValue) { '' } else { $dispatch.ToString('o') }
            WorkingMinutes = $minutes; StepEvidence = $evidence -join '; '
            IntuneHostName = [string]$record.IntuneInventory.IntuneHostName
            EthernetMacAddress = [string]$record.IntuneInventory.EthernetMacAddress
            WiFiMacAddress = [string]$record.IntuneInventory.WiFiMacAddress
            EntraDeviceId = [string]$record.IntuneInventory.EntraDeviceId
            PrimaryUser = [string]$record.IntuneInventory.PrimaryUser
            OperatingSystem = [string]$record.IntuneInventory.OperatingSystem
            OsVersion = [string]$record.IntuneInventory.OsVersion
            OsRelease = [string]$record.IntuneInventory.OsRelease
            InventoryStatus = [string]$record.IntuneInventory.Status
            InventoryCheckedAt = [string]$record.IntuneInventory.CheckedAt
            InventoryManagedDeviceId = [string]$record.IntuneInventory.ManagedDeviceId
            InventoryBuildCycleId = [string]$record.IntuneInventory.BuildCycleId
        }
    }
    return , @($rows | Sort-Object { [string]$_.Serial }, { [string]$_.RecordId })
}

function ConvertTo-SessionReportContent {
    <#
    .SYNOPSIS
        Encode a detached report as spreadsheet-safe CSV or script-free accessible HTML.
    .PARAMETER Rows
        Objects returned by Get-SessionReportRows; original property values are not changed.
    .PARAMETER Format
        CSV prefixes potentially executable spreadsheet text; HTML encodes every dynamic cell.
    .OUTPUTS
        Complete document string, or empty text for an empty report. No files are written.
    #>
    param([AllowEmptyCollection()][object[]]$Rows = @(), [ValidateSet('CSV', 'HTML')][string]$Format = 'CSV')
    if (-not $Rows.Count) { return '' }
    $columns = @($Rows[0].PSObject.Properties.Name)
    if ($Format -eq 'CSV') {
        $safeRows = foreach ($row in $Rows) {
            $values = [ordered]@{}
            foreach ($column in $columns) {
                $value = $row.$column
                if ($value -is [string] -and ($value -match '^\s*[=+\-@]' -or $value -match '^[\t\r\n]')) { $value = "'" + $value }
                $values[$column] = $value
            }
            [pscustomobject]$values
        }
        return (@($safeRows | ConvertTo-Csv -NoTypeInformation) -join [Environment]::NewLine)
    }
    # Built in one pass rather than with "+=", which copies the whole array for every table cell.
    $lines = @(
        '<!DOCTYPE html><html lang="en-AU"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1">'
        '<title>Autopilot Express session report</title><style>body{font-family:Verdana,sans-serif;margin:24px;color:#222;background:#fff}table{border-collapse:collapse;width:100%}th,td{border:1px solid #777;padding:8px;text-align:left;overflow-wrap:anywhere}th{background:#eee}.report{overflow-x:auto}</style></head><body>'
        '<h1>Autopilot Express session report</h1><p>Current session only. Recorded dispatch does not establish verified completion. Step evidence retains Submitted, Verified, TechnicianConfirmed and Simulated distinctions. Working minutes use the current saved work pattern.</p>'
        '<div class="report" tabindex="0" role="region" aria-label="Device session report"><table><caption>Current local device records</caption><thead><tr>'
        foreach ($column in $columns) { '<th scope="col">{0}</th>' -f [Net.WebUtility]::HtmlEncode($column) }
        '</tr></thead><tbody>'
        foreach ($row in $Rows) {
            '<tr>'
            foreach ($column in $columns) { '<td>{0}</td>' -f [Net.WebUtility]::HtmlEncode([string]$row.$column) }
            '</tr>'
        }
        '</tbody></table></div></body></html>'
    )
    return $lines -join [Environment]::NewLine
}

function Export-SessionReport {
    <#
    .SYNOPSIS
        Save a unique current-session report outside operational evidence storage.
    .PARAMETER Rows
        Detached report projection; empty input performs no directory or file creation.
    .PARAMETER Format
        Requested CSV or HTML document format.
    .OUTPUTS
        Verified report path, or null for no data. Existing reports are not overwritten.
    #>
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Low')]
    param([AllowEmptyCollection()][object[]]$Rows = @(), [ValidateSet('CSV', 'HTML')][string]$Format = 'CSV')
    if (-not $Rows.Count) { return $null }
    $base = if (-not [string]::IsNullOrWhiteSpace($env:LOCALAPPDATA)) { $env:LOCALAPPDATA } else { $env:TEMP }
    if ([string]::IsNullOrWhiteSpace($base)) { throw 'No local report directory is available.' }
    $modeName = if ($Script:Runtime.IsDemoMode) { 'demo' } else { 'live' }
    $userName = $env:USERNAME -replace '[^A-Za-z0-9_.-]', '_'
    $fileName = 'autopilot-session-{0}-{1}-{2}-{3}.{4}' -f $modeName, $userName, (Get-Date -Format 'yyyyMMdd-HHmmss'), [guid]::NewGuid().ToString('N'), $Format.ToLowerInvariant()
    $path = Join-Path (Join-Path $base 'PowerShellScriptingNew/AutopilotExpress/reports') $fileName
    if (Test-Path -LiteralPath $path) { throw 'The report destination already exists; no report was overwritten.' }
    $content = ConvertTo-SessionReportContent -Rows $Rows -Format $Format
    if (-not $PSCmdlet.ShouldProcess($path, 'Export current session report')) { return $null }
    Write-Utf8File -Path $path -Content $content
    return $path
}

function Show-SessionReportExport {
    <#
    .SYNOPSIS
        Preview and explicitly confirm a local export, then return to Data Settings.
    .PARAMETER Records
        Current session container only; no tenant, archive or shared audit discovery occurs.
    .OUTPUTS
        Host output and a verified report file after confirmation. Workflow evidence is untouched.
    #>
    param([Parameter(Mandatory)][hashtable]$Records)
    Show-ScriptScreen -Title 'Export Session Report'
    $rows = Get-SessionReportRows -Records @($Records.Value)
    if (-not $rows.Count) {
        Write-Host 'No current device records; no report was exported.'
        Show-ReturnToMainMenu
        return
    }
    Write-Host ('Current session: {0} device record(s), including unfinished and removed work.' -f $rows.Count)
    Write-Host 'Reports contain device identifiers. Store and share them only with authorised recipients.'
    $threshold = ConvertTo-OptionalInteger -Value $Script:Config.ReportWarningRowCount
    if ($null -eq $threshold -or $threshold -lt 1) { throw 'ReportWarningRowCount must be a positive integer.' }
    if ($rows.Count -gt $threshold) { Write-Host ('Large export: {0} rows exceeds the configured warning threshold {1}. Consider archiving completed sessions before future exports.' -f $rows.Count, $threshold) }
    Write-Host '1. Export CSV'
    Write-Host '2. Export HTML'
    Write-Host '0. Return to Data Settings'
    $choice = Read-ValidatedInput -Prompt 'Report format ([0] Cancel)' -Default '0' -Type Choice -Choices @('0', '1', '2')
    if ($choice -eq '0') { return }
    $format = if ($choice -eq '1') { 'CSV' } else { 'HTML' }
    $confirm = Read-ValidatedInput -Prompt ('Export {0} rows as {1}? [Y] Yes [N] No' -f $rows.Count, $format) -Default 'N' -Type Choice -Choices @('Y', 'N')
    if ($confirm -ine 'Y') { return }
    try {
        $path = Export-SessionReport -Rows $rows -Format $format
        if ($path) {
            Write-AutopilotExpressLog -Message ('Exported {0} session report with {1} rows: {2}' -f $format, $rows.Count, $path)
            Write-Host ('Report saved: {0}' -f $path)
        }
        else { Write-Host 'No report was exported.' }
    }
    catch {
        Write-AutopilotExpressLog -Message 'Session report export failed. Workflow evidence was not changed; retain any report recovery artefacts.' -Level ERROR
        Write-Host ('Report export failed: {0}' -f $_.Exception.Message)
    }
    Show-ReturnToMainMenu
}

function Read-PagedInformation {
    <#
    .SYNOPSIS
        Reuse the Steps List text pager for caller-owned information navigation.
    .PARAMETER Title
        Screen name retained across pages and window resizes.
    .PARAMETER Lines
        Plain terminal text, not Markdown markup.
    .PARAMETER Options
        Additional command dictionaries containing Code and Label.
    .PARAMETER ReturnDestination
        Visible caller name; this helper never redirects to another menu.
    .OUTPUTS
        Selected command code; zero returns to the calling screen.
    #>
    param(
        [Parameter(Mandatory)][ValidateNotNullOrEmpty()][string]$Title,
        [AllowEmptyCollection()][string[]]$Lines = @(),
        [AllowEmptyCollection()][hashtable[]]$Options = @(),
        [ValidateSet('main menu', 'About', 'Build bench', 'Device Commands', 'Session and Script Settings', 'Data Settings', 'Script Information', 'Work Pattern Editor')][string]$ReturnDestination = 'main menu'
    )
    if ($ReturnDestination -eq 'main menu' -and $Script:NavigationMenu -in @('Devices', 'Settings', 'Data', 'Information')) { $ReturnDestination = Get-NavigationMenuTitle }
    $pageIndex = 0
    while ($true) {
        $pages = Get-ScreenTextPage -Lines $Lines -Viewport (Get-TerminalViewport) -Title $Title
        $pageIndex = [Math]::Min($pageIndex, $pages.Count - 1)
        Show-ScriptScreen -Title ('{0} | Page {1} of {2}' -f $Title, ($pageIndex + 1), $pages.Count)
        foreach ($line in $pages[$pageIndex].Lines) { Write-Host $line }
        Write-Host ''
        $choices = @('0') + @($Options | ForEach-Object { $_.Code })
        if ($pageIndex -lt $pages.Count - 1) { Write-Host '>. Next page'; $choices += '>' }
        if ($pageIndex -gt 0) { Write-Host '<. Previous page'; $choices += '<' }
        foreach ($option in $Options) { Write-Host ('{0}. {1}' -f $option.Code, $option.Label) }
        Write-Host ('0. Return to {0}' -f $ReturnDestination)
        $choice = Read-ValidatedInput -Prompt 'Choose an option' -Default '0' -Type Choice -Choices $choices
        if ($choice -eq '>') { $pageIndex++; continue }
        if ($choice -eq '<') { $pageIndex--; continue }
        return $choice
    }
}

function Show-AboutScript {
    <#
    .SYNOPSIS
        Display editable script information without accessing tenant services.
    .DESCRIPTION
        Render the approved About copy as terminal text. Optional help launches
        remain local and return to this screen without changing session evidence.
    .OUTPUTS
        Host pages only; the explicit README command opens the maintained guide without waiting.
    #>
    $lines = @(
        'Autopilot Express'
        'Helping technical staff prepare Windows PCs at scale, within a Microsoft Intune environment.'
        ''
        'Version: 0.3.1 - Test release, released 14/10/2026; use at your own risk.'
        'Designed and developed by: Michael Harris'
        'Licensing: see repository LICENSE.'
        'Documentation: README.md'
        ''
        'Key features'
        '- Maintain and track your build bench; prepare multiple PCs and track progress by machine.'
        '- Support barcode-scanner input.'
        '- Use Microsoft Graph to simplify repeat Intune tasks and reduce portal navigation.'
        '- Apply a consistent ordered manifest workflow.'
        '- Provide recovery and restart assistance for OOBE failures, not automatic tenant rollback.'
        '- Retain device activity, history and action evidence; prompt for physical observations.'
        '- Report dispatched-device work rates and induction-to-dispatch elapsed times.'
        ''
        'Required permissions'
        '- Device: approved permission to run PowerShell scripts; this script does not bypass policy.'
        '- Intune: approved device management permissions for the intended actions.'
        '- Microsoft 365/Entra: required Microsoft Graph permissions and tenant roles.'
        ''
        'Possible enhancements (planned)'
        '- Collaborative multi-technician workbenches and shared preparation data.'
        '- Approved remote updates, application installation and device restarts.'
        '- Generate and remotely load device build certificates.'
        '- Update your organisation''s CMDB with one command.'
        '- Export information for device whitelisting with one command.'
        ''
        'Test release, not production-approved. Live requires separate approval and physical acceptance.'
        'Supports PowerShell 7 and Windows PowerShell 5.1. Demo performs no tenant actions.'
        'Shared storage remains disabled; physical work stays with the technician.'
    )
    $options = @(@{ Code = '9'; Label = 'Enhancements and Questions' }, @{ Code = 'R'; Label = 'Open README in Notepad' })
    while ($true) {
        $choice = Read-PagedInformation -Title 'About This Script' -Lines $lines -Options $options
        if ($choice -eq '0') { return }
        if ($choice -eq '9') { Show-EnhancementsQuestions -ReturnDestination About; continue }
        try {
            $readmePath = Get-AutopilotExpressDefinitionPath -FileName 'README.md'
            if (-not (Test-Path -LiteralPath $readmePath -PathType Leaf)) { throw 'The local README is unavailable; restore the complete script/documentation bundle.' }
            Start-Process -FilePath 'notepad.exe' -ArgumentList ('"{0}"' -f $readmePath) -ErrorAction Stop
        }
        catch {
            $lines = @(('Documentation could not be opened: {0}' -f $_.Exception.Message), '') + @($lines | Where-Object { $_ -notlike 'Documentation could not be opened:*' })
        }
    }
}

function Show-EnhancementsQuestions {
    <#
    .SYNOPSIS
        Display the status-labelled enhancement catalogue through the shared pager.
    .PARAMETER ReturnDestination
        Caller name used for accessible return guidance; does not activate planned features.
    .OUTPUTS
        Host output only; returns to its caller, including About, after paging or cancellation.
    #>
    param([ValidateSet('main menu', 'About', 'Script Information')][string]$ReturnDestination = 'main menu')
    $lines = @('Potential Enhancements')
    foreach ($enhancement in $Script:EnhancementManifest) {
        $lines += ('{0}. {1} [{2}]' -f $enhancement.Id, $enhancement.Title, $enhancement.Status)
        if ($enhancement.Description) { $lines += ('    {0}' -f $enhancement.Description) }
    }
    $lines += @('', 'Clarifying Questions', 'A. Required retention period for device build history?', 'B. Need encryption at rest for JSON data files?', 'C. External CMDB column mapping examples?', 'D. Preferred approach for roll-up (central share vs Graph storage)?')
    [void](Read-PagedInformation -Title 'Enhancements and Questions' -Lines $lines -ReturnDestination $ReturnDestination)
}

# ===== Build Bench =====
#endregion
#region Session Setup, Definitions and Graph Transport
$Script:BuildBench = Get-DefaultBuildBenchState
# Private copies of the records and audit files this session last saved (see Get-VerifiedSaveCopy).
$Script:LocalSaveCache = @{}

function Save-BuildBenchState {
    <#
    .SYNOPSIS
        Save current bench state unless an unresolved checkpoint blocks it.
    .PARAMETER CheckpointToken
        Internal token accepted only within the owning record writer's save scope.
    .PARAMETER ProposedContent
        Exact staged bench JSON; requires the active token and matching marker.
    .DESCRIPTION
        Standalone saves use the current bench. All guard and writer errors propagate.
    .OUTPUTS
        None. Validates/persists bench state through the guarded UTF-8 writer.
    #>
    param([string]$CheckpointToken, [string]$ProposedContent)
    try {
        $activeToken = Get-Variable -Name LocalCheckpointToken -Scope Script -ErrorAction SilentlyContinue
        if ($CheckpointToken -and $null -ne $activeToken -and $activeToken.Value -ceq $CheckpointToken) {
            $marker = Get-Content -LiteralPath (Get-LocalCheckpointPath) -Raw -ErrorAction Stop | ConvertFrom-Json -ErrorAction Stop
            if ($marker.Token -cne $CheckpointToken -or $marker.BenchJson -cne $ProposedContent) { throw 'Local checkpoint ownership or bench proposal changed.' }
        }
        else {
            if ($PSBoundParameters.ContainsKey('CheckpointToken') -or $PSBoundParameters.ContainsKey('ProposedContent')) {
                throw 'Staged bench saves require the active local checkpoint token.'
            }
            Assert-LocalCheckpointState
        }
        $json = if ($PSBoundParameters.ContainsKey('ProposedContent')) { $ProposedContent } else { $Script:BuildBench | ConvertTo-Json -Depth 6 }
        if ($Script:SessionFileNamesEnabled) { Initialize-SessionFileIndex }
        Write-Utf8File -Path (Get-BuildBenchStatePath) -Content $json
    }
    catch {
        Write-AutopilotExpressLog -Message ('Failed to save build bench: {0}' -f $_.Exception.Message) -Level 'ERROR'
        throw
    }
}

function Get-BuildBenchState {
    <#
    .SYNOPSIS
        Load and validate the current session's linked bench state.
    .OUTPUTS
        Normalised bench dictionary, or a fresh inactive default when no file exists.
        Malformed or conflicting existing evidence throws instead of silently resetting it.
    #>
    $path = Get-BuildBenchStatePath
    if (Test-Path $path) {
        try {
            $state = Get-Content -Raw -Path $path -ErrorAction Stop | ConvertFrom-Json -ErrorAction Stop
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
            Assert-BenchPositionIdentity -Positions $normalisedState.Positions
            return $normalisedState
        }
        catch {
            Write-AutopilotExpressLog -Message ('Failed to load build bench state: {0}' -f $_.Exception.Message) -Level 'ERROR'
            throw
        }
    }
    return Get-DefaultBuildBenchState
}

function Show-SessionArchive {
    <#
    .SYNOPSIS
        Select and archive this user's current-mode resumable session without deleting history.
    .DESCRIPTION
        The current storage schema has one device/bench pair per user and mode.
        No defaults select a session; No and CANCEL preserve it. CLEAR confirms
        removal from active use. Audit, receipts, other modes/users and archives remain.
    .OUTPUTS
        True only after the selected session was archived successfully. Errors propagate.
    .PARAMETER Records
        Current user/mode record container; other users, audit and recent accounts are retained.
    #>
    param([Parameter(Mandatory)][hashtable]$Records)
    Show-ScriptScreen -Title 'Archive Saved Sessions'
    $paths = @((Get-UserDataFilePath), (Get-BuildBenchStatePath))
    $hasSavedFiles = @($paths | Where-Object { Test-Path -LiteralPath $_ }).Count -gt 0
    if (-not $hasSavedFiles -and -not @($Records.Value).Count -and -not $Script:BuildBench.Active) {
        Write-Host 'No current-mode session is available to archive. Already archived history is not listed.'
        Show-ReturnToMainMenu
        return $false
    }
    Write-Host ('1. {0} session | User: {1} | Devices: {2} | Bench active: {3}' -f $Script:Runtime.Mode, $env:USERNAME, @($Records.Value).Count, $Script:BuildBench.Active)
    foreach ($path in $paths) { Write-Host ('   Active file: {0}' -f $path) }
    Write-Host '0. Cancel without changes'
    $selection = Read-ValidatedInput -Prompt 'Select session number ([0] Cancel)' -Default '0' -Type Choice -Choices @('0', '1')
    if ($selection -eq '0') { return $false }
    Write-Host 'WARNING: This ends the active session and clears its device list and bench from this view. A new session will be set up next.'
    Write-Host 'Files are archived, not permanently deleted. Audit history, sync receipts, other users/modes and existing archives are not removed. No tenant/device change is made.'
    $confirm = Read-ValidatedInput -Prompt 'Archive this session? [Y] Yes [N] No' -Default 'N' -Type Choice -Choices @('Y', 'N')
    if ($confirm -ne 'Y') { return $false }
    $clear = Read-ValidatedInput -Prompt 'Type CLEAR to archive, or CANCEL to keep the session' -Default 'CANCEL' -Type Choice -Choices @('CLEAR', 'CANCEL')
    if ($clear -ne 'CLEAR') { return $false }
    Assert-LocalStorageWriteState
    Write-UserDeviceRecords -Records $Records.Value
    $Records.Value = Reset-CurrentSessionState
    Write-AutopilotExpressLog -Message 'Current-mode device and bench session archived; starting new session setup. Audit and receipt evidence retained.' -Level INFO
    return $true
}

function Initialize-SessionState {
    <#
    .SYNOPSIS
        Offer guarded current-session resume or archive before loading records.
    .DESCRIPTION
        Successful reservation recovery resumes the existing saved files without an
        archive decision. The normal loaders still validate identities and evidence;
        this does not replay actions or bypass checkpoint/write-state guards.
    .OUTPUTS
        Current record array or empty new-session array. Never authenticates or replays actions.
    #>
    $Script:SessionStartedAt = if ($Script:ImagingSessionLoadedAt) { $Script:ImagingSessionLoadedAt } else { Get-Date }
    Sync-RepoStateFilesToActiveStorage
    $hasUserData = Test-Path (Get-UserDataFilePath)
    $hasBenchData = Test-Path (Get-BuildBenchStatePath)
    if (-not $hasUserData -and -not $hasBenchData) {
        $Script:BuildBench = Get-DefaultBuildBenchState
        return , @()
    }
    $lastUpdated = Get-SessionLastUpdated
    $resumePrompt = ('Resume existing {0} session last updated {1}? [Y] Yes [N] No' -f $Script:Runtime.ModeDisplayName, $lastUpdated.ToString('yyyy-MM-dd HH:mm:ss'))
    $resumeExisting = if ($Script:ResumeRecoveredSession) {
        Write-AutopilotExpressLog -Message 'Resuming the recovered saved session without archiving or resetting its evidence.' -Level INFO
        'Y'
    }
    else { Read-ValidatedInput -Prompt $resumePrompt -Default 'Y' -Type 'Choice' -Choices @('Y', 'N') }
    if ($resumeExisting.ToUpper() -ne 'Y') {
        Write-AutopilotExpressLog -Message ('Archiving existing {0} session and starting a clean session.' -f $Script:Runtime.ModeDisplayName) -Level 'INFO'
        return , (Reset-CurrentSessionState)
    }
    Write-AutopilotExpressLog -Message 'Session resume: loading saved bench state.' -Level INFO
    $Script:BuildBench = Get-BuildBenchState
    Write-AutopilotExpressLog -Message 'Session resume: loading saved device records.' -Level INFO
    $loadedRecords = Get-UserDeviceRecords
    Write-AutopilotExpressLog -Message 'Session resume: registering imaging-session metadata.' -Level INFO
    if (Register-ImagingSessionStart -Records $loadedRecords -Timestamp $Script:SessionStartedAt) {
        Write-AutopilotExpressLog -Message 'Session resume: saving imaging-session metadata through the guarded record writer.' -Level INFO
        Write-UserDeviceRecords -Records $loadedRecords
    }
    Write-AutopilotExpressLog -Message 'Session resume: saved-state loading and metadata registration completed.' -Level INFO
    return , $loadedRecords
}

function Get-SessionDefaultSiteCode {
    <#
    .SYNOPSIS
        Choose the initial site from bench, recent records or the configured first site.
    .PARAMETER Records
        Loaded record array used only when bench context supplies no site.
    .OUTPUTS
        Site code suggestion; no record or tenant mutation.
    #>
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
    <#
    .SYNOPSIS
        Read the configured directory-result limit, defaulting to 15.
    .OUTPUTS
        Integer search limit; runtime validation owns configuration acceptance.
    #>
    if ($Script:RuntimeConfig.autopilot.directorySearchLimit) { return [int]$Script:RuntimeConfig.autopilot.directorySearchLimit }
    return 15
}

function Get-ConfiguredDirectorySearchPageLimit {
    <#
    .SYNOPSIS
        Returns the bounded number of Graph pages permitted per user search.
    .DESCRIPTION
        The optional autopilot.directorySearchPageLimit defaults to ten pages.
        Rejects invalid values rather than allowing an unbounded directory scan.
    .OUTPUTS
        Integer from 1 to 100. Throws when a configured value is invalid.
    #>
    $configuredValue = $Script:RuntimeConfig.autopilot.directorySearchPageLimit
    if ($null -eq $configuredValue) { return 10 }
    if ([string]$configuredValue -notmatch '^[1-9][0-9]{0,2}$' -or [int]$configuredValue -gt 100) {
        throw 'autopilot.directorySearchPageLimit must be an integer from 1 to 100.'
    }
    return [int]$configuredValue
}

function Get-ConfiguredRecentUserLimit {
    <#
    .SYNOPSIS
        Read the configured recent-account limit, defaulting to eight.
    .OUTPUTS
        Integer history limit; does not load or persist account identities.
    #>
    if ($Script:RuntimeConfig.autopilot.recentUsersLimit) { return [int]$Script:RuntimeConfig.autopilot.recentUsersLimit }
    return 8
}

function Get-ConfiguredDeploymentProfileDisplayName {
    <#
    .SYNOPSIS
        Read the required deployment-profile display name without guessing a tenant value.
    .OUTPUTS
        Configured string, or empty string when absent.
    #>
    if ($Script:RuntimeConfig.autopilot.deploymentProfileDisplayName) { return [string]$Script:RuntimeConfig.autopilot.deploymentProfileDisplayName }
    return ''
}

function Get-ConfiguredPreProvisioningGroupDisplayName {
    <#
    .SYNOPSIS
        Read the configured pre-provisioning group name for exact resolution.
    .OUTPUTS
        Display-name string or empty string; name alone is not verified group identity.
    #>
    if ($Script:RuntimeConfig.autopilot.preProvisioningGroupDisplayName) { return [string]$Script:RuntimeConfig.autopilot.preProvisioningGroupDisplayName }
    return ''
}

function Get-ConfiguredMissingSerialHandoffNote {
    <#
    .SYNOPSIS
        Read missing-serial guidance without assuming an import completed.
    .OUTPUTS
        Configured guidance, or the external-upload compatibility message.
    #>
    if ($Script:RuntimeConfig.autopilot.missingSerialHandoffNote) { return [string]$Script:RuntimeConfig.autopilot.missingSerialHandoffNote }
    return 'Use the external Autopilot upload guide when the serial is not yet present in Autopilot.'
}

function Get-ConfiguredTechnicianPrefixes {
    <#
    .SYNOPSIS
        Read permitted account-name prefixes for technician selection.
    .OUTPUTS
        Prefix collection, defaulting to C and E; not role or authorisation proof.
    #>
    $prefixes = @($Script:RuntimeConfig.autopilot.technicianUpnPrefixes)
    if ($prefixes.Count -gt 0) { return $prefixes }
    return @('C', 'E')
}

function Get-ConfiguredGraphScopes {
    <#
    .SYNOPSIS
        Read the configured delegated scope request without adding permissions at runtime.
    .OUTPUTS
        Scope collection with legacy fallback; requested scopes do not prove consent.
    #>
    $scopes = @($Script:RuntimeConfig.graph.requiredScopes)
    if ($null -ne $Script:RuntimeConfig.graph.requiredScopes) { return $scopes }
    return @(
        'DeviceManagementServiceConfig.ReadWrite.All',
        'DeviceManagementManagedDevices.ReadWrite.All',
        'DeviceManagementManagedDevices.PrivilegedOperations.All',
        'DeviceManagementScripts.Read.All',
        'Group.ReadWrite.All',
        'GroupMember.ReadWrite.All',
        'User.Read.All',
        'Directory.Read.All'
    )
}

function Get-ConfiguredGraphModules {
    <#
    .SYNOPSIS
        Read the Graph SDK modules needed by the configured workflow.
    .OUTPUTS
        Module-name collection, defaulting to Authentication and Enrollment.
    #>
    $modules = @($Script:RuntimeConfig.graph.requiredModules)
    if ($modules.Count -gt 0) { return $modules }
    return @('Microsoft.Graph.Authentication', 'Microsoft.Graph.DeviceManagement.Enrollment')
}

function Get-EmptyGraphSession {
    <#
    .SYNOPSIS
        Initialise disconnected Graph state without retaining tokens or SDK contexts.
    .OUTPUTS
        Ordered session dictionary with empty account, tenant, scope and capability evidence.
    #>
    return [ordered]@{
        Connected         = $false
        RequiresReconnect = $false
        IsSimulated       = $Script:Runtime.IsDemoMode
        Account           = ''
        DisplayName       = ''
        UserId            = ''
        TenantId          = ''
        Scopes            = @()
        CapabilityResults = @()
    }
}

function Get-EnabledManifestSteps {
    <#
    .SYNOPSIS
        Return enabled steps in validated manifest order.
    .OUTPUTS
        Step array; does not evaluate per-device eligibility or execute handlers.
    #>
    return @($Script:StepManifest | Where-Object { $_.Enabled })
}

function Get-ManifestStepDefinition {
    <#
    .SYNOPSIS
        Resolve a manifest ID without confusing its display code with storage identity.
    .PARAMETER StepId
        Stored identity from the validated manifest.
    .OUTPUTS
        First matching step, or null; no workflow state changes.
    #>
    param([Parameter(Mandatory)][string]$StepId)
    return $Script:StepManifest | Where-Object { $_.Id -eq $StepId } | Select-Object -First 1
}

function Get-ManifestActionStepId {
    <#
    .SYNOPSIS
        Resolve a safety-critical action to its current enabled manifest step ID.
    .PARAMETER ActionName
        Semantic action role, independent of technician-facing step labels.
    .OUTPUTS
        Unique step ID. Missing or ambiguous roles throw before state changes.
    #>
    param([Parameter(Mandatory)][ValidateNotNullOrEmpty()][string]$ActionName)
    $definitions = @(Get-EnabledManifestSteps | Where-Object { $_.ActionName -eq $ActionName })
    if ($definitions.Count -ne 1 -or [string]::IsNullOrWhiteSpace([string]$definitions[0].Id)) {
        throw ('An enabled unique manifest step is required for action {0}.' -f $ActionName)
    }
    return [string]$definitions[0].Id
}

function Read-JsonDefinitionFile {
    <#
    .SYNOPSIS
        Read a required JSON definition and normalise its object representation.
    .PARAMETER Path
        Authorised runtime or manifest file path.
    .PARAMETER Description
        Definition name used in actionable load errors.
    .OUTPUTS
        Normalised definition; missing, empty or malformed content throws without rewriting it.
    #>
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

function Test-ManifestDependencyGraph {
    <#
    .SYNOPSIS
        Reject duplicate, missing, self-referencing or cyclic workflow dependencies.
    .PARAMETER Steps
        Complete proposed manifest step collection, including conditional actions.
    .OUTPUTS
        None. Invalid graphs throw before workflow execution or definition promotion.
    #>
    param([Parameter(Mandatory)][object[]]$Steps)

    $issues = @()
    $stepsById = @{}
    foreach ($step in $Steps) {
        $stepId = [string]$step.Id
        if ([string]::IsNullOrWhiteSpace($stepId)) {
            $issues += 'Each manifest step must have an ID.'
            continue
        }
        if ($null -ne $stepsById[$stepId]) {
            $issues += ('Manifest step ID {0} is duplicated.' -f $stepId)
            continue
        }
        $stepsById[$stepId] = $step
    }

    foreach ($stepId in $stepsById.Keys) {
        $activationRequirement = [string]$stepsById[$stepId].ActivationRequirement
        if ($activationRequirement -notin @('None', 'RecoveryMode')) {
            $issues += ('Manifest step {0} has unsupported activation requirement {1}.' -f $stepId, $activationRequirement)
        }
        $prerequisiteIds = @($stepsById[$stepId].PrerequisiteStepIds)
        $duplicatePrerequisites = @($prerequisiteIds | Group-Object | Where-Object { $_.Count -gt 1 } | Select-Object -ExpandProperty Name)
        if ($duplicatePrerequisites.Count -gt 0) {
            $issues += ('Manifest step {0} repeats prerequisite(s): {1}.' -f $stepId, ($duplicatePrerequisites -join ', '))
        }
        foreach ($prerequisiteId in $prerequisiteIds) {
            if ($prerequisiteId -eq $stepId) {
                $issues += ('Manifest step {0} cannot depend on itself.' -f $stepId)
            }
            elseif ($null -eq $stepsById[$prerequisiteId]) {
                $issues += ('Manifest step {0} references undefined prerequisite {1}.' -f $stepId, $prerequisiteId)
            }
        }
    }
    if ($issues.Count -gt 0) { throw ('Manifest dependency graph is invalid: {0}' -f ($issues -join ' ')) }

    $visitState = @{}
    foreach ($stepId in $stepsById.Keys) { $visitState[$stepId] = 'Unvisited' }
    function Invoke-ManifestStepDependency {
        <#
        .SYNOPSIS
            Visit one dependency using the enclosing graph and traversal state.
        .PARAMETER StepId
            Identity currently inspected for a back-edge.
        .OUTPUTS
            None. Updates local traversal sets and throws on a cycle; no workflow action runs.
        #>
        param([Parameter(Mandatory)][string]$StepId)

        if ($visitState[$StepId] -eq 'Visiting') { throw ('Manifest dependency graph contains a cycle involving step {0}.' -f $StepId) }
        if ($visitState[$StepId] -eq 'Visited') { return }
        $visitState[$StepId] = 'Visiting'
        foreach ($prerequisiteId in @($stepsById[$StepId].PrerequisiteStepIds)) {
            Invoke-ManifestStepDependency -StepId $prerequisiteId
        }
        $visitState[$StepId] = 'Visited'
    }
    foreach ($stepId in $stepsById.Keys) { Invoke-ManifestStepDependency -StepId $stepId }
}

function Assert-ManifestDefinition {
    <#
    .SYNOPSIS
        Reject invalid raw workflow definitions before coercion or startup access.
    .DESCRIPTION
        Supports the current 1.6 schema and its non-breaking patch revisions.
        Optional defaults remain compatible; explicitly supplied fields must have
        their declared types. Phase ordering and step-label semantics are separate.
    .PARAMETER Manifest
        Normalised JSON dictionary, without any runtime state changes.
    .OUTPUTS
        No output. Throws an actionable error for an unsupported definition.
    #>
    param([Parameter(Mandatory)][AllowNull()][AllowEmptyCollection()]$Manifest)
    if ($Manifest -isnot [System.Collections.IDictionary]) { throw 'Manifest must be a JSON object.' }
    if ($Manifest.Contains('groupConflictExclusions')) {
        if ($Manifest.groupConflictExclusions -isnot [array]) { throw 'Manifest groupConflictExclusions must be a JSON array.' }
        foreach ($rule in $Manifest.groupConflictExclusions) {
            if ($rule -isnot [System.Collections.IDictionary] -or $rule.match -notin @('Prefix', 'Exact') -or
                $rule.value -isnot [string] -or [string]::IsNullOrWhiteSpace($rule.value) -or $rule.value -cne $rule.value.Trim()) {
                throw 'Each groupConflictExclusions rule requires match Prefix or Exact and a non-blank value without surrounding whitespace.'
            }
        }
    }
    if ($Manifest.manifestVersion -isnot [string] -or $Manifest.manifestVersion -notmatch '^1\.6\.(0|[1-9][0-9]*)$') {
        throw 'Unsupported manifestVersion. This entry point supports schema 1.6.x only.'
    }
    foreach ($collectionName in @('steps', 'workflowPhases')) {
        if ($Manifest[$collectionName] -isnot [array] -or $Manifest[$collectionName].Count -eq 0) {
            throw ('Manifest {0} must be a non-empty JSON array.' -f $collectionName)
        }
    }
    $supportedActions = @(
        'ResolveAutopilotDevice', 'RemoveAssociatedManagedDevice', 'ApplyGroupTag',
        'ValidateDeploymentProfile', 'AddToPreProvisioningGroup', 'ClearUserlessEnrollmentStatus',
        'AssignTechnicianPrimaryUser', 'RetryFailedApplications', 'RemoveFromPreProvisioningGroup',
        'AssignFinalPrimaryUser', 'ConfirmImagingAndOobe', 'ConfirmReseal', 'ConfirmBootToSignIn',
        'ConfirmFirstSignIn', 'ConfirmApplicationBaseline', 'ConfirmUpdatesAndShutdown', 'ConfirmRecoveryReadiness'
    )
    $stepsById = @{}
    $actions = @{}
    $enabledCount = 0
    foreach ($entry in @($Manifest.steps) + @($Manifest.workflowPhases)) {
        if ($entry -isnot [System.Collections.IDictionary]) { throw 'Each manifest step and phase must be a JSON object.' }
        foreach ($field in @('id', 'displayName')) {
            if ($entry[$field] -isnot [string] -or [string]::IsNullOrWhiteSpace($entry[$field]) -or $entry[$field] -cne $entry[$field].Trim()) {
                throw ('Each manifest step and phase needs a non-blank {0} without surrounding whitespace.' -f $field)
            }
        }
        foreach ($field in @('enabled', 'isConditional')) {
            if ($entry.Contains($field) -and $entry[$field] -isnot [bool]) { throw ('Manifest {0} field {1} must be a JSON Boolean.' -f $entry.id, $field) }
        }
        foreach ($field in @('summary', 'notes', 'description')) {
            if ($entry.Contains($field) -and $entry[$field] -isnot [string]) { throw ('Manifest {0} field {1} must be text.' -f $entry.id, $field) }
        }
        foreach ($field in @('prerequisiteStepIds', 'requiredPermissions', 'graphEndpoints', 'actionNames', 'plannedGuidedActions', 'details')) {
            if (-not $entry.Contains($field)) { continue }
            if ($entry[$field] -isnot [array]) { throw ('Manifest {0} field {1} must be a JSON array.' -f $entry.id, $field) }
            foreach ($value in $entry[$field]) {
                if ($value -isnot [string] -or [string]::IsNullOrWhiteSpace($value) -or $value -cne $value.Trim()) {
                    throw ('Manifest {0} field {1} must contain non-blank text without surrounding whitespace.' -f $entry.id, $field)
                }
            }
        }
    }
    $displayCodes = @{}
    foreach ($step in $Manifest.steps) {
        if ($stepsById.ContainsKey($step.id)) { throw ('Manifest step ID {0} is duplicated.' -f $step.id) }
        if ($step.Contains('displayCode') -and ($step.displayCode -isnot [string] -or $step.displayCode -notmatch '^[A-Za-z][A-Za-z0-9_-]*$')) { throw ('Manifest step {0} displayCode must be a letter-led code without spaces.' -f $step.id) }
        $displayCode = if ($step.Contains('displayCode')) { $step.displayCode } else { $step.id }
        if ($displayCodes.ContainsKey($displayCode)) { throw ('Manifest display code {0} is duplicated.' -f $displayCode) }
        $displayCodes[$displayCode] = $true
        if ($step.actionName -isnot [string] -or $step.actionName -notin $supportedActions) { throw ('Manifest step {0} has an unsupported actionName.' -f $step.id) }
        if ($actions.ContainsKey($step.actionName)) { throw ('Manifest action {0} is duplicated.' -f $step.actionName) }
        if ($step.prerequisiteStepIds -isnot [array]) { throw ('Manifest step {0} needs a prerequisiteStepIds array, including [] when empty.' -f $step.id) }
        if ($step.Contains('executionType') -and ($step.executionType -isnot [string] -or $step.executionType -notin @('graph', 'guided', 'hybrid', 'hybrid-selection'))) { throw ('Manifest step {0} has an unsupported executionType.' -f $step.id) }
        if ($step.Contains('activationRequirement') -and ($step.activationRequirement -isnot [string] -or $step.activationRequirement -notin @('None', 'RecoveryMode'))) { throw ('Manifest step {0} has an unsupported activationRequirement.' -f $step.id) }
        $stepsById[$step.id] = $step
        $actions[$step.actionName] = $true
        if (-not $step.Contains('enabled') -or $step.enabled) { $enabledCount++ }
    }
    if ($enabledCount -eq 0) { throw 'Manifest must contain at least one enabled step.' }
    foreach ($step in $Manifest.steps) {
        if ($step.Contains('enabled') -and -not $step.enabled) { continue }
        foreach ($prerequisiteId in $step.prerequisiteStepIds) {
            $prerequisite = $stepsById[$prerequisiteId]
            if ($null -ne $prerequisite -and $prerequisite.Contains('enabled') -and -not $prerequisite.enabled) {
                throw ('Enabled step {0} depends on disabled prerequisite {1}.' -f $step.id, $prerequisiteId)
            }
        }
    }
    $phaseIds = @{}
    foreach ($phase in $Manifest.workflowPhases) {
        if ($phaseIds.ContainsKey($phase.id)) { throw ('Manifest phase ID {0} is duplicated.' -f $phase.id) }
        $phaseIds[$phase.id] = $true
        if ($phase.actionNames -isnot [array] -or $phase.actionNames.Count -eq 0) { throw ('Manifest phase {0} needs a non-empty actionNames array.' -f $phase.id) }
        $phaseActions = @{}
        foreach ($actionName in $phase.actionNames) {
            if (-not $actions.ContainsKey($actionName)) { throw ('Workflow phase {0} references undefined action {1}.' -f $phase.id, $actionName) }
            if ($phaseActions.ContainsKey($actionName)) { throw ('Workflow phase {0} repeats action {1}.' -f $phase.id, $actionName) }
            $phaseActions[$actionName] = $true
        }
    }
    if ($Manifest.Contains('menuTitle') -and ($Manifest.menuTitle -isnot [string] -or [string]::IsNullOrWhiteSpace($Manifest.menuTitle))) { throw 'Manifest menuTitle must be non-blank text.' }
}

function Initialize-AutopilotExpressDefinitions {
    <#
    .SYNOPSIS
        Validate runtime, site, device-type and manifest definitions before use.
    .OUTPUTS
        None. Initialises script configuration or throws before authentication/workflow entry.
    #>
    try {
        $runtimeConfigPath = Get-RuntimeConfigFilePath
        $runtimeConfig = Read-JsonDefinitionFile -Path $runtimeConfigPath -Description 'Runtime configuration'
        $manifestConfig = Read-JsonDefinitionFile -Path (Get-ManifestFilePath) -Description 'Manifest'
        Write-AutopilotExpressLog -Message ('Runtime definition loaded from {0}. Remediation permissions are checked against this configuration and the authenticated context separately.' -f $runtimeConfigPath) -Level INFO
    }
    catch {
        Write-AutopilotExpressLog -Message ('Failed to load Autopilot Express definitions: {0}' -f $_.Exception.Message) -Level 'ERROR'
        throw
    }

    Assert-ManifestDefinition -Manifest $manifestConfig

    $loadedSteps = @()
    foreach ($step in @($manifestConfig.steps)) {
        $loadedSteps += , ([ordered]@{
                Id                    = [string]$step.id
                DisplayCode           = if ($step.displayCode) { [string]$step.displayCode } else { [string]$step.id }
                DisplayName           = [string]$step.displayName
                Enabled               = if ($null -ne $step.enabled) { [bool]$step.enabled } else { $true }
                ActionName            = [string]$step.actionName
                PrerequisiteStepIds   = @($step.prerequisiteStepIds | Where-Object { -not [string]::IsNullOrWhiteSpace([string]$_) } | ForEach-Object { [string]$_ })
                ActivationRequirement = if ($step.activationRequirement) { [string]$step.activationRequirement } else { 'None' }
                IsConditional         = $step.activationRequirement -eq 'RecoveryMode'
                ExecutionType         = if ($step.executionType) { [string]$step.executionType } else { 'graph' }
                RequiredPermissions   = @($step.requiredPermissions)
                GraphEndpoints        = @($step.graphEndpoints)
                Summary               = if ($step.summary) { [string]$step.summary } else { '' }
                Notes                 = if ($step.notes) { [string]$step.notes } else { '' }
                Details               = @($step.details)
            })
    }

    Test-ManifestDependencyGraph -Steps @($loadedSteps)

    $loadedPhases = @()
    foreach ($phase in @($manifestConfig.workflowPhases)) {
        $phaseActionNames = @($phase.actionNames | Where-Object { -not [string]::IsNullOrWhiteSpace([string]$_) })
        $loadedPhases += , ([ordered]@{
                Id                   = [string]$phase.id
                DisplayName          = [string]$phase.displayName
                Description          = if ($phase.description) { [string]$phase.description } else { '' }
                ActionNames          = $phaseActionNames
                PlannedGuidedActions = @($phase.plannedGuidedActions)
                IsConditional        = if ($null -ne $phase.isConditional) { [bool]$phase.isConditional } else { $false }
            })
    }
    $Script:RuntimeConfig = $runtimeConfig
    if ($Script:AuthModeOverride -and $Script:RuntimeConfig.graph) { $Script:RuntimeConfig.graph.authMode = $Script:AuthModeOverride }
    if ($runtimeConfig.organisationName) { $Script:Config.OrganisationName = [string]$runtimeConfig.organisationName }
    $Script:StepManifest = @($loadedSteps)
    $Script:Config.GroupConflictExclusions = if ($manifestConfig.Contains('groupConflictExclusions')) { $manifestConfig.groupConflictExclusions } else { $null }
    $Script:WorkflowIdVersion = $manifestConfig.workflowIdVersion
    $Script:SessionFileNamesEnabled = $true
    $Script:WorkflowPhases = @($loadedPhases)

    Write-AutopilotExpressLog -Message ('Loaded {0} manifest step(s), {1} workflow phase(s), and runtime settings from JSON definitions.' -f $Script:StepManifest.Count, $Script:WorkflowPhases.Count) -Level 'INFO'
}

function Test-IsPlaceholderConfigurationValue {
    <#
    .SYNOPSIS
        Detect absent values and documented placeholder forms in Live configuration.
    .PARAMETER Value
        Configuration text to inspect without querying a tenant.
    .OUTPUTS
        Boolean; this syntax check cannot prove that a real tenant object exists.
    #>
    param([AllowEmptyString()][string]$Value)

    if ([string]::IsNullOrWhiteSpace($Value)) { return $true }
    return $Value -match '(?i)(example|placeholder|replace[-_ ]?me|^\s*<.+>\s*$)'
}

function Test-LiveRuntimeConfiguration {
    <#
    .SYNOPSIS
        Collect actionable Live configuration issues without authenticating.
    .OUTPUTS
        Issue array, empty on local validation success; not tenant acceptance evidence.
    #>
    $issues = @()

    if (-not $Script:RuntimeConfig.graph) { $issues += 'Runtime configuration is missing the graph block.' }
    if (-not $Script:RuntimeConfig.autopilot) { $issues += 'Runtime configuration is missing the autopilot block.' }
    if ($issues.Count -gt 0) { return @($issues) }

    $configVersion = [string]$Script:RuntimeConfig.configVersion
    if ($configVersion -notmatch '^\d+\.\d+\.\d+$') {
        $issues += 'configVersion must use semantic version format, for example 1.0.0.'
    }
    $authMode = [string]$Script:RuntimeConfig.graph.authMode
    if ($authMode -notin @('Browser', 'DeviceCode')) {
        $issues += ('graph.authMode must be Browser or DeviceCode. Current value: {0}' -f $authMode)
    }
    $contextScope = [string]$Script:RuntimeConfig.graph.contextScope
    if ($contextScope -notin @('Process', 'CurrentUser')) {
        $issues += ('graph.contextScope must be Process or CurrentUser. Current value: {0}' -f $contextScope)
    }
    $configuredScopes = @($Script:RuntimeConfig.graph.requiredScopes | Where-Object { -not [string]::IsNullOrWhiteSpace([string]$_) })
    if ($configuredScopes.Count -eq 0) {
        $issues += 'At least one Microsoft Graph scope is required in graph settings.'
    }
    $configuredModules = @($Script:RuntimeConfig.graph.requiredModules | Where-Object { -not [string]::IsNullOrWhiteSpace([string]$_) })
    if ($configuredModules.Count -eq 0) {
        $issues += 'At least one Microsoft Graph module is required in graph settings.'
    }

    $configuredPrefixes = @($Script:RuntimeConfig.autopilot.technicianUpnPrefixes | Where-Object { -not [string]::IsNullOrWhiteSpace([string]$_) })
    if ($configuredPrefixes.Count -eq 0) {
        $issues += 'At least one technician UPN prefix is required in autopilot settings.'
    }
    foreach ($limitName in @('directorySearchLimit', 'recentUsersLimit')) {
        $rawLimitValue = [string]$Script:RuntimeConfig.autopilot[$limitName]
        if ($rawLimitValue -notmatch '^[1-9][0-9]*$') {
            $issues += ('autopilot.{0} must be a positive integer.' -f $limitName)
        }
    }

    if ($null -ne $Script:RuntimeConfig.autopilot.hashImport) {
        try { $null = Get-AutopilotHashImportSettings }
        catch { $issues += 'autopilot.hashImport settings are invalid; check Boolean flags, folder arrays and literal filename prefixes.' }
    }

    return @($issues)
}

function Get-GraphLocalModuleRoot {
    <#
    .SYNOPSIS
        Resolve the per-user SDK cache on a fixed local drive, without elevation.
    .OUTPUTS
        Absolute module root. Network, redirected or unavailable local storage throws.
    #>
    if (-not $env:LOCALAPPDATA -or $env:LOCALAPPDATA -notmatch '^[A-Za-z]:[\\/]') { throw 'A local LOCALAPPDATA directory is required for Graph SDK deployment.' }
    $root = [IO.Path]::GetFullPath((Join-Path $env:LOCALAPPDATA 'PowerShellScriptingNew\AutopilotExpress\GraphModules'))
    if ([IO.DriveInfo]::new([IO.Path]::GetPathRoot($root)).DriveType -ne [IO.DriveType]::Fixed) { throw 'The Graph SDK cache must be on a fixed local drive, not a redirected home drive.' }
    $directory = [IO.DirectoryInfo]::new($root)
    while ($null -ne $directory) {
        if ($directory.Exists -and ($directory.Attributes -band [IO.FileAttributes]::ReparsePoint)) { throw 'The Graph SDK cache cannot use redirected directories.' }
        $directory = $directory.Parent
    }
    return $root
}

function Test-GraphModuleLocalPath {
    <#
    .SYNOPSIS
        Distinguish fixed local SDK files from UNC and mapped-network deployments.
    .PARAMETER Path
        Absolute candidate manifest or module directory.
    .OUTPUTS
        Boolean fixed-local, non-redirected classification; no module code is loaded.
    #>
    param([Parameter(Mandatory)][ValidateNotNullOrEmpty()][string]$Path)
    if ($Path -notmatch '^[A-Za-z]:[\\/]' -or [IO.DriveInfo]::new([IO.Path]::GetPathRoot($Path)).DriveType -ne [IO.DriveType]::Fixed) { return $false }
    $directory = [IO.DirectoryInfo]::new($Path)
    while ($null -ne $directory) {
        if ($directory.Exists -and ($directory.Attributes -band [IO.FileAttributes]::ReparsePoint)) { return $false }
        $directory = $directory.Parent
    }
    return $true
}

function Get-GraphModuleCandidate {
    <#
    .SYNOPSIS
        Read SDK manifests as restricted data before module discovery can load code.
    .PARAMETER RequiredModules
        Configured names; Authentication is always included for coherent selection.
    .PARAMETER ModuleRoots
        Explicit inspection roots. Default discovery uses the per-user cache and
        fixed-local PSModulePath entries only, never redirected network home drives.
    .OUTPUTS
        Name, Version, Path and ModuleBase metadata without imports or SDK execution.
        Unreadable or redirected candidate paths fail closed rather than disappearing.
    #>
    param(
        [Parameter(Mandatory)][ValidateNotNullOrEmpty()][string[]]$RequiredModules,
        [AllowEmptyCollection()][string[]]$ModuleRoots = @($env:PSModulePath -split [IO.Path]::PathSeparator)
    )
    if (-not $PSBoundParameters.ContainsKey('ModuleRoots')) {
        $ModuleRoots = @((Get-GraphLocalModuleRoot)) + @($ModuleRoots | Where-Object { $_ -and (Test-GraphModuleLocalPath -Path $_) })
    }
    $names = @('Microsoft.Graph.Authentication') + @($RequiredModules | Where-Object { $_ -ine 'Microsoft.Graph.Authentication' } | Sort-Object -Unique)
    $candidates = @()
    foreach ($root in @($ModuleRoots | Where-Object { $_ } | Select-Object -Unique)) {
        if ($root -notmatch '^(?:[A-Za-z]:[\\/]|\\\\[^\\]+\\[^\\]+)') { throw 'SDK search roots must be absolute filesystem paths.' }
        foreach ($name in $names) {
            if ($name -notmatch '^Microsoft\.Graph\.[A-Za-z0-9.]+$') { throw 'Only configured Microsoft.Graph module names can be inspected.' }
            $directory = Join-Path $root $name
            if (-not (Test-Path -LiteralPath $directory -PathType Container -ErrorAction Stop)) { continue }
            $directories = @(Get-Item -LiteralPath $directory -Force -ErrorAction Stop) + @(Get-ChildItem -LiteralPath $directory -Directory -Force -ErrorAction Stop)
            foreach ($item in $directories) {
                if ($item.Attributes -band [IO.FileAttributes]::ReparsePoint) { throw ('SDK discovery refused a redirected directory: {0}' -f $item.FullName) }
                $path = Join-Path $item.FullName ('{0}.psd1' -f $name)
                if (-not (Test-Path -LiteralPath $path -PathType Leaf -ErrorAction Stop)) { continue }
                $file = Get-Item -LiteralPath $path -Force -ErrorAction Stop
                if ($file.Length -gt 4194304 -or ($file.Attributes -band [IO.FileAttributes]::ReparsePoint)) { throw ('Unsafe SDK manifest: {0}' -f $path) }
                $tokens = $null; $errors = $null
                $ast = [Management.Automation.Language.Parser]::ParseFile($file.FullName, [ref]$tokens, [ref]$errors)
                if ($errors.Count -or -not $ast.EndBlock -or $ast.EndBlock.Statements.Count -ne 1) { throw ('SDK manifest is not restricted data: {0}' -f $path) }
                $statement = $ast.EndBlock.Statements[0]
                if ($statement -isnot [Management.Automation.Language.PipelineAst] -or $statement.PipelineElements.Count -ne 1 -or $statement.PipelineElements[0] -isnot [Management.Automation.Language.CommandExpressionAst] -or $statement.PipelineElements[0].Expression -isnot [Management.Automation.Language.HashtableAst]) { throw ('SDK manifest is not a literal data dictionary: {0}' -f $path) }
                $data = $statement.PipelineElements[0].Expression.SafeGetValue()
                $version = $null
                if ($data -isnot [Collections.IDictionary] -or -not [version]::TryParse([string]$data.ModuleVersion, [ref]$version)) { throw ('Invalid SDK manifest version: {0}' -f $path) }
                $candidates += @{ Name = $name; Version = $version; Path = $file.FullName; ModuleBase = $item.FullName }
            }
        }
    }
    return $candidates
}

function Test-GraphModuleScriptTrust {
    <#
    .SYNOPSIS
        Inspect the selected SDK deployment without loading its code or changing trust.
    .PARAMETER Plan
        Exact coherent SDK manifests selected by Get-GraphModuleImportPlan.
    .OUTPUTS
        Readiness and exact Internet-marked file paths with SHA-256 fingerprints.
        Uncertain network trust fails closed; signature checks never approve publishers.
    #>
    param([Parameter(Mandatory)][ValidateNotNullOrEmpty()][object[]]$Plan)
    $policy = Get-ExecutionPolicy -ErrorAction Stop
    if ($policy -eq 'Restricted') { throw 'Graph SDK loading is blocked by Restricted execution policy. Obtain an approved deployment from the policy owner; unblocking is not a remedy.' }
    $blocked = @()
    $publishers = $null
    foreach ($module in $Plan) {
        $root = [string]$module.ModuleBase
        if ($root -notmatch '^(?:[A-Za-z]:[\\/]|\\\\[^\\]+\\[^\\]+)') { throw 'Graph trust inspection requires absolute filesystem module paths.' }
        $items = @(Get-Item -LiteralPath $root -Force -ErrorAction Stop) + @(Get-ChildItem -LiteralPath $root -Recurse -Force -ErrorAction Stop)
        if (@($items | Where-Object { $_.Attributes -band [IO.FileAttributes]::ReparsePoint }).Count) { throw ('Graph trust inspection refused a redirected directory or file under {0}.' -f $root) }
        foreach ($file in @($items | Where-Object { -not $_.PSIsContainer -and $_.Extension -in @('.ps1', '.psm1', '.psd1', '.ps1xml', '.cdxml', '.dll') })) {
            $marked = $false
            $streams = @(Get-Item -LiteralPath $file.FullName -Stream '*' -ErrorAction Stop | Where-Object { $_.Stream -eq 'Zone.Identifier' })
            if ($streams) { $marked = (Get-Content -LiteralPath $file.FullName -Stream Zone.Identifier -Raw -ErrorAction Stop) -match '(?m)^ZoneId\s*=\s*[34]\s*$' }
            $needsSignature = $file.Extension -ne '.dll' -and ($policy -eq 'AllSigned' -or ($policy -eq 'RemoteSigned' -and $root.StartsWith('\\') -and -not $marked))
            if ($needsSignature) {
                $signature = Get-AuthenticodeSignature -LiteralPath $file.FullName -ErrorAction Stop
                if ($signature.Status -ne 'Valid' -or -not $signature.SignerCertificate) { throw ('Graph SDK signature or network-zone trust cannot be established for {0}. Deploy an organisation-approved coherent SDK locally, or ask the policy owner to approve its network deployment. No policy or publisher trust was changed.' -f $file.FullName) }
                if ($null -eq $publishers) { $publishers = @(Get-ChildItem -LiteralPath 'Cert:\CurrentUser\TrustedPublisher', 'Cert:\LocalMachine\TrustedPublisher' -ErrorAction Stop) }
                if ($signature.SignerCertificate.Thumbprint -notin @($publishers.Thumbprint)) { throw ('Graph SDK publisher is not already trusted for {0}. Obtain an organisation-approved deployment; publisher trust is never granted automatically.' -f $file.FullName) }
            }
            if ($marked) { $blocked += @{ Path = $file.FullName; SHA256 = (Get-FileHash -LiteralPath $file.FullName -Algorithm SHA256 -ErrorAction Stop).Hash } }
        }
    }
    return @{ Ready = ($blocked.Count -eq 0); Files = $blocked }
}

function Request-GraphModuleScriptTrust {
    <#
    .SYNOPSIS
        Offer separately confirmed removal of Internet marks from reviewed SDK files.
    .PARAMETER Plan
        Exact selected deployment, including explicitly inspected network installations.
    .OUTPUTS
        Boolean readiness. Default No makes no change. File lists and hashes are
        rechecked before unblocking; callers handle retry or exit after any failure.
    #>
    param([Parameter(Mandatory)][ValidateNotNullOrEmpty()][object[]]$Plan)
    $trust = Test-GraphModuleScriptTrust -Plan $Plan
    if ($trust.Ready) { return $true }
    Write-Host 'The selected Graph SDK contains Internet-marked files. Review their source and contents before consenting.'
    foreach ($file in $trust.Files) { Write-Host ('{0}  SHA256={1}' -f $file.Path, $file.SHA256) }
    Write-Host 'Unblocking changes these deployed files for other users too. It does not approve their publisher, override policy, or guarantee UNC/AppLocker/WDAC loading.'
    $consent = Read-ValidatedInput -Prompt 'Have you reviewed and approved every listed file and its source, and authorise removing only these Internet marks? [Y] Yes [N] No' -Default 'N' -Type 'Choice' -Choices @('Y', 'N')
    if ($consent -ine 'Y') { return $false }
    $current = Test-GraphModuleScriptTrust -Plan $Plan
    $before = @($trust.Files | ForEach-Object { '{0}|{1}' -f $_.Path, $_.SHA256 } | Sort-Object -Unique)
    $after = @($current.Files | ForEach-Object { '{0}|{1}' -f $_.Path, $_.SHA256 } | Sort-Object -Unique)
    if ($before.Count -ne $after.Count -or @(Compare-Object -ReferenceObject $before -DifferenceObject $after).Count) { throw 'Graph SDK files changed after review. Nothing was unblocked; inspect the deployment again.' }
    foreach ($file in $current.Files) {
        if ((Get-FileHash -LiteralPath $file.Path -Algorithm SHA256 -ErrorAction Stop).Hash -cne $file.SHA256) { throw 'Graph SDK content changed before unblocking. Stop and review the deployment; no module was imported.' }
        Unblock-File -LiteralPath $file.Path -ErrorAction Stop
        Write-AutopilotExpressLog -Message ('Removed the explicitly reviewed Internet mark from {0}; SHA256={1}.' -f $file.Path, $file.SHA256) -Level 'INFO'
    }
    return [bool](Test-GraphModuleScriptTrust -Plan $Plan).Ready
}

function Install-RequiredGraphModules {
    <#
    .SYNOPSIS
        Offer coherent SDK deployment to fixed local per-user storage without UAC.
    .PARAMETER RequiredModules
        Approved module names; network-only deployments also require a local copy.
    .OUTPUTS
        Boolean installation outcome. Declining or installation failure does not authorise Live use.
    #>
    param([Parameter(Mandatory)][string[]]$RequiredModules)

    $installed = @(Get-GraphModuleCandidate -RequiredModules $RequiredModules)
    $names = @('Microsoft.Graph.Authentication') + @($RequiredModules | Where-Object { $_ -ine 'Microsoft.Graph.Authentication' })
    $local = @($installed | Where-Object { Test-GraphModuleLocalPath -Path $_.Path })
    $commonVersion = $null
    foreach ($version in @($local | Where-Object { $_.Name -eq 'Microsoft.Graph.Authentication' } | ForEach-Object { $_.Version } | Sort-Object -Unique -Descending)) {
        if (@($names | Where-Object { $name = $_; -not @($local | Where-Object { $_.Name -eq $name -and $_.Version -eq $version }).Count }).Count -eq 0) { $commonVersion = $version; break }
    }
    if ($null -ne $commonVersion) { return $true }
    $root = Get-GraphLocalModuleRoot
    Write-Host 'A complete same-version Graph SDK is required on a fixed local drive. Network-loaded DLLs can fail if the share becomes unavailable.'
    Write-Host ('Local deployment: {0}' -f $root)
    Write-Host ('Modules: {0}' -f ($names -join ', '))
    Write-Host 'No administrator rights, UAC, execution-policy changes or removal of existing modules are required.'
    $consent = Read-ValidatedInput -Prompt 'Download this SDK set from PSGallery to the local per-user folder? [Y] Yes [N] No' -Default 'N' -Type 'Choice' -Choices @('Y', 'N')
    if ($consent -ine 'Y') {
        Write-AutopilotExpressLog -Message 'Local Graph SDK deployment declined; no network SDK will be imported.' -Level 'WARN'
        return $false
    }
    try {
        # Member access (not Sort-Object/Select-Object property names) reads hashtable keys in Windows PowerShell 5.1 too.
        $version = $installed | Where-Object { $_.Name -eq 'Microsoft.Graph.Authentication' } | ForEach-Object { $_.Version } | Sort-Object -Descending | Select-Object -First 1
        if ($null -eq $version) { $version = (Find-Module -Name Microsoft.Graph.Authentication -Repository PSGallery -ErrorAction Stop).Version }
        $null = New-Item -ItemType Directory -Path $root -Force -ErrorAction Stop
        foreach ($moduleName in $names) {
            Write-AutopilotExpressLog -Message ('Saving local Graph SDK module {0} {1}.' -f $moduleName, $version) -Level INFO
            Save-Module -Name $moduleName -RequiredVersion ([string]$version) -Repository PSGallery -Path $root -Force -ErrorAction Stop
        }
        $saved = @(Get-GraphModuleCandidate -RequiredModules $names -ModuleRoots @($root))
        $null = Get-GraphModuleImportPlan -RequiredModules $names -InstalledModules $saved
        Write-AutopilotExpressLog -Message 'Local coherent SDK manifests verified; file trust is checked separately before import.' -Level INFO
    }
    catch {
        Write-AutopilotExpressLog -Message ('Local Graph SDK deployment failed: {0}. No SDK was imported; retry after correcting storage or gallery access.' -f $_.Exception.Message) -Level ERROR
        return $false
    }
    return $true
}

function Get-GraphModuleImportPlan {
    <#
    .SYNOPSIS
        Select the newest installed common SDK version without changing modules.
    .PARAMETER RequiredModules
        Configured SDK module names; Authentication is always included first.
    .PARAMETER InstalledModules
        Previously selected metadata for post-import checks without repeating disk discovery.
    .OUTPUTS
        Installed module metadata in import order. Conflicting loaded SDKs throw.
    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseSingularNouns', '', Justification = 'Internal planner accepts the configured module collection.')]
    param(
        [Parameter(Mandatory)][ValidateNotNullOrEmpty()][string[]]$RequiredModules,
        [AllowEmptyCollection()][object[]]$InstalledModules
    )
    $names = @('Microsoft.Graph.Authentication') + @($RequiredModules | Where-Object { $_ -ne 'Microsoft.Graph.Authentication' } | Sort-Object -Unique)
    $available = @($InstalledModules)
    if (-not $PSBoundParameters.ContainsKey('InstalledModules')) {
        $available = @(Get-GraphModuleCandidate -RequiredModules $names | Where-Object { Test-GraphModuleLocalPath -Path $_.Path })
    }
    $versions = @($available | Where-Object { $_.Name -eq 'Microsoft.Graph.Authentication' } | ForEach-Object { $_.Version } | Sort-Object -Unique -Descending)
    $plan = @()
    foreach ($version in $versions) {
        $candidate = @()
        foreach ($name in $names) {
            $module = $available | Where-Object { $_.Name -eq $name -and $_.Version -eq $version } | Sort-Object -Property { $_.Path } | Select-Object -First 1
            if ($null -eq $module) { break }
            $candidate += $module
        }
        if ($candidate.Count -eq $names.Count) { $plan = $candidate; break }
    }
    if ($plan.Count -ne $names.Count) { throw 'No common installed Graph SDK version is available for the configured modules. Review module versions; nothing was imported.' }
    foreach ($loaded in @(Get-Module -Name 'Microsoft.Graph.*')) {
        if ($loaded.Version -ne $plan[0].Version) { throw 'A conflicting Graph SDK version is already loaded. Start a fresh PowerShell process before using Live mode.' }
        $selected = $plan | Where-Object { $_.Name -eq $loaded.Name } | Select-Object -First 1
        if ($null -ne $selected -and $loaded.ModuleBase -ine $selected.ModuleBase) { throw 'A configured Graph module is loaded from a different installation. Start a fresh PowerShell process.' }
    }
    return , $plan
}

function Import-RequiredGraphModules {
    <#
    .SYNOPSIS
        Discover/import configured SDK modules with guarded failure reporting.
    .OUTPUTS
        Boolean readiness. Missing modules follow the explicit installation prompt;
        Demo does not require Live dependencies.
    #>
    while ($true) {
        try {
            $requiredModules = Get-ConfiguredGraphModules
            Write-AutopilotExpressLog -Message 'Checking installed Graph SDK manifests as data before controlled imports.' -Level 'INFO'
            if (-not (Install-RequiredGraphModules -RequiredModules $requiredModules)) { return $false }
            $plan = Get-GraphModuleImportPlan -RequiredModules $requiredModules
            if (Request-GraphModuleScriptTrust -Plan $plan) { break }
            Write-AutopilotExpressLog -Message 'Graph SDK trust review was declined or remains unresolved. No module was imported.' -Level 'WARN'
        }
        catch { Write-AutopilotExpressLog -Message $_.Exception.Message -Level 'ERROR' }
        Write-Host 'Review the reported files, use an approved coherent local deployment if network restrictions persist, or contact the policy owner. No execution policy or publisher trust will be changed.'
        $choice = Read-ValidatedInput -Prompt 'R retry deployment inspection; 0 return without Live dependencies' -Default '0' -Type 'Choice' -Choices @('R', '0')
        if ($choice -ine 'R') { return $false }
    }
    foreach ($module in $plan) {
        try {
            if (-not (Test-GraphModuleLocalPath -Path $module.Path)) { throw 'SDK import refused a network or non-fixed-drive deployment. Use the per-user local deployment option; elevation is not required.' }
            Write-AutopilotExpressLog -Message ('Importing Graph SDK module {0} {1} from {2}.' -f $module.Name, $module.Version, $module.Path) -Level 'INFO'
            Import-Module -Name $module.Path -ErrorAction Stop | Out-Null
            Write-AutopilotExpressLog -Message ('Imported Graph SDK module {0} {1}.' -f $module.Name, $module.Version) -Level 'INFO'
        }
        catch {
            Write-AutopilotExpressLog -Message ('Failed to import Microsoft Graph module {0}: {1}' -f $module.Name, $_.Exception.Message) -Level 'ERROR'
            return $false
        }
    }
    try { [void](Get-GraphModuleImportPlan -RequiredModules $requiredModules -InstalledModules $plan) }
    catch {
        Write-AutopilotExpressLog -Message $_.Exception.Message -Level 'ERROR'
        return $false
    }
    return $true
}

function Get-GraphTransportPolicy {
    <#
    .SYNOPSIS
        Validates the bounded HTTP policy independently of state-verification polling.
    .OUTPUTS
        Dictionary containing attempt, backoff, maximum-wait and per-request timeout limits.
    #>
    $policy = @{}
    foreach ($setting in @(
            @{ Name = 'TransportMaxAttempts'; Default = 3; Minimum = 1; Maximum = 5 }
            @{ Name = 'TransportBackoffSeconds'; Default = 3; Minimum = 0; Maximum = 60 }
            @{ Name = 'TransportMaxDelaySeconds'; Default = 60; Minimum = 1; Maximum = 300 }
            @{ Name = 'TransportTimeoutSeconds'; Default = 60; Minimum = 1; Maximum = 300 }
        )) {
        $value = $Script:Config[$setting.Name]
        if ($null -eq $value) { $value = $setting.Default }
        if ([string]$value -notmatch '^[0-9]+$' -or [double]$value -lt $setting.Minimum -or [double]$value -gt $setting.Maximum) {
            throw ('{0} must be an integer from {1} to {2}.' -f $setting.Name, $setting.Minimum, $setting.Maximum)
        }
        $policy[$setting.Name] = [int]$value
    }
    if ($policy.TransportBackoffSeconds -gt $policy.TransportMaxDelaySeconds) {
        throw 'TransportBackoffSeconds must not exceed TransportMaxDelaySeconds.'
    }
    return $policy
}

function Initialize-GraphTransport {
    <#
    .SYNOPSIS
        Disables hidden SDK retries and applies the HTTP timeout before any Graph operation.
    .DESCRIPTION
        Uses the installed SDK request context, including generated mutation commands.
        Unsupported SDK versions fail closed instead of using uncontrolled replay behaviour.
    .PARAMETER Policy
        Validated timeout/retry policy; SDK retries remain disabled for explicit wrapper control.
    .OUTPUTS
        None. Configures transport once per session, recording success only after setup completes.
    #>
    param([Parameter(Mandatory)][System.Collections.IDictionary]$Policy)

    if ($Script:GraphSession.Contains('TransportTimeoutSeconds') -and $Script:GraphSession['TransportTimeoutSeconds'] -eq $Policy.TransportTimeoutSeconds) { return }
    $contextCommand = Get-Command -Name Set-MgRequestContext -ErrorAction Stop
    if ($contextCommand.Parameters.Keys -notcontains 'MaxRetry' -or $contextCommand.Parameters.Keys -notcontains 'ClientTimeout') {
        throw 'The Graph SDK must support Set-MgRequestContext -MaxRetry and -ClientTimeout.'
    }
    Set-MgRequestContext -MaxRetry 0 -ClientTimeout $Policy.TransportTimeoutSeconds -Verbose:$false -Debug:$false -ErrorAction Stop | Out-Null
    $Script:GraphSession['TransportTimeoutSeconds'] = $Policy.TransportTimeoutSeconds
}

function Get-GraphTransportFailure {
    <#
    .SYNOPSIS
        Reads structured status and safe retry/correlation headers without inspecting error text.
    .PARAMETER RequestError
        The terminating SDK ErrorRecord from a failed request.
    .DESCRIPTION
        Treat SDK fields as untrusted. Only numeric HTTP status 100-599 or a recognised
        status name is returned; arbitrary text and line breaks never enter diagnostics.
    .OUTPUTS
        Dictionary of HTTP status, Retry-After text and validated request identifier.
    #>
    param([Parameter(Mandatory)]$RequestError)

    $exception = $RequestError.Exception
    $status = $exception.ResponseStatusCode
    if ($null -eq $status) { $status = $exception.Response.StatusCode }
    $statusText = [string]$status
    if ($statusText -eq 'TooManyRequests') { $statusText = '429' }
    if ($statusText -eq 'InternalServerError') { $statusText = '500' }
    if ($statusText -eq 'ServiceUnavailable') { $statusText = '503' }
    if ($statusText -eq 'GatewayTimeout') { $statusText = '504' }
    $statusNumber = 0
    if (-not [int]::TryParse($statusText, [ref]$statusNumber) -and $statusText -match '^[A-Za-z]+$') {
        try { $statusNumber = [int][enum]::Parse([System.Net.HttpStatusCode], $statusText, $true) }
        catch { $statusNumber = 0 }
    }
    $statusText = if ($statusNumber -ge 100 -and $statusNumber -le 599) { [string]$statusNumber } else { '' }
    $headers = $exception.ResponseHeaders
    if ($null -eq $headers) { $headers = $exception.Response.Headers }
    $retryAfter = $null
    $requestId = ''
    if ($headers -is [System.Collections.IDictionary]) {
        foreach ($key in $headers.Keys) {
            if ([string]$key -ieq 'Retry-After') { $retryAfter = [string]@($headers[$key])[0] }
            if ([string]$key -ieq 'request-id') { $requestId = [string]@($headers[$key])[0] }
        }
    }
    else {
        foreach ($header in $headers) {
            if ([string]$header.Key -ieq 'Retry-After') { $retryAfter = [string]@($header.Value)[0] }
            if ([string]$header.Key -ieq 'request-id') { $requestId = [string]@($header.Value)[0] }
        }
    }
    if ($requestId -notmatch '^[A-Za-z0-9-]{1,80}$') { $requestId = 'unavailable' }
    return @{ Status = $statusText; RetryAfter = $retryAfter; RequestId = $requestId }
}

function Get-GraphOperationFailureMessage {
    <#
    .SYNOPSIS
        Format SDK failures without retaining response bodies or authentication material.
    .PARAMETER RequestError
        Caught ErrorRecord; structured SDK evidence or the guarded-request tag identifies Graph failures.
    .OUTPUTS
        Validated HTTP/correlation/type diagnostics for Graph, otherwise the local validation message.
    #>
    param([Parameter(Mandatory)]$RequestError)
    $exception = $RequestError.Exception
    $isGraphFailure = $null -ne $exception.Data['AutopilotExpress.GraphMethod'] -or
    $null -ne $exception.ResponseStatusCode -or $null -ne $exception.Response.StatusCode -or
    $RequestError.InvocationInfo.MyCommand.Name -like '*-Mg*'
    if (-not $isGraphFailure) { return $exception.Message }
    $failure = Get-GraphTransportFailure -RequestError $RequestError
    $status = if ($failure.Status) { $failure.Status } else { 'unavailable' }
    return 'Graph request failed: HTTP={0}; request-id={1}; Exception={2}. SDK response text is not retained.' -f $status, $failure.RequestId, $exception.GetType().FullName
}

function Invoke-GraphApiRequest {
    <#
    .SYNOPSIS
        Sends a Graph request with bounded transient GET retries and no mutation replay.
    .DESCRIPTION
        Retries GET only on structured 429/503/504 status. Retry-After takes precedence
        over exponential backoff. Excessive or malformed server waits fail closed.
        Authentication, permissions, unknown transport errors and all writes fail immediately.
    .OUTPUTS
        The original SDK response, or the original terminating request error.
    .PARAMETER Method
        Validated HTTP method. Only approved transient GET failures may be retried.
    .PARAMETER Uri
        Approved Graph URI; unsafe hosts, paths and continuation routes are refused.
    .PARAMETER Body
        Optional request payload; never printed in transport diagnostics.
    .PARAMETER Headers
        Explicit request headers; not copied into diagnostic output.
    #>
    param(
        [Parameter(Mandatory)][ValidateSet('GET', 'POST', 'DELETE')][string]$Method,
        [Parameter(Mandatory)][string]$Uri,
        $Body,
        [hashtable]$Headers
    )

    if (-not $Script:GraphSession.Connected) { throw 'Microsoft Graph session is not connected.' }
    if ($Script:GraphSession.IsSimulated) { throw 'Demo mode must not issue Microsoft Graph requests.' }
    if ($Script:GraphSession.RequiresReconnect) { throw 'Microsoft Graph authentication requires explicit reconnection from Session and Script Settings; no request or workflow write was replayed.' }
    $graphUri = $null
    if (-not [uri]::TryCreate($Uri, [UriKind]::Absolute, [ref]$graphUri) -or
        $graphUri.Scheme -ne 'https' -or $graphUri.Host -ne 'graph.microsoft.com' -or
        $graphUri.Port -ne 443 -or $graphUri.UserInfo -or $graphUri.Fragment -or
        $graphUri.AbsolutePath.StartsWith('//')) {
        throw 'Requests require an absolute HTTPS public Graph URI without user information, fragments or alternate ports.'
    }
    # Serve a read already collected by Invoke-GraphReadPrefetch (one use, same tenant,
    # identical URI). Any write empties the prefetch so later reads cannot see stale data.
    $prefetch = $Script:GraphSession['ReadPrefetch']
    if ($prefetch -is [System.Collections.IDictionary]) {
        if ($Method -eq 'GET' -and $prefetch.TenantId -ceq [string]$Script:GraphSession.TenantId -and $prefetch.Items.ContainsKey($Uri)) {
            $prefetched = $prefetch.Items[$Uri]
            [void]$prefetch.Items.Remove($Uri)
            Write-Verbose ('Graph GET {0} answered from the batched read; no extra request sent.' -f $graphUri.AbsolutePath)
            return $prefetched
        }
        if ($Method -ne 'GET' -and $graphUri.AbsolutePath -cne '/v1.0/$batch') { [void]$Script:GraphSession.Remove('ReadPrefetch') }
    }
    $policy = Get-GraphTransportPolicy
    Initialize-GraphTransport -Policy $policy

    $invokeParameters = @{ Method = $Method; Uri = $graphUri.PathAndQuery; ErrorAction = 'Stop'; Verbose = $false; Debug = $false }
    if ($graphUri.AbsolutePath -match '^/v1\.0/deviceManagement/importedWindowsAutopilotDeviceIdentities(?:/|$)') {
        $invokeParameters.Verbose = $false
        $invokeParameters.Debug = $false
    }
    if ($Headers -and $Headers.Count -gt 0) { $invokeParameters.Headers = $Headers }
    if ($null -ne $Body) {
        $invokeParameters.Body = if ($Body -is [string]) { $Body } else { $Body | ConvertTo-Json -Depth 8 }
        $invokeParameters.ContentType = 'application/json'
    }

    for ($attempt = 1; $attempt -le $policy.TransportMaxAttempts; $attempt++) {
        Write-Verbose ('Graph {0} {1}; attempt={2}. SDK payload diagnostics suppressed.' -f $Method, $graphUri.AbsolutePath, $attempt)
        # Start timing after the verbose line, so a screen write that waits on the host is not counted as Graph time.
        $requestStartedAt = Get-Date
        try {
            $response = Invoke-MgGraphRequest @invokeParameters
            Write-Verbose ('Graph {0} completed; attempt={1}; elapsed-ms={2:N0}.' -f $Method, $attempt, ((Get-Date) - $requestStartedAt).TotalMilliseconds)
            return $response
        }
        catch {
            $_.Exception.Data['AutopilotExpress.GraphMethod'] = $Method
            $failure = Get-GraphTransportFailure -RequestError $_
            $credentialError = $_.Exception
            for ($depth = 0; $depth -lt 8 -and $credentialError; $depth++) {
                if ($failure.Status -eq '401' -or $credentialError -is [OperationCanceledException] -or
                    $credentialError.GetType().FullName -match '(AuthenticationFailedException|MsalUiRequiredException|MsalClientException)$' -or
                    $credentialError.Message -match '^(InteractiveBrowserCredential|DeviceCodeCredential) authentication failed:') {
                    $Script:GraphSession['RequiresReconnect'] = $true
                    Write-AutopilotExpressLog -Message 'Authentication stopped. Further requests are paused; use Reconnect to Microsoft Graph in Session and Script Settings. No automatic workflow replay.' -Level WARN
                    break
                }
                $credentialError = $credentialError.InnerException
            }
            if ($Method -ne 'GET' -or $failure.Status -notin @('429', '503', '504') -or $attempt -eq $policy.TransportMaxAttempts) {
                $reportedStatus = if ($failure.Status) { [string]$failure.Status } else { 'unavailable' }
                Write-AutopilotExpressLog -Message ('Graph {0} failed: HTTP={1}; attempt={2}; request-id={3}. No automatic replay. Exception={4}.' -f $Method, $reportedStatus, $attempt, $failure.RequestId, $_.Exception.GetType().FullName) -Level 'WARN'
                throw
            }
            $delay = $policy.TransportBackoffSeconds
            for ($backoffIndex = 1; $backoffIndex -lt $attempt; $backoffIndex++) { $delay *= 2 }
            if ($delay -gt $policy.TransportMaxDelaySeconds) { $delay = $policy.TransportMaxDelaySeconds }
            if ($null -ne $failure.RetryAfter) {
                if ($failure.RetryAfter -match '^[0-9]+$') { $delay = [double]$failure.RetryAfter }
                elseif ($failure.RetryAfter -match '^[A-Za-z]{3}, [0-9]{2} [A-Za-z]{3} [0-9]{4} [0-9]{2}:[0-9]{2}:[0-9]{2} GMT$') {
                    try { $retryDate = Get-Date -Date $failure.RetryAfter -ErrorAction Stop }
                    catch { throw 'Graph returned an invalid HTTP-date Retry-After header; no retry was issued.' }
                    $delay = ($retryDate - (Get-Date)).TotalSeconds
                    if ($delay -lt 0) { $delay = 0 }
                    $wholeSeconds = [int]$delay
                    if ($wholeSeconds -lt $delay) { $wholeSeconds++ }
                    $delay = $wholeSeconds
                }
                else { throw 'Graph returned an invalid Retry-After header; no retry was issued.' }
            }
            if ($delay -gt $policy.TransportMaxDelaySeconds) {
                Write-AutopilotExpressLog -Message ('Graph GET retry deferred: requested wait exceeds {0}s; request-id={1}. Return later.' -f $policy.TransportMaxDelaySeconds, $failure.RequestId) -Level 'WARN'
                throw
            }
            Write-AutopilotExpressLog -Message ('Graph GET retry: HTTP={0}; attempt={1}/{2}; wait={3}s; request-id={4}.' -f $failure.Status, $attempt, $policy.TransportMaxAttempts, $delay, $failure.RequestId) -Level 'WARN'
            if ($delay -gt 0) { Start-Sleep -Seconds ([int]$delay) }
        }
    }
}

function Invoke-GraphReadPrefetch {
    <#
    .SYNOPSIS
        Collect several Graph reads in one JSON batch request so later reads need no extra call.
    .DESCRIPTION
        Graph accepts up to 20 requests in one $batch call. Each successful (HTTP 200)
        answer is held in the Graph session against its exact URI and handed out once by
        Invoke-GraphApiRequest, which still applies every normal validation to it.

        Nothing here can change an outcome: a refused batch, an unexpected answer or any
        non-200 item is simply left out, so that read is made individually as before and
        reports its own genuine error. Only v1.0 GET URIs are batched; a lone remaining
        read is not batched because that would save nothing. Throttling limits still
        count each item inside a batch, so this reduces round trips, not service load.
    .PARAMETER Uri
        Absolute Graph v1.0 GET URIs exactly as the later reads will request them.
    .OUTPUTS
        Number of answers stored for later use.
    .LINK
        https://learn.microsoft.com/graph/json-batching
    #>
    param([Parameter(Mandatory)][AllowEmptyCollection()][string[]]$Uri)
    if (-not $Script:GraphSession.Connected -or $Script:GraphSession.IsSimulated -or $Script:GraphSession.RequiresReconnect) { return 0 }
    $tenantId = [string]$Script:GraphSession.TenantId
    $prefetch = $Script:GraphSession['ReadPrefetch']
    if ($prefetch -isnot [System.Collections.IDictionary] -or $prefetch.TenantId -cne $tenantId) {
        # Ordinal keys: serial numbers and IDs inside URIs must match exactly, including case.
        $prefetch = @{ TenantId = $tenantId; Items = [System.Collections.Generic.Dictionary[string, object]]::new([StringComparer]::Ordinal) }
        $Script:GraphSession['ReadPrefetch'] = $prefetch
    }
    $seen = [System.Collections.Generic.HashSet[string]]::new([StringComparer]::Ordinal)
    $pending = @($Uri | Where-Object { $_ -and $_.StartsWith('https://graph.microsoft.com/v1.0/', [StringComparison]::Ordinal) -and -not $prefetch.Items.ContainsKey($_) -and $seen.Add($_) })
    $stored = 0
    for ($offset = 0; $offset -lt $pending.Count; $offset += 20) {
        $chunk = @($pending[$offset..([Math]::Min($offset + 20, $pending.Count) - 1)])
        if ($chunk.Count -lt 2) { break }
        # Batch item URLs are relative to the /v1.0 root, so drop that five-character prefix.
        $requests = @(for ($index = 0; $index -lt $chunk.Count; $index++) { @{ id = [string]($index + 1); method = 'GET'; url = ([uri]$chunk[$index]).PathAndQuery.Substring(5) } })
        try { $response = Invoke-GraphApiRequest -Method POST -Uri 'https://graph.microsoft.com/v1.0/$batch' -Body @{ requests = $requests } }
        catch {
            Write-AutopilotExpressLog -Message ('A batched Graph read was not accepted; each item will be read on its own instead: {0}' -f (Get-GraphOperationFailureMessage -RequestError $_)) -Level INFO
            if ($Script:GraphSession.RequiresReconnect) { break }
            continue
        }
        foreach ($answer in @($response.responses)) {
            $position = 0
            if ($null -eq $answer -or -not [int]::TryParse([string]$answer.id, [ref]$position) -or $position -lt 1 -or $position -gt $chunk.Count) { continue }
            if ([string]$answer.status -ne '200' -or $null -eq $answer.body) { continue }
            $prefetch.Items[$chunk[$position - 1]] = $answer.body
            $stored++
        }
    }
    return $stored
}

function Clear-GraphReadPrefetch {
    <#
    .SYNOPSIS
        Discard any batched reads that were not used, so they can never be served later.
    .OUTPUTS
        None.
    #>
    if ($Script:GraphSession -is [System.Collections.IDictionary] -and $Script:GraphSession.Contains('ReadPrefetch')) { [void]$Script:GraphSession.Remove('ReadPrefetch') }
}

function Get-GraphCapabilityReadCheck {
    <#
    .SYNOPSIS
        List the four read-permission probes run after sign-in.
    .DESCRIPTION
        Shared by Test-GraphCapabilities and Invoke-LiveStartupRead so the batched
        startup read asks for exactly the URIs the probes later request.
    .OUTPUTS
        Array of @{ Name; Uri } dictionaries.
    #>
    return @(
        @{ Name = 'Autopilot identity read'; Uri = 'https://graph.microsoft.com/v1.0/deviceManagement/windowsAutopilotDeviceIdentities?$top=1' },
        @{ Name = 'Managed-device read'; Uri = 'https://graph.microsoft.com/v1.0/deviceManagement/managedDevices?$top=1&$select=id' },
        @{ Name = 'Entra device read'; Uri = 'https://graph.microsoft.com/v1.0/devices?$top=1&$select=id' },
        @{ Name = 'Directory user read'; Uri = 'https://graph.microsoft.com/v1.0/users?$top=1&$select=id' }
    )
}

function Get-PreProvisioningGroupLookupUri {
    <#
    .SYNOPSIS
        Build the exact Graph search used to find the pre-provisioning group by name.
    .PARAMETER GroupName
        Configured group display name; single quotes are escaped for the OData filter.
    .OUTPUTS
        Absolute Graph v1.0 URI string.
    #>
    param([Parameter(Mandatory)][ValidateNotNullOrEmpty()][string]$GroupName)
    return ('https://graph.microsoft.com/v1.0/groups?$filter=displayName eq ''{0}''&$select=id,displayName,securityEnabled,mailEnabled,groupTypes,isAssignableToRole' -f $GroupName.Replace("'", "''"))
}

function Get-ManagedDeviceSerialLookupUri {
    <#
    .SYNOPSIS
        Build the exact Graph search used to find a managed device by serial number.
    .PARAMETER Serial
        Canonical serial number; single quotes are escaped for the OData filter.
    .OUTPUTS
        Absolute Graph v1.0 URI string.
    #>
    param([Parameter(Mandatory)][ValidateNotNullOrEmpty()][string]$Serial)
    return ('https://graph.microsoft.com/v1.0/deviceManagement/managedDevices?$filter=serialNumber eq ''{0}''&$select=id,deviceName,serialNumber,userPrincipalName,azureADDeviceId' -f $Serial.Replace("'", "''"))
}

function Get-ManagedDeviceInventoryUri {
    <#
    .SYNOPSIS
        Build the exact Graph read that returns every Intune detail the script saves.
    .PARAMETER ManagedDeviceId
        Intune managed-device ID.
    .OUTPUTS
        Absolute Graph v1.0 URI string.
    #>
    param([Parameter(Mandatory)][ValidateNotNullOrEmpty()][string]$ManagedDeviceId)
    return ('https://graph.microsoft.com/v1.0/deviceManagement/managedDevices/{0}?$select=id,serialNumber,azureADDeviceId,deviceName,ethernetMacAddress,wiFiMacAddress,userPrincipalName,operatingSystem,osVersion,lastSyncDateTime' -f [uri]::EscapeDataString($ManagedDeviceId))
}

function Invoke-LiveStartupRead {
    <#
    .SYNOPSIS
        Run the after-sign-in organisation, permission and group checks with one Graph request.
    .DESCRIPTION
        Batches the organisation read, the four permission probes and (when configured)
        the group search, then runs Initialize-LiveTenantContext and Test-GraphCapabilities
        unchanged; they take their answers from the batch. Before batching this took six
        requests. Unused answers are discarded before returning.
    .PARAMETER StageTracker
        Optional dictionary whose Stage value is updated so the caller's failure message
        names the stage that was running.
    .OUTPUTS
        Capability results from Test-GraphCapabilities.
    #>
    param([System.Collections.IDictionary]$StageTracker = @{})
    try {
        $uris = @('https://graph.microsoft.com/v1.0/organization?$select=id,displayName') + @(Get-GraphCapabilityReadCheck | ForEach-Object { $_.Uri })
        $groupName = Get-ConfiguredPreProvisioningGroupDisplayName
        if (-not [string]::IsNullOrWhiteSpace($groupName) -and -not (Test-IsPlaceholderConfigurationValue -Value $groupName)) { $uris += Get-PreProvisioningGroupLookupUri -GroupName $groupName }
        $StageTracker.Stage = 'Organisation discovery and tenant binding'
        $null = Invoke-GraphReadPrefetch -Uri $uris
        Initialize-LiveTenantContext
        $StageTracker.Stage = 'Graph read capability preflight'
        return @(Test-GraphCapabilities)
    }
    finally { Clear-GraphReadPrefetch }
}

function Get-DeviceActionContext {
    <#
    .SYNOPSIS
        Bind device utilities to the Windows technician, mode and current tenant.
    .OUTPUTS
        Context dictionary. Live validates the actual Graph context before reuse.
    #>
    $tenant = if ($Script:Runtime.IsDemoMode) { 'demo' } else { Get-LiveTenantBinding }
    return @{ TenantId = $tenant; Mode = if ($Script:Runtime.IsDemoMode) { 'Demo' } else { 'Live' }; Actor = '{0}\{1}' -f [Environment]::UserDomainName, [Environment]::UserName }
}

function Get-DeviceActionStatePath {
    <#
    .SYNOPSIS
        Locate per-technician preferences and run evidence outside archived build sessions.
    .PARAMETER Context
        Validated mode/tenant context; no caller-controlled path components are accepted.
    .OUTPUTS
        Local-profile JSON path. Missing durable profile storage fails rather than using TEMP.
    #>
    param([Parameter(Mandatory)][System.Collections.IDictionary]$Context)
    if (-not $env:LOCALAPPDATA) { throw 'Device actions require a durable LOCALAPPDATA profile path.' }
    if ($Context.Mode -notin @('Live', 'Demo') -or
        ($Context.Mode -eq 'Live' -and $Context.TenantId -notmatch '^[0-9a-fA-F]{8}(-[0-9a-fA-F]{4}){3}-[0-9a-fA-F]{12}$') -or
        ($Context.Mode -eq 'Demo' -and $Context.TenantId -cne 'demo')) { throw 'Invalid device-action tenant/mode context.' }
    return Join-Path (Join-Path $env:LOCALAPPDATA 'PowerShellScriptingNew/AutopilotExpress/DeviceActions') ('{0}-{1}.json' -f $Context.Mode, $Context.TenantId)
}

function Assert-DeviceActionState {
    <#
    .SYNOPSIS
        Refuse foreign, malformed or ambiguous preference/submission evidence.
    .PARAMETER State
        Detached JSON dictionary including complete arrays, revision and identity metadata.
    .PARAMETER Context
        Fresh Windows-user, mode and tenant binding.
    .OUTPUTS
        None. Validation errors preserve the original file and do not start a run.
    #>
    param([Parameter(Mandatory)][System.Collections.IDictionary]$State, [Parameter(Mandatory)][System.Collections.IDictionary]$Context)
    if ($State.SchemaVersion -ne 1 -or $State.TenantId -ine $Context.TenantId -or $State.Mode -cne $Context.Mode -or $State.Actor -cne $Context.Actor -or
        [string]$State.Revision -notmatch '^\d{1,9}$' -or $State.EnabledIds -isnot [array] -or $State.Runs -isnot [array]) { throw 'Invalid or foreign device-action settings; preserve the file for review.' }
    $guidPattern = '^[0-9a-fA-F]{8}(-[0-9a-fA-F]{4}){3}-[0-9a-fA-F]{12}$'
    foreach ($id in $State.EnabledIds) {
        if ($id -isnot [string] -or $id -notmatch $guidPattern) { throw 'Invalid enabled remediation package identity.' }
    }
    if (@($State.EnabledIds | Sort-Object -Unique).Count -ne $State.EnabledIds.Count) { throw 'Duplicate enabled remediation package identities are not permitted.' }
    $seen = @{}
    foreach ($run in $State.Runs) {
        foreach ($field in @('RunId', 'PackageId', 'ManagedDeviceId')) {
            if ($run[$field] -isnot [string] -or $run[$field] -notmatch $guidPattern) { throw 'Invalid remediation run identity.' }
        }
        $timestamp = [DateTimeOffset]::MinValue
        if ($seen.ContainsKey($run.RunId) -or $run.State -notin @('Preparing', 'Accepted', 'Uncertain', 'ExecutionObserved') -or
            $run.SubmittedAt -isnot [string] -or -not [DateTimeOffset]::TryParse($run.SubmittedAt, [ref]$timestamp) -or
            [string]::IsNullOrWhiteSpace([string]$run.Serial) -or [string]::IsNullOrWhiteSpace([string]$run.RecordId)) { throw 'Invalid remediation run evidence; automatic replay is refused.' }
        $seen[$run.RunId] = $true
    }
}

function Get-DeviceActionState {
    <#
    .SYNOPSIS
        Load recovery-checked selections and submission history, initially enabling nothing.
    .OUTPUTS
        Validated dictionary. Viewing defaults does not create files or alter workflow evidence.
    #>
    $context = Get-DeviceActionContext
    $path = Get-DeviceActionStatePath -Context $context
    Assert-FileWriteRecoveryState -Path $path
    if (-not (Test-Path -LiteralPath $path)) {
        return @{ SchemaVersion = 1; Revision = 0; TenantId = $context.TenantId; Mode = $context.Mode; Actor = $context.Actor; EnabledIds = @(); Runs = @() }
    }
    if ((Get-Item -LiteralPath $path -ErrorAction Stop).Length -gt 10485760) { throw 'Device-action history exceeds 10 MiB; preserve it and arrange an authorised archive.' }
    $parameters = @{ ErrorAction = 'Stop' }
    if ((Get-Command ConvertFrom-Json).Parameters.ContainsKey('DateKind')) { $parameters.DateKind = 'String' }
    $decoded = Get-Content -LiteralPath $path -Raw -ErrorAction Stop | ConvertFrom-Json @parameters
    if ($decoded -isnot [pscustomobject]) { throw 'Device-action settings must be a JSON object.' }
    $state = ConvertTo-NormalisedValue $decoded
    Assert-DeviceActionState -State $state -Context $context
    return $state
}

function Save-DeviceActionState {
    <#
    .SYNOPSIS
        Persist a revision-checked change with guarded writes and a short exclusive file handle.
    .PARAMETER State
        Detached state read at the current revision; updated only after verified persistence.
    .OUTPUTS
        None. Concurrent/stale changes and incomplete saves fail closed without deleting evidence.
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param([Parameter(Mandatory)][System.Collections.IDictionary]$State)
    $context = Get-DeviceActionContext
    Assert-DeviceActionState -State $State -Context $context
    $path = Get-DeviceActionStatePath -Context $context
    if (-not $PSCmdlet.ShouldProcess($path, 'Save device-action selections and run evidence')) { return }
    New-ParentDirectory -Path $path
    $handle = [IO.File]::Open(('{0}.access.lock' -f $path), [IO.FileMode]::OpenOrCreate, [IO.FileAccess]::ReadWrite, [IO.FileShare]::None)
    try {
        $current = Get-DeviceActionState
        if ($current.Revision -ne $State.Revision) { throw 'Device-action settings changed in another session; reload before saving. No submission was replayed.' }
        $next = @{}
        foreach ($key in $State.Keys) { $next[$key] = $State[$key] }
        $next.Revision = [int]$State.Revision + 1
        Write-Utf8File -Path $path -Content ($next | ConvertTo-Json -Depth 16)
        $State.Revision = $next.Revision
    }
    finally { $handle.Dispose() }
}

function Assert-DeviceRemediationAccess {
    <#
    .SYNOPSIS
        Distinguish missing requested permissions from missing granted remediation access.
    .PARAMETER Operation
        Read checks catalogue/report access; Run also checks privileged device-action access.
    .OUTPUTS
        None. Throws actionable guidance without changing configuration, consent or authentication.
    #>
    param([ValidateSet('Read', 'Run')][string]$Operation = 'Read')
    if ($Script:Runtime.IsDemoMode) { return }
    $requirements = @(@{ Scopes = @('DeviceManagementScripts.Read.All', 'DeviceManagementScripts.ReadWrite.All'); Recommended = 'DeviceManagementScripts.Read.All' })
    if ($Operation -eq 'Run') {
        $requirements += @{ Scopes = @('DeviceManagementManagedDevices.PrivilegedOperations.All'); Recommended = 'DeviceManagementManagedDevices.PrivilegedOperations.All' }
    }
    $configured = @(Get-ConfiguredGraphScopes)
    foreach ($requirement in $requirements) {
        if (-not @($configured | Where-Object { $_ -in $requirement.Scopes }).Count) {
            throw ('Remediation access is not configured: the loaded runtime graph.requiredScopes lacks {0}. Update the deployed runtime file with tenant-owner approval, then restart the script; Settings > 9 alone does not reload configuration. No permission was added automatically.' -f $requirement.Recommended)
        }
    }
    $context = Get-MgContext -ErrorAction Stop
    foreach ($requirement in $requirements) {
        if (-not @($context.Scopes | Where-Object { $_ -in $requirement.Scopes }).Count) {
            throw ('Remediation permission is not granted in the current Graph session: {0}. Have the tenant administrator review delegated consent for this application and tenant, then use Settings > 9 (Reconnect). Restart first if the runtime file changed. Successful sign-in does not grant API access; no automatic sign-in or consent was attempted.' -f $requirement.Recommended)
        }
    }
}

function Get-DeviceRemediationCatalog {
    <#
    .SYNOPSIS
        Retrieve complete remediation metadata without downloading script contents.
    .DESCRIPTION
        Uses the approved beta catalogue through bounded paged discovery. Duplicate
        display names retain distinct immutable identities; malformed IDs fail closed.
        Demo returns labelled fixtures without accessing Graph.
    .OUTPUTS
        Alphabetically sorted package metadata array, including empty results.
    .LINK
        https://learn.microsoft.com/graph/api/intune-devices-devicehealthscript-list?view=graph-rest-beta
    #>
    if ($Script:Runtime.IsDemoMode) {
        return , @(
            @{ id = '11111111-1111-1111-1111-111111111111'; displayName = 'Demo application retry'; version = '1'; publisher = 'Demo'; description = 'Simulated remediation only.' },
            @{ id = '22222222-2222-2222-2222-222222222222'; displayName = 'Demo inventory check'; version = '1'; publisher = 'Demo'; description = 'Simulated remediation only.' }
        )
    }
    Assert-DeviceRemediationAccess
    $context = Get-DeviceActionContext
    try { $catalog = Get-GraphDiscoveryCollection -Uri 'https://graph.microsoft.com/beta/deviceManagement/deviceHealthScripts?$select=id,displayName,description,publisher,version,runAsAccount,runAs32Bit,enforceSignatureCheck,lastModifiedDateTime,deviceHealthScriptType' }
    catch {
        if ((Get-GraphTransportFailure -RequestError $_).Status -eq 403) {
            throw ('Remediation catalogue access denied (HTTP 403). Graph rejected this application/session despite its declared scopes. Ask the tenant administrator to verify delegated DeviceManagementScripts.Read.All consent for the signed-in application, Intune RBAC/licensing and tenant policy, then use Settings > 9 (Reconnect). No retry or permission change was attempted. {0}' -f (Get-GraphOperationFailureMessage -RequestError $_))
        }
        throw
    }
    foreach ($package in $catalog) {
        if ($package.id -isnot [string] -or $package.id -notmatch '^[0-9a-fA-F]{8}(-[0-9a-fA-F]{4}){3}-[0-9a-fA-F]{12}$') {
            throw 'Remediation catalogue returned an invalid package identity; no partial catalogue was published.'
        }
    }
    if ((Get-DeviceActionContext).TenantId -ine $context.TenantId) { throw 'Tenant changed during remediation discovery; no catalogue was published.' }
    return , @($catalog | Sort-Object @{ Expression = { [string]$_.displayName } }, @{ Expression = { [string]$_.id } })
}

function Resolve-DeviceActionTarget {
    <#
    .SYNOPSIS
        Refresh a detached selected device without retargeting saved workflow evidence.
    .PARAMETER Device
        Selected dictionary with RecordId and serial; cached object IDs are not trusted.
    .OUTPUTS
        Immutable target dictionary. Live requires a fresh Windows managed-device match.
    #>
    param([Parameter(Mandatory)][System.Collections.IDictionary]$Device)
    if (-not $Device.RecordId -or -not $Device.Serial) { throw 'Select a device with a record identity and serial first.' }
    $context = Get-DeviceActionContext
    $candidate = @{}
    foreach ($key in $Device.Keys) { $candidate[$key] = $Device[$key] }
    if ($Script:Runtime.IsDemoMode) { $candidate.ManagedDeviceId = [string]$Device.RecordId }
    else {
        [void](Get-LiveTenantBinding -Device $candidate -AllowUnbound)
        [void](Resolve-LiveAutopilotContext -Device $candidate)
    }
    if ($candidate.ManagedDeviceId -isnot [string] -or $candidate.ManagedDeviceId -notmatch '^[0-9a-fA-F]{8}(-[0-9a-fA-F]{4}){3}-[0-9a-fA-F]{12}$') { throw 'A unique current Intune managed-device identity is required.' }
    if (-not $Script:Runtime.IsDemoMode) {
        $managed = Invoke-GraphApiRequest -Method GET -Uri ('https://graph.microsoft.com/v1.0/deviceManagement/managedDevices/{0}?$select=id,serialNumber,operatingSystem,deviceName' -f $candidate.ManagedDeviceId)
        if ($managed.id -ine $candidate.ManagedDeviceId -or $managed.serialNumber -ine $Device.Serial -or $managed.operatingSystem -ine 'Windows') { throw 'Fresh Windows managed-device identity does not match the selected serial.' }
        if ((Get-LiveTenantBinding -Device $candidate) -ine $context.TenantId) { throw 'Tenant changed while resolving the device.' }
    }
    return @{ TenantId = $context.TenantId; RecordId = [string]$Device.RecordId; Serial = [string]$Device.Serial; ManagedDeviceId = [string]$candidate.ManagedDeviceId }
}

function Get-DeviceRemediationObservation {
    <#
    .SYNOPSIS
        Read complete package execution reports and match the exact managed device locally.
    .PARAMETER PackageId
        Immutable remediation package GUID.
    .PARAMETER Target
        Fresh tenant/device binding; no display-name or serial report matching is used.
    .OUTPUTS
        Matching report or null. No script output/content is requested or logged.
    .LINK
        https://learn.microsoft.com/graph/api/resources/intune-devices-devicehealthscriptdevicestate?view=graph-rest-beta
    #>
    param([Parameter(Mandatory)][ValidatePattern('^[0-9a-fA-F]{8}(-[0-9a-fA-F]{4}){3}-[0-9a-fA-F]{12}$')][string]$PackageId, [Parameter(Mandatory)][System.Collections.IDictionary]$Target)
    if ($Script:Runtime.IsDemoMode) { return $null }
    Assert-DeviceRemediationAccess
    if ((Get-DeviceActionContext).TenantId -ine $Target.TenantId) { throw 'Remediation report tenant changed.' }
    $reports = Get-GraphDiscoveryCollection -RequiredTextProperty id -Uri ('https://graph.microsoft.com/beta/deviceManagement/deviceHealthScripts/{0}/deviceRunStates?$select=id,lastStateUpdateDateTime,detectionState,remediationState&$expand=managedDevice($select=id)' -f $PackageId)
    foreach ($report in $reports) {
        if (-not $report.managedDevice.id) { throw 'Remediation report contains limited device identity; absence cannot be inferred.' }
    }
    $reportMatches = @($reports | Where-Object { $_.managedDevice.id -ieq $Target.ManagedDeviceId })
    if ($reportMatches.Count -gt 1) { throw 'Multiple remediation reports match the selected device; execution evidence is ambiguous.' }
    if ((Get-DeviceActionContext).TenantId -ine $Target.TenantId) { throw 'Tenant changed during remediation status discovery.' }
    if ($reportMatches.Count -eq 1) { return $reportMatches[0] }
    return $null
}

function Invoke-DeviceRemediation {
    <#
    .SYNOPSIS
        Confirm one enabled package/Windows target and durably reserve one submission.
    .DESCRIPTION
        Save intent before POST. Accepted, lost-response and process-loss evidence prevents
        implicit replay across restarts. A fresh report permits a separately confirmed new run,
        but cannot correlate a scheduled execution uniquely to this on-demand request.
    .PARAMETER Device
        Selected workflow record; the workflow and checklist remain unchanged.
    .PARAMETER PackageId
        Tenant package identity explicitly enabled in this technician's quick-run preferences.
    .OUTPUTS
        Submission/evidence dictionary; acceptance never asserts device execution or success.
    .LINK
        https://learn.microsoft.com/graph/api/intune-devices-manageddevice-initiateondemandproactiveremediation?view=graph-rest-beta
    #>
    [CmdletBinding(SupportsShouldProcess)]
    [OutputType([hashtable])]
    param([Parameter(Mandatory)][System.Collections.IDictionary]$Device, [Parameter(Mandatory)][ValidatePattern('^[0-9a-fA-F]{8}(-[0-9a-fA-F]{4}){3}-[0-9a-fA-F]{12}$')][string]$PackageId)
    $state = Get-DeviceActionState
    if ($PackageId -notin $state.EnabledIds) { throw 'This remediation is not enabled for the current technician and tenant.' }
    Assert-DeviceRemediationAccess -Operation Run
    $target = Resolve-DeviceActionTarget -Device $Device
    if ($target.TenantId -ine $state.TenantId) { throw 'Remediation target tenant differs from the saved selections.' }
    $previous = @($state.Runs | Where-Object { $_.PackageId -ieq $PackageId -and $_.ManagedDeviceId -ieq $target.ManagedDeviceId } | Select-Object -Last 1)
    if ($previous.Count -and $previous[0].State -ne 'ExecutionObserved') {
        return @{ State = $previous[0].State; RunId = $previous[0].RunId; Summary = 'A previous request is accepted or uncertain. Check status; no submission was replayed.' }
    }
    if ($Script:Runtime.IsDemoMode) {
        $demoCatalog = Get-DeviceRemediationCatalog
        $package = $demoCatalog | Where-Object { $_.id -ieq $PackageId }
    }
    else { $package = Invoke-GraphApiRequest -Method GET -Uri ('https://graph.microsoft.com/beta/deviceManagement/deviceHealthScripts/{0}?$select=id,displayName,version,lastModifiedDateTime' -f $PackageId) }
    if ($package.id -ine $PackageId -or [string]::IsNullOrWhiteSpace([string]$package.displayName)) { throw 'The enabled package no longer resolves to its expected immutable identity.' }
    Write-Host ('Tenant={0} | Serial={1} | Intune device={2}' -f $target.TenantId, $target.Serial, $target.ManagedDeviceId)
    Write-Host ('Remediation: {0} | version={1} | ID={2}' -f $package.displayName, $package.version, $PackageId)
    Write-Host 'Acceptance is not proof of execution. Existing unresolved requests are never automatically repeated.'
    if (-not $PSCmdlet.ShouldProcess($target.ManagedDeviceId, ('Submit remediation {0}' -f $PackageId))) { return @{ State = 'Cancelled'; Summary = 'No remediation submitted.' } }
    if ((Read-ValidatedInput -Prompt 'Submit this remediation to this device? [Y] Yes [N] No' -Default N -Type Choice -Choices @('Y', 'N')) -ine 'Y') { return @{ State = 'Cancelled'; Summary = 'No remediation submitted.' } }
    $fresh = Resolve-DeviceActionTarget -Device $Device
    if ($fresh.ManagedDeviceId -ine $target.ManagedDeviceId -or $fresh.TenantId -ine $target.TenantId) { throw 'Device identity changed after confirmation; nothing was submitted.' }
    Assert-DeviceRemediationAccess -Operation Run
    $baseline = Get-DeviceRemediationObservation -PackageId $PackageId -Target $target
    $run = @{ RunId = [guid]::NewGuid().ToString(); PackageId = $PackageId; PackageName = [string]$package.displayName; ManagedDeviceId = $target.ManagedDeviceId; Serial = $target.Serial; RecordId = $target.RecordId; SubmittedAt = [DateTimeOffset]::UtcNow.ToString('o'); BaselineAt = [string]$baseline.lastStateUpdateDateTime; State = 'Preparing'; LastCheckedAt = ''; ObservationAt = ''; DetectionState = ''; RemediationState = '' }
    $state.Runs = @($state.Runs) + @($run)
    Save-DeviceActionState -State $state
    $accepted = $false
    try {
        if (-not $Script:Runtime.IsDemoMode) {
            if ((Get-DeviceActionContext).TenantId -ine $target.TenantId) { throw 'Tenant changed before submission.' }
            Invoke-GraphApiRequest -Method POST -Uri ('https://graph.microsoft.com/beta/deviceManagement/managedDevices/{0}/initiateOnDemandProactiveRemediation' -f $target.ManagedDeviceId) -Body @{ scriptPolicyId = $PackageId } | Out-Null
        }
        $accepted = $true
        $run.State = 'Accepted'
    }
    catch { $run.State = 'Uncertain'; Write-AutopilotExpressLog -Message ('Remediation submission outcome is uncertain for run {0}; no automatic replay. {1}' -f $run.RunId, (Get-GraphOperationFailureMessage -RequestError $_)) -Level WARN }
    try { Save-DeviceActionState -State $state }
    catch { return @{ State = $run.State; RunId = $run.RunId; Persisted = $false; Summary = 'Submission outcome could not be durably updated. Preserve intent/recovery evidence; do not repeat the request.' } }
    $summary = if ($Script:Runtime.IsDemoMode) { 'Demo: simulated acceptance only; no device action occurred.' } elseif ($accepted) { 'Remediation request accepted by Graph. Device start and completion are not yet confirmed; use Check status.' } else { 'Submission outcome is uncertain. Check tenant/device status; no automatic retry is permitted.' }
    Write-AutopilotExpressLog -Message ('Remediation run {0}: {1}; package={2}; managed-device={3}.' -f $run.RunId, $run.State, $PackageId, $target.ManagedDeviceId) -Level INFO
    return @{ State = $run.State; RunId = $run.RunId; Persisted = $true; Summary = $summary }
}

function Get-DeviceRemediationRunStatus {
    <#
    .SYNOPSIS
        Refresh execution evidence without resubmitting or asserting request correlation.
    .PARAMETER Device
        Original selected workflow; changed device/record identity refuses old evidence reuse.
    .PARAMETER RunId
        Locally durable submission identity; it is not a Graph execution correlation ID.
    .OUTPUTS
        Accepted/uncertain or fresh ExecutionObserved evidence, with separate script result states.
    #>
    param([Parameter(Mandatory)][System.Collections.IDictionary]$Device, [Parameter(Mandatory)][string]$RunId)
    $state = Get-DeviceActionState
    $runs = @($state.Runs | Where-Object { $_.RunId -ceq $RunId })
    if ($runs.Count -ne 1) { throw 'No unique saved remediation request exists for this selection.' }
    $run = $runs[0]
    $target = Resolve-DeviceActionTarget -Device $Device
    if ($run.ManagedDeviceId -ine $target.ManagedDeviceId -or $run.RecordId -cne $target.RecordId -or $run.Serial -ine $target.Serial -or $state.TenantId -ine $target.TenantId) { throw 'Remediation request target changed; original evidence was retained.' }
    if ($Script:Runtime.IsDemoMode) { return @{ State = 'Accepted'; Summary = 'Demo: no actual device execution can be confirmed.' } }
    $observation = Get-DeviceRemediationObservation -PackageId $run.PackageId -Target $target
    $observedAt = [DateTimeOffset]::MinValue
    $baselineAt = [DateTimeOffset]::MinValue
    $submittedAt = [DateTimeOffset]::Parse($run.SubmittedAt)
    $hasTime = [DateTimeOffset]::TryParse([string]$observation.lastStateUpdateDateTime, [ref]$observedAt)
    if ($run.BaselineAt -and -not [DateTimeOffset]::TryParse([string]$run.BaselineAt, [ref]$baselineAt)) { throw 'Stored baseline timestamp is malformed; execution cannot be confirmed.' }
    $run.LastCheckedAt = [DateTimeOffset]::UtcNow.ToString('o')
    $summary = 'No fresh device execution is confirmed. Pending/offline/report delay does not authorise replay.'
    if ($hasTime -and $observedAt -gt $baselineAt -and $observedAt -ge $submittedAt -and $observedAt -le [DateTimeOffset]::UtcNow -and $observation.detectionState -in @('success', 'fail', 'scriptError', 'notApplicable')) {
        $run.State = 'ExecutionObserved'
        $run.ObservationAt = $observedAt.ToString('o')
        $run.DetectionState = [string]$observation.detectionState
        $run.RemediationState = [string]$observation.remediationState
        $summary = 'Fresh device execution reported. Scheduled/concurrent execution cannot be uniquely correlated to this request; script result is shown separately.'
    }
    Save-DeviceActionState -State $state
    return @{ State = $run.State; RunId = $run.RunId; ObservationAt = $run.ObservationAt; DetectionState = $run.DetectionState; RemediationState = $run.RemediationState; Summary = $summary }
}

function Copy-DeviceIntuneOverviewLink {
    <#
    .SYNOPSIS
        Copy the fresh managed-device overview link to this technician PC's clipboard.
    .PARAMETER Device
        Selected device; Live identity is re-resolved before constructing the portal route.
    .OUTPUTS
        Link and copy outcome. Portal sign-in must use the displayed tenant; no remote clipboard action occurs.
    #>
    [CmdletBinding(SupportsShouldProcess)]
    [OutputType([hashtable])]
    param([Parameter(Mandatory)][System.Collections.IDictionary]$Device)
    if ($Script:Runtime.IsDemoMode) { return @{ State = 'Simulated'; Summary = 'Demo: no real Intune device link or clipboard change.' } }
    $target = Resolve-DeviceActionTarget -Device $Device
    $link = 'https://intune.microsoft.com/#view/Microsoft_Intune_Devices/DeviceSettingsMenuBlade/~/overview/mdmDeviceId/{0}' -f [uri]::EscapeDataString($target.ManagedDeviceId)
    if (-not $PSCmdlet.ShouldProcess('Technician PC clipboard', 'Copy selected Intune device overview link')) { return @{ State = 'Cancelled'; Url = $link; Summary = 'Clipboard unchanged.' } }
    Write-Host ('Intune overview: {0}' -f $link)
    Set-Clipboard -Value $link -ErrorAction Stop
    $copied = Get-Clipboard -Raw -ErrorAction Stop
    if ([string]$copied -cne $link) { throw 'Clipboard read-back did not match the device link; copy was not confirmed.' }
    return @{ State = 'Copied'; Url = $link; Summary = 'Copied Intune overview for Serial={0}. Portal tenant must be {1}.' -f $target.Serial, $target.TenantId }
}

function Select-RemediationMenuItem {
    <#
    .SYNOPSIS
        Page immutable package/request choices with zero/Enter cancellation.
    .PARAMETER Items
        Detached choices with id/displayName; empty collections offer no selection.
    .PARAMETER Title
        Caller-owned prompt context. N/P page; invalid or out-of-range choices re-prompt.
    .OUTPUTS
        One original item or null; duplicate names are distinguished by ID.
    #>
    param([AllowEmptyCollection()][object[]]$Items = @(), [Parameter(Mandatory)][string]$Title)
    if (-not $Items.Count) { Write-Host 'No matching remediation packages or requests.'; return $null }
    $start = 0
    while ($true) {
        Show-ScriptScreen -Title $Title
        for ($index = $start; $index -lt [Math]::Min($start + 15, $Items.Count); $index++) {
            Write-Host ('{0}. {1} | ID={2} | version={3} | publisher={4}' -f ($index + 1), $Items[$index].displayName, $Items[$index].id, $Items[$index].version, $Items[$index].publisher)
        }
        $choice = Read-ValidatedInput -Prompt 'Selection (N next, P previous, 0 returns)' -Default '0'
        if ($choice -eq '0') { return $null }
        if ($choice -ieq 'N') { if ($start + 15 -lt $Items.Count) { $start += 15 }; continue }
        if ($choice -ieq 'P') { $start = [Math]::Max(0, $start - 15); continue }
        $selected = ConvertTo-OptionalInteger -Value $choice
        if ($null -ne $selected -and $selected -ge 1 -and $selected -le $Items.Count) { return $Items[$selected - 1] }
        Write-Host 'Choose a listed item number, N, P, or 0.'
    }
}

function Show-RemediationQuickRunSettings {
    <#
    .SYNOPSIS
        Discover tenant packages and explicitly save this technician's quick-run selection.
    .DESCRIPTION
        Numbers toggle a detached selection via the paged picker. Nothing is initially enabled;
        stale/deleted IDs are shown for removal. Save defaults No; closing dirty settings offers
        save/discard/continue, never silently dropping edits. Failed saves retain the proposal.
    .PARAMETER PassThru
        Return an initial load failure to the owning device screen instead of acknowledging it here.
    .OUTPUTS
        Host output, or a failure dictionary with PassThru. No remediation or workflow milestone changes.
    #>
    param([switch]$PassThru)
    try { $state = Get-DeviceActionState; $catalog = Get-DeviceRemediationCatalog }
    catch {
        $failure = @{ State = 'Blocked'; Summary = 'Cannot load remediation settings: {0}' -f (Get-GraphOperationFailureMessage -RequestError $_) }
        if ($PassThru) { return $failure }
        Write-Host $failure.Summary
        $null = Read-ValidatedInput -Prompt 'Remediation settings unavailable; 0 returns' -Default '0' -Type Choice -Choices @('0')
        return
    }
    $enabled = @($state.EnabledIds)
    while ($true) {
        Show-ScriptScreen -Title 'My quick-run device remediations'
        Write-Host ('Tenant={0} | Technician={1} | Enabled={2} | Available={3}' -f $state.TenantId, $state.Actor, $enabled.Count, $catalog.Count)
        $items = @($catalog | ForEach-Object {
                $indicator = if ($_.id -in $enabled) { '[Enabled]' } else { '[Disabled]' }
                @{ id = $_.id; displayName = '{0} {1}' -f $indicator, $_.displayName; version = $_.version; publisher = $_.publisher; Unavailable = $false }
            })
        foreach ($id in $enabled) {
            if ($id -notin @($catalog | ForEach-Object { $_.id })) { $items += @{ id = $id; displayName = '[Unavailable; disable this saved package]'; version = ''; publisher = ''; Unavailable = $true } }
        }
        foreach ($item in $items | Where-Object { $_.id -in $enabled }) { Write-Host ('Enabled: {0} | {1}' -f $item.displayName, $item.id) }
        Write-Host '1. Select a package to enable/disable'
        Write-Host '2. Save selections'
        Write-Host '3. Refresh tenant catalogue'
        Write-Host '0. Return'
        $choice = Read-ValidatedInput -Prompt 'Quick-run settings' -Default '0' -Type Choice -Choices @('0', '1', '2', '3')
        if ($choice -eq '1') {
            $item = Select-RemediationMenuItem -Items $items -Title 'Enable or disable a quick-run remediation'
            if ($null -ne $item) {
                if ($item.id -in $enabled) { $enabled = @($enabled | Where-Object { $_ -ine $item.id }) }
                elseif (-not $item.Unavailable) { $enabled += [string]$item.id }
            }
            continue
        }
        if ($choice -eq '3') {
            try { $catalog = Get-DeviceRemediationCatalog; if ((Get-DeviceActionContext).TenantId -ine $state.TenantId) { throw 'Tenant changed; close settings and reconnect.' } }
            catch { Write-Host ('Catalogue refresh failed: {0}' -f (Get-GraphOperationFailureMessage -RequestError $_)) }
            continue
        }
        $dirty = (($enabled | Sort-Object) -join '|') -cne (($state.EnabledIds | Sort-Object) -join '|')
        if (-not $dirty) { if ($choice -eq '0') { return }; Write-Host 'Selections are unchanged.'; continue }
        $prompt = if ($choice -eq '0') { 'Save pending quick-run changes? [Y] Save [N] Discard [C] Continue editing' } else { 'Save these quick-run selections? [Y] Yes [N] No' }
        $confirmChoices = if ($choice -eq '0') { @('Y', 'N', 'C') } else { @('Y', 'N') }
        $confirmation = Read-ValidatedInput -Prompt $prompt -Default N -Type Choice -Choices $confirmChoices
        if ($confirmation -ieq 'C') { continue }
        if ($confirmation -ine 'Y') { if ($choice -eq '0') { return }; continue }
        try {
            $fresh = Get-DeviceRemediationCatalog
            if (@($enabled | Where-Object { $_ -notin @($fresh | ForEach-Object { $_.id }) }).Count) { throw 'An enabled package is unavailable; disable that saved ID before saving.' }
            $proposal = @{}
            foreach ($key in $state.Keys) { $proposal[$key] = $state[$key] }
            $proposal.EnabledIds = @($enabled | Sort-Object -Unique)
            Save-DeviceActionState -State $proposal
            $state = $proposal
            Write-Host 'Quick-run selections saved for this technician and tenant.'
            if ($choice -eq '0') { return }
        }
        catch { Write-Host ('Selections were not saved; pending edits retained. {0}' -f (Get-GraphOperationFailureMessage -RequestError $_)) }
    }
}

function Show-DeviceActions {
    <#
    .SYNOPSIS
        Share remediation run/status and clipboard commands between bench and device menus.
    .PARAMETER Records
        Existing workflow records used only for explicit device selection.
    .PARAMETER Device
        Already selected bench record, or omit for the existing serial/CI picker.
    .PARAMETER ReturnDestination
        Actual caller shown on zero/Enter return; helpers never navigate recursively.
    .OUTPUTS
        Last structured utility result for bench feedback, or null. No checklist step is changed.
    #>
    param([Parameter(Mandatory)][hashtable]$Records, [System.Collections.IDictionary]$Device, [string]$ReturnDestination = 'Device commands')
    if ($null -eq $Device) { $Device = Select-DeviceFromRecords -Records $Records -Purpose 'run device actions' -IncludeCompleted }
    if ($null -eq $Device) { return $null }
    $lastResult = $null
    while ($true) {
        Show-ScriptScreen -Title 'Device actions'
        Write-Host ('Serial={0} | CI={1}' -f $Device.Serial, $Device.ConfigItem)
        if ($lastResult) {
            Write-Host ('{0}: {1}' -f $lastResult.State, $lastResult.Summary)
            if ($lastResult.ObservationAt) { Write-Host ('Execution report={0} | detection={1} | remediation={2}' -f $lastResult.ObservationAt, $lastResult.DetectionState, $lastResult.RemediationState) }
        }
        Write-Host '1. Run an enabled quick remediation'
        Write-Host '2. Check a saved remediation request (no resubmission)'
        Write-Host '3. Copy device Intune overview link to this PC clipboard'
        Write-Host '4. Choose my quick-run remediations'
        Write-Host '[5] Generate/reprint birth certificate or checklist for this saved device'
        Write-Host ('0. Return to {0}' -f $ReturnDestination)
        $choice = Read-ValidatedInput -Prompt 'Device action' -Default '0' -Type Choice -Choices @('0', '1', '2', '3', '4', '5')
        if ($choice -eq '0') { return $lastResult }
        try {
            switch ($choice) {
                '1' {
                    $state = Get-DeviceActionState
                    $catalog = Get-DeviceRemediationCatalog
                    if ((Get-DeviceActionContext).TenantId -ine $state.TenantId) { throw 'Tenant changed; reload device actions.' }
                    $available = @($catalog | Where-Object { $_.id -in $state.EnabledIds })
                    $package = Select-RemediationMenuItem -Items $available -Title 'Run an enabled remediation'
                    if ($null -ne $package) { $lastResult = Invoke-DeviceRemediation -Device $Device -PackageId $package.id }
                }
                '2' {
                    $state = Get-DeviceActionState
                    $items = @($state.Runs | Where-Object { $_.RecordId -ceq $Device.RecordId -and $_.Serial -ieq $Device.Serial } | ForEach-Object {
                            @{ id = $_.RunId; displayName = '{0} | {1} | {2}' -f $_.SubmittedAt, $_.PackageName, $_.State; version = ''; publisher = '' }
                        })
                    $request = Select-RemediationMenuItem -Items $items -Title 'Check remediation execution evidence'
                    if ($null -ne $request) { $lastResult = Get-DeviceRemediationRunStatus -Device $Device -RunId $request.id }
                }
                '3' { $lastResult = Copy-DeviceIntuneOverviewLink -Device $Device }
                '4' {
                    $settingsResult = Show-RemediationQuickRunSettings -PassThru
                    if ($settingsResult) { $lastResult = $settingsResult }
                }
                '5' { Request-DeviceDocumentReprint -Device $Device -Records $Records }
            }
        }
        catch { $lastResult = @{ State = 'NotCompleted'; Summary = Get-GraphOperationFailureMessage -RequestError $_ } }
    }
}

function Get-GraphDiscoveryCollection {
    <#
    .SYNOPSIS
        Read complete, bounded Graph discovery pages without returning partial data.
    .PARAMETER Uri
        Initial Microsoft Graph collection URI. Continuations must retain its path.
    .PARAMETER RequiredTextProperty
        Required identity field: displayName for discovery, serialNumber for
        Autopilot, or id for limited-information direct membership responses.
    .OUTPUTS
        Complete array of validated identities; no partial results on failure.
    #>
    param(
        [Parameter(Mandatory)][ValidateNotNullOrEmpty()][string]$Uri,
        [ValidateSet('displayName', 'serialNumber', 'id')][string]$RequiredTextProperty = 'displayName'
    )
    $initialUri = [uri]$Uri
    $currentUri = $Uri
    $visited = @()
    $items = @()
    $seenIds = @{}
    while ($currentUri) {
        $pageUri = [uri]$currentUri
        if ($pageUri.Scheme -ne 'https' -or $pageUri.Host -ne 'graph.microsoft.com' -or $pageUri.Port -ne 443 -or
            $pageUri.UserInfo -or $pageUri.Fragment -or $pageUri.AbsolutePath -cne $initialUri.AbsolutePath) { throw 'Unsafe Graph discovery continuation URI.' }
        if ($currentUri -in $visited -or $visited.Count -ge 20) { throw 'Graph discovery is incomplete: repeated page or 20-page limit reached.' }
        $visited += $currentUri
        $response = Invoke-GraphApiRequest -Method GET -Uri $currentUri
        if ($null -eq $response -or $response.value -isnot [array]) { throw 'Graph discovery returned a malformed collection.' }
        foreach ($item in $response.value) {
            if ($item.id -isnot [string] -or [string]::IsNullOrWhiteSpace($item.id) -or $item.$RequiredTextProperty -isnot [string] -or [string]::IsNullOrWhiteSpace($item.$RequiredTextProperty)) { throw 'Graph discovery returned an invalid identity (missing or unexpected identity fields).' }
            if ($seenIds.ContainsKey($item.id)) { throw 'Graph discovery returned a repeated identity.' }
            $seenIds[$item.id] = $true
            $items += , $item
        }
        $nextLink = $response.'@odata.nextLink'
        if ($null -ne $nextLink -and ($nextLink -isnot [string] -or [string]::IsNullOrWhiteSpace($nextLink))) { throw 'Graph discovery returned an invalid continuation.' }
        $currentUri = $nextLink
    }
    return , $items
}

function Initialize-LiveTenantContext {
    <#
    .SYNOPSIS
        Resolve required profile/group context after validated Graph sign-in.
    .OUTPUTS
        None. Populates runtime context or throws; group lookup errors omit raw SDK text.
    #>
    $tenantId = Get-LiveTenantBinding
    $organisations = Get-GraphDiscoveryCollection -Uri 'https://graph.microsoft.com/v1.0/organization?$select=id,displayName'
    if ($organisations.Count -ne 1 -or $organisations[0].id -ine $tenantId) { throw 'Organisation discovery must return exactly one identity matching the authenticated TenantId.' }
    $Script:RuntimeConfig.organisationName = [string]$organisations[0].displayName
    $Script:Config.OrganisationName = [string]$organisations[0].displayName
    Write-AutopilotExpressLog -Message ('Resolved tenant organisation: {0}.' -f $Script:Config.OrganisationName) -Level 'INFO'

    $configuredProfileName = [string]$Script:RuntimeConfig.autopilot.deploymentProfileDisplayName
    if (Test-IsPlaceholderConfigurationValue -Value $configuredProfileName) {
        $profileItems = Get-GraphDiscoveryCollection -Uri 'https://graph.microsoft.com/beta/deviceManagement/windowsAutopilotDeploymentProfiles?$select=id,displayName'
        $profiles = @($profileItems | Sort-Object displayName)
        if ($profiles.Count -eq 0) { throw 'No Windows Autopilot deployment profiles were returned by the tenant.' }

        Write-Host 'Select Autopilot deployment profile:'
        for ($index = 0; $index -lt $profiles.Count; $index++) {
            Write-Host ('{0}. {1}' -f ($index + 1), $profiles[$index].displayName)
        }
        $profileChoice = Read-ValidatedInput -Prompt 'Choose deployment profile number' -Default '1' -Type 'Int'
        $profileIndex = (ConvertTo-OptionalInteger -Value $profileChoice) - 1
        if ($profileIndex -lt 0 -or $profileIndex -ge $profiles.Count) { throw 'The selected deployment profile number is invalid.' }
        $Script:RuntimeConfig.autopilot.deploymentProfileDisplayName = [string]$profiles[$profileIndex].displayName
        Write-AutopilotExpressLog -Message ('Selected tenant Autopilot deployment profile: {0}.' -f $Script:RuntimeConfig.autopilot.deploymentProfileDisplayName) -Level 'INFO'
    }

    $configuredGroupName = [string]$Script:RuntimeConfig.autopilot.preProvisioningGroupDisplayName
    while (Test-IsPlaceholderConfigurationValue -Value $configuredGroupName) {
        $configuredGroupName = Read-ValidatedInput -Prompt 'Enter the pre-provisioning group display name'
        $Script:RuntimeConfig.autopilot.preProvisioningGroupDisplayName = $configuredGroupName
        try {
            $group = Get-LivePreProvisioningGroup
            Write-AutopilotExpressLog -Message ('Resolved pre-provisioning group: {0} ({1}).' -f $group.displayName, $group.id) -Level 'INFO'
        }
        catch {
            Write-Host ('The specified pre-provisioning group could not be uniquely resolved: {0}' -f (Get-GraphOperationFailureMessage -RequestError $_))
            $configuredGroupName = ''
            $Script:RuntimeConfig.autopilot.preProvisioningGroupDisplayName = ''
        }
    }
}

function Test-GraphCapabilities {
    <#
    .SYNOPSIS
        Probe read surfaces and reject malformed successful collection responses.
    .OUTPUTS
        Capability results with safe failure diagnostics. Valid empty collections prove read
        access only, not write permission, object absence or checklist acceptance.
    #>
    $results = @()
    $readChecks = Get-GraphCapabilityReadCheck

    foreach ($check in $readChecks) {
        try {
            $response = Invoke-GraphApiRequest -Method 'GET' -Uri $check.Uri
            if ($null -eq $response -or $response.value -isnot [array]) { throw 'Capability read returned a malformed collection.' }
            foreach ($item in $response.value) {
                if ($item.id -isnot [string] -or [string]::IsNullOrWhiteSpace($item.id)) { throw 'Capability read returned an invalid identity.' }
            }
            $results += [ordered]@{ Name = $check.Name; Success = $true; Detail = 'Read access confirmed.' }
        }
        catch {
            $results += [ordered]@{ Name = $check.Name; Success = $false; Detail = Get-GraphOperationFailureMessage -RequestError $_ }
        }
    }

    try {
        $group = Get-LivePreProvisioningGroup
        $results += [ordered]@{ Name = 'Pre-provisioning group read'; Success = $true; Detail = ('Resolved group {0} ({1}).' -f $group.displayName, $group.id) }
    }
    catch {
        $results += [ordered]@{ Name = 'Pre-provisioning group read'; Success = $false; Detail = Get-GraphOperationFailureMessage -RequestError $_ }
    }

    return @($results)
}

function Initialize-GraphSession {
    <#
    .SYNOPSIS
        Establish Demo context or a validated, stage-labelled Live Graph session.
    .DESCRIPTION
        Display SDK sign-in instructions from its success stream as they arrive.
        Graph SDK 2.41.1 emits its device-code message through WriteObject;
        discarding that stream hides the instructions until authentication times out.
        After an SDK sign-in failure or returned cancellation, require an explicit
        method selection before retrying. Enter cancels; choices affect this call
        only. Context validation and later read failures are not retried here.
    .OUTPUTS
        Boolean readiness; retains identity, organisation and read-capability evidence.
        Failure clears session state without logging SDK response bodies or tokens.
    #>
    if ($Script:Runtime.IsDemoMode) {
        $demoUpn = if ($Script:RuntimeConfig.demo.technicianUserPrincipalName) { [string]$Script:RuntimeConfig.demo.technicianUserPrincipalName } else { 'c.demo.tech@examplehealth.network' }
        $demoDisplayName = if ($Script:RuntimeConfig.demo.technicianDisplayName) { [string]$Script:RuntimeConfig.demo.technicianDisplayName } else { 'Demo Technician' }
        $Script:GraphSession = [ordered]@{
            Connected         = $true
            RequiresReconnect = $false
            IsSimulated       = $true
            Account           = $demoUpn
            DisplayName       = $demoDisplayName
            UserId            = [guid]::NewGuid().Guid
            TenantId          = ''
            Scopes            = @()
            CapabilityResults = @([ordered]@{ Name = 'Demo simulation'; Success = $true; Detail = 'Graph capability preflight is simulated in Demo mode.' })
        }
        Write-AutopilotExpressLog -Message ('Demo mode: simulated browser login completed for {0}.' -f $demoUpn) -Level 'INFO'
        return $true
    }

    $Script:GraphSession = Get-EmptyGraphSession
    $configIssues = Test-LiveRuntimeConfiguration
    if ($configIssues.Count -gt 0) {
        foreach ($issue in $configIssues) {
            Write-AutopilotExpressLog -Message $issue -Level 'ERROR'
        }
        return $false
    }

    if (-not (Import-RequiredGraphModules)) { return $false }

    $startupStage = 'Transport configuration'
    try {
        Initialize-GraphTransport -Policy (Get-GraphTransportPolicy)
        $expectedTenantId = $Script:RuntimeConfig.graph.expectedTenantId
        if ($null -ne $expectedTenantId -and ($expectedTenantId -isnot [string] -or
                ($expectedTenantId -cne '' -and $expectedTenantId -notmatch '^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$'))) {
            throw 'Configured expectedTenantId must be empty or a tenant GUID string.'
        }
        $connectParameters = @{ Scopes = (Get-ConfiguredGraphScopes); ContextScope = ([string]$Script:RuntimeConfig.graph.contextScope); NoWelcome = $true; ErrorAction = 'Stop'; Verbose = $false; Debug = $false }
        if ($expectedTenantId) { $connectParameters.TenantId = $expectedTenantId }
        $selectedAuthMode = [string]$Script:RuntimeConfig.graph.authMode
        while ($true) {
            try {
                [void]$connectParameters.Remove('UseDeviceCode')
                [void]$connectParameters.Remove('UseDeviceAuthentication')
                $startupStage = 'Browser sign-in'
                if ($selectedAuthMode -eq 'DeviceCode') {
                    $startupStage = 'Device-code sign-in'
                    $connectCommand = Get-Command Connect-MgGraph -ErrorAction Stop
                    if ($connectCommand.Parameters.ContainsKey('UseDeviceCode')) { $connectParameters.UseDeviceCode = $true }
                    elseif ($connectCommand.Parameters.ContainsKey('UseDeviceAuthentication')) { $connectParameters.UseDeviceAuthentication = $true }
                    else { throw 'The installed Graph SDK does not expose device-code authentication. No browser fallback was attempted.' }
                }
                Write-AutopilotExpressLog -Message ('Starting Microsoft Graph {0}. Session override: -AuthMode Browser or -AuthMode DeviceCode.' -f $startupStage) -Level 'INFO'
                Connect-MgGraph @connectParameters | Out-Host
                break
            }
            catch {
                $authenticationError = $_
                Write-AutopilotExpressLog -Message ('Microsoft Graph {0} did not complete. Exception={1}. No automatic fallback was attempted.' -f $startupStage, $authenticationError.Exception.GetType().FullName) -Level 'ERROR'
                try { Disconnect-MgGraph -Verbose:$false -Debug:$false -ErrorAction Stop | Out-Null } catch { Write-Verbose 'No Graph session was disconnected after the unsuccessful sign-in attempt.' }
                Write-Host 'Changing sign-in methods does not bypass Conditional Access or grant additional permissions.'
                Write-Host 'D. Retry DeviceCode'
                Write-Host 'B. Browser sign-in'
                Write-Host '0. Cancel sign-in'
                $authChoice = Read-ValidatedInput -Prompt 'Sign-in method' -Default '0' -Type Choice -Choices @('D', 'B', '0')
                switch ($authChoice) {
                    'D' { $selectedAuthMode = 'DeviceCode' }
                    'B' { $selectedAuthMode = 'Browser' }
                    '0' { throw $authenticationError }
                }
            }
        }
        $startupStage = 'Authenticated context validation'
        $context = Get-MgContext -ErrorAction Stop
        if ($context.TenantId -isnot [string] -or $context.TenantId -notmatch '^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$') { throw 'Authenticated Graph context TenantId must be a GUID string.' }
        if ($expectedTenantId -and $context.TenantId -ine $expectedTenantId) { throw 'Authenticated tenant does not match configured expectedTenantId. No tenant reads were issued.' }
        # The guarded request helper depends on GraphSession.Connected, which is only set after this identity probe succeeds.
        $startupStage = 'Signed-in identity read (GET /v1.0/me)'
        Write-AutopilotExpressLog -Message 'Sign-in returned a valid tenant context; checking signed-in identity.' -Level 'INFO'
        $me = Invoke-MgGraphRequest -Method 'GET' -Uri '/v1.0/me?$select=id,displayName,userPrincipalName,mail' -Verbose:$false -Debug:$false -ErrorAction Stop
        $graphAccount = if ($me.userPrincipalName) { [string]$me.userPrincipalName } else { [string]$context.Account }
        $Script:GraphSession = [ordered]@{
            Connected               = $true
            RequiresReconnect       = $false
            IsSimulated             = $false
            Account                 = $graphAccount
            DisplayName             = if ($me.displayName) { [string]$me.displayName } else { $graphAccount }
            UserId                  = if ($me.id) { [string]$me.id } else { '' }
            TenantId                = $context.TenantId
            TransportTimeoutSeconds = (Get-GraphTransportPolicy).TransportTimeoutSeconds
            Scopes                  = @($context.Scopes)
            CapabilityResults       = @()
        }
        $startupStage = 'Organisation discovery and tenant binding'
        $startupTracker = @{ Stage = $startupStage }
        # One batched request answers the organisation, permission and group reads.
        try { $capabilityResults = @(Invoke-LiveStartupRead -StageTracker $startupTracker) }
        finally { $startupStage = $startupTracker.Stage }
        $Script:GraphSession.CapabilityResults = $capabilityResults
        $failedCapabilities = @($capabilityResults | Where-Object { -not $_.Success })
        if ($failedCapabilities.Count -gt 0) {
            foreach ($failure in $failedCapabilities) {
                Write-AutopilotExpressLog -Message ('Microsoft Graph capability check failed for {0}: {1}' -f $failure.Name, $failure.Detail) -Level 'ERROR'
            }
            Close-GraphSession
            return $false
        }
        Write-AutopilotExpressLog -Message ('Authenticated to Microsoft Graph as {0}.' -f $Script:GraphSession.Account) -Level 'INFO'
        Write-AutopilotExpressLog -Message 'Microsoft Graph core-workflow read capability preflight completed successfully; remediation access is checked separately.' -Level 'INFO'
        try {
            Assert-DeviceRemediationAccess
            Write-AutopilotExpressLog -Message 'Remediation delegated scope checks passed; catalogue service access is verified when opened, not by the core-workflow preflight.' -Level 'INFO'
        }
        catch { Write-AutopilotExpressLog -Message ('Remediation features unavailable: {0}' -f (Get-GraphOperationFailureMessage -RequestError $_)) -Level 'WARN' }
        return $true
    }
    catch {
        $startupError = $_
        $errorType = $startupError.Exception.GetType().FullName
        $httpStatus = 'unavailable'
        $requestId = 'unavailable'
        if (Get-Command Get-GraphTransportFailure -ErrorAction SilentlyContinue) {
            $transportFailure = Get-GraphTransportFailure -RequestError $startupError
            if ($transportFailure.Status) { $httpStatus = [string]$transportFailure.Status }
            if ($transportFailure.RequestId) { $requestId = [string]$transportFailure.RequestId }
        }
        Write-AutopilotExpressLog -Message ('Live startup failed at stage: {0}. Exception={1}; HTTP={2}; request-id={3}.' -f $startupStage, $errorType, $httpStatus, $requestId) -Level 'ERROR'
        $sdkVersions = @(Get-Module Microsoft.Graph* | ForEach-Object { '{0}={1}' -f $_.Name, $_.Version }) -join '; '
        Write-AutopilotExpressLog -Message ('Host={0}; edition={1}; language={2}; loaded Graph modules: {3}' -f $PSVersionTable.PSVersion, $PSVersionTable.PSEdition, $ExecutionContext.SessionState.LanguageMode, $sdkVersions) -Level 'ERROR'
        $innerError = $startupError.Exception
        $uriFailure = $false
        for ($depth = 0; $depth -lt 5 -and $innerError; $depth++) {
            if ($innerError -is [System.UriFormatException] -or $innerError.Message -like '*Invalid URI*') { $uriFailure = $true }
            Write-Verbose ('Startup exception[{0}]: {1}' -f $depth, $innerError.GetType().FullName)
            $innerError = $innerError.InnerException
        }
        if ($uriFailure) {
            Write-Host ('URI construction failed in the client/request path. Reported HTTP status: {0}; this is not evidence of missing Intune licences or insufficient permissions.' -f $httpStatus)
            Write-Host 'Close this PowerShell process and retry the current script in a fresh non-elevated PowerShell 7 session. Do not broaden permissions or reinstall modules solely because of this error.'
            Write-Host 'If it repeats, provide the stage, host and loaded module versions above, plus the script revision. Use -Verbose for exception type-chain diagnostics; never include tokens or SDK response bodies.'
        }
        elseif ($httpStatus -eq '401') { Write-Host 'Graph reported HTTP 401. Check the signed-in tenant/account and reconnect in a fresh session; ask your administrator to review sign-in policy if it repeats.' }
        elseif ($httpStatus -eq '403') { Write-Host 'Graph reported HTTP 403. Ask the tenant administrator to check consent, delegated scopes and operator roles for the failing read. Successful browser sign-in does not grant API access.' }
        else { Write-Host 'Inspect the failing stage and HTTP/request ID above. Browser sign-in, identity lookup, organisation discovery and Intune read access are separate checks; do not assume all failures are authentication failures.' }
        if (-not $Script:GraphSession.Connected) {
            try { Disconnect-MgGraph -Verbose:$false -Debug:$false -ErrorAction Stop | Out-Null } catch { Write-Verbose 'Graph disconnect failed after unsuccessful authentication.' }
        }
        Close-GraphSession
        Write-AutopilotExpressLog -Message 'Live startup stopped; no workflow action was run. See README.md, Troubleshooting / Live Startup Failures.' -Level 'ERROR'
        return $false
    }
}

function Close-GraphSession {
    <#
    .SYNOPSIS
        Disconnect the owned Live Graph context and clear local session state.
    .OUTPUTS
        None. Safely reported disconnect failures do not prevent local cleanup.
    #>
    if (-not $Script:Runtime.IsDemoMode -and $Script:GraphSession.Connected) {
        try { Disconnect-MgGraph -Verbose:$false -Debug:$false -ErrorAction Stop | Out-Null } catch { Write-Verbose 'Graph disconnect failed; local session state will still be cleared. No SDK error body is logged.' }
    }
    $Script:GraphSession = Get-EmptyGraphSession
}

function New-OperationResult {
    <#
    .SYNOPSIS
        Build an honest outcome; Live request acceptance alone is Submitted.
    .DESCRIPTION
        Explicit Verified claims require successful action-specific observations.
        The persistence boundary repeats this check before storing completion.
        Guided technician observations and Demo simulation remain distinct states.
    .PARAMETER ActionName
        Manifest semantic action used to select the required evidence contract.
    .PARAMETER Data
        Target identities, expected/observed values and completed read attempts.
    .OUTPUTS
        Operation dictionary; inconsistent verification becomes non-completing Submitted.
    .PARAMETER Success
        Handler outcome flag; not a substitute for explicit completion classification.
    .PARAMETER Summary
        Concise technician-facing outcome.
    .PARAMETER Notes
        Safe actionable detail; raw SDK response text must not be supplied.
    .PARAMETER CompletionState
        Explicit evidence state; Submitted/Blocked remain incomplete despite request acceptance.
    #>
    param(
        [Parameter(Mandatory)][string]$ActionName,
        [Parameter(Mandatory)][bool]$Success,
        [string]$Summary,
        [string]$Notes,
        [hashtable]$Data,
        [ValidateSet('Verified', 'TechnicianConfirmed', 'Submitted', 'Blocked', 'Failed', 'AuditedException', 'Simulated', 'LegacyCompleted')][string]$CompletionState
    )
    if ([string]::IsNullOrWhiteSpace($CompletionState)) {
        $CompletionState = if (-not $Success) { 'Failed' } elseif ($Script:Runtime.IsDemoMode) { 'Simulated' } else { 'Submitted' }
    }
    if (-not $Script:Runtime.IsDemoMode -and $CompletionState -eq 'Verified') {
        $hasEvidence = $false
        if ($Success -and $Data) {
            switch ($ActionName) {
                'ResolveAutopilotDevice' { $hasEvidence = $Data.VerificationAttempts -gt 0 -and $Data.AutopilotDeviceId -is [string] -and -not [string]::IsNullOrWhiteSpace($Data.AutopilotDeviceId) -and $Data.Serial -is [string] -and -not [string]::IsNullOrWhiteSpace($Data.Serial) -and $Data.ObservedSerial -is [string] -and $Data.ObservedSerial -ieq $Data.Serial }
                'RemoveAssociatedManagedDevice' { $hasEvidence = $Data.VerificationAttempts -gt 0 -and $Data.ContainsKey('ObservedManagedDeviceId') -and $Data.ObservedManagedDeviceId -ceq '' }
                'ApplyGroupTag' { $hasEvidence = $Data.VerificationAttempts -gt 0 -and $Data.AutopilotDeviceId -is [string] -and -not [string]::IsNullOrWhiteSpace($Data.AutopilotDeviceId) -and $Data.GroupTag -is [string] -and -not [string]::IsNullOrWhiteSpace($Data.GroupTag) -and $Data.ObservedGroupTag -ceq $Data.GroupTag }
                'AddToPreProvisioningGroup' { $hasEvidence = $Data.VerificationAttempts -gt 0 -and $Data.ExpectedMember -is [bool] -and $Data.ExpectedMember -and $Data.ObservedMember -is [bool] -and $Data.ObservedMember -and -not [string]::IsNullOrWhiteSpace($Data.GroupId) -and -not [string]::IsNullOrWhiteSpace($Data.DirectoryObjectId) }
                'RemoveFromPreProvisioningGroup' { $hasEvidence = $Data.VerificationAttempts -gt 0 -and $Data.ExpectedMember -is [bool] -and -not $Data.ExpectedMember -and $Data.ObservedMember -is [bool] -and -not $Data.ObservedMember -and -not [string]::IsNullOrWhiteSpace($Data.GroupId) -and -not [string]::IsNullOrWhiteSpace($Data.DirectoryObjectId) }
                { $_ -in @('AssignTechnicianPrimaryUser', 'AssignFinalPrimaryUser') } { $hasEvidence = $Data.AutopilotAssigned -is [bool] -and $Data.AutopilotAssigned -and $Data.ManagedDeviceConfirmed -is [bool] -and $Data.ManagedDeviceConfirmed }
            }
        }
        if (-not $hasEvidence) {
            $CompletionState = 'Submitted'
            $Success = $false
            $Notes = ('{0} Explicit Graph verification evidence is missing or inconsistent; completion refused.' -f $Notes).Trim()
        }
    }
    return [ordered]@{
        ActionName      = $ActionName
        Success         = $Success
        CompletionState = $CompletionState
        Summary         = if ($Summary) { $Summary } else { '' }
        Notes           = if ($Notes) { $Notes } else { '' }
        Data            = if ($Data) { $Data } else { @{} }
        IsSimulated     = $Script:Runtime.IsDemoMode
    }
}

#endregion
#region Directory Selection and Tenant Workflow Actions
function Get-UserLocalPart {
    <#
    .SYNOPSIS
        Trim an account name and return the portion before the first at-sign.
    .PARAMETER UserPrincipalName
        Directory account text; absent values become empty text.
    .OUTPUTS
        Local-part string; no account resolution or validation.
    #>
    param([string]$UserPrincipalName)
    if ([string]::IsNullOrWhiteSpace($UserPrincipalName)) { return '' }
    $normalisedUserPrincipalName = $UserPrincipalName.Trim().ToLower()
    if ($normalisedUserPrincipalName.Contains('@')) { return $normalisedUserPrincipalName.Split('@')[0] }
    return $normalisedUserPrincipalName
}

function Test-DirectoryUserMatchesConfiguredPrefixes {
    <#
    .SYNOPSIS
        Match the account local part against permitted prefixes without case sensitivity.
    .PARAMETER UserPrincipalName
        Candidate account; domain text does not establish a prefix match.
    .OUTPUTS
        Boolean prefix eligibility, not tenant membership or enabled-account evidence.
    #>
    param([string]$UserPrincipalName)
    $localPart = Get-UserLocalPart -UserPrincipalName $UserPrincipalName
    if ([string]::IsNullOrWhiteSpace($localPart)) { return $false }
    foreach ($configuredPrefix in (Get-ConfiguredTechnicianPrefixes)) {
        if ($localPart.StartsWith($configuredPrefix.ToLower())) { return $true }
    }
    return $false
}

function Get-DirectoryUserEligibilityMessage {
    <#
    .SYNOPSIS
        Explain missing identity, disabled account or prefix rejection.
    .PARAMETER User
        Normalised candidate containing UserPrincipalName and AccountEnabled.
    .OUTPUTS
        Actionable rejection string, or empty string for an eligible candidate.
    #>
    param($User)
    if ($null -eq $User) { return 'No directory user was supplied.' }
    if ([string]::IsNullOrWhiteSpace([string]$User.UserPrincipalName)) { return 'The selected user does not have a user principal name.' }

    if ($null -ne $User.AccountEnabled -and -not [bool]$User.AccountEnabled) {
        return ('{0} is not an active account.' -f $User.UserPrincipalName)
    }

    $accountName = if (-not [string]::IsNullOrWhiteSpace([string]$User.OnPremisesSamAccountName)) { [string]$User.OnPremisesSamAccountName } else { [string]$User.UserPrincipalName }
    if (-not (Test-DirectoryUserMatchesConfiguredPrefixes -UserPrincipalName $accountName)) {
        return ('{0} does not begin with one of the permitted prefixes: {1}.' -f $accountName, ((Get-ConfiguredTechnicianPrefixes) -join ', '))
    }

    return ''
}

function Test-EligibleDirectoryUser {
    <#
    .SYNOPSIS
        Apply the shared account-enabled and permitted-prefix selection rules.
    .PARAMETER User
        Normalised directory account candidate.
    .OUTPUTS
        Boolean result; cached candidates still require fresh Live revalidation.
    #>
    param($User)
    return [string]::IsNullOrWhiteSpace((Get-DirectoryUserEligibilityMessage -User $User))
}

function Get-EligibleDirectoryUsers {
    <#
    .SYNOPSIS
        Filter candidates and sort by display name then principal name.
    .PARAMETER Users
        Candidate collection; null and ineligible entries are excluded.
    .OUTPUTS
        Eligible account array; no fresh tenant reads.
    #>
    param([AllowEmptyCollection()][System.Collections.IEnumerable]$Users)
    return @($Users | Where-Object { $null -ne $_ -and (Test-EligibleDirectoryUser -User $_) } | Sort-Object { $_.DisplayName }, { $_.UserPrincipalName })
}

function Resolve-LiveDirectoryUserRecord {
    <#
    .SYNOPSIS
        Re-read an account by ID or escaped principal name in the current tenant.
    .DESCRIPTION
        Requires the selected ID or a single complete exact UPN match, a nonblank
        returned ID and UPN, and Boolean enabled status. Rejects malformed fresh
        responses rather than applying legacy cached-account defaults.
    .PARAMETER User
        Cached or selected account; a known immutable ID takes precedence.
    .OUTPUTS
        Normalised account, or null on missing identity/read failure. SDK failures use
        bounded diagnostics rather than retaining response messages in logs.
    #>
    param($User)
    if ($null -eq $User) { return $null }

    try {
        if ($User.Id) {
            $escapedId = [uri]::EscapeDataString([string]$User.Id)
            $resolvedUser = Invoke-GraphApiRequest -Method 'GET' -Uri ('https://graph.microsoft.com/v1.0/users/{0}?$select=id,displayName,userPrincipalName,accountEnabled,onPremisesSamAccountName' -f $escapedId)
            if ($resolvedUser.id -isnot [string] -or $resolvedUser.id -ine [string]$User.Id) {
                throw 'Directory revalidation returned a missing or unexpected account ID.'
            }
        }
        elseif ($User.UserPrincipalName) {
            $escapedUserPrincipalName = [uri]::EscapeDataString(([string]$User.UserPrincipalName).Replace("'", "''"))
            $response = Invoke-GraphApiRequest -Method 'GET' -Uri ('https://graph.microsoft.com/v1.0/users?$filter=userPrincipalName eq ''{0}''&$select=id,displayName,userPrincipalName,accountEnabled,onPremisesSamAccountName&$top=1' -f $escapedUserPrincipalName)
            if ($response.value -isnot [array] -or $response.'@odata.nextLink' -or $response.value.Count -ne 1) {
                throw 'Directory revalidation requires a single complete account response.'
            }
            $resolvedUser = $response.value[0]
            if ($resolvedUser.userPrincipalName -isnot [string] -or $resolvedUser.userPrincipalName -ine [string]$User.UserPrincipalName) {
                throw 'Directory revalidation returned an unexpected principal name.'
            }
        }
        else { return $null }
        if ($resolvedUser.id -isnot [string] -or [string]::IsNullOrWhiteSpace($resolvedUser.id) -or
            $resolvedUser.userPrincipalName -isnot [string] -or [string]::IsNullOrWhiteSpace($resolvedUser.userPrincipalName) -or
            $resolvedUser.accountEnabled -isnot [bool]) {
            throw 'Directory revalidation returned malformed identity or enabled-account metadata.'
        }
        return ConvertTo-DirectoryUserRecord -User $resolvedUser
    }
    catch {
        $userIdentity = if ($User.UserPrincipalName) { [string]$User.UserPrincipalName } elseif ($User.Id) { [string]$User.Id } else { 'unknown user' }
        Write-AutopilotExpressLog -Message ('Failed to revalidate directory user {0}: {1}' -f $userIdentity, (Get-GraphOperationFailureMessage -RequestError $_)) -Level 'WARN'
    }

    return $null
}

function Resolve-EligibleDirectoryUser {
    <#
    .SYNOPSIS
        Revalidate the selected account and enforce shared eligibility rules.
    .PARAMETER User
        Candidate; Live performs a fresh read and Demo uses synthetic records.
    .OUTPUTS
        Eligible current account, or null with feedback; no assignment occurs.
    #>
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
    <#
    .SYNOPSIS
        Load recent accounts and exclude entries failing local selection rules.
    .OUTPUTS
        Eligible recent-account array; stored identities are convenience, not Live authority.
    #>
    $recentUsersPath = Get-RecentUsersFilePath
    $recentUsers = @()

    if (Test-Path $recentUsersPath) {
        try {
            $storedUsers = Get-Content -Raw -Path $recentUsersPath | ConvertFrom-Json
            foreach ($storedUser in @($storedUsers)) {
                if ($null -eq $storedUser) { continue }
                $recentUsers += [ordered]@{
                    Id                       = if ($storedUser.id) { [string]$storedUser.id } elseif ($storedUser.Id) { [string]$storedUser.Id } else { '' }
                    DisplayName              = if ($storedUser.displayName) { [string]$storedUser.displayName } elseif ($storedUser.DisplayName) { [string]$storedUser.DisplayName } else { '' }
                    UserPrincipalName        = if ($storedUser.userPrincipalName) { [string]$storedUser.userPrincipalName } elseif ($storedUser.UserPrincipalName) { [string]$storedUser.UserPrincipalName } else { '' }
                    OnPremisesSamAccountName = [string]$storedUser.onPremisesSamAccountName
                    AccountEnabled           = if ($null -ne $storedUser.accountEnabled) { [bool]$storedUser.accountEnabled } elseif ($null -ne $storedUser.AccountEnabled) { [bool]$storedUser.AccountEnabled } else { $true }
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
    <#
    .SYNOPSIS
        Persist eligible recent accounts through guarded UTF-8 storage.
    .PARAMETER Users
        Recent-account collection for the current user and mode.
    .OUTPUTS
        None. Storage failures propagate; tokens and credentials are not stored.
    #>
    param([AllowEmptyCollection()][System.Collections.IEnumerable]$Users)
    $recentUsersPath = Get-RecentUsersFilePath
    $serialisableUsers = @($Users | ForEach-Object { ConvertTo-DirectoryUserRecord -User $_ } | Where-Object { $null -ne $_ })
    $json = if ($serialisableUsers.Count -gt 0) { ConvertTo-Json -InputObject $serialisableUsers -Depth 5 } else { '[]' }
    Write-Utf8File -Path $recentUsersPath -Content $json
}

function Add-RecentUser {
    <#
    .SYNOPSIS
        Deduplicate a selected account and persist the bounded recent-user list.
    .PARAMETER User
        Eligible account just selected by the technician.
    .OUTPUTS
        None. Updates convenience storage, not assignment evidence.
    #>
    param([Parameter(Mandatory)]$User)
    $allUsers = @()
    $allUsers += [ordered]@{
        Id                       = [string]$User.Id
        DisplayName              = [string]$User.DisplayName
        UserPrincipalName        = [string]$User.UserPrincipalName
        OnPremisesSamAccountName = [string]$User.OnPremisesSamAccountName
        AccountEnabled           = if ($null -ne $User.AccountEnabled) { [bool]$User.AccountEnabled } else { $true }
    }

    foreach ($existingUser in (Get-RecentUsers)) {
        $sameId = $existingUser.Id -and $User.Id -and $existingUser.Id -eq $User.Id
        $sameUpn = $existingUser.UserPrincipalName -and $User.UserPrincipalName -and $existingUser.UserPrincipalName.ToLower() -eq $User.UserPrincipalName.ToLower()
        if ($sameId -or $sameUpn) { continue }
        $allUsers += $existingUser
    }

    Save-RecentUsers -Users (@($allUsers | Select-Object -First (Get-ConfiguredRecentUserLimit)))
}

function ConvertTo-DirectoryUserRecord {
    <#
    .SYNOPSIS
        Reduce an SDK or JSON account to the fields required by account selection.
    .PARAMETER User
        Dictionary or object containing identity and enabled status.
    .OUTPUTS
        Identity, Windows username and enabled status, or null when unusable.
    #>
    param($User)
    if ($null -eq $User) { return $null }
    $id = if ($null -ne $User.id) { [string]$User.id } elseif ($null -ne $User.Id) { [string]$User.Id } else { '' }
    $displayName = if ($null -ne $User.displayName) { [string]$User.displayName } elseif ($null -ne $User.DisplayName) { [string]$User.DisplayName } else { '' }
    $upn = if ($null -ne $User.userPrincipalName) { [string]$User.userPrincipalName } elseif ($null -ne $User.UserPrincipalName) { [string]$User.UserPrincipalName } else { '' }
    $accountEnabled = if ($null -ne $User.accountEnabled) { [bool]$User.accountEnabled } elseif ($null -ne $User.AccountEnabled) { [bool]$User.AccountEnabled } else { $true }
    if ([string]::IsNullOrWhiteSpace($upn)) { return $null }
    return [ordered]@{ Id = $id; DisplayName = $displayName; UserPrincipalName = $upn; OnPremisesSamAccountName = [string]$User.onPremisesSamAccountName; AccountEnabled = $accountEnabled }
}

function Test-NameWordApproximation {
    <#
    .SYNOPSIS
        Checks one insertion, deletion or substitution in a complete name word.
    .DESCRIPTION
        Uses bounded string comparisons compatible with both supported hosts.
        Short fragments remain literal; transpositions and account identities
        are not corrected. This helper never selects or assigns an owner.
    .PARAMETER Fragment
        Lower-case query fragment of at least four characters.
    .PARAMETER Word
        Lower-case complete display-name word.
    .OUTPUTS
        Boolean indicating a maximum of one character edit.
    #>
    param([string]$Fragment, [string]$Word)
    if ($Fragment.Length -lt 4 -or [Math]::Abs($Fragment.Length - $Word.Length) -gt 1) { return $false }
    $fragmentIndex = 0
    $wordIndex = 0
    $edits = 0
    while ($fragmentIndex -lt $Fragment.Length -and $wordIndex -lt $Word.Length) {
        if ($Fragment[$fragmentIndex] -eq $Word[$wordIndex]) {
            $fragmentIndex++; $wordIndex++; continue
        }
        $edits++
        if ($edits -gt 1) { return $false }
        if ($Fragment.Length -ge $Word.Length) { $fragmentIndex++ }
        if ($Word.Length -ge $Fragment.Length) { $wordIndex++ }
    }
    if ($fragmentIndex -lt $Fragment.Length -or $wordIndex -lt $Word.Length) { $edits++ }
    return $edits -le 1
}

function Test-DirectoryUserSearchMatch {
    <#
    .SYNOPSIS
        Matches an exact account identity or every supplied name fragment.
    .DESCRIPTION
        Name fragments may appear in any order in the display name or UPN.
        This check narrows candidates only; account eligibility and explicit
        technician selection remain separate requirements.
    .PARAMETER User
        Dictionary-backed or object-backed directory user candidate.
    .PARAMETER SearchMode
        ExactUpn matches the full UPN or complete username, never a prefix.
    .PARAMETER Query
        Technician-supplied account identity or whitespace-separated fragments.
    .OUTPUTS
        Boolean indicating whether the candidate matches the query.
    .PARAMETER Approximate
        Permit the explicit approximate-name matching pass.
    #>
    param(
        $User,
        [Parameter(Mandatory)][ValidateSet('ExactUpn', 'DisplayName')][string]$SearchMode,
        [AllowEmptyString()][string]$Query,
        [switch]$Approximate
    )
    if ($null -eq $User -or [string]::IsNullOrWhiteSpace($Query)) { return $false }
    $normalisedQuery = $Query.Trim().ToLowerInvariant()
    $upn = ([string]$User.UserPrincipalName).ToLowerInvariant()
    if ($SearchMode -eq 'ExactUpn') {
        return $upn -eq $normalisedQuery -or (Get-UserLocalPart -UserPrincipalName $upn) -eq $normalisedQuery -or
        ([string]$User.OnPremisesSamAccountName).ToLowerInvariant() -eq $normalisedQuery
    }
    $searchText = ('{0} {1}' -f $User.DisplayName, $upn).ToLowerInvariant()
    foreach ($fragment in ($normalisedQuery -split '\s+')) {
        if ($searchText.Contains($fragment)) { continue }
        if (-not $Approximate) { return $false }
        $wordMatches = @(([string]$User.DisplayName).ToLowerInvariant() -split '\s+' | Where-Object {
                Test-NameWordApproximation -Fragment $fragment -Word $_
            })
        if ($wordMatches.Count -eq 0) { return $false }
    }
    return $true
}

function Get-DirectoryUserSearchRank {
    <#
    .SYNOPSIS
        Ranks a matching candidate by literal name or identity relevance.
    .DESCRIPTION
        Lower ranks favour exact identities/names, leading phrases, word prefixes,
        contained phrases, then name fragments over UPN-only fragment matches.
        Ranking does not infer account roles or make an ownership decision.
    .PARAMETER User
        Eligible directory candidate already matched against the query.
    .PARAMETER Query
        Technician-supplied literal identity or name fragments.
    .OUTPUTS
        Integer relevance tier from zero (strongest) to five (weakest).
    #>
    param(
        [Parameter(Mandatory)]$User,
        [Parameter(Mandatory)][ValidateNotNullOrEmpty()][string]$Query
    )
    $normalisedQuery = ($Query.Trim().ToLowerInvariant() -split '\s+') -join ' '
    $name = (([string]$User.DisplayName).Trim().ToLowerInvariant() -split '\s+') -join ' '
    $upn = ([string]$User.UserPrincipalName).ToLowerInvariant()
    if (-not (Test-DirectoryUserSearchMatch -User $User -SearchMode DisplayName -Query $Query)) { return 6 }
    if ($name -eq $normalisedQuery -or $upn -eq $normalisedQuery -or
        (Get-UserLocalPart -UserPrincipalName $upn) -eq $normalisedQuery) { return 0 }
    if ($name.StartsWith($normalisedQuery)) { return 1 }
    $allWordPrefixes = $true
    $allNameFragments = $true
    foreach ($fragment in ($normalisedQuery -split '\s+')) {
        $wordPrefix = $false
        foreach ($word in ($name -split '\s+')) {
            if ($word.StartsWith($fragment)) { $wordPrefix = $true; break }
        }
        if (-not $wordPrefix) { $allWordPrefixes = $false }
        if (-not $name.Contains($fragment)) { $allNameFragments = $false }
    }
    if ($allWordPrefixes) { return 2 }
    if ($name.Contains($normalisedQuery)) { return 3 }
    if ($allNameFragments) { return 4 }
    return 5
}

function Get-DirectoryUserSearchResult {
    <#
    .SYNOPSIS
        Returns eligible literal matches in deterministic relevance order.
    .DESCRIPTION
        Shares matching and ranking between Demo and Live searches. Equal ranks
        sort by display name and UPN. Does not mutate user or persistence records.
    .PARAMETER Users
        Candidate collection; null and empty collections return no results.
    .PARAMETER SearchMode
        Exact identity or display-name fragment search.
    .PARAMETER Query
        Literal technician query. Empty queries return no results.
    .OUTPUTS
        Directory candidates ordered by relevance, display name, then UPN.
    .PARAMETER Approximate
        Request approximate matching only after the exact search path allows it.
    #>
    param(
        [AllowNull()][AllowEmptyCollection()][object[]]$Users,
        [Parameter(Mandatory)][ValidateSet('ExactUpn', 'DisplayName')][string]$SearchMode,
        [AllowEmptyString()][string]$Query,
        [switch]$Approximate
    )
    if ([string]::IsNullOrWhiteSpace($Query)) { return }
    $Users | Where-Object {
        (Test-EligibleDirectoryUser -User $_) -and
        (Test-DirectoryUserSearchMatch -User $_ -SearchMode $SearchMode -Query $Query -Approximate:$Approximate)
    } | Sort-Object { Get-DirectoryUserSearchRank -User $_ -Query $Query }, { $_.DisplayName }, { $_.UserPrincipalName }
}

function Search-DemoDirectoryUsers {
    <#
    .SYNOPSIS
        Search synthetic accounts through the shared search modes without Graph access.
    .PARAMETER SearchMode
        Supported account-name or display-name search mode.
    .PARAMETER Query
        Literal search text; never executed as an expression.
    .PARAMETER Approximate
        Enable approximate matching rather than exact-only selection.
    .OUTPUTS
        Bounded synthetic account array; never real-directory evidence.
    #>
    param(
        [Parameter(Mandatory)][ValidateSet('ExactUpn', 'DisplayName')][string]$SearchMode,
        [Parameter(Mandatory)][string]$Query,
        [switch]$Approximate
    )
    $allUsers = @()
    foreach ($demoUser in (Get-RecentUsers)) { $allUsers += $demoUser }
    foreach ($demoUser in @($Script:RuntimeConfig.demo.defaultUsers)) {
        $userRecord = ConvertTo-DirectoryUserRecord -User $demoUser
        if ($null -eq $userRecord) { continue }
        $isDuplicate = @($allUsers | Where-Object { $_.UserPrincipalName.ToLower() -eq $userRecord.UserPrincipalName.ToLower() }).Count -gt 0
        if (-not $isDuplicate) { $allUsers += $userRecord }
    }

    $matchedUsers = @(Get-DirectoryUserSearchResult -Users $allUsers -SearchMode $SearchMode -Query $Query -Approximate:$Approximate)
    if ($matchedUsers.Count -eq 0 -and $SearchMode -eq 'DisplayName' -and -not $Approximate -and
        @($Query.Trim() -split '\s+' | Where-Object { $_.Length -ge 4 }).Count -gt 0) {
        Write-Host 'No literal matches. Approximate name suggestions follow; verify the full name and account before selecting.'
        return , (Search-DemoDirectoryUsers -SearchMode $SearchMode -Query $Query -Approximate)
    }
    return , $matchedUsers
}

function Search-LiveDirectoryUsers {
    <#
    .SYNOPSIS
        Retrieves bounded Graph candidate pages for technician-directed search.
    .DESCRIPTION
        Follows complete users continuation URLs, rejects repeated or unexpected
        links, and warns when the page bound leaves candidate discovery incomplete.
        Name searches retrieve prefixes for every distinct supplied fragment,
        then require all fragments to match locally. An exhaustive empty literal
        search may run one bounded approximate pass; truncated searches may not.
        Eligibility and query matching apply before returning unique identities.
    .PARAMETER SearchMode
        Exact account identity or order-independent name-fragment matching.
    .PARAMETER Query
        Technician-supplied search text; no ownership-role inference is performed.
    .OUTPUTS
        Array of eligible user dictionaries, bounded by directorySearchLimit.
        Graph failures propagate rather than returning misleading partial success.
    .PARAMETER Approximate
        Use bounded approximate suggestions; still require explicit account selection/revalidation.
    #>
    param(
        [Parameter(Mandatory)][ValidateSet('ExactUpn', 'DisplayName')][string]$SearchMode,
        [Parameter(Mandatory)][string]$Query,
        [switch]$Approximate
    )

    $searchLimit = Get-ConfiguredSearchLimit
    $escapedQuery = $Query.Trim().Replace("'", "''")
    $pageSize = if ($null -ne $Script:RuntimeConfig.autopilot.directorySearchPageSize) { $Script:RuntimeConfig.autopilot.directorySearchPageSize } else { 100 }
    if ([string]$pageSize -notmatch '^[1-9][0-9]*$' -or [double]$pageSize -gt 999) { throw 'directorySearchPageSize must be an integer from 1 to 999.' }
    $headers = @{}

    if ([string]::IsNullOrWhiteSpace($escapedQuery)) { return @() }

    switch ($SearchMode) {
        'ExactUpn' {
            $filter = if ($Query.Contains('@')) { "userPrincipalName eq '{0}'" -f $escapedQuery } else { "startswith(userPrincipalName,'{0}@') or onPremisesSamAccountName eq '{0}'" -f $escapedQuery }
            $uri = 'https://graph.microsoft.com/v1.0/users?$filter={0}&$select=id,displayName,userPrincipalName,accountEnabled,onPremisesSamAccountName&$top={1}&$count=true' -f [uri]::EscapeDataString($filter), $pageSize
            $headers.ConsistencyLevel = 'eventual'
        }
        'DisplayName' {
            $fragmentFilters = @($Query.Trim() -split '\s+' | Select-Object -Unique | ForEach-Object {
                    $prefix = $_
                    if ($Approximate -and $prefix.Length -ge 4) { $prefix = $prefix.Substring(0, 2) }
                    "startswith(displayName,'{0}') or startswith(givenName,'{0}') or startswith(surname,'{0}') or startswith(userPrincipalName,'{0}')" -f $prefix.Replace("'", "''")
                })
            $uri = ('https://graph.microsoft.com/v1.0/users?$filter={0}&$select=id,displayName,userPrincipalName,accountEnabled,onPremisesSamAccountName&$top={1}' -f [uri]::EscapeDataString(($fragmentFilters -join ' or ')), $pageSize)
        }
    }

    $pageLimit = Get-ConfiguredDirectorySearchPageLimit
    $visitedLinks = @()
    $candidates = @()
    $seenUpns = @()
    while ($uri) {
        if ($uri -cnotmatch '^https://graph\.microsoft\.com/v1\.0/users\?' -or $uri -match '[\r\n#]') {
            throw 'Directory search returned an unexpected continuation URL.'
        }
        if ($uri -in $visitedLinks) { throw 'Directory search returned a repeated continuation URL.' }
        $visitedLinks += $uri
        $response = Invoke-GraphApiRequest -Method 'GET' -Uri $uri -Headers $headers
        if ($null -eq $response -or $response.value -isnot [array]) {
            throw 'Directory search returned an invalid users page.'
        }
        foreach ($rawUser in @($response.value)) {
            if ($rawUser.accountEnabled -isnot [bool] -or -not $rawUser.accountEnabled) { continue }
            $user = ConvertTo-DirectoryUserRecord -User $rawUser
            if ($null -eq $user -or -not (Test-EligibleDirectoryUser -User $user)) { continue }
            if (-not (Test-DirectoryUserSearchMatch -User $user -SearchMode $SearchMode -Query $Query -Approximate:$Approximate)) { continue }
            if ($user.UserPrincipalName -in $seenUpns) { continue }
            $seenUpns += $user.UserPrincipalName
            $candidates += $user
        }
        $uri = [string]$response.'@odata.nextLink'
        if ($uri -and $visitedLinks.Count -ge $pageLimit) {
            Write-Warning ('Directory search stopped after {0} pages; results may be incomplete. Refine the search or use the full UPN.' -f $pageLimit)
            break
        }
    }
    $matchedUsers = @(Get-DirectoryUserSearchResult -Users $candidates -SearchMode $SearchMode -Query $Query -Approximate:$Approximate)
    if ($matchedUsers.Count -eq 0 -and $SearchMode -eq 'DisplayName' -and -not $Approximate -and
        -not $uri -and @($Query.Trim() -split '\s+' | Where-Object { $_.Length -ge 4 }).Count -gt 0) {
        Write-Host 'No literal matches. Approximate name suggestions follow; verify the full name and account before selecting.'
        return , (Search-LiveDirectoryUsers -SearchMode $SearchMode -Query $Query -Approximate)
    }
    return , @($matchedUsers | Select-Object -First $searchLimit)
}

function Select-UserFromResults {
    <#
    .SYNOPSIS
        Present eligible results and validate an explicit account selection.
    .PARAMETER Users
        Candidate account collection to display.
    .PARAMETER Heading
        Accessible search-result heading.
    .PARAMETER PreserveOrder
        Retain recent-account ranking instead of alphabetical ordering.
    .OUTPUTS
        Selected account or null on cancellation/empty results; no assignment.
    #>
    param(
        [AllowNull()]
        [AllowEmptyCollection()]
        [object[]]$Users,
        [Parameter(Mandatory)][string]$Heading,
        [switch]$PreserveOrder
    )
    $sortedUsers = @($Users | Where-Object { $null -ne $_ })
    if (-not $PreserveOrder) {
        $sortedUsers = @($sortedUsers | Sort-Object { $_.DisplayName }, { $_.UserPrincipalName })
    }
    if ($sortedUsers.Count -eq 0) {
        Write-Host 'No eligible accounts were returned by this selection. A bounded or incomplete search does not establish account absence; refine the query or use the exact Windows username/full UPN.'
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
    <#
    .SYNOPSIS
        Select and revalidate an account through recent users or directory searches.
    .PARAMETER Heading
        Workflow-specific selection context shown to the technician.
    .OUTPUTS
        Current eligible account or null on cancellation; retains the recent selection only.
    #>
    param([string]$Heading = 'Final primary user search (active C/E accounts only)')
    while ($true) {
        Write-Host ''
        Write-Host ('{0}:' -f $Heading)
        Write-Host '1. Recent users'
        Write-Host '2. Exact username search'
        Write-Host '3. Display name search'
        Write-Host '0. Cancel'

        $selectionMode = Read-ValidatedInput -Prompt 'Choose a search mode' -Default '0' -Type 'Choice' -Choices @('1', '2', '3', '0')
        switch ($selectionMode) {
            '0' { return $null }
            '1' {
                $selectedRecentUser = Resolve-EligibleDirectoryUser -User (Select-UserFromResults -Users (Get-RecentUsers) -Heading 'Recent active C/E users' -PreserveOrder)
                if ($selectedRecentUser) { return $selectedRecentUser }
            }
            '2' {
                $usernameQuery = Read-ValidatedInput -Prompt 'Enter username or full UPN'
                $results = if ($Script:Runtime.IsDemoMode) { Search-DemoDirectoryUsers -SearchMode 'ExactUpn' -Query $usernameQuery } else { Search-LiveDirectoryUsers -SearchMode 'ExactUpn' -Query $usernameQuery }
                $selectedUser = Resolve-EligibleDirectoryUser -User (Select-UserFromResults -Users $results -Heading 'Exact username results' -PreserveOrder)
                if ($selectedUser) { return $selectedUser }
            }
            '3' {
                $nameQuery = Read-ValidatedInput -Prompt 'Enter part of the display name'
                $results = if ($Script:Runtime.IsDemoMode) { Search-DemoDirectoryUsers -SearchMode 'DisplayName' -Query $nameQuery } else { Search-LiveDirectoryUsers -SearchMode 'DisplayName' -Query $nameQuery }
                $selectedUser = Resolve-EligibleDirectoryUser -User (Select-UserFromResults -Users $results -Heading 'Display name results' -PreserveOrder)
                if ($selectedUser) { return $selectedUser }
            }
        }
    }
}

function Resolve-LiveAutopilotDeviceBySerial {
    <#
    .SYNOPSIS
        Resolve one complete Autopilot serial match without choosing duplicates.
    .DESCRIPTION
        Uses the serial contains filter demonstrated by WindowsAutoPilotIntune,
        then enforces exact serial equality locally. Never falls back to an
        unfiltered inventory query when the service rejects a filter.
    .PARAMETER Serial
        Canonical serial; a valid empty collection means absent, not an error.
    .OUTPUTS
        Unique exact serial match or null after complete bounded filtered discovery.
        Malformed, incomplete or ambiguous results throw.
    #>
    param([Parameter(Mandatory)][ValidateNotNullOrEmpty()][string]$Serial)
    if ([string]::IsNullOrWhiteSpace($Serial)) { throw 'Autopilot lookup requires a nonblank serial; unfiltered discovery is not permitted.' }
    $filter = "contains(serialNumber,'{0}')" -f $Serial.Replace("'", "''")
    $uri = 'https://graph.microsoft.com/v1.0/deviceManagement/windowsAutopilotDeviceIdentities?$filter={0}' -f [uri]::EscapeDataString($filter)
    $collection = Get-GraphDiscoveryCollection -Uri $uri -RequiredTextProperty serialNumber
    $identities = @($collection | Where-Object { $_.serialNumber -ieq $Serial })
    if ($identities.Count -gt 1) { throw 'Multiple Autopilot identities matched the serial; resolve duplicate records before continuing.' }
    if ($identities.Count -eq 0) { return $null }
    return $identities[0]
}

function Resolve-LiveManagedDeviceBySerial {
    <#
    .SYNOPSIS
        Resolves a unique managed device or confirms an empty serial search.
    .DESCRIPTION
        Missing bodies, incomplete pages, duplicates and inconsistent identities
        fail closed rather than becoming evidence that a device is absent.
    .PARAMETER Serial
        Canonical serial number used for the exact Graph filter.
    .OUTPUTS
        One managed-device record, or null for a valid empty response.
    #>
    param([Parameter(Mandatory)][ValidateNotNullOrEmpty()][string]$Serial)
    $response = Invoke-GraphApiRequest -Method 'GET' -Uri (Get-ManagedDeviceSerialLookupUri -Serial $Serial)
    if ($null -eq $response -or $response.value -isnot [array] -or $response.'@odata.nextLink') {
        throw 'Managed-device serial lookup returned an incomplete or malformed response.'
    }
    $managedDevices = @($response.value)
    if ($managedDevices.Count -gt 1) { throw 'Multiple managed devices matched the serial; resolve the duplicate records before continuing.' }
    if ($managedDevices.Count -eq 0) { return $null }
    if ($managedDevices[0].id -isnot [string] -or [string]::IsNullOrWhiteSpace($managedDevices[0].id) -or $managedDevices[0].serialNumber -isnot [string] -or $managedDevices[0].serialNumber -ne $Serial) {
        throw 'Managed-device serial lookup returned a missing or unexpected identity.'
    }
    return $managedDevices[0]
}

function ConvertTo-EthernetMacAddress {
    <#
    .SYNOPSIS
        Normalise an optional Ethernet address without substituting another adapter.
    .PARAMETER Value
        Intune adapter inventory value; null or blank means not yet available.
    .PARAMETER AdapterName
        Adapter named in error messages. Defaults to Ethernet; Wi-Fi reuses the same rules
        but is always stored separately and never substituted for Ethernet.
    .OUTPUTS
        Uppercase colon-separated unicast address, or an empty string. Invalid values throw.
    #>
    param([AllowNull()][object]$Value, [ValidateSet('Ethernet', 'Wi-Fi')][string]$AdapterName = 'Ethernet')
    if ($null -eq $Value) { return '' }
    if ($Value -isnot [string]) { throw ('{0} inventory must be a string.' -f $AdapterName) }
    $text = $Value.Trim()
    if (-not $text) { return '' }
    if ($text -notmatch '^(?:[0-9a-fA-F]{12}|(?:[0-9a-fA-F]{2}:){5}[0-9a-fA-F]{2}|(?:[0-9a-fA-F]{2}-){5}[0-9a-fA-F]{2})$') { throw ('{0} inventory has an invalid MAC address format.' -f $AdapterName) }
    $compact = $text.Replace(':', '').Replace('-', '').ToUpperInvariant()
    if ($compact -eq '000000000000' -or ([Convert]::ToByte($compact.Substring(0, 2), 16) -band 1)) { throw ('{0} inventory is not a usable unicast MAC address.' -f $AdapterName) }
    return ([regex]::Matches($compact, '..').Value -join ':')
}

function ConvertTo-WindowsReleaseName {
    <#
    .SYNOPSIS
        Turn an Intune Windows version (for example 10.0.26200.6584) into a release name.
    .DESCRIPTION
        Only builds Microsoft has published as a named release are mapped. Anything else
        returns an empty string, so an unknown build is never mislabelled. Add new
        releases to the table below as Microsoft ships them.
    .PARAMETER OsVersion
        Intune osVersion text; null, blank or malformed values return an empty string.
    .OUTPUTS
        Release text such as 'Windows 11 25H2', or an empty string.
    .LINK
        https://learn.microsoft.com/windows/release-health/windows11-release-information
    #>
    param([AllowNull()][object]$OsVersion)
    if ($OsVersion -isnot [string] -or $OsVersion -notmatch '^10\.0\.(\d{5})(?:\.\d+)?$') { return '' }
    $releases = @{ '19044' = 'Windows 10 21H2'; '19045' = 'Windows 10 22H2'; '22621' = 'Windows 11 22H2'; '22631' = 'Windows 11 23H2'; '26100' = 'Windows 11 24H2'; '26200' = 'Windows 11 25H2' }
    $release = $releases[$Matches[1]]
    if ($release) { return $release }
    return ''
}

function Get-LiveDeviceInventory {
    <#
    .SYNOPSIS
        Read authoritative Intune hostname, adapter, user and Windows details for one bound device.
    .DESCRIPTION
        Validates the tenant before discovery. The non-default Ethernet property
        requires an individual v1.0 GET with an explicit select, so every detail is
        collected in that one request. Never changes the caller, signs in, requests a
        device sync or substitutes the Wi-Fi address for Ethernet. A malformed Wi-Fi
        value is returned empty so it cannot block the Ethernet capture.
    .PARAMETER Device
        Current serial and tenant-bound device record, with an optional managed-device ID.
    .OUTPUTS
        Detached inventory dictionary, or null when no managed device exists yet.
    .LINK
        https://learn.microsoft.com/graph/api/resources/intune-devices-manageddevice?view=graph-rest-1.0
    #>
    param([Parameter(Mandatory)][ValidateNotNullOrEmpty()][System.Collections.IDictionary]$Device)
    $tenantId = Get-LiveTenantBinding -Device $Device
    $managedDeviceId = [string]$Device.ManagedDeviceId
    $discovered = $null
    if ([string]::IsNullOrWhiteSpace($managedDeviceId)) {
        $discovered = Resolve-LiveManagedDeviceBySerial -Serial $Device.Serial
        if ($null -eq $discovered) { return $null }
        $managedDeviceId = [string]$discovered.id
    }
    $response = Invoke-GraphApiRequest -Method GET -Uri (Get-ManagedDeviceInventoryUri -ManagedDeviceId $managedDeviceId)
    if ($null -eq $response) { throw 'Intune inventory identity check failed: missing response.' }
    if ($response.id -isnot [string] -or $response.id -ne $managedDeviceId) { throw 'Intune inventory identity check failed: managed-device ID mismatch.' }
    if ($response.serialNumber -isnot [string] -or $response.serialNumber -ne $Device.Serial) { throw 'Intune inventory identity check failed: serial mismatch.' }
    if ($Device.AzureAdDeviceId -and $response.azureADDeviceId -ne $Device.AzureAdDeviceId) {
        # Re-enrolment can replace registration after the old managed device was
        # removed. Accept inventory only when independent fresh Autopilot discovery
        # binds the exact serial, managed device and registration; retain old history.
        if ($null -eq $discovered) { throw 'Intune inventory identity check failed: registration mismatch on the bound managed device.' }
        $autopilot = Resolve-LiveAutopilotDeviceBySerial -Serial $Device.Serial
        if ($null -eq $autopilot -or $response.azureADDeviceId -isnot [string] -or
            [string]::IsNullOrWhiteSpace($response.azureADDeviceId) -or
            $discovered.azureADDeviceId -ne $response.azureADDeviceId -or
            $autopilot.managedDeviceId -ne $managedDeviceId -or
            $autopilot.azureActiveDirectoryDeviceId -ne $response.azureADDeviceId) {
            throw 'Intune inventory identity check failed: new registration is not confirmed by fresh managed-device and Autopilot discovery. Retry after enrolment settles or review duplicate/stale tenant records.'
        }
    }
    if ($null -ne $response.deviceName -and $response.deviceName -isnot [string]) { throw 'Intune inventory returned a malformed hostname.' }
    $wiFiMacAddress = ''
    try { $wiFiMacAddress = ConvertTo-EthernetMacAddress -Value $response.wiFiMacAddress -AdapterName 'Wi-Fi' } catch { $wiFiMacAddress = '' }
    $osVersion = if ($response.osVersion -is [string]) { $response.osVersion.Trim() } else { '' }
    return @{
        TenantId           = $tenantId
        ManagedDeviceId    = $managedDeviceId
        IntuneHostName     = ([string]$response.deviceName).Trim()
        EthernetMacAddress = ConvertTo-EthernetMacAddress -Value $response.ethernetMacAddress
        WiFiMacAddress     = $wiFiMacAddress
        EntraDeviceId      = if ($response.azureADDeviceId -is [string]) { $response.azureADDeviceId.Trim() } else { '' }
        PrimaryUser        = if ($response.userPrincipalName -is [string]) { $response.userPrincipalName.Trim() } else { '' }
        OperatingSystem    = if ($response.operatingSystem -is [string]) { $response.operatingSystem.Trim() } else { '' }
        OsVersion          = $osVersion
        OsRelease          = ConvertTo-WindowsReleaseName -OsVersion $osVersion
        LastSyncDateTime   = [string]$response.lastSyncDateTime
    }
}

function Invoke-DeviceInventoryPrefetch {
    <#
    .SYNOPSIS
        Collect Intune details for several devices in as few Graph requests as possible.
    .DESCRIPTION
        Round 1 batches the detail read for every device whose Intune ID is already saved,
        plus a serial search for any device without one. Round 2 batches the detail read
        for devices that round 1 found by serial. Get-LiveDeviceInventory then runs as
        normal and takes its answers from the batch, so every identity check still
        applies. Anything not answered by the batch is read individually as before.
    .PARAMETER Device
        Device records about to be checked; blank serials are ignored.
    .OUTPUTS
        None. The caller must call Clear-GraphReadPrefetch when it has finished.
    #>
    param([Parameter(Mandatory)][AllowEmptyCollection()][object[]]$Device)
    $round1 = [System.Collections.Generic.List[string]]::new()
    $searches = [System.Collections.Generic.List[string]]::new()
    foreach ($record in $Device) {
        if ($record -isnot [System.Collections.IDictionary] -or [string]::IsNullOrWhiteSpace([string]$record.Serial)) { continue }
        if (-not [string]::IsNullOrWhiteSpace([string]$record.ManagedDeviceId)) { $round1.Add((Get-ManagedDeviceInventoryUri -ManagedDeviceId ([string]$record.ManagedDeviceId))); continue }
        $search = Get-ManagedDeviceSerialLookupUri -Serial ([string]$record.Serial)
        $round1.Add($search)
        $searches.Add($search)
    }
    if ((Invoke-GraphReadPrefetch -Uri $round1.ToArray()) -eq 0 -or $searches.Count -eq 0) { return }
    $round2 = [System.Collections.Generic.List[string]]::new()
    $items = $Script:GraphSession['ReadPrefetch'].Items
    foreach ($search in $searches) {
        # Look without consuming: Resolve-LiveManagedDeviceBySerial still reads and validates it.
        if (-not $items.ContainsKey($search)) { continue }
        $found = @($items[$search].value)
        if ($found.Count -eq 1 -and $found[0].id -is [string] -and -not [string]::IsNullOrWhiteSpace($found[0].id)) { $round2.Add((Get-ManagedDeviceInventoryUri -ManagedDeviceId $found[0].id)) }
    }
    $null = Invoke-GraphReadPrefetch -Uri $round2.ToArray()
}

function Get-DeviceInventoryInterval {
    <#
    .SYNOPSIS
        Validate the central automatic-inventory interval, defaulting to five minutes.
    .OUTPUTS
        Positive whole-minute interval; malformed configuration throws before any read or save.
    #>
    $minutes = $Script:Config.InventoryPollingMinutes
    if ($null -eq $minutes) { return 5 }
    if (($minutes -isnot [int] -and $minutes -isnot [long]) -or $minutes -lt 1 -or $minutes -gt 1440) { throw 'InventoryPollingMinutes must be an integer from 1 to 1440.' }
    return [int]$minutes
}

function Test-DeviceInventoryEligible {
    <#
    .SYNOPSIS
        Identify active devices whose physical reseal milestone has been confirmed.
    .PARAMETER Device
        Current-cycle record; display codes are not used to identify the milestone.
    .OUTPUTS
        Boolean. Does not change steps or infer physical completion from inventory.
    #>
    param([Parameter(Mandatory)][System.Collections.IDictionary]$Device)
    if ($Device.Status -in @('completed', 'removed') -or $Device.RecoveryActive) { return $false }
    $stepId = Get-ManifestActionStepId -ActionName ConfirmReseal
    $step = $Device.Steps[$stepId]
    return [bool]($step -and $step.Success -and $step.CompletionState -in @('Verified', 'TechnicianConfirmed'))
}

function Get-IntuneInventoryFieldSetVersion {
    <#
    .SYNOPSIS
        Report which set of Intune details the current script captures.
    .DESCRIPTION
        Version 1 (no marker) held hostname and Ethernet MAC only. Version 2 added Wi-Fi
        MAC, Entra device ID, primary user and Windows version/release. Records below the
        current version are checked once more by the backfill, even when hostname and
        Ethernet are present. Raise this when a new field is added.
    .OUTPUTS
        Version number as text, because saved inventory values are all text.
    #>
    return '2'
}

function Test-DeviceInventoryDetailMissing {
    <#
    .SYNOPSIS
        Decide whether a saved device still needs details from Intune ("missing only").
    .DESCRIPTION
        Wi-Fi MAC and primary user can legitimately be blank (no wireless adapter, shared
        device), so they never force a recheck on their own; that avoids repeating Graph
        reads forever. Devices already marked NotFound are skipped unless requested.
    .PARAMETER Device
        Saved device dictionary from the current session or an archive.
    .PARAMETER IncludeNotFound
        Recheck devices previously recorded as not found in Intune.
    .OUTPUTS
        Boolean. Reads nothing and changes nothing.
    #>
    param([Parameter(Mandatory)][System.Collections.IDictionary]$Device, [switch]$IncludeNotFound)
    $inventory = $Device.IntuneInventory
    if ($inventory -isnot [System.Collections.IDictionary] -or $inventory.Count -eq 0) { return $true }
    if ($inventory.Status -eq 'NotFound' -and -not $IncludeNotFound) { return $false }
    if ([string]$inventory.FieldSetVersion -ne (Get-IntuneInventoryFieldSetVersion)) { return $true }
    foreach ($field in @('IntuneHostName', 'EthernetMacAddress', 'EntraDeviceId', 'OsVersion')) {
        if ([string]::IsNullOrWhiteSpace([string]$inventory[$field])) { return $true }
    }
    return $false
}

function Invoke-DeviceInventoryCheck {
    <#
    .SYNOPSIS
        Stage missing Intune metadata on a detached record, with a five-minute retry interval.
    .DESCRIPTION
        The caller owns persistence and publication. A final dispatch attempt can
        bypass timing and reseal eligibility, but never authentication or identity
        checks. Empty responses never erase values from the same managed-device
        identity and build cycle. Demo does not claim actual hardware inventory.
    .PARAMETER Device
        Detached record proposal; never pass an actively displayed record before saving.
    .PARAMETER Force
        Make the final dispatch read despite the interval, milestone or completeness.
    .PARAMETER Now
        Local clock used for scheduling and offline time-boundary tests.
    .PARAMETER MarkMissingAsNotFound
        Backfill only. A deleted (HTTP 404) bound device, or no managed device for the
        serial, is recorded as NotFound with saved values kept. Without this switch the
        live polling behaviour (Pending or Error, retried later) is unchanged.
    .OUTPUTS
        Boolean indicating a staged inventory check; transport failures become Error status.
    #>
    param([Parameter(Mandatory)][System.Collections.IDictionary]$Device, [switch]$Force, [datetime]$Now = (Get-Date), [switch]$MarkMissingAsNotFound)
    if ($Script:Runtime.IsDemoMode) { return $false }
    if (-not $Force -and -not (Test-DeviceInventoryEligible -Device $Device)) { return $false }
    # Every detail captured from Intune. Add future fields here, in the record loader's
    # allowed-key list and in Get-LiveDeviceInventory, then raise the field-set version.
    $detailFields = @('IntuneHostName', 'EthernetMacAddress', 'WiFiMacAddress', 'EntraDeviceId', 'PrimaryUser', 'OperatingSystem', 'OsVersion', 'OsRelease')
    $inventory = $Device.IntuneInventory
    $staleIdentity = $inventory -isnot [System.Collections.IDictionary] -or $inventory.BuildCycleId -ne [string]$Device.BuildCycleId -or
        $inventory.TenantId -ne [string]$Device.TenantId -or ($Device.ManagedDeviceId -and $inventory.ManagedDeviceId -ne $Device.ManagedDeviceId)
    # Backfill keeps saved archive values (older files may predate the build-cycle field);
    # a genuinely different managed device is still cleared below once Intune answers.
    if ($staleIdentity) {
        $saved = $inventory
        $inventory = @{ IntuneHostName = ''; EthernetMacAddress = ''; ManagedDeviceId = ''; TenantId = [string]$Device.TenantId; BuildCycleId = [string]$Device.BuildCycleId; CheckedAt = ''; CapturedAt = ''; LastSyncDateTime = ''; Status = 'Pending'; Mode = 'Live' }
        if ($MarkMissingAsNotFound -and $saved -is [System.Collections.IDictionary]) {
            foreach ($key in @($saved.Keys)) { if ($key -notin @('TenantId', 'BuildCycleId') -and -not [string]::IsNullOrEmpty([string]$saved[$key])) { $inventory[$key] = [string]$saved[$key] } }
        }
    }
    if (-not $Force) {
        $interval = Get-DeviceInventoryInterval
        if ($inventory.IntuneHostName -and $inventory.EthernetMacAddress) { return $false }
        $lastCheck = ConvertTo-RecordDate -Value $inventory.CheckedAt
        if ($lastCheck -ne [datetime]::MinValue -and $Now.ToUniversalTime() -ge $lastCheck.ToUniversalTime() -and ($Now.ToUniversalTime() - $lastCheck.ToUniversalTime()).TotalMinutes -lt $interval) { return $false }
        if (-not $Script:GraphSession.Connected -or $Script:GraphSession.RequiresReconnect) { return $false }
    }
    $inventory = ConvertTo-NormalisedValue -Value $inventory
    $inventory.CheckedAt = $Now.ToString('o')
    try {
        $fresh = Get-LiveDeviceInventory -Device $Device
        if ($null -ne $fresh) {
            if ($inventory.ManagedDeviceId -and $inventory.ManagedDeviceId -ne $fresh.ManagedDeviceId) {
                foreach ($field in $detailFields) { if ($inventory.Contains($field)) { $inventory[$field] = '' } }
                $inventory.CapturedAt = ''
            }
            $inventory.ManagedDeviceId = [string]$fresh.ManagedDeviceId
            $inventory.TenantId = [string]$fresh.TenantId
            $inventory.LastSyncDateTime = [string]$fresh.LastSyncDateTime
            foreach ($field in $detailFields) { if ($fresh[$field]) { $inventory[$field] = [string]$fresh[$field]; $inventory.CapturedAt = $Now.ToString('o') } }
            $inventory.FieldSetVersion = Get-IntuneInventoryFieldSetVersion
            $inventory.Status = if ($inventory.IntuneHostName -and $inventory.EthernetMacAddress) { 'Available' } else { 'Pending' }
        }
        elseif ($MarkMissingAsNotFound) { $inventory.Status = 'NotFound' }
        else { $inventory.Status = if ($inventory.IntuneHostName -and $inventory.EthernetMacAddress) { 'Available' } else { 'Pending' } }
    }
    catch {
        if ($MarkMissingAsNotFound -and (Get-GraphTransportFailure -RequestError $_).Status -eq '404') {
            $inventory.Status = 'NotFound'
            Write-AutopilotExpressLog -Message ('Device {0} is no longer in Intune (managed device not found); saved details were kept.' -f $Device.Serial) -Level INFO
        }
        else {
            $inventory.Status = 'Error'
            Write-AutopilotExpressLog -Message ('Inventory check failed; existing values retained and retry remains scheduled: {0}' -f $_.Exception.Message) -Level WARN
        }
    }
    $Device.IntuneInventory = $inventory
    return $true
}

function Invoke-DeviceInventoryPolling {
    <#
    .SYNOPSIS
        Service due read-only inventory checks and publish only after a verified checkpoint save.
    .PARAMETER Records
        Active session container shared by all navigation paths.
    .PARAMETER Schedule
        Optional prompt-local scan deadline. Discard before executing any command;
        only the main runspace may update records while this schedule is in use.
    .PARAMETER Now
        Current clock for scheduling and deterministic offline boundary checks.
    .OUTPUTS
        None. Announcements are emitted only after durable save; failures propagate.
    #>
    param([Parameter(Mandatory)][hashtable]$Records, [hashtable]$Schedule, [datetime]$Now = (Get-Date))
    if ($Script:Runtime.IsDemoMode -or -not $Script:GraphSession.Connected -or $Script:GraphSession.RequiresReconnect) { return }
    $interval = Get-DeviceInventoryInterval
    $nowUtc = $Now.ToUniversalTime()
    if ($null -ne $Schedule -and [object]::ReferenceEquals($Schedule.Records, $Records.Value) -and
        $Schedule.Interval -eq $interval -and $nowUtc -ge $Schedule.ScannedAt -and $nowUtc -lt $Schedule.NextScanAt) { return }
    $pollTimer = [Diagnostics.Stopwatch]::StartNew()
    $nextScanAt = [datetime]::MaxValue
    $dueById = @{}
    foreach ($record in $Records.Value) {
        if ($record.Status -in @('completed', 'removed') -or $record.RecoveryActive -or -not (Test-DeviceInventoryEligible -Device $record)) { continue }
        $inventory = $record.IntuneInventory
        $sameIdentity = $inventory -is [System.Collections.IDictionary] -and $inventory.BuildCycleId -eq [string]$record.BuildCycleId -and
        $inventory.TenantId -eq [string]$record.TenantId -and (-not $record.ManagedDeviceId -or $inventory.ManagedDeviceId -eq $record.ManagedDeviceId)
        if ($sameIdentity -and $inventory.IntuneHostName -and $inventory.EthernetMacAddress) { continue }
        $checkedAt = if ($sameIdentity) { ConvertTo-RecordDate -Value $inventory.CheckedAt } else { [datetime]::MinValue }
        if ($checkedAt -ne [datetime]::MinValue -and $nowUtc -ge $checkedAt.ToUniversalTime()) {
            $dueAt = $checkedAt.ToUniversalTime().AddMinutes($interval)
            if ($nowUtc -lt $dueAt) {
                if ($dueAt -lt $nextScanAt) { $nextScanAt = $dueAt }
                continue
            }
        }
        if (-not $record.RecordId -or $dueById.ContainsKey([string]$record.RecordId)) { throw 'Inventory polling requires unique non-empty workflow record IDs.' }
        $dueById[[string]$record.RecordId] = $record
    }
    if (-not $dueById.Count) {
        if ($null -ne $Schedule) {
            $Schedule.Records = $Records.Value
            $Schedule.Interval = $interval
            $Schedule.ScannedAt = $nowUtc
            $Schedule.NextScanAt = $nextScanAt
        }
        Write-Verbose ('Inventory scan: due=0; elapsed-ms={0:N2}.' -f $pollTimer.Elapsed.TotalMilliseconds)
        return
    }
    $proposed = ConvertTo-NormalisedValue -Value @($Records.Value)
    $changed = [System.Collections.Generic.List[object]]::new()
    try {
        Invoke-DeviceInventoryPrefetch -Device @($proposed | Where-Object { $dueById.ContainsKey([string]$_.RecordId) })
        foreach ($proposal in @($proposed)) {
            if ($dueById.ContainsKey([string]$proposal.RecordId) -and (Invoke-DeviceInventoryCheck -Device $proposal -Now $now)) { $changed.Add($proposal) }
        }
    }
    finally { Clear-GraphReadPrefetch }
    if (-not $changed.Count) { return }
    Write-UserDeviceRecords -Records $proposed
    foreach ($proposal in $changed) {
        $original = $dueById[[string]$proposal.RecordId]
        $previousStatus = [string]$original.IntuneInventory.Status
        $original.IntuneInventory = $proposal.IntuneInventory
        if ($original.IntuneInventory.Status -eq 'Available' -and $previousStatus -ne 'Available') {
            Write-Host ('Inventory available for {0}: hostname {1}; Ethernet MAC {2}.' -f $original.Serial, $original.IntuneInventory.IntuneHostName, $original.IntuneInventory.EthernetMacAddress)
        }
    }
    Write-Verbose ('Inventory polling: due={0}; saved={1}; elapsed-ms={2:N2}.' -f $dueById.Count, $changed.Count, $pollTimer.Elapsed.TotalMilliseconds)
}

function Get-ArchivedDeviceRecordFile {
    <#
    .SYNOPSIS
        List archived Live device-record files, oldest first.
    .DESCRIPTION
        Matches only the names written by Move-SessionFileToArchive for device records
        ('...autopilot-devices-<user>...-live-<yyyyMMdd-HHmmss>-<guid>.json'). Demo
        archives, bench files, session indexes and backup copies never match.
    .OUTPUTS
        FileInfo array; empty when the archive folder does not exist yet.
    #>
    $folder = Get-ArchiveFolderPath
    if (-not (Test-Path -LiteralPath $folder -PathType Container)) { return , @() }
    $pattern = '^(?:\d{{8}}-\d{{4}}-)?{0}-.+-live-\d{{8}}-\d{{6}}-[0-9a-fA-F]{{8}}-[0-9a-fA-F]{{4}}-[0-9a-fA-F]{{4}}-[0-9a-fA-F]{{4}}-[0-9a-fA-F]{{12}}\.json$' -f [regex]::Escape($Script:Config.UserDataFilePrefix)
    return , @(Get-ChildItem -LiteralPath $folder -File -ErrorAction Stop | Where-Object { $_.Name -match $pattern } | Sort-Object Name)
}

function Update-DeviceInventoryFromIntune {
    <#
    .SYNOPSIS
        Fill in missing Intune details for devices in the current session and all Live archives.
    .DESCRIPTION
        Read-only towards Intune: one managed-device GET per device that still needs
        details (two when the managed-device ID was never saved). Devices with complete
        details, no tenant, or another tenant are skipped before any Graph request.
        Saved values are never erased by an empty answer; devices missing from Intune are
        marked NotFound and keep what was saved.

        Current session: saved through the normal checkpoint save, then published.
        Archives: read with JSON dates kept as text, only IntuneInventory is changed, and
        the result is round-trip verified before a guarded save. The replaced file is kept
        as '<file>.before-intune-details-<time>' so the archive's own .previous survives.
        A file that changed on disk during the run is skipped, not overwritten.
    .PARAMETER Records
        Current-session container (@{ Value = records }) shared with the main menu.
    .PARAMETER IncludeNotFound
        Also recheck devices previously recorded as not found in Intune.
    .OUTPUTS
        Ordered summary dictionary of counts and readable outcome lines.
    #>
    param([Parameter(Mandatory)][hashtable]$Records, [switch]$IncludeNotFound)
    $summary = [ordered]@{ Checked = 0; Updated = 0; NothingNew = 0; AlreadyComplete = 0; NotFound = 0; Errors = 0; NoTenant = 0; OtherTenant = 0; ArchiveFilesUpdated = 0; ArchiveFilesSkipped = 0; Lines = [Collections.Generic.List[string]]::new() }
    if ($Script:Runtime.IsDemoMode) { throw 'Demo mode never reads Intune. Switch to Live mode to update device details.' }
    if (-not $Script:GraphSession.Connected -or $Script:GraphSession.RequiresReconnect -or $Script:GraphSession.IsSimulated) { throw 'A connected Live Microsoft Graph session is required.' }
    $sessionTenant = [string]$Script:GraphSession.TenantId
    $comparedFields = @('IntuneHostName', 'EthernetMacAddress', 'WiFiMacAddress', 'EntraDeviceId', 'PrimaryUser', 'OperatingSystem', 'OsVersion', 'OsRelease', 'FieldSetVersion', 'ManagedDeviceId', 'Status', 'LastSyncDateTime')

    # Build one work list across every source so the progress bar shows overall progress.
    $sources = [Collections.Generic.List[hashtable]]::new()
    $sources.Add(@{ Name = 'current session'; Path = $null; Working = [object[]](ConvertTo-NormalisedValue -Value @($Records.Value)) })
    $preserveDates = (Get-Command ConvertFrom-Json).Parameters.ContainsKey('DateKind')
    if ($PSVersionTable.PSEdition -eq 'Core' -and -not $preserveDates) {
        $summary.Lines.Add('Archived sessions were not checked: this needs PowerShell 7.5 or later (or Windows PowerShell 5.1) so saved dates are not rewritten.')
    }
    else {
        foreach ($file in (Get-ArchivedDeviceRecordFile)) {
            try {
                Assert-FileWriteRecoveryState -Path $file.FullName
                $content = Get-Content -LiteralPath $file.FullName -Raw -ErrorAction Stop
                if ([string]::IsNullOrWhiteSpace($content)) { throw 'the file is empty' }
                $jsonParameters = @{ InputObject = $content; ErrorAction = 'Stop' }
                if ($preserveDates) { $jsonParameters.DateKind = 'String' }
                $parsed = ConvertFrom-Json @jsonParameters
                $original = @(foreach ($item in @($parsed)) { ConvertTo-NormalisedValue -Value $item })
                if (@($original | Where-Object { $_ -isnot [System.Collections.IDictionary] }).Count) { throw 'it contains entries that are not device records' }
                $working = @(foreach ($item in $original) { ConvertTo-NormalisedValue -Value $item })
                $sources.Add(@{ Name = $file.Name; Path = $file.FullName; Hash = (Get-FileHash -LiteralPath $file.FullName -Algorithm SHA256).Hash; Original = $original; Working = $working; JsonParameters = $jsonParameters })
            }
            catch {
                $summary.ArchiveFilesSkipped++
                $summary.Lines.Add(('Skipped archive {0}: {1}' -f $file.Name, $_.Exception.Message))
                Write-AutopilotExpressLog -Message ('Device detail update skipped archive {0}: {1}' -f $file.Name, $_.Exception.Message) -Level WARN
            }
        }
    }

    $queue = [Collections.Generic.List[hashtable]]::new()
    foreach ($source in $sources) {
        foreach ($record in $source.Working) {
            if ($record -isnot [System.Collections.IDictionary] -or [string]::IsNullOrWhiteSpace([string]$record.Serial)) { continue }
            if (-not (Test-DeviceInventoryDetailMissing -Device $record -IncludeNotFound:$IncludeNotFound)) { $summary.AlreadyComplete++; continue }
            if ([string]::IsNullOrWhiteSpace([string]$record.TenantId)) { $summary.NoTenant++; continue }
            if ([string]$record.TenantId -ine $sessionTenant) { $summary.OtherTenant++; continue }
            $queue.Add(@{ Source = $source; Record = $record })
        }
    }
    Write-AutopilotExpressLog -Message ('Device detail update started: {0} device(s) to check across {1} source(s).' -f $queue.Count, $sources.Count) -Level INFO

    # Read Intune once per queued device. Changes are staged on detached copies only.
    # Devices are batched 20 at a time (Graph's batch limit), so 45 devices take about
    # three requests instead of 45, and no batched answer is held for long.
    $activity = 'Updating device details from Intune'
    $changedSources = @{}
    $position = 0
    try {
        foreach ($item in $queue) {
            $position++
            if (($position - 1) % 20 -eq 0) {
                Clear-GraphReadPrefetch
                Invoke-DeviceInventoryPrefetch -Device @($queue.GetRange($position - 1, [Math]::Min(20, $queue.Count - $position + 1)) | ForEach-Object { $_.Record })
            }
            $record = $item.Record
            Write-Progress -Activity $activity -Status ('Device {0} of {1}: {2}' -f $position, $queue.Count, $record.Serial) -PercentComplete ([int](($position - 1) * 100 / [Math]::Max(1, $queue.Count)))
            $before = @{}
            foreach ($field in $comparedFields) { $before[$field] = if ($record.IntuneInventory -is [System.Collections.IDictionary]) { [string]$record.IntuneInventory[$field] } else { '' } }
            $isActive = $null -eq $item.Source.Path -and $record.Status -notin @('completed', 'removed')
            $null = Invoke-DeviceInventoryCheck -Device $record -Force -MarkMissingAsNotFound:(-not $isActive)
            $summary.Checked++
            $after = $record.IntuneInventory
            $changed = @($comparedFields | Where-Object { [string]$after[$_] -cne $before[$_] }).Count -gt 0
            if ($changed) { $changedSources[$item.Source.Name] = $item.Source }
            switch ([string]$after.Status) {
                'NotFound' { $summary.NotFound++ }
                'Error' { $summary.Errors++ }
                default {
                    $gained = @($comparedFields | Where-Object { $_ -notin @('Status', 'LastSyncDateTime', 'FieldSetVersion') -and [string]$after[$_] -and [string]$after[$_] -cne $before[$_] })
                    if ($gained.Count) { $summary.Updated++ } else { $summary.NothingNew++ }
                }
            }
        }
    }
    finally { Clear-GraphReadPrefetch }
    Write-Progress -Activity $activity -Completed

    # Save only sources whose details or status actually changed; a new check time alone is not worth a rewrite.
    foreach ($source in $sources) {
        if (-not $changedSources.ContainsKey($source.Name)) { continue }
        if ($null -eq $source.Path) {
            Write-UserDeviceRecords -Records $source.Working
            foreach ($proposal in $source.Working) {
                $original = @($Records.Value | Where-Object { $_.RecordId -and $_.RecordId -eq $proposal.RecordId }) | Select-Object -First 1
                if ($null -ne $original) { $original.IntuneInventory = $proposal.IntuneInventory }
            }
            $summary.Lines.Add('Saved updated details to the current session.')
            continue
        }
        try {
            $proposed = ConvertTo-Json -InputObject @($source.Working) -Depth 100
            $checkParameters = $source.JsonParameters.Clone()
            $checkParameters.InputObject = $proposed
            # Assign first: Windows PowerShell 5.1 emits a parsed JSON array as one object.
            $parsedProposal = ConvertFrom-Json @checkParameters
            $roundTrip = @(foreach ($item in @($parsedProposal)) { ConvertTo-NormalisedValue -Value $item })
            if (-not (Test-AttemptEvidenceEqual -Left @($source.Working) -Right $roundTrip)) { throw 'the proposed file did not read back identically' }
            # Prove that nothing except IntuneInventory differs from the archived evidence.
            for ($index = 0; $index -lt $source.Original.Count; $index++) {
                $left = ConvertTo-NormalisedValue -Value $source.Original[$index]
                $right = ConvertTo-NormalisedValue -Value $roundTrip[$index]
                $left.Remove('IntuneInventory'); $right.Remove('IntuneInventory')
                if (-not (Test-AttemptEvidenceEqual -Left $left -Right $right)) { throw 'a field other than the Intune details would have changed' }
            }
            if ((Get-FileHash -LiteralPath $source.Path -Algorithm SHA256).Hash -ne $source.Hash) { throw 'the file changed on disk during this run' }
            $backupPath = '{0}.before-intune-details-{1}' -f $source.Path, (Get-Date -Format 'yyyyMMdd-HHmmss')
            Write-Utf8File -Path $source.Path -Content $proposed -PreviousPath $backupPath
            $summary.ArchiveFilesUpdated++
            Write-AutopilotExpressLog -Message ('Device details updated in archive {0}; original kept as {1}.' -f $source.Name, (Split-Path -Leaf $backupPath)) -Level INFO
        }
        catch {
            $summary.ArchiveFilesSkipped++
            $summary.Lines.Add(('Archive {0} was not changed: {1}' -f $source.Name, $_.Exception.Message))
            Write-AutopilotExpressLog -Message ('Device detail update did not save archive {0}: {1}' -f $source.Name, $_.Exception.Message) -Level WARN
        }
    }
    Write-AutopilotExpressLog -Message ('Device detail update finished: checked={0}; updated={1}; nothing-new={2}; not-found={3}; errors={4}; already-complete={5}; no-tenant={6}; other-tenant={7}; archives-updated={8}; archives-skipped={9}.' -f $summary.Checked, $summary.Updated, $summary.NothingNew, $summary.NotFound, $summary.Errors, $summary.AlreadyComplete, $summary.NoTenant, $summary.OtherTenant, $summary.ArchiveFilesUpdated, $summary.ArchiveFilesSkipped) -Level INFO
    return $summary
}

function Show-DeviceInventoryBackfill {
    <#
    .SYNOPSIS
        Data Settings option 5: fill in missing Intune details for devices already processed.
    .DESCRIPTION
        Explains what will happen, offers the choice to recheck devices previously not
        found, runs Update-DeviceInventoryFromIntune and shows a plain-language summary.
        Default is [1] (missing details only), matching the agreed "missing only" rule.
    .PARAMETER Records
        Current-session container shared with the main menu.
    .OUTPUTS
        Host text only; always returns control to the calling menu.
    #>
    param([Parameter(Mandatory)][hashtable]$Records)
    Show-ScriptScreen -Title 'Update Device Details from Intune' -PromptFollows
    if ($Script:Runtime.IsDemoMode) {
        Write-Host 'Demo mode does not read Intune, so there is nothing to update. Restart in Live mode to use this option.'
        Show-ReturnToMainMenu
        return
    }
    if (-not $Script:GraphSession.Connected -or $Script:GraphSession.RequiresReconnect) {
        Write-Host 'Not connected to Microsoft Graph. Use Session and Script Settings, option 9 (Reconnect to Microsoft Graph), then try again.'
        Show-ReturnToMainMenu
        return
    }
    Write-Host 'This checks Intune for devices in this session and in archived sessions that are missing:'
    Write-Host '  hostname, Ethernet MAC, Wi-Fi MAC, Entra device ID, primary user, and Windows version.'
    Write-Host 'Only missing details are filled in. Nothing in Intune is changed, and saved details are never cleared.'
    Write-Host 'Archived files are backed up beside the original before they are updated.'
    $choice = Read-ValidatedInput -Prompt 'Choose: [1] Check missing details [2] Also recheck devices not found in Intune last time [0] Cancel' -Default '1' -Type 'Choice' -Choices @('1', '2', '0')
    if ($choice -eq '0') { return }
    try { $summary = Update-DeviceInventoryFromIntune -Records $Records -IncludeNotFound:($choice -eq '2') }
    catch {
        Write-Host ('Device details were not updated: {0}' -f $_.Exception.Message)
        Write-AutopilotExpressLog -Message ('Device detail update stopped: {0}' -f $_.Exception.Message) -Level ERROR
        Show-ReturnToMainMenu
        return
    }
    Show-ScriptScreen -Title 'Update Device Details from Intune'
    Write-Host ('Devices checked in Intune:            {0}' -f $summary.Checked)
    Write-Host ('  New details saved:                  {0}' -f $summary.Updated)
    Write-Host ('  No new details available yet:       {0}' -f $summary.NothingNew)
    Write-Host ('  Not found in Intune (values kept):  {0}' -f $summary.NotFound)
    Write-Host ('  Could not be read (see the log):    {0}' -f $summary.Errors)
    Write-Host ('Already complete, not checked:        {0}' -f $summary.AlreadyComplete)
    Write-Host ('Skipped, no tenant recorded:          {0}' -f $summary.NoTenant)
    Write-Host ('Skipped, belongs to another tenant:   {0}' -f $summary.OtherTenant)
    Write-Host ('Archive files updated:                {0}' -f $summary.ArchiveFilesUpdated)
    Write-Host ('Archive files skipped:                {0}' -f $summary.ArchiveFilesSkipped)
    foreach ($line in $summary.Lines) { Write-Host $line }
    Show-ReturnToMainMenu
}

function Read-DeviceInventoryInput {
    <#
    .SYNOPSIS
        Keep the normal host prompt active while the main runspace services inventory.
    .DESCRIPTION
        Only Read-Host runs in the temporary runspace. Graph context, records and
        checkpoint writes remain on the main runspace, preventing concurrent saves.
        Dispatch the prompt before inventory work. A prompt-local deadline skips
        redundant idle scans; every new prompt rechecks current record eligibility.
        A checkpoint failure pauses polling and propagates after the current line
        finishes; Read-Host cannot be safely interrupted by stopping its runspace.
        The submitted line is discarded on failure, never executed as a command.

        While Read-Host is waiting, the shared console host blocks every screen write
        from this runspace (Write-Host, verbose and log lines) until Enter is pressed.
        Polling output is therefore held in memory and written, in its original order,
        as soon as the prompt returns. Without this, the first log line stalled each
        Intune read and save until the next key press (seen in real logs: up to 55 min).
    .PARAMETER Prompt
        Existing accessible prompt, including its existing default text.
    .PARAMETER Records
        Current session container; no credential or SDK context crosses runspaces.
    .OUTPUTS
        One response string, preserving ordinary host editing and scanner input.
    #>
    param([Parameter(Mandatory)][string]$Prompt, [Parameter(Mandatory)][hashtable]$Records)
    $promptTimer = [Diagnostics.Stopwatch]::StartNew()
    $schedule = @{}
    $heldOutput = [System.Collections.Generic.List[object]]::new()
    $runspace = [runspacefactory]::CreateRunspace($Host)
    $pipeline = [powershell]::Create()
    try {
        $runspace.Open()
        $pipeline.Runspace = $runspace
        $null = $pipeline.AddScript('param($Prompt) Read-Host -Prompt $Prompt').AddArgument($Prompt)
        $pending = $pipeline.BeginInvoke()
        Write-Verbose ('Inventory prompt dispatched: elapsed-ms={0:N2}; foreground polling follows.' -f $promptTimer.Elapsed.TotalMilliseconds)
        $pollingFailure = $null
        do {
            if ($null -ne $pollingFailure) { continue }
            # Capture every stream (*>&1) so no screen write can wait on the open prompt.
            try { Invoke-DeviceInventoryPolling -Records $Records -Schedule $schedule *>&1 | ForEach-Object { $heldOutput.Add($_) } }
            catch {
                $pollingFailure = $_
                $heldOutput.Add('Automatic inventory polling paused after a save failure. Finish the current input line to stop safely; that input will not execute. Preserve checkpoint artefacts for review.')
            }
        }
        while (-not $pending.AsyncWaitHandle.WaitOne(1000))
        $responses = $pipeline.EndInvoke($pending)
        if ($null -ne $pollingFailure) { throw $pollingFailure }
        if ($pipeline.HadErrors) { throw 'Host input failed while automatic inventory collection was active.' }
        return [string]($responses | Select-Object -First 1)
    }
    finally {
        if ($pipeline.InvocationStateInfo.State -eq 'Running') { $pipeline.Stop() }
        $pipeline.Dispose()
        $runspace.Dispose()
        # The prompt has returned, so held lines can now reach the screen and transcript.
        foreach ($item in $heldOutput) {
            if ($item -is [System.Management.Automation.InformationRecord]) {
                if ($item.MessageData -is [System.Management.Automation.HostInformationMessage]) { Write-Host $item.MessageData.Message }
                else { Write-Information -MessageData $item.MessageData -InformationAction Continue }
            }
            elseif ($item -is [System.Management.Automation.VerboseRecord]) { Write-Verbose $item.Message }
            elseif ($item -is [System.Management.Automation.WarningRecord]) { Write-Warning $item.Message }
            elseif ($item -is [System.Management.Automation.DebugRecord]) { Write-Debug $item.Message }
            elseif ($item -is [System.Management.Automation.ErrorRecord]) { Write-Error -ErrorRecord $item }
            else { Write-Host ([string]$item) }
        }
    }
}

function Resolve-LiveEntraDeviceObject {
    <#
    .SYNOPSIS
        Resolve one Entra object for the exact device registration identifier.
    .PARAMETER AzureAdDeviceId
        Device registration ID, distinct from the returned Entra object ID.
    .OUTPUTS
        Matching object or null. Malformed, paged or ambiguous results throw.
    #>
    param([Parameter(Mandatory)][ValidateNotNullOrEmpty()][string]$AzureAdDeviceId)
    $escapedDeviceId = $AzureAdDeviceId.Replace("'", "''")
    $uri = ('https://graph.microsoft.com/v1.0/devices?$filter=deviceId eq ''{0}''&$select=id,displayName,deviceId' -f $escapedDeviceId)
    $response = Invoke-GraphApiRequest -Method 'GET' -Uri $uri
    if ($null -eq $response -or $response.value -isnot [array] -or $response.'@odata.nextLink') {
        throw 'Entra device lookup returned an incomplete or malformed response.'
    }
    $identities = $response.value
    if ($identities.Count -gt 1) { throw 'Multiple Entra objects matched the device ID; resolve duplicate records before continuing.' }
    if ($identities.Count -eq 0) { return $null }
    $identity = $identities[0]
    if ($identity.id -isnot [string] -or [string]::IsNullOrWhiteSpace($identity.id) -or
        $identity.deviceId -isnot [string] -or $identity.deviceId -ne $AzureAdDeviceId) {
        throw 'Entra device lookup returned a missing or unexpected identity.'
    }
    return $identity
}

function Get-LiveManagedDevicePrimaryUsers {
    <#
    .SYNOPSIS
        Read the complete validated primary-user relationship for one managed device.
    .PARAMETER ManagedDeviceId
        Freshly resolved Intune GUID, not an Entra device ID.
    .OUTPUTS
        Validated user collection; incomplete/malformed evidence throws.
    #>
    param([Parameter(Mandatory)][string]$ManagedDeviceId)
    $response = Invoke-GraphApiRequest -Method 'GET' -Uri ('https://graph.microsoft.com/v1.0/deviceManagement/managedDevices/{0}/users?$select=id,displayName,userPrincipalName' -f $ManagedDeviceId)
    if ($null -eq $response -or $response.value -isnot [array]) {
        throw 'Managed-device primary-user read-back returned an invalid users collection.'
    }
    if ($response.'@odata.nextLink') {
        throw 'Managed-device primary-user read-back was incomplete; additional users pages were returned.'
    }
    $users = @()
    foreach ($rawUser in @($response.value)) {
        if ($rawUser.id -isnot [string] -or [string]::IsNullOrWhiteSpace($rawUser.id) -or $rawUser.userPrincipalName -isnot [string] -or [string]::IsNullOrWhiteSpace($rawUser.userPrincipalName)) { throw 'Managed-device primary-user read-back contained an invalid identity.' }
        $user = ConvertTo-DirectoryUserRecord -User $rawUser
        if ($null -eq $user) { throw 'Managed-device primary-user read-back contained an invalid identity.' }
        $users += $user
    }
    return $users
}

function Test-ManagedDevicePrimaryUserMatch {
    <#
    .SYNOPSIS
        Verifies that one observed primary-user relationship matches the target.
    .DESCRIPTION
        Object IDs are authoritative when available on both records. UPN matching
        is a fallback only when an ID is absent. Multiple, missing or unrelated
        relationships cannot establish exclusive primary-user assignment.
    .PARAMETER Users
        Complete read-back collection; empty collections do not match.
    .PARAMETER User
        Selected target identity, not an inferred account role.
    .OUTPUTS
        Boolean indicating an exclusive matching primary-user relationship.
    #>
    param(
        [AllowNull()][AllowEmptyCollection()][object[]]$Users,
        [Parameter(Mandatory)]$User
    )
    if ($null -eq $Users -or $Users.Count -ne 1 -or $null -eq $Users[0]) { return $false }
    $observedUser = $Users[0]
    if ($observedUser.Id -and $User.Id) { return [string]$observedUser.Id -ieq [string]$User.Id }
    if ([string]::IsNullOrWhiteSpace([string]$observedUser.UserPrincipalName) -or
        [string]::IsNullOrWhiteSpace([string]$User.UserPrincipalName)) { return $false }
    return [string]$observedUser.UserPrincipalName -ieq [string]$User.UserPrincipalName
}

function Get-LiveTenantBinding {
    <#
    .SYNOPSIS
        Validate actual SDK tenant and optional record ownership without changing state.
    .PARAMETER Device
        Optional device dictionary whose persisted tenant must match the session.
    .PARAMETER AllowUnbound
        Permit only clean new records; resolution stages binding after all reads.
    .OUTPUTS
        Authenticated tenant GUID text, or an actionable terminating refusal.
    #>
    param($Device, [switch]$AllowUnbound)
    if ($Script:Runtime.IsDemoMode) { return '' }
    if (-not $Script:GraphSession.Connected -or $Script:GraphSession.IsSimulated) { throw 'A connected non-simulated Graph session is required for tenant binding.' }
    $tenantId = $Script:GraphSession.TenantId
    $context = Get-MgContext -ErrorAction Stop
    $guidPattern = '^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$'
    if ($tenantId -isnot [string] -or $tenantId -notmatch $guidPattern -or
        $context.TenantId -isnot [string] -or $context.TenantId -notmatch $guidPattern) { throw 'Graph session and actual context TenantId must be GUID strings.' }
    if ($context.TenantId -ine $tenantId) { throw 'Actual Graph context TenantId changed; reconnect before reusing records or groups.' }
    $expectedTenantId = $Script:RuntimeConfig.graph.expectedTenantId
    if ($null -ne $expectedTenantId -and ($expectedTenantId -isnot [string] -or
            ($expectedTenantId -cne '' -and $expectedTenantId -notmatch $guidPattern))) { throw 'Configured expectedTenantId must be empty or a tenant GUID string.' }
    if ($expectedTenantId -and $tenantId -ine $expectedTenantId) { throw 'Graph tenant does not match configured expectedTenantId; no device activity is permitted.' }
    if ($null -ne $Device) {
        $deviceTenant = $Device.TenantId
        if (($Device.Contains('TenantId') -and $deviceTenant -isnot [string]) -or
            ($null -ne $deviceTenant -and $deviceTenant -cne '' -and $deviceTenant -notmatch $guidPattern)) { throw 'Device TenantId must be empty legacy text or a GUID string.' }
        if ($deviceTenant) {
            if ($deviceTenant -ine $tenantId) { throw 'Device TenantId does not match the authenticated tenant; no device reads or writes are permitted.' }
        }
        else {
            foreach ($field in @('AutopilotDeviceId', 'ManagedDeviceId', 'AzureAdDeviceId', 'EntraDeviceId', 'FinalPrimaryUserId', 'TechnicianUserPrincipalName', 'FinalPrimaryUserPrincipalName', 'CompletedBy', 'RecoveryReason')) {
                if ($Device[$field]) { throw 'Legacy device has no TenantId but contains cached IDs or evidence; deliberate tenant migration is required.' }
            }
            if ($Device.Steps.Count -gt 0 -or $Device.RecoveryHistory.Count -gt 0 -or $Device.RecoveryActive -or $Device.IsCompletionVerified -or
                ($Device.CompletedAt -and $Device.CompletedAt -ne [DateTime]::MinValue) -or
                ($Device.RecoveryStartedAt -and $Device.RecoveryStartedAt -ne [DateTime]::MinValue) -or $Device.Status -eq 'completed') {
                throw 'Legacy device has no TenantId but contains workflow or recovery evidence; deliberate tenant migration is required.'
            }
            if (-not $AllowUnbound) { throw 'Resolve this new device successfully to bind its TenantId before recording Live evidence.' }
        }
    }
    return $tenantId
}

function Resolve-LiveAutopilotContext {
    <#
    .SYNOPSIS
        Refresh device identifiers only after all identity reads succeed.
    .PARAMETER Device
        Existing device dictionary to refresh from current Graph evidence.
    .PARAMETER KnownAutopilotDevice
        Autopilot identity already read by the caller in this operation (for example the
        poll that found it). Skips a second identical serial search; it must match the serial.
    .OUTPUTS
        Resolved Graph records. Failed reads leave the device unchanged;
        absent records clear cached mutation identifiers on successful refresh.
    .NOTES
        Graph call budget: the Entra object lookup is skipped when the record already holds
        an Entra object ID for the same device registration ID that Graph returned now.
        An Entra object ID never changes for a registration ID, and a deleted object makes
        the next membership read fail closed, so the reuse cannot hide a changed device.
    #>
    param([Parameter(Mandatory)]$Device, $KnownAutopilotDevice)

    $tenantId = Get-LiveTenantBinding -Device $Device -AllowUnbound
    $autopilotDevice = if ($null -ne $KnownAutopilotDevice) {
        if ($KnownAutopilotDevice.serialNumber -isnot [string] -or $KnownAutopilotDevice.serialNumber -ine $Device.Serial) { throw 'The supplied Autopilot identity does not match the selected serial.' }
        $KnownAutopilotDevice
    }
    else { Resolve-LiveAutopilotDeviceBySerial -Serial $Device.Serial }
    $managedDevice = Resolve-LiveManagedDeviceBySerial -Serial $Device.Serial
    $entraDevice = $null
    $resolved = @{ TenantId = $tenantId; AutopilotDeviceId = ''; ManagedDeviceId = ''; AzureAdDeviceId = ''; EntraDeviceId = ''; IntuneDeviceName = $Device.IntuneDeviceName; GroupTag = $Device.GroupTag }

    if ($null -ne $autopilotDevice) {
        $resolved.AutopilotDeviceId = [string]$autopilotDevice.id
        $resolved.GroupTag = [string]$autopilotDevice.groupTag
        if ($autopilotDevice.displayName) { $resolved.IntuneDeviceName = [string]$autopilotDevice.displayName }
        if ($autopilotDevice.azureActiveDirectoryDeviceId) { $resolved.AzureAdDeviceId = [string]$autopilotDevice.azureActiveDirectoryDeviceId }
    }

    if ($null -ne $managedDevice) {
        $resolved.ManagedDeviceId = [string]$managedDevice.id
        if ($managedDevice.deviceName) { $resolved.IntuneDeviceName = [string]$managedDevice.deviceName }
        if ($managedDevice.azureADDeviceId) { $resolved.AzureAdDeviceId = [string]$managedDevice.azureADDeviceId }
    }

    if ($resolved.AzureAdDeviceId) {
        $entraDevice = Get-StoredEntraDeviceObject -Device $Device -AzureAdDeviceId $resolved.AzureAdDeviceId
        if ($null -eq $entraDevice) { $entraDevice = Resolve-LiveEntraDeviceObject -AzureAdDeviceId $resolved.AzureAdDeviceId }
        if ($null -ne $entraDevice) { $resolved.EntraDeviceId = [string]$entraDevice.id }
    }
    foreach ($propertyName in $resolved.Keys) { $Device[$propertyName] = $resolved[$propertyName] }

    return [ordered]@{ Autopilot = $autopilotDevice; Managed = $managedDevice; Entra = $entraDevice }
}

function Get-StoredEntraDeviceObject {
    <#
    .SYNOPSIS
        Reuse the saved Entra object ID when the device registration has not changed.
    .DESCRIPTION
        Saves one Graph read per identity refresh. Only the record's own saved pair is
        trusted, and only when its registration ID equals the one Graph just returned.
    .PARAMETER Device
        Workflow record holding the saved AzureAdDeviceId and EntraDeviceId.
    .PARAMETER AzureAdDeviceId
        Registration ID freshly reported by Autopilot or Intune in this operation.
    .OUTPUTS
        Minimal identity (id, deviceId) or null when a fresh lookup is required.
    #>
    param([Parameter(Mandatory)]$Device, [Parameter(Mandatory)][string]$AzureAdDeviceId)
    $savedObjectId = [string]$Device.EntraDeviceId
    if ([string]::IsNullOrWhiteSpace($savedObjectId) -or [string]$Device.AzureAdDeviceId -ine $AzureAdDeviceId) { return $null }
    return @{ id = $savedObjectId; deviceId = $AzureAdDeviceId }
}

function Get-LivePreProvisioningGroup {
    <#
    .SYNOPSIS
        Resolve exactly one pre-provisioning group from its configured display name.
    .DESCRIPTION
        The group rarely changes, so a validated answer is kept in the Graph session for
        15 minutes (per tenant and group name) and reused instead of searching again for
        every device. The cache ends when the session closes or reconnects, and is cleared
        by Clear-PreProvisioningGroupCache when a membership change fails, so a renamed or
        replaced group is always picked up by the next attempt.
    .OUTPUTS
        Validated group; missing, duplicate or malformed matches throw before mutation.
    #>
    $groupName = Get-ConfiguredPreProvisioningGroupDisplayName
    $cacheKey = '{0}|{1}' -f $Script:GraphSession.TenantId, $groupName
    $cached = $Script:GraphSession['PreProvisioningGroupCache']
    if ($cached -is [System.Collections.IDictionary] -and $cached.Key -ceq $cacheKey -and ((Get-Date).ToUniversalTime() - $cached.CachedAt).TotalMinutes -lt 15) { return $cached.Group }
    if ([string]::IsNullOrEmpty($groupName)) { throw 'Group not found: no pre-provisioning group name is configured.' }
    $groups = Get-GraphDiscoveryCollection -Uri (Get-PreProvisioningGroupLookupUri -GroupName $groupName)
    if ($groups.Count -eq 0) { throw ('Group not found: {0}' -f $groupName) }
    if ($groups.Count -gt 1) { throw ('Multiple groups matched display name: {0}' -f $groupName) }
    if ($groups[0].displayName -ne $groupName) { throw 'Group discovery returned an unexpected display name.' }
    $Script:GraphSession['PreProvisioningGroupCache'] = @{ Key = $cacheKey; Group = $groups[0]; CachedAt = (Get-Date).ToUniversalTime() }
    return $groups[0]
}

function Clear-PreProvisioningGroupCache {
    <#
    .SYNOPSIS
        Forget the saved pre-provisioning group so the next lookup reads Graph again.
    .OUTPUTS
        None.
    #>
    if ($Script:GraphSession -is [System.Collections.IDictionary] -and $Script:GraphSession.Contains('PreProvisioningGroupCache')) { [void]$Script:GraphSession.Remove('PreProvisioningGroupCache') }
}

function Get-LiveAutopilotDeviceById {
    <#
    .SYNOPSIS
        Read current tag and assigned-user properties for one Autopilot identity.
    .PARAMETER AutopilotDeviceId
        Resolved Autopilot GUID, distinct from managed-device and Entra identities.
    .OUTPUTS
        Matching identity from the stable v1.0 resource read; failures propagate.
    #>
    param([Parameter(Mandatory)][string]$AutopilotDeviceId)

    $identity = Invoke-GraphApiRequest -Method 'GET' -Uri ('https://graph.microsoft.com/v1.0/deviceManagement/windowsAutopilotDeviceIdentities/{0}' -f $AutopilotDeviceId)
    if (-not $identity.id -and $identity.value -is [System.Collections.IDictionary]) { $identity = $identity.value }
    if ($identity.id -isnot [string] -or $identity.id -ine $AutopilotDeviceId) { throw 'Read-back returned a missing or unexpected Autopilot identity.' }
    return $identity
}

function Test-LiveGroupMembership {
    <#
    .SYNOPSIS
        Reads direct membership, failing closed on ambiguous Graph errors.
    .DESCRIPTION
        Uses the selected device's complete direct memberships, without advanced-query indexes.
        A successful device relationship read establishes its existence; absence
        additionally requires the expected group identity to exist.
        HTTP errors, including 404, never establish absence.
    .PARAMETER GroupId
        Group object ID to inspect.
    .PARAMETER DirectoryObjectId
        Device directory object ID to inspect.
    .PARAMETER GroupConfirmed
        The caller has just written to this exact group and Graph accepted it, which proves
        the group exists; the separate group existence read is then skipped.
    .OUTPUTS
        Boolean membership state, or a terminating read/identity error.
    #>
    param(
        [Parameter(Mandatory)][ValidateNotNullOrEmpty()][string]$GroupId,
        [Parameter(Mandatory)][ValidateNotNullOrEmpty()][string]$DirectoryObjectId,
        [switch]$GroupConfirmed
    )

    $members = Get-GraphDiscoveryCollection -Uri ('https://graph.microsoft.com/v1.0/devices/{0}/memberOf' -f $DirectoryObjectId) -RequiredTextProperty id
    if (@($members | Where-Object { $_.id -ieq $GroupId }).Count -eq 1) { return $true }
    if ($GroupConfirmed) { return $false }
    $group = Invoke-GraphApiRequest -Method 'GET' -Uri ('https://graph.microsoft.com/v1.0/groups/{0}?$select=id' -f $GroupId)
    if ($group.id -isnot [string] -or $group.id -ine $GroupId) {
        throw 'Membership absence could not be verified against the expected group and device identities.'
    }
    return $false
}

function Get-GraphVerificationPolicy {
    <#
    .SYNOPSIS
        Validates the existing attempt and pause settings for read-back polling.
    .DESCRIPTION
        MaxRetryAttempts bounds total reads per verification cycle, including the
        first immediate read. RetryBackoffSeconds is the fixed pause between reads.
        Defaults match the central configuration when running extracted helpers.
    .OUTPUTS
        Dictionary with MaxAttempts (1-20) and IntervalSeconds (0-60).
    #>
    $attempts = if ($null -ne $Script:Config.MaxRetryAttempts) { $Script:Config.MaxRetryAttempts } else { 5 }
    $interval = if ($null -ne $Script:Config.RetryBackoffSeconds) { $Script:Config.RetryBackoffSeconds } else { 3 }
    if ([string]$attempts -notmatch '^[1-9][0-9]?$' -or [int]$attempts -gt 20) {
        throw 'MaxRetryAttempts must be an integer from 1 to 20 for Graph state verification.'
    }
    if ([string]$interval -notmatch '^(0|[1-9][0-9]?)$' -or [int]$interval -gt 60) {
        throw 'RetryBackoffSeconds must be an integer from 0 to 60 for Graph state verification.'
    }
    return @{ MaxAttempts = [int]$attempts; IntervalSeconds = [int]$interval }
}

function Wait-PrimaryUserAssignmentVerification {
    <#
    .SYNOPSIS
        Polls one assignment surface without repeating its mutation.
    .DESCRIPTION
        Stops at the first matching read-back or the configured read count.
        Request and malformed-response errors propagate immediately; this helper
        does not retry failures or interpret throttling headers. No pause follows
        success or the last read, and all reads preserve strict identity matching.
    .PARAMETER Surface
        Autopilot UPN or exclusive ManagedDevice primary-user relationship.
    .PARAMETER DeviceId
        Identity for the selected assignment surface.
    .PARAMETER User
        Explicitly selected target identity.
    .PARAMETER MaxAttempts
        Total read-back attempts including the immediate first read.
    .PARAMETER IntervalSeconds
        Fixed pause between unsuccessful reads; zero is useful for tests.
    .OUTPUTS
        Dictionary containing Confirmed and the number of Attempts performed.
    #>
    param(
        [Parameter(Mandatory)][ValidateSet('Autopilot', 'ManagedDevice')][string]$Surface,
        [Parameter(Mandatory)][ValidateNotNullOrEmpty()][string]$DeviceId,
        [Parameter(Mandatory)]$User,
        [Parameter(Mandatory)][ValidateRange(1, 20)][int]$MaxAttempts,
        [Parameter(Mandatory)][ValidateRange(0, 60)][int]$IntervalSeconds
    )
    for ($attempt = 1; $attempt -le $MaxAttempts; $attempt++) {
        if ($Surface -eq 'Autopilot') {
            $observed = Get-LiveAutopilotDeviceById -AutopilotDeviceId $DeviceId
            if ($observed.id -isnot [string] -or $observed.id -ine $DeviceId) { throw 'Primary-user verification returned a missing or unexpected Autopilot identity.' }
            $confirmed = -not [string]::IsNullOrWhiteSpace([string]$User.UserPrincipalName) -and
            [string]$observed.userPrincipalName -ieq [string]$User.UserPrincipalName
        }
        else {
            $observedUsers = @(Get-LiveManagedDevicePrimaryUsers -ManagedDeviceId $DeviceId)
            $confirmed = Test-ManagedDevicePrimaryUserMatch -Users $observedUsers -User $User
        }
        if ($confirmed) { return @{ Confirmed = $true; Attempts = $attempt } }
        if ($attempt -lt $MaxAttempts -and $IntervalSeconds -gt 0) { Start-Sleep -Seconds $IntervalSeconds }
    }
    return @{ Confirmed = $false; Attempts = $MaxAttempts }
}

function Invoke-LivePrimaryUserAssignment {
    <#
    .SYNOPSIS
        Submit selected-user assignments once and verify each supported assignment surface.
    .PARAMETER Device
        Mutable workflow record with fresh validated device identities.
    .PARAMETER User
        Explicitly selected account revalidated before either assignment.
    .OUTPUTS
        Attempted/submitted/verified evidence with safe errors. Accepted or ambiguous writes
        are not automatically replayed when read-back fails.
    #>
    param(
        [Parameter(Mandatory)]$Device,
        [Parameter(Mandatory)]$User
    )

    $verificationSettings = Get-GraphVerificationPolicy
    $context = Resolve-LiveAutopilotContext -Device $Device

    $assignmentNotes = @()
    $assignmentErrors = @()
    $autopilotAssigned = $false
    $autopilotSubmitted = $false
    $autopilotAttempted = $false
    $managedDeviceAttempted = $false
    $managedDeviceAssigned = $false
    $managedDeviceConfirmed = $false
    $resolvedUser = if ($User.Id) { $User } else { Resolve-LiveDirectoryUserRecord -User $User }
    # The fresh serial search above returns the complete Autopilot record, including its assigned
    # user. When it already shows the selected user, the write and its read-back are skipped.
    $autopilotAlreadyAssigned = $null -ne $context.Autopilot -and [string]$context.Autopilot.id -ieq [string]$Device.AutopilotDeviceId -and
    -not [string]::IsNullOrWhiteSpace([string]$User.UserPrincipalName) -and [string]$context.Autopilot.userPrincipalName -ieq [string]$User.UserPrincipalName

    if ($Device.AutopilotDeviceId -and $autopilotAlreadyAssigned) {
        $autopilotAssigned = $true
        $assignmentNotes += ('Autopilot assigned user already verified as {0}; no update was needed.' -f $User.UserPrincipalName)
    }
    elseif ($Device.AutopilotDeviceId) {
        try {
            $body = @{ userPrincipalName = [string]$User.UserPrincipalName; addressableUserName = if ($User.DisplayName) { [string]$User.DisplayName } else { [string]$User.UserPrincipalName } }
            $autopilotAttempted = $true
            Invoke-GraphApiRequest -Method 'POST' -Uri ('https://graph.microsoft.com/v1.0/deviceManagement/windowsAutopilotDeviceIdentities/{0}/assignUserToDevice' -f $Device.AutopilotDeviceId) -Body $body | Out-Null
            $autopilotSubmitted = $true
            $verification = Wait-PrimaryUserAssignmentVerification -Surface Autopilot -DeviceId $Device.AutopilotDeviceId -User $User -MaxAttempts $verificationSettings.MaxAttempts -IntervalSeconds $verificationSettings.IntervalSeconds
            $autopilotAssigned = $verification.Confirmed
            $assignmentNotes += ('Autopilot verification performed {0} read-back attempts.' -f $verification.Attempts)
            if ($autopilotAssigned) {
                $assignmentNotes += ('Autopilot assigned user verified as {0}.' -f $User.UserPrincipalName)
            }
            else {
                $assignmentNotes += ('Autopilot assigned-user update was submitted but the read-back value did not match {0}.' -f $User.UserPrincipalName)
            }
        }
        catch {
            $assignmentErrors += ('Autopilot user assignment failed: {0}' -f (Get-GraphOperationFailureMessage -RequestError $_))
        }
    }
    else {
        $assignmentNotes += 'Autopilot device identity was not available for assignUserToDevice.'
    }

    if ($Device.ManagedDeviceId) {
        if ($null -eq $resolvedUser -or [string]::IsNullOrWhiteSpace([string]$resolvedUser.Id)) {
            $assignmentNotes += 'Managed-device primary-user association was skipped because the selected user ID could not be resolved.'
        }
        else {
            try {
                $existingUsers = @(Get-LiveManagedDevicePrimaryUsers -ManagedDeviceId $Device.ManagedDeviceId)
                $alreadyAssigned = @($existingUsers | Where-Object {
                        Test-ManagedDevicePrimaryUserMatch -Users @($_) -User $resolvedUser
                    }).Count -gt 0

                if ($alreadyAssigned) {
                    $managedDeviceAssigned = $true
                    $managedDeviceConfirmed = Test-ManagedDevicePrimaryUserMatch -Users $existingUsers -User $resolvedUser
                    $assignmentNotes += if ($managedDeviceConfirmed) {
                        ('Managed-device primary user already verified as {0}.' -f $resolvedUser.UserPrincipalName)
                    }
                    else {
                        'The selected managed-device user is present, but additional primary-user relationships prevent exclusive verification.'
                    }
                }
                else {
                    $body = @{ '@odata.id' = ('https://graph.microsoft.com/v1.0/users/{0}' -f $resolvedUser.Id) }
                    $managedDeviceAttempted = $true
                    Invoke-GraphApiRequest -Method 'POST' -Uri ('https://graph.microsoft.com/v1.0/deviceManagement/managedDevices(''{0}'')/users/$ref' -f $Device.ManagedDeviceId) -Body $body | Out-Null
                    $managedDeviceAssigned = $true

                    $verification = Wait-PrimaryUserAssignmentVerification -Surface ManagedDevice -DeviceId $Device.ManagedDeviceId -User $resolvedUser -MaxAttempts $verificationSettings.MaxAttempts -IntervalSeconds $verificationSettings.IntervalSeconds
                    $managedDeviceConfirmed = $verification.Confirmed
                    $assignmentNotes += ('Managed-device verification performed {0} read-back attempts.' -f $verification.Attempts)

                    if ($managedDeviceConfirmed) {
                        $assignmentNotes += ('Managed-device primary-user relationship updated to include {0}.' -f $resolvedUser.UserPrincipalName)
                    }
                    else {
                        $assignmentNotes += ('Managed-device primary-user update for {0} was submitted and may take several minutes to appear.' -f $resolvedUser.UserPrincipalName)
                    }
                }
            }
            catch {
                $assignmentErrors += ('Managed-device primary-user update failed: {0}' -f (Get-GraphOperationFailureMessage -RequestError $_))
            }
        }
    }
    else {
        $assignmentNotes += 'Managed device record was not available yet, so only the Autopilot user assignment surface was attempted.'
    }

    return [ordered]@{
        User                   = $resolvedUser
        AutopilotAssigned      = $autopilotAssigned
        AutopilotSubmitted     = $autopilotSubmitted
        AutopilotAttempted     = $autopilotAttempted
        ManagedDeviceAttempted = $managedDeviceAttempted
        ManagedDeviceAssigned  = $managedDeviceAssigned
        ManagedDeviceConfirmed = $managedDeviceConfirmed
        AnyAssignmentApplied   = ($autopilotSubmitted -or $autopilotAssigned -or $managedDeviceAssigned)
        Notes                  = @($assignmentNotes)
        Errors                 = @($assignmentErrors)
    }
}

function Invoke-StepResolveAutopilotDevice {
    <#
    .SYNOPSIS
        Resolve the selected serial and associated identities, or offer guarded hash import.
    .PARAMETER Device
        Selected record; successful resolution updates tenant-bound identity context.
    .PARAMETER StepDefinition
        Validated ResolveAutopilotDevice manifest entry.
    .OUTPUTS
        Operation result. Live uses serial-filtered exact matching; Demo remains synthetic.
        Missing/pending imports do not establish verified Autopilot presence.
    #>
    param([Parameter(Mandatory)]$Device, [Parameter(Mandatory)]$StepDefinition)

    if ($Script:Runtime.IsDemoMode) {
        $Device.AutopilotDeviceId = [guid]::NewGuid().Guid
        $Device.ManagedDeviceId = [guid]::NewGuid().Guid
        $Device.AzureAdDeviceId = [guid]::NewGuid().Guid
        $Device.EntraDeviceId = [guid]::NewGuid().Guid
        $Device.IntuneDeviceName = ('DEMO-{0}' -f $Device.Serial)
        return New-OperationResult -ActionName $StepDefinition.ActionName -Success $true -Summary 'Simulated Autopilot lookup completed.' -Notes 'Demo mode created synthetic Autopilot, Intune, and Entra identifiers.' -Data @{ Serial = $Device.Serial; IntuneDeviceName = $Device.IntuneDeviceName }
    }

    $evidence = @{ Serial = $Device.Serial; HandoffRecorded = $false; VerificationAttempts = 0 }
    try {
        $policy = Get-GraphVerificationPolicy
        $context = Resolve-LiveAutopilotContext -Device $Device
        $evidence.VerificationAttempts = 1
        $importHandled = $false
        if ($Script:RuntimeConfig.autopilot.hashImport.enabled -eq $true) {
            $existingImport = Get-AutopilotImportReceipt -Device $Device
            if ($null -eq $context.Autopilot -or $null -ne $existingImport) {
                $importResult = Invoke-AutopilotHashImport -Device $Device
                if ($null -ne $importResult) {
                    $importHandled = $true
                    $evidence.ImportState = $importResult.State
                    if ($importResult.Receipt) {
                        $evidence.ImportId = $importResult.Receipt.ImportId
                        $evidence.AutopilotImportId = $importResult.Receipt.AutopilotImportId
                    }
                    if ($importResult.State -ne 'Complete') {
                        if ($null -ne $importResult.ErrorCode) { $evidence.ImportErrorCode = $importResult.ErrorCode }
                        return New-OperationResult -ActionName $StepDefinition.ActionName -Success $false -CompletionState $importResult.State -Summary $importResult.Summary -Notes 'Recheck step A to resume saved imports without another upload. Registration is not yet verified.' -Data $evidence
                    }
                    $evidence.ImportRegistrationId = $importResult.RegistrationId
                    $context = Resolve-LiveAutopilotContext -Device $Device
                    $evidence.VerificationAttempts++
                }
            }
        }
        if ($null -eq $context.Autopilot -and -not $importHandled) {
            Write-Host (Get-ConfiguredMissingSerialHandoffNote)
            $handoffConfirmed = Read-ValidatedInput -Prompt 'Autopilot serial not found. Has the external upload-guide hand-off been completed? [Y] Yes [N] No' -Default 'N' -Type 'Choice' -Choices @('Y', 'N')
            if ($handoffConfirmed.ToUpper() -ne 'Y') {
                return New-OperationResult -ActionName $StepDefinition.ActionName -Success $false -Summary 'Autopilot serial could not be resolved.' -Notes 'Complete the external upload-guide hand-off before continuing.' -Data $evidence
            }
            $evidence.HandoffRecorded = $true
            # Poll with the single Autopilot serial search; Intune and Entra are read once, after it appears.
            for ($attempt = 1; $attempt -le $policy.MaxAttempts; $attempt++) {
                $foundAutopilot = Resolve-LiveAutopilotDeviceBySerial -Serial $Device.Serial
                $evidence.VerificationAttempts = $attempt
                if ($null -ne $foundAutopilot) {
                    $context = Resolve-LiveAutopilotContext -Device $Device -KnownAutopilotDevice $foundAutopilot
                    break
                }
                if ($attempt -lt $policy.MaxAttempts -and $policy.IntervalSeconds -gt 0) { Start-Sleep -Seconds $policy.IntervalSeconds }
            }
        }
        if ($null -eq $context.Autopilot) {
            return New-OperationResult -ActionName $StepDefinition.ActionName -Success $false -CompletionState 'Submitted' -Summary 'Upload reported, but Autopilot presence is not yet verified.' -Notes 'The bounded fresh lookups found no identity. Leave this step pending and retry lookup after propagation; do not upload again automatically.' -Data $evidence
        }
        if ($context.Autopilot.id -isnot [string] -or [string]::IsNullOrWhiteSpace($context.Autopilot.id) -or $context.Autopilot.serialNumber -ine $Device.Serial) { throw 'Autopilot verification returned an unexpected identity or serial.' }
        $evidence.AutopilotDeviceId = [string]$context.Autopilot.id
        $evidence.ObservedSerial = [string]$context.Autopilot.serialNumber
        $evidence.ManagedDeviceId = $Device.ManagedDeviceId
        $evidence.EntraDeviceId = $Device.EntraDeviceId
        $notes = if ($evidence.HandoffRecorded) { 'A fresh serial lookup verified Autopilot presence after the upload hand-off.' } else { 'Fresh discovery verified the exact serial and Autopilot identity.' }
        return New-OperationResult -ActionName $StepDefinition.ActionName -Success $true -CompletionState 'Verified' -Summary 'Autopilot presence verified by a fresh serial lookup.' -Notes $notes -Data $evidence
    }
    catch {
        if ($_.Exception.Data['AutopilotExpress.HashImportStorageFailure']) { throw }
        return New-OperationResult -ActionName $StepDefinition.ActionName -Success $false -Summary 'Autopilot presence verification failed.' -Notes 'The lookup failed or returned invalid evidence. Review the error in the approved diagnostic context; no absence or completion was inferred.' -Data $evidence
    }
}

function ConvertTo-AutopilotImportReceipt {
    <#
    .SYNOPSIS
        Validates and copies the eight hash-free fields of one import receipt.
    .DESCRIPTION
        IMPORT-RECEIPTS (owner decision 2026-11-03): import evidence lives in the
        device record's append-only ImportSubmissions ledger. Ledger entries add
        RecordedAt and, for migrated files, Source; legacy journal files hold the
        eight receipt fields only. Any other field (for example a hardware hash) is
        refused, so private data never reaches the ledger.
    .PARAMETER Value
        Normalised ledger entry or legacy journal dictionary.
    .PARAMETER AllowLedgerFields
        Accept the ledger-only RecordedAt and Source text fields.
    .OUTPUTS
        Hashtable with exactly SchemaVersion, RecordId, TenantId, Serial, ImportId,
        AutopilotImportId, State and SubmittedAt. Throws when the evidence is malformed.
    #>
    param([Parameter(Mandatory)][AllowNull()]$Value, [switch]$AllowLedgerFields)
    $receiptFields = @('SchemaVersion', 'RecordId', 'TenantId', 'Serial', 'ImportId', 'AutopilotImportId', 'State', 'SubmittedAt')
    $permittedFields = if ($AllowLedgerFields) { $receiptFields + @('RecordedAt', 'Source') } else { $receiptFields }
    if ($Value -isnot [System.Collections.IDictionary] -or
        @($Value.Keys | Where-Object { $_ -cnotin $permittedFields }).Count -or
        @($receiptFields | Where-Object { -not $Value.Contains($_) }).Count -or
        ($Value['SchemaVersion'] -isnot [int] -and $Value['SchemaVersion'] -isnot [long]) -or
        $Value['SchemaVersion'] -ne 1 -or $Value['State'] -isnot [string] -or $Value['State'] -cnotin @('Submitting', 'Accepted')) {
        throw 'The Autopilot import journal is malformed; review it before continuing.'
    }
    $receipt = @{}
    foreach ($field in $receiptFields) {
        if ($field -cne 'SchemaVersion' -and $Value[$field] -isnot [string]) { throw 'The Autopilot import journal contains invalid fields.' }
        $receipt[$field] = $Value[$field]
    }
    foreach ($field in @('RecordedAt', 'Source')) {
        if ($Value.Contains($field) -and $Value[$field] -isnot [string]) { throw 'The Autopilot import journal contains invalid fields.' }
    }
    $receipt.SchemaVersion = [int]$receipt.SchemaVersion
    $guidPattern = '^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$'
    if ($receipt.ImportId -notmatch $guidPattern -or
        ($receipt.AutopilotImportId -ne '' -and $receipt.AutopilotImportId -notmatch $guidPattern) -or
        ($receipt.State -eq 'Accepted' -and $receipt.AutopilotImportId -eq '')) {
        throw 'The Autopilot import journal identifiers are invalid.'
    }
    $null = Get-Date -Date $receipt.SubmittedAt -ErrorAction Stop
    return $receipt
}

function Get-AutopilotImportReceipt {
    <#
    .SYNOPSIS
        Validates ledger ownership before resuming an asynchronous import.
    .DESCRIPTION
        Reads the latest entry of the record's append-only ImportSubmissions ledger.
        Legacy per-record journal files are folded into the ledger at Live startup by
        Import-LegacyAutopilotImportEvidence, so no file is read here.
    .PARAMETER Device
        Selected workflow record whose tenant and serial must remain unchanged.
    .OUTPUTS
        Hash-free eight-field receipt hashtable, or null when no intent was persisted.
    #>
    param([Parameter(Mandatory)][System.Collections.IDictionary]$Device)
    $tenantId = Get-LiveTenantBinding -Device $Device -AllowUnbound
    $latestEntry = @($Device['ImportSubmissions'] | Where-Object { $null -ne $_ }) | Select-Object -Last 1
    if ($null -eq $latestEntry) { return $null }
    $receipt = ConvertTo-AutopilotImportReceipt -Value $latestEntry -AllowLedgerFields
    if ($receipt.RecordId -cne $Device.RecordId -or $receipt.Serial -cne $Device.Serial -or $receipt.TenantId -ine $tenantId) {
        throw 'The Autopilot import journal target changed; no repeat upload is permitted.'
    }
    return $receipt
}

function Save-AutopilotImportLedgerEntry {
    <#
    .SYNOPSIS
        Appends one hash-free import receipt to the record ledger and saves durably.
    .DESCRIPTION
        Each state change (Submitting, then Accepted) is a new ledger entry; earlier
        entries are never rewritten. Save failures are tagged as hash-import storage
        failures so step A stops rather than reporting an unknown upload outcome.
    .PARAMETER Device
        Session record that receives the entry.
    .PARAMETER Receipt
        Validated eight-field receipt; it is copied, never stored by reference.
    .OUTPUTS
        None. Throws when the entry cannot be saved.
    #>
    param(
        [Parameter(Mandatory)][System.Collections.IDictionary]$Device,
        [Parameter(Mandatory)][hashtable]$Receipt
    )
    $entry = $Receipt.Clone()
    $entry.RecordedAt = Get-Date -Format o
    try { Save-DeviceLedgerEntry -Device $Device -LedgerName 'ImportSubmissions' -Entry $entry }
    catch { $_.Exception.Data['AutopilotExpress.HashImportStorageFailure'] = $true; throw }
}

function Invoke-AutopilotHashImport {
    <#
    .SYNOPSIS
        Submits a selected hash once and resumes by reading durable import state.
    .DESCRIPTION
        Persists a hash-free intent before POST. Unknown outcomes reconcile by
        client import ID; they never trigger another POST. Complete import state
        still requires a separate fresh Autopilot identity lookup by the caller.
    .PARAMETER Device
        Current selected workflow, guarded against tenant and serial changes.
    .OUTPUTS
        Import outcome dictionary, or null when the import option is declined.
    #>
    param([Parameter(Mandatory)]$Device)
    if ($Script:Runtime.IsDemoMode) { throw 'Demo must not import hardware hashes.' }
    $receipt = Get-AutopilotImportReceipt -Device $Device
    if ($null -eq $receipt) {
        $choice = Read-ValidatedInput -Prompt 'Import a hardware-hash CSV for this missing device? [Y] Yes [N] No' -Default 'N' -Type Choice -Choices @('Y', 'N')
        if ($choice -ine 'Y') { return $null }
        $row = Select-AutopilotHashRow -Serial $Device.Serial
        if ($null -eq $row) { return @{ State = 'Submitted'; Summary = 'Hardware-hash file selection cancelled; no upload was sent.' } }
        $previewTenantId = Get-LiveTenantBinding -Device $Device -AllowUnbound
        Write-Host ('Selected CSV row: Serial={0}; tenant={1}. Hash encoding is valid, not proof of ownership.' -f $row.Serial, $previewTenantId)
        $confirmed = Read-ValidatedInput -Prompt 'Upload this selected serial and hardware hash? [Y] Yes [N] No' -Default 'N' -Type Choice -Choices @('Y', 'N')
        if ($confirmed -ine 'Y') { return @{ State = 'Submitted'; Summary = 'Hardware-hash upload declined; no upload was sent.' } }
        $tenantId = Get-LiveTenantBinding -Device $Device -AllowUnbound
        if ($tenantId -ine $previewTenantId -or $row.Serial -ine $Device.Serial) { throw 'The selected import target changed after confirmation.' }
        if ($null -ne (Resolve-LiveAutopilotDeviceBySerial -Serial $Device.Serial)) {
            return @{ State = 'Complete'; Summary = 'Autopilot presence changed during selection; no upload was needed.' }
        }
        $receipt = @{ SchemaVersion = 1; RecordId = $Device.RecordId; TenantId = $tenantId; Serial = $Device.Serial; ImportId = [guid]::NewGuid().Guid; AutopilotImportId = ''; State = 'Submitting'; SubmittedAt = Get-Date -Format o }
        Save-AutopilotImportLedgerEntry -Device $Device -Receipt $receipt
        $body = @{ importedWindowsAutopilotDeviceIdentities = @(@{ serialNumber = $Device.Serial; hardwareIdentifier = $row.HardwareIdentifier; importId = $receipt.ImportId }) }
        if ($Device.SiteCode -and $Device.DeviceType) { $body.importedWindowsAutopilotDeviceIdentities[0].groupTag = '{0}-{1}' -f $Device.SiteCode, ($Device.DeviceType -replace '\s', '') }
        $response = Invoke-GraphApiRequest -Method POST -Uri 'https://graph.microsoft.com/v1.0/deviceManagement/importedWindowsAutopilotDeviceIdentities/import' -Body $body
        if ($response.value -isnot [array] -or $response.value.Count -ne 1 -or
            $response.value[0].serialNumber -ine $Device.Serial -or $response.value[0].id -isnot [string] -or
            $response.value[0].id -notmatch '^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$') {
            throw 'The import response is uncertain; retain the journal and reconcile without another upload.'
        }
        $receipt.AutopilotImportId = $response.value[0].id
        $receipt.State = 'Accepted'
        Save-AutopilotImportLedgerEntry -Device $Device -Receipt $receipt
    }
    if ($receipt.AutopilotImportId -eq '') {
        $imports = Get-GraphDiscoveryCollection -Uri 'https://graph.microsoft.com/v1.0/deviceManagement/importedWindowsAutopilotDeviceIdentities' -RequiredTextProperty serialNumber
        $matchesForImport = @($imports | Where-Object { $_.importId -ceq $receipt.ImportId -and $_.serialNumber -ieq $Device.Serial })
        if ($matchesForImport.Count -gt 1) { throw 'Multiple import identities match the saved intent; review before continuing.' }
        if ($matchesForImport.Count -eq 0) { return @{ State = 'Submitted'; Summary = 'Import outcome is still uncertain; no repeat upload was sent.'; Receipt = $receipt } }
        if ($matchesForImport[0].id -isnot [string] -or $matchesForImport[0].id -notmatch '^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$') { throw 'The reconciled import identity is invalid.' }
        $receipt.AutopilotImportId = $matchesForImport[0].id
        $receipt.State = 'Accepted'
        Save-AutopilotImportLedgerEntry -Device $Device -Receipt $receipt
    }
    $policy = Get-GraphVerificationPolicy
    for ($attempt = 1; $attempt -le $policy.MaxAttempts; $attempt++) {
        $observed = Invoke-GraphApiRequest -Method GET -Uri ('https://graph.microsoft.com/v1.0/deviceManagement/importedWindowsAutopilotDeviceIdentities/{0}' -f $receipt.AutopilotImportId)
        if ($observed.value -is [System.Collections.IDictionary] -or $observed.value -is [pscustomobject]) { $observed = $observed.value }
        if ($observed.id -cne $receipt.AutopilotImportId -or $observed.serialNumber -ine $Device.Serial -or
            $observed.state.deviceImportStatus -notin @('unknown', 'pending', 'partial', 'complete', 'error')) { throw 'Import-state verification returned unexpected evidence.' }
        if ($observed.state.deviceImportStatus -eq 'complete') {
            if ($observed.state.deviceRegistrationId -isnot [string] -or [string]::IsNullOrWhiteSpace($observed.state.deviceRegistrationId)) { throw 'Completed import has no registration identity.' }
            return @{ State = 'Complete'; Summary = 'Hash import completed; verify fresh Autopilot presence next.'; Receipt = $receipt; RegistrationId = $observed.state.deviceRegistrationId }
        }
        if ($observed.state.deviceImportStatus -eq 'error') {
            if ($observed.state.deviceErrorCode -isnot [int] -and $observed.state.deviceErrorCode -isnot [long]) { throw 'The import error code is malformed.' }
            return @{ State = 'Failed'; Summary = 'The Autopilot service rejected the import; review its error code before any new upload.'; Receipt = $receipt; ErrorCode = $observed.state.deviceErrorCode }
        }
        if ($attempt -lt $policy.MaxAttempts -and $policy.IntervalSeconds -gt 0) { Start-Sleep -Seconds $policy.IntervalSeconds }
    }
    return @{ State = 'Submitted'; Summary = 'Hash import is pending; return later to recheck without another upload.'; Receipt = $receipt }
}

function Get-AutopilotHashImportSettings {
    <#
    .SYNOPSIS
        Validates opt-in hash discovery settings without opening files or Graph.
    .OUTPUTS
        Validated settings; older configurations keep the external upload flow.
    #>
    $settings = $Script:RuntimeConfig.autopilot.hashImport
    if ($null -eq $settings) { return @{ enabled = $false } }
    if ($settings -isnot [System.Collections.IDictionary] -or $settings.enabled -isnot [bool] -or $settings.includeRemovableMedia -isnot [bool]) {
        throw 'autopilot.hashImport requires Boolean enabled and includeRemovableMedia settings.'
    }
    foreach ($field in @('searchDirectories', 'filenamePrefixes', 'removableSubdirectories')) {
        if ($settings[$field] -isnot [array]) { throw ('hashImport.{0} must be an array.' -f $field) }
        foreach ($entry in $settings[$field]) {
            if ($entry -isnot [string] -or $entry -match '[\x00-\x1f]' -or ($field -ne 'removableSubdirectories' -and [string]::IsNullOrWhiteSpace($entry))) {
                throw ('hashImport.{0} contains an invalid entry.' -f $field)
            }
            if ($field -eq 'filenamePrefixes' -and $entry -match '[\\/:*?"<>|]') { throw 'Hash filename prefixes must be literal filename text.' }
            if ($field -eq 'removableSubdirectories' -and $entry -ne '' -and ($entry -match '(^|[\\/])\.\.([\\/]|$)' -or (Split-Path -Path $entry -IsAbsolute))) {
                throw 'Removable subdirectories must remain relative to the drive root.'
            }
        }
    }
    if ($settings.filenamePrefixes.Count -eq 0) { throw 'Configure at least one hash filename prefix.' }
    return $settings
}

function Get-AutopilotHashCandidate {
    <#
    .SYNOPSIS
        Lists bounded filename candidates without reading or uploading hashes.
    .OUTPUTS
        Array of unique full CSV paths, sorted for explicit technician selection.
    #>
    $settings = Get-AutopilotHashImportSettings
    if (-not $settings.enabled) { return , @() }
    $baseDirectory = Split-Path -Parent (Get-RuntimeConfigFilePath)
    $directories = @($settings.searchDirectories | ForEach-Object {
            if (Split-Path -Path $_ -IsAbsolute) { $_ } else { Join-Path $baseDirectory $_ }
        })
    if ($settings.includeRemovableMedia) {
        try {
            foreach ($drive in @(Get-CimInstance -ClassName Win32_LogicalDisk -Filter 'DriveType=2' -ErrorAction Stop)) {
                foreach ($relativePath in $settings.removableSubdirectories) {
                    $root = '{0}\' -f $drive.DeviceID
                    $directories += if ($relativePath -eq '') { $root } else { Join-Path $root $relativePath -ErrorAction Stop }
                }
            }
        }
        catch { Write-Host 'Removable-media discovery is unavailable; use a configured folder or manual path.' }
    }
    $paths = @{}
    foreach ($directory in @($directories | Sort-Object -Unique)) {
        if (-not (Test-Path -LiteralPath $directory -PathType Container)) { continue }
        try {
            $files = @(Get-ChildItem -LiteralPath $directory -Filter '*.csv' -File -ErrorAction Stop | Select-Object -First 201)
            if ($files.Count -gt 200) { throw 'Too many CSV files.' }
            foreach ($file in $files) {
                foreach ($prefix in $settings.filenamePrefixes) {
                    if ($file.Name.StartsWith($prefix, [StringComparison]::OrdinalIgnoreCase)) { $paths[$file.FullName] = $true; break }
                }
            }
        }
        catch { Write-Host 'A hash search folder could not be listed safely; use a manual path for that folder.' }
    }
    return , @($paths.Keys | Sort-Object)
}

function Select-AutopilotHashRow {
    <#
    .SYNOPSIS
        Requires explicit file selection and validates the workflow-matched row.
    .PARAMETER Serial
        Selected workflow serial, never inferred from a filename.
    .OUTPUTS
        Validated row dictionary, or null on cancellation. No upload is performed.
    #>
    param([Parameter(Mandatory)][ValidateNotNullOrEmpty()][string]$Serial)
    $paths = Get-AutopilotHashCandidate
    for ($index = 0; $index -lt $paths.Count; $index++) { Write-Host ('{0}. {1}' -f ($index + 1), $paths[$index]) }
    while ($true) {
        $selection = Read-ValidatedInput -Prompt 'CSV file number or manual path ([0] Cancel)' -Default '0'
        if ($selection -eq '0') { return $null }
        $filePath = $selection.Trim().Trim('"')
        if ($selection -match '^[0-9]+$') {
            $selectedIndex = 0
            if (-not [int]::TryParse($selection, [ref]$selectedIndex) -or $selectedIndex -lt 1 -or $selectedIndex -gt $paths.Count) {
                Write-Host 'Select a listed file number, enter a CSV path, or enter 0 to cancel.'
                continue
            }
            $filePath = $paths[$selectedIndex - 1]
        }
        try { return Get-AutopilotHashRow -Path $filePath -Serial $Serial }
        catch { Write-Host ('CSV selection failed: {0} No upload was sent.' -f $_.Exception.Message) }
    }
}

function Get-AutopilotHashRow {
    <#
    .SYNOPSIS
        Reads one serial-matched hardware-hash row without exposing hash data.
    .DESCRIPTION
        Uses the standard CSV parser. Rejects missing headers, duplicate serials,
        invalid encoding and oversized files; encoding is not ownership evidence.
    .PARAMETER Path
        Explicitly selected CSV file, accessed literally rather than as a wildcard.
    .PARAMETER Serial
        Current workflow serial which must match exactly one row, ignoring case.
    .OUTPUTS
        Dictionary containing the matched serial and its base64 hardware identifier.
    #>
    param(
        [Parameter(Mandatory)][ValidateNotNullOrEmpty()][string]$Path,
        [Parameter(Mandatory)][ValidateNotNullOrEmpty()][string]$Serial
    )
    try {
        $file = Get-Item -LiteralPath $Path -ErrorAction Stop
        if ($file.PSIsContainer -or $file.Extension -ine '.csv' -or $file.Length -gt 8388608) {
            throw 'Invalid CSV file.'
        }
        $rows = @(Import-Csv -LiteralPath $file.FullName -ErrorAction Stop)
    }
    catch { throw 'Select a readable CSV file no larger than 8 MiB.' }
    if ($rows.Count -eq 0) { throw 'The hardware-hash CSV contains no device rows.' }
    $headers = @($rows[0].PSObject.Properties.Name)
    if ($headers -notcontains 'Device Serial Number' -or $headers -notcontains 'Hardware Hash') {
        throw 'The CSV requires Device Serial Number and Hardware Hash columns.'
    }
    $seenSerials = @{}
    $selectedRow = $null
    foreach ($row in $rows) {
        $rowSerial = [string]$row.'Device Serial Number'
        if ([string]::IsNullOrWhiteSpace($rowSerial) -or $rowSerial -match '[\x00-\x1f]') {
            throw 'Every CSV row requires a non-empty serial without control characters.'
        }
        $rowSerial = $rowSerial.Trim()
        if ($seenSerials.ContainsKey($rowSerial)) { throw 'The CSV contains duplicate serial rows; select an unambiguous file.' }
        $seenSerials[$rowSerial] = $true
        if ($rowSerial -ieq $Serial.Trim()) { $selectedRow = $row }
    }
    if ($null -eq $selectedRow) { throw 'The selected CSV has no row matching this workflow serial.' }
    $hash = [string]$selectedRow.'Hardware Hash'
    if ([string]::IsNullOrWhiteSpace($hash)) { throw 'The selected serial has no hardware hash.' }
    try { $decoded = [Convert]::FromBase64String($hash) }
    catch { throw 'The selected hardware hash is not valid base64 data.' }
    if ($decoded.Length -eq 0) { throw 'The selected hardware hash contains no data.' }
    return @{ Serial = $Serial.Trim(); HardwareIdentifier = $hash.Trim() }
}

function Wait-ManagedDeviceRemovalVerification {
    <#
    .SYNOPSIS
        Polls the serial search until no managed device remains.
    .DESCRIPTION
        Repeats only validated reads, never deletion. A remaining record,
        including a replacement ID, cannot establish completion.
    .PARAMETER Serial
        Canonical serial whose Intune record must be absent.
    .PARAMETER MaxAttempts
        Total checks including the immediate first read.
    .PARAMETER IntervalSeconds
        Pause only between unsuccessful checks.
    .OUTPUTS
        Dictionary with Confirmed, Attempts and ObservedManagedDeviceId.
    #>
    param(
        [Parameter(Mandatory)][ValidateNotNullOrEmpty()][string]$Serial,
        [Parameter(Mandatory)][ValidateRange(1, 20)][int]$MaxAttempts,
        [Parameter(Mandatory)][ValidateRange(0, 60)][int]$IntervalSeconds
    )
    for ($attempt = 1; $attempt -le $MaxAttempts; $attempt++) {
        $remaining = Resolve-LiveManagedDeviceBySerial -Serial $Serial
        if ($null -eq $remaining) { return @{ Confirmed = $true; Attempts = $attempt; ObservedManagedDeviceId = '' } }
        if ($attempt -lt $MaxAttempts -and $IntervalSeconds -gt 0) { Start-Sleep -Seconds $IntervalSeconds }
    }
    return @{ Confirmed = $false; Attempts = $MaxAttempts; ObservedManagedDeviceId = [string]$remaining.id }
}

function Invoke-StepRemoveAssociatedManagedDevice {
    <#
    .SYNOPSIS
        Confirm one managed-device deletion and verify absence with fresh reads.
    .PARAMETER Device
        Selected record whose target identity is freshly checked before deletion.
    .PARAMETER StepDefinition
        Validated removal manifest entry.
    .OUTPUTS
        Operation result retaining target/submission evidence. Read errors are not absence;
        accepted deletion is never automatically replayed.
    #>
    param([Parameter(Mandatory)]$Device, [Parameter(Mandatory)]$StepDefinition)

    if ($Script:Runtime.IsDemoMode) {
        $Device.ManagedDeviceId = ''
        $Device.IntuneDeviceName = ''
        return New-OperationResult -ActionName $StepDefinition.ActionName -Success $true -Summary 'Simulated Intune device removal completed.' -Notes 'Demo mode cleared the associated Intune device context.' -Data @{ Serial = $Device.Serial }
    }

    $evidence = @{ Serial = $Device.Serial; ManagedDeviceId = $Device.ManagedDeviceId; Submitted = $false; VerificationAttempts = 0 }
    try {
        $policy = Get-GraphVerificationPolicy
        $previousResult = $null
        if ($Device.Steps -is [Collections.IDictionary] -and $Device.Steps.Contains([string]$StepDefinition.Id)) { $previousResult = $Device.Steps[[string]$StepDefinition.Id] }
        if (-not ($previousResult -and ($previousResult.Data.Submitted -eq $true -or $previousResult.Data.DeleteNotFound -eq $true))) {
            $acceptedAttempts = @($Device.AttemptHistory | Where-Object {
                    $_.StepId -ceq [string]$StepDefinition.Id -and $_.ActionName -ceq $StepDefinition.ActionName -and
                    $_.EvidenceKind -ceq 'HandlerOutcome' -and $_.Result.Data.Submitted -eq $true -and $_.Result.IsSimulated -ne $true
                } | Sort-Object Sequence -Descending)
            if ($acceptedAttempts.Count) {
                $boundary = ConvertTo-RecordDate -Value $Device.StartedAt
                if ($boundary -eq [datetime]::MinValue -or -not $Device.RecordId -or -not $Device.TenantId) { throw 'Accepted deletion history cannot be bound to this workflow start and tenant. Review it before any further deletion.' }
                $boundary = $boundary.ToUniversalTime()
                foreach ($recovery in @($Device.RecoveryHistory | Where-Object { $_.Stage -ceq 'RecoveryClosed' })) {
                    $closedAt = ConvertTo-RecordDate -Value $recovery.Timestamp
                    if ($closedAt -eq [datetime]::MinValue) { throw 'Recovery-close history has no usable date. Earlier deletion intent cannot be safely reconciled.' }
                    $closedAt = $closedAt.ToUniversalTime()
                    if ($closedAt -gt $boundary) { $boundary = $closedAt }
                }
                foreach ($attempt in $acceptedAttempts) {
                    if ($attempt.RecordId -cne $Device.RecordId -or $attempt.Serial -ine $Device.Serial -or $attempt.TenantId -ine $Device.TenantId -or $attempt.Result.ActionName -cne $StepDefinition.ActionName) { throw 'Accepted deletion history has conflicting identity context. No further deletion is permitted.' }
                    $attemptAt = ConvertTo-RecordDate -Value $attempt.Timestamp
                    if ($attemptAt -eq [datetime]::MinValue) { throw 'Accepted deletion history has no usable timestamp. Review it before any further deletion.' }
                    $attemptAt = $attemptAt.ToUniversalTime()
                    if ($attemptAt -lt $boundary) { continue }
                    if ($attempt.BuildCycleId -and $attempt.BuildCycleId -cne $Device.BuildCycleId) { continue }
                    $previousResult = $attempt.Result
                    $evidence['RecoveredAttemptId'] = [string]$attempt.AttemptId
                    break
                }
            }
        }
        $recheckOnly = $previousResult -and ($previousResult.Data.Submitted -eq $true -or $previousResult.Data.DeleteNotFound -eq $true)
        if ($recheckOnly) {
            $evidence.ManagedDeviceId = [string]$previousResult.Data.ManagedDeviceId
            $evidence.Submitted = $previousResult.Data.Submitted -eq $true
            if ($previousResult.Data.DeleteNotFound -eq $true) { $evidence['DeleteNotFound'] = $true; $evidence['RequestId'] = $previousResult.Data.RequestId }
            if (-not $evidence.ManagedDeviceId -or $previousResult.Data.Serial -ine $Device.Serial) { throw 'Earlier deletion evidence does not identify this serial and target. Review it before any further action.' }
        }
        if (-not $recheckOnly) {
            $context = Resolve-LiveAutopilotContext -Device $Device
            if (-not $Device.ManagedDeviceId -or $null -eq $context.Managed) {
                if ($null -eq $context -or $null -eq $context.Managed) {
                    # The context refresh has just completed a validated serial search that returned
                    # no managed device; repeating the identical search would add a call, not evidence.
                    $Device.ManagedDeviceId = ''
                    $Device.IntuneDeviceName = ''
                    $evidence.VerificationAttempts = 1
                    $evidence.ObservedManagedDeviceId = ''
                    return New-OperationResult -ActionName $StepDefinition.ActionName -Success $true -CompletionState 'Verified' -Summary 'No associated Intune device was present.' -Notes 'A valid empty serial search confirmed that no deletion was required.' -Data $evidence
                }
            }
            if (-not $Device.ManagedDeviceId) { throw 'Managed-device context did not include a deletion target ID.' }
            $evidence.ManagedDeviceId = [string]$Device.ManagedDeviceId
            $managedDeviceDisplay = if ($Device.IntuneDeviceName) { $Device.IntuneDeviceName } else { $Device.ManagedDeviceId }
            $confirmDelete = Read-ValidatedInput -Prompt ('Delete associated Intune device {0}? [Y] Yes [N] No' -f $managedDeviceDisplay) -Default 'Y' -Type 'Choice' -Choices @('Y', 'N')
            if ($confirmDelete.ToUpper() -ne 'Y') {
                return New-OperationResult -ActionName $StepDefinition.ActionName -Success $false -Summary 'Managed-device deletion cancelled.' -Notes 'The associated Intune device was not deleted.' -Data $evidence
            }
            try {
                if (Get-Command -Name Remove-MgDeviceManagementManagedDevice -ErrorAction SilentlyContinue) {
                    Remove-MgDeviceManagementManagedDevice -ManagedDeviceId $Device.ManagedDeviceId -ErrorAction Stop
                }
                else {
                    Invoke-GraphApiRequest -Method 'DELETE' -Uri ('https://graph.microsoft.com/v1.0/deviceManagement/managedDevices/{0}' -f $Device.ManagedDeviceId) | Out-Null
                }
                $evidence.Submitted = $true
            }
            catch {
                $failure = Get-GraphTransportFailure -RequestError $_
                if ($failure.Status -ne '404') { throw }
                $evidence['DeleteNotFound'] = $true
                $evidence['RequestId'] = $failure.RequestId
            }
        }
        $verification = Wait-ManagedDeviceRemovalVerification -Serial $Device.Serial -MaxAttempts $policy.MaxAttempts -IntervalSeconds $policy.IntervalSeconds
        $evidence.VerificationAttempts = $verification.Attempts
        $evidence.ObservedManagedDeviceId = $verification.ObservedManagedDeviceId
        if (-not $verification.Confirmed) {
            return New-OperationResult -ActionName $StepDefinition.ActionName -Success $false -CompletionState 'Submitted' -Summary 'Managed-device deletion is awaiting verification.' -Notes ('After {0} checks, Intune still returned record {1} for serial {2}; no additional delete was issued.' -f $verification.Attempts, $verification.ObservedManagedDeviceId, $Device.Serial) -Data $evidence
        }
        $Device.ManagedDeviceId = ''
        $Device.IntuneDeviceName = ''
        return New-OperationResult -ActionName $StepDefinition.ActionName -Success $true -CompletionState 'Verified' -Summary 'Associated Intune device deletion verified.' -Notes ('An empty serial search confirmed removal after {0} checks.' -f $verification.Attempts) -Data $evidence
    }
    catch {
        $state = if ($evidence.Submitted) { 'Submitted' } else { 'Failed' }
        return New-OperationResult -ActionName $StepDefinition.ActionName -Success $false -CompletionState $state -Summary 'Managed-device deletion or verification failed.' -Notes (Get-GraphOperationFailureMessage -RequestError $_) -Data $evidence
    }
}

function Wait-AutopilotGroupTagVerification {
    <#
    .SYNOPSIS
        Polls the Autopilot identity until its Group Tag matches exactly.
    .DESCRIPTION
        Performs read-only checks without repeating the tag mutation. Identity
        mismatches and request errors stop immediately. A nonmatching tag at the
        attempt bound remains unverified, including case-only differences.
    .PARAMETER AutopilotDeviceId
        Autopilot identity whose tag must be observed.
    .PARAMETER ExpectedTag
        Enforced site/device-type tag, preserving its configured case.
    .PARAMETER MaxAttempts
        Total reads including the immediate first read.
    .PARAMETER IntervalSeconds
        Pause between unsuccessful reads, never after success or the last read.
    .OUTPUTS
        Dictionary containing Confirmed, Attempts and ObservedGroupTag.
    #>
    param(
        [Parameter(Mandatory)][ValidateNotNullOrEmpty()][string]$AutopilotDeviceId,
        [Parameter(Mandatory)][ValidateNotNullOrEmpty()][string]$ExpectedTag,
        [Parameter(Mandatory)][ValidateRange(1, 20)][int]$MaxAttempts,
        [Parameter(Mandatory)][ValidateRange(0, 60)][int]$IntervalSeconds
    )
    for ($attempt = 1; $attempt -le $MaxAttempts; $attempt++) {
        $observed = Get-LiveAutopilotDeviceById -AutopilotDeviceId $AutopilotDeviceId
        if ($null -eq $observed -or [string]$observed.id -ine $AutopilotDeviceId) {
            throw 'Group Tag read-back returned a missing or unexpected Autopilot identity.'
        }
        $observedTag = [string]$observed.groupTag
        if ($observedTag -ceq $ExpectedTag) {
            return @{ Confirmed = $true; Attempts = $attempt; ObservedGroupTag = $observedTag }
        }
        if ($attempt -lt $MaxAttempts -and $IntervalSeconds -gt 0) { Start-Sleep -Seconds $IntervalSeconds }
    }
    return @{ Confirmed = $false; Attempts = $MaxAttempts; ObservedGroupTag = $observedTag }
}

function Resolve-LiveAutopilotTagContext {
    <#
    .SYNOPSIS
        Refresh only the tenant-bound Autopilot identity needed for a tag action.
    .PARAMETER Device
        Workflow record whose saved identity must still match its serial.
    .OUTPUTS
        Fresh Autopilot identity or null; unrelated Intune and Entra IDs are preserved.
    #>
    param([Parameter(Mandatory)]$Device)
    $tenantId = Get-LiveTenantBinding -Device $Device -AllowUnbound
    $identity = if ($Device.AutopilotDeviceId) {
        Get-LiveAutopilotDeviceById -AutopilotDeviceId $Device.AutopilotDeviceId
    }
    else { Resolve-LiveAutopilotDeviceBySerial -Serial $Device.Serial }
    if ($null -eq $identity) { return $null }
    if ($identity.serialNumber -isnot [string] -or $identity.serialNumber -ine $Device.Serial) {
        throw 'Autopilot tag identity does not match the selected serial; no update was attempted.'
    }
    $Device.TenantId = $tenantId
    $Device.AutopilotDeviceId = [string]$identity.id
    return $identity
}

function Invoke-StepApplyGroupTag {
    <#
    .SYNOPSIS
        Submit the expected Group Tag once or recheck a retained accepted submission.
    .PARAMETER Device
        Selected record with site/type-derived tag and retained submission context.
    .PARAMETER StepDefinition
        Validated tag entry used to locate previous pending evidence.
    .OUTPUTS
        Verified, Submitted, Blocked or failed result. One immediate read follows submission
        or recheck; read failure preserves Submitted without reposting or sleeping.
    #>
    param([Parameter(Mandatory)]$Device, [Parameter(Mandatory)]$StepDefinition)

    $expectedTag = ('{0}-{1}' -f $Device.SiteCode, ($Device.DeviceType -replace '\s', ''))
    if ($Script:Runtime.IsDemoMode) {
        $Device.GroupTag = $expectedTag
        return New-OperationResult -ActionName $StepDefinition.ActionName -Success $true -Summary 'Simulated Group Tag update completed.' -Notes ('Demo mode applied the expected Group Tag {0}.' -f $expectedTag) -Data @{ GroupTag = $expectedTag }
    }

    $previousResult = $null
    if ($Device.Steps -is [System.Collections.IDictionary] -and $Device.Steps.Contains([string]$StepDefinition.Id)) {
        $previousResult = $Device.Steps[[string]$StepDefinition.Id]
    }
    $submitted = $null -ne $previousResult -and $previousResult.Data.Submitted -eq $true
    $submissionTarget = if ($submitted) { [string]$previousResult.Data.AutopilotDeviceId } else { '' }
    $submissionContext = if ($submitted) { $previousResult.Data.AcceptedContext } else { $null }
    try {
        [void](Get-GraphVerificationPolicy)
        if ($submitted -and ($submissionTarget -ine $Device.AutopilotDeviceId -or $previousResult.Data.GroupTag -cne $expectedTag)) {
            return New-OperationResult -ActionName $StepDefinition.ActionName -Success $false -CompletionState Blocked -Summary 'A previously submitted Group Tag update requires review.' -Notes 'The device identity or requested tag changed. Review the earlier submission before authorising another update.' -Data $previousResult.Data
        }
        $autopilotIdentity = Resolve-LiveAutopilotTagContext -Device $Device
        if (-not $Device.AutopilotDeviceId -or $null -eq $autopilotIdentity) {
            return New-OperationResult -ActionName $StepDefinition.ActionName -Success $false -CompletionState 'Blocked' -Summary 'Autopilot device context is required before updating Group Tag.' -Notes 'Run the resolve step first.' -Data @{}
        }
        if ($submitted -and ($submissionTarget -ine $Device.AutopilotDeviceId -or $previousResult.Data.GroupTag -cne $expectedTag)) {
            return New-OperationResult -ActionName $StepDefinition.ActionName -Success $false -CompletionState Blocked -Summary 'A previously submitted Group Tag update requires review.' -Notes 'The device identity or requested tag changed. Review the earlier submission before authorising another update.' -Data $previousResult.Data
        }
        if ($autopilotIdentity.id -ieq $Device.AutopilotDeviceId -and $autopilotIdentity.groupTag -ceq $expectedTag) {
            $Device.GroupTag = $expectedTag
            return New-OperationResult -ActionName $StepDefinition.ActionName -Success $true -CompletionState Verified -Summary 'Group Tag already matches the required state.' -Notes 'Fresh identity lookup verified the exact tag; no additional update was submitted.' -Data @{ AutopilotDeviceId = $Device.AutopilotDeviceId; GroupTag = $expectedTag; ObservedGroupTag = $autopilotIdentity.groupTag; VerificationAttempts = 1; Submitted = $submitted }
        }
        if ($submitted) {
            $evidence = @{ AutopilotDeviceId = $submissionTarget; GroupTag = $expectedTag; ObservedGroupTag = [string]$autopilotIdentity.groupTag; VerificationAttempts = 1; Submitted = $true; AcceptedContext = $submissionContext }
            return New-OperationResult -ActionName $StepDefinition.ActionName -Success $false -CompletionState Submitted -Summary 'Group Tag propagation is still pending.' -Notes 'Continue with another bench device, then recheck this step. No additional update was submitted.' -Data $evidence
        }
        Invoke-GraphApiRequest -Method 'POST' -Uri ('https://graph.microsoft.com/v1.0/deviceManagement/windowsAutopilotDeviceIdentities/{0}/updateDeviceProperties' -f $Device.AutopilotDeviceId) -Body @{ groupTag = $expectedTag } | Out-Null
        $submitted = $true
        $submissionTarget = $Device.AutopilotDeviceId
        $submissionContext = @{ RecordId = [string]$Device.RecordId; BuildCycleId = [string]$Device.BuildCycleId; TenantId = [string]$Device.TenantId; Serial = [string]$Device.Serial }
        $verification = Wait-AutopilotGroupTagVerification -AutopilotDeviceId $Device.AutopilotDeviceId -ExpectedTag $expectedTag -MaxAttempts 1 -IntervalSeconds 0
        $evidence = @{ AutopilotDeviceId = $Device.AutopilotDeviceId; GroupTag = $expectedTag; ObservedGroupTag = $verification.ObservedGroupTag; VerificationAttempts = $verification.Attempts; Submitted = $submitted; AcceptedContext = $submissionContext }
        if (-not $verification.Confirmed) {
            return New-OperationResult -ActionName $StepDefinition.ActionName -Success $false -CompletionState 'Submitted' -Summary 'Group Tag update is awaiting read-back verification.' -Notes ('Expected Group Tag {0}, but observed {1}. Continue with another bench device, then recheck this step; no further update will be submitted.' -f $expectedTag, $verification.ObservedGroupTag) -Data $evidence
        }
        $Device.GroupTag = $verification.ObservedGroupTag
        return New-OperationResult -ActionName $StepDefinition.ActionName -Success $true -CompletionState 'Verified' -Summary 'Group Tag update verified.' -Notes ('Observed Group Tag {0} after {1} reads.' -f $expectedTag, $verification.Attempts) -Data $evidence
    }
    catch {
        $state = if ($submitted) { 'Submitted' } else { 'Failed' }
        $summary = if ($submitted) { 'Group Tag update was accepted; verification is unavailable.' } else { 'Group Tag update or prerequisite read failed.' }
        return New-OperationResult -ActionName $StepDefinition.ActionName -Success $false -CompletionState $state -Summary $summary -Notes (Get-GraphOperationFailureMessage -RequestError $_) -Data @{ AutopilotDeviceId = $submissionTarget; GroupTag = if ($submitted -and $previousResult) { $previousResult.Data.GroupTag } else { $expectedTag }; Submitted = $submitted; AcceptedContext = $submissionContext }
    }
}

function Invoke-StepValidateDeploymentProfile {
    <#
    .SYNOPSIS
        Record technician confirmation of the configured deployment profile.
    .DESCRIPTION
        The technician checks the profile in Intune; this step does not read or
        independently verify the assignment through Microsoft Graph.
    .PARAMETER Device
        Selected record with resolved Autopilot identity.
    .PARAMETER StepDefinition
        Validated deployment-profile manifest entry.
    .OUTPUTS
        Read-only operation result; profile name or a non-assigned state alone cannot complete it.
    #>
    param([Parameter(Mandatory)]$Device, [Parameter(Mandatory)]$StepDefinition)

    $profileName = Get-ConfiguredDeploymentProfileDisplayName
    if ($Script:Runtime.IsDemoMode) {
        return New-OperationResult -ActionName $StepDefinition.ActionName -Success $true -Summary 'Simulated deployment-profile validation completed.' -Notes ('Demo mode validated profile {0}.' -f $profileName) -Data @{ DeploymentProfile = $profileName }
    }

    Write-Host ('Validate in Intune that deployment profile "{0}" is assigned to this device.' -f $profileName)
    $confirmed = Read-ValidatedInput -Prompt 'Was the required deployment profile confirmed? [Y] Yes [N] No' -Default 'Y' -Type 'Choice' -Choices @('Y', 'N')
    $isConfirmed = $confirmed.ToUpper() -eq 'Y'
    $completionState = if ($isConfirmed) { 'TechnicianConfirmed' } else { 'Failed' }
    return New-OperationResult -ActionName $StepDefinition.ActionName -Success $isConfirmed -CompletionState $completionState -Summary 'Deployment-profile validation recorded.' -Notes ('Technician confirmation for profile {0}: {1}' -f $profileName, $confirmed.ToUpper()) -Data @{ DeploymentProfile = $profileName }
}

function Wait-GroupMembershipVerification {
    <#
    .SYNOPSIS
        Polls membership presence or absence without repeating a mutation.
    .DESCRIPTION
        Uses the shared read count and delay contract. Read failures propagate;
        only an observed membership state can confirm the requested outcome.
    .PARAMETER GroupId
        Resolved pre-provisioning group object ID.
    .PARAMETER DirectoryObjectId
        Entra device object ID whose direct membership is checked.
    .PARAMETER ExpectedMember
        True for addition, false for removal.
    .PARAMETER MaxAttempts
        Total read-back checks, including the immediate first check.
    .PARAMETER IntervalSeconds
        Pause between mismatches, never after success or the last check.
    .PARAMETER GroupConfirmed
        Passed through to Test-LiveGroupMembership after an accepted write to this group.
    .OUTPUTS
        Dictionary containing Confirmed, Attempts and ObservedMember.
    #>
    param(
        [Parameter(Mandatory)][ValidateNotNullOrEmpty()][string]$GroupId,
        [Parameter(Mandatory)][ValidateNotNullOrEmpty()][string]$DirectoryObjectId,
        [Parameter(Mandatory)][bool]$ExpectedMember,
        [Parameter(Mandatory)][ValidateRange(1, 20)][int]$MaxAttempts,
        [Parameter(Mandatory)][ValidateRange(0, 60)][int]$IntervalSeconds,
        [switch]$GroupConfirmed
    )
    for ($attempt = 1; $attempt -le $MaxAttempts; $attempt++) {
        $observedMember = Test-LiveGroupMembership -GroupId $GroupId -DirectoryObjectId $DirectoryObjectId -GroupConfirmed:$GroupConfirmed
        if ($observedMember -isnot [bool]) { throw 'Membership verification must return an explicit Boolean observation.' }
        if ($observedMember -eq $ExpectedMember) {
            return @{ Confirmed = $true; Attempts = $attempt; ObservedMember = $observedMember }
        }
        if ($attempt -lt $MaxAttempts -and $IntervalSeconds -gt 0) { Start-Sleep -Seconds $IntervalSeconds }
    }
    return @{ Confirmed = $false; Attempts = $MaxAttempts; ObservedMember = $observedMember }
}

function Test-AssignedSecurityGroup {
    <#
    .SYNOPSIS
        Check complete metadata before changing a direct security-group membership.
    .PARAMETER Group
        Fresh group metadata; dynamic, mail-enabled and role-assignable groups are refused.
    .OUTPUTS
        Boolean permission to offer a membership change, not proof of Graph write access.
    #>
    param([Parameter(Mandatory)]$Group)
    return $Group.securityEnabled -is [bool] -and $Group.securityEnabled -and
    $Group.mailEnabled -is [bool] -and -not $Group.mailEnabled -and
    $Group.groupTypes -is [array] -and $Group.groupTypes.Count -eq 0 -and
    ($null -eq $Group.isAssignableToRole -or ($Group.isAssignableToRole -is [bool] -and -not $Group.isAssignableToRole))
}

function Get-LivePreProvisioningConflictGroup {
    <#
    .SYNOPSIS
        Read complete direct memberships and identify other pre-provisioning prefix groups.
    .PARAMETER DirectoryObjectId
        Freshly resolved Entra device object ID.
    .PARAMETER TargetGroup
        Uniquely resolved configured target; never replaced by a discovered membership.
    .PARAMETER Memberships
        Complete fresh membership snapshot from this operation; omit to request one.
    .OUTPUTS
        Array of conflicting groups. Incomplete or limited-information discovery fails closed.
    #>
    param(
        [Parameter(Mandatory)][string]$DirectoryObjectId,
        [Parameter(Mandatory)]$TargetGroup,
        [AllowEmptyCollection()][object[]]$Memberships
    )
    $prefix = [string]$Script:RuntimeConfig.autopilot.preProvisioningGroupPrefix
    if (-not $prefix) {
        $separator = ([string]$TargetGroup.displayName).LastIndexOf('-')
        if ($separator -lt 0) { throw 'Configure autopilot.preProvisioningGroupPrefix before checking related memberships.' }
        $prefix = $TargetGroup.displayName.Substring(0, $separator + 1)
    }
    if (-not ([string]$TargetGroup.displayName).StartsWith($prefix, [StringComparison]::OrdinalIgnoreCase)) { throw 'The configured membership prefix does not include the target group.' }
    if (-not $PSBoundParameters.ContainsKey('Memberships')) {
        $Memberships = Get-GraphDiscoveryCollection -Uri ('https://graph.microsoft.com/v1.0/devices/{0}/memberOf' -f $DirectoryObjectId)
    }
    $rules = $Script:Config.GroupConflictExclusions
    if ($null -eq $rules) {
        $rules = @(@{ match = 'Exact'; value = 'Intune-Autopilot-AllDevices' }) + @(
            @('Intune-Autopilot-All-', 'Intune-Workstation-', 'Intune-Workstations-') | ForEach-Object { @{ match = 'Prefix'; value = $_ } }
        )
    }
    return , @($memberships | Where-Object {
            $excluded = $false
            foreach ($rule in $rules) {
                if (($rule.match -eq 'Prefix' -and ([string]$_.displayName).StartsWith($rule.value, [StringComparison]::OrdinalIgnoreCase)) -or
                    ($rule.match -eq 'Exact' -and $_.displayName -ieq $rule.value)) { $excluded = $true; break }
            }
            $_.'@odata.type' -eq '#microsoft.graph.group' -and $_.id -ine $TargetGroup.id -and
            ([string]$_.displayName).StartsWith($prefix, [StringComparison]::OrdinalIgnoreCase) -and -not $excluded
        } | Sort-Object displayName)
}

function Get-LivePreProvisioningMembershipState {
    <#
    .SYNOPSIS
        Resolve target membership and conflicts from one complete device membership read.
    .PARAMETER DirectoryObjectId
        Fresh validated Entra device object ID.
    .PARAMETER TargetGroup
        Fresh uniquely resolved configured group, including its object ID.
    .OUTPUTS
        ObservedMember Boolean and ConflictGroups array; partial or denied reads throw.
    #>
    param([Parameter(Mandatory)][string]$DirectoryObjectId, [Parameter(Mandatory)]$TargetGroup)
    $memberships = Get-GraphDiscoveryCollection -Uri ('https://graph.microsoft.com/v1.0/devices/{0}/memberOf' -f $DirectoryObjectId)
    return @{
        ObservedMember = @($memberships | Where-Object { $_.id -ieq $TargetGroup.id }).Count -eq 1
        ConflictGroups = Get-LivePreProvisioningConflictGroup -DirectoryObjectId $DirectoryObjectId -TargetGroup $TargetGroup -Memberships $memberships
    }
}

function Resolve-LiveMembershipContext {
    <#
    .SYNOPSIS
        Validate the selected Autopilot and Entra identities without an Intune lookup.
    .PARAMETER Device
        Tenant-bound workflow record whose serial and directory identity must be refreshed.
    .OUTPUTS
        Fresh Entra device or null; unrelated managed-device identity is preserved.
    #>
    param([Parameter(Mandatory)]$Device)
    $candidate = @{}
    foreach ($propertyName in $Device.Keys) { $candidate[$propertyName] = $Device[$propertyName] }
    $autopilot = Resolve-LiveAutopilotTagContext -Device $candidate
    if ($null -eq $autopilot -or [string]::IsNullOrWhiteSpace([string]$autopilot.azureActiveDirectoryDeviceId)) {
        $Device.EntraDeviceId = ''
        return $null
    }
    $directoryDevice = Get-StoredEntraDeviceObject -Device $Device -AzureAdDeviceId $autopilot.azureActiveDirectoryDeviceId
    if ($null -eq $directoryDevice) { $directoryDevice = Resolve-LiveEntraDeviceObject -AzureAdDeviceId $autopilot.azureActiveDirectoryDeviceId }
    $Device.TenantId = $candidate.TenantId
    $Device.AutopilotDeviceId = $candidate.AutopilotDeviceId
    $Device.AzureAdDeviceId = [string]$autopilot.azureActiveDirectoryDeviceId
    $Device.EntraDeviceId = if ($directoryDevice) { [string]$directoryDevice.id } else { '' }
    return $directoryDevice
}

function Invoke-PreProvisioningMembershipChange {
    <#
    .SYNOPSIS
        Applies and verifies one pre-provisioning membership state transition.
    .DESCRIPTION
        Shared by add/remove manifest handlers. Already-correct state is verified
        without a write; otherwise one reference mutation precedes one immediate read.
        Pending propagation returns to bench work without sleeping or replaying writes.
        Failures never become successful outcomes based on message wording.
    .PARAMETER Device
        Mutable dictionary-backed workflow record.
    .PARAMETER StepDefinition
        Manifest action whose result must be recorded.
    .PARAMETER ExpectedMember
        True to add the device, false to remove its membership reference.
    .OUTPUTS
        Operation result with explicit outcome and read-back evidence.
    #>
    param(
        [Parameter(Mandatory)]$Device,
        [Parameter(Mandatory)]$StepDefinition,
        [Parameter(Mandatory)][bool]$ExpectedMember
    )
    $groupName = Get-ConfiguredPreProvisioningGroupDisplayName
    $changeName = if ($ExpectedMember) { 'addition' } else { 'removal' }
    if ($Script:Runtime.IsDemoMode) {
        return New-OperationResult -ActionName $StepDefinition.ActionName -Success $true -Summary ('Simulated pre-provisioning membership {0} completed.' -f $changeName) -Notes ('Demo mode simulated membership state {0} for {1}.' -f $ExpectedMember, $groupName) -Data @{ Group = $groupName; ExpectedMember = $ExpectedMember }
    }
    $evidence = @{ Group = $groupName; ExpectedMember = $ExpectedMember; Submitted = $false; TargetSubmitted = $false; ConflictChanges = @(); VerificationAttempts = 0 }
    $previous = if ($StepDefinition.Id -and $Device.Steps) { $Device.Steps[$StepDefinition.Id] } else { $null }
    if ($previous.Data.Submitted -eq $true) {
        foreach ($propertyName in $previous.Data.Keys) { $evidence[$propertyName] = $previous.Data[$propertyName] }
        $evidence.TargetSubmitted = -not $previous.Data.Contains('TargetSubmitted') -or $previous.Data.TargetSubmitted -eq $true
        $evidence.ConflictChanges = @($previous.Data.ConflictChanges | Where-Object { $null -ne $_ })
    }
    try {
        [void](Get-GraphVerificationPolicy)
        [void](Resolve-LiveMembershipContext -Device $Device)
        if (-not $Device.EntraDeviceId) {
            return New-OperationResult -ActionName $StepDefinition.ActionName -Success $false -CompletionState 'Blocked' -Summary 'Entra device object ID could not be resolved.' -Notes 'Resolve the Autopilot device before changing group membership.' -Data $evidence
        }
        $group = Get-LivePreProvisioningGroup
        if (-not $group.id) { throw 'The pre-provisioning group did not resolve to an object ID.' }
        $evidence.Group = [string]$group.displayName
        $evidence.GroupId = [string]$group.id
        $evidence.DirectoryObjectId = [string]$Device.EntraDeviceId
        if ($previous.Data.Submitted -eq $true) {
            if ($previous.Data.GroupId -ine $group.id -or $previous.Data.DirectoryObjectId -ine $Device.EntraDeviceId -or $previous.Data.ExpectedMember -ne $ExpectedMember) {
                return New-OperationResult -ActionName $StepDefinition.ActionName -Success $false -CompletionState Blocked -Summary 'A previous membership submission targets a different group or device; review it before proceeding.' -Data $previous.Data
            }
        }
        $membershipState = Get-LivePreProvisioningMembershipState -DirectoryObjectId $Device.EntraDeviceId -TargetGroup $group
        $observedMember = $membershipState.ObservedMember
        if ($observedMember -isnot [bool]) { throw 'Membership verification must return an explicit Boolean observation.' }
        $evidence.ObservedMember = $observedMember
        if ($evidence.TargetSubmitted -and $observedMember -ne $ExpectedMember) {
            return New-OperationResult -ActionName $StepDefinition.ActionName -Success $false -CompletionState Submitted -Summary 'Previously accepted membership change is not yet observed; no mutation was replayed.' -Data $evidence
        }
        $conflicts = @($membershipState.ConflictGroups)
        $evidence.ConflictingGroups = @($conflicts | ForEach-Object { @{ Id = $_.id; DisplayName = $_.displayName } })
        if ($observedMember -ne $ExpectedMember -and -not (Test-AssignedSecurityGroup -Group $group)) {
            throw 'Pre-provisioning membership requires an assigned, non-mail-enabled, non-role-assignable security group with complete eligibility metadata.'
        }
        if ($conflicts.Count -gt 0) {
            Write-Host ('Configured target: {0} ({1}); required membership: {2}.' -f $group.displayName, $group.id, $ExpectedMember)
            foreach ($conflict in $conflicts) {
                Write-Host ('Conflicting direct membership: {0} ({1}).' -f $conflict.displayName, $conflict.id)
                if (-not (Test-AssignedSecurityGroup -Group $conflict)) { throw 'A conflicting group cannot be safely changed by this workflow. Resolve it manually; no correction was submitted.' }
                if (@($evidence.ConflictChanges | Where-Object { $_.GroupId -ieq $conflict.id -and $_.Submitted -eq $true }).Count -gt 0) {
                    return New-OperationResult -ActionName $StepDefinition.ActionName -Success $false -CompletionState Submitted -Summary 'A previously accepted conflicting-membership removal is still present; no deletion was replayed.' -Data $evidence
                }
            }
            $confirmation = Read-ValidatedInput -Prompt 'Remove the listed conflicting memberships and continue with the configured target? [Y] Yes [N] No' -Default 'N' -Type Choice -Choices @('Y', 'N')
            if ($confirmation -ine 'Y') {
                return New-OperationResult -ActionName $StepDefinition.ActionName -Success $false -CompletionState Blocked -Summary 'Conflicting group memberships retained; correction was not authorised.' -Data $evidence
            }
            # Submit every authorised removal first, then confirm them all from one membership read.
            foreach ($conflict in $conflicts) {
                Invoke-GraphApiRequest -Method DELETE -Uri ('https://graph.microsoft.com/v1.0/groups/{0}/members/{1}/$ref' -f $conflict.id, $Device.EntraDeviceId) | Out-Null
                $evidence.Submitted = $true
                $evidence.ConflictChanges += @{ GroupId = $conflict.id; DisplayName = $conflict.displayName; Submitted = $true }
            }
            $afterRemoval = Get-LivePreProvisioningMembershipState -DirectoryObjectId $Device.EntraDeviceId -TargetGroup $group
            $remainingConflicts = @($afterRemoval.ConflictGroups)
            if (@($remainingConflicts | Where-Object { $_.id -in @($conflicts.id) }).Count -gt 0) {
                return New-OperationResult -ActionName $StepDefinition.ActionName -Success $false -CompletionState Submitted -Summary 'Conflicting membership removal accepted; absence is not yet verified.' -Data $evidence
            }
            if ($remainingConflicts.Count -gt 0) {
                return New-OperationResult -ActionName $StepDefinition.ActionName -Success $false -CompletionState Submitted -Summary 'Related memberships changed during correction; recheck before proceeding.' -Data $evidence
            }
            $observedMember = $afterRemoval.ObservedMember
            $evidence.ObservedMember = $observedMember
        }
        if ($observedMember -eq $ExpectedMember) {
            $evidence.VerificationAttempts = 1
            return New-OperationResult -ActionName $StepDefinition.ActionName -Success $true -CompletionState 'Verified' -Summary 'Pre-provisioning membership already matches the required state.' -Notes 'Direct membership was read back; no mutation was required.' -Data $evidence
        }
        if ($ExpectedMember) {
            $body = @{ '@odata.id' = ('https://graph.microsoft.com/v1.0/directoryObjects/{0}' -f $Device.EntraDeviceId) }
            Invoke-GraphApiRequest -Method 'POST' -Uri ('https://graph.microsoft.com/v1.0/groups/{0}/members/$ref' -f $group.id) -Body $body | Out-Null
        }
        else {
            Invoke-GraphApiRequest -Method 'DELETE' -Uri ('https://graph.microsoft.com/v1.0/groups/{0}/members/{1}/$ref' -f $group.id, $Device.EntraDeviceId) | Out-Null
        }
        $evidence.Submitted = $true
        $evidence.TargetSubmitted = $true
        $verification = Wait-GroupMembershipVerification -GroupId $group.id -DirectoryObjectId $Device.EntraDeviceId -ExpectedMember $ExpectedMember -MaxAttempts 1 -IntervalSeconds 0 -GroupConfirmed
        $evidence.ObservedMember = $verification.ObservedMember
        $evidence.VerificationAttempts = $verification.Attempts
        $completionState = if ($verification.Confirmed) { 'Verified' } else { 'Submitted' }
        return New-OperationResult -ActionName $StepDefinition.ActionName -Success $verification.Confirmed -CompletionState $completionState -Summary ('Pre-provisioning membership {0}: {1}.' -f $changeName, $completionState) -Notes ('After {0} checks, expected membership {1}; observed {2}.' -f $verification.Attempts, $ExpectedMember, $verification.ObservedMember) -Data $evidence
    }
    catch {
        # The saved group may be the cause (renamed, replaced or deleted); read it afresh next time.
        Clear-PreProvisioningGroupCache
        $state = if ($evidence.Submitted) { 'Submitted' } else { 'Failed' }
        return New-OperationResult -ActionName $StepDefinition.ActionName -Success $false -CompletionState $state -Summary ('Pre-provisioning membership {0} or verification failed.' -f $changeName) -Notes (Get-GraphOperationFailureMessage -RequestError $_) -Data $evidence
    }
}

function Invoke-StepAddPreProvisioningGroup {
    <#
    .SYNOPSIS
        Delegate guarded group addition to the shared membership controller.
    .PARAMETER Device
        Selected record whose directory identity must be freshly validated.
    .PARAMETER StepDefinition
        Validated group-add manifest entry.
    .OUTPUTS
        Membership operation result; HTTP acceptance is not verified membership.
    #>
    param([Parameter(Mandatory)]$Device, [Parameter(Mandatory)]$StepDefinition)

    return Invoke-PreProvisioningMembershipChange -Device $Device -StepDefinition $StepDefinition -ExpectedMember $true
}

function Get-RecoverySubmissionEvidence {
    <#
    .SYNOPSIS
        Find the current recovery cycle's durable unblock evidence without replaying it.
    .PARAMETER Device
        Active recovery record and its append-only attempt history.
    .PARAMETER StepDefinition
        Current semantic unblock action and displayed step ID.
    .OUTPUTS
        Latest matching recovery evidence, or null when no intent has been recorded.
    #>
    param([Parameter(Mandatory)][System.Collections.IDictionary]$Device, [Parameter(Mandatory)]$StepDefinition)

    $startedAt = ConvertTo-RecordDate -Value $Device.RecoveryStartedAt
    if (-not $Device.RecoveryActive -or $startedAt -eq [DateTime]::MinValue -or $startedAt.ToUniversalTime() -gt [DateTime]::UtcNow) {
        throw 'An active recovery with a valid start time is required before an unblock.'
    }
    if (-not $Device.Contains('AttemptHistory')) { return $null }
    Assert-AttemptHistory -Record $Device
    $current = $null
    $previousCycles = @{}
    foreach ($attempt in $Device.AttemptHistory) {
        if ($attempt.EvidenceKind -cnotin @('RecoveryIntent', 'RecoveryAccepted', 'RecoveryAllowedObserved')) { continue }
        $evidenceStart = ConvertTo-RecordDate -Value $attempt.Result.Data.RecoveryStartedAt
        if ($evidenceStart.ToUniversalTime() -ne $startedAt.ToUniversalTime()) {
            $recordedAt = ConvertTo-RecordDate -Value $attempt.Timestamp
            if ($recordedAt.ToUniversalTime() -ge $startedAt.ToUniversalTime()) {
                throw 'Saved recovery evidence has an ambiguous cycle timestamp; preserve it and seek recovery support.'
            }
            $cycleKey = [string]$evidenceStart.ToUniversalTime().Ticks
            if ($attempt.EvidenceKind -ceq 'RecoveryIntent') {
                if ($previousCycles.ContainsKey($cycleKey)) { throw 'Duplicate prior recovery intent requires review; no request was sent.' }
            }
            elseif (-not $previousCycles.ContainsKey($cycleKey) -or $previousCycles[$cycleKey] -cne 'RecoveryIntent') {
                throw 'Prior recovery submission evidence has an invalid sequence; no request was sent.'
            }
            $previousCycles[$cycleKey] = $attempt.EvidenceKind
            continue
        }
        if ($attempt.StepId -cne [string]$StepDefinition.Id -or
            [string]$attempt.Result.Data.AutopilotDeviceId -ine [string]$Device.AutopilotDeviceId) {
            throw 'Saved recovery submission target or step changed; preserve the evidence and seek recovery support.'
        }
        if ($attempt.EvidenceKind -ceq 'RecoveryIntent') {
            if ($null -ne $current) { throw 'Duplicate recovery submission intent requires review; no request was sent.' }
        }
        elseif ($null -eq $current -or $current.Kind -cne 'RecoveryIntent') {
            throw 'Recovery submission evidence has an invalid sequence; no request was sent.'
        }
        $current = @{ Kind = $attempt.EvidenceKind; RecordedAt = $attempt.Timestamp; AutopilotDeviceId = $attempt.Result.Data.AutopilotDeviceId }
    }
    if (@($previousCycles.Values | Where-Object { $_ -ceq 'RecoveryIntent' }).Count -gt 0) {
        throw 'A prior recovery intent has an unknown outcome; preserve it and seek recovery support.'
    }
    return $current
}

function Save-RecoverySubmissionEvidence {
    <#
    .SYNOPSIS
        Append and save intent, accepted response or technician-observed Allowed evidence.
    .PARAMETER Device
        Active session record that owns the append-only attempt history.
    .PARAMETER StepDefinition
        Current recovery unblock action.
    .PARAMETER Kind
        Evidence stage; acceptance and observation each require an existing intent.
    .OUTPUTS
        Saved attempt entry. Throws if identity, ordering or durable storage is invalid.
    #>
    param(
        [Parameter(Mandatory)][System.Collections.IDictionary]$Device,
        [Parameter(Mandatory)]$StepDefinition,
        [Parameter(Mandatory)][ValidateSet('RecoveryIntent', 'RecoveryAccepted', 'RecoveryAllowedObserved')][string]$Kind
    )

    $prior = Get-RecoverySubmissionEvidence -Device $Device -StepDefinition $StepDefinition
    if (($Kind -eq 'RecoveryIntent' -and $null -ne $prior) -or
        ($Kind -ne 'RecoveryIntent' -and ($null -eq $prior -or $prior.Kind -cne 'RecoveryIntent'))) {
        throw 'Recovery submission evidence cannot be appended in this order.'
    }
    if ([string]::IsNullOrWhiteSpace([string]$Device.AutopilotDeviceId) -or
        [string]::IsNullOrWhiteSpace([string]$Device.RecordId) -or
        [string]::IsNullOrWhiteSpace([string]$Device.Serial) -or
        [string]::IsNullOrWhiteSpace([string]$Device.TenantId) -or
        [string]::IsNullOrWhiteSpace([string]$env:USERNAME)) {
        throw 'Recovery submission identity or actor is missing; no request can be recorded.'
    }
    $startedAt = ConvertTo-PersistedDate -Value $Device.RecoveryStartedAt
    $data = @{ RecoveryStartedAt = $startedAt; AutopilotDeviceId = [string]$Device.AutopilotDeviceId }
    $state = switch ($Kind) {
        RecoveryIntent { 'Blocked' }
        RecoveryAccepted { 'Submitted' }
        RecoveryAllowedObserved { 'TechnicianConfirmed' }
    }
    $summary = switch ($Kind) {
        RecoveryIntent { 'Recovery unblock intent recorded before the request.' }
        RecoveryAccepted { 'Recovery unblock response accepted; Intune status remains to be confirmed.' }
        RecoveryAllowedObserved { 'Technician observed Allowed; the earlier request outcome remains unknown.' }
    }
    $result = New-OperationResult -ActionName $StepDefinition.ActionName -Success ($Kind -eq 'RecoveryAllowedObserved') -CompletionState $state -Summary $summary -Data $data
    $entry = @{
        Sequence = @($Device.AttemptHistory | Where-Object { $null -ne $_ }).Count + 1
        AttemptId = [guid]::NewGuid().Guid; StepId = [string]$StepDefinition.Id; ActionName = [string]$StepDefinition.ActionName
        Actor = [string]$env:USERNAME; Timestamp = Get-Date -Format o; Mode = [string]$Script:Runtime.ModeDisplayName
        TenantId = [string]$Device.TenantId; Serial = [string]$Device.Serial; RecordId = [string]$Device.RecordId
        EvidenceKind = $Kind; Result = $result
    }
    Save-DeviceLedgerEntry -Device $Device -LedgerName 'AttemptHistory' -Entry $entry
    return $entry
}

function Invoke-StepClearUserlessEnrollmentStatus {
    <#
    .SYNOPSIS
        Submit an explicitly confirmed userless-enrolment unblock in active recovery mode.
    .PARAMETER Device
        Selected record with current recovery/submission evidence.
    .PARAMETER StepDefinition
        Validated conditional recovery manifest entry.
    .OUTPUTS
        Operation result. Durable intent prevents replay after an interrupted request.
        A technician-observed Allowed status is distinct from an accepted response.
    #>
    param([Parameter(Mandatory)]$Device, [Parameter(Mandatory)]$StepDefinition)

    if ($Script:Runtime.IsDemoMode) {
        return New-OperationResult -ActionName $StepDefinition.ActionName -Success $true -Summary 'Simulated userless-enrolment unblock completed.' -Notes 'Demo mode cleared the userless-enrolment status gate.' -Data @{}
    }

    if ([string]::IsNullOrWhiteSpace([string]$StepDefinition.Id) -or $Device.Steps -isnot [System.Collections.IDictionary]) {
        return New-OperationResult -ActionName $StepDefinition.ActionName -Success $false -CompletionState 'Blocked' -Summary 'Recovery submission evidence is unavailable.' -Notes 'No unblock request was sent. Review the saved recovery record before continuing.' -Data @{ Blocked = $true }
    }
    $previous = $Device.Steps[$StepDefinition.Id]
    if ($previous.CompletionState -eq 'Submitted') {
        return New-OperationResult -ActionName $StepDefinition.ActionName -Success $false -CompletionState 'Blocked' -Summary 'A recovery unblock is already submitted.' -Notes 'No additional request was sent. Use the recovery readiness step after the original two-minute wait; review invalid or earlier-cycle evidence before continuing.' -Data @{ Blocked = $true }
    }
    if ($previous.CompletionState -eq 'TechnicianConfirmed' -and $previous.Data.RecoveryOutcome -eq 'AllowedObserved') {
        return New-OperationResult -ActionName $StepDefinition.ActionName -Success $false -CompletionState 'Blocked' -Summary 'Allowed was already observed; the request outcome remains unknown.' -Notes 'No additional request was sent. Use the recovery readiness step after the two-minute wait from the observation.' -Data @{ Blocked = $true }
    }

    $outcomeMayBeUnknown = $false
    try {
        [void](Get-LiveTenantBinding -Device $Device)
        $prior = Get-RecoverySubmissionEvidence -Device $Device -StepDefinition $StepDefinition
        if ($null -ne $prior) {
            if ($prior.Kind -eq 'RecoveryAccepted') {
                return New-OperationResult -ActionName $StepDefinition.ActionName -Success $false -CompletionState 'Submitted' -Summary 'The saved recovery unblock was accepted earlier.' -Notes 'No additional request was sent. Use the original acceptance time for the two-minute wait.' -Data @{ AutopilotDeviceId = $prior.AutopilotDeviceId; RecoveryOutcome = 'Accepted'; RecoveryRecordedAt = $prior.RecordedAt }
            }
            if ($prior.Kind -eq 'RecoveryAllowedObserved') {
                return New-OperationResult -ActionName $StepDefinition.ActionName -Success $true -CompletionState 'TechnicianConfirmed' -Summary 'Allowed was previously observed in Intune; the request outcome remains unknown.' -Notes 'No additional request was sent. Use the recorded observation time for the two-minute wait.' -Data @{ AutopilotDeviceId = $prior.AutopilotDeviceId; RecoveryOutcome = 'AllowedObserved'; RecoveryRecordedAt = $prior.RecordedAt }
            }
            $outcomeMayBeUnknown = $true
            Write-Host 'The earlier unblock may have reached Intune, but no acceptance was saved. No request will be sent again.'
            Write-Host ('Check Userless Enrollment Status in Intune for Serial={0}; Autopilot device={1}.' -f $Device.Serial, $prior.AutopilotDeviceId)
            $confirmed = Read-ValidatedInput -Prompt 'Does this device show Allowed in Intune? [Y] Yes [N] No' -Default 'N' -Type 'Choice' -Choices @('Y', 'N')
            if ($confirmed -ine 'Y') {
                return New-OperationResult -ActionName $StepDefinition.ActionName -Success $false -CompletionState 'Blocked' -Summary 'The uncertain unblock remains under review.' -Notes 'No request was sent. Preserve the evidence and seek recovery support if Allowed cannot be confirmed.' -Data @{ Blocked = $true; OutcomeUnknown = $true }
            }
            $observed = Save-RecoverySubmissionEvidence -Device $Device -StepDefinition $StepDefinition -Kind 'RecoveryAllowedObserved'
            return New-OperationResult -ActionName $StepDefinition.ActionName -Success $true -CompletionState 'TechnicianConfirmed' -Summary 'Allowed was observed in Intune; the earlier request outcome remains unknown.' -Notes 'No request was resent. Wait two minutes from this observation before confirming recovery; the observation is not an HTTP acceptance.' -Data @{ AutopilotDeviceId = $observed.Result.Data.AutopilotDeviceId; RecoveryOutcome = 'AllowedObserved'; RecoveryRecordedAt = $observed.Timestamp }
        }

        [void](Resolve-LiveAutopilotContext -Device $Device)
        if (-not $Device.AutopilotDeviceId) {
            return New-OperationResult -ActionName $StepDefinition.ActionName -Success $false -Summary 'Autopilot device context is required before clearing Userless Enrolment Status.' -Notes 'Run the resolve step first so the Autopilot device identity is available.' -Data @{}
        }
        [void](Save-RecoverySubmissionEvidence -Device $Device -StepDefinition $StepDefinition -Kind 'RecoveryIntent')
        $outcomeMayBeUnknown = $true
        Invoke-GraphApiRequest -Method 'POST' -Uri ('https://graph.microsoft.com/beta/deviceManagement/windowsAutopilotDeviceIdentities/{0}/allowNextEnrollment' -f $Device.AutopilotDeviceId) | Out-Null
        $accepted = Save-RecoverySubmissionEvidence -Device $Device -StepDefinition $StepDefinition -Kind 'RecoveryAccepted'
        return New-OperationResult -ActionName $StepDefinition.ActionName -Success $false -CompletionState 'Submitted' -Summary 'Userless-enrolment unblock was submitted but cannot be Graph-verified.' -Notes ('Invoked allowNextEnrollment for Autopilot device {0}. Verify Allowed in Intune before retrying Autopilot.' -f $Device.AutopilotDeviceId) -Data @{ AutopilotDeviceId = $Device.AutopilotDeviceId; RecoveryOutcome = 'Accepted'; RecoveryRecordedAt = $accepted.Timestamp }
    }
    catch {
        $detail = Get-GraphOperationFailureMessage -RequestError $_
        if ($outcomeMayBeUnknown) {
            $notes = 'The earlier request may have reached Intune. No automatic replay occurred; select the unblock action to review Allowed, or seek recovery support. {0}' -f $detail
            return New-OperationResult -ActionName $StepDefinition.ActionName -Success $false -Summary 'Recovery unblock outcome or evidence is uncertain.' -Notes $notes -Data @{ AutopilotDeviceId = $Device.AutopilotDeviceId; OutcomeUnknown = $true }
        }
        return New-OperationResult -ActionName $StepDefinition.ActionName -Success $false -Summary 'Failed to prepare the recovery unblock.' -Notes ('No unblock request was sent. {0}' -f $detail) -Data @{ AutopilotDeviceId = $Device.AutopilotDeviceId }
    }
}

function Invoke-StepConfirmRecoveryReadiness {
    <#
    .SYNOPSIS
        Confirms checklist recovery readiness without claiming Graph status proof.
    .DESCRIPTION
        Requires current-cycle unblock evidence, the checklist two-minute wait
        and a valid empty managed-device search. Accepted submissions and
        technician observations must match their durable attempt evidence.
        The technician then checks Allowed and confirms physical reset/reimage.
        No reset is sent remotely. Only successful close-out restarts steps.
    .PARAMETER Device
        Active recovery record with persisted unblock evidence.
    .PARAMETER StepDefinition
        Conditional recovery close-out manifest action.
    .OUTPUTS
        Blocked, Submitted, Failed, TechnicianConfirmed or Simulated result.
    #>
    param([Parameter(Mandatory)]$Device, [Parameter(Mandatory)]$StepDefinition)

    $evidence = @{ Serial = $Device.Serial; ChecklistVersion = '1.4'; ChecklistSteps = @(12); ConfirmationDefault = 'Y' }
    try {
        $unblockStepId = Get-ManifestActionStepId -ActionName 'ClearUserlessEnrollmentStatus'
        $cleanupStepId = Get-ManifestActionStepId -ActionName 'RemoveAssociatedManagedDevice'
        $unblock = $Device.Steps[$unblockStepId]
        $allowedObserved = $null -ne $unblock -and $unblock.CompletionState -eq 'TechnicianConfirmed' -and
        $unblock.Data -is [System.Collections.IDictionary] -and $unblock.Data.RecoveryOutcome -eq 'AllowedObserved'
        if ($null -eq $unblock -or ($unblock.CompletionState -notin @('Submitted', 'Simulated') -and -not $allowedObserved)) {
            return New-OperationResult -ActionName $StepDefinition.ActionName -Success $false -CompletionState 'Blocked' -Summary ('Submit the recovery unblock action {0} first.' -f $unblockStepId) -Notes 'A previous completed recovery is not evidence for this recovery cycle.' -Data $evidence
        }
        if (-not $Script:Runtime.IsDemoMode) {
            $submittedAt = ConvertTo-RecordDate -Value $unblock.Timestamp
            $startedAt = ConvertTo-RecordDate -Value $Device.RecoveryStartedAt
            $now = Get-Date
            $accepted = $unblock.CompletionState -eq 'Submitted' -and
            $unblock.Data -is [System.Collections.IDictionary] -and $unblock.Data.RecoveryOutcome -eq 'Accepted'
            $hasRecoveryAttempts = @($Device.AttemptHistory | Where-Object { $_.EvidenceKind -cin @('RecoveryIntent', 'RecoveryAccepted', 'RecoveryAllowedObserved') }).Count -gt 0
            if ($accepted -or $allowedObserved -or $hasRecoveryAttempts) {
                $savedRecovery = Get-RecoverySubmissionEvidence -Device $Device -StepDefinition @{ Id = $unblockStepId; ActionName = 'ClearUserlessEnrollmentStatus' }
                if ($null -ne $savedRecovery -or $accepted -or $allowedObserved) {
                    $expectedKind = if ($accepted) { 'RecoveryAccepted' } elseif ($allowedObserved) { 'RecoveryAllowedObserved' } else { '' }
                    if ($null -eq $savedRecovery -or $savedRecovery.Kind -cne $expectedKind) {
                        throw 'The recovery outcome does not match saved recovery evidence. Preserve it and seek recovery support.'
                    }
                    $recordedAt = ConvertTo-RecordDate -Value $savedRecovery.RecordedAt
                    $claimedAt = ConvertTo-RecordDate -Value $unblock.Data.RecoveryRecordedAt
                    if ($recordedAt -eq [DateTime]::MinValue -or $claimedAt -eq [DateTime]::MinValue -or
                        $submittedAt.ToUniversalTime() -ne $recordedAt.ToUniversalTime() -or
                        $claimedAt.ToUniversalTime() -ne $recordedAt.ToUniversalTime() -or
                        $unblock.Data.AutopilotDeviceId -ine $savedRecovery.AutopilotDeviceId) {
                        throw 'The recovery outcome does not match saved recovery evidence. Preserve it and seek recovery support.'
                    }
                }
            }
            if ($submittedAt -eq [DateTime]::MinValue -or $startedAt -eq [DateTime]::MinValue -or $submittedAt -lt $startedAt) {
                throw ('Current-cycle unblock timestamp is missing or invalid. Do not submit {0} again; preserve the saved evidence and seek recovery support.' -f $unblockStepId)
            }
            $elapsedSeconds = ($now - $submittedAt).TotalSeconds
            if ($elapsedSeconds -lt 120) {
                return New-OperationResult -ActionName $StepDefinition.ActionName -Success $false -CompletionState 'Blocked' -Summary 'The checklist two-minute wait is not yet complete.' -Notes ('Wait at least two minutes after {0}, then refresh the Autopilot device in Intune and return here.' -f $unblockStepId) -Data $evidence
            }
            $remaining = Resolve-LiveManagedDeviceBySerial -Serial $Device.Serial
            if ($null -ne $remaining) {
                return New-OperationResult -ActionName $StepDefinition.ActionName -Success $false -CompletionState 'Blocked' -Summary 'An associated Intune device still exists.' -Notes ('Use {0} to delete and verify removal before closing recovery. No additional delete was issued.' -f $cleanupStepId) -Data $evidence
            }
        }
        Write-Host 'Checklist step 12: press Reset after the Autopilot failure and reimage using the approved Windows USB guide.'
        Write-Host 'Confirm the associated Intune device is deleted. After the two-minute wait, refresh Windows Autopilot Devices and verify Userless Enrollment Status displays Allowed.'
        Write-Host 'Do not proceed if it displays Not Allowed. Record the error and return to recovery; no remote reset or reimage is performed by this script.'
        $confirmed = Read-ValidatedInput -Prompt 'Have reset/reimage completed and Allowed been confirmed in Intune? [Y] Yes [N] No' -Default 'Y' -Type 'Choice' -Choices @('Y', 'N')
        if ($confirmed.ToUpper() -ne 'Y') {
            return New-OperationResult -ActionName $StepDefinition.ActionName -Success $false -CompletionState 'Submitted' -Summary 'Recovery readiness remains unconfirmed.' -Notes 'Recovery mode and prior step evidence are retained.' -Data $evidence
        }
        $evidence.ManagedDeviceAbsent = $true
        $evidence.AllowedEvidence = if ($Script:Runtime.IsDemoMode) { 'Simulated' } else { 'TechnicianConfirmedInIntune' }
        $evidence.ConfirmedBy = $env:USERNAME
        $state = if ($Script:Runtime.IsDemoMode) { 'Simulated' } else { 'TechnicianConfirmed' }
        return New-OperationResult -ActionName $StepDefinition.ActionName -Success $true -CompletionState $state -Summary ('Recovery readiness confirmed; restart preparation from {0}.' -f $cleanupStepId) -Notes 'Prior results are archived. Recheck deletion, Group Tag, group membership and physical build milestones.' -Data $evidence
    }
    catch {
        return New-OperationResult -ActionName $StepDefinition.ActionName -Success $false -Summary 'Recovery readiness check failed.' -Notes (Get-GraphOperationFailureMessage -RequestError $_) -Data $evidence
    }
}

function Get-RegularTechnicianUsername {
    <#
    .SYNOPSIS
        Map the Windows process login to a presumed regular username.
    .PARAMETER WindowsUsername
        Windows login, not the Graph sign-in; uncertain patterns return empty.
    .OUTPUTS
        Lower-case username only, never a manufactured UPN or directory ID.
    #>
    param([AllowEmptyString()][string]$WindowsUsername = $env:USERNAME)
    $username = $WindowsUsername.Trim().ToLowerInvariant()
    if ($username -match '^ca([0-9]+)$') { return 'e' + $Matches[1] }
    if ($username -match '^ca([a-z]+)$') { return $Matches[1] }
    if ($username -notmatch '^ca' -and $username -match '^[ce][a-z0-9]+$') { return $username }
    return ''
}

function Select-TechnicianDirectoryUser {
    <#
    .SYNOPSIS
        Resolve and positively confirm the technician's regular directory account.
    .DESCRIPTION
        Uses the Windows login only as a search hint. Uncertain names and declined
        candidates return to username entry; zero cancels without assignment.
        Graph failures never trigger an assignment or privileged-account fallback.
    .OUTPUTS
        Revalidated eligible directory user, or null when cancelled.
    #>
    param()
    $query = Get-RegularTechnicianUsername
    Write-Host ('Windows login: {0} | Regular technician search: {1}' -f $env:USERNAME, $query)
    while ($true) {
        if (-not $query) {
            $query = Read-ValidatedInput -Prompt 'Regular technician username/UPN, R recent, S search ([0] Cancel)' -Default '0'
            if ($query -eq '0') { return $null }
        }
        $candidate = $null
        if ($query -ieq 'R') {
            $candidate = Resolve-EligibleDirectoryUser -User (Select-UserFromResults -Users (Get-RecentUsers) -Heading 'Recent technician selections (most recent first)' -PreserveOrder)
        }
        elseif ($query -ieq 'S') {
            $candidate = Select-DirectoryUser -Heading 'Regular technician user search (active C/E accounts only)'
        }
        else {
            $users = if ($Script:Runtime.IsDemoMode) { Search-DemoDirectoryUsers -SearchMode ExactUpn -Query $query }
            else { Search-LiveDirectoryUsers -SearchMode ExactUpn -Query $query }
            $exactUsers = @($users | Where-Object {
                    $_.OnPremisesSamAccountName -ieq $query -or $_.UserPrincipalName -ieq $query -or
                    (Get-UserLocalPart -UserPrincipalName $_.UserPrincipalName) -ieq $query
                })
            $candidate = if ($exactUsers.Count -eq 1) { Resolve-EligibleDirectoryUser -User $exactUsers[0] }
            else { Select-DirectoryUser -Heading 'Regular technician user search (active C/E accounts only)' }
        }
        if ($null -ne $candidate) {
            Write-Host ('Regular technician: {0} <{1}>' -f $candidate.DisplayName, $candidate.UserPrincipalName)
            $confirmed = Read-ValidatedInput -Prompt 'Use this technician? Y yes, N enter another, R recent, S search, 0 cancel' -Default 'N' -Type Choice -Choices @('Y', 'N', 'R', 'S', '0')
            if ($confirmed -ieq 'Y') { Add-RecentUser -User $candidate; return $candidate }
            if ($confirmed -eq '0') { return $null }
            if ($confirmed -in @('R', 'S')) { $query = $confirmed; continue }
        }
        $query = ''
    }
}

function Invoke-StepAssignTechnicianPrimaryUser {
    <#
    .SYNOPSIS
        Preview and confirm the regular technician account before guarded assignment.
    .PARAMETER Device
        Selected record; unresolved previous assignment prevents silent retargeting.
    .PARAMETER StepDefinition
        Validated technician-assignment manifest entry.
    .OUTPUTS
        Operation result with actual account identity and per-surface evidence. Cancellation
        retains submitted data and never invents a successful assignment.
    #>
    param([Parameter(Mandatory)]$Device, [Parameter(Mandatory)]$StepDefinition)

    $previousStep = if ($Device.Steps) { $Device.Steps[$StepDefinition.Id] } else { $null }
    $retainedData = @{}
    if ($previousStep -and $previousStep.Data) { $retainedData = $previousStep.Data }
    $technicianUser = Select-TechnicianDirectoryUser
    if ($null -eq $technicianUser) {
        return New-OperationResult -ActionName $StepDefinition.ActionName -Success $false -CompletionState Blocked -Summary 'Technician account selection was cancelled; no new assignment was submitted.' -Data $retainedData
    }
    $technicianUpn = [string]$technicianUser.UserPrincipalName
    $priorWrite = $retainedData.AutopilotAttempted -or $retainedData.ManagedDeviceAttempted -or $retainedData.AutopilotSubmitted -or $retainedData.AutopilotAssigned -or $retainedData.ManagedDeviceAssigned
    if ($previousStep -and $previousStep.CompletionState -in @('Failed', 'Submitted', 'Blocked') -and $priorWrite -and
        (([string]$retainedData.Technician -ne $technicianUpn) -or ($retainedData.UserId -and $retainedData.UserId -ne $technicianUser.Id))) {
        return New-OperationResult -ActionName $StepDefinition.ActionName -Success $false -CompletionState Blocked -Summary 'An unresolved technician assignment targets a different user; no new assignment was submitted.' -Notes 'Review the retained assignment and both tenant surfaces before changing its target. Cancellation does not erase the original target evidence.' -Data $retainedData
    }
    $Device.TechnicianUserPrincipalName = $technicianUpn
    if ($Script:Runtime.IsDemoMode) {
        return New-OperationResult -ActionName $StepDefinition.ActionName -Success $true -Summary 'Simulated technician primary-user assignment completed.' -Notes ('Demo mode assigned technician {0} on both Autopilot and managed-device surfaces.' -f $technicianUpn) -Data @{ Technician = $technicianUpn; AutopilotAssigned = $true; ManagedDeviceAssigned = $true }
    }

    $assignment = Invoke-LivePrimaryUserAssignment -Device $Device -User $technicianUser
    $evidence = @{
        Technician = $technicianUpn; UserId = [string]$technicianUser.Id
        AutopilotAssigned = [bool]$assignment.AutopilotAssigned; AutopilotSubmitted = [bool]$assignment.AutopilotSubmitted
        AutopilotAttempted = [bool]$assignment.AutopilotAttempted; ManagedDeviceAttempted = [bool]$assignment.ManagedDeviceAttempted
        ManagedDeviceAssigned = [bool]$assignment.ManagedDeviceAssigned; ManagedDeviceConfirmed = [bool]$assignment.ManagedDeviceConfirmed
    }
    if (-not $assignment.AnyAssignmentApplied) {
        $completionState = if ($assignment.Errors.Count -gt 0) { 'Failed' } else { 'Blocked' }
        return New-OperationResult -ActionName $StepDefinition.ActionName -Success $false -CompletionState $completionState -Summary 'No technician primary-user assignment was verified or submitted.' -Notes ((@($assignment.Notes) + @($assignment.Errors)) -join ' ') -Data $evidence
    }

    if ($assignment.Errors.Count -gt 0) {
        return New-OperationResult -ActionName $StepDefinition.ActionName -Success $false -Summary 'Technician primary-user assignment failed.' -Notes ((@($assignment.Notes) + @($assignment.Errors)) -join ' ') -Data $evidence
    }

    if ($assignment.AutopilotAssigned -and $assignment.ManagedDeviceAssigned -and -not $assignment.ManagedDeviceConfirmed) {
        $confirmed = Read-ValidatedInput -Prompt 'Managed-device primary-user update was submitted. Has Intune reflected the technician yet? [Y] Yes [N] No' -Default 'N' -Type 'Choice' -Choices @('Y', 'N')
        $success = $confirmed.ToUpper() -eq 'Y'
        $completionState = if ($success) { 'TechnicianConfirmed' } else { 'Submitted' }
        $summary = if ($success) { 'Technician primary-user assignment confirmed manually, not Graph-verified.' } else { 'Technician primary-user assignment submitted but not yet confirmed.' }
        $notes = @($assignment.Notes)
        $notes += ('Technician confirmation: {0}' -f $confirmed.ToUpper())
        return New-OperationResult -ActionName $StepDefinition.ActionName -Success $success -CompletionState $completionState -Summary $summary -Notes ($notes -join ' ') -Data $evidence
    }

    $success = $assignment.AutopilotAssigned -and $assignment.ManagedDeviceConfirmed
    $completionState = if ($success) { 'Verified' } else { 'Submitted' }
    $summary = if ($success) { 'Technician primary-user assignment verified on both surfaces.' } else { 'Technician primary-user assignment is awaiting complete read-back verification.' }
    return New-OperationResult -ActionName $StepDefinition.ActionName -Success $success -CompletionState $completionState -Summary $summary -Notes (@($assignment.Notes) -join ' ') -Data $evidence
}

function Get-SyncSubmissionLedgerState {
    <#
    .SYNOPSIS
        Read one build cycle's sync evidence from the device record ledger.
    .DESCRIPTION
        SYNC-RECEIPTS (owner decision 2026-11-03): sync evidence lives in the
        device record's append-only SyncSubmissions ledger, not in per-record
        files. Any Accepted entry for the cycle is the receipt and permits
        confirmation only. An Intent without an Accepted entry means the earlier
        outcome is unknown (crash or lost response). Device sync is safe to repeat,
        so the owner-approved policy (2026-11-02) is to resubmit automatically and
        log the uncertainty.
    .PARAMETER Device
        Live session record whose SyncSubmissions ledger is read, never changed.
    .PARAMETER CycleKey
        BuildCycleId of the current cycle, or empty for records without one.
    .PARAMETER Target
        Refreshed RecordId, Serial, ManagedDeviceId and optional TenantId.
    .OUTPUTS
        Dictionary with Receipt (validated evidence or null), IntentExists and IntentAt.
        Throws when an accepted receipt no longer matches the refreshed target.
    #>
    param(
        [Parameter(Mandatory)][System.Collections.IDictionary]$Device,
        [AllowEmptyString()][string]$CycleKey = '',
        [Parameter(Mandatory)][hashtable]$Target
    )
    $state = @{ Receipt = $null; IntentExists = $false; IntentAt = '' }
    $cycleEntries = @($Device['SyncSubmissions'] | Where-Object { $_ -is [System.Collections.IDictionary] -and [string]$_['CycleKey'] -ceq $CycleKey })
    $acceptedEntry = @($cycleEntries | Where-Object { $_['State'] -ceq 'Accepted' }) | Select-Object -Last 1
    if ($null -eq $acceptedEntry) {
        $intentEntry = @($cycleEntries | Where-Object { $_['State'] -ceq 'Intent' }) | Select-Object -Last 1
        if ($null -ne $intentEntry) {
            $state.IntentExists = $true
            $state.IntentAt = if ($intentEntry['IntentAt'] -is [string] -and $intentEntry['IntentAt']) { $intentEntry['IntentAt'] } else { 'unrecorded' }
        }
        return $state
    }
    $evidence = @{}
    foreach ($field in @('RecordId', 'Serial', 'ManagedDeviceId', 'SubmittedAt')) {
        $value = $acceptedEntry[$field]
        if ($value -isnot [string] -or [string]::IsNullOrWhiteSpace($value)) { throw ('Sync receipt {0} must be a non-empty string.' -f $field) }
        $evidence[$field] = $value
    }
    $submittedAt = [DateTimeOffset]::MinValue
    if ($evidence.SubmittedAt -notmatch '\A\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d{7}(Z|[+-]\d{2}:\d{2})\z' -or
        -not [DateTimeOffset]::TryParse($evidence.SubmittedAt, [ref]$submittedAt)) { throw 'Sync receipt SubmittedAt must be an ISO round-trip timestamp.' }
    # An empty ledger TenantId means the original submission had no tenant context.
    if ($acceptedEntry['TenantId'] -is [string] -and $acceptedEntry['TenantId']) { $evidence.TenantId = $acceptedEntry['TenantId'] }
    foreach ($field in @('RecordId', 'Serial', 'ManagedDeviceId')) {
        if ($evidence[$field] -cne $Target[$field]) { throw ('Sync receipt target changed ({0}); no sync or confirmation is permitted. Review the original submission.' -f $field) }
    }
    if ($Target.ContainsKey('TenantId') -and $evidence.TenantId -cne $Target.TenantId) {
        throw 'Sync receipt target changed (TenantId); no sync or confirmation is permitted. Review the original submission.'
    }
    $state.Receipt = $evidence
    return $state
}

function Save-DeviceLedgerEntry {
    <#
    .SYNOPSIS
        Append one submission or recovery-evidence entry and save all records durably.
    .DESCRIPTION
        Shared by sync, import and append-only recovery attempt evidence.
        Step handlers do not receive the record collection, so the active session
        collection ($Script:InventoryRecords) is used. The device must be the same
        object held in that collection; otherwise the save is refused (fail safe), so
        no tenant write is made without durable intent evidence. A failed intent save
        (State Intent or Submitting) restores the previous in-memory ledger, because no
        tenant write follows it; a failed sync/import Accepted save keeps the entry in
        memory. Recovery attempt entries roll back on failure; their saved intent still
        prevents another request if acceptance or observation could not be saved.
    .PARAMETER Device
        Session record that receives the entry.
    .PARAMETER LedgerName
        Record field holding the append-only ledger.
    .PARAMETER Entry
        Validated ledger entry.
    .OUTPUTS
        None. Throws when the record cannot be located or saved.
    #>
    param(
        [Parameter(Mandatory)][System.Collections.IDictionary]$Device,
        [Parameter(Mandatory)][ValidateSet('SyncSubmissions', 'ImportSubmissions', 'AttemptHistory')][string]$LedgerName,
        [Parameter(Mandatory)][hashtable]$Entry
    )
    $session = Get-Variable -Name InventoryRecords -Scope Script -ErrorAction SilentlyContinue
    $sessionRecords = @()
    if ($null -ne $session -and $session.Value -is [System.Collections.IDictionary] -and $null -ne $session.Value['Value']) { $sessionRecords = @($session.Value['Value']) }
    if (-not @($sessionRecords | Where-Object { [object]::ReferenceEquals($_, $Device) }).Count) {
        throw 'Ledger persistence requires the device to belong to the active session records. Reopen the device from the menu and retry.'
    }
    $previousLedger = @($Device[$LedgerName] | Where-Object { $null -ne $_ })
    $Device[$LedgerName] = @($previousLedger) + , $Entry
    try { Write-UserDeviceRecords -Records $session.Value['Value'] }
    catch {
        if ($LedgerName -eq 'AttemptHistory' -or $Entry.State -cin @('Intent', 'Submitting')) { $Device[$LedgerName] = $previousLedger }
        throw
    }
}

function Import-LegacySyncSubmissionEvidence {
    <#
    .SYNOPSIS
        Fold legacy sync receipt and intent files into device records, then delete them.
    .DESCRIPTION
        SYNC-RECEIPTS migration (owner decision 2026-11-03). Each legacy
        sync-submission-<key>.json (receipt) and sync-intent-submission-<key>.json
        (intent) file in the active data folder is matched to its record by RecordId
        and Serial. Matching evidence is appended to that record's SyncSubmissions
        ledger (duplicates are skipped), all records are saved once, and only then are
        the migrated files deleted. Files with interrupted-save artefacts, unreadable
        content or no matching record are kept and logged for review. Idempotent and
        safe to re-run; Demo mode does nothing.
    .PARAMETER Records
        Loaded session records; matched records gain ledger entries in place.
    .OUTPUTS
        Count of legacy files migrated and deleted.
    #>
    param([Parameter(Mandatory)][AllowEmptyCollection()][System.Collections.IEnumerable]$Records)
    if ($Script:Runtime.IsDemoMode) { return 0 }
    Assert-ActiveStorageReservation
    $legacyFiles = @(Get-ChildItem -LiteralPath $Script:Storage.DataPath -File -Filter 'sync-*submission-*.json' -ErrorAction Stop |
            Where-Object { $_.Name -cmatch '\Async-(intent-)?submission-[A-Za-z0-9-]+\.json\z' } |
            Sort-Object -Property @{ Expression = { $_.Name -cnotlike 'sync-intent-*' } }, Name)
    if (-not $legacyFiles.Count) { return 0 }
    $jsonParameters = @{ ErrorAction = 'Stop' }
    if ((Get-Command ConvertFrom-Json).Parameters.ContainsKey('DateKind')) { $jsonParameters.DateKind = 'String' }
    $migratedPaths = [System.Collections.Generic.List[string]]::new()
    $appended = 0
    foreach ($file in $legacyFiles) {
        try {
            Assert-FileWriteRecoveryState -Path $file.FullName
            $isIntent = $file.Name -clike 'sync-intent-*'
            $saved = Get-Content -LiteralPath $file.FullName -Raw -ErrorAction Stop | ConvertFrom-Json @jsonParameters
            if ($saved -isnot [pscustomobject]) { throw 'Legacy sync evidence must be a JSON object.' }
            $values = @{}
            foreach ($field in @('RecordId', 'Serial', 'ManagedDeviceId', 'TenantId', 'SubmittedAt', 'IntentAt')) {
                $property = $saved.PSObject.Properties[$field]
                $values[$field] = if ($null -ne $property -and $property.Value -is [string]) { $property.Value } else { '' }
            }
            $record = @($Records | Where-Object { $_.RecordId -ceq $values.RecordId -and $_.Serial -ceq $values.Serial }) | Select-Object -First 1
            if (-not $values.RecordId -or $null -eq $record) { throw 'No loaded record matches its RecordId and Serial.' }
            $stem = $file.BaseName -creplace '\Async-(intent-)?submission-', ''
            if ($stem -ceq $values.RecordId) { $cycleKey = '' }
            elseif ($stem.StartsWith(('{0}-' -f $values.RecordId), [StringComparison]::Ordinal)) { $cycleKey = $stem.Substring($values.RecordId.Length + 1) }
            else { throw 'File name does not match its RecordId.' }
            $entry = @{ CycleKey = $cycleKey; RecordedAt = (Get-Date -Format o); RecordId = $values.RecordId; Serial = $values.Serial; ManagedDeviceId = $values.ManagedDeviceId; TenantId = $values.TenantId }
            if ($isIntent) {
                $entry.State = 'Intent'
                $entry.IntentAt = $values.IntentAt
                $entry.Source = 'MigratedIntentFile'
                $timestampField = 'IntentAt'
            }
            else {
                if ($values.SubmittedAt -notmatch '\A\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d{7}(Z|[+-]\d{2}:\d{2})\z') { throw 'Receipt SubmittedAt is not an ISO round-trip timestamp.' }
                $entry.State = 'Accepted'
                $entry.SubmittedAt = $values.SubmittedAt
                $entry.Source = 'MigratedReceiptFile'
                $timestampField = 'SubmittedAt'
            }
            $duplicate = @($record['SyncSubmissions'] | Where-Object { $_ -is [System.Collections.IDictionary] -and $_['State'] -ceq $entry.State -and [string]$_['CycleKey'] -ceq $cycleKey -and [string]$_[$timestampField] -ceq $entry[$timestampField] })
            if (-not $duplicate.Count) {
                $record['SyncSubmissions'] = @($record['SyncSubmissions'] | Where-Object { $null -ne $_ }) + , $entry
                $appended++
            }
            $migratedPaths.Add($file.FullName)
        }
        catch { Write-AutopilotExpressLog -Message ('Legacy sync evidence {0} was kept for review: {1}' -f $file.Name, $_.Exception.Message) -Level 'WARN' }
    }
    # Records are saved before any file is deleted, so evidence is never held only in memory.
    if ($appended) { Write-UserDeviceRecords -Records $Records }
    $deleted = 0
    foreach ($path in $migratedPaths) {
        try {
            Remove-Item -LiteralPath $path -ErrorAction Stop
            $deleted++
        }
        catch { Write-AutopilotExpressLog -Message ('Legacy sync evidence was migrated, but {0} could not be deleted: {1}' -f $path, $_.Exception.Message) -Level 'WARN' }
    }
    Write-AutopilotExpressLog -Message ('Legacy sync evidence migration: files={0}; ledger entries added={1}; files deleted={2}; kept for review={3}.' -f $legacyFiles.Count, $appended, $deleted, ($legacyFiles.Count - $migratedPaths.Count)) -Level 'INFO'
    return $deleted
}

function Import-LegacyAutopilotImportEvidence {
    <#
    .SYNOPSIS
        Fold legacy hash-import journal files into device records, then delete them.
    .DESCRIPTION
        IMPORT-RECEIPTS migration (owner decision 2026-11-03), mirroring the sync
        receipt migration. Each legacy autopilot-import-submission-<RecordId>.json in
        the active data folder is validated (eight hash-free fields only), matched to
        its record by RecordId and Serial (and TenantId when the record has one), and
        appended to that record's ImportSubmissions ledger with Source
        MigratedReceiptFile. Duplicates are skipped, all records are saved once, and
        only then are the migrated files deleted. Files with interrupted-save artefacts,
        unreadable or malformed content, or no matching record are kept and logged for
        review. Idempotent and safe to re-run; Demo mode does nothing.
    .PARAMETER Records
        Loaded session records; matched records gain ledger entries in place.
    .OUTPUTS
        Count of legacy files migrated and deleted.
    #>
    param([Parameter(Mandatory)][AllowEmptyCollection()][System.Collections.IEnumerable]$Records)
    if ($Script:Runtime.IsDemoMode) { return 0 }
    Assert-ActiveStorageReservation
    $legacyFiles = @(Get-ChildItem -LiteralPath $Script:Storage.DataPath -File -Filter 'autopilot-import-submission-*.json' -ErrorAction Stop |
            Where-Object { $_.Name -cmatch '\Aautopilot-import-submission-[A-Za-z0-9-]+\.json\z' } | Sort-Object -Property Name)
    if (-not $legacyFiles.Count) { return 0 }
    $jsonParameters = @{ ErrorAction = 'Stop' }
    if ((Get-Command ConvertFrom-Json).Parameters.ContainsKey('DateKind')) { $jsonParameters.DateKind = 'String' }
    $migratedPaths = [System.Collections.Generic.List[string]]::new()
    $appended = 0
    foreach ($file in $legacyFiles) {
        try {
            Assert-FileWriteRecoveryState -Path $file.FullName
            $saved = ConvertTo-NormalisedValue -Value (Get-Content -LiteralPath $file.FullName -Raw -ErrorAction Stop | ConvertFrom-Json @jsonParameters)
            $receipt = ConvertTo-AutopilotImportReceipt -Value $saved
            if ($file.Name -cne ('autopilot-import-submission-{0}.json' -f $receipt.RecordId)) { throw 'File name does not match its RecordId.' }
            $record = @($Records | Where-Object { $_.RecordId -ceq $receipt.RecordId -and $_.Serial -ceq $receipt.Serial }) | Select-Object -First 1
            if ($null -eq $record) { throw 'No loaded record matches its RecordId and Serial.' }
            if ($record['TenantId'] -is [string] -and $record['TenantId'] -and $receipt.TenantId -ine $record['TenantId']) { throw 'The journal tenant does not match its record.' }
            $duplicate = @($record['ImportSubmissions'] | Where-Object { $_ -is [System.Collections.IDictionary] -and $_['State'] -ceq $receipt.State -and $_['ImportId'] -ceq $receipt.ImportId -and $_['AutopilotImportId'] -ceq $receipt.AutopilotImportId })
            if (-not $duplicate.Count) {
                $entry = $receipt.Clone()
                $entry.RecordedAt = Get-Date -Format o
                $entry.Source = 'MigratedReceiptFile'
                $record['ImportSubmissions'] = @($record['ImportSubmissions'] | Where-Object { $null -ne $_ }) + , $entry
                $appended++
            }
            $migratedPaths.Add($file.FullName)
        }
        catch { Write-AutopilotExpressLog -Message ('Legacy import evidence {0} was kept for review: {1}' -f $file.Name, $_.Exception.Message) -Level 'WARN' }
    }
    # Records are saved before any file is deleted, so evidence is never held only in memory.
    if ($appended) { Write-UserDeviceRecords -Records $Records }
    $deleted = 0
    foreach ($path in $migratedPaths) {
        try {
            Remove-Item -LiteralPath $path -ErrorAction Stop
            $deleted++
        }
        catch { Write-AutopilotExpressLog -Message ('Legacy import evidence was migrated, but {0} could not be deleted: {1}' -f $path, $_.Exception.Message) -Level 'WARN' }
    }
    Write-AutopilotExpressLog -Message ('Legacy import evidence migration: files={0}; ledger entries added={1}; files deleted={2}; kept for review={3}.' -f $legacyFiles.Count, $appended, $deleted, ($legacyFiles.Count - $migratedPaths.Count)) -Level 'INFO'
    return $deleted
}

function Read-ApplicationRetryChoice {
    <#
    .SYNOPSIS
        Ask whether a failed application needs a device sync.
    .OUTPUTS
        N for no failures, Y for sync, or 0 to cancel. Enter defaults to N.
    #>
    return Read-ValidatedInput -Prompt 'Are there failed applications that need a device sync? [N] No failures [Y] Sync for failures [0] Cancel' -Default 'N' -Type 'Choice' -Choices @('N', 'Y', '0')
}

function Get-ConfirmedApplicationBaseline {
    <#
    .SYNOPSIS
        Find the current technician-confirmed application baseline for a no-sync outcome.
    .PARAMETER Device
        Selected workflow record with its current step evidence.
    .OUTPUTS
        Baseline step ID and timestamp, or null when the required confirmation is absent.
    #>
    param([Parameter(Mandatory)]$Device)
    if ($Device.Steps -isnot [System.Collections.IDictionary]) { return $null }
    $definitions = @(Get-EnabledManifestSteps | Where-Object { $_.ActionName -eq 'ConfirmApplicationBaseline' })
    if ($definitions.Count -ne 1 -or [string]::IsNullOrWhiteSpace([string]$definitions[0].Id)) { return $null }
    $stepId = [string]$definitions[0].Id
    $baseline = $Device.Steps[$stepId]
    $expectedState = if ($Script:Runtime.IsDemoMode) { 'Simulated' } else { 'TechnicianConfirmed' }
    if ($baseline -isnot [System.Collections.IDictionary] -or $baseline.ActionName -cne 'ConfirmApplicationBaseline' -or
        $baseline.CompletionState -cne $expectedState -or $baseline.Success -isnot [bool] -or -not $baseline.Success -or
        $baseline.IsSimulated -isnot [bool] -or $baseline.IsSimulated -ne [bool]$Script:Runtime.IsDemoMode) { return $null }
    $timestamp = ConvertTo-PersistedDate -Value $baseline.Timestamp
    if (-not $timestamp) { return $null }
    return @{ StepId = $stepId; Timestamp = $timestamp }
}

function Test-ApplicationNoFailureEvidence {
    <#
    .SYNOPSIS
        Match a no-failure outcome to its still-current application baseline.
    .PARAMETER Device
        Selected workflow record containing the current baseline.
    .PARAMETER Data
        Saved no-failure evidence, including its baseline identity and timestamp.
    .OUTPUTS
        Boolean. Stale, missing or mismatched evidence cannot complete the step.
    #>
    param([Parameter(Mandatory)]$Device, [Parameter(Mandatory)][System.Collections.IDictionary]$Data)
    $baseline = Get-ConfirmedApplicationBaseline -Device $Device
    if ($null -eq $baseline -or $Data.NoApplicationFailures -isnot [bool] -or -not $Data.NoApplicationFailures -or
        $Data.SyncRequestedForOutcome -isnot [bool] -or $Data.SyncRequestedForOutcome -or
        $Data.BaselineStepId -cne $baseline.StepId) { return $false }
    $claimedAt = ConvertTo-RecordDate -Value $Data.BaselineConfirmedAt
    $baselineAt = ConvertTo-RecordDate -Value $baseline.Timestamp
    return $claimedAt -ne [DateTime]::MinValue -and $baselineAt -ne [DateTime]::MinValue -and
    $claimedAt.ToUniversalTime() -eq $baselineAt.ToUniversalTime()
}

function Invoke-StepRetryFailedApps {
    <#
    .SYNOPSIS
        Record no failures, or submit sync for a failed application and confirm its outcome.
    .DESCRIPTION
        Enter selects no failures, which requires a current confirmed baseline and
        sends no Graph request. SYNC-RECEIPTS keeps sync evidence in the record.
        An
        Intent entry is saved durably before the POST and an Accepted entry (the
        receipt) immediately after acceptance and before input. Existing receipts
        permit confirmation only. An Intent without a receipt (crash or lost
        response) is resubmitted automatically and logged, because device sync is
        safe to repeat. A receipt persistence failure stops further sync in this
        process.
    .PARAMETER Device
        Session workflow record whose managed-device identity is refreshed before use.
    .PARAMETER StepDefinition
        RetryFailedApplications manifest action.
    .OUTPUTS
        Blocked, Submitted, TechnicianConfirmed, Failed or Simulated.
    #>
    param([Parameter(Mandatory)]$Device, [Parameter(Mandatory)]$StepDefinition)

    $stopVariable = Get-Variable -Name SyncSubmissionPersistenceFailure -Scope Script -ErrorAction SilentlyContinue
    if (-not $Script:Runtime.IsDemoMode -and $null -ne $stopVariable -and $stopVariable.Value) {
        throw 'Further sync is stopped: an accepted submission has an unresolved durable receipt gap. Review tenant state and storage before restarting; do not automatically retry.'
    }
    $choice = Read-ApplicationRetryChoice
    if ($choice -eq '0') {
        return New-OperationResult -ActionName $StepDefinition.ActionName -Success $false -CompletionState Blocked -Summary 'Application sync choice cancelled.' -Notes 'No sync was requested; the previous step evidence is retained.' -Data @{ Blocked = $true }
    }
    if ($choice -ieq 'N') {
        $baseline = Get-ConfirmedApplicationBaseline -Device $Device
        if ($null -eq $baseline) {
            return New-OperationResult -ActionName $StepDefinition.ActionName -Success $false -CompletionState Blocked -Summary 'Confirm the application baseline before recording no failures.' -Notes 'No sync was requested. Complete the application baseline, or choose sync for an actual failure.' -Data @{ Blocked = $true }
        }
        $state = if ($Script:Runtime.IsDemoMode) { 'Simulated' } else { 'TechnicianConfirmed' }
        return New-OperationResult -ActionName $StepDefinition.ActionName -Success $true -CompletionState $state -Summary 'No application failures; no sync was requested.' -Notes 'The technician confirmed the current application baseline. This outcome does not run portal remediation.' -Data @{ NoApplicationFailures = $true; SyncRequestedForOutcome = $false; BaselineStepId = $baseline.StepId; BaselineConfirmedAt = $baseline.Timestamp }
    }
    if ($choice -ine 'Y') { throw 'The application sync choice is invalid; no sync was requested.' }
    if ($Script:Runtime.IsDemoMode) {
        return New-OperationResult -ActionName $StepDefinition.ActionName -Success $true -Summary 'Simulated device sync for an application failure.' -Notes 'Demo mode does not run the named portal remediation or verify application installation.' -Data @{}
    }

    $evidence = @{}
    $accepted = $false
    try {
        [void](Resolve-LiveAutopilotContext -Device $Device)
        if (-not $Device.ManagedDeviceId) {
            return New-OperationResult -ActionName $StepDefinition.ActionName -Success $false -Summary 'Managed device context is required before retrying app installations.' -Notes 'Resolve the device first, or confirm the managed device exists in Intune.' -Data @{}
        }

        foreach ($field in @('RecordId', 'Serial', 'ManagedDeviceId')) {
            if ($Device[$field] -isnot [string] -or [string]::IsNullOrWhiteSpace($Device[$field])) { throw ('Sync target {0} must be a non-empty string.' -f $field) }
            $evidence[$field] = $Device[$field]
        }
        $sessionVariable = Get-Variable -Name GraphSession -Scope Script
        if ($null -ne $sessionVariable -and $sessionVariable.Value.Contains('TenantId')) {
            $tenantId = $sessionVariable.Value['TenantId']
            if ($null -ne $tenantId -and $tenantId -cne '') {
                if ($tenantId -isnot [string] -or [string]::IsNullOrWhiteSpace($tenantId)) { throw 'Sync target TenantId must be a non-empty string when present.' }
                $evidence.TenantId = $tenantId
            }
        }
        if ($evidence.RecordId -cnotmatch '\A[A-Za-z0-9-]+\z') { throw 'Sync target RecordId must contain only letters, digits and hyphens.' }
        Assert-ActiveStorageReservation
        $cycleKey = if ($Device.BuildCycleId) { [string]$Device.BuildCycleId } else { '' }
        $ledger = Get-SyncSubmissionLedgerState -Device $Device -CycleKey $cycleKey -Target $evidence
        if ($null -ne $ledger.Receipt) {
            $evidence = $ledger.Receipt
            $accepted = $true
            $evidence.ReceiptPersisted = $true
        }
        else {
            $ledgerIdentity = @{ CycleKey = $cycleKey; RecordId = $evidence.RecordId; Serial = $evidence.Serial; ManagedDeviceId = $evidence.ManagedDeviceId; TenantId = [string]$evidence.TenantId; Source = 'Live' }
            if ($ledger.IntentExists) {
                $evidence.ResubmittedAfterUncertainIntent = $true
                $evidence.PriorIntentAt = $ledger.IntentAt
                Write-AutopilotExpressLog -Message ('Sync for record {0} has a saved intent ({1}) but no receipt; the earlier outcome is unknown. Resubmitting automatically because device sync is safe to repeat.' -f $Device.RecordId, $ledger.IntentAt) -Level 'WARN'
            }
            else {
                # SYNC-INTENT: durable intent before the tenant write, so a crash or lost
                # response is detectable. Written once per cycle; never rewritten.
                $intentEntry = $ledgerIdentity.Clone()
                $intentEntry.State = 'Intent'
                $intentEntry.IntentAt = Get-Date -Format o
                $intentEntry.RecordedAt = $intentEntry.IntentAt
                Save-DeviceLedgerEntry -Device $Device -LedgerName 'SyncSubmissions' -Entry $intentEntry
            }
            Invoke-GraphApiRequest -Method 'POST' -Uri ('https://graph.microsoft.com/v1.0/deviceManagement/managedDevices/{0}/syncDevice' -f $Device.ManagedDeviceId) | Out-Null
            $accepted = $true
            $evidence.SyncAccepted = $true
            $evidence.SubmittedAt = Get-Date -Format o
            $acceptedEntry = $ledgerIdentity.Clone()
            $acceptedEntry.State = 'Accepted'
            $acceptedEntry.SubmittedAt = $evidence.SubmittedAt
            $acceptedEntry.RecordedAt = Get-Date -Format o
            if ($ledger.IntentExists) { $acceptedEntry.ResubmittedAfterUncertainIntent = $true }
            try {
                Save-DeviceLedgerEntry -Device $Device -LedgerName 'SyncSubmissions' -Entry $acceptedEntry
                $evidence.ReceiptPersisted = $true
            }
            catch {
                $Script:SyncSubmissionPersistenceFailure = $true
                $evidence.ReceiptPersisted = $false
                $evidence.DurableGap = $true
                return New-OperationResult -ActionName $StepDefinition.ActionName -Success $false -CompletionState 'Submitted' -Summary 'Sync was accepted, but durable receipt persistence failed. Further sync is stopped.' -Notes ('Do not automatically retry. Review tenant state and retained storage artefacts; durability across restart is unknown. Detail: {0}' -f $_.Exception.Message) -Data $evidence
            }
        }
        $evidence.SyncAccepted = $true
        $confirmed = Read-ValidatedInput -Prompt 'Was the failed application retry/remediation successful? [Y] Yes [N] No' -Default 'Y' -Type 'Choice' -Choices @('Y', 'N')
        $isConfirmed = $confirmed.ToUpper() -eq 'Y'
        $completionState = if ($isConfirmed) { 'TechnicianConfirmed' } else { 'Submitted' }
        return New-OperationResult -ActionName $StepDefinition.ActionName -Success $isConfirmed -CompletionState $completionState -Summary 'Accepted sync; app outcome recorded separately, not Graph-verified.' -Notes ('Accepted syncDevice for managed device {0} at {1}; technician confirmation {2}. No additional sync was issued for an existing receipt.' -f $evidence.ManagedDeviceId, $evidence.SubmittedAt, $confirmed.ToUpper()) -Data $evidence
    }
    catch {
        $state = if ($accepted) { 'Submitted' } else { 'Failed' }
        $evidence.SyncAccepted = $accepted
        return New-OperationResult -ActionName $StepDefinition.ActionName -Success $false -CompletionState $state -Summary 'Managed-device sync or outcome confirmation did not complete.' -Notes (Get-GraphOperationFailureMessage -RequestError $_) -Data $evidence
    }
}

function Invoke-StepRemovePreProvisioningGroup {
    <#
    .SYNOPSIS
        Delegate membership removal without deleting the group or directory device.
    .PARAMETER Device
        Selected record whose directory identity is freshly validated.
    .PARAMETER StepDefinition
        Validated group-removal manifest entry.
    .OUTPUTS
        Membership operation result; complete fresh absence evidence verifies removal.
    #>
    param([Parameter(Mandatory)]$Device, [Parameter(Mandatory)]$StepDefinition)

    return Invoke-PreProvisioningMembershipChange -Device $Device -StepDefinition $StepDefinition -ExpectedMember $false
}

function Invoke-StepAssignFinalPrimaryUser {
    <#
    .SYNOPSIS
        Select the final user and retain verified or pending assignment evidence separately.
    .PARAMETER Device
        Selected record; current identities and previous submissions constrain assignment.
    .PARAMETER StepDefinition
        Validated final-user manifest entry.
    .OUTPUTS
        Operation result; cancellation does not submit, and acceptance does not prove ownership.
    #>
    param([Parameter(Mandatory)]$Device, [Parameter(Mandatory)]$StepDefinition)

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
        $completionState = if ($assignment.Errors.Count -gt 0) { 'Failed' } else { 'Blocked' }
        return New-OperationResult -ActionName $StepDefinition.ActionName -Success $false -CompletionState $completionState -Summary 'No final primary-user assignment was verified or submitted.' -Notes ((@($assignment.Notes) + @($assignment.Errors)) -join ' ') -Data @{ FinalPrimaryUser = $selectedUser.UserPrincipalName }
    }

    if ($assignment.Errors.Count -gt 0) {
        return New-OperationResult -ActionName $StepDefinition.ActionName -Success $false -Summary 'Final primary-user assignment failed.' -Notes ((@($assignment.Notes) + @($assignment.Errors)) -join ' ') -Data @{ FinalPrimaryUser = $selectedUser.UserPrincipalName; AutopilotAssigned = $assignment.AutopilotAssigned; ManagedDeviceAssigned = $assignment.ManagedDeviceAssigned }
    }

    if ($assignment.AutopilotAssigned -and $assignment.ManagedDeviceAssigned -and -not $assignment.ManagedDeviceConfirmed) {
        $confirmed = Read-ValidatedInput -Prompt 'Managed-device primary-user update was submitted. Has Intune reflected the final user yet? [Y] Yes [N] No' -Default 'Y' -Type 'Choice' -Choices @('Y', 'N')
        $success = $confirmed.ToUpper() -eq 'Y'
        $completionState = if ($success) { 'TechnicianConfirmed' } else { 'Submitted' }
        $summary = if ($success) { 'Final primary-user assignment confirmed by technician, not Graph-verified.' } else { 'Final primary-user assignment submitted but not yet confirmed.' }
        $notes = @($assignment.Notes)
        $notes += ('Technician confirmation: {0}' -f $confirmed.ToUpper())
        return New-OperationResult -ActionName $StepDefinition.ActionName -Success $success -CompletionState $completionState -Summary $summary -Notes ($notes -join ' ') -Data @{ FinalPrimaryUser = $selectedUser.UserPrincipalName; AutopilotAssigned = $assignment.AutopilotAssigned; ManagedDeviceAssigned = $assignment.ManagedDeviceAssigned; ManagedDeviceConfirmed = $assignment.ManagedDeviceConfirmed }
    }

    $success = $assignment.AutopilotAssigned -and $assignment.ManagedDeviceConfirmed
    $completionState = if ($success) { 'Verified' } else { 'Submitted' }
    $summary = if ($success) { 'Final primary-user assignment verified on both surfaces.' } else { 'Final primary-user assignment is awaiting complete read-back verification.' }
    return New-OperationResult -ActionName $StepDefinition.ActionName -Success $success -CompletionState $completionState -Summary $summary -Notes (@($assignment.Notes) -join ' ') -Data @{ FinalPrimaryUser = $selectedUser.UserPrincipalName; AutopilotAssigned = $assignment.AutopilotAssigned; ManagedDeviceAssigned = $assignment.ManagedDeviceAssigned; ManagedDeviceConfirmed = $assignment.ManagedDeviceConfirmed }
}

function Invoke-StepConfirmPhysicalMilestone {
    <#
    .SYNOPSIS
        Guides and records a technician-observed physical milestone.
    .DESCRIPTION
        Instructions follow checklist v1.4 steps 6-10, 13-14 and 17-22. Confirmation
        defaults to Y by operator decision, but never claims Graph verification.
        The standard step writer persists evidence and preserves resume behaviour.
    .PARAMETER Device
        Workflow record for the device being physically prepared.
    .PARAMETER StepDefinition
        Manifest definition for pre-provisioning or post-login device work.
    .OUTPUTS
        TechnicianConfirmed, Submitted or Simulated operation result.
    #>
    param([Parameter(Mandatory)]$Device, [Parameter(Mandatory)]$StepDefinition)

    switch ($StepDefinition.ActionName) {
        'ConfirmImagingAndOobe' {
            $checklistSteps = @(6, 7, 8, 9, 10)
            $instructions = @(
                'Connect the device to the network. For a laptop, use the Dell docking station required by the checklist.',
                'Install Windows 11 using the approved bootable USB guide and allow imaging to restart the device.',
                'Set the correct country/region and keyboard if prompted; skip a second keyboard layout.',
                'At the work or school setup screen, press the Windows key five times.',
                'Choose Pre-provision with Windows Autopilot, then Next. Wait for the deployment-profile screen; validate it in step F before proceeding.'
            )
            $confirmation = 'Has the device reached the Autopilot deployment-profile screen? [Y] Yes [N] No'
        }
        'ConfirmReseal' {
            $checklistSteps = @(13)
            $instructions = @(
                'Wait for preparation and setup to complete successfully.',
                'If setup fails, do not confirm reseal: return to the workflow and record the failure using recovery option X.',
                'At Your device setup is complete, select Reseal and wait for the device to shut down.'
            )
            $confirmation = 'Did successful pre-provisioning finish with reseal and shutdown? [Y] Yes [N] No'
        }
        'ConfirmBootToSignIn' {
            $checklistSteps = @(14)
            $instructions = @(
                'Power up the resealed device and allow Setting up for work or school to finish.',
                'If an error appears at this stage, the checklist directs Continue Anyway. Record any error details for troubleshooting.',
                'Leave the device at the Windows sign-in screen. Do not perform the first sign-in until technician assignment and group removal are complete.'
            )
            $confirmation = 'Is the device now at the Windows sign-in screen? [Y] Yes [N] No'
        }
        'ConfirmFirstSignIn' {
            $checklistSteps = @(17)
            $instructions = @(
                'Confirm technician primary-user assignment and pre-provisioning group removal are complete.',
                'On the new device, sign in for the first time and wait for the Windows desktop to be ready.'
            )
            $confirmation = 'Has the first sign-in completed and reached the Windows desktop? [Y] Yes [N] No'
        }
        'ConfirmApplicationBaseline' {
            $checklistSteps = @(18, 19)
            $instructions = @(
                'Open Company Portal on the new device and check every required application, including applications already installed by the USB image.',
                'Install only one application at a time, in this checklist order:',
                '1. Cortex XDR Windows x64.',
                '2. Office. For a shared device, install Office 2016 Pro Plus to replace the standard version.',
                '3. Microsoft .NET Desktop Runtime 8 8.0.21.35325 (dependency for Dell Command | Update).',
                '4. Dell Command | Update.',
                '5. Microsoft Edge WebView2 Runtime 142.0.3595.53 (dependency for Zenworks Agent).',
                '6. Zenworks Agent.',
                '7. Laptops only: Global Protect.',
                'If an installation fails, leave this milestone incomplete. The checklist directs Intune > Devices > device > Run Remediations > Retry failed app installation.',
                'For a failed application, step M can request device sync; it does not invoke that named remediation. After troubleshooting, return here and verify every required application.',
                'When the baseline is confirmed and no applications have failed, step M records that no sync is needed.'
            )
            $confirmation = 'Have all required applications been checked and installed successfully? [Y] Yes [N] No'
        }
        'ConfirmUpdatesAndShutdown' {
            $checklistSteps = @(20, 21, 22)
            $instructions = @(
                'Run Dell Command | Update on the applicable device and install all required BIOS and driver updates.',
                'Complete any required reboots and recheck for remaining updates.',
                'Follow all other applicable procedures and documentation for this device, including Imprivata or host-name whitelisting where required.',
                'When updates, reboots and required procedures are complete, power off the device before final primary-user assignment.',
                'For a non-Dell device, follow the approved manufacturer procedure rather than attempting to install Dell firmware.'
            )
            $confirmation = 'Are required updates and procedures complete, and is the device powered off? [Y] Yes [N] No'
        }
        default { throw ('Unsupported physical milestone action: {0}' -f $StepDefinition.ActionName) }
    }
    Write-Host ('Device {0}: {1}' -f $Device.Serial, $StepDefinition.DisplayName)
    foreach ($instruction in $instructions) { Write-Host ('- {0}' -f $instruction) }
    $confirmed = Read-ValidatedInput -Prompt $confirmation -Default 'Y' -Type 'Choice' -Choices @('Y', 'N')
    $evidence = @{ Serial = $Device.Serial; ChecklistVersion = '1.4'; ChecklistSteps = $checklistSteps; ConfirmedBy = $env:USERNAME; ConfirmationDefault = 'Y' }
    if ($confirmed.ToUpper() -ne 'Y') {
        return New-OperationResult -ActionName $StepDefinition.ActionName -Success $false -CompletionState 'Submitted' -Summary 'Physical milestone remains incomplete.' -Notes 'No completion was confirmed; return to this step when the device is ready.' -Data $evidence
    }
    $completionState = if ($Script:Runtime.IsDemoMode) { 'Simulated' } else { 'TechnicianConfirmed' }
    return New-OperationResult -ActionName $StepDefinition.ActionName -Success $true -CompletionState $completionState -Summary 'Physical milestone confirmed by the technician.' -Notes 'This records physical observation, not remote Graph verification. Demo confirmations remain simulated.' -Data $evidence
}

function Invoke-AutopilotManifestStep {
    <#
    .SYNOPSIS
        Enforce tenant binding and prerequisites before dispatching a semantic manifest action.
    .PARAMETER Device
        Selected record; handlers own their explicit action confirmations.
    .PARAMETER StepDefinition
        Validated entry; ActionName, not the displayed letter, selects the handler.
    .OUTPUTS
        Operation result, including Blocked when eligibility fails. Unknown actions fail closed;
        recording and guarded persistence of results remain the caller's responsibility.
    #>
    param(
        [Parameter(Mandatory)]$Device,
        [Parameter(Mandatory)]$StepDefinition
    )

    if (-not $Script:Runtime.IsDemoMode) {
        try { $validatedTenant = Get-LiveTenantBinding -Device $Device -AllowUnbound:($StepDefinition.ActionName -eq 'ResolveAutopilotDevice') }
        catch { return New-OperationResult -ActionName $StepDefinition.ActionName -Success $false -CompletionState 'Blocked' -Summary 'Tenant binding refused.' -Notes $_.Exception.Message -Data @{ Blocked = $true } }
    }
    $eligibility = Test-ManifestStepEligibility -Device $Device -StepDefinition $StepDefinition
    if (-not $eligibility.Eligible) {
        $notes = if ($eligibility.MissingStepIds.Count -gt 0) {
            'Complete prerequisite step(s) before this action: {0}.' -f ($eligibility.MissingStepIds -join ', ')
        }
        else {
            'Activate {0} before this action.' -f $eligibility.ActivationRequirement
        }
        return New-OperationResult -ActionName $StepDefinition.ActionName -Success $false -CompletionState 'Blocked' -Summary 'Workflow prerequisite not met.' -Notes $notes -Data @{ Blocked = $true; MissingStepIds = $eligibility.MissingStepIds; ActivationRequirement = $eligibility.ActivationRequirement }
    }

    if (-not $Script:Runtime.IsDemoMode -and $StepDefinition.ActionName -eq 'ResolveAutopilotDevice' -and -not $Device.TenantId) {
        $Device.TenantId = $validatedTenant
    }
    try {
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
            'ConfirmImagingAndOobe' { return Invoke-StepConfirmPhysicalMilestone -Device $Device -StepDefinition $StepDefinition }
            'ConfirmReseal' { return Invoke-StepConfirmPhysicalMilestone -Device $Device -StepDefinition $StepDefinition }
            'ConfirmBootToSignIn' { return Invoke-StepConfirmPhysicalMilestone -Device $Device -StepDefinition $StepDefinition }
            'ConfirmFirstSignIn' { return Invoke-StepConfirmPhysicalMilestone -Device $Device -StepDefinition $StepDefinition }
            'ConfirmApplicationBaseline' { return Invoke-StepConfirmPhysicalMilestone -Device $Device -StepDefinition $StepDefinition }
            'ConfirmUpdatesAndShutdown' { return Invoke-StepConfirmPhysicalMilestone -Device $Device -StepDefinition $StepDefinition }
            'ConfirmRecoveryReadiness' { return Invoke-StepConfirmRecoveryReadiness -Device $Device -StepDefinition $StepDefinition }
            default {
                return New-OperationResult -ActionName $StepDefinition.ActionName -Success $false -Summary 'Manifest action is not yet implemented.' -Notes ('No step handler exists for action {0}.' -f $StepDefinition.ActionName) -Data @{}
            }
        }
    }
    catch {
        if ($_.Exception.Data['AutopilotExpress.HashImportStorageFailure'] -or
            $null -eq $_.Exception.Data['AutopilotExpress.GraphMethod']) { throw }
        $previous = $Device.Steps[$StepDefinition.Id]
        $state = 'Failed'
        $evidence = @{}
        if ($previous.CompletionState -eq 'Submitted') {
            $state = 'Submitted'
            if ($previous.Data -is [System.Collections.IDictionary]) {
                $evidence = ConvertTo-NormalisedValue -Value $previous.Data
            }
        }
        return New-OperationResult -ActionName $StepDefinition.ActionName -Success $false -CompletionState $state -Summary 'Graph evidence could not be obtained; no automatic replay was performed.' -Notes (Get-GraphOperationFailureMessage -RequestError $_) -Data $evidence
    }
}

function Show-ChecklistHandoffGuide {
    <#
    .SYNOPSIS
        Display checklist v1.4 steps 24-26 after final Intune ownership completes.
    .DESCRIPTION
        Provides read-only external handoff guidance. It does not update ZENworks,
        CMDB or device state, collect confirmation, or change completion/dispatch gates.
        The technician performs these actions using the approved external procedures.
    .PARAMETER Device
        Workflow record used only to display device identity and captured Intune name.
    .OUTPUTS
        Host guidance only; no external-system update, confirmation or dispatch certification.
    #>
    param([Parameter(Mandatory)][ValidateNotNullOrEmpty()]$Device)
    Write-Host ''
    Write-Host 'Remaining checklist handoffs (v1.4, steps 24-26)'
    Write-Host ('Device serial: {0}; Configuration Item: {1}; site: {2}' -f $Device.Serial, $Device.ConfigItem, $Device.SiteCode)
    if ($Device.IntuneInventory.IntuneHostName) { Write-Host ('Captured Intune hostname: {0}; Ethernet MAC: {1}' -f $Device.IntuneInventory.IntuneHostName, $Device.IntuneInventory.EthernetMacAddress) }
    elseif ($Device.IntuneDeviceName) { Write-Host ('Cached identity label (not confirmed final hostname): {0}' -f $Device.IntuneDeviceName) }
    $instructions = @(
        '24. ZENworks: find the replaced device under Devices > Device List and use Actions > Copy Relationships to copy its relationships to the new device.',
        'If there is no replaced device, use an existing device at the installation location that performs the same or similar activities as the relationship source.',
        '25. CMDB: find the record by device name or service tag; create a record if neither search finds it.',
        'For a new CMDB record, use the full device name shown in Intune. Use only the numbers from the Configuration Item sticker in the CMDB CI field; this guide does not change the stored CI.',
        'Check Assigned to against the approved recipient: the checklist specifies the assigned caregiver E number or, for a shared device, the Unit/Area Manager. The CLI does not infer roles or select this CMDB recipient.',
        'Check site, the full department or ward name (not an acronym), and Floor-Room with building, floor, room number where displayed, and room name or descriptor.',
        'If the replaced device is being decommissioned or disposed of, link that old device to the new device in the Downstream CI tab.',
        '26. Coordinate installation with the caregiver or manager. When replacing a device for decommissioning or disposal, collect the old device at the same time as installing the new one.',
        'Do not install the replacement until the old device can be collected, and do not leave a device awaiting decommissioning or disposal with the caregiver.',
        'Complete every applicable disposal/decommissioning procedure for the collected device before close of business on the current business day.',
        'Guidance only: no external updates or handoff confirmations are recorded here. Intune workflow completion and bench dispatch do not certify these handoffs or physical deployment.'
    )
    foreach ($instruction in $instructions) { Write-Host ('- {0}' -f $instruction) }
}

function Get-AffectedWorkflowStepId {
    <#
    .SYNOPSIS
        Find the current step and all evidence that depends on it.
    .PARAMETER Device
        Workflow record containing the current step results.
    .PARAMETER RootStepId
        Step whose confirmation or outcome is being replaced.
    .PARAMETER Definitions
        Enabled manifest actions and their declared prerequisites.
    .OUTPUTS
        Step IDs in dependency order, including a no-failure outcome dependent on the baseline.
    #>
    param(
        [Parameter(Mandatory)]$Device,
        [Parameter(Mandatory)][string]$RootStepId,
        [Parameter(Mandatory)][AllowEmptyCollection()][object[]]$Definitions
    )
    $affected = @($RootStepId)
    $baselineIds = @($Definitions | Where-Object { $_.ActionName -eq 'ConfirmApplicationBaseline' } | ForEach-Object { $_.Id })
    do {
        $added = $false
        foreach ($definition in $Definitions) {
            if ($definition.Id -in $affected) { continue }
            $dependsOnAffected = @($definition.PrerequisiteStepIds | Where-Object { $_ -in $affected }).Count -gt 0
            if (-not $dependsOnAffected -and $definition.ActionName -eq 'RetryFailedApplications') {
                $result = $Device.Steps[$definition.Id]
                $dependsOnAffected = $result.Data -is [System.Collections.IDictionary] -and
                $result.Data.NoApplicationFailures -is [bool] -and $result.Data.NoApplicationFailures -and
                @($baselineIds | Where-Object { $_ -in $affected }).Count -gt 0
            }
            if ($dependsOnAffected) { $affected += $definition.Id; $added = $true }
        }
    } while ($added)
    return $affected
}

function Write-ManifestStepResult {
    <#
    .SYNOPSIS
        Append detached outcome evidence before replacing current workflow state.
    .DESCRIPTION
        History survives retries, dependency invalidation and recovery step resets.
        Legacy evidence retains its recorded timestamp, or null when unknown.
        This records handler outcomes only, not interrupted executions or save durability.
    .PARAMETER Device
        Mutable workflow record whose history owns independent normalised snapshots.
    .PARAMETER StepDefinition
        Manifest identity for the completed handler invocation.
    .PARAMETER Result
        Complete handler outcome, including blocked and unsuccessful results.
    .OUTPUTS
        None. Appends detached in-memory outcome evidence; caller owns guarded durable storage.
    #>
    param(
        [Parameter(Mandatory)]$Device,
        [Parameter(Mandatory)]$StepDefinition,
        [Parameter(Mandatory)]$Result
    )

    function Add-ManifestAttemptSnapshot {
        <#
        .SYNOPSIS
            Append a deep copy of supplied evidence with record identity and sequence.
        .PARAMETER StepId
            Step owning the evidence; unrelated historical entries are never changed.
        .PARAMETER Evidence
            Complete handler result or untouched legacy step evidence.
        .PARAMETER Legacy
            Preserve prior evidence once without inventing its execution timestamp.
        .OUTPUTS
            None. Appends one independent snapshot to the enclosing device record.
        #>
        param([Parameter(Mandatory)][string]$StepId, [Parameter(Mandatory)]$Evidence, [switch]$Legacy)
        if ($Legacy -and @($Device.AttemptHistory | Where-Object { $_.StepId -eq $StepId }).Count -gt 0) { return }
        $snapshot = ConvertTo-NormalisedValue -Value $Evidence
        $timestamp = Get-Date -Format o
        $actor = [string]$env:USERNAME
        $mode = [string]$Script:Runtime.ModeDisplayName
        if ($Legacy) {
            $timestamp = $null
            if ($null -ne $snapshot.Timestamp) {
                $recordedTimestamp = $snapshot.Timestamp
                if ($recordedTimestamp -is [System.Collections.IDictionary]) { $recordedTimestamp = $recordedTimestamp.value }
                $recordedDate = Get-Date -Date $recordedTimestamp -ErrorAction Stop
                if ($recordedDate -ne [DateTime]::MinValue) { $timestamp = Get-Date -Date $recordedDate -Format o }
            }
            $actor = ''
            $mode = [string]$snapshot.Mode
        }
        $actionName = [string]$snapshot.ActionName
        if (-not $Legacy) { $actionName = [string]$StepDefinition.ActionName }
        $Device.AttemptHistory = @($Device.AttemptHistory) + , @{
            Sequence = $Device.AttemptHistory.Count + 1; AttemptId = [guid]::NewGuid().Guid
            StepId = $StepId; ActionName = $actionName; Actor = $actor; Timestamp = $timestamp
            Mode = $mode; TenantId = [string]$Device.TenantId; Serial = [string]$Device.Serial; RecordId = [string]$Device.RecordId
            EvidenceKind = if ($Legacy) { 'LegacyEvidence' } else { 'HandlerOutcome' }
            Result = $snapshot
        }
    }

    $resultTimestamp = Get-Date
    if ($StepDefinition.ActionName -eq 'RetryFailedApplications' -and
        $Result.Data -is [System.Collections.IDictionary] -and $Result.Data.Contains('NoApplicationFailures')) {
        $expectedState = if ($Script:Runtime.IsDemoMode) { 'Simulated' } else { 'TechnicianConfirmed' }
        if ($Result.Success -isnot [bool] -or -not $Result.Success -or
            $Result.IsSimulated -isnot [bool] -or $Result.IsSimulated -ne [bool]$Script:Runtime.IsDemoMode -or
            $Result.CompletionState -cne $expectedState -or
            -not (Test-ApplicationNoFailureEvidence -Device $Device -Data $Result.Data)) {
            throw 'The no-failure outcome does not match the current confirmed application baseline.'
        }
    }
    if (-not $Script:Runtime.IsDemoMode -and $StepDefinition.ActionName -eq 'ClearUserlessEnrollmentStatus' -and
        $Result.Data -is [System.Collections.IDictionary] -and $Result.Data.RecoveryOutcome -in @('Accepted', 'AllowedObserved')) {
        $savedRecovery = Get-RecoverySubmissionEvidence -Device $Device -StepDefinition $StepDefinition
        $expectedKind = if ($Result.Data.RecoveryOutcome -eq 'Accepted') { 'RecoveryAccepted' } else { 'RecoveryAllowedObserved' }
        if ($null -eq $savedRecovery -or $savedRecovery.Kind -cne $expectedKind) {
            throw 'Recovery outcome does not match saved submission evidence.'
        }
        $resultTimestamp = ConvertTo-RecordDate -Value $savedRecovery.RecordedAt
        $claimedTimestamp = ConvertTo-RecordDate -Value $Result.Data.RecoveryRecordedAt
        if ($resultTimestamp -eq [DateTime]::MinValue -or $claimedTimestamp -eq [DateTime]::MinValue -or
            $resultTimestamp.ToUniversalTime() -ne $claimedTimestamp.ToUniversalTime() -or
            $Result.Data.AutopilotDeviceId -ine $savedRecovery.AutopilotDeviceId) {
            throw 'Recovery outcome timestamp or target does not match saved submission evidence.'
        }
    }
    if (-not $Script:Runtime.IsDemoMode -and $Result.CompletionState -eq 'Verified') {
        $Result = New-OperationResult -ActionName $StepDefinition.ActionName -Success ([bool]$Result.Success) -CompletionState Verified -Summary $Result.Summary -Notes $Result.Notes -Data $Result.Data
    }
    if (-not $Device.Contains('AttemptHistory')) { $Device['AttemptHistory'] = @() }
    if ($Device.AttemptHistory -isnot [array]) { throw 'Attempt history must be an array; evidence cannot be discarded.' }
    if ($null -ne $Device.Steps[$StepDefinition.Id]) {
        Add-ManifestAttemptSnapshot -StepId $StepDefinition.Id -Evidence $Device.Steps[$StepDefinition.Id] -Legacy
    }
    Add-ManifestAttemptSnapshot -StepId $StepDefinition.Id -Evidence $Result
    if ($Result.Data -is [System.Collections.IDictionary] -and $Result.Data['Blocked']) { return }
    if ($Result.Success -and $StepDefinition.ActionName -eq 'ConfirmRecoveryReadiness') {
        $identityStepId = Get-ManifestActionStepId -ActionName 'ResolveAutopilotDevice'
        $unblockStepId = Get-ManifestActionStepId -ActionName 'ClearUserlessEnrollmentStatus'
        $retainedSteps = @{}
        foreach ($retainedStepId in @($identityStepId, $unblockStepId)) {
            if ($Device.Steps.Contains($retainedStepId)) { $retainedSteps[$retainedStepId] = $Device.Steps[$retainedStepId] }
        }
        $Device.RecoveryHistory = @($Device.RecoveryHistory) + , @{
            Stage = 'RecoveryClosed'; Timestamp = Get-Date -Format o; Actor = $env:USERNAME
            Reason = $Device.RecoveryReason; Steps = ConvertTo-NormalisedValue -Value $Device.Steps
        }
        $Device.Steps = $retainedSteps
        $Device.ManagedDeviceId = ''
        $Device.IntuneDeviceName = ''
        $Device.IntuneInventory = @{}
        $Device.TechnicianUserPrincipalName = ''
        $Device.FinalPrimaryUserId = ''
        $Device.FinalPrimaryUserPrincipalName = ''
        $Device.FinalPrimaryUserDisplayName = ''
        $Device.Status = 'in-progress'
        $Device.CompletedAt = [DateTime]::MinValue
        $Device.DispatchConfirmed = $false
        $Device.DispatchedAt = [DateTime]::MinValue
        $Device.CompletedBy = ''
        $Device.IsCompletionVerified = $false
    }
    $stepWasPreviouslyCompleted = Test-ManifestStepCompleted -Device $Device -StepId $StepDefinition.Id

    if ($stepWasPreviouslyCompleted -and $StepDefinition.ActionName -ne 'ConfirmRecoveryReadiness') {
        $Device.DispatchConfirmed = $false
        $Device.DispatchedAt = [DateTime]::MinValue
        $definitions = @(Get-EnabledManifestSteps)
        $affectedStepIds = @(Get-AffectedWorkflowStepId -Device $Device -RootStepId $StepDefinition.Id -Definitions $definitions)
        foreach ($stepId in $affectedStepIds) {
            if ($stepId -eq $StepDefinition.Id -or $null -eq $Device.Steps[$stepId]) { continue }
            $dependentEvidence = $Device.Steps[$stepId]
            Add-ManifestAttemptSnapshot -StepId $stepId -Evidence $dependentEvidence -Legacy
            if ($dependentEvidence.CompletionState -ne 'Blocked') { $dependentEvidence['PreviousCompletionState'] = $dependentEvidence.CompletionState }
            $dependentEvidence['CompletionState'] = 'Blocked'
            $dependentEvidence['Completed'] = $false
            $dependentEvidence['Success'] = $false
            $dependentEvidence['InvalidatedBy'] = $StepDefinition.Id
            $dependentEvidence['InvalidatedAt'] = Get-Date -Format o
        }
    }

    $Device.Steps[$StepDefinition.Id] = @{
        Completed       = (Test-CompletionStateComplete -CompletionState $Result.CompletionState)
        Success         = $Result.Success
        CompletionState = $Result.CompletionState
        Timestamp       = $resultTimestamp
        Summary         = $Result.Summary
        Notes           = $Result.Notes
        Mode            = $Script:Runtime.ModeDisplayName
        ActionName      = $Result.ActionName
        IsSimulated     = $Result.IsSimulated
        Data            = ConvertTo-NormalisedValue -Value $Result.Data
    }

    if ($Result.Success -and $Device.Status -eq 'new') { $Device.Status = 'in-progress' }
    if ($Result.Success -and $StepDefinition.ActionName -eq 'ConfirmRecoveryReadiness') {
        $Device.RecoveryActive = $false
        $Device.RecoveryReason = ''
    }
    $Device.LastUpdatedAt = Get-Date
    $Device.LastUpdatedBy = $env:USERNAME

    if ((Test-DeviceReadyForDispatch -Device $Device).Ready) {
        $Device.Status = 'completed'
        if (-not $Device.CompletedAt -or $Device.CompletedAt -eq [DateTime]::MinValue) { $Device.CompletedAt = Get-Date }
        if (-not $Device.CompletedBy) { $Device.CompletedBy = $env:USERNAME }
    }
    elseif ($Device.Status -eq 'completed') {
        $Device.Status = 'in-progress'
        $Device.CompletedAt = [DateTime]::MinValue
        $Device.DispatchConfirmed = $false
        $Device.DispatchedAt = [DateTime]::MinValue
        $Device.CompletedBy = ''
        $Device.IsCompletionVerified = $false
    }
    if ($StepDefinition.ActionName -eq 'AssignFinalPrimaryUser' -and $Result.Success -and (Test-CompletionStateComplete -CompletionState $Result.CompletionState)) {
        Show-ChecklistHandoffGuide -Device $Device
    }
}

#endregion
#region Bench Eligibility, Dispatch and Presentation
function New-BuildBench {
    <#
    .SYNOPSIS
        Initialise an empty bench with the selected capacity.
    .PARAMETER Positions
        Position count supplied by the validated bench-setup flow.
    .OUTPUTS
        None. Replaces script bench state; its caller owns subsequent guarded persistence.
    #>
    param([int]$Positions)
    if ($Positions -lt 1 -or $Positions -gt 50) { Write-Host 'Positions must be between 1 and 50.'; return }
    $Script:BuildBench.Positions = @(); for ($i = 1; $i -le $Positions; $i++) { $Script:BuildBench.Positions += [ordered]@{ Index = $i; Serial = $null; ConfigItem = $null } }
    $Script:BuildBench.Active = $true
    Write-AutopilotExpressLog -Message ('Build bench initialised with {0} positions.' -f $Positions) -Level 'INFO'
}

function Test-ManifestStepAttempted {
    <#
    .SYNOPSIS
        Test for a current step entry without treating an attempt as completion.
    .PARAMETER Device
        Record containing the current Steps dictionary.
    .PARAMETER StepId
        Stored manifest identity to inspect.
    .OUTPUTS
        Boolean entry presence; pending and failed outcomes remain attempts.
    #>
    param(
        [Parameter(Mandatory)]$Device,
        [Parameter(Mandatory)][string]$StepId
    )
    return $null -ne $Device.Steps[$StepId]
}

function Test-ManifestStepCompleted {
    <#
    .SYNOPSIS
        Interpret explicit completion evidence with legacy-state compatibility.
    .PARAMETER Device
        Record containing current step evidence.
    .PARAMETER StepId
        Stored manifest identity, not the terminal display alias.
    .OUTPUTS
        Boolean completion; explicit pending/blocked states override legacy success flags.
    #>
    param(
        [Parameter(Mandatory)]$Device,
        [Parameter(Mandatory)][string]$StepId
    )

    if (-not (Test-ManifestStepAttempted -Device $Device -StepId $StepId)) { return $false }
    $stepDefinition = Get-EnabledManifestSteps | Where-Object { $_.Id -eq $StepId } | Select-Object -First 1
    if ($stepDefinition.ActionName -eq 'ResolveAutopilotDevice' -and [string]::IsNullOrWhiteSpace($Device.AutopilotDeviceId)) { return $false }
    $stepRecord = $Device.Steps[$StepId]
    if ($null -eq $stepRecord) { return $false }

    if ($stepRecord -is [System.Collections.IDictionary]) {
        if ($stepDefinition.ActionName -eq 'RetryFailedApplications' -and
            $stepRecord.Data -is [System.Collections.IDictionary] -and $stepRecord.Data.Contains('NoApplicationFailures')) {
            $expectedState = if ($Script:Runtime.IsDemoMode) { 'Simulated' } else { 'TechnicianConfirmed' }
            if ($stepRecord.Success -isnot [bool] -or -not $stepRecord.Success -or
                $stepRecord.IsSimulated -isnot [bool] -or $stepRecord.IsSimulated -ne [bool]$Script:Runtime.IsDemoMode -or
                $stepRecord.CompletionState -cne $expectedState -or
                -not (Test-ApplicationNoFailureEvidence -Device $Device -Data $stepRecord.Data)) { return $false }
        }
        if ($null -ne $stepRecord['CompletionState']) { return Test-CompletionStateComplete -CompletionState ([string]$stepRecord['CompletionState']) }
        if ($null -ne $stepRecord['Completed']) { return [bool]$stepRecord['Completed'] }
        if ($null -ne $stepRecord['Success']) { return [bool]$stepRecord['Success'] }
    }

    if ($stepRecord.PSObject.Properties.Name -contains 'CompletionState' -and $null -ne $stepRecord.CompletionState) { return Test-CompletionStateComplete -CompletionState ([string]$stepRecord.CompletionState) }
    if ($stepRecord.PSObject.Properties.Name -contains 'Completed' -and $null -ne $stepRecord.Completed) { return [bool]$stepRecord.Completed }
    if ($stepRecord.PSObject.Properties.Name -contains 'Success' -and $null -ne $stepRecord.Success) { return [bool]$stepRecord.Success }
    return $false
}

function Test-CompletionStateComplete {
    <#
    .SYNOPSIS
        Classify documented completion states without treating Submitted as complete.
    .PARAMETER CompletionState
        Recorded evidence classification to inspect.
    .OUTPUTS
        Boolean classification only; Simulated is not Live verification.
    #>
    param([Parameter(Mandatory)][string]$CompletionState)

    return $CompletionState -in @('Verified', 'TechnicianConfirmed', 'AuditedException', 'Simulated', 'LegacyCompleted')
}

function Get-NextStepId {
    <#
    .SYNOPSIS
        Find the first eligible incomplete manifest step for the selected device.
    .PARAMETER Device
        Record with current prerequisite and recovery evidence.
    .OUTPUTS
        Stored manifest ID or null; does not execute actions or infer sequential letters.
    #>
    param($Device)
    $nextEligibleStep = Get-EligibleManifestSteps -Device $Device -First
    if ($nextEligibleStep) { return $nextEligibleStep.Id }
    return $null
}

function Get-ManifestStepPrerequisiteIds {
    <#
    .SYNOPSIS
        Read declared prerequisite identities from a validated manifest step.
    .PARAMETER StepDefinition
        Entry whose dependency graph was validated at startup.
    .OUTPUTS
        Prerequisite ID array, empty when none; no state evaluation.
    #>
    param([Parameter(Mandatory)]$StepDefinition)

    return @($StepDefinition.PrerequisiteStepIds)
}

function Test-ManifestStepEligibility {
    <#
    .SYNOPSIS
        Evaluate prerequisite completion and recovery activation independently.
    .DESCRIPTION
        Membership alone may overlap an accepted tag update bound to this record,
        build cycle, tenant, serial and target after identity/removal completion.
        This never marks the tag complete or relaxes physical milestone gates.
    .PARAMETER Device
        Record with current completion/recovery context.
    .PARAMETER StepDefinition
        Proposed action and declared dependencies/activation.
    .OUTPUTS
        Eligible, MissingStepIds, ActivationRequirement and ActivationSatisfied dictionary.
    #>
    param(
        [Parameter(Mandatory)]$Device,
        [Parameter(Mandatory)]$StepDefinition
    )

    $missingStepIds = @(Get-ManifestStepPrerequisiteIds -StepDefinition $StepDefinition | Where-Object { -not (Test-ManifestStepCompleted -Device $Device -StepId $_) })
    if ($StepDefinition.ActionName -eq 'ConfirmImagingAndOobe') {
        $tagStepId = Get-ManifestActionStepId -ActionName 'ApplyGroupTag'
        if ($tagStepId -notin $missingStepIds -and -not (Test-ManifestStepCompleted -Device $Device -StepId $tagStepId)) {
            $missingStepIds += $tagStepId
        }
    }
    if (-not $Script:Runtime.IsDemoMode -and $StepDefinition.ActionName -eq 'AddToPreProvisioningGroup' -and $missingStepIds.Count) {
        $tagStepId = Get-ManifestActionStepId -ActionName 'ApplyGroupTag'
        $tagEvidence = $Device.Steps[$tagStepId]
        if ($tagStepId -in $missingStepIds -and $tagEvidence.CompletionState -eq 'Submitted' -and $tagEvidence.Data.Submitted -eq $true) {
            $acceptedContext = $tagEvidence.Data.AcceptedContext
            $matchingScope = $acceptedContext -is [System.Collections.IDictionary] -and @('RecordId', 'BuildCycleId', 'TenantId', 'Serial' | Where-Object {
                    -not [string]$Device[$_] -or [string]$acceptedContext[$_] -ine [string]$Device[$_]
                }).Count -eq 0
            $acceptedAt = ConvertTo-RecordDate -Value $tagEvidence.Timestamp
            $cycleBoundary = ConvertTo-RecordDate -Value $Device.StartedAt
            foreach ($closedRecovery in @($Device.RecoveryHistory | Where-Object Stage -eq 'RecoveryClosed')) {
                $closedAt = ConvertTo-RecordDate -Value $closedRecovery.Timestamp
                if ($closedAt -eq [DateTime]::MinValue) { $matchingScope = $false }
                elseif ($closedAt -gt $cycleBoundary) { $cycleBoundary = $closedAt }
            }
            $requiredActionsComplete = @('ResolveAutopilotDevice', 'RemoveAssociatedManagedDevice' | Where-Object {
                    -not (Test-ManifestStepCompleted -Device $Device -StepId (Get-ManifestActionStepId -ActionName $_))
                }).Count -eq 0
            $expectedTag = '{0}-{1}' -f $Device.SiteCode, ($Device.DeviceType -replace '\s', '')
            if ($matchingScope -and $requiredActionsComplete -and $cycleBoundary -ne [DateTime]::MinValue -and
                $acceptedAt -ge $cycleBoundary -and $acceptedAt.ToUniversalTime() -le [DateTime]::UtcNow -and
                $Device.AutopilotDeviceId -and $tagEvidence.Data.AutopilotDeviceId -ieq $Device.AutopilotDeviceId -and
                $tagEvidence.Data.GroupTag -ceq $expectedTag) {
                $missingStepIds = @($missingStepIds | Where-Object { $_ -ne $tagStepId })
            }
        }
    }
    $activationRequirement = [string]$StepDefinition.ActivationRequirement
    $activationSatisfied = $activationRequirement -eq 'None' -or ($activationRequirement -eq 'RecoveryMode' -and $Device.RecoveryActive)
    if ($Device.RecoveryActive -and $activationRequirement -eq 'None' -and $StepDefinition.ActionName -notin @('ResolveAutopilotDevice', 'RemoveAssociatedManagedDevice')) {
        $activationRequirement = 'RecoveryCloseOut'
        $activationSatisfied = $false
    }
    return [ordered]@{ Eligible = ($missingStepIds.Count -eq 0 -and $activationSatisfied); MissingStepIds = $missingStepIds; ActivationRequirement = $activationRequirement; ActivationSatisfied = $activationSatisfied }
}

function Enter-DeviceRecoveryMode {
    <#
    .SYNOPSIS
        Confirm recovery entry and retain detached pre-reset evidence for accountability.
    .PARAMETER Device
        Mutable record; current-cycle gates prevent automatic replay of recovery actions.
    .OUTPUTS
        None. Updates in-memory recovery/history after confirmation; the caller persists it.
    #>
    param([Parameter(Mandatory)]$Device)

    $identityStepId = Get-ManifestActionStepId -ActionName 'ResolveAutopilotDevice'
    $unblockStepId = Get-ManifestActionStepId -ActionName 'ClearUserlessEnrollmentStatus'
    $closeOutStepId = Get-ManifestActionStepId -ActionName 'ConfirmRecoveryReadiness'
    if (-not (Test-ManifestStepCompleted -Device $Device -StepId $identityStepId)) {
        Write-Host 'Resolve the Autopilot device before recording an Autopilot failure and entering recovery mode.'
        return
    }
    if ($Device.RecoveryActive) {
        Write-Host 'Recovery mode is already active for this device.'
        return
    }
    $confirmed = Read-ValidatedInput -Prompt 'Record an Autopilot failure and enter recovery mode? [Y] Yes [N] No' -Default 'N' -Type 'Choice' -Choices @('Y', 'N')
    if ($confirmed.ToUpper() -ne 'Y') { return }
    $reason = Read-ValidatedInput -Prompt 'Recovery reason' -Default 'Autopilot failure reported by technician'
    $Device.RecoveryHistory = @($Device.RecoveryHistory) + , @{
        Stage = 'RecoveryEntered'; Timestamp = Get-Date -Format o; Actor = $env:USERNAME
        Reason = $reason; Steps = ConvertTo-NormalisedValue -Value $Device.Steps
    }
    $retainedSteps = @{}
    foreach ($stepId in $Device.Steps.Keys) {
        if ($stepId -notin @($unblockStepId, $closeOutStepId)) { $retainedSteps[$stepId] = $Device.Steps[$stepId] }
    }
    $Device.Steps = $retainedSteps
    $Device.RecoveryActive = $true
    $Device.RecoveryStartedAt = Get-Date
    $Device.RecoveryReason = $reason
    $Device.Status = 'in-progress'
    $Device.IsCompletionVerified = $false
    $Device.LastUpdatedAt = $Device.RecoveryStartedAt
    $Device.LastUpdatedBy = $env:USERNAME
    Write-AutopilotExpressLog -Message ('Recovery mode entered for Serial={0}: {1}' -f $Device.Serial, $reason) -Level 'WARN'
    Write-Host 'Recovery mode is active. Conditional recovery actions are now available.'
}

function Get-EligibleManifestSteps {
    <#
    .SYNOPSIS
        List enabled incomplete actions with satisfied prerequisites and activation.
    .PARAMETER Device
        Current record including pending recovery submissions.
    .PARAMETER First
        Stop after the first eligible action for next-step displays; omit for the complete menu list.
    .OUTPUTS
        Ordered step array; excludes inappropriate repeat recovery-unblock submission.
    #>
    param([Parameter(Mandatory)]$Device, [switch]$First)

    # Terminal records are never offered a next action, even with incomplete legacy step fields.
    if ($Device.Status -in @('completed', 'removed')) { if ($First) { return $null }; return @() }
    $eligibleSteps = @()
    foreach ($step in (Get-EnabledManifestSteps)) {
        $awaitingRecoveryConfirmation = $Device.RecoveryActive -and $step.ActionName -eq 'ClearUserlessEnrollmentStatus' -and
        $Device.Steps[$step.Id].CompletionState -eq 'Submitted'
        if ($awaitingRecoveryConfirmation -or (Test-ManifestStepCompleted -Device $Device -StepId $step.Id)) { continue }
        if (-not (Test-ManifestStepEligibility -Device $Device -StepDefinition $step).Eligible) { continue }
        if ($First) { return $step }
        $eligibleSteps += $step
    }
    return $eligibleSteps
}

function Get-DispatchBlockingManifestSteps {
    <#
    .SYNOPSIS
        Identify unresolved enabled steps, excluding inactive conditional recovery actions.
    .PARAMETER Device
        Current evidence to inspect without changing it.
    .OUTPUTS
        Blocking step array; does not waive failed or Submitted required actions.
    #>
    param([Parameter(Mandatory)]$Device)

    return @(Get-EnabledManifestSteps | Where-Object {
            $isInactiveConditionalAction = $_.ActivationRequirement -eq 'RecoveryMode' -and -not $Device.RecoveryActive
            -not $isInactiveConditionalAction -and -not (Test-ManifestStepCompleted -Device $Device -StepId $_.Id)
        })
}

function Get-DeviceFeedbackContext {
    <#
    .SYNOPSIS
        Identify the selected device independently of later bench moves/removal.
    .PARAMETER Device
        Workflow record or occupied bench slot.
    .OUTPUTS
        Position when present, serial and Configuration Item in plain text.
    .PARAMETER TextAlreadyDisplayed
        Identify context already present in captured host text without editing that text.
    #>
    param([Parameter(Mandatory)][System.Collections.IDictionary]$Device, [AllowEmptyString()][string]$TextAlreadyDisplayed = '')
    $slots = @($Script:BuildBench.Positions | Where-Object { $_.Serial -and $_.Serial -eq $Device.Serial })
    $position = if ($slots.Count -eq 1) { 'Position {0}' -f $slots[0].Index } else { 'Tracked device' }
    $parts = @()
    foreach ($part in @(@{ Text = $position; Value = $position }, @{ Text = 'Serial={0}' -f $Device.Serial; Value = [string]$Device.Serial }, @{ Text = 'CI={0}' -f $Device.ConfigItem; Value = [string]$Device.ConfigItem })) {
        $pattern = '(?<![A-Za-z0-9]){0}(?![A-Za-z0-9])' -f [regex]::Escape($part.Value)
        if (-not $TextAlreadyDisplayed -or -not $part.Value -or $TextAlreadyDisplayed -notmatch $pattern) { $parts += $part.Text }
    }
    return $parts -join ' | '
}

function Undo-LatestTechnicianConfirmation {
    <#
    .SYNOPSIS
        Withdraw the latest physical confirmation without erasing evidence or reversing Graph writes.
    .PARAMETER Records
        Current session container; its guarded writer saves a detached proposal before publication.
    .PARAMETER Device
        Active owned record. Dispatched, recovering and unbound Live records are refused.
    .OUTPUTS
        Changed and Summary dictionary. Cancellation or unsafe later remote evidence makes no change.
    #>
    param([Parameter(Mandatory)][hashtable]$Records, [Parameter(Mandatory)][System.Collections.IDictionary]$Device)
    if (@($Records.Value) -notcontains $Device -or $Device.Status -eq 'removed' -or $Device.DispatchConfirmed -or $Device.RecoveryActive) {
        return @{ Changed = $false; Summary = 'Go back refused: the record is unavailable, dispatched or in recovery.' }
    }
    if (-not $Script:Runtime.IsDemoMode) { [void](Get-LiveTenantBinding -Device $Device) }
    $manualActions = @('ConfirmImagingAndOobe', 'ValidateDeploymentProfile', 'ConfirmReseal', 'ConfirmBootToSignIn', 'ConfirmFirstSignIn', 'ConfirmApplicationBaseline', 'ConfirmUpdatesAndShutdown')
    $definitions = @(Get-EnabledManifestSteps)
    $candidates = @($definitions | Where-Object {
            $_.ActionName -in $manualActions -and ($Device.Steps[$_.Id].CompletionState -eq 'TechnicianConfirmed' -or ($Script:Runtime.IsDemoMode -and $Device.Steps[$_.Id].CompletionState -eq 'Simulated'))
        } | Sort-Object @{ Expression = { ConvertTo-RecordDate -Value $Device.Steps[$_.Id].Timestamp }; Descending = $true })
    if (-not $candidates.Count) { return @{ Changed = $false; Summary = 'No current technician confirmation can be withdrawn.' } }
    $selectedStep = $candidates[0]
    $affectedIds = @(Get-AffectedWorkflowStepId -Device $Device -RootStepId $selectedStep.Id -Definitions $definitions)
    foreach ($definition in $definitions | Where-Object { $_.Id -in $affectedIds -and $_.ActionName -notin $manualActions }) {
        $current = $Device.Steps[$definition.Id]
        $laterAccepted = @($Device.AttemptHistory | Where-Object {
                $_.StepId -eq $definition.Id -and (ConvertTo-RecordDate -Value $_.Timestamp) -ge (ConvertTo-RecordDate -Value $Device.Steps[$selectedStep.Id].Timestamp) -and
                ($_.Result.CompletionState -in @('Verified', 'Submitted', 'AuditedException', 'LegacyCompleted') -or $_.Result.Data.Submitted -eq $true)
            })
        if ($current.CompletionState -in @('Verified', 'Submitted', 'AuditedException', 'LegacyCompleted') -or $current.Data.Submitted -eq $true -or $laterAccepted.Count -gt 0) {
            return @{ Changed = $false; Summary = 'Go back refused: dependent remote action {0} has accepted or completed evidence. Review it manually; no remote action was reversed.' -f $definition.Id }
        }
    }
    Write-Host ('Withdraw {0} for serial {1}; dependent evidence will require rechecking: {2}.' -f $selectedStep.Id, $Device.Serial, ($affectedIds -join ', '))
    $confirmed = Read-ValidatedInput -Prompt 'Withdraw this technician confirmation? [Y] Yes [N] No' -Default N -Type Choice -Choices @('Y', 'N')
    if ($confirmed -ine 'Y') { return @{ Changed = $false; Summary = 'Go back cancelled; confirmation and history retained.' } }
    $proposedRecords = ConvertTo-NormalisedValue -Value @($Records.Value)
    $proposal = $proposedRecords | Where-Object { $_.Serial -eq $Device.Serial } | Select-Object -First 1
    $result = New-OperationResult -ActionName $selectedStep.ActionName -Success $false -CompletionState Failed -Summary 'Technician confirmation withdrawn.' -Notes 'Go back correction; the original confirmation remains in attempt history. No remote action was reversed.' -Data @{ Correction = $true; Reason = 'Technician withdrew an accidental confirmation.' }
    Write-ManifestStepResult -Device $proposal -StepDefinition $selectedStep -Result $result
    Write-UserDeviceRecords -Records $proposedRecords
    foreach ($field in @($proposal.Keys)) { $Device[$field] = $proposal[$field] }
    return @{ Changed = $true; Summary = 'Confirmation {0} withdrawn; its original evidence and correction were saved. Reconfirm the observation before proceeding.' -f $selectedStep.Id }
}

function Invoke-DeviceDocumentHousekeeping {
    <#
    .SYNOPSIS
        Recover terminal document staging without touching active jobs or records.
    .OUTPUTS
        Logged cleanup summary. Never imports the optional module when disabled.
    #>
    $state = Get-Variable -Name DocumentSession -Scope Script -ValueOnly -ErrorAction SilentlyContinue
    if (-not $state -or -not $state.Settings -or -not (Get-Module AutopilotExpress.Documents)) { return }
    $scope = if ($state.Mode -eq 'Demo') { 'Demo' } else { 'Live-{0}' -f $state.TenantId }
    foreach ($folder in @('Working', 'jobs')) {
        try {
            $root = Join-Path (Join-Path $state.Settings.Values.LocalRoot $scope) $folder
            $outcome = Invoke-AutopilotDocumentCleanup -JobRoot $root -FailedJobRetentionDays $state.Settings.Values.FailedJobRetentionDays
            if ($outcome.Removed -or $outcome.Moved) { Write-AutopilotExpressLog -Message ('Document housekeeping: {0} owned temporary files removed; {1} expired failure assets reversibly archived.' -f $outcome.Removed, $outcome.Moved) -Level INFO }
        }
        catch { Write-AutopilotExpressLog -Message ('Document housekeeping deferred; evidence retained: {0}' -f $_.Exception.Message) -Level WARN }
    }
}

function Test-DeviceDocumentScriptTrust {
    <#
    .SYNOPSIS
        Inspect local document scripts before optional import or worker execution.
    .OUTPUTS
        Reviewed paths and SHA-256 fingerprints of files carrying Internet-zone marks.
        This is not signature approval and never changes trust or execution policy.
    #>
    $root = Get-AutopilotExpressDefinitionPath -FileName 'Modules/Documents'
    if ($root -notmatch '^[A-Za-z]:[\\/]') { throw 'Document scripts must be deployed to a reviewed local directory.' }
    $items = @(Get-Item -LiteralPath $root -Force -ErrorAction Stop) + @(Get-ChildItem -LiteralPath $root -Recurse -Force -ErrorAction Stop)
    if (@($items | Where-Object { $_.Attributes -band [IO.FileAttributes]::ReparsePoint }).Count) { throw 'Document script trust inspection refused a redirected directory or file.' }
    $policy = Get-ExecutionPolicy -ErrorAction Stop
    if ($policy -eq 'Restricted') { throw 'Effective execution policy is Restricted. Ask the policy owner for an approved deployment; unblocking cannot enable scripts under this policy.' }
    $blocked = @()
    foreach ($file in @($items | Where-Object { -not $_.PSIsContainer -and $_.Extension -in @('.ps1', '.psm1', '.psd1') })) {
        if ($policy -eq 'AllSigned') {
            $signature = Get-AuthenticodeSignature -LiteralPath $file.FullName -ErrorAction Stop
            if ($signature.Status -ne 'Valid' -or -not $signature.SignerCertificate) { throw ('AllSigned requires a valid signed document deployment: {0}. Unblocking is not a remedy; contact the policy owner.' -f $file.FullName) }
            $publishers = @(Get-ChildItem -LiteralPath 'Cert:\CurrentUser\TrustedPublisher', 'Cert:\LocalMachine\TrustedPublisher' -ErrorAction Stop)
            if ($signature.SignerCertificate.Thumbprint -notin @($publishers.Thumbprint)) { throw ('Document publisher is not already trusted: {0}. Obtain an organisation-approved signed deployment; this script will not trust a publisher automatically.' -f $file.FullName) }
        }
        $zoneStream = @(Get-Item -LiteralPath $file.FullName -Stream '*' -ErrorAction Stop | Where-Object { $_.Stream -eq 'Zone.Identifier' })
        if (-not $zoneStream) { continue }
        $zone = Get-Content -LiteralPath $file.FullName -Stream Zone.Identifier -Raw -ErrorAction Stop
        if ($zone -match '(?m)^ZoneId\s*=\s*[34]\s*$') {
            $blocked += @{ Path = $file.FullName; SHA256 = (Get-FileHash -LiteralPath $file.FullName -Algorithm SHA256 -ErrorAction Stop).Hash }
        }
    }
    return @{ Ready = ($blocked.Count -eq 0); Files = $blocked }
}

function Initialize-DeviceDocumentSession {
    <#
    .SYNOPSIS
        Resolve optional document preferences without host probes when both outputs are off.
    .PARAMETER LoadModule
        Load the inert optional module for an explicit settings visit even if disabled.
    .OUTPUTS
        Session-only state. Saved preferences remain separate from operational records.
    #>
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'None')]
    param([switch]$LoadModule)
    $existing = Get-Variable -Name DocumentSession -Scope Script -ValueOnly -ErrorAction SilentlyContinue
    if ($existing -and $existing.Settings) { return }
    $modeName = if ($Script:Runtime.IsDemoMode) { 'Demo' } else { 'Live' }
    $tenant = if ($Script:Runtime.IsDemoMode) { 'demo' } else { [string]$Script:GraphSession.TenantId }
    if ($tenant -notmatch '^(demo|[0-9a-fA-F]{8}(-[0-9a-fA-F]{4}){3}-[0-9a-fA-F]{12})$' -or -not $env:LOCALAPPDATA) { throw 'Document preferences require a valid mode/tenant and durable local profile.' }
    $preferencePath = Join-Path $env:LOCALAPPDATA ('PowerShellScriptingNew/AutopilotExpress/Documents/Preferences/{0}-{1}.json' -f $modeName, $tenant)
    $saved = @{}; $runtimeValues = @{}
    if ($Script:RuntimeConfig.Contains('documentGeneration')) { $runtimeValues = $Script:RuntimeConfig['documentGeneration'] }
    if (Test-Path -LiteralPath $preferencePath) {
        $file = Get-Item -LiteralPath $preferencePath -Force -ErrorAction Stop
        if ($file.Length -gt 65536 -or ($file.Attributes -band [IO.FileAttributes]::ReparsePoint)) { throw 'Unsafe document preference file; preserve it for review.' }
        $stored = ConvertTo-NormalisedValue (Get-Content -LiteralPath $preferencePath -Raw -Encoding UTF8 | ConvertFrom-Json -ErrorAction Stop)
        if ($stored.SchemaVersion -ne 1 -or $stored.Mode -cne $modeName -or $stored.TenantId -ine $tenant -or $stored.Actor -cne $env:USERNAME -or $stored.Values -isnot [Collections.IDictionary]) { throw 'Foreign or invalid document preferences; no workflow was changed.' }
        $saved = $stored.Values
    }
    $requested = $false
    foreach ($key in @('BirthCertificateEnabled', 'ChecklistEnabled')) {
        $effective = $false
        foreach ($layer in @($runtimeValues, $saved, $Script:DocumentCommandLineOverrides)) { if ($layer.Contains($key)) { $effective = $layer[$key] } }
        if ($effective -isnot [bool]) { throw 'Document enablement must be Boolean.' }
        if ($effective) { $requested = $true }
    }
    if (-not $PSCmdlet.ShouldProcess('Session document settings', 'Resolve optional controls without changing workflow records')) { return }
    $Script:DocumentSession = @{ Enabled = $false; Settings = $null; Saved = $saved; Session = @{}; Jobs = @(); Mode = $modeName; TenantId = $tenant; PreferencePath = $preferencePath; PrerequisitesReady = $false; Preparation = $null; Suppressed = $false; ExitRequested = $false; PrerequisiteResult = $null }
    if (-not $requested -and -not $LoadModule) { return }
    $trust = Test-DeviceDocumentScriptTrust
    if (-not $trust.Ready) {
        $failure = [InvalidOperationException]::new('Local document scripts require file-trust review before import. No files have been unblocked.')
        $failure.Data['DocumentFiles'] = $trust.Files
        throw $failure
    }
    Import-Module -Name (Get-AutopilotExpressDefinitionPath -FileName 'Modules/Documents/AutopilotExpress.Documents.psd1') -ErrorAction Stop
    $Script:DocumentSession.Settings = Resolve-AutopilotDocumentSettings -ScriptRoot $Script:AutopilotExpressScriptDirectory -LocalApplicationData $env:LOCALAPPDATA -RuntimeConfiguration $runtimeValues -SavedPreferences $saved -CommandLineOverrides $Script:DocumentCommandLineOverrides
    $Script:DocumentSession.Enabled = $requested
    if ($requested) { Invoke-DeviceDocumentHousekeeping }
}

function Request-DeviceDocumentReadiness {
    <#
    .SYNOPSIS
        Resolve document readiness before work and after explicit configuration changes.
    .PARAMETER LoadModule
        Permit the inert optional module to load for a foreground Settings visit.
    .OUTPUTS
        True to continue, false to exit through the caller's existing cleanup.
        Failure defaults to continuing without documents for this session only.
        Unblocking requires a separate default-No confirmation of unchanged files.
    #>
    param([switch]$LoadModule)
    while ($true) {
        $blocked = @()
        try {
            Initialize-DeviceDocumentSession -LoadModule:$LoadModule
            $state = $Script:DocumentSession
            if (-not $state.Settings) { return $true }
            $runtimeValues = if ($Script:RuntimeConfig.Contains('documentGeneration')) { $Script:RuntimeConfig['documentGeneration'] } else { @{} }
            $state.Settings = Resolve-AutopilotDocumentSettings -ScriptRoot $Script:AutopilotExpressScriptDirectory -LocalApplicationData $env:LOCALAPPDATA -RuntimeConfiguration $runtimeValues -SavedPreferences $state.Saved -SessionPreferences $state.Session -CommandLineOverrides $Script:DocumentCommandLineOverrides
            $values = $state.Settings.Values
            $state.Enabled = ($values.BirthCertificateEnabled -and $values.BirthCertificateMode -ne 'Disabled') -or ($values.ChecklistEnabled -and $values.ChecklistMode -ne 'Disabled')
            $state.PrerequisitesReady = $false
            if (-not $state.Enabled) { $state['Suppressed'] = $false; $state['PrerequisiteResult'] = @{ Status = 'Disabled'; Ready = $false; Diagnostic = '' }; return $true }
            $trust = Test-DeviceDocumentScriptTrust
            if (-not $trust.Ready) {
                $failure = [InvalidOperationException]::new('Local document scripts require file-trust review before worker execution.')
                $failure.Data['DocumentFiles'] = $trust.Files
                throw $failure
            }
            $check = Test-AutopilotDocumentPrerequisite -Settings $state.Settings
        }
        catch {
            if ($_.Exception.Data.Contains('DocumentFiles')) { $blocked = @($_.Exception.Data['DocumentFiles']) }
            $check = @{ Ready = $false; Status = 'ConfigurationOrTrustFailed'; Diagnostic = $_.Exception.Message }
        }
        $state = Get-Variable -Name DocumentSession -Scope Script -ValueOnly -ErrorAction SilentlyContinue
        if (-not $state) {
            $Script:DocumentSession = @{ Enabled = $false; Settings = $null; Saved = @{}; Session = @{}; Jobs = @(); Preparation = $null; PrerequisitesReady = $false; Suppressed = $false; ExitRequested = $false; PrerequisiteResult = $null }
            $state = $Script:DocumentSession
        }
        $state['PrerequisiteResult'] = $check
        $state.PrerequisitesReady = [bool]$check.Ready
        $level = if ($check.Ready) { 'INFO' } else { 'WARN' }
        Write-AutopilotExpressLog -Message ('Document prerequisites: {0}. {1}' -f $check.Status, $check.Diagnostic) -Level $level
        if ($check.Ready) {
            $state['Suppressed'] = $false
            # Guards are removable (EnforceDocumentGuards, default false during testing).
            # Only report the DRAFT/no-print outcome when the guard is actually enforced.
            $guarded = [bool]$state.Settings.Values.EnforceDocumentGuards
            foreach ($type in @('BirthCertificate', 'Checklist')) {
                if (-not ($state.Settings.Values[('{0}Enabled' -f $type)] -and $state.Settings.Values[('{0}Mode' -f $type)] -ne 'Disabled')) { continue }
                if (-not (Get-AutopilotDocumentTemplateProfile -DocumentType $type).ApprovedForLive) {
                    if ($guarded) { Write-Host ('{0}: template profile is unapproved and document guards are ON; output is DRAFT and will not print. Turn guards off in Settings > 6 > [G].' -f $type) }
                    else { Write-Host ('{0}: document guards are OFF (testing); output is final and prints according to its policy ({1}).' -f $type, $state.Settings.Values[('{0}Mode' -f $type)]) }
                }
            }
            Write-Host 'Library checks and Word registration passed; Word activation, PDF export and physical printing are not proven by this check.'
            return $true
        }
        # Menu: bracketed keys match the Build Bench convention; the default is shown in the prompt.
        $choices = [Collections.Generic.List[string]]::new()
        Write-Host ''
        Write-Host 'Document output is not available yet. Workflow actions are not affected.'
        if ($blocked.Count) {
            # Summarise by folder instead of printing every file; [L] lists them in full.
            $rootPrefix = $Script:AutopilotExpressScriptDirectory.TrimEnd('\') + '\'
            $relativePaths = @($blocked | ForEach-Object { if ($_.Path.StartsWith($rootPrefix, [StringComparison]::OrdinalIgnoreCase)) { $_.Path.Substring($rootPrefix.Length) } else { $_.Path } })
            Write-Host ('Cause: {0} local document files carry Windows downloaded-file marks and require trust review.' -f $blocked.Count)
            foreach ($group in ($relativePaths | Group-Object { Split-Path -Parent $_ } | Sort-Object Name)) { Write-Host ('  {0,4} file(s) in {1}' -f $group.Count, $group.Name) }
            Write-Host ''
            Write-Host '[U] Unblock these files (asks [Y] Yes [N] No first; no administrator rights needed)'
            Write-Host '[L] List every blocked file with its SHA-256 hash'
            $choices.AddRange([string[]]@('U', 'L'))
        }
        else { Write-Host ('Cause: {0}' -f $check.Diagnostic); Write-Host '' }
        Write-Host '[R] Retry the check after correcting the problem'
        Write-Host '[C] Continue without documents for this session (saved preferences unchanged)'
        Write-Host '[X] Exit the session through normal cleanup'
        $choices.AddRange([string[]]@('R', 'C', 'X'))
        $answer = Read-ValidatedInput -Prompt ('Choose {0}' -f ($choices -join ', ')) -Default 'C' -Type Choice -Choices $choices.ToArray()
        if ($answer -ieq 'R') { continue }
        if ($answer -ieq 'L' -and $blocked.Count) {
            foreach ($file in $blocked) { Write-Host ('{0}{1}  SHA-256 {2}' -f [Environment]::NewLine, $file.Path, $file.SHA256) }
            continue
        }
        if ($answer -ieq 'U' -and $blocked.Count) {
            Write-Host 'Only unblock files you obtained from this project''s trusted source. Unblocking removes the downloaded-file mark only; it cannot override organisation policy and needs no elevation.'
            $approved = Read-ValidatedInput -Prompt ('Unblock these {0} local document files? [Y] Yes [N] No' -f $blocked.Count) -Default 'N' -Type Choice -Choices @('Y', 'N')
            if ($approved -ieq 'Y') {
                try {
                    $current = Test-DeviceDocumentScriptTrust
                    foreach ($file in $blocked) {
                        if (-not @($current.Files | Where-Object { $_.Path -ceq $file.Path -and $_.SHA256 -ceq $file.SHA256 }).Count) { throw 'A listed file changed after review. No further files will be unblocked; review the new list.' }
                    }
                    foreach ($file in $blocked) { Unblock-File -LiteralPath $file.Path -ErrorAction Stop }
                    Write-Host 'Reviewed file marks removed. Rechecking document prerequisites; successful execution is not assumed.'
                }
                catch { Write-Host ('File-trust remedy failed: {0}. No policy bypass or elevation was attempted.' -f $_.Exception.Message) }
            }
            continue
        }
        $state.Enabled = $false
        $state['Suppressed'] = $true
        $state['ExitRequested'] = ($answer -ieq 'X')
        if ($state['ExitRequested']) { return $false }
        Write-Host 'Continuing without document output for this session. No new document jobs will be created. Saved preferences and workflow records are unchanged; use Settings > 6 > [7] to recheck.'
        return $true
    }
}

function Get-DeviceDocumentAttemptDirectory {
    <#
    .SYNOPSIS
        Resolve the local document-only evidence directory without creating it.
    .PARAMETER State
        Current validated settings, mode and tenant; operational storage is not used.
    .OUTPUTS
        Absolute scoped directory. Redirected ancestors and invalid bindings throw.
    #>
    param([Parameter(Mandatory)][Collections.IDictionary]$State)
    $root = [string]$State.Settings.Values.LocalRoot
    if ($root -notmatch '^[A-Za-z]:[\\/]' -or $State.Mode -cnotin @('Demo', 'Live') -or ($State.Mode -ceq 'Demo' -and $State.TenantId -cne 'demo') -or ($State.Mode -ceq 'Live' -and $State.TenantId -notmatch '^[0-9a-fA-F]{8}(-[0-9a-fA-F]{4}){3}-[0-9a-fA-F]{12}$')) { throw 'Document failure storage needs a validated local root, mode and tenant.' }
    $scope = if ($State.Mode -ceq 'Demo') { 'Demo' } else { 'Live-{0}' -f $State.TenantId }
    $directory = Join-Path (Join-Path $root $scope) 'Attempts'
    $ancestor = [IO.DirectoryInfo]::new($directory)
    while ($null -ne $ancestor) {
        if ($ancestor.Exists -and ($ancestor.Attributes -band [IO.FileAttributes]::ReparsePoint)) { throw 'Document failure storage refused a redirected directory.' }
        $ancestor = $ancestor.Parent
    }
    return $directory
}

function Read-DeviceDocumentFailure {
    <#
    .SYNOPSIS
        Discover retained prequeue failures without launching workers or replaying delivery.
    .PARAMETER State
        Current Windows actor, mode and tenant determine the permitted evidence scope.
    .OUTPUTS
        Newest-first detached entries. Foreign, interrupted, oversized or malformed
        evidence is retained on disk and reported, never executed or silently repaired.
    #>
    param([Parameter(Mandatory)][Collections.IDictionary]$State)
    $directory = Get-DeviceDocumentAttemptDirectory -State $State
    if (-not (Test-Path -LiteralPath $directory -PathType Container)) { return }
    $entries = @()
    foreach ($file in @(Get-ChildItem -LiteralPath $directory -File -Filter '*.json' -ErrorAction Stop)) {
        try {
            if ($file.Length -gt 4194304 -or ($file.Attributes -band [IO.FileAttributes]::ReparsePoint)) { throw 'Unsafe document attempt size or redirection.' }
            foreach ($suffix in @('.pending', '.write-in-progress')) { if (Test-Path -LiteralPath ($file.FullName + $suffix)) { throw 'Interrupted document attempt save requires review.' } }
            $attempt = ConvertTo-NormalisedValue -Value (Get-Content -LiteralPath $file.FullName -Raw -Encoding UTF8 -ErrorAction Stop | ConvertFrom-Json -ErrorAction Stop)
            $identifier = [guid]::Empty
            if ($attempt.SchemaVersion -ne 1 -or -not [guid]::TryParse([string]$attempt.AttemptId, [ref]$identifier) -or $identifier -eq [guid]::Empty -or $file.BaseName -ine $identifier.ToString('D')) { throw 'Invalid document attempt identity.' }
            if ($attempt.Actor -cne [string]$env:USERNAME -or $attempt.Mode -cne $State.Mode -or $attempt.TenantId -ine $State.TenantId) { throw 'Document attempt belongs to another actor, mode or tenant.' }
            if ($attempt.Device -isnot [Collections.IDictionary] -or $attempt.DocumentContext -isnot [Collections.IDictionary] -or $attempt.Diagnostic -isnot [string] -or $attempt.Diagnostic.Length -gt 2048) { throw 'Invalid document attempt snapshot.' }
            if ($State.Mode -ceq 'Live' -and $attempt.Device.TenantId -ine $State.TenantId) { throw 'Document dispatch snapshot has a different tenant.' }
            $created = [DateTimeOffset]::MinValue
            if (-not [DateTimeOffset]::TryParse([string]$attempt.CreatedAtUtc, [ref]$created)) { throw 'Invalid document attempt date.' }
            $job = @{ JobId = $attempt.AttemptId }
            if ($null -ne $attempt.Job) {
                $jobId = [guid]::Empty
                if ($attempt.Job -isnot [Collections.IDictionary] -or -not [guid]::TryParse([string]$attempt.Job.JobId, [ref]$jobId) -or $jobId -eq [guid]::Empty -or $attempt.Job.RecordId -cne $attempt.Device.RecordId -or $attempt.Job.BuildCycleId -cne $attempt.Device.BuildCycleId -or $attempt.Job.Mode -cne $State.Mode -or $attempt.Job.TenantId -ine $State.TenantId) { throw 'Detached document job does not match the retained dispatch.' }
                $job = $attempt.Job
            }
            $entries += @{ Job = $job; Handle = @{ Status = 'RetainedFailure'; JobDirectory = $directory }; Result = @{ Status = 'RetainedFailure'; Results = @(); Diagnostic = $attempt.Diagnostic }; Failure = $attempt; FailurePath = $file.FullName; SortDate = $created }
        }
        catch { Write-AutopilotExpressLog -Message ('Retained document attempt requires review at {0}: {1}' -f $file.FullName, $_.Exception.Message) -Level 'WARN' }
    }
    return @($entries | Sort-Object SortDate -Descending)
}

function Read-DeviceDocumentHistory {
    <#
    .SYNOPSIS
        Catalogue completed historical document jobs (DOC-HISTORY) without replaying them.
    .DESCRIPTION
        Reads the compact `Job-<JobId>.receipt.json` receipts that Complete-AutopilotDocumentJob
        leaves under `<LocalRoot>\<Demo|Live-tenant>\Output\<device>\`. The local root lives in
        the current Windows profile (%LOCALAPPDATA%), which scopes receipts to this actor; each
        receipt must also match the current mode and tenant, carry the module owner marker,
        schema 1, the no-replay contract and a file name matching its JobId. Unsafe, foreign or
        malformed receipts are logged for review and skipped; nothing is repaired or executed.
    .PARAMETER State
        Current document session (validated settings, mode and tenant).
    .OUTPUTS
        Newest-first detached entries shaped like session job entries, with Handle.Status
        'CompletedHistory' and the validated receipt under History.
    #>
    param([Parameter(Mandatory)][Collections.IDictionary]$State)
    $scopeRoot = Split-Path -Parent (Get-DeviceDocumentAttemptDirectory -State $State)
    $outputRoot = Join-Path $scopeRoot 'Output'
    if (-not (Test-Path -LiteralPath $outputRoot -PathType Container)) { return }
    $entries = @()
    foreach ($file in @(Get-ChildItem -LiteralPath $outputRoot -File -Filter 'Job-*.receipt.json' -Recurse -Depth 1 -ErrorAction Stop)) {
        try {
            if ($file.Length -gt 65536 -or ($file.Attributes -band [IO.FileAttributes]::ReparsePoint) -or ($file.Directory.Attributes -band [IO.FileAttributes]::ReparsePoint)) { throw 'Unsafe receipt size or redirection.' }
            $receipt = ConvertTo-NormalisedValue -Value (Get-Content -LiteralPath $file.FullName -Raw -Encoding UTF8 -ErrorAction Stop | ConvertFrom-Json -ErrorAction Stop)
            $jobId = [guid]::Empty
            if ($receipt.Owner -cne 'AutopilotExpress.Documents' -or $receipt.SchemaVersion -ne 1 -or $receipt.AutomaticReplayAllowed -isnot [bool] -or $receipt.AutomaticReplayAllowed) { throw 'Invalid receipt owner, schema or no-replay contract.' }
            if (-not [guid]::TryParse([string]$receipt.JobId, [ref]$jobId) -or $jobId -eq [guid]::Empty -or $file.Name -cne ('Job-{0}.receipt.json' -f $jobId.ToString('D'))) { throw 'Receipt file name does not match its job identity.' }
            if ($receipt.Mode -cne $State.Mode -or [string]$receipt.TenantId -ine [string]$State.TenantId) { throw 'Receipt belongs to another mode or tenant.' }
            if ([string]::IsNullOrWhiteSpace([string]$receipt.RecordId) -or [string]::IsNullOrWhiteSpace([string]$receipt.BuildCycleId)) { throw 'Receipt has no record or build-cycle identity.' }
            $updated = [DateTimeOffset]::MinValue
            if (-not [DateTimeOffset]::TryParse([string]$receipt.UpdatedAtUtc, [ref]$updated)) { $updated = [DateTimeOffset]$file.LastWriteTimeUtc }
            $job = @{ JobId = $jobId.ToString('D'); RecordId = [string]$receipt.RecordId; BuildCycleId = [string]$receipt.BuildCycleId; Mode = $receipt.Mode; TenantId = $receipt.TenantId; DispatchedAt = $receipt.DispatchedAt; Fields = @{ SerialNumberOrServiceTag = [string]$receipt.Serial; ConfigurationItem = [string]$receipt.ConfigurationItem } }
            $entries += @{ Job = $job; Handle = @{ Status = 'CompletedHistory'; JobDirectory = $file.DirectoryName }; Result = @{ Status = 'Completed'; Results = @($receipt.Results) }; History = $receipt; ReceiptPath = $file.FullName; SortDate = $updated }
        }
        catch { Write-AutopilotExpressLog -Message ('Historical document receipt requires review at {0}: {1}' -f $file.FullName, $_.Exception.Message) -Level 'WARN' }
    }
    return @($entries | Sort-Object SortDate -Descending)
}

function Save-DeviceDocumentFailure {
    <#
    .SYNOPSIS
        Retain a prequeue document failure independently of committed workflow records.
    .PARAMETER State
        Validated current mode/tenant document session and its local storage root.
    .PARAMETER Device
        Already committed dispatch; only document-relevant fields are copied.
    .PARAMETER Job
        Detached job when projection succeeded, otherwise null.
    .PARAMETER DocumentContext
        Original dispatch identity text, never replaced by a later retrying operator.
    .PARAMETER Diagnostic
        Bounded failure explanation, not an exception or process object.
    .OUTPUTS
        Session job entry, retained even if durable storage fails. Durable records use
        the existing guarded UTF-8 writer; no Graph, printing or workflow writes occur.
    #>
    param(
        [Parameter(Mandatory)][Collections.IDictionary]$State,
        [Parameter(Mandatory)][Collections.IDictionary]$Device,
        [AllowNull()][object]$Job,
        [Collections.IDictionary]$DocumentContext = @{},
        [Parameter(Mandatory)][ValidateNotNullOrEmpty()][string]$Diagnostic
    )
    $snapshot = @{}
    foreach ($key in @('WorkflowIdVersion', 'RecordId', 'BuildCycleId', 'TenantId', 'Status', 'DispatchConfirmed', 'IsCompletionVerified', 'StartedAt', 'CompletedAt', 'DispatchedAt', 'Serial', 'ConfigItem', 'SiteCode', 'DeviceType', 'GroupTag', 'CompletedBy', 'TechnicianUserPrincipalName', 'FinalPrimaryUserId', 'FinalPrimaryUserPrincipalName', 'FinalPrimaryUserDisplayName', 'IntuneInventory', 'Steps')) {
        $snapshot[$key] = ConvertTo-NormalisedValue -Value $Device[$key]
    }
    $snapshot['RecoveryHistory'] = @($Device.RecoveryHistory | Where-Object { $_.Stage -eq 'CompletionOverride' } | ForEach-Object { @{ Stage = $_.Stage; Timestamp = $_.Timestamp; Reason = $_.Reason } })
    $message = [regex]::Replace($Diagnostic, '[\x00-\x08\x0B\x0C\x0E-\x1F\x7F]', ' ')
    if ($message.Length -gt 2048) { $message = $message.Substring(0, 2048) }
    $attempt = @{ SchemaVersion = 1; AttemptId = [guid]::NewGuid().ToString('D'); CreatedAtUtc = [DateTimeOffset]::UtcNow.ToString('o'); Actor = [string]$env:USERNAME; Mode = [string]$State.Mode; TenantId = [string]$State.TenantId; Device = $snapshot; Job = $Job; DocumentContext = (ConvertTo-NormalisedValue -Value $DocumentContext); Diagnostic = $message }
    $entryJob = if ($Job) { $Job } else { @{ JobId = $attempt.AttemptId } }
    $entry = @{ Job = $entryJob; Handle = @{ Status = 'FailedBeforeQueue'; JobDirectory = '' }; Result = @{ Status = 'FailedBeforeQueue'; Results = @(); Diagnostic = $message }; Failure = $attempt; FailurePath = '' }
    $State.Jobs = @($State.Jobs) + , $entry
    try {
        $directory = Get-DeviceDocumentAttemptDirectory -State $State
        $path = Join-Path $directory ('{0}.json' -f $attempt.AttemptId)
        if (Test-Path -LiteralPath $path) { throw 'Document failure identity is already occupied; no evidence was overwritten.' }
        $json = $attempt | ConvertTo-Json -Depth 40
        if ([Text.Encoding]::UTF8.GetByteCount($json) -gt 4194304) { throw 'Document failure exceeds the bounded evidence size; the session copy is retained.' }
        Write-Utf8File -Path $path -Content $json
        $entry.FailurePath = $path
        $entry.Handle.JobDirectory = $directory
        Write-AutopilotExpressLog -Message ('Document failure retained: serial={0}; CI={1}; attempt={2}; evidence={3}; {4}' -f $snapshot.Serial, $snapshot.ConfigItem, $attempt.AttemptId, $path, $message) -Level 'WARN'
    }
    catch { Write-AutopilotExpressLog -Message ('Document failure retained in this session only; durable evidence could not be saved: {0}. Original failure: {1}' -f $_.Exception.Message, $message) -Level 'ERROR' }
    return $entry
}

function Start-DeviceDocumentJob {
    <#
    .SYNOPSIS
        Queue detached output after committed dispatch, never as part of its transaction.
    .PARAMETER Device
        The successfully persisted and published workflow, not an unsaved proposal.
    .OUTPUTS
        Host diagnostic only. Failures never undo dispatch or replay tenant actions.
    #>
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'None')]
    param([Parameter(Mandatory)][Collections.IDictionary]$Device)
    $state = Get-Variable -Name DocumentSession -Scope Script -ValueOnly -ErrorAction SilentlyContinue
    if (-not $state -or -not $state.Enabled) { return }
    $job = $null
    $context = @{ SiteName = ''; TechnicianDisplayName = ''; TechnicianGivenName = ''; TechnicianSurname = ''; AssignedUserGivenName = ''; AssignedUserSurname = '' }
    if ($Script:GraphSession.Connected -and $Script:GraphSession.DisplayName -and $Script:GraphSession.DisplayName -ine $Script:GraphSession.Account) { $context.TechnicianDisplayName = [string]$Script:GraphSession.DisplayName }
    try {
        $site = @($Script:Sites | Where-Object { $_.Code -eq $Device.SiteCode })
        if ($site.Count -eq 1) { $context.SiteName = [string]$site[0].Name }
        if (-not $state.PrerequisitesReady) { throw 'Check optional document prerequisites in Settings before document generation.' }
        if ($site.Count -ne 1) { throw 'Document site must resolve to one full configured site name.' }
        $job = New-AutopilotDocumentJob -Device $Device -Settings $state.Settings -Mode $state.Mode -TenantId $state.TenantId -DocumentContext $context
        if ($null -eq $job -or -not $PSCmdlet.ShouldProcess($job.JobId, 'Queue independent post-dispatch documents')) { return }
        $expiry = Invoke-AutopilotDocumentCleanup -JobRoot $job.JobRoot -FailedJobRetentionDays $state.Settings.Values.FailedJobRetentionDays
        if ($expiry.Moved) { Write-Host ('Document housekeeping: {0} expired failure assets reversibly archived; evidence retained.' -f $expiry.Moved) }
        if ($expiry.Removed) { Write-Host ('Document housekeeping: {0} owned successful-job temporary files removed; final PDFs and compact receipts retained.' -f $expiry.Removed) }
        $handle = Start-AutopilotDocumentJob -Job $job -DependencyRoot (Join-Path $state.Settings.Values.LocalRoot 'Dependencies') -ReviewOnly:$false -EnforceDocumentGuards:([bool]$state.Settings.Values.EnforceDocumentGuards) -PreparedWorker $state['Preparation']
        if (-not $handle) { throw 'Document worker returned no handle. The dispatch remains committed; retain this attempt for document-only recovery.' }
        if ($state['Preparation'] -and $state['Preparation']['Status'] -eq 'Consumed') { $state['Preparation'] = $null }
        if ($handle) { $state.Jobs += , @{ Job = $job; Handle = $handle; Result = $null }; Write-Host ('Document job queued: {0}. Dispatch remains committed. Template approval enforcement: {1}.' -f $job.JobId, $state.Settings.Values.EnforceDocumentGuards) }
    }
    catch {
        if (-not $WhatIfPreference) { $null = Save-DeviceDocumentFailure -State $state -Device $Device -Job $job -DocumentContext $context -Diagnostic $_.Exception.Message }
        Write-Host ('Optional documents not queued: {0} Dispatch remains committed; use document-only controls, not redispatch.' -f $_.Exception.Message)
    }
}

function Get-DocumentJobFeedbackContext {
    <#
    .SYNOPSIS
        Identify the device and build cycle that a document job belongs to.
    .DESCRIPTION
        Prefers the saved inventory record (position, serial and CI via Get-DeviceFeedbackContext);
        falls back to the serial captured in the job fields when the record is not loaded.
        The build-cycle ID is always appended so repeated cycles for one serial stay distinct.
    .PARAMETER Job
        Detached document job (JobId, RecordId, BuildCycleId and Fields).
    .OUTPUTS
        Plain-text context string; read-only, no workflow state is changed.
    #>
    param([Parameter(Mandatory)][System.Collections.IDictionary]$Job)
    $inventory = Get-Variable -Name InventoryRecords -Scope Script -ValueOnly -ErrorAction SilentlyContinue
    $record = $null
    if ($Job['RecordId'] -and $inventory -and $null -ne $inventory.Value) {
        $record = @($inventory.Value | Where-Object { $_ -is [System.Collections.IDictionary] -and $_['RecordId'] -ceq $Job['RecordId'] }) | Select-Object -First 1
    }
    $device = if ($record) { Get-DeviceFeedbackContext -Device $record }
    elseif ($Job['Fields'] -is [System.Collections.IDictionary] -and $Job['Fields']['SerialNumberOrServiceTag']) { 'Serial={0}' -f $Job['Fields']['SerialNumberOrServiceTag'] }
    else { 'Documents' }
    if ($Job['BuildCycleId']) { return '{0} | Cycle={1}' -f $device, $Job['BuildCycleId'] }
    return $device
}

function Receive-DeviceDocumentJob {
    <#
    .SYNOPSIS
        Collect completed optional jobs without blocking menu or scanner input.
    .PARAMETER FeedbackState
        Optional screen-owned feedback dictionary (for example the build bench). When supplied,
        each finished job becomes one retained event (device, cycle, outcome and full detail) so
        the result survives screen redraws; nothing is written to the host directly. When
        omitted, results are written to the host exactly as before.
    .OUTPUTS
        Contextual feedback; no prompts, Graph calls or workflow writes.
    #>
    param([System.Collections.IDictionary]$FeedbackState)
    $state = Get-Variable -Name DocumentSession -Scope Script -ValueOnly -ErrorAction SilentlyContinue
    if (-not $state) { return }
    if ($state['Preparation'] -and $state['Preparation']['Status'] -eq 'Preparing') {
        $preparationResult = Receive-AutopilotDocumentJob -Handle $state['Preparation']
        if ($preparationResult.Status -ne 'Preparing') {
            $preparationText = 'Document preparation ended; dispatch will use a cold worker. Recheck prerequisites in Settings to prepare again.'
            if ($FeedbackState) { Add-ScreenFeedback -State $FeedbackState -Text @($preparationText) -Context 'Documents' }
            else { Write-Host $preparationText }
        }
    }
    foreach ($entry in $state.Jobs) {
        if ($null -ne $entry.Result) { continue }
        $result = Receive-AutopilotDocumentJob -Handle $entry.Handle
        if ($result.Status -eq 'Running') { continue }
        $entry.Result = $result
        $lines = @('Document job {0}: {1}. No physical printing or manual Save As is inferred.' -f $entry.Job.JobId, $result.Status)
        foreach ($output in @($result.Results)) { $lines += '  {0}: {1}; PDF {2}; {3}' -f $output['DocumentType'], $output['Status'], $output['PdfPath'], $output['Message'] }
        foreach ($output in @($result.Results)) {
            if ($output['TemplateRevalidated']) { $lines += '  {0}: edited template structurally revalidated for this job.' -f $output['DocumentType'] }
            foreach ($warning in @($output['ValidationWarnings'] | Where-Object { $_ })) { $lines += '  Minor template issue: {0}' -f $warning }
            if ($output['Status'] -eq 'Failed') { $lines += '  Document skipped. Correct the reported template/problem, then use Settings > Documents > Jobs for a document-only retry. Dispatch is unchanged.' }
        }
        if ($result['Diagnostic']) { $lines += '  {0}' -f $result['Diagnostic'] }
        if (-not $FeedbackState) { foreach ($line in $lines) { Write-Host $line }; continue }
        # BENCH-DOC-FEEDBACK: one complete event per job. The first line is the compact
        # bench summary (per-document outcomes); the remaining lines are the [L] detail.
        $outcomes = @(@($result.Results) | ForEach-Object { '{0} {1}' -f $_['DocumentType'], $_['Status'] })
        $summary = if ($outcomes.Count) { 'Documents {0}: {1}' -f $result.Status, ($outcomes -join '; ') } else { 'Documents {0}' -f $result.Status }
        $jobContext = Get-DocumentJobFeedbackContext -Job $entry.Job
        Add-ScreenFeedback -State $FeedbackState -Text @((@($summary) + $lines) -join "`n") -Context $jobContext
    }
    if ($state.Enabled -and $state['PrerequisitesReady'] -and -not $state['Preparation'] -and -not @($state.Jobs | Where-Object { $null -eq $_.Result }).Count) {
        try {
            Write-AutopilotExpressLog -Message 'Document preparation: entering template staging and Desktop PowerShell supervisor launch; the child may activate Word. No device data or delivery is requested.' -Level INFO
            $state['Preparation'] = Start-AutopilotDocumentJob -PreparationSettings $state.Settings -DependencyRoot (Join-Path $state.Settings.Values.LocalRoot 'Dependencies')
            if ($state['Preparation']) { Write-AutopilotExpressLog -Message ('Document preparation: supervisor launch returned; status={0}. No physical printing or delivery is inferred.' -f $state['Preparation']['Status']) -Level INFO }
        }
        catch { $state['Preparation'] = @{ Status = 'Failed' }; Write-AutopilotExpressLog -Message ('Document preparation unavailable: {0}. Dispatch remains available using a cold worker.' -f $_.Exception.Message) -Level WARN }
    }
}

function Request-DeviceDocumentReprint {
    <#
    .SYNOPSIS
        Generate fresh documents for a saved dispatch without redispatch or tenant writes.
    .PARAMETER Device
        Explicitly selected completed record; original dispatch dates and evidence remain intact.
    .PARAMETER Records
        Saved records, used only for separately confirmed legacy cycle-identity repair.
    .OUTPUTS
        Accessible queue status. Output selection is session-local to this request.
        Printing requires default-No consent; each request gets a new document job identity.
    #>
    param(
        [Parameter(Mandatory)][Collections.IDictionary]$Device,
        [Parameter(Mandatory)][hashtable]$Records
    )
    if ($Device.Status -cne 'completed' -or -not $Device.DispatchConfirmed) {
        Write-Host 'Documents require an existing confirmed dispatch. This action never dispatches a device or changes its completion evidence.'
        return
    }
    Write-Host ('Documents for serial {0}, CI {1}; original dispatch {2}.' -f $Device.Serial, $Device.ConfigItem, $Device.DispatchedAt)
    Write-Host '[B] Birth certificate'
    Write-Host '[C] Checklist'
    Write-Host '[A] Both documents'
    Write-Host '[0] Return without generating documents'
    $type = Read-ValidatedInput -Prompt 'Document selection' -Default '0' -Type Choice -Choices @('0', 'B', 'C', 'A')
    if ($type -eq '0') { return }
    Write-Host '[G] Generate PDFs only'
    Write-Host '[P] Generate and request printing (may repeat a previous print request)'
    Write-Host '[0] Return without generating documents'
    $delivery = Read-ValidatedInput -Prompt 'Document delivery' -Default '0' -Type Choice -Choices @('0', 'G', 'P')
    if ($delivery -eq '0') { return }
    if ($delivery -ieq 'P') {
        $consent = Read-ValidatedInput -Prompt 'Request printing of these documents? Physical printing cannot be confirmed by this script [Y] Yes [N] No' -Default 'N' -Type Choice -Choices @('Y', 'N')
        if ($consent -ine 'Y') { return }
    }
    try {
        if (-not (Request-DeviceDocumentReadiness -LoadModule)) { return }
        $state = $Script:DocumentSession
        if (-not $state.Settings -or $state['Suppressed']) { return }
        if ($state.Mode -eq 'Live' -and [string]$Device.TenantId -ine [string]$state.TenantId) { throw 'The saved dispatch belongs to a different tenant; no identity or document was changed.' }
        if ([string]::IsNullOrWhiteSpace([string]$Device.BuildCycleId)) {
            $consent = Read-ValidatedInput -Prompt 'This legacy record has no build-cycle ID. Save a new identity with an audit note (no steps or dispatch dates changed)? [Y] Yes [N] No' -Default 'N' -Type Choice -Choices @('Y', 'N')
            if ($consent -ine 'Y') { return }
            $proposal = ConvertTo-NormalisedValue -Value @($Records.Value)
            $matchesFound = @($proposal | Where-Object { $_.RecordId -ceq $Device.RecordId -and $_.Serial -ceq $Device.Serial })
            if ($matchesFound.Count -ne 1 -or $matchesFound[0].BuildCycleId) { throw 'Legacy identity repair requires one unchanged saved record.' }
            $repaired = $matchesFound[0]
            $repaired.BuildCycleId = [guid]::NewGuid().ToString('D')
            $repaired.RecoveryHistory = @($repaired.RecoveryHistory) + , @{
                Stage = 'LegacyBuildCycleIdentity'; Actor = $env:USERNAME; Timestamp = Get-Date -Format o
                Reason = 'Assigned missing cycle identity for document generation; prior workflow evidence and dispatch dates unchanged.'
                BuildCycleId = $repaired.BuildCycleId
            }
            Write-UserDeviceRecords -Records $proposal
            $Device.BuildCycleId = $repaired.BuildCycleId
            $Device.RecoveryHistory = $repaired.RecoveryHistory
            $Records.Value = $proposal
            Write-AutopilotExpressLog -Message ('Saved missing build-cycle identity for record {0}; no completion evidence was upgraded.' -f $Device.RecordId) -Level INFO
        }
        $original = @{}
        foreach ($key in @('Session', 'Settings', 'Enabled', 'Suppressed', 'PrerequisitesReady', 'PrerequisiteResult')) { $original[$key] = $state[$key] }
        try {
            $state.Session = @{}
            foreach ($key in $original.Session.Keys) { $state.Session[$key] = $original.Session[$key] }
            foreach ($documentType in @('BirthCertificate', 'Checklist')) {
                $selected = $type -ieq 'A' -or ($type -ieq 'B' -and $documentType -eq 'BirthCertificate') -or ($type -ieq 'C' -and $documentType -eq 'Checklist')
                $state.Session[('{0}Enabled' -f $documentType)] = $selected
                $state.Session[('{0}Mode' -f $documentType)] = if ($delivery -ieq 'P') { 'AutoPrint' } else { 'GenerateOnly' }
            }
            # Explicit CLI pins remain authoritative; refuse a conflicting selection.
            foreach ($key in $state.Session.Keys) {
                if ($Script:DocumentCommandLineOverrides.Contains($key) -and $Script:DocumentCommandLineOverrides[$key] -ne $state.Session[$key]) { throw 'A command-line document pin conflicts with this selection. Release pins in document settings [9], then retry.' }
            }
            if (-not (Request-DeviceDocumentReadiness) -or -not $state.PrerequisitesReady -or -not $state.Enabled) { return }
            Start-DeviceDocumentJob -Device $Device
        }
        finally {
            foreach ($key in $original.Keys) { $state[$key] = $original[$key] }
        }
    }
    catch { Write-AutopilotExpressLog -Message ('Document generation/reprint not queued: {0}. No redispatch or tenant action was attempted.' -f $_.Exception.Message) -Level WARN }
}

function Show-DeviceDocumentSettings {
    <#
    .SYNOPSIS
        Edit session controls, release CLI pins or explicitly save per-tenant preferences.
    .DESCRIPTION
        Menu input remains foreground-only. Separate Save Preferences defaults No;
        dependency acquisition uses its existing disclosed Default-Yes consent.
        Retry reuses detached job data, never dispatch, inventory or Graph actions.
        [P] reprints documents for existing confirmed dispatches; [G] toggles guards.
    .PARAMETER Records
        Workflow record container used by [P] to list confirmed dispatches for reprint;
        when omitted, reprint reports that no records are available.
    .OUTPUTS
        Accessible settings and retained job paths; no automatic network save.
    #>
    param([hashtable]$Records)
    if (-not (Request-DeviceDocumentReadiness -LoadModule)) { return }
    $state = $Script:DocumentSession
    if (-not $state.Settings) { return }
    if ($state['Preparation']) {
        Start-AutopilotDocumentJob -DependencyRoot (Join-Path $state.Settings.Values.LocalRoot 'Dependencies') -PreparedWorker $state['Preparation'] -StopPreparation
        $state['Preparation'] = $null
    }
    while ($true) {
        Receive-DeviceDocumentJob
        $runtimeValues = if ($Script:RuntimeConfig.Contains('documentGeneration')) { $Script:RuntimeConfig['documentGeneration'] } else { @{} }
        $state.Settings = Resolve-AutopilotDocumentSettings -ScriptRoot $Script:AutopilotExpressScriptDirectory -LocalApplicationData $env:LOCALAPPDATA -RuntimeConfiguration $runtimeValues -SavedPreferences $state.Saved -SessionPreferences $state.Session -CommandLineOverrides $Script:DocumentCommandLineOverrides
        $values = $state.Settings.Values
        $state.Enabled = -not $state['Suppressed'] -and (($values.BirthCertificateEnabled -and $values.BirthCertificateMode -ne 'Disabled') -or ($values.ChecklistEnabled -and $values.ChecklistMode -ne 'Disabled'))
        $readiness = if ($state['Suppressed']) { 'Disabled for this session after failed readiness check' } elseif ($state.PrerequisitesReady) { 'Library checks passed; delivery not proven' } else { 'Not checked / not ready' }
        Write-Host ('Document readiness: {0}' -f $readiness)
        Write-Host ('[1] Birth certificate: {0}; {1}; source {2}' -f $values.BirthCertificateEnabled, $values.BirthCertificateMode, $state.Settings.Sources.BirthCertificateEnabled)
        Write-Host ('[2] Checklist: {0}; {1}; source {2}' -f $values.ChecklistEnabled, $values.ChecklistMode, $state.Settings.Sources.ChecklistEnabled)
        Write-Host '[3] Certificate policy'
        Write-Host '[4] Checklist policy'
        Write-Host ('[5] Worker timeout: {0}s' -f $values.WorkerTimeoutSeconds)
        Write-Host ('[6] Failed-job asset retention: {0} days (0 disables expiry)' -f $values.FailedJobRetentionDays)
        Write-Host '[7] Check disclosed prerequisites'
        Write-Host '[8] Save Preferences (separate confirmation, default No)'
        Write-Host '[9] Release command-line pins'
        $guardLabel = if ($values.EnforceDocumentGuards) { 'ON' } else { 'OFF' }
        Write-Host ('[G] Template approval guards: {0}; source {1} (OFF by default for testing; both documents)' -f $guardLabel, $state.Settings.Sources.EnforceDocumentGuards)
        Write-Host '[J] Review jobs/document-only retry'
        if ($null -ne $Records) { Write-Host '[P] Generate/reprint documents for an existing dispatched device' }
        Write-Host '[0] Return'
        $choices = @('0', '1', '2', '3', '4', '5', '6', '7', '8', '9', 'G', 'J')
        if ($null -ne $Records) { $choices += 'P' }
        $choice = Read-ValidatedInput -Prompt 'Document setting ([0] returns)' -Default '0' -Type Choice -Choices $choices
        $recheck = $false
        switch ($choice.ToUpperInvariant()) {
            '0' { Receive-DeviceDocumentJob; return }
            '1' { $state.Session.BirthCertificateEnabled = -not $values.BirthCertificateEnabled; $recheck = $true }
            '2' { $state.Session.ChecklistEnabled = -not $values.ChecklistEnabled; $recheck = $true }
            { $_ -in @('3', '4') } {
                $key = if ($_ -eq '3') { 'BirthCertificateMode' } else { 'ChecklistMode' }
                $selected = Read-ValidatedInput -Prompt 'Policy: Disabled, GenerateOnly, Review, GenerateAndAsk, AutoPrint' -Default $values[$key] -Type Choice -Choices @('Disabled', 'GenerateOnly', 'Review', 'GenerateAndAsk', 'AutoPrint')
                $state.Session[$key] = @('Disabled', 'GenerateOnly', 'Review', 'GenerateAndAsk', 'AutoPrint') | Where-Object { $_ -ieq $selected }
                $recheck = $true
            }
            { $_ -in @('5', '6') } {
                $key = if ($_ -eq '5') { 'WorkerTimeoutSeconds' } else { 'FailedJobRetentionDays' }
                $minimum = if ($_ -eq '5') { 1 } else { 0 }; $maximum = if ($_ -eq '5') { 3600 } else { 3650 }
                $selected = Read-ValidatedInput -Prompt ('Integer {0}-{1}' -f $minimum, $maximum) -Default ([string]$values[$key])
                $number = 0
                if ([int]::TryParse($selected, [ref]$number) -and $number -ge $minimum -and $number -le $maximum) { $state.Session[$key] = $number; $recheck = $true }
                else { Write-Host ('Invalid value; enter a whole number between {0} and {1}. No setting changed.' -f $minimum, $maximum) }
            }
            '7' {
                $recheck = $true
                if ($state['Preparation'] -and $state['Preparation']['Status'] -in @('Failed', 'Collected')) { $state['Preparation'] = $null }
            }
            '8' {
                $answer = Read-ValidatedInput -Prompt 'Save these document preferences for this technician/mode/tenant? [Y] Yes [N] No' -Default 'N' -Type Choice -Choices @('Y', 'N')
                if ($answer -ieq 'Y') {
                    $savedValues = @{}; foreach ($key in $state.Session.Keys) { $savedValues[$key] = $state.Session[$key] }
                    foreach ($key in $state.Saved.Keys) { if (-not $savedValues.Contains($key)) { $savedValues[$key] = $state.Saved[$key] } }
                    $document = @{ SchemaVersion = 1; Mode = $state.Mode; TenantId = $state.TenantId; Actor = $env:USERNAME; Values = $savedValues }
                    Write-Utf8File -Path $state.PreferencePath -Content ($document | ConvertTo-Json -Depth 8)
                    $state.Saved = $savedValues
                    Write-Host 'Document preferences saved. Command-line pins remain session-only.'
                    $recheck = $true
                }
            }
            '9' { $Script:DocumentCommandLineOverrides = @{}; Write-Host 'Command-line document pins released for this session.'; $recheck = $true }
            'G' {
                if ($Script:DocumentCommandLineOverrides.Contains('EnforceDocumentGuards')) { Write-Host 'Template approval guards are pinned by the command line. Use [9] to release pins before changing this setting.' }
                else { $state.Session.EnforceDocumentGuards = -not $values.EnforceDocumentGuards; $recheck = $true }
            }
            'P' {
                $selected = Select-DeviceFromRecords -Records $Records -Purpose 'generate/reprint documents (completed dispatch required)' -IncludeCompleted
                if ($null -ne $selected) { Request-DeviceDocumentReprint -Device $selected -Records $Records }
            }
            'J' {
                # DOC-HISTORY: merge retained prequeue failures and validated historical receipts
                # into the session list once (deduplicated by JobId); each source fails independently.
                foreach ($source in @('Read-DeviceDocumentFailure', 'Read-DeviceDocumentHistory')) {
                    try {
                        foreach ($retained in @(& $source -State $state)) {
                            if (-not @($state.Jobs | Where-Object { $_.Job.JobId -ieq $retained.Job.JobId }).Count) { $state.Jobs += , $retained }
                        }
                    }
                    catch { Write-AutopilotExpressLog -Message ('Document job discovery ({0}) unavailable: {1}' -f $source, $_.Exception.Message) -Level 'WARN' }
                }
                $historyLimit = 20
                $history = @($state.Jobs | Where-Object { $_['History'] })
                foreach ($entry in @($state.Jobs | Where-Object { -not $_['History'] })) {
                    Write-Host ('{0}: {1}; retained local job {2}' -f $entry.Job.JobId, $entry.Handle.Status, $entry.Handle.JobDirectory)
                    if ($entry['Failure']) { Write-Host ('  Serial={0}; CI={1}; dispatch={2}; {3}' -f $entry.Failure.Device.Serial, $entry.Failure.Device.ConfigItem, $entry.Failure.Device.DispatchedAt, $entry.Failure.Diagnostic) }
                }
                if ($history.Count) {
                    Write-Host ('Completed document jobs (newest {0} of {1}; select one to generate fresh documents for that cycle):' -f [Math]::Min($historyLimit, $history.Count), $history.Count)
                    foreach ($entry in @($history | Sort-Object { $_.SortDate } -Descending | Select-Object -First $historyLimit)) {
                        $outcomes = @(@($entry.Result.Results) | ForEach-Object { '{0} {1}' -f $_['DocumentType'], $_['Status'] }) -join '; '
                        Write-Host ('{0}: completed {1}; Serial={2}; CI={3}; {4}' -f $entry.Job.JobId, $entry.SortDate.ToLocalTime().ToString('yyyy-MM-dd HH:mm'), $entry.Job.Fields.SerialNumberOrServiceTag, $entry.Job.Fields.ConfigurationItem, $outcomes)
                    }
                }
                if ($null -ne $Records) {
                    $documentedCycles = @($state.Jobs | ForEach-Object { [string]$_.Job['BuildCycleId'] } | Where-Object { $_ })
                    $undocumented = @(@($Records.Value) | Where-Object { $_.Status -ceq 'completed' -and $_.DispatchConfirmed -and ($state.Mode -ceq 'Demo' -or [string]$_.TenantId -ieq [string]$state.TenantId) -and ([string]::IsNullOrWhiteSpace([string]$_.BuildCycleId) -or $documentedCycles -notcontains [string]$_.BuildCycleId) })
                    if ($undocumented.Count) {
                        Write-Host ('Completed dispatches with no document job found ({0}); use [P] to generate documents:' -f $undocumented.Count)
                        foreach ($record in @($undocumented | Select-Object -First 10)) { Write-Host ('  Serial={0}; CI={1}; dispatched {2}' -f $record.Serial, $record.ConfigItem, $record.DispatchedAt) }
                        if ($undocumented.Count -gt 10) { Write-Host ('  ...and {0} more.' -f ($undocumented.Count - 10)) }
                    }
                }
                if (-not $state.Jobs.Count) { Write-Host 'No retained document jobs, receipts or prequeue failures were found for this actor, mode and tenant.'; break }
                $identifier = Read-ValidatedInput -Prompt 'Job ID for explicit document-only retry, or 0 to return' -Default '0'
                if ($identifier -eq '0') { break }
                $matchesFound = @($state.Jobs | Where-Object { $_.Job.JobId -ieq $identifier -and $_.Handle.Status -ne 'Running' })
                if ($matchesFound.Count -ne 1) { Write-Host 'Choose exactly one completed retained job ID; running jobs cannot be replayed.'; break }
                if ($matchesFound[0]['History']) {
                    # Historical receipts are never replayed under their old JobId; generate fresh
                    # documents for the same saved cycle through the existing reprint path instead.
                    $receiptJob = $matchesFound[0].Job
                    $savedRecords = @(if ($null -ne $Records) { @($Records.Value) | Where-Object { $_.RecordId -ceq $receiptJob.RecordId -and [string]$_.BuildCycleId -ceq $receiptJob.BuildCycleId } })
                    if ($savedRecords.Count -ne 1) { Write-Host 'The saved record for this receipt is not loaded or has started a new build cycle. Use [P] to choose the current dispatch; nothing was changed.'; break }
                    Request-DeviceDocumentReprint -Device $savedRecords[0] -Records $Records
                    break
                }
                $answer = Read-ValidatedInput -Prompt 'Retry document generation/delivery only? May repeat a prior PDF print request. [Y] Yes [N] No' -Default 'N' -Type Choice -Choices @('Y', 'N')
                if ($answer -ieq 'Y') {
                    $entry = $matchesFound[0]
                    try {
                        if (-not $state.PrerequisitesReady) { throw 'Recheck document prerequisites before a document-only retry.' }
                        $retryJob = $entry.Job
                        if ($entry['Failure']) {
                            $retryJob = New-AutopilotDocumentJob -Device $entry.Failure.Device -Settings $state.Settings -Mode $state.Mode -TenantId $state.TenantId -DocumentContext $entry.Failure.DocumentContext
                            if (-not $retryJob) { throw 'Enable a document output before retrying retained failure evidence.' }
                            $retryJob.JobDirectoryName = $retryJob.JobDirectoryName.Replace([string]$retryJob.JobId, [string]$entry.Job.JobId)
                            $retryJob.JobId = $entry.Job.JobId
                        }
                        $retryHandle = Start-AutopilotDocumentJob -Job $retryJob -DependencyRoot (Join-Path $state.Settings.Values.LocalRoot 'Dependencies') -ReviewOnly:$false -EnforceDocumentGuards:([bool]$state.Settings.Values.EnforceDocumentGuards) -ExplicitRetry -PrintApproved
                        if (-not $retryHandle) { throw 'Document retry returned no worker handle; retained evidence is unchanged.' }
                        $entry.Job = $retryJob; $entry.Handle = $retryHandle; $entry.Result = $null
                    }
                    catch { Write-AutopilotExpressLog -Message ('Document-only retry was not queued: {0}. Retained evidence and dispatch are unchanged.' -f $_.Exception.Message) -Level 'WARN' }
                }
            }
        }
        if ($recheck -and -not (Request-DeviceDocumentReadiness)) { return }
    }
}

function Complete-DeviceDispatch {
    <#
    .SYNOPSIS
        Save normal or administrative completion and bench removal together.
    .DESCRIPTION
        Overrides retain unresolved steps and recovery snapshots in history, not
        fabricated Verified results. Detached proposals use the existing checkpoint
        writer; failed saves propagate without replacing caller-owned state.
    .PARAMETER Records
        Current session collection owning Device.
    .PARAMETER Device
        Selected workflow record, retained after dispatch.
    .PARAMETER Override
        Require a reason and explicit Y; active recovery may close administratively.
    .OUTPUTS
        Completed and contextual Summary, emitted only after persistence succeeds.
    #>
    param(
        [Parameter(Mandatory)][hashtable]$Records,
        [Parameter(Mandatory)][System.Collections.IDictionary]$Device,
        [switch]$Override
    )
    $context = Get-DeviceFeedbackContext -Device $Device
    if (@($Records.Value) -notcontains $Device -or $Device.Status -eq 'removed') {
        return @{ Completed = $false; Summary = '{0}: device is not available for dispatch.' -f $context }
    }
    $readiness = Test-DeviceReadyForDispatch -Device $Device
    if (-not $Override -and -not $readiness.Ready) {
        return @{ Completed = $false; Summary = 'Cannot dispatch device in {0}. Complete required step(s): {1}.' -f $context, ($readiness.BlockingStepIds -join ', ') }
    }
    $reason = ''
    if ($Override) {
        Write-Host ('{0}: override closes the active workload, not tenant recovery or step verification. Unresolved steps: {1}. Recovery active: {2}.' -f $context, ($readiness.BlockingStepIds -join ', '), $Device.RecoveryActive)
        $reason = (Read-ValidatedInput -Prompt 'Required completion override reason ([0] Cancel)' -Default '0').Trim()
        if (-not $reason -or $reason -eq '0') { return @{ Completed = $false; Summary = '{0}: completion override cancelled.' -f $context } }
    }
    $prompt = if ($Override) { 'Confirm administrative completion override? [Y] Yes [N] No' } else { 'Confirm dispatch? [Y] Yes [N] No' }
    $confirmed = Read-ValidatedInput -Prompt $prompt -Default 'N' -Type Choice -Choices @('Y', 'N')
    if ($confirmed -ine 'Y') { return @{ Completed = $false; Summary = '{0}: dispatch not confirmed; workflow retained.' -f $context } }

    $proposedRecords = ConvertTo-NormalisedValue -Value @($Records.Value)
    $proposal = $proposedRecords | Where-Object { $_.Serial -eq $Device.Serial } | Select-Object -First 1
    $null = Invoke-DeviceInventoryCheck -Device $proposal -Force
    $missingInventory = @()
    foreach ($field in @('IntuneHostName', 'EthernetMacAddress')) { if (-not $proposal.IntuneInventory[$field]) { $missingInventory += $field } }
    $now = Get-Date
    $proposal.Status = 'completed'
    $proposal.IsCompletionVerified = -not [bool]$Override
    $proposal.CompletedAt = $now
    $proposal.DispatchedAt = $now
    $proposal.DispatchConfirmed = $true
    $proposal.CompletedBy = $env:USERNAME
    $proposal.LastUpdatedAt = $now
    $proposal.LastUpdatedBy = $env:USERNAME
    if ($Override) {
        $proposal.RecoveryHistory = @($proposal.RecoveryHistory) + , @{
            Stage = 'CompletionOverride'; Actor = $env:USERNAME; Timestamp = Get-Date -Date $now -Format o
            Reason = $reason; RecoveryActive = [bool]$Device.RecoveryActive
            UnresolvedStepIds = @($readiness.BlockingStepIds)
            Steps = ConvertTo-NormalisedValue -Value $Device.Steps
            CompletionState = 'AuditedException'
        }
    }
    $originalBench = $Script:BuildBench
    $proposedBench = ConvertTo-NormalisedValue -Value $originalBench
    foreach ($slot in $proposedBench.Positions) {
        if ($slot.Serial -eq $Device.Serial) { $slot.Serial = $null; $slot.ConfigItem = $null }
    }
    $saved = $false
    try {
        $Script:BuildBench = $proposedBench
        Write-UserDeviceRecords -Records $proposedRecords
        $saved = $true
    }
    finally { if (-not $saved) { $Script:BuildBench = $originalBench } }
    foreach ($field in @('Status', 'IsCompletionVerified', 'CompletedAt', 'CompletedBy', 'DispatchedAt', 'DispatchConfirmed', 'LastUpdatedAt', 'LastUpdatedBy', 'RecoveryHistory', 'IntuneInventory')) {
        $Device[$field] = $proposal[$field]
    }
    $documentSession = Get-Variable -Name DocumentSession -Scope Script -ValueOnly -ErrorAction SilentlyContinue
    if ($documentSession -and $documentSession.Enabled) {
        try { Start-DeviceDocumentJob -Device $Device }
        catch { Write-Host ('Optional document job failed after dispatch was committed: {0}. Do not redispatch to retry documents.' -f $_.Exception.Message) }
    }
    else {
        Write-Host 'No documents generated: document output is disabled for this session. Use Settings > Document output settings (6) to enable output and check prerequisites before the next dispatch. No document job was created; do not redispatch to retry documents.'
    }
    $description = if ($Override) { 'administratively completed by override; unresolved evidence retained, not Verified' } else { 'dispatched; required workflow evidence complete' }
    if ($missingInventory.Count -and -not $Script:Runtime.IsDemoMode) { $description += '; WARNING: final inventory attempt could not obtain {0}. Missing data retained; dispatch allowed by policy' -f ($missingInventory -join ', ') }
    elseif ($proposal.IntuneInventory.Status -eq 'Error') { $description += '; WARNING: final inventory read failed; previously captured same-cycle values retained' }
    return @{ Completed = $true; Summary = '{0}: {1}.' -f $context, $description }
}

function Test-DeviceReadyForDispatch {
    <#
    .SYNOPSIS
        Check completion evidence for all applicable dispatch requirements.
    .PARAMETER Device
        Current selected workflow record.
    .OUTPUTS
        Ready and BlockingStepIds dictionary. Dispatch confirmation/override remain separate;
        this check does not certify external checklist handoffs.
    #>
    param([Parameter(Mandatory)]$Device)

    $blockingSteps = @(Get-DispatchBlockingManifestSteps -Device $Device)
    return [ordered]@{ Ready = ($blockingSteps.Count -eq 0); BlockingStepIds = @($blockingSteps | ForEach-Object { $_.Id }) }
}

function Add-DeviceToBenchPosition {
    <#
    .SYNOPSIS
        Validate a free slot and identity before attaching a new or retained device record.
    .PARAMETER Position
        Existing empty position number; occupied slots cannot be overwritten.
    .PARAMETER Serial
        Validated serial of the proposed device.
    .PARAMETER ConfigItem
        Configuration item identity for the record.
    .PARAMETER Records
        Shared current-session record container.
    .PARAMETER SiteCode
        Selected configured site.
    .PARAMETER DeviceType
        Selected configured hardware category.
    .OUTPUTS
        None. Persists a validated checkpoint before promoting state. Reused records retain
        their original identity, timestamps and evidence.
    #>
    param([int]$Position, [string]$Serial, [string]$ConfigItem, [hashtable]$Records, [string]$SiteCode, [string]$DeviceType)
    $slot = $Script:BuildBench.Positions | Where-Object { $_.Index -eq $Position }; if (-not $slot) { Write-Host 'Invalid position.'; return }
    if ($slot.Serial) { Write-Host 'The selected bench position is occupied. Choose an empty position.'; return }
    if (@($Script:BuildBench.Positions | Where-Object { $_.Serial -eq $Serial }).Count -gt 0) {
        Write-Host 'This serial is already on the bench. Use Move to change its position.'
        return
    }
    $existing = @($Records.Value | Where-Object { $_.Serial -eq $Serial })
    if ($existing.Count -gt 1) { Write-Host 'Multiple workflow records match this serial. Resolve the duplicate records before induction.'; return }
    if ($existing.Count -eq 1) {
        if ($existing[0].Status -eq 'removed') { Write-Host 'This workflow record is removed. Restore its status before returning it to the bench.'; return }
        if ($existing[0].ConfigItem -ne $ConfigItem -or $existing[0].SiteCode -ne $SiteCode -or $existing[0].DeviceType -ne $DeviceType) {
            Write-Host 'Serial metadata differs from the existing workflow. Induct using its recorded Configuration Item, site and device type.'
            return
        }
    }
    if (@($Records.Value | Where-Object { $_.Serial -ne $Serial -and $_.ConfigItem -eq $ConfigItem -and $_.Status -ne 'removed' }).Count -gt 0) {
        Write-Host 'This Configuration Item belongs to another active workflow. Resolve the conflict before induction.'
        return
    }
    if ($existing.Count -eq 0) {
        $expectedTag = ('{0}-{1}' -f $SiteCode, ($DeviceType -replace '\s', ''))
        $rec = New-DeviceRecordObject -Serial $Serial -ConfigItem $ConfigItem -SiteCode $SiteCode -DeviceType $DeviceType -GroupTag $expectedTag
        Add-DeviceRecord -Records $Records -Record $rec
    }
    $slot.Serial = $Serial; $slot.ConfigItem = $ConfigItem
    Write-UserDeviceRecords -Records $Records.Value
}

function Remove-DeviceFromBenchPosition {
    <#
    .SYNOPSIS
        Clear an existing in-memory slot without deleting its retained device record.
    .PARAMETER Position
        Existing position number; an unknown position is reported and left unchanged.
    .OUTPUTS
        None. Clears Serial and ConfigItem only; caller owns persistence and dispatch checks.
    #>
    param([int]$Position)
    $slot = $Script:BuildBench.Positions | Where-Object { $_.Index -eq $Position }
    if (-not $slot) { Write-Host 'Invalid position.'; return }
    $slot.Serial = $null
    $slot.ConfigItem = $null
}

# Ensure that any devices shown in the bench positions exist in the per-user records
function Assert-BenchPositionIdentity {
    <#
    .SYNOPSIS
        Reject ambiguous saved positions before serial or CI selection.
    .PARAMETER Positions
        Bench positions to validate; empty positions and an empty bench are valid.
    .DESCRIPTION
        Requires unique positive position numbers and unambiguous occupied serial/CI
        identities. It never repairs, discards or combines the operator's saved data.
    .OUTPUTS
        None. Rejects ambiguous or conflicting occupied-slot identity before a checkpoint write.
    #>
    param([AllowEmptyCollection()][System.Collections.IEnumerable]$Positions = @())
    $indices = @{}
    $occupiedRecords = @()
    foreach ($position in $Positions) {
        $index = [int]$position.Index
        if ($index -lt 1 -or $indices.ContainsKey($index)) { throw 'Saved bench positions have invalid or duplicate numbers. Correct the bench data before continuing.' }
        $indices[$index] = $true
        if ($position.Serial) {
            $occupiedRecords += @{ Serial = $position.Serial; ConfigItem = $position.ConfigItem; Status = 'in-progress' }
        }
        elseif ($position.ConfigItem) { throw 'A saved bench position has a Configuration Item but no serial. Correct the bench data before continuing.' }
    }
    Assert-DeviceRecordIdentity -Records $occupiedRecords
}

function Sync-BenchRecords {
    <#
    .SYNOPSIS
        Validate all bench links before creating missing workflow records or saving.
    .DESCRIPTION
        Uses trimmed, case-insensitive identities without relabelling saved records.
        Rejects conflicting links and links to removed records; a completed record may
        keep its slot until dispatch clears it. Retains records outside the bench.
    .PARAMETER Records
        Caller-owned workflow collection; invalid links leave it unchanged.
    .PARAMETER ForceSave
        Persist an explicitly created or changed bench even when no workflow records are missing.
    .OUTPUTS
        None. Reconciles validated in-memory slot references without recreating record evidence.
    #>
    param([hashtable]$Records, [switch]$ForceSave)
    if (-not $Script:BuildBench -or -not $Script:BuildBench.Positions) { return }
    $reconciliationTimer = [Diagnostics.Stopwatch]::StartNew()
    Assert-BenchPositionIdentity -Positions $Script:BuildBench.Positions
    Assert-DeviceRecordIdentity -Records $Records.Value
    $recordsBySerial = @{}
    $recordsByConfigItem = @{}
    foreach ($record in $Records.Value) {
        $recordsBySerial[([string]$record.Serial).Trim()] = $record
        $configItem = ([string]$record.ConfigItem).Trim()
        if ($record.Status -ne 'removed' -and $configItem) { $recordsByConfigItem[$configItem] = $record }
    }
    $missingSlots = @()
    foreach ($slot in $Script:BuildBench.Positions) {
        if (-not $slot.Serial) { continue }
        $serial = ([string]$slot.Serial).Trim()
        $configItem = ([string]$slot.ConfigItem).Trim()
        if (-not $configItem) {
            throw ('Bench position {0} has no Configuration Item. Correct the bench data before continuing.' -f $slot.Index)
        }
        $existing = $recordsBySerial[$serial]
        if ($existing) {
            # A completed record may legitimately keep its slot: the final step marks
            # it completed before dispatch clears the bench. Only removed links are refused.
            if ($existing.Status -eq 'removed') {
                throw ('Bench position {0} links to a {1} workflow for serial {2}. Resolve its status and bench placement before continuing.' -f $slot.Index, $existing.Status, $serial)
            }
            if (([string]$existing.ConfigItem).Trim() -ne $configItem) {
                throw ('Bench position {0} Configuration Item {1} does not match workflow serial {2}. Correct the conflicting link before continuing.' -f $slot.Index, $configItem, $serial)
            }
        }
        $configItemOwner = $recordsByConfigItem[$configItem]
        if ($configItemOwner -and ([string]$configItemOwner.Serial).Trim() -ne $serial) {
            throw ('Bench position {0} Configuration Item {1} belongs to another workflow, serial {2}. Resolve the conflict before induction.' -f $slot.Index, $configItem, ([string]$configItemOwner.Serial).Trim())
        }
        if (-not $existing) { $missingSlots += $slot }
    }
    $site = $Script:BuildBench.SiteCode
    $dtype = $Script:BuildBench.DeviceType
    foreach ($slot in $missingSlots) {
        $expectedTag = if ($site -and $dtype) { ('{0}-{1}' -f $site, ($dtype -replace '\s', '')) } else { $null }
        $rec = New-DeviceRecordObject -Serial $slot.Serial -ConfigItem $slot.ConfigItem -SiteCode $site -DeviceType $dtype -GroupTag $expectedTag
        Add-DeviceRecord -Records $Records -Record $rec
    }
    if ($missingSlots.Count -gt 0 -or $ForceSave) { Write-UserDeviceRecords -Records $Records.Value }
    Write-Verbose ('Bench reconciliation: added={0}; saved={1}; elapsed-ms={2:N2}.' -f $missingSlots.Count, ($missingSlots.Count -gt 0 -or $ForceSave), $reconciliationTimer.Elapsed.TotalMilliseconds)
}

function Show-BuildBenchTable {
    <#
    .SYNOPSIS
        Render bench positions in width-bounded chunks with current/next display codes.
    .PARAMETER Records
        Current-session container used to resolve occupied slots.
    .OUTPUTS
        Host text only; clipping/padding never changes stored identities or step IDs.
    #>
    param([hashtable]$Records)
    $renderTimer = [Diagnostics.Stopwatch]::StartNew()
    $recordsBySerial = @{}
    foreach ($record in $Records.Value) {
        $serial = [string]$record.Serial
        if (-not $serial) { continue }
        if ($recordsBySerial.ContainsKey($serial)) { throw 'Bench rendering requires unique workflow serials.' }
        $recordsBySerial[$serial] = $record
    }
    # Column widths to preserve alignment; ellipsise long content
    $labelWidth = 10
    $colWidth = 14
    function FormatCell([string]$text, [int]$width) {
        <#
        .SYNOPSIS
            Clip and right-pad one left-aligned bench cell.
        .PARAMETER text
            Display text; stored identity remains unchanged.
        .PARAMETER width
            Positive available column width calculated by the enclosing renderer.
        .OUTPUTS
            Fixed-width cell string.
        #>
        if ($null -eq $text) { $text = '' }
        $t = [string]$text
        if ($t.Length -gt $width) { $t = $t.Substring(0, $width - 1) + '…' }
        return $t.PadRight($width)
    }
    function CenterCell([string]$text, [int]$width) {
        <#
        .SYNOPSIS
            Clip and centre one bench heading within its available width.
        .PARAMETER text
            Heading text to display.
        .PARAMETER width
            Positive available column width.
        .OUTPUTS
            Fixed-width centred string; no console state changes.
        #>
        if ($null -eq $text) { $text = '' }
        $t = [string]$text
        if ($t.Length -gt $width) { $t = $t.Substring(0, $width - 1) + '…' }
        $padTotal = $width - $t.Length
        if ($padTotal -le 0) { return $t }
        $left = ($padTotal - ($padTotal % 2)) / 2
        $right = $padTotal - $left
        return ('{0}{1}{2}' -f (' ' * $left), $t, (' ' * $right))
    }
    function BuildRow([string]$label, [string[]]$values, [bool]$centerValues) {
        <#
        .SYNOPSIS
            Compose a bench row using the enclosing renderer's stable column widths.
        .PARAMETER label
            Accessible row heading.
        .PARAMETER values
            Display values for the current position chunk.
        .PARAMETER centerValues
            Centre headings instead of left-aligning device text.
        .OUTPUTS
            Complete row string with separators; does not write to the host.
        #>
        $row = '|' + ' ' + ($label.PadRight($labelWidth)) + ' '
        foreach ($v in $values) {
            $cellText = if ($centerValues) { CenterCell -text $v -width $colWidth } else { FormatCell -text $v -width $colWidth }
            $row += ('| {0} ' -f $cellText)
        }
        $row += '|'
        return $row
    }
    # Determine how many columns fit the current window
    $winWidth = Get-ConsoleTextWidth
    $baseLen = $labelWidth + 3 + 1  # label plus separators and final '|'
    $colWidth = [Math]::Max(1, [Math]::Min($colWidth, $winWidth - $baseLen - 3))
    $perCol = $colWidth + 3         # "| {col} " per column
    $maxCols = [int][Math]::Floor(($winWidth - $baseLen) / $perCol)
    if ($maxCols -lt 1) { $maxCols = 1 }
    $colsPerRow = if ($maxCols -gt 8) { 8 } else { $maxCols }
    $positions = $Script:BuildBench.Positions
    $chunks = @()
    for ($i = 0; $i -lt $positions.Count; $i += $colsPerRow) {
        $endIndex = $i + $colsPerRow - 1
        if ($endIndex -ge $positions.Count) { $endIndex = $positions.Count - 1 }
        $chunks += , (@($positions[$i..$endIndex]))
    }
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
                $rec = $recordsBySerial[[string]$slot.Serial]
                if ($rec) {
                    $hasHandlerOutcome = $false
                    for ($attemptIndex = $rec.AttemptHistory.Count - 1; $attemptIndex -ge 0; $attemptIndex--) {
                        $attempt = $rec.AttemptHistory[$attemptIndex]
                        if ($attempt.EvidenceKind -eq 'HandlerOutcome') {
                            $val = [string]$attempt.StepId
                            $hasHandlerOutcome = $true
                            break
                        }
                    }
                    if (-not $hasHandlerOutcome -and $rec.Steps.Keys.Count -gt 0) {
                        $latest = $rec.Steps.GetEnumerator() | Sort-Object @{ Expression = { ConvertTo-RecordDate -Value $_.Value.Timestamp }; Descending = $true }, Key | Select-Object -First 1
                        $val = if ((ConvertTo-RecordDate -Value $latest.Value.Timestamp) -ne [DateTime]::MinValue) { [string]$latest.Key } else { '?' }
                    }
                }
            }
            $definition = if ($val -and $val -ne '?') { Get-ManifestStepDefinition -StepId $val } else { $null }
            if ($definition) { $val = Get-WorkflowDisplayCode -Step $definition }
            $currentVals += $val
        }
        Write-Host (BuildRow -label 'Current' -values $currentVals -centerValues $false)
        $nextVals = @()
        foreach ($slot in $chunk) {
            $val = ''
            if ($slot.Serial) {
                $rec = $recordsBySerial[[string]$slot.Serial]
                if ($rec) { $val = Get-NextStepId -Device $rec }
            }
            $definition = if ($val) { Get-ManifestStepDefinition -StepId $val } else { $null }
            if ($definition) { $val = Get-WorkflowDisplayCode -Step $definition }
            $nextVals += $val
        }
        Write-Host (BuildRow -label 'Next' -values $nextVals -centerValues $false)
        Write-Host $rule
        Write-Host ''
    }
    Write-Verbose ('Bench table: records={0}; positions={1}; elapsed-ms={2:N2}.' -f $recordsBySerial.Count, $positions.Count, $renderTimer.Elapsed.TotalMilliseconds)
}

function Get-TerminalViewport {
    <#
    .SYNOPSIS
        Read usable terminal dimensions without requiring RawUI support.
    .OUTPUTS
        Width/Height dictionary; unavailable dimensions default to 120 by 40.
    #>
    $width = 120
    $height = 40
    try {
        $size = $Host.UI.RawUI.WindowSize
        if ($size.Width -gt 1) { $width = $size.Width - 1 }
        if ($size.Height -gt 0) { $height = $size.Height }
    }
    catch { $width = 120; $height = 40 }
    return @{ Width = $width; Height = $height }
}

function Get-ScreenTextPage {
    <#
    .SYNOPSIS
        Wrap accessible text and reserve header, navigation and prompt rows before paging.
    .OUTPUTS
        Array of page dictionaries, each containing a Lines array. No host output or workflow mutations.
    .PARAMETER Lines
        Complete source text lines; an empty collection is supported.
    .PARAMETER Viewport
        Width/Height dictionary for the current terminal.
    .PARAMETER Title
        Screen title included in header-height calculations.
    #>
    param([AllowEmptyCollection()][string[]]$Lines = @(), [Parameter(Mandatory)][hashtable]$Viewport, [string]$Title)
    $width = [Math]::Max(1, [int]$Viewport.Width)
    $headerRows = [int][Math]::Ceiling(('Autopilot Express - {0} | Live | Page 999 of 999' -f $Title).Length / [double]$width)
    $reservedRows = 4
    foreach ($footer in @('NEXT PAGE. Next page', 'PREVIOUS PAGE. Previous page', 'Step letter: detail; STEP LIST: guide', '0. Return to bench', 'Guide command (default: 0): ')) {
        $reservedRows += [int][Math]::Ceiling($footer.Length / [double]$width)
    }
    $capacity = [Math]::Max(1, [int]$Viewport.Height - $headerRows - $reservedRows)
    $wrapped = @()
    foreach ($line in $Lines) {
        $remaining = [string]$line
        while ($remaining.Length -gt $width) {
            $cut = $remaining.LastIndexOf(' ', $width - 1, $width)
            if ($cut -le 0) { $cut = $width }
            $wrapped += $remaining.Substring(0, $cut)
            $remaining = $remaining.Substring($cut).TrimStart()
        }
        $wrapped += $remaining
    }
    $pages = @()
    for ($offset = 0; $offset -lt $wrapped.Count; $offset += $capacity) {
        $last = [Math]::Min($wrapped.Count - 1, $offset + $capacity - 1)
        $pages += @{ Lines = @($wrapped[$offset..$last]) }
    }
    if (-not $pages.Count) { $pages = @(@{ Lines = @('No enabled workflow steps.') }) }
    return , $pages
}

function Show-BenchWorkflowGuide {
    <#
    .SYNOPSIS
        Explain manifest step codes without executing actions or changing records.
    .DESCRIPTION
        Preserve manifest order within ordinary and conditional recovery actions.
        Pages wrap to the current viewport and recalculate after input/resize.
        > advances and < goes back; repeated symbols avoid custom step-ID collisions.
        A step letter shows paged
        detail; STEP LIST restores the overview; 0 or Enter returns to the bench. R remains
        a return alias only when it is not a manifest step ID. Input is
        case-insensitive and invalid codes are rejected by the shared validator.
    .OUTPUTS
        Accessible host text only; no workflow evidence or files are changed.
    .PARAMETER ReturnDestination
        Calling bench or information menu; zero returns control without redirecting.
    #>
    param([ValidateSet('Build bench', 'Script Information')][string]$ReturnDestination = 'Build bench')
    $steps = @(Get-EnabledManifestSteps)
    $displayCodes = @($steps | ForEach-Object { Get-WorkflowDisplayCode -Step $_ })
    if (@($displayCodes | Select-Object -Unique).Count -ne $displayCodes.Count) { throw 'Workflow display codes are ambiguous; no guide action was selected.' }
    $overview = @('Steps follow workflow order. Prerequisites must be complete before an action.', 'Conditional recovery runs only after a recorded failure.')
    foreach ($conditional in @($false, $true)) {
        $section = if ($conditional) { 'Conditional recovery - only after a recorded failure' } else { 'Normal computer build - workflow order' }
        $overview += @('', $section)
        foreach ($step in @($steps | Where-Object { [bool]$_.IsConditional -eq $conditional })) {
            $kind = switch ($step.ExecutionType) {
                'graph' { 'Graph action' }
                'hybrid' { 'Graph and technician action' }
                'hybrid-selection' { 'Selection and Graph action' }
                default { 'Technician observation' }
            }
            $overview += ('{0} [{1}]' -f (Get-WorkflowStepLabel -Step $step), $kind)
            $overview += ('   {0}' -f $step.Summary)
            $prerequisites = Get-WorkflowStepReference -StepIds @($step.PrerequisiteStepIds)
            $overview += ('   Requires: {0}' -f $prerequisites)
            $overview += ''
        }
    }
    $overview += 'Graph submission is not completion: read-back or technician confirmation is recorded separately.'
    $content = $overview
    $pageIndex = 0
    $nextCode = '>'
    $previousCode = '<'
    while ($displayCodes -contains $nextCode) { $nextCode += '>' }
    while ($displayCodes -contains $previousCode) { $previousCode += '<' }
    while ($true) {
        $pages = Get-ScreenTextPage -Lines $content -Viewport (Get-TerminalViewport) -Title 'Show Steps List'
        $pageIndex = [Math]::Min($pageIndex, $pages.Count - 1)
        Show-ScriptScreen -Title ('Show Steps List | Page {0} of {1}' -f ($pageIndex + 1), $pages.Count)
        foreach ($line in $pages[$pageIndex].Lines) { Write-Host $line }
        Write-Host ''
        $choices = @('0', 'R', 'STEP LIST') + $displayCodes
        if ($pageIndex -lt $pages.Count - 1) { Write-Host ('{0}. Next page' -f $nextCode); $choices += $nextCode } else { Write-Host 'Last page' }
        if ($pageIndex -gt 0) { Write-Host ('{0}. Previous page' -f $previousCode); $choices += $previousCode } else { Write-Host 'First page' }
        Write-Host 'Step letter: detail; STEP LIST: guide'
        $returnLabel = if ($ReturnDestination -eq 'Build bench') { 'bench' } else { $ReturnDestination.ToLowerInvariant() }
        Write-Host ('0. Return to {0}' -f $returnLabel)
        $code = Read-ValidatedInput -Prompt 'Guide command' -Default '0' -Type 'Choice' -Choices $choices
        if ($code -eq '0' -or ($code -eq 'R' -and $displayCodes -notcontains 'R')) { return }
        if ($code -eq $nextCode) { $pageIndex++; continue }
        if ($code -eq $previousCode) { $pageIndex--; continue }
        if ($code -eq 'STEP LIST') { $content = $overview; $pageIndex = 0; continue }
        $step = $steps | Where-Object { (Get-WorkflowDisplayCode -Step $_) -eq $code } | Select-Object -First 1
        $content = @(Get-WorkflowStepLabel -Step $step) + @([string]$step.Summary)
        foreach ($paragraph in @($step.Details)) { if ($paragraph) { $content += @('', [string]$paragraph) } }
        if ($step.Notes) { $content += [string]$step.Notes }
        $prerequisites = Get-WorkflowStepReference -StepIds @($step.PrerequisiteStepIds)
        $content += ('Requires completed steps: {0}' -f $prerequisites)
        $pageIndex = 0
    }
}

function Show-BenchSectionBar {
    <#
    .SYNOPSIS
        Render a full-width labelled bar with blank lines and non-colour meaning.
    .PARAMETER Title
        Accessible section name, wrapped when the console is narrow.
    .PARAMETER Background
        Grey for results or yellow for options; text remains black.
    .OUTPUTS
        Host section heading with a textual label; colour is not the only cue.
    #>
    param([Parameter(Mandatory)][string]$Title, [ValidateSet('Gray', 'Yellow')][string]$Background)
    $width = Get-ConsoleTextWidth
    Write-Host ''
    foreach ($line in (Get-ScreenFeedbackLines -State @{ Events = @(@{ Text = $Title; Context = '' }) })) {
        Write-Host $line.PadRight($width) -ForegroundColor Black -BackgroundColor $Background
    }
    Write-Host ''
}

function Get-BenchOptionLines {
    <#
    .SYNOPSIS
        Align command keys across rows, wrapping whole cells on narrow terminals.
    .OUTPUTS
        Display lines only; command bindings and workflow state are unchanged.
    #>
    $rows = @(
        @{ Cells = @('[I] Induct', '[T] Prepare', '[S] Next step', '[D] Dispatch (DO override)') }
        @{ Cells = @('[V] Show Device overview', '[X] Recover', '[M] Move', '[U] Go back') }
        @{ Cells = @('[R] Remove from bench', '[0/E] Main menu', '[A] Device actions') }
        @{ Cells = @('[W] Show Steps List', '[L] Result details') }
    )
    $width = Get-ConsoleTextWidth
    $columns = @(0..3 | ForEach-Object {
            $column = $_
            [int](@($rows | Where-Object { $_.Cells.Count -gt $column } | ForEach-Object { $_.Cells[$column].Length }) | Measure-Object -Maximum).Maximum
        })
    $lines = @()
    foreach ($row in $rows) {
        $line = ''
        for ($column = 0; $column -lt $row.Cells.Count; $column++) {
            $cell = $row.Cells[$column]
            if ($line.Length -gt 0 -and $line.Length + $cell.Length -gt $width) {
                $lines += $line.TrimEnd()
                $line = ''
            }
            $line += $cell.PadRight($columns[$column] + 3)
        }
        $lines += $line.TrimEnd()
    }
    return , $lines
}

function Read-BenchCommand {
    <#
    .SYNOPSIS
        Render complete recent events, options and finally the command prompt.
    .DESCRIPTION
        Linear output works without cursor positioning. LinearOutput remains an
        accepted compatibility switch; no terminal cursor is ever moved.
    .PARAMETER Lines
        Already retained, transient bench feedback, not persisted workflow evidence.
    .PARAMETER LinearOutput
        Use append-only input when cursor placement is unavailable or explicitly disabled.
    .OUTPUTS
        Entered command text; parsing and action dispatch remain separate.
    #>
    param([AllowEmptyCollection()][string[]]$Lines = @(), [switch]$LinearOutput)
    Write-Verbose ('Linear bench output; explicit fallback requested: {0}' -f $LinearOutput.IsPresent)
    Show-BenchSectionBar -Title 'Recent results and messages (last five events)' -Background Gray
    if (-not $Lines.Count) { Write-Host 'No actions in this bench view yet.' }
    foreach ($line in $Lines) { Write-Host $line }
    Show-BenchSectionBar -Title 'Options' -Background Yellow
    foreach ($row in (Get-BenchOptionLines)) {
        foreach ($line in (Get-ScreenFeedbackLines -State @{ Events = @(@{ Text = $row; Context = '' }) })) { Write-Host $line }
    }
    return Read-ValidatedInput -Prompt 'Command (Enter refreshes)' -AllowEmpty -Default 'REFRESH' -ServiceInventory
}

function Show-BuildBenchView {
    <#
    .SYNOPSIS
        Run the bench command loop while preserving feedback across redraws.
    .PARAMETER Records
        Mutable record container shared with tracked-device navigation.
    .OUTPUTS
        Host output only. Explicit commands own confirmations and guarded saves; Enter refreshes,
        and returning to the main menu does not silently dispatch or replay pending actions.
    #>
    param([hashtable]$Records)
    if (-not $Script:BuildBench.Active) { Write-Host 'Build bench not initialised.'; return }
    $benchFeedback = @{ Lines = @(); Events = @(); Compact = $true; Context = 'Bench | no device selected' }
    function Write-BenchFeedback {
        <#
        .SYNOPSIS
            Retain a readable result or refusal across bench redraws.
        .PARAMETER Text
            Complete feedback text; original wording is not stripped.
        .PARAMETER ContextIncluded
            Mark feedback already containing its exact device identity context.
        .OUTPUTS
            None. Appends a bounded event to the enclosing feedback state.
        #>
        param([Parameter(Mandatory)][AllowEmptyString()][string]$Text, [switch]$ContextIncluded)
        Add-ScreenFeedback -State $benchFeedback -Text @($Text) -Context $benchFeedback.Context -ContextIncluded:$ContextIncluded
        if ($ContextIncluded) { Write-Host $Text } else { Write-Host ('{0}: {1}' -f $benchFeedback.Context, $Text) }
    }
    function Invoke-BenchActionOutput {
        <#
        .SYNOPSIS
            Execute the selected action once; callers retain its structured result summary.
        .PARAMETER Action
            Explicitly selected workflow scriptblock; invoked once, never automatically replayed.
        .PARAMETER Device
            Selected record for optional verbose diagnostic context.
        .OUTPUTS
            Original action results and host output; the transcript retains complete diagnostics.
        #>
        param([Parameter(Mandatory)][scriptblock]$Action, [System.Collections.IDictionary]$Device)
        if ($Device) { Write-Verbose ('Selected bench action for serial {0}.' -f $Device.Serial) }
        & $Action
    }
    function Invoke-BenchSelectedCommand {
        <#
        .SYNOPSIS
            Run one T, X, U or A bench command for one occupied position.
        .DESCRIPTION
            Shared by single and batch selection so both apply identical record checks,
            actions and retained feedback. Batches call it once per device, in order.
        .PARAMETER Command
            T prepares (A-D), X recovers, U withdraws the latest confirmation, A opens device actions.
        .PARAMETER Slot
            Occupied bench position resolved by the caller.
        .OUTPUTS
            Short outcome text for the batch summary; feedback is also retained on the bench.
        #>
        [OutputType([string])]
        param([Parameter(Mandatory)][ValidateSet('T', 'X', 'U', 'A')][string]$Command, [Parameter(Mandatory)]$Slot)
        $benchFeedback.Context = Get-DeviceFeedbackContext -Device $Slot
        $matchesForPlan = @($Records.Value | Where-Object { $_.Serial -eq $Slot.Serial })
        if ($matchesForPlan.Count -ne 1) {
            Write-BenchFeedback 'The selected bench device has no unique workflow record.'
            return 'Skipped: no unique workflow record'
        }
        $rec = $matchesForPlan[0]
        if ($Command -eq 'A') {
            $actionResult = Show-DeviceActions -Records $Records -Device $rec -ReturnDestination 'Build bench'
            if (-not $actionResult) { return 'No device action run' }
            Write-BenchFeedback ('{0}: {1}' -f $actionResult.State, $actionResult.Summary)
            return ('{0}: {1}' -f $actionResult.State, $actionResult.Summary)
        }
        if ($Command -eq 'U') {
            $correction = Undo-LatestTechnicianConfirmation -Records $Records -Device $rec
            Write-BenchFeedback $correction.Summary
            return [string]$correction.Summary
        }
        $plan = if ($Command -eq 'T') { 'Prepare' } else { 'Recover' }
        $benchFeedback.Context = Get-DeviceFeedbackContext -Device $rec
        $outcome = Invoke-BenchActionOutput -Device $rec -Action { Invoke-DeviceWorkflowPlan -Records $Records -Device $rec -Plan $plan }
        $planState = if ($outcome.Completed) { 'Plan complete' } elseif ($outcome.Result) { $outcome.Result.CompletionState } else { 'Not completed' }
        $benchFeedback.Context = '{0}; {1} [{2}]' -f (Get-DeviceFeedbackContext -Device $rec), $plan, $planState
        $planText = [string]$outcome.Summary
        if ($outcome.Result -and $outcome.Result.Notes) { $planText += "`n" + $outcome.Result.Notes }
        Write-BenchFeedback $planText
        return ('{0}: {1}' -f $plan, $planState)
    }
    function Show-BenchScreen {
        <#
        .SYNOPSIS
            Redraw bench state, aligned commands and retained feedback without executing actions.
        .OUTPUTS
            Host output only, using the enclosing records and feedback state.
        #>
        Show-ScriptScreen -Title 'Build Bench Manager'
        Show-BuildBenchTable -Records $Records
        if ($Script:BuildBench.Faults -and $Script:BuildBench.Faults.Count -gt 0) {
            Write-Host 'Current faults:'
            foreach ($f in $Script:BuildBench.Faults) { Write-Host $f }
            Write-Host ''
        }
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
        Write-Host 'Enter a position or scan Serial/CI. Use P:1, CI:123 or S:ABC to disambiguate matches.'
        Write-Host ''
    }
    Show-BenchScreen
    while ($true) {
        # BENCH-DOC-FEEDBACK: collect finished document jobs before each redraw so outcomes are
        # retained in the bench feedback; this never prompts, saves workflow state or reads input.
        Receive-DeviceDocumentJob -FeedbackState $benchFeedback
        $feedbackLines = Get-ScreenFeedbackLines -State $benchFeedback
        $cmd = Read-BenchCommand -Lines $feedbackLines
        $u = if ([string]::IsNullOrWhiteSpace($cmd)) { 'REFRESH' } else { $cmd.Trim().ToUpper() }
        $benchFeedback.Context = 'Bench | command={0}' -f $u
        switch ($u) {
            '0' { Save-BuildBenchState; return }
            'E' { Save-BuildBenchState; return }
            'REFRESH' { Show-BenchScreen }
            'W' { Show-BenchWorkflowGuide; Show-BenchScreen }
            'L' {
                $details = @($benchFeedback.Events | ForEach-Object { '{0}: {1}' -f $_.Context, $_.Text })
                if (-not $details.Count) { $details = @('No retained results.') }
                [void](Read-PagedInformation -Title 'Recent result details' -Lines $details -ReturnDestination 'Build bench')
                Show-BenchScreen
            }
            { $_ -in @('T', 'X', 'U', 'A') } {
                # Empty input takes the default 0 and cancels. Lists, ranges and ALL run as a
                # confirmed sequential batch; any other text keeps single-device selection.
                $ans = Read-ValidatedInput -Prompt 'Position or Serial/CI; list 1,3,5-7 or ALL for several (0 to cancel)' -Default '0'
                if ($ans -eq '0') { Show-BenchScreen; continue }
                $batch = Resolve-BenchBatchSelection -Positions @($Script:BuildBench.Positions) -Selection $ans
                if ($null -eq $batch) {
                    $slot = Resolve-DeviceSelection -Items $Script:BuildBench.Positions -Selection $ans -Bench
                    if (-not $slot -or -not $slot.Serial) { Write-BenchFeedback 'No unique device at that position or identifier. Use P:, S: or CI:.'; Show-BenchScreen; continue }
                    [void](Invoke-BenchSelectedCommand -Command $u -Slot $slot)
                    Show-BenchScreen
                    continue
                }
                if ($batch.Error) { Write-BenchFeedback ('{0} No devices were selected.' -f $batch.Error); Show-BenchScreen; continue }
                $batchSlots = @($Script:BuildBench.Positions | Where-Object { [int]$_.Index -in $batch.Positions -and $_.Serial })
                $emptyPositions = @($batch.Positions | Where-Object { $_ -notin @($batchSlots | ForEach-Object { [int]$_.Index }) })
                if ($batchSlots.Count -eq 0) { Write-BenchFeedback 'No occupied positions in that selection. No devices were selected.'; Show-BenchScreen; continue }
                $commandNames = @{ T = 'Prepare (T)'; X = 'Recover (X)'; U = 'Withdraw latest confirmation (U)'; A = 'Device actions (A)' }
                Write-Host ''
                Write-Host ('{0} will run on {1} device(s), one at a time in position order:' -f $commandNames[$u], $batchSlots.Count)
                foreach ($batchSlot in $batchSlots) { Write-Host ('  [{0}] Serial {1} | CI {2}' -f $batchSlot.Index, $batchSlot.Serial, $batchSlot.ConfigItem) }
                if ($emptyPositions.Count -gt 0) { Write-Host ('  Empty positions skipped: {0}' -f ($emptyPositions -join ', ')) }
                $confirmBatch = Read-ValidatedInput -Prompt 'Run on these devices? [Y] Yes [N] No' -Default 'N' -Type 'Choice' -Choices @('Y', 'N')
                if ($confirmBatch.ToUpperInvariant() -ne 'Y') { Write-BenchFeedback 'Batch cancelled; no devices were changed.'; Show-BenchScreen; continue }
                $batchLines = [Collections.Generic.List[string]]::new()
                foreach ($batchSlot in $batchSlots) {
                    $lineText = Invoke-BenchSelectedCommand -Command $u -Slot $batchSlot
                    $batchLines.Add(('[{0}] {1}: {2}' -f $batchSlot.Index, $batchSlot.Serial, $lineText))
                }
                $benchFeedback.Context = 'Bench | batch {0}' -f $u
                Write-BenchFeedback ("Batch {0} finished for {1} device(s):`n{2}" -f $commandNames[$u], $batchSlots.Count, ($batchLines -join "`n"))
                Show-BenchScreen
            }
            'I' {
                $previousRecordCount = @($Records.Value).Count
                $previousBenchSerials = @($Script:BuildBench.Positions | Where-Object Serial | ForEach-Object Serial)
                Invoke-BenchActionOutput -Action { [void](Start-NewDeviceWorkflow -CurrentSiteCode $Script:BuildBench.SiteCode -Records $Records -BenchRequired) }
                $newRecords = @($Records.Value).Count - $previousRecordCount
                $attachedCount = @($Script:BuildBench.Positions | Where-Object { $_.Serial -and $_.Serial -notin $previousBenchSerials }).Count
                if (-not $newRecords -and -not $attachedCount) { Write-BenchFeedback 'No device attached; induction was cancelled or left unchanged.' }
                else { Write-BenchFeedback ('Induction: {0} new workflow(s); {1} retained attached.' -f $newRecords, [Math]::Max(0, ($attachedCount - $newRecords))) }
                Show-BenchScreen
            }
            'R' {
                # Remove a device by position or identifier
                $hasAny = (($Script:BuildBench.Positions | Where-Object { $_.Serial }) | Measure-Object).Count -gt 0
                if (-not $hasAny) { Write-BenchFeedback 'No devices are currently on the bench.'; Show-BenchScreen; continue }
                $max = ($Script:BuildBench.Positions | Measure-Object).Count
                $occupied = @($Script:BuildBench.Positions | Where-Object { $_.Serial })
                $defaultPos = if ($occupied.Count -gt 0) { $occupied[0].Index } else { 1 }
                $ans = Read-ValidatedInput -Prompt ('Position number (1-{0}) or Serial/CI (0 to cancel)' -f $max) -AllowEmpty -Default $defaultPos
                if ($ans -eq '0') { Show-BenchScreen; continue }
                $slot = Resolve-DeviceSelection -Items $Script:BuildBench.Positions -Selection $ans -Bench
                if (-not $slot -or -not $slot.Serial) { Write-BenchFeedback 'No unique device at that position or identifier. Use P:, S: or CI:.'; Show-BenchScreen; continue }
                $benchFeedback.Context = Get-DeviceFeedbackContext -Device $slot
                Remove-DeviceFromBenchPosition -Position ([int]$slot.Index)
                Save-BuildBenchState
                Write-BenchFeedback 'Removed from bench; workflow record retained.'
                Show-BenchScreen
            }
            'S' {
                # Action next step for a device by position or identifier
                $max = ($Script:BuildBench.Positions | Measure-Object).Count
                $ans = Read-ValidatedInput -Prompt ('Position number (1-{0}) or Serial/CI (0 to cancel)' -f $max) -Default '0'
                if ($ans -eq '0') { Show-BenchScreen; continue }
                $slot = Resolve-DeviceSelection -Items $Script:BuildBench.Positions -Selection $ans -Bench
                if (-not $slot -or -not $slot.Serial) { Write-BenchFeedback 'No unique device at that position or identifier. Use P:, S: or CI:.'; Show-BenchScreen; continue }
                $rec = $Records.Value | Where-Object { $_.Serial -eq $slot.Serial }
                if (-not $rec) {
                    $expectedTag = if ($Script:BuildBench.SiteCode -and $Script:BuildBench.DeviceType) { ('{0}-{1}' -f $Script:BuildBench.SiteCode, ($Script:BuildBench.DeviceType -replace '\s', '')) } else { $null }
                    $rec = New-DeviceRecordObject -Serial $slot.Serial -ConfigItem $slot.ConfigItem -SiteCode $Script:BuildBench.SiteCode -DeviceType $Script:BuildBench.DeviceType -GroupTag $expectedTag
                    Add-DeviceRecord -Records $Records -Record $rec
                    Write-UserDeviceRecords -Records $Records.Value
                }
                $benchFeedback.Context = Get-DeviceFeedbackContext -Device $rec
                $next = Get-NextStepId -Device $rec
                if ($next) {
                    $stepDefinition = Get-ManifestStepDefinition -StepId $next
                    if ($stepDefinition) {
                        Write-BenchFeedback 'Resolving the selected serial may read the complete Autopilot inventory. Other devices are not actioned.'
                        $result = Invoke-BenchActionOutput -Device $rec -Action { Invoke-AutopilotManifestStep -Device $rec -StepDefinition $stepDefinition }
                        Write-ManifestStepResult -Device $rec -StepDefinition $stepDefinition -Result $result
                        Write-UserDeviceRecords -Records $Records.Value
                        $benchFeedback.Context = '{0}; {1} [{2}]' -f (Get-DeviceFeedbackContext -Device $rec), (Get-WorkflowStepLabel -Step $stepDefinition), $result.CompletionState
                        $resultText = [string]$result.Summary
                        if ($result.Notes) { $resultText += "`n" + $result.Notes }
                        Write-BenchFeedback $resultText
                        Show-BenchScreen
                    }
                }
                else {
                    $readiness = Test-DeviceReadyForDispatch -Device $rec
                    if ($readiness.Ready) { Write-BenchFeedback 'All steps completed.' }
                    else { Write-BenchFeedback ('No next action is eligible. Required steps remain: {0}.' -f ($readiness.BlockingStepIds -join ', ')) }
                    Show-BenchScreen
                }
            }
            'C' {
                $max = ($Script:BuildBench.Positions | Measure-Object).Count
                $ans = Read-ValidatedInput -Prompt ('Position number (1-{0}) or Serial/CI (0 to cancel)' -f $max) -Default '0'
                if ($ans -eq '0') { Show-BenchScreen; continue }
                $slot = Resolve-DeviceSelection -Items $Script:BuildBench.Positions -Selection $ans -Bench
                if (-not $slot -or -not $slot.Serial) { Write-BenchFeedback 'No unique device at that position or identifier. Use P:, S: or CI:.'; Show-BenchScreen; continue }

                $benchFeedback.Context = Get-DeviceFeedbackContext -Device $slot
                $rec = $Records.Value | Where-Object { $_.Serial -eq $slot.Serial }
                if (-not $rec) { Write-BenchFeedback 'The selected bench device has no active workflow record.'; Show-BenchScreen; continue }
                $eligibleSteps = @(Get-EligibleManifestSteps -Device $rec)
                if ($eligibleSteps.Count -eq 0) {
                    Write-BenchFeedback 'No eligible actions are available for this device.'
                    Show-BenchScreen
                    continue
                }

                Write-Host 'Eligible actions:'
                foreach ($step in $eligibleSteps) { Write-Host (Get-WorkflowStepLabel -Step $step) }
                $stepId = Read-ValidatedInput -Prompt 'Choose eligible action ([0] Cancel)' -Default '0' -Type 'Choice' -Choices (@('0') + @($eligibleSteps | ForEach-Object { Get-WorkflowDisplayCode -Step $_ }))
                if ($stepId -eq '0') { Show-BenchScreen; continue }
                $stepDefinition = $eligibleSteps | Where-Object { (Get-WorkflowDisplayCode -Step $_) -eq $stepId } | Select-Object -First 1
                $benchFeedback.Context = Get-DeviceFeedbackContext -Device $rec
                $result = Invoke-BenchActionOutput -Device $rec -Action { Invoke-AutopilotManifestStep -Device $rec -StepDefinition $stepDefinition }
                Write-ManifestStepResult -Device $rec -StepDefinition $stepDefinition -Result $result
                Write-UserDeviceRecords -Records $Records.Value
                $benchFeedback.Context = '{0}; {1} [{2}]' -f (Get-DeviceFeedbackContext -Device $rec), (Get-WorkflowStepLabel -Step $stepDefinition), $result.CompletionState
                $resultText = [string]$result.Summary
                if ($result.Notes) { $resultText += "`n" + $result.Notes }
                Write-BenchFeedback $resultText
                Show-BenchScreen
            }
            { $_ -in @('D', 'DO') } {
                # Dispatch and finish a device by position or identifier
                $max = ($Script:BuildBench.Positions | Measure-Object).Count
                $ans = Read-ValidatedInput -Prompt ('Position number (1-{0}) or Serial/CI (0 to cancel)' -f $max) -Default '0'
                if ($ans -eq '0') { Show-BenchScreen; continue }
                $slot = Resolve-DeviceSelection -Items $Script:BuildBench.Positions -Selection $ans -Bench
                if (-not $slot -or -not $slot.Serial) { Write-BenchFeedback 'No unique device at that position or identifier. Use P:, S: or CI:.'; Show-BenchScreen; continue }
                $rec = $Records.Value | Where-Object { $_.Serial -eq $slot.Serial }
                if (-not $rec) {
                    $expectedTag = if ($Script:BuildBench.SiteCode -and $Script:BuildBench.DeviceType) { ('{0}-{1}' -f $Script:BuildBench.SiteCode, ($Script:BuildBench.DeviceType -replace '\s', '')) } else { $null }
                    $rec = New-DeviceRecordObject -Serial $slot.Serial -ConfigItem $slot.ConfigItem -SiteCode $Script:BuildBench.SiteCode -DeviceType $Script:BuildBench.DeviceType -GroupTag $expectedTag
                    Add-DeviceRecord -Records $Records -Record $rec
                }
                $benchFeedback.Context = Get-DeviceFeedbackContext -Device $rec
                $dispatch = Complete-DeviceDispatch -Records $Records -Device $rec -Override:($u -eq 'DO')
                Write-BenchFeedback $dispatch.Summary -ContextIncluded
                Show-BenchScreen
            }
            'V' {
                # View a device details by position or identifier
                $max = ($Script:BuildBench.Positions | Measure-Object).Count
                $ans = Read-ValidatedInput -Prompt ('Position number (1-{0}) or Serial/CI (0 to cancel)' -f $max) -Default '0'
                if ($ans -eq '0') { Show-BenchScreen; continue }
                $slot = Resolve-DeviceSelection -Items $Script:BuildBench.Positions -Selection $ans -Bench
                if (-not $slot -or -not $slot.Serial) { Write-BenchFeedback 'No unique device at that position or identifier. Use P:, S: or CI:.'; Show-BenchScreen; continue }
                $rec = $Records.Value | Where-Object { $_.Serial -eq $slot.Serial }
                if (-not $rec) {
                    $expectedTag = if ($Script:BuildBench.SiteCode -and $Script:BuildBench.DeviceType) { ('{0}-{1}' -f $Script:BuildBench.SiteCode, ($Script:BuildBench.DeviceType -replace '\s', '')) } else { $null }
                    $rec = New-DeviceRecordObject -Serial $slot.Serial -ConfigItem $slot.ConfigItem -SiteCode $Script:BuildBench.SiteCode -DeviceType $Script:BuildBench.DeviceType -GroupTag $expectedTag
                    Add-DeviceRecord -Records $Records -Record $rec
                    Write-UserDeviceRecords -Records $Records.Value
                }
                if ($rec) {
                    Invoke-AutopilotSequence -Records $Records -Device $rec -ReturnDestination 'Build bench' -FeedbackState $benchFeedback
                    Show-BenchScreen
                }
            }
            'M' {
                # Move device between positions; source can be pos/serial/ci, destination must be empty; default destination = next open
                $hasAny = (($Script:BuildBench.Positions | Where-Object { $_.Serial }) | Measure-Object).Count -gt 0
                if (-not $hasAny) { Write-BenchFeedback 'No devices are currently on the bench.'; Show-BenchScreen; continue }
                $max = ($Script:BuildBench.Positions | Measure-Object).Count
                $srcAns = Read-ValidatedInput -Prompt ('Source position (1-{0}) or Serial/CI (0 to cancel)' -f $max) -Default '0'
                if ($srcAns -eq '0') { Show-BenchScreen; continue }
                $srcSlot = Resolve-DeviceSelection -Items $Script:BuildBench.Positions -Selection $srcAns -Bench
                if (-not $srcSlot -or -not $srcSlot.Serial) { Write-BenchFeedback 'No unique device found at that source position or identifier.'; Show-BenchScreen; continue }
                $benchFeedback.Context = Get-DeviceFeedbackContext -Device $srcSlot

                $openSlots = @($Script:BuildBench.Positions | Where-Object { -not $_.Serial })
                if ($openSlots.Count -eq 0) { Write-BenchFeedback 'There are no empty positions to move the device to.'; Show-BenchScreen; continue }
                $defaultDest = $openSlots[0].Index
                while ($true) {
                    $destAns = Read-ValidatedInput -Prompt ('Destination position (1-{0}, 0 to cancel)' -f $max) -AllowEmpty -Default $defaultDest
                    if ($destAns -eq '0') { Show-BenchScreen; break }
                    $destNum = ConvertTo-OptionalInteger -Value $destAns
                    if ($null -eq $destNum -or $destNum -lt 1 -or $destNum -gt $max) { Write-Host ('Invalid position. Choose between 1 and {0}.' -f $max); continue }
                    $destSlot = $Script:BuildBench.Positions | Where-Object { $_.Index -eq $destNum }
                    if ($destSlot.Serial) { Write-Host ('Position {0} is occupied. Choose an empty position.' -f $destNum); continue }
                    # Move
                    $destSlot.Serial = $srcSlot.Serial; $destSlot.ConfigItem = $srcSlot.ConfigItem
                    $srcSlot.Serial = $null; $srcSlot.ConfigItem = $null
                    Save-BuildBenchState
                    Write-BenchFeedback ('Moved device to position {0}; workflow evidence retained.' -f $destNum)
                    Show-BenchScreen
                    break
                }
            }
            default {
                $slot = Resolve-DeviceSelection -Items $Script:BuildBench.Positions -Selection ([string]$cmd) -Bench
                $matchesForView = @($Records.Value | Where-Object { $slot -and $_.Serial -eq $slot.Serial -and $_.Status -notin @('removed', 'completed') })
                if ($matchesForView.Count -eq 1) {
                    Invoke-AutopilotSequence -Records $Records -Device $matchesForView[0] -ReturnDestination 'Build bench' -FeedbackState $benchFeedback
                }
                else { Write-BenchFeedback 'No unique active bench device matches. Use P:<position>, CI:<CI> or S:<serial>.' }
                Show-BenchScreen
            }
        }
    }
}

# ===== Selection helpers =====
function Resolve-BenchBatchSelection {
    <#
    .SYNOPSIS
        Parse a bench batch selection such as 1,3,5-7 or ALL into position numbers.
    .DESCRIPTION
        Owner-agreed BENCH-BATCH contract: comma lists, ascending ranges and ALL select
        several positions for T, X, U or A. Batch syntax applies only to unprefixed text
        containing a comma, a range or ALL that does not exactly match a bench serial or
        Configuration Item, so every existing single selection keeps its meaning.
    .PARAMETER Positions
        Bench positions exposing Index, Serial and ConfigItem.
    .PARAMETER Selection
        Technician text from the bench position prompt.
    .OUTPUTS
        $null when the text is not batch syntax (callers use single selection); otherwise
        a hashtable with Positions (unique ascending integers) and Error (empty when valid).
    #>
    [OutputType([hashtable])]
    param(
        [Parameter(Mandatory)][AllowEmptyCollection()][object[]]$Positions,
        [Parameter(Mandatory)][AllowEmptyString()][string]$Selection
    )
    $text = $Selection.Trim()
    $isAll = $text -eq 'ALL'
    # A lone number stays a single selection; batches need a comma, a range or ALL.
    if (-not $isAll -and ($text -notmatch '^\d+(\s*-\s*\d+)?(\s*,\s*\d+(\s*-\s*\d+)?)*$' -or $text -notmatch '[,-]')) { return $null }
    foreach ($slot in $Positions) {
        if ($slot.Serial -and (([string]$slot.Serial).Trim() -eq $text -or ([string]$slot.ConfigItem).Trim() -eq $text)) { return $null }
    }
    $validPositions = @($Positions | ForEach-Object { [int]$_.Index })
    $result = @{ Positions = @(); Error = '' }
    if ($isAll) {
        $result.Positions = @($validPositions | Sort-Object -Unique)
        return $result
    }
    $selected = [Collections.Generic.List[int]]::new()
    foreach ($part in ($text -split ',')) {
        $bounds = @($part -split '-' | ForEach-Object { $_.Trim() })
        $numbers = @()
        foreach ($bound in $bounds) {
            $value = 0
            if (-not [int]::TryParse($bound, [ref]$value) -or $value -notin $validPositions) {
                $result.Error = 'Position {0} is not a bench position (1-{1}).' -f $bound, $validPositions.Count
                return $result
            }
            $numbers += $value
        }
        if ($numbers.Count -eq 2 -and $numbers[0] -gt $numbers[1]) {
            $result.Error = 'Range {0} must run from low to high, for example 5-7.' -f $part.Trim()
            return $result
        }
        foreach ($number in ($numbers[0]..$numbers[-1])) { $selected.Add($number) }
    }
    $result.Positions = @($selected | Sort-Object -Unique)
    return $result
}

function Resolve-DeviceSelection {
    <#
    .SYNOPSIS
        Resolve position, serial or CI input only when it identifies one device.
    .PARAMETER Items
        Display-ordered workflow records or bench positions; empty input is allowed.
    .PARAMETER Selection
        Bare position/identifier, or explicit P:, S: or CI: selection; zero cancels.
    .PARAMETER Bench
        Use stored bench indices instead of displayed workflow list numbers.
    .OUTPUTS
        One original record, or null for cancelled, missing or ambiguous input.
    #>
    param(
        [AllowEmptyCollection()][System.Collections.IEnumerable]$Items = @(),
        [Parameter(Mandatory)][AllowEmptyString()][string]$Selection,
        [switch]$Bench
    )
    $text = $Selection.Trim()
    if (-not $text -or $text -eq '0') { return $null }
    $kind = 'Any'
    if ($text -match '^(P|S|CI):(.+)$') {
        $kind = $Matches[1].ToUpperInvariant()
        $text = $Matches[2].Trim()
    }
    $number = ConvertTo-OptionalInteger -Value $text
    $candidates = @()
    $displayIndex = 0
    foreach ($item in $Items) {
        $displayIndex++
        if (-not $item.Serial) { continue }
        $position = if ($Bench) { $item.Index } else { $displayIndex }
        $positionMatch = $kind -in @('Any', 'P') -and $null -ne $number -and $number -eq $position
        $serialMatch = $kind -in @('Any', 'S') -and ([string]$item.Serial).Trim() -eq $text
        $ciMatch = $kind -in @('Any', 'CI') -and ([string]$item.ConfigItem).Trim() -eq $text
        if ($positionMatch -or $serialMatch -or $ciMatch) { $candidates += , $item }
    }
    if ($candidates.Count -eq 1) { return $candidates[0] }
    if ($candidates.Count -gt 1) { Write-Host 'Ambiguous selection. Use P:<position>, CI:<CI> or S:<serial>; no device was selected.' }
    return $null
}

function Select-DeviceFromRecords {
    <#
    .SYNOPSIS
        Resolve an explicit serial, configuration item or permitted numeric selection.
    .PARAMETER Records
        Record container; ineligible statuses are excluded by default.
    .PARAMETER Purpose
        Accessible context used in selection prompts and refusals.
    .PARAMETER IncludeCompleted
        Include completed records for explicitly requested maintenance views.
    .OUTPUTS
        One selected record or null; ambiguity is refused rather than guessed.
    #>
    param([hashtable]$Records, [string]$Purpose, [switch]$IncludeCompleted)
    $list = @($Records.Value | Where-Object { $_.Status -ne 'removed' -and ($IncludeCompleted -or $_.Status -ne 'completed') })
    if (-not $list -or $list.Count -eq 0) { Write-Host ''; Write-Host 'No devices currently being worked on.'; Show-ReturnToMainMenu; return $null }
    Write-Host ''
    Write-Host ('Select a device to {0} (number, Serial, CI, or 0 to exit; explicit P:, S:, CI: supported):' -f $Purpose)
    $idx = 1
    foreach ($d in $list) { Write-Host ('  {0}. Serial={1} CI={2} Status={3}' -f $idx, $d.Serial, $d.ConfigItem, $d.Status); $idx++ }
    $sel = Read-ValidatedInput -Prompt 'Your selection (0 exits)' -Default '0'
    if ($sel -eq '0') { return $null }
    $selected = Resolve-DeviceSelection -Items $list -Selection $sel
    if ($selected) { return $selected }
    Write-Host ''; Write-Host 'No matching device'; Show-ReturnToMainMenu; return $null
}

function Select-DeviceType {
    <#
    .SYNOPSIS
        Select a configured hardware type by validated number or name.
    .PARAMETER Default
        Current configured type offered when Enter is pressed.
    .OUTPUTS
        Configured type string; invalid values re-prompt without changing the record.
    #>
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
    while ($true) {
        $selection = Read-ValidatedInput -Prompt 'Enter number, hotkey letter, or full name' -Default $Default
        $numericSelection = ConvertTo-OptionalInteger -Value $selection
        if ($null -ne $numericSelection -and $numericSelection -ge 1 -and $numericSelection -le $types.Count) {
            return $types[$numericSelection - 1]
        }
        $match = $hotkeys.Keys | Where-Object { $hotkeys[$_].Key -eq $selection.ToUpperInvariant() }
        if ($match) { return $match }
        $exact = $types | Where-Object { $_ -eq $selection }
        if ($exact) { return $exact }
        Write-Host ('Invalid device type. Enter a number from 1 to {0}, a displayed hotkey, or a configured name.' -f $types.Count)
    }
}

function Show-RecoveryEvidenceReport {
    <#
    .SYNOPSIS
        Data Settings option 4: page a size report of retained recovery backups and optionally organise them.
    .DESCRIPTION
        Owner policy BACKUP-POLICY (keep all, organise): the report is read-only, and the only action moves
        older flat snapshots and crash-lock evidence into date and tenant folders after a Y/N confirmation
        (default N). Nothing is deleted. Workflow-ID conversion backups are listed but never moved, because
        their paths are recorded in migration markers used for interrupted-conversion recovery.
    .OUTPUTS
        Host pages only; returns to Data Settings.
    #>
    while ($true) {
        try { $entries = @(Get-RecoveryEvidenceInventory) }
        catch {
            Write-Warning ('Could not read the recovery backup folder: {0}. Nothing was changed.' -f $_.Exception.Message)
            Show-ReturnToMainMenu
            return
        }
        $formatSize = { param([long]$Bytes) if ($Bytes -ge 1GB) { '{0:N2} GB' -f ($Bytes / 1GB) } elseif ($Bytes -ge 1MB) { '{0:N1} MB' -f ($Bytes / 1MB) } else { '{0:N0} KB' -f [Math]::Ceiling($Bytes / 1KB) } }
        $lines = [Collections.Generic.List[string]]::new()
        $lines.Add(('Backup folder: {0}' -f (Get-RecoveryEvidenceFolder)))
        $lines.Add('Policy: keep every backup. This screen never deletes anything.')
        $lines.Add('')
        $totalBytes = [long](($entries | Measure-Object -Property Bytes -Sum).Sum)
        $lines.Add(('Total: {0} backups, {1} files, {2}' -f $entries.Count, [int](($entries | Measure-Object -Property Files -Sum).Sum), (& $formatSize $totalBytes)))
        $organised = @($entries | Where-Object Layout -eq 'Organised')
        foreach ($group in @($organised | Group-Object -Property Kind, Date, Tenant | Sort-Object { $_.Group[0].Kind }, { $_.Group[0].Date } -Descending)) {
            $first = $group.Group[0]
            $lines.Add(('{0} | {1} | {2}: {3} item(s), {4}' -f $first.Kind, $first.Date, $first.Tenant, $group.Count, (& $formatSize ([long](($group.Group | Measure-Object -Property Bytes -Sum).Sum)))))
        }
        $legacy = @($entries | Where-Object Layout -eq 'Legacy')
        $other = @($entries | Where-Object Layout -eq 'Other')
        if ($legacy.Count) { $lines.Add(('Older unorganised backups (can be organised): {0} item(s), {1}' -f $legacy.Count, (& $formatSize ([long](($legacy | Measure-Object -Property Bytes -Sum).Sum))))) }
        if ($other.Count) { $lines.Add(('Workflow-ID conversion and other backups (left in place): {0} item(s), {1}' -f $other.Count, (& $formatSize ([long](($other | Measure-Object -Property Bytes -Sum).Sum))))) }
        if (-not $entries.Count) { $lines.Add('No recovery backups have been retained on this computer.') }
        $options = @()
        if ($legacy.Count) { $options = @(@{ Code = 'O'; Label = ('Organise {0} older backup(s) into date and tenant folders (moves only; nothing is deleted)' -f $legacy.Count) }) }
        $choice = Read-PagedInformation -Title 'Recovery Backup Size Report' -Lines $lines.ToArray() -Options $options -ReturnDestination 'Data Settings'
        if ($choice -ne 'O') { return }
        $confirm = Read-ValidatedInput -Prompt ('Move {0} older backup(s) into date and tenant folders? [Y] Yes [N] No' -f $legacy.Count) -Default 'N' -Type 'Choice' -Choices @('Y', 'N')
        if ($confirm -ne 'Y') { continue }
        $outcome = Move-RecoveryEvidenceToOrganisedLayout -Confirm:$false
        Show-ScriptScreen -Title 'Organise Recovery Backups'
        foreach ($line in $outcome.Lines) { Write-Host $line }
        Write-Host ('Moved: {0}. Skipped: {1}. Nothing was deleted.' -f $outcome.Moved, $outcome.Skipped)
        Show-ReturnToMainMenu
    }
}

function Show-ReturnToMainMenu {
    <#
    .SYNOPSIS
        Keep report/error output readable until one explicit return acknowledgement.
    .DESCRIPTION
        Zero returns; Enter uses the same default. Invalid input is re-prompted.
        Call only for reports or errors, never after an explicit navigation return.
    .OUTPUTS
        Host text only; no workflow records or persisted evidence are changed.
    #>
    [void](Read-ValidatedInput -Prompt ('0. Return to {0}' -f (Get-NavigationMenuTitle).ToLowerInvariant()) -Default '0' -Type Choice -Choices @('0'))
    try { Clear-Host } catch { Write-Host '' }
}

# INITIALISATION & MAIN LOOP
#endregion
#region Main Lifecycle
try {
    if ($SessionLockAction) {
        Invoke-LocalSessionLockRecovery -Path $SessionLockPath -Recover:($SessionLockAction -eq 'Recover') -ConfirmStopped:$ConfirmStopped
        return
    }
    if ($CheckpointAction) {
        Invoke-LocalCheckpointRecovery -Path $CheckpointPath -Resolve:($CheckpointAction -eq 'Resolve') -ConfirmStopped:$ConfirmStopped -Confirm:$false | Format-List
        return
    }
    Initialize-AutopilotExpressDefinitions
    if ($MigrateWorkflowIds) {
        Invoke-WorkflowEvidenceMigration -Apply:$ApplyWorkflowMigration
        return
    }
    Show-ScriptScreen -Title 'Initial setup and testing'
    $Script:ResumeRecoveredSession = $false
    $localSessionLock = $null
    try {
        $localSessionLock = Request-LocalSessionLock
        if ($null -eq $localSessionLock) {
            Write-Host 'Returned without starting a session. No workflow or tenant actions were performed.'
            return
        }
        Assert-LocalStorageWriteState
        if (-not (Initialize-LocalSessionForResume -SessionLock $localSessionLock)) {
            Write-Host 'Saved work was retained. Startup cancelled before sign-in; no session was archived or reset.'
            return
        }
        $Script:ImagingWorkPattern = Read-ImagingWorkPattern
        if (-not (Initialize-GraphSession)) {
            Write-AutopilotExpressLog -Message 'Autopilot Express cannot continue without a valid Graph session or demo simulation.' -Level 'ERROR'
            Write-Host 'Startup stopped before the main menu.'
            Write-Host 'Review the error messages above for configuration, module, sign-in, or permission details.'
            Write-Host 'Use Demo mode to rehearse the workflow. For Live mode, sign in with an approved CA/A account and select the tenant profile and group when prompted.'
            Write-Host 'See README.md: Troubleshooting / Live Startup Failures.'
            return
        }
        if (-not (Request-DeviceDocumentReadiness)) { return }
        $records = @{ Value = (Initialize-SessionState) }
        $Script:InventoryRecords = $records
        # SYNC-RECEIPTS: fold legacy sync receipt/intent files into record ledgers (Live only).
        try { [void](Import-LegacySyncSubmissionEvidence -Records $records.Value) }
        catch { Write-AutopilotExpressLog -Message ('Legacy sync evidence migration did not complete; legacy files were kept: {0}' -f $_.Exception.Message) -Level 'WARN' }
        # IMPORT-RECEIPTS: fold legacy hash-import journal files into record ledgers (Live only).
        try { [void](Import-LegacyAutopilotImportEvidence -Records $records.Value) }
        catch { Write-AutopilotExpressLog -Message ('Legacy import evidence migration did not complete; legacy files were kept: {0}' -f $_.Exception.Message) -Level 'WARN' }
        Receive-DeviceDocumentJob
        $currentSiteCode = Select-Site -CurrentSiteCode (Get-SessionDefaultSiteCode -Records $records.Value)
        Write-AutopilotExpressLog -Message ('Autopilot Express initialised in {0} mode' -f $Script:Runtime.ModeDisplayName) -Level 'INFO'

        $Script:NavigationMenu = 'Main'
        $Script:SessionDefaultDeviceType = $Script:DeviceTypes[0]
        while ($true) {
            Receive-DeviceDocumentJob
            $option = Show-MainMenu -CurrentSiteCode $currentSiteCode -Menu $Script:NavigationMenu
            if ($option -in @('Main', 'Devices', 'Settings', 'Data', 'Information')) {
                $Script:NavigationMenu = $option
                continue
            }
            switch ($option) {
                'NewDevice' { $currentSiteCode = Start-NewDeviceWorkflow -CurrentSiteCode $currentSiteCode -Records $records }
                'TrackedDevice' { Invoke-AutopilotSequence -Records $records }
                'DeviceList' { Show-CurrentDeviceList -Records $records }
                'Outstanding' { Get-DeviceOutstanding -Records $records }
                'DeviceActions' { Show-DeviceActions -Records $records | Out-Null }
                'Maintain' { Update-DeviceStatus -Records $records }
                'Statistics' { Get-UserStats -Records $records -CurrentSiteCode $currentSiteCode }
                'LogFolder' { Show-DiagnosticLogFolder; Show-ReturnToMainMenu }
                'Enhancements' { Show-EnhancementsQuestions -ReturnDestination 'Script Information' }
                'Site' { Show-ScriptScreen -Title 'Change Current Site'; $currentSiteCode = Select-Site -CurrentSiteCode $currentSiteCode }
                'About' { Show-AboutScript }
                'Steps' { Show-BenchWorkflowGuide -ReturnDestination 'Script Information' }
                'Documentation' { Show-SessionInformation -View Documentation }
                'CommandLine' { Show-SessionInformation -View CommandLine }
                'WorkPattern' { Show-SessionInformation -View WorkPattern }
                'WorkPatternEdit' { Show-ImagingWorkPatternEditor }
                'RemediationSettings' { Show-RemediationQuickRunSettings }
                'DocumentSettings' { try { Show-DeviceDocumentSettings -Records $records } catch { Write-Host ('Optional document settings failed: {0}. Workflow records were not changed.' -f $_.Exception.Message) } }
                'DeviceType' {
                    Show-ScriptScreen -Title 'Change Default Device Type'
                    $Script:SessionDefaultDeviceType = Select-DeviceType -Default $Script:SessionDefaultDeviceType
                }
                'GraphReconnect' {
                    Close-GraphSession
                    [void](Initialize-GraphSession)
                }
                'ArchiveSession' {
                    if (Show-SessionArchive -Records $records) {
                        $currentSiteCode = Select-Site -CurrentSiteCode $Script:Sites[0].Code
                    }
                }
                'SessionReports' { Show-SessionReportExport -Records $records }
                'RecoveryEvidence' { Show-RecoveryEvidenceReport }
                'IntuneDetails' { Show-DeviceInventoryBackfill -Records $records }
                'Bench' {
                    Show-ScriptScreen -Title 'Build Bench Setup' -PromptFollows:(-not $Script:BuildBench.Active)
                    if (-not $Script:BuildBench.Active) {
                        do {
                            $benchInput = Read-ValidatedInput -Prompt 'Number of bench positions ([0] Cancel)' -Default '0' -Type 'Int'
                            $benchCount = ConvertTo-OptionalInteger -Value $benchInput
                            if ($null -eq $benchCount -or $benchCount -lt 0 -or $benchCount -gt 50) {
                                Write-Host 'Enter a whole number from 1 to 50, or 0 to return to Main Menu.'
                            }
                        } while ($null -eq $benchCount -or $benchCount -lt 0 -or $benchCount -gt 50)
                        if ($benchCount -eq 0) { continue }
                        New-BuildBench -Positions $benchCount
                        $Script:BuildBench.SiteCode = $currentSiteCode
                        $Script:BuildBench.DeviceType = Select-DeviceType -Default $Script:SessionDefaultDeviceType
                        Sync-BenchRecords -Records $records -ForceSave
                    }
                    else { Sync-BenchRecords -Records $records }
                    Show-BuildBenchView -Records $records
                }
                'Exit' { Write-AutopilotExpressLog -Message 'Exiting Autopilot Express.' -Level 'INFO'; Close-GraphSession; break }
                default { Write-Information -MessageData 'Invalid selection.' -InformationAction Continue }
            }
            if ($option -eq 'Exit' -or ($Script:DocumentSession -and $Script:DocumentSession['ExitRequested'])) { break }
        }
    }
    finally {
        $Script:InventoryRecords = $null
        if ($localSessionLock) {
            try { Close-GraphSession }
            finally { Stop-LocalSessionLock -Lock $localSessionLock }
        }
    }
}
catch {
    Write-Information -MessageData ('Autopilot Express stopped: {0}' -f $_.Exception.Message) -InformationAction Continue
    throw
}
finally {
    try {
        $documentState = Get-Variable -Name DocumentSession -Scope Script -ValueOnly -ErrorAction SilentlyContinue
        if ($documentState) {
            $documentState.Enabled = $false
            if ($documentState['Preparation']) { Start-AutopilotDocumentJob -DependencyRoot (Join-Path $documentState.Settings.Values.LocalRoot 'Dependencies') -PreparedWorker $documentState['Preparation'] -StopPreparation }
        }
        Receive-DeviceDocumentJob
        Invoke-DeviceDocumentHousekeeping
    }
    catch { Write-AutopilotExpressLog -Message ('Document shutdown housekeeping deferred; active/uncertain evidence retained: {0}' -f $_.Exception.Message) -Level WARN }
    Complete-AutopilotDiagnostics -Path $Script:DiagnosticLogPath
    Write-Host ''
}
#endregion
