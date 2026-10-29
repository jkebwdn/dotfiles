"""Single capability/status vocabulary; no application actions during discovery."""
from dataclasses import dataclass

@dataclass(frozen=True)
class Capability:
    kind: str
    automatic: bool = False
    detail: str = ''
    readback: str = 'published-files'

CAPABILITIES = {
    'cava': Capability('next_launch', detail='Start CAVA through the MAGI shell hook. Running visualizers keep their launch colours; no automatic restart.'),
    'ascii-splash': Capability('next_launch', detail='Nearest built-in theme on the next splash launch. Explicit --theme and shared presets take precedence; running animations are unchanged.'),
    'magi': Capability('live', detail='Reactive MAGI palette; no shell reload.'),
    'hyprland': Capability('safe_reload', True, 'Border colours only.', 'command-accepted'),
    'ghostty': Capability('safe_reload', True, 'Existing GApplication reload-config action; independent instances may need manual reload.', 'action-accepted'),
    'gtk': Capability('next_launch', detail='GTK3 / Thunar: next process launch. GTK4 full palette remains deferred.'),
    'zen': Capability('restart_required', detail='Chrome stylesheet; Manual workspace colour required. Restart Zen yourself after CSS changes; no automatic browser restart. Website content unchanged.'),
    'neovim': Capability('next_launch', detail='No unsolicited RPC to editor sessions.'),
    'yazi': Capability('next_launch', detail='Preserves the magi.yazi flavour link; no session commands.'),
    'btop': Capability('next_launch', detail='Reselect manually or start a new process; terminal background inheritance retained.'),
    'starship': Capability('live', detail='Next prompt in shells already using MAGI STARSHIP_CONFIG.'),
    'fastfetch': Capability('next_launch', detail='Next invocation; ANSI colours follow the terminal palette.'),
}
LABELS = {'live':'Live','applied':'Applied','reload_requested':'Reload requested',
          'reload_required':'Reload required','reloaded':'Reloaded','next_launch':'Applies next launch','restart_required':'Restart required',
          'unsupported':'Unsupported','error':'Apply failed','pending':'Pending',
          'generation_error':'Generation failed','publication_error':'Publication failed'}

def result(status, detail='', **extra):
    return dict(status=status, label=LABELS[status], detail=detail, **extra)
