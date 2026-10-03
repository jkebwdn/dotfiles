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
    readonly property string selectedAccent: Services.Settings.data.controlCentre.controls[0].accent
    Centre.ControlTile {
        id: configuredTile
        activeColor: MagiTheme.Theme.primaryAccent(test.selectedAccent, "teal")
    }
    function near(a, b) { return Math.abs(a.r-b.r) < .005 && Math.abs(a.g-b.g) < .005 && Math.abs(a.b-b.b) < .005 }
    function mixed(a, b, amount) { return Qt.rgba(a.r*(1-amount)+b.r*amount, a.g*(1-amount)+b.g*amount, a.b*(1-amount)+b.b*amount, 1) }
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
            if (test.expected !== "" && test.step <= MagiTheme.ThemeRegistry.ids.length) {
                const theme = MagiTheme.Theme
                for (const role of ["teal", "blue", "green", "lavender"]) {
                    tile.activeColor = theme.roles[role]
                    const base = tile.activeColor
                    test.check(test.near(theme.shadeAccent(base, 0), base), "zero preserves " + role)
                    test.check(test.near(theme.shadeAccent(base, -.3), test.mixed(base, theme.shadeLight, .3)), "palette lightening " + role)
                    test.check(test.near(tile.color, test.mixed(base, theme.shadeDark, .28)), "live palette background " + role)
                    test.check(test.near(tile.border.color, test.mixed(base, theme.shadeDark, .48)), "same-accent darker border " + role)
                }
                test.check(theme.controlOn.toString() === theme.text.toString(), "on icon stays Text across palettes")
                test.check(Qt.colorEqual(configuredTile.activeColor, theme.roles[test.selectedAccent]),
                    "semantic accent resolves in " + theme.effectiveTheme)
                test.check(test.near(configuredTile.color, theme.primaryTileColor(configuredTile.activeColor))
                    && test.near(configuredTile.border.color, theme.primaryTileRim(configuredTile.activeColor)),
                    "configured accent feeds both shade layers")
                test.check(Qt.colorEqual(theme.primaryAccent("unsupported", "teal"), theme.roles.teal),
                    "unsupported accent uses deterministic fallback")
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
                test.check(MagiTheme.Theme.statusIconSize === 18, "fresh/reset icon size is 18")
                Services.Settings.setTheme("future-uninstalled")
                test.expected = "catppuccin-mocha"
                break
            case 5:
                test.check(MagiTheme.Theme.diagnostic.length > 0, "unknown theme reports fallback")
                Services.Settings.setTheme("catppuccin-mocha")
                break
            case 6:
                test.check(test.near(tile.color, MagiTheme.Theme.primaryTileColor(tile.activeColor)), "off primary tile retains color")
                test.check(MagiTheme.Theme.controlInk(false,false,true,false).toString() === MagiTheme.Theme.controlOn.toString(), "non-toggle bright")
                test.check(MagiTheme.Theme.controlInk(true,false,true,false).a < .5, "off toggle recedes")
                test.check(MagiTheme.Theme.controlInk(true,true,true,false).toString() === MagiTheme.Theme.controlOn.toString(), "on toggle bright")
                test.check(MagiTheme.Theme.controlInk(false,true,true,true).toString() === MagiTheme.Theme.danger.toString(), "armed action danger")
                Services.Settings.setVisual("statusIconSize", 24)
                Services.Settings.setVisual("tileBorderWidth", 5)
                Services.Settings.setVisual("sliderFill", "blue")
                break
            case 7:
                test.check(MagiTheme.Theme.statusIconSize === 24 && tile.border.width === 5
                    && slider.fillColor.toString() === MagiTheme.Theme.blue.toString(), "visual settings propagate live")
                Services.Settings.setVisual("tileBackgroundShade", -.2)
                Services.Settings.setVisual("tileBorderShade", .6)
                break
            case 8:
                test.check(test.near(tile.color, test.mixed(tile.activeColor, MagiTheme.Theme.shadeLight, .2))
                    && test.near(tile.border.color, test.mixed(tile.activeColor, MagiTheme.Theme.shadeDark, .6)), "shade controls update live")
                if (Services.Settings.saveState !== "saved") { test.step--; break }
                Services.Settings.discardAndReload()
                break
            case 9:
                test.check(Services.Settings.data.appearance.visual.tileBackgroundShade === -.2
                    && Services.Settings.data.appearance.visual.tileBorderShade === .6
                    && MagiTheme.Theme.statusIconSize === 24, "shades and custom icon size survive disk reload")
                console.log("RESULT: " + test.failures + " failures; 10 palettes and live appearance")
                Qt.quit()
            }
        }
    }
}
