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
    maximumBodyWidth: 520
    description: ""
    RowLayout {
        spacing: 16
        Controls.RoundedArtwork {
            objectName: "profileAvatarPreview"
            Layout.preferredWidth: 88; Layout.preferredHeight: 88
            radius: Theme.Theme.radius("avatar", 10, width, height)
            source: Services.AssetManager.assetUrl(Services.Settings.data.profile.avatar)
            placeholder: "profile"
            borderColor: Theme.Theme.border
            borderWidth: 1
        }
        ColumnLayout {
            SettingsUI.SettingsButton { text: "Choose avatar…"; onClicked: avatarDialog.open() }
            SettingsUI.SettingsButton {
                flat: true
                text: "Clear avatar"; enabled: Services.Settings.data.profile.avatar !== null
                onClicked: Services.Settings.setValue("profile", "avatar", null)
            }
        }
    }
    SettingsUI.SettingsRow {
    Label { text: "Display name"; Layout.fillWidth: true }
    SettingsUI.SettingsTextField {
        Layout.fillWidth: true
        text: Services.Settings.data.profile.displayName
        maximumLength: 80
        placeholderText: "Optional"
        onTextEdited: Services.Settings.setValue("profile", "displayName", text)
        onEditingFinished: Services.Settings.setValue("profile", "displayName", text.trim())
    }
    }
    SettingsUI.SettingsToggle {
        text: "Personal message"
        checked: Services.Settings.data.profile.subtitleMode === "custom"
        onToggled: Services.Settings.setValue("profile", "subtitleMode", checked ? "custom" : "greeting")
    }
    SettingsUI.SettingsRow {
    visible: Services.Settings.data.profile.subtitleMode === "custom"
    Label { text: "Message"; Layout.fillWidth: true }
    SettingsUI.SettingsTextField {
        Layout.fillWidth: true
        text: Services.Settings.data.profile.subtitle
        maximumLength: 160
        placeholderText: "Optional"
        onTextEdited: Services.Settings.setValue("profile", "subtitle", text)
        onEditingFinished: Services.Settings.setValue("profile", "subtitle", text.trim())
    }
    }
    SettingsUI.SettingsSection {
        title: "Weather"; collapsible: true; expanded: true
        SettingsUI.SettingsToggle {
            text: "Enable weather"; checked: Services.Settings.data.weather.enabled
            onToggled: Services.Settings.setValue("weather", "enabled", checked)
        }
        ColumnLayout {
        visible: Services.Settings.data.weather.enabled
        Layout.fillWidth: true
        Label { text: "Location" }
        SettingsUI.SettingsTextField {
            id: weatherLocation
            objectName: "weatherLocation"
            Layout.fillWidth: true
            text: Services.Settings.data.weather.location
            maximumLength: 160
            placeholderText: "City or postcode, optionally followed by country"
        }
        SettingsUI.SettingsButton {
            text: "Save location"
            enabled: weatherLocation.text.trim() !== Services.Settings.data.weather.location
            onClicked: Services.Settings.setValue("weather", "location", weatherLocation.text.trim())
        }
        SettingsUI.SettingsRow {
            Label { text: "Units"; Layout.fillWidth: true }
            SettingsUI.SettingsSelector {
                Accessible.name: "Weather units"; model: ["Metric", "Imperial"]
                currentIndex: Services.Settings.data.weather.units === "imperial" ? 1 : 0
                onActivated: Services.Settings.setValue("weather", "units", currentIndex === 1 ? "imperial" : "metric")
            }
        }
        SettingsUI.SettingsHelp {
            text: Services.Weather.refreshing ? "Updating weather…" : Services.Weather.diagnostic
                || (Services.Weather.resolvedLocation ? "Weather for " + Services.Weather.resolvedLocation : "Set a location and enable weather.")
        }
        SettingsUI.SettingsHelp { text: "Weather by Open-Meteo; locations by GeoNames. Your saved location is sent only when enabled. Refreshes every 30 minutes." }
        SettingsUI.SettingsButton {
            actionKind: "reset";  text: "Reset weather"; onClicked: Services.Settings.resetSection("weather") }
        }
    }
    Label { visible: root.importError.length > 0; text: root.importError; color: Theme.Theme.red; wrapMode: Text.Wrap; Layout.fillWidth: true }
    RowLayout {
        SettingsUI.SettingsButton {
            actionKind: "navigation"; text: "Open Control Centre"; onClicked: Services.MenuController.open("controlcentre") }
        SettingsUI.SettingsButton {
            actionKind: "reset";  text: "Reset profile"; onClicked: Services.Settings.resetSection("profile") }
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
