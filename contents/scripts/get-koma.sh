#!/usr/bin/env bash
# "Get the Complete kOMA Theme": explain, ask, then run the kOMA bootstrap from the
# theme's latest GitHub release. The bootstrap verifies the bundle and opens the installer.
set -uo pipefail
url="${KOMA_BOOTSTRAP_URL:-https://github.com/gregoftheweb/kOMA-desktop-theme/releases/latest/download/get-koma.sh}"

cat <<EOF

  kOMA — the complete desktop

  This downloads the kOMA installer from GitHub:
    $url

  The installer shows every change and asks before it applies anything.
  Your current settings are backed up and can be restored.

EOF
read -r -p "  Press Enter to continue, or Ctrl+C to cancel. " _

script=$(mktemp)
trap 'rm -f "$script"' EXIT
if ! curl -fsSL "$url" -o "$script"; then
  echo
  echo "  Could not download the installer. Check your connection and try again."
  read -r -p "  Press Enter to close. " _
  exit 1
fi
bash "$script"
status=$?
if [ "$status" -ne 0 ]; then
  echo
  read -r -p "  The installer stopped (exit $status). Press Enter to close. " _
fi
exit "$status"
