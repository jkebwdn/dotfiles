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
    description: "Compose your Bar, then select a pill to edit its family and identity. Preview controls are inert."
    property string mode: "Layout"
    property alias selection: selection
    SettingsUI.EditorSelection {
        id: selection
        familyForInstance: function(id) { return id === "workspaces" ? "workspacePills" : "statusPills" }
    }
    RowLayout {
        Repeater {
            model: ["Layout","Colours & Look","Behaviour"]
            SettingsUI.SettingsButton {
                required property string modelData
                text: modelData; primary: root.mode === modelData
                onClicked: root.mode = modelData
            }
        }
    }
    SettingsUI.VisualEditorFrame {
        SettingsUI.BarCanvas {
            id: canvas
            objectName: "barCanvas"
            Layout.alignment: Qt.AlignTop
            Layout.minimumWidth: 0
            viewport: root
            editing: root.mode === "Layout"
            selectedKey: selection.instance
            onSelected: key => selection.select(key)
            onPlacedChanged: selection.reconcile(placed)
        }
        SettingsUI.BarInspector {
            visible: root.mode === "Colours & Look"
            Layout.alignment: Qt.AlignTop
            Layout.preferredWidth: 360
            Layout.minimumWidth: 0
            selection: root.selection
        }
    }
    SettingsUI.SettingsHelp {
        visible: root.mode === "Layout"
        text: "Drag a grip into Left, Centre, Right or Available. Focus a grip: Alt+↑/↓ reorder; Alt+←/→ change region; Escape cancels. Empty regions disappear."
    }
    Flow {
        visible: root.mode === "Layout" && selection.instance !== ""
        Layout.fillWidth: true; spacing: 8
        Repeater {
            model: [{id:"left",label:"Move to Left"},{id:"center",label:"Move to Centre"},{id:"right",label:"Move to Right"},{id:"hidden",label:"Remove from Bar"}]
            SettingsUI.SettingsButton {
                required property var modelData
                text: modelData.label
                onClicked: Services.Settings.placeBar(selection.instance,modelData.id)
            }
        }
    }
    ColumnLayout {
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
    Label { font.bold: true; text: "Multi-monitor" }
    SettingsUI.SettingsToggle {
        objectName: "externalBars"
        text: "Show bar on external displays"
        checked: Services.Settings.data.bar.externalDisplays
        onClicked: Services.Settings.setValue("bar", "externalDisplays", checked)
    }
    SettingsUI.SettingsHelp { text: "Distances use logical pixels. Each bar reserves 48 px plus its edge offset at the selected edge. On narrow outputs the inset shrinks, then workspace and left modules hide to keep status controls usable." }
    }
    SettingsUI.SettingsButton { flat:true; text:"Select Bar background"; visible:root.mode === "Colours & Look"; onClicked:selection.select("") }
    SettingsUI.SettingsHelp { text: "Changes preview immediately and use Settings autosave. Reload from Disk restores the persisted layout and styling. Runtime placement waits for active menu interactions to finish." }
    SettingsUI.SettingsButton {
        flat: true
        text: "Reset Bar"
        onClicked: Services.Settings.resetSection("bar")
    }

}
