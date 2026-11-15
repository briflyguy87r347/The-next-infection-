class_name TouchHUD
extends CanvasLayer

signal move_changed(direction: Vector2)
signal look_changed(relative_motion: Vector2)
signal jump_pressed
signal sprint_changed(active: bool)
signal fire_changed(active: bool)
signal reload_pressed

const JOYSTICK_COLOR := Color(0.12, 0.16, 0.18, 0.62)
const THUMB_COLOR := Color(0.68, 0.76, 0.72, 0.82)
const BUTTON_COLOR := Color(0.18, 0.25, 0.27, 0.78)
const BUTTON_BORDER := Color(0.76, 0.83, 0.79, 0.82)

var _overlay: Control
var _health_label: Label
var _health_fill: ColorRect
var _joystick_base: Panel
var _joystick_thumb: Panel
var _jump_button: Panel
var _sprint_button: Panel
var _fire_button: Panel
var _reload_button: Panel
var _touch_controls_visible: bool = false
var _joystick_center: Vector2 = Vector2.ZERO
var _joystick_radius: float = 0.0
var _touch_roles: Dictionary = {}


func _ready() -> void:
	set_process_input(true)
	_touch_controls_visible = OS.has_feature("mobile") or DisplayServer.is_touchscreen_available()
	_build_overlay()
	get_viewport().size_changed.connect(_layout_controls)
	_layout_controls()


func set_health(current_health: int, maximum_health: int) -> void:
	if not is_instance_valid(_health_label):
		return
	_health_label.text = "HEALTH  %d / %d" % [current_health, maximum_health]
	_health_fill.size = Vector2(
		174.0 * clampf(float(current_health) / float(maximum_health), 0.0, 1.0),
		10.0
	)


func _build_overlay() -> void:
	_overlay = Control.new()
	_overlay.name = "Overlay"
	_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_overlay)

	var health_panel := ColorRect.new()
	health_panel.position = Vector2(18.0, 16.0)
	health_panel.size = Vector2(194.0, 58.0)
	health_panel.color = Color(0.02, 0.04, 0.04, 0.68)
	health_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_overlay.add_child(health_panel)

	_health_label = Label.new()
	_health_label.position = Vector2(10.0, 5.0)
	_health_label.add_theme_font_size_override("font_size", 16)
	_health_label.add_theme_color_override("font_color", Color(0.92, 0.96, 0.91))
	_health_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	health_panel.add_child(_health_label)

	var health_bar_background := ColorRect.new()
	health_bar_background.position = Vector2(10.0, 34.0)
	health_bar_background.size = Vector2(174.0, 10.0)
	health_bar_background.color = Color(0.16, 0.20, 0.19)
	health_bar_background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	health_panel.add_child(health_bar_background)

	_health_fill = ColorRect.new()
	_health_fill.size = Vector2(174.0, 10.0)
	_health_fill.color = Color(0.35, 0.78, 0.46)
	_health_fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	health_bar_background.add_child(_health_fill)

	_joystick_base = _make_disc(JOYSTICK_COLOR, BUTTON_BORDER)
	_joystick_thumb = _make_disc(THUMB_COLOR, Color(0.9, 0.96, 0.92, 0.92))
	_jump_button = _make_disc(BUTTON_COLOR, BUTTON_BORDER)
	_sprint_button = _make_disc(BUTTON_COLOR, BUTTON_BORDER)
	_fire_button = _make_disc(Color(0.43, 0.16, 0.14, 0.85), BUTTON_BORDER)
	_reload_button = _make_disc(BUTTON_COLOR, BUTTON_BORDER)
	_overlay.add_child(_joystick_base)
	_overlay.add_child(_joystick_thumb)
	_overlay.add_child(_jump_button)
	_overlay.add_child(_sprint_button)
	_overlay.add_child(_fire_button)
	_overlay.add_child(_reload_button)
	_add_button_label(_jump_button, "JUMP")
	_add_button_label(_sprint_button, "SPRINT")
	_add_button_label(_fire_button, "FIRE")
	_add_button_label(_reload_button, "RELOAD")

	for control in [_joystick_base, _joystick_thumb, _jump_button, _sprint_button, _fire_button, _reload_button]:
		control.visible = _touch_controls_visible


func _layout_controls() -> void:
	if not is_instance_valid(_overlay):
		return
	var viewport_size := get_viewport().get_visible_rect().size
	var short_side := minf(viewport_size.x, viewport_size.y)
	var button_radius := clampf(short_side * 0.065, 34.0, 58.0)
	_joystick_radius = clampf(short_side * 0.13, 52.0, 96.0)
	_joystick_center = Vector2(viewport_size.x * 0.17, viewport_size.y * 0.78)

	_set_disc_layout(_joystick_base, _joystick_center, _joystick_radius)
	_set_disc_layout(_joystick_thumb, _joystick_center, _joystick_radius * 0.35)
	_set_disc_layout(_jump_button, Vector2(viewport_size.x * 0.88, viewport_size.y * 0.70), button_radius)
	_set_disc_layout(_sprint_button, Vector2(viewport_size.x * 0.88, viewport_size.y * 0.88), button_radius)
	_set_disc_layout(_fire_button, Vector2(viewport_size.x * 0.70, viewport_size.y * 0.73), button_radius * 1.1)
	_set_disc_layout(_reload_button, Vector2(viewport_size.x * 0.70, viewport_size.y * 0.91), button_radius * 0.80)


func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed:
			if _begin_touch(event.index, event.position):
				get_viewport().set_input_as_handled()
		else:
			if _end_touch(event.index):
				get_viewport().set_input_as_handled()
	elif event is InputEventScreenDrag and _touch_roles.has(event.index):
		_update_touch(event.index, event.position, event.relative)
		get_viewport().set_input_as_handled()


func _begin_touch(index: int, position: Vector2) -> bool:
	if position.distance_to(_joystick_center) <= _joystick_radius * 1.5:
		_touch_roles[index] = "move"
		_update_joystick(position)
		return true
	if _jump_button.get_global_rect().has_point(position):
		_touch_roles[index] = "jump"
		jump_pressed.emit()
		return true
	if _sprint_button.get_global_rect().has_point(position):
		_touch_roles[index] = "sprint"
		sprint_changed.emit(true)
		return true
	if _fire_button.visible and _fire_button.get_global_rect().has_point(position):
		_touch_roles[index] = "fire"
		fire_changed.emit(true)
		return true
	if _reload_button.visible and _reload_button.get_global_rect().has_point(position):
		_touch_roles[index] = "reload"
		reload_pressed.emit()
		return true
	if position.x >= get_viewport().get_visible_rect().size.x * 0.5:
		_touch_roles[index] = "look"
		return true
	return false


func _end_touch(index: int) -> bool:
	if not _touch_roles.has(index):
		return false
	var role: String = _touch_roles[index]
	_touch_roles.erase(index)
	match role:
		"move":
			move_changed.emit(Vector2.ZERO)
			_set_disc_layout(_joystick_thumb, _joystick_center, _joystick_radius * 0.35)
		"sprint":
			sprint_changed.emit(false)
		"fire":
			fire_changed.emit(false)
	return true


func _update_touch(index: int, position: Vector2, relative_motion: Vector2) -> void:
	match _touch_roles[index]:
		"move":
			_update_joystick(position)
		"look":
			look_changed.emit(relative_motion)


func _update_joystick(position: Vector2) -> void:
	var displacement := (position - _joystick_center).limit_length(_joystick_radius)
	var direction := displacement / _joystick_radius
	if direction.length() < 0.12:
		direction = Vector2.ZERO
	move_changed.emit(direction)
	_set_disc_layout(
		_joystick_thumb,
		_joystick_center + displacement * 0.62,
		_joystick_radius * 0.35
	)


func _make_disc(fill_color: Color, border_color: Color) -> Panel:
	var panel := Panel.new()
	var style := StyleBoxFlat.new()
	style.bg_color = fill_color
	style.border_color = border_color
	style.set_border_width_all(2)
	style.set_corner_radius_all(100)
	panel.add_theme_stylebox_override("panel", style)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return panel


func _add_button_label(button: Panel, text: String) -> void:
	var label := Label.new()
	label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 14)
	label.add_theme_color_override("font_color", Color.WHITE)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.add_child(label)


func _set_disc_layout(panel: Panel, center: Vector2, radius: float) -> void:
	panel.position = center - Vector2.ONE * radius
	panel.size = Vector2.ONE * radius * 2.0
