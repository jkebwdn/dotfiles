import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts
import "../../../services" as Services
import "../../../theme" as Theme
import ".." as SettingsUI
SettingsUI.SettingsPage {
    id: root
    title: "Wallpaper"
    description: "Choose your library sources. Directory edits are saved only when you select Save directories."

    SettingsUI.SettingsToggle {
        text: "Enable Wallpaper Manager"
        checked: Services.Settings.data.wallpaper.enabled
        onClicked: Services.Settings.setValue("wallpaper", "enabled", checked)
    }
    SettingsUI.SettingsButton {
        text: "Open Wallpaper Manager"; enabled: Services.Settings.data.wallpaper.enabled
        onClicked: { Services.SettingsWindowState.shown = false; Services.Wallpaper.open() }
    }
    SettingsUI.SettingsSection {
        title: "Library sources"
        Label { text: "Wallpaper directories · one absolute or ~/ path per line"; wrapMode: Text.Wrap; Layout.fillWidth: true }
        TextArea {
            id: directories
            objectName: "wallpaperDirectories"
            Layout.fillWidth: true; Layout.preferredHeight: 130
            text: Services.Settings.data.wallpaper.directories.join("\n")
            selectByMouse: true; wrapMode: TextEdit.Wrap
        }
        SettingsUI.SettingsButton {
            primary: true; text: "Save directories"
            onClicked: Services.Settings.setValue("wallpaper", "directories", [...new Set(directories.text.split("\n").filter(p => p.length))])
        }
        Label {
            text: "Only files directly inside these roots are scanned. Missing directories are reported. PNG and JPEG are supported; WebP is not enabled on this Qt installation. Sources are never modified."
            wrapMode: Text.Wrap; Layout.fillWidth: true; color: Theme.Theme.text
        }
    }
    SettingsUI.SettingsRow {
        Label { text: "Thumbnail size"; Layout.fillWidth: true }
        SettingsUI.SettingsNumber {
            from: 160; to: 320; stepSize: 20
            value: Services.Settings.data.wallpaper.thumbnailSize
            onValueModified: Services.Settings.setValue("wallpaper", "thumbnailSize", value)
        }
    }
    Label {
        Layout.fillWidth: true; wrapMode: Text.Wrap; textFormat: Text.PlainText
        text: "Current: " + (Services.Wallpaper.currentPath || "Open the manager to inspect monitor assignments")
    }
    Label {
        Layout.fillWidth: true; wrapMode: Text.Wrap; color: Theme.Theme.text
        text: "The manager offers all-monitor or per-monitor selection, cover/contain/stretch/tile, favourites and the 24 most recent wallpapers. Fit applies with your next selection. Reset below changes preferences; saved wallpapers and favourites remain."
    }
    SettingsUI.SettingsButton { text: "Clear recent wallpapers"; enabled: !Services.Wallpaper.busy; onClicked: Services.Wallpaper.start({op:"clearRecents"}) }
    SettingsUI.SettingsButton { flat: true; text: "Reset Wallpaper preferences"; onClicked: Services.Settings.resetSection("wallpaper") }
    Label { text: Services.Wallpaper.error; color: Theme.Theme.red; Layout.fillWidth: true; wrapMode: Text.Wrap; textFormat: Text.PlainText }

}
