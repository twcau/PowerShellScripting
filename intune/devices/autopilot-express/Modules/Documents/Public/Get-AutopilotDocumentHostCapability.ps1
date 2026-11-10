<#
.SYNOPSIS
    Detect the common worker and Word registration without starting Office.
.DESCRIPTION
    Reads only installed framework/COM registration and the Windows worker path.
    Registration is not activation, licensing or a successful PDF export probe.
.FILECREATED
    2026-10-24
.FILELASTUPDATED
    2026-10-24
#>
function Get-AutopilotDocumentHostCapability {
    <#
    .SYNOPSIS
        Report local prerequisites without loading document DLLs or Word COM.
    .OUTPUTS
        Ordered dictionary. Errors become diagnostics; missing Office never installs it.
    #>
    [CmdletBinding()]
    [OutputType([System.Collections.Specialized.OrderedDictionary])]
    param()
    $worker = Join-Path ([Environment]::GetFolderPath('Windows')) 'System32/WindowsPowerShell/v1.0/powershell.exe'
    if ([Environment]::Is64BitOperatingSystem -and -not [Environment]::Is64BitProcess) {
        $worker = Join-Path ([Environment]::GetFolderPath('Windows')) 'Sysnative/WindowsPowerShell/v1.0/powershell.exe'
    }
    $release = 0; $wordRegistered = $false
    $diagnostics = [System.Collections.Generic.List[string]]::new()
    foreach ($view in @([Microsoft.Win32.RegistryView]::Registry64, [Microsoft.Win32.RegistryView]::Registry32)) {
        $machine = $null; $framework = $null; $classes = $null; $word = $null; $server = $null
        try {
            $machine = [Microsoft.Win32.RegistryKey]::OpenBaseKey([Microsoft.Win32.RegistryHive]::LocalMachine, $view)
            $framework = $machine.OpenSubKey('SOFTWARE\Microsoft\NET Framework Setup\NDP\v4\Full')
            if ($null -ne $framework) { $release = [Math]::Max($release, [int]$framework.GetValue('Release', 0)) }
            $classes = [Microsoft.Win32.RegistryKey]::OpenBaseKey([Microsoft.Win32.RegistryHive]::ClassesRoot, $view)
            $word = $classes.OpenSubKey('Word.Application\CLSID')
            if ($null -ne $word) {
                $classId = [guid]::Empty
                if ([guid]::TryParse([string]$word.GetValue(''), [ref]$classId)) {
                    $server = $classes.OpenSubKey(('CLSID\{{{0}}}\LocalServer32' -f $classId.ToString('D')))
                    if ($null -ne $server -and -not [string]::IsNullOrWhiteSpace([string]$server.GetValue(''))) { $wordRegistered = $true }
                }
            }
        }
        catch { $diagnostics.Add(('Cannot read {0} registration; check local registry access.' -f $view)) }
        finally { foreach ($key in @($server, $word, $classes, $framework, $machine)) { if ($null -ne $key) { $key.Dispose() } } }
    }
    return [ordered]@{
        WorkerExecutable = $worker; FrameworkRelease = $release
        WorkerAvailable = ((Test-Path -LiteralPath $worker -PathType Leaf) -and $release -ge 528040)
        WordRegistrationDetected = $wordRegistered; WordActivationVerified = $false
        Diagnostics = $diagnostics.ToArray()
    }
}