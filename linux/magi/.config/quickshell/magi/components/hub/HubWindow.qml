pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Window
import QtQuick.Controls.Basic
import "."
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import "../../services" as Services

PanelWindow {
    id: root
    screen: Services.SurfaceOrigin.hubTarget()
    property bool readyToOpen: true
    property alias content: content
    property Item previewSurface: null
    property bool presented: false
    readonly property Item popupOverlay: content.Overlay.overlay
    TransformWatcher { id: previewWatch; a: root.previewSurface; b: root.previewSurface ? root.previewSurface.Window.window.contentItem : null }
    readonly property bool previewPinned: Services.SettingsWindowState.controlCentrePreview && Services.Hub.mode === "settings"
    readonly property point previewOrigin: {
        const transform = previewWatch.transform
        return previewSurface ? previewSurface.mapToItem(null, 0, 0) : Qt.point(width, 0)
    }
    // Logical output coordinates; independent of the active mode's dimensions.
    readonly property real selectorAnchorY: content.selectorAbove
        ? Math.max(64, Math.min(height - 60 - 240, height * Services.Settings.data.hub.verticalPosition))
        : Math.max(64 + 240, Math.min(height - 60, height * Services.Settings.data.hub.verticalPosition))
    anchors { top: true; bottom: true; left: true; right: true }
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.namespace: "magi-hub"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: visible ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None
    visible: Services.Hub.opened && !Services.Hub.suppressed && (readyToOpen || presented || previewPinned)
    color: "transparent"
    // Only the visible Hub surfaces own pointer input. Desktop/app clicks pass through.
    mask: Region {
        item: content.surface
        Region { item: content.selectorPill }
        // A child popup may extend beyond the surface. Its normal outside-click
        // handling owns the temporary overlay; it never closes the Hub itself.
        Region {
            width: root.popupOverlay && root.popupOverlay.visible ? root.width : 0
            height: width > 0 ? root.height : 0
        }
    }
    onVisibleChanged: { if (visible) { presented = true; Qt.callLater(content.focusMode) } }
    Connections {
        target: Services.Hub
        function onOpenedChanged() { if (!Services.Hub.opened) root.presented = false }
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
        height: Math.max(selectorHeight + contentSelectorGap, Math.min(content.selectorAbove
            ? root.height - 16 - root.selectorAnchorY : root.selectorAnchorY - 64 + selectorHeight, preferredHeight))
        x: root.previewPinned && root.previewSurface ? Math.min((parent.width - width) / 2, root.previewOrigin.x - width - 16) : (parent.width - width) / 2
        y: selectorAbove ? root.selectorAnchorY : root.selectorAnchorY - height + selectorHeight
        // Counteract content repositioning for preview; selector remains output-centred.
        selectorPill.x: (root.width - selectorPill.width) / 2 - x
    }
}
