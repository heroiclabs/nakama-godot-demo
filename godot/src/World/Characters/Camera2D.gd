extends Camera2D


func set_limits(limits: Rect2) -> void:
	limit_left = int(limits.position.x)
	limit_top = int(limits.position.y)
	limit_right = int(limits.position.x + limits.size.x)
	limit_bottom = int(limits.position.y + limits.size.y)
