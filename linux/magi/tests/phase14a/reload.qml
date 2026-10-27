import QtQuick
import Quickshell
import Quickshell.Io
import "../../.config/quickshell/magi/services" as Services
import "../../.config/quickshell/magi/components/tray" as Tray
ShellRoot {
 id: root
 property int calls: 0
 QtObject {id: app;property string id:"reload-fixture";property string title:"Reload fixture";property string icon:"";property int status:1;function activate(){root.calls++}function secondaryActivate(){root.calls++}function scroll(d,h){root.calls++}}
 Services.TrayModel {id:model;sourceItems:[app]}
 FloatingWindow {visible:true;implicitWidth:300;implicitHeight:80;Tray.TrayGroup {items:model.items;nativeMenus:false}}
 Process {
  running:true
  command:["python3","-c","from pathlib import Path; import sys; p=Path(sys.argv[1]); print(int(p.exists())); p.touch()",Quickshell.env("MAGI_TRAY_RELOAD_MARKER")]
  stdout:StdioCollector {onStreamFinished:{
   if(model.items.length!==1 || root.calls!==0) throw new Error('Reload changed tray state or dispatched an action')
   if(text.trim()==='0') reload.start()
   else {console.log('Phase14A synthetic hard reload PASS');finish.start()}
  }}
 }
 Timer {id:reload;interval:100;onTriggered:{if(root.calls!==0)throw new Error('Unexpected action');Quickshell.reload(true)}}
 Timer {id:finish;interval:100;onTriggered:Qt.quit()}
}
