import QtQuick
import Quickshell
import Quickshell.Wayland
import "../../services" as Services
PanelWindow {
    id: root
    readonly property var contentItem: content.item
    property bool readyToOpen: false
    anchors { top: true; bottom: true; left: true; right: true }
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.namespace: "magi-wallpaper"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: visible ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    visible: Services.Wallpaper.opened && readyToOpen
    color: "transparent"
    mask: Region { x: 0; y: 48; width: root.width; height: Math.max(0, root.height - 48) }
    MouseArea { anchors.fill: parent; onPressed: Services.Wallpaper.close() }
    Loader {
        id: content
        active: root.visible
        anchors.centerIn: parent
        width: Math.min(root.width - 32, 1000)
        height: Math.min(root.height - 128, 720)
        sourceComponent: WallpaperContent {}
        onLoaded: item.focusGrid()
    }
}
