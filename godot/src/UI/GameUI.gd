# Main game ui control that acts as a go-between with the various in-game ui
# controls that the world can react to.
extends Control

signal color_changed(color)
signal text_sent(text)
signal editing(value)

var color: Color

onready var color_picker := $ColorUI
onready var change_color := $ChangeColorPanel/ChangeColor
onready var chat_ui := $ChatUI
onready var notifications_ui := $NotificationsUI


func _ready() -> void:
	#warning-ignore: return_value_discarded
	color_picker.connect("color_changed", self, "_on_Color_changed")
	#warning-ignore: return_value_discarded
	change_color.connect("button_down", self, "_on_Change_Color_down")
	#warning-ignore: return_value_discarded
	chat_ui.connect("text_sent", self, "_on_Chat_text_Sent")
	#warning-ignore: return_value_discarded
	chat_ui.connect("editing", self, "_on_Chat_editing")


func setup(_color: Color) -> void:
	color = _color
	color_picker.setup(color)


func add_text(text: String, sender: String, text_color: Color) -> void:
	chat_ui.add_text(text, sender, text_color)


func add_notification(username: String, text_color: Color, disconnected := false) -> void:
	notifications_ui.add_notification(username, text_color, disconnected)


func _on_Change_Color_down() -> void:
	color_picker.show()


func _on_Color_changed(_color: Color) -> void:
	color = _color
	color_picker.setup(color)
	emit_signal("color_changed", color)
	color_picker.hide()


func _on_Chat_text_Sent(text: String) -> void:
	emit_signal("text_sent", text)


func _on_Chat_editing(value: bool) -> void:
	emit_signal("editing", value)
