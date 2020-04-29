# Panel that controls the loading and displaying of characters in a character list.
# Also acts as the spawner and point of entry into the multiplayer level scene.
extends Menu

signal character_deletion_requested(index)
signal login_pressed(selected_index)
signal create_pressed

const MAX_CHARACTERS := 4

var last_index := -1

onready var character_list := $MarginContainer/VBoxContainer/CharacterList
onready var login_button := $MarginContainer/VBoxContainer/HBoxContainer/LoginButton
onready var create_button := $MarginContainer/VBoxContainer/HBoxContainer/CreateButton

onready var confirmation_popup := $ConfirmationPopup


# Initializes the control, fetches the characters from a successfully logged
# in player, and adds them in a controllable list. Also gets the last successful
# logged in character.
func setup(characters: Array, last_played_character: Dictionary) -> void:
	character_list.setup(characters, last_played_character)

	if characters.size() == MAX_CHARACTERS:
		create_button.disabled = true


func set_is_enabled(value: bool) -> void:
	.set_is_enabled(value)
	login_button.disabled = not is_enabled
	create_button.disabled = not is_enabled
	character_list.is_enabled = is_enabled


func _on_LoginButton_pressed() -> void:
	var character_data: Dictionary = character_list.get_selected_character()
	emit_signal("login_pressed", character_data.name, character_data.color)


func _on_CreateButton_pressed() -> void:
	emit_signal("create_pressed")


func _on_CharacterList_requested_deletion(character_index) -> void:
	self.is_enabled = false

	confirmation_popup.open()
	var is_confirmed: bool = yield(confirmation_popup, "option_picked")
	if is_confirmed:
		emit_signal("character_deletion_requested", character_index)

	self.is_enabled = true


func _on_CharacterList_character_selected(name: String, color: Color) -> void:
	emit_signal("login_pressed", name, color)
