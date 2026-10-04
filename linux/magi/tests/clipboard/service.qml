import QtQuick
import Quickshell
import "../../.config/quickshell/magi/services" as Services
ShellRoot {
    Timer {
        interval: 350; running: true
        onTriggered: {
            function check(value) { if (!value) throw new Error("Clipboard service assertion") }
            const service = Services.Clipboard
            check(!service.activated && !service.monitoring)
            service.ready = true
            service.query = "new query"
            service.renderedQuery = "old query"
            service.restore("test-id")
            check(!service.restoring)
            service.opened = true
            service.fullscreen = true
            check(!service.opened)
            service.toggle()
            check(!service.opened)
            service.fullscreen = false
            check(!service.opened)
            console.log("Clipboard service import isolation, stale-search guard, fullscreen close/recovery PASS")
            Qt.quit()
        }
    }
}
