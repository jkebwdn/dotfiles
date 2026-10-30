#!/usr/bin/env python3
from pathlib import Path
import subprocess,tempfile,shutil,os
root=Path(__file__).resolve().parents[2]
with tempfile.TemporaryDirectory(prefix='magi-fingerprint-ui-') as tmp:
 stage=Path(tmp);config=stage/'shell';shutil.copytree(root/'.config/quickshell/magi',config)
 # Exercise real production controls against a disposable metadata-only helper.
 (config/'services/fingerprint.py').write_text("""import json,sys
from pathlib import Path
root=Path(__file__).parent
state=root/'mock-fingers.json'
fingers=json.loads(state.read_text()) if state.exists() else ['right-index-finger']
action=sys.argv[1]
with (root/'mock-actions.jsonl').open('a') as out: out.write(json.dumps(sys.argv[1:])+'\\n')
if action=='enroll': fingers.append(sys.argv[-1])
if action=='remove': fingers.remove(sys.argv[-1])
state.write_text(json.dumps(fingers))
print(json.dumps({'state':'available','fingers':fingers,'message':'Fingerprint matched' if action=='verify' else 'Ready'}),flush=True)
""")
 (config/'settings.json').write_text('{"schemaVersion":15}')
 (config/'test.qml').write_text(Path(__file__).with_name('presentation.qml').read_text().replace('../../.config/quickshell/magi/',''))
 runtime=stage/'runtime';runtime.mkdir(mode=0o700)
 previews=Path(os.environ.get('MAGI_FINGERPRINT_PREVIEWS',str(stage/'previews')));previews.mkdir(parents=True,exist_ok=True)
 env=dict(os.environ,HOME=str(stage),XDG_CONFIG_HOME=str(stage/'config'),XDG_STATE_HOME=str(stage/'state'),XDG_DATA_HOME=str(stage/'data'),XDG_CACHE_HOME=str(stage/'cache'),XDG_RUNTIME_DIR=str(runtime),QT_QPA_PLATFORM='offscreen',QT_QUICK_BACKEND='software',MAGI_FINGERPRINT_PREVIEWS=str(previews))
 env.pop('WAYLAND_DISPLAY',None);env.pop('DISPLAY',None);env.pop('HYPRLAND_INSTANCE_SIGNATURE',None)
 result=subprocess.run(['quickshell','-p',str(config/'test.qml'),'--no-color'],env=env,text=True,capture_output=True,timeout=35)
 output=result.stdout+result.stderr;print(output)
 known=['Failed to start IPC server','This plugin does not support setting window masks','Unable to find hyprland socket','Could not connect to DBus','Could not find an available backend']
 checked='\n'.join(l for l in output.splitlines() if not any(k in l for k in known))
 assert result.returncode==0 and 'Fingerprint Settings PASS' in output and not any(k in checked for k in ['FAIL','WARN','ERROR'])
 assert [__import__('json').loads(line)[0] for line in (config/'services/mock-actions.jsonl').read_text().splitlines()] == ['status','enroll','remove','verify']
 assert (config/'settings.json').read_text()=='{"schemaVersion":15}'
 assert all((previews/(name+'.png')).stat().st_size>1000 for name in ['host-unknown','existing-enrollment','no-enrollment','enrollment','unavailable'])
 print('Five production-component previews:',previews)
