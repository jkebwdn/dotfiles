import QtQuick
import QtQuick.Window
import QtTest
import Quickshell
import "../../.config/quickshell/magi/services" as Services
import "../../.config/quickshell/magi/components/hub" as UI
ShellRoot {
    id: test
    UI.HubWindow { id: window }
    Timer { id: finish; interval: 100; onTriggered: Qt.quit() }
    Component {
        id: recordComponent
        QtObject {
            property var notification: null
            property int notificationId: 0
            property bool read: false
            property bool dismissed: false
            property double updatedAt: Date.now()
            property var data: ({})
        }
    }
    TestCase {
        name: "NotificationHubHeight"
        when: Services.Settings.ready
        function setHistory(count) {
            const records = []
            for (let i = 0; i < count; ++i)
                records.push(recordComponent.createObject(test, {
                    notificationId: i + 1,
                    updatedAt: Date.now() - i * 1000,
                    data: {id:i+1,appName:"Height fixture",summary:"Notification " + (i+1),
                        body:"Production card content. ".repeat(i % 3 + 1),urgency:1,actions:[]}
                }))
            const previous = Services.Notifications.records
            Services.Notifications.records = records
            for (const record of previous) record.destroy()
            wait(150)
        }
        function test_height() {
            try {
                // Synthetic availability only: do not claim the notification bus.
                Services.Notifications.serverActivated = true
                Services.Hub.open("notifications"); wait(80)
                const content = window.content.currentContent
                const history = findChild(content,"notificationHistory")
                const toggle = findChild(content,"hubNotificationsEnabled")
                compare(toggle.text, "")
                compare(toggle.Accessible.name, "Notifications enabled")
                for (const size of [Qt.size(1920,1080), Qt.size(1280,900), Qt.size(1024,768)]) {
                    window.contentItem.Window.window.width = size.width
                    window.contentItem.Window.window.height = size.height
                    setHistory(0)
                    compare(window.content.width,430)
                    const emptyHeight = window.content.surface.height
                    const emptyTop = window.content.y
                    const anchor = window.content.selectorPill.mapToItem(window.contentItem,0,0)
                    verify(emptyHeight < 300, "empty history is compact")
                    verify(history.height > 0)
                    setHistory(1)
                    verify(window.content.surface.height > emptyHeight, "one body-bearing card grows the surface")
                    setHistory(2)
                    const shortHeight = window.content.surface.height
                    verify(shortHeight > emptyHeight)
                    verify(window.content.y < emptyTop, "populated content grows upward")
                    compare(window.content.selectorPill.mapToItem(window.contentItem,0,0),anchor)
                    // All short-history delegates fit; size comes from their real implicit heights.
                    const first = history.itemAtIndex(0), second = history.itemAtIndex(1)
                    verify(first !== null && second !== null)
                    compare(history.contentHeight,first.implicitHeight + second.implicitHeight + history.spacing)
                    verify(Math.abs(history.height - history.contentHeight) <= 1, "no unused tall viewport for short history")
                    const beforeUpdate = window.content.surface.height
                    first.record.data = Object.assign({},first.record.data,{summary:"A wrapped summary ".repeat(12),body:"A longer body ".repeat(24)})
                    wait(150)
                    verify(window.content.surface.height > beforeUpdate, "replacement text remeasures production cards")
                    compare(window.content.selectorPill.mapToItem(window.contentItem,0,0),anchor)
                    setHistory(20)
                    const maximum = Math.min(640,window.selectorAnchorY - 64 - window.content.contentSelectorGap)
                    compare(window.content.surface.height,maximum)
                    verify(history.contentHeight > history.height, "full history overflows into the scroll view")
                    compare(window.content.selectorPill.mapToItem(window.contentItem,0,0),anchor)
                    history.positionViewAtEnd(); wait(120)
                    verify(history.contentY > 0 && history.atYEnd, "last notification remains reachable")
                    compare(window.content.surface.height,maximum, "scrolling cannot move the surface or selector")
                    compare(window.content.selectorPill.mapToItem(window.contentItem,0,0),anchor)
                    // Real clear action shrinks back to the empty state in place.
                    mouseClick(findChild(content,"hubNotificationsClear")); wait(150)
                    compare(history.count,0)
                    compare(window.content.surface.height,emptyHeight)
                    compare(window.content.y,emptyTop)
                    compare(window.content.selectorPill.mapToItem(window.contentItem,0,0),anchor)
                }
                console.log("Hub notification height PASS: no title, measured empty/short/replacement/full histories, stable selector, upward growth, bounded scrolling and Clear All")
            } catch(error) { console.error("FAIL:",error,error.stack) }
            finally { finish.start() }
        }
    }
}
