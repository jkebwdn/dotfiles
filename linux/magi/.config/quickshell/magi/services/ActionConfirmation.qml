pragma Singleton
import QtQuick
import Quickshell
Scope {
    id: root
    property string armedAction: ""
    readonly property bool armed: armedAction !== ""
    function request(action) {
        if (armedAction === action) { cancel(); return true }
        armedAction = action; expiry.restart(); return false
    }
    function cancel() { armedAction = ""; expiry.stop() }
    Timer { id: expiry; interval: 5000; onTriggered: root.armedAction = "" }
}
