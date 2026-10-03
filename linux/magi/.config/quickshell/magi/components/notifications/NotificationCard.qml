pragma ComponentBehavior: Bound
import QtQuick
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
    implicitHeight: content.implicitHeight + 28
    color: Theme.Theme.surface
    radius: Theme.Theme.radius("surface", 12, width, height)
    border.width: 1
    border.color: entry.urgency === 2 ? Theme.Theme.danger : Theme.Theme.border
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
    Column {
        id: content
        x: 14; y: 14; width: parent.width - 28
        spacing: 8
        Row {
            width: parent.width
            spacing: 8
            Item {
                width: 20; height: 20
                Image {
                    id: appIcon
                    anchors.fill: parent
                    source: {
                        const icon = root.entry.appIcon || ""
                        if (!icon) return ""
                        if (icon.startsWith("/")) return "file://" + icon
                        if (icon.startsWith("file:") || icon.startsWith("image://")) return icon
                        return icon.indexOf(":") < 0 ? Quickshell.iconPath(icon, true) : ""
                    }
                    sourceSize: Qt.size(40, 40)
                    fillMode: Image.PreserveAspectFit
                    visible: status === Image.Ready
                }
                Controls.Icon { anchors.centerIn: parent; role: "notifications"; size: 18; visible: !appIcon.visible; color: Theme.Theme.subtext }
            }
            Text {
                width: parent.width - 60; height: 20
                text: root.entry.appName || "Notification"
                textFormat: Text.PlainText
                color: Theme.Theme.subtext; font.family: Theme.Theme.fontFamily; font.pixelSize: 11
                elide: Text.ElideRight; verticalAlignment: Text.AlignVCenter
            }
            Item {
                width: 24; height: 20
                Controls.Icon { anchors.centerIn: parent; role: "close"; size: 14; color: Theme.Theme.stateColor("secondary", true) }
                MouseArea { anchors.fill: parent; onClicked: root.service.dismiss(root.entry.id) }
                Accessible.name: "Dismiss notification"; Accessible.role: Accessible.Button
            }
        }
        Text {
            width: parent.width
            text: root.entry.summary || ""
            textFormat: Text.PlainText
            color: Theme.Theme.text; font.family: Theme.Theme.fontFamily; font.pixelSize: 13; font.bold: true
            maximumLineCount: 2; wrapMode: Text.Wrap; elide: Text.ElideRight
            visible: text.length > 0
        }
        Row {
            width: parent.width
            spacing: 10
            Image {
                id: artwork
                width: visible ? 48 : 0; height: 48
                source: root.entry.image && /^(file:|image:\/\/)/.test(root.entry.image) ? root.entry.image : ""
                sourceSize: Qt.size(96, 96); fillMode: Image.PreserveAspectFit
                visible: source.toString().length > 0 && status !== Image.Error
            }
            Text {
                width: parent.width - (artwork.visible ? 58 : 0)
                text: root.showBody ? (root.entry.body || "") : ""
                visible: text.length > 0
                textFormat: Text.PlainText
                color: Theme.Theme.subtext; font.family: Theme.Theme.fontFamily; font.pixelSize: 12
                maximumLineCount: root.historyCard ? 4 : 3; wrapMode: Text.Wrap; elide: Text.ElideRight
            }
            visible: artwork.visible || (root.showBody && !!root.entry.body)
        }
        Flow {
            width: parent.width; spacing: 6
            visible: root.actions.length > 0
            Repeater {
                model: root.actions
                Rectangle {
                    id: action
                    required property var modelData
                    width: Math.min(content.width, Math.max(60, actionText.implicitWidth + 20)); height: 28
                    radius: Theme.Theme.radius("action", 6, width, height)
                    color: Theme.Theme.elevated
                    Text {
                        id: actionText; anchors.centerIn: parent; width: Math.min(implicitWidth, parent.width - 20)
                        text: action.modelData.text; textFormat: Text.PlainText; elide: Text.ElideRight
                        color: Theme.Theme.stateColor("secondary", true); font.family: Theme.Theme.fontFamily; font.pixelSize: 11
                    }
                    MouseArea { anchors.fill: parent; onClicked: root.service.invoke(root.entry.id, action.modelData.identifier) }
                    Accessible.name: modelData.text; Accessible.role: Accessible.Button
                }
            }
        }
        Text {
            visible: root.historyCard
            text: root.record ? Qt.formatDateTime(new Date(root.record.updatedAt), "ddd HH:mm") : ""
            color: Theme.Theme.muted; font.family: Theme.Theme.fontFamily; font.pixelSize: 10
        }
    }
}
