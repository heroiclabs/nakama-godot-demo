extends ConnectionControl

onready var register := $PanelContainer/MarginContainer/VBoxContainer/Buttons/Register
onready var cancel := $PanelContainer/MarginContainer/VBoxContainer/Buttons/Cancel

onready var new_email := $PanelContainer/MarginContainer/VBoxContainer/Email/LineEdit
onready var new_username := $PanelContainer/MarginContainer/VBoxContainer/Username/LineEdit
onready var new_password := $PanelContainer/MarginContainer/VBoxContainer/Password/LineEdit
onready var new_password_confirm := $PanelContainer/MarginContainer/VBoxContainer/RPassword/LineEdit

onready var register_remember_email := $PanelContainer/MarginContainer/VBoxContainer/RememberEmail
onready var preview_texture := $PanelContainer/MarginContainer/VBoxContainer/Color/TextureRect


func _ready() -> void:
	status = $PanelContainer/MarginContainer/VBoxContainer/CenterContainer/Status
	
	#warning-ignore: return_value_discarded
	register.connect("button_down", self, "_on_Register_down")
	#warning-ignore: return_value_discarded
	cancel.connect("button_down", self, "emit_signal", ["control_closed"])


func set_status(text: String) -> void:
	status.text = text


func _disable_input(value: bool) -> void:
	cancel.disabled = value
	register.disabled = value
	new_email.editable = not value
	new_username.editable = not value
	new_password.editable = not value
	new_password_confirm.editable = not value


func is_valid() -> bool:
	if new_email.text.empty():
		set_status("Email cannot be empty")
		return false
	elif new_username.text.empty():
		set_status("Username cannot be empty")
		return false
	elif new_password.text.empty() or new_password_confirm.text.empty():
		set_status("Password cannot be empty")
		return false
	elif new_password.text.similarity(new_password_confirm.text) != 1:
		set_status("Passwords do not match")
		return false
	
	return true

func _on_Register_down() -> void:
	if not is_valid():
		return
	
	set_status("Authenticating...")
	_disable_input(true)
	var result: int = yield(Connection.register(new_email.text, new_password.text, new_username.text, preview_texture.modulate), "completed")
	
	if result == OK:
		if register_remember_email.pressed:
			Connection.save_email(new_email.text)
		yield(do_connect(), "completed")
	else:
		set_status("Error code %s: %s" % [result, Connection.error_message])
	_disable_input(false)
