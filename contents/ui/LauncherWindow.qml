// kOMA Launcher: an Omarchy-style launcher and command menu for Plasma 6.
//
// Look and behavior follow Omarchy's menu (shell/plugins/menu/Menu.qml, MIT,
// https://github.com/basecamp/omarchy): a boxy card centered on a dimmed
// screen, a header that doubles as the search line, type-anywhere filtering
// across the whole menu tree, Enter/→ to drill in, Backspace/← to go back,
// and rows that fold at the bottom edge so a cut-off row says "more below".
//
// Plasma-native pieces replace the Quickshell ones:
//   - app list + launching: org.kde.plasma.private.kicker (what Kickoff uses)
//   - running commands: Plasma's "executable" data engine
//   - window placement: LayerShellQt, with KWin choosing the active screen
//     each time the launcher opens
//   - app icons: Kirigami.Icon (the user's icon theme)
import QtQuick
import QtQuick.Window
import org.kde.kirigami as Kirigami
import org.kde.layershell as LayerShell
import org.kde.plasma.plasma5support as P5Support
import org.kde.plasma.private.kicker as Kicker
import "AppSearch.js" as AppSearch
import "MenuModel.js" as MenuModel
import "DefaultMenu.js" as DefaultMenu

Window {
    id: root

    // ---------------------------------------------------------- theme
    // Background and text are tron-aqua (the Omarchy theme this desktop
    // borrows from); menu colors are derived the same way Omarchy's
    // Color.menu does. The accent (border + selected row) is the KDE theme's
    // highlight color, passed in by main.qml: Kirigami's theme only resolves
    // on Items inside plasmashell, not on this Window. Cyan is the fallback.
    property color themeBackground: "#050B14"
    property color themeForeground: "#BFEFFF"
    property color themeAccent: "#22E6FF"

    readonly property color cardBackground: themeBackground
    readonly property color foreground: themeForeground
    readonly property color cardBorder: themeAccent
    readonly property color scrim: Qt.rgba(themeBackground.r, themeBackground.g, themeBackground.b, 0.5)
    readonly property color selectedBackground: Qt.rgba(themeAccent.r, themeAccent.g, themeAccent.b, 0.12)
    readonly property color selectedText: themeAccent

    property string fontFamily: "JetBrainsMono Nerd Font"

    // ---------------------------------------------------------- sizes
    // Omarchy's Style tokens at [font] base-size = 11: every pixel value goes
    // through space(px), which scales by base-size / 12.
    property int fontBaseSize: 11
    readonly property real scale: fontBaseSize / 12
    function space(px) { return Math.max(1, Math.round(px * scale)) }
    function fontPx(mult) { return Math.max(1, Math.round(fontBaseSize * mult)) }

    readonly property int fontBody: fontPx(1.0)
    readonly property int fontBodySmall: fontPx(0.917)
    readonly property int fontTitle: fontPx(1.167)
    readonly property int fontHeading: fontPx(1.333)
    readonly property int iconLarge: fontPx(1.5)

    readonly property int gapsOut: 5
    readonly property int cornerRadius: 0
    readonly property int borderWidth: Math.max(1, space(2))
    readonly property int contentMargin: space(18)
    readonly property int headerHeight: Math.max(space(34), fontTitle + space(6) * 2)
    readonly property int contentSpacing: space(6)
    readonly property int baseRowHeight: Math.max(space(50), fontBody + space(12) * 2)
    readonly property int detailRowHeight: Math.max(space(58), fontBody + fontPx(0.833) + space(12) * 2)
    readonly property int rowPeek: Math.round(baseRowHeight * 0.55)
    readonly property int rowSpacing: space(3)
    readonly property int dividerHeight: space(17)
    // Menus whose rows are long (keybindings) get a wider card, as Omarchy
    // does for its font and screenrecord menus.
    readonly property var wideMenus: ["learn.keybindings"]
    readonly property int cardWidth: Math.min(space(wideMenus.indexOf(activeMenu) >= 0 ? 520 : 300), width - gapsOut * 2)

    // ---------------------------------------------------------- window
    color: "transparent"
    flags: Qt.FramelessWindowHint
    visible: false
    title: "kOMA Launcher"

    LayerShell.Window.scope: "komalauncher"
    LayerShell.Window.layer: LayerShell.Window.LayerOverlay
    LayerShell.Window.anchors: LayerShell.Window.AnchorTop | LayerShell.Window.AnchorBottom
                               | LayerShell.Window.AnchorLeft | LayerShell.Window.AnchorRight
    LayerShell.Window.exclusionZone: -1
    LayerShell.Window.keyboardInteractivity: LayerShell.Window.KeyboardInteractivityExclusive
    // Let KWin put the surface on the active screen (where focus is) on every
    // open, instead of whichever screen the panel hosting this widget is on.
    LayerShell.Window.wantsToBeOnActiveScreen: true

    signal closed()

    // ---------------------------------------------------------- state
    property var defaultItems: []
    property var userItems: []
    property var items: ({})
    property var itemOrder: []
    property bool rowsLoaded: false
    property string activeMenu: "root"
    property var navStack: []
    property string filterText: ""
    property int selectedIndex: 0
    property bool cursorActive: true
    property bool searchDivider: false
    property int layoutSerial: 0
    property var providersLoaded: ({})
    property var whenResults: ({})
    property var checkedResults: ({})
    property var disabledResults: ({})

    // Card top freezes on the first keystroke or submenu move so the card
    // grows/shrinks downward instead of re-centering on every change.
    property int frozenTop: -1
    property int frozenRowsHeight: -1

    // The scripts/ folder shipped next to this file, as a plain path.
    readonly property string scriptsDir: decodeURIComponent(Qt.resolvedUrl("../scripts").toString().replace(/^file:\/\//, ""))

    // ---------------------------------------------------------- open / close
    // open("") or open("root") shows the top menu; any id or alias works
    // ("apps", "system", "capture", "power-menu", ...). An alias for an action
    // runs it without showing the menu.
    function open(route) {
        root.ensureItems()
        var id = MenuModel.resolveRoute(root.items, root.itemOrder, route || "root")
        var entry = root.items[id]
        if (entry && entry.kind === "action" && entry.action) {
            root.runAction(entry.action)
            return
        }
        if (entry && entry.kind === "link" && entry.target) id = entry.target
        if (!root.items[id]) id = "root"

        root.activeMenu = id
        root.navStack = []
        root.filterText = ""
        root.selectedIndex = 0
        root.cursorActive = true
        root.frozenTop = -1
        root.frozenRowsHeight = -1
        pointerGate.reset()
        root.invalidateVolatileProviders()
        root.mergeAppRows()
        root.evaluateGuards()
        root.loadUserMenu()
        root.rebuildDisplay()
        root.loadProviderForMenu(id)
        root.visible = true
        root.requestActivate()
        keyCatcher.forceActiveFocus()
    }

    function close() {
        if (!root.visible) return
        root.visible = false
        root.filterText = ""
        root.closed()
    }

    function toggle(route) { root.visible ? root.close() : root.open(route) }

    // ---------------------------------------------------------- commands
    function shellQuote(s) { return "'" + String(s).replace(/'/g, "'\\''") + "'" }

    // Every command gets $KOMA and the koma-settings helper.
    function withEnv(script) {
        return "export KOMA=" + root.shellQuote(root.scriptsDir) + "; "
             + "koma-settings() { systemsettings \"$@\"; }; "
             + script
    }

    property int commandSerial: 0
    property var captureCallbacks: ({})

    // Detached: the launcher never waits on (or owns) what it starts.
    function runAction(action) {
        if (!action) return
        root.commandSerial += 1
        runner.connectSource("setsid -f bash -c " + root.shellQuote(root.withEnv(action))
                             + " >/dev/null 2>&1 # koma-" + root.commandSerial)
    }

    // Captured: stdout comes back to `callback` when the command exits.
    function runCapture(script, callback) {
        root.commandSerial += 1
        var source = "bash -c " + root.shellQuote(root.withEnv(script)) + " # koma-" + root.commandSerial
        var callbacks = root.captureCallbacks
        callbacks[source] = callback
        root.captureCallbacks = callbacks
        runner.connectSource(source)
    }

    P5Support.DataSource {
        id: runner
        engine: "executable"
        connectedSources: []
        onNewData: function (source, data) {
            var callback = root.captureCallbacks[source]
            if (callback) {
                var callbacks = root.captureCallbacks
                delete callbacks[source]
                root.captureCallbacks = callbacks
                callback(String(data.stdout || ""))
            }
            disconnectSource(source)
        }
    }

    // ---------------------------------------------------------- menu items
    function ensureItems() {
        if (root.defaultItems.length === 0) {
            var list = []
            for (var id in DefaultMenu.ITEMS) list.push(MenuModel.normalizeItem(id, DefaultMenu.ITEMS[id]))
            root.defaultItems = list
            root.rebuildItemsFromSources()
        }
    }

    function loadUserMenu() {
        root.runCapture("cat ~/.config/komalauncher/menu.jsonc 2>/dev/null", function (text) {
            var parsed = MenuModel.parseMenuJsonc(text)
            if (JSON.stringify(parsed) === JSON.stringify(root.userItems)) return
            root.userItems = parsed
            root.rebuildItemsFromSources()
            root.evaluateGuards()
        })
    }

    function rebuildItemsFromSources() {
        var merged = MenuModel.mergeMenuSources(root.defaultItems, root.userItems)
        root.items = merged.items
        root.itemOrder = merged.itemOrder
        root.providersLoaded = ({})
        root.rowsLoaded = true
        root.mergeAppRows()
        if (root.visible) {
            root.rebuildDisplay()
            root.loadProviderForMenu(root.activeMenu)
        }
    }

    // ---------------------------------------------------------- apps provider
    Kicker.RootModel {
        id: rootModel
        autoPopulate: true
        flat: true
        sorted: true
        showSeparators: false
        showAllApps: true
        showAllAppsCategorized: false
        showRecentApps: false
        showRecentDocs: false
        showPowerSession: false
        showFavoritesPlaceholder: false
        onCountChanged: if (root.rowsLoaded) { root.mergeAppRows(); if (root.visible) root.rebuildDisplay() }
    }

    // Row 0 of the root model is "All Applications": a flat, sorted list.
    readonly property var appsModel: rootModel.count > 0 ? rootModel.modelForRow(0) : null

    function mergeAppRows() {
        var model = root.appsModel
        if (!model || !root.rowsLoaded) return
        var appRows = []
        for (var i = 0; i < model.count; i++) {
            var idx = model.index(i, 0)
            var name = String(model.data(idx, Qt.DisplayRole) || "")
            var desktopId = String(model.data(idx, Qt.UserRole + 3) || "").replace(/\.desktop$/, "")
            if (!name || !desktopId) continue
            var description = String(model.data(idx, Qt.UserRole + 1) || "")
            var icon = model.data(idx, Qt.DecorationRole)
            appRows.push({
                id: "apps." + desktopId, parent: "apps", kind: "app",
                icon: "", iconFont: "", appIcon: typeof icon === "string" ? icon : "", appRow: i,
                label: name, title: "", target: "", description: description,
                action: "", provider: "", aliases: description ? [description] : [],
                when: "", checked: "", disabled: "", order: 0
            })
        }
        var merged = MenuModel.mergeAppRows(root.items, root.itemOrder, appRows)
        root.items = merged.items
        root.itemOrder = merged.itemOrder
    }

    // ---------------------------------------------------------- script providers
    function invalidateVolatileProviders() {
        var loaded = root.providersLoaded
        for (var id in loaded) {
            var entry = root.items[id]
            if (entry && DefaultMenu.VOLATILE_PROVIDERS.indexOf(entry.provider) >= 0) loaded[id] = false
        }
        root.providersLoaded = loaded
    }

    function loadProviderForMenu(id) {
        var entry = root.items[id]
        if (!entry || !entry.provider || entry.provider === "apps" || root.providersLoaded[id]) return
        var loaded = root.providersLoaded
        loaded[id] = true
        root.providersLoaded = loaded
        var provider = entry.provider
        root.runCapture("bash $KOMA/provider.sh " + root.shellQuote(provider), function (out) {
            root.mergeProviderRows(out, id, provider)
        })
    }

    function loadProvidersForSearch() {
        var active = root.items[root.activeMenu] ? root.activeMenu : "root"
        for (var i = 0; i < root.itemOrder.length; i++) {
            var entry = root.items[root.itemOrder[i]]
            if (!entry || !entry.provider || root.providersLoaded[entry.id]) continue
            if (active !== "root" && entry.id !== active && !MenuModel.isDescendantOf(root.items, entry.id, active)) continue
            root.loadProviderForMenu(entry.id)
        }
    }

    function mergeProviderRows(out, menuId, provider) {
        var actionFor = DefaultMenu.PROVIDER_ACTIONS[provider]
        var glyph = DefaultMenu.PROVIDER_ICONS[provider] || ""
        var lines = String(out || "").split("\n")
        var rows = []
        var taken = ({})
        for (var i = 0; i < lines.length; i++) {
            if (!lines[i].trim()) continue
            var parts = lines[i].split("\t")
            var label = parts[0] || ""
            var value = parts[1] || label
            var current = parts[2] || ""
            if (!label) continue
            var rowId = menuId + "." + MenuModel.slugify(value)
            while (taken[rowId]) rowId += "-"
            taken[rowId] = true
            rows.push({
                id: rowId, parent: menuId, kind: "action",
                icon: (current && value === current) ? "✓" : glyph, iconFont: "",
                label: label, title: "", target: "", description: "",
                action: actionFor ? actionFor(value, root.shellQuote) : "", provider: "",
                aliases: [], when: "", checked: "", disabled: "", order: 0
            })
        }
        var merged = MenuModel.swapProviderRows(root.items, root.itemOrder, menuId, rows)
        root.items = merged.items
        root.itemOrder = merged.itemOrder
        if (root.visible) root.rebuildDisplay()
    }

    // ---------------------------------------------------------- guards
    // `when:` hides a row, `checked:` adds ✓, `disabled:` dims it. One bash
    // run answers them all; the menu shows the last answers meanwhile.
    function evaluateGuards() {
        var script = MenuModel.guardScript(root.items)
        if (!script) return
        root.runCapture(script, function (out) {
            var when = ({}), checked = ({}), disabled = ({})
            var lines = out.split("\n")
            for (var i = 0; i < lines.length; i++) {
                var line = lines[i].trim()
                var colon = line.lastIndexOf(":")
                if (colon < 0) continue
                var value = line.substring(colon + 1) === "1"
                var rest = line.substring(0, colon)
                var tagAt = rest.lastIndexOf(":")
                if (tagAt < 0) continue
                var id = rest.substring(0, tagAt), tag = rest.substring(tagAt + 1)
                if (tag === "w") when[id] = value
                else if (tag === "c") checked[id] = value
                else if (tag === "d") disabled[id] = value
            }
            root.whenResults = when
            root.checkedResults = checked
            root.disabledResults = disabled
            if (root.visible) root.rebuildDisplay()
        })
    }

    // ---------------------------------------------------------- display
    ListModel { id: displayModel }
    readonly property alias rows: displayModel   // for dev/selftest.qml

    function displayRow(entry, detail, score, section) {
        var row = MenuModel.displayRow(root.items, root.itemOrder, root.checkedResults, root.disabledResults,
                                       entry, detail, score, section)
        row.appRow = entry.appRow !== undefined ? entry.appRow : -1
        return row
    }

    function isVisibleEntry(entry) {
        return MenuModel.isVisible(root.items, root.itemOrder, root.whenResults, entry)
    }

    function rebuildDisplay() {
        displayModel.clear()
        if (!root.rowsLoaded) return

        var active = root.items[root.activeMenu] ? root.activeMenu : "root"
        root.activeMenu = active
        var rows = []
        var query = root.filterText.trim()
        root.searchDivider = false

        if (query) {
            var currentRows = [], drilldownRows = []
            for (var i = 0; i < root.itemOrder.length; i++) {
                var entry = root.items[root.itemOrder[i]]
                if (!entry || entry.id === "root") continue
                if (!MenuModel.isDescendantOf(root.items, entry.id, active)) continue
                var visible = root.isVisibleEntry(entry) && !MenuModel.isDisabled(root.disabledResults, entry)
                if (!MenuModel.matchesQuery(entry, query, visible)) continue
                var detail = MenuModel.parentPathFor(root.items, entry.id)
                if (entry.kind === "app" && entry.description) detail = entry.description
                var row = root.displayRow(entry, detail, MenuModel.searchScore(root.items, entry, query))
                if (entry.parent === active) currentRows.push(row)
                else drilldownRows.push(row)
            }
            var searchSort = function (a, b) {
                if (a.score !== b.score) return a.score - b.score
                return a.path.localeCompare(b.path)
            }
            currentRows.sort(searchSort)
            drilldownRows.sort(searchSort)
            root.searchDivider = currentRows.length > 0 && drilldownRows.length > 0
            if (root.searchDivider)
                for (var d = 0; d < drilldownRows.length; d++) drilldownRows[d].section = "drilldown"
            rows = currentRows.concat(drilldownRows)
        } else {
            for (var j = 0; j < root.itemOrder.length; j++) {
                var child = root.items[root.itemOrder[j]]
                if (!child || child.parent !== active || !root.isVisibleEntry(child)) continue
                rows.push(root.displayRow(child, child.description, child.order))
            }
            if (active === "apps") {
                rows.sort(function (a, b) {
                    return String(a.label).toLowerCase().localeCompare(String(b.label).toLowerCase())
                })
            }
        }

        for (var k = 0; k < rows.length; k++) displayModel.append(rows[k])
        root.layoutSerial += 1
        root.settleCursor()
        Qt.callLater(root.revealCursor)
    }

    function settleCursor() {
        var count = displayModel.count
        if (count === 0) { root.selectedIndex = 0; return }
        var index = Math.min(Math.max(root.selectedIndex, 0), count - 1)
        for (var i = 0; i < count; i++) {
            if (!displayModel.get(index).disabled) { root.selectedIndex = index; return }
            index = (index + 1) % count
        }
        root.cursorActive = false
    }

    // ---------------------------------------------------------- navigation
    function setActiveMenu(id, pushHistory) {
        root.freezeCardTop()
        if (!root.items[id]) id = "root"
        if (pushHistory && id !== root.activeMenu) root.navStack = root.navStack.concat([root.activeMenu])
        root.activeMenu = id
        root.filterText = ""
        root.selectedIndex = 0
        root.cursorActive = true
        pointerGate.reset()
        root.rebuildDisplay()
        root.loadProviderForMenu(id)
    }

    function goBack() {
        if (root.activeMenu === "root") return
        if (root.navStack.length > 0) {
            var previous = root.navStack[root.navStack.length - 1]
            root.navStack = root.navStack.slice(0, -1)
            root.setActiveMenu(previous, false)
            return
        }
        var active = root.items[root.activeMenu]
        root.setActiveMenu(active && active.parent ? active.parent : "root", false)
    }

    function setFilter(text) {
        root.freezeCardTop()
        root.filterText = text
        root.selectedIndex = 0
        root.cursorActive = true
        pointerGate.reset()
        if (root.filterText.trim()) root.loadProvidersForSearch()
        root.rebuildDisplay()
    }

    function activateIndex(index) {
        if (index < 0 || index >= displayModel.count) return
        var row = displayModel.get(index)
        if (row.disabled) return
        if (row.kind === "menu" || row.kind === "link") {
            root.setActiveMenu(row.target || row.itemId, true)
        } else if (row.kind === "app") {
            // Start the launch before closing: in the dev preview, closing
            // quits the process, which would kill the async launch job.
            if (root.appsModel && row.appRow >= 0) root.appsModel.trigger(row.appRow, "", null)
            root.close()
        } else {
            var action = row.action
            root.close()
            root.runAction(action)
        }
    }

    function select(delta) {
        var count = displayModel.count
        if (count === 0) return
        pointerGate.reset()
        var from = root.cursorActive ? root.selectedIndex + delta : (delta < 0 ? count - 1 : 0)
        var step = delta < 0 ? -1 : 1
        // Single steps wrap; page steps stop at the ends.
        if (Math.abs(delta) === 1) from = ((from % count) + count) % count
        else from = Math.max(0, Math.min(count - 1, from))
        for (var i = 0; i < count && displayModel.get(from).disabled; i++) from = ((from + step) % count + count) % count
        root.cursorActive = true
        root.selectedIndex = from
        root.revealCursor()
    }

    // Keep the next hidden row peeking past the cursor in the direction of travel.
    function revealCursor() {
        if (displayModel.count === 0) return
        resultList.positionViewAtIndex(root.selectedIndex, ListView.Contain)
        var item = resultList.itemAtIndex(root.selectedIndex)
        if (!item) return
        var reach = root.rowPeek + root.rowSpacing
        if (root.selectedIndex < displayModel.count - 1) {
            var maxY = Math.max(resultList.originY, resultList.originY + resultList.contentHeight - resultList.height)
            var overhang = item.y + item.height + reach - (resultList.contentY + resultList.height)
            if (overhang > 0) resultList.contentY = Math.min(resultList.contentY + overhang, maxY)
        }
        if (root.selectedIndex > 0) {
            var underhang = resultList.contentY - (item.y - reach)
            if (underhang > 0) resultList.contentY = Math.max(resultList.contentY - underhang, resultList.originY)
        }
    }

    // Hover only moves the cursor on real pointer movement, so a list
    // scrolling under a resting pointer doesn't steal the keyboard cursor.
    QtObject {
        id: pointerGate
        property bool primed: false
        property real lastX: 0
        property real lastY: 0
        readonly property real threshold: 2
        function reset() { primed = false }
        function moved(item, mouse) {
            var p = item.mapToItem(card, mouse.x, mouse.y)
            var didMove = primed && (Math.abs(p.x - lastX) > threshold || Math.abs(p.y - lastY) > threshold)
            if (!primed || didMove) { lastX = p.x; lastY = p.y }
            primed = true
            return didMove
        }
    }

    // ---------------------------------------------------------- layout math
    // Row details only show while a search is narrowing the list.
    function rowHeightForDetail(detail) {
        return root.filterText && detail ? root.detailRowHeight : root.baseRowHeight
    }

    function availableRowsHeight() {
        var top = root.frozenTop >= 0 ? root.frozenTop : root.gapsOut
        var available = root.height - top - root.gapsOut - root.contentMargin * 2 - root.headerHeight - root.contentSpacing
        if (root.frozenRowsHeight >= 0) available = Math.min(available, root.frozenRowsHeight)
        // A card that swallows the whole screen reads as a page, not a menu.
        return Math.min(available, Math.round(root.height * 0.7))
    }

    // When rows don't all fit, end the card mid-row: the clipped row is what
    // tells the eye there is more below.
    function foldedListHeight(totals, available) {
        var count = totals.length
        if (count === 0) return root.baseRowHeight
        if (totals[count - 1] <= available) return totals[count - 1]
        var full = 0
        while (full < count && totals[full] <= available) full++
        while (full > 1 && totals[full - 1] + root.rowSpacing + root.rowPeek > available) full--
        if (full < 1) return Math.max(available, root.baseRowHeight)
        return totals[full - 1] + root.rowSpacing + root.rowPeek
    }

    function rowListHeight(_serial, _filter, _h) {
        if (displayModel.count === 0) return root.baseRowHeight
        var totals = [], total = 0, previousSection = ""
        for (var i = 0; i < displayModel.count; i++) {
            var row = displayModel.get(i)
            if (i > 0) total += root.rowSpacing
            if (row.section === "drilldown" && previousSection !== "drilldown") total += root.dividerHeight
            total += root.rowHeightForDetail(row.detail)
            previousSection = row.section
            totals.push(total)
        }
        return root.foldedListHeight(totals, root.availableRowsHeight())
    }

    readonly property int visibleRowsHeight: rowListHeight(layoutSerial, filterText, height)
    readonly property int cardHeight: Math.min(contentMargin * 2 + headerHeight + contentSpacing + visibleRowsHeight,
                                               height - gapsOut * 2)
    readonly property int centeredTop: Math.max(gapsOut, Math.round((height - cardHeight) / 2))
    readonly property int cardTop: frozenTop >= 0 ? frozenTop : centeredTop

    function freezeCardTop() {
        if (root.visible && root.frozenTop < 0) {
            root.frozenTop = root.cardTop
            root.frozenRowsHeight = root.visibleRowsHeight
        }
    }

    // ---------------------------------------------------------- visuals
    Rectangle {
        anchors.fill: parent
        color: root.scrim
    }

    MouseArea {
        anchors.fill: parent
        onClicked: root.close()
    }

    Rectangle {
        id: card
        width: root.cardWidth
        height: Math.min(root.cardHeight, root.height - root.gapsOut - root.cardTop)
        anchors.horizontalCenter: parent.horizontalCenter
        y: root.cardTop
        color: root.cardBackground
        radius: root.cornerRadius
        border.color: root.cardBorder
        border.width: root.borderWidth

        MouseArea { anchors.fill: parent }   // swallow clicks so they don't close

        Item {
            id: keyCatcher
            anchors.fill: parent
            focus: true

            Keys.priority: Keys.BeforeItem
            Keys.onPressed: function (event) {
                var mods = event.modifiers
                if (event.key === Qt.Key_Escape) {
                    if (root.filterText) root.setFilter("")
                    else root.close()
                } else if (root.filterText && !(mods & (Qt.AltModifier | Qt.MetaModifier))
                           && ((event.key === Qt.Key_U && mods === Qt.ControlModifier) || event.key === Qt.Key_Backspace)) {
                    if (event.key === Qt.Key_U) root.setFilter("")
                    else if (mods & Qt.ControlModifier) root.setFilter(root.filterText.replace(/\s+$/, "").replace(/\S+$/, ""))
                    else root.setFilter(root.filterText.slice(0, -1))
                } else if ((event.key === Qt.Key_Backspace || event.key === Qt.Key_Left) && !root.filterText) {
                    root.goBack()
                } else if (event.key === Qt.Key_Up) {
                    root.select(-1)
                } else if (event.key === Qt.Key_Down) {
                    root.select(1)
                } else if (event.key === Qt.Key_PageUp) {
                    root.select(-6)
                } else if (event.key === Qt.Key_PageDown) {
                    root.select(6)
                } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter || event.key === Qt.Key_Right) {
                    root.activateIndex(root.cursorActive ? root.selectedIndex : 0)
                } else if (event.text && event.text.length === 1 && event.text.charCodeAt(0) >= 32
                           && event.text.charCodeAt(0) !== 127
                           && (mods === Qt.NoModifier || mods === Qt.ShiftModifier)) {
                    root.setFilter(root.filterText + event.text)
                } else {
                    return
                }
                event.accepted = true
            }
        }

        Column {
            anchors.fill: parent
            anchors.margins: root.contentMargin
            spacing: root.contentSpacing

            // Header: "<menu>…" until you type, then the search text itself.
            Item {
                width: parent.width
                height: root.headerHeight

                Text {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    textFormat: Text.PlainText
                    text: {
                        if (root.filterText) return root.filterText
                        var entry = root.items[root.activeMenu]
                        return (entry ? (entry.title || entry.label) : "Go") + "…"
                    }
                    color: root.foreground
                    opacity: root.filterText ? 1 : 0.58
                    font.family: root.fontFamily
                    font.pixelSize: root.fontHeading
                    elide: Text.ElideRight
                }
            }

            Item {
                width: parent.width
                height: root.visibleRowsHeight

                ListView {
                    id: resultList
                    anchors.fill: parent
                    model: displayModel
                    clip: true
                    spacing: root.rowSpacing
                    boundsBehavior: Flickable.StopAtBounds

                    section.property: "section"
                    section.criteria: ViewSection.FullString
                    section.delegate: Item {
                        required property string section
                        width: ListView.view.width
                        height: section === "drilldown" ? root.dividerHeight : 0
                        visible: section === "drilldown"
                        Rectangle {
                            anchors { left: parent.left; right: parent.right; leftMargin: root.space(4); rightMargin: root.space(4); verticalCenter: parent.verticalCenter }
                            height: root.space(1)
                            color: Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, 0.2)
                        }
                    }

                    delegate: Rectangle {
                        id: row
                        required property int index
                        required property string kind
                        required property string icon
                        required property string appIcon
                        required property string label
                        required property string detail
                        required property bool disabled

                        readonly property bool hasCursor: root.cursorActive && row.index === root.selectedIndex
                        readonly property bool isApp: row.kind === "app"
                        readonly property bool hasIcon: row.icon.length > 0 || row.isApp
                        readonly property bool isMenu: row.kind === "menu" || row.kind === "link"

                        width: ListView.view.width
                        height: root.rowHeightForDetail(row.detail)
                        opacity: row.disabled ? 0.4 : 1
                        radius: root.cornerRadius
                        color: row.hasCursor ? root.selectedBackground : "transparent"

                        Text {
                            id: glyph
                            visible: row.hasIcon && !row.isApp
                            textFormat: Text.PlainText
                            text: row.icon
                            color: row.hasCursor ? root.selectedText : root.foreground
                            font.family: root.fontFamily
                            font.pixelSize: root.iconLarge
                            width: root.space(36)
                            horizontalAlignment: Text.AlignHCenter
                            anchors.left: parent.left
                            anchors.leftMargin: root.space(8)
                            y: contentColumn.y + labelText.y + (labelText.height - height) / 2
                        }

                        Kirigami.Icon {
                            visible: row.isApp
                            width: root.iconLarge
                            height: root.iconLarge
                            source: row.appIcon || "application-x-executable"
                            anchors.left: parent.left
                            anchors.leftMargin: root.space(8) + (root.space(36) - width) / 2
                            y: contentColumn.y + labelText.y + (labelText.height - height) / 2
                        }

                        Column {
                            id: contentColumn
                            anchors.left: parent.left
                            anchors.leftMargin: row.hasIcon ? root.space(8) + root.space(36) + root.space(6) : root.space(18)
                            anchors.right: trail.left
                            anchors.rightMargin: root.space(6)
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: root.space(3)

                            Text {
                                id: labelText
                                width: parent.width
                                textFormat: Text.PlainText
                                text: row.label
                                color: row.hasCursor ? root.selectedText : root.foreground
                                font.family: root.fontFamily
                                font.pixelSize: root.fontHeading
                                font.weight: Font.Medium
                                elide: Text.ElideRight
                            }

                            Text {
                                width: parent.width
                                textFormat: Text.PlainText
                                text: row.detail
                                visible: root.filterText.length > 0 && row.detail.length > 0
                                color: root.foreground
                                opacity: 0.52
                                font.family: root.fontFamily
                                font.pixelSize: root.fontBodySmall
                                elide: Text.ElideRight
                            }
                        }

                        Text {
                            id: trail
                            width: root.space(14)
                            anchors.right: parent.right
                            anchors.rightMargin: root.space(8)
                            y: contentColumn.y + labelText.y + (labelText.height - height) / 2
                            textFormat: Text.PlainText
                            text: row.isMenu ? "›" : ""
                            color: row.hasCursor ? root.selectedText : root.foreground
                            opacity: 0.36
                            font.family: root.fontFamily
                            font.pixelSize: root.fontHeading
                        }

                        MouseArea {
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: row.disabled ? Qt.ArrowCursor : Qt.PointingHandCursor
                            onPositionChanged: function (mouse) {
                                if (!row.disabled && pointerGate.moved(row, mouse)) {
                                    root.cursorActive = true
                                    root.selectedIndex = row.index
                                }
                            }
                            onClicked: if (!row.disabled) root.activateIndex(row.index)
                        }
                    }
                }

                // Scroll scrims: fade content hidden past either edge.
                Rectangle {
                    anchors { left: parent.left; right: parent.right; top: parent.top }
                    height: Math.min(root.space(28), parent.height / 2)
                    visible: opacity > 0
                    opacity: resultList.contentHeight > resultList.height
                             ? Math.max(0, Math.min(1, (resultList.contentY - resultList.originY) / height)) : 0
                    gradient: Gradient {
                        GradientStop { position: 0; color: root.cardBackground }
                        GradientStop { position: 1; color: Qt.rgba(root.cardBackground.r, root.cardBackground.g, root.cardBackground.b, 0) }
                    }
                }

                Rectangle {
                    anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
                    height: Math.min(root.space(28), parent.height / 2)
                    visible: opacity > 0
                    opacity: resultList.contentHeight > resultList.height
                             ? Math.max(0, Math.min(1, (resultList.originY + resultList.contentHeight - resultList.height - resultList.contentY) / height)) : 0
                    gradient: Gradient {
                        GradientStop { position: 0; color: Qt.rgba(root.cardBackground.r, root.cardBackground.g, root.cardBackground.b, 0) }
                        GradientStop { position: 1; color: root.cardBackground }
                    }
                }

                Column {
                    anchors.centerIn: parent
                    spacing: root.space(8)
                    visible: displayModel.count === 0

                    Text {
                        width: root.space(260)
                        horizontalAlignment: Text.AlignHCenter
                        text: "󰈉"
                        color: root.selectedText
                        opacity: 0.8
                        font.family: root.fontFamily
                        font.pixelSize: root.fontPx(2.333)
                    }

                    Text {
                        width: root.space(260)
                        horizontalAlignment: Text.AlignHCenter
                        wrapMode: Text.Wrap
                        textFormat: Text.PlainText
                        text: root.filterText ? "No matches for “" + root.filterText + "”" : "Nothing here yet"
                        color: root.foreground
                        opacity: 0.7
                        font.family: root.fontFamily
                        font.pixelSize: root.fontTitle
                    }
                }
            }
        }
    }
}
