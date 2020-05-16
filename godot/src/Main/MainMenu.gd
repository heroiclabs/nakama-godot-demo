# Handles communication with the server, character creation, etc. for the main menus.
# The menus send signals to this node, and `MainMenu` processes the data or forwards it to the 
# server.
extends Node

# Maximum number of times to retry a server request if the previous attempt failed.
const MAX_REQUEST_ATTEMPTS := 3

# Path to the scene to load after selecting a character.
export (String, FILE) var next_scene_path := ""

var _server_request_attempts := 0

onready var login_and_register := $CanvasLayer/LoginAndRegister
onready var character_menu := $CanvasLayer/CharacterMenu


# Requests the server to authenticate the player using their credentials.
# Attempts authentication up to `MAX_REQUEST_ATTEMPTS` times.
func authenticate_user_async(email: String, password: String, do_remember_email := false) -> int:
	var result := -1

	login_and_register.is_enabled = false
	while result != OK:
		if _server_request_attempts == MAX_REQUEST_ATTEMPTS:
			break
		_server_request_attempts += 1
		result = yield(ServerConnection.login_async(email, password), "completed")

	if result == OK:
		if do_remember_email:
			ServerConnection.save_email(email)
		open_character_menu_async()
	else:
		login_and_register.status = "Error code %s: %s" % [result, ServerConnection.error_message]
		login_and_register.is_enabled = true

	_server_request_attempts = 0
	return result


# Asks the server to create a new character asynchronously.
# Returns a dictionary with the player's name and color if it worked.
# Otherwise, returns an empty dictionary.
func create_character_async(name: String, color: Color) -> void:
	character_menu.is_enabled = false

	var result: int = yield(
		ServerConnection.create_player_character_async(color, name), "completed"
	)

	var data := {}
	if result == OK:
		data = {name = name, color = color}
		character_menu.add_character(name, color)
		ServerConnection.store_last_player_character_async(name, color)
	elif result == ERR_UNAVAILABLE:
		printerr("Character %s unavailable." % name)

	character_menu.is_enabled = true
	return data


# Asks the server to delete a character asynchronously.
func delete_character_async(index: int) -> void:
	character_menu.is_enabled = false
	var result: int = yield(ServerConnection.delete_player_character_async(index), "completed")

	if result == OK:
		character_menu.delete_character(index)
	character_menu.is_enabled = true


# Attempts to connect to the server, then to join the world match.
func join_game_world_async(player_name: String, player_color: Color) -> int:
	character_menu.is_enabled = false

	var result: int = yield(ServerConnection.connect_to_server_async(), "completed")
	if result == OK:
		result = yield(ServerConnection.join_world_async(), "completed")
	if result == OK:
		# warning-ignore:return_value_discarded
		get_tree().change_scene_to(load("res://src/Main/GameWorld.tscn"))
		ServerConnection.send_spawn(player_color, player_name)

	character_menu.is_enabled = true
	return result


func open_character_menu_async() -> void:
	var characters: Array = yield(ServerConnection.get_player_characters_async(), "completed")
	var last_played_character: Dictionary = yield(
		ServerConnection.get_last_player_character_async(), "completed"
	)
	character_menu.setup(characters, last_played_character)
	login_and_register.hide()
	character_menu.show()


# Deactivates the user interface and authenticates the user.
# If the server authenticated the user, goes to the game level scene.
func _on_LoginAndRegister_login_pressed(email: String, password: String, do_remember_email: bool) -> void:
	login_and_register.status = "Authenticating..."
	login_and_register.is_enabled = false

	yield(authenticate_user_async(email, password, do_remember_email), "completed")

	login_and_register.is_enabled = true


# Deactivates the user interface, registers, and authenticates the user.
# If the server authenticated the user, goes to the game level scene.
func _on_LoginAndRegister_register_pressed(email: String, password: String, do_remember_email: bool) -> void:
	login_and_register.status = "Authenticating..."
	login_and_register.is_enabled = false

	var result: int = yield(ServerConnection.register_async(email, password), "completed")
	if result == OK:
		yield(authenticate_user_async(email, password, do_remember_email), "completed")
	else:
		login_and_register.status = "Error code %s: %s" % [result, ServerConnection.error_message]

	login_and_register.is_enabled = true


func _on_CharacterMenu_character_deletion_requested(index: int) -> void:
	delete_character_async(index)


func _on_CharacterMenu_new_character_requested(name: String, color: Color) -> void:
	yield(create_character_async(name, color), "completed")
	yield(join_game_world_async(name, color), "completed")


func _on_CharacterMenu_character_selected(name: String, color: Color) -> void:
	yield(join_game_world_async(name, color), "completed")


func _on_CharacterMenu_go_back_requested() -> void:
	login_and_register.reset()
	character_menu.reset()
	character_menu.hide()
	login_and_register.show()
