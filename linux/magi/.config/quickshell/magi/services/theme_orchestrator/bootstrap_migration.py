"""Explicit, resumable conversion of journal-owned source edits to static hooks.

Never called by startup/status/apply. All source edits are preflighted before the
intent journal is saved; recovery accepts only exact pre/post bytes and identity.
"""
import copy
import re
from pathlib import Path
from . import bootstrap
from .storage import Conflict, atomic, identity, removal, text_hash


def converted(text, block, target, path, original):
    if 'MAGI BOOTSTRAP' in text:
        raise Conflict('Bootstrap already present in legacy source: ' + str(path))
    pattern = r'(?ms)^(?:#|--|/\*) MAGI THEME BEGIN(?: \*/)?\n.*?^(?:#|--|/\*) MAGI THEME END(?: \*/)?'
    if len(re.findall(pattern, text)) != 1:
        raise Conflict('Expected one journal-owned legacy block: ' + str(path))
    replacement = block
    if target == 'gtk' and path.name == 'settings.ini':
        match = re.findall(r'(?m)^gtk-theme-name=.*$', original)
        if len(match) != 1: raise Conflict('GTK fallback selection is ambiguous')
        replacement = block + '\n' + match[0]
    return re.sub(pattern, lambda _: replacement, text, count=1)


def migrate(orchestrator, state):
    store = orchestrator.store
    pending = state.get('bootstrapMigration')
    if not pending:
        proposals = []; replacements = {}
        for target in sorted(bootstrap.TARGETS):
            record = state['targets'].get(target, {})
            legacy = [i for i in record.get('edits', []) if i.get('kind') not in ('bootstrap','symlink','gsettings')]
            if not legacy: continue
            expected = bootstrap.blocks(store, target)
            if {i['path'] for i in legacy} != {str(p) for p in expected}:
                raise Conflict('Unexpected legacy source ownership: ' + target)
            orchestrator.check_hooks(record)
            canonical = []
            for item in legacy:
                path = Path(item['path']); before = path.read_text(); original = removal(item)
                after = converted(before, expected[path], target, path, original)
                proposals.append(dict(**identity(path), beforeHash=text_hash(before), after=after))
                canonical.append(dict(kind='bootstrap', **identity(path), block=expected[path]))
                if target == 'yazi' and path.name == 'theme.toml':
                    template = store.config/'yazi/magi-template.toml'
                    if template.exists() or template.is_symlink():
                        if template.is_symlink() or template.read_text() != original:
                            raise Conflict('Yazi source template already exists with different content')
                    else:
                        proposals.append(dict(**identity(template), beforeHash=None, after=original))
            replacements[target] = canonical + [i for i in record['edits'] if i not in legacy]
        if not proposals: return dict(ok=True, migrated=[])
        pending = dict(files=proposals, edits=replacements)
        state['bootstrapMigration'] = pending
        store.save(state)  # Recovery intent precedes any source write.
    # Preflight every remaining write before resuming any part of the transaction.
    for item in pending['files']:
        path = Path(item['path'])
        if identity(path) != {k:item[k] for k in ('path','resolved','link')}:
            raise Conflict('Migration source identity changed: ' + str(path))
        current = text_hash(path.read_text()) if path.exists() else None
        if current not in (item['beforeHash'], text_hash(item['after'])):
            raise Conflict('Migration source changed; retained for review: ' + str(path))
    for item in pending['files']:
        path = Path(item['path'])
        current = text_hash(path.read_text()) if path.exists() else None
        if current == text_hash(item['after']): continue
        if current != item['beforeHash']: raise Conflict('Concurrent migration edit: ' + str(path))
        atomic(Path(item['resolved']), item['after'])
    for target, edits in pending['edits'].items():
        bootstrap.records(store, target)
        state['targets'][target]['edits'] = edits
        state['targets'][target]['bootstrapVersion'] = 1
    migrated = sorted(pending['edits'])
    del state['bootstrapMigration']
    store.save(state)
    return dict(ok=True, migrated=migrated)
