pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts
import "." as SettingsUI
import "../../services" as Services
import "../../theme" as Theme
import "../../settings/SettingsSchema.js" as Schema
import "../controls" as Controls

SettingsUI.SettingsSection {
    id: root
    objectName: "ccGlobalControls"
    title: "Global controls"
    collapsible: true
    SettingsUI.SettingsHelp {
        text: "Border styling is shared with other menus."
    }
    SettingsUI.SettingsRow {
        Label {
            text: "Surface background"
            Layout.fillWidth: true
        }
        SettingsUI.SemanticPaletteSelector {
            model: ["background", "surface", "elevated", "overlay", "text", "subtext", "muted", "border", "accent"].concat(Theme.ThemeRegistry.accentRoles)
            role: Services.Settings.data.appearance.controlCentreBackgroundRole
            onRoleSelected: value => Services.Settings.setValue("appearance", "controlCentreBackgroundRole", value)
        }
    }
    SettingsUI.SettingsRow {
        Label { text: "Status row colour"; Layout.fillWidth: true }
        SettingsUI.SemanticPaletteSelector {
            objectName: "ccStatusRowColour"
            Accessible.name: "Expanded status row colour"
            model: ["text", "subtext", "muted", "background", "surface", "elevated", "accent"].concat(Theme.ThemeRegistry.accentRoles)
            role: Services.Settings.data.appearance.statusRowRole || "text"
            onRoleSelected: value => Services.Settings.setValue("appearance", "statusRowRole", value)
        }
    }
    SettingsUI.SettingsHelp {
        text: "Icons and Battery percentage in the expanded status header. Bar colours return when the panel closes. Also applies when switching to another status menu."
    }
    Rectangle {
        Layout.fillWidth: true
        implicitHeight: 42
        radius: Theme.Theme.radiusSmall
        color: Theme.Theme.roles[Services.Settings.data.appearance.controlCentreBackgroundRole]
        Row {
            anchors.centerIn: parent
            spacing: 12
            Repeater {
                model: ["wifi", "bluetooth-connected", "volume", "settings", "battery-high"]
                Controls.Icon {
                    required property string modelData
                    role: modelData
                    size: Theme.Theme.statusIconSize
                    color: Theme.Theme.expandedStatusForeground
                }
            }
            Label {
                objectName: "ccStatusRowSample"
                text: "100%"
                color: Theme.Theme.expandedStatusForeground
                anchors.verticalCenter: parent.verticalCenter
            }
        }
    }
    SettingsUI.SettingsSection {
        carded: false
        objectName: "ccStatusRowFineTune"
        title: "Fine tune"
        collapsible: true
        expanded: false
        SettingsUI.SettingsRow {
            Label { text: "Status row shade"; Layout.fillWidth: true }
            SettingsUI.SettingsSlider {
                objectName: "ccStatusRowShade"
                Accessible.name: "Expanded status row shade"
                Layout.fillWidth: true
                from: -1; to: 1; stepSize: .05
                value: Services.Settings.data.appearance.statusRowShade ?? 0
                onMoved: Services.Settings.setValue("appearance", "statusRowShade", value)
            }
        }
        SettingsUI.SettingsHelp { text: "Negative lightens · 0 keeps the palette colour · positive darkens." }
        SettingsUI.SettingsButton {
            text: "Reset status row"
            onClicked: { Services.Settings.setValue("appearance", "statusRowRole", null); Services.Settings.setValue("appearance", "statusRowShade", null) }
        }
    }
    SettingsUI.SurfaceStyleSettings {
        carded: false
        objectName: "ccGlobalBorder"
        title: "Border"
        collapsible: true
        group: "surfaceBorders"
        targets: [
            {
                id: "controlcentre",
                label: "Show border"
            }
        ]
    }
}
