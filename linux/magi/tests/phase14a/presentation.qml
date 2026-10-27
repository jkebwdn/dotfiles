import QtQuick
import QtTest
import Quickshell
import "../../.config/quickshell/magi/components/tray" as Tray
import "../../.config/quickshell/magi/services" as Services
import "../../.config/quickshell/magi/theme" as Theme
ShellRoot {
 id: root
 property var calls: []
 QtObject {
  id: app
  property string id: "app"
  property string title: "Fixture app"
  property string icon: fixture.items[0].icon
  property int status: 1
  property string tooltipTitle: "Fixture"
  property string tooltipDescription: "Application-provided plain text"
  property bool onlyMenu: false
  property bool hasMenu: true
  property var menu: ({})
  function activate(){root.calls=root.calls.concat(["activate"])}
  function secondaryActivate(){root.calls=root.calls.concat(["secondary"])}
  function scroll(delta,horizontal){root.calls=root.calls.concat([String(delta)+":"+horizontal])}
 }
 Tray.TrayPreviewModel { id: fixture }
 Services.TrayModel { id: model; sourceItems: [app] }
 FloatingWindow {
  id: win; visible: true; implicitWidth: 720; implicitHeight: 430; color: Theme.Theme.background
  Item {
   id: scene; anchors.fill: parent
   property bool bottomUp: false
   property string caption: "System Tray • synthetic applications"
   Text { x:24;y:76; text:scene.caption; color:Theme.Theme.text; font.pixelSize:18 }
   Rectangle { x:16;y:scene.bottomUp?350:20;width:parent.width-32;height:48;radius:8;color:Theme.Theme.statusPillBackground
    Tray.TrayGroup { id: group; anchors.right:parent.right;anchors.rightMargin:12;anchors.verticalCenter:parent.verticalCenter;items:fixture.items.slice(0,3);maximumWidth:240; nativeMenus:false;bottomUp:scene.bottomUp;onOverflowRequested:overflow.opened=!overflow.opened }
   }
   Tray.TrayItem { id: single;x:24;y:120;width:34;height:30;trayItem:app;nativeMenus:false;onMenuRequested:root.calls=root.calls.concat(["menu"]) }
   Tray.TrayOverflow { id: overflow; x:scene.width-width-28;y:scene.bottomUp?350-height-4:72;items:group.overflowItems;nativeMenus:false;bottomUp:scene.bottomUp;onCloseRequested:opened=false }
  }
 }
 Timer { id: finish; interval:100;onTriggered:Qt.quit() }
 TestCase {
  name:"Tray";when:Services.Settings.ready
  function capture(name){wait(120);grabImage(scene).save(Quickshell.env("MAGI_PHASE14A_PREVIEWS")+"/"+name+".png")}
  function test_tray(){try{
   compare(model.items.length,1)
   mouseClick(single,15,15,Qt.LeftButton);mouseClick(single,15,15,Qt.RightButton);mouseClick(single,15,15,Qt.MiddleButton)
   compare(root.calls.join(','),'activate,menu,secondary')
   app.onlyMenu=true;mouseClick(single,15,15,Qt.LeftButton);compare(root.calls[3],'menu')
   single.forceActiveFocus();keyClick(Qt.Key_Return);keyClick(Qt.Key_Menu);keyClick(Qt.Key_F10,Qt.ShiftModifier)
   compare(root.calls.slice(4).join(','),'menu,menu,menu')
   mouseWheel(single,15,15,120,-240);compare(root.calls.slice(-2).join(','),'-240:false,120:true')
   app.hasMenu=false;const before=root.calls.length;single.context();single.primary();compare(root.calls.length,before)
   app.onlyMenu=false;app.title='Changed title';app.icon=fixture.items[1].icon;app.status=2
   compare(single.accessibleName,'Changed title');verify(single.attention)
   const artwork=findChild(single,'trayApplicationArtwork');tryCompare(artwork,'status',Image.Ready)
   app.icon=Qt.resolvedUrl('tray-pixel.png').toString();tryCompare(artwork,'status',Image.Ready)
   app.icon=fixture.items[2].icon;tryCompare(artwork,'status',Image.Ready)
   app.title='x'.repeat(2000);app.tooltipDescription='y'.repeat(8000);verify(single.tooltipText.length<=781);compare(single.width,34)
   app.title='';app.id='';app.tooltipTitle='';app.tooltipDescription='';app.icon='';compare(single.accessibleName,'Background application');compare(single.tooltipText,'')
   model.sourceItems=[];compare(model.items.length,0);model.sourceItems=[app];compare(model.items.length,1)
   const b=Qt.createQmlObject('import QtQuick; QtObject { property string id: "b"; property string title: "B"; property int status: 0 }',root)
   model.sourceItems=[app,b];compare(model.items[0],app);b.status=2;model.sourceItems=[b,app];compare(model.items[0],app)
   model.sourceItems=[app];b.destroy();wait(30);compare(model.items.length,1)
   single.trayItem=null;verify(!single.primary());single.visible=false
   capture('three-items');group.items=[];capture('empty')
   group.items=fixture.items.slice(0,4);capture('attention');capture('top')
   group.items=fixture.items;group.maximumWidth=104;overflow.opened=true;capture('overflow')
   compare(overflow.delegates.count,group.overflowItems.length)
   const button=overflow.delegates.itemAt(0).button;button.forceActiveFocus();keyClick(Qt.Key_Escape);verify(!overflow.opened)
   scene.bottomUp=true;overflow.opened=true;capture('bottom')
   win.implicitWidth=390;capture('compact');win.implicitWidth=720
   Services.Settings.setTheme('rose-pine-dawn');capture('dawn')
   overflow.opened=false;scene.caption='Secondary output • shared tray stays on main';group.visible=false;capture('secondary-output')
   scene.caption='New main output • same shared application model';group.visible=true;capture('main-output')
   console.log('Phase14A presentation PASS')
  }catch(e){console.error('FAIL',e,e.stack)}finally{finish.start()}}
 }
}
