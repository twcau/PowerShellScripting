<#
.SYNOPSIS
    Test document settings and detached job contracts without document dependencies.
.DESCRIPTION
    Imports only the product's document contract module. Uses synthetic data and
    Pester-owned paths; never reads data/, launches Word, prints or calls Graph.
    AUTOPILOT_DOCUMENT_INTEGRATION=1 additionally exercises installed, approved
    libraries through the fixed worker and byte-identical local template copies.
    Requires Pester 5.7.1 and Windows PowerShell 5.1 or PowerShell 7.
.FILECREATED
    2026-10-23
.FILELASTUPDATED
    2026-11-04
#>
BeforeAll {
    if (-not (Get-Command -Name 'Get-ExecutionPolicy' -ErrorAction SilentlyContinue)) {
        Set-Item -Path 'Function:Get-ExecutionPolicy' -Value { 'RemoteSigned' }
    }
    if (-not (Get-Command -Name 'Get-AuthenticodeSignature' -ErrorAction SilentlyContinue)) {
        Set-Item -Path 'Function:Get-AuthenticodeSignature' -Value ([scriptblock]::Create(
                '[CmdletBinding()] param([string]$LiteralPath) throw ''Get-AuthenticodeSignature stand-in must be mocked.'''
            ))
    }
    function Write-UserDeviceRecords {
        param($Records)
        throw ('Unexpected workflow save of {0} records' -f @($Records).Count)
    }
    $script:previousDocumentRoot = $env:AutopilotExpressRoot
    $candidateRoot = $PSScriptRoot
    while ($candidateRoot -and -not (Test-Path -LiteralPath (Join-Path $candidateRoot 'autopilot-express.ps1') -PathType Leaf)) {
        $candidateRoot = Split-Path -Parent $candidateRoot
    }
    if (-not $candidateRoot) { throw 'Cannot locate the application root for document contract tests.' }
    $env:AutopilotExpressRoot = $candidateRoot
    Import-Module (Join-Path $env:AutopilotExpressRoot 'Modules/Documents/AutopilotExpress.Documents.psd1') -Force -ErrorAction Stop
    $tokens = $null; $parseErrors = $null
    $sourceAst = [System.Management.Automation.Language.Parser]::ParseFile((Join-Path $candidateRoot 'autopilot-express.ps1'), [ref]$tokens, [ref]$parseErrors)
    if ($parseErrors.Count) { throw 'Cannot parse the application record factory.' }
    foreach ($name in @('Write-AutopilotExpressLog', 'Get-AutopilotExpressDefinitionPath', 'New-EmptyDeviceRecord', 'New-DeviceRecordObject', 'Get-ConfiguredSerialPattern', 'ConvertTo-NormalisedSerialInput', 'ConvertTo-NormalisedValue', 'Get-DeviceDocumentAttemptDirectory', 'Read-DeviceDocumentFailure', 'Read-DeviceDocumentHistory', 'Save-DeviceDocumentFailure', 'Test-DeviceDocumentScriptTrust', 'Initialize-DeviceDocumentSession', 'Request-DeviceDocumentReadiness', 'Request-DeviceDocumentReprint', 'Start-DeviceDocumentJob', 'Receive-DeviceDocumentJob', 'Get-DocumentJobFeedbackContext', 'Add-ScreenFeedback', 'Get-ScreenFeedbackLines', 'Get-ConsoleTextWidth', 'Get-DeviceFeedbackContext', 'Show-DeviceDocumentSettings')) {
        $definition = $sourceAst.Find({ param($node) $node -is [System.Management.Automation.Language.FunctionDefinitionAst] -and $node.Name -eq $name }, $true)
        if ($null -eq $definition) { throw ('Missing record contract function: {0}' -f $name) }
        Set-Item -Path ('Function:{0}' -f $name) -Value $definition.Body.GetScriptBlock()
    }
}
AfterAll {
    Remove-Module AutopilotExpress.Documents -Force -ErrorAction SilentlyContinue
    $env:AutopilotExpressRoot = $script:previousDocumentRoot
}
Describe 'Document application session controls' {
    BeforeAll {
        function Write-Utf8File {
            param($Path, $Content)
            throw ('Unexpected document evidence save: {0}; characters={1}' -f $Path, $Content.Length)
        }
        function Read-ValidatedInput {
            <#
            .SYNOPSIS
                Reject unmocked settings input without opening an interactive prompt.
            .PARAMETER Prompt
                Expected foreground question.
            .PARAMETER Default
                Default answer supplied by the settings renderer.
            .PARAMETER Type
                Requested validation mode.
            .PARAMETER Choices
                Allowed settings commands.
            .OUTPUTS
                None. Tests must mock every foreground answer.
            #>
            param([string]$Prompt, [string]$Default, [string]$Type, [string[]]$Choices)
            throw ('Unexpected settings input: {0}; default={1}; type={2}; choices={3}' -f $Prompt, $Default, $Type, ($Choices -join ','))
        }
    }
    BeforeEach {
        $script:Runtime = @{ IsDemoMode = $true }
        $script:RuntimeConfig = @{}
        $script:GraphSession = @{ Connected = $true; Account = 'dispatcher@example.invalid'; DisplayName = 'Dispatch Person' }
        $script:DocumentCommandLineOverrides = @{}
        $script:DocumentSession = $null
        $script:Sites = @(@{ Code = 'SITE'; Name = 'Full Site Name' })
        $script:AutopilotExpressScriptDirectory = $env:AutopilotExpressRoot
    }
    AfterEach { $script:DocumentSession = $null }
    It 'generates selected existing-device documents without redispatch or changing preferences' -TestCases @(
        @{ Selection = 'b'; Certificate = $true; Checklist = $false },
        @{ Selection = 'c'; Certificate = $false; Checklist = $true },
        @{ Selection = 'a'; Certificate = $true; Checklist = $true }
    ) {
        param($Selection, $Certificate, $Checklist)
        $device = @{ Serial = 'EXISTING'; ConfigItem = 'CI-EXISTING'; Status = 'completed'; DispatchConfirmed = $true; BuildCycleId = [guid]::NewGuid().ToString('D'); DispatchedAt = '2026-10-28T12:00:00Z' }
        $records = @{ Value = @($device) }
        $before = $records | ConvertTo-Json -Depth 10 -Compress
        $originalSession = @{ EnforceDocumentGuards = $false }
        $script:DocumentSession = @{ Session = $originalSession; Saved = @{}; Settings = $null; Enabled = $false; Suppressed = $false; PrerequisitesReady = $false; PrerequisiteResult = $null; Jobs = @() }
        $script:reprintAnswers = [Collections.Generic.Queue[string]]::new()
        foreach ($answer in @($Selection, 'g')) { $script:reprintAnswers.Enqueue($answer) }
        Mock Read-ValidatedInput { $script:reprintAnswers.Dequeue() }
        Mock Request-DeviceDocumentReadiness {
            $state = $script:DocumentSession
            $state.Settings = Resolve-AutopilotDocumentSettings -ScriptRoot $env:AutopilotExpressRoot -LocalApplicationData $TestDrive -SessionPreferences $state.Session
            $state.Enabled = $state.Settings.Values.BirthCertificateEnabled -or $state.Settings.Values.ChecklistEnabled
            $state.PrerequisitesReady = $state.Enabled
            $true
        }
        $script:queuedDocumentValues = $null
        Mock Start-DeviceDocumentJob { $script:queuedDocumentValues = $script:DocumentSession.Settings.Values }
        Mock Write-UserDeviceRecords { throw 'Existing cycle must not be rewritten' }
        Request-DeviceDocumentReprint -Device $device -Records $records
        $script:queuedDocumentValues.BirthCertificateEnabled | Should -Be $Certificate
        $script:queuedDocumentValues.ChecklistEnabled | Should -Be $Checklist
        $script:queuedDocumentValues.BirthCertificateMode | Should -BeExactly GenerateOnly
        ($records | ConvertTo-Json -Depth 10 -Compress) | Should -BeExactly $before
        $script:DocumentSession.Session | Should -Be $originalSession
        $script:DocumentSession.Enabled | Should -BeFalse
        Should -Invoke Start-DeviceDocumentJob -Times 1 -Exactly
        Should -Invoke Write-UserDeviceRecords -Times 0 -Exactly
    }
    It 'requires separate default-No printing consent and honours cancellation: <Answer>' -TestCases @(@{ Answer = 'n' }, @{ Answer = 'y' }) {
        param($Answer)
        $device = @{ Status = 'completed'; DispatchConfirmed = $true; BuildCycleId = [guid]::NewGuid().ToString('D') }
        $script:DocumentSession = @{ Session = @{}; Settings = @{ Values = @{} }; Enabled = $false; Suppressed = $false; PrerequisitesReady = $false; PrerequisiteResult = $null }
        $script:reprintAnswers = [Collections.Generic.Queue[string]]::new()
        foreach ($answer in @('B', 'P', $Answer)) { $script:reprintAnswers.Enqueue($answer) }
        Mock Read-ValidatedInput { $script:reprintAnswers.Dequeue() }
        Mock Request-DeviceDocumentReadiness { $script:DocumentSession.Enabled = $true; $script:DocumentSession.PrerequisitesReady = $true; $true }
        Mock Start-DeviceDocumentJob {}
        Request-DeviceDocumentReprint -Device $device -Records @{ Value = @($device) }
        $expected = if ($Answer -ieq 'y') { 1 } else { 0 }
        Should -Invoke Start-DeviceDocumentJob -Times $expected -Exactly
        Should -Invoke Read-ValidatedInput -Times 1 -Exactly -ParameterFilter { $Default -eq 'N' -and ($Choices -join ',') -eq 'Y,N' }
    }
    It 'does not generate for an undispatched device or change its status' {
        $device = @{ Status = 'new'; DispatchConfirmed = $false }
        Mock Read-ValidatedInput { throw 'No prompt expected for ineligible records' }
        Mock Start-DeviceDocumentJob {}
        Request-DeviceDocumentReprint -Device $device -Records @{ Value = @($device) }
        $device.Status | Should -BeExactly new
        Should -Invoke Start-DeviceDocumentJob -Times 0 -Exactly
    }
    It 'does not promote a missing legacy cycle identity when the guarded save fails' {
        $device = @{ RecordId = [guid]::NewGuid().ToString('D'); Serial = 'LEGACY'; Status = 'completed'; DispatchConfirmed = $true; BuildCycleId = ''; RecoveryHistory = @() }
        $records = @{ Value = @($device) }
        $before = $records | ConvertTo-Json -Depth 10 -Compress
        $script:DocumentSession = @{ Mode = 'Demo'; TenantId = 'demo'; Settings = @{ Values = @{} }; Suppressed = $false }
        $script:reprintAnswers = [Collections.Generic.Queue[string]]::new()
        foreach ($answer in @('B', 'G', 'Y')) { $script:reprintAnswers.Enqueue($answer) }
        Mock Read-ValidatedInput { $script:reprintAnswers.Dequeue() }
        Mock Request-DeviceDocumentReadiness { $true }
        Mock Write-UserDeviceRecords { throw 'Synthetic failed guarded save' }
        Mock Write-AutopilotExpressLog {}
        Mock Start-DeviceDocumentJob {}
        Request-DeviceDocumentReprint -Device $device -Records $records
        ($records | ConvertTo-Json -Depth 10 -Compress) | Should -BeExactly $before
        Should -Invoke Write-AutopilotExpressLog -Times 1 -Exactly -ParameterFilter { $Level -eq 'WARN' -and $Message -like '*Synthetic failed guarded save*' }
        Should -Invoke Start-DeviceDocumentJob -Times 0 -Exactly
    }
    It 'renders each document setting on its own line with output enabled: <Enabled>' -TestCases @(@{ Enabled = $false }, @{ Enabled = $true }) {
        param($Enabled)
        $script:DocumentSession = @{
            Enabled = $Enabled; Saved = @{}; Session = @{ BirthCertificateEnabled = $Enabled }
            Settings = @{ Values = @{ LocalRoot = $TestDrive } }; Jobs = @(); Preparation = $null; PrerequisitesReady = $false
        }
        $script:documentMenuLines = [Collections.Generic.List[string]]::new()
        Mock Initialize-DeviceDocumentSession { }
        Mock Request-DeviceDocumentReadiness { $true }
        Mock Receive-DeviceDocumentJob { }
        Mock Write-Host { param($Object) $script:documentMenuLines.Add([string]$Object) }
        Mock Read-ValidatedInput { '0' }
        Show-DeviceDocumentSettings
        $optionLines = @($script:documentMenuLines | Where-Object { $_ -match '^\[[0-9GJ]\] ' })
        $optionLines.Count | Should -Be 12
        (($optionLines -replace '^\[([0-9GJ])\].*$', '$1') -join ',') | Should -BeExactly '1,2,3,4,5,6,7,8,9,G,J,0'
        foreach ($line in $optionLines) {
            [regex]::Matches($line, '(?:^|;\s+)\[[0-9GJ]\]\s').Count | Should -Be 1
        }
        Should -Invoke Read-ValidatedInput -Times 1 -Exactly -ParameterFilter { $Default -eq '0' -and $Type -eq 'Choice' -and ($Choices -join ',') -eq '0,1,2,3,4,5,6,7,8,9,G,J' }
    }
    It 'starts with both outputs disabled without importing or probing the optional module' {
        Mock Import-Module { throw 'Unexpected optional module import' }
        Mock Get-AutopilotDocumentHostCapability { throw 'Unexpected host probe' }
        Initialize-DeviceDocumentSession
        $script:DocumentSession.Enabled | Should -BeFalse
        $script:DocumentSession.Settings | Should -BeNullOrEmpty
        Should -Invoke Import-Module -Times 0 -Exactly
        Should -Invoke Get-AutopilotDocumentHostCapability -Times 0 -Exactly
    }
    It 'does not queue a disabled session even for an invalid device' {
        $script:DocumentSession = @{ Enabled = $false }
        Mock New-AutopilotDocumentJob { throw 'Unexpected detached projection' }
        Start-DeviceDocumentJob -Device @{}
        Should -Invoke New-AutopilotDocumentJob -Times 0 -Exactly
    }
    It 'prepares enabled idle sessions without waiting or creating a device job' {
        $script:DocumentSession = @{ Enabled = $true; PrerequisitesReady = $true; Settings = @{ Values = @{ LocalRoot = $TestDrive } }; Jobs = @(); Preparation = $null }
        Mock New-AutopilotDocumentJob { throw 'Preparation must not project a device' }
        $script:preparationBoundaries = @()
        Mock Write-AutopilotExpressLog { param($Message) $script:preparationBoundaries += $Message }
        Mock Start-AutopilotDocumentJob {
            param($PreparationSettings)
            $PreparationSettings | Should -Not -BeNullOrEmpty
            $script:preparationBoundaries.Count | Should -Be 1
            $script:preparationBoundaries[0] | Should -BeLike '*entering template staging*'
            @{ Status = 'Preparing' }
        }
        Receive-DeviceDocumentJob
        $script:DocumentSession.Preparation.Status | Should -BeExactly Preparing
        $script:preparationBoundaries.Count | Should -Be 2
        $script:preparationBoundaries[1] | Should -BeLike '*supervisor launch returned; status=Preparing*'
        Should -Invoke Start-AutopilotDocumentJob -Times 1 -Exactly
        Should -Invoke New-AutopilotDocumentJob -Times 0 -Exactly
    }
    It 'does not prewarm disabled sessions or overlap an outstanding job' -TestCases @(@{ Enabled = $false }, @{ Enabled = $true }) {
        param($Enabled)
        $script:DocumentSession = @{ Enabled = $Enabled; PrerequisitesReady = $true; Jobs = @(@{ Job = @{ JobId = 'synthetic' }; Handle = @{ Status = 'Running' }; Result = $null }); Preparation = $null }
        Mock Receive-AutopilotDocumentJob { @{ Status = 'Running' } }
        Mock Start-AutopilotDocumentJob { throw 'Must not prepare' }
        Receive-DeviceDocumentJob
        Should -Invoke Start-AutopilotDocumentJob -Times 0 -Exactly
    }
    It 'uses the committing signed-in actor and full site, never the imaging technician' {
        $script:DocumentSession = @{ Enabled = $true; PrerequisitesReady = $true; Settings = @{ Values = @{ LocalRoot = $TestDrive } }; Mode = 'Demo'; TenantId = 'demo'; Jobs = @() }
        Mock New-AutopilotDocumentJob { param($DocumentContext) $DocumentContext.TechnicianDisplayName | Should -BeExactly 'Dispatch Person'; $DocumentContext.SiteName | Should -BeExactly 'Full Site Name'; return @{ JobId = 'synthetic'; JobRoot = 'C:\synthetic-jobs' } }
        Mock Invoke-AutopilotDocumentCleanup { @{ Moved = 0; Removed = 0 } }
        Mock Start-AutopilotDocumentJob { return @{ Status = 'Running' } }
        Start-DeviceDocumentJob -Device @{ SiteCode = 'SITE'; TechnicianUserPrincipalName = 'imaging@example.invalid' }
        $script:DocumentSession.Jobs.Count | Should -Be 1
        Should -Invoke New-AutopilotDocumentJob -Times 1 -Exactly
    }
    It 'retains dispatch when prerequisites or background staging fail' {
        $script:DocumentSession = @{ Enabled = $true; PrerequisitesReady = $false; Jobs = @() }
        Mock Start-AutopilotDocumentJob { throw 'Must not start' }
        { Start-DeviceDocumentJob -Device @{ Status = 'completed'; SiteCode = 'SITE' } } | Should -Not -Throw
        Should -Invoke Start-AutopilotDocumentJob -Times 0 -Exactly
        $script:DocumentSession.Jobs.Count | Should -Be 1
        $script:DocumentSession.Jobs[0].Result.Status | Should -BeExactly FailedBeforeQueue
        $script:DocumentSession.Jobs[0].Failure.DocumentContext.TechnicianDisplayName | Should -BeExactly 'Dispatch Person'
        $script:DocumentSession.Jobs[0].Failure.DocumentContext.SiteName | Should -BeExactly 'Full Site Name'
    }
    It 'retains an attempt when worker staging returns no handle' {
        $script:DocumentSession = @{ Enabled = $true; PrerequisitesReady = $true; Settings = @{ Values = @{ LocalRoot = $TestDrive } }; Mode = 'Demo'; TenantId = 'demo'; Jobs = @() }
        $device = @{ Serial = 'NO-HANDLE'; SiteCode = 'SITE'; Status = 'completed'; DispatchConfirmed = $true }
        $before = $device | ConvertTo-Json -Compress
        Mock New-AutopilotDocumentJob { @{ JobId = [guid]::NewGuid().ToString('D'); JobRoot = $TestDrive } }
        Mock Invoke-AutopilotDocumentCleanup { @{ Moved = 0; Removed = 0 } }
        Mock Start-AutopilotDocumentJob { $null }
        Mock Write-Utf8File {}
        Mock Write-AutopilotExpressLog {}
        Start-DeviceDocumentJob -Device $device
        $script:DocumentSession.Jobs.Count | Should -Be 1
        $script:DocumentSession.Jobs[0].Result.Status | Should -BeExactly FailedBeforeQueue
        $script:DocumentSession.Jobs[0].Failure.Diagnostic | Should -BeLike '*returned no handle*'
        ($device | ConvertTo-Json -Compress) | Should -BeExactly $before
        Should -Invoke Write-Utf8File -Times 1 -Exactly
    }
    It 'persists a bounded prequeue failure snapshot without changing dispatch or capturing unrelated fields' {
        $state = @{ Mode = 'Demo'; TenantId = 'demo'; Settings = @{ Values = @{ LocalRoot = $TestDrive } }; Jobs = @() }
        $device = @{ Serial = 'SERIAL-FAIL'; ConfigItem = 'CI-FAIL'; Status = 'completed'; DispatchConfirmed = $true; SecretMustNotPersist = 'excluded'; Steps = @{} }
        $before = $device | ConvertTo-Json -Depth 10 -Compress
        $script:failureJson = ''; $script:failurePath = ''
        Mock Write-Utf8File { $script:failureJson = $Content; $script:failurePath = $Path }
        Mock Write-AutopilotExpressLog {}
        $entry = Save-DeviceDocumentFailure -State $state -Device $device -DocumentContext @{ TechnicianDisplayName = 'Original Dispatcher' } -Diagnostic ('x' * 3000)
        $saved = $script:failureJson | ConvertFrom-Json
        $saved.Diagnostic.Length | Should -Be 2048
        $saved.Device.Serial | Should -BeExactly SERIAL-FAIL
        $saved.DocumentContext.TechnicianDisplayName | Should -BeExactly 'Original Dispatcher'
        $script:failureJson | Should -Not -Match 'SecretMustNotPersist|excluded'
        $script:failurePath | Should -BeLike '*Demo*Attempts*.json'
        $entry.FailurePath | Should -BeExactly $script:failurePath
        ($device | ConvertTo-Json -Depth 10 -Compress) | Should -BeExactly $before
        Should -Invoke Write-AutopilotExpressLog -Times 1 -Exactly -ParameterFilter { $Level -eq 'WARN' -and $Message -like '*attempt=*' }
    }
    It 'rediscovers a retained prequeue failure after session state is lost without starting a worker' {
        $state = @{ Mode = 'Demo'; TenantId = 'demo'; Settings = @{ Values = @{ LocalRoot = $TestDrive } }; Jobs = @() }
        Mock Write-Utf8File {
            $null = New-Item -ItemType Directory -Path (Split-Path -Parent $Path) -Force
            Set-Content -LiteralPath $Path -Value $Content -Encoding UTF8
        }
        Mock Write-AutopilotExpressLog {}
        Mock Start-AutopilotDocumentJob { throw 'Discovery must never execute a worker' }
        $entry = Save-DeviceDocumentFailure -State $state -Device @{ Serial = 'RETAINED'; Status = 'completed' } -DocumentContext @{ TechnicianDisplayName = 'Original Dispatcher' } -Diagnostic 'Prerequisites unavailable'
        $state.Jobs = @()
        $restored = @(Read-DeviceDocumentFailure -State $state)
        $restored.Count | Should -Be 1
        $restored[0].FailurePath | Should -BeExactly $entry.FailurePath
        $restored[0].Failure.Device.Serial | Should -BeExactly RETAINED
        $restored[0].Failure.DocumentContext.TechnicianDisplayName | Should -BeExactly 'Original Dispatcher'
        Should -Invoke Start-AutopilotDocumentJob -Times 0 -Exactly
    }
    It 'retains but refuses foreign or interrupted document failure evidence' {
        $root = Join-Path $TestDrive ([guid]::NewGuid().ToString('D'))
        $state = @{ Mode = 'Demo'; TenantId = 'demo'; Settings = @{ Values = @{ LocalRoot = $root } }; Jobs = @() }
        Mock Write-Utf8File {
            $null = New-Item -ItemType Directory -Path (Split-Path -Parent $Path) -Force
            Set-Content -LiteralPath $Path -Value $Content -Encoding UTF8
        }
        Mock Write-AutopilotExpressLog {}
        $entry = Save-DeviceDocumentFailure -State $state -Device @{ Serial = 'RETAINED' } -Diagnostic 'Synthetic'
        $entry.Failure.Actor = 'another-actor'
        Set-Content -LiteralPath $entry.FailurePath -Value ($entry.Failure | ConvertTo-Json -Depth 40) -Encoding UTF8
        @(Read-DeviceDocumentFailure -State $state).Count | Should -Be 0
        Test-Path -LiteralPath $entry.FailurePath | Should -BeTrue
        $entry.Failure.Actor = [string]$env:USERNAME
        Set-Content -LiteralPath $entry.FailurePath -Value ($entry.Failure | ConvertTo-Json -Depth 40) -Encoding UTF8
        Set-Content -LiteralPath ($entry.FailurePath + '.pending') -Value 'interrupted'
        @(Read-DeviceDocumentFailure -State $state).Count | Should -Be 0
        Test-Path -LiteralPath ($entry.FailurePath + '.pending') | Should -BeTrue
    }
    It 'retries a rediscovered failure only after consent using the original dispatch context: <Answer>' -TestCases @(@{ Answer = 'Y' }, @{ Answer = 'N' }) {
        param($Answer)
        $script:retryIdentity = [guid]::NewGuid().ToString('D')
        $script:retainedDevice = @{ Serial = 'HISTORICAL'; Status = 'completed'; DispatchConfirmed = $true }
        $script:retainedEntry = @{
            Job = @{ JobId = $script:retryIdentity }
            Handle = @{ Status = 'RetainedFailure'; JobDirectory = $TestDrive }
            Result = @{ Status = 'RetainedFailure'; Results = @() }
            Failure = @{ Device = $script:retainedDevice; DocumentContext = @{ TechnicianDisplayName = 'Original Dispatcher'; SiteName = 'Original Site' }; Diagnostic = 'Synthetic failure' }
        }
        $script:DocumentSession = @{ Enabled = $true; PrerequisitesReady = $true; Suppressed = $false; Settings = @{ Values = @{ LocalRoot = $TestDrive; BirthCertificateEnabled = $true; BirthCertificateMode = 'Review' }; Sources = @{} }; Jobs = @(); Preparation = $null; Mode = 'Demo'; TenantId = 'demo'; Session = @{}; Saved = @{} }
        $before = $script:retainedDevice | ConvertTo-Json -Compress
        $script:retryAnswers = [Collections.Generic.Queue[string]]::new()
        foreach ($value in @('J', $script:retryIdentity, $Answer, '0')) { $script:retryAnswers.Enqueue($value) }
        Mock Request-DeviceDocumentReadiness { $true }
        Mock Resolve-AutopilotDocumentSettings { $script:DocumentSession.Settings }
        Mock Receive-DeviceDocumentJob {}
        Mock Read-DeviceDocumentFailure { $script:retainedEntry }
        Mock Read-ValidatedInput { if (-not $script:retryAnswers.Count) { throw 'Unexpected retry prompt' }; $script:retryAnswers.Dequeue() }
        Mock Write-Host {}
        Mock New-AutopilotDocumentJob {
            param($Device, $DocumentContext)
            $Device.Serial | Should -BeExactly 'HISTORICAL'
            $DocumentContext.TechnicianDisplayName | Should -BeExactly 'Original Dispatcher'
            $DocumentContext.SiteName | Should -BeExactly 'Original Site'
            $identifier = [guid]::NewGuid().ToString('D')
            @{ JobId = $identifier; JobDirectoryName = ('Retried_{0}' -f $identifier) }
        }
        Mock Start-AutopilotDocumentJob {
            param($Job)
            $Job.JobId | Should -BeExactly $script:retryIdentity
            $Job.JobDirectoryName | Should -BeExactly ('Retried_{0}' -f $script:retryIdentity)
            @{ Status = 'Running' }
        }
        Show-DeviceDocumentSettings
        $expected = if ($Answer -eq 'Y') { 1 } else { 0 }
        Should -Invoke New-AutopilotDocumentJob -Times $expected -Exactly
        Should -Invoke Start-AutopilotDocumentJob -Times $expected -Exactly -ParameterFilter { $ExplicitRetry -and $PrintApproved }
        Should -Invoke Read-ValidatedInput -Times 1 -Exactly -ParameterFilter { $Default -eq 'N' -and $Prompt -like 'Retry document generation*' }
        ($script:retainedDevice | ConvertTo-Json -Compress) | Should -BeExactly $before
    }
    Context 'Historical document jobs (DOC-HISTORY)' {
        BeforeEach {
            $script:historyRoot = Join-Path $TestDrive ([guid]::NewGuid().ToString('N'))
            $script:historyState = @{ Mode = 'Demo'; TenantId = 'demo'; Settings = @{ Values = @{ LocalRoot = $script:historyRoot } }; Jobs = @() }
            function Add-SyntheticReceipt {
                param([string]$Folder = 'Serial-H1_CI-C1', [hashtable]$Override = @{}, [string]$FileJobId)
                $jobId = [guid]::NewGuid().ToString('D')
                $receipt = [ordered]@{ SchemaVersion = 1; Owner = 'AutopilotExpress.Documents'; JobId = $jobId; RecordId = 'rec-h'; BuildCycleId = 'cycle-h'; Mode = 'Demo'; TenantId = 'demo'; Serial = 'H1'; ConfigurationItem = 'C1'; DispatchedAt = '2026-01-01T00:00:00Z'; Results = @(@{ DocumentType = 'BirthCertificate'; Status = 'Succeeded' }); AutomaticReplayAllowed = $false; Cleanup = 'Verified'; UpdatedAtUtc = '2026-01-02T00:00:00Z' }
                foreach ($key in $Override.Keys) { $receipt[$key] = $Override[$key] }
                $directory = Join-Path (Join-Path (Join-Path $script:historyRoot 'Demo') 'Output') $Folder
                $null = New-Item -ItemType Directory -Path $directory -Force
                $name = if ($FileJobId) { $FileJobId } else { $jobId }
                $path = Join-Path $directory ('Job-{0}.receipt.json' -f $name)
                Set-Content -LiteralPath $path -Value ($receipt | ConvertTo-Json -Depth 6) -Encoding UTF8
                return @{ JobId = $jobId; Path = $path }
            }
            Mock Write-AutopilotExpressLog {}
        }
        It 'catalogues a valid completed receipt as read-only history' {
            $valid = Add-SyntheticReceipt
            $history = @(Read-DeviceDocumentHistory -State $script:historyState)
            $history.Count | Should -Be 1
            $history[0].Job.JobId | Should -BeExactly $valid.JobId
            $history[0].Job.BuildCycleId | Should -BeExactly 'cycle-h'
            $history[0].Job.Fields.SerialNumberOrServiceTag | Should -BeExactly 'H1'
            $history[0].Handle.Status | Should -BeExactly 'CompletedHistory'
            $history[0].Result.Results[0].Status | Should -BeExactly 'Succeeded'
        }
        It 'skips but retains foreign, mismatched or replayable receipts' {
            $foreign = Add-SyntheticReceipt -Folder 'A' -Override @{ Mode = 'Live'; TenantId = '11111111-1111-1111-1111-111111111111' }
            $renamed = Add-SyntheticReceipt -Folder 'B' -FileJobId ([guid]::NewGuid().ToString('D'))
            $replayable = Add-SyntheticReceipt -Folder 'C' -Override @{ AutomaticReplayAllowed = $true }
            $unowned = Add-SyntheticReceipt -Folder 'D' -Override @{ Owner = 'Someone.Else' }
            @(Read-DeviceDocumentHistory -State $script:historyState).Count | Should -Be 0
            foreach ($item in @($foreign, $renamed, $replayable, $unowned)) { Test-Path -LiteralPath $item.Path | Should -BeTrue }
            Should -Invoke Write-AutopilotExpressLog -Times 4 -Exactly -ParameterFilter { $Level -eq 'WARN' -and $Message -like 'Historical document receipt requires review*' }
        }
        It 'routes a selected historical job to a fresh reprint for the same saved cycle, never a replay: <Cycle>' -TestCases @(@{ Cycle = 'cycle-h'; Expected = 1 }, @{ Cycle = 'cycle-new'; Expected = 0 }) {
            param($Cycle, $Expected)
            $valid = Add-SyntheticReceipt
            $script:historyRecords = @{ Value = @(@{ RecordId = 'rec-h'; BuildCycleId = $Cycle; Serial = 'H1'; ConfigItem = 'C1'; Status = 'completed'; DispatchConfirmed = $true }) }
            $script:DocumentSession = @{ Enabled = $true; PrerequisitesReady = $true; Suppressed = $false; Settings = @{ Values = @{ LocalRoot = $script:historyRoot }; Sources = @{} }; Jobs = @(); Preparation = $null; Mode = 'Demo'; TenantId = 'demo'; Session = @{}; Saved = @{} }
            $script:historyAnswers = [Collections.Generic.Queue[string]]::new()
            foreach ($value in @('J', $valid.JobId, '0')) { $script:historyAnswers.Enqueue($value) }
            Mock Request-DeviceDocumentReadiness { $true }
            Mock Resolve-AutopilotDocumentSettings { $script:DocumentSession.Settings }
            Mock Receive-DeviceDocumentJob {}
            Mock Read-DeviceDocumentFailure {}
            Mock Read-ValidatedInput { if (-not $script:historyAnswers.Count) { throw 'Unexpected history prompt' }; $script:historyAnswers.Dequeue() }
            Mock Write-Host {}
            Mock Request-DeviceDocumentReprint { param($Device) $Device.RecordId | Should -BeExactly 'rec-h' }
            Mock Start-AutopilotDocumentJob { throw 'Historical receipts must never be replayed' }
            Show-DeviceDocumentSettings -Records $script:historyRecords
            Should -Invoke Request-DeviceDocumentReprint -Times $Expected -Exactly
            Should -Invoke Start-AutopilotDocumentJob -Times 0 -Exactly
            Should -Invoke Read-ValidatedInput -Times 0 -Exactly -ParameterFilter { $Prompt -like 'Retry document generation*' }
        }
        It 'lists completed dispatches that have no document job' {
            $script:historyRecords = @{ Value = @(@{ RecordId = 'rec-x'; BuildCycleId = 'cycle-x'; Serial = 'NODOCS'; ConfigItem = 'C9'; Status = 'completed'; DispatchConfirmed = $true; DispatchedAt = '2026-02-01' }) }
            $script:DocumentSession = @{ Enabled = $true; PrerequisitesReady = $true; Suppressed = $false; Settings = @{ Values = @{ LocalRoot = $script:historyRoot }; Sources = @{} }; Jobs = @(); Preparation = $null; Mode = 'Demo'; TenantId = 'demo'; Session = @{}; Saved = @{} }
            $script:historyAnswers = [Collections.Generic.Queue[string]]::new()
            foreach ($value in @('J', '0')) { $script:historyAnswers.Enqueue($value) }
            $script:historyLines = [Collections.Generic.List[string]]::new()
            Mock Request-DeviceDocumentReadiness { $true }
            Mock Resolve-AutopilotDocumentSettings { $script:DocumentSession.Settings }
            Mock Receive-DeviceDocumentJob {}
            Mock Read-DeviceDocumentFailure {}
            Mock Read-ValidatedInput { if (-not $script:historyAnswers.Count) { throw 'Unexpected history prompt' }; $script:historyAnswers.Dequeue() }
            Mock Write-Host { param($Object) $script:historyLines.Add([string]$Object) }
            Show-DeviceDocumentSettings -Records $script:historyRecords
            ($script:historyLines -join "`n") | Should -BeLike '*Completed dispatches with no document job found (1)*Serial=NODOCS; CI=C9*'
        }
    }
    It 'continues collecting an existing job after future output has been disabled' {
        $script:DocumentSession = @{ Enabled = $false; Jobs = @(@{ Job = @{ JobId = 'synthetic' }; Handle = @{ Status = 'Running' }; Result = $null }) }
        Mock Receive-AutopilotDocumentJob { @{ Status = 'Completed'; Results = @() } }
        Receive-DeviceDocumentJob
        $script:DocumentSession.Jobs[0].Result.Status | Should -BeExactly Completed
        Should -Invoke Receive-AutopilotDocumentJob -Times 1 -Exactly
    }
    Context 'Bench document feedback (BENCH-DOC-FEEDBACK)' {
        BeforeEach {
            $script:BuildBench = @{ Positions = @(@{ Index = 3; Serial = 'SER123' }) }
            $script:InventoryRecords = @{ Value = @(@{ RecordId = 'rec-1'; Serial = 'SER123'; ConfigItem = 'CI-9' }) }
            $script:benchHostLines = [Collections.Generic.List[string]]::new()
            Mock Write-Host { param($Object) $script:benchHostLines.Add([string]$Object) }
        }
        AfterEach { Remove-Variable -Name BuildBench, InventoryRecords -Scope Script -ErrorAction SilentlyContinue }
        It 'retains one complete event per finished job with device and cycle context and no host output' {
            $script:DocumentSession = @{ Enabled = $false; Jobs = @(@{ Job = [ordered]@{ JobId = 'job-1'; RecordId = 'rec-1'; BuildCycleId = 'cycle-1'; Fields = @{ SerialNumberOrServiceTag = 'SER123' } }; Handle = @{ Status = 'Running' }; Result = $null }) }
            Mock Receive-AutopilotDocumentJob { @{ Status = 'Completed'; Results = @(@{ DocumentType = 'BirthCertificate'; Status = 'Succeeded'; PdfPath = 'C:\out\bc.pdf'; Message = 'ok' }, @{ DocumentType = 'Checklist'; Status = 'Failed'; PdfPath = ''; Message = 'template' }) } }
            $feedback = @{ Lines = @(); Events = @(); Compact = $true; Context = 'Bench | command=REFRESH' }
            Receive-DeviceDocumentJob -FeedbackState $feedback
            @($feedback.Events).Count | Should -Be 1
            $feedback.Events[0].Context | Should -BeExactly 'Position 3 | Serial=SER123 | CI=CI-9 | Cycle=cycle-1'
            ($feedback.Events[0].Text -split "`n")[0] | Should -BeExactly 'Documents Completed: BirthCertificate Succeeded; Checklist Failed'
            $feedback.Events[0].Text | Should -BeLike '*Document job job-1: Completed*'
            $feedback.Events[0].Text | Should -BeLike '*document-only retry*'
            $feedback.Context | Should -BeExactly 'Bench | command=REFRESH'
            $script:benchHostLines.Count | Should -Be 0
        }
        It 'does not re-report a collected job on later redraws' {
            $script:DocumentSession = @{ Enabled = $false; Jobs = @(@{ Job = [ordered]@{ JobId = 'job-1'; RecordId = 'rec-1'; BuildCycleId = 'cycle-1' }; Handle = @{ Status = 'Running' }; Result = $null }) }
            Mock Receive-AutopilotDocumentJob { @{ Status = 'Completed'; Results = @() } }
            $feedback = @{ Lines = @(); Events = @(); Compact = $true; Context = '' }
            Receive-DeviceDocumentJob -FeedbackState $feedback
            Receive-DeviceDocumentJob -FeedbackState $feedback
            @($feedback.Events).Count | Should -Be 1
            Should -Invoke Receive-AutopilotDocumentJob -Times 1 -Exactly
        }
        It 'falls back to the job serial when the record is not loaded' {
            $script:InventoryRecords = $null
            Get-DocumentJobFeedbackContext -Job ([ordered]@{ JobId = 'j'; RecordId = 'missing'; BuildCycleId = 'c-2'; Fields = @{ SerialNumberOrServiceTag = 'ABC' } }) | Should -BeExactly 'Serial=ABC | Cycle=c-2'
        }
        It 'keeps host output unchanged when no feedback state is supplied' {
            $script:DocumentSession = @{ Enabled = $false; Jobs = @(@{ Job = [ordered]@{ JobId = 'job-2' }; Handle = @{ Status = 'Running' }; Result = $null }) }
            Mock Receive-AutopilotDocumentJob { @{ Status = 'Completed'; Results = @() } }
            Receive-DeviceDocumentJob
            $script:benchHostLines[0] | Should -BeExactly 'Document job job-2: Completed. No physical printing or manual Save As is inferred.'
        }
    }
    Context 'Foreground document readiness' {
        BeforeEach {
            $script:DocumentSession = @{
                Enabled = $true; Settings = @{ Values = @{ LocalRoot = $TestDrive } }
                Saved = @{ BirthCertificateEnabled = $true }; Session = @{}; Jobs = @()
                Preparation = $null; PrerequisitesReady = $false; Suppressed = $false
                ExitRequested = $false; PrerequisiteResult = $null
                PreferencePath = Join-Path $TestDrive 'preferences.json'; Mode = 'Demo'; TenantId = 'demo'
            }
            $script:readinessMessages = [Collections.Generic.List[string]]::new()
            Mock Initialize-DeviceDocumentSession { }
            Mock Test-DeviceDocumentScriptTrust { @{ Ready = $true; Files = @() } }
            Mock Test-AutopilotDocumentPrerequisite { @{ Ready = $true; Status = 'Passed'; Diagnostic = '' } }
            Mock Read-ValidatedInput { 'C' }
            Mock Unblock-File { throw 'Unexpected trust change' }
            Mock Receive-DeviceDocumentJob { }
            Mock Write-Host { param($Object) $script:readinessMessages.Add([string]$Object) }
        }
        It 'allows testing output by default without claiming physical delivery' {
            Request-DeviceDocumentReadiness | Should -BeTrue
            $script:DocumentSession.PrerequisitesReady | Should -BeTrue
            ($script:readinessMessages -join ' ') | Should -Match 'guards are OFF.*output is final'
            ($script:readinessMessages -join ' ') | Should -Match 'physical printing are not proven'
            Should -Invoke Read-ValidatedInput -Times 0 -Exactly
            Should -Invoke Unblock-File -Times 0 -Exactly
        }
        It 'can restore approval enforcement for both enabled document types' {
            $script:DocumentSession.Saved.ChecklistEnabled = $true
            $script:DocumentSession.Session.EnforceDocumentGuards = $true
            Request-DeviceDocumentReadiness | Should -BeTrue
            @($script:readinessMessages | Where-Object { $_ -match 'guards are ON.*DRAFT.*will not print' }).Count | Should -Be 2
        }
        It 'continues without documents after <Failure> without changing saved preferences' -TestCases @(
            @{ Failure = 'WordUnavailable' }, @{ Failure = 'WorkerUnavailable' }, @{ Failure = 'TimedOut' },
            @{ Failure = 'ScriptAuthorizationFailed' }, @{ Failure = 'Declined' }, @{ Failure = 'InvalidExistingBundle' }
        ) {
            param($Failure)
            Mock Test-AutopilotDocumentPrerequisite { @{ Ready = $false; Status = $Failure; Diagnostic = 'Synthetic prerequisite evidence' } }
            Request-DeviceDocumentReadiness | Should -BeTrue
            $script:DocumentSession.Enabled | Should -BeFalse
            $script:DocumentSession.Suppressed | Should -BeTrue
            $script:DocumentSession.Saved.BirthCertificateEnabled | Should -BeTrue
            $script:DocumentSession.PrerequisiteResult.Status | Should -BeExactly $Failure
            Test-Path -LiteralPath $script:DocumentSession.PreferencePath | Should -BeFalse
            Should -Invoke Read-ValidatedInput -Times 1 -Exactly -ParameterFilter { $Default -eq 'C' -and ($Choices -join ',') -eq 'R,C,X' }
            Mock Read-ValidatedInput { param($Prompt) if ($Prompt -like 'Choose *R, C, X') { 'C' } else { '0' } }
            Show-DeviceDocumentSettings
            $script:DocumentSession.Enabled | Should -BeFalse
            Should -Invoke Unblock-File -Times 0 -Exactly
        }
        It 'records the prerequisite failure in the timestamped diagnostic stream' {
            Mock Test-AutopilotDocumentPrerequisite { @{ Ready = $false; Status = 'ScriptAuthorizationFailed'; Diagnostic = 'WorkerExecution exit 1: AuthorizationManager check failed' } }
            $diagnostics = @(Request-DeviceDocumentReadiness 6>&1)
            @($diagnostics | Where-Object { $_ -is [Management.Automation.InformationRecord] -and [string]$_.MessageData -match '\[WARN\] Document prerequisites: ScriptAuthorizationFailed.*AuthorizationManager' }).Count | Should -Be 1
            $script:DocumentSession.Suppressed | Should -BeTrue
        }
        It 'returns an explicit exit request instead of throwing into an optional-feature catch' {
            Mock Test-AutopilotDocumentPrerequisite { @{ Ready = $false; Status = 'Failed'; Diagnostic = 'Synthetic' } }
            Mock Read-ValidatedInput { 'x' }
            Request-DeviceDocumentReadiness | Should -BeFalse
            $script:DocumentSession.ExitRequested | Should -BeTrue
            $script:DocumentSession.Enabled | Should -BeFalse
        }
        It 'retries in the foreground and restores output only after success' {
            $script:readinessAttempts = 0
            Mock Test-AutopilotDocumentPrerequisite {
                $script:readinessAttempts++
                @{ Ready = ($script:readinessAttempts -gt 1); Status = 'Synthetic'; Diagnostic = '' }
            }
            Mock Read-ValidatedInput { 'r' }
            Request-DeviceDocumentReadiness | Should -BeTrue
            $script:DocumentSession.Enabled | Should -BeTrue
            $script:DocumentSession.PrerequisitesReady | Should -BeTrue
            Should -Invoke Test-AutopilotDocumentPrerequisite -Times 2 -Exactly
        }
        It 'does not probe the host or offer trust changes when effective output is disabled' {
            $script:DocumentSession.Saved.BirthCertificateEnabled = $false
            Request-DeviceDocumentReadiness | Should -BeTrue
            Should -Invoke Test-AutopilotDocumentPrerequisite -Times 0 -Exactly
            Should -Invoke Test-DeviceDocumentScriptTrust -Times 0 -Exactly
            Should -Invoke Read-ValidatedInput -Times 0 -Exactly
        }
        It 'keeps trust denial inert and defaults the separate confirmation to No' {
            Mock Test-DeviceDocumentScriptTrust { @{ Ready = $false; Files = @(@{ Path = 'C:\reviewed\worker.ps1'; SHA256 = ('A' * 64) }) } }
            $script:readinessAnswers = [Collections.Generic.Queue[string]]::new()
            foreach ($answer in @('u', 'n', 'c')) { $script:readinessAnswers.Enqueue($answer) }
            Mock Read-ValidatedInput { $script:readinessAnswers.Dequeue() }
            Request-DeviceDocumentReadiness | Should -BeTrue
            Should -Invoke Unblock-File -Times 0 -Exactly
            Should -Invoke Test-AutopilotDocumentPrerequisite -Times 0 -Exactly
            Should -Invoke Read-ValidatedInput -Times 1 -Exactly -ParameterFilter { $Default -eq 'N' -and ($Choices -join ',') -eq 'Y,N' }
        }
        It 'unblocks only explicitly reviewed unchanged files then reruns the prerequisites' {
            $script:trustChecks = 0
            Mock Test-DeviceDocumentScriptTrust {
                $script:trustChecks++
                @{ Ready = ($script:trustChecks -gt 2); Files = @(@{ Path = 'C:\reviewed\worker.ps1'; SHA256 = ('A' * 64) }) }
            }
            $script:readinessAnswers = [Collections.Generic.Queue[string]]::new()
            foreach ($answer in @('u', 'y')) { $script:readinessAnswers.Enqueue($answer) }
            Mock Read-ValidatedInput { $script:readinessAnswers.Dequeue() }
            Mock Unblock-File { }
            Request-DeviceDocumentReadiness | Should -BeTrue
            Should -Invoke Unblock-File -Times 1 -Exactly -ParameterFilter { $LiteralPath -ceq 'C:\reviewed\worker.ps1' }
            Should -Invoke Test-AutopilotDocumentPrerequisite -Times 1 -Exactly
            $script:DocumentSession.PrerequisitesReady | Should -BeTrue
        }
        It 'refuses a trust remedy when a reviewed fingerprint changes' {
            $script:trustChecks = 0
            Mock Test-DeviceDocumentScriptTrust {
                $script:trustChecks++
                $hash = if ($script:trustChecks -eq 1) { 'A' * 64 } else { 'B' * 64 }
                @{ Ready = $false; Files = @(@{ Path = 'C:\reviewed\worker.ps1'; SHA256 = $hash }) }
            }
            $script:readinessAnswers = [Collections.Generic.Queue[string]]::new()
            foreach ($answer in @('u', 'y', 'c')) { $script:readinessAnswers.Enqueue($answer) }
            Mock Read-ValidatedInput { $script:readinessAnswers.Dequeue() }
            Request-DeviceDocumentReadiness | Should -BeTrue
            Should -Invoke Unblock-File -Times 0 -Exactly
            ($script:readinessMessages -join ' ') | Should -Match 'file changed after review'
        }
        It 'rechecks after toggle, policy, timeout, retention, explicit check and pin release: <Command>' -TestCases @(
            @{ Command = '1'; Extra = $null }, @{ Command = '2'; Extra = $null },
            @{ Command = '3'; Extra = 'Review' }, @{ Command = '4'; Extra = 'AutoPrint' },
            @{ Command = '5'; Extra = '120' }, @{ Command = '6'; Extra = '8' },
            @{ Command = '7'; Extra = $null }, @{ Command = '9'; Extra = $null }
        ) {
            param($Command, $Extra)
            $script:readinessAnswers = [Collections.Generic.Queue[string]]::new()
            $script:readinessAnswers.Enqueue($Command)
            if ($Extra) { $script:readinessAnswers.Enqueue($Extra) }
            $script:readinessAnswers.Enqueue('0')
            Mock Read-ValidatedInput { $script:readinessAnswers.Dequeue() }
            Mock Request-DeviceDocumentReadiness { $true }
            Show-DeviceDocumentSettings
            Should -Invoke Request-DeviceDocumentReadiness -Times 2 -Exactly
            Should -Invoke Request-DeviceDocumentReadiness -Times 1 -Exactly -ParameterFilter { $LoadModule }
        }
        It 'rechecks immediately after a confirmed save, preserving saved enablement on failure' {
            $script:readinessAnswers = [Collections.Generic.Queue[string]]::new()
            foreach ($answer in @('8', 'y', 'c', '0')) { $script:readinessAnswers.Enqueue($answer) }
            Mock Read-ValidatedInput { $script:readinessAnswers.Dequeue() }
            Mock Test-AutopilotDocumentPrerequisite {
                if (Test-Path -LiteralPath $script:DocumentSession.PreferencePath) { @{ Ready = $false; Status = 'ScriptAuthorizationFailed'; Diagnostic = 'Saved but unavailable' } }
                else { @{ Ready = $true; Status = 'Passed'; Diagnostic = '' } }
            }
            function Write-Utf8File {
                <#
                .SYNOPSIS
                    Write only Pester-owned preference fixtures without operational I/O.
                .PARAMETER Path
                    Pester-owned destination.
                .PARAMETER Content
                    Synthetic preference JSON.
                .OUTPUTS
                    None.
                #>
                param([string]$Path, [string]$Content)
                [IO.File]::WriteAllText($Path, $Content)
            }
            Show-DeviceDocumentSettings
            $stored = Get-Content -LiteralPath $script:DocumentSession.PreferencePath -Raw | ConvertFrom-Json
            $stored.Values.BirthCertificateEnabled | Should -BeTrue
            $script:DocumentSession.Saved.BirthCertificateEnabled | Should -BeTrue
            $script:DocumentSession.Enabled | Should -BeFalse
            $script:DocumentSession.PrerequisiteResult.Status | Should -BeExactly ScriptAuthorizationFailed
            Should -Invoke Test-AutopilotDocumentPrerequisite -Times 2 -Exactly
        }
    }
}
Describe 'Document local script trust boundaries' {
    BeforeEach {
        $script:AutopilotExpressScriptDirectory = Join-Path $TestDrive ([guid]::NewGuid().ToString('N'))
        $script:trustFixtureRoot = Join-Path $script:AutopilotExpressScriptDirectory 'Modules/Documents'
        $null = New-Item -ItemType Directory -Path $trustFixtureRoot -Force
        $script:trustFixturePath = Join-Path $trustFixtureRoot 'worker.ps1'
        [IO.File]::WriteAllText($trustFixturePath, 'throw "Fixture must never execute"')
        Mock Unblock-File { throw 'Trust inspection must never change files' }
        Mock Get-ExecutionPolicy { 'RemoteSigned' }
    }
    It 'reports only marked local document scripts without executing or unblocking them' {
        Set-Content -LiteralPath $trustFixturePath -Stream Zone.Identifier -Value "[ZoneTransfer]`r`nZoneId=3`r`n" -Encoding ASCII
        $outside = Join-Path $script:AutopilotExpressScriptDirectory 'unrelated.ps1'
        [IO.File]::WriteAllText($outside, 'throw "Outside fixture"')
        Set-Content -LiteralPath $outside -Stream Zone.Identifier -Value "[ZoneTransfer]`r`nZoneId=3`r`n" -Encoding ASCII
        $result = Test-DeviceDocumentScriptTrust
        $result.Ready | Should -BeFalse
        @($result.Files).Count | Should -Be 1
        $result.Files[0].Path | Should -BeExactly $trustFixturePath
        $result.Files[0].SHA256 | Should -BeExactly (Get-FileHash -LiteralPath $trustFixturePath -Algorithm SHA256).Hash
        Should -Invoke Unblock-File -Times 0 -Exactly
    }
    It 'accepts unmarked scripts without changing them' {
        $result = Test-DeviceDocumentScriptTrust
        $result.Ready | Should -BeTrue
        @($result.Files).Count | Should -Be 0
        Should -Invoke Unblock-File -Times 0 -Exactly
    }
    It 'reports Restricted policy without prompting for individual files or changing policy' {
        Mock Get-ExecutionPolicy { 'Restricted' }
        { Test-DeviceDocumentScriptTrust } | Should -Throw '*execution policy is Restricted*'
        Should -Invoke Unblock-File -Times 0 -Exactly
    }
    It 'reports unsigned AllSigned deployments instead of prompting for each script' {
        Mock Get-ExecutionPolicy { 'AllSigned' }
        Mock Get-AuthenticodeSignature { @{ Status = 'NotSigned'; SignerCertificate = $null } }
        { Test-DeviceDocumentScriptTrust } | Should -Throw '*Unblocking is not a remedy*'
        Should -Invoke Unblock-File -Times 0 -Exactly
    }
    It 'checks readiness before session-record initialisation and honours Settings exit through cleanup' {
        $tokens = $null; $errors = $null
        $ast = [Management.Automation.Language.Parser]::ParseFile((Join-Path $env:AutopilotExpressRoot 'autopilot-express.ps1'), [ref]$tokens, [ref]$errors)
        $errors.Count | Should -Be 0
        $startupCheck = @($ast.FindAll({
                    param($node)
                    if ($node -isnot [Management.Automation.Language.CommandAst] -or $node.GetCommandName() -ne 'Request-DeviceDocumentReadiness') { return $false }
                    $ancestor = $node.Parent
                    while ($null -ne $ancestor) {
                        if ($ancestor -is [Management.Automation.Language.FunctionDefinitionAst]) { return $false }
                        $ancestor = $ancestor.Parent
                    }
                    return $true
                }, $true))
        $recordStart = @($ast.FindAll({ param($node) $node -is [Management.Automation.Language.CommandAst] -and $node.GetCommandName() -eq 'Initialize-SessionState' }, $true))
        $startupCheck.Count | Should -Be 1
        $startupCheck[0].Extent.StartOffset | Should -BeLessThan $recordStart[0].Extent.StartOffset
        $ast.Extent.Text.Contains('if ($option -eq ''Exit'' -or ($Script:DocumentSession -and $Script:DocumentSession[''ExitRequested''])) { break }') | Should -BeTrue
    }
}
Describe 'Document worker export and delivery ordering' {
    BeforeAll {
        $tokens = $null; $errors = $null
        $workerAst = [Management.Automation.Language.Parser]::ParseFile((Join-Path $env:AutopilotExpressRoot 'Modules/Documents/Workers/Invoke-DocumentJob.ps1'), [ref]$tokens, [ref]$errors)
        if ($errors.Count) { throw 'Cannot parse the document job worker.' }
        $body = $workerAst.Find({ param($node) $node -is [Management.Automation.Language.ScriptBlockAst] -and $null -ne $node.ParamBlock -and @($node.ParamBlock.Parameters).Count -eq 1 -and $node.ParamBlock.Parameters[0].Name.VariablePath.UserPath -eq 'Decoded' }, $true)
        $script:documentJobBody = $body.GetScriptBlock()
    }
    It 'preserves scalar paths decorated by PowerShell instead of turning them into dictionaries' {
        InModuleScope AutopilotExpress.Documents -Parameters @{ Root = $TestDrive } {
            param($Root)
            $path = Join-Path $Root 'decorated-scalar'
            $copy = ConvertTo-AutopilotDocumentDictionary -Value @{ Path = $path; Enabled = $false; Timeout = 60 }
            $copy.Path | Should -BeOfType ([string])
            $copy.Path | Should -BeExactly $path
            $copy.Enabled | Should -BeFalse
            $copy.Timeout | Should -Be 60
        }
    }
    It 'threads testing guard <Guarded> into both documents without changing profile approval' -TestCases @(@{ Guarded = $false }, @{ Guarded = $true }) {
        param($Guarded)
        InModuleScope AutopilotExpress.Documents -Parameters @{ Root = $TestDrive; Body = $script:documentJobBody; Guarded = $Guarded } {
            param($Root, $Body, $Guarded)
            $script:guardExpected = $Guarded
            $script:guardProfile = @{ ApprovedForLive = $false }
            $script:PreparedWordAdapter = @{ Close = {} }
            $directory = Join-Path $Root ([guid]::NewGuid().ToString('D'))
            $null = New-Item -ItemType Directory -Path $directory
            $request = @{ SchemaVersion = 1; Job = @{ SchemaVersion = 1; JobId = [guid]::NewGuid().ToString('D'); Profiles = @(@{ DocumentType = 'BirthCertificate' }, @{ DocumentType = 'Checklist' }) }; JobDirectory = $directory; DependencyRoot = $Root; ReviewOnly = $false; PrintApproved = $true; ExplicitRetry = $false; EnforceDocumentGuards = $Guarded }
            Mock Test-AutopilotDocumentJobDirectory { $true }
            Mock Test-AutopilotDocumentDependencyBundle { @{ Valid = $true; BundlePath = $Root } }
            Mock Add-Type {}
            Mock Get-AutopilotDocumentDependencyManifest { @{ Packages = @() } }
            Mock Get-AutopilotDocumentTemplateProfile { $script:guardProfile }
            Mock Get-AutopilotDocumentOutputName { param($DocumentType) '{0}.docx' -f $DocumentType }
            Mock New-AutopilotDocumentCopy {
                param($Request)
                $Request.EnforceDocumentGuards | Should -Be $script:guardExpected
                $Request.ReviewOnly | Should -Be $script:guardExpected
                $Request.Profile.ApprovedForLive | Should -BeFalse
                [IO.File]::WriteAllText($Request.OutputPath, 'Synthetic document')
                @{ Timings = @{}; TemplateSHA256 = ('A' * 64); TemplateChanged = $false; ValidationWarnings = @() }
            }
            Mock Invoke-AutopilotDocumentWordExport { @{ Status = 'Exported'; Cleanup = 'Complete'; Timings = @{} } }
            Mock Invoke-AutopilotDocumentDelivery {
                param($DocumentType, $ReviewOnly, $AllowDemoPrint)
                $ReviewOnly | Should -Be $script:guardExpected
                [bool]$AllowDemoPrint | Should -Be (-not $script:guardExpected)
                @{ DocumentType = $DocumentType; Status = 'Generated' }
            }
            Mock Write-AutopilotDocumentReceipt {}
            try {
                $results = @(& $Body $request)
                @($results | Where-Object Status -EQ Generated).Count | Should -Be 2
                $script:guardProfile.ApprovedForLive | Should -BeFalse
                Should -Invoke New-AutopilotDocumentCopy -Times 2 -Exactly
                Should -Invoke Invoke-AutopilotDocumentDelivery -Times 2 -Exactly
            }
            finally { Remove-Variable -Name PreparedWordAdapter -Scope Script -ErrorAction SilentlyContinue }
        }
    }
    It 'exports before delivery and isolates failures: export <FailExport>, delivery <FailDelivery>, metadata <FailMetadata>' -TestCases @(
        @{ FailExport = $false; FailDelivery = $false; FailMetadata = $false },
        @{ FailExport = $true; FailDelivery = $false; FailMetadata = $false },
        @{ FailExport = $false; FailDelivery = $true; FailMetadata = $false },
        @{ FailExport = $false; FailDelivery = $false; FailMetadata = $true }
    ) {
        param($FailExport, $FailDelivery, $FailMetadata)
        InModuleScope AutopilotExpress.Documents -Parameters @{ Root = $TestDrive; Body = $script:documentJobBody; FailExport = $FailExport; FailDelivery = $FailDelivery; FailMetadata = $FailMetadata } {
            param($Root, $Body, $FailExport, $FailDelivery, $FailMetadata)
            $script:documentOrder = [Collections.Generic.List[string]]::new()
            $script:failDocumentExport = $FailExport; $script:failDocumentDelivery = $FailDelivery
            $script:failDocumentMetadata = $FailMetadata
            $script:PreparedWordAdapter = @{ Close = { $script:documentOrder.Add('close') } }
            $job = @{ SchemaVersion = 1; JobId = [guid]::NewGuid().ToString('D'); Profiles = @(@{ DocumentType = 'BirthCertificate' }, @{ DocumentType = 'Checklist' }) }
            $request = @{ SchemaVersion = 1; Job = $job; JobDirectory = $Root; DependencyRoot = $Root; ReviewOnly = $true; PrintApproved = $false; ExplicitRetry = $false }
            Mock Test-AutopilotDocumentJobDirectory { $true }
            Mock Test-AutopilotDocumentDependencyBundle { @{ Valid = $true; BundlePath = $Root } }
            Mock Add-Type { }
            Mock Get-AutopilotDocumentDependencyManifest { @{ Packages = @() } }
            Mock Get-AutopilotDocumentTemplateProfile { @{ ApprovedForLive = $false } }
            Mock Get-AutopilotDocumentOutputName { param($DocumentType) '{0}-{1}-{2}-{3}.docx' -f $DocumentType, $script:failDocumentExport, $script:failDocumentDelivery, $script:failDocumentMetadata }
            Mock New-AutopilotDocumentCopy {
                param($Request)
                [IO.File]::WriteAllText($Request.OutputPath, 'Synthetic worker ordering fixture')
                @{ Timings = @{}; TemplateSHA256 = ('A' * 64); TemplateChanged = $false; ValidationWarnings = @() }
            }
            Mock Invoke-AutopilotDocumentWordExport {
                param($Request)
                $type = [IO.Path]::GetFileName($Request.SourcePath).Split('-')[0]
                $script:documentOrder.Add('export:{0}' -f $type)
                if ($script:failDocumentExport -and $type -eq 'BirthCertificate') { throw 'Synthetic export failure' }
                @{ Status = 'Exported'; Cleanup = 'Complete'; Timings = @{} }
            }
            Mock Invoke-AutopilotDocumentDelivery {
                param($DocumentType)
                $script:documentOrder.Add('deliver:{0}' -f $DocumentType)
                if ($script:failDocumentDelivery -and $DocumentType -eq 'BirthCertificate') { throw 'Synthetic delivery failure' }
                @{ DocumentType = $DocumentType; Status = 'Generated' }
            }
            Mock Write-AutopilotDocumentReceipt {
                param($Receipt)
                $script:documentOrder.Add('metadata:{0}' -f $Receipt.DocumentType)
                if ($script:failDocumentMetadata) { throw 'Synthetic supplementary metadata failure' }
            }
            try {
                $result = @(& $Body $request)
                $result.Count | Should -Be 2
                @($result | Where-Object { $_.DocumentType -eq 'Checklist' -and $_.Status -eq 'Generated' }).Count | Should -Be 1
                $script:documentOrder[0] | Should -BeExactly 'export:BirthCertificate'
                $script:documentOrder[1] | Should -BeExactly 'export:Checklist'
                $script:documentOrder[$script:documentOrder.Count - 1] | Should -BeExactly 'close'
                if (-not $FailExport -and -not $FailDelivery) {
                    ($script:documentOrder -join ',') | Should -BeExactly 'export:BirthCertificate,export:Checklist,deliver:BirthCertificate,deliver:Checklist,metadata:BirthCertificate,metadata:Checklist,close'
                    if ($FailMetadata) {
                        @($result | Where-Object { $_.Message -like 'Delivery outcome is saved;*' }).Count | Should -Be 2
                    }
                }
                else { @($result | Where-Object { $_.DocumentType -eq 'BirthCertificate' -and $_.Status -eq 'Failed' }).Count | Should -Be 1 }
            }
            finally { Remove-Variable -Name PreparedWordAdapter -Scope Script -ErrorAction SilentlyContinue }
        }
    }
}
Describe 'Document durable lifecycle state' {
    It 'binds readable serial/CI labels to the exact immutable GUID and rejects lookalikes' {
        InModuleScope AutopilotExpress.Documents -Parameters @{ Root = $TestDrive } {
            param($Root)
            $identifier = [guid]::NewGuid()
            $leaf = 'Serial-PREVIEW-ABC123_CI-CI-PREVIEW-001_{0}' -f $identifier.ToString('D')
            Test-AutopilotDocumentJobDirectory -Directory (Join-Path $Root $leaf) -JobId $identifier | Should -BeTrue
            Test-AutopilotDocumentJobDirectory -Directory (Join-Path $Root $leaf) -JobId ([guid]::NewGuid()) | Should -BeFalse
            Test-AutopilotDocumentJobDirectory -Directory (Join-Path $Root ('Review_{0}' -f $identifier)) -JobId $identifier | Should -BeFalse
        }
    }
    It 'retains uncertain jobs as active and preserves the previous revision' {
        InModuleScope AutopilotExpress.Documents -Parameters @{ Root = $TestDrive } {
            param($Root)
            $identifier = [guid]::NewGuid(); $directory = Join-Path $Root $identifier.ToString('D')
            $null = [IO.Directory]::CreateDirectory($directory)
            Write-AutopilotDocumentLifecycle -Directory $directory -JobId $identifier -Active $true
            Write-AutopilotDocumentLifecycle -Directory $directory -JobId $identifier -Active $true -Result @{ Status = 'Failed'; Cleanup = 'Uncertain'; Results = @() }
            $metadata = Get-Content -LiteralPath (Join-Path $directory 'job-lifecycle.json') -Raw | ConvertFrom-Json
            $metadata.Active | Should -BeTrue
            $metadata.Result.Cleanup | Should -BeExactly Uncertain
            @(Get-ChildItem -LiteralPath $directory -Filter '*.previous-*').Count | Should -Be 1
        }
    }
    It 'protects open-review PDFs and terminal outcomes from automatic expiry' {
        InModuleScope AutopilotExpress.Documents -Parameters @{ Root = $TestDrive } {
            param($Root)
            $identifier = [guid]::NewGuid(); $directory = Join-Path $Root $identifier.ToString('D')
            $null = [IO.Directory]::CreateDirectory($directory)
            Write-AutopilotDocumentLifecycle -Directory $directory -JobId $identifier -Active $false -Result @{ Status = 'Completed'; Results = @(@{ Status = 'OpenRequested' }) }
            $metadata = Get-Content -LiteralPath (Join-Path $directory 'job-lifecycle.json') -Raw | ConvertFrom-Json
            $metadata.State | Should -BeExactly Succeeded
            $metadata.ChecklistOpenRequested | Should -BeTrue
            $metadata.DisposableAssets.Count | Should -Be 0
        }
    }
}
Describe 'Document pipeline inert staging' {
    It 'does not stop or inspect a prepared process during WhatIf cancellation' {
        $handle = @{ Status = 'Preparing'; Process = @{} }
        Start-AutopilotDocumentJob -PreparedWorker $handle -DependencyRoot 'unused' -StopPreparation -WhatIf
        $handle.Status | Should -BeExactly Preparing
    }
    It 'returns before any host or dependency work when both documents are inactive' {
        Mock Get-AutopilotDocumentHostCapability -ModuleName AutopilotExpress.Documents { throw 'Unexpected host probe' }
        Mock Test-AutopilotDocumentDependencyBundle -ModuleName AutopilotExpress.Documents { throw 'Unexpected dependency probe' }
        Start-AutopilotDocumentJob -Job $null -DependencyRoot 'unused' | Should -BeNullOrEmpty
        Start-AutopilotDocumentJob -Job @{ Profiles = @() } -DependencyRoot 'unused' | Should -BeNullOrEmpty
        Should -Invoke Get-AutopilotDocumentHostCapability -ModuleName AutopilotExpress.Documents -Times 0 -Exactly
        Should -Invoke Test-AutopilotDocumentDependencyBundle -ModuleName AutopilotExpress.Documents -Times 0 -Exactly
    }
    It 'rejects an invalid detached job before starting a worker' {
        Mock Get-AutopilotDocumentHostCapability -ModuleName AutopilotExpress.Documents { throw 'Unexpected host probe' }
        { Start-AutopilotDocumentJob -Job @{ SchemaVersion = 1; JobId = '../unsafe'; Profiles = @(@{ DocumentType = 'Checklist' }) } -DependencyRoot 'unused' } | Should -Throw '*identity*'
        Should -Invoke Get-AutopilotDocumentHostCapability -ModuleName AutopilotExpress.Documents -Times 0 -Exactly
    }
    It 'keeps WhatIf staging free of directory, template and process writes' {
        Mock Get-AutopilotDocumentHostCapability -ModuleName AutopilotExpress.Documents { @{ WorkerAvailable = $true; WordRegistrationDetected = $true } }
        Mock Test-AutopilotDocumentDependencyBundle -ModuleName AutopilotExpress.Documents { @{ Valid = $true } }
        $root = Join-Path $TestDrive 'not-created'
        $job = @{ SchemaVersion = 1; JobId = [guid]::NewGuid().ToString(); Profiles = @(@{ DocumentType = 'Checklist' }); JobRoot = $root }
        (Start-AutopilotDocumentJob -Job $job -DependencyRoot 'unused' -WhatIf).Status | Should -BeExactly WhatIf
        Test-Path -LiteralPath $root | Should -BeFalse
    }
    It 'returns an already collected handle without executing or replaying it' {
        $handle = @{ Status = 'Collected'; JobId = [guid]::NewGuid().ToString() }
        Receive-AutopilotDocumentJob -Handle $handle | Should -Be $handle
    }
}
Describe 'Document delivery policies without viewers or printers' {
    BeforeEach {
        $script:deliveryRoot = Join-Path $TestDrive ([guid]::NewGuid().ToString('N'))
        $null = [IO.Directory]::CreateDirectory($script:deliveryRoot)
        $script:deliveryPdf = Join-Path $script:deliveryRoot 'staged.pdf'
        [IO.File]::WriteAllText($script:deliveryPdf, "%PDF-1.7`nsynthetic transport fixture only`n%%EOF`n", [Text.Encoding]::ASCII)
        $script:deliveryJob = @{
            SchemaVersion = 1; JobId = [guid]::NewGuid().ToString(); RecordId = [guid]::NewGuid().ToString(); BuildCycleId = [guid]::NewGuid().ToString()
            Mode = 'Live'; TenantId = 'synthetic'; CreatedAtUtc = [DateTimeOffset]::UtcNow.ToString('o')
            Fields = @{ SerialNumberOrServiceTag = 'ABC123'; DispatchDate = '241026' }; Settings = @{ FileNamePattern = '{SerialNumberOrServiceTag}_{DispatchDate}' }
            OutputRoot = Join-Path $script:deliveryRoot 'output'; Profiles = @(@{ DocumentType = 'BirthCertificate'; DeliveryMode = 'AutoPrint' })
        }
    }
    It 'honours testing print policy for <DocumentType> in <Mode> with enforcement <Guarded>' -TestCases @(
        @{ DocumentType = 'BirthCertificate'; Mode = 'Live'; Guarded = $false },
        @{ DocumentType = 'Checklist'; Mode = 'Live'; Guarded = $false },
        @{ DocumentType = 'BirthCertificate'; Mode = 'Demo'; Guarded = $false },
        @{ DocumentType = 'Checklist'; Mode = 'Demo'; Guarded = $false },
        @{ DocumentType = 'BirthCertificate'; Mode = 'Live'; Guarded = $true },
        @{ DocumentType = 'Checklist'; Mode = 'Live'; Guarded = $true },
        @{ DocumentType = 'BirthCertificate'; Mode = 'Demo'; Guarded = $true },
        @{ DocumentType = 'Checklist'; Mode = 'Demo'; Guarded = $true }
    ) {
        param($DocumentType, $Mode, $Guarded)
        InModuleScope AutopilotExpress.Documents -Parameters @{ Root = $script:deliveryRoot; Job = $script:deliveryJob; Pdf = $script:deliveryPdf; DocumentType = $DocumentType; Mode = $Mode; Guarded = $Guarded } {
            param($Root, $Job, $Pdf, $DocumentType, $Mode, $Guarded)
            $Job.Mode = $Mode
            $Job.Profiles = @(@{ DocumentType = $DocumentType; DeliveryMode = 'AutoPrint' })
            $script:testingPrints = 0
            $adapter = @{ Probe = { @{ CanPrint = $true; DefaultPrinter = 'Synthetic printer' } }; Print = { $script:testingPrints++ } }
            $result = Invoke-AutopilotDocumentDeliveryCore -Job $Job -DocumentType $DocumentType -PdfPath $Pdf -ReceiptDirectory $Root -Adapter $adapter -ReviewOnly:$Guarded -AllowDemoPrint:(-not $Guarded)
            $expected = if ($Guarded) { 0 } else { 1 }
            $script:testingPrints | Should -Be $expected
            $result.Status | Should -BeExactly $(if ($Guarded) { 'Generated' } else { 'PrintRequested' })
            $result.ManualSaveState | Should -BeExactly NotConfirmed
        }
    }
    It 'persists print intent before calling an adapter and never automatically replays a receipt' {
        InModuleScope AutopilotExpress.Documents -Parameters @{ Root = $script:deliveryRoot; Job = $script:deliveryJob; Pdf = $script:deliveryPdf } {
            param($Root, $Job, $Pdf)
            $script:fakePrintCount = 0
            $adapter = @{
                Probe = { @{ CanPrint = $true; CanOpen = $true; DefaultPrinter = 'Fake printer' } }
                Print = { param($Path) $script:fakePrintCount++; $stored = Get-Content -LiteralPath (Join-Path $Root ('{0}-BirthCertificate.receipt.json' -f $Job.JobId)) -Raw | ConvertFrom-Json; $stored.PrintState | Should -BeExactly Requested; $stored.PdfPath | Should -BeExactly $Path }
                Open  = { throw 'Wrong delivery policy' }
            }
            $arguments = @{ Job = $Job; DocumentType = 'BirthCertificate'; PdfPath = $Pdf; ReceiptDirectory = $Root; Adapter = $adapter; ReviewOnly = $false }
            $first = Invoke-AutopilotDocumentDeliveryCore @arguments
            $first.Status | Should -BeExactly PrintRequested
            $second = Invoke-AutopilotDocumentDeliveryCore @arguments
            $second.Status | Should -BeExactly PrintRequested
            $script:fakePrintCount | Should -Be 1
            $first.ManualSaveState | Should -BeExactly NotConfirmed
        }
    }
    It 'retains uncertainty without automatic print replay after a failed adapter' {
        InModuleScope AutopilotExpress.Documents -Parameters @{ Root = $script:deliveryRoot; Job = $script:deliveryJob; Pdf = $script:deliveryPdf } {
            param($Root, $Job, $Pdf)
            $script:fakePrintCount = 0
            $adapter = @{ Probe = { @{ CanPrint = $true; DefaultPrinter = 'Fake' } }; Print = { $script:fakePrintCount++; throw 'Synthetic uncertainty' } }
            $arguments = @{ Job = $Job; DocumentType = 'BirthCertificate'; PdfPath = $Pdf; ReceiptDirectory = $Root; Adapter = $adapter; ReviewOnly = $false }
            (Invoke-AutopilotDocumentDeliveryCore @arguments).PrintState | Should -BeExactly Uncertain
            (Invoke-AutopilotDocumentDeliveryCore @arguments).PrintState | Should -BeExactly Uncertain
            $script:fakePrintCount | Should -Be 1
        }
    }
    It 'does not print draft output and leaves checklist manual saving unconfirmed' {
        InModuleScope AutopilotExpress.Documents -Parameters @{ Root = $script:deliveryRoot; Job = $script:deliveryJob; Pdf = $script:deliveryPdf } {
            param($Root, $Job, $Pdf)
            $adapter = @{ Probe = { throw 'Draft AutoPrint must not probe a printer' }; Print = { throw 'Draft must not print' } }
            $result = Invoke-AutopilotDocumentDeliveryCore -Job $Job -DocumentType BirthCertificate -PdfPath $Pdf -ReceiptDirectory $Root -Adapter $adapter
            $result.Status | Should -BeExactly Generated
            $result.PrintState | Should -BeExactly NotRequested
            $Job.Profiles = @(@{ DocumentType = 'Checklist'; DeliveryMode = 'Review' })
            $adapter = @{ Probe = { param($Path, $IncludePrinter) Test-Path -LiteralPath $Path | Should -BeTrue; $IncludePrinter | Should -BeFalse; @{ CanOpen = $true } }; Open = { param($Path) Test-Path -LiteralPath $Path | Should -BeTrue }; Print = { throw 'Checklist must not print' } }
            $result = Invoke-AutopilotDocumentDeliveryCore -Job $Job -DocumentType Checklist -PdfPath $Pdf -ReceiptDirectory $Root -Adapter $adapter
            $result.Status | Should -BeExactly OpenRequested
            $result.ManualSaveState | Should -BeExactly NotConfirmed
            Split-Path -Leaf $result.PdfPath | Should -BeExactly 'ABC123_241026_Checklist.pdf'
        }
    }
    It 'retains the PDF when a handler or default printer is unavailable' {
        InModuleScope AutopilotExpress.Documents -Parameters @{ Root = $script:deliveryRoot; Job = $script:deliveryJob; Pdf = $script:deliveryPdf } {
            param($Root, $Job, $Pdf)
            $adapter = @{ Probe = { @{ CanPrint = $false } }; Print = { throw 'Unavailable printer must not be called' } }
            $result = Invoke-AutopilotDocumentDeliveryCore -Job $Job -DocumentType BirthCertificate -PdfPath $Pdf -ReceiptDirectory $Root -Adapter $adapter -ReviewOnly:$false
            $result.Status | Should -BeExactly DeliveryUnavailable
            $result.AttemptCount | Should -Be 0
            Test-Path -LiteralPath $result.PdfPath | Should -BeTrue
        }
    }
    It 'requires explicit retry before requesting another print and reuses the receipt-bound PDF' {
        InModuleScope AutopilotExpress.Documents -Parameters @{ Root = $script:deliveryRoot; Job = $script:deliveryJob; Pdf = $script:deliveryPdf } {
            param($Root, $Job, $Pdf)
            $script:fakePrintCount = 0
            $adapter = @{ Probe = { @{ CanPrint = $true; DefaultPrinter = 'Fake' } }; Print = { $script:fakePrintCount++ } }
            $arguments = @{ Job = $Job; DocumentType = 'BirthCertificate'; PdfPath = $Pdf; ReceiptDirectory = $Root; Adapter = $adapter; ReviewOnly = $false }
            $first = Invoke-AutopilotDocumentDeliveryCore @arguments
            $second = Invoke-AutopilotDocumentDeliveryCore @arguments -ExplicitRetry
            $script:fakePrintCount | Should -Be 2
            $second.PdfPath | Should -BeExactly $first.PdfPath
            $second.AttemptCount | Should -Be 2
        }
    }
    It 'performs no delivery when durable intent cannot be written' {
        InModuleScope AutopilotExpress.Documents -Parameters @{ Root = $script:deliveryRoot; Job = $script:deliveryJob; Pdf = $script:deliveryPdf } {
            param($Root, $Job, $Pdf)
            Mock Write-AutopilotDocumentReceipt { throw 'Synthetic receipt storage failure' }
            $adapter = @{ Probe = { throw 'Must not probe' }; Print = { throw 'Must not print' } }
            $arguments = @{ Job = $Job; DocumentType = 'BirthCertificate'; PdfPath = $Pdf; ReceiptDirectory = $Root; Adapter = $adapter; ReviewOnly = $false }
            { Invoke-AutopilotDocumentDeliveryCore @arguments } | Should -Throw '*storage failure*'
            Test-Path -LiteralPath $Job.OutputRoot | Should -BeFalse
        }
    }
    It 'waits for foreground GenerateAndAsk approval without prompting or printing' {
        InModuleScope AutopilotExpress.Documents -Parameters @{ Root = $script:deliveryRoot; Job = $script:deliveryJob; Pdf = $script:deliveryPdf } {
            param($Root, $Job, $Pdf)
            $Job.Profiles[0].DeliveryMode = 'GenerateAndAsk'
            $adapter = @{ Probe = { throw 'No foreground approval' }; Print = { throw 'No foreground approval' } }
            $result = Invoke-AutopilotDocumentDeliveryCore -Job $Job -DocumentType BirthCertificate -PdfPath $Pdf -ReceiptDirectory $Root -Adapter $adapter -ReviewOnly:$false
            $result.Status | Should -BeExactly AwaitingPrintApproval
            $result.AttemptCount | Should -Be 0
        }
    }
    It 'does not overwrite either approved final filename' {
        InModuleScope AutopilotExpress.Documents -Parameters @{ Job = $script:deliveryJob; Pdf = $script:deliveryPdf } {
            param($Job, $Pdf)
            $first = Publish-AutopilotDocumentPdf -Job $Job -DocumentType BirthCertificate -SourcePath $Pdf
            $second = Publish-AutopilotDocumentPdf -Job $Job -DocumentType BirthCertificate -SourcePath $Pdf
            { Publish-AutopilotDocumentPdf -Job $Job -DocumentType BirthCertificate -SourcePath $Pdf } | Should -Throw '*both approved names*'
            (Get-FileHash -LiteralPath $first.Path).Hash | Should -BeExactly $first.SHA256
            (Get-FileHash -LiteralPath $second.Path).Hash | Should -BeExactly $second.SHA256
        }
    }
}
Describe 'Reversible document asset expiry' {
    BeforeEach {
        $script:expiryRoot = Join-Path $TestDrive ([guid]::NewGuid().ToString('N'))
        $script:expiryJobId = [guid]::NewGuid().ToString('D')
        $script:expiryJobDirectory = Join-Path $script:expiryRoot $script:expiryJobId
        $null = [IO.Directory]::CreateDirectory($script:expiryJobDirectory)
        $script:expiryAsset = 'barcode-1234.png'
        [IO.File]::WriteAllText((Join-Path $script:expiryJobDirectory $script:expiryAsset), 'synthetic disposable asset')
        [IO.File]::WriteAllText((Join-Path $script:expiryJobDirectory 'keep.pdf'), 'never remove a generated PDF')
        $script:expiryMetadata = @{ SchemaVersion = 1; Owner = 'AutopilotExpress.Documents'; JobId = $script:expiryJobId; Active = $false; ChecklistOpenRequested = $false; State = 'Failed'; UpdatedAtUtc = '2026-10-01T00:00:00Z'; DisposableAssets = @($script:expiryAsset) }
    }
    It 'archives only declared expired assets and retains generated documents' {
        $expiryMetadata | ConvertTo-Json | Set-Content -LiteralPath (Join-Path $expiryJobDirectory 'job-lifecycle.json') -Encoding UTF8
        $result = Invoke-AutopilotDocumentCleanup -JobRoot $expiryRoot -NowUtc ([DateTimeOffset]'2026-10-24T00:00:00Z')
        $result.Moved | Should -Be 1
        Test-Path -LiteralPath (Join-Path $expiryJobDirectory ('ExpiredAssets/{0}' -f $expiryAsset)) | Should -BeTrue
        Test-Path -LiteralPath (Join-Path $expiryJobDirectory 'keep.pdf') | Should -BeTrue
    }
    It 'skips active jobs and open checklists' {
        foreach ($flag in @('Active', 'ChecklistOpenRequested')) {
            $expiryMetadata[$flag] = $true
            $expiryMetadata | ConvertTo-Json | Set-Content -LiteralPath (Join-Path $expiryJobDirectory 'job-lifecycle.json') -Encoding UTF8
            (Invoke-AutopilotDocumentCleanup -JobRoot $expiryRoot).Moved | Should -Be 0
            $expiryMetadata[$flag] = $false
        }
        Test-Path -LiteralPath (Join-Path $expiryJobDirectory $expiryAsset) | Should -BeTrue
    }
    It 'disables expiry at zero and writes no lease or archive under WhatIf' {
        $expiryMetadata | ConvertTo-Json | Set-Content -LiteralPath (Join-Path $expiryJobDirectory 'job-lifecycle.json') -Encoding UTF8
        (Invoke-AutopilotDocumentCleanup -JobRoot $expiryRoot -FailedJobRetentionDays 0).Moved | Should -Be 0
        (Invoke-AutopilotDocumentCleanup -JobRoot $expiryRoot -WhatIf).Moved | Should -Be 0
        Test-Path -LiteralPath (Join-Path $expiryJobDirectory 'job.lock') | Should -BeFalse
    }
    It 'does not expire a recent failed job or accept a document as a disposable asset' {
        $expiryMetadata.UpdatedAtUtc = [DateTimeOffset]::UtcNow.ToString('o')
        $expiryMetadata | ConvertTo-Json | Set-Content -LiteralPath (Join-Path $expiryJobDirectory 'job-lifecycle.json') -Encoding UTF8
        (Invoke-AutopilotDocumentCleanup -JobRoot $expiryRoot).Moved | Should -Be 0
        $expiryMetadata.UpdatedAtUtc = '2026-10-01T00:00:00Z'; $expiryMetadata.DisposableAssets = @('keep.pdf')
        $expiryMetadata | ConvertTo-Json | Set-Content -LiteralPath (Join-Path $expiryJobDirectory 'job-lifecycle.json') -Encoding UTF8
        (Invoke-AutopilotDocumentCleanup -JobRoot $expiryRoot).Moved | Should -Be 0
        Test-Path -LiteralPath (Join-Path $expiryJobDirectory 'keep.pdf') | Should -BeTrue
    }
}
Describe 'Document receipt persistence' {
    It 'persists intent atomically and retains the previous revision without changing identities' {
        InModuleScope AutopilotExpress.Documents -Parameters @{ Root = $TestDrive } {
            param($Root)
            $path = Join-Path $Root 'receipt.json'
            $receipt = [ordered]@{ SchemaVersion = 1; JobId = [guid]::NewGuid().ToString(); RecordId = [guid]::NewGuid().ToString(); BuildCycleId = [guid]::NewGuid().ToString(); Mode = 'Demo'; TenantId = 'synthetic'; DocumentType = 'Checklist'; DeliveryState = 'Requested' }
            Write-AutopilotDocumentReceipt -Path $path -Receipt $receipt
            $receipt.DeliveryState = 'OpenRequested'
            Write-AutopilotDocumentReceipt -Path $path -Receipt $receipt
            (Get-Content -LiteralPath $path -Raw | ConvertFrom-Json).DeliveryState | Should -BeExactly OpenRequested
            $previous = @(Get-ChildItem -LiteralPath $Root -Filter 'receipt.json.previous-*')
            $previous.Count | Should -Be 1
            (Get-Content -LiteralPath $previous[0].FullName -Raw | ConvertFrom-Json).DeliveryState | Should -BeExactly Requested
            $receipt.JobId = [guid]::NewGuid().ToString()
            { Write-AutopilotDocumentReceipt -Path $path -Receipt $receipt } | Should -Throw '*identity*'
        }
    }
    It 'writes no receipt under WhatIf' {
        InModuleScope AutopilotExpress.Documents -Parameters @{ Root = $TestDrive } {
            param($Root)
            $path = Join-Path $Root 'whatif-receipt.json'
            $receipt = @{ SchemaVersion = 1; JobId = [guid]::NewGuid().ToString(); RecordId = [guid]::NewGuid().ToString(); BuildCycleId = [guid]::NewGuid().ToString(); Mode = 'Demo'; DocumentType = 'Checklist' }
            Write-AutopilotDocumentReceipt -Path $path -Receipt $receipt -WhatIf
            Test-Path -LiteralPath $path | Should -BeFalse
        }
    }
}
Describe 'PDF supervision without Word' {
    BeforeEach {
        $script:pdfWorkerTestRoot = Join-Path $TestDrive ([guid]::NewGuid().ToString('N'))
        $null = [IO.Directory]::CreateDirectory((Join-Path $script:pdfWorkerTestRoot 'Workers'))
        $script:pdfSupervisorRequest = @{
            SchemaVersion = 1; JobId = [guid]::NewGuid().ToString('D'); JobDirectory = $script:pdfWorkerTestRoot
            SourcePath = Join-Path $script:pdfWorkerTestRoot 'source.docx'; SourceSHA256 = 'A' * 64
            OutputPath = Join-Path $script:pdfWorkerTestRoot 'output.pdf'
        }
        $script:syntheticPdfWorker = @'
param([string]$RequestPath)
[Console]::OutputEncoding=[Text.UTF8Encoding]::new($false)
$request=Get-Content -LiteralPath $RequestPath -Raw -Encoding UTF8 | ConvertFrom-Json
[IO.File]::WriteAllText($request.PendingPdfPath,"%PDF-1.7`nsynthetic transport fixture only`n%%EOF`n",[Text.Encoding]::ASCII)
$info=Get-Item -LiteralPath $request.PendingPdfPath
$hash=(Get-FileHash -LiteralPath $request.PendingPdfPath -Algorithm SHA256).Hash
@{SchemaVersion=1;WorkerPid=$PID;JobId=$request.JobId;Status='Passed';Result=@{Status='Exported';Diagnostic='';Cleanup='Complete';WordLaunchAttempted=$true;Pdf=@{Length=$info.Length;SHA256=$hash}}} | ConvertTo-Json -Depth 5 -Compress
'@
    }
    It 'publishes only a digest-checked PDF after independently verified cleanup' {
        [IO.File]::WriteAllText((Join-Path $script:pdfWorkerTestRoot 'Workers/Export-DocumentPdf.ps1'), $script:syntheticPdfWorker)
        InModuleScope AutopilotExpress.Documents -Parameters @{ Root = $script:pdfWorkerTestRoot; Request = $script:pdfSupervisorRequest } {
            param($Root, $Request)
            $worker = Join-Path $env:WINDIR 'System32/WindowsPowerShell/v1.0/powershell.exe'
            Mock Get-AutopilotDocumentHostCapability { @{ WorkerAvailable = $true; WordRegistrationDetected = $true; WorkerExecutable = $worker } }
            Mock Stop-AutopilotDocumentOwnedWord { 'NotRunning' }
            $previous = $moduleRoot
            try {
                $moduleRoot = $Root
                $result = Invoke-AutopilotDocumentPdfExport -Request $Request
                $result.Status | Should -Be Exported
                $result.Cleanup | Should -Be NotRunning
                $result.OutputPath | Should -BeExactly $Request.OutputPath
                (Get-FileHash -LiteralPath $result.OutputPath -Algorithm SHA256).Hash | Should -BeExactly $result.Pdf.SHA256
                Should -Invoke Stop-AutopilotDocumentOwnedWord -Times 1 -Exactly
            }
            finally { $moduleRoot = $previous }
        }
    }
    It 'does not publish an exported PDF when cleanup is uncertain' {
        [IO.File]::WriteAllText((Join-Path $script:pdfWorkerTestRoot 'Workers/Export-DocumentPdf.ps1'), $script:syntheticPdfWorker)
        InModuleScope AutopilotExpress.Documents -Parameters @{ Root = $script:pdfWorkerTestRoot; Request = $script:pdfSupervisorRequest } {
            param($Root, $Request)
            $worker = Join-Path $env:WINDIR 'System32/WindowsPowerShell/v1.0/powershell.exe'
            Mock Get-AutopilotDocumentHostCapability { @{ WorkerAvailable = $true; WordRegistrationDetected = $true; WorkerExecutable = $worker } }
            Mock Stop-AutopilotDocumentOwnedWord { 'Uncertain' }
            $previous = $moduleRoot
            try {
                $moduleRoot = $Root
                $result = Invoke-AutopilotDocumentPdfExport -Request $Request
                $result.Status | Should -Be Failed
                $result.Cleanup | Should -Be Uncertain
                Test-Path -LiteralPath $Request.OutputPath | Should -BeFalse
            }
            finally { $moduleRoot = $previous }
        }
    }
    It 'kills only the owned synthetic child at the deadline and reports uncertain Word ownership' {
        [IO.File]::WriteAllText((Join-Path $script:pdfWorkerTestRoot 'Workers/Export-DocumentPdf.ps1'), 'param([string]$RequestPath) [Threading.ManualResetEvent]::new($false).WaitOne() | Out-Null')
        InModuleScope AutopilotExpress.Documents -Parameters @{ Root = $script:pdfWorkerTestRoot; Request = $script:pdfSupervisorRequest } {
            param($Root, $Request)
            $worker = Join-Path $env:WINDIR 'System32/WindowsPowerShell/v1.0/powershell.exe'
            Mock Get-AutopilotDocumentHostCapability { @{ WorkerAvailable = $true; WordRegistrationDetected = $true; WorkerExecutable = $worker } }
            $previous = $moduleRoot
            try {
                $moduleRoot = $Root
                $result = Invoke-AutopilotDocumentPdfExport -Request $Request -TimeoutSeconds 1
                $result.Status | Should -Be TimedOut
                $result.Cleanup | Should -Be Uncertain
                Get-Process -Id $result.WorkerPid -ErrorAction SilentlyContinue | Should -BeNullOrEmpty
                Test-Path -LiteralPath $Request.OutputPath | Should -BeFalse
            }
            finally { $moduleRoot = $previous }
        }
    }
    It 'rejects malformed protocol without a published output' {
        [IO.File]::WriteAllText((Join-Path $script:pdfWorkerTestRoot 'Workers/Export-DocumentPdf.ps1'), 'param([string]$RequestPath) "not-json"')
        InModuleScope AutopilotExpress.Documents -Parameters @{ Root = $script:pdfWorkerTestRoot; Request = $script:pdfSupervisorRequest } {
            param($Root, $Request)
            $worker = Join-Path $env:WINDIR 'System32/WindowsPowerShell/v1.0/powershell.exe'
            Mock Get-AutopilotDocumentHostCapability { @{ WorkerAvailable = $true; WordRegistrationDetected = $true; WorkerExecutable = $worker } }
            $previous = $moduleRoot
            try {
                $moduleRoot = $Root
                $result = Invoke-AutopilotDocumentPdfExport -Request $Request
                $result.Status | Should -Be Failed
                Test-Path -LiteralPath $Request.OutputPath | Should -BeFalse
            }
            finally { $moduleRoot = $previous }
        }
    }
    It 'does not launch a worker under WhatIf' {
        InModuleScope AutopilotExpress.Documents -Parameters @{ Request = $script:pdfSupervisorRequest } {
            param($Request)
            Mock Get-AutopilotDocumentHostCapability { @{ WorkerAvailable = $true; WordRegistrationDetected = $true } }
            $result = Invoke-AutopilotDocumentPdfExport -Request $Request -WhatIf
            $result.Status | Should -Be WhatIf
            $result.WorkerPid | Should -Be 0
            $result.RequestPath | Should -BeExactly ''
        }
    }
    It 'localises missing Word without starting a process or creating job files' {
        InModuleScope AutopilotExpress.Documents -Parameters @{ Request = $script:pdfSupervisorRequest } {
            param($Request)
            Mock Get-AutopilotDocumentHostCapability { @{ WorkerAvailable = $true; WordRegistrationDetected = $false } }
            $result = Invoke-AutopilotDocumentPdfExport -Request $Request
            $result.Status | Should -Be Unavailable
            $result.WordLaunchAttempted | Should -BeFalse
            $result.RequestPath | Should -BeExactly ''
        }
    }
    It 'localises a process-start failure without losing cleanup state' {
        InModuleScope AutopilotExpress.Documents -Parameters @{ Root = $script:pdfWorkerTestRoot; Request = $script:pdfSupervisorRequest } {
            param($Root, $Request)
            $missingWorker = Join-Path $Root 'absent.exe'
            Mock Get-AutopilotDocumentHostCapability { @{ WorkerAvailable = $true; WordRegistrationDetected = $true; WorkerExecutable = $missingWorker } }
            $result = Invoke-AutopilotDocumentPdfExport -Request $Request
            $result.Status | Should -Be Failed
            $result.WorkerPid | Should -Be 0
            $result.WordLaunchAttempted | Should -BeFalse
        }
    }
}
Describe 'Word ownership cleanup with fake process objects' {
    It 'never looks up or kills an excluded pre-existing Word process' {
        InModuleScope AutopilotExpress.Documents -Parameters @{ Root = $TestDrive } {
            param($Root)
            $job = [guid]::NewGuid(); $path = Join-Path $Root 'excluded-word.json'
            @{ SchemaVersion = 1; JobId = $job.ToString('D'); WorkerPid = 543210; WordProcessId = 765432; StartTimeUtcTicks = 123; ProcessName = 'WINWORD' } | ConvertTo-Json | Set-Content -LiteralPath $path -Encoding UTF8
            Mock Get-Process { throw 'Must not look up an excluded process' }
            Stop-AutopilotDocumentOwnedWord -OwnershipPath $path -JobId $job -WorkerPid 543210 -ExcludedProcessIds @(765432) | Should -Be Uncertain
            Should -Invoke Get-Process -Times 0 -Exactly
        }
    }
    It 'refuses PID reuse instead of killing the replacement process' {
        InModuleScope AutopilotExpress.Documents -Parameters @{ Root = $TestDrive } {
            param($Root)
            $job = [guid]::NewGuid(); $path = Join-Path $Root 'reused-word.json'
            @{ SchemaVersion = 1; JobId = $job.ToString('D'); WorkerPid = 543210; WordProcessId = 765432; StartTimeUtcTicks = 123; ProcessName = 'WINWORD' } | ConvertTo-Json | Set-Content -LiteralPath $path -Encoding UTF8
            $fake = [pscustomobject]@{ ProcessName = 'WINWORD'; Handle = 1; StartTime = [DateTime]::UtcNow; SessionId = [Diagnostics.Process]::GetCurrentProcess().SessionId; Killed = $false }
            $fake | Add-Member -MemberType ScriptMethod -Name Kill -Value { $this.Killed = $true }
            $fake | Add-Member -MemberType ScriptMethod -Name Dispose -Value { }
            Mock Get-Process { $fake }
            Stop-AutopilotDocumentOwnedWord -OwnershipPath $path -JobId $job -WorkerPid 543210 | Should -Be Uncertain
            $fake.Killed | Should -BeFalse
        }
    }
    It 'stops only a matching fake owned process and waits for its exit' {
        InModuleScope AutopilotExpress.Documents -Parameters @{ Root = $TestDrive } {
            param($Root)
            $job = [guid]::NewGuid(); $path = Join-Path $Root 'owned-word.json'; $startedAt = [DateTime]::UtcNow
            @{ SchemaVersion = 1; JobId = $job.ToString('D'); WorkerPid = 543210; WordProcessId = 765432; StartTimeUtcTicks = $startedAt.ToUniversalTime().Ticks; ProcessName = 'WINWORD' } | ConvertTo-Json | Set-Content -LiteralPath $path -Encoding UTF8
            $fake = [pscustomobject]@{ ProcessName = 'WINWORD'; Handle = 1; StartTime = $startedAt; SessionId = [Diagnostics.Process]::GetCurrentProcess().SessionId; Killed = $false }
            $fake | Add-Member -MemberType ScriptMethod -Name Kill -Value { $this.Killed = $true }
            $fake | Add-Member -MemberType ScriptMethod -Name WaitForExit -Value { param($Milliseconds) $Milliseconds -eq 5000 }
            $fake | Add-Member -MemberType ScriptMethod -Name Dispose -Value { }
            Mock Get-Process { $fake }
            Stop-AutopilotDocumentOwnedWord -OwnershipPath $path -JobId $job -WorkerPid 543210 | Should -Be Stopped
            $fake.Killed | Should -BeTrue
        }
    }
}
Describe 'Author-controlled completion markers' {
    It 'parses a single tracked step or a whole required group' {
        InModuleScope AutopilotExpress.Documents {
            $single = Get-AutopilotDocumentCompletionRule -Marker '{complete:C}'
            ($single.StepIds -join ',') | Should -BeExactly 'C'
            $single.TriggerStepId | Should -BeExactly 'C'
            $group = Get-AutopilotDocumentCompletionRule -Marker '{complete:A,B,C}'
            ($group.StepIds -join ',') | Should -BeExactly 'A,B,C'
            $group.TriggerStepId | Should -BeExactly 'C'
        }
    }
    It 'refuses unsupported, duplicate or executable marker syntax <Marker>' -TestCases @(
        @{ Marker = '{complete:Q}' }, @{ Marker = '{complete:A,A}' }, @{ Marker = '{complete:}' },
        @{ Marker = '{complete:A|B}' }, @{ Marker = '{complete:$(Get-Date)}' }, @{ Marker = 'text {complete:C}' }
    ) {
        param($Marker)
        InModuleScope AutopilotExpress.Documents -Parameters @{ Marker = $Marker } {
            param($Marker)
            $arguments = @{ Marker = $Marker }
            { Get-AutopilotDocumentCompletionRule @arguments } | Should -Throw
        }
    }
}
Describe 'Word export controller with synthetic adapters only' {
    It 'closes an unused prepared Word instance once without document options' {
        InModuleScope AutopilotExpress.Documents {
            $adapter = New-AutopilotDocumentWordAdapter
            $state = & ($adapter.Close.Module) { $state }
            $application = [pscustomobject]@{ AutomationSecurity = 3; DisplayAlerts = 0; Visible = $false; QuitCount = 0 }
            $application | Add-Member -MemberType ScriptMethod -Name Quit -Value { $this.QuitCount++ }
            $state.Application = $application; $state.Owned = $true
            $state.Prior = @{ AutomationSecurity = 1; DisplayAlerts = 2; Visible = $false }
            { & $adapter.Close; & $adapter.Close } | Should -Not -Throw
            $application.QuitCount | Should -Be 1
            $application.AutomationSecurity | Should -Be 1
        }
    }
    It 'requires two certificate pages before PDF export when Word reports <PageCount>' -TestCases @(@{ PageCount = 2 }, @{ PageCount = 3 }) {
        param($PageCount)
        InModuleScope AutopilotExpress.Documents -Parameters @{ PageCount = $PageCount } {
            param($PageCount)
            $adapter = New-AutopilotDocumentWordAdapter
            $state = & ($adapter.Export.Module) { $state }
            $document = [pscustomobject]@{ PageCount = $PageCount; Repaginated = $false; Exported = $false; Statistic = 0 }
            $document | Add-Member -MemberType ScriptMethod -Name Repaginate -Value { $this.Repaginated = $true }
            $document | Add-Member -MemberType ScriptMethod -Name ComputeStatistics -Value { param($Statistic) $this.Statistic = $Statistic; return $this.PageCount }
            $document | Add-Member -MemberType ScriptMethod -Name ExportAsFixedFormat -Value { $this.Exported = $true }
            $state.Owned = $true; $state.Document = $document
            if ($PageCount -eq 2) { & $adapter.Export 'synthetic-owned-copy.pdf' 2; $document.Exported | Should -BeTrue }
            else { { & $adapter.Export 'synthetic-owned-copy.pdf' 2 } | Should -Throw '*Word reports 3 pages; expected 2*'; $document.Exported | Should -BeFalse }
            $document.Repaginated | Should -BeTrue
            $document.Statistic | Should -Be 2
        }
    }
    It 'wires the production adapter security, whole-document PDF, labels and structure flags without COM' {
        InModuleScope AutopilotExpress.Documents {
            $adapter = New-AutopilotDocumentWordAdapter
            $state = & ($adapter.Open.Module) { $state }
            $document = [pscustomobject]@{ ReadOnly = $true; ExportArguments = @(); CloseArguments = @() }
            $document | Add-Member -MemberType ScriptMethod -Name ExportAsFixedFormat -Value { $this.ExportArguments = @($args) }
            $document | Add-Member -MemberType ScriptMethod -Name Close -Value { $this.CloseArguments = @($args) }
            if (-not ('AutopilotDocumentTests.FakeDocuments' -as [type])) {
                Add-Type -TypeDefinition @'
namespace AutopilotDocumentTests {
    public sealed class FakeDocuments {
        public object Document;
        public object[] OpenArguments;
        public object OpenNoRepairDialog(object fileName, object confirmConversions, object readOnly, object recent,
            object password = null, object templatePassword = null, object revert = null, object writePassword = null,
            object templateWritePassword = null, object format = null, object encoding = null, object visible = null,
            object repair = null, object direction = null, object noEncodingDialog = null, object transform = null) {
            OpenArguments = new object[] { fileName, confirmConversions, readOnly, recent, password, templatePassword,
                revert, writePassword, templateWritePassword, format, encoding, visible, repair, direction, noEncodingDialog, transform };
            return Document;
        }
    }
}
'@
            }
            $documents = New-Object AutopilotDocumentTests.FakeDocuments
            $documents.Document = $document
            $options = [pscustomobject]@{ UpdateLinksAtOpen = $true; UpdateFieldsAtPrint = $true; UpdateLinksAtPrint = $true; CheckSpellingAsYouType = $true; CheckGrammarAsYouType = $true }
            $application = [pscustomobject]@{ AutomationSecurity = 1; DisplayAlerts = 2; Visible = $true; Options = $options; Documents = $documents; QuitArguments = @() }
            $application | Add-Member -MemberType ScriptMethod -Name Quit -Value { $this.QuitArguments = @($args) }
            $state.Application = $application; $state.Owned = $true
            & $adapter.Open 'synthetic-owned-copy.docx'
            $application.AutomationSecurity | Should -Be 3
            $options.UpdateLinksAtOpen | Should -BeFalse
            $options.UpdateFieldsAtPrint | Should -BeFalse
            $options.UpdateLinksAtPrint | Should -BeFalse
            $options.CheckSpellingAsYouType | Should -BeFalse
            $options.CheckGrammarAsYouType | Should -BeFalse
            $documents.OpenArguments[2] | Should -BeTrue
            $documents.OpenArguments[3] | Should -BeFalse
            $documents.OpenArguments[11] | Should -BeFalse
            $documents.OpenArguments[12] | Should -BeFalse
            $documents.OpenArguments[14] | Should -BeTrue
            & $adapter.Export 'synthetic-owned-copy.pdf'
            $document.ExportArguments[1] | Should -Be 17
            $document.ExportArguments[2] | Should -BeFalse
            $document.ExportArguments[3] | Should -Be 0
            $document.ExportArguments[4] | Should -Be 0
            $document.ExportArguments[8] | Should -BeFalse
            $document.ExportArguments[9] | Should -BeTrue
            $document.ExportArguments[11] | Should -BeTrue
            & $adapter.Close
            $document.CloseArguments[0] | Should -Be 0
            $adapter.Close.ToString() | Should -Match 'Quit\(\[ref\]\$saveChanges\)'
            $application.QuitArguments[0].Value | Should -Be 0
            $application.AutomationSecurity | Should -Be 1
            $options.UpdateLinksAtOpen | Should -BeTrue
            $options.CheckSpellingAsYouType | Should -BeTrue
            $options.CheckGrammarAsYouType | Should -BeTrue
            $state.Application | Should -BeNullOrEmpty
            $state.Owned | Should -BeFalse
            { & $adapter.Close } | Should -Not -Throw
        }
    }
    BeforeEach {
        $script:wordTestSource = Join-Path $TestDrive ('source-{0}.docx' -f [guid]::NewGuid().ToString('N'))
        [IO.File]::WriteAllText($script:wordTestSource, 'synthetic adapter fixture, not an Office document')
        $script:wordTestRequest = @{
            SchemaVersion = 1; JobId = [guid]::NewGuid().ToString('D'); JobDirectory = $TestDrive
            SourcePath = $script:wordTestSource; SourceSHA256 = (Get-FileHash -LiteralPath $script:wordTestSource -Algorithm SHA256).Hash
            PendingPdfPath = Join-Path $TestDrive ('pending-{0}.pdf' -f [guid]::NewGuid().ToString('N'))
            OwnershipPath = Join-Path $TestDrive ('owner-{0}.json' -f [guid]::NewGuid().ToString('N'))
        }
    }
    It 'orders ownership before read-only open, validates output and always closes' {
        InModuleScope AutopilotExpress.Documents -Parameters @{ Request = $script:wordTestRequest } {
            param($Request)
            $calls = [Collections.Generic.List[string]]::new()
            $adapter = @{
                Start  = { $calls.Add('Start'); @{ WordProcessId = 765432; StartTimeUtcTicks = 123; ProcessName = 'WINWORD' } }.GetNewClosure()
                Open   = { param($Path) $Path | Should -BeExactly $Request.SourcePath; Test-Path -LiteralPath $Request.OwnershipPath | Should -BeTrue; $calls.Add('Open') }.GetNewClosure()
                Export = { param($Path) $calls.Add('Export'); [IO.File]::WriteAllText($Path, "%PDF-1.7`nsynthetic transport fixture only`n%%EOF`n", [Text.Encoding]::ASCII) }.GetNewClosure()
                Close  = { $calls.Add('Close') }.GetNewClosure()
            }
            $result = Invoke-AutopilotDocumentWordExport -Request $Request -Adapter $adapter
            $result.Status | Should -Be Exported
            $result.Cleanup | Should -Be Complete
            $result.Pdf.SHA256 | Should -Match '^[A-F0-9]{64}$'
            ($calls -join ',') | Should -BeExactly 'Start,Open,Export,Close'
            (Get-FileHash -LiteralPath $Request.SourcePath -Algorithm SHA256).Hash | Should -BeExactly $Request.SourceSHA256
        }
    }
    It 'reuses one ownership record for two document exports and quits only at batch end' {
        InModuleScope AutopilotExpress.Documents -Parameters @{ Request = $script:wordTestRequest } {
            param($Request)
            $calls = [Collections.Generic.List[string]]::new()
            $adapter = @{
                Start         = { @{ WordProcessId = 765432; StartTimeUtcTicks = 123; ProcessName = 'WINWORD' } }
                Open          = { param($Path) $null = $Path; $calls.Add('Open') }.GetNewClosure()
                Export        = { param($Path) [IO.File]::WriteAllText($Path, "%PDF-1.7`nfixture`n%%EOF`n", [Text.Encoding]::ASCII) }
                CloseDocument = { $calls.Add('CloseDocument') }.GetNewClosure()
                Close         = { $calls.Add('Quit') }.GetNewClosure()
            }
            (Invoke-AutopilotDocumentWordExport -Request $Request -Adapter $adapter -KeepWordOpen).Status | Should -Be Exported
            $ownerHash = (Get-FileHash -LiteralPath $Request.OwnershipPath).Hash
            $Request.PendingPdfPath = Join-Path $Request.JobDirectory 'second.pdf'
            (Invoke-AutopilotDocumentWordExport -Request $Request -Adapter $adapter -KeepWordOpen).Status | Should -Be Exported
            (Get-FileHash -LiteralPath $Request.OwnershipPath).Hash | Should -BeExactly $ownerHash
            ($calls -join ',') | Should -BeExactly 'Open,CloseDocument,Open,CloseDocument'
            & $adapter.Close
            $calls[-1] | Should -BeExactly Quit
        }
    }
    It 'closes after export failure and never claims a PDF' {
        InModuleScope AutopilotExpress.Documents -Parameters @{ Request = $script:wordTestRequest } {
            param($Request)
            $state = @{ Closed = $false }
            $adapter = @{
                Start  = { @{ WordProcessId = 765432; StartTimeUtcTicks = 123; ProcessName = 'WINWORD' } }
                Open   = { param($Path) $null = $Path }
                Export = { param($Path) $null = $Path; throw 'synthetic COM export failure' }
                Close  = { $state.Closed = $true }.GetNewClosure()
            }
            $result = Invoke-AutopilotDocumentWordExport -Request $Request -Adapter $adapter
            $result.Status | Should -Be Failed
            $result.Diagnostic | Should -Match 'synthetic COM export failure'
            $result.Cleanup | Should -Be Complete
            $result.Pdf | Should -BeNullOrEmpty
            $state.Closed | Should -BeTrue
        }
    }
    It 'reports uncertain cleanup even when export produced a PDF' {
        InModuleScope AutopilotExpress.Documents -Parameters @{ Request = $script:wordTestRequest } {
            param($Request)
            $adapter = @{
                Start  = { @{ WordProcessId = 765432; StartTimeUtcTicks = 123; ProcessName = 'WINWORD' } }
                Open   = { param($Path) $null = $Path }
                Export = { param($Path) [IO.File]::WriteAllText($Path, "%PDF-1.7`nsynthetic transport fixture only`n%%EOF`n", [Text.Encoding]::ASCII) }
                Close  = { throw 'synthetic cleanup failure' }
            }
            $result = Invoke-AutopilotDocumentWordExport -Request $Request -Adapter $adapter
            $result.Status | Should -Be Failed
            $result.Cleanup | Should -Be Uncertain
        }
    }
    It 'rejects changed input before starting any adapter' {
        InModuleScope AutopilotExpress.Documents -Parameters @{ Request = $script:wordTestRequest } {
            param($Request)
            $Request.SourceSHA256 = 'A' * 64
            Mock New-AutopilotDocumentWordAdapter { throw 'adapter must not be created' }
            $result = Invoke-AutopilotDocumentWordExport -Request $Request
            $result.Status | Should -Be Failed
            $result.Diagnostic | Should -Match 'digest changed'
            $result.WordLaunchAttempted | Should -BeFalse
            Should -Invoke New-AutopilotDocumentWordAdapter -Times 0 -Exactly
        }
    }
    It 'does not create an adapter or ownership file under WhatIf' {
        InModuleScope AutopilotExpress.Documents -Parameters @{ Request = $script:wordTestRequest } {
            param($Request)
            Mock New-AutopilotDocumentWordAdapter { throw 'adapter must not be created' }
            $result = Invoke-AutopilotDocumentWordExport -Request $Request -WhatIf
            $result.Status | Should -Be WhatIf
            Test-Path -LiteralPath $Request.OwnershipPath | Should -BeFalse
            Should -Invoke New-AutopilotDocumentWordAdapter -Times 0 -Exactly
        }
    }
}
Describe 'PDF transport validation without Office' {
    It 'hashes a bounded PDF envelope without launching a viewer or claiming conformance' {
        InModuleScope AutopilotExpress.Documents -Parameters @{ Root = $TestDrive } {
            param($Root)
            $path = Join-Path $Root 'envelope.pdf'
            [IO.File]::WriteAllText($path, "%PDF-1.7`nsynthetic transport fixture only`n%%EOF`n", [Text.Encoding]::ASCII)
            $info = Get-AutopilotDocumentPdfInfo -Path $path
            $info.SHA256 | Should -BeExactly (Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash
            $info.Length | Should -Be (Get-Item -LiteralPath $path).Length
        }
    }
    It 'rejects a truncated PDF' {
        InModuleScope AutopilotExpress.Documents -Parameters @{ Root = $TestDrive } {
            param($Root)
            $path = Join-Path $Root 'truncated.pdf'
            [IO.File]::WriteAllText($path, '%PDF-1.7 synthetic incomplete transport fixture', [Text.Encoding]::ASCII)
            { Get-AutopilotDocumentPdfInfo -Path $path } | Should -Throw '*truncated*'
        }
    }
    It 'rejects a renamed non-PDF file' {
        InModuleScope AutopilotExpress.Documents -Parameters @{ Root = $TestDrive } {
            param($Root)
            $path = Join-Path $Root 'not-pdf.pdf'
            [IO.File]::WriteAllText($path, 'this is not a PDF document %%EOF', [Text.Encoding]::ASCII)
            { Get-AutopilotDocumentPdfInfo -Path $path } | Should -Throw '*PDF header*'
        }
    }
}
Describe 'Document barcode geometry and review profiles' {
    It 'uses readable integer modules and quiet zones inside unchanged bounds' {
        $layout = Get-AutopilotDocumentBarcodeLayout -ModuleCount 101 -WidthTwips 4000 -HeightTwips 600
        $layout.ModulePixels | Should -BeGreaterOrEqual 3
        $layout.QuietZoneModules | Should -Be 10
        $layout.PixelWidth | Should -Be ((101 + 20) * $layout.ModulePixels)
        $layout.WidthEmu | Should -Be ($layout.PixelWidth * 3048)
        $layout.WidthEmu | Should -BeLessOrEqual (4000 * 635)
        $layout.HeightEmu | Should -BeLessOrEqual (600 * 635)
        $layout.PixelHeight | Should -BeGreaterOrEqual 75
        $layout.PixelHeight | Should -BeGreaterOrEqual ([Math]::Ceiling(101 * $layout.ModulePixels * 0.15))
    }
    It 'classifies unreadable width as an omission rather than allowing fractional modules' {
        { Get-AutopilotDocumentBarcodeLayout -ModuleCount 900 -WidthTwips 4000 -HeightTwips 600 } | Should -Throw -ErrorId 'AutopilotBarcodeDoesNotFit,*'
    }
    It 'classifies inadequate bar height as an omission' {
        { Get-AutopilotDocumentBarcodeLayout -ModuleCount 101 -WidthTwips 4000 -HeightTwips 200 } | Should -Throw -ErrorId 'AutopilotBarcodeDoesNotFit,*'
    }
    It 'does not implicitly approve either real template' {
        foreach ($kind in @('BirthCertificate', 'Checklist')) {
            $reviewProfile = Get-AutopilotDocumentTemplateProfile -DocumentType $kind
            $reviewProfile.ApprovedForLive | Should -BeFalse
            @($reviewProfile.Bindings | Where-Object Kind -EQ CertificationLabel).Count | Should -Be 1
        }
    }
    It 'returns detached profiles including the three exact approved checklist warnings' {
        $reviewProfile = Get-AutopilotDocumentTemplateProfile -DocumentType Checklist
        $reviewProfile.ValidationExceptions.Count | Should -Be 3
        $reviewProfile.ValidationExceptions[0].Id | Should -BeExactly 'Sem_UniqueAttributeValue'
        $reviewProfile.ValidationExceptions[0].Description = 'changed by caller'
        $reviewProfile.Bindings[0].ExpectedText = 'changed by caller'
        $fresh = Get-AutopilotDocumentTemplateProfile -DocumentType Checklist
        $fresh.ValidationExceptions[0].Description | Should -Not -BeExactly 'changed by caller'
        $fresh.Bindings[0].ExpectedText | Should -Not -BeExactly 'changed by caller'
    }
}
Describe 'Isolated structural population regressions' -Tag DocumentIntegration -Skip:($env:AUTOPILOT_DOCUMENT_INTEGRATION -ne '1') {
    BeforeAll {
        Add-Type -AssemblyName System.IO.Compression.FileSystem, System.Drawing
        $script:populationDependencyRoot = Join-Path $env:LOCALAPPDATA 'PowerShellScriptingNew/AutopilotExpress/Documents/dependencies'
        $verifiedPopulationBundle = Test-AutopilotDocumentDependencyBundle -DependencyRoot $script:populationDependencyRoot
        if (-not $verifiedPopulationBundle.Valid) { throw 'These opt-in tests require the previously approved local bundle; they never acquire it.' }
        $script:populationTemplates = @{}; $script:populationTemplateHashes = @{}
        foreach ($kind in @('BirthCertificate', 'Checklist')) {
            $name = if ($kind -eq 'Checklist') { 'Autopilot Checklist - v1.5.docx' } else { 'Autopilot Birth Certificate - v1.5.docx' }
            $snapshot = Join-Path $TestDrive ('{0}.docx' -f $kind)
            $source = [IO.File]::Open((Join-Path $env:AutopilotExpressRoot ('templates/{0}' -f $name)), [IO.FileMode]::Open, [IO.FileAccess]::Read, ([IO.FileShare]::ReadWrite -bor [IO.FileShare]::Delete))
            $target = [IO.File]::Open($snapshot, [IO.FileMode]::CreateNew, [IO.FileAccess]::Write, [IO.FileShare]::None)
            try { $source.CopyTo($target) } finally { $source.Dispose(); $target.Dispose() }
            $script:populationTemplates[$kind] = $snapshot
            $script:populationTemplateHashes[$kind] = (Get-FileHash -LiteralPath $snapshot -Algorithm SHA256).Hash
        }
        $script:syntheticPopulationTemplate = Join-Path $TestDrive 'synthetic-structural.docx'
        $syntheticParts = [ordered]@{
            '[Content_Types].xml'          = '<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types"><Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/><Default Extension="xml" ContentType="application/xml"/><Override PartName="/word/document.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.document.main+xml"/><Override PartName="/word/header1.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.header+xml"/><Override PartName="/word/footer1.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.footer+xml"/></Types>'
            '_rels/.rels'                  = '<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships"><Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="word/document.xml"/></Relationships>'
            'word/_rels/document.xml.rels' = '<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships"><Relationship Id="header1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/header" Target="header1.xml"/><Relationship Id="footer1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/footer" Target="footer1.xml"/></Relationships>'
            'word/document.xml'            = '<w:document xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main" xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships"><w:body><w:p><w:r><w:t>Synthetic document</w:t></w:r></w:p><w:p><w:r><w:rPr><w:b/></w:rPr><w:t>{</w:t></w:r><w:proofErr w:type="spellStart"/><w:r><w:rPr><w:i/></w:rPr><w:t>x}</w:t></w:r><w:proofErr w:type="spellEnd"/></w:p><w:p><w:r><w:t>{x} {x}</w:t></w:r></w:p><w:p><w:sdt><w:sdtPr><w:tag w:val="Owner"/><w:id w:val="17"/><w:text/></w:sdtPr><w:sdtContent><w:r><w:t>old owner</w:t></w:r></w:sdtContent></w:sdt></w:p><w:p><w:sdt><w:sdtPr><w:tag w:val="Date"/><w:id w:val="18"/><w:date w:fullDate="2020-01-01T00:00:00Z"><w:dateFormat w:val="dd/MM/yyyy"/><w:lid w:val="en-AU"/><w:storeMappedDataAs w:val="dateTime"/><w:calendar w:val="gregorian"/></w:date></w:sdtPr><w:sdtContent><w:r><w:t>01/01/2020</w:t></w:r></w:sdtContent></w:sdt></w:p><w:p><w:r><w:t>{cross</w:t><w:tab/><w:t>}</w:t></w:r></w:p><w:sectPr><w:headerReference w:type="default" r:id="header1"/><w:footerReference w:type="default" r:id="footer1"/></w:sectPr></w:body></w:document>'
            'word/header1.xml'             = '<w:hdr xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main"><w:p><w:r><w:t>{x}</w:t></w:r></w:p></w:hdr>'
            'word/footer1.xml'             = '<w:ftr xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main"><w:p><w:r><w:t>{x}</w:t></w:r></w:p></w:ftr>'
        }
        $archive = [IO.Compression.ZipFile]::Open($script:syntheticPopulationTemplate, [IO.Compression.ZipArchiveMode]::Create)
        try {
            foreach ($name in $syntheticParts.Keys) {
                $stream = $archive.CreateEntry($name).Open()
                try { $bytes = [Text.Encoding]::UTF8.GetBytes($syntheticParts[$name]); $stream.Write($bytes, 0, $bytes.Length) } finally { $stream.Dispose() }
            }
        }
        finally { $archive.Dispose() }
        $script:createSyntheticPopulationProfile = {
            [ordered]@{
                SchemaVersion = 1; ProfileId = 'synthetic-structural-1'; ApprovedForLive = $false
                TemplateSHA256 = (Get-FileHash -LiteralPath $script:syntheticPopulationTemplate -Algorithm SHA256).Hash
                Bindings = @(
                    @{ Kind = 'CertificationLabel'; Part = '/word/document.xml'; ParagraphIndex = 0; ExpectedText = 'Synthetic document' },
                    @{ Kind = 'Literal'; Part = '/word/document.xml'; Marker = '{x}'; Field = 'Location'; Required = $true; ExpectedCount = 3 },
                    @{ Kind = 'Literal'; Part = '/word/header1.xml'; Marker = '{x}'; Field = 'Location'; Required = $true; ExpectedCount = 1 },
                    @{ Kind = 'Literal'; Part = '/word/footer1.xml'; Marker = '{x}'; Field = 'Location'; Required = $true; ExpectedCount = 1 },
                    @{ Kind = 'TextControl'; Part = '/word/document.xml'; Tag = 'Owner'; Field = 'CompletedBy'; Required = $true },
                    @{ Kind = 'DateControl'; Part = '/word/document.xml'; Tag = 'Date' }
                )
            }
        }
        $script:readPopulationXml = {
            param([string]$Path)
            $archive = [IO.Compression.ZipFile]::OpenRead($Path); $parts = @{}
            try {
                foreach ($entry in $archive.Entries | Where-Object { $_.FullName -match '\.(xml|rels)$' }) {
                    $reader = [IO.StreamReader]::new($entry.Open(), [Text.Encoding]::UTF8)
                    try { $parts[$entry.FullName] = [xml]$reader.ReadToEnd() } finally { $reader.Dispose() }
                }
            }
            finally { $archive.Dispose() }
            return $parts
        }
    }
    BeforeEach {
        $script:populationRequest = [ordered]@{
            SchemaVersion = 1; ReviewOnly = $true
            Profile = Get-AutopilotDocumentTemplateProfile -DocumentType BirthCertificate
            TemplatePath = $script:populationTemplates.BirthCertificate
            OutputPath = Join-Path $TestDrive ('generated-{0}.docx' -f [guid]::NewGuid().ToString('N'))
            Job = [ordered]@{
                SchemaVersion = 1; Mode = 'Demo'; IsAdministrativeOverride = $false; OverrideReason = ''; AssignedUserRequired = $true
                Steps = @{}; DispatchedAt = '2026-10-23T15:00:00+08:00'
                Fields = [ordered]@{
                    ConfigurationItem = '123456'; SerialNumberOrServiceTag = 'ABC123'; Location = ''; EmployeeNumber = ''
                    SiteName = 'Synthetic Full Site'; AssignedUserName = 'jane.smith'; AssignedUserFullName = 'Jane Smith'
                    TechnicianName = ('Dispatch {0}' -f [char]0x00C9)
                    IntuneHostName = 'LT-SYNTHETIC'; EthernetMacAddress = '00:11:22:33:44:55'; CompletedBy = ('Synthetic {0}' -f [char]0x00C9)
                }
            }
        }
    }
    AfterEach {
        foreach ($kind in @('BirthCertificate', 'Checklist')) {
            (Get-FileHash -LiteralPath $script:populationTemplates[$kind] -Algorithm SHA256).Hash | Should -BeExactly $script:populationTemplateHashes[$kind]
        }
        @([AppDomain]::CurrentDomain.GetAssemblies() | Where-Object { $_.GetName().Name -in @('DocumentFormat.OpenXml', 'DocumentFormat.OpenXml.Framework', 'zxing') }).Count | Should -Be 0
    }
    It 'reuses only exact prepared source bytes and policy without writing preparation output' {
        $request = $script:populationRequest
        $request['DependencyRoot'] = $script:populationDependencyRoot
        $request.TemplatePath = Join-Path $TestDrive 'cache-template.docx'
        Copy-Item -LiteralPath $script:populationTemplates.BirthCertificate -Destination $request.TemplatePath
        $payload = [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes(($request | ConvertTo-Json -Depth 20 -Compress)))
        $body = {
            $ErrorActionPreference = 'Stop'
            Import-Module (Join-Path $env:AutopilotExpressRoot 'Modules/Documents/AutopilotExpress.Documents.psd1') -Force
            & (Get-Module AutopilotExpress.Documents) {
                param($Json)
                $request = ConvertTo-AutopilotDocumentDictionary -Value ($Json | ConvertFrom-Json)
                $verified = Test-AutopilotDocumentDependencyBundle -DependencyRoot $request.DependencyRoot
                if (-not $verified.Valid) { throw 'Cache test requires the verified bundle.' }
                Add-Type -AssemblyName WindowsBase, System.Drawing, System.IO.Compression
                foreach ($package in (Get-AutopilotDocumentDependencyManifest).Packages) { $null = [Reflection.Assembly]::LoadFrom((Join-Path $verified.BundlePath $package.FileName)) }
                $basePath = $request.OutputPath
                $prepared = New-AutopilotDocumentCopy -Request $request -PrepareOnly
                if ($prepared.Status -ne 'Prepared' -or (Test-Path -LiteralPath $basePath)) { throw 'Preparation wrote an output.' }
                $first = New-AutopilotDocumentCopy -Request $request
                if (-not $first.PreparedSourceUsed) { throw 'Exact prepared source was not reused.' }
                $request.Profile['CachePolicyProbe'] = 'changed'
                $request.OutputPath = $basePath + '.policy.docx'
                $policy = New-AutopilotDocumentCopy -Request $request
                if ($policy.PreparedSourceUsed) { throw 'Changed policy incorrectly reused preparation.' }
                $stream = [IO.File]::Open($request.TemplatePath, [IO.FileMode]::Open, [IO.FileAccess]::ReadWrite, [IO.FileShare]::None)
                $archive = [IO.Compression.ZipArchive]::new($stream, [IO.Compression.ZipArchiveMode]::Update)
                try {
                    $entry = $archive.GetEntry('word/document.xml')
                    $reader = [IO.StreamReader]::new($entry.Open())
                    try { $xml = [xml]::new(); $xml.PreserveWhitespace = $true; $xml.LoadXml($reader.ReadToEnd()) } finally { $reader.Dispose() }
                    $null = $xml.AppendChild($xml.CreateComment('Cache byte mutation'))
                    $entry.Delete()
                    $writer = [IO.StreamWriter]::new($archive.CreateEntry('word/document.xml').Open(), [Text.UTF8Encoding]::new($false))
                    try { $writer.Write($xml.OuterXml) } finally { $writer.Dispose() }
                }
                finally { $archive.Dispose(); $stream.Dispose() }
                $request.OutputPath = $basePath + '.bytes.docx'
                $bytes = New-AutopilotDocumentCopy -Request $request
                if ($bytes.PreparedSourceUsed) { throw 'Changed template bytes incorrectly reused preparation.' }
                $request.Profile.Bindings[0].Kind = 'Invalid'
                try { $null = New-AutopilotDocumentCopy -Request $request -PrepareOnly; throw 'Invalid policy was accepted.' }
                catch { if ($_.Exception.Message -notlike '*Unknown or malformed*') { throw } }
                $request.Profile.Bindings[0].Kind = 'CertificationLabel'
                $request.OutputPath = $basePath + '.recovered.docx'
                $recovered = New-AutopilotDocumentCopy -Request $request
                if (-not $recovered.PreparedSourceUsed) { throw 'Rejected policy replaced the valid cache entry.' }
                'CacheChecksPassed'
            } $requestJson
        }
        $code = '$requestJson = [Text.Encoding]::UTF8.GetString([Convert]::FromBase64String(''{0}''));' -f $payload
        $encoded = [Convert]::ToBase64String([Text.Encoding]::Unicode.GetBytes(($code + $body.ToString())))
        $output = & (Join-Path $env:WINDIR 'System32/WindowsPowerShell/v1.0/powershell.exe') -NoProfile -NonInteractive -STA -EncodedCommand $encoded 2>&1
        $LASTEXITCODE | Should -Be 0 -Because ($output -join [Environment]::NewLine)
        $output | Should -Contain 'CacheChecksPassed'
    }
    It 'populates the certificate with four decode-verified barcodes and explicit DRAFT and DEMO labels' {
        $result = Invoke-AutopilotDocumentPopulation -Request $script:populationRequest -DependencyRoot $script:populationDependencyRoot
        $result.Status | Should -Be Populated
        $result.WordLaunched | Should -BeFalse
        $result.Output.BarcodeOmissions.Count | Should -Be 0
        $result.Output.ValidationWarnings.Count | Should -Be 0
        $parts = & $script:readPopulationXml $script:populationRequest.OutputPath
        $text = $parts['word/document.xml'].DocumentElement.InnerText
        $headerText = (@($parts.Keys | Where-Object { $_ -like 'word/header*.xml' } | ForEach-Object { $parts[$_].DocumentElement.InnerText }) -join ' ')
        $headerText | Should -Not -Match 'DRAFT|DEMO'
        $footer = $parts['word/footer1.xml']
        $footerParagraph = $footer.SelectSingleNode('//*[local-name()="tbl"]/*[local-name()="tr"][1]/*[local-name()="tc"][last()]/*[local-name()="p"][1]')
        $footerParagraph.InnerText | Should -Match 'DRAFT - NOT APPROVED - DEMO - NOT LIVE'
        $footerParagraph.SelectSingleNode('./*[local-name()="r"]/*[local-name()="rPr"]/*[local-name()="sz"]').GetAttribute('val', 'http://schemas.openxmlformats.org/wordprocessingml/2006/main') | Should -BeExactly '12'
        $footerParagraph.SelectSingleNode('./*[local-name()="pPr"]/*[local-name()="jc"]').GetAttribute('val', 'http://schemas.openxmlformats.org/wordprocessingml/2006/main') | Should -BeExactly 'right'
        $text | Should -Match ([regex]::Escape($script:populationRequest.Job.Fields.TechnicianName))
        $paragraphs = $parts['word/document.xml'].SelectNodes('//*[local-name()="p"]')
        foreach ($index in @(3, 6, 25, 28)) {
            $paragraphs[$index].SelectSingleNode('./*[local-name()="pPr"]/*[local-name()="jc"]').GetAttribute('val', 'http://schemas.openxmlformats.org/wordprocessingml/2006/main') | Should -BeExactly 'center'
        }
        $paragraphs[0].InnerText | Should -BeExactly 'Digital and Technology - Device Birth Certificate'
        $paragraphs[12].InnerText | Should -BeExactly 'Synthetic Full Site - '
        $paragraphs[15].InnerText | Should -BeExactly 'jane.smith Jane Smith'
        $paragraphs[49].InnerText | Should -BeExactly '23/10/2026'
        foreach ($index in @(9, 31, 42, 43, 44, 50, 51, 52)) { $paragraphs[$index].InnerText | Should -BeExactly '' }
        $parts['word/document.xml'].SelectNodes('//*[local-name()="docPr" and @name="Code 128 identifier"]').Count | Should -Be 4
        $archive = [IO.Compression.ZipFile]::OpenRead($script:populationRequest.OutputPath)
        try {
            foreach ($inline in $parts['word/document.xml'].SelectNodes('//*[local-name()="inline" and *[local-name()="docPr" and @name="Code 128 identifier"]]')) {
                $imageId = $inline.SelectSingleNode('.//*[local-name()="blip"]').GetAttribute('embed', 'http://schemas.openxmlformats.org/officeDocument/2006/relationships')
                $relation = $parts['word/_rels/document.xml.rels'].SelectSingleNode(('//*[local-name()="Relationship" and @Id="{0}"]' -f $imageId))
                $imageUri = [uri]::new([uri]'http://package/word/document.xml', $relation.GetAttribute('Target'))
                $stream = $archive.GetEntry($imageUri.AbsolutePath.TrimStart('/')).Open(); $bitmap = $null
                try {
                    $bitmap = [Drawing.Bitmap]::new($stream); $middle = [int][Math]::Floor($bitmap.Height / 2)
                    $bitmap.HorizontalResolution | Should -BeGreaterThan 599
                    $bitmap.HorizontalResolution | Should -BeLessThan 601
                    $extent = $inline.SelectSingleNode('./*[local-name()="extent"]')
                    [long]$extent.GetAttribute('cx') | Should -Be ($bitmap.Width * 1524L)
                    [long]$extent.GetAttribute('cy') | Should -Be ($bitmap.Height * 1524L)
                    $left = 0; $right = $bitmap.Width - 1
                    while ($left -lt $bitmap.Width -and $bitmap.GetPixel($left, $middle).R -eq 255) { $left++ }
                    while ($right -ge 0 -and $bitmap.GetPixel($right, $middle).R -eq 255) { $right-- }
                    $left | Should -BeGreaterOrEqual 30
                    ($bitmap.Width - 1 - $right) | Should -BeGreaterOrEqual 30
                    for ($column = 0; $column -lt $bitmap.Width; $column++) {
                        $bitmap.GetPixel($column, 0).ToArgb() | Should -Be ($bitmap.GetPixel($column, $middle).ToArgb())
                        $bitmap.GetPixel($column, $bitmap.Height - 1).ToArgb() | Should -Be ($bitmap.GetPixel($column, $middle).ToArgb())
                    }
                }
                finally { if ($null -ne $bitmap) { $bitmap.Dispose() }; $stream.Dispose() }
            }
        }
        finally { $archive.Dispose() }
    }
    It 'replaces split and repeated markers once, preserves runs and stories, and updates native text/date controls' {
        $script:populationRequest.TemplatePath = $script:syntheticPopulationTemplate
        $script:populationRequest.Profile = & $script:createSyntheticPopulationProfile
        $script:populationRequest.Job.Fields.Location = 'A & B {x}'
        $result = Invoke-AutopilotDocumentPopulation -Request $script:populationRequest -DependencyRoot $script:populationDependencyRoot
        $result.Status | Should -Be Populated
        $parts = & $script:readPopulationXml $script:populationRequest.OutputPath
        $paragraphs = $parts['word/document.xml'].SelectNodes('//*[local-name()="p"]')
        $paragraphs[1].InnerText | Should -BeExactly 'A & B {x}'
        $paragraphs[2].InnerText | Should -BeExactly 'A & B {x} A & B {x}'
        $paragraphs[1].SelectNodes('.//*[local-name()="b" or local-name()="i"]').Count | Should -Be 2
        $parts['word/header1.xml'].DocumentElement.InnerText | Should -BeExactly 'A & B {x}'
        $parts['word/footer1.xml'].DocumentElement.InnerText | Should -BeExactly 'A & B {x}'
        $paragraphs[3].InnerText | Should -BeExactly $script:populationRequest.Job.Fields.CompletedBy
        $paragraphs[4].InnerText | Should -BeExactly '23/10/2026'
        $paragraphs[4].SelectSingleNode('.//*[local-name()="date"]').GetAttribute('fullDate', 'http://schemas.openxmlformats.org/wordprocessingml/2006/main') | Should -Match '^2026-10-23T07:00:00'
    }
    It 'populates certificate groups only when every mapped action is eligible and never fills untracked groups' {
        $baselineTemplate = Join-Path $TestDrive 'unmarked-baseline.docx'
        Copy-Item -LiteralPath $script:populationRequest.TemplatePath -Destination $baselineTemplate
        $archive = [IO.Compression.ZipFile]::Open($baselineTemplate, [IO.Compression.ZipArchiveMode]::Update)
        try {
            $entry = $archive.GetEntry('word/document.xml')
            $reader = [IO.StreamReader]::new($entry.Open())
            try { $xml = [xml]::new(); $xml.PreserveWhitespace = $true; $xml.LoadXml($reader.ReadToEnd()) } finally { $reader.Dispose() }
            foreach ($paragraph in $xml.SelectNodes('//*[local-name()="p"]') | Where-Object { $_.InnerText -match '\{complete:' }) {
                foreach ($child in @($paragraph.ChildNodes | Where-Object LocalName -NE 'pPr')) { $null = $paragraph.RemoveChild($child) }
            }
            $entry.Delete()
            $replacement = $archive.CreateEntry('word/document.xml').Open()
            try { $xml.Save($replacement) } finally { $replacement.Dispose() }
        }
        finally { $archive.Dispose() }
        $script:populationRequest.TemplatePath = $baselineTemplate
        $script:populationRequest.Job.Mode = 'Live'
        foreach ($step in @('A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N', 'O')) { $script:populationRequest.Job.Steps[$step] = @{ TickEligible = $true } }
        $result = Invoke-AutopilotDocumentPopulation -Request $script:populationRequest -DependencyRoot $script:populationDependencyRoot
        $result.Status | Should -Be Populated
        $parts = & $script:readPopulationXml $script:populationRequest.OutputPath
        $paragraphs = $parts['word/document.xml'].SelectNodes('//*[local-name()="p"]')
        foreach ($index in @(64, 67, 73, 98)) { $paragraphs[$index].InnerText | Should -BeExactly 'Y' }
        foreach ($index in @(80, 95, 101, 104)) { $paragraphs[$index].InnerText | Should -BeExactly '' }
    }
    It 'evaluates split-run author markers using all explicitly mapped steps: <Case>' -ForEach @(
        @{ Case = 'all listed steps'; Mode = 'Live'; Earlier = $true; Override = $false; Index = 64; Marker = 'A,B,C'; Expected = 'Y' },
        @{ Case = 'last step only'; Mode = 'Live'; Earlier = $false; Override = $false; Index = 64; Marker = 'A,B,C'; Expected = '' },
        @{ Case = 'Demo evidence'; Mode = 'Demo'; Earlier = $true; Override = $false; Index = 64; Marker = 'A,B,C'; Expected = '' },
        @{ Case = 'override with incomplete earlier work'; Mode = 'Live'; Earlier = $false; Override = $true; Index = 64; Marker = 'A,B,C'; Expected = '' },
        @{ Case = 'single explicit tracked action'; Mode = 'Live'; Earlier = $false; Override = $false; Index = 64; Marker = 'C'; Expected = 'Y' },
        @{ Case = 'explicitly mapped manual work completed'; Mode = 'Live'; Earlier = $true; Override = $false; Index = 80; Marker = 'H,I,J,K'; Expected = 'Y' },
        @{ Case = 'explicitly mapped manual work incomplete'; Mode = 'Live'; Earlier = $false; Override = $false; Index = 80; Marker = 'H,I,J,K'; Expected = '' },
        @{ Case = 'explicitly mapped manual Demo work'; Mode = 'Demo'; Earlier = $true; Override = $false; Index = 80; Marker = 'H,I,J,K'; Expected = '' },
        @{ Case = 'reject unknown action'; Mode = 'Live'; Earlier = $true; Override = $false; Index = 64; Marker = 'A,Z'; Expected = '' },
        @{ Case = 'reject duplicate letters'; Mode = 'Live'; Earlier = $true; Override = $false; Index = 64; Marker = 'C,C'; Expected = '' },
        @{ Case = 'reject marker mixed with title text'; Mode = 'Live'; Earlier = $true; Override = $false; Index = 0; Marker = 'C'; Expected = '' }
    ) {
        $marked = Join-Path $TestDrive ('marked-{0}.docx' -f [guid]::NewGuid().ToString('N'))
        [IO.File]::Copy($script:populationTemplates.BirthCertificate, $marked)
        $archive = [IO.Compression.ZipFile]::Open($marked, [IO.Compression.ZipArchiveMode]::Update)
        try {
            $entry = $archive.GetEntry('word/document.xml'); $reader = [IO.StreamReader]::new($entry.Open())
            try { $xml = [xml]$reader.ReadToEnd() } finally { $reader.Dispose() }
            # This disposable fixture tests one directive, independent of author markers in the source snapshot.
            foreach ($existingMarker in $xml.SelectNodes('//*[local-name()="p"]') | Where-Object { $_.InnerText -match '\{complete:' }) {
                foreach ($child in @($existingMarker.ChildNodes | Where-Object LocalName -NE 'pPr')) { $null = $existingMarker.RemoveChild($child) }
            }
            $paragraph = $xml.SelectNodes('//*[local-name()="p"]')[$Index]
            $namespace = 'http://schemas.openxmlformats.org/wordprocessingml/2006/main'
            foreach ($segment in @('{complete:', ('{0}}}' -f $Marker))) {
                $run = $xml.CreateElement('w', 'r', $namespace); $text = $xml.CreateElement('w', 't', $namespace)
                $text.InnerText = $segment; $null = $run.AppendChild($text); $null = $paragraph.AppendChild($run)
            }
            $entry.Delete(); $stream = $archive.CreateEntry('word/document.xml').Open()
            try { $xml.Save($stream) } finally { $stream.Dispose() }
        }
        finally { $archive.Dispose() }
        $script:populationRequest.TemplatePath = $marked
        $script:populationRequest.Job.Mode = $Mode
        $script:populationRequest.Job.IsAdministrativeOverride = $Override
        if ($Override) { $script:populationRequest.Job.OverrideReason = 'Incomplete earlier action' }
        foreach ($step in @('A', 'B', 'C', 'H', 'I', 'J', 'K')) { $script:populationRequest.Job.Steps[$step] = @{ TickEligible = $true } }
        $earlierStep = if ($Index -eq 80) { 'H' } else { 'A' }
        $script:populationRequest.Job.Steps[$earlierStep].TickEligible = $Earlier
        $result = Invoke-AutopilotDocumentPopulation -Request $script:populationRequest -DependencyRoot $script:populationDependencyRoot
        if ($Case.StartsWith('reject')) {
            $result.Status | Should -Be Failed
            Test-Path -LiteralPath $script:populationRequest.OutputPath | Should -BeFalse
            return
        }
        $result.Diagnostic | Should -BeExactly ''
        $result.Status | Should -Be Populated
        $result.Output.CompletionMarkerCount | Should -Be 1
        $parts = & $script:readPopulationXml $script:populationRequest.OutputPath
        $parts['word/document.xml'].SelectNodes('//*[local-name()="p"]')[$Index].InnerText | Should -BeExactly $Expected
        $parts['word/document.xml'].DocumentElement.InnerText | Should -Not -Match '\{complete:'
    }
    It 'evaluates native checklist author markers and removes their visible directive: <Case>' -ForEach @(
        @{ Case = 'complete listed group'; Earlier = $true; Mode = 'Live'; Expected = '1' },
        @{ Case = 'last action only'; Earlier = $false; Mode = 'Live'; Expected = '0' },
        @{ Case = 'Demo cannot certify'; Earlier = $true; Mode = 'Demo'; Expected = '0' }
    ) {
        $marked = Join-Path $TestDrive ('checklist-marked-{0}.docx' -f [guid]::NewGuid().ToString('N'))
        [IO.File]::Copy($script:populationTemplates.Checklist, $marked)
        $archive = [IO.Compression.ZipFile]::Open($marked, [IO.Compression.ZipArchiveMode]::Update)
        try {
            $entry = $archive.GetEntry('word/document.xml'); $reader = [IO.StreamReader]::new($entry.Open())
            try { $xml = [xml]$reader.ReadToEnd() } finally { $reader.Dispose() }
            $control = $xml.SelectSingleNode('//*[local-name()="sdt"][*[local-name()="sdtPr"]/*[local-name()="id"]/@*[local-name()="val"]="1621038395"]')
            $cell = $control.SelectSingleNode('ancestor::*[local-name()="tr"][1]/*[local-name()="tc"][last()]')
            $namespace = 'http://schemas.openxmlformats.org/wordprocessingml/2006/main'
            $paragraph = $xml.CreateElement('w', 'p', $namespace)
            foreach ($segment in @('{complete:A,', 'B}')) {
                $run = $xml.CreateElement('w', 'r', $namespace); $text = $xml.CreateElement('w', 't', $namespace)
                $text.InnerText = $segment; $null = $run.AppendChild($text); $null = $paragraph.AppendChild($run)
            }
            $null = $cell.AppendChild($paragraph)
            $entry.Delete(); $stream = $archive.CreateEntry('word/document.xml').Open()
            try { $xml.Save($stream) } finally { $stream.Dispose() }
        }
        finally { $archive.Dispose() }
        $script:populationRequest.TemplatePath = $marked
        $script:populationRequest.Profile = Get-AutopilotDocumentTemplateProfile -DocumentType Checklist
        $script:populationRequest.Job.Mode = $Mode
        $script:populationRequest.Job.Steps.A = @{ TickEligible = $Earlier }
        $script:populationRequest.Job.Steps.B = @{ TickEligible = $true }
        $result = Invoke-AutopilotDocumentPopulation -Request $script:populationRequest -DependencyRoot $script:populationDependencyRoot
        $result.Diagnostic | Should -BeExactly ''
        $result.Status | Should -Be Populated
        $result.Output.CompletionMarkerCount | Should -Be 1
        $parts = & $script:readPopulationXml $script:populationRequest.OutputPath
        $outputControl = $parts['word/document.xml'].SelectSingleNode('//*[local-name()="sdt"][*[local-name()="sdtPr"]/*[local-name()="id"]/@*[local-name()="val"]="1621038395"]')
        $outputControl.SelectSingleNode('.//*[local-name()="checked"]/@*[local-name()="val"]').Value | Should -BeExactly $Expected
        $parts['word/document.xml'].DocumentElement.InnerText | Should -Not -Match '\{complete:'
    }
    It 'leaves a certificate group blank when its last action succeeds but earlier work is incomplete' {
        $script:populationRequest.Job.Mode = 'Live'
        $script:populationRequest.Job.IsAdministrativeOverride = $true
        $script:populationRequest.Job.OverrideReason = 'Incomplete earlier actions'
        $script:populationRequest.Job.Steps = @{ A = @{ TickEligible = $false }; B = @{ TickEligible = $true }; C = @{ TickEligible = $true }; G = @{ TickEligible = $true }; O = @{ TickEligible = $true } }
        $result = Invoke-AutopilotDocumentPopulation -Request $script:populationRequest -DependencyRoot $script:populationDependencyRoot
        $result.Status | Should -Be Populated
        $parts = & $script:readPopulationXml $script:populationRequest.OutputPath
        $paragraphs = $parts['word/document.xml'].SelectNodes('//*[local-name()="p"]')
        $paragraphs[64].InnerText | Should -BeExactly ''
        $paragraphs[73].InnerText | Should -BeExactly ''
        $paragraphs[98].InnerText | Should -BeExactly 'Y'
    }
    It 'leaves certificate Demo groups blank even when all eligibility flags are true' {
        foreach ($step in @('A', 'B', 'C', 'D', 'E', 'F', 'G', 'O')) { $script:populationRequest.Job.Steps[$step] = @{ TickEligible = $true } }
        $result = Invoke-AutopilotDocumentPopulation -Request $script:populationRequest -DependencyRoot $script:populationDependencyRoot
        $result.Status | Should -Be Populated
        $parts = & $script:readPopulationXml $script:populationRequest.OutputPath
        $paragraphs = $parts['word/document.xml'].SelectNodes('//*[local-name()="p"]')
        foreach ($index in @(64, 67, 73, 80, 95, 98, 101, 104)) { $paragraphs[$index].InnerText | Should -BeExactly '' }
    }
    It 'rejects a certificate group whose reviewed row label does not match' {
        ($script:populationRequest.Profile.Bindings | Where-Object Kind -EQ GroupResult | Select-Object -First 1).GuideStepText = 'wrong row'
        $result = Invoke-AutopilotDocumentPopulation -Request $script:populationRequest -DependencyRoot $script:populationDependencyRoot
        $result.Status | Should -Be Failed
        $result.Diagnostic | Should -Match 'reviewed guide-step label|missing or ambiguous GroupResult target'
    }
    It 'refuses markers crossing a tab boundary' {
        $script:populationRequest.TemplatePath = $script:syntheticPopulationTemplate
        $script:populationRequest.Profile = & $script:createSyntheticPopulationProfile
        $script:populationRequest.Job.Fields.Location = 'Synthetic location'
        $script:populationRequest.Profile.Bindings += @{ Kind = 'Literal'; Part = '/word/document.xml'; Marker = '{cross}'; Field = 'Location'; Required = $true; ExpectedCount = 1 }
        $result = Invoke-AutopilotDocumentPopulation -Request $script:populationRequest -DependencyRoot $script:populationDependencyRoot
        $result.Status | Should -Be Failed
        $result.Diagnostic | Should -Match 'cardinality differs'
    }
    It 'refuses overlapping literal mappings before publication' {
        $script:populationRequest.TemplatePath = $script:syntheticPopulationTemplate
        $script:populationRequest.Profile = & $script:createSyntheticPopulationProfile
        $script:populationRequest.Job.Fields.Location = 'Synthetic location'
        $script:populationRequest.Profile.Bindings += @{ Kind = 'Literal'; Part = '/word/document.xml'; Marker = '{x'; Field = 'Location'; Required = $true; ExpectedCount = 3 }
        $result = Invoke-AutopilotDocumentPopulation -Request $script:populationRequest -DependencyRoot $script:populationDependencyRoot
        $result.Status | Should -Be Failed
        $result.Diagnostic | Should -Match 'Overlapping literal'
        Test-Path -LiteralPath $script:populationRequest.OutputPath | Should -BeFalse
    }
    It 'preserves all checklist object/media bytes and reports only the approved source warnings' {
        $script:populationRequest.Profile = Get-AutopilotDocumentTemplateProfile -DocumentType Checklist
        $script:populationRequest.TemplatePath = $script:populationTemplates.Checklist
        $result = Invoke-AutopilotDocumentPopulation -Request $script:populationRequest -DependencyRoot $script:populationDependencyRoot
        $result.Status | Should -Be Populated
        $result.Output.ValidationWarnings.Count | Should -Be 3
        $sourceZip = [IO.Compression.ZipFile]::OpenRead($script:populationRequest.TemplatePath)
        $outputZip = [IO.Compression.ZipFile]::OpenRead($script:populationRequest.OutputPath)
        try {
            foreach ($entry in $sourceZip.Entries | Where-Object { $_.FullName -match '^word/(media|embeddings)/' -and -not $_.FullName.EndsWith('/') }) {
                $copied = $outputZip.GetEntry($entry.FullName); $copied | Should -Not -BeNullOrEmpty
                $sourceStream = $entry.Open(); $outputStream = $copied.Open(); $sha = [Security.Cryptography.SHA256]::Create()
                try { [Convert]::ToBase64String($sha.ComputeHash($outputStream)) | Should -BeExactly ([Convert]::ToBase64String($sha.ComputeHash($sourceStream))) }
                finally { $sha.Dispose(); $sourceStream.Dispose(); $outputStream.Dispose() }
            }
        }
        finally { $sourceZip.Dispose(); $outputZip.Dispose() }
        $parts = & $script:readPopulationXml $script:populationRequest.OutputPath
        $parts['word/document.xml'].SelectNodes('//*[local-name()="OLEObject" and @ProgID="PBrush"]').Count | Should -Be 1
        $parts['word/_rels/document.xml.rels'].SelectNodes('//*[local-name()="Relationship" and @Id="rId29" and @Target="embeddings/oleObject1.bin"]').Count | Should -Be 1
        $sourceParts = & $script:readPopulationXml $script:populationRequest.TemplatePath
        $parts['word/document.xml'].SelectSingleNode('//*[local-name()="p"][1]').InnerText | Should -BeExactly $sourceParts['word/document.xml'].SelectSingleNode('//*[local-name()="p"][1]').InnerText
        $footer = $parts['word/footer1.xml']
        $footer.DocumentElement.InnerText | Should -Match 'DRAFT - NOT APPROVED - DEMO - NOT LIVE'
        $labelRun = $footer.SelectSingleNode('//*[local-name()="r" and contains(.,"DRAFT")]')
        $labelRun.SelectNodes('./*[local-name()="tab"]').Count | Should -Be 2
        $labelRun.SelectSingleNode('./*[local-name()="rPr"]/*[local-name()="sz"]').GetAttribute('val', 'http://schemas.openxmlformats.org/wordprocessingml/2006/main') | Should -BeExactly '12'
        $footer.SelectNodes('//*[local-name()="instrText" and contains(.,"PAGE")]').Count | Should -Be 1
    }
    It 'ticks only wholly eligible Live groups and leaves unknown or incomplete actions clear' {
        $script:populationRequest.Profile = Get-AutopilotDocumentTemplateProfile -DocumentType Checklist
        $script:populationRequest.TemplatePath = $script:populationTemplates.Checklist
        $script:populationRequest.Job.Mode = 'Live'
        $script:populationRequest.Job.Steps = @{ A = @{ TickEligible = $true }; B = @{ TickEligible = $true }; C = @{ TickEligible = $false } }
        $result = Invoke-AutopilotDocumentPopulation -Request $script:populationRequest -DependencyRoot $script:populationDependencyRoot
        $result.Status | Should -Be Populated
        $parts = & $script:readPopulationXml $script:populationRequest.OutputPath
        $parts['word/document.xml'].SelectNodes('//*[local-name()="checkbox"]/*[local-name()="checked" and @*[local-name()="val"]="1"]').Count | Should -Be 1
    }
    It 'does not tick Demo evidence even when supplied eligibility is true' {
        $script:populationRequest.Profile = Get-AutopilotDocumentTemplateProfile -DocumentType Checklist
        $script:populationRequest.TemplatePath = $script:populationTemplates.Checklist
        $script:populationRequest.Job.Steps = @{ A = @{ TickEligible = $true }; B = @{ TickEligible = $true } }
        $result = Invoke-AutopilotDocumentPopulation -Request $script:populationRequest -DependencyRoot $script:populationDependencyRoot
        $result.Status | Should -Be Populated
        $parts = & $script:readPopulationXml $script:populationRequest.OutputPath
        $parts['word/document.xml'].SelectNodes('//*[local-name()="checkbox"]/*[local-name()="checked" and @*[local-name()="val"]="1"]').Count | Should -Be 0
    }
    It 'omits only unreadable barcodes while retaining text and unchanged table and section dimensions' {
        foreach ($binding in $script:populationRequest.Profile.Bindings | Where-Object Kind -EQ Barcode) { $binding.HeightTwips = 200 }
        $result = Invoke-AutopilotDocumentPopulation -Request $script:populationRequest -DependencyRoot $script:populationDependencyRoot
        $result.Status | Should -Be Populated
        $result.Output.BarcodeOmissions.Count | Should -Be 4
        $before = & $script:readPopulationXml $script:populationRequest.TemplatePath
        $after = & $script:readPopulationXml $script:populationRequest.OutputPath
        foreach ($name in @('tblPr', 'trPr', 'tcPr', 'sectPr', 'br')) {
            $selector = '//*[local-name()="{0}"]' -f $name
            $snapshots = foreach ($parts in @($before, $after)) {
                $nodes = foreach ($root in $parts['word/document.xml'].SelectNodes($selector)) {
                    foreach ($node in $root.SelectNodes('descendant-or-self::*')) {
                        $attributes = @($node.Attributes | Where-Object NamespaceURI -NE 'http://www.w3.org/2000/xmlns/' | ForEach-Object { '{0}|{1}|{2}' -f $_.NamespaceURI, $_.LocalName, $_.Value } | Sort-Object)
                        [ordered]@{ Name = $node.LocalName; Namespace = $node.NamespaceURI; Attributes = $attributes } | ConvertTo-Json -Compress
                    }
                }
                $nodes -join "`n"
            }
            $snapshots[1] | Should -BeExactly $snapshots[0]
        }
        foreach ($field in @('SerialNumberOrServiceTag', 'ConfigurationItem', 'IntuneHostName', 'EthernetMacAddress')) { $after['word/document.xml'].DocumentElement.InnerText | Should -Match ([regex]::Escape($script:populationRequest.Job.Fields[$field])) }
    }
    It 'renders the birth certificate override conditional only for DO: <Case>' -ForEach @(
        @{ Case = 'normal D without a reason'; Override = $false; Reason = ''; Expected = '' },
        @{ Case = 'normal D ignores a stray reason'; Override = $false; Reason = 'This must never appear on normal dispatch'; Expected = '' },
        @{ Case = 'DO includes the exact saved reason'; Override = $true; Reason = 'Synthetic missing work: H pending & device awaiting sign-in'; Expected = 'Incomplete steps overridden: Synthetic missing work: H pending & device awaiting sign-in' }
    ) {
        $script:populationRequest.Job.Mode = 'Live'
        $script:populationRequest.Job.IsAdministrativeOverride = $Override
        $script:populationRequest.Job.OverrideReason = $Reason
        $result = Invoke-AutopilotDocumentPopulation -Request $script:populationRequest -DependencyRoot $script:populationDependencyRoot
        $result.Status | Should -Be Populated
        $parts = & $script:readPopulationXml $script:populationRequest.OutputPath
        $paragraphs = $parts['word/document.xml'].SelectNodes('//*[local-name()="p"]')
        $paragraphs[35].InnerText | Should -BeExactly $Expected
        foreach ($part in $parts.Values) {
            $part.DocumentElement.InnerText | Should -Not -Match 'dispatch_override_reason|\{If |\{End if '
            if (-not $Override) {
                $part.DocumentElement.InnerText | Should -Not -Match 'Incomplete steps overridden'
                if ($Reason) { $part.DocumentElement.InnerText | Should -Not -Match ([regex]::Escape($Reason)) }
            }
        }
        foreach ($index in @(64, 67, 73, 80, 95, 98, 101, 104)) { $paragraphs[$index].InnerText | Should -BeExactly '' }
    }
    It 'refuses invalid barcode payloads instead of treating corruption as an omission' {
        $script:populationRequest.Job.Fields.SerialNumberOrServiceTag = 'A' * 81
        $result = Invoke-AutopilotDocumentPopulation -Request $script:populationRequest -DependencyRoot $script:populationDependencyRoot
        $result.Status | Should -Be Failed
        $result.Diagnostic | Should -Match '1-80 printable ASCII'
        Test-Path -LiteralPath $script:populationRequest.OutputPath | Should -BeFalse
    }
    It 'refuses review mappings for unlabelled Live publication' {
        $script:populationRequest.ReviewOnly = $false
        $result = Invoke-AutopilotDocumentPopulation -Request $script:populationRequest -DependencyRoot $script:populationDependencyRoot
        $result.Status | Should -Be Failed
        $result.Diagnostic | Should -Match 'not approved'
    }
    It 'refuses missing approved required field <Field> before publishing' -ForEach @(
        @{ Field = 'ConfigurationItem' }, @{ Field = 'TechnicianName' },
        @{ Field = 'AssignedUserName' }, @{ Field = 'AssignedUserFullName' }
    ) {
        $script:populationRequest.Job.Fields[$Field] = ''
        $result = Invoke-AutopilotDocumentPopulation -Request $script:populationRequest -DependencyRoot $script:populationDependencyRoot
        $result.Status | Should -Be Failed
        $result.Diagnostic | Should -Match ('Required document field is missing: {0}' -f $Field)
        Test-Path -LiteralPath $script:populationRequest.OutputPath | Should -BeFalse
    }
    It 'allows an explicitly non-required assigned user without inventing either placeholder value' {
        $script:populationRequest.Job.AssignedUserRequired = $false
        $script:populationRequest.Job.Fields.AssignedUserName = ''
        $script:populationRequest.Job.Fields.AssignedUserFullName = ''
        $result = Invoke-AutopilotDocumentPopulation -Request $script:populationRequest -DependencyRoot $script:populationDependencyRoot
        $result.Status | Should -Be Populated
        $parts = & $script:readPopulationXml $script:populationRequest.OutputPath
        $parts['word/document.xml'].SelectNodes('//*[local-name()="p"]')[15].InnerText.Trim() | Should -BeExactly ''
    }
    It 'rejects a last-action trigger that does not correspond to the whole reviewed group' {
        ($script:populationRequest.Profile.Bindings | Where-Object Kind -EQ GroupResult | Select-Object -First 1).TriggerStepId = 'A'
        $result = Invoke-AutopilotDocumentPopulation -Request $script:populationRequest -DependencyRoot $script:populationDependencyRoot
        $result.Status | Should -Be Failed
        $result.Diagnostic | Should -Match 'last mapped action'
    }
    It 'refuses an unknown profile source fingerprint mismatch' {
        $script:populationRequest.Profile.ProfileId = 'Unknown-v1'
        $script:populationRequest.Profile.TemplateSHA256 = 'A' * 64
        $result = Invoke-AutopilotDocumentPopulation -Request $script:populationRequest -DependencyRoot $script:populationDependencyRoot
        $result.Status | Should -Be Failed
        $result.Diagnostic | Should -Match 'fingerprint differs'
    }
    It 'does not extend approved source warnings to an unknown profile or caller exception list' {
        $modified = Join-Path $TestDrive 'synthetic-changed-checklist.docx'
        [IO.File]::Copy($script:populationTemplates.Checklist, $modified)
        $archive = [IO.Compression.ZipFile]::Open($modified, [IO.Compression.ZipArchiveMode]::Update)
        try { $null = $archive.CreateEntry('custom/review.txt') } finally { $archive.Dispose() }
        $script:populationRequest.TemplatePath = $modified
        $script:populationRequest.Profile = Get-AutopilotDocumentTemplateProfile -DocumentType Checklist
        $script:populationRequest.Profile.ProfileId = 'UnknownChecklist-v1'
        $script:populationRequest.Profile.TemplateSHA256 = (Get-FileHash -LiteralPath $modified -Algorithm SHA256).Hash
        $result = Invoke-AutopilotDocumentPopulation -Request $script:populationRequest -DependencyRoot $script:populationDependencyRoot
        $result.Status | Should -Be Failed
        $result.Diagnostic | Should -Match '3 actual, 0 allowed'
    }
    It 'refuses an ambiguous duplicate paragraph binding' {
        $script:populationRequest.Profile.Bindings += $script:populationRequest.Profile.Bindings[1]
        $result = Invoke-AutopilotDocumentPopulation -Request $script:populationRequest -DependencyRoot $script:populationDependencyRoot
        $result.Status | Should -Be Failed
        $result.Diagnostic | Should -Match 'Paragraph binding differs|Overlapping'
    }
    It 'refuses a missing required canonical value' {
        $script:populationRequest.Job.Fields.SerialNumberOrServiceTag = ''
        $result = Invoke-AutopilotDocumentPopulation -Request $script:populationRequest -DependencyRoot $script:populationDependencyRoot
        $result.Status | Should -Be Failed
        $result.Diagnostic | Should -Match 'Required document field is missing'
    }
    It 'never replaces an occupied output' {
        [IO.File]::WriteAllText($script:populationRequest.OutputPath, 'synthetic existing output')
        $result = Invoke-AutopilotDocumentPopulation -Request $script:populationRequest -DependencyRoot $script:populationDependencyRoot
        $result.Status | Should -Be Failed
        [IO.File]::ReadAllText($script:populationRequest.OutputPath) | Should -BeExactly 'synthetic existing output'
    }
    It 'rejects a macro package before SDK editing or publication' {
        $modified = Join-Path $TestDrive 'synthetic-macro.docx'
        [IO.File]::Copy($script:populationRequest.TemplatePath, $modified)
        $archive = [IO.Compression.ZipFile]::Open($modified, [IO.Compression.ZipArchiveMode]::Update)
        try { $entry = $archive.CreateEntry('word/vbaProject.bin'); $stream = $entry.Open(); try { $stream.WriteByte(1) } finally { $stream.Dispose() } } finally { $archive.Dispose() }
        $script:populationRequest.TemplatePath = $modified
        $script:populationRequest.Profile.TemplateSHA256 = (Get-FileHash -LiteralPath $modified -Algorithm SHA256).Hash
        $result = Invoke-AutopilotDocumentPopulation -Request $script:populationRequest -DependencyRoot $script:populationDependencyRoot
        $result.Status | Should -Be Failed
        $result.Diagnostic | Should -Match 'Unsafe, duplicate or excessive'
        Test-Path -LiteralPath $script:populationRequest.OutputPath | Should -BeFalse
    }
}
Describe 'Opaque document object preservation' {
    It 'snapshots embedded bytes and relationships without loading document libraries' {
        InModuleScope AutopilotExpress.Documents {
            Add-Type -AssemblyName System.IO.Compression
            $memory = [IO.MemoryStream]::new()
            try {
                $zip = [IO.Compression.ZipArchive]::new($memory, [IO.Compression.ZipArchiveMode]::Create, $true)
                try {
                    $contents = [ordered]@{
                        'word/embeddings/oleObject1.bin' = 'opaque test bytes'
                        'word/media/image1.png'          = 'opaque preview bytes'
                        'word/document.xml'              = '<w:document xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main" xmlns:o="urn:schemas-microsoft-com:office:office"><o:OLEObject Type="Embed" ProgID="PBrush" /></w:document>'
                        'word/_rels/document.xml.rels'   = '<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships"><Relationship Id="rId29" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/oleObject" Target="embeddings/oleObject1.bin" /></Relationships>'
                    }
                    foreach ($name in $contents.Keys) {
                        $entry = $zip.CreateEntry($name); $stream = $entry.Open()
                        try { $bytes = [Text.Encoding]::UTF8.GetBytes($contents[$name]); $stream.Write($bytes, 0, $bytes.Length) } finally { $stream.Dispose() }
                    }
                }
                finally { $zip.Dispose() }
                $snapshot = Get-AutopilotDocumentPreservedContent -Stream $memory
                $snapshot.Assets.Count | Should -Be 2
                $snapshot.Assets['word/embeddings/oleObject1.bin'] | Should -Match '^[A-F0-9]{64}$'
                $snapshot.Relationships.Count | Should -Be 1
                $snapshot.Objects.Count | Should -Be 1
                $snapshot.Objects[0] | Should -Match 'PBrush'
                $memory.Position | Should -Be 0
            }
            finally { $memory.Dispose() }
        }
    }
}
Describe 'Document dependency lock and host detection' {
    It 'pins the complete three-package framework closure without Graph packages' {
        $manifest = Get-AutopilotDocumentDependencyManifest
        $manifest.Packages.Count | Should -Be 3
        $manifest.Source | Should -BeExactly 'https://api.nuget.org/v3-flatcontainer'
        $manifest.WorkerRuntime | Should -BeExactly WindowsPowerShell51-NetFramework48
        foreach ($package in $manifest.Packages) {
            $package.Id | Should -Not -Match 'Graph|Kiota'
            [Convert]::FromBase64String($package.ArchiveSHA512).Length | Should -Be 64
            $package.AssetSHA256 | Should -Match '^[A-F0-9]{64}$'
            foreach ($dependency in $package.Dependencies) { $manifest.Packages.Id | Should -Contain $dependency }
        }
        $manifest.Packages[0].Version = 'changed'
        (Get-AutopilotDocumentDependencyManifest).Packages[0].Version | Should -BeExactly '3.3.0'
    }
    It 'loads no document DLL or Word COM during host detection' {
        $before = @([AppDomain]::CurrentDomain.GetAssemblies().FullName)
        $hostState = Get-AutopilotDocumentHostCapability
        $hostState.WorkerAvailable | Should -BeOfType ([bool])
        $hostState.WordRegistrationDetected | Should -BeOfType ([bool])
        $hostState.WordActivationVerified | Should -BeFalse
        $loaded = @([AppDomain]::CurrentDomain.GetAssemblies() | Where-Object { $_.FullName -notin $before -and $_.GetName().Name -match 'DocumentFormat.OpenXml|^zxing$' })
        $loaded.Count | Should -Be 0
    }
}
Describe 'Document dependency acquisition safety' {
    BeforeEach {
        $script:dependencyCache = Join-Path $TestDrive ([guid]::NewGuid().ToString('N'))
        Mock Invoke-WebRequest -ModuleName AutopilotExpress.Documents { throw 'Offline test; network is forbidden.' }
        Mock Read-Host -ModuleName AutopilotExpress.Documents { throw 'Unexpected interactive prompt.' }
    }
    It 'reports a missing bundle without creating the root' {
        (Test-AutopilotDocumentDependencyBundle -DependencyRoot $dependencyCache).Status | Should -BeExactly Missing
        Test-Path -LiteralPath $dependencyCache | Should -BeFalse
    }
    It 'does not prompt, download or create directories for <Decision>' -ForEach @(
        @{ Decision = 'Declined'; Expected = 'Declined' }, @{ Decision = 'NotGranted'; Expected = 'ConsentRequired' }
    ) {
        (Install-AutopilotDocumentDependencyBundle -DependencyRoot $dependencyCache -Consent $Decision -NoPrompts).Status | Should -BeExactly $Expected
        Test-Path -LiteralPath $dependencyCache | Should -BeFalse
        Should -Invoke Read-Host -ModuleName AutopilotExpress.Documents -Times 0
        Should -Invoke Invoke-WebRequest -ModuleName AutopilotExpress.Documents -Times 0
    }
    It 'does not acquire anything under WhatIf' {
        (Install-AutopilotDocumentDependencyBundle -DependencyRoot $dependencyCache -Consent Approved -WhatIf).Status | Should -BeExactly WhatIf
        Test-Path -LiteralPath $dependencyCache | Should -BeFalse
        Should -Invoke Read-Host -ModuleName AutopilotExpress.Documents -Times 0
        Should -Invoke Invoke-WebRequest -ModuleName AutopilotExpress.Documents -Times 0
    }
    It 'rejects the nonlocal or unsafe root <BadPath>' -ForEach @(
        @{ BadPath = '\\server\share' }, @{ BadPath = 'relative/cache' }, @{ BadPath = 'C:\cache:stream' }, @{ BadPath = 'C:\cache\*' }
    ) {
        (Install-AutopilotDocumentDependencyBundle -DependencyRoot $BadPath -NoPrompts).Status | Should -BeExactly Failed
        Should -Invoke Invoke-WebRequest -ModuleName AutopilotExpress.Documents -Times 0
    }
    It 'preserves an invalid existing bundle instead of overwriting or downloading' {
        $bundle = Join-Path $dependencyCache (Get-AutopilotDocumentDependencyManifest).BundleId
        $null = New-Item -ItemType Directory -Path $bundle -Force
        [IO.File]::WriteAllText((Join-Path $bundle 'owner-note.txt'), 'preserve')
        (Install-AutopilotDocumentDependencyBundle -DependencyRoot $dependencyCache -Consent Approved -NoPrompts).Status | Should -BeExactly InvalidExistingBundle
        [IO.File]::ReadAllText((Join-Path $bundle 'owner-note.txt')) | Should -BeExactly preserve
        Should -Invoke Invoke-WebRequest -ModuleName AutopilotExpress.Documents -Times 0
    }
    It 'does not bypass a concurrent acquisition lock' {
        $null = New-Item -ItemType Directory -Path $dependencyCache
        $handle = [IO.File]::Open((Join-Path $dependencyCache 'acquire.lock'), [IO.FileMode]::OpenOrCreate, [IO.FileAccess]::ReadWrite, [IO.FileShare]::None)
        try { (Install-AutopilotDocumentDependencyBundle -DependencyRoot $dependencyCache -Consent Approved -NoPrompts).Status | Should -BeExactly Failed }
        finally { $handle.Dispose() }
        Test-Path -LiteralPath (Join-Path $dependencyCache (Get-AutopilotDocumentDependencyManifest).BundleId) | Should -BeFalse
        Should -Invoke Invoke-WebRequest -ModuleName AutopilotExpress.Documents -Times 0
    }
    It 'retries a failed download only twice and never publishes partial content' {
        $result = Install-AutopilotDocumentDependencyBundle -DependencyRoot $dependencyCache -Consent Approved -NoPrompts
        $result.Status | Should -BeExactly Failed
        Test-Path -LiteralPath (Join-Path $dependencyCache (Get-AutopilotDocumentDependencyManifest).BundleId) | Should -BeFalse
        Should -Invoke Invoke-WebRequest -ModuleName AutopilotExpress.Documents -Times 2 -Exactly -ParameterFilter { $TimeoutSec -eq 60 -and $MaximumRedirection -eq 0 -and $Uri -like 'https://api.nuget.org/v3-flatcontainer/*' }
    }
    It 'declines mixed-case No after disclosing the default without writes' {
        Mock Read-Host -ModuleName AutopilotExpress.Documents { 'nO' }
        (Install-AutopilotDocumentDependencyBundle -DependencyRoot $dependencyCache).Status | Should -BeExactly Declined
        Test-Path -LiteralPath $dependencyCache | Should -BeFalse
        Should -Invoke Read-Host -ModuleName AutopilotExpress.Documents -Times 1 -Exactly -ParameterFilter { $Prompt -like '*Default: Yes*' }
        Should -Invoke Invoke-WebRequest -ModuleName AutopilotExpress.Documents -Times 0
    }
    It 'treats Enter as consent only after disclosure and still fails safely offline' {
        Mock Read-Host -ModuleName AutopilotExpress.Documents { '' }
        (Install-AutopilotDocumentDependencyBundle -DependencyRoot $dependencyCache).Status | Should -BeExactly Failed
        Should -Invoke Read-Host -ModuleName AutopilotExpress.Documents -Times 1 -Exactly
        Should -Invoke Invoke-WebRequest -ModuleName AutopilotExpress.Documents -Times 2 -Exactly
    }
    It 'rejects corrupted offline archives before publication or DLL extraction' {
        $source = Join-Path $dependencyCache 'source'
        $null = New-Item -ItemType Directory -Path $source -Force
        [IO.File]::WriteAllText((Join-Path $source 'documentformat.openxml.framework.3.3.0.nupkg'), 'not a valid package')
        $result = Install-AutopilotDocumentDependencyBundle -DependencyRoot $dependencyCache -Consent Approved -NoPrompts -ArchiveDirectory $source
        $result.Status | Should -BeExactly Failed
        $result.Diagnostic | Should -Match 'SHA-512 mismatch'
        Test-Path -LiteralPath $result.BundlePath | Should -BeFalse
        @(Get-ChildItem -LiteralPath $dependencyCache -Filter '*.dll' -Recurse).Count | Should -Be 0
        Should -Invoke Invoke-WebRequest -ModuleName AutopilotExpress.Documents -Times 0
    }
    It 'rejects a reparse-point ancestor without touching the target' {
        $target = Join-Path $TestDrive 'junction-target'
        $link = Join-Path $TestDrive 'junction-link'
        $null = New-Item -ItemType Directory -Path $target -Force
        $null = New-Item -ItemType Directory -Path $link -Force
        Mock Get-Item -ModuleName AutopilotExpress.Documents {
            [pscustomobject]@{
                FullName = $LiteralPath
                Attributes = [IO.FileAttributes]::Directory -bor [IO.FileAttributes]::ReparsePoint
                PSIsContainer = $true
            }
        } -ParameterFilter { $LiteralPath -like '*junction-link' }
        (Install-AutopilotDocumentDependencyBundle -DependencyRoot (Join-Path $link 'cache') -Consent Approved -NoPrompts).Status | Should -BeExactly Failed
        @(Get-ChildItem -LiteralPath $target -Force).Count | Should -Be 0
        Should -Invoke Get-Item -ModuleName AutopilotExpress.Documents -Times 1 -Exactly -ParameterFilter { $LiteralPath -like '*junction-link' }
    }
}
Describe 'Document prerequisite opt-in and isolation boundaries' {
    BeforeEach {
        $script:probeSettings = Resolve-AutopilotDocumentSettings -ScriptRoot $env:AutopilotExpressRoot -LocalApplicationData $TestDrive
        Mock Get-AutopilotDocumentHostCapability -ModuleName AutopilotExpress.Documents { [ordered]@{ WorkerAvailable = $true; WordRegistrationDetected = $true } }
        Mock Install-AutopilotDocumentDependencyBundle -ModuleName AutopilotExpress.Documents { [ordered]@{ Status = 'Verified'; Diagnostic = '' } }
        Mock Invoke-AutopilotDocumentDependencySelfTest -ModuleName AutopilotExpress.Documents { [ordered]@{ Ready = $true; Status = 'Passed'; Diagnostic = '' } }
    }
    It 'does not inspect the host, cache or network when outputs are disabled' {
        (Test-AutopilotDocumentPrerequisite -Settings $probeSettings).Status | Should -BeExactly Disabled
        Should -Invoke Get-AutopilotDocumentHostCapability -ModuleName AutopilotExpress.Documents -Times 0
        Should -Invoke Install-AutopilotDocumentDependencyBundle -ModuleName AutopilotExpress.Documents -Times 0
        Should -Invoke Invoke-AutopilotDocumentDependencySelfTest -ModuleName AutopilotExpress.Documents -Times 0
        Test-Path -LiteralPath $probeSettings.Values.LocalRoot | Should -BeFalse
    }
    It 'suppresses explicitly Disabled profiles even when enable flags are true' {
        $probeSettings.Values.BirthCertificateEnabled = $true; $probeSettings.Values.ChecklistEnabled = $true
        $probeSettings.Values.BirthCertificateMode = 'Disabled'; $probeSettings.Values.ChecklistMode = 'Disabled'
        (Test-AutopilotDocumentPrerequisite -Settings $probeSettings).Status | Should -BeExactly Disabled
        Should -Invoke Get-AutopilotDocumentHostCapability -ModuleName AutopilotExpress.Documents -Times 0
        Should -Invoke Install-AutopilotDocumentDependencyBundle -ModuleName AutopilotExpress.Documents -Times 0
    }
    It 'keeps an active profile independent of the other explicitly Disabled profile' {
        $probeSettings.Values.BirthCertificateEnabled = $true; $probeSettings.Values.ChecklistEnabled = $true
        $probeSettings.Values.BirthCertificateMode = 'Disabled'
        (Test-AutopilotDocumentPrerequisite -Settings $probeSettings -Consent Approved -NoPrompts).Ready | Should -BeTrue
        Should -Invoke Invoke-AutopilotDocumentDependencySelfTest -ModuleName AutopilotExpress.Documents -Times 1 -Exactly
    }
    It 'does not inspect or acquire prerequisites under WhatIf' {
        $probeSettings.Values.ChecklistEnabled = $true
        (Test-AutopilotDocumentPrerequisite -Settings $probeSettings -WhatIf).Status | Should -BeExactly WhatIf
        Should -Invoke Get-AutopilotDocumentHostCapability -ModuleName AutopilotExpress.Documents -Times 0
        Should -Invoke Install-AutopilotDocumentDependencyBundle -ModuleName AutopilotExpress.Documents -Times 0
    }
    It 'localises missing <Missing> without acquisition or worker launch' -ForEach @(
        @{ Missing = 'Word'; Expected = 'WordUnavailable' }, @{ Missing = 'Worker'; Expected = 'WorkerUnavailable' }
    ) {
        $probeSettings.Values.ChecklistEnabled = $true
        if ($Missing -eq 'Word') { Mock Get-AutopilotDocumentHostCapability -ModuleName AutopilotExpress.Documents { @{ WorkerAvailable = $true; WordRegistrationDetected = $false } } }
        else { Mock Get-AutopilotDocumentHostCapability -ModuleName AutopilotExpress.Documents { @{ WorkerAvailable = $false; WordRegistrationDetected = $true } } }
        (Test-AutopilotDocumentPrerequisite -Settings $probeSettings).Status | Should -BeExactly $Expected
        Should -Invoke Install-AutopilotDocumentDependencyBundle -ModuleName AutopilotExpress.Documents -Times 0
        Should -Invoke Invoke-AutopilotDocumentDependencySelfTest -ModuleName AutopilotExpress.Documents -Times 0
    }
    It 'passes the explicit consent and approved deadline without persisting settings' {
        $probeSettings.Values.BirthCertificateEnabled = $true
        (Test-AutopilotDocumentPrerequisite -Settings $probeSettings -Consent Approved -NoPrompts).Ready | Should -BeTrue
        Should -Invoke Install-AutopilotDocumentDependencyBundle -ModuleName AutopilotExpress.Documents -Times 1 -Exactly -ParameterFilter { $Consent -eq 'Approved' -and $NoPrompts -and $DependencyRoot -like '*dependencies' }
        Should -Invoke Invoke-AutopilotDocumentDependencySelfTest -ModuleName AutopilotExpress.Documents -Times 1 -Exactly -ParameterFilter { $TimeoutSeconds -eq 60 }
    }
    It 'preserves failure status <Failure> and does not run libraries after acquisition fails' -ForEach @(
        @{ Failure = 'ConsentRequired' }, @{ Failure = 'Declined' }, @{ Failure = 'InvalidExistingBundle' }
    ) {
        $probeSettings.Values.ChecklistEnabled = $true
        Mock Install-AutopilotDocumentDependencyBundle -ModuleName AutopilotExpress.Documents { @{ Status = $Failure; Diagnostic = 'Unavailable' } }
        $result = Test-AutopilotDocumentPrerequisite -Settings $probeSettings -NoPrompts
        $result.Status | Should -BeExactly $Failure
        $result.Ready | Should -BeFalse
        Should -Invoke Invoke-AutopilotDocumentDependencySelfTest -ModuleName AutopilotExpress.Documents -Times 0
    }
    It 'reports worker failure without throwing into the core workflow' {
        $probeSettings.Values.ChecklistEnabled = $true
        Mock Invoke-AutopilotDocumentDependencySelfTest -ModuleName AutopilotExpress.Documents { @{ Ready = $false; Status = 'TimedOut'; Diagnostic = 'Deadline exceeded' } }
        $result = Test-AutopilotDocumentPrerequisite -Settings $probeSettings
        $result.Status | Should -BeExactly TimedOut
        $result.Ready | Should -BeFalse
    }
}
Describe 'Document worker wrapper boundaries' {
    BeforeEach {
        $script:workerTestRoot = Join-Path $TestDrive ([guid]::NewGuid().ToString('N'))
        $null = New-Item -ItemType Directory -Path (Join-Path $workerTestRoot 'Workers') -Force
    }
    It 'does not start a worker with a missing bundle' {
        InModuleScope AutopilotExpress.Documents -Parameters @{ Root = $TestDrive } {
            param($Root)
            Mock Test-AutopilotDocumentDependencyBundle { @{ Valid = $false; Diagnostic = 'Missing' } }
            (Invoke-AutopilotDocumentDependencySelfTest -DependencyRoot $Root).Status | Should -BeExactly BundleUnavailable
        }
    }
    It 'localises a process-start failure without throwing during cleanup' {
        InModuleScope AutopilotExpress.Documents -Parameters @{ Root = $workerTestRoot } {
            param($Root)
            Mock Test-AutopilotDocumentDependencyBundle { @{ Valid = $true; BundlePath = $Root } }
            Mock Get-AutopilotDocumentHostCapability { @{ WorkerAvailable = $true; WorkerExecutable = (Join-Path $Root 'absent.exe') } }
            $result = Invoke-AutopilotDocumentDependencySelfTest -DependencyRoot $Root
            $result.Status | Should -BeExactly Failed
            $result.Ready | Should -BeFalse
            $result.WorkerPid | Should -Be 0
        }
    }
    It 'rejects malformed worker output without claiming readiness' {
        [IO.File]::WriteAllText((Join-Path $workerTestRoot 'Workers/Test-DocumentLibraries.ps1'), 'param([string]$DependencyRoot) Write-Output "not-json"')
        InModuleScope AutopilotExpress.Documents -Parameters @{ Root = $workerTestRoot } {
            param($Root)
            Mock Test-AutopilotDocumentDependencyBundle { @{ Valid = $true; BundlePath = $Root } }
            $previousModuleRoot = $moduleRoot
            try {
                $moduleRoot = $Root
                $result = Invoke-AutopilotDocumentDependencySelfTest -DependencyRoot $Root
                $result.Status | Should -BeExactly Failed
                $result.Ready | Should -BeFalse
                $result.WorkerPid | Should -BeGreaterThan 0
            }
            finally { $moduleRoot = $previousModuleRoot }
        }
    }
    It 'retains a bounded authorization failure before the worker can return JSON' {
        [IO.File]::WriteAllText((Join-Path $workerTestRoot 'Workers/Test-DocumentLibraries.ps1'), 'param([string]$DependencyRoot) [Console]::Error.WriteLine("AuthorizationManager check failed. UnauthorizedAccess" + ("x" * 4096)); exit 1')
        InModuleScope AutopilotExpress.Documents -Parameters @{ Root = $workerTestRoot } {
            param($Root)
            Mock Test-AutopilotDocumentDependencyBundle { @{ Valid = $true; BundlePath = $Root } }
            $previousModuleRoot = $moduleRoot
            try {
                $moduleRoot = $Root
                $result = Invoke-AutopilotDocumentDependencySelfTest -DependencyRoot $Root
                $result.Ready | Should -BeFalse
                $result.Status | Should -BeExactly ScriptAuthorizationFailed
                $result.Stage | Should -BeExactly WorkerExecution
                $result.ExitCode | Should -Be 1
                $result.Diagnostic | Should -Match 'AuthorizationManager check failed'
                $result.Diagnostic.Length | Should -BeLessThan 2500
                $result.Diagnostic | Should -Not -Match '[\x00-\x1F\x7F]'
            }
            finally { $moduleRoot = $previousModuleRoot }
        }
    }
    It 'terminates only its owned synthetic worker at the external deadline' {
        [IO.File]::WriteAllText((Join-Path $workerTestRoot 'Workers/Test-DocumentLibraries.ps1'), 'param([string]$DependencyRoot) [Threading.ManualResetEvent]::new($false).WaitOne() | Out-Null')
        InModuleScope AutopilotExpress.Documents -Parameters @{ Root = $workerTestRoot } {
            param($Root)
            Mock Test-AutopilotDocumentDependencyBundle { @{ Valid = $true; BundlePath = $Root } }
            $previousModuleRoot = $moduleRoot
            try {
                $moduleRoot = $Root
                $result = Invoke-AutopilotDocumentDependencySelfTest -DependencyRoot $Root -TimeoutSeconds 1
                $result.Status | Should -BeExactly TimedOut
                $result.Ready | Should -BeFalse
                $result.WorkerPid | Should -BeGreaterThan 0
                Get-Process -Id $result.WorkerPid -ErrorAction SilentlyContinue | Should -BeNullOrEmpty
            }
            finally { $moduleRoot = $previousModuleRoot }
        }
    }
}
Describe 'Document settings contracts' {
    BeforeEach {
        $script:settingsArguments = @{ ScriptRoot = $env:AutopilotExpressRoot; LocalApplicationData = $TestDrive }
    }
    It 'defaults both outputs off with the approved independent policies' {
        $settings = Resolve-AutopilotDocumentSettings @settingsArguments
        $settings.Values.BirthCertificateEnabled | Should -BeFalse
        $settings.Values.ChecklistEnabled | Should -BeFalse
        $settings.Values.EnforceDocumentGuards | Should -BeFalse
        $settings.Values.BirthCertificateMode | Should -BeExactly AutoPrint
        $settings.Values.ChecklistMode | Should -BeExactly Review
        $settings.Values.WorkerTimeoutSeconds | Should -Be 60
        $settings.Values.FailedJobRetentionDays | Should -Be 7
        $settings.Values.FileNamePattern | Should -BeExactly '{SerialNumberOrServiceTag}_{DispatchDate}'
        $settings.Sources.WorkerTimeoutSeconds | Should -BeExactly Default
    }
    It 'resolves independent settings in the agreed precedence without modifying layers' {
        $runtime = @{ BirthCertificateEnabled = $true; ChecklistEnabled = $true; WorkerTimeoutSeconds = 90 }
        $saved = @{ WorkerTimeoutSeconds = 80 }
        $session = @{ WorkerTimeoutSeconds = 70; BirthCertificateEnabled = $true }
        $commandLine = @{ WorkerTimeoutSeconds = 60; BirthCertificateEnabled = $false; ChecklistEnabled = $null }
        $before = $runtime | ConvertTo-Json -Compress
        $settings = Resolve-AutopilotDocumentSettings @settingsArguments -RuntimeConfiguration $runtime -SavedPreferences $saved -SessionPreferences $session -CommandLineOverrides $commandLine
        $settings.Values.BirthCertificateEnabled | Should -BeFalse
        $settings.Values.ChecklistEnabled | Should -BeTrue
        $settings.Values.WorkerTimeoutSeconds | Should -Be 60
        $settings.Sources.BirthCertificateEnabled | Should -BeExactly CommandLineOverrides
        $settings.Sources.ChecklistEnabled | Should -BeExactly RuntimeConfiguration
        ($runtime | ConvertTo-Json -Compress) | Should -BeExactly $before
        $session.WorkerTimeoutSeconds = 10
        $settings.Values.WorkerTimeoutSeconds | Should -Be 60
    }
    It 'applies the <Layer> layer independently' -ForEach @(
        @{ Layer = 'RuntimeConfiguration' }, @{ Layer = 'SavedPreferences' },
        @{ Layer = 'SessionPreferences' }, @{ Layer = 'CommandLineOverrides' }
    ) {
        $arguments = @{ ScriptRoot = $env:AutopilotExpressRoot; LocalApplicationData = $TestDrive }
        $arguments[$Layer] = @{ ChecklistEnabled = $true }
        (Resolve-AutopilotDocumentSettings @arguments).Values.ChecklistEnabled | Should -BeTrue
    }
    It 'rejects invalid setting <Key> = <Value>' -ForEach @(
        @{ Key = 'BirthCertificateEnabled'; Value = 'false' }, @{ Key = 'ChecklistEnabled'; Value = 1 },
        @{ Key = 'EnforceDocumentGuards'; Value = 'false' },
        @{ Key = 'WorkerTimeoutSeconds'; Value = 0 }, @{ Key = 'WorkerTimeoutSeconds'; Value = 1.5 },
        @{ Key = 'WorkerTimeoutSeconds'; Value = '60' }, @{ Key = 'WorkerTimeoutSeconds'; Value = 3601 },
        @{ Key = 'FailedJobRetentionDays'; Value = -1 }, @{ Key = 'FailedJobRetentionDays'; Value = $true },
        @{ Key = 'ChecklistMode'; Value = 'PrintEverything' }, @{ Key = 'UnknownSetting'; Value = $true },
        @{ Key = 'FileNamePattern'; Value = '../{SerialNumberOrServiceTag}' },
        @{ Key = 'FileNamePattern'; Value = '{SerialNumberOrServiceTag}_{Unrecognised}' },
        @{ Key = 'LocalRoot'; Value = '\\server\shared' }, @{ Key = 'LocalRoot'; Value = 'data:documents' },
        @{ Key = 'ChecklistTemplatePath'; Value = 'https://example.invalid/file.docx' },
        @{ Key = 'ChecklistTemplatePath'; Value = 'templates/*.docx' }
    ) {
        $layer = @{}; $layer[$Key] = $Value
        { Resolve-AutopilotDocumentSettings @settingsArguments -RuntimeConfiguration $layer } | Should -Throw
    }
    It 'accepts configured zero retention as no automatic expiry, not immediate deletion' {
        (Resolve-AutopilotDocumentSettings @settingsArguments -SessionPreferences @{ FailedJobRetentionDays = 0 }).Values.FailedJobRetentionDays | Should -Be 0
    }
    It 'requires explicit removal of a CLI pin before a session edit takes precedence' {
        $pins = @{ WorkerTimeoutSeconds = 60 }
        $session = @{ WorkerTimeoutSeconds = 90 }
        (Resolve-AutopilotDocumentSettings @settingsArguments -SessionPreferences $session -CommandLineOverrides $pins).Values.WorkerTimeoutSeconds | Should -Be 60
        $pins.Remove('WorkerTimeoutSeconds')
        $settings = Resolve-AutopilotDocumentSettings @settingsArguments -SessionPreferences $session -CommandLineOverrides $pins
        $settings.Values.WorkerTimeoutSeconds | Should -Be 90
        $settings.Sources.WorkerTimeoutSeconds | Should -BeExactly SessionPreferences
    }
    It 'rejects nested unknown configuration without evaluating supplied code' {
        { Resolve-AutopilotDocumentSettings @settingsArguments -RuntimeConfiguration @{ documentGeneration = @{} } } | Should -Throw '*Unknown document setting*'
        { Resolve-AutopilotDocumentSettings @settingsArguments -SessionPreferences @{ WorkerTimeoutSeconds = { throw 'Do not execute' } } } | Should -Throw '*must be an integer*'
    }
    It 'anchors template paths independently of the current directory and creates no output root' {
        Push-Location $TestDrive
        try { $settings = Resolve-AutopilotDocumentSettings @settingsArguments } finally { Pop-Location }
        $settings.Values.ChecklistTemplatePath | Should -BeExactly ([IO.Path]::GetFullPath((Join-Path $env:AutopilotExpressRoot 'templates/Autopilot Checklist - v1.5.docx')))
        Test-Path -LiteralPath $settings.Values.LocalRoot | Should -BeFalse
    }
}

Describe 'Detached document job contracts' {
    BeforeEach {
        $script:contractSettings = Resolve-AutopilotDocumentSettings -ScriptRoot $env:AutopilotExpressRoot -LocalApplicationData $TestDrive -SessionPreferences @{ BirthCertificateEnabled = $true; ChecklistEnabled = $true }
        $script:contractTenant = '11111111-2222-3333-4444-555555555555'
        $script:contractCycle = '22222222-2222-3333-4444-555555555555'
        $script:contractRecord = @{
            RecordId = '33333333-2222-3333-4444-555555555555'; BuildCycleId = $script:contractCycle; WorkflowIdVersion = 2
            TenantId = $script:contractTenant; Serial = 'ABC123'; ConfigItem = 'CI000123'; SiteCode = 'MI'; DeviceType = 'Laptop'
            Status = 'completed'; DispatchConfirmed = $true; IsCompletionVerified = $true
            StartedAt = '2026-10-23T09:00:00+08:00'; CompletedAt = '2026-10-23T10:00:00+08:00'; DispatchedAt = '2026-10-23T10:00:00+08:00'
            CompletedBy = 'synthetic-technician'; FinalPrimaryUserDisplayName = 'Synthetic Person'; IntuneDeviceName = 'NOT-AUTHORITATIVE'
            IntuneInventory = @{ BuildCycleId = $script:contractCycle; TenantId = $script:contractTenant; Mode = 'Live'; IntuneHostName = 'MANAGED-01'; EthernetMacAddress = '00:11:22:33:44:55' }
            Steps = @{
                A = @{ ActionName = 'ResolveAutopilotDevice'; Success = $true; IsSimulated = $false; CompletionState = 'Verified'; Timestamp = '2026-10-23T09:30:00+08:00'; Data = @{ Secret = 'not-for-documents' } }
                B = @{ ActionName = 'DeleteAssociatedIntuneDevice'; Success = $true; IsSimulated = $false; CompletionState = 'Submitted'; Timestamp = '2026-10-23T09:31:00+08:00' }
            }
            RecoveryHistory = @()
        }
        $script:jobArguments = @{ Settings = $script:contractSettings; Device = $script:contractRecord; Mode = 'Live'; TenantId = $script:contractTenant; CreatedAtUtc = [DateTimeOffset]'2026-10-24T00:00:00Z' }
        $script:tickArguments = @{ Steps = $script:contractRecord.Steps; RequiredStepIds = @('A'); Mode = 'Live'; BuildCycleId = $script:contractCycle; CycleStartedAt = [DateTimeOffset]$script:contractRecord.StartedAt; DispatchedAt = [DateTimeOffset]$script:contractRecord.DispatchedAt }
    }
    It 'gives actual new workflow records a usable distinct document cycle identity' {
        $script:RuntimeConfig = @{}
        $first = New-DeviceRecordObject -Serial 'FACTORY-001' -ConfigItem 'CI-001' -SiteCode 'SITE' -DeviceType 'Laptop'
        $second = New-DeviceRecordObject -Serial 'FACTORY-002' -ConfigItem 'CI-002' -SiteCode 'SITE' -DeviceType 'Laptop'
        [guid]::Parse($first.BuildCycleId) | Should -Not -Be ([guid]::Empty)
        $second.BuildCycleId | Should -Not -Be $first.BuildCycleId
        $first.Status = 'completed'; $first.DispatchConfirmed = $true; $first.IsCompletionVerified = $true
        $first.CompletedAt = Get-Date; $first.DispatchedAt = $first.CompletedAt
        $job = New-AutopilotDocumentJob -Settings $script:contractSettings -Device $first -Mode Demo -TenantId demo
        $job.BuildCycleId | Should -BeExactly $first.BuildCycleId
    }
    It 'does nothing for absent enablement without requiring a dispatched record' {
        $jobArguments.Settings = Resolve-AutopilotDocumentSettings -ScriptRoot $env:AutopilotExpressRoot -LocalApplicationData $TestDrive
        $jobArguments.Device = @{}
        New-AutopilotDocumentJob @jobArguments | Should -BeNullOrEmpty
        Test-Path -LiteralPath $jobArguments.Settings.Values.LocalRoot | Should -BeFalse
    }
    It 'snapshots canonical fields, missing data and provenance without raw results or template aliases' {
        $job = New-AutopilotDocumentJob @jobArguments
        $job.Fields.SerialNumberOrServiceTag | Should -BeExactly ABC123
        $job.Fields.ConfigurationItem | Should -BeExactly CI000123
        $job.Fields.IntuneHostName | Should -BeExactly MANAGED-01
        $job.Fields.EthernetMacAddress | Should -BeExactly '00:11:22:33:44:55'
        $job.Fields.DispatchDate | Should -BeExactly '231026'
        $job.MissingFields | Should -Contain EmployeeNumber
        $job.MissingFields | Should -Contain VerifiedBy
        $job.Steps.A.TickEligible | Should -BeTrue
        $job.Steps.B.TickEligible | Should -BeFalse
        ($job | ConvertTo-Json -Depth 12) | Should -Not -Match 'not-for-documents|NOT-AUTHORITATIVE'
        $contractRecord.Steps.A.CompletionState = 'Failed'
        $contractRecord.IntuneInventory.IntuneHostName = 'changed'
        $contractRecord.IntuneInventory.EthernetMacAddress = 'AA:BB:CC:DD:EE:FF'
        $contractSettings.Values.WorkerTimeoutSeconds = 10
        $job.Steps.A.TickEligible | Should -BeTrue
        $job.Fields.IntuneHostName | Should -BeExactly MANAGED-01
        $job.Fields.EthernetMacAddress | Should -BeExactly '00:11:22:33:44:55'
        $job.Settings.WorkerTimeoutSeconds | Should -Be 60
    }
    It 'maps separate assigned-user placeholders and the dispatching actor name without guessing identities' {
        $contractRecord.FinalPrimaryUserPrincipalName = 'jane.smith@example.org'
        $jobArguments.DocumentContext = @{
            SiteName = 'Full Site Name'; TechnicianGivenName = 'Anne Marie'; TechnicianSurname = 'van Example'
            TechnicianDisplayName = 'NOT THE PREFERRED NAME'; AssignedUserGivenName = 'Jane'; AssignedUserSurname = 'Smith'
        }
        $job = New-AutopilotDocumentJob @jobArguments
        $job.Fields.AssignedUserName | Should -BeExactly 'jane.smith'
        $job.Fields.AssignedUserFullName | Should -BeExactly 'Jane Smith'
        $job.Fields.TechnicianName | Should -BeExactly 'Anne Marie van Example'
        $job.Fields.SiteName | Should -BeExactly 'Full Site Name'
        $job.Fields.CompletedBy | Should -BeExactly 'synthetic-technician'
        $job.Fields.InstalledBy | Should -BeExactly ''
        $job.Fields.CmdbUpdatedBy | Should -BeExactly ''
        $job.Fields.VerifiedBy | Should -BeExactly ''
        $jobArguments.DocumentContext.TechnicianGivenName = 'CHANGED'
        $job.Fields.TechnicianName | Should -BeExactly 'Anne Marie van Example'
    }
    It 'falls back to display names but never invents a technician name from Windows or imaging usernames' {
        $jobArguments.DocumentContext = @{ TechnicianGivenName = 'Incomplete'; TechnicianDisplayName = 'Dispatch Person' }
        $job = New-AutopilotDocumentJob @jobArguments
        $job.Fields.TechnicianName | Should -BeExactly 'Dispatch Person'
        $job.Fields.AssignedUserFullName | Should -BeExactly 'Synthetic Person'
        $jobArguments.DocumentContext = @{}
        $job = New-AutopilotDocumentJob @jobArguments
        $job.Fields.TechnicianName | Should -BeExactly ''
        $job.MissingFields | Should -Contain TechnicianName
    }
    It 'does not derive a short username from a malformed or absent UPN' {
        foreach ($upn in @('', 'not-an-upn', 'one@two@three', 'has space@example.org')) {
            $contractRecord.FinalPrimaryUserPrincipalName = $upn
            $job = New-AutopilotDocumentJob @jobArguments
            $job.Fields.AssignedUserName | Should -BeExactly ''
        }
    }
    It 'supports each profile independently and Disabled mode suppresses its job' {
        $contractSettings.Values.BirthCertificateEnabled = $false
        $job = New-AutopilotDocumentJob @jobArguments
        $job.Profiles.Count | Should -Be 1
        $job.Profiles[0].DocumentType | Should -BeExactly Checklist
        $contractSettings.Values.ChecklistMode = 'Disabled'
        New-AutopilotDocumentJob @jobArguments | Should -BeNullOrEmpty
    }
    It 'round trips through JSON and generates independent job identities' {
        $first = New-AutopilotDocumentJob @jobArguments
        $second = New-AutopilotDocumentJob @jobArguments
        $first.JobId | Should -Not -Be $second.JobId
        $decoded = $first | ConvertTo-Json -Depth 12 | ConvertFrom-Json
        $decoded.BuildCycleId | Should -BeExactly $contractCycle
        $decoded.Profiles.Count | Should -Be 2
        $decoded.Steps.A.TickEligible | Should -BeTrue
        $decoded.Settings.WorkerTimeoutSeconds | Should -Be 60
    }
    It 'accepts a detached JSON-normalised record from the actual application factory' {
        $record = New-EmptyDeviceRecord
        foreach ($key in $contractRecord.Keys) { $record[$key] = $contractRecord[$key] }
        $normalised = ConvertTo-NormalisedValue -Value ($record | ConvertTo-Json -Depth 15 | ConvertFrom-Json)
        $jobArguments.Device = $normalised
        $job = New-AutopilotDocumentJob @jobArguments
        $job.RecordId | Should -BeExactly $record.RecordId
        $job.Fields.SerialNumberOrServiceTag | Should -BeExactly $record.Serial
        $job.Steps.A.TickEligible | Should -BeTrue
        $normalised.Steps.A.Success = $false
        $job.Steps.A.TickEligible | Should -BeTrue
    }
    It 'rejects invalid dispatched-record field <Key>' -ForEach @(
        @{ Key = 'RecordId'; Value = '' }, @{ Key = 'BuildCycleId'; Value = 'not-a-guid' },
        @{ Key = 'TenantId'; Value = 'different-tenant' }, @{ Key = 'Status'; Value = 'new' },
        @{ Key = 'DispatchConfirmed'; Value = 'true' }, @{ Key = 'IsCompletionVerified'; Value = $null },
        @{ Key = 'Serial'; Value = '' }, @{ Key = 'ConfigItem'; Value = @('not', 'text') },
        @{ Key = 'DispatchedAt'; Value = 'invalid' }, @{ Key = 'StartedAt'; Value = '2026-10-24T00:00:00Z' }
    ) {
        $contractRecord[$Key] = $Value
        { New-AutopilotDocumentJob @jobArguments } | Should -Throw
    }
    It 'does not reuse another cycle, mode or tenant inventory or the old convenience hostname' {
        $contractRecord.IntuneInventory.BuildCycleId = [guid]::NewGuid().ToString('D')
        $job = New-AutopilotDocumentJob @jobArguments
        $job.Fields.IntuneHostName | Should -BeNullOrEmpty
        $job.Fields.EthernetMacAddress | Should -BeNullOrEmpty
        $contractRecord.IntuneInventory.BuildCycleId = $contractCycle
        $contractRecord.IntuneInventory.Mode = 'Demo'
        $job = New-AutopilotDocumentJob @jobArguments
        $job.Fields.IntuneHostName | Should -BeNullOrEmpty
        $job.Fields.EthernetMacAddress | Should -BeNullOrEmpty
        $contractRecord.IntuneInventory.Mode = 'Live'
        $contractRecord.IntuneInventory.TenantId = [guid]::NewGuid().ToString('D')
        $job = New-AutopilotDocumentJob @jobArguments
        $job.Fields.IntuneHostName | Should -BeNullOrEmpty
        $job.Fields.EthernetMacAddress | Should -BeNullOrEmpty
    }
    It 'preserves only admissible ticks on DO and discloses the saved reason' {
        $contractRecord.IsCompletionVerified = $false
        $contractRecord.RecoveryHistory = @(@{ Stage = 'CompletionOverride'; Timestamp = $contractRecord.DispatchedAt; Reason = 'Approved synthetic exception' })
        $job = New-AutopilotDocumentJob @jobArguments
        $job.IsAdministrativeOverride | Should -BeTrue
        $job.OverrideReason | Should -BeExactly 'Approved synthetic exception'
        $job.Steps.A.TickEligible | Should -BeTrue
        $job.Steps.B.TickEligible | Should -BeFalse
        $contractRecord.RecoveryHistory[0].Reason = 'changed'
        $job.OverrideReason | Should -BeExactly 'Approved synthetic exception'
    }
    It 'refuses to invent a reason for administrative completion' {
        $contractRecord.IsCompletionVerified = $false
        { New-AutopilotDocumentJob @jobArguments } | Should -Throw '*override reason*'
    }
    It 'labels Demo explicitly and never awards a Live tick' {
        $jobArguments.Mode = 'Demo'
        $job = New-AutopilotDocumentJob @jobArguments
        $job.IsDemo | Should -BeTrue
        $job.CertificationLabel | Should -BeExactly 'DEMO - NOT LIVE CERTIFICATION'
        $job.Steps.A.TickEligible | Should -BeFalse
        $job.OutputRoot | Should -Match '\\Demo\\Output\\Serial-ABC123_CI-CI000123$'
        $job.JobRoot | Should -Match '\\Demo\\Working$'
        $job.JobDirectoryName | Should -BeExactly ('Serial-ABC123_CI-CI000123_{0}' -f $job.JobId)
    }
    Describe 'Successful document job compaction' {
        BeforeEach {
            $script:compactRoot = Join-Path $TestDrive ([guid]::NewGuid().ToString('N'))
            $script:compactJob = @{
                SchemaVersion = 1; JobId = [guid]::NewGuid().ToString('D'); RecordId = [guid]::NewGuid().ToString('D'); BuildCycleId = [guid]::NewGuid().ToString('D')
                Mode = 'Demo'; TenantId = 'demo'; DispatchedAt = [DateTimeOffset]::Now.ToString('o'); CreatedAtUtc = [DateTimeOffset]::UtcNow.ToString('o')
                JobRoot = Join-Path $compactRoot 'Working'; OutputRoot = Join-Path $compactRoot 'Output'
                Profiles = @(@{ DocumentType = 'BirthCertificate'; DeliveryMode = 'GenerateOnly' })
                Fields = @{ SerialNumberOrServiceTag = 'SYNTHETIC'; ConfigurationItem = 'CI-SYNTHETIC'; DispatchDate = '251026' }
                Settings = @{ FileNamePattern = '{SerialNumberOrServiceTag}_{DispatchDate}' }
            }
            $script:compactDirectory = Join-Path $compactJob.JobRoot $compactJob.JobId
            $null = [IO.Directory]::CreateDirectory($compactDirectory)
            $pdf = Join-Path $compactDirectory 'BirthCertificate.exported.pdf'
            [IO.File]::WriteAllText($pdf, "%PDF-1.7`nfixture`n%%EOF`n", [Text.Encoding]::ASCII)
            $delivery = Invoke-AutopilotDocumentDelivery -Job $compactJob -DocumentType BirthCertificate -PdfPath $pdf -ReceiptDirectory $compactDirectory
            $script:compactSummary = @{ Status = 'Completed'; Cleanup = 'Complete'; Results = @($delivery) }
            InModuleScope AutopilotExpress.Documents -Parameters @{ Directory = $compactDirectory; JobId = $compactJob.JobId; Summary = $compactSummary } {
                param($Directory, $JobId, $Summary)
                [IO.File]::Open((Join-Path $Directory 'job.lock'), [IO.FileMode]::CreateNew).Dispose()
                Write-AutopilotDocumentLifecycle -Directory $Directory -JobId $JobId -Active $false -Result $Summary
            }
        }
        It 'retains only the verified final PDF and one no-replay receipt and removes the working folder' {
            InModuleScope AutopilotExpress.Documents -Parameters @{ Directory = $compactDirectory; Job = $compactJob; Summary = $compactSummary } {
                param($Directory, $Job, $Summary)
                $result = Complete-AutopilotDocumentJob -Directory $Directory -Job $Job -Summary $Summary
                $result.Removed | Should -BeGreaterThan 3
                Test-Path -LiteralPath $Directory | Should -BeFalse
                Test-Path -LiteralPath $Job.JobRoot | Should -BeFalse
                @(Get-ChildItem -LiteralPath $Job.OutputRoot -File).Count | Should -Be 2
                $receipt = Get-Content -LiteralPath $result.ReceiptPath -Raw | ConvertFrom-Json
                $receipt.AutomaticReplayAllowed | Should -BeFalse
                $receipt.Results[0].OutputSHA256 | Should -BeExactly $Summary.Results[0].OutputSHA256
            }
        }
        It 'names a retained review DOCX after its actually published PDF following a partial retry' {
            $source = Join-Path $compactDirectory 'SYNTHETIC_251026.docx'
            [IO.File]::WriteAllText($source, 'owned synthetic review copy')
            $published = Join-Path $compactJob.OutputRoot 'SYNTHETIC_251026_BirthCertificate.pdf'
            [IO.File]::Move($compactSummary.Results[0].PdfPath, $published)
            $compactSummary.Results[0].PdfPath = $published
            InModuleScope AutopilotExpress.Documents -Parameters @{ Directory = $compactDirectory; Job = $compactJob; Summary = $compactSummary } {
                param($Directory, $Job, $Summary)
                $null = Complete-AutopilotDocumentJob -Directory $Directory -Job $Job -Summary $Summary -RetainReviewCopies
                Test-Path -LiteralPath (Join-Path $Job.OutputRoot 'SYNTHETIC_251026_BirthCertificate.docx') | Should -BeTrue
                Test-Path -LiteralPath (Join-Path $Job.OutputRoot 'SYNTHETIC_251026.docx') | Should -BeFalse
                Test-Path -LiteralPath $Directory | Should -BeFalse
            }
        }
        It 'suppresses worker launch and automatic delivery replay after compaction' {
            InModuleScope AutopilotExpress.Documents -Parameters @{ Directory = $compactDirectory; Job = $compactJob; Summary = $compactSummary } {
                param($Directory, $Job, $Summary)
                $null = Complete-AutopilotDocumentJob -Directory $Directory -Job $Job -Summary $Summary
                Mock Get-AutopilotDocumentHostCapability { throw 'No worker or Word probe is allowed for a completed job.' }
                $result = Start-AutopilotDocumentJob -Job $Job -DependencyRoot 'unused'
                $result.Status | Should -BeExactly Completed
                $result.Results[0].OutputSHA256 | Should -BeExactly $Summary.Results[0].OutputSHA256
                Should -Invoke Get-AutopilotDocumentHostCapability -Times 0 -Exactly
            }
        }
        It 'cleans a terminal owned success on restart even when failed-job expiry is disabled' {
            $request = @{ SchemaVersion = 1; JobDirectory = $compactDirectory; Job = $compactJob; ReviewOnly = $false }
            [IO.File]::WriteAllText((Join-Path $compactDirectory ('job-request-{0}.json' -f [guid]::NewGuid().ToString('N'))), ($request | ConvertTo-Json -Depth 12), [Text.UTF8Encoding]::new($false))
            $result = Invoke-AutopilotDocumentCleanup -JobRoot $compactJob.JobRoot -FailedJobRetentionDays 0
            $result.Removed | Should -BeGreaterThan 3
            Test-Path -LiteralPath $compactDirectory | Should -BeFalse
            @(Get-ChildItem -LiteralPath $compactJob.OutputRoot -File).Count | Should -Be 2
        }
        It 'migrates verified legacy review artifacts only, with dry run <DryRun> and unknown diagnostics <Unknown>' -ForEach @(@{ DryRun = $true; Unknown = $false }, @{ DryRun = $false; Unknown = $false }, @{ DryRun = $false; Unknown = $true }) {
            $documentRoot = Join-Path $compactRoot 'Documents'
            $reviewRoot = Join-Path $documentRoot ('review-{0}' -f [guid]::NewGuid().ToString('N'))
            $jobsRoot = Join-Path $reviewRoot 'Demo/jobs'; $null = [IO.Directory]::CreateDirectory($jobsRoot)
            $oldDirectory = $compactDirectory; $compactDirectory = Join-Path $jobsRoot $compactJob.JobId
            [IO.Directory]::Move($oldDirectory, $compactDirectory)
            $pdfRoot = Join-Path $reviewRoot 'Demo/output'; $null = [IO.Directory]::CreateDirectory($pdfRoot)
            $pdfName = [IO.Path]::GetFileName($compactSummary.Results[0].PdfPath)
            $sourcePdf = Join-Path $pdfRoot $pdfName
            [IO.File]::Move($compactSummary.Results[0].PdfPath, $sourcePdf)
            $compactSummary.Results[0].PdfPath = $sourcePdf; $compactJob.OutputRoot = $pdfRoot; $compactJob.JobRoot = $jobsRoot
            [IO.File]::WriteAllText((Join-Path $compactDirectory 'SYNTHETIC_251026.docx'), 'explicit retained review copy')
            [IO.File]::WriteAllText((Join-Path $compactDirectory 'SYNTHETIC_251026-1.png'), 'owned synthetic review page')
            [IO.File]::WriteAllText((Join-Path $pdfRoot 'SYNTHETIC_251026-2.png'), 'owned output-directory review page')
            if ($Unknown) { [IO.File]::WriteAllText((Join-Path $compactDirectory 'unknown-probe.txt'), 'must retain unchanged') }
            foreach ($folder in @('dependencies', 'preferences')) {
                $folderPath = Join-Path $documentRoot $folder
                $null = [IO.Directory]::CreateDirectory($folderPath)
                [IO.File]::WriteAllText((Join-Path $folderPath 'unchanged.txt'), 'retained folder contents')
            }
            InModuleScope AutopilotExpress.Documents -Parameters @{ Directory = $compactDirectory; Job = $compactJob; Summary = $compactSummary } {
                param($Directory, $Job, $Summary)
                Write-AutopilotDocumentLifecycle -Directory $Directory -JobId $Job.JobId -Active $false -Result $Summary
            }
            $request = @{ SchemaVersion = 1; JobDirectory = $compactDirectory; Job = $compactJob; ReviewOnly = $true }
            [IO.File]::WriteAllText((Join-Path $compactDirectory ('job-request-{0}.json' -f [guid]::NewGuid().ToString('N'))), ($request | ConvertTo-Json -Depth 12), [Text.UTF8Encoding]::new($false))
            $result = Invoke-AutopilotDocumentCleanup -JobRoot $documentRoot -ReorganiseReviews -WhatIf:$DryRun
            $result.Actions.Count | Should -Be $(if ($DryRun) { 1 } else { 4 })
            foreach ($folder in @('Dependencies', 'Preferences')) {
                $expectedCase = if ($DryRun) { $folder.ToLowerInvariant() } else { $folder }
                @(Get-ChildItem -LiteralPath $documentRoot -Directory | Where-Object Name -CEQ $expectedCase).Count | Should -Be 1
                [IO.File]::ReadAllText((Join-Path (Join-Path $documentRoot $expectedCase) 'unchanged.txt')) | Should -BeExactly 'retained folder contents'
            }
            if (-not $Unknown) { $result.Actions[0].Reason | Should -BeExactly '' }
            if ($DryRun) {
                $result.Actions[0].Status | Should -BeExactly WhatIf
                Test-Path -LiteralPath $compactDirectory | Should -BeTrue
                Test-Path -LiteralPath $result.LogPath | Should -BeFalse
            }
            elseif ($Unknown) {
                $result.Actions[0].Status | Should -BeExactly Retained
                Test-Path -LiteralPath (Join-Path $result.Actions[0].Destination 'unknown-probe.txt') | Should -BeTrue
                Test-Path -LiteralPath $compactDirectory | Should -BeFalse
                Test-Path -LiteralPath $reviewRoot | Should -BeFalse
            }
            else {
                $result.Actions[0].Status | Should -BeExactly Compacted
                Test-Path -LiteralPath $compactDirectory | Should -BeFalse
                Test-Path -LiteralPath $reviewRoot | Should -BeFalse
                Test-Path -LiteralPath $result.LogPath | Should -BeTrue
                @(Get-ChildItem -LiteralPath $result.Actions[0].Destination -File).Count | Should -Be 3
                @(Get-ChildItem -LiteralPath $result.Actions[0].Destination -Filter '*.png').Count | Should -Be 0
            }
        }
        It 'retains all evidence when an unknown file exists' {
            [IO.File]::WriteAllText((Join-Path $compactDirectory 'manual-notes.txt'), 'Preserve user content')
            InModuleScope AutopilotExpress.Documents -Parameters @{ Directory = $compactDirectory; Job = $compactJob; Summary = $compactSummary } {
                param($Directory, $Job, $Summary)
                $arguments = @{ Directory = $Directory; Job = $Job; Summary = $Summary }
                { Complete-AutopilotDocumentJob @arguments } | Should -Throw '*Unknown file*'
                Test-Path -LiteralPath (Join-Path $Directory 'manual-notes.txt') | Should -BeTrue
                Test-Path -LiteralPath (Join-Path $Directory 'BirthCertificate.exported.pdf') | Should -BeTrue
            }
        }
        It 'retains staging if the published PDF differs from its durable digest' {
            [IO.File]::WriteAllText($compactSummary.Results[0].PdfPath, "%PDF-1.7`nchanged`n%%EOF`n", [Text.Encoding]::ASCII)
            InModuleScope AutopilotExpress.Documents -Parameters @{ Directory = $compactDirectory; Job = $compactJob; Summary = $compactSummary } {
                param($Directory, $Job, $Summary)
                $arguments = @{ Directory = $Directory; Job = $Job; Summary = $Summary }
                { Complete-AutopilotDocumentJob @arguments } | Should -Throw '*differs from its receipt*'
                Test-Path -LiteralPath (Join-Path $Directory 'BirthCertificate.exported.pdf') | Should -BeTrue
            }
        }
        It 'refuses uncertain delivery, an active lease and WhatIf deletion' {
            InModuleScope AutopilotExpress.Documents -Parameters @{ Directory = $compactDirectory; Job = $compactJob; Summary = $compactSummary } {
                param($Directory, $Job, $Summary)
                $Summary.Cleanup = 'Uncertain'
                { Complete-AutopilotDocumentJob -Directory $Directory -Job $Job -Summary $Summary } | Should -Throw '*fully successful*'
                $Summary.Cleanup = 'Complete'
                $lease = [IO.File]::Open((Join-Path $Directory 'job.lock'), [IO.FileMode]::Open, [IO.FileAccess]::ReadWrite, [IO.FileShare]::None)
                try { { Complete-AutopilotDocumentJob -Directory $Directory -Job $Job -Summary $Summary } | Should -Throw } finally { $lease.Dispose() }
                (Complete-AutopilotDocumentJob -Directory $Directory -Job $Job -Summary $Summary -WhatIf).Removed | Should -Be 0
                Test-Path -LiteralPath (Join-Path $Directory 'BirthCertificate.exported.pdf') | Should -BeTrue
            }
        }
    }
    It 'accepts only <State> as admissible completed Live evidence' -ForEach @(
        @{ State = 'Verified'; Eligible = $true }, @{ State = 'TechnicianConfirmed'; Eligible = $true },
        @{ State = 'Submitted'; Eligible = $false }, @{ State = 'Failed'; Eligible = $false },
        @{ State = 'Blocked'; Eligible = $false }, @{ State = 'Cancelled'; Eligible = $false },
        @{ State = 'LegacyCompleted'; Eligible = $false }, @{ State = 'AuditedException'; Eligible = $false },
        @{ State = 'Simulated'; Eligible = $false }
    ) {
        $contractRecord.Steps.A.CompletionState = $State
        Test-AutopilotDocumentTick @tickArguments | Should -Be $Eligible
    }
    It 'rejects defective tick evidence <Key>' -ForEach @(
        @{ Key = 'Success'; Value = $false }, @{ Key = 'Success'; Value = 'true' },
        @{ Key = 'IsSimulated'; Value = $true }, @{ Key = 'IsSimulated'; Value = $null },
        @{ Key = 'Timestamp'; Value = '2026-10-22T00:00:00Z' }, @{ Key = 'Timestamp'; Value = '2026-10-24T00:00:00Z' },
        @{ Key = 'Timestamp'; Value = '' }, @{ Key = 'BuildCycleId'; Value = 'old-cycle' },
        @{ Key = 'EvidenceKind'; Value = 'LegacyEvidence' }, @{ Key = 'Data'; Value = @{ Blocked = $true } }
    ) {
        $contractRecord.Steps.A[$Key] = $Value
        Test-AutopilotDocumentTick @tickArguments | Should -BeFalse
    }
    It 'requires every grouped step and refuses empty or unknown groups' {
        $tickArguments.RequiredStepIds = @('A', 'B')
        Test-AutopilotDocumentTick @tickArguments | Should -BeFalse
        $contractRecord.Steps.B.CompletionState = 'TechnicianConfirmed'
        Test-AutopilotDocumentTick @tickArguments | Should -BeTrue
        $tickArguments.RequiredStepIds = @()
        Test-AutopilotDocumentTick @tickArguments | Should -BeFalse
        $tickArguments.RequiredStepIds = @('UNTRACKED-CMDB')
        Test-AutopilotDocumentTick @tickArguments | Should -BeFalse
    }
    It 'uses saved dispatch date and suffixes the document type only on collision' {
        $job = New-AutopilotDocumentJob @jobArguments
        Get-AutopilotDocumentOutputName -Job $job -DocumentType BirthCertificate | Should -BeExactly 'ABC123_231026.pdf'
        Get-AutopilotDocumentOutputName -Job $job -DocumentType Checklist -OccupiedFileNames @('abc123_231026.PDF') | Should -BeExactly 'ABC123_231026_Checklist.pdf'
        { Get-AutopilotDocumentOutputName -Job $job -DocumentType Checklist -OccupiedFileNames @('ABC123_231026.pdf', 'ABC123_231026_Checklist.pdf') } | Should -Throw '*no overwrite*'
    }
    It 'encodes unsafe serial characters for filenames without changing document or barcode payload' {
        $contractRecord.Serial = 'ABC/12:3'
        $job = New-AutopilotDocumentJob @jobArguments
        Get-AutopilotDocumentOutputName -Job $job -DocumentType Checklist | Should -BeExactly 'ABC%2F12%3A3_231026.pdf'
        $job.Fields.SerialNumberOrServiceTag | Should -BeExactly 'ABC/12:3'
        $job.Fields.VerifiedBy | Should -BeNullOrEmpty
    }
    It 'rejects excessive filenames rather than truncating the serial or overwriting output' {
        $contractRecord.Serial = 'A' * 260
        $job = New-AutopilotDocumentJob @jobArguments
        { Get-AutopilotDocumentOutputName -Job $job -DocumentType Checklist } | Should -Throw '*too long*'
        $job.Fields.SerialNumberOrServiceTag.Length | Should -Be 260
    }
    It 'supports WhatIf without manufacturing a job or receipt' {
        New-AutopilotDocumentJob @jobArguments -WhatIf | Should -BeNullOrEmpty
        $job = New-AutopilotDocumentJob @jobArguments
        New-AutopilotDocumentResult -Job $job -DocumentType Checklist -WhatIf | Should -BeNullOrEmpty
    }
    It 'initialises detached Pending/NotRequested receipts without pretending to print' {
        $job = New-AutopilotDocumentJob @jobArguments
        $result = New-AutopilotDocumentResult -Job $job -DocumentType Checklist
        $result.Status | Should -BeExactly Pending
        $result.PrintState | Should -BeExactly NotRequested
        $result.PdfPath | Should -BeNullOrEmpty
        $result.PrintIntentAtUtc | Should -BeNullOrEmpty
        $result.AttemptCount | Should -Be 0
        $decoded = $result | ConvertTo-Json | ConvertFrom-Json
        $decoded.RecordId | Should -BeExactly $contractRecord.RecordId
        $job.JobId = [guid]::NewGuid().ToString('D')
        $result.JobId | Should -Not -Be $job.JobId
    }
}