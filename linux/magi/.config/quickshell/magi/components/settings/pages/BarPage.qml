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
    property string mode: "Layout"
    property alias selection: selection
    SettingsUI.EditorSelection {
        id: selection
        familyKeys: ["statusPills", "workspaces"]
        familyForInstance: function(id) { return id === "workspaces" ? "workspacePills" : "statusPills" }
    }
    RowLayout {
        Repeater {
            model: ["Layout","Appearance","Behaviour"]
            SettingsUI.SettingsButton {
                required property string modelData
                text: modelData; primary: root.mode === modelData
                onClicked: root.mode = modelData
            }
        }
    }
    SettingsUI.VisualEditorFrame {
        // A horizontal object uses the full canvas width in every mode.
        columns: 1
        SettingsUI.BarCanvas {
            id: canvas
            objectName: "barCanvas"
            Layout.alignment: Qt.AlignTop
            Layout.minimumWidth: 0
            viewport: root
            editing: root.mode === "Layout"
            styling: root.mode === "Appearance"
            selectedKey: selection.instance
            onSelected: key => selection.select(key)
            onPlacedChanged: selection.reconcile(placed.concat(["statusPills"]))
        }
        SettingsUI.BarInspector {
            id: inspector
            objectName: "barAppearanceInspector"
            visible: root.mode === "Appearance"
            Layout.alignment: Qt.AlignTop
            Layout.minimumWidth: 0
            selection: root.selection
        }
    }
    ColumnLayout {
        objectName: "barBehaviourControls"
        visible: root.mode === "Behaviour"
        Layout.fillWidth: true
    Label { font.bold: true; text: "Bar placement" }
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
    SettingsUI.SettingsHelp { text: "Place System Tray through Bar Layout. Super+T temporarily shows or hides its icons on the main-output Bar without changing your layout. Audio is available through Super+A." }
    Label { font.bold: true; text: "Multi-monitor" }
    SettingsUI.SettingsToggle {
        objectName: "externalBars"
        text: "Show bar on external displays"
        checked: Services.Settings.data.bar.externalDisplays
        onClicked: Services.Settings.setValue("bar", "externalDisplays", checked)
    }

    }


    SettingsUI.SettingsButton {
        actionKind: "reset";
        visible: root.mode !== "Appearance" || selection.scope !== "module" || inspector.familySection.expanded
        text: "Reset Bar"
        onClicked: Services.Settings.resetSection("bar")
    }

}
