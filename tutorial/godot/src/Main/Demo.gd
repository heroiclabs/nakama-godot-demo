extends Node

onready var server_connection := $ServerConnection
onready var debug_panel := $CanvasLayer/DebugPanel


func _ready() -> void:
	yield(request_authentication(), "completed")
	yield(connect_to_server(), "completed")
	yield(join_world(), "completed")

	# Using the storage: saving characters, then asking the server to send us the saved data.
	var characters := [
		{name = "Jack", color = Color.blue.to_html(false)},
		{name = "Lisa", color = Color.red.to_html(false)}
	]
	yield(server_connection.write_characters_async(characters), "completed")
	var from_storage = yield(server_connection.get_characters_async(), "completed")

	debug_panel.write_message("Got %s from the server storage." % from_storage)


func request_authentication() -> void:
	var email := "test99@test.com"
	var password := "password"

	debug_panel.write_message("Authenticating user %s." % email)
	var result: int = yield(server_connection.authenticate_async(email, password), "completed")

	if result == OK:
		debug_panel.write_message("Authenticated user %s successfully." % email)
	else:
		debug_panel.write_message("Could not authenticate user %s." % email)


func connect_to_server() -> void:
	yield(server_connection.connect_to_server_async(), "completed")
	debug_panel.write_message("Connected to server.")


func join_world() -> void:
	var presences: Dictionary = yield(server_connection.join_world_async(), "completed")
	debug_panel.write_message("Joined world.")
	debug_panel.write_message("Other connected players: %s" % presences)
