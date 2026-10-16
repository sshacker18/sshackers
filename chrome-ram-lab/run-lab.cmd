@echo off
setlocal
title Chrome RAM Lab
:MENU
cls
echo.
echo  =========================================
echo     CHROME RAM LAB - SAFE CMD TOOLKIT
echo  =========================================
echo.
echo  1. Check Git, optional Python, Chrome, and RAM
echo  2. Capture a RAM snapshot to a log file
echo  3. Open Chrome Performance / Memory Saver
echo  4. Open Chrome Task Manager
echo  5. Read project README
echo  0. Exit
echo.
choice /C 123450 /N /M "Choose 1, 2, 3, 4, 5, or 0: "
if errorlevel 6 goto END
if errorlevel 5 goto README
if errorlevel 4 goto TASKMANAGER
if errorlevel 3 goto PERFORMANCE
if errorlevel 2 goto SNAPSHOT
if errorlevel 1 goto PREFLIGHT
goto MENU

:PREFLIGHT
call "%~dp0check-tools.cmd"
goto MENU

:SNAPSHOT
call "%~dp0ram-snapshot.cmd"
goto MENU

:PERFORMANCE
call "%~dp0open-chrome-performance.cmd"
echo.
pause
goto MENU

:TASKMANAGER
set "CHROME="
if exist "%ProgramFiles%\Google\Chrome\Application\chrome.exe" set "CHROME=%ProgramFiles%\Google\Chrome\Application\chrome.exe"
if not defined CHROME if exist "%ProgramFiles(x86)%\Google\Chrome\Application\chrome.exe" set "CHROME=%ProgramFiles(x86)%\Google\Chrome\Application\chrome.exe"
if not defined CHROME if exist "%LOCALAPPDATA%\Google\Chrome\Application\chrome.exe" set "CHROME=%LOCALAPPDATA%\Google\Chrome\Application\chrome.exe"
if defined CHROME (
  start "" "%CHROME%" "chrome://task-manager"
) else (
  echo Open Chrome and enter chrome://task-manager in its address bar.
)
echo This opens Chrome's own process/task list; it does not kill anything.
pause
goto MENU

:README
start "" notepad "%~dp0README.md"
goto MENU

:END
echo.
echo Chrome RAM Lab closed. No processes were terminated.
endlocal
