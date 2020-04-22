# Confirmation popup with yes and no buttons
tool
class_name ConfirmationPopup
extends Panel

signal confirmed
signal cancelled

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
	emit_signal("confirmed")
	hide()


func _on_NoButton_pressed() -> void:
	emit_signal("cancelled")
	hide()
