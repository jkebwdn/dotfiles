// Internal test/fallback wrapper. Production opens Settings only through Hub.
import QtQuick
import Quickshell
import "../../services" as Services
import "../../theme" as Theme
FloatingWindow {
    id: window
    property real outputWidth: 1920
    title: "MAGI Settings"
    implicitWidth: 940; implicitHeight: 720
    minimumSize: Qt.size(720, 500)
    color: Theme.Theme.surface
    visible: Services.SettingsWindowState.shown
    onVisibleChanged: if (!visible) Services.SettingsWindowState.shown = false
    SettingsContent { anchors.fill: parent; outputWidth: window.outputWidth }
}
