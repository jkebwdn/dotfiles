import QtQuick
import "../../theme" as Theme
// Shared collapsed presentation contract. Actions belong to the caller.
Rectangle {
    property string styleId: ""
    readonly property color itemBackground: Theme.Theme.barItemBackground(styleId)
    implicitWidth: 30
    implicitHeight: Theme.Theme.barPillHeight
    radius: Theme.Theme.barPillRadius
    color: itemBackground
}
