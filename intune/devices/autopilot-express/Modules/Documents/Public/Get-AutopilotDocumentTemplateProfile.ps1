<#
.SYNOPSIS
    Return fingerprint-bound review mappings for the current supplied DOCX templates.
.DESCRIPTION
    Pure metadata; never reads/mutates a template or approves Live certification.
    Placement examples are explicitly mapped, not interpreted as field aliases.
.FILECREATED
    2026-10-24
.FILELASTUPDATED
    2026-10-24
#>
function Get-AutopilotDocumentTemplateProfile {
    <#
    .SYNOPSIS
        Return detached review bindings; OUTPUT-CERTIFICATE remains held.
    .PARAMETER DocumentType
        Independent BirthCertificate or Checklist template profile.
    .OUTPUTS
        Fresh unapproved profile; unknown/manual actions cannot tick.
    #>
    [CmdletBinding()]
    [OutputType([Collections.Specialized.OrderedDictionary])]
    param([Parameter(Mandatory)][ValidateSet('BirthCertificate', 'Checklist')][string]$DocumentType)
    $bindings = [Collections.Generic.List[object]]::new(); $part = '/word/document.xml'
    if ($DocumentType -eq 'BirthCertificate') {
        $hash = '08A2C505B8E97FAF351F5894F02431BE55296BDD401D923D44628725466557D0'
        $bindings.Add(@{ Part = $part; Kind = 'CertificationLabel'; ParagraphIndex = 0; ExpectedText = 'Digital and Technology - Device Birth Certificate'; ReviewLabelInFooter = $true })
        foreach ($spec in @(
            @(2, '{ci}', 'ConfigurationItem'), @(5, '{serial}', 'SerialNumberOrServiceTag'),
            @(24, '{intune_host_name}', 'IntuneHostName'), @(27, '{intune_wired_mac_address}', 'EthernetMacAddress'), @(41, '{dispatch_user}', 'TechnicianName')
        )) { $bindings.Add(@{ Part = $part; Kind = 'Paragraph'; ParagraphIndex = $spec[0]; ExpectedText = $spec[1]; Field = $spec[2]; Required = ($spec[2] -in @('SerialNumberOrServiceTag','ConfigurationItem','TechnicianName')) }) }
        foreach ($spec in @(@('{sitename}', 'SiteName'), @('{assigned_user_username}', 'AssignedUserName'), @('{assigned_user_first_and_last_name}', 'AssignedUserFullName'))) {
            $bindings.Add(@{ Part = $part; Kind = 'Literal'; Marker = $spec[0]; Field = $spec[1]; Required = $false; ExpectedCount = 1 })
        }
        $bindings.Add(@{ Part = $part; Kind = 'DispatchDate'; ParagraphIndex = 49; ExpectedText = '{dispatch_date}' })
        $bindings.Add(@{ Part = $part; Kind = 'OverrideDisclosure'; ParagraphIndex = 35; ExpectedText = '{If dispatch_override_reason used}Incomplete steps overridden for following reason:{dispatch_override_reason}{End if dispatch_override_reason used)' })
        foreach ($spec in @(
            @(64, ('2 {0} 4' -f [char]0x2013), @('A','B','C'), $false), @(67, '5', @('D'), $false),
            @(73, ('6 {0} 12' -f [char]0x2013), @('E','F','G'), $false),
            @(80, ('13 {0} 15' -f [char]0x2013), @('H','I','J','K'), $true),
            @(95, ('16 {0} 20' -f [char]0x2013), @('L','M','N'), $true),
            @(98, '21', @('O'), $false), @(101, '22', @(), $true), @(104, '23-25', @(), $true)
        )) {
            $trigger = if ($spec[2].Count) { $spec[2][-1] } else { '' }
            $bindings.Add(@{ Part = $part; Kind = 'GroupResult'; ParagraphIndex = $spec[0]; ExpectedText = ''; GuideStepText = $spec[1]; StepIds = $spec[2]; TriggerStepId = $trigger; IncludesUntracked = $spec[3] })
        }
        foreach ($spec in @(@(3, '[ci]', 'ConfigurationItem'), @(6, '[serial]', 'SerialNumberOrServiceTag'), @(25, '[intune_host_name]', 'IntuneHostName'), @(28, '[intune_wired_mac_address]', 'EthernetMacAddress'))) {
            $bindings.Add(@{ Part = $part; Kind = 'Barcode'; ParagraphIndex = $spec[0]; ExpectedText = $spec[1]; Field = $spec[2]; Required = $false; WidthTwips = 4000; HeightTwips = 600; ReviewedInsetsTwips = @{ top = 0; bottom = 0; left = 108; right = 108 }; LineSlackTwips = 160 })
        }
    }
    else {
        $hash = '1B0DE794E1F0DC42D8EC49D05BD932876EB5086318FF37913761353E0521C494'
        $bindings.Add(@{ Part = $part; Kind = 'CertificationLabel'; ParagraphIndex = 0; ExpectedText = ('8Digital and Technology {0} Autopilot Checklist {0} New Device' -f [char]0x2013); ReviewLabelInFooter = $true })
        $bindings.Add(@{ Part = $part; Kind = 'TextControl'; Tag = 'Technician Name'; Field = 'TechnicianName'; Required = $true })
        $bindings.Add(@{ Part = $part; Kind = 'DispatchDate'; ParagraphIndex = 4; ExpectedText = '{dispatch_date}' })
        foreach ($spec in @(
            @('1479591474', @(), $true), @('1621038395', @('A','B'), $false), @('418905284', @('C'), $false),
            @('-137504094', @('D'), $false), @('709748985', @('E'), $false), @('1319152802', @('F'), $true),
            @('1571313608', @('G'), $false), @('1997613357', @('H','I'), $false), @('-995875195', @('J'), $false),
            @('-1265367737', @('K','L'), $true), @('-610284133', @('M'), $true), @('1946873788', @('N'), $true),
            @('-1405527525', @(), $true), @('-1352877669', @('O'), $false), @('-474691344', @(), $true),
            @('-2066178218', @(), $true), @('-551235883', @(), $true), @('1156957450', @(), $true)
        )) { $bindings.Add(@{ Part = $part; Kind = 'CheckBox'; ControlId = $spec[0]; Tag = ''; StepIds = $spec[1]; IncludesUntracked = $spec[2] }) }
    }
    $exceptions = @()
    if ($DocumentType -eq 'Checklist') {
        $exceptions = @(
            @('Picture 1', '/w:document[1]/w:body[1]/w:tbl[3]/w:tr[7]/w:tc[1]/w:p[1]/w:r[2]/mc:AlternateContent[1]/mc:Fallback[1]/w:pict[1]/v:group[1]/v:shape[2]'),
            @('drawing', '/w:document[1]/w:body[1]/w:tbl[3]/w:tr[2]/w:tc[1]/w:p[1]/w:r[1]/mc:AlternateContent[1]/mc:Fallback[1]/w:pict[1]/v:group[1]/v:shape[2]'),
            @('_x0000_t75', '/w:document[1]/w:body[1]/w:tbl[2]/w:tr[6]/w:tc[1]/w:p[1]/w:r[2]/w:object[1]/v:shapetype[1]')
        ) | ForEach-Object { [ordered]@{ Id = 'Sem_UniqueAttributeValue'; Part = $part; Path = $_[1]; Description = "Attribute 'id' should have unique value. Its current value '{0}' duplicates with others." -f $_[0] } }
    }
    return [ordered]@{
        SchemaVersion = 1; ProfileId = '{0}-v1.5-review-2' -f $DocumentType; DocumentType = $DocumentType; ApprovedForLive = $false
        TemplateSHA256 = $hash; Bindings = $bindings.ToArray(); ValidationExceptions = @($exceptions)
        RequiredFields = @('SerialNumberOrServiceTag','ConfigurationItem','TechnicianName')
        AssignedUserFields = @('AssignedUserName','AssignedUserFullName')
    }
}