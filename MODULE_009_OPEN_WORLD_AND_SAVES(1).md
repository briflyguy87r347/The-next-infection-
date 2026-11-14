# THE NEXT INFECTION — Module 009: Florida Open World

## What this prototype actually adds

**Two playable game modes remain separate:**
- **SURVIVAL ARENA:** timed/doubling zombie waves, run-specific points, permanent bank deposits on death/extraction, mystery box, weapon upgrades.
- **FLORIDA OPEN WORLD:** a larger, locally generated walkable/drivable district in either fictional Orlando-inspired Cypress Haven or Tampa-inspired Bayfront Yards. It uses the same crafted starting weapons and saved construction inventory.

The open world is an **offline vertical slice**, not Grand Theft Auto, an accurate Florida street map, or an online property market.

### Open-world controls

- **Movement:** left Android virtual joystick or desktop WASD.
- **Aim/look:** drag the right side of the screen. Tap `VIEW` for basic first-/third-person exploration, or use the standard first-person camera for shooting.
- **Vehicle:** walk within 4m of the salvage truck and press USE, or tap ENTER CAR. Joystick up accelerates; left/right steers; USE exits. Driving uses an arcade physics model, not realistic vehicle handling.
- **Fight:** FIRE, RELOAD, plus PUNCH / KICK / KNIFE buttons. Desktop keys R, F, G, V.
- **Salvage:** walk within approximately 5m of a plot's front salvage pile and press USE. The site recharges after 90 seconds. Collected parts and FAB are persisted immediately.
- **Build:** approach one of the 16 property plots in your selected city. Press BUILD, claim the plot with saved FAB tokens, then build generator/workshop/watchtower/cache. Constructions appear on that plot and persist locally.
- **Delivery mission:** collect supplies at the garage marker; travel to the clinic marker and press USE. Reward = 2 gun parts and 3 FAB, committed to your world save on delivery. Missions have 120-second cooldown after completion.
- **Travel:** CITY switches between locally generated Orlando and Tampa districts. This is a region switch, not a seamless real-life I-4 drive.
- **Return:** MENU returns to the main hub. This is the open-world mode; leaving it does **not** consume run bank points.

### Open-world boundaries and rendering

The project uses only a 4×4 core plot district and simple extra neighborhood chunks loaded near the player, bounded to a limited test area. It uses the GL Compatibility renderer and simple geometry. It is not a full persistent Florida map, has no physics vehicle traffic, AI survivors, server-shared territory, navigation meshes, or fully rigged production-quality models.

## Resource save correction

Previous builds only saved scavenged **gun parts** and **fabrication tokens** when the player extracted successfully. Now both resources are committed to `user://tni_world_progress_v1.json` **at pickup**, with pickup-ID deduplication and visible save failure messages. Survivor death will not erase successfully saved resources, whether in survival or roaming mode.

Permanent bank credits remain in `user://survival_bank_v1.json` and are still unavailable to spend during an active survival match. An open-world mission does not create match credits. Permanent guns and plots are stored in the world save.

### Transfer saves between imported ZIP builds

Because Android users often install multiple Godot projects, an explicit **SAVE & TRANSFER** tool was added to the main menu. Open the prior version, select **EXPORT & COPY SAVE**, paste the JSON into a private note, open the new version, and restore the pasted code. Do not assume Godot's per-project `user://` data directory is identical after importing under another folder. An import attempt makes a copy of the currently available save under `user://tni_before_restore.json`.

This is an offline local save, not cheat-proof, bank-grade storage, synchronized cloud save, or authenticated multi-user resource accounting. Multiplayer ownership and an economy involving real-world withdrawals require a server-authoritative ledger and a regulatory and platform-policy assessment.

## Android verification checklist

1. Import the **full** ZIP in a NEW folder and preserve Module 008 as your backup.
2. Launch the menu and select **FLORIDA OPEN WORLD**; verify player, minimap, on-foot HUD, and city scenery render.
3. Walk to the truck; enter and exit, drive/steer, and switch camera view.
4. Approach and interact with the garage, then clinic; verify mission reward increments permanent parts and FAB.
5. Salve a plot-front pile and verify inventory changes. Close and reopen project, verify balances remain. Try another version: export/import the save JSON if needed.
6. Visit the Florida district plot and build a generator. Exit/re-enter; structure should persist.
7. Shoot/knife roaming zombies and collect salvage. Check no GDScript errors under Godot's Debugger.
8. Test FPS on the user's Android tablet; optimize object counts before expanding the world.

## Long-term build sequence

**A.** A real character controller, navmesh for building/street zombies, combat polish, proper rigged 3D weapons and characters, sound, and usable vehicle cameras.

**B.** Larger interconnected city districts, dynamic events/quests, interiors, advanced construction placement, civilian/survivor NPCs and factions, day-night/weather, vehicle inventory, fuel and repairs. Use authored/fictitious geometry and appropriately licensed location reference data.

**C.** Authenticated multiplayer, authoritative property ownership, faction territory domination, player-made markets, anti-cheat and secure progression.

**D.** Review proposed cash-out/earnings separately for legal, platform and economic feasibility. In-game passive resources must not be advertised as guaranteed real-money dividends.

## Testing limitation

This package has been statically checked for file paths and save-API continuity. The build container for this conversation does not have a Godot executable or external download access. **Godot gameplay/runtime checks must be run on the Android device** before merging to the main GitHub branch.
