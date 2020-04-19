# Control panel that manages creating a new account.
extends ConnectionControl

onready var register := $Buttons/Register
onready var cancel := $Buttons/Cancel

onready var field_email := $Email/LineEdit
onready var field_password := $Password/LineEdit
onready var field_password_repeat := $Password2/LineEdit

onready var register_remember_email := $RememberEmail


func _ready() -> void:
	status = $StatusPanel

	#warning-ignore: return_value_discarded
	register.connect("button_down", self, "_on_Register_down")
	#warning-ignore: return_value_discarded
	cancel.connect("button_down", self, "emit_signal", ["control_closed"])


func _disable_input(value: bool) -> void:
	cancel.disabled = value
	register.disabled = value
	field_email.editable = not value
	field_password.editable = not value
	field_password_repeat.editable = not value


func is_valid() -> bool:
	if field_email.text.empty():
		_set_status("Email cannot be empty")
		return false
	elif field_password.text.empty() or field_password_repeat.text.empty():
		_set_status("Password cannot be empty")
		return false
	elif field_password.text.similarity(field_password_repeat.text) != 1:
		_set_status("Passwords do not match")
		return false

	return true


func _on_Register_down() -> void:
	if not is_valid():
		return

	_set_status("Authenticating...")
	_disable_input(true)

	var result: int = yield(
		Connection.register_async(field_email.text, field_password.text), "completed"
	)
	if result == OK:
		if register_remember_email.pressed:
			Connection.save_email(field_email.text)

		yield(do_connect(), "completed")
	else:
		_set_status("Error code %s: %s" % [result, Connection.error_message])

	_disable_input(false)
