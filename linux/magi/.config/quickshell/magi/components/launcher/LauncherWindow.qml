import QtQuick
import Quickshell
import Quickshell.Wayland
PanelWindow {
    id: root
    required property var service
    anchors { top: true; bottom: true; left: true; right: true }
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.namespace: "magi-launcher"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: visible ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    visible: service.opened
    color: "transparent"
    onVisibleChanged: { if (visible) Qt.callLater(() => content.focusSearch()) }
    MouseArea { anchors.fill: parent; onPressed: root.service.close() }
    LauncherContent {
        id: content
        service: root.service
        width: Math.min(parent.width - 32, service.preferences.layout === "grid" ? service.preferences.gridWidth : service.preferences.panelWidth)
        height: Math.min(parent.height - 96, desiredHeight)
        x: (parent.width - width) / 2
        y: service.preferences.position === "top" ? 64 : (parent.height - height) / 2
    }
}
