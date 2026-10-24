"""Application background policy, independent of client/window opacity."""
import math
DEFAULT = dict(managed=False, backgroundOpacity=1.0, blurEnabled=True)

def normalize(value=None):
    if value is None: value = {}
    if not isinstance(value, dict) or set(value) - set(DEFAULT):
        raise ValueError('Unknown application appearance policy')
    result = {**DEFAULT, **value}
    for key in ('managed', 'blurEnabled'):
        if type(result[key]) is not bool: raise ValueError('Expected boolean: ' + key)
    v = result['backgroundOpacity']
    if type(v) not in (int, float) or not math.isfinite(v) or not .5 <= v <= 1:
        raise ValueError('Background opacity must be 50–100%')
    return result
