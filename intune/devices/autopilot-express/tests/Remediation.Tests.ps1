<#
.SYNOPSIS
    Offline device-remediation catalogue, preferences, submission and navigation checks.
.DESCRIPTION
    Extract production functions without starting the CLI. All Graph and clipboard
    boundaries are isolated; fixtures use temporary storage, never operational files.
#>
BeforeAll {
    $sourcePath = Join-Path (Split-Path -Parent $PSScriptRoot) 'autopilot-express.ps1'
    $tokens = $null
    $parseErrors = $null
    $script:remediationAst = [System.Management.Automation.Language.Parser]::ParseFile($sourcePath, [ref]$tokens, [ref]$parseErrors)
    if ($parseErrors.Count) { throw ($parseErrors.Message -join '; ') }
    $definition = $script:remediationAst.Find({ param($node) $node -is [System.Management.Automation.Language.FunctionDefinitionAst] -and $node.Name -eq 'Get-DeviceRemediationCatalog' }, $true)
    if (-not $definition) { throw 'Missing Get-DeviceRemediationCatalog.' }
    Set-Item -Path Function:Get-DeviceRemediationCatalog -Value $definition.Body.GetScriptBlock()
    function Get-MgContext { throw 'Unexpected Graph context lookup.' }
    function Get-GraphDiscoveryCollection { param($Uri, $RequiredTextProperty) throw ('Unexpected discovery: {0}/{1}' -f $Uri, $RequiredTextProperty) }
    function Get-LiveTenantBinding { param($Device, [switch]$AllowUnbound) throw ('Unexpected tenant lookup: {0}/{1}' -f $Device.Serial, $AllowUnbound) }
    function Invoke-GraphApiRequest { param($Method, $Uri, $Body) throw ('Unexpected request {0}/{1}/{2}' -f $Method, $Uri, $Body) }
    function Resolve-LiveAutopilotContext { param($Device) throw ('Unexpected device resolution: {0}' -f $Device.Serial) }
    function Read-ValidatedInput { param($Prompt, $Default, $Type, $Choices) throw ('Unexpected input: {0}/{1}/{2}/{3}' -f $Prompt, $Default, $Type, $Choices) }
    function Write-AutopilotExpressLog { param($Message, $Level) throw ('Unexpected log: {0}/{1}' -f $Message, $Level) }
    function Get-GraphOperationFailureMessage { param($RequestError) return $RequestError.Exception.Message }
    function Get-GraphTransportFailure { param($RequestError) return @{ Status = $null; ExceptionType = $RequestError.Exception.GetType().FullName } }
    function Show-ScriptScreen { param($Title) throw ('Unexpected screen {0}' -f $Title) }
    function Select-DeviceFromRecords { param($Records, $Purpose, [switch]$IncludeCompleted) throw ('Unexpected picker {0}/{1}/{2}' -f $Records.Value.Count, $Purpose, $IncludeCompleted) }
    foreach ($name in @('Assert-DeviceRemediationAccess', 'Get-ConfiguredGraphScopes', 'Get-GraphOperationFailureMessage', 'Get-DeviceActionContext', 'Get-DeviceActionStatePath', 'Assert-DeviceActionState', 'Get-DeviceActionState', 'Save-DeviceActionState', 'ConvertTo-NormalisedValue', 'Assert-FileWriteRecoveryState', 'Write-Utf8File', 'New-ParentDirectory', 'Get-StorageFileEncoding', 'Resolve-DeviceActionTarget', 'Get-DeviceRemediationObservation', 'Invoke-DeviceRemediation', 'Get-DeviceRemediationRunStatus', 'Copy-DeviceIntuneOverviewLink', 'Select-RemediationMenuItem', 'Show-RemediationQuickRunSettings', 'Show-DeviceActions', 'ConvertTo-OptionalInteger')) {
        $definition = $script:remediationAst.Find({ param($node) $node -is [System.Management.Automation.Language.FunctionDefinitionAst] -and $node.Name -eq $name }, $true)
        if (-not $definition) { throw ('Missing {0}.' -f $name) }
        Set-Item -Path ('Function:{0}' -f $name) -Value $definition.Body.GetScriptBlock()
    }
}

Describe 'Remediation delegated access readiness' {
    BeforeAll {
        foreach ($name in @('Assert-DeviceRemediationAccess', 'Get-ConfiguredGraphScopes')) {
            $definition = $script:remediationAst.Find({ param($node) $node -is [System.Management.Automation.Language.FunctionDefinitionAst] -and $node.Name -eq $name }, $true)
            if (-not $definition) { throw ('Missing {0}.' -f $name) }
            Set-Item -Path ('Function:{0}' -f $name) -Value $definition.Body.GetScriptBlock()
        }
    }
    BeforeEach {
        $script:Runtime = @{ IsDemoMode = $false }
        $script:RuntimeConfig = @{ graph = @{ requiredScopes = @('DeviceManagementScripts.Read.All', 'DeviceManagementManagedDevices.PrivilegedOperations.All') } }
        $script:grantedScopes = @($script:RuntimeConfig.graph.requiredScopes)
        Mock Get-MgContext { return @{ Scopes = $script:grantedScopes } }
    }
    It 'identifies an explicit old configuration without widening it or contacting Graph' {
        $script:RuntimeConfig.graph.requiredScopes = @('User.Read.All')
        { Assert-DeviceRemediationAccess } | Should -Throw '*graph.requiredScopes*DeviceManagementScripts.Read.All*restart*'
        $script:RuntimeConfig.graph.requiredScopes | Should -Be @('User.Read.All')
        Should -Invoke Get-MgContext -Times 0 -Exactly
    }
    It 'identifies a session missing the configured permission rather than claiming readiness' {
        $script:grantedScopes = @('User.Read.All')
        { Assert-DeviceRemediationAccess } | Should -Throw '*granted*DeviceManagementScripts.Read.All*consent*Reconnect*'
    }
    It 'accepts granted read scope for discovery without requiring execution privilege' {
        $script:grantedScopes = @('DeviceManagementScripts.Read.All')
        { Assert-DeviceRemediationAccess } | Should -Not -Throw
    }
    It 'accepts an already approved read-write equivalent without requesting extra consent' {
        $script:RuntimeConfig.graph.requiredScopes = @('DeviceManagementScripts.ReadWrite.All')
        $script:grantedScopes = @('DeviceManagementScripts.ReadWrite.All')
        { Assert-DeviceRemediationAccess } | Should -Not -Throw
    }
    It 'requires granted execution privilege only for submission' {
        $script:grantedScopes = @('DeviceManagementScripts.Read.All')
        { Assert-DeviceRemediationAccess -Operation Run } | Should -Throw '*granted*PrivilegedOperations.All*'
    }
    It 'leaves Demo disconnected from scope and consent checks' {
        $script:Runtime.IsDemoMode = $true
        { Assert-DeviceRemediationAccess -Operation Run } | Should -Not -Throw
        Should -Invoke Get-MgContext -Times 0 -Exactly
    }
}

Describe 'Device remediation catalogue' {
    BeforeEach {
        $script:RuntimeConfig = @{ graph = @{ requiredScopes = @('DeviceManagementScripts.Read.All', 'DeviceManagementManagedDevices.PrivilegedOperations.All') } }
        Mock Get-MgContext { return @{ Scopes = @('DeviceManagementScripts.Read.All', 'DeviceManagementManagedDevices.PrivilegedOperations.All') } }
        $script:Runtime = @{ IsDemoMode = $false }
        Mock Get-DeviceActionContext { return @{ TenantId = 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa' } }
        $script:catalog = @(
            @{ id = '22222222-2222-2222-2222-222222222222'; displayName = 'Zulu'; version = '2'; publisher = 'Example' },
            @{ id = '11111111-1111-1111-1111-111111111111'; displayName = 'Alpha'; version = '1'; publisher = 'Example' }
        )
        Mock Get-GraphDiscoveryCollection { return , $script:catalog }
    }
    It 'requests metadata only and sorts by display name' {
        $catalog = Get-DeviceRemediationCatalog
        $catalog.Count | Should -Be 2
        $catalog[0].displayName | Should -BeExactly Alpha
        Should -Invoke Get-GraphDiscoveryCollection -Times 1 -Exactly -ParameterFilter {
            $Uri -like 'https://graph.microsoft.com/beta/deviceManagement/deviceHealthScripts?*' -and
            $Uri -like '*$select=id,displayName,*' -and $Uri -notmatch 'ScriptContent'
        }
    }
    It 'retains distinct immutable identities for duplicate names' {
        $script:catalog[1].displayName = 'Zulu'
        $catalog = Get-DeviceRemediationCatalog
        $catalog.Count | Should -Be 2
        @($catalog | ForEach-Object { $_.id } | Select-Object -Unique).Count | Should -Be 2
    }
    It 'returns an empty catalogue without inventing packages' {
        $script:catalog = @()
        (Get-DeviceRemediationCatalog).Count | Should -Be 0
    }
    It 'refuses missing <Boundary> permission before any catalogue request' -ForEach @(
        @{ Boundary = 'configured' }, @{ Boundary = 'granted' }
    ) {
        if ($Boundary -eq 'configured') { $script:RuntimeConfig.graph.requiredScopes = @('User.Read.All') }
        else { Mock Get-MgContext { return @{ Scopes = @('User.Read.All') } } }
        { Get-DeviceRemediationCatalog } | Should -Throw '*Remediation*DeviceManagementScripts.Read.All*'
        Should -Invoke Get-GraphDiscoveryCollection -Times 0 -Exactly
    }
    It 'refuses invalid package identity before publishing a partial catalogue' {
        $script:catalog[1].id = '../other'
        { Get-DeviceRemediationCatalog } | Should -Throw '*identity*'
    }
    It 'does not hide a discovery denial' {
        Mock Get-GraphDiscoveryCollection { throw 'Synthetic catalogue denial.' }
        { Get-DeviceRemediationCatalog } | Should -Throw '*catalogue denial*'
    }
    It 'explains a service 403 without converting it to an empty catalogue or retrying' {
        Mock Get-GraphTransportFailure { return @{ Status = 403; RequestId = 'synthetic-request-id' } }
        Mock Get-GraphDiscoveryCollection {
            $exception = [Exception]::new('synthetic-sensitive-response-body')
            $exception | Add-Member -NotePropertyName ResponseStatusCode -NotePropertyValue 403
            throw $exception
        }
        $failure = { Get-DeviceRemediationCatalog } | Should -Throw '*HTTP 403*DeviceManagementScripts.Read.All*consent*Reconnect*' -PassThru
        $failure.Exception.Message | Should -Not -Match 'synthetic-sensitive-response-body'
        $failure.Exception.Message | Should -Match 'synthetic-request-id'
        Should -Invoke Get-GraphDiscoveryCollection -Times 1 -Exactly
    }
    It 'keeps Demo discovery disconnected from Graph' {
        $script:Runtime.IsDemoMode = $true
        (Get-DeviceRemediationCatalog).Count | Should -BeGreaterThan 0
        Should -Invoke Get-GraphDiscoveryCollection -Times 0 -Exactly
    }
}

Describe 'Tenant-bound device-action preferences' {
    BeforeEach {
        $script:originalLocalAppData = $env:LOCALAPPDATA
        $env:LOCALAPPDATA = Join-Path $TestDrive ([guid]::NewGuid().ToString('N'))
        $script:Runtime = @{ IsDemoMode = $false }
        $script:tenant = 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa'
        Mock Get-LiveTenantBinding { return $script:tenant }
    }
    AfterEach { $env:LOCALAPPDATA = $script:originalLocalAppData }
    It 'starts with nothing enabled and creates no file on read' {
        $state = Get-DeviceActionState
        $state.EnabledIds.Count | Should -Be 0
        $state.Runs.Count | Should -Be 0
        Test-Path -LiteralPath (Get-DeviceActionStatePath -Context (Get-DeviceActionContext)) | Should -BeFalse
    }
    It 'round-trips empty and populated arrays through the real guarded writer' {
        $state = Get-DeviceActionState
        Save-DeviceActionState -State $state
        (Get-DeviceActionState).EnabledIds.Count | Should -Be 0
        $state.EnabledIds = @('11111111-1111-1111-1111-111111111111')
        Save-DeviceActionState -State $state
        (Get-DeviceActionState).EnabledIds[0] | Should -BeExactly $state.EnabledIds[0]
        $state.Revision | Should -Be 2
    }
    It 'keeps tenant selections separate' {
        $state = Get-DeviceActionState
        $state.EnabledIds = @('11111111-1111-1111-1111-111111111111')
        Save-DeviceActionState -State $state
        $script:tenant = 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb'
        (Get-DeviceActionState).EnabledIds.Count | Should -Be 0
        { Save-DeviceActionState -State $state } | Should -Throw '*foreign*'
    }
    It 'keeps Demo settings separate from Live' {
        $live = Get-DeviceActionStatePath -Context (Get-DeviceActionContext)
        $script:Runtime.IsDemoMode = $true
        $demo = Get-DeviceActionStatePath -Context (Get-DeviceActionContext)
        $demo | Should -Not -BeExactly $live
    }
    It 'refuses stale revision saves instead of overwriting another change' {
        $first = Get-DeviceActionState
        $stale = Get-DeviceActionState
        Save-DeviceActionState -State $first
        { Save-DeviceActionState -State $stale } | Should -Throw '*another session*'
        (Get-DeviceActionState).Revision | Should -Be 1
    }
    It 'preserves interrupted-write evidence and refuses a default reset' {
        $path = Get-DeviceActionStatePath -Context (Get-DeviceActionContext)
        New-ParentDirectory -Path $path
        Set-Content -LiteralPath ('{0}.pending' -f $path) -Value 'retained evidence'
        { Get-DeviceActionState } | Should -Throw '*Interrupted save*'
        Test-Path -LiteralPath ('{0}.pending' -f $path) | Should -BeTrue
    }
    It 'refuses unsafe package IDs' {
        $state = Get-DeviceActionState
        $state.EnabledIds = @('../other')
        { Save-DeviceActionState -State $state } | Should -Throw '*package identity*'
    }
    It 'supports WhatIf without creating the state file' {
        Save-DeviceActionState -State (Get-DeviceActionState) -WhatIf
        Test-Path -LiteralPath (Get-DeviceActionStatePath -Context (Get-DeviceActionContext)) | Should -BeFalse
    }
}

Describe 'Remediation submission, execution evidence and clipboard' {
    BeforeEach {
        $script:RuntimeConfig = @{ graph = @{ requiredScopes = @('DeviceManagementScripts.Read.All', 'DeviceManagementManagedDevices.PrivilegedOperations.All') } }
        Mock Get-MgContext { return @{ Scopes = @('DeviceManagementScripts.Read.All', 'DeviceManagementManagedDevices.PrivilegedOperations.All') } }
        $script:originalLocalAppData = $env:LOCALAPPDATA
        $env:LOCALAPPDATA = Join-Path $TestDrive ([guid]::NewGuid().ToString('N'))
        $script:Runtime = @{ IsDemoMode = $false }
        $script:tenant = 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa'
        $script:packageId = '11111111-1111-1111-1111-111111111111'
        $script:managedId = '22222222-2222-2222-2222-222222222222'
        $script:device = @{ RecordId = '33333333-3333-3333-3333-333333333333'; Serial = 'TEST-SERIAL'; ManagedDeviceId = 'stale'; Steps = @{} }
        Mock Get-LiveTenantBinding { return $script:tenant }
        Mock Resolve-LiveAutopilotContext { $Device.ManagedDeviceId = $script:managedId; $Device.TenantId = $script:tenant }
        Mock Read-ValidatedInput { return 'Y' }
        Mock Write-Host {}
        Mock Write-AutopilotExpressLog {}
        Mock Get-DeviceRemediationObservation { return $null }
        Mock Invoke-GraphApiRequest {
            if ($Method -eq 'GET' -and $Uri -like '*/deviceHealthScripts/*') { return @{ id = $script:packageId; displayName = 'Example retry'; version = '1' } }
            if ($Method -eq 'GET' -and $Uri -like '*/managedDevices/*') { return @{ id = $script:managedId; serialNumber = 'TEST-SERIAL'; operatingSystem = 'Windows' } }
            if ($Method -eq 'POST') { return $null }
            throw 'Unexpected fixture request.'
        }
        Mock Set-Clipboard {}
        Mock Get-Clipboard { return ('https://intune.microsoft.com/#view/Microsoft_Intune_Devices/DeviceSettingsMenuBlade/~/overview/mdmDeviceId/{0}' -f $script:managedId) }
        $state = Get-DeviceActionState
        $state.EnabledIds = @($script:packageId)
        Save-DeviceActionState -State $state
    }
    AfterEach { $env:LOCALAPPDATA = $script:originalLocalAppData }
    It 'refuses missing execution privilege before device reads, confirmation, intent or POST' {
        Mock Get-MgContext { return @{ Scopes = @('DeviceManagementScripts.Read.All') } }
        { Invoke-DeviceRemediation -Device $script:device -PackageId $script:packageId } | Should -Throw '*granted*PrivilegedOperations.All*'
        (Get-DeviceActionState).Runs.Count | Should -Be 0
        Should -Invoke Invoke-GraphApiRequest -Times 0 -Exactly
        Should -Invoke Read-ValidatedInput -Times 0 -Exactly
    }
    It 'persists acceptance after one exact POST and never treats it as execution' {
        $result = Invoke-DeviceRemediation -Device $script:device -PackageId $script:packageId
        $result.State | Should -Be Accepted
        (Get-DeviceActionState).Runs[0].State | Should -Be Accepted
        Should -Invoke Invoke-GraphApiRequest -Times 1 -Exactly -ParameterFilter { $Method -eq 'POST' -and $Uri -like '*/managedDevices/22222222-2222-2222-2222-222222222222/initiateOnDemandProactiveRemediation' -and $Body.scriptPolicyId -eq $script:packageId }
        $script:device.ManagedDeviceId | Should -BeExactly stale
        $script:device.Steps.Count | Should -Be 0
    }
    It 'retains a durable pre-submission intent before the request reaches Graph' {
        Mock Invoke-GraphApiRequest { (Get-DeviceActionState).Runs[0].State | Should -Be Preparing } -ParameterFilter { $Method -eq 'POST' }
        (Invoke-DeviceRemediation -Device $script:device -PackageId $script:packageId).State | Should -Be Accepted
    }
    It 'does not replay an accepted request after reloading stored evidence' {
        [void](Invoke-DeviceRemediation -Device $script:device -PackageId $script:packageId)
        (Invoke-DeviceRemediation -Device $script:device -PackageId $script:packageId).Summary | Should -BeLike '*no submission was replayed*'
        Should -Invoke Invoke-GraphApiRequest -Times 1 -Exactly -ParameterFilter { $Method -eq 'POST' }
    }
    It 'retains uncertainty after a lost response and refuses replay' {
        Mock Invoke-GraphApiRequest { throw 'Synthetic lost response.' } -ParameterFilter { $Method -eq 'POST' }
        (Invoke-DeviceRemediation -Device $script:device -PackageId $script:packageId).State | Should -Be Uncertain
        (Invoke-DeviceRemediation -Device $script:device -PackageId $script:packageId).State | Should -Be Uncertain
        Should -Invoke Invoke-GraphApiRequest -Times 1 -Exactly -ParameterFilter { $Method -eq 'POST' }
    }
    It 'cancels on No and labels the default No without intent or POST' {
        Mock Read-ValidatedInput { return 'N' }
        (Invoke-DeviceRemediation -Device $script:device -PackageId $script:packageId).State | Should -Be Cancelled
        (Get-DeviceActionState).Runs.Count | Should -Be 0
        Should -Invoke Read-ValidatedInput -Times 1 -Exactly -ParameterFilter { $Default -eq 'N' }
        Should -Invoke Invoke-GraphApiRequest -Times 0 -Exactly -ParameterFilter { $Method -eq 'POST' }
    }
    It 'refuses a disabled package before any request' {
        { Invoke-DeviceRemediation -Device $script:device -PackageId '44444444-4444-4444-4444-444444444444' } | Should -Throw '*not enabled*'
        Should -Invoke Invoke-GraphApiRequest -Times 0 -Exactly
    }
    It 'keeps an old report from confirming a new request' {
        $run = Invoke-DeviceRemediation -Device $script:device -PackageId $script:packageId
        Mock Get-DeviceRemediationObservation { return @{ lastStateUpdateDateTime = '2020-01-01T00:00:00Z'; detectionState = 'success'; remediationState = 'success' } }
        (Get-DeviceRemediationRunStatus -Device $script:device -RunId $run.RunId).State | Should -Be Accepted
        Should -Invoke Invoke-GraphApiRequest -Times 1 -Exactly -ParameterFilter { $Method -eq 'POST' }
    }
    It 'records fresh execution separately with an explicit correlation limitation' {
        $run = Invoke-DeviceRemediation -Device $script:device -PackageId $script:packageId
        Mock Get-DeviceRemediationObservation { return @{ lastStateUpdateDateTime = [DateTimeOffset]::UtcNow.ToString('o'); detectionState = 'fail'; remediationState = 'remediationFailed' } }
        $result = Get-DeviceRemediationRunStatus -Device $script:device -RunId $run.RunId
        $result.State | Should -Be ExecutionObserved
        $result.RemediationState | Should -Be remediationFailed
        $result.Summary | Should -BeLike '*cannot be uniquely correlated*'
        Should -Invoke Invoke-GraphApiRequest -Times 1 -Exactly -ParameterFilter { $Method -eq 'POST' }
    }
    It 'refuses changed managed-device identity for saved status' {
        $run = Invoke-DeviceRemediation -Device $script:device -PackageId $script:packageId
        $script:managedId = '55555555-5555-5555-5555-555555555555'
        { Get-DeviceRemediationRunStatus -Device $script:device -RunId $run.RunId } | Should -Throw '*target changed*'
    }
    It 'copies the fresh Intune ID rather than the stale or other directory identities' {
        $result = Copy-DeviceIntuneOverviewLink -Device $script:device
        $result.State | Should -Be Copied
        $result.Url | Should -BeLike '*mdmDeviceId/22222222-2222-2222-2222-222222222222'
        Should -Invoke Set-Clipboard -Times 1 -Exactly -ParameterFilter { $Value -eq $result.Url }
    }
    It 'does not report copy success when clipboard read-back differs' {
        Mock Get-Clipboard { return 'different contents' }
        { Copy-DeviceIntuneOverviewLink -Device $script:device } | Should -Throw '*read-back*'
    }
    It 'never modifies the real clipboard in Demo' {
        $script:Runtime.IsDemoMode = $true
        (Copy-DeviceIntuneOverviewLink -Device $script:device).State | Should -Be Simulated
        Should -Invoke Set-Clipboard -Times 0 -Exactly
    }
    It 'simulates one enabled Demo package without Graph access' {
        $script:Runtime.IsDemoMode = $true
        $state = Get-DeviceActionState
        $state.EnabledIds = @($script:packageId)
        Save-DeviceActionState -State $state
        $result = Invoke-DeviceRemediation -Device $script:device -PackageId $script:packageId
        $result.State | Should -Be Accepted
        $result.Summary | Should -BeLike 'Demo:*'
        Should -Invoke Invoke-GraphApiRequest -Times 0 -Exactly
    }
    It 'refuses a non-Windows or mismatched fresh managed device' {
        Mock Invoke-GraphApiRequest { return @{ id = $script:managedId; serialNumber = 'OTHER'; operatingSystem = 'Android' } }
        { Copy-DeviceIntuneOverviewLink -Device $script:device } | Should -Throw '*does not match*'
        Should -Invoke Set-Clipboard -Times 0 -Exactly
    }
    It 'does not submit if durable intent persistence fails' {
        Mock Save-DeviceActionState { throw 'Synthetic intent save denial.' }
        { Invoke-DeviceRemediation -Device $script:device -PackageId $script:packageId } | Should -Throw '*intent save*'
        Should -Invoke Invoke-GraphApiRequest -Times 0 -Exactly -ParameterFilter { $Method -eq 'POST' }
    }
    It 'retains Preparing and refuses replay if accepted outcome persistence fails' {
        $definition = $script:remediationAst.Find({ param($node) $node -is [System.Management.Automation.Language.FunctionDefinitionAst] -and $node.Name -eq 'Save-DeviceActionState' }, $true)
        $script:stateWriter = $definition.Body.GetScriptBlock()
        Mock Save-DeviceActionState {
            if ($State.Runs.Count -and $State.Runs[-1].State -eq 'Accepted') { throw 'Synthetic outcome save denial.' }
            & $script:stateWriter -State $State
        }
        $result = Invoke-DeviceRemediation -Device $script:device -PackageId $script:packageId
        $result.Persisted | Should -BeFalse
        (Get-DeviceActionState).Runs[0].State | Should -Be Preparing
        (Invoke-DeviceRemediation -Device $script:device -PackageId $script:packageId).State | Should -Be Preparing
        Should -Invoke Invoke-GraphApiRequest -Times 1 -Exactly -ParameterFilter { $Method -eq 'POST' }
    }
    It 'refuses a changed target after confirmation before persisting or submitting' {
        Mock Read-ValidatedInput { $script:managedId = '55555555-5555-5555-5555-555555555555'; return 'Y' }
        { Invoke-DeviceRemediation -Device $script:device -PackageId $script:packageId } | Should -Throw '*changed after confirmation*'
        (Get-DeviceActionState).Runs.Count | Should -Be 0
        Should -Invoke Invoke-GraphApiRequest -Times 0 -Exactly -ParameterFilter { $Method -eq 'POST' }
    }
    It 'does not submit or prompt under WhatIf' {
        (Invoke-DeviceRemediation -Device $script:device -PackageId $script:packageId -WhatIf).State | Should -Be Cancelled
        (Get-DeviceActionState).Runs.Count | Should -Be 0
        Should -Invoke Read-ValidatedInput -Times 0 -Exactly
        Should -Invoke Invoke-GraphApiRequest -Times 0 -Exactly -ParameterFilter { $Method -eq 'POST' }
    }
    It 'does not confirm execution from <Case> evidence' -ForEach @(
        @{ Case = 'pending'; Detection = 'pending'; Future = $false },
        @{ Case = 'future-dated'; Detection = 'success'; Future = $true }
    ) {
        $run = Invoke-DeviceRemediation -Device $script:device -PackageId $script:packageId
        $script:observedDetection = $Detection
        $script:observedTime = [DateTimeOffset]::UtcNow
        if ($Future) { $script:observedTime = $script:observedTime.AddDays(1) }
        Mock Get-DeviceRemediationObservation { return @{ lastStateUpdateDateTime = $script:observedTime.ToString('o'); detectionState = $script:observedDetection; remediationState = 'unknown' } }
        (Get-DeviceRemediationRunStatus -Device $script:device -RunId $run.RunId).State | Should -Be Accepted
        Should -Invoke Invoke-GraphApiRequest -Times 1 -Exactly -ParameterFilter { $Method -eq 'POST' }
    }
}

Describe 'Exact remediation report matching' {
    BeforeEach {
        $script:RuntimeConfig = @{ graph = @{ requiredScopes = @('DeviceManagementScripts.Read.All') } }
        Mock Get-MgContext { return @{ Scopes = @('DeviceManagementScripts.Read.All') } }
        $script:Runtime = @{ IsDemoMode = $false }
        $script:reportTenant = 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa'
        $script:reportPackage = '11111111-1111-1111-1111-111111111111'
        $script:reportTarget = @{ TenantId = $script:reportTenant; ManagedDeviceId = '22222222-2222-2222-2222-222222222222' }
        $script:reportRows = @(@{ id = 'report-1'; managedDevice = @{ id = $script:reportTarget.ManagedDeviceId }; detectionState = 'success' })
        Mock Get-DeviceActionContext { return @{ TenantId = $script:reportTenant } }
        Mock Get-GraphDiscoveryCollection { return , $script:reportRows }
    }
    It 'requests only status metadata and matches the managed-device relationship' {
        $script:reportRows = @(@{ id = 'other'; managedDevice = @{ id = '33333333-3333-3333-3333-333333333333' } }) + $script:reportRows
        (Get-DeviceRemediationObservation -PackageId $script:reportPackage -Target $script:reportTarget).id | Should -BeExactly report-1
        Should -Invoke Get-GraphDiscoveryCollection -Times 1 -Exactly -ParameterFilter {
            $RequiredTextProperty -eq 'id' -and $Uri -like '*/deviceRunStates?*' -and
            $Uri.Contains('$expand=managedDevice($select=id)') -and $Uri -notmatch 'Output|Error|Content'
        }
    }
    It 'returns no execution report for a complete empty collection' {
        $script:reportRows = @()
        Get-DeviceRemediationObservation -PackageId $script:reportPackage -Target $script:reportTarget | Should -BeNullOrEmpty
    }
    It 'refuses limited identity rather than interpreting it as absence' {
        $script:reportRows[0].managedDevice = $null
        { Get-DeviceRemediationObservation -PackageId $script:reportPackage -Target $script:reportTarget } | Should -Throw '*limited device identity*'
    }
    It 'refuses ambiguous device reports' {
        $script:reportRows += @{ id = 'report-2'; managedDevice = @{ id = $script:reportTarget.ManagedDeviceId } }
        { Get-DeviceRemediationObservation -PackageId $script:reportPackage -Target $script:reportTarget } | Should -Throw '*ambiguous*'
    }
    It 'does not publish a report after tenant drift during discovery' {
        Mock Get-GraphDiscoveryCollection { $script:reportTenant = 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb'; return , $script:reportRows }
        { Get-DeviceRemediationObservation -PackageId $script:reportPackage -Target $script:reportTarget } | Should -Throw '*Tenant changed*'
    }
    It 'does not turn a discovery denial into no execution' {
        Mock Get-GraphDiscoveryCollection { throw 'Synthetic report denial.' }
        { Get-DeviceRemediationObservation -PackageId $script:reportPackage -Target $script:reportTarget } | Should -Throw '*report denial*'
    }
}

Describe 'Remediation menus and pending selections' {
    BeforeEach {
        $script:originalLocalAppData = $env:LOCALAPPDATA
        $env:LOCALAPPDATA = Join-Path $TestDrive ([guid]::NewGuid().ToString('N'))
        $script:Runtime = @{ IsDemoMode = $true }
        $script:answers = [Collections.Generic.Queue[string]]::new()
        $script:menuDevice = @{ RecordId = '33333333-3333-3333-3333-333333333333'; Serial = 'MENU-SERIAL'; ConfigItem = 'CI-1'; Steps = @{} }
        $script:menuRecords = @{ Value = @($script:menuDevice) }
        $script:catalog = Get-DeviceRemediationCatalog
        Mock Show-ScriptScreen {}
        Mock Write-Host {}
        Mock Read-ValidatedInput { if (-not $script:answers.Count) { throw ('Unexpected extra prompt: {0}' -f $Prompt) }; return $script:answers.Dequeue() }
        Mock Select-DeviceFromRecords { return $script:menuDevice }
    }
    AfterEach { $env:LOCALAPPDATA = $script:originalLocalAppData }
    It 'retains a settings failure instead of the preceding clipboard success on <Caller>' -ForEach @(
        @{ Caller = 'Build bench'; Supplied = $true }, @{ Caller = 'Device commands'; Supplied = $false }
    ) {
        foreach ($answer in @('3', '4', '0')) { $script:answers.Enqueue($answer) }
        Mock Copy-DeviceIntuneOverviewLink { return @{ State = 'Copied'; Summary = 'Synthetic clipboard success.' } }
        Mock Get-DeviceRemediationCatalog { throw 'Synthetic remediation access guidance.' }
        $parameters = @{ Records = $script:menuRecords; ReturnDestination = $Caller }
        if ($Supplied) { $parameters.Device = $script:menuDevice }
        $result = Show-DeviceActions @parameters
        $result.State | Should -BeExactly Blocked
        $result.Summary | Should -BeLike '*remediation access guidance*'
        $script:answers.Count | Should -Be 0
        Should -Invoke Write-Host -Times 1 -Exactly -ParameterFilter { $Object -like 'Blocked:*remediation access guidance*' }
        $script:menuDevice.Steps.Count | Should -Be 0
    }
    It 'keeps a direct Settings load failure visible until the default-zero acknowledgement' {
        $script:answers.Enqueue('0')
        Mock Get-DeviceRemediationCatalog { throw 'Synthetic remediation access guidance.' }
        Show-RemediationQuickRunSettings | Should -BeNullOrEmpty
        Should -Invoke Read-ValidatedInput -Times 1 -Exactly -ParameterFilter { $Default -eq '0' -and $Choices.Count -eq 1 -and $Choices[0] -eq '0' }
        Should -Invoke Write-Host -Times 1 -Exactly -ParameterFilter { $Object -like 'Cannot load remediation settings:*guidance*' }
        (Get-DeviceActionState).EnabledIds.Count | Should -Be 0
    }
    It 'saves an explicitly enabled immutable package and returns to the caller' {
        foreach ($answer in @('1', '1', '2', 'Y', '0')) { $script:answers.Enqueue($answer) }
        Show-RemediationQuickRunSettings
        (Get-DeviceActionState).EnabledIds | Should -Contain $script:catalog[0].id
        $script:answers.Count | Should -Be 0
        Should -Invoke Read-ValidatedInput -Times 1 -Exactly -ParameterFilter { $Prompt -like 'Save these*' -and $Default -eq 'N' }
    }
    It 'discards pending toggles on a default-No close without creating preferences' {
        foreach ($answer in @('1', '1', '0', 'N')) { $script:answers.Enqueue($answer) }
        Show-RemediationQuickRunSettings
        (Get-DeviceActionState).EnabledIds.Count | Should -Be 0
        (Get-DeviceActionState).Revision | Should -Be 0
    }
    It 'continues editing after Cancel then saves on close' {
        foreach ($answer in @('1', '1', '0', 'C', '0', 'Y')) { $script:answers.Enqueue($answer) }
        Show-RemediationQuickRunSettings
        (Get-DeviceActionState).EnabledIds.Count | Should -Be 1
    }
    It 'does not silently drop the proposal after a save failure' {
        foreach ($answer in @('1', '1', '2', 'Y', '0', 'N')) { $script:answers.Enqueue($answer) }
        Mock Save-DeviceActionState { throw 'Synthetic preferences denial.' }
        Show-RemediationQuickRunSettings
        (Get-DeviceActionState).Revision | Should -Be 0
        $script:answers.Count | Should -Be 0
        Should -Invoke Write-Host -Times 1 -Exactly -ParameterFilter { $Object -like '*pending edits retained*' }
    }
    It 'pages a large catalogue and chooses the stable requested identity' {
        $items = @(1..20 | ForEach-Object { @{ id = 'item-{0}' -f $_; displayName = 'Package {0}' -f $_ } })
        foreach ($answer in @('N', '16')) { $script:answers.Enqueue($answer) }
        (Select-RemediationMenuItem -Items $items -Title 'Test catalogue').id | Should -BeExactly item-16
        Should -Invoke Write-Host -Times 1 -Exactly -ParameterFilter { $Object -like '16. Package 16*' }
    }
    It 'rejects malformed and out-of-range package choices' {
        foreach ($answer in @('1.5', '-1', '999999999999999999999', '999', '0')) { $script:answers.Enqueue($answer) }
        Select-RemediationMenuItem -Items $script:catalog -Title 'Test catalogue' | Should -BeNullOrEmpty
        Should -Invoke Write-Host -Times 4 -Exactly -ParameterFilter { $Object -like 'Choose a listed*' }
    }
    It 'returns from <Caller> using the shared device actions with no workflow mutation' -ForEach @(
        @{ Caller = 'Build bench'; Supplied = $true }, @{ Caller = 'Device commands'; Supplied = $false }
    ) {
        $script:answers.Enqueue('0')
        $parameters = @{ Records = $script:menuRecords; ReturnDestination = $Caller }
        if ($Supplied) { $parameters.Device = $script:menuDevice }
        Show-DeviceActions @parameters | Should -BeNullOrEmpty
        $script:menuDevice.Steps.Count | Should -Be 0
        Should -Invoke Write-Host -Times 1 -Exactly -ParameterFilter { $Object -eq ('0. Return to {0}' -f $Caller) }
    }
    It 'routes device action <Choice> once and returns its result' -ForEach @(
        @{ Choice = '1'; Handler = 'Invoke-DeviceRemediation' },
        @{ Choice = '2'; Handler = 'Get-DeviceRemediationRunStatus' },
        @{ Choice = '3'; Handler = 'Copy-DeviceIntuneOverviewLink' }
    ) {
        $state = Get-DeviceActionState
        $state.EnabledIds = @($script:catalog[0].id)
        $state.Runs = @(@{ RunId = '44444444-4444-4444-4444-444444444444'; PackageId = $script:catalog[0].id; ManagedDeviceId = $script:menuDevice.RecordId; RecordId = $script:menuDevice.RecordId; Serial = $script:menuDevice.Serial; State = 'Accepted'; SubmittedAt = [DateTimeOffset]::UtcNow.ToString('o') })
        Save-DeviceActionState -State $state
        Mock Invoke-DeviceRemediation { return @{ State = 'Accepted'; Summary = 'Synthetic acceptance.' } }
        Mock Get-DeviceRemediationRunStatus { return @{ State = 'Accepted'; Summary = 'Synthetic status.' } }
        Mock Copy-DeviceIntuneOverviewLink { return @{ State = 'Copied'; Summary = 'Synthetic clipboard.' } }
        $script:answers.Enqueue($Choice)
        if ($Choice -ne '3') { $script:answers.Enqueue('1') }
        $script:answers.Enqueue('0')
        $result = Show-DeviceActions -Records $script:menuRecords -Device $script:menuDevice
        $result.Summary | Should -BeLike 'Synthetic*'
        Should -Invoke -CommandName $Handler -Times 1 -Exactly
        $script:menuDevice.Steps.Count | Should -Be 0
    }
}