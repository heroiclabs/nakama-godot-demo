# Confirmation popup with yes and no buttons
extends Panel

#warning-ignore: unused_signal
signal confirmed
#warning-ignore: unused_signal
signal cancelled


func _ready() -> void:
	#warning-ignore: return_value_discarded
	$YesButton.connect(
		"button_down", self, "emit_signal", ["confirmed"]
	)
	#warning-ignore: return_value_discarded
	$NoButton.connect(
		"button_down", self, "emit_signal", ["cancelled"]
	)
