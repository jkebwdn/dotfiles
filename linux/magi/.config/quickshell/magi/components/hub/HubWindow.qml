pragma ComponentBehavior: Bound
import QtQuick
import "."
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import "../../services" as Services

PanelWindow {
    id: root
    property bool readyToOpen: true
    property alias content: content
    anchors { top: true; bottom: true; left: true; right: true }
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.namespace: "magi-hub"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: visible ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    visible: Services.Hub.opened && !Services.Hub.suppressed && readyToOpen
    color: "transparent"
    // Leave the bar reachable for direct anchored-surface handoff.
    mask: Region { x: 0; y: 48; width: root.width; height: Math.max(0, root.height - 48) }
    onVisibleChanged: { if (visible) Qt.callLater(content.focusMode) }
    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
        onPressed: Services.Hub.close()
    }
    IpcHandler {
        target: "hubWindow"
        function status(): string {
            const item = content.currentContent
            return JSON.stringify({visible:root.visible, mode:content.mode,
                x:content.x, y:content.y, width:content.width, height:content.height,
                focused:content.mode === "notifications" ? item.activeFocus : item.searchField.activeFocus})
        }
    }
    HubContent {
        id: content
        width: Math.min(parent.width - 32, preferredWidth)
        height: Math.min(parent.height - 96, preferredHeight)
        x: (parent.width - width) / 2
        y: mode === "apps" && launcherPreferences.position === "top" ? 64 : Math.max(64, (parent.height - height) / 2)
    }
}
