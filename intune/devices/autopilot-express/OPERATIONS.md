<!-- omit from toc -->
# Autopilot Express Operations Reference

<!-- markdownlint-configure-file { "MD033": { "allowed_elements": ["a"] } } -->

Use this guide for detailed procedures, configuration, document templates and recovery. Start with
[README.md](README.md) for setup. [TESTING.md](TESTING.md) owns validation and acceptance;
[TECHNICAL.md](TECHNICAL.md) explains the implementation, [DEVELOPMENT.md](DEVELOPMENT.md) records decisions,
and [TODO.md](TODO.md) tracks outstanding work.

## Contents

- [Workflow and Physical Work](#workflow-and-physical-work)
- [Navigation and Device Selection](#navigation-and-device-selection)
- [Configuration Reference](#configuration-reference)
- [Quick Remediations and Intune Links](#quick-remediations-and-intune-links)
- [Document Production and Template Authoring](#document-production-and-template-authoring)
- [Data, Session Recovery, and Audit](#data-session-recovery-and-audit)
- [Working-Time Policy](#working-time-policy)
- [Troubleshooting](#troubleshooting)
- [Security and Privacy](#security-and-privacy)
- [Known Issues and Limitations](#known-issues-and-limitations)
- [Support and Escalation](#support-and-escalation)

## Workflow and Physical Work

The CLI supports the [Autopilot Checklist - New Device v1.4](development/Autopilot%20Checklist%20-%20v1.4.pdf).
Confirm its currency and accept the differences below before physical work. It automates selected Intune/Entra
actions; it does not perform imaging, install applications, update firmware or complete external handoffs.

### Account Roles

The current deployment distinguishes three account roles:

- The privileged CA/A account signs the technician in to Microsoft Graph.
- The technician's regular C/E account is used for work on the physical device.
- The final primary user is the eligible C/E account selected for the device's assigned or shared purpose.

These are separate choices: Graph sign-in does not automatically select either device account. Eligibility and
selection must still be checked in the [directory search](#directory-search).

### Display and Saved IDs

Current version-two records use the displayed step letters as saved IDs. The action table is:

| Step | Action                               |
| ---- | ------------------------------------ |
| A    | Resolve Autopilot identity           |
| B    | Remove associated managed device     |
| C    | Apply Group Tag                      |
| D    | Add pre-provisioning membership      |
| E    | Confirm imaging/OOBE                 |
| F    | Validate deployment profile          |
| G    | Confirm reseal/shutdown              |
| H    | Confirm boot to sign-in              |
| I    | Assign regular technician            |
| J    | Remove pre-provisioning membership   |
| K    | Confirm first sign-in                |
| L    | Confirm application baseline         |
| M    | Review app failures; sync if needed  |
| N    | Confirm updates/shutdown             |
| O    | Assign final primary user            |
| P    | Submit recovery unblock              |
| Q    | Confirm recovery readiness           |

Legacy version-one IDs require [guarded conversion](#canonical-evidence-migration), not manual renaming.
This reference interprets old evidence; the legacy letters are not additional current commands.

| Current step and saved ID | Legacy saved ID | Action                               |
| ------------------------- | --------------- | ------------------------------------ |
| A                         | A               | Resolve Autopilot identity           |
| B                         | B               | Remove associated managed device     |
| C                         | C               | Apply Group Tag                      |
| D                         | E               | Add pre-provisioning membership      |
| E                         | K               | Confirm imaging/OOBE                 |
| F                         | D               | Validate deployment profile          |
| G                         | L               | Confirm reseal/shutdown              |
| H                         | M               | Confirm boot to sign-in              |
| I                         | G               | Assign regular technician            |
| J                         | I               | Remove pre-provisioning membership   |
| K                         | N               | Confirm first sign-in                |
| L                         | O               | Confirm application baseline         |
| M                         | H               | Review app failures; sync if needed  |
| N                         | P               | Confirm updates/shutdown             |
| O                         | J               | Assign final primary user            |
| P                         | F               | Submit recovery unblock              |
| Q                         | Q               | Confirm recovery readiness           |

### Physical Sequence

1. Use T for eligible A-D preparation. Autopilot presence is mandatory. Confirm the exact managed device before
   deletion, then wait for verified absence, the expected Group Tag and correct pre-provisioning membership.
2. Perform imaging/OOBE at E. At F verify the intended deployment profile physically before setup; a matching
   Group Tag alone does not establish profile assignment. Confirm successful provisioning/reseal at G and boot to sign-in at H.
3. At I select the regular technician account. The Windows-login hint maps `cacmiharr` to `cmiharr` and `ca123456`
   to `e123456`, case-insensitively. Uncertain names prompt. The directory match needs Y, default No; do not use
   the privileged Graph account as a fallback.
4. Verify pre-provisioning group removal at J before first physical sign-in at K. Check the applications in order.
   If one fails, leave L unconfirmed, follow the approved portal remediation and choose `[Y]` at M to request
   device sync. M does not run that remediation or prove installation succeeded. Once all applications are
   confirmed at L, choose `[N]` at M, or press Enter, to record no failures without requesting sync. `[0]` cancels.
5. Complete approved manufacturer updates, reboots, other applicable procedures and shutdown at N. Use approved
   non-Dell procedures on non-Dell hardware. At O explicitly select the correct eligible final owner.
6. Dispatch with bench D or workflow DISPATCH. Required work and explicit Y/default No are mandatory. DO instead
   needs a written reason and default-No approval; it retains incomplete/recovery evidence as an administrative exception.

Physical confirmations generally default Y as displayed; No leaves work incomplete. They are
TechnicianConfirmed in Live, not Graph verification. Demo uses Simulated evidence.

### Evidence and Completion

| State               | Meaning                                                                                |
| ------------------- | -------------------------------------------------------------------------------------- |
| Verified            | The action-specific target state was observed through Graph.                           |
| TechnicianConfirmed | A technician explicitly confirmed a guided/manual outcome.                             |
| Submitted           | A request or handoff was accepted or remains uncertain; completion is not established. |
| Failed / Blocked    | Work failed or cannot run; it does not satisfy prerequisites.                          |
| Simulated           | Demo result only; not Live certification.                                              |
| LegacyCompleted     | Compatible old completion without invented verification.                               |
| AuditedException    | Reserved exception evidence, not proof of physical success.                            |

An empty next-step picker is not completion. Retrying completed work invalidates dependent completion; completing
the upstream step again does not revive those descendants. If L is reconfirmed or withdrawn, a no-failures outcome
at M must be recorded again. Old attempts remain in history.

The writer can mark required workflow work completed before dispatch. Such a record leaves active pickers but may
still occupy a bench position: dispatch it from bench D or its already-open workflow. Dispatch clears the matching
slot only after the checkpoint save succeeds. DO sets `IsCompletionVerified` false; it never fabricates step evidence.

### Mutation Verification

- **Group Tag:** one write, then one immediate exact-ID read. Exact expected tag is Verified; absent/unavailable
  read-back stays Submitted. Reselecting an accepted pending step reads again without another POST.
- **Membership:** fresh complete direct memberships establish the target and conflicts. Already-correct state needs
  no write. Otherwise one add or reference-only removal is followed by one immediate check; pending rechecks do not
  replay accepted writes. A dynamic, mail-enabled, role-assignable or otherwise ineligible mutation target is refused.
- **Deletion:** after explicit confirmation (displayed default Y), one DELETE is followed by bounded serial reads.
  Only valid empty results prove absence. A replacement ID, partial response or failed read does not.
- **Primary user:** Verified requires the intended Autopilot UPN and a complete managed-user response containing
  exactly one matching user. An allowed manual confirmation is TechnicianConfirmed, not Verified. Changing an
  unresolved attempted target requires review of both tenant surfaces.
- **Sync/import/recovery:** request acceptance is not application success, registration or Allowed. Preserve receipts
  and use the relevant read-only recheck, not an automatic repeat.

Fresh reads cannot eliminate concurrent tenant changes or the server-acceptance-to-local-save crash gap.
Inspect uncertain tenant state under approval before another mutation.

### Recovery Close-out

1. Use X to enter/resume recovery for the selected device. New entry needs a reason and default-No confirmation;
   it is saved before cleanup. Previous results remain in RecoveryHistory.
2. Perform the approved physical reset/reimage. X resolves identity, runs eligible B cleanup and submits P only
   with current-cycle cleanup evidence. The script saves intent before the request. P stays Submitted and the
   sequence stops when the response is accepted.
3. If the request was interrupted or its response could not be saved, select P to review the same device in Intune.
   The script does not resend it. Confirm Allowed only if you have observed it for the displayed device; Enter
   defaults to No and leaves recovery paused. If it is not Allowed or cannot be checked, preserve the evidence
   and seek recovery support. The observation does not claim the earlier request was accepted.
4. After at least two minutes from an accepted P response, or from the technician's Allowed observation when the
   response is unknown, use X again or Q. Selecting an already recorded P is blocked without another request or
   restarting the wait. Q refuses a missing, invalid or old-cycle timestamp and requires a fresh lookup showing
   no managed device. If the timestamp is invalid, preserve the evidence and seek recovery support.
5. Confirm reset/reimage and Intune Allowed, default Y. No leaves recovery active. Live uses TechnicianConfirmed;
   Demo does not perform a real lookup or wait.
6. Close-out retains identity/history, archives recovery evidence and clears active ownership/completion context.
   Use T to prepare again, then repeat the physical milestones.

During recovery, normal work is blocked except identity and cleanup. Each T/X action saves before advancing;
pending, failure, cancellation or a save error stops it. Neither command is blanket mutation approval or remote reset.

### Checklist Coverage

This comparison covers all 26 steps of the bundled seven-page v1.4 checklist dated 29 April 2026.
The document owner and pilot approver must accept its currency and the differences before use.

| PDF steps | CLI work           | Coverage and boundary                                                                                                                                              |
| --------- | ------------------ | ------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| 1         | External checklist | Manually save `AP Checklist ServiceTag_DDMMYY` to SharePoint, Autopilot checklists > Your State-Your Site Code. Workflow JSON is not this copy.                    |
| 2         | A/B                | Resolve Autopilot and remove the associated managed device with read-back; missing registration uses the approved hash workflow.                                   |
| 3         | C                  | Apply the approved sitecode-devicetype Group Tag.                                                                                                                  |
| 4-5       | A/D                | Resolve Entra identity and add pre-provisioning membership.                                                                                                        |
| 6-10      | E                  | Technician performs network/dock setup, USB imaging, region/keyboard and five-key OOBE entry to the profile screen.                                                |
| 11        | F/G                | Physically verify profile and successful setup before reseal. A wrong profile requires the checklist's Cancel/repeat procedure, not an automatic loop.             |
| 12        | X/B/P/Q            | Conditional physical reset/reimage, current-cycle cleanup, unblock and timed Allowed observation.                                                                  |
| 13-14     | G/H                | Confirm reseal/shutdown and boot. Preserve any error and follow the controlled Continue Anyway instruction where applicable.                                       |
| 15-16     | I/J                | Explicit regular C/E technician selection and pre-provisioning group removal.                                                                                      |
| 17        | K                  | Physical first sign-in after assignment and group removal.                                                                                                         |
| 18-19     | L/M and portal     | Confirm the baseline at L. For failures, use Run Remediations > Retry failed app installation and request sync at M; otherwise M records no failures without sync. |
| 20-22     | N                  | Technician performs BIOS/drivers, reboots and applicable procedures, then shuts down.                                                                              |
| 23        | O                  | Select final caregiver or appropriate shared-device recipient; the CLI does not infer manager roles.                                                               |
| 24-26     | External handoff   | ZENworks, CMDB/Downstream CI, installation, collection and same-day disposal remain external work without recorded CLI completion.                                 |

The checklist's application order is Cortex XDR, Office (Office 2016 Pro Plus for shared devices), .NET Desktop
Runtime 8 8.0.21.35325, Dell Command | Update, WebView2 142.0.3595.53, Zenworks Agent, then laptop-only Global Protect.
These are the checklist's pinned versions, not current vendor-release claims. Install one at a time and verify
applications already supplied by the USB image.

### External Handoff Guidance

After completed final ownership, the CLI displays guidance to copy ZENworks relationships, find/create the CMDB CI,
link the replaced device, coordinate installation/collection and complete same-day disposal. Verify recipient,
site, department/ward, building/floor/room and numeric sticker CI externally. Do not install before old-device
collection is possible or leave disposal devices with the caregiver. No integration or handoff proof is recorded.

## Navigation and Device Selection

```plaintext
Main Menu
|-- 1. Build Bench                        # Position-based work
|-- 2. Device Commands                    # Caller-owned submenu
|   |-- 1. Start work                     # New/reuse; bench or standalone
|   |-- 2. Continue work                  # Executable device workflow
|   |-- 3. Current device list            # Read-only
|   |-- 4. Maintain device list           # Guarded status changes
|   |-- 5. Outstanding work               # Open the selected workflow directly
|   |-- 6. Device actions                 # Remediations/status/local clipboard link
|   `-- 0. Main Menu                      # Explicit return
|-- 3. My Stats                           # Dispatch counts and working-time estimates
|-- 4. Session and Script Settings         # Session defaults and explicit preferences
|   |-- 1. Current site                   # New work only
|   |-- 2. Default device type            # New work/new benches only
|   |-- 3. View work pattern              # Read-only
|   |-- 4. Edit work pattern              # Effective-dated protected history
|   |-- 5. Quick-run remediations          # Per technician and tenant
|   |-- 6. Document output settings        # Independent optional outputs
|   |-- 9. Reconnect Graph                # No workflow replay
|   `-- 0. Main Menu                      # No implicit save
|-- 5. Data Settings                      # Current user/mode
|   |-- 1. Log folder                     # Actual transcript directory in Explorer
|   |-- 2. Archive/start fresh            # Selection, No and CLEAR safeguards
|   |-- 3. Session report                 # CSV/HTML; explicit Y/default No
|   |-- 4. Recovery backup report         # Read-only sizes; O organises older backups (Y/default N); nothing deleted
|   |-- 5. Update device details from Intune # Current and archived Live sessions; missing details only
|   `-- 0. Main Menu                      # Explicit return
|-- 6. Script Information                 # Paged read-only views
|   |-- 1. About                          # R opens local README in Notepad
|   |-- 2. Steps List                     # Manifest guidance; no action execution
|   |-- 3. Basic documentation            # Operator overview
|   |-- 4. Command-line flags             # Actual entry-point parameters
|   |-- 8. Enhancements                   # Status-labelled proposals
|   `-- 0. Main Menu                      # Explicit return
`-- 0. Exit                              # Root Enter also exits
```

Actions return to their calling submenu. Choices are case-insensitive and defaults are displayed. About 9 opens
Enhancements and returns there; Information > 8 returns to Information. About's R opens README without waiting.

### Build Bench and Guide

```plaintext
Build Bench
|-- I. Induct                       # Empty position; existing eligible work or new record
|-- T. Prepare                      # Guarded A-D orchestration
|-- S. Next step                    # One selected device
|-- D. Dispatch / DO override        # Explicit default-No confirmation
|-- V. Device overview              # Executable workflow; same as Devices > 2
|-- X. Recover                      # Guarded cleanup/unblock/readiness
|-- M. Move                         # Empty destination only
|-- A. Device actions               # Remediations/status/link
|-- R. Remove                       # Position only; workflow evidence remains
|-- W. Steps List                   # Read-only guide
|-- U. Go back                      # Withdraw an eligible physical confirmation
|-- L. Result details               # Full retained event text
`-- 0. Return                       # E alias; Enter refreshes
```

Bench capacity is 1-50; zero/Enter cancels setup. Device selectors accept position, serial and CI, refusing ambiguity.
Use `P:1`, `S:ABC123`, `CI:001`; bare zero cancels but `CI:0` selects that literal CI. T/X/U/S/C/D/DO/V and move-source
selection default to cancel. Remove-position and move-destination retain their displayed defaults. C remains an
undisplayed compatibility action command.

T, X, U and A also accept several positions: a comma list (`1,3`), an ascending range (`5-7`), a mix (`1,3,5-7`)
or `ALL`. The bench lists the occupied positions it will act on and any empty positions it will skip, then asks
`Run on these devices? [Y] Yes [N] No` (default N). Devices run one at a time in position order, never in parallel,
and a per-device outcome summary is retained (use L for the full text). A descending range, an unknown position or
an empty selection is refused before anything runs. A single number, a `P:`/`S:`/`CI:` prefix or text that exactly
matches a bench serial or CI keeps its existing single-device meaning.

Prepare may run D membership while an accepted C Group Tag update is still propagating, but only after A/B are
complete and the saved submission matches this record, build cycle, tenant, serial, target and requested tag.
The C save must succeed before D runs. C stays Submitted; completed membership does not complete Prepare or unlock
E physical provisioning. Recheck C; accepted tag and membership submissions retain their no-repost guards. Failed,
unaccepted, stale, mismatched or legacy tag evidence without the accepted context does not permit this overlap.

Current is the latest recorded handler outcome (`?` if legacy ordering cannot be determined); Next is eligible work,
not proof that all work is done. Five transient event summaries appear newest first; L pages complete text. Moving
another device does not relabel earlier results. The transcript is diagnostic evidence, not proof of a committed save.

In the executable workflow, 8 runs next, a step letter selects eligible work, 9 switches device and 0 returns.
Custom-ID collisions use displayed alternatives. W uses `>`/`<` then Enter for paging, step letters for detail,
STEP LIST for overview and 0/Enter to return. N/P remain selectable steps. Resizing recalculates pages; enlarge
tiny windows. The guide never runs actions or saves progress.

### Resume, Restore and Restart

Device Commands > 1 offers bench B or standalone S when a bench exists: B defaults with free space, S when full.
Bench I requires an empty position. E lists existing off-bench records and N captures a new serial. Selection
defaults Cancel; entering an existing serial opens its explicit action menu rather than creating a duplicate.

In E, select a displayed list number, serial or CI; identifiers are case-insensitive. A valid list number takes
precedence over a numeric identifier. Unknown or ambiguous identifiers are rejected without changing a workflow;
0 cancels. Resume or restore through the existing action menu to keep the retained steps and attempt history.
The bench induction result reports new workflows separately from retained workflows attached to the bench.

| Choice    | Effect and guard                                                                                                                                                            |
| --------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| R Resume  | Continue eligible new/in-progress work with identity, start time, steps and history intact.                                                                                 |
| RESTORE   | Reactivate removed, undispatched work; reason, CI-conflict checks and default-No confirmation required.                                                                     |
| RESTART   | New build cycle for the same record/serial/CI; reason and default-No confirmation, retained prior snapshot/attempts. Active recovery or unresolved accepted work blocks it. |
| 0 / Enter | Cancel without changing the record or bench.                                                                                                                                |

Restart clears current steps, cached service IDs and dispatch/completion context and requires discovery again.
It never reverses cloud actions or adopts unsafe old tenant evidence. Current-record statistics reset until a new
dispatch; earlier-cycle snapshots remain history, not lifetime per-cycle totals. The device record's sync ledger is
retained across restart.

Sync evidence is kept inside each device record as an append-only `SyncSubmissions` ledger, keyed by build cycle and
target. Before each sync request an `Intent` entry is saved to the record; once Microsoft Graph accepts the request an
`Accepted` entry is appended. Ledger entries are never edited or removed. If a later run finds an `Intent` with no
`Accepted` entry, the earlier outcome is unknown (the process stopped or the response was lost). The sync is resubmitted
automatically, because device sync is safe to repeat, and a WARN log entry records the uncertainty. If the `Accepted`
entry cannot be saved, further sync stops for review.

The no-failures choice at M does not create or remove a sync receipt. It is available only after the current
application baseline is confirmed; a later change to that baseline invalidates the no-failures outcome. The
failure-path sync remains selectable while the baseline is incomplete.

Older versions wrote separate `sync-submission-<key>.json` and `sync-intent-submission-<key>.json` files. In Live mode,
startup migrates these into the matching device records and deletes each legacy file only after the record has been
saved successfully. A file that cannot be matched or saved is left in place and logged for review. Demo mode never
migrates or deletes them.

U withdrawal preserves the original physical attempt and appends a correction before saving. It invalidates dependent
completion and refuses dispatched/removed/recovery work or dependent accepted remote actions. It does not undo Graph.

## Configuration Reference

Definitions load once at startup. Runtime JSON owns tenant/profile/group names, scopes/modules, account/search/scanner
rules, hash discovery and storage settings. Sites MI/MU/SU/GE/AL (Midland/Murdoch/Subiaco/Geraldton/Albany), types
Desktop/Laptop/WOW/NUC and transport defaults live in the script. Use the owning source described in
[Configuration Ownership](TECHNICAL.md#configuration-ownership); do not edit saved evidence to change behaviour.

### Tenant Approval Gate

Before Live authentication or a pilot, record approval for:

- The tenant GUID, Graph account, actual application/client, installed coherent SDK and Conditional Access mode.
  A blank tenant pin is compatibility, not approval; never clear it to bypass rejection.
- The deployment profile and exact uniquely resolved pre-provisioning group, including immutable IDs. Supplied
  names are `SJOG Hybrid Join` and `Intune-Autopilot-Testing`; profile assignment still needs physical confirmation.
- All configured delegated scopes and relevant Intune/Entra roles. Read/consent success is not write permission.
  Remediation reads need `DeviceManagementScripts.Read.All`; execution/sync also need privileged device operations.
- Eligible C/E users, approved site/type tags, checklist currency, physical procedures and one dedicated pilot device.
- Local data access/retention, recovery owner, evidence location and escalation. Keep Shared disabled.
- Separate authentication/read and mutation authorisations. Startup requests write-capable scopes; there is no
  enforced read-only or dry-run mode for Live inspection.

Follow the [approved pilot procedure](TESTING.md#single-device-live-pilot), not a destructive permissions probe.

### Group Conflict Exclusion Rules

Change the exact pre-provisioning group display name in runtime JSON only after approval, restart, and verify the
resolved identity. Startup placeholder choices are session-only. Changing targets midway does not migrate membership.

The manifest's `groupConflictExclusions` supports literal case-insensitive Prefix/Exact rules. Supplied prefixes are
`Intune-Autopilot-All-`, `Intune-Workstation-`, `Intune-Workstations-`, plus Exact `Intune-Autopilot-AllDevices`.
The latter does not exclude lookalikes such as `Intune-Autopilot-AllDevices-Other`. An absent/empty array excludes
nothing; explicit custom rules remain authoritative. Restart after changes.

Exclusions only remove irrelevant background memberships from conflict correction. They do not authorise a target
or editing those groups. The default-No preview permits only displayed eligible conflicting reference removals,
never group deletion. Declining leaves memberships unchanged and blocks completion.

### Directory Search

Eligibility uses `onPremisesSamAccountName` first, UPN username only for absent SAM. Exact username/UPN searches and
explicit selection are revalidated by immutable ID and enabled status. A privileged SAM is not rescued by a C/E UPN.
Step I uses the Windows process login's regular-account hint, never the Graph identity; preview Y confirms, N changes
username, R shows recent, S searches, 0 cancels, default N. Recent entries are convenience, not assignment proof.

Displayed-result limit and page size are separate: page size defaults 100 (1-999), optional page limit 10 (1-100).
At the bound, refine the search; an empty bounded result does not prove absence. Ranking favours exact identity/name,
then phrases/prefixes/fragments. One-edit suggestions follow exhaustive empty literal results but are not exhaustive
typo discovery. Recent users remain most-recent-first; all selections require fresh Live validation.

### Scanner Serial Normalisation

Ordered runtime rules preserve valid plain serials or extract one unambiguous URL component, then display the
canonical serial for confirmation. The MyDell rule extracts `6H70TH4` from
`https://www.dell.com/support/pid?s=q3&t=6H70TH4`; wrong host/path, repeated/missing t or invalid formats are rejected.
Canonical serials drive lookup, duplicate checks, storage and audit. Avoid retaining full scanned URLs unnecessarily.

### Hardware Hash Import

When Live A cannot find the device, enabled hash import offers CSV selection; both import and final upload default No.
Zero/Enter cancels. Declining retains the external portal handoff. No later preparation proceeds without unique
matching Autopilot presence.

Runtime discovery uses `searchDirectories`, `filenamePrefixes`, `includeRemovableMedia` and `removableSubdirectories`.
Supplied discovery searches `hashes` beside the loaded runtime file and removable-drive locations using literal
Autopilot/HWID/DeviceHash/HardwareHash prefixes. It is non-recursive and refuses folders exceeding 200 CSV files;
a manual path remains available.

The CSV must be readable, at most 8 MiB, with Device Serial Number/Hardware Hash columns, no duplicate serial rows,
exactly one matching workflow serial and valid non-empty base64 hash. This validates encoding, not ownership.
Review tenant and serial, then explicitly approve upload. A final fresh presence check prevents uploading an
already-present device; CSV user/tag values do not override workflow intent.

A hash-free import receipt is saved before one POST. Pending/partial/unknown remain Submitted; Complete additionally
needs a registration ID and fresh matching Autopilot presence. Recheck A to reconcile saved intent without another
upload. Uncertain or malformed receipts need owner review; never remove one to force resubmission. Protect source CSVs.

Import evidence is kept inside each device record as an append-only `ImportSubmissions` ledger (IMPORT-RECEIPTS, owner
decision 2026-11-03), mirroring the sync ledger. A `Submitting` entry is saved before the upload and an `Accepted`
entry once Microsoft Graph returns the Autopilot import ID; earlier entries are never edited or removed, and the latest
entry is the current receipt. Entries hold eight hash-free fields plus `RecordedAt` (and `Source` when migrated); a
hardware hash or any other field is refused. If the `Submitting` entry cannot be saved, nothing is uploaded.

Older versions wrote a separate `autopilot-import-submission-<RecordId>.json` journal per record. In Live mode, startup
migrates each journal into its matching record (same RecordId and serial, and tenant when the record has one), saves
the records once, and only then deletes the migrated files. Unreadable, malformed, hash-bearing, unmatched or renamed
journals, and journals with an interrupted-save artefact, are kept and logged as WARN for review. The migration is
idempotent; Demo mode does not touch the files.

### Polling and Transport

| Script setting           | Default              | Range |
| ------------------------ | -------------------- | ----- |
| MaxRetryAttempts         | 5 verification reads | 1-20  |
| RetryBackoffSeconds      | 3                    | 0-60  |
| TransportMaxAttempts     | 3 GET attempts total | 1-5   |
| TransportBackoffSeconds  | 3                    | 0-60  |
| TransportMaxDelaySeconds | 60                   | 1-300 |
| TransportTimeoutSeconds  | 60                   | 1-300 |

First verification is immediate, with no delay after success/last read. Group Tag/membership deliberately use just
one immediate check then later read-only rechecks. Wrapper GET retries cover structured 429/503/504 only;
valid Retry-After is honoured, excessive/invalid waits refuse. POST/DELETE are not automatically retried. SDK retries
are zero with a configured timeout, set once per session. Bounds are not an overall workflow deadline or propagation SLA.

### Pasted-Code Execution

Prefer the saved entry script. In an approved IDE/ISE context keep both definitions; an explicit definition folder is:

```pwsh
$env:AutopilotExpressDefinitionDirectory = 'C:\Approved\AutopilotExpress'
```

The override selects configuration, not a policy bypass. Stale inherited repository-root variables do not establish
storage authority. FullLanguage is required for the OS lease; do not weaken corporate policy to enable it.

## Quick Remediations and Intune Links

1. Open Settings > 5 under approved tenant-read access. Retrieve the catalogue, toggle required package IDs and
   explicitly Save with Y/default No. Nothing starts enabled. N/P pages; 0/Enter cancels. Unavailable IDs stay
   removable, but cannot run. On dirty exit Y saves, N discards, C continues; default N.
2. Open Bench A or Device Commands > 6. Choose 1 Run, 2 Check saved request, 3 Copy Intune overview link or
   4 Choose quick-run remediations. Completed records are available; removed records are excluded.
3. For an approved run, review tenant, serial, fresh managed-device ID and package name/version/ID. Confirm Y/default
   No. The tool rechecks the target and baseline report, saves intent, then attempts one POST. Save failure sends nothing.
4. Check the saved request explicitly. Accepted is not Started or Successful. ExecutionObserved requires a fresh
   terminal report later than baseline/submission; detection and remediation results remain separate. A scheduled
   or concurrent execution cannot be conclusively distinguished from this request. Do not replay uncertainty.

These beta Graph utilities never advance workflow/checklist completion. Catalogue/report reads use
`deviceHealthScripts`/`deviceRunStates`; execution uses `initiateOnDemandProactiveRemediation` with `scriptPolicyId`.
Tenant consent, Intune RBAC, licensing and package/device acceptance remain required.

Option 3 copies/read-backs the freshly resolved Intune overview URL on **this technician PC**, not the device.
Use the displayed tenant. Clipboard success is not proof the portal opened. Demo leaves the real clipboard unchanged.

Preferences/request evidence live under `%LOCALAPPDATA%\PowerShellScriptingNew\AutopilotExpress\DeviceActions`,
separated by Windows profile, tenant and mode. There is no TEMP fallback. Guarded revisions and `.access.lock`
serialise normal saves; the file's existence alone is not active ownership. Retain previous/pending/write markers
and unresolved Preparing/Accepted/Uncertain intents. Archiving a session does not clear them.

### Remediation Access Recovery

1. Check the loaded runtime path in startup diagnostics. Deploying a script does not replace an older tenant JSON.
   Merge the approved `DeviceManagementScripts.Read.All` into `graph.requiredScopes` if absent; preserve other settings.
2. Have the administrator check delegated consent for the actual Graph application/client and tenant, plus roles,
   licensing and policy. Submission also needs `DeviceManagementManagedDevices.PrivilegedOperations.All`.
   Do not request broader write access merely to fix a read denial.
3. Restart after file edits. If only consent changed, explicitly reconnect through Settings > 9. Switching login
   method or repeatedly selecting the menu does not grant permission.
4. Under read approval, confirm Settings > 5 loads and save intended selections. Only under separate execution
   approval run a package for the confirmed device, then use Check saved request.

HTTP 403 is not an empty catalogue or evidence a remediation POST failed. Readiness warnings leave unrelated build
work available. Do not delete request/history files, auto-consent or repeat an uncertain execution to troubleshoot.

## Document Production and Template Authoring

The system populates copies of the two reviewed DOCX templates and exports PDFs through desktop Word. It never
saves changes to the originals. Testing now defaults to `EnforceDocumentGuards=false`
for both certificates and checklists: unapproved profiles may generate and request
printing without changing their approval metadata. Demo page labels still state
NOT LIVE CERTIFICATION. Explicit review-only requests do not print. Restore
DRAFT/print restrictions with Settings > Document output settings > `[G]`, or the
CLI parameter `-EnforceDocumentGuards $true`. A generated document does not approve
the device, template or underlying evidence.

### Generate and Find Documents

1. In Settings > 6 enable either output, independently off by default. Select Review to inspect a PDF or
   GenerateOnly to retain a PDF without opening. Run the disclosed prerequisite check before dispatch.
2. Complete D/DISPATCH or permitted DO. Jobs queue only after dispatch is saved; document failure does not undo it.
3. Review results. OpenRequested means Windows was asked to open a PDF, not that it rendered. PrintRequested is
   not paper output; opening a checklist does not prove it was saved. While the build bench is open, each finished
   or failed job appears in "Recent results and messages" as one event with its position, serial, CI and build
   cycle (for example `Documents Completed: BirthCertificate Succeeded; Checklist Failed`). The event survives
   redraws; `[L]` shows the PDF paths, warnings and retry guidance. Collection never prompts, saves workflow
   state or reads scanner input.
4. Find PDFs under `%LOCALAPPDATA%/PowerShellScriptingNew/AutopilotExpress/Documents`, separated into Demo or
   Live-tenant Output folders. Names use exact serial and saved dispatch date, e.g. `ABC123_261026.pdf`.
   Type-only suffixes resolve collisions without overwriting; an occupied suffixed name fails safely.
5. Correct an output failure and use Settings > 6 > J for document-only retry. Do not redispatch or replay Graph.
   Review prior delivery intent before approving anything that could repeat an open/print request.

Dispatch does not enable documents. When session output is disabled, D and DO save the dispatch without creating
a document job; the application now reports this explicitly. In Settings > 6, check option 1, select Review under
option 3, then run option 7 before the next dispatch. Option 8 saves preferences separately for this Windows user,
mode and tenant; without that save, session changes do not become next-run defaults. CLI pins can override them.

Enabled output is checked before device-session setup and again after output-setting changes, preference saves
and CLI-pin release. A failed check retains its stage/diagnostic in the timestamped transcript and offers retry,
exit or C/default to continue without documents for this session only. Saved preferences are unchanged by C.
Internet-marked local module/worker files require exact-path/fingerprint review and separate Y/default No consent;
no execution-policy change or publisher approval is performed. A readiness pass is not Word/PDF/print acceptance
and does not change template approval or the separately selected guard setting.
See [deployment trust limits](SETUP.md#deployment-owner-prepare-access-and-dependencies).

Enabling output later does not generate documents for earlier dispatches. Option J retries current jobs and
rediscovers retained prequeue failures for the same Windows actor, mode and tenant. Enabled-output failures,
including failed prerequisites, staging exceptions and a missing worker handle, retain a detached dispatch
snapshot and the original available dispatcher/site context under the scoped `Attempts/` directory. Storage
failure retains the attempt in this session and logs that durable recovery is unavailable. Malformed, foreign
or interrupted evidence is retained for review, not silently repaired or executed.

Select the retained attempt and explicitly approve the default-No document-only retry after prerequisites pass.
Retry uses the retained dispatch and identity context, not the current operator's identity; it never redispatches
or replays Graph. J also lists the newest 20 completed document jobs from validated receipts in this actor's
scoped `Output/` folder, and up to 10 completed dispatches with no document job found. Selecting a completed
job's ID never replays that job; it starts a fresh reprint for the single matching record and build cycle, or
refuses when no single match exists. Malformed or foreign receipts are skipped and logged for review. If outputs
were disabled or no retained attempt exists, use Settings > Document output settings >
`[P]` to select the existing confirmed dispatch. Choose `[B]` certificate, `[C]`
checklist or `[A]` both, then `[G]` PDFs or `[P]` generation and printing.
Printing requires separate default-No consent. A legacy blank build-cycle ID requires
separate consent to save an audited identity without changing steps or dispatch dates.
Do not reopen, redispatch or edit completion evidence to manufacture a job.
Check mandatory identities before recovery: DO retains incomplete steps and does not waive required document fields.

Both enabled PDFs export before delivery. Interactive desktop Word and verified libraries are required; the tool
does not install Office or upgrade Graph. Prepared workers can reduce delay, but consistent generation and visible
opening within ten seconds remain unproven. Checklist saving to a network/SharePoint destination is manual.

```plaintext
Document output settings
|-- [G] Template guards                  # OFF by default; toggle both outputs
|-- [P] Existing dispatched device       # no redispatch or tenant changes
|   |-- [B]/[C]/[A] Document selection   # certificate/checklist/both
|   |-- [G]/[P] Delivery                # PDFs only/print request
|   `-- [0] Return                      # cancel without generation
|-- [J] Retained attempts and retry      # review prior delivery intent
|   |-- Failed/retained attempts         # default-No document-only retry
|   |-- Completed jobs (newest 20)       # selecting routes to fresh reprint
|   `-- Dispatches without a job         # use [P] to generate
`-- [0] Return                           # caller owns navigation
```

### Document Output Controls

```plaintext
Settings > 6. Document output settings
|-- [1] Birth certificate            # Independent enablement; initially off
|-- [2] Checklist                    # Independent enablement; initially off
|-- [3] Certificate policy           # AutoPrint default when enabled
|-- [4] Checklist policy             # Review default when enabled
|-- [5] Worker deadline              # 60 seconds; range 1-3600
|-- [6] Failed-job retention         # 7 days; range 0-3650; 0 disables failed expiry
|-- [7] Check prerequisites          # Disclosed pinned-library acquisition; Default Yes
|-- [8] Save Preferences             # Separate Y/default No; session edits otherwise stay local
|-- [9] Release CLI pins             # Explicitly permit session overrides
|-- [G] Template approval guards     # OFF by default for both outputs during testing
|-- [J] Review/retry documents      # Current jobs and retained attempts; default No
|-- [P] Existing dispatched device  # Generate/reprint without redispatch
`-- [0] Return                       # No implicit save
```

| Policy         | Behaviour                                                                     |
| -------------- | ----------------------------------------------------------------------------- |
| Disabled       | Suppress the profile even if its enablement switch is on.                     |
| GenerateOnly   | Retain PDF, no viewer or printing.                                            |
| Review         | Retain PDF and request opening through its Windows association.               |
| GenerateAndAsk | Await explicit foreground print approval; no worker prompt or implicit print. |
| AutoPrint      | Request PDF printing to the current default printer, only when permitted.     |

With guards OFF, unapproved profiles and Demo documents can request printing under the chosen policy; Demo pages
remain labelled. Explicit review-only requests never print. Turning guards ON restores DRAFT/non-printing output for
unapproved profiles and prevents Demo printing; it does not silently change the policy to Review. Neither setting
changes template approval. Missing handler/printer support retains the PDF with a diagnostic. Durable receipts record
intent before delivery; Requested/Uncertain actions are never replayed automatically. Explicit retry uses the
original detached data; corrected templates are freshly snapshotted and the failed attempt retained. Delivery-only
retry can reuse a published hash-verified PDF.

CLI pins are `BirthCertificateEnabled`, `ChecklistEnabled`, `EnforceDocumentGuards`, `BirthCertificateMode`, `ChecklistMode`,
`DocumentWorkerTimeoutSeconds`, `DocumentFailedJobRetentionDays`. Precedence is defaults < runtime < saved <
session < CLI; explicit false disables. Releasing pins does not save preferences. Template paths resolve against
the application root, not the current working directory.

```plaintext
Documents/
|-- Dependencies/                    # Reusable verified pinned libraries
|-- Preferences/                     # Explicit per-technician preference saves
|-- MigrationLog.json                # Present after explicit legacy-review reorganisation
`-- Demo/                            # Live-{tenant GUID} is separately isolated
    |-- Output/Serial-{serial}_CI-{ci}/
    |                                # Final PDFs and compact Job-{GUID}.receipt.json
    |-- Working/                     # Active owned staging or deferred diagnostic cleanup
    |-- FailedJobs/                  # Intact failed/unknown evidence
   |-- Attempts/                    # Bounded prequeue failure snapshots; explicit retry only
    `-- Review/                      # Deliberately retained review DOCX/PDF copies
```

A successful two-output job normally retains two PDFs and one receipt. Digest-verified successful staging is
removed; unknown, active, uncertain or changed-hash files are not. Failed expiry is reversible; zero disables it,
not successful cleanup. The job menu rediscovers prequeue failures but is not a catalogue of every retained worker
job after restart. Attempt snapshots are retained; no new automatic expiry or deletion is applied to them.
Never terminate Word by name or delete unknown job files. Legacy-review reorganisation is an explicit maintenance
operation, not permission to clean operational data.

### Supported Template Methods

| Profile          | Default source relative to application root                                                                    |
| ---------------- | -------------------------------------------------------------------------------------------------------------- |
| BirthCertificate | [templates/Autopilot Birth Certificate - v1.5.docx](templates/Autopilot%20Birth%20Certificate%20-%20v1.5.docx) |
| Checklist        | [templates/Autopilot Checklist - v1.5.docx](templates/Autopilot%20Checklist%20-%20v1.5.docx)                   |

Templates use reviewed structural bindings, not arbitrary mail merge or a general expression language. A field in
the job is not automatically a Word placeholder. New fields, repeated markers, moved targets, new barcode slots
or controls require a [profile change](Modules/Documents/Public/Get-AutopilotDocumentTemplateProfile.ps1) and tests.
Changed files are structurally revalidated; a new hash is not approval of a layout.

Keep mapped paragraph markers alone in their existing paragraphs. Preserve literal occurrences, native control
tags/IDs, row labels and table dimensions. Word-split formatting runs are supported; moving a marker into a header
or footer is not a body binding. The generated review footer is managed separately and must not imply approval.

### Available Text and Date Fields

Use these exact certificate markers in their reviewed locations, not the canonical value names:

| Marker                                | Canonical value          | Source and behaviour                                                                                                                 |
| ------------------------------------- | ------------------------ | ------------------------------------------------------------------------------------------------------------------------------------ |
| `{ci}`                                | ConfigurationItem        | Exact saved CI; required.                                                                                                            |
| `{serial}`                            | SerialNumberOrServiceTag | Exact saved serial/Service Tag; required.                                                                                            |
| `{dispatch_user}`                     | TechnicianName           | Dispatching person's given name/surname, human display-name fallback; required. Not the imaging technician, Windows username or UPN. |
| `{sitename}`                          | SiteName                 | Selected site's full name; missing stays blank and manual location suffixes are not invented.                                        |
| `{assigned_user_username}`            | AssignedUserName         | Saved final user's UPN prefix before `@`; required when assignment is required. Not a new SAM lookup.                                |
| `{assigned_user_first_and_last_name}` | AssignedUserFullName     | Saved final user's given name/surname, display-name fallback; required when assignment is required.                                  |
| `{intune_host_name}`                  | IntuneHostName           | Inventory bound to this cycle, tenant and mode; otherwise blank.                                                                     |
| `{intune_wired_mac_address}`          | EthernetMacAddress       | Wired MAC from that bound inventory; no wireless substitution.                                                                       |
| `{dispatch_date}`                     | Saved DispatchedAt       | `DD/MM/YYYY`, e.g. `26/10/2026`; regeneration does not change the date.                                                              |

The checklist maps the native text control tagged `Technician Name` and `{dispatch_date}` only from this field
list. Its completion controls are native Word checkboxes, not typed box characters. Certificate barcode/text
markers cannot simply be copied into it.

Missing required values fail only that document. Employee number, destination/room, licence, Imprivata,
critical-device/prior-CI details and installation/CMDB/verification sign-offs have no supported author-added markers.
They remain manual, not guessed. Build notes are manual except the mapped DO disclosure.

### Render Identifier Barcodes

Curly braces show readable text; square brackets become a caption-free Code 128 image encoding the exact value.
Keep them in separate existing cell paragraphs. No font installation, checksum or Word MERGEBARCODE field is needed.

| Barcode marker               | Exact payload                                  | Readable marker              |
| ---------------------------- | ---------------------------------------------- | ---------------------------- |
| `[ci]`                       | ConfigurationItem                              | `{ci}`                       |
| `[serial]`                   | SerialNumberOrServiceTag                       | `{serial}`                   |
| `[intune_host_name]`         | Bound IntuneHostName                           | `{intune_host_name}`         |
| `[intune_wired_mac_address]` | Bound EthernetMacAddress, including separators | `{intune_wired_mac_address}` |

- Payloads must be 1-80 printable ASCII characters; invalid/oversized values fail, without truncation/substitution.
- Missing optional inventory omits its barcode with a diagnostic. Missing required CI/serial fails the document.
- Valid text may still be too wide. A fit-only omission retains readable text and reports the omission; it is not a scan pass.
- Each current slot is 4000 by 600 twips, about 70.6 by 10.6 mm before margins/spacing. Preserve integer-width bars
  and at least ten narrow modules of quiet zone on each side. Not every valid 80-character value fits.
- Fit uses a 300-DPI reference grid: modules must be at least 3 pixels (0.254 mm) wide, and bar height must be
  at least 75 pixels (6.35 mm) or 15 percent of symbol width, whichever is greater. Higher sampling does not relax
  these physical limits.
- Images use 600-DPI sampling at unchanged physical bounds. Do not crop, compress, shrink bars, reduce quiet zones
  or resize rows/tables to force a fit. Geometry changes need profile and rendered-output review.
- The saved PNG is decoded back to the original value. This does not establish final-PDF or physical readability;
  decode the exported PDF and obtain separately approved printer/scanner acceptance.

The checklist has no barcode slots. QR codes, other symbologies and arbitrary new fields are unsupported.

### Mark Completed Work

Place one directive alone in a paragraph in the final result cell of a reviewed three-column certificate row,
or a checklist row containing exactly one reviewed native checkbox. Preserve its guide label/control.

```plaintext
{complete:C}
```

```plaintext
{complete:H,I,J,K}
```

Use uppercase A-O, comma-separated without spaces or duplicates. Letters are saved workflow IDs, not printed guide
numbers. Unknown steps, mixed title/marker text, ambiguous targets, duplicate or misplaced markers fail validation.

Every listed step needs successful, non-simulated current-cycle Verified or TechnicianConfirmed evidence between
cycle start and dispatch. **Technician-confirmed manual steps qualify.** An explicit directive defines the row's
tracked-step requirements instead of its baseline untracked-work classification; it never relaxes evidence checks.
The last listed step is trigger metadata, not a substitute for the rest.

| Certificate guide row | Current explicit steps | Result                                                   |
| --------------------- | ---------------------- | -------------------------------------------------------- |
| 2-4                   | A,B,C                  | Y only when all qualify.                                 |
| 5                     | D                      | Y only when D qualifies.                                 |
| 6-12                  | E,F,G                  | Y only when all qualify.                                 |
| 13-15                 | H,I,J,K                | Y only when all qualify, including manual confirmations. |
| 16-20                 | L,M,N                  | Y only when all qualify, including manual confirmations. |
| 21                    | O                      | Y only when O qualifies.                                 |
| 22 and 23-25          | Unmapped               | Blank; no inferred ZENworks/CMDB/disposal completion.    |

The marker disappears; qualifying Live rows receive Y or a checked native checkbox. Missing, incomplete, stale,
blocked, submitted-only or simulated evidence stays blank/unchecked. Demo cannot certify Live work. DO supplies no
completion evidence. Without a directive the row retains its conservative baseline mapping/untracked-work protection.
For example, incomplete H leaves only its H/I/J/K group blank even if I/J/K are complete and DO was used.

### Show the DO-Only Reason

Keep this exact existing certificate conditional in one paragraph. The closing parenthesis is intentional source
syntax; do not change it to a brace.

```plaintext
{If dispatch_override_reason used}Incomplete steps overridden for following reason:{dispatch_override_reason}{End if dispatch_override_reason used)
```

| Dispatch                             | Generated disclosure                                                                       |
| ------------------------------------ | ------------------------------------------------------------------------------------------ |
| Normal D                             | Entire paragraph empty, even with a stray reason value.                                    |
| DO                                   | `Incomplete steps overridden: {saved reason}`, once, using the full matching saved reason. |
| DO without matching non-blank reason | Job construction fails; no invented reason.                                                |

The reason comes from CompletionOverride at the saved dispatch timestamp, not a later prompt/edit. Markers do not
remain in the PDF. This is one mapped conditional, not general IF/ELSE/nesting support, and does not earn any Y.

### Edit and Validate a Template

1. Keep a versioned backup. Edit the configured source, not a PDF, working snapshot or retained review copy.
2. Preserve reviewed tables, page dimensions, paragraph locations, labels, native controls and embedded objects.
   Use only supported markers; additional/moved fields or geometry need a reviewed profile change and tests.
3. Generate an isolated synthetic DRAFT using the [document validation procedure](TESTING.md#document-generation-validation-plan).
   Demo rehearses layout, not positive Live completion; synthetic Live evidence must never enter operational records.
4. Compare populated values, optional blanks and longest realistic fields. Check two certificate pages, readable
   unclipped text, labels, unchanged layout and exact final-PDF barcode payloads.
5. Test all-complete versus incomplete groups, normal D with no disclosure and DO with its full exact reason.
   Confirm no unresolved marker remains and no manual sign-off was inferred.
6. Retain failures and correct the source/mapping. Only the exact approved checklist drawing-ID exception set is
   allowed; do not broaden it or approve a new hash just to bypass validation. Obtain final/physical acceptance separately.

Each new job snapshots the current saved templates. Changed bytes invalidate prepared caches; no older approved
copy is silently substituted. One invalid document does not prevent the other valid output.

### Document Troubleshooting

| Symptom                            | Action                                                                                                               |
| ---------------------------------- | -------------------------------------------------------------------------------------------------------------------- |
| Nothing generated                  | Check enabled output, policy, prerequisites and committed dispatch.                                                  |
| Literal/blank field                | Check exact marker, profile and original placement; unsupported fields need profile review.                          |
| Missing hostname/MAC               | Check inventory binding to the same tenant/mode/cycle; do not substitute guessed data.                               |
| Technician/user failure            | Supply the actual dispatching human name and required saved final-user values.                                       |
| Completed group blank              | Check every listed step, timestamps/cycle, Demo state and marker placement; last-step success or DO is insufficient. |
| Wrong override disclosure          | Stop using the PDF; preserve source/job/output. Normal D must be empty; DO needs the matching saved reason.          |
| Barcode omitted                    | Read missing-data/fit diagnostic; retain readable value and seek geometry review, not smaller bars.                  |
| Three certificate pages            | Inspect long values/reason, wrapping and layout. The two-page export guard must not be bypassed.                     |
| Template invalid                   | Correct source/mapping, retain failed evidence and retry documents only.                                             |
| PDF opened but checklist not saved | Save manually to the approved destination; no automatic upload exists.                                               |
| Timeout/uncertain cleanup          | Preserve diagnostics. Never kill every Word instance or delete active/unknown files.                                 |

## Data, Session Recovery, and Audit

Local mode stores device/bench/recent-user records per Windows user/mode and a common local Live master audit.
Normal root is `data/` beside the resolved definitions; fallback is
`%LOCALAPPDATA%\PowerShellScriptingNew\AutopilotExpress\data`. Once authoritative, fallback stays authoritative.
Never merge roots or choose a file by timestamp. New session files use a stable original-start `YYYYMMDD-HHmm-`
prefix and collision-safe identity; the per-user/mode index selects the exact device/bench pair. Legacy names remain.

### Automatic Device Inventory

After successful reseal G, eligible active Live records retry missing hostname/primary Ethernet MAC every five
minutes at safe menu/bench prompts. `InventoryPollingMinutes` accepts 1-1440, default 5. Actions, confirmation and
selection suspend polling; recovery/removed/completed records are excluded. D/DO makes a final read after confirmation.

Inventory requires matching tenant, managed-device ID, serial and known Entra identity, with build-cycle/mode
provenance. It is distinct from Autopilot's convenience device name. Empty same-identity reads retain captured data;
changed identity/cycle starts fresh. No Wi-Fi/derived MAC is substituted. A checkpoint save precedes announcement.
If idle save fails, polling pauses and the completed input line is discarded before the failure stops execution.

Missing fields warn but do not block dispatch; a failed final save publishes neither inventory nor dispatch changes.
Demo invents no hardware. Polling does not force service freshness: Intune's inventory cadence and primary-adapter
semantics still apply. Verify docks/pass-through against the intended network-platform requirement.

### Updating Device Details from Intune

Data Settings > 5 goes back to Intune for devices that have already been through the
process, and fills in any details that are missing. It is only available in Live mode
while signed in; use Session and Script Settings > 9 to reconnect first if needed.

```plaintext
Update device details from Intune
|-- 1. Check missing details                    # Default; skips devices marked not found
|-- 2. Also recheck devices not found last time # Includes previously not-found devices
`-- 0. Cancel                                   # Nothing is read or saved
```

It checks the current session and every archived Live session in the archive folder,
including other technicians' sessions. It fills in the hostname, Ethernet MAC, Wi-Fi
MAC, Entra device ID, primary user and Windows version and release. Details already
saved are never overwritten with blanks. Devices that are complete, have no tenant
recorded, or belong to a different tenant are skipped without contacting Intune.

A device that no longer exists in Intune is marked as not found and keeps its saved
details. Devices still being worked on in the current session are never marked as not
found. When finished, it shows how many devices were checked, updated, not found,
skipped or failed, and which files were saved.

Before an archive file is changed, its original is kept beside it with a
`.before-intune-details-<date-time>` suffix. An archive that changed on disk while
the update was running is left untouched. The updated details also appear in the
session report (Data Settings > 3).

### Session Report Exports

Data Settings > 3 offers 1 CSV, 2 HTML, 0/Enter cancel, then explicit Y/default No. Empty sessions create nothing;
more than `ReportWarningRowCount` rows (default 1000) warns. Reports include unfinished/removed records, deduplicated
by record ID and sorted by serial/ID. They contain dispatch proof, working minutes, step states and captured inventory
with provenance, not raw attempts, tokens, hardware hashes or searched-user lists.

Reports use unique names under `%LOCALAPPDATA%\PowerShellScriptingNew\AutopilotExpress\reports`, TEMP only if
LOCALAPPDATA is absent. Guarded writes/read-back retain pending/write markers on failure. CSV quoting/formula-prefix
neutralisation and HTML encoding apply to exports only; source evidence is unchanged. No tenant query, automatic
viewer, archive search or external-system schema is implied. Protect exported identifiers.

### Resume and Audit Evidence

Startup Resume defaults Y; N immediately archives the current pair and starts fresh without a second confirmation.
Data Settings > 2 instead offers the one current-user/mode pair, default cancel, then No and CLEAR/CANCEL safeguards.
Confirmed archive saves/moves current and previous files, resets active work and prompts for site/bench; it does not
reconnect Graph. Both paths preserve audit, recent users, receipts, legacy import journals, work patterns and other users/modes.
Partial archive retains its marker and blocks reuse.

Normal saves retain attempts and reject history/audit truncation or rewriting. Explicit dispatch flag/time/actor,
not completed status, drive audit/statistics. Five transient bench summaries and a transcript are not a committed checkpoint.

### Local Session Reservation

A Windows-exclusive open `.session.lock.lease` handle reserves one root/mode before loading/authentication;
`.session.lock` holds readable ownership metadata. The lease sidecar persists: its existence is not active ownership.
FullLanguage is required. Separate computers/copied roots do not coordinate the same device.

```plaintext
Storage reservation recovery
|-- R. Retry                       # Reattempt exclusive acquisition
|-- C. Back up and recover         # Only verified recoverable local ownership
`-- 0. Return                      # Default; no authentication or workflow actions
```

C requires explicit confirmation that all store users stopped, default No, and verified complete backups before
reacquisition. Active/foreign/reparse-backed/unverified owners cannot be bypassed. Legacy metadata checks process
start time to distinguish a stopped/reused PID; never terminate the original host or a PID copied from another log.
Version-two recovery relies on exclusive lease acquisition, not age. Remaining checkpoints/markers still block startup.

On the owning computer, from a fresh approved host, use the exact path printed by startup. For normal Live storage:

```pwsh
$lockPath = Join-Path $PWD 'data\autopilot-express-live.session.lock'
.\autopilot-express.ps1 -SessionLockAction Inspect -SessionLockPath $lockPath
```

Inspection is read-only and never authenticates. Only after confirming every relevant session stopped and ownership
is recoverable:

```pwsh
.\autopilot-express.ps1 -SessionLockAction Recover -SessionLockPath $lockPath -ConfirmStopped
```

Recovery retains hash-verified full-session snapshots and lock originals under
`%LOCALAPPDATA%\PowerShellScriptingNew\AutopilotExpressRecoveryEvidence`, outside active discovery. Only exact OS
lease sidecars are excluded from the store snapshot. Copy/hash/inventory/ownership failure retains the reservation.
Successful recovery resumes existing work without an archive/reset prompt or tenant replay. No backup is automatically restored.

Backups are kept indefinitely (owner policy: keep all, organise). New session snapshots and crash-lock evidence are
filed as `<Kind>\<yyyy-MM-dd>\<tenant>\<original name>`, where `<Kind>` is `SessionSnapshots` or `CrashLocks` and
`<tenant>` is the store's single persisted tenant ID, `demo`, `tenant-mixed`, `tenant-unbound` or `tenant-unknown`.
The tenant folder is a filing aid only; it never binds or authorises a tenant. Data Settings > 4 pages a read-only size
report by kind, date and tenant. `[O]` then moves older flat backups into that layout after `[Y] Yes [N] No`
(default N). Moves keep original names, skip reparse-backed items and name collisions, are logged, and delete nothing.
Workflow-ID conversion backups are reported but never moved, because migration markers record their paths.

### Canonical Evidence Migration

Before sign-in, reserved startup offers action-aware conversion for version-one/missing workflow discriminators.
Y/default No retains verified complete/per-file originals, converts linked current/previous records and Live audit
for that reserved mode, then resumes. Other-mode evidence/bench bytes stay unchanged. Unknown versions, conflicting
actions, foreign reservations or unresolved checkpoints/write/archive markers refuse. Conversion requires PowerShell
7.5+ for exact date-string preservation; Desktop can load canonical records but cannot perform legacy conversion.

Explicit offline commands from the product directory have workspace immediate-data scope only:

```pwsh
.\autopilot-express.ps1 -MigrateWorkflowIds
```

After approved rehearsal and stopped sessions:

```pwsh
.\autopilot-express.ps1 -MigrateWorkflowIds -ApplyWorkflowMigration
```

These exclude archives, fallback roots, retained originals and unrelated journals/receipts. Keys and nested references
convert simultaneously by semantic action; dates, notes, identities, accepted intent and history remain. A repeated
conversion is a byte-stable no-op. Failed promotion retains a blocking marker; multi-file atomicity is not guaranteed.

### Interrupted Save Recovery

Single-file writes retain `.write-in-progress`, verified `.pending` and `.previous` evidence; multi-file saves stage
a detached record/audit/bench checkpoint. Targets may be at different committed stages after failure. Missing targets
with previous copies, orphaned pending files and write/archive/migration markers block startup rather than invent empty work.

1. Stop every CLI for the root/mode and resolve ownership.
2. Preserve targets, checkpoint, markers, pending/previous copies, receipts and legacy import journals with names/timestamps.
3. Have the recovery owner use read-only checkpoint inspection and compare proposed/actual files, identities, tenant,
   steps/history, bench and audit. Newest timestamp, valid JSON or highest revision is not commit proof.
4. Under separate approval inspect tenant changes that may have succeeded before the save failure.
5. Obtain a reviewed consistent-state recovery decision, retaining originals outside discovery. Restart and verify
   records/bench/audit before continuing; without trustworthy state, stop and escalate.

Never delete markers/journals just to bypass a guard or trigger another submission. There is no automatic rollback,
replay, reconciliation, fsync or physical power-loss/multi-file atomicity guarantee.

### Data Integrity and Authorised Corrections

Use RESTORE for removed undispatched work, RESTART for a legitimate new cycle and U for eligible mistaken physical
confirmation. Suspected damage/external edits need stopped writes, original files/hashes and a field-level review.
An exceptional repair requires approval, actor/time/reason, original/proposed values and validation; no arbitrary
repair editor is implemented. Do not fabricate completion, timestamps or verification to improve statistics.

Local checks detect malformed/inconsistent evidence, not coordinated rewriting by someone with filesystem/script
access. Same-folder hashes, DPAPI or a same-user HMAC key cannot authenticate against that user. A protected
append-only external authority would be needed for independent audit authenticity; none is implemented.

### Shared Storage: Deferred

Shared is disabled/refused, not silently replaced by Local. Do not activate it for initial imaging. Offline prototype
helpers are not distributed ownership, atomicity or network durability qualification. Backend approval, permissions,
consistent migration and real concurrency/disconnect/recovery acceptance are prerequisites; see
[the maintainer contract](TECHNICAL.md#shared-development-contract).

## Working-Time Policy

My Stats counts currently completed records with explicit proven normal/override dispatch, once on the latest
Windows-local dispatch date. Removed/incomplete/undispatched records do not count. Legacy CompletedAt alone is
insufficient; only matching explicit override evidence can supply legacy proof. Reopening invalidates current proof.

The opening view shows the current site's Monday-to-today counts followed by its all-time overall counts.
P selects the previous Monday-Sunday period across all sites: a weekly overall table is followed by each site
with transactions that week, even when only one site has data. The full period is labelled; tables contain only
transaction dates, not invented zero-day rows. N moves forward when viewing earlier weeks; C restores the current
site/current week. When the eligible dataset contains multiple sites, S selects a site's current week and O its
all-time overall. Zero/Enter returns. Empty periods are disclosed, and an entirely empty dataset remains visible
until acknowledged. Changing these views never changes dispatch or workflow evidence.

Average/Min/Max use valid induction-to-dispatch working-time samples as `Dd HH:mm`; totals average samples, not daily
averages. Missing/reversed timestamps show N/A and a sample disclosure. This estimates elapsed imaging time, not labour.

The base window is Monday-Friday 08:30-17:30 local time. Evidenced exceptional dates/late actions extend applicable
windows; after the final late action, counting pauses until the next recorded load/action. Friday 16:30 to Monday
10:00 counts 150 minutes; Saturday 10:00 to Monday 10:00 counts 540. Monday induction 16:30, last action 19:00,
Tuesday load 10:00 and dispatch 12:00 counts 270. Missing historical loads are not invented.

Settings > 4 appends weekly schedules effective today/future, using YYYY-MM-DD, weekdays 1-7/NONE and same-day HH:mm
start/finish. Overnight shifts are refused. Past hours are locked; past Sick/RDO/WFH markings are allowed but cannot
be cleared to Scheduled. All three markings mean zero imaging minutes, including WFH. They recalculate estimates
without changing device events. Save needs Y/default No; zero/Enter cancels and failed saves publish nothing.

Work patterns are per Windows user/mode under the reserved root, with append-only effective history. Archive does
not reset them; malformed/foreign or unresolved-write history stops startup. Do not edit JSON to bypass this policy.

<a id="15-october-operational-incident"></a>

## Troubleshooting

For incident causes, delivered repairs and unresolved outcomes, see the
[maintainer incident record](DEVELOPMENT.md#incident-review). The procedures below cover diagnosis and safe recovery.

### Live Startup Failures

Use the stage, permitted status/request ID, host/SDK versions and source/config revision, not sign-in success alone.
The sequence is SDK sign-in, context, /me identity, matching organisation and read capabilities. Failed startup runs
no menu workflow. HTTP unavailable means no recognised status was supplied, not proof no request occurred.

| Failure                             | Action                                                                                                                |
| ----------------------------------- | --------------------------------------------------------------------------------------------------------------------- |
| Device-code instructions missing    | Use approved current source; instructions must reach the host. Keep active codes private.                             |
| SDK sign-in returned failure/cancel | Explicit D DeviceCode, B Browser or 0/Enter cancel; invalid input re-prompts.                                         |
| Context/tenant mismatch             | Verify intended pin/account; never clear the pin to bypass rejection.                                                 |
| /me or organisation failure         | Preserve stage/status; administrator reviews minimum delegated access and intended organisation.                      |
| Read preflight failure              | Review the named capability, configured scopes, roles/policy and exact target. Reads do not establish write approval. |
| Repeated prompts                    | Retain approved SDK/Entra sign-in evidence. Fewer requests/device-code preference do not prove the cause fixed.       |

Device-code output must not be discarded: SDK 2.41.1 emits instructions on the success stream. The application routes
them to the host while keeping its Boolean result clean. Operator confirmation covers that repair, not every later
retry interaction. The application does not automatically switch flows; SDK-internal fallbacks are a separate
[contract limitation](TESTING.md#external-contract-audit). A menu cannot interrupt an SDK call still waiting.

After 401/recognised authentication failure, further requests pause until Settings > 9. A 403 needs access review,
not an automatic login loop. Reconnect revalidates identity/tenant and never replays work. Use a fresh approved
non-elevated host with coherent SDK modules; do not substitute DLLs, widen permissions or bypass policy speculatively.

### Saved Recovery History Failure

`Saved recovery history entries must be dictionaries` means a saved array contains a non-object. Current errors
identify one-based record/entry positions and type without exposing the entry. Preserve the related device/bench/
audit/checkpoint/previous/journal files and seek reviewed repair. Do not strip every null, reset the session,
repeat deletion or reinstall Graph. A preventive loader fix does not repair existing stored evidence.

### Bench Performance and Diagnostics

Use an approved Demo rehearsal with verbose phase timings:

```pwsh
.\autopilot-express.ps1 -Mode Demo -Verbose
```

Labels include Bench reconciliation/table, Master audit proposal, Checkpoint prepared/save, Inventory scan/polling
and Inventory prompt dispatched, in milliseconds. Nested timings must not be added together. Prompt dispatch ends
at BeginInvoke, not confirmed presentation; due Graph/save work can still delay processing input. Compare unchanged
entry, redraw and actual save separately, recording record/history/audit sizes and due inventory. Synthetic renderer
[measurements](TESTING.md#bench-performance-measurements) do not certify technician-perceived speed.

### Native Crash Diagnosis Procedure

The observed native `0xC0000006` is STATUS_IN_PAGE_ERROR, not an HTTP error. A UNC-loaded SDK is a lead, not proof
of the backing-file/I/O cause. DeviceCode avoiding a browser/WAM path is not a native-crash repair. Original-host
collection/reproduction requires separate approval.

1. Preserve transcript/capture, precise time/zone, process/start time, OS/PowerShell/.NET, mode, source/config hashes
   and actual SDK paths. Do not reuse PIDs from another log/computer.
2. Export original-host Application Error 1000 and WER 1001 with full XML/EVTX; correlate System storage/filesystem/
   paging/SMB events. Missing events do not rule out I/O failure.
3. Have an approved administrator configure restricted per-executable full dumps using
   [WER LocalDumps](https://learn.microsoft.com/windows/win32/wer/collecting-user-mode-dumps). Preserve old settings,
   check space/access and use the actual basename, normally pwsh.exe, not every application.
4. Reproduce only the approved authentication path, stopping before mutations. Record mode, time and loaded paths.
5. In approved WinDbg, inspect exception/context/stack and map the fault address to its backing file. For an in-page
   exception inspect the underlying I/O status, normally ExceptionInformation's third parameter, and correlate events.
6. If approved, compare the same coherent SDK version on local storage, changing one factor at a time. Never replace
   individual DLLs or assume one successful login proves repair. Remediate only the evidenced fault and restore dump settings.

| Administrator setting | Value                                                                         |
| --------------------- | ----------------------------------------------------------------------------- |
| Key                   | `HKLM\SOFTWARE\Microsoft\Windows\Windows Error Reporting\LocalDumps\pwsh.exe` |
| DumpFolder            | REG_EXPAND_SZ; restricted local folder, default `%LOCALAPPDATA%\CrashDumps`   |
| DumpType              | REG_DWORD 2 (full)                                                            |
| DumpCount             | REG_DWORD; approved small limit, e.g. 3                                       |

```text
!analyze -v
.exr -1
.ecxr
kv
lmf
```

Dumps may contain tokens and personal data. Keep originals restricted; return a redacted diagnostic summary with
exception/I/O status, mapped file/module, times, conditions and evidence references. A live dump is not a crash
exception record. Native stability, tenant actions and physical-build acceptance remain separate.

## Security and Privacy

Use approved accounts, tenant pin, least approved permissions and restricted filesystem/retention controls. Keep
credentials, hashes, personal records, transcripts and screenshots out of Git. Ignore rules reduce accidental
publication but do not redact or encrypt files. Review support copies; never share active codes, raw SDK bodies or dumps publicly.

Diagnostics retain safe status/request ID/exception type rather than untrusted service text. Local faults and
persistence errors still stop; they are not disguised as recoverable network failures. Manual and Demo evidence
must never be relabelled Verified. Security owner actions remain in [the backlog](TODO.md#retained-acceptance-and-approval-holds).

## Known Issues and Limitations

Actual SDK/tenant roles, policy, propagation, terminal accessibility and an end-to-end physical pilot still need
acceptance. Native host I/O diagnosis remains unresolved. Document profiles remain DRAFT; consistent ten-second
visible opening, final template approval, physical printing/scanning and manual-save acceptance remain outstanding.
Local multi-file recovery is not guaranteed power-loss atomicity or tamper-proof authority. Shared, all-machine
audit/search, remote machine-side installs, CMDB and automated external handoffs are not delivered.

## Support and Escalation

Use MWP + ITSOs Teams chat with serial/action, mode, host/SDK versions, source/config revision, exact inputs,
permitted code/request ID, record/checkpoint IDs and controlled evidence location. Preserve originals and stop on
uncertain state. The recovery owner and pilot approver decide when work may resume; never send secrets.
