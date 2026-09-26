import QtQuick
import Quickshell

import "components/bar" as Bar

ShellRoot {
    Bar.Bar {
        // Change to "anchored" to use the PopupWindow fallback.
        expandableHostMode: "combined"
    }
}
