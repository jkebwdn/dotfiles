#!/usr/bin/env python3
from pathlib import Path
import os
import shutil
import subprocess
import tempfile
root=Path(__file__).resolve().parents[2]
subprocess.run(['python3',str(Path(__file__).with_name('actions.py'))],check=True)
with tempfile.TemporaryDirectory(prefix='magi-bluetooth-ui-') as tmp:
    stage=Path(tmp);config=stage/'shell'
    shutil.copytree(root/'.config/quickshell/magi',config)
    (config/'settings.json').write_text('{"schemaVersion":21}')
    # Execute production coordinator/presentation, replace only transport + input model.
    path=config/'services/Bluetooth.qml';source=path.read_text()
    source=source.replace('readonly property var adapter: QsBluetooth.Bluetooth.defaultAdapter','property var adapter: null\n    property var testCommands: []')
    a=source.index('    property Process worker: Process {');b=source.index('    property Instantiator',a)
    source=source[:a]+'''    property QtObject worker: QtObject {
        property bool running: true
        function write(text) { root.testCommands = root.testCommands.concat([JSON.parse(text)]) }
    }

'''+source[b:]
    path.write_text(source)
    (config/'test.qml').write_text(Path(__file__).with_name('presentation.qml').read_text().replace('../../.config/quickshell/magi/',''))
    runtime=stage/'runtime';runtime.mkdir(mode=0o700)
    env=dict(os.environ,HOME=str(stage),XDG_CONFIG_HOME=str(stage/'config'),XDG_STATE_HOME=str(stage/'state'),XDG_DATA_HOME=str(stage/'data'),XDG_CACHE_HOME=str(stage/'cache'),XDG_RUNTIME_DIR=str(runtime),QT_QPA_PLATFORM='offscreen',QT_QUICK_BACKEND='software')
    for name in ['WAYLAND_DISPLAY','DISPLAY','HYPRLAND_INSTANCE_SIGNATURE','DBUS_SESSION_BUS_ADDRESS']:env.pop(name,None)
    result=subprocess.run(['quickshell','-p',str(config/'test.qml'),'--no-color'],env=env,text=True,capture_output=True,timeout=35)
    output=result.stdout+result.stderr;print(output)
    known=['Failed to start IPC server','This plugin does not support setting window masks','Unable to find hyprland socket','Could not connect to DBus','Could not find an available backend']
    checked='\n'.join(line for line in output.splitlines() if not any(k in line for k in known))
    assert result.returncode==0 and 'Bluetooth production menu/service and authentication PASS' in output and not any(k in checked for k in ['FAIL','WARN','ERROR']),checked
