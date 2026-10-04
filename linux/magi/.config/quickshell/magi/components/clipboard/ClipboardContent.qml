pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts
import "../../theme" as Theme
import "../../services" as Services
import "../controls" as Controls
import "../settings" as SettingsUI

Pane {
    id: root
    required property var service
    property int selectedIndex: -1
    property string selectedId: ""
    padding: 18
    font.family: Theme.Theme.fontFamily
    font.pixelSize: 12
    palette.text: Theme.Theme.text
    palette.buttonText: Theme.Theme.text
    palette.highlight: Theme.Theme.accent
    palette.highlightedText: Theme.Theme.accentText
    background: Rectangle {
        color: Theme.Theme.background
        radius: Theme.Theme.radius("surface", 18, width, height)
        border.color: Theme.Theme.border; border.width: 1
    }
    function reconcile() {
        const found = service.rows.findIndex(e => e.id === selectedId)
        select(found >= 0 ? found : Math.min(Math.max(0, selectedIndex), service.rows.length - 1))
    }
    function select(index) {
        selectedIndex = Math.max(-1, Math.min(index, service.rows.length - 1))
        selectedId = selectedIndex >= 0 ? service.rows[selectedIndex].id : ""
        if (selectedIndex >= 0) history.positionViewAtIndex(selectedIndex, ListView.Contain)
    }
    function begin() {
        search.text = ""
        service.query = ""
        selectedId = ""
        reconcile()
        search.forceActiveFocus()
    }
    function navigate(event) {
        if (event.key === Qt.Key_Escape) service.opened = false
        else if (event.key === Qt.Key_Down) select(Math.min(service.rows.length - 1, selectedIndex + 1))
        else if (event.key === Qt.Key_Up) select(Math.max(0, selectedIndex - 1))
        else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
            if (selectedId) service.restore(selectedId)
        } else if (event.key === Qt.Key_P && event.modifiers & Qt.ControlModifier) {
            if (selectedId) service.pin(selectedId)
        } else if (event.key === Qt.Key_Delete && event.modifiers & Qt.ControlModifier) {
            if (selectedId) service.remove(selectedId)
        } else if (event.key === Qt.Key_L && event.modifiers & Qt.ControlModifier) search.forceActiveFocus()
        else return
        event.accepted = true
    }
    Keys.onPressed: event => navigate(event)
    Connections { target: root.service; function onRowsChanged() { root.reconcile() } }
    ColumnLayout {
        anchors.fill: parent
        spacing: 12
        RowLayout {
            Layout.fillWidth: true
            Controls.Icon { role: "clipboard"; size: 22; color: Theme.Theme.accent }
            Label { text: "Clipboard"; font.pixelSize: 19; font.bold: true; Layout.fillWidth: true }
            Label { text: root.service.count; color: Theme.Theme.subtext }
            ClipboardIconButton {
                role: "settings"; label: "Clipboard settings"
                onClicked: {
                    root.service.opened = false
                    Services.SettingsWindowState.page = "Clipboard"
                    Services.SettingsWindowState.open()
                }
            }
            ClipboardIconButton { role: "close"; label: "Close Clipboard (Escape)"; onClicked: root.service.opened = false }
        }
        TextField {
            id: search
            objectName: "clipboardSearch"
            Layout.fillWidth: true; Layout.preferredHeight: 42
            placeholderText: "Search clipboard…"
            color: Theme.Theme.text
            placeholderTextColor: Theme.Theme.subtext
            selectionColor: Theme.Theme.accent
            selectedTextColor: Theme.Theme.accentText
            selectByMouse: true
            maximumLength: 512
            leftPadding: 12
            onTextChanged: root.service.query = text
            Keys.priority: Keys.BeforeItem
            Keys.onPressed: event => root.navigate(event)
            background: Rectangle {
                color: Theme.Theme.surface
                radius: Theme.Theme.radius("action", 10, width, height)
                border.color: search.activeFocus ? Theme.Theme.focus : Theme.Theme.border
                border.width: 1
            }
        }
        RowLayout {
            Layout.fillWidth: true
            SettingsUI.SettingsButton {
                text: root.service.preferences.enabled ? "Pause collection" : "Resume collection"
                onClicked: Services.Settings.setValue("clipboard", "enabled", !root.service.preferences.enabled)
            }
            Item { Layout.fillWidth: true }
            SettingsUI.SettingsButton {
                text: "Clear unpinned"; enabled: root.service.ready && root.service.count > 0
                onClicked: root.service.clear()
            }
        }
        Label {
            Layout.fillWidth: true
            visible: !!root.service.error || !root.service.monitoring
            text: root.service.error || (root.service.preferences.enabled ? "Starting clipboard capture…" : "Collection paused · history is still available")
            color: root.service.error ? Theme.Theme.warning : Theme.Theme.subtext
            wrapMode: Text.WordWrap
        }
        ListView {
            id: history
            Layout.fillWidth: true; Layout.fillHeight: true
            clip: true; spacing: 8
            boundsBehavior: Flickable.StopAtBounds
            model: root.service.rows
            ScrollBar.vertical: ScrollBar {}
            delegate: Rectangle {
                id: card
                required property var modelData
                required property int index
                width: history.width - 10
                height: modelData.category === "image" ? 132 : 100
                radius: Theme.Theme.radius("surface", 11, width, height)
                color: root.selectedId === modelData.id ? Theme.Theme.elevated : Theme.Theme.surface
                border.color: root.selectedId === modelData.id ? Theme.Theme.shadeAccent(Theme.Theme.accent, .25) : Theme.Theme.border
                border.width: 1
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: { root.select(card.index); root.service.restore(card.modelData.id) }
                }
                RowLayout {
                    anchors.fill: parent; anchors.margins: 12; spacing: 12
                    Controls.RoundedArtwork {
                        visible: card.modelData.category === "image"
                        Layout.preferredWidth: 106; Layout.preferredHeight: 106
                        source: card.modelData.thumbnail
                        radius: Theme.Theme.radius("action", 9, width, height)
                        borderWidth: 0; placeholder: "image"
                    }
                    ColumnLayout {
                        Layout.fillWidth: true; Layout.fillHeight: true
                        spacing: 6
                        RowLayout {
                            Controls.Icon {
                                role: card.modelData.category === "files" ? "file" : card.modelData.category === "image" ? "image" : "clipboard"
                                size: 13; color: Theme.Theme.subtext
                            }
                            Label {
                                Layout.fillWidth: true
                                text: (card.modelData.pinned ? "Pinned · " : "") + (card.modelData.category === "files" ? "Files / URIs" : card.modelData.category === "image" ? "Image" : "Text")
                                font.pixelSize: 10; color: card.modelData.pinned ? Theme.Theme.accent : Theme.Theme.subtext
                            }
                            Label { text: Qt.formatDateTime(new Date(card.modelData.timestamp * 1000), "hh:mm"); font.pixelSize: 10; color: Theme.Theme.muted }
                        }
                        Text {
                            Layout.fillWidth: true; Layout.fillHeight: true
                            text: card.modelData.preview
                            textFormat: Text.PlainText
                            color: Theme.Theme.text; font.family: Theme.Theme.fontFamily; font.pixelSize: 12
                            wrapMode: Text.Wrap; maximumLineCount: 3; elide: Text.ElideRight
                        }
                    }
                    ColumnLayout {
                        ClipboardIconButton {
                            role: "pin"; label: card.modelData.pinned ? "Unpin (Ctrl+P)" : "Pin (Ctrl+P)"
                            highlightedState: card.modelData.pinned
                            onClicked: { root.select(card.index); root.service.pin(card.modelData.id) }
                        }
                        ClipboardIconButton {
                            role: "delete"; label: "Delete entry (Ctrl+Delete)"
                            onClicked: { root.select(card.index); root.service.remove(card.modelData.id) }
                        }
                    }
                }
            }
            Label {
                anchors.centerIn: parent
                width: parent.width - 40
                visible: history.count === 0
                text: root.service.query ? "No matching copies" : "A fresh clipboard\nCopy something to start your history."
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.WordWrap
                color: Theme.Theme.subtext
            }
        }
        Label {
            Layout.fillWidth: true; wrapMode: Text.WordWrap
            text: "↑ ↓ select   Enter copy   Ctrl+P pin   Ctrl+Delete remove\n" + (root.service.preferences.persistHistory ? "Saved on disk" : "Session only") + " · Sensitive hints are respected; unmarked secrets cannot be detected."
            font.pixelSize: 10; color: Theme.Theme.subtext
        }
    }
}
