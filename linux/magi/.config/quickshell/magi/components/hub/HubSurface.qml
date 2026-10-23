import QtQuick
import "../../theme" as Theme
import "../controls" as Controls

Rectangle {
    color: Theme.Theme.surface
    radius: Theme.Theme.radius("surface", 11, width, height)
    Controls.SurfaceBorder {
        z: 3
        surfaceId: "hubContent"
        radius: parent.radius
    }
}
