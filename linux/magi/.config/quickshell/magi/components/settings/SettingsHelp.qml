import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts
import "../../theme" as Theme
Label {
    Layout.fillWidth: true
    Layout.minimumWidth: 0
    wrapMode: Text.Wrap
    textFormat: Text.PlainText
    font.pixelSize: SettingsMetrics.helperSize
    color: Theme.Theme.text
}
