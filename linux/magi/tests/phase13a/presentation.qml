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
  function test_corners_stable(){
   function check(value,message){if(!value) console.error("FAIL corners: "+message);verify(value,message)}
   function near(a,b,t,message){if(Math.abs(a-b)>t)console.error("FAIL corners: "+message+" "+a+" / "+b);fuzzyCompare(a,b,t,message)}
   function equal(a,b,message){if(a!==b)console.error("FAIL corners: "+message+" "+a+" / "+b);compare(a,b,message)}
   for(const size of [[800,600],[1920,1080],[3440,1440],[360,640]]) {
    win.contentItem.Window.window.width=size[0];win.contentItem.Window.window.height=size[1];wait(20)
    const scene=rawLock.createObject(win.contentItem,{width:size[0],height:size[1],timeLabel:"09:54",dateLabel:"Thursday, 29 October",inputActive:true,characterCount:6,visual:{displayName:"Alex",media:{available:true,title:"Morning light",playing:true},lockScreen:Model.preset("split-corners")}})
    wait(30)
    const names=["authHost","credentialDots","passwordPrompt","powerActions","authFeedback"]
    const items=names.map(n=>findChild(scene,n))
    function positions(){return items.map(i=>i.mapToItem(scene,0,0).y)}
    const label=findChild(scene,"passwordLabel"), mask=findChild(scene,"credentialDots"), power=findChild(scene,"powerSuspend")
    function right(i){return i.mapToItem(scene,i.width,0).x}
    near(right(label),right(mask),.1,"Mask and prompt share right edge")
    near(right(label),right(power),.1,"Power and prompt share right edge")
    const finger=findChild(scene,"fingerprintIndicator"), capsIcon=findChild(scene,"capsIndicator")
    check(right(capsIcon)<finger.mapToItem(scene,0,0).x,"Caps before fingerprint")
    check(right(finger)<label.mapToItem(scene,0,0).x,"Fingerprint before label")
    const before=JSON.stringify(positions())
    for(const caps of [false,true,false]) {
     scene.capsLock=caps;wait(20)
     equal(JSON.stringify(positions()),before,"Caps cannot move any auth element")
     equal(findChild(scene,"capsIndicator").opacity,caps?1:0)
    }
    for(const state of ["Touch fingerprint sensor","Reading…","Try again","Fingerprint didn’t match · try again","Fingerprint timed out · use password","Fingerprint matched","Fingerprint unavailable",""]) {
     scene.fingerprintStatus=state;scene.authStatus="Authentication failed";wait(20)
     equal(JSON.stringify(positions()),before,"Feedback cannot move authentication")
    }
    const time=scene.elementBoxes.time,identity=scene.elementBoxes.identity,auth=scene.elementBoxes.authentication
    check(!findChild(scene,"profileName").visible,"Compact identity omits username")
    near(time.height*time.scale,identity.height*identity.scale,.1,"Clock/date match avatar height")
    near(time.x-(identity.x+identity.width*identity.scale),12,.1,"Tight logical avatar/clock gutter")
    const media=scene.elementBoxes.media
    check(media.y >= identity.y+identity.height*identity.scale+12,"Now playing beneath identity")
    check(findChild(media,"nowPlayingTitle").visible,"Title only media row")
    check(media.y+media.height*media.scale < auth.y,"Media clear of auth")
    check(time.y+time.height*time.scale < auth.y,"Negative space remains")
    check(auth.x+auth.width*auth.scale <= size[0]/findChild(scene,"visualTokens").visualScale-16,"Auth safe right edge")
    check(auth.y+auth.height*auth.scale <= size[1]/findChild(scene,"visualTokens").visualScale-48,"Auth safe bottom edge")
    scene.authStatus="Locked";scene.fingerprintStatus="Touch fingerprint sensor";scene.capsLock=true;wait(30)
    grabImage(scene).save(Quickshell.env("MAGI_PHASE13A_PREVIEWS")+"/corners-"+size[0]+".png")
    scene.destroy()
   }
   console.log("Corners checks PASS")
   win.contentItem.Window.window.width=1140;win.contentItem.Window.window.height=880;wait(20)
  }
  function test_designer(){
   compare(Services.Settings.data.schemaVersion,22);page.aspectIndex=1;wait(300)
   const fallback=rawLock.createObject(win.contentItem,{visual:{lockScreen:{layoutVersion:1,space:"screen",elements:{time:{anchor:"bad"}}}},inputActive:true})
   compare(fallback.layout.preset,"centered");verify(fallback.elementBoxes.authentication.visible)
   fallback.authStatus="Keyboard state unavailable: press and release Shift";wait(30)
   verify(fallback.elementBoxes.authentication.height>0);fallback.destroy()
   for(const name of ['centered','editorial','corner','split','minimal','split-corners']){
    canvas().aspect=16/9;verify(Services.Settings.setLockLayout(Model.preset(name)));wait(80);shot(name)
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
   Services.Settings.setLockLayout(Model.preset('split-corners'));wait(40)
   for(const theme of ['catppuccin-mocha','everforest-dark-hard','kanagawa-wave','one-light','rose-pine','nord','tokyo-night-moon','rose-pine-dawn']) {
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
