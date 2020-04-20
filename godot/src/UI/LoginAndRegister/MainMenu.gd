# Aggregate class that holds the login, register, and character select controls
# and manages their visibility.
extends Control

export var CharacterSelect: PackedScene

onready var login_panel := $LoginForm
onready var register_panel := $RegisterForm
onready var characters_panel := $CharactersMenu


func _ready() -> void:
	#warning-ignore: return_value_discarded
	login_panel.connect("closed", self, "_on_RegisterForm_opened")
	#warning-ignore: return_value_discarded
	login_panel.connect("joined_world", self, "_on_Player_joined_world")
	#warning-ignore: return_value_discarded
	register_panel.connect("closed", self, "_on_RegisterForm_closed")
	#warning-ignore: return_value_discarded
	register_panel.connect("joined_world", self, "_on_Player_joined_world")


func _on_RegisterForm_opened() -> void:
	login_panel.hide()
	register_panel.show()


func _on_RegisterForm_closed() -> void:
	login_panel.show()
	register_panel.hide()


func _on_Player_joined_world() -> void:
	characters_panel.show()
	login_panel.hide()
	register_panel.hide()
	characters_panel.setup()
