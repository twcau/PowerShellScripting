<!-- omit from toc -->
# Historical Autopilot Express Code Review

> **Historical pre-1.6 review, not current operator guidance or an active change list.** Status checked
> on 13 October 2026. The original review below is retained for traceability, including its old line numbers,
> assumptions and recommendations; do not apply them to current code without a new review.

Current authority is the [operator guide](../README.md), [operations reference](../OPERATIONS.md),
[executed validation and acceptance record](../TESTING.md#validation-results) and
[development backlog](../DEVELOPMENT.md#tracked-tasks), together with the current script and JSON definitions.

The current script supports PowerShell 7 and Windows PowerShell 5.1 with host-appropriate UTF-8 handling. Missing
mode prompts with default Demo; no-argument execution does not silently default to Live. ISE still cannot host PS7,
but PS5 compatibility is no longer the old encoding failure described below, nor proof of actual ISE/policy acceptance.
The recommendation to add a PS7-only requirement was not adopted: it would remove supported PS5 compatibility.

Manifest 1.6 validation now checks supported action names and phase coverage, ordering precedes dependencies,
and completion/recovery roles are semantic rather than fixed-letter gates. Legacy dead helpers/flags were retired;
verification polling, transport controls and local session reservations are implemented. Shared remains disabled.
Historical findings must not be read as evidence of current defects or production acceptance.

Scope: `autopilot-express.ps1` (3,091 lines), `autopilot-express.manifest.json`, `autopilot-express.runtime.json`, `README.md`. Findings are grouped by severity. Line numbers refer to the `.ps1` with its original CRLF line endings as uploaded.

---

## 0. Before anything else: PowerShell ISE will not run this script correctly

You mentioned you might run this from **PowerShell ISE's Play button**. This needs to be flagged as blocking, not cosmetic:

1. **ISE cannot host PowerShell 7 at all.** The script's own header says _"The PowerShell 7 entry point"_ and the README requires "PowerShell 7 or later." Windows PowerShell ISE (`powershell_ise.exe`) only ever hosts the Windows PowerShell 5.1 engine — there is no configuration that makes its Play button (F5) launch `pwsh.exe`. Pressing Play will silently run the script under 5.1, not 7.
2. **That mismatch breaks file I/O immediately.** `Write-Utf8File` and `Test-DirectoryWritable` (lines ~417, ~497) call:

   ```powershell
   Set-Content -Path $Path -Value $Content -Encoding utf8NoBOM -NoNewline -Force -ErrorAction Stop
   ```

   `utf8NoBOM` is a PowerShell 6+ encoding name. In 5.1 it's not a valid `-Encoding` value, so this throws a parameter-binding error. `Test-DirectoryWritable` wraps the probe write in `try/catch` and just returns `$false` on any exception (line ~421), so instead of a clear "wrong engine" message you'll get: _"Autopilot Express could not find a writable storage location"_ — even though the folders are perfectly writable. This is a confusing, misleading failure mode.

   - **Fix:** add `#Requires -Version 7.0` at the very top of the file (currently absent — confirmed, there is no `#Requires` line anywhere). This makes PowerShell itself refuse to run under 5.1 with a clear, standard error instead of failing deep inside storage initialisation.

3. **Running via Play silently defaults to Live mode.** The script's param block is:

   ```powershell
   param(
       [ValidateSet('Live', 'Demo')][string]$Mode = 'Live'
   )
   ```

   ISE's Play button runs the active script with **no arguments**, so `$Mode` defaults to `'Live'` — the destructive mode — directly contradicting the README's explicit instruction to start in Demo mode. There is no ISE prompt for parameters unless they're mandatory, and `$Mode` isn't.

   - **Fix (recommended, regardless of ISE):** default `$Mode` to `'Demo'` instead of `'Live'`, so _any_ accidental no-argument launch (Play button, double-click, forgetting the flag in a terminal) lands in the safe mode. Live should be something the technician has to opt into explicitly every time.

4. **Bottom line:** even after fixing #1 and #3, ISE is still the wrong tool for this script — it cannot run PS7 code, period. Run it with:

   ```pwsh
   pwsh.exe -File .\autopilot-express.ps1 -Mode Demo
   ```

   from a real PowerShell 7 host (Windows Terminal, `pwsh` console, or VS Code with the PowerShell extension targeting a PS7 session). If you want an ISE-like click-to-run experience, VS Code's "Run" button with the PowerShell extension correctly launches PS7 and is the closest equivalent.

---

## 1. Critical / correctness issues

### 1.1 No `#Requires -Version 7.0` guard

Already covered above, but worth stating as its own line item: this is the single highest-leverage one-line fix in the whole script. Add it as the very first non-comment-block line, before the `[Diagnostics.CodeAnalysis.SuppressMessageAttribute(...)]` attributes (or immediately after the comment-based help, before `param()`).

### 1.2 Stale, misleading header comment block (lines ~62–111)

This large comment block titled `MENU STRUCTURE (ASCII, Accessible) - Draft` and `GRAPH / INTUNE / ENTRA REQUIREMENTS` describes an **entirely different, older design** than what the script actually implements:

- It documents an "Autopilot Sub-Menu (Option 2)" with fixed hotkeys `A`–`F` (_Prepare for reseal, Shared device provisioning, Assign primary user, Application check, Fix specific application (Zenworks White file copy stub), Manufacturer software update_). None of this exists in `Invoke-AutopilotSequence` — the real sub-menu is entirely manifest-driven, keyed by the manifest's step IDs (`A`–`J` from `autopilot-express.manifest.json`), which happen to be different steps with different meanings.
- It lists a "least privilege starting point" permission set including `Device.Read.All` / `Device.ReadWrite.All` and `DeviceManagementConfiguration.Read.All` that the actual runtime configuration (`autopilot-express.runtime.json`) does not request and the code does not use.
- It references a Zenworks fix-file stub and manufacturer CLI invocation that don't exist anywhere in the implementation (see 2.3 — the related config toggles are also dead).

This block is clearly a leftover design scaffold. Anyone reading the script to understand current behaviour (including a reviewer on another platform) will be actively misled by it.
**Fix:** delete it, or replace it with a short pointer to the manifest JSON as the single source of truth for steps/menus/permissions, which is in fact how the current implementation works.

### 1.3 Manifest/implementation drift is not validated at startup

`Initialize-AutopilotExpressDefinitions` validates:

- the dependency graph (duplicate IDs, undefined prerequisites, self-reference, cycles), and
- that every `workflowPhases[].actionNames` entry maps to a defined step's `actionName`.

It does **not** validate the reverse: that every enabled step's `actionName` has a corresponding `case` in `Invoke-AutopilotManifestStep`'s switch statement. If a manifest edit renames an `actionName` (or adds a new step) without a matching code change, the step silently falls through to the `default` branch and returns _"Manifest action is not yet implemented"_ at runtime, instead of failing loudly at startup where it would be caught immediately.
**Fix:** add a startup check — build the list of `ActionName` values the switch handles (or maintain it as an explicit array), and `throw` if any enabled manifest step's `actionName` isn't in that list.

### 1.4 Hard-coded `'A'` string in the Autopilot-presence gate

```powershell
if ($StepId -eq 'A' -and [string]::IsNullOrWhiteSpace($Device.AutopilotDeviceId)) { return $false }
```

(in `Test-ManifestStepCompleted`). This enforces the README's "Confirmed Version 1 Decision" that Autopilot presence is a **blocking preflight gate that cannot be bypassed**. But it's keyed to the literal manifest step ID `'A'`. If the manifest's resolve-step ID is ever renamed (e.g. to `'Resolve'` or renumbered), this safety check stops applying — silently, with no error, no test failure, nothing — and the blocking gate is defeated.
**Fix:** key this off `ActionName -eq 'ResolveAutopilotDevice'` instead of the step ID, or better, add a manifest-level concept (e.g. `"isPresenceGate": true` on the step) so the behaviour travels with the manifest rather than a magic string buried in code.

### 1.5 Step ordering vs. dependency ordering mismatch in the manifest (confusing, not functionally broken)

In `autopilot-express.manifest.json`, step `D` (`ValidateDeploymentProfile`) is listed **before** step `E` (`AddToPreProvisioningGroup`) in the JSON array, but `D.prerequisiteStepIds` includes `E`. Functionally this is fine — eligibility is computed from `prerequisiteStepIds`, not array order, and the startup cycle/graph check already proves there's no actual cycle. But the Autopilot sub-menu (`Invoke-AutopilotSequence`) renders steps in manifest array order via `Get-EnabledManifestSteps`, so a technician sees menu option **D** (blocked, "E required") listed above the **E** it depends on, which reads oddly.
**Fix (cosmetic only):** reorder the `steps` array in the manifest to `A, B, C, E, D, F, G, H, I, J` so displayed order matches achievable order.

### 1.6 `RetryFailedApplications` (step `H`) is not referenced by any `workflowPhases.actionNames`

Step `H` exists in the flat step list and is fully implemented (`Invoke-StepRetryFailedApps`), but it doesn't appear in any `workflowPhases[].actionNames` array (`IntunePreparation`, `GuidedPreProvisioning`, `ConditionalRecovery`, `PostProvisioning`, `FinalOwnership` — none list it). Today this has **no functional effect**, because `$Script:WorkflowPhases` is loaded and validated at startup but never consulted by any menu or eligibility logic (see 2.4 — it's currently just loaded and unused). But if phases are later wired into the UI (as the data model clearly anticipates), step H will be invisible under phase-based navigation.
**Fix:** add `"RetryFailedApplications"` to `PostProvisioning.actionNames` (or a dedicated phase) now, while it's cheap, rather than after phase-based UI exists.

---

## 2. Dead code and unused configuration (maintainability / trust-the-code risk)

Confirmed by grep — each of these appears exactly once in the file (its own definition) and is never called or read elsewhere:

### 2.1 `New-DeviceLock` / `Remove-DeviceLock` (lines ~745, ~756)

A whole per-serial file-locking mechanism is implemented (`.lock` files with timestamp + username) but **never invoked anywhere** in the main flow. It provides zero actual protection today. This lines up with the README's own admission that shared/concurrent-technician storage isn't implemented yet, so it's not a surprise — but as written it's a false sense of safety: a reviewer skimming the code would reasonably assume device records are locked during edits, and they are not.
**Fix:** either wire it into `Get-UserDeviceRecords`/`Write-UserDeviceRecords`/bench operations now, or remove it and track "locking" explicitly as a roadmap item (the README's roadmap item 5 already covers this) so there's no dead code implying false protection.

### 2.2 `Get-WorkflowPhaseDefinition` (line ~1268) and `Show-ReturnToPreviousMenu` (near end of file)

Both defined, neither called anywhere.
**Fix:** remove, or wire `Get-WorkflowPhaseDefinition` into phase-aware UI if/when that's built; remove `Show-ReturnToPreviousMenu` or use it in place of the ad hoc "press enter" pauses scattered through the bench sub-menu.

### 2.3 Config toggles in `$Script:Config` that are set but never read

Grep confirms each of these appears only once in the file — at its own assignment inside the `$Script:Config` hashtable (lines ~180–202) — with no code anywhere checking its value:
`EnableSharedDeviceFlow`, `EnablePrimaryUserAssignment`, `EnableManufacturerUpdate`, `EnableApplicationCheck`, `EnableZenworksWhiteFix`, `RequireManagerForSharedAssign`, `SupportAutopilotGroupAdd`, `SupportAutopilotDeleteRecord`, `ManufacturerUpdateCommand`, `ManufacturerUpdateArgs`, `MaxRetryAttempts`, `RetryBackoffSeconds`.
These are leftovers from the same older design the stale header comment (1.2) describes — manufacturer CLI invocation, Zenworks fix stub, shared-device flow gating, retry/backoff tuning — none of which the current manifest-driven implementation uses (retry/backoff, in particular, is explicitly called out in the README as "remain[ing] implementation work").
**Fix:** delete the toggles that correspond to genuinely abandoned features (manufacturer update, Zenworks), and either wire up or clearly comment `MaxRetryAttempts`/`RetryBackoffSeconds` as "reserved for the planned Graph mutation retry/polling work," since those two at least match a real roadmap item.

### 2.4 `$Script:WorkflowPhases` is loaded, validated, and then never consulted

`Initialize-AutopilotExpressDefinitions` parses `workflowPhases` from the manifest, validates every phase's `actionNames` against defined steps, and throws if a phase has no valid actions. After that, nothing reads `$Script:WorkflowPhases` except the one dead accessor in 2.2. All actual menu/eligibility logic operates on the flat `$Script:StepManifest` list. This isn't wrong, but it means the manifest's phase structure (clearly meant to mirror the official checklist's five stages, matching the README's "Workflow Model" section almost one-to-one) currently buys you nothing beyond validation — no phase grouping shows up anywhere in the UI.
**Fix:** either surface phases in the Autopilot sub-menu (group steps under their phase heading, matching the README's documented workflow model) or note in the README/code comments that phases are presently validation-only scaffolding for a future UI pass.

---

## 3. Design-level nits worth a decision

### 3.1 Technician prefix matching is a single-character `StartsWith`

`Test-DirectoryUserMatchesConfiguredPrefixes` checks whether a UPN's local part starts with a configured prefix (`C` or `E` by default). A single-letter prefix will match _any_ UPN starting with that letter — e.g. prefix `C` matches `casey.nurse@…` (intended) but also `contractor.account@…` or `careers.team@…` (not intended, if such accounts exist in the tenant). This is a business-rule precision question, not a code bug, but worth raising with whoever owns the UPN naming convention before Live use, since it directly gates who can be assigned as primary user.

### 3.2 `$env:USERNAME` / `$env:LOCALAPPDATA` are Windows-only environment variables

Used throughout for per-technician file naming and the fallback storage path (`Get-UserDataFilePath`, `Get-BuildBenchStatePath`, `Get-RecentUsersFilePath`, `Get-FallbackStorageBasePath`, plus `StartedBy`/`LastUpdatedBy`/`CompletedBy` fields). Given the README states "Windows with PowerShell 7 or later" as a hard prerequisite, this is currently acceptable. But if this is ever run under `pwsh` on macOS/Linux, `$env:USERNAME` is empty, which would collapse all technicians' file names together (`autopilot-devices-.json`) with no error. `[Environment]::UserName` is the cross-platform equivalent and costs nothing to swap in now as a defensive measure, even while the stated platform stays Windows-only.

### 3.3 Declared Graph modules may not cover every cmdlet actually called

`Get-ConfiguredGraphModules` defaults to `Microsoft.Graph.Authentication` and `Microsoft.Graph.DeviceManagement.Enrollment` (matching `runtime.json`). The script also calls `Remove-MgDeviceManagementManagedDevice` and `Update-MgDeviceManagementWindowsAutopilotDeviceIdentityDeviceProperty`, each guarded with `Get-Command -ErrorAction SilentlyContinue` and a raw-Graph-request fallback, so a missing module won't crash the script. But it's worth confirming with the Graph SDK docs which module actually ships each of those two cmdlets in the SDK version you're pinning to — if it's not `DeviceManagement.Enrollment`, the "fast path" cmdlet will never be available and every call silently takes the raw-Graph fallback, which works but defeats the purpose of listing that module at all.

### 3.4 `Test-LiveRuntimeConfiguration` doesn't validate `manifestVersion`

`runtime.json`'s `configVersion` is checked for semantic-version format and the manifest's own `manifestVersion` (`"1.3.0"`) is read but never validated or checked for compatibility against anything. Low priority, but worth a line in the "Not yet complete" list if it isn't already covered by README roadmap item 4 (tenant configuration prep).

---

## 4. Things that look like bugs but are actually fine (ruled out during review, documented so they aren't re-flagged)

- **`break` inside the `switch` in the main loop:** `'0' { ...; break }` followed by `if ($option -eq '0') { break }` outside the switch looks redundant but is correct — in PowerShell, a bare `break` inside a `switch` exits the switch (the nearest enclosing loop-like construct), not the outer `while`. The second `break` is what actually exits the main loop. Not a bug.
- **`[int]::TryParse($response, [ref]$null)`:** passing `[ref]$null` as the out-parameter is valid PowerShell and discards the parsed value safely; not a bug.
- **Hashtable dot-notation (`$Script:RuntimeConfig.graph.authMode` etc.):** works because `Read-JsonDefinitionFile` converts the parsed JSON through `ConvertTo-NormalisedValue`, which turns every `pscustomobject`/`IDictionary` into a plain `Hashtable`, and PowerShell supports member (dot) access on hashtables as sugar for key lookup. Intentional and consistent throughout.
- **Dell QR-code rule regexes:** `hostPattern`/`pathPattern`/`t` extraction were traced end-to-end against the README's own example URL and correctly resolve to `6H70TH4`. No bug found.
- **Step D depending on step E "out of order" in the JSON:** confirmed not a functional bug (see 1.5) — only a readability nit.

---

## 5. Summary of recommended fixes, in priority order

1. Add `#Requires -Version 7.0` at the top of the script (prevents the ISE/5.1 failure mode entirely, with a clear error).
2. Change `$Mode` default from `'Live'` to `'Demo'` so any no-argument launch is safe by default.
3. Run the script only via `pwsh.exe` (PowerShell 7+) — Windows Terminal, a `pwsh` console, or VS Code's PowerShell extension — never via Windows PowerShell ISE, which cannot host PS7 regardless of configuration.
4. Delete or rewrite the stale header comment block (lines ~62–111) so it matches the actual manifest-driven implementation.
5. Add a startup check that every enabled manifest step's `actionName` has a matching handler in `Invoke-AutopilotManifestStep`'s switch.
6. Replace the hard-coded `'A'` step-ID check in `Test-ManifestStepCompleted` with an `ActionName`-based or manifest-flagged check.
7. Add `RetryFailedApplications` to a `workflowPhases.actionNames` list in the manifest.
8. Remove or wire up the dead code: `New-DeviceLock`/`Remove-DeviceLock`, `Get-WorkflowPhaseDefinition`, `Show-ReturnToPreviousMenu`, and the unused `$Script:Config` toggles listed in 2.3.
9. Reorder the manifest's `steps` array to match dependency-achievable order (cosmetic).
10. Swap `$env:USERNAME`/review `$env:LOCALAPPDATA` for `[Environment]::UserName` as a low-cost defensive improvement.

None of these are needed to make the _logic_ of the Graph calls, manifest engine, or persistence layer correct — that part of the script is in solid shape (verified read-back checks after every mutation, proper dependency-graph validation, careful Demo/Live isolation). The issues above are almost entirely about **the gap between what the script was once going to be and what it is now** (stale comments, orphaned toggles, unvalidated manifest/code drift) plus **one environment-compatibility landmine** (#1–#3) that will block you specifically given how you intend to run it.
