extends Control

const MENU: String = "res://scenes/menu.tscn"
const DISTRICT: String = "res://scenes/district.tscn"

var _grid: GridContainer
var _details: Label
var _resources: Label
var _status: Label

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var bg := ColorRect.new()
	bg.color = Color(0.055, 0.075, 0.075)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)
	var scroll := ScrollContainer.new()
	scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(scroll)
	var content := VBoxContainer.new()
	content.custom_minimum_size = Vector2(890, 0)
	content.add_theme_constant_override("separation", 8)
	scroll.add_child(content)
	var title := Label.new()
	title.text = "THE NEXT INFECTION  |  FLORIDA DISTRICTS"
	title.add_theme_font_size_override("font_size", 24)
	content.add_child(title)
	var subtitle := Label.new()
	subtitle.text = "ORLANDO (CYPRESS HAVEN)  —  I-4 CORRIDOR  —  TAMPA (BAYFRONT YARDS)"
	content.add_child(subtitle)
	_resources = Label.new()
	content.add_child(_resources)
	var regions := HBoxContainer.new()
	content.add_child(regions)
	for id in ["orlando", "tampa"]:
		var button := Button.new()
		button.text = WorldProgress.REGIONS[id]
		button.custom_minimum_size = Vector2(260, 45)
		button.pressed.connect(_select_region.bind(id))
		regions.add_child(button)
	var note := Label.new()
	note.text = "16 SQUARE SECTORS PER REGION. Offline plot ownership only; PvP territory capture is not live."
	content.add_child(note)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 18)
	content.add_child(row)
	_grid = GridContainer.new()
	_grid.columns = 4
	row.add_child(_grid)
	var info := VBoxContainer.new()
	info.custom_minimum_size.x = 300
	row.add_child(info)
	_details = Label.new()
	_details.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_details.custom_minimum_size = Vector2(300, 75)
	info.add_child(_details)
	for pair in [["CLAIM PLOT — 10 FAB TOKENS", "claim"], ["BUILD GENERATOR — 3 FAB", "generator"], ["BUILD WORKSHOP — 4 FAB", "workshop"], ["BUILD WATCHTOWER — 5 FAB", "watchtower"], ["BUILD SUPPLY CACHE — 2 FAB", "supply_cache"], ["COLLECT PASSIVE FABRICATION", "collect"]]:
		var action := Button.new()
		action.text = str(pair[0])
		action.custom_minimum_size.y = 39
		action.pressed.connect(_action.bind(str(pair[1])))
		info.add_child(action)
	_status = Label.new()
	_status.custom_minimum_size.y = 34
	_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(_status)
	var travel := Button.new()
	travel.text = "TRAVEL TO SELECTED SQUARE PLOT (3D)"
	travel.custom_minimum_size.y = 48
	travel.pressed.connect(func(): get_tree().change_scene_to_file(DISTRICT))
	content.add_child(travel)
	var roam := Button.new()
	roam.text = "ENTER OPEN WORLD — DRIVE / MISSIONS / ZOMBIES"
	roam.custom_minimum_size.y = 48
	roam.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/open_world.tscn"))
	content.add_child(roam)
	var back := Button.new()
	back.text = "BACK TO HOME MENU"
	back.pressed.connect(func(): get_tree().change_scene_to_file(MENU))
	content.add_child(back)
	_refresh()

func _select_region(id: String) -> void:
	var prefix: String = "O-" if id == "orlando" else "T-"
	WorldProgress.select_plot(id, prefix + "01")
	_refresh()

func _select_plot(id: String) -> void:
	var state: Dictionary = WorldProgress.load_data()
	WorldProgress.select_plot(str(state["region"]), id)
	_refresh()

func _action(kind: String) -> void:
	var response: Dictionary = {}
	match kind:
		"claim":
			response = WorldProgress.claim_plot()
		"collect":
			response = WorldProgress.claim_production()
		_:
			response = WorldProgress.build(kind)
	_status.text = str(response.get("message", "Action unavailable"))
	_refresh(false)

func _refresh(reset_message: bool = true) -> void:
	var d: Dictionary = WorldProgress.load_data()
	_resources.text = "FABRICATION TOKENS %d  |  GUN PARTS %d  |  OWNED PLOTS %d" % [int(d["fabrication_tokens"]), int(d["gun_parts"]), (d["plots"] as Dictionary).size()]
	for child in _grid.get_children():
		child.queue_free()
	var prefix: String = "O-" if str(d["region"]) == "orlando" else "T-"
	var plots: Dictionary = d["plots"]
	for i in range(16):
		var plot: String = "%s%02d" % [prefix, i + 1]
		var button := Button.new()
		button.custom_minimum_size = Vector2(105, 60)
		button.text = "%s%s\n%s" % ["> " if plot == str(d["plot"]) else "", plot, "OWNED" if plots.has(plot) else "UNCLAIMED"]
		button.pressed.connect(_select_plot.bind(plot))
		_grid.add_child(button)
	var current: String = str(d["plot"])
	var owned: bool = plots.has(current)
	_details.text = "%s\nSELECTED PLOT: %s\n%s\nSTRUCTURES: %s" % [WorldProgress.REGIONS[str(d["region"])], current, "YOUR PROPERTY" if owned else "UNCLAIMED", str(plots[current]) if owned else "None"]
	if reset_message:
		_status.text = "Your selection sets the 3D travel destination. Salvage each plot in person, then build on owned land; production requires generator + workshop."
