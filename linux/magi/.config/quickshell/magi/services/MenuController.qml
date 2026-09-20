
pragma Singleton

import QtQuick
import Quickshell

QtObject {
    id: root

    property string activeMenu: ""

    function toggle(menuId) {
        if (activeMenu === menuId)
            activeMenu = ""
        else
            activeMenu = menuId
    }

    function open(menuId) {
        activeMenu = menuId
    }

    function close() {
        activeMenu = ""
    }

    function isOpen(menuId) {
        return activeMenu === menuId
    }
}
