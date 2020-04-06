extends Control

export var Notification: PackedScene


func add_notification(username: String, color: Color, disconnected := false) -> void:
	if not Notification:
		return
	var notification := Notification.instance()
	add_child(notification)
	notification.setup(username, color, disconnected)
