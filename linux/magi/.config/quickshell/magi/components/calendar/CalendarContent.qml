pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls.Basic
import "../../theme" as Theme
import "../settings" as SettingsUI
Item {
    id: root
    required property var service
    readonly property var model: service.model
    readonly property real cellHeight: service.preferences.density === "compact" ? 32 : 38
    readonly property real weekWidth: service.preferences.showWeekNumbers ? 28 : 0
    implicitHeight: 116 + 6 * cellHeight
    function requestInitialFocus() { root.forceActiveFocus() }
    function navigate(key) {
        if (key === Qt.Key_Escape) service.close()
        else if (key === Qt.Key_Left) model.moveDays(-1)
        else if (key === Qt.Key_Right) model.moveDays(1)
        else if (key === Qt.Key_Up) model.moveDays(-7)
        else if (key === Qt.Key_Down) model.moveDays(7)
        else if (key === Qt.Key_PageUp) model.moveMonths(-1)
        else if (key === Qt.Key_PageDown) model.moveMonths(1)
        else if (key === Qt.Key_Home) model.resetToday()
        else return false
        return true
    }
    Keys.onPressed: event => { event.accepted = navigate(event.key) }
    Column {
        width: parent.width; spacing: 4
        Text {
            text: root.model.selectedWeekday
            color: Theme.Theme.subtext; font.family: Theme.Theme.fontFamily; font.pixelSize: 13
        }
        Text {
            width: parent.width; elide: Text.ElideRight
            text: root.model.selectedLabel
            color: Theme.Theme.text; font.family: Theme.Theme.fontFamily; font.pixelSize: 20; font.bold: true
        }
    }
    Row {
        id: navigation
        y: 56; width: parent.width; height: 32; spacing: 4
        SettingsUI.SettingsButton {
            width: 28; height: 30; text: "‹"; Accessible.name: "Previous month"
            palette.buttonText: Theme.Theme.text
            onClicked: { root.model.moveMonths(-1); root.requestInitialFocus() }
        }
        Text {
            width: parent.width - 28 * 2 - 58 - 12; height: 30
            text: root.model.monthLabel; elide: Text.ElideRight
            verticalAlignment: Text.AlignVCenter; horizontalAlignment: Text.AlignHCenter
            color: Theme.Theme.text; font.family: Theme.Theme.fontFamily; font.pixelSize: 13
        }
        SettingsUI.SettingsButton {
            width: 28; height: 30; text: "›"; Accessible.name: "Next month"
            palette.buttonText: Theme.Theme.text
            onClicked: { root.model.moveMonths(1); root.requestInitialFocus() }
        }
        SettingsUI.SettingsButton {
            width: 58; height: 30; text: "Today"
            palette.buttonText: Theme.Theme.text; font.family: Theme.Theme.fontFamily; font.pixelSize: 11
            onClicked: { root.model.resetToday(); root.requestInitialFocus() }
        }
    }
    Row {
        x: root.weekWidth; y: 94; width: parent.width - x
        Repeater {
            model: root.model.weekdayNames
            Text {
                required property string modelData
                width: (root.width - root.weekWidth) / 7; height: 22
                text: modelData; elide: Text.ElideRight; horizontalAlignment: Text.AlignHCenter
                color: Theme.Theme.subtext; font.family: Theme.Theme.fontFamily; font.pixelSize: 11
            }
        }
    }
    Column {
        y: 116; width: root.weekWidth
        visible: root.weekWidth > 0
        Repeater {
            model: root.model.weekNumbers
            Text {
                required property var modelData
                width: root.weekWidth; height: root.cellHeight
                text: modelData.week; color: Theme.Theme.muted
                font.family: Theme.Theme.fontFamily; font.pixelSize: 10
                horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter
                Accessible.name: "ISO week " + modelData.week + ", " + modelData.year
            }
        }
    }
    Grid {
        x: root.weekWidth; y: 116; width: parent.width - x; columns: 7
        Repeater {
            model: root.model.cells
            Rectangle {
                id: cell
                required property var modelData
                width: (root.width - root.weekWidth) / 7; height: root.cellHeight
                radius: Theme.Theme.radius("action", 8, width, height)
                color: !modelData.shown ? "transparent" : modelData.selected ? Theme.Theme.elevated
                    : pointer.containsMouse ? Theme.Theme.overlay : "transparent"
                border.width: modelData.today && modelData.shown ? 1 : 0
                border.color: Theme.Theme.accent
                Accessible.role: Accessible.Button
                Accessible.name: modelData.date.toLocaleDateString(root.model.locale, Locale.LongFormat)
                Accessible.ignored: !modelData.shown
                Accessible.onPressAction: { root.model.select(modelData.date); root.requestInitialFocus() }
                Text {
                    anchors.centerIn: parent; visible: cell.modelData.shown
                    text: cell.modelData.day
                    color: cell.modelData.today ? Theme.Theme.accent : cell.modelData.inMonth ? Theme.Theme.text : Theme.Theme.muted
                    font.family: Theme.Theme.fontFamily; font.pixelSize: 13
                    font.bold: cell.modelData.today || cell.modelData.selected
                }
                MouseArea {
                    id: pointer
                    anchors.fill: parent; enabled: cell.modelData.shown; hoverEnabled: true
                    onClicked: { root.model.select(cell.modelData.date); root.requestInitialFocus() }
                }
            }
        }
    }
}
