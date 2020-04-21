# Control panel that manages creating a new account.
extends ConnectionControl

onready var register_button : Button= $HBoxContainer/RegisterButton
onready var cancel_button : Button= $HBoxContainer/CancelButton

onready var field_email :LineEdit= $Email/LineEdit
onready var field_password :LineEdit= $Password/LineEdit
onready var field_password_repeat :LineEdit= $Password2/LineEdit

onready var register_remember_email : CheckBox= $RememberEmail

var is_enabled := true setget set_is_enabled


func _ready() -> void:
	status = $StatusPanel


func set_is_enabled(value: bool) -> void:
	is_enabled = value
	if not cancel_button:
		yield(self, "ready")
	cancel_button.disabled = value
	register_button.disabled = value
	field_email.editable = not value
	field_password.editable = not value
	field_password_repeat.editable = not value


func is_valid() -> bool:
	var is_valid := false

	if field_email.text.empty():
		_set_status("Email cannot be empty")
	elif field_password.text.empty() or field_password_repeat.text.empty():
		_set_status("Password cannot be empty")
	elif field_password.text.similarity(field_password_repeat.text) != 1:
		_set_status("Passwords do not match")
	else:
		is_valid = true

	return is_valid


func _on_RegisterButton_pressed() -> void:
	if not is_valid():
		return

	_set_status("Authenticating...")
	self.is_enabled = false

	var result: int = yield(
		Connection.register_async(field_email.text, field_password.text), "completed"
	)
	if result == OK:
		if register_remember_email.pressed:
			Connection.save_email(field_email.text)
		yield(do_connect(), "completed")
	else:
		_set_status("Error code %s: %s" % [result, Connection.error_message])

	self.is_enabled = true


func _on_CancelButton_pressed() -> void:
	emit_signal("closed")
	hide()
