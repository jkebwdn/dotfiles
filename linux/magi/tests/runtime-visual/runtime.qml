import QtQuick
import QtTest
import Quickshell
import "../../.config/quickshell/magi/components/bar" as BarUI
import "../../.config/quickshell/magi/components/controls" as Controls
import "../../.config/quickshell/magi/plugins/bar/controlcentre" as Centre
import "../../.config/quickshell/magi/services" as Services
import "../../.config/quickshell/magi/theme" as Theme
ShellRoot {
    BarUI.Bar { id: bar; expandableHostMode: "combined" }
    QtObject { id: secured; property bool connected: false; property bool known: false; property int security: 999; property string name: "Test secure network"; property real signalStrength: 0.8; signal connectionFailed(int reason) }
    Component { id: artworkFixture; Controls.RoundedArtwork { width: 80; height: 76; source: Qt.resolvedUrl("test-artwork.ppm") } }
    Timer { id: finish; interval: 100; onTriggered: Qt.quit() }
    TestCase {
        name: "RuntimeVisual"
        when: Services.Settings.ready
        function collect(item, predicate) {
            let found = predicate(item) ? [item] : []
            for (const child of item.children || []) found = found.concat(collect(child, predicate))
            return found
        }
        function open(id) {
            Services.MenuController.open(id)
            tryCompare(bar.expandablePillRegistry[id], "phase", 3)
            wait(150)
        }
        function closeOutside() {
            const catcher = findChild(bar.contentItem, "statusDismissCatcher")
            mouseClick(catcher, 10, 400)
            tryCompare(Services.MenuController, "activeMenu", "")
            wait(550)
            verify(!bar.catcherEnabled)
            compare(bar.exclusiveZone, 48)
        }
        function test_artworkContours() {
            const art = createTemporaryObject(artworkFixture, bar.contentItem)
            verify(art !== null)
            const image = findChild(art, "artworkSource")
            tryCompare(image, "status", Image.Ready)
            for (const radius of [0, 10, 20]) {
                art.radius = radius
                for (const border of [0, 2, 6]) {
                    art.borderWidth = border
                    wait(20)
                    const bounds = findChild(art, "artworkImageBounds")
                    const mask = findChild(art, "artworkMask")
                    const effect = findChild(art, "artworkEffect")
                    compare(bounds.x, border)
                    compare(bounds.width, art.width - 2 * border)
                    compare(mask.radius, Math.max(0, radius - border))
                    compare(effect.width, image.width)
                    compare(effect.height, mask.height)
                    verify(!image.visible && image.clip && image.layer.enabled)
                    verify(effect.maskEnabled && effect.maskSource === mask)
                    compare(effect.maskThresholdMin, 0.5)
                    compare(effect.maskSpreadAtMin, 1)
                }
            }
            console.log("Artwork contour geometry PASS")
            // Geometry/source isolation only: software rendering cannot validate GPU edges.
        }
        function test_runtime() {
            try {
            wait(150)
            for (const id of ["notifications", "clipboard"]) {
                verify(!findChild(bar.contentItem, "utilityPill-" + id), "utility absent by default")
                verify(Services.Settings.placeBar(id, "right"))
                wait(100)
                const pill = findChild(bar.contentItem, "utilityPill-" + id)
                verify(pill && pill.visible, "configured utility renders")
                mouseClick(pill)
                compare(Services.Hub.mode, id)
                verify(Services.Hub.opened, "actual Hub route")
                mouseClick(pill)
                verify(!Services.Hub.opened, "same route toggles closed")
                Services.Settings.placeBar(id, "hidden")
                wait(100)
                verify(!findChild(bar.contentItem, "utilityPill-" + id))
            }
            const workspace = findChild(bar.contentItem, "testWorkspaces")
            verify(workspace !== null)
            for (const roundness of [0, 0.5, 1, 2]) {
                Services.Settings.setRoundness("barPill", roundness)
                for (const current of [1, 2, 3, 2, 1]) {
                    workspace.testCurrent = current
                    wait(180)
                    const cells = collect(workspace, item => item.modelData !== undefined && item.isActive !== undefined)
                    compare(cells.length, 3)
                    compare(cells.filter(c => c.isActive).length, 1)
                    for (const cell of cells) {
                        compare(cell.radius, workspace.radius, "same semantic radius at every position")
                        if (cell.isActive) compare(cell.color, Theme.Theme.accent)
                    }
                }
            }
            Services.Settings.resetSection("appearance")
            Services.Settings.setValue("profile", "displayName", "Ada " + "LongName".repeat(9))
            Services.Settings.setValue("profile", "subtitleMode", "custom")
            for (const palette of ["catppuccin-mocha", "catppuccin-frappe", "everforest-dark-hard", "everforest-light-hard"]) {
                Services.Settings.resetSection("controlCentre")
                Services.Settings.setTheme(palette)
                open("controlcentre")
                const profile = findChild(bar.contentItem, "runtimeProfile")
                const greeting = findChild(profile, "profileGreeting")
                const third = findChild(profile, "profileThirdLine")
                verify(profile && profile.visible)
                compare(findChild(profile, "runtimeAvatar").width, 76)
                compare(findChild(profile, "runtimeAvatar").radius, Theme.Theme.radius("avatar", 10, 76, 76), "rounded-square avatar")
                for (const hour of [0, 5, 12, 18, 23]) {
                    profile.localHour = hour
                    verify(greeting.text.startsWith(hour === 5 ? "Morning" : hour === 12 ? "Afternoon" : hour === 18 ? "Evening" : "Night"))
                }
                for (const line of ["", "An optional line", "X".repeat(160)]) {
                    Services.Settings.setValue("profile", "subtitle", line)
                    wait(30)
                    compare(third.visible, line.length > 0)
                    for (const text of [greeting, third, findChild(profile, "profileWeather")]) {
                        const point = text.mapToItem(profile, 0, 0)
                        verify(point.x >= 0 && point.x + text.width <= profile.width + 1, "profile text bounded")
                    }
                }
                compare(findChild(profile, "profileWeather").text, "Weather unavailable")
                const tiles = collect(bar.contentItem, item => item.accentRole !== undefined && item.primaryTriggered !== undefined)
                for (const tile of tiles) {
                    compare(tile.color, Theme.Theme.primaryTileColor(tile.activeColor), "configured accent retained in every tile state")
                    const ink = collect(tile, item => item.role !== undefined && item.resolved !== undefined)[0]
                    verify(Qt.colorEqual(ink.color, Theme.Theme.controlInk(tile.toggle, tile.active, tile.available, false)), "canonical primary state ink")
                }
                const cc = bar.expandablePillRegistry.controlcentre
                for (const columns of [1, 4, 5, 8, 16]) {
                    Services.Settings.setValue("controlCentre", "columns", columns)
                    Services.Settings.setValue("controlCentre", "actionColumns", 2)
                    wait(500)
                    compare(cc.actionColumns, 2, "independent secondary columns")
                    compare(cc.actionRows, 3, "multiple action rows")
                    verify(cc.expandedWidth <= bar.width - 28)
                }
                Services.Settings.setValue("controlCentre", "columns", 1)
                Services.Settings.setValue("controlCentre", "actionColumns", 16)
                wait(500)
                for (const action of ["apps", "notifications", "emoji", "clipboard"]) Services.Settings.addEntry("actions", action)
                wait(500)
                verify(cc.actionRows > 1, "actions wrap to usable cells on narrow surface")
                closeOutside()
            }
            Services.Settings.resetSection("controlCentre")
            for (const id of ["controlcentre", "wifi", "bluetooth"]) {
                open(id)
                if (id !== "controlcentre") {
                    const switches = collect(bar.contentItem, item => item.toggleStyle !== undefined && item.visible)
                    verify(switches.length > 0, id + " production switch exists")
                    Services.Settings.setValue("appearance", "hubToggleRole", "red")
                    for (const style of ["pill", "filled", "minimal"]) {
                        Services.Settings.setValue("appearance", "toggleStyle", style)
                        wait(20)
                        for (const control of switches) {
                            compare(control.toggleStyle, style, id + " consumes shared switch style")
                            compare(findChild(control, "toggleTrack").height, style === "minimal" ? 6 : 18)
                            compare(findChild(control, "toggleKnob").width, style === "filled" ? 8 : 12)
                            compare(control.activeColor, Theme.Theme.accent, "Hub toggle colour does not recolour " + id)
                        }
                    }
                    Services.Settings.setValue("appearance", "toggleStyle", "pill")
                }
                closeOutside()
                open(id)
                const module = bar.expandablePillRegistry[id]
                verify(module.menuKeyboardFocus)
                const body = collect(bar.contentItem, item => item.selected === true && item.modelData === module && item.item !== undefined)[0]
                verify(body !== undefined)
                body.item.forceActiveFocus()
                keyClick(Qt.Key_Escape)
                tryCompare(Services.MenuController, "activeMenu", "")
                wait(550)
                compare(module.phase, 0)
            }
            Services.Network.availableNetworks = [secured]
            open("wifi")
            const wifi = bar.expandablePillRegistry.wifi
            wifi.selectNetwork(secured)
            wait(500)
            let input = collect(bar.contentItem, item => item.objectName === "wifiPasswordInput" && item.visible)[0]
            verify(input !== undefined)
            input.forceActiveFocus()
            keyClick(Qt.Key_Escape)
            verify(!wifi.authenticating)
            compare(Services.MenuController.activeMenu, "wifi", "first Escape cancels password only")
            wifi.selectNetwork(secured)
            wait(500)
            input = collect(bar.contentItem, item => item.objectName === "wifiPasswordInput" && item.visible)[0]
            input.text = "test-only"
            input.accepted()
            verify(wifi.connecting)
            closeOutside()
            verify(wifi.connecting && !wifi.authenticating, "dismissal retains in-flight observation, clears password UI")
            secured.connectionFailed(1)
            verify(!wifi.connecting && Services.MenuController.activeMenu === "", "late failure does not reopen")
            console.log("Runtime optional utilities, workspace transitions, profile bounds, palette ink, action wrapping, outside/Escape dismissal and pending authentication PASS")
            finish.start()
            } catch (error) { console.error("FAIL: " + error + " " + error.stack); throw error }
        }
    }
}
