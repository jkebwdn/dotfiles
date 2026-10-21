pragma Singleton
import QtQuick
QtObject {
    // ShellScreen objects, never connector-name caches across hotplug.
    property var mainScreen: null
    property var enabledScreens: []
    property var focusedScreen: null
    // Resolve at invocation, never move an open surface merely because focus changes.
    function shortcutTarget() {
        return enabledScreens.includes(focusedScreen) ? focusedScreen : mainScreen
    }
    property var menuScreen: null
    property var hubScreen: null
    function menuTarget() { return menuScreen || mainScreen }
    function hubTarget() { return hubScreen || mainScreen }
    function reconcile() {
        if ((menuScreen && !enabledScreens.includes(menuScreen)) || (MenuController.activeMenu && !menuScreen)) {
            MenuController.close()
            SettingsWindowState.closePreview()
            menuScreen = null
        }
        if ((hubScreen && !enabledScreens.includes(hubScreen)) || (Hub.opened && !hubScreen)) {
            Hub.close()
            hubScreen = null
        }
    }
    onEnabledScreensChanged: reconcile()
}
