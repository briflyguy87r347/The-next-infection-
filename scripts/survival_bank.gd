class_name SurvivalBank
extends RefCounted

# Prototype-only local ledger. Later migrate this to authenticated server storage.
# Important: the bank cannot be spent inside an active survival match.
const SAVE_PATH: String = "user://survival_bank_v1.json"
const STORE: Array[Dictionary] = [
    {"id":"safehouse", "name":"STARTER SAFEHOUSE DEED", "cost":3000, "detail":"Opens a usable healing safehouse in the Orlando open-world starter district"},
    {"id":"workshop", "name":"WORKSHOP LICENSE", "cost":5500, "detail":"Doubles powered-workshop fabrication output"},
    {"id":"generator", "name":"GENERATOR BLUEPRINT", "cost":2000, "detail":"Makes powered workshops produce fabrication faster"}
]

static func _fresh() -> Dictionary:
    return {"version":1,"balance":0,"lifetime_deposited":0,"lifetime_spent":0,
        "runs_completed":0,"best_round":0,"last_deposit":0,"settled_run_ids":[],"owned":[],
        "generator_built":false,"barricades_built":false,"scrap":0,"production_at":0}

static func load_bank() -> Dictionary:
    var data: Dictionary = _fresh()
    if not FileAccess.file_exists(SAVE_PATH):
        return data
    var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
    if file == null:
        push_warning("Could not read bank save: %s" % error_string(FileAccess.get_open_error()))
        return data
    var parsed: Variant = JSON.parse_string(file.get_as_text())
    if not (parsed is Dictionary):
        push_warning("Bank save invalid. Existing save has NOT been overwritten.")
        data["read_error"] = true
        return data
    var result: Dictionary = parsed
    if int(result.get("version", -1)) != 1:
        data["read_error"] = true
        return data
    for field in ["balance","lifetime_deposited","lifetime_spent","runs_completed","best_round","last_deposit"]:
        data[field] = maxi(0, int(result.get(field, 0)))
    if result.get("settled_run_ids", []) is Array:
        data["settled_run_ids"] = result["settled_run_ids"]
    if result.get("owned", []) is Array:
        data["owned"] = result["owned"]
    # Module 007 adds optional settlement state without changing the v1 save schema.
    # Existing Module 006 purchases and balances remain valid.
    data["generator_built"] = bool(result.get("generator_built", false))
    data["barricades_built"] = bool(result.get("barricades_built", false))
    data["scrap"] = maxi(0, int(result.get("scrap", 0)))
    data["production_at"] = maxi(0, int(result.get("production_at", 0)))
    return data

static func _write(data: Dictionary) -> bool:
    # Temp file + same-directory rename to reduce risk of half-written saves.
    var tmp: String = SAVE_PATH + ".tmp"
    var file := FileAccess.open(tmp, FileAccess.WRITE)
    if file == null:
        push_error("Bank file unavailable: %s" % error_string(FileAccess.get_open_error()))
        return false
    file.store_string(JSON.stringify(data, "  "))
    file.flush()
    file.close()
    var err: Error = DirAccess.rename_absolute(ProjectSettings.globalize_path(tmp), ProjectSettings.globalize_path(SAVE_PATH))
    if err != OK:
        push_error("Could not commit bank save: %s" % error_string(err))
        return false
    return true

static func make_run_id() -> String:
    # Unique per scene/run; stored in ledger to guard against double deposits.
    var bytes: PackedByteArray = Crypto.new().generate_random_bytes(16)
    return bytes.hex_encode()

static func settle_run(run_id: String, unspent_points: int, best_round: int) -> Dictionary:
    if run_id.is_empty() or unspent_points < 0:
        return {"ok":false,"error":"Invalid session data"}
    var data: Dictionary = load_bank()
    if data.has("read_error"):
        return {"ok":false,"error":"Bank save unreadable — existing data protected"}
    var ids: Array = data["settled_run_ids"]
    if ids.has(run_id):
        return {"ok":true,"duplicate":true,"deposited":0,"balance":int(data["balance"])}
    if unspent_points > 1000000000:
        return {"ok":false,"error":"Deposit exceeds prototype safety limit"}
    if int(data["balance"]) > 1000000000 - unspent_points:
        return {"ok":false,"error":"Bank is at the prototype safety limit"}
    data["balance"] = int(data["balance"]) + unspent_points
    data["lifetime_deposited"] = int(data["lifetime_deposited"]) + unspent_points
    data["runs_completed"] = int(data["runs_completed"]) + 1
    data["best_round"] = maxi(int(data["best_round"]), best_round)
    data["last_deposit"] = unspent_points
    ids.append(run_id)
    # Keep a bounded history of settled IDs to avoid indefinite save growth.
    if ids.size() > 1000:
        ids = ids.slice(ids.size() - 1000)
    data["settled_run_ids"] = ids
    if not _write(data):
        return {"ok":false,"error":"Could not save deposit"}
    return {"ok":true,"duplicate":false,"deposited":unspent_points,"balance":int(data["balance"])}

static func buy(id: String) -> Dictionary:
    var chosen: Dictionary = {}
    for item in STORE:
        if str(item["id"]) == id:
            chosen = item
            break
    if chosen.is_empty():
        return {"ok":false,"error":"Unknown purchase"}
    var data: Dictionary = load_bank()
    if data.has("read_error"):
        return {"ok":false,"error":"Bank save unreadable"}
    var owned: Array = data["owned"]
    if owned.has(id):
        return {"ok":false,"error":"Already owned"}
    var cost: int = int(chosen["cost"])
    if int(data["balance"]) < cost:
        return {"ok":false,"error":"Need %d more bank points" % (cost - int(data["balance"]))}
    data["balance"] = int(data["balance"]) - cost
    data["lifetime_spent"] = int(data["lifetime_spent"]) + cost
    owned.append(id)
    data["owned"] = owned
    if not _write(data):
        return {"ok":false,"error":"Purchase could not be saved"}
    return {"ok":true,"balance":int(data["balance"])}


# Settlement-only persistent actions. Bank points remain unavailable in matches.
static func build_generator() -> Dictionary:
    var data: Dictionary = load_bank()
    if data.has("read_error"):
        return {"ok":false,"error":"Bank save unavailable"}
    if not (data["owned"] as Array).has("generator"):
        return {"ok":false,"error":"Purchase the Generator Blueprint from the bank first"}
    if bool(data["generator_built"]):
        return {"ok":false,"error":"Generator already installed"}
    data["generator_built"] = true
    data["production_at"] = int(Time.get_unix_time_from_system())
    if not _write(data):
        return {"ok":false,"error":"Could not save generator installation"}
    return {"ok":true,"message":"GENERATOR BUILT — POWER ONLINE"}


static func collect_workshop_scrap() -> Dictionary:
    var data: Dictionary = load_bank()
    if data.has("read_error"):
        return {"ok":false,"error":"Bank save unavailable"}
    if not (data["owned"] as Array).has("workshop"):
        return {"ok":false,"error":"Workshop license required"}
    if not bool(data["generator_built"]):
        return {"ok":false,"error":"Build the generator to power the workshop"}
    var now: int = int(Time.get_unix_time_from_system())
    var last: int = int(data["production_at"])
    if last <= 0 or last > now:
        data["production_at"] = now
        if not _write(data):
            return {"ok":false,"error":"Could not save workshop clock"}
        return {"ok":true,"collected":0,"scrap":int(data["scrap"])}
    # Prototype local clock: 1 scrap every 15 seconds, capped at 120 per claim.
    # This is not a secure multiplayer or real-value economy.
    var units: int = mini(120, int((now - last) / 15.0))
    if units <= 0:
        return {"ok":true,"collected":0,"scrap":int(data["scrap"])}
    data["scrap"] = int(data["scrap"]) + units
    data["production_at"] = last + units * 15
    if not _write(data):
        return {"ok":false,"error":"Could not save collected scrap"}
    return {"ok":true,"collected":units,"scrap":int(data["scrap"])}


static func construct_barricades() -> Dictionary:
    var data: Dictionary = load_bank()
    if data.has("read_error"):
        return {"ok":false,"error":"Bank save unavailable"}
    if not (data["owned"] as Array).has("safehouse"):
        return {"ok":false,"error":"Safehouse deed required"}
    if bool(data["barricades_built"]):
        return {"ok":false,"error":"Barricades already constructed"}
    if int(data["scrap"]) < 8:
        return {"ok":false,"error":"Need 8 workshop scrap to build barricades"}
    data["scrap"] = int(data["scrap"]) - 8
    data["barricades_built"] = true
    if not _write(data):
        return {"ok":false,"error":"Could not save construction"}
    return {"ok":true,"message":"BARRICADES BUILT — PROPERTY IMPROVED"}
