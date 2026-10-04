pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts
import Quickshell
import "../../theme" as Theme
import "../../services" as Services
import "../controls" as MagiControls
import "pages" as Pages
FloatingWindow {
    id: window
    property real outputWidth: 1920
    title: "MAGI Settings"
    implicitWidth: 940
    implicitHeight: 720
    minimumSize: Qt.size(720, 500)
    color: Theme.Theme.background
    visible: Services.SettingsWindowState.shown
    onVisibleChanged: { if (!visible) Services.SettingsWindowState.shown = false }
    Pane {
        anchors.fill: parent
        padding: 0
        font.family: "Noto Sans"
        font.pixelSize: 14
        palette.window: Theme.Theme.background
        palette.windowText: Theme.Theme.text
        palette.base: Theme.Theme.background
        palette.alternateBase: Theme.Theme.surface
        palette.text: Theme.Theme.text
        palette.button: Theme.Theme.elevated
        palette.buttonText: Theme.Theme.text
        palette.highlight: Theme.Theme.accent
        palette.highlightedText: Theme.Theme.accentText
        palette.light: Theme.Theme.elevated
        palette.mid: Theme.Theme.border
        palette.dark: Theme.Theme.background
        background: Rectangle { color: Theme.Theme.background }
        RowLayout {
            anchors.fill: parent
            spacing: 0
            Rectangle {
                Layout.preferredWidth: 190
                Layout.fillHeight: true
                color: Theme.Theme.surface
                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 18
                    spacing: 12
                    RowLayout {
                        MagiControls.Icon { role: "settings"; moduleId: "settings"; size: 24 }
                        Label { text: "MAGI"; font.pixelSize: 24; font.bold: true }
                    }
                    Label { text: "Settings"; color: Theme.Theme.subtext; Layout.bottomMargin: 20 }
                    Repeater {
                        model: ["Appearance", "Profile", "Bar", "Control Centre", "Notifications", "Clipboard", "Icons"]
                        SettingsButton {
                            id: navigationButton
                            required property string modelData
                            Layout.fillWidth: true
                            text: modelData
                            checked: Services.SettingsWindowState.page === modelData
                            onClicked: Services.SettingsWindowState.page = modelData
                            background: Rectangle {
                                radius: Theme.Theme.radius("action", 8, width, height)
                                color: navigationButton.checked ? Theme.Theme.elevated : "transparent"
                            }
                        }
                    }
                    Item { Layout.fillHeight: true }
                    Label { text: "Changes save automatically"; wrapMode: Text.WordWrap; Layout.fillWidth: true; color: Theme.Theme.subtext; font.pixelSize: 11 }
                    SettingsButton { text: "Close"; Layout.fillWidth: true; onClicked: Services.SettingsWindowState.shown = false }
                }
            }
            ColumnLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: 0
                Loader {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    sourceComponent: Services.SettingsWindowState.page === "Appearance" ? appearance
                        : Services.SettingsWindowState.page === "Profile" ? profile
                        : Services.SettingsWindowState.page === "Bar" ? bar
                        : Services.SettingsWindowState.page === "Notifications" ? notifications
                        : Services.SettingsWindowState.page === "Clipboard" ? clipboard
                        : Services.SettingsWindowState.page === "Icons" ? icons : centre
                }
                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: footer.implicitHeight + 20
                    color: Theme.Theme.surface
                    RowLayout {
                        id: footer
                        anchors.fill: parent
                        anchors.margins: 10
                        Label {
                            Layout.fillWidth: true
                            wrapMode: Text.WordWrap
                            text: Services.Settings.error || Services.Settings.diagnostics.join(" · ")
                                || (Services.Settings.saveState === "saved"
                                    ? "Saved · schema v" + Services.Settings.data.schemaVersion
                                    : Services.Settings.saveState)
                            color: Services.Settings.error ? Theme.Theme.red : Theme.Theme.subtext
                            font.pixelSize: 12
                        }
                        SettingsButton {
                            visible: Services.Settings.saveState === "conflict" || Services.Settings.saveState === "error"
                            text: "Discard edits and reload"
                            onClicked: Services.Settings.discardAndReload()
                        }
                    }
                }
            }
        }
    }
    Component { id: appearance; Pages.AppearancePage {} }
    Component { id: profile; Pages.ProfilePage {} }
    Component { id: bar; Pages.BarPage {} }
    Component { id: centre; Pages.ControlCentrePage { outputWidth: window.outputWidth } }
    Component { id: icons; Pages.IconsPage {} }
    Component { id: notifications; Pages.NotificationsPage {} }
    Component { id: clipboard; Pages.ClipboardPage {} }
}
