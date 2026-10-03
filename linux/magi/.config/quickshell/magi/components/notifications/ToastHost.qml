pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import Quickshell.Wayland

PanelWindow {
    id: root
    required property var service
    property bool suppressed: false
    property var inputItems: []
    function syncInputItems() {
        const items = []
        for (let i = 0; i < stack.count; ++i) if (stack.itemAt(i)) items.push(stack.itemAt(i))
        inputItems = items
    }
    anchors { top: true; right: true }
    margins { top: 62; right: 14 }
    implicitWidth: Math.min(370, screen ? screen.width - 28 : 370)
    implicitHeight: Math.max(1, screen ? screen.height - 76 : 900)
    // Ignore already means no reservation; exclusiveZone would reset this mode.
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.namespace: "magi-toasts"
    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    color: "transparent"
    visible: !suppressed && service.toasts.count > 0
    // Union of the painted, non-exiting cards only. No stack bounding-box mask.
    mask: Region {
        regions: toastRegions.instances
    }
    Variants {
        id: toastRegions
        model: root.inputItems
        delegate: Region {
            required property var modelData
            readonly property bool interactive: root.visible && modelData && !modelData.exiting
            // Region.item observes the card, not its moving ancestor. Explicit
            // window-local geometry also follows the wrapper's animated reflow.
            x: modelData ? Math.floor(modelData.x + modelData.inputItem.x) : 0
            y: modelData ? Math.floor(modelData.y + modelData.inputItem.y) : 0
            width: interactive ? Math.ceil(modelData.inputItem.width) : 0
            height: interactive ? Math.ceil(modelData.inputItem.height) : 0
            radius: modelData ? modelData.inputItem.radius : 0
        }
    }
    Column {
        width: parent.width
        spacing: 10
        move: Transition { NumberAnimation { properties: "y"; duration: 180; easing.type: Easing.OutCubic } }
        Repeater {
            id: stack
            model: root.service.toasts
            onItemAdded: Qt.callLater(root.syncInputItems)
            onItemRemoved: Qt.callLater(root.syncInputItems)
            delegate: Item {
                id: wrapper
                required property int notificationId
                required property bool exiting
                required property int index
                readonly property var record: root.service.find(notificationId)
                readonly property Item inputItem: card
                width: root.width
                height: card.implicitHeight
                opacity: 0
                Component.onCompleted: opacity = Qt.binding(() => exiting ? 0 : 1)
                Behavior on opacity { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }
                enabled: !exiting
                NotificationCard {
                    id: card
                    width: parent.width
                    height: implicitHeight
                    x: (1 - wrapper.opacity) * 24
                    record: wrapper.record
                    service: root.service
                    showBody: root.service.preferences.showBody
                }
            }
        }
    }
}
