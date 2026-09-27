import QtQuick
import Quickshell

import "components/bar" as Bar
import "components/settings" as SettingsUI

ShellRoot {
    SettingsUI.SettingsApplication { readyToOpen: bar.settingsReady; outputWidth: bar.width }
    Bar.Bar {
        id: bar
        // Change to "anchored" to use the PopupWindow fallback.
        expandableHostMode: "combined"
    }
}
