import QtQuick

import "../../../theme" as MagiTheme

Item {
    id: root

    property real revealedHeight: 0
    property int menuHeight: 0
    property real contentOpacity: 0
    property bool contentInteractive: false

    property color menuColor: "transparent"
    property Component menuContent: null
    property Component fallbackContent: null

    signal closeRequested(string reason)

    function requestInitialFocus() {
        Qt.callLater(function() {
            if (!root.visible || !root.contentInteractive)
                return

            const content = menuContentLoader.item
            if (content
                    && typeof content["requestInitialFocus"] === "function") {
                content["requestInitialFocus"]()
            } else {
                root.forceActiveFocus()
            }
        })
    }

    anchors.fill: parent
    visible: revealedHeight > 0
    enabled: contentInteractive
    focus: visible && contentInteractive
    clip: true

    Keys.onEscapePressed: function(event) {
        root.closeRequested("escape-host")
        event.accepted = true
    }

    Rectangle {
        anchors.fill: parent

        color: root.menuColor

        topLeftRadius: 0
        topRightRadius: 0

        bottomLeftRadius: Math.min(
            MagiTheme.Theme.radiusMedium, height / 2
        )
        bottomRightRadius: Math.min(
            MagiTheme.Theme.radiusMedium, height / 2
        )

        Loader {
            id: menuContentLoader

            x: MagiTheme.Theme.menuPadding
            y: MagiTheme.Theme.menuTopPadding

            width: Math.max(
                0, parent.width - MagiTheme.Theme.menuPadding * 2
            )
            height: Math.max(
                0, root.menuHeight
                    - MagiTheme.Theme.menuTopPadding
                    - MagiTheme.Theme.menuBottomPadding
            )

            sourceComponent: root.menuContent
                ? root.menuContent
                : root.fallbackContent

            opacity: root.contentOpacity
            enabled: root.contentInteractive
        }
    }
}
