pragma Singleton
import QtQuick
QtObject {
    // Settings geometry only; colours and radii remain owned by Theme.
    readonly property int sidebarInset: 10
    readonly property int pagePadding: 24
    readonly property int gap: 16
    readonly property int compactGap: 8
    readonly property int controlHeight: 34
    readonly property int titleSize: 26
    readonly property int sectionSize: 16
    readonly property int bodySize: 14
    readonly property int helperSize: 13
    readonly property int iconSize: 24
    readonly property int focusWidth: 1
    readonly property real disabledOpacity: 0.7
}
