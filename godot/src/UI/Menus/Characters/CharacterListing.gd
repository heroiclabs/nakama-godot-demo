# A flat button representing a listing for a single character
class_name CharacterListing
extends Button

signal requested_deletion(character_index)
signal character_selected(index)

var is_enabled := true setget set_is_enabled

onready var texture := $HBoxContainer/TextureRect
onready var label := $HBoxContainer/Label
onready var delete_button := $HBoxContainer/DeleteButton


func setup(character_name: String, character_color: Color) -> void:
	label.text = character_name
	texture.modulate = character_color


func get_name() -> String:
	return label.text


func set_is_enabled(value: bool) -> void:
	is_enabled = value
	if not delete_button:
		yield(self, "ready")
	disabled = not is_enabled
	delete_button.disabled = not is_enabled


func _on_pressed() -> void:
	emit_signal("character_selected", get_position_in_parent())


func _on_DeleteButton_pressed() -> void:
	emit_signal("requested_deletion", get_position_in_parent())
