// Consistency checks for the built-in menu (DefaultMenu.js): every entry is
// reachable and well-formed, so a typo in an id or target fails CI, not users.
import QtQuick
import QtTest
import "../contents/ui/DefaultMenu.js" as D
import "../contents/ui/MenuModel.js" as M

TestCase {
    name: "DefaultMenu"

    function merged() {
        var list = []
        for (var id in D.ITEMS)
            list.push(M.normalizeItem(id, D.ITEMS[id]))
        return M.mergeMenuSources(list, [])
    }

    function test_has_the_omarchy_top_level() {
        var m = merged()
        var top = m.itemOrder.filter(id => m.items[id].parent === "root").map(id => m.items[id].label)
        for (var label of ["Apps", "Learn", "Trigger", "Style", "Setup", "System"])
            verify(top.indexOf(label) >= 0, "missing top-level " + label)
        verify(m.itemOrder.length > 50)
    }

    function test_every_parent_exists() {
        var m = merged()
        for (var id of m.itemOrder) {
            var p = m.items[id].parent
            verify(p === "" || m.items[p] !== undefined, id + " has missing parent " + p)
        }
    }

    function test_links_point_at_real_entries() {
        var m = merged()
        for (var id of m.itemOrder) {
            var e = m.items[id]
            if (e.kind === "link")
                verify(m.items[e.target] !== undefined, id + " links to missing " + e.target)
        }
    }

    function test_every_entry_has_a_label_and_menus_have_children() {
        var m = merged()
        for (var id of m.itemOrder) {
            var e = m.items[id]
            verify(e.label && e.label !== id || id === "root", id + " has no label")
            if (e.kind === "menu" && !e.provider && id !== "root")
                verify(M.childCount(m.items, m.itemOrder, id) > 0, id + " is an empty menu")
        }
    }

    function test_aliases_are_unique_and_do_not_shadow_ids() {
        var m = merged()
        var seen = {}
        for (var id of m.itemOrder) {
            for (var a of m.items[id].aliases) {
                var key = a.toLowerCase()
                verify(seen[key] === undefined, "alias " + a + " used by " + seen[key] + " and " + id)
                verify(m.items[key] === undefined || key === id, "alias " + a + " shadows an id")
                seen[key] = id
                compare(M.resolveRoute(m.items, m.itemOrder, a), id)
            }
        }
    }

    function test_every_provider_has_an_action_and_icon() {
        var m = merged()
        for (var id of m.itemOrder) {
            var p = m.items[id].provider
            if (!p || p === "apps")
                continue
            verify(typeof D.PROVIDER_ACTIONS[p] === "function", "no action for provider " + p)
            verify(D.PROVIDER_ICONS[p] !== undefined, "no icon for provider " + p)
        }
    }

    function test_provider_actions_quote_their_value() {
        var q = v => "'" + String(v).replace(/'/g, "'\\''") + "'"
        var evil = "x'; rm -rf ~; echo '"
        for (var p in D.PROVIDER_ACTIONS) {
            var cmd = D.PROVIDER_ACTIONS[p](evil, q)
            if (cmd)
                verify(cmd.indexOf(q(evil)) >= 0, p + " does not quote its value: " + cmd)
        }
    }
}
