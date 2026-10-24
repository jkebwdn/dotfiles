"""Opt-in GLOBAL compositor blur size. Separate from application participation.

Persist baseline before mutation; never reload Hyprland or change blur passes.
The reviewed static bootstrap supplies config-generation identity, read-only here.
"""
import copy, fcntl, json, os, sys, tempfile
from pathlib import Path
from application_appearance.executor import BlurExecutor, GenerationChanged

DEFAULT = dict(managed=False, size=8)

def normalize(value):
    if not isinstance(value, dict) or set(value)-set(DEFAULT):
        raise ValueError('Invalid global blur policy')
    p = {**DEFAULT, **value}
    if type(p['managed']) is not bool or type(p['size']) is not int or not 1 <= p['size'] <= 40:
        raise ValueError('Global blur amount must be an integer from 1 to 40')
    return p

class Executor(BlurExecutor):
    def read(self):
        context = super().read()
        lines = self.call('repl', 'print(magi_application_background.generation); print(hl.get_config("decoration.blur.size"))').splitlines()
        if len(lines) != 2 or lines[0] != context['generation']:
            raise GenerationChanged('Configuration changed during blur readback')
        size = float(lines[1])
        if not size.is_integer() or not 0 <= size <= 100:
            raise RuntimeError('Invalid compositor blur size')
        return dict(instance=context['instance'], generation=context['generation'], size=int(size))
    def set(self, size, context):
        if type(size) is not int or not 0 <= size <= 100:
            raise ValueError('Invalid blur size')
        code = 'assert(magi_application_background.generation==' + json.dumps(context['generation']) + ',"MAGI_GENERATION_CHANGED"); hl.config({decoration={blur={size=' + str(size) + '}}})'
        result = self.call('eval', code)
        if result != 'ok':
            raise RuntimeError(result)
        actual = self.read()
        if identity(actual) != identity(context) or actual['size'] != size:
            raise RuntimeError('Global blur readback mismatch')

def identity(snapshot):
    return snapshot['instance'], snapshot['generation']

class Store:
    def __init__(self, root):
        self.root=Path(root); self.root.mkdir(parents=True,exist_ok=True,mode=0o700)
        self.path=self.root/'ownership.json'
    def load(self):
        return json.loads(self.path.read_text()) if self.path.exists() else {}
    def save(self, data):
        fd,name=tempfile.mkstemp(dir=self.root,prefix='.ownership-')
        try:
            with os.fdopen(fd,'w') as f:
                json.dump(data,f,sort_keys=True); f.flush(); os.fsync(f.fileno())
            os.replace(name,self.path)
            directory=os.open(self.root,os.O_RDONLY|os.O_DIRECTORY)
            try:os.fsync(directory)
            finally:os.close(directory)
        finally:
            if os.path.exists(name):os.unlink(name)

class Coordinator:
    def __init__(self, store, executor):self.store=store;self.executor=executor
    def apply(self, desired):
        pending=None
        try:
            policy=normalize(desired);state=self.store.load()
            if not state and not policy['managed']:
                return dict(ok=True,status='released')
            current=self.executor.read()
            # Recover an interrupted transaction only in its original generation.
            if state.get('pending'):
                old=state['pending']
                if identity(current)==identity(old['runtime']):
                    self.executor.set(old['runtime']['size'],current)
                    current=self.executor.read()
                state=old['ownership'];self.store.save(state)
            same=bool(state) and identity(state)==identity(current)
            if not policy['managed'] and not same:
                self.store.save({});return dict(ok=True,status='released')
            baseline=state['baseline'] if same else current['size']
            target=policy['size'] if policy['managed'] else baseline
            owned=dict(instance=current['instance'],generation=current['generation'],baseline=baseline)
            intent=dict(runtime=copy.deepcopy(current),ownership=copy.deepcopy(state))
            self.store.save({**owned,'pending':intent})
            pending=intent
            if current['size']!=target:self.executor.set(target,current)
            actual=self.executor.read()
            if identity(actual)!=identity(current) or actual['size']!=target:
                raise RuntimeError('Global blur readback mismatch')
            self.store.save({**owned,'applied':target} if policy['managed'] else {})
            pending=None
            return dict(ok=True,status='applied' if policy['managed'] else 'released',size=target)
        except Exception as error:
            detail=str(error)
            if pending:
                try:
                    now=self.executor.read()
                    if identity(now)==identity(pending['runtime']):
                        self.executor.set(pending['runtime']['size'],now)
                    self.store.save(pending['ownership'])
                except Exception as rollback:detail+='; rollback failed: '+str(rollback)
            return dict(ok=False,status='error',error=detail)

if __name__=='__main__':
    try:
        root=Path(os.environ.get('XDG_STATE_HOME',str(Path.home()/'.local/state')))/'magi/global-blur'
        store=Store(root)
        with (root/'transaction.lock').open('a') as lock:
            fcntl.flock(lock,fcntl.LOCK_EX)
            result=Coordinator(store,Executor()).apply(json.loads(sys.stdin.readline(8192)))
    except Exception as error:result=dict(ok=False,status='error',error=str(error))
    print(json.dumps(result))
