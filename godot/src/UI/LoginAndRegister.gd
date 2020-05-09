# The game's main menu. Aggregates the LoginForm and RegisterForm.
# Emits signals with relevant information for a parent node to communicate with the game server.
extends MenuList

signal login_pressed(email, password, do_remember_email)
signal register_pressed(email, password, do_remember_email)

onready var login_form := $LoginForm
onready var register_form := $RegisterForm

var status := "" setget set_status


func _ready() -> void:
	self.menu_current = login_form


func set_status(value: String) -> void:
	status = value
	menu_current.status = status


func reset() -> void:
	status = ""
	for child in get_children():
		child.reset()
	self.menu_current = login_form
	is_enabled = true


func _on_LoginForm_register_pressed() -> void:
	self.menu_current = register_form


func _on_LoginForm_login_pressed(email: String, password: String, do_remember_email: bool) -> void:
	emit_signal("login_pressed", email, password, do_remember_email)


func _on_RegisterForm_register_pressed(email: String, password: String, do_remember_email: bool) -> void:
	emit_signal("register_pressed", email, password, do_remember_email)


func _on_RegisterForm_cancel_pressed() -> void:
	self.menu_current = login_form
