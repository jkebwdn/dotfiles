pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Dialogs
import QtQuick.Layouts
import ".." as SettingsUI
import "../../controls" as Controls
import "../../../services" as Services
import "../../../theme" as Theme

SettingsUI.SettingsPage {
    id: root
    property int avatarRequest: 0
    property string importError: ""
    title: "Profile"
    description: "Only information you configure here is shown by MAGI."
    RowLayout {
        spacing: 16
        Controls.RoundedArtwork {
            objectName: "profileAvatarPreview"
            Layout.preferredWidth: 88; Layout.preferredHeight: 88
            radius: Theme.Theme.radius("avatar", 44, width, height)
            source: Services.AssetManager.assetUrl(Services.Settings.data.profile.avatar)
            placeholder: "profile"
            borderColor: Theme.Theme.border
            borderWidth: 1
        }
        ColumnLayout {
            SettingsUI.SettingsButton { text: "Choose avatar…"; onClicked: avatarDialog.open() }
            SettingsUI.SettingsButton {
                text: "Clear avatar"; enabled: Services.Settings.data.profile.avatar !== null
                onClicked: Services.Settings.setValue("profile", "avatar", null)
            }
        }
    }
    Label { text: "Display name"; font.bold: true }
    SettingsUI.SettingsTextField {
        Layout.fillWidth: true
        text: Services.Settings.data.profile.displayName
        maximumLength: 80
        placeholderText: "Optional"
        onTextEdited: Services.Settings.setValue("profile", "displayName", text)
        onEditingFinished: Services.Settings.setValue("profile", "displayName", text.trim())
    }
    SettingsUI.SettingsToggle {
        text: "Use custom subtitle instead of time-of-day greeting"
        checked: Services.Settings.data.profile.subtitleMode === "custom"
        onToggled: Services.Settings.setValue("profile", "subtitleMode", checked ? "custom" : "greeting")
    }
    Label { text: "Saved custom subtitle"; font.bold: true }
    SettingsUI.SettingsTextField {
        Layout.fillWidth: true
        text: Services.Settings.data.profile.subtitle
        maximumLength: 160
        placeholderText: "Optional"
        onTextEdited: Services.Settings.setValue("profile", "subtitle", text)
        onEditingFinished: Services.Settings.setValue("profile", "subtitle", text.trim())
    }
    Label { visible: root.importError.length > 0; text: root.importError; color: Theme.Theme.red; wrapMode: Text.Wrap; Layout.fillWidth: true }
    RowLayout {
        SettingsUI.SettingsButton { text: "Open Control Centre"; onClicked: Services.MenuController.open("controlcentre") }
        SettingsUI.SettingsButton { flat: true; text: "Reset profile"; onClicked: Services.Settings.resetSection("profile") }
    }

    FileDialog {
        id: avatarDialog
        title: "Select a profile image"
        nameFilters: ["Images (*.png *.jpg *.jpeg *.webp)"]
        onAccepted: {
            root.importError = ""
            root.avatarRequest = Services.AssetManager.importAvatar(selectedFile)
        }
    }
    Connections {
        target: Services.AssetManager
        function onCompleted(requestId, operation, assetId, url, error) {
            if (requestId !== root.avatarRequest) return
            root.importError = error
            if (!error) Services.Settings.setValue("profile", "avatar", assetId)
        }
    }
}
