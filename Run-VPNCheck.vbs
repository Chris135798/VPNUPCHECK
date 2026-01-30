' VPN Check Launcher - Runs PowerShell script completely hidden
' This wrapper prevents the brief PowerShell window flash

Set objShell = CreateObject("WScript.Shell")
scriptPath = objShell.ExpandEnvironmentStrings("%USERPROFILE%") & "\Scripts\Check-VPNConnection.ps1"
command = "powershell.exe -ExecutionPolicy Bypass -WindowStyle Hidden -File """ & scriptPath & """"
objShell.Run command, 0, False
