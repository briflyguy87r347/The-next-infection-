# Module 005 — BLOCK ZERO & Zombie Rewards

The Next Infection / Outbreak Zero. Mobile-first Godot 4.x.

## Intellectual property

**BLOCK ZERO** is an original suburban combat arena inspired by the quick, close-range feel of small two-house multiplayer maps. It is *not* a copy of Activision's Nuketown map. Do not use Nuketown screenshots, floor plans, sounds, signage, or trademarked art as distributable assets. The original town features two row houses with open ground floors, a central road, a damaged evacuation shuttle and sedan, sidewalks, backyard cover, a perimeter fence, and three distinct stations. The upper house floors are exterior-only placeholder facades.

## Economy rules (prototype, not real money)

- Every zombie kill immediately grants **1 kill token**.
- Every zombie kill also bursts into **5 physical gold coins**, each worth **25 points**. Move close to collect them: up to **125 points per zombie**.
- Coins disappear after ~15 seconds if uncollected. Currency resets when the session restarts.
- The **Mystery Crate** costs **650 points** and gives a random different gun from a pool of 5; it refills that gun's magazine/reserve.
- The **Weapon Forge** increases damage for the *currently held* weapon by **35% per tier** (multiplicative). Cost progression per weapon: **500 → 1,000 → 2,000 → 4,000 → 8,000** points; maximum level 5. The magazine refills on successful upgrade.
- The **Medical Supply** box costs **3 kill tokens** to restore **65 health** (capped at maximum). Cannot buy when health is already full.
- Kill tokens cannot be bought using points and are not withdrawable real-world currencies. These are two prototype in-game resources.

## Mystery crate weapons

| Gun | Base damage | Magazine | Fire interval | Notes |
|---|---:|---:|---:|---|
| Service pistol | 34 | 12 | 0.23 s | Starter weapon |
| Rapid SMG | 23 | 28 | 0.105 s | Fast firing |
| Patrol rifle | 43 | 24 | 0.18 s | Medium fire rate |
| Breach shotgun | 16 per pellet | 6 | 0.78 s | 7 scattered ray pellets |
| Support LMG | 30 | 40 | 0.15 s | Large magazine |

Ammo is finite, but clearing each wave adds reserve ammo. Weapon levels remain distinct between guns during one session.

## Controls

- Android: joystick, look drag, FIRE, RELOAD, JUMP, SPRINT, and new **USE** touch control near the lower center.
- Desktop: WASD, mouse look, left-click FIRE, R RELOAD, E USE, Shift SPRINT, Space JUMP.
- Stand within ~3 meters of a color-coded station: blue = mystery crate, purple = weapon forge, green = medical supply. Read the prompt and tap USE.

## Test plan before merging

1. Load into Block Zero street with two building exteriors, road, vehicles and visible stations.
2. Keep the game open until first four zombies approach; verify the humanoid Module 004 zombie appearance remains.
3. Kill one zombie; verify five gold coins burst outward and the kill-token counter becomes 1.
4. Walk into the coins; verify point balance increments, up to 125 per kill.
5. Collect at least 650 points and test mystery crate by walking near blue box and tapping USE.
6. Reach 500 points and buy a first weapon upgrade; next cost should show 1,000 points for the same gun.
7. Let zombies lower health, earn 3 kill tokens, use the green medical station, and verify health increases by 65 up to max.
8. Verify FIRE/RELOAD, joystick and screen-look continue functioning; test at 8-16 zombies for frame rate.
9. Test three lives to check restarting, counters and wave progression.

## Known limitations

- This arena is an original **blockout**, not an asset-rich production map. Houses have accessible ground floors but upper floors are facade only. No interiors, stairs, sound effects or large outdoor streaming map yet.
- Zombies use direct pursuit rather than a navigation mesh. They may occasionally snag on houses or vehicles.
- Coins use inexpensive visual meshes without physics bodies. Coins can roll/bounce visually but do not obey real collision with walls.
- No real-money economy, wallet, persistence, cloud saves or multiplayer yet.
- Source and references are statically reviewed but **Godot import and Android runtime testing must still be performed** for this module.
