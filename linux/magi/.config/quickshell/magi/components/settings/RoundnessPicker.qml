pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts
import "../../services" as Services
import "../../theme" as Theme

ColumnLayout {
    id: root
    objectName: "roundnessPicker"
    Layout.fillWidth: true
    spacing: SettingsMetrics.compactGap
    Label {
        text: "Roundness"
        font.pixelSize: SettingsMetrics.sectionSize
        font.bold: true
        color: Theme.Theme.text
    }
    RowLayout {
        Layout.fillWidth: true
        spacing: SettingsMetrics.gap
        Repeater {
            id: choices
            model: [
                {
                    label: "Sharp",
                    value: 0
                },
                {
                    label: "Balanced",
                    value: 1
                },
                {
                    label: "Rounded",
                    value: 2
                }
            ]
            SettingsChoiceCard {
                id: card
                required property var modelData
                required property int index
                objectName: "roundnessChoice-" + index
                Layout.fillWidth: true
                Layout.maximumWidth: 170
                Layout.minimumWidth: 0
                implicitHeight: 88
                text: modelData.label
                selected: Math.abs(Services.Settings.data.appearance.roundness.master - modelData.value) < .001
                onClicked: Services.Settings.setRoundness("master", modelData.value)
                onNavigate: delta => choices.itemAt(Math.max(0, Math.min(2, index + delta))).forceActiveFocus(Qt.TabFocusReason)
                Rectangle {
                    anchors.centerIn: parent
                    width: Math.min(80, parent.width)
                    height: 28
                    // Preview the existing master multiplier without changing shared state.
                    radius: Math.min(height / 2, 8 * card.modelData.value)
                    color: Theme.Theme.elevated
                    border.width: 1
                    border.color: Theme.Theme.accent
                }
            }
        }
    }
    SettingsSection {
        objectName: "roundnessFineTune"
        title: "Fine tune · " + Number(Services.Settings.data.appearance.roundness.master).toFixed(2)
        Layout.topMargin: 0
        collapsible: true
        SettingsSlider {
            objectName: "masterRoundnessPrecision"
            Accessible.name: "Master roundness"
            Layout.fillWidth: true
            from: 0
            to: 2
            stepSize: .05
            value: Services.Settings.data.appearance.roundness.master
            onMoved: Services.Settings.setRoundness("master", value)
        }
    }
}
