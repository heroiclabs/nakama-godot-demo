extends TextureButton

const COLOR_HOVER := Color("#0d9ad1")
const COLOR_PRESSED := Color("#1973dc")


func _on_mouse_entered() -> void:
	modulate = COLOR_HOVER


func _on_mouse_exited() -> void:
	modulate = Color.white


func _on_button_down() -> void:
	modulate = COLOR_PRESSED


func _on_button_up() -> void:
	modulate = COLOR_HOVER if is_hovered() else Color.white
