import QtQuick
import Quickshell.Hyprland
import "../../services/NotificationPolicy.js" as Policy

QtObject {
    id: root
    required property var screen
    readonly property var monitor: screen ? Hyprland.monitorFor(screen) : null
    readonly property bool suppressed: !monitor || Hyprland.toplevels.values.some(
        t => Policy.isFullscreen(t.lastIpcObject, monitor.lastIpcObject))
    function refresh() {
        Hyprland.refreshMonitors()
        Hyprland.refreshToplevels()
    }
    Component.onCompleted: refresh()
    property Connections events: Connections {
        target: Hyprland
        function onRawEvent(event) {
            if (["fullscreen", "workspace", "workspacev2", "focusedmon", "movewindow",
                    "movewindowv2", "openwindow", "closewindow", "activespecial", "activespecialv2",
                    "monitoradded", "monitorremoved"].indexOf(event.name) >= 0) Qt.callLater(root.refresh)
        }
    }
}
