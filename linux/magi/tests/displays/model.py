#!/usr/bin/env python3
from pathlib import Path
import sys,json,tempfile,unittest,time,subprocess,os
sys.dont_write_bytecode=True
ROOT=Path(__file__).resolve().parents[2];sys.path.insert(0,str(ROOT/'.config/quickshell/magi/displays'))
# This test filename is deliberately loaded as __main__, leaving model import unambiguous.
from model import *
from profiles import Store,create,check,preview,choose,import_hyprmon
from planner import plan,HyprlandBackend
from transaction import Transaction
from backend import Session,FIXTURES
class Tests(unittest.TestCase):
 def setUp(self):
  self.tmp=tempfile.TemporaryDirectory();self.path=Path(self.tmp.name);self.dual=clone(FIXTURES['Dual'])
 def tearDown(self):self.tmp.cleanup()
 def tx(self):
  t=Transaction(self.path/'tx');t.initialize(FIXTURES['Laptop']);return t
 def test_fixtures(self):
  for f in FIXTURES.values():validate(f)
  self.assertEqual(geometry(self.dual[0]),(1920,1080));self.assertEqual(geometry(self.dual[1]),(2560,1440))
  self.assertEqual(geometry(FIXTURES['Portrait'][1]),(1440,2560))
 def test_position_snapping_negative_and_cancel(self):
  d=moved(self.dual,'HDMI-A-1',1930,0);self.assertEqual(d[1]['x'],1920)
  for direction,pos in [('left',(-2560,0)),('right',(1920,0)),('above',(0,-1440)),('below',(0,1080))]:
   d=adjacent(self.dual,'HDMI-A-1','eDP-1',direction);self.assertEqual((d[1]['x'],d[1]['y']),pos)
  for _ in range(100):d=moved(d,'HDMI-A-1',d[1]['x'],d[1]['y'])
  self.assertEqual(d[1]['y'],1080)
  with self.assertRaises(Invalid):moved(self.dual,'HDMI-A-1',100,100)
 def test_validation(self):
  for key,value in [('x',float('nan')),('scale',0),('transform',8),('mode','4x4@60'),('name','x";os.execute("bad")')]:
   d=clone(self.dual);d[0][key]=value
   with self.assertRaises(Invalid):validate(d)
  for o in self.dual:o['enabled']=False
  with self.assertRaises(Invalid):validate(self.dual)
 def test_mirror(self):
  d=clone(FIXTURES['Mirror']);validate(d)
  d[0]['mirror']='HDMI-A-1'
  with self.assertRaises(Invalid):validate(d)
  d=clone(FIXTURES['Mirror']);d[0]['enabled']=False
  with self.assertRaises(Invalid):validate(d)
 def test_disable_selection(self):
  s=Session(self.path/'p',self.path/'t');s.request({'op':'edit','key':'enabled','value':False})
  self.assertEqual(s.selected,'HDMI-A-1');self.assertFalse(s.proposed[0]['enabled'])
  s.request({'op':'edit','key':'enabled','value':False});self.assertTrue(s.proposed[1]['enabled']);self.assertIn('at least one',s.error)
 def test_discovery_real_modes(self):
  rows=[dict(name='eDP-1',width=3840,height=2160,refreshRate=60,scale=2,availableModes=['3840x2160@60.00Hz','3840x2160@120.00Hz'],disabled=False)]
  d=discover(rows);validate(d);self.assertEqual(len(d[0]['modes']),2);self.assertEqual(d[0]['mode'],'3840x2160@60')
 def test_planner_exact_and_gated(self):
  args=plan(FIXTURES['Mirror']);self.assertEqual(args[:2],['/usr/bin/hyprctl','eval'])
  self.assertIn('output = "eDP-1", disabled = false, mode = "3840x2160@60", position = "0x0", scale = 2, transform = 0, mirror = ""',args[2])
  self.assertIn('mirror = "eDP-1"',args[2]);self.assertEqual(args[2].count('hl.monitor'),2)
  with self.assertRaises(Invalid):HyprlandBackend().apply(args)
 def test_hotplug_and_port_identity(self):
  draft=adjacent(self.dual,'HDMI-A-1','eDP-1','left');new=clone(self.dual);new[1]['name']='DP-9'
  d,w=reconcile(self.dual,draft,new);self.assertEqual(d[1]['x'],-2560);self.assertEqual(d[1]['name'],'DP-9')
  s=Session(self.path/'p',self.path/'t');s.proposed=draft;s.hotplug(FIXTURES['Laptop']);self.assertEqual(len(s.proposed),1)
  s.hotplug(new);self.assertEqual(len(s.proposed),2)
 def test_mirror_removal(self):
  d,w=reconcile(FIXTURES['Mirror'],FIXTURES['Mirror'],[self.dual[1]])
  self.assertEqual(d[0]['mirror'],'');self.assertTrue(w)
 def test_profiles_roundtrip_rename_delete(self):
  store=Store(self.path/'profiles');p=create('Office',self.dual);store.save(p);before=store.path(p['id']).read_bytes();store.save(p);self.assertEqual(before,store.path(p['id']).read_bytes())
  store.rename(p['id'],'Desk');self.assertEqual(store.load(p['id'])['name'],'Desk');store.delete(p['id']);self.assertEqual(store.list(),([],[]))
  with self.assertRaises(Invalid):store.path('../../bad')
 def test_profile_validation(self):
  p=create('Office',self.dual)
  for key,value in [('version',99),('name',''),('outputs',[]),('id','../../x')]:
   bad=clone(p);bad[key]=value
   with self.assertRaises(Invalid):check(bad)
  bad=clone(p);bad['outputs'][1].update(make=bad['outputs'][0]['make'],model=bad['outputs'][0]['model'],serial=bad['outputs'][0]['serial'])
  with self.assertRaises(Invalid):check(bad)
  store=Store(self.path);(self.path/('a'*32+'.json')).write_text('{');self.assertEqual(len(store.list()[1]),1)
 def test_profile_missing_mode_and_ambiguity(self):
  p=create('Office',self.dual);new=clone(self.dual);new[1]['modes']=new[1]['modes'][:1];new[1]['mode']='3840x2160@60'
  result=preview(p,new);self.assertEqual(result['status'],'degraded');self.assertTrue(result['warnings']);self.assertFalse(result['autoApply'])
  self.assertEqual(preview(p,FIXTURES['Laptop'])['status'],'missing')
  p2=create('Other',self.dual);self.assertEqual(len(choose([p,p2],self.dual)['candidates']),2);self.assertEqual(choose([p,p2],self.dual)['decision'],'ask')
 def test_import_real_profiles_no_write(self):
  for path in Path(__file__).with_name('fixtures').glob('hyprmon-*.json'):
   before=path.read_bytes();report=import_hyprmon(json.loads(before));self.assertFalse(report['written']);self.assertEqual(before,path.read_bytes())
   if 'Home-Office' in path.name:self.assertTrue(report['warnings']);self.assertFalse(report['outputs'][0]['enabled'])
 def test_three_outputs_negative_position(self):
  d=adjacent(FIXTURES['Three'],'DP-1','eDP-1','above');validate(d);self.assertLess(d[2]['y'],0)
 def test_hotplug_during_confirmation_reverts(self):
  session=Session(self.path/'p',self.path/'t');session.request({'op':'apply'})
  session.request({'op':'fixture','name':'Laptop'})
  self.assertEqual(session.tx.status()['state'],'reverted');self.assertEqual(len(session.observed),1)
 def test_disappeared_mode_requires_review(self):
  new=clone(self.dual);new[1]['modes']=new[1]['modes'][:1];new[1]['mode']='3840x2160@60'
  d,w=reconcile(self.dual,self.dual,new);self.assertTrue(w);self.assertEqual(d[1]['mode'],'3840x2160@60')
 def test_duplicate_identity_and_filename_mismatch(self):
  p=create('Office',self.dual);current=clone(self.dual);current[1].update(make=current[0]['make'],model=current[0]['model'],serial=current[0]['serial'])
  self.assertEqual(preview(p,current)['status'],'ambiguous')
  store=Store(self.path);store.save(p);other='f'*32;store.path(other).write_text(store.path(p['id']).read_text())
  with self.assertRaises(Invalid):store.load(other)
 def test_transaction_keep_timeout_manual(self):
  for action in ['keep','timeout','revert']:
   path=self.path/action;t=Transaction(path);t.initialize(FIXTURES['Laptop']);token=t.apply(self.dual,spawn=False,now=100)
   if action=='timeout':t.expire(now=116)
   else:t.finish(token,keep=action=='keep',now=101)
   self.assertEqual(t.read('backend'),self.dual if action=='keep' else FIXTURES['Laptop'])
   with self.assertRaises(Invalid):t.finish(token,keep=True)
 def test_apply_failure_and_revert_failure(self):
  t=self.tx()
  with self.assertRaises(Invalid):t.apply(self.dual,fail=True)
  self.assertEqual(t.read('backend'),FIXTURES['Laptop'])
  token=t.apply(self.dual,spawn=False);t.finish(token,revert_failure=True);self.assertEqual(t.status()['state'],'recovery-required')
  with self.assertRaises(Invalid):t.apply(self.dual)
 def test_watchdog_survives_host_death(self):
  t=self.tx();code='from transaction import Transaction;import json,sys,time; t=Transaction(sys.argv[1]);t.apply(json.loads(sys.argv[2]),timeout=.5);print("armed",flush=True);time.sleep(20)'
  env=dict(os.environ,PYTHONDONTWRITEBYTECODE='1',PYTHONPATH=str(ROOT/'.config/quickshell/magi/displays'))
  p=subprocess.Popen([sys.executable,'-c',code,str(t.directory),json.dumps(self.dual)],env=env,stdout=subprocess.PIPE,text=True)
  self.assertEqual(p.stdout.readline().strip(),'armed');p.kill();p.wait();p.stdout.close()
  deadline=time.monotonic()+4
  while t.read('transaction')['state']=='pending' and time.monotonic()<deadline:time.sleep(.05)
  self.assertEqual(t.read('transaction')['state'],'reverted');self.assertEqual(t.read('backend'),FIXTURES['Laptop'])
 def test_session_cancel_and_stale_keep(self):
  s=Session(self.path/'p',self.path/'t');s.request({'op':'move','name':'HDMI-A-1','x':-2560,'y':0});self.assertNotEqual(s.proposed,s.observed)
  s.request({'op':'reset'});self.assertEqual(s.proposed,s.observed)
  s.request({'op':'apply'});token=s.tx.status()['token'];s.request({'op':'keep','token':'bad'});self.assertTrue(s.error)
  s.request({'op':'revert','token':token});self.assertEqual(s.tx.status()['state'],'reverted')
if __name__=='__main__':unittest.main()
