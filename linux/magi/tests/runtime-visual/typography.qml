import QtQuick
import QtQuick.Window
import QtTest
import Quickshell
import "../../.config/quickshell/magi/components/hub" as HubUI
import "../../.config/quickshell/magi/components/settings" as SettingsUI
import "../../.config/quickshell/magi/components/controls" as Controls
import "../../.config/quickshell/magi/plugins/bar/controlcentre" as Centre
import "../../.config/quickshell/magi/services" as Services
import "../../.config/quickshell/magi/theme" as Theme
ShellRoot {
    HubUI.HubWindow { id: hub }
    FloatingWindow {
        id: sample
        visible: true; implicitWidth: 700; implicitHeight: 700
        Centre.ProfileHeader { id: profile; width: 400; height: implicitHeight }
        Centre.MediaSection { id: media; y: 200; width: 400; height: implicitHeight }
        SettingsUI.SettingsToggle { id: toggle; y: 470; width: 240; text: "Test switch" }
        Controls.CompactToggle { id: compact; x: 300; y:470 }
        SettingsUI.SettingsNavigationItem { id: nav; y:520; width:200; text:"Profile"; iconRole:"profile"; checked:true }
        SettingsUI.SettingsNavigationItem { id: inactive; x:240; y:520; width:200; text:"Appearance"; iconRole:"settings" }
        SettingsUI.SettingsNavigationItem { id: subsection; y:570; width:200; text:"Theme"; subsection:true; checked:true }
    }
    Timer { id: finish; interval:100; onTriggered:Qt.quit() }
    TestCase {
        name:"TypographyNavigationToggle"; when:Services.Settings.ready
        function centered(a,b,parent) {
            verify(Math.abs(a.mapToItem(parent,0,0).y+a.height/2-b.mapToItem(parent,0,0).y-b.height/2)<=1)
        }
        function test_presentation() {
            try {
                for(const theme of ["catppuccin-mocha","everforest-dark-hard","everforest-light-hard"]) {
                    Services.Settings.setTheme(theme)
                    for(const role of ["accent","red","teal","text"]) {
                        Services.Settings.setValue("appearance","navigationAccent",role);wait(10)
                        compare(findChild(nav,"settingsNavigationIcon").color,Theme.Theme.roles[role])
                        compare(findChild(nav,"settingsNavigationText").color,Theme.Theme.roles[role])
                        compare(findChild(inactive,"settingsNavigationIcon").color,Theme.Theme.subtext)
                        compare(findChild(subsection,"settingsNavigationText").color,Theme.Theme.accent)
                        sample.contentItem.Window.window.requestActivate();wait(10)
                        inactive.forceActiveFocus(Qt.TabFocusReason);wait(5)
                        verify(inactive.activeFocus && !inactive.checked)
                        compare(findChild(inactive,"settingsNavigationText").color,Theme.Theme.text)
                        Services.Hub.open("apps");wait(15)
                        const button=hub.content.modeButtons.itemAt(0)
                        compare(findChild(button,"hubModeIcon").color,Theme.Theme.hubToggleColor)
                        compare(findChild(button,"hubSelectionDot"),null)
                        Services.Hub.close()
                    }
                    sample.contentItem.Window.window.requestActivate();wait(20)
                    for(const style of ["pill","filled","minimal"]) {
                        Services.Settings.setValue("appearance","toggleStyle",style);wait(10)
                        for(const control of [toggle,compact]) {
                            compare(control.toggleStyle,style)
                            control.enabled=true;control.checked=false
                            mouseMove(control,10,10);wait(5);verify(control.hovered)
                            mouseClick(control,10,10);compare(control.checked,true)
                            inactive.forceActiveFocus(Qt.TabFocusReason);control.forceActiveFocus(Qt.TabFocusReason);wait(5);keyClick(Qt.Key_Space);compare(control.checked,false)
                            verify(control.visualFocus);compare(findChild(control,"toggleFocus").border.width,1)
                            control.enabled=false;mouseClick(control,10,10);keyClick(Qt.Key_Space);compare(control.checked,false)
                            control.checked=true;mouseClick(control,10,10);compare(control.checked,true)
                            verify(control.opacity<1);control.enabled=true
                        }
                    }
                    Services.Settings.setValue("profile","displayName","jkebwdn")
                    for(const weight of [400,700]) for(const size of [48,112]) for(const third of [false,true]) {
                        Services.Settings.setVisual("avatarSize",size)
                        Services.Settings.setVisual("profileGreetingSize",weight===400?12:24)
                        Services.Settings.setVisual("profileWeatherSize",weight===400?10:20)
                        Services.Settings.setVisual("profileThirdLineSize",weight===400?10:20)
                        for(const key of ["profileGreetingWeight","profileWeatherWeight","profileThirdLineWeight"]) Services.Settings.setVisual(key,weight)
                        Services.Settings.setValue("profile","subtitleMode",third?"custom":"greeting")
                        Services.Settings.setValue("profile","subtitle","An unusually long third line ".repeat(15))
                        wait(10)
                        const avatar=findChild(profile,"runtimeAvatar"),stack=findChild(profile,"profileTextStack")
                        compare(profile.height,Math.max(avatar.height,stack.implicitHeight)+profile.contentPadding*2);centered(avatar,stack,profile)
                        for(const id of ["profileGreeting","profileWeather","profileThirdLine"]) compare(findChild(profile,id).font.weight,weight)
                    }
                    profile.localHour=15
                    Services.Settings.setValue("profile","greetingStyle","compact");wait(10)
                    compare(findChild(profile,"profileGreeting").text,"Afternoon, jkebwdn")
                    Services.Settings.setValue("profile","greetingStyle","friendly");wait(10)
                    compare(findChild(profile,"profileGreeting").text,"Good Afternoon jkebwdn")
                    for(const titleSize of [10,24]) for(const artistSize of [10,20]) for(const weight of [400,700]) for(const artSize of [48,112]) {
                        Services.Settings.setVisual("mediaTitleSize",titleSize);Services.Settings.setVisual("mediaArtistSize",artistSize)
                        Services.Settings.setVisual("mediaTitleWeight",weight);Services.Settings.setVisual("mediaArtistWeight",weight===400?700:400)
                        Services.Settings.setVisual("mediaArtworkSize",artSize)
                        Services.Media.title="A long title ".repeat(40);Services.Media.artist="A long artist ".repeat(40)
                        for(const mode of ["always","active","hidden"]) {
                            Services.Settings.setValue("media","controlsVisibility",mode)
                            for(const available of [false,true]) {
                                Services.Media.available=available;Services.Media.playing=available;wait(5)
                                const art=findChild(media,"runtimeAlbumArt"),stack=findChild(media,"mediaMetadataStack")
                                compare(media.height,Math.max(art.height,stack.implicitHeight)+media.contentPadding*2);centered(art,stack,media)
                                compare(findChild(media,"mediaTitle").font.pixelSize,titleSize)
                                compare(findChild(media,"mediaArtist").font.pixelSize,artistSize)
                                compare(findChild(media,"mediaTitle").font.weight,weight)
                                verify(stack.width>0 && stack.x+stack.width<=media.width)
                                for(const width of [0,2,5]) {
                                    const progress=art.progress
                                    Services.Settings.setVisual("mediaProgressBorderWidth",width);wait(1)
                                    compare(art.borderWidth,width);compare(art.progress,progress)
                                    const bounds=findChild(art,"artworkImageBounds")
                                    compare(bounds.x,width);compare(bounds.width,art.width-2*width)
                                }
                            }
                        }
                    }
                }
                Services.Media.available=true
                const art=findChild(media,"runtimeAlbumArt")
                for(const playing of [true,false]) for(const progress of [0,.43,.99]) for(const roundness of [0,2]) {
                    Services.Media.playing=playing;Services.Media.progress=progress
                    Services.Settings.setRoundness("albumArt",roundness)
                    for(const width of [0,2,5]) {
                        Services.Settings.setVisual("mediaProgressBorderWidth",width);wait(5)
                        compare(art.progress,progress);compare(Services.Media.progress,progress)
                        const mask=findChild(art,"artworkMask")
                        compare(mask.radius,Math.max(0,art.outerRadius-width))
                        verify(mask.width>0 && mask.height>0)
                    }
                }
                console.log("Phase 2E.2 typography navigation toggles PASS")
            } catch(error) { console.error("FAIL:",error,error.stack) }
            finally { finish.start() }
        }
    }
}
