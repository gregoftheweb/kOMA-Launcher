// Unit tests for MenuModel.js (menu parsing, merging, routing, visibility, search).
//   make test   (runs qmltestrunner on this folder)
import QtQuick
import QtTest
import "../contents/ui/MenuModel.js" as M

TestCase {
    name: "MenuModel"

    // a small menu: root > system > {lock, power > off}, plus a link and an app
    function sample() {
        var defs = {
            "root": {
                "label": "Go"
            },
            "system": {
                "label": "System",
                "aliases": ["power-menu"]
            },
            "system.lock": {
                "label": "Lock",
                "action": "lock",
                "description": "lock the screen"
            },
            "system.power": {
                "label": "Power"
            },
            "system.power.off": {
                "label": "Shutdown",
                "action": "off"
            },
            "shortcut": {
                "label": "Quick Power",
                "target": "system.power"
            },
            "empty": {
                "label": "Nothing Here"
            }
        }
        var list = []
        for (var id in defs)
            list.push(M.normalizeItem(id, defs[id]))
        return M.mergeMenuSources(list, [])
    }

    function test_stripJsonc() {
        compare(M.stripJsonc('// c\n{"a": 1,\n  // x\n "b": [1, 2,],\n}'), '{"a": 1,\n "b": [1, 2]\n}')
    }

    function test_parseMenuJsonc_items_wrapper_and_plain_map() {
        var a = M.parseMenuJsonc('{"items": {"x": {"label": "X"}}}')
        compare(a.length, 1)
        compare(a[0].label, "X")
        var b = M.parseMenuJsonc('// mine\n{"y": {"action": "true"}, "skip": [1], "nil": null,}')
        compare(b.length, 1)
        compare(b[0].kind, "action")
    }

    function test_parseMenuJsonc_rejects_junk() {
        compare(M.parseMenuJsonc("").length, 0)
        compare(M.parseMenuJsonc("{not json").length, 0)
        compare(M.parseMenuJsonc("[1, 2]").length, 0)
    }

    function test_normalizeItem_infers_parent_and_kind() {
        var a = M.normalizeItem("style.theme.dark", {
            "action": "x"
        })
        compare(a.parent, "style.theme")
        compare(a.kind, "action")
        compare(a.label, "style.theme.dark")
        compare(M.normalizeItem("top", {}).parent, "root")
        compare(M.normalizeItem("root", {}).parent, "")
        compare(M.normalizeItem("l", {
            "target": "system"
        }).kind, "link")
        compare(M.normalizeItem("m", {
            "aliases": "one"
        }).aliases, ["one"])
    }

    function test_mergeMenuSources_user_overrides_and_keeps_order() {
        var defaults = [M.normalizeItem("a", {
                "label": "A",
                "icon": "1"
            }), M.normalizeItem("b", {
                "label": "B"
            })]
        var user = [
            {
                "id": "a",
                "label": "Mine"
            },
            M.normalizeItem("c", {
                "label": "C"
            })]
        var m = M.mergeMenuSources(defaults, user)
        compare(m.items.a.label, "Mine")
        compare(m.items.a.icon, "1")
        // untouched fields kept
        compare(m.itemOrder, ["root", "a", "b", "c"])
        // root added when missing
        compare(m.items.c.order, 3)
    }

    function test_mergeAppRows_replaces_apps_drops_orphans_and_duplicates() {
        var m = sample()
        var withApps = M.mergeAppRows(m.items, m.itemOrder, [
            {
                "id": "app.one",
                "kind": "app",
                "label": "One"
            },
            {
                "id": "app.one",
                "kind": "app",
                "label": "Dup"
            }
        ])
        compare(withApps.itemOrder.filter(i => i === "app.one").length, 1)
        // "ghost" is an orphan id: listed but with no item behind it
        var order = withApps.itemOrder.concat(["ghost"])
        var again = M.mergeAppRows(withApps.items, order, [
            {
                "id": "app.two",
                "kind": "app",
                "label": "Two"
            }
        ])
        verify(!again.items["app.one"])
        verify(again.items["app.two"])
        verify(again.itemOrder.indexOf("ghost") < 0)
        verify(m.items["app.one"] === undefined)
        // inputs never written into
    }

    function test_swapProviderRows_only_touches_its_own_rows() {
        var m = sample()
        var one = M.swapProviderRows(m.items, m.itemOrder, "themes", [
            {
                "id": "t1",
                "label": "T1"
            }
        ])
        var two = M.swapProviderRows(one.items, one.itemOrder, "themes", [
            {
                "id": "t2",
                "label": "T2"
            }
        ])
        verify(!two.items.t1)
        compare(two.items.t2.providerMenu, "themes")
        verify(two.items["system.lock"])
    }

    function test_resolveRoute() {
        var m = sample()
        compare(M.resolveRoute(m.items, m.itemOrder, ""), "root")
        compare(M.resolveRoute(m.items, m.itemOrder, "menu"), "root")
        compare(M.resolveRoute(m.items, m.itemOrder, "system.lock"), "system.lock")
        compare(M.resolveRoute(m.items, m.itemOrder, "POWER_MENU"), "system")
        compare(M.resolveRoute(m.items, m.itemOrder, "nope"), "nope")
        // app aliases never shadow a route
        var apps = M.mergeAppRows(m.items, m.itemOrder, [
            {
                "id": "app.htop",
                "kind": "app",
                "label": "htop",
                "aliases": ["power-menu"]
            }
        ])
        compare(M.resolveRoute(apps.items, apps.itemOrder, "power-menu"), "system")
        // an alias only an app has (a .desktop keyword) is not a route at all
        var kw = M.mergeAppRows(m.items, m.itemOrder, [
            {
                "id": "app.top",
                "kind": "app",
                "label": "top",
                "aliases": ["monitor"]
            }
        ])
        compare(M.resolveRoute(kw.items, kw.itemOrder, "monitor"), "monitor")
    }

    function test_paths_and_depth() {
        var m = sample()
        compare(M.depthFor(m.items, "system.power.off"), 2)
        compare(M.pathFor(m.items, "system.power.off"), "System › Power › Shutdown")
        compare(M.parentPathFor(m.items, "system.power.off"), "System › Power")
        compare(M.parentPathFor(m.items, "system"), "")
        verify(M.isDescendantOf(m.items, "system.power.off", "system"))
        verify(!M.isDescendantOf(m.items, "system", "system.power"))
        compare(M.childCount(m.items, m.itemOrder, "system"), 2)
        compare(M.slugify("  Hello, World!  "), "hello-world")
        compare(M.slugify("!!!"), "item")
    }

    function test_isVisible_hides_empty_menus_and_failed_guards() {
        var m = sample()
        verify(M.isVisible(m.items, m.itemOrder, {}, m.items.system, 0))
        verify(!M.isVisible(m.items, m.itemOrder, {}, m.items.empty, 0))
        verify(M.isVisible(m.items, m.itemOrder, {}, m.items.shortcut, 0))
        // link to a menu with children
        m.items["system.lock"].when = "test -x /bin/true"
        verify(!M.isVisible(m.items, m.itemOrder, {
            "system.lock": false
        }, m.items["system.lock"], 0))
    }

    function test_labels_mark_checked_and_disabled_rows() {
        var e = M.normalizeItem("x", {
            "label": "Tiling",
            "checked": "probe",
            "disabled": "probe"
        })
        compare(M.labelFor(e, {
            "x": true
        }, {}), "Tiling ✓")
        compare(M.labelFor(e, {}, {}), "Tiling")
        verify(M.isDisabled({
            "x": true
        }, e))
        compare(M.labelFor(e, {}, {
            "x": true
        }), "Tiling ✓")
    }

    function test_matchesQuery_names_and_whole_word_descriptions() {
        var m = sample()
        var lock = m.items["system.lock"]
        verify(M.matchesQuery(lock, "loc", true))
        verify(M.matchesQuery(lock, "screen", true))
        // whole word in description
        verify(!M.matchesQuery(lock, "scre", true))
        // partial description word
        verify(!M.matchesQuery(lock, "lock", false))
        // hidden rows never match
        verify(!M.matchesQuery(m.items.root, "go", true))
    }

    function test_searchScore_ranks_exact_then_prefix_then_contains() {
        var m = sample()
        var exact = M.searchScore(m.items, m.items["system.lock"], "lock")
        var prefix = M.searchScore(m.items, m.items["system.power.off"], "shut")
        var contains = M.searchScore(m.items, m.items["system.power.off"], "down")
        verify(exact < prefix)
        verify(prefix < contains)
    }
}
