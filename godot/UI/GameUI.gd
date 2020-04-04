extends Control


signal color_changed(color)

var color: Color

onready var color_picker := $ColorUI
onready var change_color := $PanelContainer/MarginContainer/VBoxContainer/ChangeColor


func _ready() -> void:
	#warning-ignore: return_value_discarded
	color_picker.connect("color_changed", self, "_on_Color_changed")
	#warning-ignore: return_value_discarded
	change_color.connect("button_down", self, "_on_Change_Color_down")


func setup(_color: Color) -> void:
	color = _color
	color_picker.setup(color)


func _on_Change_Color_down() -> void:
	color_picker.show()


func _on_Color_changed(_color: Color) -> void:
	color = _color
	color_picker.setup(color)
	emit_signal("color_changed", color)
	color_picker.hide()
