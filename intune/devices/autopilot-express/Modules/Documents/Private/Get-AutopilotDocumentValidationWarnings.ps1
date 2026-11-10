<#
.SYNOPSIS
    Reject new SDK errors; report only the exact approved legacy drawing exceptions.
.DESCRIPTION
    The three exact checklist semantic ID errors were approved on 24 October.
    The 25 October approval also permits those same errors after full structural
    revalidation of edited checklists. No additional exception is allowed.
.FILECREATED
    2026-10-24
.FILELASTUPDATED
    2026-10-24
#>
function Get-AutopilotDocumentValidationWarnings {
    <#
    .SYNOPSIS
        Validate a source or populated package against the same narrow policy.
    .PARAMETER Document
        Child-owned SDK document; never activates objects or launches Office.
    .PARAMETER TemplateSHA256
        Fingerprint already checked against the actual source bytes.
    .PARAMETER RevalidatedChecklist
        Fixed reviewed checklist undergoing full edited-template revalidation.
    .OUTPUTS
        No warnings for valid packages; only the exact approved set otherwise.
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory)][ValidateNotNull()][object]$Document,
        [Parameter(Mandatory)][ValidatePattern('^[A-F0-9]{64}$')][string]$TemplateSHA256,
        [switch]$RevalidatedChecklist
    )
    $validator = [DocumentFormat.OpenXml.Validation.OpenXmlValidator]::new([DocumentFormat.OpenXml.FileFormatVersions]::Office2019)
    $errors = @($validator.Validate($Document))
    if (-not $errors.Count) { return }
    $allowed = @()
    $reviewed = Get-AutopilotDocumentTemplateProfile -DocumentType Checklist
    if ($TemplateSHA256 -ceq $reviewed.TemplateSHA256 -or $RevalidatedChecklist) { $allowed = @($reviewed.ValidationExceptions) }
    if ($errors.Count -ne $allowed.Count) { throw ('DOCX validation error count differs from the approved template baseline: {0} actual, {1} allowed.' -f $errors.Count, $allowed.Count) }
    foreach ($errorItem in $errors) {
        $matchingExceptions = @($allowed | Where-Object {
            $_.Id -ceq $errorItem.Id -and $_.Part -ceq [string]$errorItem.Part.Uri -and $_.Path -ceq $errorItem.Path.XPath -and $_.Description -ceq $errorItem.Description
        })
        if ($matchingExceptions.Count -ne 1) { throw ('Unapproved DOCX validation error: {0}' -f $errorItem.Description) }
        'Preserved source-template warning: {0} ({1})' -f $errorItem.Description, $errorItem.Path.XPath
    }
}