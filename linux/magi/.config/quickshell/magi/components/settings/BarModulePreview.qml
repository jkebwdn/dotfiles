pragma ComponentBehavior: Bound
import QtQuick
import "../bar" as Bar
import "../tray" as Tray
import "../calendar" as Calendar
import "../controls" as Controls
import "../../plugins/bar/workspaces" as Workspaces
import "../../theme" as Theme
Item {
    id: root
    objectName: "barPreview-" + moduleId
    readonly property var presenter: loader.item
    required property string moduleId
    implicitWidth: loader.item ? loader.item.implicitWidth : 30
    implicitHeight: 28
    Loader {
        id: loader
        anchors.centerIn: parent
        sourceComponent: root.moduleId === "clock" || root.moduleId === "date" ? time
        : root.moduleId === "tray" ? tray : root.moduleId === "workspaces" ? workspace : root.moduleId === "battery" ? battery
        : root.moduleId === "notifications" || root.moduleId === "clipboard" ? utility : status
    }
    Component { id: tray; Tray.TrayGroup { interactive: false; nativeMenus: false; maximumWidth: 132; items: fixture.items; Tray.TrayPreviewModel { id: fixture } } }
    Component { id: time; Calendar.TimeDatePill { interactive: false; datePart: root.moduleId === "date"; previewText: root.moduleId === "clock" ? "10:24" : "23/10/2026" } }
    Component { id: workspace; Workspaces.Workspaces { preview: true } }
    Component { id: utility; Bar.UtilityPill { interactive: false; mode: root.moduleId; label: root.moduleId } }
    Component { id: battery; Bar.BatteryPillContent {} }
    Component {
        id: status
        Bar.StatusPill {
            styleId: root.moduleId
            Controls.MorphingPillContent {
                pill: null
                moduleId: root.moduleId
                icon: ({wifi:"wifi",bluetooth:"bluetooth-connected",volume:"volume",controlcentre:"settings"})[root.moduleId] || "missing"
                iconColor: ["wifi","bluetooth"].includes(root.moduleId) ? Theme.Theme.barAccent(root.moduleId) : Theme.Theme.barItemForeground(root.moduleId, Theme.Theme.text)
            }
        }
    }
}
