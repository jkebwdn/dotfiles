"""Pure display model. Physical mode pixels; x/y and canvas geometry are logical."""
import copy
import math
import re

class Invalid(ValueError): pass
CONNECTOR = re.compile(r'[A-Za-z0-9][A-Za-z0-9_.-]{0,63}\Z')
SCALES = (1, 1.25, 1.5, 1.75, 2, 2.5, 3)
def clone(value): return copy.deepcopy(value)
def identity(output):
    if output.get('serial') and output.get('make') and output.get('model'):
        return 'serial:'+'|'.join(output[k] for k in ('make','model','serial'))
    if output.get('description'): return 'description:'+output['description']
    return 'connector:'+output['name']
def mode(w,h,hz):
    return {'width':int(w),'height':int(h),'refresh':round(float(hz)*1000)}
def mode_key(m): return f"{m['width']}x{m['height']}@{m['refresh']/1000:g}"
def modes_for(output): return {mode_key(m):m for m in output['modes']}
def geometry(o):
    m=modes_for(o).get(o['mode'])
    if not m: return (0,0)
    w,h=m['width']/o['scale'],m['height']/o['scale']
    return (h,w) if o['transform']%2 else (w,h)
def overlap(a,b):
    aw,ah=geometry(a);bw,bh=geometry(b)
    return min(a['x']+aw,b['x']+bw)>max(a['x'],b['x'])+.01 and min(a['y']+ah,b['y']+bh)>max(a['y'],b['y'])+.01

def validate(outputs, overlaps=True):
    if not isinstance(outputs,list) or not 1<=len(outputs)<=16: raise Invalid('Choose at least one connected display.')
    names=set();by={}
    for o in outputs:
        if not isinstance(o,dict) or not CONNECTOR.fullmatch(o.get('name','')): raise Invalid('Invalid connector name.')
        if o['name'] in names: raise Invalid('Duplicate connector.')
        names.add(o['name']);by[o['name']]=o
        if type(o.get('enabled')) is not bool: raise Invalid('Enabled must be a boolean.')
        for key in ['make','model','serial','description']:
            if not isinstance(o.get(key,''),str) or len(o.get(key,''))>256:raise Invalid('Invalid display identity.')
        if not isinstance(o.get('modes'),list) or not o['modes']:raise Invalid('Display has no usable modes.')
        seen=set()
        for m in o['modes']:
            if not isinstance(m,dict) or any(type(m.get(k)) is not int for k in ['width','height','refresh']):raise Invalid('Invalid mode.')
            if not 160<=m['width']<=16384 or not 120<=m['height']<=16384 or not 1000<=m['refresh']<=1000000:raise Invalid('Mode outside supported bounds.')
            if mode_key(m) in seen:raise Invalid('Duplicate mode.')
            seen.add(mode_key(m))
        if o.get('mode') not in seen:raise Invalid('Selected mode is unavailable; review the proposed fallback.')
        if type(o.get('scale')) not in [int,float] or not math.isfinite(o['scale']) or not 1<=o['scale']<=3:raise Invalid('Scale must be between 1 and 3.')
        # Conservative UI set; retain valid observed fractional values too.
        if type(o.get('transform')) is not int or o['transform'] not in range(8):raise Invalid('Invalid transform.')
        if any(type(o.get(k)) is not int or abs(o[k])>65536 for k in ['x','y']):raise Invalid('Positions must be bounded logical integers.')
        w,h=geometry(o)
        if w<160 or h<120:raise Invalid('Logical display size is too small.')
        if not isinstance(o.get('mirror'),str):raise Invalid('Invalid mirror target.')
    roots=[o for o in outputs if o['enabled'] and not o['mirror']]
    if not roots:raise Invalid('Keep at least one enabled, non-mirrored display.')
    for o in outputs:
        if not o['mirror']:continue
        target=by.get(o['mirror'])
        if not target or not target['enabled']:raise Invalid('Mirror target is missing or disabled.')
        visited={o['name']};cur=o
        while cur['mirror']:
            if cur['mirror'] in visited:raise Invalid('Mirror cycle is not allowed.')
            visited.add(cur['mirror']);cur=by.get(cur['mirror'])
            if not cur:raise Invalid('Mirror target is missing.')
        if target['mirror']:raise Invalid('Mirror directly to a root display.')
    if overlaps:
        for i,a in enumerate(roots):
            for b in roots[i+1:]:
                if overlap(a,b):raise Invalid('Displays overlap. Move them apart or use Mirror.')
    return outputs

def moved(outputs,name,x,y,snap=True):
    result=clone(outputs);o=next(o for o in result if o['name']==name)
    if not o['enabled'] or o['mirror']:raise Invalid('Move an enabled, non-mirrored display.')
    x,y=round(x),round(y);w,h=geometry(o)
    if snap:
        xs=[];ys=[]
        for n in result:
            if n['name']==name or not n['enabled'] or n['mirror']:continue
            nw,nh=geometry(n)
            xs.extend([n['x']-w,n['x'],n['x']+nw,n['x']+nw-w]);ys.extend([n['y']-h,n['y'],n['y']+nh,n['y']+nh-h])
        for axis,values in [('x',xs),('y',ys)]:
            v=x if axis=='x' else y
            near=sorted(values,key=lambda n:(abs(n-v),n))
            if near and abs(near[0]-v)<=24:
                if axis=='x':x=round(near[0])
                else:y=round(near[0])
    o.update(x=x,y=y);validate(result);return result

def adjacent(outputs,name,target,direction):
    a=next(o for o in outputs if o['name']==name);b=next(o for o in outputs if o['name']==target)
    w,h=geometry(a);bw,bh=geometry(b)
    positions={'left':(b['x']-w,b['y']),'right':(b['x']+bw,b['y']),'above':(b['x'],b['y']-h),'below':(b['x'],b['y']+bh)}
    if direction not in positions:raise Invalid('Unknown placement direction.')
    return moved(outputs,name,*positions[direction],snap=False)

def discover(rows):
    result=[]
    for r in rows:
        modes=[]
        for text in r.get('availableModes',[]):
            match=re.fullmatch(r'(\d+)x(\d+)@([0-9.]+)(?:Hz)?',text)
            if match:
                m=mode(*match.groups())
                if m not in modes:modes.append(m)
        current=mode(r.get('width',0),r.get('height',0),r.get('refreshRate',0))
        active=current in modes
        selected=current if active else (modes[0] if modes else current)
        result.append(dict(name=r['name'],make=r.get('make',''),model=r.get('model',''),serial=r.get('serial',''),description=r.get('description',''),enabled=not r.get('disabled',False),modes=modes,mode=mode_key(selected),scale=r.get('scale',1),x=r.get('x',0),y=r.get('y',0),transform=r.get('transform',0),mirror=r.get('mirrorOf','') if isinstance(r.get('mirrorOf',''),str) and r.get('mirrorOf') not in ['none',''] else '',focused=r.get('focused',False),modeReview=not active))
    return result

def reconcile(observed,proposed,new):
    """Keep edits only for unique identity matches; removed outputs leave no refs."""
    result=clone(new);warnings=[]
    for o in result:
        matches=[p for p in proposed if identity(p)==identity(o)]
        if len(matches)==1:
            p=matches[0]
            for k in ['enabled','mode','scale','x','y','transform','mirror']:o[k]=p[k]
            if o['mode'] not in modes_for(o):
                original=next(n for n in new if n['name']==o['name'])
                o['mode']=original['mode'];warnings.append(o['name']+': saved mode missing; fallback requires review')
            if o['mirror']:
                oldtarget=next((p for p in proposed if p['name']==o['mirror']),None)
                targets=[n for n in new if oldtarget and identity(n)==identity(oldtarget)]
                if len(targets)==1:o['mirror']=targets[0]['name']
                else:o['mirror']='';warnings.append(o['name']+': mirror target missing; review layout')
        elif len(matches)>1:warnings.append(o['name']+': ambiguous identity; edits not restored')
    if len(result)!=len(proposed):warnings.append('Connected display set changed; review proposed layout')
    return result,warnings
