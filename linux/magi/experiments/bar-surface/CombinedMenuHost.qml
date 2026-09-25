import QtQuick

Item {
    id: root

    property bool hostEnabled: false
    property var experiment: null
    property Item anchorItem: null
    property string menuId: ""
    property real menuWidth: 1
    property real revealedHeight: 0
    property real contentOpacity: 0
    property int menuHeight: 180
    property Component menuContent: null
    property bool contentInteractive: false

    signal closeRequested(string reason)

    function requestInitialFocus() {
        Qt.callLater(function() {
            const content = contentLoader.item
            if (root.visible && root.contentInteractive && content
                    && typeof content["requestInitialFocus"] === "function")
                content["requestInitialFocus"]()
        })
    }

    x: 0
    y: anchorItem ? anchorItem.height : 28
    width: Math.max(1, menuWidth)
    height: Math.max(0, revealedHeight)
    visible: hostEnabled && revealedHeight > 0
    z: 100
    clip: true
    enabled: contentInteractive
    focus: visible && contentInteractive

    onVisibleChanged: {
        if (experiment)
            experiment.logEvent("combined-menu-visible", {
                menu: menuId,
                visible: visible
            })
    }

    Keys.onEscapePressed: function(event) {
        root.closeRequested("escape-host")
        event.accepted = true
    }

    Rectangle {
        anchors.fill: parent
        color: "#374145"
        topLeftRadius: 0
        topRightRadius: 0
        bottomLeftRadius: Math.min(8, height / 2)
        bottomRightRadius: Math.min(8, height / 2)

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
