class_name GunViewmodel
extends Node3D

# Module 010. Distinct ORIGINAL procedural first-person firearm silhouettes.
# Deliberately lightweight for low-end Android; not photorealistic or externally licensed gun assets.
var _shape_root: Node3D
var _flash: MeshInstance3D
var _flash_timer: float = 0.0
var _kick: float = 0.0
var _equip_timer: float = 0.0
var _reload_timer: float = 0.0
var _ads: bool = false
var _id: String = "pistol"
var _home: Vector3 = Vector3(0.31, -0.28, -0.68)
const HIP: Vector3 = Vector3(0.31, -0.28, -0.68)
const AIM: Vector3 = Vector3(0.015, -0.20, -0.60)

func _ready() -> void:
	_shape_root = Node3D.new()
	add_child(_shape_root)
	set_weapon("pistol")
	position = HIP

func set_weapon(id: String) -> void:
	_id = id
	if not is_instance_valid(_shape_root):
		return
	for node in _shape_root.get_children():
		_shape_root.remove_child(node)
		node.queue_free()
	var receiver := Color(0.17,0.19,0.20)
	var polymer := Color(0.07,0.082,0.087)
	var steel := Color(0.32,0.34,0.36)
	var wood := Color(0.32,0.20,0.12)
	var length: float = 0.30
	var body_width: float = 0.15
	var stock: bool = false
	match id:
		"smg":
			length = 0.56
			body_width = 0.17
			stock = true
		"rifle":
			length = 0.83
			body_width = 0.17
			stock = true
		"shotgun":
			length = 0.93
			body_width = 0.16
			stock = true
			receiver = wood
		"lmg":
			length = 0.91
			body_width = 0.23
			stock = true
			receiver = Color(0.23,0.24,0.23)
	# Receiver, slide/dust cover, fore-end and barrel are separate surfaces.
	_box("Receiver", Vector3(0,0,-length*0.28), Vector3(body_width,0.15,length*0.57), receiver, 0.45)
	_box("TopSlide", Vector3(0,0.074,-length*0.30), Vector3(body_width*0.92,0.026,length*0.50), steel, 0.64)
	_box("Grip", Vector3(0,-0.14,-0.035), Vector3(0.09,0.27,0.115), polymer)
	_box("TriggerGuard", Vector3(0,-0.073,-0.14), Vector3(0.09,0.022,0.11), steel)
	_cylinder("Muzzle", Vector3(0,0.0,-length*0.98), 0.035 if id != "lmg" else 0.047, length*0.64, steel)
	_cylinder("Bore", Vector3(0,0.0,-length*1.29), 0.019, 0.012, polymer)
	_box("FrontSight", Vector3(0,0.115,-length*1.08), Vector3(0.03,0.07,0.028), polymer)
	_box("RearSight", Vector3(0,0.115,-length*0.24), Vector3(0.07,0.044,0.029), polymer)
	_box("EjectionPort", Vector3(body_width*0.47,0.041,-length*0.29), Vector3(0.011,0.025,0.085), polymer)
	if stock:
		_box("ShoulderStock", Vector3(0,-0.012,0.22), Vector3(0.11,0.11,0.44), polymer)
		_box("StockPad", Vector3(0,-0.016,0.45), Vector3(0.14,0.16,0.055), polymer)
		_box("Magazine", Vector3(0,-0.18,-length*0.35), Vector3(body_width*0.58,0.32 if id != "lmg" else 0.43,0.13), polymer)
		_box("ForwardHandguard", Vector3(0,-0.01,-length*0.76), Vector3(body_width*0.93,0.13,length*0.35), receiver)
		_box("GripRail", Vector3(0,0.11,-length*0.57), Vector3(0.055,0.024,length*0.31), polymer)
		if id == "rifle":
			_box("OpticBase", Vector3(0,0.15,-0.36), Vector3(0.10,0.06,0.12), polymer)
			_cylinder("OpticLens", Vector3(0,0.195,-0.37), 0.042, 0.12, steel)
		if id == "smg":
			_box("CompactMagazine", Vector3(0,-0.22,-0.20), Vector3(0.065,0.30,0.085), polymer)
		if id == "shotgun":
			_cylinder("PumpTube", Vector3(0,-0.062,-0.65),0.026,0.60,polymer)
			_box("PumpGrip", Vector3(0,-0.075,-0.63),Vector3(0.14,0.12,0.27),wood)
		if id == "lmg":
			_box("BoxMagazine", Vector3(-0.07,-0.18,-0.36),Vector3(0.29,0.26,0.28),steel)
			_box("BipodLeft", Vector3(-0.14,-0.13,-0.67),Vector3(0.025,0.32,0.025),polymer)
			_box("BipodRight", Vector3(0.14,-0.13,-0.67),Vector3(0.025,0.32,0.025),polymer)
	# A pair of textured low-poly gloves make the silhouette clearly held.
	_box("RightGlove", Vector3(0.11,-0.16,0.03),Vector3(0.14,0.16,0.20),Color(0.31,0.32,0.27))
	_box("RightSleeve", Vector3(0.16,-0.38,0.17),Vector3(0.20,0.32,0.30),Color(0.19,0.24,0.22))
	if stock:
		_box("SupportGlove", Vector3(-0.12,-0.14,-length*0.64),Vector3(0.13,0.13,0.17),Color(0.32,0.34,0.28))
	_flash = MeshInstance3D.new()
	var flash_mesh := SphereMesh.new()
	flash_mesh.radius = 0.095
	flash_mesh.height = 0.19
	_flash.mesh = flash_mesh
	_flash.position = Vector3(0,0,-length*1.32)
	var flash_mat := StandardMaterial3D.new()
	flash_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	flash_mat.albedo_color = Color(1.0,0.84,0.39)
	flash_mat.emission_enabled = true
	flash_mat.emission = Color(1.0,0.52,0.07)
	flash_mat.emission_energy_multiplier = 2.0
	_flash.material_override = flash_mat
	_flash.visible = false
	_shape_root.add_child(_flash)
	_equip_timer = 0.32
	_reload_timer = 0.0

func _box(name: String, at: Vector3, dim: Vector3, color: Color, metal: float = 0.15) -> void:
	var part := MeshInstance3D.new()
	part.name = name
	var mesh := BoxMesh.new()
	mesh.size = dim
	part.mesh = mesh
	part.position = at
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.metallic = metal
	mat.roughness = 0.47
	part.material_override = mat
	_shape_root.add_child(part)

func _cylinder(name: String, at: Vector3, radius: float, height: float, color: Color) -> void:
	var part := MeshInstance3D.new()
	part.name = name
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = height
	mesh.radial_segments = 10
	part.mesh = mesh
	part.rotation_degrees.x = 90.0
	part.position = at
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.metallic = 0.68
	mat.roughness = 0.36
	part.material_override = mat
	_shape_root.add_child(part)

func set_ads(enabled: bool) -> void:
	_ads = enabled

func fire() -> void:
	_kick = 1.0
	_flash_timer = 0.075
	if is_instance_valid(_flash):
		_flash.visible = true

func play_reload(duration: float) -> void:
	_reload_timer = maxf(0.15, duration)

func _process(delta: float) -> void:
	_kick = move_toward(_kick,0.0,delta*9.0)
	_equip_timer = maxf(0.0,_equip_timer-delta)
	_reload_timer = maxf(0.0,_reload_timer-delta)
	var goal: Vector3 = AIM if _ads else HIP
	var dip: float = 0.12 if _reload_timer > 0.0 else 0.0
	var equip_dip: float = 0.11 * clampf(_equip_timer/0.32,0.0,1.0)
	_home = _home.lerp(goal,minf(delta*10.0,1.0))
	position = _home + Vector3(0,-dip-equip_dip+0.018*_kick,0.10*_kick)
	rotation.x = -0.10*_kick + (0.20 if _reload_timer > 0.0 else 0.0)
	rotation.z = sin(_reload_timer*11.0)*0.13 if _reload_timer > 0.0 else 0.0
	if _flash_timer > 0.0:
		_flash_timer -= delta
		if _flash_timer <= 0.0 and is_instance_valid(_flash):
			_flash.visible = false
