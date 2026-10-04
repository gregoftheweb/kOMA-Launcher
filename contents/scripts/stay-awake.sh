#!/usr/bin/env bash
# stay-awake.sh [toggle|status] — block sleep and screen locking via KDE's own
# inhibitor (shows up in the battery/power applet like any other inhibition).
dir=$(dirname "$0"); pat='kde-inhibit --power --screenSaver sleep infinity'
case "${1:-toggle}" in
  status) pgrep -f "$pat" >/dev/null ;;
  toggle)
    if pgrep -f "$pat" >/dev/null; then pkill -f "$pat"; bash "$dir/notify.sh" "Stay awake: off"
    else setsid -f kde-inhibit --power --screenSaver sleep infinity >/dev/null 2>&1; KOMA_ICON=system-suspend-inhibited bash "$dir/notify.sh" "Stay awake: on" "Sleep and screen locking are blocked"; fi ;;
esac
