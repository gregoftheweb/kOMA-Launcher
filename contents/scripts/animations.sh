#!/usr/bin/env bash
# animations.sh toggle|status — KDE's global animation speed (0 = off).
cur=$(kreadconfig6 --file kdeglobals --group KDE --key AnimationDurationFactor --default 1)
case "${1:-toggle}" in
  status) [ "$cur" != 0 ] ;;
  toggle)
    [ "$cur" = 0 ] && new=1 || new=0
    kwriteconfig6 --file kdeglobals --group KDE --key AnimationDurationFactor "$new"
    qdbus6 org.kde.KWin /KWin reconfigure >/dev/null 2>&1 ;;
esac
