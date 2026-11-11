pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts
import "../../services" as Services
SettingsSection {
    id: root
    objectName: "barGlobalOptions"
    title: "Global Bar options"
    description: "Shared background styling applies to status items unless their colours are overridden above."
    readonly property var roles: ["background", "surface", "elevated", "overlay", "text", "subtext", "muted", "accent", "blue", "lavender", "green", "yellow", "peach", "red", "teal", "border"]
    function setStyle(family, key, value) {
        const visual = JSON.parse(JSON.stringify(Services.Settings.data.bar.visual))
        visual[family][key] = value
        Services.Settings.setValue("bar", "visual", visual)
    }
    SettingsHelp { objectName: "barGlobalForegroundHelp"; text: "Foregrounds use each item's semantic colour and live state. Application icons keep their own artwork. Custom Image has no pill background or tint." }
    Repeater {
        model: ["host", "statusPills"]
        SettingsSection {
            id: group
            required property string modelData
            readonly property var style: Services.Settings.data.bar.visual[modelData]
            objectName: "barGlobal-" + modelData
            carded: false
            collapsible: true
            title: modelData === "host" ? "Bar background" : "Status items"
            Loader {
                active: group.modelData === "statusPills"
                visible: active
                Layout.fillWidth: true
                sourceComponent: SettingsRow {
                    Label { text: "Status icon size"; Layout.fillWidth: true }
                    SettingsNumber {
                        objectName: "visualSetting-statusIconSize"
                        from: 16; to: 28
                        value: Services.Settings.data.appearance.visual.statusIconSize
                        onValueModified: Services.Settings.setVisual("statusIconSize", value)
                    }
                }
            }
            SettingsToggle {
                text: group.modelData === "host" ? "Show Bar background" : "Show status-pill backgrounds"
                checked: group.style.enabled
                onClicked: root.setStyle(group.modelData, "enabled", checked)
            }
            SettingsRow {
                Label { text: "Background colour"; Layout.fillWidth: true }
                SettingsSelector {
                    objectName: "barGlobalRole-" + group.modelData
                    model: root.roles
                    currentIndex: model.indexOf(group.style.role)
                    onActivated: root.setStyle(group.modelData, "role", currentText)
                }
            }
            SettingsRow {
                Label { text: "Background opacity"; Layout.fillWidth: true }
                SettingsSlider {
                    Layout.fillWidth: true; Layout.minimumWidth: 100
                    from: 0; to: 1; stepSize: .05; value: group.style.opacity
                    onMoved: root.setStyle(group.modelData, "opacity", value)
                }
            }
        }
    }
    SurfaceStyleSettings {
        objectName: "barMenuInspector"
        carded: false; collapsible: true
        title: "Menu borders"
        description: "Border colour and width are shared with other shell surfaces."
        group: "surfaceBorders"
        targets: [{id:"wifi", label:"Wi-Fi border"}, {id:"bluetooth", label:"Bluetooth border"}, {id:"volume", label:"Audio border"}]
    }
}
