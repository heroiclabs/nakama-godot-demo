# Aggregate class that holds the login, register, and character select controls
# and manages their visibility.
extends Control

export var CharacterSelect: PackedScene

onready var login_form := $LoginForm
onready var register_form := $RegisterForm

onready var menu_current: Control = login_form setget set_menu_current


func set_menu_current(value: Control) -> void:
	menu_current = value
	if not menu_current:
		return

	for child in get_children():
		child.hide()
	menu_current.show()


func _on_RegisterForm_opened() -> void:
	login_form.hide()
	register_form.show()


func _on_RegisterForm_closed() -> void:
	self.menu_current = login_form


func _on_LoginForm_register_pressed() -> void:
	self.menu_current = register_form
