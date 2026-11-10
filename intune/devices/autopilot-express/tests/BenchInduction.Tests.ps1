<#
.SYNOPSIS
    Checks local bench identity and metadata guards before state or storage changes.
.DESCRIPTION
    Extracts the actual induction and collection helper. Record construction and
    persistence are mocked; no operational files, physical devices or tenant calls occur.
#>
BeforeAll {
    $sourcePath = Join-Path (Split-Path -Parent $PSScriptRoot) 'autopilot-express.ps1'
    $tokens = $null
    $parseErrors = $null
    $sourceAst = [System.Management.Automation.Language.Parser]::ParseFile($sourcePath, [ref]$tokens, [ref]$parseErrors)
    if ($parseErrors.Count) { throw ($parseErrors.Message -join '; ') }
    foreach ($functionName in @('Add-DeviceToBenchPosition', 'Add-DeviceRecord', 'Assert-DeviceRecordIdentity')) {
        $definition = $sourceAst.Find({ param($node) $node -is [System.Management.Automation.Language.FunctionDefinitionAst] -and $node.Name -eq $functionName }, $true)
        if (-not $definition) { throw ('Missing function: {0}' -f $functionName) }
        Set-Item -Path ('Function:{0}' -f $definition.Name) -Value $definition.Body.GetScriptBlock()
    }
    function New-DeviceRecordObject {
        [CmdletBinding(SupportsShouldProcess)]
        [OutputType([hashtable])]
        param($Serial, $ConfigItem, $SiteCode, $DeviceType, $GroupTag)
        if ($PSCmdlet.ShouldProcess($Serial, 'Create synthetic record')) {
            return @{ Serial = $Serial; ConfigItem = $ConfigItem; SiteCode = $SiteCode; DeviceType = $DeviceType; GroupTag = $GroupTag; Status = 'new'; Steps = @{} }
        }
    }
    function Write-UserDeviceRecords { param($Records) throw ('Unexpected save: {0}' -f @($Records).Count) }
    function Save-BuildBenchState { throw 'Unexpected bench save' }
}

Describe 'Off-bench reuse selection' {
    BeforeAll {
        foreach ($name in @('Start-NewDeviceWorkflow', 'Get-OffBenchDeviceRecord', 'Select-EmptyBenchPosition', 'Select-ExistingDeviceWorkflowAction', 'Show-ScriptScreen', 'Show-ReturnToMainMenu', 'Read-ValidatedInput')) {
            $definition = $sourceAst.Find({ param($node) $node -is [Management.Automation.Language.FunctionDefinitionAst] -and $node.Name -eq $name }, $true)
            if (-not $definition) { throw ('Missing reuse function: {0}' -f $name) }
            Set-Item -Path ('Function:{0}' -f $name) -Value $definition.Body.GetScriptBlock()
        }
    }
    BeforeEach {
        $script:BuildBench = @{ Active = $true; Positions = @(@{ Index = 1; Serial = '' }) }
        $script:reuseDevice = @{ Serial = 'DPG4RM4'; ConfigItem = 'CI86063'; SiteCode = 'MU'; DeviceType = 'Desktop'; Status = 'in-progress'; Steps = @{ B = @{ CompletionState = 'Submitted' } }; AttemptHistory = @(@{ AttemptId = 'preserve' }) }
        $script:reuseRecords = @{ Value = @($script:reuseDevice) }
        $script:reuseAnswers = [Collections.Generic.Queue[string]]::new()
        Mock Show-ScriptScreen {}
        Mock Show-ReturnToMainMenu {}
        Mock Write-Host {}
        Mock Get-OffBenchDeviceRecord { return , @($script:reuseDevice) }
        Mock Select-EmptyBenchPosition { 1 }
        Mock Read-ValidatedInput { if (-not $script:reuseAnswers.Count) { throw 'Unexpected reuse prompt' }; $script:reuseAnswers.Dequeue() }
        Mock Select-ExistingDeviceWorkflowAction {
            param($Device, $Position)
            $Device.Serial | Should -BeExactly 'DPG4RM4'
            $Device.Steps.B.CompletionState | Should -BeExactly 'Submitted'
            $Device.AttemptHistory[0].AttemptId | Should -BeExactly 'preserve'
            $Position | Should -Be 1
            $true
        }
        Mock Write-UserDeviceRecords { throw 'Selection must not save or reset the record itself' }
    }
    It 'selects retained progress using <Selection>' -TestCases @(@{ Selection = 'ci86063' }, @{ Selection = 'DPG4RM4' }, @{ Selection = '1' }) {
        param($Selection)
        foreach ($answer in @('E', $Selection)) { $script:reuseAnswers.Enqueue($answer) }
        Start-NewDeviceWorkflow -CurrentSiteCode 'MU' -Records $script:reuseRecords -BenchRequired | Should -BeExactly MU
        Should -Invoke Select-ExistingDeviceWorkflowAction -Times 1 -Exactly
        Should -Invoke Write-UserDeviceRecords -Times 0 -Exactly
    }
    It 'reprompts for an unknown identifier before selecting the retained CI' {
        foreach ($answer in @('E', 'UNKNOWN', 'CI86063')) { $script:reuseAnswers.Enqueue($answer) }
        Start-NewDeviceWorkflow -CurrentSiteCode 'MU' -Records $script:reuseRecords -BenchRequired | Should -BeExactly MU
        Should -Invoke Select-ExistingDeviceWorkflowAction -Times 1 -Exactly
        Should -Invoke Read-ValidatedInput -Times 3 -Exactly
    }
    It 'cancels without resetting, saving or resuming a record' {
        foreach ($answer in @('E', '0')) { $script:reuseAnswers.Enqueue($answer) }
        Start-NewDeviceWorkflow -CurrentSiteCode 'MU' -Records $script:reuseRecords -BenchRequired | Should -BeExactly MU
        Should -Invoke Select-ExistingDeviceWorkflowAction -Times 0 -Exactly
        Should -Invoke Write-UserDeviceRecords -Times 0 -Exactly
    }
}

Describe 'Evidence-preserving existing-device lifecycle' {
    BeforeAll {
        $tokens = $null; $errors = $null
        $ast = [System.Management.Automation.Language.Parser]::ParseFile((Join-Path (Split-Path -Parent $PSScriptRoot) 'autopilot-express.ps1'), [ref]$tokens, [ref]$errors)
        foreach ($name in @('New-EmptyDeviceRecord', 'ConvertTo-NormalisedValue', 'Invoke-ExistingDeviceLifecycle', 'Assert-DeviceRecordIdentity', 'Assert-BenchPositionIdentity')) {
            $definition = $ast.Find({ param($node) $node -is [System.Management.Automation.Language.FunctionDefinitionAst] -and $node.Name -eq $name }, $true)
            Set-Item -Path ('Function:{0}' -f $name) -Value $definition.Body.GetScriptBlock()
        }
        function Read-ValidatedInput { param($Prompt, $Default, $Type, $Choices) throw ('Unexpected input {0} {1} {2} {3}' -f $Prompt, $Default, $Type, ($Choices -join ',')) }
        function Get-LiveTenantBinding { param($Device, [switch]$AllowUnbound) throw ('Unexpected tenant lookup {0} {1}' -f $Device.RecordId, $AllowUnbound) }
        function Get-EnabledManifestSteps { return @(@{ Id = 'A'; ActionName = 'ResolveAutopilotDevice' }) }
    }
    BeforeEach {
        $script:Runtime = @{ IsDemoMode = $true }
        $script:BuildBench = @{ Active = $true; Positions = @(@{ Index = 1; Serial = $null; ConfigItem = $null }) }
        $script:lifecycleDevice = New-EmptyDeviceRecord
        $script:lifecycleDevice.RecordId = 'retained-record'
        $script:lifecycleDevice.Serial = 'CYCLE-01'; $script:lifecycleDevice.ConfigItem = 'CI-CYCLE'
        $script:lifecycleDevice.Status = 'removed'
        $script:lifecycleDevice.StartedAt = [datetime]'2026-10-01'
        $script:lifecycleDevice.Steps = @{ A = @{ CompletionState = 'Failed'; Data = @{} } }
        $script:lifecycleRecords = @{ Value = @($script:lifecycleDevice) }
        Mock Write-Host {}
        Mock Read-ValidatedInput { if ($Prompt -like 'Confirm*') { return 'Y' }; return 'Technician correction' }
        Mock Write-UserDeviceRecords {}
    }
    It 'restores removal with unchanged steps and start time and stages bench placement' {
        Mock Write-UserDeviceRecords {
            $script:lifecycleDevice.Status | Should -Be 'removed'
            @($Records)[0].Status | Should -Be 'in-progress'
            $script:BuildBench.Positions[0].Serial | Should -Be 'CYCLE-01'
        }
        (Invoke-ExistingDeviceLifecycle -Records $script:lifecycleRecords -Device $script:lifecycleDevice -Action Restore -Position 1).Changed | Should -BeTrue
        $script:lifecycleDevice.Steps.A.CompletionState | Should -Be 'Failed'
        ([datetime]$script:lifecycleDevice.StartedAt) | Should -Be ([datetime]'2026-10-01')
        $script:lifecycleDevice.RecoveryHistory[0].PreviousRecord.Status | Should -Be 'removed'
        Should -Invoke Write-UserDeviceRecords -Times 1 -Exactly
    }
    It 'restarts a completed build retaining identity and original completion evidence' {
        $script:lifecycleDevice.Status = 'completed'; $script:lifecycleDevice.DispatchConfirmed = $true
        $script:lifecycleDevice.CompletedBy = 'original-technician'
        (Invoke-ExistingDeviceLifecycle -Records $script:lifecycleRecords -Device $script:lifecycleDevice -Action Restart).Changed | Should -BeTrue
        $script:lifecycleDevice.RecordId | Should -Be 'retained-record'
        $script:lifecycleDevice.BuildCycleId | Should -Match '^[a-f0-9-]{36}$'
        $script:lifecycleDevice.Status | Should -Be 'new'
        $script:lifecycleDevice.Steps.Count | Should -Be 0
        $script:lifecycleDevice.DispatchConfirmed | Should -BeFalse
        $script:lifecycleDevice.RecoveryHistory[0].PreviousRecord.CompletedBy | Should -Be 'original-technician'
        $script:lifecycleDevice.RecoveryHistory[0].PreviousRecord.DispatchConfirmed | Should -BeTrue
    }
    It 'defaults confirmation to No and leaves cancelled evidence unchanged' {
        $before = $script:lifecycleDevice | ConvertTo-Json -Depth 30 -Compress
        Mock Read-ValidatedInput { if ($Prompt -like 'Confirm*') { return $Default }; return 'Correction' }
        (Invoke-ExistingDeviceLifecycle -Records $script:lifecycleRecords -Device $script:lifecycleDevice -Action Restore).Changed | Should -BeFalse
        ($script:lifecycleDevice | ConvertTo-Json -Depth 30 -Compress) | Should -BeExactly $before
        Should -Invoke Read-ValidatedInput -Times 1 -Exactly -ParameterFilter { $Prompt -like 'Confirm*' -and $Default -eq 'N' }
        Should -Invoke Write-UserDeviceRecords -Times 0 -Exactly
    }
    It 'restores memory and bench after a failed checkpoint save' {
        $before = $script:lifecycleDevice | ConvertTo-Json -Depth 30 -Compress
        $benchBefore = $script:BuildBench | ConvertTo-Json -Depth 10 -Compress
        Mock Write-UserDeviceRecords { throw 'Synthetic checkpoint failure' }
        { Invoke-ExistingDeviceLifecycle -Records $script:lifecycleRecords -Device $script:lifecycleDevice -Action Restart -Position 1 } | Should -Throw '*checkpoint*'
        ($script:lifecycleDevice | ConvertTo-Json -Depth 30 -Compress) | Should -BeExactly $before
        ($script:BuildBench | ConvertTo-Json -Depth 10 -Compress) | Should -BeExactly $benchBefore
    }
    It 'refuses restart with unresolved <Flag> remote evidence' -ForEach @(@{ Flag = 'Submitted' }, @{ Flag = 'OutcomeUnknown' }, @{ Flag = 'SyncAccepted' }, @{ Flag = 'DurableGap' }) {
        $script:lifecycleDevice.Steps.A.Data[$Flag] = $true
        (Invoke-ExistingDeviceLifecycle -Records $script:lifecycleRecords -Device $script:lifecycleDevice -Action Restart).Changed | Should -BeFalse
        Should -Invoke Write-UserDeviceRecords -Times 0 -Exactly
        Should -Invoke Read-ValidatedInput -Times 0 -Exactly
    }
    It 'refuses active recovery and explicit Submitted evidence' {
        $script:lifecycleDevice.RecoveryActive = $true
        (Invoke-ExistingDeviceLifecycle -Records $script:lifecycleRecords -Device $script:lifecycleDevice -Action Restart).Changed | Should -BeFalse
        $script:lifecycleDevice.RecoveryActive = $false
        $script:lifecycleDevice.Steps.A.CompletionState = 'Submitted'
        (Invoke-ExistingDeviceLifecycle -Records $script:lifecycleRecords -Device $script:lifecycleDevice -Action Restart).Changed | Should -BeFalse
        Should -Invoke Write-UserDeviceRecords -Times 0 -Exactly
    }
    It 'refuses a restored CI owned by another active serial' {
        $script:lifecycleRecords.Value += @{ Serial = 'OTHER-SERIAL'; ConfigItem = 'CI-CYCLE'; Status = 'in-progress' }
        { Invoke-ExistingDeviceLifecycle -Records $script:lifecycleRecords -Device $script:lifecycleDevice -Action Restore } | Should -Throw
        $script:lifecycleDevice.Status | Should -Be 'removed'
        Should -Invoke Write-UserDeviceRecords -Times 0 -Exactly
    }
    It 'refuses a Live tenant mismatch before input or saving' {
        $script:Runtime.IsDemoMode = $false; $script:lifecycleDevice.TenantId = '11111111-1111-1111-1111-111111111111'
        Mock Get-LiveTenantBinding { throw 'Tenant mismatch' }
        (Invoke-ExistingDeviceLifecycle -Records $script:lifecycleRecords -Device $script:lifecycleDevice -Action Restart).Summary | Should -Match 'Tenant mismatch'
        Should -Invoke Read-ValidatedInput -Times 0 -Exactly
        Should -Invoke Write-UserDeviceRecords -Times 0 -Exactly
    }
    It 'allows explicit failed-discovery-only fresh intent but never adopts cached identities' {
        $script:Runtime.IsDemoMode = $false
        Mock Get-LiveTenantBinding { return '11111111-1111-1111-1111-111111111111' }
        $script:lifecycleDevice.AutopilotDeviceId = 'unowned-cached-id'
        (Invoke-ExistingDeviceLifecycle -Records $script:lifecycleRecords -Device $script:lifecycleDevice -Action Restart).Changed | Should -BeFalse
        $script:lifecycleDevice.AutopilotDeviceId = ''
        (Invoke-ExistingDeviceLifecycle -Records $script:lifecycleRecords -Device $script:lifecycleDevice -Action Restart).Changed | Should -BeTrue
        $script:lifecycleDevice.TenantId | Should -Be '11111111-1111-1111-1111-111111111111'
        $script:lifecycleDevice.RecoveryHistory[0].PreviousRecord.TenantId | Should -Be ''
    }
}

Describe 'Local bench induction safeguards' {
    BeforeEach {
        $script:BuildBench = @{ Positions = @(@{ Index = 1; Serial = ''; ConfigItem = '' }, @{ Index = 2; Serial = ''; ConfigItem = '' }) }
        $script:records = @{ Value = @() }
        $script:record = @{ Serial = 'BENCH-01'; ConfigItem = 'CI-01'; SiteCode = 'MI'; DeviceType = 'Desktop'; Status = 'in-progress'; Steps = @{ A = @{ CompletionState = 'Simulated' } } }
        Mock Write-UserDeviceRecords { Save-BuildBenchState }
        Mock Save-BuildBenchState {}
        Mock Write-Host {}
    }

    It 'creates one new record and saves the intended slot' {
        Add-DeviceToBenchPosition -Position 1 -Serial 'BENCH-01' -ConfigItem 'CI-01' -SiteCode 'MI' -DeviceType 'Desktop' -Records $script:records
        $script:records.Value.Count | Should -Be 1
        $script:records.Value[0].GroupTag | Should -Be 'MI-Desktop'
        $script:BuildBench.Positions[0].Serial | Should -Be 'BENCH-01'
        Should -Invoke Write-UserDeviceRecords -Times 1 -Exactly
        Should -Invoke Save-BuildBenchState -Times 1 -Exactly
    }

    It 'reuses a unique matching record without losing its progress' {
        $script:records.Value = @($script:record)
        Add-DeviceToBenchPosition -Position 1 -Serial 'BENCH-01' -ConfigItem 'CI-01' -SiteCode 'MI' -DeviceType 'Desktop' -Records $script:records
        $script:records.Value.Count | Should -Be 1
        $script:records.Value[0].Steps.A.CompletionState | Should -Be 'Simulated'
        $script:BuildBench.Positions[0].ConfigItem | Should -Be 'CI-01'
    }

    It 'rejects duplicate serial slots without changing state or saving' {
        $script:BuildBench.Positions[0].Serial = 'BENCH-01'
        $script:BuildBench.Positions[0].ConfigItem = 'CI-01'
        $script:records.Value = @($script:record)
        Add-DeviceToBenchPosition -Position 2 -Serial 'bench-01' -ConfigItem 'CI-01' -SiteCode 'MI' -DeviceType 'Desktop' -Records $script:records
        $script:BuildBench.Positions[1].Serial | Should -Be ''
        $script:records.Value.Count | Should -Be 1
        Should -Invoke Write-UserDeviceRecords -Times 0 -Exactly
        Should -Invoke Save-BuildBenchState -Times 0 -Exactly
    }

    It 'does not replace an occupied slot' {
        $script:BuildBench.Positions[0].Serial = 'OTHER-DEVICE'
        Add-DeviceToBenchPosition -Position 1 -Serial 'BENCH-01' -ConfigItem 'CI-01' -SiteCode 'MI' -DeviceType 'Desktop' -Records $script:records
        $script:BuildBench.Positions[0].Serial | Should -Be 'OTHER-DEVICE'
        $script:records.Value.Count | Should -Be 0
        Should -Invoke Save-BuildBenchState -Times 0 -Exactly
    }

    It 'rejects ambiguous workflow records' {
        $script:records.Value = @($script:record, $script:record)
        Add-DeviceToBenchPosition -Position 1 -Serial 'BENCH-01' -ConfigItem 'CI-01' -SiteCode 'MI' -DeviceType 'Desktop' -Records $script:records
        $script:BuildBench.Positions[0].Serial | Should -Be ''
        Should -Invoke Write-UserDeviceRecords -Times 0 -Exactly
    }

    It 'rejects a removed workflow record' {
        $script:record.Status = 'removed'
        $script:records.Value = @($script:record)
        Add-DeviceToBenchPosition -Position 1 -Serial 'BENCH-01' -ConfigItem 'CI-01' -SiteCode 'MI' -DeviceType 'Desktop' -Records $script:records
        $script:BuildBench.Positions[0].Serial | Should -Be ''
        Should -Invoke Save-BuildBenchState -Times 0 -Exactly
    }

    It 'rejects mismatched <Field> rather than relabelling progress' -TestCases @(
        @{ Field = 'ConfigItem'; Value = 'OTHER-CI' }
        @{ Field = 'SiteCode'; Value = 'MU' }
        @{ Field = 'DeviceType'; Value = 'Laptop' }
    ) {
        param($Field, $Value)
        $script:record[$Field] = $Value
        $script:records.Value = @($script:record)
        Add-DeviceToBenchPosition -Position 1 -Serial 'BENCH-01' -ConfigItem 'CI-01' -SiteCode 'MI' -DeviceType 'Desktop' -Records $script:records
        $script:BuildBench.Positions[0].Serial | Should -Be ''
        $script:record[$Field] | Should -Be $Value
        Should -Invoke Write-UserDeviceRecords -Times 0 -Exactly
    }

    It 'rejects another active device using the same Configuration Item' {
        $script:records.Value = @($script:record)
        Add-DeviceToBenchPosition -Position 2 -Serial 'BENCH-02' -ConfigItem 'CI-01' -SiteCode 'MI' -DeviceType 'Laptop' -Records $script:records
        $script:records.Value.Count | Should -Be 1
        $script:BuildBench.Positions[1].Serial | Should -Be ''
        Should -Invoke Save-BuildBenchState -Times 0 -Exactly
    }
}<#
.SYNOPSIS
    Checks local bench identity and metadata guards before state or storage changes.
.DESCRIPTION
    Extracts the actual induction and collection helper. Record construction and
    persistence are mocked; no operational files, physical devices or tenant calls occur.
#>
BeforeAll {
    $sourcePath = Join-Path (Split-Path -Parent $PSScriptRoot) 'autopilot-express.ps1'
    $tokens = $null
    $parseErrors = $null
    $sourceAst = [System.Management.Automation.Language.Parser]::ParseFile($sourcePath, [ref]$tokens, [ref]$parseErrors)
    if ($parseErrors.Count) { throw ($parseErrors.Message -join '; ') }
    foreach ($functionName in @('Add-DeviceToBenchPosition', 'Add-DeviceRecord', 'Assert-DeviceRecordIdentity')) {
        $definition = $sourceAst.Find({ param($node) $node -is [System.Management.Automation.Language.FunctionDefinitionAst] -and $node.Name -eq $functionName }, $true)
        if (-not $definition) { throw ('Missing function: {0}' -f $functionName) }
        Set-Item -Path ('Function:{0}' -f $definition.Name) -Value $definition.Body.GetScriptBlock()
    }
    function New-DeviceRecordObject {
        [CmdletBinding(SupportsShouldProcess)]
        [OutputType([hashtable])]
        param($Serial, $ConfigItem, $SiteCode, $DeviceType, $GroupTag)
        if ($PSCmdlet.ShouldProcess($Serial, 'Create synthetic record')) {
            return @{ Serial = $Serial; ConfigItem = $ConfigItem; SiteCode = $SiteCode; DeviceType = $DeviceType; GroupTag = $GroupTag; Status = 'new'; Steps = @{} }
        }
    }
    function Write-UserDeviceRecords { param($Records) throw ('Unexpected save: {0}' -f @($Records).Count) }
    function Save-BuildBenchState { throw 'Unexpected bench save' }
}

Describe 'Local bench induction safeguards' {
    BeforeEach {
        $script:BuildBench = @{ Positions = @(@{ Index = 1; Serial = ''; ConfigItem = '' }, @{ Index = 2; Serial = ''; ConfigItem = '' }) }
        $script:records = @{ Value = @() }
        $script:record = @{ Serial = 'BENCH-01'; ConfigItem = 'CI-01'; SiteCode = 'MI'; DeviceType = 'Desktop'; Status = 'in-progress'; Steps = @{ A = @{ CompletionState = 'Simulated' } } }
        Mock Write-UserDeviceRecords { Save-BuildBenchState }
        Mock Save-BuildBenchState {}
        Mock Write-Host {}
    }

    It 'creates one new record and saves the intended slot' {
        Add-DeviceToBenchPosition -Position 1 -Serial 'BENCH-01' -ConfigItem 'CI-01' -SiteCode 'MI' -DeviceType 'Desktop' -Records $script:records
        $script:records.Value.Count | Should -Be 1
        $script:records.Value[0].GroupTag | Should -Be 'MI-Desktop'
        $script:BuildBench.Positions[0].Serial | Should -Be 'BENCH-01'
        Should -Invoke Write-UserDeviceRecords -Times 1 -Exactly
        Should -Invoke Save-BuildBenchState -Times 1 -Exactly
    }

    It 'reuses a unique matching record without losing its progress' {
        $script:records.Value = @($script:record)
        Add-DeviceToBenchPosition -Position 1 -Serial 'BENCH-01' -ConfigItem 'CI-01' -SiteCode 'MI' -DeviceType 'Desktop' -Records $script:records
        $script:records.Value.Count | Should -Be 1
        $script:records.Value[0].Steps.A.CompletionState | Should -Be 'Simulated'
        $script:BuildBench.Positions[0].ConfigItem | Should -Be 'CI-01'
    }

    It 'rejects duplicate serial slots without changing state or saving' {
        $script:BuildBench.Positions[0].Serial = 'BENCH-01'
        $script:BuildBench.Positions[0].ConfigItem = 'CI-01'
        $script:records.Value = @($script:record)
        Add-DeviceToBenchPosition -Position 2 -Serial 'bench-01' -ConfigItem 'CI-01' -SiteCode 'MI' -DeviceType 'Desktop' -Records $script:records
        $script:BuildBench.Positions[1].Serial | Should -Be ''
        $script:records.Value.Count | Should -Be 1
        Should -Invoke Write-UserDeviceRecords -Times 0 -Exactly
        Should -Invoke Save-BuildBenchState -Times 0 -Exactly
    }

    It 'does not replace an occupied slot' {
        $script:BuildBench.Positions[0].Serial = 'OTHER-DEVICE'
        Add-DeviceToBenchPosition -Position 1 -Serial 'BENCH-01' -ConfigItem 'CI-01' -SiteCode 'MI' -DeviceType 'Desktop' -Records $script:records
        $script:BuildBench.Positions[0].Serial | Should -Be 'OTHER-DEVICE'
        $script:records.Value.Count | Should -Be 0
        Should -Invoke Save-BuildBenchState -Times 0 -Exactly
    }

    It 'rejects ambiguous workflow records' {
        $script:records.Value = @($script:record, $script:record)
        Add-DeviceToBenchPosition -Position 1 -Serial 'BENCH-01' -ConfigItem 'CI-01' -SiteCode 'MI' -DeviceType 'Desktop' -Records $script:records
        $script:BuildBench.Positions[0].Serial | Should -Be ''
        Should -Invoke Write-UserDeviceRecords -Times 0 -Exactly
    }

    It 'rejects a removed workflow record' {
        $script:record.Status = 'removed'
        $script:records.Value = @($script:record)
        Add-DeviceToBenchPosition -Position 1 -Serial 'BENCH-01' -ConfigItem 'CI-01' -SiteCode 'MI' -DeviceType 'Desktop' -Records $script:records
        $script:BuildBench.Positions[0].Serial | Should -Be ''
        Should -Invoke Save-BuildBenchState -Times 0 -Exactly
    }

    It 'rejects mismatched <Field> rather than relabelling progress' -TestCases @(
        @{ Field = 'ConfigItem'; Value = 'OTHER-CI' }
        @{ Field = 'SiteCode'; Value = 'MU' }
        @{ Field = 'DeviceType'; Value = 'Laptop' }
    ) {
        param($Field, $Value)
        $script:record[$Field] = $Value
        $script:records.Value = @($script:record)
        Add-DeviceToBenchPosition -Position 1 -Serial 'BENCH-01' -ConfigItem 'CI-01' -SiteCode 'MI' -DeviceType 'Desktop' -Records $script:records
        $script:BuildBench.Positions[0].Serial | Should -Be ''
        $script:record[$Field] | Should -Be $Value
        Should -Invoke Write-UserDeviceRecords -Times 0 -Exactly
    }

    It 'rejects another active device using the same Configuration Item' {
        $script:records.Value = @($script:record)
        Add-DeviceToBenchPosition -Position 2 -Serial 'BENCH-02' -ConfigItem 'CI-01' -SiteCode 'MI' -DeviceType 'Laptop' -Records $script:records
        $script:records.Value.Count | Should -Be 1
        $script:BuildBench.Positions[1].Serial | Should -Be ''
        Should -Invoke Save-BuildBenchState -Times 0 -Exactly
    }
}