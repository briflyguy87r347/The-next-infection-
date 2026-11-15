# Module 010 — Android acceptance checklist and development notes

## Startup
- [ ] Godot 4.7.x imports the project with zero parse errors.
- [ ] Main menu opens; existing Orlando/Tampa navigation and saved resources appear.
- [ ] The game runs at an acceptable frame rate on the Android tablet; measure under several enemies.

## Loadout and persistence
- [ ] Fresh save: secondary slot 2 holds pistol, slots 1 and 3 are empty.
- [ ] Craft another gun in Gunsmith; equip it to slot 1; equip a third gun to slot 3.
- [ ] Restart project; confirm ownership, slot positions, and permanent levels are retained.
- [ ] Switching 1→2→1 retains the remaining bullets in slot 1 within the same scene.
- [ ] Switching guns cancels a previous reload, and gun magazines are independent.
- [ ] Clearing a slot doesn't destroy ownership.
- [ ] Upgrading an owned gun spends gun parts/FAB once, saves the level, and affects damage in both modes.
- [ ] Module 009 exported backup restores old inventory and starts a valid 3-slot layout.
- [ ] Save failure results in an error message rather than false success.

## Shooting and zombies
- [ ] On phone ADS hold narrows FOV, aligns the gun; releasing ADS restores view.
- [ ] Gun model changes for pistol/SMG/rifle/shotgun/LMG.
- [ ] Fire uses ammunition and shows a muzzle flash/recoil; reload takes time and animates.
- [ ] Bullets striking a zombie high in the head deal double damage.
- [ ] Walkers, Runners, Brutes have different speed/health; attacks have windup and do not damage instantly on reach.
- [ ] FPS with several zombies should remain usable; steer around a static obstacle (not guaranteed pathfinding).

## Economy and progression
- [ ] Every arena starts with 0 match points; bank balance is separate and untouched.
- [ ] Defeated zombies drop collectible match coins; each successive wave doubles total zombies.
- [ ] Mystery Box (650 match points) shows preview; EQUIP slot 1/2/3 replaces only that slot; DECLINE works.
- [ ] Match Mystery Box gun is lost after death/extraction, owned Gunsmith guns persist.
- [ ] Upgrade box doubles each subsequent **match** upgrade cost; permanent Gunsmith levels survive.
- [ ] Unspent match points deposit **once** after death or extraction, not on early QUIT RUN.
- [ ] Gun parts/FAB collected in open world persist after a scene restart; old Module 009 properties remain.

## Safehouse, menus, and driving
- [ ] From open world Orlando walk to SAFEHOUSE marker, tap ARMORY to open Gunsmith.
- [ ] Gunsmith ENTER OPEN WORLD returns to your saved region, not a new empty project.
- [ ] MENU/VIEW/MISSIONS/BUILD/CAR/EXIT and driving remain operational.
- [ ] Main Menu and save/export/restore remain operational.

## Boundaries and design honesty
- Procedural silhouettes and textures are placeholders pending original/licensed professional rigged assets.
- Static obstruction steering is not equivalent to a baked NavigationMesh.
- No authenticated multiplayer economy, trade, or cash-out system has been implemented.
- Test data is stored in Godot `user://` save locations. Each imported project may expose different save contexts, so export a backup before switching ZIP projects.
