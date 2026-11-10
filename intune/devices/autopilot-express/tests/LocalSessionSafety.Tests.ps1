<#
.SYNOPSIS
    Checks local workflow identity safety without starting Graph or the operator menu.
.DESCRIPTION
    Extracts production helpers and uses synthetic records and isolated temporary files.
    No operational session data is read or changed.
#>
BeforeAll {
    $sourcePath = Join-Path (Split-Path -Parent $PSScriptRoot) 'autopilot-express.ps1'
    $tokens = $null
    $parseErrors = $null
    $sourceAst = [System.Management.Automation.Language.Parser]::ParseFile($sourcePath, [ref]$tokens, [ref]$parseErrors)
    if ($parseErrors.Count) { throw ($parseErrors.Message -join '; ') }
    foreach ($functionName in @('Assert-DeviceRecordIdentity', 'Assert-BenchPositionIdentity', 'Add-DeviceRecord', 'Start-LocalSessionLock', 'Stop-LocalSessionLock', 'Request-LocalSessionLock', 'Read-ValidatedInput', 'Get-LocalSessionOwnerState', 'Get-LocalSessionRecoveryInventory', 'Get-RecoveryEvidenceTenantKey', 'Get-RecoveryEvidenceFolder', 'New-LocalSessionRecoverySnapshot', 'Invoke-LocalSessionLockRecovery', 'Start-AutopilotDiagnostics', 'Complete-AutopilotDiagnostics')) {
        $definition = $sourceAst.Find({ param($node) $node -is [System.Management.Automation.Language.FunctionDefinitionAst] -and $node.Name -eq $functionName }, $true)
        if (-not $definition) { throw ('Missing function: {0}' -f $functionName) }
        Set-Item -Path ('Function:{0}' -f $definition.Name) -Value $definition.Body.GetScriptBlock()
    }
    function Get-DataFolderPath { return $script:lockRoot }

    function Invoke-ConstrainedSessionLockProbe {
        <#
        .SYNOPSIS
            Run a synthetic Windows PowerShell child with bounded input and exit waits.
        .PARAMETER Bootstrap
            Single-line test command supplied to the child's standard input.
        .PARAMETER TimeoutMilliseconds
            Maximum time for input and child execution, excluding bounded cleanup.
        .OUTPUTS
            ExitCode, StandardOutput and StandardError from the owned child.
        #>
        param(
            [Parameter(Mandatory)]
            [ValidateNotNullOrEmpty()]
            [string]$Bootstrap,
            [ValidateRange(1, 60000)]
            [int]$TimeoutMilliseconds = 30000
        )

        $startInfo = [Diagnostics.ProcessStartInfo]::new()
        $startInfo.FileName = (Get-Command -Name powershell.exe -CommandType Application -ErrorAction Stop).Source
        $startInfo.Arguments = '-NoProfile -NonInteractive -Command -'
        $startInfo.UseShellExecute = $false
        $startInfo.CreateNoWindow = $true
        $startInfo.RedirectStandardInput = $true
        $startInfo.RedirectStandardOutput = $true
        $startInfo.RedirectStandardError = $true
        $child = [Diagnostics.Process]::new()
        $child.StartInfo = $startInfo
        $started = $false
        try {
            $started = $child.Start()
            if (-not $started) { throw 'Could not start the constrained reservation probe.' }
            $clock = [Diagnostics.Stopwatch]::StartNew()
            $output = $child.StandardOutput.ReadToEndAsync()
            $errors = $child.StandardError.ReadToEndAsync()
            $inputWrite = $child.StandardInput.WriteLineAsync($Bootstrap)
            $timedOut = -not $inputWrite.Wait($TimeoutMilliseconds)
            if (-not $timedOut) {
                $remaining = [Math]::Max(0, $TimeoutMilliseconds - [int]$clock.ElapsedMilliseconds)
                $inputFlush = $child.StandardInput.FlushAsync()
                $timedOut = -not $inputFlush.Wait($remaining)
            }
            if (-not $timedOut) {
                $child.StandardInput.Close()
                $remaining = [Math]::Max(0, $TimeoutMilliseconds - [int]$clock.ElapsedMilliseconds)
                $timedOut = -not $child.WaitForExit($remaining)
            }
            if ($timedOut -and -not $child.HasExited) {
                Stop-Process -Id $child.Id -ErrorAction Stop
                if (-not $child.WaitForExit(5000)) { throw 'Timed-out reservation probe did not stop.' }
            }
            if (-not $output.Wait(5000) -or -not $errors.Wait(5000)) {
                throw 'Reservation probe output did not close after the child exited.'
            }
            if ($timedOut) {
                throw ('Constrained reservation probe exceeded {0} ms. Child error output: {1}' -f $TimeoutMilliseconds, $errors.Result)
            }
            return [pscustomobject]@{
                ExitCode = $child.ExitCode
                StandardOutput = $output.Result
                StandardError = $errors.Result
            }
        }
        finally {
            try {
                if ($started -and -not $child.HasExited) {
                    Stop-Process -Id $child.Id -ErrorAction Stop
                    if (-not $child.WaitForExit(5000)) { throw 'Reservation probe cleanup did not stop its child.' }
                }
            }
            finally { $child.Dispose() }
        }
    }
}

Describe 'Bounded reservation probe' {
    It 'captures successful child output and exit status' {
        $result = Invoke-ConstrainedSessionLockProbe -Bootstrap 'Write-Output "SYNTHETIC_PROBE_OK"'
        $result.ExitCode | Should -Be 0
        $result.StandardOutput | Should -Match 'SYNTHETIC_PROBE_OK'
    }

    It 'captures a child failure and its diagnostic output' {
        $result = Invoke-ConstrainedSessionLockProbe -Bootstrap '[Console]::Error.WriteLine("SYNTHETIC_PROBE_ERROR"); exit 7'
        $result.ExitCode | Should -Be 7
        $result.StandardError | Should -Match 'SYNTHETIC_PROBE_ERROR'
    }

    It 'stops a child that exceeds the deadline' {
        $pidPath = Join-Path $TestDrive ('reservation-probe-{0}.pid' -f [guid]::NewGuid().ToString('N'))
        $escapedPath = $pidPath.Replace("'", "''")
        $bootstrap = '[IO.File]::WriteAllText(''{0}'', [string]$PID); Start-Sleep -Seconds 30' -f $escapedPath
        { Invoke-ConstrainedSessionLockProbe -Bootstrap $bootstrap -TimeoutMilliseconds 10000 } |
            Should -Throw '*exceeded 10000 ms*'
        Test-Path -LiteralPath $pidPath | Should -BeTrue
        $childId = [int](Get-Content -LiteralPath $pidPath -Raw)
        Get-Process -Id $childId -ErrorAction SilentlyContinue | Should -BeNullOrEmpty
    }
}

Describe 'Local workflow identity safeguards' {
    BeforeEach {
        $script:first = @{ RecordId = 'one'; Serial = 'DEVICE-01'; ConfigItem = 'CI-01'; Status = 'in-progress' }
        $script:second = @{ RecordId = 'two'; Serial = 'DEVICE-02'; ConfigItem = 'CI-02'; Status = 'new' }
        $script:records = @{ Value = @($script:first) }
    }

    It 'accepts an empty collection' {
        { Assert-DeviceRecordIdentity -Records @() } | Should -Not -Throw
    }

    It 'appends a distinct device' {
        Add-DeviceRecord -Records $script:records -Record $script:second
        $script:records.Value.Count | Should -Be 2
    }

    It 'rejects a duplicate serial without changing the collection' {
        $script:second.Serial = ' device-01 '
        { Add-DeviceRecord -Records $script:records -Record $script:second } | Should -Throw '*Duplicate serial*'
        $script:records.Value.Count | Should -Be 1
        $script:records.Value[0].RecordId | Should -Be 'one'
    }

    It 'rejects a duplicate record ID' {
        $script:second.RecordId = 'ONE'
        { Add-DeviceRecord -Records $script:records -Record $script:second } | Should -Throw '*record ID*'
        $script:records.Value.Count | Should -Be 1
    }

    It 'rejects an active CI conflict' {
        $script:second.ConfigItem = ' ci-01 '
        { Add-DeviceRecord -Records $script:records -Record $script:second } | Should -Throw '*Configuration Item*'
        $script:records.Value.Count | Should -Be 1
    }

    It 'allows a CI previously used by a removed device with a different serial' {
        $script:first.Status = 'removed'
        $script:second.ConfigItem = 'CI-01'
        { Add-DeviceRecord -Records $script:records -Record $script:second } | Should -Not -Throw
    }

    It 'does not create a second record for a removed serial' {
        $script:first.Status = 'removed'
        $script:second.Serial = 'DEVICE-01'
        { Add-DeviceRecord -Records $script:records -Record $script:second } | Should -Throw '*Duplicate serial*'
    }

    It 'rejects a missing serial' {
        $script:second.Serial = ' '
        { Assert-DeviceRecordIdentity -Records @($script:second) } | Should -Throw '*no serial*'
    }

    It 'rejects a serial matching another device CI' {
        $script:second.ConfigItem = 'device-01'
        { Add-DeviceRecord -Records $script:records -Record $script:second } | Should -Throw '*ambiguous scan identifier*'
        $script:records.Value.Count | Should -Be 1
    }
}

Describe 'Saved bench identity validation' {
    It 'accepts distinct occupied and empty positions' {
        { Assert-BenchPositionIdentity -Positions @(@{ Index = 1; Serial = 'DEVICE-01'; ConfigItem = 'CI-01' }, @{ Index = 2; Serial = ''; ConfigItem = '' }) } | Should -Not -Throw
    }

    It 'rejects duplicate position numbers' {
        { Assert-BenchPositionIdentity -Positions @(@{ Index = 1 }, @{ Index = 1 }) } | Should -Throw '*duplicate numbers*'
    }

    It 'rejects non-positive position numbers' {
        { Assert-BenchPositionIdentity -Positions @(@{ Index = 0 }) } | Should -Throw '*invalid*'
    }

    It 'rejects repeated occupied serials' {
        { Assert-BenchPositionIdentity -Positions @(@{ Index = 1; Serial = 'DEVICE-01' }, @{ Index = 2; Serial = 'device-01' }) } | Should -Throw '*Duplicate serial*'
    }

    It 'rejects a CI without a serial' {
        { Assert-BenchPositionIdentity -Positions @(@{ Index = 1; ConfigItem = 'CI-01' }) } | Should -Throw '*no serial*'
    }
}

Describe 'Automatic diagnostic transcript ownership' {
    BeforeEach {
        $script:priorLocalAppData = $env:LOCALAPPDATA
        $env:LOCALAPPDATA = $TestDrive
        Mock Start-Transcript {}
        Mock Stop-Transcript {}
    }
    AfterEach { $env:LOCALAPPDATA = $script:priorLocalAppData }
    It 'starts a unique local transcript without requiring verbose mode' {
        $first = Start-AutopilotDiagnostics
        $second = Start-AutopilotDiagnostics
        $first | Should -Not -Be $second
        $first | Should -BeLike (Join-Path $TestDrive 'AutopilotExpress/logs/*.log')
        Should -Invoke Start-Transcript -Times 2 -Exactly -ParameterFilter { $NoClobber -and $ErrorAction -eq 'Stop' }
    }
    It 'retains its single transcript when source fingerprinting fails' {
        Mock Get-FileHash { throw 'Synthetic fingerprint failure' }
        $path = Start-AutopilotDiagnostics -SourcePath 'synthetic-source.ps1'
        $path | Should -BeLike '*.log'
        Should -Invoke Start-Transcript -Times 1 -Exactly
        Should -Invoke Stop-Transcript -Times 0 -Exactly
    }

    It 'closes an owned transcript but never stops an unowned transcript' {
        Complete-AutopilotDiagnostics -Path ''
        Should -Invoke Stop-Transcript -Times 0 -Exactly
        Complete-AutopilotDiagnostics -Path 'synthetic.log'
        Should -Invoke Stop-Transcript -Times 1 -Exactly
    }
    It 'falls back after the first logging location fails' {
        $script:transcriptAttempts = 0
        Mock Start-Transcript { $script:transcriptAttempts++; if ($script:transcriptAttempts -eq 1) { throw 'Synthetic access denied' } }
        $path = Start-AutopilotDiagnostics
        $path | Should -BeLike (Join-Path $env:TEMP 'AutopilotExpress/logs/*.log')
        Should -Invoke Start-Transcript -Times 2 -Exactly
    }
    It 'stops startup if neither logging location works' {
        Mock Start-Transcript { throw 'Synthetic logging failure' }
        { Start-AutopilotDiagnostics } | Should -Throw '*startup stopped before storage or tenant access*'
    }
    It 'does not hide the workflow failure when transcript closure fails' {
        Mock Stop-Transcript { throw 'Synthetic close failure' }
        { try { throw 'Original workflow failure' } finally { Complete-AutopilotDiagnostics -Path 'synthetic.log' } } | Should -Throw 'Original workflow failure'
    }
}

Describe 'Interactive startup reservation recovery' {
    BeforeEach {
        $script:lockRoot = Join-Path $TestDrive ([guid]::NewGuid().Guid)
        $null = New-Item -ItemType Directory -Path $script:lockRoot
        $script:Runtime = @{ IsDemoMode = $true }
        $script:priorRecoveryLocalAppData = $env:LOCALAPPDATA
        $env:LOCALAPPDATA = $TestDrive
        Mock Write-Host {}
        Mock Read-ValidatedInput { return '0' }
    }
    AfterEach { $env:LOCALAPPDATA = $script:priorRecoveryLocalAppData }
    It 'acquires an available store without any recovery prompt' {
        $lock = Request-LocalSessionLock
        $lock.Token | Should -Not -BeNullOrEmpty
        Should -Invoke Read-ValidatedInput -Times 0 -Exactly
        Stop-LocalSessionLock -Lock $lock
    }
    It 'returns cleanly without releasing an active owner or offering recovery' {
        $lock = Start-LocalSessionLock
        $before = (Get-FileHash -LiteralPath $lock.Path).Hash
        Request-LocalSessionLock | Should -BeNullOrEmpty
        (Get-FileHash -LiteralPath $lock.Path).Hash | Should -BeExactly $before
        Should -Invoke Read-ValidatedInput -Times 1 -Exactly -ParameterFilter { $Default -eq '0' -and $Choices -notcontains 'C' }
        Stop-LocalSessionLock -Lock $lock
    }
    It 'recovers a stopped local owner and acquires a fresh token in the same invocation' {
        $path = Join-Path $script:lockRoot 'autopilot-express-demo.session.lock'
        $owner = @{ Token = 'stopped-owner'; Computer = $env:COMPUTERNAME; User = 'Synthetic'; ProcessId = 2147483646; StartedAt = '2026-10-14T09:48:39+08:00' }
        Set-Content -LiteralPath $path -Value ($owner | ConvertTo-Json)
        $before = (Get-FileHash -LiteralPath $path).Hash
        Mock Get-Process { Write-Error -Message 'Synthetic absent owner' -Category ObjectNotFound -ErrorAction Stop }
        $script:recoveryAnswers = [System.Collections.Generic.Queue[string]]::new()
        foreach ($answer in @('c', 'y')) { $script:recoveryAnswers.Enqueue($answer) }
        Mock Read-ValidatedInput { return $script:recoveryAnswers.Dequeue() }
        $lock = Request-LocalSessionLock
        $lock.Token | Should -Not -Be stopped-owner
        (Get-Content -LiteralPath $path -Raw | ConvertFrom-Json).Token | Should -Be $lock.Token
        # BACKUP-POLICY files crash evidence under CrashLocks\<date>\<tenant>; demo locks file under 'demo'.
        $evidence = @(Get-ChildItem -LiteralPath (Join-Path $TestDrive 'PowerShellScriptingNew/AutopilotExpressRecoveryEvidence/CrashLocks') -File -Recurse)
        $evidence.Count | Should -Be 1
        $evidence[0].Directory.Name | Should -Be 'demo'
        (Get-FileHash -LiteralPath $evidence[0].FullName).Hash | Should -BeExactly $before
        Stop-LocalSessionLock -Lock $lock
    }
    It 'inspects a foreign lock without querying the local process with that ID' {
        $path = Join-Path $script:lockRoot 'autopilot-express-demo.session.lock'
        Set-Content -LiteralPath $path -Value (@{ Token = 'foreign-owner'; Computer = 'OTHER-SYNTHETIC-HOST'; User = 'Synthetic'; ProcessId = 1234 } | ConvertTo-Json)
        Mock Get-Process { throw 'Must not inspect a foreign PID locally.' }
        Request-LocalSessionLock | Should -BeNullOrEmpty
        (Get-Content -LiteralPath $path -Raw | ConvertFrom-Json).Token | Should -Be foreign-owner
        Should -Invoke Get-Process -Times 0 -Exactly
    }
    It 'returns cleanly after a permission failure without pretending a lock was acquired' {
        Mock Start-LocalSessionLock { throw 'Synthetic access denied' }
        Request-LocalSessionLock | Should -BeNullOrEmpty
        Should -Invoke Read-ValidatedInput -Times 1 -Exactly -ParameterFilter { $Choices -notcontains 'C' }
    }

    It 'retains the lock after <Scenario> and permits a clean return' -TestCases @(
        @{ Scenario = 'declined confirmation'; Answers = @('C', 'N', '0'); CopyFails = $false; OwnerAppears = $false }
        @{ Scenario = 'evidence-copy failure'; Answers = @('C', 'Y', '0'); CopyFails = $true; OwnerAppears = $false }
        @{ Scenario = 'owner appearing during recovery'; Answers = @('C', 'Y', '0'); CopyFails = $false; OwnerAppears = $true }
    ) {
        param($Scenario, $Answers, $CopyFails, $OwnerAppears)
        $path = Join-Path $script:lockRoot 'autopilot-express-demo.session.lock'
        Set-Content -LiteralPath $path -Value (@{ Token = 'retained-owner'; Computer = $env:COMPUTERNAME; User = 'Synthetic'; ProcessId = 2147483646 } | ConvertTo-Json)
        $before = (Get-FileHash -LiteralPath $path).Hash
        $script:recoveryAnswers = [System.Collections.Generic.Queue[string]]::new()
        foreach ($answer in $Answers) { $script:recoveryAnswers.Enqueue($answer) }
        $script:recoveryOwnerAppears = $OwnerAppears
        $script:recoveryOwnerProbeCount = 0
        Mock Read-ValidatedInput { return $script:recoveryAnswers.Dequeue() }
        Mock Get-Process {
            $script:recoveryOwnerProbeCount++
            if ($script:recoveryOwnerAppears -and $script:recoveryOwnerProbeCount -gt 1) { return @{ Id = 2147483646 } }
            Write-Error -Message 'Synthetic absent owner' -Category ObjectNotFound -ErrorAction Stop
        }
        if ($CopyFails) { Mock Copy-Item { throw 'Synthetic evidence copy unavailable' } }
        { Request-LocalSessionLock } | Should -Not -Throw
        $script:recoveryAnswers.Count | Should -Be 0
        (Get-FileHash -LiteralPath $path).Hash | Should -BeExactly $before
        Should -Invoke Read-ValidatedInput -Times 1 -Exactly -ParameterFilter { $Default -eq 'N' -and $Choices -contains 'Y' }
        if ($Scenario -eq 'declined confirmation') { Should -Invoke Get-Process -Times 2 -Exactly }
    }
}

Describe 'Explicit crashed-lock recovery' {
    BeforeEach {
        $script:recoveryRoot = Join-Path $TestDrive ([guid]::NewGuid().Guid)
        $null = New-Item -ItemType Directory -Path $script:recoveryRoot
        $script:recoveryPath = Join-Path $script:recoveryRoot 'autopilot-express-live.session.lock'
        $script:priorLocalAppData = $env:LOCALAPPDATA
        $env:LOCALAPPDATA = $TestDrive
        $owner = @{ Token = 'stopped-token'; Computer = $env:COMPUTERNAME; User = 'Synthetic'; ProcessId = 2147483646; StartedAt = '2026-10-14T09:48:39+08:00' }
        Set-Content -LiteralPath $script:recoveryPath -Value ($owner | ConvertTo-Json)
        Mock Get-Process { Write-Error -Message 'Synthetic absent owner' -Category ObjectNotFound -ErrorAction Stop }
    }
    AfterEach { $env:LOCALAPPDATA = $script:priorLocalAppData }
    It 'inspects without changing or releasing the reservation' {
        $before = (Get-FileHash -LiteralPath $script:recoveryPath).Hash
        (Invoke-LocalSessionLockRecovery -Path $script:recoveryPath).State | Should -Be 'OwnerProcessStopped'
        (Get-FileHash -LiteralPath $script:recoveryPath).Hash | Should -BeExactly $before
    }
    It 'preserves verified evidence and releases only the explicitly stopped lock' {
        $marker = Join-Path $TestDrive 'records.json.write-in-progress'
        Set-Content -LiteralPath $marker -Value 'Retain this marker'
        $result = Invoke-LocalSessionLockRecovery -Path $script:recoveryPath -Recover -ConfirmStopped -Confirm:$false
        $result.State | Should -Be 'Recovered'
        (Get-FileHash -LiteralPath $result.EvidencePath).Hash | Should -BeExactly $result.SHA256
        Test-Path -LiteralPath $script:recoveryPath | Should -BeFalse
        Get-Content -LiteralPath $marker | Should -Be 'Retain this marker'
    }
    It 'refuses recovery without operator confirmation' {
        { Invoke-LocalSessionLockRecovery -Path $script:recoveryPath -Recover } | Should -Throw '*ConfirmStopped*'
        Test-Path -LiteralPath $script:recoveryPath | Should -BeTrue
    }
    It 'allows read-only inspection of cloud-backed locks but refuses automatic release' {
        Mock Get-Item { return @{ FullName = $script:recoveryPath; PSIsContainer = $false; Attributes = [IO.FileAttributes]::ReparsePoint } }
        (Invoke-LocalSessionLockRecovery -Path $script:recoveryPath).State | Should -Be OwnerProcessStopped
        { Invoke-LocalSessionLockRecovery -Path $script:recoveryPath -Recover -ConfirmStopped } | Should -Throw '*non-reparse-backed*'
        Test-Path -LiteralPath $script:recoveryPath | Should -BeTrue
    }
    It 'refuses a live or reused process ID' {
        Mock Get-Process { return @{ Id = 1234 } }
        { Invoke-LocalSessionLockRecovery -Path $script:recoveryPath -Recover -ConfirmStopped } | Should -Throw '*stopped owner*'
        Test-Path -LiteralPath $script:recoveryPath | Should -BeTrue
    }
    It 'refuses uncertain process state' {
        Mock Get-Process { throw 'Access denied' }
        { Invoke-LocalSessionLockRecovery -Path $script:recoveryPath -Recover -ConfirmStopped } | Should -Throw '*verify owner*'
    }
    It 'identifies a newer process reusing the legacy owner PID and permits guarded recovery' {
        Mock Get-Process { return @{ Id = 2147483646; ProcessName = 'not-the-owner'; Path = 'C:\Synthetic\unrelated.exe'; StartTime = [datetime]'2026-10-14T10:00:00+08:00' } }
        $inspection = Invoke-LocalSessionLockRecovery -Path $script:recoveryPath
        $inspection.State | Should -Be ProcessIdReused
        $inspection.ProcessPath | Should -Be 'C:\Synthetic\unrelated.exe'
        $inspection.CanRecover | Should -BeTrue
        (Invoke-LocalSessionLockRecovery -Path $script:recoveryPath -Recover -ConfirmStopped -Confirm:$false).State | Should -Be Recovered
    }
    It 'identifies an original legacy host and requires it to close without terminating it' {
        Mock Get-Process { return @{ Id = 2147483646; ProcessName = 'pwsh'; Path = 'C:\Synthetic\pwsh.exe'; StartTime = [datetime]'2026-10-14T09:00:00+08:00' } }
        $inspection = Invoke-LocalSessionLockRecovery -Path $script:recoveryPath
        $inspection.CanRecover | Should -BeFalse
        $inspection.ProcessName | Should -Be pwsh
        { Invoke-LocalSessionLockRecovery -Path $script:recoveryPath -Recover -ConfirmStopped -Confirm:$false } | Should -Throw '*stopped owner*'
        Test-Path -LiteralPath $script:recoveryPath | Should -BeTrue
    }
    It 'does not release a foreign-computer lock' {
        $owner = Get-Content -LiteralPath $script:recoveryPath -Raw | ConvertFrom-Json
        $owner.Computer = 'OTHER-SYNTHETIC-COMPUTER'
        Set-Content -LiteralPath $script:recoveryPath -Value ($owner | ConvertTo-Json)
        { Invoke-LocalSessionLockRecovery -Path $script:recoveryPath -Recover -ConfirmStopped } | Should -Throw '*another or unknown computer*'
    }
    It 'honours WhatIf and never treats a checkpoint as a session lock' {
        Invoke-LocalSessionLockRecovery -Path $script:recoveryPath -Recover -ConfirmStopped -WhatIf
        Test-Path -LiteralPath $script:recoveryPath | Should -BeTrue
        { Invoke-LocalSessionLockRecovery -Path (Join-Path $TestDrive 'devices.checkpoint.json') -Recover -ConfirmStopped } | Should -Throw '*exact Autopilot Express*'
    }
    It 'retains the reservation when evidence cannot be copied' {
        Mock Copy-Item { throw 'Synthetic evidence copy failure' }
        { Invoke-LocalSessionLockRecovery -Path $script:recoveryPath -Recover -ConfirmStopped -Confirm:$false } | Should -Throw '*copy failure*'
        Test-Path -LiteralPath $script:recoveryPath | Should -BeTrue
    }
    It 'retains the reservation when its evidence hashes disagree' {
        $script:hashReads = 0
        Mock Get-FileHash { $script:hashReads++; return @{ Hash = if ($script:hashReads -eq 3) { 'changed' } else { 'original' } } }
        { Invoke-LocalSessionLockRecovery -Path $script:recoveryPath -Recover -ConfirmStopped -Confirm:$false } | Should -Throw '*evidence changed*'
        Test-Path -LiteralPath $script:recoveryPath | Should -BeTrue
    }
    It 'rechecks ownership after verifying the evidence copy' {
        $script:processReads = 0
        Mock Get-Process {
            $script:processReads++
            if ($script:processReads -eq 2) { return @{ Id = 1234 } }
            Write-Error -Message 'Synthetic absent owner' -Category ObjectNotFound -ErrorAction Stop
        }
        { Invoke-LocalSessionLockRecovery -Path $script:recoveryPath -Recover -ConfirmStopped -Confirm:$false } | Should -Throw '*process appeared*'
        Test-Path -LiteralPath $script:recoveryPath | Should -BeTrue
    }
    It 'rechecks file contents after the last process inspection' {
        $script:processReads = 0
        Mock Get-Process {
            $script:processReads++
            if ($script:processReads -eq 2) { Set-Content -LiteralPath $script:recoveryPath -Value '{"Token":"replacement-owner"}' }
            Write-Error -Message 'Synthetic absent owner' -Category ObjectNotFound -ErrorAction Stop
        }
        { Invoke-LocalSessionLockRecovery -Path $script:recoveryPath -Recover -ConfirmStopped -Confirm:$false } | Should -Throw '*final recovery check*'
        (Get-Content -LiteralPath $script:recoveryPath -Raw | ConvertFrom-Json).Token | Should -Be 'replacement-owner'
    }
    It 'does not recover malformed ownership <Payload>' -TestCases @(
        @{ Payload = '{invalid' }
        @{ Payload = '{}' }
        @{ Payload = '{"Token":"t","Computer":"host","ProcessId":"not-a-process"}' }
    ) {
        param($Payload)
        Set-Content -LiteralPath $script:recoveryPath -Value $Payload
        { Invoke-LocalSessionLockRecovery -Path $script:recoveryPath -Recover -ConfirmStopped -Confirm:$false } | Should -Throw
        (Get-Content -LiteralPath $script:recoveryPath -Raw).Trim() | Should -BeExactly $Payload
    }
}

Describe 'OS-held reservation lifecycle and saved evidence' {
    BeforeEach {
        $script:lockRoot = Join-Path $TestDrive ([guid]::NewGuid().Guid)
        $null = New-Item -ItemType Directory -Path $script:lockRoot
        $script:Runtime = @{ IsDemoMode = $true }
        $script:priorLeaseLocalAppData = $env:LOCALAPPDATA
        $env:LOCALAPPDATA = $TestDrive
    }
    AfterEach { $env:LOCALAPPDATA = $script:priorLeaseLocalAppData }

    It 'preserves saved work and recovers after <EndState> without relying on PID absence' -TestCases @(
        @{ EndState = 'HostSurvives' }, @{ EndState = 'ProcessTerminates' }
    ) {
        param($EndState)
        foreach ($relative in @('records.json', 'records.json.previous', 'bench.json', 'audit.json', 'session-index.json', 'pending/checkpoint.json', 'records.json.write-in-progress')) {
            $path = Join-Path $script:lockRoot $relative
            $null = New-Item -ItemType Directory -Path (Split-Path -Parent $path) -Force
            Set-Content -LiteralPath $path -Value (@{ RecordId = 'retained-identity'; StartedAt = '2026-10-13T09:00:00+08:00'; DispatchedAt = '2026-10-14T10:00:00+08:00'; DispatchConfirmed = $true; History = @('Submitted', 'Verified'); Path = $relative } | ConvertTo-Json)
        }
        $before = @(Get-LocalSessionRecoveryInventory -DataPath $script:lockRoot)
        $definition = $sourceAst.Find({ param($node) $node -is [System.Management.Automation.Language.FunctionDefinitionAst] -and $node.Name -eq 'Start-LocalSessionLock' }, $true).Extent.Text
        $childBody = @(
            '$ErrorActionPreference = "Stop"'
            ('function Get-DataFolderPath {{ return ''{0}'' }}' -f $script:lockRoot.Replace("'", "''"))
            '$script:Runtime = @{ IsDemoMode = $true }'
            $definition
            '$lock = Start-LocalSessionLock; [Console]::Out.WriteLine("RESERVED"); [Console]::Out.Flush()'
            '$command = [Console]::In.ReadLine(); if ($command -eq "ABORT") { try { throw "Synthetic interrupted script" } catch {} finally { $lock.Handle.Dispose() }; [Console]::Out.WriteLine("HOST_SURVIVED"); [Console]::Out.Flush(); [void][Console]::In.ReadLine() }'
        ) -join [Environment]::NewLine
        $startInfo = [Diagnostics.ProcessStartInfo]::new()
        $hostName = if ($PSVersionTable.PSEdition -eq 'Desktop') { 'powershell.exe' } else { 'pwsh.exe' }
        $startInfo.FileName = Join-Path $PSHOME $hostName
        $startInfo.Arguments = '-NoProfile -NonInteractive -EncodedCommand {0}' -f [Convert]::ToBase64String([Text.Encoding]::Unicode.GetBytes($childBody))
        $startInfo.UseShellExecute = $false
        $startInfo.CreateNoWindow = $true
        $startInfo.RedirectStandardOutput = $true
        $startInfo.RedirectStandardError = $true
        $startInfo.RedirectStandardInput = $true
        $child = [Diagnostics.Process]::new()
        $child.StartInfo = $startInfo
        $replacement = $null
        try {
            $child.Start() | Should -BeTrue
            $ready = $child.StandardOutput.ReadLineAsync()
            $ready.Wait(15000) | Should -BeTrue
            $ready.Result | Should -Be RESERVED
            $lockPath = Join-Path $script:lockRoot 'autopilot-express-demo.session.lock'
            { Start-LocalSessionLock } | Should -Throw '*Cannot reserve local*'
            (Invoke-LocalSessionLockRecovery -Path $lockPath).CanRecover | Should -BeFalse
            { Invoke-LocalSessionLockRecovery -Path $lockPath -Recover -ConfirmStopped -Confirm:$false } | Should -Throw '*OS reservation*'
            if ($EndState -eq 'HostSurvives') {
                $child.StandardInput.WriteLine('ABORT')
                $survived = $child.StandardOutput.ReadLineAsync()
                $survived.Wait(15000) | Should -BeTrue
                $survived.Result | Should -Be HOST_SURVIVED
                $child.HasExited | Should -BeFalse
            }
            else { $child.Kill(); $child.WaitForExit(15000) | Should -BeTrue }
            $inspection = Invoke-LocalSessionLockRecovery -Path $lockPath
            $inspection.State | Should -Be OSReservationReleased
            $inspection.CanRecover | Should -BeTrue
            $result = Invoke-LocalSessionLockRecovery -Path $lockPath -Recover -ConfirmStopped -Confirm:$false
            $result.State | Should -Be Recovered
            $replacement = Start-LocalSessionLock
            $manifest = Get-Content -LiteralPath (Join-Path $result.SessionBackupPath 'manifest.json') -Raw | ConvertFrom-Json
            $manifest.Status | Should -Be Verified
            $manifest.Files.Count | Should -Be ($before.Count + 1)
            foreach ($file in $before) {
                (Get-FileHash -LiteralPath $file.SourcePath).Hash | Should -BeExactly $file.SHA256
                $copy = Join-Path $result.SessionBackupPath ('files/{0}' -f $file.RelativePath)
                (Get-FileHash -LiteralPath $copy).Hash | Should -BeExactly $file.SHA256
            }
            if ($EndState -eq 'HostSurvives') { $child.HasExited | Should -BeFalse }
            Stop-LocalSessionLock -Lock $replacement
        }
        finally {
            if ($replacement -and $replacement.Handle) { $replacement.Handle.Dispose() }
            if (-not $child.HasExited) { $child.Kill(); [void]$child.WaitForExit(15000) }
            $child.Dispose()
        }
    }

    It 'does not use inaccessible process metadata as authority when the version-two OS lease is free' {
        $lock = Start-LocalSessionLock
        $lock.Handle.Dispose()
        Mock Get-Process { throw 'Synthetic denied process metadata' }
        $inspection = Invoke-LocalSessionLockRecovery -Path $lock.Path
        $inspection.State | Should -Be OSReservationReleased
        $inspection.CanRecover | Should -BeTrue
        (Invoke-LocalSessionLockRecovery -Path $lock.Path -Recover -ConfirmStopped -Confirm:$false).State | Should -Be Recovered
    }

    It 'still blocks acquisition if readable metadata is removed while the OS handle is held' {
        $lock = Start-LocalSessionLock
        try {
            Remove-Item -LiteralPath $lock.Path
            { Start-LocalSessionLock } | Should -Throw '*Cannot reserve local*'
            Test-Path -LiteralPath $lock.Path | Should -BeFalse
        }
        finally { $lock.Handle.Dispose() }
    }

    It 'leaves every file unchanged and keeps the reservation after interrupted snapshot copying' {
        $lock = Start-LocalSessionLock
        $lock.Handle.Dispose()
        Set-Content -LiteralPath (Join-Path $script:lockRoot 'records.json') -Value '{"RecordId":"retained","DispatchConfirmed":true}'
        $before = @(Get-LocalSessionRecoveryInventory -DataPath $script:lockRoot)
        Mock Copy-Item { throw 'Synthetic interrupted session backup' }
        { Invoke-LocalSessionLockRecovery -Path $lock.Path -Recover -ConfirmStopped -Confirm:$false } | Should -Throw '*interrupted session backup*'
        $after = @(Get-LocalSessionRecoveryInventory -DataPath $script:lockRoot)
        @(Compare-Object $before $after -Property RelativePath, Length, SHA256).Count | Should -Be 0
        Test-Path -LiteralPath $lock.Path | Should -BeTrue
        $lease = [IO.File]::Open(($lock.Path + '.lease'), [IO.FileMode]::Open, [IO.FileAccess]::ReadWrite, [IO.FileShare]::None)
        $lease.Dispose()
    }
}

Describe 'Exclusive local session reservation' {
    BeforeEach {
        $script:Runtime = @{ IsDemoMode = $true }
        $script:lockRoot = Join-Path $TestDrive ([guid]::NewGuid().Guid)
        New-Item -ItemType Directory -Path $script:lockRoot | Out-Null
    }

    It 'creates ownership evidence and releases its own lock' {
        $lock = Start-LocalSessionLock
        $owner = Get-Content -LiteralPath $lock.Path -Raw | ConvertFrom-Json
        $owner.Token | Should -Be $lock.Token
        $owner.ProcessId | Should -Be $PID
        $owner.StartedAt | Should -Not -BeNullOrEmpty
        Stop-LocalSessionLock -Lock $lock
        Test-Path -LiteralPath $lock.Path | Should -BeFalse
    }

    It 'rejects another session without overwriting its evidence' {
        $lock = Start-LocalSessionLock
        $original = Get-Content -LiteralPath $lock.Path -Raw
        { Start-LocalSessionLock } | Should -Throw '*Cannot reserve local*'
        Get-Content -LiteralPath $lock.Path -Raw | Should -Be $original
        Stop-LocalSessionLock -Lock $lock
    }

    It 'allows a new session after the original session releases' {
        $firstLock = Start-LocalSessionLock
        Stop-LocalSessionLock -Lock $firstLock
        $secondLock = Start-LocalSessionLock
        $secondLock.Token | Should -Not -Be $firstLock.Token
        Stop-LocalSessionLock -Lock $secondLock
    }

    It 'isolates Demo and Live reservations' {
        $demoLock = Start-LocalSessionLock
        $script:Runtime.IsDemoMode = $false
        $liveLock = Start-LocalSessionLock
        $liveLock.Path | Should -Not -Be $demoLock.Path
        Stop-LocalSessionLock -Lock $demoLock
        Stop-LocalSessionLock -Lock $liveLock
    }

    It 'does not remove a lock with changed ownership' {
        $lock = Start-LocalSessionLock
        Set-Content -LiteralPath $lock.Path -Value '{"Token":"replacement"}'
        { Stop-LocalSessionLock -Lock $lock } | Should -Throw '*ownership changed*'
        Test-Path -LiteralPath $lock.Path | Should -BeTrue
    }

    It 'fails closed for an unreadable ownership payload' {
        $lock = Start-LocalSessionLock
        Set-Content -LiteralPath $lock.Path -Value '{invalid-json'
        { Stop-LocalSessionLock -Lock $lock } | Should -Throw
        Test-Path -LiteralPath $lock.Path | Should -BeTrue
    }

    It 'never expires or steals an abandoned lock' {
        $path = Join-Path $script:lockRoot 'autopilot-express-demo.session.lock'
        New-Item -ItemType File -Path $path -Value '{"StartedAt":"2000-01-01T00:00:00Z"}' | Out-Null
        { Start-LocalSessionLock } | Should -Throw '*Cannot reserve local*'
        Test-Path -LiteralPath $path | Should -BeTrue
    }

    It 'releases on a workflow exception through finally' {
        $lock = Start-LocalSessionLock
        { try { throw 'Synthetic workflow failure' } finally { Stop-LocalSessionLock -Lock $lock } } | Should -Throw 'Synthetic workflow failure'
        Test-Path -LiteralPath $lock.Path | Should -BeFalse
    }

    It 'honours the reservation from another constrained process' {
        $lock = Start-LocalSessionLock
        $definition = $sourceAst.Find({ param($node) $node -is [System.Management.Automation.Language.FunctionDefinitionAst] -and $node.Name -eq 'Start-LocalSessionLock' }, $true).Extent.Text
        $body = @(
            ('function Get-DataFolderPath {{ return ''{0}'' }}' -f $script:lockRoot.Replace("'", "''"))
            '$script:Runtime = @{ IsDemoMode = $true }'
            $definition
            'try { $null = Start-LocalSessionLock; throw "UNEXPECTED_ACQUISITION" } catch { if ($_.Exception.Message -notlike "Cannot reserve local*") { throw }; Write-Output "CONTENTION_PASS" }'
        ) -join [Environment]::NewLine
        $bootstrap = '$body = [Text.Encoding]::Unicode.GetString([Convert]::FromBase64String(''{0}'')); $ExecutionContext.SessionState.LanguageMode = ''ConstrainedLanguage''; Invoke-Expression $body' -f [Convert]::ToBase64String([Text.Encoding]::Unicode.GetBytes($body))
        try {
            $result = Invoke-ConstrainedSessionLockProbe -Bootstrap $bootstrap
            $result.ExitCode | Should -Be 0 -Because $result.StandardError
            $result.StandardOutput | Should -Match 'CONTENTION_PASS'
            (Get-Content -LiteralPath $lock.Path -Raw | ConvertFrom-Json).Token | Should -Be $lock.Token
        }
        finally { Stop-LocalSessionLock -Lock $lock }
    }

    It 'refuses a weaker reservation from a constrained process without changing policy or files' {
        $definitions = foreach ($functionName in @('Start-LocalSessionLock', 'Stop-LocalSessionLock', 'Assert-DeviceRecordIdentity')) {
            $sourceAst.Find({ param($node) $node -is [System.Management.Automation.Language.FunctionDefinitionAst] -and $node.Name -eq $functionName }, $true).Extent.Text
        }
        $body = @(
            ('function Get-DataFolderPath {{ return ''{0}'' }}' -f $script:lockRoot.Replace("'", "''"))
            '$script:Runtime = @{ IsDemoMode = $true }'
            ($definitions -join [Environment]::NewLine)
            'try { $null = Start-LocalSessionLock; throw "UNEXPECTED_ACQUISITION" } catch { if ($_.Exception.Message -notlike "*approved FullLanguage host*") { throw }; Write-Output "CONSTRAINED_REFUSAL_PASS" }'
        ) -join [Environment]::NewLine
        $bootstrap = '$body = [Text.Encoding]::Unicode.GetString([Convert]::FromBase64String(''{0}'')); $ExecutionContext.SessionState.LanguageMode = ''ConstrainedLanguage''; Invoke-Expression $body' -f [Convert]::ToBase64String([Text.Encoding]::Unicode.GetBytes($body))
        $result = Invoke-ConstrainedSessionLockProbe -Bootstrap $bootstrap
        $result.ExitCode | Should -Be 0 -Because $result.StandardError
        $result.StandardOutput | Should -Match 'CONSTRAINED_REFUSAL_PASS'
        @(Get-ChildItem -LiteralPath $script:lockRoot).Count | Should -Be 0
    }
}