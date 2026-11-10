<!-- omit from toc -->
# Autopilot Express Testing

Use this guide to run development checks and collect acceptance evidence. Offline tests use synthetic files,
mocked requests or isolated Demo CLI copies; they do not authorise tenant access or prove physical outcomes.
[OPERATIONS.md](OPERATIONS.md) describes operation; [TODO.md](TODO.md) owns outstanding work.

## Contents

The 3 November offline runs used a session-local copy of Pester 5.7.1 and reported
1,852 passed, zero failed and 44 skipped on each of PowerShell 7 and Windows
PowerShell 5.1. Registry tests were disabled because the sandbox denied registry
access. These historical runs are not the current, no-skip release gate, and
synthetic delivery adapters do not establish Word, printer or physical acceptance.
See [TODO.md](TODO.md#validation-blockers) for the remaining gates.

On 4 November 2026, the then-current 36-suite offline run completed on PowerShell 7.6.9
and Windows PowerShell 5.1.26100.9711. Each host reported 1,898 passed, zero failed,
44 skipped and zero not run; all 36 suites completed and the frozen inputs were
unchanged. The 44 document-integration cases were intentionally skipped because the
approved local dependency bundle was not enabled. The runner disabled XML reporting
because its environment probe requires CIM access denied in this sandbox. This is
useful regression evidence for that revision, not the no-skip release gate.
The JSON summaries and frozen-input fingerprints are in `%TEMP%` as
`autopilot-full-isolated-7.summary.json`, `autopilot-full-isolated-7.provenance.json`,
`autopilot-full-isolated-51.summary.json` and `autopilot-full-isolated-51.provenance.json`.

On 5 November, the complete offline gate passed on both hosts with the document
integration cases enabled: 1,945 of 1,945 tests passed on each, with no skips.
Complete XML reports and matching input fingerprints were retained. This does
not replace the separate real-environment acceptance checks below.

- [Contents](#contents)
- [Requirements](#requirements)
- [Run the Offline Suite](#run-the-offline-suite)
- [Run a Focused Suite](#run-a-focused-suite)
  - [Run Document Checks](#run-document-checks)
- [Static Analysis](#static-analysis)
- [Documentation Accuracy Gate](#documentation-accuracy-gate)
- [Test Catalogue](#test-catalogue)
- [Measure Offline Coverage](#measure-offline-coverage)
  - [Current Helper Coverage Audit](#current-helper-coverage-audit)
  - [Child Execution Attribution](#child-execution-attribution)
- [Document Generation Validation Plan](#document-generation-validation-plan)
- [Usability Acceptance](#usability-acceptance)
  - [Screenshot Review Backlog](#screenshot-review-backlog)
- [Real Environment Acceptance](#real-environment-acceptance)
- [Single-Device Live Pilot](#single-device-live-pilot)
  - [Approval and Baseline](#approval-and-baseline)
  - [Authorised Inspection](#authorised-inspection)
  - [Approved Build](#approved-build)
  - [Stop and Acceptance Criteria](#stop-and-acceptance-criteria)
- [Validation Results](#validation-results)
  - [Current Release Evidence](#current-release-evidence)
  - [DOCGEN-7/8/9 Current Gate](#docgen-789-current-gate)
  - [Bench Performance Measurements](#bench-performance-measurements)
  - [Security Audit Evidence](#security-audit-evidence)
- [External Contract Audit](#external-contract-audit)
- [Maintaining Tests](#maintaining-tests)

## Requirements

- Windows, approved FullLanguage PowerShell 7 and Windows PowerShell 5.1; run compatibility gates separately in fresh hosts.
- Exact approved Pester 5.7.1 and PSScriptAnalyzer 1.24.0. The maintained runner installs nothing.
- Writable external temporary evidence storage, never operational roots or repository output.
- Node.js/npm and approved markdownlint for documentation. Only MD013 is the established general lint exception.
- For explicitly enabled document integration: approved pinned libraries and a permitted isolated local document
  root. Word/PDF review, printers, scanners and network saving require their own acceptance approval.

Commands below run from this product directory. From the repository root:

```pwsh
Set-Location .\intune\devices\autopilot-express
```

Never point tests at operational data, change corporate policy to make fixtures work or use Live requests to raise
coverage. Synthetic ConstrainedLanguage tests do not certify enforced policy, ISE or every Graph SDK version.

## Run the Offline Suite

Use the root-resolved [maintained runner](development/Invoke-OfflineValidation.ps1) in each fresh supported host:

```pwsh
.\development\Invoke-OfflineValidation.ps1
```

The runner static-checks the entry point, itself and all discovered suites, runs Pester with terminating assertions,
then checks frozen source/config/test fingerprints. Empty discovery, failures, skips, unrun tests, failed containers
or changed inputs fail. XML, JSON, provenance and transcript go to a unique TEMP folder; repository report paths
are refused. Report actual totals, not a pinned old expected count.

DocumentIntegration cases are opt-in. Without the environment flag they are skipped, so an otherwise successful
default invocation is **not a passing complete no-skip gate**. After approving their local dependency/file scope,
run the complete gate with that flag and restore its previous value:

```pwsh
& {
    $previous = $env:AUTOPILOT_DOCUMENT_INTEGRATION
    try {
        $env:AUTOPILOT_DOCUMENT_INTEGRATION = '1'
        .\development\Invoke-OfflineValidation.ps1
    }
    finally {
        $env:AUTOPILOT_DOCUMENT_INTEGRATION = $previous
    }
}
```

This flag permits installed-library structural probes, not tenant work, real printing or physical acceptance.
The path-filtered Windows offline CI definition uses the same runner with read-only repository permissions/no
retained checkout credentials. Local results are not hosted CI acceptance; confirm environment and all cases there.
The runner includes the optional module and workers in static analysis and provenance. The standalone command below
can also be used when checking those files without running the complete suite.

## Run a Focused Suite

Import the exact approved Pester manifest rather than inbox Pester 3:

```pwsh
$pester = Get-Module -ListAvailable Pester |
    Where-Object Version -eq ([version]'5.7.1') |
    Select-Object -First 1
if (-not $pester) { throw 'Approved Pester 5.7.1 is required.' }
Import-Module -Name $pester.Path -Force -ErrorAction Stop
```

For an owning suite:

```pwsh
Invoke-Pester -Path '.\tests\WorkflowRehearsal.Tests.ps1' -Output Detailed
```

Use WorkflowRehearsal first for navigation, the action-specific suite for Graph work and the persistence neighbours
for shared evidence helpers. Focused passes must execute the intended cases without hidden skips/container failures;
they do not replace a full two-host release gate after code/definition/test changes.

For a documentation-only change, run the existing table/semantic-label/PowerShell-example contracts:

```pwsh
$configuration = New-PesterConfiguration
$configuration.Run.Path = '.\tests\ManifestDefinition.Tests.ps1'
$configuration.Run.PassThru = $true
$configuration.Should.ErrorAction = 'Stop'
$configuration.Filter.FullName = 'Maintained operator documentation contracts*'
$configuration.Output.Verbosity = 'Detailed'
$result = Invoke-Pester -Configuration $configuration
if ($result.PassedCount -ne 3 -or $result.FailedCount -ne 0 -or
    $result.SkippedCount -ne 0 -or
    $result.FailedContainersCount -ne 0) {
    throw 'Maintained documentation contracts did not all pass.'
}
```

Filtered-out cases appear in NotRunCount and are expected here, unlike the full-suite gate. Require all three
selected contracts to pass with no failures, skips or container errors. Do not remove table columns/labels or examples without running these
contracts; the Operations action table deliberately has exactly two columns and one row for each A-Q ID.

### Run Document Checks

With approved local libraries, preserve the integration flag and run the owning suite separately on each parent host:

```pwsh
& {
    $previous = $env:AUTOPILOT_DOCUMENT_INTEGRATION
    try {
        $env:AUTOPILOT_DOCUMENT_INTEGRATION = '1'
        Invoke-Pester -Path '.\tests\DocumentGeneration.Tests.ps1' -Output Detailed
    }
    finally {
        $env:AUTOPILOT_DOCUMENT_INTEGRATION = $previous
    }
}
```

Use [the validation matrix](#document-generation-validation-plan) to distinguish structural probes from approved
actual Word/PDF review. Never overwrite a supplied template to create a fixture. The module import itself can be
inspected without starting workers or loading document assemblies:

```pwsh
Import-Module '.\Modules\Documents\AutopilotExpress.Documents.psd1' -Force -ErrorAction Stop
Get-Command -Module AutopilotExpress.Documents | Sort-Object Name
```

## Static Analysis

After importing approved PSScriptAnalyzer 1.24.0, include module/worker scripts as well as entry point, runner and tests:

```pwsh
& {
    $ErrorActionPreference = 'Stop'
    $files = @('.\autopilot-express.ps1', '.\development\Invoke-OfflineValidation.ps1') + @(
        Get-ChildItem '.\tests' -Filter '*.Tests.ps1' -File |
            Select-Object -ExpandProperty FullName
    ) + @(
        Get-ChildItem '.\Modules\Documents' -Recurse -File |
            Where-Object Extension -in '.ps1', '.psm1', '.psd1' |
            Select-Object -ExpandProperty FullName
    )
    $findings = @($files | ForEach-Object {
        Invoke-ScriptAnalyzer -Path $_ -ExcludeRule PSUseSingularNouns, PSAvoidUsingWriteHost
    })
    $findings | Format-Table ScriptName, Line, RuleName, Message -AutoSize
    if ($findings.Count -gt 0) { throw 'Static analysis gate failed.' }
}
```

The exclusions cover collection-oriented internal names and intentional interactive output. Do not broaden them
or source suppressions to hide a defect. Record all checked inputs/tool versions; a clean entry point alone is not
a clean optional module/worker gate.

## Documentation Accuracy Gate

From the product directory, using the approved installed/cached tool:

```pwsh
npx --no-install markdownlint-cli@0.41.0 README.md OPERATIONS.md DEVELOPMENT.md TESTING.md SETUP.md CUSTOMISATION.md TECHNICAL.md FUNCTIONS.md TODO.md --disable MD013
```

Then run the [documentation contracts](#run-a-focused-suite), validate relative targets/fragments and incoming
links, and compare commands/defaults against owning code and definitions. Lint cannot detect obsolete instructions
or duplication. Keep author syntax in Operations, implementation contracts in Technical, outstanding work in TODO,
and results here; Development records completed work and decisions.

Check these easily confused behaviours explicitly:

- Startup Resume N immediately archives; Data > 2 instead requires selection, default No and CLEAR.
- Required-work completion is separate from proven dispatch and bench clearing. DO does not prove a successful build.
- Current saved/display letters are canonical; legacy IDs need semantic conversion, not manual key renaming.
- Five complete contextual events are not five wrapped lines. Root Enter exits; bench Enter refreshes.
- Explicit completion directives allow valid manual evidence; unmarked baseline untracked-work protection remains.
- Both output switches default off. With guards OFF, unapproved and Demo outputs may request printing; with guards
  ON, the restrictions return. Explicit review-only requests never print. OpenRequested is not visible opening or saving.
- Current checklist availability/source comparison is not owner approval; actual physical/tenant outcomes remain held.

Documentation-only checks do not rerun or supersede historical runtime gates. Website/Retype work is separate scope;
when approved, build a **copied temporary project**, not merely a different output directory, because Retype can
refresh the root manifest. Never edit generated docs or claim a local build establishes hosted publication.

## Test Catalogue

There are 37 existing suites, including DocumentGeneration, Remediation, BenchBatch, RecoveryEvidence and GraphCallBudget. Their current
files, not old per-file test counts, define scope. Graph/waits/manual observations are mocked unless an isolated
Demo/OS-child case says otherwise.

| Suite                                                                            | Principal behaviour and risks                                                                                                               |
| -------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------- |
| [DirectoryUser.Tests.ps1](tests/DirectoryUser.Tests.ps1)                         | SAM-first C/E eligibility, exact/name/suggestion searches, bounds, selection and recent users.                                              |
| [PrimaryUserAssignment.Tests.ps1](tests/PrimaryUserAssignment.Tests.ps1)         | Exclusive matching user evidence, object IDs, partial submissions/polling and no replay.                                                    |
| [GroupTag.Tests.ps1](tests/GroupTag.Tests.ps1)                                   | Exact guarded mutation/read-back, pending rechecks, failure retention and Demo isolation.                                                   |
| [GroupMembership.Tests.ps1](tests/GroupMembership.Tests.ps1)                     | Complete direct memberships, reference-only add/remove, exclusions, one check and later no-replay reads.                                    |
| [ManagedDeviceRemoval.Tests.ps1](tests/ManagedDeviceRemoval.Tests.ps1)           | Confirmed exact deletion, delayed absence, replacements and cancellation.                                                                   |
| [DeviceIdentity.Tests.ps1](tests/DeviceIdentity.Tests.ps1)                       | Unique serial/registration, partial/malformed reads, bound inventory, Intune details update (archives, not found, skips) and idle-input child behaviour. |
| [MutationTarget.Tests.ps1](tests/MutationTarget.Tests.ps1)                       | Fresh exact identity before writes; refuse cached/mismatched/absent targets.                                                                |
| [GraphEvidence.Tests.ps1](tests/GraphEvidence.Tests.ps1)                         | Complete safe paging/collections, duplicates and profile/group/organisation identity, plus when the saved group answer is reused or re-read. |
| [GraphTransport.Tests.ps1](tests/GraphTransport.Tests.ps1)                       | Safe Graph URIs, request context, bounded GET retries/Retry-After and redacted diagnostics.                                                 |
| [GraphCallBudget.Tests.ps1](tests/GraphCallBudget.Tests.ps1)                     | Counts every Graph request in 14 common actions against a simulated tenant, checks each outcome, and fails if any count changes. Set `GRAPH_BUDGET_OUT` to a file path to save the counts as JSON. |
| [GraphModuleSelection.Tests.ps1](tests/GraphModuleSelection.Tests.ps1)           | Coherent common versions, exact manifests/order and conflict refusal.                                                                       |
| [TenantBinding.Tests.ps1](tests/TenantBinding.Tests.ps1)                         | Pin/context/account, startup capabilities, authentication interaction and unsafe legacy adoption.                                           |
| [ManifestDefinition.Tests.ps1](tests/ManifestDefinition.Tests.ps1)               | Schema/actions/graph/phases, canonical conversion and help/documentation contracts.                                                         |
| [PhysicalMilestone.Tests.ps1](tests/PhysicalMilestone.Tests.ps1)                 | Physical prerequisites, confirmation correction, no-failures baseline invalidation, recovery and incomplete-work refusal.                   |
| [RecoverySubmission.Tests.ps1](tests/RecoverySubmission.Tests.ps1)               | Durable unblock intent, interrupted responses, no replay, guided Allowed observation and the conservative wait.                             |
| [CompletionSafety.Tests.ps1](tests/CompletionSafety.Tests.ps1)                   | Truthful state, readiness, descendant invalidation, completion/dispatch and retained evidence.                                              |
| [HandoffGuidance.Tests.ps1](tests/HandoffGuidance.Tests.ps1)                     | Guidance-only external work, trigger evidence and no invented mutation/completion.                                                          |
| [WorkflowRehearsal.Tests.ps1](tests/WorkflowRehearsal.Tests.ps1)                 | Actual copied Demo CLI, menus/bench/routing/dispatch, reports/work patterns, save faults and retained context.                              |
| [BenchInduction.Tests.ps1](tests/BenchInduction.Tests.ps1)                       | Full/occupied/conflicting positions, existing-record reuse and progress preservation.                                                       |
| [BenchLinks.Tests.ps1](tests/BenchLinks.Tests.ps1)                               | Slot/workflow serial, CI, status and metadata agreement.                                                                                    |
| [ScannerSelection.Tests.ps1](tests/ScannerSelection.Tests.ps1)                   | Normalisation/ambiguity, explicit prefixes, leading zeros and cancellation.                                                                 |
| [BenchBatch.Tests.ps1](tests/BenchBatch.Tests.ps1)                               | T/X/U/A list/range/ALL parsing, single-selection precedence, refusals, default-No confirmation and ordered Demo batch.                      |
| [PersistedState.Tests.ps1](tests/PersistedState.Tests.ps1)                       | Typed states/dates/history, legacy compatibility and no empty substitution.                                                                 |
| [StorageFailure.Tests.ps1](tests/StorageFailure.Tests.ps1)                       | Read/parse/save failures, unreadable audit preservation and true missing-file startup.                                                      |
| [StorageRoot.Tests.ps1](tests/StorageRoot.Tests.ps1)                             | Authority/sticky fallback, conflicting copies, migration and receipt boundaries.                                                            |
| [LocalSessionSafety.Tests.ps1](tests/LocalSessionSafety.Tests.ps1)               | Reservation/ownership/mode separation, actual OS contention/release and retained recovery files.                                            |
| [RecoveryEvidence.Tests.ps1](tests/RecoveryEvidence.Tests.ps1)                   | BACKUP-POLICY date/tenant layout, tenant key fallbacks, size inventory, move-only organise, collisions and default-No report action.       |
| [InterruptedWrite.Tests.ps1](tests/InterruptedWrite.Tests.ps1)                   | Staging/backup/promotion/cleanup faults, blocking markers and archive safety.                                                               |
| [LocalCheckpoint.Tests.ps1](tests/LocalCheckpoint.Tests.ps1)                     | Detached proposals, save order, unresolved checkpoints, read-only inspection and the private save copy (reuse, outside change, failed save). |
| [CheckpointWorkflow.Tests.ps1](tests/CheckpointWorkflow.Tests.ps1)               | Actual copied CLI save faults, restart refusal, successful resume and retained history.                                                     |
| [AttemptHistory.Tests.ps1](tests/AttemptHistory.Tests.ps1)                       | Detached snapshots, sequence/identity/dates, legacy and recovery retention.                                                                 |
| [AttemptHistoryPersistence.Tests.ps1](tests/AttemptHistoryPersistence.Tests.ps1) | Append-only history, rewrite/truncation refusal and record/audit agreement.                                                                 |
| [SyncSubmission.Tests.ps1](tests/SyncSubmission.Tests.ps1)                       | Conditional no-failures choice and baseline, cancellation, failure-path sync, append-only receipts, uncertain-intent resubmission and save-failure stop. |
| [ImportSubmission.Tests.ps1](tests/ImportSubmission.Tests.ps1)                   | Append-only `ImportSubmissions` record ledger (IMPORT-RECEIPTS): session-bound saves, Submitting rollback, append-only refusal for both ledgers, and Live-only legacy import journal migration with delete-after-save, review retention and Demo no-op. |
| [SharedStorageSafety.Tests.ps1](tests/SharedStorageSafety.Tests.ps1)             | Disabled runtime and disconnected reserved revision/history/recovery/preview contracts.                                                     |
| [Remediation.Tests.ps1](tests/Remediation.Tests.ps1)                             | Metadata/preferences/access, one-POST durable intent, fresh reports, clipboard and caller menus.                                            |
| [DocumentGeneration.Tests.ps1](tests/DocumentGeneration.Tests.ps1)               | Settings/jobs/evidence, pinned dependencies, structural population/barcodes, supervised export/delivery/cleanup and integration boundaries. |

## Measure Offline Coverage

After approving the opt-in integration scope, use the same full gate with coverage in PowerShell 7:

```pwsh
& {
    $previous = $env:AUTOPILOT_DOCUMENT_INTEGRATION
    try {
        $env:AUTOPILOT_DOCUMENT_INTEGRATION = '1'
        .\development\Invoke-OfflineValidation.ps1 -Coverage
    }
    finally {
        $env:AUTOPILOT_DOCUMENT_INTEGRATION = $previous
    }
}
```

The runner instruments the original entry script, not every module/worker. AST fixtures retain source metadata;
copied-script statements and OS-child activity are not automatically merged. Coverage target zero requests
measurement, not a release exemption; every discovered test must still execute/pass. Review uncovered commands
against actual behaviour, not helper-name mentions or a claimed exhaustive percentage.

### Current Helper Coverage Audit

The retained 23 October pre-document measurement is historical: 302 functions, 31 suites, 1725 passing tests;
7485/9505 commands (78.75%), 2020 missed. It does not describe current-module coverage. Its JaCoCo INSTRUCTION
counters are Pester commands, not CPU instructions; line counters are different denominators.

Sixteen helpers lacked literal test-name mentions. Fourteen had measured original-source hits. The profile-display
getter remained 0/3 commands; bench removal 0/7 had separate copied-Demo R/record-retention assertions. Neither is
fully covered by inference. Exact helper dispositions and all missed commands remain in
`%TEMP%\AutopilotAudit-CoverageCore-43c8ca54dc3c410487b25deaf67048e3` (`coverage.xml`, `helper-disposition.clixml`,
tests/summary/provenance/transcript). The related AST map is
`%TEMP%\AutopilotHelperAudit-f29dd877f51b47fca03c86196ada5665\helper-map.clixml`.

### Child Execution Attribution

Copied Demo rehearsals can run in the parent process; do not call every copy an OS child. Four actual child cases
in the historical coverage revision cover DeviceIdentity idle input success/failure and LocalSessionSafety surviving/
terminating owner handles. They assert behaviour without merged child instrumentation. Synthetic idle Graph reads
are not tenant inventory; OS lease tests are not network/power-loss qualification.

The maintained collector cannot measure exhaustive branch/path coverage or merge these instrumented children.
AST if/switch/loop counts are not a branch denominator. DOC-AUDIT-3 therefore remains BLOCKED; no test count or
copied-script assertion closes it.

## Document Generation Validation Plan

Use disposable template copies, synthetic version-two records and feature-owned local job roots. Original DOCX
files remain unchanged. Review [the maintained contracts](TECHNICAL.md#document-pipeline) and
[author syntax](OPERATIONS.md#supported-template-methods) before designing fixtures.

| Area              | Required checks                                                                                                                                                                                                                            |
| ----------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| Settings          | Both off/independent enablement, exact typed precedence/false/pin release, explicit save, invalid paths/enums/tokens/durations and no evaluated configuration. Disabled must avoid dependency/Word/output work.                            |
| Detached job      | Exact IDs/tenant/mode/cycle/date order, no live references or new queries, required/optional missing fields, actual dispatcher/final-user semantics and no invented manual sign-offs.                                                      |
| Completion        | Every explicit grouped step needs qualifying current-cycle evidence. Verified and TechnicianConfirmed both qualify; incomplete/submitted/stale/simulated/legacy/exception-only do not. Unmarked baseline protection remains.               |
| DO disclosure     | Normal D yields no line even with stray reason. DO's matching saved full reason appears exactly once; missing reason fails. No DO-created Y or unresolved author markers.                                                                  |
| Dependencies      | Pinned source/hash/target/licence, disclosed Yes/No/WhatIf, no-prompt consent refusal, offline/missing/corrupt/partial/redirected inputs, locked publication and child-only loads. Word registration is not activation.                    |
| DOCX              | Split/repeated/escaped markers in supported stories, reviewed native text/date/checkbox controls, unknown/duplicate/misplaced targets, source drift, unchanged tables/sections/images/objects/classification and exact warning exceptions. |
| Barcodes          | Exact Code 128 decode, printable/length bounds, quiet zones/integer bars/no caption, geometry/span/margins and no resizing. Fit-only omission is explicit with readable text retained; invalid payload fails.                              |
| Worker            | Both parent hosts, actual UTF-8 protocol/STA startup, deadline/hang/partial/malformed result, exact owned Word cleanup, pre-existing Word untouched and retained uncertainty. No scanner prompts or Graph/state writes.                    |
| Delivery          | All policies and guard ON/OFF combinations, explicit review-only and Demo restrictions, both exports before delivery, handler/printer absence, intent-before-Shell faults, no implicit repeat, requested not physical output and manual-save unconfirmed. |
| Cleanup/retry     | Owned metadata/digests, compact success, reversible failed expiry/zero setting, retain unknown/active/uncertain evidence, original snapshot retry and hash-verified delivery-only reuse.                                                   |
| Integration       | Actual copied CLI tracked/bench D/DO, no enqueue on failed workflow save, output failure cannot undo dispatch/slot clearing, preference/CLI/help/default/cancel routes and idle-input ownership.                                           |
| Rendered review   | Synthetic all-complete versus H-incomplete, normal versus DO, exact text/labels/dates/reason, two certificate pages, checklist layout, all final-PDF barcodes and longest realistic values.                                                |
| Actual acceptance | Approved exact templates/packages and Word host: physical default-printer output, scanner payloads, fonts/layout/labels/screen-reader structure, manual Save As/reopen and existing Word work untouched.                                   |

For a single-marker fixture, remove existing directives **only in its disposable copy** before adding the synthetic
marker. Otherwise current author directives collide with a test that assumes one target. Never weaken production
parsing or edit the source template to repair that fixture.

PNG decode is not final-PDF decode; final-PDF decode is not a paper scan. Shell return/open intent does not prove
visible rendering. Measure preparation, queueing, export, each delivery and total cleanup separately. DOCGEN-9 needs
consistent generation **and visible opening** within ten seconds, not one favourable run with preparation excluded.
Actual printing, network saving and physical acceptance stay under DOCGEN-10 approval.

## Usability Acceptance

Use disposable Demo sessions and controlled screenshots. On both supported hosts, record terminal/version,
narrow/wide dimensions, RawUI availability and observed result. Exercise every screen/route, not only mocked
Write-Host ordering. The pending technician review must include:

- Correct mode/header/context on redraw; full wrapped identities, no overlapping command/prompt/output and non-colour state labels.
- Every root/submenu/bench action and caller return; root Enter Exit, bench Enter refresh, setup 1-50 and cancel/defaults.
- Serial/CI early validation, correction retaining other values, scanner rules, leading zeros and explicit P:/S:/CI: ambiguity.
- Windows-derived technician preview/default No, recent/search/cancel and no privileged identity fallback.
- V/Devices > 2 same executable record, W read-only guide, direct Outstanding Work without reselection, continued Maintain edits.
- Guide >/< followed by Enter, N/P step detail, STEP LIST/return, resize/clamping and unavailable RawUI. Enlarge unusably tiny windows.
- Five **complete** newest-first results before options/prompt, correct device association, L full text, long errors and no consumed result objects.
- Normal/DO dispatch refusal/cancel/reason, retained evidence after reload, completed-record selection versus still-occupied bench.
- U/restore/restart safety, no dependent accepted-work withdrawal and no remote rollback claim.
- Working-time editor/history, locked past hours, Sick/RDO/WFH zero-time days, invalid dates/times and save/cancel/failure.
- Settings/remediation/documents, explicit preference save, CLI pins, failure visibility and no workflow completion from utility actions.
- Startup Resume Y/N versus Data > 2 selection/No/CLEAR, using disposable files only; archive retains audit/history and needs no reconnect.

### Screenshot Review Backlog

The implemented 11 October criteria remain acceptance inputs, not proof the current terminal is accepted:

| Original TODO | Criteria retained                                                                                                                        |
| ------------- | ---------------------------------------------------------------------------------------------------------------------------------------- |
| 49            | One ordered menu source drives visible numbers and actual routes; reorder/default/invalid tests.                                         |
| 50            | Persistent mode header, combined site/Graph context, readable narrow/no-RawUI fallback.                                                  |
| 51            | Input/result placement and retention; later approved five complete events before options supersede the old five-line/below-input layout. |
| 52            | Height-aware guide pages, boundaries/resize, detail and command collision safety; no execution/save.                                     |
| 53            | Declined induction retains editable serial/CI/site/type defaults.                                                                        |
| 54            | Early identity validation plus final recheck; no premature record/write.                                                                 |
| 55            | Next/device-switch routes and clear outcome/device/evidence ownership.                                                                   |
| 56            | Outstanding Work opens the selected workflow directly.                                                                                   |
| 57            | Maintain remains available after edit/refusal/cancel without hidden save failure.                                                        |
| 58            | Integrated regressions and actual current two-host counts, not fixed historical totals.                                                  |

Current grouped menus supersede historical flat menu numbers. The acceptance targets are behaviours and owning
routes in [Operations](OPERATIONS.md#navigation-and-device-selection), not obsolete screenshot aliases. TODO 48,
TIME-4, INV-HOST and PERF-BENCH-ACCEPT remain outstanding.

## Real Environment Acceptance

Follow [the tenant approval gate](OPERATIONS.md#tenant-approval-gate). Approvals for authentication/read inspection,
mutations, device work and document physical delivery are separate. Success in one does not authorise the next.
Compare each intended change independently in portals; do not use destructive probes to test permissions.

Record approved immutable tenant/account/group/profile/device identities, actual application/client and scopes,
roles/licensing/CA, source/config/host/SDK revision, permitted requests/statuses, service outcomes and durable reload.
Pending state is not completed work. Read-only observations must not be presented as accepted writes or a physical build.

Remediation acceptance additionally needs approved beta catalogue/report queries, exact package/version/device,
one confirmed submission and report interpretation with no unique correlation claim; verify local clipboard/portal.
Inventory acceptance needs actual hostname/primary wired-adapter semantics and freshness including docks/pass-through.
Native host diagnosis and repeated sign-in behaviour remain separate from API acceptance. Shared remains disabled.

## Single-Device Live Pilot

This prepared procedure is not approval or evidence of execution. Use one dedicated approved serial, Local storage
and the intended corporate host/policy. Do not weaken application control, execution policy or ownership safeguards.

### Approval and Baseline

Record approver/operator, pilot serial/CI/site/type/tag, exact group/profile IDs, Graph account/application and
approved scopes/roles/CA; regular technician and explicit final owner; host/SDK/source/definitions; window/evidence/
retention/recovery owner/escalation. The document owner must confirm v1.4 currency and the approver accept
[all 26 checklist steps and differences](OPERATIONS.md#checklist-coverage) before work.

Explicitly authorise required deletion, tag, membership, user assignments/sync and physical reimage/reset.
Recovery unblock and hash import need specific inclusion if required; do not deliberately fail production enrolment.
Preserve original records/bench/audit and a portal baseline for serial/Autopilot/managed/Entra IDs, tag, profile,
memberships and primary-user relationships. Ensure no other technician works that serial; local leases do not
coordinate separate computers. Resolve existing markers without discarding evidence.

### Authorised Inspection

After authentication/read approval, start Live and compare account/tenant/profile/group with the approved identities.
Startup requests write-capable configured scopes; there is no enforced read-only/dry-run switch. During inspection
do not select mutations. Resolve A and compare every identity to baseline. Stop on absent/ambiguous/unexpected
registration; an external upload handoff is not presence proof. Exit if mutation approval is not yet granted.

### Approved Build

1. **A-D:** resolve, approved managed deletion, exact tag and pre-provisioning membership; independently verify targets/outcomes.
2. **E-H:** perform network/imaging/OOBE, intended profile, pre-provisioning/reseal and boot. Wrong profile/failure stops work.
3. **I-K:** explicitly select regular technician, verify assignment and group removal, then physical first sign-in.
4. **L-N:** check applications in order. If a failure needs it, use the approved named portal remediation and
   request sync at M; M does not perform that remediation. Otherwise confirm L, then verify that M's default
   records no failures without sync. Finish updates/procedures/shutdown and preserve the CLI's receipt rules.
5. **O:** select the approved final owner; independently check Autopilot and exclusive managed-user evidence.
   Retain Verified versus TechnicianConfirmed honestly.
6. **Dispatch/reload:** explicitly dispatch, exit/resume and compare IDs, steps/history/proof. Only the pilot bench
   slot clears after saved dispatch. Complete external ZENworks/CMDB/installation/collection/disposal separately.

If recovery is necessary and approved, use X/P/Q with physical reset, fresh managed absence, required wait and
manual Allowed observation. Check retained history; use T to prepare again rather than reusing old physical evidence.
Documents, if approved, remain an independent optional acceptance path and cannot certify external handoffs.

### Stop and Acceptance Criteria

Stop on wrong/ambiguous tenant/device/group/profile/owner, permissions/policy/storage failure, unresolved marker,
physical failure or portal disagreement. Submitted/timeout/save failure may follow a successful remote mutation:
preserve evidence and inspect under approval, never blindly repeat. Deleted managed records have no automatic rollback.

Release requires a reviewed complete real build, expected portal outcomes, truthful evidence, successful save/reload,
external handoff evidence and no unresolved failures/markers. Record defects/reproduction and repeat affected pilot
checks after repair. The approver accepts remaining limitations before bulk imaging; this gate remains outstanding.

## Validation Results

On 4 November 2026, nine focused sync, recovery, milestone, persistence and manifest suites ran on both hosts.
Each passed 436 of 437 checks; the remaining check identified the deliberately stale function catalogue after
the new helpers were added. The separate copied-CLI Demo rehearsal passed all nine scenarios on each host,
including Enter at the new no-failures choice. These offline checks do not establish tenant or physical outcomes.

The latest complete offline runs used the maintained runner on both hosts, including its static checks.
Earlier static analysis also passed across 87 maintained PowerShell source, test and module files, using the
documented exclusions for `PSUseSingularNouns` and `PSAvoidUsingWriteHost`. After the earlier documentation
updates, the 89-case ManifestDefinition suite passed on both hosts. Separate tenant and physical acceptance
remain outstanding; see [TODO.md](TODO.md#retained-acceptance-and-approval-holds).

The 4 November Markdown lint pass predates these later guide updates. A recheck
could not start because the sandbox denied access to the previously configured
npm-cache parent. This session's effective policy does not include the newly
saved writable sandbox-root entry, and sandbox shells use different cache-parent
GUIDs. The saved settings also list the previous cache as read-only. The updated
guides are not yet represented as linted.

On 28 October 2026, the complete GraphModuleSelection (42) and WorkflowRehearsal (265) suites passed **307/307
on each of PowerShell Core 7.6.9 and Desktop 5.1**, with no failures, skips or failed containers. This includes
inert manifest discovery, exact-file trust consent/refusal, UNC/policy boundaries, startup readiness exit, weekly
and site navigation, year-boundary/empty periods and existing workflow routes. The first combined Core attempt
failed 35 startup cases due to a missing readiness stub; the corrected complete gate, not that failed attempt,
is the result above. Trust actions used mocks/disposable fixtures, never installed SDK files.

Earlier focused readiness/deletion/persistence validation passed 139 selected cases on Desktop. Deletion covers
accepted-write read-only rechecks, exact DELETE404 reconciliation, replacements and failed discovery; persistence
covers invalid dates without transcript errors. These results are not a full-project or full document-generation
rerun, nor affected-host authorisation, Word/PDF, printing or tenant acceptance. The historical results below retain
their original scope and revision; they do not imply that later source changes were present.

### Current Release Evidence

The 5 November full two-host offline runs included the document integration cases and completed all
36 suites. Each XML report records 1,945 executed, successful cases, with no failures, skips, unrun tests
or failed containers. Both runs used Pester 5.7.1 and PSScriptAnalyzer 1.24.0. Their 91 recorded input
fingerprints match each other and the current recorded inputs; the ten document-bundle fingerprints also
match between runs. This closes the offline gate, not Word, printer, scanner, tenant or affected-host acceptance.

The reports are under `%USERPROFILE%\.copilot\autopilot-express-validation\Reports`:

- PowerShell 7.6.9: `release-Core-6d7a7eb2c0754438b79b36eb6ed56d32`
- Windows PowerShell 5.1.26100.9711: `release-Desktop-e77473c8db214384a2e2c3fb4d0c7a0b`

Each folder contains the XML report, JSON summary, input provenance, release context and transcript.
Console redraws can obscure intermediate messages; use the retained transcript and final reports to
review the outcome.

| Retained result                                               | Scope and limit                                                                                                                                                                                          |
| ------------------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| 5 November: 1,945/1,945 on each host                         | Complete 36-suite no-skip offline gate, including document integration and the updated reservation checks; matching recorded inputs and retained XML reports.                                             |
| 5 November: 63/63 reservation-safety cases on each host     | The updated suite checks successful and failed child output, the deadline and termination of a timed-out child. No failures, skips, unrun cases or changed inputs.                                        |
| 5 November: 296/296 document cases on PowerShell 7           | Complete document suite, including the 44 opt-in cases; no failures, skips, unrun cases or changed inputs. This is not a complete application release run.                                                |
| 5 November: 44/44 document integration cases on each host    | Focused opt-in run using the verified isolated bundle; no failures or skips. Other cases were intentionally filtered out. No Word, printer or tenant operations were tested.                              |
| 5 November: combined PowerShell 7 run interrupted           | The process exited with control-C status `0xC000013A` before a summary; the source of the interruption is unknown. No failing test lines were reported before it stopped.                                  |
| 4 November: 1,898 passed on each host; 44 skipped             | Then-current 36-suite offline run; no failures, unrun tests, failed containers or changed inputs. These full runs did not execute the opt-in document cases.                                              |
| 4 November: static analysis passed on 87 files                | Maintained source, test and module set; excludes `PSUseSingularNouns` and `PSAvoidUsingWriteHost` as documented.                                                                                           |
| 26 October: 227/227 document cases on each host               | Core 7.6.8: 195.92 s; Desktop 5.1.26100.9711: 240.04 s; Pester 5.7.1, integration enabled, no failed/skipped/unrun cases. Explicit manual-marker correction included.                                    |
| Later DO-focused gate: 5/5 on each host                       | Core 16.54 s; Desktop 19.79 s. DO assertion expansion increased discovery to 229; the full 229 was not rerun.                                                                                            |
| Recovered full Core gate: 1951/1951, 32 suites                | Historical integrated run. All 85 recorded application/test/module inputs matched at recovery; not a fresh full Desktop pass.                                                                            |
| Corresponding full Desktop: 1935 passed, 16 document failures | Template edits exposed fixture/mapping mismatch; all 1726 non-document cases passed. Disposable single-marker fixture corrected, then document-only gates rerun. Never relabel this a passing full gate. |
| Earlier full 1908/1908 per host                               | Historical integration milestone before later source/template/assertion changes, not current release proof.                                                                                              |

Full 227 reports: `%TEMP%\AutopilotDocgen9-ExplicitManual-Full-Core.xml` and
`%TEMP%\AutopilotDocgen9-ExplicitManual-Full-Desktop.xml`. Later focused reports:
`%TEMP%\AutopilotDocgen9-DO-Conditional-Core.xml` and `...-Desktop.xml`.

### DOCGEN-7/8/9 Current Gate

Retained review root: `%TEMP%\AutopilotDocgen9-Final-d784bc1db42a4241b8cce3f2a1929af5`.
Use these locators rather than treating a preview job ID or repeated chat report as acceptance:

| Evidence in that root                                                  | What it establishes                                                                                                                                       |
| ---------------------------------------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------- |
| MaintainedGates/Core/tests.xml and Desktop-Final/tests.xml             | The full historical pass/failure distinction above.                                                                                                       |
| Invoke-ReviewBenchmark.ps1 / Benchmark-Latest.json                     | Reproducible synthetic timing setup and measured phases.                                                                                                  |
| Invoke-CompletionReview.ps1 / Completion-Review-20261026-085619.json   | Six Y groups when all explicit steps qualify; five when H is incomplete, H's group blank despite DO.                                                      |
| Completion-Review-20261026-205036.json / DO-Conditional-PDF-Proof.json | Normal D has no disclosure; DO has the exact full matching reason once.                                                                                   |
| Retained PDF/page-image/decoder outputs                                | Exact hostname/wired MAC text and all eight identifier barcodes across normal/override PDFs, two/six A4 pages, dates/review labels and no author markers. |

The final-PDF MAC defect was corrected with 600-DPI sampling, not a physical geometry change. Export precedes
delivery, supplementary metadata follows delivery and owned proofing settings are restored. Source templates were
not rewritten by tests. An oversized synthetic failure remains evidence rather than being hidden.

Latest prepared synthetic Shell returns were 9.25/9.29 seconds, but earlier returns were 15.01/10.70 seconds.
Preparation itself took 13.58/15.73 seconds outside that clock. Those results do not time visible rendered pages
or establish consistency; DOCGEN-9 remains IN PROGRESS. Printing/scanning, actual manual Save As, final mapping/
authority and physical-build acceptance remain held.

### Bench Performance Measurements

Historical 23 October paired same-host renderer measurements used eight positions, width 160, 25/100/500/1000
records, one or 1000 attempts per record, three warm-ups and eleven samples. Output equality was checked; host
writes were stubbed. Values are median milliseconds, not console/Graph/save/end-to-end measurements.

| Retained attempts per record | 25 records    | 100 records   | 500 records   | 1000 records   |
| ---------------------------- | ------------- | ------------- | ------------- | -------------- |
| 1, before -> after           | 5.56 -> 1.80  | 11.02 -> 1.80 | 44.87 -> 3.50 | 80.02 -> 5.89  |
| 1000, before -> after        | 42.48 -> 1.38 | 47.64 -> 1.75 | 80.80 -> 3.57 | 118.42 -> 6.61 |

Evidence: `%TEMP%\AutopilotBenchPerformance-127dd51d02c64065a03ba2cce9e8419a`. Accept actual bench entry/refresh/
mutation separately with phase timings, due inventory and retained audit sizes. These gains do not establish the
cause of the operator's observed seconds or close PERF-BENCH-ACCEPT.

### Security Audit Evidence

The dated offline audit used Gitleaks 8.30.1: reachable product history had no findings; a working-tree GUID ownership
nonce was a reviewed false positive, not globally suppressed. Remote alert 1 remains unresolved, validity unknown;
local scans cannot establish revocation and SECURITY-1 remains PAUSED.

Fourteen installed dependency versions were checked. The development Graph 2.29.1 bundle included Kiota Abstractions
1.16.3 with high advisory GHSA-7j59-v9qr-6fq9, fixed in 1.22.0. This does not identify that dependency in SDK 2.41.1.
Approve a coherent SDK update/acceptance under SECURITY-2; never substitute a DLL. Disabled Dependabot alerts/403
are unavailable evidence, not a clean audit. Document-library advisory results are separately dated in
[Technical](TECHNICAL.md#dependency-reference).

Evidence stored under TEMP is host-local and may expire. Before release, retain permitted XML/provenance/diagnostic
files in approved controlled evidence storage; rerun a gate if its exact revision/result cannot be substantiated.
Older milestone counters are not a release criterion and have been removed from routine instructions.

## External Contract Audit

The retained 22 October audit compared production routes/bodies/permissions and SDK v2.41.1 source with primary
documentation before the nested-menu revision. It established local contract findings, not tenant acceptance.
Its 358 focused synthetic Core checks passed; evidence is
`%TEMP%\AutopilotContractAudit-Core-4bc936d5519d428eb48493f7d1187850.xml`.

| Unresolved finding                          | Acceptance boundary                                                                                                                                                                                                         |
| ------------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| v1.0 managedDevices('{id}')/users/$ref POST | Retrieved public resource/update docs did not establish this exact write; a guessed reference's 404 does not prove invalidity. Require tenant acceptance and independent exclusive read-back; never PATCH read-only userId. |
| Autopilot contains(serialNumber, ...)       | Public list docs do not explicitly establish this filter. Exact local checks/paging protect identity, not filter support. No silent inventory-wide fallback.                                                                |
| Group permissions                           | Documented addition uses GroupMember.ReadWrite.All plus Device.Read.All; runtime requests broader Directory.Read.All. Consent does not establish delegated role; least-privilege changes need review.                       |
| Deployment profile/recovery beta            | Route support is separate from assigned profile/Allowed. Bodyless allowNextEnrollment 204 remains Submitted.                                                                                                                |
| SDK auth fallback                           | Application adds no automatic flow switch, but SDK 2.41.1 can use process cache after persistence failure or device code after browser-launch failure. Actual host prompts/cancellation/CA remain acceptance work.          |

| Operation / owning boundary                             | Primary reference and what still needs verification                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 |
| ------------------------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Initialize-GraphSession / Close-GraphSession            | [SDK authentication source](https://github.com/microsoftgraph/msgraph-sdk-powershell/blob/v2.41.1/src/Authentication/Authentication.Core/Utilities/AuthenticationHelpers.cs): success-stream instructions, context and tenant guards; actual SDK/CA interaction.                                                                                                                                                                                                                                                                                                                                                                                    |
| Initialize-GraphRequestContext / Invoke-GraphApiRequest | [Set-MgRequestContext](https://learn.microsoft.com/en-us/powershell/module/microsoft.graph.authentication/set-mgrequestcontext): zero SDK retries/timeout plus local bounded GET policy; never write replay.                                                                                                                                                                                                                                                                                                                                                                                                                                        |
| Discovery and capability probes                         | [Organisation](https://learn.microsoft.com/en-us/graph/api/organization-list), [profiles](https://learn.microsoft.com/en-us/graph/api/intune-enrollment-windowsautopilotdeploymentprofile-list?view=graph-rest-beta), [Autopilot](https://learn.microsoft.com/en-us/graph/api/intune-enrollment-windowsautopilotdeviceidentity-list), [managed devices](https://learn.microsoft.com/en-us/graph/api/intune-devices-manageddevice-list), [devices](https://learn.microsoft.com/en-us/graph/api/device-list), [groups](https://learn.microsoft.com/en-us/graph/api/group-list): complete paging, exact identity and query-specific tenant acceptance. |
| Directory resolution/search                             | [Users](https://learn.microsoft.com/en-us/graph/api/user-list) and [advanced-query matrix](https://learn.microsoft.com/en-us/graph/aad-advanced-queries): eventual consistency/count where required, bounded discovery and immutable revalidation.                                                                                                                                                                                                                                                                                                                                                                                                  |
| Primary user                                            | [Autopilot assignment](https://learn.microsoft.com/en-us/graph/api/intune-enrollment-windowsautopilotdeviceidentity-assignusertodevice) and [managed resource](https://learn.microsoft.com/en-us/graph/api/resources/intune-devices-manageddevice): assignment acceptance is not the exclusive managed relationship; support gap above.                                                                                                                                                                                                                                                                                                             |
| Hash import                                             | [Import](https://learn.microsoft.com/en-us/graph/api/intune-enrollment-importedwindowsautopilotdeviceidentity-import) and [state](https://learn.microsoft.com/en-us/graph/api/resources/intune-enrollment-importedwindowsautopilotdeviceidentitystate): pending 200 is not complete registration; preserve journal/registration-ID/fresh-presence checks.                                                                                                                                                                                                                                                                                           |
| Managed deletion                                        | [DELETE](https://learn.microsoft.com/en-us/graph/api/intune-devices-manageddevice-delete): exact ID, bodyless; 204 still requires valid absent read-back.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                           |
| Group Tag                                               | [Update properties](https://learn.microsoft.com/en-us/graph/api/intune-enrollment-windowsautopilotdeviceidentity-updatedeviceproperties): exact tag read, no propagation-time promise.                                                                                                                                                                                                                                                                                                                                                                                                                                                              |
| Membership                                              | [Direct memberships](https://learn.microsoft.com/en-us/graph/api/device-list-memberof), [add](https://learn.microsoft.com/en-us/graph/api/group-post-members), [remove](https://learn.microsoft.com/en-us/graph/api/group-delete-members): fresh eligible targets; DELETE must retain /$ref, never object deletion.                                                                                                                                                                                                                                                                                                                                 |
| Recovery/sync                                           | [allowNextEnrollment](https://learn.microsoft.com/en-us/graph/api/intune-enrollment-windowsautopilotdeviceidentity-allownextenrollment?view=graph-rest-beta), [syncDevice](https://learn.microsoft.com/en-us/graph/api/intune-devices-manageddevice-syncdevice): accepted bodyless POST is not physical outcome.                                                                                                                                                                                                                                                                                                                                    |

[Profile assignment timing](https://learn.microsoft.com/autopilot/profiles#assignment-of-windows-autopilot-deployment-profiles-to-devices)
varies; tag visibility is not profile assignment. Tenant-wide beta settings sync is not a documented per-device tag
accelerator. Do not add automatic sync or speculative version/permission changes to evade these boundaries.

## Maintaining Tests

- Reuse owning suites and real production helpers, with exact immutable targets and request/evidence assertions.
- Load newly extracted dependencies in every fixture, including repeated blocks; register mocks before zero-call checks.
- Preserve AST metadata; do not count a name mention, copied script or uninstrumented child as original-source coverage.
- Restore environment, prompt globals, process handles and in-memory guard probes in finally. Desktop must retain its
  system module path when launched from Core; a hidden Get-FileHash is a harness failure, not permission to drop hashes.
- Keep empty/single/multiple arrays, dictionaries, typed booleans and ISO dates compatible on both hosts. String false
  must not become true completion. Missing legacy fields can be compatible; malformed evidence must fail without writes.
- Preserve all original-template/operational bytes. Deliberate faults use disposable state and must assert retained
  evidence/no mutation, not only an exception string.
- Interactive SDK mocks must emit their documented streams and test delivery under captured output. A flag-only
  assertion previously missed invisible device-code instructions.
- Repeat focused checks after each meaningful edit and full two-host gates for changed runtime/contracts. Retain
  failed/interrupted reports; never present partial execution or a later narrow pass as a new full release gate.
