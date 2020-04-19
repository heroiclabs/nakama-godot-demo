# Panel that controls the loading and displaying of characters in a character list.
# Also acts as the spawner and point of entry into the multiplayer world scene.
extends Control

const MAX_CHARACTERS := 4

export var CharacterListing: PackedScene
export var WorldScene: PackedScene

var world: Node

var last_index := 0
var last_name: String
var last_color: Color


onready var character_list := $MarginContainer/VBoxContainer/CharacterList
onready var character_tex := $MarginContainer/VBoxContainer/CharacterList/CharacterListing/HBoxContainer/TextureRect
onready var character_name := $MarginContainer/VBoxContainer/CharacterList/CharacterListing/HBoxContainer/Label
onready var login_button := $MarginContainer/VBoxContainer/HBoxContainer/LoginButton
onready var new_character := $MarginContainer/VBoxContainer/HBoxContainer/CreateButton



# Initializes the control, fetches the characters from a successfully logged
# in player, and adds them in a controllable list. Also gets the last successful
# logged in character.
func setup() -> void:
	#warning-ignore: return_value_discarded
	new_character.connect("new_character_created", self, "_on_New_Character_Created")
	#warning-ignore: return_value_discarded
	login_button.connect("button_down", self, "_do_create_world")

	var characters: Array = yield(Connection.get_player_characters_async(), "completed")
	for i in range(characters.size()):
		var character: Dictionary = characters[i]

		var name: String = character.name
		var color: Color = character.color
		var listing := CharacterListing.instance()

		character_list.add_child(listing)
		listing.setup(i, name, color)

		#warning-ignore: return_value_discarded
		listing.connect("requested_deletion", self, "_on_CharacterListing_requested_deletion")
		#warning-ignore: return_value_discarded
		listing.connect("character_selected", self, "_on_CharacterListing_character_selected")

	if characters.size() > MAX_CHARACTERS:
		new_character.disable()

	var last_character: Dictionary = yield(
		Connection.get_last_player_character_async(), "completed"
	)
	if last_character.size() > 0:
		last_name = last_character.name
		last_color = last_character.color

		_update_character()
		_show_character()


func _disable_all() -> void:
	login_button.disabled = true
	for c in character_list.get_children():
		c.disable()
	new_character.disable()


func _enable_all() -> void:
	login_button.disabled = false
	for c in character_list.get_children():
		c.enable()
	if character_list.get_child_count() < MAX_CHARACTERS:
		new_character.enable()


func _deleted_down(index: int) -> void:
	last_index = index
	_disable_all()


func _on_New_Character_Created(name: String, color: Color) -> void:
	var result: int = yield(Connection.create_player_character_async(color, name), "completed")

	if result == ERR_UNAVAILABLE:
		new_character.name_field.text = "Name is unavailable"
	elif result == OK:
		last_name = name
		last_color = color

		_do_create_world()


func _do_create_world() -> void:
	if WorldScene:
		Connection.store_last_player_character_async(last_name, last_color)

		world = WorldScene.instance()
		get_tree().root.add_child(world)

		world.setup(last_name, last_color)

		owner.queue_free()


func _update_character() -> void:
	character_tex.modulate = last_color
	character_name.text = last_name


func _show_character() -> void:
	character_tex.visible = true
	character_name.visible = true
	login_button.visible = true


func _hide_character() -> void:
	character_tex.visible = false
	character_name.visible = false
	login_button.visible = false


func _character_selected(index: int) -> void:
	var characters: Array = yield(Connection.get_player_characters_async(), "completed")

	if index >= characters.size():
		return

	var character: Dictionary = characters[index]

	last_name = character.name
	last_color = character.color

	_update_character()
	_show_character()


func _on_ConfirmationPopup_cancelled() -> void:
	_enable_all()


func _on_ConfirmationPopup_confirmed() -> void:
	if character_list.get_child_count() <= last_index:
		return

	var listing_name = character_list.get_child(last_index).get_name()
	character_list.get_child(last_index).queue_free()

	Connection.delete_player_character_async(last_index)

	_enable_all()

	if character_list.get_child_count() == 0 or listing_name == last_name:
		_hide_character()
		last_index = 0
	for i in range(character_list.get_child_count()):
		character_list.get_child(i).index = i
