pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts
import "../../../services" as Services
import "../../../theme" as Theme
import ".." as SettingsUI
Flickable {
    id: root
    contentHeight: content.implicitHeight + 48
    clip: true
    ScrollBar.vertical: ScrollBar {}
    ColumnLayout {
        id: content
        x: 24; y: 24; width: root.width - 48; spacing: 16
        Label { text: "Notifications"; font.pixelSize: 26; font.bold: true }
        Label {
            Layout.fillWidth: true; wrapMode: Text.WordWrap
            text: "History stays in memory for this shell session. Fullscreen suppresses all toasts; DND keeps ordinary notifications in history."
            color: Theme.Theme.subtext
        }
        Repeater {
            model: [{key:"enabled",label:"Accept notifications"}, {key:"toastsEnabled",label:"Show toasts"},
                {key:"dnd",label:"Do Not Disturb"}, {key:"showBody",label:"Show body previews"},
                {key:"criticalBypassDnd",label:"Critical notifications bypass DND"}]
            CheckBox {
                required property var modelData
                text: modelData.label
                checked: Services.Settings.data.notifications[modelData.key]
                onClicked: Services.Settings.setValue("notifications", modelData.key, checked)
            }
        }
        Repeater {
            model: [{key:"fallbackTimeout",label:"Default timeout (seconds)",min:1,max:30,step:1,scale:1000},
                {key:"maxVisible",label:"Maximum visible toasts",min:1,max:4,step:1,scale:1},
                {key:"historyLimit",label:"History limit",min:10,max:500,step:10,scale:1}]
            RowLayout {
                id: row
                required property var modelData
                Layout.fillWidth: true
                Label { text: row.modelData.label; Layout.fillWidth: true }
                SpinBox {
                    from: row.modelData.min; to: row.modelData.max; stepSize: row.modelData.step
                    value: Services.Settings.data.notifications[row.modelData.key] / row.modelData.scale
                    onValueModified: Services.Settings.setValue("notifications", row.modelData.key, value * row.modelData.scale)
                }
            }
        }
        SettingsUI.SettingsButton { text: "Reset notification settings"; onClicked: Services.Settings.resetSection("notifications") }
    }
}
