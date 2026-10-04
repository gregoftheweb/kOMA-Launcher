#!/usr/bin/env bash
# Select a screen region, read its text with tesseract, copy it.
dir=$(dirname "$0"); f=$(mktemp --suffix=.png)
trap 'rm -f "$f"' EXIT
spectacle -r -b -n -o "$f" >/dev/null 2>&1
[ -s "$f" ] || exit 0
text=$(tesseract "$f" - 2>/dev/null | sed -e 's/[[:space:]]*$//')
[ -n "$text" ] || { bash "$dir/notify.sh" "No text found"; exit 0; }
bash "$dir/clip.sh" "$text"
KOMA_ICON=edit-copy bash "$dir/notify.sh" "Text copied" "$(head -c 120 <<<"$text")"
