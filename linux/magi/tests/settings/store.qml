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
                } else test.check(store.data.schemaVersion === 9 && store.saveState === "saved", "safe initial load")
                if (Quickshell.env("MAGI_TEST_LEGACY") === "1")
                    test.check(store.data.bar.left.join(",") === "date,clock"
                        && store.data.bar.center.length === 0 && store.data.custom === 42,
                        "migration preserves order, empty placement and unknown fields")
                test.check(store.setVisual("statusIconSize", 24) && store.setVisual("sliderFill", "blue"), "visual settings accepted")
                test.check(!store.setVisual("statusIconSize", 90) && !store.setVisual("sliderFill", "not-a-role"), "visual bounds enforced")
                test.check(store.setTheme("everforest-dark-hard"), "set theme")
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
                test.check(store.data.appearance.theme === "catppuccin-mocha" && store.data.bar.right.length === 2, "section reset isolation")
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
                test.check(store.data.bar.right.length === 6 && store.saveState === "saved", "full reset persisted")
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
