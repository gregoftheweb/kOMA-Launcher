# Changelog

All notable changes to kOMA Launcher. The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/) and versions follow [Semantic Versioning](https://semver.org/).

## [0.1.0] - 2026-10-04

First public release.

### Added

- Omarchy-style launcher for Plasma 6: a boxy, keyboard-driven card on the focused screen with type-to-search across apps and the whole menu tree (about 90 entries: Apps, Learn, Trigger, Style, Setup, About, System).
- `komalauncher open [menu]` to open any menu from a hotkey; pressing it again closes it.
- Menu overrides and additions in `~/.config/komalauncher/menu.jsonc`, in Omarchy's menu format.
- Wallpaper picker folders: `~/Pictures/Wallpapers`, `~/.local/share/wallpapers`, and any listed in `~/.config/komalauncher/wallpaper-dirs`.
- Border and selection follow the color scheme's highlight color.
- QML unit tests for the menu model and the built-in menu, CLI tests, linting and formatting gates (`make check`), a pre-commit hook and `make package`.

[0.1.0]: https://github.com/columbiafoundry/kOMA-Launcher/releases/tag/v0.1.0
