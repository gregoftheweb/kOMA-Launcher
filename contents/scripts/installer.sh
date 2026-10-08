#!/usr/bin/env bash
set -euo pipefail
installer="${KOMA_INSTALLER_ROOT:-${XDG_DATA_HOME:-$HOME/.local/share}/koma/installer}/install.sh"
if [[ ${1:-} == --available ]]; then
    [[ -f "$installer" && -f "$(dirname "$installer")/setup/installer/app.py" ]]
    exit $?
fi
if [[ ! -f "$installer" ]]; then
    notify-send 'kOMA Installer' 'The installer is not installed. Install the kOMA desktop bundle first.'
    exit 1
fi
exec konsole --separate -e bash "$installer"
