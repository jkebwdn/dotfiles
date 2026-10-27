#!/usr/bin/env python3
"""Deterministic device/agent fixtures exercising production coordinator."""
from pathlib import Path
import sys
import unittest
sys.path.insert(0, str(Path(__file__).resolve().parents[2]/'.config/quickshell/magi/services'))
from bluetooth_actions import Actions

A='/org/bluez/hci0/dev_11_22_33_44_55_66'
B='/org/bluez/hci0/dev_11_22_33_44_55_77'

class Fake:
    def __init__(self):
        self.calls=[]; self.pending=[]
    def read(self, path, cb): self.calls.append(('read',path)); self.pending.append(cb)
    def register(self, cb): self.calls.append(('agent',)); self.pending.append(cb)
    def call(self, path, method, cb): self.calls.append((method,path)); self.pending.append(cb)
    def trust(self, path, cb): self.calls.append(('trust',path)); self.pending.append(cb)
    def cancel_connect(self, path): self.calls.append(('cancel-connect',path))
    def cancel_pair(self, path): self.calls.append(('cancel',path))
    def reply(self, *args): self.pending.pop(0)(*args)

class Tests(unittest.TestCase):
    def setUp(self):
        self.bus=Fake(); self.events=[]; self.a=Actions(self.bus,self.events.append)
    def select(self, **props):
        self.a.start(A); self.bus.reply(dict(Powered=True,Name='Headphones',**props),None)
    def pairing(self):
        self.select(); self.bus.reply(None)
    def after_pair(self, connected=False):
        self.bus.reply(None); self.bus.reply(None)
        self.bus.reply({'Powered':True,'Paired':True,'Connected':connected},None)
    def test_new_device_once(self):
        self.pairing()
        for _ in range(10): self.a.start(A)
        self.a.start(B)  # Same display name is irrelevant; second intent cannot retarget.
        self.after_pair(); self.bus.reply(None)
        self.assertEqual(self.bus.calls,[('read',A),('agent',),('Pair',A),('trust',A),('read',A),('Connect',A)])
        self.assertIsNone(self.a.operation)
    def test_pair_already_connected(self):
        self.pairing(); self.after_pair(True)
        self.assertNotIn(('Connect',A),self.bus.calls)
    def test_pair_failure_does_not_trust(self):
        for error in ('AuthenticationRejected','AuthenticationTimeout','AuthenticationCanceled','Failed','InProgress'):
            self.setUp(); self.pairing(); self.bus.reply('org.bluez.Error.'+error)
            self.assertIsNone(self.a.operation)
            self.assertTrue(self.events[-1]['error'])
            self.assertNotIn(('trust',A),self.bus.calls)
    def test_connection_failure_retains_pairing(self):
        self.pairing(); self.after_pair(); self.bus.reply('org.bluez.Error.Failed')
        self.assertIn('Connection failed',self.events[-1]['error'])
        self.assertFalse(any(c[0]=='RemoveDevice' for c in self.bus.calls))
        self.select(Paired=True); self.assertEqual(self.bus.calls[-1],('Connect',A))
    def test_known_device_and_disconnect(self):
        for props,method in [({'Paired':True},'Connect'),({'Bonded':True},'Connect'),({'Connected':True},'Disconnect')]:
            self.setUp(); self.select(**props); self.a.start(A)
            self.assertEqual(self.bus.calls,[('read',A),(method,A)])
            self.bus.reply(None); self.assertIsNone(self.a.operation)
    def test_forget_then_select_pairs(self):
        self.select(Paired=True); self.bus.reply(None)
        self.select(Paired=False,Bonded=False,Connected=False); self.bus.reply(None)
        self.assertEqual(self.bus.calls[-1],('Pair',A))
    def test_disappearance_and_adapter_off(self):
        for path in [A,'/org/bluez/hci0']:
            self.setUp(); self.pairing(); self.a.unavailable(path)
            self.assertEqual(self.bus.calls[-1],('cancel',A))
            self.bus.reply(None)  # Stale Pair completion must not trust/connect.
            self.assertNotIn(('trust',A),self.bus.calls)
            self.assertIn('unavailable',self.events[-1]['error'])
    def test_off_before_start(self):
        self.a.start(A); self.bus.reply({'Powered':False},None)
        self.assertEqual(self.bus.calls,[('read',A)])
    def test_cancel_during_agent_registration(self):
        self.select(); self.a.cancel(); self.bus.reply(None)
        self.assertNotIn(('Pair',A),self.bus.calls)
    def test_authentication(self):
        for kind,value,expected in [('confirm','', ''),('pin','0000','0000'),('passkey','000123',123),('authorize','',''),('service','','')]:
            self.setUp(); self.pairing(); replies=[]
            self.a.challenge(A,kind,'000123',lambda *args:replies.append(args))
            self.a.answer(self.a.prompt['id'],True,value)
            self.assertEqual(replies,[(expected,None)])
    def test_reject_and_stale_answer(self):
        self.pairing(); replies=[]
        self.a.challenge(A,'confirm','123456',lambda *args:replies.append(args))
        self.a.answer(999,True); self.assertEqual(replies,[])
        self.a.answer(self.a.prompt['id'],False)
        self.assertEqual(replies,[('', 'org.bluez.Error.Rejected')])
        self.assertIsNone(self.a.prompt)
        self.assertIn(('cancel',A),self.bus.calls)
    def test_invalid_values_not_submitted(self):
        self.pairing(); replies=[]
        self.a.challenge(A,'passkey','',lambda *args:replies.append(args))
        for value in ['','1234567','12a','-1','１２']:
            self.a.answer(self.a.prompt['id'],True,value)
        self.assertEqual(replies,[])
        self.a.cancel(); self.assertEqual(replies,[(None,'org.bluez.Error.Canceled')])
    def test_unrelated_requests_rejected(self):
        self.pairing(); replies=[]
        self.a.challenge(B,'confirm','123456',lambda *args:replies.append(args))
        self.assertEqual(replies,[(None,'org.bluez.Error.Rejected')])
    def test_display_and_cancel(self):
        self.pairing(); self.a.challenge(A,'displayPasskey','000012 · 2 digits entered')
        self.a.answer(self.a.prompt['id'],True)
        self.assertIsNotNone(self.a.prompt)
        self.a.cancel(); self.assertIsNone(self.a.prompt)
    def test_service_authorization_during_connection(self):
        self.select(Paired=True); replies=[]
        self.a.challenge(A,'service','uuid',lambda *args:replies.append(args))
        self.a.answer(self.a.prompt['id'],False)
        self.assertEqual(replies,[('', 'org.bluez.Error.Rejected')])
        self.assertIn(('cancel-connect',A),self.bus.calls)
    def test_invalid_identity(self):
        for path in ['Headphones','/org/bluez',None,'']: self.a.start(path)
        self.assertEqual(self.bus.calls,[])
    def test_registration_failure(self):
        self.select(); self.bus.reply('Denied')
        self.assertIn('agent unavailable',self.events[-1]['error'])

if __name__=='__main__': unittest.main()
