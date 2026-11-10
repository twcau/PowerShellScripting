<#
.SYNOPSIS
    Offline regression tests for strict Graph discovery and identity evidence.
.DESCRIPTION
    Extracts required definitions through the PowerShell AST without starting the
    CLI or loading the SDK. Pester mocks every Graph request and polling pause;
    unexpected requests fail locally. Requires Pester 5 and FullLanguage parsing.
.FILECREATED
    2026-10-08
.FILELASTUPDATED
    2026-10-08
#>

BeforeAll {
    $sourcePath = Join-Path (Split-Path -Parent $PSScriptRoot) 'autopilot-express.ps1'
    $tokens = $null
    $parseErrors = $null
    $sourceAst = [System.Management.Automation.Language.Parser]::ParseFile($sourcePath, [ref]$tokens, [ref]$parseErrors)
    if ($parseErrors.Count) { throw ($parseErrors.Message -join '; ') }
    foreach ($functionName in @(
            'Get-GraphTransportFailure', 'Get-GraphOperationFailureMessage', 'Test-GraphCapabilities',
            'Get-GraphCapabilityReadCheck', 'Get-GraphDiscoveryCollection', 'Get-LivePreProvisioningGroup',
            'Get-PreProvisioningGroupLookupUri', 'Clear-PreProvisioningGroupCache', 'Resolve-LiveManagedDeviceBySerial', 'Get-ManagedDeviceSerialLookupUri',
            'ConvertTo-DirectoryUserRecord',
            'Get-LiveManagedDevicePrimaryUsers', 'Test-ManagedDevicePrimaryUserMatch',
            'Get-LiveAutopilotDeviceById', 'Wait-PrimaryUserAssignmentVerification'
        )) {
        $definition = $sourceAst.Find({ param($node) $node -is [System.Management.Automation.Language.FunctionDefinitionAst] -and $node.Name -eq $functionName }, $true)
        if ($null -eq $definition) { throw ('Missing function: {0}' -f $functionName) }
        Set-Item -Path ('Function:{0}' -f $definition.Name) -Value $definition.Body.GetScriptBlock()
    }
    function Invoke-GraphApiRequest {
        param([string]$Method, [string]$Uri, [hashtable]$Body)
        throw ('Unexpected Graph request: {0} {1}; body keys {2}.' -f $Method, $Uri, ($Body.Keys -join ','))
    }
    function Get-ConfiguredPreProvisioningGroupDisplayName { return 'Test pre-provisioning' }
}

Describe 'Stable Autopilot resource read-back' {
    It 'uses the v1.0 identity resource without beta projections or writes' {
        Mock Invoke-GraphApiRequest { return @{ id = 'auto-1'; groupTag = 'SITE-Desktop' } }
        (Get-LiveAutopilotDeviceById -AutopilotDeviceId 'auto-1').groupTag | Should -BeExactly 'SITE-Desktop'
        Should -Invoke Invoke-GraphApiRequest -Times 1 -Exactly -ParameterFilter {
            $Method -eq 'GET' -and $Uri -eq 'https://graph.microsoft.com/v1.0/deviceManagement/windowsAutopilotDeviceIdentities/auto-1'
        }
    }
    It 'accepts the documented single-resource value envelope but not a collection' {
        Mock Invoke-GraphApiRequest { return @{ value = @{ id = 'auto-1'; groupTag = 'SITE-Desktop' } } }
        (Get-LiveAutopilotDeviceById -AutopilotDeviceId 'auto-1').id | Should -Be 'auto-1'
        Mock Invoke-GraphApiRequest { return @{ value = @(@{ id = 'auto-1' }) } }
        { Get-LiveAutopilotDeviceById -AutopilotDeviceId 'auto-1' } | Should -Throw '*unexpected Autopilot identity*'
    }
    It 'refuses a mismatched identity rather than verifying another device' {
        Mock Invoke-GraphApiRequest { return @{ id = 'different-device'; groupTag = 'SITE-Desktop' } }
        { Get-LiveAutopilotDeviceById -AutopilotDeviceId 'auto-1' } | Should -Throw '*unexpected Autopilot identity*'
    }
}

Describe 'Capability preflight response safety' {
    BeforeEach {
        Mock Invoke-GraphApiRequest { return @{ value = @() } }
        Mock Get-LivePreProvisioningGroup { return @{ id = 'group'; displayName = 'Synthetic' } }
    }
    It 'accepts valid empty collections as read access, not device absence or write access' {
        $results = @(Test-GraphCapabilities)
        $results.Count | Should -Be 5
        @($results | Where-Object { -not $_.Success }).Count | Should -Be 0
    }
    It 'rejects malformed capability evidence <Label>' -ForEach @(
        @{ Label = 'null'; Response = $null }
        @{ Label = 'missing array'; Response = @{} }
        @{ Label = 'scalar'; Response = @{ value = @{ id = 'synthetic' } } }
        @{ Label = 'null item'; Response = @{ value = @($null) } }
        @{ Label = 'numeric identity'; Response = @{ value = @(@{ id = 123 }) } }
        @{ Label = 'blank identity'; Response = @{ value = @(@{ id = ' ' }) } }
    ) {
        $script:capabilityResponse = $Response
        Mock Invoke-GraphApiRequest { return $script:capabilityResponse }
        $results = @(Test-GraphCapabilities)
        @($results | Where-Object { -not $_.Success }).Count | Should -Be 4
    }
    It 'never retains SDK response text in capability failures' {
        Mock Invoke-GraphApiRequest {
            $exception = [Exception]::new('SYNTHETIC-PRIVATE-RESPONSE')
            $exception.Data['AutopilotExpress.GraphMethod'] = 'GET'
            throw $exception
        }
        $results = @(Test-GraphCapabilities)
        ($results | ConvertTo-Json -Depth 6) | Should -Not -Match 'SYNTHETIC-PRIVATE-RESPONSE'
        @($results | Where-Object { -not $_.Success }).Count | Should -Be 4
    }
}

Describe 'Complete bounded Graph discovery evidence' {
    BeforeEach {
        $script:initialUri = 'https://graph.microsoft.com/v1.0/groups?$select=id,displayName'
        $script:nextUri = 'https://graph.microsoft.com/v1.0/groups?$skiptoken=next'
        $script:response = @{ value = @(@{ id = 'group-1'; displayName = 'First group' }) }
        Mock Invoke-GraphApiRequest { return $script:response }
    }

    It 'preserves a valid empty collection as an array' {
        $script:response = @{ value = @() }
        $result = Get-GraphDiscoveryCollection -Uri $script:initialUri
        ($result -is [array]) | Should -BeTrue
        $result.Count | Should -Be 0
    }

    It 'preserves a singleton collection as an array' {
        $result = Get-GraphDiscoveryCollection -Uri $script:initialUri
        ($result -is [array]) | Should -BeTrue
        $result.Count | Should -Be 1
        $result[0].id | Should -Be 'group-1'
    }

    It 'returns all identities across pages and follows the exact continuation' {
        Mock Invoke-GraphApiRequest {
            if ($Uri -eq $script:initialUri) {
                return @{ value = @(@{ id = 'group-1'; displayName = 'First group' }); '@odata.nextLink' = $script:nextUri }
            }
            if ($Uri -eq $script:nextUri) { return @{ value = @(@{ id = 'group-2'; displayName = 'Second group' }) } }
            throw ('Unexpected continuation: {0}' -f $Uri)
        }
        $result = Get-GraphDiscoveryCollection -Uri $script:initialUri
        $result.Count | Should -Be 2
        $result[0].id | Should -Be 'group-1'
        $result[1].id | Should -Be 'group-2'
        Should -Invoke Invoke-GraphApiRequest -Times 2 -Exactly -ParameterFilter { $Method -eq 'GET' }
        Should -Invoke Invoke-GraphApiRequest -Times 1 -Exactly -ParameterFilter { $Uri -ceq $script:nextUri }
    }

    It 'rejects a <Label> collection envelope' -TestCases @(
        @{ Label = 'null body'; Response = $null }
        @{ Label = 'missing value'; Response = @{} }
        @{ Label = 'null value'; Response = @{ value = $null } }
        @{ Label = 'scalar object'; Response = @{ value = @{ id = 'group-1'; displayName = 'Group' } } }
        @{ Label = 'scalar text'; Response = @{ value = 'group-1' } }
    ) {
        param($Label, $Response)
        $script:response = $Response
        { Get-GraphDiscoveryCollection -Uri $script:initialUri } | Should -Throw '*malformed collection*' -Because $Label
        Should -Invoke Invoke-GraphApiRequest -Times 1 -Exactly
    }

    It 'rejects <Label> identity items' -TestCases @(
        @{ Label = 'null'; Item = $null }
        @{ Label = 'scalar'; Item = 'group-1' }
        @{ Label = 'missing ID'; Item = @{ displayName = 'Group' } }
        @{ Label = 'numeric ID'; Item = @{ id = 123; displayName = 'Group' } }
        @{ Label = 'blank ID'; Item = @{ id = ' '; displayName = 'Group' } }
        @{ Label = 'missing name'; Item = @{ id = 'group-1' } }
        @{ Label = 'numeric name'; Item = @{ id = 'group-1'; displayName = 123 } }
        @{ Label = 'blank name'; Item = @{ id = 'group-1'; displayName = ' ' } }
    ) {
        param($Label, $Item)
        $script:response = @{ value = @($Item) }
        { Get-GraphDiscoveryCollection -Uri $script:initialUri } | Should -Throw '*invalid identity*' -Because $Label
    }

    It 'rejects duplicate IDs within one page' {
        $script:response.value = @(@{ id = 'group-1'; displayName = 'First' }, @{ id = 'GROUP-1'; displayName = 'Second' })
        { Get-GraphDiscoveryCollection -Uri $script:initialUri } | Should -Throw '*repeated identity*'
    }

    It 'rejects duplicate IDs across pages instead of returning partial evidence' {
        Mock Invoke-GraphApiRequest {
            if ($Uri -eq $script:initialUri) {
                return @{ value = @(@{ id = 'group-1'; displayName = 'First' }); '@odata.nextLink' = $script:nextUri }
            }
            return @{ value = @(@{ id = 'group-1'; displayName = 'Repeated' }) }
        }
        { Get-GraphDiscoveryCollection -Uri $script:initialUri } | Should -Throw '*repeated identity*'
        Should -Invoke Invoke-GraphApiRequest -Times 2 -Exactly
    }

    It 'rejects a <Label> continuation before issuing another request' -TestCases @(
        @{ Label = 'HTTP'; Link = 'http://graph.microsoft.com/v1.0/groups?page=2' }
        @{ Label = 'foreign host'; Link = 'https://example.invalid/v1.0/groups?page=2' }
        @{ Label = 'host suffix'; Link = 'https://graph.microsoft.com.example.invalid/v1.0/groups?page=2' }
        @{ Label = 'non-443 port'; Link = 'https://graph.microsoft.com:444/v1.0/groups?page=2' }
        @{ Label = 'userinfo'; Link = 'https://account@graph.microsoft.com/v1.0/groups?page=2' }
        @{ Label = 'fragment'; Link = 'https://graph.microsoft.com/v1.0/groups?page=2#fragment' }
        @{ Label = 'different path'; Link = 'https://graph.microsoft.com/v1.0/users?page=2' }
        @{ Label = 'path case mismatch'; Link = 'https://graph.microsoft.com/v1.0/Groups?page=2' }
        @{ Label = 'relative URI'; Link = '/v1.0/groups?page=2' }
    ) {
        param($Label, $Link)
        $script:response['@odata.nextLink'] = $Link
        { Get-GraphDiscoveryCollection -Uri $script:initialUri } | Should -Throw '*Unsafe Graph discovery*' -Because $Label
        Should -Invoke Invoke-GraphApiRequest -Times 1 -Exactly
    }

    It 'rejects an unsafe initial URI without a request' {
        { Get-GraphDiscoveryCollection -Uri 'https://example.invalid/v1.0/groups' } | Should -Throw '*Unsafe Graph discovery*'
        Should -Invoke Invoke-GraphApiRequest -Times 0 -Exactly
    }

    It 'rejects a <Label> continuation value' -TestCases @(
        @{ Label = 'numeric'; Link = 123 }
        @{ Label = 'empty'; Link = '' }
        @{ Label = 'whitespace'; Link = ' ' }
    ) {
        param($Label, $Link)
        $script:response['@odata.nextLink'] = $Link
        { Get-GraphDiscoveryCollection -Uri $script:initialUri } | Should -Throw '*invalid continuation*' -Because $Label
        Should -Invoke Invoke-GraphApiRequest -Times 1 -Exactly
    }

    It 'rejects a two-page URI cycle without fetching the initial page twice' {
        Mock Invoke-GraphApiRequest {
            if ($Uri -eq $script:initialUri) { return @{ value = @(); '@odata.nextLink' = $script:nextUri } }
            return @{ value = @(); '@odata.nextLink' = $script:initialUri }
        }
        { Get-GraphDiscoveryCollection -Uri $script:initialUri } | Should -Throw '*repeated page*'
        Should -Invoke Invoke-GraphApiRequest -Times 2 -Exactly
        Should -Invoke Invoke-GraphApiRequest -Times 1 -Exactly -ParameterFilter { $Uri -eq $script:initialUri }
    }

    It 'accepts exactly twenty complete pages' {
        $script:pageNumber = 0
        Mock Invoke-GraphApiRequest {
            $script:pageNumber++
            $page = @{ value = @(@{ id = ('group-{0}' -f $script:pageNumber); displayName = 'Group' }) }
            if ($script:pageNumber -lt 20) { $page['@odata.nextLink'] = 'https://graph.microsoft.com/v1.0/groups?page={0}' -f ($script:pageNumber + 1) }
            return $page
        }
        $result = Get-GraphDiscoveryCollection -Uri $script:initialUri
        $result.Count | Should -Be 20
        Should -Invoke Invoke-GraphApiRequest -Times 20 -Exactly
    }

    It 'rejects a twenty-first page before requesting it' {
        $script:pageNumber = 0
        Mock Invoke-GraphApiRequest {
            $script:pageNumber++
            return @{ value = @(); '@odata.nextLink' = ('https://graph.microsoft.com/v1.0/groups?page={0}' -f ($script:pageNumber + 1)) }
        }
        { Get-GraphDiscoveryCollection -Uri $script:initialUri } | Should -Throw '*20-page limit*'
        Should -Invoke Invoke-GraphApiRequest -Times 20 -Exactly
    }

    It 'propagates a later-page failure rather than returning the first page' {
        Mock Invoke-GraphApiRequest {
            if ($Uri -eq $script:initialUri) { return @{ value = @(@{ id = 'group-1'; displayName = 'Group' }); '@odata.nextLink' = $script:nextUri } }
            throw 'Synthetic read denied'
        }
        { Get-GraphDiscoveryCollection -Uri $script:initialUri } | Should -Throw '*Synthetic read denied*'
    }
}

Describe 'Unique exact-name pre-provisioning group evidence' {
    BeforeEach {
        # A fresh Graph session per test, so the 15-minute group cache never carries an answer between tests.
        $script:GraphSession = [ordered]@{ TenantId = 'tenant-1' }
        Mock Invoke-GraphApiRequest { throw ('Unexpected request: {0} {1}' -f $Method, $Uri) }
    }

    It 'resolves an exact-name group found on a later page' {
        Mock Invoke-GraphApiRequest {
            if ($Uri -like '*skiptoken*') { return @{ value = @(@{ id = 'group-1'; displayName = 'Test pre-provisioning' }) } }
            return @{ value = @(); '@odata.nextLink' = 'https://graph.microsoft.com/v1.0/groups?$skiptoken=next' }
        }
        (Get-LivePreProvisioningGroup).id | Should -Be 'group-1'
        Should -Invoke Invoke-GraphApiRequest -Times 2 -Exactly -ParameterFilter { $Method -eq 'GET' }
    }

    It 'rejects no matching group' {
        Mock Invoke-GraphApiRequest { return @{ value = @() } }
        { Get-LivePreProvisioningGroup } | Should -Throw '*Group not found*'
    }

    It 'rejects ambiguous exact-name groups across pages' {
        Mock Invoke-GraphApiRequest {
            if ($Uri -like '*skiptoken*') { return @{ value = @(@{ id = 'group-2'; displayName = 'Test pre-provisioning' }) } }
            return @{ value = @(@{ id = 'group-1'; displayName = 'Test pre-provisioning' }); '@odata.nextLink' = 'https://graph.microsoft.com/v1.0/groups?$skiptoken=next' }
        }
        { Get-LivePreProvisioningGroup } | Should -Throw '*Multiple groups matched*'
        Should -Invoke Invoke-GraphApiRequest -Times 2 -Exactly
    }

    It 'rejects a unique group with a different display name' {
        Mock Invoke-GraphApiRequest { return @{ value = @(@{ id = 'group-1'; displayName = 'Other group' }) } }
        { Get-LivePreProvisioningGroup } | Should -Throw '*unexpected display name*'
    }

    It 'reuses a group found within the last 15 minutes without another request' {
        Mock Invoke-GraphApiRequest { return @{ value = @(@{ id = 'group-1'; displayName = 'Test pre-provisioning' }) } }
        (Get-LivePreProvisioningGroup).id | Should -Be 'group-1'
        (Get-LivePreProvisioningGroup).id | Should -Be 'group-1'
        Should -Invoke Invoke-GraphApiRequest -Times 1 -Exactly
    }

    It 'searches again after <Label>' -ForEach @(
        @{ Label = '15 minutes'; Change = { $script:GraphSession.PreProvisioningGroupCache.CachedAt = (Get-Date).ToUniversalTime().AddMinutes(-15) } }
        @{ Label = 'the cache is cleared'; Change = { Clear-PreProvisioningGroupCache } }
        @{ Label = 'a tenant change'; Change = { $script:GraphSession.TenantId = 'tenant-2' } }
    ) {
        Mock Invoke-GraphApiRequest { return @{ value = @(@{ id = 'group-1'; displayName = 'Test pre-provisioning' }) } }
        $null = Get-LivePreProvisioningGroup
        & $Change
        $null = Get-LivePreProvisioningGroup
        Should -Invoke Invoke-GraphApiRequest -Times 2 -Exactly
    }
}

Describe 'Strict managed-device serial evidence' {
    BeforeEach {
        $script:response = @{ value = @(@{ id = 'managed-1'; serialNumber = 'SERIAL1' }) }
        Mock Invoke-GraphApiRequest { return $script:response }
    }

    It 'accepts one textual matching identity' {
        (Resolve-LiveManagedDeviceBySerial -Serial 'SERIAL1').id | Should -Be 'managed-1'
    }

    It 'accepts a valid empty serial result as absence' {
        $script:response.value = @()
        Resolve-LiveManagedDeviceBySerial -Serial 'SERIAL1' | Should -BeNullOrEmpty
    }

    It 'rejects <Label> serial evidence' -TestCases @(
        @{ Label = 'null body'; Response = $null; ExpectedMessage = '*incomplete or malformed*' }
        @{ Label = 'null collection'; Response = @{ value = $null }; ExpectedMessage = '*incomplete or malformed*' }
        @{ Label = 'scalar collection'; Response = @{ value = @{ id = 'managed-1'; serialNumber = 'SERIAL1' } }; ExpectedMessage = '*incomplete or malformed*' }
        @{ Label = 'paged collection'; Response = @{ value = @(); '@odata.nextLink' = 'https://graph.microsoft.com/v1.0/deviceManagement/managedDevices?page=2' }; ExpectedMessage = '*incomplete or malformed*' }
        @{ Label = 'duplicate matches'; Response = @{ value = @(@{ id = 'managed-1'; serialNumber = 'SERIAL1' }, @{ id = 'managed-2'; serialNumber = 'SERIAL1' }) }; ExpectedMessage = '*Multiple managed devices*' }
        @{ Label = 'null item'; Response = @{ value = @($null) }; ExpectedMessage = '*missing or unexpected identity*' }
        @{ Label = 'numeric ID'; Response = @{ value = @(@{ id = 123; serialNumber = 'SERIAL1' }) }; ExpectedMessage = '*missing or unexpected identity*' }
        @{ Label = 'blank ID'; Response = @{ value = @(@{ id = ' '; serialNumber = 'SERIAL1' }) }; ExpectedMessage = '*missing or unexpected identity*' }
        @{ Label = 'numeric serial'; Response = @{ value = @(@{ id = 'managed-1'; serialNumber = 123 }) }; ExpectedMessage = '*missing or unexpected identity*' }
        @{ Label = 'wrong serial'; Response = @{ value = @(@{ id = 'managed-1'; serialNumber = 'OTHER' }) }; ExpectedMessage = '*missing or unexpected identity*' }
    ) {
        param($Label, $Response, $ExpectedMessage)
        $script:response = $Response
        { Resolve-LiveManagedDeviceBySerial -Serial 'SERIAL1' } | Should -Throw $ExpectedMessage -Because $Label
        Should -Invoke Invoke-GraphApiRequest -Times 1 -Exactly -ParameterFilter { $Method -eq 'GET' }
    }
}

Describe 'Strict managed-device users evidence' {
    BeforeEach {
        $script:response = @{ value = @(@{ id = 'user-1'; userPrincipalName = 'C1@example.invalid' }) }
        Mock Invoke-GraphApiRequest { return $script:response }
    }

    It 'converts valid textual identity evidence' {
        $result = @(Get-LiveManagedDevicePrimaryUsers -ManagedDeviceId 'managed-1')
        $result.Count | Should -Be 1
        $result[0].Id | Should -Be 'user-1'
        $result[0].UserPrincipalName | Should -Be 'C1@example.invalid'
    }

    It 'accepts a valid empty users collection' {
        $script:response.value = @()
        @(Get-LiveManagedDevicePrimaryUsers -ManagedDeviceId 'managed-1').Count | Should -Be 0
    }

    It 'rejects <Label> users evidence' -TestCases @(
        @{ Label = 'null body'; Response = $null; ExpectedMessage = '*invalid users collection*' }
        @{ Label = 'missing collection'; Response = @{}; ExpectedMessage = '*invalid users collection*' }
        @{ Label = 'null collection'; Response = @{ value = $null }; ExpectedMessage = '*invalid users collection*' }
        @{ Label = 'scalar collection'; Response = @{ value = @{ id = 'user-1'; userPrincipalName = 'C1@example.invalid' } }; ExpectedMessage = '*invalid users collection*' }
        @{ Label = 'paged collection'; Response = @{ value = @(); '@odata.nextLink' = 'https://graph.microsoft.com/v1.0/deviceManagement/managedDevices/managed-1/users?page=2' }; ExpectedMessage = '*incomplete*' }
        @{ Label = 'null item'; Response = @{ value = @($null) }; ExpectedMessage = '*invalid identity*' }
        @{ Label = 'scalar item'; Response = @{ value = @('user-1') }; ExpectedMessage = '*invalid identity*' }
        @{ Label = 'numeric ID'; Response = @{ value = @(@{ id = 123; userPrincipalName = 'C1@example.invalid' }) }; ExpectedMessage = '*invalid identity*' }
        @{ Label = 'blank ID'; Response = @{ value = @(@{ id = ' '; userPrincipalName = 'C1@example.invalid' }) }; ExpectedMessage = '*invalid identity*' }
        @{ Label = 'missing UPN'; Response = @{ value = @(@{ id = 'user-1' }) }; ExpectedMessage = '*invalid identity*' }
        @{ Label = 'numeric UPN'; Response = @{ value = @(@{ id = 'user-1'; userPrincipalName = 123 }) }; ExpectedMessage = '*invalid identity*' }
        @{ Label = 'blank UPN'; Response = @{ value = @(@{ id = 'user-1'; userPrincipalName = ' ' }) }; ExpectedMessage = '*invalid identity*' }
    ) {
        param($Label, $Response, $ExpectedMessage)
        $script:response = $Response
        { Get-LiveManagedDevicePrimaryUsers -ManagedDeviceId 'managed-1' } | Should -Throw $ExpectedMessage -Because $Label
        Should -Invoke Invoke-GraphApiRequest -Times 1 -Exactly -ParameterFilter { $Method -eq 'GET' }
    }
}

Describe 'Autopilot primary-user read-back identity guard' {
    BeforeEach {
        $script:target = @{ Id = 'user-1'; UserPrincipalName = 'C1@example.invalid' }
        $script:response = @{ id = 'auto-1'; userPrincipalName = 'C1@example.invalid' }
        Mock Invoke-GraphApiRequest { return $script:response }
        Mock Start-Sleep {}
    }

    It 'confirms a matching device ID and UPN without pausing' {
        $result = Wait-PrimaryUserAssignmentVerification -Surface Autopilot -DeviceId 'auto-1' -User $script:target -MaxAttempts 3 -IntervalSeconds 2
        $result.Confirmed | Should -BeTrue
        $result.Attempts | Should -Be 1
        Should -Invoke Invoke-GraphApiRequest -Times 1 -Exactly -ParameterFilter {
            $Method -eq 'GET' -and $Uri -eq 'https://graph.microsoft.com/v1.0/deviceManagement/windowsAutopilotDeviceIdentities/auto-1'
        }
        Should -Invoke Start-Sleep -Times 0 -Exactly
    }

    It 'rejects <Label> device evidence despite a matching UPN' -TestCases @(
        @{ Label = 'wrong ID'; Response = @{ id = 'other-device'; userPrincipalName = 'C1@example.invalid' } }
        @{ Label = 'numeric ID'; Response = @{ id = 123; userPrincipalName = 'C1@example.invalid' } }
        @{ Label = 'missing ID'; Response = @{ userPrincipalName = 'C1@example.invalid' } }
        @{ Label = 'blank ID'; Response = @{ id = ' '; userPrincipalName = 'C1@example.invalid' } }
        @{ Label = 'null body'; Response = $null }
    ) {
        param($Label, $Response)
        $script:response = $Response
        { Wait-PrimaryUserAssignmentVerification -Surface Autopilot -DeviceId 'auto-1' -User $script:target -MaxAttempts 3 -IntervalSeconds 2 } | Should -Throw '*unexpected Autopilot identity*' -Because $Label
        Should -Invoke Invoke-GraphApiRequest -Times 1 -Exactly
        Should -Invoke Start-Sleep -Times 0 -Exactly
    }
}