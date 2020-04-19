# Control that displays a texture that can be modulated with sliders
extends TextureRect


func _on_ColorSelector_color_changed(new_color: Color) -> void:
	modulate = new_color
