import QtQuick
QtObject {
    // Entirely synthetic application artwork. Never consults the user's tray.
    function icon(colour, shape) {
        return "data:image/svg+xml," + encodeURIComponent('<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24"><rect x="1" y="1" width="22" height="22" rx="6" fill="'+colour+'"/><path d="'+shape+'" fill="none" stroke="white" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/></svg>')
    }
    readonly property var items: [
        {id:"fixture-vpn",title:"Example VPN",icon:icon("#d8843b","M7 9L12 5L17 9V15L12 19L7 15Z"),status:1},
        {id:"fixture-sync",title:"Example Sync",icon:icon("#347ba6","M6 11A6 6 0 0 1 17 8M17 5V9H13M18 13A6 6 0 0 1 7 16M7 19V15H11"),status:1},
        {id:"fixture-utility",title:"Example Utility",icon:icon("#8060a4","M8 6V18M16 6V18M5 10H11M13 15H19"),status:0},
        {id:"fixture-attention",title:"Example needs attention",icon:icon("#388a73","M12 5L20 19H4ZM12 10V14M12 17V17.1"),status:2},
        {id:"fixture-extra",title:"Example background task",icon:icon("#4565a0","M6 12H18M12 6V18"),status:1}
    ]
}
