#!/usr/bin/env python3
from pathlib import Path
import json, os, re, shutil, subprocess, tempfile
root=Path(__file__).resolve().parents[2]
source=root/'.config/quickshell/magi'
registry=json.loads((source/'theme/palettes/registry.json').read_text())
assert len(registry['themes'])==10
assert len(set(t['id'] for t in registry['themes']))==10
roles=set(registry['themes'][0]['roles'])
def light(c):
    x=[int(c[i:i+2],16)/255 for i in (1,3,5)]
    return sum(a*b for a,b in zip([v/12.92 if v<=.04045 else ((v+.055)/1.055)**2.4 for v in x],[.2126,.7152,.0722]))
def contrast(a,b):
    a,b=sorted([light(a),light(b)]);return (b+.05)/(a+.05)
for t in registry['themes']:
    assert set(t['roles'])==roles
    assert all(re.fullmatch('#[0-9a-fA-F]{6}',c) for c in t['roles'].values())
    assert contrast(t['roles']['text'],t['roles']['background'])>=4.5
    for color in ['accent','blue','lavender','green','yellow','peach','red','teal']:
        assert contrast(t['roles'][color],t['roles']['on'+color.title()])>=4.5
print('Palette data: 10 complete definitions; primary text and colored-control ink contrast PASS')
with tempfile.TemporaryDirectory(prefix='magi-theme-') as tmp:
    stage=Path(tmp);config=stage/'config';shutil.copytree(source,config)
    (config/'settings.json').write_text('{"schemaVersion":1}')
    (config/'test.qml').write_text(Path(__file__).with_name('appearance.qml').read_text().replace('../../.config/quickshell/magi/',''))
    runtime=stage/'runtime';runtime.mkdir(mode=0o700)
    env=dict(os.environ,QT_QPA_PLATFORM='offscreen',QT_QUICK_BACKEND='software',XDG_RUNTIME_DIR=str(runtime),XDG_STATE_HOME=str(stage/'state'))
    env.pop('WAYLAND_DISPLAY',None);env.pop('DISPLAY',None)
    p=subprocess.run(['quickshell','-p',str(config/'test.qml'),'--no-color'],env=env,text=True,capture_output=True,timeout=20)
    out=p.stdout+p.stderr;print(out)
    assert p.returncode==0 and 'RESULT: 0 failures' in out and 'ERROR' not in out and 'WARN' not in out
