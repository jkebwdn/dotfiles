"""Render the reviewed temporary config; never write the live configuration."""
import re


def render(original, request_path):
    if not re.fullmatch(r"/[A-Za-z0-9_./-]+", request_path):
        raise ValueError("request path must be an absolute shell-safe path")
    changed, count = re.subn(r"(?m)^(\s*)lock_cmd\s*=.*$", lambda m: m[1] + "lock_cmd = " + request_path + " sleep-coordinated", original)
    if count != 1:
        raise ValueError("expected one lock_cmd")
    changed, count = re.subn(r"(?m)^(\s*)inhibit_sleep\s*=.*$", lambda m: m[1] + "inhibit_sleep = 3", changed)
    if count > 1:
        raise ValueError("multiple inhibit_sleep entries")
    if count == 0:
        changed = changed.replace(" sleep-coordinated\n", " sleep-coordinated\n    inhibit_sleep = 3\n", 1)
    return changed
