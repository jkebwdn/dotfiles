#!/usr/bin/env python3
"""Live fullscreen suppression using a disposable client; never fullscreen a user app."""
from pathlib import Path
import json
import subprocess
import tempfile
import time


def call(target, method, *args):
    return subprocess.check_output(['quickshell', 'ipc', '-c', 'magi', 'call', target, method, *args], text=True, timeout=5).strip()
def state(target): return json.loads(call(target, 'status'))
def active(): return json.loads(subprocess.check_output(['hyprctl', '-j', 'activewindow'], text=True, timeout=5))
def settle(): time.sleep(.7)

with tempfile.TemporaryDirectory(prefix='magi-hub-fullscreen-') as tmp:
    config = Path(tmp) / 'shell.qml'
    config.write_text('''import QtQuick
import Quickshell
ShellRoot {
    FloatingWindow {
        visible: true; title: "MAGI Hub fullscreen fixture"
        implicitWidth: 400; implicitHeight: 200
        color: "#1e1e2e"
        Text { anchors.centerIn: parent; text: "MAGI Hub fullscreen test"; color: "white" }
    }
}
''')
    assert not state('hub')['opened']
    log = open(Path(tmp) / 'shell.log', 'w+')
    process = subprocess.Popen(['quickshell', '-p', str(config), '--no-color'], stdout=log, stderr=log)
    try:
        for _ in range(40):
            if active().get('title') == 'MAGI Hub fullscreen fixture': break
            time.sleep(.1)
        else: raise AssertionError('Fixture did not gain focus; no fullscreen dispatch sent')
        call('emoji', 'open'); settle()
        assert state('hubWindow')['visible']
        # Exclusive layers preserve the underlying active client. Guard its title.
        assert active().get('title') == 'MAGI Hub fullscreen fixture'
        subprocess.run(['hyprctl', 'dispatch', 'hl.dsp.window.fullscreen({mode="fullscreen",action="set"})'], check=True, timeout=5)
        settle()
        assert active().get('fullscreen') == 2
        assert state('hub')['suppressed'] and not state('hubWindow')['visible']
        for target in ['launcher', 'notifications', 'emoji', 'clipboard']:
            call(target, 'toggle')
            assert not state('hub')['opened']
        subprocess.run(['hyprctl', 'dispatch', 'hl.dsp.window.fullscreen({mode="fullscreen",action="unset"})'], check=True, timeout=5)
        settle()
        assert not state('hub')['suppressed'] and not state('hubWindow')['visible']
        call('emoji', 'open'); settle()
        assert state('hubWindow')['focused']
        call('hub', 'close'); settle()
        assert active().get('title') == 'MAGI Hub fullscreen fixture'
        print('Live Hub fullscreen PASS: close on entry, all shortcuts blocked, no automatic reopen, explicit recovery focus')
    finally:
        call('hub', 'close')
        process.terminate(); process.wait(timeout=5)
        log.close()
