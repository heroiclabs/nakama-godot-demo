# Control panel that manages creating a new account.
extends Control

signal register_pressed(email, password, do_remember_email)
signal cancel_pressed

onready var register_button: Button = $HBoxContainer/RegisterButton
onready var cancel_button: Button = $HBoxContainer/CancelButton

onready var field_email: LineEdit = $Email/LineEditValidate
onready var field_password: LineEdit = $Password/LineEditValidate
onready var field_password_repeat: LineEdit = $PasswordRepeat/LineEditValidate

onready var remember_email: CheckBox = $RememberEmail
onready var status_panel := $StatusPanel

var is_enabled := true setget set_is_enabled


func set_is_enabled(value: bool) -> void:
	is_enabled = value
	if not cancel_button:
		yield(self, "ready")
	cancel_button.disabled = value
	register_button.disabled = value
	field_email.editable = not value
	field_password.editable = not value
	field_password_repeat.editable = not value



func update_status(text: String) -> void:
	status_panel.text = text


func _on_RegisterButton_pressed() -> void:
	
	if field_email.text.empty():
		update_status("Email cannot be empty")
		return
	elif field_password.text.empty() or field_password_repeat.text.empty():
		update_status("Password cannot be empty")
		return
	elif field_password.text.similarity(field_password_repeat.text) != 1:
		update_status("Passwords do not match")
		return
	
	emit_signal("register_pressed", field_email.text, field_password.text, remember_email.pressed)


func _on_CancelButton_pressed() -> void:
	emit_signal("cancel_pressed")
	hide()
