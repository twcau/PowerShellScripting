<#
.SYNOPSIS
    Populate a fingerprint-bound DOCX copy using reviewed structural bindings.
.DESCRIPTION
    Child-only SDK engine. No Word, Graph, PDF, printing or original-template writes.
    Template approval is independent of the explicit testing-phase guard setting.
.FILECREATED
    2026-10-24
.FILELASTUPDATED
    2026-10-24
#>
function New-AutopilotDocumentCopy {
    <#
    .SYNOPSIS
        Apply literal, paragraph, native-control and barcode bindings to an owned copy.
    .PARAMETER Request
        Schema-one dictionary with Job, Profile, TemplatePath, OutputPath and ReviewOnly.
        Profile bindings explicitly identify part, kind, expected count and field/steps.
        EnforceDocumentGuards=false permits unapproved mappings without changing their approval.
        Absent enforcement retains guarded behaviour for older population requests.
    .PARAMETER PrepareOnly
        Validate and cache immutable source metadata in this isolated worker without
        populating, publishing or supplying device completion evidence.
    .OUTPUTS
        Structured receipt only after SDK validation; failed copies remain unpublished
        with a .pending GUID suffix for diagnosis. Existing outputs are never replaced.
    #>
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'None')]
    [OutputType([System.Collections.Specialized.OrderedDictionary])]
    param(
        [Parameter(Mandatory)][ValidateNotNull()][Collections.IDictionary]$Request,
        [switch]$PrepareOnly
    )
    $templateProfile = $Request['Profile']; $job = $Request['Job']
    if ($templateProfile -isnot [Collections.IDictionary] -or $job -isnot [Collections.IDictionary] -or $job['Fields'] -isnot [Collections.IDictionary] -or $job['Steps'] -isnot [Collections.IDictionary]) { throw 'Document request requires detached job/profile dictionaries.' }
    if ($Request['SchemaVersion'] -ne 1 -or $templateProfile['SchemaVersion'] -ne 1 -or $job['SchemaVersion'] -ne 1 -or $templateProfile['ApprovedForLive'] -isnot [bool] -or $Request['ReviewOnly'] -isnot [bool]) { throw 'Invalid structural document request schema.' }
    if ($templateProfile['TemplateSHA256'] -cnotmatch '^[A-F0-9]{64}$' -or [string]::IsNullOrWhiteSpace($templateProfile['ProfileId']) -or @($templateProfile['Bindings']).Count -notin 1..256) { throw 'Invalid document profile identity, fingerprint or binding count.' }
    if ($Request.Contains('EnforceDocumentGuards') -and $Request['EnforceDocumentGuards'] -isnot [bool]) { throw 'Document guard enforcement must be Boolean.' }
    $enforceGuards = -not $Request.Contains('EnforceDocumentGuards') -or $Request['EnforceDocumentGuards']
    if ($enforceGuards -and -not $templateProfile['ApprovedForLive'] -and -not $Request['ReviewOnly']) { throw 'Template mappings are not approved; only explicitly labelled review output is allowed.' }
    if ($job['Mode'] -cnotin @('Live', 'Demo') -or $job['IsAdministrativeOverride'] -isnot [bool] -or ($job['IsAdministrativeOverride'] -and [string]::IsNullOrWhiteSpace($job['OverrideReason']))) { throw 'Invalid document mode or override disclosure.' }
    $requiredFields = @($templateProfile['RequiredFields'] | Where-Object { $_ })
    if (@($templateProfile['AssignedUserFields'] | Where-Object { $_ }).Count) {
        if ($job['AssignedUserRequired'] -isnot [bool]) { throw 'Assigned-user requirement must be explicitly declared by the job.' }
        if ($job['AssignedUserRequired']) { $requiredFields += @($templateProfile['AssignedUserFields']) }
    }
    foreach ($field in $requiredFields) {
        if ($job['Fields'][$field] -isnot [string] -or [string]::IsNullOrWhiteSpace($job['Fields'][$field])) { throw ('Required document field is missing: {0}' -f $field) }
    }
    foreach ($binding in $templateProfile['Bindings']) {
        if ($binding -isnot [Collections.IDictionary] -or $binding['Kind'] -cnotin @('Literal','Paragraph','DispatchDate','OverrideDisclosure','CertificationLabel','TextControl','DateControl','CheckBox','GroupResult','Barcode')) { throw 'Unknown or malformed document binding.' }
        if ($binding['Kind'] -in @('Paragraph','Literal','TextControl','Barcode') -and $binding['Required'] -isnot [bool]) { throw 'Text/barcode bindings require an explicit Boolean Required flag.' }
        if ($binding['Kind'] -in @('CheckBox','GroupResult') -and $binding['IncludesUntracked'] -isnot [bool]) { throw 'Group bindings require an explicit untracked-work flag.' }
        if ($binding['Kind'] -eq 'GroupResult' -and @($binding['StepIds']).Count -gt 0 -and $binding['TriggerStepId'] -cne $binding['StepIds'][-1]) { throw 'Group trigger must be the last mapped action, not a substitute for the whole group.' }
    }
    $template = [IO.Path]::GetFullPath([string]$Request['TemplatePath']); $output = [IO.Path]::GetFullPath([string]$Request['OutputPath'])
    $null = Resolve-AutopilotDocumentLocalPath -Path (Split-Path -Parent $template)
    $null = Resolve-AutopilotDocumentLocalPath -Path (Split-Path -Parent $output)
    if ($template -ieq $output -or [IO.Path]::GetExtension($output) -ine '.docx' -or (Test-Path -LiteralPath $output)) { throw 'Document output must be a new local DOCX, never the template or an existing output.' }
    $inputFile = Get-Item -LiteralPath $template -Force -ErrorAction Stop
    if ($inputFile.Length -gt 33554432 -or ($inputFile.Attributes -band [IO.FileAttributes]::ReparsePoint)) { throw 'Invalid template file/size.' }
    if (@($templateProfile['Bindings'] | Where-Object { $_['Kind'] -eq 'CertificationLabel' }).Count -ne 1) { throw 'Every profile requires exactly one visible certification/review label binding.' }
    if (-not $PSCmdlet.ShouldProcess($output, 'Populate a new document copy; no Word or printing')) { return [ordered]@{ Status = 'WhatIf'; OutputPath = ''; Replacements = 0 } }
    $memory = [IO.MemoryStream]::new(); $document = $null; $pending = ''; $source = $null; $sha = $null
    $phaseClock = [Diagnostics.Stopwatch]::StartNew()
    $timings = [ordered]@{ SourceValidationMilliseconds = 0L; BindingMilliseconds = 0L; PopulationMilliseconds = 0L; OutputValidationMilliseconds = 0L; PreservationMilliseconds = 0L }
    try {
        $source = [IO.File]::Open($template, [IO.FileMode]::Open, [IO.FileAccess]::Read, ([IO.FileShare]::ReadWrite -bor [IO.FileShare]::Delete))
        $source.CopyTo($memory); $source.Dispose(); $source = $null; $memory.Position = 0
        $sha = [Security.Cryptography.SHA256]::Create()
        $actualTemplateSHA256 = [BitConverter]::ToString($sha.ComputeHash($memory)).Replace('-', '')
        $templateChanged = $actualTemplateSHA256 -cne $templateProfile['TemplateSHA256']
        $knownProfile = $templateProfile['ProfileId'] -cin @('BirthCertificate-v1.5-review-2','Checklist-v1.5-review-2')
        if ($templateChanged -and -not $knownProfile) { throw 'Template fingerprint differs from the reviewed mapping version.' }
        $policyHash = [BitConverter]::ToString($sha.ComputeHash([Text.Encoding]::UTF8.GetBytes(($templateProfile | ConvertTo-Json -Depth 20 -Compress)))).Replace('-', '')
        if (-not (Get-Variable -Name DocumentTemplateCache -Scope Script -ErrorAction SilentlyContinue)) { $script:DocumentTemplateCache = @{} }
        $cached = if ($knownProfile) { $script:DocumentTemplateCache[$templateProfile['ProfileId']] } else { $null }
        if ($null -ne $cached -and ($cached.TemplateHash -cne $actualTemplateSHA256 -or $cached.PolicyHash -cne $policyHash)) { $cached = $null }
        $memory.Position = 0
        $zip = [IO.Compression.ZipArchive]::new($memory, [IO.Compression.ZipArchiveMode]::Read, $true)
        try {
            $total = 0L; $names = @{}
            foreach ($entry in $zip.Entries) {
                $total += $entry.Length
                if ($entry.Length -gt 33554432 -or $total -gt 134217728 -or $names.ContainsKey($entry.FullName) -or $entry.FullName -match '(^/|\\|(^|/)\.\.(/|$)|vbaProject|afchunk)') { throw 'Unsafe, duplicate or excessive template package content.' }
                $names[$entry.FullName] = $true
            }
        }
        finally { $zip.Dispose() }
        $preservedContent = if ($null -ne $cached) { $cached.PreservedContent } else { Get-AutopilotDocumentPreservedContent -Stream $memory }
        $memory.Position = 0
        $document = [DocumentFormat.OpenXml.Packaging.WordprocessingDocument]::Open($memory, $true)
        $revalidatedChecklist = $templateProfile['ProfileId'] -ceq 'Checklist-v1.5-review-2'
        $validationWarnings = @(if ($null -ne $cached) { $cached.Warnings } else { Get-AutopilotDocumentValidationWarnings -Document $document -TemplateSHA256 $actualTemplateSHA256 -RevalidatedChecklist:$revalidatedChecklist })
        $parts = [ordered]@{ '/word/document.xml' = $document.MainDocumentPart }
        foreach ($part in @($document.MainDocumentPart.HeaderParts) + @($document.MainDocumentPart.FooterParts)) { $parts[$part.Uri.ToString()] = $part }
        $queue = [Collections.Generic.Queue[object]]::new(); $visited = @{}
        if ($null -eq $cached) { $queue.Enqueue($document) }
        while ($queue.Count) {
            $container = $queue.Dequeue()
            if (@($container.ExternalRelationships).Count) { throw 'External linked content is not supported; hyperlinks are preserved but never fetched.' }
            foreach ($pair in $container.Parts) {
                $part = $pair.OpenXmlPart
                if ($part.RelationshipType -match 'aFChunk|attachedTemplate|vbaProject') { throw 'Active or linked package content is not supported.' }
                if (-not $visited.ContainsKey($part.Uri.ToString())) { $visited[$part.Uri.ToString()] = $true; $queue.Enqueue($part) }
            }
        }
        $timings.SourceValidationMilliseconds = $phaseClock.ElapsedMilliseconds
        $phaseClock.Restart()
        $effectiveProfile = $templateProfile
        if ($null -ne $cached) {
            $effectiveProfile = @{}
            foreach ($key in $templateProfile.Keys) { $effectiveProfile[$key] = $templateProfile[$key] }
            $effectiveProfile['Bindings'] = $cached.Bindings
        }
        $bindingPlan = Get-AutopilotDocumentTemplateBindings -Parts $parts -TemplateProfile $effectiveProfile -Changed:($templateChanged -and $null -eq $cached)
        if ($knownProfile) { $script:DocumentTemplateCache[$templateProfile['ProfileId']] = @{ TemplateHash = $actualTemplateSHA256; PolicyHash = $policyHash; PreservedContent = $preservedContent; Warnings = $validationWarnings; Bindings = $bindingPlan.Bindings } }
        if ($PrepareOnly) {
            $barcodeBinding = $bindingPlan.Bindings | Where-Object { $_['Kind'] -eq 'Barcode' } | Select-Object -First 1
            if ($null -ne $barcodeBinding) {
                $partName = [string]$barcodeBinding['Part']
                Add-AutopilotDocumentBarcode -Paragraph $bindingPlan.StoryParagraphs[$partName][[int]$barcodeBinding['ParagraphIndex']] -Part $parts[$partName] -Payload 'PREP' -Binding $barcodeBinding -DrawingId $bindingPlan.NextDrawingId
            }
            return [ordered]@{ Status = 'Prepared'; TemplateSHA256 = $actualTemplateSHA256; ValidationWarnings = $validationWarnings }
        }
        $bindings = $bindingPlan.Bindings
        $storyParagraphs = $bindingPlan.StoryParagraphs; $storyControls = $bindingPlan.StoryControls
        $count = 0; $drawingId = $bindingPlan.NextDrawingId
        $omissions = [Collections.Generic.List[object]]::new()
        $timings.BindingMilliseconds = $phaseClock.ElapsedMilliseconds
        $phaseClock.Restart()
        $literalPlans = [ordered]@{}; $literalTargets = @{}; $explicitTargets = @{}
        foreach ($binding in $bindings | Where-Object { $_['Kind'] -eq 'Literal' }) {
            $partName = [string]$binding['Part']; $marker = $binding['Marker']; $field = $binding['Field']
            if (-not $parts.Contains($partName) -or $marker -isnot [string] -or -not $marker.Length -or $binding['ExpectedCount'] -lt 1 -or -not $job['Fields'].Contains($field) -or $job['Fields'][$field] -isnot [string]) { throw 'Invalid literal story, marker, cardinality or canonical field.' }
            $value = $job['Fields'][$field]
            if ($binding['Required'] -and [string]::IsNullOrWhiteSpace($value)) { throw 'Required literal document field is missing.' }
            if (-not $literalPlans.Contains($partName)) { $literalPlans[$partName] = @{ Replacements = [Collections.Generic.Dictionary[string,object]]::new([StringComparer]::Ordinal); Expected = 0 } }
            if ($literalPlans[$partName].Replacements.ContainsKey($marker)) { throw 'A literal marker may be mapped only once per story.' }
            $literalPlans[$partName].Replacements.Add($marker, $value)
            $matched = 0
            foreach ($paragraph in $storyParagraphs[$partName]) {
                if ($paragraph.InnerText.IndexOf($marker, [StringComparison]::Ordinal) -lt 0) { continue }
                $clone = $paragraph.CloneNode($true)
                $hits = Set-AutopilotDocumentParagraphText -Paragraph $clone -Replacements @{ $marker = $value }
                foreach ($hyperlink in $clone.ChildElements | Where-Object LocalName -EQ 'hyperlink') { $hits += Set-AutopilotDocumentParagraphText -Paragraph $hyperlink -Replacements @{ $marker = $value } }
                if ($hits) { $literalTargets[[Runtime.CompilerServices.RuntimeHelpers]::GetHashCode($paragraph)] = $true }
                $matched += $hits
            }
            if ($matched -ne $binding['ExpectedCount']) { throw 'Literal binding cardinality differs from the reviewed profile.' }
            $literalPlans[$partName].Expected += $matched
        }
        foreach ($binding in $bindings) {
            $partName = [string]$binding['Part']
            if (-not $parts.Contains($partName)) { throw 'Mapped document story is missing.' }
            $part = $parts[$partName]
            $kind = [string]$binding['Kind']; $value = ''
            if ($kind -eq 'Literal') { continue }
            switch ($kind) {
                { $_ -in @('DispatchDate','DateControl') } { $value = [DateTimeOffset]::Parse($job['DispatchedAt'], [Globalization.CultureInfo]::InvariantCulture).ToString('dd/MM/yyyy', [Globalization.CultureInfo]::InvariantCulture) }
                'OverrideDisclosure' { if ($job['IsAdministrativeOverride']) { $value = 'Incomplete steps overridden: {0}' -f $job['OverrideReason'] } }
                'CertificationLabel' {
                    $value = [string]$binding['ExpectedText']
                }
                'CheckBox' { }
                'GroupResult' { }
                default {
                    if (-not $job['Fields'].Contains($binding['Field']) -or $job['Fields'][$binding['Field']] -isnot [string]) { throw 'Unknown/non-text canonical document field.' }
                    $value = $job['Fields'][$binding['Field']]
                    if ($binding['Required'] -and [string]::IsNullOrWhiteSpace($value)) { throw ('Required document field is missing: {0}' -f $binding['Field']) }
                    if ($value -match '[\x00-\x08\x0B\x0C\x0E-\x1F\r\n]') { throw 'Document field contains unsupported control characters.' }
                }
            }
            $eligible = $false
            if ($kind -in @('CheckBox','GroupResult')) {
                $eligible = $job['Mode'] -eq 'Live' -and -not $binding['IncludesUntracked'] -and @($binding['StepIds']).Count -gt 0
                foreach ($step in $binding['StepIds']) {
                    if (-not $job['Steps'].Contains($step) -or $job['Steps'][$step]['TickEligible'] -isnot [bool] -or -not $job['Steps'][$step]['TickEligible']) { $eligible = $false }
                }
                if ($kind -eq 'GroupResult' -and $eligible) { $value = 'Y' }
            }
            $paragraphs = $storyParagraphs[$partName]
            if ($kind -in @('TextControl', 'DateControl', 'CheckBox')) {
                $selectorKey = if ($binding['Tag']) { 'tag:{0}' -f $binding['Tag'] } else { 'id:{0}' -f $binding['ControlId'] }
                $lookup = $storyControls[$partName]
                $controls = @(if ($lookup.ContainsKey($selectorKey)) { $lookup[$selectorKey].ToArray() })
                if ($controls.Count -ne 1) { throw 'Native control mapping is missing or ambiguous.' }
                $identity = [Runtime.CompilerServices.RuntimeHelpers]::GetHashCode($controls[0])
                if ($explicitTargets.ContainsKey($identity)) { throw 'Duplicate native-control binding.' }
                $explicitTargets[$identity] = $true
                if ($kind -eq 'CheckBox') {
                    Set-AutopilotDocumentControl -Control $controls[0] -Checked $eligible
                }
                elseif ($kind -eq 'DateControl') { Set-AutopilotDocumentControl -Control $controls[0] -Text $value -DateValue $job['DispatchedAt'] }
                else { Set-AutopilotDocumentControl -Control $controls[0] -Text $value }
                $count++; continue
            }
            $paragraphIndex = [int]$binding['ParagraphIndex']
            if ($paragraphIndex -lt 0 -or $paragraphIndex -ge $paragraphs.Count) { throw ('Mapped paragraph {0} is outside story {1}.' -f $paragraphIndex, $partName) }
            if ($paragraphs[$paragraphIndex].InnerText -cne $binding['ExpectedText']) { throw ('Paragraph binding differs from the fingerprinted template structure: {0}, {1}, index {2}, expected length {3}, actual length {4}.' -f $partName, $kind, $paragraphIndex, ([string]$binding['ExpectedText']).Length, $paragraphs[$paragraphIndex].InnerText.Length) }
            $paragraph = $paragraphs[$paragraphIndex]
            $identity = [Runtime.CompilerServices.RuntimeHelpers]::GetHashCode($paragraph)
            if ($literalTargets.ContainsKey($identity) -or $explicitTargets.ContainsKey($identity)) { throw 'Overlapping paragraph/literal bindings are not supported.' }
            $explicitTargets[$identity] = $true
            if ($kind -eq 'Barcode') {
                $omission = ''
                if ([string]::IsNullOrEmpty($value)) { $omission = 'No authoritative value is available.' }
                else {
                    try {
                        Add-AutopilotDocumentBarcode -Paragraph $paragraph -Part $part -Payload $value -Binding $binding -DrawingId $drawingId
                        $drawingId++
                    }
                    catch {
                        if ($_.FullyQualifiedErrorId -notlike 'AutopilotBarcodeDoesNotFit,*') { throw }
                        $omission = $_.Exception.Message
                    }
                }
                if ($omission) {
                    $removed = Set-AutopilotDocumentParagraphText -Paragraph $paragraph -Replacements @{ $binding['ExpectedText'] = '' }
                    if ($removed -ne 1) { throw 'Cannot safely clear the omitted barcode placement.' }
                    $omissions.Add([ordered]@{ Field = $binding['Field']; Part = $partName; ParagraphIndex = $paragraphIndex; Reason = $omission })
                }
            }
            elseif ($kind -eq 'OverrideDisclosure') {
                if (@($paragraph.Descendants() | Where-Object { $_.LocalName -in @('drawing','pict','sdt','fldChar','instrText','tab','hyperlink') }).Count) { throw 'Override disclosure contains unsupported mixed content.' }
                $texts = @($paragraph.Descendants() | Where-Object { $_.LocalName -eq 't' -and $_.NamespaceUri -eq 'http://schemas.openxmlformats.org/wordprocessingml/2006/main' })
                if (-not $texts.Count) { throw 'Override disclosure has no mapped text.' }
                foreach ($text in $texts) { $text.Text = '' }
                $texts[0].Text = $value; $texts[0].Space = [DocumentFormat.OpenXml.SpaceProcessingModeValues]::Preserve
            }
            elseif ($kind -in @('Paragraph', 'DispatchDate', 'CertificationLabel', 'GroupResult')) {
                if ($kind -eq 'GroupResult') {
                    if ($paragraph.Parent.LocalName -ne 'tc' -or $paragraph.Parent.Parent.LocalName -ne 'tr') { throw 'Group result is not a direct table-cell paragraph.' }
                    $cells = @($paragraph.Parent.Parent.ChildElements | Where-Object LocalName -EQ 'tc')
                    if ($cells.Count -ne 3 -or -not [object]::ReferenceEquals($cells[2], $paragraph.Parent) -or $cells[0].InnerText -cne $binding['GuideStepText']) { throw 'Group result row differs from its reviewed guide-step label.' }
                    if (-not $binding['CompletionMarker'] -and @($paragraph.ChildElements | Where-Object LocalName -NE 'pPr').Count) { throw 'Group result must target an empty paragraph without fields or drawings.' }
                }
                if ($binding['ExpectedText']) {
                    $replaced = Set-AutopilotDocumentParagraphText -Paragraph $paragraph -Replacements @{ $binding['ExpectedText'] = $value }
                    if ($replaced -ne 1) { throw 'Paragraph mapping crosses unsupported fields, drawings or controls.' }
                }
                elseif ($value.Length) {
                    $run = [DocumentFormat.OpenXml.Wordprocessing.Run]::new(); $text = [DocumentFormat.OpenXml.Wordprocessing.Text]::new($value)
                    $text.Space = [DocumentFormat.OpenXml.SpaceProcessingModeValues]::Preserve; $run.Append([DocumentFormat.OpenXml.OpenXmlElement[]](,$text)); $paragraph.Append([DocumentFormat.OpenXml.OpenXmlElement[]](,$run))
                }
                if ($kind -eq 'CertificationLabel') {
                    $labels = @()
                    if ($Request['ReviewOnly']) { $labels += 'DRAFT - TEMPLATE MAPPINGS NOT APPROVED' }
                    if ($job['Mode'] -eq 'Demo') { $labels += 'DEMO - NOT LIVE CERTIFICATION' }
                    if ($labels.Count) {
                        if ($binding['ReviewLabelInFooter']) {
                            $labels = @()
                            if ($Request['ReviewOnly']) { $labels += 'DRAFT - NOT APPROVED' }
                            if ($job['Mode'] -eq 'Demo') { $labels += 'DEMO - NOT LIVE' }
                        }
                        $labelRun = [DocumentFormat.OpenXml.Wordprocessing.Run]::new()
                        $labelProperties = [DocumentFormat.OpenXml.Wordprocessing.RunProperties]::new()
                        $labelSize = if ($binding['ReviewLabelInFooter']) { '12' } else { '16' }
                        $labelProperties.FontSize = [DocumentFormat.OpenXml.Wordprocessing.FontSize]::new(); $labelProperties.FontSize.Val = $labelSize
                        $labelProperties.FontSizeComplexScript = [DocumentFormat.OpenXml.Wordprocessing.FontSizeComplexScript]::new(); $labelProperties.FontSizeComplexScript.Val = $labelSize
                        $labelRun.Append([DocumentFormat.OpenXml.OpenXmlElement[]](,$labelProperties))
                        if (-not $binding['ReviewLabelInFooter']) { $labelRun.Append([DocumentFormat.OpenXml.OpenXmlElement[]](,[DocumentFormat.OpenXml.Wordprocessing.Break]::new())) }
                        $labelRun.Append([DocumentFormat.OpenXml.OpenXmlElement[]](,[DocumentFormat.OpenXml.Wordprocessing.Text]::new(($labels -join ' - '))))
                        if ($binding['ReviewLabelInFooter']) {
                            $footers = @($parts.Values | Where-Object { $_ -is [DocumentFormat.OpenXml.Packaging.FooterPart] })
                            if (-not $footers.Count) { throw 'Review label requires an existing footer.' }
                            foreach ($footer in $footers) {
                                $rows = @($footer.RootElement.Descendants() | Where-Object LocalName -EQ 'tr')
                                $footerRun = $labelRun.CloneNode($true)
                                if ($rows.Count) {
                                    $cells = @($rows[0].ChildElements | Where-Object LocalName -EQ 'tc')
                                    $footerParagraph = @($cells[-1].ChildElements | Where-Object LocalName -EQ 'p')[0]
                                    if ($footerParagraph.InnerText.Length) { throw 'Review footer table cell must be empty.' }
                                }
                                else {
                                    $footerParagraph = @($footer.RootElement.ChildElements | Where-Object LocalName -EQ 'p')[-1]
                                    $footerRun.InsertAt([DocumentFormat.OpenXml.Wordprocessing.TabChar]::new(), 1) | Out-Null
                                    $footerRun.InsertAt([DocumentFormat.OpenXml.Wordprocessing.TabChar]::new(), 2) | Out-Null
                                }
                                if ($null -eq $footerParagraph) { throw 'Review footer has no existing paragraph.' }
                                $footerParagraph.Append([DocumentFormat.OpenXml.OpenXmlElement[]](,$footerRun))
                            }
                        }
                        else { $paragraph.Append([DocumentFormat.OpenXml.OpenXmlElement[]](,$labelRun)) }
                    }
                }
            }
            else { throw 'Unsupported structural document binding kind.' }
            $count++
        }
        foreach ($partName in $literalPlans.Keys) {
            $matched = 0
            foreach ($paragraph in $storyParagraphs[$partName]) {
                if (-not $literalTargets.ContainsKey([Runtime.CompilerServices.RuntimeHelpers]::GetHashCode($paragraph))) { continue }
                $matched += Set-AutopilotDocumentParagraphText -Paragraph $paragraph -Replacements $literalPlans[$partName].Replacements
                foreach ($hyperlink in $paragraph.ChildElements | Where-Object LocalName -EQ 'hyperlink') { $matched += Set-AutopilotDocumentParagraphText -Paragraph $hyperlink -Replacements $literalPlans[$partName].Replacements }
            }
            if ($matched -ne $literalPlans[$partName].Expected) { throw 'Literal target changed during structural population.' }
            $count += $matched
        }
        foreach ($marker in $bindingPlan.ClearMarkers) {
            if ((Set-AutopilotDocumentParagraphText -Paragraph $marker.Paragraph -Replacements @{ $marker.Marker = '' }) -ne 1) { throw 'Completion marker crosses unsupported fields or controls.' }
        }
        $timings.PopulationMilliseconds = $phaseClock.ElapsedMilliseconds
        $phaseClock.Restart()
        $validationWarnings = @(Get-AutopilotDocumentValidationWarnings -Document $document -TemplateSHA256 $actualTemplateSHA256 -RevalidatedChecklist:$revalidatedChecklist)
        foreach ($part in $parts.Values) { $part.RootElement.Save() }
        $document.Dispose(); $document = $null
        $timings.OutputValidationMilliseconds = $phaseClock.ElapsedMilliseconds
        $phaseClock.Restart()
        $afterContent = Get-AutopilotDocumentPreservedContent -Stream $memory
        foreach ($name in $preservedContent.Assets.Keys) {
            if (-not $afterContent.Assets.Contains($name) -or $afterContent.Assets[$name] -cne $preservedContent.Assets[$name]) { throw 'Existing embedded object or image bytes changed; output was not published.' }
        }
        if (($preservedContent.Relationships | ConvertTo-Json -Compress) -cne ($afterContent.Relationships | ConvertTo-Json -Compress) -or ($preservedContent.Objects | ConvertTo-Json -Compress) -cne ($afterContent.Objects | ConvertTo-Json -Compress)) { throw 'Existing embedded object metadata or relationships changed; output was not published.' }
        $pending = '{0}.pending-{1}' -f $output, [guid]::NewGuid().ToString('N')
        $file = [IO.File]::Open($pending, [IO.FileMode]::CreateNew, [IO.FileAccess]::Write, [IO.FileShare]::None)
        try { $bytes = $memory.ToArray(); $file.Write($bytes, 0, $bytes.Length); $file.Flush($true) } finally { $file.Dispose() }
        [IO.File]::Move($pending, $output)
        $timings.PreservationMilliseconds = $phaseClock.ElapsedMilliseconds
        return [ordered]@{ Status = 'Populated'; OutputPath = $output; Replacements = $count; BarcodeOmissions = $omissions.ToArray(); ValidationWarnings = $validationWarnings; TemplateSHA256 = $actualTemplateSHA256; TemplateChanged = $templateChanged; CompletionMarkerCount = $bindingPlan.MarkerCount; ProfileId = $templateProfile['ProfileId']; ReviewOnly = $Request['ReviewOnly']; WordLaunched = $false; Timings = $timings; PreparedSourceUsed = ($null -ne $cached) }
    }
    finally { if ($null -ne $document) { $document.Dispose() }; if ($null -ne $source) { $source.Dispose() }; if ($null -ne $sha) { $sha.Dispose() }; $memory.Dispose() }
}