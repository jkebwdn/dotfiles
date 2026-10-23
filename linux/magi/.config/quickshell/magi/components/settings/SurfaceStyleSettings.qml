import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts
import "../../services" as Services
import "../../theme" as Theme
SettingsSection {
    id: root
    required property string group
    property var targets: []
    property bool showSharedControls: true
    readonly property var style: Services.Settings.data.appearance[group]
    function set(key, value) { Services.Settings.setValue("appearance",group,Object.assign({},style,{[key]:value})) }
    SettingsRow {
        visible: root.showSharedControls
        Layout.fillWidth: true
        Label { text: "Colour"; Layout.fillWidth: true }
        SettingsSelector {
            Accessible.name: root.title + " colour"
            Layout.fillWidth: true; Layout.minimumWidth: 0
            model: ["border","background","surface","elevated","overlay","text","subtext","muted","accent","blue","lavender","green","yellow","peach","red","teal"]
            currentIndex: model.indexOf(root.style.role)
            onActivated: root.set("role",currentText)
        }
    }
    SettingsRow {
        visible: root.showSharedControls
        Label { text: "Width"; Layout.fillWidth: true }
        SettingsNumber { Accessible.name: root.title + " width"; from: 0; to: 5; value: root.style.width; onValueModified: root.set("width", value) }
    }
    ColumnLayout {
        Layout.fillWidth: true; spacing: SettingsMetrics.compactGap
        Repeater {
            model: root.targets
            SettingsToggle {
                required property var modelData
                text: modelData.label; checked: root.style[modelData.id]
                onClicked: root.set(modelData.id,checked)
            }
        }
    }
}
