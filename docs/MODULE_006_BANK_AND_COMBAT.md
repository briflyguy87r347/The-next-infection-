# THE NEXT INFECTION — Module 006: Banked survival progression

Built from the user's working Module 005 source snapshot; no GitHub commits are made by this package.

## New rules

- Each run **starts with 0 match points and 0 kill tokens**, regardless of permanent bank balance.
- Killed infected emit **5 physical gold coins worth 25 match points each**. You must collect coins before they expire; simply killing an infected does not auto-credit coins.
- **Only unspent, collected match points** are deposited on death or voluntary extraction. Money used on mystery rolls, ammunition, or upgrades cannot also be banked.
- Health restoration still uses **3 kill tokens**, earned separately per kill. Kill tokens reset each run and are not banked.
- A permanent local bank is accessible from the **main menu only**. Bank points cannot be pulled back into a live wave or used to buy weapons in that wave.
- Prototype permanent purchases at the menu: safehouse deed, workshop license, generator blueprint. These purchases are saved as **entitlement records only**; producing resources and owning real persistent map buildings is planned for later development.
- The deposit uses a unique run ID, maintains a history of recently settled IDs, and saves with a temporary file + rename to reduce accidental duplicate deposits and truncated files.
- If a deposit fails, the death screen stays open and offers **RETRY BANK SAVE** instead of silently discarding earnings.
- Current bank is **local Android device storage only** (`user://survival_bank_v1.json`). It is **not** a secure server wallet, cloud account, transferable asset or real-money currency. Uninstalling the app or clearing Godot's app data may erase it. Save files can be manually altered in this prototype.
- Abandoning or force-closing a run without dying/extracting does not bank pending match points.

## Zombie growth

- Round 1: 4; Round 2: 8; Round 3: 16; Round 4: 32; Round 5: 64; Round 10: 2,048.
- Wave count is `4 × 2^(round−1)` with no 16-total-zombie cap.
- Only 16 zombies can be alive simultaneously. The next queued zombie enters ~0.2 seconds after an active slot becomes available.
- HUD reports **LEFT** (remaining total, queued included) and **FIELD** (simultaneously alive).
- When Round 5, 10, 15 etc. finishes, a 15-second **EXTRACT** option appears. Extracting deposits the same way as death. Letting the timer expire continues to the next round.
- Later waves can be very long; 2,048 kills in Round 10 is intentionally demanding. This prototype does not support an infinite integer range (64-bit counts have finite limits).

## Extra gameplay

- A simple 3D gun is attached to the camera, changing shape with different mystery-box weapons and kicking back with a short muzzle flash when fired.
- Mystery-box purchases display a 4-second gun preview card, weapon name, magazine size, and base damage; the random gun equips automatically.
- An **Ammo Resupply** station sells 3 magazines worth of reserve ammo for 450 *current-run* points.
- Weapon upgrades remain 500, 1,000, 2,000, 4,000, 8,000 points for levels 1–5 of each weapon.
- Original map, zombie visuals, shooting calculations, health station, and Android touch controls remain in place.

## Install

1. Download `TNI_Outbreak_Zero_Module_006_Full.zip` to Android Downloads.
2. Godot Project Manager → Import → ZIP file. Import into a NEW folder; do not overwrite working Module 005.
3. Press Play. The new **START NEW SURVIVAL RUN** button launches Block Zero.
4. Test the coins, Mystery Box preview, weapon viewmodel, doubling waves, ammo station, death deposit, and permanent bank spending.

## Smoke-test checklist

- First app launch shows main menu, bank = 0 and buttons for the out-of-match purchase records.
- After `START`, HUD shows MATCH = 0, and 4 zombies spawn (FIELD at most 16).
- Pick up five coins: match = 125. Coins collected on the same death frame are ignored after a run ends.
- At 650 match points, buy a Mystery Box gun. Remaining match points decrease by 650; preview shows the gun.
- Fire a gun: a camera-mounted weapon moves back and the muzzle flashes.
- Kill all 4 enemies; Round 2 should start with 8, then Round 3 with 16 and Round 4 with 32 (but at most 16 active at once).
- Get killed with an unspent balance; result screen says BANKED + amount, then returns to main menu. Start again and verify MATCH = 0 while BANK retains deposit.
- Buy a permanent item from the main menu; bank balance decreases and item becomes OWNED. Start a match: MATCH still = 0.
- Finish Round 5: EXTRACT shows for 15 seconds; using EXTRACT deposits unspent match points and returns to menu.
- Turn off local storage write access or test with a read-only app data directory (advanced): death should show RETRY BANK SAVE rather than silently restarting.

## Known limitations

Godot compilation and physical Android runtime were not executed in this packaging environment. Please test in Godot before publishing or merging. The gun is a lightweight procedural placeholder, not a detailed rigged character/weapon model. The mystery preview is drawn, not a 3D spinning collectible. Banks need authoritative server-side accounts, authentication, durable transaction IDs, inventory rules, economy balancing, and anti-cheat protection before public multiplayer or real-money systems.
