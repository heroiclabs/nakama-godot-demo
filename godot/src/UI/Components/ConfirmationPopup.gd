# Confirmation popup with yes and no buttons
tool
class_name ConfirmationPopup
extends Menu

signal option_picked(is_confirmed)

export var text := "Label" setget set_text

onready var label: Label = $Label


func _ready() -> void:
	hide()


func set_text(value: String) -> void:
	text = value
	if not label:
		yield(self, "ready")
	label.text = text


func _on_YesButton_pressed() -> void:
	emit_signal("option_picked", true)
	close()


func _on_NoButton_pressed() -> void:
	emit_signal("option_picked", false)
	close()
