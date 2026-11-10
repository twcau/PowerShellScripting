<!-- omit from toc -->
# Autopilot Express Technical Guide

This guide explains the current implementation and its trust boundaries. It is for maintainers, reviewers and
support staff diagnosing why an action, save or output is refused. [SETUP.md](SETUP.md) covers deployment and first
use; [OPERATIONS.md](OPERATIONS.md) covers procedures; [CUSTOMISATION.md](CUSTOMISATION.md) covers changes.
[FUNCTIONS.md](FUNCTIONS.md) documents all declared functions. Dated rationale, incidents and scope decisions remain
in [DEVELOPMENT.md](DEVELOPMENT.md); executable checks and evidence remain in [TESTING.md](TESTING.md).

## Contents

- [Components and Ownership](#components-and-ownership)
- [Configuration Ownership](#configuration-ownership)
- [Implementation Contracts](#implementation-contracts)
- [Startup and Shutdown](#startup-and-shutdown)
- [Records and Evidence](#records-and-evidence)
- [Workflow Execution and Evidence](#workflow-execution-and-evidence)
- [Graph and Identity Boundaries](#graph-and-identity-boundaries)
- [Persistence and Ownership](#persistence-and-ownership)
- [Shared Development Contract](#shared-development-contract)
- [Migration and Recovery](#migration-and-recovery)
- [Console and Background Work](#console-and-background-work)
- [Statistics Inventory and Reports](#statistics-inventory-and-reports)
- [Document Pipeline](#document-pipeline)
- [Failure Model](#failure-model)
- [Verification and Known Gaps](#verification-and-known-gaps)

## Components and Ownership

| Component | Responsibility | Not Its Responsibility |
| --- | --- | --- |
| [Entry script](autopilot-express.ps1) | Bootstrap, CLI, definitions, Local state, Graph controllers, workflow and document integration | Not a safely importable library or production approval. |
| [Manifest](autopilot-express.manifest.json) | Ordered enabled semantic actions, prerequisites, phases, display/guidance and descriptive permissions/routes | Not executable PowerShell or a plugin loader. |
| [Runtime definition](autopilot-express.runtime.json) | Tenant/group/profile, SDK/scopes, scanner/search/import, Demo and disabled Shared policy | Not saved action evidence or automatic tenant consent. |
| [Document module](Modules/Documents/AutopilotExpress.Documents.psd1) | 19 exported APIs, 23 private helpers, fixed workers and independent output receipts | No Graph/workflow writes; import alone performs no acquisition/rendering. |
| [Validation runner](development/Invoke-OfflineValidation.ps1) and tests | Synthetic/rehearsal contracts, exact-tool checks and external reports | Not real tenant, physical, network-storage or exhaustive path acceptance. |
| Controlled checklist and supplied templates | Governing physical procedure and reviewed output layouts | A filename/version is not owner approval or proof of completed work. |

The main script retains eight source regions rather than being split into independently importable modules:
Bootstrap and Diagnostics; Runtime Defaults and Record Shapes; Storage Authority and Persisted Evidence;
Console Input and Technician Navigation; Session Setup, Definitions and Graph Transport; Directory Selection and
Tenant Workflow Actions; Bench Eligibility, Dispatch and Presentation; Main Lifecycle. Regions aid navigation
without changing executable order, shared scope or fixture extraction.

There are 336 main-script and 42 document-module function declarations in the reviewed source snapshot. Nested
helpers are included. Five worker scripts and the module loader contain operational top-level code despite
declaring no functions. See the [source inventory](FUNCTIONS.md#source-inventory) for fingerprints and contracts.

## Configuration Ownership

Definitions load once; approved changes require restart. Edit policy at its source, never saved device evidence.

| Source                    | Owns                                                                                                                                      | Boundary                                                                       |
| ------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------ |
| Script Sites              | MI/MU/SU/GE/AL and full site names                                                                                                        | Reviewed selection/tag/default change.                                         |
| Script DeviceTypes        | Desktop/Laptop/WOW/NUC                                                                                                                    | Reviewed induction/tag/physical-guidance change.                               |
| Script Config             | Storage names, verification/transport/inventory/report defaults                                                                           | Preserve authoritative roots and compatibility.                                |
| Runtime JSON              | Tenant/profile/group, modules/scopes, C/E/search/recent/scanner/hash rules, Demo, disabled Shared contract and optional document settings | Tenant-owner review; no automatic scope widening or policy bypass.             |
| Manifest JSON             | Enabled action names, canonical IDs, execution/activation, prerequisites, phases, permissions/endpoints and guidance                      | Coordinate handlers and evidence; ID changes require migration.                |
| Manifest display metadata | displayCode (saved-ID fallback), summary/notes/details; recovery grouping                                                                 | Paging/custom-code tests; display changes do not rename saved evidence.        |
| Session site/type         | Defaults for new work/benches                                                                                                             | No migration of existing records/tags/membership.                              |
| Explicit user preferences | Work patterns, remediation selections and optional document overrides                                                                     | Preserve owner/mode/tenant boundaries, save confirmation and separate history. |

Script/About 0.3.1 is a Test label dated 14 October 2026; manifest 1.6.2 and runtime configVersion 1.0.0 describe
different schemas. They are not a coordinated production version. Use hashes/provenance to identify a revision.
The repository licence is GPLv3, not MIT. The checklist is separately controlled at v1.4; v1.5 template filenames
do not approve its current authority.

## Implementation Contracts

### Workflow and Identity

- The checklist governs physical sequencing. Current saved/display IDs are canonical A-O plus recovery P/Q,
  WorkflowIdVersion 2. Zero is navigation; next/switch/guide commands avoid custom-ID collisions.
- Live mutations require a validated tenant and freshly resolved immutable target. Stage identity until complete;
  reject partial/ambiguous/wrong-serial evidence and unsafe adoption of legacy unbound work.
- Verified means observed action-specific state; TechnicianConfirmed means explicit manual evidence. Submitted,
  Simulated, legacy or exception-only results must not become verified completion. Accepted evidence survives a
  later prerequisite/read failure. Retrying upstream work invalidates descendants without erasing attempts.
- T/X orchestrate semantic actions with individual approval, save and stop boundaries. P submission is not Allowed;
  Q requires current-cycle evidence, delay, managed-device absence and manual observation. Do not add automatic reset.
- Regular technician selection uses Windows-derived C/E hints, SAM-first eligibility, explicit approval and immutable
  enabled-user validation. Graph identity/cache/name suggestions never substitute for these checks.
- Group conflicts use literal approved exclusions and eligible reference-only removals. Dynamic/other ineligible
  groups remain protected. Tag/membership rechecks read accepted targets without POST replay.
- GET transport retry policy does not extend to mutations. Receipts/journals prevent normal repeat submission, not
  exactly-once behaviour across service acceptance and durable local saving.

### Persistence and Runtime Boundaries

- Resolve roots from authorised definitions; fallback authority is sticky. Use the authoritative session index,
  not latest-file heuristics. No cross-root merge, silent reset or automatic checkpoint rollback.
- Propose detached record/audit/bench changes, save, then publish. Save failure retains unresolved evidence and stops
  rather than showing success or accepting the completed input line. Dispatch and document results stay separate.
- Preserve append-only attempts/history and original identities. Migration converts action references simultaneously,
  including snapshots/current/previous/audit, under ownership with retained verified originals. PS7.5+ preserves date
  strings; canonical PS5.1 loading remains supported. Real workspace conversion is still blocked.
- An exclusive open OS lease, not PID/file age, governs local ownership. Retain lock metadata and complete recovery
  snapshots outside discovery. Do not kill an unverifiable host, bypass foreign/reparse-backed ownership or weaken policy.
- Graph, inventory interpretation, UI and operational saves stay on the main runspace. Only input waiting uses a
  temporary runspace; worker output is not permission to read scanner input or mutate state off-thread.
- Inventory binds hostname/Ethernet MAC to tenant/mode/device/build cycle and saves before announcement. A five-minute
  query interval is not service freshness or proof of the physically intended dock/adapter.
- Data Settings > 5 fills in missing inventory (field set version 2) for the current session and archived Live
  sessions, using the same single managed-device read. Archives are saved only after an unchanged-file hash check,
  a check that nothing other than device details differs, and an exact read-back; the original is kept as
  `.before-intune-details-<date-time>`. Wi-Fi MAC is stored separately and never replaces the Ethernet MAC.
- Statistics count proven current dispatch once per record. Working-time estimates follow effective schedules and
  observed exceptional windows, not old always-count-nights/weekends policy. Preserve original event timestamps.
- Remediation request evidence is separate from workflow completion. Fresh terminal reporting is not a unique
  on-demand correlation; accepted/uncertain requests are never implicitly replayed.

Local JSON, hashes and revisions defend ordinary consistency, not a malicious same-user rewrite. Independent audit
authenticity needs a separately protected append-only authority. Neither Local nor prototype Shared provides a
physical power-loss/fsync or multi-file atomicity guarantee.

## Startup and Shutdown

The lifecycle deliberately separates definition validation, ownership, saved-state preparation, authentication and
user work. A failure at an earlier boundary is not permission to continue at a later one.

1. Start the owned transcript and capture host/source provenance before operational/bootstrap/authentication work.
   Logs use LocalAppData with TEMP fallback; inability to establish either stops startup. Bootstrap preserves the
   original error rather than masking it with a secondary message.
2. Resolve the authorised definition directory and root. Script location, explicit
   `AutopilotExpressDefinitionDirectory`, invocation paths and bounded ancestor candidates support different launch
   contexts. README/LICENSE/.git are anchors; this product's README can anchor locally. Current working directory
   alone must not silently retarget storage. See `Resolve-ScriptDirectory` and neighbouring bootstrap contracts.
3. Select Demo/Live, with Demo as the interactive default. Load and validate raw runtime/manifest definitions before
   operational access. Invalid types/schema/actions/dependencies fail instead of partially publishing configuration.
4. Establish the authoritative Local root and acquire the root/mode reservation. Expected ownership refusal is
   coordinated by startup; the acquisition primitive remains strict. Shared configuration is refused, not activated.
5. Prepare saved work under ownership, including the guarded semantic legacy conversion path when eligible. Conversion
   occurs before authentication; ordinary malformed loading still fails. Never stamp a version to bypass conversion.
6. In Live, select/import a coherent Graph SDK, perform explicit authentication, validate context/tenant and perform
   capability/configured-selection checks. Demo substitutes controlled synthetic operations, not a queued Live session.
7. Initialise/resume user-mode records, bench and preferences, choose session defaults and enter caller-owned menus.
   Startup Resume N has its documented immediate archive behaviour; it is not the later Data archive workflow.
8. On exit/error, stop unused preparation, disconnect the owned Graph session as appropriate, release only the owned
   reservation/handles and complete diagnostics. Graph cleanup failure must not retain an OS lease forever.

Use the linked definitions and `Main Lifecycle` region for exact call placement. The function reference's caller
graph excludes top-level calls, so a helper with no listed function caller may still be essential to startup.
Neither a transcript line nor a returned Boolean proves a committed device checkpoint.

## Records and Evidence

`New-EmptyDeviceRecord` initialises a complete shape; `New-DeviceRecordObject` assigns induction identity and dates.
`ConvertTo-NormalisedValue` detaches dictionaries/objects recursively while preserving empty and singleton arrays.
Dates are round-trip values; strict loaders distinguish compatible absence from malformed data.

| Data | Meaning and Invariant |
| --- | --- |
| RecordId / BuildCycleId | Stable record versus current build-cycle identity; restart cannot reuse old physical proof as new completion. |
| Serial / ConfigItem | Normalised exact serial and text CI, preserving leading zeros. Uniqueness/ambiguity checks precede selection/mutation. |
| AutopilotDeviceId / ManagedDeviceId / EntraDeviceId / AzureAdDeviceId | Different service identities; cached fields are hints, not fresh mutation authority. |
| SiteCode / DeviceType / GroupTag | Selected intent and resulting tag policy, not proof the tenant currently matches. |
| Steps | Saved per-ID latest action result, details/evidence and invalidation context; IDs retain semantic association. |
| Attempts / recovery snapshots and history | Detached append-only evidence, sequence and cycle context; do not truncate to the latest success. |
| Completion and dispatch fields | Required-work completion is distinct from explicit proven dispatch, actor/time and override reason. |
| ImagingSessionStarts and work patterns | Observed loads/actions and effective schedule inputs to estimates; do not rewrite event timestamps. |
| IntuneInventory | Bound hostname/Ethernet snapshot with mode/tenant/device/cycle provenance, not the old convenience name. |
| Bench positions | Physical position links and metadata that must agree with unique workflow records; removal alone retains the record. |
| Master audit / checkpoints / journals / receipts | Distinct history, multi-file save/recovery and accepted-submission evidence; not interchangeable backups. |

Loaders validate typed flags, dates, status and nested dictionaries/history before use. Text `false` must never be
coerced into true completion. A whole-null supported legacy field differs from a null element inside a history.
Unknown/malformed evidence fails without replacing it with an empty collection. Diagnostics identify location/type
without dumping record contents; the historical two-line repair required separate exact approval.

## Workflow Execution and Evidence

The loader supports manifest 1.6.x and preserves array order. It validates raw booleans/metadata, unique identities,
supported actions/execution/activation and an acyclic enabled dependency graph. Phases group guidance; they do not
invoke arbitrary functions. Current saved IDs are A-O/P-Q with WorkflowIdVersion 2; display codes are separate.

The controlling path is:

```plaintext
Caller selects device/action       # Unique record and enabled step
  -> eligibility/tenant guards      # Prerequisites, cycle and activation
  -> explicit semantic dispatcher   # One of 17 supported action names
  -> action-specific handler        # Fresh target, confirmation, request/read evidence
  -> result writer                  # Classify, snapshot attempt, invalidate descendants
  -> guarded record/audit save      # Retain interrupted evidence on failure
  -> caller publication/feedback    # Announce only the committed outcome
```

`Invoke-AutopilotManifestStep` checks tenant/eligibility and dispatches explicitly. Resolve can bind a clean first
lookup to the validated tenant; it must not adopt arbitrary legacy unbound evidence. Tagged Graph errors can become
truthful action results; persistence failures and unclassified faults still propagate. Accepted submission data is
retained before later prerequisite reads so a transient failure cannot turn a recheck into a repeated POST.

`Write-ManifestStepResult` validates state/evidence, snapshots attempts and maintains completion. Retrying upstream
work invalidates transitive descendants even if the retry succeeds. Their previous details remain; completing the
upstream step again does not automatically revive them. Semantic role resolution fails on missing/ambiguous roles.

For applications, M can request sync while L remains incomplete because a failed installation needs attention.
The default no-failures outcome instead requires the current confirmed L baseline and makes no Graph request.
It records the baseline identity and time; changing or withdrawing L invalidates that outcome. The result writer
and completion check reject inconsistent, stale or wrong-mode evidence. Existing sync receipts remain separate.
Sync does not invoke the named portal remediation or establish that applications were installed.

Recovery unblock records an append-only, cycle- and target-bound intent before the POST. A saved accepted response
retains its original wait time even if the later step save is interrupted. When only intent remains, the outcome is
unknown: the technician may explicitly confirm that the same device shows Allowed, with No as the default. That
observation is saved separately from HTTP acceptance and starts a fresh two-minute wait. Neither a lost response nor
a failed save causes an automatic resend. These local records do not guarantee exactly-once execution across
independent hosts or prove physical recovery.

| State | Interpretation |
| --- | --- |
| Verified | Action-specific target state was observed and its evidence passed checks. |
| TechnicianConfirmed | Explicit eligible manual observation, not a synthetic Graph result. |
| Submitted | Accepted/handoff work remains unverified; return for read-only inspection. |
| Blocked / Failed | Unavailable or unsuccessful action; neither satisfies successful work. |
| Simulated | Successful Demo operation only; cannot certify Live documents. |
| LegacyCompleted | Compatible old success without invented current Graph verification. |
| AuditedException | Reserved exception evidence; not proof of each physical requirement. |

Prerequisite compatibility and document certification are different predicates. The workflow can accept supported
manual/Demo/legacy states where appropriate; Live document ticks require successful current-cycle Verified or
TechnicianConfirmed evidence. No eligible next step is not proof every required step is complete.

`Complete-DeviceDispatch` separately checks readiness, approval and optional override reason, proposes dispatch
metadata/bench changes, saves, then publishes. DO retains unresolved work and sets completion verification false.
Only after that successful save/publication may optional document output start. Output failure cannot undo dispatch
or cause workflow/Graph replay. T/X orchestrate existing semantic actions with individual save/stop boundaries.

## Graph and Identity Boundaries

Authentication configuration and authority are independent: requested scopes, actual context grants, tenant/account,
delegated role, licensing and Conditional Access all matter. DeviceCode instructions use the SDK success stream and
are explicitly sent to the host without contaminating the Boolean result. Failure offers explicit D/B/Cancel; the
application does not silently switch methods, although SDK-internal fallback is separately documented in Testing.

Select a common installed SDK version for all required modules and retain exact paths. Reuse successfully configured
request context, but validate a reused session. SDK retry is zero; application GET policy owns bounded transient
retries. POST/DELETE have one application attempt. A timeout is not remote non-acceptance and is never blanket replay
permission. Preserve original native in-page I/O failure separately from managed Graph errors.

Collection readers require bounded complete pages, valid next links and unambiguous exact identity. Autopilot serial
discovery uses encoded `contains` plus exact local equality, with no silent inventory-wide fallback. Rejected filters,
duplicates, malformed/partial pages and wrong IDs stop. Public filter/write-contract gaps and tenant acceptance remain
in [the external audit](TESTING.md#external-contract-audit), not hidden by a synthetic response.

| Operation | Current Verification Boundary |
| --- | --- |
| Group Tag | Fresh serial-checked Autopilot, one write/one immediate read; exact case-sensitive tag. Later recheck is read-only. |
| Group membership | Fresh Autopilot record and complete direct device memberOf snapshot; saved Entra object ID only while the fresh registration ID matches; eligible group and reference-only changes. |
| Managed deletion | Exact approved target; valid serial-search absence, including refusal to ignore a replacement record. |
| Primary user | Intended Autopilot UPN plus complete exclusive managed-users response; partial agreement remains pending. |
| Recovery unblock | Request acceptance remains Submitted; required wait, managed absence and manual Allowed/readiness observation remain. |
| Hash import | Hash-free durable intent before POST; import registration ID/state then independent unique Autopilot presence. |
| Remediation | Effective read access, opt-in immutable package/device, durable intent and one POST; fresh report is not unique request correlation. |

Tag/membership use narrower identity reads than generic refresh. Membership derives direct, not transitive, evidence
from `/v1.0/devices/{id}/memberOf`; a fresh snapshot is not reused across operations. Removal retains `/$ref` so it
cannot become object deletion. Literal Prefix/Exact exclusions protect intended groups; dynamic/ineligible targets
are not automatically corrected. Already-correct read verification is not authority for a new membership write.

### Keeping Graph Calls to a Minimum

Every Graph action has a fixed call count, enforced by
[GraphCallBudget.Tests.ps1](tests/GraphCallBudget.Tests.ps1). On 7 November 2026 the 14 measured actions fell
from 136 calls to 51; [DEVELOPMENT.md](DEVELOPMENT.md#7-november-2026-fewer-graph-calls) lists each one.

Saved device details are used where they cannot be out of date, and not otherwise:

| Information | How it is used |
| --- | --- |
| Entra object ID | Reused when Autopilot or Intune freshly reports the same registration ID; looked up again if the registration has changed. |
| Pre-provisioning group | Remembered for 15 minutes per tenant and group name. Forgotten on sign-in or close, and after any failed membership change. |
| Autopilot and Intune records | Always read fresh at the start of each step, because enrolment changes them and steps can be days apart. |
| Group memberships | Always read fresh, and read again after every change. This read is the proof that the change took effect. |
| Primary user | Read first; no write is sent when Autopilot and Intune both already show the intended user. |

Independent reads are combined into one Graph batch request of up to 20 reads: the startup checks, and the
device-detail reads for Data Settings > 5 and the automatic detail check. Each answer is used once, for the exact
request it matches, and passes the same checks as a normal read. A refused batch or a failed item is read again on its
own, so errors are reported exactly as before. Any write clears unused batch answers, so nothing read before a
change is used after it. Graph's throttling limits count each read inside a batch separately; batching saves time
and round trips, not throttling allowance.

The transport retries only classified GET 429/503/504 responses, honours valid numeric/date Retry-After within bounds
and refuses excessive delays rather than shortening them. Invalid headers and other/unclassified failures stop.
Default 60-second requests, three attempts and backoff may nest inside verification; there is no whole-workflow
deadline. Tag/membership do not add verification sleeps. See [policy defaults/ranges](OPERATIONS.md#configuration-reference)
and [customisation](CUSTOMISATION.md#timeouts-and-retry-policy) before changing them.

Diagnostics retain safe status/request identity and controlled timings, not raw request bodies/hashes/tokens.
Transcripts still need restricted access because ordinary workflow identifiers and active sign-in instructions may
appear. Same-user local files/hashes are not an adversarial security boundary.

## Persistence and Ownership

Storage authority is explicit and sticky. Normal project data is beside the resolved definitions; an authorised
LocalAppData fallback does not silently switch back when a directory becomes writable. The session index chooses
linked files, not newest timestamps. Do not merge roots, rename records by hand or auto-select a checkpoint.

An exclusive open OS lease governs root/mode ownership for the invocation. Readable metadata records identity but
does not replace the handle. PID reuse is checked against start/executable/session context; age or a matching number
on another computer cannot prove a stopped owner. FullLanguage is required for this safety mechanism, not bypassed.

Local writes validate detached proposals and existing append-only history before staging, retaining previous copies
and checkpoint/journal evidence. Save success precedes publication. Interrupted promotion or an unreadable audit
must stop, not return an empty session or discard the blocking artefact. The design is neither an fsync/power-loss
guarantee nor a multi-file atomic transaction across all records, bench and audit.

Submission receipts are separate from step completion. For sync/import/remediation, persist intent before the write,
retain accepted/uncertain state, and resume through reads/explicit recovery. This reduces ordinary replay; a crash
between remote acceptance and durable local evidence still prevents an exactly-once claim.

Shared helpers are disconnected offline prototypes: exclusive token, revisioned snapshot validation, retained
history, read-only recovery inspection and pristine-destination migration preview. They provide no network fencing,
SMB/OneDrive/disconnect qualification, malicious-writer protection or approved promotion. Local-only initial imaging
remains the decision; neither `lockTimeoutSeconds` nor a JSON mode edit overrides it.

## Shared Development Contract

Local-only initial imaging was selected on 11 October 2026. Shared remains disabled/refused at runtime; these are
disconnected development helpers, not operator commands or qualified network guarantees. Missing storage definitions
retain Local; invalid/unknown modes fail before storage/prompts.

| Runtime field       | Intended contract                                                              |
| ------------------- | ------------------------------------------------------------------------------ |
| sharedDataRoot      | Approved network backend root.                                                 |
| sharedBenchId       | Stable physical bench identity.                                                |
| lockTimeoutSeconds  | Reviewed stale-owner consideration, not Local expiry or automatic takeover.    |
| requireAtomicWrites | Backend-qualified replacement/recovery requirement, not an existing guarantee. |

| Helper                            | Implemented offline behaviour                                                                                                                                                          |
| --------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Start-SharedStoreReservation      | Existing isolated root, exclusive ownership token; readers/writers/cleanup verify ownership. No network fencing.                                                                       |
| Get-SharedStoreSnapshot           | Reserved envelope of devices/bench/audit; missing initial store revision zero, malformed/interrupted data fails.                                                                       |
| Write-SharedStoreSnapshot         | Expected revision, typed identities/status/bench links, retained record/serial/history/audit. Refuses active/removed serial reassignment/swaps and retains fault files.                |
| Get-SharedStoreRecoveryInspection | Independently validates target/pending/previous and ownership before/after reads. ReviewRequired; RecoveryApproved always false. No automatic highest-revision selection or promotion. |
| Get-SharedStoreMigrationPreview   | Captured normalised source and reserved pristine revision-zero destination only. Detached preview; ReviewRequired true, MigrationApproved false. No capture/merge/write/approval.      |

Structural history comparison ignores dictionary order, not key casing, array order or text. No SMB/OneDrive,
disconnect, distributed/malicious-writer or physical power-loss qualification exists. Backend/permissions, atomicity,
distributed ownership, consistent local migration and multi-technician recovery acceptance precede activation.

## Migration and Recovery

Canonical migration remaps all colliding legacy IDs simultaneously by semantic action. It covers steps, attempts,
prerequisites and recovery/override/audit references, retaining notes, times, accepted intent and linked current/
previous artefacts. A direct sequential rename can overwrite an old key; a version stamp cannot prove conversion.

Explicit conversion needs PowerShell 7.5+ to retain date strings, owned root/mode authority, approved scope, verified
originals outside discovery and no unresolved markers/checkpoints. Normal canonical PS5.1 loading is still supported.
Interrupted stages retain blocking evidence. Idempotent synthetic conversion is not real operational load/save/reload;
TODO 99/101 remain blocked for the guarded workspace.

Reservation recovery retains a complete hash-verified saved-store snapshot outside discovery before reacquisition.
It excludes only exact OS-lease sidecars, not inconvenient journals/audit/index files. Failed copying/verification
retains the reservation. Never kill an unverified process, delete a foreign/reparse-backed lock or restore previous
copies blindly. A snapshot can preserve evidence without granting authority to replay a tenant mutation.

Restore/restart/withdrawal are distinct guarded user operations with reasons/defaults and retained history. They do
not implement remote rollback. Administrative closure, archive, recovery entry and new build cycles must remain
distinguishable in attempts, audit, statistics and documents.

## Console and Background Work

Ordered menu definitions provide labels, keys and stable actions; the outer dispatcher and caller-owned loops own
navigation. Helpers return outcomes instead of recursively calling a menu. Main Enter exits, bench Enter refreshes,
and submenus return to their caller. Read-only steps/guide paging must not execute a workflow or save it.

Serial/CI/position resolution refuses ambiguity; explicit P:/S:/CI: disambiguates it. Induction validates early and
again before commit, retaining corrected defaults. Reuse preserves progress and cannot overwrite a full bench.
Feedback retains five complete newest-first contextual events, not five wrapped lines; detail view exposes full text.

Graph, record interpretation, UI and operational writes stay on the main runspace. Only waiting for console input
uses the temporary input runspace; the foreground loop handles a completed input before due inventory work. This
avoids cross-thread state mutation and scanner-input competition. Actual ConsoleHost editing/Ctrl+C/accessibility
still needs host acceptance; a synthetic child test does not certify every terminal.

Document processes use a separate redirected command pipe and never consume technician/scanner input. Their
external supervisor does not move Graph or operational writes into a worker.

## Statistics Inventory and Reports

Dispatch projection counts one eligible current record on its latest proven local dispatch date, excluding currently
removed/incomplete/undispatched records. CompletedAt alone is not dispatch proof. Valid duration samples determine
Average/Min/Max; totals weight records, not daily averages. Missing/reversed times remain disclosed, not zeroed.

The original elapsed-hours policy included nights/weekends. Current estimates use effective local schedules,
default Monday-Friday 08:30-17:30, observed exceptional activity and pause rules. Append-only schedule history protects
past hours except authorised Sick/RDO/WFH zero-imaging markings. The change is documented historically; original
events are never rewritten to make a statistic match a screenshot.

Inventory stores managed hostname/primary Ethernet separately from the old Autopilot convenience name. It is bound
to mode/tenant/device/cycle, retried at safe five-minute intervals after reseal and saved before announcement. Final
confirmed D/DO attempts a read; incomplete data warns and can still dispatch. Query time does not prove service
freshness or identify the intended physical onboard/dock/pass-through adapter.

Bench optimisations skip unchanged reconciliation saves, build fresh per-redraw record indexes, reverse-scan
attempts and schedule only due inventory IDs. They retain prevalidation/save-before-publication. Synthetic exact-
output speedups are not measured real-console/Graph improvement.

Saves keep a private copy of the last records file they wrote and verified. The copy is reused only when the file on
disk is exactly the same text; any difference forces a full re-read, and a failed save discards the copy. Shared-
storage helpers must stay valid in constrained language mode, so they avoid non-core .NET types.

Session exports project immutable current evidence into uniquely named CSV/HTML outside operational discovery.
Spreadsheet formula neutralisation and HTML encoding protect the output without editing source data. Empty export
is a no-op; large exports warn. Generic reports are neither an all-machine audit nor approved network/CMDB formats.

## Document Pipeline

### Configuration and Post-Commit Boundary

The optional document module is inert at import. Both outputs default disabled; disabled integration returns before
host/cache access. Typed scalar precedence is Default < runtime < saved preference < session < CLI. Null means no
override; false is explicit. Editing a CLI-pinned value requires releasing the pin. Save Preferences is separate.

After successful dispatch save/publication, construct an allowlisted detached job from cached device/site/dispatcher/
final-user context without a new directory lookup. Revalidate mode/tenant/cycle/date/evidence at the queue boundary.
Do not include raw SDK Data, hashes or full recovery snapshots. Missing required data fails that output only.
A crash after dispatch and before enqueue is a disclosed gap, not an exactly-once document guarantee.

The normal lifecycle is:

```plaintext
Committed D/DO                     # Dispatch already succeeded
  -> settings/job snapshot         # Independent enabled profiles, current evidence
  -> durable job / supervisor      # Owned directory, lease, request identity
  -> isolated Desktop STA child    # Verified libraries and owned Word lifetime
  -> structural DOCX population    # Current template bytes, reviewed bindings
  -> PDF export for both profiles  # Before either delivery request
  -> durable intent / delivery     # Request is not physical output or visible rendering
  -> receipts / bounded cleanup    # Retain failed/uncertain evidence; explicit retry
```

### Workers and Dependencies

| Executable File | Entry Contract and Role |
| --- | --- |
| [Run-DocumentJob.ps1](Modules/Documents/Workers/Run-DocumentJob.ps1) | RequestPath and optional Prepare; external supervisor, owner/queue/job lease/deadline, exact child and Word cleanup, durable lifecycle result. Does not load document SDKs. |
| [Invoke-DocumentJob.ps1](Modules/Documents/Workers/Invoke-DocumentJob.ps1) | RequestPath and optional Prepare; Desktop STA job interpreter, validated detached payload, child-only libraries, population/export, then independent deliveries/receipts. |
| [Populate-Document.ps1](Modules/Documents/Workers/Populate-Document.ps1) | Fixed isolated structural-population entry used by the public population API; validated data protocol, not arbitrary supplied code. |
| [Export-DocumentPdf.ps1](Modules/Documents/Workers/Export-DocumentPdf.ps1) | Fixed isolated Word-export entry used by the public export API; exact owned source/job and bounded result. |
| [Test-DocumentLibraries.ps1](Modules/Documents/Workers/Test-DocumentLibraries.ps1) | Fixed library self-test entry; synthetic DOCX/schema and exact barcode PNG round-trip, not Word/PDF/print acceptance. |

The public Start/Receive APIs are the caller boundary; workers are not general CLI utilities. The supervisor uses
a per-user mutex, external timeout and verified process identity; RequestPath is bounded local JSON, never executable
configuration. Preparation tracks the parent process/start/session, atomically publishes readiness and stops when
unused, owner/child exits or idle lifetime expires. Its device-free warm-up may initialise libraries/Word but creates
no device job, output or delivery. Preparation time is part of honest end-to-end reporting.

The pinned bundle uses OpenXml.Framework 3.3.0, OpenXml 3.3.0 and ZXing.Net 0.16.11 with reviewed .NET Framework
assets, platform WindowsBase/System.Drawing, archive SHA-512 and DLL SHA-256. Disclosed acquisition, exclusive staging
and non-replacing publication precede child-only loading. Invalid caches fail instead of silently repairing.
Publication, synthetic library success, Word registration, activation/licensing and usable PDFs are separate states.

### Module and Job Contract

The [module](Modules/Documents/AutopilotExpress.Documents.psd1) exports 19 functions. Import is inert: no acquisition,
assembly load, Word launch, rendering or writes. Optional application integration returns before host/cache access
when disabled. Document libraries never enter the Graph runspace.

| API group                                                           | Contract                                                                                                                                                                                                        |
| ------------------------------------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Resolve-AutopilotDocumentSettings                                   | Flat typed inputs, SchemaVersion 1; defaults < runtime < saved < session < CLI; null override absent, false explicit. Return values and sources; no evaluated configuration.                                    |
| New-AutopilotDocumentJob / Test-AutopilotDocumentTick               | Detached allowlisted data, dispatched version-two identity, ordered dates and matching tenant/cycle. All listed steps need successful current-cycle Verified/TechnicianConfirmed evidence. Demo cannot certify. |
| Get-AutopilotDocumentOutputName / New-AutopilotDocumentResult       | Safe exact-value leaf names and fully initialised separate receipts. Name calculation is not reservation; publication reserves exclusively.                                                                     |
| Dependency manifest/host/bundle/install/self-test/prerequisite APIs | Hash-pinned acquisition and child-only load; registration is not activation/licensing. Disabled returns before probing.                                                                                         |
| Template profile/population/barcode/PDF APIs                        | Reviewed structural targets, typed editing, unchanged layout, exact decoding and owned bounded export.                                                                                                          |
| Delivery/cleanup/start/receive APIs                                 | Data-only supervised queue, durable delivery intent, separate results, narrow ownership/digest cleanup and explicit retries.                                                                                    |

Complete-DeviceDispatch calls output only after Write-UserDeviceRecords succeeds and committed state is published.
Snapshot dispatcher/site/final-user context already available; never add a directory query or substitute imaging
technician/Windows username for the human dispatcher. Required missing fields fail only that output, not dispatch.
Jobs include JobId, RecordId, BuildCycleId, mode/tenant, dates, settings/profiles, fields and step/override evidence;
exclude raw SDK Data, searches, hashes and full recovery snapshots. Serial/CI map from Serial/ConfigItem; inventory
uses only matching IntuneInventory, not the older convenience name. DO needs its matching saved reason, without
altering step eligibility. A job factory cannot prove persistence; caller ordering is mandatory.

Each scalar setting is validated. Defaults are both enablements false, certificate AutoPrint/checklist Review,
local per-technician Documents root, saved-dispatch-date filename, timeout 60 seconds (1-3600), failed retention
seven days (0-3650; zero disables expiry). The local root cannot be UNC/provider/TEMP fallback. Exact serial plus
DDMMYY is the default name; only document-type collision suffix is approved, never overwrite/counter/GUID truncation.
Optional naming tokens are DocumentType/RecordId/BuildCycleId/JobId; serial remains required. Session edits are not
persisted until Save Preferences. The testing default permits print requests for unapproved and labelled Demo output; explicit review-only requests never print.

The queue validates serialised detached input again; dictionary detachment is not cryptographic immutability.
Jobs/receipts remain outside operational discovery. A process death after dispatch but before enqueue is a disclosed
gap. Record intent before Shell delivery, keep Requested/Uncertain honest and require explicit document-only retry.

### Dependency Reference

Bundle `openxml-3.3.0-zxing-0.16.11-netfx48-v1` is pinned in the
[dependency manifest](Modules/Documents/Public/Get-AutopilotDocumentDependencyManifest.ps1).

| Package                          | Version/licence      | Selected asset                                                         |
| -------------------------------- | -------------------- | ---------------------------------------------------------------------- |
| DocumentFormat.OpenXml.Framework | 3.3.0 / MIT          | lib/net46/DocumentFormat.OpenXml.Framework.dll                         |
| DocumentFormat.OpenXml           | 3.3.0 / MIT          | lib/net46/DocumentFormat.OpenXml.dll; exact Framework 3.3.0 dependency |
| ZXing.Net                        | 0.16.11 / Apache-2.0 | lib/net48/zxing.dll; classic System.Drawing binding                    |

WindowsBase/System.Drawing platform assemblies are additionally used; the selected target needs no separate
System.IO.Packaging NuGet package. Verify archive SHA-512, selected DLL SHA-256, target closure and retained licence/
nuspec metadata before child-only load. Versions/hashes are code-owned, not mutable request configuration.

Acquisition discloses source `api.nuget.org/v3-flatcontainer`, versions, roughly 22 MB, local destination and scope;
Default Yes is explicit approved behaviour. Declined/NoPrompts/WhatIf cannot fabricate consent or writes. HTTPS has
60-second per-request limits, at most two immediate attempts and no redirects. Offline ArchiveDirectory uses the
same checks without fallback download. Exclusive acquire.lock, staging and non-replacing rename publish the bundle;
invalid existing caches fail rather than silently repair. Never run package install scripts or extract arbitrary entries.

Publication is not runtime readiness. Self-test validates synthetic DOCX/schema and exact PNG round-trip in the
bounded child; aggregate prerequisite readiness adds Word registration, not activation/licensing/PDF/scan acceptance.
The 24 October advisory check found no known advisories for these three exact versions, not a permanent guarantee.
Original archives and failed stages remain evidence; same-user/admin tampering is not a defended boundary.

### Population Rendering and Delivery

Population uses typed Open XML elements and paragraph-local offsets, preserving split runs, stories, native control
state/glyphs, formatting and opaque embedded/OLE content without activation. Never regex-rewrite raw XML. Current
source bytes and exact warning-policy fingerprints invalidate prepared bindings when templates change. Three exact
approved legacy drawing-ID warnings are not a general validation waiver.

Explicit author completion groups replace baseline untracked classification only for their declared step list.
Every listed step still needs valid Live current-cycle Verified/TechnicianConfirmed evidence. Unmarked baseline
rows containing untracked external work remain protected. DO disclosure uses its matching saved reason once; normal
D must not show it. See [author syntax](OPERATIONS.md#supported-template-methods), not invented field aliases.

ZXing Code 128 preserves exact payload, integer bars and quiet zones without captions. Sampling is 600 DPI at unchanged
physical geometry. Fit-only omission is disclosed with readable text retained; invalid payload fails. PNG decode,
final-PDF decode and physical scan are three different acceptance layers.

Word uses one exact owned interactive-desktop lifetime with macro/link/print-field updates disabled and owned settings
restored in finally. HWND zero is handled by a blank bootstrap before ownership proof; Quit uses by-reference save
arguments. Never kill by WINWORD name or close an unproved/pre-existing instance. Certificate export requires exactly
two pages; observed checklist review is six pages. PDF signature/EOF/digest checks are not PDF/accessibility certification.

Names use exact serial plus saved dispatch date, with only the approved document-type collision suffix; publication
reserves exclusively and never overwrites. Intent is durable before Shell delivery. Requested/OpenRequested/Uncertain
cannot be relabelled Printed, visibly open or manually saved. With guards OFF by default for testing, unapproved and
labelled Demo output can request printing according to its policy. Guards ON restore DRAFT/non-printing output for
unapproved profiles and block Demo printing. An explicit review-only request never prints, regardless of guard state.
Explicit document-only retry reuses validated retained outputs and preserves failed attempts; it never redispatches.

Successful compaction retains PDFs and receipt; cleanup acts only on exact feature-owned metadata/digests and retains
unknown, active, uncertain and protected review assets. Failed retention defaults seven days, zero disables expiry.
No broad Temp/network traversal or removal of original templates is part of this pipeline.

## Failure Model

| Failure | Required Behaviour |
| --- | --- |
| Invalid definitions/roots/mode/policy | Stop before the protected downstream boundary; retain original diagnostics. |
| Active/unverified ownership | Refuse operational access; no file-age/PID-only takeover or policy bypass. |
| Incomplete/wrong/ambiguous identity | No mutation; stage identifiers until complete validation succeeds. |
| Accepted mutation but failed read | Retain accepted Submitted/uncertain evidence; later reads do not repost. |
| Record/audit/checkpoint save fails | Stop and retain evidence; do not publish success or accept more work as if saved. |
| Worker/export/delivery fails after dispatch | Dispatch stays committed; retain separate failed/uncertain result and retry documents only. |
| Unproved Word ownership/cleanup | Mark uncertainty and retain evidence; never widen process termination. |
| Fatal native host I/O | Preserve original-host/WER evidence; managed catches and mock passes do not certify its cause/fix. |

## Verification and Known Gaps

Use the owning suites in [TESTING.md](TESTING.md#test-catalogue): identity/transport/tenant for requests; completion/
physical/manifest for semantics; storage/checkpoint/attempt/lease for persistence; rehearsal for real copied Demo
routes; document tests for isolated output. Function help/caller links are navigation, not measured branch coverage.

Manifest endpoint descriptions identify the filtered v1.0 serial lookup and direct device membership reads. The
profile-confirmation step records the technician's observation; it does not independently read the assignment.
These descriptions do not establish service support, permissions or successful tenant operation.

Actual tenant filter/write/role/policy outcomes, native-host diagnosis, terminal/inventory/bench performance,
physical build, current checklist authority, final document mappings, consistent ten-second visible opening,
printing/scanning/manual Save As and Shared qualification remain separate recorded gates. See the
[active backlog](TODO.md). Local JSON/hash protections do not provide independent
tamper-proof auditing; Office automation remains an interactive desktop feature, not a server conversion service.
