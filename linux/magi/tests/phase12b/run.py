#!/usr/bin/env python3
"""Production components with isolated Settings and inert CC preview."""
from pathlib import Path
import os,shutil,subprocess,tempfile,sys
root=Path(__file__).resolve().parents[2]
fixture=sys.argv[1] if len(sys.argv)>1 else 'presentation.qml'
assert fixture in ('presentation.qml','switching.qml')
previews=Path(os.environ.get('MAGI_PHASE12B_PREVIEWS','/tmp/magi12b/previews'));previews.mkdir(parents=True,exist_ok=True)
with tempfile.TemporaryDirectory(prefix='magi12b-qml-') as tmp:
 stage=Path(tmp);config=stage/'shell';shutil.copytree(root/'.config/quickshell/magi',config)
 shutil.copytree(root/'native/lock/qml',config/'lock')
 ghost=stage/'config/ghostty/config.ghostty';ghost.parent.mkdir(parents=True);ghost.write_text('font-size = 11\n')
 (config/'settings.json').write_text('{"schemaVersion":16}')
 (config/'test.qml').write_text(Path(__file__).with_name(fixture).read_text().replace('../../.config/quickshell/magi/','').replace('../../native/lock/qml','lock'))
 runtime=stage/'runtime';runtime.mkdir(mode=0o700)
 env=dict(os.environ,HOME=str(stage),XDG_CONFIG_HOME=str(stage/'config'),XDG_DATA_HOME=str(stage/'data'),XDG_STATE_HOME=str(stage/'state'),XDG_CACHE_HOME=str(stage/'cache'),XDG_RUNTIME_DIR=str(runtime),QT_QPA_PLATFORM='offscreen',QT_QUICK_BACKEND='software',MAGI_PHASE12B_PREVIEWS=str(previews))
 for key in ['WAYLAND_DISPLAY','DISPLAY','HYPRLAND_INSTANCE_SIGNATURE']:env.pop(key,None)
 result=subprocess.run(['quickshell','-p',str(config/'test.qml'),'--no-color'],env=env,capture_output=True,text=True,timeout=120)
 output=result.stdout+result.stderr;print(output)
 known=['Failed to start IPC server','This plugin does not support setting window masks','Unable to find hyprland socket','HYPRLAND_INSTANCE_SIGNATURE is unset','Could not connect to DBus','Could not find an available backend']
 checked='\n'.join(l for l in output.splitlines() if not any(k in l for k in known))
 assert result.returncode==0 and ('Phase12B switching PASS' if fixture=='switching.qml' else 'Phase12B presentation PASS') in output and not any(k in checked for k in ['FAIL','WARN','ERROR'])

if fixture=="presentation.qml":
 assert len(list(previews.glob("*.png"))) == 8
