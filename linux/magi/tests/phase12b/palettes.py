#!/usr/bin/env python3
"""Registry, contrast and all adapter outputs in isolated homes; no live activation."""
import importlib.util,json,os,re,subprocess,sys,tomllib,unittest
from pathlib import Path
sys.dont_write_bytecode=True
ROOT=Path(__file__).resolve().parents[2]
SOURCE=ROOT/'.config/quickshell/magi'
sys.path.insert(0,str(SOURCE/'services'))
from theme_orchestrator.palette import resolve,ROLES,REGISTRY
from theme_orchestrator.adapters import ADAPTERS
spec=importlib.util.spec_from_file_location('lifecycle',ROOT/'tests/theme-orchestrator/run.py')
base=importlib.util.module_from_spec(spec);spec.loader.exec_module(base)
# Pin the accepted pre-12B oracle so this regression survives its own commit.
BASELINE='e20a3342f8c37d6359f27bfe5c6a17448bcad147'
registry=json.loads(REGISTRY.read_text())
new=registry['themes'][10:]
def luminance(c):
    values=[int(c[i:i+2],16)/255 for i in (1,3,5)]
    return sum(w*(v/12.92 if v<=.04045 else ((v+.055)/1.055)**2.4) for v,w in zip(values,[.2126,.7152,.0722]))
def contrast(a,b):
    lo,hi=sorted([luminance(a),luminance(b)]);return (hi+.05)/(lo+.05)
class Palettes(unittest.TestCase):
    def test_registry_and_backwards_compatibility(self):
        themes=registry['themes'];self.assertEqual(len(themes),18)
        self.assertEqual(len({t['id'] for t in themes}),len(themes))
        old=json.loads(subprocess.check_output(['git','show',BASELINE+':linux/magi/.config/quickshell/magi/theme/palettes/registry.json'],cwd=ROOT))
        old_code=subprocess.check_output(['git','show',BASELINE+':linux/magi/.config/quickshell/magi/services/theme_orchestrator/palette.py'],cwd=ROOT,text=True)
        oracle={'__file__':str(SOURCE/'services/theme_orchestrator/palette.py')}
        exec(compile(old_code,'baseline-palette.py','exec'),oracle)
        for before,after in zip(old['themes'],themes):
            self.assertEqual(resolve(before['id']),oracle['resolve'](before['id']))
            self.assertEqual(before,{k:v for k,v in after.items() if k!='ansiMagenta'})
        for t in themes:
            self.assertTrue(t['label'].strip() and t['family'].strip());self.assertIs(type(t['dark']),bool)
            self.assertEqual(set(t['roles']),set(ROLES))
            self.assertTrue(all(re.fullmatch('#[0-9a-f]{6}',v) for v in t['roles'].values()))
            self.assertEqual(resolve(t['id']),resolve(t['id']))
        for t in themes[:4]: self.assertEqual(resolve(t['id'])['ansi'][5],t['ansiMagenta'])
        self.assertEqual([t['id'] for t in themes if t['family']=='Nord'],['nord'])
        self.assertEqual([t['id'] for t in new if not t['dark']],['rose-pine-dawn','tokyo-night-day'])
        self.assertEqual(next(t for t in new if t['id']=='rose-pine-dawn')['roles']['text'],'#575279')
        self.assertEqual(next(t for t in new if t['id']=='tokyo-night-day')['roles']['background'],'#e1e2e7')
    def test_contrast(self):
        report=[]
        for t in new:
            r=t['roles'];pairs={f'text/{bg}':contrast(r['text'],r[bg]) for bg in ['background','surface','elevated']}
            for name,value in pairs.items():self.assertGreaterEqual(value,3,(t['id'],name,value))
            for role in ['accent']+registry['accentRoles']:
                value=contrast(r['on'+role.title()],r[role]);pairs['on/'+role]=value
                self.assertGreaterEqual(value,4.5,(t['id'],role,value))
                pairs[role+'/surface']=contrast(r[role],r['surface'])
            pairs['muted/surface']=contrast(r['muted'],r['surface'])
            report.append(dict(id=t['id'],ratios={k:round(v,2) for k,v in pairs.items()},below45=[k for k,v in pairs.items() if v<4.5]))
        output=Path(os.environ.get('MAGI_PHASE12B_OUTPUT','/tmp/magi12b/output'));output.mkdir(parents=True,exist_ok=True)
        (output/'contrast.json').write_text(json.dumps(report,indent=2)+'\n')
        print('Contrast warnings (not palette mutations):',json.dumps({r['id']:r['below45'] for r in report}))

class Adapters(unittest.TestCase):
    setUp=base.Lifecycle.setUp
    request=base.Lifecycle.request
    enable=base.Lifecycle.enable
    def test_all_palettes_all_adapters_and_return(self):
        out=Path(os.environ.get('MAGI_PHASE12B_OUTPUT','/tmp/magi12b/output'))
        for target in ADAPTERS:
            if target!='magi':self.enable(target)
        for t in registry['themes']+[registry['themes'][0]]:
            self.theme=t['id'];p=resolve(self.theme)
            for name,adapter in ADAPTERS.items():
                rendered=adapter.render(p,self.store)
                self.assertEqual(rendered,adapter.render(p,self.store),'deterministic '+name)
                for relative,body in rendered.items():
                    self.assertNotRegex(body,r'undefined|#[^\s";,\)\]}]*None')
                    path=out/self.theme/name/relative;path.parent.mkdir(parents=True,exist_ok=True);path.write_text(body)
                    if path.suffix=='.toml':tomllib.loads(body)
                    if path.suffix=='.lua':subprocess.run(['luac','-p',str(path)],check=True)
                    if path.suffix=='.css':self.assertEqual(body.count('{'),body.count('}'))
                if name=='ghostty':
                    text=rendered['colors.conf'];self.assertEqual(len(re.findall(r'^palette = ',text,re.M)),16)
                if name=='hyprland':self.assertNotRegex(rendered['colors.lua'],r'opacity|blur|animation')
            result=self.request('apply');self.assertFalse(any(r['error'] for r in result['targets']),result)
            for name in ADAPTERS:
                if name not in ('magi','fastfetch'):
                    self.assertEqual(json.loads((self.store.current(name)/'palette.json').read_text())['id'],self.theme)
            before={str(p):p.read_bytes() for p in self.store.data.rglob('*') if p.is_file()}
            self.request('apply')
            self.assertEqual(before,{str(p):p.read_bytes() for p in self.store.data.rglob('*') if p.is_file()})
        self.assertEqual(self.gsettings['color-scheme'],"'prefer-dark'")
if __name__=='__main__':unittest.main(verbosity=2)
