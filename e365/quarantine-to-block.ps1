<#
.TITLE
Quarantine-To-Block.ps1

.SYNOPSIS
Automates review of quarantined messages and blocks sender domains in the Tenant Allow/Block List (TABL).

.NOTES
.FILECREATED      : 2025-12-15
.FILELASTUPDATED  : 2026-04-28
.VERSION          : 2.1.1
.REQUIRES         : ExchangeOnlineManagement (EXO V3 cmdlets)
.EXITCODES        : 0 = Success; 2 = Failed header coverage (when -FailOnLowHeaderCoverage)

$script:PSLRules = $null
$script:PSLExact = $null
$script:PSLWildcard = $null
$script:PSLExceptions = $null

The script can, at user request, offer to provide a list and/or automate deletion incuding permanent deletion if requested) of relevant messages once analysed.

Safety mechanisms are provided that will help avoid scenarios including:
- Domains that are already in the TABL Allow list, unless the user explictely invokes the relevant override feature

CSV output of actions or conflicts is also provided that shows what was done, or not done.

Comments use EN-AU spelling.

.USAGE EXAMPLE
.\Quarantine-To-Block.ps1 -AutoInstall `
    -ExcludedDomains @('microsoft.com') `
    -QuarantineTypesFilter @('Phish', 'HighConfidencePhish') `
    -BlockExpiry Never

Accepted parameters for passing to the script at the command line follow.

.PARAMETER UserPrincipalName
UPN to connect to Exchange Online. If a session is already connected, it is reused.

.PARAMETER AutoInstall
If set, installs ExchangeOnlineManagement for the current user when not present.

.PARAMETER QuarantineTypesFilter
Optional quarantine type filter, e.g. @('Phish', 'HighConfidencePhish'). If omitted, processes all types returned.

.PARAMETER ExcludedDomains
One or more domains to exclude from consideration (merged with JSON list and built-ins).

.PARAMETER ExcludedDomainsJsonPath
JSON file path containing an array or an object with a "domains" property to exclude.

.PARAMETER PslJsonPath
Path to a JSON PSL file. If omitted, the script uses public_suffix_list.dat in the script folder (if cached) or a quick network fetch with a background refresh.

.PARAMETER BlockExpiry
Block duration: Never, 1d, 7d, 30d, or Date (use BlockExpiryDate).

.PARAMETER ValidateHeaders
If set, records coverage metrics for header retrieval and can optionally fail the run when coverage is too low.

.PARAMETER DeleteQuarantineMode
Controls deletion of analysed quarantine messages. Options:
- Yes: delete all analysed messages (no confirmation).
- No: skip deletion.
- List (default): open a selection grid to choose messages to delete.
- Permanent: hard delete all analysed messages (prompted safety gate).

.PARAMETER OverrideAllowConflicts
Include allow-listed domains in the candidate list (disables default suppression). Use this when you explicitly intend to review/block domains that appear on the TABL Allow list.

.PARAMETER QuarantineReasonFilter
Optional list of quarantine reasons to include (default: all). Accepts one or more of: Transport rule, Bulk, Spam, Data Loss Prevention, Malware, Admin action - File type block, Phishing, High confidence phishing.

.PARAMETER PolicyTypeFilter
Optional list of policy types to include (default: all). Accepts one or more of: Anti-malware policy, Safe Attachments policy, Anti-phishing policy, Anti-spam policy, Transport rule, Data Loss Prevention Rule.

.PARAMETER UseDefaults
Runs the script without prompting for release options, using configured defaults defined in the Configuration parameters section. Grid views for selecting messages/domains still appear.

.PARAMETER ReportToDnsbl
When enabled, for messages mapped to domains selected to BLOCK, the script will generate a separate email per message to the configured DNSBL recipients before any delete step. In ExportAttach mode, the original message is exported to .eml and attached to each report email.

.PARAMETER DnsblRecipients
One or more DNSBL submission addresses. Example: @('submit.gbRjyoiL5EmAY4n7@spam.spamcop.net','reportphishing@apwg.org').

.PARAMETER DnsblMode
Reporting mode. ExportAttach attaches the original .eml to a new email (recommended when a custom From is needed). Allowed: ExportAttach.

.PARAMETER DnsblFrom
Optional sender address to use for DNSBL emails (ExportAttach only). If omitted, defaults to abuse@<primary-domain>, where primary-domain is resolved from your tenant (default accepted domain or the connected UPN domain). Requires Send As or alias on the sending identity.

.PARAMETER DnsblReason
Optional reason string used when exporting messages (Export-QuarantineMessage -ReasonForExport). Also included in the email body.

.PARAMETER DryRun
Simulates actions without making changes: does not release or delete quarantine items, and does not create TABL entries. Adds [DryRun] notices to output while preserving counts for preview.

.LINK
https://learn.microsoft.com/powershell/exchange/exchange-online-powershell-v2
https://github.com/publicsuffix/list

.DOCUMENTATION
Connect-ExchangeOnline           https://learn.microsoft.com/powershell/module/exchange/connect-exchangeonline
Disconnect-ExchangeOnline        https://learn.microsoft.com/powershell/module/exchange/disconnect-exchangeonline
Get-QuarantineMessage            https://learn.microsoft.com/powershell/module/exchange/get-quarantinemessage
Get-QuarantineMessageHeader      https://learn.microsoft.com/powershell/module/exchange/get-quarantinemessageheader
Get-TenantAllowBlockListItems    https://learn.microsoft.com/powershell/module/exchange/get-tenantallowblocklistitems
New-TenantAllowBlockListItems    https://learn.microsoft.com/powershell/module/exchange/new-tenantallowblocklistitems
Delete-QuarantineMessage         https://learn.microsoft.com/powershell/module/exchangepowershell/delete-quarantinemessage

.CHANGELOG
2.1.1 (2026 - 04 - 28)
- DNSBL reporting now requires the explicit switch or an explicit -UseDefaults run with Pref_ReportToDnsblDefault = 'Y'.
- Added helper regression coverage for PSL loading, client-side filtering, export fallback, and expiry validation.
2.1.0 (2025 - 12 - 17)
- Added filters for Quarantine reason and Policy type (default: all).
- Prevent recommending blocks for tenant-owned domains (Accepted, Remote, DKIM).
- GridView shows 'Number of emails' per domain; console shows Allowed? + Emails.
- Summary includes concise list of allow-suppressed domains (when not overriding).
2.0 (2025 - 12 - 17)
- Added TABL Allow snapshot, conflict detection, CSV export (TABL_allow_conflicts_YYYYMMDD.csv).
- Default suppression of allow-listed candidates with -OverrideAllowConflicts to include them.
1.6.0 (2025 - 12 - 16)
- Added header coverage validation mode (-ValidateHeaders, stats, optional gating).
- Implemented PSL .dat cache and quick fetch with async refresh; enforced onmicrosoft.com rule.
- Prioritised exact smtp.mailfrom over roots; reduced duplicate noise; refined confirmation flow.
- Skipped Released quarantine messages before analysis.
- Fixed single-item paging AddRange issue for quarantine pages.
- Added comprehensive comment headers and module-level documentation links.
- Added end-of-run summary (added/confirmed/unconfirmed/skipped).
- Added optional deletion of analysed quarantine messages: -DeleteQuarantineMode Yes | No | List | Permanent (default: List).
1.5.0 (2025 - 12 - 15)
- Do not offer duplicates: union of expiring and no-expiration TABL entries in snapshot.
- Preserve tenant identifiers for *.onmicrosoft.com via PSL rule.
- Confirm additions with refresh + retry, print [OK] when confirmed.
- Added -BlockExpiry (Never, 1d, 7d, 30d, Date) and -BlockExpiryDate; attaches formatted note.

.EXAMPLE
PS> .\Quarantine-To-Block.ps1 -AutoInstall -BlockExpiry 7d
Connects to EXO, reviews quarantine, and offers discovered sender domains for blocking, expiring after 7 days.
#>

[CmdletBinding()]
param(
    # Connection & behaviour
    [string]$UserPrincipalName = "",
    [switch]$AutoInstall,

    # Paging / reliability
    [int]$PageSize = 1000,
    [int]$MaxRetries = 3,
    [int]$BackoffSecondsBase = 3,

    # Logging
    [string]$TranscriptPath = "$env:TEMP\quarantine-to-block.transcript.log",
    [int]$MismatchCsvWarnThreshold = 50000,

    # PSL input (optional); if omitted, script tries .\psl.json then fallback list
    [string]$PslJsonPath = "",

    # Quarantine type filters (off by default)
    [string[]]$QuarantineTypesFilter = @(),

    # Quarantine reason filter (default: all)
    [ValidateSet('Transport rule', 'Bulk', 'Spam', 'Data Loss Prevention', 'Malware', 'Admin action - File type block', 'Phishing', 'High confidence phishing')]
    [string[]]$QuarantineReasonFilter = @(),

    # ---------------------------
    # DNSBL reporting (ExportAttach via Microsoft Graph)
    # ---------------------------

    # Policy type filter (default: all)
    [ValidateSet('Anti-malware policy', 'Safe Attachments policy', 'Anti-phishing policy', 'Anti-spam policy', 'Transport rule', 'Data Loss Prevention Rule')]
    [string[]]$PolicyTypeFilter = @(),

    # Process Exclusions (merged: built-in 'crispykangaroo.com' + param + JSON)
    [string[]]$ExcludedDomains = @(),
    [string]$ExcludedDomainsJsonPath = "",

    # Non-interactive release options (uses top-level preferences; still shows grids)
    # Purpose: Skip per-message release prompts and use script-level defaults for release options.
    # Usage: -UseDefaults
    [switch]$UseDefaults,

    # DNSBL reporting (ExportAttach)
    # Purpose: Before deletion, report messages whose domains were selected for BLOCK to DNSBL recipients.
    # Usage: -ReportToDnsbl [-DnsblRecipients addr1,addr2] [-DnsblMode ExportAttach] [-DnsblFrom abuse@domain] [-DnsblReason "text"]
    [switch]$ReportToDnsbl,
    [string[]]$DnsblRecipients = @(),
    [ValidateSet('ExportAttach')]
    [string]$DnsblMode = 'ExportAttach',
    [string]$DnsblFrom = '',
    [string]$DnsblReason = 'Quarantine-To-Block DNSBL report',
    # Post-analysis deletion mode for analysed quarantine messages
    # Purpose: Controls what happens to analysed quarantine items after the review step.
    # Usage: -DeleteQuarantineMode Yes|No|List|Permanent
    # Allowed values:
    # - Yes: Delete all analysed messages (soft delete) without further prompts.
    # - No:  Do not delete any analysed messages.
    # - List (default): Open a selection grid to choose which messages to delete.
    # - Permanent: Hard delete all analysed messages (safety prompt appears in workflow).
    [ValidateSet('Yes', 'No', 'List', 'Permanent')]
    [string]$DeleteQuarantineMode = 'List'
    ,
    # Override default suppression of allow-listed candidates
    # Purpose: Include domains that appear on the TABL Allow list in the block candidate list.
    # Usage: -OverrideAllowConflicts
    [switch]$OverrideAllowConflicts
    ,
    # Toggle allow-list conflict detection and export (useful to disable for speed)
    # Purpose: Enable/disable detection and CSV export of Allow-list conflicts.
    # Usage: -DetectAllowConflicts:$true | -DetectAllowConflicts:$false
    # Default: $true (enabled). Set to $false to skip detection for speed.
    [bool]$DetectAllowConflicts = $true
    ,
    # Include provider roots (gmail.com, outlook.com, etc.) in BLOCK candidates
    # Purpose: By default, common provider domains are excluded to avoid broad blocks.
    # Usage: -IncludeProviderRoots to include them in the candidate list.
    [switch]$IncludeProviderRoots
    ,
    # Block duration configuration
    # Purpose: Controls the expiry applied to new TABL Block entries created by this script.
    # Usage: -BlockExpiry Never|1d|7d|30d|Date [-BlockExpiryDate yyyy-MM-dd]
    # Allowed values: 'Never', '1d', '7d', '30d', 'Date'
    # Notes:
    # - When 'Date' is supplied, also pass -BlockExpiryDate with a specific date within 30 days from today.
    # - Example: -BlockExpiry 7d   or   -BlockExpiry Date -BlockExpiryDate '2026-01-31'
    [ValidateSet('Never', '1d', '7d', '30d', 'Date')]
    [string]$BlockExpiry = 'Never',
    [datetime]$BlockExpiryDate,

    # Back-compat; prefer -BlockExpiry (kept so existing runs still work)
    # Purpose: Legacy switch that maps to a non-expiring block. Prefer -BlockExpiry Never.
    # Usage: -NoExpiration
    [switch]$NoExpiration
    ,
    # Header validation (assurance) - opt-in
    # Purpose: Measure and optionally enforce a minimum success rate for Get-QuarantineMessageHeader calls.
    # Usage: -ValidateHeaders [-MinHeaderSuccessRate <0..1>] [-FailOnLowHeaderCoverage] [-HeaderSecondPassDelaySeconds <int>] [-MaxHeaderDumps <int>] [-HeaderDumpFolder <path>]
    # Examples:
    # -ValidateHeaders -MinHeaderSuccessRate 0.9 -FailOnLowHeaderCoverage
    # -ValidateHeaders -MaxHeaderDumps 50 -HeaderDumpFolder 'C:\Temp\header-dumps'
    [switch]$ValidateHeaders,
    [ValidateRange(0.0, 1.0)]
    [double]$MinHeaderSuccessRate = 0.95,
    # If specified, the script will exit with the documented non-success code when coverage < MinHeaderSuccessRate.
    [switch]$FailOnLowHeaderCoverage,
    # Delay between header retrieval passes when performing a second attempt (seconds).
    [int]$HeaderSecondPassDelaySeconds = 10,
    # Maximum number of header payloads to dump to disk for diagnostics (0 = none).
    [int]$MaxHeaderDumps = 0,
    # Folder used when dumping headers.
    [string]$HeaderDumpFolder = (Join-Path $env:TEMP 'quarantine-header-dumps')
    ,
    # Delay before first TABL confirmation snapshot (seconds)
    # Purpose: Time to wait before the first TABL snapshot after adding entries.
    # Usage: -InitialConfirmDelaySeconds <0..60>
    [ValidateRange(0, 60)]
    [int]$InitialConfirmDelaySeconds = 3
    ,
    # Maximum total seconds to wait for snapshot confirmations after add
    # Purpose: Upper bound on total wait time across confirmation backoffs.
    # Usage: -MaxConfirmWaitSeconds <0..300>
    [ValidateRange(0, 300)]
    [int]$MaxConfirmWaitSeconds = 30
    ,
    # Diagnostics: print timing for connect and early stages; probe key endpoints
    # Purpose: Prints extra diagnostics including connection timings and key endpoint probes.
    # Usage: -DiagConnectionTiming
    [switch]$DiagConnectionTiming
    ,
    # Optional app-only authentication (faster, non-interactive, requires EXO app permissions)
    # Purpose: Use app-only auth for non-interactive runs (requires EXO application permissions and a cert).
    # Usage: -PreferAppOnly -AppId '<GUID>' -Organization '<tenantGUID or domain>' -CertificateThumbprint '<thumbprint>'
    # Notes:
    # - All three values are typically required when -PreferAppOnly is used.
    # - Example: -PreferAppOnly -AppId '00000000-0000-0000-0000-000000000000' -Organization 'contoso.onmicrosoft.com' -CertificateThumbprint 'ABCDEF1234...'
    [string]$AppId = "",
    [string]$Organization = "",
    [string]$CertificateThumbprint = "",
    [switch]$PreferAppOnly
    ,
    # Trust cmdlet success as confirmation (uses input entries when output lacks Entries)
    # Purpose: When EXO returns no Entries in the output, trust cmdlet success and use inputs for confirmation logic.
    # Usage: -PreferCmdletConfirm
    [switch]$PreferCmdletConfirm
    ,

    # Simulation mode: no changes to EXO or TABL
    # Purpose: Perform a dry run; print intended actions without modifying EXO or TABL.
    # Usage: -DryRun
    [switch]$DryRun
    ,
    # Library/test mode: skip MAIN execution to allow function-only usage (dot-sourcing/tests)
    [switch]$NoMain
)

# ---------------------------
# DNSBL reporting (ExportAttach via Microsoft Graph)
# ---------------------------

function Write-ConsoleMessage {
    <#
    .SYNOPSIS
    Writes interactive status text to the current host.

    .DESCRIPTION
    Centralises user-facing console output for this script so dry-run notices,
    progress updates, selection guidance, and summaries remain readable without
    scattering direct host calls throughout the workflow.

    .PARAMETER Message
    Text to display to the current operator.

    .PARAMETER ForegroundColor
    Optional console colour applied while writing the message.

    .PARAMETER NoNewline
    Writes the message without appending a trailing newline.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, Position = 0)][AllowEmptyString()][string]$Message,
        [System.ConsoleColor]$ForegroundColor,
        [switch]$NoNewline
    )

    $renderedMessage = $Message

    if ($PSBoundParameters.ContainsKey('ForegroundColor')) {
        $prefix = switch ([string]$ForegroundColor) {
            'Green' { $PSStyle.Foreground.Green; break }
            'Yellow' { $PSStyle.Foreground.Yellow; break }
            'DarkYellow' { $PSStyle.Foreground.Yellow; break }
            'Gray' { $PSStyle.Foreground.BrightBlack; break }
            'Cyan' { $PSStyle.Foreground.Cyan; break }
            'Magenta' { $PSStyle.Foreground.Magenta; break }
            default { '' }
        }

        if (-not [string]::IsNullOrEmpty($prefix)) {
            $renderedMessage = '{0}{1}{2}' -f $prefix, $Message, $PSStyle.Reset
        }
    }

    if ($NoNewline) {
        Write-Verbose 'Write-ConsoleMessage received -NoNewline; emitting a standard line because information-stream output is line-oriented.'
    }

    Write-Information -MessageData $renderedMessage -InformationAction Continue
}

function Resolve-PrimaryDomain {
    <#
    .SYNOPSIS
    Resolves the most suitable tenant domain for operator-originated actions.

    .DESCRIPTION
    DNSBL reporting needs a stable sender domain when the operator does not
    provide one. This helper prefers a non-onmicrosoft accepted domain and only
    falls back to the connected Exchange Online UPN domain when tenant metadata
    is unavailable.

    .OUTPUTS
    [string] A tenant domain suitable for derived sender addresses, or $null.
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param()
    try {
        $ads = Get-AcceptedDomain -ErrorAction Stop
        $def = $ads | Where-Object { $_.IsDefault -and $_.DomainName -notlike '*.onmicrosoft.com' } | Select-Object -First 1
        if ($def) { return $def.DomainName }
        $cand = $ads | Where-Object { $_.DomainType -eq 'Authoritative' -and $_.DomainName -notlike '*.onmicrosoft.com' } | Select-Object -First 1
        if ($cand) { return $cand.DomainName }
    }
    catch { Write-Verbose ("Resolve-PrimaryDomain accepted-domain lookup failed: {0}" -f $_.Exception.Message) }
    try {
        $ci = Get-ConnectionInformation | Where-Object { $_.Name -like 'ExchangeOnline*' } | Select-Object -First 1
        if ($ci -and $ci.UserPrincipalName -match '@') { return ($ci.UserPrincipalName -split '@')[1] }
    }
    catch { Write-Verbose ("Resolve-PrimaryDomain connection lookup failed: {0}" -f $_.Exception.Message) }
    return $null
}

function Resolve-DnsblFromAddress {
    <#
    .SYNOPSIS
    Resolves the effective sender address for DNSBL submissions.

    .DESCRIPTION
    DNSBL reporting supports an explicit sender, a configured default, or an
    automatically derived abuse@ address. This helper keeps that precedence in
    one place so the reporting workflow does not duplicate the same fallback
    logic.

    .PARAMETER ParamFrom
    Sender address supplied on the command line.

    .OUTPUTS
    [string] The sender address to use, or $null when none can be resolved.
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param([string]$ParamFrom)
    if (-not [string]::IsNullOrWhiteSpace($ParamFrom)) { return $ParamFrom }
    if (-not [string]::IsNullOrWhiteSpace($Pref_DnsblFromDefault)) { return $Pref_DnsblFromDefault }
    $dom = Resolve-PrimaryDomain
    if ($dom) { return ('abuse@{0}' -f $dom) }
    return $null
}

function Test-MailAddressFormat {
    <#
    .SYNOPSIS
    Performs a lightweight email-address format check.

    .DESCRIPTION
    DNSBL submission addresses and derived sender addresses should be validated
    before Microsoft Graph calls are attempted. This helper provides a simple
    guardrail so invalid values are skipped early with clear warnings.

    .PARAMETER Address
    Email address to validate.

    .OUTPUTS
    [bool] True when the value resembles a usable email address.
    #>
    [CmdletBinding()]
    [OutputType([bool])]
    param([string]$Address)

    if ([string]::IsNullOrWhiteSpace($Address)) { return $false }
    return [bool]([regex]::IsMatch($Address.Trim(), '^[^@\s]+@[^@\s]+\.[^@\s]+$'))
}

function Test-DnsblReportingEnabled {
    <#
    .SYNOPSIS
    Determines whether DNSBL reporting is explicitly enabled for the run.

    .DESCRIPTION
    Reporting to third-party abuse desks is a material outbound action. This
    helper keeps the enablement rule explicit by allowing reporting only when
    the operator passes ReportToDnsbl or intentionally runs UseDefaults with the
    matching preference enabled.

    .OUTPUTS
    [bool] True when DNSBL reporting should execute for this run.
    #>
    [CmdletBinding()]
    [OutputType([bool])]
    param()

    if ($ReportToDnsbl) { return $true }
    if ($UseDefaults -and ($Pref_ReportToDnsblDefault -eq 'Y')) { return $true }
    return $false
}

function Get-DnsblScopeRootSet {
    <#
    .SYNOPSIS
    Builds the registrable-domain scope used by DNSBL reporting.

    .DESCRIPTION
    DNSBL reporting should follow the domains the operator selected to block,
    with optional expansion to provider roots when the preference requires it.
    This helper keeps the selected-root and provider-root merge logic consistent
    and de-duplicated.

    .PARAMETER SelectedDomains
    Domains selected for blocking during the current run.

    .OUTPUTS
    [string[]] Unique eTLD+1 roots that are eligible for DNSBL reporting.
    #>
    [CmdletBinding()]
    [OutputType([string[]])]
    param([string[]]$SelectedDomains)

    $roots = @(
        $SelectedDomains |
        Where-Object { $_ -and $_.Trim() -ne '' } |
        ForEach-Object { Get-ETLDPlusOne $_ } |
        Where-Object { $_ }
    ) | Select-Object -Unique

    if ($Pref_DnsblScopeDefault -eq 'SelectedPlusExcludedProviders') {
        $providerRoots = @(
            $Pref_DefaultExcluded |
            ForEach-Object { Get-ETLDPlusOne $_ } |
            Where-Object { $_ }
        ) | Select-Object -Unique
        $roots = @(@($roots) + @($providerRoots)) | Select-Object -Unique
    }

    return [string[]]@($roots)
}

function Test-GraphMailReadiness {
    <#
    .SYNOPSIS
    Validates Microsoft Graph mail prerequisites before sending reports.

    .DESCRIPTION
    DNSBL reporting depends on a usable sender, at least one valid recipient,
    and a Graph context that can send mail. This helper consolidates those
    checks so the reporting workflow can fail fast with actionable diagnostics.

    .PARAMETER FromUser
    Effective sender address used for delegated Graph mail submission.

    .PARAMETER Recipients
    Candidate DNSBL recipient addresses.

    .OUTPUTS
    [pscustomobject] Validation result containing Ok and ValidRecipients.
    #>
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [Parameter(Mandatory)][string]$FromUser,
        [Parameter()][string[]]$Recipients
    )

    $validRecipients = @($Recipients | Where-Object { Test-MailAddressFormat $_ } | Select-Object -Unique)
    $invalidRecipients = @($Recipients | Where-Object { -not (Test-MailAddressFormat $_) } | Select-Object -Unique)
    foreach ($invalidRecipient in $invalidRecipients) {
        Write-Warning ("Skipping invalid DNSBL recipient address: {0}" -f $invalidRecipient)
    }

    if (-not (Test-MailAddressFormat $FromUser)) {
        Write-Warning ("DNSBL From address is invalid: {0}" -f $FromUser)
        return [pscustomobject]@{ Ok = $false; ValidRecipients = $validRecipients }
    }

    $ctx = $null
    try { $ctx = Get-MgContext }
    catch { Write-Verbose ("Get-MgContext validation failed: {0}" -f $_.Exception.Message) }

    if (-not $ctx) {
        Write-Warning 'Microsoft Graph context is unavailable after connection; skipping DNSBL reporting.'
        return [pscustomobject]@{ Ok = $false; ValidRecipients = $validRecipients }
    }

    $ctxScopes = @($ctx.Scopes)
    if ($ctxScopes.Count -gt 0 -and ('Mail.Send' -notin $ctxScopes)) {
        Write-Warning ("Microsoft Graph context does not include Mail.Send. Current scopes: {0}" -f (($ctxScopes | Sort-Object -Unique) -join ', '))
        return [pscustomobject]@{ Ok = $false; ValidRecipients = $validRecipients }
    }

    try {
        if ($ctx.Account -and ($ctx.Account -ne $FromUser)) {
            Write-Verbose ("Graph context account {0} differs from DNSBL sender {1}; delegated send may require send-as rights." -f $ctx.Account, $FromUser)
        }
    }
    catch {
        Write-Verbose ("Graph context account validation failed: {0}" -f $_.Exception.Message)
    }

    if ($validRecipients.Count -le 0) {
        Write-Warning 'DNSBL reporting enabled but no valid recipient addresses remain after validation; skipping.'
        return [pscustomobject]@{ Ok = $false; ValidRecipients = @() }
    }

    return [pscustomobject]@{ Ok = $true; ValidRecipients = $validRecipients }
}

function Initialize-GraphModule {
    <#
    .SYNOPSIS
    Ensures the Microsoft Graph module is available for DNSBL reporting.

    .DESCRIPTION
    DNSBL reporting uses Microsoft Graph to submit exported messages as email
    attachments. This helper checks for the module first and only attempts an
    install when it is genuinely missing.

    .OUTPUTS
    [bool] True when the Microsoft Graph module is available for use.
    #>
    [CmdletBinding()]
    [OutputType([bool])]
    param()
    $loaded = Get-Module Microsoft.Graph -ListAvailable
    if ($loaded) { return $true }
    try {
        Install-Module Microsoft.Graph -Scope CurrentUser -Force -AllowClobber -ErrorAction Stop
        return $true
    }
    catch {
        Write-Warning ("Unable to install Microsoft.Graph: {0}" -f $_.Exception.Message)
        return $false
    }
}

function Connect-GraphMailIfNeeded {
    <#
    .SYNOPSIS
    Reuses or establishes a Microsoft Graph context for mail submission.

    .DESCRIPTION
    The DNSBL reporting stage should not prompt repeatedly when a suitable
    Graph context already exists. This helper attempts reuse first and only
    performs a Mail.Send connection when needed.

    .OUTPUTS
    [bool] True when a usable Microsoft Graph context is available.
    #>
    [CmdletBinding()]
    [OutputType([bool])]
    param()
    try { if (Get-MgContext) { return $true } }
    catch { Write-Verbose ("Get-MgContext pre-check failed: {0}" -f $_.Exception.Message) }
    try {
        Connect-MgGraph -NoWelcome -Scopes 'Mail.Send' | Out-Null
        return $true
    }
    catch {
        Write-Warning ("Connect-MgGraph failed: {0}" -f $_.Exception.Message)
        return $false
    }
}

function Send-GraphMailWithAttachment {
    <#
    .SYNOPSIS
    Sends a single DNSBL report email with an attached exported message.

    .DESCRIPTION
    ExportAttach mode creates one message per exported quarantine item and per
    recipient. This helper encapsulates the attachment payload construction and
    retry logic so transient send failures do not leak into the main workflow.

    .PARAMETER FromUser
    Delegated Graph sender address.

    .PARAMETER To
    Recipient address for the DNSBL report.

    .PARAMETER Subject
    Subject line to submit.

    .PARAMETER BodyText
    Plain-text body for the report email.

    .PARAMETER AttachmentPath
    Local path to the exported .eml file.

    .PARAMETER MaxRetries
    Maximum resend attempts after the initial failure.

    .PARAMETER BackoffSecondsBase
    Base delay used to calculate linear backoff between retries.

    .OUTPUTS
    [bool] True when the message is accepted by Microsoft Graph.
    #>
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        [Parameter(Mandatory)][string]$FromUser,
        [Parameter(Mandatory)][string]$To,
        [Parameter(Mandatory)][string]$Subject,
        [Parameter(Mandatory)][string]$BodyText,
        [Parameter(Mandatory)][string]$AttachmentPath,
        [int]$MaxRetries = 0,
        [int]$BackoffSecondsBase = 2
    )
    $bytes = [IO.File]::ReadAllBytes($AttachmentPath)
    $attName = [IO.Path]::GetFileName($AttachmentPath)
    $attempt = 0
    while ($true) {
        $msg = @{
            subject      = $Subject
            body         = @{ contentType = 'Text'; content = $BodyText }
            toRecipients = @(@{ emailAddress = @{ address = $To } })
            attachments  = @(@{
                    '@odata.type' = '#microsoft.graph.fileAttachment'
                    name          = $attName
                    contentBytes  = [Convert]::ToBase64String($bytes)
                })
        }
        try {
            Send-MgUserMail -UserId $FromUser -Message $msg -SaveToSentItems | Out-Null
            return $true
        }
        catch {
            $attempt++
            if ($attempt -gt $MaxRetries) {
                Write-Warning ("Send to {0} failed after {1} attempt(s): {2}" -f $To, $attempt, $_.Exception.Message)
                return $false
            }
            $delay = [Math]::Max(1, $BackoffSecondsBase * $attempt)
            Start-Sleep -Seconds $delay
        }
    }
}

function Invoke-ReportToDnsbl {
    <#
    .SYNOPSIS
    Reports selected blocked-message samples to configured DNSBL recipients.

    .DESCRIPTION
    This workflow is intentionally decoupled from blocking and deletion so the
    operator can preview, scope, and validate outbound reporting independently.
    It exports only messages whose roots match the selected block domains, then
    submits them through Microsoft Graph in attachment form.

    .PARAMETER Messages
    Quarantine messages still in scope after filtering and release handling.

    .PARAMETER SelectedDomains
    Domains selected for blocking during the current run.

    .PARAMETER MaxRetries
    Maximum retry attempts for outbound report submission.

    .PARAMETER BackoffSecondsBase
    Base delay used to calculate linear backoff for retries.

    .OUTPUTS
    [pscustomobject] Summary of reported, skipped, and failed DNSBL actions.
    #>
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [Parameter()][AllowEmptyCollection()][object[]]$Messages,
        [Parameter()][string[]]$SelectedDomains,
        [int]$MaxRetries = 2,
        [int]$BackoffSecondsBase = 2
    )

    if (-not $Messages -or $Messages.Count -le 0) {
        return [pscustomobject]@{ Reported = 0; MessagesReported = 0; RecipientSubmissionsSent = 0; Failed = 0; Skipped = 0 }
    }
    if (-not (Test-DnsblReportingEnabled)) {
        return [pscustomobject]@{ Reported = 0; MessagesReported = 0; RecipientSubmissionsSent = 0; Failed = 0; Skipped = 0 }
    }

    $effRecipients = @()
    if ($DnsblRecipients -and $DnsblRecipients.Count -gt 0) { $effRecipients = $DnsblRecipients }
    elseif ($Pref_DnsblRecipientsDefault -and $Pref_DnsblRecipientsDefault.Count -gt 0) { $effRecipients = $Pref_DnsblRecipientsDefault }
    if ($effRecipients.Count -le 0) {
        Write-Warning 'DNSBL reporting enabled but no recipients configured; skipping.'
        return [pscustomobject]@{ Reported = 0; MessagesReported = 0; RecipientSubmissionsSent = 0; Failed = 0; Skipped = 0 }
    }

    $effFrom = Resolve-DnsblFromAddress -ParamFrom $DnsblFrom
    if ([string]::IsNullOrWhiteSpace($effFrom)) {
        Write-Warning 'Unable to resolve From address for DNSBL reporting; skipping.'
        return [pscustomobject]@{ Reported = 0; MessagesReported = 0; RecipientSubmissionsSent = 0; Failed = 0; Skipped = 0 }
    }

    $roots = Get-DnsblScopeRootSet -SelectedDomains $SelectedDomains

    if ($DryRun) {
        if (-not $SelectedDomains -or $SelectedDomains.Count -le 0) {
            Write-ConsoleMessage ("[DryRun] DNSBL reporting skipped: no selected block domains.") -ForegroundColor DarkYellow
            return [pscustomobject]@{ Reported = 0; MessagesReported = 0; RecipientSubmissionsSent = 0; Failed = 0; Skipped = $Messages.Count }
        }
        $matchCount = 0
        foreach ($m in $Messages) {
            try {
                $norm = ConvertTo-NormalizedAddress $m.SenderAddress
                if ($norm) {
                    $senderRoot = Get-ETLDPlusOne (ConvertTo-NormalizedDomain $norm)
                    if ($roots -contains $senderRoot) { $matchCount++ }
                }
            }
            catch {
                Write-Verbose ("DNSBL dry-run match evaluation failed for {0}: {1}" -f $m.Identity, $_.Exception.Message)
            }
        }
        $skipped = ($Messages.Count - $matchCount)
        Write-ConsoleMessage ("[DryRun] Would send DNSBL reports for {0} messages to {1} valid recipient(s): {2} (Skipped: {3})" -f $matchCount, $effRecipients.Count, ($effRecipients -join ', '), $skipped) -ForegroundColor DarkYellow
        return [pscustomobject]@{ Reported = 0; MessagesReported = 0; RecipientSubmissionsSent = 0; Failed = 0; Skipped = $skipped }
    }

    if (-not (Initialize-GraphModule)) {
        return [pscustomobject]@{ Reported = 0; MessagesReported = 0; RecipientSubmissionsSent = 0; Failed = $Messages.Count; Skipped = 0 }
    }
    if (-not (Connect-GraphMailIfNeeded)) {
        return [pscustomobject]@{ Reported = 0; MessagesReported = 0; RecipientSubmissionsSent = 0; Failed = $Messages.Count; Skipped = 0 }
    }

    $graphCheck = Test-GraphMailReadiness -FromUser $effFrom -Recipients $effRecipients
    if (-not $graphCheck.Ok) {
        return [pscustomobject]@{ Reported = 0; MessagesReported = 0; RecipientSubmissionsSent = 0; Failed = $Messages.Count; Skipped = 0 }
    }
    $effRecipients = @($graphCheck.ValidRecipients)

    # Choose effective export reason (param or default preference)
    $effectiveReason = $DnsblReason
    if ([string]::IsNullOrWhiteSpace($effectiveReason) -and -not [string]::IsNullOrWhiteSpace($Pref_DnsblReasonDefault)) { $effectiveReason = $Pref_DnsblReasonDefault }

    $messagesReported = 0; $recipientSubmissionsSent = 0; $failed = 0; $skipped = 0
    $tmpRoot = Join-Path $env:TEMP ('q2b_dnsbl_' + (Get-Date -Format 'yyyyMMdd_HHmmss'))
    try { New-Item -ItemType Directory -Path $tmpRoot -Force | Out-Null }
    catch {
        Write-Warning ("Failed to create DNSBL working folder {0}: {1}" -f $tmpRoot, $_.Exception.Message)
        return [pscustomobject]@{ Reported = 0; MessagesReported = 0; RecipientSubmissionsSent = 0; Failed = $Messages.Count; Skipped = 0 }
    }

    foreach ($m in $Messages) {
        $emlPath = $null
        $senderRoot = $null
        try {
            $norm = ConvertTo-NormalizedAddress $m.SenderAddress
            if ($norm) { $senderRoot = Get-ETLDPlusOne (ConvertTo-NormalizedDomain $norm) }
        }
        catch {
            Write-Verbose ("DNSBL sender-root evaluation failed for {0}: {1}" -f $m.Identity, $_.Exception.Message)
        }
        # Only report messages whose sender root matches selected block domains
        if (-not $senderRoot -or -not ($roots -contains $senderRoot)) { $skipped++; continue }

        $exp = $null
        try {
            # Prefer calling with -CompressOutput:$false. If the parameter doesn't exist on this EXO version,
            # fall back to the invocation without it.
            try {
                $exp = Export-QuarantineMessage -Identity $m.Identity -ReasonForExport $effectiveReason -ForceConversionToMime -CompressOutput:$false
            }
            catch [System.Management.Automation.ParameterBindingException] {
                if ($_.Exception.Message -match "matches parameter name 'CompressOutput'|Parameter set") {
                    $exp = Export-QuarantineMessage -Identity $m.Identity -ReasonForExport $effectiveReason -ForceConversionToMime
                }
                else {
                    throw
                }
            }
        }
        catch { Write-Warning ("Export failed for {0}: {1}" -f $m.Identity, $_.Exception.Message); $failed++; continue }
        if (-not $exp -or -not $exp.eml) { Write-Warning ("Export returned no data for {0}" -f $m.Identity); $failed++; continue }
        $emlBytes = [Convert]::FromBase64String($exp.eml)
        $fileSafeSubject = ($m.Subject -replace '[^A-Za-z0-9 _.-]', '_')
        $rootForName = if ($null -ne $senderRoot -and $senderRoot -ne '') { $senderRoot } else { 'unknown' }
        $emlPath = Join-Path $tmpRoot ("{0}_{1}.eml" -f $rootForName, $fileSafeSubject.Substring(0, [Math]::Min(40, $fileSafeSubject.Length)))
        try { [IO.File]::WriteAllBytes($emlPath, $emlBytes) } catch { Write-Warning ("Write .eml failed for {0}: {1}" -f $m.Identity, $_.Exception.Message); $failed++; continue }

        # Subject: original message subject only; Body: empty
        $subj = $m.Subject
        $body = ''

        $messageReported = $false
        foreach ($rcpt in $effRecipients) {
            $ok = Send-GraphMailWithAttachment -FromUser $effFrom -To $rcpt -Subject $subj -BodyText $body -AttachmentPath $emlPath -MaxRetries $MaxRetries -BackoffSecondsBase $BackoffSecondsBase
            if ($ok) {
                $recipientSubmissionsSent++
                $messageReported = $true
            }
            else { $failed++ }
        }
        if ($messageReported) { $messagesReported++ }

        if ($emlPath -and (Test-Path -LiteralPath $emlPath)) {
            try { Remove-Item -LiteralPath $emlPath -Force -ErrorAction Stop }
            catch { Write-Verbose ("Failed to remove temporary DNSBL export {0}: {1}" -f $emlPath, $_.Exception.Message) }
        }
    }

    if (Test-Path -LiteralPath $tmpRoot) {
        try { Remove-Item -LiteralPath $tmpRoot -Recurse -Force -ErrorAction Stop }
        catch { Write-Verbose ("Failed to remove DNSBL working folder {0}: {1}" -f $tmpRoot, $_.Exception.Message) }
    }

    return [pscustomobject]@{
        Reported                 = $recipientSubmissionsSent
        MessagesReported         = $messagesReported
        RecipientSubmissionsSent = $recipientSubmissionsSent
        Failed                   = $failed
        Skipped                  = $skipped
    }
}

# ---------------------------
# Configuration parameters
# ---------------------------
# Release stage defaults and behaviour. Edit these to change the UX defaults.
# All values are validated downstream; unsafe values are ignored.
$Pref_ReleaseToAllDefault = 'Y'       # 'Y' to release to all original recipients; 'N' to release only to listed recipient
$Pref_ReportFalsePositiveDefault = 'Y'# 'Y' to report false positive (spam only); 'N' to skip reporting
$Pref_AllowSenderDefault = 'N'        # 'Y' to set AllowSender on release; 'N' to skip
$Pref_CreateAllowDefault = 'Y'        # 'Y' to create a Tenant Allow entry; 'N' to skip
$Pref_AllowScopeDefault = 'Domain'    # 'Address' for per-address allow; 'Domain' for domain-level allow
$Pref_AllowExpiryDefault = '45'       # One of: '45' (last-used), '1', '7', '30', '45', 'Date'
$Pref_AllowExpiryDateDefault = $null  # When 'Date' is selected, supply a specific [datetime] (optional)
$Pref_DeleteAfterReleaseDefault = 'None' # 'None', 'Soft', or 'Hard'
$Pref_AllowNoteAuto = $true           # When true, always use Get-BlockNote for allow-entry notes (mandatory)
$Pref_UseDefaultsNoPromptsDefault = $false # When true, skip release prompts and use defaults
$Pref_AllowNoteTemplate = 'Quarantine-To-Block script, added {DATE}, by {UPN}'
# Block stage defaults and behaviour. Edit these to change the UX defaults.
$Pref_BlockNoteTemplate = 'Quarantine-To-Block script, added {DATE}, by {UPN}'

# Default exclusions (registrable roots) merged with tenant-owned roots and parameters
$Pref_DefaultExcluded = @(
    'crispykangaroo.com',
    'ckpersonal.onmicrosoft.com',
    'hotmail.com',
    'outlook.com',
    'live.com',
    'gmail.com',
    'yahoo.com',
    'icloud.com',
    'aol.com'
)

# Block expiry defaults (mirrors -BlockExpiry / -BlockExpiryDate params)
# One of: 'Never','1d','7d','30d','Date'. When 'Date', supply a valid Pref_BlockExpiryDateDefault.
$Pref_BlockExpiryDefault = 'Never'
$Pref_BlockExpiryDateDefault = $null

# DNSBL reporting defaults
$Pref_ReportToDnsblDefault = 'N'                     # 'Y' to enable reporting only when -UseDefaults is explicitly requested
$Pref_DnsblModeDefault = 'ExportAttach'              # Only supported mode in this version
$Pref_DnsblRecipientsDefault = @(
    'submit.gbRjyoiL5EmAY4n7@spam.spamcop.net',
    'reportphishing@apwg.org'
)
$Pref_DnsblFromDefault = ''                          # If empty, auto-resolve abuse@<primary-domain>
$Pref_DnsblReasonDefault = 'Quarantine-To-Block DNSBL report'

# DNSBL scope preference: controls which messages are eligible for DNSBL reporting
# Allowed:
# - 'Selected' (default): only messages mapped to selected BLOCK domains
# - 'SelectedPlusExcludedProviders': include messages whose sender roots match provider exclusions
$Pref_DnsblScopeDefault = 'SelectedPlusExcludedProviders'

# Global interaction preference when -UseDefaults isn't passed
# Allowed: 'Prompt' (always prompt), 'Defaults' (never prompt), 'Auto' (prompt when OGV available; else defaults)
$Pref_InteractionMode = 'Defaults'

# Include provider roots in BLOCK candidates (safety default: 'N')
# When 'Y' or when -IncludeProviderRoots is passed, common provider domains
# (e.g., gmail.com, outlook.com) are not excluded from candidates.
$Pref_IncludeProviderRootsDefault = 'N'

# Authentication login mode for Exchange Online (user auth path)
# Allowed: 'WAM' (Windows Account Manager/MSAL broker) | 'WebLogin' (browser-based login) | 'Device' (device code flow)
# Tip: Use 'WebLogin' or 'Device' to avoid OS-level "add account to device" and management prompts.
$Pref_AuthLoginMode = 'WebLogin'
# When using WAM, passing -UserPrincipalName can mis-select accounts when the OS profile differs.
# Set false to omit UPN in WAM mode; set true to force UPN.
$Pref_AuthUseUPNWithWAM = $false

# Offer to persist corrected defaults back into this script file when found
$Pref_PromptToPersistDefaults = $false

# Confirmation backoff tuning for post-add confirmations
$Pref_ConfirmBackoffStartSeconds = 3
$Pref_ConfirmBackoffIncrementSeconds = 3
$Pref_ConfirmBackoffMaxSeconds = 12

# Validation helpers for preferences
function Test-ValidAllowScope {
    <#
    .SYNOPSIS
    Validates the configured allow-list scope preference.

    .DESCRIPTION
    The release workflow supports Address and Domain scopes only. This helper
    normalises persisted values so prompts and default-mode runs stay on a safe,
    known option even when the script file contains stale data.

    .PARAMETER Scope
    Candidate preference value.

    .OUTPUTS
    [string] A safe allow scope value.
    #>
    [OutputType([string])]
    param([string]$Scope)
    $s = if ($null -ne $Scope) { $Scope } else { '' }
    $s = $s.Trim()
    if ($s -in @('Address', 'Domain')) { return $s } else { return 'Address' }
}

function Test-ValidExpiryChoice {
    <#
    .SYNOPSIS
    Validates the configured allow-entry expiry choice.

    .DESCRIPTION
    Persisted defaults can drift over time. This helper constrains the release
    allow-entry expiry choice to the supported menu values before the workflow
    consumes it.

    .PARAMETER Choice
    Candidate expiry choice.

    .OUTPUTS
    [string] A supported expiry-choice token.
    #>
    [OutputType([string])]
    param([string]$Choice)
    $c = if ($null -ne $Choice) { $Choice } else { '' }
    $c = $c.Trim().ToUpperInvariant()
    if ($c -in @('45', '1', '7', '30', 'DATE')) { return $c } else { return '45' }
}

function ConvertTo-ExpiryDate {
    <#
    .SYNOPSIS
    Converts a supplied value to a valid [datetime] within allowed bounds, or $null on failure.

    .DESCRIPTION
    The block and allow workflows both support explicit expiry dates, but only
    within the near-term safety window documented by the script. This helper
    accepts the supported input formats, normalises the result to a date-only
    value, and rejects anything outside the permitted range.

    .PARAMETER Value
    The candidate value to parse; accepts [datetime] or string.

    .OUTPUTS
    [datetime] Parsed date within the supported window, or $null.
    #>
    [CmdletBinding()]
    [OutputType([datetime])]
    param([object]$Value)
    if ($null -eq $Value) { return $null }
    if ($Value -is [datetime]) { return [datetime]$Value }
    $s = [string]$Value
    if ([string]::IsNullOrWhiteSpace($s)) { return $null }
    $formats = @('yyyy-MM-dd', 'dd/MM/yyyy', 'MM/dd/yyyy', 'yyyy/MM/dd', 'dd-MM-yyyy', 'MM-dd-yyyy')
    $dt = $null
    foreach ($fmt in $formats) {
        if ([datetime]::TryParseExact($s, $fmt, [System.Globalization.CultureInfo]::InvariantCulture, [System.Globalization.DateTimeStyles]::None, [ref]$dt)) { break }
        if ([datetime]::TryParseExact($s, $fmt, [System.Globalization.CultureInfo]::CurrentCulture, [System.Globalization.DateTimeStyles]::None, [ref]$dt)) { break }
    }
    if ($null -eq $dt) {
        # Last resort: general parse respecting current culture
        if (-not [datetime]::TryParse($s, [ref]$dt)) { return $null }
    }
    # Constrain within 0..30 days ahead to align with UX.
    $today = (Get-Date).Date
    $dt = $dt.Date
    if ($dt -lt $today) { return $null }
    if ($dt -gt $today.AddDays(30)) { return $null }
    return $dt
}

function Get-InteractionMode {
    <#
    .SYNOPSIS
    Resolves the effective interaction mode based on the command-line switch and preference.

    .DESCRIPTION
    This script supports prompt-driven runs, explicit default-mode runs, and an
    automatic mode that falls back when Out-GridView is unavailable. Centralising
    that decision keeps interactive and unattended branches aligned.

    .OUTPUTS
    [string] One of: 'Prompt' | 'Defaults'
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param()

    if ($UseDefaults) { return 'Defaults' }
    $m = if ($null -ne $Pref_InteractionMode) { $Pref_InteractionMode } else { 'Prompt' }
    $m = $m.ToString().Trim()
    if ($m -in @('Prompt', 'Defaults', 'Auto')) {
        if ($m -eq 'Auto') {
            if (Test-OutGridViewAvailable) { return 'Prompt' } else { return 'Defaults' }
        }
        return $m
    }
    return 'Prompt'
}

function Test-ValidBlockExpiryChoice {
    <#
    .SYNOPSIS
    Validates the configured block-entry expiry choice.

    .DESCRIPTION
    Block creation accepts a constrained set of expiry modes. This helper keeps
    persisted defaults and runtime fallbacks aligned with that supported set.

    .PARAMETER Choice
    Candidate block expiry choice.

    .OUTPUTS
    [string] A safe block-expiry choice.
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param([string]$Choice)
    $c = if ($null -ne $Choice) { $Choice } else { '' }
    $c = $c.Trim()
    if ($c -in @('Never', '1d', '7d', '30d', 'Date')) { return $c } else { return 'Never' }
}

function Test-ValidYesNo {
    <#
    .SYNOPSIS
    Normalises a yes-or-no preference value.

    .DESCRIPTION
    Several persisted defaults use Y/N flags. This helper constrains them to a
    consistent uppercase representation so later prompts and branching remain
    deterministic.

    .PARAMETER Value
    Candidate Y/N value.

    .OUTPUTS
    [string] Either Y or N.
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param([string]$Value)
    $v = if ($null -ne $Value) { $Value } else { '' }
    $v = $v.Trim().ToUpperInvariant()
    if ($v -in @('Y', 'N')) { return $v } else { return 'N' }
}

function Test-ValidDnsblMode {
    <#
    .SYNOPSIS
    Validates the configured DNSBL reporting mode.

    .DESCRIPTION
    The current workflow supports only ExportAttach. This helper prevents stale
    or speculative values from being used during DNSBL submission.

    .PARAMETER Mode
    Candidate DNSBL mode.

    .OUTPUTS
    [string] A supported DNSBL mode value.
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param([string]$Mode)
    $m = if ($null -ne $Mode) { $Mode } else { '' }
    $m = $m.Trim()
    if ($m -in @('ExportAttach')) { return $m } else { return 'ExportAttach' }
}

function Test-ValidDeleteMode {
    <#
    .SYNOPSIS
    Validates the configured post-analysis delete mode.

    .DESCRIPTION
    Delete handling is intentionally constrained to the supported soft, hard, or
    no-delete branches. This helper ensures persisted defaults remain within that
    supported set.

    .PARAMETER Mode
    Candidate delete mode.

    .OUTPUTS
    [string] A supported delete mode value.
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param([string]$Mode)
    $m = if ($null -ne $Mode) { $Mode } else { '' }
    $m = $m.Trim().ToUpperInvariant()
    if ($m -in @('NONE', 'SOFT', 'HARD')) { return $m } else { return 'NONE' }
}

function Test-ValidInteractionMode {
    <#
    .SYNOPSIS
    Validates the configured interaction mode.

    .DESCRIPTION
    Interaction mode controls whether the script prompts, defaults silently, or
    decides automatically based on host capability. This helper rejects values
    outside that supported set.

    .PARAMETER Mode
    Candidate interaction mode.

    .OUTPUTS
    [string] A supported interaction mode value.
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param([string]$Mode)
    $m = if ($null -ne $Mode) { $Mode } else { '' }
    $m = $m.Trim()
    if ($m -in @('Prompt', 'Defaults', 'Auto')) { return $m } else { return 'Prompt' }
}

function Test-ValidAuthLoginMode {
    <#
    .SYNOPSIS
    Validates the configured Exchange Online authentication mode.

    .DESCRIPTION
    The script supports WAM, WebLogin, and Device flows only. This helper keeps
    preference validation aligned with the runtime parameter-detection logic.

    .PARAMETER Mode
    Candidate authentication mode.

    .OUTPUTS
    [string] A supported authentication mode.
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param([string]$Mode)
    $m = if ($null -ne $Mode) { $Mode } else { '' }
    $m = $m.Trim()
    if ($m -in @('WAM', 'WebLogin', 'Device')) { return $m } else { return 'WAM' }
}

function Update-ScriptPreference {
    <#
    .SYNOPSIS
    Persists updated preference values back into this script file.

    .DESCRIPTION
    Preference validation is intentionally able to repair stale defaults in
    memory without silently editing the source file. This helper performs the
    explicit write-back step only when the operator has already consented.

    .PARAMETER Changes
    Array of @{ Name = 'Pref_*'; NewValue = <object> } entries.

    .OUTPUTS
    [bool] True when the requested preference updates are written successfully.
    #>
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Low')]
    [OutputType([bool])]
    param([Parameter(Mandatory)][object[]]$Changes)

    if (-not $PSCommandPath) { return $false }
    try {
        $content = Get-Content -Path $PSCommandPath -Raw -ErrorAction Stop
    }
    catch {
        Write-Warning ("Unable to read script for persistence: {0}" -f $_.Exception.Message)
        return $false
    }

    foreach ($c in $Changes) {
        $name = [string]$c.Name
        $val = $c.NewValue
        $valText = '$null'
        if ($null -ne $val) {
            if ($val -is [bool]) { $valText = if ($val) { '$true' } else { '$false' } }
            elseif ($val -is [datetime]) { $valText = ("'{0}'" -f $val.ToString('yyyy-MM-dd')) }
            else {
                $s = [string]$val
                $s = $s -replace "'", "''"
                $valText = ("'{0}'" -f $s)
            }
        }
        $pattern = "(?m)^\s*\$${name}\s*=\s*.*$"
        $replacement = ("${0} = {1}" -f ("$" + $name), $valText)
        $new = [regex]::Replace($content, $pattern, $replacement)
        if ($new -ne $content) { $content = $new }
        else { Write-Verbose ("Preference line not found for {0}; skipping." -f $name) }
    }

    if (-not $PSCmdlet.ShouldProcess($PSCommandPath, 'Persist corrected preference values to the script file')) {
        return $false
    }

    try {
        Set-Content -Path $PSCommandPath -Value $content -Encoding UTF8 -ErrorAction Stop
        return $true
    }
    catch {
        Write-Warning ("Failed to write preferences to script: {0}" -f $_.Exception.Message)
        return $false
    }
}

function Initialize-PreferenceState {
    <#
    .SYNOPSIS
    Validates top-level preferences, applies safe in-memory corrections, and optionally persists them.

    .DESCRIPTION
    This helper is the guardrail between persisted defaults and runtime use. It
    repairs invalid values in memory, queues any optional write-back changes, and
    keeps every later prompt or default-mode branch operating against validated
    preference data.
    #>
    [CmdletBinding()]
    [OutputType([void])]
    param()

    $changes = @()

    # Helper to queue and set
    function Register-CorrectedPreference {
        param([string]$Name, [object]$Correct)
        Set-Variable -Name $Name -Scope Script -Value $Correct -Force
        $script:__queuedChanges += [pscustomobject]@{ Name = $Name; NewValue = $Correct }
    }

    $script:__queuedChanges = @()

    # Validate Y/N preferences
    foreach ($pair in @(
            @{ N = 'Pref_ReleaseToAllDefault'; V = $Pref_ReleaseToAllDefault },
            @{ N = 'Pref_ReportFalsePositiveDefault'; V = $Pref_ReportFalsePositiveDefault },
            @{ N = 'Pref_AllowSenderDefault'; V = $Pref_AllowSenderDefault },
            @{ N = 'Pref_CreateAllowDefault'; V = $Pref_CreateAllowDefault }
        )) {
        $fixed = Test-ValidYesNo $pair.V
        if ($fixed -ne $pair.V) { Register-CorrectedPreference -Name $pair.N -Correct $fixed }
    }

    # Allow scope
    $fixedScope = Test-ValidAllowScope $Pref_AllowScopeDefault
    if ($fixedScope -ne $Pref_AllowScopeDefault) { Register-CorrectedPreference -Name 'Pref_AllowScopeDefault' -Correct $fixedScope }

    # Allow expiry and date
    $fixedAllowChoice = Test-ValidExpiryChoice $Pref_AllowExpiryDefault
    if ($fixedAllowChoice -ne $Pref_AllowExpiryDefault) { Register-CorrectedPreference -Name 'Pref_AllowExpiryDefault' -Correct $fixedAllowChoice }
    if ($fixedAllowChoice -eq 'DATE') {
        $allowDt = ConvertTo-ExpiryDate $Pref_AllowExpiryDateDefault
        if ($null -eq $allowDt -and $null -ne $Pref_AllowExpiryDateDefault) {
            # Invalid date configured; clear it
            Register-CorrectedPreference -Name 'Pref_AllowExpiryDateDefault' -Correct $null
        }
    }

    # Delete-after-release
    $fixedDel = Test-ValidDeleteMode $Pref_DeleteAfterReleaseDefault
    if ($fixedDel -ne $Pref_DeleteAfterReleaseDefault) { Register-CorrectedPreference -Name 'Pref_DeleteAfterReleaseDefault' -Correct $fixedDel }

    # Block expiry choice/date
    $fixedBlock = Test-ValidBlockExpiryChoice $Pref_BlockExpiryDefault
    if ($fixedBlock -ne $Pref_BlockExpiryDefault) { Register-CorrectedPreference -Name 'Pref_BlockExpiryDefault' -Correct $fixedBlock }
    if ($fixedBlock -eq 'Date') {
        $blkDt = ConvertTo-ExpiryDate $Pref_BlockExpiryDateDefault
        if ($null -eq $blkDt -and $null -ne $Pref_BlockExpiryDateDefault) { Register-CorrectedPreference -Name 'Pref_BlockExpiryDateDefault' -Correct $null }
    }

    # DNSBL preferences
    $fixedDnsblY = Test-ValidYesNo $Pref_ReportToDnsblDefault
    if ($fixedDnsblY -ne $Pref_ReportToDnsblDefault) { Register-CorrectedPreference -Name 'Pref_ReportToDnsblDefault' -Correct $fixedDnsblY }
    $fixedDnsblMode = Test-ValidDnsblMode $Pref_DnsblModeDefault
    if ($fixedDnsblMode -ne $Pref_DnsblModeDefault) { Register-CorrectedPreference -Name 'Pref_DnsblModeDefault' -Correct $fixedDnsblMode }

    # Interaction mode
    $fixedIM = Test-ValidInteractionMode $Pref_InteractionMode
    if ($fixedIM -ne $Pref_InteractionMode) { Register-CorrectedPreference -Name 'Pref_InteractionMode' -Correct $fixedIM }

    # Auth login mode (WAM vs WebLogin)
    $fixedAuth = Test-ValidAuthLoginMode $Pref_AuthLoginMode
    if ($fixedAuth -ne $Pref_AuthLoginMode) { Register-CorrectedPreference -Name 'Pref_AuthLoginMode' -Correct $fixedAuth }

    $changes = $script:__queuedChanges
    if ($changes.Count -le 0) { return }

    # Optionally persist corrections (only when interaction mode resolves to Prompt)
    $effMode = Get-InteractionMode
    if (-not $Pref_PromptToPersistDefaults) { return }
    if ($effMode -ne 'Prompt') { return }

    Write-ConsoleMessage "Detected invalid preference values. Apply corrections permanently to this script?" -ForegroundColor Yellow
    foreach ($c in $changes) { Write-ConsoleMessage (" - {0} => {1}" -f $c.Name, $c.NewValue) -ForegroundColor Gray }
    $answer = Read-Host 'Persist corrected defaults? (Y/N, Default: N)'
    if ([string]::IsNullOrWhiteSpace($answer)) { $answer = 'N' } else { $answer = $answer.Trim().ToUpperInvariant() }
    if ($answer -eq 'Y') {
        if (Update-ScriptPreference -Changes $changes) { Write-ConsoleMessage 'Defaults persisted.' -ForegroundColor Green }
        else { Write-ConsoleMessage 'Failed to persist defaults.' -ForegroundColor Yellow }
    }
}

# ---------------------------
# Transcript
# ---------------------------
# Use a per-run unique transcript path to avoid file-in-use conflicts
$script:RunTranscriptPath = $TranscriptPath
if ([string]::IsNullOrWhiteSpace($script:RunTranscriptPath)) {
    $script:RunTranscriptPath = Join-Path $env:TEMP ("quarantine-to-block_{0}.transcript.log" -f (Get-Date -Format "yyyyMMdd_HHmmss"))
}
elseif ($script:RunTranscriptPath -like "*quarantine-to-block.transcript.log") {
    $script:RunTranscriptPath = Join-Path $env:TEMP ("quarantine-to-block_{0}.transcript.log" -f (Get-Date -Format "yyyyMMdd_HHmmss"))
}
try { Start-Transcript -Path $script:RunTranscriptPath -Force | Out-Null } catch { Write-Warning ("Start-Transcript failed: {0}" -f $_.Exception.Message) }

# ---------------------------
# Install EXO module if needed
# ---------------------------
Initialize-PreferenceState

function Install-ExchangeOnlineModule {
    <#
    .SYNOPSIS
    Ensures ExchangeOnlineManagement is available and imported.

    .DESCRIPTION
    The quarantine workflow depends on Exchange Online cmdlets being present
    before any discovery or remediation begins. This helper keeps module import
    and optional installation logic in one place so the main path can fail fast
    with clear guidance.

    .PARAMETER AutoInstall
    When specified, prompts and installs the module for CurrentUser if missing.

    .OUTPUTS
    None. Throws on failure when -AutoInstall is not used or installation/import fails.
    #>
    [CmdletBinding()]
    param([switch]$AutoInstall)

    try { Import-Module ExchangeOnlineManagement -ErrorAction Stop }
    catch {
        if ($AutoInstall) {
            $answer = Read-Host "ExchangeOnlineManagement not found. Install for CurrentUser now? (Y/N, Default: Y)"
            if ([string]::IsNullOrWhiteSpace($answer) -or $answer.Trim().ToUpper() -eq 'Y') {
                Install-Module ExchangeOnlineManagement -Scope CurrentUser -Force -ErrorAction Stop
                Import-Module ExchangeOnlineManagement -ErrorAction Stop
            }
            else { throw "ExchangeOnlineManagement is required. Aborting." }
        }
        else {
            throw "ExchangeOnlineManagement is required. Use -AutoInstall to enable prompted install."
        }
    }
}

# ---------------------------
# Detect existing EXO connection
# ---------------------------
function Test-ExchangeOnlineConnected {
    <#
    .SYNOPSIS
    Detects whether an Exchange Online session is currently connected.

    .DESCRIPTION
    Reusing an existing Exchange Online session avoids unnecessary sign-in
    prompts and prevents the script from disconnecting a session that it did not
    create. This helper abstracts the module-version differences in session
    detection behind one boolean check.

    .OUTPUTS
    [bool] True if a session named like ExchangeOnline* is connected; otherwise False.
    #>
    [CmdletBinding()]
    [OutputType([bool])]
    param()
    $connected = $false
    try {
        if (Get-Command Get-ConnectionInformation -ErrorAction SilentlyContinue) {
            $ci = Get-ConnectionInformation
            if ($ci -and ($ci | Where-Object { $_.State -eq 'Connected' -and $_.Name -like 'ExchangeOnline*' })) {
                $connected = $true
            }
        }
        else {
            $pss = Get-PSSession -ErrorAction SilentlyContinue
            if ($pss -and ($pss | Where-Object { $_.State -eq 'Opened' -and $_.Name -like 'ExchangeOnline*' })) {
                $connected = $true
            }
        }
    }
    catch { $connected = $false }
    return $connected
}

# ---------------------------
# Connect if not already connected; track ownership for disconnect
# ---------------------------
$script:DidConnect = $false
function Connect-ExchangeOnlineWithRetry {
    <#
    .SYNOPSIS
    Connects to Exchange Online if not already connected, with retry and backoff.

    .DESCRIPTION
    Authentication behaviour varies across Exchange Online module versions and
    supported parameters. This helper centralises connection reuse, runtime
    parameter detection, login-mode preference handling, and retry behaviour so
    the rest of the script can assume a ready session.

    .PARAMETER UserPrincipalName
    Optional UPN to direct WAM/MSAL account selection.

    .PARAMETER MaxRetries
    Maximum connection attempts.

    .PARAMETER BackoffSecondsBase
    Base seconds for linear backoff between attempts.

    .OUTPUTS
    [bool] True on connected/ready; False on persistent failure.
    #>
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        [string]$UserPrincipalName,
        [int]$MaxRetries = 3,
        [int]$BackoffSecondsBase = 3,
        [string]$AppId,
        [string]$Organization,
        [string]$CertificateThumbprint,
        [switch]$PreferAppOnly
    )

    if (Test-ExchangeOnlineConnected) {
        Write-Verbose "Exchange Online already connected; skipping reconnection."
        $script:DidConnect = $false
        return $true
    }

    $tries = 0
    do {
        try {
            $swConn = [System.Diagnostics.Stopwatch]::StartNew()
            $usedAppOnly = $false
            if ( ($PreferAppOnly -or (-not [string]::IsNullOrWhiteSpace($AppId))) -and (-not [string]::IsNullOrWhiteSpace($Organization)) -and (-not [string]::IsNullOrWhiteSpace($CertificateThumbprint)) ) {
                Connect-ExchangeOnline -AppId $AppId -Organization $Organization -CertificateThumbprint $CertificateThumbprint -ShowBanner:$false -SkipLoadingCmdletHelp:$true -ErrorAction Stop
                $usedAppOnly = $true
            }
            else {
                # Decide auth login mode and detect supported parameters on this module version
                $authMode = Test-ValidAuthLoginMode $Pref_AuthLoginMode
                $paramKeys = @()
                try { $cmd = Get-Command -Name Connect-ExchangeOnline -ErrorAction Stop; $paramKeys = $cmd.Parameters.Keys } catch { $paramKeys = @() }
                $supportsWebLogin = $paramKeys -contains 'UseWebLogin'
                $supportsDevice = $paramKeys -contains 'Device'
                $supportsUseWAM = $paramKeys -contains 'UseWAM'

                switch ($authMode) {
                    'WebLogin' {
                        if ($supportsWebLogin) {
                            Connect-ExchangeOnline -UseWebLogin -ShowBanner:$false -SkipLoadingCmdletHelp:$true -ErrorAction Stop
                        }
                        elseif ($supportsDevice) {
                            Connect-ExchangeOnline -Device -ShowBanner:$false -SkipLoadingCmdletHelp:$true -ErrorAction Stop
                        }
                        else {
                            # Fallback to WAM/default
                            if ($supportsUseWAM) {
                                if ($Pref_AuthUseUPNWithWAM -and -not [string]::IsNullOrWhiteSpace($UserPrincipalName)) {
                                    Connect-ExchangeOnline -UseWAM -UserPrincipalName $UserPrincipalName -ShowBanner:$false -SkipLoadingCmdletHelp:$true -ErrorAction Stop
                                }
                                else {
                                    Connect-ExchangeOnline -UseWAM -ShowBanner:$false -SkipLoadingCmdletHelp:$true -ErrorAction Stop
                                }
                            }
                            else {
                                if ($Pref_AuthUseUPNWithWAM -and -not [string]::IsNullOrWhiteSpace($UserPrincipalName)) {
                                    Connect-ExchangeOnline -UserPrincipalName $UserPrincipalName -ShowBanner:$false -SkipLoadingCmdletHelp:$true -ErrorAction Stop
                                }
                                else {
                                    Connect-ExchangeOnline -ShowBanner:$false -SkipLoadingCmdletHelp:$true -ErrorAction Stop
                                }
                            }
                        }
                    }
                    'Device' {
                        if ($supportsDevice) {
                            Connect-ExchangeOnline -Device -ShowBanner:$false -SkipLoadingCmdletHelp:$true -ErrorAction Stop
                        }
                        elseif ($supportsWebLogin) {
                            Connect-ExchangeOnline -UseWebLogin -ShowBanner:$false -SkipLoadingCmdletHelp:$true -ErrorAction Stop
                        }
                        else {
                            # Fallback to default/WAM
                            if ($supportsUseWAM) {
                                if ($Pref_AuthUseUPNWithWAM -and -not [string]::IsNullOrWhiteSpace($UserPrincipalName)) {
                                    Connect-ExchangeOnline -UseWAM -UserPrincipalName $UserPrincipalName -ShowBanner:$false -SkipLoadingCmdletHelp:$true -ErrorAction Stop
                                }
                                else {
                                    Connect-ExchangeOnline -UseWAM -ShowBanner:$false -SkipLoadingCmdletHelp:$true -ErrorAction Stop
                                }
                            }
                            else {
                                if ($Pref_AuthUseUPNWithWAM -and -not [string]::IsNullOrWhiteSpace($UserPrincipalName)) {
                                    Connect-ExchangeOnline -UserPrincipalName $UserPrincipalName -ShowBanner:$false -SkipLoadingCmdletHelp:$true -ErrorAction Stop
                                }
                                else {
                                    Connect-ExchangeOnline -ShowBanner:$false -SkipLoadingCmdletHelp:$true -ErrorAction Stop
                                }
                            }
                        }
                    }
                    Default {
                        # WAM
                        if ($supportsUseWAM) {
                            if ($Pref_AuthUseUPNWithWAM -and -not [string]::IsNullOrWhiteSpace($UserPrincipalName)) {
                                Connect-ExchangeOnline -UseWAM -UserPrincipalName $UserPrincipalName -ShowBanner:$false -SkipLoadingCmdletHelp:$true -ErrorAction Stop
                            }
                            else {
                                Connect-ExchangeOnline -UseWAM -ShowBanner:$false -SkipLoadingCmdletHelp:$true -ErrorAction Stop
                            }
                        }
                        else {
                            if ($Pref_AuthUseUPNWithWAM -and -not [string]::IsNullOrWhiteSpace($UserPrincipalName)) {
                                Connect-ExchangeOnline -UserPrincipalName $UserPrincipalName -ShowBanner:$false -SkipLoadingCmdletHelp:$true -ErrorAction Stop
                            }
                            else {
                                Connect-ExchangeOnline -ShowBanner:$false -SkipLoadingCmdletHelp:$true -ErrorAction Stop
                            }
                        }
                    }
                }
            }
            $swConn.Stop()
            $script:ConnectExchangeMs = $swConn.ElapsedMilliseconds
            if ($usedAppOnly) { Write-Verbose ("Connect-ExchangeOnline (app-only) took {0} ms" -f $script:ConnectExchangeMs) }
            else { Write-Verbose ("Connect-ExchangeOnline (user) took {0} ms" -f $script:ConnectExchangeMs) }
            $script:DidConnect = $true
            return $true
        }
        catch {
            $tries++
            Write-Warning ("Connect attempt {0} failed: {1}" -f $tries, $_.Exception.Message)
            Start-Sleep -Seconds ($BackoffSecondsBase * $tries)
        }
    } while ($tries -lt $MaxRetries)
    return $false
}

# ---------------------------
# PSL (Exact eTLD+1)
# ---------------------------
$script:PSLRules = $null
$script:PSLExact = $null
$script:PSLWildcard = $null
$script:PSLExceptions = $null
${script:ETLDCache} = New-Object 'System.Collections.Generic.Dictionary[string,string]'

function Get-PslWorkingFolder {
    <#
    .SYNOPSIS
    Resolves the working folder for PSL cache/files.

    .DESCRIPTION
    PSL cache files should follow the script when it is run from its repository
    location, but library-mode tests and other entry points may not expose a
    script path. This helper provides a single working-folder resolution rule for
    all PSL file operations.

    .OUTPUTS
    [string] Absolute folder path (script directory when available; otherwise current directory).
    #>
    [CmdletBinding()]
    param()
    if ($PSCommandPath) { return (Split-Path -Parent $PSCommandPath) }
    return (Get-Location).Path
}

function ConvertFrom-PslDat {
    <#
    .SYNOPSIS
    Parses Mozilla public_suffix_list.dat into exact, wildcard, and exception collections.

    .DESCRIPTION
    public_suffix_list.dat is the authoritative fallback source when JSON rule
    data is unavailable. This helper converts the raw PSL file into the in-memory
    structures used by Get-ETLDPlusOne.

    .PARAMETER DatPath
    Path to a local .dat file.

    .OUTPUTS
    None. Populates $script:PSLExact, $script:PSLWildcard, $script:PSLExceptions.
    #>
    [CmdletBinding()]
    param([Parameter(Mandatory)][string]$DatPath)

    $exact = New-Object System.Collections.Generic.List[string]
    $wild = New-Object System.Collections.Generic.List[string]
    $exc = New-Object System.Collections.Generic.List[string]

    foreach ($line in Get-Content -Path $DatPath -Encoding UTF8) {
        $l = $line.Trim()
        if ([string]::IsNullOrWhiteSpace($l)) { continue }
        if ($l.StartsWith('//')) { continue }
        if ($l.StartsWith('!')) { $exc.Add($l.Substring(1)); continue }
        if ($l.StartsWith('*.')) { $wild.Add($l.Substring(2)); continue }
        $exact.Add($l)
    }

    Set-PublicSuffixRuleSet -Exact $exact -Wildcard $wild -Exceptions $exc
}

function Set-PublicSuffixRuleSet {
    <#
    .SYNOPSIS
    Normalises and stores loaded PSL rule collections.

    .DESCRIPTION
    PSL data can come from JSON, cached dat content, or the built-in fallback.
    This helper ensures every source is normalised consistently before the rule
    collections are stored for domain-root calculations.

    .PARAMETER Exact
    Exact suffix matches.

    .PARAMETER Wildcard
    Wildcard suffix matches without the '*.' prefix.

    .PARAMETER Exceptions
    Exception rules without the '!' prefix.
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter()][AllowEmptyCollection()][string[]]$Exact = @(),
        [Parameter()][AllowEmptyCollection()][string[]]$Wildcard = @(),
        [Parameter()][AllowEmptyCollection()][string[]]$Exceptions = @()
    )

    $exactList = New-Object System.Collections.Generic.List[string]
    $wildList = New-Object System.Collections.Generic.List[string]
    $exceptionList = New-Object System.Collections.Generic.List[string]

    foreach ($rule in @($Exact)) {
        $normalisedRule = ConvertTo-NormalizedDomain $rule
        if ($normalisedRule -and -not $exactList.Contains($normalisedRule)) { $exactList.Add($normalisedRule) }
    }
    foreach ($rule in @($Wildcard)) {
        $normalisedRule = ConvertTo-NormalizedDomain $rule
        if ($normalisedRule -and -not $wildList.Contains($normalisedRule)) { $wildList.Add($normalisedRule) }
    }
    foreach ($rule in @($Exceptions)) {
        $normalisedRule = ConvertTo-NormalizedDomain $rule
        if ($normalisedRule -and -not $exceptionList.Contains($normalisedRule)) { $exceptionList.Add($normalisedRule) }
    }

    if (-not ($exactList -contains 'onmicrosoft.com')) { $exactList.Add('onmicrosoft.com') }

    if ($PSCmdlet.ShouldProcess('Script PSL cache', 'Store loaded public suffix rules')) {
        $script:PSLExact = $exactList
        $script:PSLWildcard = $wildList
        $script:PSLExceptions = $exceptionList
    }
}

function Import-PublicSuffixList {
    <#
    .SYNOPSIS
    Loads PSL rules from JSON (preferred) or cached .dat, with non-blocking network refresh.

    .DESCRIPTION
    Domain-root accuracy is central to exclusions, allow/block checks, and
    origin analysis. This helper loads PSL data from the preferred JSON format
    when available, falls back to the cached dat file, and only then uses the
    minimal built-in rule set with an asynchronous refresh.

    .PARAMETER PslJsonPath
    Optional JSON file path. When omitted, tries psl.json beside the script, else uses .dat cache.

    .OUTPUTS
    None. Populates $script:PSLExact, $script:PSLWildcard, $script:PSLExceptions; warns on fallback.
    #>
    [CmdletBinding()]
    param([string]$PslJsonPath)

    $candidate = $PslJsonPath
    if ([string]::IsNullOrWhiteSpace($candidate)) { $candidate = Join-Path (Get-PslWorkingFolder) 'psl.json' }

    if (Test-Path $candidate) {
        try {
            $json = Get-Content -Path $candidate -Raw | ConvertFrom-Json -ErrorAction Stop
            if ($json) {
                $exact = New-Object System.Collections.Generic.List[string]
                $wild = New-Object System.Collections.Generic.List[string]
                $exc = New-Object System.Collections.Generic.List[string]

                if ($json.PSObject.Properties['exact'] -and $json.exact) { $json.exact | ForEach-Object { $exact.Add($_.ToLower().Trim()) } }
                if ($json.PSObject.Properties['wildcard'] -and $json.wildcard) { $json.wildcard | ForEach-Object { $wild.Add($_.ToLower().Trim()) } }
                if ($json.PSObject.Properties['exceptions'] -and $json.exceptions) { $json.exceptions | ForEach-Object { $exc.Add($_.ToLower().Trim()) } }

                if (($exact.Count -eq 0) -and ($json.PSObject.Properties['rules'] -and $json.rules)) {
                    foreach ($r in $json.rules) {
                        $rule = $r.ToLower().Trim()
                        if ([string]::IsNullOrWhiteSpace($rule)) { continue }
                        if ($rule.StartsWith('!')) { $exc.Add($rule.Substring(1)); continue }
                        if ($rule.StartsWith('*.')) { $wild.Add($rule.Substring(2)); continue }
                        $exact.Add($rule)
                    }
                }

                Set-PublicSuffixRuleSet -Exact $exact -Wildcard $wild -Exceptions $exc
                return
            }
        }
        catch {
            Write-Verbose ("Failed to parse PSL JSON: {0}" -f $_.Exception.Message)
        }
    }

    # Fallback to cached .dat file or quick network fetch
    $datPath = Join-Path (Get-PslWorkingFolder) 'public_suffix_list.dat'
    $url = 'https://publicsuffix.org/list/public_suffix_list.dat'
    $usedCache = $false

    if (Test-Path $datPath) {
        try {
            ConvertFrom-PslDat -DatPath $datPath
            $usedCache = $true
            Write-Verbose ("Loaded cached PSL .dat from {0}" -f $datPath)
        }
        catch {
            Write-Verbose ("Failed to parse cached PSL .dat: {0}" -f $_.Exception.Message)
        }
    }

    if (-not $usedCache) {
        try {
            $resp = Invoke-WebRequest -Uri $url -UseBasicParsing -TimeoutSec 5 -ErrorAction Stop
            if ($resp -and $resp.Content) {
                Set-Content -Path $datPath -Value $resp.Content -Encoding UTF8
                ConvertFrom-PslDat -DatPath $datPath
                $usedCache = $true
                Write-Verbose ("Loaded PSL .dat from network into {0}" -f $datPath)
            }
        }
        catch {
            Write-Verbose ("PSL quick fetch failed: {0}" -f $_.Exception.Message)
        }
    }

    if (-not $usedCache) {
        # Minimal built-in list to keep script fast and resilient (include common IN/UK/AU/NZ/ID)
        Set-PublicSuffixRuleSet -Exact @('onmicrosoft.com',
            'ac.in', 'co.in', 'in',
            'co.uk',
            'com.au', 'net.au', 'org.au', 'edu.au', 'gov.au',
            'co.nz', 'nz',
            'co.id', 'or.id', 'ac.id', 'net.id', 'id',
            'com', 'net', 'org', 'edu', 'gov')
        Write-Warning "PSL cache not found and quick fetch failed. Using minimal built-in list and refreshing cache in background."

        # Refresh cache asynchronously without delaying script
        try {
            Start-Job -Name 'Refresh-PSL-Dat' -ScriptBlock {
                try {
                    $resp = Invoke-WebRequest -Uri $using:url -UseBasicParsing -TimeoutSec 20 -ErrorAction Stop
                    Set-Content -Path $using:datPath -Value $resp.Content -Encoding UTF8
                }
                catch { Write-Verbose ("Background PSL refresh failed: {0}" -f $_.Exception.Message) }
            } | Out-Null
        }
        catch { Write-Verbose ("Failed to start background PSL refresh job: {0}" -f $_.Exception.Message) }
    }
}

function Get-ETLDPlusOne {
    <#
    .SYNOPSIS
    Computes registrable domain (eTLD+1) from a domain or email using loaded PSL rules.

    .DESCRIPTION
    The script compares roots rather than raw domains for exclusions, provider
    suppression, allow/block conflicts, and header analysis. This helper is the
    single source of truth for that eTLD+1 resolution and uses a script-scoped
    cache to avoid repeated PSL lookups.

    .PARAMETER DomainOrEmail
    Domain or email address; quotes and brackets are stripped.

    .OUTPUTS
    [string] eTLD+1. Falls back to last two labels when no rule matches.
    #>
    [CmdletBinding()]
    param([Parameter(Mandatory)][string]$DomainOrEmail)

    $dom = $DomainOrEmail.Trim().ToLower()
    # Strip common prefixes and wrappers early
    $dom = $dom.Trim('<', '>', '"', "'", ' ')
    if ($dom.StartsWith('smtp:')) { $dom = $dom.Substring(5) }
    # If it starts with *@ or @ (TABL domain entries sometimes look like '@example.com')
    if ($dom.StartsWith('*@')) { $dom = $dom.Substring(2) }
    elseif ($dom.StartsWith('@')) { $dom = $dom.Substring(1) }
    # If it's a full address user@domain extract the domain
    if ($dom -match ".+@(.+)$") { $dom = $Matches[1] }

    # Memo cache lookup
    if ($script:ETLDCache -and $script:ETLDCache.ContainsKey($dom)) { return $script:ETLDCache[$dom] }
    $labels = $dom.Split('.') | Where-Object { $_ -ne "" }
    if ($labels.Count -le 2) { return $dom }

    $candidates = @()
    for ($i = 0; $i -lt $labels.Count; $i++) { $candidates += ($labels[$i..($labels.Count - 1)] -join '.') }

    # Exceptions first
    foreach ($cand in $candidates) {
        if ($script:PSLExceptions -and ($script:PSLExceptions -contains $cand)) {
            $ruleLen = ($cand -split '\.').Count - 1
            $lower = ($labels.Count - ($ruleLen + 1))
            $upper = ($labels.Count - 1)
            return (($labels[$lower..$upper]) -join '.')
        }
    }

    # Exact matches
    foreach ($cand in $candidates) {
        if ($script:PSLExact -and ($script:PSLExact -contains $cand)) {
            $ruleLen = ($cand -split '\.').Count
            $lower = ($labels.Count - ($ruleLen + 1))
            $upper = ($labels.Count - 1)
            return (($labels[$lower..$upper]) -join '.')
        }
    }

    # Wildcards (suffix match)
    $__wild = $script:PSLWildcard
    if (-not $__wild) { $__wild = @() }
    foreach ($w in $__wild) {
        $suffixLen = ($w -split '\.').Count
        $suffix = ($labels[($labels.Count - $suffixLen)..($labels.Count - 1)] -join '.')
        if ($suffix -eq $w) {
            $lower = ($labels.Count - ($suffixLen + 1))
            $upper = ($labels.Count - 1)
            return (($labels[$lower..$upper]) -join '.')
        }
    }

    $result = ($labels[$labels.Count - 2] + '.' + $labels[$labels.Count - 1])
    try { if ($script:ETLDCache -and -not $script:ETLDCache.ContainsKey($dom)) { $script:ETLDCache.Add($dom, $result) } }
    catch { Write-Verbose ("ETLD cache add failed for {0}: {1}" -f $dom, $_.Exception.Message) }
    return $result
}

# ---------------------------
# Normalization & Retry
# ---------------------------
function ConvertTo-NormalizedAddress {
    <#
    .SYNOPSIS
    Normalises an address-like value by trimming wrappers and separators.

    .DESCRIPTION
    Exchange headers and TABL values often include wrappers, quoting, or folded
    punctuation. This helper strips those transport artefacts so later parsing and
    comparison logic works with a predictable address value.

    .PARAMETER Value
    String possibly containing <address>, quotes, or trailing commas/semicolons.

    .OUTPUTS
    [string] Address without wrappers; or $null when input is empty.
    #>
    [CmdletBinding()]
    param([string]$Value)
    if (-not $Value) { return $null }
    $v = $Value.Trim().Trim('<', '>', '"', "'", ' ')
    if ($v -match "<(.+@.+)>") { $v = $Matches[1] }
    # Remove trailing separators inside header tokens
    $v = $v.Trim(',', ';')
    return $v
}

function ConvertTo-NormalizedDomain {
    <#
    .SYNOPSIS
    Normalises a domain or email to a bare lower-case domain.

    .DESCRIPTION
    Several workflows need to compare domains from sender addresses, TABL
    entries, headers, and transport values. This helper collapses those variants
    to a single lower-case bare-domain representation.

    .PARAMETER Domain
    Domain or email; removes quotes/brackets and trailing separators.

    .OUTPUTS
    [string] Domain; or $null when input is empty.
    #>
    [CmdletBinding()]
    param([string]$Domain)
    if (-not $Domain) { return $null }
    $d = $Domain.Trim().ToLower().Trim('<', '>', '"', "'", ' ')
    # Strip common prefixes found in EXO values
    if ($d.StartsWith('smtp:')) { $d = $d.Substring(5) }
    # If value is '@domain.com' or '*@domain.com', trim to bare domain
    if ($d.StartsWith('*@')) { $d = $d.Substring(2) }
    elseif ($d.StartsWith('@')) { $d = $d.Substring(1) }
    # If it's a full address, extract the domain
    if ($d -match ".+@(.+)$") { $d = $Matches[1] }
    # Remove trailing separators, common in folded headers
    $d = $d.Trim(',', ';')
    return $d
}

function Invoke-OperationWithRetry {
    <#
    .SYNOPSIS
    Runs an operation with retries and linear backoff.

    .DESCRIPTION
    Exchange Online and Microsoft Graph operations can fail transiently. This
    helper standardises retry handling so mutating and discovery operations use a
    shared backoff model and consistent warning output.

    .PARAMETER Operation
    ScriptBlock to invoke.

    .PARAMETER Label
    Friendly label for logging.

    .PARAMETER MaxRetries
    Maximum attempts before throwing.

    .PARAMETER BackoffSecondsBase
    Base seconds used to compute delay between attempts.

    .OUTPUTS
    Any. Returns the operation's output on success; throws on failure.
    #>
    [CmdletBinding()]
    param([scriptblock]$Operation, [string]$Label = "Operation", [int]$MaxRetries = 3, [int]$BackoffSecondsBase = 3)
    $tries = 0
    do {
        try { return & $Operation }
        catch {
            $tries++; Write-Warning ("{0} attempt {1} failed: {2}" -f $Label, $tries, $_.Exception.Message)
            Start-Sleep -Seconds ($BackoffSecondsBase * $tries)
        }
    } while ($tries -lt $MaxRetries)
    throw ("{0} failed after {1} attempts." -f $Label, $MaxRetries)
}

# ---------------------------
# Header parsing
# ---------------------------
function Get-AuthenticationResultsLine {
    <#
    .SYNOPSIS
    Extracts Authentication-Results and ARC-Authentication-Results header lines.

    .DESCRIPTION
    Origin analysis depends on the trust chain captured in Authentication-Results
    and ARC-Authentication-Results. This helper isolates those lines so later
    parsing functions can work against a focused subset of the headers.

    .PARAMETER HeaderText
    Full raw headers as a single string.

    .OUTPUTS
    [pscustomobject] @{ Auth = string[]; ARC = string[] }
    #>
    [CmdletBinding()]
    param([string]$HeaderText)
    $lines = ($HeaderText -split "`r?`n")
    $authLines = $lines | Where-Object { $_ -match "^\s*Authentication-Results\s*:" }
    $arcLines = $lines | Where-Object { $_ -match "^\s*ARC-Authentication-Results\s*:" }
    return [pscustomobject]@{ Auth = $authLines; ARC = $arcLines }
}

function Get-ExchangeAuthResultsLine {
    <#
    .SYNOPSIS
    Extracts X-MS-Exchange-Authentication-Results header lines.

    .DESCRIPTION
    Exchange sometimes records useful sender hints in its proprietary
    authentication-results header even when standard headers are incomplete. This
    helper exposes those lines for fallback origin analysis.

    .PARAMETER HeaderText
    Full raw headers as a single string.

    .OUTPUTS
    [string[]] Array of matching header lines.
    #>
    [CmdletBinding()]
    param([string]$HeaderText)
    $lines = ($HeaderText -split "`r?`n")
    $exch = $lines | Where-Object { $_ -match "^\s*X-MS-Exchange-Authentication-Results\s*:" }
    return $exch
}

function ConvertFrom-ForefrontAsfHeader {
    <#
    .SYNOPSIS
    Parses X-Forefront-Antispam-Report-Untrusted for useful origin hints.

    .DESCRIPTION
    Forefront antispam headers can contain HELO and PTR hints that help map a
    quarantined message back to its effective sender root. This helper extracts
    those hints without forcing the calling logic to parse the raw header text.

    .PARAMETER HeaderText
    Full raw headers as a single string.

    .OUTPUTS
    [pscustomobject] @{ HELO = string; PTR = string }
    #>
    [CmdletBinding()]
    param([string]$HeaderText)
    $lines = ($HeaderText -split "`r?`n")
    $ff = $lines | Where-Object { $_ -match "^\s*X-Forefront-Antispam-Report-Untrusted\s*:" }
    if (-not $ff -or $ff.Count -eq 0) { return [pscustomobject]@{ HELO = $null; PTR = $null } }
    $joined = ($ff -join ' ')
    $helo = $null; $ptr = $null
    try {
        $mH = [regex]::Match($joined, '\bH:([^;\s]+)', 'IgnoreCase')
        if ($mH.Success) { $helo = $mH.Groups[1].Value }
    }
    catch { Write-Verbose ("Failed to parse Forefront HELO hint: {0}" -f $_.Exception.Message) }
    try {
        $mP = [regex]::Match($joined, '\bPTR:([^;\s]+)', 'IgnoreCase')
        if ($mP.Success) { $ptr = $mP.Groups[1].Value }
    }
    catch { Write-Verbose ("Failed to parse Forefront PTR hint: {0}" -f $_.Exception.Message) }
    return [pscustomobject]@{ HELO = $helo; PTR = $ptr }
}

function Get-MailFromDomainExact {
    <#
    .SYNOPSIS
    Finds the most recent smtp.mailfrom domain from Authentication-Results lines.

    .DESCRIPTION
    The script prefers an exact smtp.mailfrom value over broader root guesses
    wherever possible. This helper scans the relevant header lines from newest to
    oldest to capture the most recent authoritative mail-from domain.

    .PARAMETER Lines
    Header lines to scan (latest evaluated first).

    .OUTPUTS
    [string] Exact domain; or $null when no match.
    #>
    [CmdletBinding()]
    param([string[]]$Lines)
    for ($i = $Lines.Count - 1; $i -ge 0; $i--) {
        $line = $Lines[$i]
        $m = [regex]::Match($line, "smtp\.mailfrom\s*=\s*[""<]?([^""'>;\s]+)["">]?", 'IgnoreCase')
        if ($m.Success) {
            $val = $m.Groups[1].Value.Trim().Trim(',', ';')
            return (ConvertTo-NormalizedDomain $val)
        }
    }
    return $null
}

function Get-MailFromCandidate {
    <#
    .SYNOPSIS
    Builds candidate domains from smtp.mailfrom, Return-Path, and Received-SPF.

    .DESCRIPTION
    Not every message exposes the same sender hints. This helper assembles a
    de-duplicated fallback list from the common header sources so origin analysis
    can continue even when one field is absent.

    .PARAMETER HeaderText
    Full headers text to search.

    .OUTPUTS
    [string[]] Unique, normalised domains.
    #>
    [CmdletBinding()]
    param([string]$HeaderText)

    $flat = ($HeaderText -replace "`r?`n", " ")
    $cands = New-Object System.Collections.Generic.List[string]

    foreach ($m in [regex]::Matches($flat, "smtp\.mailfrom\s*=\s*[""<]?([^""'>;\s]+)["">]?", 'IgnoreCase')) {
        $cands.Add( (ConvertTo-NormalizedDomain $m.Groups[1].Value.Trim().Trim(',', ';')) )
    }

    $rp = [regex]::Match($flat, "Return-Path\s*:\s*<?([^>\s]+)>?", 'IgnoreCase')
    if ($rp.Success) { $cands.Add( (ConvertTo-NormalizedDomain $rp.Groups[1].Value) ) }

    $spf = [regex]::Match($flat, "Received-SPF\s*:\s*.*?domain\s+of\s+([^\s]+)", 'IgnoreCase')
    if ($spf.Success) { $cands.Add( (ConvertTo-NormalizedDomain $spf.Groups[1].Value) ) }

    return ($cands | Where-Object { $_ } | Select-Object -Unique)
}

function Get-MessageOriginAnalysis {
    <#
    .SYNOPSIS
    Parses a quarantined message and its headers into reusable origin hints.

    .DESCRIPTION
    Header review is one of the core reasons this script exists. This helper
    consolidates sender, return-path, smtp.mailfrom, header.from, HELO, and PTR
    evidence into one reusable object so later workflows can reason about origin
    consistently.

    .PARAMETER Message
    Quarantined message object.

    .PARAMETER HeaderText
    Full header text for the message.

    .OUTPUTS
    [pscustomobject] with sender, return-path, smtp.mailfrom, and HELO/PTR roots.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][object]$Message,
        [Parameter(Mandatory)][string]$HeaderText
    )

    $senderEmail = $null
    if ($Message.PSObject.Properties['SenderAddress'] -and $Message.SenderAddress) {
        $senderEmail = ConvertTo-NormalizedAddress $Message.SenderAddress
    }

    $senderDomain = $null
    if ($senderEmail) { $senderDomain = ConvertTo-NormalizedDomain $senderEmail }
    $senderRoot = $null
    if ($senderDomain) { $senderRoot = Get-ETLDPlusOne $senderDomain }

    $lines = Get-AuthenticationResultsLine $HeaderText
    $exchLines = Get-ExchangeAuthResultsLine $HeaderText
    $ffHints = ConvertFrom-ForefrontAsfHeader $HeaderText

    $mailFromExact = $null
    if ($lines.Auth.Count -gt 0) { $mailFromExact = Get-MailFromDomainExact -Lines $lines.Auth }
    if (-not $mailFromExact -and $lines.ARC.Count -gt 0) { $mailFromExact = Get-MailFromDomainExact -Lines $lines.ARC }
    if (-not $mailFromExact -and $exchLines -and $exchLines.Count -gt 0) { $mailFromExact = Get-MailFromDomainExact -Lines $exchLines }

    $mailFromCandidates = Get-MailFromCandidate -HeaderText $HeaderText
    if (-not $mailFromExact -and $mailFromCandidates.Count -gt 0) { $mailFromExact = $mailFromCandidates[-1] }

    $returnPathExact = $null
    try {
        $rpMatch = [regex]::Match($HeaderText, '(?im)^\s*Return-Path\s*:\s*<?([^>\s]+)>?')
        if ($rpMatch.Success) { $returnPathExact = ConvertTo-NormalizedDomain $rpMatch.Groups[1].Value }
    }
    catch {
        Write-Verbose ("Return-Path parsing failed for {0}: {1}" -f $Message.Identity, $_.Exception.Message)
    }

    $mailFromRoot = $null
    if ($mailFromExact) { $mailFromRoot = Get-ETLDPlusOne $mailFromExact }

    $returnPathRoot = $null
    if ($returnPathExact) { $returnPathRoot = Get-ETLDPlusOne $returnPathExact }

    $allAuthText = ($lines.Auth + $lines.ARC + $exchLines) -join ' '
    $headerFromRoot = $null
    $headerFromMatch = [regex]::Match($allAuthText, 'header\.from\s*=\s*([^;,\s]+)', 'IgnoreCase')
    if ($headerFromMatch.Success) { $headerFromRoot = Get-ETLDPlusOne $headerFromMatch.Groups[1].Value }
    if (-not $senderRoot -and $headerFromRoot) { $senderRoot = $headerFromRoot }

    $heloDomain = $null
    if ($ffHints -and $ffHints.HELO) { $heloDomain = ConvertTo-NormalizedDomain $ffHints.HELO }
    $heloRoot = $null
    if ($heloDomain) { $heloRoot = Get-ETLDPlusOne $heloDomain }

    $ptrDomain = $null
    if ($ffHints -and $ffHints.PTR) { $ptrDomain = ConvertTo-NormalizedDomain $ffHints.PTR }
    $ptrRoot = $null
    if ($ptrDomain) { $ptrRoot = Get-ETLDPlusOne $ptrDomain }

    $candidates = New-Object System.Collections.Generic.List[string]
    $addCandidate = {
        param([string]$Value)
        if ([string]::IsNullOrWhiteSpace($Value)) { return }
        $normalisedValue = ConvertTo-NormalizedDomain $Value
        if ($normalisedValue -and -not $candidates.Contains($normalisedValue)) { $candidates.Add($normalisedValue) }
    }

    & $addCandidate $returnPathExact
    if ($returnPathRoot -and (-not $returnPathExact -or (Get-ETLDPlusOne $returnPathExact) -ne $returnPathRoot)) { & $addCandidate $returnPathRoot }
    $mailFromExactRoot = $null
    if ($mailFromExact) { $mailFromExactRoot = Get-ETLDPlusOne $mailFromExact }
    if ($mailFromExact -and ($returnPathRoot -ne $mailFromExactRoot)) { & $addCandidate $mailFromExact }
    if ($mailFromRoot -and ($mailFromRoot -ne $returnPathRoot) -and (-not $mailFromExact -or $mailFromExactRoot -ne $mailFromRoot)) { & $addCandidate $mailFromRoot }
    if ($senderRoot -and ($senderRoot -ne $mailFromRoot) -and ($senderRoot -ne $returnPathRoot)) { & $addCandidate $senderRoot }
    & $addCandidate $heloDomain
    & $addCandidate $ptrDomain

    return [pscustomobject]@{
        SenderEmail          = $senderEmail
        SenderDomain         = $senderDomain
        SenderRoot           = $senderRoot
        MailFromExact        = $mailFromExact
        MailFromRoot         = $mailFromRoot
        ReturnPathExact      = $returnPathExact
        ReturnPathRoot       = $returnPathRoot
        HeaderFromRoot       = $headerFromRoot
        HeloDomain           = $heloDomain
        HeloRoot             = $heloRoot
        PtrDomain            = $ptrDomain
        PtrRoot              = $ptrRoot
        CandidatesToConsider = @($candidates)
        PreferredRoots       = @($returnPathRoot, $mailFromRoot, $senderRoot, $heloRoot, $ptrRoot)
    }
}

function Select-QuarantineMessage {
    <#
    .SYNOPSIS
    Applies client-side quarantine filters consistently across workflow stages.

    .DESCRIPTION
    Exchange cmdlet filtering is not uniform across module versions and server
    behaviour. This helper keeps reason, policy, and type filtering consistent by
    applying the same client-side logic before release handling and after refresh.

    .PARAMETER Messages
    Messages to filter.

    .PARAMETER QuarantineReasonFilter
    Client-side quarantine reason filter values.

    .PARAMETER PolicyTypeFilter
    Client-side policy type filter values.

    .PARAMETER QuarantineTypesFilter
    Client-side quarantine type filter values.

    .OUTPUTS
    [object[]] Messages that remain in scope after client-side filtering.
    #>
    [CmdletBinding()]
    [OutputType([object[]])]
    param(
        [Parameter()][AllowEmptyCollection()][object[]]$Messages,
        [string[]]$QuarantineReasonFilter = @(),
        [string[]]$PolicyTypeFilter = @(),
        [string[]]$QuarantineTypesFilter = @()
    )

    if (-not $Messages -or $Messages.Count -eq 0) { return @() }
    if ($QuarantineReasonFilter.Count -eq 0 -and $PolicyTypeFilter.Count -eq 0 -and $QuarantineTypesFilter.Count -eq 0) { return @($Messages) }

    $qrNeedles = @($QuarantineReasonFilter | ForEach-Object { $_.ToLower() })
    $ptNeedles = @($PolicyTypeFilter | ForEach-Object { $_.ToLower() })
    $qtNeedles = @($QuarantineTypesFilter | ForEach-Object { $_.ToLower() })

    $afterFilter = New-Object System.Collections.Generic.List[object]
    foreach ($m in $Messages) {
        $ok = $true
        if ($qrNeedles.Count -gt 0) {
            $qrText = ''
            foreach ($prop in @('QuarantineReason', 'Reason', 'QuarantineTypes')) {
                if ($m.PSObject.Properties[$prop]) {
                    $val = $m.$prop
                    if ($val -is [array]) { $qrText += ' ' + ($val -join ' ') }
                    elseif ($val) { $qrText += ' ' + [string]$val }
                }
            }
            $qrl = $qrText.ToLower()
            $ok = $false
            foreach ($n in $qrNeedles) { if ($qrl -like ('*{0}*' -f $n)) { $ok = $true; break } }
        }
        if ($ok -and $ptNeedles.Count -gt 0) {
            $ptText = ''
            foreach ($prop in @('PolicyType', 'Policy')) { if ($m.PSObject.Properties[$prop]) { $ptText += ' ' + [string]$m.$prop } }
            $ptl = $ptText.ToLower()
            $ok2 = $false
            foreach ($n in $ptNeedles) { if ($ptl -like ('*{0}*' -f $n)) { $ok2 = $true; break } }
            $ok = $ok2
        }
        if ($ok -and $qtNeedles.Count -gt 0) {
            $qtText = ''
            foreach ($prop in @('QuarantineTypes', 'QuarantineType', 'Type')) {
                if ($m.PSObject.Properties[$prop]) {
                    $val = $m.$prop
                    if ($val -is [array]) { $qtText += ' ' + ($val -join ' ') }
                    elseif ($val) { $qtText += ' ' + [string]$val }
                }
            }
            $qtl = $qtText.ToLower()
            $ok3 = $false
            foreach ($n in $qtNeedles) { if ($qtl -like ('*{0}*' -f $n)) { $ok3 = $true; break } }
            $ok = $ok3
        }
        if ($ok) { $afterFilter.Add($m) }
    }

    return @($afterFilter.ToArray())
}

# ---------------------------
# Quarantine deletion helpers
# ---------------------------
function Get-QuarantineMessageDisplayRow {
    <#
    .SYNOPSIS
    Projects a quarantine message into a display-friendly row.

    .DESCRIPTION
    Deletion and review prompts should show the same core fields regardless of
    the original object shape returned by Exchange Online. This helper creates a
    compact projection used by interactive selection views.

    .PARAMETER Message
    Message object from Get-QuarantineMessage.

    .OUTPUTS
    [pscustomobject] with Identity, Reason, ReceivedTime, Subject, Sender, Recipient.
    #>
    [CmdletBinding()]
    param([Parameter(Mandatory)][object]$Message)

    $reason = $null
    if ($Message.PSObject.Properties['QuarantineTypes']) { $reason = ($Message.QuarantineTypes -join ',') }
    elseif ($Message.PSObject.Properties['QuarantineType']) { $reason = $Message.QuarantineType }
    elseif ($Message.PSObject.Properties['Reason']) { $reason = $Message.Reason }

    $fromAddr = $null
    if ($Message.PSObject.Properties['SenderAddress']) { $fromAddr = $Message.SenderAddress }
    $toAddr = $null
    if ($Message.PSObject.Properties['RecipientAddress']) { $toAddr = $Message.RecipientAddress }
    [pscustomobject]@{
        Identity     = $Message.Identity
        Reason       = $reason
        ReceivedTime = $Message.ReceivedTime
        Subject      = $Message.Subject
        Sender       = $fromAddr
        Recipient    = $toAddr
    }
}

function Invoke-DeleteQuarantineMessage {
    <#
    .SYNOPSIS
    Deletes analysed quarantine messages according to the selected mode.

    .DESCRIPTION
    Deletion is intentionally separated from discovery and blocking so operators
    can decide whether to retain analysed samples. This helper centralises the
    safety prompt, grid or console selection path, and retry behaviour for the
    supported delete modes.

    .PARAMETER Messages
    Analysed messages to consider for deletion.

    .PARAMETER Mode
    One of Yes, No, List, Permanent.

    .OUTPUTS
    [pscustomobject] @{ Deleted = int; Failed = int; Mode = string }

    .DOCUMENTATION
    Delete-QuarantineMessage https://learn.microsoft.com/powershell/module/exchangepowershell/delete-quarantinemessage
    #>
    [CmdletBinding()]
    param(
        [Parameter()][AllowEmptyCollection()][object[]]$Messages,
        [ValidateSet('Yes', 'No', 'List', 'Permanent')][string]$Mode = 'List',
        [Parameter()][string[]]$SelectedDomains = @()
    )

    $deleted = 0; $failed = 0
    if (-not $Messages -or $Messages.Count -eq 0) { return [pscustomobject]@{ Deleted = 0; Failed = 0; Mode = $Mode } }

    if ($Mode -eq 'No') { return [pscustomobject]@{ Deleted = 0; Failed = 0; Mode = $Mode } }

    $performDeletes = {
        param($items, [switch]$Hard)
        $useHardDelete = [bool]$Hard
        $localDeleted = 0; $localFailed = 0
        foreach ($m in $items) {
            try {
                Invoke-OperationWithRetry -Label ("Delete-QuarantineMessage:{0}" -f $m.Identity) -MaxRetries 3 -BackoffSecondsBase 2 -Operation {
                    if ($useHardDelete) { Delete-QuarantineMessage -Identity $m.Identity -HardDelete -Confirm:$false -ErrorAction Stop }
                    else { Delete-QuarantineMessage -Identity $m.Identity -Confirm:$false -ErrorAction Stop }
                } | Out-Null
                $localDeleted++
            }
            catch {
                $localFailed++
                Write-Warning ("Failed to delete {0}: {1}" -f $m.Identity, $_.Exception.Message)
            }
        }
        [pscustomobject]@{ Deleted = $localDeleted; Failed = $localFailed }
    }

    switch ($Mode) {
        'Yes' {
            $res = & $performDeletes $Messages
            $deleted += $res.Deleted; $failed += $res.Failed
        }
        'Permanent' {
            # Safety prompt before permanent deletion; default to List per accessibility standards
            $ans = Read-Host "Permanent deletion selected. Proceed? (Y)es / (N)o / (L)ist (Default: N)"
            $choice = 'N'
            if (-not [string]::IsNullOrWhiteSpace($ans)) { $choice = $ans.Trim().Substring(0, 1).ToUpperInvariant() }
            if ($choice -eq 'Y') { $res = & $performDeletes $Messages -Hard; $deleted += $res.Deleted; $failed += $res.Failed }
            elseif ($choice -eq 'L') {
                # Fallthrough to List mode
                $Mode = 'List'
            }
            else {
                return [pscustomobject]@{ Deleted = 0; Failed = 0; Mode = 'Permanent:Aborted' }
            }
            if ($Mode -ne 'List') { return [pscustomobject]@{ Deleted = $deleted; Failed = $failed; Mode = 'Permanent' } }
        }
    }

    # List mode: allow user selection via grid (filtered to selected block domains when provided)
    if ($Mode -eq 'List') {
        $rootsToMatch = @()
        if ($SelectedDomains -and $SelectedDomains.Count -gt 0) { $rootsToMatch = $SelectedDomains | ForEach-Object { Get-ETLDPlusOne $_ } | Select-Object -Unique }

        $toShow = @()
        if ($rootsToMatch.Count -gt 0) {
            foreach ($m in $Messages) {
                $bestRoot = $null
                $senderRoot = $null
                try {
                    if ($m.SenderAddress) { $senderRoot = Get-ETLDPlusOne (ConvertTo-NormalizedAddress $m.SenderAddress) }
                    $headerText = Get-QuarantineMessageHeader -Identity $m.Identity -ErrorAction Stop
                    $origin = Get-MessageOriginAnalysis -Message $m -HeaderText $headerText
                    foreach ($candidate in $origin.PreferredRoots) { if ($candidate) { $bestRoot = $candidate; break } }
                }
                catch {
                    Write-Verbose ("Delete list origin parsing failed for {0}: {1}" -f $m.Identity, $_.Exception.Message)
                    if ($senderRoot) { $bestRoot = $senderRoot }
                }
                if ($bestRoot -and ($rootsToMatch -contains $bestRoot)) { $toShow += $m }
            }
        }
        else { $toShow = $Messages }

        if (-not $toShow -or $toShow.Count -eq 0) { Write-ConsoleMessage 'List mode skipped: no messages match selected block domains.' -ForegroundColor Yellow; return [pscustomobject]@{ Deleted = 0; Failed = 0; Mode = $Mode } }

        $rows = $toShow | ForEach-Object { Get-QuarantineMessageDisplayRow -Message $_ }
        Write-ConsoleMessage "List mode: In Out-GridView, press Ctrl+A to select all, then Ctrl-click to unselect items to keep." -ForegroundColor Yellow
        $selectedRows = @()
        $gridFailed = -not (Test-OutGridViewAvailable)
        if (-not $gridFailed) {
            try { $selectedRows = @($rows | Out-GridView -PassThru -Title 'Select messages to DELETE from quarantine') }
            catch {
                $gridFailed = $true
                Write-Verbose ("Delete list Out-GridView failed: {0}" -f $_.Exception.Message)
            }
        }
        if ($gridFailed) {
            Write-ConsoleMessage 'Out-GridView unavailable or failed. Falling back to console selection.' -ForegroundColor Yellow
            for ($i = 0; $i -lt $rows.Count; $i++) {
                $r = $rows[$i]
                Write-ConsoleMessage ("[{0}] {1} | {2} | {3}" -f $i, $r.Sender, $r.Subject, $r.ReceivedTime) -ForegroundColor Gray
            }
            $ix = Read-Host 'Enter indices to delete (comma-separated) (Default: skip)'
            if (-not [string]::IsNullOrWhiteSpace($ix)) {
                $parts = $ix.Split(',') | ForEach-Object { $_.Trim() } | Where-Object { $_ -ne '' }
                foreach ($p in $parts) {
                    [int]$idxOut = -1
                    if ([int]::TryParse($p, [ref]$idxOut)) {
                        if ($idxOut -ge 0 -and $idxOut -lt $rows.Count) { $selectedRows += $rows[$idxOut] }
                    }
                }
            }
        }
        if ($selectedRows -and $selectedRows.Count -gt 0) {
            $idsToDelete = $selectedRows | Select-Object -ExpandProperty Identity
            $map = @{}
            foreach ($m in $toShow) { $map[$m.Identity.ToString()] = $m }
            $toDelete = @()
            foreach ($id in $idsToDelete) { if ($map.ContainsKey($id.ToString())) { $toDelete += $map[$id.ToString()] } }
            $res2 = & $performDeletes $toDelete
            $deleted += $res2.Deleted; $failed += $res2.Failed
        }
    }

    return [pscustomobject]@{ Deleted = $deleted; Failed = $failed; Mode = $Mode }
}

# ---------------------------
# Release workflow (pre-block)
# ---------------------------
function Test-OutGridViewAvailable {
    <#
        .SYNOPSIS
        Detects whether Out-GridView is available on the current system.

        .DESCRIPTION
        Interactive selection is preferred when available, but the script must
        remain usable on hosts where Out-GridView is absent. This helper allows
        selection workflows to switch cleanly between graphical and console paths.

        .OUTPUTS
        [bool] True when Out-GridView command is present; otherwise False.
        #>
    [CmdletBinding()]
    [OutputType([bool])]
    param()
    return $null -ne (Get-Command -Name Out-GridView -ErrorAction SilentlyContinue)
}

function Get-ReleaseDisplayRow {
    <#
        .SYNOPSIS
        Projects a quarantined message into a display row with key fields.

        .DESCRIPTION
        Release prompts need a stable shape that preserves the original message
        while surfacing the fields an operator uses to decide whether to release.
        This helper creates that row model for both grid and console selection.

        .PARAMETER Message
        The quarantined message object returned by Get-QuarantineMessage.

        .OUTPUTS
        [pscustomobject] with common display fields and the original message attached.
        #>
    [CmdletBinding()]
    param([Parameter(Mandatory)]$Message)

    $received = $null
    try { $received = $Message.ReceivedTime } catch { $received = $null }
    [pscustomobject]@{
        Identity  = $Message.Identity
        Sender    = $Message.SenderAddress
        Recipient = $Message.RecipientAddress
        Subject   = $Message.Subject
        Type      = $Message.QuarantineTypes
        Reason    = $Message.QuarantineReason
        Received  = $received
        Original  = $Message
    }
}

function Get-ReleaseOptionsForMessage {
    <#
        .SYNOPSIS
        Prompts the user for release options for a selected quarantined message.

        .DESCRIPTION
        Release handling can also create allow entries and optional deletions, so
        the script needs one place to capture or derive the per-message choices.
        This helper applies defaults mode when requested and otherwise walks the
        operator through the supported release settings.

        .PARAMETER Row
        A display row produced by Get-ReleaseDisplayRow.

        .OUTPUTS
        [pscustomobject] containing per-message options.
        #>
    [CmdletBinding()]
    param([Parameter(Mandatory)]$Row)

    $mode = Get-InteractionMode
    $nonInteractive = ($mode -eq 'Defaults') -or $Pref_UseDefaultsNoPromptsDefault
    if ($nonInteractive) {
        $releaseAll = ($Pref_ReleaseToAllDefault -eq 'Y')
        $reportFP = ($Pref_ReportFalsePositiveDefault -eq 'Y')
        $allowSenderSwitch = ($Pref_AllowSenderDefault -eq 'Y')
        $createAllow = ($Pref_CreateAllowDefault -eq 'Y')
        $allowScope = Test-ValidAllowScope $Pref_AllowScopeDefault
        $removeAfter = $null; $allowDate = $null
        $choice = Test-ValidExpiryChoice $Pref_AllowExpiryDefault
        switch ($choice) {
            '45' { $removeAfter = 45 }
            '1' { $removeAfter = 1 }
            '7' { $removeAfter = 7 }
            '30' { $removeAfter = 30 }
            'DATE' {
                $parsed = ConvertTo-ExpiryDate $Pref_AllowExpiryDateDefault
                if ($parsed) { $allowDate = $parsed } else { $removeAfter = 45 }
            }
        }
        $allowNote = if ($Pref_AllowNoteAuto) {
            if ($Pref_AllowNoteTemplate) {
                $dateStr = (Get-Date -Format 'dd/MM/yyyy'); $who = $env:USERNAME
                try { $ci = Get-ConnectionInformation | Where-Object { $_.Name -like 'ExchangeOnline*' } | Select-Object -First 1; if ($ci) { $who = $ci.UserPrincipalName } }
                catch { Write-Verbose ("Allow-note connection lookup failed: {0}" -f $_.Exception.Message) }
                $Pref_AllowNoteTemplate.Replace('{DATE}', $dateStr).Replace('{UPN}', $who).Replace('{USERNAME}', $env:USERNAME).Replace('{SCRIPT}', 'Quarantine-To-Block')
            }
            else { Get-BlockNote }
        }
        else { '' }
        $delMode = $Pref_DeleteAfterReleaseDefault
        return [pscustomobject]@{
            ReleaseToAll        = $releaseAll
            ReportFalsePositive = $reportFP
            AllowSender         = $allowSenderSwitch
            CreateAllow         = $createAllow
            AllowScope          = $allowScope
            RemoveAfterDays     = $removeAfter
            ExpirationDate      = $allowDate
            AllowNote           = $allowNote
            DeleteMode          = $delMode
        }
    }

    Write-ConsoleMessage ("\nConfigure release options for: {0} | {1}" -f $Row.Sender, $Row.Subject) -ForegroundColor Cyan

    function Read-YesNo {
        param([string]$Prompt, [string]$Default)
        $def = if ($Default -eq 'Y') { 'Y' } else { 'N' }
        while ($true) {
            $resp = Read-Host ("{0} (Y/N, default: {1})" -f $Prompt, $def)
            if ([string]::IsNullOrWhiteSpace($resp)) { return $def }
            $resp = $resp.Trim().ToUpperInvariant()
            if ($resp -in @('Y', 'N')) { return $resp }
            Write-ConsoleMessage "Please enter Y or N." -ForegroundColor Yellow
        }
    }

    $releaseAll = (Read-YesNo -Prompt 'Release to all original recipients' -Default $Pref_ReleaseToAllDefault) -eq 'Y'
    $reportFP = (Read-YesNo -Prompt 'Report false positive to Microsoft (spam only)' -Default $Pref_ReportFalsePositiveDefault) -eq 'Y'
    $allowSenderSwitch = (Read-YesNo -Prompt 'Allow sender in mailbox (AllowSender switch)' -Default $Pref_AllowSenderDefault) -eq 'Y'

    $createAllow = (Read-YesNo -Prompt 'Create Tenant Allow entry (TABL) for sender' -Default $Pref_CreateAllowDefault) -eq 'Y'
    $allowScope = 'Address'
    $removeAfter = $null
    $allowDate = $null
    $allowNote = ''
    if ($createAllow) {
        # Determine the default answer explicitly (avoid ternary for compatibility)
        $defaultScopeYN = if ($Pref_AllowScopeDefault -eq 'Domain') { 'Y' } else { 'N' }
        $scopeYN = Read-YesNo -Prompt 'Use domain-level allow (default: Address)' -Default $defaultScopeYN
        if ($scopeYN -eq 'Y') { $allowScope = 'Domain' }

        Write-ConsoleMessage 'Select allow expiry: 45(last-used) | 1 | 7 | 30 | Date' -ForegroundColor Gray
        $defLabel = $Pref_AllowExpiryDefault
        $defaultAllowDate = ConvertTo-ExpiryDate $Pref_AllowExpiryDateDefault
        if (($defLabel -eq 'Date') -and $defaultAllowDate) {
            $defLabel = ("Date {0}" -f $defaultAllowDate.ToString('yyyy-MM-dd'))
        }
        $expiry = Read-Host ("Enter one of: 45 | 1 | 7 | 30 | Date (Default: {0})" -f $defLabel)
        if ([string]::IsNullOrWhiteSpace($expiry)) { $expiry = $Pref_AllowExpiryDefault }
        switch ($expiry.Trim().ToUpperInvariant()) {
            '45' { $removeAfter = 45 }
            '1' { $removeAfter = 1 }
            '7' { $removeAfter = 7 }
            '30' { $removeAfter = 30 }
            'DATE' {
                $allowDate = ConvertTo-ExpiryDate $Pref_AllowExpiryDateDefault
                while (-not $allowDate -and $null -eq $removeAfter) {
                    $dt = Read-Host 'Enter specific expiry date (yyyy-MM-dd), max 30 days from today (Default: use 45 days)'
                    if ([string]::IsNullOrWhiteSpace($dt)) {
                        $removeAfter = 45
                        break
                    }
                    $allowDate = ConvertTo-ExpiryDate $dt
                    if (-not $allowDate) { Write-ConsoleMessage 'Please enter a valid expiry date within the next 30 days.' -ForegroundColor Yellow }
                }
            }
            default { $removeAfter = 45 }
        }
        # Mandatory note sourced automatically when configured; otherwise prompt
        if ($Pref_AllowNoteAuto) { $allowNote = Get-BlockNote }
        else { $allowNote = Read-Host 'Note to attach to allow entry (required)' }
    }

    Write-ConsoleMessage 'Delete after release: None | Soft | Hard' -ForegroundColor Gray
    $delMode = Read-Host ('Enter delete mode [None|Soft|Hard] (Default: {0}):' -f $Pref_DeleteAfterReleaseDefault)
    if ([string]::IsNullOrWhiteSpace($delMode)) { $delMode = $Pref_DeleteAfterReleaseDefault }
    $delMode = $delMode.Trim().ToUpperInvariant()
    if ($delMode -notin @('NONE', 'SOFT', 'HARD')) { $delMode = 'NONE' }

    [pscustomobject]@{
        ReleaseToAll        = $releaseAll
        ReportFalsePositive = $reportFP
        AllowSender         = $allowSenderSwitch
        CreateAllow         = $createAllow
        AllowScope          = $allowScope
        RemoveAfterDays     = $removeAfter
        ExpirationDate      = $allowDate
        AllowNote           = $allowNote
        DeleteMode          = $delMode
    }
}

function Invoke-QuarantineReleaseWorkflow {
    <#
        .SYNOPSIS
        Interactive release workflow executed before block/delete analysis.

        .DESCRIPTION
        Release decisions must happen before the script recommends new blocks so
        already-released items are not analysed twice. This helper handles
        selection, per-root option caching, release execution, optional allow-list
        creation, and optional post-release deletion.

        .PARAMETER Messages
        Array of quarantined message objects to display and select for release.

        .PARAMETER MaxRetries
        Maximum retries for operations.

        .PARAMETER BackoffSecondsBase
        Base seconds for linear backoff between retries.

        .OUTPUTS
        [pscustomobject] summary of actions taken.
        #>
    [CmdletBinding()]
    param(
        [Parameter()][AllowEmptyCollection()] [object[]]$Messages,
        [int]$MaxRetries = 3,
        [int]$BackoffSecondsBase = 3
    )

    if (-not $Messages -or $Messages.Count -le 0) { return [pscustomobject]@{ Released = 0; Allowed = 0; DeletedSoft = 0; DeletedHard = 0 } }

    # Filter out any messages already released before presenting the grid
    $messagesToShow = @()
    foreach ($m in $Messages) {
        $isReleased = $false
        try {
            if ($m.PSObject.Properties['ReleaseStatus']) { $isReleased = ($m.ReleaseStatus -match '^Released$') }
            elseif ($m.PSObject.Properties['Status']) { $isReleased = ($m.Status -match '^Released$') }
        }
        catch { $isReleased = $false }
        if (-not $isReleased) { $messagesToShow += $m }
    }
    if (-not $messagesToShow -or $messagesToShow.Count -eq 0) { return [pscustomobject]@{ Released = 0; Allowed = 0; DeletedSoft = 0; DeletedHard = 0 } }

    if ($DryRun) { Write-ConsoleMessage '[DryRun] Release workflow is simulation-only; no EXO changes will be made.' -ForegroundColor Yellow }

    # Build a simple array of display rows to avoid generic List type issues
    $rows = @()
    foreach ($m in $messagesToShow) { $rows += (Get-ReleaseDisplayRow -Message $m) }

    $selected = @()
    $gridFailed = $false
    if (Test-OutGridViewAvailable) {
        try { $selected = $rows | Out-GridView -Title 'Select messages to release' -PassThru } catch { $gridFailed = $true }
    }
    else { $gridFailed = $true }
    if ($gridFailed) {
        Write-ConsoleMessage ('Out-GridView unavailable or failed. Falling back to console selection.') -ForegroundColor Yellow
        for ($i = 0; $i -lt $rows.Count; $i++) {
            $r = $rows[$i]
            Write-ConsoleMessage ("[{0}] {1} | {2} | {3}" -f $i, $r.Sender, $r.Subject, $r.Received) -ForegroundColor Gray
        }
        $ix = Read-Host 'Enter indices to release (comma-separated) (Default: skip)'
        if (-not [string]::IsNullOrWhiteSpace($ix)) {
            $parts = $ix.Split(',') | ForEach-Object { $_.Trim() } | Where-Object { $_ -ne '' }
            foreach ($p in $parts) {
                [int]$idxOut = -1
                if ([int]::TryParse($p, [ref]$idxOut)) {
                    if ($idxOut -ge 0 -and $idxOut -lt $rows.Count) { $selected += $rows[$idxOut] }
                }
            }
        }
    }

    if (-not $selected -or $selected.Count -eq 0) {
        Write-ConsoleMessage 'Release selection cancelled or none selected; continuing without releases.' -ForegroundColor Yellow
        return [pscustomobject]@{ Released = 0; Allowed = 0; DeletedSoft = 0; DeletedHard = 0 }
    }

    $released = 0; $allowed = 0; $delSoft = 0; $delHard = 0
    # Cache release options by sender root to avoid repeated prompts
    $releaseOptionCache = @{}
    # Track allow entries added in this run to avoid duplicate New-TenantAllowBlockListItems calls
    $allowEntriesSeen = New-Object 'System.Collections.Generic.HashSet[string]'
    foreach ($row in $selected) {
        $senderEmailForKey = ConvertTo-NormalizedAddress $row.Sender
        $senderRootKey = $null
        try { if ($senderEmailForKey) { $senderRootKey = Get-ETLDPlusOne (ConvertTo-NormalizedDomain $senderEmailForKey) } } catch { $senderRootKey = $null }

        $opts = $null
        if ($senderRootKey -and $releaseOptionCache.ContainsKey($senderRootKey)) {
            $opts = $releaseOptionCache[$senderRootKey]
        }
        else {
            $opts = Get-ReleaseOptionsForMessage -Row $row
            if ($senderRootKey) { $releaseOptionCache[$senderRootKey] = $opts }
        }
        $msg = $row.Original

        $relParams = @{ Identity = $msg.Identity; Confirm = $false }
        if ($opts.ReleaseToAll) { $relParams['ReleaseToAll'] = $true } else { $relParams['User'] = @($msg.RecipientAddress) }
        if ($opts.ReportFalsePositive) { $relParams['ReportFalsePositive'] = $true }
        if ($opts.AllowSender) { $relParams['AllowSender'] = $true }

        if (-not $DryRun) {
            Invoke-OperationWithRetry -Operation { Release-QuarantineMessage @relParams } -Label ('Release {0}' -f $msg.Identity) -MaxRetries $MaxRetries -BackoffSecondsBase $BackoffSecondsBase | Out-Null
        }
        else { Write-ConsoleMessage ("[DryRun] Would release {0}" -f $msg.Identity) -ForegroundColor DarkYellow }
        $released++

        if ($opts.CreateAllow) {
            # Derive entry value from sender email; never pass raw address to domain resolution
            $senderEmail = ConvertTo-NormalizedAddress $msg.SenderAddress
            $entryValue = $senderEmail
            if ($opts.AllowScope -eq 'Domain') {
                $senderDomain = ConvertTo-NormalizedDomain $senderEmail
                $entryValue = Get-ETLDPlusOne $senderDomain
            }
            if ([string]::IsNullOrWhiteSpace($entryValue)) { continue }
            if ($allowEntriesSeen.Contains($entryValue)) { continue }
            $allowParams = @{ ListType = 'Sender'; Allow = $true; Entries = @($entryValue) }
            if ($null -ne $opts.RemoveAfterDays) { $allowParams['RemoveAfter'] = [int]$opts.RemoveAfterDays }
            if ($null -ne $opts.ExpirationDate) { $allowParams['ExpirationDate'] = $opts.ExpirationDate }
            if (-not [string]::IsNullOrWhiteSpace($opts.AllowNote)) { $allowParams['Notes'] = $opts.AllowNote }
            if (-not $DryRun) {
                try { New-TenantAllowBlockListItems @allowParams | Out-Null; $allowed++; $allowEntriesSeen.Add($entryValue) | Out-Null }
                catch { Write-ConsoleMessage ("Allow entry failed for {0}: {1}" -f $entryValue, $_.Exception.Message) -ForegroundColor Yellow }
            }
            else { Write-ConsoleMessage ("[DryRun] Would allow {0} (scope={1})" -f $entryValue, $opts.AllowScope) -ForegroundColor DarkYellow; $allowed++; $allowEntriesSeen.Add($entryValue) | Out-Null }
        }

        switch ($opts.DeleteMode) {
            'SOFT' { if (-not $DryRun) { Invoke-OperationWithRetry -Operation { Delete-QuarantineMessage -Identity $msg.Identity -Confirm:$false } -Label ('Delete {0}' -f $msg.Identity) -MaxRetries $MaxRetries -BackoffSecondsBase $BackoffSecondsBase | Out-Null } else { Write-ConsoleMessage ("[DryRun] Would delete {0} (soft)" -f $msg.Identity) -ForegroundColor DarkYellow }; $delSoft++ }
            'HARD' { if (-not $DryRun) { Invoke-OperationWithRetry -Operation { Delete-QuarantineMessage -Identity $msg.Identity -HardDelete -Confirm:$false } -Label ('HardDelete {0}' -f $msg.Identity) -MaxRetries $MaxRetries -BackoffSecondsBase $BackoffSecondsBase | Out-Null } else { Write-ConsoleMessage ("[DryRun] Would delete {0} (hard)" -f $msg.Identity) -ForegroundColor DarkYellow }; $delHard++ }
        }
    }

    [pscustomobject]@{ Released = $released; Allowed = $allowed; DeletedSoft = $delSoft; DeletedHard = $delHard }
}

# ---------------------------
# TABL actions and helpers
# ---------------------------
function Get-TenantBlockListSnapshot {
    <#
    .SYNOPSIS
    Gets a combined snapshot of TABL Sender block entries (expiring and no-expiration).

    .DESCRIPTION
    Candidate selection and post-add confirmation both depend on an accurate view
    of existing sender blocks. This helper merges expiring and non-expiring TABL
    entries into one normalised snapshot for root and exact comparisons.

    .OUTPUTS
    [pscustomobject] @{ Exact = string[]; Root = string[] }
    #>
    [CmdletBinding()]
    param()

    $expiring = @()
    $noexp = @()

    # Expiring entries
    try {
        $expEntries = Get-TenantAllowBlockListItems -ListType Sender -Block -ErrorAction Stop
        foreach ($item in $expEntries) {
            if ($item.PSObject.Properties.Match('Entries').Count -gt 0 -and $item.Entries) { $expiring += ($item.Entries | Where-Object { $_ }) }
            elseif ($item.PSObject.Properties.Match('Entry').Count -gt 0 -and $item.Entry) { $expiring += $item.Entry }
        }
    }
    catch { Write-Verbose ("TABL Sender block snapshot (expiring) failed: {0}" -f $_.Exception.Message) }

    # No-expiration entries
    try {
        $noExpEntries = Get-TenantAllowBlockListItems -ListType Sender -Block -NoExpiration -ErrorAction Stop
        foreach ($item in $noExpEntries) {
            if ($item.PSObject.Properties.Match('Entries').Count -gt 0 -and $item.Entries) { $noexp += ($item.Entries | Where-Object { $_ }) }
            elseif ($item.PSObject.Properties.Match('Entry').Count -gt 0 -and $item.Entry) { $noexp += $item.Entry }
        }
    }
    catch { Write-Verbose ("TABL Sender block snapshot (no-expiration) failed: {0}" -f $_.Exception.Message) }

    $exact = @($expiring + $noexp) | ForEach-Object { ConvertTo-NormalizedDomain $_ } | Sort-Object -Unique
    # Preserve tenant label for onmicrosoft.com by using Get-ETLDPlusOne
    $roots = $exact | ForEach-Object { Get-ETLDPlusOne $_ } | Sort-Object -Unique

    return [pscustomobject]@{ Exact = $exact; Root = $roots }
}

function Get-TenantAllowListSnapshot {
    <#
    .SYNOPSIS
    Gets a combined snapshot of TABL Sender allow entries (expiring and no-expiration).

    .DESCRIPTION
    Allow-list suppression is a core safety feature of the workflow. This helper
    collects both expiring and non-expiring allow entries so conflict detection
    can compare new candidates against the full current allow state.

    .OUTPUTS
    [pscustomobject] @{ Exact = string[]; Root = string[] }
    #>
    [CmdletBinding()]
    param()

    $expiring = @()
    $noexp = @()

    try {
        $expEntries = Get-TenantAllowBlockListItems -ListType Sender -Allow -ErrorAction Stop
        foreach ($item in $expEntries) {
            if ($item.PSObject.Properties.Match('Entries').Count -gt 0 -and $item.Entries) { $expiring += ($item.Entries | Where-Object { $_ }) }
            elseif ($item.PSObject.Properties.Match('Entry').Count -gt 0 -and $item.Entry) { $expiring += $item.Entry }
        }
    }
    catch { Write-Verbose ("TABL Sender allow snapshot (expiring) failed: {0}" -f $_.Exception.Message) }

    try {
        $noExpEntries = Get-TenantAllowBlockListItems -ListType Sender -Allow -NoExpiration -ErrorAction Stop
        foreach ($item in $noExpEntries) {
            if ($item.PSObject.Properties.Match('Entries').Count -gt 0 -and $item.Entries) { $noexp += ($item.Entries | Where-Object { $_ }) }
            elseif ($item.PSObject.Properties.Match('Entry').Count -gt 0 -and $item.Entry) { $noexp += $item.Entry }
        }
    }
    catch { Write-Verbose ("TABL Sender allow snapshot (no-expiration) failed: {0}" -f $_.Exception.Message) }

    $exact = @($expiring + $noexp) | ForEach-Object { ConvertTo-NormalizedDomain $_ } | Sort-Object -Unique
    $roots = $exact | ForEach-Object { Get-ETLDPlusOne $_ } | Sort-Object -Unique

    return [pscustomobject]@{ Exact = $exact; Root = $roots }
}
function Get-BlockExpiryArg {
    <#
    .SYNOPSIS
    Translates expiry parameters into arguments for TABL cmdlets.

    .DESCRIPTION
    TABL cmdlets use a combination of NoExpiration and ExpirationDate rather than
    the higher-level BlockExpiry choices exposed by this script. This helper maps
    the script-friendly choices to the cmdlet-friendly argument shape.

    .PARAMETER BlockExpiry
    Never, 1d, 7d, 30d, or Date.

    .PARAMETER BlockExpiryDate
    Required when -BlockExpiry Date.

    .PARAMETER NoExpiration
    Back-compat flag; treated as Never.

    .OUTPUTS
    [hashtable] @{ NoExpiration = bool; ExpirationDate = [DateTime] or $null }
    #>
    [CmdletBinding()]
    [OutputType([hashtable])]
    param([string]$BlockExpiry, [Nullable[datetime]]$BlockExpiryDate, [switch]$NoExpiration)

    # Prefer new setting; fallback to old -NoExpiration if used.
    if ($BlockExpiry -eq 'Never' -or $NoExpiration) {
        return @{ NoExpiration = $true; ExpirationDate = $null }
    }
    elseif ($BlockExpiry -eq '1d') {
        return @{ NoExpiration = $false; ExpirationDate = (Get-Date).AddDays(1).ToUniversalTime() }
    }
    elseif ($BlockExpiry -eq '7d') {
        return @{ NoExpiration = $false; ExpirationDate = (Get-Date).AddDays(7).ToUniversalTime() }
    }
    elseif ($BlockExpiry -eq '30d') {
        return @{ NoExpiration = $false; ExpirationDate = (Get-Date).AddDays(30).ToUniversalTime() }
    }
    elseif ($BlockExpiry -eq 'Date') {
        if (-not $BlockExpiryDate.HasValue) {
            throw 'BlockExpiry Date requires BlockExpiryDate with a valid date within the next 30 days.'
        }
        return @{ NoExpiration = $false; ExpirationDate = $BlockExpiryDate.Value.ToUniversalTime() }
    }
    else {
        return @{ NoExpiration = $true; ExpirationDate = $null }
    }
}

function Get-BlockNote {
    <#
    .SYNOPSIS
    Generates a consistent note string for new TABL entries.

    .DESCRIPTION
    TABL notes are part of the script's audit trail. This helper generates the
    standardised note text that records who added an entry and when it was added.

    .OUTPUTS
    [string] Note including date and operator identity.
    #>
    [CmdletBinding()]
    param()
    $who = $null
    try {
        if (Get-Command Get-ConnectionInformation -ErrorAction SilentlyContinue) {
            $ci = Get-ConnectionInformation | Where-Object { $_.Name -like 'ExchangeOnline*' } | Select-Object -First 1
            if ($ci) { $who = $ci.UserPrincipalName }
        }
    }
    catch { Write-Verbose ("Get-ConnectionInformation failed, falling back to USERNAME: {0}" -f $_.Exception.Message) }
    if (-not $who) { $who = $env:USERNAME }

    $dateStr = (Get-Date -Format 'dd/MM/yyyy')
    $scriptName = 'Quarantine-To-Block'
    $tpl = $Pref_BlockNoteTemplate
    if ([string]::IsNullOrWhiteSpace($tpl)) { $tpl = 'Quarantine-To-Block script, added {DATE}, by {UPN}' }
    $tpl.Replace('{DATE}', $dateStr).Replace('{UPN}', $who).Replace('{USERNAME}', $env:USERNAME).Replace('{SCRIPT}', $scriptName)
}

function Add-TenantBlockListSender {
    <#
    .SYNOPSIS
    Adds sender domains to the Tenant Block List with retries and duplicate-safe logic.

    .DESCRIPTION
    Adding TABL entries is the final mutating step in the workflow, so the logic
    needs retries, duplicate handling, dry-run support, and confirmation-friendly
    output. This helper encapsulates that write path behind a single call.

    .PARAMETER Domains
    Domains to add (exact or root).

    .PARAMETER NoExpiration
    When set, adds as non-expiring entries.

    .PARAMETER ExpirationDate
    When provided, adds with an explicit expiry date (UTC).

    .PARAMETER MaxRetries
    Maximum attempts for the batch/individual operations.

    .PARAMETER BackoffSecondsBase
    Base seconds for linear backoff between attempts.

    .PARAMETER Notes
    Freeform note attached to entries.

    .OUTPUTS
    [pscustomobject] @{ Success = [bool]; Added = [string[]] }
    #>
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Low')]
    param(
        [string[]]$Domains,
        [switch]$NoExpiration,
        [Nullable[datetime]]$ExpirationDate,
        [int]$MaxRetries = 3,
        [int]$BackoffSecondsBase = 3,
        [string]$Notes,
        [switch]$TrustOnSuccess
    )

    if (-not $Domains -or $Domains.Count -eq 0) { return [pscustomobject]@{ Success = $true; Added = @() } }

    $tries = 0
    do {
        try {
            if ($PSCmdlet.ShouldProcess("Tenant Block List", ("Add domains: {0}" -f ($Domains -join ', ')))) {
                $out = $null
                if ($NoExpiration) {
                    if (-not $DryRun) { $out = New-TenantAllowBlockListItems -ListType Sender -Block -Entries $Domains -NoExpiration -Notes $Notes -ErrorAction Stop }
                }
                else {
                    if (-not $DryRun -and $ExpirationDate.HasValue) {
                        $out = New-TenantAllowBlockListItems -ListType Sender -Block -Entries $Domains -ExpirationDate $ExpirationDate.Value -Notes $Notes -ErrorAction Stop
                    }
                    elseif (-not $DryRun -and -not $ExpirationDate.HasValue) {
                        # Default to no-expiration when date missing
                        $out = New-TenantAllowBlockListItems -ListType Sender -Block -Entries $Domains -NoExpiration -Notes $Notes -ErrorAction Stop
                    }
                }
                # Extract added entries from cmdlet output for higher-trust confirmation
                $added = @()
                if ($out) {
                    $items = @($out)
                    foreach ($item in $items) {
                        if ($item.PSObject.Properties.Match('Entries').Count -gt 0 -and $item.Entries) { $added += ($item.Entries | Where-Object { $_ }) }
                        elseif ($item.PSObject.Properties.Match('Entry').Count -gt 0 -and $item.Entry) { $added += $item.Entry }
                    }
                    $added = $added | ForEach-Object { ConvertTo-NormalizedDomain $_ } | Sort-Object -Unique
                }
                elseif ($TrustOnSuccess) {
                    # Fallback: trust inputs if cmdlet succeeded but didn't echo entries
                    $added = $Domains | ForEach-Object { ConvertTo-NormalizedDomain $_ } | Sort-Object -Unique
                }
                return [pscustomobject]@{ Success = $true; Added = $added }
            }
            else {
                # ShouldProcess declined; treat as success without changes
                return [pscustomobject]@{ Success = $true; Added = @() }
            }
        }
        catch {
            if ($_.Exception.Message -match "Duplicate value") {
                # Already present; treat as success quietly to avoid redundant noise
                Write-Verbose ("Duplicate detected, already present: {0}" -f ($Domains -join ', '))
                return [pscustomobject]@{ Success = $true; Added = @() }
            }
            $tries++
            Write-Warning ("New-TenantAllowBlockListItems batch attempt {0} failed: {1}" -f $tries, $_.Exception.Message)
            Start-Sleep -Seconds ($BackoffSecondsBase * $tries)
        }
    } while ($tries -lt $MaxRetries)
    return [pscustomobject]@{ Success = $false; Added = @() }
}

# ---------------------------
# MAIN
# ---------------------------
if ($NoMain -or $Script:LibraryMode -or $env:Q2B_LibraryMode -eq '1') {
    Write-Verbose 'Library mode active: skipping MAIN execution.'
    return
}
Install-ExchangeOnlineModule -AutoInstall:$AutoInstall

# Optional connection diagnostics and timing
if ($DiagConnectionTiming) {
    Write-ConsoleMessage "[Diag] Starting connection diagnostics..." -ForegroundColor Cyan
}

$swOverall = [System.Diagnostics.Stopwatch]::StartNew()
$swConn = [System.Diagnostics.Stopwatch]::StartNew()
if (-not (Connect-ExchangeOnlineWithRetry -UserPrincipalName $UserPrincipalName -MaxRetries $MaxRetries -BackoffSecondsBase $BackoffSecondsBase -AppId $AppId -Organization $Organization -CertificateThumbprint $CertificateThumbprint -PreferAppOnly:$PreferAppOnly)) {
    throw "Unable to connect to Exchange Online after $MaxRetries attempts."
}
$swConn.Stop()
if ($DiagConnectionTiming) {
    $ms = if ($script:ConnectExchangeMs) { $script:ConnectExchangeMs } else { $swConn.ElapsedMilliseconds }
    Write-ConsoleMessage ("[Diag] Connect-ExchangeOnline duration: {0} ms" -f $ms) -ForegroundColor Cyan
}

if ($DiagConnectionTiming) { $swPSL = [System.Diagnostics.Stopwatch]::StartNew() }
Import-PublicSuffixList -PslJsonPath $PslJsonPath
if ($DiagConnectionTiming) { $swPSL.Stop(); Write-ConsoleMessage ("[Diag] PSL load duration: {0} ms" -f $swPSL.ElapsedMilliseconds) -ForegroundColor Cyan }

# Safety: gather tenant-owned domains and exclude from consideration
$tenantDomains = New-Object System.Collections.Generic.HashSet[string]
if ($DiagConnectionTiming) { $swTenant = [System.Diagnostics.Stopwatch]::StartNew() }
try {
    $acc = $null
    try { $acc = Get-AcceptedDomain -ErrorAction Stop } catch { Write-Verbose ("Get-AcceptedDomain failed: {0}" -f $_.Exception.Message) }
    if ($acc) {
        foreach ($d in $acc) { if ($d.DomainName) { [void]$tenantDomains.Add([string]$d.DomainName) } }
    }

    $rem = $null
    try { $rem = Get-RemoteDomain -ErrorAction Stop } catch { Write-Verbose ("Get-RemoteDomain failed: {0}" -f $_.Exception.Message) }
    if ($rem) {
        foreach ($d in $rem) { if ($d.DomainName -and $d.DomainName -ne '*' -and $d.DomainName -ne 'Default') { [void]$tenantDomains.Add([string]$d.DomainName) } }
    }

    $dk = $null
    try { $dk = Get-DkimSigningConfig -ErrorAction Stop } catch { Write-Verbose ("Get-DkimSigningConfig failed: {0}" -f $_.Exception.Message) }
    if ($dk) {
        foreach ($d in $dk) { if ($d.DomainName) { [void]$tenantDomains.Add([string]$d.DomainName) } }
    }
}
catch { Write-Verbose ("Tenant domain discovery encountered an error: {0}" -f $_.Exception.Message) }
if ($DiagConnectionTiming) { $swTenant.Stop(); Write-ConsoleMessage ("[Diag] Tenant domain discovery: {0} ms" -f $swTenant.ElapsedMilliseconds) -ForegroundColor Cyan }

# Exclusions: built-in + param + optional JSON
# Maintain exact excludes for tenant *.onmicrosoft.com, but avoid suppressing all onmicrosoft tenants globally
$excludedExact = @()
if ($tenantDomains.Count -gt 0) {
    $tenantOnMs = $tenantDomains | Where-Object { $_ -like '*.onmicrosoft.com' }
    foreach ($d in $tenantOnMs) { $excludedExact += (ConvertTo-NormalizedDomain $d) }
}

# Build default excluded roots: provider roots + non-onmicrosoft tenant roots
$DefaultExcluded = @()
$DefaultExcluded += $Pref_DefaultExcluded
if ($tenantDomains.Count -gt 0) {
    $tenantNonOnMs = $tenantDomains | Where-Object { $_ -notlike '*.onmicrosoft.com' }
    $tenantRoots = $tenantNonOnMs | ForEach-Object { Get-ETLDPlusOne $_ } | Sort-Object -Unique
    $DefaultExcluded += $tenantRoots
}

$ExcludedDomainsInput = @(); $ExcludedDomainsInput += $DefaultExcluded; $ExcludedDomainsInput += $ExcludedDomains
if ($IncludeProviderRoots -or ($Pref_IncludeProviderRootsDefault -eq 'Y')) {
    # Remove provider defaults from exclusions so they appear as candidates
    $ExcludedDomainsInput = @($ExcludedDomainsInput | Where-Object { $_ -notin $Pref_DefaultExcluded })
    Write-ConsoleMessage 'Including provider roots in BLOCK candidates (provider exclusions removed).' -ForegroundColor Yellow
}

if (-not [string]::IsNullOrWhiteSpace($ExcludedDomainsJsonPath) -and (Test-Path $ExcludedDomainsJsonPath)) {
    try {
        $jsonRaw = Get-Content -Path $ExcludedDomainsJsonPath -Raw
        $jsonObj = $jsonRaw | ConvertFrom-Json
        if ($jsonObj -is [System.Collections.IEnumerable]) { $ExcludedDomainsInput += $jsonObj }
        elseif ($jsonObj.PSObject.Properties['domains']) { $ExcludedDomainsInput += $jsonObj.domains }
        else { Write-Warning "ExcludedDomainsJsonPath loaded but has no array or 'domains' property." }
    }
    catch { Write-Warning ("Failed to read excluded domains JSON: {0}" -f $_.Exception.Message) }
}
$excludedRoots = $ExcludedDomainsInput | Where-Object { $_ } | ForEach-Object { Get-ETLDPlusOne $_ } | Sort-Object -Unique
Write-ConsoleMessage ("Excluded roots (merged): {0}" -f ($excludedRoots -join ', ')) -ForegroundColor Yellow
if ($excludedExact.Count -gt 0) { Write-ConsoleMessage ("Excluded exact: {0}" -f ($excludedExact -join ', ')) -ForegroundColor Yellow }

# Fetch quarantine
$start = (Get-Date).AddDays(-30); $end = Get-Date
$page = 1
$all = New-Object System.Collections.Generic.List[object]

if ($DiagConnectionTiming) { $swFetch = [System.Diagnostics.Stopwatch]::StartNew() }
do {
    $batch = Invoke-OperationWithRetry -Label ("Get-QuarantineMessage page {0}" -f $page) -MaxRetries $MaxRetries -BackoffSecondsBase $BackoffSecondsBase -Operation {
        $qmArgs = @{ StartReceivedDate = $start; EndReceivedDate = $end; PageSize = $PageSize; Page = $page; ErrorAction = 'Stop' }
        if ($QuarantineTypesFilter.Count -gt 0) { $qmArgs['QuarantineTypes'] = $QuarantineTypesFilter }
        $result = $null
        if ($PolicyTypeFilter.Count -gt 0) {
            try {
                $qmArgs['PolicyTypes'] = $PolicyTypeFilter
                $result = Get-QuarantineMessage @qmArgs
            }
            catch {
                $qmArgs.Remove('PolicyTypes')
                Write-Verbose ("Get-QuarantineMessage with -PolicyTypes failed, retrying without: {0}" -f $_.Exception.Message)
                $result = Get-QuarantineMessage @qmArgs
            }
        }
        else {
            $result = Get-QuarantineMessage @qmArgs
        }
        $result
    }
    $batchArray = @($batch)
    $count = $batchArray.Count
    if ($count -gt 0) { $all.AddRange($batchArray) }
    $page++
} while ($count -eq $PageSize)
if ($DiagConnectionTiming) { $swFetch.Stop(); Write-ConsoleMessage ("[Diag] Quarantine fetch duration: {0} ms" -f $swFetch.ElapsedMilliseconds) -ForegroundColor Cyan }
$all = @($all.ToArray())
$filtersAppliedBeforeRelease = $false
if ($QuarantineReasonFilter.Count -gt 0 -or $PolicyTypeFilter.Count -gt 0 -or $QuarantineTypesFilter.Count -gt 0) {
    $all = @(Select-QuarantineMessage -Messages $all -QuarantineReasonFilter $QuarantineReasonFilter -PolicyTypeFilter $PolicyTypeFilter -QuarantineTypesFilter $QuarantineTypesFilter)
    $filtersAppliedBeforeRelease = $true
    Write-ConsoleMessage ("Pre-release filters applied. Items in scope: {0}" -f $all.Count) -ForegroundColor Cyan
}

# Pre-block: interactive release workflow
try {
    # Pass actual messages as an array, not the List wrapper; default summary to zeros
    $relSummary = [pscustomobject]@{ Released = 0; Allowed = 0; DeletedSoft = 0; DeletedHard = 0 }
    $tmpRel = Invoke-QuarantineReleaseWorkflow -Messages $all -MaxRetries $MaxRetries -BackoffSecondsBase $BackoffSecondsBase
    if ($null -ne $tmpRel) { $relSummary = $tmpRel }
    if ($relSummary -and ($relSummary.Released -gt 0 -or $relSummary.Allowed -gt 0 -or $relSummary.DeletedSoft -gt 0 -or $relSummary.DeletedHard -gt 0)) {
        Write-ConsoleMessage ("Release stage: Released={0} | Allowed={1} | DeletedSoft={2} | DeletedHard={3}" -f $relSummary.Released, $relSummary.Allowed, $relSummary.DeletedSoft, $relSummary.DeletedHard) -ForegroundColor Cyan
        # Refresh quarantine list after release stage
        $page = 1
        $all = New-Object System.Collections.Generic.List[object]
        if ($DiagConnectionTiming) { $swFetch = [System.Diagnostics.Stopwatch]::StartNew() }
        do {
            $qmArgs = @{ Page = $page; PageSize = $PageSize; StartReceivedDate = $start; EndReceivedDate = $end }
            $batch = Invoke-OperationWithRetry -Operation {
                Get-QuarantineMessage @qmArgs
            } -Label ("Get-QuarantineMessage page {0}" -f $page) -MaxRetries $MaxRetries -BackoffSecondsBase $BackoffSecondsBase
            $batchArray = @($batch)
            $count = $batchArray.Count
            if ($count -gt 0) { $all.AddRange($batchArray) }
            $page++
        } while ($count -eq $PageSize)
        if ($DiagConnectionTiming) { $swFetch.Stop(); Write-ConsoleMessage ("[Diag] Post-release fetch duration: {0} ms" -f $swFetch.ElapsedMilliseconds) -ForegroundColor Cyan }
        $all = @($all.ToArray())
        if ($QuarantineReasonFilter.Count -gt 0 -or $PolicyTypeFilter.Count -gt 0 -or $QuarantineTypesFilter.Count -gt 0) {
            $all = @(Select-QuarantineMessage -Messages $all -QuarantineReasonFilter $QuarantineReasonFilter -PolicyTypeFilter $PolicyTypeFilter -QuarantineTypesFilter $QuarantineTypesFilter)
            Write-ConsoleMessage ("Post-release filters applied. Items in scope: {0}" -f $all.Count) -ForegroundColor Cyan
        }
    }
}
catch { Write-ConsoleMessage ("Release workflow encountered an error: {0}" -f $_.Exception.Message) -ForegroundColor Yellow }

# Guardrail: skip any messages that have been Released
$kept = New-Object System.Collections.Generic.List[object]
$releasedCount = 0
foreach ($m in $all) {
    $isReleased = $false
    try {
        if ($m.PSObject.Properties['ReleaseStatus']) { $isReleased = ($m.ReleaseStatus -match '^Released$') }
        elseif ($m.PSObject.Properties['Status']) { $isReleased = ($m.Status -match '^Released$') }
    }
    catch { $isReleased = $false }
    if ($isReleased) { $releasedCount++ } else { $kept.Add($m) }
}
$all = @($kept.ToArray())

Write-ConsoleMessage ("Total quarantined items: {0}" -f $all.Count) -ForegroundColor Green
if ($releasedCount -gt 0) { Write-ConsoleMessage ("Skipped released messages: {0}" -f $releasedCount) -ForegroundColor Yellow }

# Optional client-side filters: Quarantine reason, Policy type, Quarantine types
if (-not $filtersAppliedBeforeRelease -and ($QuarantineReasonFilter.Count -gt 0 -or $PolicyTypeFilter.Count -gt 0 -or $QuarantineTypesFilter.Count -gt 0)) {
    $all = @(Select-QuarantineMessage -Messages $all -QuarantineReasonFilter $QuarantineReasonFilter -PolicyTypeFilter $PolicyTypeFilter -QuarantineTypesFilter $QuarantineTypesFilter)
    Write-ConsoleMessage ("After filters, items: {0}" -f $all.Count) -ForegroundColor Cyan
}
# Analyze headers
$discovered = New-Object 'System.Collections.Generic.HashSet[string]'
$mismatches = New-Object System.Collections.Generic.List[object]
${domainCounts} = @{}

# Optional assurance: initialise header stats and failures collection
if ($ValidateHeaders) {
    $script:hdrStats = [pscustomobject]@{
        Attempted = 0
        Succeeded = 0
        Failed    = 0
        Retried   = 0
        Failures  = New-Object System.Collections.Generic.List[object]
        Dumps     = 0
    }
    if ($MaxHeaderDumps -gt 0) {
        try { if (-not (Test-Path $HeaderDumpFolder)) { New-Item -ItemType Directory -Path $HeaderDumpFolder -Force | Out-Null } } catch { Write-Verbose ("Failed to create header dump folder: {0}" -f $_.Exception.Message) }
    }
}

$failedMsgObjs = New-Object System.Collections.Generic.List[object]

foreach ($msg in $all) {
    $senderRoot = $null
    if ($msg.SenderAddress) { $senderRoot = Get-ETLDPlusOne (ConvertTo-NormalizedAddress $msg.SenderAddress) }

    try {
        if ($ValidateHeaders) { $script:hdrStats.Attempted++ }
        $headerText = Invoke-OperationWithRetry -Label "Get-QuarantineMessageHeader" -MaxRetries $MaxRetries -BackoffSecondsBase $BackoffSecondsBase -Operation {
            Get-QuarantineMessageHeader -Identity $msg.Identity -ErrorAction Stop
        }
        if ($ValidateHeaders) {
            $script:hdrStats.Succeeded++
            if ($MaxHeaderDumps -gt 0 -and $script:hdrStats.Dumps -lt $MaxHeaderDumps) {
                try {
                    $safeId = $msg.Identity.ToString()
                    $safeId = ($safeId -replace '[\\/:*?"<>|]', '_')
                    $dumpPath = Join-Path $HeaderDumpFolder ("header_{0}.txt" -f $safeId)
                    Set-Content -Path $dumpPath -Value $headerText -Encoding UTF8
                    $script:hdrStats.Dumps++
                }
                catch { Write-Verbose ("Header dump write failed: {0}" -f $_.Exception.Message) }
            }
        }
        $origin = Get-MessageOriginAnalysis -Message $msg -HeaderText $headerText
        $senderRoot = $origin.SenderRoot

        foreach ($d in $origin.CandidatesToConsider) {
            $root = Get-ETLDPlusOne $d
            $dNorm = ConvertTo-NormalizedDomain $d
            if ( ($excludedExact -notcontains $dNorm) -and ($excludedRoots -notcontains $root) ) {
                [void]$discovered.Add($d)
                $key = $root
                if (-not ${domainCounts}.ContainsKey($key)) { ${domainCounts}[$key] = 0 }
                ${domainCounts}[$key] = ${domainCounts}[$key] + 1
            }
        }

        if ($origin.SenderRoot -and $origin.MailFromRoot -and ($origin.MailFromRoot -ne $origin.SenderRoot)) {
            $mismatches.Add([pscustomobject]@{
                    MessageId     = $msg.MessageId
                    SenderAddress = $msg.SenderAddress
                    SenderRoot    = $origin.SenderRoot
                    MailFromExact = $origin.MailFromExact
                    MailFromRoot  = $origin.MailFromRoot
                    Subject       = $msg.Subject
                    ReceivedTime  = $msg.ReceivedTime
                })
        }
    }
    catch {
        if ($ValidateHeaders) {
            $script:hdrStats.Failed++
            $script:hdrStats.Failures.Add([pscustomobject]@{ Identity = $msg.Identity; Error = $_.Exception.Message; When = (Get-Date) })
            $failedMsgObjs.Add($msg)
            Write-Verbose ("Header fetch failed for {0}: {1}" -f $msg.Identity, $_.Exception.Message)
        }
        else {
            Write-Warning ("Header fetch failed for {0}: {1}" -f $msg.Identity, $_.Exception.Message)
        }
    }
}

# Optional second pass for headers that failed in the first pass
if ($ValidateHeaders -and $failedMsgObjs.Count -gt 0) {
    Start-Sleep -Seconds $HeaderSecondPassDelaySeconds
    $retryList = ($failedMsgObjs | Select-Object -Unique Identity, SenderAddress, Subject, ReceivedTime, MessageId)
    $script:hdrStats.Retried = $retryList.Count

    $stillFailed = New-Object System.Collections.Generic.List[object]
    foreach ($r in $retryList) {
        try {
            $headerText = Invoke-OperationWithRetry -Label ("Get-QuarantineMessageHeader:retry:{0}" -f $r.Identity) -MaxRetries ([math]::Min(2, $MaxRetries)) -BackoffSecondsBase $BackoffSecondsBase -Operation {
                Get-QuarantineMessageHeader -Identity $r.Identity -ErrorAction Stop
            }
            $script:hdrStats.Succeeded++
            $script:hdrStats.Failed--
            Write-Verbose ("[OK] Confirmed headers after delay for {0}" -f $r.Identity)

            # Re-run parsing to fold discoveries into candidates
            $lines = Get-AuthenticationResultsLine $headerText
            $exchLines = Get-ExchangeAuthResultsLine $headerText
            $ffHints2 = ConvertFrom-ForefrontAsfHeader $headerText

            $mailFromExact = $null
            if ($lines.Auth.Count -gt 0) { $mailFromExact = Get-MailFromDomainExact -Lines $lines.Auth }
            if (-not $mailFromExact -and $lines.ARC.Count -gt 0) { $mailFromExact = Get-MailFromDomainExact -Lines $lines.ARC }
            if (-not $mailFromExact -and $exchLines -and $exchLines.Count -gt 0) { $mailFromExact = Get-MailFromDomainExact -Lines $exchLines }

            $mailFromCandidates = Get-MailFromCandidate -HeaderText $headerText
            if (-not $mailFromExact -and $mailFromCandidates.Count -gt 0) { $mailFromExact = $mailFromCandidates[-1] }

            $mailFromRoot = $null
            if ($mailFromExact) { $mailFromRoot = Get-ETLDPlusOne $mailFromExact }

            $senderRoot2 = $null
            if ($r.SenderAddress) { $senderRoot2 = Get-ETLDPlusOne (ConvertTo-NormalizedAddress $r.SenderAddress) }

            $allAuthText2 = ($lines.Auth + $lines.ARC + $exchLines) -join " "
            $hm2 = [regex]::Match($allAuthText2, 'header\.from\s*=\s*([^;,\s]+)', 'IgnoreCase')
            $headerFromRoot2 = $null
            if ($hm2.Success) { $headerFromRoot2 = Get-ETLDPlusOne $hm2.Groups[1].Value }
            if (-not $senderRoot2 -and $headerFromRoot2) { $senderRoot2 = $headerFromRoot2 }

            $heloDom2 = $null; $ptrDom2 = $null
            if ($ffHints2) {
                if ($ffHints2.HELO) { $heloDom2 = ConvertTo-NormalizedDomain $ffHints2.HELO }
                if ($ffHints2.PTR) { $ptrDom2 = ConvertTo-NormalizedDomain $ffHints2.PTR }
            }
            foreach ($d in @($senderRoot2, $mailFromExact, $mailFromRoot, $heloDom2, $ptrDom2)) {
                if ($d) {
                    $root = Get-ETLDPlusOne $d
                    $dNorm2 = ConvertTo-NormalizedDomain $d
                    if ( ($excludedExact -notcontains $dNorm2) -and ($excludedRoots -notcontains $root) ) {
                        [void]$discovered.Add($d)
                        $key = $root
                        if (-not ${domainCounts}.ContainsKey($key)) { ${domainCounts}[$key] = 0 }
                        ${domainCounts}[$key] = ${domainCounts}[$key] + 1
                    }
                }
            }

            if ($senderRoot2 -and $mailFromRoot -and ($mailFromRoot -ne $senderRoot2)) {
                $mismatches.Add([pscustomobject]@{
                        MessageId     = $r.MessageId
                        SenderAddress = $r.SenderAddress
                        SenderRoot    = $senderRoot2
                        MailFromExact = $mailFromExact
                        MailFromRoot  = $mailFromRoot
                        Subject       = $r.Subject
                        ReceivedTime  = $r.ReceivedTime
                    })
            }
        }
        catch {
            $stillFailed.Add([pscustomobject]@{ Identity = $r.Identity; Error = $_.Exception.Message; When = (Get-Date) })
        }
    }
    $script:hdrStats.Failures = $stillFailed
    $script:hdrStats.Failed = $stillFailed.Count
}

# Snapshot TABL (expiring + no-expiration)
$tabl = Get-TenantBlockListSnapshot
$blockedExact = $tabl.Exact
$blockedRoots = $tabl.Root

# Snapshot TABL allow entries for conflict detection/suppression
if ($DetectAllowConflicts) {
    $tallow = Get-TenantAllowListSnapshot
    $allowExact = $tallow.Exact
    $allowRoots = $tallow.Root
}
else {
    $allowExact = @(); $allowRoots = @()
}

# Deduplicate candidates (drop exact or root already blocked)
$discArray = @($discovered)
$discoveredUniqueCount = $discArray.Count
$candidates = $discArray | Sort-Object -Unique | Where-Object {
    ($blockedExact -notcontains $_) -and ( $blockedRoots -notcontains (Get-ETLDPlusOne $_) )
} | Where-Object { $_ -ne 'onmicrosoft.com' }

# Conflicts with Allow list from pre-suppression candidates
$candidatesPreAllow = $candidates
$allowConflicts = @()
if ($DetectAllowConflicts) {
    $allowConflicts = @($candidatesPreAllow | Where-Object { ($allowExact -contains $_) -or ( $allowRoots -contains (Get-ETLDPlusOne $_) ) })
    if ($allowConflicts.Count -gt 0) {
        $confRows = @()
        foreach ($d in $allowConflicts) {
            $root = Get-ETLDPlusOne $d
            $match = if ($allowExact -contains $d) { 'Exact' } elseif ($allowRoots -contains $root) { 'Root' } else { '' }
            $confRows += [pscustomobject]@{ Domain = $d; Root = $root; AllowMatch = $match }
        }
        $confCsv = Join-Path $env:TEMP ("TABL_allow_conflicts_{0}.csv" -f (Get-Date -Format "yyyyMMdd_HHmmss"))
        $confRows | Export-Csv -Path $confCsv -NoTypeInformation
        Write-Warning ("Allow-list conflicts detected: {0}. Exported to: {1}" -f $allowConflicts.Count, $confCsv)
    }
    # Default suppression of allow-listed candidates unless overridden
    if (-not $OverrideAllowConflicts) {
        $candidates = $candidatesPreAllow | Where-Object { ($allowExact -notcontains $_) -and ( $allowRoots -notcontains (Get-ETLDPlusOne $_) ) }
    }
}

$alreadyBlockedCount = (@($discArray) | Where-Object { ($blockedExact -contains $_) -or ( $blockedRoots -contains (Get-ETLDPlusOne $_) ) }).Count
$offeredCount = $candidates.Count
$allowSuppressedCount = 0
if ($allowConflicts.Count -gt 0) { $allowSuppressedCount = $allowConflicts.Count }
$excludedCount = [math]::Max(0, $discoveredUniqueCount - $offeredCount - $alreadyBlockedCount)

Write-ConsoleMessage ("Already in block list: {0}" -f $alreadyBlockedCount) -ForegroundColor Green
Write-ConsoleMessage ("Candidates to add to block list: {0}" -f $offeredCount) -ForegroundColor Green

if ($offeredCount -eq 0 -and $discoveredUniqueCount -gt 0) {
    # Diagnostic: show why discovered domains were not offered
    Write-ConsoleMessage 'All discovered domains were excluded or already blocked.' -ForegroundColor Yellow
    $preview = @($discArray | Select-Object -First 10)
    foreach ($d in $preview) {
        $root = Get-ETLDPlusOne $d
        $status = 'Candidate'
        if ($blockedExact -contains $d -or $blockedRoots -contains $root) { $status = 'AlreadyBlocked' }
        elseif ($DetectAllowConflicts -and (($allowExact -contains $d) -or ($allowRoots -contains $root))) { $status = 'AllowSuppressed' }
        elseif ($excludedRoots -contains $root -or $excludedExact -contains (ConvertTo-NormalizedDomain $d)) { $status = 'Excluded' }
        Write-ConsoleMessage (" - {0} (root: {1}) => {2}" -f $d, $root, $status) -ForegroundColor Gray
    }
    Write-ConsoleMessage 'Tip: use -IncludeProviderRoots to include common providers in the candidate list.' -ForegroundColor Yellow
}

# Selection UI (candidates only; never offers already-blocked items)
$toAdd = @()
if ($candidates.Count -gt 0) {
    try {
        Write-ConsoleMessage "Opening selection grid... Switch to the Out-GridView window to choose domains." -ForegroundColor Yellow
        # Build grid rows with Allowed and EmailCount columns (avoid punctuation that may break some OGV hosts)
        $gridRows = foreach ($d in $candidates) {
            $root = Get-ETLDPlusOne $d
            $isAllowed = $false
            if ($DetectAllowConflicts) {
                $isAllowed = (($allowExact -contains $d) -or ($allowRoots -contains $root))
            }
            $emailCount = 0; if (${domainCounts}.ContainsKey($root)) { $emailCount = ${domainCounts}[$root] }
            $flag = if ($isAllowed) { 'Yes' } else { 'No' }
            [pscustomobject]@{ Domain = $d; Root = $root; Allowed = $flag; EmailCount = $emailCount }
        }
        $selRows = $gridRows | Out-GridView -PassThru -Title "Select domains to BLOCK (Tenant Allow/Block List)"
        if ($selRows) { $toAdd = $selRows | Select-Object -ExpandProperty Domain }
    }
    catch {
        Write-Warning ("Out-GridView failed here; using console selection. {0}" -f $_.Exception.Message)
        $i = 1; $map = @{}
        foreach ($d in $candidates) {
            $root = Get-ETLDPlusOne $d
            $isAllowed = $false
            if ($DetectAllowConflicts) { $isAllowed = (($allowExact -contains $d) -or ($allowRoots -contains $root)) }
            $emailCount = 0; if (${domainCounts}.ContainsKey($root)) { $emailCount = ${domainCounts}[$root] }
            $flag = if ($isAllowed) { 'Yes' } else { 'No' }
            Write-ConsoleMessage ("[{0}] {1}  Allowed?: {2}  Emails: {3}" -f $i, $d, $flag, $emailCount)
            $map[$i] = $d; $i++
        }
        Write-ConsoleMessage "Selection help: enter A for all; use ranges like 1-3,5; or A-3,5 to select all except 3 and 5." -ForegroundColor Yellow
        $sel = Read-Host "Enter selection (A | 1-3,5 | A-3,5) (Default: skip)"
        if ($sel) {
            $inputText = $sel.Trim()
            $allIdx = @($map.Keys | Sort-Object)
            $chooseIdx = @()

            # A or A- exclusions
            if ($inputText -match '^(?i)a(?:\s*-\s*(.+))?$') {
                $chooseIdx = $allIdx
                $exPart = $Matches[1]
                if ($exPart) {
                    $excTokens = $exPart -split "[, \s]+" | Where-Object { $_ }
                    $excIdx = @()
                    foreach ($t in $excTokens) {
                        if ($t -match '^(\d+)-(\d+)$') {
                            $startN = [int]$Matches[1]; $endN = [int]$Matches[2]
                            if ($endN -lt $startN) { $tmp = $startN; $startN = $endN; $endN = $tmp }
                            $excIdx += ($startN..$endN)
                        }
                        elseif ($t -match '^\d+$') {
                            $excIdx += [int]$t
                        }
                    }
                    $excIdx = $excIdx | Sort-Object -Unique
                    $chooseIdx = $chooseIdx | Where-Object { $excIdx -notcontains $_ }
                }
            }
            else {
                # Parse explicit list/ranges like 1-3,5
                $tokens = $inputText -split "[, \s]+" | Where-Object { $_ }
                foreach ($t in $tokens) {
                    if ($t -match '^(\d+)-(\d+)$') {
                        $s = [int]$Matches[1]; $e = [int]$Matches[2]
                        if ($e -lt $s) { $tmp = $s; $s = $e; $e = $tmp }
                        $chooseIdx += ($s..$e)
                    }
                    elseif ($t -match '^\d+$') {
                        $chooseIdx += [int]$t
                    }
                }
                $chooseIdx = $chooseIdx | Sort-Object -Unique
            }

            # Map back to domains, ignoring out-of-range indices
            if ($chooseIdx.Count -gt 0) {
                $toAdd = ($chooseIdx | Where-Object { $map.ContainsKey($_) } | ForEach-Object { $map[$_] }) | Sort-Object -Unique
            }
        }
    }
}

# Pre-filter in case user selected something that became blocked meanwhile
$toAdd = $toAdd | Where-Object { ($blockedExact -notcontains $_) -and ( $blockedRoots -notcontains (Get-ETLDPlusOne $_) ) }
$selectedCount = $toAdd.Count

# Block expiry args and note (honour preferences when running with defaults)
$effBlockExpiry = $BlockExpiry
$effBlockExpiryDate = $BlockExpiryDate
$__mode = Get-InteractionMode
if ($__mode -eq 'Defaults') {
    if (-not $PSBoundParameters.ContainsKey('BlockExpiry')) { $effBlockExpiry = $Pref_BlockExpiryDefault }
    if ($effBlockExpiry -eq 'Date' -and -not $PSBoundParameters.ContainsKey('BlockExpiryDate') -and $null -ne $Pref_BlockExpiryDateDefault) {
        $effBlockExpiryDate = ConvertTo-ExpiryDate $Pref_BlockExpiryDateDefault
    }
}
if ($effBlockExpiry -eq 'Date') {
    $resolvedBlockExpiryDate = ConvertTo-ExpiryDate $effBlockExpiryDate
    if ($null -eq $resolvedBlockExpiryDate) {
        throw 'BlockExpiry Date requires BlockExpiryDate to be a valid date within the next 30 days.'
    }
    $effBlockExpiryDate = $resolvedBlockExpiryDate
}

$expiryArgs = Get-BlockExpiryArg -BlockExpiry $effBlockExpiry -BlockExpiryDate $effBlockExpiryDate -NoExpiration:$NoExpiration
$noteText = if ($Pref_BlockNoteTemplate) { Get-BlockNote } else { Get-BlockNote }

# Add (skip duplicates; do not retry duplicates)
$added = @(); $failed = @(); $confirmedCount = 0
if ($toAdd.Count -gt 0) {
    if ($DryRun) { Write-ConsoleMessage "[DryRun] Skipping actual TABL changes; simulating add flow." -ForegroundColor Yellow }
    Write-ConsoleMessage "Adding selected domains to Tenant Block List..." -ForegroundColor Cyan

    # Batch add first
    # Refresh snapshot before add to avoid offering newly-blocked entries
    $tabl = Get-TenantBlockListSnapshot
    $blockedExact = $tabl.Exact
    $blockedRoots = $tabl.Root
    $toAdd = $toAdd | Where-Object { ($blockedExact -notcontains $_) -and ( $blockedRoots -notcontains (Get-ETLDPlusOne $_) ) }

    if ($toAdd.Count -eq 0) {
        Write-ConsoleMessage "Nothing to add; all selected domains are already blocked." -ForegroundColor Yellow
    }
    else {
        $batchRes = Add-TenantBlockListSender -Domains $toAdd -NoExpiration:$expiryArgs.NoExpiration -ExpirationDate $expiryArgs.ExpirationDate -Notes $noteText -MaxRetries $MaxRetries -BackoffSecondsBase $BackoffSecondsBase -TrustOnSuccess:$PreferCmdletConfirm
        $addedViaCmdlet = @()
        if ($batchRes -and $batchRes.Success) { $addedViaCmdlet = $batchRes.Added }
        if (-not $batchRes.Success) {
            # Fallback: individual adds (skip duplicates)
            foreach ($d in $toAdd) {
                if ( ($blockedExact -contains $d) -or ( $blockedRoots -contains (Get-ETLDPlusOne $d) ) ) { continue }
                $res = Add-TenantBlockListSender -Domains @($d) -NoExpiration:$expiryArgs.NoExpiration -ExpirationDate $expiryArgs.ExpirationDate -Notes $noteText -MaxRetries $MaxRetries -BackoffSecondsBase $BackoffSecondsBase -TrustOnSuccess:$PreferCmdletConfirm
                if ($res.Success) { $added += $d; if ($res.Added) { $addedViaCmdlet += $res.Added } } else { $failed += $d }
            }
        }
        else {
            $added = $toAdd
        }
        # Keep a unique list of domains echoed by the cmdlet for higher-trust pre-confirm
        $script:AddedViaCmdlet = @($addedViaCmdlet | Sort-Object -Unique)
    }
}

# Confirm additions; retry individually up to 2 times if not confirmed
if ($added.Count -gt 0) {
    if ($InitialConfirmDelaySeconds -gt 0) { Start-Sleep -Seconds $InitialConfirmDelaySeconds }
    $refresh = Get-TenantBlockListSnapshot
    $pending = New-Object System.Collections.Generic.List[string]

    foreach ($d in ($added | Sort-Object -Unique)) {
        $norm = ConvertTo-NormalizedDomain $d
        # Trust cmdlet echo if available; tentatively confirm
        if ($script:AddedViaCmdlet -and ($script:AddedViaCmdlet -contains $norm)) {
            Write-ConsoleMessage ("[OK] Added (cmdlet): {0}" -f $d) -ForegroundColor Green
            $confirmedCount++
            continue
        }
        if ( ($refresh.Exact -contains $d) -or ( $refresh.Root -contains (Get-ETLDPlusOne $d) ) ) {
            Write-ConsoleMessage ("[OK] Added and confirmed: {0}" -f $d) -ForegroundColor Green
            $confirmedCount++
        }
        else {
            $pending.Add($d)
        }
    }

    # Extended backoff wait up to MaxConfirmWaitSeconds (tuned progressive backoff)
    if ($pending.Count -gt 0 -and $MaxConfirmWaitSeconds -gt 0) {
        $elapsed = 0
        $step = $Pref_ConfirmBackoffStartSeconds
        while ($elapsed -lt $MaxConfirmWaitSeconds -and $pending.Count -gt 0) {
            Start-Sleep -Seconds $step
            $elapsed += $step
            if ($step -lt $Pref_ConfirmBackoffMaxSeconds) { $step += $Pref_ConfirmBackoffIncrementSeconds } # progressive backoff with cap
            $snap = Get-TenantBlockListSnapshot
            $still = New-Object System.Collections.Generic.List[string]
            foreach ($d in $pending) {
                if ( ($snap.Exact -contains $d) -or ( $snap.Root -contains (Get-ETLDPlusOne $d) ) ) {
                    Write-ConsoleMessage ("[OK] Confirmed present after delay: {0}" -f $d) -ForegroundColor Green
                    $confirmedCount++
                }
                else {
                    $still.Add($d)
                }
            }
            $pending = $still
        }
    }

    # Re-add once if still missing, then final snapshot check
    foreach ($d in @($pending)) {
        $res2 = Add-TenantBlockListSender -Domains @($d) -NoExpiration:$expiryArgs.NoExpiration -ExpirationDate $expiryArgs.ExpirationDate -Notes $noteText -MaxRetries $MaxRetries -BackoffSecondsBase $BackoffSecondsBase -TrustOnSuccess:$PreferCmdletConfirm
        $post = Get-TenantBlockListSnapshot
        if ( ($post.Exact -contains $d) -or ( $post.Root -contains (Get-ETLDPlusOne $d) ) -or ($res2.Success -and ($res2.Added -contains (ConvertTo-NormalizedDomain $d))) ) {
            Write-ConsoleMessage ("[OK] Added and confirmed after retry: {0}" -f $d) -ForegroundColor Green
            $confirmedCount++
        }
        else {
            Write-Warning ("Not confirmed after extended waits: {0}" -f $d)
            $failed += $d
        }
    }
}

# Summary & mismatch export
if ($mismatches.Count -gt 0) {
    $mismatchCsv = Join-Path $env:TEMP ("smtp_mailfrom_mismatches_{0}.csv" -f (Get-Date -Format "yyyyMMdd_HHmmss"))
    $mismatches | Export-Csv -Path $mismatchCsv -NoTypeInformation
    Write-ConsoleMessage ("Mismatch details exported: {0}" -f $mismatchCsv) -ForegroundColor Cyan
    if ($mismatches.Count -gt $MismatchCsvWarnThreshold) {
        Write-Warning ("Mismatch CSV exceeds threshold ({0}). Consider filtering or archiving." -f $MismatchCsvWarnThreshold)
    }
}
else {
    Write-ConsoleMessage "No mismatches detected; no CSV exported." -ForegroundColor Cyan
}

# Header validation summary & coverage gating (optional)
if ($ValidateHeaders) {
    $rate = 0.0
    if ($script:hdrStats.Attempted -gt 0) { $rate = [math]::Round(($script:hdrStats.Succeeded / $script:hdrStats.Attempted), 4) }
    Write-ConsoleMessage ("Header coverage: {0}/{1} ({2:P2}), retried: {3}" -f $script:hdrStats.Succeeded, $script:hdrStats.Attempted, $rate, $script:hdrStats.Retried) -ForegroundColor Cyan

    if ($script:hdrStats.Failed -gt 0) {
        $failCsv = Join-Path $env:TEMP ("quarantine_header_failures_{0}.csv" -f (Get-Date -Format "yyyyMMdd_HHmmss"))
        $script:hdrStats.Failures | Export-Csv -Path $failCsv -NoTypeInformation
        Write-Warning ("Header fetch failures exported: {0}" -f $failCsv)
    }

    if ($rate -lt $MinHeaderSuccessRate) {
        Write-Warning ("Header success rate below threshold ({0:P2} < {1:P2})" -f $rate, $MinHeaderSuccessRate)
        if ($FailOnLowHeaderCoverage) { exit 2 }
    }
}

# End-of-run summary
$addedOKCount = @($added | Sort-Object -Unique).Count
$unconfirmedCount = @($failed | Sort-Object -Unique).Count
Write-ConsoleMessage "---- Summary ----" -ForegroundColor Cyan
Write-ConsoleMessage ("Analysed: {0} | Released skipped: {1}" -f $all.Count, $releasedCount)
if ($relSummary) {
    Write-ConsoleMessage ("Release: Released={0} | Allowed={1} | DeletedSoft={2} | DeletedHard={3}" -f $relSummary.Released, $relSummary.Allowed, $relSummary.DeletedSoft, $relSummary.DeletedHard)
}
Write-ConsoleMessage ("Discovered: {0} | Already blocked: {1} | Excluded: {2}" -f $discoveredUniqueCount, $alreadyBlockedCount, $excludedCount)
if ($allowSuppressedCount -gt 0 -and (-not $OverrideAllowConflicts)) {
    Write-ConsoleMessage ("Allow-list conflicts (suppressed): {0}" -f $allowSuppressedCount) -ForegroundColor Yellow
    $suppListPreview = ($allowConflicts | Select-Object -First 10)
    if ($suppListPreview -and $suppListPreview.Count -gt 0) {
        $more = ''
        if ($allowConflicts.Count -gt $suppListPreview.Count) { $more = (' ... and {0} more' -f ($allowConflicts.Count - $suppListPreview.Count)) }
        Write-ConsoleMessage ("Suppressed domains: {0}{1}" -f ($suppListPreview -join ', '), $more) -ForegroundColor Yellow
    }
}
Write-ConsoleMessage ("Offered: {0} | Selected: {1}" -f $offeredCount, $selectedCount)
Write-ConsoleMessage ("Added: {0} | Confirmed: {1} | Not confirmed: {2}" -f $addedOKCount, $confirmedCount, $unconfirmedCount)

# Optional DNSBL reporting before deletion (only when at least one domain was selected to BLOCK)
$dnsblSummary = $null
try {
    if (($DnsblMode -eq 'ExportAttach') -and ($selectedCount -gt 0)) {
        $dnsblSummary = Invoke-ReportToDnsbl -Messages $all -SelectedDomains $toAdd
    }
}
catch {
    Write-Warning ("DNSBL reporting failed: {0}" -f $_.Exception.Message)
}
if ($dnsblSummary) {
    $sk = if ($dnsblSummary.PSObject.Properties['Skipped']) { $dnsblSummary.Skipped } else { 0 }
    $dnsMessagesReported = 0; $dnsReported = 0; $dnsFailed = 0
    try { $dnsMessagesReported = $dnsblSummary.MessagesReported } catch { $dnsMessagesReported = 0 }
    try { $dnsReported = $dnsblSummary.RecipientSubmissionsSent } catch { $dnsReported = 0 }
    try { $dnsFailed = $dnsblSummary.Failed } catch { $dnsFailed = 0 }
    Write-ConsoleMessage ("DNSBL: MessagesReported={0} | RecipientSubmissions={1} | Failed={2} | Skipped={3} | Mode={4}" -f $dnsMessagesReported, $dnsReported, $dnsFailed, $sk, $DnsblMode) -ForegroundColor Magenta
}

# Optional deletion of analysed quarantine messages (only when at least one domain was selected to BLOCK)
$deleteSummary = $null
try {
    if ($selectedCount -gt 0) {
        $deleteSummary = Invoke-DeleteQuarantineMessage -Messages $all -Mode $DeleteQuarantineMode -SelectedDomains $toAdd
    }
    else {
        Write-ConsoleMessage ('Skipped deletion: no domains selected to BLOCK.') -ForegroundColor Yellow
    }
}
catch {
    $errMsg = ''
    try { $errMsg = $_.Exception.Message } catch { $errMsg = [string]$_ }
    Write-Warning ("Deletion step failed: {0}" -f $errMsg)
}
if ($deleteSummary) {
    $delDeleted = 0; $delFailed = 0; $delMode = ''
    try { $delDeleted = $deleteSummary.Deleted } catch { $delDeleted = 0 }
    try { $delFailed = $deleteSummary.Failed } catch { $delFailed = 0 }
    try { $delMode = $deleteSummary.Mode } catch { $delMode = '' }
    Write-ConsoleMessage ("Deleted: {0} | Delete failures: {1} | Mode: {2}" -f $delDeleted, $delFailed, $delMode) -ForegroundColor Magenta
}

# Overall timing diagnostics
if ($DiagConnectionTiming -and $null -ne $swOverall) {
    try { $swOverall.Stop() }
    catch {
        $errMsg = ''
        try { $errMsg = $_.Exception.Message } catch { $errMsg = [string]$_ }
        Write-Verbose ("Overall timing stopwatch stop failed: {0}" -f $errMsg)
    }
    $elapsedMs = $null
    try { $elapsedMs = $swOverall.ElapsedMilliseconds } catch { $elapsedMs = 0 }
    Write-ConsoleMessage ("[Diag] Overall duration: {0} ms" -f $elapsedMs) -ForegroundColor Cyan
}

# Disconnect only if this script connected
if ($script:DidConnect) {
    try { Disconnect-ExchangeOnline -Confirm:$false }
    catch {
        $errMsg = ''
        try { $errMsg = $_.Exception.Message } catch { $errMsg = [string]$_ }
        Write-Warning ("Disconnect failed: {0}" -f $errMsg)
    }
}
try { Stop-Transcript | Out-Null }
catch {
    $errMsg = ''
    try { $errMsg = $_.Exception.Message } catch { $errMsg = [string]$_ }
    Write-Verbose ("Stop-Transcript failed: {0}" -f $errMsg)
}
