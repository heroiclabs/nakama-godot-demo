# Menu that lists the user's characters.
# Each `CharacterListing` in the menu allows the player to select and delete a character.
extends Menu

signal requested_deletion(character_index)
signal character_selected(name, color)

const CharacterListing := preload("res://src/UI/Menus/Characters/CharacterListing.tscn")

var selected_index := -1


# Fills the list with character listings and gives focus to the last played character's listing.
func setup(characters: Array, last_played_character: Dictionary) -> void:
	for index in range(characters.size()):
		var character: Dictionary = characters[index]
		var listing := add_character(character.name, character.color)

		if last_played_character and character.name == last_played_character.name:
			listing.grab_focus()
			selected_index = index


# Creates a new `CharacterListing` that represents a character in the interface.
func add_character(name: String, color: Color) -> Node:
	var listing := CharacterListing.instance()
	add_child(listing)
	listing.setup(name, color)
	#warning-ignore: return_value_discarded
	listing.connect("requested_deletion", self, "_on_CharacterListing_requested_deletion")
	#warning-ignore: return_value_discarded
	listing.connect("character_selected", self, "_on_CharacterListing_character_selected")
	# warning-ignore:return_value_discarded
	listing.connect("character_accepted", self, "_on_CharacterListing_character_accepted")
	return listing


# Deletes the listing for the selected character and updates the `selected_index`.
func delete_character(index: int) -> void:
	get_child(index).queue_free()
	var new_index: int = selected_index % int(max(get_child_count() - 1, 1))
	if new_index != selected_index:
		selected_index = new_index
		get_child(selected_index).grab_focus()


func set_is_enabled(value: bool) -> void:
	.set_is_enabled(value)
	if get_child_count() == 0:
		yield(self, "ready")
	for character_listing in get_children():
		character_listing.is_enabled = is_enabled


func reset() -> void:
	for child in get_children():
		child.queue_free()


func get_character_data(index: int) -> Dictionary:
	var listing: CharacterListing = get_child(index)
	if listing == null:
		return {}
	return {name = listing.label.text, color = listing.texture.modulate}


# Returns the selected characterData. Convenience function for `get_character_data`
func get_selected_character() -> Dictionary:
	return get_character_data(selected_index)


func _on_CharacterListing_requested_deletion(index: int) -> void:
	emit_signal("requested_deletion", index)


func _on_CharacterListing_character_selected(index: int) -> void:
	selected_index = index


func _on_CharacterListing_character_accepted(index: int) -> void:
	var character := get_character_data(index)
	emit_signal("character_selected", character.name, character.color)
