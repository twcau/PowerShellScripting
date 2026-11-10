<#
.SYNOPSIS
    Checks completion safety for failed, cancelled and successful operations.
.DESCRIPTION
    Extracts the current result factory, final-owner handler, dispatcher, writer
    and completion gates without starting the CLI. The current manifest supplies
    prerequisites and activation requirements. Tenant calls, selection, guidance
    and recent-user persistence are mocked; no operational records are accessed.
    Requires Pester 5 and FullLanguage for source parsing.
.FILECREATED
    2026-10-08
.FILELASTUPDATED
    2026-10-11
#>
BeforeAll {
    $sourcePath = Join-Path (Split-Path -Parent $PSScriptRoot) 'autopilot-express.ps1'
    $tokens = $null
    $parseErrors = $null
    $sourceAst = [System.Management.Automation.Language.Parser]::ParseFile($sourcePath, [ref]$tokens, [ref]$parseErrors)
    if ($parseErrors.Count) { throw ($parseErrors.Message -join '; ') }
    foreach ($functionName in @(
            'New-EmptyDeviceRecord', 'New-OperationResult', 'ConvertTo-NormalisedValue', 'ConvertTo-StepHashtable', 'Test-AttemptEvidenceEqual',
            'Get-ManifestActionStepId', 'Get-LiveTenantBinding', 'Invoke-StepAssignFinalPrimaryUser',
            'Invoke-AutopilotManifestStep', 'Get-AffectedWorkflowStepId', 'Write-ManifestStepResult',
            'Test-ManifestStepAttempted', 'Test-ManifestStepCompleted',
            'Test-CompletionStateComplete', 'Get-ManifestStepPrerequisiteIds',
            'Test-ManifestStepEligibility', 'Get-EligibleManifestSteps', 'Get-NextStepId',
            'Get-DispatchBlockingManifestSteps', 'Test-DeviceReadyForDispatch', 'Get-DeviceFeedbackContext', 'Complete-DeviceDispatch',
            'Start-DeviceDocumentJob',
            'Invoke-DeviceInventoryCheck', 'Get-IntuneInventoryFieldSetVersion', 'ConvertTo-RecordDate', 'Test-DeviceInventoryEligible'
        )) {
        $definition = $sourceAst.Find({ param($node) $node -is [System.Management.Automation.Language.FunctionDefinitionAst] -and $node.Name -eq $functionName }, $true)
        if ($null -eq $definition) { throw ('Missing function: {0}' -f $functionName) }
        Set-Item -Path ('Function:{0}' -f $definition.Name) -Value $definition.Body.GetScriptBlock()
    }
    function Get-EnabledManifestSteps { return $script:manifestSteps }
    function Get-MgContext { throw 'Unexpected Graph context lookup.' }
    $script:fixtureTenantId = '11111111-2222-3333-4444-555555555555'
    function Select-DirectoryUser { throw 'Unexpected directory selection.' }
    function Write-UserDeviceRecords { param($Records) throw ('Unexpected dispatch save: {0}' -f @($Records).Count) }
    function Get-LiveDeviceInventory { param($Device) throw ('Unexpected dispatch inventory read: {0}' -f $Device.Serial) }
    function Add-RecentUser { param($User) throw ('Unexpected recent-user save: {0}' -f $User.UserPrincipalName) }
    function Invoke-LivePrimaryUserAssignment {
        param($Device, $User)
        throw ('Unexpected tenant assignment: {0}, {1}' -f $Device.Serial, $User.UserPrincipalName)
    }
    function Show-ChecklistHandoffGuide { param($Device) throw ('Unexpected handoff guide: {0}' -f $Device.Serial) }
    function Write-AutopilotExpressLog { param($Message, $Level) throw ('Unexpected log: {0}: {1}' -f $Level, $Message) }
    function Read-ValidatedInput {
        param($Prompt, $Default, $Type, $Choices)
        throw ('Unexpected prompt: {0}; default {1}; type {2}; choices {3}' -f $Prompt, $Default, $Type, ($Choices -join ','))
    }
    $manifestPath = Join-Path (Split-Path -Parent $PSScriptRoot) 'autopilot-express.manifest.json'
    $manifest = Get-Content -LiteralPath $manifestPath -Raw | ConvertFrom-Json
    $script:manifestSteps = @($manifest.steps | Where-Object enabled | ForEach-Object {
            @{
                Id = $_.id; ActionName = $_.actionName; DisplayName = $_.displayName
                PrerequisiteStepIds = @($_.prerequisiteStepIds)
                ActivationRequirement = if ($_.activationRequirement) { $_.activationRequirement } else { 'None' }
            }
        })
}

Describe 'Short-circuit next-step selection' {
    BeforeEach {
        $script:selectionDevice = New-EmptyDeviceRecord
        $script:selectionSteps = @(
            @{ Id = 'A'; ActionName = 'First' }, @{ Id = 'B'; ActionName = 'Second' }, @{ Id = 'C'; ActionName = 'Third' }
        )
        Mock Get-EnabledManifestSteps { return $script:selectionSteps }
        Mock Test-ManifestStepCompleted { return $false }
        Mock Test-ManifestStepEligibility { return @{ Eligible = $true } }
    }
    It 'evaluates only the first eligible action for a next-step display' {
        Get-NextStepId -Device $script:selectionDevice | Should -BeExactly A
        Should -Invoke Test-ManifestStepEligibility -Times 1 -Exactly -ParameterFilter { $StepDefinition.Id -eq 'A' }
        Should -Invoke Test-ManifestStepCompleted -Times 1 -Exactly
    }
    It 'still returns every eligible action in manifest order for menus' {
        $steps = @(Get-EligibleManifestSteps -Device $script:selectionDevice)
        ($steps.Id -join ',') | Should -BeExactly 'A,B,C'
        Should -Invoke Test-ManifestStepEligibility -Times 3 -Exactly
    }
    It 'continues past an ineligible prerequisite without evaluating later actions unnecessarily' {
        Mock Test-ManifestStepEligibility { return @{ Eligible = ($StepDefinition.Id -ne 'A') } }
        Get-NextStepId -Device $script:selectionDevice | Should -BeExactly B
        Should -Invoke Test-ManifestStepEligibility -Times 2 -Exactly
    }
    It 'skips completed actions without reevaluating their prerequisites' {
        Mock Test-ManifestStepCompleted { return $StepId -eq 'A' }
        Get-NextStepId -Device $script:selectionDevice | Should -BeExactly B
        Should -Invoke Test-ManifestStepEligibility -Times 1 -Exactly -ParameterFilter { $StepDefinition.Id -eq 'B' }
    }
    It 'does not repeat a recovery unblock awaiting confirmation' {
        $script:selectionDevice.RecoveryActive = $true
        $script:selectionDevice.Steps.A = @{ CompletionState = 'Submitted' }
        $script:selectionSteps[0].ActionName = 'ClearUserlessEnrollmentStatus'
        Get-NextStepId -Device $script:selectionDevice | Should -BeExactly B
        Should -Invoke Test-ManifestStepCompleted -Times 0 -Exactly -ParameterFilter { $StepId -eq 'A' }
    }
    It 'returns no next step after checking all blocked actions without inventing eligibility' {
        Mock Test-ManifestStepEligibility { return @{ Eligible = $false } }
        Get-NextStepId -Device $script:selectionDevice | Should -BeNullOrEmpty
        Should -Invoke Test-ManifestStepEligibility -Times 3 -Exactly
    }
}

Describe 'Operation completion safety' {
    BeforeEach {
        $script:Runtime = @{ IsDemoMode = $true; ModeDisplayName = 'Demo' }
        $script:GraphSession = @{ Connected = $true; IsSimulated = $false; TenantId = $script:fixtureTenantId }
        Mock Get-MgContext { return @{ TenantId = $script:fixtureTenantId } }
        $script:device = New-EmptyDeviceRecord
        $script:device.TenantId = $script:fixtureTenantId
        $script:device.Serial = 'COMPLETION-SAFETY-01'
        $script:device.AutopilotDeviceId = 'synthetic-autopilot-id'
        $script:device.RecoveryActive = $false
        $script:finalStep = $script:manifestSteps | Where-Object ActionName -eq AssignFinalPrimaryUser
        foreach ($definition in $script:manifestSteps) {
            if ($definition.ActivationRequirement -eq 'None' -and $definition.Id -ne $script:finalStep.Id) {
                $script:device.Steps[$definition.Id] = @{ CompletionState = 'Verified' }
            }
        }
        Mock Select-DirectoryUser { return $null }
        Mock Add-RecentUser {}
        Mock Invoke-LivePrimaryUserAssignment { throw 'Unexpected tenant assignment in completion-safety tests.' }
        Mock Show-ChecklistHandoffGuide {}
        Mock Write-AutopilotExpressLog {}
        Mock Write-Host {}
    }

    It 'defaults an unsuccessful Demo operation to Failed rather than Simulated' {
        $result = New-OperationResult -ActionName $script:finalStep.ActionName -Success $false
        $result.Success | Should -BeFalse
        $result.IsSimulated | Should -BeTrue
        $result.CompletionState | Should -Be 'Failed'
        Test-CompletionStateComplete -CompletionState $result.CompletionState | Should -BeFalse
    }

    It 'defaults a successful Demo operation to Simulated' {
        $result = New-OperationResult -ActionName $script:finalStep.ActionName -Success $true
        $result.Success | Should -BeTrue
        $result.IsSimulated | Should -BeTrue
        $result.CompletionState | Should -Be 'Simulated'
        Test-CompletionStateComplete -CompletionState $result.CompletionState | Should -BeTrue
    }

    It 'does not promote a successful Live request without verification to completion' {
        $script:Runtime = @{ IsDemoMode = $false; ModeDisplayName = 'Live' }
        $result = New-OperationResult -ActionName $script:finalStep.ActionName -Success $true
        $result.CompletionState | Should -Be 'Submitted'
        Write-ManifestStepResult -Device $script:device -StepDefinition $script:finalStep -Result $result
        Test-ManifestStepCompleted -Device $script:device -StepId $script:finalStep.Id | Should -BeFalse
        (Test-DeviceReadyForDispatch -Device $script:device).Ready | Should -BeFalse
        Should -Invoke Show-ChecklistHandoffGuide -Times 0 -Exactly
    }

    It 'refuses explicit Verified without action-specific read-back evidence' {
        $script:Runtime = @{ IsDemoMode = $false; ModeDisplayName = 'Live' }
        foreach ($action in @('ResolveAutopilotDevice', 'ApplyGroupTag', 'AddToPreProvisioningGroup', 'RemoveFromPreProvisioningGroup', 'AssignFinalPrimaryUser', 'UnsupportedAction')) {
            $result = New-OperationResult -ActionName $action -Success $true -CompletionState Verified -Data @{}
            $result.CompletionState | Should -Be 'Submitted'
            $result.Success | Should -BeFalse
        }
    }

    It 'rechecks hand-built Verified claims at the persistence boundary' {
        $script:Runtime = @{ IsDemoMode = $false; ModeDisplayName = 'Live' }
        $result = @{ Success = $true; CompletionState = 'Verified'; Summary = 'Write accepted'; Notes = ''; Data = @{} }
        Write-ManifestStepResult -Device $script:device -StepDefinition $script:finalStep -Result $result
        $script:device.Steps.O.CompletionState | Should -Be 'Submitted'
        Test-ManifestStepCompleted -Device $script:device -StepId O | Should -BeFalse
        (Test-DeviceReadyForDispatch -Device $script:device).Ready | Should -BeFalse
    }

    It 'refuses contradictory tag or membership observations' {
        $script:Runtime.IsDemoMode = $false
        $cases = @(
            @{ Action = 'ApplyGroupTag'; Data = @{ AutopilotDeviceId = 'auto-1'; VerificationAttempts = 1; GroupTag = 'EXPECTED'; ObservedGroupTag = 'expected' } }
            @{ Action = 'AddToPreProvisioningGroup'; Data = @{ GroupId = 'group-1'; DirectoryObjectId = 'device-1'; VerificationAttempts = 1; ExpectedMember = $true; ObservedMember = $false } }
            @{ Action = 'RemoveFromPreProvisioningGroup'; Data = @{ GroupId = 'group-1'; DirectoryObjectId = 'device-1'; VerificationAttempts = 1; ExpectedMember = $false; ObservedMember = $true } }
            @{ Action = 'ResolveAutopilotDevice'; Data = @{ Serial = 'SERIAL1'; ObservedSerial = 'OTHER'; AutopilotDeviceId = 'auto-1'; VerificationAttempts = 1 } }
        )
        foreach ($case in $cases) {
            $result = New-OperationResult -ActionName $case.Action -Success $true -CompletionState Verified -Data $case.Data
            $result.CompletionState | Should -Be Submitted
            $result.Success | Should -BeFalse
        }
    }

    It 'persists cancelled final ownership as attempted but incomplete and blocks dispatch' {
        $script:finalStep.Id | Should -Be 'O'
        foreach ($definition in $script:manifestSteps) {
            if ($definition.ActivationRequirement -eq 'None' -and $definition.Id -ne $script:finalStep.Id) {
                Test-ManifestStepCompleted -Device $script:device -StepId $definition.Id | Should -BeTrue
            }
        }
        (Test-ManifestStepEligibility -Device $script:device -StepDefinition $script:finalStep).Eligible | Should -BeTrue
        $result = Invoke-StepAssignFinalPrimaryUser -Device $script:device -StepDefinition $script:finalStep
        $result.Success | Should -BeFalse
        $result.CompletionState | Should -Be 'Failed'
        $result.Summary | Should -BeLike '*cancelled*'
        Write-ManifestStepResult -Device $script:device -StepDefinition $script:finalStep -Result $result
        Test-ManifestStepAttempted -Device $script:device -StepId O | Should -BeTrue
        Test-ManifestStepCompleted -Device $script:device -StepId O | Should -BeFalse
        $script:device.Steps.O.CompletionState | Should -Be 'Failed'
        $script:device.Status | Should -Not -Be 'completed'
        $readiness = Test-DeviceReadyForDispatch -Device $script:device
        $readiness.Ready | Should -BeFalse
        $readiness.BlockingStepIds | Should -Contain 'O'
        Should -Invoke Select-DirectoryUser -Times 1 -Exactly
        Should -Invoke Add-RecentUser -Times 0 -Exactly
        Should -Invoke Invoke-LivePrimaryUserAssignment -Times 0 -Exactly
        Should -Invoke Show-ChecklistHandoffGuide -Times 0 -Exactly
    }

    It 'keeps an unsupported Demo dispatcher action failed and non-dispatchable' {
        $unsupportedStep = ConvertTo-NormalisedValue -Value $script:finalStep
        $unsupportedStep.ActionName = 'UnsupportedCompletionSafetyAction'
        $result = Invoke-AutopilotManifestStep -Device $script:device -StepDefinition $unsupportedStep
        $result.Success | Should -BeFalse
        $result.CompletionState | Should -Be 'Failed'
        $result.Summary | Should -BeLike '*not yet implemented*'
        Write-ManifestStepResult -Device $script:device -StepDefinition $unsupportedStep -Result $result
        Test-ManifestStepCompleted -Device $script:device -StepId $unsupportedStep.Id | Should -BeFalse
        (Test-DeviceReadyForDispatch -Device $script:device).Ready | Should -BeFalse
        Should -Invoke Select-DirectoryUser -Times 0 -Exactly
        Should -Invoke Invoke-LivePrimaryUserAssignment -Times 0 -Exactly
    }

    It 'preserves explicit Submitted evidence despite the unsuccessful Demo default' {
        $result = New-OperationResult -ActionName $script:finalStep.ActionName -Success $false -CompletionState Submitted
        $result.CompletionState | Should -Be 'Submitted'
        Test-CompletionStateComplete -CompletionState $result.CompletionState | Should -BeFalse
        Write-ManifestStepResult -Device $script:device -StepDefinition $script:finalStep -Result $result
        $script:device.Steps[$script:finalStep.Id].CompletionState | Should -Be 'Submitted'
        Test-ManifestStepAttempted -Device $script:device -StepId $script:finalStep.Id | Should -BeTrue
        Test-ManifestStepCompleted -Device $script:device -StepId $script:finalStep.Id | Should -BeFalse
        (Test-DeviceReadyForDispatch -Device $script:device).Ready | Should -BeFalse
        Should -Invoke Show-ChecklistHandoffGuide -Times 0 -Exactly
    }

    It 'keeps successful Live final ownership Verified using only synthetic assignment evidence' {
        $script:Runtime = @{ IsDemoMode = $false; ModeDisplayName = 'Live' }
        Mock Select-DirectoryUser { return @{ Id = 'synthetic-user-id'; UserPrincipalName = 'E1@example.invalid'; DisplayName = 'Synthetic owner' } }
        Mock Invoke-LivePrimaryUserAssignment {
            return @{ AnyAssignmentApplied = $true; AutopilotAssigned = $true; ManagedDeviceAssigned = $true; ManagedDeviceConfirmed = $true; Notes = @(); Errors = @() }
        }
        (New-OperationResult -ActionName $script:finalStep.ActionName -Success $true).CompletionState | Should -Be 'Submitted'
        $result = Invoke-AutopilotManifestStep -Device $script:device -StepDefinition $script:finalStep
        $result.Success | Should -BeTrue
        $result.IsSimulated | Should -BeFalse
        $result.CompletionState | Should -Be 'Verified'
        Write-ManifestStepResult -Device $script:device -StepDefinition $script:finalStep -Result $result
        Test-ManifestStepCompleted -Device $script:device -StepId $script:finalStep.Id | Should -BeTrue
        (Test-DeviceReadyForDispatch -Device $script:device).Ready | Should -BeTrue
        Should -Invoke Add-RecentUser -Times 1 -Exactly
        Should -Invoke Invoke-LivePrimaryUserAssignment -Times 1 -Exactly -ParameterFilter { $Device.Serial -eq 'COMPLETION-SAFETY-01' -and $User.Id -eq 'synthetic-user-id' }
        Should -Invoke Show-ChecklistHandoffGuide -Times 1 -Exactly
    }
}

Describe 'Completed prerequisite retry safety' {
    BeforeEach {
        $script:savedManifestSteps = $script:manifestSteps
        $script:Runtime = @{ IsDemoMode = $false; ModeDisplayName = 'Live' }
        $script:GraphSession = @{ Connected = $true; IsSimulated = $false; TenantId = $script:fixtureTenantId }
        Mock Get-MgContext { return @{ TenantId = $script:fixtureTenantId } }
        $script:device = New-EmptyDeviceRecord
        $script:device.TenantId = $script:fixtureTenantId
        $script:device.Serial = 'RETRY-SAFETY-01'
        $script:device.AutopilotDeviceId = 'synthetic-autopilot-id'
        $script:device.RecoveryActive = $false
        $script:device.Status = 'completed'
        $script:device.CompletedAt = [datetime]'2026-10-01T10:00:00Z'
        $script:device.CompletedBy = 'synthetic-technician'
        $script:device.IsCompletionVerified = $true
        foreach ($definition in $script:manifestSteps) {
            $script:device.Steps[$definition.Id] = @{
                CompletionState = 'Verified'; Completed = $true; Success = $true
                Timestamp = '2026-10-01T09:00:00.0000000Z'; Summary = ('Original evidence for {0}' -f $definition.Id)
                Notes = @('Synthetic technician evidence'); Mode = 'Live'; ActionName = $definition.ActionName
                IsSimulated = $false; Data = @{ EvidenceId = $definition.Id; Checklist = @('first', 'second') }
            }
        }
        $script:baselineSteps = ConvertTo-NormalisedValue -Value $script:device.Steps
        $script:applicationStep = $script:manifestSteps | Where-Object ActionName -eq ConfirmApplicationBaseline
        Mock Show-ChecklistHandoffGuide {}
        Mock Write-AutopilotExpressLog {}
        Mock Write-Host {}
    }

    AfterEach {
        $script:manifestSteps = $script:savedManifestSteps
    }

    It 'invalidates P and J after a completed O retry returns <State>, retaining evidence after reconfirmation' -ForEach @(
        @{ State = 'Submitted'; Success = $true }
        @{ State = 'Failed'; Success = $false }
    ) {
        $script:applicationStep.Id | Should -Be 'L'
        (Test-DeviceReadyForDispatch -Device $script:device).Ready | Should -BeTrue
        $result = New-OperationResult -ActionName $script:applicationStep.ActionName -Success $Success -CompletionState $State
        Write-ManifestStepResult -Device $script:device -StepDefinition $script:applicationStep -Result $result
        $script:device.Steps.L.CompletionState | Should -Be $State
        $script:device.Steps.L.Completed | Should -BeFalse
        Test-ManifestStepCompleted -Device $script:device -StepId L | Should -BeFalse
        foreach ($stepId in @('N', 'O')) {
            $evidence = $script:device.Steps[$stepId]
            $evidence.CompletionState | Should -Be 'Blocked'
            $evidence.Completed | Should -BeFalse
            $evidence.Success | Should -BeFalse
            $evidence.PreviousCompletionState | Should -Be 'Verified'
            $evidence.InvalidatedBy | Should -Be 'L'
            { [datetime]::Parse($evidence.InvalidatedAt) } | Should -Not -Throw
            foreach ($field in @('Timestamp', 'Summary', 'Notes', 'Mode', 'ActionName', 'IsSimulated', 'Data')) {
                Test-AttemptEvidenceEqual -Left $evidence[$field] -Right $script:baselineSteps[$stepId][$field] | Should -BeTrue -Because ('retained {0}/{1} evidence must match structurally' -f $stepId, $field)
            }
        }
        $script:device.Status | Should -Be 'in-progress'
        $script:device.CompletedAt | Should -Be ([datetime]::MinValue)
        $script:device.CompletedBy | Should -BeNullOrEmpty
        $script:device.IsCompletionVerified | Should -BeFalse
        $blockedEvidence = ConvertTo-NormalisedValue -Value $script:device.Steps
        $result = New-OperationResult -ActionName $script:applicationStep.ActionName -Success $true -CompletionState TechnicianConfirmed
        Write-ManifestStepResult -Device $script:device -StepDefinition $script:applicationStep -Result $result
        Test-ManifestStepCompleted -Device $script:device -StepId L | Should -BeTrue
        $readiness = Test-DeviceReadyForDispatch -Device $script:device
        $readiness.Ready | Should -BeFalse
        foreach ($stepId in @('N', 'O')) {
            $readiness.BlockingStepIds | Should -Contain $stepId
            Test-ManifestStepCompleted -Device $script:device -StepId $stepId | Should -BeFalse
            $script:device.Steps[$stepId].Count | Should -Be $blockedEvidence[$stepId].Count
            foreach ($field in $blockedEvidence[$stepId].Keys) {
                Test-AttemptEvidenceEqual -Left $script:device.Steps[$stepId][$field] -Right $blockedEvidence[$stepId][$field] | Should -BeTrue -Because ('blocked {0}/{1} evidence must remain unchanged' -f $stepId, $field)
            }
        }
        Should -Invoke Show-ChecklistHandoffGuide -Times 0 -Exactly
    }

    It 'invalidates completed P and J even when the O retry succeeds' {
        $result = New-OperationResult -ActionName $script:applicationStep.ActionName -Success $true -CompletionState TechnicianConfirmed
        Write-ManifestStepResult -Device $script:device -StepDefinition $script:applicationStep -Result $result
        $script:device.Steps.L.Completed | Should -BeTrue
        Test-ManifestStepCompleted -Device $script:device -StepId L | Should -BeTrue
        foreach ($stepId in @('N', 'O')) {
            $script:device.Steps[$stepId].CompletionState | Should -Be 'Blocked'
            $script:device.Steps[$stepId].Completed | Should -BeFalse
            $script:device.Steps[$stepId].Success | Should -BeFalse
            $script:device.Steps[$stepId].InvalidatedBy | Should -Be 'L'
        }
        (Test-DeviceReadyForDispatch -Device $script:device).Ready | Should -BeFalse
    }

    It 'follows renamed prerequisite IDs transitively when children precede parents' {
        $script:manifestSteps = @(
            @{ Id = 'leaf-renamed'; ActionName = 'SyntheticLeaf'; ActivationRequirement = 'None'; PrerequisiteStepIds = @('middle-renamed') }
            @{ Id = 'middle-renamed'; ActionName = 'SyntheticMiddle'; ActivationRequirement = 'None'; PrerequisiteStepIds = @('root-renamed') }
            @{ Id = 'root-renamed'; ActionName = 'SyntheticRoot'; ActivationRequirement = 'None'; PrerequisiteStepIds = @() }
        )
        $script:device.Steps = @{}
        foreach ($definition in $script:manifestSteps) {
            $script:device.Steps[$definition.Id] = @{ CompletionState = 'Verified'; Completed = $true; Success = $true }
        }
        (Test-DeviceReadyForDispatch -Device $script:device).Ready | Should -BeTrue
        $root = $script:manifestSteps | Where-Object Id -eq 'root-renamed'
        $result = New-OperationResult -ActionName $root.ActionName -Success $true -CompletionState TechnicianConfirmed
        Write-ManifestStepResult -Device $script:device -StepDefinition $root -Result $result
        $script:device.Steps[$root.Id].Completed | Should -BeTrue
        foreach ($stepId in @('middle-renamed', 'leaf-renamed')) {
            $script:device.Steps[$stepId].CompletionState | Should -Be 'Blocked'
            $script:device.Steps[$stepId].Completed | Should -BeFalse
            $script:device.Steps[$stepId].Success | Should -BeFalse
            $script:device.Steps[$stepId].PreviousCompletionState | Should -Be 'Verified'
            $script:device.Steps[$stepId].InvalidatedBy | Should -Be $root.Id
            Test-ManifestStepCompleted -Device $script:device -StepId $stepId | Should -BeFalse
        }
        (Test-DeviceReadyForDispatch -Device $script:device).Ready | Should -BeFalse
    }

    It 'leaves every unrelated manifest branch unchanged on O retry' {
        $result = New-OperationResult -ActionName $script:applicationStep.ActionName -Success $false -CompletionState Failed
        Write-ManifestStepResult -Device $script:device -StepDefinition $script:applicationStep -Result $result
        foreach ($definition in $script:manifestSteps | Where-Object { $_.Id -notin @('L', 'N', 'O') }) {
            $script:device.Steps[$definition.Id].Count | Should -Be $script:baselineSteps[$definition.Id].Count
            foreach ($field in $script:baselineSteps[$definition.Id].Keys) {
                Test-AttemptEvidenceEqual -Left $script:device.Steps[$definition.Id][$field] -Right $script:baselineSteps[$definition.Id][$field] | Should -BeTrue -Because ('unrelated {0}/{1} evidence must remain unchanged' -f $definition.Id, $field)
            }
        }
        $script:device.Steps.M.CompletionState | Should -Be 'Verified'
    }

    It 'does not invalidate existing descendant evidence on a first-time O result' {
        $script:device.Steps.Remove($script:applicationStep.Id)
        Test-ManifestStepAttempted -Device $script:device -StepId L | Should -BeFalse
        $result = New-OperationResult -ActionName $script:applicationStep.ActionName -Success $true -CompletionState TechnicianConfirmed
        Write-ManifestStepResult -Device $script:device -StepDefinition $script:applicationStep -Result $result
        foreach ($stepId in @('N', 'O')) {
            $script:device.Steps[$stepId].Count | Should -Be $script:baselineSteps[$stepId].Count
            foreach ($field in $script:baselineSteps[$stepId].Keys) {
                Test-AttemptEvidenceEqual -Left $script:device.Steps[$stepId][$field] -Right $script:baselineSteps[$stepId][$field] | Should -BeTrue -Because ('first-time retry must retain {0}/{1} evidence' -f $stepId, $field)
            }
            $script:device.Steps[$stepId].ContainsKey('InvalidatedBy') | Should -BeFalse
        }
        (Test-DeviceReadyForDispatch -Device $script:device).Ready | Should -BeTrue
    }

    It 'preserves blocked evidence and dispatch safety through the actual JSON step normalisers' {
        $result = New-OperationResult -ActionName $script:applicationStep.ActionName -Success $true -CompletionState Submitted
        Write-ManifestStepResult -Device $script:device -StepDefinition $script:applicationStep -Result $result
        $beforeReload = ConvertTo-NormalisedValue -Value $script:device.Steps
        $json = $script:device.Steps | ConvertTo-Json -Depth 30
        $script:device.Steps = ConvertTo-StepHashtable -Value ($json | ConvertFrom-Json)
        $script:device.Steps | Should -BeOfType [hashtable]
        $script:device.Steps.L.CompletionState | Should -Be 'Submitted'
        $script:device.Steps.L.Completed | Should -BeFalse
        Test-ManifestStepCompleted -Device $script:device -StepId O | Should -BeFalse
        foreach ($stepId in @('N', 'O')) {
            $evidence = $script:device.Steps[$stepId]
            foreach ($field in @('CompletionState', 'Completed', 'Success', 'PreviousCompletionState', 'InvalidatedBy', 'InvalidatedAt', 'Timestamp', 'Summary', 'Notes', 'Mode', 'ActionName', 'IsSimulated', 'Data')) {
                Test-AttemptEvidenceEqual -Left $evidence[$field] -Right $beforeReload[$stepId][$field] | Should -BeTrue -Because ('round-tripped {0}/{1} evidence must match structurally' -f $stepId, $field)
            }
            Test-ManifestStepCompleted -Device $script:device -StepId $stepId | Should -BeFalse
        }
        $readiness = Test-DeviceReadyForDispatch -Device $script:device
        $readiness.Ready | Should -BeFalse
        foreach ($stepId in @('L', 'N', 'O')) { $readiness.BlockingStepIds | Should -Contain $stepId }
    }
}

Describe 'Audited administrative dispatch' {
    BeforeEach {
        $script:Runtime = @{ IsDemoMode = $false; ModeDisplayName = 'Live' }
        $script:device = New-EmptyDeviceRecord
        $script:device.Serial = 'OVERRIDE-01'
        $script:device.ConfigItem = 'CI-OVERRIDE'
        $script:device.Status = 'in-progress'
        $script:device.RecoveryActive = $true
        $script:device.Steps.A = @{ CompletionState = 'Submitted'; Data = @{} }
        $script:records = @{ Value = @($script:device) }
        $script:BuildBench = @{ Positions = @(@{ Index = 1; Serial = 'OVERRIDE-01'; ConfigItem = 'CI-OVERRIDE' }) }
        $script:DocumentSession = @{ Enabled = $false }
        Mock Write-Host {}
        Mock Start-DeviceDocumentJob {}
        Mock Write-UserDeviceRecords {}
        Mock Get-LiveDeviceInventory { return $null }
        Mock Read-ValidatedInput { if ($Type -eq 'Choice') { return 'Y' }; return 'Approved administrative closure' }
    }

    AfterEach { $script:DocumentSession = $null }

    It 'reports disabled documents after committed <Action> without queuing a worker' -ForEach @(
        @{ Action = 'D'; UseOverride = $false }, @{ Action = 'DO'; UseOverride = $true }
    ) {
        Mock Test-DeviceReadyForDispatch { return @{ Ready = $true; BlockingStepIds = @() } }
        $outcome = Complete-DeviceDispatch -Records $script:records -Device $script:device -Override:$UseOverride
        $outcome.Completed | Should -BeTrue
        $script:device.DispatchConfirmed | Should -BeTrue
        $script:DocumentSession.Enabled | Should -BeFalse
        Should -Invoke Write-UserDeviceRecords -Times 1 -Exactly
        Should -Invoke Start-DeviceDocumentJob -Times 0 -Exactly
        Should -Invoke Write-Host -Times 1 -Exactly -ParameterFilter {
            $Object -like 'No documents generated:*disabled*Settings*No document job was created*do not redispatch*'
        }
    }

    It 'queues enabled documents only after <Action> has been saved and published' -ForEach @(
        @{ Action = 'D'; UseOverride = $false }, @{ Action = 'DO'; UseOverride = $true }
    ) {
        $script:DocumentSession.Enabled = $true
        Mock Test-DeviceReadyForDispatch { return @{ Ready = $true; BlockingStepIds = @() } }
        Mock Write-UserDeviceRecords {
            $script:device.DispatchConfirmed | Should -BeFalse
            Should -Invoke Start-DeviceDocumentJob -Times 0 -Exactly
        }
        $outcome = Complete-DeviceDispatch -Records $script:records -Device $script:device -Override:$UseOverride
        $outcome.Completed | Should -BeTrue
        Should -Invoke Start-DeviceDocumentJob -Times 1 -Exactly -ParameterFilter { $Device.DispatchConfirmed -eq $true }
        Should -Invoke Write-Host -Times 0 -Exactly -ParameterFilter { $Object -like 'No documents generated:*' }
    }

    It 'retains incomplete evidence and active recovery without claiming Verified' {
        $before = ConvertTo-NormalisedValue -Value $script:device.Steps
        $outcome = Complete-DeviceDispatch -Records $script:records -Device $script:device -Override
        $outcome.Completed | Should -BeTrue
        $script:device.Status | Should -Be 'completed'
        $script:device.IsCompletionVerified | Should -BeFalse
        Test-AttemptEvidenceEqual -Left $script:device.Steps -Right $before | Should -BeTrue
        $script:device.RecoveryActive | Should -BeTrue
        $script:device.RecoveryHistory[-1].Stage | Should -Be 'CompletionOverride'
        $script:device.RecoveryHistory[-1].Reason | Should -Be 'Approved administrative closure'
        $script:device.RecoveryHistory[-1].UnresolvedStepIds | Should -Contain 'A'
        $script:BuildBench.Positions[0].Serial | Should -BeNullOrEmpty
        $script:records.Value.Count | Should -Be 1
        Should -Invoke Read-ValidatedInput -Times 1 -Exactly -ParameterFilter { $Default -eq 'N' }
    }

    It 'does not clear the bench or close the record after a save failure' {
        Mock Write-UserDeviceRecords { throw 'Synthetic dispatch save failure' }
        { Complete-DeviceDispatch -Records $script:records -Device $script:device -Override } | Should -Throw '*dispatch save failure*'
        $script:device.Status | Should -Be 'in-progress'
        $script:device.RecoveryHistory.Count | Should -Be 0
        $script:BuildBench.Positions[0].Serial | Should -Be 'OVERRIDE-01'
    }

    It 'treats No as no operation and retains the device' {
        Mock Read-ValidatedInput { if ($Type -eq 'Choice') { return 'N' }; return 'Reason' }
        (Complete-DeviceDispatch -Records $script:records -Device $script:device -Override).Completed | Should -BeFalse
        Should -Invoke Write-UserDeviceRecords -Times 0 -Exactly
        $script:device.Status | Should -Be 'in-progress'
    }

    It 'refuses normal dispatch with device context while evidence is missing' {
        $outcome = Complete-DeviceDispatch -Records $script:records -Device $script:device
        $outcome.Completed | Should -BeFalse
        $outcome.Summary | Should -BeLike '*Position 1*Serial=OVERRIDE-01*CI=CI-OVERRIDE*'
        Should -Invoke Read-ValidatedInput -Times 0 -Exactly
        Should -Invoke Write-UserDeviceRecords -Times 0 -Exactly
    }

    It 'makes a final read and allows <Action> with an explicit missing-data warning' -ForEach @(
        @{ Action = 'D'; UseOverride = $false }, @{ Action = 'DO'; UseOverride = $true }
    ) {
        if (-not $UseOverride) {
            $script:device.RecoveryActive = $false
            $script:device.AutopilotDeviceId = 'synthetic-autopilot-id'
            foreach ($step in $script:manifestSteps) { if ($step.ActivationRequirement -eq 'None') { $script:device.Steps[$step.Id] = @{ CompletionState = 'Verified' } } }
        }
        $outcome = Complete-DeviceDispatch -Records $script:records -Device $script:device -Override:$UseOverride
        $outcome.Completed | Should -BeTrue
        $outcome.Summary | Should -BeLike '*WARNING*IntuneHostName*EthernetMacAddress*dispatch allowed*'
        $script:device.IntuneInventory.Status | Should -Be 'Pending'
        Should -Invoke Get-LiveDeviceInventory -Times 1 -Exactly
    }

    It 'persists final inventory on the proposal before publishing it to the selected device' {
        Mock Get-LiveDeviceInventory { return @{ IntuneHostName = 'FINAL-PC'; EthernetMacAddress = '10:20:30:40:50:60'; ManagedDeviceId = 'managed-final'; TenantId = ''; LastSyncDateTime = '' } }
        Mock Write-UserDeviceRecords {
            $script:device.IntuneInventory.Count | Should -Be 0
            @($Records)[0].IntuneInventory.IntuneHostName | Should -Be 'FINAL-PC'
        }
        $outcome = Complete-DeviceDispatch -Records $script:records -Device $script:device -Override
        $outcome.Completed | Should -BeTrue
        $script:device.IntuneInventory.IntuneHostName | Should -Be 'FINAL-PC'
        $outcome.Summary | Should -Not -BeLike '*could not obtain*'
    }

    It 'retains the original metadata and bench when final metadata cannot be saved' {
        Mock Get-LiveDeviceInventory { return @{ IntuneHostName = 'FINAL-PC'; EthernetMacAddress = ''; ManagedDeviceId = 'managed-final'; TenantId = ''; LastSyncDateTime = '' } }
        Mock Write-UserDeviceRecords { throw 'Synthetic final metadata save failure' }
        { Complete-DeviceDispatch -Records $script:records -Device $script:device -Override } | Should -Throw '*metadata save failure*'
        $script:device.IntuneInventory.Count | Should -Be 0
        $script:BuildBench.Positions[0].Serial | Should -Be 'OVERRIDE-01'
    }

    It 'does not make an inventory read after dispatch is declined' {
        Mock Read-ValidatedInput { if ($Type -eq 'Choice') { return 'N' }; return 'Reason' }
        $null = Complete-DeviceDispatch -Records $script:records -Device $script:device -Override
        Should -Invoke Get-LiveDeviceInventory -Times 0 -Exactly
    }
}