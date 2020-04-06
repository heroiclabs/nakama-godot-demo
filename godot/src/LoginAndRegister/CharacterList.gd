extends VBoxContainer


func disable() -> void:
	for c in get_children():
		c.disable()


func enable() -> void:
	for c in get_children():
		c.enable()
