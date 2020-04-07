# Utility class that draws a rectangle over a rectangle collision shape.
tool
extends CollisionShape2D

export var color := Color.white setget _set_shape_color


func _draw() -> void:
	var extents: Vector2 = shape.extents
	draw_rect(Rect2(-extents, extents * 2), color, true)


func _set_shape_color(value: Color) -> void:
	color = value
	update()
