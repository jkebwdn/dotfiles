import QtQuick
import Quickshell
import Quickshell.Wayland
// Temporary presentation host. Future HubWindow can host EmojiContent directly.
PanelWindow {
    id: root
    required property var service
    anchors { top: true; bottom: true; left: true; right: true }
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.namespace: "magi-emoji"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: visible ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    visible: service.opened
    color: "transparent"
    onVisibleChanged: { if (visible) Qt.callLater(() => content.focusSearch()) }
    MouseArea { anchors.fill: parent; onPressed: root.service.close() }
    EmojiContent {
        id: content
        service: root.service
        width: Math.min(parent.width - 32, service.preferences.gridColumns * (service.preferences.emojiSize + 24) + 32)
        height: Math.min(parent.height - 96, desiredHeight)
        x: (parent.width - width) / 2; y: (parent.height - height) / 2
    }
}
