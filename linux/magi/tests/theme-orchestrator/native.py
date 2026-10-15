#!/usr/bin/env python3
"""Bounded native parsers/terminal startup, using disposable application config.
No desktop reload, dconf write, browser launch or operator config edit.
"""
import importlib.util
import sys
sys.dont_write_bytecode = True
import os
from pathlib import Path
import pty
import select
import subprocess
import time
import fcntl
import termios
import struct

spec = importlib.util.spec_from_file_location('fixtures', Path(__file__).with_name('run.py'))
fixtures = importlib.util.module_from_spec(spec)
spec.loader.exec_module(fixtures)
test = fixtures.Lifecycle('test_native_parsers')
test.setUp()
try:
    for theme in (fixtures.MOCHA, fixtures.FOREST, fixtures.MOCHA):
        p = fixtures.resolve(theme)
        for target in ('hyprland', 'neovim', 'ghostty', 'gtk', 'starship', 'btop', 'yazi'):
            files = fixtures.ADAPTERS[target].render(p, test.store)
            root = test.home/'native'/target
            for name, text in files.items():
                path = root/name; path.parent.mkdir(parents=True, exist_ok=True); path.write_text(text)
                if name.endswith('.lua'):
                    subprocess.run(['luac', '-p', str(path)], check=True, capture_output=True)
        ghost = test.home/'native/ghostty/colors.conf'
        (ghost.parent/'config.ghostty').write_text(ghost.read_text())
        proc = subprocess.run(['ghostty', '+show-config'], env=dict(os.environ, HOME=str(test.home),
            XDG_CONFIG_HOME=str(test.home/'native')), text=True, capture_output=True, timeout=10)
        assert proc.returncode == 0, proc.stderr
        assert ('background = '+p['roles']['background']) in proc.stdout, proc.stdout[:500]
        assert ('foreground = '+p['roles']['text']) in proc.stdout
        prompt = subprocess.run(['starship', 'prompt', '--path', str(test.home)], env=dict(os.environ,
            STARSHIP_CONFIG=str(test.home/'native/starship/starship.toml'), TERM='xterm-256color'),
            text=True, capture_output=True, timeout=10)
        assert prompt.returncode == 0 and '[ERROR]' not in prompt.stderr, prompt.stderr
        print(theme + ': Lua syntax, Ghostty effective RGB, Starship prompt PASS')

    test.theme = fixtures.FOREST
    test.enable('yazi')
    plugins = test.store.config/'yazi/plugins'; plugins.mkdir()
    (plugins/'yatline.yazi').symlink_to(fixtures.ROOT.parent/'t15g/yazi/.config/yazi/plugins/yatline.yazi')
    master, slave = pty.openpty()
    fcntl.ioctl(slave, termios.TIOCSWINSZ, struct.pack('HHHH', 30, 100, 0, 0))
    env = dict(os.environ, YAZI_CONFIG_HOME=str(test.store.config/'yazi'),
               YAZI_STATE_HOME=str(test.home/'yazi-state'), TERM='xterm-256color')
    proc = subprocess.Popen(['yazi', str(test.home)], stdin=slave, stdout=slave, stderr=slave, env=env, cwd=test.home)
    os.close(slave)
    output = b''
    try:
        deadline = time.monotonic() + 4
        while time.monotonic() < deadline:
            if select.select([master], [], [], .1)[0]:
                try: chunk = os.read(master, 65536)
                except OSError: break
                output += chunk
                if b'\x1b[6n' in chunk: os.write(master, b'\x1b[1;1R')
                if b'\x1b[c' in chunk: os.write(master, b'\x1b[?62;4;6;22c')
        assert b'Yazi:' in output and b'runtime error' not in output and b'Failed to' not in output, output[-1500:]
        assert b'167;192;128' in output, 'Everforest accent not present in native Yazi output'
        print('Yazi + yatline: native startup and Everforest RGB PASS; bounded PTY teardown, no live reload claim')
    finally:
        if proc.poll() is None: proc.kill()
        proc.wait(timeout=3)
        os.close(master)
finally:
    test.doCleanups()
