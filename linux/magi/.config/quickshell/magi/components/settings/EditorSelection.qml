import QtQuick
QtObject {
    property string scope: "host"
    property string family: "host"
    property string instance: ""
    property var familyForInstance: function(id) { return "item" }
    function select(id) {
        instance = id
        scope = id ? "module" : "host"
        family = id ? familyForInstance(id) : "host"
    }
    function reconcile(ids) { if (instance && !ids.includes(instance)) select("") }
}
