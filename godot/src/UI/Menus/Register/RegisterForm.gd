# Interface to register a new account.
extends Menu

signal register_pressed(email, password, do_remember_email)
signal cancel_pressed

onready var register_button: Button = $HBoxContainer/RegisterButton
onready var cancel_button: Button = $HBoxContainer/CancelButton

onready var email_field: LineEdit = $Email/LineEditValidate
onready var password_field: LineEdit = $Password/LineEditValidate
onready var password_field_repeat: LineEdit = $PasswordRepeat/LineEditValidate

onready var remember_email: CheckBox = $RememberEmail
onready var status_panel := $StatusPanel


func set_is_enabled(value: bool) -> void:
	.set_is_enabled(value)
	if not cancel_button:
		yield(self, "ready")
	cancel_button.disabled = not value
	register_button.disabled = not value
	email_field.editable = value
	password_field.editable = value
	password_field_repeat.editable = value


func set_status(text: String) -> void:
	.set_status(text)
	status_panel.text = text


func reset() -> void:
	.reset()
	self.status = ""
	password_field.text = ""
	password_field_repeat.text = ""
	email_field.text = ""


func attempt_register() -> void:
	if email_field.text.empty():
		self.status = "Email cannot be empty"
		return
	elif password_field.text.empty() or password_field_repeat.text.empty():
		self.status = "Password cannot be empty"
		return
	elif password_field.text.similarity(password_field_repeat.text) != 1:
		self.status = "Passwords do not match"
		return

	emit_signal("register_pressed", email_field.text, password_field.text, remember_email.pressed)


func _on_RegisterButton_pressed() -> void:
	attempt_register()


func _on_CancelButton_pressed() -> void:
	emit_signal("cancel_pressed")
	hide()


# Connected to all three LineEditValidate in the scene
func _on_LineEditValidate_text_entered(_new_text: String) -> void:
	attempt_register()


func _on_open() -> void:
	email_field.grab_focus()
