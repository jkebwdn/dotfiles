"""Audited Lua fixed-rule toggle only. No application/window opacity API."""
import json, os, re, subprocess
from .planner import HANDLE, toggle_lua
def compatible_version(output):
    match = re.match(r'\A(?:Hyprland\s+v?|v)(0|[1-9]\d*)\.(0|[1-9]\d*)\.(0|[1-9]\d*)(?=\s|$)', output.strip())
    return bool(match and tuple(map(int, match.groups()[:2])) in ((0, 56), (0, 57)))
class GenerationChanged(RuntimeError): pass
class BlurExecutor:
    def __init__(self): self.instance=os.environ.get('HYPRLAND_INSTANCE_SIGNATURE','')
    def call(self,*args):
        if not re.fullmatch(r'[a-f0-9]+_[0-9]+_[0-9]+',self.instance): raise RuntimeError('Hyprland unavailable')
        p=subprocess.run(['hyprctl','-i',self.instance,*args],capture_output=True,text=True,timeout=8)
        if p.returncode: raise RuntimeError((p.stderr or p.stdout).strip())
        return p.stdout.strip()
    def read(self):
        if not compatible_version(self.call('version')): raise RuntimeError('Hyprland appearance effects require audited 0.56–0.57 Lua APIs')
        errors=json.loads(self.call('-j','configerrors'))
        if not isinstance(errors,list) or any(not isinstance(e,str) for e in errors): raise RuntimeError('Invalid configuration diagnostics')
        errors=[e.strip() for e in errors if e.strip()]
        if errors: raise RuntimeError('\n'.join(errors))
        code='local s='+HANDLE+'; if not s or s.rule:is_enabled()==nil then print("missing") else print(os.getenv("HYPRLAND_INSTANCE_SIGNATURE")); print(s.generation); print(tostring(s.rule:is_enabled())); print(s.thunar_rule and tostring(s.thunar_rule:is_enabled()) or "missing") end'
        lines=self.call('repl',code).splitlines()
        if len(lines)!=4 or lines[0]!=self.instance or not re.fullmatch('[a-f0-9-]{36}',lines[1]) or lines[2] not in ('true','false') or lines[3] not in ('true','false','missing'):
            raise RuntimeError('Application blur bootstrap missing or invalid')
        return dict(instance=lines[0],generation=lines[1],enabled=lines[2]=='true',thunarEnabled=None if lines[3]=='missing' else lines[3]=='true')
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

    def set_thunar(self, enabled, context):
        if type(enabled) is not bool: raise ValueError('Invalid Thunar blur state')
        if context['instance'] != self.instance: raise GenerationChanged('Compositor changed')
        code = 'local s=' + HANDLE + '; assert(s and s.generation==' + json.dumps(context['generation']) + ',"MAGI_GENERATION_CHANGED"); assert(s.thunar_rule,"Thunar blur bootstrap missing"); s.thunar_rule:set_enabled(' + ('true' if enabled else 'false') + ')'
        result = self.call('eval', code)
        if 'MAGI_GENERATION_CHANGED' in result: raise GenerationChanged('Configuration changed')
        if result != 'ok': raise RuntimeError(result)
        actual = self.read()
        if (actual['instance'],actual['generation']) != (context['instance'],context['generation']):
            raise GenerationChanged('Configuration changed')
        if actual['thunarEnabled'] != enabled: raise RuntimeError('Thunar blur readback mismatch')
        return actual
