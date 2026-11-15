extends Node3D

# Module 009: playable on-site actions in two original Florida-inspired districts.
# Ownership remains OFFLINE and is not a multiplayer land claim.
const PLAYER: PackedScene = preload("res://scenes/player.tscn")
const HUD: PackedScene = preload("res://scenes/hud.tscn")
const MAP: String = "res://scenes/world_map.tscn"

var _player: FirstPersonPlayer
var _world: DistrictWorld
var _message: Label
var _resources: Label
var _nearest_label: Label
var _selected: String = ""
var _build_panel: PanelContainer
var _build_text: Label
var _selected_kind: String = "generator"
var _slot: int = 0
var _build_open: bool = false

func _ready() -> void:
    _world = DistrictWorld.new()
    add_child(_world)
    var state: Dictionary = WorldProgress.load_data()
    _selected = str(state["plot"])
    _player = PLAYER.instantiate() as FirstPersonPlayer
    add_child(_player)
    _player.global_position = DistrictWorld.plot_center(_selected) + Vector3(0,0.15,12.0)
    var hud := HUD.instantiate() as TouchHUD
    add_child(hud)
    hud.set_combat_controls_visible(false)
    hud.move_changed.connect(_player.set_mobile_movement)
    hud.look_changed.connect(_player.apply_touch_look)
    hud.jump_pressed.connect(_player.request_jump)
    hud.sprint_changed.connect(_player.set_mobile_sprinting)
    hud.use_pressed.connect(_interact)
    _player.health_changed.connect(hud.set_health)
    hud.set_health(_player.health, _player.maximum_health)
    _make_overlay()
    _refresh()

func _process(_delta: float) -> void:
    if _build_open:
        return
    var nearby: String = ""
    var nearest_distance: float = 5.0 * 5.0
    var current_region: String = str(WorldProgress.load_data()["region"])
    var prefix: String = "O-" if current_region == "orlando" else "T-"
    for i in range(1,17):
        var plot_id: String = "%s%02d" % [prefix,i]
        var center: Vector3 = DistrictWorld.plot_center(plot_id) + Vector3(0,0,9.5)
        var dist: float = _player.global_position.distance_squared_to(center)
        if dist < nearest_distance:
            nearest_distance = dist
            nearby = plot_id
    if _selected != nearby and not nearby.is_empty():
        _selected = nearby
        WorldProgress.select_plot(current_region,_selected)
        _refresh()
    _nearest_label.text = "WALK TO A PLOT'S FRONT SALVAGE PILE • USE TO SALVAGE | BUILD FOR CONSTRUCTION" if nearby.is_empty() else "PLOT %s: USE TO SALVAGE • BUILD TO CONSTRUCT" % nearby

func _unhandled_input(event: InputEvent) -> void:
    if event is InputEventKey and event.pressed and not event.echo and event.physical_keycode == KEY_E:
        _interact()

func _make_overlay() -> void:
    var canvas := CanvasLayer.new()
    canvas.layer = 5
    add_child(canvas)
    var bar := HBoxContainer.new()
    bar.position = Vector2(12,6)
    bar.add_theme_constant_override("separation",8)
    canvas.add_child(bar)
    _resources = Label.new()
    _resources.custom_minimum_size.x = 420
    _resources.add_theme_font_size_override("font_size",15)
    bar.add_child(_resources)
    var build_button := Button.new()
    build_button.text = "BUILD / INSPECT"
    build_button.custom_minimum_size = Vector2(160,42)
    build_button.pressed.connect(_toggle_build)
    bar.add_child(build_button)
    var production := Button.new()
    production.text = "COLLECT FAB"
    production.custom_minimum_size = Vector2(134,42)
    production.pressed.connect(_claim_production)
    bar.add_child(production)
    var back := Button.new()
    back.text = "FLORIDA MAP"
    back.custom_minimum_size = Vector2(140,42)
    back.pressed.connect(func(): get_tree().change_scene_to_file(MAP))
    bar.add_child(back)
    _nearest_label = Label.new()
    _nearest_label.position = Vector2(14,55)
    _nearest_label.size = Vector2(925,27)
    _nearest_label.add_theme_font_size_override("font_size",14)
    canvas.add_child(_nearest_label)
    _message = Label.new()
    _message.position = Vector2(14,90)
    _message.size = Vector2(900,62)
    _message.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    _message.add_theme_font_size_override("font_size",15)
    canvas.add_child(_message)
    _build_panel = PanelContainer.new()
    _build_panel.visible = false
    _build_panel.position = Vector2(170,110)
    _build_panel.custom_minimum_size = Vector2(610,360)
    canvas.add_child(_build_panel)
    var body := VBoxContainer.new()
    body.add_theme_constant_override("separation",5)
    _build_panel.add_child(body)
    _build_text = Label.new()
    _build_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    body.add_child(_build_text)
    var claim := Button.new()
    claim.text = "CLAIM SELECTED PLOT (10 FAB)"
    claim.pressed.connect(_claim_plot)
    body.add_child(claim)
    var kinds := HBoxContainer.new()
    body.add_child(kinds)
    for kind in ["generator","workshop","watchtower","supply_cache"]:
        var button := Button.new()
        button.text = kind.replace("_", " ").to_upper()
        button.pressed.connect(_select_kind.bind(kind))
        kinds.add_child(button)
    var slots := HBoxContainer.new()
    body.add_child(slots)
    for index in range(4):
        var button := Button.new()
        button.text = "SLOT %d" % [index+1]
        button.custom_minimum_size.x = 125
        button.pressed.connect(_select_slot.bind(index))
        slots.add_child(button)
    var construct := Button.new()
    construct.text = "CONFIRM BUILD • SAVE TO THIS PLOT"
    construct.pressed.connect(_build)
    body.add_child(construct)
    var close := Button.new()
    close.text = "CLOSE / RETURN TO EXPLORATION"
    close.pressed.connect(_toggle_build)
    body.add_child(close)

func _refresh() -> void:
    var data: Dictionary = WorldProgress.load_data()
    var plots: Dictionary = data["plots"]
    _resources.text = "%s   PARTS %d   FAB %d   PLOTS %d" % [str(data["region"]).to_upper(), int(data["gun_parts"]),int(data["fabrication_tokens"]),plots.size()]
    var owned: bool = plots.has(_selected)
    var structures: String = str(plots[_selected]) if owned else "None"
    _build_text.text = "%s | %s\nOWNED: %s | STRUCTURES: %s\nSELECT BLUEPRINT AND SLOT. A TRANSLUCENT CUBE MARKS THE SPOT." % [str(data["region"]).to_upper(),_selected,str(owned),structures]

func _interact() -> void:
    if _build_open:
        return
    var region: String = str(WorldProgress.load_data()["region"])
    var current: String = str(WorldProgress.load_data()["plot"])
    var distance: float = _player.global_position.distance_to(DistrictWorld.plot_center(current) + Vector3(0,0,9.5))
    if distance > 5.0:
        _message.text = "Walk near a plot's front salvage pile to scavenge."
        return
    var result: Dictionary = WorldProgress.salvage_site(region,current)
    _message.text = str(result.get("message", "Salvage unavailable"))
    _refresh()

func _toggle_build() -> void:
    _build_open = not _build_open
    _build_panel.visible = _build_open
    if _build_open:
        var region: String = str(WorldProgress.load_data()["region"])
        var closest: float = 999999.0
        var prefix: String = "O-" if region == "orlando" else "T-"
        for n in range(1,17):
            var id: String = "%s%02d" % [prefix,n]
            var distance: float = DistrictWorld.plot_center(id).distance_squared_to(_player.global_position)
            if distance < closest:
                closest = distance
                _selected = id
        WorldProgress.select_plot(region,_selected)
        _update_preview()
    else:
        _world.preview_build(_selected,_slot,"")
    _refresh()

func _select_kind(kind: String) -> void:
    _selected_kind = kind
    _update_preview()

func _select_slot(index: int) -> void:
    _slot = index
    _update_preview()

func _update_preview() -> void:
    _world.preview_build(_selected,_slot,_selected_kind)
    _refresh()
    _build_text.text += "\nPREVIEW: %s / SLOT %d | COST %d FAB" % [_selected_kind.to_upper(),_slot+1,int(WorldProgress.BUILDINGS[_selected_kind]["tokens"])]

func _claim_plot() -> void:
    var response: Dictionary = WorldProgress.claim_plot()
    _message.text = str(response.get("message", "Claim failed"))
    _refresh()

func _build() -> void:
    var response: Dictionary = WorldProgress.build_at(_selected_kind,_slot)
    _message.text = str(response.get("message", "Construction failed"))
    if bool(response.get("ok",false)):
        _world.refresh_plot(_selected)
    _refresh()

func _claim_production() -> void:
    var response: Dictionary = WorldProgress.claim_production()
    _message.text = str(response.get("message", "Production unavailable"))
    _refresh()
