pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls.Basic
import "../../theme" as Theme
import "../hub" as HubUI
Rectangle {
    id: root
    required property var service
    property bool embedded: false
    readonly property var preferences: service.preferences
    readonly property int columns: Math.min(preferences.gridColumns, Math.max(1, Math.floor((width - 32) / (preferences.emojiSize + 20))))
    readonly property int cellSize: preferences.emojiSize + 24
    readonly property int desiredHeight: 148 + 5 * cellSize
    property alias searchField: search
    property alias gridView: grid
    function focusSearch() { search.forceActiveFocus() }
    function navigate(key, modifiers) {
        if (key === Qt.Key_Escape) service.close()
        else if (key === Qt.Key_Return || key === Qt.Key_Enter) service.choose(service.selected)
        else if ((modifiers & Qt.ControlModifier) && (key === Qt.Key_Left || key === Qt.Key_Right)) {
            const categories = service.categories
            const delta = key === Qt.Key_Right ? 1 : -1
            service.chooseCategory(categories[(categories.indexOf(service.category) + delta + categories.length) % categories.length])
        }
        else if (key === Qt.Key_Down) service.move(columns)
        else if (key === Qt.Key_Up) service.move(-columns)
        else if (key === Qt.Key_Right) service.move(1)
        else if (key === Qt.Key_Left) service.move(-1)
        else if (key === Qt.Key_PageDown) service.move(columns * 5)
        else if (key === Qt.Key_PageUp) service.move(-columns * 5)
        else return false
        return true
    }
    color: root.embedded ? "transparent" : Theme.Theme.surface
    radius: Theme.Theme.radius("surface", 22, width, height)
    border.color: Theme.Theme.border; border.width: root.embedded ? 0 : 1
    clip: true
    MouseArea { anchors.fill: parent; onClicked: root.focusSearch() }
    HubUI.HubSearchField {
        id: search
        x: 16; y: 16; width: parent.width - 32; height: 46
        placeholderText: "Search emoji"
        text: root.service.query
        onTextEdited: root.service.query = text
        Keys.priority: Keys.BeforeItem
        Keys.onPressed: event => { event.accepted = root.navigate(event.key, event.modifiers) }
    }
    ComboBox {
        id: category
        x: 16; y: search.y + search.height + 8; width: parent.width - 32; height: visible ? 32 : 0
        visible: root.preferences.showCategories
        model: root.service.categories
        currentIndex: root.service.categories.indexOf(root.service.category)
        focusPolicy: Qt.NoFocus
        onActivated: { root.service.chooseCategory(currentText); root.focusSearch() }
        palette.text: Theme.Theme.text; palette.buttonText: Theme.Theme.text
        palette.button: Theme.Theme.surface; palette.base: Theme.Theme.surface
        palette.window: Theme.Theme.surface; palette.windowText: Theme.Theme.text
        palette.highlight: Theme.Theme.elevated; palette.highlightedText: Theme.Theme.text
        font.family: Theme.Theme.fontFamily; font.pixelSize: 12
        background: Rectangle { color: Theme.Theme.surface; radius: 8; border.width: 1; border.color: Theme.Theme.border }
        ToolTip.visible: hovered
        ToolTip.text: "Ctrl + Left / Right changes category · Search spans all categories"
    }
    Row {
        id: recentRow
        objectName: "emojiRecentRow"
        x: 16; y: category.y + category.height + 8
        width: parent.width - 32
        height: visible ? root.cellSize : 0
        visible: !root.service.query && recentRepeater.count > 0
        Repeater {
            id: recentRepeater
            model: (root.service.recentEntries || []).slice(0, Math.min(10, root.columns))
            Button {
                required property var modelData
                required property int index
                width: recentRow.width / root.columns; height: root.cellSize - 4
                Accessible.name: "Recent: " + modelData.name
                text: modelData.emoji
                font.family: "Noto Color Emoji"; font.pixelSize: root.preferences.emojiSize
                background: Rectangle { radius: 8; color: parent.hovered ? Theme.Theme.elevated : "transparent" }
                onClicked: { root.service.chooseRecent(index); root.focusSearch() }
                ToolTip.visible: hovered; ToolTip.text: modelData.name
            }
        }
    }
    Rectangle {
        x: 16; y: recentRow.y + recentRow.height
        width: parent.width - 32; height: 1
        visible: recentRow.visible; color: Theme.Theme.border
    }
    GridView {
        id: grid
        x: 16; y: recentRow.y + recentRow.height + (recentRow.visible ? 8 : 0); width: parent.width - 32
        height: Math.max(0, parent.height - y - 42)
        cellWidth: width / root.columns; cellHeight: root.cellSize
        clip: true; boundsBehavior: Flickable.StopAtBounds
        model: root.service.results
        currentIndex: root.service.selected
        onCurrentIndexChanged: positionViewAtIndex(currentIndex, GridView.Contain)
        onModelChanged: Qt.callLater(() => positionViewAtIndex(currentIndex, GridView.Contain))
        ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }
        delegate: Rectangle {
            id: entry
            required property var modelData
            required property int index
            width: grid.cellWidth - 4; height: grid.cellHeight - 4
            radius: Theme.Theme.radius("action", 10, width, height)
            color: index === root.service.selected ? Theme.Theme.elevated : pointer.containsMouse ? Theme.Theme.surface : "transparent"
            border.width: index === root.service.selected ? 1 : 0
            border.color: Theme.Theme.accent
            Accessible.role: Accessible.Button
            Accessible.name: modelData.name
            Accessible.onPressAction: root.service.choose(index)
            Text {
                anchors.centerIn: parent; text: entry.modelData.emoji
                font.family: "Noto Color Emoji"; font.pixelSize: root.preferences.emojiSize
                textFormat: Text.PlainText
            }
            MouseArea {
                id: pointer
                anchors.fill: parent; hoverEnabled: true
                onClicked: { root.service.selected = entry.index; root.service.choose(entry.index); root.focusSearch() }
            }
            ToolTip.visible: pointer.containsMouse
            ToolTip.delay: 400
            ToolTip.text: modelData.name
        }
        Text {
            anchors.centerIn: parent; width: parent.width; horizontalAlignment: Text.AlignHCenter; wrapMode: Text.WordWrap
            visible: grid.count === 0
            text: root.service.dataError || (root.service.query ? "No matching emoji" : "Loading emoji…")
            color: Theme.Theme.subtext; font.family: Theme.Theme.fontFamily
        }
    }
    Text {
        x: 20; y: grid.y + grid.height + 10; width: parent.width - 40
        text: root.service.error || root.service.message || (root.service.busy ? "Copying…" :
            (root.service.results[root.service.selected] ? root.service.results[root.service.selected].name : "Emoji") + " · Enter to copy")
        textFormat: Text.PlainText; elide: Text.ElideRight
        color: root.service.error ? Theme.Theme.warning : Theme.Theme.subtext
        font.family: Theme.Theme.fontFamily; font.pixelSize: 11
    }
}
