import QtQuick
import "../../services" as Services
import "../../theme" as Theme
Rectangle {
    id: root
    property string family: "surfaceBorders"
    property string surfaceId: ""
    readonly property var style: Services.Settings.data.appearance[family]
    anchors.fill: parent
    color: "transparent"
    border.width: style && style[surfaceId] === true ? style.width : 0
    border.color: Theme.Theme.roles[style ? style.role : "border"] || Theme.Theme.border
    visible: border.width > 0
    // Overlay only; never owns input or changes the surface's geometry.
}
