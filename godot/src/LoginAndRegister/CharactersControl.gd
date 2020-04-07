extends Control

export var CharacterListing: PackedScene
export var WorldScene: PackedScene

var world: Node

var last_index := 0
var last_name: String
var last_color: Color

onready var listings := $MarginContainer/VBoxContainer/CharacterListing/CharacterList
onready var character_tex := $MarginContainer/VBoxContainer/CharacterListing/Character/TextureRect
onready var character_name := $MarginContainer/VBoxContainer/CharacterListing/Character/Label
onready var login_button := $MarginContainer/VBoxContainer/CharacterListing/Character/Button
onready var new_character := $MarginContainer/VBoxContainer/NewCharacter
onready var confirmation := $CenterContainer/Confirmation


func setup() -> void:
	#warning-ignore: return_value_discarded
	confirmation.connect("cancelled", self, "_on_Delete_cancelled")
	#warning-ignore: return_value_discarded
	confirmation.connect("confirmed", self, "_on_Delete_confirmed")
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
		listings.add_child(listing)
		listing.setup(i, name, color)
		#warning-ignore: return_value_discarded
		listing.connect("deleted_down", self, "_deleted_down")
		#warning-ignore: return_value_discarded
		listing.connect("character_selected", self, "_character_selected")

	if characters.size() > 5:
		new_character.disable()

	var last_character: Dictionary = yield(Connection.get_last_player_character_async(), "completed")
	if last_character.size() > 0:
		last_name = last_character.name
		last_color = last_character.color

		_update_character()
		_show_character()


func _disable_all() -> void:
	login_button.disabled = true
	for c in listings.get_children():
		c.disable()
	new_character.disable()


func _enable_all() -> void:
	login_button.disabled = false
	for c in listings.get_children():
		c.enable()
	if listings.get_child_count() < 5:
		new_character.enable()


func _deleted_down(index: int) -> void:
	last_index = index
	confirmation.visible = true
	_disable_all()


func _on_Delete_cancelled() -> void:
	_enable_all()
	confirmation.visible = false


func _on_Delete_confirmed() -> void:
	if listings.get_child_count() <= last_index:
		return
	
	var listing_name = listings.get_child(last_index).get_name()
	listings.get_child(last_index).queue_free()
	Connection.delete_player_character_async(last_index)
	_enable_all()
	confirmation.visible = false
	if listings.get_child_count() == 0 or listing_name == last_name:
		_hide_character()
		last_index = 0
	for i in range(listings.get_child_count()):
		listings.get_child(i).index = i


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
		world = WorldScene.instance()
		get_tree().root.add_child(world)
		Connection.store_last_player_character_async(last_name, last_color)
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
