pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls.Basic
import "../../plugins/bar/controlcentre" as CC
import "../controls" as Controls
import "../../settings/SettingsSchema.js" as Schema
import "../../theme" as Theme

Item {
    id: root
    objectName: "ccPreview-" + entry.module
    property alias presenter: presenter.item
    required property var entry
    required property string family
    readonly property var definition: Schema.controlDefinitions().find(d => d.id === entry.module)
    readonly property bool active: ["wifi", "bluetooth"].includes(entry.module)
    Loader {
        id: presenter
        anchors.fill: parent
        enabled: false
        sourceComponent: root.family === "controls" ? primary : root.family === "sliders" ? slider : secondary
    }
    Component {
        id: primary
        CC.ControlTile {
            moduleId: root.entry.module
            icon: root.definition.icon
            title: root.definition.label
            interactive: false
            available: true
            active: root.active
            toggle: ["wifi", "bluetooth", "power-saver", "airplane-mode", "dnd", "caffeine", "vpn"].includes(moduleId)
            accentRole: root.entry.accent || root.definition.accent || "lavender"
            activeColor: Theme.Theme.primaryAccent(accentRole, "lavender")
        }
    }
    Component {
        id: secondary
        CC.ActionButton {
            moduleId: root.entry.module
            icon: root.definition.icon
            label: root.definition.label
            interactive: false
            available: true
            active: root.active
            accentRole: root.entry.accent || ""
            toggle: ["wifi", "bluetooth", "power-saver", "airplane-mode", "dnd", "caffeine", "vpn"].includes(moduleId)
        }
    }
    Component {
        id: slider
        Controls.IconSlider {
            opacity: 1
            interactive: false
            moduleId: root.entry.module
            icon: root.definition.icon
            value: root.entry.module === "volume" ? .65 : .8
        }
    }
}
