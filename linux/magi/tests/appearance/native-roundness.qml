// Host-only review harness. The launcher supplies a disposable Settings document.
import QtQuick
import QtQuick.Window
import Quickshell
import Quickshell.Io
import "components/settings" as UI
import "services" as Services
import "theme" as Theme
ShellRoot {
    readonly property int reviewWidth: Number(Quickshell.env("MAGI_REVIEW_WIDTH"))
    readonly property int reviewHeight: Number(Quickshell.env("MAGI_REVIEW_HEIGHT"))
    property bool started: false
    property string original: ""
    function findItem(item,name) {
        if(item.objectName===name)return item
        for(const child of item.children){const match=findItem(child,name);if(match)return match}
        return null
    }
    FileView {id:document;path:Services.Settings.path;blockLoading:true;blockWrites:true}
    UI.SettingsWindow {
        id:window
        title:"MAGI Feature Roundness — private review (Ctrl+R reload; Ctrl+Shift+R restore)"
        implicitWidth:reviewWidth;implicitHeight:reviewHeight
        minimumSize:Qt.size(reviewWidth,reviewHeight);maximumSize:Qt.size(reviewWidth,reviewHeight)
        Shortcut {sequence:"Ctrl+R";onActivated:Services.Settings.reload()}
        Shortcut {sequence:"Ctrl+Shift+R";onActivated:{if(Services.Settings.saveState==="saved"){document.setText(original);Services.Settings.reload()}}}
    }
    Connections {target:Services.Settings;function onReadyChanged(){if(Services.Settings.ready)begin()}}
    function begin(){
        if(started || !Services.Settings.ready)return
        started=true;original=document.text()
        Services.SettingsWindowState.page="Appearance";Services.SettingsWindowState.shown=true
        capture.start()
    }
    Component.onCompleted:begin()
    Timer {
        id:capture;interval:1200
        onTriggered:{
            const page=findItem(window.contentItem,"settingsPage-Appearance"),roundness=findItem(window.contentItem,"roundnessPicker")
            if(!page || !roundness || window.width!==reviewWidth || window.height!==reviewHeight){console.error("NATIVE_REVIEW_GEOMETRY");return}
            page.contentY=Math.max(0,Math.min(page.contentHeight-page.height,roundness.mapToItem(page,0,0).y+page.contentY-24))
            settle.start()
        }
    }
    Timer {
        id:settle;interval:300
        onTriggered:findItem(window.contentItem,"settingsApplicationPane").grabToImage(result=>{
            if(!result.saveToFile(Quickshell.env("MAGI_REVIEW_CAPTURE"))){console.error("NATIVE_REVIEW_CAPTURE_FAILED");return}
            console.log("NATIVE_REVIEW_READY "+JSON.stringify({theme:Theme.Theme.definition.id,width:window.width,height:window.height,selected:Services.Settings.data.appearance.theme}))
        })
    }
}
