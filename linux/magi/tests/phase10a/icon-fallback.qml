import QtQuick
import QtQuick.Window
import QtTest
import Quickshell
import "../../.config/quickshell/magi/components/bar" as BarUI
import "../../.config/quickshell/magi/components/controls" as Controls
import "../../.config/quickshell/magi/services" as Services
import "../../.config/quickshell/magi/theme" as Theme
import "../../.config/quickshell/magi/icons" as Icons
ShellRoot {
    BarUI.Bar { id: bar; expandableHostMode: "combined" }
    FloatingWindow {
        id: gallery; visible: true; implicitWidth: 840; implicitHeight: 310; color: Theme.Theme.surface
        Column {
            anchors.fill: parent; anchors.margins: 20; spacing: 18
            Text { text: "Incomplete alternate pack → exact MAGI default roles"; color: Theme.Theme.text; font.pixelSize: 18 }
            Text { text: "Only Wi-Fi is supplied by this test pack. All other IDs use MAGI Default."; color: Theme.Theme.subtext }
            Row {
                spacing: 12
                Repeater {
                    model: ["wifi","battery-unknown","battery-charging","battery-full","battery-high","battery-medium","battery-low"]
                    Column {
                        required property string modelData
                        width: 100; spacing: 8
                        Controls.Icon { anchors.horizontalCenter: parent.horizontalCenter; role: parent.modelData; size: 30; color: Theme.Theme.text }
                        Text { width: 100; text: parent.modelData; color: Theme.Theme.subtext; font.pixelSize: 10; wrapMode: Text.Wrap; horizontalAlignment: Text.AlignHCenter }
                    }
                }
            }
            Row {
                spacing: 12
                Repeater {
                    model: ["settings","lock","dnd","caffeine","shutdown","brightness","calendar"]
                    Column {
                        required property string modelData
                        width: 100; spacing: 8
                        Controls.Icon { anchors.horizontalCenter: parent.horizontalCenter; role: parent.modelData; size: 30; color: Theme.Theme.teal }
                        Text { width: 100; text: parent.modelData; color: Theme.Theme.subtext; font.pixelSize: 10; wrapMode: Text.Wrap; horizontalAlignment: Text.AlignHCenter }
                    }
                }
            }
            Text { text: "Calendar removed from both fixture packs → real missing.svg asset."; color: Theme.Theme.subtext }
        }
    }
    Controls.Icon { id: missing; role: "calendar"; size: 24; color: Theme.Theme.teal }
    Controls.Icon { id: broken; role: "settings"; size: 24 }
    Timer { id: finish; interval: 100; onTriggered: Qt.quit() }
    TestCase {
        when: Services.Settings.ready && Icons.IconRegistry.packs.length >= 3
        function collect(item) {
            let icons=item.resolved !== undefined && item.role !== undefined ? [item] : []
            for(const child of item.children || []) icons=icons.concat(collect(child))
            return icons
        }
        function snap(item,name) {
            const dir=Quickshell.env("MAGI_FALLBACK_CAPTURES")
            if(dir) { grabImage(item);wait(100);grabImage(item).save(dir+"/"+name+".png") }
        }
        function test_fallback() {
            try {
                // Deliberately remove a real semantic role from both fixture packs.
                Icons.IconRegistry.packs=Icons.IconRegistry.packs.map(pack=>{
                    const roles=Object.assign({},pack.roles);delete roles.calendar
                    return Object.assign({},pack,{roles:roles})
                })
                Services.Settings.setIconPack('incomplete-fixture')
                Services.Battery.available=true;Services.Battery.percentage=80
                Services.Bluetooth.available=true;Services.Bluetooth.enabled=true;Services.Bluetooth.connectedCount=1
                Services.Audio.available=true;Services.Audio.volumePercent=70
                Services.Brightness.available=true;Services.Brightness.percent=70
                wait(150)
                compare(Icons.IconRegistry.batteryRole(true,false,80),'battery-high')
                compare(Icons.IconRegistry.resolve('battery-high').sourcePack,'magi-default')
                compare(Icons.IconRegistry.resolve('wifi').sourcePack,'incomplete-fixture')
                compare(missing.resolved.icon.kind,'placeholder')
                verify(missing.semanticAsset);compare(missing.color,Theme.Theme.teal)
                verify(String(missing.placeholderSource).endsWith('/magi-default/missing.svg'))
                const ids=['settings','lock','dnd','caffeine','battery-unknown','battery-high','brightness']
                for(const id of ids) {
                    const result=Icons.IconRegistry.resolve(id)
                    compare(result.sourcePack,'magi-default',id)
                    verify(result.icon.kind!=='placeholder',id)
                    verify(result.icon.text!=='?',id)
                }
                // Exercise the renderer's image failure recovery, beyond descriptor lookup.
                Icons.IconRegistry.packs=Icons.IconRegistry.packs.map(pack=>pack.id==='incomplete-fixture'
                    ? Object.assign({},pack,{roles:{wifi:pack.roles.wifi,settings:{asset:'unreadable.svg'}}}) : pack)
                tryCompare(broken,'failureStage',1)
                compare(broken.resolved.sourcePack,'magi-default')
                compare(broken.resolved.icon.kind,'glyph')
                // Failure of the default asset itself must terminate at the bundled SVG.
                const saved=Icons.IconRegistry.packs
                Icons.IconRegistry.packs=saved.map(pack=>pack.id==='magi-default'
                    ? Object.assign({},pack,{roles:Object.assign({},pack.roles,{'fixture-broken':{asset:'unreadable.svg'}})}) : pack)
                broken.role='fixture-broken';tryCompare(broken,'failureStage',2)
                compare(broken.resolved.icon.kind,'placeholder')
                Icons.IconRegistry.packs=saved;broken.role='settings'
                Services.MenuController.close();wait(350)
                const status=collect(bar.contentItem).filter(i=>i.visible)
                verify(status.some(i=>i.role==='battery-high'))
                for(const icon of status) verify(icon.resolved.icon.text!=='?')
                bar.contentItem.Window.window.height=48;wait(80)
                snap(bar.contentItem,'bar-battery-high')
                bar.contentItem.Window.window.height=800;wait(80)
                Services.SurfaceOrigin.mainScreen = bar.outputScreen
                Services.SurfaceOrigin.enabledScreens = [bar.outputScreen]
                Services.MenuController.open('controlcentre', bar.outputScreen)
                tryCompare(bar.expandablePillRegistry.controlcentre,'phase',3)
                wait(150)
                const ccIcons=collect(bar.contentItem).filter(i=>i.visible)
                verify(ccIcons.some(i=>i.role==='caffeine'))
                for(const icon of ccIcons) {
                    verify(icon.resolved.icon.kind!=='placeholder',icon.role)
                    verify(icon.resolved.icon.text!=='?',icon.role)
                }
                snap(bar.activeCombinedRegion,'control-centre-incomplete-pack')
                snap(gallery.contentItem,'semantic-fallback-gallery')
                console.log('Icon fallback production bar/CC/battery, real SVG placeholder and image-error recovery PASS')
            } catch(e) {console.error('FAIL: '+e+' '+e.stack)}
            finish.start()
        }
    }
}
