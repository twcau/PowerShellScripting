<!-- omit from toc -->
# Autopilot Express First-Time Setup

Use this guide to prepare a deployment or use an approved deployment for the first time. It separates the
deployment owner's decisions from the technician's work. You do not need to write PowerShell to use the existing
workflow. Changing that workflow is a separate activity described in [CUSTOMISATION.md](CUSTOMISATION.md).

This is a development release. Demo is available for rehearsal; Live can delete Intune managed-device records
and change device properties, membership and primary users. Completing this guide does not authorise those actions.
Never disable corporate execution policy, Conditional Access or ownership checks to get through setup.

## Contents

Current non-admin deployment: the script offers to download a coherent Graph SDK
set into `%LOCALAPPDATA%\PowerShellScriptingNew\AutopilotExpress\GraphModules`.
It uses explicit fixed-local manifests rather than importing DLLs from redirected
home drives. Consent defaults to No; no UAC, existing-module deletion or execution
policy changes occur. Gallery/PowerShellGet access must be available under the
organisation's policy. An already loaded conflicting SDK requires a fresh shell.

Document trust failures now show bracketed `[R]`, `[C]`, `[X]`, `[L]` and `[U]`
choices when applicable. `[L]` shows the complete path/fingerprint review list;
`[U]` requires separate default-No consent before removing only reviewed file marks.
`[C]` continues without output for that session and does not change saved preferences.
Template guards are separately OFF by default for testing; trust/dependency checks
are not removed by that setting.

- [Contents](#contents)
- [Choose Your Path](#choose-your-path)
- [Deployment Owner: Prepare the Files and Host](#deployment-owner-prepare-the-files-and-host)
- [Deployment Owner: Configure the Organisation](#deployment-owner-configure-the-organisation)
- [Deployment Owner: Review the Workflow](#deployment-owner-review-the-workflow)
- [Deployment Owner: Prepare Access and Dependencies](#deployment-owner-prepare-access-and-dependencies)
- [Deployment Owner: Validate and Hand Over](#deployment-owner-validate-and-hand-over)
- [Technician: Check the Deployment](#technician-check-the-deployment)
- [Technician: Rehearse a First Device](#technician-rehearse-a-first-device)
- [Technician: Start Approved Live Work](#technician-start-approved-live-work)
- [Timeouts, Waiting and Pending Work](#timeouts-waiting-and-pending-work)
- [Setup Problems](#setup-problems)
- [Ready-to-Use Checklist](#ready-to-use-checklist)

## Choose Your Path

| Your responsibility                        | Start here                                                    | You need from someone else                                                                        |
| ------------------------------------------ | ------------------------------------------------------------- | ------------------------------------------------------------------------------------------------- |
| Deploy or adapt the tool                   | Owner sections below, then the technician rehearsal           | Tenant and checklist owners, security approver and pilot approver.                                |
| Build devices using an existing deployment | Technician sections below                                     | Approved file set, tenant/site/group choices, authorised accounts and physical procedure.         |
| Change action order or add behaviour       | Owner review, then Customisation                              | An approved revised process, source/test access and a data compatibility decision.                |
| Diagnose or maintain the implementation    | [TECHNICAL.md](TECHNICAL.md) and [FUNCTIONS.md](FUNCTIONS.md) | The affected revision, controlled evidence and permission for any real-environment investigation. |

If the deployment owner has not supplied those decisions, stop before Live. A technician should not have to
guess a tenant GUID, target group, device policy or permission list at a setup prompt.

## Deployment Owner: Prepare the Files and Host

1. Obtain a reviewed revision of the complete product folder. Keep the script, both JSON definitions, guides,
   document module and reviewed templates together. Retain the repository licence and applicable notices.
2. Use a Windows technician desktop and a fresh PowerShell 7 session, preferably not elevated. Windows PowerShell
   5.1 is also supported for ordinary operation; explicit legacy conversion requires PowerShell 7.5 or later.
   FullLanguage is required by current reservation safety. Do not attempt to bypass an enforced language policy.
3. Use an approved local deployment location. A copied or OneDrive-backed data folder is not a shared bench.
   Existing foreign/reparse-backed ownership evidence must not be deleted to make a copy writable.
4. Check the actual language mode, files and PowerShell edition. These commands inspect the host; they do not
   initialise application storage or connect to Graph. Run them from the product folder:

```pwsh
$PSVersionTable
$ExecutionContext.SessionState.LanguageMode
Get-Location
Get-Item .\autopilot-express.ps1, .\autopilot-express.runtime.json, .\autopilot-express.manifest.json
```

From this repository's root, reach the product folder with:

```pwsh
Set-Location .\intune\devices\autopilot-express
```

The script first finds a folder containing both definitions. It considers the script location, an explicit
`AutopilotExpressDefinitionDirectory` environment value and current-directory ancestors. It then resolves a project
root using README, LICENSE or Git ancestry. Do not assume the repository root is the operational data root:
the product README can anchor it locally. Record the loaded definition path and reported authoritative storage path.

For supported pasted execution, set the definition-directory environment value to the actual reviewed product
folder first. Normal script-file execution is easier to identify, support and fingerprint; do not paste fragments
that omit bootstrap, validation or cleanup. See [pasted execution](OPERATIONS.md#pasted-code-execution).

## Deployment Owner: Configure the Organisation

Keep a reviewed copy of the starting definitions outside operational discovery. Read the supplied values as
examples to validate, not approval to target those objects. Definitions load once: restart after changing them.
Reconnect does not reread the files.

| Location                                  | Decide and verify                                                                                   | Why it matters                                                                                |
| ----------------------------------------- | --------------------------------------------------------------------------------------------------- | --------------------------------------------------------------------------------------------- |
| Runtime organisationName                  | Your actual display name, not Example Health Network.                                               | Placeholder configuration must not become an accepted deployment.                             |
| graph.expectedTenantId                    | Approved tenant GUID.                                                                               | Authentication in another tenant must fail before workflow actions.                           |
| graph.authMode/contextScope               | DeviceCode or Browser; Process or CurrentUser.                                                      | Authentication path and SDK context lifetime are distinct from workflow permissions.          |
| graph.requiredScopes/requiredModules      | Approved complete lists and coherent installed SDK versions.                                        | Explicit lists are not silently broadened; consent and operator roles remain separate checks. |
| autopilot.deploymentProfileDisplayName    | Exact intended profile.                                                                             | The technician must still check the physical assignment.                                      |
| autopilot.preProvisioningGroupDisplayName | Exact approved group, uniquely resolvable and eligible for the required writes.                     | Addition/removal use the configured target; a prefix is not the target.                       |
| autopilot.preProvisioningGroupPrefix      | Reviewed conflict-discovery prefix.                                                                 | Incorrect breadth could identify unrelated memberships for correction.                        |
| Manifest groupConflictExclusions          | Literal Prefix/Exact exceptions approved for your directory.                                        | Do not exempt all matching groups merely to suppress a conflict.                              |
| Script Sites/DeviceTypes                  | Approved codes, full names and device classes.                                                      | Group Tags derive from site/type; changing session defaults does not retag existing work.     |
| autopilot.technicianUpnPrefixes           | Approved eligible regular-account prefixes.                                                         | This is an account-selection filter, not a licence or role check.                             |
| Scanner normalisation                     | Actual scanners and vendor URLs, tested before lookup.                                              | Normalisation affects serial identity, duplicates, tags and target resolution.                |
| Hash import                               | Approved local search folders, filename prefixes and removable-media policy, or disable the option. | Hardware hashes are sensitive; discovery does not establish device ownership.                 |
| storage.mode                              | Local.                                                                                              | Shared remains disabled and unqualified, regardless of fields present in the file.            |
| Demo data                                 | Clearly synthetic names, users and device identifiers.                                              | Rehearsal must not be confused with real certification.                                       |

At the inspected revision, the supplied group value is `Intune-Autopilot-ESP-Prod`; the name alone grants no
approval. Earlier development records refer to `Intune-Autopilot-Testing`. Consult the actual loaded definition,
not a historical name copied into instructions. A mid-build group change needs a reviewed transition because
removal may otherwise target a different group from the earlier addition.

The eight supplied delegated scopes cover core operations plus remediation catalogue/report reads. Review each
in the [Graph reference](TECHNICAL.md#graph-and-identity-boundaries). DeviceManagementScripts.Read.All does not grant
on-demand submission; that separate utility needs its additional supported permission and operator approval.
Do not add permissions merely because an error contains 403.

## Deployment Owner: Review the Workflow

Start with the governing [v1.4 checklist](development/Autopilot%20Checklist%20-%20v1.4.pdf) and obtain owner confirmation
of its currency. The [26-step comparison](OPERATIONS.md#checklist-coverage) identifies manual and external work.
The v1.5 Word-template filenames do not supersede checklist authority.

The supplied workflow contains normal A-O actions and conditional recovery P/Q. Array order controls presentation
and next-eligible selection; prerequisites control eligibility. Phases group the guide. Function placement in the
PowerShell source does not determine this business sequence.

1. Match each required physical/tenant action to an existing semantic handler.
2. Review prerequisite chains and recovery activation against your approved process.
3. Keep saved IDs and action meanings stable for existing records. A rename is not a harmless text edit.
4. Check that group removal, first sign-in, application checks, conditional sync, shutdown and final ownership remain
   correctly gated. At M, no failures is the default after baseline confirmation; a failure can instead prompt a sync.
   Sync is not the named application remediation.
5. Follow [CUSTOMISATION.md](CUSTOMISATION.md) for a worked ordering example, handler reuse and the point at which
   new code is required. Do not edit saved JSON to make an action eligible.

## Deployment Owner: Prepare Access and Dependencies

Core Live operation needs the configured Microsoft.Graph.Authentication and Microsoft.Graph.DeviceManagement.Enrollment
modules. Startup selects a common installed version, imports Authentication first by exact manifest and refuses
loaded-version/path conflicts. Open a fresh shell rather than unloading assemblies or replacing a bundled DLL.

Before module discovery/import, startup reads installed manifests as restricted literal data and inspects the
selected SDK directories. Internet-marked files are listed with SHA-256 fingerprints. Removing those marks requires
separate Y/default No consent after reviewing every file and its source; changed files require a new review.
This applies to explicitly inspected local and network installations, including redirected home directories.
Unblocking changes deployed files for other users too, not just this application session.

Restricted policy, invalid AllSigned signatures and untrusted publishers are not repaired by unblocking. UNC
classification may still prevent loading after marks are removed: the preflight conservatively requires already
trusted signatures for unmarked network scripts under RemoteSigned. Use an organisation-approved coherent local
deployment or ask the policy owner to approve the network deployment. Retry inspection with R after correction,
or use 0/default to return without Live dependencies. No policy, publisher trust or installed SDK version is changed
automatically. AppLocker/WDAC and actual DLL-loading outcomes still require affected-host acceptance.

Missing modules offer current-user PSGallery installation, default No. Accept only under your software policy;
the application does not approve installation, administrator consent or tenant access. Confirm supported proxy,
TLS and Graph connectivity with the organisation's administrators. Authentication can invoke SDK/broker behaviour;
the explicit app retry menu cannot interrupt an SDK call still waiting.

Keep these identities separate:

- Windows process user: local saved work, preferences and the regular-technician account hint.
- Graph account: delegated tenant access; an administrative login is not the physical sign-in or final owner.
- Regular technician: explicitly confirmed eligible directory user for the build.
- Final recipient: separately selected eligible user; the script does not infer a manager or CMDB recipient.

Optional document output needs its reviewed local module/templates, pinned Open XML/ZXing bundle and supported
desktop Word installation. Both output types default off. Enable through Settings > 6 only after reviewing
[document controls and prerequisites](OPERATIONS.md#document-output-controls). Acquisition has its own disclosed
consent; it is not part of Graph installation. Template guards are OFF by default for testing, so unapproved
profiles can generate and request printing according to the selected policy. Demo pages remain labelled, and an
explicit review-only request never prints. Settings `[G]` or `-EnforceDocumentGuards $true` restores the unapproved
profile and Demo printing restrictions. Disabling the guards does not approve the templates. Printer/scanner and
manual-save acceptance remain separate approvals.

When output is enabled, document readiness runs before device-session setup. Settings changes, preference saves
and CLI-pin release recheck it. Failure offers retry, exit or C/default: continue with document output suppressed
for this session only, without changing saved preferences. Local document-script Internet marks have their own
exact-file, unchanged-fingerprint review and separate default-No consent. Successful library/worker checks do not
prove Word activation, PDF export, physical printing or template approval. The entry script cannot repair its own
authorisation before PowerShell permits it to execute; the deployment owner must resolve that boundary first.

## Deployment Owner: Validate and Hand Over

Use the [offline validation procedure](TESTING.md#run-the-offline-suite) against the exact deployment revision.
The runner alone does not opt into document integration; follow the explicit full-gate instructions when that
feature is included. Check examples, definition structure, both-host compatibility and applicable targeted suites.
Do not import or dot-source the interactive entry script as though it were a passive validation library.

Perform the Demo rehearsal below, including exit/restart and saved-state inspection. Then obtain separately
approved tenant/SDK checks and the [single-device physical pilot](TESTING.md#single-device-live-pilot). Passing Demo
does not prove consent, RBAC, actual Graph endpoint support, a physical build or real terminal accessibility.

Hand over the reviewed revision and hashes, actual paths, approved tenant/profile/group/site/type choices,
account guidance, physical prerequisites, output policy, support route and the stop/recovery procedure.
Record outstanding acceptance explicitly. Do not describe a test release as accepted merely because it starts.

## Technician: Check the Deployment

Before first use, obtain the owner's completed handover. You need approved installation media/network access,
device serial and CI labels, site/type choices, the physical checklist and the intended final-user process.
Ask the owner about missing decisions rather than changing the deployment to get past a warning.

Open a fresh PowerShell session in the product folder and start Demo:

```pwsh
.\autopilot-express.ps1 -Mode Demo
```

Check the Demo label, loaded definition location, transcript path, authoritative data location and selected site.
Demo persists its own local records; it is not a discard-on-exit preview.

**Startup Resume defaults to Y. Answering N immediately archives current-user/current-mode device and bench files
and starts a fresh session, without a second confirmation.** Choose Y to continue or inspect saved work. The later
Data Settings > 2 archive command has additional default-No/CLEAR safeguards; it is not the same interaction.

## Technician: Rehearse a First Device

Use clearly synthetic identifiers that satisfy the configured rules, for example serial `DEMO1234` and CI
`DEMO-CI-001`. CI is text; retain leading zeros when supplied. Do not reuse an actual device's identifiers to
present a rehearsal as operational evidence.

1. Select a site. Open Main Menu > 1 Build Bench and choose a small capacity such as two positions.
2. Induct with I. Choose a new synthetic device, review serial/CI/site/type and confirm the proposal. Declining
   correction keeps the entered defaults; occupied/full/duplicate positions must not be overwritten.
3. Use T to prepare. Review each prompt and result. The sequence stops at pending, failed, blocked, cancelled or
   failed-save work; it does not mean every later build step has run.
4. Open V for the executable workflow and W for the read-only guide. Rehearse the ordered physical confirmations
   as simulated work; observe that Demo outcomes are Simulated, not Verified physical results.
5. Complete the synthetic normal sequence and explicitly dispatch. D on the bench means dispatch; D in the
   workflow is a step, so use DISPATCH there. Dispatch approval defaults No.
6. Exit with 0, restart Demo and choose Resume Y. Check that device identity, attempts and dispatch remain and
   that completed history is available through the current-device list/maintenance, not lost because a slot cleared.
7. Review My Stats and, if wanted, an explicitly confirmed session report. These describe saved dispatch/evidence,
   not a certificate of external handoffs or physical completion.

Selectors accept positions, serials or CIs. Disambiguate with `P:1`, `S:DEMO1234` or `CI:DEMO-CI-001`.
Root Enter exits, bench Enter refreshes and submenu 0 returns. Inputs are case-insensitive; read the displayed
default before pressing Enter. Some existing physical prompts default Yes: never accept one before observing it.

## Technician: Start Approved Live Work

Only after the owner's approvals, use a fresh reviewed deployment and shell:

```pwsh
.\autopilot-express.ps1 -Mode Live
```

Verify tenant/account/site/group selections before any mutation. DeviceCode is the configured default; an approved
session override can select Browser. A returned sign-in failure offers D/B/0; Enter cancels. Reconnect is Settings

> 9 and does not reload definitions or replay actions.

Follow the [daily workflow](OPERATIONS.md#workflow-and-physical-work). Submitted means pending, not failed proof
that a write never happened. Preserve evidence and obtain authorised read-back before any repeat mutation.
DO is audited administrative closure, not a way to certify incomplete work. Do not replay dispatch to retry PDFs.

## Timeouts, Waiting and Pending Work

| Control                    | Supplied value                                      | What you should expect                                                                               |
| -------------------------- | --------------------------------------------------- | ---------------------------------------------------------------------------------------------------- |
| HTTP client timeout        | 60 seconds                                          | Per configured request, not a complete action/sign-in deadline.                                      |
| GET transport attempts     | 3 total                                             | Only structured 429/503/504 are eligible; delays can extend the wait.                                |
| GET backoff                | 3 seconds initially, maximum 60 seconds             | Retry-After is bounded; an excessive delay is refused, not silently shortened.                       |
| Verification reads         | 5 total, 3 seconds between nonmatching reads        | First read is immediate; reads may themselves have transport retries.                                |
| Tag/membership propagation | One immediate read per submission/recheck           | Pending returns to the bench; a later check must not repost an accepted write.                       |
| Inventory retry interval   | 5 minutes                                           | Safe navigation/input boundaries only, not a background freshness guarantee.                         |
| Recovery close-out         | At least 120 seconds after current-cycle submission | Also needs managed-device absence and technician-observed Allowed/reset/reimage.                     |
| Document worker            | 60 seconds by default; validated 1-3600             | Export/preparation supervision is separate from Graph and the visible-opening target.                |
| Failed document retention  | 7 days by default; 0 disables expiry                | Only owned declared assets qualify for lifecycle cleanup; retained operational evidence is separate. |
| Authentication             | SDK/policy controlled                               | No application-wide sign-in deadline or guaranteed immediate cancellation is claimed.                |

An accepted mutation is not automatically retried after a timeout. Do not lengthen every timeout because a Group
Tag has not propagated. The [technical timing model](TECHNICAL.md#graph-and-identity-boundaries) explains nested waits,
and Customisation identifies the source and valid range of each setting.

## Setup Problems

| Problem                                  | Safe next action                                                                                           |
| ---------------------------------------- | ---------------------------------------------------------------------------------------------------------- |
| Definitions missing/wrong revision       | Verify both files and the reported folder; stop rather than selecting an unrelated copy.                   |
| Required module versions conflict        | Close this session and use an approved coherent installed version in a fresh shell.                        |
| Language-mode refusal                    | Ask the policy/deployment owner; do not weaken the policy or reservation guard.                            |
| Existing lock/checkpoint/write marker    | Preserve the store and use [owned session recovery](OPERATIONS.md#data-session-recovery-and-audit).        |
| Wrong group/tenant/profile               | Stop and obtain owner review; changing defaults cannot safely migrate an active build.                     |
| 403 or unavailable remediation catalogue | Review actual loaded configuration, consent and role; do not widen scope or repeat submission blindly.     |
| Device is Submitted                      | Inspect the action's pending evidence and approved read-back; do not reset the record to make it runnable. |
| PDFs fail after dispatch                 | Keep dispatch; inspect job diagnostics and use explicit document-only retry.                               |

Transcripts can contain device/user identifiers and sign-in instructions. Restrict access, retain controlled
originals and redact only copies for support. Never share tokens, hardware hashes or unrestricted operational stores.

## Ready-to-Use Checklist

- [ ] Owner: file revision, paths, host/policy, tenant, profile, group and scopes reviewed.
- [ ] Owner: checklist authority, workflow/prerequisites and migration implications reviewed.
- [ ] Owner: required dependencies approved; optional document readiness assessed separately.
- [ ] Technician: Demo induction/action/dispatch/exit/resume rehearsed and saved evidence checked.
- [ ] Owner/approver: actual tenant/SDK, terminal and physical-pilot acceptance recorded, or clearly still held.
- [ ] Technician: account roles, default prompts, stop conditions and recovery/support route understood.

Only the responsible approvers can close the real-environment items. A checked documentation list is not a
tenant permission grant or proof that an actual device was built successfully.
