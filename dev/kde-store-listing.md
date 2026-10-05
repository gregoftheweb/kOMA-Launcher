# kOMA Launcher

Version: 0.1.0
License: MIT
Category: Plasma 6 Applets
Source: https://github.com/gregoftheweb/kOMA-Launcher

## Description

A keyboard-driven application launcher and command menu for KDE Plasma 6, inspired by Omarchy.

Type to search applications and menu actions. Browse menus with the arrow keys, launch with Enter, go back with Backspace, and close with Escape. The launcher opens on the focused screen and uses your Plasma color scheme.

Features:

- Search applications and the built-in menu tree.
- Access desktop settings, appearance controls, screenshots, sharing tools, keybindings, and system actions.
- Customize menu entries with ~/.config/komalauncher/menu.jsonc.
- Set a global shortcut through the widget's Keyboard Shortcuts settings.
- Use the optional komalauncher command for shortcuts that open specific submenus.

Requires KDE Plasma 6 and a Nerd Font for menu icons. Some menu actions require additional tools such as Spectacle, Tesseract, zbar, KDE Connect, or LocalSend. The optional command requires qdbus6 and is installed separately from the source repository.

Install the .plasmoid through Plasma's widget manager, add kOMA Launcher to a panel, and configure its keyboard shortcut. The widget must remain on a panel for shortcuts to reach it.

Part of kOMA, and also usable as a standalone widget. MIT licensed, with credit to Omarchy and David Heinemeier Hansson for the original menu model and design.

Source and support: https://github.com/gregoftheweb/kOMA-Launcher

## Upload

dist/com.columbiafoundry.komalauncher-0.1.0.plasmoid

Attach real screenshots of the root menu, application search, and an example submenu.
