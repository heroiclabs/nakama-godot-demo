# Interface to register a new account.
extends Menu

signal register_pressed(email, password, do_remember_email)
signal cancel_pressed

onready var register_button: Button = $HBoxContainer/RegisterButton
onready var cancel_button: Button = $HBoxContainer/CancelButton

onready var field_email: LineEdit = $Email/LineEditValidate
onready var field_password: LineEdit = $Password/LineEditValidate
onready var field_password_repeat: LineEdit = $PasswordRepeat/LineEditValidate

onready var remember_email: CheckBox = $RememberEmail
onready var status_panel := $StatusPanel


func set_is_enabled(value: bool) -> void:
	.set_is_enabled(value)
	if not cancel_button:
		yield(self, "ready")
	cancel_button.disabled = not value
	register_button.disabled = not value
	field_email.editable = value
	field_password.editable = value
	field_password_repeat.editable = value


func set_status(text: String) -> void:
	.set_status(text)
	status_panel.text = text


func _on_RegisterButton_pressed() -> void:
	if field_email.text.empty():
		self.status = "Email cannot be empty"
		return
	elif field_password.text.empty() or field_password_repeat.text.empty():
		self.status = "Password cannot be empty"
		return
	elif field_password.text.similarity(field_password_repeat.text) != 1:
		self.status = "Passwords do not match"
		return

	emit_signal("register_pressed", field_email.text, field_password.text, remember_email.pressed)


func _on_CancelButton_pressed() -> void:
	emit_signal("cancel_pressed")
	hide()
