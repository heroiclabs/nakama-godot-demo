# Main game ui control that acts as a go-between with the various in-game ui
# controls that the world can react to.
extends Control

signal color_changed(color)
signal text_sent(text)
signal editing(value)

onready var color_editor := $CharacterColorEditor
onready var chat_box := $ChatBox
onready var notifications_ui := $NotificationsUI


func setup(_color: Color) -> void:
	color_editor.color = _color


func add_text(text: String, sender: String, text_color: Color) -> void:
	chat_box.add_text(text, sender, text_color)


func add_notification(username: String, text_color: Color, disconnected := false) -> void:
	notifications_ui.add_notification(username, text_color, disconnected)


func _on_ChangeColorButton_pressed() -> void:
	color_editor.show()


func _on_ChatBox_editing(value) -> void:
	emit_signal("editing", value)


func _on_ChatBox_text_sent(text: String) -> void:
	emit_signal("text_sent", text)


func _on_CharacterColorEditor_color_changed(_color: Color) -> void:
	emit_signal("color_changed", _color)
