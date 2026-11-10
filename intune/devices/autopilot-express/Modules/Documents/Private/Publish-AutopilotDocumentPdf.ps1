<#
.SYNOPSIS
    Publish a verified PDF with the approved two-name collision policy.
.DESCRIPTION
    Local platform-only publication. Copies to an exclusive pending file, flushes
    and verifies it, then atomically moves without overwriting either final name.
    The source PDF is retained for document-only retry and diagnostic review.
.FILECREATED
    2026-10-24
.FILELASTUPDATED
    2026-10-24
#>
function Publish-AutopilotDocumentPdf {
    <#
    .SYNOPSIS
        Reserve only the base name or the document-type suffix, never a counter.
    .PARAMETER Job
        Detached job containing the approved output directory and naming settings.
    .PARAMETER DocumentType
        BirthCertificate or Checklist, used for the single allowed collision suffix.
    .PARAMETER SourcePath
        Existing verified local PDF. No rendering, printing or network access occurs.
    .OUTPUTS
        Published PDF path, length and SHA-256 after a no-overwrite move.
    #>
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'None')]
    [OutputType([Collections.Specialized.OrderedDictionary])]
    param(
        [Parameter(Mandatory)][Collections.IDictionary]$Job,
        [Parameter(Mandatory)][ValidateSet('BirthCertificate','Checklist')][string]$DocumentType,
        [Parameter(Mandatory)][ValidateNotNullOrEmpty()][string]$SourcePath
    )
    $sourceInfo = Get-AutopilotDocumentPdfInfo -Path $SourcePath
    $directory = Resolve-AutopilotDocumentLocalPath -Path $Job['OutputRoot']
    if (-not $PSCmdlet.ShouldProcess($directory, 'Publish verified PDF without replacing any final file')) { return $null }
    $null = [IO.Directory]::CreateDirectory($directory)
    $occupied = @([IO.Directory]::EnumerateFileSystemEntries($directory) | ForEach-Object { [IO.Path]::GetFileName($_) })
    $name = Get-AutopilotDocumentOutputName -Job $Job -DocumentType $DocumentType -OccupiedFileNames $occupied
    $pending = Join-Path $directory ('.pdf-pending-{0}' -f [guid]::NewGuid().ToString('N'))
    [IO.File]::Copy($SourcePath, $pending, $false)
    $stream = [IO.File]::Open($pending, [IO.FileMode]::Open, [IO.FileAccess]::ReadWrite, [IO.FileShare]::None)
    $sha = [Security.Cryptography.SHA256]::Create()
    try {
        $stream.Flush($true)
        $hash = [BitConverter]::ToString($sha.ComputeHash($stream)).Replace('-', '')
        if ($hash -cne $sourceInfo.SHA256 -or $stream.Length -ne $sourceInfo.Length) { throw 'Pending PDF differs from its verified source.' }
    }
    finally { $sha.Dispose(); $stream.Dispose() }
    for ($attempt = 0; $attempt -lt 2; $attempt++) {
        $destination = Join-Path $directory $name
        try {
            [IO.File]::Move($pending, $destination)
            return [ordered]@{ Path = $destination; SHA256 = $hash; Length = $sourceInfo.Length }
        }
        catch [IO.IOException] {
            if (-not (Test-Path -LiteralPath $destination) -or $attempt -eq 1) { throw }
            $occupied += $name
            $name = Get-AutopilotDocumentOutputName -Job $Job -DocumentType $DocumentType -OccupiedFileNames $occupied
        }
    }
}