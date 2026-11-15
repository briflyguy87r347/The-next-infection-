# THE NEXT INFECTION — Florida districts, crafting and territory roadmap

## Vision and rules retained from the design conversations
THE NEXT INFECTION is a realistic, mobile-first, first-person zombie survival game. OUTBREAK ZERO remains the first release in Godot 4. The world begins in Florida, with optional third-person exploration later, primarily cooperative multiplayer, designated opt-in PvP areas, persistent ownership, Creator/Destroyer faction influence, and property businesses producing game resources. Death drops carried survival loot and reduces equipment durability in the later persistent mode, but never erases deed ownership. The first property plot is free. Temporary relocation can move active players to a different region without requiring their precise GPS location.

## Regional world proposal
- **Cypress Haven / Orlando corridor:** starter region, inland suburban homes, original survival arena, first safehouse, garden, recycling workshop and supply depot.
- **Bayfront Yards / Tampa Bay:** second region, industrial salvage, shipping warehouses, port-adjacent workshops and specialized weapon component drops.
- Future regions: **Ironworks District** (industrial crafting), **Blackwater Harbor** (boats and docks), and then larger Florida expansion.
- Real Florida locations are geographic anchors, NOT exact copies of neighborhoods. Current Module 008 3D districts are original fictional 4x4 plots, *not imported geographic maps*.

## World and sector structure
Florida world map > city region > square sector plot > building and interior. A sector ID is stable (`O-01` through `O-16`, `T-01` through `T-16`). WorldProgress saves owned plot IDs and per-plot buildings. A player visits the district in first person, but offline claims do not mean that territory is reserved on a server. When multiplayer arrives, the server—not clients—must issue claims, handle conflict rules, use transactions and enforce limits.

### Proposed PvP territory control
- Plot claims protect a player's permanent building rights; *domination* is a separate temporary influence score (not permanent confiscation of deeds).
- Designated faction-control square sectors only, optional PvP, with protected neutral residences and new-player safe areas.
- Influence earned through defending, delivering supplies, clearing infected, and rebuilding; diminishing returns and cooldowns prevent a single squad from capturing everything quickly.
- Creator faction decreases local infection pressure, Destroyer faction increases the risk/reward of affected sectors. Civilian ownership persists when a faction loses influence.
- No fake real-money returns. All resources and bank credits are in-game only until an entirely separate legal and policy review.

## Three layers of value; avoid inflation
| Resource | Source | Spent on | Can be used inside survival arena? |
|---|---|---|---|
| Match Cash | Coins burst from defeated zombies, collected in a run | Mystery Box, temporary weapon upgrades, ammunition | Yes; starts at 0 every run |
| Permanent Bank Credits | Unspent Match Cash deposited after death/extraction | Deeds, world unlocks and future property purchase | No |
| Fabrication Tokens (FAB) | Salvage loot extracted alive, powered workshops over time | Land claims and buildings; also permanent gunsmith recipes | No |
| Gun Parts | Loot extracted alive, future workshop production | Craft permanent gun unlocks | No |

Kill tokens used by the health station remain in-match and are not Fabrication Tokens. Avoid adding more fungible coins without a clear reason.

## Weapon progression
Wave mode starts with a basic unlocked pistol (built-in). Mystery Box guns remain match-only. Players earn gun parts and FAB through survival extraction, build a permanent weapon in the Gunsmith, choose a starting loadout, and keep that unlock across death. Distinct regional gun classes and blueprints, repairs, material quality, durability and module-specific weapon modifications are later steps. Ranked arena variants should have standardized weapon loadouts.

## Loot, melee, character growth
Module 008 prototypes PUNCH, KICK and KNIFE with independent reach/damage/cooldowns. Scavenge pickups include ammo, medical supplies, weapon parts and FAB. On death, unextracted gun parts/FAB are lost while the **unspent points bank deposit still occurs**, honoring the current rule. On extraction, acquired parts and FAB are stored. Future inventory includes weighted backpack slots, armor, clothing, first aid, tools, throwables, character skills, consumable blueprints and crafting ingredients. A later inventory UI must clearly mark `carried`, `stash`, and `permanent unlock` items.

## Building and passive production
Owned sector allows blueprint placement for a generator, workshop, watchtower and supply cache. Prototype production requires generator + workshop on the same plot, producing a capped amount of Fabrication Tokens. This uses a local clock for demonstration only. Real shared-world production needs server time, fuel/electricity upkeep, storage capacity, theft-defense limits, cap and claim cooldowns. Autonomy while the owner is deployed: structures continue operating with limited vulnerability, but no automatic permanent deed loss.

## The scope we should build next
1. **Module 008 (prototype):** Florida Orlando/Tampa selector, 16 plots per region, local plot ownership and visible structures, starting pistol/owned guns/loadout, active melee and collectible extraction loot, persistent FAB and gun parts. *Not networked.*
2. **Module 009:** collision-safe placement preview, snapping, building validation, inventory and stash, object blueprints with construction/material costs, actual interior interaction and repair system.
3. **Module 010:** upgrade zombie behavior with animation trees and baked navigation meshes for roads/interiors, physical hit reactions, locomotion, performant lighting/textures/sounds, real gun rigs. Apply LOD, enemy pooling and maintain capped active zombies.
4. **Module 011:** backend authoritative region ownership, faction influence, persistent inventory and audits; coop matchmaking and protected property snapshots.
5. **Module 012+:** optional PvP zone objectives, vehicles/boats, travel/relocation tokens, regional crafting economy, expansion and marketplace.

## Constraints, risks and guardrails
- Android GL Compatibility rendering, low draw calls, chunk-loading, pool zombies, object instances, simplified collision; avoid a continuous 1:1 Florida 3D world on device.
- The doubling wave rule is exponential (4, 8, 16, 32...) and must have a progression/time-balance solution by later waves; max-active pool does not prevent 2048 total in Round 10.
- Godot built-in 3D NavigationServer/NavigationRegion supported; bake navmeshes in authoring pipeline where possible, not each frame on the tablet.
- OpenStreetMap data can be useful for future geographic road anchors subject to ODbL attribution/terms and appropriate mapping/tile service licenses; do not scrape commercial basemaps or reproduce identical protected game maps/buildings.
- Client-side saves are not tamper-proof or suitable for a monetized player market. Multiplayer ownership, loot and virtual currency must be validated by the server and transactions must be idempotent.
- Do not promise passive cash earnings, financial returns or cash-out until legal, platform-policy, payments, taxes, fraud and anti-money laundering reviews are resolved.

## Manual Godot validation for this build
- Editor imports all scenes without parse errors.
- Home menu -> Florida Map -> select Orlando / Tampa -> choose sector -> Visit -> movement works; buildings exist; selected structures appear.
- Starter O-01 is already free, and no bank points can be transferred into the survival match.
- Gunsmith starts with owned pistol; crafting needs extracted gun parts + FAB; re-opening the scene shows the chosen starting weapon.
- In survival, PUNCH / KICK / KNIFE work without ammo; rare loot visibly drops and is picked up near player.
- Death banks only unspent match cash; loot parts and FAB are lost; extraction banks unspent cash and stores salvage.
- No crashes when switching modes; check FPS on Android at increasing zombie counts.
- This ZIP has **not been validated with a running Godot binary in the build environment**. Keep your previous playable ZIP and GitHub branch unchanged until device testing passes.
