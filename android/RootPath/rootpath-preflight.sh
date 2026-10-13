#!/data/data/com.termux/files/usr/bin/bash
# RootPath: read-only Android rooting preflight.
# This script DOES NOT root, patch, download, or flash anything.
set -u

out="${HOME}/rootpath-preflight-$(date +%Y%m%d-%H%M%S).txt"

{
  echo "RootPath preflight report"
  echo "Generated: $(date 2>/dev/null || echo unknown)"
  echo
  echo "== Device identity =="
  for p in ro.product.model ro.product.device ro.product.vendor.device ro.product.system.device ro.build.product; do
    printf '%s: %s\n' "$p" "$(getprop "$p" 2>/dev/null)"
  done
  echo
  echo "== Android / ROM =="
  for p in ro.build.version.release ro.build.version.sdk ro.build.display.id ro.build.fingerprint ro.system.build.fingerprint ro.vendor.build.fingerprint; do
    printf '%s: %s\n' "$p" "$(getprop "$p" 2>/dev/null)"
  done
  echo
  echo "== Boot / verification properties (informational only) =="
  for p in ro.boot.flash.locked ro.boot.verifiedbootstate ro.build.ab_update ro.build.system_root_image; do
    printf '%s: %s\n' "$p" "$(getprop "$p" 2>/dev/null)"
  done
  echo
  echo "== Kernel / architecture =="
  uname -a 2>&1
  getprop ro.product.cpu.abi 2>/dev/null
  echo
  echo "== Storage =="
  df -h "$HOME" /sdcard 2>&1
  echo
  echo "== Root manager presence (not proof of root) =="
  pm list packages 2>/dev/null | grep -Ei 'magisk|kernelsu|apatch' || echo "No known root-manager package found."
  echo
  echo "== su command check (not proof of root) =="
  command -v su 2>/dev/null || true
  echo
  echo "== Safety assessment =="
  product="$(getprop ro.product.device 2>/dev/null)"
  vendor="$(getprop ro.product.vendor.device 2>/dev/null)"
  build_product="$(getprop ro.build.product 2>/dev/null)"
  if [ "$product" != "$build_product" ] || { [ -n "$vendor" ] && [ "$vendor" != "$build_product" ]; }; then
    echo "STOP: device properties disagree. Do not patch or flash an image until the exact device/ROM package is verified."
  else
    echo "Properties did not show the specific mismatch check. This is not proof that any image is compatible."
  fi
  echo
  echo "This is a read-only report. No partition was read or written, and no changes were made."
} | tee "$out"

echo
echo "Saved report: $out"
