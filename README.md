# THE NEXT INFECTION — OUTBREAK ZERO / Module 010

**Android-first playable development project based on Module 009.** Engine: Godot 4.x, Compatibility renderer. New systems are a gameplay prototype, **not high-budget photorealistic art**, and still require a real-device test.

## What's actually implemented

- Three firearm slots in **FLORIDA OPEN WORLD** and **SURVIVAL ARENA**. Touch buttons labeled `1 / 2 / 3`; desktop keyboard `1`, `2`, `3`. Default slot 2 contains a permanent Service Pistol; slots 1 and 3 begin empty.
- Gunsmith crafts guns using permanently saved gun parts and FAB, and can equip each owned gun in any one of the three slots. Purchased gun identities and saved slot choices survive game restarts. **Guns cannot occupy two permanent slots at once.**
- Each active scene keeps a separate magazine and reserve ammunition for each gun slot. Switching guns does not create extra ammo. On entering a *new* scene/run, ammo is freshly initialized; it is not a persistent ammo stockpile.
- Gunsmith can **permanently upgrade** an owned gun to level 3 for parts and FAB. Permanent upgrades add damage in both modes. Arena weapon station upgrades remain **match-only** and its point cost doubles with each in-match upgrade for that gun.
- Better-differentiated **original lightweight procedural** gun silhouettes with front/rear sights, receiver, grip, support hand, ammunition magazine, muzzle flash, recoil, aim-down-sights and reload movement. They are not professionally rigged gun assets.
- **ADS** touch button (hold) and desktop right mouse button: narrows the view, weapon moves toward center, and bullet spread decreases.
- Zombies now have **Walker, Runner, Brute** behavior profiles, delayed reach attacks, cheap obstruction steering, hit flinch, animated falls and approximate 2× headshots. They still use original procedural humanoids—not photorealistic characters and not true baked navmesh pathfinding.
- Mystery Box displays its result without automatically overwriting the current firearm. Choose **EQUIP 1**, **EQUIP 2**, **EQUIP 3** or **DECLINE**. These rewards are match-only, and a rejected reward is not refunded.
- New **ARMORY** shortcut near the Orlando open-world SAFEHOUSE marker; keeps the original healing rest interaction. Gunsmith has **ENTER OPEN WORLD** option.
- Slightly more detailed original asphalt/concrete surface textures to reduce flatness while remaining mobile-friendly.
- Previous Module 009 plot ownership, driving, deliveries, gun-parts/FAB pickup saves, Survival Bank, doubling zombie waves and building remain present.

## How to import on Android

1. **Protect old progress first.** From your working Module 009 main menu, open **WORLD SAVE BACKUP & RESTORE**. Choose **EXPORT & COPY SAVE**. Paste the JSON into a private text note before importing a new ZIP. Do not share it publicly.
2. Keep your working Module 009 project installed. Open Godot → **Project → Quit to Project List** → **Import**.
3. Browse to `/storage/emulated/0/Download` and choose `TNI_Outbreak_Zero_Module_010_Full.zip`. Import to a **new folder**, e.g. `/storage/emulated/0/Documents/tni-module-010`.
4. Open the new project and press **Play**. If your previous save is missing, open **WORLD SAVE BACKUP & RESTORE**, paste the saved JSON, choose **RESTORE PASTED SAVE**, and restart the game. Do not restore an old backup over newer progress unless intended.
5. In **GUNSMITH**, try crafting a gun; equip it to slot 1 or 3. Enter the open world. Test weapon switching and separate ammunition, ADS, reloading and zombie headshots. From Orlando, visit the SAFEHOUSE marker and tap **ARMORY** to access Gunsmith.
6. In **SURVIVAL ARENA**, earn 650 match points, use the Mystery Box and deliberately choose which slot to replace. Verify match-only guns disappear after the run while permanent guns remain owned.

## Starting conditions / economy

- Every new survival run begins at **0 match cash**. The persistent bank is not spendable during a run. All **unspent** match points deposit on **death** or successful **extraction**. Quit Run from the confirmation dialog forfeits unbanked match cash.
- Collected crafting **gun parts and fabrication tokens** are written to `user://tni_world_progress_v1.json` immediately. Collectible drops that fail a save show a warning and remain for retry.
- Gunsmith `weapon_slots` and `weapon_upgrades` live in the **same v1 save**, with automatic migration for Module 009's previous single `starting_weapon` field. The bank continues in its independent v1 file.
- Permanent weapons do **not** become permanent because they were found in the Mystery Box. Craft and equip guns at Gunsmith instead.

## Current limitations

- This package passed Python archive/reference/static sanity checks, **but no Godot executable was available to run engine/runtime or real-device tests in this environment**. It may still have gameplay or script problems. Do not delete your working Module 009 project.
- Original procedural zombies and gun silhouettes are more detailed but not photorealistic. True realistic art requires licensed original rigged assets, dedicated animation, lighting, and Android optimization.
- This is an **offline local-save prototype**. It is not online multiplayer, authenticated plot ownership, real-world geography, real money, or a Play Store-ready release.
- Three slot records currently store one instance per catalog gun ID, not duplicates with independent attachments and durability. Multi-instance gun inventory, genuine persistent stash containers, advanced AI navigation and full indoor safehouse exploration remain future modules.

See `docs/MODULE_010_TEST_PLAN.md` for feature-by-feature acceptance tests.
