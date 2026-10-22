"""Versioned preview profiles, never Hyprmon writes or main Settings writes."""
from pathlib import Path
import json,os,re,tempfile,uuid
from model import clone,validate,Invalid,identity,mode,mode_key,reconcile,modes_for

def atomic(path,value):
    path=Path(path);path.parent.mkdir(parents=True,exist_ok=True,mode=0o700)
    fd,tmp=tempfile.mkstemp(prefix='.',dir=path.parent)
    try:
        with os.fdopen(fd,'w') as stream:
            stream.write(json.dumps(value,sort_keys=True,indent=2,allow_nan=False)+'\n');stream.flush();os.fsync(stream.fileno())
        os.replace(tmp,path)
        fd=os.open(path.parent,os.O_DIRECTORY)
        try:os.fsync(fd)
        finally:os.close(fd)
    finally:
        if os.path.exists(tmp):os.unlink(tmp)

def check(profile):
    if not isinstance(profile,dict) or profile.get('version')!=1:raise Invalid('Unsupported profile version.')
    if not re.fullmatch(r'[a-f0-9]{32}',profile.get('id','')):raise Invalid('Invalid profile ID.')
    if not isinstance(profile.get('name'),str) or not profile['name'].strip() or len(profile['name'])>80:raise Invalid('Profile name must contain 1–80 characters.')
    if profile.get('matching') not in ['exact','subset','manual']:raise Invalid('Invalid profile matching policy.')
    validate(profile.get('outputs'))
    ids=[identity(o) for o in profile['outputs']]
    if len(set(ids))!=len(ids):raise Invalid('Profile identities are ambiguous.')
    return profile

def create(name,outputs,matching='exact'):
    keys=['name','make','model','serial','description','enabled','modes','mode','scale','x','y','transform','mirror']
    saved=[{k:clone(o[k]) for k in keys} for o in outputs]
    return check(dict(version=1,id=uuid.uuid4().hex,name=name.strip(),matching=matching,outputs=saved))

def preview(profile,observed):
    check(profile)
    ids=[identity(o) for o in observed];wanted=[identity(o) for o in profile['outputs']]
    ambiguous=len(set(ids))!=len(ids)
    missing=sorted(set(wanted)-set(ids))
    status='ambiguous' if ambiguous else 'missing' if missing else 'exact' if set(ids)==set(wanted) else 'subset'
    if profile['matching']=='manual':status='manual'
    proposed,warnings=reconcile([],profile['outputs'],observed)
    if missing:warnings.append('Missing saved displays: '+', '.join(missing))
    if ambiguous:warnings.append('Duplicate hardware identity; select displays manually')
    try:validate(proposed)
    except Invalid as e:warnings.append(str(e))
    if warnings and status in ['exact','subset']:status='degraded'
    return dict(status=status,outputs=proposed,warnings=warnings,autoApply=False)

def choose(profiles,observed):
    candidates=[p['id'] for p in profiles if p['matching']=='exact' and preview(p,observed)['status']=='exact']
    return dict(candidates=sorted(candidates),decision='ask' if candidates else 'manual',autoApply=False)

class Store:
    def __init__(self,directory):self.directory=Path(directory)
    def path(self,id):
        if not isinstance(id,str) or not re.fullmatch('[a-f0-9]{32}',id):raise Invalid('Invalid profile ID.')
        p=self.directory/(id+'.json')
        if p.is_symlink():raise Invalid('Profile symlinks are not supported.')
        return p
    def save(self,p):check(p);atomic(self.path(p['id']),p)
    def load(self,id):
        p=check(json.loads(self.path(id).read_text()))
        if p['id']!=id:raise Invalid('Profile ID differs from filename.')
        return p
    def delete(self,id):self.path(id).unlink()
    def rename(self,id,name):p=self.load(id);p['name']=name.strip();self.save(p)
    def list(self):
        records=[];errors=[]
        for path in sorted(self.directory.glob('*.json')):
            try:records.append(self.load(path.stem))
            except (ValueError,OSError,KeyError,TypeError) as e:errors.append(path.name+': '+str(e))
        return records,errors

def import_hyprmon(document):
    """Return conversion report only. Caller must explicitly save a reviewed profile."""
    if not isinstance(document,dict) or not isinstance(document.get('monitors'),list):raise Invalid('Invalid Hyprmon profile.')
    outputs=[];warnings=[];unsupported={}
    understood={'name','hardware_id','make','model','serial','PxW','PxH','Hz','Scale','X','Y','Active','EDIDName','Modes','Transform','IsMirrored','MirrorSource','MirrorTargets','Dragging','DragOffX','DragOffY'}
    for m in document['monitors']:
        modes=[]
        for raw in m.get('Modes',[]):
            value=mode(raw['W'],raw['H'],raw['Hz'])
            if value not in modes:modes.append(value)
        selected=mode_key(mode(m['PxW'],m['PxH'],m['Hz']))
        if selected not in [mode_key(x) for x in modes]:warnings.append(m['name']+': saved refresh/mode absent from listed modes; review required')
        unsupported[m['name']]={k:v for k,v in m.items() if k not in understood}
        if any(v not in [0,'',False,None] for v in unsupported[m['name']].values()):warnings.append(m['name']+': unsupported advanced display fields')
        outputs.append(dict(name=m['name'],make=m.get('make',''),model=m.get('model',''),serial=m.get('serial',''),description=m.get('EDIDName',''),enabled=m['Active'],modes=modes,mode=selected,scale=m['Scale'],x=m['X'],y=m['Y'],transform=m.get('Transform',0),mirror=m.get('MirrorSource','') if m.get('IsMirrored') else ''))
    try:validate(outputs)
    except (Invalid,KeyError,TypeError) as e:warnings.append(str(e))
    return dict(name=document.get('name','Imported profile'),outputs=outputs,unsupported=unsupported,warnings=warnings,ready=not warnings,converted=['identity','enabled','mode','scale','position','transform','mirror'],written=False)
