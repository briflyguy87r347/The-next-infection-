extends Control

# Responsive main hub: spend bank credits outside matches, and choose the mode.
var _balance_label: Label
var _message_label: Label
var _items: VBoxContainer

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var backdrop := ColorRect.new()
	backdrop.color = Color(0.045,0.065,0.065)
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(backdrop)
	var scroll := ScrollContainer.new()
	scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(scroll)
	var center := CenterContainer.new()
	center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(center)
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(680, 0)
	center.add_child(panel)
	var padding := MarginContainer.new()
	padding.add_theme_constant_override("margin_left",18)
	padding.add_theme_constant_override("margin_right",18)
	padding.add_theme_constant_override("margin_top",15)
	padding.add_theme_constant_override("margin_bottom",15)
	panel.add_child(padding)
	var main := VBoxContainer.new()
	main.add_theme_constant_override("separation",8)
	padding.add_child(main)
	var heading := Label.new()
	heading.text = "THE NEXT INFECTION — MODULE 010 / FLORIDA OUTBREAK"
	heading.add_theme_font_size_override("font_size",21)
	main.add_child(heading)
	var hint := Label.new()
	hint.text = "MATCH CASH RESETS TO 0. BANK IS PERMANENT AND CANNOT BE USED IN SURVIVAL."
	hint.add_theme_font_size_override("font_size",13)
	main.add_child(hint)
	_balance_label = Label.new()
	main.add_child(_balance_label)
	_add_nav(main, "SURVIVAL ARENA — START NEW RUN", "res://scenes/main.tscn")
	_add_nav(main, "FLORIDA OPEN WORLD — EXPLORE / DRIVE / MISSIONS", "res://scenes/open_world.tscn")
	_add_nav(main, "FLORIDA DISTRICTS — TRAVEL / SALVAGE / BUILD", "res://scenes/world_map.tscn")
	_add_nav(main, "GUNSMITH — CRAFT, UPGRADE AND EQUIP THREE GUNS", "res://scenes/arsenal.tscn")
	_add_nav(main, "VISIT ORIGINAL SETTLEMENT — SAFEHOUSE & WORKSHOP", "res://scenes/settlement.tscn")
	_add_nav(main, "WORLD SAVE BACKUP & RESTORE", "res://scenes/save_manager.tscn")
	var title := Label.new()
	title.text = "PERMANENT BANK PURCHASES — WORLD ONLY"
	main.add_child(title)
	_items = VBoxContainer.new()
	main.add_child(_items)
	_message_label = Label.new()
	_message_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	main.add_child(_message_label)
	_refresh()

func _add_nav(parent: VBoxContainer, label: String, destination: String) -> void:
	var button := Button.new()
	button.text = label
	button.custom_minimum_size.y = 48
	button.pressed.connect(func(): get_tree().change_scene_to_file(destination))
	parent.add_child(button)

func _refresh() -> void:
	var data: Dictionary = SurvivalBank.load_bank()
	var world: Dictionary = WorldProgress.load_data()
	_balance_label.text = "BANK %d  |  RUNS %d  |  BEST %d  |  FAB %d  |  GUN PARTS %d" % [
		int(data["balance"]),int(data["runs_completed"]),int(data["best_round"]),
		int(world["fabrication_tokens"]),int(world["gun_parts"])]
	for child in _items.get_children():
		child.queue_free()
	for item in SurvivalBank.STORE:
		var id: String = str(item["id"])
		var owned: bool = (data["owned"] as Array).has(id)
		var button := Button.new()
		button.text = "%s — %s" % [str(item["name"]), "OWNED" if owned else "%d BANK" % int(item["cost"])]
		button.tooltip_text = str(item["detail"])
		button.disabled = owned or data.has("read_error")
		button.pressed.connect(_buy.bind(id))
		_items.add_child(button)
	_message_label.text = "Starter plot O-01 is yours. Your 3-slot arsenal and permanent gun upgrades are saved at Gunsmith. Use the ARMORY near your Orlando safehouse. Salvaged parts/FAB save immediately; match coins bank on death or extraction."

func _buy(id: String) -> void:
	var result: Dictionary = SurvivalBank.buy(id)
	_refresh()
	_message_label.text = "PURCHASE UNLOCKED — Visit Florida Open World / collect workshop FAB" if bool(result.get("ok", false)) else str(result.get("error", "Purchase failed"))
