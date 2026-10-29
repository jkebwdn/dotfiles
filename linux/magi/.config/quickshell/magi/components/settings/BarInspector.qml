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
    function setItems(values) {
        const modules = JSON.parse(JSON.stringify(Services.Settings.data.bar.modules));
        modules[instance] = Object.assign({}, modules[instance] || {}, values);
        Services.Settings.setValue("bar", "modules", modules);
    }
    function setItem(key, value) { const values = {}; values[key] = value; setItems(values) }
    readonly property var refinements: {
        if (!individual || family !== "statusPills") return []
        const stateful = ["wifi", "bluetooth", "volume"].includes(instance)
        const entries = [{key:"backgroundShade", label:instance === "battery" ? "Icon background shade" : "Background shade"}]
        if (instance !== "tray") entries.push({key:"foregroundShade", label:stateful ? "On icon shade" : ["clock", "date"].includes(instance) ? "Text shade" : "Icon shade"})
        if (stateful) entries.push({key:"foregroundOffShade", label:"Off icon shade"})
        if (instance === "battery") entries.push({key:"percentageBackgroundShade", label:"Percentage background shade"}, {key:"percentageForegroundShade", label:"Percentage text shade"})
        return entries
    }
    function refinementValue(key) {
        return key === "percentageBackgroundShade" ? Theme.Theme.barPercentageShade() : itemStyle[key] ?? 0
    }
    function resetRefinements() {
        const values = {}
        for (const entry of refinements) values[entry.key] = entry.key === "percentageBackgroundShade" ? null : 0
        setItems(values)
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
            text: root.instance === "battery" ? "Use shared icon background" : "Use shared background"
            onClicked: root.setItems({backgroundRole:null, backgroundShade:0})
        }
        SettingsRow {
            visible: root.instance === "battery"
            Label { text: "Percentage background"; Layout.fillWidth: true }
            SettingsSelector {
                objectName: "batteryPercentageBackground"
                Accessible.name: "Battery percentage background"
                model: root.roles
                currentIndex: model.indexOf(Services.Settings.data.bar.modules.battery?.percentageBackgroundRole || Services.Settings.data.bar.modules.battery?.backgroundRole || Services.Settings.data.bar.visual.statusPills.role)
                onActivated: root.setItem("percentageBackgroundRole", currentText)
            }
        }
        SettingsButton { visible: root.instance === "battery"; text: "Follow icon background"; onClicked: root.setItems({percentageBackgroundRole:null, percentageBackgroundShade:null}) }
        SettingsRow {
            visible: root.instance === "battery"
            Label { text: "Percentage colour"; Layout.fillWidth: true }
            SettingsSelector {
                Accessible.name: "Battery percentage colour"
                model: root.roles
                currentIndex: model.indexOf(Services.Settings.data.bar.modules.battery?.percentageForegroundRole || "text")
                onActivated: root.setItem("percentageForegroundRole", currentText)
            }
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
        objectName: "barColourRefinement"
        visible: root.individual && root.family === "statusPills"
        title: "Fine tune"
        description: "Lighten or darken individual colours."
        collapsible: true
        expanded: false
        SettingsHelp { text: "Negative lightens · 0 keeps the palette colour · positive darkens." + (["wifi", "bluetooth", "volume"].includes(root.instance) ? " Off shade applies to disconnected or muted icons." : "") }
        Repeater {
            model: root.refinements
            SettingsRow {
                id: shadeRow
                required property var modelData
                Layout.fillWidth: true
                columns: 2
                rowSpacing: 2
                Label { text: shadeRow.modelData.label; Layout.fillWidth: true; wrapMode: Text.Wrap }
                Label {
                    readonly property real setting: root.refinementValue(shadeRow.modelData.key)
                    text: (setting > 0 ? "+" : "") + Math.round(setting * 100) + "%"
                    horizontalAlignment: Text.AlignRight
                    color: Theme.Theme.subtext
                    Layout.preferredWidth: 56
                }
                SettingsSlider {
                    objectName: "barItemShade-" + shadeRow.modelData.key
                    Accessible.name: shadeRow.modelData.label
                    Layout.row: 1; Layout.columnSpan: 2
                    Layout.fillWidth: true
                    from: -1; to: 1; stepSize: .05
                    value: root.refinementValue(shadeRow.modelData.key)
                    onMoved: root.setItem(shadeRow.modelData.key, value)
                }
            }
        }
        SettingsButton { text: "Reset colour refinement"; onClicked: root.resetRefinements() }
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
