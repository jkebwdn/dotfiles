#!/usr/bin/env python3
"""Synthetic components only: never imports/references the SystemTray singleton."""
from pathlib import Path
import os, shutil, subprocess, tempfile
root=Path(__file__).resolve().parents[2]
pragmas='\n'.join(line for line in (root/'.config/quickshell/magi/shell.qml').read_text().splitlines() if line.startswith('//@ pragma '))+'\n'
assert '//@ pragma UseQApplication\n' in pragmas
subprocess.run(['node','tests/phase14a/model.cjs',*([os.environ['MAGI_TRAY_OPERATOR_FIXTURE']] if os.environ.get('MAGI_TRAY_OPERATOR_FIXTURE') else [])],cwd=root,check=True)
with tempfile.TemporaryDirectory(prefix='magi-tray-') as tmp:
 stage=Path(tmp);config=stage/'shell';shutil.copytree(root/'.config/quickshell/magi',config)
 (config/'settings.json').write_text('{"schemaVersion":21}')
 # Fail closed: any accidental production-service access gets an empty model,
 # never registers a host on the operator bus.
 (config/'services/TrayService.qml').write_text('pragma Singleton\nimport QtQuick\nTrayModel {}\n')
 (config/'test.qml').write_text(pragmas+Path(__file__).with_name('presentation.qml').read_text().replace('../../.config/quickshell/magi/',''))
 import struct,zlib
 def chunk(kind,data):return struct.pack('!I',len(data))+kind+data+struct.pack('!I',zlib.crc32(kind+data))
 (config/'tray-pixel.png').write_bytes(b'\x89PNG\r\n\x1a\n'+chunk(b'IHDR',struct.pack('!2I5B',1,1,8,6,0,0,0))+chunk(b'IDAT',zlib.compress(b'\x00\x38\x8a\x73\xff'))+chunk(b'IEND',b''))
 runtime=stage/'runtime';runtime.mkdir(mode=0o700)
 previews=Path(os.environ.get('MAGI_PHASE14A_PREVIEWS',str(stage/'previews')));previews.mkdir(parents=True,exist_ok=True)
 env=dict(os.environ,HOME=str(stage),XDG_CONFIG_HOME=str(stage/'config'),XDG_STATE_HOME=str(stage/'state'),XDG_DATA_HOME=str(stage/'data'),XDG_CACHE_HOME=str(stage/'cache'),XDG_RUNTIME_DIR=str(runtime),QT_QPA_PLATFORM='offscreen',QT_QUICK_BACKEND='software',MAGI_PHASE14A_PREVIEWS=str(previews))
 for key in ['DISPLAY','WAYLAND_DISPLAY','HYPRLAND_INSTANCE_SIGNATURE','DBUS_SESSION_BUS_ADDRESS']:env.pop(key,None)
 result=subprocess.run(['quickshell','-p',str(config/'test.qml'),'--no-color'],env=env,text=True,capture_output=True,timeout=60)
 output=result.stdout+result.stderr;print(output)
 known=['Failed to start IPC server','This plugin does not support setting window masks']
 checked='\n'.join(line for line in output.splitlines() if not any(k in line for k in known))
 assert result.returncode==0 and 'Phase14A presentation PASS' in output and not any(k in checked for k in ['FAIL','WARN','ERROR'])
 for name in ['empty','three-items','attention','overflow','top','bottom','compact','dawn','secondary-output','main-output']:assert (previews/(name+'.png')).stat().st_size>1000,name
 (config/'settings.json').write_text('{"schemaVersion":21}')
 (config/'test.qml').write_text(pragmas+Path(__file__).with_name('designer.qml').read_text().replace('../../.config/quickshell/magi/',''))
 result=subprocess.run(['quickshell','-p',str(config/'test.qml'),'--no-color'],env=env,text=True,capture_output=True,timeout=60)
 output=result.stdout+result.stderr;print(output)
 checked='\n'.join(line for line in output.splitlines() if not any(k in line for k in known))
 assert result.returncode==0 and 'Phase14A designer PASS' in output and not any(k in checked for k in ['FAIL','WARN','ERROR'])
 # Quickshell's own reload toast needs a layer-shell backend, absent offscreen.
 known += ['WARN: QQmlComponent: Component is not ready', 'ERROR: Failed to open reload popup:']
 env['MAGI_TRAY_RELOAD_MARKER']=str(stage/'reload-marker')
 (config/'test.qml').write_text(pragmas+Path(__file__).with_name('reload.qml').read_text().replace('../../.config/quickshell/magi/',''))
 result=subprocess.run(['quickshell','-p',str(config/'test.qml'),'--no-color'],env=env,text=True,capture_output=True,timeout=15)
 output=result.stdout+result.stderr;print(output)
 checked='\n'.join(line for line in output.splitlines() if not any(k in line for k in known))
 assert result.returncode==0 and 'Phase14A synthetic hard reload PASS' in output and not any(k in checked for k in ['FAIL','WARN','ERROR'])
 # Native menu API startup-mode regression, without any D-Bus app/host.
 probe='import QtQuick\nimport Quickshell\nShellRoot { FloatingWindow { id: win; visible: true; implicitWidth: 80; implicitHeight: 80 } QsMenuAnchor { id: menu; anchor.window: win } Timer { interval: 100; running: true; onTriggered: { menu.open(); Qt.quit() } } }'
 for enabled in [False,True]:
  (config/'mode.qml').write_text((pragmas if enabled else '')+probe)
  result=subprocess.run(['quickshell','-p',str(config/'mode.qml'),'--no-color'],env=env,text=True,capture_output=True,timeout=10)
  output=result.stdout+result.stderr
  assert result.returncode==0,output
  blocked='not started in QApplication mode' in output
  assert blocked != enabled,output
  if enabled:print(output)
 print('Native menu QApplication prerequisite: old mode rejected; production pragma accepted PASS')
 print('Synthetic tray gallery:',previews)
