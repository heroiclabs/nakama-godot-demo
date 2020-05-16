extends Control


onready var column: VBoxContainer = $VBoxContainer


func write_message(text: String) -> void:
	var label := Label.new()
	label.text = text
	label.align = Label.ALIGN_CENTER
	column.add_child(label)
