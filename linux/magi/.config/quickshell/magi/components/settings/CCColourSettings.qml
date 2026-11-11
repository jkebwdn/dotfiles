pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts
import "." as SettingsUI
import "../../services" as Services
import "../../theme" as Theme

SettingsUI.SettingsSection {
    objectName: "ccColours"
    title: "Colours"
    infoText: "Control Centre panel background and border appearance. Border colour and width are shared with other menus."
    SettingsUI.SettingsSubheading {
        objectName: "ccBackground"
        title: "Background"
        SettingsUI.SettingsRow {
            Label { text: "Colour"; Layout.fillWidth: true }
            SettingsUI.SemanticPaletteSelector {
                objectName: "ccBackgroundColour"
                Accessible.name: "Control Centre background colour"
                model: ["background", "surface", "elevated", "overlay", "text", "subtext", "muted", "border", "accent"].concat(Theme.ThemeRegistry.accentRoles)
                role: Services.Settings.data.appearance.controlCentreBackgroundRole
                onRoleSelected: value => Services.Settings.setValue("appearance", "controlCentreBackgroundRole", value)
            }
        }
    }
    SettingsUI.SettingsSubheading {
        objectName: "ccBorder"
        title: "Border"
        collapsible: true
        SettingsUI.SurfaceStyleSettings {
            objectName: "ccBorderStyle"
            carded: false
            // Title is supplied by the semantic subheading; retain accessible control scope.
            accessibleTitle: "Border"
            group: "surfaceBorders"
            targets: [{id: "controlcentre", label: "Show border"}]
        }
    }
}
