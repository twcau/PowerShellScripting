<!-- omit from toc -->

# Known Issues

## UI Behaviour Checklist (ScriptLauncher)

Before merging UI changes, validate the following:

- Single-press Esc closes these dialogs: Settings, Import, Export, History, About.
- Menus use Commands only (no duplicate Click + Command wiring).
- Modal windows opened with `Owner = MainWindow`.
- Keyboard accessibility verified (Access keys on buttons; sensible Tab order).

## Historical Issue: Double Esc / Dialog Respawn

- Symptom: Pressing Esc closed a dialog but an identical window remained, requiring a second Esc.
- Root cause: Menu items wired with both Click and Command handlers caused two dialogs to open. Closing one revealed the second.
- Fix: Removed Click handlers for menu items that already use Commands; added per-dialog native-handle ESC hooks.
- Prevention: Follow UI Interaction Standards in README and CONTRIBUTING.

## Quarantine-to-Block Workflow Notes (2026-01-30)

- Out-GridView availability: When `Out-GridView` is unavailable or fails, the scripts fall back to a console-based selection. This is expected and should be used to proceed.
- Release cancel behaviour: Cancelling the release selection grid is treated as selecting zero releases; the workflow continues to discovery and candidate selection.
- Provider roots suppression: By default, common provider roots (e.g., gmail.com, outlook.com) are excluded from block candidates. Use `-IncludeProviderRoots` or set the preference to include them when desired.
- Zero-candidate diagnostics: When candidates are zero but discoveries exist, the script prints a preview of discovered domains with classification (AlreadyBlocked, AllowSuppressed, Excluded) to guide next actions.
- Parser checker noise: The `tools/ps1-parse-checker.ps1` may report token logs near tail sections without actionable syntax errors. Treat as informational unless accompanied by explicit parse errors.
- DNSBL execution gating (2026-04-28): DNSBL reporting now runs only when `-ReportToDnsbl` is supplied explicitly, or when defaults mode is explicitly requested and the saved DNSBL preference is enabled. Prompt-mode runs no longer auto-enable DNSBL reporting from saved preferences alone.
- DNSBL scope merging (2026-04-28): Selected domains and provider-root exclusions are kept as separate roots during DNSBL evaluation so the script does not form malformed combined roots or over-broad report matches.
- Regression coverage (2026-04-28): `testing/Quarantine-To-Block.Tests.ps1` covers PSL JSON/dat loading, DNSBL gating, root scope handling, filter consistency, export fallback, and explicit block-expiry validation.
