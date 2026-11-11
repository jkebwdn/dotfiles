#!/usr/bin/env python3
"""Production Settings UI under QtTest; never use operator HOME/config/state."""
from pathlib import Path
import os
import shutil
import subprocess
import tempfile
root = Path(__file__).resolve().parents[2]
with tempfile.TemporaryDirectory(prefix='magi-settings-refinement-test-') as tmp:
    stage = Path(tmp)
    config = stage/'shell'
    shutil.copytree(root/'.config/quickshell/magi', config)
    # Baseline defaults and migrations must be identical; only the catalogue grows.
    schema='linux/magi/.config/quickshell/magi/settings/SettingsSchema.js'
    baseline=subprocess.check_output(['git','show','5e00c381f76830ba2a75e952e6f723efe2604ea1:'+schema],cwd=root)
    baseline_schema=stage/'baseline.js';baseline_schema.write_bytes(baseline)
    check="const fs=require('fs'),vm=require('vm');function defaults(p){let c=vm.createContext({});vm.runInContext(fs.readFileSync(p,'utf8'),c);return JSON.stringify(c.defaults())} if(defaults(process.argv[1])!==defaults(process.argv[2]))throw Error('Defaults changed'); console.log(defaults(process.argv[2]));"
    seed=subprocess.check_output(['node','-e',check,str(baseline_schema),str(config/'settings/SettingsSchema.js')],text=True)
    migration='linux/magi/.config/quickshell/magi/settings/SettingsMigrations.js'
    assert subprocess.check_output(['git','show','5e00c381f76830ba2a75e952e6f723efe2604ea1:'+migration],cwd=root)==(config/'settings/SettingsMigrations.js').read_bytes()
    (config/'settings.json').write_text(seed)
    (config/'test.qml').write_text(Path(__file__).with_suffix('.qml').read_text().replace('../../.config/quickshell/magi/', ''))
    runtime = stage/'runtime'; runtime.mkdir(mode=0o700)
    env = dict(os.environ, HOME=str(stage), XDG_CONFIG_HOME=str(stage/'config'),
               XDG_DATA_HOME=str(stage/'data'), XDG_STATE_HOME=str(stage/'state'),
               XDG_RUNTIME_DIR=str(runtime), QT_QPA_PLATFORM='offscreen', QT_QUICK_BACKEND='software')
    env.update(DBUS_SESSION_BUS_ADDRESS='unix:path='+str(stage/'no-session-bus'),
               DBUS_SYSTEM_BUS_ADDRESS='unix:path='+str(stage/'no-system-bus'),
               HYPRLAND_INSTANCE_SIGNATURE='magi-offline-no-compositor', MAGI_ACTION_DRY_RUN='1')
    if os.environ.get('MAGI_REFINEMENT_CAPTURES'):
        Path(os.environ['MAGI_REFINEMENT_CAPTURES']).mkdir(parents=True,exist_ok=True)
    env.pop('WAYLAND_DISPLAY', None); env.pop('DISPLAY', None)
    result = subprocess.run(['quickshell','-p',str(config/'test.qml'),'--no-color'], env=env,
                            text=True, capture_output=True, timeout=120)
    output = result.stdout + result.stderr
    print(output)
    known = ('ERROR quickshell.service.pipewire.loop: Failed to connect pipewire context. Errno: 1',
             'WARN quickshell.service.upower: Could not connect to DBus. UPower service will not work.',
             'WARN quickshell.service.mpris.watcher: Could not connect to DBus. Mpris service will not work.',
             'ERROR quickshell.ipc: Failed to start IPC server',
             'ERROR quickshell.network: Network will not work. Could not find an available backend.',
             'WARN: This plugin does not support setting window masks',
             'WARN quickshell.network.networkmanager: Could not connect to DBus. NetworkManager backend will not work.',
             'WARN quickshell.bluetooth: Could not connect to DBus. Bluetooth integration is not available.',
             'WARN: Unable to find hyprland socket. Cannot connect to hyprland.')
    checked = '\n'.join(line for line in output.splitlines() if not any(k in line for k in known))
    assert result.returncode == 0 and 'Settings refinement PASS' in output
    assert not any(k in checked for k in ('FAIL!', 'FAIL:', 'ERROR', 'WARN'))
