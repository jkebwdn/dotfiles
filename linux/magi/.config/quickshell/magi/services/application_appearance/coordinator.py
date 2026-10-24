"""Shared-lock application transaction; Theme Orchestrator remains the sole writer.

No automatic app reload. Published config requires Ghostty's native reload action.
All runtime calls are confined to the fixed blur handle.
"""
import copy, hashlib, json, subprocess, tempfile
from pathlib import Path
from .policy import normalize, DEFAULT
from .planner import plan
from .registry import CAPABILITIES
from .executor import GenerationChanged


def validate_ghostty(files):
    with tempfile.TemporaryDirectory(prefix='magi-ghostty-validate-') as tmp:
        config=files['colors.conf']
        if 'background-blur.css' in files:
            css=Path(tmp)/'background-blur.css';css.write_text(files['background-blur.css'])
            config='\n'.join('gtk-custom-css = '+str(css) if line.startswith('gtk-custom-css = ') else line for line in config.splitlines())+'\n'
        path=Path(tmp)/'colors.conf';path.write_text(config)
        p=subprocess.run(['ghostty','+validate-config','--config-file='+str(path)],capture_output=True,text=True,timeout=8,
                         env={**__import__('os').environ,'HOME':tmp,'XDG_CONFIG_HOME':tmp})
        if p.returncode or p.stderr.strip(): raise RuntimeError('Ghostty validation failed: '+(p.stderr or p.stdout).strip())


class ApplicationAppearanceCoordinator:
    def __init__(self, orchestrator, blur, validator=validate_ghostty):
        self.orchestrator=orchestrator;self.store=orchestrator.store;self.blur=blur;self.validator=validator

    def snapshot_files(self):
        pointer=self.store.current('ghostty')
        if not pointer.is_symlink(): raise RuntimeError('Enroll Ghostty theme before managing its background')
        root=pointer.resolve()
        if not root.is_relative_to(self.store.data/'ghostty/generations'): raise RuntimeError('Ghostty generation redirected')
        manifest=json.loads((root/'.manifest.json').read_text());files={}
        for name,digest in manifest['files'].items():
            path=root/name
            if path.is_symlink() or not path.resolve().is_relative_to(root): raise RuntimeError('Artifact redirected')
            files[name]=path.read_text()
            if hashlib.sha256(files[name].encode()).hexdigest()!=digest: raise RuntimeError('Generated config was edited')
        return dict(files=files,digest=root.name)

    def verify_files(self,expected):
        if self.snapshot_files()!=expected: raise RuntimeError('Published generation readback mismatch')

    def restore(self,pending):
        current=self.blur.read()
        ctx=pending['blur']
        # A new config load has its own initially disabled rule: never restore an old flag into it.
        if all(current[k]==ctx[k] for k in ('instance','generation')):
            self.blur.set(ctx['enabled'],ctx)
        previous=pending['publication']
        self.store.publish('ghostty',previous['files'],previous['digest']);self.verify_files(previous)
        self.store.save(pending['state'])

    def apply(self,state,desired,palette):
        pending=None
        try:
            policy=normalize(desired)
            if state.get('applicationAppearancePending'):
                self.restore(state['applicationAppearancePending']);state=self.store.load()
            previous=normalize(state.get('applicationAppearance'))
            if not policy['managed'] and not previous['managed']:
                state['applicationAppearance']=policy;self.store.save(state)
                return dict(ok=True,status='released',error='',support=CAPABILITIES)
            record=state['targets'].get('ghostty',{})
            if not record.get('enabled'): raise RuntimeError('Enable Ghostty in Theme applications first')
            from theme_orchestrator.adapters import ADAPTERS
            adapter=ADAPTERS['ghostty']
            self.orchestrator.ready(adapter);self.orchestrator.check_hooks(record)
            publication=self.snapshot_files()
            files,digest=self.orchestrator.render(adapter,palette,appearance=policy)
            self.validator(files)
            ctx=self.blur.read()
            candidate=plan(policy)
            intent=dict(state=copy.deepcopy(state),publication=publication,blur=ctx)
            journal={**state,'applicationAppearancePending':intent};self.store.save(journal)
            pending=intent
            self.store.publish('ghostty',files,digest)
            self.verify_files(dict(files=files,digest=digest))
            if ctx['enabled']!=candidate['blurExcluded']:self.blur.set(candidate['blurExcluded'],ctx)
            verified=self.blur.read()
            if any(verified[k]!=ctx[k] for k in ('instance','generation')): raise GenerationChanged('Configuration changed')
            if verified['enabled']!=candidate['blurExcluded']: raise RuntimeError('Blur state mismatch')
            state['applicationAppearance']=policy
            record.update(generation=digest,publishedPalette=palette['id'],appliedPalette=None,
                          result='Reload Ghostty configuration to load background appearance',error='')
            state['applicationAppearanceStatus']=dict(status='reload-required',blur=verified)
            self.store.save(state);pending=None
            return dict(ok=True,status='reload-required',error='',support=CAPABILITIES,
                        background='published' if policy['managed'] else 'operator configuration restored; reload required',blur=verified)
        except Exception as error:
            detail=str(error)
            if pending:
                try:self.restore(pending)
                except Exception as rollback:detail+='; rollback failed: '+str(rollback)
            return dict(ok=False,status='error',error=detail,support=CAPABILITIES)
