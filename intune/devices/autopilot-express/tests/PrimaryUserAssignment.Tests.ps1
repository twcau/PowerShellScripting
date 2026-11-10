<#
.SYNOPSIS
    Isolated regression tests for primary-user assignment evidence.
.DESCRIPTION
    Extracts product functions without starting the CLI. Graph, selection and
    persistence are mocked; no tenant or operational records are accessed.
    Requires Pester 5 and FullLanguage for source parsing.
#>

BeforeAll {
    $sourcePath = Join-Path (Split-Path -Parent $PSScriptRoot) 'autopilot-express.ps1'
    $tokens = $null
    $parseErrors = $null
    $sourceAst = [System.Management.Automation.Language.Parser]::ParseFile($sourcePath, [ref]$tokens, [ref]$parseErrors)
    if ($parseErrors.Count) { throw ($parseErrors.Message -join '; ') }
    foreach ($functionName in @('Get-GraphTransportFailure', 'Get-GraphOperationFailureMessage', 'New-OperationResult', 'Get-UserLocalPart', 'Test-DirectoryUserMatchesConfiguredPrefixes', 'Get-DirectoryUserEligibilityMessage', 'ConvertTo-DirectoryUserRecord', 'Get-LiveManagedDevicePrimaryUsers', 'Test-ManagedDevicePrimaryUserMatch', 'Get-GraphVerificationPolicy', 'Wait-PrimaryUserAssignmentVerification', 'Invoke-LivePrimaryUserAssignment', 'Invoke-StepAssignFinalPrimaryUser', 'Get-RegularTechnicianUsername', 'Select-TechnicianDirectoryUser', 'Invoke-StepAssignTechnicianPrimaryUser')) {
        $definition = $sourceAst.Find({ param($node) $node -is [System.Management.Automation.Language.FunctionDefinitionAst] -and $node.Name -eq $functionName }, $true)
        if ($null -eq $definition) { throw ('Missing function: {0}' -f $functionName) }
        Set-Item -Path ('Function:{0}' -f $definition.Name) -Value $definition.Body.GetScriptBlock()
    }
    function Get-ConfiguredTechnicianPrefixes { return @('C', 'E') }
    function Select-DirectoryUser { throw 'Unexpected directory selection.' }
    function Get-RecentUsers { throw 'Unexpected recent-user lookup.' }
    function Select-UserFromResults {
        param($Users, $Heading, [switch]$PreserveOrder)
        throw ('Unexpected recent selection: {0}/{1}/{2}' -f @($Users).Count, $Heading, $PreserveOrder)
    }
    function Search-LiveDirectoryUsers {
        param($SearchMode, $Query)
        throw ('Unexpected search: {0}/{1}' -f $SearchMode, $Query)
    }
    function Search-DemoDirectoryUsers {
        param($SearchMode, $Query)
        throw ('Unexpected Demo search: {0}/{1}' -f $SearchMode, $Query)
    }
    function Resolve-EligibleDirectoryUser {
        param($User)
        throw ('Unexpected revalidation: {0}' -f $User.UserPrincipalName)
    }
    function Add-RecentUser {
        param($User)
        throw ('Unexpected persistence for {0}.' -f $User.UserPrincipalName)
    }
    function Resolve-LiveAutopilotContext {
        param($Device)
        throw ('Unexpected context lookup for {0}.' -f $Device.Serial)
    }
    function Resolve-LiveDirectoryUserRecord {
        param($User)
        throw ('Unexpected directory lookup for {0}.' -f $User.UserPrincipalName)
    }
    function Get-LiveAutopilotDeviceById {
        param([string]$AutopilotDeviceId)
        throw ('Unexpected Autopilot lookup for {0}.' -f $AutopilotDeviceId)
    }
    function Invoke-GraphApiRequest {
        param([string]$Method, [string]$Uri, [hashtable]$Body)
        throw ('Unexpected Graph request: {0} {1}; body keys {2}.' -f $Method, $Uri, ($Body.Keys -join ','))
    }
    function Read-ValidatedInput {
        param([string]$Prompt, [string]$Default, [string]$Type, [string[]]$Choices)
        throw ('Unexpected prompt: {0}; default {1}; type {2}; choices {3}.' -f $Prompt, $Default, $Type, ($Choices -join ','))
    }
}

Describe 'Managed-device exclusive primary-user matching' {
    BeforeAll { $script:target = @{ Id = 'user-1'; UserPrincipalName = 'C1@example.invalid' } }

    It 'matches a single object ID even when the UPN has changed' {
        Test-ManagedDevicePrimaryUserMatch -Users @(@{ Id = 'user-1'; UserPrincipalName = 'E2@example.invalid' }) -User $script:target | Should -BeTrue
    }

    It 'rejects a conflicting object ID even when UPNs match' {
        Test-ManagedDevicePrimaryUserMatch -Users @(@{ Id = 'other'; UserPrincipalName = 'C1@example.invalid' }) -User $script:target | Should -BeFalse
    }

    It 'uses case-insensitive UPN fallback only when an ID is absent' {
        Test-ManagedDevicePrimaryUserMatch -Users @(@{ UserPrincipalName = 'c1@EXAMPLE.INVALID' }) -User $script:target | Should -BeTrue
    }

    It 'does not verify multiple users including the selected target' {
        Test-ManagedDevicePrimaryUserMatch -Users @($script:target, @{ Id = 'other' }) -User $script:target | Should -BeFalse
    }

    It 'rejects empty, null and missing-identity observations' {
        Test-ManagedDevicePrimaryUserMatch -Users @() -User $script:target | Should -BeFalse
        Test-ManagedDevicePrimaryUserMatch -Users $null -User $script:target | Should -BeFalse
        Test-ManagedDevicePrimaryUserMatch -Users @($null) -User $script:target | Should -BeFalse
        Test-ManagedDevicePrimaryUserMatch -Users @(@{}) -User $script:target | Should -BeFalse
    }
}

Describe 'Primary-user polling configuration' {
    BeforeEach { $script:Config = @{} }

    It 'defaults to five reads with three-second pauses' {
        $settings = Get-GraphVerificationPolicy
        $settings.MaxAttempts | Should -Be 5
        $settings.IntervalSeconds | Should -Be 3
    }

    It 'accepts existing configured limits including zero delay' {
        $script:Config = @{ MaxRetryAttempts = 2; RetryBackoffSeconds = 0 }
        $settings = Get-GraphVerificationPolicy
        $settings.MaxAttempts | Should -Be 2
        $settings.IntervalSeconds | Should -Be 0
    }

    It 'rejects invalid attempt counts without unsafe casts' {
        foreach ($invalid in @('', 0, -1, 21, '2.5', 'many', '999999999999')) {
            $script:Config.MaxRetryAttempts = $invalid
            { Get-GraphVerificationPolicy } | Should -Throw '*MaxRetryAttempts*'
        }
    }

    It 'rejects invalid pauses without unsafe casts' {
        foreach ($invalid in @('', -1, 61, '1.5', 'later', '999999999999')) {
            $script:Config.RetryBackoffSeconds = $invalid
            { Get-GraphVerificationPolicy } | Should -Throw '*RetryBackoffSeconds*'
        }
    }
}

Describe 'Bounded primary-user verification polling' {
    BeforeEach {
        $script:target = @{ Id = 'user-1'; UserPrincipalName = 'C1@example.invalid' }
        $script:pollReads = 0
        Mock Start-Sleep {}
        Mock Get-LiveAutopilotDeviceById { return @{ id = 'auto-1'; userPrincipalName = 'C1@example.invalid' } }
        Mock Get-LiveManagedDevicePrimaryUsers { return $script:target }
    }

    It 'stops on an immediate match without any pause' {
        $result = Wait-PrimaryUserAssignmentVerification -Surface Autopilot -DeviceId 'auto-1' -User $script:target -MaxAttempts 3 -IntervalSeconds 4
        $result.Confirmed | Should -BeTrue
        $result.Attempts | Should -Be 1
        Should -Invoke Get-LiveAutopilotDeviceById -Times 1 -Exactly
        Should -Invoke Start-Sleep -Times 0 -Exactly
    }

    It 'pauses only between unsuccessful reads and stops on a later match' {
        Mock Get-LiveAutopilotDeviceById {
            $script:pollReads++
            if ($script:pollReads -eq 1) { return @{ id = 'auto-1'; userPrincipalName = 'old@example.invalid' } }
            return @{ id = 'auto-1'; userPrincipalName = 'c1@EXAMPLE.INVALID' }
        }
        $result = Wait-PrimaryUserAssignmentVerification -Surface Autopilot -DeviceId 'auto-1' -User $script:target -MaxAttempts 3 -IntervalSeconds 4
        $result.Confirmed | Should -BeTrue
        $result.Attempts | Should -Be 2
        Should -Invoke Get-LiveAutopilotDeviceById -Times 2 -Exactly
        Should -Invoke Start-Sleep -Times 1 -Exactly -ParameterFilter { $Seconds -eq 4 }
    }

    It 'exhausts a bounded ambiguous read-back without a final pause' {
        Mock Get-LiveManagedDevicePrimaryUsers { return @($script:target, @{ Id = 'other'; UserPrincipalName = 'E2@example.invalid' }) }
        $result = Wait-PrimaryUserAssignmentVerification -Surface ManagedDevice -DeviceId 'managed-1' -User $script:target -MaxAttempts 3 -IntervalSeconds 4
        $result.Confirmed | Should -BeFalse
        $result.Attempts | Should -Be 3
        Should -Invoke Get-LiveManagedDevicePrimaryUsers -Times 3 -Exactly
        Should -Invoke Start-Sleep -Times 2 -Exactly -ParameterFilter { $Seconds -eq 4 }
    }

    It 'propagates request failures without retrying or pausing' {
        Mock Get-LiveAutopilotDeviceById { throw 'Permission denied' }
        { Wait-PrimaryUserAssignmentVerification -Surface Autopilot -DeviceId 'auto-1' -User $script:target -MaxAttempts 3 -IntervalSeconds 4 } |
        Should -Throw '*Permission denied*'
        Should -Invoke Get-LiveAutopilotDeviceById -Times 1 -Exactly
        Should -Invoke Start-Sleep -Times 0 -Exactly
    }

    It 'does not equate missing target and observed UPNs' {
        Mock Get-LiveAutopilotDeviceById { return @{ id = 'auto-1' } }
        $result = Wait-PrimaryUserAssignmentVerification -Surface Autopilot -DeviceId 'auto-1' -User @{} -MaxAttempts 1 -IntervalSeconds 0
        $result.Confirmed | Should -BeFalse
        Should -Invoke Start-Sleep -Times 0 -Exactly
    }
}

Describe 'Live assignment read-back' {
    BeforeEach {
        $script:Config = @{ MaxRetryAttempts = 3; RetryBackoffSeconds = 0 }
        Mock Start-Sleep {}
        $script:target = @{ Id = 'user-1'; DisplayName = 'Amy'; UserPrincipalName = 'C1@example.invalid' }
        $script:device = @{ Serial = 'SERIAL1'; AutopilotDeviceId = 'autopilot-1'; ManagedDeviceId = 'managed-1' }
        $script:readCount = 0
        Mock Resolve-LiveAutopilotContext {}
        Mock Invoke-GraphApiRequest {}
        Mock Get-LiveAutopilotDeviceById { return @{ id = 'autopilot-1'; userPrincipalName = 'C1@example.invalid' } }
        Mock Get-LiveManagedDevicePrimaryUsers { return $script:target }
    }

    It 'does not rewrite an already exclusive managed-device relationship' {
        $result = Invoke-LivePrimaryUserAssignment -Device $script:device -User $script:target
        $result.AutopilotAssigned | Should -BeTrue
        $result.ManagedDeviceConfirmed | Should -BeTrue
        Should -Invoke Invoke-GraphApiRequest -Times 0 -Exactly -ParameterFilter { $Uri -like '*managedDevices*' }
    }

    It 'verifies the relationship after posting the selected object reference' {
        Mock Get-LiveManagedDevicePrimaryUsers {
            $script:readCount++
            if ($script:readCount -gt 1) { return $script:target }
        }
        $result = Invoke-LivePrimaryUserAssignment -Device $script:device -User $script:target
        $result.ManagedDeviceConfirmed | Should -BeTrue
        Should -Invoke Invoke-GraphApiRequest -Times 1 -Exactly -ParameterFilter {
            $Method -eq 'POST' -and $Uri -like '*managedDevices*' -and $Body.'@odata.id' -eq 'https://graph.microsoft.com/v1.0/users/user-1'
        }
    }

    It 'does not verify or rewrite an ambiguous relationship already containing the target' {
        Mock Get-LiveManagedDevicePrimaryUsers { return @($script:target, @{ Id = 'other'; UserPrincipalName = 'E2@example.invalid' }) }
        $result = Invoke-LivePrimaryUserAssignment -Device $script:device -User $script:target
        $result.ManagedDeviceConfirmed | Should -BeFalse
        $result.ManagedDeviceAssigned | Should -BeTrue
        Should -Invoke Invoke-GraphApiRequest -Times 0 -Exactly -ParameterFilter { $Uri -like '*managedDevices*' }
    }

    It 'retains submission evidence when Autopilot read-back has not matched' {
        $script:device.ManagedDeviceId = ''
        Mock Get-LiveAutopilotDeviceById { return @{ id = 'autopilot-1'; userPrincipalName = 'old@example.invalid' } }
        $result = Invoke-LivePrimaryUserAssignment -Device $script:device -User $script:target
        $result.AutopilotSubmitted | Should -BeTrue
        $result.AutopilotAssigned | Should -BeFalse
        $result.AnyAssignmentApplied | Should -BeTrue
    }

    It 'keeps a managed-device write unverified when its read-back is empty' {
        Mock Get-LiveManagedDevicePrimaryUsers {}
        $result = Invoke-LivePrimaryUserAssignment -Device $script:device -User $script:target
        $result.ManagedDeviceAssigned | Should -BeTrue
        $result.ManagedDeviceConfirmed | Should -BeFalse
    }

    It 'records read-back failures without hiding submission evidence' {
        Mock Get-LiveAutopilotDeviceById { throw 'Read denied' }
        $result = Invoke-LivePrimaryUserAssignment -Device $script:device -User $script:target
        $result.AutopilotSubmitted | Should -BeTrue
        $result.Errors -join ' ' | Should -Match 'Read denied'
    }

    It 'polls delayed Autopilot propagation without repeating the write' {
        Mock Get-LiveAutopilotDeviceById {
            $script:readCount++
            if ($script:readCount -eq 1) { return @{ id = 'autopilot-1'; userPrincipalName = 'old@example.invalid' } }
            return @{ id = 'autopilot-1'; userPrincipalName = 'C1@example.invalid' }
        }
        $result = Invoke-LivePrimaryUserAssignment -Device $script:device -User $script:target
        $result.AutopilotAssigned | Should -BeTrue
        Should -Invoke Get-LiveAutopilotDeviceById -Times 2 -Exactly
        Should -Invoke Invoke-GraphApiRequest -Times 1 -Exactly -ParameterFilter { $Method -eq 'POST' -and $Uri -like '*assignUserToDevice' }
    }

    It 'polls delayed managed-user propagation after a single relationship write' {
        Mock Get-LiveManagedDevicePrimaryUsers {
            $script:readCount++
            if ($script:readCount -ge 3) { return $script:target }
        }
        $result = Invoke-LivePrimaryUserAssignment -Device $script:device -User $script:target
        $result.ManagedDeviceConfirmed | Should -BeTrue
        Should -Invoke Get-LiveManagedDevicePrimaryUsers -Times 3 -Exactly
        Should -Invoke Invoke-GraphApiRequest -Times 1 -Exactly -ParameterFilter { $Method -eq 'POST' -and $Uri -like '*managedDevices*' }
        $result.Notes -join ' ' | Should -Match 'Managed-device verification performed 2 read-back attempts'
    }

    It 'rejects invalid polling settings before context lookup or mutations' {
        $script:Config.MaxRetryAttempts = 0
        { Invoke-LivePrimaryUserAssignment -Device $script:device -User $script:target } | Should -Throw '*MaxRetryAttempts*'
        Should -Invoke Resolve-LiveAutopilotContext -Times 0 -Exactly
        Should -Invoke Invoke-GraphApiRequest -Times 0 -Exactly
    }
}

Describe 'Managed-device users reader completeness' {
    It 'rejects malformed responses' {
        Mock Invoke-GraphApiRequest { return @{} }
        { Get-LiveManagedDevicePrimaryUsers -ManagedDeviceId 'managed-1' } | Should -Throw '*invalid users collection*'
    }

    It 'rejects partial users pages rather than claiming exclusive assignment' {
        Mock Invoke-GraphApiRequest { return @{ value = @(@{ id = 'user-1'; userPrincipalName = 'C1@example.invalid' }); '@odata.nextLink' = 'next-page' } }
        { Get-LiveManagedDevicePrimaryUsers -ManagedDeviceId 'managed-1' } | Should -Throw '*incomplete*'
    }

    It 'accepts a complete empty users collection' {
        Mock Invoke-GraphApiRequest { return @{ value = @() } }
        @(Get-LiveManagedDevicePrimaryUsers -ManagedDeviceId 'managed-1').Count | Should -Be 0
    }

    It 'does not silently discard malformed identities from a multi-user response' {
        Mock Invoke-GraphApiRequest { return @{ value = @(
                    @{ id = 'user-1'; userPrincipalName = 'C1@example.invalid' }
                    @{ id = 'other' }
                )
            } }
        { Get-LiveManagedDevicePrimaryUsers -ManagedDeviceId 'managed-1' } | Should -Throw '*invalid identity*'
    }
}

Describe 'Final primary-user completion evidence' {
    BeforeEach {
        $script:Runtime = @{ IsDemoMode = $false }
        $script:selectedUser = @{ Id = 'user-1'; DisplayName = 'Amy'; UserPrincipalName = 'C1@example.invalid' }
        $script:device = @{ Serial = 'SERIAL1'; FinalPrimaryUserId = ''; FinalPrimaryUserPrincipalName = ''; FinalPrimaryUserDisplayName = '' }
        $script:step = @{ ActionName = 'AssignFinalPrimaryUser' }
        $script:assignment = @{
            AutopilotAssigned = $true; ManagedDeviceAssigned = $true; ManagedDeviceConfirmed = $true
            AnyAssignmentApplied = $true; Notes = @('Assignment evidence'); Errors = @()
        }
        Mock Select-DirectoryUser { return $script:selectedUser }
        Mock Add-RecentUser {}
        Mock Invoke-LivePrimaryUserAssignment { return $script:assignment }
        Mock Read-ValidatedInput { throw 'Unexpected manual confirmation.' }
    }

    It 'verifies only when both read-back surfaces match' {
        $result = Invoke-StepAssignFinalPrimaryUser -Device $script:device -StepDefinition $script:step
        $result.Success | Should -BeTrue
        $result.CompletionState | Should -Be 'Verified'
        $result.Data.ManagedDeviceConfirmed | Should -BeTrue
        Should -Invoke Read-ValidatedInput -Times 0 -Exactly
    }

    It 'does not complete an Autopilot-only assignment' {
        $script:assignment.ManagedDeviceAssigned = $false
        $script:assignment.ManagedDeviceConfirmed = $false
        $result = Invoke-StepAssignFinalPrimaryUser -Device $script:device -StepDefinition $script:step
        $result.Success | Should -BeFalse
        $result.CompletionState | Should -Be 'Submitted'
    }

    It 'does not complete a managed-device-only assignment' {
        $script:assignment.AutopilotAssigned = $false
        $result = Invoke-StepAssignFinalPrimaryUser -Device $script:device -StepDefinition $script:step
        $result.Success | Should -BeFalse
        $result.CompletionState | Should -Be 'Submitted'
    }

    It 'labels manual confirmation as technician evidence rather than Graph verification' {
        $script:assignment.ManagedDeviceConfirmed = $false
        Mock Read-ValidatedInput { return 'y' }
        $result = Invoke-StepAssignFinalPrimaryUser -Device $script:device -StepDefinition $script:step
        $result.Success | Should -BeTrue
        $result.CompletionState | Should -Be 'TechnicianConfirmed'
        $result.Data.ManagedDeviceConfirmed | Should -BeFalse
    }

    It 'keeps an unconfirmed submission incomplete' {
        $script:assignment.ManagedDeviceConfirmed = $false
        Mock Read-ValidatedInput { return 'N' }
        $result = Invoke-StepAssignFinalPrimaryUser -Device $script:device -StepDefinition $script:step
        $result.Success | Should -BeFalse
        $result.CompletionState | Should -Be 'Submitted'
    }

    It 'blocks missing targets without claiming a failed mutation' {
        $script:assignment.AnyAssignmentApplied = $false
        $script:assignment.AutopilotAssigned = $false
        $script:assignment.ManagedDeviceAssigned = $false
        $script:assignment.ManagedDeviceConfirmed = $false
        $result = Invoke-StepAssignFinalPrimaryUser -Device $script:device -StepDefinition $script:step
        $result.CompletionState | Should -Be 'Blocked'
        $result.Success | Should -BeFalse
    }

    It 'does not let partial success hide a Graph failure' {
        $script:assignment.Errors = @('Graph permission denied')
        $result = Invoke-StepAssignFinalPrimaryUser -Device $script:device -StepDefinition $script:step
        $result.CompletionState | Should -Be 'Failed'
        $result.Success | Should -BeFalse
        $result.Notes | Should -Match 'Graph permission denied'
    }

    It 'makes no assignment or persistence call after selection cancellation' {
        Mock Select-DirectoryUser { return $null }
        $result = Invoke-StepAssignFinalPrimaryUser -Device $script:device -StepDefinition $script:step
        $result.Success | Should -BeFalse
        Should -Invoke Invoke-LivePrimaryUserAssignment -Times 0 -Exactly
        Should -Invoke Add-RecentUser -Times 0 -Exactly
    }

    It 'keeps Demo assignments simulated and isolated from Graph' {
        $script:Runtime.IsDemoMode = $true
        $result = Invoke-StepAssignFinalPrimaryUser -Device $script:device -StepDefinition $script:step
        $result.CompletionState | Should -Be 'Simulated'
        $result.Success | Should -BeTrue
        Should -Invoke Invoke-LivePrimaryUserAssignment -Times 0 -Exactly
    }
}

Describe 'Technician primary-user completion evidence' {
    BeforeEach {
        $script:Runtime = @{ IsDemoMode = $false }
        $script:GraphSession = @{ Account = 'C1@example.invalid'; UserId = 'user-1'; DisplayName = 'Amy' }
        $script:device = @{ Serial = 'SERIAL1'; TechnicianUserPrincipalName = ''; Steps = @{} }
        $script:step = @{ Id = 'G'; ActionName = 'AssignTechnicianPrimaryUser' }
        $script:assignment = @{
            AutopilotAssigned = $true; ManagedDeviceAssigned = $true; ManagedDeviceConfirmed = $true
            AnyAssignmentApplied = $true; Notes = @(); Errors = @()
        }
        Mock Invoke-LivePrimaryUserAssignment { return $script:assignment }
        Mock Select-TechnicianDirectoryUser { return @{ Id = 'regular-user'; UserPrincipalName = 'C1@example.invalid'; AccountEnabled = $true } }
        Mock Read-ValidatedInput { throw 'Unexpected manual confirmation.' }
    }

    It 'requires both surfaces before reporting Graph verification' {
        $result = Invoke-StepAssignTechnicianPrimaryUser -Device $script:device -StepDefinition $script:step
        $result.Success | Should -BeTrue
        $result.CompletionState | Should -Be 'Verified'
    }

    It 'blocks a different target after retained <Flag> evidence without changing intent' -ForEach @(
        @{ Flag = 'AutopilotAttempted' }
        @{ Flag = 'ManagedDeviceAttempted' }
        @{ Flag = 'AutopilotSubmitted' }
        @{ Flag = 'AutopilotAssigned' }
        @{ Flag = 'ManagedDeviceAssigned' }
    ) {
        $priorData = @{ Technician = 'E2@example.invalid'; UserId = 'original-user' }
        $priorData[$Flag] = $true
        $script:device.TechnicianUserPrincipalName = $priorData.Technician
        $script:device.Steps.G = @{ CompletionState = 'Failed'; Data = $priorData }
        $result = Invoke-StepAssignTechnicianPrimaryUser -Device $script:device -StepDefinition $script:step
        $result.CompletionState | Should -Be 'Blocked'
        $result.Data.Technician | Should -Be 'E2@example.invalid'
        $result.Data[$Flag] | Should -BeTrue
        $script:device.TechnicianUserPrincipalName | Should -Be 'E2@example.invalid'
        Should -Invoke Invoke-LivePrimaryUserAssignment -Times 0 -Exactly
    }

    It 'retains unresolved target evidence when technician selection is cancelled' {
        $script:device.Steps.G = @{ CompletionState = 'Submitted'; Data = @{ Technician = 'E2@example.invalid'; AutopilotSubmitted = $true } }
        Mock Select-TechnicianDirectoryUser { return $null }
        $result = Invoke-StepAssignTechnicianPrimaryUser -Device $script:device -StepDefinition $script:step
        $result.Data.Technician | Should -Be 'E2@example.invalid'
        $result.Data.AutopilotSubmitted | Should -BeTrue
        Should -Invoke Invoke-LivePrimaryUserAssignment -Times 0 -Exactly
    }

    It 'retains the actual selected object and submission flags on a partial failure' {
        $script:assignment.AutopilotSubmitted = $true
        $script:assignment.AutopilotAttempted = $true
        $script:assignment.Errors = @('Managed-device request failed')
        $result = Invoke-StepAssignTechnicianPrimaryUser -Device $script:device -StepDefinition $script:step
        $result.CompletionState | Should -Be 'Failed'
        $result.Data.UserId | Should -Be 'regular-user'
        $result.Data.AutopilotSubmitted | Should -BeTrue
        $result.Data.AutopilotAttempted | Should -BeTrue
    }

    It 'does not complete an Autopilot-only technician assignment' {
        $script:assignment.ManagedDeviceAssigned = $false
        $script:assignment.ManagedDeviceConfirmed = $false
        $result = Invoke-StepAssignTechnicianPrimaryUser -Device $script:device -StepDefinition $script:step
        $result.Success | Should -BeFalse
        $result.CompletionState | Should -Be 'Submitted'
    }

    It 'keeps manual technician confirmation distinct from Graph evidence' {
        $script:assignment.ManagedDeviceConfirmed = $false
        Mock Read-ValidatedInput { return 'Y' }
        $result = Invoke-StepAssignTechnicianPrimaryUser -Device $script:device -StepDefinition $script:step
        $result.Success | Should -BeTrue
        $result.CompletionState | Should -Be 'TechnicianConfirmed'
        $result.Data.ManagedDeviceConfirmed | Should -BeFalse
    }

    It 'preserves Demo simulation without invoking the Live assignment handler' {
        $script:Runtime.IsDemoMode = $true
        $result = Invoke-StepAssignTechnicianPrimaryUser -Device $script:device -StepDefinition $script:step
        $result.CompletionState | Should -Be 'Simulated'
        Should -Invoke Invoke-LivePrimaryUserAssignment -Times 0 -Exactly
    }

    It 'does not assign when technician selection is cancelled' {
        Mock Select-TechnicianDirectoryUser { return $null }
        $result = Invoke-StepAssignTechnicianPrimaryUser -Device $script:device -StepDefinition $script:step
        $result.CompletionState | Should -Be 'Blocked'
        Should -Invoke Invoke-LivePrimaryUserAssignment -Times 0 -Exactly
    }

    It 'passes the regular directory ID rather than the Graph login ID' {
        Invoke-StepAssignTechnicianPrimaryUser -Device $script:device -StepDefinition $script:step | Out-Null
        Should -Invoke Invoke-LivePrimaryUserAssignment -Times 1 -Exactly -ParameterFilter { $User.Id -eq 'regular-user' }
    }
}

Describe 'Windows regular technician account resolution' {
    BeforeEach {
        $script:Runtime = @{ IsDemoMode = $false }
        Mock Write-Host {}
        Mock Get-RegularTechnicianUsername { return 'cmiharr' }
        Mock Search-LiveDirectoryUsers { return @(@{ Id = 'regular'; DisplayName = 'Technician'; UserPrincipalName = 'cmiharr@example.invalid'; AccountEnabled = $true }) }
        Mock Resolve-EligibleDirectoryUser { return $User }
        Mock Read-ValidatedInput { return 'Y' }
        Mock Add-RecentUser {}
    }

    It 'requires explicit Y with default N before returning the directory account' {
        $user = Select-TechnicianDirectoryUser
        $user.Id | Should -Be 'regular'
        Should -Invoke Read-ValidatedInput -Times 1 -Exactly -ParameterFilter { $Default -eq 'N' -and $Type -eq 'Choice' }
    }

    It 'loops back to username entry after No and permits cancellation' {
        Mock Read-ValidatedInput { if ($Type -eq 'Choice') { return 'N' }; return '0' }
        Select-TechnicianDirectoryUser | Should -BeNullOrEmpty
        Should -Invoke Read-ValidatedInput -Times 1 -Exactly -ParameterFilter { $Default -eq '0' }
        Should -Invoke Add-RecentUser -Times 0 -Exactly
    }

    It 'accepts an exact Windows username when the UPN local part differs' {
        Mock Search-LiveDirectoryUsers { return @(@{ Id = 'regular'; DisplayName = 'Technician'; OnPremisesSamAccountName = 'CMIHARR'; UserPrincipalName = 'michael.harris@example.invalid'; AccountEnabled = $true }) }
        (Select-TechnicianDirectoryUser).Id | Should -Be 'regular'
        Should -Invoke Search-LiveDirectoryUsers -Times 1 -Exactly -ParameterFilter { $Query -eq 'cmiharr' }
    }

    It 'remembers the explicitly confirmed technician for later selection' {
        (Select-TechnicianDirectoryUser).Id | Should -Be 'regular'
        Should -Invoke Add-RecentUser -Times 1 -Exactly -ParameterFilter { $User.Id -eq 'regular' }
    }

    It 'offers recent selections in saved order and revalidates the chosen identity' {
        $script:technicianConfirmations = 0
        Mock Get-RecentUsers { return , @(@{ Id = 'last'; UserPrincipalName = 'c.last@example.invalid' }) }
        Mock Select-UserFromResults { return $Users[0] }
        Mock Read-ValidatedInput { $script:technicianConfirmations++; if ($script:technicianConfirmations -eq 1) { return 'r' }; return 'y' }
        (Select-TechnicianDirectoryUser).Id | Should -Be 'last'
        Should -Invoke Select-UserFromResults -Times 1 -Exactly -ParameterFilter { $PreserveOrder }
        Should -Invoke Resolve-EligibleDirectoryUser -Times 1 -Exactly -ParameterFilter { $User.Id -eq 'last' }
        Should -Invoke Add-RecentUser -Times 1 -Exactly -ParameterFilter { $User.Id -eq 'last' }
    }

    It 'cancels from the account preview without recording or assigning a user' {
        Mock Read-ValidatedInput { return '0' }
        Select-TechnicianDirectoryUser | Should -BeNullOrEmpty
        Should -Invoke Add-RecentUser -Times 0 -Exactly
    }
}

Describe 'Windows username mapping rules' {
    It 'maps <Login> to <Expected> without inventing a domain' -TestCases @(
        @{ Login = 'CaCmiharr'; Expected = 'cmiharr' },
        @{ Login = 'CA123456'; Expected = 'e123456' },
        @{ Login = 'Cmiharr'; Expected = 'cmiharr' },
        @{ Login = 'E123456'; Expected = 'e123456' },
        @{ Login = 'caabc123'; Expected = '' },
        @{ Login = 'administrator'; Expected = '' },
        @{ Login = ''; Expected = '' }
    ) {
        param($Login, $Expected)
        Get-RegularTechnicianUsername -WindowsUsername $Login | Should -Be $Expected
    }
}