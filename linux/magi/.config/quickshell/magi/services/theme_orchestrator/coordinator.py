"""Serialized per-target publication, enrollment and truthful activation results."""
import json
import os
from pathlib import Path
from .adapters import ADAPTERS, DEFERRED
from .adapters.base import command
from .palette import resolve, fingerprint
from .storage import Conflict, atomic, install, removal, text_hash, sync_directory
from . import bootstrap


class Orchestrator:
    def __init__(self, store, executor=None):
        self.store = store
        from theme_activation.coordinator import ThemeActivationCoordinator
        self.activation = ThemeActivationCoordinator(self, executor)

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
            if item.get('kind') == 'bootstrap':
                bootstrap.verify(item)
            elif item.get('kind') == 'gsettings':
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

    def render(self, adapter, palette, appearance=None):
        if adapter.id == 'ghostty':
            policy = self.store.load().get('applicationAppearance') if appearance is None else appearance
            files = adapter.render(palette, self.store, policy)
        else:
            files = adapter.render(palette, self.store)
        if files:
            files['palette.json'] = json.dumps(palette, sort_keys=True, indent=2) + '\n'
        return files, fingerprint({'renderer': adapter.version, 'files': files})

    def plan(self, target, options, palette):
        adapter = ADAPTERS[target]
        probe = self.ready(adapter)
        if self.store.load()['targets'].get(target, {}).get('edits'):
            raise Conflict('Target already has an enrollment; disable/remove it first')
        canonical = bootstrap.records(self.store, target)
        edits = bootstrap.runtime_plan(self.store, target, canonical, command) if canonical else adapter.plan(self.store, options)
        for item in edits:
            if item.get('kind') not in ('bootstrap', 'gsettings', 'symlink') and bootstrap.inside_git(item['resolved']):
                raise Conflict('Tracked source requires a canonical static bootstrap: ' + item['path'])
        for item in edits:
            if item.get('kind') == 'bootstrap':
                item['diff'] = 'Use read-only canonical bootstrap: ' + item['path']
            elif item.get('kind') == 'gsettings':
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
        adapter.validate(files)
        if files:
            self.store.publish(target, files, digest)
        for item in record['edits']:
            if item.get('kind') == 'bootstrap':
                bootstrap.verify(item)
            elif item.get('kind') == 'gsettings':
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
        if target == 'ghostty' and state.get('applicationAppearance', {}).get('managed'):
            raise Conflict('Release application appearance before removing Ghostty integration')
        record = state['targets'].setdefault(target, {})
        if any(i.get('kind') not in ('bootstrap', 'gsettings', 'symlink')
               and bootstrap.inside_git(i['resolved']) for i in record.get('edits', [])):
            raise Conflict('Migrate legacy checkout integration before disabling it')
        record['enabled'] = False  # Pause immediately even if cleanup conflicts.
        record['phase'] = 'removing'
        self.store.save(state)
        planned = []
        canonical = any(i.get('kind') == 'bootstrap' for i in record.get('edits', []))
        if canonical:
            self.activation.snapshot(target)  # Refuse edited output before runtime cleanup.
        for item in record.get('edits', []):
            if item.get('kind') == 'bootstrap':
                bootstrap.verify(item)
            elif item.get('kind') == 'gsettings':
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
        if canonical:
            pointer = self.store.current(target)
            if pointer.is_symlink():
                pointer.unlink()
                sync_directory(pointer.parent)
        record.update(installed=False, edits=[], phase='disabled', error='',
                      result='Disabled — loaded colours may remain; ' + ADAPTERS[target].boundary)

    def activate_scheme(self, record, palette):
        for item in record.get('edits', []):
            if item.get('dynamicScheme'):
                desired = repr('prefer-dark' if palette['dark'] else 'prefer-light')
                if item['after'] != desired:
                    command(['gsettings', 'set', item['schema'], item['key'], desired])
                    item['after'] = desired

    def apply_target(self, state, adapter, palette, force=False):
        return self.activation.apply(state, {adapter.id: adapter}, palette, force)

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
                             phase=record.get('phase', 'disabled'),
                             activationKind=adapter.capability.kind, automaticSafe=adapter.capability.automatic,
                             statusLabel='Live' if target == 'magi' else record.get('activation', {}).get('label', ''),
                             activationGeneration=record.get('activation', {}).get('generation', ''),
                             activationDetail=record.get('activation', {}).get('detail', adapter.capability.detail)))
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
            if op == 'migrate-bootstrap':
                if state.get('applicationAppearancePending'):
                    raise Conflict('Recover pending appearance transaction first')
                from .bootstrap_migration import migrate
                return migrate(self, state)
            if state.get('bootstrapMigration'):
                raise Conflict('Complete pending bootstrap migration before theme operations')
            if op == 'application-appearance':
                from application_appearance.coordinator import ApplicationAppearanceCoordinator
                from application_appearance.executor import BlurExecutor
                before = state['targets'].get('ghostty', {}).get('generation')
                outcome = ApplicationAppearanceCoordinator(self, BlurExecutor(), validator=ADAPTERS['ghostty'].validate).apply(state, request.get('policy'), palette)
                if outcome.get('ok') and outcome.get('status') != 'released':
                    state = self.store.load()
                    record = state['targets']['ghostty']
                    from .palette import fingerprint as generation_id
                    generation = generation_id([palette['fingerprint'],state.get('applicationAppearance'),record['generation']])
                    candidates = {'ghostty':dict(adapter=ADAPTERS['ghostty'],digest=record['generation'],record=record,palette=palette)}
                    activation = self.activation.activate_published(candidates,generation,
                        changed={'ghostty':before != record['generation']})
                    self.store.save(state)
                    row = activation.get('targets', {}).get('ghostty', {})
                    outcome.update(status=row.get('status','reload-required'), activation=row,
                                   error=row.get('detail','') if row.get('status')=='error' else '')
                return outcome
            if state.get('applicationAppearancePending'):
                raise Conflict('Recover pending application appearance transaction before theme updates')
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
                selected = {key: adapter for key, adapter in ADAPTERS.items()
                            if key != 'magi' and state['targets'].get(key, {}).get('enabled')
                            and (op == 'apply' or key == target)}
                self.activation.apply(state, selected, palette, force=op == 'retry')
            elif op != 'status':
                raise ValueError('Unknown theme operation')
            return self.status(state, palette)
