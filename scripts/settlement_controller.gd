extends Node3D

const PLAYER_SCENE: PackedScene = preload("res://scenes/player.tscn")
const HUD_SCENE: PackedScene = preload("res://scenes/hud.tscn")
const MENU_PATH: String = "res://scenes/menu.tscn"
const POINTS: Dictionary = {
    "safehouse": Vector3(-11, 0, -6),
    "workshop": Vector3(12, 0, -9),
    "generator": Vector3(0, 0, -9),
    "barricades": Vector3(-20, 0, -8)
}

var player: FirstPersonPlayer
var _world: SettlementWorld
var _status: Label
var _prompt: Label
var _message: Label
var _nearest: String = ""

func _ready() -> void:
    _world = SettlementWorld.new()
    add_child(_world)
    player = PLAYER_SCENE.instantiate() as FirstPersonPlayer
    add_child(player)
    player.global_position = Vector3(0, 0.12, 19)
    var hud := HUD_SCENE.instantiate() as TouchHUD
    add_child(hud)
    hud.set_combat_controls_visible(false)
    hud.move_changed.connect(player.set_mobile_movement)
    hud.look_changed.connect(player.apply_touch_look)
    hud.jump_pressed.connect(player.request_jump)
    hud.sprint_changed.connect(player.set_mobile_sprinting)
    hud.use_pressed.connect(_interact)
    player.health_changed.connect(hud.set_health)
    hud.set_health(player.health, player.maximum_health)
    _build_interface()
    _refresh_status()

func _process(_delta: float) -> void:
    _nearest = ""
    var best: float = 3.3 * 3.3
    for key in POINTS.keys():
        var marker: Vector3 = POINTS[key]
        var flat_distance: Vector3 = player.global_position - marker
        flat_distance.y = 0
        if flat_distance.length_squared() < best:
            best = flat_distance.length_squared()
            _nearest = str(key)
    _prompt.text = "" if _nearest == "" else "USE / E: " + _interaction_label(_nearest)

func _unhandled_input(event: InputEvent) -> void:
    if event is InputEventKey and event.pressed and not event.echo and event.physical_keycode == KEY_E:
        _interact()

func _interaction_label(kind: String) -> String:
    match kind:
        "safehouse":
            return "INSPECT SAFEHOUSE"
        "workshop":
            return "COLLECT WORKSHOP RESOURCES"
        "generator":
            return "BUILD / INSPECT GENERATOR"
        "barricades":
            return "BUILD SAFEHOUSE BARRICADES"
    return "INTERACT"

func _interact() -> void:
    if _nearest == "":
        _notice("Walk to a labeled building or construction pad")
        return
    var state: Dictionary = SurvivalBank.load_bank()
    var owned: Array = state["owned"]
    match _nearest:
        "safehouse":
            if owned.has("safehouse"):
                _notice("SAFEHOUSE OWNED — the front doorway is unlocked. Walk inside!")
            else:
                _notice("PREVIEW ONLY — buy the 3000-point Safehouse Deed at the bank")
        "generator":
            if bool(state["generator_built"]):
                _notice("GENERATOR RUNNING — workshop power is available")
            elif not owned.has("generator"):
                _notice("Purchase the 2000-point Generator Blueprint in the bank")
            else:
                _show_result(SurvivalBank.build_generator())
        "workshop":
            if not owned.has("workshop"):
                _notice("Purchase the 5500-point Workshop License in the bank")
            elif not bool(state["generator_built"]):
                _notice("Workshop needs power — install the generator first")
            else:
                var result: Dictionary = SurvivalBank.collect_workshop_scrap()
                if bool(result.get("ok", false)):
                    _notice("WORKSHOP PRODUCED +%d SCRAP (TOTAL %d)" % [int(result.get("collected", 0)), int(result.get("scrap", 0))])
                else:
                    _show_result(result)
        "barricades":
            _show_result(SurvivalBank.construct_barricades())
    _world.refresh_state()
    _refresh_status()

func _show_result(result: Dictionary) -> void:
    if bool(result.get("ok", false)):
        _notice(str(result.get("message", "Saved successfully")))
    else:
        _notice(str(result.get("error", "Action unavailable")))

func _notice(message: String) -> void:
    _message.text = message

func _refresh_status() -> void:
    var data: Dictionary = SurvivalBank.load_bank()
    var owned: Array = data["owned"]
    _status.text = "SETTLEMENT • BANK %d • SCRAP %d\nDEED: %s   WORKSHOP: %s   GENERATOR: %s" % [
        int(data["balance"]), int(data["scrap"]),
        "OWNED" if owned.has("safehouse") else "LOCKED",
        "OWNED" if owned.has("workshop") else "LOCKED",
        "BUILT" if bool(data["generator_built"]) else "NOT BUILT"
    ]

func _build_interface() -> void:
    var layer := CanvasLayer.new()
    layer.layer = 2
    add_child(layer)
    var overlay := Control.new()
    overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
    layer.add_child(overlay)
    var backdrop := ColorRect.new()
    backdrop.position = Vector2(10, 82)
    backdrop.size = Vector2(700, 67)
    backdrop.color = Color(0.02, 0.04, 0.04, 0.72)
    backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
    overlay.add_child(backdrop)
    _status = Label.new()
    _status.position = Vector2(18, 86)
    _status.add_theme_font_size_override("font_size", 15)
    overlay.add_child(_status)
    _prompt = Label.new()
    _prompt.position = Vector2(175, 167)
    _prompt.size = Vector2(620, 42)
    _prompt.add_theme_font_size_override("font_size", 18)
    _prompt.add_theme_color_override("font_color", Color(1, 0.89, 0.56))
    overlay.add_child(_prompt)
    _message = Label.new()
    _message.position = Vector2(175, 207)
    _message.size = Vector2(650, 66)
    _message.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    _message.add_theme_font_size_override("font_size", 17)
    overlay.add_child(_message)
    var exit_button := Button.new()
    exit_button.text = "BANK / MENU"
    exit_button.position = Vector2(750, 10)
    exit_button.size = Vector2(193, 48)
    exit_button.pressed.connect(func(): get_tree().change_scene_to_file(MENU_PATH))
    overlay.add_child(exit_button)
    _notice("Preview buildings before purchase. Safehouse opens with deed; workshop needs generator power.")
