# Character selection menu
extends Control

signal new_character_requested(name, color)

onready var character_selector := $CharacterSelector
onready var character_creator := $CharacterCreator
onready var characters_menu := $ConfirmationPopup

onready var menu_current := character_selector setget set_menu_current


func set_menu_current(value: Control) -> void:
	menu_current = value
	if not menu_current:
		return

	for child in get_children():
		child.hide()
	menu_current.show()


func _on_CharacterCreator_new_character_requested(name: String, color: Color) -> void:
	emit_signal("new_character_requested", name, color)
