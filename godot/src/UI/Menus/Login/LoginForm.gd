# Control panel that manages logging into an existing account.
extends ConnectionControl

signal register_pressed

onready var open_register := $HBoxContainer/RegisterButton
onready var login := $HBoxContainer/LoginButton

onready var email := $Email/LineEditValidate
onready var password := $Password/LineEditValidate

onready var remember_email := $RememberEmail


func _ready() -> void:
	status = $StatusPanel

	#warning-ignore: return_value_discarded
	login.connect("pressed", self, "_on_Login_pressed")
	#warning-ignore: return_value_discarded
	open_register.connect("button_down", self, "emit_signal", ["closed"])

	email.text = Connection.get_last_email()
	if not email.text.empty():
		remember_email.pressed = true

	email.grab_focus()


func _disable_input(value: bool) -> void:
	email.editable = not value
	password.editable = not value
	login.disabled = value
	open_register.disabled = value


func _on_LoginButton_pressed() -> void:
	if not email.is_valid:
		_set_status("The email address is not valid")
		return
	if password.text == "":
		_set_status("Please enter your password to log in")
		return
	if password.text.length() < 8:
		_set_status("The password should be at least 8 characters long")
		return

	_set_status("Authenticating...")
	_disable_input(true)

	var result: int = yield(Connection.login_async(email.text, password.text), "completed")
	if result != OK:
		status.show()
		_set_status(Connection.error_message)
	else:
		status.hide()
		if remember_email.pressed:
			Connection.save_email(email.text)
		yield(do_connect(), "completed")

	_disable_input(false)


func _on_RegisterButton_pressed() -> void:
	emit_signal("register_pressed")
