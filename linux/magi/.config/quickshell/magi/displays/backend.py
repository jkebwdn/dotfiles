#!/usr/bin/env python3
"""Preview-only JSON service. No production apply route exists."""
from pathlib import Path
import json,os,select,sys,tempfile,time
sys.dont_write_bytecode=True
from model import *
from profiles import Store,create,preview,choose,import_hyprmon
from planner import plan,HyprlandBackend
from transaction import Transaction
FIXTURES=json.loads(Path(__file__).with_name('fixtures.json').read_text())

class Session:
    def __init__(self,profiles,transactions):
        self.store=Store(profiles);self.tx=Transaction(transactions)
        self.observed=clone(FIXTURES['Dual']);self.proposed=clone(self.observed)
        self.fixture='Dual';self.selected=self.proposed[0]['name'];self.warnings=[];self.error='';self.report=None
        self.tx.initialize(self.observed)
    def snapshot(self):
        records,errors=self.store.list();t=self.tx.status();remaining=max(0,int(t.get('deadline',0)-time.monotonic()+.999)) if t['state']=='pending' else 0
        validation=''
        try:validate(self.proposed)
        except (Invalid,KeyError,TypeError) as e:validation=str(e)
        return dict(observed=self.observed,proposed=self.proposed,knownGood=self.tx.read('known-good'),selected=self.selected,dirty=self.proposed!=self.observed,warnings=self.warnings,error=self.error,validation=validation,transaction=t,remaining=remaining,profiles=[dict(id=p['id'],name=p['name'],matching=preview(p,self.observed)['status']) for p in records],profileErrors=errors,report=self.report,fixtures=list(FIXTURES),fixture=self.fixture,authoritative=False,plan=plan(self.proposed) if not validation else [])
    def request(self,r):
        self.error=''
        try:
            op=r['op'];pending=self.tx.pending()
            if pending and op not in ['status','keep','revert','select','fixture','discover']:raise Invalid('Keep or revert the preview before editing.')
            if op=='status':pass
            elif op=='select':
                if r['name'] not in [o['name'] for o in self.proposed]:raise Invalid('Display disappeared.')
                self.selected=r['name']
            elif op=='fixture':
                if r['name'] not in FIXTURES:raise Invalid('Unknown fixture.')
                self.fixture=r['name'];self.hotplug(FIXTURES[r['name']])
            elif op=='reset':self.proposed=clone(self.observed);self.warnings=[]
            elif op=='review':self.warnings=[]
            elif op=='move':
                self.proposed=moved(self.proposed,r['name'],r['x'],r['y']);self.selected=r['name']
            elif op=='place':self.proposed=adjacent(self.proposed,self.selected,r['target'],r['direction'])
            elif op=='edit':
                if r['key'] not in ['enabled','mode','scale','transform','mirror']:raise Invalid('Unknown display field.')
                candidate=clone(self.proposed);o=next(o for o in candidate if o['name']==self.selected);o[r['key']]=r['value']
                # Allow overlap during scale/rotation edits; Apply remains blocked until positioned.
                validate(candidate,overlaps=False);self.proposed=candidate
                if not o['enabled']:self.selected=next(o['name'] for o in candidate if o['enabled'] and not o['mirror'])
            elif op=='apply':
                if self.warnings:raise Invalid('Review the degraded layout before Apply preview.')
                self.tx.apply(self.proposed)
            elif op in ['keep','revert']:
                t=self.tx.status();state=self.tx.finish(r['token'],keep=op=='keep')
                if state=='kept':self.observed=clone(self.proposed)
                else:self.proposed=clone(self.observed)
            elif op=='save':self.store.save(create(r['name'],self.proposed))
            elif op=='rename':self.store.rename(r['id'],r['name'])
            elif op=='delete':self.store.delete(r['id'])
            elif op=='profile':
                result=preview(self.store.load(r['id']),self.observed);self.proposed=result['outputs'];self.warnings=result['warnings']
            elif op=='import':
                # Fixed first-party read-only source, never an arbitrary path from QML.
                directory=Path(os.environ.get('XDG_CONFIG_HOME',str(Path.home()/'.config')))/'hyprmon/profiles'
                self.report=[]
                for path in sorted(directory.glob('*.json')):
                    try:self.report.append(import_hyprmon(json.loads(path.read_text())))
                    except (ValueError,KeyError,TypeError) as e:self.report.append({'name':path.stem,'warnings':[str(e)],'written':False})
            elif op=='discover':
                live=HyprlandBackend().read();self.fixture='';self.hotplug(live);self.warnings.append('Read-only live snapshot. Apply preview affects only the simulation.')
            else:raise Invalid('Unknown preview operation.')
        except (Invalid,KeyError,TypeError,ValueError,OSError,StopIteration) as e:self.error=str(e) or 'Invalid display request.'
        except Exception as e:self.error='Display preview operation failed: '+type(e).__name__
        return self.snapshot()
    def hotplug(self,outputs):
        if self.tx.pending():self.tx.finish(self.tx.status()['token'])
        self.proposed,self.warnings=reconcile(self.observed,self.proposed,outputs);self.observed=clone(outputs)
        if self.selected not in [o['name'] for o in self.proposed]:self.selected=self.proposed[0]['name'] if self.proposed else ''
        # Observed baseline changed; fake backend reconciles, never physical outputs.
        self.tx.write('backend',self.observed);self.tx.write('known-good',self.observed)

def main():
    state=Path(os.environ.get('XDG_STATE_HOME',str(Path.home()/'.local/state')))/'magi/display-preview'
    runtime=Path(tempfile.mkdtemp(prefix='magi-display-preview-'))
    session=Session(state/'profiles',runtime)
    def emit(value):print(json.dumps(value,allow_nan=False),flush=True)
    emit(session.snapshot());last=None;buffer=b''
    try:
        while True:
            ready,_,_=select.select([sys.stdin],[],[],.2)
            if ready:
                chunk=os.read(sys.stdin.fileno(),65536)
                if not chunk:break
                buffer+=chunk
                while b'\n' in buffer:
                    line,buffer=buffer.split(b'\n',1)
                    try:emit(session.request(json.loads(line)))
                    except ValueError:emit({'error':'Invalid JSON request.'})
            status=session.tx.status();marker=(status['state'],int(status.get('deadline',0)-time.monotonic()) if status['state']=='pending' else status.get('token',''))
            if marker!=last and status['state'] in ['pending','reverted','recovery-required']:
                emit(session.snapshot());last=marker
    finally:
        if session.tx.pending():session.tx.finish(session.tx.status()['token'])
if __name__=='__main__':main()
