# VBoxContainer that contains a list of buttons.
# Can enable and disable them all.
extends VBoxContainer


func disable() -> void:
	for character_listing in get_children():
		character_listing.disable()


func enable() -> void:
	for character_listing in get_children():
		character_listing.enable()
