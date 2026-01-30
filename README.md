# VPN Connection Check for Windows

A Windows utility that periodically checks if you're connected to a VPN and warns you if you're not. Supports ExpressVPN, Cisco Secure Client (AnyConnect), and WireGuard.

![Windows](https://img.shields.io/badge/Windows-10%2F11-blue)
![PowerShell](https://img.shields.io/badge/PowerShell-5.1+-purple)
![License](https://img.shields.io/badge/License-MIT-green)

## Features

- **Automatic VPN detection** for ExpressVPN, Cisco Secure Client, and WireGuard
- **Scheduled checks** at customizable intervals (15/30/60 minutes or at logon)
- **Warning popup** when no VPN connection is detected
- **System tray app** to quickly enable/disable checking
- **No window flash** - runs completely hidden
- **Single instance** - prevents multiple warning popups from stacking

## Quick Start

### 1. Download

Download all files from the [Releases](../../releases) page or clone the repository:

```bash
git clone https://github.com/yourusername/vpn-check-windows.git
```

### 2. Install

1. Copy all files to `%USERPROFILE%\Scripts\` (e.g., `C:\Users\YourName\Scripts\`)

2. Run `Install-VPNCheckTask.bat` as Administrator:
   - Right-click → **Run as administrator**
   - Choose your preferred check interval

3. Done! The VPN check will now run automatically.

### 3. (Optional) System Tray Toggle

For easy enable/disable control via system tray:

1. Double-click `VPNCheck-Tray.vbs` (accept the UAC prompt)
2. Look for the icon in your system tray (bottom-right, near the clock)
3. Run `Add-To-Startup.bat` to auto-start the tray app with Windows

## Files

| File | Description |
|------|-------------|
| `Check-VPNConnection.ps1` | Main script that checks VPN status |
| `Run-VPNCheck.vbs` | Launcher for hidden execution (no window flash) |
| `Install-VPNCheckTask.bat` | Creates the Windows scheduled task |
| `VPNCheck-Tray.ps1` | System tray toggle app |
| `VPNCheck-Tray.vbs` | Launcher for the tray app |
| `Add-To-Startup.bat` | Adds tray app to Windows startup |
| `Enable-VPNCheck.bat` | Manually enable VPN checking |
| `Disable-VPNCheck.bat` | Manually disable VPN checking |

## System Tray App

The tray app provides a convenient way to toggle VPN checking on/off:

| Icon | Status |
|------|--------|
| 🟢 Green | VPN check is **enabled** |
| 🔴 Red | VPN check is **disabled** |
| ⚫ Gray | Scheduled task not found |

**Controls:**
- **Left-click** - Toggle enabled/disabled
- **Right-click** - Menu with Enable/Disable/Exit options
- **Hover** - Shows current status

## Configuration

### Enable Logging

Edit `Check-VPNConnection.ps1` and set:

```powershell
$EnableLogging = $true
```

Logs are written to `%USERPROFILE%\VPNCheck.log`

### Change Check Interval

Re-run `Install-VPNCheckTask.bat` and select a different interval, or modify the task directly in Windows Task Scheduler.

### Add More VPN Providers

Edit `Check-VPNConnection.ps1` and add a new detection function. VPNs are detected by:
- Network adapter name/description
- Running processes
- Active routing table entries

## How Detection Works

| VPN | Detection Method |
|-----|------------------|
| **ExpressVPN** | Checks for ExpressVPN processes + Lightway/TAP/Wintun adapters with active VPN routes (0.0.0.0/1, 128.0.0.0/1) |
| **Cisco Secure Client** | Checks for Cisco AnyConnect/Secure Client network adapter in "Up" state |
| **WireGuard** | Checks for WireGuard adapter or running WireGuardTunnel service |

## Troubleshooting

### Warning doesn't appear
- Check if notifications are enabled in Windows Settings
- Run the script manually to test: `wscript.exe "%USERPROFILE%\Scripts\Run-VPNCheck.vbs"`
- Check the log file for errors

### False positives (VPN detected when not connected)
- Enable logging to see what's being detected
- List your adapters: `Get-NetAdapter | Format-Table Name, InterfaceDescription, Status`
- The script checks for active VPN routes, not just adapter presence

### Task doesn't run
- Verify the task exists: `schtasks /query /tn "VPN Connection Check"`
- Check Task Scheduler history for errors
- Ensure scripts are in `%USERPROFILE%\Scripts\`

### Enable/Disable doesn't work
- Use the `.bat` files (not `.ps1`) - they handle admin elevation
- Or run PowerShell as Administrator

## Uninstall

1. Remove the scheduled task:
   ```cmd
   schtasks /delete /tn "VPN Connection Check" /f
   ```

2. Remove from startup (if added):
   ```cmd
   del "%APPDATA%\Microsoft\Windows\Start Menu\Programs\Startup\VPNCheck-Tray.lnk"
   ```

3. Delete the Scripts folder contents

## Requirements

- Windows 10 or 11
- PowerShell 5.1 or later (included with Windows)
- Administrator rights (for scheduled task installation)

## License

MIT License - see [LICENSE](LICENSE) for details.

## Contributing

Contributions are welcome! Feel free to:
- Add support for additional VPN providers
- Improve detection methods
- Report issues or bugs

## Acknowledgments

Built with the assistance of Claude (Anthropic).
