extends Button

const icon_pressed := preload("res://assets/theme/icons/chevron-right.svg")
const icon_released := preload("res://assets/theme/icons/chevron-up.svg")


func _on_toggled(button_pressed: bool) -> void:
	icon = icon_pressed if button_pressed else icon_released
