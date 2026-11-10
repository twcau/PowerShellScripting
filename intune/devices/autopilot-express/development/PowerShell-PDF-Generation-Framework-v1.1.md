<!-- omit from toc -->
# PowerShell PDF Document Generation Framework

## Complete Design & Implementation Specification v1.1

**Status:** Approved Design Baseline
**Audience:** GitHub Copilot, Developers, Future Maintainers
**Purpose:** Functional and technical specification for integration of document generation, barcode rendering, PDF export and optional printing into the existing PowerShell application.

---

# 1. Executive Summary

This feature adds automated document generation capabilities to an existing PowerShell application.

The system will use Microsoft Word DOCX templates stored relative to the application root, populate them using data already maintained by the script, insert generated barcode images, export the completed document as PDF, and optionally present or print the final document.

The design intentionally treats document generation as a non-critical capability. Failures associated with template processing, barcode generation, PDF creation or printing must never prevent the primary workflow of the application from continuing.

The resulting architecture is template-driven, configuration-driven, observable, maintainable by non-developers, and extensible for future document types and GS1 QR support.

---

# 2. Project Objectives

## Mandatory Objectives

- Support Microsoft Word DOCX templates.
- Populate predefined placeholders.
- Insert barcode images.
- Generate PDFs.
- Support PowerShell 5.1.
- Support PowerShell 7+.
- Use existing application data.
- Preserve template formatting.
- Support optional printing.
- Support runtime overrides.
- Support future template types.
- Remain maintainable by non-developers.

## Non-Objectives

- Digital signatures.
- Regulatory PDF signing.
- Long-term document retention management.
- Cloud document storage.
- Database-backed document storage.
- Initial GS1 QR implementation.

---

# 3. Approved Technology Stack

As part of using this technology stack, the script should have appropriate logic to ensure these are all available, allow the user to permit the script to get these automatically, have the script install them if permitted to do so, and then check they are all there and working, and availabnle to the script.

## DOCX Processing

Approved Standard:

- Open XML SDK

Purpose:

- Placeholder discovery.
- Placeholder replacement.
- Template validation.
- Image insertion.

Word should not be used for routine document editing.

## Barcode Generation

Approved Standard:

- ZXing.Net

Initial Symbology:

- Code 128

Future Symbology:

- GS1 QR

## PDF Generation

Approved Standard:

- Microsoft Word COM Automation

Word is the authoritative rendering engine.

Reasoning:

- Highest fidelity.
- Preserves formatting.
- Consistent with existing templates.
- Word 365 is expected on all supported machines.

## Printing

Approved Option:

- PDF generated.
- PDF opened through normal Windows mechanisms.
- User or automation prints PDF.

This guarantees users print exactly the document produced.

---

# 4. Solution Architecture

Workflow:

1. User completes workflow within the main script (being a dispatch, or dispatch override)
2. Script determines document requirements.
3. Validation performed.
4. Template loaded.
5. Data mapped.
6. Barcode images generated.
7. Placeholders replaced.
8. DOCX output created.
9. PDF exported.
10. PDF optionally opened.
11. PDF optionally printed.
12. Temporary assets cleaned up.
13. Logging completed.

---

# 5. Directory Structure

Recommended structure:

Root

- Templates/
- Output/
- Temp/

Templates folder contains all supported DOCX templates.

Output folder contains generated documents.

Temp folder may be used for intermediate barcode assets.

---

# 6. Template Design Standard

Templates are authoritative.

The application must not recreate formatting.

Templates own:

- Layout
- Positioning
- Tables
- Header/footer content
- Text styles
- Margins
- Checklists
- Human-readable labels

The script owns:

- Data substitution
- Barcode generation
- Image insertion

---

# 7. Placeholder Standard

## Text Placeholders

Format:

{{PlaceholderName}}

Examples:

{{SiteCode}}
{{DeviceName}}
{{SerialNumber}}
{{CompletionDate}}
{{OperatorName}}

## Image Placeholders

Format:

[[PlaceholderName]]

Examples:

[[AssetBarcode]]
[[SerialBarcode]]
[[GS1QRCode]]

Image placeholders indicate:

- Placeholder text removed.
- Image inserted.

---

# 8. Placeholder Validation

Validation must confirm:

- Template can be opened.
- Placeholders are discoverable.
- Placeholder names are valid.
- Placeholders expected by script exist.
- Unexpected placeholders are reported.

Mismatch handling:

- Warning issued.
- Document generation disabled if required mappings cannot be satisfied.
- Primary script functionality continues.

---

# 9. Barcode Framework

## Initial Release

Code 128 only.

## Future Release

GS1 QR.

## Barcode Requirements

Barcodes must:

- Preserve aspect ratio.
- Include required quiet zones.
- Omit barcode captions.
- Omit embedded human-readable text.
- Produce PNG output.

Human-readable values remain under template control.

---

# 10. Barcode Placement Rules

The implementation shall:

- Detect available insertion region.
- Fit within available region.
- Preserve template layout.
- Preserve table dimensions.
- Preserve row heights.
- Preserve pagination.

Barcode images should be generated at the highest practical quality and scaled to fit available space.

Barcode suppression is not desired.

Use best-fit rendering when space becomes constrained.

---

# 11. Checklist Framework

Second-page checklist support is required.

The template will contain bracketed letter identifiers.

Examples:

{A}
{B}
{C}

When a corresponding workflow step has completed:

{A} -> ✔

When incomplete:

Original document state remains.

Exact mapping logic will be defined during implementation because GitHub Copilot has access to the existing workflow and execution state information.

---

# 12. Date & Time Population

The solution shall support:

- Date fields
- Time fields
- Combined DateTime fields
- Workflow completion timestamps
- Device-specific timestamps

Formatting remains under application control.

---

# 13. Multi-Template Support

Support for multiple templates is mandatory.

Currently anticipated:

- Template A
- Template B

Selection may originate from:

- JSON configuration
- Command-line override
- Interactive menu selection

---

# 14. Template Selection Behaviour

This area requires additional implementation discovery.

Reasons:

- Existing application workflow not yet integrated.
- User-configurable defaults exist.
- Runtime overrides exist.
- Multiple templates may become available.

Recommended resolution order:

1. Command-line override
2. Interactive menu override
3. JSON configuration
4. Application default

Final behaviour should be confirmed during implementation.

---

# 15. Configuration Integration

The application already contains configuration structures.

Document-generation configuration should be integrated into the existing configuration architecture.

The specification deliberately avoids defining a final schema because GitHub Copilot can evaluate the existing configuration model directly.

Expected settings include:

- Enable/disable generation
- Template selection
- Output location
- PDF open behaviour
- Print behaviour
- Cleanup behaviour

---

# 16. Runtime Overrides

Users must be able to:

- Enable generation.
- Disable generation.
- Change template.
- Print both templates, where a specific template is sent to the default printer automatically, and the other is just displayed in the browser or PDF viewer on the device for the purpose of saving that file elsewhere.
- Change print mode.

Methods:

- JSON defaults
- Command-line flags
- Interactive menu changes

Runtime changes should affect only the current session unless explicitly persisted.

---

# 17. Printing Framework

Supported modes:

Disabled
GenerateOnly
Review
GenerateAndAsk
AutoPrint

## Preferred Workflow

Generate PDF.

Open PDF using Windows file association.

Allow review.

Optional print.

## Runtime Behaviour

Users must be able to override print behaviour during execution.

Command-line flags may also override configured defaults.

All printing options must be documented within application help.

---

# 18. Output Directory Behaviour

Output directory validation required.

If missing:

- Create automatically.
- Log action.
- Continue processing.

Failure to create output location:

- Disable document generation.
- Continue primary application workflow.

---

# 19. Generated File Naming

Naming must be configuration-driven.

Potential naming tokens:

- SiteCode
- DeviceName
- SerialNumber
- Date
- DateTime
- Workflow identifiers

Hardcoded naming must be avoided.

---

# 20. Reimaged Device Considerations

The wider application tracks workflows that may be executed repeatedly against the same asset.

Document generation must therefore:

- Treat each workflow instance independently.
- Avoid assuming only one document exists per asset.
- Generate filenames capable of distinguishing runs.

The application logic already understands this concept and should remain authoritative.

---

# 21. Temporary File Lifecycle

Temporary barcode files should:

- Use GUID-based names.
- Avoid collisions.
- Be disposable.

Examples:

GUID-device-barcode.png
GUID-serial-barcode.png

## Successful Generation

Delete temporary assets.

## Failed Generation

Retain files if configured.

## Startup Cleanup

Subsequent runs should remove stale temporary assets.

This satisfies troubleshooting requirements without permanent accumulation.

---

# 22. Validation Framework

Validation occurs after site selection and before workflow execution proceeds.

Checks:

- Configuration validity
- Template folder existence
- Template existence
- Template readability
- Template structure
- Placeholder consistency
- Word availability
- Output location access

Failures must never stop use of the core application.

---

# 23. Error Handling Framework

Principle:

Document generation is non-critical.

## Warning Events

Examples:

- Barcode generation failed.
- Missing optional placeholder.
- Non-critical template mismatch.

Behaviour:

- Warn.
- Log.
- Continue.

## Error Events

Examples:

- Template cannot be opened.
- PDF export fails.
- Required mapping failure.

Behaviour:

- Disable generation.
- Record failure.
- Continue application.

---

# 24. Logging & Observability

Reuse the application's existing observability standards.

Required logging events:

- Template selected
- Validation completed
- Barcode generation started
- Barcode generation completed
- Placeholder replacement completed
- DOCX generated
- PDF exported
- PDF opened
- Print requested
- Cleanup completed
- Errors/warnings

Logging should conform to the application's current standards.

---

# 25. Audit Metadata

Future enhancement.

Potential footer fields:

- Generated By
- Generated Date
- Generated Time
- Template Version
- Script Version

Implementation deferred.

---

# 26. GS1 QR Future Architecture

Not required in v1.

Architecture must avoid blocking future support.

Future implementation should require:

- New payload builder
- New barcode mapping
- Template placeholder

No major redesign should be required.

---

# 27. PowerShell Compatibility Requirements

Must support:

- PowerShell 5.1
- PowerShell 7+

Implementation must avoid language features unavailable in PowerShell 5.1.

Compatibility testing is mandatory.

---

# 28. Acceptance Criteria

Feature considered complete when:

- Template loads successfully.
- Placeholders populate correctly.
- Barcode images generate correctly.
- Code 128 scans successfully.
- PDF exports correctly.
- Existing formatting preserved.
- Optional printing works.
- Runtime overrides work.
- PowerShell 5.1 validated.
- PowerShell 7 validated.
- Document-generation failures do not stop application.

---

# 29. Testing Plan

Test:

- Missing template.
- Missing placeholder.
- Unknown placeholder.
- Barcode generation failure.
- Word unavailable.
- Invalid output folder.
- Printing disabled.
- Review mode.
- AutoPrint mode.
- Multiple workflow runs.
- PowerShell 5.1.
- PowerShell 7.

Validation must include both PDF review and physical print review.

---

# 30. Final Design Statement

The approved architecture is a placeholder-driven, template-managed document-generation framework that uses Open XML SDK for document manipulation, ZXing.Net for barcode generation, Microsoft Word as the authoritative PDF rendering engine, and the application's existing configuration, logging and workflow systems for management and observability.

The solution prioritises maintainability, reliability, operational simplicity and future extensibility while ensuring that document-generation failures never interrupt the primary purpose of the application.
