pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import "../../services" as Services
import "../../theme" as Theme
import "../../settings/SettingsSchema.js" as Schema
Item {
    id: root
    property bool editing: false
    property string selectedKey: ""
    property alias board: board
    required property Flickable viewport
    signal selected(string key)
    readonly property var bar: Services.Settings.data.bar
    readonly property var placed: bar.left.concat(bar.center,bar.right)
    readonly property var labels: ({clock:"Time",date:"Date",workspaces:"Workspaces",volume:"Volume",wifi:"Wi-Fi",bluetooth:"Bluetooth",battery:"Battery",notifications:"Notifications",clipboard:"Clipboard",controlcentre:"Control Centre"})
    function entries() {
        return Schema.barIds.map(id => {
            const lane = ["left","center","right"].find(l => bar[l].includes(id)) || "hidden"
            return {key:id,label:labels[id],lane:lane,position:lane === "hidden" ? Schema.barIds.indexOf(id) : bar[lane].indexOf(id),
                width: id === "workspaces" ? 90 : id === "date" ? 92 : id === "clock" || id === "battery" ? 62 : 36}
        })
    }
    implicitWidth: 680
    Layout.preferredWidth: 680
    Layout.fillWidth: true
    implicitHeight: (editing ? 260 : 150) * stage.scale
    Item {
        id: stage
        width: Math.max(900,root.width,2*root.bar.horizontalInset + ["left","center","right"].reduce((sum,l) => sum + Math.max(180,root.entries().filter(e=>e.lane===l).reduce((n,e)=>n+e.width+6,20)),0)); height: root.editing ? 260 : 150
        scale: Math.min(1,root.width/width); transformOrigin: Item.TopLeft
        Rectangle {
            anchors.fill: parent; radius: 10; color: Theme.Theme.background
            border.width: 1; border.color: Theme.Theme.border
            MouseArea { anchors.fill: parent; onClicked: root.selected("") }
        }
        Rectangle {
            objectName: "barPreviewHost"
            x: root.bar.horizontalInset; width: stage.width - 2*x; height: 48
            y: root.bar.position === "bottom" ? 94-root.bar.edgeOffset : 28+root.bar.edgeOffset
            color: Theme.Theme.barBackground
        }
        SettingsReorderBoard {
            id: board
            objectName: "barOrder"
            x: root.bar.horizontalInset; width: stage.width-2*x
            y: root.bar.position === "bottom" ? 60-root.bar.edgeOffset : root.bar.edgeOffset
            canvasMode: true; editing: root.editing; selectedKey: root.selectedKey
            viewport: root.viewport; rowHeight: 32; gap: 6
            lanes: [{id:"left",label:"LEFT"},{id:"center",label:"CENTRE",alignment:"center"},{id:"right",label:"RIGHT",alignment:"right"},{id:"hidden",label:"AVAILABLE MODULES",ordered:false,palette:true}]
            entries: root.entries()
            onSelected: key => root.selected(key)
            onMoveRequested: (key,lane,position) => Services.Settings.placeBar(key,lane,position)
            rowContent: Component {
                Item {
                    readonly property var entry: parent.entry
                    BarModulePreview { anchors.centerIn: parent; moduleId: parent.entry ? parent.entry.key : "wifi" }
                }
            }
        }
    }
}
