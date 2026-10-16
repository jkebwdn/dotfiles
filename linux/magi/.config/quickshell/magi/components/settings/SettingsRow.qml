import QtQuick
import QtQuick.Layouts
// Stable control children and identity; presentation never writes Settings.
GridLayout {
    Layout.fillWidth: true
    columns: width < 420 ? 1 : 2
    columnSpacing: SettingsMetrics.gap
    rowSpacing: SettingsMetrics.compactGap
}
