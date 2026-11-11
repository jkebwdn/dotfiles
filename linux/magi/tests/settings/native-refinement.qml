// Host-only private review. No operator Settings or system actions are writable.
import QtQuick
import QtQuick.Window
import Quickshell
import Quickshell.Io
import "components/settings" as UI
import "services" as Services
import "theme" as Theme
ShellRoot {
    property bool started: false
    property string original: ""
    readonly property int reviewWidth: Number(Quickshell.env("MAGI_REVIEW_WIDTH"))
    readonly property int reviewHeight: Number(Quickshell.env("MAGI_REVIEW_HEIGHT"))
    FileView { id: document; path: Services.Settings.path; blockLoading: true; blockWrites: true }
    Process { id: addWallpaper; command: ["cp", Quickshell.env("MAGI_REVIEW_FIXTURE"), Quickshell.env("MAGI_REVIEW_NEW_WALLPAPER")] }
    UI.SettingsWindow {
        id: window
        title: "MAGI Settings refinement — private review"
        implicitWidth: reviewWidth; implicitHeight: reviewHeight
        minimumSize: Qt.size(reviewWidth,reviewHeight); maximumSize: Qt.size(reviewWidth,reviewHeight)
        Shortcut { sequence: "Ctrl+R"; onActivated: Services.Settings.reload() }
        Shortcut { sequence: "Ctrl+Shift+R"; onActivated: {
            if (Services.Settings.saveState === "saved") { Services.Settings.commit(JSON.parse(original)) }
        } }
        Shortcut { sequence: "Ctrl+N"; onActivated: addWallpaper.running = true }
    }
    function findItem(item,name) {
        if(item.objectName===name)return item
        for(const child of item.children){const match=findItem(child,name);if(match)return match}
        return null
    }
    function begin() {
        if (started || !Services.Settings.ready) return
        started = true; original = document.text()
        Services.SettingsWindowState.page = "Bar"; Services.SettingsWindowState.shown = true
        Services.Wallpaper.initialize()
        capture.start()
    }
    Connections { target: Services.Settings; function onReadyChanged() { begin() } }
    Component.onCompleted: begin()
    Timer {
        id: capture; interval: 1200
        onTriggered: findItem(window.contentItem,"settingsApplicationPane").grabToImage(result => {
            if (!result.saveToFile(Quickshell.env("MAGI_REVIEW_CAPTURE"))) { console.error("NATIVE_REVIEW_CAPTURE_FAILED"); return }
            console.log("NATIVE_REVIEW_READY " + JSON.stringify({width:window.width,height:window.height,selected:Services.Settings.data.appearance.theme}))
        })
    }
}
