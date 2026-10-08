// kOMA Launcher panel widget: a button that toggles the launcher, plus a
// remote-control hook so hotkeys can open any menu:
//   komalauncher open [menu]     (bin/komalauncher)
pragma ComponentBehavior: Bound

import QtQuick
import org.kde.kirigami as Kirigami
import org.kde.plasma.plasmoid

PlasmoidItem {
    id: root

    // A single button, like KDE's Show Desktop widget: the button IS the full
    // representation (with only a compact one, the panel shows nothing).
    preferredRepresentation: fullRepresentation
    activationTogglesExpanded: false

    // One deferred pass after panel startup; the helper deduplicates multiple panels.
    CommandQueue {
        id: startupRefresh
    }
    Timer {
        interval: 2500
        running: true
        repeat: false
        onTriggered: {
            var path = decodeURIComponent(Qt.resolvedUrl("../scripts/refresh-panel-overlap.sh").toString().replace("file://", ""))
            startupRefresh.run("bash '" + path.replace(/'/g, "'\\''") + "'")
        }
    }

    fullRepresentation: MouseArea {
        hoverEnabled: true
        onClicked: launcher.toggle("root")
        Item {
            anchors.centerIn: parent
            width: Math.min(parent.width, parent.height)
            height: width
            Kirigami.Icon {
                anchors.fill: parent
                source: Qt.resolvedUrl("../icons/koma-ring.svg")
                isMask: true
                color: "white"
            }
            Kirigami.Icon {
                anchors.fill: parent
                source: Qt.resolvedUrl("../icons/koma-k.svg")
                isMask: true
                color: Kirigami.Theme.highlightColor
            }
        }
    }

    // The widget's own keyboard shortcut (Configure → Keyboard Shortcuts).
    Connections {
        target: Plasmoid
        function onActivated() {
            launcher.toggle("root")
        }
    }

    // bin/komalauncher writes "<route>|<timestamp>". Asking for the menu
    // that's already showing closes it, so one hotkey both opens and closes.
    property string openedRoute: ""
    Connections {
        target: Plasmoid.configuration
        function onOpenRequestChanged() {
            var request = String(Plasmoid.configuration.openRequest || "")
            if (!request)
                return
            var route = request.split("|")[0] || "root"
            if (launcher.visible && route === root.openedRoute) {
                launcher.close()
                return
            }
            if (launcher.visible)
                launcher.close()
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
