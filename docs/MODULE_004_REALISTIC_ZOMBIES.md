# THE NEXT INFECTION — Module 004, humanoid zombie visual upgrade

Works with Module 003 combat. Replaces **only** `scripts/zombie.gd` and `scenes/zombie.tscn`, and adds three original PNG textures.

## What changes
- Replaces the featureless green capsule mesh with a textured human-like silhouette: torso, neck, skull, face, damaged clothing, arms, legs and shoes.
- Four color/appearance variants, slightly different movement speeds and limps.
- Animated walk, shoulder sway, arms reaching forward when attacking, hit flinch and a short death fall.
- Facial details are hidden past 14 metres from the player for mobile performance.
- The original `OutbreakZombie`, `take_damage`, `defeated`, `attack_landed`, and player targeting API remain compatible with Module 003.

## Deliberate limits
This is a **procedural low-poly humanoid** upgrade for a budget Android device, not a photorealistic scanned character or a skeletal animation system. Zombies still chase in a straight line and may collide with obstacles. The body is animated by rotating simple nodes, not motion capture or ragdoll physics.

## Safe integration via Codespaces
1. On `feature/module-003-combat`, create a new branch `feature/module-004-zombie-visuals`.
2. Upload this ZIP to Codespaces, not into your installed Godot scene.
3. Inspect with `unzip -l TNI_Module_004_Realistic_Zombies.zip`.
4. Back up the existing files: `cp scripts/zombie.gd /tmp/tni-zombie003.gd && cp scenes/zombie.tscn /tmp/tni-zombie003.tscn`.
5. Extract the five files from the ZIP into the repository root: `unzip -o TNI_Module_004_Realistic_Zombies.zip`.
6. Test: `godot --headless --editor --path . --quit` (or use the full path to your Godot binary), then `godot --headless --path . --quit-after 180`.
7. Review `git diff --stat` and commit only the new/changed `scripts/zombie.gd`, `scenes/zombie.tscn`, `assets/zombies/`, and `docs/MODULE_004_REALISTIC_ZOMBIES.md`.
8. Test in Android Godot before merging.

## Visual upgrade beyond Module 004
For film-level realism, replace the procedurally generated Body rig with original or properly licensed optimized skinned zombie GLB assets (PBR textures, normal maps, LODs, walk/attack/death clips). Keep the existing physics and combat API in `zombie.gd` intact.
