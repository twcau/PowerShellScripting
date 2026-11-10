<#
.SYNOPSIS
    Checks physical guidance, evidence and manifest prerequisite gates.
.DESCRIPTION
    Extracts the real handlers, dispatcher, eligibility and result writer without
    starting the CLI. Prompts are mocked; no physical or tenant actions occur.
#>
BeforeAll {
    $sourcePath = Join-Path (Split-Path -Parent $PSScriptRoot) 'autopilot-express.ps1'
    $tokens = $null
    $parseErrors = $null
    $sourceAst = [System.Management.Automation.Language.Parser]::ParseFile($sourcePath, [ref]$tokens, [ref]$parseErrors)
    if ($parseErrors.Count) { throw ($parseErrors.Message -join '; ') }
    foreach ($functionName in @('Get-ManifestActionStepId', 'Get-LiveTenantBinding', 'New-OperationResult', 'ConvertTo-NormalisedValue', 'Invoke-StepConfirmPhysicalMilestone', 'Invoke-StepClearUserlessEnrollmentStatus', 'Invoke-StepConfirmRecoveryReadiness', 'ConvertTo-RecordDate', 'ConvertTo-PersistedDate', 'Get-ConfirmedApplicationBaseline', 'Test-ApplicationNoFailureEvidence', 'Enter-DeviceRecoveryMode', 'Invoke-AutopilotManifestStep', 'Get-AffectedWorkflowStepId', 'Write-ManifestStepResult', 'Test-ManifestStepAttempted', 'Test-ManifestStepCompleted', 'Test-CompletionStateComplete', 'Get-ManifestStepPrerequisiteIds', 'Test-ManifestStepEligibility', 'Get-EligibleManifestSteps', 'Get-DispatchBlockingManifestSteps', 'Test-DeviceReadyForDispatch', 'Test-ManifestDependencyGraph', 'Resolve-DeviceSelection', 'Select-DeviceFromRecords', 'ConvertTo-OptionalInteger', 'Update-DeviceStatus')) {
        $definition = $sourceAst.Find({ param($node) $node -is [System.Management.Automation.Language.FunctionDefinitionAst] -and $node.Name -eq $functionName }, $true)
        if ($null -eq $definition) { throw ('Missing function: {0}' -f $functionName) }
        Set-Item -Path ('Function:{0}' -f $definition.Name) -Value $definition.Body.GetScriptBlock()
    }
    foreach ($functionName in @('Get-GraphTransportFailure', 'Get-GraphOperationFailureMessage')) {
        $definition = $sourceAst.Find({ param($node) $node -is [System.Management.Automation.Language.FunctionDefinitionAst] -and $node.Name -eq $functionName }, $true)
        Set-Item -Path ('Function:{0}' -f $definition.Name) -Value $definition.Body.GetScriptBlock()
    }
    foreach ($functionName in @('Invoke-DeviceWorkflowPlan', 'New-EmptyDeviceRecord', 'Undo-LatestTechnicianConfirmation')) {
        $definition = $sourceAst.Find({ param($node) $node -is [System.Management.Automation.Language.FunctionDefinitionAst] -and $node.Name -eq $functionName }, $true)
        if ($null -eq $definition) { throw ('Missing function: {0}' -f $functionName) }
        Set-Item -Path ('Function:{0}' -f $definition.Name) -Value $definition.Body.GetScriptBlock()
    }
    function Get-ManifestStepDefinition { param($StepId) throw ('Unexpected manifest lookup: {0}' -f $StepId) }
    function Read-ValidatedInput { param($Prompt, $Default, $Type, $Choices) throw ('Unexpected prompt: {0}, {1}, {2}, {3}' -f $Prompt, $Default, $Type, ($Choices -join ',')) }
    foreach ($functionName in @('Show-ScriptScreen', 'Show-ReturnToMainMenu', 'Get-NavigationMenuTitle')) {
        $definition = $sourceAst.Find({ param($node) $node -is [System.Management.Automation.Language.FunctionDefinitionAst] -and $node.Name -eq $functionName }, $true)
        Set-Item -Path ('Function:{0}' -f $definition.Name) -Value $definition.Body.GetScriptBlock()
    }
    function Show-ChecklistHandoffGuide { param($Device) if (-not $Device.Serial) { throw 'Guide requires a device serial' } }
    function Resolve-LiveManagedDeviceBySerial { param($Serial) throw ('Unexpected lookup: {0}' -f $Serial) }
    function Resolve-LiveAutopilotContext { param($Device) throw ('Unexpected context lookup: {0}' -f $Device.Serial) }
    function Invoke-GraphApiRequest { param($Method, $Uri) throw ('Unexpected Graph request: {0} {1}' -f $Method, $Uri) }
    function Write-AutopilotExpressLog { param($Message, $Level) throw ('Unexpected log: {0}: {1}' -f $Level, $Message) }
    function Write-UserDeviceRecords { param($Records) throw ('Unexpected save of {0} records' -f @($Records).Count) }
    function Get-NextStepId { param($Device) if ($Device.Serial) { return 'I' } }
    function Get-EnabledManifestSteps { return $script:manifestSteps }
    function Get-MgContext { throw 'Unexpected Graph context lookup.' }
    $script:fixtureTenantId = '11111111-2222-3333-4444-555555555555'
    $manifestPath = Join-Path (Split-Path -Parent $PSScriptRoot) 'autopilot-express.manifest.json'
    $manifest = Get-Content -LiteralPath $manifestPath -Raw | ConvertFrom-Json
    $script:manifestSteps = @($manifest.steps | ForEach-Object {
            @{ Id = $_.id; ActionName = $_.actionName; DisplayName = $_.displayName; PrerequisiteStepIds = @($_.prerequisiteStepIds); ActivationRequirement = if ($_.activationRequirement) { $_.activationRequirement } else { 'None' } }
        })
}

Describe 'Evidence-preserving technician confirmation correction' {
    BeforeEach {
        $script:Runtime = @{ IsDemoMode = $false; ModeDisplayName = 'Live' }
        $script:RuntimeConfig = @{ graph = @{ expectedTenantId = $script:fixtureTenantId } }
        $script:GraphSession = @{ Connected = $true; IsSimulated = $false; TenantId = $script:fixtureTenantId }
        $script:device = New-EmptyDeviceRecord
        $script:device.Serial = 'UNDO-01'
        $script:device.RecordId = 'undo-record'
        $script:device.TenantId = $script:fixtureTenantId
        $script:device.Steps.E = @{ CompletionState = 'TechnicianConfirmed'; ActionName = 'ConfirmImagingAndOobe'; Timestamp = Get-Date; Data = @{ Observation = 'Original confirmation' } }
        $script:records = @{ Value = @($script:device) }
        Mock Get-MgContext { return @{ TenantId = $script:fixtureTenantId } }
        Mock Write-Host {}
        Mock Read-ValidatedInput { return 'Y' }
        Mock Write-UserDeviceRecords { $script:device.Steps.E.CompletionState | Should -Be TechnicianConfirmed }
    }
    It 'saves the correction before changing caller state and retains original evidence' {
        (Undo-LatestTechnicianConfirmation -Records $script:records -Device $script:device).Changed | Should -BeTrue
        $script:device.Steps.E.CompletionState | Should -Be Failed
        $script:device.AttemptHistory.Count | Should -Be 2
        $script:device.AttemptHistory[0].Result.Data.Observation | Should -Be 'Original confirmation'
        $script:device.AttemptHistory[1].Result.Data.Correction | Should -BeTrue
        Should -Invoke Read-ValidatedInput -Times 1 -Exactly -ParameterFilter { $Default -eq 'N' }
        Should -Invoke Write-UserDeviceRecords -Times 1 -Exactly
    }
    It 'cancels without saving or altering evidence' {
        Mock Read-ValidatedInput { return 'N' }
        $before = $script:device | ConvertTo-Json -Depth 30
        (Undo-LatestTechnicianConfirmation -Records $script:records -Device $script:device).Changed | Should -BeFalse
        ($script:device | ConvertTo-Json -Depth 30) | Should -BeExactly $before
        Should -Invoke Write-UserDeviceRecords -Times 0 -Exactly
    }
    It 'leaves caller state intact after a failed save' {
        Mock Write-UserDeviceRecords { throw 'Synthetic correction storage failure' }
        $before = $script:device | ConvertTo-Json -Depth 30
        { Undo-LatestTechnicianConfirmation -Records $script:records -Device $script:device } | Should -Throw '*storage failure*'
        ($script:device | ConvertTo-Json -Depth 30) | Should -BeExactly $before
    }
    It 'refuses to cross a dependent remote submission without prompting or saving' {
        $script:device.Steps.I = @{ CompletionState = 'Submitted'; Data = @{ Submitted = $true } }
        (Undo-LatestTechnicianConfirmation -Records $script:records -Device $script:device).Changed | Should -BeFalse
        Should -Invoke Read-ValidatedInput -Times 0 -Exactly
        Should -Invoke Write-UserDeviceRecords -Times 0 -Exactly
    }
    It 'shows and invalidates the dependent no-failure outcome when withdrawing the baseline' {
        $baselineTime = (Get-Date).AddSeconds(1)
        $script:device.Steps.L = @{ CompletionState = 'TechnicianConfirmed'; ActionName = 'ConfirmApplicationBaseline'; Success = $true; IsSimulated = $false; Timestamp = $baselineTime; Data = @{} }
        $script:device.Steps.M = @{ CompletionState = 'TechnicianConfirmed'; ActionName = 'RetryFailedApplications'; Success = $true; IsSimulated = $false; Timestamp = $baselineTime.AddSeconds(1); Data = @{ NoApplicationFailures = $true; SyncRequestedForOutcome = $false; BaselineStepId = 'L'; BaselineConfirmedAt = $baselineTime.ToString('o') } }
        Test-ManifestStepCompleted -Device $script:device -StepId 'M' | Should -BeTrue
        (Undo-LatestTechnicianConfirmation -Records $script:records -Device $script:device).Changed | Should -BeTrue
        $script:device.Steps.L.CompletionState | Should -Be 'Failed'
        $script:device.Steps.M.CompletionState | Should -Be 'Blocked'
        $script:device.Steps.M.InvalidatedBy | Should -Be 'L'
        Should -Invoke Write-Host -Times 1 -Exactly -ParameterFilter { [string]$Object -match 'dependent evidence will require rechecking:.*M' }
    }

    It 'refuses baseline withdrawal when a later dependent sync was submitted' {
        $baselineTime = (Get-Date).AddSeconds(1)
        $script:device.Steps.L = @{ CompletionState = 'TechnicianConfirmed'; ActionName = 'ConfirmApplicationBaseline'; Success = $true; IsSimulated = $false; Timestamp = $baselineTime; Data = @{} }
        $script:device.Steps.M = @{ CompletionState = 'TechnicianConfirmed'; ActionName = 'RetryFailedApplications'; Success = $true; IsSimulated = $false; Timestamp = $baselineTime.AddSeconds(2); Data = @{ NoApplicationFailures = $true; SyncRequestedForOutcome = $false; BaselineStepId = 'L'; BaselineConfirmedAt = $baselineTime.ToString('o') } }
        $script:device.AttemptHistory = @(@{ StepId = 'M'; Timestamp = $baselineTime.AddSeconds(1).ToString('o'); Result = @{ CompletionState = 'Submitted'; Data = @{} } })
        (Undo-LatestTechnicianConfirmation -Records $script:records -Device $script:device).Changed | Should -BeFalse
        Should -Invoke Read-ValidatedInput -Times 0 -Exactly
        Should -Invoke Write-UserDeviceRecords -Times 0 -Exactly
    }

    It 'rejects a no-failure result bound to a different baseline time before recording it' {
        $baselineTime = Get-Date
        $script:device.Steps.L = @{ CompletionState = 'TechnicianConfirmed'; ActionName = 'ConfirmApplicationBaseline'; Success = $true; IsSimulated = $false; Timestamp = $baselineTime; Data = @{} }
        $step = $script:manifestSteps | Where-Object ActionName -eq 'RetryFailedApplications'
        $result = New-OperationResult -ActionName $step.ActionName -Success $true -CompletionState TechnicianConfirmed -Data @{ NoApplicationFailures = $true; SyncRequestedForOutcome = $false; BaselineStepId = 'L'; BaselineConfirmedAt = $baselineTime.AddMinutes(-1).ToString('o') }
        { Write-ManifestStepResult -Device $script:device -StepDefinition $step -Result $result } | Should -Throw '*does not match the current confirmed application baseline*'
        $script:device.AttemptHistory.Count | Should -Be 0
        $script:device.Steps.Contains('M') | Should -BeFalse
    }

    It 'does not treat a no-failure result as complete after its baseline changes' {
        $baselineTime = Get-Date
        $script:device.Steps.L = @{ CompletionState = 'TechnicianConfirmed'; ActionName = 'ConfirmApplicationBaseline'; Success = $true; IsSimulated = $false; Timestamp = $baselineTime; Data = @{} }
        $script:device.Steps.M = @{ CompletionState = 'TechnicianConfirmed'; ActionName = 'RetryFailedApplications'; Success = $true; IsSimulated = $false; Timestamp = $baselineTime; Data = @{ NoApplicationFailures = $true; SyncRequestedForOutcome = $false; BaselineStepId = 'L'; BaselineConfirmedAt = $baselineTime.ToString('o') } }
        Test-ManifestStepCompleted -Device $script:device -StepId 'M' | Should -BeTrue
        $script:device.Steps.L.Timestamp = $baselineTime.AddSeconds(1)
        Test-ManifestStepCompleted -Device $script:device -StepId 'M' | Should -BeFalse
    }

    It 'invalidates the prior no-failure outcome when the baseline is reconfirmed' {
        $baselineTime = Get-Date
        $script:device.Steps.L = @{ CompletionState = 'TechnicianConfirmed'; ActionName = 'ConfirmApplicationBaseline'; Success = $true; IsSimulated = $false; Timestamp = $baselineTime; Data = @{} }
        $script:device.Steps.M = @{ CompletionState = 'TechnicianConfirmed'; ActionName = 'RetryFailedApplications'; Success = $true; IsSimulated = $false; Timestamp = $baselineTime; Data = @{ NoApplicationFailures = $true; SyncRequestedForOutcome = $false; BaselineStepId = 'L'; BaselineConfirmedAt = $baselineTime.ToString('o') } }
        $step = $script:manifestSteps | Where-Object ActionName -eq 'ConfirmApplicationBaseline'
        $result = New-OperationResult -ActionName $step.ActionName -Success $true -CompletionState TechnicianConfirmed -Data @{}
        Write-ManifestStepResult -Device $script:device -StepDefinition $step -Result $result
        $script:device.Steps.M.CompletionState | Should -Be 'Blocked'
        $script:device.Steps.M.InvalidatedBy | Should -Be 'L'
        Test-ManifestStepCompleted -Device $script:device -StepId 'M' | Should -BeFalse
    }

    It 'rejects inconsistent no-failure evidence at the write and completion boundaries' {
        $baselineTime = Get-Date
        $script:device.Steps.L = @{ CompletionState = 'TechnicianConfirmed'; ActionName = 'ConfirmApplicationBaseline'; Success = $true; IsSimulated = $false; Timestamp = $baselineTime; Data = @{} }
        $step = $script:manifestSteps | Where-Object ActionName -eq 'RetryFailedApplications'
        $result = New-OperationResult -ActionName $step.ActionName -Success $true -CompletionState TechnicianConfirmed -Data @{ NoApplicationFailures = $true; SyncRequestedForOutcome = $true; BaselineStepId = 'L'; BaselineConfirmedAt = $baselineTime.ToString('o') }
        { Write-ManifestStepResult -Device $script:device -StepDefinition $step -Result $result } | Should -Throw '*does not match the current confirmed application baseline*'
        $script:device.Steps.M = @{ CompletionState = 'TechnicianConfirmed'; ActionName = 'RetryFailedApplications'; Success = $true; IsSimulated = $false; Timestamp = $baselineTime; Data = $result.Data }
        Test-ManifestStepCompleted -Device $script:device -StepId 'M' | Should -BeFalse
        $script:device.Steps.M.Data.SyncRequestedForOutcome = $false
        $script:device.Steps.M.IsSimulated = $true
        Test-ManifestStepCompleted -Device $script:device -StepId 'M' | Should -BeFalse
        $script:device.Steps.M.IsSimulated = $false
        $script:device.Steps.M.Success = $false
        Test-ManifestStepCompleted -Device $script:device -StepId 'M' | Should -BeFalse
        $script:device.Steps.M.Success = $true
        $script:device.Steps.M.Data.NoApplicationFailures = $false
        Test-ManifestStepCompleted -Device $script:device -StepId 'M' | Should -BeFalse
    }
}

Describe 'Combined preparation and recovery plans' {
    BeforeEach {
        $script:Runtime = @{ IsDemoMode = $true; ModeDisplayName = 'Demo' }
        $script:device = New-EmptyDeviceRecord
        $script:device.Serial = 'PLAN-01'
        $script:device.AutopilotDeviceId = 'auto-1'
        $script:records = @{ Value = @($script:device) }
        $script:planActions = @()
        Mock Get-ManifestStepDefinition { return $script:manifestSteps | Where-Object Id -eq $StepId }
        Mock Write-Host {}
        Mock Write-AutopilotExpressLog {}
        Mock Write-UserDeviceRecords {}
        Mock Invoke-AutopilotManifestStep {
            $script:planActions += $StepDefinition.ActionName
            return New-OperationResult -ActionName $StepDefinition.ActionName -Success $true -CompletionState Simulated -Summary 'Synthetic complete action.'
        }
    }

    It 'runs only preparation actions in order and saves after each one' {
        $outcome = Invoke-DeviceWorkflowPlan -Records $script:records -Device $script:device -Plan Prepare
        $outcome.Completed | Should -BeTrue
        ($script:planActions -join ',') | Should -Be 'ResolveAutopilotDevice,RemoveAssociatedManagedDevice,ApplyGroupTag,AddToPreProvisioningGroup'
        Should -Invoke Write-UserDeviceRecords -Times 4 -Exactly
    }

    It 'saves and stops on <State> rather than running later actions' -ForEach @(
        @{ State = 'Submitted' }
        @{ State = 'Failed' }
        @{ State = 'Blocked' }
    ) {
        Mock Invoke-AutopilotManifestStep { return New-OperationResult -ActionName $StepDefinition.ActionName -Success $false -CompletionState $State -Summary 'Synthetic incomplete action.' }
        $outcome = Invoke-DeviceWorkflowPlan -Records $script:records -Device $script:device -Plan Prepare
        $outcome.Completed | Should -BeFalse
        $outcome.Result.CompletionState | Should -Be $State
        Should -Invoke Invoke-AutopilotManifestStep -Times 1 -Exactly
        Should -Invoke Write-UserDeviceRecords -Times 1 -Exactly
    }

    It 'does not run another action when saving fails' {
        Mock Write-UserDeviceRecords { throw 'Synthetic save failure' }
        { Invoke-DeviceWorkflowPlan -Records $script:records -Device $script:device -Plan Prepare } | Should -Throw '*save failure*'
        Should -Invoke Invoke-AutopilotManifestStep -Times 1 -Exactly
    }

    It 'declines recovery without running cleanup or saving a cancelled decision' {
        $script:device.Steps.A = @{ CompletionState = 'Simulated' }
        Mock Read-ValidatedInput { return 'N' }
        $outcome = Invoke-DeviceWorkflowPlan -Records $script:records -Device $script:device -Plan Recover
        $outcome.Completed | Should -BeFalse
        $script:device.RecoveryActive | Should -BeFalse
        Should -Invoke Invoke-AutopilotManifestStep -Times 0 -Exactly
        Should -Invoke Write-UserDeviceRecords -Times 0 -Exactly
    }

    It 'persists new recovery entry before executing cleanup and stops if that save fails' {
        $script:device.Steps.A = @{ CompletionState = 'Simulated' }
        Mock Read-ValidatedInput { return 'Y' }
        Mock Write-UserDeviceRecords { throw 'Synthetic recovery save failure' }
        { Invoke-DeviceWorkflowPlan -Records $script:records -Device $script:device -Plan Recover } | Should -Throw '*save failure*'
        Should -Invoke Invoke-AutopilotManifestStep -Times 0 -Exactly
    }

    It 'repeats stale cleanup but never resubmits a current-cycle unblock' {
        $script:device.RecoveryActive = $true
        $script:device.RecoveryStartedAt = (Get-Date).AddMinutes(-10)
        $script:device.Steps.A = @{ CompletionState = 'Simulated' }
        $script:device.Steps.B = @{ CompletionState = 'Simulated'; Timestamp = (Get-Date).AddHours(-1) }
        $script:device.Steps.P = @{ CompletionState = 'Submitted'; Timestamp = (Get-Date).AddMinutes(-3) }
        $outcome = Invoke-DeviceWorkflowPlan -Records $script:records -Device $script:device -Plan Recover
        $outcome.Completed | Should -BeTrue
        ($script:planActions -join ',') | Should -Be 'RemoveAssociatedManagedDevice,ConfirmRecoveryReadiness'
        $script:device.RecoveryActive | Should -BeFalse
    }

    It 'refuses an older unblock submission without replay' {
        $script:device.RecoveryActive = $true
        $script:device.RecoveryStartedAt = (Get-Date).AddMinutes(-10)
        $script:device.Steps.A = @{ CompletionState = 'Simulated' }
        $script:device.Steps.B = @{ CompletionState = 'Simulated'; Timestamp = (Get-Date).AddMinutes(-5) }
        $script:device.Steps.P = @{ CompletionState = 'Submitted'; Timestamp = (Get-Date).AddHours(-1) }
        $outcome = Invoke-DeviceWorkflowPlan -Records $script:records -Device $script:device -Plan Recover
        $outcome.Completed | Should -BeFalse
        $outcome.Summary | Should -BeLike '*requires review*'
        Should -Invoke Invoke-AutopilotManifestStep -Times 0 -Exactly
    }

    It 'rejects a removed selected device before resolving or executing actions' {
        $script:device.Status = 'removed'
        $outcome = Invoke-DeviceWorkflowPlan -Records $script:records -Device $script:device -Plan Prepare
        $outcome.Completed | Should -BeFalse
        Should -Invoke Get-ManifestStepDefinition -Times 0 -Exactly
        Should -Invoke Invoke-AutopilotManifestStep -Times 0 -Exactly
    }

    It 'does not repeat preparation actions whose completion evidence is still valid' {
        $null = Invoke-DeviceWorkflowPlan -Records $script:records -Device $script:device -Plan Prepare
        $outcome = Invoke-DeviceWorkflowPlan -Records $script:records -Device $script:device -Plan Prepare
        $outcome.Completed | Should -BeTrue
        Should -Invoke Invoke-AutopilotManifestStep -Times 4 -Exactly
        Should -Invoke Write-UserDeviceRecords -Times 4 -Exactly
    }

    It 'saves an accepted unblock and stops without automatically running readiness' {
        $script:device.Steps.A = @{ CompletionState = 'Simulated' }
        Mock Read-ValidatedInput { return 'Y' }
        Mock Invoke-AutopilotManifestStep {
            return New-OperationResult -ActionName $StepDefinition.ActionName -Success $true -CompletionState Submitted -Summary 'Synthetic accepted unblock.'
        } -ParameterFilter { $StepDefinition.ActionName -eq 'ClearUserlessEnrollmentStatus' }
        $outcome = Invoke-DeviceWorkflowPlan -Records $script:records -Device $script:device -Plan Recover
        $outcome.Completed | Should -BeFalse
        $outcome.Result.CompletionState | Should -Be Submitted
        $script:device.RecoveryActive | Should -BeTrue
        $script:device.Steps.P.CompletionState | Should -Be Submitted
        Should -Invoke Write-UserDeviceRecords -Times 3 -Exactly
        Should -Invoke Invoke-AutopilotManifestStep -Times 0 -Exactly -ParameterFilter { $StepDefinition.ActionName -eq 'ConfirmRecoveryReadiness' }
    }

    It 'refuses a missing semantic role before executing any action' {
        Mock Get-ManifestActionStepId { throw 'Synthetic missing manifest role' } -ParameterFilter { $ActionName -eq 'AddToPreProvisioningGroup' }
        { Invoke-DeviceWorkflowPlan -Records $script:records -Device $script:device -Plan Prepare } | Should -Throw '*missing manifest role*'
        Should -Invoke Invoke-AutopilotManifestStep -Times 0 -Exactly
        Should -Invoke Write-UserDeviceRecords -Times 0 -Exactly
    }

    It 'resolves preparation by semantic actions after every step label is renamed' {
        $originalDefinitions = $script:manifestSteps
        try {
            $script:manifestSteps = ConvertTo-NormalisedValue -Value $originalDefinitions
            foreach ($definition in $script:manifestSteps) {
                $definition.Id = 'CUSTOM-{0}' -f $definition.Id
                $definition.PrerequisiteStepIds = @($definition.PrerequisiteStepIds | ForEach-Object { 'CUSTOM-{0}' -f $_ })
            }
            $outcome = Invoke-DeviceWorkflowPlan -Records $script:records -Device $script:device -Plan Prepare
            $outcome.Completed | Should -BeTrue
            $script:device.Steps.Keys | Should -Contain 'CUSTOM-A'
            $script:device.Steps.Keys | Should -Contain 'CUSTOM-B'
            $script:device.Steps.Keys | Should -Contain 'CUSTOM-C'
            $script:device.Steps.Keys | Should -Contain 'CUSTOM-D'
        }
        finally { $script:manifestSteps = $originalDefinitions }
    }
}

Describe 'Guarded Group Tag preparation overlap' {
    BeforeEach {
        $script:Runtime = @{ IsDemoMode = $false; ModeDisplayName = 'Live' }
        $script:device = New-EmptyDeviceRecord
        $script:device.RecordId = 'overlap-record'
        $script:device.BuildCycleId = 'overlap-cycle'
        $script:device.TenantId = $script:fixtureTenantId
        $script:device.Serial = 'OVERLAP-01'
        $script:device.SiteCode = 'MI'
        $script:device.DeviceType = 'Desktop'
        $script:device.AutopilotDeviceId = 'overlap-target'
        $script:device.StartedAt = (Get-Date).AddMinutes(-10)
        $script:device.Steps.A = @{ CompletionState = 'Verified' }
        $script:device.Steps.B = @{ CompletionState = 'Verified' }
        $script:device.Steps.C = @{
            CompletionState = 'Submitted'; Timestamp = (Get-Date).AddMinutes(-1)
            Data = @{ Submitted = $true; AutopilotDeviceId = 'overlap-target'; GroupTag = 'MI-Desktop'
                AcceptedContext = @{ RecordId = 'overlap-record'; BuildCycleId = 'overlap-cycle'; TenantId = $script:fixtureTenantId; Serial = 'OVERLAP-01' } }
        }
        Mock Get-ManifestStepDefinition { return $script:manifestSteps | Where-Object Id -eq $StepId }
    }
    It 'allows membership while keeping the tag and physical milestone incomplete' {
        (Test-ManifestStepEligibility -Device $script:device -StepDefinition (Get-ManifestStepDefinition D)).Eligible | Should -BeTrue
        (Test-ManifestStepCompleted -Device $script:device -StepId C) | Should -BeFalse
        (Test-ManifestStepEligibility -Device $script:device -StepDefinition (Get-ManifestStepDefinition E)).Eligible | Should -BeFalse
    }
    It 'saves pending tag evidence before membership and reports the tag as still incomplete' {
        $script:tagSaved = $false
        Mock Write-Host {}
        Mock Write-UserDeviceRecords { $script:tagSaved = $true }
        Mock Invoke-AutopilotManifestStep {
            if ($StepDefinition.ActionName -eq 'ApplyGroupTag') {
                return New-OperationResult -ActionName $StepDefinition.ActionName -Success $false -CompletionState Submitted -Summary 'Tag pending.' -Data $Device.Steps.C.Data
            }
            $script:tagSaved | Should -BeTrue
            (Test-ManifestStepEligibility -Device $Device -StepDefinition $StepDefinition).Eligible | Should -BeTrue
            return New-OperationResult -ActionName $StepDefinition.ActionName -Success $true -CompletionState Verified -Summary 'Membership verified.' -Data @{
                VerificationAttempts = 1; ExpectedMember = $true; ObservedMember = $true; GroupId = 'overlap-group'; DirectoryObjectId = 'overlap-directory-object'
            }
        }
        $outcome = Invoke-DeviceWorkflowPlan -Records @{ Value = @($script:device) } -Device $script:device -Plan Prepare
        $outcome.Completed | Should -BeFalse
        $outcome.Result.CompletionState | Should -Be Submitted
        $outcome.Summary | Should -BeLike '*Membership is complete*Group Tag remains Submitted*'
        $script:device.Steps.C.CompletionState | Should -Be Submitted
        $script:device.Steps.D.CompletionState | Should -Be Verified
        (Test-ManifestStepEligibility -Device $script:device -StepDefinition (Get-ManifestStepDefinition E)).Eligible | Should -BeFalse
        Should -Invoke Write-UserDeviceRecords -Times 2 -Exactly
        Should -Invoke Invoke-AutopilotManifestStep -Times 1 -Exactly -ParameterFilter { $StepDefinition.ActionName -eq 'AddToPreProvisioningGroup' }
    }
    It 'does not reach membership if saving the pending tag fails' {
        Mock Write-Host {}
        Mock Write-UserDeviceRecords { throw 'Synthetic pending-tag save failure' }
        Mock Invoke-AutopilotManifestStep {
            return New-OperationResult -ActionName $StepDefinition.ActionName -Success $false -CompletionState Submitted -Summary 'Tag pending.' -Data $Device.Steps.C.Data
        }
        { Invoke-DeviceWorkflowPlan -Records @{ Value = @($script:device) } -Device $script:device -Plan Prepare } | Should -Throw '*pending-tag save failure*'
        Should -Invoke Invoke-AutopilotManifestStep -Times 0 -Exactly -ParameterFilter { $StepDefinition.ActionName -eq 'AddToPreProvisioningGroup' }
    }
    It 'stops on a new blocked tag result even when older accepted evidence is preserved' {
        Mock Write-Host {}
        Mock Write-UserDeviceRecords {}
        Mock Invoke-AutopilotManifestStep {
            return New-OperationResult -ActionName $StepDefinition.ActionName -Success $false -CompletionState Blocked -Summary 'Current tag check blocked.' -Data @{ Blocked = $true }
        }
        $outcome = Invoke-DeviceWorkflowPlan -Records @{ Value = @($script:device) } -Device $script:device -Plan Prepare
        $outcome.Completed | Should -BeFalse
        $outcome.Result.CompletionState | Should -Be Blocked
        $script:device.Steps.C.CompletionState | Should -Be Submitted
        Should -Invoke Invoke-AutopilotManifestStep -Times 0 -Exactly -ParameterFilter { $StepDefinition.ActionName -eq 'AddToPreProvisioningGroup' }
    }
    It 'keeps both tag and membership pending without declaring preparation complete' {
        Mock Write-Host {}
        Mock Write-UserDeviceRecords {}
        Mock Invoke-AutopilotManifestStep {
            return New-OperationResult -ActionName $StepDefinition.ActionName -Success $false -CompletionState Submitted -Summary 'Accepted, not verified.' -Data $Device.Steps.C.Data
        }
        $outcome = Invoke-DeviceWorkflowPlan -Records @{ Value = @($script:device) } -Device $script:device -Plan Prepare
        $outcome.Completed | Should -BeFalse
        $outcome.Step.ActionName | Should -Be AddToPreProvisioningGroup
        $outcome.Summary | Should -BeLike '*Group Tag verification also remains pending*'
        Should -Invoke Write-UserDeviceRecords -Times 2 -Exactly
    }
    It 'resolves overlap dependencies by semantic action after step labels change' {
        $originalDefinitions = $script:manifestSteps
        try {
            $script:manifestSteps = ConvertTo-NormalisedValue -Value $originalDefinitions
            foreach ($definition in $script:manifestSteps) {
                $definition.Id = 'CUSTOM-{0}' -f $definition.Id
                $definition.PrerequisiteStepIds = @($definition.PrerequisiteStepIds | ForEach-Object { 'CUSTOM-{0}' -f $_ })
            }
            $script:device.Steps = @{ 'CUSTOM-A' = $script:device.Steps.A; 'CUSTOM-B' = $script:device.Steps.B; 'CUSTOM-C' = $script:device.Steps.C }
            (Test-ManifestStepEligibility -Device $script:device -StepDefinition (Get-ManifestStepDefinition CUSTOM-D)).Eligible | Should -BeTrue
            (Test-ManifestStepEligibility -Device $script:device -StepDefinition (Get-ManifestStepDefinition CUSTOM-E)).Eligible | Should -BeFalse
        }
        finally { $script:manifestSteps = $originalDefinitions }
    }
    It 'refuses a mismatched accepted <Field>' -ForEach @(
        @{ Field = 'RecordId' }, @{ Field = 'BuildCycleId' }, @{ Field = 'TenantId' }, @{ Field = 'Serial' }
    ) {
        $script:device.Steps.C.Data.AcceptedContext[$Field] = 'different'
        (Test-ManifestStepEligibility -Device $script:device -StepDefinition (Get-ManifestStepDefinition D)).Eligible | Should -BeFalse
    }
    It 'refuses <Defect> instead of relaxing other prerequisites' -ForEach @(
        @{ Defect = 'Legacy' }, @{ Defect = 'Failed' }, @{ Defect = 'NotAccepted' }, @{ Defect = 'Target' }, @{ Defect = 'Tag' },
        @{ Defect = 'Old' }, @{ Defect = 'Future' }, @{ Defect = 'MissingTimestamp' }, @{ Defect = 'IdentityPending' }, @{ Defect = 'CleanupPending' }, @{ Defect = 'ClosedRecovery' }
    ) {
        switch ($Defect) {
            Legacy { $script:device.Steps.C.Data.Remove('AcceptedContext') }
            Failed { $script:device.Steps.C.CompletionState = 'Failed' }
            NotAccepted { $script:device.Steps.C.Data.Submitted = $false }
            Target { $script:device.Steps.C.Data.AutopilotDeviceId = 'different' }
            Tag { $script:device.Steps.C.Data.GroupTag = 'MU-Desktop' }
            Old { $script:device.Steps.C.Timestamp = (Get-Date).AddHours(-1) }
            Future { $script:device.Steps.C.Timestamp = (Get-Date).AddHours(1) }
            MissingTimestamp { $script:device.Steps.C.Timestamp = '' }
            IdentityPending { $script:device.Steps.A.CompletionState = 'Submitted' }
            CleanupPending { $script:device.Steps.B.CompletionState = 'Submitted' }
            ClosedRecovery { $script:device.RecoveryHistory = @(@{ Stage = 'RecoveryClosed'; Timestamp = Get-Date }) }
        }
        (Test-ManifestStepEligibility -Device $script:device -StepDefinition (Get-ManifestStepDefinition D)).Eligible | Should -BeFalse
    }
}

Describe 'Semantic safety gates with renamed step labels' {
    BeforeEach {
        $script:originalManifestSteps = $script:manifestSteps
        $script:manifestSteps = ConvertTo-NormalisedValue -Value $script:originalManifestSteps
        $labelMap = @{ A = 'Identity'; B = 'Cleanup'; P = 'Unblock'; Q = 'CloseRecovery'; C = 'A' }
        foreach ($definition in $script:manifestSteps) {
            if ($labelMap.ContainsKey($definition.Id)) { $definition.Id = $labelMap[$definition.Id] }
            $definition.PrerequisiteStepIds = @($definition.PrerequisiteStepIds | ForEach-Object {
                    if ($labelMap.ContainsKey($_)) { $labelMap[$_] } else { $_ }
                })
        }
        $script:Runtime = @{ IsDemoMode = $false; ModeDisplayName = 'Live' }
        $script:GraphSession = @{ Connected = $true; IsSimulated = $false; TenantId = $script:fixtureTenantId }
        Mock Get-MgContext { return @{ TenantId = $script:fixtureTenantId } }
        $script:device = @{
            TenantId = $script:fixtureTenantId
            Serial = 'RENAMED-01'; AutopilotDeviceId = 'ap-one'; ManagedDeviceId = ''; IntuneDeviceName = ''
            Steps = @{}; RecoveryActive = $true; RecoveryStartedAt = (Get-Date).AddMinutes(-5)
            RecoveryReason = 'Synthetic failure'; RecoveryHistory = @(); Status = 'in-progress'; IsCompletionVerified = $false
        }
        foreach ($definition in $script:manifestSteps) {
            if ($definition.ActivationRequirement -eq 'None') { $script:device.Steps[$definition.Id] = @{ CompletionState = 'Verified' } }
        }
        $script:device.Steps.Unblock = @{ CompletionState = 'Submitted'; Timestamp = (Get-Date).AddMinutes(-3) }
        Mock Read-ValidatedInput { return 'Y' }
        Mock Write-Host {}
        Mock Write-AutopilotExpressLog {}
        Mock Resolve-LiveManagedDeviceBySerial { return $null }
    }

    AfterEach { $script:manifestSteps = $script:originalManifestSteps }

    It 'requires an Autopilot identifier for the renamed identity action but not an unrelated A label' {
        $script:device.AutopilotDeviceId = ''
        Test-ManifestStepCompleted -Device $script:device -StepId Identity | Should -BeFalse
        Test-ManifestStepCompleted -Device $script:device -StepId A | Should -BeTrue
    }

    It 'allows renamed identity and cleanup actions during recovery but blocks unrelated A' {
        foreach ($stepId in @('Identity', 'Cleanup')) {
            $step = $script:manifestSteps | Where-Object Id -eq $stepId
            (Test-ManifestStepEligibility -Device $script:device -StepDefinition $step).Eligible | Should -BeTrue
        }
        $step = $script:manifestSteps | Where-Object Id -eq A
        (Test-ManifestStepEligibility -Device $script:device -StepDefinition $step).Eligible | Should -BeFalse
    }

    It 'uses the renamed unblock and cleanup steps for readiness evidence and guidance' {
        $step = $script:manifestSteps | Where-Object Id -eq CloseRecovery
        $result = Invoke-StepConfirmRecoveryReadiness -Device $script:device -StepDefinition $step
        $result.Success | Should -BeTrue
        $result.CompletionState | Should -Be 'TechnicianConfirmed'
        $result.Summary | Should -BeLike '*restart preparation from Cleanup*'
        Should -Invoke Resolve-LiveManagedDeviceBySerial -Times 1 -Exactly
    }

    It 'does not accept evidence under the old unblock label as current-cycle evidence' {
        $script:device.Steps.P = $script:device.Steps.Unblock
        $script:device.Steps.Remove('Unblock')
        $step = $script:manifestSteps | Where-Object Id -eq CloseRecovery
        $result = Invoke-StepConfirmRecoveryReadiness -Device $script:device -StepDefinition $step
        $result.CompletionState | Should -Be 'Blocked'
        $result.Summary | Should -BeLike '*Unblock first*'
        Should -Invoke Read-ValidatedInput -Times 0 -Exactly
    }

    It 'offers close-out instead of replaying a renamed submitted unblock' {
        $eligibleIds = @(Get-EligibleManifestSteps -Device $script:device | ForEach-Object Id)
        $eligibleIds | Should -Contain 'CloseRecovery'
        $eligibleIds | Should -Not -Contain 'Unblock'
    }

    It 'archives all prior evidence and retains only semantic identity unblock and close-out records' {
        $step = $script:manifestSteps | Where-Object Id -eq CloseRecovery
        $result = New-OperationResult -ActionName $step.ActionName -Success $true -CompletionState TechnicianConfirmed
        Write-ManifestStepResult -Device $script:device -StepDefinition $step -Result $result
        @($script:device.Steps.Keys).Count | Should -Be 3
        $script:device.Steps.Identity.CompletionState | Should -Be 'Verified'
        $script:device.Steps.Unblock.CompletionState | Should -Be 'Submitted'
        $script:device.Steps.CloseRecovery.CompletionState | Should -Be 'TechnicianConfirmed'
        $script:device.Steps.ContainsKey('A') | Should -BeFalse
        $script:device.RecoveryHistory[0].Steps.A.CompletionState | Should -Be 'Verified'
        $script:device.RecoveryActive | Should -BeFalse
        (Get-EligibleManifestSteps -Device $script:device | Select-Object -First 1).Id | Should -Be 'Cleanup'
    }

    It 'enters recovery using renamed identity and removes renamed recovery results without losing history' {
        $script:device.RecoveryActive = $false
        $script:device.Steps.CloseRecovery = @{ CompletionState = 'TechnicianConfirmed' }
        Enter-DeviceRecoveryMode -Device $script:device
        $script:device.RecoveryActive | Should -BeTrue
        $script:device.Steps.ContainsKey('Unblock') | Should -BeFalse
        $script:device.Steps.ContainsKey('CloseRecovery') | Should -BeFalse
        $script:device.Steps.Identity.CompletionState | Should -Be 'Verified'
        $script:device.RecoveryHistory[0].Steps.Unblock.CompletionState | Should -Be 'Submitted'
        $script:device.RecoveryHistory[0].Steps.CloseRecovery.CompletionState | Should -Be 'TechnicianConfirmed'
    }

    It 'rejects missing or ambiguous action roles before changing recovery state' {
        $script:device.RecoveryActive = $false
        $before = $script:device | ConvertTo-Json -Depth 100 -Compress
        $script:manifestSteps = @($script:manifestSteps | Where-Object ActionName -ne ResolveAutopilotDevice)
        { Enter-DeviceRecoveryMode -Device $script:device } | Should -Throw '*unique manifest step*'
        ($script:device | ConvertTo-Json -Depth 100 -Compress) | Should -Be $before
        $script:manifestSteps = @($script:originalManifestSteps) + , $script:originalManifestSteps[0]
        { Get-ManifestActionStepId -ActionName ResolveAutopilotDevice } | Should -Throw '*unique manifest step*'
        Should -Invoke Read-ValidatedInput -Times 0 -Exactly
    }
}

Describe 'Complete semantic action dispatch' {
    BeforeAll {
        $script:dispatchHandlers = @('Invoke-StepResolveAutopilotDevice', 'Invoke-StepRemoveAssociatedManagedDevice', 'Invoke-StepApplyGroupTag', 'Invoke-StepValidateDeploymentProfile', 'Invoke-StepAddPreProvisioningGroup', 'Invoke-StepClearUserlessEnrollmentStatus', 'Invoke-StepAssignTechnicianPrimaryUser', 'Invoke-StepRetryFailedApps', 'Invoke-StepRemovePreProvisioningGroup', 'Invoke-StepAssignFinalPrimaryUser', 'Invoke-StepConfirmPhysicalMilestone', 'Invoke-StepConfirmRecoveryReadiness')
        foreach ($handler in $script:dispatchHandlers) {
            $definition = $sourceAst.Find({ param($node) $node -is [System.Management.Automation.Language.FunctionDefinitionAst] -and $node.Name -eq $handler }, $true)
            Set-Item -Path ('Function:{0}' -f $definition.Name) -Value $definition.Body.GetScriptBlock()
        }
    }
    BeforeEach {
        $script:Runtime = @{ IsDemoMode = $false }
        $script:routeDevice = @{ Serial = 'ROUTE-01'; Steps = @{} }
        Mock Get-LiveTenantBinding { return @{ TenantId = 'synthetic' } }
        Mock Test-ManifestStepEligibility { return @{ Eligible = $true } }
        foreach ($handler in $script:dispatchHandlers) {
            Mock -CommandName $handler -MockWith { throw 'Unexpected action handler.' }
        }
    }
    It 'routes <Action> once without depending on the displayed step ID' -TestCases @(
        @{ Action = 'ResolveAutopilotDevice'; Handler = 'Invoke-StepResolveAutopilotDevice' }
        @{ Action = 'RemoveAssociatedManagedDevice'; Handler = 'Invoke-StepRemoveAssociatedManagedDevice' }
        @{ Action = 'ApplyGroupTag'; Handler = 'Invoke-StepApplyGroupTag' }
        @{ Action = 'ValidateDeploymentProfile'; Handler = 'Invoke-StepValidateDeploymentProfile' }
        @{ Action = 'AddToPreProvisioningGroup'; Handler = 'Invoke-StepAddPreProvisioningGroup' }
        @{ Action = 'ClearUserlessEnrollmentStatus'; Handler = 'Invoke-StepClearUserlessEnrollmentStatus' }
        @{ Action = 'AssignTechnicianPrimaryUser'; Handler = 'Invoke-StepAssignTechnicianPrimaryUser' }
        @{ Action = 'RetryFailedApplications'; Handler = 'Invoke-StepRetryFailedApps' }
        @{ Action = 'RemoveFromPreProvisioningGroup'; Handler = 'Invoke-StepRemovePreProvisioningGroup' }
        @{ Action = 'AssignFinalPrimaryUser'; Handler = 'Invoke-StepAssignFinalPrimaryUser' }
        @{ Action = 'ConfirmImagingAndOobe'; Handler = 'Invoke-StepConfirmPhysicalMilestone' }
        @{ Action = 'ConfirmReseal'; Handler = 'Invoke-StepConfirmPhysicalMilestone' }
        @{ Action = 'ConfirmBootToSignIn'; Handler = 'Invoke-StepConfirmPhysicalMilestone' }
        @{ Action = 'ConfirmFirstSignIn'; Handler = 'Invoke-StepConfirmPhysicalMilestone' }
        @{ Action = 'ConfirmApplicationBaseline'; Handler = 'Invoke-StepConfirmPhysicalMilestone' }
        @{ Action = 'ConfirmUpdatesAndShutdown'; Handler = 'Invoke-StepConfirmPhysicalMilestone' }
        @{ Action = 'ConfirmRecoveryReadiness'; Handler = 'Invoke-StepConfirmRecoveryReadiness' }
    ) {
        param($Action, $Handler)
        $script:expectedHandler = $Handler
        Mock -CommandName $Handler -MockWith { return @{ Handler = $script:expectedHandler; Serial = $Device.Serial; StepId = $StepDefinition.Id } }
        $result = Invoke-AutopilotManifestStep -Device $script:routeDevice -StepDefinition @{ Id = 'RENAMED'; ActionName = $Action }
        $result.Handler | Should -Be $Handler
        $result.Serial | Should -Be ROUTE-01
        $result.StepId | Should -Be RENAMED
        Should -Invoke -CommandName $Handler -Times 1 -Exactly
        foreach ($otherHandler in @($script:dispatchHandlers | Where-Object { $_ -ne $Handler })) {
            Should -Invoke -CommandName $otherHandler -Times 0 -Exactly
        }
        Should -Invoke Get-LiveTenantBinding -Times 1 -Exactly -ParameterFilter { [bool]$AllowUnbound -eq ($Action -eq 'ResolveAutopilotDevice') }
        $script:routeDevice.Steps.Count | Should -Be 0
    }
    It 'refuses a tenant mismatch before checking prerequisites or calling any handler' {
        Mock Get-LiveTenantBinding { throw 'Synthetic tenant mismatch' }
        $result = Invoke-AutopilotManifestStep -Device $script:routeDevice -StepDefinition @{ Id = 'A'; ActionName = 'ResolveAutopilotDevice' }
        $result.CompletionState | Should -Be Blocked
        Should -Invoke Test-ManifestStepEligibility -Times 0 -Exactly
        foreach ($handler in $script:dispatchHandlers) { Should -Invoke -CommandName $handler -Times 0 -Exactly }
    }
    It 'refuses missing prerequisites or activation without executing actions' -TestCases @(
        @{ Missing = @('Earlier'); Activation = 'None'; Expected = '*prerequisite*' }
        @{ Missing = @(); Activation = 'Recovery'; Expected = '*Activate Recovery*' }
    ) {
        param($Missing, $Activation, $Expected)
        $script:missingRouteSteps = $Missing
        $script:routeActivation = $Activation
        Mock Test-ManifestStepEligibility { return @{ Eligible = $false; MissingStepIds = $script:missingRouteSteps; ActivationRequirement = $script:routeActivation } }
        $result = Invoke-AutopilotManifestStep -Device $script:routeDevice -StepDefinition @{ Id = 'A'; ActionName = 'ApplyGroupTag' }
        $result.CompletionState | Should -Be Blocked
        $result.Notes | Should -BeLike $Expected
        foreach ($handler in $script:dispatchHandlers) { Should -Invoke -CommandName $handler -Times 0 -Exactly }
    }
    It 'fails closed on unknown actions without invoking a neighbouring handler' {
        $result = Invoke-AutopilotManifestStep -Device $script:routeDevice -StepDefinition @{ Id = 'A'; ActionName = 'UnknownAction' }
        $result.Success | Should -BeFalse
        $result.CompletionState | Should -Be Failed
        foreach ($handler in $script:dispatchHandlers) { Should -Invoke -CommandName $handler -Times 0 -Exactly }
    }
}

Describe 'Guided physical milestone workflow' {
    BeforeEach {
        $script:Runtime = @{ IsDemoMode = $false; ModeDisplayName = 'Live' }
        $script:GraphSession = @{ Connected = $true; IsSimulated = $false; TenantId = $script:fixtureTenantId }
        Mock Get-MgContext { return @{ TenantId = $script:fixtureTenantId } }
        $script:device = @{ TenantId = $script:fixtureTenantId; Serial = 'SERIAL1'; AutopilotDeviceId = 'autopilot-1'; Steps = @{}; RecoveryActive = $false; Status = 'new'; LastUpdatedAt = $null; LastUpdatedBy = '' }
        foreach ($stepId in @('A', 'B', 'C', 'D')) { $script:device.Steps[$stepId] = @{ CompletionState = 'Verified' } }
        Mock Read-ValidatedInput { return 'Y' }
        Mock Write-Host {}
    }

    It 'contains tagged <Method> failures without retaining SDK text or retrying a handler' -ForEach @(
        @{ Method = 'GET' }
        @{ Method = 'POST' }
    ) {
        $script:failureMethod = $Method
        Mock Invoke-StepConfirmPhysicalMilestone {
            $failure = New-Object System.Exception 'SYNTHETIC-PRIVATE-SDK-DETAIL'
            $failure.Data['AutopilotExpress.GraphMethod'] = $script:failureMethod
            throw $failure
        }
        $step = $script:manifestSteps | Where-Object { $_.Id -eq 'E' }
        $result = Invoke-AutopilotManifestStep -Device $script:device -StepDefinition $step
        $result.CompletionState | Should -Be 'Failed'
        $result.Notes | Should -Match 'SDK response text is not retained'
        ($result | ConvertTo-Json -Depth 10) | Should -Not -Match 'SYNTHETIC-PRIVATE'
        Should -Invoke Invoke-StepConfirmPhysicalMilestone -Times 1 -Exactly
    }

    It 'preserves earlier Submitted target evidence when a fresh Graph lookup fails' {
        $script:device.Steps.E = @{ CompletionState = 'Submitted'; Data = @{ Submitted = $true; TargetId = 'retained-target'; Nested = @{ State = 'accepted' } } }
        Mock Invoke-StepConfirmPhysicalMilestone {
            $failure = New-Object System.Exception 'SYNTHETIC-PRIVATE-SDK-DETAIL'
            $failure.Data['AutopilotExpress.GraphMethod'] = 'GET'
            throw $failure
        }
        $step = $script:manifestSteps | Where-Object { $_.Id -eq 'E' }
        $result = Invoke-AutopilotManifestStep -Device $script:device -StepDefinition $step
        $result.CompletionState | Should -Be 'Submitted'
        $result.Data.Submitted | Should -BeTrue
        $result.Data.TargetId | Should -BeExactly 'retained-target'
        $result.Data.Nested.State = 'changed-copy'
        $script:device.Steps.E.Data.Nested.State | Should -BeExactly 'accepted'
        Should -Invoke Invoke-StepConfirmPhysicalMilestone -Times 1 -Exactly
    }

    It 'does not swallow untagged local or explicitly tagged persistence failures' -ForEach @(
        @{ StorageTagged = $false }
        @{ StorageTagged = $true }
    ) {
        $script:storageTagged = $StorageTagged
        Mock Invoke-StepConfirmPhysicalMilestone {
            $failure = New-Object System.Exception 'Synthetic storage failure'
            if ($script:storageTagged) {
                $failure.Data['AutopilotExpress.GraphMethod'] = 'GET'
                $failure.Data['AutopilotExpress.HashImportStorageFailure'] = $true
            }
            throw $failure
        }
        $step = $script:manifestSteps | Where-Object { $_.Id -eq 'E' }
        { Invoke-AutopilotManifestStep -Device $script:device -StepDefinition $step } | Should -Throw '*Synthetic storage failure*'
        Should -Invoke Invoke-StepConfirmPhysicalMilestone -Times 1 -Exactly
    }

    It 'loads an acyclic manifest with all physical actions enabled' {
        { Test-ManifestDependencyGraph -Steps $script:manifestSteps } | Should -Not -Throw
        @($manifest.steps | Where-Object { $_.id -in @('E', 'G', 'H') -and $_.enabled }).Count | Should -Be 3
    }

    It 'selects the sole dictionary-backed device rather than its first property' {
        Mock Read-ValidatedInput { return '1' }
        $records = @{ Value = @($script:device) }
        $selected = Select-DeviceFromRecords -Records $records -Purpose 'autopilot'
        $selected.Serial | Should -Be 'SERIAL1'
        $selected.Steps.A.CompletionState | Should -Be 'Verified'
    }

    It 'does not complete a device when no next step is eligible but required work remains' {
        Mock Get-NextStepId { return $null }
        $step = $script:manifestSteps | Where-Object { $_.Id -eq 'E' }
        $result = New-OperationResult -ActionName $step.ActionName -Success $false -CompletionState Submitted
        Write-ManifestStepResult -Device $script:device -StepDefinition $step -Result $result
        $script:device.Status | Should -Not -Be 'completed'
        (Test-DeviceReadyForDispatch -Device $script:device).Ready | Should -BeFalse
    }

    It 'completes a device only when every active required action is complete' {
        foreach ($definition in $script:manifestSteps) {
            if ($definition.ActivationRequirement -eq 'None') { $script:device.Steps[$definition.Id] = @{ CompletionState = 'TechnicianConfirmed' } }
        }
        $step = $script:manifestSteps | Where-Object { $_.Id -eq 'O' }
        $result = New-OperationResult -ActionName $step.ActionName -Success $true -CompletionState TechnicianConfirmed
        Write-ManifestStepResult -Device $script:device -StepDefinition $step -Result $result
        $script:device.Status | Should -Be 'completed'
        $script:device.CompletedAt | Should -Not -BeNullOrEmpty
        (Test-DeviceReadyForDispatch -Device $script:device).Ready | Should -BeTrue
    }

    It 'clears stale completion metadata when a required action becomes incomplete' {
        $script:device.Status = 'completed'
        $script:device.CompletedAt = Get-Date
        $script:device.CompletedBy = 'Previous technician'
        $script:device.IsCompletionVerified = $true
        $step = $script:manifestSteps | Where-Object { $_.Id -eq 'E' }
        $result = New-OperationResult -ActionName $step.ActionName -Success $false -CompletionState Submitted
        Write-ManifestStepResult -Device $script:device -StepDefinition $step -Result $result
        $script:device.Status | Should -Be 'in-progress'
        $script:device.CompletedAt | Should -Be ([DateTime]::MinValue)
        $script:device.CompletedBy | Should -Be ''
        $script:device.IsCompletionVerified | Should -BeFalse
    }

    It 'rejects manual completed status while required work remains' {
        Mock Clear-Host {}
        Mock Read-Host { return '' }
        Mock Select-DeviceFromRecords { return $script:device }
        Mock Read-ValidatedInput { return 'completed' } -ParameterFilter { $Prompt -like 'Enter status*' }
        Mock Read-ValidatedInput { return 'new' } -ParameterFilter { $Prompt -eq 'Status' }
        Mock Read-ValidatedInput { return '0' } -ParameterFilter { $Prompt -like '1. Maintain another*' }
        Mock Write-UserDeviceRecords {}
        Update-DeviceStatus -Records @{ Value = @($script:device) }
        $script:device.Status | Should -Be 'new'
        Should -Invoke Write-UserDeviceRecords -Times 0 -Exactly
        Should -Invoke Write-Host -Times 1 -Exactly -ParameterFilter { $Object -like '*Cannot mark this device completed*' }
    }

    It 'allows manual completed status after all normal actions are complete' {
        Mock Clear-Host {}
        Mock Read-Host { return '' }
        foreach ($definition in $script:manifestSteps) {
            if ($definition.ActivationRequirement -eq 'None') { $script:device.Steps[$definition.Id] = @{ CompletionState = 'TechnicianConfirmed' } }
        }
        Mock Select-DeviceFromRecords { return $script:device }
        Mock Read-ValidatedInput { return 'completed' } -ParameterFilter { $Prompt -like 'Enter status*' }
        Mock Read-ValidatedInput { return '0' } -ParameterFilter { $Prompt -like '1. Maintain another*' }
        Mock Write-UserDeviceRecords {}
        Mock Write-AutopilotExpressLog {}
        Update-DeviceStatus -Records @{ Value = @($script:device) }
        $script:device.Status | Should -Be 'completed'
        Should -Invoke Write-UserDeviceRecords -Times 1 -Exactly
    }

    It 'dispatches imaging guidance with the agreed Y default and technician evidence' {
        $step = $script:manifestSteps | Where-Object { $_.Id -eq 'E' }
        $result = Invoke-AutopilotManifestStep -Device $script:device -StepDefinition $step
        $result.CompletionState | Should -Be 'TechnicianConfirmed'
        $result.Data.ChecklistVersion | Should -Be '1.4'
        $result.Data.ChecklistSteps | Should -Be @(6, 7, 8, 9, 10)
        Should -Invoke Read-ValidatedInput -Times 1 -Exactly -ParameterFilter { $Default -eq 'Y' -and $Type -eq 'Choice' }
        Should -Invoke Write-Host -Times 1 -Exactly -ParameterFilter { $Object -like '*Windows key five times*' }
    }

    It 'blocks profile validation until imaging and OOBE are confirmed' {
        $step = $script:manifestSteps | Where-Object { $_.Id -eq 'F' }
        (Test-ManifestStepEligibility -Device $script:device -StepDefinition $step).Eligible | Should -BeFalse
        $script:device.Steps.E = @{ CompletionState = 'TechnicianConfirmed' }
        (Test-ManifestStepEligibility -Device $script:device -StepDefinition $step).Eligible | Should -BeTrue
    }

    It 'blocks reseal before profile validation without prompting' {
        $step = $script:manifestSteps | Where-Object { $_.Id -eq 'G' }
        (Invoke-AutopilotManifestStep -Device $script:device -StepDefinition $step).CompletionState | Should -Be 'Blocked'
        Should -Invoke Read-ValidatedInput -Times 0 -Exactly
    }

    It 'records reseal against checklist step 13 after profile confirmation' {
        $script:device.Steps.F = @{ CompletionState = 'TechnicianConfirmed' }
        $step = $script:manifestSteps | Where-Object { $_.Id -eq 'G' }
        $result = Invoke-AutopilotManifestStep -Device $script:device -StepDefinition $step
        $result.CompletionState | Should -Be 'TechnicianConfirmed'
        $result.Data.ChecklistSteps | Should -Be @(13)
    }

    It 'records boot-to-sign-in against checklist step 14 after reseal' {
        $script:device.Steps.G = @{ CompletionState = 'TechnicianConfirmed' }
        $step = $script:manifestSteps | Where-Object { $_.Id -eq 'H' }
        (Invoke-AutopilotManifestStep -Device $script:device -StepDefinition $step).Data.ChecklistSteps | Should -Be @(14)
    }

    It 'blocks technician assignment until boot-to-sign-in is confirmed' {
        $script:device.Steps.F = @{ CompletionState = 'TechnicianConfirmed' }
        $step = $script:manifestSteps | Where-Object { $_.Id -eq 'I' }
        (Test-ManifestStepEligibility -Device $script:device -StepDefinition $step).Eligible | Should -BeFalse
        $script:device.Steps.H = @{ CompletionState = 'TechnicianConfirmed' }
        (Test-ManifestStepEligibility -Device $script:device -StepDefinition $step).Eligible | Should -BeTrue
    }

    It 'keeps a negative confirmation incomplete and resumable' {
        Mock Read-ValidatedInput { return 'n' }
        $step = $script:manifestSteps | Where-Object { $_.Id -eq 'E' }
        $result = Invoke-AutopilotManifestStep -Device $script:device -StepDefinition $step
        $result.CompletionState | Should -Be 'Submitted'
        Write-ManifestStepResult -Device $script:device -StepDefinition $step -Result $result
        Test-ManifestStepCompleted -Device $script:device -StepId 'E' | Should -BeFalse
    }

    It 'preserves technician evidence through a saved step JSON round trip' {
        $step = $script:manifestSteps | Where-Object { $_.Id -eq 'E' }
        $result = Invoke-AutopilotManifestStep -Device $script:device -StepDefinition $step
        Write-ManifestStepResult -Device $script:device -StepDefinition $step -Result $result
        $saved = $script:device.Steps.E | ConvertTo-Json -Depth 10 | ConvertFrom-Json
        $saved.CompletionState | Should -Be 'TechnicianConfirmed'
        $saved.Data.ConfirmationDefault | Should -Be 'Y'
        $saved.Data.ChecklistSteps.Count | Should -Be 5
        $saved.Timestamp | Should -Not -BeNullOrEmpty
        $script:device.Status | Should -Be 'in-progress'
    }

    It 'keeps Demo confirmation simulated' {
        $script:Runtime.IsDemoMode = $true
        $step = $script:manifestSteps | Where-Object { $_.Id -eq 'E' }
        (Invoke-AutopilotManifestStep -Device $script:device -StepDefinition $step).CompletionState | Should -Be 'Simulated'
    }

    It 'does not fabricate new milestones from pre-existing completed records' {
        $script:device.Steps.I = @{ CompletionState = 'LegacyCompleted' }
        Test-ManifestStepCompleted -Device $script:device -StepId 'I' | Should -BeTrue
        foreach ($stepId in @('E', 'G', 'H')) { Test-ManifestStepCompleted -Device $script:device -StepId $stepId | Should -BeFalse }
    }

    It 'blocks first sign-in until assignment, group removal and boot are complete' {
        $step = $script:manifestSteps | Where-Object { $_.Id -eq 'K' }
        (Invoke-AutopilotManifestStep -Device $script:device -StepDefinition $step).CompletionState | Should -Be 'Blocked'
        Should -Invoke Read-ValidatedInput -Times 0 -Exactly
        foreach ($stepId in @('I', 'J', 'H')) { $script:device.Steps[$stepId] = @{ CompletionState = 'TechnicianConfirmed' } }
        (Test-ManifestStepEligibility -Device $script:device -StepDefinition $step).Eligible | Should -BeTrue
    }

    It 'dispatches post-login milestones and persists checklist evidence: <StepId>' -TestCases @(
        @{ StepId = 'K'; Prerequisites = @('I', 'J', 'H'); ChecklistSteps = @(17) }
        @{ StepId = 'L'; Prerequisites = @('K'); ChecklistSteps = @(18, 19) }
        @{ StepId = 'N'; Prerequisites = @('L'); ChecklistSteps = @(20, 21, 22) }
    ) {
        param($StepId, $Prerequisites, $ChecklistSteps)
        foreach ($prerequisite in $Prerequisites) { $script:device.Steps[$prerequisite] = @{ CompletionState = 'TechnicianConfirmed' } }
        $step = $script:manifestSteps | Where-Object { $_.Id -eq $StepId }
        $result = Invoke-AutopilotManifestStep -Device $script:device -StepDefinition $step
        $result.CompletionState | Should -Be 'TechnicianConfirmed'
        $result.Data.ChecklistSteps | Should -Be $ChecklistSteps
        Write-ManifestStepResult -Device $script:device -StepDefinition $step -Result $result
        Test-ManifestStepCompleted -Device $script:device -StepId $StepId | Should -BeTrue
        Should -Invoke Read-ValidatedInput -Times 1 -Exactly -ParameterFilter { $Default -eq 'Y' }
    }

    It 'presents ordered application guidance without claiming sync invokes remediation' {
        $script:device.Steps.K = @{ CompletionState = 'TechnicianConfirmed' }
        $step = $script:manifestSteps | Where-Object { $_.Id -eq 'L' }
        [void](Invoke-AutopilotManifestStep -Device $script:device -StepDefinition $step)
        Should -Invoke Write-Host -Times 1 -Exactly -ParameterFilter { $Object -like '*Install only one application at a time*' }
        Should -Invoke Write-Host -Times 1 -Exactly -ParameterFilter { $Object -like '*Laptops only: Global Protect*' }
        Should -Invoke Write-Host -Times 1 -Exactly -ParameterFilter { $Object -like '*does not invoke that named remediation*' }
    }

    It 'does not unlock final ownership after negative application confirmation' {
        $script:device.Steps.K = @{ CompletionState = 'TechnicianConfirmed' }
        $script:device.Steps.J = @{ CompletionState = 'Verified' }
        Mock Read-ValidatedInput { return 'N' }
        $step = $script:manifestSteps | Where-Object { $_.Id -eq 'L' }
        $result = Invoke-AutopilotManifestStep -Device $script:device -StepDefinition $step
        Write-ManifestStepResult -Device $script:device -StepDefinition $step -Result $result
        $updates = $script:manifestSteps | Where-Object { $_.Id -eq 'N' }
        $ownership = $script:manifestSteps | Where-Object { $_.Id -eq 'O' }
        (Test-ManifestStepEligibility -Device $script:device -StepDefinition $updates).Eligible | Should -BeFalse
        (Test-ManifestStepEligibility -Device $script:device -StepDefinition $ownership).Eligible | Should -BeFalse
    }

    It 'unlocks final ownership only after updates and shutdown confirmation' {
        $script:device.Steps.J = @{ CompletionState = 'Verified' }
        $ownership = $script:manifestSteps | Where-Object { $_.Id -eq 'O' }
        (Test-ManifestStepEligibility -Device $script:device -StepDefinition $ownership).Eligible | Should -BeFalse
        $script:device.Steps.N = @{ CompletionState = 'TechnicianConfirmed' }
        (Test-ManifestStepEligibility -Device $script:device -StepDefinition $ownership).Eligible | Should -BeTrue
    }

    It 'keeps post-login Demo confirmations simulated: <StepId>' -TestCases @(
        @{ StepId = 'K'; Prerequisites = @('I', 'J', 'H') }
        @{ StepId = 'L'; Prerequisites = @('K') }
        @{ StepId = 'N'; Prerequisites = @('L') }
    ) {
        param($StepId, $Prerequisites)
        $script:Runtime.IsDemoMode = $true
        foreach ($prerequisite in $Prerequisites) { $script:device.Steps[$prerequisite] = @{ CompletionState = 'Simulated' } }
        $step = $script:manifestSteps | Where-Object { $_.Id -eq $StepId }
        (Invoke-AutopilotManifestStep -Device $script:device -StepDefinition $step).CompletionState | Should -Be 'Simulated'
    }
}

Describe 'Recovery close-out and restart' {
    BeforeEach {
        $script:Runtime = @{ IsDemoMode = $false; ModeDisplayName = 'Live' }
        $script:GraphSession = @{ Connected = $true; IsSimulated = $false; TenantId = $script:fixtureTenantId }
        Mock Get-MgContext { return @{ TenantId = $script:fixtureTenantId } }
        $script:device = @{
            TenantId = $script:fixtureTenantId
            Serial = 'SERIAL1'; AutopilotDeviceId = 'auto-1'; RecoveryActive = $true
            RecoveryStartedAt = (Get-Date).AddMinutes(-10); RecoveryReason = 'Setup failed'; RecoveryHistory = @()
            Steps = @{ A = @{ CompletionState = 'Verified' }; P = @{ CompletionState = 'Submitted'; Timestamp = (Get-Date).AddMinutes(-3) }; L = @{ CompletionState = 'TechnicianConfirmed' } }
            Status = 'in-progress'; ManagedDeviceId = 'old-id'; IntuneDeviceName = 'Old name'
            TechnicianUserPrincipalName = 'old@example.invalid'; FinalPrimaryUserId = 'old-user'
            FinalPrimaryUserPrincipalName = 'old@example.invalid'; FinalPrimaryUserDisplayName = 'Old user'
            CompletedAt = [DateTime]::MinValue; CompletedBy = ''; IsCompletionVerified = $false
        }
        $script:recoveryStep = $script:manifestSteps | Where-Object { $_.Id -eq 'Q' }
        Mock Read-ValidatedInput { return 'Y' }
        Mock Write-Host {}
        Mock Write-AutopilotExpressLog {}
        Mock Resolve-LiveManagedDeviceBySerial { return $null }
        Mock Resolve-LiveAutopilotContext { throw 'A submitted unblock must not refresh for another write.' }
        Mock Invoke-GraphApiRequest { throw 'A submitted unblock must not be sent again.' }
    }
    It 'preserves recovery timestamps and scalar evidence through repeated JSON normalisation' {
        $saved = $script:device | ConvertTo-Json -Depth 15 | ConvertFrom-Json
        $normalised = ConvertTo-NormalisedValue -Value $saved
        $script:device = ConvertTo-NormalisedValue -Value ($normalised | ConvertTo-Json -Depth 15 | ConvertFrom-Json)
        $script:device.Steps.P.Timestamp | Should -BeOfType ([string])
        $script:device.RecoveryActive | Should -BeOfType ([bool])
        $result = Invoke-AutopilotManifestStep -Device $script:device -StepDefinition $script:recoveryStep
        $result.CompletionState | Should -Be 'TechnicianConfirmed'
        Write-ManifestStepResult -Device $script:device -StepDefinition $script:recoveryStep -Result $result
        $reloaded = ConvertTo-NormalisedValue -Value ($script:device | ConvertTo-Json -Depth 15 | ConvertFrom-Json)
        $reloaded.RecoveryHistory[0].Timestamp | Should -BeOfType ([string])
        (ConvertTo-RecordDate -Value $reloaded.RecoveryHistory[0].Timestamp) | Should -Not -Be ([DateTime]::MinValue)
    }
    It 'preserves an evidence array of <Count> items' -TestCases @(
        @{ Count = 0; Items = @() }
        @{ Count = 1; Items = @('One') }
        @{ Count = 2; Items = @('One', 'Two') }
    ) {
        param($Count, $Items)
        $normalised = ConvertTo-NormalisedValue -Value @{ Items = $Items }
        ($normalised.Items -is [array]) | Should -BeTrue
        $normalised.Items.Count | Should -Be $Count
        $reloaded = ConvertTo-NormalisedValue -Value ($normalised | ConvertTo-Json -Depth 5 | ConvertFrom-Json)
        ($reloaded.Items -is [array]) | Should -BeTrue
        $reloaded.Items.Count | Should -Be $Count
    }
    It 'requires an unblock submission before prompting' {
        $script:device.Steps.P = $null
        (Invoke-AutopilotManifestStep -Device $script:device -StepDefinition $script:recoveryStep).CompletionState | Should -Be 'Blocked'
        Should -Invoke Read-ValidatedInput -Times 0 -Exactly
    }
    It 'requires the two-minute wait without sleeping or mutating progress' {
        $script:device.Steps.P.Timestamp = Get-Date
        $result = Invoke-AutopilotManifestStep -Device $script:device -StepDefinition $script:recoveryStep
        $result.CompletionState | Should -Be 'Blocked'
        $script:device.Steps.L.CompletionState | Should -Be 'TechnicianConfirmed'
        Should -Invoke Resolve-LiveManagedDeviceBySerial -Times 0 -Exactly
        Should -Invoke Read-ValidatedInput -Times 0 -Exactly
    }
    It 'blocks a manually repeated unblock without changing the saved submission or its wait time' {
        $unblockStep = $script:manifestSteps | Where-Object { $_.Id -eq 'P' }
        $submittedAt = $script:device.Steps.P.Timestamp
        $result = Invoke-AutopilotManifestStep -Device $script:device -StepDefinition $unblockStep
        $result.CompletionState | Should -Be 'Blocked'
        $result.Data.Blocked | Should -BeTrue
        Write-ManifestStepResult -Device $script:device -StepDefinition $unblockStep -Result $result
        $script:device.Steps.P.CompletionState | Should -Be 'Submitted'
        $script:device.Steps.P.Timestamp | Should -Be $submittedAt
        (Invoke-AutopilotManifestStep -Device $script:device -StepDefinition $script:recoveryStep).CompletionState | Should -Be 'TechnicianConfirmed'
        Should -Invoke Resolve-LiveAutopilotContext -Times 0 -Exactly
        Should -Invoke Invoke-GraphApiRequest -Times 0 -Exactly
    }
    It 'directs an earlier recovery timestamp to support without advising another unblock' {
        $script:device.Steps.P.Timestamp = (Get-Date).AddHours(-1)
        $result = Invoke-AutopilotManifestStep -Device $script:device -StepDefinition $script:recoveryStep
        $result.CompletionState | Should -Be 'Failed'
        $result.Notes | Should -Match 'Do not submit P again; preserve the saved evidence and seek recovery support'
        Should -Invoke Resolve-LiveManagedDeviceBySerial -Times 0 -Exactly
        Should -Invoke Invoke-GraphApiRequest -Times 0 -Exactly
    }
    It 'blocks close-out while an Intune record remains' {
        Mock Resolve-LiveManagedDeviceBySerial { return @{ id = 'still-present' } }
        (Invoke-AutopilotManifestStep -Device $script:device -StepDefinition $script:recoveryStep).CompletionState | Should -Be 'Blocked'
        Should -Invoke Read-ValidatedInput -Times 0 -Exactly
    }
    It 'fails closed on a serial read error' {
        Mock Resolve-LiveManagedDeviceBySerial { throw 'Read denied' }
        (Invoke-AutopilotManifestStep -Device $script:device -StepDefinition $script:recoveryStep).CompletionState | Should -Be 'Failed'
    }
    It 'retains progress and active recovery after negative confirmation' {
        Mock Read-ValidatedInput { return 'N' }
        $result = Invoke-AutopilotManifestStep -Device $script:device -StepDefinition $script:recoveryStep
        Write-ManifestStepResult -Device $script:device -StepDefinition $script:recoveryStep -Result $result
        $script:device.RecoveryActive | Should -BeTrue
        $script:device.Steps.L.CompletionState | Should -Be 'TechnicianConfirmed'
        $script:device.RecoveryHistory.Count | Should -Be 0
    }
    It 'archives prior results and restarts from B only after confirmed readiness' {
        $result = Invoke-AutopilotManifestStep -Device $script:device -StepDefinition $script:recoveryStep
        $result.CompletionState | Should -Be 'TechnicianConfirmed'
        $result.Data.AllowedEvidence | Should -Be 'TechnicianConfirmedInIntune'
        Write-ManifestStepResult -Device $script:device -StepDefinition $script:recoveryStep -Result $result
        $script:device.RecoveryActive | Should -BeFalse
        $script:device.RecoveryHistory[0].Steps.L.CompletionState | Should -Be 'TechnicianConfirmed'
        $script:device.Steps.L | Should -BeNullOrEmpty
        $script:device.Steps.A.CompletionState | Should -Be 'Verified'
        $script:device.Steps.P.CompletionState | Should -Be 'Submitted'
        $script:device.FinalPrimaryUserId | Should -Be ''
        $cleanup = $script:manifestSteps | Where-Object { $_.Id -eq 'B' }
        (Test-ManifestStepEligibility -Device $script:device -StepDefinition $cleanup).Eligible | Should -BeTrue
    }
    It 'keeps ordinary device work blocked during recovery but allows cleanup B' {
        $imaging = $script:manifestSteps | Where-Object { $_.Id -eq 'E' }
        $cleanup = $script:manifestSteps | Where-Object { $_.Id -eq 'B' }
        (Test-ManifestStepEligibility -Device $script:device -StepDefinition $imaging).Eligible | Should -BeFalse
        (Test-ManifestStepEligibility -Device $script:device -StepDefinition $cleanup).Eligible | Should -BeTrue
    }
    It 'clears old recovery actions on entry and retains their history' {
        $script:device.RecoveryActive = $false
        $script:device.Steps.Q = @{ CompletionState = 'TechnicianConfirmed' }
        Enter-DeviceRecoveryMode -Device $script:device
        $script:device.RecoveryActive | Should -BeTrue
        $script:device.Steps.P | Should -BeNullOrEmpty
        $script:device.Steps.Q | Should -BeNullOrEmpty
        $script:device.RecoveryHistory[0].Steps.Q.CompletionState | Should -Be 'TechnicianConfirmed'
    }
    It 'keeps Demo recovery simulated without a serial read or real wait' {
        $script:Runtime.IsDemoMode = $true
        $script:device.Steps.P = @{ CompletionState = 'Simulated'; Timestamp = Get-Date }
        $result = Invoke-AutopilotManifestStep -Device $script:device -StepDefinition $script:recoveryStep
        $result.CompletionState | Should -Be 'Simulated'
        Should -Invoke Resolve-LiveManagedDeviceBySerial -Times 0 -Exactly
    }
    It 'offers recovery close-out rather than repeating a submitted unblock as the next bench action' {
        Mock Get-EnabledManifestSteps { return @($script:manifestSteps | Where-Object { $_.Id -in @('P', 'Q') }) }
        $eligible = @(Get-EligibleManifestSteps -Device $script:device)
        $eligible.Count | Should -Be 1
        $eligible[0].Id | Should -Be 'Q'
        $unblockStep = $script:manifestSteps | Where-Object { $_.Id -eq 'P' }
        (Test-ManifestStepEligibility -Device $script:device -StepDefinition $unblockStep).Eligible | Should -BeTrue
    }
}