pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts
import Quickshell
import "../../theme" as Theme
import "../../services" as Services
import "../controls" as MagiControls
import "pages" as Pages
import "SettingsFeedback.js" as Feedback
FocusScope {
    id: window
    property real outputWidth: 1920
    readonly property var navigationGroups: [
        {title:"Personalisation", pages:["Appearance", "Wallpaper", "Applications", "Profile"]},
        {title:"Desktop", pages:["Bar", "Control Centre", "Hub", "Date & time"]},
        {title:"Everyday tools", pages:["Launcher", "Notifications", "Clipboard", "Emoji"]},
        {title:"Session & hardware", pages:["Lock Screen", "Security", "Power & Idle", "Displays"]}
    ]
    readonly property var navigationPages: navigationGroups.reduce((pages, group) => pages.concat(group.pages), [])
    function revealNavigation(button) {
        const view = navigationScroll.contentItem
        const y = button.mapToItem(view.contentItem, 0, 0).y
        view.contentY = Math.max(0, Math.min(Math.max(0, view.contentHeight - view.height),
            y < view.contentY ? y : y + button.height > view.contentY + view.height ? y + button.height - view.height : view.contentY))
    }
    function focusNavigation(page, delta) {
        const next = navigationPages[Math.max(0, Math.min(navigationPages.length - 1, navigationPages.indexOf(page) + delta))]
        const button = navigationButtons.itemAt(navigationPages.indexOf(next)).button
        button.forceActiveFocus(Qt.TabFocusReason)
    }
    function revealSelectedNavigation() {
        // During keyboard traversal the focused destination can differ from the
        // selected page. Never scroll that focus away when the viewport resizes.
        for (let i = 0; i < navigationButtons.count; ++i) {
            const button = navigationButtons.itemAt(i).button
            if (button.activeFocus) { revealNavigation(button); return }
        }
        const entry = navigationButtons.itemAt(navigationPages.indexOf(Services.SettingsWindowState.page))
        if (entry) revealNavigation(entry.button)
    }
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
                objectName: "settingsSidebar"
                Layout.preferredWidth: 206
                Layout.margins: SettingsMetrics.sidebarInset
                Layout.fillHeight: true
                color: Theme.Theme.elevated
                radius: Theme.Theme.radius("surface", 11, width, height)
                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 14
                    spacing: 12
                    RowLayout {
                        MagiControls.Icon { role: "settings"; moduleId: "settings"; size: SettingsMetrics.iconSize }
                        Label { text: "MAGI"; font.pixelSize: 20; font.bold: true }
                    }
                    ScrollView {
                        id: navigationScroll
                        onHeightChanged: Qt.callLater(window.revealSelectedNavigation)
                        ScrollInput { view: navigationScroll.contentItem }
                        objectName: "settingsNavigation"
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        contentWidth: availableWidth
                        clip: true
                        ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
                        ColumnLayout {
                            width: parent.width
                            spacing: 0
                            Repeater {
                                id: navigationButtons
                                model: window.navigationPages
                                ColumnLayout {
                                    id: navigationEntry
                                    required property string modelData
                                    readonly property string groupTitle: window.navigationGroups.find(group => group.pages[0] === modelData)?.title || ""
                                    property alias button: navigationButton
                                    Layout.fillWidth: true
                                    spacing: 0
                                    Label {
                                        objectName: "settingsGroup-" + navigationEntry.groupTitle
                                        visible: navigationEntry.groupTitle.length > 0
                                        text: navigationEntry.groupTitle
                                        Layout.fillWidth: true
                                        Layout.topMargin: navigationEntry.modelData === window.navigationPages[0] ? 0 : 10
                                        Layout.bottomMargin: 4
                                        font.pixelSize: 11
                                        color: Theme.Theme.subtext
                                        Accessible.role: Accessible.Heading
                                    }
                                    SettingsNavigationItem {
                                        id: navigationButton
                                        readonly property string pageId: navigationEntry.modelData
                                        objectName: "settingsNav-" + pageId
                                        Layout.fillWidth: true
                                        iconRole: ({"Applications":"apps","Hub":"hub","Control Centre":"settings","Bar":"menu","Appearance":"settings","Profile":"profile","Date & time":"calendar","Notifications":"notifications","Clipboard":"clipboard","Launcher":"apps","Emoji":"emoji","Wallpaper":"image","Power & Idle":"power","Displays":"settings","Lock Screen":"lock","Security":"lock"})[pageId]
                                        text: pageId === "Applications" ? "Transparency" : pageId
                                        Accessible.name: text
                                        checked: pageId === "Appearance" ? Services.SettingsWindowState.inAppearance : Services.SettingsWindowState.page === pageId
                                        onClicked: Services.SettingsWindowState.page = pageId
                                        onActiveFocusChanged: if (activeFocus) window.revealNavigation(this)
                                        onCheckedChanged: if (checked) Qt.callLater(window.revealSelectedNavigation)
                                        Keys.onReturnPressed: clicked()
                                        Keys.onEnterPressed: clicked()
                                        Keys.onDownPressed: window.focusNavigation(pageId, 1)
                                        Keys.onUpPressed: window.focusNavigation(pageId, -1)
                                    }
                                }
                            }
                        }
                    }
                    Rectangle {
                        objectName: "settingsSavePanel"
                        Layout.fillWidth: true
                        implicitHeight: statusColumn.implicitHeight + 16
                        radius: Theme.Theme.radius("action", 8, width, height)
                        color: "transparent"
                        ColumnLayout {
                            id: statusColumn
                            anchors { left: parent.left; right: parent.right; verticalCenter: parent.verticalCenter; margins: 8 }
                            spacing: 6
                            Label {
                                objectName: "settingsSaveStatus"
                                horizontalAlignment: Text.AlignHCenter
                                Layout.fillWidth: true
                                textFormat: Text.PlainText; wrapMode: Text.Wrap
                                maximumLineCount: 3; elide: Text.ElideRight
                                text: Feedback.save(Services.Settings.saveState)
                                color: Services.Settings.error ? Theme.Theme.red : Theme.Theme.subtext
                                font.pixelSize: 11
                                ToolTip.visible: statusHover.hovered
                                ToolTip.text: Services.Settings.error || Services.Settings.diagnostics.join(" · ") || text
                                HoverHandler { id: statusHover }
                            }
                            SettingsButton {
                                Layout.fillWidth: true
                                visible: Services.Settings.saveState === "conflict" || Services.Settings.saveState === "error"
                                text: "Reload from disk"
                                onClicked: Services.Settings.discardAndReload()
                            }
                            SettingsButton {
                                objectName: "settingsCloseControlCentrePreview"
                                Layout.fillWidth: true
                                visible: Services.SettingsWindowState.controlCentrePreview
                                flat: true; text: "Close CC preview"
                                Accessible.name: "Close Control Centre preview"
                                onClicked: Services.SettingsWindowState.closePreview()
                            }
                        }
                    }
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
                        model: ["Appearance", "Applications", "Hub", "Profile", "Bar", "Date & time", "Control Centre", "Notifications", "Clipboard", "Launcher", "Emoji", "Wallpaper", "Power & Idle", "Displays", "Lock Screen", "Security"]
                        Loader {
                            required property string modelData
                            property bool visited: false
                            readonly property bool selected: Services.SettingsWindowState.page === modelData
                            anchors.fill: parent
                            visible: selected
                            active: visited || selected
                            onSelectedChanged: if (selected) visited = true
                            Component.onCompleted: if (selected) visited = true
                            sourceComponent: modelData === "Applications" ? applications
                                : modelData === "Appearance" ? appearance
                                : modelData === "Hub" ? hubAppearance
                                : modelData === "Profile" ? profile
                                : modelData === "Bar" ? bar
                                : modelData === "Lock Screen" ? (Quickshell.env("MAGI_LOCK_DESIGNER") === "1" ? lockDesigner : lockScreen)
                                : modelData === "Security" ? security
                                : modelData === "Displays" ? displays
                                : modelData === "Power & Idle" ? powerIdle
                                : modelData === "Date & time" ? calendar
                                : modelData === "Notifications" ? notifications
                                : modelData === "Clipboard" ? clipboard
                                : modelData === "Wallpaper" ? wallpaper
                                : modelData === "Emoji" ? emoji
                                : modelData === "Launcher" ? launcher
                                : centre
                        }
                    }
                }

            }
        }
    }
    Component { id: hubAppearance; Pages.HubPage {} }
    Component { id: applications; Pages.ApplicationsPage {} }
    Component { id: appearance; Pages.AppearancePage {} }
    Component { id: profile; Pages.ProfilePage {} }
    Component { id: lockScreen; Pages.LockScreenPage {} }
    Component { id: lockDesigner; Pages.LockDesignerPage {} }
    Component { id: security; Pages.SecurityPage {} }
    Component { id: displays; Pages.DisplaysPage {} }
    Component { id: powerIdle; Pages.PowerIdlePage {} }
    Component { id: calendar; Pages.CalendarPage {} }
    Component { id: bar; Pages.BarPage {} }
    Component { id: centre; Pages.ControlCentrePage { outputWidth: window.outputWidth } }
    Component { id: notifications; Pages.NotificationsPage {} }
    Component { id: wallpaper; Pages.WallpaperPage {} }
    Component { id: emoji; Pages.EmojiPage {} }
    Component { id: launcher; Pages.LauncherPage {} }
    Component { id: clipboard; Pages.ClipboardPage {} }
}
