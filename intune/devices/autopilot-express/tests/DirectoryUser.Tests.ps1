<#
.SYNOPSIS
    Regression tests for technician-directed directory user eligibility.
.DESCRIPTION
    Loads only the required function definitions, without running the CLI,
    accessing operational records, or connecting to Graph. Requires Pester 5.
#>

BeforeAll {
    $sourcePath = Join-Path (Split-Path -Parent $PSScriptRoot) 'autopilot-express.ps1'
    $tokens = $null
    $parseErrors = $null
    $sourceAst = [System.Management.Automation.Language.Parser]::ParseFile($sourcePath, [ref]$tokens, [ref]$parseErrors)
    if ($parseErrors.Count -gt 0) { throw ($parseErrors.Message -join [Environment]::NewLine) }
    $requiredFunctions = @('Get-UserLocalPart', 'Test-DirectoryUserMatchesConfiguredPrefixes', 'Get-DirectoryUserEligibilityMessage', 'Test-EligibleDirectoryUser', 'Get-EligibleDirectoryUsers', 'ConvertTo-DirectoryUserRecord', 'Save-RecentUsers', 'Get-ConfiguredDirectorySearchPageLimit', 'Test-DirectoryUserSearchMatch', 'Get-DirectoryUserSearchRank', 'Get-DirectoryUserSearchResult', 'Search-DemoDirectoryUsers', 'Search-LiveDirectoryUsers', 'Select-UserFromResults')
    foreach ($functionName in $requiredFunctions) {
        $definition = $sourceAst.Find({ param($node) $node -is [System.Management.Automation.Language.FunctionDefinitionAst] -and $node.Name -eq $functionName }, $true)
        if ($null -eq $definition) { throw ('Missing function: {0}' -f $functionName) }
        Set-Item -Path ('Function:{0}' -f $definition.Name) -Value $definition.Body.GetScriptBlock()
    }
    $approximation = $sourceAst.Find({ param($node) $node -is [System.Management.Automation.Language.FunctionDefinitionAst] -and $node.Name -eq 'Test-NameWordApproximation' }, $true)
    Set-Item -Path ('Function:{0}' -f $approximation.Name) -Value $approximation.Body.GetScriptBlock()
    foreach ($functionName in @('Resolve-LiveDirectoryUserRecord', 'Resolve-EligibleDirectoryUser', 'Select-DirectoryUser', 'Add-RecentUser', 'Get-GraphTransportFailure', 'Get-GraphOperationFailureMessage')) {
        $definition = $sourceAst.Find({ param($node) $node -is [System.Management.Automation.Language.FunctionDefinitionAst] -and $node.Name -eq $functionName }, $true)
        Set-Item -Path ('Function:{0}' -f $definition.Name) -Value $definition.Body.GetScriptBlock()
    }
    function Get-ConfiguredRecentUserLimit { return 3 }
    function Write-AutopilotExpressLog { param($Message, $Level) throw ('Unexpected log: {0}: {1}' -f $Level, $Message) }
    function Get-ConfiguredTechnicianPrefixes { return @('C', 'E') }
    function Get-ConfiguredSearchLimit { return 15 }
    function Read-ValidatedInput {
        param([string]$Prompt, [string]$Default, [string]$Type)
        throw ('Unexpected prompt: {0}; default: {1}; type: {2}' -f $Prompt, $Default, $Type)
    }
    function Get-RecentUsers { return , $script:directoryFixtures }
    function Invoke-GraphApiRequest {
        param([string]$Method, [string]$Uri, [hashtable]$Headers)
        throw ('Unexpected Graph request: {0} {1}; headers={2}' -f $Method, $Uri, $Headers.Count)
    }
    function Get-RecentUsersFilePath { return (Join-Path $TestDrive 'recent-users.json') }
    function Write-Utf8File {
        param([string]$Path, [string]$Content)
        Set-Content -LiteralPath $Path -Value $Content -Encoding UTF8 -ErrorAction Stop
    }
}

Describe 'Fresh directory identity authority' {
    BeforeEach {
        $script:Runtime = @{ IsDemoMode = $false }
        $script:selectedAccount = @{ Id = 'account-1'; DisplayName = 'Synthetic One'; UserPrincipalName = 'E1@example.invalid'; AccountEnabled = $true }
        Mock Write-Host {}
        Mock Write-AutopilotExpressLog {}
        Mock Invoke-GraphApiRequest { return $script:selectedAccount }
    }
    It 'uses the immutable selected ID and returns the current account name' {
        $candidate = @{ Id = 'account-1'; UserPrincipalName = 'Eold@example.invalid' }
        (Resolve-EligibleDirectoryUser -User $candidate).UserPrincipalName | Should -Be 'E1@example.invalid'
        Should -Invoke Invoke-GraphApiRequest -Times 1 -Exactly -ParameterFilter { $Method -eq 'GET' -and $Uri -like '*/users/account-1?*' }
    }
    It 'uses the fresh Windows username rather than the selected cached prefix' {
        $script:selectedAccount.UserPrincipalName = 'person@example.invalid'
        $script:selectedAccount.OnPremisesSamAccountName = 'C123'
        (Resolve-EligibleDirectoryUser -User @{ Id = 'account-1'; UserPrincipalName = 'old@example.invalid' }).OnPremisesSamAccountName | Should -Be C123
        $script:selectedAccount.OnPremisesSamAccountName = 'AC123'
        Resolve-EligibleDirectoryUser -User @{ Id = 'account-1'; UserPrincipalName = 'C123@example.invalid' } | Should -BeNullOrEmpty
    }
    It 'refuses a different ID returned for the selected account' {
        Mock Invoke-GraphApiRequest { return @{ Id = 'account-2'; UserPrincipalName = 'E2@example.invalid'; AccountEnabled = $true } }
        Resolve-EligibleDirectoryUser -User $script:selectedAccount | Should -BeNullOrEmpty
    }
    It 'refuses malformed fresh enabled status <State>' -TestCases @(
        @{ State = 'false' }, @{ State = 1 }, @{ State = $null }
    ) {
        param($State)
        $script:selectedAccount.AccountEnabled = $State
        Resolve-EligibleDirectoryUser -User $script:selectedAccount | Should -BeNullOrEmpty
    }
    It 'refuses disabled and newly ineligible fresh accounts' -TestCases @(
        @{ Enabled = $false; Upn = 'E1@example.invalid' }
        @{ Enabled = $true; Upn = 'X1@example.invalid' }
    ) {
        param($Enabled, $Upn)
        $script:selectedAccount.AccountEnabled = $Enabled
        $script:selectedAccount.UserPrincipalName = $Upn
        Resolve-EligibleDirectoryUser -User $script:selectedAccount | Should -BeNullOrEmpty
    }
    It 'refuses <Kind> UPN lookup responses rather than choosing the first account' -TestCases @(
        @{ Kind = 'duplicate'; Response = @{ value = @(@{ id = 'one'; userPrincipalName = 'E1@example.invalid'; accountEnabled = $true }, @{ id = 'two'; userPrincipalName = 'E1@example.invalid'; accountEnabled = $true }) } }
        @{ Kind = 'wrong identity'; Response = @{ value = @(@{ id = 'two'; userPrincipalName = 'E2@example.invalid'; accountEnabled = $true }) } }
        @{ Kind = 'incomplete'; Response = @{ value = @(@{ id = 'one'; userPrincipalName = 'E1@example.invalid'; accountEnabled = $true }); '@odata.nextLink' = 'https://graph.microsoft.com/v1.0/users?$skiptoken=next' } }
        @{ Kind = 'scalar'; Response = @{ value = @{ id = 'one'; userPrincipalName = 'E1@example.invalid'; accountEnabled = $true } } }
        @{ Kind = 'empty'; Response = @{ value = @() } }
        @{ Kind = 'missing'; Response = $null }
    ) {
        param($Kind, $Response)
        $script:revalidationResponse = $Response
        Mock Invoke-GraphApiRequest { return $script:revalidationResponse }
        Resolve-LiveDirectoryUserRecord -User @{ UserPrincipalName = 'E1@example.invalid' } | Should -BeNullOrEmpty -Because $Kind
        Should -Invoke Invoke-GraphApiRequest -Times 1 -Exactly
    }
    It 'encodes UPN filter literals and preserves a single exact match' {
        $script:quotedUpn = "E'o&name@example.invalid"
        Mock Invoke-GraphApiRequest { return @{ value = @(@{ id = 'one'; userPrincipalName = $script:quotedUpn; accountEnabled = $true }) } }
        (Resolve-LiveDirectoryUserRecord -User @{ UserPrincipalName = $script:quotedUpn }).Id | Should -Be one
        Should -Invoke Invoke-GraphApiRequest -Times 1 -Exactly -ParameterFilter {
            $Uri -like '*%26*' -and [uri]::UnescapeDataString($Uri) -like "*userPrincipalName eq 'E''o&name@example.invalid'*"
        }
    }
    It 'returns safely on a read failure without retaining SDK text' {
        Mock Invoke-GraphApiRequest {
            $failure = [InvalidOperationException]::new('SYNTHETIC_PRIVATE_BODY')
            $failure.Data['AutopilotExpress.GraphMethod'] = 'GET'
            throw $failure
        }
        Resolve-EligibleDirectoryUser -User $script:selectedAccount | Should -BeNullOrEmpty
        Should -Invoke Write-AutopilotExpressLog -Times 1 -Exactly -ParameterFilter { $Message -notlike '*SYNTHETIC_PRIVATE_BODY*' }
        Should -Invoke Invoke-GraphApiRequest -Times 1 -Exactly
    }
    It 'does not revalidate a cancelled selection' {
        Mock Read-ValidatedInput { return '0' }
        Select-DirectoryUser | Should -BeNullOrEmpty
        Should -Invoke Invoke-GraphApiRequest -Times 0 -Exactly
    }
    It 'revalidates a recent account selected explicitly' {
        $script:answers = [System.Collections.Generic.Queue[string]]::new()
        $script:answers.Enqueue('1')
        $script:answers.Enqueue('1')
        Mock Read-ValidatedInput { return $script:answers.Dequeue() }
        Mock Get-RecentUsers { return , @($script:selectedAccount) }
        (Select-DirectoryUser).Id | Should -Be account-1
        Should -Invoke Invoke-GraphApiRequest -Times 1 -Exactly
    }
    It 'uses Demo identities without a Graph request' {
        $script:Runtime.IsDemoMode = $true
        (Resolve-EligibleDirectoryUser -User $script:selectedAccount).Id | Should -Be account-1
        Should -Invoke Invoke-GraphApiRequest -Times 0 -Exactly
    }
}

Describe 'Directory user eligibility' {
    It 'rejects disabled dictionary-backed users' {
        $user = [ordered]@{ UserPrincipalName = 'C123@example.invalid'; AccountEnabled = $false }
        Test-EligibleDirectoryUser -User $user | Should -BeFalse
        Get-DirectoryUserEligibilityMessage -User $user | Should -Be 'C123@example.invalid is not an active account.'
    }

    It 'rejects disabled object-backed users' {
        $user = [pscustomobject]@{ UserPrincipalName = 'E123@example.invalid'; AccountEnabled = $false }
        Test-EligibleDirectoryUser -User $user | Should -BeFalse
    }

    It 'accepts enabled users with case-insensitive permitted prefixes' {
        $user = @{ UserPrincipalName = 'e123@example.invalid'; AccountEnabled = $true }
        Test-EligibleDirectoryUser -User $user | Should -BeTrue
    }

    It 'preserves compatibility for legacy records without account state' {
        Test-EligibleDirectoryUser -User @{ UserPrincipalName = 'C123@example.invalid' } | Should -BeTrue
    }

    It 'rejects unapproved prefixes even when enabled' {
        $user = @{ UserPrincipalName = 'X123@example.invalid'; AccountEnabled = $true }
        Test-EligibleDirectoryUser -User $user | Should -BeFalse
    }

    It 'rejects missing users and missing principal names' {
        Test-EligibleDirectoryUser -User $null | Should -BeFalse
        Test-EligibleDirectoryUser -User @{ AccountEnabled = $true } | Should -BeFalse
    }

    It 'sorts eligible dictionaries by name and then principal name' {
        $users = @(
            [ordered]@{ DisplayName = 'Zed'; UserPrincipalName = 'C2@example.invalid'; AccountEnabled = $true }
            [ordered]@{ DisplayName = 'Amy'; UserPrincipalName = 'E2@example.invalid'; AccountEnabled = $true }
            [ordered]@{ DisplayName = 'Amy'; UserPrincipalName = 'C1@example.invalid'; AccountEnabled = $true }
            [ordered]@{ DisplayName = 'Aaron'; UserPrincipalName = 'C0@example.invalid'; AccountEnabled = $false }
        )
        $results = @(Get-EligibleDirectoryUsers -Users $users)
        $results.Count | Should -Be 3
        ($results | ForEach-Object { $_.UserPrincipalName }) -join ',' | Should -Be 'C1@example.invalid,E2@example.invalid,C2@example.invalid'
    }

    It 'accepts an empty eligible-user collection' {
        @(Get-EligibleDirectoryUsers -Users @()).Count | Should -Be 0
    }

    It 'persists dictionary identity and disabled state in a single-user array' {
        $user = [ordered]@{ Id = 'user-1'; DisplayName = 'Amy'; UserPrincipalName = 'C1@example.invalid'; AccountEnabled = $false }
        Save-RecentUsers -Users @($user)
        $json = Get-Content -LiteralPath (Get-RecentUsersFilePath) -Raw
        $json.Trim().StartsWith('[') | Should -BeTrue
        $restored = @($json | ConvertFrom-Json | ForEach-Object { $_ })
        $restored.Count | Should -Be 1
        $restored[0].Id | Should -Be 'user-1'
        $restored[0].DisplayName | Should -Be 'Amy'
        $restored[0].UserPrincipalName | Should -Be 'C1@example.invalid'
        $restored[0].AccountEnabled | Should -BeFalse
    }

    It 'persists an empty recent-user collection as an empty JSON array' {
        Save-RecentUsers -Users @()
        (Get-Content -LiteralPath (Get-RecentUsersFilePath) -Raw).Trim() | Should -Be '[]'
    }
}

Describe 'Directory user search matching' {
    BeforeAll {
        $script:candidate = [ordered]@{ DisplayName = 'Amy Harris'; UserPrincipalName = 'C123@example.invalid'; AccountEnabled = $true }
    }

    It 'matches name fragments in either order and ignores case' {
        Test-DirectoryUserSearchMatch -User $script:candidate -SearchMode DisplayName -Query 'harr AM' | Should -BeTrue
    }

    It 'requires every name fragment to match' {
        Test-DirectoryUserSearchMatch -User $script:candidate -SearchMode DisplayName -Query 'Amy Jones' | Should -BeFalse
    }

    It 'treats wildcard symbols literally' {
        Test-DirectoryUserSearchMatch -User $script:candidate -SearchMode DisplayName -Query '*' | Should -BeFalse
    }

    It 'matches a complete username or UPN but not an account prefix' {
        Test-DirectoryUserSearchMatch -User $script:candidate -SearchMode ExactUpn -Query ' c123 ' | Should -BeTrue
        Test-DirectoryUserSearchMatch -User $script:candidate -SearchMode ExactUpn -Query 'C123@EXAMPLE.INVALID' | Should -BeTrue
        Test-DirectoryUserSearchMatch -User $script:candidate -SearchMode ExactUpn -Query 'C12' | Should -BeFalse
    }

    It 'rejects empty queries and missing candidates' {
        Test-DirectoryUserSearchMatch -User $script:candidate -SearchMode DisplayName -Query ' ' | Should -BeFalse
        Test-DirectoryUserSearchMatch -User $null -SearchMode DisplayName -Query 'Amy' | Should -BeFalse
    }
}

Describe 'Directory user search callers' {
    BeforeAll {
        $script:directoryFixtures = @(
            [ordered]@{ Id = 'active'; DisplayName = 'Amy Harris'; UserPrincipalName = 'C123@example.invalid'; AccountEnabled = $true }
            [ordered]@{ Id = 'unrelated'; DisplayName = 'Andy Harris'; UserPrincipalName = 'E124@example.invalid'; AccountEnabled = $true }
            [ordered]@{ Id = 'disabled'; DisplayName = 'Amy Harris'; UserPrincipalName = 'C125@example.invalid'; AccountEnabled = $false }
        )
        $script:RuntimeConfig = @{ demo = @{ defaultUsers = @() } }
    }

    BeforeEach {
        Mock Invoke-GraphApiRequest { return @{ value = $script:directoryFixtures } }
    }

    It 'returns only enabled Demo candidates matching every name fragment' {
        $results = Search-DemoDirectoryUsers -SearchMode DisplayName -Query 'Harris Amy'
        $results.Count | Should -Be 1
        $results[0].Id | Should -Be 'active'
    }

    It 'filters unrelated and disabled Live candidates without contacting Graph' {
        $results = Search-LiveDirectoryUsers -SearchMode DisplayName -Query 'Harris Amy'
        $results.Count | Should -Be 1
        $results[0].Id | Should -Be 'active'
        Should -Invoke Invoke-GraphApiRequest -Times 1 -Exactly -ParameterFilter { $Method -eq 'GET' }
    }

    It 'retrieves a contained first fragment using a later surname prefix' {
        Mock Invoke-GraphApiRequest {
            if ([uri]::UnescapeDataString($Uri) -like "*startswith(surname,'Harris')*") { return @{ value = @($script:directoryFixtures[0]) } }
            return @{ value = @() }
        }
        $results = Search-LiveDirectoryUsers -SearchMode DisplayName -Query 'my Harris'
        $results.Count | Should -Be 1
        $results[0].Id | Should -Be 'active'
        Should -Invoke Invoke-GraphApiRequest -Times 1 -Exactly
    }

    It 'includes each distinct fragment without weakening the all-fragment match' {
        $results = Search-LiveDirectoryUsers -SearchMode DisplayName -Query 'Amy Jones Amy' -Approximate:$false
        $results.Count | Should -Be 0
        Should -Invoke Invoke-GraphApiRequest -Times 1 -Exactly -ParameterFilter {
            [uri]::UnescapeDataString($Uri) -like "*startswith(surname,'Jones')*" -and
            ([regex]::Matches([uri]::UnescapeDataString($Uri), "startswith\(displayName,'Amy'\)")).Count -eq 1
        }
    }

    It 'does not accept a prefix as an exact Live account identity' {
        $results = Search-LiveDirectoryUsers -SearchMode ExactUpn -Query 'C12'
        $results.Count | Should -Be 0
    }

    It 'preserves the complete identity in a single exact Live result' {
        $results = Search-LiveDirectoryUsers -SearchMode ExactUpn -Query 'c123'
        $results.Count | Should -Be 1
        $results[0].UserPrincipalName | Should -Be 'C123@example.invalid'
    }
    It 'finds the exact Windows username with required advanced-query headers and preserves the real UPN' {
        Mock Invoke-GraphApiRequest { return @{ value = @(@{ id = 'sam-user'; displayName = 'Synthetic Person'; userPrincipalName = 'person@example.invalid'; onPremisesSamAccountName = 'C123'; accountEnabled = $true }) } }
        $results = Search-LiveDirectoryUsers -SearchMode ExactUpn -Query c123
        $results.Count | Should -Be 1
        $results[0].UserPrincipalName | Should -Be 'person@example.invalid'
        Should -Invoke Invoke-GraphApiRequest -Times 1 -Exactly -ParameterFilter {
            [uri]::UnescapeDataString($Uri) -like "*onPremisesSamAccountName eq 'c123'*" -and $Uri -like '*$count=true*' -and $Headers.ConsistencyLevel -eq 'eventual'
        }
    }

    It 'finds a matching identity on a later page using the unchanged continuation URL' {
        $script:nextPage = 'https://graph.microsoft.com/v1.0/users?$skiptoken=opaque%2Btoken&$top=15'
        Mock Invoke-GraphApiRequest {
            if ($Uri -eq $script:nextPage) { return @{ value = @($script:directoryFixtures[0]) } }
            return @{ value = @($script:directoryFixtures[1]); '@odata.nextLink' = $script:nextPage }
        }
        $results = Search-LiveDirectoryUsers -SearchMode DisplayName -Query 'Amy Harris'
        $results.Count | Should -Be 1
        $results[0].Id | Should -Be 'active'
        Should -Invoke Invoke-GraphApiRequest -Times 1 -Exactly -ParameterFilter { $Uri -ceq $script:nextPage }
    }

    It 'continues past an empty page and removes duplicate identities across pages' {
        Mock Invoke-GraphApiRequest {
            if ($Uri -like '*skiptoken=second') {
                return @{ value = @($script:directoryFixtures[0], $script:directoryFixtures[0], $script:directoryFixtures[2]) }
            }
            return @{ value = @(); '@odata.nextLink' = 'https://graph.microsoft.com/v1.0/users?$skiptoken=second' }
        }
        $results = Search-LiveDirectoryUsers -SearchMode ExactUpn -Query 'c123'
        $results.Count | Should -Be 1
        Should -Invoke Invoke-GraphApiRequest -Times 2 -Exactly
    }

    It 'warns and stops at the configured page bound' {
        Mock Get-ConfiguredDirectorySearchPageLimit { return 2 }
        Mock Write-Warning {}
        Mock Invoke-GraphApiRequest {
            return @{ value = $script:directoryFixtures; '@odata.nextLink' = ('https://graph.microsoft.com/v1.0/users?$skiptoken={0}' -f $Uri.Length) }
        }
        $results = Search-LiveDirectoryUsers -SearchMode DisplayName -Query 'Amy'
        $results.Count | Should -Be 1
        Should -Invoke Invoke-GraphApiRequest -Times 2 -Exactly
        Should -Invoke Write-Warning -Times 1 -Exactly -ParameterFilter { $Message -like '*results may be incomplete*' }
    }

    It 'rejects a repeated continuation without requesting it twice' {
        Mock Invoke-GraphApiRequest { return @{ value = @(); '@odata.nextLink' = $Uri } }
        { Search-LiveDirectoryUsers -SearchMode ExactUpn -Query 'c123' } | Should -Throw '*repeated continuation*'
        Should -Invoke Invoke-GraphApiRequest -Times 1 -Exactly
    }

    It 'rejects a continuation outside the Graph users endpoint' {
        Mock Invoke-GraphApiRequest { return @{ value = @(); '@odata.nextLink' = 'https://example.invalid/users?token=secret' } }
        { Search-LiveDirectoryUsers -SearchMode ExactUpn -Query 'c123' } | Should -Throw '*unexpected continuation*'
        Should -Invoke Invoke-GraphApiRequest -Times 1 -Exactly
    }

    It 'propagates later-page failures rather than returning partial results' {
        Mock Invoke-GraphApiRequest {
            if ($Uri -like '*skiptoken=second') { throw 'Graph page unavailable' }
            return @{ value = @($script:directoryFixtures[0]); '@odata.nextLink' = 'https://graph.microsoft.com/v1.0/users?$skiptoken=second' }
        }
        { Search-LiveDirectoryUsers -SearchMode DisplayName -Query 'Amy' } | Should -Throw '*Graph page unavailable*'
    }

    It 'rejects a malformed users response' {
        Mock Invoke-GraphApiRequest { return @{} }
        { Search-LiveDirectoryUsers -SearchMode ExactUpn -Query 'c123' } | Should -Throw '*invalid users page*'
    }

    It 'keeps the configured result bound after collecting pages' {
        Mock Get-ConfiguredSearchLimit { return 1 }
        Mock Invoke-GraphApiRequest { return @{ value = @(
                    @{ Id = 'one'; DisplayName = 'Amy Alpha'; UserPrincipalName = 'C1@example.invalid'; AccountEnabled = $true }
                    @{ Id = 'two'; DisplayName = 'Amy Beta'; UserPrincipalName = 'C2@example.invalid'; AccountEnabled = $true }
                )
            } }
        $results = Search-LiveDirectoryUsers -SearchMode DisplayName -Query 'Amy'
        $results.Count | Should -Be 1
        $results[0].Id | Should -Be 'one'
    }
}

Describe 'Directory search relevance' {
    BeforeAll {
        $script:rankFixtures = @(
            [ordered]@{ Id = 'weak'; DisplayName = 'Aamy Harris'; UserPrincipalName = 'C2@example.invalid'; AccountEnabled = $true }
            [ordered]@{ Id = 'prefix'; DisplayName = 'Amy Harris Junior'; UserPrincipalName = 'C3@example.invalid'; AccountEnabled = $true }
            [ordered]@{ Id = 'exact'; DisplayName = 'Amy Harris'; UserPrincipalName = 'E1@example.invalid'; AccountEnabled = $true }
        )
    }

    It 'puts exact names before alphabetical substring matches without modifying identities' {
        $results = @(Get-DirectoryUserSearchResult -Users $script:rankFixtures -SearchMode DisplayName -Query 'Amy Harris')
        ($results | ForEach-Object { $_.Id }) -join ',' | Should -Be 'exact,prefix,weak'
        $script:rankFixtures[2].Keys.Count | Should -Be 4
        $results[0].UserPrincipalName | Should -Be 'E1@example.invalid'
    }

    It 'uses documented literal relevance tiers including identity-only matches' {
        $cases = @(
            @{ Name = 'Amy Harris'; Upn = 'C1@example.invalid'; Query = ' Amy   HARRIS '; Rank = 0 }
            @{ Name = 'Amy Harris Junior'; Upn = 'C1@example.invalid'; Query = 'Amy Harris'; Rank = 1 }
            @{ Name = 'Harris Amy'; Upn = 'C1@example.invalid'; Query = 'am harr'; Rank = 2 }
            @{ Name = 'Aamy Harris'; Upn = 'C1@example.invalid'; Query = 'amy harr'; Rank = 3 }
            @{ Name = 'Aamy Xharris'; Upn = 'C1@example.invalid'; Query = 'amy harr'; Rank = 4 }
            @{ Name = 'Alex'; Upn = 'Camy.harris@example.invalid'; Query = 'amy harr'; Rank = 5 }
            @{ Name = 'Alex'; Upn = 'C1@example.invalid'; Query = 'c1'; Rank = 0 }
        )
        foreach ($case in $cases) {
            Get-DirectoryUserSearchRank -User @{ DisplayName = $case.Name; UserPrincipalName = $case.Upn } -Query $case.Query |
            Should -Be $case.Rank
        }
    }

    It 'ranks reordered case-insensitive fragments by word prefix rather than UPN fragments' {
        $users = @(
            @{ Id = 'upn'; DisplayName = 'Aaron'; UserPrincipalName = 'Camy.harris@example.invalid'; AccountEnabled = $true }
            @{ Id = 'name'; DisplayName = 'Amy Harris'; UserPrincipalName = 'E2@example.invalid'; AccountEnabled = $true }
        )
        $results = @(Get-DirectoryUserSearchResult -Users $users -SearchMode DisplayName -Query 'HARR AM')
        ($results | ForEach-Object { $_.Id }) -join ',' | Should -Be 'name,upn'
    }

    It 'uses name and UPN ties while excluding disabled and unrelated candidates' {
        $users = @(
            @{ Id = 'second'; DisplayName = 'Amy'; UserPrincipalName = 'E2@example.invalid'; AccountEnabled = $true }
            @{ Id = 'first'; DisplayName = 'Amy'; UserPrincipalName = 'C1@example.invalid'; AccountEnabled = $true }
            @{ Id = 'disabled'; DisplayName = 'Amy'; UserPrincipalName = 'C0@example.invalid'; AccountEnabled = $false }
            @{ Id = 'unrelated'; DisplayName = 'Bob'; UserPrincipalName = 'C3@example.invalid'; AccountEnabled = $true }
        )
        $results = @(Get-DirectoryUserSearchResult -Users $users -SearchMode DisplayName -Query 'Amy')
        ($results | ForEach-Object { $_.Id }) -join ',' | Should -Be 'first,second'
    }

    It 'returns no ranked results for empty input or blank queries' {
        @(Get-DirectoryUserSearchResult -Users @() -SearchMode DisplayName -Query 'Amy').Count | Should -Be 0
        @(Get-DirectoryUserSearchResult -Users $null -SearchMode DisplayName -Query 'Amy').Count | Should -Be 0
        @(Get-DirectoryUserSearchResult -Users $script:rankFixtures -SearchMode DisplayName -Query ' ').Count | Should -Be 0
    }

    It 'shares ranked results between Demo and mocked Live search' {
        $script:RuntimeConfig = @{ demo = @{ defaultUsers = @() } }
        Mock Get-RecentUsers { return , $script:rankFixtures }
        Mock Invoke-GraphApiRequest { return @{ value = $script:rankFixtures } }
        $demo = Search-DemoDirectoryUsers -SearchMode DisplayName -Query 'Amy Harris'
        $live = Search-LiveDirectoryUsers -SearchMode DisplayName -Query 'Amy Harris'
        ($demo | ForEach-Object { $_.Id }) -join ',' | Should -Be 'exact,prefix,weak'
        ($live | ForEach-Object { $_.Id }) -join ',' | Should -Be 'exact,prefix,weak'
    }
}

Describe 'Ranked directory user selection' {
    BeforeAll {
        $script:selectionFixtures = @(
            @{ Id = 'best'; DisplayName = 'Zed'; UserPrincipalName = 'E1@example.invalid' }
            @{ Id = 'later'; DisplayName = 'Amy'; UserPrincipalName = 'C2@example.invalid' }
        )
    }
    BeforeEach {
        Mock Write-Host {}
        Mock Read-ValidatedInput { return '1' }
    }

    It 'displays and selects the first ranked result without alphabetical resorting' {
        $selected = Select-UserFromResults -Users $script:selectionFixtures -Heading 'Results' -PreserveOrder
        $selected.Id | Should -Be 'best'
        Should -Invoke Write-Host -Times 1 -Exactly -ParameterFilter { $Object -eq '1. Zed <E1@example.invalid>' }
        Should -Invoke Read-ValidatedInput -Times 1 -Exactly -ParameterFilter { $Default -eq '0' -and $Type -eq 'Int' }
    }

    It 'retains alphabetical selection for callers that do not request ranked order' {
        (Select-UserFromResults -Users $script:selectionFixtures -Heading 'Recent').Id | Should -Be 'later'
        Should -Invoke Write-Host -Times 1 -Exactly -ParameterFilter { $Object -eq '1. Amy <C2@example.invalid>' }
    }

    It 'returns no user for cancellation or out-of-range choices' {
        Mock Read-ValidatedInput { return '0' }
        Select-UserFromResults -Users $script:selectionFixtures -Heading 'Results' -PreserveOrder | Should -BeNullOrEmpty
        Mock Read-ValidatedInput { return '3' }
        Select-UserFromResults -Users $script:selectionFixtures -Heading 'Results' -PreserveOrder | Should -BeNullOrEmpty
        Mock Read-ValidatedInput { return '-1' }
        Select-UserFromResults -Users $script:selectionFixtures -Heading 'Results' -PreserveOrder | Should -BeNullOrEmpty
    }

    It 'does not prompt for an empty result collection' {
        Select-UserFromResults -Users @() -Heading 'Results' -PreserveOrder | Should -BeNullOrEmpty
        Should -Invoke Read-ValidatedInput -Times 0 -Exactly
    }
}

Describe 'Automatic approximate name suggestions' {
    BeforeEach {
        $script:suggestionUser = @{ Id = 'suggestion'; DisplayName = 'Amy Harris'; UserPrincipalName = 'C123@example.invalid'; AccountEnabled = $true }
        $script:RuntimeConfig = @{ demo = @{ defaultUsers = @() } }
        Mock Write-Host {}
        Mock Get-RecentUsers { return , @($script:suggestionUser) }
        Mock Invoke-GraphApiRequest {
            if ([uri]::UnescapeDataString($Uri) -like "*startswith(surname,'Ha')*") { return @{ value = @($script:suggestionUser) } }
            return @{ value = @() }
        }
    }

    It 'supports one insertion deletion or substitution but not transpositions or two edits' {
        foreach ($fragment in @('harriss', 'haris', 'harrus', 'harris')) {
            Test-NameWordApproximation -Fragment $fragment -Word 'harris' | Should -BeTrue
        }
        foreach ($fragment in @('har', 'hxxris', 'harrsi', '')) {
            Test-NameWordApproximation -Fragment $fragment -Word 'harris' | Should -BeFalse
        }
    }

    It 'returns labelled Live suggestions after zero literal matches with one bounded extra pass' {
        $results = Search-LiveDirectoryUsers -SearchMode DisplayName -Query 'Harrus'
        $results.Count | Should -Be 1
        $results[0].Id | Should -Be 'suggestion'
        Should -Invoke Invoke-GraphApiRequest -Times 2 -Exactly
        Should -Invoke Write-Host -Times 1 -Exactly -ParameterFilter { $Object -like '*Approximate name suggestions*' }
    }

    It 'shares automatic suggestions in Demo while retaining all fragment requirements' {
        $results = Search-DemoDirectoryUsers -SearchMode DisplayName -Query 'Amy Harrus'
        $results.Count | Should -Be 1
        $results[0].Id | Should -Be 'suggestion'
        (Search-DemoDirectoryUsers -SearchMode DisplayName -Query 'Bob Harrus').Count | Should -Be 0
    }

    It 'never broadens a successful literal search' {
        Mock Invoke-GraphApiRequest { return @{ value = @($script:suggestionUser) } }
        (Search-LiveDirectoryUsers -SearchMode DisplayName -Query 'Harris').Count | Should -Be 1
        Should -Invoke Invoke-GraphApiRequest -Times 1 -Exactly
        Should -Invoke Write-Host -Times 0 -Exactly
    }

    It 'does not correct exact usernames or short fragments' {
        (Search-LiveDirectoryUsers -SearchMode ExactUpn -Query 'C124').Count | Should -Be 0
        (Search-LiveDirectoryUsers -SearchMode DisplayName -Query 'Axy').Count | Should -Be 0
        Should -Invoke Invoke-GraphApiRequest -Times 2 -Exactly
        Should -Invoke Write-Host -Times 0 -Exactly
    }

    It 'does not fall back from incomplete literal retrieval' {
        Mock Get-ConfiguredDirectorySearchPageLimit { return 1 }
        Mock Write-Warning {}
        Mock Invoke-GraphApiRequest { return @{ value = @(); '@odata.nextLink' = 'https://graph.microsoft.com/v1.0/users?$skiptoken=more' } }
        (Search-LiveDirectoryUsers -SearchMode DisplayName -Query 'Harrus').Count | Should -Be 0
        Should -Invoke Invoke-GraphApiRequest -Times 1 -Exactly
        Should -Invoke Write-Warning -Times 1 -Exactly
        Should -Invoke Write-Host -Times 0 -Exactly
    }

    It 'propagates fallback failures instead of claiming no matching users' {
        Mock Invoke-GraphApiRequest {
            if ([uri]::UnescapeDataString($Uri) -like "*startswith(surname,'Ha')*") { throw 'Suggestion retrieval failed' }
            return @{ value = @() }
        }
        { Search-LiveDirectoryUsers -SearchMode DisplayName -Query 'Harrus' } | Should -Throw '*Suggestion retrieval failed*'
        Should -Invoke Invoke-GraphApiRequest -Times 2 -Exactly
    }

    It 'keeps suggestions below literal matches and excludes disabled accounts and fuzzy UPNs' {
        $users = @(
            $script:suggestionUser
            @{ Id = 'literal'; DisplayName = 'Harrus'; UserPrincipalName = 'E1@example.invalid'; AccountEnabled = $true }
            @{ Id = 'disabled'; DisplayName = 'Harris'; UserPrincipalName = 'E2@example.invalid'; AccountEnabled = $false }
            @{ Id = 'upn'; DisplayName = 'Bob'; UserPrincipalName = 'Charris@example.invalid'; AccountEnabled = $true }
        )
        $results = @(Get-DirectoryUserSearchResult -Users $users -SearchMode DisplayName -Query 'Harrus' -Approximate)
        ($results | ForEach-Object { $_.Id }) -join ',' | Should -Be 'literal,suggestion'
    }
}

Describe 'Directory search page configuration' {
    BeforeEach { $script:RuntimeConfig = @{ autopilot = @{} } }

    It 'defaults to ten pages for existing configuration' {
        Get-ConfiguredDirectorySearchPageLimit | Should -Be 10
    }

    It 'accepts the configured page bound' {
        $script:RuntimeConfig.autopilot.directorySearchPageLimit = 2
        Get-ConfiguredDirectorySearchPageLimit | Should -Be 2
    }

    It 'rejects invalid bounds' {
        foreach ($invalidValue in @('', 0, -1, 101, '1.5', 'abc', '99999999999999')) {
            $script:RuntimeConfig.autopilot.directorySearchPageLimit = $invalidValue
            { Get-ConfiguredDirectorySearchPageLimit } | Should -Throw '*integer from 1 to 100*'
        }
    }
}