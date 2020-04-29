# A flat button representing a listing for a single character
class_name CharacterListing
extends Button

signal requested_deletion(character_index)
signal character_selected(index)
signal character_accepted(index)

var is_enabled := true setget set_is_enabled

onready var texture := $HBoxContainer/TextureRect
onready var label := $HBoxContainer/Label
onready var delete_button := $HBoxContainer/DeleteButton


func _gui_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"):
		emit_signal("character_accepted", get_position_in_parent())
		accept_event()
	if event is InputEventMouseButton and event.doubleclick:
		emit_signal("character_accepted", get_position_in_parent())
		accept_event()


func setup(character_name: String, character_color: Color) -> void:
	label.text = character_name
	texture.modulate = character_color


func set_is_enabled(value: bool) -> void:
	is_enabled = value
	if not delete_button:
		yield(self, "ready")
	disabled = not is_enabled
	delete_button.disabled = not is_enabled


func _on_DeleteButton_pressed() -> void:
	emit_signal("requested_deletion", get_position_in_parent())


func _on_focus_entered() -> void:
	emit_signal("character_selected", get_position_in_parent())
