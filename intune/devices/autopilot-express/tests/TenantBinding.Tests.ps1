<#
.SYNOPSIS
    Offline tenant ownership checks for sessions, device resolution and evidence.
.DESCRIPTION
    Extracts actual source functions without launching the CLI. SDK authentication,
    Graph requests and persistence are mocked; all tenant GUIDs are synthetic.
    Requires Pester 5 and FullLanguage for parsing. No tenant actions occur.
.FILECREATED
    2026-10-08
.FILELASTUPDATED
    2026-10-08
#>
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseSingularNouns', '', Scope = 'Function', Target = 'Import-RequiredGraphModules', Justification = 'Offline stub must retain the existing source function name.')]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseSingularNouns', '', Scope = 'Function', Target = 'Get-ConfiguredGraphScopes', Justification = 'Offline stub must retain the existing source function name.')]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseSingularNouns', '', Scope = 'Function', Target = 'Test-GraphCapabilities', Justification = 'Offline stub must retain the existing source function name.')]
param()

BeforeAll {
    $sourcePath = Join-Path (Split-Path -Parent $PSScriptRoot) 'autopilot-express.ps1'
    $tokens = $null
    $parseErrors = $null
    $sourceAst = [System.Management.Automation.Language.Parser]::ParseFile($sourcePath, [ref]$tokens, [ref]$parseErrors)
    if ($parseErrors.Count) { throw ($parseErrors.Message -join '; ') }
    foreach ($functionName in @(
            'New-EmptyDeviceRecord', 'Get-EmptyGraphSession', 'Get-LiveTenantBinding',
            'Resolve-LiveAutopilotContext', 'Initialize-GraphSession', 'Close-GraphSession', 'Read-ValidatedInput',
            'Initialize-LiveTenantContext', 'Invoke-LiveStartupRead', 'Get-GraphCapabilityReadCheck', 'Get-PreProvisioningGroupLookupUri', 'Clear-GraphReadPrefetch', 'Get-ConfiguredPreProvisioningGroupDisplayName', 'Get-StoredEntraDeviceObject', 'Get-GraphDiscoveryCollection', 'New-OperationResult',
            'Get-GraphTransportFailure', 'Get-GraphOperationFailureMessage', 'Assert-DeviceRemediationAccess',
            'Invoke-AutopilotManifestStep', 'Get-UserDeviceRecords', 'ConvertTo-NormalisedValue',
            'ConvertTo-StepHashtable', 'ConvertTo-RecordDate', 'ConvertTo-PersistedDate',
            'ConvertTo-PersistedDeviceRecord', 'Assert-DeviceRecordIdentity', 'Get-MasterAuditProposal', 'Get-VerifiedSaveCopy', 'Update-MasterAuditLedger'
            'Assert-AttemptHistory', 'Test-AttemptEvidenceEqual', 'Assert-AttemptHistoryPreserved'
        )) {
        $definition = $sourceAst.Find({ param($node) $node -is [System.Management.Automation.Language.FunctionDefinitionAst] -and $node.Name -eq $functionName }, $true)
        if (-not $definition) { throw ('Missing function: {0}' -f $functionName) }
        Set-Item -Path ('Function:{0}' -f $definition.Name) -Value $definition.Body.GetScriptBlock()
    }
    function Get-MgContext { throw 'Unexpected SDK context lookup.' }
    function Connect-MgGraph { [CmdletBinding()] param($Scopes, $ContextScope, [switch]$NoWelcome, $TenantId, [switch]$UseDeviceCode) throw ('Unexpected authentication: {0}, {1}, {2}, {3}, {4}' -f $Scopes, $ContextScope, $NoWelcome, $TenantId, $UseDeviceCode) }
    function Disconnect-MgGraph { throw 'Unexpected SDK disconnect.' }
    function Invoke-MgGraphRequest { param($Method, $Uri) throw ('Unexpected SDK request: {0} {1}' -f $Method, $Uri) }
    function Invoke-GraphApiRequest { param($Method, $Uri) throw ('Unexpected Graph request: {0} {1}' -f $Method, $Uri) }
    function Test-LiveRuntimeConfiguration { throw 'Unexpected configuration check.' }
    function Import-RequiredGraphModules { throw 'Unexpected module import.' }
    function Get-GraphTransportPolicy { throw 'Unexpected transport policy.' }
    function Initialize-GraphTransport { param($Policy) throw ('Unexpected transport initialisation: {0}' -f $Policy) }
    function Get-ConfiguredGraphScopes { throw 'Unexpected scope lookup.' }
    function Test-GraphCapabilities { throw 'Unexpected capability check.' }
    # Startup batching is proven by GraphCallBudget.Tests.ps1; here each read stays on Invoke-GraphApiRequest.
    function Invoke-GraphReadPrefetch { return 0 }
    function Test-IsPlaceholderConfigurationValue { param($Value) throw ('Unexpected placeholder check: {0}' -f $Value) }
    function Resolve-LiveAutopilotDeviceBySerial { param($Serial) throw ('Unexpected Autopilot read: {0}' -f $Serial) }
    function Resolve-LiveManagedDeviceBySerial { param($Serial) throw ('Unexpected managed read: {0}' -f $Serial) }
    function Resolve-LiveEntraDeviceObject { param($AzureAdDeviceId) throw ('Unexpected Entra read: {0}' -f $AzureAdDeviceId) }
    function Test-ManifestStepEligibility { param($Device, $StepDefinition) throw ('Unexpected eligibility: {0} {1}' -f $Device.Serial, $StepDefinition.ActionName) }
    function Invoke-StepConfirmPhysicalMilestone { param($Device, $StepDefinition) throw ('Unexpected physical evidence: {0} {1}' -f $Device.Serial, $StepDefinition.ActionName) }
    function Invoke-StepResolveAutopilotDevice { param($Device, $StepDefinition) throw ('Unexpected identity action: {0} {1}' -f $Device.Serial, $StepDefinition.ActionName) }
    function Get-UserDataFilePath { return 'synthetic-device-state.json' }
    function Get-MasterAuditFilePath { return 'synthetic-audit.json' }
    function Write-Utf8File { param($Path, $Content) throw ('Unexpected write: {0} {1}' -f $Path, $Content) }
    function Write-AutopilotExpressLog { param($Message, $Level) throw ('Unexpected log: {0} {1}' -f $Level, $Message) }
}

Describe 'Sign-in menu input validation' {
    It 'validates <Label> using the production prompt helper' -ForEach @(
        @{ Label = 'Enter as Cancel'; Responses = @(''); Expected = '0' },
        @{ Label = 'lowercase DeviceCode'; Responses = @('d'); Expected = 'd' },
        @{ Label = 'lowercase Browser'; Responses = @('b'); Expected = 'b' },
        @{ Label = 'explicit Cancel'; Responses = @('0'); Expected = '0' },
        @{ Label = 'invalid choices before Browser'; Responses = @('x', '1', 'b'); Expected = 'b' }
    ) {
        $script:signInInputs = [System.Collections.Generic.Queue[string]]::new()
        foreach ($response in $Responses) { $script:signInInputs.Enqueue($response) }
        Mock Write-Host {}
        Mock Read-Host { return $script:signInInputs.Dequeue() }
        Read-ValidatedInput -Prompt 'Sign-in method' -Default '0' -Type Choice -Choices @('D', 'B', '0') | Should -BeExactly $Expected
        Should -Invoke Read-Host -Times $Responses.Count -Exactly -ParameterFilter { $Prompt -eq 'Sign-in method (default: 0)' }
    }
}

Describe 'Tenant ownership before Live device reads and evidence' {
    BeforeEach {
        $script:Runtime = @{ IsDemoMode = $false }
        $script:RuntimeConfig = @{ graph = @{ expectedTenantId = '' } }
        $script:tenant = '11111111-1111-1111-1111-111111111111'
        $script:otherTenant = '22222222-2222-2222-2222-222222222222'
        $script:GraphSession = @{ Connected = $true; IsSimulated = $false; TenantId = $script:tenant }
        $script:device = New-EmptyDeviceRecord
        $script:device.Serial = 'TENANT-TEST-01'
        Mock Get-MgContext { return @{ TenantId = $script:tenant } }
        Mock Resolve-LiveAutopilotDeviceBySerial { return @{ id = 'ap-new'; azureActiveDirectoryDeviceId = 'registration-new' } }
        Mock Resolve-LiveManagedDeviceBySerial { return @{ id = 'managed-new' } }
        Mock Resolve-LiveEntraDeviceObject { return @{ id = 'entra-new' } }
        Mock Test-ManifestStepEligibility { return @{ Eligible = $true } }
        Mock Invoke-StepConfirmPhysicalMilestone { return @{ Success = $true } }
        Mock Invoke-StepResolveAutopilotDevice { return @{ Success = $true } }
    }

    It 'initialises device and empty session TenantId as empty text' {
        $script:device.TenantId | Should -BeExactly ''
        (Get-EmptyGraphSession).TenantId | Should -BeExactly ''
    }

    It 'accepts a matching configured tenant pin case-insensitively' {
        $script:RuntimeConfig.graph.expectedTenantId = $script:tenant.ToUpperInvariant()
        Get-LiveTenantBinding | Should -Be $script:tenant
    }

    It 'refuses a configured tenant mismatch before device discovery' {
        $script:RuntimeConfig.graph.expectedTenantId = $script:otherTenant
        { Resolve-LiveAutopilotContext -Device $script:device } | Should -Throw '*expectedTenantId*'
        Should -Invoke Resolve-LiveAutopilotDeviceBySerial -Times 0 -Exactly
        Should -Invoke Resolve-LiveManagedDeviceBySerial -Times 0 -Exactly
    }

    It 'refuses malformed configured tenant pins' -TestCases @(
        @{ Value = 'not-a-tenant' }
        @{ Value = $true }
        @{ Value = ' 11111111-1111-1111-1111-111111111111 ' }
    ) {
        param($Value)
        $script:RuntimeConfig.graph.expectedTenantId = $Value
        { Get-LiveTenantBinding } | Should -Throw '*tenant GUID*'
    }

    It 'refuses a mismatched bound record before any device read' {
        $script:device.TenantId = $script:otherTenant
        { Resolve-LiveAutopilotContext -Device $script:device } | Should -Throw '*does not match*'
        Should -Invoke Resolve-LiveAutopilotDeviceBySerial -Times 0 -Exactly
        Should -Invoke Resolve-LiveManagedDeviceBySerial -Times 0 -Exactly
        Should -Invoke Resolve-LiveEntraDeviceObject -Times 0 -Exactly
    }

    It 'refuses a changed actual SDK tenant before reusing the bound record' {
        $script:device.TenantId = $script:tenant
        Mock Get-MgContext { return @{ TenantId = $script:otherTenant } }
        { Resolve-LiveAutopilotContext -Device $script:device } | Should -Throw '*context TenantId changed*'
        Should -Invoke Resolve-LiveAutopilotDeviceBySerial -Times 0 -Exactly
    }

    It 'refuses disconnected or simulated Live sessions' {
        foreach ($session in @(@{ Connected = $false; IsSimulated = $false; TenantId = $script:tenant }, @{ Connected = $true; IsSimulated = $true; TenantId = $script:tenant })) {
            $script:GraphSession = $session
            { Resolve-LiveAutopilotContext -Device $script:device } | Should -Throw '*non-simulated*'
        }
        Should -Invoke Resolve-LiveAutopilotDeviceBySerial -Times 0 -Exactly
    }

    It 'fails closed for invalid TenantId on <Surface>' -ForEach @(
        @{ Surface = 'Session' }, @{ Surface = 'Context' }, @{ Surface = 'Device' }
    ) {
        foreach ($invalid in @($null, 42, @('text'), '', ' ', 'not-a-guid')) {
            if ($Surface -eq 'Device' -and $null -ne $invalid -and $invalid -ceq '') { continue }
            $script:GraphSession.TenantId = $script:tenant
            $script:device.TenantId = $script:tenant
            $script:actualTenant = $script:tenant
            if ($Surface -eq 'Session') { $script:GraphSession.TenantId = $invalid }
            elseif ($Surface -eq 'Device') { $script:device.TenantId = $invalid }
            else { $script:actualTenant = $invalid }
            Mock Get-MgContext { return @{ TenantId = $script:actualTenant } }
            { Resolve-LiveAutopilotContext -Device $script:device } | Should -Throw '*GUID*'
        }
        Should -Invoke Resolve-LiveAutopilotDeviceBySerial -Times 0 -Exactly
    }

    It 'requires deliberate migration for unbound legacy <Field>' -ForEach @(
        @{ Field = 'AutopilotDeviceId'; Value = 'cached' }, @{ Field = 'ManagedDeviceId'; Value = 'cached' },
        @{ Field = 'AzureAdDeviceId'; Value = 'cached' }, @{ Field = 'EntraDeviceId'; Value = 'cached' },
        @{ Field = 'Steps'; Value = @{ A = $false } }, @{ Field = 'RecoveryHistory'; Value = @(@{ Stage = 'Started' }) },
        @{ Field = 'RecoveryActive'; Value = $true }, @{ Field = 'RecoveryReason'; Value = 'Failure' },
        @{ Field = 'RecoveryStartedAt'; Value = [DateTime]'2026-10-08' }, @{ Field = 'Status'; Value = 'completed' },
        @{ Field = 'IsCompletionVerified'; Value = $true }, @{ Field = 'CompletedAt'; Value = [DateTime]'2026-10-08' }
    ) {
        $script:device[$Field] = $Value
        $before = $script:device | ConvertTo-Json -Depth 10 -Compress
        { Resolve-LiveAutopilotContext -Device $script:device } | Should -Throw '*deliberate tenant migration*'
        ($script:device | ConvertTo-Json -Depth 10 -Compress) | Should -BeExactly $before
        Should -Invoke Resolve-LiveAutopilotDeviceBySerial -Times 0 -Exactly
    }

    It 'binds tenant and resolved IDs only after all successful reads' {
        Mock Resolve-LiveEntraDeviceObject {
            $script:device.TenantId | Should -BeExactly ''
            $script:device.AutopilotDeviceId | Should -BeExactly ''
            return @{ id = 'entra-new' }
        }
        $null = Resolve-LiveAutopilotContext -Device $script:device
        $script:device.TenantId | Should -BeExactly $script:tenant
        $script:device.AutopilotDeviceId | Should -Be 'ap-new'
        $script:device.ManagedDeviceId | Should -Be 'managed-new'
        $script:device.EntraDeviceId | Should -Be 'entra-new'
    }

    It 'leaves a clean unbound record unchanged after a <Surface> read failure' -ForEach @(
        @{ Surface = 'Autopilot' }, @{ Surface = 'Managed' }, @{ Surface = 'Entra' }
    ) {
        $before = $script:device | ConvertTo-Json -Depth 10 -Compress
        if ($Surface -eq 'Autopilot') { Mock Resolve-LiveAutopilotDeviceBySerial { throw 'Synthetic read failure' } }
        elseif ($Surface -eq 'Managed') { Mock Resolve-LiveManagedDeviceBySerial { throw 'Synthetic read failure' } }
        else { Mock Resolve-LiveEntraDeviceObject { throw 'Synthetic read failure' } }
        { Resolve-LiveAutopilotContext -Device $script:device } | Should -Throw '*Synthetic read failure*'
        ($script:device | ConvertTo-Json -Depth 10 -Compress) | Should -BeExactly $before
    }

    It 'binds a clean record after complete absent serial reads without inventing IDs' {
        Mock Resolve-LiveAutopilotDeviceBySerial { return $null }
        Mock Resolve-LiveManagedDeviceBySerial { return $null }
        $null = Resolve-LiveAutopilotContext -Device $script:device
        $script:device.TenantId | Should -Be $script:tenant
        $script:device.AutopilotDeviceId | Should -BeExactly ''
        Should -Invoke Resolve-LiveEntraDeviceObject -Times 0 -Exactly
    }

    It 'blocks wrong-tenant <Action> without dispatch or record mutation' -ForEach @(
        @{ Action = 'ConfirmImagingAndOobe' }, @{ Action = 'ConfirmReseal' }, @{ Action = 'ConfirmBootToSignIn' },
        @{ Action = 'ConfirmFirstSignIn' }, @{ Action = 'ConfirmApplicationBaseline' },
        @{ Action = 'ConfirmUpdatesAndShutdown' }, @{ Action = 'ConfirmRecoveryReadiness' }
    ) {
        $script:device.TenantId = $script:otherTenant
        $before = $script:device | ConvertTo-Json -Depth 10 -Compress
        $result = Invoke-AutopilotManifestStep -Device $script:device -StepDefinition @{ ActionName = $Action }
        $result.CompletionState | Should -Be 'Blocked'
        $result.Data.Blocked | Should -BeTrue
        Should -Invoke Test-ManifestStepEligibility -Times 0 -Exactly
        Should -Invoke Invoke-StepConfirmPhysicalMilestone -Times 0 -Exactly
        ($script:device | ConvertTo-Json -Depth 10 -Compress) | Should -BeExactly $before
    }

    It 'requires resolution before a new blank device can record physical evidence' {
        $result = Invoke-AutopilotManifestStep -Device $script:device -StepDefinition @{ ActionName = 'ConfirmImagingAndOobe' }
        $result.CompletionState | Should -Be 'Blocked'
        Should -Invoke Invoke-StepConfirmPhysicalMilestone -Times 0 -Exactly
        (Invoke-AutopilotManifestStep -Device $script:device -StepDefinition @{ ActionName = 'ResolveAutopilotDevice' }).Success | Should -BeTrue
    }

    It 'binds authenticated ownership before recording a failed first lookup so retry remains possible' {
        Mock Invoke-StepResolveAutopilotDevice { return New-OperationResult -ActionName 'ResolveAutopilotDevice' -Success $false -Summary 'Synthetic authentication cancellation.' }
        $step = @{ Id = 'A'; ActionName = 'ResolveAutopilotDevice' }
        (Invoke-AutopilotManifestStep -Device $script:device -StepDefinition $step).Success | Should -BeFalse
        $script:device.TenantId | Should -BeExactly $script:tenant
        $script:device.AutopilotDeviceId | Should -BeExactly ''
        $script:device.Steps = @{ A = @{ CompletionState = 'Failed' } }
        (Invoke-AutopilotManifestStep -Device $script:device -StepDefinition $step).CompletionState | Should -Be 'Failed'
        Should -Invoke Invoke-StepResolveAutopilotDevice -Times 2 -Exactly
    }

    It 'permits bound physical evidence and skips all tenant helpers in Demo dispatch' {
        $script:device.TenantId = $script:tenant
        (Invoke-AutopilotManifestStep -Device $script:device -StepDefinition @{ ActionName = 'ConfirmFirstSignIn' }).Success | Should -BeTrue
        $script:Runtime.IsDemoMode = $true
        $script:device.TenantId = 'demo-not-a-tenant'
        Mock Get-LiveTenantBinding { throw 'Demo must not call tenant helpers' }
        (Invoke-AutopilotManifestStep -Device $script:device -StepDefinition @{ ActionName = 'ConfirmFirstSignIn' }).Success | Should -BeTrue
        Should -Invoke Get-LiveTenantBinding -Times 0 -Exactly
    }
}

Describe 'Authenticated session and organisation tenant discovery' {
    BeforeEach {
        $script:Runtime = @{ IsDemoMode = $false }
        $script:tenant = '11111111-1111-1111-1111-111111111111'
        $script:GraphSession = Get-EmptyGraphSession
        $script:RuntimeConfig = @{ graph = @{ authMode = 'Browser'; contextScope = 'Process' }; autopilot = @{ deploymentProfileDisplayName = 'Synthetic profile'; preProvisioningGroupDisplayName = 'Synthetic group' }; demo = @{} }
        $script:Config = @{}
        Mock Get-MgContext { return @{ TenantId = $script:tenant; Account = 'synthetic@example.invalid' } }
        Mock Test-LiveRuntimeConfiguration { return @() }
        Mock Import-RequiredGraphModules { return $true }
        Mock Get-GraphTransportPolicy { return @{} }
        Mock Initialize-GraphTransport {}
        Mock Get-ConfiguredGraphScopes { return @('Synthetic.Scope') }
        Mock Connect-MgGraph {}
        Mock Disconnect-MgGraph {}
        Mock Invoke-MgGraphRequest { return @{ id = 'synthetic-user'; userPrincipalName = 'synthetic@example.invalid' } }
        Mock Invoke-GraphApiRequest { return @{ value = @(@{ id = $script:tenant; displayName = 'Synthetic organisation' }) } }
        Mock Test-IsPlaceholderConfigurationValue { return $false }
        Mock Test-GraphCapabilities { return @(@{ Success = $true }) }
        Mock Write-AutopilotExpressLog {}
        Mock Read-ValidatedInput { return '0' }
    }

    It 'warns about missing remediation <Boundary> access without claiming full readiness or repeating sign-in' -ForEach @(
        @{ Boundary = 'configured'; Configured = @('User.Read.All'); Granted = @('User.Read.All'); Guidance = '*graph.requiredScopes*' },
        @{ Boundary = 'granted'; Configured = @('DeviceManagementScripts.Read.All'); Granted = @('User.Read.All'); Guidance = '*not granted*consent*Reconnect*' }
    ) {
        $script:requestedAccessScopes = $Configured
        $script:actualAccessScopes = $Granted
        $script:expectedAccessGuidance = $Guidance
        Mock Get-ConfiguredGraphScopes { return $script:requestedAccessScopes }
        Mock Get-MgContext { return @{ TenantId = $script:tenant; Account = 'synthetic@example.invalid'; Scopes = $script:actualAccessScopes } }
        Initialize-GraphSession | Should -BeTrue
        $script:GraphSession.Connected | Should -BeTrue
        $script:GraphSession.Scopes | Should -Be $Granted
        Should -Invoke Write-AutopilotExpressLog -Times 1 -Exactly -ParameterFilter {
            $Level -eq 'WARN' -and $Message -like 'Remediation features unavailable:*' -and $Message -like $script:expectedAccessGuidance
        }
        Should -Invoke Write-AutopilotExpressLog -Times 0 -Exactly -ParameterFilter { $Message -like 'Remediation delegated scope checks passed*' }
        Should -Invoke Connect-MgGraph -Times 1 -Exactly
        Should -Invoke Read-ValidatedInput -Times 0 -Exactly
        Should -Invoke Invoke-GraphApiRequest -Times 0 -Exactly -ParameterFilter { $Uri -like '*deviceHealthScripts*' }
    }

    It 'records actual granted scopes without treating a scope check as catalogue service acceptance' {
        Mock Get-ConfiguredGraphScopes { return @('DeviceManagementScripts.Read.All') }
        Mock Get-MgContext { return @{ TenantId = $script:tenant; Account = 'synthetic@example.invalid'; Scopes = @('DeviceManagementScripts.Read.All') } }
        Initialize-GraphSession | Should -BeTrue
        $script:GraphSession.Scopes | Should -Contain 'DeviceManagementScripts.Read.All'
        Should -Invoke Write-AutopilotExpressLog -Times 1 -Exactly -ParameterFilter { $Level -eq 'INFO' -and $Message -like 'Remediation delegated scope checks passed*catalogue service access is verified when opened*' }
        Should -Invoke Invoke-GraphApiRequest -Times 0 -Exactly -ParameterFilter { $Uri -like '*deviceHealthScripts*' }
        Should -Invoke Connect-MgGraph -Times 1 -Exactly
    }

    It 'offers an explicit <Choice> after SDK cancellation without changing the configured preference' -ForEach @(
        @{ Choice = 'D'; ExpectedReady = $true; ExpectedDeviceCode = $true },
        @{ Choice = 'B'; ExpectedReady = $true; ExpectedDeviceCode = $false },
        @{ Choice = 'd'; ExpectedReady = $true; ExpectedDeviceCode = $true },
        @{ Choice = 'b'; ExpectedReady = $true; ExpectedDeviceCode = $false },
        @{ Choice = '0'; ExpectedReady = $false; ExpectedDeviceCode = $false }
    ) {
        $script:RuntimeConfig.graph.authMode = 'DeviceCode'
        $script:RuntimeConfig.graph.expectedTenantId = $script:tenant
        $script:authenticationAttempts = 0
        $script:authenticationChoice = $Choice
        Mock Write-Host {}
        Mock Connect-MgGraph {
            $script:authenticationAttempts++
            if ($script:authenticationAttempts -eq 1) { throw [System.Threading.Tasks.TaskCanceledException]::new('Synthetic cancellation.') }
        }
        Mock Read-ValidatedInput { return $script:authenticationChoice }
        $result = @(Initialize-GraphSession)
        $result.Count | Should -Be 1
        $result[0] | Should -BeOfType ([bool])
        $result[0] | Should -Be $ExpectedReady
        Should -Invoke Read-ValidatedInput -Times 1 -Exactly -ParameterFilter {
            $Default -eq '0' -and $Type -eq 'Choice' -and ($Choices -join ',') -eq 'D,B,0'
        }
        $script:RuntimeConfig.graph.authMode | Should -BeExactly 'DeviceCode'
        if ($ExpectedReady) {
            $script:authenticationAttempts | Should -Be 2
            $expectedDeviceAttempts = if ($ExpectedDeviceCode) { 2 } else { 1 }
            Should -Invoke Connect-MgGraph -Times $expectedDeviceAttempts -Exactly -ParameterFilter { $UseDeviceCode }
            Should -Invoke Connect-MgGraph -Times 2 -Exactly -ParameterFilter { $TenantId -eq $script:tenant -and $ContextScope -eq 'Process' -and $Scopes -contains 'Synthetic.Scope' -and $NoWelcome }
        }
        else {
            $script:authenticationAttempts | Should -Be 1
            Should -Invoke Get-MgContext -Times 0 -Exactly
            Should -Invoke Invoke-MgGraphRequest -Times 0 -Exactly
            $script:GraphSession.Connected | Should -BeFalse
        }
    }

    It 'requires a choice after every SDK failure and cleans up before switching back from Browser' {
        $script:RuntimeConfig.graph.authMode = 'DeviceCode'
        $script:signInChoices = [System.Collections.Generic.Queue[string]]::new()
        foreach ($choice in @('B', 'D', '0')) { $script:signInChoices.Enqueue($choice) }
        $script:attemptedDeviceModes = @()
        $script:signInCleanupCount = 0
        Mock Write-Host {}
        Mock Read-ValidatedInput { return $script:signInChoices.Dequeue() }
        Mock Disconnect-MgGraph { $script:signInCleanupCount++ }
        Mock Connect-MgGraph {
            $script:signInCleanupCount | Should -Be $script:attemptedDeviceModes.Count
            Should -Invoke Read-ValidatedInput -Times $script:attemptedDeviceModes.Count -Exactly
            $script:attemptedDeviceModes += [bool]$UseDeviceCode
            throw [System.UnauthorizedAccessException]::new('Synthetic private policy denial.')
        }
        Initialize-GraphSession | Should -BeFalse
        ($script:attemptedDeviceModes -join ',') | Should -BeExactly 'True,False,True'
        Should -Invoke Read-ValidatedInput -Times 3 -Exactly
        Should -Invoke Get-MgContext -Times 0 -Exactly
        Should -Invoke Invoke-MgGraphRequest -Times 0 -Exactly
        Should -Invoke Write-AutopilotExpressLog -Times 0 -Exactly -ParameterFilter { $Message -like '*private policy denial*' }
        $script:GraphSession.Connected | Should -BeFalse
    }

    It 'does not offer authentication retry after a <Stage> failure' -ForEach @(
        @{ Stage = 'context' }, @{ Stage = 'identity' }, @{ Stage = 'organisation' }, @{ Stage = 'capability' }
    ) {
        Mock Write-Host {}
        if ($Stage -eq 'context') { Mock Get-MgContext { return @{ TenantId = 'invalid-tenant' } } }
        elseif ($Stage -eq 'identity') { Mock Invoke-MgGraphRequest { throw 'Synthetic identity failure.' } }
        elseif ($Stage -eq 'organisation') { Mock Invoke-GraphApiRequest { throw 'Synthetic organisation failure.' } }
        else { Mock Test-GraphCapabilities { return @(@{ Success = $false; Name = 'Synthetic'; Detail = 'Synthetic failure.' }) } }
        Initialize-GraphSession | Should -BeFalse
        Should -Invoke Connect-MgGraph -Times 1 -Exactly
        Should -Invoke Read-ValidatedInput -Times 0 -Exactly
        $script:GraphSession.Connected | Should -BeFalse
    }

    It 'uses the SDK device-code credential without a browser fallback' {
        $script:RuntimeConfig.graph.authMode = 'DeviceCode'
        Initialize-GraphSession | Should -BeTrue
        Should -Invoke Connect-MgGraph -Times 1 -Exactly -ParameterFilter { $UseDeviceCode -and $ContextScope -eq 'Process' }
        Should -Invoke Read-ValidatedInput -Times 0 -Exactly
    }

    It 'displays SDK device-code success-stream instructions without polluting its Boolean result' {
        $script:RuntimeConfig.graph.authMode = 'DeviceCode'
        Mock Connect-MgGraph { Write-Output 'Synthetic device-code sign-in instructions; not a usable code.' }
        Mock Out-Host {}
        $result = @(Initialize-GraphSession)
        $result.Count | Should -Be 1
        $result[0] | Should -BeOfType ([bool])
        $result[0] | Should -BeTrue
        Should -Invoke Out-Host -Times 1 -Exactly -ParameterFilter { $InputObject -eq 'Synthetic device-code sign-in instructions; not a usable code.' }
    }

    It 'preserves instructions when the SDK <Outcome> even when the caller captures the result' -ForEach @(
        @{ Outcome = 'returns successfully'; FailAfterPrompt = $false },
        @{ Outcome = 'throws cancellation'; FailAfterPrompt = $true }
    ) {
        $script:RuntimeConfig.graph.authMode = 'DeviceCode'
        $script:devicePromptObserved = $false
        $script:devicePromptFailure = $FailAfterPrompt
        Mock Write-Host {}
        Mock Out-Host { $script:devicePromptObserved = $true } -ParameterFilter {
            $InputObject -eq 'Synthetic streaming sign-in instructions; not a usable code.'
        }
        Mock Connect-MgGraph {
            Write-Output 'Synthetic streaming sign-in instructions; not a usable code.'
            if ($script:devicePromptFailure) { throw [System.Threading.Tasks.TaskCanceledException]::new('Synthetic authentication cancellation.') }
        }
        Mock Get-MgContext {
            $script:devicePromptObserved | Should -BeTrue
            return @{ TenantId = $script:tenant; Account = 'synthetic@example.invalid' }
        }
        $result = @(Initialize-GraphSession)
        $script:devicePromptObserved | Should -BeTrue
        $result.Count | Should -Be 1
        $result[0] | Should -BeOfType ([bool])
        $result[0] | Should -Be (-not $FailAfterPrompt)
        if ($FailAfterPrompt) {
            Should -Invoke Get-MgContext -Times 0 -Exactly
            Should -Invoke Invoke-MgGraphRequest -Times 0 -Exactly
            $script:GraphSession.Connected | Should -BeFalse
        }
    }

    It 'keeps browser authentication available as an explicit preference' {
        Initialize-GraphSession | Should -BeTrue
        Should -Invoke Connect-MgGraph -Times 1 -Exactly -ParameterFilter { -not $UseDeviceCode }
    }

    It 'captures the actual SDK GUID after Connect before marking Connected' {
        Mock Get-MgContext {
            if (-not $script:GraphSession.Connected) { Should -Invoke Connect-MgGraph -Times 1 -Exactly }
            return @{ TenantId = $script:tenant }
        }
        Mock Invoke-MgGraphRequest { $script:GraphSession.Connected | Should -BeFalse; return @{ id = 'synthetic-user' } }
        Initialize-GraphSession | Should -BeTrue
        $script:GraphSession.TenantId | Should -BeExactly $script:tenant
        $script:GraphSession.Connected | Should -BeTrue
        Should -Invoke Invoke-GraphApiRequest -Times 1 -Exactly -ParameterFilter { $Uri -eq 'https://graph.microsoft.com/v1.0/organization?$select=id,displayName' }
        Should -Invoke Invoke-MgGraphRequest -Times 1 -Exactly -ParameterFilter { $Uri -eq '/v1.0/me?$select=id,displayName,userPrincipalName,mail' }
    }

    It 'reports identity URI failure as a post-sign-in stage without leaking SDK messages' {
        Mock Write-Host {}
        Mock Invoke-MgGraphRequest { throw [System.UriFormatException]::new('Invalid URI: synthetic-secret-response') }
        Initialize-GraphSession | Should -BeFalse
        Should -Invoke Write-AutopilotExpressLog -Times 1 -Exactly -ParameterFilter { $Message -like '*stage: Signed-in identity read*HTTP=unavailable*' -and $Level -eq 'ERROR' }
        Should -Invoke Write-Host -Times 1 -Exactly -ParameterFilter { $Object -like 'URI construction failed*not evidence of missing Intune*' }
        Should -Invoke Write-AutopilotExpressLog -Times 0 -Exactly -ParameterFilter { $Message -like '*synthetic-secret-response*' }
        Should -Invoke Invoke-GraphApiRequest -Times 0 -Exactly
        Should -Invoke Disconnect-MgGraph -Times 1 -Exactly
        $script:GraphSession.Connected | Should -BeFalse
    }

    It 'reports organisation URI failure separately from successful browser and identity checks' {
        Mock Write-Host {}
        Mock Invoke-GraphApiRequest { throw [System.UriFormatException]::new('Invalid URI: synthetic organisation failure') }
        Initialize-GraphSession | Should -BeFalse
        Should -Invoke Write-AutopilotExpressLog -Times 1 -Exactly -ParameterFilter { $Message -like '*stage: Organisation discovery and tenant binding*' -and $Level -eq 'ERROR' }
        Should -Invoke Test-GraphCapabilities -Times 0 -Exactly
        Should -Invoke Disconnect-MgGraph -Times 1 -Exactly
        $script:GraphSession.Connected | Should -BeFalse
    }

    It 'supports the advertised script Verbose common parameter' {
        @($sourceAst.ParamBlock.Attributes | Where-Object { $_.TypeName.Name -eq 'CmdletBinding' }).Count | Should -Be 1
    }

    It 'detects a wrapped URI exception and retains the startup stage when disconnect fails' {
        Mock Write-Host {}
        Mock Write-Verbose {}
        Mock Invoke-GraphApiRequest {
            throw [Exception]::new('Synthetic private outer body', [System.UriFormatException]::new('Synthetic private inner body'))
        }
        Mock Disconnect-MgGraph { Write-Error 'Synthetic private disconnect body' -ErrorAction Stop }
        Initialize-GraphSession | Should -BeFalse
        Should -Invoke Write-AutopilotExpressLog -Times 1 -Exactly -ParameterFilter { $Message -like '*stage: Organisation discovery and tenant binding*HTTP=unavailable*' }
        Should -Invoke Write-Host -Times 1 -Exactly -ParameterFilter { $Object -like 'URI construction failed*' }
        Should -Invoke Write-AutopilotExpressLog -Times 0 -Exactly -ParameterFilter { $Message -like '*private*' }
        Should -Invoke Write-Verbose -Times 0 -Exactly -ParameterFilter { $Message -like '*private*' }
        Should -Invoke Disconnect-MgGraph -Times 1 -Exactly
        Should -Invoke Test-GraphCapabilities -Times 0 -Exactly
        $script:GraphSession.Connected | Should -BeFalse
        $script:GraphSession.TenantId | Should -BeExactly ''
    }

    It 'reports browser sign-in failure without suggesting a successful identity check' {
        Mock Write-Host {}
        Mock Connect-MgGraph { throw 'Synthetic private sign-in body' }
        Initialize-GraphSession | Should -BeFalse
        Should -Invoke Write-AutopilotExpressLog -Times 1 -Exactly -ParameterFilter { $Message -like '*stage: Browser sign-in*' }
        Should -Invoke Write-AutopilotExpressLog -Times 0 -Exactly -ParameterFilter { $Message -like '*returned a valid tenant context*' -or $Message -like '*private*' }
        Should -Invoke Get-MgContext -Times 0 -Exactly
        Should -Invoke Invoke-MgGraphRequest -Times 0 -Exactly
        $script:GraphSession.Connected | Should -BeFalse
    }

    It 'distinguishes HTTP <Status> after sign-in without logging the SDK response' -ForEach @(
        @{ Status = 401; Advice = 'Graph reported HTTP 401.*' },
        @{ Status = 403; Advice = 'Graph reported HTTP 403.*' }
    ) {
        $script:startupStatus = $Status
        Mock Write-Host {}
        Mock Invoke-MgGraphRequest {
            $exception = [Exception]::new('Synthetic confidential SDK body')
            $exception | Add-Member -NotePropertyName ResponseStatusCode -NotePropertyValue $script:startupStatus
            throw $exception
        }
        Initialize-GraphSession | Should -BeFalse
        Should -Invoke Write-Host -Times 1 -Exactly -ParameterFilter { $Object -like $Advice }
        Should -Invoke Write-AutopilotExpressLog -Times 0 -Exactly -ParameterFilter { $Message -like '*confidential SDK body*' }
        Should -Invoke Disconnect-MgGraph -Times 1 -Exactly
    }

    It 'closes the SDK session with no Connected leftovers for invalid context TenantId' {
        foreach ($invalid in @($null, '', 'tenant-name', 42)) {
            $script:actualTenant = $invalid
            Mock Get-MgContext { return @{ TenantId = $script:actualTenant } }
            Initialize-GraphSession | Should -BeFalse
            $script:GraphSession.Connected | Should -BeFalse
            $script:GraphSession.TenantId | Should -BeExactly ''
        }
        Should -Invoke Invoke-MgGraphRequest -Times 0 -Exactly
        Should -Invoke Disconnect-MgGraph -Times 4 -Exactly
    }

    It 'fails closed and disconnects for <Label> organisation discovery' -ForEach @(
        @{ Label = 'empty'; Response = @{ value = @() } },
        @{ Label = 'malformed'; Response = @{ value = @{ id = 'one' } } },
        @{ Label = 'wrong tenant'; Response = @{ value = @(@{ id = '22222222-2222-2222-2222-222222222222'; displayName = 'Other' }) } },
        @{ Label = 'missing name'; Response = @{ value = @(@{ id = '11111111-1111-1111-1111-111111111111' }) } },
        @{ Label = 'duplicate'; Response = @{ value = @(@{ id = '11111111-1111-1111-1111-111111111111'; displayName = 'One' }, @{ id = '11111111-1111-1111-1111-111111111111'; displayName = 'One' }) } },
        @{ Label = 'unsafe continuation'; Response = @{ value = @(); '@odata.nextLink' = 'https://example.invalid/organization' } }
    ) {
        $script:organisationResponse = $Response
        Mock Invoke-GraphApiRequest { return $script:organisationResponse }
        Initialize-GraphSession | Should -BeFalse
        $script:GraphSession.Connected | Should -BeFalse
        $script:GraphSession.TenantId | Should -BeExactly ''
        Should -Invoke Disconnect-MgGraph -Times 1 -Exactly
        Should -Invoke Test-GraphCapabilities -Times 0 -Exactly
    }

    It 'follows organisation continuations completely and refuses multiple identities' {
        Mock Invoke-GraphApiRequest {
            if ($Uri -like '*skiptoken*') { return @{ value = @(@{ id = '22222222-2222-2222-2222-222222222222'; displayName = 'Other' }) } }
            return @{ value = @(@{ id = $script:tenant; displayName = 'One' }); '@odata.nextLink' = 'https://graph.microsoft.com/v1.0/organization?$skiptoken=synthetic' }
        }
        Initialize-GraphSession | Should -BeFalse
        Should -Invoke Invoke-GraphApiRequest -Times 2 -Exactly
        $script:GraphSession.Connected | Should -BeFalse
    }

    It 'closes after organisation request errors or failed capability checks' {
        Mock Invoke-GraphApiRequest { throw 'Synthetic discovery denied' }
        Initialize-GraphSession | Should -BeFalse
        $script:GraphSession.Connected | Should -BeFalse
        Mock Invoke-GraphApiRequest { return @{ value = @(@{ id = $script:tenant; displayName = 'One' }) } }
        Mock Test-GraphCapabilities { return @(@{ Name = 'Synthetic read'; Success = $false; Detail = 'Denied' }) }
        Initialize-GraphSession | Should -BeFalse
        $script:GraphSession.Connected | Should -BeFalse
        Should -Invoke Disconnect-MgGraph -Times 2 -Exactly
    }

    It 'keeps Demo simulated with no actual tenant discovery or authentication' {
        $script:Runtime.IsDemoMode = $true
        Mock Get-LiveTenantBinding { throw 'Demo must not call tenant helper' }
        Initialize-GraphSession | Should -BeTrue
        $script:GraphSession.IsSimulated | Should -BeTrue
        $script:GraphSession.TenantId | Should -BeExactly ''
        Should -Invoke Get-MgContext -Times 0 -Exactly
        Should -Invoke Connect-MgGraph -Times 0 -Exactly
        Should -Invoke Invoke-GraphApiRequest -Times 0 -Exactly
        Should -Invoke Get-LiveTenantBinding -Times 0 -Exactly
    }
}

Describe 'TenantId persisted state and audit integration' {
    BeforeEach {
        $script:Runtime = @{ IsDemoMode = $false }
        $script:tenant = '11111111-1111-1111-1111-111111111111'
        $script:jsonFixture = '{"Serial":"TENANT-TEST-01"}'
        Mock Test-Path { return $true }
        Mock Get-Content { return $script:jsonFixture }
        Mock Write-AutopilotExpressLog {}
        Mock Write-Utf8File { $script:auditContent = $Content }
    }

    It 'loads missing legacy TenantId as empty without adopting a session tenant' {
        $script:GraphSession = @{ TenantId = $script:tenant }
        $records = Get-UserDeviceRecords
        $records[0].TenantId | Should -BeExactly ''
        Should -Invoke Write-Utf8File -Times 0 -Exactly
    }

    It 'round trips a bound TenantId using the existing generic serializer' {
        $device = New-EmptyDeviceRecord
        $device.Serial = 'TENANT-TEST-01'
        $device.TenantId = $script:tenant
        $script:jsonFixture = ConvertTo-PersistedDeviceRecord -Record $device | ConvertTo-Json -Depth 10
        $records = Get-UserDeviceRecords
        $records[0].TenantId | Should -BeExactly $script:tenant
    }

    It 'rejects non-text null whitespace and non-GUID persisted TenantId' {
        foreach ($invalid in @($null, 42, $false, @('text'), @{ value = 'text' }, ' ', 'not-a-guid')) {
            $script:jsonFixture = @{ Serial = 'TENANT-TEST-01'; TenantId = $invalid } | ConvertTo-Json -Depth 10
            { Get-UserDeviceRecords } | Should -Throw '*TenantId*'
        }
        Should -Invoke Write-Utf8File -Times 0 -Exactly
    }

    It 'includes the record TenantId in the audit ledger without adopting context' {
        Mock Test-Path { return $false }
        $device = New-EmptyDeviceRecord
        $device.RecordId = 'synthetic-record'
        $device.Serial = 'TENANT-TEST-01'
        $device.TenantId = $script:tenant
        Update-MasterAuditLedger -Records @($device)
        ($script:auditContent | ConvertFrom-Json).TenantId | Should -BeExactly $script:tenant
    }
}