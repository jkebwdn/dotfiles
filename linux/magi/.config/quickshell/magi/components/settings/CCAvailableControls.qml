pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import "../../theme" as Theme
SettingsSection {
    id: root
    objectName: "ccAvailableControls"
    required property var preview
    property alias controlsArea: controlsArea
    property alias sectionsArea: sectionsArea
    readonly property int columns: Math.max(1, Math.floor(controlsArea.width / 92))
    title: "Available controls"
    collapsible: true
    expanded: true
    description: "Drag controls between here and the preview to add or remove them. Rearrange modules directly on the preview."
    Connections {
        target: root.preview.moduleBoard
        function onTargetLaneChanged() { if (target.targetLane === "available") root.expanded = true }
    }
    Connections {
        target: root.preview.structureBoard
        function onTargetLaneChanged() { if (target.targetLane === "availableStructure") root.expanded = true }
    }
    Binding {
        target: root.cardBackground
        property: "border.color"
        value: root.preview.moduleBoard.targetLane === "available" || root.preview.structureBoard.targetLane === "availableStructure" ? Theme.Theme.accent : Qt.alpha(Theme.Theme.border, .45)
    }
    SettingsHelp { visible: text.length > 0; text: root.preview.moduleBoard.rejectedLane ? "This control cannot be placed in that section." : root.preview.structureBoard.rejectedLane ? "This module must stay in the composition." : "" }
    Item {
        id: controlsArea
        Layout.fillWidth: true
        implicitHeight: Math.max(64, Math.ceil(root.preview.moduleBoard.order("available").length / root.columns) * 66)
    }
    Item {
        id: sectionsArea
        Layout.fillWidth: true
        visible: root.preview.availableSections.length > 0
        implicitHeight: Math.ceil(root.preview.availableSections.length / root.columns) * 40
    }
}
