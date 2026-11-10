<#
.SYNOPSIS
    Validate manifest contracts without operational storage or tenant access.
.DESCRIPTION
    Uses the actual loader and current JSON as the baseline, then injects invalid
    definitions. Requires Pester 5 and FullLanguage for source parsing.
#>
BeforeAll {
    $definitionRoot = Split-Path -Parent $PSScriptRoot
    $tokens = $null
    $parseErrors = $null
    $script:sourceAst = [System.Management.Automation.Language.Parser]::ParseFile((Join-Path $definitionRoot 'autopilot-express.ps1'), [ref]$tokens, [ref]$parseErrors)
    if ($parseErrors.Count) { throw ($parseErrors.Message -join '; ') }
    $script:functionHelp = @($script:sourceAst.FindAll({ param($node) $node -is [System.Management.Automation.Language.FunctionDefinitionAst] }, $true) | ForEach-Object {
            @{ Name = $_.Name; Help = $_.GetHelpContent(); Parameters = @($_.Parameters) + @($_.Body.ParamBlock.Parameters) }
        })
    foreach ($functionName in @('ConvertTo-NormalisedValue', 'Get-LegacyWorkflowIdMap', 'ConvertTo-CanonicalWorkflowRecord', 'ConvertTo-StepHashtable', 'Assert-AttemptHistory', 'Test-AttemptEvidenceEqual', 'Invoke-WorkflowEvidenceMigration', 'Get-LocalSessionRecoveryInventory', 'Get-RecoveryEvidenceTenantKey', 'Get-RecoveryEvidenceFolder', 'New-LocalSessionRecoverySnapshot', 'Assert-ManifestDefinition', 'Test-ManifestDependencyGraph', 'Initialize-AutopilotExpressDefinitions', 'Get-SessionFileIndexPath', 'Get-SessionFileIndex', 'Initialize-SessionFileIndex', 'Get-UserDataFilePath', 'Get-BuildBenchStatePath', 'Get-ModeUserDataFilePrefix', 'Get-ModeBuildBenchFilePrefix', 'Assert-FileWriteRecoveryState')) {
        $definition = $script:sourceAst.Find({ param($node) $node -is [System.Management.Automation.Language.FunctionDefinitionAst] -and $node.Name -eq $functionName }, $true)
        if (-not $definition) { throw ('Missing function: {0}' -f $functionName) }
        Set-Item -Path ('Function:{0}' -f $definition.Name) -Value $definition.Body.GetScriptBlock()
    }
    $scopeDefinition = $script:sourceAst.Find({ param($node) $node -is [System.Management.Automation.Language.FunctionDefinitionAst] -and $node.Name -eq 'Get-ConfiguredGraphScopes' }, $true)
    Set-Item -Path ('Function:{0}' -f $scopeDefinition.Name) -Value $scopeDefinition.Body.GetScriptBlock()
    $script:manifestJson = Get-Content -LiteralPath (Join-Path $definitionRoot 'autopilot-express.manifest.json') -Raw
    function Get-RuntimeConfigFilePath { return 'synthetic-runtime' }
    function Get-ManifestFilePath { return 'synthetic-manifest' }
    function Read-JsonDefinitionFile { param($Path, $Description) throw ('Unexpected read: {0} {1}' -f $Description, $Path) }
    function Write-AutopilotExpressLog { param($Message, $Level) throw ('Unexpected log: {0} {1}' -f $Level, $Message) }
}

Describe 'Production function documentation contract' {
    It 'provides recognised purpose and output help for every top-level and nested function' {
        $script:functionHelp.Count | Should -BeGreaterThan 200
        $missing = @($script:functionHelp | Where-Object { -not $_.Help.Synopsis -or -not $_.Help.Outputs.Count } | ForEach-Object { $_.Name })
        $missing.Count | Should -Be 0 -Because ($missing -join ', ')
    }

    It 'documents every declared parameter including inline nested-function signatures' {
        $missing = @()
        foreach ($definition in $script:functionHelp) {
            foreach ($parameter in @($definition.Parameters | Where-Object { $null -ne $_ })) {
                $name = $parameter.Name.VariablePath.UserPath.ToUpperInvariant()
                if (-not $definition.Help.Parameters.ContainsKey($name) -or -not $definition.Help.Parameters[$name]) {
                    $missing += '{0} parameter {1}' -f $definition.Name, $name
                }
            }
        }
        $missing.Count | Should -Be 0 -Because ($missing -join ', ')
    }
}

Describe 'Delegated scope fallback compatibility' {
    It 'retains the already configured privileged-operations scope in the fallback request' {
        $script:RuntimeConfig = @{}
        Get-ConfiguredGraphScopes | Should -Contain 'DeviceManagementManagedDevices.PrivilegedOperations.All'
    }

    It 'does not silently broaden an explicit administrator-owned scope list' {
        $script:RuntimeConfig = @{ graph = @{ requiredScopes = @('User.Read.All') } }
        @(Get-ConfiguredGraphScopes) | Should -Be @('User.Read.All')
    }

    It 'does not broaden an explicitly empty scope list into write permissions' {
        $script:RuntimeConfig = @{ graph = @{ requiredScopes = @() } }
        @(Get-ConfiguredGraphScopes).Count | Should -Be 0
    }
}

Describe 'Manifest endpoint descriptions' {
    BeforeAll {
        $script:endpointManifest = $script:manifestJson | ConvertFrom-Json
    }

    It 'describes the filtered v1.0 Autopilot lookup used by the serial resolver' {
        $step = $script:endpointManifest.steps | Where-Object actionName -eq 'ResolveAutopilotDevice'
        $step.graphEndpoints | Should -Contain 'GET /v1.0/deviceManagement/windowsAutopilotDeviceIdentities?$filter=contains(serialNumber,''{serial}'')'
        $resolver = $script:sourceAst.Find({ param($node) $node -is [System.Management.Automation.Language.FunctionDefinitionAst] -and $node.Name -eq 'Resolve-LiveAutopilotDeviceBySerial' }, $true)
        $resolver.Body.Extent.Text | Should -Match 'v1\.0/deviceManagement/windowsAutopilotDeviceIdentities\?\$filter='
    }

    It 'describes direct device memberships for both group actions' {
        $actions = @('AddToPreProvisioningGroup', 'RemoveFromPreProvisioningGroup')
        foreach ($action in $actions) {
            $step = $script:endpointManifest.steps | Where-Object actionName -eq $action
            $step.graphEndpoints | Should -Contain 'GET /v1.0/devices/{directoryObjectId}/memberOf'
            $step.graphEndpoints | Should -Not -Contain 'GET /v1.0/groups/{groupId}/members'
        }
        $reader = $script:sourceAst.Find({ param($node) $node -is [System.Management.Automation.Language.FunctionDefinitionAst] -and $node.Name -eq 'Test-LiveGroupMembership' }, $true)
        $reader.Body.Extent.Text | Should -Match 'v1\.0/devices/\{0\}/memberOf'
    }

    It 'does not claim a Graph assignment read for technician-confirmed profile validation' {
        $step = $script:endpointManifest.steps | Where-Object actionName -eq 'ValidateDeploymentProfile'
        $step.executionType | Should -BeExactly 'guided'
        @($step.graphEndpoints).Count | Should -Be 0
        @($step.requiredPermissions).Count | Should -Be 0
        $controller = $script:sourceAst.Find({ param($node) $node -is [System.Management.Automation.Language.FunctionDefinitionAst] -and $node.Name -eq 'Invoke-StepValidateDeploymentProfile' }, $true)
        $commands = @($controller.Body.FindAll({ param($node) $node -is [System.Management.Automation.Language.CommandAst] }, $true) | ForEach-Object { $_.GetCommandName() })
        $commands | Should -Contain 'Read-ValidatedInput'
        $commands | Should -Not -Contain 'Invoke-GraphApiRequest'
    }

    It 'describes uncertain recovery without claiming acceptance or automatic resend' {
        $unblock = $script:endpointManifest.steps | Where-Object actionName -eq 'ClearUserlessEnrollmentStatus'
        $readiness = $script:endpointManifest.steps | Where-Object actionName -eq 'ConfirmRecoveryReadiness'
        ($unblock.details -join ' ') | Should -Match 'outcome is unknown'
        ($unblock.details -join ' ') | Should -Match 'defaults to No'
        $unblock.notes | Should -Match 'without claiming HTTP acceptance'
        ($readiness.details -join ' ') | Should -Match 'Allowed observation'
        ($readiness.details -join ' ') | Should -Match 'Wait two minutes'
        $readiness.notes | Should -Match 'current-cycle P evidence'
    }

    It 'describes conditional application sync without blocking failures on the baseline step' {
        $baseline = $script:endpointManifest.steps | Where-Object actionName -eq 'ConfirmApplicationBaseline'
        $retry = $script:endpointManifest.steps | Where-Object actionName -eq 'RetryFailedApplications'
        $retry.prerequisiteStepIds | Should -Not -Contain $baseline.id
        ($retry.details -join ' ') | Should -Match 'defaults to no failures'
        ($retry.details -join ' ') | Should -Match 'baseline to be confirmed first'
        ($retry.details -join ' ') | Should -Match 'not the named portal application-remediation'
    }
}

Describe 'Manifest definition startup contract' {
    It 'retains invalidation associations under canonical IDs' {
        $converted = ConvertTo-CanonicalWorkflowRecord -Record @{ Steps = @{ P = @{ InvalidatedBy = 'O'; CompletionState = 'Blocked' } }; AttemptHistory = @(@{ StepId = 'J'; Result = @{ InvalidatedBy = 'P' } }) }
        $converted.Steps.N.InvalidatedBy | Should -Be 'L'
        $converted.AttemptHistory[0].Result.InvalidatedBy | Should -Be 'N'
    }
    It 'converts colliding legacy IDs and nested history once without altering original evidence' {
        $record = @{ Steps = @{ D = @{ ActionName = 'ValidateDeploymentProfile'; Notes = 'D E F are original notes'; Timestamp = '2026-10-01T08:00:00+08:00' }; F = @{ ActionName = 'ClearUserlessEnrollmentStatus' } }; AttemptHistory = @(@{ StepId = 'H'; ActionName = 'RetryFailedApplications'; AttemptId = 'retained'; Result = @{ Summary = 'Do not rewrite H in this text' } }); RecoveryHistory = @(@{ Steps = @{ E = @{ Completed = $true } }; UnresolvedStepIds = @('D', 'E', 'F'); Timestamp = 'original'; Actor = 'retained' }) }
        $original = $record | ConvertTo-Json -Depth 30 -Compress
        $converted = ConvertTo-CanonicalWorkflowRecord -Record $record
        $converted.WorkflowIdVersion | Should -Be 2
        $converted.Steps.F.ActionName | Should -Be 'ValidateDeploymentProfile'
        $converted.Steps.P.ActionName | Should -Be 'ClearUserlessEnrollmentStatus'
        $converted.Steps.F.Notes | Should -BeExactly 'D E F are original notes'
        $converted.Steps.F.Timestamp | Should -BeExactly '2026-10-01T08:00:00+08:00'
        $converted.AttemptHistory[0].StepId | Should -Be 'M'
        $converted.AttemptHistory[0].Result.Summary | Should -BeExactly 'Do not rewrite H in this text'
        $converted.RecoveryHistory[0].Steps.D.Completed | Should -BeTrue
        ($converted.RecoveryHistory[0].UnresolvedStepIds -join ',') | Should -Be 'F,D,P'
        ($record | ConvertTo-Json -Depth 30 -Compress) | Should -BeExactly $original
        $again = ConvertTo-CanonicalWorkflowRecord -Record $converted
        $again.Steps.F.ActionName | Should -Be 'ValidateDeploymentProfile'
        $again.AttemptHistory[0].StepId | Should -Be 'M'
    }
    It 'rejects unknown versions IDs and mismatched action associations' {
        foreach ($record in @(@{ WorkflowIdVersion = 3 }, @{ WorkflowIdVersion = '2' }, @{ Steps = @{ Z = @{} } }, @{ Steps = @{ D = @{ ActionName = 'ApplyGroupTag' } } }, @{ AttemptHistory = @(@{ StepId = 'D'; ActionName = 'ApplyGroupTag' }) })) {
            { ConvertTo-CanonicalWorkflowRecord -Record $record } | Should -Throw
        }
    }
    It 'preserves empty histories and converts every legacy letter bijectively' {
        $map = Get-LegacyWorkflowIdMap
        (@($map.Values | Sort-Object -Unique) -join ',') | Should -Be 'A,B,C,D,E,F,G,H,I,J,K,L,M,N,O,P,Q'
        $converted = ConvertTo-CanonicalWorkflowRecord -Record @{ Steps = @{}; AttemptHistory = @(); RecoveryHistory = @() }
        $converted.AttemptHistory.Count | Should -Be 0
        $converted.RecoveryHistory.Count | Should -Be 0
    }
    BeforeEach {
        $script:manifest = ConvertTo-NormalisedValue -Value ($script:manifestJson | ConvertFrom-Json)
        $script:RuntimeConfig = @{ sentinel = 'old-runtime' }
        $script:Config = @{ OrganisationName = 'old-organisation' }
        $script:StepManifest = @(@{ Id = 'old-step' })
        $script:WorkflowPhases = @(@{ Id = 'old-phase' })
        Mock Read-JsonDefinitionFile {
            if ($Path -eq 'synthetic-manifest') { return $script:manifest }
            return @{ organisationName = 'new-organisation' }
        }
        Mock Write-AutopilotExpressLog {}
    }

    It 'loads the current manifest with all 17 steps and six phases' {
        Initialize-AutopilotExpressDefinitions
        $script:StepManifest.Count | Should -Be 17
        $script:WorkflowPhases.Count | Should -Be 6
        $script:Config.OrganisationName | Should -Be 'new-organisation'
    }
    It 'derives recovery classification from the real activation rule and loads guide metadata' {
        Initialize-AutopilotExpressDefinitions
        (@($script:StepManifest | Where-Object { -not $_.IsConditional }).Id -join ',') | Should -Be 'A,B,C,D,E,F,G,H,I,J,K,L,M,N,O'
        (@($script:StepManifest | Where-Object { $_.IsConditional }).Id -join ',') | Should -Be 'P,Q'
        foreach ($step in $script:StepManifest) {
            $step.DisplayCode | Should -Be $step.Id
            $step.Details.Count | Should -BeGreaterThan 0
        }
    }
    It 'rejects malformed guide paragraphs and colliding display codes before publication' {
        $script:manifest.steps[0].details = 'not an array'
        { Initialize-AutopilotExpressDefinitions } | Should -Throw '*details*'
        $script:StepManifest[0].Id | Should -Be 'old-step'
        $script:manifest.steps[0].details = @('Valid paragraph')
        $script:manifest.steps[0].displayCode = $script:manifest.steps[1].displayCode
        { Initialize-AutopilotExpressDefinitions } | Should -Throw '*display code*'
    }

    It 'displays every prerequisite before its dependent action without changing step IDs' {
        Initialize-AutopilotExpressDefinitions
        $displayedIds = @($script:StepManifest.Id)
        ($displayedIds | Sort-Object) -join ',' | Should -Be 'A,B,C,D,E,F,G,H,I,J,K,L,M,N,O,P,Q'
        $displayedEarlier = @()
        foreach ($step in $script:StepManifest) {
            foreach ($prerequisiteId in $step.PrerequisiteStepIds) {
                $prerequisiteId | Should -BeIn $displayedEarlier -Because ('step {0} depends on {1}' -f $step.Id, $prerequisiteId)
            }
            $displayedEarlier += $step.Id
        }
    }

    It 'includes every enabled action in exactly one workflow phase' {
        Initialize-AutopilotExpressDefinitions
        $phaseActions = @($script:WorkflowPhases | ForEach-Object { $_.ActionNames })
        foreach ($step in $script:StepManifest | Where-Object { $_.Enabled }) {
            @($phaseActions | Where-Object { $_ -eq $step.ActionName }).Count | Should -Be 1
        }
        $completion = $script:WorkflowPhases | Where-Object { $_.Id -eq 'PhysicalCompletion' }
        $completion.ActionNames | Should -Contain 'RetryFailedApplications'
    }

    It 'preserves application retry prerequisites and conditional recovery activation' {
        Initialize-AutopilotExpressDefinitions
        $retry = $script:StepManifest | Where-Object { $_.ActionName -eq 'RetryFailedApplications' }
        $retry.Id | Should -Be 'M'
        ($retry.PrerequisiteStepIds -join ',') | Should -Be 'I,K'
        foreach ($actionName in @('ClearUserlessEnrollmentStatus', 'ConfirmRecoveryReadiness')) {
            $recovery = $script:StepManifest | Where-Object { $_.ActionName -eq $actionName }
            $recovery.ActivationRequirement | Should -Be 'RecoveryMode'
            ($recovery.PrerequisiteStepIds -join ',') | Should -Be 'A'
        }
    }

    It 'accepts schema 1.6 patch revisions and rejects unsupported versions' {
        $script:manifest.manifestVersion = '1.6.12'
        { Assert-ManifestDefinition -Manifest $script:manifest } | Should -Not -Throw
        foreach ($version in @($null, 1, '', '1.6', '1.6.0-preview', '1.5.0', '1.7.0', '2.0.0', '1.6.01')) {
            $script:manifest.manifestVersion = $version
            { Assert-ManifestDefinition -Manifest $script:manifest } | Should -Throw '*manifestVersion*'
        }
    }

    It 'rejects a non-object definition and missing empty or scalar top-level arrays' {
        { Assert-ManifestDefinition -Manifest $null } | Should -Throw '*JSON object*'
        foreach ($field in @('steps', 'workflowPhases')) {
            foreach ($value in @($null, @(), 'wrong', @{})) {
                $candidate = ConvertTo-NormalisedValue -Value ($script:manifestJson | ConvertFrom-Json)
                $candidate[$field] = $value
                { Assert-ManifestDefinition -Manifest $candidate } | Should -Throw '*non-empty JSON array*'
            }
        }
    }

    It 'rejects incomplete steps instead of silently dropping them' {
        $script:manifest.steps[0].Remove('actionName')
        { Initialize-AutopilotExpressDefinitions } | Should -Throw '*unsupported actionName*'
        $script:StepManifest[0].Id | Should -Be 'old-step'
        $script:RuntimeConfig.sentinel | Should -Be 'old-runtime'
    }

    It 'rejects null entries and non-text blank or padded required fields' {
        $script:manifest.steps += , $null
        { Assert-ManifestDefinition -Manifest $script:manifest } | Should -Throw '*JSON object*'
        $script:manifest.steps = @($script:manifest.steps | Where-Object { $null -ne $_ })
        foreach ($value in @(3, '', ' ', ' A ')) {
            $script:manifest.steps[0].id = $value
            { Assert-ManifestDefinition -Manifest $script:manifest } | Should -Throw '*non-blank id*'
        }
    }

    It 'requires JSON Booleans rather than truthy strings' {
        $script:manifest.steps[0].enabled = 'false'
        { Assert-ManifestDefinition -Manifest $script:manifest } | Should -Throw '*JSON Boolean*'
        $script:manifest.steps[0].enabled = $true
        $script:manifest.workflowPhases[0].isConditional = 1
        { Assert-ManifestDefinition -Manifest $script:manifest } | Should -Throw '*JSON Boolean*'
    }
    It 'rejects unsafe group conflict rule shapes and permits an explicit empty rule list' {
        foreach ($rules in @('scalar', @(@{ match = 'Regex'; value = '.*' }), @(@{ match = 'Prefix'; value = ' ' }), @(@{ match = 'Exact'; value = ' padded' }), @(@{ match = 'Prefix'; value = 42 }), @($null))) {
            $candidate = ConvertTo-NormalisedValue -Value ($script:manifestJson | ConvertFrom-Json)
            $candidate.groupConflictExclusions = $rules
            { Assert-ManifestDefinition -Manifest $candidate } | Should -Throw
        }
        $script:manifest.groupConflictExclusions = @()
        { Assert-ManifestDefinition -Manifest $script:manifest } | Should -Not -Throw
    }

    It 'requires typed array metadata and non-blank text entries' {
        foreach ($field in @('prerequisiteStepIds', 'requiredPermissions', 'graphEndpoints')) {
            $candidate = ConvertTo-NormalisedValue -Value ($script:manifestJson | ConvertFrom-Json)
            $candidate.steps[0][$field] = 'scalar'
            { Assert-ManifestDefinition -Manifest $candidate } | Should -Throw '*JSON array*'
            $candidate.steps[0][$field] = @('')
            { Assert-ManifestDefinition -Manifest $candidate } | Should -Throw '*non-blank text*'
        }
    }

    It 'rejects unsupported and duplicate actions including on disabled steps' {
        $script:manifest.steps[0].enabled = $false
        $script:manifest.steps[0].actionName = 'UnknownAction'
        { Assert-ManifestDefinition -Manifest $script:manifest } | Should -Throw '*unsupported actionName*'
        $script:manifest.steps[0].actionName = $script:manifest.steps[1].actionName
        { Assert-ManifestDefinition -Manifest $script:manifest } | Should -Throw '*action*duplicated*'
    }

    It 'rejects duplicate step and phase IDs case-insensitively' {
        $script:manifest.steps[1].id = 'a'
        { Assert-ManifestDefinition -Manifest $script:manifest } | Should -Throw '*step ID*duplicated*'
        $script:manifest.steps[1].id = 'B'
        $script:manifest.workflowPhases[1].id = $script:manifest.workflowPhases[0].id.ToLowerInvariant()
        { Assert-ManifestDefinition -Manifest $script:manifest } | Should -Throw '*phase ID*duplicated*'
    }

    It 'rejects enabled dependencies on disabled prerequisites' {
        $script:manifest.steps[0].enabled = $false
        { Initialize-AutopilotExpressDefinitions } | Should -Throw '*depends on disabled prerequisite*'
    }

    It 'rejects a workflow with no enabled steps' {
        foreach ($step in $script:manifest.steps) { $step.enabled = $false }
        { Initialize-AutopilotExpressDefinitions } | Should -Throw '*at least one enabled*'
    }

    It 'keeps optional defaults when flags and descriptive fields are omitted' {
        $script:manifest.steps[0].Remove('enabled')
        $script:manifest.steps[0].Remove('executionType')
        $script:manifest.steps[0].Remove('notes')
        Initialize-AutopilotExpressDefinitions
        $script:StepManifest[0].Enabled | Should -BeTrue
        $script:StepManifest[0].ActivationRequirement | Should -Be 'None'
        $script:StepManifest[0].ExecutionType | Should -Be 'graph'
        $script:StepManifest[0].Notes | Should -Be ''
    }

    It 'rejects unsupported execution and activation metadata' {
        $script:manifest.steps[0].executionType = 'remote'
        { Assert-ManifestDefinition -Manifest $script:manifest } | Should -Throw '*executionType*'
        $script:manifest.steps[0].executionType = 'graph'
        $script:manifest.steps[0].activationRequirement = 'AlwaysBypass'
        { Assert-ManifestDefinition -Manifest $script:manifest } | Should -Throw '*activationRequirement*'
    }

    It 'rejects undefined repeated and empty phase action collections' {
        $script:manifest.workflowPhases[0].actionNames = @('UnknownAction')
        { Assert-ManifestDefinition -Manifest $script:manifest } | Should -Throw '*undefined action*'
        $script:manifest.workflowPhases[0].actionNames = @('ResolveAutopilotDevice', 'ResolveAutopilotDevice')
        { Assert-ManifestDefinition -Manifest $script:manifest } | Should -Throw '*repeats action*'
        $script:manifest.workflowPhases[0].actionNames = @()
        { Assert-ManifestDefinition -Manifest $script:manifest } | Should -Throw '*non-empty actionNames*'
    }

    It 'preserves all published definitions if dependency graph validation fails' {
        $script:manifest.steps[0].prerequisiteStepIds = @('B')
        { Initialize-AutopilotExpressDefinitions } | Should -Throw '*cycle*'
        $script:StepManifest[0].Id | Should -Be 'old-step'
        $script:WorkflowPhases[0].Id | Should -Be 'old-phase'
        $script:RuntimeConfig.sentinel | Should -Be 'old-runtime'
        $script:Config.OrganisationName | Should -Be 'old-organisation'
    }

    It 'continues to reject undefined self and duplicate prerequisites' {
        foreach ($prerequisites in @(@('Undefined'), @('A'), @('B', 'B'))) {
            $script:manifest.steps[0].prerequisiteStepIds = $prerequisites
            { Initialize-AutopilotExpressDefinitions } | Should -Throw '*dependency graph is invalid*'
        }
    }

    It 'keeps the accepted action set identical to the actual dispatcher cases' {
        $dispatcher = $script:sourceAst.Find({ param($node) $node -is [System.Management.Automation.Language.FunctionDefinitionAst] -and $node.Name -eq 'Invoke-AutopilotManifestStep' }, $true)
        $switchStatement = $dispatcher.Find({ param($node) $node -is [System.Management.Automation.Language.SwitchStatementAst] }, $true)
        $dispatcherActions = @($switchStatement.Clauses | ForEach-Object { $_.Item1.Value } | Sort-Object)
        $manifestActions = @($script:manifest.steps.actionName | Sort-Object)
        ($dispatcherActions -join ',') | Should -Be ($manifestActions -join ',')
        foreach ($actionName in $dispatcherActions) {
            $candidate = ConvertTo-NormalisedValue -Value ($script:manifestJson | ConvertFrom-Json)
            $candidate.steps = @(@{ id = 'Test'; displayName = 'Test'; actionName = $actionName; prerequisiteStepIds = @() })
            $candidate.workflowPhases = @(@{ id = 'Test'; displayName = 'Test'; actionNames = @($actionName) })
            { Assert-ManifestDefinition -Manifest $candidate } | Should -Not -Throw
        }
    }
}

Describe 'Maintained operator documentation contracts' {
    BeforeAll {
        $script:operatorDefinitionRoot = Split-Path -Parent $PSScriptRoot
        $script:operatorGuide = Get-Content -LiteralPath (Join-Path $script:operatorDefinitionRoot 'OPERATIONS.md') -Raw -Encoding UTF8
        $script:operatorRows = @([regex]::Matches($script:operatorGuide, '(?m)^\|[ \t]*([A-Q])[ \t]*\|[ \t]*([^|\r\n]+?)[ \t]*\|[ \t]*\r?$'))
        $script:legacyOperatorRows = @([regex]::Matches($script:operatorGuide, '(?m)^\|[ \t]*([A-Q])[ \t]*\|[ \t]*([A-Q])[ \t]*\|[ \t]*([^|\r\n]+?)[ \t]*\|[ \t]*\r?$'))
    }
    It 'documents every manifest workflow ID exactly once in the operator action table' {
        $manifest = $script:manifestJson | ConvertFrom-Json
        $documented = @($script:operatorRows | ForEach-Object { $_.Groups[1].Value } | Sort-Object)
        ($documented -join ',') | Should -BeExactly (@($manifest.steps.id | Sort-Object) -join ',')
    }
    It 'keeps human-readable workflow labels associated with their semantic actions' {
        $labels = @{
            ResolveAutopilotDevice = 'Resolve Autopilot identity'; RemoveAssociatedManagedDevice = 'Remove associated managed device'
            ApplyGroupTag = 'Apply Group Tag'; AddToPreProvisioningGroup = 'Add pre-provisioning membership'
            ConfirmImagingAndOobe = 'Confirm imaging/OOBE'; ValidateDeploymentProfile = 'Validate deployment profile'
            ConfirmReseal = 'Confirm reseal/shutdown'; ConfirmBootToSignIn = 'Confirm boot to sign-in'
            AssignTechnicianPrimaryUser = 'Assign regular technician'; RemoveFromPreProvisioningGroup = 'Remove pre-provisioning membership'
            ConfirmFirstSignIn = 'Confirm first sign-in'; ConfirmApplicationBaseline = 'Confirm application baseline'
            RetryFailedApplications = 'Review app failures; sync if needed'; ConfirmUpdatesAndShutdown = 'Confirm updates/shutdown'
            AssignFinalPrimaryUser = 'Assign final primary user'; ClearUserlessEnrollmentStatus = 'Submit recovery unblock'
            ConfirmRecoveryReadiness = 'Confirm recovery readiness'
        }
        foreach ($step in ($script:manifestJson | ConvertFrom-Json).steps) {
            $row = @($script:operatorRows | Where-Object { $_.Groups[1].Value -ceq $step.id })
            $row.Count | Should -Be 1
            $row[0].Groups[2].Value.Trim() | Should -BeExactly $labels[$step.actionName]
            $legacyRow = @($script:legacyOperatorRows | Where-Object { $_.Groups[1].Value -ceq $step.id })
            $legacyRow.Count | Should -Be 1
            $legacyRow[0].Groups[3].Value.Trim() | Should -BeExactly $labels[$step.actionName]
        }
    }
    It 'provides parseable PowerShell examples in all eight maintained product guides' {
        $examples = 0
        foreach ($name in @('README.md', 'OPERATIONS.md', 'TESTING.md', 'DEVELOPMENT.md', 'SETUP.md', 'CUSTOMISATION.md', 'TECHNICAL.md', 'FUNCTIONS.md')) {
            $content = Get-Content -LiteralPath (Join-Path $script:operatorDefinitionRoot $name) -Raw
            foreach ($block in [regex]::Matches($content, '(?ims)^```(?:powershell|pwsh)[^\r\n]*\r?\n(?<code>.*?)^```')) {
                $tokens = $null
                $parseErrors = $null
                $null = [System.Management.Automation.Language.Parser]::ParseInput($block.Groups['code'].Value, [ref]$tokens, [ref]$parseErrors)
                $parseErrors.Count | Should -Be 0 -Because ('{0}: {1}' -f $name, ($parseErrors.Message -join '; '))
                $examples++
            }
        }
        $examples | Should -BeGreaterThan 10
    }
    It 'resolves every relative link and heading anchor in the maintained guides' {
        # GitHub-style heading slugs: lower case, punctuation removed, spaces to hyphens, duplicates suffixed -1, -2.
        $getAnchors = {
            param([string]$Path)
            $anchors = [System.Collections.Generic.HashSet[string]]::new([StringComparer]::Ordinal)
            $seen = @{}; $inFence = $false
            foreach ($line in [IO.File]::ReadAllLines($Path)) {
                if ($line -match '^\s*(```|~~~)') { $inFence = -not $inFence; continue }
                if ($inFence -or $line -notmatch '^#{1,6}\s+(.+?)\s*#*$') { continue }
                $text = $Matches[1] -replace '`', '' -replace '\[([^\]]*)\]\([^)]*\)', '$1'
                $slug = ($text.ToLowerInvariant() -replace '[^\p{L}\p{Nd}\- _]', '') -replace ' ', '-'
                if ($seen.ContainsKey($slug)) { $seen[$slug]++; $slug = '{0}-{1}' -f $slug, $seen[$slug] } else { $seen[$slug] = 0 }
                [void]$anchors.Add($slug)
            }
            , $anchors
        }
        $anchorCache = @{}; $problems = [System.Collections.Generic.List[string]]::new()
        foreach ($name in @('README.md', 'OPERATIONS.md', 'TESTING.md', 'DEVELOPMENT.md', 'SETUP.md', 'CUSTOMISATION.md', 'TECHNICAL.md', 'FUNCTIONS.md', 'TODO.md')) {
            $guidePath = Join-Path $script:operatorDefinitionRoot $name
            # Links inside fenced blocks and inline code are examples, not navigation.
            $prose = [regex]::Replace([IO.File]::ReadAllText($guidePath), '(?ms)^\s*```.*?^\s*```', '') -replace '`[^`\r\n]*`', ''
            foreach ($link in [regex]::Matches($prose, '\]\(<?([^)\s>]+)>?(?:\s+"[^"]*")?\)')) {
                $target = $link.Groups[1].Value
                if ($target -match '^(https?|mailto):') { continue }
                $file, $fragment = $target -split '#', 2
                $resolved = if ($file) { Join-Path $script:operatorDefinitionRoot ([uri]::UnescapeDataString($file)) } else { $guidePath }
                if (-not (Test-Path -LiteralPath $resolved)) { $problems.Add(('{0} -> {1} (missing file)' -f $name, $target)); continue }
                if (-not $fragment -or $resolved -notlike '*.md' -or $fragment -match '^L\d+$') { continue }
                if (-not $anchorCache.ContainsKey($resolved)) { $anchorCache[$resolved] = & $getAnchors $resolved }
                if (-not $anchorCache[$resolved].Contains($fragment)) { $problems.Add(('{0} -> {1} (missing anchor)' -f $name, $target)) }
            }
        }
        $problems -join [Environment]::NewLine | Should -BeNullOrEmpty
    }
    It 'starts every maintained guide with the omit-from-toc marker directly above the title' {
        foreach ($name in @('README.md', 'OPERATIONS.md', 'TESTING.md', 'DEVELOPMENT.md', 'SETUP.md', 'CUSTOMISATION.md', 'TECHNICAL.md', 'FUNCTIONS.md', 'TODO.md')) {
            $opening = @(Get-Content -LiteralPath (Join-Path $script:operatorDefinitionRoot $name) -TotalCount 2 -Encoding UTF8)
            $opening[0] | Should -BeExactly '<!-- omit from toc -->' -Because $name
            $opening[1] | Should -Match '^# \S' -Because $name
        }
    }
    It 'keeps the function catalogue in step with every declared function' {
        # Names and per-file counts must match the source; line numbers and hashes refresh when FUNCTIONS.md is regenerated.
        $catalogue = Get-Content -LiteralPath (Join-Path $script:operatorDefinitionRoot 'FUNCTIONS.md') -Encoding UTF8
        # Exact extension match: Windows PowerShell 5.1 -Include '*.ps1' also matches .psd1 files.
        $sources = @('autopilot-express.ps1') + @(Get-ChildItem -LiteralPath (Join-Path $script:operatorDefinitionRoot 'Modules\Documents') -Recurse -File |
                Where-Object { $_.Extension -in '.ps1', '.psm1' } |
                ForEach-Object { $_.FullName.Substring($script:operatorDefinitionRoot.Length + 1) -replace '\\', '/' })
        $declared = foreach ($relative in $sources) {
            $tokens = $null; $parseErrors = $null
            $ast = [System.Management.Automation.Language.Parser]::ParseFile((Join-Path $script:operatorDefinitionRoot $relative), [ref]$tokens, [ref]$parseErrors)
            $functions = @($ast.FindAll({ param($node) $node -is [System.Management.Automation.Language.FunctionDefinitionAst] }, $true))
            $prefix = '| [{0}]({0})' -f $relative
            $row = @($catalogue | Where-Object { $_.StartsWith($prefix, [StringComparison]::Ordinal) })
            $row.Count | Should -Be 1 -Because ('{0} must appear once in the source inventory' -f $relative)
            [int]($row[0].Split('|')[2].Trim()) | Should -Be $functions.Count -Because ('{0} definition count' -f $relative)
            $functions.Name
        }
        $documented = @($catalogue | Where-Object { $_ -like '### *' } | ForEach-Object { $_.Substring(4).Trim() } | Sort-Object)
        ($documented -join ',') | Should -BeExactly (@($declared | Sort-Object) -join ',')
    }
}

Describe 'Offline workspace workflow migration' {
    BeforeEach {
        $script:originalDefinitionDirectory = $script:AutopilotExpressScriptDirectory
        $script:originalLocalAppData = $env:LOCALAPPDATA
        $script:AutopilotExpressScriptDirectory = Join-Path $TestDrive ([guid]::NewGuid().Guid)
        $script:migrationData = Join-Path $script:AutopilotExpressScriptDirectory 'data'
        New-Item -ItemType Directory -Path $script:migrationData -Force | Out-Null
        $env:LOCALAPPDATA = Join-Path $script:AutopilotExpressScriptDirectory 'external-evidence'
        $script:migrationFile = Join-Path $script:migrationData 'autopilot-devices-test.json'
        Set-Content -LiteralPath $script:migrationFile -Value '[{"RecordId":"unchanged","Steps":{"D":{"ActionName":"ValidateDeploymentProfile","Timestamp":"2026-10-01T08:00:00+08:00"}},"AttemptHistory":[],"RecoveryHistory":[]}]' -Encoding UTF8
        $script:migrationCanPreserveDates = (Get-Command ConvertFrom-Json).Parameters.ContainsKey('DateKind')
    }
    AfterEach {
        $script:AutopilotExpressScriptDirectory = $script:originalDefinitionDirectory
        $env:LOCALAPPDATA = $script:originalLocalAppData
    }
    It 'requires a date-preserving host and defaults to read-only rehearsal' {
        $before = (Get-FileHash -LiteralPath $script:migrationFile).Hash
        if ($script:migrationCanPreserveDates) { Invoke-WorkflowEvidenceMigration | Should -Match '1 need conversion' }
        else { { Invoke-WorkflowEvidenceMigration } | Should -Throw '*PowerShell 7.5*' }
        (Get-FileHash -LiteralPath $script:migrationFile).Hash | Should -Be $before
    }
    It 'backs up originals converts current and previous and is a byte-stable no-op on repeat' {
        if (-not $script:migrationCanPreserveDates) { { Invoke-WorkflowEvidenceMigration -Apply } | Should -Throw '*PowerShell 7.5*'; return }
        Copy-Item -LiteralPath $script:migrationFile -Destination ('{0}.previous' -f $script:migrationFile)
        $original = (Get-FileHash -LiteralPath $script:migrationFile).Hash
        Invoke-WorkflowEvidenceMigration -Apply -Confirm:$false | Should -Match 'Converted 2 files'
        $converted = Get-Content -LiteralPath $script:migrationFile -Raw | ConvertFrom-Json
        $converted.WorkflowIdVersion | Should -Be 2
        $converted.Steps.F.ActionName | Should -Be 'ValidateDeploymentProfile'
        (Get-Content -LiteralPath $script:migrationFile -Raw) | Should -Match '2026-10-01T08:00:00\+08:00'
        $backups = @(Get-ChildItem -LiteralPath $env:LOCALAPPDATA -Recurse -File | Where-Object Name -eq 'autopilot-devices-test.json')
        $backups.Count | Should -Be 1
        (Get-FileHash -LiteralPath $backups[0].FullName).Hash | Should -Be $original
        $after = (Get-FileHash -LiteralPath $script:migrationFile).Hash
        Invoke-WorkflowEvidenceMigration -Apply -Confirm:$false | Should -Match '0 need conversion'
        (Get-FileHash -LiteralPath $script:migrationFile).Hash | Should -Be $after
    }
    It 'includes timestamp-prefixed current and previous records without rewriting prefixed benches' {
        if (-not $script:migrationCanPreserveDates) { { Invoke-WorkflowEvidenceMigration -Apply } | Should -Throw '*PowerShell 7.5*'; return }
        $current = Join-Path $script:migrationData '20261014-0700-autopilot-devices-test-unique.json'
        Copy-Item -LiteralPath $script:migrationFile -Destination $current
        Copy-Item -LiteralPath $script:migrationFile -Destination ('{0}.previous' -f $current)
        $bench = Join-Path $script:migrationData '20261014-0700-build-bench-test-unique.json'
        Set-Content -LiteralPath $bench -Value '{"Active":false,"Positions":[]}'
        $benchHash = (Get-FileHash -LiteralPath $bench).Hash
        Invoke-WorkflowEvidenceMigration -Apply -Confirm:$false | Should -Match 'Converted 3 files'
        (Get-Content -LiteralPath $current -Raw | ConvertFrom-Json).WorkflowIdVersion | Should -Be 2
        (Get-Content -LiteralPath ('{0}.previous' -f $current) -Raw | ConvertFrom-Json).Steps.F.ActionName | Should -Be ValidateDeploymentProfile
        (Get-FileHash -LiteralPath $bench).Hash | Should -BeExactly $benchHash
    }

    It 'refuses each unresolved reservation without deleting it' -ForEach @(
        @{ Marker = 'autopilot-express-live.session.lock' }
        @{ Marker = 'record.json.pending' }
        @{ Marker = 'record.json.write-in-progress' }
        @{ Marker = 'session.checkpoint.json' }
        @{ Marker = 'session.archive-in-progress' }
    ) {
        $path = Join-Path $script:migrationData $Marker
        Set-Content -LiteralPath $path -Value 'retained'
        { Invoke-WorkflowEvidenceMigration -Apply -Confirm:$false } | Should -Throw
        Test-Path -LiteralPath $path | Should -BeTrue
    }
    It 'leaves archives and unrelated submission evidence byte-identical' {
        if (-not $script:migrationCanPreserveDates) { { Invoke-WorkflowEvidenceMigration -Apply } | Should -Throw '*PowerShell 7.5*'; return }
        $archive = Join-Path $script:migrationData 'archives'
        New-Item -ItemType Directory -Path $archive | Out-Null
        $archivedFile = Join-Path $archive 'autopilot-devices-test.json'
        Copy-Item -LiteralPath $script:migrationFile -Destination $archivedFile
        $receipt = Join-Path $script:migrationData 'sync-submission-original.json'
        Set-Content -LiteralPath $receipt -Value '{"Submitted":true}'
        $hash = (Get-FileHash -LiteralPath $archivedFile).Hash
        $receiptHash = (Get-FileHash -LiteralPath $receipt).Hash
        Invoke-WorkflowEvidenceMigration -Apply -Confirm:$false | Should -Match 'Converted 1 files'
        (Get-FileHash -LiteralPath $archivedFile).Hash | Should -Be $hash
        (Get-FileHash -LiteralPath $receipt).Hash | Should -Be $receiptHash
    }
    It 'retains recovery marker and verified originals when canonical staging fails' {
        if (-not $script:migrationCanPreserveDates) { { Invoke-WorkflowEvidenceMigration -Apply } | Should -Throw '*PowerShell 7.5*'; return }
        $hash = (Get-FileHash -LiteralPath $script:migrationFile).Hash
        Mock Set-Content { throw 'Injected staging fault' }
        { Invoke-WorkflowEvidenceMigration -Apply -Confirm:$false } | Should -Throw '*staging fault*'
        Test-Path -LiteralPath (Join-Path $script:migrationData 'workflow-id-migration.write-in-progress') | Should -BeTrue
        (Get-FileHash -LiteralPath $script:migrationFile).Hash | Should -Be $hash
    }
    Context 'Conversion under the startup-owned Live reservation' {
        BeforeEach {
            $path = Join-Path $script:migrationData 'autopilot-express-live.session.lock'
            $token = [guid]::NewGuid().Guid
            Set-Content -LiteralPath $path -Value (@{ Token = $token; Computer = $env:COMPUTERNAME; ProcessId = $PID; ReservationVersion = 2 } | ConvertTo-Json)
            $script:ownedMigrationLock = @{ Path = $path; Token = $token; Handle = [IO.File]::Open(($path + '.lease'), [IO.FileMode]::OpenOrCreate, [IO.FileAccess]::ReadWrite, [IO.FileShare]::None) }
            Mock Write-AutopilotExpressLog {}
        }
        AfterEach { $script:ownedMigrationLock.Handle.Dispose() }
        It 'converts linked Live and audit evidence only and retains a complete verified snapshot' {
            if (-not $script:migrationCanPreserveDates) { { Invoke-WorkflowEvidenceMigration -Apply -SessionLock $script:ownedMigrationLock } | Should -Throw '*PowerShell 7.5*'; return }
            $demo = Join-Path $script:migrationData 'autopilot-devices-demo-test.json'
            $audit = Join-Path $script:migrationData 'autopilot-master-audit.json'
            Copy-Item -LiteralPath $script:migrationFile -Destination $demo
            Copy-Item -LiteralPath $script:migrationFile -Destination $audit
            Copy-Item -LiteralPath $script:migrationFile -Destination ($script:migrationFile + '.previous')
            $originalHash = (Get-FileHash -LiteralPath $script:migrationFile).Hash
            $plan = Invoke-WorkflowEvidenceMigration -SessionLock $script:ownedMigrationLock -PassThru
            $plan.ChangedCount | Should -Be 3
            $result = Invoke-WorkflowEvidenceMigration -SessionLock $script:ownedMigrationLock -Apply -PassThru -Confirm:$false
            $result.Applied | Should -BeTrue
            $result.ChangedCount | Should -Be 3
            foreach ($path in @($script:migrationFile, ($script:migrationFile + '.previous'), $audit)) {
                (Get-Content -LiteralPath $path -Raw | ConvertFrom-Json).Steps.F.ActionName | Should -BeExactly ValidateDeploymentProfile
                (Get-FileHash -LiteralPath (Join-Path $result.BackupPath (Split-Path -Leaf $path))).Hash | Should -BeExactly $originalHash
            }
            (Get-FileHash -LiteralPath $demo).Hash | Should -BeExactly $originalHash
            $snapshots = @(Get-ChildItem -LiteralPath (Join-Path $env:LOCALAPPDATA 'PowerShellScriptingNew/AutopilotExpressRecoveryEvidence/SessionSnapshots') -Filter manifest.json -Recurse -File)
            $snapshots.Count | Should -Be 1
            $manifest = Get-Content -LiteralPath $snapshots[0].FullName -Raw | ConvertFrom-Json
            $manifest.Status | Should -BeExactly Verified
            @($manifest.Files).Count | Should -Be 5
            foreach ($entry in $manifest.Files) {
                (Get-FileHash -LiteralPath (Join-Path $snapshots[0].DirectoryName ('files/' + $entry.RelativePath))).Hash | Should -BeExactly $entry.SHA256
            }
            $afterHash = (Get-FileHash -LiteralPath $script:migrationFile).Hash
            (Invoke-WorkflowEvidenceMigration -SessionLock $script:ownedMigrationLock -Apply -PassThru -Confirm:$false).ChangedCount | Should -Be 0
            (Get-FileHash -LiteralPath $script:migrationFile).Hash | Should -BeExactly $afterHash
        }
        It 'does not exempt another mode reservation or an unresolved marker' -ForEach @(
            @{ Marker = 'autopilot-express-demo.session.lock' }
            @{ Marker = 'record.json.pending' }
            @{ Marker = 'record.json.write-in-progress' }
            @{ Marker = 'session.checkpoint.json' }
        ) {
            $hash = (Get-FileHash -LiteralPath $script:migrationFile).Hash
            $markerPath = Join-Path $script:migrationData $Marker
            Set-Content -LiteralPath $markerPath -Value 'retained'
            { Invoke-WorkflowEvidenceMigration -SessionLock $script:ownedMigrationLock -Apply -Confirm:$false } | Should -Throw
            (Get-FileHash -LiteralPath $script:migrationFile).Hash | Should -BeExactly $hash
            Get-Content -LiteralPath $markerPath | Should -BeExactly retained
        }
        It 'refuses replaced ownership or a released handle without promotion' -ForEach @(@{ Released = $false }, @{ Released = $true }) {
            $hash = (Get-FileHash -LiteralPath $script:migrationFile).Hash
            if ($Released) { $script:ownedMigrationLock.Handle.Dispose() }
            else { $script:ownedMigrationLock.Token = 'different-owner' }
            { Invoke-WorkflowEvidenceMigration -SessionLock $script:ownedMigrationLock -Apply -Confirm:$false } | Should -Throw
            (Get-FileHash -LiteralPath $script:migrationFile).Hash | Should -BeExactly $hash
        }
        It 'retains originals when a write marker appears after the complete backup' -ForEach @(
            @{ LateMarker = 'record.json.pending' }
            @{ LateMarker = 'record.json.write-in-progress' }
        ) {
            if (-not $script:migrationCanPreserveDates) { { Invoke-WorkflowEvidenceMigration -Apply -SessionLock $script:ownedMigrationLock } | Should -Throw '*PowerShell 7.5*'; return }
            $hash = (Get-FileHash -LiteralPath $script:migrationFile).Hash
            $script:realMigrationSnapshot = (Get-Command New-LocalSessionRecoverySnapshot).ScriptBlock
            $script:lateMigrationMarker = $LateMarker
            Mock New-LocalSessionRecoverySnapshot {
                $snapshot = & $script:realMigrationSnapshot -DataPath $DataPath -Confirm:$false
                Set-Content -LiteralPath (Join-Path $DataPath $script:lateMigrationMarker) -Value 'retained late write'
                return $snapshot
            }
            { Invoke-WorkflowEvidenceMigration -Apply -SessionLock $script:ownedMigrationLock -Confirm:$false } | Should -Throw '*unresolved write appeared*'
            (Get-FileHash -LiteralPath $script:migrationFile).Hash | Should -BeExactly $hash
            Test-Path -LiteralPath (Join-Path $script:migrationData 'workflow-id-migration.write-in-progress') | Should -BeTrue
            Get-Content -LiteralPath (Join-Path $script:migrationData $LateMarker) | Should -BeExactly 'retained late write'
        }
        It 'rechecks the computer identity after backup even when the token and PID are unchanged' {
            if (-not $script:migrationCanPreserveDates) { { Invoke-WorkflowEvidenceMigration -Apply -SessionLock $script:ownedMigrationLock } | Should -Throw '*PowerShell 7.5*'; return }
            $hash = (Get-FileHash -LiteralPath $script:migrationFile).Hash
            $script:realMigrationSnapshot = (Get-Command New-LocalSessionRecoverySnapshot).ScriptBlock
            Mock New-LocalSessionRecoverySnapshot {
                $snapshot = & $script:realMigrationSnapshot -DataPath $DataPath -Confirm:$false
                $owner = Get-Content -LiteralPath $script:ownedMigrationLock.Path -Raw | ConvertFrom-Json
                $owner.Computer = 'another-computer'
                Set-Content -LiteralPath $script:ownedMigrationLock.Path -Value ($owner | ConvertTo-Json)
                return $snapshot
            }
            { Invoke-WorkflowEvidenceMigration -Apply -SessionLock $script:ownedMigrationLock -Confirm:$false } | Should -Throw '*ownership changed*'
            (Get-FileHash -LiteralPath $script:migrationFile).Hash | Should -BeExactly $hash
            Test-Path -LiteralPath (Join-Path $script:migrationData 'workflow-id-migration.write-in-progress') | Should -BeTrue
        }
    }
}

Describe 'Repeatable offline execution gate' {
    BeforeAll {
        $path = Join-Path (Split-Path -Parent $PSScriptRoot) 'development/Invoke-OfflineValidation.ps1'
        $tokens = $null
        $parseErrors = $null
        $runnerAst = [System.Management.Automation.Language.Parser]::ParseFile($path, [ref]$tokens, [ref]$parseErrors)
        if ($parseErrors.Count) { throw ($parseErrors.Message -join '; ') }
        $definition = $runnerAst.Find({ param($node) $node -is [System.Management.Automation.Language.FunctionDefinitionAst] -and $node.Name -eq 'Assert-OfflineTestResult' }, $true)
        Set-Item -Path Function:Assert-OfflineTestResult -Value $definition.Body.GetScriptBlock()
    }
    BeforeEach { $script:offlineResult = @{ TotalCount = 1; PassedCount = 1; FailedCount = 0; SkippedCount = 0; NotRunCount = 0; FailedContainersCount = 0 } }
    It 'accepts a fully executed passing summary' { { Assert-OfflineTestResult -Result $script:offlineResult } | Should -Not -Throw }
    It 'rejects failed skipped unrun and undiscovered containers' -ForEach @(
        @{ Field = 'FailedCount' }
        @{ Field = 'SkippedCount' }
        @{ Field = 'NotRunCount' }
        @{ Field = 'FailedContainersCount' }
    ) {
        $script:offlineResult[$Field] = 1
        { Assert-OfflineTestResult -Result $script:offlineResult } | Should -Throw '*Offline regression gate*'
    }
    It 'rejects no discovery and incomplete execution' -ForEach @(@{ Total = 0 }, @{ Total = 2 }) {
        $script:offlineResult.TotalCount = $Total
        { Assert-OfflineTestResult -Result $script:offlineResult } | Should -Throw '*Offline regression gate*'
    }
    It 'does not interpret malformed or missing counts as successful zeros' -ForEach @(
        @{ Count = $null }
        @{ Count = '0' }
        @{ Count = $false }
        @{ Count = -1 }
    ) {
        $script:offlineResult.FailedContainersCount = $Count
        { Assert-OfflineTestResult -Result $script:offlineResult } | Should -Throw '*invalid or missing count*'
    }
}

Describe 'Stable indexed session filenames' {
    BeforeAll {
        function Get-DataFolderPath { param($BasePath) if ($BasePath) { return $BasePath }; return $script:indexData }
        function Write-Utf8File { param($Path, $Content) Set-Content -LiteralPath $Path -Value $Content -Encoding UTF8 -NoNewline }
    }
    BeforeEach {
        $script:indexData = Join-Path $TestDrive ([guid]::NewGuid().Guid)
        New-Item -ItemType Directory -Path $script:indexData | Out-Null
        $script:Config = @{ DemoUserDataFilePrefix = 'autopilot-devices-demo'; DemoBuildBenchFilePrefix = 'build-bench-demo'; UserDataFilePrefix = 'autopilot-devices'; BuildBenchFilePrefix = 'build-bench' }
        $script:Runtime = @{ IsDemoMode = $true }
        $script:SessionFileNamesEnabled = $true
        $script:SessionStartedAt = Get-Date '2026-10-14T07:00:00'
    }
    AfterEach { $script:SessionFileNamesEnabled = $false }
    It 'uses the original start prefix and the same collision-safe identity on resume' {
        Initialize-SessionFileIndex
        $first = Get-SessionFileIndex -DataPath $script:indexData
        $first.DeviceFile | Should -Match '^20261014-0700-autopilot-devices-demo-'
        $first.BenchFile | Should -Match '^20261014-0700-build-bench-demo-'
        $first.DeviceFile | Should -Match ([regex]::Escape($first.SessionId))
        $script:SessionStartedAt = Get-Date '2026-10-15T08:00:00'
        Initialize-SessionFileIndex
        (Get-SessionFileIndex -DataPath $script:indexData).DeviceFile | Should -BeExactly $first.DeviceFile
        Get-UserDataFilePath | Should -BeExactly (Join-Path $script:indexData $first.DeviceFile)
        Get-BuildBenchStatePath | Should -BeExactly (Join-Path $script:indexData $first.BenchFile)
    }
    It 'does not rename legacy files or invent a legacy session start' {
        $legacy = Join-Path $script:indexData ('autopilot-devices-demo-{0}.json' -f $env:USERNAME)
        Set-Content -LiteralPath $legacy -Value '[]'
        Initialize-SessionFileIndex
        Get-UserDataFilePath | Should -BeExactly $legacy
        Get-SessionFileIndex -DataPath $script:indexData | Should -BeNullOrEmpty
    }
    It 'refuses missing index authority rather than selecting a newer stamped file' {
        $name = '20261014-0700-autopilot-devices-demo-{0}-{1}.json' -f $env:USERNAME, [guid]::NewGuid().Guid
        Set-Content -LiteralPath (Join-Path $script:indexData $name) -Value '[]'
        { Get-UserDataFilePath } | Should -Throw '*without their authoritative resume index*'
    }
    It 'refuses path traversal cross-user identity and changed session prefixes' -ForEach @(
        @{ Field = 'DeviceFile'; Value = '../unrelated.json' }
        @{ Field = 'User'; Value = 'another-user' }
        @{ Field = 'Mode'; Value = 'live' }
        @{ Field = 'SessionPrefix'; Value = '20261015-0700' }
        @{ Field = 'SchemaVersion'; Value = 9 }
        @{ Field = 'SchemaVersion'; Value = '1' }
        @{ Field = 'SchemaVersion'; Value = $true }
        @{ Field = 'SchemaVersion'; Value = 1.5 }
        @{ Field = 'SessionId'; Value = 'deadbeef----------------------------' }
        @{ Field = 'StartedAt'; Value = '' }
        @{ Field = 'StartedAt'; Value = 0 }
    ) {
        Initialize-SessionFileIndex
        $index = Get-SessionFileIndex -DataPath $script:indexData
        $index[$Field] = $Value
        Write-Utf8File -Path (Get-SessionFileIndexPath -DataPath $script:indexData) -Content ($index | ConvertTo-Json)
        { Get-UserDataFilePath } | Should -Throw
    }
    It 'refuses unfinished index saves without deleting recovery artefacts' {
        $path = '{0}.pending' -f (Get-SessionFileIndexPath -DataPath $script:indexData)
        Set-Content -LiteralPath $path -Value 'retained'
        { Initialize-SessionFileIndex } | Should -Throw '*Interrupted save*'
        Test-Path -LiteralPath $path | Should -BeTrue
    }
}