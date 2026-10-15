#!/usr/bin/env python3
"""One JSON request per process; no shell interpolation or browser data discovery."""
import json
import sys
from theme_orchestrator.coordinator import Orchestrator
from theme_orchestrator.storage import Store

if __name__ == '__main__':
    try:
        request = json.loads(sys.stdin.readline(1024 * 1024))
        result = Orchestrator(Store()).perform(request)
    except Exception as error:
        result = {'ok': False, 'error': str(error)[:800]}
    print(json.dumps(result))
