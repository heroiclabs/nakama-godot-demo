extends Control


export var WorldScene: PackedScene

var state_positions: Dictionary
var state_inputs: Dictionary
var world: Node

onready var login_panel := $Login
onready var register_panel := $Register


func _ready() -> void:
	#warning-ignore: return_value_discarded
	login_panel.connect("control_closed", self, "_on_Register_opened")
	#warning-ignore: return_value_discarded
	login_panel.connect("joined_world", self, "_on_Player_joined_world")
	#warning-ignore: return_value_discarded
	register_panel.connect("control_closed", self, "_on_Register_closed")
	#warning-ignore: return_value_discarded
	register_panel.connect("joined_world", self, "_on_Player_joined_world")
	#warning-ignore: return_value_discarded
	Connection.connect("state_updated", self, "_on_state_updated")


func _on_Register_opened() -> void:
	login_panel.visible = false
	register_panel.visible = true


func _on_Register_closed() -> void:
	login_panel.visible = true
	register_panel.visible = false


func _on_Player_joined_world() -> void:
	if WorldScene:
		world = WorldScene.instance()
		get_tree().root.add_child(world)
		if state_positions.size() > 0:
			world.join_world(Connection.username, state_positions, state_inputs)
			queue_free()


func _on_state_updated(positions: Dictionary, inputs: Dictionary) -> void:
	state_positions = positions
	state_inputs = inputs
	if world:
		world.join_world(Connection.username, state_positions, state_inputs)
		queue_free()
