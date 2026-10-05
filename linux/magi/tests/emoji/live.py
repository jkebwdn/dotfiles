#!/usr/bin/env python3
"""Explicit live focus/layer/handoff check. No clipboard read/write or settings edits.
Opens/closes MAGI surfaces and types only after confirming Emoji owns an overlay.
"""
import json
import subprocess
import time


def call(target, method, *args):
    return subprocess.check_output(['quickshell','ipc','-c','magi','call',target,method,*args], text=True, timeout=5).strip()


def state(target): return json.loads(call(target, 'status'))
def hypr(command): return json.loads(subprocess.check_output(['hyprctl',command,'-j'], text=True, timeout=5))
def settle(): time.sleep(.8)
def key(name):
    assert state('emoji')['opened']
    subprocess.run(['hyprctl','dispatch',f'hl.dsp.send_shortcut({{mods = "", key = "{name}"}})'], check=True, stdout=subprocess.DEVNULL, timeout=5)
    time.sleep(.12)


def reservation():
    assert all(m['reserved'] == [0,48,0,0] for m in hypr('monitors'))


try:
    assert not state('emoji')['opened'], 'Close Emoji before running this fixture'
    reservation()
    previous = hypr('activewindow').get('address')
    for view in ('calendar','controlcentre'):
        assert call('magi','open',view) == 'true'
        settle()
        assert state('magi')['active'] == view
        call('emoji','open'); settle()
        assert state('emoji')['opened'] and state('magi')['active'] == ''
        reservation()
        layers = hypr('layers')
        overlays = [layer for output in layers.values() for layer in output['levels']['3'] if layer['namespace'] == 'magi-emoji']
        assert len(overlays) == 1
        assert call('magi','open',view) == 'true'
        settle()
        assert not state('emoji')['opened'] and state('magi')['active'] == view
        call('magi','close'); settle()
    for _ in range(2):
        call('emoji','open'); settle()
        for letter in 'fire': key(letter)
        assert 0 < state('emoji')['count'] < 3944, 'Immediate typing did not filter'
        key('Right'); assert state('emoji')['selected'] == 1
        key('Left'); assert state('emoji')['selected'] == 0
        key('Escape'); settle()
        assert not state('emoji')['opened']
    reservation()
    assert hypr('activewindow').get('address') == previous, 'Previous window did not regain focus'
    assert not subprocess.check_output(['hyprctl','configerrors'], text=True, timeout=5).strip()
    print('Live Emoji overlay, immediate typing, arrows, Escape, reopen focus, Calendar/CC handoff, previous-app restoration, 48px reservation and Hyprland config health PASS')
finally:
    call('emoji','close'); call('magi','close')
