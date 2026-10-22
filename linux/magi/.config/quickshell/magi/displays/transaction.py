"""Independent watchdog for the FILE-ONLY synthetic backend; never invokes hyprctl."""
from pathlib import Path
import contextlib,fcntl,json,os,secrets,subprocess,sys,time,threading
sys.dont_write_bytecode=True
from model import validate,Invalid
from profiles import atomic

class Transaction:
    def __init__(self,directory):self.directory=Path(directory)
    @contextlib.contextmanager
    def locked(self):
        self.directory.mkdir(parents=True,exist_ok=True,mode=0o700)
        with (self.directory/'lock').open('a') as f:
            fcntl.flock(f,fcntl.LOCK_EX);yield
    def read(self,name):return json.loads((self.directory/(name+'.json')).read_text())
    def write(self,name,value):atomic(self.directory/(name+'.json'),value)
    def initialize(self,outputs):
        validate(outputs)
        with self.locked():
            if (self.directory/'transaction.json').exists():raise Invalid('Existing transaction requires recovery.')
            self.write('backend',outputs);self.write('known-good',outputs)
    def apply(self,candidate,timeout=15,fail=False,spawn=True,now=None):
        validate(candidate)
        if not 0.1<=timeout<=30:raise Invalid('Invalid confirmation timeout.')
        with self.locked():
            if self.pending():raise Invalid('Confirm or revert the current preview first.')
            previous=self.read('backend')
            if fail:raise Invalid('Synthetic apply failed; previous layout remains.')
            token=secrets.token_hex(16)
            self.write('transaction',dict(token=token,state='pending',previous=previous,candidate=candidate,deadline=(time.monotonic() if now is None else now)+timeout))
            if spawn:
                try:
                    child=subprocess.Popen([sys.executable,str(Path(__file__).resolve()),str(self.directory),token],stdin=subprocess.DEVNULL,stdout=subprocess.DEVNULL,stderr=subprocess.DEVNULL,start_new_session=True,close_fds=True)
                    threading.Thread(target=child.wait,daemon=True).start()
                except Exception:
                    self.write('transaction',dict(token=token,state='reverted',reason='Watchdog could not start'));raise
            # Watchdog is already launched before any candidate backend mutation.
            self.write('backend',candidate)
            return token
    def pending(self):
        p=self.directory/'transaction.json'
        return p.exists() and self.read('transaction').get('state') in ['pending','recovery-required']
    def finish(self,token,keep=False,now=None,revert_failure=False):
        with self.locked():
            t=self.read('transaction')
            if t['token']!=token or t['state']!='pending':raise Invalid('Stale confirmation token.')
            expired=(time.monotonic() if now is None else now)>=t['deadline']
            if keep and not expired:self.write('known-good',t['candidate']);t['state']='kept'
            else:
                try:
                    if revert_failure:raise OSError('Injected synthetic backend failure')
                    self.write('backend',t['previous']);t['state']='reverted'
                except OSError:
                    t['state']='recovery-required';t['error']='Preview rollback failed. Restore previous layout from transaction.json before continuing.'
            self.write('transaction',t)
            return t['state']
    def expire(self,now=None):
        if not self.pending():return
        t=self.read('transaction')
        if t['state']=='pending' and (time.monotonic() if now is None else now)>=t['deadline']:
            try:self.finish(t['token'],now=now)
            except Invalid:pass
    def status(self):
        self.expire()
        p=self.directory/'transaction.json';return self.read('transaction') if p.exists() else {'state':'idle'}

def watchdog(directory,token):
    manager=Transaction(directory)
    while True:
        t=manager.read('transaction')
        if t['token']!=token or t['state']!='pending':return
        if time.monotonic()>=t['deadline']:
            manager.expire();return
        time.sleep(min(.1,max(.01,t['deadline']-time.monotonic())))

if __name__=='__main__':
    if len(sys.argv)!=3:raise SystemExit('Internal synthetic watchdog only')
    watchdog(sys.argv[1],sys.argv[2])
