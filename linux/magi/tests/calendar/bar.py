#!/usr/bin/env python3
"""Production Bar and Calendar with the established isolated system-service stubs."""
import ast
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
with tempfile.TemporaryDirectory(prefix='magi-calendar-bar-') as temporary:
    stage=Path(temporary);config=stage/'config'
    shutil.copytree(root/'.config/quickshell/magi',config)
    (config/'settings.json').write_text('{"schemaVersion":8,"bar":{"left":["clock","date"],"center":[],"right":["controlcentre"]}}')
    stubs['Battery'] += '\nproperty string statusText: \"Unavailable\"'
    (config/'plugins/bar/workspaces/Workspaces.qml').write_text('import QtQuick\nItem { implicitWidth: 80; implicitHeight: 28 }')
    for name,body in stubs.items():
        (config/f'services/{name}.qml').write_text('pragma Singleton\nimport QtQuick\nQtObject { id: root\n'+body+'\n}')
    # Offscreen Qt has no layer-shell backend. Adapt only the native wrapper;
    # production bar content, masks and shared animation owners remain intact.
    path=config/'components/bar/Bar.qml'
    source=path.read_text().replace('PanelWindow {','FloatingWindow {',1)
    start=source.index('    exclusiveZone:')
    end=source.index('    implicitHeight:',start)
    source=source[:start]+"    property int exclusiveZone: fullSurface ? 48 : 0\n    implicitWidth: 1200\n"+source[end:]
    path.write_text(source)
    (config/'test.qml').write_text(Path(__file__).with_name('bar.qml').read_text().replace('../../.config/quickshell/magi/',''))
    runtime=stage/'runtime';runtime.mkdir(mode=0o700)
    env=dict(os.environ,QT_QPA_PLATFORM='offscreen',QT_QUICK_BACKEND='software',XDG_RUNTIME_DIR=str(runtime),XDG_STATE_HOME=str(stage/'state'))
    env.pop('WAYLAND_DISPLAY',None);env.pop('DISPLAY',None)
    result=subprocess.run(['quickshell','-p',str(config/'test.qml'),'--no-color'],env=env,capture_output=True,text=True,timeout=20)
    output=result.stdout+result.stderr
    checked='\n'.join(line for line in output.splitlines() if 'Failed to start IPC server' not in line
                      and 'This plugin does not support setting window masks' not in line)
    print(checked)
    assert result.returncode==0 and 'PASS' in output and 'ERROR' not in checked and 'WARN' not in checked
