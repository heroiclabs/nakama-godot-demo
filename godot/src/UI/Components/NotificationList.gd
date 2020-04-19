# List of notifications that appear when users join or leave the game.
extends Control

const Notification := preload("res://src/UI/Elements/Notification.tscn")


func add_notification(username: String, color: Color, disconnected := false) -> void:
	if not Notification:
		return
	var notification := Notification.instance()
	add_child(notification)
	notification.setup(username, color, disconnected)
