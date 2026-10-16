@echo off
setlocal
title Laptop Performance Pilot - Audit
set "LOGDIR=%~dp0logs"
if not exist "%LOGDIR%" mkdir "%LOGDIR%"

set "STAMP="
for /f "tokens=2 delims==" %%I in ('wmic os get LocalDateTime /value 2^>nul ^| find "="') do set "DT=%%I"
if defined DT (
  set "STAMP=%DT:~0,8%-%DT:~8,6%"
) else (
  set "STAMP=%RANDOM%-%RANDOM%"
)
set "LOG=%LOGDIR%\laptop-audit-%STAMP%.txt"

> "%LOG%" echo LAPTOP PERFORMANCE PILOT - DIAGNOSTIC REPORT
>>"%LOG%" echo Date: %DATE%  Time: %TIME%
>>"%LOG%" echo Computer: %COMPUTERNAME%
>>"%LOG%" echo.
>>"%LOG%" echo === OPERATING SYSTEM AND MEMORY ===
>>"%LOG%" powershell -NoProfile -Command "$os=Get-CimInstance Win32_OperatingSystem; 'OS: '+$os.Caption; 'Version/build: '+$os.Version+' / '+$os.BuildNumber; 'Visible RAM: {0:N2} GiB' -f ($os.TotalVisibleMemorySize/1MB); 'Free physical memory: {0:N0} MiB' -f ($os.FreePhysicalMemory/1024); 'Free memory percentage of visible RAM: {0:N1}%%' -f (100*$os.FreePhysicalMemory/$os.TotalVisibleMemorySize)"
>>"%LOG%" echo.
>>"%LOG%" echo === CPU ===
>>"%LOG%" powershell -NoProfile -Command "Get-CimInstance Win32_Processor | Select-Object Name,NumberOfCores,NumberOfLogicalProcessors,LoadPercentage,MaxClockSpeed | Format-List"
>>"%LOG%" echo.
>>"%LOG%" echo === TOP 15 PROCESS WORKING SETS ===
>>"%LOG%" powershell -NoProfile -Command "Get-Process | Sort-Object WorkingSet64 -Descending | Select-Object -First 15 ProcessName,Id,@{N='RAM_MB';E={[math]::Round($_.WorkingSet64/1MB)}} | Format-Table -AutoSize"
>>"%LOG%" echo.
>>"%LOG%" echo === CHROME SUMMARY ===
>>"%LOG%" powershell -NoProfile -Command "$c=@(Get-Process chrome -ErrorAction SilentlyContinue); if($c.Count -gt 0) { 'Chrome process count: '+$c.Count; 'Combined Chrome working set: {0:N0} MB' -f ((($c | Measure-Object WorkingSet64 -Sum).Sum)/1MB) } else { 'Chrome is not running.' }"
>>"%LOG%" echo.
>>"%LOG%" echo === STARTUP REGISTRY ENTRIES ===
>>"%LOG%" powershell -NoProfile -Command "$paths=@('HKCU:\Software\Microsoft\Windows\CurrentVersion\Run','HKLM:\Software\Microsoft\Windows\CurrentVersion\Run','HKLM:\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Run'); foreach($p in $paths){ if(Test-Path $p){ '--- '+$p; Get-ItemProperty $p | Select-Object * -ExcludeProperty PSPath,PSParentPath,PSChildName,PSDrive,PSProvider | Format-List } }"
>>"%LOG%" echo.
>>"%LOG%" echo === FIXED DISKS ===
>>"%LOG%" powershell -NoProfile -Command "Get-CimInstance Win32_LogicalDisk -Filter 'DriveType=3' | Select-Object DeviceID,@{N='Size_GB';E={[math]::Round($_.Size/1GB,1)}},@{N='Free_GB';E={[math]::Round($_.FreeSpace/1GB,1)}} | Format-Table -AutoSize"
>>"%LOG%" echo.
>>"%LOG%" echo === CHROME MEMORY SETTINGS ===
>>"%LOG%" echo Review manually at chrome://settings/performance. No setting was changed by this report.
>>"%LOG%" echo.
>>"%LOG%" echo === SAFETY ===
>>"%LOG%" echo This report is read-only. It does not terminate processes or change system settings.

echo.
echo Diagnostic report saved to:
echo "%LOG%"
echo.
type "%LOG%"
echo.
echo Audit complete. No processes were stopped and no settings were changed.
pause
