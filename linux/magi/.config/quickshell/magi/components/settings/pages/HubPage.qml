import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts
import "../../../services" as Services
import "../../../theme" as Theme
import ".." as SettingsUI
import "../../../settings/SettingsSchema.js" as Schema
SettingsUI.SettingsPage {
    title: "Hub"
    description: "The selector stays anchored; content grows away from it within the output."
    Repeater {
        model: [{key:"hubSelectionRole",label:"Selected mode colour"},{key:"hubToggleRole",label:"Toggle colour"}]
        SettingsUI.SettingsRow {
            id: colorRow
            required property var modelData
            Label { text: colorRow.modelData.label; Layout.fillWidth: true }
            SettingsUI.SemanticPaletteSelector {
                objectName: colorRow.modelData.key
                Accessible.name: colorRow.modelData.label
                role: Services.Settings.data.appearance[colorRow.modelData.key]
                onRoleSelected: value => Services.Settings.setValue("appearance",colorRow.modelData.key,value)
            }
        }
    }
    SettingsUI.SettingsRow {
        Label { text: "Selector position"; Layout.fillWidth: true }
        SettingsUI.SettingsSelector { model: ["Below content","Above content"]; currentIndex: Services.Settings.data.hub.selectorPosition === "above" ? 1 : 0; onActivated: Services.Settings.setValue("hub","selectorPosition", currentIndex ? "above" : "below") }
    }
    Label { text: "Vertical position · " + Math.round(Services.Settings.data.hub.verticalPosition * 100) + "%" }
    SettingsUI.SettingsSlider { Layout.fillWidth: true; from: .1; to: .9; stepSize: .01; value: Services.Settings.data.hub.verticalPosition; onMoved: Services.Settings.setValue("hub","verticalPosition",value) }
    Label { text: "Selector corner roundness" }
    SettingsUI.SettingsSlider { Layout.fillWidth: true; from: 0; to: 2; stepSize: .05; value: Services.Settings.data.appearance.roundness.roles.hubSelector ?? Services.Settings.data.appearance.roundness.master; onMoved: Services.Settings.setRoundness("hubSelector",value) }
    SettingsUI.SettingsButton { text: "Follow Master roundness"; onClicked: Services.Settings.setRoundness("hubSelector",null) }
    SettingsUI.SettingsButton { text: "Reset Hub appearance"; onClicked: { Services.Settings.resetSection("hub"); Services.Settings.setRoundness("hubSelector",null); for (const key of ["hubSelectionRole","hubToggleRole"]) Services.Settings.setValue("appearance",key,Schema.defaults().appearance[key]) } }
}
