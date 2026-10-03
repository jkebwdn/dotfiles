pragma ComponentBehavior: Bound
import QtQuick
import ".." as SettingsUI
import QtQuick.Controls.Basic
import QtQuick.Layouts
import "../../../services" as Services
import "../../../theme" as Theme
Flickable {
    id: root
    contentHeight: content.implicitHeight + 48
    clip: true
    ScrollBar.vertical: ScrollBar {}
    ColumnLayout {
        id: content
        x: 24; y: 24; width: root.width - 48
        spacing: 16
        Label { text: "Bar"; font.pixelSize: 26; font.bold: true }
        Label { text: "Place modules and adjust their order. Hidden modules remain available in Control Centre.\nPlacement waits until menus and password/network interactions finish."; wrapMode: Text.WordWrap; Layout.fillWidth: true; color: Theme.Theme.subtext }
        Repeater {
            model: ["clock", "date", "workspaces", "volume", "wifi", "bluetooth", "battery", "notifications", "controlcentre"]
            RowLayout {
                id: row
                required property string modelData
                readonly property string section: {
                    const bar = Services.Settings.data.bar
                    return ["left", "center", "right"].find(s => bar[s].indexOf(modelData) >= 0) || "hidden"
                }
                readonly property int position: section === "hidden" ? -1 : Services.Settings.data.bar[section].indexOf(modelData)
                Layout.fillWidth: true
                Label { text: row.modelData; Layout.fillWidth: true }
                ComboBox {
                    model: ["Hidden", "Left", "Centre", "Right"]
                    currentIndex: ["hidden", "left", "center", "right"].indexOf(row.section)
                    onActivated: index => Services.Settings.placeBar(row.modelData, ["hidden", "left", "center", "right"][index])
                }
                SettingsUI.SettingsButton { text: "↑"; Accessible.name: "Move earlier"; enabled: row.position > 0; onClicked: Services.Settings.moveBar(row.section,row.position,-1) }
                SettingsUI.SettingsButton { text: "↓"; Accessible.name: "Move later"; enabled: row.position >= 0 && row.position < Services.Settings.data.bar[row.section].length - 1; onClicked: Services.Settings.moveBar(row.section,row.position,1) }
            }
        }
        SettingsUI.SettingsButton { text: "Reset bar placement"; onClicked: Services.Settings.resetSection("bar") }
    }
}
