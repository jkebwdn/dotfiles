import QtQuick
import "../../theme" as Theme
// Shared collapsed presentation contract. Actions belong to the caller.
Rectangle {
    implicitWidth: 30
    implicitHeight: Theme.Theme.barPillHeight
    radius: Theme.Theme.barPillRadius
    color: Theme.Theme.statusPillBackground
}
