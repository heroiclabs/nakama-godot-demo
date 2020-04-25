# Menu that lists the user's characters.
# Each `CharacterListing` in the menu allows the player to select and delete a character.
extends Menu

signal requested_deletion(character_index)

const CharacterListing := preload("res://src/UI/Menus/Characters/CharacterListing.tscn")

var selected_index := -1

func _ready() -> void:
	setup(
		[{name = "Test", color = Color.white}, {name = "Test2", color = Color.red}],
		{name = "Test2", color = Color.red}
	)


func setup(characters: Array, last_played_character: Dictionary) -> void:
	for index in range(characters.size()):
		var character: Dictionary = characters[index]

		var name: String = character.name
		var color: Color = character.color
		var listing := CharacterListing.instance()

		add_child(listing)
		listing.setup(name, color)
		if name == last_played_character.name:
			listing.grab_focus()
			selected_index = index

		#warning-ignore: return_value_discarded
		listing.connect("requested_deletion", self, "_on_CharacterListing_requested_deletion")
		#warning-ignore: return_value_discarded
		listing.connect("character_selected", self, "_on_CharacterListing_character_selected")


# Deletes the listing for the selected character and updates the `selected_index`.
func delete_selected_character() -> void:
	get_child(selected_index).queue_free()
	selected_index = selected_index % int(max(get_child_count() - 1, 1))
	get_child(selected_index).grab_focus()


func set_is_enabled(value: bool) -> void:
	.set_is_enabled(value)
	if not get_child(0):
		yield(self, "ready")
	for character_listing in get_children():
		character_listing.is_enabled = is_enabled


func _on_CharacterListing_requested_deletion(index: int) -> void:
	emit_signal("requested_deletion", index)


func _on_CharacterListing_character_selected(index: int) -> void:
	selected_index = index
