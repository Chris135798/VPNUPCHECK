# VPN Check Tray Toggle
# System tray app to enable/disable VPN connection check

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# Self-elevate if not running as admin
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Start-Process powershell.exe -ArgumentList "-ExecutionPolicy Bypass -WindowStyle Hidden -File `"$PSCommandPath`"" -Verb RunAs
    exit
}

# Task name
$taskName = "VPN Connection Check"

# Function to check if task is enabled
function Get-TaskEnabled {
    try {
        $task = Get-ScheduledTask -TaskName $taskName -ErrorAction Stop
        return ($task.State -ne "Disabled")
    } catch {
        return $null  # Task doesn't exist
    }
}

# Function to create icons programmatically
function New-StatusIcon {
    param([string]$Color)
    
    $bitmap = New-Object System.Drawing.Bitmap(16, 16)
    $graphics = [System.Drawing.Graphics]::FromImage($bitmap)
    $graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
    
    switch ($Color) {
        "Green" {
            $brush = [System.Drawing.Brushes]::LimeGreen
            $pen = New-Object System.Drawing.Pen([System.Drawing.Color]::DarkGreen, 1)
        }
        "Red" {
            $brush = [System.Drawing.Brushes]::Red
            $pen = New-Object System.Drawing.Pen([System.Drawing.Color]::DarkRed, 1)
        }
        "Gray" {
            $brush = [System.Drawing.Brushes]::Gray
            $pen = New-Object System.Drawing.Pen([System.Drawing.Color]::DarkGray, 1)
        }
    }
    
    # Draw filled circle with border
    $graphics.FillEllipse($brush, 1, 1, 13, 13)
    $graphics.DrawEllipse($pen, 1, 1, 13, 13)
    
    # Add V for VPN
    $font = New-Object System.Drawing.Font("Arial", 7, [System.Drawing.FontStyle]::Bold)
    $graphics.DrawString("V", $font, [System.Drawing.Brushes]::White, 3, 1)
    
    $graphics.Dispose()
    
    $icon = [System.Drawing.Icon]::FromHandle($bitmap.GetHicon())
    return $icon
}

# Create icons
$iconEnabled = New-StatusIcon -Color "Green"
$iconDisabled = New-StatusIcon -Color "Red"
$iconMissing = New-StatusIcon -Color "Gray"

# Create notification icon
$notifyIcon = New-Object System.Windows.Forms.NotifyIcon
$notifyIcon.Visible = $true

# Create context menu
$contextMenu = New-Object System.Windows.Forms.ContextMenuStrip

$menuEnable = New-Object System.Windows.Forms.ToolStripMenuItem
$menuEnable.Text = "Enable VPN Check"

$menuDisable = New-Object System.Windows.Forms.ToolStripMenuItem
$menuDisable.Text = "Disable VPN Check"

$menuSeparator = New-Object System.Windows.Forms.ToolStripSeparator

$menuExit = New-Object System.Windows.Forms.ToolStripMenuItem
$menuExit.Text = "Exit"

$contextMenu.Items.AddRange(@($menuEnable, $menuDisable, $menuSeparator, $menuExit))
$notifyIcon.ContextMenuStrip = $contextMenu

# Function to update icon and menu based on status
function Update-Status {
    $enabled = Get-TaskEnabled
    
    if ($null -eq $enabled) {
        $notifyIcon.Icon = $iconMissing
        $notifyIcon.Text = "VPN Check - Task not found!"
        $menuEnable.Enabled = $false
        $menuDisable.Enabled = $false
    } elseif ($enabled) {
        $notifyIcon.Icon = $iconEnabled
        $notifyIcon.Text = "VPN Check - ENABLED"
        $menuEnable.Enabled = $false
        $menuDisable.Enabled = $true
    } else {
        $notifyIcon.Icon = $iconDisabled
        $notifyIcon.Text = "VPN Check - DISABLED"
        $menuEnable.Enabled = $true
        $menuDisable.Enabled = $false
    }
}

# Enable action
$menuEnable.Add_Click({
    try {
        schtasks /change /tn $taskName /enable | Out-Null
        Update-Status
        $notifyIcon.ShowBalloonTip(2000, "VPN Check", "VPN Check has been ENABLED", [System.Windows.Forms.ToolTipIcon]::Info)
    } catch {
        $notifyIcon.ShowBalloonTip(3000, "Error", "Failed to enable task", [System.Windows.Forms.ToolTipIcon]::Error)
    }
})

# Disable action
$menuDisable.Add_Click({
    try {
        schtasks /change /tn $taskName /disable | Out-Null
        Update-Status
        $notifyIcon.ShowBalloonTip(2000, "VPN Check", "VPN Check has been DISABLED", [System.Windows.Forms.ToolTipIcon]::Warning)
    } catch {
        $notifyIcon.ShowBalloonTip(3000, "Error", "Failed to disable task", [System.Windows.Forms.ToolTipIcon]::Error)
    }
})

# Left-click toggles
$notifyIcon.Add_Click({
    param($sender, $e)
    if ($e.Button -eq [System.Windows.Forms.MouseButtons]::Left) {
        $enabled = Get-TaskEnabled
        if ($null -ne $enabled) {
            if ($enabled) {
                $menuDisable.PerformClick()
            } else {
                $menuEnable.PerformClick()
            }
        }
    }
})

# Exit action
$menuExit.Add_Click({
    $notifyIcon.Visible = $false
    $notifyIcon.Dispose()
    [System.Windows.Forms.Application]::Exit()
})

# Initial status update
Update-Status

# Show startup notification
$notifyIcon.ShowBalloonTip(2000, "VPN Check Toggle", "Click tray icon to toggle VPN check on/off", [System.Windows.Forms.ToolTipIcon]::Info)

# Keep the app running
[System.Windows.Forms.Application]::Run()
