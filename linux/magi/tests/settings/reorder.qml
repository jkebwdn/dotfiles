import QtQuick
import QtQuick.Window
import QtTest
import QtQuick.Controls.Basic
import Quickshell
import "../../.config/quickshell/magi/components/settings" as UI
import "../../.config/quickshell/magi/services" as Services
ShellRoot {
    UI.SettingsWindow { id: window }
    Component { id: dialogFixture; Dialog { title: "Close ownership"; modal: true; focus: true; standardButtons: Dialog.Close } }
    Component { id: editorFixture; TextField { Keys.onEscapePressed: event => { text = "cancelled"; event.accepted = true } } }
    Timer { id: finish; interval: 100; onTriggered: Qt.quit() }
    TestCase {
        name: "SettingsReorder"
        when: Services.Settings.ready
        function check(ok, message) { if (!ok) console.error("FAIL: " + message); verify(ok, message) }
        function equal(actual, expected, message) {
            if (actual !== expected && JSON.stringify(actual) !== JSON.stringify(expected))
                console.error("FAIL: " + message + " actual=" + JSON.stringify(actual) + " expected=" + JSON.stringify(expected))
            compare(actual, expected, message)
        }
        function waitFor(object, property, expected) {
            for (let i = 0; i < 100 && object[property] !== expected; ++i) wait(50)
            equal(object[property], expected, "wait for " + property)
        }
        function capture(name) {
            const directory = Quickshell.env("MAGI_SETTINGS_CAPTURES")
            if (directory) grabImage(window.contentItem).save(directory + "/" + name + "-" + window.contentItem.width + ".png")
        }
        function find(name) { const item = findChild(window.contentItem, name); check(item !== null, name); return item }
        function open(name) { Services.SettingsWindowState.page = name; wait(180); return find("settingsPage-" + name) }
        function keyOrder(group) { return Services.Settings.data.controlCentre[group].filter(e => e.enabled).map(e => e.key) }
        function reveal(board, key) {
            wait(140)
            const handle = find(board.objectName + "-handle-" + key)
            const page = board.viewport
            page.contentY = Math.max(0, Math.min(page.contentHeight - page.height,
                handle.mapToItem(page.contentItem, 0, 0).y - page.height / 3))
            wait(180)
            const point = handle.mapToItem(page, handle.width / 2, handle.height / 2)
            check(point.y > 0 && point.y < page.height, "handle visible before press")
            return handle
        }
        function beginDrag(board, key) {
            console.log("DRAG", board.objectName, key)
            const handle = reveal(board, key)
            const point = handle.mapToItem(window.contentItem, handle.width / 2, handle.height / 2)
            mousePress(window.contentItem, point.x, point.y)
            mouseMove(window.contentItem, point.x - 12, point.y, 30)
            waitFor(board, "dragging", true)
            return handle
        }
        function travel(board, laneId, targetKey, after) {
            const page = board.viewport
            let last
            for (let i = 0; i < 140; ++i) {
                const lane = board.geometry.find(l => l.id === laneId)
                const slot = targetKey ? board.location(targetKey) : null
                const x = board.canvasMode && slot ? slot.x + slot.width * (after ? .8 : .2) : lane.x + lane.width / 2
                const y = slot ? slot.y + board.rowHeight * (after ? 0.8 : 0.2)
                    : lane.y + board.inset + board.headingHeight + board.rowHeight / 2
                const point = board.mapToItem(page, x, y)
                const cy = Math.max(10, Math.min(page.height - 10, point.y))
                last = page.mapToItem(window.contentItem, point.x, cy)
                mouseMove(window.contentItem, last.x, last.y, 20)
                wait(20)
                if (point.y >= 32 && point.y <= page.height - 32) {
                    wait(140)
                    check(board.dragging, "pointer grab survives preview reordering")
                    check(find(board.objectName + "-insertion").visible, "insertion indicator visible")
                    equal(board.targetLane, laneId)
                    return last
                }
            }
            console.error("FAIL: autoscroll target", laneId, targetKey, board.targetLane, board.viewport.contentY)
            fail("autoscroll did not reach target")
            return last
        }
        function drag(board, key, lane, target, after) {
            const beforeRevision = Services.Settings.revision
            const handle = beginDrag(board, key)
            const point = travel(board, lane, target, after)
            equal(Services.Settings.revision, beforeRevision, "preview does not persist intermediate positions")
            const indicator = find(board.objectName + "-insertion")
            const indicatorPoint = indicator.mapToItem(board.viewport, 0, 0)
            check(indicatorPoint.x >= 0 && indicatorPoint.x + indicator.width <= board.viewport.width,
                "scrolled drop indicator stays horizontally bounded")
            capture(board.objectName + "-drag")
            mouseRelease(window.contentItem, point.x, point.y)
            wait(180)
            equal(board.dragging, false)
            check(Services.SettingsWindowState.shown, "Escape cancels drag before closing Settings")
            equal(find(board.objectName + "-handle-" + key), handle, "stable delegate survives reorder")
        }
        function keyboard(board, key, code) {
            const handle = reveal(board, key)
            handle.forceActiveFocus(Qt.TabFocusReason)
            keyClick(code, Qt.AltModifier)
            wait(180)
            equal(find(board.objectName + "-handle-" + key), handle)
            check(handle.activeFocus, "focus survives keyboard movement")
            const point = handle.mapToItem(board.viewport, 0, 0)
            check(point.y >= 0 && point.y + handle.height <= board.viewport.height, "keyboard movement reveals the focused row")
        }
        function cc(group, boardName) {
            const board = find(boardName)
            const initial = keyOrder(group)
            const records = JSON.stringify(Services.Settings.data.controlCentre[group].slice().sort((a,b)=>a.key.localeCompare(b.key)))
            drag(board, initial[0], group, initial[initial.length - 1], true)
            equal(keyOrder(group), initial.slice(1).concat(initial[0]), group + " first to last")
            drag(board, initial[0], group, initial[1], false)
            equal(keyOrder(group), initial, group + " last to first")
            drag(board, initial[1], group, initial[initial.length - 1], true)
            keyboard(board, initial[1], Qt.Key_Home)
            equal(keyOrder(group)[0], initial[1])
            keyboard(board, initial[1], Qt.Key_End)
            equal(keyOrder(group).slice(-1)[0], initial[1])
            keyboard(board, initial[1], Qt.Key_Up)
            equal(keyOrder(group)[initial.length - 2], initial[1])
            equal(JSON.stringify(Services.Settings.data.controlCentre[group].slice().sort((a,b)=>a.key.localeCompare(b.key))), records,
                "identity, enabled, accent and extension metadata stay with their key")
            const prior = JSON.stringify(keyOrder(group))
            beginDrag(board, initial[0]); travel(board, group, initial[initial.length - 1], true)
            keyClick(Qt.Key_Escape)
            equal(board.dragging, false)
            check(Services.SettingsWindowState.shown, "Escape cancels drag before closing Settings")
            equal(JSON.stringify(keyOrder(group)), prior, "Escape cancels without mutation")
            mouseRelease(window.contentItem, 1, 1)
            beginDrag(board, initial[0])
            mouseMove(window.contentItem, 5, 5, 30); mouseRelease(window.contentItem, 5, 5)
            wait(140)
            equal(JSON.stringify(keyOrder(group)), prior, "release outside page cancels")
            beginDrag(board, initial[0])
            const position = Services.Settings.data.controlCentre[group].findIndex(e => e.key === initial[0])
            const other = keyOrder(group).find(key => key !== initial[0])
            const destination = Services.Settings.data.controlCentre[group].findIndex(e => e.key === other)
            Services.Settings.moveEntry(group, initial[0], destination - position)
            equal(board.dragging, false, "external ordering change invalidates the preview")
            const external = JSON.stringify(keyOrder(group))
            mouseRelease(window.contentItem, 5, 5)
            equal(JSON.stringify(keyOrder(group)), external, "stale drag cannot overwrite external order")
        }
        function validateBar() {
            const bar = Services.Settings.data.bar
            const ids = bar.left.concat(bar.center, bar.right)
            equal(new Set(ids).size, ids.length, "no duplicate bar module IDs")
            equal(Services.Settings.diagnostics.length, 0, "canonical settings remain valid")
        }
        function test_reordering() {
            Services.SettingsWindowState.shown = true
            for (const size of [Qt.size(720,500), Qt.size(940,720)]) {
                window.contentItem.Window.window.width = size.width
                window.contentItem.Window.window.height = size.height
                waitFor(window.contentItem, "width", size.width)
                waitFor(window.contentItem, "height", size.height)
                Services.Settings.resetSection("controlCentre")
                Services.Settings.setValue("controlCentre", "columns", 7)
                Services.Settings.setValue("controlCentre", "actionColumns", 3)
                Services.Settings.editControl("network", "enabled", false)
                Services.Settings.editControl("wireless", "accent", "red")
                Services.Settings.editEntry("actions", "vpn", "enabled", false)
                open("Control Centre")
                const ccBoard=find("ccModuleBoard")
                check(ccBoard.canonicalKeys("available").includes("wifi"),"disabled module is available")
                const before=Services.Settings.data.controlCentre.controls.find(e=>e.module==="bluetooth")
                ccBoard.request("bluetooth","actions",0,true)
                equal(Services.Settings.data.controlCentre.actions[0].accent,"red","accent follows presentation")
                ccBoard.request("bluetooth","available",0,true)
                check(ccBoard.canonicalKeys("available").includes("bluetooth"))
                ccBoard.request("bluetooth","controls",0,true)
                equal(Services.Settings.data.controlCentre.controls[0].key,before.key,"stable identity")
                equal(Services.Settings.data.controlCentre.columns,7)
                equal(Services.Settings.data.controlCentre.actionColumns,3)
                // Full pointer/race and structural coverage lives in phase12d/presentation.qml.

                Services.Settings.resetSection("bar")
                open("Bar")
                const barBoard = find("barOrder")
                check(barBoard.canvasMode && barBoard.parent.scale <= 1, "responsive fit-to-width canvas")
                barBoard.viewport.contentY = 0; wait(140); capture("bar-arranger")
                drag(barBoard, "clock", "left", "date", true)
                equal(Services.Settings.data.bar.left, ["date", "clock"])
                drag(barBoard, "date", "center", "workspaces", false)
                equal(Services.Settings.data.bar.center, ["date", "workspaces"])
                drag(barBoard, "workspaces", "center", "date", false)
                equal(Services.Settings.data.bar.center, ["workspaces", "date"])
                drag(barBoard, "controlcentre", "right", "volume", false)
                equal(Services.Settings.data.bar.right[0], "controlcentre")
                drag(barBoard, "wifi", "left", "clock", false)
                equal(Services.Settings.data.bar.left, ["wifi", "clock"])
                validateBar()
                drag(barBoard, "wifi", "hidden", null, false)
                check(barBoard.canonicalKeys("hidden").includes("wifi"), "pointer hide preserves availability")
                drag(barBoard, "wifi", "left", "clock", false)
                equal(Services.Settings.data.bar.left, ["wifi", "clock"])
                keyboard(barBoard, "wifi", Qt.Key_Down)
                equal(Services.Settings.data.bar.left, ["clock", "wifi"])
                keyboard(barBoard, "wifi", Qt.Key_Right)
                equal(Services.Settings.data.bar.center.slice(-1)[0], "wifi")
                keyboard(barBoard, "wifi", Qt.Key_Right)
                keyboard(barBoard, "wifi", Qt.Key_Right)
                check(!Services.Settings.data.bar.right.includes("wifi"), "keyboard hide")
                check(barBoard.canonicalKeys("hidden").includes("wifi"))
                drag(barBoard, "wifi", "left", "clock", false)
                equal(Services.Settings.data.bar.left, ["wifi", "clock"], "hidden module re-adds by drag")
                validateBar()
                waitFor(Services.Settings, "saveState", "saved")
                const savedBar = JSON.stringify(Services.Settings.data.bar)
                const savedSecondary = JSON.stringify(Services.Settings.data.controlCentre.actions)
                const savedPrimary = JSON.stringify(Services.Settings.data.controlCentre.controls)
                Services.Settings.discardAndReload()
                waitFor(Services.Settings, "ready", true)
                equal(JSON.stringify(Services.Settings.data.bar), savedBar, "bar order persists")
                equal(JSON.stringify(Services.Settings.data.controlCentre.controls), savedPrimary, "control order persists")
                equal(JSON.stringify(Services.Settings.data.controlCentre.actions), savedSecondary, "action order persists")
                beginDrag(barBoard, "clock")
                open("Profile")
                equal(barBoard.dragging, false, "page navigation cancels the drag")
                mouseRelease(window.contentItem, 5, 5)
                equal(JSON.stringify(Services.Settings.data.bar), savedBar)
            }
            const dialog = createTemporaryObject(dialogFixture, window.contentItem)
            dialog.open(); wait(100)
            keyClick(Qt.Key_Escape); wait(100)
            check(!dialog.visible, "dialog consumes Escape")
            check(Services.SettingsWindowState.shown, "dialog Escape does not close Settings")
            const editor = createTemporaryObject(editorFixture, find("settingsApplicationPane"))
            editor.forceActiveFocus(Qt.TabFocusReason)
            keyClick(Qt.Key_Escape)
            equal(editor.text, "cancelled", "text edit consumes its cancellation")
            check(Services.SettingsWindowState.shown, "text cancellation leaves Settings open")
            const nav = find("settingsNav-Profile")
            nav.forceActiveFocus(Qt.TabFocusReason)
            keyClick(Qt.Key_Escape)
            waitFor(Services.SettingsWindowState, "shown", false)
            Services.SettingsWindowState.shown = true
            open("Bar")
            find("barOrder-handle-clock").forceActiveFocus(Qt.TabFocusReason)
            keyClick(Qt.Key_Escape)
            waitFor(Services.SettingsWindowState, "shown", false)
            console.log("RESULT: 0 failures; production drag, keyboard, cancel, scroll, metadata and persistence")
            finish.start()
        }
    }
}
