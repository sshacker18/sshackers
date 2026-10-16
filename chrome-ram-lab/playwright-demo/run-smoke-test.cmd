@echo off
setlocal
cd /d "%~dp0"
title Chrome RAM Lab - Playwright Smoke Test

if not exist ".venv\Scripts\python.exe" (
  echo Playwright environment not found.
  echo Run install-playwright.cmd first.
  pause
  exit /b 1
)

".venv\Scripts\python.exe" smoke_test.py
if errorlevel 1 (
  echo.
  echo Smoke test failed. Review the error above.
  pause
  exit /b 1
)

echo.
echo Smoke test passed.
pause
