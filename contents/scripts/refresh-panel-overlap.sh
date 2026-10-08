#!/usr/bin/env bash
# Multiple panels share one check per KWin session. No polling or workspace switch.
set -euo pipefail
[[ -n ${XDG_RUNTIME_DIR:-} ]] || exit 0
exec 9>"$XDG_RUNTIME_DIR/koma-panel-overlap.lock"
flock -n 9 || exit 0
name=koma-launcher-panel-overlap-once
loaded=$(qdbus6 org.kde.KWin /Scripting org.kde.kwin.Scripting.isScriptLoaded "$name")
[[ $loaded != true ]] || exit 0
script="$(cd "$(dirname "$0")" && pwd)/refresh-panel-overlap.js"
id=$(qdbus6 org.kde.KWin /Scripting org.kde.kwin.Scripting.loadScript "$script" "$name")
[[ $id =~ ^[0-9]+$ ]] || exit 1
qdbus6 org.kde.KWin "/Scripting/Script$id" org.kde.kwin.Script.run
