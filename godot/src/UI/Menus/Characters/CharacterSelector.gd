# Panel that controls the loading and displaying of characters in a character list.
# Also acts as the spawner and point of entry into the multiplayer level scene.
extends Control

const MAX_CHARACTERS := 4

# TODO: Move
const LevelScene: PackedScene = preload("res://src/World/Level.tscn")

var level: Node

var last_index := 0
var last_name: String
var last_color: Color

onready var character_list := $MarginContainer/VBoxContainer/CharacterList
onready var login_button := $MarginContainer/VBoxContainer/HBoxContainer/LoginButton
onready var create_button := $MarginContainer/VBoxContainer/HBoxContainer/CreateButton


# Initializes the control, fetches the characters from a successfully logged
# in player, and adds them in a controllable list. Also gets the last successful
# logged in character.
func setup() -> void:
	# TODO: change_scene? Move that up the tree, to a Game node?
# warning-ignore:return_value_discarded
	login_button.connect("button_down", self, "_do_create_level")

	var characters: Array = yield(Connection.get_player_characters_async(), "completed")
	var last_played_character: Dictionary = yield(
		Connection.get_last_player_character_async(), "completed"
	)
	character_list.setup(characters, last_played_character)

	if characters.size() == MAX_CHARACTERS:
		create_button.disable()


func _disable_all() -> void:
	login_button.disabled = true
	character_list.disable()
	create_button.disable()


func _enable_all() -> void:
	login_button.disabled = false
	character_list.enable()
	if character_list.get_child_count() < MAX_CHARACTERS:
		create_button.enable()


func _deleted_down(index: int) -> void:
	last_index = index
	_disable_all()


# TODO: move away
func _do_create_level() -> void:
	if LevelScene:
		Connection.store_last_player_character_async(last_name, last_color)

		level = LevelScene.instance()
		get_tree().root.add_child(level)

		level.setup(last_name, last_color)

		owner.queue_free()


# TODO: move away
func _character_selected(index: int) -> void:
	var characters: Array = yield(Connection.get_player_characters_async(), "completed")

	if index >= characters.size():
		return

	var character: Dictionary = characters[index]

	last_name = character.name
	last_color = character.color


func _on_ConfirmationPopup_cancelled() -> void:
	_enable_all()


# TODO: move to List
func _on_ConfirmationPopup_confirmed() -> void:
	if character_list.get_child_count() <= last_index:
		return

	character_list.get_child(last_index).queue_free()
	Connection.delete_player_character_async(last_index)
	_enable_all()

	for i in range(character_list.get_child_count()):
		character_list.get_child(i).index = i


func _on_CharacterCreator_character_created(name: String, color: Color) -> void:
	var result: int = yield(Connection.create_player_character_async(color, name), "completed")

	if result == ERR_UNAVAILABLE:
		create_button.name_field.text = "Name is unavailable"
	elif result == OK:
		last_name = name
		last_color = color

		_do_create_level()


func _on_LoginButton_pressed() -> void:
	pass # Replace with function body.
