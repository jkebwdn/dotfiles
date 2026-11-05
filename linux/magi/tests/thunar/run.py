#!/usr/bin/env python3
"""Scoped GTK rendering/alpha and fixed Lua participation; native pixels remain separate."""
import json,re,subprocess,sys,unittest
from pathlib import Path
ROOT=Path(__file__).resolve().parents[2]
sys.dont_write_bytecode=True
sys.path.insert(0,str(ROOT/'.config/quickshell/magi/services'))
from theme_orchestrator.adapters import ADAPTERS
from theme_orchestrator.palette import resolve
from application_appearance.executor import BlurExecutor
from unittest.mock import patch

class Thunar(unittest.TestCase):
 def test_palette_policy_scope_and_parser(self):
  import gi
  gi.require_version('Gtk','3.0')
  from gi.repository import Gtk
  for theme in ('nord','catppuccin-mocha','everforest-dark-hard','one-light'):
   palette=resolve(theme);adapter=ADAPTERS['gtk']
   unmanaged=adapter.render(palette,None)
   self.assertEqual(unmanaged,adapter.render(palette,None,{'managed':False,'backgroundOpacity':.5}))
   self.assertNotIn('rgba(',unmanaged['theme/gtk-3.0/gtk.css'])
   for alpha in (.5,.8,1):
    files=adapter.render(palette,None,{'managed':True,'backgroundOpacity':alpha})
    css=files['theme/gtk-3.0/gtk.css']
    self.assertEqual(set(files),{'gtk.css','theme/gtk-3.0/gtk.css'})
    self.assertNotRegex(css,r'(?<![-\w])opacity\s*:|backdrop-filter|filter\s*:')
    self.assertNotIn('rgba(',files['gtk.css']) # Shared definitions never apply alpha globally.
    for selector,body in re.findall(r'([^{}]+)\{([^{}]*)\}',css):
     if 'transparent' in body or 'rgba(' in body:
      selector=re.sub(r'/\*.*?\*/','',selector,flags=re.S).strip()
      self.assertTrue(all(s.strip().startswith('window.thunar') for s in selector.split(',')))
      self.assertNotRegex(body,r'(?<![-\w])color:\s*(?:transparent|rgba)')
    # Thunar's root/background and Adwaita's inactive surfaces both covered.
    self.assertIn('window.thunar:backdrop',css)
    self.assertIn('.standard-view .view:backdrop',css)
    color=palette['roles']['background'].lstrip('#')
    expected='rgba(%s, %.6g)'%(', '.join(str(int(color[i:i+2],16)) for i in (0,2,4)),alpha)
    self.assertIn(expected,css)
    self.assertIn('color: '+palette['roles']['onAccent'],css)
    # Parse our full rule set without importing GTK's display-dependent Adwaita icons.
    rules=re.sub(r'^@import .*;\n','',css,flags=re.M)
    provider=Gtk.CssProvider();errors=[]
    provider.connect('parsing-error',lambda p,s,e:errors.append(str(e)))
    provider.load_from_data(rules.encode());self.assertEqual(errors,[])
 def test_fixed_independent_rules(self):
  source=(ROOT.parent/'t15g/hypr/.config/hypr/hyprland.lua').read_text()
  code=source.split('-- MAGI APPLICATION BACKGROUND BEGIN',1)[1].split('-- MAGI APPLICATION BACKGROUND END',1)[0]
  # Skip trailing prose on the marker line; execute canonical Lua, not a copied fixture.
  code=code.split('\n',1)[1]
  mock='''local rules={};hl={window_rule=function(r) rules[#rules+1]=r; return {set_enabled=function(_,v)r.enabled=v end,is_enabled=function()return r.enabled end} end}
'''
  proof='''
assert(#rules==2)
assert(rules[2].match.class=="^[Tt]hunar$" and rules[2].no_blur and not rules[2].enabled)
for i=1,200 do
 magi_application_background.thunar_rule:set_enabled(true)
 assert(not magi_application_background.rule:is_enabled())
 magi_application_background.thunar_rule:set_enabled(false)
end
assert(#rules==2 and not rules[1].enabled and not rules[2].enabled)
'''
  subprocess.run(['lua','-'],input=mock+code+proof,text=True,check=True)
 def test_runtime_thunar_toggle_readback(self):
  e=BlurExecutor();e.instance='a'*40+'_1_2';gen='12345678-1234-1234-1234-123456789abc'
  ctx={'instance':e.instance,'generation':gen,'enabled':False,'thunarEnabled':False}
  with patch.object(e,'call',return_value='ok') as call,patch.object(e,'read',return_value={**ctx,'thunarEnabled':True}):
   self.assertTrue(e.set_thunar(True,ctx)['thunarEnabled'])
   self.assertIn('s.thunar_rule:set_enabled(true)',call.call_args.args[-1])
  with patch.object(e,'call',return_value='ok'),patch.object(e,'read',return_value=ctx):
   with self.assertRaisesRegex(RuntimeError,'Thunar blur readback mismatch'):e.set_thunar(True,ctx)
if __name__=='__main__':unittest.main()
