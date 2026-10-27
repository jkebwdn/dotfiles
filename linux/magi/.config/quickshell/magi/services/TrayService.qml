pragma Singleton
import QtQuick
import Quickshell.Services.SystemTray
TrayModel {
    // The only protocol tracking reference in MAGI. Never loaded by previews.
    sourceItems: SystemTray.items.values
}
