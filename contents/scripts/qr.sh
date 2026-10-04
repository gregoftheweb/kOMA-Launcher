#!/usr/bin/env bash
# Select a screen region, decode a QR code in it, copy the contents.
dir=$(dirname "$0"); f=$(mktemp --suffix=.png)
trap 'rm -f "$f"' EXIT
spectacle -r -b -n -o "$f" >/dev/null 2>&1
[ -s "$f" ] || exit 0
text=$(zbarimg -q --raw "$f" 2>/dev/null)
[ -n "$text" ] || { bash "$dir/notify.sh" "No QR code found"; exit 0; }
bash "$dir/clip.sh" "$text"
KOMA_ICON=edit-copy bash "$dir/notify.sh" "QR code copied" "$(head -c 120 <<<"$text")"
