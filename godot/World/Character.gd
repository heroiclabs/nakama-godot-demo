class_name Character
extends KinematicBody2D

signal spawned

const TRUE_SCALE := Vector2.ONE
const SQUASHED_SCALE := TRUE_SCALE * Vector2(1, 0.5)
const STRETCHED_SCALE := TRUE_SCALE * Vector2(1, 1.25)
const SQUASH_TIME := 0.1
const DRAG_AMOUNT := 0.2
const GRAVITY := 4500.0
const ACCELERATION := 4500.0
const MAX_SPEED := 600.0
const JUMP_SPEED := 2000.0
const FLOOR_HEIGHT := 463.15

export var color := Color.white

var velocity := Vector2.ZERO
var moving := false
var falling := false
var direction := Vector2.ZERO
var username: String setget _set_username

var last_position := Vector2.ZERO
var last_input := 0.0
var next_position := Vector2.ZERO
var next_input := 0.0
var next_jump := false

onready var tween := $Tween
onready var sprite := $Sprite
onready var id_label := $CenterContainer/Label


func _ready() -> void:
	sprite.modulate = color


func _physics_process(delta: float) -> void:
	move(delta)
	velocity.y += GRAVITY * delta
	velocity = move_and_slide(velocity, Vector2.UP)
	if falling and is_on_floor():
		falling = false
		squash()
	if not falling and not is_on_floor():
		falling = true
		stretch()


func move(delta: float) -> void:
	var accel := ACCELERATION * direction
	velocity += accel * delta
	velocity.x = clamp(velocity.x, -MAX_SPEED, MAX_SPEED)
	if direction.x == 0:
		velocity.x = lerp(velocity.x, 0, DRAG_AMOUNT)


func update_position_to(new_position: Vector2) -> void:
	tween.interpolate_property(self, "global_position", global_position, new_position, 0.2)
	tween.start()


func jump() -> void:
	if is_on_floor():
		stretch()
		velocity.y -= JUMP_SPEED
		falling = true


func stretch() -> void:
	tween.interpolate_property(sprite, "scale", scale, STRETCHED_SCALE, SQUASH_TIME, Tween.TRANS_LINEAR, Tween.EASE_OUT)
	tween.start()


func squash() -> void:
	tween.interpolate_property(sprite, "scale", scale, SQUASHED_SCALE, SQUASH_TIME, Tween.TRANS_LINEAR, Tween.EASE_OUT)
	tween.interpolate_property(sprite, "scale", SQUASHED_SCALE, TRUE_SCALE, SQUASH_TIME, Tween.TRANS_LINEAR, Tween.EASE_OUT, SQUASH_TIME)
	tween.start()


func spawn() -> void:
	tween.interpolate_property(self, "scale", Vector2.ZERO, TRUE_SCALE, 0.75, Tween.TRANS_ELASTIC, Tween.EASE_OUT)
	tween.start()
	yield(tween, "tween_all_completed")
	emit_signal("spawned")


func despawn() -> void:
	tween.interpolate_property(self, "scale", scale, Vector2.ZERO, 1.0, Tween.TRANS_ELASTIC, Tween.EASE_IN)
	tween.start()
	yield(tween, "tween_all_completed")
	queue_free()


func update_state() -> void:
	if next_jump:
		jump()
	
	if global_position.distance_squared_to(last_position) > 625:
		var anticipated := last_position + velocity * 0.1
		anticipated.y = min(anticipated.y, FLOOR_HEIGHT)
		tween.interpolate_property(self, "global_position", global_position, anticipated, 0.1)
		tween.start()
	
	next_jump = false
	direction.x = last_input
	
	last_input = next_input
	last_position = next_position


func _set_username(value: String) -> void:
	username = value
	id_label.text = username
