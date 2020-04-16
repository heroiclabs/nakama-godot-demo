# Control panel that manages logging into an existing account.
extends ConnectionControl

onready var open_register := $Buttons/Register
onready var login := $Buttons/Login

onready var email := $Email/LineEdit
onready var password := $Password/LineEdit

onready var remember_email := $RememberEmail


func _ready() -> void:
	status = $Panel/Status

	#warning-ignore: return_value_discarded
	login.connect("pressed", self, "_on_Login_pressed")
	#warning-ignore: return_value_discarded
	open_register.connect("button_down", self, "emit_signal", ["control_closed"])

	email.text = Connection.get_last_email()
	if not email.text.empty():
		remember_email.pressed = true

	email.grab_focus()


func _disable_input(value: bool) -> void:
	email.editable = not value
	password.editable = not value
	login.disabled = value
	open_register.disabled = value


func _on_Login_pressed() -> void:
	_set_status("Authenticating...")
	_disable_input(true)

	var result: int = yield(Connection.login_async(email.text, password.text), "completed")
	if result != OK:
		_set_status(Connection.error_message)
	else:
		if remember_email.pressed:
			Connection.save_email(email.text)
		yield(do_connect(), "completed")

	_disable_input(false)
