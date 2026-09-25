import QtQuick

Rectangle {
    id: root

    property var experiment: null
    property var barWindow: null
    property string hostMode: "anchored"
    property string menuId: ""
    property string icon: "󰒓"
    property string title: "Experiment menu"
    property int collapsedWidth: 28
    property int expandedWidth: 220
    property int menuHeight: 180
    property Component menuContent: null

    readonly property int expandDuration: 180
    readonly property int revealDuration: 140
    readonly property int fadeInDuration: 90
    readonly property int fadeOutDuration: 70
    readonly property int retractDuration: 120
    readonly property int contractDuration: 160

    // 0 collapsed, 1 widening, 2 revealing, 3 open,
    // 4 fading out, 5 retracting, 6 narrowing.
    property int phase: 0
    property real animatedWidth: collapsedWidth
    property real revealedHeight: 0
    property real contentOpacity: 0

    readonly property bool requestedOpen:
        experiment && experiment.activeMenu === menuId
    readonly property bool contentInteractive:
        requestedOpen && phase === 3
    readonly property Item combinedMenuRegion: combinedHost
    readonly property var activeHost:
        hostMode === "combined" ? combinedHost : anchoredHost

    implicitWidth: animatedWidth
    implicitHeight: 28
    z: phase === 0 ? 1 : 50
    radius: 8
    bottomLeftRadius: revealedHeight > 0 ? 0 : 8
    bottomRightRadius: revealedHeight > 0 ? 0 : 8
    color: "#374145"

    function log(kind, details) {
        if (!experiment)
            return

        const values = details || {}
        values.menu = menuId
        values.phase = phase
        values.width = animatedWidth
        values.height = revealedHeight
        values.opacity = contentOpacity
        const point = experiment
            ? root.mapToItem(experiment.contentItem, 0, 0)
            : Qt.point(0, 0)
        values.x = point.x
        values.y = point.y
        experiment.logEvent(kind, values)
    }

    function snapshot() {
        const point = experiment
            ? root.mapToItem(experiment.contentItem, 0, 0)
            : Qt.point(0, 0)
        return {
            menu: menuId,
            requested: requestedOpen,
            phase: phase,
            pill: {
                x: point.x,
                y: point.y,
                width: width,
                height: height
            },
            menuGeometry: {
                x: point.x,
                y: point.y + height,
                width: animatedWidth,
                height: revealedHeight
            },
            contentOpacity: contentOpacity
        }
    }

    function stopAnimations() {
        if (horizontalAnimation.running || verticalAnimation.running
                || contentAnimation.running)
            log("animations-interrupted")

        horizontalAnimation.stop()
        verticalAnimation.stop()
        contentAnimation.stop()
    }

    function syncRequestedState() {
        if (requestedOpen) {
            if (phase === 0 || phase === 4 || phase === 5 || phase === 6)
                beginOpening()
        } else if (phase === 1 || phase === 2 || phase === 3) {
            beginClosing()
        }
    }

    function beginOpening() {
        stopAnimations()

        if (revealedHeight > 0 && animatedWidth < expandedWidth) {
            phase = 5
            contentOpacity = 0
            log("retract-before-reopen")
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
        log("widen-start")
        horizontalAnimation.from = animatedWidth
        horizontalAnimation.to = expandedWidth
        horizontalAnimation.duration = expandDuration
        horizontalAnimation.start()
    }

    function beginReveal() {
        phase = 2
        log("reveal-start")
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
            log("fade-out-start")
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
        log("narrow-start")
        horizontalAnimation.from = animatedWidth
        horizontalAnimation.to = collapsedWidth
        horizontalAnimation.duration = contractDuration
        horizontalAnimation.start()
    }

    function requestInitialFocus() {
        if (experiment && experiment.keyboardEnabled)
            activeHost.requestInitialFocus()
    }

    onRequestedOpenChanged: syncRequestedState()
    onPhaseChanged: log("phase-changed")

    Component.onCompleted: {
        if (experiment)
            experiment.registerPill(menuId, root)
        log("pill-created")
    }

    Component.onDestruction: {
        log("pill-destroyed")
        if (experiment)
            experiment.unregisterPill(menuId, root)
    }

    NumberAnimation {
        id: horizontalAnimation
        target: root
        property: "animatedWidth"
        duration: root.expandDuration
        easing.type: Easing.OutCubic

        onFinished: {
            root.log("horizontal-finished")
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

    NumberAnimation {
        id: verticalAnimation
        target: root
        property: "revealedHeight"
        duration: root.revealDuration
        easing.type: Easing.OutCubic

        onFinished: {
            root.log("vertical-finished")
            if (root.phase === 2) {
                root.phase = 3
                root.requestInitialFocus()
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

    NumberAnimation {
        id: contentAnimation
        target: root
        property: "contentOpacity"
        duration: root.fadeInDuration
        easing.type: Easing.OutCubic

        onFinished: {
            root.log("content-fade-finished")
            if (root.phase === 4) {
                root.phase = 5
                verticalAnimation.from = root.revealedHeight
                verticalAnimation.to = 0
                verticalAnimation.duration = root.retractDuration
                verticalAnimation.start()
            }
        }
    }

    Text {
        anchors.centerIn: parent
        width: Math.max(0, parent.width - 12)
        text: root.phase === 0 ? root.icon : root.title
        color: "#d3c6aa"
        font.pixelSize: 12
        horizontalAlignment: Text.AlignHCenter
        elide: Text.ElideRight
        clip: true
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            root.log("pill-clicked")
            if (root.experiment)
                root.experiment.toggleMenu(root.menuId, "pill")
        }
    }

    AnchoredPopupHost {
        id: anchoredHost
        hostEnabled: root.hostMode === "anchored"
        experiment: root.experiment
        barWindow: root.barWindow
        anchorItem: root
        menuId: root.menuId
        menuWidth: root.animatedWidth
        revealedHeight: root.revealedHeight
        contentOpacity: root.contentOpacity
        menuHeight: root.menuHeight
        menuContent: root.menuContent
        contentInteractive: root.contentInteractive
        onCloseRequested: function(reason) {
            if (root.experiment)
                root.experiment.requestClose(root.menuId, reason)
        }
    }

    CombinedMenuHost {
        id: combinedHost
        hostEnabled: root.hostMode === "combined"
        experiment: root.experiment
        anchorItem: root
        menuId: root.menuId
        menuWidth: root.animatedWidth
        revealedHeight: root.revealedHeight
        contentOpacity: root.contentOpacity
        menuHeight: root.menuHeight
        menuContent: root.menuContent
        contentInteractive: root.contentInteractive
        onCloseRequested: function(reason) {
            if (root.experiment)
                root.experiment.requestClose(root.menuId, reason)
        }
    }
}
