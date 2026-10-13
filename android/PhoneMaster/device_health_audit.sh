#!/data/data/com.termux/files/usr/bin/bash
# Read-only POCO/Android charging and performance audit. No root, no settings changed.
set -u
OUTDIR="$HOME/phone-health-reports"
mkdir -p "$OUTDIR"
STAMP="$(date +%Y%m%d-%H%M%S)"
OUT="$OUTDIR/health-audit-$STAMP.txt"
exec > >(tee "$OUT") 2>&1

section() { printf '\n\n========== %s ==========\n' "$1"; }
echo "POCO PHONE HEALTH AUDIT — READ ONLY"
echo "Timestamp: $(date)"
echo "Device: $(getprop ro.product.model 2>/dev/null) / $(getprop ro.product.device 2>/dev/null)"
echo "Build: $(getprop ro.build.display.id 2>/dev/null)"
echo "Kernel: $(uname -a)"
echo "Report: $OUT"
echo "This script does not root, change settings, kill processes, or write to power-supply sysfs."

section "1. ANDROID BATTERY SERVICE"
command -v dumpsys >/dev/null 2>&1 && dumpsys battery || echo "dumpsys unavailable"

section "2. KERNEL POWER-SUPPLY TELEMETRY"
FOUND=0
for d in /sys/class/power_supply/*; do
  [ -e "$d" ] || continue
  FOUND=1
  echo "--- $d ---"
  for f in type present online status health capacity capacity_level technology temp voltage_now voltage_max current_now current_avg current_max charge_counter charge_full charge_full_design cycle_count input_current_limit usb_type; do
    if [ -r "$d/$f" ]; then printf '%s=' "$f"; cat "$d/$f" 2>/dev/null || echo "(read failed)"; fi
  done
done
[ "$FOUND" -eq 1 ] || echo "No readable power_supply entries; Android permissions/kernel may restrict access."

section "3. USB / CONNECTIVITY CLUES"
for p in /sys/class/power_supply/usb/online /sys/class/power_supply/usb/status /sys/class/power_supply/usb/type /sys/class/typec/port0/power_role /sys/class/typec/port0/data_role /sys/class/typec/port0/port_type /sys/class/usb_role/*/role; do
  [ -r "$p" ] && { printf '%s=' "$p"; cat "$p" 2>/dev/null || true; }
done
echo "USB/Type-C sysfs nodes may be absent on this kernel; absence does not prove a fault."

section "4. THERMAL SNAPSHOT"
for d in /sys/class/thermal/thermal_zone*; do
  [ -r "$d/temp" ] || continue
  typ="unknown"; [ -r "$d/type" ] && typ="$(cat "$d/type" 2>/dev/null)"
  printf '%s: %s\n' "$typ" "$(cat "$d/temp" 2>/dev/null)"
done
echo "Thermal readings can be millidegrees Celsius, but vendor sensors vary."

section "5. PERFORMANCE BASELINE"
echo "-- memory --"
grep -E 'MemTotal|MemAvailable|MemFree|Cached|SwapTotal|SwapFree' /proc/meminfo 2>/dev/null || true
echo "-- storage --"
df -h "$HOME" /storage/emulated/0 2>&1 || true
echo "-- CPU policy/governor (read-only) --"
for f in /sys/devices/system/cpu/cpufreq/policy*/scaling_governor /sys/devices/system/cpu/cpufreq/policy*/scaling_cur_freq /sys/devices/system/cpu/cpufreq/policy*/scaling_min_freq /sys/devices/system/cpu/cpufreq/policy*/scaling_max_freq; do
  [ -r "$f" ] && { printf '%s=' "$f"; cat "$f" 2>/dev/null || true; }
done
echo "-- load --"; uptime 2>&1 || true
echo "-- processes (limited view) --"
ps -A -o PID,USER,STAT,%CPU,%MEM,ARGS 2>&1 | head -n 45 || ps -A 2>&1 | head -n 45

section "6. SHORT CHARGING OBSERVATION"
echo "Capturing up to 6 readings, 10 seconds apart. Do not press, bend, or move the phone/connector to provoke a fault."
echo "If you suspect the port is loose, unplug it and stop here rather than continuing the observation."
i=1
while [ "$i" -le 6 ]; do
  echo "--- sample $i / $(date +%H:%M:%S) ---"
  if command -v dumpsys >/dev/null 2>&1; then dumpsys battery 2>/dev/null | grep -E 'AC powered|USB powered|Wireless powered|status:|health:|level:|voltage:|temperature:' || true; fi
  for d in /sys/class/power_supply/*; do
    [ -d "$d" ] || continue
    vals=""
    for f in online status current_now voltage_now temp capacity; do
      if [ -r "$d/$f" ]; then vals="$vals $f=$(cat "$d/$f" 2>/dev/null)"; fi
    done
    [ -n "$vals" ] && echo "$(basename "$d"):$vals"
  done
  [ "$i" -eq 6 ] || sleep 10
  i=$((i+1))
done

section "7. INTERPRETATION / LIMITATIONS"
cat <<'EOF'
This report can show whether Android detects external power and whether reported current/voltage/status change over time.
It CANNOT identify a specific broken wire, solder joint, USB-C pin, charging IC, battery connector, or board trace.
A current reading of zero, missing sysfs fields, or odd units can be a kernel/vendor reporting limitation; do not diagnose from one value alone.
If charging starts/stops with ordinary cable contact or slight movement, stop manipulating it and ask a repair technician to inspect the USB-C port, charging sub-board, interconnect flex/connectors, battery connector, and charging circuitry.
Do not open, puncture, bend, heat, short, or probe the lithium battery. Do not use metal tools in the USB port.
No CPU governor, thermal, charging, battery, or kernel settings were changed.
EOF
section "DONE"
echo "Saved report: $OUT"
echo "Share the report text for interpretation. Redact any personal details before sharing."
