import QtQuick
import QtQuick.Window
import QtTest
import Quickshell
import "../../.config/quickshell/magi/components/settings/pages" as Pages
import "../../.config/quickshell/magi/components/settings" as UI
import "../../.config/quickshell/magi/components/lockPresentation" as Lock
import "../../.config/quickshell/magi/components/lockPresentation/LockLayout.js" as Model
import "../../.config/quickshell/magi/services" as Services
import "../../.config/quickshell/magi/theme" as Theme
ShellRoot {
 FloatingWindow {id:win;visible:true;implicitWidth:1140;implicitHeight:880;color:Theme.Theme.background
  Pages.LockScreenPage {id:page;anchors.fill:parent}
 }
 Component {id:rawLock;Lock.LockScreen {width:360;height:640;visible:true}}
 Component {id:fullSettings;UI.SettingsContent {anchors.fill:parent}}
 Timer {id:finish;interval:100;onTriggered:Qt.quit()}
 TestCase {
  name:"Phase13A";when:Services.Settings.ready
  function canvas(){return findChild(page,"lockLayoutCanvas")}
  function shot(name){wait(80);grabImage(win.contentItem).save(Quickshell.env("MAGI_PHASE13A_PREVIEWS")+"/"+name+".png")}
  function test_designer(){
   compare(Services.Settings.data.schemaVersion,20);page.aspectIndex=1;wait(300)
   const fallback=rawLock.createObject(win.contentItem,{visual:{lockScreen:{layoutVersion:1,space:"screen",elements:{time:{anchor:"bad"}}}},inputActive:true})
   compare(fallback.layout.preset,"centered");verify(fallback.elementBoxes.authentication.visible)
   fallback.authStatus="Keyboard state unavailable: press and release Shift";wait(30)
   verify(fallback.elementBoxes.authentication.height>0);fallback.destroy()
   for(const name of ['centered','editorial','corner','split','minimal']){
    verify(Services.Settings.setLockLayout(Model.preset(name)));wait(80);shot(name)
    const scene=findChild(canvas(),"syntheticScene")
    verify(scene!==null)
    for(const ratio of [16/9,16/10,21/9,9/16]){
     canvas().aspect=ratio;wait(30)
     for(const id of Model.ids()){
      const b=scene.elementBoxes[id];verify(b.x>=0&&b.y>=0,id+' inside');verify(b.visible||id!=='authentication')
      verify((b.y+b.height*b.scale)*scene.unit<=scene.height,id+' bottom')
     }
    }
   }
   canvas().aspect=16/9;Services.Settings.setLockLayout(Model.preset('centered'));wait(80)
   for(let state=1;state<=4;state++){page.previewState=state;shot(['','typing','authenticating','wrong-password','caps-lock'][state])}
   page.previewState=0
   page.selected='identity';page.edit('visible',false);wait(30)
   verify(!Services.Settings.data.lockScreen.elements.identity.visible)
   page.edit('visible',true);wait(30);verify(Services.Settings.data.lockScreen.elements.identity.visible)
   Services.Settings.setLockLayout(Model.preset('centered'));page.selected='time';wait(50)
   const c=canvas(), original=JSON.stringify(Services.Settings.data.lockScreen)
   const scene=findChild(c,"syntheticScene"), b=scene.elementBoxes.time
   const px=(b.x+b.width*b.scale/2)*scene.unit*c.width/scene.width
   const py=(b.y+b.height*b.scale/2)*scene.unit*c.width/scene.width
   mousePress(c,px,py,Qt.LeftButton);mouseMove(c,px+32,py+18,30)
   compare(JSON.stringify(Services.Settings.data.lockScreen),original)
   mouseRelease(c,px+32,py+18,Qt.LeftButton);wait(40)
   verify(JSON.stringify(Services.Settings.data.lockScreen)!==original,"pointer release commits")
   Services.Settings.setLockLayout(Model.preset('centered'));wait(50)
   c.begin();c.move('time',100,100,true);compare(JSON.stringify(Services.Settings.data.lockScreen),original)
   c.cancel();compare(JSON.stringify(Services.Settings.data.lockScreen),original)
   c.begin();c.move('time',100,100,true);c.finish();wait(30)
   compare(Services.Settings.data.lockScreen.preset,'custom')
   c.forceActiveFocus();const x=Services.Settings.data.lockScreen.elements.time.offsetX
   keyClick(Qt.Key_Right);wait(30);verify(Services.Settings.data.lockScreen.elements.time.offsetX>x)
   c.begin();c.move('time',500,200,true);keyClick(Qt.Key_Escape);compare(c.draft,null)
   verify(Services.Settings.resetSection('lockScreen'));wait(30);compare(page.layout.preset,'centered')
   win.contentItem.Window.window.width=630;wait(60);shot('compact');win.contentItem.Window.window.width=1140
   canvas().aspect=21/9;shot('ultrawide');canvas().aspect=16/9
   for(const theme of ['catppuccin-mocha','everforest-dark-hard','rose-pine','nord','tokyo-night-moon','rose-pine-dawn']) {
    verify(Services.Settings.setTheme(theme));wait(120);shot(theme==='rose-pine-dawn' ? 'dawn' : 'theme-'+theme)
   }
   page.visible=false;win.contentItem.Window.window.width=1380
   const full=fullSettings.createObject(win.contentItem)
   Services.SettingsWindowState.page="Lock Screen";wait(250)
   verify(findChild(full,"settingsNav-Lock Screen")!==null)
   verify(findChild(full,"lockLayoutCanvas")!==null)
   shot('settings-navigation')
   console.log('Phase13A presentation PASS');finish.start()
  }
 }
}
