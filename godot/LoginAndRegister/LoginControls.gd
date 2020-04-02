extends ConnectionControl

onready var open_register := $PanelContainer/MarginContainer/VBoxContainer/Buttons/Register
onready var login := $PanelContainer/MarginContainer/VBoxContainer/Buttons/Login

onready var email := $PanelContainer/MarginContainer/VBoxContainer/Email/LineEdit
onready var password := $PanelContainer/MarginContainer/VBoxContainer/Password/LineEdit

onready var remember_email := $PanelContainer/MarginContainer/VBoxContainer/RememberEmail


func _ready() -> void:
	status = $PanelContainer/MarginContainer/VBoxContainer/CenterContainer/Status
	
	#warning-ignore: return_value_discarded
	login.connect("button_down", self, "_on_Login_down")
	#warning-ignore: return_value_discarded
	open_register.connect("button_down", self, "emit_signal", ["control_closed"])
	
	email.text = Connection.get_last_email()
	if not email.text.empty():
		remember_email.pressed = true


func _disable_input(value: bool) -> void:
	email.editable = not value
	password.editable = not value
	login.disabled = value
	open_register.disabled = value


func _on_Login_down() -> void:
	set_status("Authenticating...")
	_disable_input(true)
	
	var result: int = yield(Connection.login(email.text, password.text), "completed")
	if result != OK:
		set_status("Error code %s: %s" % [result, Connection.error_message])
	else:
		if remember_email.pressed:
			Connection.save_email(email.text)
		yield(do_connect(), "completed")
	
	_disable_input(false)
