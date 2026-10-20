#!/usr/bin/env python3
"""Production presenters in disposable HOME/XDG roots; optional offscreen captures."""
from pathlib import Path
import os, shutil, subprocess, tempfile
root = Path(__file__).resolve().parents[2]
with tempfile.TemporaryDirectory(prefix='magi-10a-') as tmp:
    stage=Path(tmp); config=stage/'shell'
    shutil.copytree(root/'.config/quickshell/magi',config)
    (config/'settings.json').write_text('{"schemaVersion":12}')
    (config/'test.qml').write_text(Path(__file__).with_name('refinement.qml').read_text().replace('../../.config/quickshell/magi/',''))
    runtime=stage/'runtime';runtime.mkdir(mode=0o700)
    env=dict(os.environ,HOME=str(stage),XDG_CONFIG_HOME=str(stage/'config'),XDG_DATA_HOME=str(stage/'data'),XDG_CACHE_HOME=str(stage/'cache'),XDG_STATE_HOME=str(stage/'state'),XDG_RUNTIME_DIR=str(runtime),QT_QPA_PLATFORM='offscreen',QT_QUICK_BACKEND=os.environ.get('MAGI_TEST_RENDERER','software'))
    env.pop('DISPLAY',None);env.pop('WAYLAND_DISPLAY',None)
    if env.get('MAGI_10A_CAPTURES'): Path(env['MAGI_10A_CAPTURES']).mkdir(parents=True,exist_ok=True)
    result=subprocess.run(['quickshell','-p',str(config/'test.qml'),'--no-color'],env=env,text=True,capture_output=True,timeout=30)
    output=result.stdout+result.stderr;print(output)
    expected=['Failed to start IPC server','This plugin does not support setting window masks','Unable to find hyprland socket','Could not connect to DBus.','Network will not work. Could not find an available backend.']
    checked='\n'.join(line for line in output.splitlines() if not any(s in line for s in expected))
    assert result.returncode==0 and 'lifecycle PASS' in output and not any(s in checked for s in ['ERROR','WARN','FAIL'])
