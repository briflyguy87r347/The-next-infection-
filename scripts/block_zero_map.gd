class_name BlockZeroMap
extends Node3D

# Original suburban survival arena. Inspired by the *pace* of compact two-house
# multiplayer maps; not a reproduction of Nuketown's protected layout or assets.
var stations: Array[SupplyStation] = []


func _ready() -> void:
	name = "BlockZero"
	_build_ground()
	_build_house(-17.5, true, Color(0.34, 0.46, 0.48))
	_build_house(17.5, false, Color(0.54, 0.43, 0.38))
	_build_street()
	_build_props()
	_build_stations()
	_build_lighting()


func _build_ground() -> void:
	_box(self, "ResidentialGround", Vector3(0, -0.55, 0), Vector3(66, 1.1, 66), Color(0.29, 0.32, 0.27))
	# Fence walls have two alleyway gaps on either side for player escape lanes.
	_box(self, "NorthFence", Vector3(0, 1.15, -32.5), Vector3(65, 2.3, 0.6), Color(0.23, 0.28, 0.27))
	_box(self, "SouthFence", Vector3(0, 1.15, 32.5), Vector3(65, 2.3, 0.6), Color(0.23, 0.28, 0.27))
	for side in [-1.0, 1.0]:
		_box(self, "WestEastFence", Vector3(side * 32.5, 1.15, 0), Vector3(0.6, 2.3, 65), Color(0.22, 0.27, 0.27))


func _build_house(x: float, left: bool, tint: Color) -> void:
	var house := Node3D.new()
	house.name = "WestRowHouse" if left else "EastRowHouse"
	add_child(house)
	var center := Vector3(x, 0, 0)
	var front_x: float = x + 6.2 if left else x - 6.2
	var rear_x: float = x - 6.2 if left else x + 6.2
	var wall_color: Color = tint
	var inside := Color(0.32, 0.32, 0.30)
	_box(house, "Floor", center + Vector3(0, 0.13, 0), Vector3(12.4, 0.26, 13.4), inside)
	for z in [-6.55, 6.55]:
		_box(house, "WallSide", Vector3(x, 1.55, z), Vector3(12.4, 3.10, 0.35), wall_color)
	_box(house, "RearWall", Vector3(rear_x, 1.55, 0), Vector3(0.35, 3.10, 13.3), wall_color.darkened(0.08))
	# Wide front entrance, plus two low concrete window sills.
	for z in [-4.0, 4.0]:
		_box(house, "FrontSection", Vector3(front_x, 1.55, z), Vector3(0.35, 3.10, 5.2), wall_color)
	_box(house, "DoorLintel", Vector3(front_x, 2.72, 0), Vector3(0.45, 0.75, 2.8), wall_color)
	_box(house, "Ceiling", Vector3(x, 3.21, 0), Vector3(12.6, 0.28, 13.4), Color(0.15, 0.17, 0.18))
	# Upper floor facade intentionally solid: detail without expensive interiors.
	for z in [-6.55, 6.55]:
		_box(house, "UpperWall", Vector3(x, 4.50, z), Vector3(12.4, 2.35, 0.35), wall_color.lightened(0.07))
	for wall_x in [front_x, rear_x]:
		_box(house, "UpperWallEnd", Vector3(wall_x, 4.50, 0), Vector3(0.35, 2.35, 13.3), wall_color.lightened(0.09))
	_box(house, "Roof", Vector3(x, 5.85, 0), Vector3(13.0, 0.32, 14.1), Color(0.15, 0.18, 0.20))
	# Upper floor windows are non-interactive; first floor is playable.
	for z in [-3.35, 3.35]:
		_decoration(house, "DarkWindow", Vector3(front_x + (0.21 if left else -0.21), 4.60, z), Vector3(0.07, 1.12, 2.0), Color(0.08, 0.16, 0.21))
	# Inside cover helps distinguish the two houses.
	_box(house, "InsideCover", Vector3(x, 0.65, 2.9 if left else -2.9), Vector3(2.8, 1.3, 1.0), Color(0.38, 0.34, 0.29))
	# Backyard sheds leave paths around the main entrances.
	_box(house, "YardCrate", Vector3(x, 0.55, -10.7), Vector3(2.1, 1.1, 2.0), Color(0.30, 0.36, 0.35))


func _build_street() -> void:
	_decoration(self, "WornRoad", Vector3(0, 0.025, 0), Vector3(13.5, 0.05, 64.0), Color(0.12, 0.14, 0.15))
	for side in [-1.0, 1.0]:
		_decoration(self, "Walkway", Vector3(side * 7.4, 0.06, 0), Vector3(1.0, 0.09, 64.0), Color(0.44, 0.43, 0.38))
	for z in [-26.0, -18.0, -10.0, -2.0, 6.0, 14.0, 22.0]:
		_decoration(self, "LaneStripe", Vector3(0, 0.073, z), Vector3(0.18, 0.012, 3.8), Color(0.72, 0.62, 0.38))


func _build_props() -> void:
	# An abandoned evacuation shuttle and damaged sedan make original center cover.
	_box(self, "EvacShuttleChassis", Vector3(-1.8, 0.92, -7.8), Vector3(2.55, 1.85, 5.2), Color(0.25, 0.36, 0.40))
	_decoration(self, "EvacShuttleWindshield", Vector3(-1.8, 1.63, -10.43), Vector3(2.15, 0.68, 0.07), Color(0.08, 0.17, 0.23))
	for z in [-9.25, -6.38]:
		for side in [-1.0, 1.0]:
			_box(self, "ShuttleWheel", Vector3(-1.8 + side * 1.17, 0.34, z), Vector3(0.18, 0.67, 0.8), Color(0.08, 0.09, 0.09))
	_box(self, "DamagedSedan", Vector3(2.2, 0.68, 9.8), Vector3(2.6, 1.35, 3.85), Color(0.48, 0.30, 0.28))
	_decoration(self, "SedanGlass", Vector3(2.2, 1.41, 9.8), Vector3(1.9, 0.24, 2.1), Color(0.10, 0.19, 0.24))
	# Small outer-lane cover pieces.
	for side in [-1.0, 1.0]:
		for z in [-18.0, 21.0]:
			_box(self, "Barrier", Vector3(side * 8.8, 0.48, z), Vector3(0.72, 0.96, 3.2), Color(0.41, 0.40, 0.37))
	for side in [-1.0, 1.0]:
		for z in [-25.5, 25.5]:
			_decoration(self, "LampPost", Vector3(side * 8.9, 2.5, z), Vector3(0.15, 5.0, 0.15), Color(0.20, 0.23, 0.26))
			_decoration(self, "LampHead", Vector3(side * 8.9, 5.0, z), Vector3(0.65, 0.2, 0.65), Color(0.69, 0.66, 0.48))


func _build_stations() -> void:
	_make_station("mystery", Vector3(-5.5, 0, 5.0))
	_make_station("upgrade", Vector3(5.6, 0, -6.4))
	_make_station("heal", Vector3(-5.5, 0, 19.0))
	_make_station("ammo", Vector3(5.5, 0, 19.0))


func _make_station(kind: String, at: Vector3) -> void:
	var station := SupplyStation.new()
	station.station_type = kind
	station.position = at
	add_child(station)
	stations.append(station)


func _build_lighting() -> void:
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-53.0, -21.0, 0.0)
	sun.light_color = Color(0.83, 0.83, 0.76)
	sun.light_energy = 0.85
	sun.shadow_enabled = false
	add_child(sun)
	var environment := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.10, 0.13, 0.14)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.42, 0.44, 0.44)
	env.ambient_light_energy = 0.65
	environment.environment = env
	add_child(environment)


func _box(parent: Node3D, label: String, at: Vector3, dimensions: Vector3, color: Color) -> void:
	var body := StaticBody3D.new()
	body.name = label
	body.position = at
	var shape := BoxShape3D.new()
	shape.size = dimensions
	var collision := CollisionShape3D.new()
	collision.shape = shape
	body.add_child(collision)
	var mesh := BoxMesh.new()
	mesh.size = dimensions
	var visual := MeshInstance3D.new()
	visual.mesh = mesh
	visual.material_override = _material(color)
	body.add_child(visual)
	parent.add_child(body)


func _decoration(parent: Node3D, label: String, at: Vector3, dimensions: Vector3, color: Color) -> void:
	var mesh := BoxMesh.new()
	mesh.size = dimensions
	var visual := MeshInstance3D.new()
	visual.name = label
	visual.position = at
	visual.mesh = mesh
	visual.material_override = _material(color)
	parent.add_child(visual)


func _material(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.92
	return material
