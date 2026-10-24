#!/usr/bin/env python3
"""Offline application-alpha/blur tests. Never modifies a running application."""
import copy,json,os,subprocess,sys,tempfile,unittest
from pathlib import Path
from unittest.mock import patch
sys.dont_write_bytecode=True
ROOT=Path(__file__).resolve().parents[2]
SERVICES=ROOT/'.config/quickshell/magi/services';sys.path.insert(0,str(SERVICES))
from application_appearance.policy import DEFAULT,normalize
from application_appearance.planner import plan,toggle_lua
from application_appearance.registry import CAPABILITIES
from application_appearance.executor import BlurExecutor,BUILD,GenerationChanged
from application_appearance.coordinator import ApplicationAppearanceCoordinator,validate_ghostty
from theme_orchestrator.storage import Store
from theme_orchestrator.coordinator import Orchestrator
from theme_orchestrator.adapters import ADAPTERS
from theme_orchestrator.palette import resolve

class Blur:
 def __init__(self):self.state=dict(instance='test-instance',generation='one',enabled=False);self.calls=[];self.fail=False;self.offline=False;self.mismatch=False
 def read(self):
  if self.offline:raise RuntimeError('IPC unavailable')
  return dict(self.state)
 def set(self,value,ctx):
  if any(ctx[k]!=self.state[k] for k in ('instance','generation')):raise GenerationChanged('new generation')
  self.calls.append(value);self.state['enabled']=value
  if self.fail:self.fail=False;raise RuntimeError('partial toggle failure')
  if self.mismatch:self.mismatch=False;self.state['enabled']=not value
  return self.read()

class Policy(unittest.TestCase):
 def test_bounds(self):
  for a in [.5,.85,1]:self.assertEqual(normalize(dict(backgroundOpacity=a))['backgroundOpacity'],a)
  for a in [.49,1.01,True,None,float('nan'),'0.9']:
   with self.assertRaises(ValueError):normalize(dict(backgroundOpacity=a))
  for p in [{'activeOpacity':1},{'blurEnabled':0},{'managed':'yes'}]:
   with self.assertRaises(ValueError):normalize(p)
 def test_four_states(self):
  for alpha in [1,.8]:
   for blur in [True,False]:
    p=plan(dict(managed=True,backgroundOpacity=alpha,blurEnabled=blur))
    self.assertEqual(p['blurExcluded'],not blur)
    self.assertEqual(p['policy']['backgroundOpacity'],alpha)
  self.assertFalse(plan(DEFAULT)['blurExcluded'])
 def test_no_forbidden_production_operations(self):
  code='\n'.join(p.read_text() for p in (SERVICES/'application_appearance').glob('*.py'))
  for forbidden in ['active_opacity','inactive_opacity','fullscreen_opacity','hl.config','hl.window_rule','hl.layer_rule','decoration.blur.size','decoration.blur.passes',"'reload'",'setprop','namespace']:
   self.assertNotIn(forbidden,code)
  self.assertEqual((ROOT/'.config/quickshell/magi/shell.qml').read_text().count('Services.ApplicationAppearanceService.activate()'),1)
  self.assertFalse((SERVICES/'window_appearance').exists())
 def test_fixed_match_and_no_accumulation(self):
  hunk=Path(__file__).with_name('bootstrap.lua').read_text()
  self.assertEqual(hunk.count('hl.window_rule('),1);self.assertIn('^com\\\\.mitchellh\\\\.ghostty$',hunk)
  self.assertNotIn('class = ".*"',hunk);self.assertNotIn('hl.config',hunk)
  mock='''local count=0;local effect;hl={window_rule=function(r)count=count+1;effect=r;return{set_enabled=function(_,v)r.enabled=v end,is_enabled=function()return r.enabled end}end}\n'''
  test='''assert(count==1 and effect.enabled==false and effect.no_blur==true)
for i=1,200 do magi_application_background.rule:set_enabled(true);magi_application_background.rule:set_enabled(false) end
assert(count==1 and effect.enabled==false and effect.no_blur==true)
'''
  subprocess.run(['lua','-'],input=mock+hunk+test,text=True,check=True)
 def test_registry(self):
  self.assertEqual(len(CAPABILITIES),9)
  self.assertEqual([r['id'] for r in CAPABILITIES if r['support']=='reload-required'],['ghostty'])
  self.assertEqual(next(r for r in CAPABILITIES if r['id']=='gtk')['blur'],'deferred')
 def test_no_broad_gtk_transparency(self):
  import re
  output='\n'.join(ADAPTERS['gtk'].render(resolve('catppuccin-mocha'),None).values())
  self.assertIsNone(re.search(r'\*\s*\{[^}]*background(?:-color)?\s*:\s*(?:transparent|rgba)',output))
 def test_api_blank_errors_and_toggle(self):
  sig=BUILD+'_123_456';generation='12345678-1234-1234-1234-123456789abc';snapshot='\n'.join([sig,generation,'false'])
  with patch.dict(os.environ,HYPRLAND_INSTANCE_SIGNATURE=sig),patch.object(BlurExecutor,'call',side_effect=[BUILD,'[""]',snapshot]) as call:
   b=BlurExecutor();ctx=b.read();self.assertFalse(ctx['enabled']);self.assertIn('rule:is_enabled()',call.call_args.args[-1])
  self.assertEqual(toggle_lua(True),'magi_application_background.rule:set_enabled(true)')
  with patch.dict(os.environ,HYPRLAND_INSTANCE_SIGNATURE=sig),patch.object(BlurExecutor,'call',side_effect=[BUILD,'["real error"]']):
   with self.assertRaisesRegex(RuntimeError,'real error'):BlurExecutor().read()
 def test_generated_ghostty_validates(self):
  files=ADAPTERS['ghostty'].render(resolve('catppuccin-mocha'),None,dict(managed=True,backgroundOpacity=.85))
  validate_ghostty(files)
 def test_background_only_palette_invariance(self):
  adapter=ADAPTERS['ghostty']
  for theme in ['catppuccin-mocha','rose-pine-dawn','nord']:
   p=resolve(theme);base=adapter.render(p,None);managed=adapter.render(p,None,dict(managed=True,backgroundOpacity=.85))
   self.assertEqual(managed,adapter.render(p,None,dict(managed=True,backgroundOpacity=.85)))
   alpha_lines=[l for l in managed['colors.conf'].splitlines(True) if l.startswith('background-opacity')]
   self.assertEqual(''.join(l for l in managed['colors.conf'].splitlines(True) if not l.startswith(('background-opacity','gtk-custom-css'))),base['colors.conf'])
   self.assertEqual(alpha_lines,['background-opacity = 0.85\n','background-opacity-cells = false\n'])
   self.assertEqual(adapter.render(p,None,DEFAULT),base)
 def test_full_render_matrix(self):
  adapter=ADAPTERS['ghostty']
  for theme in ['catppuccin-mocha','rose-pine-dawn','nord']:
   palette=resolve(theme);base=adapter.render(palette,None)
   for alpha in [.5,.8,.95,1]:
    for managed in [False,True]:
     for blur in [False,True]:
      policy=dict(managed=managed,backgroundOpacity=alpha,blurEnabled=blur)
      files=adapter.render(palette,None,policy)
      self.assertEqual(files,adapter.render(palette,None,policy))
      validate_ghostty(files)
      if not managed:self.assertEqual(files,base)
      else:
       stripped=''.join(line for line in files['colors.conf'].splitlines(True) if not line.startswith(('background-opacity','gtk-custom-css')))
       self.assertEqual(stripped,base['colors.conf'])
 def test_shared_surface_boundaries(self):
  root=ROOT/'.config/quickshell/magi'
  theme=(root/'theme/Theme.qml').read_text()
  self.assertIn('Qt.alpha(base, transparency.backgroundOpacity)',theme)
  sites=['components/hub/HubSurface.qml','components/hub/HubSelector.qml','components/notifications/NotificationCard.qml','components/bar/SharedStatusSurface.qml','components/bar/menu/AnchoredPopupHost.qml','components/bar/menu/CombinedMenuHost.qml','plugins/bar/workspaces/Workspaces.qml']
  for site in sites:
   code=(root/site).read_text();self.assertIn('surfaceBackground(',code)
   self.assertNotRegex(code,r'(?m)^\s*opacity:.*(?:backgroundOpacity|transparency|applicationAppearance)')
  for site in ['components/bar/Bar.qml','components/hub/HubWindow.qml','components/notifications/ToastHost.qml','components/bar/menu/AnchoredPopupHost.qml']:
   code=(root/site).read_text();self.assertIn('BackgroundEffect.blurRegion:',code)
   self.assertNotIn('BackgroundEffect.blurRegion: mask',code)
  self.assertNotIn('hl.layer_rule', '\n'.join(p.read_text() for p in (root/'services/application_appearance').glob('*.py')))
  self.assertNotIn('passes=',(root/'services/global_blur.py').read_text())
 def test_ghostty_blur_request_scope_and_parser(self):
  import gi
  gi.require_version('Gtk','4.0')
  from gi.repository import Gtk
  adapter=ADAPTERS['ghostty'];palette=resolve('nord')
  on=adapter.render(palette,None,dict(managed=True,blurEnabled=True))
  off=adapter.render(palette,None,dict(managed=True,blurEnabled=False))
  self.assertEqual(on,off) # runtime rule, not stylesheet churn, toggles blur
  css=on['background-blur.css']
  self.assertIn('window.window { backdrop-filter: blur(20px); }',css)
  # GTK 4.24 BACKGROUND_BLUR_THRESHOLD: smaller valid CSS emits no region.
  import re
  self.assertGreaterEqual(float(re.search(r'blur\((\d+)px\)',css)[1]),20)
  for forbidden in ['background-color:', 'opacity:', '* {', 'color:']:
   self.assertNotIn(forbidden,css)
  provider=Gtk.CssProvider();errors=[]
  provider.connect('parsing-error',lambda p,s,e:errors.append(str(e)))
  provider.load_from_data(css.encode());self.assertEqual(errors,[])
  released=adapter.render(palette,None,DEFAULT)
  self.assertNotIn('background-blur.css',released)
  self.assertNotIn('gtk-custom-css',released['colors.conf'])

class Transactions(unittest.TestCase):
 def setUp(self):
  self.tmp=tempfile.TemporaryDirectory(prefix='magi-appearance-tests-');r=Path(self.tmp.name)
  self.store=Store(home=r,config=r/'config',data=r/'data',state=r/'state');self.orch=Orchestrator(self.store)
  self.orch.ready=lambda a:{};self.orch.check_hooks=lambda r:None
  self.palette=resolve('catppuccin-mocha');self.blur=Blur()
  self.state={'schemaVersion':1,'targets':{'ghostty':{'enabled':True,'edits':[]}}}
  self.store.save(self.state);files,digest=self.orch.render(ADAPTERS['ghostty'],self.palette);self.store.publish('ghostty',files,digest)
  self.service=ApplicationAppearanceCoordinator(self.orch,self.blur,lambda f:None)
  self.baseline=self.service.snapshot_files()
 def tearDown(self):self.tmp.cleanup()
 def apply(self,**kw):
  with self.store.locked():return self.service.apply(self.store.load(),{**DEFAULT,'managed':True,**kw},self.palette)
 def test_enable_update_disable(self):
  self.assertEqual(self.apply(backgroundOpacity=.85,blurEnabled=False)['status'],'reload-required');self.assertTrue(self.blur.state['enabled'])
  self.assertIn('background-opacity = 0.85',self.service.snapshot_files()['files']['colors.conf'])
  self.apply(backgroundOpacity=.9,blurEnabled=True);self.assertFalse(self.blur.state['enabled'])
  self.assertEqual(self.apply(managed=False)['status'],'reload-required');self.assertEqual(self.service.snapshot_files(),self.baseline)
 def test_neutral_no_compositor(self):
  self.blur.offline=True;self.assertEqual(self.apply(managed=False)['status'],'released');self.assertEqual(self.service.snapshot_files(),self.baseline)
 def test_theme_compose_and_unsupported_unchanged(self):
  self.apply(backgroundOpacity=.85)
  p=resolve('rose-pine-dawn');f,_=self.orch.render(ADAPTERS['ghostty'],p)
  self.assertIn('background-opacity = 0.85',f['colors.conf']);self.assertIn(p['terminal']['foreground'],f['colors.conf'])
  for key in ['gtk','hyprland','zen','neovim','btop']:
   a=ADAPTERS[key];self.assertEqual(self.orch.render(a,p)[0],{**a.render(p,self.store),'palette.json':json.dumps(p,sort_keys=True,indent=2)+'\n'})
 def test_generation_validation_failures(self):
  for attribute in ['render','validator']:
   with self.subTest(attribute=attribute):
    obj=self.orch if attribute=='render' else self.service
    with patch.object(obj,attribute,side_effect=RuntimeError('injected generation/validation')):
     self.assertFalse(self.apply()['ok'])
    self.assertEqual(self.service.snapshot_files(),self.baseline);self.assertEqual(self.blur.calls,[])
 def test_publication_failure(self):
  publish=self.store.publish;calls=[]
  def fail(*args):
   calls.append(1)
   if len(calls)==1:raise RuntimeError('publish failed')
   return publish(*args)
  with patch.object(self.store,'publish',side_effect=fail):self.assertFalse(self.apply()['ok'])
  self.assertEqual(self.service.snapshot_files(),self.baseline)
 def test_journal_failure_prevents_mutation(self):
  with patch.object(self.store,'save',side_effect=RuntimeError('disk full')):
   self.assertFalse(self.apply(blurEnabled=False)['ok'])
  self.assertEqual(self.blur.calls,[]);self.assertEqual(self.service.snapshot_files(),self.baseline)
 def test_commit_failure_rolls_back(self):
  save=self.store.save;calls=[]
  def fail(state):
   calls.append(1)
   if len(calls)==2:raise RuntimeError('commit failed')
   save(state)
  with patch.object(self.store,'save',side_effect=fail):self.assertFalse(self.apply(blurEnabled=False)['ok'])
  self.assertFalse(self.blur.state['enabled']);self.assertEqual(self.service.snapshot_files(),self.baseline)
 def test_partial_blur_failure_and_readback(self):
  for attr in ['fail','mismatch']:
   with self.subTest(attr=attr):
    setattr(self.blur,attr,True);self.assertFalse(self.apply(blurEnabled=False)['ok'])
    self.assertFalse(self.blur.state['enabled']);self.assertEqual(self.service.snapshot_files(),self.baseline)
 def test_rollback_failure_recovery(self):
  self.blur.fail=True
  with patch.object(self.service,'restore',side_effect=RuntimeError('rollback unavailable')):
   result=self.apply(blurEnabled=False);self.assertIn('rollback failed',result['error'])
  self.assertIn('applicationAppearancePending',self.store.load())
  self.assertTrue(self.apply(managed=False)['ok']);self.assertEqual(self.service.snapshot_files(),self.baseline)
  self.assertNotIn('applicationAppearancePending',self.store.load())
 def test_missing_bootstrap_or_ipc_no_publish(self):
  self.blur.offline=True;self.assertFalse(self.apply()['ok']);self.assertEqual(self.service.snapshot_files(),self.baseline)
 def test_restart_and_reload(self):
  self.apply(blurEnabled=False);self.assertTrue(self.blur.state['enabled'])
  self.service=ApplicationAppearanceCoordinator(self.orch,self.blur,lambda f:None)
  count=len(self.blur.calls);self.apply(blurEnabled=False);self.assertEqual(len(self.blur.calls),count)
  self.blur.state.update(generation='two',enabled=False);self.apply(blurEnabled=False)
  self.assertEqual(len(self.blur.calls),count+1)
 def test_release_failure_preserves_previous(self):
  self.apply(blurEnabled=False,backgroundOpacity=.85);previous=self.service.snapshot_files();self.blur.fail=True
  self.assertFalse(self.apply(managed=False)['ok']);self.assertEqual(self.service.snapshot_files(),previous);self.assertTrue(self.blur.state['enabled'])
 def test_reject_theme_unenrollment_while_managed(self):
  self.apply()
  with self.assertRaisesRegex(RuntimeError,'Release application appearance'):self.orch.disable(self.store.load(),'ghostty')
 def test_corrupt_artifact_not_overwritten(self):
  p=self.store.current('ghostty')/'colors.conf';p.write_text('operator edit')
  self.assertFalse(self.apply()['ok']);self.assertEqual(p.read_text(),'operator edit')

if __name__=='__main__':unittest.main()
