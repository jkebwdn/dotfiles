pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts
import "../../services" as Services
import "../../theme" as Theme
SettingsSection {
    id: root
    property var numbers: []
    property var colors: []
    readonly property var paletteRoles: ["background", "surface", "elevated", "overlay", "text", "subtext", "muted", "accent", "blue", "lavender", "green", "yellow", "peach", "red", "teal", "border"]
    Layout.fillWidth: true
    collapsible: true
    Repeater {
        model: root.numbers
        SettingsRow {
            id: numberRow
            required property var modelData
            Layout.fillWidth: true
            columns: 2
            Label { text: numberRow.modelData.label; Layout.fillWidth: true; Layout.columnSpan: 2; wrapMode: Text.Wrap }
            SettingsSlider {
                objectName: "visualSetting-" + numberRow.modelData.key
                Accessible.name: numberRow.modelData.label
                Layout.fillWidth: true
                from: numberRow.modelData.min; to: numberRow.modelData.max; stepSize: numberRow.modelData.step
                value: Services.Settings.data.appearance.visual[numberRow.modelData.key]
                onMoved: Services.Settings.setVisual(numberRow.modelData.key, value)
            }
            Label {
                readonly property real setting: Services.Settings.data.appearance.visual[numberRow.modelData.key]
                text: numberRow.modelData.shade
                    ? (setting > 0 ? "+" : "") + Math.round(setting * 100) + "%"
                    : Number(setting).toFixed(numberRow.modelData.step < 1 ? 2 : 0)
                Layout.preferredWidth: 56
            }
        }
    }
    Repeater {
        model: root.colors
        SettingsRow {
            id: colorRow
            required property var modelData
            Layout.fillWidth: true
            columns: 2
            Label { text: colorRow.modelData.label; Layout.fillWidth: true; Layout.columnSpan: 2; wrapMode: Text.Wrap }
            SettingsSelector {
                Accessible.name: colorRow.modelData.label
                Layout.fillWidth: true
                model: root.paletteRoles
                currentIndex: model.indexOf(Services.Settings.data.appearance.visual[colorRow.modelData.key])
                onActivated: index => Services.Settings.setVisual(colorRow.modelData.key, model[index])
            }
            Rectangle { implicitWidth: 24; implicitHeight: 24; radius: 4; color: Theme.Theme.roles[Services.Settings.data.appearance.visual[colorRow.modelData.key]] }
        }
    }
}
