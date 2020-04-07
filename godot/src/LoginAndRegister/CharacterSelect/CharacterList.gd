# A control representing a list of characters
extends VBoxContainer


func disable() -> void:
	for c in get_children():
		c.disable()


func enable() -> void:
	for c in get_children():
		c.enable()
