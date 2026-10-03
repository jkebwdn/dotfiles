#!/usr/bin/env python3
"""Non-destructive quick-action adapter checks."""
import importlib.util
import os
from pathlib import Path
import tempfile

root = Path(__file__).resolve().parents[2]
source = root / '.config/quickshell/magi/services/system_actions.py'
spec = importlib.util.spec_from_file_location('magi_actions', source)
actions = importlib.util.module_from_spec(spec)
spec.loader.exec_module(actions)

class Completed:
    def __init__(self, stdout='', stderr='', returncode=0):
        self.stdout, self.stderr, self.returncode = stdout, stderr, returncode

with tempfile.TemporaryDirectory(prefix='magi-actions-') as temporary:
    profile = Path(temporary) / 'platform_profile'
    choices = Path(temporary) / 'platform_profile_choices'
    profile.write_text('balanced')
    choices.write_text('low-power balanced performance')
    os.environ['MAGI_PLATFORM_PROFILE'] = str(profile)
    original_which = actions.shutil.which
    actions.shutil.which = lambda name: None if name == 'powerprofilesctl' else original_which(name)
    assert actions.power_status()['available']
    assert actions.power_set('low-power')['active'] and profile.read_text() == 'low-power'
    assert not actions.power_set('bogus')['ok']

    actions.shutil.which = lambda name: '/mock/' + name
    def fake_run(command):
        if command[-3:] == ['connection', 'show', '--active']:
            return Completed('22222222-2222-2222-2222-222222222222\n')
        if command[-2:] == ['connection', 'show']:
            return Completed('11111111-1111-1111-1111-111111111111:802-11-wireless:Wi-Fi\n'
                             '22222222-2222-2222-2222-222222222222:vpn:Work VPN\n')
        return Completed()
    actions.run = fake_run
    vpn = actions.vpn_profiles()
    assert vpn['available'] and vpn['active'] and vpn['name'] == 'Work VPN'
    assert actions.vpn_set(vpn['uuid'], False)['ok']

    actions.shutil.which = lambda name: None
    os.environ['MAGI_ACTION_DRY_RUN'] = '1'
    for name in ('lock', 'hibernate', 'shutdown'):
        checked = actions.execute_action(name)
        assert checked['ok'] and checked['dryRun']
    del os.environ['MAGI_ACTION_DRY_RUN']
    print('Power, VPN and dry-run destructive action boundaries PASS')
