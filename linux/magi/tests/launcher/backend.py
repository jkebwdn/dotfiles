#!/usr/bin/env python3
"""Isolated XDG entries: visibility, precedence, field codes and launch failures."""
import json
import os
from pathlib import Path
import subprocess
import tempfile
import time

helper = Path('.config/quickshell/magi/services/launcher_backend.py').resolve()
with tempfile.TemporaryDirectory(prefix='magi-launcher-backend-') as temp:
    stage = Path(temp)
    apps = stage / 'data/applications'
    apps.mkdir(parents=True)
    system = stage / 'system/applications'
    system.mkdir(parents=True)
    script = stage / 'record.py'
    output = stage / 'result.json'
    script.write_text('import json,os,sys\nfrom pathlib import Path\nPath(sys.argv[1]).write_text(json.dumps([os.getcwd(),sys.argv[2:]]))\n')
    entry = f'[Desktop Entry]\nType=Application\nName=Launch Fixture\nGenericName=Test App\nKeywords=alpha;beta;\nExec=python3 {script} {output} %c %k %f\nPath={stage}\n'
    (apps / 'fixture.desktop').write_text(entry)
    (system / 'fixture.desktop').write_text(entry.replace('Launch Fixture','Wrong Override'))
    (apps / 'hidden.desktop').write_text(entry+'Hidden=true\n')
    (apps / 'nodisplay.desktop').write_text(entry+'NoDisplay=true\n')
    (apps / 'other.desktop').write_text(entry+'OnlyShowIn=OtherDesktop;\n')
    (apps / 'broken.desktop').write_text('[Desktop Entry]\nType=Application\nName=Broken\nExec=/nonexistent/magi-test-app\n')
    env = dict(os.environ,XDG_DATA_HOME=str(apps.parent),XDG_DATA_DIRS=str(system.parent),XDG_CURRENT_DESKTOP='Hyprland')
    def call(*args):
        return subprocess.run(['python3',str(helper),*args],env=env,capture_output=True,text=True,timeout=5)
    result = call('--list')
    assert result.returncode == 0, result.stderr
    rows=json.loads(result.stdout)
    assert [a['id'] for a in rows] == ['fixture.desktop'],rows
    assert rows[0]['keywords'] == ['alpha','beta']
    result=call('--launch','fixture.desktop')
    assert result.returncode == 0,result.stderr
    for _ in range(50):
        if output.exists(): break
        time.sleep(.02)
    cwd,args=json.loads(output.read_text())
    assert cwd == str(stage)
    assert args == ['Launch Fixture',str(apps/'fixture.desktop')],args
    for name in ['missing.desktop','hidden.desktop','nodisplay.desktop','other.desktop','broken.desktop']:
        assert call('--launch',name).returncode != 0,name
    # A fake Ghostty verifies terminal argv and environment without opening a window.
    binary = stage / 'bin'
    binary.mkdir()
    terminal = binary / 'ghostty'
    terminal.write_text('#!/usr/bin/python3\nimport os,sys\nassert sys.argv[1] == "-e"\nassert "MAGI_LAUNCHER_PATH" not in os.environ\nos.execvp(sys.argv[2],sys.argv[2:])\n')
    terminal.chmod(0o755)
    env['PATH'] = str(binary) + os.pathsep + env['PATH']
    (apps / 'fixture.desktop').write_text(entry+'Terminal=true\n')
    output.unlink()
    result=call('--launch','fixture.desktop')
    assert result.returncode == 0,result.stderr
    for _ in range(50):
        if output.exists(): break
        time.sleep(.02)
    assert json.loads(output.read_text()) == [str(stage),['Launch Fixture',str(apps/'fixture.desktop')]]
    print('GIO terminal Ghostty adapter preserves argv, field codes, cwd and restores PATH PASS')
    print('GIO XDG visibility, override precedence, metadata, execution, field codes, working directory and failure PASS')
