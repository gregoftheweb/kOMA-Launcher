.pragma library

// kOMA Launcher's built-in menu, in Omarchy's menu format
// (id → { icon, label, action | target | provider, aliases, when, checked }).
// The parent is the dotted id minus its last segment. Icons are Nerd Font
// glyphs, labels and structure follow Omarchy's default menu; actions are
// KDE-native.
//
// Actions run with `bash -c` and these helpers in the environment:
//   $KOMA   the package's scripts/ folder
//   koma-settings <kcm>   open a System Settings page
// Override or extend any entry in ~/.config/komalauncher/menu.jsonc
// (same format, JSONC; reusing an id merges over the default).

var ITEMS = {
    "root": {
        "label": "Go"
    },
    "apps": {
        "icon": "󰀻",
        "label": "Apps",
        "aliases": ["app", "applications"],
        "provider": "apps"
    },
    "learn": {
        "icon": "󰧑",
        "label": "Learn"
    },
    "trigger": {
        "icon": "󱓞",
        "label": "Trigger"
    },
    "style": {
        "icon": "",
        "label": "Style"
    },
    "setup": {
        "icon": "",
        "label": "Setup",
        "aliases": ["settings"]
    },
    "about": {
        "icon": "",
        "label": "About",
        "action": "kinfocenter"
    },
    "system": {
        "icon": "",
        "label": "System",
        "aliases": ["power-menu", "power"]
    },
    // ---------------------------------------------------------------- system
    "system.settings": {
        "icon": "",
        "label": "Plasma System Settings",
        "aliases": ["system-settings", "systemsettings"],
        "action": "systemsettings"
    },
    "system.lock": {
        "icon": "",
        "label": "Lock",
        "action": "loginctl lock-session"
    },
    "system.screen-off": {
        "icon": "󱄄",
        "label": "Screen Off",
        "action": "sleep 0.5; qdbus6 org.kde.kglobalaccel /component/org_kde_powerdevil org.kde.kglobalaccel.Component.invokeShortcut 'Turn Off Screen'"
    },
    "system.suspend": {
        "icon": "󰒲",
        "label": "Suspend",
        "action": "systemctl suspend"
    },
    // Hibernation needs a real (non-zram) swap device to hold the image.
    "system.hibernate": {
        "icon": "󰤁",
        "label": "Hibernate",
        "when": "grep -qw disk /sys/power/state && swapon --show=NAME --noheadings | grep -qv zram",
        "action": "systemctl hibernate"
    },
    "system.logout": {
        "icon": "󰍃",
        "label": "Logout",
        "action": "qdbus6 org.kde.Shutdown /Shutdown org.kde.Shutdown.logout"
    },
    "system.reboot": {
        "icon": "󰜉",
        "label": "Reboot",
        "action": "qdbus6 org.kde.Shutdown /Shutdown org.kde.Shutdown.logoutAndReboot"
    },
    "system.shutdown": {
        "icon": "󰐥",
        "label": "Shutdown",
        "action": "qdbus6 org.kde.Shutdown /Shutdown org.kde.Shutdown.logoutAndShutdown"
    },

    // ----------------------------------------------------------------- learn
    "learn.keybindings": {
        "icon": "",
        "label": "Keybindings",
        "aliases": ["keybindings", "keys", "shortcuts"],
        "provider": "keybindings"
    },
    "learn.kde": {
        "icon": "",
        "label": "KDE Plasma",
        "action": "xdg-open 'https://userbase.kde.org/Plasma'"
    },
    "learn.arch": {
        "icon": "󰣇",
        "label": "Arch",
        "action": "xdg-open 'https://wiki.archlinux.org/title/Main_page'"
    },
    "learn.neovim": {
        "icon": "",
        "label": "Neovim",
        "action": "xdg-open 'https://www.lazyvim.org/keymaps'"
    },
    "learn.bash": {
        "icon": "󱆃",
        "label": "Bash",
        "action": "xdg-open 'https://devhints.io/bash'"
    },

    // --------------------------------------------------------------- trigger
    "trigger.emoji": {
        "icon": "",
        "label": "Emoji",
        "aliases": ["emoji", "emojis"],
        "action": "plasma-emojier"
    },
    "trigger.capture": {
        "icon": "",
        "label": "Capture",
        "aliases": ["capture", "screenshot", "screenrecord"]
    },
    "trigger.capture.screenshot": {
        "icon": "",
        "label": "Screenshot"
    },
    "trigger.capture.screenshot.region": {
        "icon": "󰩭",
        "label": "Region",
        "action": "spectacle -r -b -c"
    },
    "trigger.capture.screenshot.window": {
        "icon": "",
        "label": "Window",
        "action": "spectacle -a -b -c"
    },
    "trigger.capture.screenshot.screen": {
        "icon": "󰍹",
        "label": "Screen",
        "action": "spectacle -m -b -c"
    },
    "trigger.capture.screenshot.everything": {
        "icon": "󰍺",
        "label": "All Screens",
        "action": "spectacle -f -b -c"
    },
    "trigger.capture.screenshot.app": {
        "icon": "",
        "label": "Open Spectacle",
        "action": "spectacle"
    },
    "trigger.capture.screenrecord": {
        "icon": "",
        "label": "Screenrecord"
    },
    "trigger.capture.screenrecord.region": {
        "icon": "󰩭",
        "label": "Region",
        "action": "spectacle -R r"
    },
    "trigger.capture.screenrecord.window": {
        "icon": "",
        "label": "Window",
        "action": "spectacle -R w"
    },
    "trigger.capture.screenrecord.screen": {
        "icon": "󰍹",
        "label": "Screen",
        "action": "spectacle -R s"
    },
    "trigger.capture.text": {
        "icon": "󰴑",
        "label": "Text",
        "description": "Read text from a screen region (OCR)",
        "action": "bash $KOMA/ocr.sh"
    },
    "trigger.capture.qr": {
        "icon": "󰐲",
        "label": "QR Code",
        "action": "bash $KOMA/qr.sh"
    },
    "trigger.capture.color": {
        "icon": "󰃉",
        "label": "Color",
        "aliases": ["color-picker"],
        "action": "bash $KOMA/colorpick.sh"
    },
    "trigger.share": {
        "icon": "",
        "label": "Share",
        "aliases": ["share"]
    },
    "trigger.share.receive": {
        "icon": "󰥦",
        "label": "LocalSend",
        "when": "koma-cmd-present localsend",
        "action": "localsend"
    },
    "trigger.share.phone": {
        "icon": "",
        "label": "Phone (KDE Connect)",
        "when": "koma-cmd-present kdeconnect-app",
        "action": "kdeconnect-app"
    },
    "trigger.toggle": {
        "icon": "󰔎",
        "label": "Toggle",
        "aliases": ["toggle", "toggles"]
    },
    "trigger.toggle.idle-lock": {
        "icon": "󰅶",
        "label": "Stay Awake",
        "checked": "bash $KOMA/stay-awake.sh status",
        "action": "bash $KOMA/stay-awake.sh toggle"
    },
    "trigger.toggle.notifications": {
        "icon": "󰂛",
        "label": "Do Not Disturb",
        "action": "qdbus6 org.kde.kglobalaccel /component/plasmashell org.kde.kglobalaccel.Component.invokeShortcut 'toggle do not disturb'"
    },
    "trigger.toggle.nightlight": {
        "icon": "󰔎",
        "label": "Nightlight",
        "checked": "[[ $(qdbus6 org.kde.KWin.NightLight /org/kde/KWin/NightLight org.kde.KWin.NightLight.running) == true ]]",
        "action": "qdbus6 org.kde.kglobalaccel /component/kwin org.kde.kglobalaccel.Component.invokeShortcut 'Toggle Night Color'"
    },
    "trigger.toggle.top-bar": {
        "icon": "󰍜",
        "label": "Panel Autohide",
        "checked": "bash $KOMA/panels.sh status",
        "action": "bash $KOMA/panels.sh autohide"
    },
    "trigger.toggle.animations": {
        "icon": "󰕟",
        "label": "Animations",
        "checked": "bash $KOMA/animations.sh status",
        "action": "bash $KOMA/animations.sh toggle"
    },
    "trigger.toggle.tiling": {
        "icon": "󰕴",
        "label": "Tiling",
        "aliases": ["tiling", "tile"],
        "when": "[ -d /usr/share/kwin/scripts/krohnkite ] || [ -d ~/.local/share/kwin/scripts/krohnkite ]",
        "checked": "bash $KOMA/tiling.sh status",
        "action": "bash $KOMA/tiling.sh toggle"
    },
    "trigger.hardware": {
        "icon": "",
        "label": "Hardware",
        "aliases": ["hardware", "hw"]
    },
    "trigger.hardware.audio": {
        "icon": "󰕾",
        "label": "Audio",
        "aliases": ["audio", "sound"],
        "action": "koma-settings kcm_pulseaudio"
    },
    "trigger.hardware.bluetooth": {
        "icon": "󰂯",
        "label": "Bluetooth",
        "aliases": ["bluetooth"],
        "action": "koma-settings kcm_bluetooth"
    },
    "trigger.hardware.network": {
        "icon": "󰖩",
        "label": "Network",
        "aliases": ["network", "wifi"],
        "action": "koma-settings kcm_networkmanagement"
    },
    "trigger.hardware.display": {
        "icon": "󰍹",
        "label": "Display",
        "aliases": ["display", "monitors"],
        "action": "koma-settings kcm_kscreen"
    },
    "trigger.hardware.power": {
        "icon": "󰚥",
        "label": "Power",
        "aliases": ["power-settings"],
        "action": "koma-settings kcm_powerdevilprofilesconfig"
    },
    "trigger.hardware.keyboard": {
        "icon": "󰌌",
        "label": "Keyboard",
        "action": "koma-settings kcm_keyboard"
    },
    "trigger.hardware.mouse": {
        "icon": "󰍽",
        "label": "Mouse",
        "action": "koma-settings kcm_mouse"
    },
    "trigger.hardware.touchpad": {
        "icon": "󰟸",
        "label": "Touchpad",
        "when": "ls /sys/class/input/*/device/name 2>/dev/null | xargs -r cat | grep -qi touchpad",
        "action": "koma-settings kcm_touchpad"
    },
    "trigger.hardware.activity": {
        "icon": "󰓅",
        "label": "Activity",
        "aliases": ["activity", "system-monitor"],
        "action": "plasma-systemmonitor"
    },

    // ----------------------------------------------------------------- style
    "style.theme": {
        "icon": "󰸌",
        "label": "Theme",
        "aliases": ["theme", "themes"],
        "provider": "themes"
    },
    "style.colors": {
        "icon": "",
        "label": "Colors",
        "aliases": ["colors", "color-scheme"],
        "provider": "colors"
    },
    "style.background": {
        "icon": "",
        "label": "Background",
        "aliases": ["background", "wallpaper"],
        "provider": "wallpapers"
    },
    "style.icons": {
        "icon": "",
        "label": "Icons",
        "provider": "icons"
    },
    "style.cursor": {
        "icon": "󰇀",
        "label": "Cursor",
        "provider": "cursors"
    },
    "style.font": {
        "icon": "",
        "label": "Font",
        "action": "koma-settings kcm_fonts"
    },
    "style.bar": {
        "icon": "󰍜",
        "label": "Panels"
    },
    "style.bar.position": {
        "icon": "",
        "label": "Position"
    },
    "style.bar.position.top": {
        "icon": "󰁝",
        "label": "Top",
        "action": "bash $KOMA/panels.sh top"
    },
    "style.bar.position.bottom": {
        "icon": "󰁅",
        "label": "Bottom",
        "action": "bash $KOMA/panels.sh bottom"
    },
    "style.bar.autohide": {
        "icon": "󰍜",
        "label": "Autohide",
        "checked": "bash $KOMA/panels.sh status",
        "action": "bash $KOMA/panels.sh autohide"
    },
    "style.bar.edit": {
        "icon": "",
        "label": "Edit Panels",
        "action": "qdbus6 org.kde.plasmashell /PlasmaShell org.kde.PlasmaShell.setEditMode true"
    },
    "style.window-decoration": {
        "icon": "",
        "label": "Window Decorations",
        "action": "koma-settings kcm_kwindecoration"
    },

    // ----------------------------------------------------------------- setup
    "setup.koma-installer": {
        "icon": "󰏖",
        "label": "kOMA Installer",
        "aliases": ["koma-installer"],
        "when": "bash \"$KOMA/installer.sh\" --available",
        "action": "bash \"$KOMA/installer.sh\""
    },
    "setup.get-koma-theme": {
        "icon": "󰏖",
        "label": "Get the Complete kOMA Theme",
        "aliases": ["get-koma-theme"],
        "when": "! bash \"$KOMA/installer.sh\" --available",
        "action": "xdg-open https://github.com/gregoftheweb/kOMA-desktop-theme"
    },
    "setup.monitors": {
        "icon": "󰍹",
        "label": "Monitors",
        "action": "koma-settings kcm_kscreen"
    },
    "setup.keybindings": {
        "icon": "",
        "label": "Keybindings",
        "action": "koma-settings kcm_keys"
    },
    "setup.input": {
        "icon": "",
        "label": "Input",
        "action": "koma-settings kcm_keyboard"
    },
    "setup.network": {
        "icon": "󰛳",
        "label": "Network",
        "action": "koma-settings kcm_networkmanagement"
    },
    "setup.default": {
        "icon": "",
        "label": "Default Apps",
        "aliases": ["default", "defaults"],
        "action": "koma-settings kcm_componentchooser"
    },
    "setup.desktops": {
        "icon": "󱂬",
        "label": "Virtual Desktops",
        "action": "koma-settings kcm_kwin_virtualdesktops"
    },
    "setup.notifications": {
        "icon": "󰂚",
        "label": "Notifications",
        "action": "koma-settings kcm_notifications"
    },
    "setup.security": {
        "icon": "",
        "label": "Security"
    },
    "setup.security.screenlock": {
        "icon": "",
        "label": "Screen Locking",
        "action": "koma-settings kcm_screenlocker"
    },
    "setup.security.users": {
        "icon": "",
        "label": "Users & Password",
        "action": "koma-settings kcm_users"
    },
    "setup.config": {
        "icon": "",
        "label": "Config"
    },
    "setup.config.launcher": {
        "icon": "",
        "label": "kOMA Launcher Menu",
        "action": "mkdir -p ~/.config/komalauncher; f=~/.config/komalauncher/menu.jsonc; [ -f \"$f\" ] || printf '{\\n  // kOMA Launcher menu overrides (same format as the built-in menu).\\n}\\n' > \"$f\"; kate \"$f\""
    },
    "setup.config.autostart": {
        "icon": "",
        "label": "Autostart",
        "action": "koma-settings kcm_autostart"
    },
    "setup.config.window-rules": {
        "icon": "",
        "label": "Window Rules",
        "action": "koma-settings kcm_kwinrules"
    }
};

// How each provider turns a picked value into a command.
var PROVIDER_ACTIONS = {
    "themes": function (v, q) {
        return "plasma-apply-lookandfeel -a " + q(v)
    },
    "colors": function (v, q) {
        return "plasma-apply-colorscheme " + q(v)
    },
    "wallpapers": function (v, q) {
        return "plasma-apply-wallpaperimage " + q(v)
    },
    "icons": function (v, q) {
        return "/usr/lib/plasma-changeicons " + q(v)
    },
    "cursors": function (v, q) {
        return "plasma-apply-cursortheme " + q(v)
    },
    "keybindings": function (v, q) {
        return ""
    }
};

// Glyph shown on provider rows (the current value gets ✓ instead).
var PROVIDER_ICONS = {
    "themes": "󰸌",
    "colors": "",
    "wallpapers": "",
    "icons": "",
    "cursors": "󰇀",
    "keybindings": ""
};

// Rebuilt on every open, since the pick may have changed what's current.
var VOLATILE_PROVIDERS = ["themes", "colors", "icons", "cursors", "keybindings"]
