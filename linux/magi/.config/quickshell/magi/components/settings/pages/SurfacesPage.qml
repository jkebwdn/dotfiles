import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts
import "../../../services" as Services
import "../../../theme" as Theme
import ".." as SettingsUI
import "../../../settings/SettingsSchema.js" as Schema
SettingsUI.SettingsPage {
    title: "Surfaces"
    SettingsUI.SettingsRow {
        Label { text: "Navigation accent"; Layout.fillWidth: true }
        SettingsUI.SettingsSelector {
            Accessible.name: "Navigation accent"
            model: ["background","surface","elevated","overlay","text","subtext","muted","accent","blue","lavender","green","yellow","peach","red","teal","border"]
            currentIndex: model.indexOf(Services.Settings.data.appearance.navigationAccent)
            onActivated: Services.Settings.setValue("appearance", "navigationAccent", currentText)
        }
    }
    SettingsUI.SettingsRow {
        Label { text: "Toggle style"; Layout.fillWidth: true }
        SettingsUI.SettingsSelector {
            Accessible.name: "Toggle style"; model: ["Pill", "Filled", "Minimal"]
            currentIndex: ["pill","filled","minimal"].indexOf(Services.Settings.data.appearance.toggleStyle)
            onActivated: Services.Settings.setValue("appearance", "toggleStyle", ["pill","filled","minimal"][currentIndex])
        }
    }
    SettingsUI.SurfaceStyleSettings { title: "Expanded surface border"; group: "surfaceBorders"; targets: [
        {id:"controlcentre",label:"Control Centre"},{id:"wifi",label:"Wi-Fi"},{id:"bluetooth",label:"Bluetooth"},
        {id:"hubContent",label:"Hub content"},{id:"hubSelector",label:"Hub selector"}] }
    SettingsUI.SurfaceStyleSettings { title: "History and notification card borders"; group: "notificationBorders"; targets: [
        {id:"toasts",label:"Toast borders"},{id:"history",label:"Notification history"},{id:"clipboard",label:"Clipboard card borders"}] }
    SettingsUI.SettingsSection {
        title: "Roundness and status icons"
        collapsible: false
        Label { text: "Roundness"; font.bold: true }
        Label { text: "Square (0) → reference (1) → rounder (2). Role defaults follow Master."; wrapMode: Text.Wrap; Layout.fillWidth: true; color: Theme.Theme.text }
        Repeater {
            model: [{id:"master",label:"Master"},{id:"barPill",label:"Bar pills"},
                {id:"surface",label:"Expanded surfaces"},{id:"controlTile",label:"Control Centre tiles"},
                {id:"slider",label:"Sliders"},{id:"action",label:"Buttons / actions"}]
            GridLayout {
                columns: 3
                id: radiusRow
                required property var modelData
                readonly property var setting: modelData.id === "master" ? Services.Settings.data.appearance.roundness.master
                    : Services.Settings.data.appearance.roundness.roles[modelData.id]
                Layout.fillWidth: true
                Label { text: radiusRow.modelData.label; Layout.fillWidth: true; Layout.columnSpan: 3; wrapMode: Text.Wrap }
                SettingsUI.SettingsSlider {
                    Layout.fillWidth: true
                    from: 0; to: 2; stepSize: .05
                    value: parent.setting === null ? Services.Settings.data.appearance.roundness.master : parent.setting
                    onMoved: Services.Settings.setRoundness(parent.modelData.id, value)
                }
                Label { text: parent.setting === null ? "Default" : Number(parent.setting).toFixed(2); Layout.preferredWidth: 55 }
                SettingsUI.SettingsButton { text: "Default"; onClicked: Services.Settings.setRoundness(parent.modelData.id, parent.modelData.id === "master" ? 1 : null) }
            }
        }
    }
    SettingsUI.SettingsButton { text: "Reset surface borders"; onClicked: {
        Services.Settings.setValue("appearance","surfaceBorders", Schema.defaults().appearance.surfaceBorders)
        Services.Settings.setValue("appearance","notificationBorders", Schema.defaults().appearance.notificationBorders)
    } }
}
