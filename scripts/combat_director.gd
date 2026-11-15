class_name CombatDirector
extends Node3D

# Module 006: doubling waves, permanent post-run bank, viewmodel, and mystery reward preview.
# All rewards are virtual prototype game currency, not withdrawable money.
const ZOMBIE_SCENE: PackedScene = preload("res://scenes/zombie.tscn")
const WEAPONS: Array[Dictionary] = [
	{"id": "pistol", "name": "SERVICE PISTOL", "damage": 34, "mag": 12, "reserve": 72, "interval": 0.23, "range": 80.0, "pellets": 1},
	{"id": "smg", "name": "RAPID SMG", "damage": 23, "mag": 28, "reserve": 168, "interval": 0.105, "range": 55.0, "pellets": 1},
	{"id": "rifle", "name": "PATROL RIFLE", "damage": 43, "mag": 24, "reserve": 120, "interval": 0.18, "range": 90.0, "pellets": 1},
	{"id": "shotgun", "name": "BREACH SHOTGUN", "damage": 16, "mag": 6, "reserve": 42, "interval": 0.78, "range": 25.0, "pellets": 7},
	{"id": "lmg", "name": "SUPPORT LMG", "damage": 30, "mag": 40, "reserve": 200, "interval": 0.15, "range": 75.0, "pellets": 1}
]
const COIN_VALUE: int = 25
const COINS_PER_ZOMBIE: int = 5
const MYSTERY_COST: int = 650
const BASE_UPGRADE_COST: int = 500
const MAX_UPGRADE_LEVEL: int = 5
const AMMO_COST: int = 450
const HEAL_TOKEN_COST: int = 3
const HEAL_AMOUNT: int = 65
const AMMO_PER_CLEARED_WAVE: int = 36
const BETWEEN_WAVES: float = 3.0
const MAX_ACTIVE_ZOMBIES: int = 16
const INITIAL_WAVE_ZOMBIES: int = 4
const EXTRACTION_SECONDS: float = 15.0
const RELOAD_SECONDS: float = 1.35
const SPAWN_POINTS: Array[Vector3] = [
	Vector3(-4.2, 0, -25), Vector3(4.2, 0, -25),
	Vector3(-4.2, 0, 25), Vector3(4.2, 0, 25),
	Vector3(-7.3, 0, -20), Vector3(7.3, 0, 20),
	Vector3(-7.3, 0, 20), Vector3(7.3, 0, -20)
]

var player: FirstPersonPlayer
var hud: TouchHUD
var world: BlockZeroMap

var _wave: int = 0
var _alive: int = 0
var _wave_remaining: int = 0
var _pending_spawns: int = 0
var _spawn_timer: float = 0.0
var _kills: int = 0
var _points: int = 0
var _earned_total: int = 0
var _spent_total: int = 0
var _run_id: String = ""
var _run_settled: bool = false
var _finish_reason: String = "OVERWHELMED"
var _extraction_window: bool = false
var _extraction_timer: float = 0.0
var _kill_tokens: int = 0
var _weapon_index: int = 0
var _slot_ids: Array = ["", "pistol", ""]
var _slot_ammo: Dictionary = {}
var _active_slot: int = 1
var _slot_buttons: Array[Button] = []
var _pending_mystery: int = -1
var _ads: bool = false
var _permanent_upgrades: Dictionary = {}
var _gun_camera: Camera3D
var _quit_dialog: ConfirmationDialog
var _weapon_upgrades: Dictionary = {}
var _loaded: int = 12
var _reserve: int = 72
var _fire_timer: float = 0.0
var _reload_timer: float = 0.0
var _reloading: bool = false
var _mobile_firing: bool = false
var _pending_fire: bool = false
var _game_running: bool = true
var _station_refresh: float = 0.0
var _nearest_station: SupplyStation
var _next_wave_timer: Timer
var _ammo_label: Label
var _wave_label: Label
var _cash_label: Label
var _gun_label: Label
var _crosshair: Label
var _prompt_label: Label
var _feedback_label: Label
var _feedback_timer: float = 0.0
var _game_over_label: Label
var _extract_button: Button
var _retry_button: Button
var _reward_popup: PanelContainer
var _reward_title: Label
var _reward_stats: Label
var _reward_art: WeaponCardArt
var _popup_timer: float = 0.0
var _gun_viewmodel: GunViewmodel
var _loot_parts: int = 0
var _loot_fabrication: int = 0
var _loot_label: Label
var _melee_timer: float = 0.0
var _pending_melee: String = ""
var _melee_buttons: Array[Button] = []


func _ready() -> void:
	if not is_instance_valid(player) or not is_instance_valid(hud) or not is_instance_valid(world):
		push_error("CombatDirector requires a player, HUD and BlockZeroMap")
		set_process(false)
		set_physics_process(false)
		return

	_run_id = SurvivalBank.make_run_id()
	# Permanent guns start equipped. Mystery-box weapons remain match-only.
	var world_save: Dictionary = WorldProgress.load_data()
	_permanent_upgrades = world_save.get("weapon_upgrades", {})
	_initialize_loadout(world_save)
	hud.fire_changed.connect(_set_mobile_firing)
	hud.reload_pressed.connect(_begin_reload)
	hud.aim_changed.connect(_set_ads)
	hud.use_pressed.connect(_try_interact)
	_build_combat_overlay()
	var camera := player.get_node_or_null("CameraPivot/Camera3D") as Camera3D
	_gun_camera = camera
	if is_instance_valid(camera):
		_gun_viewmodel = GunViewmodel.new()
		_gun_viewmodel.name = "FirstPersonWeapon"
		camera.add_child(_gun_viewmodel)
		_gun_viewmodel.set_weapon(str(_weapon()["id"]))

	_next_wave_timer = Timer.new()
	_next_wave_timer.name = "WaveDelay"
	_next_wave_timer.one_shot = true
	_next_wave_timer.wait_time = BETWEEN_WAVES
	add_child(_next_wave_timer)
	_next_wave_timer.timeout.connect(_start_wave)
	_update_all_labels()
	_start_wave()


func _process(delta: float) -> void:
	if _feedback_timer > 0.0:
		_feedback_timer -= delta
		if _feedback_timer <= 0.0:
			_feedback_label.visible = false
	if _pending_mystery >= 0:
		_popup_timer = 0.0
	if _popup_timer > 0.0:
		_popup_timer -= delta
		if _popup_timer <= 0.0:
			_reward_popup.visible = false
	if _extraction_window and _game_running:
		_extraction_timer -= delta
		_extract_button.text = "EXTRACT  (%d s)" % ceili(maxf(0.0, _extraction_timer))
		if _extraction_timer <= 0.0:
			_extraction_window = false
			_extract_button.visible = false
			_next_wave_timer.start()


func _physics_process(delta: float) -> void:
	if not _game_running:
		return
	_fire_timer = maxf(0.0, _fire_timer - delta)
	_melee_timer = maxf(0.0, _melee_timer - delta)
	if _pending_melee != "":
		var chosen: String = _pending_melee
		_pending_melee = ""
		_execute_melee(chosen)
	_spawn_timer = maxf(0.0, _spawn_timer - delta)
	if _pending_spawns > 0 and _alive < MAX_ACTIVE_ZOMBIES and _spawn_timer <= 0.0:
		_spawn_one_zombie()
		_spawn_timer = 0.2
	if _reloading:
		_reload_timer -= delta
		if _reload_timer <= 0.0:
			_finish_reload()

	if not OS.has_feature("mobile") and is_instance_valid(_gun_camera):
		_set_ads(Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT))
	_station_refresh -= delta
	if _station_refresh <= 0.0:
		_station_refresh = 0.14
		_refresh_station_prompt()

	var desktop_fire: bool = not OS.has_feature("mobile") and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)
	if _pending_fire or _mobile_firing or desktop_fire:
		_pending_fire = false
		_fire_weapon()


func _input(event: InputEvent) -> void:
	if not _game_running:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		if event.physical_keycode == KEY_R:
			_begin_reload()
		elif event.physical_keycode == KEY_E:
			_try_interact()
		elif event.physical_keycode == KEY_F:
			_queue_melee("punch")
		elif event.physical_keycode == KEY_G:
			_queue_melee("kick")
		elif event.physical_keycode == KEY_V:
			_queue_melee("knife")
		elif event.physical_keycode == KEY_X and _extraction_window:
			_extract_run()
		elif event.physical_keycode == KEY_1:
			_switch_slot(0)
		elif event.physical_keycode == KEY_2:
			_switch_slot(1)
		elif event.physical_keycode == KEY_3:
			_switch_slot(2)


func _weapon() -> Dictionary:
	return WEAPONS[_weapon_index]

func _lookup_index(id: String) -> int:
	for i in range(WEAPONS.size()):
		if str(WEAPONS[i]["id"]) == id:
			return i
	return 0

func _initialize_loadout(state: Dictionary) -> void:
	_slot_ids = (state.get("weapon_slots", ["", "pistol", ""]) as Array).duplicate()
	if _slot_ids.size() != 3:
		_slot_ids = ["", "pistol", ""]
	_active_slot = clampi(int(state.get("active_weapon_slot",1)),0,2)
	if str(_slot_ids[_active_slot]).is_empty():
		_active_slot = _slot_ids.find("pistol") if _slot_ids.has("pistol") else 1
	for slot in range(3):
		var id: String = str(_slot_ids[slot])
		if id != "":
			var gun: Dictionary = WEAPONS[_lookup_index(id)]
			_slot_ammo[str(slot)] = {"loaded":int(gun["mag"]), "reserve":int(gun["reserve"])}
	_weapon_index = _lookup_index(str(_slot_ids[_active_slot]))
	var ammo: Dictionary = _slot_ammo.get(str(_active_slot),{"loaded":12,"reserve":72})
	_loaded = int(ammo["loaded"])
	_reserve = int(ammo["reserve"])

func _switch_slot(slot: int) -> void:
	if not _game_running or _pending_mystery >= 0 or slot < 0 or slot >= 3:
		return
	var id: String = str(_slot_ids[slot])
	if id == "":
		_announce("EMPTY SLOT — CRAFT IN GUNSMITH OR USE MYSTERY BOX")
		return
	if slot == _active_slot:
		return
	_slot_ammo[str(_active_slot)] = {"loaded":_loaded,"reserve":_reserve}
	_active_slot = slot
	_weapon_index = _lookup_index(id)
	var ammo: Dictionary = _slot_ammo.get(str(slot),{"loaded":int(_weapon()["mag"]),"reserve":int(_weapon()["reserve"])})
	_loaded = int(ammo["loaded"])
	_reserve = int(ammo["reserve"])
	_reloading = false
	_mobile_firing = false
	_pending_fire = false
	_fire_timer = 0.25
	_set_ads(false)
	if is_instance_valid(_gun_viewmodel):
		_gun_viewmodel.set_weapon(id)
	_update_all_labels()

func _set_ads(enabled: bool) -> void:
	_ads = enabled and _game_running and _pending_mystery < 0
	if is_instance_valid(_gun_camera):
		_gun_camera.fov = 57.0 if _ads else 75.0
	if is_instance_valid(_gun_viewmodel):
		_gun_viewmodel.set_ads(_ads)


func _weapon_tier() -> int:
	return int(_permanent_upgrades.get(str(_weapon()["id"]),0)) + _weapon_match_tier()

func _weapon_match_tier() -> int:
	return int(_weapon_upgrades.get(str(_weapon()["id"]),0))


func _set_mobile_firing(active: bool) -> void:
	_mobile_firing = active
	if active:
		_pending_fire = true


func _queue_melee(kind: String) -> void:
	if _game_running:
		_pending_melee = kind


func _execute_melee(kind: String) -> void:
	if not _game_running or _melee_timer > 0.0:
		return
	var power: int = 12
	var reach: float = 1.8
	match kind:
		"kick":
			power = 23
			reach = 2.0
			_melee_timer = 0.85
		"knife":
			power = 40
			reach = 2.0
			_melee_timer = 0.48
		_:
			_melee_timer = 0.58
	var camera := player.get_node_or_null("CameraPivot/Camera3D") as Camera3D
	if not is_instance_valid(camera):
		return
	var origin: Vector3 = camera.global_position
	var end: Vector3 = origin - camera.global_transform.basis.z * reach
	var ray := PhysicsRayQueryParameters3D.create(origin, end)
	ray.exclude = [player.get_rid()]
	var hit: Dictionary = get_world_3d().direct_space_state.intersect_ray(ray)
	if hit.has("collider") and hit["collider"] is OutbreakZombie:
		(hit["collider"] as OutbreakZombie).take_damage(power)
		_announce("%s HIT  +%d DAMAGE" % [kind.to_upper(), power])
	else:
		_announce(kind.to_upper() + " — MISS")


func _fire_weapon() -> void:
	if not _game_running or _pending_mystery >= 0 or _reloading or _fire_timer > 0.0:
		return
	if _loaded <= 0:
		_begin_reload()
		return
	var gun: Dictionary = _weapon()
	_fire_timer = float(gun["interval"])
	_loaded -= 1
	_update_ammo_label()
	if is_instance_valid(_gun_viewmodel):
		_gun_viewmodel.fire()

	var camera: Camera3D = player.get_node_or_null("CameraPivot/Camera3D") as Camera3D
	if not is_instance_valid(camera):
		return
	var start: Vector3 = camera.global_position
	var spread: float = 0.07 if int(gun["pellets"]) > 1 else (0.003 if _ads else 0.015)
	var headshots: int = 0
	var hits: int = 0
	var damage: int = int(round(float(gun["damage"]) * pow(1.35, float(_weapon_tier()))))
	for i in range(int(gun["pellets"])):
		var direction: Vector3 = -camera.global_transform.basis.z
		if spread > 0.0:
			direction = (direction + camera.global_transform.basis.x * randf_range(-spread, spread) + camera.global_transform.basis.y * randf_range(-spread, spread)).normalized()
		var end: Vector3 = start + direction * float(gun["range"])
		var query := PhysicsRayQueryParameters3D.create(start, end)
		query.exclude = [player.get_rid()]
		var hit: Dictionary = get_world_3d().direct_space_state.intersect_ray(query)
		if hit.has("collider") and hit["collider"] is OutbreakZombie:
			var zombie: OutbreakZombie = hit["collider"] as OutbreakZombie
			if zombie.take_damage_at(damage,hit["position"]):
				headshots += 1
			hits += 1
	if headshots > 0:
		_announce("HEADSHOT — 2x DAMAGE")
	elif hits > 0:
		_announce("HIT CONFIRMED")


func _begin_reload() -> void:
	if not _game_running or _reloading or _loaded >= int(_weapon()["mag"]) or _reserve <= 0:
		return
	_reloading = true
	_reload_timer = RELOAD_SECONDS
	if is_instance_valid(_gun_viewmodel):
		_gun_viewmodel.play_reload(RELOAD_SECONDS)
	_update_ammo_label()


func _finish_reload() -> void:
	_reloading = false
	var amount: int = mini(int(_weapon()["mag"]) - _loaded, _reserve)
	_loaded += amount
	_reserve -= amount
	_update_ammo_label()


func _start_wave() -> void:
	if not _game_running:
		return
	_extraction_window = false
	_extract_button.visible = false
	if _wave > 0:
		_reserve = mini(240, _reserve + AMMO_PER_CLEARED_WAVE)
		_update_ammo_label()
	_wave += 1
	# Round 1 = 4, round 2 = 8, round 3 = 16, etc.
	# Spawn queue ensures at most 16 are simulated at one time on Android.
	var total: int = INITIAL_WAVE_ZOMBIES * (1 << (_wave - 1))
	_wave_remaining = total
	_pending_spawns = total
	_alive = 0
	_spawn_timer = 0.0
	for i in range(mini(6, _pending_spawns)):
		_spawn_one_zombie()
	_update_wave_label()
	_announce("ROUND %d — %d INFECTED" % [_wave, total])


func _spawn_one_zombie() -> void:
	if _pending_spawns <= 0 or not _game_running or not is_instance_valid(player):
		return
	var zombie := ZOMBIE_SCENE.instantiate() as OutbreakZombie
	if not is_instance_valid(zombie):
		push_error("Unable to instantiate zombie scene")
		# Don't silently end a wave when a scene is missing.
		return
	var possible: Array[Vector3] = []
	for spawn_point in SPAWN_POINTS:
		if spawn_point.distance_squared_to(player.global_position) > 80.0:
			possible.append(spawn_point)
	var where: Vector3 = SPAWN_POINTS[randi_range(0, SPAWN_POINTS.size() - 1)]
	if not possible.is_empty():
		where = possible[randi_range(0, possible.size() - 1)]
	zombie.position = where + Vector3(randf_range(-1.1, 1.1), 0, randf_range(-1.1, 1.1))
	zombie.target = player
	zombie.defeated.connect(_on_zombie_defeated.bind(zombie))
	zombie.attack_landed.connect(_damage_player)
	add_child(zombie)
	_alive += 1
	_pending_spawns -= 1
	_update_wave_label()

func _on_zombie_defeated(zombie: OutbreakZombie) -> void:
	if not _game_running:
		return
	_alive = maxi(0, _alive - 1)
	_wave_remaining = maxi(0, _wave_remaining - 1)
	_kills += 1
	_kill_tokens += 1
	# Tokens are granted on kill; collectible coins are separate spendable points.
	var at: Vector3 = zombie.global_position + Vector3.UP * 0.7
	for i in range(COINS_PER_ZOMBIE):
		var coin := KillCoin.new()
		coin.value = COIN_VALUE
		coin.player = player
		coin.launch_velocity = Vector3(randf_range(-3.1, 3.1), randf_range(3.4, 5.7), randf_range(-3.1, 3.1))
		coin.collected.connect(_on_coin_collected)
		get_parent().add_child(coin)
		coin.global_position = at
	_update_wave_label()
	_update_cash_label()
	# Active scavenging: rare component drops must be picked up and extracted.
	if randi() % 4 == 0:
		_spawn_loot(zombie.global_position + Vector3.UP * 0.45, "parts")
	if randi() % 9 == 0:
		_spawn_loot(zombie.global_position + Vector3.UP * 0.45, "fabrication")
	if randi() % 9 == 0:
		_spawn_loot(zombie.global_position + Vector3.UP * 0.45, "medkit")
	if randi() % 8 == 0:
		_spawn_loot(zombie.global_position + Vector3.UP * 0.45, "ammo")
	if _wave_remaining == 0 and _pending_spawns == 0:
		if _wave % 5 == 0:
			_extraction_window = true
			_extraction_timer = EXTRACTION_SECONDS
			_extract_button.visible = true
			_announce("ROUND CLEARED — EXTRACT OR CONTINUE")
		else:
			_next_wave_timer.start()
			_announce("WAVE CLEARED — COLLECT YOUR COINS")


func _spawn_loot(at: Vector3, loot_kind: String) -> void:
	var drop := ScavengePickup.new()
	drop.kind = loot_kind
	drop.target = player
	drop.collected.connect(_receive_loot)
	drop.save_failed.connect(_announce)
	get_parent().add_child(drop)
	drop.global_position = at


func _receive_loot(kind: String, amount: int) -> void:
	if not _game_running:
		return
	match kind:
		"parts":
			_loot_parts += amount
		"fabrication":
			_loot_fabrication += amount
		"medkit":
			player.health = mini(player.maximum_health, player.health + 25 * amount)
			player.health_changed.emit(player.health, player.maximum_health)
		"ammo":
			_reserve = mini(999, _reserve + int(_weapon()["mag"]) * amount)
			_update_ammo_label()
	_update_loot_label()
	_announce("STORED: " + kind.to_upper() if ["parts", "fabrication"].has(kind) else "LOOT: " + kind.to_upper())


func _on_coin_collected(amount: int) -> void:
	if not _game_running or amount <= 0:
		return
	_points += amount
	_earned_total += amount
	_update_cash_label()


func _damage_player(amount: int) -> void:
	if not _game_running or not is_instance_valid(player):
		return
	player.health = maxi(0, player.health - maxi(amount, 0))
	player.health_changed.emit(player.health, player.maximum_health)
	if player.health <= 0:
		_finish_run("OVERWHELMED")


func _extract_run() -> void:
	if _extraction_window and _game_running:
		_finish_run("EXTRACTED")


func _finish_run(reason: String) -> void:
	if _run_settled:
		return
	_pending_mystery = -1
	_reward_popup.visible = false
	_finish_reason = reason
	_game_running = false
	_extraction_window = false
	_mobile_firing = false
	_next_wave_timer.stop()
	_extract_button.visible = false
	_game_over_label.visible = true
	var result: Dictionary = SurvivalBank.settle_run(_run_id, _points, _wave)
	if not bool(result.get("ok", false)):
		_game_over_label.text = "BANK SAVE FAILED\n" + str(result.get("error", "Unknown error"))
		_retry_button.visible = true
		return
	# Picked-up FAB and parts are credited immediately in WorldProgress on collection.
	# Do not deposit them again on extraction or death.
	_run_settled = true
	_retry_button.visible = false
	_game_over_label.text = "%s\nBANKED +%d  |  BANK %d\nPERMANENT SALVAGE: +%d PARTS  +%d FAB" % [reason, int(result.get("deposited",0)), int(result.get("balance",0)), _loot_parts, _loot_fabrication]
	_return_to_menu()


func _retry_save() -> void:
	_finish_run(_finish_reason)


func _return_to_menu() -> void:
	await get_tree().create_timer(6.0).timeout
	get_tree().change_scene_to_file("res://scenes/menu.tscn")


func _refresh_station_prompt() -> void:
	_nearest_station = null
	var best: float = 3.15 * 3.15
	for station in world.stations:
		if not is_instance_valid(station):
			continue
		var ds: float = station.global_position.distance_squared_to(player.global_position)
		if ds < best:
			best = ds
			_nearest_station = station
	if not is_instance_valid(_nearest_station):
		_prompt_label.visible = false
		return
	var label: String = ""
	match _nearest_station.station_type:
		"mystery":
			label = "MYSTERY: %d POINTS" % MYSTERY_COST
		"upgrade":
			var level: int = _weapon_tier()
			label = "UPGRADE MAXED" if level >= MAX_UPGRADE_LEVEL else "UPGRADE: %d POINTS (LVL %d)" % [BASE_UPGRADE_COST * (1 << _weapon_match_tier()), level + 1]
		"heal":
			label = "HEAL +%d HP: %d KILL TOKENS" % [HEAL_AMOUNT, HEAL_TOKEN_COST]
		"ammo":
			label = "AMMO RESUPPLY: %d MATCH POINTS" % AMMO_COST
	_prompt_label.text = "USE / E — " + label
	_prompt_label.visible = true


func _try_interact() -> void:
	if not _game_running or _pending_mystery >= 0:
		return
	_refresh_station_prompt()
	if not is_instance_valid(_nearest_station):
		if _extraction_window:
			_extract_run()
		else:
			_announce("MOVE NEAR A SUPPLY BOX")
		return
	match _nearest_station.station_type:
		"mystery":
			if _points < MYSTERY_COST:
				_announce("NEED %d MORE POINTS" % (MYSTERY_COST - _points))
				return
			_points -= MYSTERY_COST
			_spent_total += MYSTERY_COST
			var options: Array[int] = []
			for i in range(WEAPONS.size()):
				if i != _weapon_index:
					options.append(i)
			_pending_mystery = options.pick_random()
			_mobile_firing = false
			_pending_fire = false
			_set_ads(false)
			_show_mystery_reward()
			_announce("MYSTERY GUN — CHOOSE THE SLOT TO REPLACE")
		"upgrade":
			var level: int = _weapon_tier()
			if level >= MAX_UPGRADE_LEVEL:
				_announce("THIS WEAPON IS MAXED")
				return
			var cost: int = BASE_UPGRADE_COST * (1 << _weapon_match_tier())
			if _points < cost:
				_announce("NEED %d MORE POINTS" % (cost - _points))
				return
			_points -= cost
			_spent_total += cost
			_weapon_upgrades[str(_weapon()["id"])] = _weapon_match_tier() + 1
			_loaded = int(_weapon()["mag"])
			_announce("WEAPON LVL %d — NEXT COST DOUBLES" % (level + 1))
		"ammo":
			if _points < AMMO_COST:
				_announce("NEED %d MORE MATCH POINTS" % (AMMO_COST - _points))
				return
			_points -= AMMO_COST
			_spent_total += AMMO_COST
			_reserve = mini(999, _reserve + 3 * int(_weapon()["mag"]))
			_announce("AMMO RESUPPLIED")
		"heal":
			if player.health >= player.maximum_health:
				_announce("HEALTH ALREADY FULL")
				return
			if _kill_tokens < HEAL_TOKEN_COST:
				_announce("NEED %d KILL TOKENS" % (HEAL_TOKEN_COST - _kill_tokens))
				return
			_kill_tokens -= HEAL_TOKEN_COST
			player.health = mini(player.maximum_health, player.health + HEAL_AMOUNT)
			player.health_changed.emit(player.health, player.maximum_health)
			_announce("HEALTH RESTORED +%d" % HEAL_AMOUNT)
	_update_all_labels()
	_refresh_station_prompt()


func _build_combat_overlay() -> void:
	var layer := CanvasLayer.new()
	layer.name = "CombatOverlay"
	layer.layer = 2
	add_child(layer)
	var overlay := Control.new()
	overlay.name = "CombatLabels"
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(overlay)
	_ammo_label = _make_label(17, Color(1.0, 0.94, 0.79))
	_wave_label = _make_label(16, Color(0.86, 0.96, 0.86))
	_cash_label = _make_label(16, Color(1.0, 0.81, 0.24))
	_gun_label = _make_label(14, Color(0.78, 0.88, 0.94))
	_loot_label = _make_label(15, Color(0.69, 0.89, 1.0))
	_crosshair = _make_label(25, Color(0.95, 0.98, 0.93))
	_prompt_label = _make_label(15, Color(1.0, 0.91, 0.56))
	_feedback_label = _make_label(19, Color(1.0, 0.92, 0.73))
	_game_over_label = _make_label(23, Color(1.0, 0.85, 0.69))
	_crosshair.text = "+"
	_crosshair.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_prompt_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_feedback_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_game_over_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_game_over_label.text = "YOU WERE OVERWHELMED"
	_game_over_label.visible = false
	_prompt_label.visible = false
	_feedback_label.visible = false
	for label in [_ammo_label, _wave_label, _cash_label, _gun_label, _loot_label, _crosshair, _prompt_label, _feedback_label, _game_over_label]:
		overlay.add_child(label)
	_extract_button = Button.new()
	_extract_button.text = "EXTRACT"
	_extract_button.visible = false
	_extract_button.pressed.connect(_extract_run)
	overlay.add_child(_extract_button)
	for i in range(3):
		var weapon_slot := Button.new()
		weapon_slot.text = "SLOT %d" % (i+1)
		weapon_slot.custom_minimum_size = Vector2(93,40)
		weapon_slot.add_theme_font_size_override("font_size",12)
		weapon_slot.pressed.connect(_switch_slot.bind(i))
		overlay.add_child(weapon_slot)
		_slot_buttons.append(weapon_slot)
	var exit_button := Button.new()
	exit_button.text = "QUIT RUN"
	exit_button.custom_minimum_size = Vector2(110,37)
	exit_button.pressed.connect(func(): _quit_dialog.popup_centered())
	overlay.add_child(exit_button)
	exit_button.position = Vector2(540,16)
	_quit_dialog = ConfirmationDialog.new()
	_quit_dialog.title = "ABANDON SURVIVAL RUN?"
	_quit_dialog.dialog_text = "Quit without extraction? Unspent match points will NOT be banked. Saved crafting loot and permanent weapons remain."
	_quit_dialog.confirmed.connect(func(): get_tree().change_scene_to_file("res://scenes/menu.tscn"))
	add_child(_quit_dialog)
	_retry_button = Button.new()
	_retry_button.text = "RETRY BANK SAVE"
	_retry_button.visible = false
	_retry_button.pressed.connect(_retry_save)
	overlay.add_child(_retry_button)
	# Touch-friendly melee fallback; no ammunition needed.
	for kind in ["PUNCH", "KICK", "KNIFE"]:
		var button := Button.new()
		button.text = kind
		button.custom_minimum_size = Vector2(72, 38)
		button.pressed.connect(_queue_melee.bind(kind.to_lower()))
		button.add_theme_font_size_override("font_size", 13)
		overlay.add_child(button)
		_melee_buttons.append(button)
	_build_reward_popup(layer)
	get_viewport().size_changed.connect(_layout_overlay)
	_layout_overlay()


func _make_label(font_size: int, font_color: Color) -> Label:
	var label := Label.new()
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", font_color)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label


func _layout_overlay() -> void:
	if not is_instance_valid(_ammo_label):
		return
	var viewport: Vector2 = get_viewport().get_visible_rect().size
	_ammo_label.position = Vector2(viewport.x - 250.0, 18.0)
	_ammo_label.size = Vector2(232.0, 28.0)
	_ammo_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_gun_label.position = Vector2(viewport.x - 300.0, 49.0)
	_gun_label.size = Vector2(282.0, 32.0)
	_gun_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_wave_label.position = Vector2(18.0, 79.0)
	_wave_label.size = Vector2(540.0, 28.0)
	_cash_label.position = Vector2(18.0, 111.0)
	_cash_label.size = Vector2(350.0, 28.0)
	_loot_label.position = Vector2(18.0, 142.0)
	_loot_label.size = Vector2(350.0, 28.0)
	for i in range(_slot_buttons.size()):
		_slot_buttons[i].position = Vector2(18.0 + i*97.0,viewport.y*0.49)
		_slot_buttons[i].size = Vector2(93,42)
	for i in range(_melee_buttons.size()):
		# Vertical stack on the left-center, away from the USE/FIRE touch zones.
		_melee_buttons[i].position = Vector2(viewport.x * 0.40, viewport.y * 0.55 + 48.0 * i)
		_melee_buttons[i].size = Vector2(76.0, 42.0)
	_crosshair.position = Vector2(viewport.x * 0.5 - 24.0, viewport.y * 0.5 - 26.0)
	_crosshair.size = Vector2(48.0, 48.0)
	_prompt_label.position = Vector2(viewport.x * 0.5 - 250.0, viewport.y * 0.70)
	_prompt_label.size = Vector2(500.0, 34.0)
	_feedback_label.position = Vector2(viewport.x * 0.5 - 260.0, viewport.y * 0.16)
	_feedback_label.size = Vector2(520.0, 42.0)
	_game_over_label.position = Vector2(viewport.x * 0.5 - 300.0, viewport.y * 0.30)
	_game_over_label.size = Vector2(600.0, 140.0)
	_extract_button.position = Vector2(viewport.x * 0.50 - 94.0, 18.0)
	_extract_button.size = Vector2(188.0, 50.0)
	_retry_button.position = Vector2(viewport.x * 0.5 - 115.0, viewport.y * 0.63)
	_retry_button.size = Vector2(230.0, 44.0)
	_reward_popup.position = Vector2(viewport.x * 0.5 - 195.0, viewport.y * 0.5 - 128.0)


func _announce(message: String) -> void:
	_feedback_label.text = message
	_feedback_label.visible = true
	_feedback_timer = 2.5


func _update_all_labels() -> void:
	_update_ammo_label()
	_update_wave_label()
	_update_cash_label()
	_update_gun_label()
	_update_loot_label()
	_update_slot_labels()


func _update_slot_labels() -> void:
	for i in range(_slot_buttons.size()):
		var id: String = str(_slot_ids[i])
		_slot_buttons[i].text = "%d %s" % [i+1,"--" if id.is_empty() else id.to_upper()]
		_slot_buttons[i].disabled = id.is_empty() or not _game_running or _pending_mystery >= 0
		_slot_buttons[i].modulate = Color(0.43,1.0,0.74) if i == _active_slot else Color.WHITE

func _update_ammo_label() -> void:
	_ammo_label.text = "AMMO  %d / %d%s" % [_loaded, _reserve, "  RELOADING" if _reloading else ""]


func _update_wave_label() -> void:
	_wave_label.text = "ROUND %d  |  LEFT %d  |  FIELD %d  |  KILLS %d" % [_wave, _wave_remaining, _alive, _kills]


func _update_cash_label() -> void:
	_cash_label.text = "MATCH %d  |  KILL TOKENS %d" % [_points, _kill_tokens]


func _update_loot_label() -> void:
	_loot_label.text = "SAVED SALVAGE  |  PARTS +%d  |  FAB +%d" % [_loot_parts, _loot_fabrication]


func _update_gun_label() -> void:
	_gun_label.text = "SLOT %d  |  %s  |  LVL %d" % [_active_slot+1,str(_weapon()["name"]), _weapon_tier()]


func _build_reward_popup(layer: CanvasLayer) -> void:
	_reward_popup = PanelContainer.new()
	_reward_popup.name = "MysteryRewardPopup"
	_reward_popup.visible = false
	_reward_popup.custom_minimum_size = Vector2(390.0, 248.0)
	layer.add_child(_reward_popup)
	var stack := VBoxContainer.new()
	stack.add_theme_constant_override("separation", 5)
	_reward_popup.add_child(stack)
	_reward_title = _make_label(23, Color(1.0,0.89,0.48))
	_reward_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stack.add_child(_reward_title)
	_reward_art = WeaponCardArt.new()
	_reward_art.custom_minimum_size = Vector2(360, 122)
	stack.add_child(_reward_art)
	_reward_stats = _make_label(17, Color(0.88,0.95,0.93))
	_reward_stats.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stack.add_child(_reward_stats)
	var info := _make_label(14, Color(0.75,0.85,0.86))
	info.text = "MATCH ONLY — CHOOSE A SLOT. NO PERMANENT UNLOCK."
	info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stack.add_child(info)
	var row := HBoxContainer.new()
	stack.add_child(row)
	for slot in range(3):
		var button := Button.new()
		button.text = "EQUIP %d" % (slot+1)
		button.custom_minimum_size = Vector2(80,42)
		button.pressed.connect(_equip_mystery.bind(slot))
		row.add_child(button)
	var decline := Button.new()
	decline.text = "DECLINE"
	decline.custom_minimum_size = Vector2(93,42)
	decline.pressed.connect(_decline_mystery)
	row.add_child(decline)

func _show_mystery_reward() -> void:
	if _pending_mystery < 0:
		return
	var gun: Dictionary = WEAPONS[_pending_mystery]
	var colors: Array[String] = ["COMMON", "UNCOMMON", "RARE", "EPIC", "LEGENDARY"]
	var rarity: String = colors[mini(_pending_mystery,colors.size()-1)]
	_reward_title.text = "%s  |  %s" % [rarity,str(gun["name"])]
	_reward_stats.text = "DAMAGE %d  |  MAG %d  |  RANGE %dm" % [int(gun["damage"]),int(gun["mag"]),int(float(gun["range"]))]
	_reward_art.set_weapon(str(gun["id"]))
	_reward_popup.visible = true
	_popup_timer = 0.0
	_update_slot_labels()

func _equip_mystery(slot: int) -> void:
	if _pending_mystery < 0 or not _game_running:
		return
	var gun: Dictionary = WEAPONS[_pending_mystery]
	_slot_ammo[str(_active_slot)] = {"loaded":_loaded,"reserve":_reserve}
	_slot_ids[slot] = str(gun["id"])
	_slot_ammo[str(slot)] = {"loaded":int(gun["mag"]),"reserve":int(gun["reserve"])}
	_pending_mystery = -1
	_reward_popup.visible = false
	# Use the standard switching path to restore the destination slot's ammo.
	if slot == _active_slot:
		_weapon_index = _lookup_index(str(gun["id"]))
		_loaded = int(gun["mag"])
		_reserve = int(gun["reserve"])
		_reloading = false
		if is_instance_valid(_gun_viewmodel):
			_gun_viewmodel.set_weapon(str(gun["id"]))
	else:
		_switch_slot(slot)
	_announce("MYSTERY %s EQUIPPED IN SLOT %d" % [str(gun["name"]),slot+1])
	_update_all_labels()

func _decline_mystery() -> void:
	_pending_mystery = -1
	_reward_popup.visible = false
	_announce("REWARD DECLINED — PAID POINTS ARE NOT REFUNDED")
	_update_slot_labels()
