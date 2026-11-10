# Autopilot Express

Helping technical staff prepare Windows PC's at scale, within a Microsoft Intune environment

Version 0.3.1 - Test release, released 14/10/2026; Use at your own risk.

Designed and developed by: Michael Harris
Copyright and licensing yet to be determined.

For documentation, consult README.md.

## Key features

- Maintain and track your build bench
  - Quickly prepare multiple PC's at once
  - Track your progress by machine
  - Supports data input from barcode scanners
- Simplifies steps to prepare PC's:
  - Leverage Microsoft Graph API, to avoid repeatedly navigating through Intune to automate common and repeat tasks
  - Apply a consistent workflow, from an ordered manifest of steps, to execute associated code
  - Rollback and restart assistance for OOBE failures
- Track and validate outcomes
  - Records statistics, history, and activities for each step with every AutoPilot device
  - Prompt technicians to perform and check steps when required, and record positive confirmation
  - Statistics to show technician completion workrates and estimate average process time.

## Required permissions

- Your device: Permission to run unsigned PowerShell scripts.
- Intune: Perform Add/Move/Changes associated with devices.
- M365/Entra: Use Microsoft Graph Rest API, with all relevant function permissions.

## Possible enhancements

- Multiple technicians sharing data across devices, for a collaborative workbench and shared device preperation activities
- Remotely execute steps on a device (Dell Command, Windows Update, Install Company Portal Applications, Restart)
- Produce and remotely load a build certificate record to a device
- Single command to update device information in your companies' CMDB
- Single command to export data for whitelisting devices

For more on future enhancements, enter 9 to view the Enhancements and Questions screen
