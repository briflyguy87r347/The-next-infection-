#!/usr/bin/env python3
"""Check that the Module 010 source repository has its required paths.

This is a static check, not a substitute for a Godot engine launch or on-device play.
"""
from pathlib import Path
import re
import sys
root = Path(__file__).resolve().parents[1]
assert (root / 'project.godot').is_file(), 'Missing project.godot'
assert (root / 'scenes/menu.tscn').is_file(), 'Missing menu scene'
assert (root / 'scenes/open_world.tscn').is_file(), 'Missing open-world scene'
assert (root / 'scenes/zombie.tscn').is_file(), 'Missing zombie scene'
assert (root / 'scripts/combat_director.gd').is_file(), 'Missing combat director'
assert (root / 'scripts/world_progress.gd').is_file(), 'Missing persistent world progress'
assert (root / 'scripts/open_world_controller.gd').is_file(), 'Missing open-world controller'
files = sorted(list(root.rglob('*.tscn')) + list(root.rglob('*.gd')))
missing=[]
for f in files:
    text=f.read_text(encoding='utf-8')
    for match in re.finditer(r'res://([A-Za-z0-9_./-]+)', text):
        target=match.group(1).rstrip('.,;')
        if not (root / target).exists() and not target.startswith('.godot/'):
            missing.append(f'{f.relative_to(root)} -> {target}')
if missing:
    print('Missing resource refs:')
    print('\n'.join(sorted(set(missing))))
    sys.exit(1)
print(f'PASS: {len(files)} scene/script files and local res:// paths checked; project source present.')
