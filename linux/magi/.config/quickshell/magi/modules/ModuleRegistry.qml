import QtQuick
import Quickshell
import "../plugins/bar/wifi" as Wifi
import "../plugins/bar/bluetooth" as Bluetooth
import "../plugins/bar/volume" as Volume
import "../plugins/bar/controlcentre" as ControlCentre

// Explicit built-ins, scoped per Bar. These are Scopes, not hidden bar Items.
Scope {
    id: root
    required property var barWindow
    property var sharedSurface: null
    property string hostMode: "combined"
    readonly property var modules: ({wifi: wifi, bluetooth: bluetooth,
        volume: volume, controlcentre: centre})
    readonly property bool presentationBusy: Object.values(modules).some(module => module.phase !== 0)
    readonly property bool interactionBusy: wifi.selectedNetwork !== null
        || wifi.passwordCandidate !== null || wifi.pendingNetwork !== null
    Wifi.Wifi {
        id: wifi
        barWindow: root.barWindow
        sharedSurface: root.sharedSurface
        hostMode: root.hostMode
        fallbackAnchor: centre.pill
    }
    Bluetooth.Bluetooth {
        id: bluetooth
        barWindow: root.barWindow
        sharedSurface: root.sharedSurface
        hostMode: root.hostMode
        fallbackAnchor: centre.pill
    }
    Volume.Volume {
        id: volume
        barWindow: root.barWindow
        sharedSurface: root.sharedSurface
        hostMode: root.hostMode
        fallbackAnchor: centre.pill
    }
    ControlCentre.ControlCentre {
        id: centre
        barWindow: root.barWindow
        sharedSurface: root.sharedSurface
        hostMode: root.hostMode
        fallbackAnchor: centre.pill
    }
}
