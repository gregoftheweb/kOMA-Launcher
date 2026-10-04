#!/usr/bin/env bash
# panels.sh autohide|status|top|bottom — act on every panel at once.
eval_js() { qdbus6 org.kde.plasmashell /PlasmaShell org.kde.PlasmaShell.evaluateScript "$1"; }
case "$1" in
  autohide) eval_js 'panels().forEach(function(p){ p.hiding = (p.hiding === "none") ? "autohide" : "none"; })' ;;
  status)   [ "$(eval_js 'print(panels().length ? panels()[0].hiding : "none")')" != none ] ;;
  top|bottom) eval_js "panels().forEach(function(p){ p.location = \"$1\"; })" ;;
esac
