class_name FirstPersonPlayer
extends CharacterBody3D

signal health_changed(current_health: int, maximum_health: int)

@export var walk_speed: float = 4.5
@export var sprint_speed: float = 7.0
@export var jump_velocity: float = 4.5
@export var look_sensitivity: float = 0.0025
@export var look_smoothing: float = 14.0
@export var maximum_health: int = 100

const GRAVITY: float = 9.8
const MINIMUM_PITCH: float = -1.3962634
const MAXIMUM_PITCH: float = 1.3962634

var health: int = 100
var _target_yaw: float = 0.0
var _target_pitch: float = 0.0
var _mobile_movement: Vector2 = Vector2.ZERO
var _mobile_sprinting: bool = false
var _mobile_jump_requested: bool = false

@onready var _camera_pivot: Node3D = $CameraPivot


func _ready() -> void:
	health = maximum_health
	_configure_keyboard_controls()
	if not OS.has_feature("mobile"):
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	health_changed.emit(health, maximum_health)


func _process(delta: float) -> void:
	var blend := minf(look_smoothing * delta, 1.0)
	rotation.y = lerp_angle(rotation.y, _target_yaw, blend)
	_camera_pivot.rotation.x = lerp_angle(_camera_pivot.rotation.x, _target_pitch, blend)


func _physics_process(delta: float) -> void:
	var keyboard_movement := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var movement_input := _mobile_movement if _mobile_movement.length_squared() > 0.01 else keyboard_movement
	var local_direction := Vector3(movement_input.x, 0.0, movement_input.y)
	var movement_direction := (global_transform.basis * local_direction).normalized()
	var target_speed := sprint_speed if _mobile_sprinting or Input.is_action_pressed("sprint") else walk_speed
	var acceleration := 20.0 if is_on_floor() else 7.0

	velocity.x = move_toward(velocity.x, movement_direction.x * target_speed, acceleration * delta)
	velocity.z = move_toward(velocity.z, movement_direction.z * target_speed, acceleration * delta)

	if is_on_floor():
		if velocity.y < 0.0:
			velocity.y = 0.0
		if Input.is_action_just_pressed("jump") or _mobile_jump_requested:
			velocity.y = jump_velocity
	else:
		velocity.y -= GRAVITY * delta

	_mobile_jump_requested = false
	move_and_slide()


func set_mobile_movement(direction: Vector2) -> void:
	_mobile_movement = direction.limit_length(1.0)


func set_mobile_sprinting(active: bool) -> void:
	_mobile_sprinting = active


func request_jump() -> void:
	_mobile_jump_requested = true


func apply_touch_look(relative_motion: Vector2) -> void:
	_apply_look(relative_motion)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.physical_keycode == KEY_ESCAPE and event.pressed:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	elif event is InputEventMouseButton and event.pressed and not OS.has_feature("mobile"):
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	elif event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		_apply_look(event.relative)


func _apply_look(relative_motion: Vector2) -> void:
	_target_yaw -= relative_motion.x * look_sensitivity
	_target_pitch = clampf(
		_target_pitch - relative_motion.y * look_sensitivity,
		MINIMUM_PITCH,
		MAXIMUM_PITCH
	)


func _configure_keyboard_controls() -> void:
	_add_key_binding("move_forward", KEY_W)
	_add_key_binding("move_back", KEY_S)
	_add_key_binding("move_left", KEY_A)
	_add_key_binding("move_right", KEY_D)
	_add_key_binding("jump", KEY_SPACE)
	_add_key_binding("sprint", KEY_SHIFT)


func _add_key_binding(action_name: String, key_code: Key) -> void:
	if not InputMap.has_action(action_name):
		InputMap.add_action(action_name)
	for existing_event in InputMap.action_get_events(action_name):
		if existing_event is InputEventKey and existing_event.physical_keycode == key_code:
			return
	var key_event := InputEventKey.new()
	key_event.physical_keycode = key_code
	InputMap.action_add_event(action_name, key_event)
