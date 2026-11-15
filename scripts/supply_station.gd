class_name SupplyStation
extends StaticBody3D

# Interactive stationary device; actual spending handled by CombatDirector.
var station_type: String = "mystery"
var display_name: String = "MYSTERY CRATE"
var _label: Label3D


func _ready() -> void:
	name = "Station_" + station_type
	var color: Color = Color(0.20, 0.35, 0.65)
	match station_type:
		"upgrade":
			color = Color(0.62, 0.22, 0.78)
			display_name = "WEAPON FORGE"
		"heal":
			color = Color(0.18, 0.56, 0.38)
			display_name = "MEDICAL SUPPLY"
		"ammo":
			color = Color(0.63, 0.43, 0.16)
			display_name = "AMMO RESUPPLY"
		_:
			display_name = "MYSTERY CRATE"

	var base := BoxMesh.new()
	base.size = Vector3(1.65, 0.9, 1.15)
	var body := MeshInstance3D.new()
	body.name = "MachineBase"
	body.mesh = base
	body.material_override = _material(color.darkened(0.42))
	body.position.y = 0.46
	add_child(body)

	var panel := BoxMesh.new()
	panel.size = Vector3(1.36, 0.46, 0.06)
	var panel_visual := MeshInstance3D.new()
	panel_visual.name = "IlluminatedFront"
	panel_visual.mesh = panel
	var bright := _material(color)
	bright.emission_enabled = true
	bright.emission = color
	bright.emission_energy_multiplier = 0.4
	panel_visual.material_override = bright
	panel_visual.position = Vector3(0, 0.63, -0.6)
	add_child(panel_visual)

	var rim := BoxMesh.new()
	rim.size = Vector3(1.8, 0.15, 1.3)
	var top := MeshInstance3D.new()
	top.mesh = rim
	top.material_override = _material(Color(0.11, 0.12, 0.15))
	top.position.y = 0.98
	add_child(top)

	var shape := CollisionShape3D.new()
	var collision := BoxShape3D.new()
	collision.size = Vector3(1.65, 1.0, 1.15)
	shape.shape = collision
	shape.position.y = 0.5
	add_child(shape)

	_label = Label3D.new()
	_label.name = "WorldLabel"
	_label.position.y = 1.47
	_label.text = display_name
	_label.font_size = 30
	_label.pixel_size = 0.006
	_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_label.modulate = Color.WHITE
	_label.no_depth_test = true
	add_child(_label)


func _material(color: Color) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.76
	return mat
