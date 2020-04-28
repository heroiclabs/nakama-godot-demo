# Character class to represent any of the other clients in the world. Reacts
# primarily through events from the server, kept moving using godot's own game loop.
class_name Character
extends KinematicBody2D

signal spawned

enum States { ON_GROUND, IN_AIR }

const SCALE_BASE := Vector2.ONE
const SCALE_SQUASHED := SCALE_BASE * Vector2(1.25, 0.5)
const SCALE_STRETCHED := SCALE_BASE * Vector2(0.8, 1.35)
const ANIM_IN_DURATION := 0.1
const ANIM_OUT_DURATION := 0.25

const MAX_SPEED := 600.0
const JUMP_SPEED := 2000.0
const GRAVITY := 4500.0
const ACCELERATION := 4500.0
const DRAG_AMOUNT := 0.2

var color := Color.white setget _set_color
var state: int = States.ON_GROUND

var velocity := Vector2.ZERO
var direction := Vector2.ZERO
var username := "" setget _set_username

var last_position := Vector2.ZERO
var last_input := 0.0
var next_position := Vector2.ZERO
var next_input := 0.0
var next_jump := false

onready var tween := $Tween
onready var sprite := $Sprite
onready var id_label := $CenterContainer/Label
onready var last_collision_layer := collision_layer
onready var last_collision_mask := collision_mask


func _physics_process(delta: float) -> void:
	move(delta)

	match state:
		States.ON_GROUND:
			if not is_on_floor():
				state = States.IN_AIR
				stretch()
		States.IN_AIR:
			if is_on_floor():
				state = States.ON_GROUND
				squash()


func move(delta: float) -> void:
	var accel := ACCELERATION * direction
	velocity += accel * delta
	velocity.x = clamp(velocity.x, -MAX_SPEED, MAX_SPEED)
	if direction.x == 0:
		velocity.x = lerp(velocity.x, 0, DRAG_AMOUNT)
	velocity.y += GRAVITY * delta
	velocity = move_and_slide(velocity, Vector2.UP)


func jump() -> void:
	stretch()
	velocity.y -= JUMP_SPEED
	state = States.IN_AIR


func stretch() -> void:
	tween.interpolate_property(
		sprite,
		"scale",
		scale,
		SCALE_STRETCHED,
		ANIM_IN_DURATION,
		Tween.TRANS_LINEAR,
		Tween.EASE_OUT
	)
	tween.interpolate_property(
		sprite,
		"scale",
		SCALE_STRETCHED,
		SCALE_BASE,
		ANIM_OUT_DURATION,
		Tween.TRANS_LINEAR,
		Tween.EASE_OUT,
		ANIM_IN_DURATION
	)
	tween.start()


func squash() -> void:
	tween.interpolate_property(
		sprite, "scale", scale, SCALE_SQUASHED, ANIM_IN_DURATION, Tween.TRANS_LINEAR, Tween.EASE_OUT
	)
	tween.interpolate_property(
		sprite,
		"scale",
		SCALE_SQUASHED,
		SCALE_BASE,
		ANIM_IN_DURATION,
		Tween.TRANS_LINEAR,
		Tween.EASE_OUT,
		ANIM_IN_DURATION
	)
	tween.start()


func spawn() -> void:
	tween.interpolate_property(
		sprite, "scale", Vector2.ZERO, SCALE_BASE, 0.75, Tween.TRANS_ELASTIC, Tween.EASE_OUT
	)
	tween.start()
	yield(tween, "tween_all_completed")
	emit_signal("spawned")


func despawn() -> void:
	tween.interpolate_property(
		self, "scale", scale, Vector2.ZERO, 1.0, Tween.TRANS_ELASTIC, Tween.EASE_IN
	)
	tween.start()
	yield(tween, "tween_all_completed")
	queue_free()


func update_state() -> void:
	if next_jump:
		jump()
		next_jump = false

	if global_position.distance_squared_to(last_position) > 10000:
		tween.interpolate_property(self, "global_position", global_position, last_position, 0.2)
		tween.start()
	else:
		var anticipated := last_position + velocity * 0.2
		tween.interpolate_method(self, "do_state_update_move", global_position, anticipated, 0.2)
		tween.start()

	direction.x = last_input

	last_input = next_input
	last_position = next_position


func do_hide() -> void:
	collision_layer = 0
	collision_mask = 0
	hide()


func do_show() -> void:
	collision_layer = last_collision_layer
	collision_mask = last_collision_mask
	show()


func _set_username(value: String) -> void:
	username = value
	id_label.text = username


func _set_color(value: Color) -> void:
	color = value
	if not is_inside_tree():
		yield(self, "ready")
	sprite.modulate = color


func do_state_update_move(new_position: Vector2) -> void:
	var distance := new_position - global_position
	# warning-ignore:return_value_discarded
	move_and_slide(distance, Vector2.UP)
