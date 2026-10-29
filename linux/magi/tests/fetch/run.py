#!/usr/bin/env python3
"""Pure geometry and isolated PTY lifecycle; no live configuration writes."""
import fcntl
import importlib.util
import json
import os
from pathlib import Path
import pty
import select
import signal
import struct
import subprocess
import sys
import tempfile
import termios
import time
import unittest
from unittest.mock import patch
sys.dont_write_bytecode=True
ROOT=Path(__file__).resolve().parents[2]
SERVICES=ROOT/'.config/quickshell/magi/services'
sys.path.insert(0,str(SERVICES))
import magi_fetch as m
from theme_orchestrator.palette import resolve

class Fetch(unittest.TestCase):
    def test_geometry_snapshots_overlay_and_depth(self):
        for angle,name in [(0,'zero'),(.35,'quarter'),(.8,'turn')]:
            frame=m.frame(angle)
            self.assertEqual(len(frame),15);self.assertTrue(all(len(row)==35 for row in frame))
            plain='\n'.join(''.join(c for c,r in row).rstrip() for row in frame)+'\n'
            self.assertEqual(plain,(Path(__file__).parent/'snapshots'/f'{name}.txt').read_text())
            self.assertTrue({'muted','teal','accent','text'}<=set(r for row in frame for c,r in row))
            self.assertTrue(all(0<=x<70 and 0<=y<60 for x,y in m.geometry(angle)))
            self.assertTrue(all(row[1:34]==m.frame(0)[y][1:34] for y,row in enumerate(frame) if 4<=y<=10))
        self.assertNotEqual(m.frame(0)[2],m.frame(.35)[2])
        self.assertEqual(m.frame(0),m.frame(0))
    def test_palettes_fallbacks_and_no_color(self):
        for theme in ['catppuccin-mocha','everforest-dark-hard','kanagawa-wave','dracula','gruvbox-dark','one-light']:
            roles=resolve(theme)['roles'];lines=m.render(.35,roles)
            rgb=';'.join(str(int(roles['accent'][i:i+2],16)) for i in (1,3,5))
            self.assertIn('38;2;'+rgb,'\n'.join(lines))
            self.assertTrue(all(m.safe_line(line,color=False)[1]==35 for line in lines))
            mono=m.render(.35,roles,'none',True)
            self.assertTrue(all(line.isascii() and '\x1b' not in line for line in mono))
            self.assertEqual(m.static_output(['Host  fixture'],roles,'none',30,10)[0],'NERV / MAGI SYSTEM')
            self.assertFalse(m.layout(80,10,['Host fixture']))
        with tempfile.TemporaryDirectory() as d, patch.dict(os.environ,{'XDG_CONFIG_HOME':d,'XDG_DATA_HOME':d}):
            self.assertEqual(m.palette(),resolve('catppuccin-mocha')['roles'])
            p=Path(d)/'quickshell/magi/settings.json';p.parent.mkdir(parents=True)
            p.write_text(json.dumps({'appearance':{'theme':'one-light'}}))
            before=p.read_bytes();self.assertEqual(m.palette(),resolve('one-light')['roles']);self.assertEqual(p.read_bytes(),before)
            p.write_text('invalid');self.assertEqual(m.palette(),resolve('catppuccin-mocha')['roles'])
    def test_vertical_alignment(self):
        roles=resolve('catppuccin-mocha')['roles']
        info=['row-'+str(i) for i in range(13)]
        lines=m.static_output(info,roles,'none',110,30)
        self.assertTrue(lines[1].endswith('row-0'));self.assertTrue(lines[13].endswith('row-12'))
        self.assertFalse(any('row-' in line for line in lines[:1]+lines[14:]))
        tall=['row-'+str(i) for i in range(21)]
        lines=m.static_output(tall,roles,'none',110,30)
        self.assertTrue(all(line.startswith(' '*38) for line in lines[:3]+lines[18:]))
        self.assertEqual(len(lines),21)
    def test_fastfetch_cursor_sanitization(self):
        self.assertEqual(m.safe_line('Key\x1b[18GValue',color=False)[0],'Key'+' '*14+'Value')
        text,width=m.safe_line('\x1b[31m界abcdef\x1b[2J\x1b]0;title\x07',4)
        self.assertEqual(m.safe_line(text,color=False)[0],'界ab');self.assertEqual(width,4)
        self.assertNotIn('2J',text);self.assertNotIn('title',text)
    def session(self,args,action=None,columns=110,rows=30,extra_env=None):
        with tempfile.TemporaryDirectory(prefix='magi-fetch-test-') as d:
            root=Path(d);bindir=root/'bin';bindir.mkdir();log=root/'calls'
            fake=bindir/'fastfetch';fake.write_text('#!'+sys.executable+'\nfrom pathlib import Path\nimport os\nPath(os.environ["FETCH_CALLS"]).open("a").write("once\\n")\nprint("Host\\x1b[18Gfixture-system")\nprint("Shell\\x1b[18Gbash")\n');fake.chmod(0o700)
            env=dict(os.environ,HOME=d,XDG_CONFIG_HOME=d,XDG_DATA_HOME=d,PATH=str(bindir)+os.pathsep+os.environ['PATH'],TERM='xterm-ghostty',COLORTERM='truecolor',FETCH_CALLS=str(log))
            env.pop('NO_COLOR',None)
            env.update(extra_env or {})
            master,slave=pty.openpty();fcntl.ioctl(slave,termios.TIOCSWINSZ,struct.pack('HHHH',rows,columns,0,0));before=termios.tcgetattr(slave)
            child=subprocess.Popen([sys.executable,str(SERVICES/'magi_fetch.py'),*args],stdin=slave,stdout=slave,stderr=slave,env=env)
            output=b'';sent=False;start=time.monotonic()
            try:
                while time.monotonic()-start<6:
                    if select.select([master],[],[],.05)[0]:output+=os.read(master,65536)
                    if action and not sent and b'?25l' in output:
                        time.sleep(.12)
                        if action=='resize':
                            fcntl.ioctl(slave,termios.TIOCSWINSZ,struct.pack('HHHH',12,45,0,0));child.send_signal(signal.SIGWINCH)
                        elif action == 'key':os.write(master,b'x')
                        elif action=='input':os.write(master,b'queued-command\n')
                        else:child.send_signal(action)
                        sent=True
                    if child.poll() is not None:
                        while select.select([master],[],[],.05)[0]:output+=os.read(master,65536)
                        break
                self.assertIsNotNone(child.poll(),'fetch failed to stop')
                self.assertEqual(child.returncode,0,output[-1000:])
                self.assertEqual(termios.tcgetattr(slave),before)
                if action == 'key':
                    os.write(master,b'\n')
                    self.assertEqual(os.read(slave,1),b'x')
                if action=='input':self.assertEqual(os.read(slave,256),b'queued-command\n')
                self.assertEqual(log.read_text(),'once\n')
                self.assertEqual(output.count(b'fixture-system'),1,'System information must be printed once')
                self.assertNotIn(b'Traceback',output)
                if b'?25l' in output:self.assertTrue(output.endswith(b'\x1b[0m\x1b[?25h\r'),output[-100:])
                return output,time.monotonic()-start
            finally:
                if child.poll() is None:child.kill()
                child.wait();os.close(master);os.close(slave)
    def test_bounded_animation_and_fixed_info(self):
        out,elapsed=self.session([]);self.assertLess(elapsed,3.5);self.assertGreater(elapsed,1.8)
        self.assertGreater(out.count(b'\x1b[15A'),10)
        # Only 35-column logo rows are written on updates; info column starts at 38.
        for update in out.split(b'\x1b[15A')[1:]:
            for line in update.decode().split('\x1b[1B\r'):
                self.assertLessEqual(m.safe_line(line,color=False)[1],35)
    def test_signals_resize_and_queued_input(self):
        for action in (signal.SIGINT,signal.SIGTERM,signal.SIGTSTP,signal.SIGQUIT,signal.SIGHUP,'resize','input'):
            with self.subTest(action=action):
                out,elapsed=self.session(['--loop'],action);self.assertLess(elapsed,2)
    def test_pty_size_overrides_stale_shell_size(self):
        out,_=self.session(['--until-key'],'key',extra_env={'COLUMNS':'40','LINES':'10'})
        self.assertIn(b'?25l',out)
        self.assertNotIn(b'NERV / MAGI SYSTEM',out)

    def test_first_key_is_preserved(self):
        out,elapsed=self.session(['--until-key'],'key');self.assertLess(elapsed,2)

    def test_static_and_small_terminal(self):
        for args,cols,rows in [(['--static'],110,30),([],40,12),(['--static','--no-color'],110,30)]:
            out,elapsed=self.session(args,columns=cols,rows=rows)
            self.assertNotIn(b'?25l',out);self.assertLess(elapsed,1)
            if '--no-color' in args:self.assertNotIn(b'\x1b',out)
    def test_bash_startup_guards_and_cli(self):
        hook=SERVICES/'terminal_fetch.sh'
        with tempfile.TemporaryDirectory() as d:
            root=Path(d)
            for name in ('magi-fetch','fastfetch'):
                p=root/name
                p.write_text('#!/bin/sh\nprintf "%s\\n" "'+name+' $*" >> "$FETCH_LOG"\n')
                p.chmod(0o700)
            for case in ('normal','ssh','tmux','dumb','other','nested'):
                with self.subTest(case=case):
                    log=root/'log';log.unlink(missing_ok=True)
                    env=dict(os.environ,PATH=d+':'+os.environ['PATH'],FETCH_LOG=str(log),TERM='xterm-ghostty',TERM_PROGRAM='ghostty')
                    for k in ('SSH_CONNECTION','SSH_TTY','TMUX','STY','MAGI_FETCH_TTY'):env.pop(k,None)
                    if case=='ssh':env['SSH_CONNECTION']='fixture'
                    if case=='tmux':env['TMUX']='fixture'
                    if case=='dumb':env['TERM']='dumb'
                    if case=='other':env.update(TERM='xterm',TERM_PROGRAM='fixture')
                    master,slave=pty.openpty()
                    try:
                        prefix='export MAGI_FETCH_TTY=$(tty); ' if case=='nested' else ''
                        command=prefix+'source "$1"; source "$1"; fastfetch; fastfetch --version'
                        child=subprocess.Popen(['bash','--norc','--noprofile','-ic',command,'fixture',str(hook)],stdin=slave,stdout=slave,stderr=slave,env=env)
                        child.wait(timeout=4)
                        self.assertEqual(child.returncode,0)
                        lines=log.read_text().splitlines()
                        expected=['magi-fetch --until-key'] if case=='normal' else []
                        self.assertEqual(lines,expected+['magi-fetch --until-key','fastfetch --version'])
                    finally:
                        if child.poll() is None:child.kill();child.wait()
                        os.close(master);os.close(slave)
            # Noninteractive sourcing installs neither function nor startup execution.
            p=subprocess.run(['bash','--norc','-c','source "$1"; declare -F fastfetch','fixture',str(hook)],capture_output=True)
            self.assertNotEqual(p.returncode,0)

    def test_pipe_and_real_fastfetch(self):
        env=dict(os.environ,NO_COLOR='1')
        p=subprocess.run([sys.executable,str(SERVICES/'magi_fetch.py'),'--static'],env=env,capture_output=True,text=True,timeout=8)
        self.assertEqual(p.returncode,0,p.stderr);self.assertNotIn('\x1b',p.stdout)
        self.assertIn('MAGI SYSTEM',p.stdout)
        self.assertNotIn('magi_fetch.py',p.stdout)
        self.assertIn('Host',p.stdout)

if __name__=='__main__':unittest.main(verbosity=2)
