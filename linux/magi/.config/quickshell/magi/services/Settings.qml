
pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: settings

    property alias palette: adapter.palette

    property alias barLeftPlugins: adapter.barLeftPlugins
    property alias barCenterPlugins: adapter.barCenterPlugins
    property alias barRightPlugins: adapter.barRightPlugins

    FileView {
        id: file

        path: Qt.resolvedUrl("../settings.json")
        watchChanges: true
        blockLoading: true

        onFileChanged: reload()

        JsonAdapter {
            id: adapter

            property string palette: "catppuccin"

            property var barLeftPlugins: ["clock", "date"]
            property var barCenterPlugins: []
            property var barRightPlugins: []
        }
    }
}
