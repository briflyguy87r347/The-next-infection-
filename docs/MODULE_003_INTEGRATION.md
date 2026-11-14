# Module 003 — Existing repository audit and safe integration

Date: 2026-11-14
Repository: `briflyguy87r347/The-next-infection-`
Existing branch inspected: `main`; head commit: `a5143d93e5676a1d1bb0c74be41675f75e3e5961`.

## What was inspected

The original tree contains `README.md`, `project.godot`, `scenes/main.tscn`, `scenes/hud.tscn`, `scenes/player.tscn`, `scripts/main.gd`, `scripts/hud.gd`, `scripts/player.gd`, plus the binary `TNI_Outbreak_Zero_02.zip`.

The binary ZIP could not be decoded by the connected GitHub reader, so it was not incorporated or changed. The exact original `project.godot`, player script, and three scene files were preserved in the full test project. Original `main.gd` and `hud.gd` were minimally extended.

## Confirmed bug fixed

- `scripts/main.gd` originally called `hud.set_health(player.health, player.max_health)`, but the player script exports `maximum_health`. Module 003 changes this to `player.maximum_health`.

## Functionality added in source

- `scripts/combat_director.gd`: orchestrates combat, raycast shooting, clip/reserve ammunition, reloading, capped wave spawning, GUI readouts, game-over restart.
- `scripts/zombie.gd` and `scenes/zombie.tscn`: capsule enemy chases the player, deals proximity damage, receives hits, and emits death/attack signals.
- `scripts/hud.gd`: FIRE and RELOAD touch controls using the existing multitouch role system.
- `scripts/main.gd`: attaches combat director to the existing player and HUD once they are created.

## Integration through GitHub Codespaces

Start a Codespace on the existing repository. In the **Codespace terminal**, from the repository root, run:

```bash
git checkout main
git pull --ff-only
git checkout -b tni/module-003-combat
```

Upload `TNI_Module_003_Overlay.zip` to the Codespace using its Files/Explorer view. From the repository root, run (adjust upload path if needed):

```bash
unzip -o TNI_Module_003_Overlay.zip
git status
git diff -- scripts/main.gd scripts/hud.gd
git add scripts/main.gd scripts/hud.gd scripts/combat_director.gd scripts/zombie.gd scenes/zombie.tscn docs/MODULE_003_INTEGRATION.md
git commit -m "Add isolated wave combat module for Outbreak Zero"
git push -u origin tni/module-003-combat
```

Then open a pull request on GitHub into `main`. Do not merge until Godot tests pass. Avoid uploading the **full** ZIP contents onto `main` because the overlay is explicitly designed to minimize changes.

## Minimum Godot test plan

1. Godot 4 loads `project.godot` and resolves every script without parse errors.
2. The scene opens with the original 3D arena, player movement and camera working.
3. Health HUD displays `100 / 100` on startup (verifies bug fix).
4. First round spawns four green capsule zombies.
5. Mouse/phone drag aims; FIRE or held left mouse shoots; crosshair in center.
6. Two successful hits defeat one zombie (34 x 2 damage versus 68 health), assuming all shots hit.
7. Zombies can damage health if they reach the player; killing all spawns the next round.
8. Ammo falls from 12 toward zero, reload transfers up to 12 bullets from reserve. A cleared wave replenishes 36 reserve bullets, capped at 120.
9. At zero health, the game restarts after approximately 3 seconds.
10. On tablet, verify simultaneous thumb movement + look drag + FIRE and acceptable performance.

## Limitations / risks

- No headless Godot executable was available during preparation. Runtime or Android correctness is **not verified**.
- Zombies use direct pursuit, not pathfinding; they can get stuck against obstacles.
- Only temporary combat state is stored; no economy, saving, authentication, persistence, multiplayer, or ownership logic.
- Arena has no boundary walls; player can walk off the floor.
- Art and sound are placeholders. No Play Store export is configured.
- The GitHub connection returned HTTP 403 (`Resource not accessible by integration`) for both branch creation and file writing. No files or commits were changed on GitHub by this assistant.
