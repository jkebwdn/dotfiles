pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Dialogs
import QtQuick.Layouts
import ".." as SettingsUI
import "../../../services" as Services
import "../../../theme" as Theme

Flickable {
    id: root
    property int avatarRequest: 0
    property string importError: ""
    contentHeight: content.implicitHeight + 48
    clip: true
    ScrollBar.vertical: ScrollBar {}
    ColumnLayout {
        id: content
        x: 24; y: 24; width: root.width - 48
        spacing: 16
        Label { text: "Profile"; font.pixelSize: 26; font.bold: true }
        Label {
            text: "Only information you configure here is shown by MAGI."
            color: Theme.Theme.subtext; wrapMode: Text.WordWrap; Layout.fillWidth: true
        }
        RowLayout {
            spacing: 16
            Rectangle {
                Layout.preferredWidth: 88; Layout.preferredHeight: 88; radius: 44; clip: true
                color: Theme.Theme.elevated
                Image {
                    anchors.fill: parent
                    source: Services.AssetManager.assetUrl(Services.Settings.data.profile.avatar)
                    fillMode: Image.PreserveAspectCrop
                    sourceSize: Qt.size(176, 176)
                }
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
        TextField {
            Layout.fillWidth: true
            text: Services.Settings.data.profile.displayName
            maximumLength: 80
            placeholderText: "Optional"
            onTextEdited: Services.Settings.setValue("profile", "displayName", text)
            onEditingFinished: Services.Settings.setValue("profile", "displayName", text.trim())
        }
        Label { text: "Subtitle or status"; font.bold: true }
        TextField {
            Layout.fillWidth: true
            text: Services.Settings.data.profile.subtitle
            maximumLength: 160
            placeholderText: "Optional"
            onTextEdited: Services.Settings.setValue("profile", "subtitle", text)
            onEditingFinished: Services.Settings.setValue("profile", "subtitle", text.trim())
        }
        Label { visible: root.importError.length > 0; text: root.importError; color: Theme.Theme.red; wrapMode: Text.WordWrap; Layout.fillWidth: true }
        RowLayout {
            SettingsUI.SettingsButton { text: "Open Control Centre"; onClicked: Services.MenuController.open("controlcentre") }
            SettingsUI.SettingsButton { text: "Reset profile"; onClicked: Services.Settings.resetSection("profile") }
        }
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
