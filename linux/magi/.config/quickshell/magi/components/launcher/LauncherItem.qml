pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls.Basic
import "../../services" as Services
import "../../theme" as Theme
Rectangle {
    id: root
    required property var app
    required property var preferences
    property bool grid: false
    property bool selected: false
    property var iconPresentation: Services.LauncherIcons.resolve(app)
    signal chosen()
    signal contextRequested(real pointerX, real pointerY)
    radius: Theme.Theme.radius("action", 12, width, height)
    color: selected ? Theme.Theme.elevated : mouse.containsMouse ? Theme.Theme.surface : "transparent"
    border.width: selected ? 1 : 0
    border.color: Theme.Theme.accent
    Accessible.role: Accessible.Button
    Accessible.name: app.name
    Accessible.onPressAction: chosen()
    Image {
        id: icon
        visible: root.preferences.showIcons
        width: root.grid ? root.preferences.iconSize : Math.min(root.preferences.iconSize, root.height - 12); height: width
        x: root.grid ? (parent.width - width) / 2 : 12
        y: root.grid ? 12 : (parent.height - height) / 2
        source: root.iconPresentation.source
        sourceSize: Qt.size(width * 2, height * 2)
        fillMode: Image.PreserveAspectFit
        Text {
            anchors.centerIn: parent
            visible: icon.status !== Image.Ready
            text: root.iconPresentation.fallbackText
            color: Theme.Theme.accent; font.pixelSize: root.preferences.iconSize * 0.7
        }
    }
    Column {
        x: root.grid ? 6 : root.preferences.showIcons ? icon.x + icon.width + 12 : 14
        y: root.grid ? (root.preferences.showIcons ? icon.y + icon.height + 8 : 16) : (parent.height - height) / 2
        width: parent.width - x - (root.grid ? 6 : 12)
        spacing: 3
        Text {
            textFormat: Text.PlainText
            width: parent.width; visible: root.preferences.showLabels
            text: root.app.name; elide: Text.ElideRight
            horizontalAlignment: root.grid ? Text.AlignHCenter : Text.AlignLeft
            color: Theme.Theme.text; font.family: Theme.Theme.fontFamily; font.pixelSize: 14
        }
        Text {
            textFormat: Text.PlainText
            width: parent.width
            visible: !root.grid && root.preferences.showSubtitles && root.preferences.showLabels && text.length > 0
            text: root.app.genericName || root.app.comment || ""
            elide: Text.ElideRight; color: Theme.Theme.subtext
            font.family: Theme.Theme.fontFamily; font.pixelSize: 11
        }
    }
    MouseArea {
        id: mouse
        anchors.fill: parent; hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onClicked: event => {
            if (event.button === Qt.RightButton) root.contextRequested(event.x, event.y)
            else root.chosen()
        }
    }
    ToolTip.visible: mouse.containsMouse && (!root.preferences.showLabels || root.grid)
    ToolTip.text: root.app.name
}
