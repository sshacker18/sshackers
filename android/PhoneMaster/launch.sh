#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")" && pwd)"
command -v python >/dev/null 2>&1 || { echo "Python missing. Run: pkg install python"; exit 1; }
if ! command -v tmux >/dev/null 2>&1; then
  echo "tmux missing. Installing it..."
  pkg install tmux -y
fi
mkdir -p "$HOME/phone-master-reports"
if [ -n "${TMUX:-}" ]; then
  exec python "$ROOT/phone_master.py"
else
  exec tmux new-session -A -s phone-master "python '$ROOT/phone_master.py'"
fi
