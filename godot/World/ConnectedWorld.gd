extends Node2D

export var PlayerScene: PackedScene
export var CharacterScene: PackedScene
export var spawn_height: float
export var world_width: float

var player: Node
var characters := {}

onready var world := $World


func join_world(username: String, player_position: Vector2) -> void:
	_setup_player(username, player_position)
	
	var presences := Connection.presences
	for p in presences.keys():
		_setup_character(p, presences[p].username)
	
	#warning-ignore: return_value_discarded
	Connection.connect("presences_changed", self, "_on_Presences_changed")
	#warning-ignore: return_value_discarded
	Connection.connect("position_updated", self, "_on_Position_updated")


func _setup_player(username: String, player_position: Vector2) -> void:
	player = PlayerScene.instance()
	
	world.add_child(player)
	player.username = username
	
	player.global_position = player_position
	player.spawn()


func _setup_character(id: String, username: String) -> void:
	var character: = CharacterScene.instance()
	Connection.request_position_update(id)
	
	#warning-ignore: return_value_discarded
	world.add_child(character)
	character.username = username
	characters[id] = character


func _on_Player_direction_changed(_direction: Vector2) -> void:
	pass


func _on_Player_jumped() -> void:
	pass


func _on_Presences_changed() -> void:
	var presences := Connection.presences
	for p in presences.keys():
		if not characters.has(p):
			_setup_character(p, presences[p].username)
	var despawns := []
	for c in characters.keys():
		if not presences.has(c):
			despawns.append(c)
	for d in despawns:
		characters[d].despawn()
		#warning-ignore: return_value_discarded
		characters.erase(d)


func _on_Position_updated(id: String, position: Vector2) -> void:
	if characters.has(id):
		characters[id].update_position_to(position)
		if not characters[id].spawned:
			characters[id].spawn()
