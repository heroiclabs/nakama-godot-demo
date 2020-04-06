extends HBoxContainer


signal deleted_down(character_index)

var index: int

onready var texture := $TextureRect
onready var select_button := $Button
onready var delete_button := $Delete


func _ready() -> void:
	#warning-ignore: return_value_discarded
	delete_button.connect("deleted_down", self, "_on_Deleted_down")


func setup(character_index: int, character_name: String, character_color: Color) -> void:
	select_button.text = character_name
	texture.modulate = character_color
	index = character_index


func disable() -> void:
	select_button.disabled = true
	delete_button.disabled = true


func enable() -> void:
	select_button.disabled = false
	delete_button.disabled = false


func _on_Deleted_down() -> void:
	emit_signal("deleted_down", index)
