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
    description: "SUPER + C opens history. New copies are collected; the clipboard already present at startup is skipped."
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
        text: "Sensitive hints are respected; unmarked secrets cannot be detected. History, including pins, is normally session-only. Persistence saves unencrypted clipboard data in your user storage. Turning it off removes MAGI's saved history; backups may retain it."
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
    Label {
        Layout.fillWidth: true; wrapMode: Text.Wrap
        text: "Sensitive-marked copies are ignored, but apps may omit that hint. Wayland does not reliably identify the source app. Pause collection before copying private content. Images and history have additional memory limits; lowering the entry limit may unpin excess items."
        color: Theme.Theme.text
    }
    SettingsUI.SettingsSection {
        title: "History actions"
        RowLayout {
            SettingsUI.SettingsButton {
                text: "Clear unpinned"; enabled: Services.Clipboard.ready
                onClicked: Services.Clipboard.clear()
            }
            SettingsUI.SettingsButton {
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
    SettingsUI.SettingsButton { flat: true; text: "Reset clipboard settings"; onClicked: Services.Settings.resetSection("clipboard") }

    Timer { id: disarm; interval: 5000; onTriggered: root.eraseArmed = false }
}
