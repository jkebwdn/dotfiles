import QtQuick
import "../lockPresentation" as Lock
Item {
    id: root
    property string kind
    property string choice
    property var palette
    Lock.LockTokens {id:tokens;palette:root.palette || ({})}
    Lock.LockCredential {anchors.centerIn:parent;width:90;scale:.65;tokens:tokens;characterCount:6;style:root.choice;visible:root.kind==="credential"}
    Lock.LockProfile {anchors.centerIn:parent;width:160;scale:.3;tokens:tokens;displayName:"Alex";treatment:root.choice;visible:root.kind==="avatar"}
    Lock.LockAuxiliary {
        anchors.centerIn:parent;width:180;scale:root.kind==="media" && root.choice==="artwork" ? .25 : .42;tokens:tokens;style:root.choice
        media:root.kind==="media";snapshot:({available:true,temperature:"12°",condition:"Partly cloudy",title:"Morning light",artist:"Sample artist",artwork:true})
        artworkSource:Qt.resolvedUrl("lock-depth-fixture.svg")
        visible:root.kind==="weather" || root.kind==="media"
    }
}
