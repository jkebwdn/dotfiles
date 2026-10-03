#!/usr/bin/env python3
"""Actual module/session components, with isolated system-service stubs."""
from pathlib import Path
import os, shutil, subprocess, tempfile, sys
root=Path(__file__).resolve().parents[2]
with tempfile.TemporaryDirectory(prefix='magi-modules-') as tmp:
    stage=Path(tmp); config=stage/'config'
    shutil.copytree(root/'.config/quickshell/magi',config)
    stubs={
      'Network': '''property bool connected: false; property bool wifiEnabled: true; property bool wifiHardwareEnabled: true
        property string icon: "wifi"; property string ssid: ""; property int signalStrength: 0
        property var activeNetwork: null; property var availableNetworks: []
        property bool scanning: false; property int knownCalls: 0; property int openCalls: 0; property int passwordCalls: 0
        function setScanning(v) {root.scanning=v} function setWifiEnabled(v) {root.wifiEnabled=v} function connectKnown(n) {root.knownCalls++}
        function connectOpen(n) {root.openCalls++} function connectWithPassword(n,p) {root.passwordCalls++}''',
      'Bluetooth': '''property bool available: false; property bool enabled: false; property bool discovering: false
        property var primaryDevice: null; property var devices: []; property int connectedCount: 0
        function displayName(d) {return d ? d.name : ""} function batteryPercent(d) {return d && d.batteryAvailable ? Math.round(d.battery*100) : -1}
        function setEnabled(v) {root.enabled=v} function setDiscovering(v) {} function toggleConnection(d) {}''',
      'Audio': '''property bool available: false; property bool muted: false; property real volume: 0; property int volumePercent: 0
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
        function setPowerSaver(v) {root.powerSaver=v} function toggleVpn() {root.vpnActive=!root.vpnActive} function setDnd(v) { root.dndActive=v } function execute(v) {}''',
      'AirplaneMode': '''property bool active: false; property bool priorWifi: false; property bool priorBluetooth: false
        function begin(w,b){root.priorWifi=w;root.priorBluetooth=b;root.active=true}
        function end(){const r={wifi:root.priorWifi,bluetooth:root.priorBluetooth};root.active=false;return r}
        function cancel(){root.active=false}''',
      'Caffeine': 'property bool requested: false; property bool bound: true; readonly property bool active: requested && bound; function setRequested(v) {requested=v}',
      'ActionConfirmation': 'property string armedAction: ""; function request(v) {if (armedAction===v){armedAction="";return true} armedAction=v;return false} function cancel(){armedAction=""}'
    }
    for name,body in stubs.items():
        (config/f'services/{name}.qml').write_text('pragma Singleton\nimport QtQuick\nQtObject { id: root\n'+body+'\n}')
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
    (config/'test.qml').write_text(Path(__file__).with_name(sys.argv[1] if len(sys.argv) > 1 else 'modules.qml').read_text().replace('../../.config/quickshell/magi/',''))
    runtime=stage/'runtime';runtime.mkdir(mode=0o700)
    env=dict(os.environ, QT_QPA_PLATFORM='offscreen',QT_QUICK_BACKEND='software',XDG_RUNTIME_DIR=str(runtime),XDG_STATE_HOME=str(stage/'state'))
    env.pop('WAYLAND_DISPLAY',None);env.pop('DISPLAY',None)
    p=subprocess.run(['quickshell','-p',str(config/'test.qml'),'--no-color'],env=env,capture_output=True,text=True,timeout=30)
    out=p.stdout+p.stderr;print(out)
    # Qt's offscreen platform cannot install a native window mask. Only this
    # exact platform warning is allowed for the normal-window harness.
    checked = '\n'.join(line for line in out.splitlines()
                        if 'ERROR quickshell.ipc: Failed to start IPC server' not in line)
    if len(sys.argv) > 1 and sys.argv[1] == "window.qml":
        checked = checked.replace("  WARN: This plugin does not support setting window masks", "")
    assert p.returncode==0 and 'RESULT: 0 failures' in out and 'ERROR' not in checked and 'WARN' not in checked
