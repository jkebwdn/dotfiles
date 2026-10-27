import QtQuick
import QtQuick.Window
import QtQuick.Layouts
import "../../.config/quickshell/magi/icons" as Icons
import "../../.config/quickshell/magi/components/settings/SettingsScroll.js" as Scroll
import QtTest
import Quickshell
import "../../.config/quickshell/magi/theme" as Theme
import "../../.config/quickshell/magi/components/settings" as UI
import "../../.config/quickshell/magi/services" as Services
ShellRoot {
 FloatingWindow {id:win;visible:true;implicitWidth:1080;implicitHeight:780;color:Theme.Theme.background;UI.SettingsContent {anchors.fill:parent}
 Item {id:nestedLayer;anchors.fill:parent;visible:false;z:100
  UI.SettingsPage {id:outer;x:280;y:100;width:400;height:300
   UI.SettingsPage {id:inner;Layout.fillWidth:true;Layout.preferredHeight:120;Rectangle {implicitHeight:600;Layout.fillWidth:true;color:Theme.Theme.surface}}
   Rectangle {implicitHeight:650;Layout.fillWidth:true;color:Theme.Theme.elevated}
  }
 }
}
 Timer {id:finish;interval:100;onTriggered:Qt.quit()}
 TestCase {
  name:"Phase12F";when:Services.Settings.ready
  function item(n){const x=findChild(win.contentItem,n);verify(x!==null,n);return x}
  function page(name){Services.SettingsWindowState.page=name;wait(180);return item("settingsPage-"+({Launcher:"Application Launcher",Emoji:"Emoji Picker"}[name]||name))}
  function checkBarComposition(){
   const p=item("settingsPage-Bar"),canvas=item("barCanvas"),mode=p.mode
   verify(Math.abs(canvas.width-p.body.width)<1,"Bar canvas fills the editor width: "+mode)
   compare(canvas.mapToItem(p.body,0,0).x,0)
   if(mode!=="Layout"){
    const controls=item(mode==="Appearance"?"barAppearanceInspector":"barBehaviourControls")
    verify(controls.mapToItem(p.body,0,0).y>=canvas.mapToItem(p.body,0,canvas.height).y,"Bar controls stay below the preview: "+mode)
    compare(controls.mapToItem(p.body,0,0).x,0)
   }
  }
  function capture(n){
   win.contentItem.opacity=.999;wait(30);win.contentItem.opacity=1;wait(100)
   if(n.startsWith("bar-")||n.startsWith("compact-bar-"))checkBarComposition()
   const requested=(Quickshell.env("MAGI_PHASE12F_CAPTURES") || "").split(",").filter(x=>x.length)
   if(requested.length&&!requested.includes(n))return
   grabImage(win.contentItem).save(Quickshell.env("MAGI_PHASE12F_PREVIEWS")+"/"+n+".png")
  }
  function checkScopes(){
   let p=page("Control Centre");p.mode="Appearance";p.contentY=0;wait(60)
   const family=item("ccFamilyInspector"), revision=Services.Settings.revision, before=JSON.stringify(Services.Settings.data)
   for(const [group,module,captureName] of [["controls","wifi","primary"],["actions","dnd","secondary"],["sliders","volume","sliders"]]){
    const region=item("ccAppearanceRegion-"+group)
    // A broad region target, including blank space, selects the family.
    mouseClick(region,region.width-8,10);wait(40)
    compare(p.selection.scope,"family");compare(p.selection.family,group);verify(!family.collapsible);verify(family.expanded)
    verify(item("ccFamilyHighlight-"+group).visible);compare(item("ccModuleBoard-row-"+module).border.width,0)
    verify(item("ccFamilyShape").visible);capture("cc-family-"+captureName)
    mouseClick(item("ccModuleBoard-row-"+module),12,12);wait(40)
    compare(p.selection.scope,"module");compare(p.selection.instance,module);verify(family.collapsible);verify(!family.expanded)
    verify(!item("ccFamilyShape").visible);verify(!item("ccFamilyHighlight-"+group).visible)
    compare(item("ccModuleBoard-row-"+module).border.width,2)
    compare(item("ccInstanceAccent").visible,group!=="sliders")
    verify(!item("settingsButton-Reset Control Centre appearance").visible)
    capture("cc-item-"+module)
    family.children[1].forceActiveFocus();keyClick(Qt.Key_Space);wait(40)
    verify(family.expanded);verify(item("ccFamilyShape").visible);compare(p.selection.instance,module)
    // Collapsing must clamp a scrolled inspector instead of leaving a blank viewport.
    p.contentY=1000;family.children[1].forceActiveFocus();keyClick(Qt.Key_Space);wait(40)
    verify(!family.expanded);verify(p.contentY<=Math.max(0,p.contentHeight-item("controlCentreEditor").height)+1)
    p.contentY=0
    region.forceActiveFocus();keyClick(Qt.Key_Return);wait(30);compare(p.selection.scope,"family")
    item("ccModuleBoard-row-"+module).forceActiveFocus();keyClick(Qt.Key_Space);wait(30);compare(p.selection.scope,"module");verify(!family.expanded)
   }
   compare(JSON.stringify(Services.Settings.data),before);compare(Services.Settings.revision,revision,"Selection and disclosure must not save")
   // Real instance picker changes only that module; shared style and sibling identity survive.
   for(const [group,module,sibling,role] of [["controls","wifi","bluetooth","red"],["actions","dnd","caffeine","teal"]]){
    p.selection.select(module);wait(30)
    const appearance=JSON.stringify(Services.Settings.data.appearance),other=JSON.stringify(Services.Settings.data.controlCentre[group].find(e=>e.module===sibling))
    const accent=item("ccInstanceAccent"),previous=Services.Settings.data.controlCentre[group].find(e=>e.module===module).accent
    accent.activated(accent.roles.indexOf(role));wait(30)
    compare(Services.Settings.data.controlCentre[group].find(e=>e.module===module).accent,role)
    compare(JSON.stringify(Services.Settings.data.appearance),appearance);compare(JSON.stringify(Services.Settings.data.controlCentre[group].find(e=>e.module===sibling)),other)
    const record=Services.Settings.data.controlCentre[group].find(e=>e.module===module);Services.Settings.editEntry(group,record.key,"accent",previous)
    mouseClick(item("ccAppearanceRegion-"+group),8,8);wait(30)
    const shape=item("ccFamilyShape"),old=shape.value;shape.forceActiveFocus();keyClick(Qt.Key_Right);wait(30);verify(shape.value>old)
    const a=item("ccPreview-"+module).presenter,b=item("ccPreview-"+sibling).presenter
    compare(group==="controls"?a.radius:a.children[0].radius,group==="controls"?b.radius:b.children[0].radius)
    Services.Settings.setRoundness(group==="controls"?"controlTile":"secondaryControl",null)
   }
   for(const singleton of ["profile","media",""]){p.selection.select(singleton);wait(30);verify(!family.collapsible);verify(family.expanded)}
   p.selection.select("wifi");Services.Settings.placeCCModule("wifi","available");wait(30);compare(p.selection.instance,"")
   Services.Settings.resetSection("controlCentre");wait(60)
   for(const entry of Services.Settings.data.controlCentre.controls.slice())Services.Settings.placeCCModule(entry.module,"available")
   wait(50);const empty=item("ccAppearanceRegion-controls");verify(empty.visible);mouseClick(empty,8,8);compare(p.selection.scope,"family")
   Services.Settings.resetSection("controlCentre");wait(60)
   p=page("Bar");p.mode="Appearance";wait(60)
   const barFamily=item("barFamilyInspector"),barBefore=JSON.stringify(Services.Settings.data),barRevision=Services.Settings.revision
   mouseClick(item("barFamilyTarget-statusPills"));wait(40);compare(p.selection.scope,"family");verify(barFamily.expanded);verify(!barFamily.collapsible)
   for(const id of ["wifi","bluetooth"]){verify(item("barOrder-row-"+id).familyHighlighted);compare(item("barOrder-row-"+id).border.width,1)}
   verify(!item("barOrder-row-workspaces").familyHighlighted);capture("bar-family-status")
   item("barOrder-row-wifi").forceActiveFocus(Qt.TabFocusReason);compare(item("barOrder-row-wifi").border.width,2);compare(p.selection.scope,"family")
   keyClick(Qt.Key_Space);wait(30);compare(p.selection.instance,"wifi");verify(!barFamily.expanded)
   for(const id of ["wifi","bluetooth"]){
    mouseClick(item("barOrder-row-"+id),10,10);wait(40);compare(p.selection.scope,"module");verify(!barFamily.expanded)
    verify(!item("visualSetting-statusIconSize").visible);verify(item("barInstanceAccent").visible)
    compare(item("barOrder-row-"+id).border.width,2);verify(!item("barOrder-row-"+id).familyHighlighted)
    capture("bar-item-"+id)
    barFamily.children[1].forceActiveFocus();keyClick(Qt.Key_Space);wait(30);verify(item("visualSetting-statusIconSize").visible)
   }
   item("barFamilyTarget-workspaces").forceActiveFocus();keyClick(Qt.Key_Space);wait(40)
   compare(p.selection.scope,"family");compare(p.selection.family,"workspacePills");verify(barFamily.expanded);verify(!item("barIdentityInspector").visible)
   mouseClick(item("barOrder-row-workspaces"),10,10);compare(p.selection.scope,"family")
   verify(item("barOrder-row-workspaces").familyHighlighted);capture("bar-family-workspace")
   compare(JSON.stringify(Services.Settings.data),barBefore);compare(Services.Settings.revision,barRevision)
   p.selection.select("wifi");wait(30)
   const visual=JSON.stringify(Services.Settings.data.bar.visual),bt=JSON.stringify(Services.Settings.data.bar.modules.bluetooth),accent=item("barInstanceAccent")
   accent.currentIndex=accent.model.indexOf("red");accent.activated(accent.currentIndex);wait(30)
   compare(Services.Settings.data.bar.modules.wifi.accentRole,"red");compare(JSON.stringify(Services.Settings.data.bar.visual),visual);compare(JSON.stringify(Services.Settings.data.bar.modules.bluetooth),bt)
   mouseClick(item("barFamilyTarget-statusPills"));wait(30)
   const size=item("visualSetting-statusIconSize"),oldSize=size.value;size.forceActiveFocus();keyClick(Qt.Key_Up);wait(30);verify(size.value>oldSize)
   compare(item("barPreview-wifi").presenter.radius,item("barPreview-bluetooth").presenter.radius)
   for(const id of ["wifi","bluetooth"]){
    const content=item("barPreview-"+id).presenter.children.find(c=>c.moduleId===id)
    verify(content!==undefined);const icon=content.children.find(c=>c.size!==undefined);compare(icon.size,size.value)
   }
   compare(p.selection.scope,"family","Family survives shared-style updates")
   p.selection.select("wifi");Services.Settings.placeBar("wifi","hidden");wait(30);compare(p.selection.instance,"")
   Services.Settings.resetSection("bar");Services.Settings.setVisual("statusIconSize",oldSize)
   p=page("Control Centre");p.contentY=0
  }
  function test_refinement(){try{
   const initial=JSON.stringify(Services.Settings.data)
   for(const name of ["Appearance","Bar","Control Centre","Hub","Profile","Date & time","Notifications","Clipboard","Launcher","Emoji","Wallpaper","Power & Idle","Displays","Security"]){
    const p=page(name);capture(name.toLowerCase().replace(/[^a-z]+/g,"-"));compare(JSON.stringify(Services.Settings.data),initial,"Opening a page must not edit settings")
    verify(p.width>300);verify(p.height>500)
    if (p.title !== undefined) { const title=p.body.children[0].mapToItem(win.contentItem,0,0);compare(title.x,250);compare(title.y,24) }
   }
   let p=page("Appearance"),advanced=item("advancedShellStyling")
   const themes=item("themeGallery"),packs=item("iconPackGallery")
   compare(themes.count,18);tryVerify(()=>packs.count>=2)
   for(let i=0;i<themes.count;++i){
    const card=themes.itemAt(i),definition=Theme.ThemeRegistry.themes[i]
    compare(card.text,definition.label);compare(card.modelData.roles,definition.roles)
    themes.reveal(i);wait(20);mouseClick(card);compare(Services.Settings.data.appearance.theme,definition.id);verify(card.selected)
    verify(card.x>=themes.contentX-.1&&card.x+card.width<=themes.contentX+themes.width+.1)
   }
   themes.focusIndex(0);keyClick(Qt.Key_Right);verify(themes.itemAt(1).activeFocus);keyClick(Qt.Key_Return)
   compare(Services.Settings.data.appearance.theme,Theme.ThemeRegistry.ids[1])
   Services.Settings.setTheme("catppuccin-mocha");wait(40);capture("appearance-theme-gallery")
   const appIcons=JSON.stringify(Services.LauncherIcons.resolve({name:"Sample",icon:""})),originalPack=Services.Settings.data.icons.pack
   for(let i=0;i<packs.count;++i){packs.reveal(i);wait(20);mouseClick(packs.itemAt(i));compare(Services.Settings.data.icons.pack,packs.model[i].id);verify(packs.itemAt(i).selected)}
   packs.focusIndex(0);keyClick(Qt.Key_Right);keyClick(Qt.Key_Return);compare(Services.Settings.data.icons.pack,packs.model[1].id)
   compare(JSON.stringify(Services.LauncherIcons.resolve({name:"Sample",icon:""})),appIcons)
   // Preview resolution uses the same fallback authority without changing selection.
   compare(Icons.IconRegistry.resolvePack("wifi","not-installed").sourcePack,"magi-default")
   const inventory=Icons.IconRegistry.packs,base=inventory.find(pack=>pack.id==="magi-default")
   Icons.IconRegistry.packs=inventory.concat([Object.assign({},base,{id:"preview-incomplete",label:"Incomplete preview",roles:{wifi:base.roles.wifi}})])
   compare(Icons.IconRegistry.resolvePack("wifi","preview-incomplete").sourcePack,"preview-incomplete")
   compare(Icons.IconRegistry.resolvePack("volume","preview-incomplete").sourcePack,"magi-default")
   Icons.IconRegistry.packs=inventory
   Services.Settings.setIconPack(originalPack);wait(20);capture("appearance-icon-gallery")
   const roles=JSON.stringify(Services.Settings.data.appearance.roundness.roles)
   for(let i=0;i<3;++i){mouseClick(item("roundnessChoice-"+i));compare(Services.Settings.data.appearance.roundness.master,i)}
   compare(JSON.stringify(Services.Settings.data.appearance.roundness.roles),roles)
   Services.Settings.setRoundness("master",.85);item("roundnessFineTune").expanded=true;wait(20)
   const fine=item("masterRoundnessPrecision");verify(fine.visible);fine.forceActiveFocus();keyClick(Qt.Key_Right);verify(Services.Settings.data.appearance.roundness.master>.85)
   capture("roundness-fine-tune");Services.Settings.setRoundness("master",1);item("roundnessFineTune").expanded=false
   // Immediate fractional, normal and continuous wheel input; no waiting for animation.
   win.contentItem.Window.window.height=560;wait(80);p.contentY=0
   mouseWheel(p,10,200,0,-1);verify(p.contentY>0&&p.contentY<2)
   p.contentY=0;mouseWheel(p,10,200,0,-120);compare(p.contentY,48)
   for(let i=0;i<12;++i)mouseWheel(p,10,200,0,-120)
   verify(p.contentY<=p.contentHeight-p.height+.1)
   p.contentY=0;themes.contentX=0
   mouseWheel(themes,80,40,0,-120);compare(themes.contentX,0);compare(p.contentY,48)
   p.contentY=0;mouseWheel(themes,80,40,0,-120,Qt.NoButton,Qt.ShiftModifier);compare(themes.contentX,48);compare(p.contentY,0)
   mouseWheel(themes,80,40,-120,0);verify(themes.contentX>48);compare(p.contentY,0)
   const nav=item("settingsNavigation");nav.contentItem.contentY=0;mouseWheel(nav,20,50,0,-120);verify(nav.contentItem.contentY>0&&nav.contentItem.contentY<=48);nav.contentItem.contentY=0
   nestedLayer.visible=true;wait(40);inner.contentY=0;outer.contentY=0
   mouseWheel(inner,30,50,0,-120);compare(inner.contentY,48);compare(outer.contentY,0)
   inner.contentY=inner.contentHeight-inner.height
   mouseWheel(inner,30,50,0,-120);compare(outer.contentY,48)
   nestedLayer.visible=false
   // Pixel deltas retain fractional precision; physical touchpad phases need native review.
   compare(Scroll.delta(.25,120),.25);compare(Scroll.delta(0,120),48)
   win.contentItem.Window.window.height=780;p.contentY=0;themes.reveal(themes.currentIndex);wait(60)

   verify(!advanced.expanded);advanced.expanded=true;wait(30);verify(advanced.expanded);advanced.expanded=false
   p=page("Profile");verify(!item("weatherLocation").visible)
   // Disclosing weather must retain the existing input and explicit save action.
   mouseClick(item("settingsToggle-Enable weather"));wait(30);verify(item("weatherLocation").visible)
   mouseClick(item("settingsToggle-Enable weather"));verify(!item("weatherLocation").visible)
   const avatarButton=item("settingsButton-Choose avatar…")
   verify(!avatarButton.flat);verify(avatarButton.background.visible);avatarButton.forceActiveFocus();verify(avatarButton.activeFocus)
   compare(avatarButton.leftPadding,UI.SettingsMetrics.fieldPadding)
   const profileReset=item("settingsButton-Reset profile"),profileLink=item("settingsButton-Open Control Centre")
   compare(profileReset.actionKind,"reset");verify(profileReset.utility);verify(!profileReset.flat)
   compare(profileLink.actionKind,"navigation");verify(!profileLink.flat)
   profileReset.forceActiveFocus();verify(profileReset.activeFocus)
   profileReset.down=true;compare(profileReset.background.color,Theme.Theme.overlay);compare(profileReset.contentItem.color,Theme.Theme.text);profileReset.down=false
   p=page("Emoji");const clearRecent=item("settingsButton-Clear Recently Used")
   verify(clearRecent.destructive);compare(clearRecent.contentItem.color,Theme.Theme.red)
   clearRecent.down=true;compare(clearRecent.contentItem.color,Theme.Theme.accentText);clearRecent.down=false
   p=page("Clipboard");const privacy=item("clipboardHistoryPrivacy"),unchanged=JSON.stringify(Services.Settings.data)
   verify(!privacy.expanded);privacy.children[1].forceActiveFocus();keyClick(Qt.Key_Space);verify(privacy.expanded)
   compare(JSON.stringify(Services.Settings.data),unchanged,"Privacy disclosure is presentation-only");p.contentY=0;capture("clipboard-history-details")
   privacy.expanded=false;p.contentY=0;item("clipboardAppearance").expanded=true;wait(30);verify(item("settingsToggle-Clipboard card borders").visible);capture("clipboard-appearance")
   p=page("Control Centre");const preview=item("controlCentrePreview")
   verify(preview.moduleBoard.visible&&preview.structureBoard.visible,"One Layout supports both drag operations")
   verify(!findChild(win.contentItem,"expandControlCentrePreview"))
   const handle=item("ccModuleBoard-handle-wifi"),row=item("ccModuleBoard-row-wifi")
   compare(handle.text,"");compare(handle.width,row.width);compare(handle.height,row.height)
   // The item itself receives the drag, not a small persistent grip.
   const target=preview.moduleBoard.geometry.find(l=>l.id==="actions"),before=JSON.stringify(Services.Settings.data.controlCentre)
   mousePress(handle,handle.width/2,handle.height/2,Qt.LeftButton)
   mouseMove(preview.moduleBoard,target.x+20,target.y+35,40);verify(preview.moduleBoard.dragging)
   compare(JSON.stringify(Services.Settings.data.controlCentre),before)
   handle.forceActiveFocus();keyClick(Qt.Key_Escape);verify(!preview.moduleBoard.dragging)
   mouseRelease(preview.moduleBoard,target.x+20,target.y+35,Qt.LeftButton);compare(JSON.stringify(Services.Settings.data.controlCentre),before)
   handle.forceActiveFocus();keyClick(Qt.Key_Right,Qt.AltModifier);wait(100)
   verify(Services.Settings.data.controlCentre.actions.some(e=>e.module==="wifi"&&e.enabled))
   const moved=item("ccModuleBoard-handle-wifi")
   moved.forceActiveFocus();keyClick(Qt.Key_F10,Qt.ShiftModifier);wait(80)
   const menu=moved.contextMenu;verify(menu.visible)
   mouseClick(findChild(menu.contentItem,"ccModuleBoard-move-wifi-available"));wait(80)
   verify(preview.moduleBoard.canonicalKeys("available").includes("wifi"))
   Services.Settings.resetSection("controlCentre");wait(100)
   checkScopes();p=page("Control Centre")
   for(const [id,section,key] of [["wifi","ccPrimaryFineTune","primaryIconSize"],["dnd","ccSecondaryFineTune","secondaryIconSize"],["profile","ccProfileFineTune","avatarSize"],["media","ccMediaFineTune","mediaArtworkSize"]]){
    p.mode="Appearance";p.selection.select(id);p.contentY=0;wait(50)
    if(item("ccFamilyInspector").collapsible){item("ccFamilyInspector").expanded=true;wait(30)}
    const disclosure=item(section),precision=item("visualSetting-"+key),saved=JSON.stringify(Services.Settings.data)
    verify(!disclosure.expanded);verify(!precision.visible)
    // Focus-only access opens the real disclosure; exact tuning is retained.
    disclosure.children[1].forceActiveFocus();keyClick(Qt.Key_Space);wait(30)
    verify(disclosure.expanded);verify(precision.visible);compare(JSON.stringify(Services.Settings.data),saved)
    disclosure.expanded=false
   }
   for(const id of ["wifi","profile","volume","media",""]){p.mode="Appearance";p.selection.select(id);p.contentY=0;capture("cc-"+(id||"host"))}
   p.selection.select("wifi");wait(30);item("ccFamilyInspector").expanded=true;item("ccPrimaryFineTune").expanded=true;p.contentY=200;capture("cc-fine-tune");item("ccPrimaryFineTune").expanded=false;item("ccFamilyInspector").expanded=false;p.contentY=0
   p=page("Bar")
   for(const mode of ["Layout","Appearance","Behaviour"]){p.mode=mode;if(mode==="Appearance")p.selection.select("wifi");wait(50);capture("bar-"+mode.toLowerCase())}
   p=page("Hub");const hub=item("hubEditorPreview")
   const hubValues=JSON.stringify(Services.Settings.data)
   for(let i=0;i<5;++i){mouseClick(hub.selector.modeButtons.itemAt(i));compare(p.selection.scope,"family");compare(p.selection.instance,"selector")}
   mouseClick(item("settingsToggle-Sample enabled preference"));compare(p.selection.scope,"family");compare(p.selection.instance,"toggles")
   compare(JSON.stringify(Services.Settings.data),hubValues)
   p.mode="Appearance";p.selection.select("toggles");hub.mode="settings";wait(40)
   for(const style of ["pill","filled","minimal"]){mouseClick(item("switchStyleChoice-"+style));compare(Services.Settings.data.appearance.toggleStyle,style);compare(item("settingsToggle-Sample enabled preference").toggleStyle,style)}
   capture("switch-style-picker");p.mode="Layout";wait(30);compare(item("hubEditorInspector").title,"");capture("hub-layout")

   for(const mode of ["apps","clipboard","notifications","emoji","settings"]){hub.mode=mode;wait(30);capture("hub-"+mode)}
   for(const key of ["","selector","toggles"]){p.mode="Appearance";p.selection.select(key);hub.mode=key==="toggles"?"settings":"apps";capture("hub-"+(key||"host"))}
   win.contentItem.Window.window.width=720;win.contentItem.Window.window.height=650
   for(const name of ["Appearance","Control Centre","Hub","Profile"]){p=page(name);if(["Control Centre","Hub"].includes(name)){p.mode="Appearance";p.selection.select(name==="Control Centre"?"wifi":"selector");p.contentY=0}capture("compact-"+name.toLowerCase().replace(/ /g,"-"))}
   p=page("Control Centre");p.mode="Appearance";p.selection.select("controls");wait(40)
   verify(item("ccFamilyHighlight-controls").visible);verify(item("ccFamilyInspector").expanded);capture("compact-cc-family-primary")
   p=page("Bar");p.contentY=0
   const compactBefore=JSON.stringify(Services.Settings.data)
   for(const mode of ["Layout","Appearance","Behaviour"]){p.mode=mode;wait(40);checkBarComposition()}
   compare(JSON.stringify(Services.Settings.data),compactBefore)
   p.mode="Appearance";wait(40)
   mouseClick(item("barFamilyTarget-statusPills"));wait(40);verify(item("barOrder-row-wifi").familyHighlighted);capture("compact-bar-family-status")
   mouseClick(item("barOrder-row-wifi"),10,10);wait(40);verify(!item("barFamilyInspector").expanded);compare(item("barOrder-row-wifi").border.width,2);capture("compact-bar-item-wifi")
   win.contentItem.Window.window.width=1400;win.contentItem.Window.window.height=900
   p=page("Control Centre");p.mode="Layout";capture("large-control-centre")
   win.contentItem.Window.window.width=1080;win.contentItem.Window.window.height=780
   p=page("Appearance")
   for(const theme of ["catppuccin-mocha","everforest-dark-hard","rose-pine","nord","tokyo-night-moon","rose-pine-dawn"]){Services.Settings.setTheme(theme);wait(50);capture("palette-"+theme)}
   Services.Settings.setTheme("rose-pine-dawn")
   for(const name of ["Appearance","Control Centre","Hub","Profile","Notifications"]){p=page(name);if(["Control Centre","Hub"].includes(name)){p.mode="Appearance";p.selection.select(name==="Control Centre"?"wifi":"selector");p.contentY=0}capture("light-"+name.toLowerCase().replace(/ /g,"-"))}
   tryCompare(Services.Settings,"saveState","saved");wait(150)
   const saved=JSON.stringify(Services.Settings.data)
   Services.Settings.setTheme("nord");verify(Services.Settings.discardAndReload());tryCompare(Services.Settings,"ready",true)
   compare(JSON.stringify(Services.Settings.data),saved)
   compare(Services.Settings.data.schemaVersion,22)
   console.log("Phase12F presentation PASS")
  }catch(e){console.error("FAIL",e,e.stack)}finally{finish.start()}}
 }
}
