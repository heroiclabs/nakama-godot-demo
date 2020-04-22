extends Node

const MAX_REQUEST_ATTEMPTS := 3
const LevelScene: PackedScene = preload("res://src/World/Level.tscn")

var level: Node

var _server_request_attempts := 0

onready var main_menu := $MainMenu
onready var character_menu := $CharacterMenu


func create_level(player_data: Dictionary) -> void:
	level = LevelScene.instance()
	add_child(level)
	level.setup(player_data.name, player_data.color)


# Asks the server to create a new character asynchronously.
# Returns a dictionary with the player's name and color if it worked.
# Otherwise, returns an empty dictionary.
func create_character(name: String, color: Color) -> void:
	var result: int = yield(Connection.create_player_character_async(color, name), "completed")

	var data := {}
	if result == ERR_UNAVAILABLE:
		printerr("Character %s unavailable." % name)
	elif result == OK:
		data = {name = name, color = color}
		Connection.store_last_player_character_async(name, color)
	return data


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
func authenticate_user(email: String, password: String, do_remember_email: bool) -> void:
	var result := -1

	while result != OK:
		if _server_request_attempts < MAX_REQUEST_ATTEMPTS:
			_server_request_attempts += 1
			result = yield(_request_authentication(email, password, do_remember_email), "completed")
		else:
			break

	if result == OK:
		main_menu.hide()
		character_menu.show()
	else:
		main_menu.update_status("Error code %s: %s" % [result, Connection.error_message])

	_server_request_attempts = 0

# Requests the server to authenticate the player using their credentials.
func _request_authentication(email: String, password: String, do_remember_email := false) -> int:
	main_menu.is_enabled = false

	var result: int = yield(Connection.login_async(email, password), "completed")
	if result == OK and do_remember_email:
		Connection.save_email(email)

	main_menu.is_enabled = true
	return result


func _on_CharacterMenu_new_character_requested(name: String, color: Color) -> void:
	create_character(name, color)


func _on_MainMenu_login_pressed(email: String, password: String, do_remember_email: bool) -> void:
	authenticate_user(email, password, do_remember_email)


func _on_MainMenu_register_pressed(email: String, password: String, do_remember_email: bool) -> void:
	main_menu.update_status("Authenticating...")
	main_menu.is_enabled = false

	var result: int = yield(
		Connection.register_async(email, password), "completed"
	)
	if result == OK:
		authenticate_user(email, password, do_remember_email)
	else:
		main_menu.update_status("Error code %s: %s" % [result, Connection.error_message])

	main_menu.is_enabled = true
