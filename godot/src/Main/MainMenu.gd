# The game's main menu. Aggregates the LoginForm and RegisterForm.
# Emits signals with relevant information for a parent node to communicate with the game server.
extends Control

signal login_pressed(email, password, do_remember_email)
signal register_pressed(email, password, do_remember_email)

var is_enabled := true setget set_is_enabled

onready var login_form := $LoginForm
onready var register_form := $RegisterForm

onready var menu_current: Control = login_form setget set_menu_current

func _ready() -> void:
	self.menu_current = login_form


func set_is_enabled(value: bool) -> void:
	is_enabled = value
	for menu in get_children():
		menu.is_enabled = is_enabled

func set_menu_current(value: Control) -> void:
	menu_current = value
	if not menu_current:
		return

	for menu in get_children():
		menu.hide()
	menu_current.show()


# Updates the status panel of the active menu.
func update_status(text: String) -> void:
	menu_current.status_panel.text = text



func _on_LoginForm_register_pressed() -> void:
	self.menu_current = register_form


func _on_LoginForm_login_pressed(email: String, password: String, do_remember_email: bool) -> void:
	emit_signal("login_pressed", email, password, do_remember_email)


func _on_RegisterForm_register_pressed(email: String, password: String, do_remember_email: bool) -> void:
	emit_signal("register_pressed", email, password, do_remember_email)


func _on_RegisterForm_cancel_pressed() -> void:
	self.menu_current = login_form
