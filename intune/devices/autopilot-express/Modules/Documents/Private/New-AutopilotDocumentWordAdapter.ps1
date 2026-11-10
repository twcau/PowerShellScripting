<#
.SYNOPSIS
    Create an inert adapter; only its Start operation may launch desktop Word.
.DESCRIPTION
    Intended solely for the fixed Desktop STA child. Never attaches through the ROT,
    activates embedded objects, updates links, prints or terminates another instance.
.DOCUMENTATION
    https://learn.microsoft.com/office/vba/api/word.documents.opennorepairdialog
    https://learn.microsoft.com/office/vba/api/word.application.automationsecurity
    https://learn.microsoft.com/office/vba/api/word.document.exportasfixedformat
.FILECREATED
    2026-10-24
.FILELASTUPDATED
    2026-10-24
#>
function New-AutopilotDocumentWordAdapter {
    <#
    .SYNOPSIS
        Keep COM references and prior settings inside one owned worker instance.
    .OUTPUTS
        Start/Open/Export/Close operations; no side effects until Start is invoked.
    #>
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'None')]
    [OutputType([Collections.Specialized.OrderedDictionary])]
    param()
    if (-not $PSCmdlet.ShouldProcess('Inert Word operation dictionary', 'Create adapter without launching Word')) { return }
    $state = @{ Application = $null; Documents = $null; Document = $null; Options = $null; Owned = $false; Prior = @{}; Identity = $null }
    return [ordered]@{
        Start         = {
            if ($state.Owned) { return $state.Identity }
            if ($PSVersionTable.PSEdition -ne 'Desktop' -or [Threading.Thread]::CurrentThread.ApartmentState -ne 'STA' -or -not [Environment]::UserInteractive -or [Diagnostics.Process]::GetCurrentProcess().SessionId -eq 0) { throw 'Word export requires an interactive Desktop STA worker, not a service.' }
            if (-not ('AutopilotDocumentNative.WindowProcess' -as [type])) {
                Add-Type -TypeDefinition @'
using System;
using System.Runtime.InteropServices;
namespace AutopilotDocumentNative {
    public static class WindowProcess {
        [DllImport("user32.dll", SetLastError = true)]
        public static extern uint GetWindowThreadProcessId(IntPtr window, out uint processId);
    }
}
'@ -ErrorAction Stop
            }
            $existing = @(Get-Process -Name WINWORD -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Id)
            $notBefore = [DateTime]::UtcNow.AddSeconds(-2)
            $state.Application = New-Object -ComObject Word.Application -ErrorAction Stop
            $wordProcessId = [uint32]0
            $windowHandle = [long]$state.Application.Hwnd
            if (-not $windowHandle) {
                $state.Prior = @{ AutomationSecurity = $state.Application.AutomationSecurity; DisplayAlerts = $state.Application.DisplayAlerts; Visible = $state.Application.Visible }
                $state.Application.AutomationSecurity = 3
                $state.Documents = $state.Application.Documents
                $state.Document = $state.Documents.Add()
                $bootstrapWindow = $state.Document.ActiveWindow
                try { $windowHandle = [long]$bootstrapWindow.Hwnd }
                finally { if ([Runtime.InteropServices.Marshal]::IsComObject($bootstrapWindow)) { $null = [Runtime.InteropServices.Marshal]::FinalReleaseComObject($bootstrapWindow) } }
            }
            $threadId = [AutopilotDocumentNative.WindowProcess]::GetWindowThreadProcessId([IntPtr]::new($windowHandle), [ref]$wordProcessId)
            if (-not $threadId -or -not $wordProcessId -or $wordProcessId -in $existing) { throw ('Word process ownership is unproven: HWND={0}; thread={1}; PID={2}; previously running={3}; Win32Error={4}. No document was opened.' -f $windowHandle, $threadId, $wordProcessId, ($wordProcessId -in $existing), [Runtime.InteropServices.Marshal]::GetLastWin32Error()) }
            $process = [Diagnostics.Process]::GetProcessById([int]$wordProcessId)
            try {
                if ($process.ProcessName -ine 'WINWORD' -or $process.SessionId -ne [Diagnostics.Process]::GetCurrentProcess().SessionId -or $process.StartTime.ToUniversalTime() -lt $notBefore) { throw 'Word process identity differs from the newly created worker-owned instance.' }
                $state.Owned = $true
                if ($null -ne $state.Document) {
                    $state.Document.Close(0)
                    $null = [Runtime.InteropServices.Marshal]::FinalReleaseComObject($state.Document)
                    $state.Document = $null
                }
                $state.Identity = [ordered]@{ WordProcessId = $process.Id; StartTimeUtcTicks = $process.StartTime.ToUniversalTime().Ticks; ProcessName = $process.ProcessName }
                return $state.Identity
            }
            finally { $process.Dispose() }
        }.GetNewClosure()
        Open          = {
            param([string]$InputPath)
            if (-not $state.Owned) { throw 'Refusing to open a document in unowned Word.' }
            $state.Options = $state.Application.Options
            if (-not $state.Prior.ContainsKey('UpdateLinksAtOpen')) {
                $priorApplication = if ($state.Prior.Count) { $state.Prior } else { @{ AutomationSecurity = $state.Application.AutomationSecurity; DisplayAlerts = $state.Application.DisplayAlerts; Visible = $state.Application.Visible } }
                $state.Prior = @{
                    AutomationSecurity = $priorApplication.AutomationSecurity; DisplayAlerts = $priorApplication.DisplayAlerts; Visible = $priorApplication.Visible
                    UpdateLinksAtOpen = $state.Options.UpdateLinksAtOpen; UpdateFieldsAtPrint = $state.Options.UpdateFieldsAtPrint; UpdateLinksAtPrint = $state.Options.UpdateLinksAtPrint
                    CheckSpellingAsYouType = $state.Options.CheckSpellingAsYouType; CheckGrammarAsYouType = $state.Options.CheckGrammarAsYouType
                }
            }
            $state.Application.AutomationSecurity = 3; $state.Application.DisplayAlerts = 0; $state.Application.Visible = $false
            $state.Options.UpdateLinksAtOpen = $false; $state.Options.UpdateFieldsAtPrint = $false; $state.Options.UpdateLinksAtPrint = $false
            $state.Options.CheckSpellingAsYouType = $false; $state.Options.CheckGrammarAsYouType = $false
            $state.Documents = $state.Application.Documents
            $missing = [Type]::Missing
            $openArguments = [object[]]@($InputPath, $false, $true, $false, $missing, $missing, $false, $missing, $missing, $missing, $missing, $false, $false, $missing, $true, $missing)
            $state.Document = $state.Documents.GetType().InvokeMember('OpenNoRepairDialog', ([Reflection.BindingFlags]::InvokeMethod -bor [Reflection.BindingFlags]::OptionalParamBinding), $null, $state.Documents, $openArguments)
            if ($null -eq $state.Document -or -not $state.Document.ReadOnly) { throw 'Word did not open the owned copy read-only.' }
        }.GetNewClosure()
        Export        = {
            param([string]$PdfPath, [ValidateRange(0, 10000)][int]$ExpectedPageCount = 0)
            if (-not $state.Owned -or $null -eq $state.Document) { throw 'No owned Word document is available for PDF export.' }
            if ($ExpectedPageCount) {
                $state.Document.Repaginate()
                $pageCount = [int]$state.Document.ComputeStatistics(2)
                if ($pageCount -ne $ExpectedPageCount) { throw ('Document pagination failed: Word reports {0} pages; expected {1}. No PDF was exported; retain the DOCX for review.' -f $pageCount, $ExpectedPageCount) }
            }
            $state.Document.ExportAsFixedFormat($PdfPath, 17, $false, 0, 0, 1, 1, 0, $false, $true, 1, $true, $true, $false)
        }.GetNewClosure()
        CloseDocument = {
            if ($null -ne $state.Document) {
                $state.Document.Close(0)
                if ([Runtime.InteropServices.Marshal]::IsComObject($state.Document)) { $null = [Runtime.InteropServices.Marshal]::FinalReleaseComObject($state.Document) }
                $state.Document = $null
            }
        }.GetNewClosure()
        Close         = {
            $failures = [Collections.Generic.List[string]]::new()
            if ($null -ne $state.Application -and -not $state.Owned) { $failures.Add('Unproven Word ownership: its instance was not closed.') }
            if ($state.Owned) {
                try { if ($null -ne $state.Document) { $state.Document.Close(0) } } catch { $failures.Add('Owned document close failed.') }
                try {
                    if ($state.Prior.Count) {
                        if ($null -ne $state.Options) {
                            foreach ($name in @('UpdateLinksAtOpen', 'UpdateFieldsAtPrint', 'UpdateLinksAtPrint', 'CheckSpellingAsYouType', 'CheckGrammarAsYouType')) { $state.Options.$name = $state.Prior[$name] }
                        }
                        foreach ($name in @('AutomationSecurity', 'DisplayAlerts', 'Visible')) { $state.Application.$name = $state.Prior[$name] }
                    }
                }
                catch { $failures.Add('Owned Word settings could not be restored.') }
                try { $saveChanges = 0; $state.Application.Quit([ref]$saveChanges) } catch { $failures.Add(('Owned Word quit failed: {0}' -f $_.Exception.Message)) }
            }
            foreach ($name in @('Document', 'Documents', 'Options', 'Application')) {
                if ($null -ne $state[$name]) {
                    try { if ([Runtime.InteropServices.Marshal]::IsComObject($state[$name])) { $null = [Runtime.InteropServices.Marshal]::FinalReleaseComObject($state[$name]) } }
                    catch { $failures.Add('Owned COM reference release failed.') }
                    $state[$name] = $null
                }
            }
            $state.Owned = $false
            $state.Identity = $null
            if ($failures.Count) { throw ($failures -join ' ') }
        }.GetNewClosure()
    }
}