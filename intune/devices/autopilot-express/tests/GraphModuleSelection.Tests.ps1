<#
.SYNOPSIS
    Check deterministic installed SDK selection without installation or tenant calls.
.DESCRIPTION
    Extract production import functions and mock module discovery and imports.
    Requires Pester 5 and FullLanguage for source parsing.
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
    $sourcePath = Join-Path (Split-Path -Parent $PSScriptRoot) 'autopilot-express.ps1'
    $tokens = $null
    $parseErrors = $null
    $sourceAst = [System.Management.Automation.Language.Parser]::ParseFile($sourcePath, [ref]$tokens, [ref]$parseErrors)
    if ($parseErrors.Count) { throw ($parseErrors.Message -join '; ') }
    foreach ($functionName in @('Get-GraphLocalModuleRoot', 'Test-GraphModuleLocalPath', 'Get-GraphModuleCandidate', 'Test-GraphModuleScriptTrust', 'Request-GraphModuleScriptTrust', 'Get-GraphModuleImportPlan', 'Import-RequiredGraphModules', 'Test-LiveRuntimeConfiguration')) {
        $definition = $sourceAst.Find({ param($node) $node -is [System.Management.Automation.Language.FunctionDefinitionAst] -and $node.Name -eq $functionName }, $true)
        Set-Item -Path ('Function:{0}' -f $definition.Name) -Value $definition.Body.GetScriptBlock()
    }
    $script:localGraphInstaller = $sourceAst.Find({ param($node) $node -is [Management.Automation.Language.FunctionDefinitionAst] -and $node.Name -eq 'Install-RequiredGraphModules' }, $true).Body.GetScriptBlock()
    function Get-ConfiguredGraphModules { return @('Microsoft.Graph.DeviceManagement.Enrollment') }
    function Install-RequiredGraphModules { param($RequiredModules) return ($RequiredModules.Count -gt 0) }
    function Read-ValidatedInput {
        param($Prompt, $Default, $Type, $Choices)
        if (-not $Prompt -or $Type -ne 'Choice' -or $Default -notin $Choices) { throw 'Invalid synthetic choice prompt contract.' }
        return $Default
    }
    function Write-AutopilotExpressLog { param($Message, $Level) throw ('Unexpected log: {0}: {1}' -f $Level, $Message) }
    # Pester requires a resolvable command before it can register a mock.
    # Restricted hosts may omit PowerShellGet, so create inert, parameter-compatible targets only when absent.
    $mockTargets = @(
        @{ Name = 'Save-Module'; Parameters = '$Name, $RequiredVersion, $Repository, $Path, [switch]$Force' }
        @{ Name = 'Find-Module'; Parameters = '$Name, $Repository' }
        @{ Name = 'Install-Module'; Parameters = '$Name, $RequiredVersion, $Repository, $Scope, [switch]$Force' }
    )
    foreach ($mockTarget in $mockTargets) {
        if (-not (Get-Command -Name $mockTarget.Name -ErrorAction SilentlyContinue)) {
            $definition = 'param({0}) throw ''{1} stand-in must be mocked.''' -f $mockTarget.Parameters, $mockTarget.Name
            Set-Item -Path ('Function:{0}' -f $mockTarget.Name) -Value ([scriptblock]::Create($definition))
        }
    }
}
Describe 'Graph filesystem discovery before execution' {
    BeforeEach {
        $script:sdkFixture = Join-Path $TestDrive ([guid]::NewGuid().ToString('N'))
        $script:authFixture = Join-Path $sdkFixture 'Microsoft.Graph.Authentication/2.41.1'
        $null = New-Item -ItemType Directory -Path $authFixture -Force
        $script:sdkManifest = Join-Path $authFixture 'Microsoft.Graph.Authentication.psd1'
        Set-Content -LiteralPath $sdkManifest -Value "@{ ModuleVersion = '2.41.1'; RootModule = 'must-not-execute.psm1' }"
        Set-Content -LiteralPath (Join-Path $authFixture 'must-not-execute.psm1') -Value 'throw "SDK code must never execute during discovery"'
        Mock Import-Module { throw 'Discovery cannot import SDK code' }
        Mock Get-Module { throw 'Discovery cannot load module metadata' }
    }
    It 'reads literal metadata without module discovery or execution' {
        $items = @(Get-GraphModuleCandidate -RequiredModules @('Microsoft.Graph.Authentication') -ModuleRoots @($sdkFixture))
        $items.Count | Should -Be 1
        $items[0].Version | Should -Be ([version]'2.41.1')
        $items[0].Path | Should -BeExactly $sdkManifest
        Should -Invoke Get-Module -Times 0 -Exactly
        Should -Invoke Import-Module -Times 0 -Exactly
    }
    It 'refuses a manifest expression instead of evaluating it' {
        Set-Content -LiteralPath $sdkManifest -Value '@{ ModuleVersion = (throw "Not data") }'
        { Get-GraphModuleCandidate -RequiredModules @('Microsoft.Graph.Authentication') -ModuleRoots @($sdkFixture) } | Should -Throw
        Should -Invoke Import-Module -Times 0 -Exactly
    }
    It 'returns no candidates for a missing installed module without installing anything' {
        @(Get-GraphModuleCandidate -RequiredModules @('Microsoft.Graph.Authentication') -ModuleRoots @()).Count | Should -Be 0
    }
}
Describe 'Selected Graph deployment trust' {
    BeforeEach {
        $script:trustRoot = Join-Path $TestDrive ([guid]::NewGuid().ToString('N'))
        $null = New-Item -ItemType Directory -Path $trustRoot
        $script:trustFile = Join-Path $trustRoot 'Synthetic.psm1'
        Set-Content -LiteralPath $trustFile -Value 'throw "Never execute this fixture"'
        $script:trustPlan = @(@{ ModuleBase = $trustRoot; Path = $trustFile })
        Mock Get-ExecutionPolicy { 'RemoteSigned' }
        Mock Import-Module { throw 'Trust inspection cannot import code.' }
        Mock Unblock-File {}
        Mock Read-ValidatedInput { 'N' }
        Mock Write-AutopilotExpressLog {}
    }
    It 'accepts an unmarked local deployment without importing or unblocking it' {
        (Test-GraphModuleScriptTrust -Plan $trustPlan).Ready | Should -BeTrue
        Should -Invoke Import-Module -Times 0 -Exactly
        Should -Invoke Unblock-File -Times 0 -Exactly
    }
    It 'retains exact fingerprints of Internet-marked files' {
        Set-Content -LiteralPath $trustFile -Stream Zone.Identifier -Value "[ZoneTransfer]`r`nZoneId=3" -Encoding ASCII
        $result = Test-GraphModuleScriptTrust -Plan $trustPlan
        $result.Ready | Should -BeFalse
        $result.Files.Count | Should -Be 1
        $result.Files[0].Path | Should -BeExactly $trustFile
        $result.Files[0].SHA256 | Should -BeExactly (Get-FileHash -LiteralPath $trustFile -Algorithm SHA256).Hash
    }
    It 'does not unblock when default-No consent is declined' {
        Set-Content -LiteralPath $trustFile -Stream Zone.Identifier -Value "[ZoneTransfer]`r`nZoneId=3" -Encoding ASCII
        Request-GraphModuleScriptTrust -Plan $trustPlan | Should -BeFalse
        Should -Invoke Read-ValidatedInput -Times 1 -Exactly -ParameterFilter { $Default -eq 'N' }
        Should -Invoke Unblock-File -Times 0 -Exactly
    }
    It 'unblocks only the reviewed unchanged fixture and rechecks it after consent' {
        Set-Content -LiteralPath $trustFile -Stream Zone.Identifier -Value "[ZoneTransfer]`r`nZoneId=3" -Encoding ASCII
        Mock Read-ValidatedInput { 'y' }
        Mock Unblock-File { Remove-Item -LiteralPath $LiteralPath -Stream Zone.Identifier -ErrorAction Stop }
        Request-GraphModuleScriptTrust -Plan $trustPlan | Should -BeTrue
        Should -Invoke Unblock-File -Times 1 -Exactly -ParameterFilter { $LiteralPath -eq $script:trustFile }
        Should -Invoke Import-Module -Times 0 -Exactly
    }
    It 'rejects content changed during explicit review before any unblocking' {
        Set-Content -LiteralPath $trustFile -Stream Zone.Identifier -Value "[ZoneTransfer]`r`nZoneId=3" -Encoding ASCII
        Mock Read-ValidatedInput { Set-Content -LiteralPath $script:trustFile -Value 'changed'; 'Y' }
        { Request-GraphModuleScriptTrust -Plan $trustPlan } | Should -Throw '*changed after review*'
        Should -Invoke Unblock-File -Times 0 -Exactly
    }
    It 'never treats Restricted policy as something unblocking can fix' {
        Mock Get-ExecutionPolicy { 'Restricted' }
        { Request-GraphModuleScriptTrust -Plan $trustPlan } | Should -Throw '*Restricted*'
        Should -Invoke Read-ValidatedInput -Times 0 -Exactly
        Should -Invoke Unblock-File -Times 0 -Exactly
    }
    It 'rejects an unsigned AllSigned deployment without granting trust' {
        Mock Get-ExecutionPolicy { 'AllSigned' }
        Mock Get-AuthenticodeSignature { @{ Status = 'NotSigned'; SignerCertificate = $null } }
        { Test-GraphModuleScriptTrust -Plan $trustPlan } | Should -Throw '*signature*'
        Should -Invoke Unblock-File -Times 0 -Exactly
    }
    It 'rejects a valid but untrusted publisher rather than surfacing a run-once prompt' {
        Mock Get-ExecutionPolicy { 'AllSigned' }
        Mock Get-AuthenticodeSignature { @{ Status = 'Valid'; SignerCertificate = @{ Thumbprint = 'UNAPPROVED' } } }
        Mock Get-ChildItem { @() } -ParameterFilter { $LiteralPath -contains 'Cert:\CurrentUser\TrustedPublisher' }
        { Test-GraphModuleScriptTrust -Plan $trustPlan } | Should -Throw '*publisher is not already trusted*'
        Should -Invoke Unblock-File -Times 0 -Exactly
    }
    It 'does not assume an unmarked UNC deployment is locally trusted' {
        $script:networkRoot = '\\synthetic-server\sdk\Authentication'
        $script:networkFile = [pscustomobject]@{ FullName = ($networkRoot + '\Module.psm1'); Extension = '.psm1'; PSIsContainer = $false; Attributes = [IO.FileAttributes]::Normal }
        Mock Get-Item { if ($Stream) { @() } else { [pscustomobject]@{ Attributes = [IO.FileAttributes]::Directory; PSIsContainer = $true } } }
        Mock Get-ChildItem { $script:networkFile }
        Mock Get-AuthenticodeSignature { @{ Status = 'NotSigned'; SignerCertificate = $null } }
        { Test-GraphModuleScriptTrust -Plan @(@{ ModuleBase = $networkRoot }) } | Should -Throw '*network-zone trust cannot be established*'
        Should -Invoke Import-Module -Times 0 -Exactly
    }
}
Describe 'Installed Graph SDK selection' {
    BeforeEach {
        $script:available = @(
            @{ Name = 'Microsoft.Graph.Authentication'; Version = [version]'2.29.1'; Path = 'C:\SDK\Auth\2.29.1\Auth.psd1'; ModuleBase = 'C:\SDK\Auth\2.29.1' }
            @{ Name = 'Microsoft.Graph.Authentication'; Version = [version]'2.27.0'; Path = 'C:\SDK\Auth\2.27.0\Auth.psd1'; ModuleBase = 'C:\SDK\Auth\2.27.0' }
            @{ Name = 'Microsoft.Graph.DeviceManagement.Enrollment'; Version = [version]'2.27.0'; Path = 'C:\SDK\Enrollment\2.27.0\Enrollment.psd1'; ModuleBase = 'C:\SDK\Enrollment\2.27.0' }
        )
        $script:loaded = @()
        Mock Get-GraphModuleCandidate { return $script:available }
        Mock Request-GraphModuleScriptTrust { return $true }
        Mock Get-Module { if ($ListAvailable) { return $script:available } else { return $script:loaded } }
        Mock Import-Module {}
        Mock Write-AutopilotExpressLog {}
    }
    It 'chooses the newest common version with Authentication first' {
        $plan = Get-GraphModuleImportPlan -RequiredModules @('Microsoft.Graph.DeviceManagement.Enrollment')
        $plan.Count | Should -Be 2
        $plan[0].Name | Should -Be 'Microsoft.Graph.Authentication'
        $plan[0].Version | Should -Be ([version]'2.27.0')
    }
    It 'selects a newer complete set when installed' {
        $script:available += @{ Name = 'Microsoft.Graph.DeviceManagement.Enrollment'; Version = [version]'2.29.1'; Path = 'C:\SDK\Enrollment\2.29.1\Enrollment.psd1'; ModuleBase = 'C:\SDK\Enrollment\2.29.1' }
        (Get-GraphModuleImportPlan -RequiredModules @('Microsoft.Graph.DeviceManagement.Enrollment'))[0].Version | Should -Be ([version]'2.29.1')
    }
    It 'prefers a complete local version over a newer network deployment' {
        $script:available += @(
            @{ Name = 'Microsoft.Graph.Authentication'; Version = [version]'9.0.0'; Path = '\\server\modules\Auth.psd1'; ModuleBase = '\\server\modules\Auth' }
            @{ Name = 'Microsoft.Graph.DeviceManagement.Enrollment'; Version = [version]'9.0.0'; Path = '\\server\modules\Enrollment.psd1'; ModuleBase = '\\server\modules\Enrollment' }
        )
        (Get-GraphModuleImportPlan -RequiredModules @('Microsoft.Graph.DeviceManagement.Enrollment'))[0].Version | Should -Be ([version]'2.27.0')
    }
    It 'refuses a network-only SDK without importing any remote assemblies' {
        $script:available = @(
            @{ Name = 'Microsoft.Graph.Authentication'; Version = [version]'2.27.0'; Path = '\\server\modules\Auth.psd1'; ModuleBase = '\\server\modules\Auth' }
            @{ Name = 'Microsoft.Graph.DeviceManagement.Enrollment'; Version = [version]'2.27.0'; Path = '\\server\modules\Enrollment.psd1'; ModuleBase = '\\server\modules\Enrollment' }
        )
        Import-RequiredGraphModules | Should -BeFalse
        Should -Invoke Import-Module -Times 0 -Exactly
    }
    It 'refuses missing common versions before importing' {
        $script:available = @($script:available | Where-Object { $_.Version -eq [version]'2.29.1' -or $_.Name -ne 'Microsoft.Graph.Authentication' })
        Import-RequiredGraphModules | Should -BeFalse
        Should -Invoke Import-Module -Times 0 -Exactly
    }
    It 'refuses a conflicting preloaded SDK version' {
        $script:loaded = @($script:available[0])
        Import-RequiredGraphModules | Should -BeFalse
        Should -Invoke Import-Module -Times 0 -Exactly
    }
    It 'refuses the same version from another installation' {
        $script:loaded = @(@{ Name = 'Microsoft.Graph.Authentication'; Version = [version]'2.27.0'; ModuleBase = 'C:\Other' })
        Import-RequiredGraphModules | Should -BeFalse
        Should -Invoke Import-Module -Times 0 -Exactly
    }
    It 'imports exact manifest paths rather than module names' {
        Import-RequiredGraphModules | Should -BeTrue
        Should -Invoke Import-Module -Times 1 -Exactly -ParameterFilter { $Name -eq 'C:\SDK\Auth\2.27.0\Auth.psd1' }
        Should -Invoke Import-Module -Times 1 -Exactly -ParameterFilter { $Name -eq 'C:\SDK\Enrollment\2.27.0\Enrollment.psd1' }
    }
    It 'returns guarded failure when startup discovery fails at <Stage>' -ForEach @(
        @{ Stage = 'configuration'; Command = 'Get-ConfiguredGraphModules' },
        @{ Stage = 'installed module lookup'; Command = 'Install-RequiredGraphModules' }
    ) {
        Mock -CommandName $Command -MockWith { throw 'Synthetic startup discovery failure.' }
        Import-RequiredGraphModules | Should -BeFalse
        Should -Invoke Import-Module -Times 0 -Exactly
        Should -Invoke Write-AutopilotExpressLog -Times 1 -Exactly -ParameterFilter { $Level -eq 'ERROR' -and $Message -like '*Synthetic startup discovery failure*' }
    }
    It 'reuses the pinned discovery plan when checking post-import dependency drift' {
        Import-RequiredGraphModules | Should -BeTrue
        Should -Invoke Get-GraphModuleCandidate -Times 1 -Exactly
        Should -Invoke Get-Module -Times 0 -Exactly -ParameterFilter { $ListAvailable }
    }
    It 'does not import when selected deployment trust is declined' {
        Mock Request-GraphModuleScriptTrust { return $false }
        Import-RequiredGraphModules | Should -BeFalse
        Should -Invoke Import-Module -Times 0 -Exactly
    }
    It 'records SDK import boundaries before and after each selected module' {
        Import-RequiredGraphModules | Should -BeTrue
        Should -Invoke Write-AutopilotExpressLog -Times 2 -Exactly -ParameterFilter { $Message -like 'Importing Graph SDK module *' -and $Level -eq 'INFO' }
        Should -Invoke Write-AutopilotExpressLog -Times 2 -Exactly -ParameterFilter { $Message -like 'Imported Graph SDK module *' -and $Level -eq 'INFO' }
    }
    It 'returns failure when an import fails' {
        Mock Import-Module { throw 'Synthetic import failure' }
        Import-RequiredGraphModules | Should -BeFalse
    }
    It 'rejects dependency drift after imports' {
        Mock Import-Module { $script:loaded = @($script:available[0]) }
        Import-RequiredGraphModules | Should -BeFalse
    }
}

Describe 'Non-administrative local Graph SDK deployment' {
    BeforeEach {
        $script:localSdkRoot = Join-Path $TestDrive ('LocalGraphModules-{0}' -f [guid]::NewGuid().ToString('N'))
        $script:localSdkNames = @('Microsoft.Graph.Authentication', 'Microsoft.Graph.DeviceManagement.Enrollment')
        $script:remoteSdk = @($localSdkNames | ForEach-Object { @{ Name = $_; Version = [version]'2.41.1'; Path = '\\server\modules\{0}\2.41.1\{0}.psd1' -f $_; ModuleBase = '\\server\modules\{0}\2.41.1' -f $_ } })
        $script:savedSdk = @($localSdkNames | ForEach-Object { @{ Name = $_; Version = [version]'2.41.1'; Path = Join-Path $script:localSdkRoot ('{0}\2.41.1\{0}.psd1' -f $_); ModuleBase = Join-Path $script:localSdkRoot ('{0}\2.41.1' -f $_) } })
        Mock Get-GraphLocalModuleRoot { $script:localSdkRoot }
        Mock Get-GraphModuleCandidate { $script:remoteSdk }
        Mock Get-GraphModuleCandidate { $script:savedSdk } -ParameterFilter { $ModuleRoots.Count -eq 1 -and $ModuleRoots[0] -eq $script:localSdkRoot }
        Mock Get-Module { @() }
        Mock Read-ValidatedInput { 'y' }
        Mock Save-Module {}
        Mock Find-Module { throw 'Installed version should be retained' }
        Mock Install-Module { throw 'CurrentUser installation may use a redirected home and must not be used' }
        Mock Import-Module { throw 'Deployment must not execute SDK code' }
        Mock Write-AutopilotExpressLog {}
    }
    It 'downloads every module at the existing coherent version without UAC or altering remote copies' {
        & $script:localGraphInstaller -RequiredModules @('Microsoft.Graph.DeviceManagement.Enrollment') | Should -BeTrue
        Should -Invoke Save-Module -Times 2 -Exactly -ParameterFilter { $Path -eq $script:localSdkRoot -and $RequiredVersion -eq '2.41.1' -and $Repository -eq 'PSGallery' }
        Should -Invoke Install-Module -Times 0 -Exactly
        Should -Invoke Import-Module -Times 0 -Exactly
        Should -Invoke Find-Module -Times 0 -Exactly
    }
    It 'makes no changes when local deployment consent is declined' {
        Mock Read-ValidatedInput { 'n' }
        & $script:localGraphInstaller -RequiredModules @('Microsoft.Graph.DeviceManagement.Enrollment') | Should -BeFalse
        Test-Path -LiteralPath $script:localSdkRoot | Should -BeFalse
        Should -Invoke Save-Module -Times 0 -Exactly
        Should -Invoke Read-ValidatedInput -Times 1 -Exactly -ParameterFilter { $Default -eq 'N' }
    }
    It 'does not download when a coherent local deployment already exists' {
        Mock Get-GraphModuleCandidate { $script:savedSdk }
        & $script:localGraphInstaller -RequiredModules @('Microsoft.Graph.DeviceManagement.Enrollment') | Should -BeTrue
        Should -Invoke Save-Module -Times 0 -Exactly
        Should -Invoke Read-ValidatedInput -Times 0 -Exactly
    }
    It 'surfaces deployment failure without importing or returning success' {
        Mock Save-Module { throw 'Synthetic gallery failure' }
        & $script:localGraphInstaller -RequiredModules @('Microsoft.Graph.DeviceManagement.Enrollment') | Should -BeFalse
        Should -Invoke Write-AutopilotExpressLog -Times 1 -Exactly -ParameterFilter { $Level -eq 'ERROR' -and $Message -like '*Synthetic gallery failure*' }
        Should -Invoke Import-Module -Times 0 -Exactly
    }
}

Describe 'Offline Live configuration refusal' {
    BeforeEach {
        $script:RuntimeConfig = @{
            configVersion = '1.0.0'
            graph = @{ authMode = 'Browser'; contextScope = 'Process'; requiredScopes = @('User.Read'); requiredModules = @('Microsoft.Graph.Authentication') }
            autopilot = @{ technicianUpnPrefixes = @('C', 'E'); directorySearchLimit = 20; recentUsersLimit = 10 }
        }
        Mock Import-Module { throw 'Configuration validation must not import modules.' }
    }
    It 'accepts locally valid settings without importing or authenticating' {
        @(Test-LiveRuntimeConfiguration).Count | Should -Be 0
        Should -Invoke Import-Module -Times 0 -Exactly
    }
    It 'accepts device-code authentication without importing or authenticating' {
        $script:RuntimeConfig.graph.authMode = 'DeviceCode'
        @(Test-LiveRuntimeConfiguration).Count | Should -Be 0
        Should -Invoke Import-Module -Times 0 -Exactly
    }
    It 'reports a missing <Block> block without throwing' -TestCases @(
        @{ Block = 'graph' }, @{ Block = 'autopilot' }
    ) {
        param($Block)
        $script:RuntimeConfig.Remove($Block)
        $issues = @(Test-LiveRuntimeConfiguration)
        $issues | Should -Contain ('Runtime configuration is missing the {0} block.' -f $Block)
        Should -Invoke Import-Module -Times 0 -Exactly
    }
    It 'rejects invalid <Block>.<Key> locally' -TestCases @(
        @{ Block = 'graph'; Key = 'authMode'; Value = 'Device'; Expected = '*must be Browser or DeviceCode*' }
        @{ Block = 'graph'; Key = 'contextScope'; Value = 'Tenant'; Expected = '*contextScope must be*' }
        @{ Block = 'graph'; Key = 'requiredScopes'; Value = @(); Expected = '*scope is required*' }
        @{ Block = 'graph'; Key = 'requiredModules'; Value = @(' '); Expected = '*module is required*' }
        @{ Block = 'autopilot'; Key = 'technicianUpnPrefixes'; Value = @(); Expected = '*UPN prefix is required*' }
        @{ Block = 'autopilot'; Key = 'directorySearchLimit'; Value = 0; Expected = '*directorySearchLimit must be a positive integer*' }
        @{ Block = 'autopilot'; Key = 'directorySearchLimit'; Value = -1; Expected = '*directorySearchLimit must be a positive integer*' }
        @{ Block = 'autopilot'; Key = 'directorySearchLimit'; Value = 1.5; Expected = '*directorySearchLimit must be a positive integer*' }
        @{ Block = 'autopilot'; Key = 'directorySearchLimit'; Value = $true; Expected = '*directorySearchLimit must be a positive integer*' }
        @{ Block = 'autopilot'; Key = 'recentUsersLimit'; Value = $null; Expected = '*recentUsersLimit must be a positive integer*' }
    ) {
        param($Block, $Key, $Value, $Expected)
        $script:RuntimeConfig[$Block][$Key] = $Value
        $issues = @(Test-LiveRuntimeConfiguration)
        @($issues | Where-Object { $_ -like $Expected }).Count | Should -Be 1
        Should -Invoke Import-Module -Times 0 -Exactly
    }
    It 'rejects malformed semantic versions' -TestCases @(
        @{ Version = $null }, @{ Version = '1.0' }, @{ Version = '1.0.0-extra' }
    ) {
        param($Version)
        $script:RuntimeConfig.configVersion = $Version
        @(Test-LiveRuntimeConfiguration) | Should -Contain 'configVersion must use semantic version format, for example 1.0.0.'
    }
}