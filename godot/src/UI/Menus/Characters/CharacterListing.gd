# A control representing a listing for a single character
extends Button

signal requested_deletion(character_index)
signal character_selected(character_index)

var index: int

onready var texture := $HBoxContainer/TextureRect
onready var label := $HBoxContainer/Label
onready var delete_button := $HBoxContainer/DeleteButton


func _ready() -> void:
	#warning-ignore: return_value_discarded
	delete_button.connect("pressed", self, "_on_DeleteButton_down")
	#warning-ignore: return_value_discarded
	connect("pressed", self, "_on_Character_Select_down")


func setup(character_index: int, character_name: String, character_color: Color) -> void:
	label.text = character_name
	texture.modulate = character_color
	index = character_index


func get_name() -> String:
	return label.text


func disable() -> void:
	label.disabled = true
	delete_button.disabled = true


func enable() -> void:
	label.disabled = false
	delete_button.disabled = false


func _on_DeleteButton_down() -> void:
	emit_signal("requested_deletion", index)


func _on_Character_Select_down() -> void:
	emit_signal("character_selected", index)
