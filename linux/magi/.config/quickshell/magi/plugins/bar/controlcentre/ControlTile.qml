import QtQuick
import "../../../theme" as MagiTheme

Rectangle {
    id: root
    property string icon: ""
    property string title: ""
    property string subtitle: ""
    property bool active: false
    property bool available: true
    property bool interactive: true
    property color activeColor: MagiTheme.RenderTokens.wifi
    property color rimColor: MagiTheme.RenderTokens.wifiRim
    signal primaryTriggered()
    signal secondaryTriggered()

    implicitWidth: MagiTheme.RenderTokens.tileSize
    implicitHeight: MagiTheme.RenderTokens.tileSize
    radius: MagiTheme.RenderTokens.tileRadius
    color: active ? activeColor : MagiTheme.RenderTokens.group
    border.width: MagiTheme.RenderTokens.tileBorder
    border.color: tileHover.hovered && interactive
        ? Qt.lighter(rimColor, 1.12)
        : active ? rimColor : MagiTheme.RenderTokens.sliderRim
    opacity: available ? 1 : 0.45
    Accessible.name: title + (subtitle.length ? ": " + subtitle : "")

    Text {
        anchors.centerIn: parent
        text: root.icon
        color: MagiTheme.RenderTokens.foreground
        font.family: MagiTheme.Theme.fontFamily
        font.pixelSize: MagiTheme.RenderTokens.tileIconSize
    }
    HoverHandler { id: tileHover; enabled: root.interactive }
    TapHandler {
        acceptedButtons: Qt.LeftButton
        enabled: root.available && root.interactive
        onTapped: root.primaryTriggered()
    }
    TapHandler {
        acceptedButtons: Qt.RightButton
        enabled: root.available && root.interactive
        onTapped: root.secondaryTriggered()
    }
}
