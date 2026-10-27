import QtQuick
import QtQuick.Layouts
// Stable control children and identity; presentation never writes Settings.
GridLayout {
    id: root
    property real fieldWidth: 240
    // Ordinary two-field rows share a trailing control column. Compact steppers
    // retain their natural width inside that column; multi-cell rows opt out.
    Binding {
        when: root.children.length === 2 && root.columns === 2
        target: root.children.length === 2 ? root.children[1].Layout : null
        property: "preferredWidth"
        value: root.children.length === 2 && root.children[1].compactControl === true ? SettingsMetrics.stepperWidth : root.fieldWidth
        restoreMode: Binding.RestoreBindingOrValue
    }
    Binding {
        when: root.children.length === 2 && root.columns === 2
        target: root.children.length === 2 ? root.children[1].Layout : null
        property: "maximumWidth"
        value: root.fieldWidth
        restoreMode: Binding.RestoreBindingOrValue
    }
    Binding {
        when: root.children.length === 2
        target: root.children.length === 2 ? root.children[1].Layout : null
        property: "alignment"
        value: (root.columns === 2 ? Qt.AlignRight : Qt.AlignLeft) | Qt.AlignVCenter
        restoreMode: Binding.RestoreBindingOrValue
    }
    Layout.fillWidth: true
    // The parent owns available width. Our provisional implicit width changes
    // when the trailing field constraints switch, so it cannot choose columns.
    columns: (!parent || parent.width < 420) ? 1 : 2
    columnSpacing: SettingsMetrics.sectionGap
    rowSpacing: SettingsMetrics.compactGap
}
