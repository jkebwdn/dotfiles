#!/usr/bin/env python3
"""Production Settings drag and keyboard ordering under QtTest; never use operator HOME/config/state."""
from pathlib import Path
import os
import shutil
import subprocess
import tempfile
root = Path(__file__).resolve().parents[2]
with tempfile.TemporaryDirectory(prefix='magi-settings-reorder-') as tmp:
    stage = Path(tmp)
    config = stage/'shell'
    shutil.copytree(root/'.config/quickshell/magi', config)
    (config/'settings.json').write_text('{"schemaVersion":10}')
    (config/'test.qml').write_text(Path(__file__).with_suffix('.qml').read_text().replace('../../.config/quickshell/magi/', ''))
    runtime = stage/'runtime'; runtime.mkdir(mode=0o700)
    env = dict(os.environ, HOME=str(stage), XDG_CONFIG_HOME=str(stage/'config'),
               XDG_DATA_HOME=str(stage/'data'), XDG_STATE_HOME=str(stage/'state'),
               XDG_RUNTIME_DIR=str(runtime), QT_QPA_PLATFORM='offscreen', QT_QUICK_BACKEND='software')
    env.pop('WAYLAND_DISPLAY', None); env.pop('DISPLAY', None)
    result = subprocess.run(['quickshell','-p',str(config/'test.qml'),'--no-color'], env=env,
                            text=True, capture_output=True, timeout=90)
    output = result.stdout + result.stderr
    print(output)
    known = ('ERROR quickshell.ipc: Failed to start IPC server',
             'ERROR quickshell.network: Network will not work. Could not find an available backend.',
             'WARN: This plugin does not support setting window masks',
             'WARN quickshell.network.networkmanager: Could not connect to DBus. NetworkManager backend will not work.',
             'WARN quickshell.bluetooth: Could not connect to DBus. Bluetooth integration is not available.',
             'WARN: Unable to find hyprland socket. Cannot connect to hyprland.')
    checked = '\n'.join(line for line in output.splitlines() if not any(k in line for k in known))
    assert result.returncode == 0 and 'RESULT: 0 failures' in output
    assert not any(k in checked for k in ('FAIL!', 'FAIL:', 'ERROR', 'WARN'))
