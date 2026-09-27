import QtQuick

// Only instantiated for a configured, visible bar placement.
ExpandablePlugin {
    id: root
    required property var module
    barWindow: module.barWindow
    sharedSurface: module.sharedSurface
    hostMode: module.hostMode
    menuId: module.menuId
    icon: module.icon
    title: module.title
    menuKeyboardFocus: module.menuKeyboardFocus
    collapsedWidth: module.collapsedWidth
    expandedWidth: module.expandedWidth
    menuHeight: module.menuHeight
    pillContent: module.pillContent
    menuContent: module.menuContent
    color: module.color
    viewPadding: module.viewPadding
    viewTopPadding: module.viewTopPadding
    viewBottomPadding: module.viewBottomPadding
    viewRadius: module.viewRadius
    viewSurfaceColor: module.viewSurfaceColor
    Component.onCompleted: module.pill = root
    Component.onDestruction: { if (module.pill === root) module.pill = null }
}
