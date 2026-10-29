#!/usr/bin/env python3
from pathlib import Path
import os, shutil, subprocess, tempfile

root = Path(__file__).resolve().parents[2]
with tempfile.TemporaryDirectory(prefix='magi-daily-polish-test-') as temporary:
    stage = Path(temporary)
    shutil.copytree(root / '.config/quickshell/magi', stage / 'magi')
    harness = Path(__file__).with_name('presentation.qml').read_text().replace('../../.config/quickshell/magi/', '')
    (stage / 'magi/test.qml').write_text(harness)
    (stage / 'magi/settings.json').write_text('{"schemaVersion":22}')
    runtime = stage / 'runtime'; runtime.mkdir(mode=0o700)
    env = dict(os.environ, QT_QPA_PLATFORM='offscreen', QT_QUICK_BACKEND=os.environ.get('MAGI_TEST_RENDERER','software'),
               HOME=str(stage), XDG_CONFIG_HOME=str(stage/'config'), XDG_STATE_HOME=str(stage/'state'), XDG_RUNTIME_DIR=str(runtime), XDG_DATA_HOME=str(stage/'data'), XDG_CACHE_HOME=str(stage/'cache'))
    env.pop('WAYLAND_DISPLAY', None); env.pop('DISPLAY', None)
    result = subprocess.run(['quickshell','-p',str(stage/'magi/test.qml'),'--no-color'], env=env,
                            text=True, capture_output=True, timeout=60)
    output = result.stdout + result.stderr
    print(output)
    checked = '\n'.join(line for line in output.splitlines()
                        if 'ERROR quickshell.ipc: Failed to start IPC server' not in line and 'This plugin does not support setting window masks' not in line)
    assert result.returncode == 0 and 'Daily polish PASS' in output and 'ERROR' not in checked and 'FAIL' not in checked and 'WARN' not in checked
