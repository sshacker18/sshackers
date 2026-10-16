@echo off
setlocal
title Chrome RAM Lab - Snapshot
set "LOGDIR=%~dp0logs"
if not exist "%LOGDIR%" mkdir "%LOGDIR%"

set "DT="
for /f "tokens=2 delims==" %%I in ('wmic os get LocalDateTime /value 2^>nul ^| find "="') do set "DT=%%I"
if defined DT (
  set "STAMP=%DT:~0,8%-%DT:~8,6%"
) else (
  set "STAMP=%RANDOM%-%RANDOM%"
)
set "LOG=%LOGDIR%\snapshot-%STAMP%.txt"

> "%LOG%" echo CHROME RAM LAB - SNAPSHOT
>>"%LOG%" echo Date: %DATE%  Time: %TIME%
>>"%LOG%" echo Computer: %COMPUTERNAME%
>>"%LOG%" echo.
>>"%LOG%" echo === OS MEMORY COUNTERS (KB) ===
>>"%LOG%" wmic OS get Caption,OSArchitecture,TotalVisibleMemorySize,FreePhysicalMemory /value
>>"%LOG%" echo.
>>"%LOG%" echo === TOP 15 PROCESS WORKING SETS (MB) ===
>>"%LOG%" powershell -NoProfile -Command "Get-Process | Sort-Object WorkingSet64 -Descending | Select-Object -First 15 ProcessName,Id,@{N='RAM_MB';E={[math]::Round($_.WorkingSet64/1MB)}} | Format-Table -AutoSize"
>>"%LOG%" echo.
>>"%LOG%" echo === CHROME PROCESS SUMMARY ===
>>"%LOG%" powershell -NoProfile -Command "$c=@(Get-Process chrome -ErrorAction SilentlyContinue); if($c.Count -gt 0) { 'Chrome process count: ' + $c.Count; 'Combined Chrome working set: {0:N0} MB' -f ((($c | Measure-Object WorkingSet64 -Sum).Sum)/1MB) } else { 'Chrome is not running.' }"
>>"%LOG%" echo.
>>"%LOG%" echo === CHROME TASK LIST ===
>>"%LOG%" tasklist /FI "IMAGENAME eq chrome.exe"

echo.
echo Snapshot saved to:
echo "%LOG%"
echo.
type "%LOG%"
echo.
echo Report complete. No process was stopped and no setting was changed.
pause
