#!/usr/bin/env python3
from pathlib import Path
import os,shutil,subprocess,tempfile
root=Path(__file__).resolve().parents[2]
subprocess.run(['python',str(Path(__file__).with_name('policy.py'))],check=True)
subprocess.run(['node',str(Path(__file__).with_name('schema.cjs')),str(root/'.config/quickshell/magi')],check=True)
with tempfile.TemporaryDirectory(prefix='magi-power-ui-') as tmp:
 stage=Path(tmp);config=stage/'shell';shutil.copytree(root/'.config/quickshell/magi',config)
 (config/'settings.json').write_text('{"schemaVersion":14}')
 (config/'test.qml').write_text(Path(__file__).with_name('presentation.qml').read_text().replace('../../.config/quickshell/magi/',''))
 runtime=stage/'runtime';runtime.mkdir(mode=0o700)
 preview=Path(os.environ.get('MAGI_POWER_PREVIEW',str(stage/'power-idle.png')));preview.parent.mkdir(parents=True,exist_ok=True)
 env=dict(os.environ,HOME=str(stage),XDG_CONFIG_HOME=str(stage/'config'),XDG_STATE_HOME=str(stage/'state'),XDG_DATA_HOME=str(stage/'data'),XDG_CACHE_HOME=str(stage/'cache'),XDG_RUNTIME_DIR=str(runtime),QT_QPA_PLATFORM='offscreen',QT_QUICK_BACKEND='software',MAGI_POWER_PREVIEW=str(preview))
 env.pop('WAYLAND_DISPLAY',None);env.pop('DISPLAY',None)
 result=subprocess.run(['quickshell','-p',str(config/'test.qml'),'--no-color'],env=env,text=True,capture_output=True,timeout=25)
 output=result.stdout+result.stderr;print(output)
 known=['Failed to start IPC server','This plugin does not support setting window masks','Unable to find hyprland socket','Could not connect to DBus','Could not find an available backend']
 checked='\n'.join(l for l in output.splitlines() if not any(k in l for k in known))
 assert result.returncode==0 and 'Power & Idle UI, ordering, unenrolled failure and persistence PASS' in output and not any(k in checked for k in ['FAIL','WARN','ERROR'])
 assert (config/'settings.json').read_text()=='{"schemaVersion":14}'
 # Reuse the actual fleet/window adapters, with the dedicated Caffeine fixture.
 for name in ['.config','tests']:shutil.copytree(root/name,stage/'fleet'/name)
 runner=stage/'fleet/tests/phase10b/run.py'
 runner.write_text(runner.read_text().replace('Phase 10B lifecycle PASS','Phase 10C.1 Caffeine lifecycle PASS'))
 (runner.parent/'lifecycle.qml').write_text(Path(__file__).with_name('caffeine.qml').read_text())
 subprocess.run(['python',str(runner)],check=True)
