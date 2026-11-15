class_name CombatDirector
extends Node3D

# Module 003: independent combat system; it does not change the player movement script.
const ZOMBIE_SCENE: PackedScene = preload("res://scenes/zombie.tscn")
const MAGAZINE_SIZE: int = 12
const STARTING_RESERVE: int = 72
const AMMO_PER_CLEARED_WAVE: int = 36
const SHOT_DAMAGE: int = 34
const SHOT_RANGE: float = 80.0
const FIRE_INTERVAL: float = 0.23
const RELOAD_SECONDS: float = 1.35
const BETWEEN_WAVES: float = 3.0
const MAX_ZOMBIES_PER_WAVE: int = 16

var player: FirstPersonPlayer
var hud: TouchHUD

var _wave: int = 0
var _alive: int = 0
var _kills: int = 0
var _loaded: int = MAGAZINE_SIZE
var _reserve: int = STARTING_RESERVE
var _fire_timer: float = 0.0
var _reload_timer: float = 0.0
var _reloading: bool = false
var _mobile_firing: bool = false
var _pending_fire: bool = false
var _game_running: bool = true
var _next_wave_timer: Timer
var _ammo_label: Label
var _wave_label: Label
var _crosshair: Label
var _game_over_label: Label


func _ready() -> void:
	if not is_instance_valid(player) or not is_instance_valid(hud):
		push_error("CombatDirector requires an existing player and touch HUD")
		set_process(false)
		return

	hud.fire_changed.connect(_set_mobile_firing)
	hud.reload_pressed.connect(_begin_reload)
	_build_combat_overlay()

	_next_wave_timer = Timer.new()
	_next_wave_timer.name = "WaveDelay"
	_next_wave_timer.one_shot = true
	_next_wave_timer.wait_time = BETWEEN_WAVES
	add_child(_next_wave_timer)
	_next_wave_timer.timeout.connect(_start_wave)
	_start_wave()


# Godot physics queries must run on the physics tick, not the render/input tick.
func _physics_process(delta: float) -> void:
	if not _game_running:
		return
	_fire_timer = maxf(0.0, _fire_timer - delta)
	if _reloading:
		_reload_timer -= delta
		if _reload_timer <= 0.0:
			_finish_reload()

	var desktop_fire: bool = not OS.has_feature("mobile") and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)
	if _pending_fire or _mobile_firing or desktop_fire:
		_pending_fire = false
		_fire_weapon()


func _input(event: InputEvent) -> void:
	if not _game_running:
		return
	if event is InputEventKey and event.pressed and not event.echo and event.physical_keycode == KEY_R:
		_begin_reload()


func _set_mobile_firing(active: bool) -> void:
	_mobile_firing = active
	if active:
		_pending_fire = true


func _fire_weapon() -> void:
	if not _game_running or _reloading or _fire_timer > 0.0:
		return
	if _loaded <= 0:
		_begin_reload()
		return

	_fire_timer = FIRE_INTERVAL
	_loaded -= 1
	_update_ammo_label()

	var camera: Camera3D = player.get_node_or_null("CameraPivot/Camera3D") as Camera3D
	if not is_instance_valid(camera):
		return
	var start: Vector3 = camera.global_position
	var end: Vector3 = start - camera.global_transform.basis.z * SHOT_RANGE
	var query := PhysicsRayQueryParameters3D.create(start, end)
	query.exclude = [player.get_rid()]
	var result: Dictionary = get_world_3d().direct_space_state.intersect_ray(query)
	if result.has("collider"):
		var hit_object: Object = result["collider"]
		if hit_object is OutbreakZombie:
			(hit_object as OutbreakZombie).take_damage(SHOT_DAMAGE)


func _begin_reload() -> void:
	if not _game_running or _reloading or _loaded >= MAGAZINE_SIZE or _reserve <= 0:
		return
	_reloading = true
	_reload_timer = RELOAD_SECONDS
	_update_ammo_label()


func _finish_reload() -> void:
	_reloading = false
	var amount: int = mini(MAGAZINE_SIZE - _loaded, _reserve)
	_loaded += amount
	_reserve -= amount
	_update_ammo_label()


func _start_wave() -> void:
	if not _game_running:
		return
	if _wave > 0:
		# Reward enough reserve ammo for later waves (up to 16 zombies).
		_reserve = mini(120, _reserve + AMMO_PER_CLEARED_WAVE)
		_update_ammo_label()
	_wave += 1
	var count: int = mini(2 + _wave * 2, MAX_ZOMBIES_PER_WAVE)
	_alive = 0
	for i in range(count):
		var zombie := ZOMBIE_SCENE.instantiate() as OutbreakZombie
		if zombie == null:
			push_error("Zombie scene could not be instantiated")
			continue
		var angle: float = TAU * float(i) / float(count) + randf_range(-0.18, 0.18)
		var radius: float = randf_range(11.0, 16.0)
		zombie.position = Vector3(
			player.position.x + cos(angle) * radius,
			0.0,
			player.position.z + sin(angle) * radius
		)
		zombie.target = player
		zombie.defeated.connect(_on_zombie_defeated.bind(zombie))
		zombie.attack_landed.connect(_damage_player)
		add_child(zombie)
		_alive += 1
	_update_wave_label()


func _on_zombie_defeated(_zombie: OutbreakZombie) -> void:
	if not _game_running:
		return
	_alive = maxi(0, _alive - 1)
	_kills += 1
	_update_wave_label()
	if _alive == 0:
		_next_wave_timer.start()


func _damage_player(amount: int) -> void:
	if not _game_running or not is_instance_valid(player):
		return
	player.health = maxi(0, player.health - maxi(amount, 0))
	player.health_changed.emit(player.health, player.maximum_health)
	if player.health == 0:
		_game_running = false
		_mobile_firing = false
		_next_wave_timer.stop()
		_game_over_label.visible = true
		_restart_after_death()


func _restart_after_death() -> void:
	await get_tree().create_timer(3.0).timeout
	get_tree().reload_current_scene()


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

	_ammo_label = _make_label(18, Color(1.0, 0.94, 0.79))
	_wave_label = _make_label(17, Color(0.86, 0.96, 0.86))
	_crosshair = _make_label(25, Color(0.95, 0.98, 0.93))
	_game_over_label = _make_label(30, Color(1.0, 0.65, 0.56))
	_crosshair.text = "+"
	_crosshair.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_game_over_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_game_over_label.text = "YOU WERE OVERWHELMED\nRestarting..."
	_game_over_label.visible = false

	for label in [_ammo_label, _wave_label, _crosshair, _game_over_label]:
		overlay.add_child(label)
	get_viewport().size_changed.connect(_layout_overlay)
	_layout_overlay()
	_update_ammo_label()
	_update_wave_label()


func _make_label(font_size: int, font_color: Color) -> Label:
	var label := Label.new()
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", font_color)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label


func _layout_overlay() -> void:
	if not is_instance_valid(_ammo_label):
		return
	var size: Vector2 = get_viewport().get_visible_rect().size
	_ammo_label.position = Vector2(size.x - 235.0, 20.0)
	_ammo_label.size = Vector2(218.0, 64.0)
	_ammo_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_wave_label.position = Vector2(18.0, 85.0)
	_wave_label.size = Vector2(260.0, 48.0)
	_crosshair.position = Vector2(size.x * 0.5 - 24.0, size.y * 0.5 - 26.0)
	_crosshair.size = Vector2(48.0, 48.0)
	_game_over_label.position = Vector2(size.x * 0.5 - 240.0, size.y * 0.30)
	_game_over_label.size = Vector2(480.0, 110.0)


func _update_ammo_label() -> void:
	if not is_instance_valid(_ammo_label):
		return
	var suffix: String = "  RELOADING" if _reloading else ""
	_ammo_label.text = "AMMO  %d / %d%s" % [_loaded, _reserve, suffix]


func _update_wave_label() -> void:
	if not is_instance_valid(_wave_label):
		return
	_wave_label.text = "ROUND %d  |  LEFT %d  |  KILLS %d" % [_wave, _alive, _kills]
