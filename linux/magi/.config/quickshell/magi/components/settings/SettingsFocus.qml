import QtQuick
import "../../theme" as Theme
Rectangle {
    id: frame
    anchors.fill: parent
    anchors.margins: 1
    z: 10
    color: "transparent"
    radius: Theme.Theme.radius("action", 8, width, height)
    border.width: SettingsMetrics.focusWidth
    border.color: Theme.Theme.accent
    visible: parent.activeFocus && parent.focusReason !== Qt.MouseFocusReason
    // Tab navigation must reveal controls below the visible page, too.
    Connections {
        target: frame.parent
        function onActiveFocusChanged() {
            const control = frame.parent
            if (!control.activeFocus) return
            let view = control.parent
            while (view && view.contentY === undefined) view = view.parent
            if (!view || !view.contentItem) return
            const top = control.mapToItem(view.contentItem, 0, 0).y
            const inset = SettingsMetrics.compactGap
            if (top < view.contentY + inset) view.contentY = Math.max(0, top - inset)
            else if (top + control.height > view.contentY + view.height - inset)
                view.contentY = Math.max(0, Math.min(view.contentHeight - view.height, top + control.height - view.height + inset))
        }
    }
}
