extends TextureRect

export var red_path := NodePath()
export var green_path := NodePath()
export var blue_path := NodePath()

onready var red_slider: HSlider = get_node(red_path)
onready var green_slider: HSlider = get_node(green_path)
onready var blue_slider: HSlider = get_node(blue_path)


func _ready() -> void:
	#warning-ignore: return_value_discarded
	red_slider.connect("value_changed", self, "_on_colors_changed")
	#warning-ignore: return_value_discarded
	green_slider.connect("value_changed", self, "_on_colors_changed")
	#warning-ignore: return_value_discarded
	blue_slider.connect("value_changed", self, "_on_colors_changed")


func _on_colors_changed(_value: float) -> void:
	modulate = Color(red_slider.value, green_slider.value, blue_slider.value)
