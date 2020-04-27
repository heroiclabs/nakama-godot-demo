extends GridContainer

signal color_changed(new_value)

var color := Color.white

var disabled := false setget set_disabled


func _ready() -> void:
	for swatch in get_children():
		swatch.connect("pressed", self, "_on_ColorSwatch_pressed", [swatch.color])


func set_disabled(value: bool) -> void:
	disabled = value
	for button in get_children():
		button.disabled = disabled


func focus_first_swatch() -> void:
	get_child(0).grab_focus()


func _on_ColorSwatch_pressed(selected_color: Color) -> void:
	color = selected_color
	emit_signal("color_changed", color)
