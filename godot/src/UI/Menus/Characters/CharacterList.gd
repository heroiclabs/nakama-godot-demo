# Menu that lists the user's characters.
# Each CharacterListing in the menu allows the player to select and delete a character.
extends VBoxContainer

signal requested_deletion(character_index)
signal character_selected(character_index)

const CharacterListing := preload("res://src/UI/Menus/Characters/CharacterListing.tscn")

var is_enabled := true setget set_is_enabled


func _ready() -> void:
	setup(
		[{name = "Test", color = Color.white}, {name = "Test2", color = Color.red}],
		{name = "Test2", color = Color.red}
	)


func setup(characters: Array, last_played_character: Dictionary) -> void:
	# TODO: double-check the index is correct and corresponds to the server?
	for i in range(characters.size()):
		var character: Dictionary = characters[i]

		var name: String = character.name
		var color: Color = character.color
		var listing := CharacterListing.instance()

		add_child(listing)
		listing.setup(i, name, color)
		if name == last_played_character.name:
			listing.grab_focus()

		#warning-ignore: return_value_discarded
		listing.connect("requested_deletion", self, "_on_CharacterListing_requested_deletion")
		#warning-ignore: return_value_discarded
		listing.connect("character_selected", self, "_on_CharacterListing_character_selected")


func set_is_enabled(value: bool) -> void:
	is_enabled = value
	if not get_child(0):
		yield(self, "ready")
	for character_listing in get_children():
		character_listing.is_enabled = is_enabled


func _on_CharacterListing_requested_deletion(index: int) -> void:
	emit_signal("requested_deletion", index)
