#!/usr/bin/env bash
# provider.sh <name> — print menu rows as "label<TAB>value<TAB>current".
case "$1" in
  themes)
    cur=$(kreadconfig6 --file kdeglobals --group KDE --key LookAndFeelPackage)
    plasma-apply-lookandfeel -l | while read -r id; do
      [ -n "$id" ] || continue
      meta=""; for d in ~/.local/share/plasma/look-and-feel /usr/share/plasma/look-and-feel; do [ -f "$d/$id/metadata.json" ] && meta="$d/$id/metadata.json" && break; done
      name=$( [ -n "$meta" ] && python3 -c 'import json,sys;print(json.load(open(sys.argv[1]))["KPlugin"]["Name"])' "$meta" 2>/dev/null )
      printf '%s\t%s\t%s\n' "${name:-$id}" "$id" "$cur"
    done ;;
  colors)
    plasma-apply-colorscheme --list-schemes | sed -n 's/^ \* //p' | while read -r line; do
      name=${line% (current color scheme)}; cur=""; [ "$name" != "$line" ] && cur=$name
      printf '%s\t%s\t%s\n' "$name" "$name" "$cur"
    done ;;
  cursors)
    plasma-apply-cursortheme --list-themes | sed -n 's/^ \* //p' | while read -r line; do
      id=$(sed -n 's/.*\[\(.*\)\].*/\1/p' <<<"$line"); name=${line%% \[*}; cur=""; [[ $line == *"(Current"* ]] && cur=$id
      printf '%s\t%s\t%s\n' "$name" "$id" "$cur"
    done ;;
  icons)
    cur=$(kreadconfig6 --file kdeglobals --group Icons --key Theme)
    for d in /usr/share/icons/* ~/.local/share/icons/*; do
      [ -f "$d/index.theme" ] && grep -q '^Directories' "$d/index.theme" || continue
      id=$(basename "$d"); [ "$id" = hicolor ] && continue
      name=$(sed -n 's/^Name=//p' "$d/index.theme" | head -1)
      printf '%s\t%s\t%s\n' "${name:-$id}" "$id" "$cur"
    done ;;
  wallpapers)
    for d in ~/Pictures/Wallpapers ~/.local/share/wallpapers /mnt/devplex/kde-desktop/wallpapers; do
      [ -d "$d" ] && find "$d" -maxdepth 2 -type f \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.webp' \)
    done | sort | while read -r f; do printf '%s\t%s\t\n' "$(basename "${f%.*}")" "$f"; done ;;
  keybindings)
    # Active global shortcuts from kglobalshortcutsrc: "<keys>  <action>".
    # App launchers ([services][x.desktop] _launch=) are named from their
    # .desktop file; Krohnkite's actions are shown as "Tiling: ...".
    awk -F= '
      /^\[/ { comp=substr($0,2,length($0)-2); next }
      /^_k_friendly_name/ || !/=/ { next }
      # KConfig list escaping: \\\\ is a literal backslash, \\, a literal comma.
      { val=substr($0, index($0,"=")+1)
        gsub(/\\\\\\\\/, "\002", val); gsub(/\\\\,/, "\001", val)
        split(val, v, ","); keys=v[1]; name=v[3]
        if (keys=="" || keys=="none") next
        gsub(/\001/, ",", keys); gsub(/\002/, "\\", keys); gsub(/\\t/, "  /  ", keys)
        sub(/^Krohnkite: /, "Tiling: ", name)
        if (name=="" && $1=="_launch" && comp ~ /^services\]\[/) name="@" substr(comp, 11)
        if (name=="") name=$1
        printf "%s\t%s\t%s\n", keys, name, comp "/" $1 }' ~/.config/kglobalshortcutsrc |
    while IFS=$'\t' read -r keys name id; do
      if [[ $name == @* ]]; then
        desktop=${name#@}; name=$desktop
        for d in ~/.local/share/applications /usr/share/applications; do
          [ -f "$d/$desktop" ] && name=$(sed -n 's/^Name=//p' "$d/$desktop" | head -1) && break
        done
        name="Launch: ${name:-$desktop}"
      fi
      printf '%-28s %s\t%s\t\n' "$keys" "$name" "$id"
    done | sort -f ;;
esac
