<#
.SYNOPSIS
    Bind readable and legacy document-job directory names to their GUID identity.
.FILECREATED
    2026-10-25
.FILELASTUPDATED
    2026-10-25
#>
function Test-AutopilotDocumentJobDirectory {
    <#
    .SYNOPSIS
        Recognise only a GUID leaf or the fixed device-labelled job-name grammar.
    .PARAMETER Directory
        Explicit local job directory; ancestors must not be reparse points.
    .PARAMETER JobId
        Immutable detached job identity, never inferred from a human label.
    .OUTPUTS
        Boolean identity check without creating files.
    #>
    [CmdletBinding()]
    [OutputType([bool])]
    param([Parameter(Mandatory)][string]$Directory, [Parameter(Mandatory)][guid]$JobId)
    $leaf = [IO.Path]::GetFileName((Resolve-AutopilotDocumentLocalPath -Path $Directory))
    return $leaf -ceq $JobId.ToString('D') -or $leaf -cmatch ('^Serial-[A-Za-z0-9._-]{{1,24}}_CI-[A-Za-z0-9._-]{{1,24}}_{0}$' -f [regex]::Escape($JobId.ToString('D')))
}