# Handles communication with the server, character creation, etc. for the main menus.
# The menus send signals to this node, and `MainMenu` processes the data or forwards it to the 
# server.
extends Node

const MAX_REQUEST_ATTEMPTS := 3
const LevelScene: PackedScene = preload("res://src/World/Level.tscn")

export (String, FILE) var next_scene_path := ""

var level: Node

var _server_request_attempts := 0

onready var login_and_register := $LoginAndRegister
onready var character_menu := $CharacterMenu


func create_level(player_data: Dictionary) -> void:
	level = LevelScene.instance()
	add_child(level)
	level.setup(player_data.name, player_data.color)


# Asks the server to create a new character asynchronously.
# Returns a dictionary with the player's name and color if it worked.
# Otherwise, returns an empty dictionary.
func create_character(name: String, color: Color) -> void:
	character_menu.is_enabled = false

	var result: int = yield(Connection.create_player_character_async(color, name), "completed")

	var data := {}
	if result == OK:
		data = {name = name, color = color}
		character_menu.add_character(name, color)
		Connection.store_last_player_character_async(name, color)
	elif result == ERR_UNAVAILABLE:
		printerr("Character %s unavailable." % name)

	character_menu.is_enabled = true
	return data


func delete_character(index: int) -> void:
	character_menu.is_enabled = false
	var result: int = yield(Connection.delete_player_character_async(index), "completed")

	if result == OK:
		character_menu.delete_character(index)
	character_menu.is_enabled = true


# Gets a player's data asynchronously by `index` from the server.
func get_player(index: int) -> Dictionary:
	var characters: Array = yield(Connection.get_player_characters_async(), "completed")
	return characters[index]


# Attempts to connect to the server, then to join the world match.
func join_game_world() -> int:
	var result: int = yield(Connection.connect_to_server_async(), "completed")

	if result == OK:
		result = yield(Connection.join_world_async(), "completed")

	if result == OK:
		emit_signal("server_request_succeeded")
	else:
		emit_signal(
			"server_request_failed", "Error code %s: %s" % [result, Connection.error_message]
		)
	return result


# Requests the server to authenticate the player using their credentials.
# Attempts authentication up to `MAX_REQUEST_ATTEMPTS` times.
func authenticate_user(email: String, password: String, do_remember_email := false) -> int:
	var result := -1

	while result != OK:
		if _server_request_attempts < MAX_REQUEST_ATTEMPTS:
			_server_request_attempts += 1
			result = yield(_request_authentication(email, password, do_remember_email), "completed")
		else:
			break

	if result == OK:
		open_character_menu()
	else:
		login_and_register.status = "Error code %s: %s" % [result, Connection.error_message]

	_server_request_attempts = 0
	return result


func open_character_menu() -> void:
	var characters: Array = yield(Connection.get_player_characters_async(), "completed")
	var last_played_character: Dictionary = yield(
		Connection.get_last_player_character_async(), "completed"
	)
	character_menu.setup(characters, last_played_character)
	login_and_register.hide()
	character_menu.show()


# Requests the server to authenticate the player using their credentials.
func _request_authentication(email: String, password: String, do_remember_email := false) -> int:
	login_and_register.is_enabled = false

	var result: int = yield(Connection.login_async(email, password), "completed")
	if result == OK and do_remember_email:
		Connection.save_email(email)

	login_and_register.is_enabled = true
	return result


# Deactivates the user interface and authenticates the user.
# If the server authenticated the user, goes to the game level scene.
func _on_LoginAndRegister_login_pressed(email: String, password: String, do_remember_email: bool) -> void:
	login_and_register.status = "Authenticating..."
	login_and_register.is_enabled = false

	yield(authenticate_user(email, password, do_remember_email), "completed")

	login_and_register.is_enabled = true


# Deactivates the user interface, registers, and authenticates the user.
# If the server authenticated the user, goes to the game level scene.
func _on_LoginAndRegister_register_pressed(email: String, password: String, do_remember_email: bool) -> void:
	login_and_register.status = "Authenticating..."
	login_and_register.is_enabled = false

	var result: int = yield(Connection.register_async(email, password), "completed")
	if result == OK:
		yield(authenticate_user(email, password, do_remember_email), "completed")
	else:
		login_and_register.status = "Error code %s: %s" % [result, Connection.error_message]

	login_and_register.is_enabled = true


func _on_CharacterMenu_character_deletion_requested(index: int) -> void:
	delete_character(index)


func _on_CharacterMenu_new_character_requested(name: String, color: Color) -> void:
	create_character(name, color)


func _on_CharacterMenu_character_selected(_index: int) -> void:
	# warning-ignore:return_value_discarded
	get_tree().change_scene_to(load("res://src/Main/GameWorld.tscn"))
