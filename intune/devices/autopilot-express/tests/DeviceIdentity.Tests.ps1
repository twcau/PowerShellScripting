<#
.SYNOPSIS
    Offline regression checks for fail-closed Autopilot and Entra resolution.
.DESCRIPTION
    Extracts actual functions without launching the CLI. Graph responses are
    synthetic; no operational storage, authentication or device changes occur.
    Requires Pester 5 and FullLanguage for source parsing.
#>
BeforeAll {
    $sourcePath = Join-Path (Split-Path -Parent $PSScriptRoot) 'autopilot-express.ps1'
    $tokens = $null
    $parseErrors = $null
    $sourceAst = [System.Management.Automation.Language.Parser]::ParseFile($sourcePath, [ref]$tokens, [ref]$parseErrors)
    if ($parseErrors.Count) { throw ($parseErrors.Message -join '; ') }
    foreach ($functionName in @('ConvertTo-NormalisedValue', 'ConvertTo-AutopilotImportReceipt', 'Get-AutopilotImportReceipt', 'Save-AutopilotImportLedgerEntry', 'Invoke-AutopilotHashImport', 'Get-AutopilotHashImportSettings', 'Get-AutopilotHashCandidate', 'Select-AutopilotHashRow', 'Get-AutopilotHashRow', 'New-OperationResult', 'Get-GraphVerificationPolicy', 'Invoke-StepResolveAutopilotDevice', 'Get-LiveTenantBinding', 'Get-GraphDiscoveryCollection', 'Resolve-LiveAutopilotDeviceBySerial', 'Resolve-LiveEntraDeviceObject', 'Resolve-LiveManagedDeviceBySerial', 'Resolve-LiveAutopilotContext', 'Get-StoredEntraDeviceObject', 'Get-ManagedDeviceSerialLookupUri')) {
        $definition = $sourceAst.Find({ param($node) $node -is [System.Management.Automation.Language.FunctionDefinitionAst] -and $node.Name -eq $functionName }, $true)
        if (-not $definition) { throw ('Missing function: {0}' -f $functionName) }
        Set-Item -Path ('Function:{0}' -f $definition.Name) -Value $definition.Body.GetScriptBlock()
    }
    function Invoke-GraphApiRequest { param($Method, $Uri, $Body) if ($null -ne $Body) { throw ('Unexpected Graph write: {0} {1}' -f $Method, $Uri) }; throw ('Unexpected Graph request: {0} {1}' -f $Method, $Uri) }
    function Get-MgContext { throw 'Unexpected actual tenant lookup.' }
    function Write-AutopilotExpressLog { param($Message, $Level) throw ('Unexpected log: {0}; {1}' -f $Level, $Message) }
    function Get-ConfiguredMissingSerialHandoffNote { return 'Follow the approved upload guide.' }
    function Read-ValidatedInput { param($Prompt, $Default, $Type, $Choices) throw ('Unexpected prompt: {0}, {1}, {2}, {3}' -f $Prompt, $Default, $Type, ($Choices -join ',')) }
    function Write-Utf8File { param($Path, $Content) throw ('Unexpected write: {0}; {1} characters' -f $Path, $Content.Length) }
    function Save-DeviceLedgerEntry { param($Device, $LedgerName, $Entry) throw ('Unexpected ledger save: {0} {1} {2}' -f $Device.Serial, $LedgerName, $Entry.State) }
    function Assert-ActiveStorageReservation { throw 'Unexpected storage reservation access.' }
    function Assert-FileWriteRecoveryState { param($Path) throw ('Unexpected recovery check: {0}' -f $Path) }
    function Get-RuntimeConfigFilePath { throw 'Unexpected configuration-path lookup.' }
}

Describe 'Automatic Intune inventory read contract' {
    BeforeAll {
        foreach ($functionName in @('ConvertTo-EthernetMacAddress', 'ConvertTo-WindowsReleaseName', 'Get-LiveDeviceInventory', 'Get-ManagedDeviceInventoryUri')) {
            $definition = $sourceAst.Find({ param($node) $node -is [System.Management.Automation.Language.FunctionDefinitionAst] -and $node.Name -eq $functionName }, $true)
            if (-not $definition) { throw ('Missing inventory function: {0}' -f $functionName) }
            Set-Item -Path ('Function:{0}' -f $definition.Name) -Value $definition.Body.GetScriptBlock()
        }
    }
    BeforeEach {
        $script:inventoryDevice = @{ Serial = 'SERIAL1'; TenantId = 'tenant-1'; ManagedDeviceId = 'managed-1'; AzureAdDeviceId = 'registration-1' }
        $script:inventoryResponse = @{ id = 'managed-1'; serialNumber = 'SERIAL1'; azureADDeviceId = 'registration-1'; deviceName = 'IMAGED-PC-01'; ethernetMacAddress = 'aabbccddeeff'; lastSyncDateTime = '2026-10-22T10:00:00Z' }
        Mock Get-LiveTenantBinding { return 'tenant-1' }
        Mock Invoke-GraphApiRequest { return $script:inventoryResponse }
        Mock Resolve-LiveManagedDeviceBySerial { throw 'Unexpected managed-device discovery.' }
        Mock Resolve-LiveAutopilotDeviceBySerial { throw 'Unexpected Autopilot reconciliation.' }
    }
    It 'reads the explicit Ethernet property from one managed-device resource without mutating the record' {
        $before = $script:inventoryDevice | ConvertTo-Json -Compress
        $inventory = Get-LiveDeviceInventory -Device $script:inventoryDevice
        $inventory.IntuneHostName | Should -BeExactly 'IMAGED-PC-01'
        $inventory.EthernetMacAddress | Should -BeExactly 'AA:BB:CC:DD:EE:FF'
        $inventory.ManagedDeviceId | Should -Be 'managed-1'
        Should -Invoke Invoke-GraphApiRequest -Times 1 -Exactly -ParameterFilter { $Method -eq 'GET' -and $Uri -like '*/v1.0/deviceManagement/managedDevices/managed-1?*' -and $Uri -like '*ethernetMacAddress*' }
        ($script:inventoryDevice | ConvertTo-Json -Compress) | Should -BeExactly $before
    }
    It 'treats a null Ethernet value as pending rather than substituting Wi-Fi' {
        $script:inventoryResponse.ethernetMacAddress = $null
        $script:inventoryResponse.wiFiMacAddress = '10:20:30:40:50:60'
        (Get-LiveDeviceInventory -Device $script:inventoryDevice).EthernetMacAddress | Should -BeExactly ''
    }
    It 'captures the extra device details from the same single request' {
        $script:inventoryResponse.wiFiMacAddress = '102030405060'
        $script:inventoryResponse.userPrincipalName = ' user@example.test '
        $script:inventoryResponse.operatingSystem = 'Windows'
        $script:inventoryResponse.osVersion = '10.0.26100.4061'
        $inventory = Get-LiveDeviceInventory -Device $script:inventoryDevice
        $inventory.WiFiMacAddress | Should -BeExactly '10:20:30:40:50:60'
        $inventory.EntraDeviceId | Should -BeExactly 'registration-1'
        $inventory.PrimaryUser | Should -BeExactly 'user@example.test'
        $inventory.OperatingSystem | Should -BeExactly 'Windows'
        $inventory.OsVersion | Should -BeExactly '10.0.26100.4061'
        $inventory.OsRelease | Should -BeExactly 'Windows 11 24H2'
        Should -Invoke Invoke-GraphApiRequest -Times 1 -Exactly -ParameterFilter { $Uri -like '*wiFiMacAddress*' -and $Uri -like '*userPrincipalName*' -and $Uri -like '*osVersion*' }
    }
    It 'returns an empty Wi-Fi address instead of failing when Intune reports a malformed one' {
        $script:inventoryResponse.wiFiMacAddress = 'not-a-mac'
        $inventory = Get-LiveDeviceInventory -Device $script:inventoryDevice
        $inventory.WiFiMacAddress | Should -BeExactly ''
        $inventory.EthernetMacAddress | Should -BeExactly 'AA:BB:CC:DD:EE:FF'
    }
    It 'names Windows release <Expected> for build <Version>' -ForEach @(
        @{ Version = '10.0.19045.5737'; Expected = 'Windows 10 22H2' }, @{ Version = '10.0.22631'; Expected = 'Windows 11 23H2' },
        @{ Version = '10.0.26200.1'; Expected = 'Windows 11 25H2' }, @{ Version = '10.0.99999.1'; Expected = '' }, @{ Version = 'unknown'; Expected = '' }, @{ Version = ''; Expected = '' }
    ) {
        ConvertTo-WindowsReleaseName -OsVersion $Version | Should -BeExactly $Expected
    }
    It 'rejects wrong returned <Field> without changing caller evidence' -ForEach @(
        @{ Field = 'id'; Value = 'other-device' }, @{ Field = 'serialNumber'; Value = 'OTHER' }, @{ Field = 'azureADDeviceId'; Value = 'other-registration' }
    ) {
        $script:inventoryResponse[$Field] = $Value
        $before = $script:inventoryDevice | ConvertTo-Json -Compress
        { Get-LiveDeviceInventory -Device $script:inventoryDevice } | Should -Throw
        ($script:inventoryDevice | ConvertTo-Json -Compress) | Should -BeExactly $before
    }
    It 'rejects invalid Ethernet <Value>' -ForEach @(
        @{ Value = '00:00:00:00:00:00' }, @{ Value = 'FF:FF:FF:FF:FF:FF' }, @{ Value = '01:00:5E:00:00:01' }, @{ Value = 'not-a-mac' }
    ) {
        { ConvertTo-EthernetMacAddress -Value $Value } | Should -Throw
    }
    It 'accepts a new registration only when two fresh discoveries bind it without rewriting historical identity' {
        $script:inventoryDevice.ManagedDeviceId = ''
        $script:inventoryResponse.azureADDeviceId = 'registration-new'
        Mock Resolve-LiveManagedDeviceBySerial { @{ id = 'managed-1'; serialNumber = 'SERIAL1'; azureADDeviceId = 'registration-new' } }
        Mock Resolve-LiveAutopilotDeviceBySerial { @{ id = 'autopilot-1'; serialNumber = 'SERIAL1'; managedDeviceId = 'managed-1'; azureActiveDirectoryDeviceId = 'registration-new' } }
        $before = $script:inventoryDevice | ConvertTo-Json -Compress
        (Get-LiveDeviceInventory -Device $script:inventoryDevice).IntuneHostName | Should -BeExactly 'IMAGED-PC-01'
        ($script:inventoryDevice | ConvertTo-Json -Compress) | Should -BeExactly $before
        Should -Invoke Resolve-LiveAutopilotDeviceBySerial -Times 1 -Exactly
    }
    It 'refuses new registration reconciliation when fresh Autopilot <Field> disagrees' -ForEach @(
        @{ Field = 'managedDeviceId' }, @{ Field = 'azureActiveDirectoryDeviceId' }
    ) {
        $script:inventoryDevice.ManagedDeviceId = ''
        $script:inventoryResponse.azureADDeviceId = 'registration-new'
        $script:freshAutopilot = @{ managedDeviceId = 'managed-1'; azureActiveDirectoryDeviceId = 'registration-new' }
        $script:freshAutopilot[$Field] = 'stale'
        Mock Resolve-LiveManagedDeviceBySerial { @{ id = 'managed-1'; azureADDeviceId = 'registration-new' } }
        Mock Resolve-LiveAutopilotDeviceBySerial { $script:freshAutopilot }
        { Get-LiveDeviceInventory -Device $script:inventoryDevice } | Should -Throw '*not confirmed*'
    }
    It 'retains the bound-device registration guard without attempting reconciliation' {
        $script:inventoryResponse.azureADDeviceId = 'registration-new'
        { Get-LiveDeviceInventory -Device $script:inventoryDevice } | Should -Throw '*registration mismatch*'
        Should -Invoke Resolve-LiveAutopilotDeviceBySerial -Times 0 -Exactly
    }
}

Describe 'Automatic inventory scheduling and publication' {
    BeforeAll {
        foreach ($functionName in @('New-EmptyDeviceRecord', 'ConvertTo-RecordDate', 'Get-ManifestActionStepId', 'Get-EnabledManifestSteps', 'Get-DeviceInventoryInterval', 'Test-DeviceInventoryEligible', 'Get-IntuneInventoryFieldSetVersion', 'Test-DeviceInventoryDetailMissing', 'Invoke-DeviceInventoryCheck', 'Invoke-DeviceInventoryPolling', 'Clear-GraphReadPrefetch')) {
            $definition = $sourceAst.Find({ param($node) $node -is [System.Management.Automation.Language.FunctionDefinitionAst] -and $node.Name -eq $functionName }, $true)
            Set-Item -Path ('Function:{0}' -f $definition.Name) -Value $definition.Body.GetScriptBlock()
        }
        function Get-LiveDeviceInventory { param($Device) throw ('Unexpected inventory read: {0}' -f $Device.Serial) }
        # Batching is proven by GraphCallBudget.Tests.ps1; here reads stay on the mocked Get-LiveDeviceInventory.
        function Invoke-DeviceInventoryPrefetch { return 0 }
        function Write-UserDeviceRecords { param($Records) throw ('Unexpected inventory save: {0}' -f @($Records).Count) }
    }
    BeforeEach {
        $script:Runtime = @{ IsDemoMode = $false }
        $script:Config = @{ InventoryPollingMinutes = 5 }
        $script:GraphSession = @{ Connected = $true; RequiresReconnect = $false }
        $script:StepManifest = @(@{ Id = 'CUSTOM-RESEAL'; ActionName = 'ConfirmReseal'; Enabled = $true })
        $script:inventoryRecord = New-EmptyDeviceRecord
        $script:inventoryRecord.RecordId = 'record-1'
        $script:inventoryRecord.Serial = 'SERIAL1'
        $script:inventoryRecord.TenantId = 'tenant-1'
        $script:inventoryRecord.ManagedDeviceId = 'managed-1'
        $script:inventoryRecord.BuildCycleId = 'cycle-1'
        $script:inventoryRecord.Steps['CUSTOM-RESEAL'] = @{ Success = $true; CompletionState = 'TechnicianConfirmed' }
        $script:metadata = @{ IntuneHostName = 'IMAGED-PC-01'; EthernetMacAddress = 'AA:BB:CC:DD:EE:FF'; ManagedDeviceId = 'managed-1'; TenantId = 'tenant-1'; LastSyncDateTime = '2026-10-22T10:00:00Z' }
        $script:checkTime = [datetime]'2026-10-22T12:00:00Z'
        Mock Get-LiveDeviceInventory { return $script:metadata }
        Mock Write-UserDeviceRecords {}
        Mock Write-Host {}
        Mock Write-AutopilotExpressLog {}
    }
    It 'validates the central polling interval before permitting reads' {
        Get-DeviceInventoryInterval | Should -Be 5
        foreach ($invalid in @('5', 0, -1, 1441, 1.5, $false)) {
            $script:Config.InventoryPollingMinutes = $invalid
            { Get-DeviceInventoryInterval } | Should -Throw '*InventoryPollingMinutes*'
        }
    }
    It 'uses semantic reseal eligibility rather than a hardcoded G ID' {
        Test-DeviceInventoryEligible -Device $script:inventoryRecord | Should -BeTrue
        $script:inventoryRecord.Steps.Clear()
        Test-DeviceInventoryEligible -Device $script:inventoryRecord | Should -BeFalse
    }
    It 'does not read before the physical milestone' {
        $script:inventoryRecord.Steps.Clear()
        Invoke-DeviceInventoryCheck -Device $script:inventoryRecord -Now $script:checkTime | Should -BeFalse
        Should -Invoke Get-LiveDeviceInventory -Times 0 -Exactly
    }
    It 'populates both fields and retains identity cycle and check provenance' {
        Invoke-DeviceInventoryCheck -Device $script:inventoryRecord -Now $script:checkTime | Should -BeTrue
        $script:inventoryRecord.IntuneInventory.Status | Should -Be 'Available'
        $script:inventoryRecord.IntuneInventory.IntuneHostName | Should -Be 'IMAGED-PC-01'
        $script:inventoryRecord.IntuneInventory.EthernetMacAddress | Should -Be 'AA:BB:CC:DD:EE:FF'
        $script:inventoryRecord.IntuneInventory.BuildCycleId | Should -Be 'cycle-1'
        $script:inventoryRecord.IntuneInventory.CheckedAt | Should -Be $script:checkTime.ToString('o')
    }
    It 'retries partial inventory only at the five-minute boundary' {
        $script:metadata.EthernetMacAddress = ''
        $null = Invoke-DeviceInventoryCheck -Device $script:inventoryRecord -Now $script:checkTime
        Invoke-DeviceInventoryCheck -Device $script:inventoryRecord -Now $script:checkTime.AddSeconds(299) | Should -BeFalse
        Invoke-DeviceInventoryCheck -Device $script:inventoryRecord -Now $script:checkTime.AddMinutes(5) | Should -BeTrue
        Should -Invoke Get-LiveDeviceInventory -Times 2 -Exactly
    }
    It 'stops regular reads when complete but forces a final dispatch-time read' {
        $null = Invoke-DeviceInventoryCheck -Device $script:inventoryRecord -Now $script:checkTime
        Invoke-DeviceInventoryCheck -Device $script:inventoryRecord -Now $script:checkTime.AddMinutes(5) | Should -BeFalse
        Invoke-DeviceInventoryCheck -Device $script:inventoryRecord -Now $script:checkTime -Force | Should -BeTrue
        Should -Invoke Get-LiveDeviceInventory -Times 2 -Exactly
    }
    It 'retains collected values after a transient empty final response' {
        $null = Invoke-DeviceInventoryCheck -Device $script:inventoryRecord -Now $script:checkTime
        $script:metadata.IntuneHostName = ''; $script:metadata.EthernetMacAddress = ''
        $null = Invoke-DeviceInventoryCheck -Device $script:inventoryRecord -Now $script:checkTime -Force
        $script:inventoryRecord.IntuneInventory.Status | Should -Be 'Available'
        $script:inventoryRecord.IntuneInventory.IntuneHostName | Should -Be 'IMAGED-PC-01'
        $script:inventoryRecord.IntuneInventory.EthernetMacAddress | Should -Be 'AA:BB:CC:DD:EE:FF'
    }
    It 'does not reuse inventory from a different current managed-device identity' {
        $null = Invoke-DeviceInventoryCheck -Device $script:inventoryRecord -Now $script:checkTime
        $script:inventoryRecord.ManagedDeviceId = 'managed-new'
        Mock Get-LiveDeviceInventory { return $null }
        $null = Invoke-DeviceInventoryCheck -Device $script:inventoryRecord -Now $script:checkTime -Force
        $script:inventoryRecord.IntuneInventory.Status | Should -Be 'Pending'
        $script:inventoryRecord.IntuneInventory.IntuneHostName | Should -BeExactly ''
    }
    It 'does not treat a cached Autopilot display name as captured inventory' {
        $script:inventoryRecord.IntuneDeviceName = 'OLD-AUTOPILOT-LABEL'
        Mock Get-LiveDeviceInventory { return $null }
        $null = Invoke-DeviceInventoryCheck -Device $script:inventoryRecord -Now $script:checkTime
        $script:inventoryRecord.IntuneInventory.IntuneHostName | Should -BeExactly ''
    }
    It 'records a read error without erasing good same-cycle evidence' {
        $null = Invoke-DeviceInventoryCheck -Device $script:inventoryRecord -Now $script:checkTime
        Mock Get-LiveDeviceInventory { throw 'Synthetic inventory read failure' }
        $null = Invoke-DeviceInventoryCheck -Device $script:inventoryRecord -Now $script:checkTime -Force
        $script:inventoryRecord.IntuneInventory.Status | Should -Be 'Error'
        $script:inventoryRecord.IntuneInventory.IntuneHostName | Should -Be 'IMAGED-PC-01'
        Should -Invoke Write-AutopilotExpressLog -Times 1 -Exactly -ParameterFilter { $Level -eq 'WARN' -and $Message -like '*retry remains scheduled*Synthetic inventory read failure*' }
    }
    It 'never starts regular reads in Demo or when explicit reconnection is required' {
        $script:Runtime.IsDemoMode = $true
        Invoke-DeviceInventoryCheck -Device $script:inventoryRecord -Now $script:checkTime | Should -BeFalse
        $script:Runtime.IsDemoMode = $false; $script:GraphSession.RequiresReconnect = $true
        Invoke-DeviceInventoryCheck -Device $script:inventoryRecord -Now $script:checkTime | Should -BeFalse
        Should -Invoke Get-LiveDeviceInventory -Times 0 -Exactly
    }
    It 'publishes and announces availability only after the detached proposal was saved' {
        $records = @{ Value = @($script:inventoryRecord) }
        Mock Write-UserDeviceRecords {
            $script:inventoryRecord.IntuneInventory.Count | Should -Be 0
            @($Records)[0].IntuneInventory.Status | Should -Be 'Available'
        }
        Invoke-DeviceInventoryPolling -Records $records
        $script:inventoryRecord.IntuneInventory.Status | Should -Be 'Available'
        Should -Invoke Write-UserDeviceRecords -Times 1 -Exactly
        Should -Invoke Write-Host -Times 1 -Exactly -ParameterFilter { $Object -like '*Inventory available*SERIAL1*' }
    }
    It 'does not publish or announce a metadata snapshot whose save failed' {
        $records = @{ Value = @($script:inventoryRecord) }
        Mock Write-UserDeviceRecords { throw 'Synthetic inventory save failure' }
        { Invoke-DeviceInventoryPolling -Records $records } | Should -Throw '*inventory save failure*'
        $script:inventoryRecord.IntuneInventory.Count | Should -Be 0
        Should -Invoke Write-Host -Times 0 -Exactly
    }
    It 'skips idle scans until the exact five-minute boundary with a prompt-local schedule' {
        $script:inventoryRecord.IntuneInventory = @{ IntuneHostName = 'IMAGED-PC-01'; EthernetMacAddress = ''; BuildCycleId = 'cycle-1'; TenantId = 'tenant-1'; ManagedDeviceId = 'managed-1'; CheckedAt = $script:checkTime.ToString('o') }
        Mock Test-DeviceInventoryEligible { return $true }
        $records = @{ Value = @($script:inventoryRecord) }
        $schedule = @{}
        Invoke-DeviceInventoryPolling -Records $records -Schedule $schedule -Now $script:checkTime
        Invoke-DeviceInventoryPolling -Records $records -Schedule $schedule -Now $script:checkTime.AddSeconds(299)
        Should -Invoke Test-DeviceInventoryEligible -Times 1 -Exactly
        Should -Invoke Get-LiveDeviceInventory -Times 0 -Exactly
        Invoke-DeviceInventoryPolling -Records $records -Schedule $schedule -Now $script:checkTime.AddMinutes(5)
        Should -Invoke Get-LiveDeviceInventory -Times 1 -Exactly
        Should -Invoke Write-UserDeviceRecords -Times 1 -Exactly
    }
    It 'rechecks a replaced record collection rather than retaining an empty idle schedule' {
        $records = @{ Value = @() }
        $schedule = @{}
        Invoke-DeviceInventoryPolling -Records $records -Schedule $schedule
        $records.Value = @($script:inventoryRecord)
        Invoke-DeviceInventoryPolling -Records $records -Schedule $schedule
        Should -Invoke Get-LiveDeviceInventory -Times 1 -Exactly
    }
    It 'discards prompt-local eligibility after a command confirms the reseal milestone' {
        $script:inventoryRecord.Steps.Clear()
        $records = @{ Value = @($script:inventoryRecord) }
        Invoke-DeviceInventoryPolling -Records $records -Schedule @{}
        Should -Invoke Get-LiveDeviceInventory -Times 0 -Exactly
        $script:inventoryRecord.Steps['CUSTOM-RESEAL'] = @{ Success = $true; CompletionState = 'TechnicianConfirmed' }
        Invoke-DeviceInventoryPolling -Records $records -Schedule @{}
        Should -Invoke Get-LiveDeviceInventory -Times 1 -Exactly
    }
    It 'invalidates an idle deadline after a backwards clock change' {
        $script:inventoryRecord.IntuneInventory = @{ IntuneHostName = ''; EthernetMacAddress = ''; BuildCycleId = 'cycle-1'; TenantId = 'tenant-1'; ManagedDeviceId = 'managed-1'; CheckedAt = $script:checkTime.ToString('o') }
        $records = @{ Value = @($script:inventoryRecord) }
        $schedule = @{}
        Invoke-DeviceInventoryPolling -Records $records -Schedule $schedule -Now $script:checkTime
        Invoke-DeviceInventoryPolling -Records $records -Schedule $schedule -Now $script:checkTime.AddMinutes(-1)
        Should -Invoke Get-LiveDeviceInventory -Times 1 -Exactly
    }
    It 'does not delay fresh inventory for a changed managed-device identity using an old timestamp' {
        $script:inventoryRecord.IntuneInventory = @{ IntuneHostName = 'OLD-PC'; EthernetMacAddress = 'AA:BB:CC:DD:EE:FF'; BuildCycleId = 'cycle-1'; TenantId = 'tenant-1'; ManagedDeviceId = 'managed-old'; CheckedAt = (Get-Date).ToString('o') }
        Invoke-DeviceInventoryPolling -Records @{ Value = @($script:inventoryRecord) }
        Should -Invoke Get-LiveDeviceInventory -Times 1 -Exactly
        $script:inventoryRecord.IntuneInventory.ManagedDeviceId | Should -BeExactly 'managed-1'
    }
    It 'refuses ambiguous due record IDs before any tenant read or persistence' {
        $other = ConvertTo-NormalisedValue -Value $script:inventoryRecord
        $other.Serial = 'SERIAL2'
        { Invoke-DeviceInventoryPolling -Records @{ Value = @($script:inventoryRecord, $other) } } | Should -Throw '*unique non-empty workflow record IDs*'
        Should -Invoke Get-LiveDeviceInventory -Times 0 -Exactly
        Should -Invoke Write-UserDeviceRecords -Times 0 -Exactly
    }
    It 'treats a device as needing details until the current detail set is complete' {
        $script:inventoryRecord.IntuneInventory = @{}
        Test-DeviceInventoryDetailMissing -Device $script:inventoryRecord | Should -BeTrue
        $script:inventoryRecord.IntuneInventory = @{ IntuneHostName = 'PC'; EthernetMacAddress = 'AA:BB:CC:DD:EE:FF'; EntraDeviceId = 'e'; OsVersion = '10.0.26100.1' }
        Test-DeviceInventoryDetailMissing -Device $script:inventoryRecord | Should -BeTrue -Because 'records saved before version 2 are checked once more'
        $script:inventoryRecord.IntuneInventory.FieldSetVersion = '2'
        Test-DeviceInventoryDetailMissing -Device $script:inventoryRecord | Should -BeFalse -Because 'a blank Wi-Fi MAC or primary user never forces a recheck'
        $script:inventoryRecord.IntuneInventory.OsVersion = ''
        Test-DeviceInventoryDetailMissing -Device $script:inventoryRecord | Should -BeTrue
        $script:inventoryRecord.IntuneInventory.Status = 'NotFound'
        Test-DeviceInventoryDetailMissing -Device $script:inventoryRecord | Should -BeFalse
        Test-DeviceInventoryDetailMissing -Device $script:inventoryRecord -IncludeNotFound | Should -BeTrue
    }
    It 'stamps the field-set version and keeps optional details from a successful read' {
        $script:metadata.WiFiMacAddress = '10:20:30:40:50:60'; $script:metadata.OsRelease = 'Windows 11 25H2'
        $null = Invoke-DeviceInventoryCheck -Device $script:inventoryRecord -Now $script:checkTime -Force
        $script:inventoryRecord.IntuneInventory.FieldSetVersion | Should -BeExactly '2'
        $script:inventoryRecord.IntuneInventory.WiFiMacAddress | Should -BeExactly '10:20:30:40:50:60'
        $script:inventoryRecord.IntuneInventory.OsRelease | Should -BeExactly 'Windows 11 25H2'
    }
    It 'marks a device with no managed record as NotFound only when asked, keeping saved values' {
        $script:inventoryRecord.IntuneInventory = @{ IntuneHostName = 'SAVED-PC'; EthernetMacAddress = 'AA:BB:CC:DD:EE:FF'; ManagedDeviceId = 'managed-1'; TenantId = 'tenant-1'; BuildCycleId = 'cycle-1'; Status = 'Available' }
        Mock Get-LiveDeviceInventory { return $null }
        $null = Invoke-DeviceInventoryCheck -Device $script:inventoryRecord -Now $script:checkTime -Force -MarkMissingAsNotFound
        $script:inventoryRecord.IntuneInventory.Status | Should -BeExactly 'NotFound'
        $script:inventoryRecord.IntuneInventory.IntuneHostName | Should -BeExactly 'SAVED-PC'
    }
    It 'marks a deleted managed device (HTTP 404) as NotFound without a warning' {
        function Get-GraphTransportFailure { return @{ Status = '404' } }
        Mock Get-LiveDeviceInventory { throw 'Synthetic not found' }
        $null = Invoke-DeviceInventoryCheck -Device $script:inventoryRecord -Now $script:checkTime -Force -MarkMissingAsNotFound
        $script:inventoryRecord.IntuneInventory.Status | Should -BeExactly 'NotFound'
        Should -Invoke Write-AutopilotExpressLog -Times 0 -Exactly -ParameterFilter { $Level -eq 'WARN' }
    }
    It 'keeps saved archive values whose build cycle predates the current rules' {
        $script:inventoryRecord.IntuneInventory = @{ IntuneHostName = 'OLD-ARCHIVE-PC'; EthernetMacAddress = 'AA:BB:CC:DD:EE:FF'; ManagedDeviceId = 'managed-1'; TenantId = 'tenant-1' }
        $script:metadata.IntuneHostName = ''; $script:metadata.EthernetMacAddress = ''; $script:metadata.OsVersion = '10.0.26100.1'
        $null = Invoke-DeviceInventoryCheck -Device $script:inventoryRecord -Now $script:checkTime -Force -MarkMissingAsNotFound
        $script:inventoryRecord.IntuneInventory.IntuneHostName | Should -BeExactly 'OLD-ARCHIVE-PC'
        $script:inventoryRecord.IntuneInventory.OsVersion | Should -BeExactly '10.0.26100.1'
        $script:inventoryRecord.IntuneInventory.BuildCycleId | Should -BeExactly 'cycle-1'
        $script:inventoryRecord.IntuneInventory.Status | Should -BeExactly 'Available'
    }
}

Describe 'Updating device details from Intune for processed devices' {
    BeforeAll {
        foreach ($functionName in @('Get-ArchivedDeviceRecordFile', 'Update-DeviceInventoryFromIntune', 'Test-DeviceInventoryDetailMissing', 'Get-IntuneInventoryFieldSetVersion', 'Test-AttemptEvidenceEqual', 'Write-Utf8File', 'Clear-GraphReadPrefetch')) {
            $definition = $sourceAst.Find({ param($node) $node -is [System.Management.Automation.Language.FunctionDefinitionAst] -and $node.Name -eq $functionName }, $true)
            if (-not $definition) { throw ('Missing backfill function: {0}' -f $functionName) }
            Set-Item -Path ('Function:{0}' -f $definition.Name) -Value $definition.Body.GetScriptBlock()
        }
        function Get-ArchiveFolderPath { return $script:archiveFolder }
        function New-ParentDirectory {
            [CmdletBinding(SupportsShouldProcess)]
            param([string]$Path)
            if ($PSCmdlet.ShouldProcess($Path, 'Create simulated parent folder')) { $script:createdParents += $Path }
        }
        function Get-StorageFileEncoding { return 'utf8' }
        function Invoke-DeviceInventoryCheck { param($Device, [switch]$Force, [switch]$MarkMissingAsNotFound) throw ('Unexpected check: {0}; force={1}; mark-missing={2}' -f $Device.Serial, $Force, $MarkMissingAsNotFound) }
        function Write-UserDeviceRecords { param($Records) throw ('Unexpected session save: {0}' -f @($Records).Count) }
        # Batching is proven by GraphCallBudget.Tests.ps1; here reads stay on the mocked Get-LiveDeviceInventory.
        function Invoke-DeviceInventoryPrefetch { return 0 }
        $script:fullDetails = @{ IntuneHostName = 'PC-01'; EthernetMacAddress = 'AA:BB:CC:DD:EE:FF'; EntraDeviceId = 'entra-1'; OsVersion = '10.0.26100.1'; FieldSetVersion = '2'; Status = 'Available' }
    }
    BeforeEach {
        $script:Runtime = @{ IsDemoMode = $false }
        $script:Config = @{ UserDataFilePrefix = 'autopilot-devices' }
        $script:GraphSession = @{ Connected = $true; RequiresReconnect = $false; IsSimulated = $false; TenantId = 'tenant-1' }
        $script:archiveFolder = Join-Path $TestDrive ('archive-{0}' -f [guid]::NewGuid())
        New-Item -ItemType Directory -Path $script:archiveFolder | Out-Null
        $script:archiveName = 'autopilot-devices-autopilot-devices-tech-session-live-20260101-090000-11111111-2222-3333-4444-555555555555.json'
        $script:archivePath = Join-Path $script:archiveFolder $script:archiveName
        # Raw JSON keeps exact date text and an extra field the update must not touch.
        $script:archiveJson = '[{"RecordId":"a-1","Serial":"ARCH1","TenantId":"tenant-1","Status":"completed","StartedAt":"2026-01-01T09:00:00.1234567+10:00","Notes":"keep me","IntuneInventory":{"IntuneHostName":"","EthernetMacAddress":"","Status":"Pending"}}]'
        Set-Content -LiteralPath $script:archivePath -Value $script:archiveJson -NoNewline -Encoding utf8
        Mock Assert-FileWriteRecoveryState {}
        Mock Write-AutopilotExpressLog {}
        Mock Write-Progress {}
        Mock Write-UserDeviceRecords {}
        Mock Invoke-DeviceInventoryCheck { $Device.IntuneInventory = @{ IntuneHostName = 'FOUND-PC'; EthernetMacAddress = '10:20:30:40:50:60'; EntraDeviceId = 'entra-9'; OsVersion = '10.0.26200.1'; FieldSetVersion = '2'; Status = 'Available' }; return $true }
    }
    It 'lists only Live device archives' {
        foreach ($name in @('autopilot-devices-demo-tech-demo-20260101-090000-11111111-2222-3333-4444-555555555555.json', 'autopilot-bench-tech-live-20260101-090000-11111111-2222-3333-4444-555555555555.json', ('{0}.previous' -f $script:archiveName), ('{0}.before-intune-details-20260101-100000' -f $script:archiveName))) {
            Set-Content -LiteralPath (Join-Path $script:archiveFolder $name) -Value '[]'
        }
        @(Get-ArchivedDeviceRecordFile).Name | Should -BeExactly @($script:archiveName)
    }
    It 'refuses to run in Demo mode or without a Live Graph connection' {
        $script:Runtime.IsDemoMode = $true
        { Update-DeviceInventoryFromIntune -Records @{ Value = @() } } | Should -Throw '*Demo*'
        $script:Runtime.IsDemoMode = $false; $script:GraphSession.Connected = $false
        { Update-DeviceInventoryFromIntune -Records @{ Value = @() } } | Should -Throw '*connected*'
        Should -Invoke Invoke-DeviceInventoryCheck -Times 0 -Exactly
    }
    It 'updates only the Intune details in an archive, keeping dates, other fields and a dated backup' -Skip:($PSVersionTable.PSEdition -eq 'Core' -and -not (Get-Command ConvertFrom-Json).Parameters.ContainsKey('DateKind')) {
        $summary = Update-DeviceInventoryFromIntune -Records @{ Value = @() }
        $summary.Updated | Should -Be 1
        $summary.ArchiveFilesUpdated | Should -Be 1
        $saved = Get-Content -LiteralPath $script:archivePath -Raw
        $saved | Should -Match ([regex]::Escape('2026-01-01T09:00:00.1234567+10:00'))
        $saved | Should -Match 'keep me'
        $saved | Should -Match 'FOUND-PC'
        $backup = @(Get-ChildItem -LiteralPath $script:archiveFolder -Filter ('{0}.before-intune-details-*' -f $script:archiveName))
        $backup.Count | Should -Be 1
        (Get-Content -LiteralPath $backup[0].FullName -Raw) | Should -BeExactly $script:archiveJson
        Should -Invoke Invoke-DeviceInventoryCheck -Times 1 -Exactly -ParameterFilter { $Force -and $MarkMissingAsNotFound }
    }
    It 'makes no Graph request for complete, untenanted or other-tenant devices and does not rewrite unchanged files' {
        $records = @{ Value = @(
                @{ RecordId = 'c-1'; Serial = 'DONE1'; TenantId = 'tenant-1'; Status = 'completed'; IntuneInventory = $script:fullDetails.Clone() }
                @{ RecordId = 'c-2'; Serial = 'NOTEN'; TenantId = ''; Status = 'completed'; IntuneInventory = @{} }
                @{ RecordId = 'c-3'; Serial = 'OTHER'; TenantId = 'tenant-2'; Status = 'completed'; IntuneInventory = @{} }
            ) }
        Remove-Item -LiteralPath $script:archivePath
        $summary = Update-DeviceInventoryFromIntune -Records $records
        $summary.AlreadyComplete | Should -Be 1
        $summary.NoTenant | Should -Be 1
        $summary.OtherTenant | Should -Be 1
        Should -Invoke Invoke-DeviceInventoryCheck -Times 0 -Exactly
        Should -Invoke Write-UserDeviceRecords -Times 0 -Exactly
    }
    It 'saves the current session through the normal save and publishes after it succeeds' {
        Remove-Item -LiteralPath $script:archivePath
        $original = @{ RecordId = 's-1'; Serial = 'SESS1'; TenantId = 'tenant-1'; Status = 'in-progress'; IntuneInventory = @{} }
        $summary = Update-DeviceInventoryFromIntune -Records @{ Value = @($original) }
        $summary.Updated | Should -Be 1
        $original.IntuneInventory.IntuneHostName | Should -BeExactly 'FOUND-PC'
        Should -Invoke Write-UserDeviceRecords -Times 1 -Exactly
        Should -Invoke Invoke-DeviceInventoryCheck -Times 1 -Exactly -ParameterFilter { -not $MarkMissingAsNotFound } -Because 'active devices may simply not be enrolled yet'
    }
    It 'leaves an archive untouched when it changed on disk during the run' -Skip:($PSVersionTable.PSEdition -eq 'Core' -and -not (Get-Command ConvertFrom-Json).Parameters.ContainsKey('DateKind')) {
        Mock Invoke-DeviceInventoryCheck {
            Add-Content -LiteralPath $script:archivePath -Value ' '
            $Device.IntuneInventory = @{ IntuneHostName = 'FOUND-PC'; Status = 'Available' }
            return $true
        }
        $summary = Update-DeviceInventoryFromIntune -Records @{ Value = @() }
        $summary.ArchiveFilesUpdated | Should -Be 0
        $summary.ArchiveFilesSkipped | Should -Be 1
        (Get-Content -LiteralPath $script:archivePath -Raw) | Should -Not -Match 'FOUND-PC'
    }
}

Describe 'Data Settings menu offers the Intune detail update' {
    It 'lists option 5 with the IntuneDetails action' {
        $definition = $sourceAst.Find({ param($node) $node -is [System.Management.Automation.Language.FunctionDefinitionAst] -and $node.Name -eq 'Get-MainMenuDefinition' }, $true)
        $definition.Extent.Text | Should -Match ([regex]::Escape("@{ Key = '5'; Action = 'IntuneDetails';"))
        $sourceAst.Extent.Text | Should -Match ([regex]::Escape("'IntuneDetails' { Show-DeviceInventoryBackfill -Records `$records }"))
    }
}

Describe 'Actual idle prompt runspace' {
    It 'services idle polling before input and handles synthetic failure=<Fail> without executing a command' -ForEach @(@{ Fail = $false }, @{ Fail = $true }) {
        $definition = $sourceAst.Find({ param($node) $node -is [System.Management.Automation.Language.FunctionDefinitionAst] -and $node.Name -eq 'Read-DeviceInventoryInput' }, $true)
        $childScript = $definition.Extent.Text + [Environment]::NewLine + ('$script:FailOnTick = ${0}' -f ([string]$Fail).ToLowerInvariant()) + [Environment]::NewLine + @'
function Invoke-DeviceInventoryPolling {
    param($Records, $Schedule)
    $script:Ticks++
    if ($script:Ticks -eq 2) {
        [Console]::WriteLine('IDLE-TICK')
        if ($script:FailOnTick) { throw 'SYNTHETIC-POLL-FAILURE' }
    }
}
$script:Ticks = 0
try {
    $response = Read-DeviceInventoryInput -Prompt 'Synthetic scanner input' -Records @{ Value = @() }
    [Console]::WriteLine(('RESULT:{0};TICKS:{1}' -f $response, $script:Ticks))
}
catch { [Console]::WriteLine(('CAUGHT:{0}' -f $_.Exception.Message)) }
'@
        $startInfo = New-Object System.Diagnostics.ProcessStartInfo
        $startInfo.FileName = (Get-Process -Id $PID).Path
        $startInfo.Arguments = '-NoProfile -EncodedCommand {0}' -f [Convert]::ToBase64String([Text.Encoding]::Unicode.GetBytes($childScript))
        $startInfo.UseShellExecute = $false
        $startInfo.RedirectStandardInput = $true
        $startInfo.RedirectStandardOutput = $true
        $startInfo.RedirectStandardError = $true
        $process = New-Object System.Diagnostics.Process
        $process.StartInfo = $startInfo
        $started = $false
        try {
            $started = $process.Start()
            $idleLine = $process.StandardOutput.ReadLineAsync()
            $idleLine.Wait(15000) | Should -BeTrue -Because 'inventory must run while the operator has not submitted any input'
            $idleLine.Result | Should -BeLike '*IDLE-TICK*'
            $process.StandardInput.WriteLine('S:SCANNER-123')
            $process.StandardInput.Close()
            $process.WaitForExit(15000) | Should -BeTrue
            $output = $process.StandardOutput.ReadToEnd()
            $errors = $process.StandardError.ReadToEnd()
            $process.ExitCode | Should -Be 0 -Because $errors
            if ($Fail) {
                $output | Should -BeLike '*CAUGHT:SYNTHETIC-POLL-FAILURE*'
                $output | Should -Not -BeLike '*RESULT:*'
            }
            else { $output | Should -BeLike '*RESULT:S:SCANNER-123;TICKS:2*' }
        }
        finally {
            if ($started -and -not $process.HasExited) { $process.Kill() }
            $process.Dispose()
        }
    }

    It 'holds screen and log output from idle polling until the prompt returns, so polling is never stalled by the open prompt' {
        # Regression for the real logs: any host write (Write-Host, verbose or log line) from the
        # main runspace waited for Enter, so idle Intune reads and saves only ran after input.
        $definition = $sourceAst.Find({ param($node) $node -is [System.Management.Automation.Language.FunctionDefinitionAst] -and $node.Name -eq 'Read-DeviceInventoryInput' }, $true)
        $childScript = $definition.Extent.Text + [Environment]::NewLine + @'
function Invoke-DeviceInventoryPolling {
    param($Records, $Schedule)
    $script:Ticks++
    if ($script:Ticks -eq 2) {
        Write-Information -MessageData '[2026-01-01 00:00:00] [INFO] HELD-LOG' -InformationAction Continue
        Write-Verbose 'HELD-VERBOSE'
        Write-Host 'HELD-HOST'
        [Console]::WriteLine('IDLE-TICK-AFTER-OUTPUT')
    }
}
$VerbosePreference = 'Continue'
$script:Ticks = 0
$response = Read-DeviceInventoryInput -Prompt 'Synthetic scanner input' -Records @{ Value = @() }
[Console]::WriteLine(('RESULT:{0}' -f $response))
'@
        $startInfo = New-Object System.Diagnostics.ProcessStartInfo
        $startInfo.FileName = (Get-Process -Id $PID).Path
        $startInfo.Arguments = '-NoProfile -EncodedCommand {0}' -f [Convert]::ToBase64String([Text.Encoding]::Unicode.GetBytes($childScript))
        $startInfo.UseShellExecute = $false
        $startInfo.RedirectStandardInput = $true
        $startInfo.RedirectStandardOutput = $true
        $startInfo.RedirectStandardError = $true
        $process = New-Object System.Diagnostics.Process
        $process.StartInfo = $startInfo
        $started = $false
        try {
            $started = $process.Start()
            $errorText = $process.StandardError.ReadToEndAsync()
            $idleLine = $process.StandardOutput.ReadLineAsync()
            $idleLine.Wait(15000) | Should -BeTrue -Because 'polling that writes to the screen must still finish while no input has been submitted'
            $idleLine.Result | Should -BeLike '*IDLE-TICK-AFTER-OUTPUT*'
            $process.StandardInput.WriteLine('S:SCANNER-456')
            $process.StandardInput.Close()
            $process.WaitForExit(15000) | Should -BeTrue
            $output = $process.StandardOutput.ReadToEnd()
            $process.ExitCode | Should -Be 0 -Because $errorText.Result
            # A child started with -EncodedCommand writes verbose lines to its error stream.
            $errorText.Result | Should -Match 'HELD-VERBOSE' -Because 'held verbose lines are replayed once the prompt returns'
            $logAt = $output.IndexOf('HELD-LOG')
            $hostAt = $output.IndexOf('HELD-HOST')
            $resultAt = $output.IndexOf('RESULT:S:SCANNER-456')
            $logAt | Should -BeGreaterOrEqual 0 -Because 'held log lines are shown once the prompt returns'
            $hostAt | Should -BeGreaterThan $logAt -Because 'held lines keep their original order'
            $resultAt | Should -BeGreaterThan $hostAt -Because 'held lines appear before the submitted input is acted on'
        }
        finally {
            if ($started -and -not $process.HasExited) { $process.Kill() }
            $process.Dispose()
        }
    }
}

Describe 'Narrow tag and membership identity reads' {
    BeforeAll {
        foreach ($functionName in @('Get-LiveAutopilotDeviceById', 'Resolve-LiveAutopilotTagContext', 'Resolve-LiveMembershipContext', 'Get-StoredEntraDeviceObject')) {
            $definition = $sourceAst.Find({ param($node) $node -is [System.Management.Automation.Language.FunctionDefinitionAst] -and $node.Name -eq $functionName }, $true)
            Set-Item -Path ('Function:{0}' -f $definition.Name) -Value $definition.Body.GetScriptBlock()
        }
    }
    BeforeEach {
        $script:narrowDevice = @{ Serial = 'SERIAL1'; TenantId = 'tenant-1'; AutopilotDeviceId = 'auto-1'; ManagedDeviceId = 'managed-retained'; EntraDeviceId = 'old-object'; AzureAdDeviceId = 'old-registration' }
        $script:narrowIdentity = @{ id = 'auto-1'; serialNumber = 'SERIAL1'; groupTag = 'SITE-Desktop'; azureActiveDirectoryDeviceId = 'registration-1' }
        Mock Get-LiveTenantBinding { return 'tenant-1' }
        Mock Invoke-GraphApiRequest {
            if ($Uri -eq 'https://graph.microsoft.com/v1.0/deviceManagement/windowsAutopilotDeviceIdentities/auto-1') { return $script:narrowIdentity }
            if ($Uri -like 'https://graph.microsoft.com/v1.0/devices?*') { return @{ value = @(@{ id = 'current-object'; deviceId = 'registration-1' }) } }
            throw ('Unnecessary identity read: {0}' -f $Uri)
        }
    }
    It 'validates a saved Autopilot ID and serial with exactly one stable resource read' {
        (Resolve-LiveAutopilotTagContext -Device $script:narrowDevice).groupTag | Should -BeExactly 'SITE-Desktop'
        Should -Invoke Invoke-GraphApiRequest -Times 1 -Exactly
        Should -Invoke Get-LiveTenantBinding -Times 1 -Exactly
        $script:narrowDevice.ManagedDeviceId | Should -BeExactly 'managed-retained'
        $script:narrowDevice.EntraDeviceId | Should -BeExactly 'old-object'
    }
    It 'refuses a wrong <Field> before changing a selected tag identity' -ForEach @(
        @{ Field = 'id'; Value = 'wrong-id' }, @{ Field = 'serialNumber'; Value = 'wrong-serial' }
    ) {
        $script:narrowIdentity[$Field] = $Value
        $before = $script:narrowDevice | ConvertTo-Json -Compress
        { Resolve-LiveAutopilotTagContext -Device $script:narrowDevice } | Should -Throw
        ($script:narrowDevice | ConvertTo-Json -Compress) | Should -BeExactly $before
        Should -Invoke Invoke-GraphApiRequest -Times 1 -Exactly
    }
    It 'refreshes membership identity with two reads and no managed-device query' {
        (Resolve-LiveMembershipContext -Device $script:narrowDevice).id | Should -BeExactly 'current-object'
        $script:narrowDevice.EntraDeviceId | Should -BeExactly 'current-object'
        $script:narrowDevice.ManagedDeviceId | Should -BeExactly 'managed-retained'
        Should -Invoke Invoke-GraphApiRequest -Times 2 -Exactly
        Should -Invoke Invoke-GraphApiRequest -Times 0 -Exactly -ParameterFilter { $Uri -like '*/beta/*' -or $Uri -like '*managedDevices*' }
    }
    It 'does not publish a partially refreshed identity after an Entra read failure' {
        Mock Invoke-GraphApiRequest { throw 'Synthetic Entra read failure.' } -ParameterFilter { $Uri -like 'https://graph.microsoft.com/v1.0/devices?*' }
        $before = $script:narrowDevice | ConvertTo-Json -Compress
        { Resolve-LiveMembershipContext -Device $script:narrowDevice } | Should -Throw '*Entra read failure*'
        ($script:narrowDevice | ConvertTo-Json -Compress) | Should -BeExactly $before
    }
}

Describe 'Hardware-hash CSV selection safety' {
    BeforeEach {
        $script:hashRows = @([pscustomobject]@{ 'Device Serial Number' = 'SERIAL1'; 'Hardware Hash' = 'c3ludGhldGlj'; 'Windows Product ID' = '' })
        Mock Get-Item { return @{ PSIsContainer = $false; Extension = '.csv'; Length = 128; FullName = 'synthetic-hash.csv' } }
        Mock Import-Csv { return $script:hashRows }
    }
    It 'returns only the explicitly matched serial and hardware identifier' {
        $row = Get-AutopilotHashRow -Path 'synthetic-hash.csv' -Serial 'serial1'
        $row.Serial | Should -Be 'serial1'
        $row.HardwareIdentifier | Should -Be 'c3ludGhldGlj'
        $row.Count | Should -Be 2
        Should -Invoke Import-Csv -Times 1 -Exactly -ParameterFilter { $LiteralPath -eq 'synthetic-hash.csv' }
    }
    It 'rejects an absent selected serial' {
        { Get-AutopilotHashRow -Path 'synthetic-hash.csv' -Serial 'OTHER' } | Should -Throw '*no row matching*'
    }
    It 'rejects duplicate serials even when their case or surrounding spaces differ' {
        $script:hashRows += [pscustomobject]@{ 'Device Serial Number' = ' serial1 '; 'Hardware Hash' = 'c3ludGhldGlj' }
        { Get-AutopilotHashRow -Path 'synthetic-hash.csv' -Serial 'SERIAL1' } | Should -Throw '*duplicate serial*'
    }
    It 'rejects missing headers' {
        $script:hashRows = @([pscustomobject]@{ Serial = 'SERIAL1'; Hash = 'c3ludGhldGlj' })
        { Get-AutopilotHashRow -Path 'synthetic-hash.csv' -Serial 'SERIAL1' } | Should -Throw '*requires*columns*'
    }
    It 'rejects empty files without returning a candidate' {
        $script:hashRows = @()
        { Get-AutopilotHashRow -Path 'synthetic-hash.csv' -Serial 'SERIAL1' } | Should -Throw '*no device rows*'
    }
    It 'rejects invalid or empty hardware hashes without exposing their content' {
        foreach ($badHash in @('', 'PRIVATE-HASH-NOT-BASE64')) {
            $script:hashRows[0].'Hardware Hash' = $badHash
            { Get-AutopilotHashRow -Path 'synthetic-hash.csv' -Serial 'SERIAL1' } | Should -Throw '*hardware hash*'
        }
    }
    It 'refuses oversized files before parsing their contents' {
        Mock Get-Item { return @{ PSIsContainer = $false; Extension = '.csv'; Length = 8388609 } }
        { Get-AutopilotHashRow -Path 'synthetic-hash.csv' -Serial 'SERIAL1' } | Should -Throw '*8 MiB*'
        Should -Invoke Import-Csv -Times 0 -Exactly
    }
}

Describe 'Actual structured hardware-hash CSV parsing' {
    It 'reads a selected row from a multi-device CSV with quoted commas' {
        $path = Join-Path $TestDrive 'hardware.csv'
        @(
            [pscustomobject]@{ 'Device Serial Number' = 'OTHER'; 'Hardware Hash' = 'b3RoZXI='; 'Windows Product ID' = '' }
            [pscustomobject]@{ 'Device Serial Number' = 'SERIAL1'; 'Hardware Hash' = 'c3ludGhldGlj'; 'Windows Product ID' = 'quoted, product' }
        ) | Export-Csv -LiteralPath $path -NoTypeInformation
        (Get-AutopilotHashRow -Path $path -Serial 'SERIAL1').HardwareIdentifier | Should -Be 'c3ludGhldGlj'
    }
}

Describe 'Hash discovery settings and explicit selection' {
    BeforeEach {
        $script:RuntimeConfig = @{ autopilot = @{ hashImport = @{ enabled = $true; searchDirectories = @('hashes'); filenamePrefixes = @('Autopilot'); includeRemovableMedia = $true; removableSubdirectories = @('', 'HWID') } } }
        Mock Get-RuntimeConfigFilePath { return 'C:\synthetic\autopilot-express.runtime.json' }
        Mock Get-CimInstance { return @{ DeviceID = 'C:' } }
        Mock Test-Path { return $true }
        Mock Get-ChildItem { return @(@{ Name = 'autopilot-one.csv'; FullName = 'C:\synthetic\autopilot-one.csv' }, @{ Name = 'Other.csv'; FullName = 'C:\synthetic\Other.csv' }) }
        Mock Write-Host {}
    }
    It 'keeps older configuration disabled without discovery' {
        $script:RuntimeConfig = @{}
        (Get-AutopilotHashImportSettings).enabled | Should -BeFalse
        $paths = Get-AutopilotHashCandidate
        $paths.Count | Should -Be 0
        Should -Invoke Get-CimInstance -Times 0 -Exactly
    }
    It 'discovers configured and removable folders without recursion or duplicate paths' {
        $paths = Get-AutopilotHashCandidate
        $paths.Count | Should -Be 1
        $paths[0] | Should -Be 'C:\synthetic\autopilot-one.csv'
        Should -Invoke Get-ChildItem -Times 1 -Exactly -ParameterFilter { $LiteralPath -eq 'C:\' }
        Should -Invoke Get-ChildItem -Times 1 -Exactly -ParameterFilter { $LiteralPath -eq 'C:\HWID' }
    }
    It 'refuses removable-directory traversal and wildcard prefixes' {
        $script:RuntimeConfig.autopilot.hashImport.removableSubdirectories = @('..\outside')
        { Get-AutopilotHashImportSettings } | Should -Throw '*relative*'
        $script:RuntimeConfig.autopilot.hashImport.removableSubdirectories = @('')
        $script:RuntimeConfig.autopilot.hashImport.filenamePrefixes = @('Auto*')
        { Get-AutopilotHashImportSettings } | Should -Throw '*literal*'
    }
    It 'cancels explicit file selection without reading a hash' {
        Mock Read-ValidatedInput { return '0' }
        Mock Get-AutopilotHashRow { throw 'No row should be read.' }
        Select-AutopilotHashRow -Serial 'SERIAL1' | Should -BeNullOrEmpty
        Should -Invoke Get-AutopilotHashRow -Times 0 -Exactly
    }
    It 'accepts a manual path outside discovery prefixes only through row validation' {
        Mock Read-ValidatedInput { return 'C:\manual\custom.csv' }
        Mock Get-AutopilotHashRow { return @{ Serial = $Serial; HardwareIdentifier = 'c3ludGhldGlj' } }
        (Select-AutopilotHashRow -Serial 'SERIAL1').Serial | Should -Be 'SERIAL1'
        Should -Invoke Get-AutopilotHashRow -Times 1 -Exactly -ParameterFilter { $Path -eq 'C:\manual\custom.csv' -and $Serial -eq 'SERIAL1' }
    }
}

Describe 'Hash import ledger ownership validation' {
    BeforeEach {
        $script:Runtime = @{ IsDemoMode = $false }
        $script:fixtureTenantId = '11111111-2222-3333-4444-555555555555'
        $script:GraphSession = @{ Connected = $true; IsSimulated = $false; TenantId = $script:fixtureTenantId }
        $script:RuntimeConfig = @{ graph = @{ expectedTenantId = '' } }
        $script:journalFixture = @{ SchemaVersion = 1; RecordId = 'hash-record'; Serial = 'SERIAL1'; TenantId = $script:fixtureTenantId; ImportId = 'aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee'; AutopilotImportId = ''; State = 'Submitting'; SubmittedAt = '2026-10-13T09:00:00.0000000Z'; RecordedAt = '2026-10-13T09:00:00.0000000Z' }
        $script:hashDevice = @{ RecordId = 'hash-record'; Serial = 'SERIAL1'; TenantId = $script:fixtureTenantId; ImportSubmissions = @($script:journalFixture) }
        Mock Get-MgContext { return @{ TenantId = $script:fixtureTenantId } }
    }
    It 'reads an existing intent without inferring POST acceptance or returning ledger-only fields' {
        $receipt = Get-AutopilotImportReceipt -Device $script:hashDevice
        $receipt.State | Should -Be Submitting
        $receipt.Count | Should -Be 8
        $receipt.ContainsKey('RecordedAt') | Should -BeFalse
    }
    It 'returns null when the record has no import ledger entries' {
        $script:hashDevice.ImportSubmissions = @()
        Get-AutopilotImportReceipt -Device $script:hashDevice | Should -BeNullOrEmpty
        $script:hashDevice.Remove('ImportSubmissions')
        Get-AutopilotImportReceipt -Device $script:hashDevice | Should -BeNullOrEmpty
    }
    It 'uses the latest append-only entry as the current receipt' {
        $accepted = $script:journalFixture.Clone()
        $accepted.State = 'Accepted'
        $accepted.AutopilotImportId = 'ffffffff-bbbb-cccc-dddd-eeeeeeeeeeee'
        $script:hashDevice.ImportSubmissions = @($script:journalFixture, $accepted)
        $receipt = Get-AutopilotImportReceipt -Device $script:hashDevice
        $receipt.State | Should -Be Accepted
        $receipt.AutopilotImportId | Should -Be 'ffffffff-bbbb-cccc-dddd-eeeeeeeeeeee'
    }
    It 'rejects <Field> ownership changes without retargeting the ledger' -ForEach @(
        @{ Field = 'Serial'; Value = 'OTHER' }
        @{ Field = 'RecordId'; Value = 'other-record' }
        @{ Field = 'TenantId'; Value = 'aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee' }
    ) {
        $script:journalFixture[$Field] = $Value
        { Get-AutopilotImportReceipt -Device $script:hashDevice } | Should -Throw '*target changed*'
    }
    It 'rejects unexpected ledger fields and invalid identifiers' {
        $script:journalFixture.HardwareIdentifier = 'private'
        { Get-AutopilotImportReceipt -Device $script:hashDevice } | Should -Throw '*malformed*'
        $script:journalFixture.Remove('HardwareIdentifier')
        $script:journalFixture.ImportId = '------------------------------------'
        { Get-AutopilotImportReceipt -Device $script:hashDevice } | Should -Throw '*identifiers*'
    }
    It 'refuses ledger-only fields in a legacy journal file shape' {
        { ConvertTo-AutopilotImportReceipt -Value $script:journalFixture } | Should -Throw '*malformed*'
        $script:journalFixture.Remove('RecordedAt')
        (ConvertTo-AutopilotImportReceipt -Value $script:journalFixture).Count | Should -Be 8
    }
}

Describe 'Hash import single-submission and asynchronous evidence' {
    BeforeEach {
        $script:Runtime = @{ IsDemoMode = $false }
        $script:Config = @{ MaxRetryAttempts = 2; RetryBackoffSeconds = 0 }
        $script:fixtureTenantId = '11111111-2222-3333-4444-555555555555'
        $script:GraphSession = @{ Connected = $true; IsSimulated = $false; TenantId = $script:fixtureTenantId }
        $script:RuntimeConfig = @{ graph = @{ expectedTenantId = '' } }
        $script:hashDevice = @{ RecordId = 'hash-record'; Serial = 'SERIAL1'; TenantId = $script:fixtureTenantId; Steps = @{} }
        $script:existingImport = $null
        $script:journalWrites = @()
        $script:importIdentity = 'aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee'
        Mock Get-MgContext { return @{ TenantId = $script:fixtureTenantId } }
        Mock Get-AutopilotImportReceipt { return $script:existingImport }
        Mock Select-AutopilotHashRow { return @{ Serial = 'SERIAL1'; HardwareIdentifier = 'c3ludGhldGlj' } }
        Mock Read-ValidatedInput { return 'Y' }
        Mock Resolve-LiveAutopilotDeviceBySerial { return $null }
        Mock Save-DeviceLedgerEntry { $script:journalWrites += , (ConvertTo-NormalisedValue -Value ($Entry | ConvertTo-Json | ConvertFrom-Json)) }
        Mock Write-Host {}
        Mock Start-Sleep {}
        Mock Invoke-GraphApiRequest {
            if ($Method -eq 'POST') {
                $script:journalWrites.Count | Should -Be 1
                return @{ value = @(@{ id = $script:importIdentity; serialNumber = 'SERIAL1' }) }
            }
            return @{ id = $script:importIdentity; serialNumber = 'SERIAL1'; state = @{ deviceImportStatus = 'pending' } }
        }
    }

    It 'declines import with the default-No prompt without reading files or submitting' {
        Mock Read-ValidatedInput { return 'N' }
        Invoke-AutopilotHashImport -Device $script:hashDevice | Should -BeNullOrEmpty
        Should -Invoke Read-ValidatedInput -Times 1 -Exactly -ParameterFilter { $Default -eq 'N' }
        Should -Invoke Select-AutopilotHashRow -Times 0 -Exactly
        Should -Invoke Invoke-GraphApiRequest -Times 0 -Exactly
        Should -Invoke Save-DeviceLedgerEntry -Times 0 -Exactly
    }

    It 'cancels file selection without creating an intent or submitting' {
        Mock Select-AutopilotHashRow { return $null }
        (Invoke-AutopilotHashImport -Device $script:hashDevice).State | Should -Be Submitted
        Should -Invoke Invoke-GraphApiRequest -Times 0 -Exactly
        Should -Invoke Save-DeviceLedgerEntry -Times 0 -Exactly
    }

    It 'requires separate default-No confirmation of the selected tenant and serial' {
        Mock Read-ValidatedInput { return 'N' } -ParameterFilter { $Prompt -like 'Upload this*' }
        (Invoke-AutopilotHashImport -Device $script:hashDevice).State | Should -Be Submitted
        Should -Invoke Invoke-GraphApiRequest -Times 0 -Exactly
        Should -Invoke Save-DeviceLedgerEntry -Times 0 -Exactly
    }

    It 'persists hash-free intent before one POST and leaves pending service state incomplete' {
        $result = Invoke-AutopilotHashImport -Device $script:hashDevice
        $result.State | Should -Be Submitted
        $script:journalWrites.Count | Should -Be 2
        $script:journalWrites[0].State | Should -Be Submitting
        $script:journalWrites[1].State | Should -Be Accepted
        foreach ($journal in $script:journalWrites) {
            $journal.Count | Should -Be 9
            $journal.Contains('RecordedAt') | Should -BeTrue
            $journal.Contains('HardwareIdentifier') | Should -BeFalse
            ($journal | ConvertTo-Json -Compress) | Should -Not -Match 'c3ludGhldGlj'
        }
        Should -Invoke Invoke-GraphApiRequest -Times 1 -Exactly -ParameterFilter {
            $Method -eq 'POST' -and $Body.importedWindowsAutopilotDeviceIdentities.Count -eq 1 -and
            $Body.importedWindowsAutopilotDeviceIdentities[0].serialNumber -eq 'SERIAL1'
        }
        Should -Invoke Invoke-GraphApiRequest -Times 2 -Exactly -ParameterFilter { $Method -eq 'GET' }
    }

    It 'resumes accepted imports with reads only and distinguishes complete from final presence' {
        $script:existingImport = @{ AutopilotImportId = $script:importIdentity; State = 'Accepted' }
        Mock Invoke-GraphApiRequest { return @{ id = $script:importIdentity; serialNumber = 'SERIAL1'; state = @{ deviceImportStatus = 'complete'; deviceRegistrationId = 'registration-one' } } }
        $result = Invoke-AutopilotHashImport -Device $script:hashDevice
        $result.State | Should -Be Complete
        $result.RegistrationId | Should -Be 'registration-one'
        Should -Invoke Invoke-GraphApiRequest -Times 0 -Exactly -ParameterFilter { $Method -eq 'POST' }
        Should -Invoke Select-AutopilotHashRow -Times 0 -Exactly
        Should -Invoke Read-ValidatedInput -Times 0 -Exactly
    }

    It 'keeps uncertain accepted-response outcomes read-only on subsequent invocation' {
        Mock Invoke-GraphApiRequest { return @{ value = @() } } -ParameterFilter { $Method -eq 'POST' }
        { Invoke-AutopilotHashImport -Device $script:hashDevice } | Should -Throw '*uncertain*'
        $script:existingImport = $script:journalWrites[0]
        Mock Get-GraphDiscoveryCollection { return @() }
        (Invoke-AutopilotHashImport -Device $script:hashDevice).State | Should -Be Submitted
        Should -Invoke Invoke-GraphApiRequest -Times 1 -Exactly -ParameterFilter { $Method -eq 'POST' }
        Should -Invoke Select-AutopilotHashRow -Times 1 -Exactly
    }

    It 'refuses malformed response identifiers without saving acceptance or reading status' {
        Mock Invoke-GraphApiRequest { return @{ value = @(@{ id = '------------------------------------'; serialNumber = 'SERIAL1' }) } }
        { Invoke-AutopilotHashImport -Device $script:hashDevice } | Should -Throw '*uncertain*'
        $script:journalWrites.Count | Should -Be 1
        $script:journalWrites[0].State | Should -Be Submitting
        Should -Invoke Invoke-GraphApiRequest -Times 0 -Exactly -ParameterFilter { $Method -eq 'GET' }
    }

    It 'reconciles one matching saved intent and saves acceptance before read-only polling' {
        $script:existingImport = @{ AutopilotImportId = ''; State = 'Submitting'; ImportId = 'aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee' }
        Mock Get-GraphDiscoveryCollection { return @(@{ id = $script:importIdentity; serialNumber = 'SERIAL1'; importId = $script:existingImport.ImportId }) }
        Mock Invoke-GraphApiRequest {
            $script:journalWrites.Count | Should -Be 1
            $script:journalWrites[0].State | Should -Be Accepted
            return @{ id = $script:importIdentity; serialNumber = 'SERIAL1'; state = @{ deviceImportStatus = 'complete'; deviceRegistrationId = 'registration-one' } }
        }
        (Invoke-AutopilotHashImport -Device $script:hashDevice).State | Should -Be Complete
        Should -Invoke Invoke-GraphApiRequest -Times 0 -Exactly -ParameterFilter { $Method -eq 'POST' }
        Should -Invoke Read-ValidatedInput -Times 0 -Exactly
    }

    It 'keeps accepted <Status> state pending without another upload' -TestCases @(
        @{ Status = 'unknown' }; @{ Status = 'partial' }
    ) {
        param($Status)
        $script:existingImport = @{ AutopilotImportId = $script:importIdentity; State = 'Accepted' }
        $script:observedImportStatus = $Status
        Mock Invoke-GraphApiRequest { return @{ id = $script:importIdentity; serialNumber = 'SERIAL1'; state = @{ deviceImportStatus = $script:observedImportStatus } } }
        (Invoke-AutopilotHashImport -Device $script:hashDevice).State | Should -Be Submitted
        Should -Invoke Invoke-GraphApiRequest -Times 0 -Exactly -ParameterFilter { $Method -eq 'POST' }
    }

    It 'rejects complete import without registration identity' {
        $script:existingImport = @{ AutopilotImportId = $script:importIdentity; State = 'Accepted' }
        Mock Invoke-GraphApiRequest { return @{ id = $script:importIdentity; serialNumber = 'SERIAL1'; state = @{ deviceImportStatus = 'complete' } } }
        { Invoke-AutopilotHashImport -Device $script:hashDevice } | Should -Throw '*no registration identity*'
        Should -Invoke Invoke-GraphApiRequest -Times 0 -Exactly -ParameterFilter { $Method -eq 'POST' }
    }

    It 'refuses a POST when the intent cannot be saved and tags the storage failure' {
        Mock Save-DeviceLedgerEntry { throw 'Synthetic intent write failure' }
        $failure = $null
        try { Invoke-AutopilotHashImport -Device $script:hashDevice } catch { $failure = $_ }
        $failure.Exception.Message | Should -BeLike '*intent write failure*'
        $failure.Exception.Data['AutopilotExpress.HashImportStorageFailure'] | Should -BeTrue
        Should -Invoke Invoke-GraphApiRequest -Times 0 -Exactly
        Should -Invoke Save-DeviceLedgerEntry -Times 1 -Exactly -ParameterFilter { $LedgerName -ceq 'ImportSubmissions' -and $Entry.State -ceq 'Submitting' }
    }

    It 'propagates accepted-receipt save failures without continuing to status reads' {
        Mock Save-DeviceLedgerEntry {
            if ($script:journalWrites.Count -gt 0) { throw 'Synthetic receipt write failure' }
            $script:journalWrites += , (ConvertTo-NormalisedValue -Value ($Entry | ConvertTo-Json | ConvertFrom-Json))
        }
        { Invoke-AutopilotHashImport -Device $script:hashDevice } | Should -Throw '*receipt write failure*'
        Should -Invoke Invoke-GraphApiRequest -Times 1 -Exactly -ParameterFilter { $Method -eq 'POST' }
        Should -Invoke Invoke-GraphApiRequest -Times 0 -Exactly -ParameterFilter { $Method -eq 'GET' }
    }

    It 'keeps service rejection failed rather than registration evidence' {
        $script:existingImport = @{ AutopilotImportId = $script:importIdentity }
        Mock Invoke-GraphApiRequest { return @{ id = $script:importIdentity; serialNumber = 'SERIAL1'; state = @{ deviceImportStatus = 'error'; deviceErrorCode = 1036 } } }
        $result = Invoke-AutopilotHashImport -Device $script:hashDevice
        $result.State | Should -Be Failed
        $result.ErrorCode | Should -Be 1036
        Should -Invoke Invoke-GraphApiRequest -Times 0 -Exactly -ParameterFilter { $Method -eq 'POST' }
    }

    It 'rejects an import-state response for a different serial' {
        $script:existingImport = @{ AutopilotImportId = $script:importIdentity }
        Mock Invoke-GraphApiRequest { return @{ id = $script:importIdentity; serialNumber = 'OTHER'; state = @{ deviceImportStatus = 'complete' } } }
        { Invoke-AutopilotHashImport -Device $script:hashDevice } | Should -Throw '*unexpected evidence*'
        Should -Invoke Invoke-GraphApiRequest -Times 0 -Exactly -ParameterFilter { $Method -eq 'POST' }
    }

    It 'does not complete step A when import completes but Autopilot is absent' {
        $script:RuntimeConfig.autopilot = @{ hashImport = @{ enabled = $true } }
        Mock Resolve-LiveAutopilotContext { return @{ Autopilot = $null } }
        Mock Invoke-AutopilotHashImport { return @{ State = 'Complete'; RegistrationId = 'registration-one' } }
        $result = Invoke-StepResolveAutopilotDevice -Device $script:hashDevice -StepDefinition @{ ActionName = 'ResolveAutopilotDevice' }
        $result.CompletionState | Should -Be Submitted
        $result.Data.ImportState | Should -Be Complete
        Should -Invoke Read-ValidatedInput -Times 0 -Exactly
    }

    It 'verifies completed import only after fresh exact-serial Autopilot presence' {
        $script:RuntimeConfig.autopilot = @{ hashImport = @{ enabled = $true } }
        $script:contextReads = 0
        Mock Resolve-LiveAutopilotContext {
            $script:contextReads++
            if ($script:contextReads -eq 1) { return @{ Autopilot = $null } }
            return @{ Autopilot = @{ id = 'autopilot-one'; serialNumber = 'SERIAL1' } }
        }
        Mock Invoke-AutopilotHashImport { return @{ State = 'Complete'; RegistrationId = 'registration-one' } }
        $result = Invoke-StepResolveAutopilotDevice -Device $script:hashDevice -StepDefinition @{ ActionName = 'ResolveAutopilotDevice' }
        $result.CompletionState | Should -Be Verified
        $result.Data.ObservedSerial | Should -Be 'SERIAL1'
        Should -Invoke Resolve-LiveAutopilotContext -Times 2 -Exactly
    }

    It 'propagates import storage failures out of step A instead of recording success or continuing' {
        $script:RuntimeConfig.autopilot = @{ hashImport = @{ enabled = $true } }
        Mock Resolve-LiveAutopilotContext { return @{ Autopilot = $null } }
        Mock Invoke-AutopilotHashImport {
            $exception = [Exception]::new('Synthetic storage failure')
            $exception.Data['AutopilotExpress.HashImportStorageFailure'] = $true
            throw $exception
        }
        { Invoke-StepResolveAutopilotDevice -Device $script:hashDevice -StepDefinition @{ ActionName = 'ResolveAutopilotDevice' } } | Should -Throw '*storage failure*'
    }
}

Describe 'Fail-closed unique device lookups' {
    It 'returns a unique Autopilot identity with the matching serial' {
        Mock Invoke-GraphApiRequest { return @{ value = @(@{ id = 'autopilot-one'; serialNumber = 'SERIAL1' }) } }
        (Resolve-LiveAutopilotDeviceBySerial -Serial 'SERIAL1').id | Should -Be 'autopilot-one'
        Should -Invoke Invoke-GraphApiRequest -Times 1 -Exactly -ParameterFilter {
            $Method -eq 'GET' -and [uri]::UnescapeDataString($Uri) -ceq "https://graph.microsoft.com/v1.0/deviceManagement/windowsAutopilotDeviceIdentities?`$filter=contains(serialNumber,'SERIAL1')"
        }
    }

    It 'does not infer an exact serial match from a partial contains result' {
        Mock Invoke-GraphApiRequest { return @{ value = @(@{ id = 'other-device'; serialNumber = 'SERIAL10' }) } }
        Resolve-LiveAutopilotDeviceBySerial -Serial SERIAL1 | Should -BeNullOrEmpty
    }

    It 'does not fall back to an inventory scan after a rejected filtered read' {
        Mock Invoke-GraphApiRequest { throw 'Synthetic filter rejection' }
        { Resolve-LiveAutopilotDeviceBySerial -Serial SERIAL1 } | Should -Throw '*filter rejection*'
        Should -Invoke Invoke-GraphApiRequest -Times 1 -Exactly -ParameterFilter { $Uri -like '*?$filter=*' }
    }

    It 'rejects blank serial discovery before a request' {
        Mock Invoke-GraphApiRequest { throw 'Unexpected blank-serial request' }
        { Resolve-LiveAutopilotDeviceBySerial -Serial ' ' } | Should -Throw '*nonblank serial*'
        Should -Invoke Invoke-GraphApiRequest -Times 0 -Exactly
    }

    It 'finds a local exact serial match on a later complete page' {
        Mock Invoke-GraphApiRequest {
            if ($Uri -like '*skiptoken*') { return @{ value = @(@{ id = 'autopilot-one'; serialNumber = 'SERIAL1' }) } }
            return @{ value = @(@{ id = 'other'; serialNumber = 'SERIAL10' }); '@odata.nextLink' = 'https://graph.microsoft.com/v1.0/deviceManagement/windowsAutopilotDeviceIdentities?$skiptoken=next' }
        }
        (Resolve-LiveAutopilotDeviceBySerial -Serial 'SERIAL1').id | Should -Be 'autopilot-one'
        Should -Invoke Invoke-GraphApiRequest -Times 2 -Exactly
    }

    It 'rejects duplicate serial matches across distinct identities' {
        Mock Invoke-GraphApiRequest { return @{ value = @(@{ id = 'one'; serialNumber = 'SERIAL1' }, @{ id = 'two'; serialNumber = 'serial1' }) } }
        { Resolve-LiveAutopilotDeviceBySerial -Serial SERIAL1 } | Should -Throw '*Multiple Autopilot*'
    }

    It 'does not infer absence from a valid first page followed by a failed page' {
        Mock Invoke-GraphApiRequest {
            if ($Uri -like '*skiptoken*') { throw 'Later page denied' }
            return @{ value = @(); '@odata.nextLink' = 'https://graph.microsoft.com/v1.0/deviceManagement/windowsAutopilotDeviceIdentities?$skiptoken=next' }
        }
        { Resolve-LiveAutopilotDeviceBySerial -Serial SERIAL1 } | Should -Throw '*Later page denied*'
    }

    It 'returns an Entra object ID only for its matching registration ID' {
        Mock Invoke-GraphApiRequest { return @{ value = @(@{ id = 'object-one'; deviceId = 'registration-one' }) } }
        (Resolve-LiveEntraDeviceObject -AzureAdDeviceId 'registration-one').id | Should -Be 'object-one'
    }

    It 'treats a complete empty collection as absent on both surfaces' {
        Mock Invoke-GraphApiRequest { return @{ value = @() } }
        Resolve-LiveAutopilotDeviceBySerial -Serial 'SERIAL1' | Should -BeNullOrEmpty
        Resolve-LiveEntraDeviceObject -AzureAdDeviceId 'registration-one' | Should -BeNullOrEmpty
    }

    It 'rejects missing null scalar and object collections rather than treating them as absent' {
        foreach ($response in @($null, @{}, @{ value = $null }, @{ value = 'invalid' }, @{ value = @{ id = 'one' } })) {
            $script:identityResponse = $response
            Mock Invoke-GraphApiRequest { return $script:identityResponse }
            { Resolve-LiveAutopilotDeviceBySerial -Serial 'SERIAL1' } | Should -Throw '*malformed*'
            { Resolve-LiveEntraDeviceObject -AzureAdDeviceId 'registration-one' } | Should -Throw '*malformed*'
        }
    }

    It 'rejects incomplete pages including empty pages with a continuation' {
        Mock Invoke-GraphApiRequest { return @{ value = @(); '@odata.nextLink' = 'https://graph.microsoft.com/more' } }
        { Resolve-LiveAutopilotDeviceBySerial -Serial 'SERIAL1' } | Should -Throw '*continuation*'
        { Resolve-LiveEntraDeviceObject -AzureAdDeviceId 'registration-one' } | Should -Throw '*incomplete*'
        Should -Invoke Invoke-GraphApiRequest -Times 2 -Exactly
    }

    It 'rejects multiple results even when both entries have the same ID' {
        Mock Invoke-GraphApiRequest { return @{ value = @(@{ id = 'one'; serialNumber = 'SERIAL1' }, @{ id = 'one'; serialNumber = 'SERIAL1' }) } }
        { Resolve-LiveAutopilotDeviceBySerial -Serial 'SERIAL1' } | Should -Throw '*repeated identity*'
        { Resolve-LiveEntraDeviceObject -AzureAdDeviceId 'registration-one' } | Should -Throw '*Multiple Entra*'
    }

    It 'rejects missing blank wrong and non-text Autopilot identities' {
        foreach ($identity in @($null, @{}, @{ id = ' '; serialNumber = 'SERIAL1' }, @{ id = 'one'; serialNumber = '' }, @{ id = 1; serialNumber = 'SERIAL1' }, @{ id = 'one'; serialNumber = @('SERIAL1') })) {
            $script:identityResponse = @{ value = @($identity) }
            Mock Invoke-GraphApiRequest { return $script:identityResponse }
            { Resolve-LiveAutopilotDeviceBySerial -Serial 'SERIAL1' } | Should -Throw '*unexpected identity*'
        }
    }

    It 'rejects missing blank wrong and non-text Entra identities' {
        foreach ($identity in @($null, @{}, @{ id = ' '; deviceId = 'registration-one' }, @{ id = 'one'; deviceId = 'OTHER' }, @{ id = 1; deviceId = 'registration-one' }, @{ id = 'one'; deviceId = @('registration-one') })) {
            $script:identityResponse = @{ value = @($identity) }
            Mock Invoke-GraphApiRequest { return $script:identityResponse }
            { Resolve-LiveEntraDeviceObject -AzureAdDeviceId 'registration-one' } | Should -Throw '*unexpected identity*'
        }
    }

    It 'propagates read failures without retrying locally' {
        Mock Invoke-GraphApiRequest { throw 'Synthetic lookup denied' }
        { Resolve-LiveAutopilotDeviceBySerial -Serial 'SERIAL1' } | Should -Throw '*lookup denied*'
        { Resolve-LiveEntraDeviceObject -AzureAdDeviceId 'registration-one' } | Should -Throw '*lookup denied*'
        Should -Invoke Invoke-GraphApiRequest -Times 2 -Exactly
    }

    It 'escapes quoted filter values without changing the matching identity' {
        Mock Invoke-GraphApiRequest { return @{ value = @(@{ id = 'one'; serialNumber = "SER'IAL"; deviceId = "registration'one" }) } }
        (Resolve-LiveAutopilotDeviceBySerial -Serial "SER'IAL").id | Should -Be 'one'
        (Resolve-LiveEntraDeviceObject -AzureAdDeviceId "registration'one").id | Should -Be 'one'
        Should -Invoke Invoke-GraphApiRequest -Times 1 -Exactly -ParameterFilter { [uri]::UnescapeDataString($Uri) -ceq "https://graph.microsoft.com/v1.0/deviceManagement/windowsAutopilotDeviceIdentities?`$filter=contains(serialNumber,'SER''IAL')" }
        Should -Invoke Invoke-GraphApiRequest -Times 1 -Exactly -ParameterFilter { $Uri -like "*deviceId eq 'registration''one'*" }
    }
}

Describe 'Autopilot upload confirmation requires fresh presence evidence' {
    BeforeEach {
        $script:Runtime = @{ IsDemoMode = $false }
        $script:RuntimeConfig = @{}
        $script:Config = @{ MaxRetryAttempts = 3; RetryBackoffSeconds = 2 }
        $script:device = @{ Serial = 'SERIAL1'; AutopilotDeviceId = ''; ManagedDeviceId = ''; EntraDeviceId = '' }
        $script:step = @{ ActionName = 'ResolveAutopilotDevice' }
        $script:uploadReads = 0
        Mock Write-Host {}
        Mock Start-Sleep {}
        Mock Read-ValidatedInput { return 'Y' }
        Mock Resolve-LiveAutopilotContext { return @{ Autopilot = $null } }
    }

    It 'verifies immediate presence without an upload prompt' {
        Mock Resolve-LiveAutopilotContext { return @{ Autopilot = @{ id = 'auto-1'; serialNumber = 'SERIAL1' } } }
        $result = Invoke-StepResolveAutopilotDevice -Device $script:device -StepDefinition $script:step
        $result.CompletionState | Should -Be Verified
        $result.Data.AutopilotDeviceId | Should -Be 'auto-1'
        $result.Notes | Should -Not -Match 'upload'
        Should -Invoke Read-ValidatedInput -Times 0 -Exactly
    }

    It 'automatically rechecks after Yes and observes delayed upload propagation' {
        # Rechecks use the single Autopilot serial search; the full context is read once it appears.
        Mock Resolve-LiveAutopilotDeviceBySerial {
            $script:uploadReads++
            if ($script:uploadReads -lt 2) { return $null }
            return @{ id = 'auto-1'; serialNumber = 'SERIAL1' }
        }
        Mock Resolve-LiveAutopilotContext { return @{ Autopilot = $KnownAutopilotDevice } } -ParameterFilter { $null -ne $KnownAutopilotDevice }
        $result = Invoke-StepResolveAutopilotDevice -Device $script:device -StepDefinition $script:step
        $result.CompletionState | Should -Be Verified
        $result.Data.HandoffRecorded | Should -BeTrue
        $result.Data.VerificationAttempts | Should -Be 2
        $result.Notes | Should -Match 'after the upload hand-off'
        Should -Invoke Resolve-LiveAutopilotDeviceBySerial -Times 2 -Exactly
        Should -Invoke Resolve-LiveAutopilotContext -Times 2 -Exactly
        Should -Invoke Resolve-LiveAutopilotContext -Times 1 -Exactly -ParameterFilter { $KnownAutopilotDevice.id -eq 'auto-1' }
        Should -Invoke Start-Sleep -Times 1 -Exactly
    }

    It 'keeps reported upload Submitted after bounded absent reads' {
        Mock Resolve-LiveAutopilotDeviceBySerial { return $null }
        $result = Invoke-StepResolveAutopilotDevice -Device $script:device -StepDefinition $script:step
        $result.CompletionState | Should -Be Submitted
        $result.Success | Should -BeFalse
        $result.Data.VerificationAttempts | Should -Be 3
        Should -Invoke Resolve-LiveAutopilotContext -Times 1 -Exactly
        Should -Invoke Resolve-LiveAutopilotDeviceBySerial -Times 3 -Exactly
        Should -Invoke Start-Sleep -Times 2 -Exactly
    }

    It 'does not requery when the upload handoff is declined' {
        Mock Read-ValidatedInput { return 'N' }
        (Invoke-StepResolveAutopilotDevice -Device $script:device -StepDefinition $script:step).CompletionState | Should -Be Failed
        Should -Invoke Resolve-LiveAutopilotContext -Times 1 -Exactly
    }

    It 'fails closed on a post-upload read error without inferring absence' {
        Mock Resolve-LiveAutopilotDeviceBySerial { throw 'Permission denied' }
        $result = Invoke-StepResolveAutopilotDevice -Device $script:device -StepDefinition $script:step
        $result.CompletionState | Should -Be Failed
        $result.Data.HandoffRecorded | Should -BeTrue
        Should -Invoke Resolve-LiveAutopilotContext -Times 1 -Exactly
        Should -Invoke Resolve-LiveAutopilotDeviceBySerial -Times 1 -Exactly
    }

    It 'refuses mismatched observed serial evidence' {
        Mock Resolve-LiveAutopilotContext { return @{ Autopilot = @{ id = 'auto-1'; serialNumber = 'OTHER' } } }
        (Invoke-StepResolveAutopilotDevice -Device $script:device -StepDefinition $script:step).CompletionState | Should -Be Failed
    }
}

Describe 'Device context refresh without partial identity updates' {
    BeforeEach {
        $script:Runtime = @{ IsDemoMode = $false }
        $script:GraphSession = @{ Connected = $true; IsSimulated = $false; TenantId = '11111111-1111-1111-1111-111111111111' }
        Mock Get-MgContext { return @{ TenantId = '11111111-1111-1111-1111-111111111111' } }
        $script:device = @{ TenantId = '11111111-1111-1111-1111-111111111111'; Serial = 'SERIAL1'; AutopilotDeviceId = 'old-ap'; ManagedDeviceId = 'old-managed'; AzureAdDeviceId = 'old-registration'; EntraDeviceId = 'old-object'; IntuneDeviceName = 'old-name'; GroupTag = 'old-tag' }
        Mock Resolve-LiveAutopilotDeviceBySerial { return @{ id = 'new-ap'; groupTag = 'new-tag'; azureActiveDirectoryDeviceId = 'new-registration'; managedDeviceId = 'stale-managed' } }
        Mock Resolve-LiveManagedDeviceBySerial { return @{ id = 'new-managed'; deviceName = 'new-name'; azureADDeviceId = 'current-registration' } }
        Mock Resolve-LiveEntraDeviceObject { return @{ id = 'new-object' } }
    }

    It 'leaves every cached field unchanged when Entra resolution fails' {
        $before = $script:device | ConvertTo-Json -Compress
        Mock Resolve-LiveEntraDeviceObject { throw 'Ambiguous Entra identity' }
        { Resolve-LiveAutopilotContext -Device $script:device } | Should -Throw '*Ambiguous Entra*'
        ($script:device | ConvertTo-Json -Compress) | Should -Be $before
    }

    It 'leaves cached fields unchanged when managed resolution fails' {
        $before = $script:device | ConvertTo-Json -Compress
        Mock Resolve-LiveManagedDeviceBySerial { throw 'Ambiguous managed identity' }
        { Resolve-LiveAutopilotContext -Device $script:device } | Should -Throw '*Ambiguous managed*'
        ($script:device | ConvertTo-Json -Compress) | Should -Be $before
        Should -Invoke Resolve-LiveEntraDeviceObject -Times 0 -Exactly
    }

    It 'commits resolved identifiers together using current managed registration evidence' {
        $context = Resolve-LiveAutopilotContext -Device $script:device
        $script:device.AutopilotDeviceId | Should -Be 'new-ap'
        $script:device.ManagedDeviceId | Should -Be 'new-managed'
        $script:device.AzureAdDeviceId | Should -Be 'current-registration'
        $script:device.EntraDeviceId | Should -Be 'new-object'
        $script:device.IntuneDeviceName | Should -Be 'new-name'
        $script:device.GroupTag | Should -Be 'new-tag'
        $context.Entra.id | Should -Be 'new-object'
        Should -Invoke Resolve-LiveEntraDeviceObject -Times 1 -Exactly -ParameterFilter { $AzureAdDeviceId -eq 'current-registration' }
    }

    It 'clears stale mutation IDs when both serial lookups confirm absence' {
        Mock Resolve-LiveAutopilotDeviceBySerial { return $null }
        Mock Resolve-LiveManagedDeviceBySerial { return $null }
        [void](Resolve-LiveAutopilotContext -Device $script:device)
        foreach ($field in @('AutopilotDeviceId', 'ManagedDeviceId', 'AzureAdDeviceId', 'EntraDeviceId')) { $script:device[$field] | Should -BeNullOrEmpty }
        Should -Invoke Resolve-LiveEntraDeviceObject -Times 0 -Exactly
    }

    It 'does not reuse an Autopilot managed-device association after a complete absent managed read' {
        Mock Resolve-LiveManagedDeviceBySerial { return $null }
        [void](Resolve-LiveAutopilotContext -Device $script:device)
        $script:device.ManagedDeviceId | Should -BeNullOrEmpty
        $script:device.AutopilotDeviceId | Should -Be 'new-ap'
    }

    It 'clears a stale Entra object ID when the current registration has no directory object' {
        Mock Resolve-LiveEntraDeviceObject { return $null }
        [void](Resolve-LiveAutopilotContext -Device $script:device)
        $script:device.EntraDeviceId | Should -BeNullOrEmpty
        $script:device.AzureAdDeviceId | Should -Be 'current-registration'
    }
}
