# Changelog

All notable changes to kOMA Launcher. The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/) and versions follow [Semantic Versioning](https://semver.org/).

## [0.2.0] - Unreleased

### Added

- kOMA panel mark: a white ring with the "k" in the color scheme's accent color, replacing the Arch logo.
- **kOMA Installer** entry (top level and System) when the kOMA theme installer is available; otherwise **Get the Complete kOMA Theme** links to the theme on GitHub.
- At panel startup, one deferred pass asks KWin to re-place normal windows overlapping a panel's reserved screen edge. Multiple panels share one pass per KWin session; fullscreen and minimized windows are skipped.

### Changed

- Keybindings reference: a wider card with keys and action in two columns, `Super` and `Enter` instead of `Meta` and `Return`, ordered by `contents/data/keybinding-order.csv`. It only orders active KDE shortcuts; it does not install Omarchy-only bindings.

### Fixed

- Commands keep one fixed source name and run through `CommandQueue`. A per-call counter in the name made Plasma's command engine keep a property per call forever, slowing plasmashell over time.
- `make install` / `bin/dev-reload` installs only the package files instead of copying the whole repository, `node_modules` included, into the Plasma widget folder.

## [0.1.0] - 2026-10-04

First public release.

### Added

- Omarchy-style launcher for Plasma 6: a boxy, keyboard-driven card on the focused screen with type-to-search across apps and the whole menu tree (about 90 entries: Apps, Learn, Trigger, Style, Setup, About, System).
- `komalauncher open [menu]` to open any menu from a hotkey; pressing it again closes it.
- Menu overrides and additions in `~/.config/komalauncher/menu.jsonc`, in Omarchy's menu format.
- Wallpaper picker folders: `~/Pictures/Wallpapers`, `~/.local/share/wallpapers`, and any listed in `~/.config/komalauncher/wallpaper-dirs`.
- Border and selection follow the color scheme's highlight color.
- QML unit tests for the menu model and the built-in menu, CLI tests, linting and formatting gates (`make check`), a pre-commit hook and `make package`.

[0.1.0]: https://github.com/gregoftheweb/kOMA-Launcher/releases/tag/v0.1.0
