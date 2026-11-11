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
    UI.SettingsWindow {
        id: window
        title: "MAGI Control Centre pass 2 — private review"
        implicitWidth: reviewWidth; implicitHeight: reviewHeight
        minimumSize: Qt.size(reviewWidth,reviewHeight); maximumSize: Qt.size(reviewWidth,reviewHeight)
        Shortcut { sequence: "Ctrl+R"; onActivated: Services.Settings.reload() }
        Shortcut { sequence: "Ctrl+Shift+R"; onActivated: {
            if (Services.Settings.saveState === "saved") { Services.Settings.commit(JSON.parse(original)) }
        } }
    }
    function findItem(item,name) {
        if(item.objectName===name)return item
        for(const child of item.children){const match=findItem(child,name);if(match)return match}
        return null
    }
    function begin() {
        if (started || !Services.Settings.ready) return
        started = true; original = document.text()
        Services.SettingsWindowState.page = "Control Centre"; Services.SettingsWindowState.shown = true
        capture.start()
    }
    Connections { target: Services.Settings; function onReadyChanged() { begin() } }
    Component.onCompleted: begin()
    Timer {
        id: capture; interval: 1200
        onTriggered: {
            const card=findItem(window.contentItem,"ccAvailableControls"), preview=findItem(window.contentItem,"controlCentrePreview")
            for(const key of preview.moduleBoard.order("available")) {
                const row=preview.moduleBoard.rowFor(key), presenter=findItem(row,"ccPreview-"+key)
                if (!presenter || presenter.height <= 0 || presenter.mapToItem(card,0,0).y < card.controlsArea.mapToItem(card,0,0).y - 1) {
                    console.error("NATIVE_REVIEW_PALETTE_GEOMETRY_FAILED " + key); return
                }
            }
            findItem(window.contentItem,"settingsApplicationPane").grabToImage(result => {
            if (!result.saveToFile(Quickshell.env("MAGI_REVIEW_CAPTURE"))) { console.error("NATIVE_REVIEW_CAPTURE_FAILED"); return }
            console.log("NATIVE_REVIEW_READY " + JSON.stringify({width:window.width,height:window.height,selected:Services.Settings.data.appearance.theme,panelWidth:preview.canvasWidth*preview.fitScale,panelHeight:preview.composition.height*preview.fitScale}))
        })
        }
    }
}
