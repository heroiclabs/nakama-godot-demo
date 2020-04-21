# Character selection menu
extends Control

onready var character_selector := $CharacterSelector
onready var register_form := $CharacterColorEditor
onready var characters_menu := $ConfirmationPopup

onready var menu_current := character_selector setget set_menu_current


func set_menu_current(value: Control) -> void:
	menu_current = value
	if not menu_current:
		return

	for child in get_children():
		child.hide()
	menu_current.show()
