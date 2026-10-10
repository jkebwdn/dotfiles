import QtQuick
import Quickshell
import "../../.config/quickshell/magi/services" as Services
import "../../.config/quickshell/magi/components/hub" as UI
ShellRoot {
    id: test
    property int step: 0
    property var firstContent: null
    property var firstWindow: null
    property bool ready: true
    UI.HubWindow { id: window; readyToOpen: test.ready }
    function check(ok, label) { if (!ok) throw new Error("Hub step " + step + ": " + label) }
    function exclusive(mode) {
        check(Services.Hub.opened && Services.Hub.mode === mode, "active mode " + mode)
        check([Services.Launcher.opened, Services.Notifications.centreOpen, Services.Emoji.opened, Services.Clipboard.opened].filter(Boolean).length === 1, "one active utility")
        check(Services.MenuController.activeMenu === "", "no anchored menu")
    }
    Timer { id: finish; interval: 400; onTriggered: Qt.quit() }
    Timer {
        id: sequence
        interval: 150; running: true; repeat: true
        onTriggered: {
            if (!Services.Settings.ready || !Services.Emoji.entries.length) return
            switch (test.step++) {
            case 0:
                test.firstWindow = window
                test.check(!Services.Notifications.serverActivated && !Services.Clipboard.activated, "content must not activate backends")
                Services.Launcher.toggle(); test.exclusive("apps"); break
            case 1:
                test.check(window.visible && window.content.currentContent.searchField.activeFocus, "apps focus")
                test.firstContent = window.content.currentContent
                Services.Launcher.query = "retained query"
                Services.Emoji.toggle(); test.exclusive("emoji"); break
            case 2:
                test.check(window.visible && window === test.firstWindow, "stable window")
                test.check(window.content.currentContent.searchField.activeFocus, "emoji focus")
                Services.Emoji.query = "woman technologist medium skin tone"
                test.check(Services.Emoji.results[0].emoji === "👩🏽‍💻", "emoji exact sequence search")
                window.content.modeButtons.itemAt(0).clicked(); test.exclusive("apps"); break
            case 3:
                test.check(window.content.currentContent === test.firstContent, "retained content identity")
                test.check(Services.Launcher.query === "retained query", "within-session query")
                test.check(window.content.currentContent.searchField.activeFocus, "switcher focus")
                window.content.modeButtons.itemAt(1).clicked(); test.exclusive("notifications"); break
            case 4:
                test.check(window.content.currentContent.activeFocus, "notification surface focus")
                test.check(Services.Notifications.centreOpen, "history policy still knows centre is open")
                Services.Clipboard.toggle(); test.exclusive("clipboard"); break
            case 5:
                test.check(window.content.currentContent.searchField.activeFocus, "clipboard focus")
                Services.Clipboard.query = "sample"
                Services.Notifications.toggle(); test.exclusive("notifications")
                Services.Clipboard.toggle(); test.exclusive("clipboard")
                test.check(Services.Clipboard.query === "sample", "clipboard retains query")
                Services.Clipboard.toggle(); test.check(!window.visible, "same-mode shortcut closes")
                Services.Clipboard.opened = true; test.exclusive("clipboard")
                Services.Clipboard.opened = false; test.check(!Services.Hub.opened, "legacy property close")
                Services.Notifications.centreOpen = true; test.exclusive("notifications")
                Services.Notifications.centreOpen = false; test.check(!Services.Hub.opened, "legacy centre close")
                Services.Launcher.open(); test.check(Services.Launcher.query === "", "new session resets")
                Services.MenuController.open("controlcentre"); test.check(!window.visible, "Hub to CC")
                test.ready = false
                Services.Emoji.open(); test.exclusive("emoji")
                test.check(!window.visible, "wait for anchored collapse")
                test.ready = true; break
            case 6:
                test.check(window.visible, "CC to Hub after collapse")
                Services.Calendar.open(); test.check(!window.visible && Services.Calendar.opened, "Hub to Calendar")
                Services.Notifications.open(); test.exclusive("notifications")
                test.check(!Services.Calendar.opened, "Calendar to Hub")
                Services.Hub.suppressed = true
                test.check(!window.visible && !Services.Hub.opened, "fullscreen closes")
                for (const mode of Services.Hub.modes) { Services.Hub.open(mode); test.check(!Services.Hub.opened, "blocked over fullscreen") }
                Services.Hub.suppressed = false; test.check(!window.visible, "no unsolicited recovery")
                Services.Emoji.open(); test.exclusive("emoji"); break
            case 7:
                test.check(window.content.currentContent.searchField.activeFocus, "recovery focus")
                window.content.currentContent.navigate(Qt.Key_Escape, 0)
                test.check(!window.visible, "Escape closes shared host")
                Services.Hub.open("invalid"); test.check(!window.visible, "invalid mode rejected")
                Services.Launcher.open(); Services.SettingsWindowState.open()
                test.check(!window.visible, "Settings handoff")
                console.log("Hub integration PASS: direct modes, selector, retained identity/state, focus, toggles, legacy APIs, anchored handoff, suppression and Escape")
                sequence.stop(); finish.start()
            }
        }
    }
}
