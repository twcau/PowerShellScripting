<#
.SYNOPSIS
    Checks persisted device and step evidence without starting the CLI.
.DESCRIPTION
    Extracts the actual production validators from their syntax tree. Synthetic
    JSON is supplied through mocked reads; path resolution, logging and UTF-8
    writes are mocked. No operational files or tenant services are accessed.
    Requires Pester 5 and FullLanguage for source parsing.
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
    foreach ($functionName in @(
            'ConvertTo-StepHashtable', 'ConvertTo-NormalisedValue', 'New-EmptyDeviceRecord',
            'Get-UserDeviceRecords', 'Assert-DeviceRecordIdentity', 'ConvertTo-RecordDate'
            'Assert-AttemptHistory', 'Test-AttemptEvidenceEqual', 'Assert-AttemptHistoryPreserved'
            'Enter-DeviceRecoveryMode', 'ConvertTo-PersistedDeviceRecord', 'ConvertTo-PersistedDate'
        )) {
        $definition = $sourceAst.Find({ param($node) $node -is [System.Management.Automation.Language.FunctionDefinitionAst] -and $node.Name -eq $functionName }, $true)
        if ($null -eq $definition) { throw ('Missing function: {0}' -f $functionName) }
        Set-Item -Path ('Function:{0}' -f $definition.Name) -Value $definition.Body.GetScriptBlock()
    }
    function Get-UserDataFilePath { throw 'Unexpected operational path resolution.' }
    function Write-Utf8File { param($Path, $Content) throw ('Unexpected write: {0}, {1}' -f $Path, $Content) }
    function Write-AutopilotExpressLog { param($Message, $Level) throw ('Unexpected log: {0}, {1}' -f $Level, $Message) }
    function Get-ManifestActionStepId { param($ActionName) throw ('Unexpected manifest lookup: {0}' -f $ActionName) }
    function Test-ManifestStepCompleted { param($Device, $StepId) throw ('Unexpected completion check: {0}, {1}' -f $Device.Serial, $StepId) }
    function Read-ValidatedInput { param($Prompt, $Default, $Type, $Choices) throw ('Unexpected prompt: {0}, {1}, {2}, {3}' -f $Prompt, $Default, $Type, ($Choices -join ',')) }
}

Describe 'Record date conversion' {
    It 'treats missing or invalid dates as absent without a caught Get-Date error' {
        Mock Get-Date { throw 'Date conversion must not generate a terminating diagnostic' }
        foreach ($value in @($null, '', ' ', 'not-a-date', @{ value = '' }, @{ value = $null })) {
            ConvertTo-RecordDate -Value $value | Should -Be ([DateTime]::MinValue)
        }
        Should -Invoke Get-Date -Times 0 -Exactly
    }
    It 'preserves date objects and parses wrapped ISO evidence with its UTC instant' {
        $date = [datetime]::new(2026, 10, 27, 15, 30, 0, [DateTimeKind]::Utc)
        ConvertTo-RecordDate -Value $date | Should -Be $date
        (ConvertTo-RecordDate -Value @{ value = '2026-10-27T23:30:00+08:00' }).ToUniversalTime() | Should -Be $date
    }
}

Describe 'Persisted device record validation' {
    BeforeEach {
        $script:jsonFixture = '{"Serial":"PERSISTED-01","RecordId":"synthetic-record"}'
        Mock Get-UserDataFilePath { return 'synthetic-persisted-state.json' }
        Mock Test-Path { return $true }
        Mock Get-Content { return $script:jsonFixture }
        Mock Write-AutopilotExpressLog {}
        Mock Write-Utf8File { throw 'Loader attempted an unexpected write.' }
    }

    It 'loads legacy records without inventing an authoritative hostname or Ethernet address' {
        $script:jsonFixture = @{ Serial = 'PERSISTED-01'; RecordId = 'synthetic-record'; IntuneDeviceName = 'OLD-AUTOPILOT-LABEL' } | ConvertTo-Json
        $loaded = Get-UserDeviceRecords
        $loaded[0].IntuneInventory.Count | Should -Be 0
        $loaded[0].IntuneDeviceName | Should -Be 'OLD-AUTOPILOT-LABEL'
    }
    It 'round-trips hostname Ethernet and inventory provenance through the actual record writer projection and loader' {
        $inventory = @{ IntuneHostName = 'FINAL-PC'; EthernetMacAddress = '10:20:30:40:50:60'; ManagedDeviceId = 'managed-1'; TenantId = ''; BuildCycleId = ''; CheckedAt = '2026-10-22T12:00:00Z'; CapturedAt = '2026-10-22T12:00:00Z'; LastSyncDateTime = '2026-10-22T11:59:00Z'; Status = 'Available'; Mode = 'Live' }
        $script:jsonFixture = @{ Serial = 'PERSISTED-01'; RecordId = 'synthetic-record'; IntuneInventory = $inventory } | ConvertTo-Json -Depth 10
        $loaded = Get-UserDeviceRecords
        $persisted = ConvertTo-PersistedDeviceRecord -Record $loaded[0]
        $script:jsonFixture = $persisted | ConvertTo-Json -Depth 20
        $reloaded = Get-UserDeviceRecords
        foreach ($field in $inventory.Keys) {
            if ($field -in @('CheckedAt', 'CapturedAt', 'LastSyncDateTime')) { ([datetime]$reloaded[0].IntuneInventory[$field]).ToUniversalTime() | Should -Be ([datetime]$inventory[$field]).ToUniversalTime() }
            else { $reloaded[0].IntuneInventory[$field] | Should -BeExactly $inventory[$field] }
        }
        Should -Invoke Write-Utf8File -Times 0 -Exactly
    }
    It 'rejects unknown or non-text inventory evidence rather than repairing it' {
        foreach ($inventory in @(@{ Unexpected = 'value' }, @{ IntuneHostName = 42 }, @{ EthernetMacAddress = @('10:20:30:40:50:60') }, @('not-a-dictionary'))) {
            $script:jsonFixture = @{ Serial = 'PERSISTED-01'; IntuneInventory = $inventory } | ConvertTo-Json -Depth 10
            { Get-UserDeviceRecords } | Should -Throw '*IntuneInventory*'
        }
        Should -Invoke Write-Utf8File -Times 0 -Exactly
    }

    It 'retains a build cycle on load without inventing one for legacy records' {
        $cycle = [guid]::NewGuid().Guid
        $script:jsonFixture = @{ Serial = 'PERSISTED-01'; RecordId = 'synthetic-record'; BuildCycleId = $cycle } | ConvertTo-Json
        $loaded = Get-UserDeviceRecords
        $loaded[0].BuildCycleId | Should -Be $cycle
        $script:jsonFixture = '{"Serial":"PERSISTED-01","RecordId":"synthetic-record"}'
        $loaded = Get-UserDeviceRecords
        $loaded[0].BuildCycleId | Should -Be ''
    }
    It 'refuses unsafe or non-string cycle identifiers before receipt selection' {
        foreach ($value in @('../different-receipt', 42, '------------------------------------', $null)) {
            $script:jsonFixture = @{ Serial = 'PERSISTED-01'; BuildCycleId = $value } | ConvertTo-Json
            { Get-UserDeviceRecords } | Should -Throw '*BuildCycleId*'
        }
    }
    It 'round-trips an ImportSubmissions ledger and defaults legacy records to an empty ledger' {
        $entry = [ordered]@{ SchemaVersion = 1; RecordId = 'synthetic-record'; TenantId = 'tenant-1'; Serial = 'PERSISTED-01'; ImportId = 'aaaaaaaa-2222-3333-4444-555555555555'; AutopilotImportId = ''; State = 'Submitting'; SubmittedAt = '2026-10-13T09:00:00.0000000Z'; RecordedAt = '2026-10-13T09:00:01.0000000Z' }
        $script:jsonFixture = @{ Serial = 'PERSISTED-01'; RecordId = 'synthetic-record'; ImportSubmissions = @($entry) } | ConvertTo-Json -Depth 10
        $loaded = Get-UserDeviceRecords
        $persisted = ConvertTo-PersistedDeviceRecord -Record $loaded[0]
        $script:jsonFixture = $persisted | ConvertTo-Json -Depth 15
        $reloaded = Get-UserDeviceRecords
        @($reloaded[0].ImportSubmissions).Count | Should -Be 1
        $reloaded[0].ImportSubmissions[0].ImportId | Should -BeExactly $entry.ImportId
        $script:jsonFixture = '{"Serial":"PERSISTED-01","RecordId":"synthetic-record"}'
        @((Get-UserDeviceRecords)[0].ImportSubmissions).Count | Should -Be 0
        Should -Invoke Write-Utf8File -Times 0 -Exactly
    }
    It 'refuses malformed ImportSubmissions evidence (<Label>) without writing repairs' -ForEach @(
        @{ Label = 'foreign record'; Change = @{ RecordId = 'other-record' } },
        @{ Label = 'foreign serial'; Change = @{ Serial = 'OTHER' } },
        @{ Label = 'unknown state'; Change = @{ State = 'Intent' } },
        @{ Label = 'hash field'; Change = @{ HardwareIdentifier = 'cHJpdmF0ZQ==' } },
        @{ Label = 'non-text value'; Change = @{ ImportId = 42 } },
        @{ Label = 'text schema version'; Change = @{ SchemaVersion = '1' } }
    ) {
        $entry = @{ SchemaVersion = 1; RecordId = 'synthetic-record'; TenantId = ''; Serial = 'PERSISTED-01'; ImportId = 'aaaaaaaa-2222-3333-4444-555555555555'; AutopilotImportId = ''; State = 'Submitting'; SubmittedAt = '2026-10-13T09:00:00.0000000Z' }
        foreach ($key in $Change.Keys) { $entry[$key] = $Change[$key] }
        $script:jsonFixture = @{ Serial = 'PERSISTED-01'; RecordId = 'synthetic-record'; ImportSubmissions = @($entry) } | ConvertTo-Json -Depth 10
        { Get-UserDeviceRecords } | Should -Throw '*ImportSubmissions*'
        Should -Invoke Write-Utf8File -Times 0 -Exactly
    }
    It 'round-trips one session load as an array and leaves legacy session evidence empty' {
        $script:jsonFixture = @{ Serial = 'PERSISTED-01'; RecordId = 'synthetic-record'; ImagingSessionStarts = @('2026-10-21T10:00:00') } | ConvertTo-Json
        $loaded = Get-UserDeviceRecords
        $persisted = ConvertTo-PersistedDeviceRecord -Record $loaded[0]
        $script:jsonFixture = $persisted | ConvertTo-Json -Depth 15
        $reloaded = Get-UserDeviceRecords
        Should -ActualValue $reloaded[0].ImagingSessionStarts -BeOfType ([array])
        @($reloaded[0].ImagingSessionStarts).Count | Should -Be 1
        $script:jsonFixture = '{"Serial":"PERSISTED-01","RecordId":"synthetic-record"}'
        $legacy = Get-UserDeviceRecords
        @($legacy[0].ImagingSessionStarts).Count | Should -Be 0
        Should -Invoke Write-Utf8File -Times 0 -Exactly
    }
    It 'refuses malformed session-load evidence without writing repairs' {
        foreach ($value in @('2026-10-21T10:00:00', @('not-a-date'), @(42), @($null))) {
            $script:jsonFixture = @{ Serial = 'PERSISTED-01'; ImagingSessionStarts = $value } | ConvertTo-Json -Depth 10
            { Get-UserDeviceRecords } | Should -Throw
        }
        Should -Invoke Write-Utf8File -Times 0 -Exactly
    }
    It 'rejects <Label> rather than replacing it with an empty session' -ForEach @(
        @{ Label = 'JSON null'; Json = 'null' }
        @{ Label = 'empty content'; Json = '' }
        @{ Label = 'whitespace content'; Json = '   ' }
    ) {
        $script:jsonFixture = $Json
        { Get-UserDeviceRecords } | Should -Throw
        Should -Invoke Write-Utf8File -Times 0 -Exactly
    }

    It 'rejects non-dictionary records in an array' {
        foreach ($json in @('[false]', '[1]', '["false"]', '[null]', '[{"Serial":"PERSISTED-01"},false]')) {
            $script:jsonFixture = $json
            { Get-UserDeviceRecords } | Should -Throw
        }
        Should -Invoke Write-Utf8File -Times 0 -Exactly
    }

    It 'rejects non-Boolean device flag <Field>' -ForEach @(
        @{ Field = 'IsCompletionVerified' }
        @{ Field = 'RecoveryActive' }
    ) {
        foreach ($badValue in @('false', 0, 1, @($false), $null)) {
            $record = @{ Serial = 'PERSISTED-01' }
            $record[$Field] = $badValue
            $script:jsonFixture = ConvertTo-Json -InputObject $record -Depth 12
            { Get-UserDeviceRecords } | Should -Throw '*must be a Boolean*'
        }
        Should -Invoke Write-Utf8File -Times 0 -Exactly
    }

    It 'rejects non-string text fields before coercing their values' {
        foreach ($field in @(
                'RecordId', 'Serial', 'ConfigItem', 'AutopilotDeviceId', 'ManagedDeviceId', 'AzureAdDeviceId',
                'EntraDeviceId', 'IntuneDeviceName', 'SiteCode', 'DeviceType', 'GroupTag', 'Status',
                'StartedBy', 'LastUpdatedBy', 'CompletedBy', 'RecoveryReason', 'TechnicianUserPrincipalName',
                'TechnicianUser', 'FinalPrimaryUserId', 'FinalPrimaryUserPrincipalName', 'FinalPrimaryUser',
                'FinalPrimaryUserDisplayName', 'FinalPrimaryUserName'
            )) {
            foreach ($badValue in @(42, $false, @('text'), @{ value = 'text' })) {
                $record = @{ Serial = 'PERSISTED-01' }
                $record[$field] = $badValue
                $script:jsonFixture = ConvertTo-Json -InputObject $record -Depth 12
                { Get-UserDeviceRecords } | Should -Throw '*must be text*'
            }
        }
        Should -Invoke Write-Utf8File -Times 0 -Exactly
    }

    It 'rejects invalid device dates and invalid wrapped date types' {
        foreach ($field in @('StartedAt', 'LastUpdatedAt', 'CompletedAt', 'RecoveryStartedAt')) {
            foreach ($badValue in @('not-a-date', 42, @('2026-10-08'), @{ value = 'not-a-date' }, @{ value = $false })) {
                $record = @{ Serial = 'PERSISTED-01' }
                $record[$field] = $badValue
                $script:jsonFixture = ConvertTo-Json -InputObject $record -Depth 12
                { Get-UserDeviceRecords } | Should -Throw
            }
        }
        Should -Invoke Write-Utf8File -Times 0 -Exactly
    }

    It 'rejects explicitly null Steps at the loader boundary' {
        $script:jsonFixture = '{"Serial":"PERSISTED-01","Steps":null}'
        { Get-UserDeviceRecords } | Should -Throw '*Steps cannot be null*'
        Should -Invoke Write-Utf8File -Times 0 -Exactly
    }

    It 'rejects non-array recovery history' {
        foreach ($badValue in @('false', 1, $false, @{ Stage = 'Started'; Actor = 'synthetic'; Timestamp = '2026-10-08T10:00:00Z' })) {
            $script:jsonFixture = ConvertTo-Json -InputObject @{ Serial = 'PERSISTED-01'; RecoveryHistory = $badValue } -Depth 12
            { Get-UserDeviceRecords } | Should -Throw '*history must be an array*'
        }
        Should -Invoke Write-Utf8File -Times 0 -Exactly
    }

    It 'preserves valid recovery history with <Count> entries after JSON reload' -ForEach @(
        @{ Count = 1 }
        @{ Count = 2 }
    ) {
        $history = @(for ($index = 0; $index -lt $Count; $index++) {
                @{ Stage = 'RecoveryEntered'; Actor = 'synthetic'; Timestamp = '2026-10-12T17:00:00Z'; Steps = @{} }
            })
        $script:jsonFixture = ConvertTo-Json -InputObject @{ Serial = 'PERSISTED-01'; RecoveryHistory = $history } -Depth 20
        $records = Get-UserDeviceRecords
        $records[0].RecoveryHistory.Count | Should -Be $Count
        foreach ($entry in $records[0].RecoveryHistory) {
            ($entry -is [System.Collections.IDictionary]) | Should -BeTrue
            $entry.Stage | Should -Be 'RecoveryEntered'
            $entry.Actor | Should -Be 'synthetic'
        }
        Should -Invoke Write-Utf8File -Times 0 -Exactly
    }

    It 'rejects non-dictionary recovery history entries' {
        foreach ($badValue in @('false', 1, $false, $null, @('entry'))) {
            $script:jsonFixture = ConvertTo-Json -InputObject @{ Serial = 'PERSISTED-01'; RecoveryHistory = @($badValue) } -Depth 12
            { Get-UserDeviceRecords } | Should -Throw '*entries must be dictionaries*'
        }
        Should -Invoke Write-Utf8File -Times 0 -Exactly
    }

    It 'reloads recovery entered after loading <Label> history without introducing null entries' -ForEach @(
        @{ Label = 'missing'; Json = '{"Serial":"PERSISTED-01"}' }
        @{ Label = 'empty'; Json = '{"Serial":"PERSISTED-01","RecoveryHistory":[]}' }
        @{ Label = 'legacy null'; Json = '{"Serial":"PERSISTED-01","RecoveryHistory":null}' }
    ) {
        Mock Get-ManifestActionStepId {
            switch ($ActionName) {
                'ResolveAutopilotDevice' { return 'A' }
                'ClearUserlessEnrollmentStatus' { return 'F' }
                'ConfirmRecoveryReadiness' { return 'Q' }
                default { throw 'Unexpected recovery action.' }
            }
        }
        Mock Test-ManifestStepCompleted { return $true }
        Mock Read-ValidatedInput { return 'Y' }
        Mock Write-Host {}
        $script:jsonFixture = $Json
        $records = Get-UserDeviceRecords
        Enter-DeviceRecoveryMode -Device $records[0]
        $script:jsonFixture = ConvertTo-Json -InputObject (ConvertTo-PersistedDeviceRecord -Record $records[0]) -Depth 100
        $reloaded = Get-UserDeviceRecords
        $reloaded[0].RecoveryActive | Should -BeTrue
        ($reloaded[0].RecoveryHistory -is [array]) | Should -BeTrue
        $reloaded[0].RecoveryHistory.Count | Should -Be 1
        ($reloaded[0].RecoveryHistory[0] -is [System.Collections.IDictionary]) | Should -BeTrue
        $reloaded[0].RecoveryHistory[0].Stage | Should -Be 'RecoveryEntered'
        $reloaded[0].RecoveryHistory[0].Reason | Should -Be 'Y'
        Should -Invoke Write-Utf8File -Times 0 -Exactly
    }

    It 'locates a malformed <Label> entry without exposing contents or writing repairs' -ForEach @(
        @{ Label = 'null'; BadValue = $null; ExpectedType = 'null' }
        @{ Label = 'text'; BadValue = 'sensitive-content'; ExpectedType = 'String' }
        @{ Label = 'nested array'; BadValue = @('sensitive-content'); ExpectedType = 'Object[]' }
    ) {
        $validEntry = @{ Stage = 'Started'; Actor = 'synthetic'; Timestamp = '2026-10-12T17:00:00Z' }
        $history = @($validEntry) + , $BadValue
        $script:jsonFixture = ConvertTo-Json -InputObject @(
            @{ Serial = 'PERSISTED-01' }
            @{ Serial = 'SENSITIVE-RECORD-02'; RecoveryHistory = $history }
        ) -Depth 20
        $failureMessage = ''
        try { $null = Get-UserDeviceRecords }
        catch { $failureMessage = $_.Exception.Message }
        $failureMessage | Should -Match ([regex]::Escape(('Record 2; history entry 2; type {0}.' -f $ExpectedType)))
        $failureMessage | Should -Not -Match 'SENSITIVE-RECORD|sensitive-content'
        $failureMessage | Should -Match 'no automatic repair or action replay'
        Should -Invoke Write-Utf8File -Times 0 -Exactly
    }

    It 'requires non-empty string history field <Field>' -ForEach @(
        @{ Field = 'Stage' }
        @{ Field = 'Actor' }
        @{ Field = 'Timestamp' }
    ) {
        foreach ($badValue in @($null, '', '   ', 42, $false, @('text'))) {
            $entry = @{ Stage = 'Started'; Actor = 'synthetic'; Timestamp = '2026-10-08T10:00:00Z' }
            $entry[$Field] = $badValue
            $script:jsonFixture = ConvertTo-Json -InputObject @{ Serial = 'PERSISTED-01'; RecoveryHistory = @($entry) } -Depth 12
            { Get-UserDeviceRecords } | Should -Throw '*requires text field*'
        }
        $entry.Remove($Field)
        $script:jsonFixture = ConvertTo-Json -InputObject @{ Serial = 'PERSISTED-01'; RecoveryHistory = @($entry) } -Depth 12
        { Get-UserDeviceRecords } | Should -Throw '*requires text field*'
        Should -Invoke Write-Utf8File -Times 0 -Exactly
    }

    It 'validates history dates and embedded step evidence' {
        foreach ($entry in @(
                @{ Stage = 'Started'; Actor = 'synthetic'; Timestamp = 'not-a-date' },
                @{ Stage = 'Started'; Actor = 'synthetic'; Timestamp = '2026-10-08T10:00:00Z'; Steps = @('bad') },
                @{ Stage = 'Started'; Actor = 'synthetic'; Timestamp = '2026-10-08T10:00:00Z'; Steps = @{ A = @{ Completed = 'false' } } }
            )) {
            $script:jsonFixture = ConvertTo-Json -InputObject @{ Serial = 'PERSISTED-01'; RecoveryHistory = @($entry) } -Depth 12
            { Get-UserDeviceRecords } | Should -Throw
        }
        Should -Invoke Write-Utf8File -Times 0 -Exactly
    }

    It 'loads valid <Label> without operational writes' -ForEach @(
        @{ Label = 'single object'; Json = '{"Serial":"PERSISTED-01","IsCompletionVerified":false,"RecoveryActive":true}'; Count = 1 }
        @{ Label = 'multiple-record array'; Json = '[{"Serial":"PERSISTED-01"},{"Serial":"PERSISTED-02"}]'; Count = 2 }
        @{ Label = 'empty array'; Json = '[]'; Count = 0 }
        @{ Label = 'legacy null recovery history'; Json = '{"Serial":"PERSISTED-01","RecoveryHistory":null}'; Count = 1 }
    ) {
        $script:jsonFixture = $Json
        $records = Get-UserDeviceRecords
        ($records -is [array]) | Should -BeTrue
        $records.Count | Should -Be $Count
        if ($Count -gt 0) {
            $records[0].Serial | Should -Be 'PERSISTED-01'
            ($records[0].RecoveryHistory -is [array]) | Should -BeTrue
            $records[0].RecoveryHistory.Count | Should -Be 0
            $records[0].Steps.Count | Should -Be 0
        }
        if ($Label -eq 'single object') {
            $records[0].IsCompletionVerified | Should -BeFalse
            $records[0].RecoveryActive | Should -BeTrue
        }
        if ($Count -eq 2) { $records[1].Serial | Should -Be 'PERSISTED-02' }
        Should -Invoke Write-Utf8File -Times 0 -Exactly
    }

    It 'loads legacy wrapped ISO dates without discarding their values' {
        $date = '2026-10-08T10:00:00Z'
        $record = @{ Serial = 'PERSISTED-01'; Steps = @{ A = @{ Completed = $true; Timestamp = @{ value = $date }; InvalidatedAt = @{ value = $date } } } }
        foreach ($field in @('StartedAt', 'LastUpdatedAt', 'CompletedAt', 'RecoveryStartedAt')) { $record[$field] = @{ value = $date } }
        $script:jsonFixture = ConvertTo-Json -InputObject $record -Depth 12
        $records = Get-UserDeviceRecords
        foreach ($field in @('StartedAt', 'LastUpdatedAt', 'CompletedAt', 'RecoveryStartedAt')) {
            $records[0][$field].ToUniversalTime() | Should -Be ([datetime]$date).ToUniversalTime()
        }
        $records[0].Steps.A.CompletionState | Should -Be 'LegacyCompleted'
        ([datetime]$records[0].Steps.A.Timestamp.value).ToUniversalTime() | Should -Be ([datetime]$date).ToUniversalTime()
        ([datetime]$records[0].Steps.A.InvalidatedAt.value).ToUniversalTime() | Should -Be ([datetime]$date).ToUniversalTime()
        Should -Invoke Write-Utf8File -Times 0 -Exactly
    }

    It 'round-trips history arrays, typed flags and embedded legacy evidence' {
        $script:jsonFixture = '{"Serial":"PERSISTED-01","RecordId":"synthetic-record","RecoveryHistory":[{"Stage":"Started","Actor":"synthetic","Timestamp":"2026-10-08T10:00:00Z","Steps":{"A":{"Completed":true,"Data":{"Checklist":["one"]}}}},{"Stage":"Allowed","Actor":"synthetic","Timestamp":"2026-10-08T11:00:00Z","Steps":{"F":{"Success":false,"CompletionState":"Submitted"}}}]}'
        $records = Get-UserDeviceRecords
        $records[0].RecoveryHistory.Count | Should -Be 2
        $records[0].RecoveryHistory[0].Steps.A.CompletionState | Should -Be 'LegacyCompleted'
        $records[0].RecoveryHistory[0].Steps.A.Completed | Should -BeTrue
        ($records[0].RecoveryHistory[0].Steps.A.Data.Checklist -is [array]) | Should -BeTrue
        $records[0].RecoveryHistory[1].Steps.F.Success | Should -BeFalse
        $script:jsonFixture = ConvertTo-Json -InputObject (ConvertTo-NormalisedValue -Value $records[0]) -Depth 12
        $reloaded = Get-UserDeviceRecords
        $reloaded[0].RecoveryHistory.Count | Should -Be 2
        $reloaded[0].RecoveryHistory[0].Actor | Should -Be 'synthetic'
        ([datetime]$reloaded[0].RecoveryHistory[0].Timestamp).ToUniversalTime() | Should -Be ([datetime]'2026-10-08T10:00:00Z').ToUniversalTime()
        $reloaded[0].RecoveryHistory[0].Steps.A.Data.Checklist.Count | Should -Be 1
        $reloaded[0].RecoveryHistory[0].Steps.A.Data.Checklist[0] | Should -Be 'one'
        $reloaded[0].RecoveryHistory[1].Stage | Should -Be 'Allowed'
        $reloaded[0].RecoveryHistory[1].Steps.F.CompletionState | Should -Be 'Submitted'
        Should -Invoke Write-Utf8File -Times 0 -Exactly
    }

    It 'preserves missing-file startup without reading or writing' {
        Mock Test-Path { return $false }
        $records = Get-UserDeviceRecords
        $records.Count | Should -Be 0
        Should -Invoke Get-Content -Times 0 -Exactly
        Should -Invoke Write-Utf8File -Times 0 -Exactly
    }
}

Describe 'Persisted step evidence validation' {
    It 'rejects a non-dictionary <Label> step map' -ForEach @(
        @{ Label = 'string'; Value = 'false' }
        @{ Label = 'number'; Value = 1 }
        @{ Label = 'array'; Value = @(@{ Completed = $true }) }
    ) {
        { ConvertTo-StepHashtable -Value $Value } | Should -Throw '*Steps must be a dictionary*'
    }

    It 'rejects non-dictionary step entries' {
        foreach ($badValue in @($null, 'false', 1, @(@{ Completed = $true }))) {
            { ConvertTo-StepHashtable -Value @{ A = $badValue } } | Should -Throw '*must be a dictionary*'
        }
    }

    It 'rejects non-dictionary Data' {
        foreach ($badValue in @($null, 'false', 1, @('evidence'))) {
            { ConvertTo-StepHashtable -Value @{ A = @{ Data = $badValue } } } | Should -Throw '*data must be a dictionary*'
        }
    }

    It 'rejects invalid <Field> evidence dates' -ForEach @(
        @{ Field = 'Timestamp' }
        @{ Field = 'InvalidatedAt' }
    ) {
        foreach ($badValue in @('not-a-date', 42, $false, @('2026-10-08'), @{ value = 'not-a-date' })) {
            $step = @{ Completed = $true }
            $step[$Field] = $badValue
            { ConvertTo-StepHashtable -Value @{ A = $step } } | Should -Throw
        }
    }

    It 'rejects unsupported completion states and non-string state values' {
        foreach ($badValue in @('Complete', '', 'false', $false, 1, $null, @('Verified'))) {
            { ConvertTo-StepHashtable -Value @{ A = @{ CompletionState = $badValue } } } | Should -Throw '*unsupported completion state*'
        }
    }

    It 'rejects malicious non-Boolean <Field> flags even with an explicit state' -ForEach @(
        @{ Field = 'Completed' }
        @{ Field = 'Success' }
        @{ Field = 'IsSimulated' }
    ) {
        foreach ($badValue in @('false', 'true', 0, 1, @($false), $null)) {
            $step = @{ CompletionState = 'Verified' }
            $step[$Field] = $badValue
            { ConvertTo-StepHashtable -Value @{ A = $step } } | Should -Throw '*must be a Boolean*'
        }
    }

    It 'migrates typed legacy <Field>=<Flag> to <State>' -ForEach @(
        @{ Field = 'Completed'; Flag = $true; State = 'LegacyCompleted' }
        @{ Field = 'Completed'; Flag = $false; State = 'Failed' }
        @{ Field = 'Success'; Flag = $true; State = 'LegacyCompleted' }
        @{ Field = 'Success'; Flag = $false; State = 'Failed' }
    ) {
        $step = @{ IsSimulated = $false; Data = @{} }
        $step[$Field] = $Flag
        $converted = ConvertTo-StepHashtable -Value @{ A = $step }
        $converted.A.CompletionState | Should -Be $State
        $converted.A[$Field] | Should -BeOfType [bool]
        $converted.A[$Field] | Should -Be $Flag
    }

    It 'accepts every explicit known state without inferring completion from false Success' {
        foreach ($state in @('Verified', 'TechnicianConfirmed', 'Submitted', 'Blocked', 'Failed', 'AuditedException', 'Simulated', 'LegacyCompleted')) {
            $converted = ConvertTo-StepHashtable -Value @{ A = @{ Success = $false; Completed = $false; IsSimulated = $false; CompletionState = $state } }
            $converted.A.CompletionState | Should -Be $state
            $converted.A.Success | Should -BeFalse
            $converted.A.Completed | Should -BeFalse
        }
    }

    It 'preserves direct null step compatibility as an empty dictionary' {
        $converted = ConvertTo-StepHashtable -Value $null
        $converted | Should -BeOfType [hashtable]
        $converted.Count | Should -Be 0
    }

    It 'does not mutate caller-owned flags, nested data or arrays during migration' {
        $original = [ordered]@{ A = [ordered]@{ Completed = $true; Data = @{ Checklist = @('one'); Nested = @{ Evidence = 'original' } } } }
        $baseline = ConvertTo-Json -InputObject $original -Depth 12 -Compress
        $converted = ConvertTo-StepHashtable -Value $original
        (ConvertTo-Json -InputObject $original -Depth 12 -Compress) | Should -BeExactly $baseline
        $original.A.Contains('CompletionState') | Should -BeFalse
        $converted.A.CompletionState | Should -Be 'LegacyCompleted'
        $converted.A.Data.Checklist[0] = 'changed'
        $converted.A.Data.Nested.Evidence = 'changed'
        $converted.A.Completed = $false
        $original.A.Data.Checklist[0] | Should -Be 'one'
        $original.A.Data.Nested.Evidence | Should -Be 'original'
        $original.A.Completed | Should -BeTrue
    }
}