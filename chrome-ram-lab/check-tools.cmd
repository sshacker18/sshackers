@echo off
setlocal
title Chrome RAM Lab - Preflight
echo.
echo ==========================================
echo   CHROME RAM LAB - TOOL CHECK
echo ==========================================
echo.

echo [1] Git
where git >nul 2>&1
if errorlevel 1 (
  echo Git: NOT FOUND in PATH
  echo If winget is available, run:
  echo   winget install --id Git.Git -e --source winget
) else (
  git --version
)

echo.
echo [2] Python (optional; this project does not need it)
where py >nul 2>&1
if errorlevel 1 (
  echo Python Launcher: not found
) else (
  py -V
)
where python >nul 2>&1
if errorlevel 1 (
  echo python.exe: not found in PATH
) else (
  python --version
)

echo.
echo [3] Chrome
set "CHROME="
if exist "%ProgramFiles%\Google\Chrome\Application\chrome.exe" set "CHROME=%ProgramFiles%\Google\Chrome\Application\chrome.exe"
if not defined CHROME if exist "%ProgramFiles(x86)%\Google\Chrome\Application\chrome.exe" set "CHROME=%ProgramFiles(x86)%\Google\Chrome\Application\chrome.exe"
if not defined CHROME if exist "%LOCALAPPDATA%\Google\Chrome\Application\chrome.exe" set "CHROME=%LOCALAPPDATA%\Google\Chrome\Application\chrome.exe"
if defined CHROME (
  echo Chrome found: "%CHROME%"
) else (
  echo Chrome was not found in the three standard installation paths.
  echo Try opening Chrome manually and check chrome://version
)

echo.
echo [4] Memory counters (raw values in KB)
wmic OS get TotalVisibleMemorySize,FreePhysicalMemory
if errorlevel 1 echo WMIC did not return memory counters on this Windows installation.

echo.
echo [5] Top 10 process working sets (MB)
powershell -NoProfile -Command "Get-Process | Sort-Object WorkingSet64 -Descending | Select-Object -First 10 ProcessName,Id,@{N='RAM_MB';E={[math]::Round($_.WorkingSet64/1MB)}} | Format-Table -AutoSize"
echo.
echo Preflight complete. No settings or processes were changed.
pause
