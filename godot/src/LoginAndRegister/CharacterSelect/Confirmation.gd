# Control panel to confirm whether or not to delete a character
extends PanelContainer

#warning-ignore: unused_signal
signal confirmed
#warning-ignore: unused_signal
signal cancelled


func _ready() -> void:
	#warning-ignore: return_value_discarded
	$MarginContainer/VBoxContainer/HBoxContainer/Yes.connect(
		"button_down", self, "emit_signal", ["confirmed"]
	)
	#warning-ignore: return_value_discarded
	$MarginContainer/VBoxContainer/HBoxContainer/No.connect(
		"button_down", self, "emit_signal", ["cancelled"]
	)
