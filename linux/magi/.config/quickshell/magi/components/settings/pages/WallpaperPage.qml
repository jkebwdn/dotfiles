import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts
import "../../../services" as Services
import "../../../theme" as Theme
import ".." as SettingsUI
import "../../wallpaper" as WallpaperUI
SettingsUI.SettingsPage {
    id: root
    title: "Wallpaper"
    description: "Choose a wallpaper for every monitor or just one. Fit applies with your next selection."
    Component.onCompleted: Services.Wallpaper.prepare()
    onRevisited: Services.Wallpaper.prepare()

    WallpaperUI.WallpaperContent {
        Layout.fillWidth: true
        Layout.preferredHeight: Math.max(360, root.height - 150)
    }

    SettingsUI.SettingsToggle {
        text: "Enable Wallpaper Manager"
        checked: Services.Settings.data.wallpaper.enabled
        onClicked: Services.Settings.setValue("wallpaper", "enabled", checked)
    }
    SettingsUI.SettingsSection {
        objectName: "wallpaperLibrarySources"
        title: "Library sources"
        collapsible: true
        description: directories.text !== Services.Settings.data.wallpaper.directories.join("\n") ? "Unsaved directory changes" : "Directory changes apply only when saved."
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
    SettingsUI.SettingsButton { text: "Clear recent wallpapers"; enabled: !Services.Wallpaper.busy; onClicked: Services.Wallpaper.start({op:"clearRecents"}) }
    SettingsUI.SettingsButton { flat: true; text: "Reset Wallpaper preferences"; onClicked: Services.Settings.resetSection("wallpaper") }

}
