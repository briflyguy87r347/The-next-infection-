class_name ArcadeVehicle
extends CharacterBody3D

# Prototype car: arcade steering tuned for mobile, deliberately not full car physics.
var speed: float = 0.0
const TOP_SPEED: float = 18.0
const REVERSE_SPEED: float = -7.5
const ACCELERATION: float = 11.0
const DRAG: float = 5.0

func _ready() -> void:
    name = "SalvageTruck"
    var collision := CollisionShape3D.new()
    collision.name = "TruckCollision"
    collision.position = Vector3(0, 0.85, 0)
    var shape := BoxShape3D.new()
    shape.size = Vector3(1.7, 1.65, 3.8)
    collision.shape = shape
    add_child(collision)
    _part("Chassis", Vector3(0,0.7,0), Vector3(1.9,0.7,4.0), Color(0.21,0.30,0.28))
    _part("Cab", Vector3(0,1.3,-0.6), Vector3(1.75,0.85,1.8), Color(0.18,0.26,0.24))
    _part("Window", Vector3(0,1.5,-1.53), Vector3(1.5,0.48,0.06), Color(0.13,0.20,0.24))
    _part("Bed", Vector3(0,1.0,1.2), Vector3(1.85,0.28,1.5), Color(0.14,0.20,0.19))
    _part("HeadlampL", Vector3(-0.64,0.85,-2.03), Vector3(0.3,0.15,0.08), Color(0.85,0.78,0.58))
    _part("HeadlampR", Vector3(0.64,0.85,-2.03), Vector3(0.3,0.15,0.08), Color(0.85,0.78,0.58))
    for side in [-1.0,1.0]:
        for longitudinal in [-1.3,1.36]:
            var wheel := MeshInstance3D.new()
            var circle := CylinderMesh.new()
            circle.top_radius = 0.37
            circle.bottom_radius = 0.37
            circle.height = 0.24
            wheel.mesh = circle
            wheel.rotation.z = PI/2.0
            wheel.position = Vector3(side*0.91,0.43,longitudinal)
            var mat := StandardMaterial3D.new()
            mat.albedo_color = Color(0.06,0.06,0.06)
            wheel.material_override = mat
            add_child(wheel)

func _part(label: String, at: Vector3, dimensions: Vector3, tint: Color) -> void:
    var visual := MeshInstance3D.new()
    visual.name = label
    var box := BoxMesh.new()
    box.size = dimensions
    visual.mesh = box
    visual.position = at
    var material := StandardMaterial3D.new()
    material.albedo_color = tint
    material.roughness = 0.72
    visual.material_override = material
    add_child(visual)

func drive(throttle: float, steering: float, delta: float) -> void:
    var target: float = TOP_SPEED * clampf(throttle, 0.0, 1.0) + REVERSE_SPEED * clampf(-throttle, 0.0, 1.0)
    speed = move_toward(speed, target, (ACCELERATION if absf(throttle) > 0.05 else DRAG) * delta)
    if absf(speed) > 0.35:
        rotation.y += steering * delta * 1.55 * clampf(speed / 6.0, -1.0, 1.0)
    var forward: Vector3 = -global_transform.basis.z
    velocity.x = forward.x * speed
    velocity.z = forward.z * speed
    if not is_on_floor():
        velocity.y -= 16.0 * delta
    else:
        velocity.y = 0.0
    move_and_slide()
    if get_slide_collision_count() > 0 and absf(speed) > 2.0:
        speed *= 0.60
