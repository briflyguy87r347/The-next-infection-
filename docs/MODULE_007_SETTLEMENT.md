# Module 007 — Settlement prototype

Previous limitation: Module 006 had permanent shop purchase flags but no visitable destination or functional effect. Module 007 adds a visitable area and makes the three existing unlocks actionable, while preserving survival gameplay.

## Test sequence
1. From menu tap VISIT SETTLEMENT. Tour accessible yard without purchase; safehouse door remains locked.
2. Back to bank. Purchase safehouse deed (if sufficient bank points), revisit; door is open and home interior can be entered.
3. Purchase generator blueprint, revisit and use Generator pad; full 3D generator appears and persists on later visits.
4. Purchase workshop license, visit workshop and use after 15 seconds; scrap balance rises.
5. Reach 8 scrap, visit barricade marker and use; visible planks appear on home.
6. Return to menu and enter a survival run; match points start 0, bank points inaccessible. Death/extraction deposits unspent match points to bank.

## Known limitations
- Buildings/props are lightweight graybox geometry, not high-realism assets.
- Workshop accrual depends on untrusted client device clock; must move server-side before any valuable economy.
- User data is device-local, not cloud-synced. Back up prior saves.
- Some mobile UI labels need device-specific layout testing.
- No network, multiplayer, cash conversion, or property trading.
