extends Control

# Module 010: persistent three-weapon Gunsmith (save-compatible with Module 009).
# Purchased / crafted weapons are permanent; Mystery Box rolls are match-only.
var _list: VBoxContainer
var _message: Label
var _resource: Label

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var background := ColorRect.new()
	background.color = Color(0.045,0.065,0.075)
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background)
	var scroll := ScrollContainer.new()
	scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(scroll)
	var body := VBoxContainer.new()
	body.custom_minimum_size = Vector2(825.0, 0.0)
	body.add_theme_constant_override("separation", 10)
	scroll.add_child(body)
	var heading := Label.new()
	heading.text = "GUNSMITH  /  THREE PERMANENT WEAPON SLOTS"
	heading.add_theme_font_size_override("font_size", 24)
	body.add_child(heading)
	var guide := Label.new()
	guide.text = "CRAFT WITH PARTS + FAB   |   EQUIP ANY OWNED GUN TO SLOT 1, 2 OR 3.\nSLOT 2 STARTS WITH THE SERVICE PISTOL. Weapons stay yours after death."
	guide.add_theme_font_size_override("font_size", 14)
	body.add_child(guide)
	_resource = Label.new()
	body.add_child(_resource)
	_list = VBoxContainer.new()
	_list.add_theme_constant_override("separation", 8)
	body.add_child(_list)
	_message = Label.new()
	_message.custom_minimum_size.y = 48
	body.add_child(_message)
	var back_row := HBoxContainer.new()
	body.add_child(back_row)
	_button(back_row, "BACK TO MENU", func(): get_tree().change_scene_to_file("res://scenes/menu.tscn"))
	_button(back_row, "ENTER OPEN WORLD", func(): get_tree().change_scene_to_file("res://scenes/open_world.tscn"))
	_refresh()

func _button(parent: Node, caption: String, callback: Callable) -> Button:
	var b := Button.new()
	b.text = caption
	b.custom_minimum_size = Vector2(139, 43)
	b.pressed.connect(callback)
	parent.add_child(b)
	return b

func _refresh() -> void:
	var d: Dictionary = WorldProgress.load_data()
	if d.has("read_error"):
		_resource.text = "SAVE ERROR: EQUIPMENT CHANGES DISABLED."
		return
	var slots: Array = d["weapon_slots"]
	_resource.text = "GUN PARTS %d  |  FAB %d    /    LOADOUT:  [1] %s   [2] %s   [3] %s" % [
		int(d["gun_parts"]), int(d["fabrication_tokens"]),
		str(slots[0]).to_upper() if str(slots[0]) != "" else "EMPTY",
		str(slots[1]).to_upper() if str(slots[1]) != "" else "EMPTY",
		str(slots[2]).to_upper() if str(slots[2]) != "" else "EMPTY"]
	for child in _list.get_children():
		_list.remove_child(child)
		child.queue_free()
	for id in ["pistol", "smg", "shotgun", "rifle", "lmg"]:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 5)
		_list.add_child(row)
		var owned: bool = (d["owned_weapons"] as Array).has(id)
		var name: String = "SERVICE PISTOL" if id == "pistol" else str(WorldProgress.RECIPES[id]["name"])
		var label := Label.new()
		label.custom_minimum_size = Vector2(175, 44)
		label.text = "%s  /  %s" % [name, "OWNED" if owned else "LOCKED"]
		row.add_child(label)
		if owned:
			var level: int = int((d.get("weapon_upgrades", {}) as Dictionary).get(id,0))
			label.text = "%s  /  LVL %d" % [name,level]
			for slot in range(3):
				var label_text: String = "SLOT %d %s" % [slot + 1, "✓" if str(slots[slot]) == id else "EQUIP"]
				var button := _button(row, label_text, _assign.bind(slot, id))
				button.disabled = str(slots[slot]) == id
			var upgrade := _button(row, "UPGRADE" if level < 3 else "MAXED", _upgrade.bind(id))
			upgrade.disabled = level >= 3
		else:
			var recipe: Dictionary = WorldProgress.RECIPES[id]
			_button(row, "CRAFT: %d PARTS + %d FAB" % [int(recipe["parts"]), int(recipe["tokens"])], _craft.bind(id))
	var empty_row := HBoxContainer.new()
	_list.add_child(empty_row)
	for slot in range(3):
		_button(empty_row, "CLEAR SLOT %d" % [slot + 1], _assign.bind(slot, ""))

func _craft(id: String) -> void:
	var result: Dictionary = WorldProgress.craft_gun(id)
	_refresh()
	_message.text = str(result.get("message", "Craft failed"))

func _assign(slot: int, id: String) -> void:
	var result: Dictionary = WorldProgress.assign_weapon_slot(slot, id)
	_refresh()
	_message.text = str(result.get("message", "Equip failed"))

func _upgrade(id: String) -> void:
	var result: Dictionary = WorldProgress.upgrade_owned_gun(id)
	_refresh()
	_message.text = str(result.get("message", "Upgrade failed"))
