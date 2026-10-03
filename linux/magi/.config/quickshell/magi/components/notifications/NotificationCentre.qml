pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls.Basic
import Quickshell
import Quickshell.Wayland
import "../../theme" as Theme
import "../../services" as Services
import "../controls" as Controls
import "../settings" as SettingsUI

PanelWindow {
    id: root
    required property var service
    property bool suppressed: false
    anchors { top: true; right: true }
    margins { top: 62; right: 14 }
    implicitWidth: Math.min(410, screen ? screen.width - 28 : 410)
    implicitHeight: Math.min(640, screen ? screen.height - 76 : 640)
    // Ignore already means no reservation; exclusiveZone would reset this mode.
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.namespace: "magi-notification-centre"
    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
    visible: service.centreOpen && !suppressed
    color: "transparent"
    onSuppressedChanged: { if (suppressed) service.centreOpen = false }
    Rectangle {
        anchors.fill: parent
        color: Theme.Theme.background
        radius: Theme.Theme.radius("surface", 14, width, height)
        border.width: 1; border.color: Theme.Theme.border
        focus: true
        Keys.onEscapePressed: root.service.centreOpen = false
        Column {
            id: header
            x: 14; y: 14; width: parent.width - 28; spacing: 10
            Row {
                spacing: 10; width: parent.width
                Controls.Icon { role: "notifications"; size: 22 }
                Text { width: parent.width - 70; text: "Notifications"; color: Theme.Theme.text; font.family: Theme.Theme.fontFamily; font.pixelSize: 17; font.bold: true }
                Item {
                    width: 28; height: 24
                    Controls.Icon { anchors.centerIn: parent; role: "close"; size: 16 }
                    TapHandler { onTapped: root.service.centreOpen = false }
                    Accessible.name: "Close Notification Centre"; Accessible.role: Accessible.Button
                }
            }
            Row {
                spacing: 10
                SettingsUI.SettingsButton {
                    text: root.service.preferences.dnd ? "DND on" : "DND off"
                    enabled: root.service.serverActivated
                    palette.buttonText: Theme.Theme.text
                    font.family: Theme.Theme.fontFamily
                    onClicked: Services.QuickActions.setDnd(!root.service.preferences.dnd)
                }
                SettingsUI.SettingsButton {
                    text: "Clear all"; enabled: root.service.history.length > 0
                    palette.buttonText: Theme.Theme.text
                    font.family: Theme.Theme.fontFamily
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
            x: 14; y: header.y + header.height + 14
            width: parent.width - 28; height: parent.height - y - 14
            clip: true; spacing: 10
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
            Text {
                anchors.centerIn: parent
                visible: history.count === 0
                text: "All caught up\nYour notifications will appear here."
                horizontalAlignment: Text.AlignHCenter
                color: Theme.Theme.subtext; font.family: Theme.Theme.fontFamily; font.pixelSize: 12
            }
        }
    }
}
