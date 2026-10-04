// Dev harness: opens the launcher window directly, without plasmashell.
//   qml6 dev/preview.qml              top menu
//   qml6 dev/preview.qml -- system    any menu id or alias (apps, capture, ...)
// Quits shortly after the launcher closes. The delay lets a launch finish
// handing off to KDE; quitting immediately kills the launch job.
import QtQuick
import "../contents/ui"

LauncherWindow {
    id: launcher
    Component.onCompleted: {
        var args = Qt.application.arguments
        var dash = args.indexOf("--")
        open(dash >= 0 && dash + 1 < args.length ? args[dash + 1] : "root")
    }
    onClosed: quitTimer.start()

    property Timer quitTimer: Timer {
        interval: 3000
        onTriggered: Qt.quit()
    }
}
