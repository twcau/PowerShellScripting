<#
.SYNOPSIS
    Isolated Group Tag mutation and read-back regression tests.
.DESCRIPTION
    Extracts only the required functions without starting the CLI. Requests and
    pauses are mocked; no tenant or operational records are modified. Requires
    Pester 5 and FullLanguage for source parsing.
#>

BeforeAll {
    $sourcePath = Join-Path (Split-Path -Parent $PSScriptRoot) 'autopilot-express.ps1'
    $tokens = $null
    $parseErrors = $null
    $sourceAst = [System.Management.Automation.Language.Parser]::ParseFile($sourcePath, [ref]$tokens, [ref]$parseErrors)
    if ($parseErrors.Count) { throw ($parseErrors.Message -join '; ') }
    foreach ($functionName in @('Get-GraphTransportFailure', 'Get-GraphOperationFailureMessage', 'New-OperationResult', 'Get-GraphVerificationPolicy', 'Wait-AutopilotGroupTagVerification', 'Invoke-StepApplyGroupTag')) {
        $definition = $sourceAst.Find({ param($node) $node -is [System.Management.Automation.Language.FunctionDefinitionAst] -and $node.Name -eq $functionName }, $true)
        if ($null -eq $definition) { throw ('Missing function: {0}' -f $functionName) }
        Set-Item -Path ('Function:{0}' -f $definition.Name) -Value $definition.Body.GetScriptBlock()
    }
    function Get-LiveAutopilotDeviceById {
        param([string]$AutopilotDeviceId)
        throw ('Unexpected lookup for {0}.' -f $AutopilotDeviceId)
    }
    function Resolve-LiveAutopilotContext {
        param($Device)
        throw ('Unexpected context lookup for {0}.' -f $Device.Serial)
    }
    function Resolve-LiveAutopilotTagContext {
        param($Device)
        throw ('Unexpected tag context lookup for {0}.' -f $Device.Serial)
    }
    function Invoke-GraphApiRequest {
        param([string]$Method, [string]$Uri, [hashtable]$Body)
        throw ('Unexpected Graph request: {0} {1}; tag {2}.' -f $Method, $Uri, $Body.groupTag)
    }
    function Update-MgDeviceManagementWindowsAutopilotDeviceIdentityDeviceProperty {
        [CmdletBinding(SupportsShouldProcess)]
        param([string]$WindowsAutopilotDeviceIdentityId, [hashtable]$BodyParameter)
        if ($PSCmdlet.ShouldProcess($WindowsAutopilotDeviceIdentityId, 'Update Group Tag')) {
            throw ('Unexpected SDK write: {0}; tag {1}.' -f $WindowsAutopilotDeviceIdentityId, $BodyParameter.groupTag)
        }
    }
}

Describe 'Group Tag polling and completion' {
    BeforeEach {
        $script:Config = @{ MaxRetryAttempts = 3; RetryBackoffSeconds = 0 }
        $script:Runtime = @{ IsDemoMode = $false }
        $script:device = @{ Serial = 'SERIAL1'; AutopilotDeviceId = 'auto-1'; SiteCode = 'SITE'; DeviceType = 'Desk Top'; GroupTag = 'previous' }
        $script:step = @{ Id = 'C'; ActionName = 'ApplyGroupTag' }
        $script:reads = 0
        Mock Start-Sleep {}
        Mock Get-Command { return $null } -ParameterFilter { $Name -eq 'Update-MgDeviceManagementWindowsAutopilotDeviceIdentityDeviceProperty' }
        Mock Invoke-GraphApiRequest {}
        Mock Update-MgDeviceManagementWindowsAutopilotDeviceIdentityDeviceProperty {}
        Mock Resolve-LiveAutopilotContext {}
        Mock Resolve-LiveAutopilotTagContext { return @{ id = $Device.AutopilotDeviceId; groupTag = 'previous' } }
        Mock Get-LiveAutopilotDeviceById { return @{ id = 'auto-1'; groupTag = 'SITE-DeskTop' } }
    }

    It 'does not refresh unrelated Intune and Entra context for an already resolved tag' {
        $result = Invoke-StepApplyGroupTag -Device $script:device -StepDefinition $script:step
        $result.CompletionState | Should -Be Verified
        Should -Invoke Resolve-LiveAutopilotContext -Times 0 -Exactly
    }

    It 'verifies an immediate match after one REST mutation' {
        $result = Invoke-StepApplyGroupTag -Device $script:device -StepDefinition $script:step
        $result.CompletionState | Should -Be 'Verified'
        $result.Success | Should -BeTrue
        $result.Data.VerificationAttempts | Should -Be 1
        $script:device.GroupTag | Should -Be 'SITE-DeskTop'
        Should -Invoke Invoke-GraphApiRequest -Times 1 -Exactly -ParameterFilter {
            $Method -eq 'POST' -and $Uri -eq 'https://graph.microsoft.com/v1.0/deviceManagement/windowsAutopilotDeviceIdentities/auto-1/updateDeviceProperties' -and $Body.groupTag -ceq 'SITE-DeskTop'
        }
        Should -Invoke Start-Sleep -Times 0 -Exactly
    }

    It 'does not resubmit an update when fresh discovery already observes the exact tag' {
        Mock Resolve-LiveAutopilotTagContext { return @{ id = 'auto-1'; groupTag = 'SITE-DeskTop' } }
        $result = Invoke-StepApplyGroupTag -Device $script:device -StepDefinition $script:step
        $result.CompletionState | Should -Be Verified
        $result.Data.AutopilotDeviceId | Should -Be 'auto-1'
        $result.Data.Submitted | Should -BeFalse
        Should -Invoke Invoke-GraphApiRequest -Times 0 -Exactly
        Should -Invoke Get-LiveAutopilotDeviceById -Times 0 -Exactly
    }

    It 'observes delayed propagation across bench rechecks without repeating the mutation or sleeping' {
        $script:Config.RetryBackoffSeconds = 2
        Mock Get-LiveAutopilotDeviceById {
            $script:reads++
            return @{ id = 'auto-1'; groupTag = if ($script:reads -lt 3) { 'previous' } else { 'SITE-DeskTop' } }
        }
        Mock Resolve-LiveAutopilotTagContext {
            if ($Device.Steps.C.Data.Submitted) {
                $script:reads++
                return @{ id = 'auto-1'; groupTag = if ($script:reads -lt 3) { 'previous' } else { 'SITE-DeskTop' } }
            }
            return @{ id = 'auto-1'; groupTag = 'previous' }
        }
        $script:device.Steps = @{}
        1..2 | ForEach-Object {
            $pending = Invoke-StepApplyGroupTag -Device $script:device -StepDefinition $script:step
            $pending.CompletionState | Should -Be Submitted
            $script:device.Steps.C = $pending
        }
        $result = Invoke-StepApplyGroupTag -Device $script:device -StepDefinition $script:step
        $result.CompletionState | Should -Be 'Verified'
        $result.Data.VerificationAttempts | Should -Be 1
        Should -Invoke Get-LiveAutopilotDeviceById -Times 1 -Exactly
        Should -Invoke Invoke-GraphApiRequest -Times 1 -Exactly
        Should -Invoke Start-Sleep -Times 0 -Exactly
    }

    It 'retains the original accepted scope through a failed read and later pending recheck without reposting' {
        $script:device.RecordId = 'tag-record'
        $script:device.BuildCycleId = 'tag-cycle'
        $script:device.TenantId = 'tag-tenant'
        $script:device.Steps = @{}
        Mock Get-LiveAutopilotDeviceById { return @{ id = 'auto-1'; groupTag = 'previous' } }
        $pending = Invoke-StepApplyGroupTag -Device $script:device -StepDefinition $script:step
        $pending.CompletionState | Should -Be Submitted
        $pending.Data.AcceptedContext.RecordId | Should -Be 'tag-record'
        $pending.Data.AcceptedContext.BuildCycleId | Should -Be 'tag-cycle'
        $pending.Data.AcceptedContext.TenantId | Should -Be 'tag-tenant'
        $pending.Data.AcceptedContext.Serial | Should -Be SERIAL1
        $script:device.Steps.C = $pending
        $script:device.BuildCycleId = 'different-cycle'
        Mock Resolve-LiveAutopilotTagContext { throw 'Synthetic read failure' }
        $failed = Invoke-StepApplyGroupTag -Device $script:device -StepDefinition $script:step
        $failed.CompletionState | Should -Be Submitted
        $failed.Data.AcceptedContext.BuildCycleId | Should -Be 'tag-cycle'
        $script:device.Steps.C = $failed
        Mock Resolve-LiveAutopilotTagContext { return @{ id = 'auto-1'; groupTag = 'previous' } }
        $rechecked = Invoke-StepApplyGroupTag -Device $script:device -StepDefinition $script:step
        $rechecked.CompletionState | Should -Be Submitted
        $rechecked.Data.AcceptedContext.BuildCycleId | Should -Be 'tag-cycle'
        Should -Invoke Invoke-GraphApiRequest -Times 1 -Exactly
    }
    It 'returns an accepted pending tag to bench work after one read without another write or sleep' {
        $script:device.Steps = @{ C = @{ CompletionState = 'Submitted'; Data = @{ Submitted = $true; AutopilotDeviceId = 'auto-1'; GroupTag = 'SITE-DeskTop' } } }
        Mock Get-LiveAutopilotDeviceById { return @{ id = 'auto-1'; groupTag = 'previous' } }
        $result = Invoke-StepApplyGroupTag -Device $script:device -StepDefinition $script:step
        $result.CompletionState | Should -Be Submitted
        $result.Data.Submitted | Should -BeTrue
        $result.Data.AutopilotDeviceId | Should -Be 'auto-1'
        $result.Data.VerificationAttempts | Should -Be 1
        Should -Invoke Invoke-GraphApiRequest -Times 0 -Exactly
        Should -Invoke Get-LiveAutopilotDeviceById -Times 0 -Exactly
        Should -Invoke Start-Sleep -Times 0 -Exactly
    }

    It 'verifies a pending submission on a later read without submitting another update' {
        $script:device.Steps = @{ C = @{ CompletionState = 'Submitted'; Data = @{ Submitted = $true; AutopilotDeviceId = 'auto-1'; GroupTag = 'SITE-DeskTop' } } }
        Mock Resolve-LiveAutopilotTagContext { return @{ id = 'auto-1'; groupTag = 'SITE-DeskTop' } }
        $result = Invoke-StepApplyGroupTag -Device $script:device -StepDefinition $script:step
        $result.CompletionState | Should -Be Verified
        $script:device.GroupTag | Should -Be 'SITE-DeskTop'
        Should -Invoke Invoke-GraphApiRequest -Times 0 -Exactly
        Should -Invoke Start-Sleep -Times 0 -Exactly
    }

    It 'preserves accepted target evidence across a failed recheck and a later successful retry' {
        $script:device.Steps = @{ C = @{ CompletionState = 'Submitted'; Data = @{ Submitted = $true; AutopilotDeviceId = 'auto-1'; GroupTag = 'SITE-DeskTop' } } }
        Mock Resolve-LiveAutopilotTagContext { throw 'Synthetic read failure' }
        $failed = Invoke-StepApplyGroupTag -Device $script:device -StepDefinition $script:step
        $failed.CompletionState | Should -Be Submitted
        $failed.Data.Submitted | Should -BeTrue
        $failed.Data.AutopilotDeviceId | Should -Be 'auto-1'
        $script:device.Steps.C = $failed
        Mock Resolve-LiveAutopilotTagContext { return @{ id = 'auto-1'; groupTag = 'SITE-DeskTop' } }
        $verified = Invoke-StepApplyGroupTag -Device $script:device -StepDefinition $script:step
        $verified.CompletionState | Should -Be Verified
        Should -Invoke Invoke-GraphApiRequest -Times 0 -Exactly
    }

    It 'blocks a pending update after its <Field> changes instead of silently submitting again' -ForEach @(
        @{ Field = 'AutopilotDeviceId'; Value = 'different-device' }
        @{ Field = 'SiteCode'; Value = 'DIFFERENT-SITE' }
    ) {
        $script:device.Steps = @{ C = @{ CompletionState = 'Submitted'; Data = @{ Submitted = $true; AutopilotDeviceId = 'auto-1'; GroupTag = 'SITE-DeskTop' } } }
        $script:device[$Field] = $Value
        $result = Invoke-StepApplyGroupTag -Device $script:device -StepDefinition $script:step
        $result.CompletionState | Should -Be Blocked
        $result.Data.AutopilotDeviceId | Should -Be 'auto-1'
        $result.Data.GroupTag | Should -Be 'SITE-DeskTop'
        Should -Invoke Invoke-GraphApiRequest -Times 0 -Exactly
        Should -Invoke Get-LiveAutopilotDeviceById -Times 0 -Exactly
    }

    It 'keeps an exhausted mismatch Submitted without changing the stored tag' {
        $script:Config.RetryBackoffSeconds = 2
        Mock Get-LiveAutopilotDeviceById { return @{ id = 'auto-1'; groupTag = 'previous' } }
        $result = Invoke-StepApplyGroupTag -Device $script:device -StepDefinition $script:step
        $result.Success | Should -BeFalse
        $result.CompletionState | Should -Be 'Submitted'
        $result.Data.ObservedGroupTag | Should -Be 'previous'
        $result.Data.VerificationAttempts | Should -Be 1
        $script:device.GroupTag | Should -Be 'previous'
        Should -Invoke Get-LiveAutopilotDeviceById -Times 1 -Exactly
        Should -Invoke Invoke-GraphApiRequest -Times 1 -Exactly
        Should -Invoke Start-Sleep -Times 0 -Exactly
    }

    It 'does not verify case-only differences in the enforced tag' {
        Mock Get-LiveAutopilotDeviceById { return @{ id = 'auto-1'; groupTag = 'site-desktop' } }
        $result = Invoke-StepApplyGroupTag -Device $script:device -StepDefinition $script:step
        $result.CompletionState | Should -Be 'Submitted'
        $result.Success | Should -BeFalse
    }

    It 'records a read failure with submission evidence without retrying the error' {
        Mock Get-LiveAutopilotDeviceById { throw 'Read denied' }
        $result = Invoke-StepApplyGroupTag -Device $script:device -StepDefinition $script:step
        $result.CompletionState | Should -Be 'Submitted'
        $result.Data.Submitted | Should -BeTrue
        $result.Notes | Should -Match 'Read denied'
        Should -Invoke Get-LiveAutopilotDeviceById -Times 1 -Exactly
    }

    It 'does not read back or claim submission after a failed write' {
        Mock Invoke-GraphApiRequest { throw 'Write denied' }
        $result = Invoke-StepApplyGroupTag -Device $script:device -StepDefinition $script:step
        $result.CompletionState | Should -Be 'Failed'
        $result.Data.Submitted | Should -BeFalse
        Should -Invoke Get-LiveAutopilotDeviceById -Times 0 -Exactly
    }

    It 'blocks unavailable Autopilot identities without issuing a write' {
        $script:device.AutopilotDeviceId = ''
        $result = Invoke-StepApplyGroupTag -Device $script:device -StepDefinition $script:step
        $result.CompletionState | Should -Be 'Blocked'
        Should -Invoke Invoke-GraphApiRequest -Times 0 -Exactly
    }

    It 'resolves missing identity context before writing' {
        $script:device.AutopilotDeviceId = ''
        Mock Resolve-LiveAutopilotTagContext { $Device.AutopilotDeviceId = 'auto-1'; return @{ id = 'auto-1'; groupTag = 'previous' } }
        $result = Invoke-StepApplyGroupTag -Device $script:device -StepDefinition $script:step
        $result.CompletionState | Should -Be 'Verified'
        Should -Invoke Resolve-LiveAutopilotTagContext -Times 1 -Exactly
    }

    It 'rejects invalid policy before lookup or mutation' {
        $script:Config.MaxRetryAttempts = 0
        $script:device.AutopilotDeviceId = ''
        $result = Invoke-StepApplyGroupTag -Device $script:device -StepDefinition $script:step
        $result.CompletionState | Should -Be 'Failed'
        $result.Data.Submitted | Should -BeFalse
        Should -Invoke Invoke-GraphApiRequest -Times 0 -Exactly
        Should -Invoke Resolve-LiveAutopilotContext -Times 0 -Exactly
    }

    It 'uses one guarded REST write even when the optional SDK writer is available' {
        Mock Get-Command { return @{ Name = 'Update-MgDeviceManagementWindowsAutopilotDeviceIdentityDeviceProperty' } } -ParameterFilter { $Name -eq 'Update-MgDeviceManagementWindowsAutopilotDeviceIdentityDeviceProperty' }
        $result = Invoke-StepApplyGroupTag -Device $script:device -StepDefinition $script:step
        $result.CompletionState | Should -Be 'Verified'
        Should -Invoke Update-MgDeviceManagementWindowsAutopilotDeviceIdentityDeviceProperty -Times 0 -Exactly
        Should -Invoke Invoke-GraphApiRequest -Times 1 -Exactly -ParameterFilter {
            $Method -eq 'POST' -and $Uri -eq 'https://graph.microsoft.com/v1.0/deviceManagement/windowsAutopilotDeviceIdentities/auto-1/updateDeviceProperties' -and $Body.groupTag -ceq 'SITE-DeskTop'
        }
    }

    It 'keeps Demo simulation isolated from Graph and pauses' {
        $script:Runtime.IsDemoMode = $true
        $result = Invoke-StepApplyGroupTag -Device $script:device -StepDefinition $script:step
        $result.CompletionState | Should -Be 'Simulated'
        $script:device.GroupTag | Should -Be 'SITE-DeskTop'
        Should -Invoke Invoke-GraphApiRequest -Times 0 -Exactly
        Should -Invoke Get-LiveAutopilotDeviceById -Times 0 -Exactly
        Should -Invoke Start-Sleep -Times 0 -Exactly
    }

    It 'rejects missing or unexpected identity read-back' {
        foreach ($badResponse in @($null, @{}, @{ id = 'other'; groupTag = 'SITE-DeskTop' })) {
            $script:badResponse = $badResponse
            Mock Get-LiveAutopilotDeviceById { return $script:badResponse }
            $result = Invoke-StepApplyGroupTag -Device $script:device -StepDefinition $script:step
            $result.Success | Should -BeFalse
            $result.CompletionState | Should -Be 'Submitted'
            $result.Data.Submitted | Should -BeTrue
            $result.Notes | Should -Match 'unexpected Autopilot identity'
        }
    }
}