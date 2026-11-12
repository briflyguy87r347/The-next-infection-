extends Node3D

func _ready() -> void:
	print("THE NEXT INFECTION")
	print("OUTBREAK ZERO initialized")
	build_world()

func build_world() -> void:
	var ground := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = Vector3(40, 1, 40)
	ground.mesh = mesh
	ground.position.y = -0.5
	add_child(ground)

	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-45, -30, 0)
	add_child(light)

	var camera := Camera3D.new()
	camera.position = Vector3(0, 2, 8)
	camera.rotation_degrees.x = -12
	camera.current = true
	add_child(camera)
