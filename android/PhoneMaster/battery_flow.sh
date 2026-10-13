#!/data/data/com.termux/files/usr/bin/bash
# POCO Battery Flow: read-only battery/app diagnosis and safe recommendations.
set -u
OUTDIR="$HOME/phone-battery-reports"
mkdir -p "$OUTDIR"
STAMP="$(date +%Y%m%d-%H%M%S)"
OUT="$OUTDIR/battery-flow-$STAMP.txt"
exec > >(tee "$OUT") 2>&1

section() { printf '\n\n========== %s ==========\n' "$1"; }
run_capture() {
  label="$1"; shift
  echo "--- $label ---"
  "$@" 2>&1 || echo "[unavailable or permission-restricted: $label]"
}

echo "POCO BATTERY FLOW — DIAGNOSE FIRST, NO SETTINGS CHANGED"
echo "Timestamp: $(date)"
echo "Device: $(getprop ro.product.model 2>/dev/null) / $(getprop ro.product.device 2>/dev/null)"
echo "Build: $(getprop ro.build.display.id 2>/dev/null)"
echo "Report: $OUT"
echo "This flow does not force-stop apps, kill processes, alter app standby buckets, change governors, or disable notifications."

section "1. BATTERY STATUS (TERMUX:API FALLBACK)"
if command -v termux-battery-status >/dev/null 2>&1; then
  termux-battery-status 2>&1 || echo "Termux:API command failed; check the Termux:API companion app."
else
  echo "termux-battery-status is not installed."
  echo "To enable battery readings, install the Termux:API Android companion app from the same source as Termux, then run: pkg install termux-api"
fi
if command -v dumpsys >/dev/null 2>&1; then
  echo "--- Android dumpsys battery (may be permission-restricted) ---"
  dumpsys battery 2>&1 || true
else
  echo "dumpsys is unavailable in this Termux environment; this is expected without privileged shell access."
fi

section "2. BATTERY AND CHARGING TELEMETRY"
found_supply=0
for d in /sys/class/power_supply/*; do
  [ -e "$d" ] || continue
  found_supply=1
  echo "--- $d ---"
  for f in type present online status health capacity capacity_level technology temp voltage_now voltage_max current_now current_avg current_max charge_counter charge_full charge_full_design cycle_count input_current_limit usb_type; do
    if [ -r "$d/$f" ]; then printf '%s=' "$f"; cat "$d/$f" 2>/dev/null || echo "(read failed)"; fi
  done
done
[ "$found_supply" -eq 1 ] || echo "No readable power_supply entries were exposed to Termux."

section "3. ANDROID BATTERY STATISTICS"
if command -v dumpsys >/dev/null 2>&1; then
  echo "--- batterystats help / availability ---"
  dumpsys batterystats -h 2>&1 | head -n 70 || true
  echo "--- usage since last charge (output capped) ---"
  dumpsys batterystats --charged 2>&1 | head -n 500 || true
  echo "--- battery history / summary availability ---"
  dumpsys batterystats 2>&1 | grep -i -E 'Estimated power use|Uid |Wake lock|WakeLock|Partial Wakelock|screen on|mobile radio|wifi|bluetooth|Discharge|Battery History|Permission Denial|not allowed' | head -n 180 || true
else
  echo "dumpsys is unavailable; app-level system battery statistics cannot be collected here."
fi

section "4. APP INVENTORY (BEST-EFFORT)"
echo "Android often blocks package-manager shell commands from ordinary Termux."
if command -v pm >/dev/null 2>&1; then
  pm list packages -3 2>&1 || true
elif command -v cmd >/dev/null 2>&1; then
  cmd package list packages -3 2>&1 || true
else
  echo "Package manager CLI unavailable from this app UID."
fi
echo "For authoritative app-by-app battery attribution, open Android Settings > Battery > Battery usage."

section "5. SCREEN, CONNECTIVITY AND BACKGROUND CLUES"
echo "--- screen/display state ---"
if command -v dumpsys >/dev/null 2>&1; then
  dumpsys power 2>&1 | grep -i -E 'Display Power|Wakefulness|mWakefulness|mIsPowered|Battery Saver|Low Power|Doze' | head -n 100 || true
else
  echo "dumpsys unavailable from Termux; inspect Battery Saver and screen settings in Android Settings."
fi
echo "--- network interfaces (not traffic attribution) ---"
cat /proc/net/dev 2>/dev/null || true
echo "--- processes snapshot (Termux-compatible fallback) ---"
if ps -A >/dev/null 2>&1; then
  ps -A 2>&1 | head -n 60
else
  ps 2>&1 | head -n 60 || true
fi

section "6. SAFE BATTERY RECOMMENDATIONS"
cat <<'EOF'
Use the collected statistics to identify likely drains. These are conditional recommendations, not claims that an app is definitely draining the battery:
- If screen/display dominates: lower brightness, shorten screen timeout, and use a lower refresh rate if the ROM exposes that setting.
- If mobile radio or weak signal dominates: prefer stable Wi-Fi where appropriate; poor cellular reception can increase radio power use.
- If a specific app has high background use or repeated wake locks: review Android Settings > Battery > Battery usage for that app, update it, and consider Optimized/Restricted only if delayed sync/notifications are acceptable.
- If location scanning is unnecessary: limit location permission to while-in-use for apps that do not need background location.
- Turn off hotspot, Bluetooth, GPS/location scanning, or always-on display only when you do not need them.
- Use Android Battery Saver when you need extra runtime; verify behavior after enabling it in Settings or Quick Settings.
- Avoid “RAM booster” apps, frequent force-stopping, repeated cache clearing, disabling thermal controls, random build.prop tweaks, and forcing CPU governors. These can worsen battery, smoothness, or reliability.
- Battery aging or a hardware charging fault cannot be repaired by software. Since this phone reportedly charges when pressure is applied to its back, arrange physical inspection of the charging port/sub-board/flex/battery connector; do not press or bend the device to make it charge.
EOF

section "7. WHAT THIS SCRIPT CANNOT DO"
cat <<'EOF'
Termux normally lacks the privileged shell permissions required to reliably change global battery policies or set background restrictions for every installed app. This script intentionally does not try hidden settings writes, appops changes, force-stops, package disabling, or root commands.
Battery stats can be missing, incomplete, permission-denied, or reset by charging/rebooting. Termux:API provides battery level/status/temperature/health/current where supported, but it does not expose Android's full per-app battery attribution. Compare Android Settings > Battery > Battery usage and repeat observations over a representative period.
No settings were changed by this script.
EOF

section "DONE"
echo "Saved report: $OUT"
echo "Open Android Settings > Battery > Battery usage to cross-check app-specific usage. Share this report for interpretation."
