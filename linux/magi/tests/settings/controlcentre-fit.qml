import QtQuick
import QtQuick.Window
import QtTest
import Quickshell
import Quickshell.Io
import "../../.config/quickshell/magi/components/settings" as UI
import "../../.config/quickshell/magi/services" as Services
ShellRoot {
    UI.SettingsWindow { id:window }
    FileView {id:saved;path:Services.Settings.path;blockLoading:true;blockWrites:true}
    Timer {id:finish;interval:100;onTriggered:Qt.quit()}
    TestCase {
        when:Services.Settings.ready
        name:"ControlCentrePanelFit"
        function item(name){const found=findChild(window.contentItem,name);verify(found!==null,name);return found}
        function capture(name){const dir=Quickshell.env("MAGI_CC_WORKFLOW_CAPTURES");if(dir){wait(180);grabImage(window.contentItem).save(dir+"/"+name+".png")}}
        function test_fit(){try{
            const raw=saved.text(),original=JSON.parse(JSON.stringify(Services.Settings.data)),revision=Services.Settings.revision
            const before=Quickshell.env("MAGI_CC_FIT_BEFORE")==="1"
            Services.SettingsWindowState.shown=true;Services.SettingsWindowState.page="Control Centre";wait(200)
            const preview=item("controlCentrePreview"),page=item("settingsPage-Control Centre")
            const initial=original.controlCentre.decoration
            const fixtures=JSON.parse(Quickshell.env("MAGI_CC_FIXTURES"))
            compare(Services.Settings.revision,revision);saved.reload();compare(saved.text(),raw)
            for(const theme of ["nord","one-light"]){
                Services.Settings.setTheme(theme)
                for(const size of [[720,600],[1000,760],[1400,900]]){
                    window.contentItem.Window.window.width=size[0];window.contentItem.Window.window.height=size[1];wait(150)
                    item("decorationSettings").setOption("asset",initial.asset);item("decorationSettings").setOption("enabled",initial.enabled);wait(120)
                    console.log("PANEL_DIMENSIONS "+JSON.stringify({before:before,theme:theme,window:size,panel:[preview.canvasWidth*preview.fitScale,preview.composition.height*preview.fitScale],logical:[preview.canvasWidth,preview.composition.height],viewport:[preview.width,preview.height],scale:preview.fitScale}))
                    capture(theme+"-"+size[0]+"-operator")
                    let fixed=null
                    for(let i=0;i<fixtures.length+1;i++){
                        item("decorationSettings").setOption("enabled",i>0);item("decorationSettings").setOption("asset",i?fixtures[i-1]:null);wait(160)
                        if(i===0)fixed=preview.fitScale
                        if(!before){
                            compare(preview.fitScale,fixed,"Artwork dimensions cannot shrink the panel")
                            const decoration=item("decorationPreview")
                            if(i){
                                tryVerify(()=>decoration.ready)
                                // Existing compact fallback shrinks/hides artwork, never the panel.
                                if(decoration.visible){verify(decoration.x>=0);verify(decoration.y>=0);verify(decoration.width<=decoration.availableWidth);verify(decoration.height<=decoration.availableHeight)}
                            }
                            const scroll=page.inspectorViewport,pos=preview.mapToItem(window.contentItem,0,0)
                            for(const name of ["ccRoundness","decorationSettings"]){
                                const card=item(name);card.expanded=true
                                scroll.contentY=Math.max(0,Math.min(scroll.contentHeight-scroll.height,card.y));wait(40)
                                compare(preview.mapToItem(window.contentItem,0,0),pos)
                                compare(preview.fitScale,fixed)
                                capture(theme+"-"+size[0]+"-"+i+"-"+name)
                            }
                            scroll.contentY=0
                        }
                        capture(theme+"-"+size[0]+"-asset-"+i)
                    }
                }
            }
            Services.Settings.commit(original);tryCompare(Services.Settings,"saveState","saved",10000)
            Services.Settings.discardAndReload();tryCompare(Services.Settings,"ready",true);compare(Services.Settings.data,original)
            console.log("Control Centre fit PASS")
        }catch(e){console.error("FAIL:",e,e.stack)}finally{finish.start()}}
    }
}
