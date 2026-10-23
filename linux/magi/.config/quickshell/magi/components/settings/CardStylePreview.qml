import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts
import "../notifications" as Notifications
import "../clipboard" as Clipboard
import "../../theme" as Theme

// Only deterministic local data and an inert service; no live notifications/clipboard.
ColumnLayout {
    id: root
    property bool clipboard: false
    property bool compact: false
    Layout.fillWidth: true
    QtObject {
        id: sample
        property var data: ({
                id: "preview",
                appName: "MAGI",
                summary: "A quiet workspace",
                body: "Everything you need, right where you left it.",
                actions: []
            })
        property var notification: null
        property double updatedAt: 1792756800000
        property bool hovered: false
    }
    QtObject {
        id: inert
        function dismiss(id) {
        }
        function invoke(id, action) {
        }
    }
    Repeater {
        model: root.clipboard ? 0 : root.compact ? 1 : 2
        ColumnLayout {
            required property int index
            Layout.fillWidth: true
            Label {
                text: index || root.compact ? "History" : "Toast"
                color: Theme.Theme.subtext
            }
            Notifications.NotificationCard {
                objectName: "notificationStylePreview"
                Layout.fillWidth: true
                Layout.preferredHeight: implicitHeight
                historyCard: parent.index === 1 || root.compact
                record: sample
                service: inert
                // Interaction is blocked without dimming the actual presenter.
                MouseArea {
                    anchors.fill: parent
                    z: 10
                }
            }
        }
    }
    Clipboard.ClipboardCardFrame {
        visible: root.clipboard
        Layout.fillWidth: true
        Layout.preferredHeight: 100
        Column {
            anchors.fill: parent
            anchors.margins: 14
            spacing: 10
            Label {
                text: "Pinned · Text · 12:00"
                color: Theme.Theme.accent
            }
            Label {
                text: "A sample clipboard note"
                color: Theme.Theme.text
            }
            Label {
                text: "Preview only — no clipboard access"
                color: Theme.Theme.subtext
            }
        }
    }
}
