#!/usr/bin/env python3
"""Isolated generation/publication/activation fixtures. Never dispatch to user apps."""
import importlib.util
import json
import os
from pathlib import Path
import re
import sys
import unittest
from unittest.mock import Mock, patch
sys.dont_write_bytecode = True
ROOT = Path(__file__).resolve().parents[2]
spec = importlib.util.spec_from_file_location('orchestrator_fixtures', ROOT/'tests/theme-orchestrator/run.py')
fixtures = importlib.util.module_from_spec(spec); spec.loader.exec_module(fixtures)
from theme_activation.capabilities import CAPABILITIES
from theme_activation.executor import Executor, SessionBus
from theme_orchestrator.coordinator import Orchestrator
from theme_orchestrator.adapters import ADAPTERS
from theme_orchestrator.palette import resolve

class Transactions(unittest.TestCase):
    def setUp(self):
        self.f = fixtures.Lifecycle(); self.f.setUp(); self.addCleanup(self.f.doCleanups)
        for name in ('ghostty', 'neovim'): self.f.enable(name)
        self.worker = self.f.worker; self.store = self.f.store; self.c = self.worker.activation
        self.executor = Mock(wraps=self.c.executor); self.c.executor = self.executor
        self.f.theme = fixtures.FOREST

    def test_all_render_and_validation_before_first_publish(self):
        events = []
        render = self.worker.render; publish = self.store.publish
        def rendered(adapter, palette):
            events.append('render:'+adapter.id); return render(adapter,palette)
        def published(*args):
            events.append('publish:'+args[0]); return publish(*args)
        with patch.object(self.worker,'render',side_effect=rendered), patch.object(self.store,'publish',side_effect=published):
            self.f.request('apply')
        first = next(i for i,v in enumerate(events) if v.startswith('publish'))
        self.assertEqual(set(events[:first]), {'render:ghostty','render:neovim'})
        self.assertEqual(self.executor.activate.call_count, 2)

    def test_render_or_validation_failure_publishes_and_activates_nothing(self):
        for method in ('render','validate'):
            with self.subTest(method=method), patch.object(ADAPTERS['neovim'],method,side_effect=ValueError('candidate invalid')), patch.object(self.store,'publish') as publish:
                self.f.request('apply')
                publish.assert_not_called(); self.executor.activate.assert_not_called()
                self.assertEqual(self.store.load()['targets']['ghostty']['stage'], 'generation')

    def test_publish_failure_compensates_owned_prior_generation_and_never_activates(self):
        before = {k:self.c.snapshot(k) for k in ('ghostty','neovim')}
        publish = self.store.publish
        def broken(target, files, digest):
            if target == 'neovim': raise OSError('disk failure')
            return publish(target,files,digest)
        with patch.object(self.store,'publish',side_effect=broken): self.f.request('apply')
        self.executor.activate.assert_not_called()
        status = self.c.load(); self.assertEqual(status['phase'],'publication_error')
        self.assertEqual(status['publication'],{'ghostty':'restored','neovim':'unchanged'})
        self.assertEqual(before,{k:self.c.snapshot(k) for k in before})

    def test_compensation_failure_is_reported_not_hidden(self):
        publish = self.store.publish; calls = []
        def broken(target,files,digest):
            calls.append(target)
            if len(calls)>1: raise OSError('disk failed including restore')
            return publish(target,files,digest)
        with patch.object(self.store,'publish',side_effect=broken): self.f.request('apply')
        self.executor.activate.assert_not_called()
        self.assertTrue(self.c.load()['publication']['ghostty'].startswith('restore-failed'))

    def test_activation_barrier_and_local_failure(self):
        activate = self.executor.activate._mock_wraps
        def checked(target,adapter,store):
            for k in ('ghostty','neovim'):
                self.assertEqual(json.loads((store.current(k)/'palette.json').read_text())['id'], fixtures.FOREST)
            if target=='ghostty': raise TimeoutError('reload timed out')
            return activate(target,adapter,store)
        self.executor.activate.side_effect = checked
        self.f.request('apply')
        state = self.store.load()
        self.assertEqual(self.c.load()['phase'],'activation_error')
        self.assertEqual(state['targets']['ghostty']['activation']['status'],'error')
        self.assertEqual(state['targets']['neovim']['activation']['status'],'next_launch')
        self.assertEqual(state['targets']['ghostty']['publishedPalette'],fixtures.FOREST)

    def test_failed_activation_can_be_explicitly_retried(self):
        activate=self.executor.activate._mock_wraps
        def fail_ghostty(target,adapter,store):
            if target=='ghostty': raise TimeoutError('temporary D-Bus timeout')
            return activate(target,adapter,store)
        self.executor.activate.side_effect=fail_ghostty
        self.f.request('apply')
        self.assertEqual(self.c.load()['targets']['ghostty']['status'],'error')
        calls=self.executor.activate.call_count
        self.f.request('apply')
        self.assertEqual(self.executor.activate.call_count,calls, 'No automatic retry storm')
        self.executor.activate.side_effect=None
        self.f.request('retry',target='ghostty')
        self.assertEqual(self.executor.activate.call_count,calls+1)
        self.assertEqual(self.c.load()['targets']['ghostty']['status'],'reload_requested')
        self.assertFalse(self.store.load()['targets']['ghostty']['error'])

    def test_same_generation_and_restart_do_not_replay(self):
        self.f.request('apply'); first = self.c.load()['generation']
        self.f.request('apply'); self.assertEqual(self.executor.activate.call_count,2)
        Orchestrator(self.store,self.executor).perform(dict(op='apply',theme=fixtures.FOREST))
        self.assertEqual(self.executor.activate.call_count,2)
        self.assertEqual(self.c.load()['generation'],first)

    def test_existing_output_without_receipts_does_not_reload_on_startup(self):
        self.f.request('apply'); self.c.path.unlink(); self.executor.reset_mock()
        self.f.request('apply'); self.executor.activate.assert_not_called()

    def test_rapid_generations_and_late_result(self):
        self.f.request('apply'); a = self.c.load()['generation']
        self.f.theme = fixtures.MOCHA; self.f.request('apply')
        self.f.theme = 'rose-pine-dawn'; self.f.request('apply'); c = self.c.load()
        self.assertNotEqual(a,c['generation'])
        self.assertFalse(self.c.complete(a,'ghostty',dict(status='error')))
        self.assertEqual(self.c.load(),c)

    def test_publication_journal_failure_blocks_activation(self):
        save=self.store.save; failed=False
        def fail_once(state):
            nonlocal failed
            if not failed:
                failed=True; raise OSError('publication journal failed')
            return save(state)
        with patch.object(self.store,'save',side_effect=fail_once): self.f.request('apply')
        self.executor.activate.assert_not_called()
        self.assertEqual(self.c.load()['phase'],'publication_error')

    def test_appearance_theme_composition_and_release_activation(self):
        spec=importlib.util.spec_from_file_location('appearance_fixtures',ROOT/'tests/phase12g/run.py')
        module=importlib.util.module_from_spec(spec);spec.loader.exec_module(module)
        with patch('application_appearance.executor.BlurExecutor',return_value=module.Blur()):
            self.f.request('application-appearance',policy=dict(managed=True,backgroundOpacity=.85,blurEnabled=True))
            self.f.request('apply')
            colors=(self.store.current('ghostty')/'colors.conf').read_text()
            css=(self.store.current('ghostty')/'background-blur.css').read_text()
            self.assertIn('background-opacity = 0.85',colors)
            self.assertIn('background-opacity-cells = false',colors)
            self.assertIn('20px',css)
            self.f.request('application-appearance',policy=dict(managed=True,backgroundOpacity=.9,blurEnabled=True))
            updated=(self.store.current('ghostty')/'colors.conf').read_text()
            self.assertEqual(colors.replace('0.85','0.9'),updated)
            self.f.request('application-appearance',policy=dict(managed=False,backgroundOpacity=1,blurEnabled=True))
            self.assertNotIn('background-opacity =',(self.store.current('ghostty')/'colors.conf').read_text())
            self.assertEqual(self.c.load()['targets']['ghostty']['status'],'reload_requested')

    def test_btop_theme_is_enumerated_and_owned_link_restores_cleanly(self):
        self.f.enable('btop')
        link=self.store.config/'btop/themes/magi.theme'
        self.assertTrue(link.is_symlink())
        self.assertEqual(link.resolve(),(self.store.current('btop')/'magi.theme').resolve())
        config=(self.store.config/'btop/btop.conf').read_text()
        selected=json.loads(re.search(r'^color_theme = (.+)$',config,re.M)[1])
        # btop 1.4.7 updateThemes enumerates *.theme under config/themes;
        # setTheme matches the enumerated path, stem or filename, not realpath.
        enumerated=list(link.parent.glob('*.theme'))
        self.assertTrue(any(str(p)==selected or p.stem==selected or p.name==selected for p in enumerated))
        self.assertIn('theme_background = false',config)
        self.f.request('disable',target='btop')
        self.assertFalse(link.is_symlink())
        self.assertEqual((self.store.config/'btop/btop.conf').read_text(), 'color_theme = "t15g"\ntheme_background = false\n')

    def test_schema_and_no_runtime_state_in_settings(self):
        self.f.request('apply')
        self.assertEqual(self.c.path,self.store.state.parent/'theme-activation/status.json')
        self.assertFalse((self.store.config/'quickshell/magi/settings.json').exists())

class GhosttyDispatch(unittest.TestCase):
    def setUp(self):
        self.bus = Mock(); self.bus.owner.return_value = ':1.55'
        self.bus.identity.return_value = (os.getuid(),101)
        self.bus.describe.return_value = (True,'',[])
        self.ex = Executor(bus_factory=lambda:self.bus)
        self.ex.processes = Mock(return_value=[101])
        p=patch('theme_activation.executor.shutil.which',return_value='/usr/bin/ghostty');p.start();self.addCleanup(p.stop)

    def test_running_dispatches_parameterless_action_to_verified_unique_owner(self):
        r=self.ex.ghostty();self.assertEqual(r['status'],'reload_requested')
        self.bus.reload.assert_called_once_with(':1.55')

    def test_absent_never_connects_or_starts(self):
        self.ex.processes.return_value=[]
        self.assertEqual(self.ex.ghostty()['status'],'next_launch');self.bus.owner.assert_not_called()

    def test_multiple_independent_processes_are_not_signalled(self):
        self.ex.processes.return_value=[101,202]
        r=self.ex.ghostty();self.assertEqual(r['otherProcesses'],1)
        self.bus.reload.assert_called_once_with(':1.55')

    def test_independent_without_owner_requires_manual_reload(self):
        self.bus.owner.return_value=None
        self.assertEqual(self.ex.ghostty()['status'],'reload_required');self.bus.reload.assert_not_called()

    def test_owner_mismatch_disabled_action_and_owner_race(self):
        for scenario in ('pid','uid','disabled','parameter','race'):
            with self.subTest(scenario=scenario):
                self.setUp()
                if scenario=='pid': self.bus.identity.return_value=(os.getuid(),999)
                if scenario=='uid': self.bus.identity.return_value=(os.getuid()+1,101)
                if scenario=='disabled': self.bus.describe.return_value=(False,'',[])
                if scenario=='parameter': self.bus.describe.return_value=(True,'s',[])
                if scenario=='race': self.bus.owner.side_effect=[':1.55',':1.56']
                with self.assertRaises(RuntimeError):self.ex.ghostty()
                self.bus.reload.assert_not_called()

    def test_timeout_propagates_without_retry(self):
        self.bus.reload.side_effect=TimeoutError('timeout')
        with self.assertRaises(TimeoutError):self.ex.ghostty()
        self.assertEqual(self.bus.reload.call_count,1)

    def test_wire_contract_nested_describe_and_activate(self):
        bus=SessionBus.__new__(SessionBus);bus.call=Mock(return_value=((True,'',[]),))
        self.assertEqual(bus.describe(':1.55'),(True,'',[]))
        self.assertEqual(bus.call.call_args.args[-1],'((bgav))')
        bus.reload(':1.55')
        self.assertEqual(bus.call.call_args.args,(':1.55','/com/mitchellh/ghostty','org.gtk.Actions','Activate','(sava{sv})',('reload-config',[],{}),'()'))

class Capabilities(unittest.TestCase):
    def test_passive_targets_never_dispatch(self):
        ex=Executor(bus_factory=Mock(side_effect=AssertionError('No bus')))
        for target in ('gtk','neovim','yazi','btop','fastfetch','starship','magi'):
            adapter=Mock();r=ex.activate(target,adapter,None)
            self.assertEqual(r['status'],CAPABILITIES[target].kind);adapter.activate.assert_not_called()

    def test_zen_running_and_absent_without_restart(self):
        ex=Executor();adapter=Mock()
        for running,status in ((True,'restart_required'),(False,'next_launch')):
            with patch.object(ex,'running',return_value=running):self.assertEqual(ex.activate('zen',adapter,None)['status'],status)
        adapter.activate.assert_not_called()

    def test_no_destructive_or_opacity_execution(self):
        source=(ROOT/'.config/quickshell/magi/services/theme_activation/executor.py').read_text()
        for forbidden in ('os.kill(', 'pkill', 'killall', 'ydotool', 'active_opacity','inactive_opacity','blur.passes'):
            self.assertNotIn(forbidden,source)
        self.assertIn('DBusCallFlags.NO_AUTO_START',source)

class BtopSemantics(unittest.TestCase):
    def test_six_palettes_determinism_roles_and_readable_selection(self):
        def luminance(color):
            rgb=[int(color[i:i+2],16)/255 for i in (1,3,5)]
            return sum(w*(v/12.92 if v<=.04045 else ((v+.055)/1.055)**2.4) for w,v in zip((.2126,.7152,.0722),rgb))
        for theme in ('catppuccin-mocha','everforest-dark-hard','rose-pine','nord','tokyo-night-moon','rose-pine-dawn'):
            with self.subTest(theme=theme):
                p=resolve(theme)
                output=ADAPTERS['btop'].render(p,None)
                self.assertEqual(output,ADAPTERS['btop'].render(p,None))
                ADAPTERS['btop'].validate(output)
                text=output['magi.theme']
                self.assertEqual(text,(Path(__file__).parent/'fixtures'/('btop-'+theme+'.theme')).read_text())
                colors=dict(re.findall(r'theme\[([^]]+)\]="(#[0-9a-fA-F]{6})"',text))
                self.assertEqual(colors['main_fg'],p['roles']['text'])
                self.assertEqual(colors['selected_fg'],p['roles']['onAccent'])
                for a,b in (('main_fg','main_bg'),('selected_fg','selected_bg')):
                    x,y=sorted((luminance(colors[a]),luminance(colors[b])))
                    self.assertGreaterEqual((y+.05)/(x+.05),4.5)
                self.assertEqual(colors['temp_end'],p['roles']['danger'])
                self.assertNotEqual(colors['download_start'],colors['upload_start'])
                self.assertNotIn('theme_background = true',text)

if __name__=='__main__':unittest.main(verbosity=2)
