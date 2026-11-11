import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Window
import QtTest
import Quickshell
import Quickshell.Io
import "../../.config/quickshell/magi/components/settings" as UI
import "../../.config/quickshell/magi/services" as Services
import "../../.config/quickshell/magi/theme" as Theme
ShellRoot {
    UI.SettingsWindow { id: window }
    FileView { id: saved; path: Services.Settings.path; blockLoading: true; blockWrites: true }
    Timer { id: finish; interval: 100; onTriggered: Qt.quit() }
    TestCase {
        name: "ControlCentreHierarchy"
        when: Services.Settings.ready
        function item(name) { const found=findChild(window.contentItem,name);verify(found!==null,name);return found }
        function reveal(control,page) {
            wait(80) // Settle selection/disclosure layout before measuring the target.
            const scroll=page.inspectorViewport
            scroll.contentY=Math.max(0,Math.min(scroll.contentHeight-scroll.height,control.mapToItem(scroll.contentItem,0,0).y-12));wait(120)
        }
        function capture(name) { const dir=Quickshell.env("MAGI_CC_WORKFLOW_CAPTURES");if(dir){if(!name.includes("-help-")){item("ccResetComposition").forceActiveFocus();mouseMove(item("ccPageTitle"),2,2)}wait(120);grabImage(window.contentItem).save(dir+"/"+name+".png")} }
        function test_hierarchy(){try {
            const original=JSON.parse(JSON.stringify(Services.Settings.data)),raw=saved.text(),revision=Services.Settings.revision
            Services.SettingsWindowState.shown=true;Services.SettingsWindowState.page="Control Centre";wait(250)
            const p=item("settingsPage-Control Centre"),preview=item("controlCentrePreview")
            verify(findChild(window.contentItem,"ccGlobalControls")===null)
            verify(findChild(window.contentItem,"roundness-action")===null)
            const colours=item("ccColours"),status=item("ccStatusItems"),border=item("ccBorder"),background=item("ccBackground")
            verify(colours.carded);verify(status.carded)
            compare(colours.title,"Colours");compare(status.title,"Status Items")
            verify(background.visible);verify(border.visible)
            border.disclosureButton.forceActiveFocus();keyClick(Qt.Key_Space);verify(border.expanded)
            keyClick(Qt.Key_Space);verify(!border.expanded);verify(border.visible)
            for(const role of ["controlTile","secondaryControl","slider","albumArt","avatar"]){
                const value=item("roundnessValue-"+role)
                verify(value.infoText.length>0);compare(value.description,"")
                const slider=item("roundness-"+role);compare(slider.from,0);compare(slider.to,2);compare(slider.stepSize,.05)
            }
            compare(item("roundnessValue-controlTile").label,"Primary Controls")
            for(const name of ["controls","artwork"]){
                const h=item("ccRoundness-"+name);h.expanded=true;wait(20);h.disclosureButton.forceActiveFocus();keyClick(Qt.Key_Space);verify(!h.expanded);verify(h.visible);h.expanded=true
            }
            compare(JSON.stringify(Services.Settings.data),JSON.stringify(original));compare(Services.Settings.revision,revision)
            saved.reload();compare(saved.text(),raw)
            for(const theme of ["nord","one-light"]){
                Services.Settings.setTheme(theme);tryCompare(Services.Settings,"saveState","saved",10000)
                for(const size of [[720,600],[1000,760],[1400,900]]){
                    window.contentItem.Window.window.width=size[0];window.contentItem.Window.window.height=size[1];wait(160)
                    const current=JSON.stringify(Services.Settings.data),rev=Services.Settings.revision
                    saved.reload();wait(80);const bytes=saved.text();const fixed=preview.mapToItem(p,0,0),scale=preview.fitScale
                    compare(preview.mapToItem(p,preview.panelX,0).x,item("ccPageTitle").x)
                    for(const key of ["","controls","wifi"]){
                        p.selection.select(key);wait(100)
                        compare(item("ccSelectedInspector").visible,!!key)
                        let bottom=-1
                        for(const name of ["ccAvailableControls","ccSelectedInspector","ccColours","ccStatusItems","ccRoundness","decorationSettings"]){
                            const card=item(name);if(!card.visible)continue
                            verify(card.y>=bottom,name+" order");bottom=card.y+card.height
                        }
                        capture(theme+"-"+size[0]+"-"+(key||"none"))
                    }
                    p.selection.select("")
                    for(const name of ["ccColours","ccBorder","ccStatusItems","ccRoundness","decorationSettings"]){
                        item(name).expanded=true;reveal(item(name),p);capture(theme+"-"+size[0]+"-"+name)
                        compare(preview.mapToItem(p,0,0),fixed);compare(preview.fitScale,scale)
                    }
                    for(const name of ["Status Items","Primary Controls"]){
                        const info=item("settingsInfo-"+name);reveal(info,p);wait(80)
                        verify(info.visible);compare(info.Accessible.name,name+" information");verify(info.Accessible.description.length>10)
                        // Hover does not take focus or move/reflow the inspector.
                        item("ccResetComposition").forceActiveFocus();const y=p.inspectorViewport.contentY,contentHeight=p.inspectorViewport.contentHeight
                        mouseMove(info,info.width/2,info.height/2);tryCompare(info.helpPopup,"visible",true)
                        verify(!info.helpPopup.modal);compare(info.helpPopup.popupType,Popup.Item)
                        compare(p.inspectorViewport.contentY,y);compare(p.inspectorViewport.contentHeight,contentHeight)
                        verify(info.helpPopup.width<=320);capture(theme+"-"+size[0]+"-help-"+name.replace(/ /g,"-"))
                        mouseMove(item("ccResetComposition"),2,2);tryCompare(info.helpPopup,"visible",false)
                        info.forceActiveFocus(Qt.TabFocusReason);tryCompare(info.helpPopup,"visible",true)
                        keyClick(Qt.Key_Escape);tryCompare(info.helpPopup,"visible",false)
                        keyClick(Qt.Key_Space);tryCompare(info.helpPopup,"visible",true)
                        keyClick(Qt.Key_Tab);tryCompare(info.helpPopup,"visible",false)
                        mouseClick(info,info.width/2,info.height/2);tryCompare(info.helpPopup,"visible",true)
                        keyClick(Qt.Key_Escape);tryCompare(info.helpPopup,"visible",false)
                        mouseMove(item("ccResetComposition"),2,2);wait(100)
                        verify(!info.helpPopup.visible,"Leaving a dismissed, still-focused icon must not reopen help")
                    }
                    compare(JSON.stringify(Services.Settings.data),current);compare(Services.Settings.revision,rev)
                    saved.reload();wait(80);compare(saved.text(),bytes,"Help, disclosures and selection never write Settings")
                }
            }
            // Original writers and exact fields stay reachable in their new owners.
            const oldSurface=Services.Settings.data.appearance.controlCentreBackgroundRole
            item("ccBackgroundColour").roleSelected("overlay");compare(Services.Settings.data.appearance.controlCentreBackgroundRole,"overlay");compare(preview.color,Theme.Theme.roles.overlay)
            item("ccStatusRowColour").roleSelected("red");compare(Services.Settings.data.appearance.statusRowRole,"red")
            item("ccStatusRowShade").value=.25;item("ccStatusRowShade").moved();compare(Services.Settings.data.appearance.statusRowShade,.25)
            const style=findChild(border,"ccBorderStyle");verify(style!==null)
            style.set("role","accent");style.set("width",3);style.set("controlcentre",true)
            compare(Services.Settings.data.appearance.surfaceBorders.role,"accent");compare(Services.Settings.data.appearance.surfaceBorders.width,3);verify(Services.Settings.data.appearance.surfaceBorders.controlcentre)
            tryCompare(Services.Settings,"saveState","saved",10000)
            const persisted=JSON.stringify(Services.Settings.data);Services.Settings.discardAndReload();tryCompare(Services.Settings,"ready",true);compare(JSON.stringify(Services.Settings.data),persisted)
            Services.Settings.commit(original);tryCompare(Services.Settings,"saveState","saved",10000)
            console.log("Control Centre hierarchy PASS")
        }catch(e){console.error("FAIL:",e,e.stack)}finally{finish.start()}}
    }
}
