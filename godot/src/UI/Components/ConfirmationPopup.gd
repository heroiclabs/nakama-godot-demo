@tool
# Confirmation popup with yes and no buttons
class_name ConfirmationPopup
extends Menu

signal option_picked(is_confirmed)

@export var text := "Label": set = set_text

@onready var label: Label = $Label
@onready var yes_button: Button = $YesButton


func _ready() -> void:
	hide()


func set_text(value: String) -> void:
	text = value
	if not label:
		await self.ready
	label.text = text


func open() -> void:
	super.open()
	yes_button.grab_focus()


func _on_YesButton_pressed() -> void:
	emit_signal("option_picked", true)
	close()


func _on_NoButton_pressed() -> void:
	emit_signal("option_picked", false)
	close()
