pragma ComponentBehavior: Bound
import QtQuick
import Quickshell

FloatingWindow {
    id: root
    required property var service
    title: "MAGI Clipboard"
    implicitWidth: Math.min(540, screen ? screen.width - 32 : 540)
    implicitHeight: Math.min(660, screen ? screen.height - 96 : 660)
    minimumSize: Qt.size(400, 360)
    color: "transparent"
    visible: service.opened && !service.fullscreen
    onVisibleChanged: {
        if (visible) Qt.callLater(content.begin)
        // A native close can change visibility independently of the model.
        // Defer reconciliation to avoid re-entering the fullscreen binding.
        else Qt.callLater(() => { if (!root.visible) root.service.opened = false })
    }
    ClipboardContent {
        id: content
        anchors.fill: parent
        service: root.service
    }
}
