import QtQuick
import "../../../components/controls" as Controls
import "../../../theme" as MagiTheme

Rectangle {
    id: root
    property string icon: ""
    property string moduleId: ""
    property string title: ""
    property string subtitle: ""
    property bool toggle: true
    property bool active: false
    property bool available: true
    property bool interactive: true
    property color activeColor: MagiTheme.Theme.teal
    property string accentRole: "teal"
    property color rimColor: MagiTheme.Theme.primaryTileRim(activeColor)
    signal primaryTriggered()
    signal secondaryTriggered()

    implicitWidth: MagiTheme.RenderTokens.tileSize
    implicitHeight: MagiTheme.RenderTokens.tileSize
    radius: MagiTheme.RenderTokens.tileRadius
    color: MagiTheme.Theme.primaryTileColor(activeColor)
    border.width: MagiTheme.RenderTokens.tileBorder
    border.color: rimColor
    Accessible.name: title + (subtitle.length ? ": " + subtitle : "")

    Controls.Icon {
        anchors.centerIn: parent
        role: root.icon
        moduleId: root.moduleId
        color: MagiTheme.Theme.controlInk(root.toggle, root.active, root.available, false)
        size: MagiTheme.RenderTokens.tileIconSize
    }
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
