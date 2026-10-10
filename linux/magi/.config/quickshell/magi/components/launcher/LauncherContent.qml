pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls.Basic
import "../../theme" as Theme
Rectangle {
    id: root
    required property var service
    property bool embedded: false
    readonly property var preferences: service.preferences
    readonly property bool grid: preferences.layout === "grid"
    readonly property int columns: grid ? Math.min(preferences.gridColumns, Math.max(1, Math.floor((width - 32) / 90))) : 1
    readonly property int itemHeight: grid ? preferences.iconSize + 64 : preferences.rowHeight
    readonly property int headerHeight: preferences.headerEnabled && preferences.headerImage ? 150 : 0
    readonly property int desiredHeight: 112 + headerHeight + (grid ? Math.min(3, preferences.visibleRows) : preferences.visibleRows) * itemHeight
    property alias searchField: search
    function focusSearch() { search.forceActiveFocus() }
    property string contextId: ""
    property alias contextMenu: appMenu
    function showContext(appId, position) {
        contextId = appId
        appMenu.popup(position.x, position.y)
    }
    function navigate(key, modifiers) {
        if (key === Qt.Key_Menu || (key === Qt.Key_F10 && (modifiers & Qt.ShiftModifier))) {
            const item = results.itemAtIndex(service.selected)
            if (item) showContext(item.app.id, item.mapToItem(root, 12, item.height))
            return true
        }
        if (key === Qt.Key_Escape) service.close()
        else if (key === Qt.Key_Return || key === Qt.Key_Enter) service.launch(service.selected)
        else if (key === Qt.Key_Down) service.move(columns)
        else if (key === Qt.Key_Up) service.move(-columns)
        else if (grid && key === Qt.Key_Right) service.move(1)
        else if (grid && key === Qt.Key_Left) service.move(-1)
        else if (key === Qt.Key_PageDown) service.move(columns * 3)
        else if (key === Qt.Key_PageUp) service.move(-columns * 3)
        else return false
        return true
    }
    Connections {
        target: root.service
        function onOpenedChanged() { if (!root.service.opened) appMenu.close() }
    }
    Menu {
        id: appMenu
        popupType: Popup.Item
        modal: false
        focus: true
        width: 200
        palette.text: Theme.Theme.text
        palette.windowText: Theme.Theme.text
        palette.highlight: Theme.Theme.elevated
        palette.highlightedText: Theme.Theme.text
        font.family: Theme.Theme.fontFamily
        onClosed: { if (root.service.opened) root.focusSearch() }
        background: Rectangle {
            color: Theme.Theme.surface; radius: 10
            border.width: 1; border.color: Theme.Theme.border
        }
        MenuItem {
            text: "Hide application"
            onTriggered: root.service.hide(root.contextId)
        }
    }
    color: root.embedded ? "transparent" : Qt.rgba(Theme.Theme.background.r, Theme.Theme.background.g, Theme.Theme.background.b, 1)
    radius: Theme.Theme.radius("surface", 22, width, height)
    border.color: Theme.Theme.border; border.width: root.embedded ? 0 : 1
    clip: true
    Image {
        anchors.fill: parent; anchors.margins: 12
        visible: root.preferences.backgroundEnabled
        source: visible && root.preferences.backgroundImage ? "file://" + root.preferences.backgroundImage : ""
        sourceSize: Qt.size(root.width * 2, root.height * 2)
        fillMode: Image.PreserveAspectCrop; opacity: 0.16
    }
    // Catch panel whitespace so it cannot dismiss the launcher.
    MouseArea { anchors.fill: parent; onClicked: root.focusSearch() }
    Image {
        id: header
        x: 12; width: parent.width - 24; height: root.headerHeight
        y: root.preferences.headerPosition === "top" ? 12 : parent.height - height - 12
        visible: height > 0
        source: visible ? "file://" + root.preferences.headerImage : ""
        sourceSize: Qt.size(width * 2, height * 2); fillMode: Image.PreserveAspectCrop
    }
    TextField {
        id: search
        x: 16; y: 16 + (root.preferences.headerPosition === "top" ? root.headerHeight : 0)
        width: parent.width - 32; height: 46
        placeholderText: "Search applications"
        text: root.service.query
        onTextEdited: root.service.query = text
        color: Theme.Theme.text; placeholderTextColor: Theme.Theme.subtext
        font.family: Theme.Theme.fontFamily; font.pixelSize: 15
        selectionColor: Theme.Theme.accent; selectedTextColor: Theme.Theme.accentText
        leftPadding: 14; rightPadding: 14
        background: Rectangle { color: Theme.Theme.surface; radius: 12; border.width: 1; border.color: search.activeFocus ? Theme.Theme.accent : Theme.Theme.border }
        Keys.priority: Keys.BeforeItem
        Keys.onPressed: event => { event.accepted = root.navigate(event.key, event.modifiers) }
    }
    GridView {
        id: results
        x: 16; y: search.y + search.height + 14; width: parent.width - 32
        height: Math.max(0, parent.height - y - 40 - (root.preferences.headerPosition === "bottom" ? root.headerHeight : 0))
        clip: true; boundsBehavior: Flickable.StopAtBounds
        cellWidth: width / root.columns; cellHeight: root.itemHeight
        model: root.service.results
        currentIndex: root.service.selected
        onCurrentIndexChanged: positionViewAtIndex(currentIndex, GridView.Contain)
        onCellWidthChanged: Qt.callLater(() => positionViewAtIndex(currentIndex, GridView.Contain))
        ScrollBar.vertical: ScrollBar {}
        delegate: LauncherItem {
            id: entry
            required property var modelData
            required property int index
            width: results.cellWidth - (root.grid ? 6 : 0); height: results.cellHeight - 4
            app: modelData; preferences: root.preferences; grid: root.grid
            selected: index === root.service.selected
            onChosen: { root.service.selected = index; root.service.launch(index) }
            onContextRequested: (pointerX, pointerY) => {
                root.service.selected = index
                root.showContext(modelData.id, entry.mapToItem(root, pointerX, pointerY))
            }
        }
        Text {
            anchors.centerIn: parent; visible: results.count === 0
            text: root.service.query ? "No matching applications" : "No applications available"
            color: Theme.Theme.subtext; font.family: Theme.Theme.fontFamily
        }
    }
    Text {
        x: 20; y: results.y + results.height + 8; width: parent.width - 40
        text: root.service.error || (root.service.busy ? "Opening…" : root.service.results.length + " applications  ·  Enter to open  ·  Esc to close")
        elide: Text.ElideRight; color: root.service.error ? Theme.Theme.warning : Theme.Theme.subtext
        font.family: Theme.Theme.fontFamily; font.pixelSize: 11
    }
}
