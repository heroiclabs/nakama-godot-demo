# Control panel that enables the changing of character's color on the fly with sliders.
extends Control

signal color_changed(color)

onready var texture_preview := $CenterContainer/VBoxContainer/TextureRect

var color := Color.white setget set_color


func set_color(value: Color) -> void:
	color = value
	texture_preview.modulate = color


func _on_OkButton_pressed() -> void:
	color = texture_preview.modulate
	emit_signal("color_changed", color)
	hide()


func _on_CancelButton_pressed() -> void:
	texture_preview.modulate = color
	hide()
