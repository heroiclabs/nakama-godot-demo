# A control representing a list of characters
extends VBoxContainer


func disable() -> void:
	for character_listing in get_children():
		character_listing.disable()


func enable() -> void:
	for character_listing in get_children():
		character_listing.enable()
