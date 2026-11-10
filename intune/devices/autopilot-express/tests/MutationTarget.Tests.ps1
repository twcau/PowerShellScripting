<#
.SYNOPSIS
    Tests refreshed mutation targets for Group Tag, enrolment unblock and sync.
.DESCRIPTION
    Extracts actual handlers, result, policy and verification functions with the
    PowerShell parser without starting the CLI. Parameter-aware dependency stubs
    and Pester 5 mocks isolate all tenant requests and technician input. Cached
    identities must never override current context or survive a failed refresh
    as mutation targets. Primary-user assignment receives focused checks too.
.FILECREATED
    2026-10-08
.FILELASTUPDATED
    2026-10-08
#>

BeforeAll {
    $sourcePath = Join-Path (Split-Path -Parent $PSScriptRoot) 'autopilot-express.ps1'
    $tokens = $null
    $parseErrors = $null
    $sourceAst = [System.Management.Automation.Language.Parser]::ParseFile($sourcePath, [ref]$tokens, [ref]$parseErrors)
    if ($parseErrors.Count) { throw ($parseErrors.Message -join '; ') }
    foreach ($functionName in @(
            'Get-GraphTransportFailure', 'Get-GraphOperationFailureMessage',
            'New-OperationResult', 'Get-GraphVerificationPolicy',
            'Wait-AutopilotGroupTagVerification', 'Wait-PrimaryUserAssignmentVerification',
            'Test-ManagedDevicePrimaryUserMatch', 'Invoke-LivePrimaryUserAssignment',
            'ConvertTo-RecordDate', 'ConvertTo-PersistedDate', 'ConvertTo-StepHashtable', 'Assert-AttemptHistory',
            'Get-RecoverySubmissionEvidence', 'Save-RecoverySubmissionEvidence',
            'Invoke-StepApplyGroupTag', 'Invoke-StepClearUserlessEnrollmentStatus',
            'Read-ApplicationRetryChoice', 'Invoke-StepRetryFailedApps'
        )) {
        $definition = $sourceAst.Find({
                param($node)
                $node -is [System.Management.Automation.Language.FunctionDefinitionAst] -and $node.Name -eq $functionName
            }, $true)
        if ($null -eq $definition) { throw ('Missing function: {0}' -f $functionName) }
        Set-Item -Path ('Function:{0}' -f $definition.Name) -Value $definition.Body.GetScriptBlock()
    }

    function Resolve-LiveAutopilotContext {
        param($Device)
        throw ('Unexpected context refresh for serial {0}.' -f $Device.Serial)
    }
    function Get-LiveTenantBinding { param($Device) throw ('Unexpected tenant validation: {0}' -f $Device.Serial) }
    function Resolve-LiveAutopilotTagContext {
        param($Device)
        throw ('Unexpected tag identity refresh for serial {0}.' -f $Device.Serial)
    }
    function Invoke-GraphApiRequest {
        param([string]$Method, [string]$Uri, [hashtable]$Body)
        throw ('Unexpected Graph request: {0} {1}; body {2}.' -f $Method, $Uri, ($Body | ConvertTo-Json -Compress))
    }
    function Get-LiveAutopilotDeviceById {
        param([string]$AutopilotDeviceId)
        throw ('Unexpected Autopilot read for {0}.' -f $AutopilotDeviceId)
    }
    function Get-LiveManagedDevicePrimaryUsers {
        param([string]$ManagedDeviceId)
        throw ('Unexpected managed-device user read for {0}.' -f $ManagedDeviceId)
    }
    function Read-ValidatedInput {
        param([string]$Prompt, [string]$Default, [string]$Type, [string[]]$Choices)
        throw ('Unexpected input: {0}; default {1}; type {2}; choices {3}.' -f $Prompt, $Default, $Type, ($Choices -join ', '))
    }
    function Get-SyncSubmissionLedgerState {
        param($Device, $CycleKey, $Target)
        throw ('Unexpected ledger read: {0} {1} {2}' -f $Device.Serial, $CycleKey, $Target.RecordId)
    }
    function Save-DeviceLedgerEntry {
        param($Device, $LedgerName, $Entry)
        throw ('Unexpected ledger save: {0} {1} {2}' -f $Device.Serial, $LedgerName, $Entry.State)
    }
    function Assert-ActiveStorageReservation {}
    # Logging is intentionally silenced in these isolation tests.
    function Write-AutopilotExpressLog { param($Message, $Level) $null = $Message, $Level }
    function Write-Utf8File { param($Path, $Content) throw ('Unexpected receipt write: {0} {1}' -f $Path, $Content) }
}

Describe 'Mutation target refresh isolation' {
    BeforeEach {
        $script:Runtime = @{ IsDemoMode = $false; ModeDisplayName = 'Live' }
        $script:GraphSession = @{}
        $script:SyncSubmissionPersistenceFailure = $false
        $script:Config = @{ MaxRetryAttempts = 1; RetryBackoffSeconds = 0 }
        $script:device = @{
            RecordId = 'record-1'
            TenantId = '11111111-2222-3333-4444-555555555555'
            Serial = 'SERIAL1'; SiteCode = 'SITE'; DeviceType = 'Desk Top'
            GroupTag = 'previous'; AutopilotDeviceId = 'cached-auto'
            ManagedDeviceId = 'cached-managed'; EntraDeviceId = 'cached-entra'
            Steps = @{}; AttemptHistory = @(); RecoveryActive = $true; RecoveryStartedAt = (Get-Date).AddMinutes(-10)
        }
        $script:user = @{ Id = 'selected-user'; UserPrincipalName = 'user@example.test'; DisplayName = 'Selected User' }
        $script:managedReadCount = 0
        Mock Get-Command { return $null } -ParameterFilter {
            $Name -eq 'Update-MgDeviceManagementWindowsAutopilotDeviceIdentityDeviceProperty'
        }
        Mock Resolve-LiveAutopilotContext {
            $Device.AutopilotDeviceId = 'current-auto'
            $Device.ManagedDeviceId = 'current-managed'
            $Device.EntraDeviceId = 'current-entra'
            return @{ AutopilotDevice = @{ id = 'current-auto' } }
        }
        Mock Resolve-LiveAutopilotTagContext {
            $Device.AutopilotDeviceId = 'current-auto'
            return @{ id = 'current-auto'; serialNumber = $Device.Serial; groupTag = 'previous' }
        }
        Mock Invoke-GraphApiRequest {}
        Mock Get-LiveAutopilotDeviceById {
            return @{ id = 'current-auto'; groupTag = 'SITE-DeskTop'; userPrincipalName = 'user@example.test' }
        }
        Mock Get-LiveManagedDevicePrimaryUsers {
            $script:managedReadCount++
            if ($script:managedReadCount -gt 1) { return $script:user }
        }
        Mock Read-ValidatedInput { return 'Y' }
        Mock Read-ApplicationRetryChoice { return 'Y' }
        Mock Get-LiveTenantBinding { return $Device.TenantId }
        Mock Get-SyncSubmissionLedgerState { return @{ Receipt = $null; IntentExists = $false; IntentAt = '' } }
        Mock Save-DeviceLedgerEntry {
            if ($LedgerName -eq 'AttemptHistory') { $Device.AttemptHistory = @($Device.AttemptHistory) + , $Entry }
        }
        Mock Write-Utf8File {}
    }

    It '<Action> writes only to the refreshed identity' -ForEach @(
        @{ Action = 'ClearUserlessEnrollmentStatus'; Handler = 'Invoke-StepClearUserlessEnrollmentStatus'; Uri = 'https://graph.microsoft.com/beta/deviceManagement/windowsAutopilotDeviceIdentities/current-auto/allowNextEnrollment'; State = 'Submitted' }
        @{ Action = 'RetryFailedApplications'; Handler = 'Invoke-StepRetryFailedApps'; Uri = 'https://graph.microsoft.com/v1.0/deviceManagement/managedDevices/current-managed/syncDevice'; State = 'TechnicianConfirmed' }
    ) {
        $script:expectedMutationUri = $Uri
        $stepId = if ($Action -eq 'ClearUserlessEnrollmentStatus') { 'P' } else { 'M' }
        $result = & $Handler -Device $script:device -StepDefinition @{ Id = $stepId; ActionName = $Action }
        $result.CompletionState | Should -Be $State
        $script:device.AutopilotDeviceId | Should -Be 'current-auto'
        $script:device.ManagedDeviceId | Should -Be 'current-managed'
        Should -Invoke Resolve-LiveAutopilotContext -Times 1 -Exactly -ParameterFilter { $Device.Serial -eq 'SERIAL1' }
        Should -Invoke Invoke-GraphApiRequest -Times 1 -Exactly
        Should -Invoke Invoke-GraphApiRequest -Times 1 -Exactly -ParameterFilter { $Method -eq 'POST' -and $Uri -eq $script:expectedMutationUri }
        Should -Invoke Invoke-GraphApiRequest -Times 0 -Exactly -ParameterFilter { $Method -eq 'DELETE' -or $Uri -match 'cached-' }
        if ($Action -eq 'ApplyGroupTag') {
            $result.Success | Should -BeTrue
            Should -Invoke Get-LiveAutopilotDeviceById -Times 1 -Exactly -ParameterFilter { $AutopilotDeviceId -eq 'current-auto' }
            Should -Invoke Invoke-GraphApiRequest -Times 1 -Exactly -ParameterFilter { $Body.groupTag -ceq 'SITE-DeskTop' }
        }
    }

    It '<Action> clears an absent current target and performs no write' -ForEach @(
        @{ Action = 'ClearUserlessEnrollmentStatus'; Handler = 'Invoke-StepClearUserlessEnrollmentStatus'; State = 'Failed' }
        @{ Action = 'RetryFailedApplications'; Handler = 'Invoke-StepRetryFailedApps'; State = 'Failed' }
    ) {
        Mock Resolve-LiveAutopilotContext {
            $Device.AutopilotDeviceId = ''
            $Device.ManagedDeviceId = ''
            $Device.EntraDeviceId = ''
            return @{ AutopilotDevice = $null }
        }
        $stepId = if ($Action -eq 'ClearUserlessEnrollmentStatus') { 'P' } else { 'M' }
        $result = & $Handler -Device $script:device -StepDefinition @{ Id = $stepId; ActionName = $Action }
        $result.Success | Should -BeFalse
        $result.CompletionState | Should -Be $State
        $script:device.AutopilotDeviceId | Should -BeNullOrEmpty
        $script:device.ManagedDeviceId | Should -BeNullOrEmpty
        Should -Invoke Resolve-LiveAutopilotContext -Times 1 -Exactly
        Should -Invoke Invoke-GraphApiRequest -Times 0 -Exactly
        Should -Invoke Get-LiveAutopilotDeviceById -Times 0 -Exactly
        Should -Invoke Read-ValidatedInput -Times 0 -Exactly
    }

    It '<Action> fails without POST or DELETE when refresh throws' -ForEach @(
        @{ Action = 'ClearUserlessEnrollmentStatus'; Handler = 'Invoke-StepClearUserlessEnrollmentStatus' }
        @{ Action = 'RetryFailedApplications'; Handler = 'Invoke-StepRetryFailedApps' }
    ) {
        Mock Resolve-LiveAutopilotContext { throw 'Current context unavailable' }
        $stepId = if ($Action -eq 'ClearUserlessEnrollmentStatus') { 'P' } else { 'M' }
        $result = & $Handler -Device $script:device -StepDefinition @{ Id = $stepId; ActionName = $Action }
        $result.Success | Should -BeFalse
        $result.CompletionState | Should -Be 'Failed'
        $result.Notes | Should -Match 'Current context unavailable'
        Should -Invoke Resolve-LiveAutopilotContext -Times 1 -Exactly
        Should -Invoke Invoke-GraphApiRequest -Times 0 -Exactly
        Should -Invoke Get-LiveAutopilotDeviceById -Times 0 -Exactly
        Should -Invoke Read-ValidatedInput -Times 0 -Exactly
    }

    It 'writes a tag only to its freshly validated Autopilot target without unrelated context reads' {
        $result = Invoke-StepApplyGroupTag -Device $script:device -StepDefinition @{ Id = 'C'; ActionName = 'ApplyGroupTag' }
        $result.CompletionState | Should -Be Verified
        $script:device.ManagedDeviceId | Should -BeExactly 'cached-managed'
        $script:device.EntraDeviceId | Should -BeExactly 'cached-entra'
        Should -Invoke Resolve-LiveAutopilotContext -Times 0 -Exactly
        Should -Invoke Resolve-LiveAutopilotTagContext -Times 1 -Exactly
        Should -Invoke Get-LiveAutopilotDeviceById -Times 1 -Exactly -ParameterFilter { $AutopilotDeviceId -eq 'current-auto' }
        Should -Invoke Invoke-GraphApiRequest -Times 1 -Exactly -ParameterFilter {
            $Method -eq 'POST' -and $Uri -eq 'https://graph.microsoft.com/v1.0/deviceManagement/windowsAutopilotDeviceIdentities/current-auto/updateDeviceProperties' -and $Body.groupTag -ceq 'SITE-DeskTop'
        }
    }

    It 'refuses a Live unblock when its saved step evidence cannot be inspected' {
        $script:device.Steps = $null
        $result = Invoke-StepClearUserlessEnrollmentStatus -Device $script:device -StepDefinition @{ Id = 'P'; ActionName = 'ClearUserlessEnrollmentStatus' }
        $result.CompletionState | Should -Be Blocked
        $result.Notes | Should -Match 'No unblock request was sent'
        Should -Invoke Resolve-LiveAutopilotContext -Times 0 -Exactly
        Should -Invoke Invoke-GraphApiRequest -Times 0 -Exactly
    }

    It 'blocks tag mutation when the narrow identity read returns no Autopilot identity' {
        Mock Resolve-LiveAutopilotTagContext { return $null }
        (Invoke-StepApplyGroupTag -Device $script:device -StepDefinition @{ ActionName = 'ApplyGroupTag' }).CompletionState | Should -Be Blocked
        Should -Invoke Invoke-GraphApiRequest -Times 0 -Exactly
        Should -Invoke Get-LiveAutopilotDeviceById -Times 0 -Exactly
    }

    It 'fails tag mutation without POST when its narrow identity refresh throws' {
        Mock Resolve-LiveAutopilotTagContext { throw 'Synthetic tag identity failure.' }
        (Invoke-StepApplyGroupTag -Device $script:device -StepDefinition @{ ActionName = 'ApplyGroupTag' }).CompletionState | Should -Be Failed
        Should -Invoke Invoke-GraphApiRequest -Times 0 -Exactly
        Should -Invoke Get-LiveAutopilotDeviceById -Times 0 -Exactly
    }

    It 'keeps all three Demo handlers isolated from refresh and writes' {
        $script:Runtime.IsDemoMode = $true
        foreach ($handler in @('Invoke-StepApplyGroupTag', 'Invoke-StepClearUserlessEnrollmentStatus', 'Invoke-StepRetryFailedApps')) {
            $result = & $handler -Device $script:device -StepDefinition @{ ActionName = $handler }
            $result.Success | Should -BeTrue
            $result.CompletionState | Should -Be 'Simulated'
            $result.IsSimulated | Should -BeTrue
        }
        $script:device.AutopilotDeviceId | Should -Be 'cached-auto'
        $script:device.ManagedDeviceId | Should -Be 'cached-managed'
        Should -Invoke Resolve-LiveAutopilotContext -Times 0 -Exactly
        Should -Invoke Invoke-GraphApiRequest -Times 0 -Exactly
        Should -Invoke Get-LiveAutopilotDeviceById -Times 0 -Exactly
        Should -Invoke Read-ValidatedInput -Times 0 -Exactly
    }

    It 'assigns the primary user only on refreshed Autopilot and managed-device surfaces' {
        $result = Invoke-LivePrimaryUserAssignment -Device $script:device -User $script:user
        $result.AutopilotAssigned | Should -BeTrue
        $result.ManagedDeviceConfirmed | Should -BeTrue
        Should -Invoke Resolve-LiveAutopilotContext -Times 1 -Exactly
        Should -Invoke Invoke-GraphApiRequest -Times 2 -Exactly
        Should -Invoke Invoke-GraphApiRequest -Times 1 -Exactly -ParameterFilter {
            $Method -eq 'POST' -and $Uri -eq 'https://graph.microsoft.com/v1.0/deviceManagement/windowsAutopilotDeviceIdentities/current-auto/assignUserToDevice' -and $Body.userPrincipalName -eq 'user@example.test'
        }
        Should -Invoke Invoke-GraphApiRequest -Times 1 -Exactly -ParameterFilter {
            $Method -eq 'POST' -and $Uri -eq 'https://graph.microsoft.com/v1.0/deviceManagement/managedDevices(''current-managed'')/users/$ref' -and $Body['@odata.id'] -eq 'https://graph.microsoft.com/v1.0/users/selected-user'
        }
        Should -Invoke Invoke-GraphApiRequest -Times 0 -Exactly -ParameterFilter { $Method -eq 'DELETE' -or $Uri -match 'cached-' }
        Should -Invoke Get-LiveAutopilotDeviceById -Times 1 -Exactly -ParameterFilter { $AutopilotDeviceId -eq 'current-auto' }
        Should -Invoke Get-LiveManagedDevicePrimaryUsers -Times 2 -Exactly -ParameterFilter { $ManagedDeviceId -eq 'current-managed' }
    }

    It 'propagates primary-assignment refresh failure before any POST or DELETE' {
        Mock Resolve-LiveAutopilotContext { throw 'Current context unavailable' }
        { Invoke-LivePrimaryUserAssignment -Device $script:device -User $script:user } | Should -Throw '*Current context unavailable*'
        Should -Invoke Resolve-LiveAutopilotContext -Times 1 -Exactly
        Should -Invoke Invoke-GraphApiRequest -Times 0 -Exactly
        Should -Invoke Get-LiveAutopilotDeviceById -Times 0 -Exactly
        Should -Invoke Get-LiveManagedDevicePrimaryUsers -Times 0 -Exactly
    }
}