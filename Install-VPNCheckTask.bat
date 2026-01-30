@echo off
REM ============================================================
REM  Install VPN Check Scheduled Task
REM  Run this script as Administrator
REM ============================================================

echo.
echo ========================================
echo  VPN Check - Scheduled Task Installer
echo ========================================
echo.

REM Check for admin privileges
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo ERROR: This script requires Administrator privileges.
    echo Please right-click and select "Run as administrator"
    echo.
    pause
    exit /b 1
)

REM Set paths
set "SCRIPT_DIR=%USERPROFILE%\Scripts"
set "PS_SCRIPT=%SCRIPT_DIR%\Check-VPNConnection.ps1"
set "VBS_LAUNCHER=%SCRIPT_DIR%\Run-VPNCheck.vbs"

REM Create Scripts directory if it doesn't exist
if not exist "%SCRIPT_DIR%" (
    echo Creating Scripts directory...
    mkdir "%SCRIPT_DIR%"
)

REM Check if scripts exist
if not exist "%PS_SCRIPT%" (
    echo.
    echo WARNING: PowerShell script not found at %PS_SCRIPT%
    echo Please copy Check-VPNConnection.ps1 to %SCRIPT_DIR%
    echo.
)
if not exist "%VBS_LAUNCHER%" (
    echo.
    echo WARNING: VBS launcher not found at %VBS_LAUNCHER%
    echo Please copy Run-VPNCheck.vbs to %SCRIPT_DIR%
    echo.
)

echo.
echo Select how often to check VPN status:
echo   1. Every 15 minutes
echo   2. Every 30 minutes  
echo   3. Every hour
echo   4. At logon only
echo   5. Custom (every N minutes)
echo.
set /p CHOICE="Enter choice (1-5): "

if "%CHOICE%"=="1" (
    set "INTERVAL=15"
    set "TRIGGER_TYPE=interval"
) else if "%CHOICE%"=="2" (
    set "INTERVAL=30"
    set "TRIGGER_TYPE=interval"
) else if "%CHOICE%"=="3" (
    set "INTERVAL=60"
    set "TRIGGER_TYPE=interval"
) else if "%CHOICE%"=="4" (
    set "TRIGGER_TYPE=logon"
) else if "%CHOICE%"=="5" (
    set /p INTERVAL="Enter interval in minutes: "
    set "TRIGGER_TYPE=interval"
) else (
    echo Invalid choice. Defaulting to 30 minutes.
    set "INTERVAL=30"
    set "TRIGGER_TYPE=interval"
)

REM Remove existing task if present
echo.
echo Removing existing task if present...
schtasks /delete /tn "VPN Connection Check" /f >nul 2>&1

REM Create the scheduled task using the VBS launcher (no window flash!)
echo Creating scheduled task...

if "%TRIGGER_TYPE%"=="logon" (
    schtasks /create ^
        /tn "VPN Connection Check" ^
        /tr "wscript.exe \"%VBS_LAUNCHER%\"" ^
        /sc onlogon ^
        /rl highest ^
        /f
) else (
    schtasks /create ^
        /tn "VPN Connection Check" ^
        /tr "wscript.exe \"%VBS_LAUNCHER%\"" ^
        /sc minute ^
        /mo %INTERVAL% ^
        /rl highest ^
        /f
)

if %errorLevel% equ 0 (
    echo.
    echo ========================================
    echo  Task created successfully!
    echo ========================================
    echo.
    if "%TRIGGER_TYPE%"=="logon" (
        echo The VPN check will run at each logon.
    ) else (
        echo The VPN check will run every %INTERVAL% minutes.
    )
    echo.
    echo Script location: %PS_SCRIPT%
    echo Launcher: %VBS_LAUNCHER%
    echo.
    echo To test now, run:
    echo   schtasks /run /tn "VPN Connection Check"
    echo.
    echo To remove later, run:
    echo   schtasks /delete /tn "VPN Connection Check" /f
    echo.
) else (
    echo.
    echo ERROR: Failed to create scheduled task.
    echo.
)

pause
