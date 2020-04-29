# Interface to create a new character. Allows you to pick a color from a palette and set the
# character's name.
extends Menu

signal new_character_requested(name, color)

onready var create_button := $VBoxContainer/CreateButton
onready var name_field := $VBoxContainer/HBoxContainer/LineEdit
onready var color_selector := $VBoxContainer/Color/ColorSelector


func set_is_enabled(value: bool) -> void:
	.set_is_enabled(value)
	if not create_button:
		yield(self, "ready")
	create_button.disabled = not value
	name_field.editable = value


func open() -> void:
	.open()
	color_selector.focus_first_swatch()


func request_character_creation() -> void:
	if name_field.text.length() == 0:
		return
	emit_signal("new_character_requested", name_field.text, color_selector.color)
	close()


func _on_CreateButton_pressed() -> void:
	request_character_creation()


func _on_LineEdit_text_entered(_new_text: String) -> void:
	request_character_creation()
