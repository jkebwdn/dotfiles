pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts
import "../../services" as Services
import "../../theme" as Theme

ColumnLayout {
    id: root
    required property var selection
    property alias familySection: familySection
    readonly property bool individual: selection.scope === "module"
    function resetDisclosure() { familySection.expanded = !root.individual }
    Connections {
        target: root.selection
        function onInstanceChanged() { Qt.callLater(root.resetDisclosure) }
        function onFamilyChanged() { Qt.callLater(root.resetDisclosure) }
    }
    readonly property string family: selection.family
    readonly property string instance: selection.instance
    readonly property var style: Services.Settings.data.bar.visual[family]
    readonly property var roles: ["background", "surface", "elevated", "overlay", "text", "subtext", "muted", "accent", "blue", "lavender", "green", "yellow", "peach", "red", "teal", "border"]
    function setStyle(key, value) {
        const visual = JSON.parse(JSON.stringify(Services.Settings.data.bar.visual));
        visual[family][key] = value;
        Services.Settings.setValue("bar", "visual", visual);
    }
    function setAccent(role) {
        const modules = JSON.parse(JSON.stringify(Services.Settings.data.bar.modules));
        modules[instance].accentRole = role;
        Services.Settings.setValue("bar", "modules", modules);
    }
    Layout.fillWidth: true
    SettingsSection {
        objectName: "barIdentityInspector"
        visible: root.individual
        collapsible: false
        title: ({
                wifi: "Wi-Fi",
                bluetooth: "Bluetooth",
                clock: "Time",
                date: "Date",
                volume: "Volume",
                battery: "Battery",
                notifications: "Notifications",
                clipboard: "Clipboard",
                controlcentre: "Control Centre"
            })[root.instance] || ""
        SettingsRow {
            visible: ["wifi", "bluetooth"].includes(root.instance)
            Label {
                text: "Accent"
                Layout.fillWidth: true
            }
            SettingsSelector {
                objectName: "barInstanceAccent"
                Accessible.name: root.instance + " accent"
                model: root.roles
                currentIndex: model.indexOf(Services.Settings.data.bar.modules[root.instance]?.accentRole || "accent")
                onActivated: root.setAccent(currentText)
            }
        }
    }
    SettingsSection {
        id: familySection
        objectName: "barFamilyInspector"
        collapsible: root.individual
        expanded: !root.individual
        title: root.family === "host" ? "Bar background" : root.family === "workspacePills" ? "Workspace pills" : "Status pills"
        description: ""
        SettingsToggle {
            visible: root.family !== "workspacePills"
            text: root.family === "host" ? "Show Bar background" : "Pill background enabled"
            checked: root.style.enabled === true
            onClicked: root.setStyle("enabled", checked)
        }
        SettingsRow {
            visible: root.family !== "workspacePills"
            Label {
                text: "Background role"
                Layout.fillWidth: true
            }
            SettingsSelector {
                model: root.roles
                currentIndex: model.indexOf(root.style.role)
                onActivated: root.setStyle("role", currentText)
            }
        }
        SettingsRow {
            visible: root.family !== "workspacePills"
            Label {
                text: "Background opacity"
                Layout.fillWidth: true
            }
            SettingsSlider {
                Layout.fillWidth: true
                Layout.minimumWidth: 100
                from: 0
                to: 1
                stepSize: 0.05
                value: root.style.opacity === undefined ? 1 : root.style.opacity
                onMoved: root.setStyle("opacity", value)
            }
        }
        SettingsRow {
            visible: root.family !== "host"
            Label {
                text: "Roundness"
                Layout.fillWidth: true
            }
            SettingsSlider {
                Layout.fillWidth: true
                Layout.minimumWidth: 100
                from: 0
                to: 2
                stepSize: .05
                value: root.family === "workspacePills" ? (root.style.roundness == null ? (Services.Settings.data.appearance.roundness.roles.barPill ?? Services.Settings.data.appearance.roundness.master) : root.style.roundness) : (Services.Settings.data.appearance.roundness.roles.barPill ?? Services.Settings.data.appearance.roundness.master)
                onMoved: root.family === "workspacePills" ? root.setStyle("roundness", value) : Services.Settings.setRoundness("barPill", value)
            }
        }
        SettingsButton {
            actionKind: "reset"
            visible: root.family !== "host"
            text: root.family === "workspacePills" ? "Follow Bar pill roundness" : "Follow Master roundness"
            onClicked: root.family === "workspacePills" ? root.setStyle("roundness", null) : Services.Settings.setRoundness("barPill", null)
        }
        SettingsRow {
            visible: root.family === "statusPills"
            Label {
                text: "Status icon size"
                Layout.fillWidth: true
            }
            SettingsNumber {
                objectName: "visualSetting-statusIconSize"
                from: 16
                to: 28
                value: Services.Settings.data.appearance.visual.statusIconSize
                onValueModified: Services.Settings.setVisual("statusIconSize", value)
            }
        }
        SettingsHelp {
            visible: root.family === "statusPills"
            text: "Connected: module accent. Unavailable: muted. Volume: warning when muted."
        }
    }
    SurfaceStyleSettings {
        objectName: "barMenuInspector"
        visible: ["wifi", "bluetooth"].includes(root.instance)
        collapsible: true
        title: root.instance === "wifi" ? "Wi-Fi menu" : "Bluetooth menu"
        description: "Colour, width and roundness are shared with other menus."
        group: "surfaceBorders"
        SettingsRow {
            Label {
                text: "Shared surface roundness"
                Layout.fillWidth: true
            }
            SettingsSlider {
                Layout.fillWidth: true
                Layout.minimumWidth: 100
                from: 0
                to: 2
                stepSize: .05
                value: Services.Settings.data.appearance.roundness.roles.surface ?? Services.Settings.data.appearance.roundness.master
                onMoved: Services.Settings.setRoundness("surface", value)
            }
        }
        targets: [
            {
                id: ["wifi", "bluetooth"].includes(root.instance) ? root.instance : "wifi",
                label: "Menu border enabled"
            }
        ]
    }
    SettingsHelp {
        visible: root.instance === "controlcentre" || root.instance === "date" || root.instance === "clock"
        text: root.instance === "controlcentre" ? "Control Centre contents and appearance remain in the Control Centre section." : "Calendar appearance and formatting remain in Date & time."
    }
}
