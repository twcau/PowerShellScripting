<#
.SYNOPSIS
    Tests durable sync acceptance separately from technician confirmation.
.DESCRIPTION
    Extracts production functions without starting the CLI. Requests, refreshed
    targets and input are mocked. SYNC-RECEIPTS keeps sync evidence in each
    device record's SyncSubmissions ledger; a Write-UserDeviceRecords stand-in
    serialises the session records to a TestDrive JSON store so durability and
    restart behaviour can be asserted without operational storage or a tenant.
    Legacy receipt/intent file migration is exercised with real files in TestDrive.
.FILECREATED
    2026-10-08
.FILELASTUPDATED
    2026-11-03
#>
BeforeAll {
    $sourcePath = Join-Path (Split-Path -Parent $PSScriptRoot) 'autopilot-express.ps1'
    $tokens = $null
    $parseErrors = $null
    $sourceAst = [System.Management.Automation.Language.Parser]::ParseFile($sourcePath, [ref]$tokens, [ref]$parseErrors)
    if ($parseErrors.Count) { throw ($parseErrors.Message -join '; ') }
    foreach ($functionName in @('Get-GraphTransportFailure', 'Get-GraphOperationFailureMessage', 'New-OperationResult', 'ConvertTo-RecordDate', 'ConvertTo-PersistedDate', 'Read-ApplicationRetryChoice', 'Get-ConfirmedApplicationBaseline', 'Test-ApplicationNoFailureEvidence', 'Get-SyncSubmissionLedgerState', 'Save-DeviceLedgerEntry', 'Import-LegacySyncSubmissionEvidence', 'Invoke-StepRetryFailedApps', 'Assert-FileWriteRecoveryState')) {
        $definition = $sourceAst.Find({ param($node) $node -is [System.Management.Automation.Language.FunctionDefinitionAst] -and $node.Name -eq $functionName }, $true)
        if ($null -eq $definition) { throw ('Missing function: {0}' -f $functionName) }
        Set-Item -Path ('Function:{0}' -f $definition.Name) -Value $definition.Body.GetScriptBlock()
    }
    function Assert-ActiveStorageReservation { throw 'Unexpected reservation check' }
    function Write-AutopilotExpressLog { param($Message, $Level) $null = $Message, $Level }
    function Resolve-LiveAutopilotContext { param($Device) throw ('Unexpected refresh: {0}' -f $Device.Serial) }
    function Invoke-GraphApiRequest { param($Method, $Uri) throw ('Unexpected request: {0} {1}' -f $Method, $Uri) }
    function Get-EnabledManifestSteps { return $script:syncManifestSteps }
    function Read-ValidatedInput {
        param($Prompt, $Default, $Type, $Choices)
        throw ('Unexpected input: {0} {1} {2} {3}' -f $Prompt, $Default, $Type, ($Choices -join ','))
    }
    # Durable-store stand-in for the production checkpointed records writer.
    function Write-UserDeviceRecords {
        param($Records)
        Set-Content -LiteralPath $script:storePath -Value (ConvertTo-Json -InputObject @($Records) -Depth 10) -NoNewline
    }
    $script:realSave = ${function:Write-UserDeviceRecords}

    function Get-StoredLedger {
        <# Read one record's ledger back from the durable store as hashtables. #>
        param([string]$RecordId = 'record-1')
        if (-not (Test-Path -LiteralPath $script:storePath)) { return , @() }
        $jsonParameters = @{}
        if ((Get-Command ConvertFrom-Json).Parameters.ContainsKey('DateKind')) { $jsonParameters.DateKind = 'String' }
        $stored = @((Get-Content -LiteralPath $script:storePath -Raw | ConvertFrom-Json @jsonParameters) | ForEach-Object { $_ })
        $record = $stored | Where-Object { $_.RecordId -eq $RecordId } | Select-Object -First 1
        $entries = foreach ($entry in @($record.SyncSubmissions)) {
            if ($null -eq $entry) { continue }
            $map = @{}
            foreach ($property in $entry.PSObject.Properties) { $map[$property.Name] = $property.Value }
            $map
        }
        return , @($entries)
    }

    function Use-SessionDevice {
        <# Make the given records the active session collection, as startup does. #>
        param([Parameter(Mandatory)][object[]]$Devices)
        $script:device = $Devices[0]
        $script:InventoryRecords = @{ Value = $Devices }
    }
}

Describe 'Application sync choice' {
    It 'displays the approved no-failure default and an explicit cancellation choice' {
        Mock Read-ValidatedInput { return 'N' }
        Read-ApplicationRetryChoice | Should -Be 'N'
        Should -Invoke Read-ValidatedInput -Times 1 -Exactly -ParameterFilter {
            $Default -eq 'N' -and $Prompt -match '\[N\] No failures' -and
            $Prompt -match '\[Y\] Sync for failures' -and $Prompt -match '\[0\] Cancel'
        }
    }
}

Describe 'Sync submission ledger' {
    BeforeEach {
        $script:Runtime = @{ IsDemoMode = $false }
        $script:GraphSession = @{ TenantId = 'tenant-1' }
        $script:SyncSubmissionPersistenceFailure = $false
        $script:storePath = Join-Path $TestDrive ('{0}.json' -f [guid]::NewGuid().Guid)
        Use-SessionDevice -Devices @(@{ RecordId = 'record-1'; Serial = 'SERIAL1'; ManagedDeviceId = 'cached'; SyncSubmissions = @() })
        $script:step = @{ ActionName = 'RetryFailedApplications' }
        $script:syncManifestSteps = @(@{ Id = 'L'; ActionName = 'ConfirmApplicationBaseline' })
        Mock Assert-ActiveStorageReservation {}
        Mock Resolve-LiveAutopilotContext { $Device.ManagedDeviceId = 'current-managed' }
        Mock Invoke-GraphApiRequest {}
        Mock Write-AutopilotExpressLog {}
        Mock Write-UserDeviceRecords { & $script:realSave -Records $Records }
        Mock Read-ApplicationRetryChoice { return 'Y' }
        Mock Read-ValidatedInput {
            @(Get-StoredLedger | Where-Object { $_.State -eq 'Accepted' }).Count | Should -Be 1
            return 'Y'
        }
    }

    It 'records no failures only after the current baseline is confirmed, without Graph or ledger writes' {
        $script:device.Steps = @{ L = @{ ActionName = 'ConfirmApplicationBaseline'; CompletionState = 'TechnicianConfirmed'; Success = $true; IsSimulated = $false; Timestamp = Get-Date } }
        Mock Read-ApplicationRetryChoice { return 'N' }
        $result = Invoke-StepRetryFailedApps -Device $script:device -StepDefinition $script:step
        $result.CompletionState | Should -Be 'TechnicianConfirmed'
        $result.Data.NoApplicationFailures | Should -BeTrue
        $result.Data.SyncRequestedForOutcome | Should -BeFalse
        $result.Data.BaselineStepId | Should -Be 'L'
        Test-ApplicationNoFailureEvidence -Device $script:device -Data $result.Data | Should -BeTrue
        Should -Invoke Resolve-LiveAutopilotContext -Times 0 -Exactly
        Should -Invoke Invoke-GraphApiRequest -Times 0 -Exactly
        Should -Invoke Write-UserDeviceRecords -Times 0 -Exactly
    }

    It 'blocks no failures for an unconfirmed or invalid baseline: <Case>' -ForEach @(
        @{ Case = 'missing'; Step = $null }
        @{ Case = 'pending'; Step = @{ ActionName = 'ConfirmApplicationBaseline'; CompletionState = 'Submitted'; Success = $false; IsSimulated = $false; Timestamp = '2026-10-08T12:00:00Z' } }
        @{ Case = 'legacy completion'; Step = @{ ActionName = 'ConfirmApplicationBaseline'; CompletionState = 'LegacyCompleted'; Success = $true; IsSimulated = $false; Timestamp = '2026-10-08T12:00:00Z' } }
        @{ Case = 'wrong action'; Step = @{ ActionName = 'ConfirmFirstSignIn'; CompletionState = 'TechnicianConfirmed'; Success = $true; IsSimulated = $false; Timestamp = '2026-10-08T12:00:00Z' } }
        @{ Case = 'missing time'; Step = @{ ActionName = 'ConfirmApplicationBaseline'; CompletionState = 'TechnicianConfirmed'; Success = $true; IsSimulated = $false; Timestamp = $null } }
        @{ Case = 'simulated in Live'; Step = @{ ActionName = 'ConfirmApplicationBaseline'; CompletionState = 'Simulated'; Success = $true; IsSimulated = $true; Timestamp = '2026-10-08T12:00:00Z' } }
    ) {
        $script:device.Steps = @{ L = $Step }
        Mock Read-ApplicationRetryChoice { return 'N' }
        $result = Invoke-StepRetryFailedApps -Device $script:device -StepDefinition $script:step
        $result.CompletionState | Should -Be 'Blocked'
        $result.Data.Blocked | Should -BeTrue
        $result.Summary | Should -Match 'Confirm the application baseline'
        Should -Invoke Invoke-GraphApiRequest -Times 0 -Exactly
        Should -Invoke Resolve-LiveAutopilotContext -Times 0 -Exactly
    }

    It 'keeps no-failure evidence simulated in Demo without requesting sync' {
        $script:Runtime.IsDemoMode = $true
        $script:device.Steps = @{ L = @{ ActionName = 'ConfirmApplicationBaseline'; CompletionState = 'Simulated'; Success = $true; IsSimulated = $true; Timestamp = Get-Date } }
        Mock Read-ApplicationRetryChoice { return 'N' }
        $result = Invoke-StepRetryFailedApps -Device $script:device -StepDefinition $script:step
        $result.CompletionState | Should -Be 'Simulated'
        $result.IsSimulated | Should -BeTrue
        Should -Invoke Invoke-GraphApiRequest -Times 0 -Exactly
    }

    It 'describes a Demo failure-path sync without claiming portal remediation' {
        $script:Runtime.IsDemoMode = $true
        $result = Invoke-StepRetryFailedApps -Device $script:device -StepDefinition $script:step
        $result.CompletionState | Should -Be 'Simulated'
        $result.Notes | Should -Match 'does not run the named portal remediation'
        Should -Invoke Invoke-GraphApiRequest -Times 0 -Exactly
    }

    It 'retains earlier sync receipts when recording a later no-failure outcome' {
        $script:device.Steps = @{ L = @{ ActionName = 'ConfirmApplicationBaseline'; CompletionState = 'TechnicianConfirmed'; Success = $true; IsSimulated = $false; Timestamp = Get-Date } }
        $script:device.SyncSubmissions = @(@{ State = 'Accepted'; SubmittedAt = '2026-10-08T12:00:00Z' })
        $before = $script:device.SyncSubmissions | ConvertTo-Json -Compress
        Mock Read-ApplicationRetryChoice { return 'N' }
        $result = Invoke-StepRetryFailedApps -Device $script:device -StepDefinition $script:step
        $result.CompletionState | Should -Be 'TechnicianConfirmed'
        ($script:device.SyncSubmissions | ConvertTo-Json -Compress) | Should -BeExactly $before
        Should -Invoke Invoke-GraphApiRequest -Times 0 -Exactly
    }

    It 'cancels without refreshing the target or issuing a request' {
        Mock Read-ApplicationRetryChoice { return '0' }
        $result = Invoke-StepRetryFailedApps -Device $script:device -StepDefinition $script:step
        $result.CompletionState | Should -Be 'Blocked'
        $result.Data.Blocked | Should -BeTrue
        Should -Invoke Resolve-LiveAutopilotContext -Times 0 -Exactly
        Should -Invoke Invoke-GraphApiRequest -Times 0 -Exactly
        Should -Invoke Write-UserDeviceRecords -Times 0 -Exactly
    }

    It 'persists accepted refreshed evidence in the record before input and never repeats POST' {
        $first = Invoke-StepRetryFailedApps -Device $script:device -StepDefinition $script:step
        $first.CompletionState | Should -Be 'TechnicianConfirmed'
        $ledger = Get-StoredLedger
        $ledger.Count | Should -Be 2
        $ledger[0].State | Should -BeExactly 'Intent'
        $saved = $ledger[1]
        $saved.State | Should -BeExactly 'Accepted'
        $saved.RecordId | Should -Be 'record-1'
        $saved.Serial | Should -Be 'SERIAL1'
        $saved.ManagedDeviceId | Should -Be 'current-managed'
        $saved.TenantId | Should -Be 'tenant-1'
        $saved.Source | Should -BeExactly 'Live'
        $saved.CycleKey | Should -BeExactly ''
        $saved.SubmittedAt | Should -BeExactly $first.Data.SubmittedAt
        $second = Invoke-StepRetryFailedApps -Device $script:device -StepDefinition $script:step
        $second.CompletionState | Should -Be 'TechnicianConfirmed'
        Should -Invoke Invoke-GraphApiRequest -Times 1 -Exactly -ParameterFilter { $Method -eq 'POST' -and $Uri -eq 'https://graph.microsoft.com/v1.0/deviceManagement/managedDevices/current-managed/syncDevice' }
        Should -Invoke Write-UserDeviceRecords -Times 2 -Exactly
        Should -Invoke Read-ValidatedInput -Times 2 -Exactly
    }

    It 'isolates a new build cycle without altering or reusing the previous receipt' {
        [void](Invoke-StepRetryFailedApps -Device $script:device -StepDefinition $script:step)
        $oldEntries = ConvertTo-Json -InputObject (Get-StoredLedger) -Depth 5 -Compress
        $script:device.BuildCycleId = '22222222-2222-2222-2222-222222222222'
        Mock Read-ValidatedInput { return 'Y' }
        [void](Invoke-StepRetryFailedApps -Device $script:device -StepDefinition $script:step)
        [void](Invoke-StepRetryFailedApps -Device $script:device -StepDefinition $script:step)
        $ledger = Get-StoredLedger
        $ledger.Count | Should -Be 4
        (ConvertTo-Json -InputObject @($ledger[0], $ledger[1]) -Depth 5 -Compress) | Should -BeExactly $oldEntries
        @($ledger | Where-Object { $_.CycleKey -eq '22222222-2222-2222-2222-222222222222' -and $_.State -eq 'Accepted' }).Count | Should -Be 1
        Should -Invoke Invoke-GraphApiRequest -Times 2 -Exactly
    }

    It 'retains Submitted after negative input and prompt failure without resubmitting' {
        Mock Read-ValidatedInput { return 'N' }
        $result = Invoke-StepRetryFailedApps -Device $script:device -StepDefinition $script:step
        $result.CompletionState | Should -Be 'Submitted'
        $result.Data.SyncAccepted | Should -BeTrue
        Mock Read-ValidatedInput { throw 'Input interrupted' }
        $result = Invoke-StepRetryFailedApps -Device $script:device -StepDefinition $script:step
        $result.CompletionState | Should -Be 'Submitted'
        $result.Notes | Should -Match 'Input interrupted'
        Should -Invoke Invoke-GraphApiRequest -Times 1 -Exactly
        Should -Invoke Write-UserDeviceRecords -Times 2 -Exactly
    }

    It 'records intent but no receipt or confirmation when POST fails' {
        Mock Invoke-GraphApiRequest { throw 'POST rejected' }
        $result = Invoke-StepRetryFailedApps -Device $script:device -StepDefinition $script:step
        $result.CompletionState | Should -Be 'Failed'
        $result.Data.SyncAccepted | Should -BeFalse
        $ledger = Get-StoredLedger
        $ledger.Count | Should -Be 1
        $ledger[0].State | Should -BeExactly 'Intent'
        Should -Invoke Read-ValidatedInput -Times 0 -Exactly
    }

    It 'resumes from the saved record after the first confirmation throws and memory is lost' {
        Mock Read-ValidatedInput { throw 'First input interrupted' }
        $first = Invoke-StepRetryFailedApps -Device $script:device -StepDefinition $script:step
        $first.CompletionState | Should -Be 'Submitted'
        $first.Data.ReceiptPersisted | Should -BeTrue
        $first.Notes | Should -Match 'First input interrupted'
        Use-SessionDevice -Devices @(@{ RecordId = 'record-1'; Serial = 'SERIAL1'; ManagedDeviceId = 'stale-after-restart'; SyncSubmissions = (Get-StoredLedger) })
        Mock Read-ValidatedInput { return 'Y' }
        $second = Invoke-StepRetryFailedApps -Device $script:device -StepDefinition $script:step
        $second.CompletionState | Should -Be 'TechnicianConfirmed'
        $second.Data.SubmittedAt | Should -BeExactly $first.Data.SubmittedAt
        $second.Data.ManagedDeviceId | Should -BeExactly 'current-managed'
        Should -Invoke Invoke-GraphApiRequest -Times 1 -Exactly
    }

    It 'keeps each record''s ledger separate within one saved collection' {
        $other = @{ RecordId = 'record-2'; Serial = 'SERIAL2'; ManagedDeviceId = 'cached'; SyncSubmissions = @() }
        Use-SessionDevice -Devices @($script:device, $other)
        Mock Read-ValidatedInput { return 'N' }
        $first = Invoke-StepRetryFailedApps -Device $script:device -StepDefinition $script:step
        $originalLedger = ConvertTo-Json -InputObject (Get-StoredLedger) -Depth 5 -Compress
        $second = Invoke-StepRetryFailedApps -Device $other -StepDefinition $script:step
        $first.CompletionState | Should -Be 'Submitted'
        $second.CompletionState | Should -Be 'Submitted'
        (ConvertTo-Json -InputObject (Get-StoredLedger) -Depth 5 -Compress) | Should -BeExactly $originalLedger
        $otherLedger = Get-StoredLedger -RecordId 'record-2'
        @($otherLedger | Where-Object { $_.RecordId -cne 'record-2' -or $_.Serial -cne 'SERIAL2' }).Count | Should -Be 0
        $otherLedger.Count | Should -Be 2
        Should -Invoke Invoke-GraphApiRequest -Times 2 -Exactly
    }

    It 'refuses a changed <Field> without POST, confirmation or retargeting the receipt' -ForEach @(
        @{ Field = 'ManagedDeviceId' }, @{ Field = 'Serial' }, @{ Field = 'RecordId' }, @{ Field = 'TenantId' }
    ) {
        Invoke-StepRetryFailedApps -Device $script:device -StepDefinition $script:step | Out-Null
        $script:device.SyncSubmissions[1][$Field] = 'different-target'
        $result = Invoke-StepRetryFailedApps -Device $script:device -StepDefinition $script:step
        $result.CompletionState | Should -Be 'Failed'
        $result.Notes | Should -Match ('target changed \({0}\)' -f $Field)
        $script:device.SyncSubmissions.Count | Should -Be 2
        Should -Invoke Invoke-GraphApiRequest -Times 1 -Exactly
        Should -Invoke Read-ValidatedInput -Times 1 -Exactly
        Should -Invoke Write-UserDeviceRecords -Times 2 -Exactly
    }

    It 'rejects re-enrolment even when a cached managed identity matches the receipt' {
        Invoke-StepRetryFailedApps -Device $script:device -StepDefinition $script:step | Out-Null
        Mock Resolve-LiveAutopilotContext { $Device.ManagedDeviceId = 'reenrolled-managed' }
        $result = Invoke-StepRetryFailedApps -Device $script:device -StepDefinition $script:step
        $result.CompletionState | Should -Be 'Failed'
        $result.Notes | Should -Match 'target changed \(ManagedDeviceId\)'
        Should -Invoke Invoke-GraphApiRequest -Times 1 -Exactly
        Should -Invoke Read-ValidatedInput -Times 1 -Exactly
    }

    It 'accepts GUID RecordId as well as fixture identifiers' {
        $script:device.RecordId = [guid]::NewGuid().Guid
        Mock Read-ValidatedInput { return 'Y' }
        $result = Invoke-StepRetryFailedApps -Device $script:device -StepDefinition $script:step
        $result.CompletionState | Should -Be 'TechnicianConfirmed'
        (Get-StoredLedger -RecordId $script:device.RecordId).Count | Should -Be 2
    }

    It 'rejects unsafe RecordId <Label> before any POST or write' -ForEach @(
        @{ Label = 'empty'; Value = '' }, @{ Label = 'null'; Value = $null },
        @{ Label = 'number'; Value = 17 }, @{ Label = 'traversal'; Value = '../outside' },
        @{ Label = 'backslash'; Value = '..\outside' }, @{ Label = 'rooted'; Value = 'C:\outside' },
        @{ Label = 'dot'; Value = '.' }, @{ Label = 'whitespace'; Value = 'record 1' },
        @{ Label = 'newline'; Value = "record-1`n" }
    ) {
        $script:device.RecordId = $Value
        $result = Invoke-StepRetryFailedApps -Device $script:device -StepDefinition $script:step
        $result.CompletionState | Should -Be 'Failed'
        Should -Invoke Invoke-GraphApiRequest -Times 0 -Exactly
        Should -Invoke Write-UserDeviceRecords -Times 0 -Exactly
        Should -Invoke Read-ValidatedInput -Times 0 -Exactly
    }

    It 'rejects a malformed accepted entry (<Label>) without POST or confirmation' -ForEach @(
        @{ Label = 'missing RecordId'; Field = 'RecordId'; Value = $null },
        @{ Label = 'numeric RecordId'; Field = 'RecordId'; Value = 42 },
        @{ Label = 'empty Serial'; Field = 'Serial'; Value = '' },
        @{ Label = 'array Serial'; Field = 'Serial'; Value = @('SERIAL1') },
        @{ Label = 'Boolean ManagedDeviceId'; Field = 'ManagedDeviceId'; Value = $true },
        @{ Label = 'missing timestamp'; Field = 'SubmittedAt'; Value = $null },
        @{ Label = 'numeric timestamp'; Field = 'SubmittedAt'; Value = 123 },
        @{ Label = 'locale timestamp'; Field = 'SubmittedAt'; Value = '08/10/2026' },
        @{ Label = 'impossible ISO date'; Field = 'SubmittedAt'; Value = '2026-02-30T12:00:00.0000000Z' },
        @{ Label = 'no ISO offset'; Field = 'SubmittedAt'; Value = '2026-10-08T12:00:00.0000000' }
    ) {
        $entry = @{ CycleKey = ''; State = 'Accepted'; RecordedAt = (Get-Date -Format o); RecordId = 'record-1'; Serial = 'SERIAL1'; ManagedDeviceId = 'current-managed'; TenantId = 'tenant-1'; SubmittedAt = (Get-Date -Format o); Source = 'Live' }
        $entry[$Field] = $Value
        $script:device.SyncSubmissions = @($entry)
        $result = Invoke-StepRetryFailedApps -Device $script:device -StepDefinition $script:step
        $result.CompletionState | Should -Be 'Failed'
        $script:device.SyncSubmissions.Count | Should -Be 1
        Should -Invoke Invoke-GraphApiRequest -Times 0 -Exactly
        Should -Invoke Write-UserDeviceRecords -Times 0 -Exactly
        Should -Invoke Read-ValidatedInput -Times 0 -Exactly
    }

    It 'records accepted evidence and stops further sync when receipt persistence fails' {
        Mock Write-UserDeviceRecords { throw 'Synthetic receipt writer failure' } -ParameterFilter { @($Records[0].SyncSubmissions)[-1].State -eq 'Accepted' }
        $result = Invoke-StepRetryFailedApps -Device $script:device -StepDefinition $script:step
        $result.CompletionState | Should -Be 'Submitted'
        $result.Success | Should -BeFalse
        $result.Data.SyncAccepted | Should -BeTrue
        $result.Data.ReceiptPersisted | Should -BeFalse
        $result.Data.DurableGap | Should -BeTrue
        $result.Data.ManagedDeviceId | Should -BeExactly 'current-managed'
        $result.Data.SubmittedAt | Should -Not -BeNullOrEmpty
        $result.Notes | Should -Match 'durability across restart is unknown'
        @(Get-StoredLedger | Where-Object { $_.State -eq 'Accepted' }).Count | Should -Be 0
        { Invoke-StepRetryFailedApps -Device $script:device -StepDefinition $script:step } | Should -Throw '*Further sync is stopped*'
        $script:device.RecordId = 'record-2'
        { Invoke-StepRetryFailedApps -Device $script:device -StepDefinition $script:step } | Should -Throw '*Further sync is stopped*'
        Should -Invoke Invoke-GraphApiRequest -Times 1 -Exactly
        Should -Invoke Read-ValidatedInput -Times 0 -Exactly
    }

    It 'resubmits after restart when the receipt save failed but the intent was durable' {
        # Filtered mocks outrank later unfiltered ones, so the failure is flag-controlled.
        $script:failReceiptSave = $true
        Mock Write-UserDeviceRecords { throw 'Synthetic receipt writer failure' } -ParameterFilter { $script:failReceiptSave -and @($Records[0].SyncSubmissions)[-1].State -eq 'Accepted' }
        [void](Invoke-StepRetryFailedApps -Device $script:device -StepDefinition $script:step)
        $script:failReceiptSave = $false
        $script:SyncSubmissionPersistenceFailure = $false
        Use-SessionDevice -Devices @(@{ RecordId = 'record-1'; Serial = 'SERIAL1'; ManagedDeviceId = 'cached'; SyncSubmissions = (Get-StoredLedger) })
        $resumed = Invoke-StepRetryFailedApps -Device $script:device -StepDefinition $script:step
        $resumed.CompletionState | Should -Be 'TechnicianConfirmed'
        $resumed.Data.ResubmittedAfterUncertainIntent | Should -BeTrue
        Should -Invoke Invoke-GraphApiRequest -Times 2 -Exactly
    }

    It 'requires the active reservation before ledger access or POST' {
        Mock Assert-ActiveStorageReservation { throw 'Reservation ownership changed' }
        $result = Invoke-StepRetryFailedApps -Device $script:device -StepDefinition $script:step
        $result.CompletionState | Should -Be 'Failed'
        $result.Notes | Should -Match 'Reservation ownership changed'
        Should -Invoke Invoke-GraphApiRequest -Times 0 -Exactly
        Should -Invoke Write-UserDeviceRecords -Times 0 -Exactly
        Should -Invoke Read-ValidatedInput -Times 0 -Exactly
    }

    It 'supports absent tenant context without inventing a tenant binding' {
        $script:GraphSession = @{}
        $first = Invoke-StepRetryFailedApps -Device $script:device -StepDefinition $script:step
        $first.CompletionState | Should -Be 'TechnicianConfirmed'
        $first.Data.ContainsKey('TenantId') | Should -BeFalse
        (Get-StoredLedger)[1].TenantId | Should -BeExactly ''
        $second = Invoke-StepRetryFailedApps -Device $script:device -StepDefinition $script:step
        $second.CompletionState | Should -Be 'TechnicianConfirmed'
        $second.Data.ContainsKey('TenantId') | Should -BeFalse
        Should -Invoke Invoke-GraphApiRequest -Times 1 -Exactly
    }

    It 'refuses a receipt lacking tenant evidence when the current tenant is available' {
        $script:GraphSession = @{}
        Invoke-StepRetryFailedApps -Device $script:device -StepDefinition $script:step | Out-Null
        $script:GraphSession = @{ TenantId = 'tenant-1' }
        $result = Invoke-StepRetryFailedApps -Device $script:device -StepDefinition $script:step
        $result.CompletionState | Should -Be 'Failed'
        $result.Notes | Should -Match 'target changed \(TenantId\)'
        Should -Invoke Invoke-GraphApiRequest -Times 1 -Exactly
        Should -Invoke Read-ValidatedInput -Times 1 -Exactly
    }

    It 'leaves Demo unchanged without ledger access, writes, refresh or input' {
        $script:Runtime.IsDemoMode = $true
        $script:SyncSubmissionPersistenceFailure = $true
        $script:device.RecordId = '../invalid-for-live'
        $result = Invoke-StepRetryFailedApps -Device $script:device -StepDefinition $script:step
        $result.CompletionState | Should -Be 'Simulated'
        $result.Success | Should -BeTrue
        $script:device.SyncSubmissions.Count | Should -Be 0
        Test-Path -LiteralPath $script:storePath | Should -BeFalse
        Should -Invoke Assert-ActiveStorageReservation -Times 0 -Exactly
        Should -Invoke Resolve-LiveAutopilotContext -Times 0 -Exactly
        Should -Invoke Invoke-GraphApiRequest -Times 0 -Exactly
        Should -Invoke Write-UserDeviceRecords -Times 0 -Exactly
        Should -Invoke Read-ValidatedInput -Times 0 -Exactly
    }

    It 'refuses a Live no-failure outcome while an accepted receipt is unresolved' {
        $script:SyncSubmissionPersistenceFailure = $true
        Mock Read-ApplicationRetryChoice { return 'N' }
        { Invoke-StepRetryFailedApps -Device $script:device -StepDefinition $script:step } | Should -Throw '*unresolved durable receipt gap*'
        Should -Invoke Read-ApplicationRetryChoice -Times 0 -Exactly
        Should -Invoke Invoke-GraphApiRequest -Times 0 -Exactly
    }

    It 'saves intent durably before POST' {
        Mock Invoke-GraphApiRequest {
            $stored = Get-StoredLedger
            $stored.Count | Should -Be 1
            $stored[0].State | Should -BeExactly 'Intent'
            $stored[0].IntentAt | Should -Not -BeNullOrEmpty
        }
        $result = Invoke-StepRetryFailedApps -Device $script:device -StepDefinition $script:step
        $result.CompletionState | Should -Be 'TechnicianConfirmed'
        $result.Data.ContainsKey('ResubmittedAfterUncertainIntent') | Should -BeFalse
        Should -Invoke Invoke-GraphApiRequest -Times 1 -Exactly
    }

    It 'automatically resubmits and logs when a lost response left intent without a receipt' {
        Mock Invoke-GraphApiRequest { throw 'Response lost' }
        $lost = Invoke-StepRetryFailedApps -Device $script:device -StepDefinition $script:step
        $lost.CompletionState | Should -Be 'Failed'
        $priorIntentAt = (Get-StoredLedger)[0].IntentAt
        Mock Invoke-GraphApiRequest {}
        $resubmitted = Invoke-StepRetryFailedApps -Device $script:device -StepDefinition $script:step
        $resubmitted.CompletionState | Should -Be 'TechnicianConfirmed'
        $resubmitted.Data.ResubmittedAfterUncertainIntent | Should -BeTrue
        $resubmitted.Data.PriorIntentAt | Should -BeExactly $priorIntentAt
        $ledger = Get-StoredLedger
        @($ledger | Where-Object { $_.State -eq 'Intent' }).Count | Should -Be 1
        $accepted = @($ledger | Where-Object { $_.State -eq 'Accepted' })
        $accepted.Count | Should -Be 1
        $accepted[0].ResubmittedAfterUncertainIntent | Should -BeTrue
        Should -Invoke Write-AutopilotExpressLog -Times 1 -Exactly -ParameterFilter { $Level -eq 'WARN' -and $Message -match 'outcome is unknown' }
    }

    It 'does not POST when the intent cannot be saved, and keeps no phantom intent' {
        Mock Write-UserDeviceRecords { throw 'Synthetic intent writer failure' }
        $result = Invoke-StepRetryFailedApps -Device $script:device -StepDefinition $script:step
        $result.CompletionState | Should -Be 'Failed'
        $result.Data.SyncAccepted | Should -BeFalse
        $result.Notes | Should -Match 'Synthetic intent writer failure'
        $script:device.SyncSubmissions.Count | Should -Be 0
        Should -Invoke Invoke-GraphApiRequest -Times 0 -Exactly
        Should -Invoke Read-ValidatedInput -Times 0 -Exactly
    }

    It 'refuses to submit for a device that is not in the active session records' {
        $script:InventoryRecords = @{ Value = @(@{ RecordId = 'record-1'; Serial = 'SERIAL1'; SyncSubmissions = @() }) }
        $result = Invoke-StepRetryFailedApps -Device $script:device -StepDefinition $script:step
        $result.CompletionState | Should -Be 'Failed'
        $result.Notes | Should -Match 'active session records'
        Should -Invoke Invoke-GraphApiRequest -Times 0 -Exactly
        Should -Invoke Write-UserDeviceRecords -Times 0 -Exactly
    }
}

Describe 'Legacy sync evidence migration' {
    BeforeEach {
        $script:Runtime = @{ IsDemoMode = $false }
        $script:Storage = @{ DataPath = (Join-Path $TestDrive ([guid]::NewGuid().Guid)) }
        New-Item -ItemType Directory -Path $script:Storage.DataPath | Out-Null
        $script:storePath = Join-Path $script:Storage.DataPath 'records-store.json'
        $script:records = @(
            @{ RecordId = 'record-1'; Serial = 'SERIAL1'; SyncSubmissions = @() },
            @{ RecordId = 'record-2'; Serial = 'SERIAL2'; SyncSubmissions = @() }
        )
        Mock Assert-ActiveStorageReservation {}
        Mock Write-AutopilotExpressLog {}
        Mock Write-UserDeviceRecords { & $script:realSave -Records $Records }
        Mock Read-ApplicationRetryChoice { return 'Y' }
        $script:cycle = '22222222-2222-2222-2222-222222222222'
        $script:submittedAt = '2026-10-08T12:00:00.0000000Z'
        Set-Content -LiteralPath (Join-Path $script:Storage.DataPath 'sync-submission-record-1.json') -NoNewline -Value (@{ RecordId = 'record-1'; Serial = 'SERIAL1'; ManagedDeviceId = 'managed-1'; TenantId = 'tenant-1'; SubmittedAt = $script:submittedAt } | ConvertTo-Json -Compress)
        Set-Content -LiteralPath (Join-Path $script:Storage.DataPath ('sync-intent-submission-record-2-{0}.json' -f $script:cycle)) -NoNewline -Value (@{ RecordId = 'record-2'; Serial = 'SERIAL2'; ManagedDeviceId = 'managed-2'; IntentAt = '2026-10-09T08:00:00.0000000Z' } | ConvertTo-Json -Compress)
    }

    It 'folds receipt and intent files into matching records, saves once, then deletes them' {
        Import-LegacySyncSubmissionEvidence -Records $script:records | Should -Be 2
        $receipt = (Get-StoredLedger -RecordId 'record-1')[0]
        $receipt.State | Should -BeExactly 'Accepted'
        $receipt.CycleKey | Should -BeExactly ''
        $receipt.SubmittedAt | Should -BeExactly $script:submittedAt
        $receipt.ManagedDeviceId | Should -BeExactly 'managed-1'
        $receipt.Source | Should -BeExactly 'MigratedReceiptFile'
        $intent = (Get-StoredLedger -RecordId 'record-2')[0]
        $intent.State | Should -BeExactly 'Intent'
        $intent.CycleKey | Should -BeExactly $script:cycle
        $intent.TenantId | Should -BeExactly ''
        $intent.Source | Should -BeExactly 'MigratedIntentFile'
        @(Get-ChildItem -LiteralPath $script:Storage.DataPath -Filter 'sync-*submission-*').Count | Should -Be 0
        Should -Invoke Write-UserDeviceRecords -Times 1 -Exactly
        Should -Invoke Write-AutopilotExpressLog -Times 1 -Exactly -ParameterFilter { $Level -eq 'INFO' -and $Message -match 'files=2; ledger entries added=2; files deleted=2; kept for review=0' }
    }

    It 'is idempotent: a second run finds nothing and does not save' {
        [void](Import-LegacySyncSubmissionEvidence -Records $script:records)
        Import-LegacySyncSubmissionEvidence -Records $script:records | Should -Be 0
        $script:records[0].SyncSubmissions.Count | Should -Be 1
        Should -Invoke Write-UserDeviceRecords -Times 1 -Exactly
    }

    It 'skips duplicate evidence already in the ledger but still removes the file' {
        [void](Import-LegacySyncSubmissionEvidence -Records $script:records)
        Set-Content -LiteralPath (Join-Path $script:Storage.DataPath 'sync-submission-record-1.json') -NoNewline -Value (@{ RecordId = 'record-1'; Serial = 'SERIAL1'; ManagedDeviceId = 'managed-1'; SubmittedAt = $script:submittedAt } | ConvertTo-Json -Compress)
        Import-LegacySyncSubmissionEvidence -Records $script:records | Should -Be 1
        $script:records[0].SyncSubmissions.Count | Should -Be 1
        Test-Path -LiteralPath (Join-Path $script:Storage.DataPath 'sync-submission-record-1.json') | Should -BeFalse
        Should -Invoke Write-UserDeviceRecords -Times 1 -Exactly
    }

    It 'keeps <Label> files for review without changing records' -ForEach @(
        @{ Label = 'unmatched'; Name = 'sync-submission-record-9.json'; Content = '{"RecordId":"record-9","Serial":"SERIAL9","ManagedDeviceId":"m","SubmittedAt":"2026-10-08T12:00:00.0000000Z"}' },
        @{ Label = 'serial-mismatched'; Name = 'sync-submission-record-1.json'; Content = '{"RecordId":"record-1","Serial":"OTHER","ManagedDeviceId":"m","SubmittedAt":"2026-10-08T12:00:00.0000000Z"}' },
        @{ Label = 'unreadable'; Name = 'sync-submission-record-1.json'; Content = '{' },
        @{ Label = 'bad-timestamp'; Name = 'sync-submission-record-1.json'; Content = '{"RecordId":"record-1","Serial":"SERIAL1","ManagedDeviceId":"m","SubmittedAt":"08/10/2026"}' },
        @{ Label = 'name-mismatched'; Name = 'sync-submission-record-2.json'; Content = '{"RecordId":"record-1","Serial":"SERIAL1","ManagedDeviceId":"m","SubmittedAt":"2026-10-08T12:00:00.0000000Z"}' }
    ) {
        Get-ChildItem -LiteralPath $script:Storage.DataPath -Filter 'sync-*' | Remove-Item
        $path = Join-Path $script:Storage.DataPath $Name
        Set-Content -LiteralPath $path -Value $Content -NoNewline
        Import-LegacySyncSubmissionEvidence -Records $script:records | Should -Be 0
        Get-Content -LiteralPath $path -Raw | Should -BeExactly $Content
        $script:records[0].SyncSubmissions.Count | Should -Be 0
        Should -Invoke Write-UserDeviceRecords -Times 0 -Exactly
        Should -Invoke Write-AutopilotExpressLog -Times 1 -Exactly -ParameterFilter { $Level -eq 'WARN' -and $Message -match 'kept for review' }
    }

    It 'keeps a file that has an interrupted-save artefact' {
        $path = Join-Path $script:Storage.DataPath 'sync-submission-record-1.json'
        Set-Content -LiteralPath ('{0}.pending' -f $path) -Value 'retained-evidence' -NoNewline
        [void](Import-LegacySyncSubmissionEvidence -Records $script:records)
        Test-Path -LiteralPath $path | Should -BeTrue
        $script:records[0].SyncSubmissions.Count | Should -Be 0
        Should -Invoke Write-AutopilotExpressLog -Times 1 -Exactly -ParameterFilter { $Level -eq 'WARN' -and $Message -match 'Interrupted save recovery' }
    }

    It 'deletes nothing when the records save fails' {
        Mock Write-UserDeviceRecords { throw 'Synthetic records save failure' }
        { Import-LegacySyncSubmissionEvidence -Records $script:records } | Should -Throw '*Synthetic records save failure*'
        @(Get-ChildItem -LiteralPath $script:Storage.DataPath -Filter 'sync-*submission-*').Count | Should -Be 2
    }

    It 'does nothing in Demo mode' {
        $script:Runtime.IsDemoMode = $true
        Import-LegacySyncSubmissionEvidence -Records $script:records | Should -Be 0
        @(Get-ChildItem -LiteralPath $script:Storage.DataPath -Filter 'sync-*submission-*').Count | Should -Be 2
        Should -Invoke Assert-ActiveStorageReservation -Times 0 -Exactly
        Should -Invoke Write-UserDeviceRecords -Times 0 -Exactly
    }

    It 'honours a migrated receipt so the next sync step does not POST again' {
        [void](Import-LegacySyncSubmissionEvidence -Records $script:records)
        $script:GraphSession = @{ TenantId = 'tenant-1' }
        $script:SyncSubmissionPersistenceFailure = $false
        $script:records[0].ManagedDeviceId = 'cached'
        $script:InventoryRecords = @{ Value = $script:records }
        Mock Resolve-LiveAutopilotContext { $Device.ManagedDeviceId = 'managed-1' }
        Mock Invoke-GraphApiRequest {}
        Mock Read-ValidatedInput { return 'Y' }
        $result = Invoke-StepRetryFailedApps -Device $script:records[0] -StepDefinition @{ ActionName = 'RetryFailedApplications' }
        $result.CompletionState | Should -Be 'TechnicianConfirmed'
        $result.Data.SubmittedAt | Should -BeExactly $script:submittedAt
        Should -Invoke Invoke-GraphApiRequest -Times 0 -Exactly
    }
}
