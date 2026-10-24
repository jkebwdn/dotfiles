"""Small adapter contract; discovery never installs anything."""
from pathlib import Path
import shutil
import subprocess
from ..storage import edit, Conflict


def command(argv):
    result = subprocess.run(argv, text=True, capture_output=True, timeout=8)
    if result.returncode or (argv[0] == 'gsettings' and argv[1] == 'set' and result.stderr.strip()):
        raise RuntimeError((result.stderr or result.stdout or 'Command failed')[:600])
    return result.stdout.strip()


def change(path, transform):
    before = path.read_text() if path.exists() else ''
    after = transform(before)
    if before == after:
        raise Conflict('Integration already present or incompatible: ' + str(path))
    return edit(path, before, after)


def block(text, body, language='#', prepend=False):
    if 'MAGI THEME BEGIN' in text:
        raise Conflict('Unowned MAGI integration already exists')
    if language == 'css':
        chunk = '/* MAGI THEME BEGIN */\n' + body + '\n/* MAGI THEME END */\n'
    else:
        chunk = language + ' MAGI THEME BEGIN\n' + body + '\n' + language + ' MAGI THEME END\n'
    return chunk + text if prepend else text + '\n' + chunk


class Adapter:
    id = ''
    label = ''
    executable = ''
    config_path = ''
    boundary = 'Next launch'
    version = 1
    compatibility = 'Audited configuration layout; native acceptance required'

    def path(self, store):
        return store.config / self.config_path

    def detect(self, store):
        configured = self.path(store).is_file()
        available = bool(shutil.which(self.executable)) if self.executable else True
        return dict(available=available, configured=configured,
                    path=str(self.path(store)), resolved=str(self.path(store).resolve()),
                    reason='' if available and configured else 'Application unavailable' if not available else 'Audited configuration missing')

    def plan(self, store, options):
        return []

    def render(self, palette, store):
        return {}

    @property
    def capability(self):
        from theme_activation.capabilities import CAPABILITIES
        return CAPABILITIES[self.id]

    def validate(self, files):
        from theme_activation.validation import validate
        validate(self.id, files)

    def activate(self, store):
        return self.boundary
