pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Window
import "."
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import "../../services" as Services

PanelWindow {
    id: root
    property bool readyToOpen: true
    property alias content: content
    property Item previewSurface: null
    property bool presented: false
    TransformWatcher { id: previewWatch; a: root.previewSurface; b: root.previewSurface ? root.previewSurface.Window.window.contentItem : null }
    readonly property bool previewPinned: Services.SettingsWindowState.controlCentrePreview && Services.Hub.mode === "settings"
    readonly property point previewOrigin: {
        const transform = previewWatch.transform
        return previewSurface ? previewSurface.mapToItem(null, 0, 0) : Qt.point(width, 0)
    }
    // Logical output coordinates; independent of the active mode's dimensions.
    readonly property real selectorAnchorY: Math.max(120, Math.min(height - 60, height * 2 / 3))
    anchors { top: true; bottom: true; left: true; right: true }
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.namespace: "magi-hub"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: visible ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    visible: Services.Hub.opened && !Services.Hub.suppressed && (readyToOpen || presented || previewPinned)
    color: "transparent"
    // Leave the bar reachable for direct anchored-surface handoff.
    mask: Region {
        x: 0; y: 48; width: root.width; height: Math.max(0, root.height - 48)
        // Let pointer events reach the real, lower bar layer during preview.
        Region {
            x: root.previewOrigin.x; y: root.previewOrigin.y
            width: root.previewPinned && root.previewSurface ? root.previewSurface.width : 0
            height: root.previewPinned && root.previewSurface ? root.previewSurface.height : 0
            intersection: Intersection.Subtract
        }
    }
    onVisibleChanged: { if (visible) { presented = true; Qt.callLater(content.focusMode) } }
    Connections {
        target: Services.Hub
        function onOpenedChanged() { if (!Services.Hub.opened) root.presented = false }
    }
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
                focused:!!item && (content.mode === "notifications" || content.mode === "settings" ? item.activeFocus : item.searchField.activeFocus)})
        }
    }
    HubContent {
        id: content
        outputWidth: root.width
        width: Math.max(240, Math.min(parent.width - 32, preferredWidth,
            root.previewPinned && root.previewSurface ? root.previewOrigin.x - 32 : parent.width - 32))
        height: Math.min(root.selectorAnchorY - 64 + selectorHeight, preferredHeight)
        x: root.previewPinned && root.previewSurface ? Math.min((parent.width - width) / 2, root.previewOrigin.x - width - 16) : (parent.width - width) / 2
        y: root.selectorAnchorY - height + selectorHeight
        // Counteract content repositioning for preview; selector remains output-centred.
        selectorPill.x: (root.width - selectorPill.width) / 2 - x
    }
}
