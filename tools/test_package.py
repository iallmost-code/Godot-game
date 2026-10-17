#!/usr/bin/env python3
"""Regression checks for an archive Godot's Web Editor can actually extract."""
from pathlib import Path
import subprocess
import sys
import tempfile
from zipfile import ZipFile
root=Path(__file__).resolve().parents[1]
with tempfile.TemporaryDirectory() as directory:
    output=Path(directory)/'project.zip'
    subprocess.run([sys.executable,str(root/'tools/package_side_scroller.py'),'--output',str(output)],check=True)
    with ZipFile(output) as z:
        names=set(z.namelist())
        assert z.testzip() is None
        assert {'project.godot','main.tscn','main.gd','README.md'}<=names
        assert {'art/warrior_atlas.png','art/sky.png','art/props.png','art/terrain.png','art/enemies.png','art/effects.png'}<=names
        assert {'art/sword_atlas.png','art/spear_atlas.png','art/thief_atlas.png','world/player_star.gd'}<=names
        assert {'art/rootwarden.png','art/briar_background.png','actors/rootwarden.gd','data/maps.gd','tests/test_bulk_stats.gd','tests/test_briar.gd'}<=names
        assert {'fonts/damage-bold.ttf','fonts/LICENSE.md','visuals/damage_gradient.gdshader','visuals/damage_number.gd','ui/map_panel.gd','ui/item_icon.gd'}<=names
        assert {'actors/boss.gd','world/summon.gd','visuals/mob_art.gd','data/enemy_stats.gd','tests/test_skills.gd','tests/test_roster.gd','tests/helpers.gd'}<=names
        assert b'Windswept' in z.read('project.godot')
        assert len(names)==len(z.namelist())
        assert not any('.godot/' in n or '.git/' in n or n.endswith('.json') for n in names)
        assert not any(n.startswith('side_scroller/') for n in names)
        for name in names:
            if '/' in name and not name.endswith('/'):
                parent=name.rsplit('/',1)[0]+'/'
                assert parent in names, f'Godot importer needs directory entry: {parent}'
        for source in (root/'side_scroller').rglob('*.gd'):
            if '.godot' not in source.parts:
                assert source.relative_to(root/'side_scroller').as_posix() in names
        with ZipFile(root/'Side-Scroller-Warrior.zip') as shipped:
            assert set(shipped.namelist()) == names, 'Shipped ZIP file list is stale'
            for name in names:
                assert shipped.read(name) == z.read(name), f'Shipped ZIP is stale: {name}'
print('PASS: ZIP integrity, root layout, all scripts, directory entries, cache/save exclusions, shipped source parity')
