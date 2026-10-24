#!/usr/bin/env python3
"""Real QML lifecycle/debounce with a disposable fake worker, never native IPC."""
from pathlib import Path
import json, os, shutil, subprocess, tempfile
root=Path(__file__).resolve().parents[2]
with tempfile.TemporaryDirectory(prefix='magi-window-lifecycle-') as tmp:
 stage=Path(tmp);config=stage/'shell';shutil.copytree(root/'.config/quickshell/magi',config)
 (config/'settings.json').write_text('{"schemaVersion":18}')
 (config/'services/theme_backend.py').write_text('''import json,sys,pathlib,os
p=pathlib.Path(os.environ['XDG_STATE_HOME']);p.mkdir(parents=True,exist_ok=True)
c=p/'calls';n=int(c.read_text())+1 if c.exists() else 1;c.write_text(str(n))
v=json.loads(sys.stdin.readline())['policy'];v['calls']=n
print(json.dumps(dict(status='unavailable' if v['backgroundOpacity']==.51 else 'reload-required' if v['managed'] else 'released',outcome=v,error='')))
''')
 (config/'test.qml').write_text(Path(__file__).with_name('lifecycle.qml').read_text().replace('../../.config/quickshell/magi/',''))
 runtime=stage/'runtime';runtime.mkdir(mode=0o700)
 env=dict(os.environ,HOME=str(stage),XDG_STATE_HOME=str(stage/'state'),XDG_CONFIG_HOME=str(stage/'config'),XDG_RUNTIME_DIR=str(runtime),QT_QPA_PLATFORM='offscreen',QT_QUICK_BACKEND='software')
 for key in ['WAYLAND_DISPLAY','DISPLAY','HYPRLAND_INSTANCE_SIGNATURE']:env.pop(key,None)
 result=subprocess.run(['quickshell','-p',str(config/'test.qml'),'--no-color'],env=env,text=True,capture_output=True,timeout=20)
 print(result.stdout+result.stderr)
 assert result.returncode==0 and 'Phase12G lifecycle PASS' in result.stdout+result.stderr
