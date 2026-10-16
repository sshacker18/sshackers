@echo off
setlocal
title Laptop Performance Pilot
:MENU
cls
echo.
echo  =========================================
echo     LAPTOP PERFORMANCE PILOT
echo  =========================================
echo.
echo  1. Create full diagnostic report
echo  2. Open Chrome Memory Saver settings
echo  3. Open Windows Startup Apps settings
echo  4. Open Task Manager and Resource Monitor
echo  5. Open Windows Storage settings
echo  0. Exit
echo.
choice /C 123450 /N /M "Choose 1, 2, 3, 4, 5, or 0: "
if errorlevel 6 goto END
if errorlevel 5 goto STORAGE
if errorlevel 4 goto MONITORS
if errorlevel 3 goto STARTUP
if errorlevel 2 goto CHROME
if errorlevel 1 goto AUDIT
goto MENU

:AUDIT
call "%~dp0collect-audit.cmd"
goto MENU

:CHROME
start "" "chrome.exe" "chrome://settings/performance"
echo Opened Chrome Performance settings. No settings were changed automatically.
pause
goto MENU

:STARTUP
start "" "ms-settings:startupapps"
echo Review only apps you recognize. Avoid security and device-driver components.
pause
goto MENU

:MONITORS
start "" taskmgr.exe
start "" resmon.exe
goto MENU

:STORAGE
start "" "ms-settings:storagesense"
echo Review Windows Storage recommendations before deleting anything.
pause
goto MENU

:END
echo.
echo Laptop Performance Pilot closed. No processes were terminated.
endlocal
