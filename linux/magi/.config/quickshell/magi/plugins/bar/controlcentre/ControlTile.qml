import QtQuick
import "../../../components/controls" as Controls
import "../../../theme" as MagiTheme

Rectangle {
    id: root
    property string icon: ""
    property string moduleId: ""
    property string title: ""
    property string subtitle: ""
    property bool active: false
    property bool available: true
    property bool interactive: true
    property color activeColor: MagiTheme.Theme.teal
    property string accentRole: "teal"
    property color rimColor: MagiTheme.Theme.teal
    signal primaryTriggered()
    signal secondaryTriggered()

    implicitWidth: MagiTheme.RenderTokens.tileSize
    implicitHeight: MagiTheme.RenderTokens.tileSize
    radius: MagiTheme.RenderTokens.tileRadius
    color: active ? activeColor : MagiTheme.Theme.elevated
    border.width: MagiTheme.RenderTokens.tileBorder
    border.color: tileHover.hovered && interactive
        ? Qt.lighter(rimColor, 1.12)
        : active ? rimColor : MagiTheme.Theme.sliderRim
    opacity: available ? 1 : 0.45
    Accessible.name: title + (subtitle.length ? ": " + subtitle : "")

    Controls.Icon {
        anchors.centerIn: parent
        role: root.icon
        moduleId: root.moduleId
        color: root.active ? MagiTheme.Theme.onColor(root.accentRole) : MagiTheme.Theme.text
        size: MagiTheme.RenderTokens.tileIconSize
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
