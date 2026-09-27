pragma ComponentBehavior: Bound
import QtQuick
import ".." as SettingsUI
import QtQuick.Controls.Basic
import QtQuick.Layouts
import "../../../services" as Services
import "../../../theme" as Theme
import "../../../modules" as Modules
Flickable {
    id: root
    property real outputWidth: 1920
    readonly property int effectiveColumns: Math.max(1, Math.min(Services.Settings.data.controlCentre.columns, Math.floor((outputWidth - 56 + 18) / 78)))
    contentHeight: content.implicitHeight + 48
    clip: true
    ScrollBar.vertical: ScrollBar {}
    ColumnLayout {
        id: content
        x: 24; y: 24; width: root.width - 48
        spacing: 16
        Label { text: "Control Centre"; font.pixelSize: 26; font.bold: true }
        Label { text: "Controls resize and reflow the shared surface live. Password/network sessions defer layout changes until safe."; wrapMode: Text.WordWrap; Layout.fillWidth: true; color: Theme.Theme.subtext }
        RowLayout {
            Label { text: "Columns" }
            SpinBox { from: 1; to: 16; value: Services.Settings.data.controlCentre.columns; onValueModified: Services.Settings.setValue("controlCentre","columns",value) }
            Label { text: "Fits " + root.effectiveColumns + " on this output"; color: Theme.Theme.subtext; Layout.fillWidth: true }
            SettingsUI.SettingsButton { text: "Preview"; onClicked: Services.MenuController.open("controlcentre") }
        }
        Label { text: "Top controls · " + Services.Settings.data.controlCentre.controls.filter(e => e.enabled).length + " enabled"; font.bold: true }
        Repeater {
            model: Services.Settings.data.controlCentre.controls
            RowLayout {
                id: row
                required property var modelData
                required property int index
                Layout.fillWidth: true
                CheckBox { checked: row.modelData.enabled; Accessible.name: "Enable control"; onToggled: Services.Settings.editControl(row.modelData.key,"enabled",checked) }
                ComboBox {
                    Layout.fillWidth: true
                    model: Modules.ControlCatalog.definitions.filter(d => d.id === row.modelData.module || !Services.Settings.data.controlCentre.controls.some(e => e.module === d.id))
                    textRole: "label"
                    currentIndex: model.findIndex(d => d.id === row.modelData.module)
                    onActivated: index => Services.Settings.editControl(row.modelData.key,"module",model[index].id)
                }
                SettingsUI.SettingsButton { text: "↑"; Accessible.name: "Move earlier"; enabled: row.index > 0; onClicked: Services.Settings.moveControl(row.modelData.key,-1) }
                SettingsUI.SettingsButton { text: "↓"; Accessible.name: "Move later"; enabled: row.index < Services.Settings.data.controlCentre.controls.length - 1; onClicked: Services.Settings.moveControl(row.modelData.key,1) }
                SettingsUI.SettingsButton { text: "−"; Accessible.name: "Remove control"; onClicked: Services.Settings.removeControl(row.modelData.key) }
            }
        }
        RowLayout {
            ComboBox {
                id: addChoice
                Layout.fillWidth: true
                model: Modules.ControlCatalog.definitions.filter(d => !Services.Settings.data.controlCentre.controls.some(e => e.module === d.id))
                textRole: "label"
            }
            SettingsUI.SettingsButton { text: "Add control"; enabled: addChoice.currentIndex >= 0; onClicked: Services.Settings.addControl(addChoice.model[addChoice.currentIndex].id) }
        }
        Label { text: "Sliders"; font.bold: true }
        Repeater {
            model: Services.Settings.data.controlCentre.sliders
            CheckBox {
                required property var modelData
                text: modelData.module
                checked: modelData.enabled
                onToggled: {
                    const entries = JSON.parse(JSON.stringify(Services.Settings.data.controlCentre.sliders))
                    entries.find(e => e.key === modelData.key).enabled = checked
                    Services.Settings.setValue("controlCentre","sliders",entries)
                }
            }
        }
        SettingsUI.SettingsButton { text: "Reset Control Centre"; onClicked: Services.Settings.resetSection("controlCentre") }
    }
}
