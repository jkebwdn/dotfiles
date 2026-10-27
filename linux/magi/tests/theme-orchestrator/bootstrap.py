#!/usr/bin/env python3
"""Static-source enrollment and explicit legacy migration, isolated from host state."""
import importlib.util
import os
from pathlib import Path
import subprocess
import sys
import unittest
from unittest.mock import patch
sys.dont_write_bytecode = True
spec=importlib.util.spec_from_file_location('legacy',Path(__file__).with_name('run.py'))
f=importlib.util.module_from_spec(spec);spec.loader.exec_module(f)
from theme_orchestrator import bootstrap
from theme_orchestrator.storage import Conflict

class Bootstrap(unittest.TestCase):
    def setUp(self):
        self.f=f.Lifecycle('test_native_parsers');self.f.setUp();self.addCleanup(self.f.doCleanups)
        self.store=self.f.store
    def sources(self):
        paths={p for t in bootstrap.TARGETS for p in bootstrap.blocks(self.store,t)}
        paths.add(self.store.config/'yazi/magi-template.toml')
        return {str(p):p.read_bytes() for p in paths if p.exists()}
    def legacy(self):
        for target in sorted(bootstrap.TARGETS):self.f.enable(target)
    def migrate(self):return self.f.request('migrate-bootstrap')
    def fresh(self):
        # Source templates are current candidate files, never live operator state.
        root=f.ROOT.parent/'t15g'
        pairs={self.store.home/'.bashrc':root/'bash/.bashrc'}
        for package,names in {'ghostty':['ghostty/config.ghostty'], 'gtk3':['gtk-3.0/gtk.css','gtk-3.0/settings.ini'], 'hypr':['hypr/hyprland.lua'], 'nvim':['nvim/init.lua'], 'yazi':['yazi/init.lua','yazi/theme.toml','yazi/magi-template.toml']}.items():
            pairs.update({self.store.config/n:root/package/'.config'/n for n in names})
        for dst,src in pairs.items():
            text=src.read_text()
            if dst.name=='config.ghostty':
                text=text.replace('?~/.local/share/magi/theme-orchestrator/ghostty/current/colors.conf','?'+str(self.store.current('ghostty')/'colors.conf'))
            dst.write_text(text)
    def test_fresh_round_trip_all_sources_unchanged(self):
        self.fresh();before=self.sources()
        self.assertFalse(self.store.journal.exists())
        for target in sorted(bootstrap.TARGETS):self.f.enable(target)
        self.assertEqual(before,self.sources())
        from theme_orchestrator.palette import REGISTRY
        import json
        additions=[t['id'] for t in json.loads(REGISTRY.read_text())['themes'][18:]]
        for theme in [f.FOREST,*additions,f.MOCHA]:
            self.f.theme=theme;rows=self.f.request('apply')['targets']
            self.assertFalse([r for r in rows if r['error']]);self.assertEqual(before,self.sources())
        for target in sorted(bootstrap.TARGETS):
            row=next(r for r in self.f.request('disable',target=target)['targets'] if r['id']==target)
            self.assertFalse(row['error'],row);self.assertFalse(self.store.current(target).exists())
            self.assertEqual(before,self.sources());self.f.enable(target);self.assertEqual(before,self.sources())
    def test_legacy_journal_reconciliation_preserves_source_and_generation(self):
        self.legacy()
        path=self.store.config/'hypr/hyprland.lua';path.write_text(path.read_text()+'\n-- unrelated operator rule\n')
        generations={t:self.store.current(t).resolve() for t in bootstrap.TARGETS}
        self.assertEqual(set(self.migrate()['migrated']),bootstrap.TARGETS)
        self.assertTrue(path.read_text().endswith('-- unrelated operator rule\n'))
        self.assertEqual(generations,{t:self.store.current(t).resolve() for t in bootstrap.TARGETS})
        before=self.sources()
        for t in bootstrap.TARGETS:
            edits=self.store.load()['targets'][t]['edits']
            self.assertTrue(all(i.get('kind') in ('bootstrap','symlink','gsettings') for i in edits))
            row=next(r for r in self.f.request('disable',target=t)['targets'] if r['id']==t)
            self.assertFalse(row['error'],row);self.assertEqual(before,self.sources())
        self.assertEqual(self.migrate()['migrated'],[])
    def test_foreign_block_and_git_source_refused(self):
        self.fresh();p=self.store.config/'ghostty/config.ghostty';p.write_text(p.read_text().replace('config-file = ?', 'config-file = /foreign/'))
        with self.assertRaises(Conflict):self.f.request('plan',target='ghostty')
        # A legacy non-bootstrap source in a checkout cannot be enrolled.
        p.write_text('font-size = 12\n');(self.store.config/'.git').mkdir();(self.store.config/'.git/HEAD').write_text('ref: refs/heads/main\n')
        with self.assertRaisesRegex(Conflict,'Tracked source'):self.f.request('plan',target='ghostty')
    def test_interrupted_migration_resumes_and_refuses_intervening_edit(self):
        self.legacy()
        import theme_orchestrator.bootstrap_migration as m
        real=m.atomic;count=0
        def interrupted(path,text):
            nonlocal count
            count+=1
            if count==2:raise OSError('fixture interruption')
            real(path,text)
        with patch.object(m,'atomic',side_effect=interrupted):
            with self.assertRaises(OSError):self.migrate()
        pending=self.store.load()['bootstrapMigration'];self.assertTrue(pending)
        with self.assertRaisesRegex(Conflict,'pending bootstrap'):self.f.request('apply')
        p=Path(pending['files'][-1]['path']);exists=p.exists();original=p.read_bytes() if exists else b''
        p.write_text('foreign change\n')
        with self.assertRaises(Conflict):self.migrate()
        if exists:p.write_bytes(original)
        else:p.unlink()
        self.migrate();self.assertNotIn('bootstrapMigration',self.store.load())
    def test_fresh_native_syntax(self):
        self.fresh();env=dict(os.environ,HOME=str(self.store.home),XDG_CONFIG_HOME=str(self.store.config),XDG_DATA_HOME=str(self.store.data.parents[1]))
        subprocess.run(['bash','-n',str(self.store.home/'.bashrc')],check=True)
        for p in [self.store.config/'hypr/hyprland.lua',self.store.config/'nvim/init.lua',self.store.config/'yazi/init.lua']:
            subprocess.run(['luac','-p',str(p)],check=True)
        p=subprocess.run(['ghostty','+validate-config','--config-file='+str(self.store.config/'ghostty/config.ghostty')],env=env,capture_output=True,text=True)
        self.assertEqual(p.returncode,0,p.stderr+p.stdout)
        import tomllib,configparser
        tomllib.loads((self.store.config/'yazi/theme.toml').read_text())
        c=configparser.ConfigParser();c.read(self.store.config/'gtk-3.0/settings.ini');self.assertNotEqual(c['Settings']['gtk-theme-name'],'MAGI')
        from theme_activation.validation import validate
        validate('gtk',{'gtk.css':(self.store.config/'gtk-3.0/gtk.css').read_text()})

    def test_fresh_missing_and_generated_application_startup(self):
        self.fresh()
        env=dict(os.environ,HOME=str(self.store.home),XDG_CONFIG_HOME=str(self.store.config),XDG_DATA_HOME=str(self.store.data.parents[1]),XDG_STATE_HOME=str(self.store.state.parents[1]),TERM='xterm-256color')
        # Test the portable Ghostty tilde form as shipped, with no generated state.
        ghost=self.store.config/'ghostty/config.ghostty'
        ghost.write_text(ghost.read_text().replace(str(self.store.current('ghostty')/'colors.conf'),'~/.local/share/magi/theme-orchestrator/ghostty/current/colors.conf'))
        result=subprocess.run(['ghostty','+validate-config','--config-file='+str(ghost)],env=env,capture_output=True,text=True)
        self.assertEqual(result.returncode,0,result.stderr+result.stdout)
        # Restore the custom-XDG fixture's explicit hook for runtime enrollment.
        ghost.write_text(ghost.read_text().replace('~/.local/share/magi/theme-orchestrator/ghostty/current/colors.conf',str(self.store.current('ghostty')/'colors.conf')))
        plugins=self.store.config/'yazi/plugins';plugins.mkdir()
        (plugins/'yatline.yazi').symlink_to(f.ROOT.parent/'t15g/yazi/.config/yazi/plugins/yatline.yazi')
        import pty,select,time,fcntl,termios,struct
        def yazi():
            master,slave=pty.openpty();fcntl.ioctl(slave,termios.TIOCSWINSZ,struct.pack('HHHH',30,100,0,0))
            child=subprocess.Popen(['yazi',str(self.store.home)],stdin=slave,stdout=slave,stderr=slave,env=dict(env,YAZI_CONFIG_HOME=str(self.store.config/'yazi'),YAZI_STATE_HOME=str(self.store.home/'yazi-state')),cwd=self.store.home)
            os.close(slave);output=b''
            try:
                end=time.monotonic()+2
                while time.monotonic()<end:
                    if select.select([master],[],[],.1)[0]:
                        try:chunk=os.read(master,65536)
                        except OSError:break
                        output+=chunk
                        if b'\x1b[6n' in chunk:os.write(master,b'\x1b[1;1R')
                        if b'\x1b[c' in chunk:os.write(master,b'\x1b[?62;4;6;22c')
                self.assertIsNone(child.poll(),output[-1000:])
                self.assertIn(b'Yazi:',output)
                self.assertNotIn(b'runtime error',output);self.assertNotIn(b'Failed to',output)
            finally:
                if child.poll() is None:child.kill()
                child.wait();os.close(master)
        def nvim():
            # Existing plugin setup is independent; prevent plugin/network side effects
            # while executing the real init and its generated-colourscheme guard.
            pre='lua for _,n in ipairs({"options","keymaps","plugins"}) do package.preload[n]=function() return {} end end'
            out=subprocess.run(['nvim','--headless','--cmd',pre,'-u',str(self.store.config/'nvim/init.lua'),'+qa'],env=env,capture_output=True,text=True,timeout=10)
            self.assertEqual(out.returncode,0,out.stderr);self.assertNotIn('Error',out.stderr)
        def bash(expected):
            inherited=dict(env,STARSHIP_CONFIG=str(self.store.current('starship')/'starship.toml'))
            result=subprocess.run(['bash','--noprofile','--norc','-c','. "$1"; printf "%s" "${STARSHIP_CONFIG-unset}"','fixture',str(self.store.home/'.bashrc')],env=inherited,capture_output=True,text=True,timeout=5)
            self.assertEqual(result.returncode,0,result.stderr);self.assertEqual(result.stdout,expected)
        yazi();nvim();bash('unset')
        self.f.enable('starship');bash(str(self.store.current('starship')/'starship.toml'))
        self.f.request('disable',target='starship');bash('unset')
        for target in ('yazi','neovim'):self.f.enable(target)
        yazi();nvim()
        for target in ('yazi','neovim'):self.f.request('disable',target=target)
        yazi();nvim()

    def test_hyprmon_profile_keeps_guarded_source_unchanged(self):
        # Installed binary, fake compositor executable, disposable HOME/config.
        # No live compositor socket or host profile is reachable.
        import json
        root=self.store.home/'hyprmon-proof';config=root/'.config/hypr';config.mkdir(parents=True)
        profiles=root/'.config/hyprmon/profiles';profiles.mkdir(parents=True)
        (profiles/'Fixture.json').write_text(json.dumps({'name':'Fixture','monitors':[{'name':'eDP-1','PxW':1920,'PxH':1080,'Hz':60,'Scale':1,'X':0,'Y':0,'Active':True}]}))
        binary=root/'bin';binary.mkdir();fake=binary/'hyprctl'
        fake.write_text('#!/usr/bin/python3\nimport sys,json\nprint(json.dumps([dict(id=0,name="eDP-1",width=1920,height=1080,refreshRate=60,x=0,y=0,scale=1,disabled=False)]) if "monitors" in sys.argv else "[]" if "workspaces" in sys.argv else "ok")\n');fake.chmod(0o700)
        source=(f.ROOT.parent/'t15g/hypr/.config/hypr/hyprland.lua').read_text()
        guard=source.split('-- hyprmon: managed monitor profile include\n',1)[1].split('-- MAGI APPLICATION BACKGROUND BEGIN',1)[0]
        path=config/'hyprland.lua';path.write_text(guard);before=path.read_bytes()
        env=dict(os.environ,HOME=str(root),XDG_CONFIG_HOME=str(root/'.config'),HYPRLAND_CONFIG=str(path),HYPRLAND_INSTANCE_SIGNATURE='magi-no-compositor',PATH=str(binary)+':'+os.environ['PATH'],DBUS_SESSION_BUS_ADDRESS='unix:path='+str(root/'absent'))
        subprocess.run(['lua',str(path)],env=env,check=True,capture_output=True)
        run=subprocess.run(['/usr/bin/hyprmon','-cfg',str(profiles.parent),'-profile','Fixture'],env=env,capture_output=True,text=True,timeout=15)
        self.assertEqual(run.returncode,0,run.stderr+run.stdout)
        self.assertEqual(path.read_bytes(),before)
        self.assertTrue((config/'hyprmon.lua').exists())
        # Existing sidecar errors must propagate; the loader doesn't swallow them.
        (config/'hyprmon.lua').write_text('error("fixture syntax/runtime failure")')
        check=subprocess.run(['lua','-e','package.path="'+str(config)+'/?.lua;"..package.path; dofile("'+str(path)+'")'],env=env,capture_output=True,text=True)
        self.assertNotEqual(check.returncode,0)
        self.assertIn('fixture syntax/runtime failure',check.stderr)

if __name__=='__main__':unittest.main()
