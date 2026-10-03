import QtQuick
import Quickshell
import "../../.config/quickshell/magi/services" as Services
import "../../.config/quickshell/magi/components/notifications" as UI
import "../../.config/quickshell/magi/settings/SettingsSchema.js" as Schema
ShellRoot {
    id: test
    property int step: 0
    property int failures: 0
    property var firstDelegate: null
    property var thirdDelegate: null
    function check(ok, label) { if (!ok) { failures++; console.error("FAIL: " + label) } }
    Services.NotificationModel {
        id: service
        property bool serverActivated: true
        preferences: Schema.defaults().notifications
    }
    QtObject {
        id: record
        property var notification: null
        property var data: ({id:1,appName:"MAGI test",summary:"Compact notification",body:"A bounded preview",actions:[],urgency:1})
        property int notificationId: 1
        property bool hovered: false
        property bool dismissed: false
        property bool read: false
        property double updatedAt: Date.now()
    }
    Component {
        id: recordComponent
        QtObject {
            property var notification: null
            property var data: ({})
            property int notificationId: 0
            property bool hovered: false
            property bool dismissed: false
            property bool read: false
            property double updatedAt: Date.now()
        }
    }
    UI.ToastHost { id: host; service: service; suppressed: service.fullscreen }
    UI.NotificationCentre { id: centre; service: service; suppressed: service.fullscreen }
    Timer {
        interval: 450; running: true; repeat: true
        onTriggered: {
            switch (test.step++) {
            case 0:
                service.records = [record, recordComponent.createObject(test, {notificationId:2,
                    data:{id:2,appName:"Second",summary:"Second notification",body:"Body",actions:[],urgency:1}}),
                    recordComponent.createObject(test, {notificationId:3,
                    data:{id:3,appName:"Third",summary:"Third notification",body:"Body",actions:[],urgency:1}})]
                service.toasts.append({notificationId:1,exiting:false,exitAt:0})
                service.toasts.append({notificationId:2,exiting:false,exitAt:0})
                service.toasts.append({notificationId:3,exiting:false,exitAt:0})
                break
            case 1:
                test.check(host.visible && host.inputItems.length === 3, "three visible toasts")
                test.check(host.mask.regions.length === 3 && host.mask.regions.every(r => r.width > 0), "card input only")
                test.check(host.inputItems[0].height < 220, "compact bounded card")
                test.firstDelegate = host.inputItems[0]
                test.thirdDelegate = host.inputItems[2]
                service.hideToast(2)
                test.check(host.mask.regions[1].width === 0, "exiting card immediately loses input")
                break
            case 2:
                test.check(host.inputItems.length === 2 && host.inputItems[0] === test.firstDelegate
                    && host.inputItems[1] === test.thirdDelegate, "removal retains surviving delegates")
                test.check(host.mask.regions.length === 2 && host.mask.regions[1].y === Math.floor(test.thirdDelegate.y), "mask follows reflowed ancestor")
                test.check(host.mask.regions[0].y + host.mask.regions[0].height < host.mask.regions[1].y, "stack gap excluded from input")
                record.data = Object.assign({}, record.data, {summary:"Updated without duplication",body:"long body ".repeat(300)})
                break
            case 3:
                test.check(host.inputItems.length === 2 && host.inputItems[0] === test.firstDelegate, "update preserves card identity")
                test.check(host.inputItems[0].height < 260, "long body stays bounded")
                test.check(host.mask.regions[1].y === Math.floor(test.thirdDelegate.y), "growth reflow updates mask")
                service.fullscreen = true
                break
            case 4:
                test.check(!host.visible, "fullscreen unmaps toast window")
                test.check(host.mask.regions.every(r => r.width === 0), "fullscreen clears input")
                service.fullscreen = false
                service.centreOpen = true
                break
            case 5:
                test.check(centre.visible && service.unread === 0, "centre opens and marks read")
                service.centreOpen = false
                console.log("RESULT: " + test.failures + " failures; real toast/centre geometry state")
                Qt.quit()
            }
        }
    }
}
