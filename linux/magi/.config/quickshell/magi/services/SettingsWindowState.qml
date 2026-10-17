pragma Singleton
import QtQuick
QtObject {
    id: root
    property string page: "Appearance"
    property bool requested: false
    property bool shown: false
    property bool controlCentrePreview: false
    function closePreview() {
        const closeSurface = controlCentrePreview && MenuController.activeMenu === "controlcentre"
        controlCentrePreview = false
        if (closeSurface) MenuController.close()
    }
    function toggleControlCentrePreview() {
        if (controlCentrePreview) { closePreview(); return }
        if (!shown) return
        controlCentrePreview = true
        MenuController.open("controlcentre")
    }
    onShownChanged: if (!shown) {
        closePreview()
        Hub.closeMode("settings")
    }
    property Connections menuWatch: Connections {
        target: MenuController
        function onActiveMenuChanged() {
            if (MenuController.activeMenu !== "controlcentre") root.controlCentrePreview = false
        }
    }
    function open() {
        requested = true
        Hub.open("settings")
        requested = false
    }
}
