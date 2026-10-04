pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import "../bar" as BarUI
import "../../theme" as Theme
BarUI.SharedStatusSurface {
    id: root
    required property var service
    property Item anchorItem: null
    property Item clockItem: null
    property Item dateItem: null
    readonly property bool absorbed: phase !== 0
    readonly property point origin: {
        const a = anchorWatch.transform, c = clockWatch.transform, d = dateWatch.transform
        if (!anchorItem || !parent) return Qt.point(14, 10)
        const point = anchorItem.mapToItem(parent, 0, 0)
        if (clockItem && dateItem) {
            const cp = clockItem.mapToItem(parent, 0, 0), dp = dateItem.mapToItem(parent, 0, 0)
            const left = Math.min(cp.x, dp.x), right = Math.max(cp.x + clockItem.width, dp.x + dateItem.width)
            if (Math.abs(cp.y - dp.y) < 1 && right - left <= clockItem.width + dateItem.width + Theme.Theme.barSectionSpacing + 1)
                return Qt.point(left, cp.y)
        }
        return point
    }
    TransformWatcher { id: anchorWatch; a: root.parent; b: root.anchorItem }
    TransformWatcher { id: clockWatch; a: root.parent; b: root.clockItem }
    TransformWatcher { id: dateWatch; a: root.parent; b: root.dateItem }
    x: Math.max(Theme.Theme.barEdgeMargin, Math.min(origin.x, (parent ? parent.width : 1920) - width - Theme.Theme.barEdgeMargin))
    y: origin.y
    visible: absorbed
    combined: true
    headerAlignment: Qt.AlignLeft
    requestedModule: service.opened && anchorItem ? definition : null
    modules: [definition]
    QtObject {
        id: definition
        property int expandedWidth: 344
        property int menuHeight: 134 + 6 * (root.service.preferences.density === "compact" ? 32 : 38)
        property int viewPadding: 12
        property int viewTopPadding: 6
        property int viewBottomPadding: 12
        property real viewRadius: Theme.Theme.radiusMedium
        property color viewSurfaceColor: Theme.Theme.surface
        property Component menuContent: Component { CalendarContent { service: root.service } }
    }
    statusContent: Component {
        Row {
            spacing: Theme.Theme.barSectionSpacing
            TimeDatePill { expansion: root.expansion; onTriggered: root.service.close() }
            TimeDatePill { datePart: true; expansion: root.expansion; onTriggered: root.service.close() }
        }
    }
    // Every point in the inherited clock/date header remains a close target.
    MouseArea { width: parent.width; height: root.headerHeight; z: 3; onClicked: root.service.close() }
}
