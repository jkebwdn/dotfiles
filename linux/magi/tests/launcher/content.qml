import QtQuick
import Quickshell
import "../../.config/quickshell/magi/components/launcher" as UI
import "../../.config/quickshell/magi/settings/SettingsSchema.js" as Schema
import "../../.config/quickshell/magi/services/LauncherSearch.js" as Search
ShellRoot {
    QtObject {
        id: mock
        property var preferences: Schema.defaults().launcher
        property var apps: [{id:"a",name:"Alpha",genericName:"Editor",keywords:["text"],icon:""}, {id:"b",name:"Beta",genericName:"Browser",keywords:["web"],icon:""}]
        property var results: Search.rank(apps,query,{})
        property string query: ""
        property bool opened: true
        property int selected: 0
        property bool busy: false
        property string error: ""
        property int launched: -1
        onResultsChanged: selected = 0
        function move(delta) { selected = Math.max(0,Math.min(results.length-1,selected+delta)) }
        function launch(index) { if (index >= 0 && index < results.length) launched = index }
        function close() { opened = false }
    }
    FloatingWindow {
        visible: true; implicitWidth: 720; implicitHeight: 640
        UI.LauncherContent { id: ui; anchors.fill: parent; service: mock }
    }
    UI.LauncherItem {
        id: iconProbe
        visible: false; width: 200; height: 56
        app: ({id:"probe.desktop",name:"Alpha",icon:""})
        preferences: mock.preferences
    }
    Timer {
        interval: 400; running: true
        onTriggered: {
            function check(ok) { if (!ok) throw new Error("Launcher UI assertion") }
            check(iconProbe.iconPresentation.source === "" && iconProbe.iconPresentation.fallbackText === "A")
            iconProbe.app = {id:"probe.desktop",name:"Beta",icon:""}
            check(iconProbe.iconPresentation.fallbackText === "B")
            iconProbe.iconPresentation = {source:"",fallbackText:"Override"}
            iconProbe.grid = true
            check(iconProbe.iconPresentation.fallbackText === "Override")
            ui.focusSearch(); check(ui.searchField.activeFocus)
            ui.navigate(Qt.Key_Down); check(mock.selected === 1)
            ui.navigate(Qt.Key_Up); check(mock.selected === 0)
            mock.query = "web"; check(mock.results.length === 1 && mock.results[0].id === "b")
            ui.navigate(Qt.Key_Return); check(mock.launched === 0)
            mock.query = "missing"; mock.launched = -1
            ui.navigate(Qt.Key_Return); check(mock.launched === -1)
            mock.query = ""
            mock.preferences = Object.assign({},mock.preferences,{layout:"grid"})
            check(ui.grid && ui.columns === 5)
            ui.navigate(Qt.Key_Right); check(mock.selected === 1)
            ui.navigate(Qt.Key_Left); check(mock.selected === 0)
            ui.navigate(Qt.Key_Escape); check(!mock.opened)
            console.log("Launcher content focus, filtering, selection, Enter, Escape, list/grid PASS")
            const preview = Quickshell.env("MAGI_LAUNCHER_PREVIEW")
            if (preview) Qt.callLater(() => ui.grabToImage(image => { image.saveToFile(preview); Qt.quit() }))
            else Qt.quit()
        }
    }
}
