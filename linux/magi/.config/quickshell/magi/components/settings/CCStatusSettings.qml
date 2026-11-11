pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts
import "." as SettingsUI
import "../../services" as Services
import "../../theme" as Theme
import "../controls" as Controls

SettingsUI.SettingsSection {
    objectName: "ccStatusItems"
    title: "Status Items"
    infoText: "Shared icon and battery-text appearance in the expanded Control Centre status header and other expanded status menus. Collapsed Bar pills keep their Bar styling."
    SettingsUI.SettingsRow {
        Label { text: "Icon colour"; Layout.fillWidth: true }
        SettingsUI.SemanticPaletteSelector {
            objectName: "ccStatusRowColour"
            Accessible.name: "Expanded status row colour"
            model: ["text", "subtext", "muted", "background", "surface", "elevated", "accent"].concat(Theme.ThemeRegistry.accentRoles)
            role: Services.Settings.data.appearance.statusRowRole || "text"
            onRoleSelected: value => Services.Settings.setValue("appearance", "statusRowRole", value)
        }
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
        infoText: "Negative lightens; zero keeps the palette colour; positive darkens."
        SettingsUI.SettingsRow {
            Label { text: "Shade"; Layout.fillWidth: true }
            SettingsUI.SettingsSlider {
                objectName: "ccStatusRowShade"
                Accessible.name: "Expanded status row shade"
                Layout.fillWidth: true
                from: -1; to: 1; stepSize: .05
                value: Services.Settings.data.appearance.statusRowShade ?? 0
                onMoved: Services.Settings.setValue("appearance", "statusRowShade", value)
            }
        }
        SettingsUI.SettingsButton {
            text: "Reset status row"
            onClicked: { Services.Settings.setValue("appearance", "statusRowRole", null); Services.Settings.setValue("appearance", "statusRowShade", null) }
        }
    }
}
