extends Node2D

export var PlayerScene: PackedScene
export var CharacterScene: PackedScene

var player: Node
var characters := {}

onready var world := $World
onready var game_ui := $CanvasLayer/GameUI


func _ready() -> void:
	#warning-ignore: return_value_discarded
	game_ui.connect("color_changed", self, "_on_Color_changed")


func join_world(username: String, state_positions: Dictionary, state_inputs: Dictionary) -> void:
	assert(state_positions.has(Connection.session.user_id), "Server did not return valid state")
	
	var player_position: Dictionary = state_positions[Connection.session.user_id]
	_setup_player(username, Vector2(player_position.x, player_position.y))
	
	var presences := Connection.presences
	var character_colors: Dictionary = yield(Connection.get_player_colors(presences.keys()), "completed")
	for p in presences.keys():
		var character_position := Vector2(state_positions[p].x, state_positions[p].y)
		var color: Color = character_colors[p] if character_colors.has(p) else Color.white
		_setup_character(p, presences[p].username, character_position, state_inputs[p].dir, color)
	
	#warning-ignore: return_value_discarded
	Connection.connect("presences_changed", self, "_on_Presences_changed")
	#warning-ignore: return_value_discarded
	Connection.connect("state_updated", self, "_on_State_updated")
	#warning-ignore: return_value_discarded
	Connection.connect("color_updated", self, "_on_Color_updated")


func _setup_player(username: String, player_position: Vector2) -> void:
	var player_color: Color = yield(Connection.get_player_color(Connection.session.user_id), "completed")
	
	player = PlayerScene.instance()
	player.color = player_color
	
	world.add_child(player)
	player.username = username
	
	player.global_position = player_position
	player.spawn()


func _setup_character(id: String, username: String, character_position: Vector2, character_input: float, color: Color) -> void:
	var character: = CharacterScene.instance()
	character.position = character_position
	character.direction.x = character_input
	character.color = color
	
	#warning-ignore: return_value_discarded
	world.add_child(character)
	character.username = username
	characters[id] = character
	character.spawn()


func _on_Presences_changed() -> void:
	var presences := Connection.presences
	for p in presences.keys():
		if not characters.has(p):
			var character_color: Color = yield(Connection.get_player_color(p), "completed")
			_setup_character(p, presences[p].username, Vector2.ZERO, 0, character_color)
	var despawns := []
	for c in characters.keys():
		if not presences.has(c):
			despawns.append(c)
	for d in despawns:
		characters[d].despawn()
		#warning-ignore: return_value_discarded
		characters.erase(d)


func _on_State_updated(positions: Dictionary, inputs: Dictionary) -> void:
	var update := false
	for c in characters.keys():
		update = false
		if positions.has(c):
			var next_position: Dictionary = positions[c]
			characters[c].next_position = Vector2(next_position.x, next_position.y)
			update = true
		if inputs.has(c):
			characters[c].next_input = inputs[c].dir
			characters[c].next_jump = inputs[c].jmp == 1
			update = true
		if update:
			characters[c].update_state()


func _on_Color_changed(color: Color) -> void:
	player.color = color
	Connection.send_player_color(color)
	Connection.send_player_color_update(color)


func _on_Color_updated(id: String, color: Color) -> void:
	if characters.has(id):
		characters[id].color = color
