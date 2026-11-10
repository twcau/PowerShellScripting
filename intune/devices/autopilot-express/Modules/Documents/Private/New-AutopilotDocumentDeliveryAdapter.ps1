<#
.SYNOPSIS
    Construct inert Windows PDF association/default-printer delivery operations.
.DESCRIPTION
    Uses registered shell verbs for the generated PDF, never Word printing.
    Construction does not probe or launch anything. Probe is bounded/local; actual
    shell delivery runs only in the supervised document worker, not the input loop.
.FILECREATED
    2026-10-24
.FILELASTUPDATED
    2026-10-24
#>
function New-AutopilotDocumentDeliveryAdapter {
    <#
    .SYNOPSIS
        Return private Probe/Open/Print operations without starting a viewer.
    .OUTPUTS
        Adapter dictionary. A successful shell request is not physical print proof.
    #>
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'None')]
    [OutputType([hashtable])]
    param()
    if (-not $PSCmdlet.ShouldProcess('Inert PDF shell operations', 'Construct')) { return $null }
    return @{
        Probe = {
            param([string]$Path, [bool]$IncludePrinter = $true)
            $start = [Diagnostics.ProcessStartInfo]::new($Path)
            $verbs = @($start.Verbs)
            $printer = ''
            try {
                if ($IncludePrinter -and 'print' -in $verbs) {
                $defaults = @(Get-CimInstance -ClassName Win32_Printer -Filter 'Default = TRUE' -OperationTimeoutSec 5 -ErrorAction Stop)
                if ($defaults.Count -eq 1) { $printer = [string]$defaults[0].Name }
                }
            }
            catch { $printer = '' }
            return @{ CanOpen = ('open' -in $verbs); CanPrint = ('print' -in $verbs -and -not [string]::IsNullOrWhiteSpace($printer)); DefaultPrinter = $printer }
        }
        Open = {
            param([string]$Path)
            $start = [Diagnostics.ProcessStartInfo]::new($Path)
            $start.UseShellExecute = $true; $start.Verb = 'open'
            $process = [Diagnostics.Process]::Start($start)
            if ($null -ne $process) { $process.Dispose() }
        }
        Print = {
            param([string]$Path)
            $start = [Diagnostics.ProcessStartInfo]::new($Path)
            $start.UseShellExecute = $true; $start.Verb = 'print'; $start.WindowStyle = [Diagnostics.ProcessWindowStyle]::Hidden
            $process = [Diagnostics.Process]::Start($start)
            if ($null -ne $process) { $process.Dispose() }
        }
    }
}