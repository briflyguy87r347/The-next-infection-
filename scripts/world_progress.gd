class_name WorldProgress
extends RefCounted

# Offline prototype ledger; server-authoritative ownership is required for multiplayer.
# Separate from the match-points SurvivalBank. No active match can withdraw these funds.
const SAVE: String = "user://tni_world_progress_v1.json"
const REGIONS: Dictionary = {"orlando":"CYPRESS HAVEN — ORLANDO", "tampa":"BAYFRONT YARDS — TAMPA"}
const RECIPES: Dictionary = {
    "smg":{"name":"RAPID SMG", "parts":3, "tokens":2},
    "shotgun":{"name":"BREACH SHOTGUN", "parts":4, "tokens":3},
    "rifle":{"name":"PATROL RIFLE", "parts":6, "tokens":4},
    "lmg":{"name":"SUPPORT LMG", "parts":10, "tokens":7}
}
const BUILDINGS: Dictionary = {
    "generator":{"name":"GENERATOR", "tokens":3},
    "workshop":{"name":"SALVAGE WORKSHOP", "tokens":4},
    "watchtower":{"name":"WATCHTOWER", "tokens":5},
    "supply_cache":{"name":"SUPPLY CACHE", "tokens":2}
}

static func fresh() -> Dictionary:
    return {"version":1,"region":"orlando","plot":"O-01","plots":{"O-01":[]},
        "owned_weapons":["pistol"],"starting_weapon":"pistol",
        "weapon_slots":["", "pistol", ""], "active_weapon_slot":1,"weapon_upgrades":{},
        "gun_parts":0,"fabrication_tokens":0,"production_last":int(Time.get_unix_time_from_system()),"processed_runs":[],
        "processed_pickups":[],"salvage_sites":{},"placements":{}, "open_positions":{},"missions":{},"mission_cooldowns":{},"missions_completed":{},"safehouse_last_rest":0}

static func load_data() -> Dictionary:
    var data: Dictionary = fresh()
    if not FileAccess.file_exists(SAVE):
        return data
    var file := FileAccess.open(SAVE, FileAccess.READ)
    if file == null:
        data["read_error"] = true
        return data
    var parsed: Variant = JSON.parse_string(file.get_as_text())
    if not (parsed is Dictionary) or int(parsed.get("version", -1)) != 1:
        data["read_error"] = true
        return data
    for key in ["region","plot","plots","owned_weapons","starting_weapon","weapon_slots","active_weapon_slot","weapon_upgrades","gun_parts","fabrication_tokens","production_last","processed_runs","processed_pickups","salvage_sites","placements","open_positions","missions","mission_cooldowns","missions_completed","safehouse_last_rest"]:
        if parsed.has(key):
            data[key] = parsed[key]
    if not (data["plots"] is Dictionary) or not (data["owned_weapons"] is Array) or not (data["processed_pickups"] is Array) or not (data["salvage_sites"] is Dictionary) or not (data["placements"] is Dictionary) or not (data["missions"] is Dictionary):
        data["read_error"] = true
        return data
    data["gun_parts"] = maxi(0, int(data["gun_parts"]))
    data["fabrication_tokens"] = maxi(0, int(data["fabrication_tokens"]))
    # Backward-compatible migration for previous one-weapon saves.
    # Never silently lose purchased guns or overwrite a damaged save.
    var owned: Array = data["owned_weapons"]
    if not owned.has("pistol"):
        owned.append("pistol")
    var slots: Array = data.get("weapon_slots", ["", "pistol", ""])
    if not parsed.has("weapon_slots"):
        slots = ["", "pistol", ""]
        var old_start: String = str(data.get("starting_weapon", "pistol"))
        if old_start != "pistol" and owned.has(old_start):
            slots[0] = old_start
            data["active_weapon_slot"] = 0
    var validated: Array = ["", "", ""]
    if slots is Array and slots.size() == 3:
        for i in range(3):
            var item: String = str(slots[i])
            if owned.has(item) and ["pistol","smg","rifle","shotgun","lmg"].has(item) and not validated.has(item):
                validated[i] = item
    if not validated.has("pistol"):
        validated[1] = "pistol"
    if not (data.get("weapon_upgrades", {}) is Dictionary):
        data["read_error"] = true
        return data
    data["weapon_slots"] = validated
    data["active_weapon_slot"] = clampi(int(data.get("active_weapon_slot", 1)), 0, 2)
    if str(validated[int(data["active_weapon_slot"])]) == "":
        data["active_weapon_slot"] = validated.find("pistol") if validated.has("pistol") else 0
    return data

static func _save(data: Dictionary) -> bool:
    if data.has("read_error"):
        return false
    var path: String = SAVE + ".tmp"
    var file := FileAccess.open(path, FileAccess.WRITE)
    if file == null:
        return false
    file.store_string(JSON.stringify(data, "  "))
    file.flush()
    file.close()
    return DirAccess.rename_absolute(ProjectSettings.globalize_path(path), ProjectSettings.globalize_path(SAVE)) == OK

static func select_plot(region: String, plot_id: String) -> bool:
    if not REGIONS.has(region) or not valid_plot(plot_id, region):
        return false
    var d: Dictionary = load_data()
    if d.has("read_error"):
        return false
    d["region"] = region
    d["plot"] = plot_id
    return _save(d)

static func valid_plot(plot_id: String, region: String) -> bool:
    var prefix: String = "O-" if region == "orlando" else "T-"
    if not plot_id.begins_with(prefix):
        return false
    var number: int = int(plot_id.substr(2))
    return number >= 1 and number <= 16 and plot_id == "%s%02d" % [prefix, number]

static func claim_plot() -> Dictionary:
    var d: Dictionary = load_data()
    if d.has("read_error"):
        return {"ok":false,"message":"Save unreadable"}
    var p: String = str(d["plot"])
    var plots: Dictionary = d["plots"]
    if plots.has(p):
        return {"ok":false,"message":"Plot already owned"}
    if int(d["fabrication_tokens"]) < 10:
        return {"ok":false,"message":"Need 10 Fabrication Tokens to claim"}
    d["fabrication_tokens"] = int(d["fabrication_tokens"]) - 10
    plots[p] = []
    d["plots"] = plots
    var saved: bool = _save(d)
    return {"ok":saved,"message":"Claimed %s" % p if saved else "Could not save claim"}

static func craft_gun(id: String) -> Dictionary:
    var d: Dictionary = load_data()
    if d.has("read_error") or not RECIPES.has(id):
        return {"ok":false,"message":"Unknown recipe or unreadable save"}
    if (d["owned_weapons"] as Array).has(id):
        return {"ok":false,"message":"Weapon already owned"}
    var recipe: Dictionary = RECIPES[id]
    if int(d["gun_parts"]) < int(recipe["parts"]) or int(d["fabrication_tokens"]) < int(recipe["tokens"]):
        return {"ok":false,"message":"Need %d parts and %d Fabrication Tokens" % [int(recipe["parts"]), int(recipe["tokens"])]}
    d["gun_parts"] = int(d["gun_parts"]) - int(recipe["parts"])
    d["fabrication_tokens"] = int(d["fabrication_tokens"]) - int(recipe["tokens"])
    (d["owned_weapons"] as Array).append(id)
    var saved: bool = _save(d)
    return {"ok":saved,"message":"Crafted %s permanently" % str(recipe["name"]) if saved else "Crafting save failed"}

static func equip(id: String) -> Dictionary:
    var d: Dictionary = load_data()
    if d.has("read_error") or not (d["owned_weapons"] as Array).has(id):
        return {"ok":false,"message":"Weapon not owned"}
    d["starting_weapon"] = id
    return {"ok":_save(d),"message":"Starting weapon set to %s" % id.to_upper()}


# A saved inventory is not a consumable run balance. 3 slots persist across modes.
# Slot 1=primary, 2=secondary, 3=third weapon; each weapon can occupy one slot.
static func assign_weapon_slot(slot: int, id: String) -> Dictionary:
    if slot < 0 or slot > 2:
        return {"ok":false,"message":"Invalid slot"}
    var d: Dictionary = load_data()
    if d.has("read_error"):
        return {"ok":false,"message":"Could not read save; nothing changed"}
    if not id.is_empty() and not (d["owned_weapons"] as Array).has(id):
        return {"ok":false,"message":"Craft or unlock this weapon first"}
    if not id.is_empty() and not ["pistol","smg","shotgun","rifle","lmg"].has(id):
        return {"ok":false,"message":"Unknown weapon"}
    var slots: Array = (d["weapon_slots"] as Array).duplicate()
    for i in range(3):
        if i != slot and str(slots[i]) == id and not id.is_empty():
            slots[i] = ""
    slots[slot] = id
    # Keep a functional pistol accessible if moving a gun between slots.
    d["weapon_slots"] = slots
    if not id.is_empty():
        d["active_weapon_slot"] = slot
        d["starting_weapon"] = id  # Legacy compatibility.
    var ok: bool = _save(d)
    return {"ok":ok,"message":"EQUIPPED %s IN SLOT %d — SAVED" % [id.to_upper(), slot + 1] if ok else "Save failed; previous loadout protected"}

static func set_active_weapon_slot(slot: int) -> bool:
    if slot < 0 or slot > 2:
        return false
    var d: Dictionary = load_data()
    if d.has("read_error") or str((d["weapon_slots"] as Array)[slot]).is_empty():
        return false
    d["active_weapon_slot"] = slot
    return _save(d)


# Permanent gunsmith upgrades (separate from temporary wave-box upgrades).
static func upgrade_owned_gun(id: String) -> Dictionary:
    var d: Dictionary = load_data()
    if d.has("read_error") or not (d["owned_weapons"] as Array).has(id):
        return {"ok":false,"message":"Weapon not owned or save unavailable"}
    var levels: Dictionary = d.get("weapon_upgrades", {})
    var level: int = maxi(0,int(levels.get(id,0)))
    if level >= 3:
        return {"ok":false,"message":"Permanent weapon upgrade maxed (level 3)"}
    var parts_cost: int = 2 + level*3
    var fab_cost: int = 2 + level*2
    if int(d["gun_parts"]) < parts_cost or int(d["fabrication_tokens"]) < fab_cost:
        return {"ok":false,"message":"Need %d gun parts and %d FAB" % [parts_cost,fab_cost]}
    d["gun_parts"] = int(d["gun_parts"]) - parts_cost
    d["fabrication_tokens"] = int(d["fabrication_tokens"]) - fab_cost
    levels[id] = level + 1
    d["weapon_upgrades"] = levels
    var ok: bool = _save(d)
    return {"ok":ok,"message":"PERMANENT %s LEVEL %d SAVED" % [id.to_upper(),level+1] if ok else "Save failed: upgrade not charged"}

# Existing map buttons auto-assign a free placement slot; district building allows a chosen slot.
static func build(kind: String) -> Dictionary:
    return build_at(kind, -1)

static func build_at(kind: String, requested_slot: int) -> Dictionary:
    var d: Dictionary = load_data()
    if d.has("read_error") or not BUILDINGS.has(kind):
        return {"ok":false,"message":"Save unavailable or blueprint missing"}
    var plots: Dictionary = d["plots"]
    var plot_id: String = str(d["plot"])
    if not plots.has(plot_id):
        return {"ok":false,"message":"Claim this plot first"}
    var built: Array = plots[plot_id]
    if built.has(kind):
        return {"ok":false,"message":"Already built on this plot"}
    var placements: Dictionary = d["placements"]
    var taken: Dictionary = placements.get(plot_id, {})
    var slot: int = requested_slot
    if slot == -1:
        for candidate in range(4):
            if not taken.values().has(candidate):
                slot = candidate
                break
    if slot < 0 or slot > 3 or taken.values().has(slot):
        return {"ok":false,"message":"Placement slot occupied; select a free slot"}
    var cost: int = int(BUILDINGS[kind]["tokens"])
    if int(d["fabrication_tokens"]) < cost:
        return {"ok":false,"message":"Need %d FAB (have %d)" % [cost, int(d["fabrication_tokens"])]}
    d["fabrication_tokens"] = int(d["fabrication_tokens"]) - cost
    built.append(kind)
    plots[plot_id] = built
    d["plots"] = plots
    taken[kind] = slot
    placements[plot_id] = taken
    d["placements"] = placements
    if kind == "workshop":
        d["production_last"] = int(Time.get_unix_time_from_system())
    var ok: bool = _save(d)
    return {"ok":ok,"message":"Built %s at %s / slot %d" % [kind.to_upper(), plot_id, slot + 1] if ok else "Save failed; build NOT charged"}

# Immediate, idempotent salvage writes: no more extraction-only loss of picked-up FAB/parts.
static func credit_pickup(pickup_id: String, kind: String, amount: int) -> Dictionary:
    if pickup_id.is_empty() or not ["parts", "fabrication"].has(kind) or amount <= 0 or amount > 10:
        return {"ok":false,"message":"Invalid loot pickup"}
    var d: Dictionary = load_data()
    if d.has("read_error"):
        return {"ok":false,"message":"Save unreadable; pickup remains available"}
    var ids: Array = d["processed_pickups"]
    if ids.has(pickup_id):
        return {"ok":true,"duplicate":true}
    var field: String = "gun_parts" if kind == "parts" else "fabrication_tokens"
    d[field] = int(d[field]) + amount
    ids.append(pickup_id)
    if ids.size() > 2000:
        ids = ids.slice(ids.size() - 2000)
    d["processed_pickups"] = ids
    var ok: bool = _save(d)
    return {"ok":ok,"duplicate":false,"message":"%s saved" % kind if ok else "Save failed; pickup remains"}

# Each physical plot has a salvage site that recharges after 90 seconds.
# This offline-clock cooldown is demonstrational, not secure against cheating.
static func salvage_site(region: String, plot_id: String) -> Dictionary:
    if not REGIONS.has(region) or not valid_plot(plot_id, region):
        return {"ok":false,"message":"Invalid site"}
    var d: Dictionary = load_data()
    if d.has("read_error"):
        return {"ok":false,"message":"Cannot access saved inventory"}
    var now: int = int(Time.get_unix_time_from_system())
    var sites: Dictionary = d["salvage_sites"]
    var last: int = int(sites.get(plot_id, 0))
    if last > 0 and now - last < 90:
        return {"ok":false,"message":"Salvage recharges in %d s" % (90 - maxi(0, now - last))}
    var parts: int = 1 if region == "orlando" else 2
    var fab: int = 1
    d["gun_parts"] = int(d["gun_parts"]) + parts
    d["fabrication_tokens"] = int(d["fabrication_tokens"]) + fab
    sites[plot_id] = now
    d["salvage_sites"] = sites
    var ok: bool = _save(d)
    return {"ok":ok,"message":"STASHED +%d GUN PARTS / +%d FAB" % [parts, fab] if ok else "Salvage save failed; try again"}

# Used only after validating the pasted save backup in SaveManagerMenu.
static func import_save(data: Dictionary) -> bool:
    if int(data.get("version", -1)) != 1 or not (data.get("plots") is Dictionary) or not (data.get("owned_weapons") is Array):
        return false
    if not (data.get("processed_runs", []) is Array):
        return false
    return _save(data)

static func claim_production() -> Dictionary:
    var d: Dictionary = load_data()
    if d.has("read_error"):
        return {"ok":false,"message":"Save unavailable"}
    var production: int = 0
    for plot in (d["plots"] as Dictionary).values():
        if plot is Array and (plot as Array).has("workshop") and (plot as Array).has("generator"):
            production += 1
    if production == 0:
        return {"ok":false,"message":"Build a generator and workshop on the same plot"}
    var bank: Dictionary = SurvivalBank.load_bank()
    var deeds: Array = bank.get("owned", [])
    if deeds.has("workshop"):
        production *= 2
    var interval: int = 1200 if deeds.has("generator") else 1800
    var now: int = int(Time.get_unix_time_from_system())
    var elapsed: int = maxi(0, now - int(d["production_last"]))
    # Offline demo cap of 12 FAB per claim; bank entitlements affect output.
    var tokens: int = mini(12, int(elapsed / interval) * production)
    if tokens == 0:
        return {"ok":true,"message":"No fabrication tokens ready yet"}
    d["fabrication_tokens"] = int(d["fabrication_tokens"]) + tokens
    d["production_last"] = now
    return {"ok":_save(d),"message":"Collected %d Fabrication Tokens" % tokens}

static func deposit_extracted_loot(run_id: String, parts: int, tokens: int) -> Dictionary:
    # Prototype save keeps credits and processed run ID in the same atomic write.
    # The later multiplayer backend must validate these rewards server-side.
    var d: Dictionary = load_data()
    if d.has("read_error") or run_id.is_empty():
        return {"ok":false,"message":"Cannot save loot"}
    var ids: Array = d["processed_runs"]
    if ids.has(run_id):
        return {"ok":true,"message":"Loot already saved"}
    d["gun_parts"] = int(d["gun_parts"]) + maxi(0, mini(200, parts))
    d["fabrication_tokens"] = int(d["fabrication_tokens"]) + maxi(0, mini(200, tokens))
    ids.append(run_id)
    if ids.size() > 1000:
        ids = ids.slice(ids.size() - 1000)
    d["processed_runs"] = ids
    return {"ok":_save(d),"message":"Salvage stored"}

# Open-world state is stored alongside crafted weapons and owned plots.
static func remember_position(region: String, pos: Vector3) -> bool:
    if not REGIONS.has(region) or absf(pos.x) > 400.0 or absf(pos.z) > 400.0:
        return false
    var d: Dictionary = load_data()
    if d.has("read_error"):
        return false
    var positions: Dictionary = d["open_positions"]
    positions[region] = [pos.x, 0.0, pos.z]
    d["open_positions"] = positions
    return _save(d)

static func restore_position(region: String) -> Vector3:
    var d: Dictionary = load_data()
    var saved: Variant = d.get("open_positions", {}).get(region, [])
    if saved is Array and saved.size() == 3:
        return Vector3(float(saved[0]), 0.15, float(saved[2]))
    return Vector3(0.0, 0.15, 12.0)

# An offline demonstration mission: collect a supply crate at the garage and
# deliver it to the clinic. Rewards are awarded once per completed mission.
static func mission_stage(region: String) -> int:
    return int(load_data().get("missions", {}).get(region, 0))

static func mission_interact(region: String, at_clinic: bool) -> Dictionary:
    if not REGIONS.has(region):
        return {"ok":false,"message":"Invalid mission region"}
    var d: Dictionary = load_data()
    if d.has("read_error"):
        return {"ok":false,"message":"Save unavailable"}
    var missions: Dictionary = d["missions"]
    var stage: int = int(missions.get(region, 0))
    var now: int = int(Time.get_unix_time_from_system())
    var cooldown: int = int(d["mission_cooldowns"].get(region, 0))
    if stage == 0 and not at_clinic:
        if now < cooldown:
            return {"ok":false,"message":"Next delivery available in %ds" % (cooldown-now)}
        missions[region] = 1
        d["missions"] = missions
        var okay: bool = _save(d)
        return {"ok":okay,"message":"SUPPLIES LOADED. Deliver to the clinic." if okay else "Save failed"}
    if stage == 1 and at_clinic:
        missions[region] = 0
        d["missions"] = missions
        d["gun_parts"] = int(d["gun_parts"]) + 2
        d["fabrication_tokens"] = int(d["fabrication_tokens"]) + 3
        var cooldowns: Dictionary = d["mission_cooldowns"]
        cooldowns[region] = now + 120
        d["mission_cooldowns"] = cooldowns
        var counts: Dictionary = d["missions_completed"]
        counts[region] = int(counts.get(region, 0)) + 1
        d["missions_completed"] = counts
        var okay: bool = _save(d)
        return {"ok":okay,"message":"DELIVERY COMPLETE: +2 gun parts, +3 FAB SAVED" if okay else "Reward save failed"}
    return {"ok":false,"message":"Deliver supplies to the clinic" if stage == 1 else "Pick up supplies at the garage"}

# Safehouse deed unlocks a physical heal spot in Cypress Haven / O-01.
static func rest_at_safehouse() -> Dictionary:
    var bank: Dictionary = SurvivalBank.load_bank()
    if not (bank.get("owned", []) as Array).has("safehouse"):
        return {"ok":false,"message":"Buy the Safehouse Deed at the main menu first"}
    var d: Dictionary = load_data()
    if d.has("read_error"):
        return {"ok":false,"message":"Save unavailable"}
    var now: int = int(Time.get_unix_time_from_system())
    var last: int = int(d.get("safehouse_last_rest", 0))
    if last > 0 and now-last < 60:
        return {"ok":false,"message":"Safehouse rest available in %d seconds" % (60-(now-last))}
    d["safehouse_last_rest"] = now
    var ok: bool = _save(d)
    return {"ok":ok,"message":"SAFEHOUSE RESTED — HEALTH RESTORED" if ok else "Rest save failed"}
