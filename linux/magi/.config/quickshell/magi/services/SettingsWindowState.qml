pragma Singleton
import QtQuick
QtObject {
    property string page: "Appearance"
    property bool requested: false
    property bool shown: false
    function open() {
        requested = true
        MenuController.close()
    }
}
