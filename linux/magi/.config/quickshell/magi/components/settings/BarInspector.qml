pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts
import "../../services" as Services
import "../../theme" as Theme

ColumnLayout {
    id: root
    required property var selection
    readonly property bool individual: selection.scope === "module"
    property bool editThemeAccent: false
    Connections { target: root.selection; function onInstanceChanged() { root.editThemeAccent = false } }
    readonly property string family: selection.family
    readonly property string instance: selection.instance
    readonly property string foregroundKey: ["wifi", "bluetooth"].includes(instance) ? "accentRole" : "foregroundRole"
    readonly property string defaultForeground: foregroundKey === "accentRole" ? "accent" : "text"
    readonly property var itemStyle: Services.Settings.data.bar.modules[instance] || ({})
    readonly property var roles: ["background", "surface", "elevated", "overlay", "text", "subtext", "muted", "accent", "blue", "lavender", "green", "yellow", "peach", "red", "teal", "border"]
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
    Layout.fillWidth: true
    SettingsSection {
        objectName: "barIdentityInspector"
        visible: root.individual && !["customImage", "workspaces"].includes(root.instance)
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
        SettingsToggle {
            objectName: "barForegroundInherited"
            visible: root.instance !== "tray"
            text: root.foregroundKey === "accentRole" ? "Use theme accent colour" : "Use default foreground colour"
            checked: root.foregroundKey === "accentRole" ? !root.editThemeAccent && root.itemStyle.accentRole === "accent" : root.itemStyle.foregroundRole == null
            onClicked: {
                if (root.foregroundKey === "accentRole") { const follow = checked; root.editThemeAccent = !follow; if (follow) root.setItem("accentRole", "accent") }
                else root.setItem("foregroundRole", checked ? null : "text")
            }
        }
        SettingsRow {
            visible: root.instance !== "tray" && root.instance !== "workspaces"
            Label { text: ["clock", "date"].includes(root.instance) ? "Text colour" : "Icon colour"; Layout.fillWidth: true }
            SettingsSelector {
                objectName: "barInstanceAccent"
                enabled: root.foregroundKey === "accentRole" ? root.editThemeAccent || root.itemStyle.accentRole !== "accent" : root.itemStyle.foregroundRole != null
                Accessible.name: root.instance + " foreground colour"
                model: root.roles
                currentIndex: model.indexOf(root.itemStyle[root.foregroundKey] || root.defaultForeground)
                onActivated: root.setItem(root.foregroundKey, currentText)
            }
        }
        SettingsToggle {
            objectName: "barBackgroundInherited"
            visible: root.family === "statusPills"
            text: "Use global background colour"
            checked: root.itemStyle.backgroundRole == null
            onClicked: root.setItem("backgroundRole", checked ? null : Services.Settings.data.bar.visual.statusPills.role)
        }
        SettingsRow {
            visible: root.family === "statusPills"
            Label { text: root.instance === "battery" ? "Icon background" : "Background colour"; Layout.fillWidth: true }
            SettingsSelector {
                objectName: "barItemBackground"
                enabled: root.itemStyle.backgroundRole != null
                Accessible.name: root.instance + " background colour"
                model: root.roles
                currentIndex: model.indexOf(Services.Settings.data.bar.modules[root.instance]?.backgroundRole || Services.Settings.data.bar.visual.statusPills.role)
                onActivated: root.setItem("backgroundRole", currentText)
            }
        }
        SettingsToggle {
            objectName: "batteryBackgroundInherited"
            visible: root.instance === "battery"
            text: "Use icon background colour"
            checked: root.itemStyle.percentageBackgroundRole == null
            onClicked: root.setItem("percentageBackgroundRole", checked ? null : root.itemStyle.backgroundRole || Services.Settings.data.bar.visual.statusPills.role)
        }
        SettingsRow {
            visible: root.instance === "battery"
            Label { text: "Percentage background"; Layout.fillWidth: true }
            SettingsSelector {
                objectName: "batteryPercentageBackground"
                enabled: root.itemStyle.percentageBackgroundRole != null
                Accessible.name: "Battery percentage background"
                model: root.roles
                currentIndex: model.indexOf(Services.Settings.data.bar.modules.battery?.percentageBackgroundRole || Services.Settings.data.bar.modules.battery?.backgroundRole || Services.Settings.data.bar.visual.statusPills.role)
                onActivated: root.setItem("percentageBackgroundRole", currentText)
            }
        }
        SettingsToggle {
            visible: root.instance === "battery"
            text: "Use default percentage colour"
            checked: root.itemStyle.percentageForegroundRole == null
            onClicked: root.setItem("percentageForegroundRole", checked ? null : "text")
        }
        SettingsRow {
            visible: root.instance === "battery"
            Label { text: "Percentage colour"; Layout.fillWidth: true }
            SettingsSelector {
                Accessible.name: "Battery percentage colour"
                enabled: root.itemStyle.percentageForegroundRole != null
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
        SettingsSection {
            objectName: "barColourRefinement"
            carded: false
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
        SettingsHelp {
            visible: root.instance === "controlcentre" || ["date", "clock"].includes(root.instance)
            text: root.instance === "controlcentre" ? "Configure contents in Control Centre Settings." : "Formatting and calendar options are in Date & time."
        }
    }
    CustomImageSettings { visible: root.individual && root.instance === "customImage" }
    SettingsSection {
        visible: root.individual && root.instance === "workspaces"
        title: "Workspaces"
        description: "Workspace pills use the Bar Roundness card. Drag this item to choose its Bar region."
    }
}
