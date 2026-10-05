pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts
import "../../../services" as Services
import "../../../theme" as Theme
import ".." as SettingsUI
Flickable {
    id: root
    contentHeight: content.implicitHeight + 48; clip: true
    ScrollBar.vertical: ScrollBar {}
    ColumnLayout {
        id: content
        x: 24; y: 24; width: root.width - 48; spacing: 14
        Label { text: "Emoji Picker"; font.pixelSize: 26; font.bold: true }
        Label { text: "SUPER + . · Search, choose, then paste"; color: Theme.Theme.subtext }
        Repeater {
            model: [{key:"enabled",label:"Enable Emoji Picker"}, {key:"showCategories",label:"Show category selector"},
                {key:"closeOnSelect",label:"Close after copying"}]
            CheckBox {
                required property var modelData
                text: modelData.label; checked: Services.Settings.data.emoji[modelData.key]
                onClicked: Services.Settings.setValue("emoji", modelData.key, checked)
            }
        }
        Repeater {
            model: [{key:"gridColumns",label:"Grid columns",min:4,max:12},
                {key:"emojiSize",label:"Emoji size",min:20,max:48}, {key:"recentLimit",label:"Recent history limit (0 disables)",min:0,max:60}]
            RowLayout {
                required property var modelData
                Layout.fillWidth: true
                Label { text: parent.modelData.label; Layout.fillWidth: true }
                SpinBox {
                    readonly property var option: parent.modelData
                    from: option.min; to: option.max
                    value: Services.Settings.data.emoji[option.key]
                    onValueModified: Services.Settings.setValue("emoji", option.key, value)
                }
            }
        }
        Label {
            Layout.fillWidth: true; wrapMode: Text.WordWrap; color: Theme.Theme.subtext
            text: "Search covers every category. Recently Used is saved in MAGI Settings. Clear or reset below to erase it. Skin-tone variants are individual results."
        }
        SettingsUI.SettingsButton { text: "Clear Recently Used"; onClicked: Services.Settings.setValue("emoji", "recents", []) }
        SettingsUI.SettingsButton { text: "Reset Emoji settings and history"; onClicked: Services.Settings.resetSection("emoji") }
    }
}
