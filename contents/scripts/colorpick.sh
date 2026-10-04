#!/usr/bin/env bash
# Pick a color anywhere on screen with KWin's picker; copy it as #RRGGBB.
dir=$(dirname "$0")
raw=$(qdbus6 --literal org.kde.KWin /ColorPicker org.kde.kwin.ColorPicker.pick 2>/dev/null) || exit 0
n=$(grep -oE '[0-9]+' <<<"$raw" | tail -1)
[ -n "$n" ] || exit 0
hex=$(printf '#%06X' $(( n & 0xFFFFFF )))
bash "$dir/clip.sh" "$hex"
KOMA_ICON=color-picker bash "$dir/notify.sh" "Color copied" "$hex"
