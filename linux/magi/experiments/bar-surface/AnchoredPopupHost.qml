import QtQuick
import Quickshell

PopupWindow {
    id: root

    property bool hostEnabled: false
    property var experiment: null
    property var barWindow: null
    property Item anchorItem: null
    property string menuId: ""
    property real menuWidth: 1
    property real revealedHeight: 0
    property real contentOpacity: 0
    property int menuHeight: 180
    property Component menuContent: null
    property bool contentInteractive: false

    signal closeRequested(string reason)

    readonly property real mappedX: {
        const transform = positionWatcher.transform
        if (!barWindow || !anchorItem)
            return 0
        return Math.round(
            barWindow.contentItem.mapFromItem(anchorItem, 0, anchorItem.height).x
        )
    }
    readonly property real mappedY: {
        const transform = positionWatcher.transform
        if (!barWindow || !anchorItem)
            return 0
        return Math.round(
            barWindow.contentItem.mapFromItem(anchorItem, 0, anchorItem.height).y
        )
    }

    function requestInitialFocus() {
        Qt.callLater(function() {
            const content = contentLoader.item
            if (root.visible && root.contentInteractive && content
                    && typeof content["requestInitialFocus"] === "function")
                content["requestInitialFocus"]()
        })
    }

    anchor.window: barWindow
    anchor.rect.x: mappedX
    anchor.rect.y: mappedY
    anchor.adjustment: PopupAdjustment.None

    implicitWidth: Math.max(1, menuWidth)
    implicitHeight: Math.max(1, revealedHeight)
    visible: hostEnabled && revealedHeight > 0
    color: "transparent"

    onVisibleChanged: {
        if (experiment)
            experiment.logEvent("anchored-window-visible", {
                menu: menuId,
                visible: visible
            })
    }

    TransformWatcher {
        id: positionWatcher
        a: root.barWindow ? root.barWindow.contentItem : null
        b: root.anchorItem
    }

    Rectangle {
        anchors.fill: parent
        color: "#374145"
        clip: true
        topLeftRadius: 0
        topRightRadius: 0
        bottomLeftRadius: Math.min(8, height / 2)
        bottomRightRadius: Math.min(8, height / 2)
        enabled: root.contentInteractive
        focus: root.visible && root.contentInteractive

        Keys.onEscapePressed: function(event) {
            root.closeRequested("escape-host")
            event.accepted = true
        }

        Loader {
            id: contentLoader
            active: root.hostEnabled
            x: 12
            y: 12
            width: Math.max(0, parent.width - 24)
            height: Math.max(0, root.menuHeight - 24)
            sourceComponent: root.menuContent
            opacity: root.contentOpacity
            enabled: root.contentInteractive
        }
    }
}
