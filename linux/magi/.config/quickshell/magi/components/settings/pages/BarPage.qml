pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts
import ".." as SettingsUI
import "../../../services" as Services
import "../../../theme" as Theme
SettingsUI.SettingsPage {
    id: root
    title: "Bar"
    description: "Arrange modules across your bar. Modules in Available are hidden from the bar and remain available in Control Centre."
    readonly property var knownModules: ["clock", "date", "workspaces", "volume", "wifi", "bluetooth", "battery", "notifications", "clipboard", "controlcentre"]
    readonly property var labels: ({clock:"Time", date:"Date", workspaces:"Workspaces", volume:"Volume",
        wifi:"Wi-Fi", bluetooth:"Bluetooth", battery:"Battery", notifications:"Notifications", clipboard:"Clipboard", controlcentre:"Control Centre"})
    function arrangedModules() {
        const bar = Services.Settings.data.bar
        // Include any already-configured schema-supported IDs without inventing defaults.
        const ids = [...new Set(knownModules.concat(bar.left, bar.center, bar.right))]
        const hidden = ids.filter(id => !["left", "center", "right"].some(l => bar[l].includes(id)))
            .sort((a,b) => (labels[a] || a).localeCompare(labels[b] || b))
        return ids.map(id => {
            const lane = ["left", "center", "right"].find(l => bar[l].includes(id)) || "hidden"
            return {key:id, label:labels[id] || id, lane:lane,
                position:lane === "hidden" ? hidden.indexOf(id) : bar[lane].indexOf(id)}
        })
    }
    function placeModule(id, lane, position) {
        const bar = Services.Settings.data.bar
        const from = ["left", "center", "right"].find(l => bar[l].includes(id)) || "hidden"
        if (lane === "hidden") { if (from !== lane) Services.Settings.placeBar(id, "hidden"); return }
        if (from !== lane && !Services.Settings.placeBar(id, lane)) return
        // placeBar removes the ID from all regions and appends it to the destination.
        // moveBar then places it at the dropped index, using the same validated writer.
        const index = Services.Settings.data.bar[lane].indexOf(id)
        if (index >= 0 && index !== position) Services.Settings.moveBar(lane, index, position - index)
    }
    Label { font.bold: true; text: "Bar placement" }
    SettingsUI.SettingsRow {
        Label { text: "Position"; Layout.fillWidth: true }
        SettingsUI.SettingsSelector {
            objectName: "barPosition"
            model: ["Top", "Bottom"]
            currentIndex: Services.Settings.data.bar.position === "bottom" ? 1 : 0
            onActivated: Services.Settings.setValue("bar", "position", currentIndex === 1 ? "bottom" : "top")
        }
    }
    Repeater {
        model: [{key:"horizontalInset", label:"Horizontal inset (px)", maximum:64},
            {key:"edgeOffset", label:"Edge offset (px)", maximum:32}]
        SettingsUI.SettingsRow {
            required property var modelData
            Label { text: parent.modelData.label; Layout.fillWidth: true }
            SettingsUI.SettingsNumber {
                readonly property var option: parent.modelData
                objectName: option.key
                from: 0; to: option.maximum; stepSize: 1
                value: Services.Settings.data.bar[option.key]
                onValueModified: Services.Settings.setValue("bar", option.key, value)
            }
        }
    }
    Label { font.bold: true; text: "Multi-monitor" }
    SettingsUI.SettingsToggle {
        objectName: "externalBars"
        text: "Show bar on external displays"
        checked: Services.Settings.data.bar.externalDisplays
        onClicked: Services.Settings.setValue("bar", "externalDisplays", checked)
    }
    SettingsUI.SettingsHelp { text: "Distances use logical pixels. Each bar reserves 48 px plus its edge offset at the selected edge. On narrow outputs the inset shrinks, then workspace and left modules hide to keep status controls usable." }
    SettingsUI.VisualSettingsGroup {
        collapsible: false
        title: "Status icons"
        numbers: [{key:"statusIconSize",label:"Status icon size",min:16,max:28,step:1}]
    }
    SettingsUI.SettingsReorderBoard {
        objectName: "barOrder"
        viewport: root
        rowHeight: 44
        lanes: [{id:"left",label:"LEFT"}, {id:"center",label:"CENTRE"},
            {id:"right",label:"RIGHT"}, {id:"hidden",label:"AVAILABLE · HIDDEN FROM BAR",ordered:false}]
        entries: root.arrangedModules()
        onMoveRequested: (key, lane, position) => root.placeModule(key, lane, position)
        rowContent: Component {
            Label {
                text: parent.entry ? parent.entry.label : ""
                color: Theme.Theme.text
                verticalAlignment: Text.AlignVCenter
                elide: Text.ElideRight
            }
        }
    }
    SettingsUI.SettingsHelp { text: "Bar placement updates when open menus and network/password interactions have finished." }
    SettingsUI.SettingsButton { flat: true; text: "Reset bar placement"; onClicked: Services.Settings.resetSection("bar") }
}
