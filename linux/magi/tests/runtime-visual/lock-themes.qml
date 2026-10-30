import QtQuick
import QtQuick.Window
import QtTest
import Quickshell
import "../../.config/quickshell/magi/components/settings/pages" as Pages
import "../../.config/quickshell/magi/components/lockPresentation" as Lock
import "../../.config/quickshell/magi/components/lockPresentation/LockThemes.js" as Themes
import "../../.config/quickshell/magi/components/lockPresentation/LockLayout.js" as Model
import "../../.config/quickshell/magi/services" as Services
import "../../.config/quickshell/magi/theme" as Theme
ShellRoot {
 FloatingWindow {id:win;visible:true;implicitWidth:1200;implicitHeight:900;color:Theme.Theme.background
  Pages.LockScreenPage {id:page;anchors.fill:parent}
 }
 Component {id:sceneFactory;Lock.LockScreen {timeLabel:"09:41";dateLabel:"Friday, 30 October";inputActive:true;characterCount:6;preparedMediaSource:Qt.resolvedUrl("components/settings/lock-depth-fixture.svg")}}
 Timer {id:finish;interval:100;onTriggered:Qt.quit()}
 TestCase {
  name:"LockThemes";when:Services.Settings.ready
  function check(v,m){if(!v)console.error("FAIL: "+m);verify(v,m)}
  function equal(a,b,m){check(JSON.stringify(a)===JSON.stringify(b),(m||"Values differ")+" "+JSON.stringify(a)+" / "+JSON.stringify(b))}
  function capture(item,name){const dir=Quickshell.env("MAGI_LOCK_THEME_PREVIEWS");if(dir){wait(20);grabImage(item).save(dir+"/"+name+".png")}}
  function test_themes(){try {
   const wallpaperPath=Quickshell.env("MAGI_LOCK_THEME_WALLPAPER")
   Services.Settings.setLockLayout(Themes.create("split-corners",{effects:{blur:false,credential:"line"}}))
   Services.Wallpaper.state={shared:{path:wallpaperPath},monitors:{},favourites:[],recents:[]}
   check(String(page.wallpaperSource).endsWith("test-artwork.ppm"),"Shared lock wallpaper selected")
   for(const width of [460,760,1120]) {
    win.contentItem.Window.window.width=width;wait(30)
    const gallery=findChild(page,"lockThemeGallery")
    check(gallery.columns>=1&&gallery.columns<=4,"responsive columns")
    for(const t of Themes.catalogue()) {
     page.choose(t.id);wait(30)
     check(findChild(page,"lockThemeCard-"+t.id).selected,"selected theme")
     const mini=findChild(findChild(page,"lockThemeCard-"+t.id),"lockThemeMini")
     check(Math.abs(mini.width/mini.height-16/9)<.01,"Card preview retains widescreen proportions")
     const wallpaper=findChild(mini,"lockPreviewWallpaper")
     tryVerify(()=>wallpaper.status===Image.Ready,2000,"Wallpaper loads: "+wallpaper.source)
     equal(wallpaper.sourceSize.width,960,"Bounded shared wallpaper decode")
     equal(String(wallpaper.source),String(page.wallpaperSource),"Card uses actual shared wallpaper")
     const avatar=findChild(mini,"lockThemeAvatar")
     equal(avatar.radius,t.id==="split-corners" && page.layout.effects.avatar==="frame" ? 4 : page.avatarRadius,"Native avatar rounding")
     check(avatar.radius<avatar.width/2,"Avatar is not an invented circle")
     if(width===1120&&Quickshell.env("MAGI_LOCK_THEME_PREVIEWS")){capture(win.contentItem,"gallery-"+t.id);page.contentY=Math.max(0,page.contentHeight-page.height);capture(win.contentItem,"options-"+t.id);page.contentY=0}
     check(!findChild(page,"lockThemeLivePreview").interactive,"read-only preview")
     equal(String(findChild(findChild(page,"lockThemeLivePreview"),"lockPreviewWallpaper").source),String(page.wallpaperSource),"Large preview wallpaper")
     check(findChild(page,"lockElementInspector")===null,"no designer")
     for(const key of ["avatar","clockSize","date","media","weather","artwork","edgeInset"])
      equal(findChild(page,"lockOption-"+key).visible,Themes.supports(t.id,key))
    }
   }
   const legacy=Model.preset("split");legacy.preset="custom";Services.Settings.setLockLayout(legacy);wait(30);check(page.selection.legacy,"legacy preserved");equal(JSON.stringify(page.saved),JSON.stringify(legacy));capture(win.contentItem,"gallery-legacy")
   const unknown=Model.preset("split");unknown.preset="future-theme";Services.Settings.setLockLayout(unknown);wait(30)
   check(page.selection.unavailable,"Unknown theme disclosed");equal(page.layout.preset,"centered");equal(page.saved.preset,"future-theme")
   const accepted=Themes.create("split-corners",null);accepted.preset="custom";accepted.effects.blur=false;accepted.effects.artwork=true
   Services.Settings.setLockLayout(accepted);wait(30)
   const revision=Services.Settings.revision
   check(page.selection.id==="split-corners","Accepted Custom recognized without selecting")
   wait(30);equal(Services.Settings.revision,revision,"Opening a theme does not write settings")
   page.visible=false
   for(const palette of ["catppuccin-mocha","everforest-dark-hard","kanagawa-wave","one-light"]) {
    Services.Settings.setTheme(palette);wait(50)
    for(const t of Themes.catalogue())for(const size of [[800,600],[1920,1080],[3440,1440],[360,640]])for(const variant of [0,1,2,3]) {
     const extras=variant>0
     let l=Themes.create(t.id,null)
     if(extras)for(const key of ["media","weather"])if(Themes.supports(t.id,key))l=Themes.customize(l,key,true)
     if(variant>=2)l=Themes.customize(l,"clockSize",1.15)
     if(variant===3&&Themes.supports(t.id,"avatar"))l=Themes.customize(l,"avatar",false)
     const scene=sceneFactory.createObject(win.contentItem,{width:size[0],height:size[1],visual:Object.assign({},page.colors,{lockScreen:l,media:{available:true,title:"Morning light",artist:"Sample artist",playing:true,artwork:true},weather:{available:true,temperature:"12°",condition:"Clear"}})})
     wait(5)
     const boxes=scene.elementBoxes,active=Model.ids().filter(id=>boxes[id].visible),label=t.id+" "+size+" variant="+variant
     for(const id of active){const b=boxes[id],p=b.mapToItem(scene,0,0),q=b.mapToItem(scene,b.width,b.height);check(p.x>=0&&p.y>=0&&q.x<=scene.width+.1&&q.y<=scene.height+.1,label+" safe "+id)}
     for(let i=0;i<active.length;i++)for(let j=i+1;j<active.length;j++)check(!Model.overlaps(boxes[active[i]],boxes[active[j]],0),label+" overlap "+active[i]+"/"+active[j])
     const names=["authHost","credentialDots","passwordPrompt","powerActions","authFeedback"]
     const positions=()=>JSON.stringify(names.map(n=>{const i=findChild(scene,n);return i.mapToItem(scene,0,0).y}))
     const before=positions()
     for(const state of ["Touch fingerprint sensor","Fingerprint didn’t match · try again","Fingerprint unavailable","Fingerprint matched"]){scene.fingerprintStatus=state;scene.capsLock=!scene.capsLock;wait(1);equal(positions(),before);check(boxes.authentication.visible,label+" password fallback visible")}
     if(size[0]===1920&&!extras){win.contentItem.Window.window.width=1920;win.contentItem.Window.window.height=1080;capture(scene,palette+"-"+t.id)}
     scene.destroy()
    }
   }
   // Independent simultaneous outputs, with a shared presentation-only snapshot.
   for(const t of Themes.catalogue()) {
    const l=Themes.create(t.id,null),visual={lockScreen:l}
    const a=sceneFactory.createObject(win.contentItem,{width:800,height:600,visual:visual}),b=sceneFactory.createObject(win.contentItem,{width:3440,height:1440,visual:visual});wait(5)
    check(a.elementBoxes.authentication.visible&&b.elementBoxes.authentication.visible,t.id+" synthetic multi-output auth")
    a.destroy();b.destroy()
   }
   for(const size of [[800,600],[1920,1080],[3440,1440],[360,640]]) {
    const old=sceneFactory.createObject(win.contentItem,{width:size[0],height:size[1],visual:{lockScreen:accepted}})
    const recognized=sceneFactory.createObject(win.contentItem,{width:size[0],height:size[1],visual:{lockScreen:Themes.migrate(accepted)}});wait(5)
    for(const id of Model.ids()){const a=old.elementBoxes[id],b=recognized.elementBoxes[id];equal(a.visible,b.visible,"Accepted visibility unchanged: "+id);if(a.visible)equal([a.x,a.y,a.width,a.height,a.scale],[b.x,b.y,b.width,b.height,b.scale],"Accepted layout unchanged: "+id)}
    old.destroy();recognized.destroy()
   }
   console.log("Lock themes product and runtime PASS")
  }catch(e){console.error("FAIL: "+e)}finally{finish.start()}}
 }
}
