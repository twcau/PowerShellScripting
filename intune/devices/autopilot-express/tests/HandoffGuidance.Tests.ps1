<#
.SYNOPSIS
    Checks read-only external handoff guidance and its final-ownership trigger.
.DESCRIPTION
    Extracts the actual guide and step writer. Dispatch readiness is isolated;
    no tenant, external-system, physical-device or operational-file actions occur.
#>
BeforeAll {
    $sourcePath = Join-Path (Split-Path -Parent $PSScriptRoot) 'autopilot-express.ps1'
    $tokens = $null
    $parseErrors = $null
    $sourceAst = [System.Management.Automation.Language.Parser]::ParseFile($sourcePath, [ref]$tokens, [ref]$parseErrors)
    if ($parseErrors.Count) { throw ($parseErrors.Message -join '; ') }
    foreach ($functionName in @('New-OperationResult', 'Show-ChecklistHandoffGuide', 'Get-AffectedWorkflowStepId', 'Write-ManifestStepResult', 'ConvertTo-NormalisedValue', 'Test-ManifestStepAttempted', 'Test-ManifestStepCompleted', 'Test-CompletionStateComplete')) {
        $definition = $sourceAst.Find({ param($node) $node -is [System.Management.Automation.Language.FunctionDefinitionAst] -and $node.Name -eq $functionName }, $true)
        if (-not $definition) { throw ('Missing function: {0}' -f $functionName) }
        Set-Item -Path ('Function:{0}' -f $definition.Name) -Value $definition.Body.GetScriptBlock()
    }
    function Test-DeviceReadyForDispatch { param($Device) return @{ Ready = $script:ready; Serial = $Device.Serial } }
}

Describe 'Read-only checklist handoff guidance' {
    BeforeEach {
        $script:Runtime = @{ IsDemoMode = $false; ModeDisplayName = 'Live' }
        $script:ready = $false
        $script:device = @{ Serial = 'HANDOFF-01'; ConfigItem = 'CI-01'; SiteCode = 'MI'; IntuneDeviceName = 'LT-EXAMPLE'; Status = 'in-progress'; Steps = @{}; LastUpdatedAt = $null; LastUpdatedBy = '' }
        $script:step = @{ Id = 'J'; ActionName = 'AssignFinalPrimaryUser' }
        $script:result = @{ Success = $true; CompletionState = 'Verified'; Summary = 'Ownership complete'; Notes = ''; ActionName = 'AssignFinalPrimaryUser'; IsSimulated = $false; Data = @{ AutopilotAssigned = $true; ManagedDeviceConfirmed = $true } }
        Mock Write-Host {}
    }

    It 'shows ZENworks, CMDB and collection/disposal requirements with device context' {
        Show-ChecklistHandoffGuide -Device $script:device
        Should -Invoke Write-Host -Times 1 -Exactly -ParameterFilter { $Object -like '*Actions > Copy Relationships*' }
        Should -Invoke Write-Host -Times 1 -Exactly -ParameterFilter { $Object -like '*Downstream CI*' }
        Should -Invoke Write-Host -Times 1 -Exactly -ParameterFilter { $Object -like '*Do not install the replacement until*' }
        Should -Invoke Write-Host -Times 1 -Exactly -ParameterFilter { $Object -like '*close of business*' }
        Should -Invoke Write-Host -Times 1 -Exactly -ParameterFilter { $Object -like '*LT-EXAMPLE*' }
        Should -Invoke Write-Host -Times 1 -Exactly -ParameterFilter { $Object -like '*do not certify these handoffs*' }
    }

    It 'does not mutate the device or add confirmation evidence' {
        $before = $script:device | ConvertTo-Json -Depth 8
        Show-ChecklistHandoffGuide -Device $script:device
        ($script:device | ConvertTo-Json -Depth 8) | Should -BeExactly $before
        $script:device.Steps.Count | Should -Be 0
    }

    It 'shows guidance after completed final ownership in state <State>' -TestCases @(
        @{ State = 'Verified' }
        @{ State = 'TechnicianConfirmed' }
        @{ State = 'Simulated' }
    ) {
        param($State)
        $script:result.CompletionState = $State
        Write-ManifestStepResult -Device $script:device -StepDefinition $script:step -Result $script:result
        Should -Invoke Write-Host -Times 1 -Exactly -ParameterFilter { $Object -eq 'Remaining checklist handoffs (v1.4, steps 24-26)' }
        $script:device.Steps.Count | Should -Be 1
        $script:device.Steps.J.CompletionState | Should -Be $State
        $script:device.Status | Should -Be 'in-progress'
    }

    It 'does not imply handoff readiness for final ownership in state <State>' -TestCases @(
        @{ State = 'Submitted' }
        @{ State = 'Failed' }
        @{ State = 'Blocked' }
    ) {
        param($State)
        $script:result.CompletionState = $State
        Write-ManifestStepResult -Device $script:device -StepDefinition $script:step -Result $script:result
        Should -Invoke Write-Host -Times 0 -Exactly
    }

    It 'does not show guidance for an unsuccessful result' {
        $script:result.Success = $false
        Write-ManifestStepResult -Device $script:device -StepDefinition $script:step -Result $script:result
        Should -Invoke Write-Host -Times 0 -Exactly
    }

    It 'does not show guidance after an unrelated action' {
        $script:step.ActionName = 'ConfirmReseal'
        Write-ManifestStepResult -Device $script:device -StepDefinition $script:step -Result $script:result
        Should -Invoke Write-Host -Times 0 -Exactly
    }

    It 'retains existing completion semantics without extra required steps' {
        $script:ready = $true
        Write-ManifestStepResult -Device $script:device -StepDefinition $script:step -Result $script:result
        $script:device.Status | Should -Be 'completed'
        $script:device.Steps.Count | Should -Be 1
        $script:device.Steps.ContainsKey('J') | Should -BeTrue
    }
}