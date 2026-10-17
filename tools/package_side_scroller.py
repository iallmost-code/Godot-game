#!/usr/bin/env python3
"""Build the standalone project ZIP, never a ZIP of the old crypt project."""
import argparse
import json
from pathlib import Path
import re
from zipfile import ZipFile, ZipInfo, ZIP_DEFLATED

root = Path(__file__).resolve().parents[1] / 'side_scroller'
parser = argparse.ArgumentParser()
parser.add_argument('--output', required=True, type=Path)
args = parser.parse_args()
required = ['project.godot', 'main.gd', 'main.tscn', 'README.md']
for name in required:
    if not (root / name).is_file():
        raise SystemExit(f'Missing required entry: {name}')
files = []
for path in sorted(root.rglob('*')):
    if not path.is_file() or any(part.startswith('.') for part in path.relative_to(root).parts):
        continue
    if path.suffix in {'.tmp', '.import'}:
        continue
    # Authored data is shipped; browser saves outside data/ remain excluded.
    if path.suffix == '.json':
        if path.parent != root / 'data':
            continue
        json.loads(path.read_text(encoding='utf-8'))
    if path.suffix not in {'.json', '.gd', '.godot', '.tscn', '.tres', '.md', '.svg', '.png', '.uid', '.ttf', '.gdshader'}:
        raise SystemExit(f'Unexpected project file: {path}')
    if path.suffix in {'.gd', '.tscn', '.godot', '.tres'}:
        text = path.read_text()
        for ref in re.findall(r'res://([A-Za-z0-9_./-]+\.(?:gdshader|gd|tscn|svg|png|tres|ttf))', text):
            if not (root / ref).is_file():
                raise SystemExit(f'Missing dependency {ref} referenced by {path.name}')
    files.append(path)
args.output.parent.mkdir(parents=True, exist_ok=True)
with ZipFile(args.output, 'w', ZIP_DEFLATED) as z:
    # Godot's Project Manager extracts files without recursively making their parents.
    directories = set()
    for path in files:
        parent = path.relative_to(root).parent
        while parent != Path('.'):
            directories.add(parent.as_posix() + '/')
            parent = parent.parent
    for name in sorted(directories, key=lambda n: (n.count('/'), n)):
        info = ZipInfo(name, date_time=(2026, 10, 13, 0, 0, 0))
        info.external_attr = (0o40755 << 16) | 0x10
        z.writestr(info, b'')
    for path in files:
        info = ZipInfo(path.relative_to(root).as_posix(), date_time=(2026, 10, 13, 0, 0, 0))
        info.compress_type = ZIP_DEFLATED
        info.external_attr = 0o100644 << 16
        z.writestr(info, path.read_bytes())
with ZipFile(args.output) as z:
    assert z.testzip() is None
    assert len(z.namelist()) == len(set(z.namelist()))
print(f'Verified {args.output}: {len(files)} files, {args.output.stat().st_size:,} bytes')
