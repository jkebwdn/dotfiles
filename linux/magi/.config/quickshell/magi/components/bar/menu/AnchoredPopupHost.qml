import QtQuick
import Quickshell

PopupWindow {
    id: root

    property var barWindow: null
    property Item anchorItem: null

    property real menuWidth: 0
    property real revealedHeight: 0
    property int menuHeight: 0
    property real contentOpacity: 0

    property color menuColor: "transparent"
    property Component menuContent: null
    property Component fallbackContent: null

    // ---------------------------------------------------------
    // Popup position tracking
    // ---------------------------------------------------------

    TransformWatcher {
        id: popupPositionWatcher

        a: root.barWindow ? root.barWindow.contentItem : null
        b: root.anchorItem
    }

    // Position relative to the actual bar window.

    anchor.window: root.barWindow

    anchor.rect.x: {
        const transform = popupPositionWatcher.transform

        if (!root.barWindow)
            return 0

        return Math.round(
            root.barWindow.contentItem.mapFromItem(
                root.anchorItem, 0, root.anchorItem.height
            ).x
        )
    }

    anchor.rect.y: {
        const transform = popupPositionWatcher.transform

        if (!root.barWindow)
            return 0

        return Math.round(
            root.barWindow.contentItem.mapFromItem(
                root.anchorItem, 0, root.anchorItem.height
            ).y
        )
    }

    anchor.adjustment: PopupAdjustment.None

    implicitWidth: root.menuWidth
    implicitHeight: Math.max(1, root.revealedHeight)

    visible: root.revealedHeight > 0
    color: "transparent"

    Rectangle {
        anchors.fill: parent

        color: root.menuColor
        clip: true

        topLeftRadius: 0
        topRightRadius: 0

        bottomLeftRadius: Math.min(8, height / 2)
        bottomRightRadius: Math.min(8, height / 2)

        // The host controls geometry and opacity.
        // The loaded component controls its own contents.

        Loader {
            id: menuContentLoader

            x: 12
            y: 12

            width: Math.max(0, parent.width - 24)
            height: Math.max(0, root.menuHeight - 24)

            sourceComponent: root.menuContent
                ? root.menuContent
                : root.fallbackContent

            opacity: root.contentOpacity
        }
    }
}
