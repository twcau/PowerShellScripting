<!-- omit from toc -->
# Contributing

Thank you for contributing to PowerShellScriptingNew. To maintain a high-quality, accessible, and consistent experience, please follow these guidelines.

## Table of Contents

- [Table of Contents](#table-of-contents)
- [Development Standards](#development-standards)
- [ScriptLauncher UI Standards](#scriptlauncher-ui-standards)
- [Accessibility](#accessibility)
- [Documentation](#documentation)
- [Testing \& Linting](#testing--linting)
- [Commit \& PR Guidelines](#commit--pr-guidelines)

## Development Standards

- Use Australian English (EN-AU) in documentation and comments.
- Prefer modular, reusable code; avoid large monolithic scripts.
- Include clear headers in scripts/modules (purpose, parameters, returns, last updated).
- Avoid hardcoded credentials or secrets; use secure stores.
- Follow existing folder and naming conventions.

## ScriptLauncher UI Standards

- **Commands-only menus**: Use WPF `Command` on menu items; avoid duplicate `Click + Command` wiring.
- **Single-press Esc close**: Implement `HwndSource.AddHook` with ESC handling (`WM_KEYDOWN/WM_SYSKEYDOWN VK_ESCAPE`) for all dialog windows to close immediately regardless of focused control.
- **Owner assignment**: Open modal dialogs with `Owner = MainWindow` for consistent modality and focus.
- **No global ESC interceptors**: Do not add thread-level ESC handlers; handle Esc at the dialog level.
- **Keyboard accessibility**: Provide access keys on buttons and consistent Tab navigation.

## Accessibility

- Ensure UI and docs are accessible to screen readers; avoid colour-only cues.
- Use clear, descriptive text for actions and statuses.
- Provide keyboard shortcuts and access keys.

## Documentation

- Keep README up to date when major features change.
- Add or update `.website/` content if present; prefer relative links.
- Include usage examples and prerequisites in script/module headers.

## Testing & Linting

- Run `dotnet build` (ScriptLauncher) or `PSScriptAnalyzer` (PowerShell) before PR.
- Validate single-press Esc and menu behaviours in all dialogs.
- Fix warnings or document exceptions in `KNOWNISSUES.md`.

## Commit & PR Guidelines

- Use clear, descriptive commit messages.
- Reference issues when applicable.
- Include screenshots/GIFs for UI changes.
- Update documentation alongside code changes.
