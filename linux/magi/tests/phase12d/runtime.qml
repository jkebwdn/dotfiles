import QtQuick
import QtTest
import Quickshell
import "../../.config/quickshell/magi/components/bar" as BarUI
import "../../.config/quickshell/magi/services" as Services
import "../../.config/quickshell/magi/theme" as Theme
ShellRoot {
 BarUI.Bar {id:bar;expandableHostMode:"combined"}
 Timer {id:finish;interval:100;onTriggered:Qt.quit()}
 TestCase {
  name:"CompositionRuntime";when:Services.Settings.ready
  function test_composition(){try{
   Services.Settings.setValue("profile","displayName","Alex")
   Services.MenuController.open("controlcentre")
   const cc=bar.expandablePillRegistry.controlcentre
   tryCompare(cc,"phase",3)
   const ids=["profile","controls","sliders","actions","media"]
   for(const order of [ids,["media","actions","sliders","controls","profile"],["sliders","profile","media","controls","actions"]]){
    Services.Settings.setValue("controlCentre","layout",order);wait(80)
    let end=0
    for(const id of order){const i=ids.indexOf(id);verify(cc.sectionLayout.positions[i]>=end);end=cc.sectionLayout.positions[i]}
    verify(cc.naturalHeight>0)
   }
   for(const group of ["controls","actions","sliders"]){
    const entries=Services.Settings.data.controlCentre[group].slice()
    for(const entry of entries)Services.Settings.placeCCModule(entry.module,"available")
    wait(20);verify(!cc[({controls:"showControls",actions:"showActions",sliders:"showSliders"})[group]])
    for(const entry of entries.filter(e=>e.enabled))Services.Settings.placeCCModule(entry.module,group)
   }
   for(const id of ["profile","media","sliders"]){Services.Settings.placeCCSection(id,-1);wait(10);verify(!cc[({profile:"showProfile",media:"showMedia",sliders:"showSliders"})[id]]);Services.Settings.placeCCSection(id,0)}
   for(let columns=1;columns<=16;columns++){Services.Settings.setValue("controlCentre","columns",columns);Services.Settings.setValue("controlCentre","actionColumns",columns);wait(10);verify(cc.columns>=1&&cc.columns<=columns);verify(cc.actionColumns>=1&&cc.actionColumns<=columns)}
   Services.Settings.placeCCModule("wifi","actions",0);wait(20);verify(cc.actions.some(e=>e.module==="wifi"));verify(!cc.controls.some(e=>e.module==="wifi"))
   Services.Settings.placeCCModule("wifi","controls",0);wait(20);verify(cc.controls.some(e=>e.module==="wifi"));verify(!cc.actions.some(e=>e.module==="wifi"))
   Services.Settings.setValue("appearance","controlCentreBackgroundRole","elevated");compare(cc.viewSurfaceColor,Theme.Theme.elevated)
   Services.MenuController.close();tryCompare(cc,"phase",0)
   console.log("Phase12D runtime composition PASS")
  }catch(e){console.error("FAIL:",e,e.stack)}finally{finish.start()}}
 }
}
