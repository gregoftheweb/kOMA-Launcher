#!/usr/bin/env bash
# notify.sh <title> [body] — small wrapper so every action reports the same way.
notify-send -a "kOMA Launcher" -i "${KOMA_ICON:-archlinux}" "$1" "${2:-}"
