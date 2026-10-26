#!/usr/bin/env python3
"""Real GIO + isolated Quickshell lifecycle; no user applications or live shell.

Default delayed write is over two minutes after launch. Use --delay 2 for a
quick development run. A baseline negative control proves closed-pipe detection.
"""
import argparse
import json
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import time

parser = argparse.ArgumentParser()
parser.add_argument('--delay', type=float, default=125)
args = parser.parse_args()
assert args.delay >= 0
root = Path(__file__).resolve().parents[2]


def wait_for(predicate, timeout=10):
    end = time.monotonic() + timeout
    while time.monotonic() < end:
        if predicate():
            return
        time.sleep(.05)
    raise AssertionError('Timed out waiting for lifecycle evidence')


with tempfile.TemporaryDirectory(prefix='magi-launcher-lifecycle-') as temporary:
    stage = Path(temporary)
    config = stage / 'config'
    shutil.copytree(root / '.config/quickshell/magi', config)
    (config / 'settings.json').write_text('{"schemaVersion":21}')
    child = stage / 'child.py'
    child.write_text('''import errno,json,os,sys,time
from pathlib import Path
folder=Path(sys.argv[1]); started=time.monotonic()
folder.mkdir(exist_ok=True)
def save(name,value):
    temp=folder/(name+'.tmp');temp.write_text(json.dumps(value));temp.replace(folder/name)
save('started',{'pid':os.getpid(),'fds':{str(n):os.readlink('/proc/self/fd/'+str(n)) for n in range(3)}})
try:
    for event in ['closed','reloaded','late']:
        deadline=time.monotonic()+180
        while not (folder/('go-'+event)).exists():
            if time.monotonic()>deadline: raise RuntimeError('gate timeout')
            time.sleep(.02)
        for fd in [1,2]: os.write(fd,('delayed '+event+' output\\n').encode())
        save(event,{'healthy':True,'elapsed':time.monotonic()-started})
    save('done',{'healthy':True})
except Exception as error:
    save('error',{'type':type(error).__name__,'errno':getattr(error,'errno',None)})
''')
    apps = stage / 'data/applications'
    apps.mkdir(parents=True)
    env = dict(os.environ, HOME=str(stage), XDG_CONFIG_HOME=str(stage/'xdg-config'),
               XDG_DATA_HOME=str(apps.parent), XDG_DATA_DIRS=str(stage/'empty-data'),
               XDG_STATE_HOME=str(stage/'state'), XDG_CACHE_HOME=str(stage/'cache'),
               XDG_RUNTIME_DIR=str(stage/'runtime'), XDG_CURRENT_DESKTOP='Hyprland',
               QT_QPA_PLATFORM='offscreen', QT_QUICK_BACKEND='software',
               MAGI_LIFECYCLE_RELOADED=str(stage/'reloaded'))
    Path(env['XDG_RUNTIME_DIR']).mkdir(mode=0o700)
    for key in ['WAYLAND_DISPLAY', 'DISPLAY', 'HYPRLAND_INSTANCE_SIGNATURE', 'DBUS_SESSION_BUS_ADDRESS']:
        env.pop(key, None)

    def entry(folder):
        (apps/'lifecycle.desktop').write_text(
            '[Desktop Entry]\nType=Application\nName=Lifecycle Fixture\n'
            f'Exec=python3 {child} {folder}\n')

    # The old app.launch() inherits pipes, despite returning successful launch.
    negative = stage/'negative'
    entry(negative)
    old = "import gi; gi.require_version('GioUnix','2.0'); from gi.repository import Gio,GioUnix; assert GioUnix.DesktopAppInfo.new('lifecycle.desktop').launch([],Gio.AppLaunchContext())"
    process = subprocess.Popen(['python3', '-c', old], env=env,
                               stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    assert process.wait(timeout=5) == 0
    wait_for(lambda: (negative/'started').exists())
    process.stdout.close(); process.stderr.close()
    (negative/'go-closed').touch()
    wait_for(lambda: (negative/'error').exists())
    assert json.loads((negative/'error').read_text())['errno'] == 32
    print('Baseline negative control: launch succeeded, later output raises EPIPE PASS', flush=True)

    positive = stage/'positive'
    entry(positive)
    harness = Path(__file__).with_suffix('.qml').read_text().replace('../../.config/quickshell/magi/', '')
    (config/'test.qml').write_text(harness)
    log_path = stage/'shell.log'
    with log_path.open('w+') as log:
        shell = subprocess.Popen(['quickshell', '-p', str(config/'test.qml'), '--no-color'],
                                 env=env, stdout=log, stderr=subprocess.STDOUT)
        try:
            def logged(message):
                return message in log_path.read_text()
            wait_for(lambda: logged('LIFECYCLE_UI_DESTROYED'))
            wait_for(lambda: (positive/'started').exists())
            data = json.loads((positive/'started').read_text())
            assert set(data['fds'].values()) == {'/dev/null'}, data
            (positive/'go-closed').touch()
            wait_for(lambda: (positive/'closed').exists())
            print('Hub closed + LauncherContent destroyed; child stdout/stderr healthy PASS', flush=True)
            wait_for(lambda: logged('LIFECYCLE_RELOADED'))
            (positive/'go-reloaded').touch()
            wait_for(lambda: (positive/'reloaded').exists())
            assert shell.wait(timeout=10) == 0
            print('Same shell hard reload + subsequent shell exit; child healthy PASS', flush=True)
        finally:
            if shell.poll() is None:
                shell.terminate()  # Only this disposable test shell, never MAGI.
                shell.wait(timeout=5)
    time.sleep(args.delay)
    (positive/'go-late').touch()
    wait_for(lambda: (positive/'done').exists() or (positive/'error').exists())
    assert not (positive/'error').exists(), (positive/'error').read_text()
    elapsed = json.loads((positive/'late').read_text())['elapsed']
    assert elapsed >= args.delay
    print(f'Output after shell exit at {elapsed:.1f}s; no broken pipe; child completed PASS', flush=True)
