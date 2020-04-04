extends Control


signal color_changed(color)

onready var texture_preview := $PanelContainer/MarginContainer/VBoxContainer/Color/TextureRect
onready var accept := $PanelContainer/MarginContainer/VBoxContainer/HBoxContainer/Accept
onready var cancel := $PanelContainer/MarginContainer/VBoxContainer/HBoxContainer/Cancel
onready var red := $PanelContainer/MarginContainer/VBoxContainer/Color/VBoxContainer/Red
onready var green := $PanelContainer/MarginContainer/VBoxContainer/Color/VBoxContainer/Green
onready var blue := $PanelContainer/MarginContainer/VBoxContainer/Color/VBoxContainer/Blue


func _ready() -> void:
	#warning-ignore: return_value_discarded
	accept.connect("button_down", self, "_on_Accept_button_down")
	#warning-ignore: return_value_discarded
	cancel.connect("button_down", self, "hide")


func setup(color: Color) -> void:
	red.value = color.r
	green.value = color.g
	blue.value = color.b


func _on_Accept_button_down() -> void:
	var color: Color = texture_preview.modulate
	hide()
	emit_signal("color_changed", color)
