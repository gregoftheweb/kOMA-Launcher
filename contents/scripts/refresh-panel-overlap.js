// One pass per KWin session, after the launcher's panel has appeared.
// Windows that opened before the panel (such as a welcome app at login) were placed
// on the whole screen and can sit under it. Move each one into the area the panels
// leave free, shrinking it only if it is larger than that area.
function clamp(value, low, high) {
    return Math.max(low, Math.min(value, high))
}

for (const window of workspace.windowList()) {
    if (!window.normalWindow || window.fullScreen || window.minimized || !window.moveable)
        continue
    const usable = workspace.clientArea(KWin.MaximizeArea, window)
    const frame = window.frameGeometry
    const inside = frame.x >= usable.x && frame.y >= usable.y && frame.x + frame.width <= usable.x + usable.width && frame.y + frame.height <= usable.y + usable.height
    if (inside)
        continue
    if (window.maximizable && frame.width >= usable.width && frame.height >= usable.height) {
        // a maximized window: maximize again into the new area
        window.setMaximize(false, false)
        window.setMaximize(true, true)
    } else {
        const width = Math.min(frame.width, usable.width)
        const height = Math.min(frame.height, usable.height)
        window.frameGeometry = {
            x: clamp(frame.x, usable.x, usable.x + usable.width - width),
            y: clamp(frame.y, usable.y, usable.y + usable.height - height),
            width: width,
            height: height
        }
    }
    print('kOMA Launcher: moved out from under the panel: ' + window.caption)
}
