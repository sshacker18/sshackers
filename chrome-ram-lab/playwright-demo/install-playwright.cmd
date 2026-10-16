@echo off
setlocal
cd /d "%~dp0"
title Chrome RAM Lab - Playwright Setup

echo.
echo ==========================================
echo   PLAYWRIGHT DEMO SETUP
echo ==========================================
echo.

where py >nul 2>&1
if errorlevel 1 (
  echo Python Launcher (py.exe) was not found.
  echo Install Python 3.13 with Windows Package Manager:
  echo   winget install --id Python.Python.3.13 -e --source winget
  echo Then close and reopen CMD and run this script again.
  pause
  exit /b 1
)

py -3 --version
if errorlevel 1 (
  echo Python 3 was not found through the Python launcher.
  echo Install Python 3.13, then retry.
  pause
  exit /b 1
)

if not exist ".venv\Scripts\python.exe" (
  echo Creating an isolated virtual environment...
  py -3 -m venv .venv
  if errorlevel 1 (
    echo Could not create the virtual environment.
    pause
    exit /b 1
  )
)

echo.
echo Updating pip in the local virtual environment...
".venv\Scripts\python.exe" -m pip install --upgrade pip
if errorlevel 1 goto FAILED

echo.
echo Installing pinned dependencies from requirements.txt...
".venv\Scripts\python.exe" -m pip install -r requirements.txt
if errorlevel 1 goto FAILED

echo.
echo Downloading Playwright Chromium only...
".venv\Scripts\python.exe" -m playwright install chromium
if errorlevel 1 goto FAILED

echo.
echo Setup complete. To run the smoke test, execute:
echo   run-smoke-test.cmd
echo.
echo Note: browser binaries use additional disk space.
pause
exit /b 0

:FAILED
echo.
echo Setup did not complete. Read the error above and retry after resolving it.
pause
exit /b 1
