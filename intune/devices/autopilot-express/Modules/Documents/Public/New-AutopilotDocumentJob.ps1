<#
.SYNOPSIS
    Build the detached version-one document job contract from a dispatched record.
.DESCRIPTION
    Requires PowerShell 5.1 or later only. Does not prove a record was saved: the
    future dispatcher must call this only after its guarded save succeeds.
    No storage discovery, file creation, logging or external calls occur here.
.FILECREATED
    2026-10-23
.FILELASTUPDATED
    2026-10-23
#>
function New-AutopilotDocumentJob {
    <#
    .SYNOPSIS
        Snapshot allowlisted identity, document fields and individual step eligibility.
    .PARAMETER Settings
        Validated Resolve-AutopilotDocumentSettings output; absent enablement yields no job.
    .PARAMETER Device
        Normalised current version-two record, never a path into operational data/.
    .PARAMETER Mode
        Explicit trusted parent-session mode, not inferred from template or device text.
    .PARAMETER TenantId
        Parent-session binding. Live requires a non-empty GUID matching the record.
    .PARAMETER CreatedAtUtc
        Generation timestamp; filename date remains the original saved dispatch date.
    .PARAMETER DocumentContext
        Detached site and identity text supplied by the trusted dispatch caller.
        TechnicianGivenName, TechnicianSurname and TechnicianDisplayName describe
        the dispatching actor, never the earlier imaging account. AssignedUserGivenName
        and AssignedUserSurname describe the record's final assigned user. SiteName
        is the selected site's full name. Missing names never fall back to usernames.
    .PARAMETER AssignedUserRequired
        True for the normal final-user assignment workflow. A caller may explicitly
        declare no assigned user is required; this does not supply assignment evidence.
    .OUTPUTS
        Detached serialisable job dictionary, or null when no output is enabled.
    #>
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'None')]
    [OutputType([System.Collections.Specialized.OrderedDictionary])]
    param(
        [Parameter(Mandatory)][System.Collections.IDictionary]$Settings,
        [Parameter(Mandatory)][System.Collections.IDictionary]$Device,
        [Parameter(Mandatory)][ValidateSet('Demo', 'Live')][string]$Mode,
        [Parameter(Mandatory)][ValidateNotNullOrEmpty()][string]$TenantId,
        [DateTimeOffset]$CreatedAtUtc = [DateTimeOffset]::UtcNow,
        [System.Collections.IDictionary]$DocumentContext = @{},
        [bool]$AssignedUserRequired = $true
    )
    if (-not $PSCmdlet.ShouldProcess('Detached document job only; no files or workflow changes', 'Construct')) { return $null }
    if ($Settings['SchemaVersion'] -ne 1 -or $Settings['Values'] -isnot [System.Collections.IDictionary]) { throw 'Unsupported document settings contract.' }
    $values = $Settings['Values']
    $profiles = @()
    foreach ($type in @('BirthCertificate', 'Checklist')) {
        if ($values[('{0}Enabled' -f $type)] -isnot [bool]) { throw 'Document enablement must be a Boolean.' }
        if (-not $values[('{0}Enabled' -f $type)]) { continue }
        $policy = [string]$values[('{0}Mode' -f $type)]
        if ($policy -cnotin @('Disabled', 'GenerateOnly', 'Review', 'GenerateAndAsk', 'AutoPrint')) { throw 'Unsupported document delivery policy.' }
        if ($policy -eq 'Disabled') { continue }
        $profiles += , [ordered]@{ DocumentType = $type; TemplateId = $type; TemplatePath = [string]$values[('{0}TemplatePath' -f $type)]; DeliveryMode = $policy }
    }
    if (-not $profiles.Count) { return $null }
    if ($Device['WorkflowIdVersion'] -ne 2 -or $Device['Status'] -cne 'completed' -or $Device['DispatchConfirmed'] -isnot [bool] -or -not $Device['DispatchConfirmed'] -or $Device['IsCompletionVerified'] -isnot [bool]) { throw 'Document jobs require an explicitly dispatched version-two record.' }
    $identity = [ordered]@{}
    foreach ($key in @('RecordId', 'BuildCycleId')) {
        $parsed = [guid]::Empty
        if ($Device[$key] -isnot [string] -or -not [guid]::TryParse($Device[$key], [ref]$parsed) -or $parsed -eq [guid]::Empty) { throw ('Invalid document identity: {0}.' -f $key) }
        $identity[$key] = $parsed.ToString('D')
    }
    $tenantGuid = [guid]::Empty
    if ($Mode -eq 'Live' -and (-not [guid]::TryParse($TenantId, [ref]$tenantGuid) -or $tenantGuid -eq [guid]::Empty)) { throw 'Live document jobs require a valid bound tenant.' }
    if (($Mode -eq 'Live' -or $Device['TenantId']) -and [string]$Device['TenantId'] -ine $TenantId) { throw 'Document tenant does not match the record.' }
    $dates = [ordered]@{}
    foreach ($key in @('StartedAt', 'CompletedAt', 'DispatchedAt')) {
        $value = $Device[$key]
        if ($value -is [DateTime] -or $value -is [DateTimeOffset]) { $value = $value.ToString('o') }
        $parsedDate = [DateTimeOffset]::MinValue
        if ($value -isnot [string] -or -not [DateTimeOffset]::TryParse($value, [Globalization.CultureInfo]::InvariantCulture, [Globalization.DateTimeStyles]::None, [ref]$parsedDate) -or $parsedDate.Year -le 1) { throw ('Invalid document date: {0}.' -f $key) }
        $dates[$key] = $parsedDate
    }
    if ($dates.StartedAt -gt $dates.CompletedAt -or $dates.CompletedAt -gt $dates.DispatchedAt -or $dates.DispatchedAt -gt $CreatedAtUtc) { throw 'Document record timestamps are not in dispatch order.' }
    $fields = [ordered]@{}
    $fieldMap = [ordered]@{
        SerialNumberOrServiceTag = 'Serial'; ConfigurationItem = 'ConfigItem'; SiteCode = 'SiteCode'
        DeviceType = 'DeviceType'; GroupTag = 'GroupTag'; CompletedBy = 'CompletedBy'
        TechnicianUserPrincipalName = 'TechnicianUserPrincipalName'
        FinalPrimaryUserId = 'FinalPrimaryUserId'; FinalPrimaryUserPrincipalName = 'FinalPrimaryUserPrincipalName'
        FinalPrimaryUserDisplayName = 'FinalPrimaryUserDisplayName'
    }
    foreach ($key in $fieldMap.Keys) {
        $value = $Device[$fieldMap[$key]]
        if ($null -ne $value -and $value -isnot [string]) { throw ('Document field {0} must be text.' -f $key) }
        $fields[$key] = [string]$value
    }
    $contextKeys = @('SiteName', 'TechnicianGivenName', 'TechnicianSurname', 'TechnicianDisplayName', 'AssignedUserGivenName', 'AssignedUserSurname')
    if ($null -eq $DocumentContext) { throw 'Document context must be a dictionary.' }
    foreach ($key in $DocumentContext.Keys) {
        if ($key -cnotin $contextKeys -or $DocumentContext[$key] -isnot [string]) { throw 'Document context accepts only the documented text fields.' }
    }
    $fields['SiteName'] = ([string]$DocumentContext['SiteName']).Trim()
    $fields['TechnicianName'] = ([string]$DocumentContext['TechnicianDisplayName']).Trim()
    $fields['AssignedUserFullName'] = $fields.FinalPrimaryUserDisplayName.Trim()
    foreach ($personPrefix in @('Technician', 'AssignedUser')) {
        $givenName = ([string]$DocumentContext[('{0}GivenName' -f $personPrefix)]).Trim()
        $surname = ([string]$DocumentContext[('{0}Surname' -f $personPrefix)]).Trim()
        if ($givenName -and $surname) {
            $target = if ($personPrefix -eq 'Technician') { 'TechnicianName' } else { 'AssignedUserFullName' }
            $fields[$target] = '{0} {1}' -f $givenName, $surname
        }
    }
    $fields['AssignedUserName'] = ''
    $upnMatch = [regex]::Match($fields.FinalPrimaryUserPrincipalName, '^([^@\s]+)@[^@\s]+$')
    if ($upnMatch.Success) { $fields.AssignedUserName = $upnMatch.Groups[1].Value }
    if ([string]::IsNullOrWhiteSpace($fields.SerialNumberOrServiceTag)) { throw 'A document job requires the exact serial or service tag.' }
    $fields['DispatchDate'] = $dates.DispatchedAt.ToString('ddMMyy', [Globalization.CultureInfo]::InvariantCulture)
    $inventory = $Device['IntuneInventory']
    $inventoryBound = $inventory -is [System.Collections.IDictionary] -and [string]$inventory['BuildCycleId'] -ieq $identity.BuildCycleId -and [string]$inventory['TenantId'] -ieq [string]$Device['TenantId'] -and [string]$inventory['Mode'] -ieq $Mode
    foreach ($key in @('IntuneHostName', 'EthernetMacAddress')) {
        $value = if ($inventoryBound) { $inventory[$key] } else { $null }
        if ($null -ne $value -and $value -isnot [string]) { throw ('Document inventory field {0} must be text.' -f $key) }
        $fields[$key] = [string]$value
    }
    foreach ($key in @('EmployeeNumber', 'Destination', 'Room', 'Location', 'M365Licence', 'Imprivata', 'CriticalDevice', 'PreviousConfigurationItem', 'BuildNotes', 'InstalledBy', 'InstalledAt', 'CmdbUpdatedBy', 'CmdbUpdatedAt', 'VerifiedBy', 'VerifiedAt')) { $fields[$key] = '' }
    $overrideReason = ''
    $isOverride = -not $Device['IsCompletionVerified']
    if ($isOverride) {
        foreach ($entry in @($Device['RecoveryHistory'])) {
            if ($entry -isnot [System.Collections.IDictionary] -or $entry['Stage'] -ne 'CompletionOverride') { continue }
            $entryDate = [DateTimeOffset]::MinValue
            if ([DateTimeOffset]::TryParse([string]$entry['Timestamp'], [Globalization.CultureInfo]::InvariantCulture, [Globalization.DateTimeStyles]::None, [ref]$entryDate) -and $entryDate -eq $dates.DispatchedAt -and $entry['Reason'] -is [string]) { $overrideReason = $entry['Reason'] }
        }
        if ([string]::IsNullOrWhiteSpace($overrideReason)) { throw 'Administrative dispatch requires its saved, matching override reason.' }
    }
    $steps = $Device['Steps']
    if ($steps -isnot [System.Collections.IDictionary]) { throw 'Document step evidence must be a dictionary.' }
    $stepSnapshots = [ordered]@{}
    foreach ($stepId in $steps.Keys) {
        if ($stepId -isnot [string] -or $stepId -notmatch '^[A-Za-z0-9_-]{1,64}$') { throw 'Invalid document step identifier.' }
        $evidence = $steps[$stepId]
        if ($evidence -isnot [System.Collections.IDictionary]) { throw 'Invalid document step evidence.' }
        $eligible = Test-AutopilotDocumentTick -Steps $steps -RequiredStepIds @($stepId) -Mode $Mode -BuildCycleId $identity.BuildCycleId -CycleStartedAt $dates.StartedAt -DispatchedAt $dates.DispatchedAt
        $stepSnapshots[$stepId] = [ordered]@{ ActionName = [string]$evidence['ActionName']; CompletionState = [string]$evidence['CompletionState']; TickEligible = $eligible }
    }
    $settingsSnapshot = [ordered]@{}
    foreach ($key in $values.Keys) {
        if ($values[$key] -isnot [string] -and $values[$key] -isnot [bool] -and $values[$key] -isnot [int] -and $values[$key] -isnot [long]) { throw 'Document settings must contain scalar contract values only.' }
        $settingsSnapshot[$key] = $values[$key]
    }
    $scope = if ($Mode -eq 'Demo') { 'Demo' } else { 'Live-{0}' -f $tenantGuid.ToString('D') }
    $jobId = [guid]::NewGuid().ToString('D')
    $labels = @()
    foreach ($value in @($fields.SerialNumberOrServiceTag, $fields.ConfigurationItem)) {
        $label = [regex]::Replace($value, '[^A-Za-z0-9._-]', '_').Trim('.')
        if (-not $label) { $label = 'Unknown' }
        $labels += $label.Substring(0, [Math]::Min(24, $label.Length))
    }
    $deviceLabel = 'Serial-{0}_CI-{1}' -f $labels[0], $labels[1]
    $certificationLabel = if ($Mode -eq 'Demo') { 'DEMO - NOT LIVE CERTIFICATION' } else { 'Live evidence snapshot' }
    return [ordered]@{
        SchemaVersion = 1; JobId = $jobId; JobDirectoryName = '{0}_{1}' -f $deviceLabel, $jobId; RecordId = $identity.RecordId; BuildCycleId = $identity.BuildCycleId
        Mode = $Mode; TenantId = $TenantId; IsDemo = ($Mode -eq 'Demo'); CertificationLabel = $certificationLabel
        CreatedAtUtc = $CreatedAtUtc.ToUniversalTime().ToString('o'); StartedAt = $dates.StartedAt.ToString('o'); CompletedAt = $dates.CompletedAt.ToString('o'); DispatchedAt = $dates.DispatchedAt.ToString('o')
        IsAdministrativeOverride = $isOverride; OverrideReason = $overrideReason; AssignedUserRequired = $AssignedUserRequired
        Fields = $fields; MissingFields = @($fields.Keys | Where-Object { [string]::IsNullOrWhiteSpace([string]$fields[$_]) })
        Steps = $stepSnapshots; Profiles = $profiles; Settings = $settingsSnapshot
        JobRoot = Join-Path (Join-Path $values.LocalRoot $scope) 'Working'; OutputRoot = Join-Path (Join-Path (Join-Path $values.LocalRoot $scope) 'Output') $deviceLabel
    }
}