import QtQuick
import QtQuick.Window
import QtTest
import Quickshell
import "../../.config/quickshell/magi/components/hub" as HubUI
import "../../.config/quickshell/magi/components/settings" as SettingsUI
import "../../.config/quickshell/magi/plugins/bar/controlcentre" as Centre
import "../../.config/quickshell/magi/services" as Services
import "../../.config/quickshell/magi/theme" as Theme
ShellRoot {
    HubUI.HubWindow { id: hub }
    FloatingWindow {
        id: sample; visible: true; implicitWidth: 620; implicitHeight: 420
        Centre.ProfileHeader { id: profile; width: 400; height: implicitHeight }
        Centre.MediaSection { id: media; y: 170; width: 400; height: implicitHeight }
        SettingsUI.SettingsSelector { id: selector; y: 320; width: 300; model: ["surface","accent","elevated"]; currentIndex: 1 }
        SettingsUI.SettingsNumber { id: number; x: 340; y: 320; from: 1; to: 8; value: 4 }
    }
    Timer { id: finish; interval: 100; onTriggered: Qt.quit() }
    TestCase {
        name: "FinalNativeFeedback"
        when: Services.Settings.ready
        function collect(item,predicate) {
            let result=predicate(item)?[item]:[]
            for(const child of item.children || []) result=result.concat(collect(child,predicate))
            return result
        }
        function centered(a,b,container) {
            const ay=a.mapToItem(container,0,0).y+a.height/2
            const by=b.mapToItem(container,0,0).y+b.height/2
            verify(Math.abs(ay-by)<=1,"natural stacks share vertical centre: "+ay+" / "+by)
        }
        function test_feedback() {
            try {
                for(const theme of ["catppuccin-mocha","catppuccin-frappe","everforest-light-hard"]) {
                    Services.Settings.setTheme(theme);wait(30)
                    const swatch=findChild(selector,"settingsRoleSwatch")
                    verify(swatch.visible);compare(swatch.color,Theme.Theme.accent)
                    compare(selector.background.color,Theme.Theme.elevated)
                    compare(number.background.color,Theme.Theme.elevated)
                    verify(selector.background.border.width>0 && number.background.border.width>0)
                    const value=findChild(selector,"settingsSelectorValue")
                    const left=value.parent.mapToItem(selector,0,0).x
                    compare(left, selector.leftPadding)
                    verify(value.parent.width <= selector.availableWidth)
                    const chevronX=selector.indicator.x
                    selector.currentIndex=2;wait(20);compare(selector.indicator.x,chevronX);compare(swatch.color,Theme.Theme.elevated)
                    selector.currentIndex=1
                    selector.enabled=false;compare(selector.opacity,SettingsUI.SettingsMetrics.disabledOpacity);selector.enabled=true
                    selector.forceActiveFocus();verify(selector.activeFocus)
                    number.forceActiveFocus();keyClick(Qt.Key_Up);verify(number.value>4);number.value=4
                    for(const background of [false,true]) for(const size of [48,112]) for(const font of [12,24]) for(const third of [false,true]) {
                        Services.Settings.setVisual("avatarSize",size)
                        Services.Settings.setVisual("profileGreetingSize",font)
                        Services.Settings.setVisual("profileWeatherSize",font===12?10:20)
                        Services.Settings.setVisual("profileThirdLineSize",font===12?10:20)
                        Services.Settings.setValue("profile","subtitleMode",third?"custom":"greeting")
                        Services.Settings.setValue("profile","subtitle","Optional line")
                        Services.Settings.setValue("appearance","profileBackground",{enabled:background,role:"elevated"});wait(15)
                        const avatar=findChild(profile,"runtimeAvatar"), text=findChild(profile,"profileTextStack")
                        compare(profile.height,Math.max(avatar.height,text.implicitHeight)+2*profile.contentPadding)
                        centered(avatar,text,profile)
                        verify(text.height===text.implicitHeight)
                    }
                    for(const size of [48,112]) for(const available of [false,true]) for(const mode of ["always","active","hidden"]) {
                        Services.Settings.setVisual("mediaArtworkSize",size)
                        Services.Media.available=available;Services.Media.title="Long title ".repeat(80);Services.Media.artist="Long artist ".repeat(80)
                        Services.Settings.setValue("media","controlsVisibility",mode);wait(20)
                        const art=findChild(media,"runtimeAlbumArt"), stack=findChild(media,"mediaMetadataStack")
                        compare(media.height,Math.max(art.height,stack.implicitHeight)+2*media.contentPadding)
                        centered(art,stack,media);compare(stack.height,stack.implicitHeight)
                        verify(stack.x+stack.width<=media.width-media.contentPadding+1)
                    }
                }
                Services.SettingsWindowState.open();wait(150)
                const content=hub.content.currentContent
                compare(hub.mask.regions[1].width,0,"ordinary desktop input passes through")
                Services.SettingsWindowState.page="Date & time";wait(50)
                const themeChoice=findChild(content,"settingsSelector-First day of week")
                themeChoice.popup.open();wait(30)
                compare(hub.mask.regions[1].width,hub.width,"child popup owns its extended input")
                themeChoice.popup.close();wait(150)
                compare(hub.mask.regions[1].width,0)

                for(const size of [Qt.size(800,768),Qt.size(1280,900)]) {
                    hub.contentItem.Window.window.width=size.width;hub.contentItem.Window.window.height=size.height;wait(60)
                    const sidebar=findChild(content,"settingsSidebar"), save=findChild(content,"settingsSavePanel"), status=findChild(content,"settingsSaveStatus")
                    compare(sidebar.color,Theme.Theme.elevated);verify(sidebar.radius>0)
                    verify(save.mapToItem(sidebar,0,0).y+save.height<=sidebar.height)
                    verify(save.width<sidebar.width)
                    tryCompare(Services.Settings,"saveState","saved")
                    compare(status.text,"All changes saved")
                    Services.Settings.setValue("profile","displayName","Save indicator "+size.width)
                    compare(Services.Settings.saveState,"pending");wait(10);compare(status.text,"Saving…")
                    tryCompare(Services.Settings,"saveState","saved")
                    verify(!Services.Settings.setValue("hub","verticalPosition",2))
                    wait(20);verify(status.text.length>0);compare(status.color,Theme.Theme.red)
                    Services.Settings.setValue("hub","verticalPosition",2/3)
                    tryCompare(Services.Settings,"saveState","saved")
                    for(const name of ["Appearance","Profile","Date & time","Notifications","Clipboard","Launcher","Emoji","Wallpaper","Security"]) {
                        Services.SettingsWindowState.page=name;wait(20)
                        const nav=findChild(content,"settingsNav-"+name)
                        verify(nav.checked && nav.iconRole.length>0)
                        compare(findChild(nav,"settingsNavigationIcon").color,Theme.Theme.accent)
                        compare(findChild(nav,"settingsNavigationText").color,Theme.Theme.accent)
                        verify(findChild(nav,"settingsSelectionDot")===null)
                    }
                    Services.SettingsWindowState.page="Control Centre";wait(50)
                    const nav=findChild(content,"settingsNav-Control Centre");verify(nav.checked)
                    const page=findChild(content,"settingsPage-Control Centre")
                    const runtime=JSON.stringify(Services.Settings.data)
                    page.mode="Appearance"
                    for(const family of ["profile","controls","sliders","actions","media"]) {
                        page.selection.select(family);wait(0)
                        const sections=collect(page, item => item.visible && item.collapsible === true && item.expanded !== undefined)
                        verify(sections.length > 0, family+" disclosures")
                        for (const section of sections) {
                            const button=collect(section, item => item.text !== undefined && item.clicked !== undefined && item.text.startsWith(section.title+"  "))[0]
                            verify(button !== undefined, "Keyboard disclosure exists")
                            const editor=findChild(page,"controlCentreEditor")
                            editor.contentY=Math.max(0,button.mapToItem(editor.contentItem,0,0).y-30)
                            const expanded=section.expanded
                            button.forceActiveFocus();keyClick(Qt.Key_Space);wait(0)
                            compare(section.expanded,!expanded)
                            compare(JSON.stringify(Services.Settings.data),runtime)
                            keyClick(Qt.Key_Space);compare(section.expanded,expanded)
                        }
                    }
                }
                // Another application window may take focus without closing any mode.
                for(const mode of Services.Hub.modes) {
                    Services.Hub.open(mode);wait(30)
                    mouseClick(hub.contentItem,8,80);verify(Services.Hub.opened)
                    sample.contentItem.Window.window.requestActivate();number.forceActiveFocus();wait(20)
                    verify(Services.Hub.opened && Services.Hub.mode===mode)
                }
                Services.Hub.open("apps");Services.Hub.open("settings");compare(Services.Hub.mode,"settings")
                verify(Services.SettingsWindowState.shown)
                Services.Hub.close()
                console.log("Phase 2E.1 feedback PASS")
            } catch(error) { console.error("FAIL:",error,error.stack) }
            finally { finish.start() }
        }
    }
}
