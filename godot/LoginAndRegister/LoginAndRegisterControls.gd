extends Control

export var CharacterSelect: PackedScene

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


func _on_Register_opened() -> void:
	login_panel.hide()
	register_panel.show()


func _on_Register_closed() -> void:
	login_panel.show()
	register_panel.hide()


func _on_Player_joined_world() -> void:
	if CharacterSelect:
		get_parent().add_child(CharacterSelect.instance())
		queue_free()
