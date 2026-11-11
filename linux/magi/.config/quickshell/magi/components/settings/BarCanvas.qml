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
    property string selectedKey: ""
    property alias board: board
    required property Flickable viewport
    signal selected(string key)
    readonly property var bar: Services.Settings.data.bar
    readonly property var placed: bar.left.concat(bar.center, bar.right)
    readonly property var labels: ({
            clock: "Time",
            date: "Date",
            customImage: "Custom Image",
            workspaces: "Workspaces",
            volume: "Volume",
            wifi: "Wi-Fi",
            bluetooth: "Bluetooth",
            battery: "Battery",
            notifications: "Notifications",
            clipboard: "Clipboard",
            controlcentre: "Control Centre",
            tray: "System Tray"
        })
    function entries() {
        return Schema.barIds.map(id => {
            const lane = ["left", "center", "right"].find(l => bar[l].includes(id)) || "hidden";
            return {
                key: id,
                label: !editing && id === "workspaces" ? "Workspace pills" : labels[id],
                lane: lane,
                position: lane === "hidden" ? Schema.barIds.indexOf(id) : bar[lane].indexOf(id),
                width: id === "customImage" ? imageWidth : id === "tray" ? 132 : id === "workspaces" ? 90 : id === "date" ? 92 : id === "clock" || id === "battery" ? 62 : 36
            };
        });
    }
    function laneWidth(lane) {
        return Math.max(180, entries().filter(e => e.lane === lane).reduce((sum, e) => sum + e.width + 6, 20))
    }
    readonly property real imageWidth: {
        const config = bar.modules.customImage || {}, asset = config.asset
        if (!asset) return 100
        const bounds = config.trim === false ? [0, 0, asset.width, asset.height] : asset.bounds
        return Math.min(240, bounds[2] * (config.height || 32) / bounds[3])
    }
    implicitWidth: 680
    Layout.preferredWidth: 680
    Layout.fillWidth: true
    implicitHeight: layoutCard.height + (editing ? 12 + availableCard.height : 0)
    SettingsSection {
        id: layoutCard
        objectName: "barLayoutCard"
        width: root.width
        height: stage.y + Math.max(board.y + 80, previewHost.y + previewHost.height) * stage.scale + 12
        title: "Layout"
        description: "Click a Bar item for more options."
    }
    SettingsSection {
        id: availableCard
        objectName: "barAvailableItems"
        visible: root.editing
        y: layoutCard.height + 12
        width: root.width
        height: 40 + board.rowHeight * stage.scale + 12
        title: "Available items"
    }
    Item {
        id: stage
        x: 12; y: 72
        width: Math.max(900, root.width - 24, 2 * root.bar.horizontalInset + 2 * Math.max(root.laneWidth("left"), root.laneWidth("right")) + root.laneWidth("center"))
        height: (root.implicitHeight - y) / scale
        scale: Math.min(1, Math.max(1, root.width - 24) / width)
        transformOrigin: Item.TopLeft
        Rectangle {
            anchors.fill: parent
            radius: Theme.Theme.radius("surface", 10, width, height)
            color: "transparent"
            MouseArea {
                anchors.fill: parent
                onClicked: { root.forceActiveFocus(Qt.MouseFocusReason); root.selected("") }
            }
        }
        Rectangle {
            id: previewHost
            objectName: "barPreviewHost"
            x: root.bar.horizontalInset
            width: stage.width - 2 * x
            height: 48
            y: root.bar.position === "bottom" ? 94 - root.bar.edgeOffset : 28 + root.bar.edgeOffset
            color: Theme.Theme.barBackground
        }
        SettingsReorderBoard {
            id: board
            objectName: "barOrder"
            x: root.bar.horizontalInset
            width: stage.width - 2 * x
            y: root.bar.position === "bottom" ? 60 - root.bar.edgeOffset : root.bar.edgeOffset
            removeLane: "hidden"
            paletteY: (availableCard.y + 40 - stage.y) / stage.scale - y
            paletteHeadingVisible: false
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
