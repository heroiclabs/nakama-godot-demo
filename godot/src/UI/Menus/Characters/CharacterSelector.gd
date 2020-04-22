# Panel that controls the loading and displaying of characters in a character list.
# Also acts as the spawner and point of entry into the multiplayer level scene.
extends Control

signal create_pressed
signal login_pressed

const MAX_CHARACTERS := 4

var is_enabled := true setget set_is_enabled
var last_index := -1

onready var character_list := $MarginContainer/VBoxContainer/CharacterList
onready var login_button := $MarginContainer/VBoxContainer/HBoxContainer/LoginButton
onready var create_button := $MarginContainer/VBoxContainer/HBoxContainer/CreateButton


# Initializes the control, fetches the characters from a successfully logged
# in player, and adds them in a controllable list. Also gets the last successful
# logged in character.
func setup() -> void:
	var characters: Array = yield(Connection.get_player_characters_async(), "completed")
	var last_played_character: Dictionary = yield(
		Connection.get_last_player_character_async(), "completed"
	)
	character_list.setup(characters, last_played_character)

	if characters.size() == MAX_CHARACTERS:
		create_button.disabled = true


func set_is_enabled(value: bool) -> void:
	is_enabled = value
	login_button.disabled = not is_enabled
	create_button.disabled = not is_enabled
	character_list.is_enabled = is_enabled


func _on_ConfirmationPopup_cancelled() -> void:
	self.is_enabled = true


func _on_ConfirmationPopup_confirmed() -> void:
	if character_list.get_child_count() <= last_index:
		return

	character_list.get_child(last_index).queue_free()
	Connection.delete_player_character_async(last_index)
	self.is_enabled = true

	for i in range(character_list.get_child_count()):
		character_list.get_child(i).index = i


func _on_LoginButton_pressed() -> void:
	pass  # Replace with function body.


func _on_CharacterList_character_selected(character_index) -> void:
	pass  # Replace with function body.


func _on_CreateButton_pressed() -> void:
	pass  # Replace with function body.
