# World that aggregates the world and game ui together. Primarily reacts to
# events from either the UI or from the server, updating the characters or
# player accordingly, and facilitating sending messages back to the server.
extends Node2D

export var PlayerScene: PackedScene
export var CharacterScene: PackedScene

var characters := {}
var last_name: String
var last_color: Color

onready var world := $World
onready var player: Node = $Player
onready var game_ui := $CanvasLayer/GameUI


func _ready() -> void:
	#warning-ignore: return_value_discarded
	ServerConnection.connect(
		"initial_state_received", self, "_on_ServerConnection_initial_state_received"
	)
	game_ui.setup(Color.green)


func setup(username: String, color: Color) -> void:
	last_name = username
	last_color = color
	#ServerConnection.send_spawn(color, username)


# The main entry point. Sets up the client player and the various characters that
# are already logged into the world, and sets up the signal chain to respond to
# the server.
func join_world(
	state_positions: Dictionary,
	state_inputs: Dictionary,
	state_colors: Dictionary,
	state_names: Dictionary
) -> void:
	var user_id := ServerConnection.get_user_id()
	assert(state_positions.has(user_id), "Server did not return valid state")
	var username: String = state_names.get(user_id)
	var player_color: Color = state_colors.get(user_id)

	var player_position: Vector2 = Vector2(state_positions[user_id].x, state_positions[user_id].y)
	player.setup(username, player_color, player_position, world.get_limits())
	game_ui.setup(player_color)

	var presences := ServerConnection.presences
	for p in presences.keys():
		var character_position := Vector2(state_positions[p].x, state_positions[p].y)
		create_character(
			p, state_names[p], character_position, state_inputs[p].dir, state_colors[p], true
		)

	#warning-ignore: return_value_discarded
	ServerConnection.connect("presences_changed", self, "_on_ServerConnection_presences_changed")
	#warning-ignore: return_value_discarded
	ServerConnection.connect("state_updated", self, "_on_ServerConnection_state_updated")
	#warning-ignore: return_value_discarded
	ServerConnection.connect("color_updated", self, "_on_ServerConnection_color_updated")
	#warning-ignore: return_value_discarded
	ServerConnection.connect(
		"chat_message_received", self, "_on_ServerConnection_chat_message_received"
	)
	#warning-ignore: return_value_discarded
	ServerConnection.connect("character_spawned", self, "_on_ServerConnection_character_spawned")


func create_character(
	id: String,
	username: String,
	position: Vector2,
	direction_x: float,
	color: Color,
	do_spawn: bool
) -> void:
	var character := CharacterScene.instance()
	character.position = position
	character.direction.x = direction_x
	character.color = color

	#warning-ignore: return_value_discarded
	world.add_child(character)
	character.username = username
	characters[id] = character
	if do_spawn:
		character.spawn()
	else:
		character.do_hide()


func _on_ServerConnection_presences_changed() -> void:
	var presences := ServerConnection.presences

	for key in presences:
		if not key in characters:
			create_character(key, "User", Vector2.ZERO, 0, Color.white, false)

	var to_delete := []
	for key in characters.keys():
		if not key in presences:
			to_delete.append(key)

	for key in to_delete:
		characters[key].despawn()
		game_ui.add_notification(characters[key].username, characters[key].color, true)
		#warning-ignore: return_value_discarded
		characters.erase(key)


func _on_ServerConnection_state_updated(positions: Dictionary, inputs: Dictionary) -> void:
	var update := false
	for key in characters:
		update = false
		if key in positions:
			var next_position: Dictionary = positions[key]
			characters[key].next_position = Vector2(next_position.x, next_position.y)
			update = true
		if key in inputs:
			characters[key].next_input = inputs[key].dir
			characters[key].next_jump = inputs[key].jmp == 1
			update = true
		if update:
			characters[key].update_state()


func _on_ServerConnection_color_updated(id: String, color: Color) -> void:
	if id in characters:
		characters[id].color = color


func _on_ServerConnection_chat_message_received(sender_id: String, message: String) -> void:
	var color := Color.gray
	var sender_name := "User"

	if sender_id in characters:
		color = characters[sender_id].color
		sender_name = characters[sender_id].username
	elif sender_id == ServerConnection.get_user_id():
		color = player.color
		sender_name = player.username

	game_ui.add_chat_reply(message, sender_name, color)


func _on_ServerConnection_character_spawned(id: String, color: Color, name: String) -> void:
	if id in characters:
		characters[id].color = color
		characters[id].username = name
		characters[id].spawn()
		characters[id].do_show()
		game_ui.add_notification(characters[id].username, color)


func _on_ServerConnection_initial_state_received(
	positions: Dictionary, inputs: Dictionary, colors: Dictionary, names: Dictionary
) -> void:
	#warning-ignore: return_value_discarded
	ServerConnection.disconnect(
		"initial_state_received", self, "_on_ServerConnection_initial_state_received"
	)
	join_world(positions, inputs, colors, names)


func _on_GameUI_color_changed(color) -> void:
	game_ui.setup(color)
	ServerConnection.send_player_color_update(color)
	ServerConnection.update_player_character_async(color, player.username)


func _on_GameUI_text_sent(text) -> void:
	ServerConnection.send_text_async(text)


func _on_GameUI_logged_out() -> void:
	var result: int = yield(ServerConnection.disconnect_from_server_async(), "completed")
	if result == OK:
		get_tree().change_scene_to(load("res://src/Main/MainMenu.tscn"))
