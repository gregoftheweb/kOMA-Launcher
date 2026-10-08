# kOMA Launcher

**[Omarchy](https://omarchy.org)'s launcher and command menu, rebuilt as a native KDE Plasma 6 widget.** Press a hotkey, start typing, and launch apps or run anything in Omarchy's menu tree (screenshots, toggles, themes, power) without touching the mouse.

It's part of kOMA (KDE + Omarchy), a set of add-ons that make Plasma look and drive like Omarchy.

## Features

- **Keyboard first**: type anywhere to search apps and every menu entry; Enter or → drills in, Backspace or ← goes back, Esc closes.
- **Omarchy's menu tree**, with KDE-native actions: Apps, Learn (including a live list of your keybindings), Trigger (capture, share, toggles), Style (Global Theme, colors, icons, cursor, wallpaper), Setup, About and System (lock, suspend, logout, reboot, shutdown).
- **Opens on the focused screen**, as a boxy card over a dimmed desktop.
- **Follows your theme**: the border and selection use your color scheme's highlight color.
- **Yours to change**: override or add entries in `~/.config/komalauncher/menu.jsonc`.

## Requirements

- KDE Plasma 6
- A [Nerd Font](https://www.nerdfonts.com) for the menu icons, for example JetBrainsMono Nerd Font (`ttf-jetbrains-mono-nerd` on Arch)
- `qdbus6` (in `qt6-tools` on Arch) for the `komalauncher` command
- Optional, for some actions: `spectacle` (screenshots and recording), `tesseract` (text from a screen region), `zbar` (QR codes), `libnotify` (notifications), `kdeconnect` and `localsend` (sharing)

## Install

From the KDE Store: right-click the panel, **Add or Manage Widgets**, **Get New Widgets**, search for "kOMA Launcher", and add it to a panel. The widget must sit on at least one panel for hotkeys to reach it.

From source:

```sh
git clone https://github.com/gregoftheweb/kOMA-Launcher
cd kOMA-Launcher
bin/dev-reload                                   # install the widget and restart plasmashell
ln -s "$PWD/bin/komalauncher" ~/.local/bin/      # the command for hotkeys
```

## Hotkeys

For a Store installation, right-click the widget, choose **Configure kOMA Launcher**, and set a shortcut in **Keyboard Shortcuts**. This opens the launcher without installing the optional `komalauncher` command.

Bind any key to `komalauncher open [menu]` in System Settings › Keyboard › Shortcuts (Add New › Command or Script). Omarchy's defaults:

| Key              | Command                         |
| ---------------- | ------------------------------- |
| Super+Space      | `komalauncher open`             |
| Super+Alt+Space  | `komalauncher open apps`        |
| Super+Esc        | `komalauncher open system`      |
| Super+K          | `komalauncher open keybindings` |
| Super+Ctrl+C     | `komalauncher open capture`     |
| Super+Ctrl+O     | `komalauncher open toggle`      |
| Super+Ctrl+Space | `komalauncher open background`  |

`menu` is any menu id or alias, such as `style`, `share`, `theme` or `trigger.emoji`. Running the same command while the menu is open closes it.

## Customizing

`~/.config/komalauncher/menu.jsonc` uses Omarchy's menu format: an object of `id → { icon, label, action | target | provider, aliases, when, checked }`. The parent is the dotted id minus its last part, and reusing an id merges over the built-in entry.

```jsonc
{
  // a new entry under Trigger
  "trigger.backup": { "icon": "󰁯", "label": "Backup", "action": "deja-dup --backup" },
  // relabel a built-in one
  "system.lock": { "label": "Lock Screen" },
}
```

Extra wallpaper folders for Style › Wallpaper go in `~/.config/komalauncher/wallpaper-dirs`, one per line.

## Development

```sh
make setup      # prettier + shellcheck in node_modules, and the git hook
make check      # qmllint, qmlformat, prettier, shellcheck, metadata, QML unit tests, CLI tests
make format     # apply every formatter
make package    # dist/com.columbiafoundry.komalauncher-<version>.plasmoid for the KDE Store
qml6 dev/preview.qml    # run the launcher outside the panel
```

The pre-commit hook runs `make check`. Qt 6's tools are taken from `/usr/lib/qt6/bin`; set `QT_BIN` if yours live elsewhere.

## License

MIT © 2026 Columbia Foundry. kOMA Launcher ports parts of [Omarchy](https://github.com/basecamp/omarchy) (MIT, © David Heinemeier Hansson): the menu model and the menu's look and behavior. See [LICENSE](LICENSE).

At panel startup, Launcher performs one deferred check for normal windows overlapping
panel-reserved screen edges and requests a same-workspace reassignment. Multiple
panels share one pass per KWin session. Fullscreen and minimized windows are skipped.
This request can be ignored by KWin if it considers the assignment unchanged.

Launcher 0.2.0 adds the white-ring/accent-k panel mark, a kOMA Installer menu entry,
and a wider keybinding reference ordered by contents/data/keybinding-order.csv.
This reference only orders active KDE shortcuts; it does not install Omarchy-only bindings.
