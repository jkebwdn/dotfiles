import QtQuick
import QtQuick.Window
import QtTest
import Quickshell
import "../../.config/quickshell/magi/components/settings" as UI
import "../../.config/quickshell/magi/components/clipboard" as Clip
import "../../.config/quickshell/magi/components/emoji" as EmojiUI
import "../../.config/quickshell/magi/components/controls" as Controls
import "../../.config/quickshell/magi/plugins/bar/controlcentre" as Centre
import "../../.config/quickshell/magi/services" as Services
import "../../.config/quickshell/magi/theme" as Theme
import "../../.config/quickshell/magi/icons" as Icons
ShellRoot {
    QtObject {
        id: clipboard
        signal entered()
        signal resultsAccepted()
        signal resultsReplacing()
        property var rows: []
        property string query: ""
        property string renderedQuery: ""
        property string error: ""
        property bool ready: true
        property bool monitoring: true
        property int count: rows.length
        property var preferences: ({enabled:true})
        function publish(values, query) { resultsReplacing(); rows = values; renderedQuery = query; resultsAccepted() }
    }
    QtObject {
        id: media
        property bool available: true
        property real progress: .65
        property string artworkUrl: ""
        property string title: "Phase 10A media preview"
        property string artist: "Semantic palette roles"
        property string identity: "Fixture"
        property bool canPrevious: true
        property bool canNext: true
        property bool canToggle: true
        property bool playing: true
    }
    FloatingWindow {
        id: window
        color: Theme.Theme.surface
        visible: true; implicitWidth: 1000; implicitHeight: 720
        UI.SettingsContent { id: settings; anchors.fill: parent }
        Clip.ClipboardContent { id: clip; width: 540; height: 600; service: clipboard; visible: false }
        EmojiUI.EmojiContent { id: emoji; width: 448; height: 500; service: Services.Emoji; visible: false }
        Rectangle {
            id: mediaPreview; width: 500; height: 190; visible: false; color: Theme.Theme.surface
            Centre.MediaSection { id: mediaSection; x: 16; y: 16; width: 468; height: implicitHeight; service: media }
            Row {
                x: 16; y: 140; spacing: 24
                UI.SettingsToggle { id: toggle; checked: true }
                Text { text: "Hub toggle · teal"; color: Theme.Theme.text }
            }
        }
    }
    Timer { id: finish; interval: 100; onTriggered: Qt.quit() }
    TestCase {
        name: "Phase10A"
        when: Services.Settings.ready && Icons.IconRegistry.packs.length > 0
        function snap(item, name) {
            wait(80)
            if (Quickshell.env("MAGI_10A_CAPTURES")) grabImage(item).save(Quickshell.env("MAGI_10A_CAPTURES") + "/" + name + ".png")
        }
        function rows(n, prefix) {
            let result=[]
            for(let i=0;i<n;i++) result.push({id:(prefix || "item-")+i,category:"text",preview:i === 0 ? "Newest clipboard item" : "Clipboard entry " + i,timestamp:100-i,pinned:false,thumbnail:""})
            return result
        }
        function test_refinement() {
            try {
                wait(150)
                verify(findChild(settings,"settingsNav-Icons") === null)
                const sidebar=findChild(settings,"settingsSidebar"), tabs=findChild(settings,"appearanceNavigation")
                compare(sidebar.mapToItem(settings,0,0).y,tabs.mapToItem(settings,0,0).y)
                const status=findChild(settings,"settingsSaveStatus")
                compare(status.horizontalAlignment,Text.AlignHCenter)
                const pair=findChild(settings,"themeAndIconPack")
                compare(pair.columns,2)
                compare(findChild(settings,"iconPackSelector").currentIndex,Icons.IconRegistry.packs.findIndex(p=>p.id==='magi-default'))
                const packSelector=findChild(settings,"iconPackSelector")
                const appIconBefore=JSON.stringify(Services.LauncherIcons.resolve({name:"Sample",icon:""}))
                const legacyIndex=Icons.IconRegistry.packs.findIndex(p=>p.id==='magi-legacy')
                packSelector.activated(legacyIndex)
                compare(Services.Settings.data.icons.pack,'magi-legacy')
                compare(JSON.stringify(Services.LauncherIcons.resolve({name:'Sample',icon:''})),appIconBefore)
                packSelector.activated(Icons.IconRegistry.packs.findIndex(p=>p.id==='magi-default'))
                tryCompare(Services.Settings,"saveState","saved")
                grabImage(settings) // warm the offscreen scene before the saved preview
                snap(settings,"theme-wide")
                window.contentItem.Window.window.width=600; wait(100)
                compare(pair.columns,1)
                verify(pair.width <= settings.width-206)
                snap(settings,"theme-narrow")
                window.contentItem.Window.window.width=1000; wait(80)
                Services.SettingsWindowState.page="Bar"; wait(80)
                verify(findChild(settings,"visualSetting-statusIconSize").visible)
                snap(settings,"bar")
                Services.SettingsWindowState.page="Surfaces"; wait(80)
                verify(findChild(findChild(settings,"settingsPage-Surfaces"),"visualSetting-statusIconSize") === null)
                Services.Settings.setValue("appearance","mediaProgressRole","green")
                Services.Settings.setValue("appearance","hubToggleRole","teal")
                for(const id of Theme.ThemeRegistry.ids) {
                    Services.Settings.setTheme(id)
                    compare(Theme.Theme.mediaProgressColor,Theme.Theme.green)
                    compare(Theme.Theme.hubToggleColor,Theme.Theme.teal)
                    compare(findChild(mediaSection,"runtimeAlbumArt").progressColor,Theme.Theme.green)
                    for(const style of ['pill','filled','minimal']) {
                        Services.Settings.setValue('appearance','toggleStyle',style)
                        compare(findChild(toggle,'toggleTrack').color,Theme.Theme.teal)
                    }
                }
                compare(Theme.Theme.primaryAccent('missing','missing'),Theme.Theme.accent)
                Services.Settings.setTheme('catppuccin-mocha')
                settings.visible=false; mediaPreview.visible=true
                snap(mediaPreview,'media-and-toggles')
                mediaPreview.visible=false; emoji.visible=true
                Services.Emoji.prepare()
                Services.Settings.setValue('emoji','recents',[])
                wait(50)
                const recent=findChild(emoji,'emojiRecentRow')
                verify(!recent.visible)
                verify(!Services.Emoji.categories.includes('Recently Used'))
                Services.Emoji.chooseCategory('recents'); compare(Services.Emoji.category,'All')
                Services.Settings.setValue('emoji','recents',['1F525','1F600','2764-FE0F'])
                wait(50)
                verify(recent.visible && recent.height===emoji.cellSize)
                verify(Services.Emoji.results.length>100)
                compare(Services.Emoji.recentEntries[0].emoji,'🔥')
                snap(emoji,'emoji-recents')
                Services.Emoji.query='fire'; wait(30)
                verify(!recent.visible); compare(Services.Emoji.results[0].emoji,'🔥')
                emoji.visible=false; clip.visible=true
                // Fresh entry with empty model; asynchronously arriving data starts at top.
                clipboard.entered(); wait(20)
                clipboard.publish(rows(40),''); wait(60)
                verify(clip.historyView.atYBeginning)
                compare(clip.selectedId,'item-0')
                snap(clip,'clipboard-fresh')
                clip.historyView.positionViewAtIndex(20,ListView.Beginning); wait(30)
                const before=clip.historyView.contentY
                clipboard.publish(rows(40),''); wait(60)
                compare(clip.historyView.contentY,before,'ordinary replacement preserves browsing')
                clipboard.publish([{id:'new',category:'text',preview:'New arrival',timestamp:200,pinned:false,thumbnail:''}].concat(rows(40)),''); wait(60)
                verify(clip.historyView.contentY>1000,'new arrivals do not force scrolling to top')
                compare(clipboard.rows[clip.historyView.indexAt(1,clip.historyView.contentY+1)].id,'item-20','same visible entry survives insertion')
                // Search waits for the matching asynchronous response.
                clipboard.query='match'; wait(20)
                verify(clip.resetPending)
                clipboard.publish(rows(5,'match-'),'match'); wait(60)
                verify(clip.historyView.atYBeginning); compare(clip.selectedId,'match-0')
                clipboard.entered(); wait(20)
                clipboard.publish(rows(40),''); wait(60)
                verify(clip.historyView.atYBeginning); compare(clip.selectedId,'item-0')
                clip.select(15); wait(30); verify(!clip.historyView.atYBeginning)
                clipboard.entered(); wait(60); verify(clip.historyView.atYBeginning)
                // Pins stay first, but fresh entry targets the newest timestamp.
                clipboard.publish([], '')
                clipboard.entered(); wait(20); verify(clip.resetPending)
                const pinnedRows=rows(40)
                pinnedRows[0].pinned=true; pinnedRows[0].timestamp=1
                clipboard.publish(pinnedRows,''); wait(60)
                compare(clip.selectedId,'item-1')
                compare(clip.historyView.indexAt(1,clip.historyView.contentY+1),1)
                clip.historyView.positionViewAtIndex(20,ListView.Beginning); wait(30)
                clipboard.publish(pinnedRows.slice(),''); wait(60)
                compare(clip.historyView.indexAt(1,clip.historyView.contentY+1),20)
                clipboard.query='pinned'; wait(20)
                clipboard.publish(pinnedRows,'pinned'); wait(60)
                compare(clip.selectedId,'item-0'); verify(clip.historyView.atYBeginning)
                clipboard.entered(); wait(20)
                clipboard.publish(pinnedRows,''); wait(60)
                compare(clip.selectedId,'item-1')
                console.log('Phase 10A layout, palettes, recent row and asynchronous Clipboard lifecycle PASS')
            } catch(e) { console.error('FAIL: '+e+' '+e.stack) }
            finish.start()
        }
    }
}
