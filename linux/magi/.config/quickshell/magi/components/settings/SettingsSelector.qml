pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts
import "../../theme" as Theme
ComboBox {
    id: root
    objectName: "settingsSelector-" + Accessible.name
    property bool leftAligned: false
    readonly property bool roleSelector: {
        if (!model || !model.length) return false
        for (let i = 0; i < model.length; ++i)
            if (typeof model[i] !== "string" || Theme.Theme.roles[model[i]] === undefined) return false
        return true
    }
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
    contentItem: Item {
        implicitWidth: valueText.implicitWidth + (root.roleSelector ? 24 : 0)
        implicitHeight: valueText.implicitHeight
        Row {
            anchors.verticalCenter: parent.verticalCenter
            x: root.leftAligned ? 0 : Math.max(0,(parent.width-width)/2)
            width: Math.min(parent.width, valueText.implicitWidth + (root.roleSelector ? 24 : 0)); spacing: 8
            Rectangle {
                objectName: "settingsRoleSwatch"
                visible: root.roleSelector
                width: visible ? 16 : 0; height: 16; radius: 3
                anchors.verticalCenter: parent.verticalCenter
                color: root.roleSelector ? Theme.Theme.roles[root.currentText] || Theme.Theme.surface : "transparent"
                border.width: 1; border.color: Theme.Theme.text
            }
            Text {
                id: valueText
                objectName: "settingsSelectorValue"
                width: Math.max(0,parent.width - (root.roleSelector ? 24 : 0))
                text: root.displayText; font: root.font; color: Theme.Theme.text
                elide: Text.ElideRight; verticalAlignment: Text.AlignVCenter
            }
        }
    }
    indicator: Text {
        x: root.width - width - 10
        y: (root.height - height) / 2
        text: "⌄"; font.pixelSize: 16
        color: Theme.Theme.text
    }
    background: Rectangle {
        radius: Theme.Theme.radius("action", 8, width, height)
        color: root.down || root.hovered ? Theme.Theme.overlay : Theme.Theme.elevated
        border.width: 1; border.color: root.activeFocus ? Theme.Theme.focus : Theme.Theme.border
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
