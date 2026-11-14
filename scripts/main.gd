extends Node3D

const PLAYER_SCENE: PackedScene = preload("res://scenes/player.tscn")
const HUD_SCENE: PackedScene = preload("res://scenes/hud.tscn")

var _player_spawn: Marker3D


func _ready() -> void:
	print("THE NEXT INFECTION")
	print("OUTBREAK ZERO initialized")
	build_world()
	_spawn_player_and_hud()


func build_world() -> void:
	var ground := StaticBody3D.new()
	ground.name = "Ground"
	ground.position.y = -0.5

	var ground_shape := CollisionShape3D.new()
	ground_shape.name = "GroundCollision"
	var ground_box := BoxShape3D.new()
	ground_box.size = Vector3(40.0, 1.0, 40.0)
	ground_shape.shape = ground_box
	ground.add_child(ground_shape)

	var ground_mesh := MeshInstance3D.new()
	ground_mesh.name = "GroundVisual"
	var ground_box_mesh := BoxMesh.new()
	ground_box_mesh.size = ground_box.size
	ground_mesh.mesh = ground_box_mesh
	ground_mesh.material_override = _make_material(Color(0.20, 0.24, 0.22))
	ground.add_child(ground_mesh)
	add_child(ground)

	_player_spawn = Marker3D.new()
	_player_spawn.name = "PlayerSpawn"
	_player_spawn.position = Vector3(0.0, 0.0, 3.0)
	add_child(_player_spawn)

	_create_obstacle(Vector3(-4.0, 0.0, -4.0), Vector3(2.0, 2.0, 2.0), Color(0.34, 0.30, 0.26))
	_create_obstacle(Vector3(3.0, 0.0, -6.0), Vector3(3.0, 1.4, 1.5), Color(0.28, 0.32, 0.36))
	_create_obstacle(Vector3(6.0, 0.0, 1.0), Vector3(1.5, 3.0, 1.5), Color(0.37, 0.29, 0.28))

	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-45.0, -30.0, 0.0)
	light.shadow_enabled = false
	add_child(light)


func _spawn_player_and_hud() -> void:
	var player := PLAYER_SCENE.instantiate() as FirstPersonPlayer
	add_child(player)
	player.global_position = _player_spawn.global_position

	var hud := HUD_SCENE.instantiate() as TouchHUD
	add_child(hud)
	hud.move_changed.connect(player.set_mobile_movement)
	hud.look_changed.connect(player.apply_touch_look)
	hud.jump_pressed.connect(player.request_jump)
	hud.sprint_changed.connect(player.set_mobile_sprinting)
	player.health_changed.connect(hud.set_health)
	hud.set_health(player.health, player.maximum_health)
	var combat := CombatDirector.new()
	combat.name = "CombatDirector"
	combat.player = player
	combat.hud = hud
	add_child(combat)


func _create_obstacle(ground_position: Vector3, size: Vector3, color: Color) -> void:
	var obstacle := StaticBody3D.new()
	obstacle.position = Vector3(ground_position.x, size.y * 0.5, ground_position.z)

	var collision := CollisionShape3D.new()
	collision.name = "ObstacleCollision"
	var shape := BoxShape3D.new()
	shape.size = size
	collision.shape = shape
	obstacle.add_child(collision)

	var mesh_instance := MeshInstance3D.new()
	mesh_instance.name = "ObstacleVisual"
	var mesh := BoxMesh.new()
	mesh.size = size
	mesh_instance.mesh = mesh
	mesh_instance.material_override = _make_material(color)
	obstacle.add_child(mesh_instance)
	add_child(obstacle)


func _make_material(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 1.0
	return material
