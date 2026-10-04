// Dev self-test: opens a few routes and prints what the launcher would show.
//   qml6 dev/selftest.qml
import QtQuick
import "../contents/ui"

LauncherWindow {
    id: lg
    property var steps: [function () {
            open("root")
        }, function () {
            dump("root")
        }, function () {
            close()
            open("system")
        }, function () {
            dump("system (hibernate hidden on zram?)")
        }, function () {
            close()
            open("toggle")
        }, function () {
            dump("toggle (✓ marks)")
        }, function () {
            close()
            open("theme")
        }, function () {
            dump("style.theme provider")
        }, function () {
            close()
            open("root")
            setFilter("dolph")
        }, function () {
            dump("search 'dolph'")
        }, function () {
            setFilter("screen")
        }, function () {
            dump("search 'screen'")
        }, function () {
            close()
            Qt.quit()
        }]
    property int step: 0
    function dump(title) {
        var out = ["== " + title + " [" + activeMenu + "] " + rows.count + " rows"]
        for (var i = 0; i < Math.min(rows.count, 12); i++) {
            var r = rows.get(i)
            out.push("  " + (r.section === "drilldown" ? "· " : "") + r.kind + " | " + r.icon + " " + r.label + (r.detail ? "  (" + r.detail + ")" : ""))
        }
        console.log(out.join("\n"))
    }
    property Timer t: Timer {
        interval: 900
        repeat: true
        running: true
        onTriggered: {
            if (lg.step < lg.steps.length)
                lg.steps[lg.step++]()
        }
    }
}
