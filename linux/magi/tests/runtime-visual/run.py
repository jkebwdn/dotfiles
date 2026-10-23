#!/usr/bin/env python3
"""Production runtime visual/interaction contracts; isolated adapters, no native quality claims."""
import ast
import json
import sys
import os
from pathlib import Path
import shutil
import subprocess
import tempfile

root=Path(__file__).resolve().parents[2]
# Reuse existing literal test adapters, without executing their runner.
tree=ast.parse((root/'tests/settings/modules.py').read_text())
stubs=next(ast.literal_eval(n.value) for n in ast.walk(tree) if isinstance(n,ast.Assign)
           and any(isinstance(t,ast.Name) and t.id=='stubs' for t in n.targets))
with tempfile.TemporaryDirectory(prefix='magi-runtime-visual-') as temporary:
    stage=Path(temporary);config=stage/'config'
    shutil.copytree(root/'.config/quickshell/magi',config)
    (config/'test-artwork.ppm').write_bytes(b'P6\n120 40\n255\n' + bytes([0,255,255]) * 120 * 40)
    for name, w, h in [('square',64,64),('portrait',40,120)]:
        (config/f'{name}.ppm').write_bytes(f'P6\n{w} {h}\n255\n'.encode() + bytes([255,120,20]) * w * h)
    (config/'settings.json').write_text('{"schemaVersion":10}')
    stubs['Battery'] += '\nproperty string statusText: "Unavailable"'
    # Replace only Hyprland input in the copied workspace presenter.
    workspace = config/'plugins/bar/workspaces/Workspaces.qml'
    source = workspace.read_text().replace('import Quickshell.Hyprland', '')
    source = source.replace('id: root', 'id: root; objectName: "testWorkspaces"; property int testCurrent: 1', 1)
    source = source.replace('Component.onCompleted: Hyprland.refreshWorkspaces()', '')
    source = source.replace('Hyprland.workspaces.values', '[{id:1,name:"1"},{id:2,name:"2"},{id:3,name:"3"}]')
    source = source.replace('outputScreen ? Hyprland.monitorFor(outputScreen) : null', '({activeWorkspace:{id:root.testCurrent}})')
    workspace.write_text(source)
    for name,body in stubs.items():
        (config/f'services/{name}.qml').write_text('pragma Singleton\nimport QtQuick\nQtObject { id: root\n'+body+'\n}')
    # Offscreen Qt has no layer-shell backend. Adapt only the native wrapper;
    # production bar content, masks and shared animation owners remain intact.
    path=config/'components/bar/Bar.qml'
    source=path.read_text()
    assert 'exclusiveZone: fullSurface ? geometry.reservation : 0' in source
    source=source.replace('PanelWindow {','FloatingWindow {',1).replace('        syncPlacement()', '        MagiServices.SurfaceOrigin.mainScreen = bar.outputScreen\n        syncPlacement()')
    start=source.index('    exclusiveZone:')
    end=source.index('    implicitHeight:',start)
    source=source[:start]+"    property int exclusiveZone: fullSurface ? geometry.reservation : 0\n    implicitWidth: 1200\n"+source[end:]
    path.write_text(source)
    path=config/'components/hub/HubWindow.qml'
    source=path.read_text().replace('PanelWindow {','FloatingWindow {\n    implicitWidth: 1920; implicitHeight: 1080',1)
    path.write_text('\n'.join(line for line in source.splitlines() if not any(token in line for token in
        ['anchors { top: true;', 'exclusionMode:', 'WlrLayershell.'])))
    if len(sys.argv) > 1 and sys.argv[1] == 'colours.qml':
        # Read the oracle directly from the immutable committed tree, never from
        # current helper formulas. Relocate imports only to share identical inputs.
        def old(path):
            return subprocess.check_output(['git','show','7afd1c6:linux/magi/.config/quickshell/magi/' + path],cwd=root,text=True)
        reference=config/'reference';reference.mkdir()
        for name in ['Theme.qml','RenderTokens.qml','ThemeRegistry.qml']:
            (reference/name).write_text(old('theme/'+name))
        (reference/'palettes').mkdir()
        (reference/'palettes/registry.json').write_text(old('theme/palettes/registry.json'))
        (reference/'qmldir').write_text('singleton Theme 1.0 Theme.qml\nsingleton RenderTokens 1.0 RenderTokens.qml\nsingleton ThemeRegistry 1.0 ThemeRegistry.qml\n')
        tile=old('plugins/bar/controlcentre/ControlTile.qml')
        tile=tile.replace('"../../../components/controls"','"../components/controls"').replace('"../../../theme"','"."')
        (reference/'ControlTile.qml').write_text(tile)
        # Phase 10A replaces icon lookup. This oracle compares tile geometry and
        # semantic RGBA supplied to the shared renderer, not resolver identity.
        # tests/settings/icons.cjs independently covers the new manifest contract.
    if len(sys.argv) > 1 and sys.argv[1] == 'weather.qml':
        (config/'services/weather.py').rename(config/'services/weather_backend.py')
        shutil.copy(root/'tests/weather/fixture.py',config/'services/weather.py')
    (config/'test.qml').write_text((Path(__file__).parent / (sys.argv[1] if len(sys.argv) > 1 else 'runtime.qml')).read_text().replace('../../.config/quickshell/magi/',''))
    runtime=stage/'runtime';runtime.mkdir(mode=0o700)
    env=dict(os.environ,QT_QPA_PLATFORM='offscreen',QT_QUICK_BACKEND='software',XDG_RUNTIME_DIR=str(runtime),XDG_STATE_HOME=str(stage/'state'), HOME=str(stage), XDG_CONFIG_HOME=str(stage/'xdg-config'), XDG_DATA_HOME=str(stage/'data'), XDG_CACHE_HOME=str(stage/'cache'))
    env.pop('WAYLAND_DISPLAY',None);env.pop('DISPLAY',None)
    result=subprocess.run(['quickshell','-p',str(config/'test.qml'),'--no-color'],env=env,capture_output=True,text=True,timeout=120 if len(sys.argv) > 1 and sys.argv[1] == "appearance.qml" else 60)
    output=result.stdout+result.stderr
    checked='\n'.join(line for line in output.splitlines() if 'Failed to start IPC server' not in line
                      and 'This plugin does not support setting window masks' not in line
                      and 'WARN: Unable to find hyprland socket. Cannot connect to hyprland.' not in line)
    print(checked)
    assert result.returncode==0 and 'PASS' in output and ({'../phase12d/runtime.qml':'Phase12D runtime composition PASS','../phase12b/surfaces.qml':'Phase12B surfaces PASS','typography.qml':'Phase 2E.2 typography navigation toggles PASS','weather.qml':'Weather service PASS','feedback.qml':'Phase 2E.1 feedback PASS','polish.qml':'Phase 2E polish PASS','secondary.qml':'Secondary surfaces PASS','appearance.qml':'CC appearance and preview PASS','colours.qml':'7afd1c6 colour equivalence PASS','hub.qml':'Hub production preview PASS'}[sys.argv[1]] if len(sys.argv) > 1 else 'Artwork contour geometry PASS') in output and 'ERROR' not in checked and 'WARN' not in checked and 'FAIL!' not in checked and 'FAIL:' not in checked
