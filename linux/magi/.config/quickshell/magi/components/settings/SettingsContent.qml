pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts
import Quickshell
import "../../theme" as Theme
import "../../services" as Services
import "../controls" as MagiControls
import "pages" as Pages
FocusScope {
    id: window
    property real outputWidth: 1920
    function focusContent() { forceActiveFocus() }
    Pane {
        objectName: "settingsApplicationPane"
        // Child controls/popups handle Escape first; only unhandled keys bubble here.
        Keys.priority: Keys.AfterItem
        Keys.onEscapePressed: event => {
            Services.SettingsWindowState.shown = false
            event.accepted = true
        }
        anchors.fill: parent
        padding: 0
        font.family: "Noto Sans"
        font.pixelSize: SettingsMetrics.bodySize
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
        background: Item {}
        RowLayout {
            anchors.fill: parent
            spacing: 0
            Rectangle {
                Layout.preferredWidth: 190
                Layout.fillHeight: true
                color: Theme.Theme.surface
                radius: Theme.Theme.radius("surface", 11, width, height)
                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 14
                    spacing: 12
                    RowLayout {
                        MagiControls.Icon { role: "settings"; moduleId: "settings"; size: SettingsMetrics.iconSize }
                        Label { text: "MAGI"; font.pixelSize: 20; font.bold: true }
                    }
                    Label { text: "Settings"; color: Theme.Theme.subtext; Layout.bottomMargin: 12 }
                    ScrollView {
                        id: navigationScroll
                        objectName: "settingsNavigation"
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        contentWidth: availableWidth
                        clip: true
                        ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
                        ColumnLayout {
                            width: parent.width
                            spacing: 2
                            Repeater {
                                model: ["Appearance", "Profile", "Bar", "Date & time", "Control Centre", "Notifications", "Clipboard", "Launcher", "Emoji", "Wallpaper", "Icons"]
                                SettingsNavigationItem {
                                    id: navigationButton
                                    required property string modelData
                                    objectName: "settingsNav-" + modelData
                                    Layout.fillWidth: true
                                    text: modelData
                                    checked: Services.SettingsWindowState.page === modelData
                                    onClicked: Services.SettingsWindowState.page = modelData
                                    onActiveFocusChanged: if (activeFocus) {
                                        const view = navigationScroll.contentItem
                                        if (y < view.contentY) view.contentY = y
                                        else if (y + height > view.contentY + view.height)
                                            view.contentY = y + height - view.height
                                    }
                                }
                            }
                        }
                    }
                    SettingsButton { flat: true; text: "Close"; Layout.fillWidth: true; onClicked: Services.SettingsWindowState.shown = false }
                }
            }
            ColumnLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: 0
                Item {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Repeater {
                        model: ["Appearance", "Profile", "Bar", "Date & time", "Control Centre", "Notifications", "Clipboard", "Launcher", "Emoji", "Wallpaper", "Icons"]
                        Loader {
                            required property string modelData
                            property bool visited: false
                            readonly property bool selected: Services.SettingsWindowState.page === modelData
                            anchors.fill: parent
                            visible: selected
                            active: visited || selected
                            onSelectedChanged: if (selected) visited = true
                            Component.onCompleted: if (selected) visited = true
                            sourceComponent: modelData === "Appearance" ? appearance
                                : modelData === "Profile" ? profile
                                : modelData === "Bar" ? bar
                                : modelData === "Date & time" ? calendar
                                : modelData === "Notifications" ? notifications
                                : modelData === "Clipboard" ? clipboard
                                : modelData === "Wallpaper" ? wallpaper
                                : modelData === "Emoji" ? emoji
                                : modelData === "Launcher" ? launcher
                                : modelData === "Icons" ? icons : centre
                        }
                    }
                }
                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: footer.implicitHeight + 16
                    color: Theme.Theme.background
                    RowLayout {
                        id: footer
                        anchors.fill: parent
                        anchors.margins: 10
                        SettingsButton {
                            objectName: "settingsCloseControlCentrePreview"
                            visible: Services.SettingsWindowState.controlCentrePreview
                            flat: true
                            text: "CC preview active · Close"
                            Accessible.name: "Close Control Centre preview"
                            onClicked: Services.SettingsWindowState.closePreview()
                        }
                        ScrollView {
                            id: statusScroll
                            objectName: "settingsSaveStatusScroll"
                            Layout.fillWidth: true
                            implicitHeight: Math.min(80, saveStatus.implicitHeight)
                            contentWidth: availableWidth
                            clip: true
                            ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
                            Label {
                                id: saveStatus
                                objectName: "settingsSaveStatus"
                                textFormat: Text.PlainText
                                width: statusScroll.availableWidth
                                wrapMode: Text.Wrap
                                text: Services.Settings.error || Services.Settings.diagnostics.join(" · ")
                                    || (Services.Settings.saveState === "saved"
                                        ? "All changes saved"
                                        : Services.Settings.saveState)
                                color: Services.Settings.error ? Theme.Theme.red : Theme.Theme.text
                                font.pixelSize: 11
                                horizontalAlignment: Services.Settings.error || Services.Settings.diagnostics.length ? Text.AlignLeft : Text.AlignRight
                            }
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
    Component { id: calendar; Pages.CalendarPage {} }
    Component { id: bar; Pages.BarPage {} }
    Component { id: centre; Pages.ControlCentrePage { outputWidth: window.outputWidth } }
    Component { id: icons; Pages.IconsPage {} }
    Component { id: notifications; Pages.NotificationsPage {} }
    Component { id: wallpaper; Pages.WallpaperPage {} }
    Component { id: emoji; Pages.EmojiPage {} }
    Component { id: launcher; Pages.LauncherPage {} }
    Component { id: clipboard; Pages.ClipboardPage {} }
}
