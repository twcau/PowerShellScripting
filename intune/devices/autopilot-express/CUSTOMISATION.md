<!-- omit from toc -->
# Autopilot Express Customisation

Use this guide when adapting a reviewed deployment or implementing an approved enhancement. First-time deployment
and rehearsal are in [SETUP.md](SETUP.md); daily controls are in [OPERATIONS.md](OPERATIONS.md). Decisions and
implementation history are in [DEVELOPMENT.md](DEVELOPMENT.md); outstanding approvals are in [TODO.md](TODO.md).
Configuration is not a mechanism for bypassing identity, evidence or storage guards.

## Contents

- [Choose the Smallest Change](#choose-the-smallest-change)
- [Understand the Four Orders](#understand-the-four-orders)
- [Inspect the Supplied Workflow](#inspect-the-supplied-workflow)
- [Reuse Existing Actions](#reuse-existing-actions)
- [Change Workflow Definitions Safely](#change-workflow-definitions-safely)
- [Change Configuration](#change-configuration)
- [Add a New Action](#add-a-new-action)
- [Reuse Modules and Helpers](#reuse-modules-and-helpers)
- [Timeouts and Retry Policy](#timeouts-and-retry-policy)
- [Development and Extension](#development-and-extension)
- [Change Management](#change-management)
- [Review and Hand Over](#review-and-hand-over)

## Choose the Smallest Change

`documentGeneration.EnforceDocumentGuards` is a validated Boolean, default `false`
during testing. It applies to both document types and is resolved through runtime,
saved, session and explicit CLI layers. `true` restores unapproved-profile DRAFT
and print refusal. Neither value changes `ApprovedForLive`, template mappings,
tenant identity, dispatch evidence, trust policy or delivery receipts. Explicit
review-only requests remain non-printing. Use document Settings `[G]` to toggle;
release CLI pins with `[9]` if necessary, and `[8]` saves preferences separately.

| Requirement | Start Here | Why |
| --- | --- | --- |
| Different approved tenant, group, profile or scanner | Runtime JSON and the owner path in Setup | No handler change is normally needed; tenant acceptance still is. |
| Different default site/type catalogue | Script Sites/DeviceTypes | These arrays feed selection, tags and physical guidance; saved records are not automatically migrated. |
| Better wording or display codes | Manifest guidance/display metadata | Display is separate from stored identity; preserve semantic actions and evidence. |
| Approved workflow sequence or prerequisites | Manifest steps, dependency graph and physical checklist | Existing handlers may be reusable; changing an order can still invalidate safety assumptions. |
| New document layout/bindings | Operations authoring rules and reviewed profile | A new runtime action is not needed to change a document. Preserve originals and revalidate changed bytes. |
| New tenant operation or milestone | Owning existing handler, then the new-action process below | Arbitrary PowerShell function names in JSON are not supported plugins. |
| New persistence/schema | Record/checkpoint/migration helpers and compatibility tests | Never repair a schema by editing saved evidence into the new shape. |

Work on reviewed source and disposable definitions/data. Record the request, intended result, approval boundary,
risks, chosen approach and rejected alternatives before implementation. Do not copy a live storage folder into a
test that may archive, migrate or overwrite it. Never dot-source the interactive entry script to obtain its helpers.

## Understand the Four Orders

1. **Manifest sequence:** the `steps` array supplies the ordered enabled workflow list. Next eligible selection walks
   that order; alphabetical IDs or PowerShell declaration positions do not independently determine it.
2. **Eligibility:** `prerequisiteStepIds`, execution type, activation and current saved evidence decide whether a
   step may run. Putting a step earlier in the array does not satisfy its prerequisites or physical conditions.
3. **Guidance phases:** phase `actionNames` organise instructions. They do not register an executable function or
   provide a second independent dispatcher.
4. **PowerShell availability and calls:** bootstrap definitions needed early must exist before their top-level use.
   Runtime functions then call their dependencies through the controller/handler path. Moving a declaration does
   not reorder a build, and extracting it can break script-scoped configuration, state or nested closures.

The current normal flow is A-O, with conditional recovery P/Q. `displayCode` is presentation; saved `id` is identity.
`workflowIdVersion` 2 describes the canonical ID scheme, not permission to relabel an old attempt. A handler can be
called only after tenant/eligibility checks and still requires its own fresh target and action-specific evidence.

## Inspect the Supplied Workflow

Run this read-only inspection from the product directory. It parses JSON; it does not start the application:

```pwsh
$manifest = Get-Content -LiteralPath '.\autopilot-express.manifest.json' -Raw | ConvertFrom-Json
$manifest.steps | Select-Object id, displayCode, actionName, enabled,
    executionType, activation, prerequisiteStepIds | Format-List
```

Read the current [manifest](autopilot-express.manifest.json) and governing checklist together. Use
`Assert-ManifestDefinition` and `Test-ManifestDependencyGraph` through the established tests: they reject malformed
types, duplicate/missing IDs, unsupported action names and invalid dependencies. Validation is not a proof that
every proposed physical order, phase description or tenant operation is correct. Review those separately.

## Reuse Existing Actions

These are semantic action names accepted by validation and dispatched by `Invoke-AutopilotManifestStep`. Reuse the
matching action rather than copying its handler under a different name. The function reference links each complete
contract; [TECHNICAL.md](TECHNICAL.md#workflow-execution-and-evidence) explains the controller/result/save sequence.

| Semantic Action | Existing Handler | Boundary to Retain |
| --- | --- | --- |
| ResolveAutopilotDevice | Invoke-StepResolveAutopilotDevice | Unique fresh serial/identity and tenant binding; import journal if explicitly needed. |
| RemoveAssociatedManagedDevice | Invoke-StepRemoveAssociatedManagedDevice | Exact target, confirmation and verified absence, not merely DELETE acceptance. |
| ApplyGroupTag | Invoke-StepApplyGroupTag | Exact site/type-derived tag; one read then retained Submitted/read-only recheck. |
| ValidateDeploymentProfile | Invoke-StepValidateDeploymentProfile | Intended assignment plus technician observation; tag propagation is not profile proof. |
| AddToPreProvisioningGroup | Invoke-StepAddPreProvisioningGroup | Fresh eligible Entra target, complete direct membership and reference-only changes. |
| ClearUserlessEnrollmentStatus | Invoke-StepClearUserlessEnrollmentStatus | Submitted is not observed Allowed or physical recovery readiness. |
| AssignTechnicianPrimaryUser | Invoke-StepAssignTechnicianPrimaryUser | Explicit eligible regular technician and action-specific identity/user evidence. |
| RetryFailedApplications | Invoke-StepRetryFailedApps | No-failures outcome depends on the confirmed baseline; failure-path sync is not portal remediation or proof of installation. |
| RemoveFromPreProvisioningGroup | Invoke-StepRemovePreProvisioningGroup | Exact group/member reference and retained no-replay evidence. |
| AssignFinalPrimaryUser | Invoke-StepAssignFinalPrimaryUser | Explicit final-user selection, enabled immutable account and independent read-back. |
| ConfirmImagingAndOobe | Invoke-StepConfirmPhysicalMilestone | Explicit physical observation; no synthetic Graph verification. |
| ConfirmReseal | Invoke-StepConfirmPhysicalMilestone | Ordered manual evidence and pre-provisioning conditions. |
| ConfirmBootToSignIn | Invoke-StepConfirmPhysicalMilestone | Actual boot/sign-in observation. |
| ConfirmFirstSignIn | Invoke-StepConfirmPhysicalMilestone | Actual intended sign-in, not assigned-user metadata alone. |
| ConfirmApplicationBaseline | Invoke-StepConfirmPhysicalMilestone | Manual application checks; no inference from a sync or remediation request. |
| ConfirmUpdatesAndShutdown | Invoke-StepConfirmPhysicalMilestone | Manual updates/procedures/shutdown. |
| ConfirmRecoveryReadiness | Invoke-StepConfirmRecoveryReadiness | Current-cycle recovery evidence, wait, managed absence and manual readiness. |

The same physical handler branches on supported semantics; adding a new JSON name does not automatically add its
guidance or evidence rules. Safety-critical roles also resolve through `Get-ManifestActionStepId`: absent or
ambiguous role definitions fail rather than choosing an arbitrary occurrence.

## Change Workflow Definitions Safely

For example, a requested reorder has three questions: is it physically safe, does the existing handler still mean
the same thing, and can retained evidence still be interpreted correctly? An earlier display position alone must
not allow a manual milestone before its required preparation.

1. Inspect the current array and dependencies using the read-only command above. Write the proposed order and the
   reason for every changed edge; obtain checklist-owner approval where physical sequencing changes.
2. In an isolated candidate copy, move the **whole existing step object**, retaining its saved ID/action. Change
   dependencies only where the approved design calls for it. Do not alter operational JSON or attempt history.
3. Review phase guidance, execution/activation and semantic-role uniqueness. Do not remove an edge merely because
   a test or the current device says Blocked. Review T/X, next-step selection and recovery as well as manual selection.
4. Exercise raw definition rejection, graph cycles/missing dependencies, eligible/ineligible branches, descendant
   invalidation, retained pending submissions and normal/override dispatch in the existing owning suites.
5. Rehearse the copied Demo CLI, including incomplete steps, exit/resume and old evidence compatibility. Demo is
   not physical/tenant acceptance. Run the required two-host gates before release.

Changing only a summary usually needs no evidence migration. Changing what a saved step means may need one even
when its ID is unchanged: old success cannot silently certify a new requirement. Renaming IDs requires an explicit
semantic migration across current/previous records, snapshots, attempts, audit and receipts under the existing
ownership/checkpoint contract. The real operational migration remains blocked under TODO 99/101.

## Change Configuration

Definitions load once at startup. Restart after an approved edit and verify the loaded path and immutable tenant,
profile and group, rather than assuming a same-named file elsewhere was used. Session choices do not rewrite JSON.
Current ownership and exact supplied values are in [SETUP.md](SETUP.md#deployment-owner-configure-the-organisation).

Do not treat script 0.3.1, manifest 1.6.2 and runtime 1.0.0 as a single release version. Record source/config hashes.
The supplied runtime currently names `Intune-Autopilot-ESP-Prod`; the earlier Testing-group decision is historical,
not an instruction to restore that value. Names identify intended configuration; Live selection must resolve IDs.

Display-only changes still need width/paging/accessibility checks. New sites/types affect generated tags and
existing selection semantics. Scope/module changes need coherent dependency selection and tenant-owner review;
do not widen permissions to hide a failure, substitute one SDK DLL or add an automatic inventory-wide fallback.
Shared remains disabled: editing its JSON values does not activate a supported backend.

## Add a New Action

Start only when existing semantics cannot implement the approved requirement. Keep the new operation in its owning
boundary; do not make manifest data executable or build a second Graph/storage framework.

1. Define inputs, target identity, prerequisites, confirmation/default/cancel behaviour, allowable outcomes, durable
   evidence and what must happen after unknown remote acceptance. Define an observable falsifying test first.
2. Reuse an existing handler's `Device`/`StepDefinition` convention and `New-OperationResult` shape where appropriate.
   Use the source contract, not a copied success dictionary. Initialise all fields and preserve cross-host types.
3. Reuse the common Graph context/transport, immutable-target resolution, redaction and result helpers. GET retry
   logic is not mutation retry logic. Define intent/receipt handling before any non-idempotent submission.
4. Add the semantic name to the validator's allowlist and an explicit dispatcher case. Supply an implemented
   handler; update physical-handler branches only if the action is genuinely a manual milestone.
5. Add the reviewed manifest step, prerequisites, execution/activation, phase guidance and endpoint/permission
   descriptions. Update semantic-role helpers, T/X plans and final gating if their roles genuinely change.
6. Route the result through `Write-ManifestStepResult`, guarded record/audit saving and publication. A handler return
   is not a durable save. Preserve accepted evidence on later reads/failures and invalidate dependent work honestly.
7. Test exact targets, Demo isolation, wrong tenant/serial/cycle, partial/malformed reads, cancel, accepted-but-pending,
   transport failure, save failure, explicit later recheck, no replay, dispatch and retained-history compatibility.
8. Review migration, reports, document completion mappings and checklist scope. Do not let a new action certify
   untracked external work. Update its function help, these guides, dated Development record and validation evidence.

Do not emit Verified merely because a request returned 2xx. Manual completion is TechnicianConfirmed with explicit
observation; Demo is Simulated. If no reliable verification exists, document the limitation and keep the result
truthful. Do not add a generic automatic retry around the entire controller.

## Reuse Modules and Helpers

The main file has eight source regions for navigation, not eight independently importable modules. Helpers share
configuration, reservation, current session, mode and Graph context. Extracting a function into another project
requires deliberately replacing those dependencies; copying its declaration alone does not make it safe.

The optional [document module manifest](Modules/Documents/AutopilotExpress.Documents.psd1) exports 19 APIs and loads
Public/Private definitions without rendering, downloading, Word activation or document-assembly loading. Its private
helpers are not public extension points. Five fixed workers implement process isolation, not general command hosts.
Use the public settings/job/prerequisite/start/receive APIs in their documented lifecycle; do not launch a worker
with an invented payload or import document DLLs into the Graph session.

[FUNCTIONS.md](FUNCTIONS.md) covers all 370 declared functions, parameters, defaults, help contracts and named call
relationships, including nested helpers. Use it to find dependencies, then read the owning implementation and test.
The catalogue does not resolve every dynamic/member call or establish behavioural coverage. Tests use controlled
AST extraction rather than loading the interactive application; retain source metadata and include dependencies
before callers in fixtures. Empty/single/multiple arrays and dictionaries must work on Core and Desktop.

## Timeouts and Retry Policy

| Control | Current Default | Meaning and Change Risk |
| --- | --- | --- |
| TransportTimeoutSeconds | 60 seconds | Per Graph request, not the whole operation or SDK sign-in deadline. |
| TransportMaxAttempts | 3 | Bounded GET attempts; never permission to repeat a mutation. |
| TransportBackoffSeconds / TransportMaxDelaySeconds | 3 / 60 seconds | Local read retry delays, including bounded Retry-After handling. |
| MaxRetryAttempts / RetryBackoffSeconds | 5 / 3 seconds | Action-specific verification policy; not used as a blanket tag/membership wait. |
| Tag/membership verification | One immediate read | Later explicit check reads retained targets without reposting. |
| InventoryPollingMinutes | 5 minutes | Safe foreground idle-query interval; not guaranteed service freshness. |
| Document worker | 60 seconds; integer 1-3600 | Externally supervised worker deadline; does not certify delivery or visible opening. |
| Failed document retention | 7 days; integer 0-3650 | Feature-owned cleanup eligibility; zero disables automatic expiry. |
| Shared lockTimeoutSeconds | 30 seconds in disabled prototype config | Not Local lease expiry or permission to steal a reservation. |

Read validation and action-specific use before changing a numeric value. Nested attempts and service/SDK behaviour
mean an attempt count is not a wall-clock deadline. Longer waits can make the bench unusable; shorter waits can
produce more honest Submitted results without proving failure. Keep recovery's required waiting/observation rule,
inventory cadence, document deadline and authentication timeout conceptually separate.

## Development and Extension

The entry script implements the local workflow, UI, Graph boundaries and persistence. Definitions describe policy
and actions; the optional document module handles document jobs separately. Start at the owning helper and its
existing test suite, not a parallel implementation. The historical autopilot-express.txt scaffold is not authoritative.

| Change                 | Owning source                                                                                                      | Validation                                                                                           |
| ---------------------- | ------------------------------------------------------------------------------------------------------------------ | ---------------------------------------------------------------------------------------------------- |
| Screen layout/feedback | Show-ScriptScreen, Add-ScreenFeedback and screen helpers in the entry script                                       | Workflow rehearsal; actual narrow/wide terminal acceptance.                                          |
| Menu routing           | Ordered menu definitions, outer dispatcher and caller-owned loops                                                  | Every displayed route, default, cancel and caller return.                                            |
| Workflow               | Manifest actions/prerequisites/phases and Invoke-AutopilotManifestStep/handlers                                    | Definitions, eligibility, action evidence, downstream invalidation and recovery.                     |
| Graph/identity         | Discovery, target, transport and action-specific helpers                                                           | Exact IDs, tenant binding, complete reads, request counts, no replay and SDK/tenant acceptance.      |
| Saved evidence         | Record/audit/checkpoint/lease/migration helpers                                                                    | Both-host shape/history compatibility, interrupted writes, ownership and real reload where approved. |
| Statistics/reports     | Dispatch projection, work-pattern and export helpers                                                               | Proven dispatch population, local-day/time rules, encoding, no-op and failed-save cases.             |
| Optional documents     | [Module manifest](Modules/Documents/AutopilotExpress.Documents.psd1), its Public/Private scripts and dispatch hook | Document, workflow, safety and definition suites; isolated Word/PDF acceptance.                      |

Function help must explain purpose, inputs and outputs. Define extracted dependencies before callers in fixtures,
preserve AST source metadata, initialise properties and keep empty/single/multiple arrays and dictionaries stable
on Core and Desktop. Do not let a mock's simplified shape become the production contract.

## Change Management

1. Identify the controlling helper and nearest falsifying check; make a small change and run that check immediately.
2. Review scopes/RBAC, immutable targets, evidence truthfulness, storage compatibility, privacy and both-host shapes.
3. Update the correct guide: entry path in README, technician procedures in Operations, contracts in Technical, outstanding work in TODO and
   executable verification/evidence in Testing. Replace superseded instructions; do not append chat-derived diaries.
4. Run the [required focused/full gates](TESTING.md) for changed code, definitions or tests. Record the tested revision
   and failures honestly; a focused pass never becomes a full gate by implication.
5. Preserve others' edits and operational evidence. Never commit credentials, records, journals, dumps or tenant
   screenshots. Source validation is not deployed/hosted acceptance; website work needs explicit scope approval and
   an isolated copied-project build. Never edit generated docs or let a check refresh committed Retype output.

Uncertainty blocks the affected slice, not unrelated authorised work. Do not weaken guards, remove failing assertions
or expand tenant/data/network/physical scope to force completion.

## Review and Hand Over

Record dated task IDs, problem/evidence, why this design was chosen, exact changes, failures and lessons in
Development. Keep superseded decisions dated and identify their replacement; do not overwrite history with the
latest configuration. Testing owns commands, dated reports/provenance and acceptance limits. Technical owns current
internals; Functions owns the source-derived catalogue. Setup/Operations must explain changed user behaviour.

Use the focused checks immediately, then the required [release gates](TESTING.md). Check source/definition/template
fingerprints and every affected guide. Real SDK, policy, console, inventory and physical outcomes need their existing
separate approvals. No documentation edit, test pass or general instruction to continue releases an approval hold.
