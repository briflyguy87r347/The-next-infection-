class_name OutbreakZombie
extends CharacterBody3D

signal defeated
signal attack_landed(damage: int)

@export var maximum_health: int = 68
@export var move_speed: float = 1.65
@export var attack_damage: int = 9
@export var attack_reach: float = 1.45
@export var attack_cooldown: float = 1.2

const GRAVITY: float = 9.8

var target: FirstPersonPlayer
var _health: int = 68
var _attack_timer: float = 0.0
var _defeated: bool = false


func _ready() -> void:
	_health = maximum_health
	add_to_group("zombies")
	var visual := $Body as MeshInstance3D
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(0.22, 0.45, 0.33)
	material.roughness = 1.0
	visual.material_override = material


func _physics_process(delta: float) -> void:
	if _defeated or not is_instance_valid(target) or target.health <= 0:
		velocity.x = move_toward(velocity.x, 0.0, delta * 8.0)
		velocity.z = move_toward(velocity.z, 0.0, delta * 8.0)
		if not is_on_floor():
			velocity.y -= GRAVITY * delta
		move_and_slide()
		return

	_attack_timer = maxf(_attack_timer - delta, 0.0)
	var displacement: Vector3 = target.global_position - global_position
	var horizontal: Vector3 = Vector3(displacement.x, 0.0, displacement.z)
	var distance: float = horizontal.length()

	if not is_on_floor():
		velocity.y -= GRAVITY * delta
	else:
		velocity.y = 0.0

	if distance > attack_reach:
		var heading: Vector3 = horizontal.normalized()
		velocity.x = move_toward(velocity.x, heading.x * move_speed, delta * 9.0)
		velocity.z = move_toward(velocity.z, heading.z * move_speed, delta * 9.0)
	else:
		velocity.x = move_toward(velocity.x, 0.0, delta * 9.0)
		velocity.z = move_toward(velocity.z, 0.0, delta * 9.0)

	if distance > 0.05:
		rotation.y = atan2(-horizontal.x, -horizontal.z)
	move_and_slide()

	if distance <= attack_reach and _attack_timer <= 0.0:
		_attack_timer = attack_cooldown
		attack_landed.emit(attack_damage)


func take_damage(amount: int) -> void:
	if _defeated or amount <= 0:
		return
	_health = maxi(0, _health - amount)
	if _health == 0:
		_defeated = true
		defeated.emit()
		queue_free()
