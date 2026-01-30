@echo off
:: Check for admin rights
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo Requesting administrator privileges...
    powershell -Command "Start-Process '%~f0' -Verb RunAs"
    exit /b
)

schtasks /change /tn "VPN Connection Check" /disable
echo.
echo VPN Check has been DISABLED.
echo.
pause
