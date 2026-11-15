class_name KillCoin
extends Node3D

# Visual 3D coin burst; lightweight custom animation (no rigid bodies).
signal collected(value: int)

var value: int = 25
var player: FirstPersonPlayer
var launch_velocity: Vector3 = Vector3.ZERO

var _velocity: Vector3 = Vector3.ZERO
var _age: float = 0.0
var _floor_height: float = 0.22
var _mesh: MeshInstance3D
var _collected: bool = false


func _ready() -> void:
	_velocity = launch_velocity
	_floor_height = maxf(0.22, global_position.y - 0.55)
	_mesh = MeshInstance3D.new()
	_mesh.name = "GoldCoin"
	var disc := CylinderMesh.new()
	disc.top_radius = 0.14
	disc.bottom_radius = 0.14
	disc.height = 0.035
	disc.radial_segments = 12
	_mesh.mesh = disc
	_mesh.rotation.x = PI * 0.5
	var gold := StandardMaterial3D.new()
	gold.albedo_color = Color(1.0, 0.76, 0.14)
	gold.metallic = 0.48
	gold.roughness = 0.35
	gold.emission_enabled = true
	gold.emission = Color(0.65, 0.38, 0.04)
	gold.emission_energy_multiplier = 0.35
	_mesh.material_override = gold
	add_child(_mesh)


func _process(delta: float) -> void:
	if _collected:
		return
	_age += delta
	_mesh.rotation.y += delta * 6.0
	if _age > 15.0:
		queue_free()
		return

	# Toss, bounce twice, then pull coins toward nearby players.
	if is_instance_valid(player) and global_position.distance_to(player.global_position + Vector3.UP * 0.7) < 2.8:
		var destination: Vector3 = player.global_position + Vector3.UP * 0.85
		global_position = global_position.move_toward(destination, delta * 8.0)
		if global_position.distance_to(destination) < 0.7:
			_collected = true
			collected.emit(value)
			queue_free()
		return

	_velocity.y -= 15.0 * delta
	global_position += _velocity * delta
	if global_position.y < _floor_height:
		global_position.y = _floor_height
		_velocity.y = absf(_velocity.y) * 0.32 if absf(_velocity.y) > 0.8 else 0.0
		_velocity.x *= 0.65
		_velocity.z *= 0.65
