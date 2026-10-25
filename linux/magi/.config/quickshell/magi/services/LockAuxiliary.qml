pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import "../icons" as Icons
Scope {
    id: root
    property bool active: false
    readonly property var layout: Settings.data.lockScreen || ({})
    readonly property bool enabled: !!(Settings.ready && layout.elements && layout.elements.media && layout.elements.media.visible === true)
    readonly property string payload: JSON.stringify(enabled ? {title:Media.title,artist:Media.artist,available:Media.available,playing:Media.playing,artwork:Media.artworkUrl,icon:Icons.IconRegistry.resolve("media-play").icon} : {})
    property string pending: ""
    function activate() { active=true; schedule() }
    function schedule() { if(active) {pending=payload;debounce.restart()} }
    onPayloadChanged: schedule()
    Timer {id:debounce;interval:300;onTriggered:{if(!writer.running) writer.running=true}}
    Process {
        id:writer;stdinEnabled:true
        command:["python3",Qt.resolvedUrl("lock_auxiliary.py").toString().replace(/^file:\/\//, "")]
        property string submitted: ""
        onStarted:{submitted=root.pending;write(submitted+"\n")}
        onExited:{if(submitted!==root.pending) debounce.restart()}
    }
}
