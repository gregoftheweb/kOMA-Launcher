// One pass per KWin session, after the launcher's panel has appeared.
// Reassign only normal windows intersecting a panel's reserved screen edge.
for (const window of workspace.windowList()) {
    if (!window.normalWindow || window.fullScreen || window.minimized)
        continue
    var usable = workspace.clientArea(KWin.MaximizeArea, window)
    var screen = workspace.clientArea(KWin.FullScreenArea, window)
    var frame = window.frameGeometry
    var right = frame.x + frame.width
    var bottom = frame.y + frame.height
    var overlaps = (usable.y > screen.y && frame.y < usable.y && bottom > screen.y) || (usable.x > screen.x && frame.x < usable.x && right > screen.x) || (usable.y + usable.height < screen.y + screen.height && bottom > usable.y + usable.height && frame.y < screen.y + screen.height) || (usable.x + usable.width < screen.x + screen.width && right > usable.x + usable.width && frame.x < screen.x + screen.width)
    if (overlaps) {
        window.desktops = window.desktops.slice()
        print('kOMA Launcher: requested same-workspace refresh for ' + window.caption)
    }
}
