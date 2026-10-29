"""Optional terminal visuals: colours only, consumed by guarded launch hooks."""
import colorsys
import json
import shutil
from .base import Adapter
from ..storage import Conflict

def splash_theme(palette):
    # Compare accent hue to the installed built-ins' representative middle tones.
    color = palette['accent'].lstrip('#')
    h, saturation, _ = colorsys.rgb_to_hsv(*(int(color[i:i+2], 16)/255 for i in (0,2,4)))
    if saturation < .12: return 'monochrome'
    hues = {'ocean': 195/360, 'matrix': 120/360, 'starlight': 260/360, 'fire': 25/360}
    return min(hues, key=lambda name: min(abs(h-hues[name]), 1-abs(h-hues[name])))

class Visual(Adapter):
    optional = True
    config_path = 'quickshell/magi/services/terminal_visuals.sh'
    boundary = 'Next launch through the MAGI shell hook; running processes are unchanged.'
    def detect(self, store):
        result = super().detect(store)
        result['available'] = bool(self.executable_path())
        result['reason'] = ('Application unavailable' if not result['available'] else
                            '' if result['configured'] else 'Canonical terminal visuals bootstrap missing')
        return result
    def executable_path(self):
        return shutil.which(self.executable)
    def plan(self, store, options):
        raise Conflict('Install the canonical terminal visuals bootstrap before enrollment')

class Cava(Visual):
    id, label, executable = 'cava', 'CAVA', 'cava'
    compatibility = 'CAVA 1.0.0; next-launch colour snapshot, no signals or audio reconfiguration'
    def render(self, palette, store):
        p = palette['roles']
        roles = ('teal', 'accent', 'green', 'warning', 'peach', 'red')
        lines = ['[color]', "background = 'default'", "foreground = '%s'" % p['accent'], 'gradient = 1', 'gradient_count = 6']
        lines += ["gradient_color_%d = '%s'" % (i+1, p[role]) for i, role in enumerate(roles)]
        return {'colors.ini': '\n'.join(lines)+'\n'}

class Splash(Visual):
    id, label, executable = 'ascii-splash', 'ascii-splash', 'splash'
    compatibility = 'ascii-splash 0.6.1; nearest built-in theme, not an exact custom palette'
    def executable_path(self):
        return shutil.which('splash') or shutil.which('ascii-splash')
    def render(self, palette, store):
        return {'theme.json': json.dumps({'theme': splash_theme(palette['roles'])}, sort_keys=True)+'\n'}
