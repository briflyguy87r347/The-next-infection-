class_name OutbreakZombie
extends CharacterBody3D

# Module 004 - lightweight humanoid zombie visuals and animated behavior.
# Preserves the Module 003 signals, combat API, and capsule-based collision.
signal defeated
signal attack_landed(damage: int)

@export var maximum_health: int = 68
@export var move_speed: float = 1.65
@export var attack_damage: int = 9
@export var attack_reach: float = 1.45
@export var attack_cooldown: float = 1.2

const GRAVITY: float = 9.8
const SKIN_TEXTURE: Texture2D = preload("res://assets/zombies/skin_decay.png")
const SHIRT_TEXTURE: Texture2D = preload("res://assets/zombies/torn_fabric.png")
const PANTS_TEXTURE: Texture2D = preload("res://assets/zombies/dirty_pants.png")

var target: FirstPersonPlayer
var _health: int = 68
var _attack_timer: float = 0.0
var _attack_pose_timer: float = 0.0
var _hurt_timer: float = 0.0
var _death_timer: float = 0.0
var _defeated: bool = false
var _walk_cycle: float = 0.0
var _stride_offset: float = 0.0
var _limp_factor: float = 1.0
var _lean: float = 0.0
var infected_class: String = "WALKER"
var _attack_windup: float = 0.0
var _obstacle_check: float = 0.0
var _steer_timer: float = 0.0
var _steer_side: float = 1.0

@onready var _body_root: Node3D = $Body
var _rig: Node3D
var _upper: Node3D
var _head: Node3D
var _left_arm: Node3D
var _right_arm: Node3D
var _left_leg: Node3D
var _right_leg: Node3D
var _small_details: Node3D


func _ready() -> void:
	# Lightweight profiles with meaningful behaviors, no extra draw-call-heavy effects.
	var roll: int = randi_range(0,9)
	if roll >= 9:
		infected_class = "BRUTE"
		maximum_health = maxi(maximum_health,160)
		move_speed = 1.12
		attack_damage = 18
		attack_cooldown = 1.65
	elif roll >= 7:
		infected_class = "RUNNER"
		maximum_health = maxi(36,int(float(maximum_health)*0.7))
		move_speed = 2.9
		attack_damage = 7
		attack_cooldown = 0.86
	_health = maximum_health
	add_to_group("zombies")
	_stride_offset = randf_range(0.0, TAU)
	_limp_factor = randf_range(0.75, 1.15)
	_lean = randf_range(-0.07, 0.07)
	move_speed *= randf_range(0.82, 1.16)
	_build_humanoid(randi_range(0, 3))
	if infected_class == "BRUTE":
		_rig.scale = Vector3(1.20,1.14,1.18)
	elif infected_class == "RUNNER":
		_rig.scale = Vector3(0.89,0.96,0.88)


func _physics_process(delta: float) -> void:
	if _defeated:
		velocity = Vector3.ZERO
		_death_timer += delta
		if _death_timer >= 1.25:
			queue_free()
		return

	if not is_instance_valid(target) or target.health <= 0:
		velocity.x = move_toward(velocity.x, 0.0, delta * 8.0)
		velocity.z = move_toward(velocity.z, 0.0, delta * 8.0)
		if not is_on_floor():
			velocity.y -= GRAVITY * delta
		move_and_slide()
		return

	_attack_timer = maxf(_attack_timer - delta, 0.0)
	_obstacle_check = maxf(_obstacle_check - delta, 0.0)
	_steer_timer = maxf(_steer_timer - delta, 0.0)
	if _attack_windup > 0.0:
		_attack_windup -= delta
		if _attack_windup <= 0.0 and target.global_position.distance_to(global_position) < attack_reach + 0.55:
			attack_landed.emit(attack_damage)
	var displacement: Vector3 = target.global_position - global_position
	var horizontal := Vector3(displacement.x, 0.0, displacement.z)
	var distance: float = horizontal.length()

	if not is_on_floor():
		velocity.y -= GRAVITY * delta
	else:
		velocity.y = 0.0

	if distance > attack_reach:
		var heading: Vector3 = horizontal.normalized()
		# Cheap obstacle avoidance; not a substitute for baked navigation meshes.
		# Query roughly 4x/second so 16 active infected remain affordable on mobile.
		if _obstacle_check <= 0.0:
			_obstacle_check = randf_range(0.17,0.31)
			var start: Vector3 = global_position + Vector3.UP*0.86
			var query := PhysicsRayQueryParameters3D.create(start,start+heading*1.9)
			query.exclude = [get_rid()]
			var hit: Dictionary = get_world_3d().direct_space_state.intersect_ray(query)
			if hit.has("collider") and hit["collider"] is StaticBody3D:
				_steer_side = -1.0 if randf() < 0.5 else 1.0
				_steer_timer = 0.9
		if _steer_timer > 0.0:
			heading = (heading + heading.rotated(Vector3.UP,_steer_side*PI*0.46)*1.3).normalized()
		velocity.x = move_toward(velocity.x, heading.x * move_speed, delta * 5.5)
		velocity.z = move_toward(velocity.z, heading.z * move_speed, delta * 5.5)
	else:
		velocity.x = move_toward(velocity.x, 0.0, delta * 9.0)
		velocity.z = move_toward(velocity.z, 0.0, delta * 9.0)

	if distance > 0.05:
		rotation.y = lerp_angle(rotation.y, atan2(-horizontal.x, -horizontal.z), minf(delta * 5.0, 1.0))
	move_and_slide()

	if distance <= attack_reach and _attack_timer <= 0.0 and _attack_windup <= 0.0:
		_attack_timer = attack_cooldown
		_attack_pose_timer = 0.5
		_attack_windup = 0.25


func _process(delta: float) -> void:
	if not is_instance_valid(_rig):
		return
	if _defeated:
		# Lightweight death-fall animation; zombies stop attacking immediately.
		var fall: float = clampf(_death_timer / 0.52, 0.0, 1.0)
		_rig.rotation.z = lerpf(_rig.rotation.z, 1.33, minf(delta * 9.0, 1.0))
		_rig.position.y = -0.34 * fall
		_head.rotation.x = lerpf(_head.rotation.x, 0.55, minf(delta * 7.0, 1.0))
		return

	_attack_pose_timer = maxf(0.0, _attack_pose_timer - delta)
	_hurt_timer = maxf(0.0, _hurt_timer - delta)
	var moving: bool = Vector2(velocity.x, velocity.z).length_squared() > 0.12
	if moving:
		_walk_cycle += delta * (2.5 + move_speed * 2.0) * _limp_factor
	var step: float = sin(_walk_cycle + _stride_offset) if moving else 0.0
	var arm_step: float = sin(_walk_cycle + _stride_offset + PI) if moving else 0.0
	var attack_progress: float = _attack_pose_timer / 0.5
	var swing: float = sin(attack_progress * PI) if _attack_pose_timer > 0.0 else 0.0
	var flinch: float = sin(_hurt_timer * 28.0) * 0.17 if _hurt_timer > 0.0 else 0.0

	_left_leg.rotation.x = lerpf(_left_leg.rotation.x, step * 0.42, minf(delta * 11.0, 1.0))
	_right_leg.rotation.x = lerpf(_right_leg.rotation.x, -step * 0.32, minf(delta * 11.0, 1.0))
	_left_arm.rotation.x = lerpf(_left_arm.rotation.x, 0.28 + arm_step * 0.22 + swing * 1.05, minf(delta * 10.0, 1.0))
	_right_arm.rotation.x = lerpf(_right_arm.rotation.x, 0.40 - arm_step * 0.17 + swing * 0.82, minf(delta * 10.0, 1.0))
	_upper.rotation.z = _lean + step * 0.065 + flinch
	_upper.rotation.x = 0.12 + swing * 0.25
	_head.rotation.z = -_lean * 1.5 - step * 0.05
	_head.rotation.x = -0.08 + swing * 0.2
	_rig.position.y = absf(step) * 0.022 if moving else 0.0

	# Extra facial details disappear at a distance to save draw calls on Android.
	if is_instance_valid(target) and is_instance_valid(_small_details):
		_small_details.visible = global_position.distance_squared_to(target.global_position) < 196.0


# Returns true when the ray struck the upper head region; doubles headshot damage.
func take_damage_at(amount: int, world_hit: Vector3) -> bool:
	var headshot: bool = world_hit.y - global_position.y > 1.42
	take_damage(amount*2 if headshot else amount)
	return headshot

func take_damage(amount: int) -> void:
	if _defeated or amount <= 0:
		return
	_health = maxi(0, _health - amount)
	_hurt_timer = 0.28
	if _health == 0:
		_defeated = true
		defeated.emit()
		var shape := get_node_or_null("CollisionShape3D") as CollisionShape3D
		if is_instance_valid(shape):
			shape.set_deferred("disabled", true)
		remove_from_group("zombies")


func _build_humanoid(style: int) -> void:
	var skin_tints: Array[Color] = [
		Color(0.82, 0.88, 0.79), Color(0.66, 0.69, 0.60),
		Color(0.85, 0.75, 0.68), Color(0.56, 0.57, 0.53)
	]
	var shirt_tints: Array[Color] = [
		Color(0.72, 0.76, 0.69), Color(0.68, 0.76, 0.89),
		Color(0.73, 0.58, 0.49), Color(0.48, 0.53, 0.50)
	]
	var skin: StandardMaterial3D = _textured_material(SKIN_TEXTURE, skin_tints[style])
	var shirt: StandardMaterial3D = _textured_material(SHIRT_TEXTURE, shirt_tints[style])
	var trousers: StandardMaterial3D = _textured_material(PANTS_TEXTURE, Color(0.78, 0.82, 0.79))
	var hair: StandardMaterial3D = _plain_material(Color(0.09, 0.084, 0.073))
	var dark: StandardMaterial3D = _plain_material(Color(0.067, 0.043, 0.045))
	var wound: StandardMaterial3D = _plain_material(Color(0.31, 0.085, 0.075))
	var boot: StandardMaterial3D = _plain_material(Color(0.13, 0.13, 0.12))

	_rig = Node3D.new()
	_rig.name = "ZombieRig"
	_body_root.add_child(_rig)
	_upper = Node3D.new()
	_upper.name = "UpperBody"
	_rig.add_child(_upper)

	# Human-like silhouette: pelvis, tapering ribcage, neck and separate head.
	_make_segment(_rig, "Pelvis", Vector3(0, 0.82, 0), Vector3(0, 1.03, 0), 0.24, 0.23, trousers)
	_make_segment(_upper, "TornShirt", Vector3(0, 1.02, 0), Vector3(0, 1.52, 0.035), 0.215, 0.29, shirt)
	_make_segment(_upper, "Neck", Vector3(0, 1.48, 0), Vector3(0, 1.65, 0), 0.105, 0.097, skin)

	_head = Node3D.new()
	_head.name = "HeadPivot"
	_head.position = Vector3(0.0, 1.63, -0.012)
	_upper.add_child(_head)
	_make_sphere(_head, "Skull", Vector3(0, 0.10, -0.015), Vector3(0.215, 0.25, 0.195), skin)
	_make_sphere(_head, "Jaw", Vector3(0, -0.048, -0.065), Vector3(0.174, 0.095, 0.157), skin)
	_make_sphere(_head, "Mouth", Vector3(0, -0.052, -0.211), Vector3(0.103, 0.025, 0.013), dark)
	_make_sphere(_head, "Nose", Vector3(0, 0.065, -0.217), Vector3(0.043, 0.07, 0.042), skin)

	_small_details = Node3D.new()
	_small_details.name = "FaceDetailsLOD"
	_head.add_child(_small_details)
	for side in [-1.0, 1.0]:
		_make_sphere(_small_details, "SunkenEye", Vector3(side * 0.091, 0.12, -0.173), Vector3(0.056, 0.048, 0.027), dark)
		_make_sphere(_small_details, "CloudedEye", Vector3(side * 0.09, 0.122, -0.196), Vector3(0.028, 0.024, 0.016), _plain_material(Color(0.61, 0.65, 0.57)))
	_make_sphere(_small_details, "CheekInjury", Vector3(-0.129, 0.015, -0.148), Vector3(0.065, 0.025, 0.018), wound)
	_make_sphere(_small_details, "SplitLip", Vector3(0.060, -0.077, -0.218), Vector3(0.044, 0.012, 0.012), wound)
	if style != 2:
		_make_sphere(_head, "MattedHair", Vector3(-0.022, 0.26, 0.015), Vector3(0.21, 0.067, 0.186), hair)

	# Irregular fabric damage is represented as small dark patches on clothes.
	_make_sphere(_upper, "RippedShoulder", Vector3(-0.236, 1.36, -0.129), Vector3(0.075, 0.06, 0.026), wound)
	_make_sphere(_upper, "TornCollar", Vector3(0.13, 1.47, -0.158), Vector3(0.085, 0.042, 0.017), dark)

	_left_arm = _make_arm(-1.0, shirt, skin, wound)
	_right_arm = _make_arm(1.0, shirt, skin, wound)
	_left_leg = _make_leg(-1.0, trousers, boot)
	_right_leg = _make_leg(1.0, trousers, boot)
	_right_arm.rotation.x = 0.40
	_left_arm.rotation.x = 0.28


func _make_arm(side: float, shirt: Material, skin: Material, wound: Material) -> Node3D:
	var arm := Node3D.new()
	arm.name = "LeftArm" if side < 0.0 else "RightArm"
	arm.position = Vector3(side * 0.284, 1.435, 0.02)
	_upper.add_child(arm)
	_make_segment(arm, "Sleeve", Vector3.ZERO, Vector3(side * 0.055, -0.25, -0.06), 0.115, 0.092, shirt)
	_make_segment(arm, "Forearm", Vector3(side * 0.055, -0.25, -0.06), Vector3(side * 0.11, -0.49, -0.18), 0.082, 0.06, skin)
	_make_sphere(arm, "Hand", Vector3(side * 0.115, -0.53, -0.20), Vector3(0.074, 0.095, 0.047), skin)
	for finger in range(3):
		_make_segment(arm, "Finger", Vector3(side * 0.115 + float(finger - 1) * 0.045, -0.57, -0.21), Vector3(side * 0.118 + float(finger - 1) * 0.045, -0.625, -0.26), 0.013, 0.009, skin)
	if side < 0.0:
		_make_sphere(arm, "ArmWound", Vector3(side * 0.11, -0.35, -0.133), Vector3(0.06, 0.05, 0.012), wound)
	return arm


func _make_leg(side: float, trousers: Material, boot: Material) -> Node3D:
	var leg := Node3D.new()
	leg.name = "LeftLeg" if side < 0.0 else "RightLeg"
	leg.position = Vector3(side * 0.137, 0.91, 0.0)
	_rig.add_child(leg)
	_make_segment(leg, "Thigh", Vector3.ZERO, Vector3(side * 0.03, -0.40, -0.025), 0.13, 0.105, trousers)
	_make_segment(leg, "Calf", Vector3(side * 0.03, -0.40, -0.025), Vector3(side * 0.034, -0.75, 0.025), 0.103, 0.072, trousers)
	_make_box(leg, "Boot", Vector3(side * 0.037, -0.82, -0.084), Vector3(0.17, 0.145, 0.29), boot)
	return leg


func _make_segment(parent: Node3D, name: String, a: Vector3, b: Vector3, bottom_radius: float, top_radius: float, material: Material) -> void:
	var mesh := CylinderMesh.new()
	mesh.top_radius = top_radius
	mesh.bottom_radius = bottom_radius
	mesh.height = a.distance_to(b)
	mesh.radial_segments = 10
	var visual := MeshInstance3D.new()
	visual.name = name
	visual.mesh = mesh
	visual.material_override = material
	visual.position = (a + b) * 0.5
	var direction: Vector3 = (b - a).normalized()
	if direction.dot(Vector3.UP) < -0.999:
		visual.rotation.z = PI
	else:
		visual.quaternion = Quaternion(Vector3.UP, direction)
	visual.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(visual)


func _make_sphere(parent: Node3D, name: String, position: Vector3, radii: Vector3, material: Material) -> void:
	var mesh := SphereMesh.new()
	mesh.radius = 1.0
	mesh.height = 2.0
	mesh.radial_segments = 12
	mesh.rings = 6
	var visual := MeshInstance3D.new()
	visual.name = name
	visual.mesh = mesh
	visual.position = position
	visual.scale = radii
	visual.material_override = material
	visual.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(visual)


func _make_box(parent: Node3D, name: String, position: Vector3, size: Vector3, material: Material) -> void:
	var mesh := BoxMesh.new()
	mesh.size = size
	var visual := MeshInstance3D.new()
	visual.name = name
	visual.mesh = mesh
	visual.position = position
	visual.material_override = material
	visual.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(visual)


func _textured_material(texture: Texture2D, tint: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_texture = texture
	material.albedo_color = tint
	material.roughness = 1.0
	return material


func _plain_material(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 1.0
	return material
