#!/usr/bin/env python3
"""Real Settings/Process bridge in disposable HOME and XDG roots."""
from pathlib import Path
import os
import json
import shutil
import subprocess
import tempfile

ROOT = Path(__file__).resolve().parents[2]
with tempfile.TemporaryDirectory(prefix='magi-orchestrator-qml-') as tmp:
    stage = Path(tmp)
    config = stage/'shell'
    shutil.copytree(ROOT/'.config/quickshell/magi', config)
    (config/'settings.json').write_text('{"schemaVersion":10}')
    path = config/'components/hub/HubWindow.qml'
    text = path.read_text().replace('PanelWindow {', 'FloatingWindow {\n    implicitWidth: 1280; implicitHeight: 900')
    path.write_text('\n'.join(line for line in text.splitlines() if not any(token in line for token in
        ['anchors { top: true;', 'exclusionMode:', 'WlrLayershell.'])))
    # No running host application may receive a fixture activation request.
    executor = config/'services/theme_activation/executor.py'
    executor.write_text(executor.read_text().replace('        found=[]', '        return []  # isolated fixture: no running applications\n        found=[]', 1))
    app = stage/'config/ghostty/config.ghostty'
    app.parent.mkdir(parents=True)
    app.write_text('font-size = 11\n')
    runtime = stage/'runtime'; runtime.mkdir(mode=0o700)
    profile = stage/'.zen/release'
    (profile/'chrome').mkdir(parents=True)
    (profile/'chrome/userChrome.css').write_text('/* existing custom CSS */\n')
    (profile/'prefs.js').write_text('user_pref("toolkit.legacyUserProfileCustomizations.stylesheets", true);\n')
    (stage/'.zen/profiles.ini').write_text('[Profile0]\nPath=release\nIsRelative=1\n[Install15B76BAA26BA15E7]\nDefault=release\n')
    (stage/'.zen/installs.ini').write_text('[15B76BAA26BA15E7]\nDefault=release\n')
    # Transfer the explicit operator confirmation to this isolated test profile.
    zen = config/'services/theme_orchestrator/adapters/zen.py'
    zen.write_text(zen.read_text().replace('/home/jkebwdn/.zen/0rzna1o3.Default (release)', str(profile)))
    bin_dir = stage/'bin'; bin_dir.mkdir()
    copier = bin_dir/'wl-copy'
    copier.write_text("#!/usr/bin/python3\nimport json,os,sys\nassert sys.argv[1:] == ['--type','text/plain;charset=utf-8']\nwith open(os.environ['MAGI_COPY_CAPTURE'], 'a') as out: out.write(json.dumps(sys.stdin.read())+'\\n')\n")
    copier.chmod(0o700)
    for harness in ('integration.qml', '../settings/window.qml', 'pointer.qml'):

        source = Path(__file__).parent/harness
        (config/'test.qml').write_text(source.read_text().replace('../../.config/quickshell/magi/', ''))
        env = dict(os.environ, PATH=str(bin_dir)+os.pathsep+os.environ['PATH'],
                   MAGI_COPY_CAPTURE=str(stage/'copied.jsonl'), HOME=str(stage), XDG_CONFIG_HOME=str(stage/'config'),
                   XDG_DATA_HOME=str(stage/'data'), XDG_STATE_HOME=str(stage/'state'),
                   XDG_RUNTIME_DIR=str(runtime), QT_QPA_PLATFORM='offscreen', QT_QUICK_BACKEND='software')
        env.pop('WAYLAND_DISPLAY', None); env.pop('DISPLAY', None)
        result = subprocess.run(['quickshell', '-p', str(config/'test.qml'), '--no-color'],
                                text=True, capture_output=True, env=env, timeout=25)
        output = result.stdout + result.stderr
        print(output)
        checked = '\n'.join(line for line in output.splitlines() if 'ERROR quickshell.ipc: Failed to start IPC server' not in line
                            and 'ERROR quickshell.network: Network will not work. Could not find an available backend.' not in line)
        marker = 'Theme pointer PASS' if harness == 'pointer.qml' else 'RESULT: 0 failures'
        assert result.returncode == 0 and marker in output and 'ERROR' not in checked and 'FAIL:' not in checked and 'FAIL!' not in checked, (harness, result.returncode)
    assert 'config-file = /user/' in app.read_text(), 'Removal must retain user-edited hook'
    assert (profile/'chrome/userChrome.css').read_text() == '/* existing custom CSS */\n'
    registry = json.loads((config/'theme/palettes/registry.json').read_text())
    copied = [json.loads(line) for line in (stage/'copied.jsonl').read_text().splitlines()]
    assert copied == [theme['roles']['background'] for theme in registry['themes']], copied
    print('Zen Copy: exact hex-only clipboard payload for all current palettes PASS')
