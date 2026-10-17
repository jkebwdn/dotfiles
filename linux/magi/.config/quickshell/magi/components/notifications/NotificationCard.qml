pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls.Basic
import Quickshell
import "../../theme" as Theme
import "../controls" as Controls

Rectangle {
    id: root
    required property var record
    required property var service
    property bool historyCard: false
    property bool showBody: true
    readonly property var entry: record ? record.data : ({})
    readonly property var actions: record && record.notification
        ? (entry.actions || []).filter(a => a.identifier !== "default").slice(0, historyCard ? 16 : 3) : []
    readonly property bool defaultAction: record && record.notification
        && (entry.actions || []).some(a => a.identifier === "default")
    implicitHeight: Math.max(64, content.implicitHeight) + 28
    color: root.historyCard ? Theme.Theme.elevated : Theme.Theme.surface
    radius: Theme.Theme.radius("surface", 12, width, height)
    Controls.SurfaceBorder { z: 2; family: "notificationBorders"; surfaceId: root.historyCard ? "history" : "toasts"; radius: parent.radius }
    clip: true
    Accessible.name: (entry.appName || "") + ": " + (entry.summary || "")
    HoverHandler {
        onHoveredChanged: { if (root.record && !root.historyCard) root.record.hovered = hovered }
    }
    MouseArea {
        anchors.fill: parent
        enabled: root.defaultAction
        onClicked: root.service.invoke(root.entry.id, "default")
    }
    Item {
        id: leading
        objectName: "notificationLeadingVisual"
        x: 14; y: 14; width: 64; height: 64
        Controls.RoundedArtwork {
            id: artwork
            objectName: "notificationImage"
            anchors.fill: parent
            source: root.entry.image && /^(file:|image:\/\/)/.test(root.entry.image) ? root.entry.image : ""
            sourceSize: Qt.size(128,128)
            asynchronous: true; borderWidth: 0
            radius: Theme.Theme.radius("action", 8, width, height)
            visible: status === Image.Ready
        }
        Image {
            id: appIcon
            objectName: "notificationAppIcon"
            anchors.fill: parent
            source: {
                const icon = root.entry.appIcon || ""
                if (!icon) return ""
                if (icon.startsWith("/")) return "file://" + icon
                if (icon.startsWith("file:") || icon.startsWith("image://")) return icon
                return icon.indexOf(":") < 0 ? Quickshell.iconPath(icon, true) : ""
            }
            sourceSize: Qt.size(128,128); fillMode: Image.PreserveAspectFit
            visible: !artwork.visible && status === Image.Ready
        }
        Controls.Icon { anchors.centerIn: parent; role: "notifications"; size: 40; visible: !artwork.visible && !appIcon.visible; color: Theme.Theme.subtext }
        ToolTip.visible: leadingHover.hovered
        ToolTip.text: root.entry.appName || "Notification"
        HoverHandler { id: leadingHover }
    }
    Controls.IconButton {
        objectName: "notificationDismiss"
        anchors { right: parent.right; top: parent.top; margins: 8 }
        width: 24; height: 24
        role: "close"; label: "Dismiss notification"
        onClicked: root.service.dismiss(root.entry.id)
    }
    Column {
        id: content
        x: 90; y: 14; width: Math.max(0, parent.width - x - 36)
        spacing: 8
        Text {
            objectName: "notificationTitle"
            width: parent.width
            text: root.entry.summary || root.entry.appName || "Notification"
            textFormat: Text.PlainText
            color: Theme.Theme.text; font.family: Theme.Theme.fontFamily; font.pixelSize: 13; font.bold: true
            maximumLineCount: 2; wrapMode: Text.Wrap; elide: Text.ElideRight
        }
        Text {
            width: parent.width
            text: root.showBody ? (root.entry.body || "") : ""
            visible: text.length > 0
            textFormat: Text.PlainText
            color: Theme.Theme.subtext; font.family: Theme.Theme.fontFamily; font.pixelSize: 12
            maximumLineCount: root.historyCard ? 4 : 3; wrapMode: Text.Wrap; elide: Text.ElideRight
        }
        Text {
            visible: root.historyCard
            width: parent.width
            text: root.record ? Qt.formatDateTime(new Date(root.record.updatedAt), "ddd HH:mm") : ""
            color: Theme.Theme.subtext; font.family: Theme.Theme.fontFamily; font.pixelSize: 11
        }
        Flow {
            width: parent.width; spacing: 6
            visible: root.actions.length > 0
            Repeater {
                model: root.actions
                Button {
                    id: action
                    required property var modelData
                    objectName: "notificationAction-" + modelData.identifier
                    width: Math.min(content.width, Math.max(60, actionText.implicitWidth + 20)); height: 28
                    background: Rectangle {
                        radius: Theme.Theme.radius("action", 6, width, height)
                        color: action.hovered ? Theme.Theme.overlay : Theme.Theme.surface
                        border.width: action.activeFocus ? 1 : 0; border.color: Theme.Theme.focus
                    }
                    Text {
                        id: actionText; anchors.centerIn: parent; width: Math.min(implicitWidth, parent.width - 20)
                        text: action.modelData.text; textFormat: Text.PlainText; elide: Text.ElideRight
                        color: Theme.Theme.text; font.family: Theme.Theme.fontFamily; font.pixelSize: 11
                    }
                    onClicked: root.service.invoke(root.entry.id, action.modelData.identifier)
                    Accessible.name: modelData.text; Accessible.role: Accessible.Button
                }
            }
        }
    }
}
