#!/usr/bin/env python3
"""Tracked Lua direct routes; never reload the compositor or mutate its config."""
from pathlib import Path
import re
import subprocess
root=Path(__file__).resolve().parents[4]
config=root/'linux/t15g/hypr/.config/hypr/hyprland.lua'
source=config.read_text()
source='\n'.join(line for line in source.splitlines() if not line.lstrip().startswith('--'))
expected={'SPACE':'hub toggle apps','N':'hub toggle notifications','C':'hub toggle clipboard',
          'E':'hub toggle emoji','M':'magi toggle controlcentre','W':'magi toggle wifi','B':'magi toggle bluetooth','S':'hub open settings'}
bindings=re.findall(r'hl\.bind\(\s*SUPER\s*\.\.\s*"([^"\n]+)"\s*,\s*hl\.dsp\.exec_cmd\(\s*"([^"\n]+)"',source)
chords=re.findall(r'hl\.bind\(\s*SUPER\s*\.\.\s*"([^"\n]+)"',source)
for key,route in expected.items():
 assert sum(chord.strip()=='+ '+key for chord in chords)==1,key
 matches=[command for chord,command in bindings if chord.strip() == '+ '+key]
 assert matches==['quickshell ipc -c magi call '+route],(key,matches)
assert not any('mftrunk' in c.lower() or 'rofi' in c.lower() for k,c in bindings)
assert not any(k.strip() in ['+ period','+ SHIFT + V'] for k,c in bindings if 'quickshell' in c)
subprocess.run(['luac','-p',str(config)],check=True)
bar=(root/'linux/magi/.config/quickshell/magi/components/bar/Bar.qml').read_text()
assert 'function toggle(view: string)' in bar
assert 'function open(view: string)' in bar
print('Eight direct MAGI routes, conflict-free chords, retired legacy launchers and Lua syntax PASS')
