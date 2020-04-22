# Base class that exposes some common functionality for Login and Register controls
class_name ConnectionControl
extends Control

#warning-ignore: unused_signal
signal closed
signal joined_world

var status


# Sets the label to the provided status message
func _set_status(text: String) -> void:
	if status:
		status.text = text
