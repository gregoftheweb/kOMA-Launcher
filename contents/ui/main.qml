// kOMA Launcher panel widget: a button that toggles the launcher, plus a
// remote-control hook so hotkeys can open any menu:
//   komalauncher open [menu]     (bin/komalauncher)
import QtQuick
import org.kde.kirigami as Kirigami
import org.kde.plasma.plasmoid

PlasmoidItem {
    id: root

    // A single button, like KDE's Show Desktop widget: the button IS the full
    // representation (with only a compact one, the panel shows nothing).
    preferredRepresentation: fullRepresentation
    activationTogglesExpanded: false

    fullRepresentation: MouseArea {
        hoverEnabled: true
        onClicked: launcher.toggle("root")
        Kirigami.Icon {
            anchors.fill: parent
            source: Plasmoid.icon || "archlinux"
            active: parent.containsMouse
        }
    }

    // The widget's own keyboard shortcut (Configure → Keyboard Shortcuts).
    Connections {
        target: Plasmoid
        function onActivated() { launcher.toggle("root") }
    }

    // bin/komalauncher writes "<route>|<timestamp>". Asking for the menu
    // that's already showing closes it, so one hotkey both opens and closes.
    property string openedRoute: ""
    Connections {
        target: Plasmoid.configuration
        function onOpenRequestChanged() {
            var request = String(Plasmoid.configuration.openRequest || "")
            if (!request) return
            var route = request.split("|")[0] || "root"
            if (launcher.visible && route === root.openedRoute) {
                launcher.close()
                return
            }
            if (launcher.visible) launcher.close()
            root.openedRoute = route
            launcher.open(route)
        }
    }

    LauncherWindow {
        id: launcher
        // The theme's highlight color; follows color scheme + accent changes live.
        themeAccent: Kirigami.Theme.highlightColor
        onClosed: root.openedRoute = ""
    }
}
