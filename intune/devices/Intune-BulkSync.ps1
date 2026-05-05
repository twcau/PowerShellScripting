# Intune - Bulk sync devices
# v2.2
# Created on 4/06/2025, by Michael Harris - ICT Analyst
# Last updated 20/06/2025, by Michael Harris
# See Changelog for update history
#
#---------------------------------------------------------------------
# Purpose: Connect to Intune, and initiate a sync for all devices
#---------------------------------------------------------------------
#
# TODO:
# - See if Powershell 7 Test Code, and Powershell 7 module loading can be simplified into a single script
#
# Changelog
# - 20/06/2025: Added functions to test for, and import, the PowerShell 7 Test Module
# - 12/06/2025: Added function and menu option to perform a sync against devices in known test groups meeting a defined pattern
# - 11/06/2025: Added function and menu option to perfom a single device sync; search logic for single device sync; update language on end of sync loop to be more clear on what is being asked.
# - 9/06/2025: Prompt user for the specific device OS they wish to sync by menu, or option to sync all devices, improved logic to deal with header formatting issues
# - 4/06/2025: Initial release; include code to test for Powershell 7, as needed for Webauthn support.

#-------------------------------------------------------------------------------------------
# Common functions
#-------------------------------------------------------------------------------------------

function Import-RequirePwsh7Module {
    $modulePath = "C:\Users\pc\OneDrive - Crispy Kangaroo\Documents\GitProjects\PowerShellScriptingNew\general\module-management\Module-PowerShell7-Require.ps1"

    Write-Host "$($PSStyle.Foreground.White)$($PSStyle.Background.Blue)Testing for, and loading, required scripts$($PSStyle.Reset)`n"

    Set-ExecutionPolicy RemoteSigned -Scope CurrentUser

    # Check if the file exists
    if (-not (Test-Path -Path $modulePath)) {
        Write-Host "❌ The required module file was not found at: $modulePath" -ForegroundColor Red
        return $false
        Write-Host "Press the Enter key to finish the script..."
        Read-Host
        exit
    }

    # Unblock the file if it's blocked (Zone.Identifier)
    try {
        if (Get-Item $modulePath -Stream 'Zone.Identifier' -ErrorAction SilentlyContinue) {
            Write-Host "⚠️  The script is blocked (from another source). Attempting to unblock..." -ForegroundColor Yellow
            Unblock-File -Path $modulePath
            Write-Host "✅ File unblocked." -ForegroundColor Green
        }
    }
    catch {
        Write-Host "⚠️  Could not determine if file is blocked. Continuing..." -ForegroundColor Yellow
    }

    # Check if execution policy will allow sourcing it
    $policy = Get-ExecutionPolicy -Scope CurrentUser
    if ($policy -in @('Restricted', 'AllSigned')) {
        Write-Host "⚠️  Current execution policy is '$policy' and may prevent script execution." -ForegroundColor Yellow
        Write-Host "You may need to re-run: Set-ExecutionPolicy RemoteSigned -Scope CurrentUser"
        return $false
        Write-Host "Press the Enter key to finish the script..."
        Read-Host
        exit
    }

    # Dot-source the script
    try {
        . "$modulePath"
        Write-Host "✅ Require-Pwsh7 module successfully imported from:`n   $modulePath" -ForegroundColor Green
        return $true
    }
    catch {
        Write-Host "❌ Failed to import the module: $_" -ForegroundColor Red
        return $false
        Write-Host "Press the Enter key to finish the script..."
        Read-Host
        exit
    }
}


#-------------------------------------------------------------------------------------------
# STEP 0: Start script, get file names, check and select right file
#-------------------------------------------------------------------------------------------

Write-Host "$($PSStyle.Foreground.White)$($PSStyle.Background.Blue)Intune - Bulk sync devices$($PSStyle.Reset)`n"

#-------------------------------------------------------------------------------------------
# STEP 1: Run me in Powershell 7
#-------------------------------------------------------------------------------------------

# Check if running in PowerShell 7 (Core)
if (-not (Import-RequirePwsh7Module)) {
    Write-Host "Exiting because the required module could not be loaded." -ForegroundColor Red
    exit 1
}

#-------------------------------------------------------------------------------------------
# STEP 2: Test for required modules
#-------------------------------------------------------------------------------------------

Write-Host ""
Write-Host "$($PSStyle.Foreground.White)$($PSStyle.Background.Blue)Testing for required modules$($PSStyle.Reset)`n"

<#
Specify, then test for, required modules, install if needed, then import the module.
#>

$moduleNames = @(
    "Microsoft.Graph.Intune",
    "Microsoft.Graph.DeviceManagement",
    "Microsoft.Graph.Authentication"
)

foreach ($moduleName in $moduleNames) {
    if (-not (Get-Module -ListAvailable -Name $moduleName)) {
        Write-Host "Module '$moduleName' not found. Installing..." -ForegroundColor Yellow
        Install-Module -Name $moduleName -Scope CurrentUser -Force
    }
    else {
        Write-Host "Module '$moduleName' is already installed." -ForegroundColor Green
    }

    # Import the module
    Import-Module -Name $moduleName -Force
}

#-------------------------------------------------------------------------------------------
# STEP 3: Authenticate
#-------------------------------------------------------------------------------------------

Write-Host ""
Write-Host "$($PSStyle.Foreground.White)$($PSStyle.Background.Blue)Authentication$($PSStyle.Reset)"
Write-Host  -Foregroundcolor Black -BackgroundColor Black
Write-Host "When prompted - please authenticate with your permitted account, to connect to Intune via Microsoft Graph.`n" -ForegroundColor Yellow

<#
Connect to Intune Graph module with the required permissions.
#>
Connect-MgGraph -Scopes "DeviceManagementApps.ReadWrite.All"


#-------------------------------------------------------------------------------------------
# STEP 4: Functions, including device syncronisation
#-------------------------------------------------------------------------------------------

# List of menu options
function Show-Menu {
    Write-Host "$($PSStyle.Foreground.White)$($PSStyle.Background.Blue)Select devices to Sync$($PSStyle.Reset)"
    Write-Host "" -Foregroundcolor Black -BackgroundColor Black
    Write-Host "Enter the device operating systems you would like to sync with Intune`n" -ForegroundColor Yellow

    Write-Host "===="
    Write-Host "By operating system"
    Write-Host "1. Windows"
    Write-Host "2. Android"
    Write-Host "3. iOS"
    Write-Host "4. All operating systems"
    Write-Host "===="
    Write-Host "By device"
    Write-Host "5. Single device by name"
    Write-Host "===="
    Write-Host "By group"
    Write-Host "6. All devices in test groups"
    Write-Host "===="
    Write-Host "7. End script"
    Write-Host ""
}

# TODO: Address issues in code with syncronisation.

<#
Example of errors

Select devices to Sync                                                                                                                                                                                                                          Enter the device operating systems you would like to sync with Intune                                                                                                                                                                           ====                                                                                                                    By operating system                                                                                                     1. Windows                                                                                                              2. Android                                                                                                              3. iOS                                                                                                                  4. All operating systems                                                                                                ====                                                                                                                    By device                                                                                                               5. Single device by name                                                                                                ====                                                                                                                    By group                                                                                                                6. All devices in test groups                                                                                           ====                                                                                                                    7. End script                                                                                                                                                                                                                                   Select an option (1-7): 3                                                                                                                                                                                                                       Syncing iOS devices                                                                                                     Sync-MgDeviceManagementManagedDevice_Sync: C:\Users\pc\OneDrive - Crispy Kangaroo\Documents\GitProjects\PowerShellScriptingNew\intune\devices\Intune-BulkSync.ps1:292                                                                           Line |                                                                                                                   292 |              Sync-MgDeviceManagementManagedDevice -ManagedDeviceId $de …                                              |              ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~                                                | {   "_version": 3,   "Message": "Application is not authorized to perform this operation. Application must have       | one of the following scopes: DeviceManagementManagedDevices.PrivilegedOperations.All - Operation ID (for              | customer support): 00000000-0000-0000-0000-000000000000 - Activity ID: 1be35c24-4299-4987-8674-cb157e0624e7 -         | Url:                                                                                                                  | https://proxy.msud01.manage.microsoft.com/DeviceFE/StatelessDeviceFEService/deviceManagement/managedDevices('df3412a5-7fbf-4776-90e0-b80bd89371ef')/microsoft.management.services.api.syncDevice?api-version=2025-07-09",   "CustomApiErrorPhrase": "",   "RetryAfter": null,   "ErrorSourceService": "",   "HttpHeaders": "{}" }  Status: 403 (Forbidden) ErrorCode: Forbidden Date: 2026-01-07T04:43:04  Headers: Vary                          : Accept-Encoding Strict-Transport-Security     : max-age=31536000 request-id                    : afab8aee-9d6e-46b7-9c94-f57d30f7d71d client-request-id             : 1be35c24-4299-4987-8674-cb157e0624e7 x-ms-ags-diagnostic           : {"ServerInfo":{"DataCenter":"Australia Southeast","Slice":"E","Ring":"3","ScaleUnit":"000","RoleInstance":"ML1PEPF0000F462"}} Date                          : Wed, 07 Jan 2026 04:43:03 GMT                                                                                                                                                                                                                         Recommendation: See service error codes: https://learn.microsoft.com/graph/errors                                     Sync initiated for device: Michael’s iPhone                                                                             Sync-MgDeviceManagementManagedDevice_Sync: C:\Users\pc\OneDrive - Crispy Kangaroo\Documents\GitProjects\PowerShellScriptingNew\intune\devices\Intune-BulkSync.ps1:292                                                                           Line |                                                                                                                   292 |              Sync-MgDeviceManagementManagedDevice -ManagedDeviceId $de …                                              |              ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~                                                | {   "_version": 3,   "Message": "Application is not authorized to perform this operation. Application must have       | one of the following scopes: DeviceManagementManagedDevices.PrivilegedOperations.All - Operation ID (for              | customer support): 00000000-0000-0000-0000-000000000000 - Activity ID: 40b0de9d-263b-469c-8062-23ba1cb297fa -         | Url:                                                                                                                  | https://proxy.msud01.manage.microsoft.com/DeviceFE/StatelessDeviceFEService/deviceManagement/managedDevices('eb69b08c-c441-4b1a-8a47-9ada70bbb8f7')/microsoft.management.services.api.syncDevice?api-version=2025-07-09",   "CustomApiErrorPhrase": "",   "RetryAfter": null,   "ErrorSourceService": "",   "HttpHeaders": "{}" }  Status: 403 (Forbidden) ErrorCode: Forbidden Date: 2026-01-07T04:43:04  Headers: Vary                          : Accept-Encoding Strict-Transport-Security     : max-age=31536000 request-id                    : 5e08986f-0f43-46b7-835d-42f3a8240b55 client-request-id             : 40b0de9d-263b-469c-8062-23ba1cb297fa x-ms-ags-diagnostic           : {"ServerInfo":{"DataCenter":"Australia Southeast","Slice":"E","Ring":"3","ScaleUnit":"000","RoleInstance":"ML1PEPF0000F462"}} Date                          : Wed, 07 Jan 2026 04:43:03 GMT                                                                                                                                                                                                                         Recommendation: See service error codes: https://learn.microsoft.com/graph/errors                                     Sync initiated for device: Michael’s iPad                                                                                                                                                                                                       Sync of iOS devices complete.                                                                                                                                                                                                                   Do you want to sync other devices? (y/n): y                                                                             Select devices to Sync                                                                                                                                                                                                                          Enter the device operating systems you would like to sync with Intune                                                                                                                                                                           ====                                                                                                                    By operating system                                                                                                     1. Windows                                                                                                              2. Android                                                                                                              3. iOS                                                                                                                  4. All operating systems                                                                                                ====                                                                                                                    By device                                                                                                               5. Single device by name                                                                                                ====                                                                                                                    By group                                                                                                                6. All devices in test groups                                                                                           ====                                                                                                                    7. End script                                                                                                                                                                                                                                   Select an option (1-7): 1                                                                                                                                                                                                                       Syncing windows devices                                                                                                                                                                                                                         Sync-MgDeviceManagementManagedDevice_Sync: C:\Users\pc\OneDrive - Crispy Kangaroo\Documents\GitProjects\PowerShellScriptingNew\intune\devices\Intune-BulkSync.ps1:238                                                                           Line |                                                                                                                   238 |              Sync-MgDeviceManagementManagedDevice -ManagedDeviceId $de …                                              |              ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~                                                | {   "_version": 3,   "Message": "Application is not authorized to perform this operation. Application must have       | one of the following scopes: DeviceManagementManagedDevices.PrivilegedOperations.All - Operation ID (for              | customer support): 00000000-0000-0000-0000-000000000000 - Activity ID: ccb75887-921e-459e-b37c-72e4a3c73154 -         | Url:                                                                                                                  | https://proxy.msud01.manage.microsoft.com/DeviceFE/StatelessDeviceFEService/deviceManagement/managedDevices('ccf9d2c8-e421-48bb-aa54-af0bea5f0ec2')/microsoft.management.services.api.syncDevice?api-version=2025-07-09",   "CustomApiErrorPhrase": "",   "RetryAfter": null,   "ErrorSourceService": "",   "HttpHeaders": "{}" }  Status: 403 (Forbidden) ErrorCode: Forbidden Date: 2026-01-07T04:43:54  Headers: Vary                          : Accept-Encoding Strict-Transport-Security     : max-age=31536000 request-id                    : 58cc9e09-46e5-4581-8157-b34137678085 client-request-id             : ccb75887-921e-459e-b37c-72e4a3c73154 x-ms-ags-diagnostic           : {"ServerInfo":{"DataCenter":"Australia Southeast","Slice":"E","Ring":"3","ScaleUnit":"000","RoleInstance":"ML1PEPF0000F462"}} Date                          : Wed, 07 Jan 2026 04:43:53 GMT                                                                                                                                                                                                                         Recommendation: See service error codes: https://learn.microsoft.com/graph/errors                                     Sync initiated for device: WINCHESTER08                                                                                                                                                                                                         Sync of Windows devices complete.                                                                                                                                                                                                               Do you want to sync other devices? (y/n):

#>

# TODO: Optimise Proceed with Sync block in each function, so it can just pass code to a standalone function to perform the sync, and avoid having to have the same code repeat in multiple places in the script.

# Sync a single device

function syncSingleDevice {
    Write-Host ""
    Write-Host "$($PSStyle.Foreground.White)$($PSStyle.Background.Blue)Syncing a single Windows device$($PSStyle.Reset)`n"

    # Prompt for a machine name
    $machineName = Read-Host "$($PSStyle.Foreground.Yellow)$($PSStyle.Background.Black)Enter the name of the device to sync$($PSStyle.Reset)"

    # Get all Windows devices
    $devices = Get-MgDeviceManagementManagedDevice -All

    # First, try exact match
    $device = $devices | Where-Object { $_.DeviceName -ieq $machineName }

    if (-not $device) {
        # If no exact match, try partial matches (and sort them)
        $partialMatches = $devices |
        Where-Object { $_.DeviceName -ilike "*$machineName*" } |
        Sort-Object DeviceName

        if (-not $partialMatches) {
            Write-Host "No device found matching '$machineName'." -ForegroundColor Red -BackgroundColor Black
            return
        }

        # Display sorted partial matches and prompt for selection
        Write-Host "`n$($PSStyle.Foreground.Yellow)$($PSStyle.Background.Black)Multiple devices found matching '$machineName':$($PSStyle.Reset)`n"
        for ($i = 0; $i -lt $partialMatches.Count; $i++) {
            Write-Host "$($i + 1): $($partialMatches[$i].DeviceName)"
        }

        $selection = Read-Host "`n$($PSStyle.Foreground.Yellow)$($PSStyle.Background.Black)Enter the number of the device you wish to sync$($PSStyle.Reset)"

        if ($selection -notmatch '^\d+$' -or [int]$selection -lt 1 -or [int]$selection -gt $partialMatches.Count) {
            Write-Host "Invalid selection. Exiting." -ForegroundColor Red
            return
        }

        $device = $partialMatches[ [int]$selection - 1 ]
    }

    # Proceed with sync
    try {
        Sync-MgDeviceManagementManagedDevice -ManagedDeviceId $device.Id
        Write-Host "`nSync initiated for device: $($device.DeviceName)" -ForegroundColor Green
    }
    catch {
        Write-Host "Failed to sync device: $($device.DeviceName)" -ForegroundColor Red
    }
    Write-Host ""
    Write-Host "Sync of $($device.DeviceName) complete.`n" -ForegroundColor Green
}

# Sync Windows OS
function syncWindows {
    Write-Host ""
    Write-Host "Syncing windows devices`n" -ForegroundColor Green

    # Insert your Task 1 logic here
    <#
    Get all devices, and execute a Device Sync with Intune.
    #>

    # Get all devices (filter to Windows if needed)
    $devices = Get-MgDeviceManagementManagedDevice -Filter "contains(operatingSystem,'Windows')" -All

    # Loop through each device and initiate a sync
    foreach ($device in $devices) {
        try {
            Sync-MgDeviceManagementManagedDevice -ManagedDeviceId $device.Id
            Write-Host "Sync initiated for device: $($device.DeviceName)" -ForegroundColor Green
        }
        catch {
            Write-Host "Failed to sync device: $($device.DeviceName)" -ForegroundColor Red
        }
    }

    Write-Host ""
    Write-Host "Sync of Windows devices complete.`n" -ForegroundColor Green
}

# Sync Android OS
function syncAndroid {
    Write-Host ""
    Write-Host "Syncing Android devices" -ForegroundColor Green
    # Insert your Task 2 logic here
    <#
    Get all devices, and execute a Device Sync with Intune.
    #>

    # Get all devices (filter to Windows if needed)
    $devices = Get-MgDeviceManagementManagedDevice -Filter "contains(operatingSystem,'Android')" -All

    # Loop through each device and initiate a sync
    foreach ($device in $devices) {
        try {
            Sync-MgDeviceManagementManagedDevice -ManagedDeviceId $device.Id
            Write-Host "Sync initiated for device: $($device.DeviceName)" -ForegroundColor Green
        }
        catch {
            Write-Host "Failed to sync device: $($device.DeviceName)" -ForegroundColor Red
        }
    }

    Write-Host ""
    Write-Host "Sync of Android devices complete.`n"
}

# Sync iOS
function syncIOS {
    Write-Host ""
    Write-Host "Syncing iOS devices" -ForegroundColor Green
    # Insert your Task 3 logic here
    <#
    Get all devices, and execute a Device Sync with Intune.
    #>

    # Get all devices (filter to Windows if needed)
    $devices = Get-MgDeviceManagementManagedDevice -Filter "contains(operatingSystem,'iOS')" -All

    # Loop through each device and initiate a sync
    foreach ($device in $devices) {
        try {
            Sync-MgDeviceManagementManagedDevice -ManagedDeviceId $device.Id
            Write-Host "Sync initiated for device: $($device.DeviceName)" -ForegroundColor Green
        }
        catch {
            Write-Host "Failed to sync device: $($device.DeviceName)" -ForegroundColor Red
        }
    }

    Write-Host ""
    Write-Host "Sync of iOS devices complete.`n"
}

# Sync devices in defined test groups

function syncTestDevices {
    Write-Host ""
    Write-Host "Syncing test devices`n" -ForegroundColor Green

    # Define the Entra group names to check
    $targetGroupNames = @(
        'int_test',
        'int_remediation_test',
        'int_autopilot_test'
    )

    # Retrieve the matching groups
    $groups = foreach ($groupName in $targetGroupNames) {
        try {
            Get-MgGroup -Filter "displayName eq '$groupName'" -All
        }
        catch {
            Write-Host "Error fetching group: $groupName" -ForegroundColor Red
        }
    }

    if (-not $groups) {
        Write-Host "No matching groups found." -ForegroundColor Red
        return
    }

    # Gather all managed device IDs
    $deviceIds = @()

    foreach ($group in $groups) {
        Write-Host "Processing group: $($group.DisplayName)" -ForegroundColor Cyan

        try {
            $members = Get-MgGroupMember -GroupId $group.Id -All

            foreach ($member in $members) {
                $type = $member.'@odata.type'

                Write-Host "   Processing member ID: $($member.Id), Type: $type" -ForegroundColor Gray

                # Attempt sync if it's a user (lookup managed devices by UPN)
                if ($member.PSObject.Properties.Match('UserPrincipalName')) {
                    $upn = $member.UserPrincipalName
                    if ($upn) {
                        try {
                            $userDevices = Get-MgDeviceManagementManagedDevice -Filter "userPrincipalName eq '$upn'" -ErrorAction SilentlyContinue
                            if ($userDevices) {
                                Write-Host "   Found $($userDevices.Count) device(s) for user: $upn"
                                $deviceIds += $userDevices.Id
                            }
                            else {
                                Write-Host "   No managed devices found for user: $upn" -ForegroundColor Yellow
                            }
                        }
                        catch {
                            Write-Host "   Failed to query managed devices for user: $upn" -ForegroundColor Yellow
                        }
                        continue
                    }
                }

                # Attempt to treat member ID as a managed device ID
                try {
                    $device = Get-MgDeviceManagementManagedDevice -ManagedDeviceId $member.Id -ErrorAction SilentlyContinue
                    if ($device) {
                        Write-Host "   Member ID appears to be a managed device: $($device.DeviceName)"
                        $deviceIds += $device.Id
                    }
                    else {
                        Write-Host "   Member ID $($member.Id) is not a managed device." -ForegroundColor DarkYellow
                    }
                }
                catch {
                    Write-Host "   Error checking member ID $($member.Id) as a managed device." -ForegroundColor Yellow
                }
            }

        }
        catch {
            Write-Host "   Error processing members for group: $($group.DisplayName)" -ForegroundColor Red
        }
    }

    $deviceIds = $deviceIds | Select-Object -Unique

    if (-not $deviceIds) {
        Write-Host ""
        Write-Host "No managed devices found from group membership." -ForegroundColor Yellow
        return
    }

    # Retrieve full device records
    $devices = foreach ($id in $deviceIds) {
        try {
            Get-MgDeviceManagementManagedDevice -ManagedDeviceId $id -ErrorAction SilentlyContinue
        }
        catch { Write-CustomMessage "WARNING: Ignored exception in bulk sync loop: $_" }
    }

    if (-not $devices) {
        Write-Host "No valid managed devices found for sync." -ForegroundColor Yellow
        return
    }

    # Sync each device
    foreach ($device in $devices) {
        try {
            Sync-MgDeviceManagementManagedDevice -ManagedDeviceId $device.Id
            Write-Host "✔ Sync initiated for device: $($device.DeviceName)" -ForegroundColor Green
        }
        catch {
            Write-Host "✖ Failed to sync device: $($device.DeviceName)" -ForegroundColor Red
        }
    }

    Write-Host ""
    Write-Host "Sync of test devices complete.`n" -ForegroundColor Green
}


# End script

# TODO: Further fix code, to prevent the window from closing when it was run from within an existing terminal/console. In this screnario, the script should return back to the command prompt
function endScript {
    Write-Host ""    
    Write-Host "$($PSStyle.Foreground.White)$($PSStyle.Background.Green)Script complete$($PSStyle.Reset)"
    Write-Host ""
    Write-Host "Press the Enter key to end and exit the script...`n"
    Read-Host

    if ($host.Name -eq 'ConsoleHost') {
        Stop-Process -Id $PID
    }
    else {
        exit
    }
}

#-------------------------------------------------------------------------------------------
# STEP 5: Render menu to prompt which devices to Sync
#-------------------------------------------------------------------------------------------

do {
    Show-Menu
    $choice = Read-Host "Select an option (1-7)"
    
    switch ($choice) {
        '1' { syncWindows }
        '2' { syncAndroid }
        '3' { syncIOS }
        '4' {
            syncWindows
            syncAndroid
            syncIOS
        }
        '5' { syncSingleDevice }
        '6' { syncTestDevices }
        '7' { endScript }
        default {
            Write-Host "Invalid option. Please select 1 to 7." -ForegroundColor Red
        }
    }

    $repeat = Read-Host "Do you want to sync other devices? (y/n)"
}
while ($repeat -eq 'y')


#-------------------------------------------------------------------------------------------
# STEP 6: End script
#-------------------------------------------------------------------------------------------

# If ended by any other means, ensure graceful and intended exit.

endScript
