# Controls the visibility of menus to select, delete, and create a new character.
extends MenuList

signal new_character_requested(name, color)
signal character_deletion_requested(index)

onready var character_selector := $CharacterSelector
onready var character_creator := $CharacterCreator
onready var confirmation_popup := $ConfirmationPopup


func _ready() -> void:
	self.menu_current = character_selector


func _on_CharacterCreator_new_character_requested(name: String, color: Color) -> void:
	emit_signal("new_character_requested", name, color)


func _on_CharacterSelector_create_pressed() -> void:
	pass  # Replace with function body.


func _on_CharacterSelector_login_pressed() -> void:
	pass  # Replace with function body.
