# Control panel that manages creating a new account.
extends ConnectionControl

onready var register := $MarginContainer/VBoxContainer/Buttons/Register
onready var cancel := $MarginContainer/VBoxContainer/Buttons/Cancel

onready var new_email := $MarginContainer/VBoxContainer/Email/LineEdit
onready var new_password := $MarginContainer/VBoxContainer/Password/LineEdit
onready var new_password_confirm := $MarginContainer/VBoxContainer/RPassword/LineEdit

onready var register_remember_email := $MarginContainer/VBoxContainer/RememberEmail


func _ready() -> void:
	status = $MarginContainer/VBoxContainer/CenterContainer/Status

	#warning-ignore: return_value_discarded
	register.connect("button_down", self, "_on_Register_down")
	#warning-ignore: return_value_discarded
	cancel.connect("button_down", self, "emit_signal", ["control_closed"])


func _disable_input(value: bool) -> void:
	cancel.disabled = value
	register.disabled = value
	new_email.editable = not value
	new_password.editable = not value
	new_password_confirm.editable = not value


func is_valid() -> bool:
	if new_email.text.empty():
		_set_status("Email cannot be empty")
		return false
	elif new_password.text.empty() or new_password_confirm.text.empty():
		_set_status("Password cannot be empty")
		return false
	elif new_password.text.similarity(new_password_confirm.text) != 1:
		_set_status("Passwords do not match")
		return false

	return true


func _on_Register_down() -> void:
	if not is_valid():
		return

	_set_status("Authenticating...")
	_disable_input(true)
	
	var result: int = yield(
		Connection.register_async(new_email.text, new_password.text), "completed"
	)
	if result == OK:
		if register_remember_email.pressed:
			Connection.save_email(new_email.text)
		
		yield(do_connect(), "completed")
	else:
		_set_status("Error code %s: %s" % [result, Connection.error_message])
	
	_disable_input(false)
