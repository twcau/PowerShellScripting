<#
.SYNOPSIS
    Checks unambiguous scanner selection and shared main/bench routing.
.DESCRIPTION
    Extracts only the real resolver, integer converter and main selector from
    the source AST. Synthetic records and mocked prompts avoid CLI startup,
    persistence and live calls. Bench routing is inspected without execution.
.FILECREATED
    2026-10-08
.FILELASTUPDATED
    2026-10-08
#>
BeforeAll {
    $sourcePath = Join-Path (Split-Path -Parent $PSScriptRoot) 'autopilot-express.ps1'
    $tokens = $null
    $parseErrors = $null
    $script:sourceAst = [System.Management.Automation.Language.Parser]::ParseFile($sourcePath, [ref]$tokens, [ref]$parseErrors)
    if ($parseErrors.Count) { throw ($parseErrors.Message -join '; ') }
    foreach ($functionName in @('Resolve-DeviceSelection', 'ConvertTo-OptionalInteger', 'Select-DeviceFromRecords')) {
        $definition = $script:sourceAst.Find({ param($node) $node -is [System.Management.Automation.Language.FunctionDefinitionAst] -and $node.Name -eq $functionName }, $true)
        if ($null -eq $definition) { throw ('Missing function: {0}' -f $functionName) }
        . ([scriptblock]::Create($definition.Extent.Text))
    }
    function Read-ValidatedInput {
        <# .SYNOPSIS Reject an unexpected interactive prompt in isolated tests. #>
        param($Prompt)
        throw ('Unexpected prompt: {0}' -f $Prompt)
    }
    function Show-ReturnToMainMenu {
        <# .SYNOPSIS Replace the interactive acknowledgement that follows a failed main-menu selection. #>
    }
}

Describe 'Scanner selection identity and routing' {
    BeforeEach {
        $script:items = @(
            @{ Serial = 'AAAA'; ConfigItem = '900'; Index = 1; Status = 'in-progress' },
            @{ Serial = 'BBBB'; ConfigItem = '1'; Index = 2; Status = 'in-progress' }
        )
        Mock Write-Host {}
    }

    It 'rejects a numeric CI collision with a displayed position in the main selector' {
        Mock Read-ValidatedInput { return '1' }
        Select-DeviceFromRecords -Records @{ Value = $script:items } -Purpose 'test' | Should -BeNullOrEmpty
        Should -Invoke Write-Host -Times 1 -Exactly -ParameterFilter { $Object -like 'Ambiguous selection*' }
    }

    It 'rejects a numeric CI collision with a stored bench position' {
        Resolve-DeviceSelection -Items $script:items -Selection '1' -Bench | Should -BeNullOrEmpty
        Should -Invoke Write-Host -Times 1 -Exactly -ParameterFilter { $Object -like 'Ambiguous selection*' }
    }

    It 'keeps leading-zero CI text while also checking its numeric position' {
        $script:items[1].ConfigItem = '001'
        Resolve-DeviceSelection -Items $script:items -Selection '001' | Should -BeNullOrEmpty
        Resolve-DeviceSelection -Items $script:items -Selection '001' -Bench | Should -BeNullOrEmpty
        Should -Invoke Write-Host -Times 2 -Exactly -ParameterFilter { $Object -like 'Ambiguous selection*' }
    }

    It 'matches leading-zero identifiers literally rather than normalising them to another CI' {
        $script:items[1].ConfigItem = '00900'
        (Resolve-DeviceSelection -Items $script:items -Selection 'CI:00900').Serial | Should -Be 'BBBB'
        (Resolve-DeviceSelection -Items $script:items -Selection 'CI:900').Serial | Should -Be 'AAAA'
        Resolve-DeviceSelection -Items $script:items -Selection 'CI:0900' | Should -BeNullOrEmpty
    }

    It 'uses case-insensitive explicit position CI and serial prefixes to disambiguate' {
        (Resolve-DeviceSelection -Items $script:items -Selection 'p:1').Serial | Should -Be 'AAAA'
        (Resolve-DeviceSelection -Items $script:items -Selection 'cI:1' -Bench).Serial | Should -Be 'BBBB'
        (Resolve-DeviceSelection -Items $script:items -Selection 's:bbbb').Serial | Should -Be 'BBBB'
        (Resolve-DeviceSelection -Items $script:items -Selection 'P:2' -Bench).Serial | Should -Be 'BBBB'
    }

    It 'rejects duplicate serial matches even with an explicit serial prefix' {
        $script:items[1].Serial = 'aaaa'
        Resolve-DeviceSelection -Items $script:items -Selection 'AAAA' | Should -BeNullOrEmpty
        Resolve-DeviceSelection -Items $script:items -Selection 'S:AAAA' -Bench | Should -BeNullOrEmpty
        Should -Invoke Write-Host -Times 2 -Exactly -ParameterFilter { $Object -like 'Ambiguous selection*' }
    }

    It 'rejects duplicate CI matches even with an explicit CI prefix' {
        $script:items[1].ConfigItem = '900'
        Resolve-DeviceSelection -Items $script:items -Selection '900' -Bench | Should -BeNullOrEmpty
        Resolve-DeviceSelection -Items $script:items -Selection 'CI:900' | Should -BeNullOrEmpty
        Should -Invoke Write-Host -Times 2 -Exactly -ParameterFilter { $Object -like 'Ambiguous selection*' }
    }

    It 'unions serial CI and numeric position matches across different items' {
        $script:items[0].Serial = '2'
        Resolve-DeviceSelection -Items $script:items -Selection '2' | Should -BeNullOrEmpty
        $script:items[1].ConfigItem = '2'
        Resolve-DeviceSelection -Items $script:items -Selection '2' -Bench | Should -BeNullOrEmpty
        (Resolve-DeviceSelection -Items $script:items -Selection 'S:2').Serial | Should -Be '2'
        Should -Invoke Write-Host -Times 2 -Exactly -ParameterFilter { $Object -like 'Ambiguous selection*' }
    }

    It 'counts one item only once when its position serial and CI all match' {
        $script:items[0].Serial = '1'
        $script:items[0].ConfigItem = '1'
        $script:items[1].ConfigItem = '900'
        $selected = Resolve-DeviceSelection -Items $script:items -Selection '1'
        [object]::ReferenceEquals($selected, $script:items[0]) | Should -BeTrue
        $benchSelected = Resolve-DeviceSelection -Items $script:items -Selection '1' -Bench
        [object]::ReferenceEquals($benchSelected, $script:items[0]) | Should -BeTrue
        Should -Invoke Write-Host -Times 0 -Exactly
    }

    It 'accepts omitted or empty items and an IEnumerable without selecting missing input' {
        Resolve-DeviceSelection -Selection 'AAAA' | Should -BeNullOrEmpty
        Resolve-DeviceSelection -Items @() -Selection 'P:1' -Bench | Should -BeNullOrEmpty
        Resolve-DeviceSelection -Items $script:items -Selection '' | Should -BeNullOrEmpty
        Resolve-DeviceSelection -Items $script:items -Selection 'unknown' | Should -BeNullOrEmpty
        $collection = [System.Collections.ArrayList]::new()
        [void]$collection.Add($script:items[0])
        (Resolve-DeviceSelection -Items $collection -Selection 'AAAA').Serial | Should -Be 'AAAA'
    }

    It 'skips empty bench positions and uses actual stored indices not occupied-list offsets' {
        $positions = @(
            @{ Index = 1; Serial = ''; ConfigItem = '' },
            @{ Index = 7; Serial = 'DEVICE-SEVEN'; ConfigItem = '700' }
        )
        Resolve-DeviceSelection -Items $positions -Selection 'P:1' -Bench | Should -BeNullOrEmpty
        Resolve-DeviceSelection -Items $positions -Selection '2' -Bench | Should -BeNullOrEmpty
        (Resolve-DeviceSelection -Items $positions -Selection '7' -Bench).Serial | Should -Be 'DEVICE-SEVEN'
        (Resolve-DeviceSelection -Items $positions -Selection 'P:7' -Bench).Serial | Should -Be 'DEVICE-SEVEN'
    }

    It 'cancels bare zero but permits an explicitly selected zero CI' {
        $script:items[0].ConfigItem = '0'
        Resolve-DeviceSelection -Items $script:items -Selection '0' | Should -BeNullOrEmpty
        Resolve-DeviceSelection -Items $script:items -Selection '0' -Bench | Should -BeNullOrEmpty
        (Resolve-DeviceSelection -Items $script:items -Selection 'CI:0').Serial | Should -Be 'AAAA'
        (Resolve-DeviceSelection -Items $script:items -Selection 'ci:0' -Bench).Serial | Should -Be 'AAAA'
    }

    It 'filters removed records before resolving the main displayed list' {
        $script:items[0].Status = 'removed'
        Mock Read-ValidatedInput { return '1' }
        $selected = Select-DeviceFromRecords -Records @{ Value = $script:items } -Purpose 'test'
        [object]::ReferenceEquals($selected, $script:items[1]) | Should -BeTrue
        Mock Read-ValidatedInput { return 'S:AAAA' }
        Select-DeviceFromRecords -Records @{ Value = $script:items } -Purpose 'test' | Should -BeNullOrEmpty
        Should -Invoke Write-Host -Times 0 -Exactly -ParameterFilter { $Object -like 'Ambiguous selection*' }
    }

    It 'routes all bench action source selections and top-level scans through the shared resolver' {
        $benchCalls = @($script:sourceAst.FindAll({
            param($node)
            $node -is [System.Management.Automation.Language.CommandAst] -and
            $node.GetCommandName() -eq 'Resolve-DeviceSelection' -and
            @($node.CommandElements | Where-Object { $_ -is [System.Management.Automation.Language.CommandParameterAst] -and $_.ParameterName -eq 'Bench' }).Count -eq 1
        }, $true))
        # Seven action clauses plus the default top-level scan path.
        $benchCalls.Count | Should -Be 8
        $owners = @($benchCalls | ForEach-Object {
            $ancestor = $_.Parent
            while ($null -ne $ancestor -and $ancestor -isnot [System.Management.Automation.Language.FunctionDefinitionAst]) { $ancestor = $ancestor.Parent }
            if ($null -eq $ancestor) { throw 'Bench resolver call has no owning function' }
            $ancestor
        })
        @($owners.Name | Select-Object -Unique).Count | Should -Be 1
        $benchDefinition = $owners[0]
        $actionSwitches = @($benchDefinition.Body.FindAll({ param($node) $node -is [System.Management.Automation.Language.SwitchStatementAst] }, $true))
        # Multi-key clauses use a scriptblock condition such as { $_ -in @('T', 'X') }; match the quoted key text.
        foreach ($action in @('T', 'R', 'S', 'C', 'D', 'V', 'M')) {
            $keyText = "'{0}'" -f $action
            $clauses = @($actionSwitches.Clauses | Where-Object { $_.Item1.Extent.Text.Contains($keyText) })
            $clauses.Count | Should -Be 1
            $calls = @($clauses[0].Item2.FindAll({ param($node) $node -is [System.Management.Automation.Language.CommandAst] -and $node.GetCommandName() -eq 'Resolve-DeviceSelection' }, $true))
            $calls.Count | Should -Be 1
            $calls[0].Extent.Text | Should -Match '-Items\s+\$Script:BuildBench\.Positions\s+-Selection\s+\$(ans|srcAns)\s+-Bench'
            if ($action -eq 'M') { $calls[0].Extent.Text | Should -Match '-Selection\s+\$srcAns\b' }
        }
    }
}