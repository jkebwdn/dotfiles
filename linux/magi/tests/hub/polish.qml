import QtQuick
import QtQuick.Window
import QtTest
import Quickshell
import "../../.config/quickshell/magi/services" as Services
import "../../.config/quickshell/magi/components/hub" as UI
import "../../.config/quickshell/magi/theme" as Theme
ShellRoot {
    UI.HubWindow { id: window }
    Timer { id: finish; interval: 100; onTriggered: Qt.quit() }
    TestCase {
        name: "HubPolish"
        when: Services.Settings.ready
        function history(count) {
            const rows = []
            for (let i=0;i<count;i++) rows.push({id:"row-"+i,category:i%3===0?"image":"text",preview:"History "+i,thumbnail:"",pinned:false,timestamp:1})
            Services.Clipboard.rows=rows; Services.Clipboard.count=count
            wait(180)
        }
        function test_composition() {
            try {
                Services.Hub.open("clipboard"); wait(300)
                const clip=window.content.currentContent
                const list=findChild(clip,"clipboardHistory")
                const search=clip.searchField
                verify(search.activeFocus)
                for (const size of [Qt.size(1024,640),Qt.size(1280,900),Qt.size(3840,2160)]) {
                    window.contentItem.Window.window.width=size.width
                    window.contentItem.Window.window.height=size.height
                    for (const position of ["below","above"]) {
                        Services.Settings.setValue("hub","selectorPosition",position)
                        for (const fraction of [.1,2/3,.9]) {
                            Services.Settings.setValue("hub","verticalPosition",fraction)
                            history(0)
                            const anchor=window.content.selectorPill.mapToItem(window.contentItem,0,0)
                            const empty=window.content.surface.height
                            const top=window.content.y
                            verify(anchor.y>=48 && anchor.y+window.content.selectorHeight<=size.height)
                            history(1)
                            verify(window.content.surface.height>=empty,"one image grows within available room")
                            compare(window.content.selectorPill.mapToItem(window.contentItem,0,0),anchor)
                            history(30)
                            verify(window.content.surface.height<=660)
                            verify(list.contentHeight>list.height)
                            verify(window.content.y>=48)
                            verify(window.content.y+window.content.height<=size.height)
                            compare(window.content.selectorPill.mapToItem(window.contentItem,0,0),anchor)
                            if(position==="below") verify(window.content.y<=top)
                            else compare(window.content.y,top)
                            if(size.height>=900 && fraction===2/3 && position==="below") verify(window.content.surface.height>empty,"unclamped history grows")
                            verify(search.mapToItem(clip,0,0).y >= list.mapToItem(clip,0,0).y+list.height)
                            list.positionViewAtEnd(); wait(40); verify(list.contentY>0)
                        }
                    }
                }
                Services.Settings.setRoundness("hubSelector",0); wait(30)
                compare(window.content.selectorPill.radius,0)
                Services.Settings.setRoundness("hubSelector",1); wait(30)
                verify(window.content.selectorPill.radius>0)
                history(3); search.forceActiveFocus(); keyClick(Qt.Key_Down)
                verify(clip.selectedIndex>=0)
                list.positionViewAtBeginning();wait(80)
                const card=list.itemAtIndex(0), frame=findChild(card,"clipboardCardBorder")
                const height=card.height
                for(const palette of ["catppuccin-mocha","everforest-light-hard"]) {
                    Services.Settings.setTheme(palette)
                    for(const enabled of [true,false]) for(const width of [0,3]) {
                        Services.Settings.setValue("appearance","notificationBorders",Object.assign({},Services.Settings.data.appearance.notificationBorders,{role:"accent",width:width,clipboard:enabled}))
                        wait(20);compare(frame.border.width,enabled?width:0);compare(frame.border.color,Theme.Theme.accent);compare(card.height,height)
                    }
                }
                Services.Hub.close(); wait(30); verify(!window.visible)
                console.log("Hub polish PASS: normalized anchors, above/below, Clipboard measured height, scrolling, bottom search, roundness and keyboard")
            } catch(error) { console.error("FAIL:",error,error.stack) }
            finally { finish.start() }
        }
    }
}
