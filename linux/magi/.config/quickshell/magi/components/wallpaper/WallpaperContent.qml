pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts
import "../../services" as Services
import "../../theme" as Theme
Pane {
    id: root
    property alias grid: grid
    function focusGrid() { grid.forceActiveFocus() }
    padding: 20
    focus: true
    palette.windowText: Theme.Theme.text
    palette.text: Theme.Theme.text
    palette.button: Theme.Theme.elevated
    palette.buttonText: Theme.Theme.text
    palette.base: Theme.Theme.surface
    palette.highlight: Theme.Theme.accent
    background: Rectangle { color: Theme.Theme.background; radius: 16; border.color: Theme.Theme.border }
    Keys.onEscapePressed: Services.Wallpaper.close()
    ColumnLayout {
        anchors.fill: parent; spacing: 12
        RowLayout {
            Label { text: "Wallpapers"; font.pixelSize: 26; font.bold: true; Layout.fillWidth: true }
            Button { text: "Settings"; onClicked: { Services.Wallpaper.close(); Services.SettingsWindowState.page = "Wallpaper"; Services.SettingsWindowState.open() } }
            Button { text: "Close"; onClicked: Services.Wallpaper.close() }
        }
        RowLayout {
            ComboBox {
                model: ["All", "Favourites", "Recents"]
                currentIndex: model.indexOf(Services.Wallpaper.filter)
                onActivated: Services.Wallpaper.filter = currentText
            }
            ComboBox {
                Layout.fillWidth: true
                model: [{name:"", label:"All monitors"}].concat(Services.Wallpaper.monitors.map(m => ({name:m.name, label:m.name})))
                textRole: "label"
                currentIndex: Math.max(0, model.findIndex(m => m.name === Services.Wallpaper.scope))
                onActivated: Services.Wallpaper.scope = model[currentIndex].name
            }
            ComboBox {
                model: ["cover", "contain", "stretch", "tile"]
                currentIndex: model.indexOf(Services.Wallpaper.mode)
                onActivated: Services.Wallpaper.mode = currentText
                Accessible.name: "Fit mode for next selection"
            }
            Button { text: "Random"; enabled: !Services.Wallpaper.busy && Services.Wallpaper.results.some(e => !e.outsideLibrary); onClicked: Services.Wallpaper.random() }
            Button { text: "Refresh"; enabled: !Services.Wallpaper.busy; onClicked: Services.Wallpaper.refresh() }
        }
        Label {
            Layout.fillWidth: true; wrapMode: Text.WordWrap; textFormat: Text.PlainText
            color: Services.Wallpaper.error ? Theme.Theme.red : Theme.Theme.subtext
            text: Services.Wallpaper.error || (Services.Wallpaper.busy ? "Working…" : Services.Wallpaper.message)
                || Services.Wallpaper.warnings.join(" · ") || "Choose an image to apply it. Arrow keys browse; Enter applies."
        }
        GridView {
            id: grid
            Layout.fillWidth: true; Layout.fillHeight: true
            clip: true; focus: true; cacheBuffer: 0
            model: Services.Wallpaper.results
            cellWidth: width / Math.max(2, Math.floor(width / Services.Wallpaper.preferences.thumbnailSize))
            cellHeight: cellWidth * 0.65
            keyNavigationEnabled: true
            onModelChanged: currentIndex = 0
            Keys.onReturnPressed: { if (currentIndex >= 0 && currentIndex < count) Services.Wallpaper.choose(model[currentIndex].path) }
            Keys.onEnterPressed: { if (currentIndex >= 0 && currentIndex < count) Services.Wallpaper.choose(model[currentIndex].path) }
            ScrollBar.vertical: ScrollBar {}
            delegate: WallpaperTile {
                required property var modelData
                required property int index
                entry: modelData
                width: grid.cellWidth; height: grid.cellHeight
                current: Services.Wallpaper.currentPath === modelData.path
                favourite: Services.Wallpaper.state.favourites.indexOf(modelData.path) >= 0
                selected: grid.currentIndex === index
                onChosen: { grid.currentIndex = index; grid.forceActiveFocus(); Services.Wallpaper.choose(modelData.path) }
                onFavouriteRequested: Services.Wallpaper.favourite(modelData.path)
            }
            Label {
                anchors.centerIn: parent; width: parent.width - 40
                horizontalAlignment: Text.AlignHCenter; wrapMode: Text.WordWrap
                visible: !grid.count && !Services.Wallpaper.busy
                color: Theme.Theme.subtext
                text: Services.Wallpaper.filter === "All" ? "No images found. Add explicit wallpaper directories in Settings, then Refresh. PNG and JPEG are supported." : "No saved wallpapers in this view."
            }
        }
        Label {
            Layout.fillWidth: true; elide: Text.ElideMiddle; textFormat: Text.PlainText; color: Theme.Theme.subtext
            text: !Services.Wallpaper.currentKnown ? "Current wallpaper unavailable — check the backend connection."
                : Services.Wallpaper.currentPath || "Different wallpapers across monitors"
        }
    }
}
