
import QtQuick

import "../../services" as MagiServices
import "menu" as MenuHosts

Rectangle {
    id: root

    // ---------------------------------------------------------
    // Public interface
    // ---------------------------------------------------------

    // Supplied by Bar.qml.
    property var barWindow: null

    property string menuId: ""
    property string icon: "󰒓"
    property string title: "MAGI · Test menu"

    property int collapsedWidth: 28
    property int expandedWidth: 220
    property int menuHeight: 180

    // Plugin-specific expanded content.
    // If omitted, the component displays its test content.
    property Component menuContent: null

    // ---------------------------------------------------------
    // Animation timing
    // ---------------------------------------------------------

    readonly property int expandDuration: 180
    readonly property int revealDuration: 140
    readonly property int fadeInDuration: 90

    readonly property int fadeOutDuration: 70
    readonly property int retractDuration: 120
    readonly property int contractDuration: 160

    // ---------------------------------------------------------
    // Animation state
    //
    // 0 = collapsed
    // 1 = widening
    // 2 = revealing
    // 3 = open
    // 4 = fading content out
    // 5 = retracting
    // 6 = narrowing
    // ---------------------------------------------------------

    property int phase: 0

    readonly property bool requestedOpen:
        menuId !== ""
        && MagiServices.MenuController.activeMenu === menuId

    property real animatedWidth: collapsedWidth
    property real revealedHeight: 0
    property real contentOpacity: 0

    implicitWidth: animatedWidth
    implicitHeight: 28

    radius: 8

    bottomLeftRadius: revealedHeight > 0 ? 0 : 8
    bottomRightRadius: revealedHeight > 0 ? 0 : 8

    color: "#374145"

    // ---------------------------------------------------------
    // Animation coordination
    // ---------------------------------------------------------

    function stopAnimations() {
        horizontalAnimation.stop()
        verticalAnimation.stop()
        contentAnimation.stop()
    }

    function syncRequestedState() {
        if (requestedOpen) {
            if (phase === 0 || phase === 4
                    || phase === 5 || phase === 6) {
                beginOpening()
            }
        } else {
            if (phase === 1 || phase === 2 || phase === 3) {
                beginClosing()
            }
        }
    }

    function beginOpening() {
        stopAnimations()

        if (revealedHeight > 0 && animatedWidth < expandedWidth) {
            phase = 5
            contentOpacity = 0

            verticalAnimation.from = revealedHeight
            verticalAnimation.to = 0
            verticalAnimation.duration = retractDuration
            verticalAnimation.start()
            return
        }

        if (animatedWidth >= expandedWidth) {
            beginReveal()
            return
        }

        phase = 1
        contentOpacity = 0

        horizontalAnimation.from = animatedWidth
        horizontalAnimation.to = expandedWidth
        horizontalAnimation.duration = expandDuration
        horizontalAnimation.start()
    }

    function beginReveal() {
        phase = 2

        verticalAnimation.from = revealedHeight
        verticalAnimation.to = menuHeight
        verticalAnimation.duration = revealDuration
        verticalAnimation.start()

        contentAnimation.from = contentOpacity
        contentAnimation.to = 1
        contentAnimation.duration = fadeInDuration
        contentAnimation.start()
    }

    function beginClosing() {
        stopAnimations()

        if (revealedHeight > 0) {
            phase = 4

            contentAnimation.from = contentOpacity
            contentAnimation.to = 0
            contentAnimation.duration = fadeOutDuration
            contentAnimation.start()
            return
        }

        beginNarrowing()
    }

    function beginNarrowing() {
        phase = 6
        contentOpacity = 0

        horizontalAnimation.from = animatedWidth
        horizontalAnimation.to = collapsedWidth
        horizontalAnimation.duration = contractDuration
        horizontalAnimation.start()
    }

    onRequestedOpenChanged: syncRequestedState()

    // ---------------------------------------------------------
    // Horizontal animation
    // ---------------------------------------------------------

    NumberAnimation {
        id: horizontalAnimation

        target: root
        property: "animatedWidth"

        duration: root.expandDuration
        easing.type: Easing.OutCubic

        onFinished: {
            if (root.phase === 1) {
                if (root.requestedOpen)
                    root.beginReveal()
                else
                    root.beginClosing()

            } else if (root.phase === 6) {
                root.phase = 0

                if (root.requestedOpen)
                    root.beginOpening()
            }
        }
    }

    // ---------------------------------------------------------
    // Vertical animation
    // ---------------------------------------------------------

    NumberAnimation {
        id: verticalAnimation

        target: root
        property: "revealedHeight"

        duration: root.revealDuration
        easing.type: Easing.OutCubic

        onFinished: {
            if (root.phase === 2) {
                root.phase = 3

                if (!root.requestedOpen)
                    root.beginClosing()

            } else if (root.phase === 5) {
                if (root.requestedOpen)
                    root.beginOpening()
                else
                    root.beginNarrowing()
            }
        }
    }

    // ---------------------------------------------------------
    // Content fade
    // ---------------------------------------------------------

    NumberAnimation {
        id: contentAnimation

        target: root
        property: "contentOpacity"

        duration: root.fadeInDuration
        easing.type: Easing.OutCubic

        onFinished: {
            if (root.phase === 4) {
                root.phase = 5

                verticalAnimation.from = root.revealedHeight
                verticalAnimation.to = 0
                verticalAnimation.duration = root.retractDuration
                verticalAnimation.start()
            }
        }
    }

    // ---------------------------------------------------------
    // Pill content
    // ---------------------------------------------------------

    Text {
        id: pillLabel

        anchors.centerIn: parent

        text: root.phase === 0
            ? root.icon
            : root.title

        color: "#d3c6aa"
        font.pixelSize: 12

        width: Math.max(0, parent.width - 12)
        horizontalAlignment: Text.AlignHCenter
        elide: Text.ElideRight
        clip: true
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor

        onClicked: MagiServices.MenuController.toggle(root.menuId)
    }

    // ---------------------------------------------------------
    // Fallback menu content
    //
    // Used only when no plugin-specific menuContent is supplied.
    // ---------------------------------------------------------

    Component {
        id: fallbackMenuContent

        Column {
            width: parent ? parent.width : 0
            spacing: 12

            Text {
                text: "Expandable menu test"

                color: "#d3c6aa"
                font.pixelSize: 13
                font.bold: true
            }

            Rectangle {
                width: parent.width
                height: 1

                color: "#d3c6aa"
                opacity: 0.2
            }

            Text {
                width: parent.width

                text: "This panel extends below MAGI without moving your tiled windows."

                color: "#d3c6aa"
                font.pixelSize: 12
                wrapMode: Text.WordWrap
            }

            Text {
                text: "Wi-Fi · Volume · Battery"

                color: "#9da9a0"
                font.pixelSize: 11
            }
        }
    }

    // ---------------------------------------------------------
    // Expanded panel
    // ---------------------------------------------------------

    MenuHosts.AnchoredPopupHost {
        id: menuPopup

        barWindow: root.barWindow
        anchorItem: root

        menuWidth: root.width
        revealedHeight: root.revealedHeight
        menuHeight: root.menuHeight
        contentOpacity: root.contentOpacity

        menuColor: root.color
        menuContent: root.menuContent
        fallbackContent: fallbackMenuContent
    }
}
