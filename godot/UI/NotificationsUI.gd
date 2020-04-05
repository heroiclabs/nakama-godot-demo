extends Control


export var Notification: PackedScene

onready var list := $VBoxContainer

func add_notification(username: String, color: Color, disconnected := false) -> void:
	if not Notification:
		return
	var notification := Notification.instance()
	list.add_child(notification)
	notification.setup(username, color, disconnected)
