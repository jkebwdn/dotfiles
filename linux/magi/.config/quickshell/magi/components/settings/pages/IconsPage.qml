pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Dialogs
import QtQuick.Layouts
import ".." as SettingsUI
import "../../../components/controls" as Controls
import "../../../services" as Services
import "../../../theme" as Theme
import "../../../icons" as Icons

SettingsUI.SettingsPage {
    id: root
    property string selectedRole: ""
    property int importRequest: 0
    property int packRequest: 0
    property string importError: ""
    readonly property var roles: ["wifi", "bluetooth", "volume", "settings"]
    title: "Icons"
    description: "MAGI shell icons follow the selected pack. Overrides are validated and copied into MAGI-managed storage. Clearing one returns to the selected pack."
    SettingsUI.SettingsSection {
        title: "Shell icon pack"
        description: "MAGI icons are separate from application icons, which follow your system theme."
        RowLayout {
            Layout.fillWidth: true
            ColumnLayout {
                Layout.fillWidth: true
                Label {
                    text: Icons.IconRegistry.packs.find(p => p.id === Services.Settings.data.icons.pack)?.label || Services.Settings.data.icons.pack
                    font.pixelSize: 18; font.bold: true
                    Layout.fillWidth: true; wrapMode: Text.Wrap
                }
                SettingsUI.SettingsHelp { text: "Current pack · change in Appearance" }
            }
            SettingsUI.SettingsButton { text: "Install pack manifest…"; onClicked: packDialog.open() }
        }
    }
    SettingsUI.SettingsSection {
        title: "Individual overrides"
        description: "Import a local SVG for a role, or restore the pack default."
        Repeater {
            model: root.roles
            RowLayout {
                id: roleRow
                required property string modelData
                Layout.fillWidth: true
                Layout.minimumHeight: 60
                spacing: 16
                Rectangle {
                    implicitWidth: 44; implicitHeight: 44
                    radius: Theme.Theme.radius("controlTile", 10, width, height)
                    color: Theme.Theme.surface
                    Controls.Icon { anchors.centerIn: parent; role: roleRow.modelData; moduleId: roleRow.modelData; size: 24 }
                }
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 3
                    Label { text: roleRow.modelData; Layout.fillWidth: true; font.capitalization: Font.Capitalize }
                    Label {
                        text: Services.Settings.data.icons.overrides.global[roleRow.modelData] ? "Custom SVG" : "Pack default"
                        color: Theme.Theme.text; font.pixelSize: 12
                    }
                }
                SettingsUI.SettingsButton {
                    text: "Import SVG…"
                    onClicked: { root.selectedRole = roleRow.modelData; svgDialog.open() }
                }
                SettingsUI.SettingsButton {
                    flat: true
                    text: "Default"
                    enabled: !!Services.Settings.data.icons.overrides.global[roleRow.modelData]
                    onClicked: Services.Settings.setIconOverride(roleRow.modelData, null, "")
                }
            }
        }
    }
    Label { visible: root.importError.length > 0; text: root.importError; color: Theme.Theme.red; wrapMode: Text.Wrap; Layout.fillWidth: true }
    SettingsUI.SettingsButton { flat: true; text: "Reset all icon overrides"; onClicked: Services.Settings.resetSection("icons") }

    FileDialog {
        id: svgDialog
        title: "Import a local SVG"
        nameFilters: ["SVG images (*.svg)"]
        onAccepted: {
            root.importError = ""
            root.importRequest = Services.AssetManager.importIcon(selectedFile, root.selectedRole, "")
        }
    }
    FileDialog {
        id: packDialog
        title: "Install a local MAGI icon-pack manifest"
        nameFilters: ["JSON manifests (*.json)"]
        onAccepted: {
            root.importError = ""
            root.packRequest = Services.AssetManager.importIconPack(selectedFile)
        }
    }
    Connections {
        target: Services.AssetManager
        function onCompleted(requestId, operation, assetId, url, error) {
            if (requestId === root.packRequest && operation === "icon-pack") {
                root.importError = error
                if (!error && assetId.indexOf("pack:") === 0)
                    Services.Settings.setIconPack(assetId.slice(5))
                return
            }
            if (requestId !== root.importRequest) return
            root.importError = error
            if (!error) Services.Settings.setIconOverride(root.selectedRole, assetId, "")
        }
    }
}
