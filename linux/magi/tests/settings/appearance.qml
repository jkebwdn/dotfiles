import QtQuick
import Quickshell
import "../../.config/quickshell/magi/services" as Services
import "../../.config/quickshell/magi/theme" as MagiTheme
import "../../.config/quickshell/magi/components/controls" as Controls
import "../../.config/quickshell/magi/plugins/bar/controlcentre" as Centre
ShellRoot {
    id: test
    property int step: 0
    property int failures: 0
    property string expected: ""
    Controls.IconSlider { id: slider; width: 136 }
    Controls.ActionChip { id: action }
    Centre.ControlTile { id: tile }
    function check(ok, label) { if (!ok) { failures++; console.error("FAIL: " + label) } }
    Timer {
        interval: 300; running: true; repeat: true
        onTriggered: {
            if (!Services.Settings.ready) return
            if (test.expected !== "") {
                test.check(MagiTheme.Theme.effectiveTheme === test.expected, "live selected palette")
                test.check(MagiTheme.Theme.surface.toString() === MagiTheme.Theme.definition.roles.surface,
                    "semantic color updates")
            }
            if (test.step < MagiTheme.ThemeRegistry.ids.length) {
                test.expected = MagiTheme.ThemeRegistry.ids[test.step++]
                Services.Settings.setTheme(test.expected)
                return
            }
            switch (test.step++ - MagiTheme.ThemeRegistry.ids.length) {
            case 0: Services.Settings.setRoundness("master", 0); break
            case 1:
                test.check(MagiTheme.Theme.barPillRadius === 0 && tile.radius === 0
                    && MagiTheme.RenderTokens.sliderRadius === 0 && action.radius === 0, "master affects roles live")
                Services.Settings.setRoundness("controlTile", 1.5)
                break
            case 2:
                test.check(tile.radius === 15 && action.radius === 0, "role override isolates radius")
                Services.Settings.setRoundness("surface", 2)
                Services.Settings.setRoundness("barPill", 2)
                break
            case 3:
                test.check(MagiTheme.RenderTokens.outerRadius === 22 && MagiTheme.Theme.barPillRadius === 14,
                    "surface role and pill geometric clamp")
                Services.Settings.resetSection("appearance")
                test.expected = "catppuccin-mocha"
                break
            case 4:
                test.check(tile.radius === 10 && MagiTheme.RenderTokens.sliderRadius === 10
                    && action.radius === 13 && MagiTheme.Theme.barPillRadius === 8, "default radius restoration")
                test.check(MagiTheme.RenderTokens.controlWidth === 320 && MagiTheme.RenderTokens.controlBodyHeight === 208
                    && slider.implicitHeight === 48 && tile.implicitWidth === 60, "geometry unchanged")
                Services.Settings.setTheme("future-uninstalled")
                test.expected = "catppuccin-mocha"
                break
            case 5:
                test.check(MagiTheme.Theme.diagnostic.length > 0, "unknown theme reports fallback")
                Services.Settings.setTheme("catppuccin-mocha")
                break
            case 6:
                console.log("RESULT: " + test.failures + " failures; 10 palettes and live appearance")
                Qt.quit()
            }
        }
    }
}
