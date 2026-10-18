#!/usr/bin/env python3
"""Require passing checks AND no script errors; Godot can exit 0 after script errors."""
import os
from pathlib import Path
import subprocess
import sys
root=Path(__file__).resolve().parents[1]
environment=os.environ.copy()
for name,directory in [('XDG_CACHE_HOME','godot-cache'),('XDG_DATA_HOME','side-scroller-tests-data'),('XDG_CONFIG_HOME','side-scroller-tests-config')]:
    environment.setdefault(name,str(root.parent/'scratch'/directory))
    Path(environment[name]).mkdir(parents=True,exist_ok=True)
godot=os.environ.get('GODOT_BIN','/workspace/tools/bin/godot')
command=[godot,'--headless','--path',str(root/'side_scroller'),'--script','res://tests/runner.gd','--']+sys.argv[1:]
result=subprocess.run(command,env=environment,text=True,stdout=subprocess.PIPE,stderr=subprocess.STDOUT,timeout=int(environment.get("GODOT_TEST_TIMEOUT","240")))
print(result.stdout,end='')
if result.returncode or 'SCRIPT ERROR' in result.stdout or 'ERROR:' in result.stdout:
    raise SystemExit(1)
if 'RESULT:' not in result.stdout:
    raise SystemExit('Missing completed test summary')
