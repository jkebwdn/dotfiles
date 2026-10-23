import QtQuick
import "SettingsScroll.js" as Scroll

WheelHandler {
    required property Flickable view
    property bool horizontal: false
    parent: view
    target: null
    acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
    blocking: true
    onWheel: event => {
        const shifted = (event.modifiers & Qt.ShiftModifier) !== 0;
        if (horizontal && !shifted) {
            // Ordinary vertical input belongs to the containing page. Consume
            // after forwarding so Flickable cannot reinterpret it horizontally.
            Scroll.ancestor(view, Scroll.delta(event.pixelDelta.y, event.angleDelta.y));
            event.accepted = true;
        } else {
            const amount = Scroll.delta(event.pixelDelta.y, event.angleDelta.y);
            event.accepted = Scroll.move(view, amount, horizontal) || Scroll.ancestor(view, amount);
        }
    }
}
