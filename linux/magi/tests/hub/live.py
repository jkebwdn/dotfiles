#!/usr/bin/env python3
"""Live compositor integration; no clipboard access, app launch or settings writes.

Uses existing IPC and injects keys only after confirming Hub owns keyboard focus.
Physical pointer/shortcut acceptance remains operator review.
"""
import json
import subprocess
import time


def call(target, method, *args):
    return subprocess.check_output(['quickshell', 'ipc', '-c', 'magi', 'call', target, method, *args], text=True, timeout=5).strip()


def state(target): return json.loads(call(target, 'status'))
def hypr(command): return json.loads(subprocess.check_output(['hyprctl', command, '-j'], text=True, timeout=5))
def settle(): time.sleep(.65)
def reservation(): assert all(m['reserved'] == [0, 48, 0, 0] for m in hypr('monitors'))
def layers(): return [layer for output in hypr('layers').values() for level in output['levels'].values() for layer in level]
def host():
    utility = [layer for layer in layers() if layer['namespace'] in ['magi-hub', 'magi-launcher', 'magi-emoji', 'magi-notification-centre']]
    assert len(utility) == 1 and utility[0]['namespace'] == 'magi-hub', utility
    assert not any(c.get('title') == 'MAGI Clipboard' for c in hypr('clients'))
    return utility[0]['address']


def key(name, require_search=True, mods=""):
    assert state('hubWindow')['visible'] and (not require_search or state('hubWindow')['focused'])
    subprocess.run(['hyprctl', 'dispatch', f'hl.dsp.send_shortcut({{mods = "{mods}", key = "{name}"}})'], check=True, stdout=subprocess.DEVNULL, timeout=5)
    time.sleep(.12)


try:
    assert not state('hub')['opened'], 'Close Hub before running this fixture'
    reservation()
    previous = hypr('activewindow').get('address')
    backend = state('notifications')['activated']
    capture = state('clipboard')['monitoring']
    call('launcher', 'toggle'); settle()
    identity = host()
    for target, mode in [('launcher', 'apps'), ('notifications', 'notifications'), ('emoji', 'emoji'), ('clipboard', 'clipboard')]:
        if mode != 'apps': call(target, 'toggle'); settle()
        assert state('hub')['mode'] == mode and state('hubWindow')['focused'], (mode, state('hubWindow'))
        assert host() == identity, 'Mode switch replaced native window'
        reservation()
        if mode == 'emoji':
            for letter in 'fire': key(letter)
            assert 0 < state('emoji')['count'] < 3944
        if mode == 'apps':
            for letter in 'zzzznomatch': key(letter)
            assert state('launcher')['count'] == 0
    # F6, Tab and Space exercise actual keyboard reachability of the selector.
    key('F6'); key('Tab', False, 'SHIFT'); key('space', False); settle()
    assert state('hub')['mode'] != 'clipboard', 'Selector keyboard activation failed'
    call('clipboard', 'toggle'); settle()
    call('clipboard', 'toggle'); settle()
    assert not state('hubWindow')['visible']
    assert hypr('activewindow').get('address') == previous, 'Focus restoration after mode switches'
    for mode, target in [('apps', 'launcher'), ('notifications', 'notifications'), ('emoji', 'emoji'), ('clipboard', 'clipboard')]:
        call(target, 'toggle'); settle()
        assert state('hub')['mode'] == mode and state('hubWindow')['focused']
        key('Escape'); settle()
        assert not state('hub')['opened']
        assert hypr('activewindow').get('address') == previous
    for view in ['controlcentre', 'calendar']:
        assert call('magi', 'open', view) == 'true'; settle()
        call('emoji', 'open'); settle()
        assert state('magi')['active'] == '' and state('magi')['phase'] == 0
        assert state('hubWindow')['visible'] and state('hubWindow')['focused']
        host(); reservation()
        assert call('magi', 'open', view) == 'true'; settle()
        assert not state('hubWindow')['visible'] and state('magi')['active'] == view
        call('magi', 'close'); settle()
    assert state('notifications')['activated'] == backend
    assert state('clipboard')['monitoring'] == capture
    reservation()
    assert not subprocess.check_output(['hyprctl', 'configerrors'], text=True, timeout=5).strip()
    print('Live Hub PASS: same native window through four modes, search focus/typing, keyboard selector, toggles, Escape, previous-app focus, CC/Calendar handoffs, backend continuity, no duplicate hosts, exactly48px and config health')
finally:
    call('hub', 'close'); call('magi', 'close')
