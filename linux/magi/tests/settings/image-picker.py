#!/usr/bin/env python3
"""Real Qt file-list interaction, shared imports and persistence in isolated XDG roots."""
from pathlib import Path
import os, shutil, subprocess, tempfile
from PyQt6.QtGui import QImage, QColor
root = Path(__file__).resolve().parents[2]
with tempfile.TemporaryDirectory(prefix='magi-image-picker-') as tmp:
    stage = Path(tmp); config = stage/'config'
    shutil.copytree(root/'.config/quickshell/magi', config)
    (config/'settings.json').write_text('{"schemaVersion":22}')
    frame = QImage(24,24,QImage.Format.Format_RGBA8888); frame.fill(QColor(0,0,0,0)); frame.setPixelColor(3,4,QColor(20,40,60,128)); frame.save(str(config/'alpha.png'))
    shutil.copyfile(root/'tests/bar-image/alpha.gif', config/'alpha.gif')
    (config/'unsupported.txt').write_text('not an image')
    runtime=stage/'runtime'; runtime.mkdir(mode=0o700)
    env=dict(os.environ, HOME=str(stage), XDG_CONFIG_HOME=str(stage/'xdg-config'), XDG_DATA_HOME=str(stage/'data'), XDG_STATE_HOME=str(stage/'state'), XDG_CACHE_HOME=str(stage/'cache'), XDG_RUNTIME_DIR=str(runtime), QT_QPA_PLATFORM='offscreen', QT_QUICK_BACKEND='software')
    env.pop('WAYLAND_DISPLAY',None); env.pop('DISPLAY',None)
    env.pop('MAGI_SETTINGS_CARD_CAPTURES',None)
    for fixture,marker in [('image-picker.qml','Settings image picker PASS')]:
        (config/'test.qml').write_text(Path(__file__).with_name(fixture).read_text().replace('../../.config/quickshell/magi/',''))
        result=subprocess.run(['quickshell','-p',str(config/'test.qml'),'--no-color'],env=env,text=True,capture_output=True,timeout=60)
        out=result.stdout+result.stderr;print(out,flush=True)
        known=('ERROR quickshell.ipc: Failed to start IPC server','WARN: This plugin does not support setting window masks','WARN: Unable to find hyprland socket. Cannot connect to hyprland.', 'WARN quickshell.network.networkmanager: Could not connect to DBus. NetworkManager backend will not work.', 'ERROR quickshell.network: Network will not work. Could not find an available backend.', 'WARN quickshell.bluetooth: Could not connect to DBus. Bluetooth integration is not available.')
        checked='\n'.join(line for line in out.splitlines() if not any(k in line for k in known))
        assert result.returncode==0 and marker in out and not any(k in checked for k in ('FAIL!','FAIL:','ERROR','WARN'))
    import hashlib,json
    for file in ['alpha.png','alpha.gif']:
        original=(config/file).read_bytes();sha=hashlib.sha256(original).hexdigest()
        assert (stage/'data/magi/images'/f'{sha}{Path(file).suffix}').read_bytes()==original
    saved=json.loads((config/'settings.json').read_text())
    assert saved['controlCentre']['decoration']['asset']['id'].endswith('.gif')
    print('Picker byte identity, alpha metadata and persisted GIF PASS')
