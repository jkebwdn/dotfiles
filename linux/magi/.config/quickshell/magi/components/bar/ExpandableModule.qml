pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import "menu" as Hosts
import "../../services" as Services
import "../../theme" as MagiTheme

// Non-visual session/body owner. Bar placement never creates or destroys it.
Scope {
    id: root
    property var barWindow: null
    property var sharedSurface: null
    property string hostMode: "anchored"
    property var pill: null
    property var fallbackAnchor: null
    readonly property var fallbackPill: fallbackLoader.item
    Loader {
        id: fallbackLoader
        active: !root.sharedSurface && root.pill === null && root.fallbackAnchor !== null
        sourceComponent: Component {
            Hosts.AnchoredDetailHost { module: root; anchorItem: root.fallbackAnchor }
        }
    }
    signal secondaryTriggered()
    property string menuId: ""
    property string icon: ""
    property string title: ""
    property bool menuKeyboardFocus: true
    property bool barVisible: true
    property int collapsedWidth: 28
    property int expandedWidth: 220
    property int menuHeight: 180
    // Call with a complete target pair, or bind expandedWidth/menuHeight to layout.
    // The shared host coalesces changes after bindings settle.
    function requestGeometry(width, height) {
        if (!isFinite(width) || !isFinite(height) || width < 1 || height < 1) return false
        expandedWidth = Math.round(width)
        menuHeight = Math.round(height)
        return true
    }
    property Component pillContent: null
    property Component menuContent: null
    property color color: MagiTheme.Theme.surface
    property real viewPadding: MagiTheme.Theme.menuPadding
    property real viewTopPadding: MagiTheme.Theme.menuTopPadding
    property real viewBottomPadding: MagiTheme.Theme.menuBottomPadding
    property real viewRadius: MagiTheme.Theme.radiusMedium
    property color viewSurfaceColor: MagiTheme.Theme.surface
    readonly property bool requestedOpen: Services.MenuController.activeMenu === menuId
    readonly property int phase: sharedSurface ? sharedSurface.phase
        : pill ? pill.phase : fallbackPill ? fallbackPill.phase : 0
}
