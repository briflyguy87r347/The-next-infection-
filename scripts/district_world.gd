class_name DistrictWorld
extends Node3D

# Original, square-sector neighborhood prototype. This is not real-world geospatial data.
# Offline plots only; server-authoritative faction control comes later.
const ASPHALT: Texture2D = preload("res://assets/world/asphalt.png")
const CONCRETE: Texture2D = preload("res://assets/world/weathered_concrete.png")

var region: String = "orlando"
var _preview: MeshInstance3D

static func plot_center(plot_id: String) -> Vector3:
    var index: int = maxi(0, int(plot_id.substr(2)) - 1)
    return Vector3((float(index % 4) - 1.5) * 22.0, 0.0, (float(index / 4) - 1.5) * 22.0)

static func build_slot_position(slot: int) -> Vector3:
    match slot:
        0: return Vector3(-7, 0, 4.8)
        1: return Vector3(7, 0, 4.8)
        2: return Vector3(-7, 0, -4.9)
        _: return Vector3(7, 0, -4.9)

func refresh_plot(plot_id: String) -> void:
    var existing := get_node_or_null("Plot_" + plot_id)
    if existing != null:
        remove_child(existing)
        existing.queue_free()
    _build_plot(plot_id, plot_center(plot_id), WorldProgress.load_data()["plots"])

func preview_build(plot_id: String, slot: int, kind: String) -> void:
    if _preview != null:
        _preview.queue_free()
        _preview = null
    if kind.is_empty():
        return
    _preview = MeshInstance3D.new()
    _preview.name = "BlueprintPlacementPreview"
    var mesh := BoxMesh.new()
    mesh.size = Vector3(2.1,1.6,2.1)
    _preview.mesh = mesh
    var material := StandardMaterial3D.new()
    material.albedo_color = Color(0.15,0.85,0.75,0.38)
    material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
    material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
    _preview.material_override = material
    _preview.position = plot_center(plot_id) + build_slot_position(slot) + Vector3.UP * 0.8
    add_child(_preview)


func _ready() -> void:
    region = str(WorldProgress.load_data()["region"])
    _name_and_ground()
    var state: Dictionary = WorldProgress.load_data()
    var owned: Dictionary = state["plots"]
    var prefix: String = "O-" if region == "orlando" else "T-"
    for row in range(4):
        for col in range(4):
            var id: String = "%s%02d" % [prefix, row * 4 + col + 1]
            _build_plot(id, plot_center(id), owned)
    _build_street_props()
    var sun := DirectionalLight3D.new()
    sun.rotation_degrees = Vector3(-48, -40, 0)
    sun.shadow_enabled = false
    add_child(sun)

func _name_and_ground() -> void:
    name = "OrlandoSector" if region == "orlando" else "TampaSector"
    _box(self, "FloridaDistrictGround", Vector3(0, -0.58, 0), Vector3(104, 1.1, 104), Color(0.20,0.26,0.18) if region == "orlando" else Color(0.25,0.28,0.29), true)
    for n in range(5):
        var offset: float = (float(n) - 2.0) * 22.0
        _box(self, "NorthSouthStreet", Vector3(offset, 0.02, 0), Vector3(4.2, 0.04, 104), Color(0.13,0.15,0.16), false)
        _box(self, "EastWestStreet", Vector3(0, 0.04, offset), Vector3(104, 0.04, 4.2), Color(0.13,0.15,0.16), false)
    var banner := Label3D.new()
    banner.text = "CYPRESS HAVEN / ORLANDO" if region == "orlando" else "BAYFRONT YARDS / TAMPA"
    banner.position = Vector3(0, 5, 48)
    banner.font_size = 40
    banner.pixel_size = 0.012
    banner.billboard = BaseMaterial3D.BILLBOARD_ENABLED
    banner.no_depth_test = true
    add_child(banner)

func _build_plot(id: String, at: Vector3, owned: Dictionary) -> void:
    var lot := Node3D.new()
    lot.name = "Plot_" + id
    lot.position = at
    add_child(lot)
    var is_owned: bool = owned.has(id)
    var block_color: Color = Color(0.28,0.44,0.33) if is_owned else Color(0.37,0.36,0.28)
    _box(lot,"Parcel",Vector3(0,0.02,0),Vector3(17.5,0.10,17.5),block_color,false)
    # Distinct silhouettes: Florida townhomes, industrial repair yards and shops.
    var part: int = int(id.substr(2))
    var industrial: bool = region == "tampa" or part % 4 == 0
    var walls: Color = Color(0.42,0.45,0.43) if industrial else Color(0.59,0.51,0.41)
    var depth: float = 8.0 if industrial else 9.5
    var height: float = 3.5 if industrial else 4.1
    _box(lot,"Floor",Vector3(0,0.15,0),Vector3(11.5,0.25,depth),Color(0.31,0.30,0.28),true)
    _box(lot,"RearWall",Vector3(0,height*0.5,-depth*0.5),Vector3(11.5,height,0.27),walls,true)
    _box(lot,"LeftWall",Vector3(-5.75,height*0.5,0),Vector3(0.27,height,depth),walls,true)
    _box(lot,"RightWall",Vector3(5.75,height*0.5,0),Vector3(0.27,height,depth),walls,true)
    _box(lot,"FrontWingLeft",Vector3(-4.15,height*0.5,depth*0.5),Vector3(3.1,height,0.27),walls,true)
    _box(lot,"FrontWingRight",Vector3(4.15,height*0.5,depth*0.5),Vector3(3.1,height,0.27),walls,true)
    _box(lot,"DoorLintel",Vector3(0,height-0.43,depth*0.5),Vector3(5.2,0.86,0.27),walls,true)
    _box(lot,"Roof",Vector3(0,height,0),Vector3(11.8,0.31,depth+0.4),Color(0.15,0.18,0.18),true)
    if not industrial:
        _box(lot,"Porch",Vector3(0,0.07,depth*0.5+2.1),Vector3(7.1,0.14,3.0),Color(0.42,0.41,0.38),true)
    else:
        _box(lot,"CargoContainer",Vector3(6.2,1.05,-6.3),Vector3(2.4,2.1,4.2),Color(0.31,0.35,0.39),true)
    var sign := Label3D.new()
    sign.text = "%s  /  %s" % [id, "OWNED" if is_owned else "UNCLAIMED"]
    sign.position = Vector3(0,2.5,9)
    sign.font_size = 32
    sign.pixel_size = 0.01
    sign.billboard = BaseMaterial3D.BILLBOARD_ENABLED
    sign.no_depth_test = true
    lot.add_child(sign)
    # Site marker makes each plot useful for scavenging and on-site construction.
    _box(lot, "SalvagePile", Vector3(0,0.32,9.5), Vector3(1.4,0.64,0.9), Color(0.42,0.48,0.44), false)
    if is_owned:
        var saved: Dictionary = WorldProgress.load_data().get("placements", {}).get(id, {})
        _build_structures(lot, owned[id], saved)

func _build_structures(lot: Node3D, structures: Array, saved_slots: Dictionary) -> void:
    var index: int = 0
    for kind_variant in structures:
        var kind: String = str(kind_variant)
        var slot: int = int(saved_slots.get(kind, index))
        slot = clampi(slot,0,3)
        var pos: Vector3 = build_slot_position(slot)
        match kind:
            "generator":
                _box(lot,"GeneratorBase",pos + Vector3(0,0.6,0),Vector3(2.2,1.2,1.7),Color(0.11,0.43,0.26),true)
                _box(lot,"GeneratorVent",pos + Vector3(0,1.35,0),Vector3(1.2,0.3,1.2),Color(0.23,0.25,0.22),false)
            "workshop":
                _box(lot,"WorkshopPlatform",pos + Vector3(0,0.24,0),Vector3(3.0,0.4,2.2),Color(0.23,0.24,0.24),true)
                _box(lot,"WorkshopBench",pos + Vector3(0,0.93,0),Vector3(2.6,0.3,0.9),Color(0.43,0.30,0.19),true)
                _box(lot,"WorkshopShelter",pos + Vector3(0,2.3,0),Vector3(3.2,0.25,2.5),Color(0.24,0.27,0.29),false)
            "watchtower":
                for x in [-0.95,0.95]:
                    for z in [-0.8,0.8]:
                        _box(lot,"WatchtowerPost",pos + Vector3(x,1.6,z),Vector3(0.18,3.2,0.18),Color(0.27,0.22,0.18),true)
                _box(lot,"WatchtowerDeck",pos + Vector3(0,3.35,0),Vector3(2.6,0.24,2.4),Color(0.29,0.28,0.24),true)
            "supply_cache":
                _box(lot,"SupplyStorage",pos + Vector3(0,0.6,0),Vector3(2.1,1.2,1.5),Color(0.34,0.39,0.20),true)
        var label := Label3D.new()
        label.text = kind.replace("_", " ").to_upper() + "  /  SLOT %d" % (slot+1)
        label.position = pos + Vector3(0,2.6 if kind != "watchtower" else 4.1,0)
        label.font_size = 26
        label.pixel_size = 0.008
        label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
        label.no_depth_test = true
        lot.add_child(label)
        index += 1

func _build_street_props() -> void:
    # Lightweight landmarks to distinguish the two Florida-inspired districts.
    for i in range(8):
        var z: float = -38.0 + float(i) * 11.0
        var x: float = -38.0 if i % 2 == 0 else 38.0
        if region == "orlando":
            _tree(Vector3(x, 0.0, z), i)
        else:
            _box(self, "SalvageCrate", Vector3(x,0.62,z), Vector3(1.4,1.24,1.3), Color(0.36,0.33,0.25), true)
    for i in range(6):
        var x: float = -33.0 + float(i) * 13.0
        var position_z: float = 12.5 if i % 2 == 0 else -12.5
        _vehicle(Vector3(x, 0.0, position_z), i)
    for i in range(6):
        var pos_x: float = -42.0 + float(i) * 16.0
        _box(self,"RoadMarker",Vector3(pos_x,0.07,11.0),Vector3(1.7,0.025,0.11),Color(0.82,0.79,0.52),false)

func _tree(at: Vector3, index: int) -> void:
    _box(self,"TreeTrunk",at + Vector3(0,1.25,0),Vector3(0.45,2.5,0.45),Color(0.35,0.27,0.16),true)
    var cap := MeshInstance3D.new()
    cap.name = "TreeCanopy"
    var mesh := SphereMesh.new()
    mesh.radius = 1.65
    mesh.height = 3.2
    cap.mesh = mesh
    cap.position = at + Vector3(0,3.15,0)
    var mat := StandardMaterial3D.new()
    mat.albedo_color = Color(0.14,0.27,0.15) if index % 2 == 0 else Color(0.20,0.29,0.13)
    mat.roughness = 1.0
    cap.material_override = mat
    add_child(cap)

func _vehicle(at: Vector3, index: int) -> void:
    var colors: Array[Color] = [Color(0.23,0.27,0.29),Color(0.39,0.29,0.20),Color(0.24,0.35,0.34)]
    var tint: Color = colors[index % colors.size()]
    _box(self,"AbandonedVehicle",at + Vector3(0,0.55,0),Vector3(2.1,0.9,4.4),tint,true)
    _box(self,"VehicleRoof",at + Vector3(0,1.32,-0.2),Vector3(1.7,0.72,2.25),tint.darkened(0.16),true)
    for side in [-1.0,1.0]:
        for z in [-1.45,1.45]:
            var wheel := MeshInstance3D.new()
            var w := CylinderMesh.new()
            w.top_radius = 0.37
            w.bottom_radius = 0.37
            w.height = 0.21
            wheel.mesh = w
            wheel.rotation.z = PI / 2.0
            wheel.position = at + Vector3(side * 1.02,0.39,z)
            var rubber := StandardMaterial3D.new()
            rubber.albedo_color = Color(0.05,0.055,0.06)
            wheel.material_override = rubber
            add_child(wheel)


func _box(parent: Node3D, label: String, at: Vector3, dimensions: Vector3, tint: Color, solid: bool) -> void:
    var mesh := BoxMesh.new()
    mesh.size = dimensions
    var visual := MeshInstance3D.new()
    visual.name = label
    visual.mesh = mesh
    var material := StandardMaterial3D.new()
    material.albedo_color = tint
    material.roughness = 0.92
    if label.contains("Street"):
        material.albedo_texture = ASPHALT
        material.uv1_scale = Vector3(8,8,1)
    elif label in ["RearWall", "LeftWall", "RightWall", "FrontWingLeft", "FrontWingRight", "Home", "Warehouse"]:
        material.albedo_texture = CONCRETE
        material.uv1_scale = Vector3(2,2,1)
    visual.material_override = material
    if solid:
        var body := StaticBody3D.new()
        body.name = label + "Collider"
        body.position = at
        var collider := CollisionShape3D.new()
        var box := BoxShape3D.new()
        box.size = dimensions
        collider.shape = box
        body.add_child(collider)
        body.add_child(visual)
        parent.add_child(body)
    else:
        visual.position = at
        parent.add_child(visual)
