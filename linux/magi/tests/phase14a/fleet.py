#!/usr/bin/env python3
"""Reuse Phase10B's isolated window/service adapters with tray-specific assertions."""
from pathlib import Path
runner=Path(__file__).resolve().parents[1]/'phase10b/run.py'
source=runner.read_text()
source=source.replace("Path(__file__).with_name('lifecycle.qml')", "Path("+repr(str(Path(__file__).with_name('fleet.qml')))+")")
source=source.replace('Phase 10B lifecycle PASS','Phase14A fleet PASS')
exec(compile(source,str(runner),'exec'),{'__file__':str(runner),'__name__':'__main__'})
