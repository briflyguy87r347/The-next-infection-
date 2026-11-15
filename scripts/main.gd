extends Node3D

const PLAYER_SCENE: PackedScene = preload("res://scenes/player.tscn")
const HUD_SCENE: PackedScene = preload("res://scenes/hud.tscn")

var _player_spawn: Marker3D
var _arena: BlockZeroMap


func _ready() -> void:
	print("THE NEXT INFECTION")
	print("OUTBREAK ZERO initialized")
	_arena = BlockZeroMap.new()
	add_child(_arena)
	_spawn_player_and_hud()


# Modular map: the existing Module 004 player, HUD and combat remain intact.


func _spawn_player_and_hud() -> void:
	var player := PLAYER_SCENE.instantiate() as FirstPersonPlayer
	add_child(player)
	player.global_position = Vector3(0.0, 0.15, 3.0)

	var hud := HUD_SCENE.instantiate() as TouchHUD
	add_child(hud)
	hud.move_changed.connect(player.set_mobile_movement)
	hud.look_changed.connect(player.apply_touch_look)
	hud.jump_pressed.connect(player.request_jump)
	hud.sprint_changed.connect(player.set_mobile_sprinting)
	player.health_changed.connect(hud.set_health)
	# Module 003: fix incorrect player.max_health property reference.
	hud.set_health(player.health, player.maximum_health)

	# Module 003 is added alongside the existing player and touch HUD.
	# Existing movement, camera, world geometry, and health HUD are preserved.
	var combat := CombatDirector.new()
	combat.name = "CombatDirector"
	combat.player = player
	combat.hud = hud
	combat.world = _arena
	add_child(combat)
