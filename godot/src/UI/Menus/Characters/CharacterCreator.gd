# Interface to create a new character. Allows you to pick a color from a palette and set the
# character's name.
extends Menu

signal new_character_requested(name, color)

onready var create_button := $VBoxContainer/CreateButton
onready var name_field := $VBoxContainer/HBoxContainer/LineEdit
onready var color_selector := $VBoxContainer/Color/ColorSelector


func _ready() -> void:
	#warning-ignore: return_value_discarded
	create_button.connect("button_down", self, "_on_Create_down")


func set_is_enabled(value: bool) -> void:
	.set_is_enabled(value)
	if not create_button:
		yield(self, "ready")
	create_button.disabled = value
	name_field.editable = value


func _on_CreateButton_pressed() -> void:
	if name_field.text.length() == 0:
		return
	emit_signal("new_character_requested", name_field.text, color_selector.color)


func _on_ConfirmationPopup_confirmed() -> void:
	pass  # Replace with function body.


func _on_ConfirmationPopup_cancelled() -> void:
	pass  # Replace with function body.
