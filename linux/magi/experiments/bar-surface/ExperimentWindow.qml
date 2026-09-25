pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

PanelWindow {
    id: root

    property string hostMode: "anchored"
    property bool reservationEnabled: false
    property string requestedScreenName: ""

    property string activeMenu: ""
    property int requestGeneration: 0
    property bool keyboardEnabled: false
    property string dismissalMode: "mask-only"
    property string placementPreset: "default"
    property var pillRegistry: ({})

    property var leftPlugins: ["status-a"]
    property var centerPlugins: ["status-b"]
    property var rightPlugins: ["menu-one", "menu-two", "status-c"]

    readonly property var activePill:
        activeMenu !== "" ? (pillRegistry[activeMenu] || null) : null
    readonly property Item activeCombinedRegion:
        hostMode === "combined" && activePill
            && activePill.revealedHeight > 0
            ? activePill.combinedMenuRegion
            : null
    readonly property bool catcherEnabled:
        hostMode === "combined"
        && dismissalMode === "consume"
        && activeMenu !== ""

    readonly property var pluginComponents: ({
        "status-a": statusAComponent,
        "status-b": statusBComponent,
        "status-c": statusCComponent,
        "menu-one": menuOneComponent,
        "menu-two": menuTwoComponent
    })

    function resolveScreen(name) {
        const screens = Quickshell.screens
        if (name) {
            for (let i = 0; i < screens.length; ++i) {
                if (screens[i].name === name)
                    return screens[i]
            }
        }
        return screens.length > 0 ? screens[0] : null
    }

    function logEvent(kind, details) {
        const record = Object.assign({
            time: Date.now(),
            event: kind,
            host: hostMode,
            generation: requestGeneration,
            requestedMenu: activeMenu,
            screen: screen ? screen.name : "",
            screenWidth: screen ? screen.width : width,
            screenHeight: screen ? screen.height : height,
            devicePixelRatio: screen ? screen.devicePixelRatio : 1,
            keyboard: keyboardEnabled ? "on-demand" : "none",
            dismissal: dismissalMode,
            reservation: reservationEnabled ? 48 : 0
        }, details || {})
        console.log("MAGI_EXPERIMENT " + JSON.stringify(record))
    }

    function registerPill(menuId, pill) {
        const next = Object.assign({}, pillRegistry)
        next[menuId] = pill
        pillRegistry = next
    }

    function unregisterPill(menuId, pill) {
        if (pillRegistry[menuId] !== pill)
            return
        const next = Object.assign({}, pillRegistry)
        delete next[menuId]
        pillRegistry = next
    }

    function validMenu(menuId) {
        return menuId === "menu-one" || menuId === "menu-two"
    }

    function toggleMenu(menuId, reason) {
        if (!validMenu(menuId)) {
            logEvent("menu-request-rejected", { menu: menuId })
            return
        }

        requestGeneration += 1
        activeMenu = activeMenu === menuId ? "" : menuId
        logEvent("menu-toggled", {
            menu: menuId,
            reason: reason || "ipc"
        })
    }

    function requestClose(menuId, reason) {
        if (activeMenu !== menuId)
            return
        requestGeneration += 1
        activeMenu = ""
        logEvent("menu-closed", {
            menu: menuId,
            reason: reason || "unknown"
        })
    }

    function closeActive(reason) {
        if (activeMenu !== "")
            requestClose(activeMenu, reason)
    }

    function setPreset(name) {
        closeActive("placement-change")
        placementPreset = name

        if (name === "menus-left") {
            leftPlugins = ["menu-one", "menu-two", "status-a"]
            centerPlugins = ["status-b"]
            rightPlugins = ["status-c"]
        } else if (name === "menus-center") {
            leftPlugins = ["status-a"]
            centerPlugins = ["menu-one", "menu-two", "status-b"]
            rightPlugins = ["status-c"]
        } else if (name === "split") {
            leftPlugins = ["menu-one", "status-a"]
            centerPlugins = ["status-b"]
            rightPlugins = ["menu-two", "status-c"]
        } else {
            placementPreset = "default"
            leftPlugins = ["status-a"]
            centerPlugins = ["status-b"]
            rightPlugins = ["menu-one", "menu-two", "status-c"]
        }

        logEvent("placement-changed", { preset: placementPreset })
    }

    function setDismissal(name) {
        if (name === "consume" && hostMode !== "combined") {
            logEvent("dismissal-rejected", {
                requested: name,
                reason: "combined-only"
            })
            return
        }
        dismissalMode = name === "consume" ? "consume" : "mask-only"
        logEvent("dismissal-changed")
    }

    function snapshot() {
        const pills = []
        for (const menuId in pillRegistry) {
            const pill = pillRegistry[menuId]
            if (pill)
                pills.push(pill.snapshot())
        }

        return JSON.stringify({
            host: hostMode,
            generation: requestGeneration,
            requestedMenu: activeMenu,
            placement: placementPreset,
            dismissal: dismissalMode,
            keyboardEnabled: keyboardEnabled,
            reservation: reservationEnabled ? 48 : 0,
            screen: screen ? screen.name : "",
            window: {
                width: root.width,
                height: root.height
            },
            pills: pills
        })
    }

    screen: resolveScreen(requestedScreenName)
    anchors {
        top: true
        left: true
        right: true
    }
    implicitHeight: hostMode === "combined"
        ? Math.max(48, screen ? screen.height : 1080)
        : 48
    exclusiveZone: reservationEnabled ? 48 : 0
    color: "transparent"

    WlrLayershell.namespace: "magi-bar-surface-experiment-" + hostMode
    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.keyboardFocus: keyboardEnabled && activeMenu !== ""
        ? WlrKeyboardFocus.OnDemand
        : WlrKeyboardFocus.None

    mask: Region {
        item: barStrip

        Region {
            item: root.activeCombinedRegion
            intersection: Intersection.Combine
        }

        Region {
            item: root.catcherEnabled ? clickCatcher : null
            intersection: Intersection.Combine
        }
    }

    onActiveMenuChanged: logEvent("requested-menu-changed")
    onKeyboardEnabledChanged: logEvent("keyboard-mode-changed")

    Component.onCompleted: logEvent("fixture-ready", {
        requestedScreen: requestedScreenName
    })
    Component.onDestruction: logEvent("fixture-destroyed")

    IpcHandler {
        target: "magi-bar-surface-experiment"

        function toggle(menuId: string): void {
            root.toggleMenu(menuId, "ipc")
        }

        function close(): void {
            root.closeActive("ipc")
        }

        function preset(name: string): void {
            root.setPreset(name)
        }

        function dismissal(name: string): void {
            root.setDismissal(name)
        }

        function keyboard(enabled: bool): void {
            root.keyboardEnabled = enabled
        }

        function status(): string {
            return root.snapshot()
        }
    }

    Item {
        id: clickCatcher
        anchors.fill: parent
        visible: root.catcherEnabled
        z: 0

        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
            onClicked: root.closeActive("outside-catcher")
        }
    }

    Rectangle {
        id: barStrip
        anchors {
            top: parent.top
            left: parent.left
            right: parent.right
        }
        height: 48
        z: 10
        color: "#20272a"

        Row {
            id: leftSection
            anchors {
                left: parent.left
                leftMargin: 16
                verticalCenter: parent.verticalCenter
            }
            spacing: 8

            Repeater {
                model: root.leftPlugins
                Loader {
                    required property string modelData
                    sourceComponent: root.pluginComponents[modelData] || null
                }
            }
        }

        Row {
            id: centerSection
            anchors.centerIn: parent
            spacing: 8

            Repeater {
                model: root.centerPlugins
                Loader {
                    required property string modelData
                    sourceComponent: root.pluginComponents[modelData] || null
                }
            }
        }

        Row {
            id: rightSection
            anchors {
                right: parent.right
                rightMargin: 16
                verticalCenter: parent.verticalCenter
            }
            spacing: 8

            Repeater {
                model: root.rightPlugins
                Loader {
                    required property string modelData
                    sourceComponent: root.pluginComponents[modelData] || null
                }
            }
        }
    }

    Component {
        id: statusAComponent

        Rectangle {
            implicitWidth: 44
            implicitHeight: 28
            radius: 8
            color: "#30393c"

            Text {
                anchors.centerIn: parent
                text: "A"
                color: "#9da9a0"
                font.pixelSize: 11
            }

            MouseArea {
                anchors.fill: parent
                onClicked: root.logEvent("status-clicked", {
                    plugin: "status-a"
                })
            }
        }
    }

    Component {
        id: statusBComponent

        Rectangle {
            implicitWidth: 44
            implicitHeight: 28
            radius: 8
            color: "#30393c"

            Text {
                anchors.centerIn: parent
                text: "B"
                color: "#9da9a0"
                font.pixelSize: 11
            }

            MouseArea {
                anchors.fill: parent
                onClicked: root.logEvent("status-clicked", {
                    plugin: "status-b"
                })
            }
        }
    }

    Component {
        id: statusCComponent

        Rectangle {
            implicitWidth: 44
            implicitHeight: 28
            radius: 8
            color: "#30393c"

            Text {
                anchors.centerIn: parent
                text: "C"
                color: "#9da9a0"
                font.pixelSize: 11
            }

            MouseArea {
                anchors.fill: parent
                onClicked: root.logEvent("status-clicked", {
                    plugin: "status-c"
                })
            }
        }
    }

    Component {
        id: menuOneComponent

        ExpandablePill {
            experiment: root
            barWindow: root
            hostMode: root.hostMode
            menuId: "menu-one"
            icon: "1"
            title: "Menu one"
            menuContent: Component {
                TestMenuContent {
                    experiment: root
                    menuId: "menu-one"
                }
            }
        }
    }

    Component {
        id: menuTwoComponent

        ExpandablePill {
            experiment: root
            barWindow: root
            hostMode: root.hostMode
            menuId: "menu-two"
            icon: "2"
            title: "Menu two"
            menuHeight: 260
            menuContent: Component {
                TestMenuContent {
                    experiment: root
                    menuId: "menu-two"
                }
            }
        }
    }
}
