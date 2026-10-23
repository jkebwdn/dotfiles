pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import "../../services" as Services
import "../../theme" as Theme
import "../controls" as Controls

GridLayout {
    id: root
    columns: width < 240 ? 1 : 3
    objectName: "switchStylePicker"
    Layout.fillWidth: true
    columnSpacing: SettingsMetrics.compactGap
    rowSpacing: SettingsMetrics.compactGap
    Repeater {
        id: choices
        model: [
            {
                id: "pill",
                label: "Pill"
            },
            {
                id: "filled",
                label: "Filled"
            },
            {
                id: "minimal",
                label: "Minimal"
            }
        ]
        SettingsChoiceCard {
            id: card
            required property var modelData
            required property int index
            objectName: "switchStyleChoice-" + modelData.id
            Layout.fillWidth: true
            Layout.minimumWidth: 0
            implicitHeight: root.columns === 1 ? 72 : 88
            text: modelData.label
            selected: Services.Settings.data.appearance.toggleStyle === modelData.id
            Keys.onUpPressed: navigate(-1)
            Keys.onDownPressed: navigate(1)
            onClicked: Services.Settings.setValue("appearance", "toggleStyle", modelData.id)
            onNavigate: delta => choices.itemAt(Math.max(0, Math.min(2, index + delta))).forceActiveFocus(Qt.TabFocusReason)
            Controls.CompactToggle {
                anchors.centerIn: parent
                checked: true
                toggleStyle: card.modelData.id
                activeColor: Theme.Theme.hubToggleColor
                // Presentation is production; interaction belongs to the enclosing choice.
                enabled: false
                opacity: 1
            }
        }
    }
}
