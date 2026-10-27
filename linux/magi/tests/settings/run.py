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
    # Exercise production persistence with the canonical JS defaults, not live settings.
    defaults = json.loads(subprocess.check_output([
        'node', '-e', "const fs=require('fs'),vm=require('vm');const c=vm.createContext({});"
        "vm.runInContext(fs.readFileSync(process.argv[1],'utf8'),c);"
        "console.log(JSON.stringify(vm.runInContext('defaults()',c)));",
        str(source/'settings/SettingsSchema.js')], text=True))
    current = defaults['schemaVersion']
    for label, original, expected_count in [
        ('current', json.dumps(defaults), 0),
        ('previous', json.dumps(dict(defaults, schemaVersion=current-1)), 1),
        ('historical', '{"schemaVersion":3,"custom":12}', 1),
        ('legacy', '{"palette":"everforest","custom":12}', 1),
        ('malformed', '{broken json', 1),
    ]:
        case = stage/('backup-'+label)
        case.mkdir()
        os.environ['XDG_STATE_HOME'] = str(case/'state')
        path = case/'settings.json'
        path.write_text(original)
        for edit in range(3):
            before = path.read_text()
            updated = json.dumps(dict(defaults, custom=edit))
            assert module.perform({'op':'write','path':str(path),
                                   'expected':before,'text':updated})['ok']
            backups = list((case/'state/magi/settings-backups').glob('*.json'))
            assert len(backups) == expected_count, (label, edit, backups)
            if backups:
                assert backups[0].read_bytes() == original.encode(), label
        # Unchanged current-schema save also must not add a backup.
        before = path.read_text()
        assert module.perform({'op':'write','path':str(path),
                               'expected':before,'text':before})['ok']
        assert len(list((case/'state/magi/settings-backups').glob('*.json'))) == expected_count
    # A failed replacement leaves original settings and their migration backup intact;
    # retrying the same migration reuses the content-addressed backup.
    from unittest.mock import patch
    case = stage/'failed'; case.mkdir()
    os.environ['XDG_STATE_HOME'] = str(case/'state')
    path = case/'settings.json'
    original = json.dumps(dict(defaults, schemaVersion=current-1))
    path.write_text(original)
    request = {'op':'write','path':str(path),'expected':original,'text':json.dumps(defaults)}
    with patch.object(module.os, 'replace', side_effect=OSError('synthetic replacement failure')):
        try:
            module.perform(request)
            raise AssertionError('Expected replacement failure')
        except OSError:
            pass
    assert path.read_text() == original
    assert module.perform(request)['ok']
    backups = list((case/'state/magi/settings-backups').glob('*.json'))
    assert len(backups) == 1 and backups[0].read_text() == original
    assert not list(case.glob('.settings.json-*'))
    print('Migration backup: current/no-op, previous, historical, legacy, recovery, repeated saves and failed-write retry PASS')
    os.environ['XDG_STATE_HOME'] = str(stage/'state')
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
    # Live Settings is deliberately absent from source. Saving into a checkout
    # with the exact ignore contract must not add working-tree noise.
    subprocess.run(['git','init','-q',str(p.parent)],check=True)
    (p.parent/'.gitignore').write_text('/settings.json\n')
    before_status=subprocess.check_output(['git','status','--short'],cwd=p.parent)
    old=p.read_text();new=json.dumps(dict(defaults, custom=42))
    assert module.perform({'op':'write','path':str(p),'expected':old,'text':new})['ok']
    assert p.read_text()==new
    assert subprocess.check_output(['git','status','--short'],cwd=p.parent)==before_status
    subprocess.run(['git','check-ignore','-q','settings.json'],cwd=p.parent,check=True)
    print('Ignored local Settings save leaves Git status unchanged PASS')
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
        if initial is None: configfile.unlink(missing_ok=True)
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
        assert json.loads(configfile.read_text())['schemaVersion']==22
