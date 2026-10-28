pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Window
import QtQuick.Controls.Basic
import QtQuick.Layouts
import "../../theme" as Theme
import "../../services" as Services

ColumnLayout {
    id: gallery
    objectName: "themeGallery"
    Layout.fillWidth: true
    Layout.minimumWidth: 0
    spacing: 16
    property bool expanded: false
    property int filter: 0
    property var previewThemes: []
    property string focusId: ""
    readonly property var model: Theme.ThemeRegistry.themes
    readonly property var groups: {
        if (!expanded) return previewThemes.length ? [{family: previewThemes[0].family, themes: previewThemes}] : []
        const result = []
        for (const theme of model) {
            if ((filter === 1 && !theme.dark) || (filter === 2 && theme.dark)) continue
            let group = result.find(value => value.family === theme.family)
            if (!group) { group = {family: theme.family, themes: []}; result.push(group) }
            group.themes.push(theme)
        }
        return result
    }
    readonly property var visibleThemes: groups.reduce((themes, group) => themes.concat(group.themes), [])
    readonly property int count: visibleThemes.length
    readonly property int columns: Math.max(1, Math.floor((width + 12) / (176 + 12)))
    readonly property real cardWidth: Math.min(220, Math.max(0, (width - (columns - 1) * 12) / columns))
    readonly property real cardHeight: 138
    readonly property string selectedId: Services.Settings.data.appearance.theme
    readonly property int currentIndex: visibleThemes.findIndex(theme => theme.id === selectedId)
    readonly property string tabId: visibleThemes.some(theme => theme.id === focusId) ? focusId
        : currentIndex >= 0 ? selectedId : count ? visibleThemes[0].id : ""

    // Keep a single row, including the selected variant. Preserve the existing
    // row while selecting another visible card so focus/card instances stay put.
    function updatePreview() {
        if (!model || !selectedId) return
        const family = Theme.ThemeRegistry.resolve(selectedId).family
        const members = model.filter(theme => theme.family === family)
        const size = Math.min(columns, members.length)
        if (previewThemes.length === size && previewThemes.every(theme => theme.family === family)
                && previewThemes.some(theme => theme.id === selectedId)) return
        const index = Math.max(0, members.findIndex(theme => theme.id === selectedId))
        const start = Math.max(0, Math.min(index - Math.floor(size / 2), members.length - size))
        previewThemes = members.slice(start, start + size)
    }
    onSelectedIdChanged: updatePreview()
    onColumnsChanged: updatePreview()
    onModelChanged: updatePreview()
    Component.onCompleted: updatePreview()

    function itemAt(index) {
        for (let g = 0; g < families.count; ++g) {
            const section = families.itemAt(g)
            if (index < section.cards.count) return section.cards.itemAt(index)
            index -= section.cards.count
        }
        return null
    }
    function reveal(index) {
        revealItem(itemAt(index))
    }
    function revealItem(card) {
        if (!card) return
        // The Settings page owns scrolling; the gallery never creates a nested
        // horizontal or vertical viewport.
        for (let view = parent; view; view = view.parent) {
            if (view.contentY === undefined || view.cancelFlick === undefined) continue
            let owner = card
            while (owner && owner !== view) owner = owner.parent
            if (!owner) return
            const point = card.mapToItem(view, 0, 0)
            let delta = point.y < 0 ? point.y : point.y + card.height > view.height ? point.y + card.height - view.height : 0
            view.cancelFlick()
            view.contentY = Math.max(view.originY, Math.min(view.originY + Math.max(0, view.contentHeight - view.height), view.contentY + delta))
            return
        }
    }
    function focusIndex(index) {
        index = Math.max(0, Math.min(count - 1, index))
        const card = itemAt(index)
        if (card) { focusId = card.modelData.id; card.forceActiveFocus(Qt.TabFocusReason); reveal(index) }
    }
    function verticalIndex(index, direction) {
        let start = 0
        for (let g = 0; g < groups.length; ++g) {
            const size = groups[g].themes.length
            if (index >= start + size) { start += size; continue }
            const local = index - start, column = local % columns
            if (direction > 0) {
                if (Math.floor(local / columns) < Math.floor((size - 1) / columns))
                    return start + Math.min(size - 1, local + columns)
                return g + 1 < groups.length ? start + size + Math.min(column, groups[g + 1].themes.length - 1) : index
            }
            if (local >= columns) return index - columns
            if (g === 0) return index
            const previous = groups[g - 1].themes.length
            return start - previous + Math.floor((previous - 1) / columns) * columns
                + Math.min(column, (previous - 1) % columns)
        }
        return index
    }
    RowLayout {
        Layout.fillWidth: true
        spacing: 12
        SettingsButton {
            id: disclosure
            objectName: "themeGalleryDisclosure"
            text: gallery.expanded ? "Show fewer themes  ▴" : "Show all themes  ▾"
            Accessible.name: gallery.expanded ? "Show fewer themes" : "Show all themes"
            checked: gallery.expanded
            actionKind: "navigation"
            onClicked: {
                gallery.expanded = !gallery.expanded
                Qt.callLater(() => gallery.revealItem(disclosure))
            }
        }
        Label {
            Layout.fillWidth: true
            Layout.minimumWidth: 0
            horizontalAlignment: Text.AlignRight
            text: "Current · " + Theme.ThemeRegistry.resolve(gallery.selectedId).label
            color: Theme.Theme.subtext
            elide: Text.ElideRight
            ToolTip.visible: hovered.hovered && truncated
            ToolTip.text: text
            HoverHandler { id: hovered }
        }
    }
    RowLayout {
        Layout.fillWidth: true
        visible: gallery.expanded
        spacing: 6
        Repeater {
            model: ["All", "Dark", "Light"]
            SettingsButton {
                required property string modelData
                required property int index
                objectName: "themeFilter-" + modelData
                text: modelData
                primary: gallery.filter === index
                Accessible.name: modelData + " themes"
                Accessible.role: Accessible.RadioButton
                Accessible.checked: gallery.filter === index
                onClicked: gallery.filter = index
            }
        }
        Item { Layout.fillWidth: true }
    }
    Repeater {
        id: families
        model: gallery.groups
        ColumnLayout {
            id: section
            required property var modelData
            property alias cards: cards
            objectName: "themeFamily-" + modelData.family
            Layout.fillWidth: true
            Layout.minimumWidth: 0
            spacing: 8
            Label {
                text: section.modelData.family
                color: Theme.Theme.subtext
                font.bold: true
                Accessible.role: Accessible.Heading
            }
            Grid {
                Layout.fillWidth: true
                columns: gallery.columns
                spacing: 12
                Repeater {
                    id: cards
                    model: section.modelData.themes
                    SettingsChoiceCard {
                        id: card
                        required property var modelData
                        readonly property int flatIndex: gallery.visibleThemes.findIndex(theme => theme.id === modelData.id)
                        objectName: "themeChoice-" + modelData.id
                        width: gallery.cardWidth
                        height: gallery.cardHeight
                        text: modelData.label
                        activeFocusOnTab: activeFocus || gallery.tabId === modelData.id
                        selected: gallery.selectedId === modelData.id
                        onClicked: Services.Settings.setTheme(modelData.id)
                        onNavigate: delta => gallery.focusIndex(flatIndex + delta)
                        Keys.onTabPressed: event => {
                            event.accepted = false
                            Qt.callLater(() => gallery.revealItem(gallery.Window.window.activeFocusItem))
                        }
                        Keys.onBacktabPressed: event => {
                            event.accepted = false
                            Qt.callLater(() => gallery.revealItem(gallery.Window.window.activeFocusItem))
                        }
                        Keys.onUpPressed: gallery.focusIndex(gallery.verticalIndex(flatIndex, -1))
                        Keys.onDownPressed: gallery.focusIndex(gallery.verticalIndex(flatIndex, 1))
                        onActiveFocusChanged: if (activeFocus) {
                            gallery.focusId = modelData.id
                            gallery.reveal(flatIndex)
                        }
                        Rectangle {
                            anchors.fill: parent
                            color: card.modelData.roles.background
                            radius: Theme.Theme.radius("action", 6, width, height)
                            Rectangle {
                                anchors.fill: parent; anchors.margins: 7
                                color: card.modelData.roles.surface
                                radius: Theme.Theme.radius("action", 5, width, height)
                                Text { x: 8; y: 4; text: "Aa"; color: card.modelData.roles.text; font.pixelSize: 20; font.weight: Font.DemiBold }
                                Text { x: 40; y: 10; text: "Text"; color: card.modelData.roles.subtext; font.pixelSize: 11 }
                                Rectangle {
                                    anchors.right: parent.right; anchors.top: parent.top; anchors.margins: 7
                                    width: 22; height: 22; radius: 5
                                    color: card.modelData.roles.elevated
                                    Rectangle { anchors.centerIn: parent; width: 10; height: 10; radius: 3; color: card.modelData.roles.accent }
                                }
                                Row {
                                    anchors.left: parent.left; anchors.bottom: parent.bottom; anchors.margins: 8
                                    spacing: 4
                                    Repeater {
                                        model: ["accent", "lavender", "blue", "success", "warning", "danger"]
                                        Rectangle {
                                            required property string modelData
                                            width: 13; height: 7; radius: 3
                                            color: card.modelData.roles[modelData]
                                        }
                                    }
                                }
                            }
                            // Selection remains distinct even while another card has focus.
                            Rectangle {
                                visible: card.selected
                                anchors.right: parent.right; anchors.top: parent.top
                                width: 18; height: 18; radius: 9
                                color: Theme.Theme.accent
                                Text { anchors.centerIn: parent; text: "✓"; color: Theme.Theme.accentText; font.pixelSize: 12 }
                            }
                        }
                    }
                }
            }
        }
    }
}
