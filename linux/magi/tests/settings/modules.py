#!/usr/bin/env python3
"""Actual module/session components, with isolated system-service and password-window stubs."""
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
        function setScanning(v) {} function setWifiEnabled(v) {} function connectKnown(n) {}
        function connectOpen(n) {} function connectWithPassword(n,p) {}''',
      'Bluetooth': '''property bool available: false; property bool enabled: false; property bool discovering: false
        property var primaryDevice: null; property var devices: []; property int connectedCount: 0
        function displayName(d) {return ""} function batteryPercent(d) {return -1}
        function setEnabled(v) {} function setDiscovering(v) {} function toggleConnection(d) {}''',
      'Audio': '''property bool available: false; property bool muted: false; property real volume: 0; property int volumePercent: 0
        function setVolume(v) {} function toggleMute() {}''',
      'Battery': '''property bool charging: false; property bool available: false; property string icon: "battery"; property int percentage: 0
        property string stateText: ""; property string timeText: ""''',
      'Brightness': 'property bool available: false; property int percent: 0; function setPercent(v) {}',
      'Media': '''property bool available: false; property string identity: ""; property string title: ""; property string artist: ""
        property string artworkUrl: ""; property bool playing: false; property bool canToggle: true
        property bool canPrevious: true; property bool canNext: true
        function previous() {} function togglePlaying() {} function next() {}'''
    }
    for name,body in stubs.items():
        (config/f'services/{name}.qml').write_text('pragma Singleton\nimport QtQuick\nQtObject {\n'+body+'\n}')
    (config/'plugins/bar/wifi/WifiPasswordWindow.qml').write_text('''import QtQuick
QtObject { property var network: null; property bool connecting: false
signal submitted(string password); signal cancelled(); function clearPassword() {} }
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
