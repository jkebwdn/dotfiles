"""All-candidate preflight, per-target atomic publication, then activation.

Call under Theme Orchestrator's existing process lock. No global atomicity claim.
"""
import copy, hashlib, json
from pathlib import Path
from theme_orchestrator.palette import fingerprint
from theme_orchestrator.storage import atomic, Conflict
from .capabilities import CAPABILITIES, result
from .executor import Executor

class ThemeActivationCoordinator:
    def __init__(self, orchestrator, executor=None):
        self.orchestrator=orchestrator;self.store=orchestrator.store
        self.executor=executor if executor is not None else Executor()
        self.path=self.store.state.parent/'theme-activation/status.json'

    def load(self):
        if self.path.is_symlink() or self.path.parent.absolute()!=self.path.parent.resolve():
            raise Conflict('Activation status was redirected')
        return json.loads(self.path.read_text()) if self.path.exists() else {}

    def save(self, status):
        self.load() # recheck path before writing
        atomic(self.path,json.dumps(status,sort_keys=True,indent=2)+'\n')

    def complete(self, generation, target, outcome):
        current=self.load()
        if current.get('generation')!=generation: return False
        outcome={**outcome,'generation':generation}
        current.setdefault('targets',{})[target]=outcome
        current.setdefault('receipts',{})[target]=outcome
        self.save(current);return True

    def snapshot(self, target):
        pointer=self.store.current(target)
        if not pointer.exists() and not pointer.is_symlink(): return None
        root=pointer.resolve();parent=self.store.data/target/'generations'
        if not pointer.is_symlink() or root.parent!=parent or len(root.name)!=64:
            raise Conflict('Unrecognized current generation: '+target)
        manifest=json.loads((root/'.manifest.json').read_text());files={}
        if manifest.get('owner')!='MAGI theme store v1': raise Conflict('Unowned generation')
        for name,digest in manifest['files'].items():
            p=root/name
            if p.is_symlink() or not p.resolve().is_relative_to(root):raise Conflict('Artifact redirected')
            text=p.read_text()
            if hashlib.sha256(text.encode()).hexdigest()!=digest:raise Conflict('Artifact edited')
            files[name]=text
        return dict(files=files,digest=root.name)

    def activate_published(self, candidates, generation, force=False, changed=None):
        old=self.load();previous=old.get('receipts',old.get('targets',{}))
        status=dict(generation=generation,phase='activation',targets={},receipts=previous.copy(),publication={k:'published' for k in candidates})
        self.save(status)
        for target,candidate in candidates.items():
            key=fingerprint([target,candidate['digest'],CAPABILITIES[target].kind])
            prior=previous.get(target,{})
            if not force and prior.get('key')==key:
                outcome=prior
            elif not force and changed is not None and not changed.get(target,False) and not prior:
                # Startup with existing files and no activation receipt: never replay reloads.
                outcome=result('live' if CAPABILITIES[target].kind=='live' else 'next_launch',
                               'Published output already current; startup did not replay activation.',key=key)
            else:
                # Persist dispatch intent BEFORE calling an external app. Crash restart never retries automatically.
                outcome=result('pending','Activation interrupted; explicit retry is available.',key=key)
                self.complete(generation,target,outcome)
                try:
                    self.orchestrator.activate_scheme(candidate['record'],candidate['palette'])
                    outcome={**self.executor.activate(target,candidate['adapter'],self.store),'key':key}
                except Exception as error:
                    outcome=result('error',str(error)[:800],key=key)
            outcome={**outcome,'generation':generation}
            if not self.complete(generation,target,outcome): return self.load()
            candidate['record'].update(activation=outcome,result=outcome['label']+' — '+outcome.get('detail',''),
                                       error=outcome.get('detail','') if outcome['status']=='error' else '',
                                       stage='activate' if outcome['status']=='error' else 'ready')
        current=self.load()
        if current.get('generation')==generation:
            current['phase']='activation_error' if any(v['status']=='error' for v in current['targets'].values()) else 'ready'
            self.save(current)
        return current

    def apply(self, state, adapters, palette, force=False):
        candidates={};snapshots={};target=''
        try:
            # Nothing below this barrier publishes or activates.
            for target,adapter in adapters.items():
                record=state['targets'][target]
                if getattr(adapter, 'optional', False) and not self.orchestrator.probe(adapter)['available']:
                    record.update(error='', appliedPalette=None, result='Application unavailable',
                                  activation={'label':'Not installed', 'detail':'Install the application to use this optional target.'})
                    continue
                probe=self.orchestrator.ready(adapter)
                if target=='zen' and probe.get('profile')!=record.get('options',{}).get('confirmedProfile'):
                    raise Conflict('Zen profile selection changed; re-enroll')
                if record.get('probe',{}).get('resolved')!=probe.get('resolved'):
                    raise Conflict('Configuration identity changed; re-enroll '+target)
                self.orchestrator.check_hooks(record)
                files,digest=self.orchestrator.render(adapter,palette)
                adapter.validate(files)
                snapshots[target]=self.snapshot(target) if files else None
                candidates[target]=dict(adapter=adapter,files=files,digest=digest,record=record,palette=palette)
            if 'fastfetch' in candidates and not state['targets'].get('ghostty',{}).get('enabled'):
                raise Conflict('Fastfetch requires enrolled Ghostty ANSI palette')
        except Exception as error:
            detail=str(error)[:800]
            for key in adapters:
                state['targets'][key].update(stage='generation',error=detail,result='Generation failed — nothing published')
            self.store.save(state)
            status=dict(generation=fingerprint([palette['fingerprint'], state.get('applicationAppearance'), sorted(adapters), 'preflight']),
                        phase='generation_error',error=detail,failedTarget=target,publication={},targets={},
                        receipts=self.load().get('receipts',{}))
            self.save(status)
            return status
        generation=fingerprint({'palette':palette['fingerprint'],'appearance':state.get('applicationAppearance'),
                                'targets':{k:v['digest'] for k,v in candidates.items()}})
        published={};changed={};before_state=copy.deepcopy(state)
        try:
            for target,c in candidates.items():
                changed[target]=self.store.publish(target,c['files'],c['digest']) if c['files'] else False
                published[target]='published'
                if c['files'] and self.snapshot(target)!=dict(files=c['files'],digest=c['digest']):
                    raise RuntimeError('Publication readback mismatch: '+target)
            for key,c in candidates.items():
                c['record'].update(generation=c['digest'],publishedPalette=palette['id'],desiredPalette=palette['id'],
                                   appliedPalette=None,phase='ready',installed=True,error='')
            self.store.save(state) # Journal publication before any runtime activation.
        except Exception as error:
            # Include the failed operation: it may have switched its pointer before fsync failed.
            if target in candidates: published[target]='failed-or-uncertain'
            for key in reversed(list(published)):
                old=snapshots[key];c=candidates[key]
                try:
                    now=self.snapshot(key) if c['files'] else None
                    if now==old: published[key]='unchanged';continue
                    if old and now==dict(files=c['files'],digest=c['digest']):
                        self.store.publish(key,old['files'],old['digest'])
                        if self.snapshot(key)!=old:raise RuntimeError('Restore readback mismatch')
                        published[key]='restored'
                    else:published[key]='retained-or-conflicted'
                except Exception as restore:published[key]='restore-failed: '+str(restore)[:300]
            state.clear();state.update(before_state)
            status=dict(generation=generation,phase='publication_error',error=str(error)[:800],publication=published,targets={})
            status['receipts']=self.load().get('receipts',{})
            self.save(status)
            for key in adapters:state['targets'][key].update(stage='publish',error=status['error'],result='Publication failed — activation not started')
            self.store.save(state);return status
        status=self.activate_published(candidates,generation,force,changed)
        for key,c in candidates.items():
            if c['files']:
                record=c['record']
                history=[g for g in record.get('generations',[]) if g!=c['digest']]+[c['digest']]
                retained=[g for g in history[:-2] if not self.store.prune(key,g)]
                record['generations']=retained+history[-2:]
        self.store.save(state)
        return status
