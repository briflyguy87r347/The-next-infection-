class_name OpenWorldMinimap
extends Control

var position_3d: Vector3 = Vector3.ZERO
var vehicle_position: Vector3 = Vector3.ZERO
var destination: Vector3 = Vector3.ZERO
var in_vehicle: bool = false
const SCALE: float = 0.65

func _ready() -> void:
    mouse_filter = Control.MOUSE_FILTER_IGNORE
    custom_minimum_size = Vector2(168, 168)

func _draw() -> void:
    draw_rect(Rect2(Vector2.ZERO, size), Color(0.018,0.035,0.039,0.86), true)
    var center := size * 0.5
    # Roads and district sector grid, north-up (not an actual Florida map).
    for i in range(-4,5):
        var coordinate: float = float(i)*22.0
        var line_x: float = center.x + (coordinate-position_3d.x)*SCALE
        var line_y: float = center.y + (coordinate-position_3d.z)*SCALE
        draw_line(Vector2(line_x,0),Vector2(line_x,size.y),Color(0.32,0.36,0.36,0.36),2)
        draw_line(Vector2(0,line_y),Vector2(size.x,line_y),Color(0.32,0.36,0.36,0.36),2)
    var destination_2d: Vector2 = center + Vector2(destination.x-position_3d.x, destination.z-position_3d.z) * SCALE
    destination_2d.x = clampf(destination_2d.x,9.0,size.x-9.0)
    destination_2d.y = clampf(destination_2d.y,9.0,size.y-9.0)
    draw_circle(destination_2d,6.0,Color(0.96,0.76,0.23))
    draw_circle(center,5.5,Color(0.28,0.89,0.96))
    draw_rect(Rect2(Vector2.ZERO,size),Color(0.38,0.66,0.65,0.75),false,2)
