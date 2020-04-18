# Control panel that enables the changing of character's color on the fly with sliders.
extends Control

signal color_changed(color)

onready var texture_preview := $VBoxContainer/TextureRect


func _on_OkButton_pressed() -> void:
	var color: Color = texture_preview.modulate
	hide()
	emit_signal("color_changed", color)


func _on_CancelButton_pressed() -> void:
	hide()
