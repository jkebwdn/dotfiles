#!/usr/bin/env python3
"""Exercise the real settings store and disk helper in disposable config roots."""
import importlib.util
import json
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import sys
sys.dont_write_bytecode = True

root = Path(__file__).resolve().parents[2]
source = root / '.config/quickshell/magi'
subprocess.run(['node', str(Path(__file__).with_name('schema.cjs')), str(source / 'settings')], check=True)
spec = importlib.util.spec_from_file_location('persist', source / 'settings/persist.py')
module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(module)
with tempfile.TemporaryDirectory(prefix='magi-settings-') as temp:
    stage = Path(temp)
    os.environ['XDG_STATE_HOME'] = str(stage / 'state')
    p = stage / 'io/settings.json'
    assert module.perform({'op':'read','path':str(p)})['text'] is None
    old = '{"palette":"everforest","custom":12}'
    p.parent.mkdir()
    p.write_text(old)
    new = '{"schemaVersion":3,"custom":12}'
    assert module.perform({'op':'write','path':str(p),'expected':old,'text':new})['ok']
    assert p.read_text() == new
    assert next((stage/'state/magi/settings-backups').glob('*.json')).read_text() == old
    assert module.perform({'op':'write','path':str(p),'expected':old,'text':new})['conflict']
    link = stage / 'link.json'
    link.symlink_to(p)
    assert module.perform({'op':'write','path':str(link),'expected':new,'text':'{"schemaVersion":3}'})['ok']
    assert link.is_symlink() and json.loads(p.read_text()) == {'schemaVersion':3}
    assert not list(p.parent.glob('.settings.json-*'))
    print('Atomic I/O: missing read, migration backup, write, conflict, symlink, temp cleanup PASS')
    fixtures = {
        'missing': None,
        'legacy': json.dumps({'palette': 'catppuccin', 'barLeftPlugins': ['date', 'clock'],
                              'barCenterPlugins': [], 'barRightPlugins': ['volume', 'wifi'],
                              'custom': 42}),
        'valid': json.dumps({'schemaVersion':3, 'appearance':{'theme':'everforest-dark-hard'}, 'custom':42}),
        'invalid': '{"schemaVersion":3,"appearance":{"roundness":{"master":-4}}}',
        'partial': '{"schemaVersion":3,"appearance":{"theme":"catppuccin-mocha"}}',
    }
    for name, initial in fixtures.items():
        config = stage/name
        shutil.copytree(source, config)
        configfile = config/'settings.json'
        if initial is None: configfile.unlink()
        else: configfile.write_text(initial)
        harness = Path(__file__).with_name('store.qml').read_text().replace('../../.config/quickshell/magi/', '')
        (config/'test.qml').write_text(harness)
        runtime = config/'runtime'; runtime.mkdir(mode=0o700)
        env = dict(os.environ, QT_QPA_PLATFORM='offscreen', QT_QUICK_BACKEND='software',
                   XDG_RUNTIME_DIR=str(runtime), MAGI_TEST_SETTINGS=str(configfile), MAGI_TEST_LEGACY="1" if name == "legacy" else "0", MAGI_TEST_INVALID="1" if name == "invalid" else "0")
        env.pop('WAYLAND_DISPLAY', None); env.pop('DISPLAY', None)
        result = subprocess.run(['quickshell','-p',str(config/'test.qml'),'--no-color'],env=env,text=True,capture_output=True,timeout=15)
        output=result.stdout+result.stderr
        print(name + ': ' + output)
        checked = '\n'.join(line for line in output.splitlines()
                            if 'ERROR quickshell.ipc: Failed to start IPC server' not in line)
        assert result.returncode == 0 and 'RESULT: 0 failures' in output and 'ERROR' not in checked and 'FAIL:' not in checked
        assert json.loads(configfile.read_text())['schemaVersion']==9
