@echo off
setlocal
title Chrome RAM Lab - Chrome Performance
set "CHROME="
if exist "%ProgramFiles%\Google\Chrome\Application\chrome.exe" set "CHROME=%ProgramFiles%\Google\Chrome\Application\chrome.exe"
if not defined CHROME if exist "%ProgramFiles(x86)%\Google\Chrome\Application\chrome.exe" set "CHROME=%ProgramFiles(x86)%\Google\Chrome\Application\chrome.exe"
if not defined CHROME if exist "%LOCALAPPDATA%\Google\Chrome\Application\chrome.exe" set "CHROME=%LOCALAPPDATA%\Google\Chrome\Application\chrome.exe"

if not defined CHROME (
  echo Chrome was not found in the three standard installation paths.
  echo Open Chrome manually and type this into its address bar:
  echo   chrome://settings/performance
  echo Then press Enter. Do not type that URL directly as a CMD command.
  pause
  exit /b 1
)

echo Opening Chrome Performance settings...
start "" "%CHROME%" "chrome://settings/performance"
echo.
echo Recommended first test: enable Memory Saver and choose Balanced.
echo If you still hit memory pressure, compare Maximum, noting that tabs may reload more often.
echo This script opens the page only; it does not change settings for you.
