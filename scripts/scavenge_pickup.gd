class_name ScavengePickup
extends Node3D

signal collected(kind: String, amount: int)
signal save_failed(message: String)

var kind: String = "parts"
var amount: int = 1
var target: FirstPersonPlayer
var _life: float = 24.0
var _spin: float = 0.0
var _visual: MeshInstance3D
var _pickup_id: String = SurvivalBank.make_run_id()
var _retry_delay: float = 0.0

func _ready() -> void:
	_visual = MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = Vector3(0.30,0.25,0.30)
	_visual.mesh = mesh
	var mat := StandardMaterial3D.new()
	match kind:
		"parts": mat.albedo_color = Color(0.31,0.66,0.92)
		"fabrication": mat.albedo_color = Color(0.93,0.70,0.25)
		"medkit": mat.albedo_color = Color(0.32,0.83,0.48)
		"ammo": mat.albedo_color = Color(0.77,0.50,0.22)
	_visual.material_override = mat
	add_child(_visual)
	var name_label := Label3D.new()
	name_label.text = kind.to_upper()
	name_label.font_size = 25
	name_label.pixel_size = 0.005
	name_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	name_label.no_depth_test = true
	name_label.position.y = 0.44
	add_child(name_label)

func _process(delta: float) -> void:
	_life -= delta
	if _life <= 0:
		queue_free()
		return
	_spin += delta
	_visual.rotation.y = _spin * 2.0
	_visual.position.y = sin(_spin * 3.0) * 0.075
	_retry_delay = maxf(0.0, _retry_delay - delta)
	if _retry_delay > 0.0:
		return
	if is_instance_valid(target) and global_position.distance_squared_to(target.global_position + Vector3.UP * 0.75) < 3.0:
		if kind == "parts" or kind == "fabrication":
			var result: Dictionary = WorldProgress.credit_pickup(_pickup_id, kind, amount)
			if not bool(result.get("ok", false)):
				save_failed.emit(str(result.get("message", "Save failed")))
				_retry_delay = 2.0
				return
		collected.emit(kind, amount)
		queue_free()
