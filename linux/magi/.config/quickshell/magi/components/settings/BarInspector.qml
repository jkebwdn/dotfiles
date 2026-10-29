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
    readonly property string foregroundKey: ["wifi", "bluetooth"].includes(instance) ? "accentRole" : "foregroundRole"
    readonly property string defaultForeground: foregroundKey === "accentRole" ? "accent" : "text"
    readonly property var itemStyle: Services.Settings.data.bar.modules[instance] || ({})
    readonly property var style: Services.Settings.data.bar.visual[family]
    readonly property var roles: ["background", "surface", "elevated", "overlay", "text", "subtext", "muted", "accent", "blue", "lavender", "green", "yellow", "peach", "red", "teal", "border"]
    function setStyle(key, value) {
        const visual = JSON.parse(JSON.stringify(Services.Settings.data.bar.visual));
        visual[family][key] = value;
        Services.Settings.setValue("bar", "visual", visual);
    }
    function setItem(key, value) {
        const modules = JSON.parse(JSON.stringify(Services.Settings.data.bar.modules));
        if (!modules[instance]) modules[instance] = {};
        modules[instance][key] = value;
        Services.Settings.setValue("bar", "modules", modules);
    }
    function setAccent(role) { setItem("accentRole", role) }
    Layout.fillWidth: true
    SettingsHelp {
        objectName: "barSelectionContext"
        text: root.individual ? "Selected item · identity and options"
            : root.family === "host" ? "Bar background · select an item or group in the preview"
            : "Shared style · changes affect the whole group"
    }
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
                controlcentre: "Control Centre",
                tray: "System Tray"
            })[root.instance] || ""
        SettingsRow {
            visible: root.instance !== "tray" && root.instance !== "workspaces"
            Label { text: ["clock", "date"].includes(root.instance) ? "Text colour" : "Icon colour"; Layout.fillWidth: true }
            SettingsSelector {
                objectName: "barInstanceAccent"
                Accessible.name: root.instance + " foreground colour"
                model: root.roles
                currentIndex: model.indexOf(root.itemStyle[root.foregroundKey] || root.defaultForeground)
                onActivated: root.setItem(root.foregroundKey, currentText)
            }
        }
        SettingsRow {
            visible: root.family === "statusPills"
            Label { text: root.instance === "battery" ? "Icon background" : "Background colour"; Layout.fillWidth: true }
            SettingsSelector {
                objectName: "barItemBackground"
                Accessible.name: root.instance + " background colour"
                model: root.roles
                currentIndex: model.indexOf(Services.Settings.data.bar.modules[root.instance]?.backgroundRole || Services.Settings.data.bar.visual.statusPills.role)
                onActivated: root.setItem("backgroundRole", currentText)
            }
        }
        SettingsButton {
            visible: root.family === "statusPills"
            text: "Use shared background"
            onClicked: root.setItem("backgroundRole", null)
        }
        SettingsToggle {
            visible: root.instance === "battery"
            text: "Show percentage"
            checked: Services.Settings.data.bar.modules.battery?.showPercentage !== false
            onClicked: root.setItem("showPercentage", checked)
        }
        SettingsHelp {
            visible: root.instance === "tray"
            text: "Application icons keep their own colours. Background colour styles the shared Tray pill."
        }
    }
    SettingsSection {
        visible: root.individual && root.instance === "battery"
        title: "Fine tune"
        collapsible: true
        expanded: false
        SettingsRow {
            Label { text: "Percentage background"; Layout.fillWidth: true }
            SettingsSelector {
                objectName: "batteryPercentageBackground"
                Accessible.name: "Battery percentage background"
                model: root.roles
                currentIndex: model.indexOf(Services.Settings.data.bar.modules.battery?.percentageBackgroundRole || Services.Settings.data.bar.modules.battery?.backgroundRole || Services.Settings.data.bar.visual.statusPills.role)
                onActivated: root.setItem("percentageBackgroundRole", currentText)
            }
        }
        SettingsButton { text: "Follow icon background"; onClicked: root.setItem("percentageBackgroundRole", null) }
        SettingsRow {
            Label { text: "Percentage colour"; Layout.fillWidth: true }
            SettingsSelector {
                Accessible.name: "Battery percentage colour"
                model: root.roles
                currentIndex: model.indexOf(Services.Settings.data.bar.modules.battery?.percentageForegroundRole || "text")
                onActivated: root.setItem("percentageForegroundRole", currentText)
            }
        }
    }

    SettingsSection {
        id: familySection
        objectName: "barFamilyInspector"
        collapsible: root.individual
        expanded: !root.individual
        title: root.family === "host" ? "Bar background" : root.family === "workspacePills" ? "Workspace pills" : "Status pills"
        description: root.individual ? "Shared with other items in this group." : ""
        SettingsToggle {
            visible: root.family !== "workspacePills"
            text: root.family === "host" ? "Show Bar background" : "Pill background enabled"
            checked: root.style.enabled === true
            onClicked: root.setStyle("enabled", checked)
        }
        SettingsRow {
            visible: root.family !== "workspacePills"
            Label {
                text: "Background colour"
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
            text: root.instance === "tray" ? "System Tray shares Status pill styling. Application icons retain their own artwork and colours." : "Connected items use their accent. Unavailable items are muted; muted audio uses the warning colour."
        }
    }
    SurfaceStyleSettings {
        objectName: "barMenuInspector"
        visible: ["wifi", "bluetooth", "volume"].includes(root.instance)
        collapsible: true
        title: root.instance === "volume" ? "Audio menu" : root.instance === "wifi" ? "Wi-Fi menu" : "Bluetooth menu"
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
                id: ["wifi", "bluetooth", "volume"].includes(root.instance) ? root.instance : "wifi",
                label: "Menu border enabled"
            }
        ]
    }
    SettingsHelp {
        visible: root.instance === "controlcentre" || root.instance === "date" || root.instance === "clock"
        text: root.instance === "controlcentre" ? "Control Centre contents and appearance remain in the Control Centre section." : "Calendar appearance and formatting remain in Date & time."
    }
}
