#!/usr/bin/env python3
"""Explicit-location Open-Meteo summary. Stdlib only; no location discovery.

One bounded helper per refresh; cache contains only the latest location/observation.
Network errors never echo the query, URL or provider payload into the shell.
"""
import hashlib
import json
import math
import os
from pathlib import Path
import sys
import time
from urllib.parse import urlencode
from urllib.request import Request, urlopen

REFRESH_SECONDS = 30 * 60
MAX_AGE = 3 * 60 * 60
TIMEOUT = 8
MAX_RESPONSE = 128 * 1024


def condition(code):
    if code == 0: return "Clear"
    if code == 1: return "Mostly clear"
    if code == 2: return "Partly cloudy"
    if code == 3: return "Cloudy"
    if code in (45, 48): return "Foggy"
    if code in (51, 53, 55): return "Drizzle"
    if code in (56, 57, 66, 67): return "Freezing rain"
    if code in (61, 63, 65, 80, 81, 82): return "Rainy"
    if code in (71, 73, 75, 77, 85, 86): return "Snowy"
    if code in (95, 96, 97, 99): return "Thunderstorms"
    raise ValueError("Unknown weather condition")


def number(value, low, high):
    if isinstance(value, bool) or not isinstance(value, (int, float)) or not math.isfinite(value) or not low <= value <= high:
        raise ValueError("Invalid weather response")
    return value


def request(endpoint, params):
    req = Request(endpoint + "?" + urlencode(params), headers={"User-Agent": "MAGI-Weather/1", "Accept": "application/json"})
    with urlopen(req, timeout=TIMEOUT) as response:
        data = response.read(MAX_RESPONSE + 1)
    if len(data) > MAX_RESPONSE: raise ValueError("Invalid weather response")
    result = json.loads(data)
    if not isinstance(result, dict) or result.get("error"): raise ValueError("Invalid weather response")
    return result


def resolve(data):
    results = data.get("results", [])
    if not results: raise ValueError("Location not found")
    place = results[0]
    return {"latitude": number(place["latitude"], -90, 90), "longitude": number(place["longitude"], -180, 180),
            "name": ", ".join(str(place[k]) for k in ("name", "admin1", "country") if place.get(k))[:200]}


def observation(data, now):
    current = data["current"]
    temperature = number(current["temperature_2m"], -100, 70)  # cache always Celsius
    code = number(current["weather_code"], 0, 99)
    condition(code)
    observed = number(current["time"], now - MAX_AGE, now + 900)
    if data.get("current_units", {}).get("temperature_2m") != "°C": raise ValueError("Invalid weather units")
    return {"temperature": temperature, "code": code, "observed": observed, "fetched": now}


def present(cached, units, error=""):
    temp = cached["temperature"]
    if units == "imperial": temp = temp * 9 / 5 + 32
    return {"summary": f'{condition(cached["code"])} · {math.floor(temp + .5)}°' + ("F" if units == "imperial" else "C"),
            "resolvedLocation": cached["place"]["name"], "observed": cached["observed"], "error": error}


def fetch(config, cache_path, now=None, get=request):
    now = time.time() if now is None else now
    if not config.get("enabled"): return {"summary": "", "error": "Weather is disabled"}
    location = config.get("location", "").strip()
    if not location: return {"summary": "", "error": "Set a weather location"}
    if len(location) > 160 or config.get("units") not in ("metric", "imperial"):
        return {"summary": "", "error": "Invalid weather configuration"}
    key = hashlib.sha256(location.encode()).hexdigest()
    cached = {}
    try:
        saved = json.loads(cache_path.read_text())
        if saved.get("key") == key:
            # Validate cached fields before accepting them as an observation.
            number(saved["temperature"], -100, 70); condition(saved["code"])
            number(saved["observed"], 0, now + 900); number(saved["fetched"], 0, now)
            resolve({"results": [saved["place"]]})
            cached = saved
    except (OSError, ValueError, KeyError, TypeError): pass
    fresh = cached and 0 <= now - cached["observed"] <= MAX_AGE
    if fresh and now - cached["fetched"] < REFRESH_SECONDS:
        return present(cached, config["units"])
    try:
        place = cached.get("place") or resolve(get("https://geocoding-api.open-meteo.com/v1/search",
            {"name": location, "count": 1, "language": "en", "format": "json"}))
        data = get("https://api.open-meteo.com/v1/forecast", {"latitude": place["latitude"], "longitude": place["longitude"],
            "current": "temperature_2m,weather_code", "temperature_unit": "celsius", "timeformat": "unixtime", "forecast_days": 1})
        result = dict(observation(data, now), place=place, key=key)
        try:
            cache_path.parent.mkdir(parents=True, exist_ok=True, mode=0o700)
            temp = cache_path.with_suffix(".tmp")
            fd = os.open(temp, os.O_WRONLY | os.O_CREAT | os.O_TRUNC, 0o600)
            with os.fdopen(fd, "w") as stream: json.dump(result, stream)
            temp.replace(cache_path)
        except OSError: pass  # read-only cache must not discard a valid observation
        return present(result, config["units"])
    except Exception as error:
        message = "Location not found" if isinstance(error, ValueError) and str(error) == "Location not found" else "Weather refresh unavailable"
        return present(cached, config["units"], message) if fresh else {"summary": "", "error": message}


if __name__ == "__main__":
    try:
        config = json.loads(sys.stdin.readline(4096))
        cache = Path(os.environ.get("XDG_CACHE_HOME", str(Path.home() / ".cache"))) / "magi/weather/current.json"
        result = fetch(config, cache)
    except Exception:
        result = {"summary": "", "error": "Weather refresh unavailable"}
    print(json.dumps(result, ensure_ascii=False))
