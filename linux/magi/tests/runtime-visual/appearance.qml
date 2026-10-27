import QtQuick
import QtQuick.Window
import QtTest
import Quickshell
import "../../.config/quickshell/magi/components/bar" as BarUI
import "../../.config/quickshell/magi/components/hub" as HubUI
import "../../.config/quickshell/magi/services" as Services
import "../../.config/quickshell/magi/theme" as Theme
ShellRoot {
    BarUI.Bar { id: bar; expandableHostMode: "combined" }
    HubUI.HubWindow { id: settings; readyToOpen: bar.settingsReady; previewSurface: bar.activeCombinedRegion }
    Timer { id: finish; interval: 100; onTriggered: Qt.quit() }
    TestCase {
        name: "ControlCentreAppearancePreview"
        when: Services.Settings.ready
        function collect(item, predicate) {
            let found = predicate(item) ? [item] : []
            for (const child of item.children || []) found = found.concat(collect(child, predicate))
            return found
        }
        function reveal(page, item) {
            page = findChild(page, "controlCentreEditor") || page
            page.contentY = Math.max(0, Math.min(page.contentHeight - page.height, item.mapToItem(page.contentItem, 0, 0).y - 40))
            wait(30)
        }
        function setting(page, key) {
            const families = {primaryIconSize:"controls", primaryContainerSize:"controls", secondaryIconSize:"actions", avatarSize:"profile", mediaArtworkSize:"media", profileGreetingSize:"profile", profileWeatherSize:"profile", profileThirdLineSize:"profile", profileControlsGap:"profile", controlsSlidersGap:"controls", slidersActionsGap:"sliders", actionsMediaGap:"actions"}
            page.mode = "Appearance"
            page.selection.select(families[key])
            wait(0)
            const slider = findChild(page, "visualSetting-" + key)
            verify(slider !== null, "Current inspector owns " + key)
            for (let item = slider.parent; item && item !== page; item = item.parent)
                if (item.expanded !== undefined) item.expanded = true
            wait(0)
            return slider
        }
        function tiles() { return collect(bar.contentItem, i => i.accentRole !== undefined && i.primaryTriggered !== undefined) }
        function icon(tile) { return collect(tile, i => i.resolved !== undefined && i.size !== undefined)[0] }
        function body() {
            return collect(bar.contentItem, i => i.selected === true && i.modelData === bar.expandablePillRegistry.controlcentre && i.item !== undefined)[0].item
        }
        function assertArtwork(art, size, radius) {
            compare(art.width, size); compare(art.height, size); compare(art.radius, radius)
            const bounds = findChild(art, "artworkImageBounds")
            const mask = findChild(art, "artworkMask")
            compare(bounds.x, art.frameWidth)
            compare(bounds.width, size - 2 * art.frameWidth)
            compare(mask.radius, Math.max(0, radius - art.frameWidth))
            verify(bounds.x >= 0 && bounds.x + bounds.width <= art.width)
        }
        function test_appearanceAndPreview() {
            try {
            Services.SettingsWindowState.page = "Control Centre"
            Services.SettingsWindowState.open()
            Services.Settings.setValue("profile", "displayName", "A long display name ".repeat(4).trim())
            Services.Settings.setValue("profile", "subtitleMode", "custom")
            Services.Settings.setValue("profile", "subtitle", "A long optional profile line ".repeat(4))
            Services.Media.available = true
            Services.Media.title = "Long media title ".repeat(20)
            Services.Media.artist = "Long artist ".repeat(20)
            Services.Media.artworkUrl = Qt.resolvedUrl("test-artwork.ppm").toString()
            Services.Bluetooth.available = true
            Services.QuickActions.powerAvailable = true
            wait(150)
            const page = findChild(settings.contentItem, "settingsPage-Control Centre")
            const preview = findChild(page, "controlCentrePreview")
            verify(preview !== null)
            Services.SettingsWindowState.toggleControlCentrePreview()
            const cc = bar.expandablePillRegistry.controlcentre
            tryCompare(cc, "phase", 3)
            verify(Services.SettingsWindowState.controlCentrePreview && bar.previewPinned)
            verify(!bar.catcherEnabled, "no full-screen input catcher in preview")
            compare(bar.exclusiveZone, 48)
            bar.closeActiveCombinedMenu()
            compare(Services.MenuController.activeMenu, "controlcentre", "outside dismissal entry point ignores preview")
            // Real Settings interactions write the canonical preferences and update
            // the actual retained runtime objects, not a duplicate preview widget.
            for (const key of ["primaryIconSize", "primaryContainerSize", "secondaryIconSize", "avatarSize", "mediaArtworkSize"]) {
                const slider = setting(page, key)
                reveal(page, slider)
                const before = Services.Settings.data.appearance.visual[key]
                settings.contentItem.Window.window.requestActivate()
                mouseClick(slider, slider.width / 2, slider.height / 2)
                slider.forceActiveFocus()
                keyClick(Qt.Key_Right)
                verify(Services.Settings.data.appearance.visual[key] !== before, "real setting edits " + key)
                wait(450)
                compare(cc.phase, 3)
                verify(bar.previewPinned && !bar.catcherEnabled)
            }
            const fontKeys = ["profileGreetingSize","profileWeatherSize","profileThirdLineSize"]
            const textNames = ["profileGreeting","profileWeather","profileThirdLine"]
            const fontDefaults = [16,12,11]
            const gapKeys = ["profileControlsGap","controlsSlidersGap","slidersActionsGap","actionsMediaGap"]
            for (const key of fontKeys.concat(gapKeys)) {
                const slider = setting(page, key)
                reveal(page,slider); mouseClick(slider); slider.forceActiveFocus(); keyClick(Qt.Key_Right)
                wait(40); verify(bar.previewPinned)
                const value = Services.Settings.data.appearance.visual[key]
                if (fontKeys.indexOf(key) >= 0) compare(findChild(body(),textNames[fontKeys.indexOf(key)]).font.pixelSize,value)
            }
            for (let i=0;i<3;i++) Services.Settings.setVisual(fontKeys[i],fontDefaults[i])
            for (let i=0;i<3;i++) {
                for (const value of [i===0 ? 12 : 10,i===0 ? 24 : 20]) {
                    Services.Settings.setVisual(fontKeys[i],value); wait(20)
                    for (let j=0;j<3;j++) compare(findChild(body(),textNames[j]).font.pixelSize,i===j ? value : fontDefaults[j])
                }
                Services.Settings.setVisual(fontKeys[i],fontDefaults[i])
            }
            const sectionKeys=["profile","quickControls","sliders","actions","media"]
            const sectionNames=["runtimeProfile","runtimePrimarySection","runtimeSliderSection","runtimeActionSection","runtimeMediaSection"]
            for (const gaps of [[0,0,0,0],[48,48,48,48],[7,13,19,31]]) {
                gapKeys.forEach((key,i)=>Services.Settings.setVisual(key,gaps[i]))
                fontKeys.forEach((key,i)=>Services.Settings.setVisual(key,i===0 ? 24 : 20))
                Services.Settings.setVisual("avatarSize",48)
                for (let mask=0;mask<32;mask++) {
                    sectionKeys.forEach((key,i)=>Services.Settings.setControlSection(key,!!(mask & (1<<i))))
                    Services.Settings.setValue("controlCentre","columns",mask%2 ? 1 : 4)
                    Services.Settings.setValue("controlCentre","actionColumns",mask%2 ? 2 : 3)
                    Services.Settings.setValue("profile","subtitleMode",mask%4===1 ? "custom" : "greeting")
                    wait(40)
                    const sections=sectionNames.map(name=>findChild(body(),name))
                    let previous=-1, end=0
                    sections.forEach((section,i)=>{
                        if (!(mask & (1<<i))) return
                        compare(section.y,end+(previous>=0 ? gaps[previous] : 0),"single gap after previous visible section")
                        end=section.y+section.height; previous=i
                    })
                    compare(cc.naturalHeight,end,"height equals visible sections plus single gaps")
                    compare(body().contentHeight,end)
                    if (mask&1) {
                        const header=sections[0]
                        let bottom=0
                        for (const name of textNames) {
                            const line=findChild(header,name)
                            if (!line.visible) continue
                            const point=line.mapToItem(header,0,0)
                            verify(point.y>=bottom-1 && point.y+line.height<=header.height+1,"profile text fits without overlap")
                            verify(point.x+line.width<=header.width+1,"long text stays bounded")
                            bottom=point.y+line.height
                        }
                        compare(findChild(header,"profileThirdLine").visible,mask%4===1)
                    }
                    verify(bar.previewPinned)
                }
            }
            sectionKeys.forEach(key=>Services.Settings.setControlSection(key,true))
            fontKeys.forEach((key,i)=>Services.Settings.setVisual(key,fontDefaults[i]))
            gapKeys.forEach(key=>Services.Settings.setVisual(key,20))
            console.log("Live typography and 96 hidden-section/gap combinations PASS")
            // Exact colour equivalence is covered by colours.qml against Git 7afd1c6.
            for (const size of [Qt.size(720,500), Qt.size(940,720)]) {
                settings.contentItem.Window.window.width = size.width
                settings.contentItem.Window.window.height = size.height
                for (const values of [[16,60,16,48,112,0,2],[48,60,36,112,48,2,0],[48,96,36,112,112,2,2],[32,68,32,76,80,1,1]]) {
                    const keys = ["primaryIconSize","primaryContainerSize","secondaryIconSize","avatarSize","mediaArtworkSize"]
                    keys.forEach((key,i) => Services.Settings.setVisual(key,values[i]))
                    Services.Settings.setRoundness("avatar",values[5])
                    Services.Settings.setRoundness("albumArt",values[6])
                    Services.Settings.setValue("controlCentre","columns",size.width === 720 ? 1 : 5)
                    Services.Settings.setValue("controlCentre","actionColumns",2)
                    wait(500)
                    const content = body()
                    verify(cc.expandedWidth <= bar.width - 28)
                    verify(content.contentHeight <= cc.naturalHeight + 1, "measured body fits height contract")
                    compare(cc.actionRows,3)
                    const liveTiles = tiles()
                    for (const tile of liveTiles) {
                        compare(tile.width, values[1]); compare(icon(tile).size, values[0])
                        const point = tile.mapToItem(content,0,0)
                        verify(point.x >= 0 && point.x + tile.width <= content.width + 1)
                        verify(icon(tile).x >= 0 && icon(tile).x + icon(tile).width <= tile.width)
                    }
                    const avatar = findChild(content,"runtimeAvatar")
                    const art = findChild(content,"runtimeAlbumArt")
                    for (const border of [0,2,5]) {
                        Services.Settings.setVisual("avatarBorderWidth",border)
                        wait(20)
                        assertArtwork(avatar,values[3],10*values[5])
                        assertArtwork(art,values[4],10*values[6])
                    }
                    for (const item of collect(content, i => i.text !== undefined && i.elide !== undefined && i.visible)) {
                        const point = item.mapToItem(content,0,0)
                        verify(point.x >= -1 && point.x + item.width <= content.width + 1, "long text bounded")
                    }
                    const actions = collect(content, i => i.moduleId !== undefined && i.danger !== undefined && i.triggered !== undefined)
                    for (const action of actions) compare(icon(action).size, values[2])
                }
            }
            // Reset and persist through the production UI while preview remains open.
            const reset = findChild(page, "settingsButton-Reset Control Centre appearance")
            reveal(page,reset); mouseClick(reset)
            wait(500)
            compare(Theme.RenderTokens.tileSize,68)
            compare(Theme.RenderTokens.tileIconSize,32)
            compare(Theme.RenderTokens.avatarSize,76)
            compare(Theme.RenderTokens.mediaArtworkSize,80)
            tryCompare(Services.Settings,"saveState","saved")
            Services.Settings.discardAndReload()
            tryCompare(Services.Settings,"ready",true)
            verify(bar.previewPinned)
            Services.SettingsWindowState.toggleControlCentrePreview()
            tryCompare(cc,"phase",0)
            verify(!Services.SettingsWindowState.controlCentrePreview)
            // New typography and border settings update the real pinned production card.
            Services.SettingsWindowState.toggleControlCentrePreview(); tryCompare(cc,"phase",3)
            for (const weight of [400,700]) {
                for (const key of ["profileGreetingWeight","profileWeatherWeight","profileThirdLineWeight","mediaTitleWeight","mediaArtistWeight"])
                    Services.Settings.setVisual(key,weight)
                Services.Settings.setVisual("mediaTitleSize",weight===400?10:24)
                Services.Settings.setVisual("mediaArtistSize",weight===400?10:20)
                Services.Settings.setVisual("mediaProgressBorderWidth",weight===400?0:5)
                wait(80)
                for (const id of ["profileGreeting","profileWeather","profileThirdLine","mediaTitle","mediaArtist"])
                    compare(findChild(body(),id).font.weight,weight)
                compare(findChild(body(),"mediaTitle").font.pixelSize,weight===400?10:24)
                compare(findChild(body(),"mediaArtist").font.pixelSize,weight===400?10:20)
                compare(findChild(body(),"runtimeAlbumArt").borderWidth,weight===400?0:5)
                verify(bar.previewPinned)
            }
            Services.SettingsWindowState.toggleControlCentrePreview();tryCompare(cc,"phase",0)
            // The pin belongs to the Settings session, across every real page.
            Services.SettingsWindowState.toggleControlCentrePreview(); tryCompare(cc,"phase",3)
            const closePreview = findChild(settings.contentItem,"settingsCloseControlCentrePreview")
            for (const name of ["Appearance","Profile","Bar","Date & time","Notifications","Clipboard","Launcher","Emoji","Wallpaper","Security","Control Centre"]) {
                const nav = findChild(settings.contentItem,"settingsNav-"+name)
                nav.forceActiveFocus(); wait(30); mouseClick(nav); wait(80)
                compare(Services.SettingsWindowState.page,name)
                compare(cc.phase,3); verify(bar.previewPinned && closePreview.visible)
                if (name === "Appearance") {
                    Services.Settings.setVisual("primaryIconSize",40); wait(30)
                    tiles().forEach(tile => compare(icon(tile).size,40))
                }
                if (name === "Profile") {
                    const profilePage = findChild(settings.contentItem,"settingsPage-Profile")
                    const fields = collect(profilePage,i => i.maximumLength === 80 || i.maximumLength === 160)
                    for (const field of fields) {
                        reveal(profilePage,field); mouseClick(field); field.forceActiveFocus()
                        keyClick(Qt.Key_A,Qt.ControlModifier);
                        for (const character of (field.maximumLength === 80 ? "Operator" : "Live third line")) keyClick(character)
                    }
                    wait(80)
                    verify(findChild(body(),"profileGreeting").text.endsWith(" Operator"))
                    compare(findChild(body(),"profileThirdLine").text,"Live third line")
                    for (const enabled of [false,true]) {
                        Services.Settings.setValue("profile","subtitleMode",enabled ? "custom" : "greeting")
                        wait(30); compare(findChild(body(),"profileThirdLine").visible,enabled)
                    }
                }
            }
            Services.SettingsWindowState.open(); wait(30)
            verify(bar.previewPinned,"reopening Settings keeps session preview")
            verify(Services.Settings.setControlSection("media",false))
            wait(500); verify(!findChild(body(),"runtimeAlbumArt").visible)
            Services.Settings.setControlSection("media",true); wait(500)
            verify(findChild(body(),"runtimeAlbumArt").visible)
            mouseClick(closePreview); tryCompare(cc,"phase",0); verify(!bar.previewPinned)
            Services.MenuController.open("controlcentre"); tryCompare(cc,"phase",3)
            verify(bar.catcherEnabled)
            mouseClick(findChild(bar.contentItem,"statusDismissCatcher"),10,400)
            tryCompare(cc,"phase",0)
            Services.SettingsWindowState.open(); wait(150)
            Services.SettingsWindowState.toggleControlCentrePreview(); tryCompare(cc,"phase",3)
            Services.SettingsWindowState.page = "Profile"
            Services.SettingsWindowState.shown = false
            tryCompare(cc,"phase",0); verify(!bar.previewPinned)
            Services.SettingsWindowState.page = "Control Centre"
            // Preview Escape still reaches the production body/Loader dismissal.
            Services.SettingsWindowState.open(); wait(150)
            Services.SettingsWindowState.toggleControlCentrePreview(); tryCompare(cc,"phase",3)
            bar.contentItem.Window.window.requestActivate()
            wait(50)
            body().forceActiveFocus(); keyClick(Qt.Key_Escape)
            tryCompare(cc,"phase",0); verify(!bar.previewPinned)
            verify(Services.SettingsWindowState.shown, "Escape in CC leaves Settings open")
            settings.contentItem.Window.window.requestActivate()
            wait(50)
            Services.SettingsWindowState.toggleControlCentrePreview(); tryCompare(cc,"phase",3)
            Services.MenuController.navigate("wifi")
            verify(!bar.previewPinned)
            Services.MenuController.close(); wait(550)
            Services.MenuController.open("controlcentre"); tryCompare(cc,"phase",3)
            verify(bar.catcherEnabled, "normal outside catcher restored")
            mouseClick(findChild(bar.contentItem,"statusDismissCatcher"),10,400)
            tryCompare(cc,"phase",0)
            compare(bar.exclusiveZone,48)
            console.log("CC appearance and preview PASS")
            finish.start()
            } catch (error) { console.error("FAIL: " + error + " " + error.stack); throw error }
        }
    }
}
