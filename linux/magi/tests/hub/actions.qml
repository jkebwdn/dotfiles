import QtQuick
import QtTest
import Quickshell
import "../../.config/quickshell/magi/services" as Services
import "../../.config/quickshell/magi/components/hub" as UI
ShellRoot {
    id: test
    UI.HubWindow { id: window }
    Timer { id: finish; interval: 100; onTriggered: Qt.quit() }
    TestCase {
        name: "HubActions"
        when: Services.Settings.ready && Services.Emoji.entries.length > 0
        function test_selection() {
            Services.Launcher.open()
            tryVerify(() => Services.Launcher.applications.length > 0)
            Services.Launcher.query = "MAGI Hub launch fixture"
            compare(Services.Launcher.results.length, 1)
            window.content.currentContent.navigate(Qt.Key_Return, 0)
            tryCompare(Services.Hub, "opened", false)
            compare(Services.Launcher.error, "")
            compare(Services.Launcher.history["magi-hub-fixture.desktop"], 1)
            Services.Emoji.open()
            Services.Emoji.query = "woman technologist medium skin tone"
            compare(Services.Emoji.results[0].emoji, "👩🏽‍💻")
            window.content.currentContent.navigate(Qt.Key_Return, 0)
            tryCompare(Services.Hub, "opened", false)
            compare(Services.Emoji.error, "")
            // Actual model/card actions with a controlled notification action object.
            test.sample = recordComponent.createObject(test)
            Services.Notifications.records = [test.sample]
            Services.Notifications.open()
            compare(Services.Notifications.history.length, 1)
            const history = findChild(window.content.currentContent, "notificationHistory")
            tryVerify(() => history.itemAtIndex(0) !== null)
            const card = history.itemAtIndex(0)
            verify(card !== null)
            mouseClick(card, 100, 70)
            compare(test.invoked, true)
            Services.Notifications.dismiss(9001)
            compare(Services.Notifications.history.length, 0)
            Services.Hub.close()
            Services.Clipboard.activate()
            Services.Clipboard.open()
            tryCompare(Services.Clipboard, "ready", true)
            Services.Clipboard.query = "hub sample"
            tryCompare(Services.Clipboard, "renderedQuery", "hub sample")
            compare(Services.Clipboard.rows.length, 1)
            const content = window.content.currentContent
            content.select(0)
            content.navigate({key:Qt.Key_Return, modifiers:0, accepted:false})
            tryCompare(Services.Hub, "opened", false)
            compare(Services.Clipboard.error, "")
            console.log("Hub actions PASS: desktop launch, exact emoji copy, notification history/default action/dismiss, clipboard search/restore dismissal")
            finish.start()
        }
    }
    property bool invoked: false
    QtObject {
        id: action
        property string identifier: "default"
        function invoke() { test.invoked = true }
    }
    QtObject {
        id: liveNotification
        property var actions: [action]
        function dismiss() { test.sample.dismissed = true }
    }
    property var sample: null
    Component {
      id: recordComponent
      QtObject {
        property var notification: liveNotification
        property int notificationId: 9001
        property bool read: false
        property bool dismissed: false
        property bool hovered: false
        property double updatedAt: Date.now()
        property int remaining: 0
        property var data: ({id:9001, appName:"Hub fixture",summary:"Hub sample",body:"Synthetic notification",urgency:1,transient:false,actions:[{identifier:"default",text:"Open"}]})
      }
    }
}
