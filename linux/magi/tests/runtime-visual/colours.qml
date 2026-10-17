import QtQuick
import QtTest
import Quickshell
import "../../.config/quickshell/magi/reference" as Old
import "../../.config/quickshell/magi/plugins/bar/controlcentre" as Current
import "../../.config/quickshell/magi/services" as Services
import "../../.config/quickshell/magi/theme" as Theme
ShellRoot {
    FloatingWindow {
        visible: true
        implicitWidth: 400; implicitHeight: 200
        Old.ControlTile { id: old; x: 10; y: 10 }
        Current.ControlTile { id: current; x: 150; y: 10 }
    }
    Timer { id: finish; interval: 100; onTriggered: Qt.quit() }
    TestCase {
        when: Services.Settings.ready
        function icon(tile) {
            for (const child of tile.children) if (child.resolved !== undefined) return child
            fail("Missing production Icon")
        }
        function equalColour(a,b,label) {
            verify(Qt.colorEqual(a,b),label+": "+a+" vs "+b)
            for (const channel of ["r","g","b","a"]) compare(a[channel],b[channel],label+" "+channel)
        }
        function test_referenceEquivalence() {
            try {
                let cases = 0
                // Defaults, signed shade endpoints and mixed/custom semantic roles.
                const settings = [
                    [.28,.48,4,0,.28,"text","background"],
                    [-1,1,0,-1,0,"blue","red"],
                    [1,-1,6,1,1,"lavender","peach"],
                    [-.2,.6,2.5,.35,.7,"subtext","overlay"],
                    [.6,-.3,1,-.4,.3,"background","text"]]
                const keys=["tileBackgroundShade","tileBorderShade","tileBorderWidth","controlOffShade","controlOffOpacity","controlOn","controlOff"]
                for (const pack of ["magi-legacy","magi-default"]) {
                    Services.Settings.setIconPack(pack)
                    for (const palette of ["catppuccin-mocha","everforest-dark-hard","everforest-light-hard"]) {
                        Services.Settings.setTheme(palette)
                        for (const values of settings) {
                            keys.forEach((key,i) => Services.Settings.setVisual(key,values[i]))
                            wait(1)
                            for (const entry of [["wifi","red"],["bluetooth","blue"],["power-saver","peach"],["airplane-mode","lavender"]]) {
                                old.moduleId=current.moduleId=entry[0]
                                old.icon=current.icon=entry[0]
                                old.accentRole=current.accentRole=entry[1]
                                old.activeColor=Old.Theme.primaryAccent(entry[1],"teal")
                                current.activeColor=Theme.Theme.primaryAccent(entry[1],"teal")
                                for (const state of [[true,true,true],[true,false,true],[true,true,false],[false,false,true],[false,true,false]]) {
                                    old.toggle=current.toggle=state[0]
                                    old.active=current.active=state[1]
                                    old.available=current.available=state[2]
                                    equalColour(current.color,old.color,"tile fill")
                                    equalColour(current.border.color,old.border.color,"tile rim")
                                    compare(current.border.width,old.border.width)
                                    equalColour(icon(current).color,icon(old).color,"production icon RGBA")
                                    compare(current.opacity,old.opacity,"whole-tile alpha")
                                    compare(icon(current).semanticAsset,icon(old).semanticAsset)
                                    compare(JSON.stringify(icon(current).resolved),JSON.stringify(icon(old).resolved))
                                    cases++
                                }
                            }
                        }
                    }
                }
                current.forceActiveFocus(); wait(1)
                equalColour(current.border.color,old.border.color,"focus does not replace canonical rim")
                // Accepted new geometry still binds independently of old colours.
                Services.Settings.setVisual("primaryIconSize",48)
                Services.Settings.setVisual("primaryContainerSize",96)
                wait(1)
                compare(icon(current).size,48); compare(current.implicitWidth,96)
                equalColour(icon(current).color,icon(old).color,"geometry leaves colour equivalent")
                console.log("7afd1c6 colour equivalence PASS: " + cases + " production pairs, exact RGBA; glyph/SVG, unavailable/non-toggle and focus")
                finish.start()
            } catch (error) { console.error("FAIL: " + error + " " + error.stack); throw error }
        }
    }
}
