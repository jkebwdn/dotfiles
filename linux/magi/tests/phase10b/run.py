#!/usr/bin/env python3
"""Production Variants, bars, surfaces and Settings in a disposable offscreen shell.
Only native window wrappers and external service adapters are substituted.
"""
import ast, os, shutil, subprocess, tempfile
from pathlib import Path
root=Path(__file__).resolve().parents[2]; source=root/'.config/quickshell/magi'
subprocess.run(['node',str(Path(__file__).with_name('policy.cjs')),str(source)],check=True)
tree=ast.parse((root/'tests/settings/modules.py').read_text())
stubs=next(ast.literal_eval(n.value) for n in ast.walk(tree) if isinstance(n,ast.Assign) and any(isinstance(t,ast.Name) and t.id=='stubs' for t in n.targets))
with tempfile.TemporaryDirectory(prefix='magi-10b-') as temporary:
 stage=Path(temporary);config=stage/'shell';shutil.copytree(source,config)
 (config/'settings.json').write_text('{"schemaVersion":13}')
 stubs['Battery']+='\nproperty string statusText: "Unavailable"'
 # Use the production scanning lease logic with harmless mock networks.
 network=source/'services/Network.qml';text=network.read_text();a=text.index('    property var scanOwners:');b=text.index('    // Connection controls',a)
 stubs['Network']=stubs['Network'].replace('function setScanning(v) {root.scanning=v}',text[a:b])
 for name,body in stubs.items():
  (config/f'services/{name}.qml').write_text('pragma Singleton\nimport QtQuick\nQtObject { id: root\n'+body+'\n}')
 # Fake outputs cannot be assigned to the native QScreen wrapper; leave the
 # native screen offscreen, injecting identities through Bar.outputScreen.
 p=config/'components/bar/Bar.qml';s=p.read_text().replace('PanelWindow {','FloatingWindow {',1)
 a=s.index('    exclusiveZone:');b=s.index('    implicitHeight:',a)
 s=s.replace('    Component.onCompleted: {', '    Item { id: captureRoot; objectName: "captureRoot"; anchors.fill: parent }\n    Component.onCompleted: {\n        for (const child of Array.from(contentItem.children)) if (child !== captureRoot) child.parent = captureRoot',1)
 a=s.index('    exclusiveZone:');b=s.index('    implicitHeight:',a)
 s=s[:a]+'''    property int exclusiveZone: fullSurface ? geometry.reservation : 0
    property bool topReserved: !bottomBar
'''+s[b:];p.write_text(s)
 p=config/'components/bar/BarFleet.qml';s=p.read_text().replace('screen: modelData','outputScreen: modelData\n            implicitWidth: modelData.width\n            implicitHeight: modelData.height');s=s.replace('Hyprland.refreshWorkspaces()', '').replace('    IdleInhibitor { enabled: Services.Caffeine.requested && !!root.mainBar; window: root.mainBar }','');p.write_text(s)
 # monitorFor expects real QScreenInfo. Keep workspace production content and
 # inject a name-matched monitor in the fixture instead of compositor IPC.
 p=config/'plugins/bar/workspaces/Workspaces.qml';s=p.read_text().replace('outputScreen ? Hyprland.monitorFor(outputScreen) : null','outputScreen ? outputScreen.monitor : null');s=s.replace('Hyprland.workspaces.values', '[{id:1,name:"1"},{id:2,name:"2"}]').replace('id: root', 'id: root; objectName: "workspaceStrip"; property string dispatched: ""; function dispatchCapture(value) { dispatched = value }',1).replace('Hyprland.dispatch(', 'root.dispatchCapture(');p.write_text(s)
 p=config/'components/hub/HubWindow.qml';s=p.read_text().replace('PanelWindow {','FloatingWindow {\n    implicitWidth: 1920; implicitHeight: 1080',1).replace('screen: Services.SurfaceOrigin.hubTarget()', 'property var routedScreen: Services.SurfaceOrigin.hubTarget()')
 p.write_text('\n'.join(line for line in s.splitlines() if not any(token in line for token in ['anchors { top: true;', 'exclusionMode:', 'WlrLayershell.'])))
 (config/'test.qml').write_text(Path(__file__).with_name('lifecycle.qml').read_text().replace('../../.config/quickshell/magi/',''))
 runtime=stage/'runtime';runtime.mkdir(mode=0o700)
 env=dict(os.environ,HOME=str(stage),XDG_RUNTIME_DIR=str(runtime),XDG_CONFIG_HOME=str(stage/'config'),XDG_STATE_HOME=str(stage/'state'),XDG_DATA_HOME=str(stage/'data'),XDG_CACHE_HOME=str(stage/'cache'),QT_QPA_PLATFORM='offscreen',QT_QUICK_BACKEND='software')
 env.pop('DISPLAY',None);env.pop('WAYLAND_DISPLAY',None)
 if env.get('MAGI_10B_CAPTURES'):Path(env['MAGI_10B_CAPTURES']).mkdir(parents=True,exist_ok=True)
 try:
  result=subprocess.run(['quickshell','-p',str(config/'test.qml'),'--no-color'],env=env,text=True,capture_output=True,timeout=150)
 except subprocess.TimeoutExpired as e:
  print(e.stdout.decode() if isinstance(e.stdout,bytes) else e.stdout);raise
 output=result.stdout+result.stderr;print(output)
 expected=['Failed to start IPC server','This plugin does not support setting window masks','Unable to find hyprland socket']
 checked='\n'.join(line for line in output.splitlines() if not any(s in line for s in expected))
 assert result.returncode==0 and 'Phase 10B lifecycle PASS' in output and not any(s in checked for s in ['ERROR','WARN','FAIL'])
