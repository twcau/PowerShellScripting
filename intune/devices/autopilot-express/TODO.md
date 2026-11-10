<!-- omit from toc -->
# Autopilot Express Prioritised TODOs

<!-- markdownlint-configure-file {"MD013": {"tables": false}} -->

Persistent working queue recovered on 2 November 2026 from all eight product guides,
historical task records and all 30 supplied analysis logs (42,438 lines). This file
survives editor/chat failures. Existing identifiers, approvals and completion
history in [DEVELOPMENT.md](DEVELOPMENT.md#tracked-tasks) remain authoritative;
they are not
renumbered or discarded. Older log failures are not automatically current
defects. Table rows remain on one line to preserve accessible Markdown rendering.

## Contents

- [Priority and Status](#priority-and-status)
- [Active Work and Evidence](#active-work-and-evidence)
- [Retained Acceptance and Approval Holds](#retained-acceptance-and-approval-holds)
- [Deferred Scope](#deferred-scope)
- [Log Audit Evidence](#log-audit-evidence)
- [Validation Blockers](#validation-blockers)

## Priority and Status

P0 means incident disposition requiring immediate owner attention, not a proven
vulnerability. P1 blocks requested output or release acceptance; P2 is a reliability,
usability or tooling gap; P3 is deferred scope. BLOCKED, PAUSED and HELD items cannot
be closed without the specified evidence or owner approval. Completed work is recorded
in [DEVELOPMENT.md](DEVELOPMENT.md), not repeated as an open task here.

## Active Work and Evidence

| ID | Priority | Status | Next action and acceptance |
| --- | --- | --- | --- |
| LOG-REMAINING | P2 | EVIDENCE REQUIRED | Obtain exact reproductions and deployed hashes for abrupt transcripts and remaining inventory failures. The 27 October recovery wait was explained by repeated unblock requests; verify the new guard on an approved affected host. |
| AGENT-INTERRUPTION | P2 | EVIDENCE REQUIRED | Obtain correlated editor or agent debug logs for the interrupted sessions. Existing file-watcher errors do not establish the cause; do not attribute it to Cortex or Word without evidence. |
| VALIDATION-INTERRUPTION | P2 | EVIDENCE REQUIRED | Investigate if the complete test-run interruption recurs. A 5 November PowerShell 7 diagnostic ended with control-C status 0xC000013A; its source is unknown. Reservation child checks are now bounded, and later complete runs passed on both hosts. |
| VALIDATION-DISPLAY | P2 | EVIDENCE REQUIRED | Investigate console redraws that obscured intermediate test output. Keep failure details visible or readily available without changing application menu behaviour. Both 5 November runs ultimately passed. |
| DOC-LINT-POLICY | P2 | BLOCKED | The 5 November lint recheck was denied. Each sandboxed shell uses a different cache-parent GUID, so the saved fixed-path grant is not reliable. The effective policy lists the Packages ancestor as read-only. Agree a suitable policy, then verify it before rerunning lint. |
| BACKLOG-TRACE-62-63 | P2 | EVIDENCE REQUIRED | Locate the descriptions or original task records for archived tasks 62 and 63. The available archive does not describe them; do not invent their contents or assume they are complete. |

## Retained Acceptance and Approval Holds

The following are not silently released by a general instruction to continue work.
Removing template guards for testing is explicitly authorised; production approval
and physical acceptance remain distinct, and must not prevent that testing.

| ID | Priority | Status | Required evidence or dependency |
| --- | --- | --- | --- |
| SECURITY-1 | P0 | PAUSED | Credential-owner disposition of alert 1: validity/exposure, rotation or revocation where required, and explicit resumption. No confirmed compromise inferred. |
| INCIDENT-HOST | P0 | BLOCKED | Original fatal/Application Error/WER evidence and deployed revision; timestamp/timezone, PID and process start correlation. |
| INCIDENT-CORTEX | P0 | BLOCKED | Detection rule/action, process tree, command lines/hashes and owner disposition. No bypass or blanket PowerShell allowlisting. |
| INCIDENT-8 | P1 | BLOCKED | Native in-page I/O evidence and same-version fixed-local SDK comparison; network loading is a plausible cause, not proved by the screenshot alone. |
| SECURITY-2 | P1 | HELD | Approved coherent SDK update/comparison and separate tenant acceptance; no bundled DLL substitution. Non-admin local deployment is implemented, not tenant approval. |
| TODO 31 | P1 | PAUSED | Explicit actual-tenant authentication/read approval; consent, RBAC, Conditional Access and action acceptance. |
| TODO 73 | P1 | PAUSED | Inspect current tenant state before replaying failed-save incident work. Existing local repair/resume is not authorisation to replay mutations. |
| PERF-5 | P1 | HELD | Actual serial-filter, tag/direct-membership reads and repeated sign-in on affected tenant/host. |
| REMED-ACCEPT | P1 | HELD | Approved beta catalogue/query, consent/RBAC/licensing, then separately approved exact package/device execution, reports and clipboard/portal checks. |
| INCIDENT-APP | P1 | HELD | Actual package submission/result and affected-device WebView2 outcome; sync success alone is insufficient. |
| APP-FLOW-ACCEPT | P1 | HELD | During an approved pilot, verify M's no-failures default after baseline confirmation and the separate failure/sync path on a suitable device. Tenant and mutation approvals remain separate. |
| TODO 99 | P1 | BLOCKED | Safe owning-host recovery and fresh operational migration inventory; foreign/reparse locks remain protected. |
| TODO 101 | P1 | BLOCKED | After TODO 99, approved real canonical migration, load/save/reload and repeated no-op proof; preserve originals. |
| TODO 98 | P1 | PAUSED | Checklist-owner v1.4 currency and 26-step comparison acceptance. |
| INCIDENT-9 | P1 | PAUSED | Original-host device-code/CA, tag/group/account/correction/restart and complete physical outcomes after TODO 73/48/31/10 approval. Verify the recovery guard and wait without repeating an accepted unblock. |
| TODO 10 | P1 | PAUSED | Dedicated authorised Local pilot, saved resume, induction, checklist and dispatch. |
| OUTPUT-CERTIFICATE | P1 | BLOCKED | Final marker/control/group mappings, prefills and manual/uncollected fields approval. Renderer selected; testing may proceed with guards OFF. |
| DOCGEN-10 | P1 | HELD | After mapping/performance acceptance, actual paper/barcode scan, final layout/accessibility and manual save/reopen; no requirement to block testing generation/printing. |
| DOCGEN-9 | P2 | IN PROGRESS | Measure repeatable visibly opened PDFs within ten seconds under agreed cold/warm/preparation conditions. Shell return timing does not prove visibility. |
| DOC-AUDIT-3 | P2 | BLOCKED | Branch/path and instrumented-child merged coverage; command coverage alone is not exhaustive. |
| INCIDENT-STATS | P2 | HELD | Authorised underlying dispatch/timing records for independent historical screenshot recalculation. |
| TODO 48 | P2 | PAUSED | Actual narrow/wide terminal, keyboard and screen-reader visual/input acceptance. |
| TIME-4 | P2 | HELD | Original-host working-time examples, exclusion labels and diagnostic-folder navigation. |
| INV-HOST | P2 | HELD | Actual ConsoleHost input/Ctrl+C, live hostname/Ethernet freshness and dock/pass-through identity. |
| PERF-BENCH-ACCEPT | P2 | HELD | Real-host unchanged-redraw versus mutation timings, due inventory and realistic retained/audit scale. |
| INTUNE-DETAILS-ACCEPT | P1 | HELD | Run Data Settings > 5 against the real tenant on an approved host. Confirm the filled-in hostname, Ethernet and Wi-Fi MAC, Entra device ID, primary user and Windows version match the Intune portal; that deleted devices show as not found and keep their saved details; and that archive backups are created and the session still loads. Offline tests do not prove this. |
| GRAPH-CALLS-ACCEPT | P1 | HELD | On an approved host and tenant, confirm the 7 November call reductions behave as tested: startup and device-detail batches are accepted, any refused batch falls back to single reads without a new error, and a group renamed within 15 minutes is picked up after a failed change. The call counts come from a simulated tenant only. |
| SPEED-ACCEPT | P2 | HELD | On a real console, confirm the 8 November changes: the inventory check no longer appears to stall while typing, and its held messages appear once typing ends; saves feel quicker with a realistic records file; and a second session's change is still picked up. Timings so far are from test harnesses only. |

## Deferred Scope

| ID | Priority | Status | Decision needed before implementation |
| --- | --- | --- | --- |
| OUTPUT-NETWORK | P2 | HELD | Next planned feature: a CSV export for network whitelisting. Needs the target platform's exact column names and order, which MAC addresses to include (Ethernet, Wi-Fi or both), how to treat missing, stale or duplicate devices, and a sample import file to test against. Data Settings > 5 now collects the device details this export will need. |
| GRAPH-SELECT | P3 | PROPOSED | The Autopilot serial lookup returns every property because it has no `$select`. Narrowing it needs a check of every caller and a real-tenant test, as this endpoint has historically been unreliable when `$select` is combined with `contains` filters. |
| OUTPUT-CMDB | P3 | HELD | CMDB schema/order, reconciliation keys, create/update/recipient/relationship rules and representative reconciliation tests. |
| TODO 6 | P3 | DEFERRED | Shared backend selection, ownership/concurrency/recovery qualification and approved migration. Prototype is not production Shared support. |
| GUIDED-MODE | P3 | PROPOSED | Decide whether to add the previously proposed manual portal/device mode without Graph sign-in, retaining workflow and audit records while distinguishing technician confirmations from Graph verification. It is not implemented. |
| AUDIT-SEARCH | P3 | PROPOSED | Decide whether to support historical activity and build-status search by serial, actor, site and date/time, including the separate need for an all-machine audit. Local history alone is not that service. |
| DIRECTORY-SEARCH | P3 | PROPOSED | Decide whether broader final-user fuzzy discovery is needed beyond the existing bounded suggestions, without weakening explicit selection and Live identity checks. |
| PERMISSION-UI | P3 | PROPOSED | Decide whether to disable unavailable actions in the interface based on capabilities. UI state must not replace tenant permissions or the existing action guards. |
| EXTERNAL-AUTOMATION | P3 | PROPOSED | Decide separately whether to automate checklist storage, CMDB/Zenworks handoffs or machine-side actions, or record manual handoff confirmations. These remain outside the approved workflow. |
| DEVICE-CERTIFICATE | P3 | PROPOSED | Decide whether to place a build certificate on the built computer, including access, content and security. Generating a document for a technician does not deliver it to the device. |
| FUTURE-CATALOGUE | P3 | PROPOSED | Decide separately on service-management and compliance integration, safe offline queueing, localisation, telemetry, custom-token hardening, remote or collaborative operation, and audit/security/retention enhancements. None is authorised merely by appearing here. |

## Log Audit Evidence

Evidence is in the supplied `errors/logs-for-analysis` folder. Coverage includes
the 23 October boundary transcript continuing into 26 October, through 2 November.
No logs or operational records were modified.

| Finding | Evidence | Interpretation |
| --- | --- | --- |
| Missing BuildCycleId | 29 October 00:04:19, lines 877-879 | Document path failed after dispatch; actual factory fixed. Legacy repair remains explicit. |
| Inventory identity validation | 32 occurrences across nine files; 2 November 17:02:03, lines 187-198 and 244 | Real inventory error; fresh re-enrolment/cached-registration case reproduced. Logs omit comparison values, so not every occurrence has a proved common cause. |
| DELETE 404 | 27 October 13:07:51, lines 6338-6411 and 12421-12519 | Historical failure; current reconciliation/tests already address it. |
| Optional date diagnostics | 47 occurrences across nine files | Caught diagnostics, not 47 application crashes; current TryParse implementation fixes them. |
| Session ownership | 15 files | Protected stale/live ownership handling, not proof of a defect. Preserve evidence and recover only verified stopped owners. |
| Authentication cancellation | 30 October 08:50:11 and 14:14:57 | Expected pause/reconnect behaviour; downstream failures are not independent root causes. |
| Trust/prerequisites | 27-29 October | Internet-marked document files and network Graph deployment; explicit trust review required. Library failure details insufficient to prove a template-engine defect. |
| Unapproved print prohibition | 29 October 00:04:19 | Removed by default for the expressly authorised testing phase, independently for both document types. |
| Recovery wait and repeated unblock | 27 October 15:18:56-15:22:58 | Seven unblock submissions preceded the final readiness check, which was 117 seconds after the last submission. The observed wait was expected; the new direct-selection guard prevents a further accepted submission from resetting it. |

## Validation Blockers

- An earlier sandbox session denied external instruction reads despite the saved
  `readonlyPaths` entry. The current session could read the applicable language
  instructions; the earlier user authorisation remains part of the history.
- An unprivileged session-local Pester 5.7.1 copy enabled offline runs on both
  PowerShell 7 and Windows PowerShell 5.1. The 4 November full runs passed 1,898
  tests on each host, with no failures, but skipped 44 document-integration tests;
  the registry test plugin was disabled because the sandbox denies HKCU. On
  5 November, later normal-user runs passed the complete no-skip offline gate on
  both hosts; see [TESTING.md](TESTING.md#current-release-evidence).
- Offline tests do not establish actual Word rendering, physical printing, tenant
  actions or affected-host acceptance. Available results are recorded in TESTING.
- Pester's XML test report cannot be produced in this sandbox. The report writer
  reads operating-system details through CIM, which the sandbox blocks, so Pester
  stops before returning its results. The 5 November normal-user runs outside
  this sandbox produced complete XML reports, so this limitation no longer blocks
  the recorded offline release evidence.
- A later combined PowerShell 7 diagnostic ended with control-C termination
  status `0xC000013A` before producing a summary. The source of that interruption
  is unknown; it is not evidence that the earlier `0xC0000006` application crash
  had the same cause. The reservation tests now bound their child-process waits,
  and subsequent complete runs passed on both hosts.
- A later Markdown lint recheck could not start because the sandbox denied the
  previously configured npm-cache parent. Sandbox shells use different
  cache-parent GUIDs, and this session's effective policy lacks the newly saved
  fixed-path entry. The saved settings also list that cache as read-only.
  The earlier lint pass does not establish that the subsequently updated guides
  have passed lint.
- The earlier Python decoder install was denied by sandbox policy. Windows'
  built-in media support enabled a sampled review without changing that policy;
  actual current-host visual acceptance remains open.
