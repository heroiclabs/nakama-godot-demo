extends Camera2D


func set_limits(limits: Rect2) -> void:
	limit_left = limits.position.x
	limit_top = limits.position.y
	limit_right = limits.position.x + limits.size.x
	limit_bottom = limits.position.y + limits.size.y
	
