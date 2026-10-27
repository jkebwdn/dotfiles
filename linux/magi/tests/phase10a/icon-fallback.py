#!/usr/bin/env python3
"""Isolated production bar/CC and exact-role fallback. Never connects to the live shell."""
from pathlib import Path
import ast,json,os,shutil,subprocess,tempfile
root=Path(__file__).resolve().parents[2]
tree=ast.parse((root/'tests/settings/modules.py').read_text())
stubs=next(ast.literal_eval(n.value) for n in ast.walk(tree) if isinstance(n,ast.Assign) and any(isinstance(t,ast.Name) and t.id=='stubs' for t in n.targets))
with tempfile.TemporaryDirectory(prefix='magi-fallback-') as tmp:
    stage=Path(tmp);config=stage/'shell'
    shutil.copytree(root/'.config/quickshell/magi',config)
    (config/'settings.json').write_text('{"schemaVersion":13}')
    for name,body in stubs.items():
        if name=='Battery':body+='\nproperty string statusText: "Battery fixture"'
        (config/f'services/{name}.qml').write_text('pragma Singleton\nimport QtQuick\nQtObject { id:root\n'+body+'\n}')
    (config/'services/TrayService.qml').write_text('pragma Singleton\nimport QtQuick\nTrayModel {}\n')
    workspace=config/'plugins/bar/workspaces/Workspaces.qml'
    text=workspace.read_text().replace('import Quickshell.Hyprland','').replace('Component.onCompleted: Hyprland.refreshWorkspaces()','')
    text=text.replace('Hyprland.workspaces.values','[{id:1,name:"1"}]').replace('Hyprland.focusedWorkspace !== null','true').replace('Hyprland.focusedWorkspace.id','1')
    text=text.replace('outputScreen ? Hyprland.monitorFor(outputScreen) : null', 'null')
    workspace.write_text(text)
    p=config/'components/bar/Bar.qml';text=p.read_text().replace('PanelWindow {','FloatingWindow {',1)
    a=text.index('    exclusiveZone:');b=text.index('    implicitHeight:',a)
    text=text[:a]+'    property int exclusiveZone: 48\n    implicitWidth: 1200\n'+text[b:];p.write_text(text)
    pack=stage/'data/magi/icon-packs/incomplete-fixture';pack.mkdir(parents=True)
    (pack/'manifest.json').write_text(json.dumps({'formatVersion':1,'id':'incomplete-fixture','displayName':'Incomplete fixture','roles':{'wifi':{'asset':'wifi.svg'}}}))
    shutil.copy(config/'icons/packs/magi-default/wifi.svg',pack/'wifi.svg')
    (config/'test.qml').write_text(Path(__file__).with_suffix('.qml').read_text().replace('../../.config/quickshell/magi/',''))
    runtime=stage/'runtime';runtime.mkdir(mode=0o700)
    env=dict(os.environ,HOME=str(stage),XDG_CONFIG_HOME=str(stage/'config'),XDG_DATA_HOME=str(stage/'data'),XDG_CACHE_HOME=str(stage/'cache'),XDG_STATE_HOME=str(stage/'state'),XDG_RUNTIME_DIR=str(runtime),QT_QPA_PLATFORM='offscreen',QT_QUICK_BACKEND='software')
    env.pop('DISPLAY',None);env.pop('WAYLAND_DISPLAY',None)
    if env.get('MAGI_FALLBACK_CAPTURES'):
        Path(env['MAGI_FALLBACK_CAPTURES']).mkdir(parents=True,exist_ok=True)
        # Qt software cannot render MultiEffect. For SHAPE previews only, expose
        # the real resolved SVG Image in white; production glyph colours remain.
        # First run this fixture without captures to test the unchanged renderer.
        p=config/'components/controls/Icon.qml';text=p.read_text().replace('root.assetIcon && !root.semanticAsset && status !== Image.Error','root.assetIcon && status !== Image.Error').replace('visible: root.semanticAsset && asset.status !== Image.Error','visible: false')
        p.write_text(text)
    result=subprocess.run(['quickshell','-p',str(config/'test.qml'),'--no-color'],env=env,capture_output=True,text=True,timeout=30)
    output=result.stdout+result.stderr;print(output)
    known=['Failed to start IPC server','This plugin does not support setting window masks','Unable to find hyprland socket','Cannot open: file:', 'Could not connect to DBus.','Network will not work. Could not find an available backend.']
    checked='\n'.join(line for line in output.splitlines() if not any(k in line for k in known) and not ('Cannot open: file:' in line and line.endswith('/unreadable.svg')))
    assert result.returncode==0 and 'image-error recovery PASS' in output and not any(k in checked for k in ['WARN','ERROR','FAIL'])
