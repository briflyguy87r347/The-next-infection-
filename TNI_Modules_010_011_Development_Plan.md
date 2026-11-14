# THE NEXT INFECTION — Modules 010–011 Development Specification

**Project:** THE NEXT INFECTION / OUTBREAK ZERO + FLORIDA OPEN WORLD  
**Target:** Godot 4.7.x, Android touchscreen tablet, GL Compatibility renderer, existing mobile-first codebase  
**Baseline reviewed:** `TNI_Outbreak_Zero_Module_009_Open_World_Full.zip`  
**State:** DESIGN / BUILD SPECIFICATION — not implemented or tested  
**Repository:** https://github.com/briflyguy87r347/The-next-infection-  
**Protection:** Preserve playable Module 009, use a new feature branch, do not merge until Android verification.

## Product direction

Two modes share persistent progression: **Outbreak Zero** (round-based wave survival) and **Florida Open World** (district exploration, missions, salvage, territory, property development). Their economies and weapon ownership rules remain coherent across modes. The intended feel is an original immersive open-world zombie-survival sandbox, without recreating other games' protected map assets or designs.

## Current implementation inventory (Module 009)

- `scripts/open_world_controller.gd`: walk/drive, first/third view, missions, plot building, shooting and melee; **one active weapon dictionary**.
- `scripts/combat_director.gd`: rounds, zombie doubling, cash/bank, Mystery Box, loot, melee, upgrade stations; **one active weapon index**.
- `scripts/gun_viewmodel.gd`: simple procedural gun shape and muzzle flash; not realistic rigged weapon assets.
- `scripts/zombie.gd`: procedural humanoid with texture images and animated body parts; not rigged/retargeted cinematic animations.
- `scripts/hud.gd`: touch movement/looking/jump/sprint/fire/reload/use, no 3-slot weapon selector.
- `scripts/world_progress.gd`: owned regions/plots, craft recipes, fabrication parts and build progress.
- `scripts/survival_bank.gd`: per-run earned/unspent banking and persistent bank.
- `scripts/save_manager.gd`: manual export/restore of save data between app installations.
- `assets/zombies/`: textures; `scripts/district_world.gd` and `scripts/open_world_controller.gd` generate simplified geometry.

**Do not pretend gameplay is implemented by a menu entry:** a deed, blueprint or building is complete only when its corresponding visit/placement/use loop works.

---

# MODULE 010 — Combat & Immersion Upgrade

## Scope and acceptance priority

**P0 (must ship):** three gun slots; functioning swap, ammo per gun, viewmodel matching active gun; safe persistent stash/loadout; responsive mystery-box popup; headshot/hit/kill feedback; zombie pursuit around fixed obstacles; UI fit on target tablet; Godot parse+startup+Android tests.

**P1 (include if P0 stable):** aim-down-sights, separate recoil per gun type, reload animation, muzzle audio, quality zombie animation states, one furnished/lootable indoor space, accessible safehouse stash.

**Not Module 010:** public multiplayer, cash withdrawal, open-world Florida streaming, destructible full environments, 50 detailed active zombies, real player-to-player property trades.

## 010-A: Three weapon slots and permanent arsenal

- **Slot 1 — Primary:** rifle, shotgun, SMG or DMR.
- **Slot 2 — Secondary:** pistol/revolver/compact SMG.
- **Slot 3 — Utility/third gun:** shotgun, heavy weapon, crossbow or special firearm (separate from melee).
- **Always accessible:** punch, kick and knife via context-responsive melee control; no gun slot consumed by melee.
- Slot switch: tapping one of three HUD slots; cannot switch while stunned / in interaction dialog; reload canceled cleanly when switching (do not transfer ammo between guns).
- Each equipped gun has persistent `weapon_id`, `instance_id`, attachments, upgrade level, durability, magazine/reserve; **in-run state** is distinct from stash record. Never merge two weapon instances just because they share a catalog ID.
- Default starter is unlocked service pistol (in secondary slot). Primary and third slot may be empty until crafted, found and extracted or obtained via allowed unlock.
- Pickups acquired during a run: temporary carried until extracted/stashed, except existing always-saved crafting materials. If death occurs, carried unextracted rare guns/gear are lost; permanently owned stashed guns remain in account inventory. If a stored gun is brought on a run, define loss and durability clearly before enabling equipment loss; Module 010 default: **no permanent weapon destruction on death**, limited durability cost only.
- Save-on-change for stash, equipped slots and modifications, and a visible save-failure warning. Validate IDs on load; preserve older Module 009 saves with a migration version.

### Suggested data structure

```json
{
  "schema": 2,
  "loadout": {"primary": null, "secondary": "weapon-instance-01", "third": null},
  "weapon_instances": {
    "weapon-instance-01": {
      "catalog_id": "service_pistol",
      "level": 0,
      "durability": 100,
      "attachments": [],
      "location": "stash"
    }
  },
  "inventory_version": 1
}
```

Keep active magazine/reserve ammo in run state or when temporarily leaving an open-world session; explicitly define persistence, not accidental transfer from bank.

## 010-B: Gun realism

- Replace each gun's single procedural primitive viewmodel with an original or properly licensed rigged/low-poly asset, distinct silhouette per class.
- Gun model attached under active camera pivot; separate position and projection for aiming.
- Weapon state machine: `IDLE`, `AIM`, `FIRE`, `RELOAD`, `SWAP`, `EMPTY`, `SPRINT`, `MELEE`.
- Tracer/hit impact, shell ejection at near camera only, muzzle flash, synchronized recoil kick, audio per gun class; respect fire-rate timing and trigger modes.
- Hitscan for pistol/rifle/SMG initially; multi-pellet shotgun with spread, damage falloff and per-target hit aggregation.
- Damage feedback: hit-marker, headshot multiplier, distinct metal/wood/flesh hit audio; no gore-dependent gameplay.
- Aim: hold ADS button to reduce FOV and sensitivity; sprint cancels ADS; no automatic aim bots in competitive modes.
- Mystery Box: animated floating 3D weapon or 2D preview card with item name, class, rarity, damage, mag size, options `EQUIP`, `STASH/CLAIM` where allowed, `DECLINE`. The result must be server-validated eventually; use one weighted loot table in single player now. Never silently discard a full-slot weapon.

## 010-C: Zombie realism and navigation

- Replace prototype procedural bodies with **licensed or original** skinned humanoid meshes with consistent skeleton and LODs; 3 clothing/skin variants minimum.
- Animation states: idle, walk, run, turn, alerted, hit/stagger, lunge/attack, death, optional crawl (advanced).
- Distinct profiles: Walker (basic), Runner (fast, fragile), Brute (slow, armored/high HP). Spitter and Screamer remain later-phase enemy classes because they require projectile/audio AI and balancing.
- Head and torso hurtboxes; headshot damage modifier (proposed 2×); optional leg damage affecting movement.
- Improve AI: sound/line-of-sight detection; path to last heard location; pursue around buildings using baked NavigationMesh and NavigationAgent3D; obstacle avoidance tested with groups of zombies.
- Ensure defeated signal fires once; health/clips/drop rewards are awarded once only.
- Ragdoll is **not required** for Android P0; use authored death animations plus collision disable and timed cleanup.

## 010-D: Safehouse and open-world purpose

One small **traversable interior** rather than another purchase-only menu:

- Front door enters safehouse without breaking world navigation.
- Armory/stash interacts with your permanent 3-slot loadout.
- Craft bench turns fabrication tokens + gun parts into one unlocked weapon blueprint.
- Medical station restores health with existing kill-token or stored-supply cost by mode.
- Mission board lists 3 repeatable tasks: salvage delivery, infected nest clearing, and survivor escort placeholder (escort only if NPC path is reliable).
- Save point displays last save status, bank total and resource totals.

## 010-E: Touch HUD layout

**Landscape 16:9 target**; test all corners with Godot embedded-run overlay **disabled** for final input verification.

```
┌─────────────────────────────────────────────────────────────────────────┐
│ HP / ARMOR  | DISTRICT | MISSION        | BANK(OUTSIDE RUN) | MAP | MENU│
│ WPN NAME  AMMO  STAMINA                         [MINIMAP]              │
│                                                                         │
│                         world / crosshair                               │
│                                                                         │
│ [MOVE]                               [ADS] [FIRE]    [JUMP]            │
│                                      [RELOAD] [USE]  [SPRINT]           │
│             [PRIMARY] [SECONDARY] [THIRD] [MELEE]                        │
└─────────────────────────────────────────────────────────────────────────┘
```

- No overlap between use/reload/melee, weapon selector and right-thumb aim zone. Allow touch drag anywhere in an unclaimed look zone.
- Provide single **MELEE** control with hold/radial option for punch/kick/knife; keep 3 gun slots visible.
- One Back/Menu action always available; confirmation before abandoning an active wave run.
- Responsive sizing for 960×540 virtual resolution and smaller Android screen; safe-area margins; UI opacity/scale in Settings.
- On-screen prompts only when near interactables, with distance and action text.

## 010-F: Economy and save invariants

1. Match points start at **zero** every new arena run.
2. Killed enemies release collectible match coins; spending subtracts from match points, not the permanent bank.
3. Death or successful extraction deposits only **unspent** match points; one run ID can settle only once.
4. Permanent Bank Credits cannot be injected into a live survival run.
5. **Gun parts and fabrication tokens save immediately on pickup**, as requested in the last update. Show success/failure; on failure queue a retry, and do not claim a save succeeded.
6. Temporary high-value loot and found rare guns become permanent only upon extraction/return to stash, with clear inventory labels.
7. Generator/workshop production is bounded, with a defined storage cap and elapsed-time cap; no unlimited offline farming.
8. All save mutations are atomic where supported (write temp, verify, replace), versioned, logged and idempotent. Local save isn't cheat-resistant; future multiplayer requires server-authoritative transactions.
9. Every wave doubles the total zombie count from 4, but active rendered/AI enemies are dynamically capped for Android. A visible queue counter prevents seemingly infinite rounds.

## 010-G: Technical implementation map

**Modify existing:** `scripts/open_world_controller.gd`, `scripts/combat_director.gd`, `scripts/gun_viewmodel.gd`, `scripts/zombie.gd`, `scripts/hud.gd`, `scripts/arsenal_menu.gd`, `scripts/world_progress.gd`, `scripts/save_manager.gd`, `scripts/survival_menu.gd`.

**Add:**

- `scripts/weapon_catalog.gd` — one source of truth for weapon definitions.
- `scripts/weapon_instance.gd` — individual ownership/upgrades/attachments representation.
- `scripts/loadout_manager.gd` — inventory IDs and three-slot equip rules.
- `scripts/weapon_controller.gd` — shooting / reload / switching / ADS state machine.
- `scripts/loot_table.gd` — weighted mystery-box and field rewards.
- `scripts/interaction_controller.gd` — distance-based use actions.
- `scripts/mission_manager.gd` — tracked world tasks, objectives and reward once.
- `scripts/zombie_brain.gd` — AI state/navigation, independent of model.
- `scenes/safehouse_interior.tscn`, `scenes/weapon_station.tscn`, `scenes/weapon_reward_popup.tscn`.
- `assets/weapons/...` and `assets/zombies/...` — original or properly licensed lightweight models, textures, animations. Document credits/licenses.

**Avoid big-bang script rewrites.** Integrate adapters so existing `CombatDirector` and `open_world_controller` delegate to shared weapon/loadout components.

## 010-H: Android performance budget and test gates

- Target 30 FPS sustained on the user's entry-level Android tablet, preferably 45–60 on stronger devices; test actual device.
- Maintain Compatibility renderer for first release; no assumption of desktop rendering features.
- Start at 8 near fully animated zombies and scale toward **16 active max** only if performance permits. Far zombies use fewer AI/path/animation updates.
- Limit light sources/shadows; baked/static lighting where useful; atlas textures, LODs, careful occlusion and chunk loading.
- Measure frame time, peak memory, temperature and battery drain during 15-minute play; establish device baseline before selecting art budgets.

**Release checklist:**

1. Existing Module 009 project stays independently runnable.
2. Godot editor scan has **0 parse errors**, game boots headlessly with **0 runtime errors**.
3. On Android, player can equip 3 weapon slots, swap 50 times without ammo leakage, aim and fire.
4. Mystery Box gives a clear reward; full loadout prompts replace/stash/decline; no duplicate rewards.
5. Zombies navigate around a barricade, move at visibly different speeds, hit/react/die, reward once.
6. Craft a weapon in a safehouse; return to menu; relaunch; owned weapon and selected slots persist.
7. FAB and gun parts persist after pickup, death, quit, relaunch and app process restart.
8. Arena run always starts at 0 points; purchases spend once; death/extraction banks only remaining points **once**.
9. Menus readable and clickable in landscape; critical buttons don't overlap.
10. 15-minute Android test remains responsive within defined budget; test recordings/screenshots captured.

**GitHub:** create a new `feature/module-010-combat-immersion` branch **from the actual Module 009 source**, publish as a draft PR, and merge only after tests. Do not try to merge a newer ZIP blindly into the old Module 003 PR. Ensure Module 009 source is committed to its own baseline before branching.

---

# MODULE 011 — Open World Depth, Plot Ownership, and Settlement Production

## Core experience

From the safehouse, choose a Florida district, load an equipped weapon, drive or walk into a mission, scavenge materials, fight infected, secure a plot/structure, return alive, invest in production, and unlock a new location. This is **single-player offline progression first** with a backend-compatible schema.

## 011-A: Distinct neighborhoods that matter

- Orlando/Cypress Haven starter district and Tampa/Bayfront Yards industrial district.
- Each has sector/plot IDs; plot preview, claim, teleport/drive-to, visit, build, collect and defend actions must be accessible.
- Sector control affects local danger, supply respawns and faction influence; a single player's offline plot does not pretend to be multiplayer domination.
- Events: infected nest, timed supply drop, clinic delivery, police-depot salvage, garage defense.
- Map UI shows selection, distance, owned structures, mission marker, infection tier and resource bias.
- A plot purchase creates a visible owned location, not just a line in a saved dictionary.

## 011-B: Physical building mode

- Enter Build Mode only while inside owned parcel boundary; transparent ghost model and valid/invalid placement indicator.
- Snap/rotate/cancel/place foundation, walls, door, generator, workshop, watchtower and cache.
- Spend required resources **only after successful placement**. Occupancy checks prevent intersecting doors/roads/other buildings. Save location, yaw and structure type.
- Blueprint unlock screens provide `PREVIEW`, `CRAFT/BUILD`, `PLACE`, `GO TO PROPERTY`.
- Generator must power relevant structures. Workshop produces limited fabrication over time (bounded offline accrual); supply cache holds physical inventory; towers affect defense only when occupied or staffed.
- Easy safe relocation / demolition refund rule; avoid punishing placement mistakes on mobile.

## 011-C: World simulation and reasons to explore

- Enterable clinic, garage, 1 residence, 1 shop, each with 2–4 actual searchable containers.
- Repairable vehicles with condition and fuel; start with one reliable drivable vehicle and improve physics gradually.
- Survivor vendor, mechanic and mission-giver; basic navigation/voice text; no promises of sophisticated AI yet.
- Threat evolves with time/noise and missions: gunfire draws infected; cleared nests reduce local pressure for a period.
- Open-world death applies a defined loss rule: temporary carried rare loot lost, permanent stash protected; map ownership and bank persist.

## 011-D: Long-term economy architecture

- In-game Bank Credits buy properties and permits; Fabrication Tokens build and repair; Gun Parts plus blueprints craft/upgrade; Kill Tokens buy health/rare perks.
- All costs/rewards in a centralized balance table with sinks, caps, crafting durations and a migration version.
- Offline passive income is **virtual game resources**, not a promise of cash or real-money investment returns.
- Future player trading, cash-out or property finance requires server-side ownership, abuse mitigation and legal/platform review before launch.

## 011-E: Release gates

1. Drive to 2 different zones, follow world map marker, switch regions and retain current mission progress.
2. Claim a plot, walk onto it, place a generator and workshop, exit game, reload and see both structures.
3. Workshop credits bounded fabrication production offline; it doesn't duplicate earnings if the app restarts twice.
4. Buy a blueprint, see its preview, place and interact with the actual object.
5. 3 repeatable missions and 1 special infected event produce one-time verified reward grants.
6. Combat and 3-slot loadout from Module 010 work in both modes.
7. Save migration preserves prior gun parts, FAB, bank, plot deeds and weapon unlocks.
8. Measured FPS and memory remain within Android budgets.

---

# Recommended execution order

1. Snapshot/archive Module 009, commit the real baseline to GitHub, write save migration tests.
2. Add weapon catalog + 3-slot `LoadoutManager` with placeholder visuals and persistence.
3. Upgrade shared combat controls and Mystery Box UI; run input/weapon tests.
4. Integrate 2–3 properly licensed rigged zombie models and pathfinding; profile Android.
5. Add one physical safehouse interior and mission board; test entire fight/loot/store/replay loop.
6. Finish Module 010 test gates, make draft PR and APK or Android Godot import test build.
7. For Module 011, build a single truly functional parcel then replicate into two districts.
8. Add construction placement and bounded passive production before expanding territory or multiplayer.

**Definition of success:** the player fights using one of three persistent equipped guns, loots and survives, returns to a real safehouse, constructs something valuable, sees it remain after closing the app, and has an engaging reason to revisit the next district.
