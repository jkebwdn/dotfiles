#!/usr/bin/env python3
from pathlib import Path
import subprocess,tempfile,shutil,os,json
root=Path(__file__).resolve().parents[2]
with tempfile.TemporaryDirectory(prefix='magi-phase12h-ui-') as tmp:
 stage=Path(tmp);config=stage/'shell';shutil.copytree(root/'.config/quickshell/magi',config)
 (config/'settings.json').write_text(json.dumps({"schemaVersion":18,"icons":{"pack":os.environ.get("MAGI_PHASE12H_ICON_PACK","magi-default")}}))
 (config/'services/theme_backend.py').write_text('import json,sys,os\nr=json.load(sys.stdin)\nwith open(os.environ["MAGI_PHASE12H_REQUESTS"],"a") as f:f.write(json.dumps(r)+"\\n")\nprint(json.dumps({"ok":True}))\n')
 (config/'test.qml').write_text(Path(__file__).with_name('presentation.qml').read_text().replace('../../.config/quickshell/magi/',''))
 runtime=stage/'runtime';runtime.mkdir(mode=0o700)
 previews=Path(os.environ.get('MAGI_PHASE12H_PREVIEWS',str(stage/'previews')));previews.mkdir(parents=True,exist_ok=True)
 env=dict(os.environ,HOME=str(stage),XDG_CONFIG_HOME=str(stage/'config'),XDG_STATE_HOME=str(stage/'state'),XDG_DATA_HOME=str(stage/'data'),XDG_CACHE_HOME=str(stage/'cache'),XDG_RUNTIME_DIR=str(runtime),QT_QPA_PLATFORM=os.environ.get('MAGI_TEST_QPA','offscreen'),QT_QUICK_BACKEND=os.environ.get('MAGI_TEST_RENDERER','software'),MAGI_PHASE12H_PREVIEWS=str(previews))
 env['MAGI_PHASE12H_REQUESTS']=str(stage/'requests.jsonl')
 env.pop('WAYLAND_DISPLAY',None);env.pop('DISPLAY',None);env.pop('HYPRLAND_INSTANCE_SIGNATURE',None)
 result=subprocess.run(['quickshell','-p',str(config/'test.qml'),'--no-color'],env=env,text=True,capture_output=True,timeout=90)
 output=result.stdout+result.stderr;print("EXIT",result.returncode);print(output)
 known=['Failed to start IPC server','This plugin does not support setting window masks','Unable to find hyprland socket','Could not connect to DBus','Could not find an available backend', '$HYPRLAND_INSTANCE_SIGNATURE is unset. Cannot connect to hyprland.']
 checked='\n'.join(l for l in output.splitlines() if not any(k in l for k in known))
 assert result.returncode==0 and 'Phase12H presentation PASS' in output and not any(k in checked for k in ['FAIL','WARN','ERROR'])

 requests=[json.loads(line) for line in (stage/'requests.jsonl').read_text().splitlines()]
 applies=[r for r in requests if r['op']=='apply']
 assert len(applies)==1 and applies[0]['theme']=='rose-pine-dawn', applies
 print('Phase12H production-component previews:',previews)
