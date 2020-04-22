# A notification that scales up to appear on the screen,
# stays for a few instants, and fades out slowly.
extends Control

const DURATION_SCALE := 0.25
const DURATION_VISIBLE := 2.0
const DURATION_FADE_OUT := 2.0

onready var label: RichTextLabel = $RichTextLabel
onready var tween: Tween = $Tween


func _ready() -> void:
	rect_pivot_offset = rect_size
	rect_scale = Vector2.ZERO


func setup(username: String, color := Color.white, disconnected := false) -> void:
	label.bbcode_text = (
		"[color=#%s]%s[/color] %s"
		% [color.to_html(false), username, "left" if disconnected else "joined"]
	)
# warning-ignore:return_value_discarded
	tween.interpolate_property(
		self,
		"rect_scale",
		Vector2.ZERO,
		Vector2.ONE,
		DURATION_SCALE,
		Tween.TRANS_LINEAR,
		Tween.EASE_OUT
	)
# warning-ignore:return_value_discarded
	tween.interpolate_property(
		self,
		"modulate",
		Color.white,
		Color.transparent,
		DURATION_FADE_OUT,
		Tween.TRANS_LINEAR,
		Tween.EASE_IN_OUT,
		DURATION_SCALE + DURATION_VISIBLE
	)
# warning-ignore:return_value_discarded
	tween.start()
	yield(tween, "tween_all_completed")
	queue_free()
