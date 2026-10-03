import QtQuick
import Quickshell

// Hidden-from-bar detail fallback: a popup anchored to a real CC trigger,
// never an invisible bar Item. Visible pills retain their original adapter.
Scope {
    id: root
    required property var module
    required property var anchorItem
    property int phase: 0
    property real menuWidth: anchorItem ? anchorItem.width : 0
    property real revealedHeight: 0
    property real opacity: 0
    function sync() {
        horizontal.stop(); vertical.stop(); fade.stop()
        if (module.requestedOpen) {
            if (revealedHeight > 0) reveal()
            else {
                phase = 1
                horizontal.to = module.expandedWidth
                horizontal.duration = 180
                horizontal.start()
            }
        } else if (revealedHeight > 0) {
            phase = 4; fade.to = 0; fade.duration = 70; fade.start()
        } else narrow()
    }
    function reveal() {
        phase = 2
        vertical.to = module.menuHeight; vertical.duration = 140; vertical.start()
        fade.to = 1; fade.duration = 90; fade.start()
    }
    function narrow() {
        phase = 6
        horizontal.to = anchorItem ? anchorItem.width : 0
        horizontal.duration = 160; horizontal.start()
    }
    function retargetGeometry() {
        if (!module.requestedOpen || phase < 1 || phase > 3) return
        if (menuWidth !== module.expandedWidth) {
            horizontal.stop(); horizontal.from = menuWidth
            horizontal.to = module.expandedWidth; horizontal.duration = 180; horizontal.start()
        }
        if (phase !== 1 && revealedHeight !== module.menuHeight) {
            vertical.stop(); vertical.from = revealedHeight
            vertical.to = module.menuHeight; vertical.duration = 140; vertical.start()
        }
    }
    Connections {
        target: root.module
        function onRequestedOpenChanged() { root.sync() }
        function onMenuHeightChanged() { Qt.callLater(root.retargetGeometry) }
        function onExpandedWidthChanged() { Qt.callLater(root.retargetGeometry) }
    }
    Component.onCompleted: { if (module.requestedOpen) sync() }
    NumberAnimation {
        id: horizontal; target: root; property: "menuWidth"; easing.type: Easing.OutCubic
        onFinished: { if (root.phase === 1) root.reveal(); else if (root.phase === 6) root.phase = 0 }
    }
    NumberAnimation {
        id: vertical; target: root; property: "revealedHeight"; easing.type: Easing.OutCubic
        onFinished: { if (root.phase === 2) root.phase = 3; else if (root.phase === 5) root.narrow() }
    }
    NumberAnimation {
        id: fade; target: root; property: "opacity"; easing.type: Easing.OutCubic
        onFinished: {
            if (root.phase === 4) { root.phase = 5; vertical.to = 0; vertical.duration = 120; vertical.start() }
        }
    }
    AnchoredPopupHost {
        barWindow: root.module.barWindow
        anchorItem: root.anchorItem
        menuWidth: root.menuWidth
        revealedHeight: root.revealedHeight
        menuHeight: root.module.menuHeight
        contentOpacity: root.opacity
        menuColor: root.module.viewSurfaceColor
        menuContent: root.module.menuContent
    }
}
