import QtQuick
import Quickshell
import "../../.config/quickshell/magi/settings" as Config

ShellRoot {
    id: test
    property int step: 0
    property int failures: 0
    property int waits: 0
    property int notifications: 0
    Config.SettingsStore { id: store; path: Quickshell.env("MAGI_TEST_SETTINGS") }
    Connections { target: store; function onRevisionChanged() { test.notifications++ } }
    function check(ok, label) {
        if (!ok) { failures++; console.error("FAIL: " + label + " " + store.saveState + " " + store.error) }
    }
    Timer {
        interval: 400
        running: true
        repeat: true
        onTriggered: {
            if (!store.ready) return
            if ([1, 3, 5, 6, 7].indexOf(test.step) >= 0 && store.saveState === "pending" && test.waits++ < 25)
                return
            test.waits = 0
            switch (test.step++) {
            case 0:
                if (Quickshell.env("MAGI_TEST_INVALID") === "1") {
                    test.check(store.saveState === "invalid" && store.data.appearance.roundness.master === 1, "invalid fallback")
                    test.check(store.resetSection("appearance"), "explicit repair")
                } else test.check(store.data.schemaVersion === 12 && store.saveState === "saved", "safe initial load")
                if (Quickshell.env("MAGI_TEST_LEGACY") === "1")
                    test.check(store.data.bar.left.join(",") === "date,clock"
                        && store.data.bar.center.length === 0 && store.data.custom === 42,
                        "migration preserves order, empty placement and unknown fields")
                test.check(store.setVisual("statusIconSize", 24) && store.setVisual("sliderFill", "blue"), "visual settings accepted")
                test.check(!store.setVisual("statusIconSize", 90) && !store.setVisual("sliderFill", "not-a-role"), "visual bounds enforced")
                for (const entry of [["primaryIconSize",48],["primaryContainerSize",96],["secondaryIconSize",36],["avatarSize",112],["mediaArtworkSize",48]])
                    test.check(store.setVisual(entry[0], entry[1]), "CC appearance accepted " + entry[0])
                for (const entry of [["profileGreetingSize",24],["profileWeatherSize",20],["profileThirdLineSize",10],["profileControlsGap",0],["controlsSlidersGap",48],["slidersActionsGap",7],["actionsMediaGap",31]])
                    test.check(store.setVisual(entry[0], entry[1]), "type/gap accepted " + entry[0])
                test.check(!store.setVisual("profileGreetingSize",16.5), "integer font size enforced")
                for (const entry of [["profileGreetingWeight",400],["profileWeatherWeight",700],["profileThirdLineWeight",700],["mediaTitleSize",24],["mediaArtistSize",20],["mediaTitleWeight",400],["mediaArtistWeight",700],["mediaProgressBorderWidth",5]])
                    test.check(store.setVisual(entry[0],entry[1]),"final visual accepted "+entry[0])
                store.setValue("appearance","navigationAccent","teal");store.setValue("appearance","toggleStyle","minimal")
                store.setValue("profile","greetingStyle","friendly")
                store.setValue("weather","enabled",true);store.setValue("weather","location","Test town");store.setValue("weather","units","imperial")
                store.setRoundness("avatar", .5); store.setRoundness("albumArt", 2)
                test.check(store.setTheme("everforest-dark-hard"), "set theme")
                store.setValue("appearance","surfaceBorders",{role:"accent",width:3,controlcentre:true,wifi:true,bluetooth:true,hubContent:false,hubSelector:false})
                store.setValue("appearance","notificationBorders",{role:"text",width:0,toasts:false,history:true,clipboard:false})
                store.setValue("appearance","profileBackground",{enabled:true,role:"overlay"})
                store.setRoundness("hubSelector",.5)
                store.setValue("hub","selectorPosition","above")
                store.setValue("hub","verticalPosition",.35)
                store.setValue("media","controlsVisibility","always")
                store.setValue("notifications","retentionHours",24)
                test.check(store.editControl(store.data.controlCentre.controls[0].key, "accent", "red"), "semantic tile accent accepted")
                test.check(!store.editControl(store.data.controlCentre.controls[0].key, "accent", "rosewater"), "unsupported tile accent rejected")
                break
            case 1:
                test.check(store.saveState === "saved", "atomic save acknowledged")
                store.reload()
                break
            case 2:
                test.check(store.data.appearance.theme === "everforest-dark-hard", "save/reload")
                test.check(store.data.appearance.visual.statusIconSize === 24 && store.data.appearance.visual.sliderFill === "blue", "visual persistence reload")
                test.check(store.data.controlCentre.controls[0].accent === "red", "semantic tile accent persistence reload")
                for (const entry of [["primaryIconSize",48],["primaryContainerSize",96],["secondaryIconSize",36],["avatarSize",112],["mediaArtworkSize",48]])
                    test.check(store.data.appearance.visual[entry[0]] === entry[1], "CC size persisted " + entry[0])
                test.check(store.data.appearance.roundness.roles.avatar === .5 && store.data.appearance.roundness.roles.albumArt === 2, "independent artwork roundness persisted")
                for (const entry of [["profileGreetingSize",24],["profileWeatherSize",20],["profileThirdLineSize",10],["profileControlsGap",0],["controlsSlidersGap",48],["slidersActionsGap",7],["actionsMediaGap",31]])
                    test.check(store.data.appearance.visual[entry[0]] === entry[1], "type/gap persisted " + entry[0])
                test.check(store.data.appearance.surfaceBorders.width===3 && store.data.appearance.surfaceBorders.wifi,"shared border persistence")
                test.check(!store.data.appearance.notificationBorders.toasts && !store.data.appearance.notificationBorders.clipboard && store.data.appearance.notificationBorders.width===0,"notification border persistence")
                test.check(store.data.appearance.profileBackground.enabled && store.data.appearance.profileBackground.role==="overlay","profile background persistence")
                test.check(store.data.appearance.roundness.roles.hubSelector===.5 && store.data.hub.selectorPosition==="above" && store.data.hub.verticalPosition===.35,"Hub preference persistence")
                test.check(store.data.media.controlsVisibility==="always" && store.data.notifications.retentionHours===24,"media and retention persistence")
                for (const entry of [["profileGreetingWeight",400],["profileWeatherWeight",700],["profileThirdLineWeight",700],["mediaTitleSize",24],["mediaArtistSize",20],["mediaTitleWeight",400],["mediaArtistWeight",700],["mediaProgressBorderWidth",5]])
                    test.check(store.data.appearance.visual[entry[0]]===entry[1],"final visual persisted "+entry[0])
                test.check(store.data.appearance.navigationAccent==="teal" && store.data.appearance.toggleStyle==="minimal","navigation and toggle persistence")
                test.check(store.data.profile.greetingStyle==="friendly" && store.data.weather.enabled && store.data.weather.location==="Test town" && store.data.weather.units==="imperial","greeting/weather persistence")
                store.resetSection("weather");store.resetSection("profile")
                test.check(!store.data.weather.enabled && store.data.weather.location==="" && store.data.weather.units==="metric" && store.data.profile.greetingStyle==="compact","weather/greeting reset")
                store.resetSection("hub"); store.resetSection("media"); store.resetSection("notifications")
                test.check(store.data.hub.selectorPosition==="below" && store.data.hub.verticalPosition===2/3 && store.data.media.controlsVisibility==="active" && store.data.notifications.retentionHours===6,"new section resets")
                store.setRoundness("master", 0.1)
                store.save() // start a write, then supersede its in-flight snapshot
                for (let i = 0; i < 50; i++) store.setRoundness("master", i / 25)
                break
            case 3:
                test.check(store.saveState === "saved" && store.data.appearance.roundness.master === 1.96, "rapid latest wins")
                store.setValue("bar", "right", ["wifi", "controlcentre"])
                store.setValue("profile", "displayName", "Ada")
                store.setValue("profile", "subtitle", "Ready")
                store.setValue("profile", "avatar", "avatar:" + "a".repeat(64) + ".png")
                break
            case 4:
                store.resetSection("appearance")
                break
            case 5:
                test.check(store.data.appearance.surfaceBorders.width===1 && !store.data.appearance.surfaceBorders.wifi && store.data.appearance.notificationBorders.toasts && store.data.appearance.notificationBorders.clipboard && !store.data.appearance.profileBackground.enabled && store.data.appearance.roundness.roles.hubSelector===null,"shared appearance resets")
                test.check(store.data.appearance.theme === "catppuccin-mocha" && store.data.bar.right.length === 2, "section reset isolation")
                test.check(store.data.appearance.visual.primaryIconSize === 32 && store.data.appearance.visual.primaryContainerSize === 68
                    && store.data.appearance.visual.secondaryIconSize === 32 && store.data.appearance.visual.avatarSize === 76
                    && store.data.appearance.visual.mediaArtworkSize === 80 && store.data.appearance.roundness.roles.albumArt === null, "CC appearance resets")
                for (const entry of [["profileGreetingSize",16],["profileWeatherSize",12],["profileThirdLineSize",11],["profileControlsGap",20],["controlsSlidersGap",20],["slidersActionsGap",20],["actionsMediaGap",20]])
                    test.check(store.data.appearance.visual[entry[0]] === entry[1], "type/gap reset " + entry[0])
                test.check(store.data.profile.displayName === "Ada" && store.data.profile.subtitle === "Ready"
                    && store.data.profile.avatar.indexOf("avatar:") === 0, "profile live state and persistence")
                test.check(!store.setRoundness("master", -5), "reject invalid edit")
                test.check(store.setValue("notifications", "dnd", true)
                    && store.setValue("notifications", "maxVisible", 4)
                    && store.setValue("notifications", "historyLimit", 50), "notification edits accepted")
                break
            case 6:
                test.check(store.data.notifications.dnd && store.data.notifications.maxVisible === 4
                    && store.data.notifications.historyLimit === 50 && store.saveState === "saved", "notification settings persisted")
                store.discardAndReload()
                break
            case 7:
                test.check(store.data.notifications.dnd && store.data.notifications.maxVisible === 4
                    && store.data.notifications.historyLimit === 50, "notification settings reloaded")
                store.resetAll()
                break
            case 8:
                test.check(store.data.bar.right.length === 5 && store.saveState === "saved", "full reset persisted")
                test.check(store.data.controlCentre.controls.map(e => e.accent).join(",") === "teal,blue,green,lavender", "full reset restores tile accents")
                test.check(test.notifications >= 50, "live notifications")
                store.reload()
                break
            case 9:
                test.check(store.data.appearance.roundness.master === 1 && !store.dirty, "reset reload")
                console.log("RESULT: " + test.failures + " failures")
                Qt.quit()
            }
        }
    }
}
