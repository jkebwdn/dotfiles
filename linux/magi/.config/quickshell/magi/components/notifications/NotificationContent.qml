pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts
import Quickshell
import "../../theme" as Theme
import "../../services" as Services
import "../controls" as Controls
import "../settings" as SettingsUI

FocusScope {
    id: root
    required property var service
    property bool embedded: false
    readonly property int contentInset: 14
    readonly property int sectionSpacing: 10
    // Measure the existing production delegates, including wrapped bodies/actions.
    // Large histories remain virtualized; Hub caps the surface and this view scrolls.
    implicitHeight: header.y + header.implicitHeight + contentInset
        + (history.count > 0 ? history.contentHeight : emptyState.implicitHeight + sectionSpacing)
        + contentInset
    function focusContent() { forceActiveFocus() }
    Rectangle {
        anchors.fill: parent
        color: root.embedded ? "transparent" : Theme.Theme.surface
        radius: Theme.Theme.radius("surface", 11, width, height)
        border.width: root.embedded ? 0 : 1; border.color: Theme.Theme.border
        focus: true
        Keys.onEscapePressed: root.service.centreOpen = false
        Column {
            id: header
            x: root.contentInset; y: root.contentInset; width: parent.width - 2 * root.contentInset; spacing: root.sectionSpacing
            RowLayout {
                width: parent.width; spacing: 8
                SettingsUI.SettingsToggle {
                    objectName: "hubNotificationsEnabled"
                    text: ""
                    Accessible.name: "Notifications enabled"
                    ToolTip.visible: hovered
                    ToolTip.delay: 400
                    ToolTip.text: checked ? "Disable notifications" : "Enable notifications"
                    checked: root.service.preferences.enabled
                    onClicked: Services.Settings.setValue("notifications", "enabled", checked)
                }
                Item { Layout.fillWidth: true }
                Controls.IconButton {
                    objectName: "hubNotificationsDnd"
                    role: "dnd"; label: root.service.preferences.dnd ? "Disable Do Not Disturb" : "Enable Do Not Disturb"
                    highlightedState: root.service.preferences.dnd
                    checkable: true; checked: root.service.preferences.dnd
                    enabled: root.service.serverActivated
                    onClicked: Services.QuickActions.setDnd(!root.service.preferences.dnd)
                }
                Controls.IconButton {
                    objectName: "hubNotificationsClear"
                    role: "delete"; label: "Clear all notifications"
                    enabled: root.service.history.length > 0
                    onClicked: root.service.clear()
                }
            }
            Text {
                visible: !root.service.serverActivated
                width: parent.width; wrapMode: Text.Wrap
                text: "Notifications aren't active yet."
                color: Theme.Theme.subtext; font.pixelSize: 11
            }
        }
        ListView {
            id: history
            objectName: "notificationHistory"
            x: root.contentInset; y: header.y + header.height + root.contentInset
            width: parent.width - 2 * root.contentInset; height: Math.max(0, parent.height - y - root.contentInset)
            clip: true; spacing: root.sectionSpacing
            boundsBehavior: Flickable.StopAtBounds
            model: root.service.history
            ScrollBar.vertical: ScrollBar {}
            delegate: NotificationCard {
                required property var modelData
                width: history.width
                height: implicitHeight
                record: modelData; service: root.service; historyCard: true
                showBody: root.service.preferences.showBody
            }
            Column {
                id: emptyState
                anchors.centerIn: parent
                width: parent.width - 32; spacing: root.sectionSpacing
                visible: history.count === 0
                Controls.Icon { anchors.horizontalCenter: parent.horizontalCenter; role: "notifications"; size: 28; color: Theme.Theme.subtext }
                Text {
                    width: parent.width
                    text: !root.service.preferences.enabled ? "Notifications paused" : "All caught up"
                    horizontalAlignment: Text.AlignHCenter; wrapMode: Text.Wrap
                    color: Theme.Theme.text; font.family: Theme.Theme.fontFamily; font.pixelSize: 14; font.bold: true
                }
                Text {
                    width: parent.width
                    text: !root.service.preferences.enabled ? "Turn notifications on to receive new messages."
                        : "Your notifications will appear here."
                    horizontalAlignment: Text.AlignHCenter; wrapMode: Text.Wrap
                    color: Theme.Theme.subtext; font.family: Theme.Theme.fontFamily; font.pixelSize: 12
                }
            }
        }
    }
}
