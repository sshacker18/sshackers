#!/data/data/com.termux/files/usr/bin/bash
# Prime Video Ad Filter Helper
# Device target: Termux on Android / LineageOS. No root, no app killing,
# no hosts-file edits, no data deletion. This does NOT guarantee Prime Video ad removal.

set -u
APP_NAME="Prime Video Ad Filter Helper"

pause() {
  printf '\nPress Enter to return to the menu...'
  read -r _
}

header() {
  clear 2>/dev/null || true
  printf '========== %s ==========\n' "$APP_NAME"
  printf 'Device: %s | Android: %s\n' "${MODEL:-Android}" "${ANDROID_VERSION:-unknown}"
  printf 'Mode: non-root, reversible, no data deletion\n\n'
}

open_private_dns_settings() {
  if command -v am >/dev/null 2>&1; then
    am start -a android.settings.PRIVATE_DNS_SETTINGS >/dev/null 2>&1 && {
      echo "Opened Android Private DNS settings."
      echo "If the screen did not open, navigate manually: Settings > Network & internet > Private DNS."
    } || {
      echo "Could not open settings automatically."
      echo "Open Settings > Network & internet > Private DNS manually."
    }
  else
    echo "The Android activity launcher (am) is not available in this Termux session."
    echo "Open Settings > Network & internet > Private DNS manually."
  fi
  echo
  echo "Optional DNS provider hostname to try: dns.adguard-dns.com"
  echo "This may block some domain-based ads/trackers, but it will NOT reliably remove"
  echo "Prime Video in-stream ads. Some apps or networks may stop working with filtering."
  echo "To undo: set Private DNS back to Automatic."
}

connectivity_check() {
  echo "Checking basic HTTPS reachability..."
  if command -v curl >/dev/null 2>&1; then
    if curl --connect-timeout 5 --max-time 10 -sS -o /dev/null https://www.primevideo.com; then
      echo "Prime Video website HTTPS reachable."
    else
      echo "Prime Video HTTPS check failed; DNS, network, VPN, or service may be responsible."
    fi
    if curl --connect-timeout 5 --max-time 10 -sS -o /dev/null https://www.google.com; then
      echo "General HTTPS connectivity reachable."
    else
      echo "General HTTPS check failed."
    fi
  else
    echo "curl is not installed. Install it with: pkg install curl"
  fi
  echo "Note: this checks connectivity only; it does not prove whether ads are blocked."
}

show_limits() {
  cat <<'INFO'
What this helper can and cannot do
- Android Private DNS filtering may block some ad/tracker domains across apps.
- Prime Video can serve ads from infrastructure also used for playback, so DNS
  filtering cannot reliably block all video ads and may break streaming.
- This script does not modify Prime Video, bypass subscriptions, install a VPN,
  alter system files, kill processes, or delete files.
- For guaranteed removal of most on-demand ads, use Prime Video's official Ad Free
  option where available. Live/sports/ad-supported content and promotional trailers
  may still contain ads.
INFO
  echo
  echo "Official information: https://www.primevideo.com/help?nodeId=TR7P4YDu3J97ETYJ7S"
}

while true; do
  header
  cat <<'MENU'
1) Open Private DNS settings (manual, reversible setup)
2) Test Prime Video and general HTTPS connectivity
3) Explain limitations and official ad-free option
4) Exit
MENU
  printf '\nChoose [1-4]: '
  read -r choice
  case "$choice" in
    1) open_private_dns_settings; pause ;;
    2) connectivity_check; pause ;;
    3) show_limits; pause ;;
    4) echo "Exiting. No system changes were made by this script."; exit 0 ;;
    *) echo "Invalid choice. Enter 1, 2, 3, or 4."; sleep 1 ;;
  esac
done
