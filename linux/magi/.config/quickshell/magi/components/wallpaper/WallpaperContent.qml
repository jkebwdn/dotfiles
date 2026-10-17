pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts
import "../../services" as Services
import "../../theme" as Theme
import "../settings" as SettingsUI
Pane {
    id: root
    objectName: "wallpaperManagerContent"
    property alias grid: grid
    function focusGrid() { grid.forceActiveFocus() }
    padding: 0
    focus: true
    background: Item {}
    ColumnLayout {
        anchors.fill: parent; spacing: SettingsUI.SettingsMetrics.gap
        GridLayout {
            Layout.fillWidth: true
            columns: root.width < 520 ? 1 : 2
            columnSpacing: 10; rowSpacing: 8
            SettingsUI.SettingsSelector {
                Layout.fillWidth: true; Layout.maximumWidth: -1
                model: [{name:"", label:"Shared · all monitors"}].concat(Services.Wallpaper.monitors.map(m => ({name:m.name, label:"Monitor · " + m.name})))
                textRole: "label"; Accessible.name: "Wallpaper monitor"
                currentIndex: Math.max(0, model.findIndex(m => m.name === Services.Wallpaper.scope))
                onActivated: Services.Wallpaper.scope = model[currentIndex].name
            }
            SettingsUI.SettingsSelector {
                Layout.fillWidth: true; Layout.maximumWidth: -1
                model: ["cover", "contain", "stretch", "tile"]
                currentIndex: model.indexOf(Services.Wallpaper.mode)
                onActivated: Services.Wallpaper.mode = currentText
                Accessible.name: "Fit mode for next selection"
            }
        }
        RowLayout {
            Layout.fillWidth: true; spacing: 8
            SettingsUI.SettingsSelector {
                Layout.fillWidth: true; Layout.minimumWidth: 100
                model: ["All", "Favourites", "Recents"]
                Accessible.name: "Wallpaper collection"
                currentIndex: model.indexOf(Services.Wallpaper.filter)
                onActivated: Services.Wallpaper.filter = currentText
            }
            SettingsUI.SettingsButton { text: "Random"; enabled: Services.Wallpaper.enabled && !Services.Wallpaper.busy && Services.Wallpaper.results.some(e => !e.outsideLibrary); onClicked: Services.Wallpaper.random() }
            SettingsUI.SettingsButton { text: "Refresh"; enabled: Services.Wallpaper.enabled && !Services.Wallpaper.busy; onClicked: Services.Wallpaper.refresh() }
        }
        Label {
            Layout.fillWidth: true; elide: Text.ElideMiddle; textFormat: Text.PlainText; color: Theme.Theme.subtext
            text: !Services.Wallpaper.currentKnown ? "Current wallpaper unavailable"
                : Services.Wallpaper.currentPath ? "Current · " + Services.Wallpaper.currentPath.split("/").pop()
                : "Different wallpapers across monitors"
        }
        Label {
            Layout.fillWidth: true; wrapMode: Text.WordWrap; textFormat: Text.PlainText
            visible: text.length > 0
            color: Services.Wallpaper.error ? Theme.Theme.red : Theme.Theme.subtext
            text: Services.Wallpaper.error || (Services.Wallpaper.busy ? "Working…" : Services.Wallpaper.message)
                || Services.Wallpaper.warnings.join(" · ")
        }
        GridView {
            id: grid
            objectName: "wallpaperGrid"
            Layout.fillWidth: true; Layout.fillHeight: true; Layout.minimumHeight: 140
            clip: true; focus: true; cacheBuffer: 0
            enabled: Services.Wallpaper.enabled
            model: Services.Wallpaper.results
            cellWidth: width / Math.max(1, Math.floor(width / Services.Wallpaper.preferences.thumbnailSize))
            cellHeight: cellWidth * 0.625 + 38
            keyNavigationEnabled: true
            onModelChanged: currentIndex = 0
            onCurrentIndexChanged: positionViewAtIndex(currentIndex, GridView.Contain)
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
                keyboardFocused: selected && grid.activeFocus
                onChosen: { grid.currentIndex = index; grid.forceActiveFocus(); Services.Wallpaper.choose(modelData.path) }
                onFavouriteRequested: Services.Wallpaper.favourite(modelData.path)
            }
            Label {
                anchors.centerIn: parent; width: Math.max(0, parent.width - 32)
                horizontalAlignment: Text.AlignHCenter; wrapMode: Text.WordWrap
                visible: !grid.count
                color: Theme.Theme.subtext
                text: Services.Wallpaper.busy ? "Loading wallpapers…"
                    : !Services.Wallpaper.enabled ? "Enable Wallpaper Manager to choose an image."
                    : Services.Wallpaper.filter === "All" ? "No images found\nAdd wallpaper directories in Library sources below."
                    : Services.Wallpaper.filter === "Favourites" ? "No favourites yet\nUse the star on an image to save it here."
                    : "No recent wallpapers yet"
            }
        }
    }
}
