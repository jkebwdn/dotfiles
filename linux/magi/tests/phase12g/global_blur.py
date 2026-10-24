"""Fake compositor tests for separately opted-in global blur amount."""
import sys,tempfile,unittest,copy
sys.dont_write_bytecode=True
from pathlib import Path
from unittest.mock import patch
sys.path.insert(0,str(Path(__file__).resolve().parents[2]/'.config/quickshell/magi/services'))
from global_blur import Store,Coordinator,Executor,normalize
class Fake:
 def __init__(self):self.state=dict(instance='one',generation='a',size=8);self.calls=[];self.fail=False;self.unavailable=False
 def read(self):
  if self.unavailable:raise RuntimeError('unavailable')
  return dict(self.state)
 def set(self,size,ctx):
  self.calls.append(size);self.state['size']=size
  if self.fail:self.fail=False;raise RuntimeError('partial apply')
class Tests(unittest.TestCase):
 def setUp(self):
  self.tmp=tempfile.TemporaryDirectory();self.store=Store(self.tmp.name);self.e=Fake();self.c=Coordinator(self.store,self.e)
 def tearDown(self):self.tmp.cleanup()
 def apply(self,managed=True,size=12):return self.c.apply(dict(managed=managed,size=size))
 def test_bounds(self):
  for size in [1,8,40]:self.assertEqual(normalize(dict(size=size))['size'],size)
  for size in [0,41,1.5,True,'8']:
   with self.assertRaises(ValueError):normalize(dict(size=size))
 def test_off_no_ipc(self):
  self.e.unavailable=True;self.assertTrue(self.apply(False)['ok']);self.assertEqual(self.e.calls,[])
 def test_update_restart_release(self):
  self.e.state['size']=11;self.apply();self.apply(size=20)
  self.c=Coordinator(self.store,self.e);self.apply(size=20)
  self.assertEqual(self.e.calls,[12,20]);self.assertEqual(self.store.load()['baseline'],11)
  self.assertTrue(self.apply(False)['ok']);self.assertEqual(self.e.state['size'],11);self.assertEqual(self.store.load(),{})
 def test_reload_new_baseline_once(self):
  self.apply();self.e.state.update(generation='b',size=6);self.apply();self.apply()
  self.assertEqual(self.e.calls,[12,12]);self.apply(False);self.assertEqual(self.e.state['size'],6)
 def test_new_session_disabled(self):
  self.apply();self.e.state.update(instance='two',size=5);self.apply(False);self.assertEqual(self.e.state['size'],5)
 def test_partial_apply_and_release_rollback(self):
  self.e.fail=True;self.assertFalse(self.apply()['ok']);self.assertEqual(self.e.state['size'],8);self.assertEqual(self.store.load(),{})
  self.apply();self.e.fail=True;self.assertFalse(self.apply(False)['ok']);self.assertEqual(self.e.state['size'],12);self.assertEqual(self.store.load()['baseline'],8)
 def test_crash_recovery(self):
  before=self.e.read();self.store.save(dict(pending=dict(runtime=before,ownership={})));self.e.state['size']=18
  self.apply(False);self.assertEqual(self.e.state['size'],8)
 def test_readback_mismatch(self):
  with patch.object(self.e,'set',lambda size,ctx:None):self.assertFalse(self.apply()['ok'])
  self.assertEqual(self.store.load(),{})
 def test_rollback_failure_retains_journal(self):
  with patch.object(self.e,'set',side_effect=RuntimeError('failed')):
   result=self.apply();self.assertIn('rollback failed',result['error']);self.assertIn('pending',self.store.load())
 def test_publication_failure_precedes_mutation(self):
  with patch.object(self.store,'save',side_effect=OSError('disk full')):self.assertFalse(self.apply()['ok'])
  # rollback may attempt the original value, never the candidate
  self.assertNotIn(12,self.e.calls)
 def test_exact_api_and_boundary(self):
  e=Executor();ctx=dict(instance=e.instance,generation='a',size=8)
  with patch.object(e,'call',return_value='ok') as call,patch.object(e,'read',return_value={**ctx,'size':12}):
   e.set(12,ctx);code=call.call_args.args[-1];self.assertIn('hl.config({decoration={blur={size=12}}})',code)
   for forbidden in ['passes','active_opacity','inactive_opacity','window_rule','layer_rule','reload','keyword']:self.assertNotIn(forbidden,code)
if __name__=='__main__':unittest.main()
