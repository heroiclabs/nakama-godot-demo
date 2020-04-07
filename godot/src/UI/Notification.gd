# A script that reprents a notification that pops up, then fades away.
extends PanelContainer

onready var label := $MarginContainer/Label
onready var tween := $Tween


func setup(username: String, color: Color, disconnected := false) -> void:
	label.bbcode_text = (
		"[color=#%s]%s[/color] %s"
		% [color.to_html(false), username, "left" if disconnected else "joined"]
	)
	tween.interpolate_property(
		self, "rect_scale", Vector2.ZERO, Vector2.ONE, 0.25, Tween.TRANS_LINEAR, Tween.EASE_OUT
	)
	tween.interpolate_property(
		self,
		"modulate",
		Color.white,
		Color.transparent,
		3.0,
		Tween.TRANS_LINEAR,
		Tween.EASE_IN_OUT,
		1.5
	)
	tween.interpolate_property(
		self, "rect_scale", Vector2.ONE, Vector2.ZERO, 0.25, Tween.TRANS_LINEAR, Tween.EASE_OUT, 4.5
	)
	tween.start()
	yield(tween, "tween_all_completed")
	queue_free()
