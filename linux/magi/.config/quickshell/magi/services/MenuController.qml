
pragma Singleton

import QtQuick
import Quickshell

QtObject {
    id: root

    property string activeMenu: ""

    property var history: []
    readonly property bool canGoBack: history.length > 0

    function toggle(menuId) {
        if (activeMenu === menuId)
            close()
        else
            open(menuId)
    }

    function open(menuId) {
        history = []
        activeMenu = menuId
    }

    function navigate(menuId) {
        if (activeMenu === menuId)
            return
        if (activeMenu !== "")
            history = history.concat([activeMenu])
        activeMenu = menuId
    }

    function back() {
        if (!canGoBack)
            return
        const previous = history[history.length - 1]
        history = history.slice(0, -1)
        activeMenu = previous
    }

    function close() {
        history = []
        activeMenu = ""
    }

    function isOpen(menuId) {
        return activeMenu === menuId
    }
}
