extends Panel

var text := "": set = set_text

@onready var label := $Label


func _ready() -> void:
	self.text = ""


func set_text(value: String) -> void:
	text = value
	if label:
		label.text = value
