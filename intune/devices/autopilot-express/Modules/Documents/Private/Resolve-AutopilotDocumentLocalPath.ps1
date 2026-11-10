<#
.SYNOPSIS
    Validate local dependency paths and reject redirected ancestors.
.DESCRIPTION
    PowerShell 5.1 or later. No writes; every existing ancestor must be a normal
    directory, not a reparse point. This is not protection against local admins.
.FILECREATED
    2026-10-24
.FILELASTUPDATED
    2026-10-24
#>
function Resolve-AutopilotDocumentLocalPath {
    <#
    .SYNOPSIS
        Return a canonical local directory path or throw before dependency access.
    .PARAMETER Path
        Absolute local Windows dependency directory; no UNC, providers or ADS.
    .OUTPUTS
        Canonical path. No directory is created.
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param([Parameter(Mandatory)][ValidateNotNullOrEmpty()][string]$Path)
    if ($Path -notmatch '^[A-Za-z]:[\\/]' -or $Path.Substring(2).Contains(':') -or $Path.IndexOfAny([IO.Path]::GetInvalidPathChars()) -ge 0 -or $Path -match '[*?]') { throw 'Dependencies require an absolute local filesystem directory.' }
    $resolved = [IO.Path]::GetFullPath($Path)
    if ($resolved.TrimEnd([IO.Path]::DirectorySeparatorChar).Length -le 2) { throw 'A drive root is not a feature-owned dependency directory.' }
    $ancestor = $resolved
    while ($ancestor) {
        if (Test-Path -LiteralPath $ancestor) {
            $item = Get-Item -LiteralPath $ancestor -Force -ErrorAction Stop
            if (-not $item.PSIsContainer -or ($item.Attributes -band [IO.FileAttributes]::ReparsePoint)) { throw 'Dependency directories must not traverse files or reparse points.' }
        }
        $ancestor = Split-Path -Parent $ancestor
    }
    return $resolved.TrimEnd([IO.Path]::DirectorySeparatorChar)
}