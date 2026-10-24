"""Only the fixed, Ghostty-specific exclusion handle can be toggled."""
from .policy import normalize
RULE = 'magi-ghostty-background-no-blur'
HANDLE = 'magi_application_background'

def plan(policy):
    p = normalize(policy)
    return dict(policy=p, blurExcluded=p['managed'] and not p['blurEnabled'],
                target='ghostty', activation='reload-required')

def toggle_lua(enabled):
    if type(enabled) is not bool: raise ValueError('Invalid rule state')
    return HANDLE + '.rule:set_enabled(' + ('true' if enabled else 'false') + ')'
