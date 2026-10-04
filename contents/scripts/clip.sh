#!/usr/bin/env bash
# clip.sh <text> — put text on the KDE clipboard (Klipper).
qdbus6 org.kde.klipper /klipper org.kde.klipper.klipper.setClipboardContents "$1" >/dev/null
