pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Dialogs
import QtQuick.Layouts
import ".." as SettingsUI
import "../../../components/controls" as Controls
import "../../../services" as Services
import "../../../theme" as Theme

Flickable {
    id: root
    property string selectedRole: ""
    property int importRequest: 0
    property int packRequest: 0
    property string importError: ""
    readonly property var roles: ["wifi", "bluetooth", "volume", "settings"]
    contentHeight: content.implicitHeight + 48
    clip: true
    ScrollBar.vertical: ScrollBar {}
    ColumnLayout {
        id: content
        x: 24; y: 24; width: root.width - 48
        spacing: 16
        Label { text: "Icons"; font.pixelSize: 26; font.bold: true }
        Label {
            text: "Overrides are validated and copied into MAGI-managed storage. Clearing one returns to the selected pack."
            color: Theme.Theme.subtext; wrapMode: Text.WordWrap; Layout.fillWidth: true
        }
        RowLayout {
            Layout.fillWidth: true
            Label { text: "Installed packs"; font.bold: true; Layout.fillWidth: true }
            SettingsUI.SettingsButton { text: "Install pack manifest…"; onClicked: packDialog.open() }
        }
        Repeater {
            model: root.roles
            RowLayout {
                id: roleRow
                required property string modelData
                Layout.fillWidth: true
                Controls.Icon { role: roleRow.modelData; moduleId: roleRow.modelData; size: 24 }
                Label { text: roleRow.modelData; Layout.fillWidth: true; font.capitalization: Font.Capitalize }
                Label {
                    text: Services.Settings.data.icons.overrides.global[roleRow.modelData] ? "Custom" : "Pack default"
                    color: Theme.Theme.subtext
                }
                SettingsUI.SettingsButton {
                    text: "Import SVG…"
                    onClicked: { root.selectedRole = roleRow.modelData; svgDialog.open() }
                }
                SettingsUI.SettingsButton {
                    text: "Default"
                    enabled: !!Services.Settings.data.icons.overrides.global[roleRow.modelData]
                    onClicked: Services.Settings.setIconOverride(roleRow.modelData, null, "")
                }
            }
        }
        Label { visible: root.importError.length > 0; text: root.importError; color: Theme.Theme.red; wrapMode: Text.WordWrap; Layout.fillWidth: true }
        SettingsUI.SettingsButton { text: "Reset all icon overrides"; onClicked: Services.Settings.resetSection("icons") }
    }
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
