
pragma ComponentBehavior: Bound

import QtQuick

import "../../services" as MagiServices
import "../../theme" as MagiTheme
import "menu" as MenuHosts

Rectangle {
    id: root

    // ---------------------------------------------------------
    // Public interface
    // ---------------------------------------------------------

    // Supplied by Bar.qml.
    property var barWindow: null
    property var menuCoordinator: null
    // Combined production delegates presentation to the whole status cluster.
    property var sharedSurface: null
    property string hostMode: "anchored"
    property bool menuKeyboardFocus: true
    property bool barVisible: true

    property string menuId: ""
    signal secondaryTriggered()
    property string icon: "settings"
    property string title: "MAGI"

    property int collapsedWidth: 28
    property int expandedWidth: 220
    property int menuHeight: 180

    // Optional per-view presentation, independent of the shared host lifecycle.
    property real viewPadding: MagiTheme.Theme.menuPadding
    property real viewTopPadding: MagiTheme.Theme.menuTopPadding
    property real viewBottomPadding: MagiTheme.Theme.menuBottomPadding
    property real viewRadius: MagiTheme.Theme.radiusMedium
    property color viewSurfaceColor: MagiTheme.Theme.surface

    // Plugin-owned visual shared by the compact and widened pill states.
    // If omitted, the current icon/title presentation is used.
    property Component pillContent: null

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

    property int phase: sharedSurface ? sharedSurface.phase : 0

    readonly property bool requestedOpen:
        menuId !== ""
        && MagiServices.MenuController.activeMenu === menuId
    readonly property bool contentInteractive:
        hostMode === "combined" && requestedOpen && phase === 3
    readonly property var combinedMenuRegion:
        menuHost.combinedRegion

    property real animatedWidth: collapsedWidth
    property real revealedHeight: 0
    property real contentOpacity: 0

    implicitWidth: animatedWidth
    implicitHeight: MagiTheme.Theme.barPillHeight
    z: hostMode === "combined"
        ? (phase === 0 ? 1 : 50)
        : 0

    radius: MagiTheme.Theme.barPillRadius

    bottomLeftRadius: revealedHeight > 0
        ? 0
        : MagiTheme.Theme.barPillRadius
    bottomRightRadius: revealedHeight > 0
        ? 0
        : MagiTheme.Theme.barPillRadius

    color: MagiTheme.Theme.surface

    // ---------------------------------------------------------
    // Animation coordination
    // ---------------------------------------------------------

    function stopAnimations() {
        horizontalAnimation.stop()
        verticalAnimation.stop()
        contentAnimation.stop()
    }

    function syncRequestedState() {
        if (sharedSurface)
            return
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

    function syncCollapsedWidth() {
        if (sharedSurface) {
            animatedWidth = collapsedWidth
            return
        }
        if (phase === 0) {
            animatedWidth = collapsedWidth
            return
        }

        if (phase === 6) {
            horizontalAnimation.stop()

            horizontalAnimation.from = animatedWidth
            horizontalAnimation.to = collapsedWidth
            horizontalAnimation.duration = contractDuration
            horizontalAnimation.start()
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
    onCollapsedWidthChanged: syncCollapsedWidth()

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

                if (root.requestedOpen)
                    menuHost.requestInitialFocus()

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

    Component {
        id: fallbackPillContent

        Text {
            readonly property var pill: parent

            anchors.centerIn: parent

            text: pill && pill.phase === 0
                ? pill.icon
                : pill ? pill.title : ""

            color: MagiTheme.Theme.text
            font.family: MagiTheme.Theme.fontFamily
            font.pixelSize: 12

            width: pill
                ? Math.max(0, pill.availableWidth - 12)
                : 0
            horizontalAlignment: Text.AlignHCenter
            elide: Text.ElideRight
            clip: true
        }
    }

    Loader {
        // Give plugin-owned pill content the pill's real animated bounds.
        // Morphing content uses this coordinate space to move its persistent
        // icon from the compact group into the expanded header.
        anchors.fill: parent

        readonly property real availableWidth: parent.width
        readonly property real availableHeight: parent.height
        readonly property int phase: root.phase
        readonly property int collapsedWidth: root.collapsedWidth
        readonly property int expandedWidth: root.expandedWidth
        readonly property real animatedWidth: root.animatedWidth
        readonly property string icon: root.icon
        readonly property string title: root.title

        sourceComponent: root.pillContent
            ? root.pillContent
            : fallbackPillContent
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor

        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onClicked: mouse => {
            if (mouse.button === Qt.RightButton) root.secondaryTriggered()
            else MagiServices.MenuController.toggle(root.menuId)
        }
    }

    Component.onCompleted: {
        if (menuCoordinator)
            menuCoordinator.registerExpandablePill(menuId, root)
    }

    Component.onDestruction: {
        if (menuCoordinator)
            menuCoordinator.unregisterExpandablePill(menuId, root)
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
                text: root.title

                color: MagiTheme.Theme.text
                font.family: MagiTheme.Theme.fontFamily
                font.pixelSize: 13
                font.bold: true
            }

            Rectangle {
                width: parent.width
                height: 1

                color: MagiTheme.Theme.border
                opacity: 0.2
            }

            Text {
                width: parent.width

                text: "No menu content is configured for this plugin."

                color: MagiTheme.Theme.text
                font.family: MagiTheme.Theme.fontFamily
                font.pixelSize: 12
                wrapMode: Text.WordWrap
            }

            Text {
                text: root.menuId

                color: MagiTheme.Theme.muted
                font.family: MagiTheme.Theme.fontFamily
                font.pixelSize: 11
            }
        }
    }

    // ---------------------------------------------------------
    // Expanded panel
    // ---------------------------------------------------------

    MenuHosts.MenuHostSelector {
        id: menuHost

        hostingEnabled: !root.sharedSurface
        hostMode: root.hostMode
        barWindow: root.barWindow
        anchorItem: root

        menuWidth: root.width
        revealedHeight: root.revealedHeight
        menuHeight: root.menuHeight
        contentOpacity: root.contentOpacity
        contentInteractive: root.contentInteractive

        menuColor: root.color
        menuContent: root.menuContent
        fallbackContent: fallbackMenuContent

        onCloseRequested: function(reason) {
            if (root.requestedOpen)
                MagiServices.MenuController.close()
        }
    }
}
