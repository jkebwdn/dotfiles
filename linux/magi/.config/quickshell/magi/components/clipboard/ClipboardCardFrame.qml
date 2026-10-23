import QtQuick
import "../../theme" as Theme
import "../controls" as Controls

Rectangle {
    property bool selected: false
    radius: Theme.Theme.radius("surface", 11, width, height)
    color: selected ? Theme.Theme.overlay : Theme.Theme.elevated
    Controls.SurfaceBorder {
        objectName: "clipboardCardBorder"
        family: "notificationBorders"
        surfaceId: "clipboard"
        radius: parent.radius
    }
}
