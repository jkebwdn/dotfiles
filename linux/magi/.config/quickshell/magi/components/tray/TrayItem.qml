import QtQuick
import QtQuick.Controls.Basic
import Quickshell
import "../../theme" as Theme
import "TrayActions.js" as Actions
FocusScope {
    id: root
    property var trayItem: null
    property bool interactive: true
    property bool bottomUp: false
    property bool nativeMenus: true
    readonly property string accessibleName: Actions.name(trayItem)
    readonly property string tooltipText: Actions.tooltip(trayItem)
    readonly property bool attention: trayItem !== null && trayItem.status === 2
    readonly property bool menuVisible: menuAnchor.visible
    signal menuRequested()
    implicitWidth: Math.max(30, Theme.Theme.statusIconSize + 8)
    implicitHeight: Theme.Theme.barPillHeight
    activeFocusOnTab: interactive
    Accessible.role: Accessible.Button
    Accessible.name: accessibleName
    Accessible.onPressAction: primary()
    function showMenu() {
        menuRequested()
        if (nativeMenus && visible && !menuAnchor.visible) menuAnchor.open()
    }
    function primary() { if (interactive) return Actions.invoke(trayItem, "primary", showMenu); return false }
    function context() { if (interactive) return Actions.invoke(trayItem, "menu", showMenu); return false }
    function secondary() { if (interactive) return Actions.invoke(trayItem, "secondary", showMenu); return false }
    function wheel(x, y) { return interactive && Actions.scroll(trayItem, x, y) }
    function closeMenu() { if (menuAnchor.visible) menuAnchor.close() }
    onTrayItemChanged: closeMenu()
    onVisibleChanged: if (!visible) closeMenu()
    Component.onDestruction: closeMenu()
    readonly property bool usableMenu: !!trayItem && !!trayItem.hasMenu && !!trayItem.menu
    onUsableMenuChanged: if (!usableMenu) closeMenu()
    Keys.onReturnPressed: event => { primary(); event.accepted = true }
    Keys.onEnterPressed: event => { primary(); event.accepted = true }
    Keys.onSpacePressed: event => { primary(); event.accepted = true }
    Keys.onMenuPressed: event => { context(); event.accepted = true }
    Keys.onPressed: event => {
        if (event.key === Qt.Key_F10 && (event.modifiers & Qt.ShiftModifier)) { context(); event.accepted = true }
    }
    Rectangle {
        anchors.fill: parent
        radius: Theme.Theme.radius("action", 7, width, height)
        color: pointer.containsMouse || root.activeFocus ? Theme.Theme.overlay : "transparent"
        border.width: root.activeFocus ? 1 : 0
        border.color: Theme.Theme.focus
    }
    Image {
        id: artwork
        objectName: "trayApplicationArtwork"
        anchors.centerIn: parent
        width: Theme.Theme.statusIconSize; height: width
        sourceSize.width: width; sourceSize.height: height
        source: root.trayItem ? root.trayItem.icon || "" : ""
        fillMode: Image.PreserveAspectFit
        visible: status === Image.Ready
        // Application-provided Image source; deliberately no semantic mapping/tint.
    }
    Rectangle {
        anchors.centerIn: parent
        width: Theme.Theme.statusIconSize - 4; height: width
        visible: artwork.status !== Image.Ready
        radius: 4; color: "transparent"; border.width: 1; border.color: Theme.Theme.subtext
        Text { anchors.centerIn: parent; text: "·"; color: Theme.Theme.text }
    }
    Rectangle {
        visible: root.attention
        width: 5; height: 5; radius: 3
        anchors.right: parent.right; anchors.top: parent.top; anchors.margins: 2
        color: Theme.Theme.yellow
    }
    ToolTip {
        parent: root
        visible: root.interactive && pointer.containsMouse && root.tooltipText.length > 0
        delay: 500
        text: root.tooltipText
        width: Math.min(320, implicitWidth)
        contentItem: Text { text: root.tooltipText; textFormat: Text.PlainText; wrapMode: Text.Wrap; color: Theme.Theme.text; font.pixelSize: 12 }
        background: Rectangle { radius: Theme.Theme.radiusMedium; color: Theme.Theme.surfaceBackground(Theme.Theme.elevated); border.color: Theme.Theme.border; border.width: 1 }
    }
    MouseArea {
        id: pointer
        anchors.fill: parent
        enabled: root.interactive
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
        onClicked: event => {
            root.forceActiveFocus(Qt.MouseFocusReason)
            if (event.button === Qt.RightButton) root.context()
            else if (event.button === Qt.MiddleButton) root.secondary()
            else root.primary()
        }
        onWheel: event => { event.accepted = root.wheel(event.angleDelta.x, event.angleDelta.y) }
    }
    QsMenuAnchor {
        id: menuAnchor
        menu: root.nativeMenus && root.trayItem && root.trayItem.hasMenu ? root.trayItem.menu : null
        anchor.item: root
        anchor.edges: root.bottomUp ? Edges.Top : Edges.Bottom
        anchor.gravity: (root.bottomUp ? Edges.Top : Edges.Bottom) | Edges.Right
    }
}
