<!-- omit from toc -->

# PowerShellScripting

A collection of PowerShell scripts for enterprise IT administration, covering Active Directory, Microsoft 365, Exchange Online, Entra ID, and Intune management tasks that i've created over the years.

[![License: GPL v3](https://img.shields.io/badge/License-GPLv3-blue.svg)](https://www.gnu.org/licenses/gpl-3.0)
[![PowerShell Gallery](https://img.shields.io/badge/PowerShell-7.0+-blue.svg)](https://github.com/PowerShell/PowerShell)
[![Platform](https://img.shields.io/badge/Platform-Windows-lightgrey.svg)](https://www.microsoft.com/windows)
[![Build: .NET (ScriptLauncher)](https://github.com/twcau/PowerShellScriptingNew/actions/workflows/dotnet-ci.yml/badge.svg)](https://github.com/twcau/PowerShellScriptingNew/actions/workflows/dotnet-ci.yml)

## Table of Contents

- [Table of Contents](#table-of-contents)
- [Features](#features)
- [Getting Started](#getting-started)
  - [ScriptLauncher Prerequisites](#scriptlauncher-prerequisites)
  - [Installation](#installation)
- [Usage](#usage)
  - [Basic Usage](#basic-usage)
  - [Script Categories](#script-categories)
  - [Interactive Scripts](#interactive-scripts)
  - [Intune Autopilot Express CLI](#intune-autopilot-express-cli)
- [Configuration](#configuration)
  - [Environment Variables](#environment-variables)
  - [Authentication](#authentication)
  - [Customisation](#customisation)
- [Folder Structure](#folder-structure)
- [Modules and Functions](#modules-and-functions)
  - [Core Functionality](#core-functionality)
  - [Key Scripts](#key-scripts)
- [Testing](#testing)
  - [Development Environment](#development-environment)
  - [Validation](#validation)
- [Logging and Troubleshooting](#logging-and-troubleshooting)
  - [Logging Standards](#logging-standards)
  - [Common Issues](#common-issues)
  - [Support Resources](#support-resources)
- [Accessibility](#accessibility)
- [Contributing](#contributing)
  - [Development Guidelines](#development-guidelines)
- [Changelog](#changelog)
  - [Recent Updates](#recent-updates)
  - [Version History](#version-history)
- [License](#license)
- [Like to say thank you?](#like-to-say-thank-you)
- [Contact and Support](#contact-and-support)
  - [Project Maintainer](#project-maintainer)
  - [Getting Help](#getting-help)
  - [Support Guidelines](#support-guidelines)
- [ScriptLauncher: Build \& Publish](#scriptlauncher-build--publish)
  - [Prerequisites](#prerequisites)
  - [Build \& Run (Debug)](#build--run-debug)
  - [CI Checks](#ci-checks)
    - [Download Workflow Logs](#download-workflow-logs)
  - [Publish Single EXE and Zip](#publish-single-exe-and-zip)
  - [UI Interaction Standards (ScriptLauncher)](#ui-interaction-standards-scriptlauncher)

## Features

- **Active Directory Management**: User creation, group management, computer organisation, and bulk operations
- **Microsoft 365 Administration**: Exchange Online mailbox management, quarantine handling, and transport rules
- **Entra ID Integration**: External user management, compromised account remediation, and identity operations
- **Intune Device Management**: Bulk device synchronisation, remediation scripts, and compliance monitoring
- **General Utilities**: Password generation, module management, and script selection tools
- **OneDrive Administration**: User content download and management capabilities
- **Comprehensive Logging**: Standardised logging across all scripts with detailed audit trails
- **Error Handling**: Robust error handling and retry logic for enterprise environments
- **GUI Interfaces**: User-friendly forms for complex administrative tasks

## Getting Started

### ScriptLauncher Prerequisites

- PowerShell 7.0 or later
- Windows operating system
- Appropriate administrative permissions for target systems
- Required PowerShell modules (see individual scripts for specific requirements):
  - Active Directory Module
  - Exchange Online Management
  - Microsoft Graph PowerShell SDK
  - Microsoft.Graph.Intune
  - MSOnline (where applicable)

### Installation

1. Clone the repository:

   ```bash
   git clone https://github.com/twcau/PowerShellScripting.git
   ```

2. Navigate to the project directory:

   ```bash
   cd PowerShellScripting
   ```

3. Review the script you want to use and install any required modules:

   ```powershell
   # Example: Install Exchange Online Management module
   Install-Module -Name ExchangeOnlineManagement -Force
   ```

4. Configure the scripts according to your environment (see Configuration section)

## Usage

### Basic Usage

Each script is designed to be run independently. Navigate to the appropriate folder and execute the script:

```powershell
# Example: Run user creation script
.\ad\user\creation\User-Creation.ps1

# Example: Run Intune bulk sync
.\intune\devices\Intune-BulkSync.ps1
```

### Script Categories

- **Active Directory**: Scripts for user and computer management in on-premises AD environments
- **Exchange 365**: Email and mailbox management for cloud and hybrid environments
- **Entra ID**: Identity and access management for Azure AD/Entra ID
- **Intune**: Mobile device management and compliance scripts
- **General**: Utility scripts for common administrative tasks

### Interactive Scripts

Many scripts include GUI interfaces for ease of use:

- User creation wizards with form-based input
- Device selection interfaces
- Progress indicators for long-running operations

### Intune Autopilot Express CLI

The technician-friendly, menu-driven CLI for rapid Autopilot preparation and tracking lives here:

- Path: `intune/devices/autopilot-express/autopilot-express.ps1`
- Manifest: `intune/devices/autopilot-express/autopilot-express.manifest.json`
- Runtime settings: `intune/devices/autopilot-express/autopilot-express.runtime.json`

How to run:

1. Open PowerShell 7 in the repository root.
2. Run live mode with `intune/devices/autopilot-express/autopilot-express.ps1 -Mode Live`.
3. Run demonstration mode with `intune/devices/autopilot-express/autopilot-express.ps1 -Mode Demo`.
4. Select your current site when prompted (default is shown). The site code is used to enforce the Group Tag format.
5. Use the on-screen menu to perform common tasks.

Current workflow coverage:

- 1. Start work on a new device (capture Serial/CI, confirm Site, select Device Type, enforce Group Tag e.g., `MI-Desktop`)
- 1. Run the manifest-driven Autopilot sequence (steps A-J cover Autopilot lookup, Intune cleanup, Group Tag application, deployment-profile confirmation, pre-provisioning group add/remove, userless-enrolment unblock, technician primary user, app retry, and final primary user assignment)
- 1. Show outstanding work (devices with incomplete steps)
- 1. Maintain device records
- 1. Stats and summaries
- 1. Enhancements (feature ideas; manifest-driven)
- 1. Change site
- 1. Build bench (positions grid with session persistence)

Mode behaviour:

- `Live` mode uses browser-based Microsoft Graph sign-in only and validates the runtime JSON before continuing.
- `Demo` mode simulates browser sign-in plus every manifest and Graph-backed action, while still persisting progress, recent-user choices, and resume state.
- Live and demo sessions are isolated from each other and prompt to resume or archive-and-start-clean when prior state exists.

Build bench quick reference:

- Displays a grid of positions sized to your window, with centred position numbers and truncated values for readability.
- `I` = Induct new device
- `S` = Start next step for a device
- `V` = View all actions for a device
- `D` = Dispatch and finish a device
- `R` = Remove from position
- `M` = Move device between positions
- `E` = Exit build bench view

Data and persistence:

- Session JSON is written to `data/` when the repository path is writable.
- If the repository path is read-only or behaves like a synced/reparse-point path that rejects new files, the script automatically falls back to `%LOCALAPPDATA%\PowerShellScriptingNew\AutopilotExpress\data`.
- Separate per-user files are maintained for live and demo device records, recent users, and build-bench state.
- Clean restarts archive the previous session automatically.
- Live mode also maintains `autopilot-master-audit.json` for manager review of technician actions and resulting device/user outcomes.
- Group Tag is enforced as `SITECODE-DeviceType` (no override) for consistency and policy compliance.
- Required Graph scopes, modules, and tenant-specific values are externalised in the runtime JSON rather than hard-coded in the script body.

## Configuration

### Environment Variables

Some scripts may require environment-specific configuration. Review each script's header for specific requirements.

### Authentication

- Ensure you have appropriate administrative credentials
- Some scripts require multi-factor authentication (MFA)
- Consider using application passwords where applicable

### Customisation

Scripts include configurable parameters at the top of each file. Common customisations include:

- Domain names and organisational units
- Email domains and Exchange settings
- Logging paths and retention policies
- Timeout values and retry attempts

## Folder Structure

```plaintext
PowerShellScripting/
├── ad/                                    # Active Directory scripts
│   ├── computer/
│   │   └── FindMachineOU.ps1             # Locate computer objects in AD
│   └── user/
│       ├── creation/                      # User account creation scripts
│       │   ├── AD-CopyGroups.ps1         # Copy group memberships
│       │   ├── User-Creation-Bulk.ps1    # Bulk user creation
│       │   ├── User-Creation.ps1         # Individual user creation with GUI
│       │   └── User-Departure.ps1        # User departure processing
│       └── reconcillation/               # User account reconciliation
│           ├── AD-Bulk-DepartedEmployeeReconcillation.ps1
│           ├── Employee-Departure-Reconciliation.ps1
│           └── Employee-Listing.ps1
├── e365/                                  # Exchange 365 scripts
│   ├── E365-Mailbox-ConvertToShared.ps1 # Convert mailboxes to shared
│   ├── E365-Quarantine-ExportRecord.ps1 # Export quarantine records
│   ├── Exchange-QuarantineTABL-DataDownload.ps1
│   ├── quarantine-to-block-v1.ps1       # Legacy quarantine triage and TABL workflow
│   ├── quarantine-to-block.ps1          # Current quarantine triage, TABL, DNSBL, and deletion workflow
│   └── NewTransportRuleExecName.ps1     # Transport rule management
├── entra/                                 # Entra ID (Azure AD) scripts
│   ├── AutomateCompromisedAccountRemediation.ps1
│   ├── Entra-UserExternal-Create.ps1    # External user creation
│   └── User-Management-External.ps1     # External user management
├── general/                               # General utility scripts
│   ├── ScriptSelector.ps1                # Interactive script launcher
│   ├── module-management/                # PowerShell module utilities
│   │   ├── Module-PowerShell7-Require.ps1
│   │   └── Update-Module.ps1
│   └── password-generation/              # Password generation tools
│       ├── Password-Generator-Silent.ps1
│       └── Password-Generator.ps1
├── intune/                                # Microsoft Intune scripts
│   ├── devices/
│   │   └── Intune-BulkSync.ps1          # Bulk device synchronisation
│   └── remediation/                      # Intune remediation scripts
│       ├── M365-VersionDetect.ps1       # M365 Apps version detection
│       ├── M365-VersionRemediate.ps1    # M365 Apps version remediation
│       ├── TeamsOld-Detect.ps1          # Legacy Teams detection
│       ├── TeamsOld-Remediate.ps1       # Legacy Teams remediation
│       ├── WinUpdate-23H2to24H2Force-Detect.ps1
│       ├── WinUpdate-23H2to24H2Force-Remediate.ps1
│       ├── WinUpdate-Detect.ps1         # Windows Update detection
│       ├── WinUpdate-Pause-Detect.ps1   # Windows Update pause detection
│       ├── WinUpdate-Pause-Remediate.ps1
│       └── WinUpdate-Remediate.ps1      # Windows Update remediation
├── m365/                                  # Microsoft 365 scripts
├── onedrive/                              # OneDrive management scripts
│   └── M365-OneDrive-DownloadUserContents.ps1
└── testing/                               # Development and testing scripts
```

## Modules and Functions

### Core Functionality

The scripts in this collection provide:

- **User Management**: Creation, modification, and departure processing
- **Group Management**: Membership copying and bulk operations
- **Device Management**: Synchronisation, detection, and remediation
- **Security Operations**: Compromised account handling and compliance monitoring
- **Utility Functions**: Password generation, module management, and system utilities

### Key Scripts

- **User-Creation.ps1**: Comprehensive user creation with GUI interface
- **Intune-BulkSync.ps1**: Mass device synchronisation for Intune environments
- **Autopilot Express (CLI)**: `intune/devices/autopilot-express/autopilot-express.ps1` — Menu-driven technician workflow with build bench and per-user persistence
- **quarantine-to-block.ps1**: Interactive Exchange Online quarantine triage with guided release, TABL blocking, optional DNSBL submission, and optional deletion. DNSBL reporting is explicit opt-in.
- **AutomateCompromisedAccountRemediation.ps1**: Automated security response
- **ScriptSelector.ps1**: Interactive menu system for script selection

## Testing

### Development Environment

Testing scripts are located in the `testing/` folder and include:

- Proof-of-concept implementations
- Version comparisons
- Experimental features

### Validation

Before using scripts in production:

1. Review the script header for version information and changelog
2. Test in a non-production environment
3. Verify all required modules are installed
4. Check logging output for any warnings or errors
5. For `e365/quarantine-to-block.ps1`, verify release, TABL selection, and deletion behaviour in a test tenant first. DNSBL reporting now runs only when `-ReportToDnsbl` is passed, or when defaults mode is explicitly requested and the saved DNSBL preference is enabled.

## Logging and Troubleshooting

### Logging Standards

All scripts follow consistent logging practices:

- Log files stored in `$env:TEMP` with timestamps
- Comprehensive error logging with context
- Success and failure reporting
- Progress indicators for long-running operations

### Common Issues

- **Module Import Errors**: Ensure required PowerShell modules are installed
- **Authentication Failures**: Verify credentials and MFA settings
- **Permission Errors**: Check administrative rights for target systems
- **Network Connectivity**: Ensure access to required cloud services
- **Quarantine-to-Block DNSBL Skips**: DNSBL reporting is explicit opt-in. The script skips DNSBL submission unless `-ReportToDnsbl` is supplied, or defaults mode is explicitly requested with DNSBL enabled in the saved preferences.

### Support Resources

- Check script headers for specific documentation links
- Review Microsoft documentation for API changes
- Consult PowerShell Gallery for module updates

## Accessibility

This project is committed to accessibility and inclusive design:

- Scripts include progress indicators and clear status messages
- Documentation uses descriptive text for all functionality
- Error messages provide actionable guidance
- GUI interfaces follow accessibility best practices
- All documentation supports screen readers

## Contributing

Contributions to improve and expand this script collection are welcome. Please read the contribution guidelines:

1. **Code Standards**: Follow PowerShell best practices and existing code style
2. **Documentation**: Include comprehensive headers and inline comments
3. **Testing**: Validate scripts in appropriate test environments
4. **Security**: Ensure no hardcoded credentials or sensitive information

### Development Guidelines

- Use Australian English (EN-AU) for documentation and comments
- Include proper error handling and logging
- Follow the established folder structure
- Update this README when adding new functionality

## Changelog

### Recent Updates

- **28/04/2026**: Quarantine-to-Block now treats DNSBL reporting as explicit opt-in, keeps DNSBL scope roots separate during evaluation, expands function-level comment-based help across the script, and validates the workflow with dedicated regression tests for PSL loading, filter handling, export fallback, DNSBL gating, and block-expiry validation.
- **30/01/2026**: Quarantine-to-Block workflow hardened: cancel on release grid now continues with zero releases; added `-IncludeProviderRoots` to opt-in common provider roots for candidate selection; zero-candidate diagnostics preview added; DNSBL and deletion steps gated strictly on domain selections; dry-run guidance documented.
- **6/06/2025**: Enhanced user creation script with group copying improvements
- **27/03/2025**: Added Clear Base User and Clear All User functionality
- **21/05/2025**: Implemented base group validation and management
- **4/03/2025**: Updated department listings for dynamic group memberships

### Version History

See individual script headers for detailed version history and changelog information.

## License

This project is licensed under the GNU General Public License v3.0 - see the [LICENSE](LICENSE) file for details.

Copyright (c) 2025, Michael Harris, All rights reserved.

## Like to say thank you?

If these scripts have helped you in your IT administration tasks, consider:

- ⭐ Starring this repository
- 🐛 Reporting issues or suggesting improvements
- 📖 Contributing to the documentation
- ☕ [Buy me a coffee](https://ko-fi.com/twcau) to support continued development

## Contact and Support

### Project Maintainer

- **Michael Harris** - [@twcau](https://github.com/twcau)

### Getting Help

- **Issues**: Report bugs or request features via [GitHub Issues](https://github.com/twcau/PowerShellScripting/issues)
- **Discussions**: Join the conversation in [GitHub Discussions](https://github.com/twcau/PowerShellScripting/discussions)
- **Documentation**: Review script headers and Microsoft documentation links

### Support Guidelines

- Provide clear descriptions of issues with relevant log files
- Include PowerShell version and module information
- Specify the target environment (on-premises, cloud, hybrid)
- Follow the issue templates when reporting problems

---

_This project follows Microsoft PowerShell best practices and maintains compatibility with enterprise IT environments._

## ScriptLauncher: Build & Publish

The WPF-based ScriptLauncher app lives in `ScriptLauncher/`. It lets you organise and run PowerShell scripts by category, with per-user JSON config and optional elevation.

### Prerequisites

- Windows 10/11
- .NET SDK 8 (LTS) or 10 (latest). Verify installation:

```powershell
dotnet --info
```

If SDK is missing, install via Winget:

```powershell
winget install Microsoft.DotNet.SDK.8
# or
winget install Microsoft.DotNet.SDK.10
```

This repo includes [global.json](global.json) to prefer SDK 8 and roll forward to newer SDKs if needed.

### Build & Run (Debug)

```powershell
dotnet build ScriptLauncher\ScriptLauncher.csproj -c Debug
dotnet run --project ScriptLauncher\ScriptLauncher.csproj
```

First run will prompt to browse an existing config or create `%AppData%\ScriptLauncher\scripts.json`.

### CI Checks

This repository includes automated CI for the WPF `ScriptLauncher` app. On pushes and pull requests to the default branches, GitHub Actions will:

- Build with warnings treated as errors to enforce quality (`-warnaserror`).
- Run an analyser sweep via `dotnet format analyzers` at diagnostic verbosity.
- Capture a verbose build (`-v diag`) and upload both logs as workflow artefacts.

Workflow: [.github/workflows/dotnet-ci.yml](.github/workflows/dotnet-ci.yml)

Badge: See the status badge at the top of this README.

#### Download Workflow Logs

PR authors can download the CI logs for troubleshooting:

1. Open your pull request on GitHub.
2. Select the "Checks" tab, then choose ".NET Build & Analyzers (ScriptLauncher)".
3. Open the latest workflow run for your commit.
4. In the run summary, find the Artefacts section and download `scriptlauncher-logs`.
5. The zip contains `analyzers-diagnostics.log` and `build-diagnostics.log`.

### Publish Single EXE and Zip

```powershell
dotnet publish ScriptLauncher\ScriptLauncher.csproj -c Release -r win-x64 --self-contained true /p:PublishSingleFile=true
Compress-Archive -Path ScriptLauncher\bin\Release\net8.0-windows\win-x64\publish\* -DestinationPath ScriptLauncher-win-x64.zip -Force
```

Distribute the `ScriptLauncher-win-x64.zip`; users can run `ScriptLauncher.exe`. On first launch, the app will discover or create the per-user config.

### UI Interaction Standards (ScriptLauncher)

- **Commands-only menus**: Menu items must use `Command` only (no duplicate `Click + Command`). Dialogs open via `CommandBindings` in `MainWindow.xaml.cs`.
- **Single-press Esc close**: Every modal window implements a native-handle ESC hook (`HwndSource.AddHook` with `WM_KEYDOWN/VK_ESCAPE`) to close immediately, regardless of focused control or dropdowns.
- **Owner assignment**: All modal dialogs are opened with `Owner = MainWindow` to ensure consistent modality and focus behaviour.
- **No global Esc interceptors**: Avoid thread-level ESC interceptors; handle Esc per dialog to prevent unintended interactions.
- **Accessibility**: Provide access keys in dialog buttons and consistent keyboard navigation (e.g., Tab behaviour in grids).

These standards are enforced to maintain consistent, accessible UX and to prevent regressions like double-Esc or dialog respawn.
in `MainWindow.xaml.cs`.

- **Single-press Esc close**: Every modal window implements a native-handle ESC hook (`HwndSource.AddHook` with `WM_KEYDOWN/VK_ESCAPE`) to close immediately, regardless of focused control or dropdowns.
- **Owner assignment**: All modal dialogs are opened with `Owner = MainWindow` to ensure consistent modality and focus behaviour.
- **No global Esc interceptors**: Avoid thread-level ESC interceptors; handle Esc per dialog to prevent unintended interactions.
- **Accessibility**: Provide access keys in dialog buttons and consistent keyboard navigation (e.g., Tab behaviour in grids).

These standards are enforced to maintain consistent, accessible UX and to prevent regressions like double-Esc or dialog respawn.
