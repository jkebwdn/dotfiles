pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts
import "../../theme" as Theme
ComboBox {
    id: root
    objectName: "settingsSelector-" + Accessible.name
    implicitWidth: 208
    implicitHeight: SettingsMetrics.controlHeight
    Layout.maximumWidth: 260
    leftPadding: 10; rightPadding: 28
    focusPolicy: Qt.StrongFocus
    opacity: enabled ? 1 : SettingsMetrics.disabledOpacity
    palette.buttonText: Theme.Theme.text
    palette.text: Theme.Theme.text
    palette.highlight: Theme.Theme.accent
    palette.highlightedText: Theme.Theme.accentText
    indicator: Text {
        x: root.width - width - 10
        y: (root.height - height) / 2
        text: "⌄"; font.pixelSize: 16
        color: Theme.Theme.text
    }
    background: Rectangle {
        radius: Theme.Theme.radius("action", 8, width, height)
        color: root.down || root.hovered ? Theme.Theme.elevated : root.flat ? "transparent" : Theme.Theme.surface
    }
    delegate: ItemDelegate {
        required property int index
        width: ListView.view ? ListView.view.width : root.width
        implicitHeight: SettingsMetrics.controlHeight
        text: root.textAt(index)
        highlighted: root.highlightedIndex === index
        contentItem: Text {
            text: parent.text
            font: root.font
            color: parent.highlighted ? Theme.Theme.accentText : Theme.Theme.text
            elide: Text.ElideRight
            verticalAlignment: Text.AlignVCenter
        }
        background: Rectangle {
            radius: Theme.Theme.radius("action", 6, width, height)
            color: parent.highlighted ? Theme.Theme.accent : "transparent"
        }
    }
    popup: Popup {
        y: root.height + 4
        width: root.width
        padding: 4
        margins: 8
        implicitHeight: Math.min(300, list.contentHeight + 8)
        contentItem: ListView {
            id: list
            clip: true
            implicitHeight: contentHeight
            model: root.delegateModel
            currentIndex: root.highlightedIndex
            highlightMoveDuration: 0
            ScrollBar.vertical: ScrollBar {}
        }
        background: Rectangle {
            color: Theme.Theme.surface
            radius: Theme.Theme.radius("surface", 10, width, height)
            border.width: 1; border.color: Theme.Theme.border
        }
    }
    SettingsFocus {}
}
