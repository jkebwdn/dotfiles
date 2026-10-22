pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls.Basic
import "../../theme" as Theme
Rectangle {
    id: root
    property var outputs: []
    property string selected: ""
    property bool editable: true
    signal selectOutput(string name)
    signal moveOutput(string name, real x, real y)
    function size(o) {
        const m=o.modes.find(m => m.width+"x"+m.height+"@"+(m.refresh/1000) === o.mode)
        if (!m) return Qt.size(0,0)
        return o.transform%2 ? Qt.size(m.height/o.scale,m.width/o.scale) : Qt.size(m.width/o.scale,m.height/o.scale)
    }
    readonly property var bounds: {
        if (!outputs.length) return {x:0,y:0,w:1920,h:1080}
        let x=0,y=0,r=1,b=1
        for(const o of outputs) { const s=size(o);x=Math.min(x,o.x);y=Math.min(y,o.y);r=Math.max(r,o.x+s.width);b=Math.max(b,o.y+s.height) }
        return {x:x,y:y,w:r-x,h:b-y}
    }
    readonly property real factor: Math.max(.01,Math.min((width-32)/bounds.w,(height-32)/bounds.h))
    readonly property real originX: (width-bounds.w*factor)/2-bounds.x*factor
    readonly property real originY: (height-bounds.h*factor)/2-bounds.y*factor
    color: Theme.Theme.background
    border.color: Theme.Theme.border
    radius: 10
    clip: true
    implicitHeight: 220
    Repeater {
        model: root.outputs
        Rectangle {
            id: monitor
            required property var modelData
            property real dx: 0
            property real dy: 0
            objectName: "displayRect-"+modelData.name
            x: root.originX+modelData.x*root.factor+dx
            y: root.originY+modelData.y*root.factor+dy
            width: Math.max(22,root.size(modelData).width*root.factor)
            height: Math.max(22,root.size(modelData).height*root.factor)
            z: modelData.name === root.selected ? 2 : 1
            color: modelData.name === root.selected ? Theme.Theme.overlay : Theme.Theme.surface
            opacity: modelData.enabled ? 1 : .45
            border.width: modelData.name === root.selected ? 3 : 1
            border.color: modelData.name === root.selected ? Theme.Theme.accent : Theme.Theme.border
            radius: 6
            focus: modelData.name===root.selected
            activeFocusOnTab: true
            Accessible.role: Accessible.Button
            Accessible.name: modelData.name+" display; arrow keys move by 32 logical pixels"
            Keys.onPressed: event => {
                if(!root.editable) return
                const directions={};directions[Qt.Key_Left]=[-32,0];directions[Qt.Key_Right]=[32,0];directions[Qt.Key_Up]=[0,-32];directions[Qt.Key_Down]=[0,32]
                const delta=directions[event.key]
                if(delta){root.moveOutput(modelData.name,modelData.x+delta[0],modelData.y+delta[1]);event.accepted=true}
            }
            Text {
                anchors.centerIn: parent
                width: parent.width-12
                text: monitor.modelData.name+"\n"+(monitor.modelData.mirror ? "Mirrors "+monitor.modelData.mirror : monitor.modelData.mode)+"\n"+(monitor.modelData.enabled ? "Scale "+monitor.modelData.scale : "Disabled")
                horizontalAlignment: Text.AlignHCenter
                color: Theme.Theme.text
                font.pixelSize: Math.max(9,Math.min(13,parent.width/12))
                wrapMode: Text.Wrap
                elide: Text.ElideRight
            }
            MouseArea {
                anchors.fill: parent
                property point start
                property real factorAtPress
                onPressed: mouse => { start=mapToItem(root,mouse.x,mouse.y);factorAtPress=root.factor;monitor.forceActiveFocus() }
                onPositionChanged: mouse => {
                    if(pressed && root.editable && monitor.modelData.enabled && !monitor.modelData.mirror){const p=mapToItem(root,mouse.x,mouse.y);monitor.dx=p.x-start.x;monitor.dy=p.y-start.y}
                }
                onReleased: {
                    const x=monitor.modelData.x+monitor.dx/factorAtPress,y=monitor.modelData.y+monitor.dy/factorAtPress
                    const moved=Math.abs(monitor.dx)+Math.abs(monitor.dy)>3
                    monitor.dx=0;monitor.dy=0
                    if(moved)root.moveOutput(monitor.modelData.name,x,y)
                    else root.selectOutput(monitor.modelData.name)
                }
                onCanceled: {monitor.dx=0;monitor.dy=0}
            }
        }
    }
}
