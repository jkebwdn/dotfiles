import QtQuick
import "../../services" as Services
import "../../theme" as Theme
import "../controls" as Controls

Rectangle {
    implicitWidth: 30; implicitHeight: Theme.Theme.barPillHeight
    radius: Theme.Theme.barPillRadius; color: Theme.Theme.surface
    Controls.Icon {
        anchors.centerIn: parent
        role: Services.Notifications.preferences.dnd ? "dnd" : "notifications"
        moduleId: "notifications"; size: Theme.Theme.statusIconSize
        color: Theme.Theme.stateColor("secondary", Services.Notifications.unread > 0 || Services.Notifications.preferences.dnd)
    }
    Rectangle {
        x: parent.width - 7; y: 3; width: 4; height: 4; radius: 2
        color: Theme.Theme.accent; visible: Services.Notifications.unread > 0
    }
    TapHandler {
        onTapped: {
            Services.MenuController.close()
            Services.Notifications.centreOpen = !Services.Notifications.centreOpen
        }
    }
    Accessible.name: "Notifications, " + Services.Notifications.unread + " unread"
    Accessible.role: Accessible.Button
}
