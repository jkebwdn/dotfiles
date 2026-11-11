#!/usr/bin/env python3
"""Production Settings UI under QtTest; never use operator HOME/config/state."""
from pathlib import Path
import os
import sys
import json
import hashlib
import shutil
import subprocess
import tempfile
root = Path(__file__).resolve().parents[2]
with tempfile.TemporaryDirectory(prefix='magi-controlcentre-workflow-test-') as tmp:
    stage = Path(tmp)
    config = stage/'shell'
    shutil.copytree(root/'.config/quickshell/magi', config)
    # Baseline schema, defaults and migrations must remain byte-identical.
    schema='linux/magi/.config/quickshell/magi/settings/SettingsSchema.js'
    baseline=subprocess.check_output(['git','show','93ef0da1b29908e4908bb9923b26772835d9872b:'+schema],cwd=root)
    assert baseline==(config/'settings/SettingsSchema.js').read_bytes()
    baseline_schema=stage/'baseline.js';baseline_schema.write_bytes(baseline)
    check="const fs=require('fs'),vm=require('vm');function defaults(p){let c=vm.createContext({});vm.runInContext(fs.readFileSync(p,'utf8'),c);return JSON.stringify(c.defaults())} if(defaults(process.argv[1])!==defaults(process.argv[2]))throw Error('Defaults changed'); console.log(defaults(process.argv[2]));"
    seed=subprocess.check_output(['node','-e',check,str(baseline_schema),str(config/'settings/SettingsSchema.js')],text=True)
    migration='linux/magi/.config/quickshell/magi/settings/SettingsMigrations.js'
    assert subprocess.check_output(['git','show','93ef0da1b29908e4908bb9923b26772835d9872b:'+migration],cwd=root)==(config/'settings/SettingsMigrations.js').read_bytes()
    if os.environ.get('MAGI_CC_SETTINGS_SNAPSHOT'):
        seed=Path(os.environ['MAGI_CC_SETTINGS_SNAPSHOT']).read_text()
        for name in ['images','avatars','bar-images']:
            original=Path('/home/jkebwdn/.local/share/magi')/name
            if original.exists():shutil.copytree(original,stage/'data/magi'/name)
    (config/'settings.json').write_text(seed)
    fixtures=[]
    if '--fit' in sys.argv:
        from PyQt6.QtGui import QImage,QColor
        for width,height in [(200,400),(800,180),(160,1000)]:
            image=QImage(width,height,QImage.Format.Format_RGBA8888);image.fill(QColor(0,0,0,0))
            for y in range(10,height-10):
                for x in range(10,width-10):image.setPixelColor(x,y,QColor(210,80,110,190 if x<20 else 255))
            target=stage/'fixture.png';image.save(str(target));name=hashlib.sha256(target.read_bytes()).hexdigest()+'.png'
            folder=stage/'data/magi/images';folder.mkdir(parents=True,exist_ok=True);shutil.copyfile(target,folder/name)
            fixtures.append(dict(id='decoration-image:'+name,width=width,height=height,bounds=[10,10,width-20,height-20]))
    fixture=Path(__file__).with_name('controlcentre-fit.qml') if '--fit' in sys.argv else Path(__file__).with_suffix('.qml')
    (config/'test.qml').write_text(fixture.read_text().replace('../../.config/quickshell/magi/', ''))
    runtime = stage/'runtime'; runtime.mkdir(mode=0o700)
    env = dict(os.environ, HOME=str(stage), XDG_CONFIG_HOME=str(stage/'config'),
               XDG_DATA_HOME=str(stage/'data'), XDG_STATE_HOME=str(stage/'state'),
               XDG_RUNTIME_DIR=str(runtime), QT_QPA_PLATFORM='offscreen', QT_QUICK_BACKEND='software')
    env['MAGI_CC_FIXTURES']=json.dumps(fixtures)
    env.update(DBUS_SESSION_BUS_ADDRESS='unix:path='+str(stage/'no-session-bus'),
               DBUS_SYSTEM_BUS_ADDRESS='unix:path='+str(stage/'no-system-bus'),
               HYPRLAND_INSTANCE_SIGNATURE='magi-offline-no-compositor', MAGI_ACTION_DRY_RUN='1')
    if os.environ.get('MAGI_CC_WORKFLOW_CAPTURES'):
        Path(os.environ['MAGI_CC_WORKFLOW_CAPTURES']).mkdir(parents=True,exist_ok=True)
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
    assert result.returncode == 0 and ('Control Centre fit PASS' if '--fit' in sys.argv else 'Control Centre workflow PASS') in output
    assert not any(k in checked for k in ('FAIL!', 'FAIL:', 'ERROR', 'WARN'))
