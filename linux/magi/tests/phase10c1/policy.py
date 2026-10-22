#!/usr/bin/env python3
"""No live controller: only fake services and disconnected native parsing."""
from pathlib import Path
import importlib.util
import json
import os
import subprocess
import sys
import tempfile
import unittest
from unittest.mock import patch
ROOT = Path(__file__).resolve().parents[2]
CONFIG = ROOT/'.config/quickshell/magi'
sys.dont_write_bytecode = True
sys.path.insert(0,str(CONFIG/'settings'))
import power_idle as idle
import persist

class FakeService:
    def __init__(self): self.calls=[]; self.failures=0; self.duplicate=False; self.available=True
    def safe_to_restart(self): pass
    def restart(self):
        self.calls.append('restart')
        if self.failures:
            self.failures-=1
            raise RuntimeError('restart failed')
    def verify(self):
        self.calls.append('verify')
        if not self.available: raise RuntimeError('no hypridle')
        if self.duplicate: raise RuntimeError('two hypridle processes')

class PolicyTests(unittest.TestCase):
    def setUp(self):
        self.temp=tempfile.TemporaryDirectory(); self.directory=Path(self.temp.name)
        self.service=FakeService(); self.validations=[]
        self.manager=idle.Manager(self.directory/'policy',self.service,self.validations.append)
        self.old={'powerIdle':dict(idle.DEFAULT)}
        self.new={'powerIdle':dict(lockAfter=60,displayOffAfter=300,suspendAfter=900)}
        self.manager.prepare(idle.DEFAULT); self.manager.enroll(idle.DEFAULT);self.service.calls=[]
    def tearDown(self):self.temp.cleanup()
    def test_matrix_and_native_parser(self):
        for policy in [idle.DEFAULT,dict(lockAfter=0,displayOffAfter=0,suspendAfter=0),
                       dict(lockAfter=300,displayOffAfter=0,suspendAfter=0),
                       self.new['powerIdle'],dict(lockAfter=300,displayOffAfter=0,suspendAfter=1800),
                       dict(lockAfter=0,displayOffAfter=600,suspendAfter=1800)]:
            text=idle.render(policy)
            self.assertEqual(text,idle.render(policy));self.assertEqual(idle.parse_generated(text),policy)
            self.assertEqual(text.count('listener {'),sum(bool(v) for v in policy.values()))
            self.assertIn('lock_cmd = /usr/bin/magi-lock-request sleep-coordinated',text)
            self.assertIn('inhibit_sleep = 3',text);self.assertIn('before_sleep_cmd = /usr/bin/loginctl lock-session',text)
            self.assertIn('after_sleep_cmd = '+idle.WAKE,text)
            self.assertEqual('on-resume = '+idle.WAKE in text,bool(policy['displayOffAfter']))
            self.assertNotIn('ignore_inhibit',text);self.assertNotIn('ignore_wayland_inhibit',text)
            idle.validate_native(text)
    def test_invalid_and_contract_tampering(self):
        for policy in [dict(lockAfter=600,displayOffAfter=300),dict(lockAfter=600,suspendAfter=300),
                       dict(lockAfter=True),dict(lockAfter=-1),dict(suspendAfter=60),dict(displayOffAfter='600')]:
            with self.assertRaises(idle.PolicyError):idle.policy({'powerIdle':policy})
        for text in [idle.render(idle.DEFAULT).replace('inhibit_sleep = 3','inhibit_sleep = 0'),
                     idle.render(idle.DEFAULT).replace('before_sleep_cmd', 'other_cmd'),
                     idle.render(idle.DEFAULT)+'listener {\n    timeout = 300\n    on-timeout = '+idle.LOCK+'\n}\n']:
            with self.assertRaises(idle.PolicyError):idle.validate_native(text)
    def test_success_settings_last(self):
        writes=[]
        def save():
            self.assertEqual(self.service.calls,['verify','restart','verify'])
            self.assertEqual(self.manager.active.read_text(),idle.render(self.new['powerIdle']));writes.append(True)
        self.manager.change(self.old,self.new,save)
        self.assertEqual(writes,[True]);self.assertFalse(self.manager.pending.exists())
    def test_explicit_unchanged_apply_restarts(self):
        writes=[]
        self.manager.change(self.old,self.old,lambda:writes.append(True),force=True)
        self.assertEqual(writes,[True]);self.assertEqual(self.service.calls,['verify','restart','verify'])
    def test_caffeine_blocks_persistence_and_same_policy_apply(self):
        path=self.directory/'settings.json';before=json.dumps(self.old);path.write_text(before)
        with patch.dict(os.environ,{'XDG_STATE_HOME':str(self.directory/'state')}),patch.object(persist,'Manager',lambda:self.manager):
            for following,force in [(self.new,False),(self.old,True)]:
                with self.assertRaisesRegex(idle.PolicyError,'idle inhibition is active'):
                    persist.perform(dict(op='write',path=str(path),expected=before,text=json.dumps(following),idleInhibited=True,applyIdle=force))
        self.assertEqual(path.read_text(),before);self.assertEqual(self.service.calls,[])
    def test_validation_failure_preserves(self):
        def fail(_): raise idle.PolicyError('invalid')
        self.manager.validator=fail
        with self.assertRaises(idle.PolicyError):self.manager.change(self.old,self.new,lambda:self.fail('saved'))
        self.assertEqual(self.service.calls,[]);self.assertEqual(self.manager.active.read_text(),idle.render(idle.DEFAULT))
    def test_restart_failure_rolls_back(self):
        self.service.failures=1
        with self.assertRaisesRegex(idle.PolicyError,'previous policy remains active'):
            self.manager.change(self.old,self.new,lambda:self.fail('saved'))
        self.assertEqual(self.service.calls,['verify','restart','restart','verify'])
        self.assertEqual(self.manager.active.read_text(),idle.render(idle.DEFAULT))
    def test_failed_health_rolls_back(self):
        n=0
        def verify():
            nonlocal n;n+=1
            if n==2:raise RuntimeError('not healthy')
        self.service.verify=verify
        with self.assertRaisesRegex(idle.PolicyError,'previous policy remains active'):
            self.manager.change(self.old,self.new,lambda:self.fail('saved'))
        self.assertEqual(n,3)
    def test_failed_save_rolls_back(self):
        def fail():raise OSError('disk full')
        with self.assertRaisesRegex(idle.PolicyError,'previous policy remains active'):
            self.manager.change(self.old,self.new,fail)
        self.assertEqual(self.manager.active.read_text(),idle.render(idle.DEFAULT))
    def test_rollback_failure_is_honest_and_recoverable(self):
        self.service.failures=2
        with self.assertRaisesRegex(idle.PolicyError,'recovery failed'):
            self.manager.change(self.old,self.new,lambda:None)
        self.assertTrue(self.manager.pending.exists())
        self.manager.recover(idle.DEFAULT);self.assertFalse(self.manager.pending.exists())
    def test_duplicate_or_missing_preflight_does_not_touch_policy(self):
        for flag in ['duplicate','available']:
            self.service.duplicate=flag=='duplicate';self.service.available=flag!='available'
            with self.assertRaises(RuntimeError):self.manager.change(self.old,self.new,lambda:self.fail('saved'))
            self.assertNotIn('restart',self.service.calls)
            self.assertEqual(self.manager.active.read_text(),idle.render(idle.DEFAULT))
    def test_inhibited_change_never_restarts(self):
        def blocked():raise idle.PolicyError("Power policy can't be changed while idle inhibition is active.")
        self.service.safe_to_restart=blocked
        with self.assertRaisesRegex(idle.PolicyError,'idle inhibition is active'):
            self.manager.change(self.old,self.new,lambda:self.fail('saved'))
        self.assertNotIn('restart',self.service.calls)
        self.assertFalse(self.manager.pending.exists())
        self.assertEqual(self.manager.active.read_text(),idle.render(idle.DEFAULT))
    def test_real_controller_preflight_guards(self):
        controller=idle.ServiceController(self.manager.active)
        def command(*args):
            if args[0].endswith('hyprctl'):return '[{"inhibitingIdle":false}]'
            if args[0].endswith('systemctl'):return 'a'*32
            if args[0].endswith('journalctl'):return 'Inhibit locks: 1\n'
            return 'b false'
        controller.command=command
        with self.assertRaisesRegex(idle.PolicyError,'idle inhibition is active'):controller.safe_to_restart()
        controller.command=lambda *args: '[{"inhibitingIdle":false}]' if args[0].endswith('hyprctl') else 'a'*32 if args[0].endswith('systemctl') else ('Inhibit locks: 1\nInhibit locks: 0\n' if args[0].endswith('journalctl') else 'b true')
        with self.assertRaisesRegex(idle.PolicyError,'sleep or resume'):controller.safe_to_restart()
        controller.command=lambda *args: '[{"inhibitingIdle":false}]' if args[0].endswith('hyprctl') else 'a'*32 if args[0].endswith('systemctl') else ('Inhibit locks: 0\n' if args[0].endswith('journalctl') else 'b false')
        controller.safe_to_restart()
        original=controller.command
        controller.command=lambda *args: '[{"inhibitingIdle":true}]' if args[0].endswith('hyprctl') else original(*args)
        with self.assertRaisesRegex(idle.PolicyError,'idle inhibition is active'):controller.safe_to_restart()
    def test_real_controller_readiness_and_all_never(self):
        controller=idle.ServiceController(self.manager.active)
        for zero in [False,True]:
            if zero:idle.atomic(self.manager.active,idle.render(dict.fromkeys(idle.DEFAULT,0)))
            def command(*args):
                if args[0].endswith('systemctl'):return 'ActiveState=active\nSubState=running\nMainPID=123\nInvocationID='+'a'*32
                if args[0].endswith('pgrep'):return '123\n'
                return ('[ERR] Config has errors:\nNo rules configured\nProceeding ignoring faulty entries\n' if zero else '')+'Sleep inhibition enabled - inhibiting until the wayland session gets locked\nInhibited sleep with fd 9\n'
            controller.command=command
            with patch.object(Path,'read_bytes',return_value=b'/usr/bin/hypridle\0--config\0'+os.fsencode(self.manager.active)+b'\0'),patch.object(idle.time,'sleep'):
                controller.verify_ready()
            original=controller.command
            controller.command=lambda *args: '123\n456\n' if args[0].endswith('pgrep') else original(*args)
            with self.assertRaisesRegex(idle.PolicyError,'exactly one'):controller.verify_ready()
    def test_not_enrolled_and_default_migration_inert(self):
        self.manager.marker.unlink()
        with self.assertRaisesRegex(idle.PolicyError,'not active yet'):
            self.manager.change(self.old,self.new,lambda:self.fail('saved'))
        calls=[];self.manager.change({'schemaVersion':14},{'schemaVersion':15,'powerIdle':idle.DEFAULT},lambda:calls.append(True))
        self.assertEqual(calls,[True]);self.assertEqual(self.service.calls,[])
    def test_persistence_integration(self):
        path=self.directory/'settings.json';before=json.dumps({'schemaVersion':14,'custom':{'kept':True}});path.write_text(before)
        after=json.dumps({'schemaVersion':15,'custom':{'kept':True},'powerIdle':self.new['powerIdle']})
        with patch.dict(os.environ,{'XDG_STATE_HOME':str(self.directory/'state')}),patch.object(persist,'Manager',lambda:self.manager):
            result=persist.perform(dict(op='write',path=str(path),expected=before,text=after))
        self.assertTrue(result['ok']);self.assertEqual(path.read_text(),after)
    def test_persistence_failure_no_settings_change(self):
        path=self.directory/'settings.json';before=json.dumps(self.old);path.write_text(before);self.service.failures=1
        with patch.dict(os.environ,{'XDG_STATE_HOME':str(self.directory/'state')}),patch.object(persist,'Manager',lambda:self.manager):
            with self.assertRaises(idle.PolicyError):persist.perform(dict(op='write',path=str(path),expected=before,text=json.dumps(self.new)))
        self.assertEqual(path.read_text(),before)
    def test_external_edit_during_activation_is_preserved(self):
        path=self.directory/'settings.json';before=json.dumps(self.old);path.write_text(before)
        external=json.dumps({'schemaVersion':15,'custom':'operator edit','powerIdle':idle.DEFAULT})
        def restart():self.service.calls.append('restart');path.write_text(external)
        self.service.restart=restart
        with patch.dict(os.environ,{'XDG_STATE_HOME':str(self.directory/'state')}),patch.object(persist,'Manager',lambda:self.manager):
            with self.assertRaisesRegex(idle.PolicyError,'previous policy remains active'):
                persist.perform(dict(op='write',path=str(path),expected=before,text=json.dumps(self.new)))
        self.assertEqual(path.read_text(),external)
        self.assertEqual(self.manager.active.read_text(),idle.render(idle.DEFAULT))
    def test_caffeine_and_manual_contract_unchanged(self):
        fleet=(CONFIG/'components/bar/BarFleet.qml').read_text()
        self.assertEqual(fleet.count('IdleInhibitor {'),1)
        self.assertIn('enabled: Services.Caffeine.requested && !!root.mainBar',fleet)
        for path in ['services/Caffeine.qml','services/system_actions.py']:
            baseline=subprocess.check_output(['git','show','HEAD:linux/magi/.config/quickshell/magi/'+path],cwd=ROOT)
            self.assertEqual((CONFIG/path).read_bytes(),baseline)
        canonical=(ROOT.parent/'t15g/hypr/.config/hypr/hypridle.conf').read_text()
        self.assertIn('inhibit_sleep = 3',canonical);self.assertIn('magi-lock-request sleep-coordinated',canonical)
        self.assertIn('before_sleep_cmd = loginctl lock-session',canonical)

if __name__=='__main__':unittest.main()
