// Editor only; shared native types are explicitly declared in their qmldir.
import QtQuick
import "../lockPresentation" as Lock
import "../lockPresentation/LockLayout.js" as Model
Item {
    id: root
    property var layout: Model.preset("centered")
    property var palette: ({})
    property string selected: "time"
    property int stateIndex: 0
    property real aspect: 16/9
    property bool interactive: true
    property var draft: null
    property real guideX: -1
    property real guideY: -1
    readonly property var effective: draft || Model.normalize(layout)
    signal committed(var value)
    signal selectionRequested(string id)
    implicitHeight: width/aspect
    clip: true
    activeFocusOnTab: interactive
    Accessible.name: "Lock screen layout canvas"
    function begin() {
        const next=Model.copy(effective), s=scene.unit
        if (next.space === "composition") {
            for (const id of Model.ids()) {
                const box=scene.elementBoxes[id]
                next.elements[id]=Model.place(next.elements[id],box.x,box.y,scene.width/s,scene.height/s,box.width*box.scale,box.height*box.scale)
            }
            next.space="screen"
        }
        next.preset="custom"; draft=next
    }
    function move(id,x,y,bypass) {
        const next=Model.copy(draft), box=scene.elementBoxes[id], s=scene.unit
        const w=scene.width/s,h=scene.height/s,ew=box.width*box.scale,eh=box.height*box.scale
        const othersX=[],othersY=[]
        for (const other of Model.ids()) if (other!==id && scene.elementBoxes[other].visible) {
            const b=scene.elementBoxes[other]
            othersX.push(b.x,b.x+b.width*b.scale/2,b.x+b.width*b.scale)
            othersY.push(b.y,b.y+b.height*b.scale/2,b.y+b.height*b.scale)
        }
        const sx=Model.snap(x,ew,w,othersX,bypass),sy=Model.snap(y,eh,h,othersY,bypass)
        guideX=sx.guide*s;guideY=sy.guide*s
        const e=Model.place(next.elements[id],sx.value,sy.value,w,h,ew,eh)
        const bounded=Model.position(e,w,h,ew,eh)
        next.elements[id]=Model.place(e,bounded.x,bounded.y,w,h,ew,eh);draft=next
    }
    function finish() { if (draft) { const result=draft;draft=null;committed(result) };guideX=-1;guideY=-1 }
    function cancel() { draft=null;guideX=-1;guideY=-1 }
    Keys.onPressed: event => {
        if (!interactive) return
        if (event.key===Qt.Key_Escape) { cancel();event.accepted=true;return }
        const delta=event.modifiers & Qt.ShiftModifier ? 10 : 1
        const dx=event.key===Qt.Key_Left ? -delta : event.key===Qt.Key_Right ? delta : 0
        const dy=event.key===Qt.Key_Up ? -delta : event.key===Qt.Key_Down ? delta : 0
        if (dx || dy) { begin();const b=scene.elementBoxes[selected];move(selected,b.x+dx,b.y+dy,true);finish();event.accepted=true }
    }
    Rectangle { anchors.fill: parent; color: "transparent"; border.width: root.interactive ? 1 : 0; border.color: root.palette.subtext || "#bac2de"; z: 40; opacity: .3 }
    Item {
        id: plane
        width: 1600; height: width/root.aspect
        scale: root.width/width; transformOrigin: Item.TopLeft
        Lock.LockScreen {
            id: scene
            objectName: "syntheticScene"
            anchors.fill: parent
            readonly property real unit: Math.max(.8,Math.min(1.15,Math.pow(Math.min(width/1920,height/1080),.45)))
            visual: Object.assign({},root.palette,{displayName:"Alex Morgan",lockScreen:root.effective})
            timeLabel: "09:41"; dateLabel: "Saturday, 24 October"
            characterCount: root.stateIndex===1 ? 6 : 0
            inputActive: true; capsLock: root.stateIndex===4
            authStatus: root.stateIndex===2 ? "Authenticating" : root.stateIndex===3 ? "Authentication failed" : "Locked"
        }
        Repeater {
            model: Model.ids()
            Item {
                id: overlay
                required property string modelData
                Accessible.role: Accessible.Button
                Accessible.name: ({time:"Clock and date element",identity:"Avatar and username element",authentication:"Authentication element"})[modelData]
                Accessible.onPressAction: { root.selectionRequested(modelData);root.forceActiveFocus() }
                readonly property var box: scene.elementBoxes[modelData]
                x: box.x*scene.unit; y: box.y*scene.unit
                width: box.width*box.scale*scene.unit
                height: Math.max(36,box.height*box.scale*scene.unit)
                visible: root.interactive && box.visible
                z: 10+box.z
                Rectangle { anchors.fill: parent; color:"transparent";border.color:root.palette.accent || "#b4befe";border.width:root.selected===overlay.modelData ? 2/plane.scale : 0;radius:6 }
                MouseArea {
                    anchors.fill: parent;preventStealing:true
                    cursorShape: pressed ? Qt.ClosedHandCursor : Qt.OpenHandCursor
                    property point start
                    property point position
                    property bool moved: false
                    onPressed: mouse => { root.selectionRequested(overlay.modelData);root.forceActiveFocus();start=mapToItem(plane,mouse.x,mouse.y);position=Qt.point(overlay.box.x,overlay.box.y);moved=false;root.begin() }
                    onPositionChanged: mouse => {
                        if (!pressed || !root.draft) return
                        const p=mapToItem(plane,mouse.x,mouse.y)
                        moved=true;root.move(overlay.modelData,position.x+(p.x-start.x)/scene.unit,position.y+(p.y-start.y)/scene.unit,Boolean(mouse.modifiers & Qt.AltModifier))
                    }
                    onReleased: mouse => {
                        const p=mapToItem(plane,mouse.x,mouse.y)
                        if (root.draft && (moved || Math.abs(p.x-start.x)+Math.abs(p.y-start.y)>2)) {
                            root.move(overlay.modelData,position.x+(p.x-start.x)/scene.unit,position.y+(p.y-start.y)/scene.unit,Boolean(mouse.modifiers & Qt.AltModifier))
                            root.finish()
                        } else root.cancel()
                    }
                    onCanceled: root.cancel()
                    onWheel: wheel => { wheel.accepted=true }
                }
            }
        }
        Rectangle { visible:root.guideX>=0;x:root.guideX;width:1/plane.scale;height:plane.height;color:root.palette.accent || "#b4befe";opacity:.65;z:20 }
        Rectangle { visible:root.guideY>=0;y:root.guideY;height:1/plane.scale;width:plane.width;color:root.palette.accent || "#b4befe";opacity:.65;z:20 }
    }
}
