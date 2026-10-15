"""Hybrid Zen: owned CSS aliases; native workspace base remains manual."""
import configparser
from pathlib import Path
import re
from .base import Adapter, block, change
from ..storage import Conflict


class Zen(Adapter):
    id, label, executable = 'zen', 'Zen Browser', 'zen-browser'
    boundary = 'CSS generated · Manual workspace colour required · Restart Zen after CSS changes'
    install_id = '15B76BAA26BA15E7'
    # Explicit operator confirmation, not a discovery heuristic. Never redirect it.
    confirmed_profile = '/home/jkebwdn/.zen/0rzna1o3.Default (release)'

    def profile(self, store):
        root = store.home / '.zen'
        profiles, installs = configparser.ConfigParser(), configparser.ConfigParser()
        profiles.read(root / 'profiles.ini')
        installs.read(root / 'installs.ini')
        section = 'Install' + self.install_id
        candidate = profiles.get(section, 'Default', fallback='')
        if not candidate or installs.get(self.install_id, 'Default', fallback='') != candidate:
            raise Conflict('Zen installation/profile metadata is missing or disagrees')
        registered = []
        for name in profiles.sections():
            if not name.startswith('Profile'):
                continue
            path = Path(profiles.get(name, 'Path', fallback=''))
            if profiles.get(name, 'IsRelative', fallback='1') == '1':
                path = root / path
            registered.append(path.resolve())
        path = (root / candidate).resolve()
        if registered.count(path) != 1 or not path.is_dir():
            raise Conflict('Zen installation profile is unregistered or ambiguous')
        return path

    def path(self, store):
        return self.profile(store) / 'chrome/userChrome.css'

    def detect(self, store):
        try:
            path = self.path(store)
            # Audited installation binary; do not infer another browser installation.
            available = Path('/opt/zen-browser-bin/zen-bin').is_file()
            return dict(available=available, configured=path.is_file(), path=str(path),
                        resolved=str(path.resolve()), profile=str(self.profile(store)),
                        confirmedProfile=str(self.profile(store)) if str(self.profile(store)) == self.confirmed_profile else '',
                        reason='' if str(self.profile(store)) == self.confirmed_profile else 'Confirm Profile Directory in about:support before enrollment')
        except (Conflict, OSError, configparser.Error) as error:
            return dict(available=False, configured=False, reason=str(error))

    def plan(self, store, options):
        profile = self.profile(store)
        if options.get('confirmedProfile') != str(profile):
            raise Conflict('Confirm the exact Zen Profile Directory in about:support')
        # Never retain or return prefs.js content; inspect only this prerequisite.
        enabled = False
        with (profile / 'prefs.js').open() as stream:
            for line in stream:
                if re.fullmatch(r'\s*user_pref\("toolkit\.legacyUserProfileCustomizations\.stylesheets", true\);\s*', line):
                    enabled = True
        if not enabled:
            raise Conflict('Enable custom stylesheets in Zen, then restart and retry; MAGI does not edit preferences')
        url = (store.current(self.id) / 'chrome.css').as_uri()
        return [change(self.path(store), lambda t: block(t, '@import url("' + url + '");', 'css', True))]

    def render(self, p, store):
        r = p['roles']
        # Existing ctp rules deliberately remain; important aliases supersede
        # their non-important values without deleting the user's composition.
        variables = {'ctp-base': 'background', 'ctp-surface0': 'surface', 'ctp-text': 'text'}
        text = '/* MAGI generated aliases; native workspace theme remains user-owned */\n:root {\n'
        text += ''.join(f'  --{k}: {r[v]} !important;\n' for k, v in variables.items()) + '}\n'
        return {'chrome.css': text}
