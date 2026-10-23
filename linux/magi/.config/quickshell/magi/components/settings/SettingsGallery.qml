import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts
import "SettingsScroll.js" as Scroll

Flickable {
    id: root
    required property var model
    required property Component delegate
    property real cardWidth: 176
    property real cardHeight: 126
    property int currentIndex: -1
    property alias count: cards.count
    function itemAt(index) {
        return cards.itemAt(index);
    }
    function reveal(index) {
        const card = itemAt(index);
        if (!card)
            return;
        if (card.x < contentX)
            contentX = card.x;
        else if (card.x + card.width > contentX + width)
            contentX = Math.max(0, card.x + card.width - width);
    }
    function focusIndex(index) {
        index = Math.max(0, Math.min(count - 1, index));
        reveal(index);
        if (itemAt(index))
            itemAt(index).forceActiveFocus(Qt.TabFocusReason);
    }
    onCurrentIndexChanged: Qt.callLater(() => reveal(currentIndex))
    onWidthChanged: Qt.callLater(() => reveal(currentIndex))
    Layout.fillWidth: true
    Layout.minimumWidth: 0
    implicitHeight: cardHeight + 12
    contentWidth: row.width
    contentHeight: height
    flickableDirection: Flickable.HorizontalFlick
    boundsBehavior: Flickable.StopAtBounds
    clip: true
    ScrollBar.horizontal: ScrollBar {
        policy: ScrollBar.AsNeeded
    }
    ScrollInput {
        view: root
        horizontal: true
    }
    WheelHandler {
        target: null
        acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
        orientation: Qt.Horizontal
        blocking: true
        onWheel: event => {
            event.accepted = Scroll.move(root, Scroll.delta(event.pixelDelta.x, event.angleDelta.x), true);
        }
    }
    Row {
        id: row
        spacing: SettingsMetrics.gap
        Repeater {
            id: cards
            model: root.model
            delegate: root.delegate
            onCountChanged: Qt.callLater(() => root.reveal(root.currentIndex))
        }
    }
}
