pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts
import "../../services" as Services
import "../../theme" as Theme

ColumnLayout {
    id: root
    required property string fieldKey
    required property string label
    property string accessibleLabel: label
    property string description: ""
    property string infoText: ""
    property bool editingAllowed: true
    property bool authoritative: false
    property real reference: 10
    objectName: "roundnessValue-" + fieldKey
    Layout.fillWidth: true
    Layout.minimumWidth: 0
    spacing: 6
    readonly property var storedValue: fieldKey === "workspace"
        ? Services.Settings.data.bar.visual.workspacePills.roundness
        : Services.Settings.data.appearance.roundness.roles[fieldKey]
    readonly property real inheritedValue: fieldKey === "workspace"
        ? (Services.Settings.data.appearance.roundness.roles.barPill ?? Services.Settings.data.appearance.roundness.master)
        : Services.Settings.data.appearance.roundness.master
    readonly property real displayedValue: storedValue ?? inheritedValue
    function setValue(value) {
        if (fieldKey === "workspace") {
            const visual = JSON.parse(JSON.stringify(Services.Settings.data.bar.visual))
            visual.workspacePills.roundness = value
            Services.Settings.setValue("bar", "visual", visual)
        } else Services.Settings.setRoundness(fieldKey, value)
    }
    RowLayout {
        Layout.fillWidth: true
        spacing: SettingsMetrics.compactGap
        Label { visible: text.length > 0; text: root.label; Layout.fillWidth: true; Layout.minimumWidth: 0; wrapMode: Text.Wrap }
        SettingsInfo { visible: root.infoText.length > 0; label: root.label; helpText: root.infoText }
    }
    SettingsHelp { visible: text.length > 0; text: root.description }
    SettingsToggle {
        objectName: "roundnessInherit-" + root.fieldKey
        visible: !root.authoritative
        text: root.fieldKey === "workspace" ? "Use Bar pill roundness" : "Use base roundness (" + root.inheritedValue.toFixed(2) + "×)"
        Accessible.name: root.accessibleLabel + ": " + text
        Accessible.description: "Inherited when checked; a custom override when unchecked. Disabling inheritance starts at the parent's current value."
        enabled: root.editingAllowed
        checked: root.storedValue == null
        onClicked: root.setValue(checked ? null : root.inheritedValue)
    }
    RowLayout {
        Layout.fillWidth: true
        SettingsSlider {
            objectName: "roundness-" + root.fieldKey
            Accessible.name: root.accessibleLabel + " multiplier"
            enabled: root.editingAllowed && (root.authoritative || root.storedValue != null)
            Layout.fillWidth: true
            Layout.minimumWidth: 40
            from: 0; to: 2; stepSize: .05
            value: root.displayedValue
            onMoved: root.setValue(value)
        }
        Rectangle {
            objectName: "roundnessPreview-" + root.fieldKey
            implicitWidth: 56; implicitHeight: 28
            radius: root.fieldKey === "workspace" ? Theme.Theme.workspacePillRadius
                : Theme.Theme.radius(root.fieldKey, root.reference, width, height)
            color: Theme.Theme.surface
            border.color: Theme.Theme.border
            Label { anchors.centerIn: parent; text: root.displayedValue.toFixed(2) + "×" }
        }
    }
    SettingsButton {
        visible: root.authoritative
        text: "Reset roundness"
        actionKind: "reset"
        onClicked: root.setValue(null)
    }
    SettingsHelp {
        visible: !root.authoritative
        text: root.storedValue == null ? "Inherited · " + root.displayedValue.toFixed(2) + "×" : "Custom override"
    }
}
