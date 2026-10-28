import QtQuick
import QtQuick.Window
import QtTest
import Quickshell
import "../../.config/quickshell/magi/components/settings" as UI
import "../../.config/quickshell/magi/services" as Services
import "../../.config/quickshell/magi/theme" as Theme
ShellRoot {
    FloatingWindow {
        id: win; visible:true; implicitWidth:1000; implicitHeight:720
        color:Theme.Theme.background
        UI.SettingsContent {id:content;anchors.fill:parent}
    }
    Timer {id:finish;interval:100;onTriggered:Qt.quit()}
    TestCase {
        name:"SettingsProduct";when:Services.Settings.ready
        function capture(name) {
            const directory=Quickshell.env("MAGI_SETTINGS_PRODUCT_CAPTURES")
            if(directory)grabImage(content).save(directory+"/"+name+".png")
        }
        function test_review() {try {
            for(const theme of ["kanagawa-wave","one-light"]) {
                Services.Settings.setTheme(theme);tryCompare(Theme.Theme,"effectiveTheme",theme)
                tryCompare(Services.Settings,"saveState","saved")
                const before=JSON.stringify(Services.Settings.data),revision=Services.Settings.revision
                for(const geometry of [Qt.size(1000,720),Qt.size(720,500),Qt.size(1280,900)]) {
                    content.Window.window.width=geometry.width;content.Window.window.height=geometry.height
                    tryCompare(content,"width",geometry.width);tryCompare(content,"height",geometry.height)
                    for(const name of ["Appearance","Bar","Control Centre","Applications","Wallpaper","Lock Screen","Profile"]) {
                        // Applications is labelled Transparency in the canonical sidebar.
                        Services.SettingsWindowState.page=name;wait(100)
                        const title=name==="Applications"?"Transparency & blur":name
                        const p=findChild(content,"settingsPage-"+title)
                        verify(p!==null,"page exists: "+title);tryCompare(p,"visible",true)
                        p.contentY=0
                        if(name==="Bar")p.mode="Layout"
                        waitForPolish(content.Window.window)
                        verify(p.width>0 && p.width<=content.width)
                        if(p.body.visible)verify(p.body.width>0 && p.body.width<=p.width,"visible body bounded: "+name)
                        if(geometry.width===1000) {
                            console.log("PRODUCT METRIC",theme,name,"viewport",Math.round(p.height),"content",Math.round(p.contentHeight),"scroll",p.contentY,"origin",p.originY,"bodyY",p.body.y)
                            capture(theme+"-"+name.toLowerCase().replace(/ /g,"-"))
                            if(name==="Bar") {p.mode="Appearance";waitForPolish(content.Window.window);capture(theme+"-bar-appearance")}
                        } else if(["Appearance","Lock Screen","Profile"].includes(name))capture(theme+"-"+geometry.width+"-"+name.toLowerCase().replace(/ /g,"-"))
                    }
                }
                wait(300)
                compare(JSON.stringify(Services.Settings.data),before,"Navigation/preview modes must not edit preferences")
                compare(Services.Settings.revision,revision)
            }
            console.log("Settings product review PASS: current pages at three sizes; navigation does not persist preferences")
            finish.start()
        }catch(error){console.error("FAIL:",error,error.stack);finish.start();throw error}}
    }
}
