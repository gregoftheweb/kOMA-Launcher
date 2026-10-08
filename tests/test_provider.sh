#!/usr/bin/env bash
# Tests for contents/scripts/provider.sh against a temporary HOME.
set -uo pipefail
here=$(cd "$(dirname "$0")" && pwd)
provider="$here/../contents/scripts/provider.sh"
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
fails=0 passes=0

check() { # name, condition...
  local name=$1
  shift
  if "$@"; then passes=$((passes + 1)); else
    echo "FAIL: $name"
    fails=$((fails + 1))
  fi
}

lacks() { # text, pattern: the text has no line matching pattern
  ! grep -q "$2" <<<"$1"
}

export HOME="$tmp/home" XDG_DATA_HOME="$tmp/home/.local/share" XDG_CONFIG_HOME="$tmp/home/.config"
walls="$XDG_DATA_HOME/wallpapers"
mkdir -p "$walls/Lightcycles/contents/images" "$walls/Unnamed/contents/images" "$walls/NotAPackage" "$HOME/Pictures/Wallpapers"
cat >"$walls/Lightcycles/metadata.json" <<'JSON'
{ "KPlugin": { "Authors": [{ "Name": "Someone" }], "Id": "Lightcycles", "Name": "kOMA Lightcycles" } }
JSON
echo '{ "KPlugin": { "Id": "Unnamed" } }' >"$walls/Unnamed/metadata.json"
touch "$walls/Lightcycles/contents/images/1920x1080.png" "$walls/Unnamed/contents/images/1280x720.jpg"
echo '{}' >"$walls/NotAPackage/metadata.json"
touch "$HOME/Pictures/Wallpapers/beach.jpg" "$walls/loose.png"

out=$(bash "$provider" wallpapers)
check "a package is listed by its metadata name" grep -qxF "kOMA Lightcycles	$walls/Lightcycles	" <<<"$out"
check "the author's name is not mistaken for the package name" lacks "$out" "^Someone"
check "a package without a name falls back to its folder" grep -qxF "Unnamed	$walls/Unnamed	" <<<"$out"
check "a folder without contents/images is not a package" lacks "$out" "NotAPackage"
check "package images are not listed one by one" lacks "$out" "1920x1080"
check "loose images are still listed" grep -qxF "beach	$HOME/Pictures/Wallpapers/beach.jpg	" <<<"$out"
check "loose images in the wallpapers folder are listed" grep -qxF "loose	$walls/loose.png	" <<<"$out"
check "entries are sorted by name" test "$(cut -f1 <<<"$out" | tr '\n' ,)" = "beach,kOMA Lightcycles,loose,Unnamed,"

echo "komalauncher provider: $passes passed, $fails failed"
[ "$fails" -eq 0 ]
