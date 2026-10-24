"""Pinned fixed-rule toggle only. No application/window opacity API."""
import json, os, re, subprocess
from .planner import HANDLE, toggle_lua
BUILD = 'efb50993780079460b0cbed1363e2166a2de1d9f'
class GenerationChanged(RuntimeError): pass
class BlurExecutor:
    def __init__(self): self.instance=os.environ.get('HYPRLAND_INSTANCE_SIGNATURE','')
    def call(self,*args):
        if not re.fullmatch(r'[a-f0-9]+_[0-9]+_[0-9]+',self.instance): raise RuntimeError('Hyprland unavailable')
        p=subprocess.run(['hyprctl','-i',self.instance,*args],capture_output=True,text=True,timeout=8)
        if p.returncode: raise RuntimeError((p.stderr or p.stdout).strip())
        return p.stdout.strip()
    def read(self):
        if BUILD not in self.call('version'): raise RuntimeError('Unaudited Hyprland build')
        errors=json.loads(self.call('-j','configerrors'))
        if not isinstance(errors,list) or any(not isinstance(e,str) for e in errors): raise RuntimeError('Invalid configuration diagnostics')
        errors=[e.strip() for e in errors if e.strip()]
        if errors: raise RuntimeError('\n'.join(errors))
        code='local s='+HANDLE+'; if not s or s.rule:is_enabled()==nil then print("missing") else print(os.getenv("HYPRLAND_INSTANCE_SIGNATURE")); print(s.generation); print(tostring(s.rule:is_enabled())) end'
        lines=self.call('repl',code).splitlines()
        if len(lines)!=3 or lines[0]!=self.instance or not re.fullmatch('[a-f0-9-]{36}',lines[1]) or lines[2] not in ('true','false'):
            raise RuntimeError('Ghostty-only blur bootstrap missing or invalid')
        return dict(instance=lines[0],generation=lines[1],enabled=lines[2]=='true')
    def set(self,enabled,context):
        if context['instance']!=self.instance: raise GenerationChanged('Compositor changed')
        code='local s='+HANDLE+'; assert(s and s.generation=='+json.dumps(context['generation'])+' and s.rule:is_enabled()~=nil,"MAGI_GENERATION_CHANGED"); '+toggle_lua(enabled)
        result=self.call('eval',code)
        if 'MAGI_GENERATION_CHANGED' in result: raise GenerationChanged('Configuration changed')
        if result!='ok': raise RuntimeError(result)
        actual=self.read()
        if (actual['instance'],actual['generation'])!=(context['instance'],context['generation']): raise GenerationChanged('Configuration changed')
        if actual['enabled']!=enabled: raise RuntimeError('Blur readback mismatch')
        return actual
