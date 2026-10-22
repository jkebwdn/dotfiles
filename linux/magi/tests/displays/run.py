#!/usr/bin/env python3
from pathlib import Path
import subprocess,tempfile,shutil,os
root=Path(__file__).resolve().parents[2]
subprocess.run(['python',str(Path(__file__).with_name('model.py'))],check=True)
with tempfile.TemporaryDirectory(prefix='magi-displays-ui-') as tmp:
 stage=Path(tmp);config=stage/'shell';shutil.copytree(root/'.config/quickshell/magi',config)
 (config/'settings.json').write_text('{"schemaVersion":15}')
 (config/'test.qml').write_text(Path(__file__).with_name('presentation.qml').read_text().replace('../../.config/quickshell/magi/',''))
 runtime=stage/'runtime';runtime.mkdir(mode=0o700)
 previews=Path(os.environ.get('MAGI_DISPLAY_PREVIEWS',str(stage/'previews')));previews.mkdir(parents=True,exist_ok=True)
 env=dict(os.environ,HOME=str(stage),XDG_CONFIG_HOME=str(stage/'config'),XDG_STATE_HOME=str(stage/'state'),XDG_DATA_HOME=str(stage/'data'),XDG_CACHE_HOME=str(stage/'cache'),XDG_RUNTIME_DIR=str(runtime),QT_QPA_PLATFORM='offscreen',QT_QUICK_BACKEND='software',MAGI_DISPLAY_PREVIEWS=str(previews))
 env.pop('WAYLAND_DISPLAY',None);env.pop('DISPLAY',None);env.pop('HYPRLAND_INSTANCE_SIGNATURE',None)
 result=subprocess.run(['quickshell','-p',str(config/'test.qml'),'--no-color'],env=env,text=True,capture_output=True,timeout=35)
 output=result.stdout+result.stderr;print(output)
 known=['Failed to start IPC server','This plugin does not support setting window masks','Unable to find hyprland socket','Could not connect to DBus','Could not find an available backend']
 checked='\n'.join(l for l in output.splitlines() if not any(k in l for k in known))
 assert result.returncode==0 and 'Display UI drag, selection, profiles, confirmation and degraded state PASS' in output and not any(k in checked for k in ['FAIL','WARN','ERROR'])
 assert (config/'settings.json').read_text()=='{"schemaVersion":15}'
 assert all((previews/(name+'.png')).stat().st_size>1000 for name in ['laptop','dual','external','profiles','confirmation','missing'])
 print('Six production-component previews:',previews)

 # Reuse Phase 10B's isolated window/service adapters, never the desktop.
with tempfile.TemporaryDirectory(prefix='magi-display-bars-') as tmp:
 stage=Path(tmp)
 for name in ['.config','tests']:shutil.copytree(root/name,stage/name)
 runner=stage/'tests/phase10b/run.py'
 runner.write_text(runner.read_text().replace('Phase 10B lifecycle PASS','Display model to Phase 10B lifecycle PASS'))
 (runner.parent/'lifecycle.qml').write_text(Path(__file__).with_name('bar-interaction.qml').read_text())
 subprocess.run(['python',str(runner)],check=True)
