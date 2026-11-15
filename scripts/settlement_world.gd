class_name SettlementWorld
extends Node3D

# A physically visitable, original starter neighborhood. All geometry is generated
# from lightweight Godot primitives so it remains usable on an Android tablet.
var _safehouse_door: StaticBody3D
var _generator_visual: Node3D
var _barricade_visual: Node3D

func _ready() -> void:
    name = "StarterSettlement"
    _build_ground()
    _build_safehouse()
    _build_workshop()
    _build_generator_pad()
    _build_furniture()
    _build_signs()
    _build_lighting()
    refresh_state()

func refresh_state() -> void:
    var state: Dictionary = SurvivalBank.load_bank()
    var owns_home: bool = (state["owned"] as Array).has("safehouse")
    if is_instance_valid(_safehouse_door):
        _safehouse_door.visible = not owns_home
        var collision := _safehouse_door.get_node("CollisionShape3D") as CollisionShape3D
        collision.set_deferred("disabled", owns_home)
    if is_instance_valid(_generator_visual):
        _generator_visual.visible = bool(state["generator_built"])
    if is_instance_valid(_barricade_visual):
        _barricade_visual.visible = bool(state["barricades_built"])

func _build_ground() -> void:
    _box(self, "Ground", Vector3(0, -0.55, 0), Vector3(70, 1.1, 65), Color(0.27, 0.31, 0.26))
    _visual(self, "Road", Vector3(0, 0.03, 14), Vector3(56, 0.05, 8), Color(0.12, 0.14, 0.15))
    _visual(self, "Footpath", Vector3(0, 0.04, -4), Vector3(2.4, 0.07, 32), Color(0.42, 0.41, 0.37))
    for x in [-32.0, 32.0]:
        _box(self, "OuterFence", Vector3(x, 1.0, -10), Vector3(0.5, 2.0, 41), Color(0.23, 0.28, 0.26))
    _box(self, "RearFence", Vector3(0, 1.0, -30), Vector3(65, 2.0, 0.5), Color(0.23, 0.28, 0.26))
    _sign("SETTLEMENT DISTRICT", Vector3(0, 3.2, 10))

func _build_safehouse() -> void:
    var house := Node3D.new()
    house.name = "StarterSafehouse"
    add_child(house)
    var wall: Color = Color(0.36, 0.46, 0.48)
    _box(house, "Floor", Vector3(-11, 0.1, -12), Vector3(10, 0.2, 9), Color(0.46, 0.42, 0.35))
    _box(house, "BackWall", Vector3(-11, 1.75, -16.5), Vector3(10, 3.5, 0.3), wall)
    _box(house, "LeftWall", Vector3(-16, 1.75, -12), Vector3(0.3, 3.5, 9), wall)
    _box(house, "RightWall", Vector3(-6, 1.75, -12), Vector3(0.3, 3.5, 9), wall)
    _box(house, "FrontLeft", Vector3(-14, 1.75, -7.5), Vector3(4, 3.5, 0.3), wall)
    _box(house, "FrontRight", Vector3(-8, 1.75, -7.5), Vector3(4, 3.5, 0.3), wall)
    _box(house, "Lintel", Vector3(-11, 3.05, -7.5), Vector3(2.0, 0.9, 0.3), wall)
    _box(house, "Roof", Vector3(-11, 3.68, -12), Vector3(10.7, 0.32, 9.8), Color(0.16, 0.18, 0.19))
    _safehouse_door = _box(house, "LockedDoor", Vector3(-11, 1.15, -7.5), Vector3(1.85, 2.3, 0.18), Color(0.36, 0.25, 0.16))
    _sign("SAFEHOUSE / 3000 BANK", Vector3(-11, 2.6, -5.8))
    # Furniture is collidable; players with a deed can walk through the front door.
    _box(house, "Bed", Vector3(-13.1, 0.5, -14.4), Vector3(2.4, 0.65, 1.3), Color(0.27, 0.29, 0.32))
    _box(house, "StorageLocker", Vector3(-8.2, 1.1, -14.8), Vector3(1.3, 2.1, 1.0), Color(0.27, 0.34, 0.34))
    _visual(house, "FloorMat", Vector3(-11, 0.23, -10.5), Vector3(2.4, 0.02, 1.7), Color(0.26, 0.31, 0.28))
    _barricade_visual = Node3D.new()
    _barricade_visual.name = "BuiltBarricades"
    house.add_child(_barricade_visual)
    for at in [Vector3(-14.0, 1.4, -7.16), Vector3(-8.0, 1.4, -7.16)]:
        _visual(_barricade_visual, "Planks", at, Vector3(3.6, 0.24, 0.19), Color(0.44, 0.29, 0.16))
        _visual(_barricade_visual, "Planks", at + Vector3(0, 0.55, 0), Vector3(3.6, 0.24, 0.19), Color(0.44, 0.29, 0.16))

func _build_workshop() -> void:
    var shop := Node3D.new()
    shop.name = "Workshop"
    add_child(shop)
    _box(shop, "Floor", Vector3(11, 0.1, -12), Vector3(10, 0.2, 9), Color(0.38, 0.38, 0.35))
    var wall: Color = Color(0.47, 0.36, 0.29)
    _box(shop, "BackWall", Vector3(11, 1.75, -16.5), Vector3(10, 3.5, 0.3), wall)
    _box(shop, "LeftWall", Vector3(6, 1.75, -12), Vector3(0.3, 3.5, 9), wall)
    _box(shop, "RightWall", Vector3(16, 1.75, -12), Vector3(0.3, 3.5, 9), wall)
    _box(shop, "FrontLeft", Vector3(8.5, 1.75, -7.5), Vector3(5.0, 3.5, 0.3), wall)
    _box(shop, "FrontRight", Vector3(14.5, 1.75, -7.5), Vector3(3.0, 3.5, 0.3), wall)
    _box(shop, "Roof", Vector3(11, 3.68, -12), Vector3(10.7, 0.32, 9.8), Color(0.18, 0.19, 0.20))
    _box(shop, "WorkBench", Vector3(11.5, 0.65, -14), Vector3(3.0, 1.3, 1.2), Color(0.30, 0.33, 0.37))
    _visual(shop, "ToolShelf", Vector3(14.9, 1.6, -13), Vector3(0.3, 2.5, 3.0), Color(0.21, 0.24, 0.24))
    _sign("WORKSHOP / 5500 BANK", Vector3(11, 2.5, -5.7))

func _build_generator_pad() -> void:
    _box(self, "GeneratorPad", Vector3(0, 0.1, -11.5), Vector3(3.5, 0.2, 3.0), Color(0.38, 0.39, 0.36))
    _generator_visual = Node3D.new()
    _generator_visual.name = "InstalledGenerator"
    add_child(_generator_visual)
    _box(_generator_visual, "Generator", Vector3(0, 0.9, -11.5), Vector3(2.3, 1.6, 1.7), Color(0.26, 0.32, 0.27))
    _visual(_generator_visual, "PowerStripe", Vector3(0, 1.25, -10.62), Vector3(1.4, 0.22, 0.08), Color(0.32, 0.92, 0.45))
    _sign("GENERATOR / 2000 BANK", Vector3(0, 2.5, -8.4))

func _build_furniture() -> void:
    for x in [-24.0, 24.0]:
        _box(self, "Crate", Vector3(x, 0.7, -12), Vector3(1.7, 1.4, 1.7), Color(0.39, 0.31, 0.21))
    _sign("BARRICADES / NEED 8 SCRAP", Vector3(-20, 2.0, -8.0))

func _build_signs() -> void:
    _sign("VISIT FREE / BUY AT BANK MENU", Vector3(0, 2.0, 7.5))

func _build_lighting() -> void:
    var sun := DirectionalLight3D.new()
    sun.rotation_degrees = Vector3(-54, -28, 0)
    sun.light_energy = 0.93
    sun.shadow_enabled = false
    add_child(sun)
    var env_node := WorldEnvironment.new()
    var env := Environment.new()
    env.background_mode = Environment.BG_COLOR
    env.background_color = Color(0.13, 0.18, 0.19)
    env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
    env.ambient_light_color = Color(0.57, 0.62, 0.60)
    env.ambient_light_energy = 0.9
    env_node.environment = env
    add_child(env_node)

func _box(parent: Node3D, label: String, at: Vector3, dimensions: Vector3, tint: Color) -> StaticBody3D:
    var body := StaticBody3D.new()
    body.name = label
    body.position = at
    var collider := CollisionShape3D.new()
    collider.name = "CollisionShape3D"
    var box := BoxShape3D.new()
    box.size = dimensions
    collider.shape = box
    body.add_child(collider)
    var visual := MeshInstance3D.new()
    var box_mesh := BoxMesh.new()
    box_mesh.size = dimensions
    visual.mesh = box_mesh
    visual.material_override = _mat(tint)
    body.add_child(visual)
    parent.add_child(body)
    return body

func _visual(parent: Node3D, label: String, at: Vector3, dimensions: Vector3, tint: Color) -> void:
    var visual := MeshInstance3D.new()
    visual.name = label
    visual.position = at
    var box_mesh := BoxMesh.new()
    box_mesh.size = dimensions
    visual.mesh = box_mesh
    visual.material_override = _mat(tint)
    parent.add_child(visual)

func _mat(tint: Color) -> StandardMaterial3D:
    var material := StandardMaterial3D.new()
    material.albedo_color = tint
    material.roughness = 0.84
    return material

func _sign(message: String, at: Vector3) -> void:
    var label := Label3D.new()
    label.text = message
    label.name = "Sign"
    label.position = at
    label.font_size = 31
    label.pixel_size = 0.006
    label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
    label.no_depth_test = true
    add_child(label)
