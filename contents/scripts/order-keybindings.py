#!/usr/bin/env python3
"""Display active KDE shortcuts in the supplied Omarchy CSV reference order."""
import csv
from pathlib import Path
import re
import sys

ALIASES = {
    'koma launcher': 'Omarchy menu', 'konsole': 'Terminal',
    'dolphin': 'File manager', 'make window fullscreen': 'Full screen',
    'maximize window horizontally': 'Full width', 'lock session': 'Lock system',
    'keep window above': 'Pop window out (float & pin)',
    'toggle float': 'Toggle window floating/tiling', 'toggle split': 'Toggle window split',
    'show clipboard items at mouse position': 'Clipboard manager',
    'show clipboard history': 'Clipboard manager', 'clipboard history': 'Clipboard manager',
    'emoji picker': 'Emojis', 'screenshot region': 'Screenshot',
    'record region': 'Screenrecording', 'switch to next desktop': 'Next workspace',
    'switch to previous desktop': 'Previous workspace',
    'walk through windows': 'Focus on next window',
    'walk through windows (reverse)': 'Focus on previous window',
}


def normalized(name):
    name = name.removeprefix('Launch: ').removeprefix('Tiling: ')
    move = re.fullmatch(r'Window to Desktop (\d+)', name, re.I)
    desktop = re.fullmatch(r'Switch to Desktop (\d+)', name, re.I)
    if move:
        return 'Move window to workspace ' + move[1]
    if desktop:
        return 'Switch to workspace ' + desktop[1]
    return ALIASES.get(name.lower(), name)


def chord(value):
    value = value.upper().replace('ENTER', 'RETURN').replace('ESCAPE', 'ESC')
    tokens = [p for p in re.split(r'[ +]+', value) if p]
    return tuple(sorted(tokens))


REFERENCE = list(csv.DictReader((Path(__file__).resolve().parents[1] / 'data/keybinding-order.csv').open()))


def rank(row):
    keys, title, action = row
    name = normalized(title).lower()
    names = [int(r['order']) for r in REFERENCE if r['action'].lower() == name]
    if names:
        return (min(names), action)
    # Order KDE-specific equivalents by their active chord; preserve their own labels.
    chords = {chord(k.strip()) for k in keys.split('  /  ')}
    matches = [int(r['order']) for r in REFERENCE if chord(r['keys']) in chords]
    return (min(matches) if matches else 1000, action)


def render(rows):
    for keys, title, action in sorted(rows, key=rank):
        name = normalized(title)
        if name == 'Omarchy menu':
            name = 'kOMA Launcher'
        if name == 'Browser' and 'Super+Shift+Enter' in keys:
            chords = keys.split('  /  ')
            chords.sort(key=lambda c: c != 'Super+Shift+Enter')
            keys = '  /  '.join(chords)
        yield f'{keys} → {name}\t{action}\t\n'


if __name__ == '__main__':
    rows = [line.rstrip('\n').split('\t') for line in sys.stdin if line.strip()]
    sys.stdout.writelines(render(rows))
