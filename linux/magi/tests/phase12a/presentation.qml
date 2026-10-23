import QtQuick
import QtQuick.Window
import QtTest
import Quickshell
import "../../.config/quickshell/magi/theme" as Theme
import "../../.config/quickshell/magi/components/settings" as UI
import "../../.config/quickshell/magi/services" as Services
ShellRoot {
 FloatingWindow {id:win;visible:true;implicitWidth:1400;implicitHeight:900;color:Theme.Theme.background;UI.SettingsContent {anchors.fill:parent}}
 Timer {id:finish;interval:100;onTriggered:Qt.quit()}
 TestCase {
  name:"Phase12A"
  when:Services.Settings.ready
  function capture(name,item){wait(150);grabImage(item||win.contentItem).save(Quickshell.env("MAGI_PHASE12A_PREVIEWS")+"/"+name+".png")}
  function item(name){const o=findChild(win.contentItem,name);verify(o!==null,name);return o}
  function order(group){return Services.Settings.data.controlCentre[group].filter(e=>e.enabled).map(e=>e.key)}
  function reveal(editor,target){editor.contentY=Math.max(0,target.mapToItem(editor.contentItem,0,0).y-30);wait(40)}
  function test_configurator() {
   try {
    Services.SettingsWindowState.page="Control Centre";wait(250)
    const page=item("settingsPage-Control Centre"), preview=item("controlCentrePreview"), editor=item("controlCentreEditor")
    page.mode="Appearance";wait(80)
    verify(preview.width>=300);verify(editor.width>=400)
    for(const columns of [1,2,4]){
      Services.Settings.setValue("controlCentre","columns",columns);wait(20)
      compare(preview.columns("controls"),columns)
      verify(preview.sectionHeight("controls")>=Theme.RenderTokens.tileSize)
    }
    capture("overall");capture("default",preview)
    compare(UI.SettingsMetrics.navigationIconSize,22)
    const avatar=item("runtimeAvatar"),profile=item("previewProfile"),art=item("runtimeAlbumArt")
    for(const [key,value] of [["avatarSize",96],["avatarBorderWidth",3],["profileGreetingSize",21],["profileWeatherSize",16],["profileThirdLineSize",15],["profileGreetingWeight",700],["profileWeatherWeight",400],["profileThirdLineWeight",700]]) Services.Settings.setVisual(key,value)
    Services.Settings.setValue("appearance","profileBackground",{enabled:true,role:"blue"});wait(40)
    compare(avatar.width,96);compare(avatar.borderWidth,3);compare(profile.color,Theme.Theme.roles.blue)
    for(const [name,size,weight] of [["profileGreeting",21,700],["profileWeather",16,400],["profileThirdLine",15,700]]){compare(item(name).font.pixelSize,size);compare(item(name).font.weight,weight)}
    page.selection.select("profile");capture("profile")
    Services.Settings.setValue("appearance","profileBackground",{enabled:false,role:"blue"});compare(profile.color,"#00000000")
    for(const [key,value] of [["mediaArtworkSize",96],["mediaProgressBorderWidth",4],["mediaTitleSize",20],["mediaArtistSize",16],["mediaTitleWeight",700],["mediaArtistWeight",400]]) Services.Settings.setVisual(key,value)
    Services.Settings.setValue("appearance","mediaProgressRole","teal");wait(40)
    compare(art.width,96);compare(art.borderWidth,4);compare(art.progressColor,Theme.Theme.mediaProgressColor)
    compare(item("mediaTitle").font.pixelSize,20);compare(item("mediaTitle").font.weight,700)
    compare(item("mediaArtist").font.pixelSize,16);compare(item("mediaArtist").font.weight,400)
    const playback=item("mediaPlaybackControls")
    preview.playing=false;Services.Settings.setValue("media","controlsVisibility","always");verify(playback.visible)
    Services.Settings.setValue("media","controlsVisibility","playing");verify(!playback.visible)
    preview.playing=true;verify(playback.visible)
    preview.playing=false;Services.Settings.setValue("media","controlsVisibility","active");verify(playback.visible)
    Services.Settings.setValue("media","controlsVisibility","hidden");verify(!playback.visible)
    Services.Settings.setValue("media","controlsVisibility","always");preview.playing=true
    page.selection.select("media");reveal(editor,item("mediaPlayerSettings"));capture("media")
    // Every renderer is inert, including programmatic media activation.
    verify(!item("previewMedia").interactive);verify(!item("mediaToggle").enabled)
    item("mediaToggle").triggered();compare(preview.playing,true)
    // Composition pointer/race coverage moved to phase12d; retained presenters remain under test here.
    capture("reorder",preview)
    tryCompare(Services.Settings,"saveState","saved")
    wait(100)
    const saved=Services.Settings.data.appearance.visual.avatarSize
    Services.Settings.setVisual("avatarSize",80);wait(20);compare(avatar.width,80)
    Services.Settings.discardAndReload();verify(!Services.Settings.ready);tryCompare(Services.Settings,"ready",true);wait(20);compare(avatar.width,saved)
    Services.Settings.setVisual("avatarSize",88);wait(20);compare(avatar.width,88);tryCompare(Services.Settings,"saveState","saved");wait(100)
    Services.Settings.discardAndReload();verify(!Services.Settings.ready);tryCompare(Services.Settings,"ready",true);wait(20);compare(avatar.width,88)
    Services.Settings.setValue("appearance","hubSelectionRole","red")
    Services.Settings.setValue("appearance","hubToggleRole","green")
    Services.Settings.setValue("appearance","navigationAccent","blue")
    compare(Theme.Theme.hubSelectionColor,Theme.Theme.primaryAccent("red","accent"))
    const toggle=Theme.Theme.hubToggleColor,nav=Theme.Theme.navigationAccent
    Services.Settings.setValue("appearance","hubSelectionRole","teal");compare(Theme.Theme.hubToggleColor,toggle);compare(Theme.Theme.navigationAccent,nav)
    const selected=Theme.Theme.hubSelectionColor
    Services.Settings.setValue("appearance","hubToggleRole","yellow");compare(Theme.Theme.hubSelectionColor,selected);compare(Theme.Theme.navigationAccent,nav)
    Services.SettingsWindowState.page="Hub";wait(50);capture("hub")
    const hubReset=item("settingsButton-Reset Hub appearance")
    mouseClick(hubReset);compare(Services.Settings.data.appearance.hubSelectionRole,"accent")
    compare(Services.Settings.data.appearance.hubToggleRole,"accent");compare(Services.Settings.data.appearance.navigationAccent,"blue")
    Services.Settings.setValue("appearance","hubSelectionRole","teal")
    Services.SettingsWindowState.page="Control Centre";editor.contentY=0
    for(const [theme,name] of [["catppuccin-frappe","frappe"],["everforest-dark-hard","everforest"]]){Services.Settings.setTheme(theme);wait(80);compare(Theme.Theme.hubSelectionColor,Theme.Theme.primaryAccent("teal","accent"));capture(name)}
    for(const size of [Qt.size(940,720),Qt.size(720,500),Qt.size(1400,900)]){
      win.contentItem.Window.window.width=size.width;win.contentItem.Window.window.height=size.height;wait(150)
      verify(preview.width>150,"preview width "+preview.width);verify(preview.composition.height*preview.fitScale<=preview.height+1,"full-height fitted preview");verify(preview.height>=130,"preview height "+preview.height);verify(editor.height>=100,"inspector height "+editor.height)
      verify(preview.mapToItem(page,0,0).x>=0);verify(preview.mapToItem(page,preview.width,0).x<=page.width)
      if(size.width===720){
        capture("compact")
        verify(editor.visible);verify(preview.visible)
        verify(preview.composition.height*preview.fitScale<=preview.height+1)
      }
    }
    page.resetAppearance();wait(40)
    compare(avatar.width,76);compare(art.width,80)
    tryCompare(Services.Settings,"saveState","saved")
    console.log("Phase12A presentation PASS")
   } catch(e) {console.error("FAIL",e,e.stack)}
   finish.start()
  }
 }
}
