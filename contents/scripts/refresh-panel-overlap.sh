#!/usr/bin/env bash
# Multiple panels share one check per KWin session. No polling or workspace switch.
set -euo pipefail
[[ -n ${XDG_RUNTIME_DIR:-} ]] || exit 0
exec 9>"$XDG_RUNTIME_DIR/koma-panel-overlap.lock"
flock -n 9 || exit 0
name=koma-launcher-panel-overlap-once
loaded=$(qdbus6 org.kde.KWin /Scripting org.kde.kwin.Scripting.isScriptLoaded "$name")
[[ $loaded != true ]] || exit 0
# A tiling script that started before the panel (Krohnkite) keeps tiling into the
# whole screen and moves windows back under the panel. Restart it so it measures
# the area the panel leaves free; KWin reloads enabled scripts on reconfigure.
kwin_script() { qdbus6 org.kde.KWin /Scripting "org.kde.kwin.Scripting.$1" "$2"; }
if [[ $(kwin_script isScriptLoaded krohnkite) == true ]]; then
  kwin_script unloadScript krohnkite >/dev/null
  qdbus6 org.kde.KWin /KWin reconfigure
  sleep 1
fi
script="$(cd "$(dirname "$0")" && pwd)/refresh-panel-overlap.js"
id=$(qdbus6 org.kde.KWin /Scripting org.kde.kwin.Scripting.loadScript "$script" "$name")
[[ $id =~ ^[0-9]+$ ]] || exit 1
qdbus6 org.kde.KWin "/Scripting/Script$id" org.kde.kwin.Script.run
