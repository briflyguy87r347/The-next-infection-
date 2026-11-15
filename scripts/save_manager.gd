extends Control

# Manual transfer for Android users importing successive game ZIP builds.
# Local saves are not encrypted or protected against editing. Back up before restoring.
var _text: TextEdit
var _status: Label

func _ready() -> void:
    Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
    set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    var bg := ColorRect.new()
    bg.color = Color(0.04,0.06,0.07)
    bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
    add_child(bg)
    var scroll := ScrollContainer.new()
    scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    add_child(scroll)
    var body := VBoxContainer.new()
    body.custom_minimum_size = Vector2(850,0)
    body.add_theme_constant_override("separation",10)
    scroll.add_child(body)
    var title := Label.new()
    title.text = "THE NEXT INFECTION — SAVE & TRANSFER"
    title.add_theme_font_size_override("font_size",22)
    body.add_child(title)
    var warning := Label.new()
    warning.text = "Export a backup BEFORE replacing a version. Import overwrites this project's world and bank save. Store the code privately."
    warning.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    body.add_child(warning)
    _text = TextEdit.new()
    _text.custom_minimum_size = Vector2(820,290)
    _text.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
    body.add_child(_text)
    var buttons := HBoxContainer.new()
    body.add_child(buttons)
    _button(buttons,"EXPORT & COPY SAVE",_export)
    _button(buttons,"RESTORE PASTED SAVE",_restore)
    _button(buttons,"BACK TO MENU",func(): get_tree().change_scene_to_file("res://scenes/menu.tscn"))
    _status = Label.new()
    _status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    body.add_child(_status)
    _status.text = "Export creates a JSON backup of your WorldProgress and SurvivalBank. No cloud storage is provided."

func _button(parent: HBoxContainer, title: String, callback: Callable) -> void:
    var button := Button.new()
    button.text = title
    button.custom_minimum_size = Vector2(245,48)
    button.pressed.connect(callback)
    parent.add_child(button)

func _export() -> void:
    var world: Dictionary = WorldProgress.load_data()
    var bank: Dictionary = SurvivalBank.load_bank()
    if world.has("read_error") or bank.has("read_error"):
        _status.text = "SAVE READ ERROR: Existing progress protected. Do not restore until files can be read."
        return
    var payload: Dictionary = {"format":"TNI_LOCAL_BACKUP_V1","world":world,"bank":bank}
    _text.text = JSON.stringify(payload,"  ")
    DisplayServer.clipboard_set(_text.text)
    _status.text = "BACKUP COPIED. Paste into a personal note or a local .txt file before importing another game ZIP."

func _restore() -> void:
    var parsed: Variant = JSON.parse_string(_text.text)
    if not (parsed is Dictionary) or str(parsed.get("format","")) != "TNI_LOCAL_BACKUP_V1":
        _status.text = "INVALID BACKUP: No data was changed."
        return
    if not (parsed.get("world") is Dictionary) or not (parsed.get("bank") is Dictionary):
        _status.text = "INVALID BACKUP: Missing world or bank record."
        return
    var w: Dictionary = parsed["world"]
    var b: Dictionary = parsed["bank"]
    if int(w.get("version",-1)) != 1 or not (w.get("plots") is Dictionary) or not (w.get("owned_weapons") is Array):
        _status.text = "WORLD VALIDATION FAILED. No changes made."
        return
    if int(b.get("version",-1)) != 1 or int(b.get("balance",-1)) < 0 or not (b.get("settled_run_ids") is Array) or not (b.get("owned") is Array):
        _status.text = "BANK VALIDATION FAILED. No changes made."
        return
    var before: Dictionary = {"format":"TNI_LOCAL_BACKUP_V1","world":WorldProgress.load_data(),"bank":SurvivalBank.load_bank()}
    if before["world"].has("read_error") or before["bank"].has("read_error"):
        _status.text = "Current save unreadable. Refusing to overwrite."
        return
    var previous_path: String = "user://tni_before_restore.json"
    var previous := FileAccess.open(previous_path,FileAccess.WRITE)
    if previous == null:
        _status.text = "Could not save existing backup; restore cancelled."
        return
    previous.store_string(JSON.stringify(before,"  "))
    previous.flush()
    previous.close()
    if not WorldProgress.import_save(w):
        _status.text = "World restore failed. Previous backup is at user://tni_before_restore.json"
        return
    if not SurvivalBank._write(b):
        WorldProgress.import_save(before["world"])
        _status.text = "Bank restore failed; attempted rollback. Old backup retained."
        return
    _status.text = "RESTORE COMPLETE. Restart the game to refresh all inventory and ownership screens."
