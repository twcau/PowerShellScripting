<!-- omit from toc -->
# Autopilot Express Development

This is the development record: what changed, when, why it was needed, why the chosen approach was used,
and what was learned. Historical decisions retain their original context; a later change does not erase them.
[README.md](README.md) is the entry guide and [OPERATIONS.md](OPERATIONS.md) covers daily work.
[TESTING.md](TESTING.md) owns validation evidence, and [TODO.md](TODO.md) tracks outstanding work.

## Contents

- [Tracked Tasks](#tracked-tasks)
  - [Approved Scope and Decisions](#approved-scope-and-decisions)
- [Development History](#development-history)
  - [16 October 2026: Device-Code Instructions and Explicit Authentication Retry](#16-october-2026-device-code-instructions-and-explicit-authentication-retry)
  - [27-28 October 2026: Readiness, Deletion Reconciliation and Weekly Statistics](#27-28-october-2026-readiness-deletion-reconciliation-and-weekly-statistics)
  - [3-4 November 2026: Testing, Recovery and Documentation](#3-4-november-2026-testing-recovery-and-documentation)
  - [5 November 2026: Isolated Document Test Bundle](#5-november-2026-isolated-document-test-bundle)
  - [6 November 2026: Updating Device Details from Intune](#6-november-2026-updating-device-details-from-intune)
  - [7 November 2026: Fewer Graph Calls](#7-november-2026-fewer-graph-calls)
  - [8 November 2026: Speed and Waiting Review](#8-november-2026-speed-and-waiting-review)
- [Completed Work](#completed-work)
- [Incident Review](#incident-review)

## Tracked Tasks

[TODO.md](TODO.md) is the prioritised queue for unfinished work, acceptance and approval holds.
Completed tasks and the decisions behind them are recorded below.

### Approved Scope and Decisions

Authorised offline implementation, synthetic migration rehearsals and tests do not authorise authentication,
tenant calls, operational repairs/migrations, physical actions, network publication, deployment or Shared activation.
The later testing decision expressly permits document generation and print requests with template guards OFF; it does
not approve the templates or establish physical printer/scanner acceptance. No other approvals were broadened.

The approved operational migration scope, when eligible, is immediate workspace data and linked current/previous
files, excluding archives/fallback roots/retained originals. Stop on locks or unresolved checkpoints/markers; never
delete them to force eligibility. Owning-host resume confirmation is not workspace migration proof.

Stable original-start indexed filenames, reuse without reset, explicit proven dispatch, GPLv3/About credit,
non-waiting Notepad and caller-specific menus are approved decisions. The later effective-dated work-pattern model
supersedes the initial nights/weekends duration policy. The owner chose to retain the existing startup: the main menu
opens first and option 1 opens Build Bench. Main Enter exits; bench Enter refreshes; retain five complete newest-first
contextual events. Additional history retention/durable search or changed defaults requires a decision.

## Development History

Dates identify recorded development or review activity, not a production release. A passed offline gate applies
to its recorded revision; it does not close separate tenant, technician-host or physical acceptance tasks.
Original task identifiers remain attached to the work, including superseded approaches and failed attempts.
References below to mandatory DRAFT/no-print restrictions describe the earlier guard setting. The later testing
decision made those guards removable and OFF by default for both documents; explicit review-only requests still
cannot print.

### 16 October 2026: Device-Code Instructions and Explicit Authentication Retry

**Problem and evidence.** Two transcripts from the same B64FDFD1 revision showed the SDK waiting for device-code
authentication without displaying instructions, then timing out. Inspection of SDK 2.41.1 established that its
callback writes the instructions to the success stream. The application piped that stream to Out-Null.
This was a presentation defect, not evidence that the tenant needed broader scopes or a policy bypass.

**Tasks and implementation.**

- AUTH-1: Correlate the two matching transcripts and inspect the actual SDK callback, separating the missing prompt
  from Conditional Access, native I/O failure and secondary disconnect messages.
- AUTH-2: Reproduce hidden instructions with a failing regression, replace the Connect-MgGraph Out-Null sink with
  Out-Host, and retain a clean Boolean startup result. Cover instructions followed by cancellation and their delivery
  before subsequent context validation; the owning 66-case suite passed offline.
- AUTH-3: Record the assurance failure: the earlier SDK mock emitted no instructions, so checking the DeviceCode
  switch alone missed an unusable interaction. Test the real output-stream contract under captured caller output.
- AUTH-4: Complete the historical prompt-fix gate: 1429/1429 on each host, all 30 suites, 32 static-clean PowerShell
  files and 34 matching provenance inputs per report. Sixteen operational originals retained hashes, lengths and
  attributes. The operator subsequently confirmed that device-flow login worked.
- AUTH-5: Add explicit D DeviceCode, B Browser and 0 Cancel after a returned SDK sign-in failure or cancellation.
  The user approved Enter as Cancel. Keep the same scopes, tenant pin and post-sign-in checks; change only the
  session attempt mode. Do not add automatic fallback, background attempts, workflow replay or Ctrl+C interception.
  The owning 81-case suite covered real input validation, repeated mode changes and cleanup.
- AUTH-6: Complete the separate retry-menu gate: 1444/1444 on each host, all 30 suites, 32 static-clean files and
  34 matching provenance inputs per report; operational originals remained unchanged.

**Why this approach.** Showing the SDK's interactive output repairs the demonstrated stream boundary without
changing identity policy. An explicit retry menu gives the technician control over another attempt; a silent
fallback could select a different authentication path without consent. SDK success remains separate from later
context, identity and capability validation, so those failures cannot accidentally replay the sign-in loop.

**Outcome and lesson.** Visible instructions were operator-confirmed. The later retry interaction was validated
offline, not accepted on every real SDK/Conditional Access path. Native 0xC0000006 diagnosis, broader tenant checks
and physical acceptance remain separate. Historical report locations belong in the testing evidence register.

### 27-28 October 2026: Readiness, Deletion Reconciliation and Weekly Statistics

This dated development record is not a production-release or host-acceptance claim. The supplied 27 October logs
ran entry-script hash 2234D43B...66A8C, not the subsequently repaired local source.

**Document readiness.** The affected-host worker explicitly returned AuthorizationManager/UnauthorizedAccess.
That proves script authorisation failed, not which combination of Internet marks, network classification or
organisational controls caused it. Recovered code checks local document scripts before optional import/worker
execution, runs enabled-output preflight before session loading, and rechecks output configuration and saves.
The worker wrapper preserves bounded stage/exit/error details. WARN/INFO readiness outcomes now use timestamped
central logging. Retry/exit/session-only suppression are explicit; C/default does not rewrite saved preferences.
Local unblocking requires separately confirmed reviewed paths and unchanged fingerprints. DRAFT/no-print remains.
The user's later Unblock-File execution has not yet been followed by a successful affected-host worker result.

**Deletion reconciliation.** CI86063's first DELETE was accepted, but five serial reads remained stale. Retrying
sent another DELETE to the same ID and returned HTTP404. Accepted submissions now recheck without confirmation or
another write. A structured 404 from the exact DELETE is retained as reconciliation evidence, not falsely marked
accepted; only successful validated serial discovery can establish absence. Replacements and failed discovery
remain unverified. A failed read after accepted deletion preserves Submitted. This does not migrate old records
whose latest result has already lost earlier accepted evidence, and it does not make arbitrary 404 responses safe.

**Date and statistics repair.** Invalid optional dates previously generated caught transcript errors. TryParse
now returns the existing missing-date sentinel without expected-error pollution. Statistics retain proven-dispatch
eligibility and weighted duration samples. The opening tables remain current-site scoped. Earlier weeks show
all-site weekly totals and site breakdowns even for a single site, with explicit Monday-Sunday dates. Selected-site
views, Next/current navigation, narrow terminals and visible empty states are covered without fabricated daily rows.

**Graph trust.** The redirected-home SDK lives on UNC paths. Get-Module -ListAvailable can reach trust-sensitive
discovery before an import-only check, so a filesystem/AST literal-manifest reader now feeds the existing coherent
version planner. Exact selected SDK trees are inspected before loading. Default-No consent covers only listed,
unchanged Internet-marked files, including reviewed network files. Restricted/AllSigned/publisher failures and
uncertain UNC trust give retry/return and approved-deployment guidance; no policy bypass, publisher installation,
silent SDK replacement or loaded-assembly conflict relaxation was added. This conservative network check is not
a claim that all UNC deployments are inherently forbidden by Windows.

**Validation and lessons.** The final Graph/workflow gate passed 307 cases on each of Core 7.6.9 and Desktop 5.1.
The first wider run exposed 35 failures because the isolated startup harness still stubbed the old initialiser;
it was repaired to include the new readiness boundary, with an explicit safe-exit test, before rerunning both gates.
Earlier focused readiness/deletion/persistence checks passed 139 selected cases on Desktop. Resolve the Pester
manifest in the parent when orchestrating Desktop, and use Set-Content -Stream for cross-host synthetic Internet-mark
fixtures. None of these offline gates proves tenant, affected-host trust, Word, printer or physical build acceptance.

**Still required.** Durable prequeue document failures and historical cycle-specific recovery; document feedback in
bench events; CI-based off-bench reuse; guarded Prepare C/D overlap; sequential multi-position commands; sync receipt
consolidation without replay; organised keep-all backups and a proposed primary-file backup/retention policy;
remaining log/inventory/recovery-wait review; assistant interruption diagnosis; complete restored development history
and a regenerated function catalogue. Existing task identifiers and paused/held acceptance work remain unchanged.

**28 October Cortex XDR incident: investigation blocked on endpoint evidence.** The supplied 08:54:33 transcript
identifies PowerShell Core 7.6.9, PID 31488, entry-script hash 771D617E...BAF562. Graph imports and sign-in succeeded;
document prerequisites reported Passed at 08:55:20. The final message announces recovered-session resume. The
Cortex screenshot identifies the same PID and reports only "Behavioral threat detected"; it does not identify a
rule, triggering operation, child process or detection timestamp. This is separate from the earlier worker
AuthorizationManager rejection and is not established as a false positive or as a Copilot interruption.

After that final message, startup loads bench/device JSON, may save imaging-session metadata, then automatically
stages and launches optional document preparation before site selection. Preparation starts fixed Desktop
PowerShell supervisor/STA scripts and may activate Word through COM; its ownership checks compile a small native
window-to-process adapter. This is a plausible behavioural-alert surface, not a confirmed cause. Earlier failed
prerequisites prevented this preparation path; the newly successful check now permits it.

Timestamped boundaries now precede individual session loaders, metadata registration/save and preparation entry,
and record completion or a caught preparation failure. An endpoint product terminating the process can prevent
PowerShell catch/finally or transcript shutdown from running, so these changes do not guarantee a final error or
resolve the security block. No worker behaviour, ownership guard, execution policy or endpoint protection changed.
The focused mocked checks passed 47 cases on each of Core and Desktop; three touched PowerShell files passed
static analysis with the existing exclusions. No affected-host replay, Word activation or tenant operation was run.

Before another affected-host reproduction, request the security team's Cortex alert/incident export: detection
name and rule/module identifier, timestamp with timezone, action taken, causality/process tree, full relevant
command lines and any named file/hash. Correlate PID and process start time, not PID alone. Preserve the transcript
and recovery evidence; do not disable Cortex, change execution policy or broadly allowlist PowerShell to test a
guess. The wider work remains paused pending this incident investigation.

**28 October continuation authorised: prequeue recovery and off-bench selection.** The user subsequently resumed
the wider TODO work. The Cortex investigation remains blocked on endpoint evidence; no affected-host reproduction
or security-policy change was performed. The preceding pause statement records the investigation's earlier status.

Optional-document failures before worker staging now retain detached, actor/mode/tenant-scoped attempt evidence
under Attempts, including the original dispatcher and resolved full site name. A missing worker handle is treated
as a failure rather than a silently lost job. Settings J rediscovers these attempts and offers default-No,
document-only retry using their original context. This does not yet provide every historical cycle or every staged
worker job across sessions, and does not approve DRAFT output or prove physical delivery.

The existing off-bench E selector accepts list numbers, serials and CIs without replacing the guarded lifecycle
actions. The bench now distinguishes retained-workflow attachment from new-record creation and cancellation.
The first long summary was clipped by bounded feedback; a shorter result passed the same bench-routing checks.
The combined offline Graph/workflow/bench/deletion/persistence/document gate passed 660 selected cases on each of
Core 7.6.9 and Desktop 5.1, with no failures or skips and 44 not selected. Four touched PowerShell files passed
PSScriptAnalyzer with only the established exclusions. Historical document selection, bench document events,
Prepare overlap, batch commands, storage organisation and documentation-history restoration remain outstanding.

**28 October guarded Prepare overlap completed locally.** After the preceding gate, Prepare was extended to allow
D membership while a persisted accepted C tag remains pending. Eligibility requires completed identity/removal,
matching record/cycle/tenant/serial and target/tag, and current timestamp evidence. New tag submissions retain their
original accepted scope through failed reads and rechecks; legacy evidence is not silently assigned a new scope.
The guarded C save precedes D, and save failure stops the plan. Pending C remains Submitted, including when D
completes; if D is pending too, both limitations are reported. No tag or membership no-repost guard was relaxed.

The added direct physical-gate test exposed that E previously relied on D as its transitive prerequisite. Once
overlap permits D to complete first, that is insufficient: E now explicitly requires C completion by semantic
action, including after manifest labels change. The corrected owning/adjacent safety gate passed all 326 cases
on each of Core 7.6.9 and Desktop 5.1 with no failures, skips or unrun cases; three touched PowerShell files passed
static analysis with the existing exclusions. These are isolated mocked checks, not tenant or physical acceptance.
The final follow-up requires the latest C result itself to be accepted Submitted: a new Blocked result stops the
plan even when the writer preserves earlier accepted evidence. All 21 overlap-specific checks passed on both
hosts after this guard, and the two changed files again passed static analysis; the full 326-case gate above
precedes this final follow-up rather than claiming another complete run.
Batch selection, historical document recovery/events, storage organisation and history/catalogue reconciliation
remain outstanding; the endpoint incident still needs the security export.

### 3-4 November 2026: Testing, Recovery and Documentation

The supplied logs and guides were reviewed to recover the outstanding work and separate implemented fixes from
real-world acceptance. Thirty logs and eight guides were reviewed; their remaining evidence and approval needs are
in [TODO.md](TODO.md). The native in-page I/O failure is established, but network-hosted SDK files remain a
plausible cause rather than a proven one.

- **Testing documents (DOC-TEST-GUARDS, DOC-READINESS-UI, DOC-REPRINT and DOC-CYCLE).** The owner directed that
  template approval guards be removable and OFF by default for both documents during testing. The settings toggle
  and command-line switch restore enforcement; they do not approve a template. Explicit review-only requests do
  not print. Clearer bracketed trust choices, existing-dispatch reprints and build-cycle repair address the observed
  obstacles without redispatching a device. Word, printer and barcode acceptance still need real equipment.
- **Document visibility (DOC-HISTORY and BENCH-DOC-FEEDBACK).** Completed job receipts can be reviewed and used
  to start a fresh reprint; an old job is never replayed. The bench now collects each finished job as a contextual
  event, without taking scanner input or saving workflow changes.
- **Non-administrative SDK (SDK-LOCAL and PS51-COMPAT).** SDK modules are selected from a fixed-local per-user
  cache rather than loaded from a network home directory. A Windows PowerShell 5.1 hashtable-sorting defect was
  corrected so the installed version is reused as intended. Actual installation and crash comparison on the
  affected host remain outstanding.
- **Inventory and log findings (INV-RECONCILE, INV-DIAGNOSTICS, LOG-DELETE-404 and LOG-OPTIONAL-DATES).**
  Fresh serial-based discovery reconciles the supported re-enrolment case while identity mismatches remain blocked.
  Diagnostics and retries are clearer. The current deletion reconciliation and optional-date handling already
  cover the other reviewed log findings; caught diagnostics are not counted as separate crashes.
- **Recovery wait.** The 27 October log showed seven unblock requests followed by a readiness check 117 seconds
  after the last submission, not proof of a faulty two-minute timer. Directly selecting an already-submitted
  unblock now stops before another request and preserves the original submission time. The focused recovery and
  mutation tests passed 129/129 on each PowerShell host, without skips. A lost response or interruption before the
  submission is saved remains a separate uncertainty; this fix is not an exactly-once guarantee.
- **Interrupted recovery (RECOVERY-UNCERTAIN).** The owner chose guided review rather than automatically resending
  an unblock whose response is unknown. A durable intent precedes the request. If only that intent remains, the
  technician can check the same device in Intune and confirm Allowed; Enter defaults to No. An Allowed observation
  starts a fresh two-minute wait and is retained separately from an accepted response. Save failures stop progress;
  these local records do not guarantee exactly-once execution across hosts.
- **Conditional application sync (APP-CONDITIONAL-SYNC).** The owner confirmed that M should request sync only
  when a failure needs it. Enter selects no failures after L's application baseline is confirmed; this sends no
  request. A failure can still be handled while L is incomplete. Reconfirming or withdrawing L invalidates the
  no-failures outcome. The named Intune portal remediation remains separate, and existing sync receipts are retained.
- **Older bench recording.** A sample across the 226-second October recording showed the earlier bench interaction
  and an "all steps completed" message when no next action was available. Current code checks dispatch readiness
  before displaying that message. The sample does not establish a current defect or explain the editor interruption;
  current-host visual and accessibility acceptance remains outstanding.
- **Submission records (SYNC-INTENT, SYNC-RECEIPTS and IMPORT-RECEIPTS).** Intent and accepted sync entries,
  and submitting and accepted import entries, now live in append-only device ledgers. Approved legacy receipts
  are removed only after the record saves; unmatched or invalid files remain for review. Import entries exclude
  hardware hashes. The owner's safe-to-repeat sync decision permits resubmission after an unresolved sync intent;
  neither ledger proves exactly-once execution.
- **Bench and storage (BENCH-BATCH, BENCH-DUP-SERIAL and BACKUP-POLICY).** Batch actions resolve and confirm
  selected positions before sequential processing; duplicate induction is refused early. The owner chose to keep
  all backups and organise them by date and tenant. Older flat backups can be moved after confirmation, not deleted.
- **Prompt and test upkeep (PROMPT-DEFAULTS, PROMPT-BRACKETS, TEST-REFRESH and VALIDATION-PROVENANCE).**
  Prompt keys are bracketed without changing their defaults. Tests were brought into line with current menus and
  records, and validation now fingerprints the module, workers and templates as well as the entry script.
- **Guide upkeep (DOC-CATALOGUE, DOC-ALL-EIGHT and DOC-CONTRACTS).** The function catalogue was regenerated,
  guide links and workflow identifiers were checked, and the documentation tests cover the maintained guides.
  The README is now an entry point; detailed procedures, contracts and change guidance have been moved to their
  respective guides. Outstanding work stays in TODO; this file records completed work and decisions.

- **Cross-host validation and fixture compatibility (4 November).** The first focused Windows PowerShell 5.1
  run showed that Pester could not resolve `Get-AuthenticodeSignature` on this restricted host. The trust tests
  now create a conditional, inert command stand-in for Pester to mock, rather than importing the Security module
  that previously caused duplicate type data in 5.1. The focused set passed 389 tests with 44 opt-in skips on
  both hosts. The complete 36-suite offline run then passed 1,898 tests, with no failures or unrun tests and the
  frozen inputs unchanged on both hosts. After recording the results, the updated documentation contracts passed
  89/89 on each host, and static analysis passed across 87 maintained PowerShell files. The 44 document-integration
  tests were skipped in those runs, and XML reporting was unavailable because the sandbox denies its CIM
  environment probe; the release gate was therefore still open at that point. See [TESTING.md](TESTING.md)
  and [TODO.md](TODO.md).
- **Document-library test approval and sandbox boundary (4 November).** The owner approved acquisition solely
  for the isolated integration tests. The first attempt downloaded the pinned archives and verified their hashes,
  but sandbox policy denied the final directory publication. After the owner updated the policy, a new PowerShell
  session resolved a different sandbox cache location, so the earlier staging archives were unavailable there.
  No alternate location or permission workaround was used; the integration tests remain open until the approved
  local cache is accessible consistently.
- **Step M wording, sandbox-safe junction test and Markdown lint (4 November).** Both action tables in
  [OPERATIONS.md](OPERATIONS.md) now describe step M as "Review app failures; sync if needed", matching the
  conditional sync. The documentation contract now checks the legacy table as well, so the two cannot drift
  apart. One document safety test created a real directory junction, which the sandbox refuses ("Access is
  denied"). That failure came from the test environment, not the product. The test now simulates the redirected
  folder instead, so it still proves that the script refuses a redirected cache path without touching the
  target. After the owner allowed the npm cache, the pinned Markdown linter found no problems in the ten product
  guides. This resolved the lint blocker at that time. Static analysis again found no issues in 87 files.

Archived backlog tasks 67-70 were reconciled against the current implementation and focused tests: action-specific
evidence is checked on creation and persistence; post-upload serial discovery is bounded; serial and direct
membership discovery are complete before group eligibility decisions; and propagation, no-op and rejected evidence
remain distinct. At that point task 71 still needed a fresh release gate; the later offline gate is recorded below.
The available archive says tasks 59-61 and 64-66 were complete, but does not describe tasks 62-63; those identifiers
remain an evidence request rather than invented work.

### 5 November 2026: Isolated Document Test Bundle

The owner granted a dedicated local test folder after the sandbox redirected each
shell's normal application-data path to a different cache. The approved pinned
document libraries were acquired there without administrator access. Their
archives and extracted libraries passed the existing integrity checks. The test
folder is separate from the application's normal cache; using it does not change
the application's settings or establish Word, printer or tenant acceptance.
With that bundle, all 44 opt-in document integration cases passed separately on
both PowerShell 7 and Windows PowerShell 5.1, with no failures or skips.

The complete 296-case document suite also passed on PowerShell 7. A later combined
run stopped making progress around the reservation checks, although the next
check passed in isolation. Its two constrained child-process probes previously
had no deadline. They now drain output, enforce a 30-second limit and terminate
an overdue child. Tests cover successful output, failure details and termination
of a timed-out child; all 63 reservation-safety cases passed on both hosts.
This improves the test harness without changing the application's lock logic.

A subsequent combined PowerShell 7 diagnostic exited with control-C status
`0xC000013A` before producing a summary. No failing test lines were reported
before the interruption, but its source is unknown. This is separate from the
earlier application crash with status `0xC0000006`; neither is used to infer
the cause of the other.

The later Markdown lint recheck could not start because the sandbox denied the
previously configured npm-cache parent. The earlier lint pass is retained as
historical evidence, not claimed for these subsequent guide updates. The current
session's effective policy lacks the newly saved writable sandbox-root entry;
the saved settings also list that cache as read-only. Later checks showed that
separate sandboxed shells receive different cache-parent GUIDs, so granting one
fixed path is not a dependable solution. The policy needs review and verification
before another lint attempt.

At this point the complete release gate remained open. Pester's XML exporter needs
a Windows CIM query that the sandbox blocks, independently of access to the test
folder. A local, non-administrator helper checks the pinned tools, bundle and CIM
access before running the maintained release gate on each host.

The owner then ran that helper in normal, non-administrator PowerShell 7 and
Windows PowerShell 5.1 sessions. Both complete 36-suite runs passed all 1,945
tests, including document integration, with no failures, skips, unrun tests or
failed containers. Their XML reports and all 91 recorded input fingerprints were
checked; the fingerprints match each other and the current inputs. The ten bundle
fingerprints match as well. This completes BACKLOG-TRACE-71 and RELEASE-TWO-HOST
for offline validation. Word/PDF rendering, physical printing and scanning,
tenant work and affected-host acceptance remain separate.

### 6 November 2026: Updating Device Details from Intune

The owner asked for a way to go back to Intune for devices that have already been
through the process, so missing details can be filled in. This is groundwork for a
later CSV export to whitelist devices on the network. The agreed design was:

- It covers the current session and every archived Live session, and saves the
  updates back into the archive files.
- It fills in the hostname, Ethernet MAC, Wi-Fi MAC, Entra device ID, primary user
  and Windows version and release, and only touches details that are missing.
- It sits at Data Settings > 5.
- Devices that are no longer in Intune are marked as not found and keep their
  saved details. They are only checked again if the technician chooses option 2.
- The CSV export itself comes later (OUTPUT-NETWORK in [TODO.md](TODO.md)).

The existing inventory read already asked Intune for the device in a single request,
so the extra details were added to that same request instead of adding new ones.
Devices that are already complete, have no tenant recorded, or belong to a different
tenant are skipped before any request is made.

Archive files are treated with care because they are the only record of past work.
Before an archive is saved, the tool checks that the file has not changed since it
was read, that only device details differ, and that the new content reads back
exactly. The original is kept beside it with a `.before-intune-details-` date and
time suffix. Dates in the archive are kept exactly as written. On PowerShell 7
builds that cannot read dates as plain text, archives are skipped with a message
instead of risking a change to their dates.

Two assumptions were made and should be confirmed by the owner. The primary user
is the user Intune shows against the device, and every Live archive in the shared
archive folder is included, including other technicians' sessions.

The new tests found two faults before release. The current session's device list
was being wrapped as a single item. Windows PowerShell 5.1 also treated a re-read
archive as one item, which made the safety check refuse every archive save. Both
were fixed.

The same day's Graph audit was a code review of every Graph call. It was not a
measurement against the tenant. It found no duplicate calls within a step that
could be removed safely. Each step looks the device up again, which takes up to
three reads (Autopilot, Intune and Entra). Steps can be hours or days apart, and
in that time enrolment creates the Intune and Entra records and can rename the
device. A saved copy would therefore be wrong, not merely old. Within step A, the
extra lookups only follow an upload, or wait a bounded number of times for the
device to appear. The group-membership step reads the pre-provisioning group once.
That read is how the tool notices that an earlier submission targeted a group that
has since been recreated. Caching these reads (first proposed as GRAPH-CACHE) was
therefore not adopted and was removed from the backlog. GRAPH-SELECT remains open:
it would shrink the size of an Autopilot lookup, not the number of calls.
Real-tenant checking of the new option is recorded as INTUNE-DETAILS-ACCEPT.

This review was too narrow, and its conclusion was revised the next day. It looked
only for repeated calls within a step and did not count calls. See the 7 November
entry below.

### 7 November 2026: Fewer Graph Calls

The owner asked for proof that every action uses as few Graph calls as possible,
and that saved device details help to avoid calls. The earlier review gave neither.
A new test, [GraphCallBudget.Tests.ps1](tests/GraphCallBudget.Tests.ps1), now runs
14 common actions against a simulated tenant and counts every request. It was run
once before any change, to record the starting counts, and again afterwards.

| Action | Calls before | Calls after |
| --- | ---: | ---: |
| Startup checks after sign-in | 6 | 1 |
| Refresh a known device | 3 | 2 |
| Refresh a device whose registration changed | 3 | 3 |
| Step A, with the upload appearing on the third check | 9 | 7 |
| Step B, deleting an existing Intune record | 5 | 4 |
| Step B, with nothing to delete | 4 | 2 |
| Primary user, already assigned | 6 | 3 |
| Primary user, new assignment | 8 | 7 |
| Step D, adding the device to the group | 6 | 4 |
| Step D, device already in the group | 4 | 2 |
| Step J, removing the device from the group | 7 | 4 |
| Step D, with two conflicting groups to remove first | 13 | 7 |
| Data Settings > 5 for 45 devices | 50 | 4 |
| Automatic detail check for 12 devices | 12 | 1 |
| **Total** | **136** | **51** |

What changed, and why each change is safe:

- **Startup.** The organisation, permission checks and group lookup are sent as one
  Graph batch request instead of six separate requests. Any part that fails, or a
  batch that is refused, is simply read again on its own, so its real error is still
  reported in the usual way.
- **Saved Entra object.** When the device's registration ID has not changed, the
  saved Entra object ID is reused instead of being looked up again. If the
  registration ID changes, it is still looked up, as the third row shows.
- **Step A waiting.** While waiting for an upload to appear, only Autopilot is
  checked. Intune and Entra are read once, after the device appears.
- **Step B.** The second search that repeated the first was removed. A deleted
  record is still confirmed absent by a fresh search.
- **Primary user.** When Autopilot and Intune both already show the intended user,
  nothing is written.
- **Group changes.** After adding or removing the device, the group itself is not
  read again; only the device's memberships are checked. When conflicting groups must
  be removed first, all the removals are sent and then confirmed together with one
  read, instead of one read after each removal.
- **Group lookup.** The pre-provisioning group is remembered for 15 minutes. Its
  membership is always read fresh. The remembered group is forgotten when Graph is
  signed in again or closed, when the tenant or group name changes, and after any
  failed membership change, so a renamed or replaced group is picked up next time.
- **Device details.** Data Settings > 5 and the automatic detail check request up to
  20 devices in each batch, instead of one request per device.

Some things were kept on purpose. Each step still re-reads Autopilot and Intune,
because steps can be hours or days apart and enrolment changes those records. Writes
are still followed by a fresh read, which is how the tool proves a change took
effect. Graph's throttling limits count each request inside a batch separately, so
batching saves time and round trips, not throttling allowance.

The counts come from a simulated tenant. They show what the script sends, not how
the real tenant responds, so a real-tenant check is tracked as GRAPH-CALLS-ACCEPT.
Updating the older tests to the new counts also found that a dictionary removal
leaked a `True` value into a function's output; it was fixed before release.

### 8 November 2026: Speed and Waiting Review

After the Graph work, the owner asked whether the rest of the script does the right
thing in the least time. Each area was measured first, and only areas where the
numbers justified a change were changed. Every change was then checked for identical
results on PowerShell 7 and Windows PowerShell 5.1.

What was changed:

- **Polling stopped while typing.** The real logs showed the inventory check never
  really ran in the background. While the prompt was open, the first screen or log
  line the check tried to write waited for Enter, so its Intune read (about 0.5 s)
  and save (about 2.5 s) only ran after the technician pressed Enter. The owner chose
  to keep true background checking rather than move the check to before each prompt.
  The check's messages are now collected instead of written, so nothing waits for
  the prompt: the read and save finish while the technician is still typing, and the
  collected messages are shown, in order, once typing ends. The timer that reports
  how long a Graph request took also wrongly counted that wait, and was corrected.
- **Saving device records.** Before each save, the script re-read and re-checked the
  whole records file. It now keeps a private copy of the last file it saved and
  checked. If the file on disk is exactly the same, the copy is reused; any change,
  even from another session, causes a full re-read. The copy is discarded after a
  failed save.   A later repeat measurement (median of three runs, realistic
  records) found saves 35-50% faster than a full re-read. For example, 100 records
  on Windows PowerShell 5.1 went from 15.7 to 7.9 seconds, and 25 records on
  PowerShell 7 went from 3.2 to 1.7 seconds. An earlier note here said 45-59%; that
  figure could not be reproduced and has been corrected. The owner approved this approach. One small difference:
  the extra loading checks run again only on the next full read, which happens
  whenever the file changes.
- **Comparing values before saving.** The routines that compare saved values were
  rewritten to do less work, making them 2-3 times faster. Comparing every saved
  attempt went from 1,491 ms to 453 ms in the test case.
- **Session report.** The HTML report was rebuilt one row at a time, which slows down
  badly as rows grow. It is now built in one pass, with identical output.

| Session report, 20 columns | Before | After |
| --- | ---: | ---: |
| Windows PowerShell 5.1, 100 rows | 183 ms | 5 ms |
| Windows PowerShell 5.1, 500 rows | 4,546 ms | 54 ms |
| PowerShell 7, 500 rows | 317 ms | 151 ms |

What was checked and left alone:

- **Waiting.** Every pause was recorded across the 14 Graph test actions, using the
  real retry delays. Only Step A pauses, twice for three seconds, while waiting for
  the upload to appear. That wait is needed, so nothing was cut.
- **Loading records.** The loader adds records one at a time. This costs under 1% of
  load time, and rewriting the validated loop carries more risk than it saves.
- **Document generation.** No recent log shows a document being produced, because
  document prerequisites failed on those machines. With nothing real to measure, it
  was not changed.

Lessons learned:

- The first faster comparison routine used a .NET list that the restricted
  PowerShell mode used by the shared-storage safety test does not allow. That test
  caught it, and the routine was rewritten to work in both modes. Speed changes to
  shared-storage routines must be tested in that mode as well.
- Tests load selected functions from the script. Any new helper must be added to
  each test's list, or many tests fail at once.

Five tests in [LocalCheckpoint.Tests.ps1](tests/LocalCheckpoint.Tests.ps1) now
protect the private copy: reuse when unchanged, a full re-read after an outside
change, keeping another session's audit entry, discarding after a failed save, and
the same result with or without the copy. The full suites passed on both hosts:
1,945 passed, 0 failed and 44 skipped.

## Completed Work

This ledger retains identifiers and unique outcomes, not repeated test counters. A completed offline task does not
complete its separately listed host/tenant/physical acceptance. Dated reports and limits are in
[Validation Results](TESTING.md#validation-results).

| Completed tasks                                        | Delivered outcome                                                                                                                                                                        |
| ------------------------------------------------------ | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| BACKLOG-TRACE-71, RELEASE-TWO-HOST                      | Complete no-skip offline release gate on both supported hosts, with matching input and bundle fingerprints and retained XML reports.                                                     |
| TODO 100                                               | Collision-safe original-start session/archive filenames and authoritative index; legacy/unknown starts retained.                                                                         |
| TODO 102                                               | Shared new/existing induction for standalone/bench, progress-preserving reuse, explicit cancel/full/conflict guards.                                                                     |
| TODO 103                                               | Explicit dispatch flag/time/actor, once-per-record latest-day totals, removed/incomplete exclusions and matching legacy override proof only.                                             |
| TODO 104                                               | Valid-sample Average/Min/Max, weighted totals, N/A and Dd HH:mm display; later TIME/EDIT work changes eligible hours, not event timestamps.                                              |
| TODO 105                                               | Avoid duplicate identity context while preserving complete handler text and event association.                                                                                           |
| TODO 106-107                                           | Width-aware aligned bench commands; Recover before Move; executable Device overview versus read-only Steps List.                                                                         |
| TODO 108-110                                           | Credited GPLv3 About/Notepad, fourteen status-labelled enhancements, caller-aware paging and one input-boundary blank row.                                                               |
| TODO 111-112                                           | Slice-aligned guides/tests and recorded historical cross-host/static/documentation release gates.                                                                                        |
| QA 1-6                                                 | Risk review, safe diagnostics/capability/index fixes, private-data hygiene, function help/source regions and AST-based QA.                                                               |
| LOCK-1 through LOCK-5                                  | Startup now coordinates explicit reservation inspection/recovery rather than exposing the strict primitive's refusal.                                                                    |
| LEASE-1 through LEASE-6                                | Reused-PID/start distinction, OS-held lease, complete verified external snapshots and guarded reacquisition.                                                                             |
| RESUME-1 through RESUME-5                              | Wire action-aware non-empty legacy conversion into reserved pre-auth startup; retain originals and prove repeat no-op. Operator confirmed resume.                                        |
| ASSURE-1 through ASSURE-7                              | Migration fault injection, documentation contracts, local security/dependency audits, exact-tool offline runner/CI definition, synthetic stats measurement and protected data inventory. |
| ASSURE-8 through ASSURE-11                             | Real tag/membership controller boundaries, retained accepted evidence after prerequisite failures and three in-memory guard-sensitivity probes. No exhaustive mutation score.            |
| 15 October INCIDENT-1 through INCIDENT-7               | First-lookup tenant binding, dispatch audit proof, explicit DeviceCode/reconnect, narrow group conflicts, U withdrawal, bounded feedback and SAM-first selection.                        |
| FOLLOWUP-1 through FOLLOWUP-5                          | Native diagnostic procedure, manifest display metadata/paging, restore/restart with reasons/history and correction-versus-tampering boundary.                                            |
| AUTH-1 through AUTH-6                                  | Expose SDK success-stream device-code instructions with clean Boolean result; explicit D/B/Cancel retry interaction and regressions.                                                     |
| PERF-1 through PERF-4                                  | Narrow exact tag reads, complete direct-membership snapshots and one-read/later-read-only checks; v1.0 serial discovery without unfiltered fallback.                                     |
| CONTRACT-1 through CONTRACT-4                          | Primary-source external API/SDK audit, focused synthetic contracts and unresolved support/least-privilege boundaries.                                                                    |
| TIME-1 through TIME-3, TIME-QA-1                       | Work-window estimates and array-shaped load evidence; schedule editor originally future, later implemented by EDIT.                                                                      |
| GROUP-1, NAV-1, LOG-1                                  | Literal Prefix/Exact exclusions, relevant target labels, corrected guide destination and reviewed supplied log outcomes. Current menus supersede the former flat routes.                 |
| MENU-1 through MENU-6                                  | Six caller-owned root areas, implemented read-only pages, session device-type default and later working editor.                                                                          |
| EDIT-1, EDIT-2, EDIT-QA, TECH-1                        | Effective schedule history/past-hour protection/zero-hour markings, guarded editor and Windows SAM/UPN/recent-user correction.                                                           |
| REPORT-1, REPORT-2, REPORT-QA                          | Immutable session export projection, formula neutralisation/HTML encoding, unique guarded CSV/HTML and empty/large/cancel paths.                                                         |
| INV-1, INV-2, INV-QA                                   | Bound hostname/Ethernet inventory, five-minute safe idle retries and final D/DO capture without false freshness claims.                                                                  |
| DOC-AUDIT-1, DOC-AUDIT-2, DOC-AUDIT-4                  | Capability/test mapping, measured helper dispositions and canonical action-table/documentation contracts. DOC-AUDIT-3 remains blocked.                                                   |
| MENU-AUDIT-1 through MENU-AUDIT-3, MENU-AUDIT-QA       | Real leaf/bench routes, setup and default-cancel repair, caller wording and route evidence; no invented destination.                                                                     |
| 23 October INCIDENT-1 through INCIDENT-3, INCIDENT-QA  | Exact AllDevices exclusion, contained startup discovery/reused pinned metadata and disposition of root evidence; no native/app/statistics acceptance claim.                              |
| REMED-1 through REMED-4, REMED-QA                      | Opt-in package IDs, shared action screen, durable one-POST intent/fresh reports and technician-PC clipboard link.                                                                        |
| REMED-ACCESS-1 through REMED-ACCESS-3, REMED-ACCESS-QA | Permission-readiness guard, loaded runtime provenance, safe actionable 403 and retained caller failures; no auto-consent/scope widening.                                                 |
| PERF-BENCH-1 through PERF-BENCH-4, PERF-BENCH-QA       | Skip unchanged saves, fresh per-redraw indexes/reverse history scan, due-ID inventory scheduling, phase timings and paired exact-output renderer measurements.                           |
| DOCGEN-1 through DOCGEN-8                              | Document contracts, dependencies, population, barcodes, isolated export, delivery and post-dispatch/preferences integration described above.                                             |

Earlier delivered work includes action-evidence/target guards, staged/checkpoint saves, append-only attempts,
shared-store offline prototypes and the 11 October screenshot implementation (TODOs 49-58). Incident prevention
TODOs 72/74/75, combined preparation/recovery TODOs 67-71/76-77 and hash discovery/import TODOs 78-81 are delivered
offline. Their tests do not close the retained operational acceptance tasks.

## Incident Review

| Finding                                                        | Repair or decision                                                                                                                     | What remains                                                                                            |
| -------------------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------- |
| Recovery array emitted null before appending a snapshot        | Assign arrays directly; diagnose one-based saved record/entry/type without disclosure.                                                 | Preventive code cannot repair existing files.                                                           |
| Approved 13 October attached records had one leading null each | Remove only those two approved lines in current device/audit copies; hash-verified originals outside discovery, other files unchanged. | Operator confirmed local resume, not tenant state after the earlier accepted deletion; TODO 73 remains. |
| Recovered owner had a reused RuntimeBroker PID                 | Compare start/executable; hold OS lease and retain complete snapshot before reacquisition.                                             | Never infer a foreign/cloud-backed workspace owner stopped.                                             |
| Lock recovery succeeded but legacy startup failed              | Connect strict version guard to semantic converter before auth; test non-empty actual CLI state, not empty fixtures.                   | Real workspace conversion/reload remains TODO 99/101.                                                   |
| SDK device-code instructions disappeared                       | Connect-MgGraph success output goes to Out-Host, not Out-Null; test prompt delivery under captured output.                             | Initial operator login confirmation does not accept every retry/CA path.                                |
| Native 0xC0000006 during authentication                        | Preserve STATUS_IN_PAGE_ERROR separately from managed Graph failure. UNC-loaded SDK is only a lead.                                    | Original-host fault/I/O evidence and approved comparison, not speculative upgrade.                      |
| Exact AllDevices spelling escaped prefix exclusions            | Add only exact approved literal and test actual controllers.                                                                           | No authority to remove unrelated groups or accept tenant outcomes.                                      |
| Remediation catalogue denied permission                        | Guard effective configuration/grants; preserve loaded path and 403 guidance.                                                           | Logs cannot distinguish stale JSON from absent consent; no submission proved.                           |
| Reported slow bench with growing records                       | Remove repeated local work and measure same-host exact output.                                                                         | Synthetic renderer gain does not identify real seconds or accept end-to-end speed.                      |
| Word HWND-zero/Quit and final-PDF MAC barcode defects          | Prove ownership after bootstrap, use by-ref Quit and 600-DPI sampling at unchanged geometry.                                           | No physical scan or consistent ten-second visible-page guarantee.                                       |
| Single-marker fixture collided with new author directives      | Clear directives only in its disposable copy before inserting one synthetic marker.                                                    | Never change production parsing/original templates to make the fixture pass.                            |
| Explicit manual completion rows suppressed                     | Validated explicit directive replaces baseline untracked classification; full saved-evidence guards remain.                            | Unmarked baseline and external/manual handoff protection remain.                                        |

These are actionable lessons and disposition, not a transcript archive. Preserve controlled original evidence and
use the [operator recovery procedures](OPERATIONS.md#troubleshooting); no new repair/replay approval is implied.
