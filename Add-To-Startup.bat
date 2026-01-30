@echo off
echo Creating startup shortcut for VPN Check Tray...

set "STARTUP=%APPDATA%\Microsoft\Windows\Start Menu\Programs\Startup"
set "VBS_PATH=%USERPROFILE%\Scripts\VPNCheck-Tray.vbs"

:: Create shortcut using PowerShell
powershell -Command "$ws = New-Object -ComObject WScript.Shell; $s = $ws.CreateShortcut('%STARTUP%\VPNCheck-Tray.lnk'); $s.TargetPath = 'wscript.exe'; $s.Arguments = '\"%VBS_PATH%\"'; $s.WorkingDirectory = '%USERPROFILE%\Scripts'; $s.Description = 'VPN Check Tray Toggle'; $s.Save()"

echo.
echo Done! VPN Check Tray will now start automatically with Windows.
echo.
echo To remove from startup, delete:
echo   %STARTUP%\VPNCheck-Tray.lnk
echo.
pause
