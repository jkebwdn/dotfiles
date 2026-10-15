"""Serialized per-target publication, enrollment and truthful activation results."""
import json
import os
from pathlib import Path
from .adapters import ADAPTERS, DEFERRED
from .adapters.base import command
from .palette import resolve, fingerprint
from .storage import Conflict, atomic, install, removal, text_hash


class Orchestrator:
    def __init__(self, store):
        self.store = store

    def probe(self, adapter):
        try:
            return adapter.detect(self.store)
        except Exception as error:
            return dict(available=False, configured=False, reason=str(error)[:600])

    def ready(self, adapter):
        probe = self.probe(adapter)
        if not probe['available'] or not probe['configured']:
            raise RuntimeError(probe.get('reason') or 'Target unavailable')
        return probe

    def check_hooks(self, record):
        for item in record.get('edits', []):
            if item.get('kind') == 'gsettings':
                value = command(['gsettings', 'get', item['schema'], item['key']])
                if value != item['after']:
                    raise Conflict('System appearance setting changed outside MAGI: ' + item['key'])
            elif item.get('kind') == 'symlink':
                path = Path(item['path'])
                if not path.is_symlink() or os.readlink(path) != item['destination']:
                    raise Conflict('Owned integration link changed: ' + str(path))
                if str(path.parent.resolve()) != item['parent']:
                    raise Conflict('Integration directory changed: ' + str(path))
            else:
                removal(item)  # Validate only: never restore while applying.
                current = Path(item['path']).read_text()
                if text_hash(current) == item['beforeHash']:
                    raise Conflict('Integration was removed outside MAGI')

    def render(self, adapter, palette):
        files = adapter.render(palette, self.store)
        if files:
            files['palette.json'] = json.dumps(palette, sort_keys=True, indent=2) + '\n'
        return files, fingerprint({'renderer': adapter.version, 'files': files})

    def plan(self, target, options, palette):
        adapter = ADAPTERS[target]
        probe = self.ready(adapter)
        if self.store.load()['targets'].get(target, {}).get('edits'):
            raise Conflict('Target already has an enrollment; disable/remove it first')
        edits = adapter.plan(self.store, options)
        for item in edits:
            if item.get('kind') == 'gsettings':
                if item.get('dynamicScheme'):
                    item['after'] = repr('prefer-dark' if palette['dark'] else 'prefer-light')
                item['diff'] = 'GSettings ' + item['schema'] + ' ' + item['key'] + ': ' + item['before'] + ' → ' + item['after']
            elif item.get('kind') == 'symlink':
                item['parent'] = str(Path(item['path']).parent.resolve())
                item['diff'] = 'Create integration symlink: ' + item['path'] + ' -> ' + item['destination']
        self.render(adapter, palette)  # Refuse an enrollment whose output cannot render.
        plan = dict(target=target, edits=edits, options=options, probe=probe,
                    boundary=adapter.boundary, palette=palette['id'])
        plan['token'] = fingerprint(plan)
        return plan

    def enable(self, state, target, request, palette):
        plan = self.plan(target, request.get('options', {}), palette)
        if request.get('token') != plan['token']:
            raise Conflict('Enrollment preview changed; review the refreshed plan')
        record = dict(enabled=False, installed=False, phase='installing', edits=plan['edits'],
                      options=plan['options'], probe=plan['probe'], result='Installing', error='')
        state['targets'][target] = record
        # Journal intent BEFORE any application edit, including partial-failure recovery.
        self.store.save(state)
        adapter = ADAPTERS[target]
        files, digest = self.render(adapter, palette)
        if files:
            self.store.publish(target, files, digest)
        for item in record['edits']:
            if item.get('kind') == 'gsettings':
                if command(['gsettings', 'get', item['schema'], item['key']]) != item['before']:
                    raise Conflict('System appearance setting changed since preview')
                command(['gsettings', 'set', item['schema'], item['key'], item['after']])
            elif item.get('kind') == 'symlink':
                path = Path(item['path'])
                if path.exists() or path.is_symlink() or str(path.parent.resolve()) != item['parent']:
                    raise Conflict('Integration link precondition changed')
                path.parent.mkdir(parents=True, exist_ok=True)
                path.symlink_to(item['destination'])
            else:
                install(item)
        record.update(enabled=True, installed=True, phase='ready')
        self.store.save(state)
        self.apply_target(state, adapter, palette, force=True)
        if record.get('error'):
            record.update(enabled=False, phase='failed')
            self.store.save(state)

    def disable(self, state, target):
        record = state['targets'].setdefault(target, {})
        record['enabled'] = False  # Pause immediately even if cleanup conflicts.
        record['phase'] = 'removing'
        self.store.save(state)
        planned = []
        for item in record.get('edits', []):
            if item.get('kind') == 'gsettings':
                value = command(['gsettings', 'get', item['schema'], item['key']])
                if value == item['before']:
                    continue
                if value != item['after']:
                    raise Conflict('System appearance setting edited; updates stopped: ' + item['key'])
                planned.append((item, item['before']))
            elif item.get('kind') == 'symlink':
                path = Path(item['path'])
                if not path.exists() and not path.is_symlink():
                    continue
                if not path.is_symlink() or os.readlink(path) != item['destination'] or str(path.parent.resolve()) != item['parent']:
                    raise Conflict('Integration link changed; updates stopped, link retained')
                planned.append((item, None))
            else:
                planned.append((item, removal(item)))
        for item, text in planned:
            if item.get('kind') == 'gsettings':
                if command(['gsettings', 'get', item['schema'], item['key']]) != item['after']:
                    raise Conflict('System appearance setting changed during removal')
                command(['gsettings', 'set', item['schema'], item['key'], text])
                continue
            path = Path(item['path'])
            if item.get('kind') == 'symlink':
                path.unlink()
            else:
                # A final read guards against concurrent edits during removal planning.
                current = path.read_text() if path.exists() else ''
                if removal(item) != text:
                    raise Conflict('Configuration changed while removing integration')
                if current != text:
                    atomic(Path(item['resolved']), text)
        record.update(installed=False, edits=[], phase='disabled', error='',
                      result='Disabled — loaded colours may remain; ' + ADAPTERS[target].boundary)

    def apply_target(self, state, adapter, palette, force=False):
        target = adapter.id
        record = state['targets'][target]
        stage = 'detect'
        try:
            probe = self.ready(adapter)
            if target == 'zen' and probe.get('profile') != record.get('options', {}).get('confirmedProfile'):
                raise Conflict('Zen profile selection changed; new enrollment required')
            if record.get('probe', {}).get('resolved') != probe.get('resolved'):
                raise Conflict('Audited configuration identity changed; re-enroll target')
            stage = 'integration'
            self.check_hooks(record)
            stage = 'render'
            files, digest = self.render(adapter, palette)
            stage = 'publish'
            changed = self.store.publish(target, files, digest) if files else False
            record.update(desiredPalette=palette['id'], publishedPalette=palette['id'], generation=digest)
            if files:
                history = [g for g in record.get('generations', []) if g != digest] + [digest]
                # Current + previous; altered/unknown artifacts are never deleted.
                retained = [g for g in history[:-2] if not self.store.prune(target, g)]
                record['generations'] = retained + history[-2:]
            if target == 'fastfetch':
                ghostty = state['targets'].get('ghostty', {})
                if not ghostty.get('enabled') or ghostty.get('publishedPalette') != palette['id'] or ghostty.get('error'):
                    raise RuntimeError('Waiting for enabled Ghostty palette; Fastfetch has no independent RGB config')
            stage = 'activate'
            for item in record.get('edits', []):
                if item.get('dynamicScheme'):
                    desired = repr('prefer-dark' if palette['dark'] else 'prefer-light')
                    if item['after'] != desired:
                        command(['gsettings', 'set', item['schema'], item['key'], desired])
                        item['after'] = desired
                        self.store.save(state)
            if changed or force or record.get('error') or not record.get('result'):
                record['result'] = adapter.activate(self.store)
            record.update(error='', stage='ready', phase='ready', installed=True)
            # A generated palette is not a claim of visible application.
            record['appliedPalette'] = palette['id'] if target == 'magi' else None
        except Exception as error:
            record.update(error=str(error)[:800], stage=stage,
                          result='Ownership conflict' if isinstance(error, Conflict) else 'Failed')
        self.store.save(state)

    def status(self, state, palette):
        rows = []
        for target, adapter in ADAPTERS.items():
            record = state['targets'].get(target, {})
            probe = self.probe(adapter)
            rows.append(dict(id=target, label=adapter.label, compatibility=adapter.compatibility, **probe,
                             enabled=target == 'magi' or record.get('enabled', False),
                             installed=target == 'magi' or record.get('installed', False),
                             desiredPalette=palette['id'], publishedPalette=record.get('publishedPalette'),
                             appliedPalette=palette['id'] if target == 'magi' else record.get('appliedPalette'),
                             result='Applied — reactive palette' if target == 'magi' else record.get('result', 'Not enrolled'),
                             error=record.get('error', ''), boundary=adapter.boundary,
                             phase=record.get('phase', 'disabled')))
        for item in DEFERRED:
            rows.append(dict(item, available=False, configured=False, enabled=False, installed=False,
                             result='Deferred', error='', boundary='Deferred'))
        failures = [r['label'] for r in rows if r['enabled'] and r['error']]
        return dict(ok=True, targets=rows, palette=palette['id'],
                    summary=('Partial failure: ' + ', '.join(failures)) if failures else
                    'MAGI palette selected; see each target for reload/activation status')

    def perform(self, request):
        palette = resolve(request['theme'])
        op = request.get('op', 'status')
        target = request.get('target', '')
        with self.store.locked():
            state = self.store.load()
            if op == 'plan':
                if target not in ADAPTERS or target == 'magi':
                    raise ValueError('Invalid enrollment target')
                return dict(ok=True, plan=self.plan(target, request.get('options', {}), palette))
            if op in ('enable', 'disable', 'retry', 'resume') and (target not in ADAPTERS or target == 'magi'):
                raise ValueError('Invalid target')
            if op == 'enable':
                try:
                    self.enable(state, target, request, palette)
                except Exception as error:
                    record = state['targets'].setdefault(target, {})
                    record.update(error=str(error)[:800], result='Enrollment failed; disable to remove partial hooks')
                    self.store.save(state)
            elif op == 'resume':
                record = state['targets'].get(target, {})
                if not record.get('installed'):
                    raise Conflict('No complete integration to resume; review enrollment first')
                record['enabled'] = True
                self.apply_target(state, ADAPTERS[target], palette, force=True)
                if record.get('error'):
                    record.update(enabled=False, phase='failed')
                self.store.save(state)
            elif op == 'disable':
                try:
                    self.disable(state, target)
                except Exception as error:
                    state['targets'][target].update(error=str(error)[:800], result='Updates stopped; removal conflict')
                self.store.save(state)
            elif op in ('apply', 'retry'):
                for key, adapter in ADAPTERS.items():
                    if key == 'magi' or not state['targets'].get(key, {}).get('enabled'):
                        continue
                    if op == 'apply' or key == target:
                        self.apply_target(state, adapter, palette, force=op == 'retry')
            elif op != 'status':
                raise ValueError('Unknown theme operation')
            return self.status(state, palette)
