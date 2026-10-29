#!/usr/bin/env python3
"""Optional terminal colours, real publication lifecycle and guarded consumers."""
import importlib.util
import json
import os
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile
import unittest
from unittest.mock import patch
sys.dont_write_bytecode = True
spec=importlib.util.spec_from_file_location('fixture',Path(__file__).with_name('run.py'))
f=importlib.util.module_from_spec(spec);spec.loader.exec_module(f)
from theme_orchestrator.adapters import ADAPTERS
from theme_orchestrator.adapters.visuals import splash_theme
from theme_orchestrator.palette import REGISTRY, resolve
from theme_orchestrator.storage import Conflict
from terminal_visuals import cava_config, validate_payload, explicit_override

NATIVE_CAVA = shutil.which("cava")

class Visuals(unittest.TestCase):
    def setUp(self):
        self.f=f.Lifecycle('test_native_parsers');self.f.setUp();self.addCleanup(self.f.doCleanups)
        self.store=self.f.store
        self.cava=self.store.config/'cava/config';self.cava.parent.mkdir()
        self.original="[general]\nframerate = 37\nsensitivity = 73\n[input]\nmethod = pipewire\nsource = auto\n[color]\nforeground = '#123456'\n[smoothing]\nnoise_reduction = 64\n"
        self.cava.write_text(self.original)
        self.splash=self.store.config/'ascii-splash-nodejs/.splashrc.json';self.splash.parent.mkdir()
        self.splash.write_text(json.dumps(dict(defaultPattern='lavaLamp',quality='high',fps=42,theme='fire',patterns={'lavaLamp':{'blobCount':7}})))
    def snapshot(self):
        return {str(p):p.read_bytes() for p in self.store.config.rglob('*') if p.is_file()}
    def test_roundtrip_disable_reenable_source_unchanged(self):
        before=self.snapshot()
        for t in ('cava','ascii-splash'):self.f.enable(t)
        for theme in ('everforest-dark-hard','kanagawa-wave','dracula','gruvbox-dark','one-light',f.MOCHA):
            self.f.theme=theme
            rows=self.f.request('apply')['targets']
            for t in ('cava','ascii-splash'):
                row=next(r for r in rows if r['id']==t)
                self.assertFalse(row['error'],row);self.assertEqual(row['statusLabel'],'Applies next launch')
                self.assertEqual(json.loads((self.store.current(t)/'palette.json').read_text())['id'],theme)
            self.assertEqual(before,self.snapshot())
        for t in ('cava','ascii-splash'):
            self.f.request('disable',target=t);self.assertFalse(self.store.current(t).exists())
            self.f.enable(t)
        self.assertEqual(before,self.snapshot())
    def test_missing_optional_apps_do_not_block_other_targets(self):
        for t in ('cava','ascii-splash','starship'):self.f.enable(t)
        with patch('theme_orchestrator.adapters.visuals.shutil.which',side_effect=lambda name: None if name in ('cava','splash','ascii-splash') else '/usr/bin/test'):
            self.f.theme=f.FOREST;rows=self.f.request('apply')['targets']
            self.assertFalse(any(r['error'] for r in rows),rows)
            for t in ('cava','ascii-splash'):
                row=next(r for r in rows if r['id']==t)
                self.assertFalse(row['available']);self.assertEqual(row['statusLabel'],'Not installed')
            self.assertEqual(json.loads((self.store.current('starship')/'palette.json').read_text())['id'],f.FOREST)
        rows=self.f.request('apply')['targets']
        self.assertTrue(all(next(r for r in rows if r['id']==t)['publishedPalette']==f.FOREST for t in ('cava','ascii-splash')))
    def test_alternate_executable_and_missing_bootstrap(self):
        with patch('theme_orchestrator.adapters.visuals.shutil.which', side_effect=lambda name: '/bin/fixture' if name=='ascii-splash' else None):
            row=ADAPTERS['ascii-splash'].detect(self.store)
            self.assertTrue(row['available']);self.assertTrue(row['configured']);self.assertEqual(row['reason'],'')
            ADAPTERS['ascii-splash'].path(self.store).unlink()
            row=ADAPTERS['ascii-splash'].detect(self.store)
            self.assertTrue(row['available']);self.assertFalse(row['configured']);self.assertIn('bootstrap',row['reason'])
    def test_all_palettes_and_malformed_payloads(self):
        themes=json.loads(REGISTRY.read_text())['themes'];self.assertEqual(len(themes),26)
        for theme in themes:
            p=resolve(theme['id'])
            for t in ('cava','ascii-splash'):
                files=ADAPTERS[t].render(p,self.store);ADAPTERS[t].validate(files)
                self.assertEqual(files,ADAPTERS[t].render(p,self.store))
            colors=ADAPTERS['cava'].render(p,self.store)['colors.ini']
            self.assertEqual(validate_payload('cava',colors)['background'],'default')
        for t,text in [('cava','[color]\ngradient=9'),('cava',colors.replace("'default'","'#000000'")),('ascii-splash','{"theme":"magi"}'),('ascii-splash','[]'),('ascii-splash','bad')]:
            with self.assertRaises((ValueError,KeyError)):validate_payload(t,text)
        self.assertEqual(splash_theme({'accent':'#808080'}),'monochrome')
        for color,expected in [('#00ff00','matrix'),('#00c0ff','ocean'),('#8000ff','starlight'),('#ff6000','fire')]:
            self.assertEqual(splash_theme({'accent':color}),expected)
    def launch(self,target,args=()):
        # Fake actual executables expose argv and inherited anonymous CAVA config.
        bindir=self.store.home/'bin';bindir.mkdir(exist_ok=True)
        for name in ('cava','splash'):
            p=bindir/name;p.write_text('#!'+sys.executable+'\nimport sys,json,pathlib\na=sys.argv[1:]\nprint(json.dumps({"args":a,"config":pathlib.Path(a[1]).read_text() if pathlib.Path(sys.argv[0]).name=="cava" and a and a[0]=="-p" and a[1].startswith("/proc/") else None}))\n');p.chmod(0o700)
        env=dict(os.environ,HOME=str(self.store.home),XDG_CONFIG_HOME=str(self.store.config),XDG_DATA_HOME=str(self.store.data.parents[1]),PATH=str(bindir)+':'+os.environ['PATH'])
        result=subprocess.run([sys.executable,str(f.SOURCE/'services/terminal_visuals.py'),target,*args],env=env,capture_output=True,text=True,check=True)
        return json.loads(result.stdout)
    def test_launch_fallback_overrides_behavior_and_no_files(self):
        before=self.snapshot()
        self.assertEqual(self.launch('cava')['args'],[])
        self.assertEqual(self.launch('ascii-splash',['-p','lavalamp'])['args'],['-p','lavalamp'])
        for t in ('cava','ascii-splash'):self.f.enable(t)
        merged=self.launch('cava')['config']
        for line in ('framerate = 37','sensitivity = 73','method = pipewire','source = auto','noise_reduction = 64'):self.assertIn(line,merged)
        self.assertNotIn('#123456',merged);self.assertIn("background = 'default'",merged)
        args=['-p','lavalamp','-q','high','-f','42']
        launched=self.launch('ascii-splash',args)['args'];self.assertEqual(launched[:6],args);self.assertEqual(launched[6],'--theme')
        for target,args in [('cava',['-v']),('cava',['-p','personal']),('ascii-splash',['-t','fire']),('ascii-splash',['--theme=ocean']),('ascii-splash',['play','shared-code'])]:
            self.assertEqual(self.launch(target,args)['args'],args)
        self.assertEqual(before,self.snapshot())
        for t in ('cava','ascii-splash'):
            self.f.request('disable',target=t);self.assertEqual(self.launch(t)['args'],[])
        self.cava.unlink();self.splash.unlink()
        for t in ('cava','ascii-splash'):self.f.enable(t)
        self.assertIn('[color]',self.launch('cava')['config']);self.assertFalse(self.cava.exists());self.assertFalse(self.splash.exists())
    def test_corrupt_runtime_payload_falls_back_and_stays_local(self):
        for target,name in [('cava','colors.ini'),('ascii-splash','theme.json')]:
            self.f.enable(target)
            payload=self.store.current(target)/name;original=payload.read_text()
            payload.write_text('malformed fixture')
            self.assertEqual(self.launch(target)['args'],[])
            payload.write_text(original)
    def test_installed_splash_semantics(self):
        # Discover only the executable's own package, never scan global npm trees.
        binary=next((Path(folder)/'splash' for folder in os.environ['PATH'].split(os.pathsep) if (Path(folder)/'splash').is_file()),None)
        if binary is None:self.skipTest('ascii-splash unavailable: native semantics need host')
        dist=binary.resolve().parent
        script="""
import assert from 'node:assert/strict';
import {pathToFileURL} from 'node:url';
const root=process.argv[1];
const load=async p=>await import(pathToFileURL(root+'/'+p));
const {THEME_NAMES,getTheme}=await load('config/themes.js');
const {createDefaultConfig}=await load('config/defaults.js');
const {validateFileConfig}=await load('config/validateConfig.js');
const payloads=JSON.parse(process.argv[2]);
assert.deepEqual(THEME_NAMES,['ocean','matrix','starlight','fire','monochrome']);
for(const payload of payloads) {
  let warnings=[];
  const clean=validateFileConfig({...payload,defaultPattern:'lavalamp',quality:'high',fps:42},createDefaultConfig(),'fixture',v=>warnings.push(v));
  assert.equal(warnings.length,0);assert.equal(clean.theme,payload.theme);
  assert.equal(clean.defaultPattern,'lavalamp');assert.equal(clean.quality,'high');assert.equal(clean.fps,42);
  const theme=getTheme(clean.theme);assert.equal(theme.name,clean.theme);
  for(const intensity of [0,.25,.5,.75,1]) {
    const c=theme.getColor(intensity);assert.ok(Object.values(c).every(v=>Number.isInteger(v)&&v>=0&&v<=255));
  }
}
let warnings=[];
const bad=validateFileConfig({theme:'not-supported'},createDefaultConfig(),'fixture',v=>warnings.push(v));
assert.equal(bad.theme,undefined);assert.equal(warnings.length,1);
console.log('Installed ascii-splash validators accepted every mapped palette; invalid theme rejected');
"""
        payloads=[json.loads(ADAPTERS['ascii-splash'].render(resolve(t['id']),self.store)['theme.json']) for t in json.loads(REGISTRY.read_text())['themes']]
        result=subprocess.run(['node','--input-type=module','-e',script,str(dist),json.dumps(payloads)],capture_output=True,text=True)
        self.assertEqual(result.returncode,0,result.stderr);print(result.stdout.strip())
    def test_foreign_bootstrap_rejected(self):
        path=ADAPTERS['cava'].path(self.store);path.write_text(path.read_text().replace('python3','false'))
        with self.assertRaises(Conflict):self.f.enable('cava')
    def test_installed_cava_parser_every_palette(self):
        # Captured before the isolated lifecycle fixture mocks app discovery.
        binary=NATIVE_CAVA
        if not binary:self.skipTest('CAVA unavailable: native parser coverage needs host')
        env=dict(os.environ,HOME=str(self.store.home),XDG_CONFIG_HOME=str(self.store.config))
        for theme in json.loads(REGISTRY.read_text())['themes']:
            colors=ADAPTERS['cava'].render(resolve(theme['id']),self.store)['colors.ini']
            path=self.store.home/'parse.ini';path.write_text("[input]\nmethod = fifo\nsource = /dev/zero\n[output]\nmethod = raw\nraw_target = /dev/null\n"+colors)
            p=subprocess.Popen([binary,'-p',str(path)],env=env,stdout=subprocess.PIPE,stderr=subprocess.PIPE)
            try:
                out,err=p.communicate(timeout=.15)
                self.fail((theme['id'],p.returncode,out,err))
            except subprocess.TimeoutExpired:
                p.terminate();out,err=p.communicate(timeout=3)
                self.assertNotIn(b'Error',err,(theme['id'],err))

if __name__=='__main__':unittest.main(verbosity=2)
