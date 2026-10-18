"""Central capabilities registry. IDs persist independently of display names."""
from .desktop import Magi, Hyprland, Ghostty, Gtk
from .zen import Zen
from .terminal import Yazi, Starship, Btop, Fastfetch
from .neovim import Neovim

ADAPTERS = {a.id: a for a in (Magi(), Hyprland(), Ghostty(), Gtk(), Zen(), Yazi(),
                             Neovim(), Starship(), Fastfetch(), Btop())}
DEFERRED = [dict(id='qt', label='Qt', reason='Active platform plugin not verified'),
            dict(id='hyprtoolkit', label='hyprtoolkit', reason='Authentication/helper dialogs need native validation')]

# Compatibility evidence is a capability, not a claim of current runtime success.
for target, version in {'magi': 'Quickshell 0.3.1', 'hyprland': 'Hyprland 0.56.x Lua',
                        'ghostty': 'Ghostty 1.3.1', 'gtk': 'GTK3 3.24.52 / GTK4 policy',
                        'zen': 'Zen 1.23b, native release install 15B76BAA26BA15E7',
                        'yazi': 'Yazi 26.9.1 + configured yatline', 'neovim': 'Neovim 0.12.5',
                        'starship': 'Starship 1.26.0', 'fastfetch': 'Fastfetch 2.69.0 ANSI',
                        'btop': 'btop 1.4.7'}.items():
    ADAPTERS[target].compatibility = version
