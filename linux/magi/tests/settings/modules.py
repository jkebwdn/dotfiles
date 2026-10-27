#!/usr/bin/env python3
"""Actual module/session components, with isolated system-service stubs."""
from pathlib import Path
import os, shutil, subprocess, tempfile, sys
root=Path(__file__).resolve().parents[2]
with tempfile.TemporaryDirectory(prefix='magi-modules-') as tmp:
    stage=Path(tmp); config=stage/'config'
    shutil.copytree(root/'.config/quickshell/magi',config)
    (config/'settings.json').write_text('{"schemaVersion":11}')
    stubs={
      'Network': '''property bool connected: false; property bool wifiEnabled: true; property bool wifiHardwareEnabled: true
        property string icon: "wifi"; property string ssid: ""; property int signalStrength: 0
        property var wifiDevice: null; property var activeNetwork: null; property var availableNetworks: []
        property bool scanning: false; property int knownCalls: 0; property int openCalls: 0; property int passwordCalls: 0
        function setScanning(v) {root.scanning=v} function setWifiEnabled(v) {root.wifiEnabled=v} function connectKnown(n) {root.knownCalls++}
        function connectOpen(n) {root.openCalls++} function connectWithPassword(n,p) {root.passwordCalls++}''',
      'Bluetooth': '''property bool available: false; property bool enabled: false; property bool discovering: false
        property var primaryDevice: null; property var devices: []; property int connectedCount: 0
        function displayName(d) {return d ? d.name : ""} function batteryPercent(d) {return d && d.batteryAvailable ? Math.round(d.battery*100) : -1}
        property var prompt: null; property bool busy: false; property string actionPath: ""; property string actionName: ""; property string actionError: ""
        function stateText(d) {return d ? "Connected" : "Unavailable"} function canAct(d) {return !!d && !busy}
        function answer(a,v) {} function cancel() {}
        function setEnabled(v) {root.enabled=v} function setDiscovering(v) {} function toggleConnection(d) {}''',
      'Audio': '''property bool available: false; property bool muted: false; property real volume: 0; property int volumePercent: 0
        property var applications: []; property var outputs: []; property var inputs: []; property var streams: []; property var sink: null; property var source: null
        property var pendingOutput: null; property var pendingInput: null; property string error: ""
        function usable(n){return false} function name(n){return "Audio"} function detail(n,p){return ""} function icon(n){return "volume"} function appIcon(n){return ""}
        function selectOutput(n){} function selectInput(n){} function setNodeVolume(n,v){} function toggleNodeMute(n){}
        function setVolume(v) {} function toggleMute() {} function adjustVolume(v) {}''',
      'Battery': '''property bool charging: false; property bool available: false; property string icon: "battery"; property int percentage: 0
        property string stateText: ""; property string timeText: ""''',
      'Brightness': 'property bool available: false; property int percent: 0; function setPercent(v) {}',
      'Media': '''property bool available: false; property string identity: ""; property string title: ""; property string artist: ""
        property real progress: -1; property string artworkUrl: ""; property bool playing: false; property bool canToggle: true
        property bool canPrevious: true; property bool canNext: true
        function previous() {} function togglePlaying() {} function next() {}''',
      'QuickActions': '''property bool powerAvailable: false; property bool powerSaver: false; property string powerProfile: ""
        property bool vpnAvailable: false; property bool vpnActive: false; property string vpnName: ""
        property bool dndAvailable: true; property bool dndActive: false; property bool lockAvailable: true
        property bool hibernateAvailable: false; property bool shutdownAvailable: true
        property bool rebootAvailable: true; property var executed: []
        function actionAvailable(v) {return v === "lock" ? lockAvailable : v === "shutdown" ? shutdownAvailable : v === "reboot" ? rebootAvailable : v === "hibernate" ? hibernateAvailable : false}
        function setPowerSaver(v) {root.powerSaver=v} function toggleVpn() {root.vpnActive=!root.vpnActive} function setDnd(v) { root.dndActive=v } function execute(v) {root.executed=root.executed.concat([v])}''',
      'AirplaneMode': '''property bool active: false; property bool priorWifi: false; property bool priorBluetooth: false
        function begin(w,b){root.priorWifi=w;root.priorBluetooth=b;root.active=true}
        function end(){const r={wifi:root.priorWifi,bluetooth:root.priorBluetooth};root.active=false;return r}
        function cancel(){root.active=false}''',
      'Caffeine': 'property bool requested: false; property bool bound: true; readonly property bool active: requested && bound; function setRequested(v) {requested=v}',
      'ActionConfirmation': 'property string armedAction: ""; function request(v) {if (armedAction===v){armedAction="";return true} armedAction=v;return false} function cancel(){armedAction=""}'
    }
    for name,body in stubs.items():
        (config/f'services/{name}.qml').write_text('pragma Singleton\nimport QtQuick\nQtObject { id: root\n'+body+'\n}')
    if len(sys.argv) > 1 and sys.argv[1] in ('catalogue', 'window.qml'):
        path = config / 'components/hub/HubWindow.qml'
        text = path.read_text().replace('PanelWindow {', 'FloatingWindow {\n    implicitWidth: 1280; implicitHeight: 900')
        path.write_text('\n'.join(line for line in text.splitlines() if not any(token in line for token in
            ['anchors { top: true;', 'exclusionMode:', 'WlrLayershell.'])))
    if len(sys.argv) > 1 and sys.argv[1] == 'anchored-layout.qml':
        # Test actual animation owners without creating offscreen native popups.
        (config/'components/bar/menu/AnchoredPopupHost.qml').write_text('''import QtQuick
Item {
    property var barWindow: null; property Item anchorItem: null
    property real menuWidth: 0; property real revealedHeight: 0
    property int menuHeight: 0; property real contentOpacity: 0
    property color menuColor: "transparent"
    property Component menuContent: null; property Component fallbackContent: null
}
''')
    fixture = root / 'tests/hub/catalogue.qml' if len(sys.argv) > 1 and sys.argv[1] == 'catalogue' else Path(__file__).with_name(sys.argv[1] if len(sys.argv) > 1 else 'modules.qml')
    (config/'test.qml').write_text(fixture.read_text().replace('../../.config/quickshell/magi/',''))
    runtime=stage/'runtime';runtime.mkdir(mode=0o700)
    env=dict(os.environ, QT_QPA_PLATFORM='offscreen',QT_QUICK_BACKEND='software',XDG_RUNTIME_DIR=str(runtime),XDG_STATE_HOME=str(stage/'state'),HOME=str(stage),XDG_CONFIG_HOME=str(stage/'xdg-config'),XDG_DATA_HOME=str(stage/'data'),XDG_CACHE_HOME=str(stage/'cache'))
    env.pop('WAYLAND_DISPLAY',None);env.pop('DISPLAY',None)
    p=subprocess.run(['quickshell','-p',str(config/'test.qml'),'--no-color'],env=env,capture_output=True,text=True,timeout=30)
    out=p.stdout+p.stderr;print(out)
    # Qt's offscreen platform cannot install a native window mask. Only this
    # exact platform warning is allowed for the normal-window harness.
    checked = '\n'.join(line for line in out.splitlines()
                        if 'ERROR quickshell.ipc: Failed to start IPC server' not in line)
    if len(sys.argv) > 1 and sys.argv[1] in ("window.qml", "catalogue"):
        checked = checked.replace("  WARN: This plugin does not support setting window masks", "")
    assert p.returncode==0 and 'RESULT: 0 failures' in out and 'ERROR' not in checked and 'WARN' not in checked
