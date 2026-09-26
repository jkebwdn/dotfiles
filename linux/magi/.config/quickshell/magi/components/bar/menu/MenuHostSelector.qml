pragma ComponentBehavior: Bound

import QtQuick

Item {
    id: root

    property string hostMode: "anchored"
    property var barWindow: null
    property Item anchorItem: null

    property real menuWidth: 0
    property real revealedHeight: 0
    property int menuHeight: 0
    property real contentOpacity: 0
    property bool contentInteractive: false

    property color menuColor: "transparent"
    property Component menuContent: null
    property Component fallbackContent: null

    signal closeRequested(string reason)
    signal initialFocusRequested()

    readonly property bool combined: hostMode === "combined"
    readonly property var combinedRegion:
        combined ? hostLoader.item : null

    function requestInitialFocus() {
        if (combined)
            initialFocusRequested()
    }

    width: 0
    height: 0
    z: 100

    Loader {
        id: hostLoader

        x: 0
        y: root.combined && root.anchorItem
            ? root.anchorItem.height
            : 0

        width: root.combined ? Math.max(1, root.menuWidth) : 0
        height: root.combined ? Math.max(0, root.revealedHeight) : 0

        sourceComponent: root.combined
            ? combinedHostComponent
            : anchoredHostComponent
    }

    Component {
        id: anchoredHostComponent

        AnchoredPopupHost {
            barWindow: root.barWindow
            anchorItem: root.anchorItem

            menuWidth: root.menuWidth
            revealedHeight: root.revealedHeight
            menuHeight: root.menuHeight
            contentOpacity: root.contentOpacity

            menuColor: root.menuColor
            menuContent: root.menuContent
            fallbackContent: root.fallbackContent
        }
    }

    Component {
        id: combinedHostComponent

        CombinedMenuHost {
            id: combinedHost

            revealedHeight: root.revealedHeight
            menuHeight: root.menuHeight
            contentOpacity: root.contentOpacity
            contentInteractive: root.contentInteractive

            menuColor: root.menuColor
            menuContent: root.menuContent
            fallbackContent: root.fallbackContent

            onCloseRequested: function(reason) {
                root.closeRequested(reason)
            }

            Connections {
                target: root

                function onInitialFocusRequested() {
                    combinedHost.requestInitialFocus()
                }
            }
        }
    }
}
