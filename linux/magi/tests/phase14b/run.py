#!/usr/bin/env python3
from pathlib import Path
import os,shutil,subprocess,tempfile,json
root=Path(__file__).resolve().parents[2]
fixture=os.environ.get('MAGI_PHASE14B_OPERATOR_FIXTURE')
with tempfile.TemporaryDirectory(prefix='magi-phase14b-') as tmp:
 stage=Path(tmp);config=stage/'shell';shutil.copytree(root/'.config/quickshell/magi',config)
 if not fixture:
  fixture=str(stage/'operator.json');Path(fixture).write_text(json.dumps({'schemaVersion':21,'bar':{'left':['clock'],'center':['workspaces'],'right':['volume','tray','controlcentre']},'custom':{'preserved':True}}))
 subprocess.run(['node',str(Path(__file__).with_name('schema.cjs')),fixture],check=True)
 (config/'settings.json').write_text('{"schemaVersion":22}')
 (config/'services/TrayService.qml').write_text('pragma Singleton\nimport QtQuick\nTrayModel {}\n')
 (config/'services/Audio.qml').write_text('pragma Singleton\nimport QtQuick\nAudioModel { property int muteCalls:0; property int wheelCalls:0; function toggleMute(){muteCalls++} function adjustVolume(s){wheelCalls++} }\n')
 # Replace native menu transport only. Production focus/press/hover lifecycle runs.
 p=config/'components/tray/TrayItem.qml';s=p.read_text();a=s.index('    QsMenuAnchor {');s=s[:a]+'''    QtObject { id: menuAnchor; property bool visible: false; function open(){visible=true} function close(){visible=false} }
}
''';p.write_text(s)
 (config/'test.qml').write_text(Path(__file__).with_name('presentation.qml').read_text().replace('../../.config/quickshell/magi/',''))
 runtime=stage/'runtime';runtime.mkdir(mode=0o700)
 previews=Path(os.environ.get('MAGI_PHASE14B_PREVIEWS',str(stage/'previews')));previews.mkdir(parents=True,exist_ok=True)
 env=dict(os.environ,HOME=str(stage),XDG_CONFIG_HOME=str(stage/'config'),XDG_STATE_HOME=str(stage/'state'),XDG_DATA_HOME=str(stage/'data'),XDG_CACHE_HOME=str(stage/'cache'),XDG_RUNTIME_DIR=str(runtime),QT_QPA_PLATFORM='offscreen',QT_QUICK_BACKEND='software',MAGI_PHASE14B_PREVIEWS=str(previews))
 for key in ['DISPLAY','WAYLAND_DISPLAY','HYPRLAND_INSTANCE_SIGNATURE','DBUS_SESSION_BUS_ADDRESS']:env.pop(key,None)
 result=subprocess.run(['quickshell','-p',str(config/'test.qml'),'--no-color'],env=env,text=True,capture_output=True,timeout=45)
 output=result.stdout+result.stderr;print(output)
 known=['Failed to start IPC server','This plugin does not support setting window masks','Unable to find hyprland socket']
 checked='\n'.join(line for line in output.splitlines() if not any(k in line for k in known))
 assert result.returncode==0 and 'Phase14B audio actions, identities, lifecycle and tray interaction/preview PASS' in output and not any(k in checked for k in ['FAIL','WARN','ERROR']),checked
 print('Synthetic gallery:',previews)
