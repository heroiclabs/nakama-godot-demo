# A flat button representing a listing for a single character
extends Button

signal requested_deletion(character_index)
signal character_selected(character_index)

var index: int = -1
var is_enabled := true setget set_is_enabled

onready var texture := $HBoxContainer/TextureRect
onready var label := $HBoxContainer/Label
onready var delete_button := $HBoxContainer/DeleteButton

func _ready() -> void:
	setup(1, "hello", Color.green)
	self.is_enabled = false

func setup(character_index: int, character_name: String, character_color: Color) -> void:
	label.text = character_name
	texture.modulate = character_color
	index = character_index


func get_name() -> String:
	return label.text


func set_is_enabled(value: bool) -> void:
	is_enabled = value
	if not delete_button:
		yield(self, "ready")
	disabled = not is_enabled
	delete_button.disabled = not is_enabled


func _on_pressed() -> void:
	emit_signal("character_selected", index)


func _on_DeleteButton_pressed() -> void:
	emit_signal("requested_deletion", index)
