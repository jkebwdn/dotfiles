"""Execute the real request script with only systemctl replaced by an offline fake."""
import importlib.util
import json
import os
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]
spec = importlib.util.spec_from_file_location("config", ROOT / "integration/handoff_config.py")
config = importlib.util.module_from_spec(spec)
spec.loader.exec_module(config)


class Request(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.state = self.root / "state.json"
        self.state.write_text('{}')
        fake = self.root / "systemctl"
        fake.write_text(f'#!{sys.executable}\n' + '''import os,json,sys
from pathlib import Path
p=Path(os.environ['FAKE_STATE']);states=json.loads(p.read_text())
args=sys.argv[1:]
with p.with_suffix('.calls').open('a') as f:f.write(json.dumps(args)+'\\n')
if 'show-environment' in args:
 print('WAYLAND_DISPLAY='+os.environ.get('FAKE_DISPLAY','wayland-test'))
 print('XDG_RUNTIME_DIR='+os.environ['XDG_RUNTIME_DIR'])
 sys.exit(int(os.environ.get('FAKE_BUS_ERROR','0')))
unit=next(a for a in args if a.endswith('.service'))
if 'show' in args:print(states.get(unit,'inactive'))
elif 'start' in args:
 states[unit]='activating';p.write_text(json.dumps(states))
else:sys.exit(99)
''')
        fake.chmod(0o700)
        self.script = self.root / "request"
        self.script.write_text((ROOT / "integration/magi-lock-request").read_text().replace('/usr/bin/systemctl', str(fake)))
        self.env = dict(os.environ, FAKE_STATE=str(self.state), WAYLAND_DISPLAY='wayland-test', XDG_RUNTIME_DIR=str(self.root))

    def invoke(self, *args):
        return subprocess.run(['/bin/sh', str(self.script), *args], env=self.env, capture_output=True, timeout=3)

    def calls(self):
        p = self.state.with_suffix('.calls')
        return [json.loads(x) for x in p.read_text().splitlines()] if p.exists() else []

    def test_manual(self):
        self.assertEqual(self.invoke('lock').returncode, 0)
        self.assertEqual(self.calls()[-1], ['--user', 'start', 'magi-lock@native.service'])

    def test_default_manual(self):
        self.assertEqual(self.invoke().returncode, 0)
        self.assertIn('magi-lock@native.service', self.calls()[-1])

    def test_coordinated(self):
        self.assertEqual(self.invoke('sleep-coordinated').returncode, 0)
        self.assertIn('magi-lock@hypridle.service', self.calls()[-1])

    def test_repeated_requests_reuse_activation(self):
        self.invoke('sleep-coordinated')
        self.invoke('lock')
        self.invoke('sleep-coordinated')
        self.assertEqual(set(json.loads(self.state.read_text())), {'magi-lock@hypridle.service'})

    def test_existing_native_is_not_replaced(self):
        self.state.write_text(json.dumps({'magi-lock@native.service': 'active'}))
        self.invoke('sleep-coordinated')
        self.assertIn('magi-lock@native.service', self.calls()[-1])

    def test_no_public_unlock_or_unit_injection(self):
        for args in [('unlock',), ('stop',), ('native',), ('sleep-coordinated', 'extra'), ('x;false',)]:
            with self.subTest(args=args):
                self.assertEqual(self.invoke(*args).returncode, 64)
        self.assertEqual(self.calls(), [])

    def test_config_chain(self):
        original = '''general {
    lock_cmd = pidof hyprlock || hyprlock
    before_sleep_cmd = loginctl lock-session
    after_sleep_cmd = hyprctl dispatch dpms on
}
listener {
    timeout = 600
    on-timeout = hyprctl dispatch dpms off
}
'''
        result = config.render(original, str(self.script))
        self.assertIn('inhibit_sleep = 3', result)
        command = next(x.split('=', 1)[1].strip() for x in result.splitlines() if 'lock_cmd =' in x)
        self.assertEqual(subprocess.run(['/bin/sh', *command.split()], env=self.env, capture_output=True, timeout=3).returncode, 0)
        self.assertIn('magi-lock@hypridle.service', self.calls()[-1])
        self.assertEqual(result.replace('    inhibit_sleep = 3\n', '').replace(str(self.script) + ' sleep-coordinated', 'pidof hyprlock || hyprlock'), original)

    def test_template_single_implementation(self):
        unit = (ROOT / 'integration/magi-lock@.service').read_text()
        self.assertIn('Type=notify', unit)
        self.assertIn('--sleep-coordinator=%i', unit)
        self.assertIn('Restart=no', unit)
        self.assertNotIn('Conflicts=', unit)

    def test_missing_graphical_environment(self):
        self.env.pop('WAYLAND_DISPLAY')
        self.assertEqual(self.invoke('lock').returncode, 78)
        self.assertEqual(self.calls(), [])

    def test_wrong_session_never_starts(self):
        self.env['FAKE_DISPLAY'] = 'other-session'
        self.assertEqual(self.invoke('lock').returncode, 78)
        self.assertFalse(any('start' in c for c in self.calls()))

    def test_manager_failure_never_starts(self):
        self.env['FAKE_BUS_ERROR'] = '1'
        self.assertEqual(self.invoke('lock').returncode, 69)
        self.assertFalse(any('start' in c for c in self.calls()))

    def test_deactivating_owner_not_replaced(self):
        self.state.write_text(json.dumps({'magi-lock@native.service': 'deactivating'}))
        self.assertEqual(self.invoke('lock').returncode, 69)
        self.assertFalse(any('start' in c for c in self.calls()))


if __name__ == '__main__':
    unittest.main()
