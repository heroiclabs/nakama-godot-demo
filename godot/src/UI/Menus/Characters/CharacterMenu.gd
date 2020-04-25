# Controls the visibility of menus to select, delete, and create a new character.
extends MenuList

signal new_character_requested(name, color)
signal character_deletion_requested(index)
signal character_selected(index)

onready var character_selector := $CharacterSelector
onready var character_creator := $CharacterCreator


func _ready() -> void:
	self.menu_current = character_selector


func setup(characters: Array, last_played_character: Dictionary) -> void:
	character_selector.setup(characters, last_played_character)


func add_character(name: String, color: Color) -> void:
	character_selector.character_list.add_character(name, color)

func delete_character(index: int) -> void:
	character_selector.character_list.delete_character(index)

func _on_CharacterSelector_create_pressed() -> void:
	self.menu_current = character_creator


# TODO: need to use name instead for server?
func _on_CharacterSelector_login_pressed(selected_index: int) -> void:
	emit_signal("character_selected", selected_index)


func _on_CharacterCreator_new_character_requested(name: String, color: Color) -> void:
	emit_signal("new_character_requested", name, color)
	self.menu_current = character_selector


func _on_CharacterSelector_character_deletion_requested(index: int) -> void:
	emit_signal("character_deletion_requested", index)
