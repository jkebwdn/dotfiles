pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls.Basic
import "../../services" as Services
import "../../theme" as Theme
import "../../settings/SettingsSchema.js" as Schema

Item {
    id: root
    property bool editing: false
    property bool styling: false
    property string selectedKey: ""
    property alias board: board
    required property Flickable viewport
    signal selected(string key)
    readonly property var bar: Services.Settings.data.bar
    readonly property var placed: bar.left.concat(bar.center, bar.right)
    readonly property var labels: ({
            clock: "Time",
            date: "Date",
            workspaces: "Workspaces",
            volume: "Volume",
            wifi: "Wi-Fi",
            bluetooth: "Bluetooth",
            battery: "Battery",
            notifications: "Notifications",
            clipboard: "Clipboard",
            controlcentre: "Control Centre"
        })
    function entries() {
        return Schema.barIds.map(id => {
            const lane = ["left", "center", "right"].find(l => bar[l].includes(id)) || "hidden";
            return {
                key: id,
                label: !editing && id === "workspaces" ? "Workspace pills" : labels[id],
                lane: lane,
                position: lane === "hidden" ? Schema.barIds.indexOf(id) : bar[lane].indexOf(id),
                width: id === "workspaces" ? 90 : id === "date" ? 92 : id === "clock" || id === "battery" ? 62 : 36
            };
        });
    }
    implicitWidth: 680
    Layout.preferredWidth: 680
    Layout.fillWidth: true
    implicitHeight: (editing ? 210 : 150) * stage.scale
    Item {
        id: stage
        width: Math.max(900, root.width, 2 * root.bar.horizontalInset + ["left", "center", "right"].reduce((sum, l) => sum + Math.max(180, root.entries().filter(e => e.lane === l).reduce((n, e) => n + e.width + 6, 20)), 0))
        height: root.editing ? 210 : 150
        scale: Math.min(1, root.width / width)
        transformOrigin: Item.TopLeft
        Rectangle {
            anchors.fill: parent
            radius: Theme.Theme.radius("surface", 10, width, height)
            color: Theme.Theme.background
            border.width: 1
            border.color: Theme.Theme.border
            MouseArea {
                anchors.fill: parent
                onClicked: { root.forceActiveFocus(Qt.MouseFocusReason); root.selected("") }
            }
        }
        Rectangle {
            objectName: "barPreviewHost"
            x: root.bar.horizontalInset
            width: stage.width - 2 * x
            height: 48
            y: root.bar.position === "bottom" ? 94 - root.bar.edgeOffset : 28 + root.bar.edgeOffset
            color: Theme.Theme.barBackground
        }
        Repeater {
            model: root.styling ? ["statusPills", "workspaces"] : []
            SettingsButton {
                required property string modelData
                objectName: "barFamilyTarget-" + modelData
                visible: modelData !== "workspaces" || root.placed.includes("workspaces")
                x: modelData === "statusPills" ? root.bar.horizontalInset + 10 : stage.width / 2 - width / 2
                y: board.y
                z: 2
                text: modelData === "statusPills" ? "Status pills" : "Workspace pills"
                Accessible.name: text + " appearance"
                flat: true
                font.pixelSize: 11
                font.bold: true
                implicitHeight: 28
                topPadding: 2
                bottomPadding: 2
                checked: root.selectedKey === modelData
                onClicked: root.selected(modelData)
            }
        }
        SettingsReorderBoard {
            id: board
            objectName: "barOrder"
            x: root.bar.horizontalInset
            width: stage.width - 2 * x
            y: root.bar.position === "bottom" ? 60 - root.bar.edgeOffset : root.bar.edgeOffset
            familySelection: key => root.styling && ((root.selectedKey === "statusPills" && key !== "workspaces") || (root.selectedKey === "workspaces" && key === "workspaces"))
            removeLane: "hidden"
            canvasMode: true
            editing: root.editing
            selectedKey: root.selectedKey
            viewport: root.viewport
            rowHeight: 32
            gap: 6
            lanes: [
                {
                    id: "left",
                    label: root.editing ? "Left" : ""
                },
                {
                    id: "center",
                    label: root.editing ? "Centre" : "",
                    alignment: "center"
                },
                {
                    id: "right",
                    label: root.editing ? "Right" : "",
                    alignment: "right"
                },
                {
                    id: "hidden",
                    label: "Available",
                    ordered: false,
                    palette: true
                }
            ]
            entries: root.entries()
            onSelected: key => root.selected(key)
            onMoveRequested: (key, lane, position) => Services.Settings.placeBar(key, lane, position)
            rowContent: Component {
                Item {
                    readonly property var entry: parent.entry
                    BarModulePreview {
                        anchors.centerIn: parent
                        moduleId: parent.entry ? parent.entry.key : "wifi"
                    }
                }
            }
        }
    }
}
