class_name WeaponCardArt
extends Control

# Drawn preview, never a licensed weapon image.
var _weapon_id: String = "pistol"

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func set_weapon(id: String) -> void:
	_weapon_id = id
	queue_redraw()

func _draw() -> void:
	var c := Color(0.22,0.82,0.80)
	var w := size.x
	var h := size.y
	var gun_length: float = 0.35 if _weapon_id == "pistol" else 0.64
	if _weapon_id == "shotgun" or _weapon_id == "lmg":
		gun_length = 0.80
	var start_x := w * (1.0 - gun_length) * 0.5
	var end_x := start_x + w * gun_length
	var y := h * 0.46
	draw_rect(Rect2(Vector2(start_x,y),Vector2(end_x - start_x,h * 0.14)),c)
	draw_rect(Rect2(Vector2(start_x + 15,y + 8),Vector2(22,h * 0.36)),c.darkened(0.25))
	draw_rect(Rect2(Vector2(start_x + 45,y - 11),Vector2(50,11)),c)
	draw_rect(Rect2(Vector2(end_x - 15,y + 5),Vector2(30,6)),c.lightened(0.3))
	if _weapon_id != "pistol":
		draw_rect(Rect2(Vector2(start_x + (end_x-start_x) * 0.51,y + 12),Vector2(12,34)),c.darkened(0.20))
	if _weapon_id == "shotgun":
		draw_rect(Rect2(Vector2(start_x + 35,y - 12),Vector2((end_x-start_x)*0.7,7)),c.darkened(0.10))
	if _weapon_id == "lmg":
		draw_rect(Rect2(Vector2(start_x+40,y+16),Vector2(42,29)),c.darkened(0.2))
