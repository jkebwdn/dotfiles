"""Hyprland 0.56 Lua planning only: no production execution capability."""
import json,subprocess
from model import validate,Invalid,discover

def plan(outputs):
    validate(outputs)
    # Roots first, then mirrors, disables last. One Lua eval argument, no shell.
    ordered=sorted(outputs,key=lambda o:(2 if not o['enabled'] else 1 if o['mirror'] else 0,o['name']))
    statements=[]
    for o in ordered:
        fields={'output':o['name'],'disabled':not o['enabled']}
        if o['enabled']:fields.update(mode=o['mode'],position=f"{o['x']}x{o['y']}",scale=o['scale'],transform=o['transform'],mirror=o['mirror'])
        encoded=', '.join(k+' = '+json.dumps(v,ensure_ascii=True,allow_nan=False) for k,v in fields.items())
        statements.append('hl.monitor({ '+encoded+' })')
    return ['/usr/bin/hyprctl','eval','; '.join(statements)]

class HyprlandBackend:
    authoritative=False
    def read(self):
        result=subprocess.run(['/usr/bin/hyprctl','-j','monitors','all'],capture_output=True,text=True,timeout=5,check=True)
        return discover(json.loads(result.stdout))
    def apply(self,*args,**kwargs):raise Invalid('Production display changes are disabled in Phase 10C.2A.')
