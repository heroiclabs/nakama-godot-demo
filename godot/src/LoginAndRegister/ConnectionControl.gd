# Base class that exposes some common functionality for Login and Register controls
class_name ConnectionControl
extends Control

#warning-ignore: unused_signal
signal control_closed
signal joined_world

var status: Label


# Sets the label to the provided status message
func _set_status(text: String) -> void:
	if status:
		status.text = text


# Sends a connection attempt to the server and joins the world match.
func do_connect() -> int:
	_set_status("Connecting...")
	
	var result: int = yield(Connection.connect_to_server_async(), "completed")
	if not result == OK:
		_set_status("Error code %s: %s" % [result, Connection.error_message])
	else:
		_set_status("Connected. Joining world...")
		
		result = yield(Connection.join_world_async(), "completed")
		if not result == OK:
			_set_status("Error code %s: %s" % [result, Connection.error_message])
		else:
			_set_status("Joined world.")
			emit_signal("joined_world")
	return result


func _disable_input(_value: bool) -> void:
	pass
