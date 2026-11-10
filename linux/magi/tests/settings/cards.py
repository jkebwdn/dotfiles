#!/usr/bin/env python3
"""Production Settings UI under QtTest; never use operator HOME/config/state."""
from pathlib import Path
import os
import shutil
import subprocess
import tempfile
import sys
root = Path(__file__).resolve().parents[2]
with tempfile.TemporaryDirectory(prefix='magi-settings-cards-') as tmp:
    stage = Path(tmp)
    config = stage/'shell'
    shutil.copytree(root/'.config/quickshell/magi', config)
    (config/'settings.json').write_text('{"schemaVersion":10}')
    (config/'test.qml').write_text(Path(__file__).with_name('cards.qml').read_text().replace('../../.config/quickshell/magi/', ''))
    runtime = stage/'runtime'; runtime.mkdir(mode=0o700)
    env = dict(os.environ, HOME=str(stage), XDG_CONFIG_HOME=str(stage/'config'),
               XDG_DATA_HOME=str(stage/'data'), XDG_STATE_HOME=str(stage/'state'),
               XDG_RUNTIME_DIR=str(runtime), QT_QPA_PLATFORM='offscreen', QT_QUICK_BACKEND='software')
    env.pop('WAYLAND_DISPLAY', None); env.pop('DISPLAY', None)
    env.pop('MAGI_SETTINGS_CARD_CAPTURES', None)
    if len(sys.argv) > 1:
        captures = Path(sys.argv[1]); captures.mkdir(parents=True, exist_ok=True)
        env['MAGI_SETTINGS_CARD_CAPTURES'] = str(captures)
    result = subprocess.run(['quickshell','-p',str(config/'test.qml'),'--no-color'], env=env,
                            text=True, capture_output=True, timeout=60)
    output = result.stdout + result.stderr
    print(output)
    known = ('ERROR quickshell.ipc: Failed to start IPC server',
             'ERROR quickshell.network: Network will not work. Could not find an available backend.',
             'WARN: This plugin does not support setting window masks',
             'WARN quickshell.network.networkmanager: Could not connect to DBus. NetworkManager backend will not work.',
             'WARN quickshell.bluetooth: Could not connect to DBus. Bluetooth integration is not available.',
             'WARN: Unable to find hyprland socket. Cannot connect to hyprland.')
    checked = '\n'.join(line for line in output.splitlines() if not any(k in line for k in known))
    assert result.returncode == 0 and 'Settings cards PASS' in output
    assert not any(k in checked for k in ('FAIL!', 'FAIL:', 'ERROR', 'WARN'))

    if len(sys.argv)>1:
        for theme in ['one-light','nord']:
            for width in [720,1000,1400]:
                for page in ['Appearance','Bar','Control-Centre','Lock-Screen','Power-&-Idle']:
                    assert (captures/f'{theme}-{width}-{page}.png').stat().st_size>1000
