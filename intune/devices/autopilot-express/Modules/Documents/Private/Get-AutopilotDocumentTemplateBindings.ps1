<#
.SYNOPSIS
    Resolve validated document bindings and author-supplied completion markers.
.DESCRIPTION
    Runs only inside the isolated SDK worker. Returns detached mappings without
    changing the source package, native controls or tracked completion evidence.
.FILECREATED
    2026-10-25
.FILELASTUPDATED
    2026-10-25
#>
function Get-AutopilotDocumentTemplateBindings {
    <#
    .SYNOPSIS
        Locate semantic targets and reject ambiguous or malformed row directives.
    .PARAMETER Parts
        SDK-owned document stories keyed by package URI.
    .PARAMETER TemplateProfile
        Fixed reviewed baseline; live approval is never inferred from an edit.
    .PARAMETER Changed
        True requests structural revalidation rather than byte-identical pinning.
    .OUTPUTS
        Effective bindings and marker paragraphs to clear after population.
    #>
    [CmdletBinding()]
    [OutputType([Collections.Specialized.OrderedDictionary])]
    param(
        [Parameter(Mandatory)][Collections.IDictionary]$Parts,
        [Parameter(Mandatory)][Collections.IDictionary]$TemplateProfile,
        [bool]$Changed
    )
    $bindings = [Collections.Generic.List[object]]::new()
    foreach ($binding in $TemplateProfile['Bindings']) { $bindings.Add((ConvertTo-AutopilotDocumentDictionary -Value $binding)) }
    $clearMarkers = [Collections.Generic.List[object]]::new(); $rowsSeen = @{}
    $storyParagraphs = @{}; $storyControls = @{}; $storyText = @{}; $storyGroups = @{}; $storyMarkers = @{}; $nextDrawingId = 1
    foreach ($partName in $Parts.Keys) {
        $paragraphs = [Collections.Generic.List[object]]::new(); $markers = [Collections.Generic.List[object]]::new()
        $controls = [Collections.Generic.Dictionary[string,object]]::new([StringComparer]::Ordinal)
        $texts = [Collections.Generic.Dictionary[string,object]]::new([StringComparer]::Ordinal)
        $groups = [Collections.Generic.Dictionary[string,object]]::new([StringComparer]::Ordinal)
        foreach ($element in $Parts[$partName].RootElement.Descendants()) {
            switch ($element.LocalName) {
                'p' {
                    if ($element.NamespaceUri -cne 'http://schemas.openxmlformats.org/wordprocessingml/2006/main') { continue }
                    $paragraphs.Add($element)
                    $text = [string]$element.InnerText
                    if ($Changed) {
                        if (-not $texts.ContainsKey($text)) { $texts[$text] = [Collections.Generic.List[object]]::new() }
                        $texts[$text].Add($element)
                    }
                    if ($text.IndexOf('{complete', [StringComparison]::OrdinalIgnoreCase) -ge 0) { $markers.Add($element) }
                    if ($Changed -and $element.Parent.LocalName -eq 'tc' -and $element.Parent.Parent.LocalName -eq 'tr') {
                        $cells = @($element.Parent.Parent.ChildElements | Where-Object LocalName -EQ 'tc')
                        if ($cells.Count -eq 3 -and [object]::ReferenceEquals($element.Parent, $cells[2])) {
                            $label = [string]$cells[0].InnerText
                            if (-not $groups.ContainsKey($label)) { $groups[$label] = [Collections.Generic.List[object]]::new() }
                            $groups[$label].Add($element)
                        }
                    }
                }
                'sdt' {
                    foreach ($properties in $element.ChildElements) {
                        if ($properties.LocalName -ne 'sdtPr') { continue }
                        foreach ($selector in $properties.ChildElements) {
                            if ($selector.LocalName -notin @('id','tag')) { continue }
                            $key = '{0}:{1}' -f $selector.LocalName, [string]$selector.Val
                            if (-not $controls.ContainsKey($key)) { $controls[$key] = [Collections.Generic.List[object]]::new() }
                            $controls[$key].Add($element)
                        }
                    }
                }
                'docPr' { $nextDrawingId = [Math]::Max($nextDrawingId, [int]$element.Id.Value + 1) }
            }
        }
        $storyParagraphs[$partName] = $paragraphs.ToArray(); $storyControls[$partName] = $controls
        $storyText[$partName] = $texts; $storyGroups[$partName] = $groups; $storyMarkers[$partName] = $markers.ToArray()
    }
    foreach ($binding in $bindings) {
        if (-not $Changed -or $binding['Kind'] -in @('Literal','CheckBox','TextControl','DateControl')) { continue }
        if (-not $Parts.Contains($binding['Part'])) { throw 'A required template story is missing.' }
        $paragraphs = $storyParagraphs[$binding['Part']]
        if ($binding['Kind'] -eq 'GroupResult') {
            $lookup = $storyGroups[$binding['Part']]; $key = [string]$binding['GuideStepText']
            $candidateParagraphs = @(if ($lookup.ContainsKey($key)) { $lookup[$key].ToArray() })
        }
        elseif ($binding['Kind'] -eq 'CertificationLabel') { $candidateParagraphs = @($paragraphs | Select-Object -First 1) }
        else {
            $lookup = $storyText[$binding['Part']]; $key = [string]$binding['ExpectedText']
            $candidateParagraphs = @(if ($lookup.ContainsKey($key)) { $lookup[$key].ToArray() })
        }
        if ($candidateParagraphs.Count -ne 1) { throw ('Changed template has a missing or ambiguous {0} target; correct it before retrying.' -f $binding['Kind']) }
        $binding['ParagraphIndex'] = [array]::IndexOf($paragraphs, $candidateParagraphs[0])
        if ($binding['Kind'] -eq 'CertificationLabel') {
            if ([string]::IsNullOrWhiteSpace($candidateParagraphs[0].InnerText)) { throw 'Template title is missing.' }
            $binding['ExpectedText'] = $candidateParagraphs[0].InnerText
        }
    }
    foreach ($partName in $Parts.Keys) {
        $paragraphs = $storyParagraphs[$partName]
        foreach ($paragraph in $storyMarkers[$partName]) {
            $rule = Get-AutopilotDocumentCompletionRule -Marker $paragraph.InnerText
            if ($partName -cne '/word/document.xml' -or $paragraph.Parent.LocalName -ne 'tc' -or $paragraph.Parent.Parent.LocalName -ne 'tr') { throw 'A completion marker must occupy its own paragraph in a body-table cell.' }
            $row = $paragraph.Parent.Parent; $rowIdentity = [Runtime.CompilerServices.RuntimeHelpers]::GetHashCode($row)
            if ($rowsSeen.ContainsKey($rowIdentity)) { throw 'Only one completion marker is allowed in each row.' }
            $rowsSeen[$rowIdentity] = $true
            $boxes = @($row.Descendants() | Where-Object { $_.LocalName -eq 'sdt' -and @($_.Descendants() | Where-Object LocalName -EQ 'checkbox').Count -eq 1 })
            if ($boxes.Count -gt 1) { throw 'Completion marker row contains ambiguous native checkboxes.' }
            if ($boxes.Count) {
                $controlId = @($boxes[0].Descendants() | Where-Object LocalName -EQ 'id')[0].Val.Value
                $targets = @($bindings | Where-Object { $_['Kind'] -eq 'CheckBox' -and [string]$_['ControlId'] -ceq [string]$controlId })
                if ($targets.Count -ne 1) { throw 'Completion marker has no unique reviewed checkbox target.' }
                $target = $targets[0]
                $clearMarkers.Add([ordered]@{ Paragraph = $paragraph; Marker = $rule.Marker })
            }
            else {
                $cells = @($row.ChildElements | Where-Object LocalName -EQ 'tc')
                if ($cells.Count -ne 3 -or -not [object]::ReferenceEquals($cells[2], $paragraph.Parent)) { throw 'Certificate completion marker belongs in the final result cell of a three-column row.' }
                $index = [array]::IndexOf($paragraphs, $paragraph)
                $targets = @($bindings | Where-Object { $_['Kind'] -eq 'GroupResult' -and $_['Part'] -ceq $partName -and $_['ParagraphIndex'] -eq $index })
                if ($targets.Count -ne 1) { throw 'Completion marker has no unique reviewed certificate row.' }
                $target = $targets[0]; $target['ExpectedText'] = $paragraph.InnerText; $target['CompletionMarker'] = $true
            }
            $target['StepIds'] = $rule.StepIds; $target['TriggerStepId'] = $rule.TriggerStepId
            $target['IncludesUntracked'] = $false
        }
    }
    return [ordered]@{ Bindings = $bindings.ToArray(); ClearMarkers = $clearMarkers.ToArray(); MarkerCount = $rowsSeen.Count; StoryParagraphs = $storyParagraphs; StoryControls = $storyControls; NextDrawingId = $nextDrawingId }
}