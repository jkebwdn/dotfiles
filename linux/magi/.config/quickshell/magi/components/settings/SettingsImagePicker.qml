pragma Singleton
import QtQuick
import QtQuick.Dialogs
import QtQuick.Controls.Basic as Controls
import Quickshell
import "../../services" as Services

// One retained Settings owner; imports finish even if the requesting page unloads.
Scope {
    id: root
    property var hostWindow: null
    property string kind: ""
    property int requestId: 0
    property var errors: ({})
    readonly property bool busy: dialog.visible || requestId !== 0
    property alias dialog: dialog
    function setError(kind, message) {
        errors = Object.assign({}, errors, {[kind]: message})
    }
    function choose(kind, window) {
        if (busy) return
        if (!window) { setError(kind, "The Settings window is unavailable. Reopen Settings and try again."); return }
        root.kind = kind
        hostWindow = window
        setError(kind, "")
        dialog.open()
    }
    function importSelected(url) {
        requestId = kind === "decoration" ? Services.AssetManager.importDecorationImage(url)
            : Services.AssetManager.importBarImage(url)
    }
    function complete(id, asset, error) {
        if (!requestId || id !== requestId) return
        requestId = 0
        setError(kind, error)
        if (error) return
        if (kind === "decoration") {
            const next = Object.assign({}, Services.Settings.data.controlCentre.decoration, {asset: asset})
            Services.Settings.setValue("controlCentre", "decoration", next)
        } else {
            const modules = JSON.parse(JSON.stringify(Services.Settings.data.bar.modules))
            modules.customImage = Object.assign({}, modules.customImage || {}, {asset: asset})
            Services.Settings.setValue("bar", "modules", modules)
        }
    }
    FileDialog {
        id: dialog
        objectName: "settingsImageDialog"
        parentWindow: root.hostWindow
        fileMode: FileDialog.OpenFile
        // Keep the Qt dialog above the layer-shell Settings host and inside its
        // existing input mask; no unmanaged native top-level behind the Hub.
        options: FileDialog.DontUseNativeDialog
        popupType: Controls.Popup.Item
        title: root.kind === "decoration" ? "Select a decorative image" : "Select a Bar image"
        nameFilters: root.kind === "decoration" ? ["Images (*.png *.gif)"] : ["Images (*.gif *.png *.jpg *.jpeg *.webp)"]
        onAccepted: root.importSelected(selectedFile)
    }
    Connections {
        target: root.hostWindow
        function onVisibleChanged() { if (!root.hostWindow.visible) dialog.reject() }
    }
    Connections {
        target: Services.SettingsWindowState
        // Hub mode switches keep the backing window mapped. A chooser must not
        // remain modal over a different mode; an accepted import still completes.
        function onShownChanged() { if (!Services.SettingsWindowState.shown) dialog.reject() }
    }
    Connections {
        target: Services.AssetManager
        function onDecorationImageImported(id, asset, error) { if (root.kind === "decoration") root.complete(id, asset, error) }
        function onBarImageImported(id, asset, error) { if (root.kind === "bar") root.complete(id, asset, error) }
    }
}
