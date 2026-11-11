pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts
import ".." as SettingsUI
import "../../../services" as Services
import "../../../theme" as Theme
SettingsUI.SettingsPage {
    id: root
    title: "Bar"
    maximumBodyWidth: 1200
    description: ""
    property alias selection: selection
    SettingsUI.EditorSelection {
        id: selection
        familyForInstance: function(id) { return id === "customImage" ? "artwork" : id === "workspaces" ? "workspacePills" : "statusPills" }
    }
    SettingsUI.BarCanvas {
        objectName: "barCanvas"
        viewport: root
        editing: true
        selectedKey: selection.instance
        onSelected: key => selection.select(placed.includes(key) ? key : "")
        onPlacedChanged: selection.reconcile(placed)
    }
    SettingsUI.BarInspector {
        objectName: "barAppearanceInspector"
        visible: selection.instance.length > 0
        selection: root.selection
    }
    SettingsUI.SettingsSection {
        objectName: "barBehaviourControls"
        title: "Behaviour"
        Layout.fillWidth: true
        SettingsUI.SettingsHelp { objectName: "barBehaviourHelp"; text: "Add System Tray through Available items. Super+T temporarily shows or hides its icons on the main-output Bar without changing your layout. Audio is available through Super+A." }
        SettingsUI.SettingsSection {
            objectName: "barPlacement"
            title: "Bar placement"
            carded: false
            collapsible: true
            SettingsUI.SettingsRow {
                Label { text: "Position"; Layout.fillWidth: true }
                SettingsUI.SettingsSelector {
                    objectName: "barPosition"
                    model: ["Top", "Bottom"]
                    currentIndex: Services.Settings.data.bar.position === "bottom" ? 1 : 0
                    onActivated: Services.Settings.setValue("bar", "position", currentIndex === 1 ? "bottom" : "top")
                }
            }
            Repeater {
                model: [{key:"horizontalInset", label:"Horizontal inset (px)", maximum:64},
                    {key:"edgeOffset", label:"Edge offset (px)", maximum:32}]
                SettingsUI.SettingsRow {
                    required property var modelData
                    Label { text: parent.modelData.label; Layout.fillWidth: true }
                    SettingsUI.SettingsNumber {
                        readonly property var option: parent.modelData
                        objectName: option.key
                        from: 0; to: option.maximum; stepSize: 1
                        value: Services.Settings.data.bar[option.key]
                        onValueModified: Services.Settings.setValue("bar", option.key, value)
                    }
                }
            }
        }
        Label { font.bold: true; text: "Multi-monitor" }
        SettingsUI.SettingsToggle {
            objectName: "externalBars"
            text: "Show bar on external displays"
            checked: Services.Settings.data.bar.externalDisplays
            onClicked: Services.Settings.setValue("bar", "externalDisplays", checked)
        }

    }
    SettingsUI.SettingsSection {
        objectName: "barRoundness"
        title: "Roundness"
        description: "Shapes status and workspace pills, including connected joins."
        SettingsUI.RoundnessValue { fieldKey: "barPill"; label: ""; accessibleLabel: "Bar roundness"; reference: 8; editingAllowed: Services.Settings.data.bar.visual.workspacePills.roundness === null }
        SettingsUI.SettingsHelp { visible: Services.Settings.data.bar.visual.workspacePills.roundness !== null; text: "Workspace pills have a separate saved override. Review that value before changing unified Bar roundness." }
    }

    SettingsUI.BarGlobalSettings { }
    SettingsUI.SettingsButton {
        actionKind: "reset"
        text: "Reset Bar"
        onClicked: Services.Settings.resetSection("bar")
    }
}
