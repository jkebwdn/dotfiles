import QtQuick
import QtQuick.Window
import QtTest
import Quickshell
import "../../.config/quickshell/magi/components/settings" as UI
import "../../.config/quickshell/magi/services" as Services
import "../../.config/quickshell/magi/theme" as Theme
ShellRoot {
    UI.SettingsWindow { id: window }
    Timer { id: finish; interval: 100; onTriggered: Qt.quit() }
    TestCase {
        name: "AppearanceSimplification"; when: Services.Settings.ready
        function item(name) { const x=findChild(window.contentItem,name); verify(x!==null,name); return x }
        function reveal(x) {
            const p=item("settingsPage-Appearance")
            p.contentY=Math.max(0,Math.min(p.contentHeight-p.height,x.mapToItem(p,0,0).y+p.contentY-20))
            waitForPolish(window.contentItem.Window.window)
        }
        function capture(name) {
            const folder=Quickshell.env("MAGI_APPEARANCE_CAPTURES")
            wait(50); if(folder) grabImage(window.contentItem).save(folder+"/"+name+".png")
        }
        function texts(node) {
            let out=[]
            if(!node.visible)return out
            if(typeof node.text==="string")out.push(node.text)
            for(const child of node.children)out=out.concat(texts(child))
            return out
        }
        function fixtures() {
            return [
                ["hyprland","Hyprland","Live",""],
                ["ghostty","Ghostty","Reload requested",""],
                ["gtk","GTK / Thunar","Applies next launch",""],
                ["zen","Zen Browser","Restart required",""],
                ["btop","btop","Applies next launch",""],
                ["missing","Missing dependency","Unavailable","Executable not found"],
                ["activation","Activation failure","Failed","Reload activation failed"],
                ["publication","Publication failure with a deliberately long application name","Publication failed","Validation rejected publication"]
            ].map(v=>({id:v[0],label:v[1],statusLabel:v[2],error:v[3],available:v[0]!=="missing",configured:true,
                enabled:true,installed:true,phase:v[3]?"error":"ready",reason:v[3],confirmedProfile:"fixture",publishedPalette:"nord",
                result:v[0]==="zen"?"Manual workspace colour required. Restart Zen.":v[0]==="btop"?"Reselect manually or start a new process.":v[2]}))
        }
        function test_review() { try {
            Services.SettingsWindowState.shown=true; Services.SettingsWindowState.page="Appearance"
            tryVerify(()=>!Services.ThemeOrchestrator.busy); wait(150)
            const page=item("settingsPage-Appearance"),gallery=item("themeGallery"),packs=item("iconPackGallery")
            const original=JSON.parse(JSON.stringify(Services.Settings.data))
            verify(findChild(page,"applicationThemeReview")===null)
            verify(findChild(page,"roundnessChoice-0")===null)
            for(const theme of ["nord","one-light"]) {
                Services.Settings.setTheme(theme)
                for(const size of [[720,600,2],[1000,760,3],[1400,900,5]]) {
                    window.contentItem.Window.window.width=size[0]; window.contentItem.Window.window.height=size[1]
                    tryCompare(window,"width",size[0]);waitForPolish(window.contentItem.Window.window)
                    gallery.expanded=false;page.contentY=0;wait(80)
                    compare(gallery.count,size[2]);verify(gallery.visibleThemes.some(t=>t.id===theme))
                    const indexes=gallery.visibleThemes.map(t=>gallery.model.findIndex(x=>x.id===t.id))
                    compare(indexes,indexes.slice().sort((a,b)=>a-b))
                    verify(gallery.itemAt(0).Accessible.checked===gallery.itemAt(0).selected)
                    const last=gallery.itemAt(gallery.count-1),disclosure=item("themeGalleryDisclosure")
                    verify(disclosure.y>=last.mapToItem(gallery,0,last.height).y)
                    verify(item("installIconPack").y>=packs.y+packs.height)
                    const visible=texts(page).join("\n")
                    verify(!/Current ·|Your choice is saved|Changes are saved automatically/.test(visible))
                    capture(theme+"-"+size[0]+"-appearance")
                }
            }
            window.contentItem.Window.window.width=1000;wait(60)
            const disclosure=item("themeGalleryDisclosure");reveal(disclosure);mouseClick(disclosure)
            tryCompare(gallery,"expanded",true);wait(60)
            const allFilter=item("themeFilter-All")
            verify(allFilter.activeFocus,"Expansion focuses gallery filters")
            verify(allFilter.mapToItem(page,0,0).y>=0,"Gallery start remains visible")
            verify(allFilter.mapToItem(page,0,allFilter.height).y<=page.height)
            gallery.expanded=false;wait(60)
            const before=Services.Settings.data.appearance.roundness.master
            const slider=item("masterRoundnessPrecision");reveal(slider);slider.forceActiveFocus();keyClick(Qt.Key_Left)
            compare(Services.Settings.data.appearance.roundness.master,Math.max(0,before-.05))
            compare(item("masterRoundnessPreview").radius,Math.min(14,8*Services.Settings.data.appearance.roundness.master))
            tryCompare(Services.Settings,"saveState","saved")
            capture("roundness-primary")
            Services.Settings.reload();tryCompare(Services.Settings,"ready",true)
            compare(Services.Settings.data.appearance.roundness.master,Math.max(0,before-.05))
            Services.Settings.setRoundness("master",before)
            const revision=Services.Settings.revision
            reveal(packs);packs.focusIndex(0);keyClick(Qt.Key_Right);keyClick(Qt.Key_Return)
            compare(Services.Settings.data.icons.pack,packs.model[1].id);verify(packs.itemAt(1).Accessible.checked)
            Services.Settings.setIconPack(original.icons.pack)
            const install=item("installIconPack");reveal(install);mouseClick(install)
            const dialog=page.testPackDialog;tryCompare(dialog,"visible",true);dialog.reject();tryCompare(dialog,"visible",false);window.contentItem.Window.window.requestActivate();wait(100)
            const summary=item("applicationThemesSummary");summary.expanded=true;wait(50)
            Services.ThemeOrchestrator.targets=fixtures();wait(100)
            for(const width of [720,1000,1400]) {
                window.contentItem.Window.window.width=width;wait(60)
                for(const target of fixtures()) {
                    const row=item("applicationRow-"+target.id),follow=item("followTheme-"+target.id)
                    verify(follow.mapToItem(row,follow.width,0).x<=row.width+1,"Toggle contained at "+width)
                }
            }
            window.contentItem.Window.window.width=1000;wait(60)
            reveal(summary);capture("applications-collapsed")
            compare(summary.title,"Application themes");compare(summary.attentionCount,3)
            let height=-1
            for(const target of fixtures()) {
                const row=item("applicationRow-"+target.id),details=item("themeDetails-"+target.id),follow=item("followTheme-"+target.id)
                verify(!row.expanded);compare(follow.text,"");compare(follow.Accessible.name,"Follow MAGI for "+target.label)
                compare(item("themeAttention-"+target.id).visible,!!target.error)
                verify(!item("themeSummary-"+target.id).visible);verify(!item("themeStatus-"+target.id).visible)
                if(height<0)height=row.height;compare(row.height,height)
                verify(follow.mapToItem(row,0,0).x>details.mapToItem(row,0,0).x)
                verify(follow.mapToItem(row,follow.width,0).x<=row.width+1)
                reveal(details);const enabled=follow.checked;details.forceActiveFocus();verify(details.activeFocus,"disclosure focus "+target.id);keyClick(Qt.Key_Space)
                verify(row.expanded,"expanded "+target.id);compare(follow.checked,enabled);verify(item("themeSummary-"+target.id).visible)
                verify(item("themeStatus-"+target.id).visible)
                if(target.id==="ghostty")capture("application-healthy-expanded")
                if(target.id==="publication")capture("application-error-expanded")
                reveal(details);wait(40);mouseClick(details);verify(!row.expanded,"collapse "+target.id);compare(follow.checked,enabled)
            }
            verify(!item("zenWorkspaceColor").visible)
            Services.ThemeOrchestrator.targets=fixtures().filter(t=>!t.error);wait(50);compare(summary.description,"")
            Services.Settings.setTheme(original.appearance.theme);tryCompare(Services.Settings,"saveState","saved")
            compare(Services.Settings.data,original,"No unrelated persisted fields changed")
            console.log("Appearance simplification PASS");finish.start()
        } catch(e) { console.error("FAIL:",e,e.stack);finish.start();throw e } }
    }
}
