#!/usr/bin/env python3
"""Actual host/card/centre types offscreen. Native compositor input is operator-only."""
from pathlib import Path
import os, shutil, subprocess, tempfile
root = Path(__file__).resolve().parents[2]
with tempfile.TemporaryDirectory(prefix='magi-notification-ui-') as tmp:
    stage=Path(tmp); config=stage/'config'; shutil.copytree(root/'.config/quickshell/magi',config)
    # Qt offscreen has no layer-shell backend. Substitute only the native window
    # wrapper; exercise production content, animation and Region bindings intact.
    for name in ['ToastHost.qml','NotificationCentre.qml']:
        path=config/'components/notifications'/name
        text=path.read_text().replace('PanelWindow {','FloatingWindow {')
        text='\n'.join(line for line in text.splitlines() if not any(token in line for token in
            ['anchors { top: true;', 'margins {', 'exclusiveZone:', 'exclusionMode:', 'WlrLayershell.']))
        path.write_text(text)
    (config/'test.qml').write_text(Path(__file__).with_name('presentation.qml').read_text()
        .replace('../../.config/quickshell/magi/',''))
    runtime=stage/'runtime'; runtime.mkdir(mode=0o700)
    env=dict(os.environ, QT_QPA_PLATFORM='offscreen',QT_QUICK_BACKEND='software',
             XDG_RUNTIME_DIR=str(runtime),XDG_STATE_HOME=str(stage/'state'))
    env.pop('WAYLAND_DISPLAY',None); env.pop('DISPLAY',None)
    result=subprocess.run(['quickshell','-p',str(config/'test.qml'),'--no-color'],env=env,
                          text=True,capture_output=True,timeout=15)
    output=result.stdout+result.stderr; print(output)
    checked='\n'.join(line for line in output.splitlines()
        if 'ERROR quickshell.ipc: Failed to start IPC server' not in line
        and 'This plugin does not support setting window masks' not in line)
    assert result.returncode==0 and 'RESULT: 0 failures' in output and 'ERROR' not in checked and 'WARN' not in checked
