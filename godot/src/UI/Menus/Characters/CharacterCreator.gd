# Editor panel for creating new characters. Allows you to pick a color from a palette and set the character's name.
extends Control

signal character_created(name, color)

onready var create := $VBoxContainer/CreateButton
onready var name_field := $VBoxContainer/HBoxContainer/LineEdit
onready var color_selector := $VBoxContainer/Color/ColorSelector


func _ready() -> void:
	#warning-ignore: return_value_discarded
	create.connect("button_down", self, "_on_Create_down")


func disable() -> void:
	modulate = Color.gray
	create.disabled = true
	name_field.editable = false


func enable() -> void:
	modulate = Color.white
	create.disabled = false
	name_field.editable = true


func _on_CreateButton_pressed() -> void:
	if name_field.text.length() == 0:
		return
	emit_signal("character_created", name_field.text, color_selector.color)
