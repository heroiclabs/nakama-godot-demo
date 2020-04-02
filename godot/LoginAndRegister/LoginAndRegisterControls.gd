extends Control


export var WorldScene: PackedScene

var player_position := Vector2.ZERO

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
	Connection.connect("position_updated", self, "_on_position_updated")


func _on_Register_opened() -> void:
	login_panel.visible = false
	register_panel.visible = true


func _on_Register_closed() -> void:
	login_panel.visible = true
	register_panel.visible = false


func _on_Player_joined_world() -> void:
	if WorldScene:
		var world := WorldScene.instance()
		get_tree().root.add_child(world)
		world.join_world(Connection.username, player_position)
		queue_free()


func _on_position_updated(id: String, position: Vector2) -> void:
	if id == Connection.session.user_id:
		player_position = position
