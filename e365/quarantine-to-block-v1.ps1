<#
.TITLE
Quarantine-To-Block.ps1

.SYNOPSIS
Automates review of quarantined messages and blocks sender domains in the Tenant Allow/Block List (TABL).

.NOTES
.FILECREATED      : 2025-12-15
.FILELASTUPDATED  : 2025-12-17
.VERSION          : 2.1.0
.REQUIRES         : ExchangeOnlineManagement (EXO V3 cmdlets)
.EXITCODES        : 0 = Success; 2 = Failed header coverage (when -FailOnLowHeaderCoverage)

.DESCRIPTION
Fetches recent quarantine items that have not been released, parses headers to determine the exact smtp.mailfrom domain and registrable root (eTLD+1 via the Public Suffix List), compares against existing TABL entries, and interactively adds new block entries. Includes robust retries, duplicate-safe behaviour, optional header coverage validation, and a non-blocking PSL cache (Mozilla .dat) stored alongside the script.

Filtering is available by Quarantine reason and Policy type (defaults include all). Tenant-owned domains from Accepted Domains, Remote Domains, and DKIM configs are automatically excluded from recommendation to prevent accidental self-blocking.

The script can, at user request, offer to provide a list and/or automate deletion incuding permanent deletion if requested) of relevant messages once analysed.

Safety mechanisms are provided that will help avoid scenarios including:
- Domains that are already in the TABL Allow list, unless the user explictely invokes the relevant override feature

CSV output of actions or conflicts is also provided that shows what was done, or not done.

Comments use EN-AU spelling.

.USAGE EXAMPLE
    .\Quarantine-To-Block.ps1 -AutoInstall `
        -ExcludedDomains @('microsoft.com') `
        -QuarantineTypesFilter @('Phish','HighConfidencePhish') `
        -BlockExpiry Never

Accepted parameters for passing to the script at the command line follow.

.PARAMETER UserPrincipalName
UPN to connect to Exchange Online. If a session is already connected, it is reused.

.PARAMETER AutoInstall
If set, installs ExchangeOnlineManagement for the current user when not present.

.PARAMETER QuarantineTypesFilter
Optional quarantine type filter, e.g. @('Phish','HighConfidencePhish'). If omitted, processes all types returned.

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
    2.1.0 (2025-12-17)
    - Added filters for Quarantine reason and Policy type (default: all).
    - Prevent recommending blocks for tenant-owned domains (Accepted, Remote, DKIM).
    - GridView shows 'Number of emails' per domain; console shows Allowed? + Emails.
    - Summary includes concise list of allow-suppressed domains (when not overriding).
    2.0 (2025-12-17)
    - Added TABL Allow snapshot, conflict detection, CSV export (TABL_allow_conflicts_YYYYMMDD.csv).
    - Default suppression of allow-listed candidates with -OverrideAllowConflicts to include them.
    1.6.0 (2025-12-16)
    - Added header coverage validation mode (-ValidateHeaders, stats, optional gating).
    - Implemented PSL .dat cache and quick fetch with async refresh; enforced onmicrosoft.com rule.
    - Prioritised exact smtp.mailfrom over roots; reduced duplicate noise; refined confirmation flow.
    - Skipped Released quarantine messages before analysis.
    - Fixed single-item paging AddRange issue for quarantine pages.
    - Added comprehensive comment headers and module-level documentation links.
    - Added end-of-run summary (added/confirmed/unconfirmed/skipped).
    - Added optional deletion of analysed quarantine messages: -DeleteQuarantineMode Yes|No|List|Permanent (default: List).
    1.5.0 (2025-12-15)
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

    # Policy type filter (default: all)
    [ValidateSet('Anti-malware policy', 'Safe Attachments policy', 'Anti-phishing policy', 'Anti-spam policy', 'Transport rule', 'Data Loss Prevention Rule')]
    [string[]]$PolicyTypeFilter = @(),

    # Exclusions (merged: built-in 'crispykangaroo.com' + param + JSON)
    [string[]]$ExcludedDomains = @(),
    [string]$ExcludedDomainsJsonPath = "",

    # Block duration configuration
    [ValidateSet('Never', '1d', '7d', '30d', 'Date')]
    [string]$BlockExpiry = 'Never',
    [datetime]$BlockExpiryDate,

    # Back-compat; prefer -BlockExpiry (kept so existing runs still work)
    [switch]$NoExpiration
    ,
    # Header validation (assurance) - opt-in
    [switch]$ValidateHeaders,
    [ValidateRange(0.0, 1.0)]
    [double]$MinHeaderSuccessRate = 0.95,
    [switch]$FailOnLowHeaderCoverage,
    [int]$HeaderSecondPassDelaySeconds = 10,
    [int]$MaxHeaderDumps = 0,
    [string]$HeaderDumpFolder = (Join-Path $env:TEMP 'quarantine-header-dumps')
    ,
    # Post-analysis deletion mode for analysed quarantine messages
    [ValidateSet('Yes', 'No', 'List', 'Permanent')]
    [string]$DeleteQuarantineMode = 'List'
    ,
    # Override default suppression of allow-listed candidates
    [switch]$OverrideAllowConflicts
    ,
    # Toggle allow-list conflict detection and export (useful to disable for speed)
    [bool]$DetectAllowConflicts = $true
    ,
    # Delay before first TABL confirmation snapshot (seconds)
    [ValidateRange(0, 60)]
    [int]$InitialConfirmDelaySeconds = 3
    ,
    # Maximum total seconds to wait for snapshot confirmations after add
    [ValidateRange(0, 300)]
    [int]$MaxConfirmWaitSeconds = 30
    ,
    # Diagnostics: print timing for connect and early stages; probe key endpoints
    [switch]$DiagConnectionTiming
    ,
    # Optional app-only authentication (faster, non-interactive, requires EXO app permissions)
    [string]$AppId = "",
    [string]$Organization = "",
    [string]$CertificateThumbprint = "",
    [switch]$PreferAppOnly
    ,
    # Trust cmdlet success as confirmation (uses input entries when output lacks Entries)
    [switch]$PreferCmdletConfirm
)

# PSScriptAnalyzer: Write-Host is intentionally used for interactive CLI output.
# To suppress PSAvoidUsingWriteHost in CI, use a settings file or pass -ExcludeRule.

# ---------------------------
# Transcript
# ---------------------------
try { Start-Transcript -Path $TranscriptPath -Force | Out-Null } catch { Write-Warning ("Start-Transcript failed: {0}" -f $_.Exception.Message) }

# ---------------------------
# Install EXO module if needed
# ---------------------------
function Install-ExchangeOnlineModule {
    <#
    .SYNOPSIS
    Ensures ExchangeOnlineManagement is available and imported.

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
            $answer = Read-Host "ExchangeOnlineManagement not found. Install for CurrentUser now? (Y/N, default Y)"
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
                if ([string]::IsNullOrWhiteSpace($UserPrincipalName)) {
                    # WAM/MSAL will pick the best cached account; suppress banner/help for faster start
                    Connect-ExchangeOnline -ShowBanner:$false -SkipLoadingCmdletHelp:$true -ErrorAction Stop
                }
                else {
                    # Prefer WAM/MSAL account selection with explicit UPN, suppress banner/help
                    Connect-ExchangeOnline -UserPrincipalName $UserPrincipalName -ShowBanner:$false -SkipLoadingCmdletHelp:$true -ErrorAction Stop
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

function Get-PslWorkingFolder {
    <#
    .SYNOPSIS
    Resolves the working folder for PSL cache/files.

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

    if (-not ($exact -contains 'onmicrosoft.com')) { $exact.Add('onmicrosoft.com') }

    $script:PSLExact = $exact
    $script:PSLWildcard = $wild
    $script:PSLExceptions = $exc
}

function Import-PublicSuffixList {
    <#
    .SYNOPSIS
    Loads PSL rules from JSON (preferred) or cached .dat, with non-blocking network refresh.

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
                if (-not ($exact) -or ($exact.Count -eq 0)) {
                    if ($json.PSObject.Properties['rules'] -and $json.rules) {
                        foreach ($r in $json.rules) {
                            $rr = $r.ToLower().Trim()
                            if ($rr.StartsWith('!')) { $exc.Add($rr.Substring(1)); continue }
                            if ($rr.StartsWith('*.')) { $wild.Add($rr.Substring(2)); continue }
                            $exact.Add($rr)
                        }
                    }
                }
                if (-not ($exact -contains 'onmicrosoft.com')) { $exact.Add('onmicrosoft.com') }
                $script:PSLExact = $exact; $script:PSLWildcard = $wild; $script:PSLExceptions = $exc
                Write-Verbose ("Loaded PSL rules from {0}: exact={1}, wildcard={2}, exceptions={3}" -f $candidate, $exact.Count, $wild.Count, $exc.Count)
                return
            }
        }
        catch {
            Write-Warning ("Failed to parse PSL JSON at {0}: {1}" -f $candidate, $_.Exception.Message)
        }
    }

    # Fallback: PSL .dat with same-folder cache; do not block execution
    $datPath = Join-Path (Get-PslWorkingFolder) 'public_suffix_list.dat'
    $usedCache = $false
    if (Test-Path $datPath) {
        try { ConvertFrom-PslDat -DatPath $datPath; $usedCache = $true; Write-Verbose ("Loaded PSL .dat from cache {0}" -f $datPath) }
        catch { Write-Warning ("Failed to parse cached PSL .dat: {0}" -f $_.Exception.Message) }
    }
    $url = 'https://raw.githubusercontent.com/publicsuffix/list/refs/heads/main/public_suffix_list.dat'
    if (-not $usedCache) {
        $fetched = $false
        try {
            $resp = Invoke-WebRequest -Uri $url -UseBasicParsing -TimeoutSec 5 -ErrorAction Stop
            if ($resp -and $resp.Content) {
                Set-Content -Path $datPath -Value $resp.Content -Encoding UTF8
                ConvertFrom-PslDat -DatPath $datPath
                $usedCache = $true
                $fetched = $true
                Write-Verbose ("Loaded PSL .dat from network into {0}" -f $datPath)
            }
        }
        catch {
            Write-Verbose ("PSL quick fetch failed: {0}" -f $_.Exception.Message)
        }

        if (-not $fetched) {
            # Minimal built-in list to keep script fast and resilient (include common IN/UK/AU)
            $script:PSLExact = [System.Collections.Generic.List[string]]::new()
            $script:PSLWildcard = [System.Collections.Generic.List[string]]::new()
            $script:PSLExceptions = [System.Collections.Generic.List[string]]::new()
            @('onmicrosoft.com', 'ac.in', 'co.in', 'in', 'co.uk', 'com.au', 'net.au', 'org.au', 'edu.au', 'gov.au', 'com', 'net', 'org', 'edu', 'gov') | ForEach-Object { $script:PSLExact.Add($_) }
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
}

function Get-ETLDPlusOne {
    <#
    .SYNOPSIS
    Computes registrable domain (eTLD+1) from a domain or email using loaded PSL rules.

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

    return ($labels[$labels.Count - 2] + '.' + $labels[$labels.Count - 1])
}

# ---------------------------
# Normalization & Retry
# ---------------------------
function ConvertTo-NormalizedAddress {
    <#
    .SYNOPSIS
    Normalises an address-like value by trimming wrappers and separators.

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

function Get-MailFromDomainExact {
    <#
    .SYNOPSIS
    Finds the most recent smtp.mailfrom domain from Authentication-Results lines.

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

# ---------------------------
# Quarantine deletion helpers
# ---------------------------
function Get-QuarantineMessageDisplayRow {
    <#
    .SYNOPSIS
    Projects a quarantine message into a display-friendly row.

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
        [Parameter(Mandatory)][object[]]$Messages,
        [ValidateSet('Yes', 'No', 'List', 'Permanent')][string]$Mode = 'List'
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
            $ans = Read-Host "Permanent deletion selected. Proceed? (Y)es / (N)o / (L)ist (default: N)"
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

    # List mode: allow user selection via grid
    if ($Mode -eq 'List') {
        $rows = $Messages | ForEach-Object { Get-QuarantineMessageDisplayRow -Message $_ }
        Write-Host "List mode: In Out-GridView, press Ctrl+A to select all, then Ctrl-click to unselect items to keep." -ForegroundColor Yellow
        try {
            $selected = $rows | Out-GridView -PassThru -Title "Select messages to DELETE from quarantine"
            if ($selected -and $selected.Count -gt 0) {
                $idsToDelete = $selected | Select-Object -ExpandProperty Identity
                $map = @{}
                foreach ($m in $Messages) { $map[$m.Identity.ToString()] = $m }
                $toDelete = @()
                foreach ($id in $idsToDelete) { if ($map.ContainsKey($id.ToString())) { $toDelete += $map[$id.ToString()] } }
                $res2 = & $performDeletes $toDelete
                $deleted += $res2.Deleted; $failed += $res2.Failed
            }
        }
        catch {
            Write-Warning ("Out-GridView unavailable; skipping deletion step. {0}" -f $_.Exception.Message)
        }
    }

    return [pscustomobject]@{ Deleted = $deleted; Failed = $failed; Mode = $Mode }
}

# ---------------------------
# TABL actions and helpers
# ---------------------------
function Get-TenantBlockListSnapshot {
    <#
    .SYNOPSIS
    Gets a combined snapshot of TABL Sender block entries (expiring and no-expiration).

    .OUTPUTS
    [pscustomobject] @{ Exact = string[]; Root = string[] }
    #>
    [CmdletBinding()]
    param()

    $expiring = @()
    $noexp = @()

    # Expiring entries
    try {
        $expEntries = Get-TenantAllowBlockListItems -ListType Sender -Block -ResultSize Unlimited -ErrorAction Stop
        foreach ($item in $expEntries) {
            if ($item.PSObject.Properties.Match('Entries').Count -gt 0 -and $item.Entries) { $expiring += ($item.Entries | Where-Object { $_ }) }
            elseif ($item.PSObject.Properties.Match('Entry').Count -gt 0 -and $item.Entry) { $expiring += $item.Entry }
        }
    }
    catch { Write-Verbose ("TABL Sender block snapshot (expiring) failed: {0}" -f $_.Exception.Message) }

    # No-expiration entries
    try {
        $noExpEntries = Get-TenantAllowBlockListItems -ListType Sender -Block -NoExpiration -ResultSize Unlimited -ErrorAction Stop
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

    .OUTPUTS
    [pscustomobject] @{ Exact = string[]; Root = string[] }
    #>
    [CmdletBinding()]
    param()

    $expiring = @()
    $noexp = @()

    try {
        $expEntries = Get-TenantAllowBlockListItems -ListType Sender -Allow -ResultSize Unlimited -ErrorAction Stop
        foreach ($item in $expEntries) {
            if ($item.PSObject.Properties.Match('Entries').Count -gt 0 -and $item.Entries) { $expiring += ($item.Entries | Where-Object { $_ }) }
            elseif ($item.PSObject.Properties.Match('Entry').Count -gt 0 -and $item.Entry) { $expiring += $item.Entry }
        }
    }
    catch { Write-Verbose ("TABL Sender allow snapshot (expiring) failed: {0}" -f $_.Exception.Message) }

    try {
        $noExpEntries = Get-TenantAllowBlockListItems -ListType Sender -Allow -NoExpiration -ResultSize Unlimited -ErrorAction Stop
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
            # Expected default: treat missing date as never expire
            return @{ NoExpiration = $true; ExpirationDate = $null }
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
    return ("Quarantine-To-Block script, added {0}, by {1}" -f $dateStr, $who)
}

function Add-TenantBlockListSender {
    <#
    .SYNOPSIS
    Adds sender domains to the Tenant Block List with retries and duplicate-safe logic.

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
Install-ExchangeOnlineModule -AutoInstall:$AutoInstall

# Optional connection diagnostics and timing
if ($DiagConnectionTiming) {
    Write-Host "[Diag] Starting connection diagnostics..." -ForegroundColor Cyan
}

$swOverall = [System.Diagnostics.Stopwatch]::StartNew()
$swConn = [System.Diagnostics.Stopwatch]::StartNew()
if (-not (Connect-ExchangeOnlineWithRetry -UserPrincipalName $UserPrincipalName -MaxRetries $MaxRetries -BackoffSecondsBase $BackoffSecondsBase -AppId $AppId -Organization $Organization -CertificateThumbprint $CertificateThumbprint -PreferAppOnly:$PreferAppOnly)) {
    throw "Unable to connect to Exchange Online after $MaxRetries attempts."
}
$swConn.Stop()
if ($DiagConnectionTiming) {
    $ms = if ($script:ConnectExchangeMs) { $script:ConnectExchangeMs } else { $swConn.ElapsedMilliseconds }
    Write-Host ("[Diag] Connect-ExchangeOnline duration: {0} ms" -f $ms) -ForegroundColor Cyan
}

if ($DiagConnectionTiming) { $swPSL = [System.Diagnostics.Stopwatch]::StartNew() }
Import-PublicSuffixList -PslJsonPath $PslJsonPath
if ($DiagConnectionTiming) { $swPSL.Stop(); Write-Host ("[Diag] PSL load duration: {0} ms" -f $swPSL.ElapsedMilliseconds) -ForegroundColor Cyan }

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
if ($DiagConnectionTiming) { $swTenant.Stop(); Write-Host ("[Diag] Tenant domain discovery: {0} ms" -f $swTenant.ElapsedMilliseconds) -ForegroundColor Cyan }

# Exclusions: built-in + param + optional JSON (all normalized to eTLD+1)
$DefaultExcluded = @('crispykangaroo.com')
# Fold tenant domains into default exclusions (by registrable root)
if ($tenantDomains.Count -gt 0) {
    $tenantRoots = $tenantDomains | ForEach-Object { Get-ETLDPlusOne $_ } | Sort-Object -Unique
    $DefaultExcluded += $tenantRoots
}
$ExcludedDomainsInput = @(); $ExcludedDomainsInput += $DefaultExcluded; $ExcludedDomainsInput += $ExcludedDomains

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
Write-Host ("Excluded roots (merged): {0}" -f ($excludedRoots -join ', ')) -ForegroundColor Yellow

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
if ($DiagConnectionTiming) { $swFetch.Stop(); Write-Host ("[Diag] Quarantine fetch duration: {0} ms" -f $swFetch.ElapsedMilliseconds) -ForegroundColor Cyan }

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
$all = $kept

Write-Host ("Total quarantined items: {0}" -f $all.Count) -ForegroundColor Green
if ($releasedCount -gt 0) { Write-Host ("Skipped released messages: {0}" -f $releasedCount) -ForegroundColor Yellow }

# Optional client-side filters: Quarantine reason, Policy type, Quarantine types
if ($QuarantineReasonFilter.Count -gt 0 -or $PolicyTypeFilter.Count -gt 0 -or $QuarantineTypesFilter.Count -gt 0) {
    $qrNeedles = @($QuarantineReasonFilter | ForEach-Object { $_.ToLower() })
    $ptNeedles = @($PolicyTypeFilter | ForEach-Object { $_.ToLower() })
    $qtNeedles = @($QuarantineTypesFilter | ForEach-Object { $_.ToLower() })

    $afterFilter = New-Object System.Collections.Generic.List[object]
    foreach ($m in $all) {
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
            $ok = $false; foreach ($n in $qrNeedles) { if ($qrl -like ("*{0}*" -f $n)) { $ok = $true; break } }
        }
        if ($ok -and $ptNeedles.Count -gt 0) {
            $ptText = ''
            foreach ($prop in @('PolicyType', 'Policy')) { if ($m.PSObject.Properties[$prop]) { $ptText += ' ' + [string]$m.$prop } }
            $ptl = $ptText.ToLower()
            $ok2 = $false; foreach ($n in $ptNeedles) { if ($ptl -like ("*{0}*" -f $n)) { $ok2 = $true; break } }
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
            $ok3 = $false; foreach ($n in $qtNeedles) { if ($qtl -like ("*{0}*" -f $n)) { $ok3 = $true; break } }
            $ok = $ok3
        }
        if ($ok) { $afterFilter.Add($m) }
    }
    $all = $afterFilter
    Write-Host ("After filters, items: {0}" -f $all.Count) -ForegroundColor Cyan
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
        $lines = Get-AuthenticationResultsLine $headerText

        $mailFromExact = $null
        if ($lines.Auth.Count -gt 0) { $mailFromExact = Get-MailFromDomainExact -Lines $lines.Auth }
        if (-not $mailFromExact -and $lines.ARC.Count -gt 0) { $mailFromExact = Get-MailFromDomainExact -Lines $lines.ARC }

        $mailFromCandidates = Get-MailFromCandidate -HeaderText $headerText
        if (-not $mailFromExact -and $mailFromCandidates.Count -gt 0) { $mailFromExact = $mailFromCandidates[-1] }

        $mailFromRoot = $null
        if ($mailFromExact) { $mailFromRoot = Get-ETLDPlusOne $mailFromExact }

        $allAuthText = ($lines.Auth + $lines.ARC) -join " "
        $hm = [regex]::Match($allAuthText, 'header\.from\s*=\s*([^;,\s]+)', 'IgnoreCase')
        $headerFromRoot = $null
        if ($hm.Success) { $headerFromRoot = Get-ETLDPlusOne $hm.Groups[1].Value }
        if (-not $senderRoot -and $headerFromRoot) { $senderRoot = $headerFromRoot }

        # Prefer exact domain; avoid adding its root when exact is present
        $toConsider = New-Object System.Collections.Generic.List[string]
        if ($mailFromExact) { $toConsider.Add($mailFromExact) }
        if ($mailFromRoot -and (-not $mailFromExact -or (Get-ETLDPlusOne $mailFromExact) -ne $mailFromRoot)) { $toConsider.Add($mailFromRoot) }
        if ($senderRoot -and ($senderRoot -ne $mailFromRoot)) { $toConsider.Add($senderRoot) }

        foreach ($d in $toConsider) {
            $root = Get-ETLDPlusOne $d
            if ($excludedRoots -notcontains $root) {
                [void]$discovered.Add($d)
                $key = $root
                if (-not ${domainCounts}.ContainsKey($key)) { ${domainCounts}[$key] = 0 }
                ${domainCounts}[$key] = ${domainCounts}[$key] + 1
            }
        }

        if ($senderRoot -and $mailFromRoot -and ($mailFromRoot -ne $senderRoot)) {
            $mismatches.Add([pscustomobject]@{
                    MessageId     = $msg.MessageId
                    SenderAddress = $msg.SenderAddress
                    SenderRoot    = $senderRoot
                    MailFromExact = $mailFromExact
                    MailFromRoot  = $mailFromRoot
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

            $mailFromExact = $null
            if ($lines.Auth.Count -gt 0) { $mailFromExact = Get-MailFromDomainExact -Lines $lines.Auth }
            if (-not $mailFromExact -and $lines.ARC.Count -gt 0) { $mailFromExact = Get-MailFromDomainExact -Lines $lines.ARC }

            $mailFromCandidates = Get-MailFromCandidate -HeaderText $headerText
            if (-not $mailFromExact -and $mailFromCandidates.Count -gt 0) { $mailFromExact = $mailFromCandidates[-1] }

            $mailFromRoot = $null
            if ($mailFromExact) { $mailFromRoot = Get-ETLDPlusOne $mailFromExact }

            $senderRoot2 = $null
            if ($r.SenderAddress) { $senderRoot2 = Get-ETLDPlusOne (ConvertTo-NormalizedAddress $r.SenderAddress) }

            $allAuthText2 = ($lines.Auth + $lines.ARC) -join " "
            $hm2 = [regex]::Match($allAuthText2, 'header\.from\s*=\s*([^;,\s]+)', 'IgnoreCase')
            $headerFromRoot2 = $null
            if ($hm2.Success) { $headerFromRoot2 = Get-ETLDPlusOne $hm2.Groups[1].Value }
            if (-not $senderRoot2 -and $headerFromRoot2) { $senderRoot2 = $headerFromRoot2 }

            foreach ($d in @($senderRoot2, $mailFromExact, $mailFromRoot)) {
                if ($d) {
                    $root = Get-ETLDPlusOne $d
                    if ($excludedRoots -notcontains $root) {
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

Write-Host ("Already in block list: {0}" -f $alreadyBlockedCount) -ForegroundColor Green
Write-Host ("Candidates to add to block list: {0}" -f $offeredCount) -ForegroundColor Green

# Selection UI (candidates only; never offers already-blocked items)
$toAdd = @()
if ($candidates.Count -gt 0) {
    try {
        Write-Host "Opening selection grid... Switch to the Out-GridView window to choose domains." -ForegroundColor Yellow
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
            Write-Host ("[{0}] {1}  Allowed?: {2}  Emails: {3}" -f $i, $d, $flag, $emailCount)
            $map[$i] = $d; $i++
        }
        Write-Host "Selection help: enter A for all; use ranges like 1-3,5; or A-3,5 to select all except 3 and 5." -ForegroundColor Yellow
        $sel = Read-Host "Enter selection (A | 1-3,5 | A-3,5). Press Enter to skip (default: skip)"
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

# Block expiry args and note
$expiryArgs = Get-BlockExpiryArg -BlockExpiry $BlockExpiry -BlockExpiryDate $BlockExpiryDate -NoExpiration:$NoExpiration
$noteText = Get-BlockNote

# Add (skip duplicates; do not retry duplicates)
$added = @(); $failed = @(); $confirmedCount = 0
if ($toAdd.Count -gt 0) {
    Write-Host "Adding selected domains to Tenant Block List..." -ForegroundColor Cyan

    # Batch add first
    # Refresh snapshot before add to avoid offering newly-blocked entries
    $tabl = Get-TenantBlockListSnapshot
    $blockedExact = $tabl.Exact
    $blockedRoots = $tabl.Root
    $toAdd = $toAdd | Where-Object { ($blockedExact -notcontains $_) -and ( $blockedRoots -notcontains (Get-ETLDPlusOne $_) ) }

    if ($toAdd.Count -eq 0) {
        Write-Host "Nothing to add; all selected domains are already blocked." -ForegroundColor Yellow
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
            Write-Host ("[OK] Added (cmdlet): {0}" -f $d) -ForegroundColor Green
            $confirmedCount++
            continue
        }
        if ( ($refresh.Exact -contains $d) -or ( $refresh.Root -contains (Get-ETLDPlusOne $d) ) ) {
            Write-Host ("[OK] Added and confirmed: {0}" -f $d) -ForegroundColor Green
            $confirmedCount++
        }
        else {
            $pending.Add($d)
        }
    }

    # Extended backoff wait up to MaxConfirmWaitSeconds
    if ($pending.Count -gt 0 -and $MaxConfirmWaitSeconds -gt 0) {
        $elapsed = 0
        $step = 2
        while ($elapsed -lt $MaxConfirmWaitSeconds -and $pending.Count -gt 0) {
            Start-Sleep -Seconds $step
            $elapsed += $step
            if ($step -lt 10) { $step += 2 } # progressive backoff 2,4,6,8,10...
            $snap = Get-TenantBlockListSnapshot
            $still = New-Object System.Collections.Generic.List[string]
            foreach ($d in $pending) {
                if ( ($snap.Exact -contains $d) -or ( $snap.Root -contains (Get-ETLDPlusOne $d) ) ) {
                    Write-Host ("[OK] Confirmed present after delay: {0}" -f $d) -ForegroundColor Green
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
            Write-Host ("[OK] Added and confirmed after retry: {0}" -f $d) -ForegroundColor Green
            $confirmedCount++
        }
        else {
            Write-Warning ("Not confirmed after extended waits: {0}" -f $d)
            $failed += $d
        }
    }
}

# Summary & mismatch export
$mismatchCsv = Join-Path $env:TEMP ("smtp_mailfrom_mismatches_{0}.csv" -f (Get-Date -Format "yyyyMMdd_HHmmss"))
$mismatches | Export-Csv -Path $mismatchCsv -NoTypeInformation
Write-Host ("Mismatch details exported: {0}" -f $mismatchCsv) -ForegroundColor Cyan
if ($mismatches.Count -gt $MismatchCsvWarnThreshold) {
    Write-Warning ("Mismatch CSV exceeds threshold ({0}). Consider filtering or archiving." -f $MismatchCsvWarnThreshold)
}

# Header validation summary & coverage gating (optional)
if ($ValidateHeaders) {
    $rate = 0.0
    if ($script:hdrStats.Attempted -gt 0) { $rate = [math]::Round(($script:hdrStats.Succeeded / $script:hdrStats.Attempted), 4) }
    Write-Host ("Header coverage: {0}/{1} ({2:P2}), retried: {3}" -f $script:hdrStats.Succeeded, $script:hdrStats.Attempted, $rate, $script:hdrStats.Retried) -ForegroundColor Cyan

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
Write-Host "---- Summary ----" -ForegroundColor Cyan
Write-Host ("Analysed: {0} | Released skipped: {1}" -f $all.Count, $releasedCount)
Write-Host ("Discovered: {0} | Already blocked: {1} | Excluded: {2}" -f $discoveredUniqueCount, $alreadyBlockedCount, $excludedCount)
if ($allowSuppressedCount -gt 0 -and (-not $OverrideAllowConflicts)) {
    Write-Host ("Allow-list conflicts (suppressed): {0}" -f $allowSuppressedCount) -ForegroundColor Yellow
    $suppListPreview = ($allowConflicts | Select-Object -First 10)
    if ($suppListPreview -and $suppListPreview.Count -gt 0) {
        $more = ''
        if ($allowConflicts.Count -gt $suppListPreview.Count) { $more = (' ... and {0} more' -f ($allowConflicts.Count - $suppListPreview.Count)) }
        Write-Host ("Suppressed domains: {0}{1}" -f ($suppListPreview -join ', '), $more) -ForegroundColor Yellow
    }
}
Write-Host ("Offered: {0} | Selected: {1}" -f $offeredCount, $selectedCount)
Write-Host ("Added: {0} | Confirmed: {1} | Not confirmed: {2}" -f $addedOKCount, $confirmedCount, $unconfirmedCount)

# Optional deletion of analysed quarantine messages
$deleteSummary = $null
try {
    $deleteSummary = Invoke-DeleteQuarantineMessage -Messages $all -Mode $DeleteQuarantineMode
}
catch {
    Write-Warning ("Deletion step failed: {0}" -f $_.Exception.Message)
}
if ($deleteSummary) {
    Write-Host ("Deleted: {0} | Delete failures: {1} | Mode: {2}" -f $deleteSummary.Deleted, $deleteSummary.Failed, $deleteSummary.Mode) -ForegroundColor Magenta
}

# Overall timing diagnostics
if ($DiagConnectionTiming -and $null -ne $swOverall) {
    try { $swOverall.Stop() } catch { Write-Verbose ("Overall timing stopwatch stop failed: {0}" -f $_.Exception.Message) }
    Write-Host ("[Diag] Overall duration: {0} ms" -f $swOverall.ElapsedMilliseconds) -ForegroundColor Cyan
}

# Disconnect only if this script connected
if ($script:DidConnect) {
    try { Disconnect-ExchangeOnline -Confirm:$false } catch { Write-Warning ("Disconnect failed: {0}" -f $_.Exception.Message) }
}
try { Stop-Transcript | Out-Null } catch { Write-Verbose ("Stop-Transcript failed: {0}" -f $_.Exception.Message) }
