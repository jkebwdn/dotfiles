import QtQuick
import Quickshell
import "../../.config/quickshell/magi/components/clipboard" as ClipboardUI

ShellRoot {
    QtObject {
        id: mock
        property var rows: [{id:"one",category:"text",preview:"<b>Literal sample</b>",timestamp:1,pinned:false,thumbnail:""},
            {id:"two",category:"files",preview:"file:///harmless",timestamp:2,pinned:true,thumbnail:""}]
        property int count: rows.length
        property var preferences: ({enabled:true,persistHistory:false})
        property bool opened: true
        property bool ready: true
        property bool monitoring: true
        property string query: ""
        property string error: ""
        property string result: ""
        function restore(id) { result = "restore:" + id }
        function remove(id) { result = "delete:" + id }
        function pin(id) { result = "pin:" + id }
        function clear() { rows = [] }
    }
    FloatingWindow {
        visible: true; implicitWidth: 540; implicitHeight: 660
        ClipboardUI.ClipboardContent { id: ui; anchors.fill: parent; service: mock }
    }
    Timer {
        interval: 350; running: true
        onTriggered: {
            function check(value) { if (!value) throw new Error("Clipboard UI assertion") }
            function key(code, modifiers) { ui.navigate({key:code,modifiers:modifiers || 0,accepted:false}) }
            ui.begin(); check(ui.selectedId === "one")
            key(Qt.Key_Down); check(ui.selectedId === "two")
            key(Qt.Key_Return); check(mock.result === "restore:two")
            key(Qt.Key_P, Qt.ControlModifier); check(mock.result === "pin:two")
            key(Qt.Key_Delete, Qt.ControlModifier); check(mock.result === "delete:two")
            key(Qt.Key_Up); check(ui.selectedId === "one")
            mock.rows = [mock.rows[1]]; check(ui.selectedId === "two")
            mock.clear(); check(ui.selectedId === "")
            key(Qt.Key_Return); key(Qt.Key_Down); check(ui.selectedId === "")
            key(Qt.Key_Escape); check(mock.opened === false)
            console.log("Clipboard UI navigation, empty, selection reconciliation PASS")
            Qt.quit()
        }
    }
}
