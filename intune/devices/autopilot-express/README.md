<!-- omit from toc -->
# Autopilot Express

Autopilot Express helps technicians follow the organisation's device-build checklist while preparing and tracking
multiple computers. It brings the build bench, selected Intune and Microsoft Entra actions, saved progress, and
optional document output into one PowerShell interface.

The script is still being tested. Demo mode is for rehearsal; Live access, physical builds and release acceptance
remain subject to the approvals and checks in [TODO.md](TODO.md). A successful offline test is not a successful
tenant operation or a completed physical build.

> **Warning:** Live mode can delete Intune managed-device records and change device properties, group membership
> and primary users. Do not use it in a production tenant until the required approvals and pilot checks are complete.

## Contents

- [What It Does](#what-it-does)
- [Before You Start](#before-you-start)
- [Start a Demo Session](#start-a-demo-session)
- [Finding Your Way Around](#finding-your-way-around)
- [Documents and Reprints](#documents-and-reprints)
- [Troubleshooting and Safety](#troubleshooting-and-safety)
- [Guides](#guides)
- [Product Files](#product-files)

## What It Does

- Tracks devices by serial number and configuration item, with a bench for working on more than one device.
- Guides the checklist in order and records whether an outcome was simulated, submitted, observed or confirmed.
- Saves local sessions and provides recovery guidance when work is interrupted.
- Generates optional birth certificates and checklists after dispatch, or for an existing confirmed dispatch.
- Keeps external tasks such as CMDB updates, network registration and physical imaging with the technician.

## Before You Start

Use an approved Windows desktop, the current controlled checklist and the complete reviewed product folder.
The script does not replace the checklist, physical work or technician judgement. PowerShell 7 is recommended;
Windows PowerShell 5.1 is supported for ordinary operation. Explicit legacy data conversion requires PowerShell 7.5
or later. See [SETUP.md](SETUP.md) for deployment, trust, permissions and the controlled checklist.

For Demo, work with a non-operational copy and approved local storage: the script saves session data. Live mode
requires an authorised tenant configuration, account, permissions and a separately approved pilot. Installing the
Graph SDK into the fixed-local per-user cache does not require administrator rights, but remains subject to your
organisation's software and execution policies.

## Start a Demo Session

From the repository root:

```pwsh
Set-Location .\intune\devices\autopilot-express
.\autopilot-express.ps1 -Mode Demo
```

Follow the displayed defaults and select a site. Resume a previous Demo session only when it is the one you intend
to use. The [first-device rehearsal](SETUP.md#technician-rehearse-a-first-device) explains what to check before
moving to an approved Live session.

## Finding Your Way Around

The main menu opens after setup. Pressing Enter at the main menu exits; within the build bench it refreshes the view.
The menu's numbered options are:

```plaintext
Main menu
|-- 1. Build Bench              # Induct, move, advance and dispatch devices
|-- 2. Device menu              # Start or continue one device; view outstanding work
|-- 3. My stats                 # View supported session statistics
|-- 4. Session and settings     # Site, work pattern, remediations and document output
|-- 5. Data settings            # Session, reports and recovery evidence
|-- 6. Script information       # Guides, About and command-line information
`-- 0. Exit                     # Default when Enter is pressed
```

Use [OPERATIONS.md](OPERATIONS.md#navigation-and-device-selection) for the full menus, scanner input, recovery and
dispatch procedures. A submitted Graph request is not the same as a verified result, and a document does not prove
the physical build is complete.

## Documents and Reprints

Both document types are **disabled by default**. When enabled, template approval guards are **OFF by default for
testing**. This permits unapproved certificate and checklist profiles to generate and request printing under the
chosen delivery policy; it does not approve the templates. Demo pages remain labelled, and explicitly review-only
requests do not print.

To reprint for a confirmed dispatch, open **Settings > Document output settings > [P]**, select the device and
certificate, checklist or both, then choose PDF generation or printing. Printing has its own confirmation; this
does not redispatch the device or repeat Graph actions. Use `[G]` in the same settings screen, or
`-EnforceDocumentGuards $true`, to restore the restrictions for both document types.

Word, document libraries, the PDF handler and printer must be available for the selected operation. A print request
is not proof of paper output. See [document controls](OPERATIONS.md#document-output-controls) and
[existing-device reprints](OPERATIONS.md#generate-and-find-documents) for prerequisites and recovery.

## Troubleshooting and Safety

- **A step is submitted or blocked:** read its result and follow the relevant
  [workflow guidance](OPERATIONS.md#workflow-and-physical-work); do not assume a request succeeded.
- **Document output fails:** retain the result and use the document-only retry or reprint options described in
  [Operations](OPERATIONS.md#document-production-and-template-authoring).
- **A session or host fails:** preserve the logs and saved evidence, and follow
  [interrupted-save recovery](OPERATIONS.md#interrupted-save-recovery). Do not remove locks or replay tenant actions
  merely to make startup succeed.
- **A tenant or physical action needs approval:** stop at that boundary. The
  [open acceptance items](TODO.md#retained-acceptance-and-approval-holds) say what evidence is still required.

Do not include credentials, access tokens, hardware hashes or unnecessary personal information in support reports.
For help, provide the script revision, mode, affected step, safe error details and permitted evidence location.
See [support and escalation](OPERATIONS.md#support-and-escalation).

## Guides

- [Setup](SETUP.md) - deployment, prerequisites and first-device rehearsal.
- [Operations](OPERATIONS.md) - menus, workflow, documents, recovery and support.
- [Customisation](CUSTOMISATION.md) - changing an approved deployment or workflow.
- [Technical guide](TECHNICAL.md) - implementation, evidence and trust boundaries.
- [Function catalogue](FUNCTIONS.md) - source, parameters and callers.
- [Testing](TESTING.md) - offline checks and real-environment acceptance.
- [Outstanding work](TODO.md) - priorities, blockers and approval holds.
- [Development history](DEVELOPMENT.md) - completed work and decisions.
- [Repository licence](../../../LICENSE) - GNU General Public License, version 3.

## Product Files

```plaintext
autopilot-express/
|-- autopilot-express.ps1             # Entry point, menus, workflow and local state
|-- autopilot-express.manifest.json    # Workflow actions and descriptive metadata
|-- autopilot-express.runtime.json     # Tenant, runtime and optional output settings
|-- Modules\Documents\                 # Optional document APIs and isolated workers
|-- templates\                         # Source document templates; originals are preserved
|-- tests\                             # Pester regression suites
`-- development\                       # Development tools and supporting reference material
```

Run the relevant checks in [TESTING.md](TESTING.md) after changes. Shared multi-technician storage, production
template approval, physical printing and tenant acceptance remain separate from the implemented local workflow.
