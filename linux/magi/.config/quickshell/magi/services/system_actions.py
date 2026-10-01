#!/usr/bin/env python3
"""Bounded adapters for MAGI quick actions.

Every subprocess uses an argument vector.  Destructive session actions are
separate operations so QML can require an explicit second activation first.
"""
import json
import os
from pathlib import Path
import re
import shutil
import subprocess
import sys


def run(args):
    return subprocess.run(args, text=True, capture_output=True, timeout=8)


def result(available=False, active=False, **values):
    return {"available": bool(available), "active": bool(active), **values}


def power_status():
    executable = shutil.which("powerprofilesctl")
    if executable:
        current = run([executable, "get"])
        listed = run([executable, "list"])
        profiles = re.findall(r"^\s*\*?\s*([a-z][a-z0-9-]+):", listed.stdout, re.M)
        name = current.stdout.strip()
        return result(current.returncode == 0 and "power-saver" in profiles,
                      name == "power-saver", profile=name, profiles=profiles,
                      backend="power-profiles-daemon")
    path = Path(os.environ.get("MAGI_PLATFORM_PROFILE", "/sys/firmware/acpi/platform_profile"))
    choices = path.with_name("platform_profile_choices")
    try:
        profile = path.read_text().strip()
        profiles = choices.read_text().split()
        writable = os.access(path, os.W_OK)
        return result(writable and "low-power" in profiles, profile == "low-power",
                      profile=profile, profiles=profiles, backend="platform-profile",
                      reason="" if writable else "Platform profile is read-only")
    except OSError:
        return result(reason="No supported power-profile backend", profile="", profiles=[])


def power_set(profile):
    status = power_status()
    if not status["available"] or profile not in status.get("profiles", []):
        return {**status, "ok": False, "error": status.get("reason", "Profile unavailable")}
    executable = shutil.which("powerprofilesctl")
    if executable:
        changed = run([executable, "set", profile])
        if changed.returncode: return {**status, "ok": False, "error": changed.stderr.strip()}
    else:
        Path(os.environ.get("MAGI_PLATFORM_PROFILE", "/sys/firmware/acpi/platform_profile")).write_text(profile)
    return {**power_status(), "ok": True}


def vpn_profiles():
    executable = shutil.which("nmcli")
    if not executable: return result(reason="NetworkManager client unavailable", profiles=[])
    all_profiles = run([executable, "-t", "--escape", "no", "-f", "UUID,TYPE,NAME", "connection", "show"])
    active_profiles = run([executable, "-t", "--escape", "no", "-f", "UUID", "connection", "show", "--active"])
    if all_profiles.returncode: return result(reason=all_profiles.stderr.strip(), profiles=[])
    active = set(active_profiles.stdout.split())
    profiles = []
    for line in all_profiles.stdout.splitlines():
        fields = line.split(":", 2)
        if len(fields) == 3 and fields[1] in ("vpn", "wireguard"):
            profiles.append({"uuid": fields[0], "type": fields[1], "name": fields[2], "active": fields[0] in active})
    selected = next((p for p in profiles if p["active"]), profiles[0] if profiles else None)
    return result(bool(profiles), bool(selected and selected["active"]), profiles=profiles,
                  uuid=selected["uuid"] if selected else "", name=selected["name"] if selected else "",
                  reason="" if profiles else "No configured VPN profile")


def vpn_set(uuid, enabled):
    status = vpn_profiles()
    profile = next((p for p in status.get("profiles", []) if p["uuid"] == uuid), None)
    if not profile: return {**status, "ok": False, "error": "Unknown VPN profile"}
    executable = shutil.which("nmcli")
    command = [executable, "connection", "up" if enabled else "down", "uuid", uuid]
    changed = run(command)
    if changed.returncode: return {**status, "ok": False, "error": changed.stderr.strip()}
    return {**vpn_profiles(), "ok": True}


def dnd_status():
    executable = shutil.which("swaync-client")
    if not executable: return result(reason="No supported notification DND adapter")
    queried = run([executable, "-D"])
    if queried.returncode: return result(reason=queried.stderr.strip())
    value = queried.stdout.strip().lower()
    return result(value in ("true", "false"), value == "true", backend="swaync")


def dnd_set(enabled):
    status = dnd_status()
    if not status["available"]: return {**status, "ok": False, "error": status.get("reason", "DND unavailable")}
    changed = run([shutil.which("swaync-client"), "-dn" if enabled else "-df"])
    if changed.returncode: return {**status, "ok": False, "error": changed.stderr.strip()}
    return {**dnd_status(), "ok": True}


def can_login_action(method):
    executable = shutil.which("busctl")
    if not executable: return False
    checked = run([executable, "call", "org.freedesktop.login1", "/org/freedesktop/login1",
                   "org.freedesktop.login1.Manager", method])
    return checked.returncode == 0 and any(word in checked.stdout.lower() for word in ('"yes"', '"challenge"'))


def action_status():
    return {"available": True, "lock": bool(shutil.which("loginctl")),
            "hibernate": can_login_action("CanHibernate"), "shutdown": can_login_action("CanPowerOff")}


def execute_action(name):
    commands = {"lock": ["loginctl", "lock-session"],
                "hibernate": ["systemctl", "hibernate"], "shutdown": ["systemctl", "poweroff"]}
    if name not in commands: raise ValueError("Unknown system action")
    if os.environ.get("MAGI_ACTION_DRY_RUN") == "1": return {"ok": True, "dryRun": True, "command": commands[name]}
    executable = shutil.which(commands[name][0])
    if not executable: return {"ok": False, "error": "System action is unavailable"}
    completed = run([executable, *commands[name][1:]])
    return {"ok": completed.returncode == 0, "error": completed.stderr.strip() if completed.returncode else ""}


def perform(request):
    operation = request.get("op")
    if operation == "power-status": return power_status()
    if operation == "power-set": return power_set(request.get("profile", ""))
    if operation == "vpn-status": return vpn_profiles()
    if operation == "vpn-set": return vpn_set(request.get("uuid", ""), bool(request.get("enabled")))
    if operation == "dnd-status": return dnd_status()
    if operation == "dnd-set": return dnd_set(bool(request.get("enabled")))
    if operation == "action-status": return action_status()
    if operation == "action": return execute_action(request.get("name", ""))
    raise ValueError("Unknown operation")


if __name__ == "__main__":
    try: response = {"ok": True, **perform(json.loads(sys.stdin.readline()))}
    except Exception as error: response = {"ok": False, "error": str(error)}
    print(json.dumps(response), flush=True)
