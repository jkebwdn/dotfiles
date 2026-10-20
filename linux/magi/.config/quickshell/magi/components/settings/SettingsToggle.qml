import QtQuick
import QtQuick.Layouts
import "../../theme" as Theme
import "../controls" as Controls
Controls.CompactToggle {
    id: root
    objectName: "settingsToggle-" + text
    indicatorOnRight: true
    activeColor: Theme.Theme.hubToggleColor
    Layout.fillWidth: text.length > 0
    implicitWidth: Math.max(34, contentItem.implicitWidth + leftPadding + rightPadding)
    implicitHeight: Math.max(SettingsMetrics.controlHeight, contentItem.implicitHeight + 12)
    leftPadding: 0; rightPadding: text.length > 0 ? 48 : 0
    contentItem: Text {
        text: root.text
        font: root.font
        color: Theme.Theme.text
        verticalAlignment: Text.AlignVCenter
        wrapMode: Text.Wrap
    }
    SettingsFocus {}
}
