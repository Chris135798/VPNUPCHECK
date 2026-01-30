' VPN Check Tray Launcher - Runs the tray app completely hidden
Set objShell = CreateObject("WScript.Shell")
scriptPath = objShell.ExpandEnvironmentStrings("%USERPROFILE%") & "\Scripts\VPNCheck-Tray.ps1"
command = "powershell.exe -ExecutionPolicy Bypass -WindowStyle Hidden -File """ & scriptPath & """"
objShell.Run command, 0, False
