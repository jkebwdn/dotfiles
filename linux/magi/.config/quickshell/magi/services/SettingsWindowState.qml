pragma Singleton
import QtQuick
QtObject {
    id: root
    property string page: "Appearance"
    readonly property var appearanceRoutes: ({theme:"Appearance", surfaces:"Surfaces", controlcentre:"Control Centre", hub:"Hub"})
    readonly property bool inAppearance: Object.values(appearanceRoutes).indexOf(page) >= 0
    readonly property string appearanceSection: Object.keys(appearanceRoutes).find(id => appearanceRoutes[id] === page) || "theme"
    function selectAppearance(id) { if (appearanceRoutes[id]) page = appearanceRoutes[id] }
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
        MenuController.open("controlcentre", SurfaceOrigin.hubTarget())
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
    function open(screen) {
        requested = true
        Hub.open("settings", screen)
        requested = false
    }
}
