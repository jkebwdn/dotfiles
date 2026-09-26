pragma ComponentBehavior: Bound

import QtQuick
import "../../services" as MagiServices
import "../../theme" as MagiTheme

// One presentation lifecycle for the status cluster. Native input/focus belongs
// to Bar; system state and body Components continue to belong to each plugin.
Item {
    id: root

    property bool combined: false
    property Component statusContent: null
    property var modules: []
    property var requestedModule: null
    property var displayedModule: null
    property int phase: 0
    property bool switchingView: false
    property real animatedWidth: collapsedWidth
    property real revealedHeight: 0
    property real contentOpacity: 0

    readonly property real collapsedWidth: statusLoader.item
        ? statusLoader.item.implicitWidth : 0
    readonly property real targetWidth: Math.max(collapsedWidth + 52,
        displayedModule ? displayedModule.expandedWidth : collapsedWidth)
    readonly property real targetHeight: displayedModule
        ? displayedModule.menuHeight : 0
    readonly property bool requestedOpen: combined && requestedModule !== null
    readonly property bool interactive: requestedOpen && phase === 3
        && !switchingView && displayedModule === requestedModule
    readonly property real expansion: phase === 0 ? 0
        : phase === 1 || phase === 6
            ? Math.max(0, Math.min(1, (animatedWidth - collapsedWidth)
                / Math.max(1, targetWidth - collapsedWidth))) : 1
    readonly property real headerHeight: MagiTheme.Theme.barPillHeight + 8 * expansion

    width: combined ? animatedWidth : collapsedWidth
    height: headerHeight + revealedHeight

    function presentation(module, key, fallback) {
        return module && module[key] !== undefined ? module[key] : fallback
    }

    function animate(animation, from, to, duration) {
        animation.stop()
        animation.from = from
        animation.to = to
        animation.duration = duration
        animation.start()
    }

    function stopAnimations() {
        horizontal.stop()
        vertical.stop()
        fade.stop()
    }

    function focusBody() {
        Qt.callLater(function() {
            if (!root.interactive)
                return
            for (let i = 0; i < bodies.count; ++i) {
                const body = bodies.itemAt(i)
                if (body && body.selected) {
                    body.forceActiveFocus()
                    const content = body.item
                    if (content && typeof content.requestInitialFocus === "function")
                        content.requestInitialFocus()
                    return
                }
            }
        })
    }

    function reveal() {
        phase = 2
        animate(vertical, revealedHeight, targetHeight, 140)
        animate(fade, contentOpacity, 1, 90)
    }

    function narrow() {
        phase = 6
        animate(horizontal, animatedWidth, collapsedWidth, 160)
    }

    function syncSelection() {
        if (!combined)
            return
        stopAnimations()
        switchingView = false
        if (!requestedOpen) {
            if (revealedHeight > 0) {
                phase = 4
                animate(fade, contentOpacity, 0, 70)
            } else {
                contentOpacity = 0
                narrow()
            }
            return
        }

        if (revealedHeight > 0) {
            // Keep the surface open, including when reversing a partial close.
            // Multiple requests during the fade resolve to the latest module.
            switchingView = true
            phase = 2
            animate(fade, contentOpacity, 0, 70)
        } else {
            displayedModule = requestedModule
            contentOpacity = 0
            phase = 1
            animate(horizontal, animatedWidth, targetWidth, 180)
        }
    }

    // Selection also updates requestedOpen and Bar's focus/registry bindings.
    // React after those bindings settle, not to the previous derived state.
    // Coalescing same-turn requests also makes the latest selection win.
    onRequestedModuleChanged: Qt.callLater(root.syncSelection)
    function syncCompactWidth() {
        if (!combined || phase === 0)
            animatedWidth = collapsedWidth
        else if (phase === 6)
            animate(horizontal, animatedWidth, collapsedWidth, 160)
        else if (requestedOpen)
            animate(horizontal, animatedWidth, targetWidth, 180)
    }
    // targetWidth depends on collapsedWidth; apply the same settled-binding rule.
    onCollapsedWidthChanged: Qt.callLater(root.syncCompactWidth)

    NumberAnimation {
        id: horizontal
        target: root
        property: "animatedWidth"
        easing.type: Easing.OutCubic
        onFinished: {
            if (root.phase === 1)
                root.reveal()
            else if (root.phase === 6)
                root.phase = 0
        }
    }

    NumberAnimation {
        id: vertical
        target: root
        property: "revealedHeight"
        easing.type: Easing.OutCubic
        onFinished: {
            if (root.phase === 2 && !root.switchingView) {
                root.phase = 3
                root.focusBody()
            } else if (root.phase === 5) {
                root.narrow()
            }
        }
    }

    NumberAnimation {
        id: fade
        target: root
        property: "contentOpacity"
        easing.type: Easing.OutCubic
        onFinished: {
            if (root.switchingView && root.requestedOpen) {
                root.switchingView = false
                root.displayedModule = root.requestedModule
                root.animate(horizontal, root.animatedWidth, root.targetWidth, 180)
                root.reveal()
            } else if (root.phase === 4) {
                root.phase = 5
                root.animate(vertical, root.revealedHeight, 0, 120)
            }
        }
    }

    Rectangle {
        anchors.fill: parent
        visible: root.combined && root.phase !== 0
        opacity: root.expansion
        radius: root.presentation(root.displayedModule, "viewRadius",
            MagiTheme.Theme.radiusMedium)
        color: root.presentation(root.displayedModule, "viewSurfaceColor",
            MagiTheme.Theme.surface)

        // Blank space belongs to the surface, not to the outside catcher.
        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.AllButtons
            onWheel: wheel => wheel.accepted = true
        }
    }

    Loader {
        id: statusLoader
        sourceComponent: root.statusContent
        x: root.width - width - 12 * root.expansion
        y: 4 * root.expansion
        // Intrinsic row size stays independent of the growing surface.
        width: item ? item.implicitWidth : 0
        height: MagiTheme.Theme.barPillHeight
    }

    Text {
        x: 10
        y: 4
        width: 24
        height: MagiTheme.Theme.barPillHeight
        text: "󰁍"
        font.family: MagiTheme.Theme.fontFamily
        font.pixelSize: 16
        color: MagiTheme.Theme.text
        verticalAlignment: Text.AlignVCenter
        horizontalAlignment: Text.AlignHCenter
        visible: root.combined && root.phase !== 0 && MagiServices.MenuController.canGoBack
        opacity: root.expansion
        MouseArea {
            anchors.fill: parent
            enabled: root.requestedOpen
            cursorShape: Qt.PointingHandCursor
            onClicked: MagiServices.MenuController.back()
        }
    }

    Item {
        y: root.headerHeight
        width: root.width
        height: Math.max(0, root.revealedHeight)
        clip: true
        visible: root.combined && root.revealedHeight > 0

        Repeater {
            id: bodies
            model: root.combined ? root.modules : []
            Loader {
                required property var modelData
                readonly property bool selected: modelData === root.displayedModule
                x: root.presentation(modelData, "viewPadding", MagiTheme.Theme.menuPadding)
                y: root.presentation(modelData, "viewTopPadding", MagiTheme.Theme.menuTopPadding)
                width: Math.max(0, parent.width - 2 * x)
                height: Math.max(0, modelData.menuHeight - y
                    - root.presentation(modelData, "viewBottomPadding",
                        MagiTheme.Theme.menuBottomPadding))
                sourceComponent: modelData.menuContent
                visible: selected
                opacity: selected ? root.contentOpacity : 0
                enabled: selected && root.interactive
                focus: enabled
                Keys.onEscapePressed: event => {
                    MagiServices.MenuController.close()
                    event.accepted = true
                }
            }
        }
    }
}
