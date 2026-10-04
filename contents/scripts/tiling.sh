#!/usr/bin/env bash
# tiling.sh toggle|status — turn the Krohnkite tiling script on or off.
cur=$(kreadconfig6 --file kwinrc --group Plugins --key krohnkiteEnabled --default false)
case "${1:-toggle}" in
  status) [ "$cur" = true ] ;;
  toggle)
    if [ "$cur" = true ]; then
      kwriteconfig6 --file kwinrc --group Plugins --key krohnkiteEnabled false
      qdbus6 org.kde.KWin /Scripting org.kde.kwin.Scripting.unloadScript krohnkite >/dev/null 2>&1
    else
      kwriteconfig6 --file kwinrc --group Plugins --key krohnkiteEnabled true
    fi
    qdbus6 org.kde.KWin /KWin reconfigure >/dev/null 2>&1
    qdbus6 org.kde.KWin /Scripting org.kde.kwin.Scripting.start >/dev/null 2>&1 ;;
esac
