pragma Singleton
import QtQuick
QtObject {
    property bool requested: false
    property bool bound: false
    readonly property bool active: requested && bound
    function setRequested(value) { requested = !!value }
}
