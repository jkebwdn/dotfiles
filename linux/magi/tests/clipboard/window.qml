import QtQuick
import Quickshell
import "../../.config/quickshell/magi/components/clipboard" as ClipboardUI
ShellRoot {
    QtObject {
        id: mock
        property var rows: []
        property int count: 0
        property var preferences: ({enabled:true,persistHistory:false})
        property bool opened: true
        property bool fullscreen: false
        onFullscreenChanged: { if (fullscreen) opened = false }
        property bool ready: true
        property bool monitoring: true
        property string query: ""
        property string error: ""
        function clear() {}
    }
    ClipboardUI.ClipboardWindow { id: window; service: mock }
    Timer {
        interval: 350; running: true
        onTriggered: {
            function check(value) { if (!value) throw new Error("Clipboard window assertion") }
            check(window.visible && window.title === "MAGI Clipboard")
            mock.fullscreen = true
            check(!window.visible && !mock.opened)
            mock.fullscreen = false
            check(!window.visible)
            mock.opened = true
            check(window.visible)
            window.visible = false
            Qt.callLater(() => {
                check(!mock.opened)
                console.log("Clipboard floating window visibility, fullscreen and native-close state PASS")
                Qt.quit()
            })
        }
    }
}
