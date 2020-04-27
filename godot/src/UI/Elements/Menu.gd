# Abstract base class for menus. Defines a minimal interface for the game's menus, so classes like
# `MenuList` can use it safely. Extend this class's methods to add functionality.
class_name Menu
extends Control

signal open
signal closed

var is_enabled := true setget set_is_enabled

var status := "" setget set_status


func open() -> void:
	show()
	emit_signal("open")


func close() -> void:
	hide()
	emit_signal("closed")


func reset() -> void:
	pass


func set_is_enabled(value: bool) -> void:
	is_enabled = value


func set_status(value: String) -> void:
	status = value
