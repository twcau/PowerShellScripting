<#
Script Selector

Version: 10.0

Created: -
Created by: -

Updated: 20/06/2025
Updated by: Michael Harris

Purpose:
- WinForms to quickly run common scripts

Update history:

20/06/2025
- Updated code to automatically number items in the scriptInfo array
- Add new script: User Creation - External
- Modify Exchange script names from 365 to E365
- Widen window

10/03/2025
- Added 15. 365 - Quarantine Data Export
#>

Set-ExecutionPolicy Unrestricted -Scope CurrentUser

# Load the Windows Forms assembly
Add-Type -AssemblyName System.Windows.Forms

# Create a form
$form = New-Object Windows.Forms.Form -Property @{
    Text      = "Script Selector!"
    Width     = 600
    Height    = 350
    Font      = New-Object Drawing.Font("Segoe UI", 14)
    BackColor = [System.Drawing.Color]::White
    ForeColor = [System.Drawing.Color]::Black
}

# Create a list box to display available scripts
$listBox = New-Object Windows.Forms.ListBox -Property @{
    Location  = New-Object Drawing.Point(20, 20)
    Width     = 540
    Height    = 200
    Font      = New-Object Drawing.Font("Segoe UI", 14)
    BackColor = [System.Drawing.Color]::WhiteSmoke
    ForeColor = [System.Drawing.Color]::Black
}

# Base directory for scripts
$scriptBasePath = "\\server\path\to\folder\for\saved scripts"

# Base list of display names and file names (without numbers, which are automatically added later based on their order in this list)
$scriptInfo = @(
    @{ Display = "AD - User Creation"; File = "User-Creation.ps1" },
    @{ Display = "AD - User Departure"; File = "User-Departure.ps1" },
    @{ Display = "AD - Change of Role"; File = "Copy-Paste-AD-Groups.ps1" },
    @{ Display = "AD - Returning Hire"; File = "Copy-Paste-AD-Groups.ps1" },
    @{ Display = "AD - Password Generator"; File = "Password-Generator.ps1" },
    @{ Display = "AD - User Creation - External"; File = "User-Creation-External.ps1" },
    @{ Display = "AD - Sync to Cloud (Delta)"; File = "Delta-Sync.ps1" },
    @{ Display = "AD - Lockout & PW Expiry Checker"; File = "Lockout-and-PW-expiry-checker.ps1" },
    @{ Display = "AD - Transfer Direct Reports"; File = "Transfer-Direct-Reports.ps1" },
    @{ Display = "AD - Employee Org, Manager and Title Update (Your HR System to AD)"; File = "Employee-Listing.ps1" },
    @{ Display = "Employee Departure Reconcillation (Your HR System to AD)"; File = "Employee-Departure-Reconciliation.ps1" },
    @{ Display = "AD - Inactive users (90 days) to CSV"; File = "Inactive-Users.ps1" },
    @{ Display = "AD - Find OU of a machine"; File = "FindMachineOU.ps1" },
    @{ Display = "InTune - Force Sync All Devices (Windows, Android, or iOS)"; File = "Intune-BulkSync.ps1" },
    @{ Display = "InTune - Show Last Sync Time"; File = "Intune-Show-Last-Sync.ps1" },
    @{ Display = "E365 - Inactive Mailbox"; File = "Inactive-mb.ps1" },
    @{ Display = "E365 - Quarantine Data Export"; File = "E365-Quarantine-ExportRecord.ps1" }
)

# Add numbers based on array index
$scriptMapping = $scriptInfo | ForEach-Object -Begin { $i = 1 } -Process {
    [PSCustomObject]@{
        Name = "$i. $($_.Display)"
        File = $_.File
    }
    $i++
}

# Populate the list box while preserving order
$scriptmappingnames = $scriptMapping | ForEach-Object { $_.Name }
$listBox.Items.AddRange($scriptmappingnames)

# Create a button to run the selected script
$runButton = New-Object Windows.Forms.Button -Property @{
    Location  = New-Object Drawing.Point(20, 240)
    Size      = New-Object Drawing.Size(540, 40)
    Text      = "Run"
    Font      = New-Object Drawing.Font("Segoe UI", 12)
    BackColor = [System.Drawing.Color]::FromArgb(0, 120, 215)
    ForeColor = [System.Drawing.Color]::White
    FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
}

$runButton.Add_Click({
        $selectedScript = $listBox.SelectedItem
        if ($selectedScript) {
            $scriptItem = $scriptMapping | Where-Object { $_.Name -eq $selectedScript }
            if ($scriptItem) {
                $scriptFile = $scriptItem.File
                $scriptPath = Join-Path -Path $scriptBasePath -ChildPath $scriptFile

                if (Test-Path $scriptPath) {
                    # Run the selected script
                    $process = Start-Process powershell.exe -ArgumentList "-File `"$scriptPath`"" -Wait -PassThru
                
                    # Check the exit code
                    switch ($process.ExitCode) {
                        0 {
                            [System.Windows.Forms.MessageBox]::Show("Script completed successfully!", "Success", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
                        }
                        1 {
                            [System.Windows.Forms.MessageBox]::Show("Script encountered an error!", "Error", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
                        }
                        default {
                            [System.Windows.Forms.MessageBox]::Show("Script was canceled or closed!", "Cancelled", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Warning)
                        }
                    }
                }
                else {
                    [System.Windows.Forms.MessageBox]::Show("Script not found!", "Error", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
                }
            }
        }
    })


# Add controls to the form
$form.Controls.Add($listBox)
$form.Controls.Add($runButton)

# Show the form
$form.ShowDialog()
$form.Dispose()
