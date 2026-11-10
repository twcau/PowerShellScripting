<#
.SYNOPSIS
    Checks bounded Graph HTTP retries, SDK context and mutation replay guards.
.DESCRIPTION
    Extracts production functions without starting the CLI. SDK calls and waits are
    mocked. Synthetic exceptions contain structured HTTP evidence; no tenant or
    operational records are accessed. Requires Pester 5 and FullLanguage for parsing.
#>
BeforeAll {
    $sourcePath = Join-Path (Split-Path -Parent $PSScriptRoot) 'autopilot-express.ps1'
    $tokens = $null
    $parseErrors = $null
    $sourceAst = [System.Management.Automation.Language.Parser]::ParseFile($sourcePath, [ref]$tokens, [ref]$parseErrors)
    if ($parseErrors.Count) { throw ($parseErrors.Message -join '; ') }
    foreach ($functionName in @('Get-GraphTransportPolicy', 'Initialize-GraphTransport', 'Get-GraphTransportFailure', 'Get-GraphOperationFailureMessage', 'Invoke-GraphApiRequest')) {
        $definition = $sourceAst.Find({ param($node) $node -is [System.Management.Automation.Language.FunctionDefinitionAst] -and $node.Name -eq $functionName }, $true)
        if ($null -eq $definition) { throw ('Missing function: {0}' -f $functionName) }
        Set-Item -Path ('Function:{0}' -f $functionName) -Value $definition.Body.GetScriptBlock()
    }
    function Set-MgRequestContext {
        [CmdletBinding(SupportsShouldProcess)]
        param($MaxRetry, $ClientTimeout)
        if ($PSCmdlet.ShouldProcess('Synthetic context', 'Set')) {
            throw ('Unexpected context change: {0}, {1}' -f $MaxRetry, $ClientTimeout)
        }
    }
    function Invoke-MgGraphRequest {
        [CmdletBinding()]
        param($Method, $Uri, $Body, $Headers, $ContentType)
        throw ('Unexpected SDK request: {0}, {1}, {2}, {3}, {4}' -f $Method, $Uri, $Body, $Headers, $ContentType)
    }
    function Write-AutopilotExpressLog {
        param($Message, $Level)
        throw ('Unexpected log: {0}, {1}' -f $Level, $Message)
    }
    function Get-TransportTestException {
        param($Status, $Headers = @{}, [switch]$NestedResponse)
        $exception = [Exception]::new('Synthetic SDK failure')
        if ($NestedResponse) {
            $exception | Add-Member -NotePropertyName Response -NotePropertyValue @{ StatusCode = $Status; Headers = $Headers }
        }
        else {
            $exception | Add-Member -NotePropertyName ResponseStatusCode -NotePropertyValue $Status
            $exception | Add-Member -NotePropertyName ResponseHeaders -NotePropertyValue $Headers
        }
        return $exception
    }
}

Describe 'Graph transport policy and replay safety' {
    BeforeEach {
        $script:Config = @{ TransportMaxAttempts = 3; TransportBackoffSeconds = 2; TransportMaxDelaySeconds = 60; TransportTimeoutSeconds = 60 }
        $script:GraphSession = @{ Connected = $true; IsSimulated = $false }
        $script:requests = 0
        $script:failure = Get-TransportTestException -Status 429
        Mock Set-MgRequestContext {}
        Mock Write-AutopilotExpressLog {}
        Mock Start-Sleep {}
        Mock Invoke-MgGraphRequest { return @{ id = 'expected' } }
    }

    It 'uses separate defaults when transport settings are absent' {
        $script:Config = @{ MaxRetryAttempts = 20; RetryBackoffSeconds = 60 }
        $policy = Get-GraphTransportPolicy
        $policy.TransportMaxAttempts | Should -Be 3
        $policy.TransportBackoffSeconds | Should -Be 3
        $policy.TransportMaxDelaySeconds | Should -Be 60
        $policy.TransportTimeoutSeconds | Should -Be 60
    }

    It 'rejects invalid <Setting> value <Value> before any request' -TestCases @(
        @{ Setting = 'TransportMaxAttempts'; Value = 0 }
        @{ Setting = 'TransportMaxAttempts'; Value = 6 }
        @{ Setting = 'TransportMaxAttempts'; Value = '1.5' }
        @{ Setting = 'TransportBackoffSeconds'; Value = -1 }
        @{ Setting = 'TransportMaxDelaySeconds'; Value = 301 }
        @{ Setting = 'TransportTimeoutSeconds'; Value = 0 }
        @{ Setting = 'TransportTimeoutSeconds'; Value = $true }
    ) {
        param($Setting, $Value)
        $script:Config[$Setting] = $Value
        { Invoke-GraphApiRequest -Method GET -Uri 'https://graph.microsoft.com/v1.0/test' } | Should -Throw
        Should -Invoke Invoke-MgGraphRequest -Times 0 -Exactly
        Should -Invoke Set-MgRequestContext -Times 0 -Exactly
    }

    It 'rejects a backoff larger than the maximum accepted wait' {
        $script:Config.TransportMaxDelaySeconds = 1
        { Get-GraphTransportPolicy } | Should -Throw '*must not exceed*'
    }

    It 'disables SDK retries and sets the timeout before returning an unchanged response' {
        $response = Invoke-GraphApiRequest -Method GET -Uri 'https://graph.microsoft.com/v1.0/test'
        $response.id | Should -Be 'expected'
        Should -Invoke Set-MgRequestContext -Times 1 -Exactly -ParameterFilter { $MaxRetry -eq 0 -and $ClientTimeout -eq 60 }
        Should -Invoke Invoke-MgGraphRequest -Times 1 -Exactly
        Should -Invoke Start-Sleep -Times 0 -Exactly
    }

    It 'configures transport once across consecutive requests in the same session' {
        1..3 | ForEach-Object { Invoke-GraphApiRequest -Method GET -Uri 'https://graph.microsoft.com/v1.0/test' | Out-Null }
        Should -Invoke Set-MgRequestContext -Times 1 -Exactly
        Should -Invoke Invoke-MgGraphRequest -Times 3 -Exactly
    }
    It 'pauses further SDK requests after authentication cancellation without replaying the action' {
        Mock Invoke-MgGraphRequest { throw [OperationCanceledException]::new('Synthetic cancellation') }
        { Invoke-GraphApiRequest -Method POST -Uri 'https://graph.microsoft.com/v1.0/test' } | Should -Throw
        $script:GraphSession.RequiresReconnect | Should -BeTrue
        { Invoke-GraphApiRequest -Method GET -Uri 'https://graph.microsoft.com/v1.0/test' } | Should -Throw '*explicit reconnection*'
        Should -Invoke Invoke-MgGraphRequest -Times 1 -Exactly
        Should -Invoke Start-Sleep -Times 0 -Exactly
    }
    It 'requires explicit reconnection after HTTP 401 but not a permission denial' {
        $script:failure = Get-TransportTestException -Status 401
        Mock Invoke-MgGraphRequest { throw $script:failure }
        { Invoke-GraphApiRequest -Method GET -Uri 'https://graph.microsoft.com/v1.0/test' } | Should -Throw
        $script:GraphSession.RequiresReconnect | Should -BeTrue
        $script:GraphSession.RequiresReconnect = $false
        $script:failure = Get-TransportTestException -Status 403
        { Invoke-GraphApiRequest -Method GET -Uri 'https://graph.microsoft.com/v1.0/test' } | Should -Throw
        $script:GraphSession.RequiresReconnect | Should -BeFalse
    }

    It 'does not remember failed SDK setup' {
        Mock Set-MgRequestContext { throw 'Synthetic setup failure' }
        { Invoke-GraphApiRequest -Method GET -Uri 'https://graph.microsoft.com/v1.0/test' } | Should -Throw '*setup failure*'
        $script:GraphSession.Contains('TransportTimeoutSeconds') | Should -BeFalse
        Mock Set-MgRequestContext {}
        Invoke-GraphApiRequest -Method GET -Uri 'https://graph.microsoft.com/v1.0/test' | Out-Null
        Should -Invoke Set-MgRequestContext -Times 2 -Exactly
    }

    It 'passes the startup organisation path and query without a GET body or SDK environment override' {
        $response = Invoke-GraphApiRequest -Method GET -Uri 'https://graph.microsoft.com/v1.0/organization?$select=id,displayName'
        $response.id | Should -Be 'expected'
        Should -Invoke Invoke-MgGraphRequest -Times 1 -Exactly -ParameterFilter {
            $Method -ceq 'GET' -and
            $Uri -ceq '/v1.0/organization?$select=id,displayName' -and
            -not ([uri]$Uri).IsAbsoluteUri -and
            $null -eq $Body -and $null -eq $ContentType
        }
        Should -Invoke Start-Sleep -Times 0 -Exactly
    }

    It 'suppresses SDK payload diagnostics for all <Method> requests even in verbose mode' -TestCases @(
        @{ Method = 'POST' }; @{ Method = 'GET' }
    ) {
        param($Method)
        Invoke-GraphApiRequest -Method $Method -Uri 'https://graph.microsoft.com/v1.0/deviceManagement/windowsAutopilotDeviceIdentities/target' -Body @{ syntheticPrivatePayload = 'not-for-logs' } -Verbose | Out-Null
        Should -Invoke Invoke-MgGraphRequest -Times 1 -Exactly -ParameterFilter {
            $Verbose -eq $false -and $Debug -eq $false
        }
    }

    It 'rejects unsafe Graph URI <Uri> before SDK context or requests' -TestCases @(
        @{ Uri = '/v1.0/organization' }
        @{ Uri = 'http://graph.microsoft.com/v1.0/organization' }
        @{ Uri = 'https://example.test/v1.0/organization' }
        @{ Uri = 'https://graph.microsoft.com:444/v1.0/organization' }
        @{ Uri = 'https://synthetic@graph.microsoft.com/v1.0/organization' }
        @{ Uri = 'https://graph.microsoft.com/v1.0/organization#fragment' }
        @{ Uri = 'https://graph.microsoft.com//example.test/v1.0/organization' }
    ) {
        param($Uri)
        $script:unsafeGraphUri = $Uri
        { Invoke-GraphApiRequest -Method GET -Uri $script:unsafeGraphUri } | Should -Throw '*absolute HTTPS public Graph URI*'
        Should -Invoke Set-MgRequestContext -Times 0 -Exactly
        Should -Invoke Invoke-MgGraphRequest -Times 0 -Exactly
    }

    It 'fails closed when the installed SDK lacks required transport controls' {
        Mock Get-Command { return @{ Parameters = @{ ClientTimeout = @{} } } } -ParameterFilter { $Name -eq 'Set-MgRequestContext' }
        { Invoke-GraphApiRequest -Method GET -Uri 'https://graph.microsoft.com/v1.0/test' } | Should -Throw '*must support*'
        Should -Invoke Invoke-MgGraphRequest -Times 0 -Exactly
    }

    It 'fails before requests when context configuration fails' {
        Mock Set-MgRequestContext { throw 'Context denied' }
        { Invoke-GraphApiRequest -Method GET -Uri 'https://graph.microsoft.com/v1.0/test' } | Should -Throw 'Context denied'
        Should -Invoke Invoke-MgGraphRequest -Times 0 -Exactly
    }

    It 'blocks disconnected sessions' {
        $script:GraphSession.Connected = $false
        { Invoke-GraphApiRequest -Method GET -Uri 'https://graph.microsoft.com/v1.0/test' } | Should -Throw '*not connected*'
        Should -Invoke Invoke-MgGraphRequest -Times 0 -Exactly
    }

    It 'blocks simulated sessions from making real requests' {
        $script:GraphSession.IsSimulated = $true
        { Invoke-GraphApiRequest -Method GET -Uri 'https://graph.microsoft.com/v1.0/test' } | Should -Throw '*Demo mode*'
        Should -Invoke Invoke-MgGraphRequest -Times 0 -Exactly
    }

    It 'retries transient GET status <Status> then returns success' -TestCases @(
        @{ Status = 429 }
        @{ Status = 503 }
        @{ Status = 504 }
        @{ Status = 'TooManyRequests' }
        @{ Status = 'ServiceUnavailable' }
        @{ Status = 'GatewayTimeout' }
    ) {
        param($Status)
        $script:failure = Get-TransportTestException -Status $Status
        Mock Invoke-MgGraphRequest { $script:requests++; if ($script:requests -eq 1) { throw $script:failure }; return @{ id = 'expected' } }
        (Invoke-GraphApiRequest -Method GET -Uri 'https://graph.microsoft.com/v1.0/test').id | Should -Be 'expected'
        Should -Invoke Invoke-MgGraphRequest -Times 2 -Exactly
        Should -Invoke Start-Sleep -Times 1 -Exactly -ParameterFilter { $Seconds -eq 2 }
    }

    It 'bounds exhaustion and only waits between attempts' {
        Mock Invoke-MgGraphRequest { throw $script:failure }
        { Invoke-GraphApiRequest -Method GET -Uri 'https://graph.microsoft.com/v1.0/test' } | Should -Throw 'Synthetic SDK failure'
        Should -Invoke Invoke-MgGraphRequest -Times 3 -Exactly
        Should -Invoke Start-Sleep -Times 2 -Exactly
        Should -Invoke Start-Sleep -Times 1 -Exactly -ParameterFilter { $Seconds -eq 2 }
        Should -Invoke Start-Sleep -Times 1 -Exactly -ParameterFilter { $Seconds -eq 4 }
    }

    It 'does not retry permanent or unclassified status <Status>' -TestCases @(
        @{ Status = 400 }
        @{ Status = 401 }
        @{ Status = 403 }
        @{ Status = 404 }
        @{ Status = 500 }
        @{ Status = 'InternalServerError' }
        @{ Status = $null }
    ) {
        param($Status)
        $script:failure = Get-TransportTestException -Status $Status
        Mock Invoke-MgGraphRequest { throw $script:failure }
        { Invoke-GraphApiRequest -Method GET -Uri 'https://graph.microsoft.com/v1.0/test' } | Should -Throw 'Synthetic SDK failure'
        Should -Invoke Invoke-MgGraphRequest -Times 1 -Exactly
        Should -Invoke Start-Sleep -Times 0 -Exactly
    }

    It 'does not disclose malformed structured HTTP status <Label>' -ForEach @(
        @{ Label = 'text'; Status = 'Bearer SYNTHETIC-PRIVATE-STATUS' }
        @{ Label = 'out of range'; Status = 999 }
        @{ Label = 'negative'; Status = -1 }
        @{ Label = 'Boolean'; Status = $true }
        @{ Label = 'injected lines'; Status = "SYNTHETIC-PRIVATE-STATUS`nHTTP=200" }
    ) {
        $script:failure = Get-TransportTestException -Status $Status
        Mock Invoke-MgGraphRequest { throw $script:failure }
        { Invoke-GraphApiRequest -Method GET -Uri 'https://graph.microsoft.com/v1.0/test' } | Should -Throw 'Synthetic SDK failure'
        Should -Invoke Write-AutopilotExpressLog -Times 1 -Exactly -ParameterFilter {
            $Message -match 'HTTP=unavailable;' -and $Message -notmatch 'SYNTHETIC-PRIVATE-STATUS'
        }
        Should -Invoke Invoke-MgGraphRequest -Times 1 -Exactly
        Should -Invoke Start-Sleep -Times 0 -Exactly
    }

    It 'redacts original SDK errors while preserving safe HTTP diagnostics and local validation' {
        $exception = Get-TransportTestException -Status 403 -Headers @{ 'request-id' = 'safe-correlation' }
        $exception.Data['AutopilotExpress.GraphMethod'] = 'GET'
        $errorRecord = [System.Management.Automation.ErrorRecord]::new($exception, 'Synthetic', [System.Management.Automation.ErrorCategory]::NotSpecified, $null)
        $message = Get-GraphOperationFailureMessage -RequestError $errorRecord
        $message | Should -Match 'HTTP=403; request-id=safe-correlation;'
        $message | Should -Not -Match 'Synthetic SDK failure'
        try { throw 'Local validation remains actionable.' } catch {
            Get-GraphOperationFailureMessage -RequestError $_ | Should -BeExactly 'Local validation remains actionable.'
        }
    }

    It 'reports HTTP 500 numerically for <Label> SDK status evidence' -ForEach @(
        @{ Label = 'integer'; Status = 500 }
        @{ Label = 'enum'; Status = [System.Net.HttpStatusCode]::InternalServerError }
        @{ Label = 'symbolic'; Status = 'InternalServerError' }
    ) {
        foreach ($nested in @($false, $true)) {
            $exception = Get-TransportTestException -Status $Status -NestedResponse:$nested
            $failure = Get-GraphTransportFailure -RequestError @{ Exception = $exception }
            $failure.Status | Should -Be '500'
        }
    }

    It 'does not replay <Method> on a transient failure' -TestCases @(
        @{ Method = 'POST' }
        @{ Method = 'DELETE' }
    ) {
        param($Method)
        $script:requestMethod = $Method
        Mock Invoke-MgGraphRequest { throw $script:failure }
        { Invoke-GraphApiRequest -Method $script:requestMethod -Uri 'https://graph.microsoft.com/v1.0/test' -Body @{ value = 'synthetic' } } | Should -Throw 'Synthetic SDK failure'
        Should -Invoke Invoke-MgGraphRequest -Times 1 -Exactly
        Should -Invoke Start-Sleep -Times 0 -Exactly
    }

    It 'preserves JSON bodies, content type and custom request headers' {
        Invoke-GraphApiRequest -Method POST -Uri 'https://graph.microsoft.com/v1.0/test' -Body @{ sample = 'value' } -Headers @{ ConsistencyLevel = 'eventual' }
        Should -Invoke Invoke-MgGraphRequest -Times 1 -Exactly -ParameterFilter { $Uri -ceq '/v1.0/test' -and ($Body | ConvertFrom-Json).sample -eq 'value' -and $ContentType -eq 'application/json' -and $Headers.ConsistencyLevel -eq 'eventual' }
    }

    It 'retains literal OData query names and escaped values in relative SDK paths' {
        Invoke-GraphApiRequest -Method GET -Uri 'https://graph.microsoft.com/v1.0/users?$filter=userPrincipalName%20eq%20%27synthetic%2Btest%40example.test%27&$select=id'
        Should -Invoke Invoke-MgGraphRequest -Times 1 -Exactly -ParameterFilter {
            $Uri -ceq '/v1.0/users?$filter=userPrincipalName%20eq%20%27synthetic%2Btest%40example.test%27&$select=id'
        }
    }

    It 'retains the literal reference segment for a non-replayed mutation' {
        Invoke-GraphApiRequest -Method DELETE -Uri 'https://graph.microsoft.com/v1.0/groups/synthetic/members/synthetic/$ref'
        Should -Invoke Invoke-MgGraphRequest -Times 1 -Exactly -ParameterFilter {
            $Method -ceq 'DELETE' -and $Uri -ceq '/v1.0/groups/synthetic/members/synthetic/$ref'
        }
        Should -Invoke Start-Sleep -Times 0 -Exactly
    }

    It 'honours numeric Retry-After from nested response headers' {
        $script:failure = Get-TransportTestException -Status 429 -NestedResponse -Headers @{ 'Retry-After' = @('7'); 'request-id' = 'safe-request-123' }
        Mock Invoke-MgGraphRequest { $script:requests++; if ($script:requests -eq 1) { throw $script:failure }; return @{ id = 'expected' } }
        Invoke-GraphApiRequest -Method GET -Uri 'https://graph.microsoft.com/v1.0/test'
        Should -Invoke Start-Sleep -Times 1 -Exactly -ParameterFilter { $Seconds -eq 7 }
        Should -Invoke Write-AutopilotExpressLog -Times 1 -Exactly -ParameterFilter { $Message -like '*request-id=safe-request-123*' }
    }

    It 'honours HTTP-date Retry-After' {
        $script:failure = Get-TransportTestException -Status 503 -Headers @{ 'Retry-After' = 'Tue, 06 Oct 2026 12:00:07 GMT' }
        $script:fixedNow = Get-Date -Date 'Tue, 06 Oct 2026 12:00:00 GMT'
        Mock Get-Date { return $script:fixedNow } -ParameterFilter { $null -eq $Date }
        Mock Invoke-MgGraphRequest { $script:requests++; if ($script:requests -eq 1) { throw $script:failure }; return @{ id = 'expected' } }
        Invoke-GraphApiRequest -Method GET -Uri 'https://graph.microsoft.com/v1.0/test'
        Should -Invoke Start-Sleep -Times 1 -Exactly -ParameterFilter { $Seconds -eq 7 }
    }

    It 'honours zero Retry-After without sleeping' {
        $script:failure = Get-TransportTestException -Status 429 -Headers @{ 'Retry-After' = '0' }
        Mock Invoke-MgGraphRequest { $script:requests++; if ($script:requests -eq 1) { throw $script:failure }; return @{ id = 'expected' } }
        Invoke-GraphApiRequest -Method GET -Uri 'https://graph.microsoft.com/v1.0/test'
        Should -Invoke Start-Sleep -Times 0 -Exactly
        Should -Invoke Invoke-MgGraphRequest -Times 2 -Exactly
    }

    It 'does not shorten an excessive server wait' {
        $script:failure = Get-TransportTestException -Status 429 -Headers @{ 'Retry-After' = '61' }
        Mock Invoke-MgGraphRequest { throw $script:failure }
        { Invoke-GraphApiRequest -Method GET -Uri 'https://graph.microsoft.com/v1.0/test' } | Should -Throw 'Synthetic SDK failure'
        Should -Invoke Invoke-MgGraphRequest -Times 1 -Exactly
        Should -Invoke Start-Sleep -Times 0 -Exactly
    }

    It 'rejects malformed Retry-After without retrying' {
        $script:failure = Get-TransportTestException -Status 429 -Headers @{ 'Retry-After' = 'invalid' }
        Mock Invoke-MgGraphRequest { throw $script:failure }
        { Invoke-GraphApiRequest -Method GET -Uri 'https://graph.microsoft.com/v1.0/test' } | Should -Throw '*invalid Retry-After*'
        Should -Invoke Invoke-MgGraphRequest -Times 1 -Exactly
        Should -Invoke Start-Sleep -Times 0 -Exactly
    }

    It 'does not expose URI, payload or untrusted request identifiers in logs' {
        $script:failure = Get-TransportTestException -Status 429 -Headers @{ 'request-id' = 'unsafe secret text' }
        Mock Invoke-MgGraphRequest { throw $script:failure }
        { Invoke-GraphApiRequest -Method POST -Uri 'https://graph.microsoft.com/v1.0/secret-uri' -Body 'secret-body' } | Should -Throw
        Should -Invoke Write-AutopilotExpressLog -Times 1 -Exactly -ParameterFilter { $Message -like '*request-id=unavailable*' -and $Message -notmatch 'secret|unsafe' }
    }

    It 'reports unknown HTTP status and URI exception type without leaking query or body or retrying' {
        Mock Invoke-MgGraphRequest { throw [System.UriFormatException]::new('Synthetic secret SDK body') }
        { Invoke-GraphApiRequest -Method GET -Uri 'https://graph.microsoft.com/v1.0/organization?$select=secret-field' } | Should -Throw
        Should -Invoke Write-AutopilotExpressLog -Times 1 -Exactly -ParameterFilter { $Message -like '*HTTP=unavailable*request-id=unavailable*Exception=*UriFormatException*' -and $Message -notmatch 'secret|organization|graph.microsoft.com' }
        Should -Invoke Invoke-MgGraphRequest -Times 1 -Exactly
        Should -Invoke Start-Sleep -Times 0 -Exactly
    }
}