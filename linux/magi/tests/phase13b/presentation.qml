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
  Pages.LockDesignerPage {id:page;anchors.fill:parent}
 }
 Component {id:rawLock;Lock.LockScreen {width:360;height:640;visible:true}}
 Component {id:fullSettings;UI.SettingsContent {anchors.fill:parent}}
 Timer {id:finish;interval:100;onTriggered:Qt.quit()}
 TestCase {
  name:"Phase13B";when:Services.Settings.ready
  function canvas(){return findChild(page,"lockLayoutCanvas")}
  function shot(name){wait(80);grabImage(win.contentItem).save(Quickshell.env("MAGI_PHASE13B_PREVIEWS")+"/"+name+".png")}
  function test_auth_backdrop(){
   const l=Model.preset('editorial');l.elements.media.visible=true
   const scene=rawLock.createObject(win.contentItem,{width:1920,height:1080,
       visual:{lockScreen:l,media:{available:true,title:"Synthetic track",artist:"Synthetic artist"}}})
   wait(40)
   const backdrop=findChild(scene,"authContrastBackdrop")
   verify(backdrop!==null);verify(!backdrop.visible,"separated media needs no auth panel")
   l.elements.media.anchor=l.elements.authentication.anchor
   l.elements.media.offsetX=l.elements.authentication.offsetX
   l.elements.media.offsetY=l.elements.authentication.offsetY
   scene.visual={lockScreen:l,media:{available:true,title:"Synthetic track"}};wait(40)
   verify(backdrop.visible,"overlapping media retains auth protection")
   scene.visual={lockScreen:l,media:{available:false}};wait(40);verify(!backdrop.visible)
   l.elements.media.visible=false;l.effects.depth=true
   scene.preparedDepthSource="";scene.visual={lockScreen:l,depthAvailable:true};wait(40);verify(backdrop.visible,"depth retains protection")
   scene.destroy()
  }
  function test_designer(){
   compare(Services.Settings.data.schemaVersion,22);page.aspectIndex=1;wait(300)
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
   for(const name of ['centered','editorial','split']) {
    const l=Model.preset(name);l.elements.weather.visible=name!=='editorial';l.elements.media.visible=name!=='centered'
    verify(Services.Settings.setLockLayout(l));page.selected=name==='centered'?'weather':'media';wait(60);shot('modules-'+name)
   }
   page.selected='media';page.effect('media','artwork');wait(60);shot('media-artwork')
   for(const theme of ['catppuccin-mocha','everforest-dark-hard','rose-pine','nord','tokyo-night-moon','rose-pine-dawn']){Services.Settings.setTheme(theme);wait(120);shot('modules-'+theme)}
   for(const style of ['dots','line','segments','ring','minimal']){page.selected='authentication';page.effect('credential',style);page.previewState=1;wait(50);shot('credential-'+style)}
   for(const style of ['plain','ring','glow','frame']){page.selected='identity';page.effect('avatar',style);wait(50);shot('avatar-'+style)}
   page.depthPreview=true;wait(60);shot('depth-synthetic');page.depthPreview=false
   page.previewState=3;shot('modules-error');page.previewState=4;shot('modules-caps')
   win.contentItem.Window.window.width=630;wait(60);shot('modules-compact');win.contentItem.Window.window.width=1140
   canvas().aspect=21/9;shot('modules-ultrawide');canvas().aspect=16/9
   Services.Settings.setLockLayout(Model.preset('centered'));wait(50)
   page.previewState=5;page.selected='weather';wait(50)
   const previewScene=findChild(canvas(),"syntheticScene")
   verify(previewScene.elementBoxes.weather.visible)
   compare(Services.Settings.data.lockScreen.elements.weather.visible,false)
   canvas().forceActiveFocus();keyClick(Qt.Key_Right);wait(40)
   compare(Services.Settings.data.lockScreen.elements.weather.visible,false)
   page.previewState=6;wait(40);verify(previewScene.elementBoxes.media.visible)
   compare(Services.Settings.data.lockScreen.elements.media.visible,false)
   page.previewState=0;wait(40)
   verify(!previewScene.elementBoxes.weather.visible && !previewScene.elementBoxes.media.visible)
   page.visible=false;win.contentItem.Window.window.width=1380
   const full=fullSettings.createObject(win.contentItem)
   Services.SettingsWindowState.page="Lock Screen";wait(250)
   verify(findChild(full,"settingsNav-Lock Screen")!==null)
   verify(findChild(full,"lockLayoutCanvas")!==null)
   shot('settings-navigation')
   console.log('Phase13B presentation PASS');finish.start()
  }
 }
}
