"""Candidate-only validators; never load a running application's config."""
import json, re, subprocess, tempfile, tomllib
from pathlib import Path

def validate(target, files):
    if target=='ghostty':
        from application_appearance.coordinator import validate_ghostty
        validate_ghostty(files)
    if target in ('cava', 'ascii-splash'):
        from terminal_visuals import validate_payload
        name = 'colors.ini' if target == 'cava' else 'theme.json'
        validate_payload(target, files[name])
    for name,text in files.items():
        if not isinstance(text,str) or '\0' in text: raise ValueError('Invalid text artifact: '+name)
        if name.endswith('.json'): json.loads(text)
        elif name.endswith('.toml'): tomllib.loads(text)
        elif name.endswith('.lua'):
            with tempfile.TemporaryDirectory(prefix='magi-lua-validation-') as tmp:
                path=Path(tmp)/'candidate.lua';path.write_text(text)
                p=subprocess.run(['luac','-p',str(path)],capture_output=True,text=True,timeout=5)
                if p.returncode: raise ValueError(p.stderr)
        elif name.endswith('.css'):
            if target=='zen':
                body=re.sub(r'/\*.*?\*/','',text,flags=re.S).strip()
                if not re.fullmatch(r':root\s*\{(?:\s*--ctp-(?:base|surface0|text):\s*#[0-9a-fA-F]{6}\s*!important;){3}\s*\}',body):
                    raise ValueError('Invalid generated Zen alias stylesheet')
                continue
            # GTK's own parser, isolated from Ghostty's GTK4 process.
            script="""import gi,sys
 gi.require_version('Gtk','3.0')
 from gi.repository import Gtk
 p=Gtk.CssProvider();errors=[]
 p.connect('parsing-error',lambda p,s,e:errors.append(str(e)))
 p.load_from_data(sys.stdin.buffer.read())
 if errors: raise ValueError('; '.join(errors))
"""
            script='\n'.join(line[1:] if line.startswith(' ') else line for line in script.splitlines())
            if target=='ghostty':
                script=script.replace("'Gtk','3.0'", "'Gtk','4.0'").replace('p.load_from_data(sys.stdin.buffer.read())', 'p.load_from_string(sys.stdin.read())')
            p=subprocess.run(['python3','-c',script],input=text,capture_output=True,text=True,timeout=5)
            if p.returncode: raise ValueError('CSS validation: '+p.stderr[-600:])
        elif name.endswith('.theme'):
            seen=set()
            for line in text.splitlines():
                if not line.strip() or line.lstrip().startswith('#'): continue
                match=re.fullmatch(r'theme\[([a-z_]+)\]="(#[0-9a-fA-F]{6})"',line)
                if not match or match[1] in seen: raise ValueError('Invalid/duplicate btop theme entry')
                seen.add(match[1])
