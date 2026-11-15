extends Node3D

# Module 009: small, offline Florida open-world vertical slice. It is not GTA,
# a complete Florida recreation, multiplayer, or a real-world property market.
const PLAYER_SCENE: PackedScene = preload("res://scenes/player.tscn")
const HUD_SCENE: PackedScene = preload("res://scenes/hud.tscn")
const ZOMBIE_SCENE: PackedScene = preload("res://scenes/zombie.tscn")
const MENU: String = "res://scenes/menu.tscn"
const GARAGE: Vector3 = Vector3(22, 0, -22)
const CLINIC: Vector3 = Vector3(-22, 0, 22)
const RELOAD_TIME: float = 1.4
const ASPHALT: Texture2D = preload("res://assets/world/asphalt.png")
const CONCRETE: Texture2D = preload("res://assets/world/weathered_concrete.png")

var _player: FirstPersonPlayer
var _hud: TouchHUD
var _district: DistrictWorld
var _car: ArcadeVehicle
var _car_camera: Camera3D
var _third_camera: Camera3D
var _third_person: bool = false
var _survivor_model: Node3D
var _viewmodel: GunViewmodel
var _tiles: Node3D
var _map: OpenWorldMinimap
var _status: Label
var _notice: Label
var _mission: Label
var _ammo: Label
var _enter_button: Button
var _build_panel: PanelContainer
var _build_label: Label
var _region: String = "orlando"
var _car_mode: bool = false
var _joystick: Vector2 = Vector2.ZERO
var _firing: bool = false
var _loaded: int = 12
var _reserve: int = 72
var _reloading: float = 0.0
var _shot_cooldown: float = 0.0
var _spawn_timer: float = 1.0
var _status_timer: float = 0.0
var _save_timer: float = 0.0
var _stream_timer: float = 0.0
var _notice_timer: float = 0.0
var _zombies: Array[OutbreakZombie] = []
var _weapon: Dictionary = {}
var _slot_ids: Array = ["", "pistol", ""]
var _slot_ammo: Dictionary = {}
var _active_slot: int = 1
var _slot_buttons: Array[Button] = []
var _ads: bool = false
var _permanent_upgrades: Dictionary = {}

var _build_kind: String = "generator"
var _selected_plot: String = "O-01"

func _ready() -> void:
    var state: Dictionary = WorldProgress.load_data()
    _region = str(state.get("region", "orlando"))
    _selected_plot = str(state.get("plot", "O-01"))
    _district = DistrictWorld.new()
    add_child(_district)
    _tiles = Node3D.new()
    _tiles.name = "StreamingOuterNeighborhoods"
    add_child(_tiles)
    _player = PLAYER_SCENE.instantiate() as FirstPersonPlayer
    add_child(_player)
    _player.global_position = WorldProgress.restore_position(_region)
    _hud = HUD_SCENE.instantiate() as TouchHUD
    add_child(_hud)
    _hud.move_changed.connect(_on_movement)
    _hud.look_changed.connect(_player.apply_touch_look)
    _hud.jump_pressed.connect(_on_jump)
    _hud.sprint_changed.connect(_player.set_mobile_sprinting)
    _hud.use_pressed.connect(_interact)
    _hud.fire_changed.connect(_on_fire)
    _hud.reload_pressed.connect(_reload)
    _hud.aim_changed.connect(_set_ads)
    _player.health_changed.connect(_hud.set_health)
    _hud.set_health(_player.health, _player.maximum_health)
    _permanent_upgrades = state.get("weapon_upgrades", {})
    _initialize_loadout(state)
    var camera := _player.get_node("CameraPivot/Camera3D") as Camera3D
    _viewmodel = GunViewmodel.new()
    camera.add_child(_viewmodel)
    _viewmodel.set_weapon(str(_weapon["id"]))
    _car = ArcadeVehicle.new()
    add_child(_car)
    _car.global_position = Vector3(0,0.12,6)
    _car_camera = Camera3D.new()
    _car_camera.name = "VehicleFollowCamera"
    _car_camera.fov = 72.0
    add_child(_car_camera)
    _car_camera.current = false
    _third_camera = Camera3D.new()
    _third_camera.name = "ThirdPersonExploreCamera"
    _third_camera.fov = 75.0
    add_child(_third_camera)
    _third_camera.current = false
    _create_survivor_model()
    _build_ui()
    _place_landmark("GARAGE", GARAGE, Color(0.89,0.66,0.22))
    _place_landmark("CLINIC", CLINIC, Color(0.24,0.73,0.50))
    if _region == "orlando":
        _place_landmark("SAFEHOUSE", Vector3(-33,0,-23), Color(0.25,0.56,0.75))
    _refresh_tiles()
    _refresh_labels()
    _announce("OPEN WORLD: follow the mission marker; press USE near sites or the truck")

func _definition(id: String) -> Dictionary:
    for candidate in CombatDirector.WEAPONS:
        if str(candidate["id"]) == id:
            return candidate
    return CombatDirector.WEAPONS[0]

func _initialize_loadout(world_state: Dictionary) -> void:
    _slot_ids = (world_state.get("weapon_slots", ["", "pistol", ""]) as Array).duplicate()
    if _slot_ids.size() != 3:
        _slot_ids = ["", "pistol", ""]
    _active_slot = clampi(int(world_state.get("active_weapon_slot", 1)),0,2)
    if str(_slot_ids[_active_slot]).is_empty():
        _active_slot = _slot_ids.find("pistol") if _slot_ids.has("pistol") else 1
    for i in range(3):
        var id: String = str(_slot_ids[i])
        if id != "":
            var def: Dictionary = _definition(id)
            _slot_ammo[str(i)] = {"loaded":int(def["mag"]), "reserve":int(def["reserve"])}
    _weapon = _definition(str(_slot_ids[_active_slot]))
    var state: Dictionary = _slot_ammo.get(str(_active_slot), {"loaded":12,"reserve":72})
    _loaded = int(state["loaded"])
    _reserve = int(state["reserve"])

func _switch_weapon(slot: int) -> void:
    if _car_mode or slot < 0 or slot >= 3:
        return
    var id: String = str(_slot_ids[slot])
    if id.is_empty():
        _announce("SLOT %d EMPTY — CRAFT AND EQUIP A GUN AT GUNSMITH" % (slot+1))
        return
    if slot == _active_slot:
        return
    _slot_ammo[str(_active_slot)] = {"loaded":_loaded, "reserve":_reserve}
    _active_slot = slot
    _weapon = _definition(id)
    var ammo: Dictionary = _slot_ammo.get(str(slot), {"loaded":int(_weapon["mag"]),"reserve":int(_weapon["reserve"])})
    _loaded = int(ammo["loaded"])
    _reserve = int(ammo["reserve"])
    _reloading = 0.0
    _shot_cooldown = 0.35
    _firing = false
    _set_ads(false)
    _viewmodel.set_weapon(id)
    if not WorldProgress.set_active_weapon_slot(slot):
        _announce("WARNING: ACTIVE WEAPON PREFERENCE NOT SAVED")
    _refresh_labels()

func _set_ads(enabled: bool) -> void:
    _ads = enabled and not _car_mode and not _third_person
    var camera := _player.get_node_or_null("CameraPivot/Camera3D") as Camera3D
    if is_instance_valid(camera):
        camera.fov = 57.0 if _ads else 75.0
    if is_instance_valid(_viewmodel):
        _viewmodel.set_ads(_ads)

func _open_armory() -> void:
    if _car_mode or _region != "orlando" or _player.global_position.distance_to(Vector3(-33,0,-23)) > 8.0:
        _announce("ARMORY: GO TO THE SAFEHOUSE IN ORLANDO")
        return
    WorldProgress.remember_position(_region,_player.global_position)
    get_tree().change_scene_to_file("res://scenes/arsenal.tscn")

func _on_movement(direction: Vector2) -> void:
    _joystick = direction
    if not _car_mode:
        _player.set_mobile_movement(direction)

func _on_jump() -> void:
    if not _car_mode:
        _player.request_jump()

func _on_fire(active: bool) -> void:
    _firing = active and not _car_mode

func _input(event: InputEvent) -> void:
    if event is InputEventKey and event.pressed and not event.echo:
        if event.physical_keycode == KEY_E:
            _interact()
        elif event.physical_keycode == KEY_R:
            _reload()
        elif event.physical_keycode == KEY_F:
            _melee(30, 1.6)
        elif event.physical_keycode == KEY_G:
            _melee(42, 1.9)
        elif event.physical_keycode == KEY_V:
            _melee(65, 2.1)
        elif event.physical_keycode == KEY_1:
            _switch_weapon(0)
        elif event.physical_keycode == KEY_2:
            _switch_weapon(1)
        elif event.physical_keycode == KEY_3:
            _switch_weapon(2)

func _physics_process(delta: float) -> void:
    _shot_cooldown = maxf(0.0, _shot_cooldown - delta)
    if _reloading > 0.0:
        _reloading -= delta
        if _reloading <= 0.0:
            var transfer: int = mini(int(_weapon["mag"]) - _loaded, _reserve)
            _loaded += transfer
            _reserve -= transfer
            _refresh_labels()
    if _car_mode:
        var keyboard: Vector2 = Input.get_vector("move_left","move_right","move_forward","move_back")
        var direction: Vector2 = _joystick if _joystick.length_squared() > 0.01 else keyboard
        _car.drive(-direction.y,direction.x,delta)
        # Zombie AI still sees the player's tracked position while the car is occupied.
        _player.global_position = _car.global_position + Vector3(0,0.1,0)
        var camera_from: Vector3 = _car.global_position + _car.global_transform.basis * Vector3(0,4.2,8)
        _car_camera.global_position = _car_camera.global_position.lerp(camera_from, minf(delta*6.0,1.0))
        _car_camera.look_at(_car.global_position + Vector3.UP*1.3,Vector3.UP)
    elif _firing or (not OS.has_feature("mobile") and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED):
        _shoot()
    _spawn_timer -= delta
    if _third_person and not _car_mode:
        var behind: Vector3 = _player.global_position + _player.global_transform.basis * Vector3(0,2.9,3.2)
        _third_camera.global_position = _third_camera.global_position.lerp(behind,minf(delta*8.0,1.0))
        _third_camera.look_at(_player.global_position+Vector3.UP*1.25,Vector3.UP)
    if _spawn_timer <= 0.0:
        _spawn_timer = 3.0
        if _zombies.size() < 7 and _player.health > 0:
            _spawn_zombie()

func _process(delta: float) -> void:
    _status_timer += delta
    _save_timer += delta
    _stream_timer += delta
    if _notice_timer > 0.0:
        _notice_timer -= delta
        if _notice_timer <= 0.0:
            _notice.text = ""
    if _status_timer > 0.65:
        _status_timer = 0.0
        _refresh_labels()
        _update_map()
        _refresh_selected_plot()
    if _save_timer > 15.0:
        _save_timer = 0.0
        var okay: bool = WorldProgress.remember_position(_region,_player.global_position)
        if not okay:
            _announce("WARNING: Open world position was not saved")
    if _stream_timer > 1.5:
        _stream_timer = 0.0
        _refresh_tiles()

func _build_ui() -> void:
    var layer := CanvasLayer.new()
    layer.name = "OpenWorldHUD"
    layer.layer = 4
    add_child(layer)
    var top := HBoxContainer.new()
    top.position = Vector2(218,5)
    top.add_theme_constant_override("separation",5)
    layer.add_child(top)
    _enter_button = _make_button(top,"CAR / EXIT",_interact,108)
    _make_button(top,"BUILD",_toggle_build,79)
    _make_button(top,"VIEW",_toggle_view,71)
    _make_button(top,"MISSIONS",_show_mission,94)
    _make_button(top,"CITY",_switch_region,78)
    _make_button(top,"MENU",_to_menu,82)
    _make_button(top,"ARMORY",_open_armory,82)
    _status = Label.new()
    _status.position = Vector2(18,80)
    _status.size = Vector2(750,28)
    _status.add_theme_font_size_override("font_size",15)
    layer.add_child(_status)
    _mission = Label.new()
    _mission.position = Vector2(18,110)
    _mission.size = Vector2(730,40)
    _mission.add_theme_font_size_override("font_size",15)
    layer.add_child(_mission)
    _ammo = Label.new()
    _ammo.position = Vector2(20,145)
    _ammo.size = Vector2(400,32)
    _ammo.add_theme_font_size_override("font_size",15)
    layer.add_child(_ammo)
    _notice = Label.new()
    _notice.position = Vector2(18,175)
    _notice.size = Vector2(790,52)
    _notice.add_theme_font_size_override("font_size",16)
    layer.add_child(_notice)
    var weapon_row := HBoxContainer.new()
    weapon_row.name = "ThreeWeaponSlots"
    weapon_row.position = Vector2(18,285)
    weapon_row.add_theme_constant_override("separation",4)
    layer.add_child(weapon_row)
    for i in range(3):
        var btn := _make_button(weapon_row,"SLOT %d" % (i+1),_switch_weapon.bind(i),93)
        btn.add_theme_font_size_override("font_size",12)
        _slot_buttons.append(btn)
    _map = OpenWorldMinimap.new()
    _map.position = Vector2(780,75)
    _map.size = Vector2(164,164)
    layer.add_child(_map)
    var melee := HBoxContainer.new()
    melee.position = Vector2(365,452)
    melee.add_theme_constant_override("separation",5)
    layer.add_child(melee)
    _make_button(melee,"PUNCH",func(): _melee(30,1.6),78)
    _make_button(melee,"KICK",func(): _melee(42,1.9),69)
    _make_button(melee,"KNIFE",func(): _melee(65,2.1),70)
    _build_panel = PanelContainer.new()
    _build_panel.visible = false
    _build_panel.position = Vector2(155,205)
    _build_panel.custom_minimum_size = Vector2(570,240)
    layer.add_child(_build_panel)
    var content := VBoxContainer.new()
    _build_panel.add_child(content)
    _build_label = Label.new()
    content.add_child(_build_label)
    var group := HBoxContainer.new()
    content.add_child(group)
    _make_button(group,"CLAIM 10 FAB",_claim_plot,122)
    for kind in ["generator","workshop","watchtower","supply_cache"]:
        _make_button(group,kind.to_upper(),_build_on_plot.bind(kind),102)
    _make_button(content,"CLOSE BUILD MENU",_toggle_build,560)

func _make_button(parent: Node, title: String, action: Callable, width: float) -> Button:
    var button := Button.new()
    button.text = title
    button.custom_minimum_size = Vector2(width,39)
    button.pressed.connect(action)
    parent.add_child(button)
    return button

func _announce(message: String) -> void:
    if is_instance_valid(_notice):
        _notice.text = message
        _notice_timer = 4.0

func _refresh_labels() -> void:
    if not is_instance_valid(_status):
        return
    var state: Dictionary = WorldProgress.load_data()
    _status.text = "%s | PLOT %s | PARTS %d | FAB %d | ZOMBIES %d" % [str(WorldProgress.REGIONS[_region]),str(state["plot"]),int(state["gun_parts"]),int(state["fabrication_tokens"]),_zombies.size()]
    var stage: int = WorldProgress.mission_stage(_region)
    var goal: Vector3 = CLINIC if stage == 1 else GARAGE
    var distance: int = int(_player.global_position.distance_to(goal))
    _mission.text = "%s  |  %dm  |  USE near marker" % ["SUPPLY DELIVERY → CLINIC" if stage == 1 else "COLLECT SUPPLIES → GARAGE",distance]
    _ammo.text = "SLOT %d  |  %s  |  AMMO %d/%d%s" % [_active_slot+1,str(_weapon["name"]),_loaded,_reserve," (RELOADING)" if _reloading > 0.0 else ""]
    for i in range(_slot_buttons.size()):
        var id: String = str(_slot_ids[i])
        _slot_buttons[i].text = "%d %s" % [i+1, "--" if id.is_empty() else id.to_upper()]
        _slot_buttons[i].disabled = id.is_empty() or _car_mode
        _slot_buttons[i].modulate = Color(0.43,1.0,0.74) if i == _active_slot else Color.WHITE
    _enter_button.text = "EXIT CAR" if _car_mode else "ENTER CAR"
    _enter_button.disabled = not _car_mode and _player.global_position.distance_to(_car.global_position) > 5.0
    if _build_panel.visible:
        _build_label.text = "%s / %s — CLAIM OR BUILD (stored on this plot)" % [_region.to_upper(),_selected_plot]

func _refresh_selected_plot() -> void:
    if _car_mode:
        return
    var closest: float = 18.0*18.0
    var found: String = ""
    var prefix: String = "O-" if _region == "orlando" else "T-"
    for i in range(1,17):
        var id: String = "%s%02d" % [prefix,i]
        var distance: float = _player.global_position.distance_squared_to(DistrictWorld.plot_center(id))
        if distance < closest:
            closest = distance
            found = id
    if not found.is_empty() and found != _selected_plot:
        _selected_plot = found
        WorldProgress.select_plot(_region,found)

func _update_map() -> void:
    var goal: Vector3 = CLINIC if WorldProgress.mission_stage(_region) == 1 else GARAGE
    _map.position_3d = _player.global_position
    _map.vehicle_position = _car.global_position
    _map.destination = goal
    _map.in_vehicle = _car_mode
    _map.queue_redraw()

func _interact() -> void:
    if _car_mode:
        _exit_vehicle()
        return
    if _player.global_position.distance_to(_car.global_position) < 4.1:
        _enter_vehicle()
        return
    if _player.global_position.distance_to(GARAGE) < 5.5:
        var result: Dictionary = WorldProgress.mission_interact(_region,false)
        _announce(str(result.get("message","Mission unavailable")))
        return
    if _region == "orlando" and _player.global_position.distance_to(Vector3(-33,0,-23)) < 5.5:
        var rested: Dictionary = WorldProgress.rest_at_safehouse()
        _announce(str(rested.get("message","Safehouse unavailable")))
        if bool(rested.get("ok",false)):
            _player.health = _player.maximum_health
            _player.health_changed.emit(_player.health,_player.maximum_health)
        return
    if _player.global_position.distance_to(CLINIC) < 5.5:
        var result: Dictionary = WorldProgress.mission_interact(_region,true)
        _announce(str(result.get("message","Mission unavailable")))
        return
    var distance: float = _player.global_position.distance_to(DistrictWorld.plot_center(_selected_plot) + Vector3(0,0,9.5))
    if distance < 5.5:
        var salvage: Dictionary = WorldProgress.salvage_site(_region,_selected_plot)
        _announce(str(salvage.get("message","Scavenging unavailable")))
    else:
        _announce("Go to the garage, clinic or a parcel salvage pile. Use BUILD for plots.")

func _enter_vehicle() -> void:
    _set_ads(false)
    _car_mode = true
    _firing = false
    _player.set_mobile_movement(Vector2.ZERO)
    _player.velocity = Vector3.ZERO
    _player.set_physics_process(false)
    _player.set_process(false)
    _player.visible = false
    (_player.get_node("CameraPivot/Camera3D") as Camera3D).current = false
    _car_camera.global_position = _car.global_position + Vector3(0,4,7)
    _car_camera.current = true
    _third_camera.current = false
    _hud.set_combat_controls_visible(false)
    _viewmodel.visible = false
    _survivor_model.visible = false
    _announce("DRIVING: joystick UP to accelerate, LEFT/RIGHT to steer, USE to exit")

func _exit_vehicle() -> void:
    _car_mode = false
    _car.speed = 0.0
    _joystick = Vector2.ZERO
    _player.global_position = _car.global_position + _car.global_transform.basis.x * 3.0 + Vector3(0,0.2,0)
    _player.velocity = Vector3.ZERO
    _player.set_physics_process(true)
    _player.set_process(true)
    _player.visible = true
    _car_camera.current = false
    (_player.get_node("CameraPivot/Camera3D") as Camera3D).current = not _third_person
    _third_camera.current = _third_person
    _hud.set_combat_controls_visible(true)
    _viewmodel.visible = not _third_person
    _survivor_model.visible = _third_person
    _refresh_labels()
    _announce("ON FOOT: FIRE, RELOAD, USE, PUNCH, KICK and KNIFE")

func _reload() -> void:
    if _car_mode or _reloading > 0.0 or _loaded >= int(_weapon["mag"]) or _reserve <= 0:
        return
    _reloading = RELOAD_TIME
    _viewmodel.play_reload(RELOAD_TIME)

func _shoot() -> void:
    if _car_mode or _shot_cooldown > 0.0 or _reloading > 0.0:
        return
    if _loaded <= 0:
        _reload()
        return
    if _third_person:
        _toggle_view()  # Return to accurate first-person aiming before firing.
    _loaded -= 1
    _shot_cooldown = float(_weapon["interval"])
    _viewmodel.fire()
    var camera := _player.get_node("CameraPivot/Camera3D") as Camera3D
    var start: Vector3 = camera.global_position
    var pellets: int = int(_weapon["pellets"])
    var spread: float = 0.085 if pellets > 1 else (0.004 if _ads else 0.012)
    var headshots: int = 0
    var hits: int = 0
    var permanent_level: int = int(_permanent_upgrades.get(str(_weapon["id"]),0))
    var base_damage: int = int(round(float(_weapon["damage"])*pow(1.18,float(permanent_level))))
    for i in range(pellets):
        var direction: Vector3 = -camera.global_transform.basis.z
        direction = (direction + camera.global_transform.basis.x*randf_range(-spread,spread) + camera.global_transform.basis.y*randf_range(-spread,spread)).normalized()
        var query := PhysicsRayQueryParameters3D.create(start,start+direction*float(_weapon["range"]))
        query.exclude = [_player.get_rid()]
        var result: Dictionary = get_world_3d().direct_space_state.intersect_ray(query)
        if result.has("collider") and result["collider"] is OutbreakZombie:
            var zombie: OutbreakZombie = result["collider"] as OutbreakZombie
            if zombie.take_damage_at(base_damage,result["position"]):
                headshots += 1
            hits += 1
    if headshots > 0:
        _announce("HEADSHOT  2x DAMAGE")
    elif hits > 0:
        _announce("HIT CONFIRMED")
    _refresh_labels()

func _melee(damage: int, reach: float) -> void:
    if _car_mode or _shot_cooldown > 0.0:
        return
    _shot_cooldown = 0.45
    var camera := _player.get_node("CameraPivot/Camera3D") as Camera3D
    var start: Vector3 = camera.global_position
    var query := PhysicsRayQueryParameters3D.create(start,start-camera.global_transform.basis.z*reach)
    query.exclude = [_player.get_rid()]
    var hit: Dictionary = get_world_3d().direct_space_state.intersect_ray(query)
    if hit.has("collider") and hit["collider"] is OutbreakZombie:
        (hit["collider"] as OutbreakZombie).take_damage(damage)
        _announce("MELEE HIT")

func _spawn_zombie() -> void:
    var zombie := ZOMBIE_SCENE.instantiate() as OutbreakZombie
    if zombie == null:
        return
    var angle: float = randf() * TAU
    var radius: float = randf_range(18.0,30.0)
    zombie.target = _player
    add_child(zombie)
    zombie.global_position = Vector3(_player.global_position.x + cos(angle)*radius,0.1,_player.global_position.z + sin(angle)*radius)
    zombie.defeated.connect(_zombie_defeated.bind(zombie))
    zombie.attack_landed.connect(_take_damage)
    _zombies.append(zombie)

func _zombie_defeated(zombie: OutbreakZombie) -> void:
    _zombies.erase(zombie)
    var drop := ScavengePickup.new()
    drop.kind = "parts" if randf() < 0.75 else "fabrication"
    drop.target = _player
    drop.collected.connect(func(kind: String, amount: int): _announce("%d %s saved to permanent inventory" % [amount,kind]))
    drop.save_failed.connect(_announce)
    add_child(drop)
    drop.global_position = zombie.global_position + Vector3.UP * 0.45

func _take_damage(amount: int) -> void:
    if _player.health <= 0:
        return
    var applied: int = maxi(0,amount)
    if _car_mode:
        applied = maxi(1,int(ceil(float(applied)*0.25)))
    _player.health = maxi(0,_player.health-applied)
    _player.health_changed.emit(_player.health,_player.maximum_health)
    if _player.health <= 0:
        _announce("YOU WERE OVERWHELMED. Returning to the safehouse; saved resources remain.")
        _respawn()

func _respawn() -> void:
    await get_tree().create_timer(2.5).timeout
    if _car_mode:
        _exit_vehicle()
    _player.global_position = Vector3(0,0.15,12)
    _player.health = _player.maximum_health
    _player.health_changed.emit(_player.health,_player.maximum_health)

func _show_mission() -> void:
    _announce("Mission: collect garage supplies and deliver to the clinic. Reward: 2 parts + 3 FAB (saved).")

func _toggle_build() -> void:
    _build_panel.visible = not _build_panel.visible
    _refresh_labels()
    if _build_panel.visible:
        _announce("Claim a nearby plot, then construct buildings with saved fabrication tokens.")

func _claim_plot() -> void:
    var result: Dictionary = WorldProgress.claim_plot()
    _announce(str(result.get("message","Claim unavailable")))
    if bool(result.get("ok",false)):
        _district.refresh_plot(_selected_plot)
    _refresh_labels()

func _build_on_plot(kind: String) -> void:
    var result: Dictionary = WorldProgress.build(kind)
    _announce(str(result.get("message","Build unavailable")))
    if bool(result.get("ok",false)):
        _district.refresh_plot(_selected_plot)
    _refresh_labels()

func _switch_region() -> void:
    WorldProgress.remember_position(_region,_player.global_position)
    var next_region: String = "tampa" if _region == "orlando" else "orlando"
    var prefix: String = "T-" if next_region == "tampa" else "O-"
    if not WorldProgress.select_plot(next_region,prefix+"01"):
        _announce("Could not save fast-travel destination")
        return
    get_tree().reload_current_scene()

func _toggle_view() -> void:
    if _car_mode:
        return
    _set_ads(false)
    _third_person = not _third_person
    (_player.get_node("CameraPivot/Camera3D") as Camera3D).current = not _third_person
    _third_camera.current = _third_person
    _viewmodel.visible = not _third_person
    _survivor_model.visible = _third_person
    if _third_person:
        _third_camera.global_position = _player.global_position + _player.global_transform.basis * Vector3(0,2.9,3.2)
        _third_camera.look_at(_player.global_position + Vector3.UP * 1.25,Vector3.UP)
    _announce("THIRD-PERSON EXPLORATION" if _third_person else "FIRST-PERSON AIMING")

func _create_survivor_model() -> void:
    _survivor_model = Node3D.new()
    _survivor_model.name = "ExplorerCharacter"
    _player.add_child(_survivor_model)
    for item in [
        ["Torso",Vector3(0,1.18,0),Vector3(0.44,0.68,0.26),Color(0.17,0.29,0.31)],
        ["Head",Vector3(0,1.72,0),Vector3(0.31,0.32,0.3),Color(0.64,0.49,0.36)],
        ["LeftArm",Vector3(-0.35,1.16,0),Vector3(0.18,0.67,0.21),Color(0.21,0.34,0.35)],
        ["RightArm",Vector3(0.35,1.16,0),Vector3(0.18,0.67,0.21),Color(0.21,0.34,0.35)],
        ["LeftLeg",Vector3(-0.14,0.44,0),Vector3(0.19,0.82,0.21),Color(0.16,0.18,0.21)],
        ["RightLeg",Vector3(0.14,0.44,0),Vector3(0.19,0.82,0.21),Color(0.16,0.18,0.21)]
    ]:
        _simple_box(_survivor_model,str(item[0]),item[1],item[2],item[3],false)
    _survivor_model.visible = false

func _to_menu() -> void:
    WorldProgress.remember_position(_region,_player.global_position)
    get_tree().change_scene_to_file(MENU)

func _place_landmark(title: String, at: Vector3, color: Color) -> void:
    _simple_box(self,title + " Marker",at+Vector3(0,0.48,0),Vector3(2.0,0.9,2.0),color,true)
    var sign := Label3D.new()
    sign.text = title + "  /  USE"
    sign.font_size = 34
    sign.pixel_size = 0.01
    sign.position = at+Vector3(0,2.4,0)
    sign.billboard = BaseMaterial3D.BILLBOARD_ENABLED
    sign.no_depth_test = true
    add_child(sign)

func _refresh_tiles() -> void:
    if not is_instance_valid(_tiles):
        return
    var pos: Vector3 = _car.global_position if _car_mode else _player.global_position
    var origin_x: int = clampi(int(round(pos.x/104.0)),-2,2)
    var origin_z: int = clampi(int(round(pos.z/104.0)),-2,2)
    var needed: Dictionary = {}
    for x in range(origin_x-1,origin_x+2):
        for z in range(origin_z-1,origin_z+2):
            if abs(x)>2 or abs(z)>2 or (x == 0 and z == 0):
                continue
            var key: String = "%d_%d" % [x,z]
            needed[key] = true
            if _tiles.get_node_or_null(key) == null:
                _create_tile(key,x,z)
    for tile in _tiles.get_children():
        if not needed.has(tile.name):
            _tiles.remove_child(tile)
            tile.queue_free()

func _create_tile(key: String, x: int, z: int) -> void:
    var tile := Node3D.new()
    tile.name = key
    tile.position = Vector3(x*104.0,0,z*104.0)
    _tiles.add_child(tile)
    _simple_box(tile,"Ground",Vector3(0,-0.55,0),Vector3(104,1.0,104),Color(0.22,0.28,0.24) if _region == "orlando" else Color(0.29,0.29,0.27),true)
    _simple_box(tile,"HighwayNorth",Vector3(0,0.0,0),Vector3(9,0.06,102),Color(0.13,0.14,0.15),false)
    _simple_box(tile,"HighwayEast",Vector3(0,0.0,0),Vector3(102,0.06,9),Color(0.13,0.14,0.15),false)
    for number in range(6):
        var row: int = int(number/3)
        var col: int = number%3
        var at := Vector3(-34.0+float(col)*33.0,0,-35.0+float(row)*69.0)
        if absf(at.x) < 7.0:
            at.x += 10.0
        _simple_box(tile,"Warehouse" if _region == "tampa" else "Home",at+Vector3(0,2.2,0),Vector3(13,4.4,12),Color(0.49,0.44,0.37) if _region == "orlando" else Color(0.34,0.40,0.43),true)
        _simple_box(tile,"Roof",at+Vector3(0,4.52,0),Vector3(14,0.3,13),Color(0.16,0.19,0.18),false)

func _simple_box(parent: Node3D, label: String, at: Vector3, dimensions: Vector3, tint: Color, solid: bool) -> void:
    var node: Node3D
    if solid:
        var body := StaticBody3D.new()
        body.position = at
        var collider := CollisionShape3D.new()
        var shape := BoxShape3D.new()
        shape.size = dimensions
        collider.shape = shape
        body.add_child(collider)
        node = body
    else:
        node = Node3D.new()
        node.position = at
    node.name = label
    var mesh := MeshInstance3D.new()
    var box := BoxMesh.new()
    box.size = dimensions
    mesh.mesh = box
    var material := StandardMaterial3D.new()
    material.albedo_color = tint
    material.roughness = 0.94
    if label.begins_with("Highway"):
        material.albedo_texture = ASPHALT
        material.uv1_scale = Vector3(8,8,1)
    elif label in ["Home", "Warehouse"]:
        material.albedo_texture = CONCRETE
        material.uv1_scale = Vector3(2,2,1)
    mesh.material_override = material
    node.add_child(mesh)
    parent.add_child(node)
