pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts
import "../../services" as Services
import "../../theme" as Theme

SettingsSection {
    id: root
    objectName: "roundnessPicker"
    title: "Roundness"
    RowLayout {
        Layout.fillWidth: true
        SettingsSlider {
            objectName: "masterRoundnessPrecision"
            Accessible.name: "Master roundness"
            Layout.fillWidth: true
            from: 0; to: 2; stepSize: .05
            value: Services.Settings.data.appearance.roundness.master
            onMoved: Services.Settings.setRoundness("master", value)
        }
        Rectangle {
            objectName: "masterRoundnessPreview"
            implicitWidth: 54; implicitHeight: 28
            radius: Math.min(height / 2, 8 * Services.Settings.data.appearance.roundness.master)
            color: Theme.Theme.surface
            border.color: Theme.Theme.border
            Label { anchors.centerIn: parent; text: Number(Services.Settings.data.appearance.roundness.master).toFixed(2) }
        }
    }
}
