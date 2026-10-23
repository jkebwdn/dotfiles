pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts
import "../../../services" as Services
import "../../../theme" as Theme
import ".." as SettingsUI

SettingsUI.SettingsPage {
    id: root
    property bool eraseArmed: false
    title: "Clipboard"
    description: "Super + C opens history."

    Repeater {
        model: [{key:"enabled",label:"Collect clipboard history"},
            {key:"includeImages",label:"Include PNG and JPEG images"},
            {key:"includeFiles",label:"Include file / URI lists"},
            {key:"persistHistory",label:"Keep history across restarts (stored on disk)"}]
        SettingsUI.SettingsToggle {
            required property var modelData
            text: modelData.label
            checked: Services.Settings.data.clipboard[modelData.key]
            onClicked: Services.Settings.setValue("clipboard", modelData.key, checked)
        }
    }
    Label {
        Layout.fillWidth: true; wrapMode: Text.Wrap
        text: "History is session-only by default. Saved history is unencrypted."
        color: Theme.Theme.text
    }
    SettingsUI.SettingsRow {
        Layout.fillWidth: true
        Label { text: "Maximum history entries"; Layout.fillWidth: true }
        SettingsUI.SettingsNumber {
            from: 10; to: 200; stepSize: 10
            value: Services.Settings.data.clipboard.historyLimit
            onValueModified: Services.Settings.setValue("clipboard", "historyLimit", value)
        }
    }
    SettingsUI.SettingsSection {
        objectName: "clipboardHistoryPrivacy"
        title: "About Clipboard history"
        collapsible: true
        SettingsUI.SettingsHelp { text: "Sensitive hints are respected; unmarked secrets cannot be detected. History, including pins, is normally session-only. Persistence saves unencrypted clipboard data in your user storage. Turning it off removes MAGI's saved history; backups may retain it." }
        SettingsUI.SettingsHelp { text: "Pause collection before copying private content. Lowering the history limit may unpin older items." }
    }
    SettingsUI.SettingsSection {
        objectName: "clipboardAppearance"
        title: "Card appearance"
        collapsible: true
        SettingsUI.CardStylePreview { clipboard: true }
        SettingsUI.SurfaceStyleSettings {
            title: ""
            group: "notificationBorders"
            showSharedControls: false
            targets: [{id: "clipboard", label: "Clipboard card borders"}]
        }
        SettingsUI.SettingsHelp { text: "Borders follow Notifications; shape follows Appearance." }
        SettingsUI.SettingsButton {
            actionKind: "navigation";  text: "Shared card borders ↗"; onClicked: Services.SettingsWindowState.page = "Notifications" }
        SettingsUI.SettingsButton {
            actionKind: "navigation";  text: "Shared card roundness ↗"; onClicked: Services.SettingsWindowState.page = "Appearance" }
    }
    SettingsUI.SettingsSection {
        title: "History actions"
        RowLayout {
            SettingsUI.SettingsButton {
                destructive: true; text: "Clear unpinned"; enabled: Services.Clipboard.ready
                onClicked: Services.Clipboard.clear()
            }
            SettingsUI.SettingsButton {
                destructive: true
                text: root.eraseArmed ? "Confirm erase including pins" : "Erase all history…"
                enabled: Services.Clipboard.ready
                onClicked: {
                    if (root.eraseArmed) { Services.Clipboard.erase(); root.eraseArmed = false }
                    else { root.eraseArmed = true; disarm.restart() }
                }
            }
        }
        SettingsUI.SettingsHelp { visible: root.eraseArmed; text: "This also removes favourites. Click again to confirm."; color: Theme.Theme.warning }
        Label {
            Layout.fillWidth: true; wrapMode: Text.Wrap
            text: Services.Clipboard.error || (Services.Clipboard.monitoring ? "Collecting new copies" : "Collection paused or unavailable")
            color: Services.Clipboard.error ? Theme.Theme.warning : Theme.Theme.subtext
        }
    }
    SettingsUI.SettingsButton {
        actionKind: "reset";  text: "Reset clipboard settings"; onClicked: Services.Settings.resetSection("clipboard") }

    Timer { id: disarm; interval: 5000; onTriggered: root.eraseArmed = false }
}
