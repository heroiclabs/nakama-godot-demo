# Extended character that is controlled by the user and does not respond to
# server events. Intead, it sends some of its own to notify the server of certain
# inputs.
class_name Player
extends Character


var input_locked := false
var accel := Vector2.ZERO
var last_direction := Vector2.ZERO

onready var timer := $Timer


func _ready() -> void:
	#warning-ignore: return_value_discarded
	timer.connect("timeout", self, "_on_Timer_timeout")


func _physics_process(_delta: float) -> void:
	direction = _get_direction()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("jump") and state == States.ON_GROUND:
		jump()
		ServerConnection.send_jump()


func setup(username: String, color: Color, position: Vector2) -> void:
	self.username = username
	self.color = color
	global_position = position
	spawn()


func spawn() -> void:
	set_process_unhandled_input(false)
	.spawn()
	yield(self, "spawned")
	set_process_unhandled_input(true)


func _get_direction() -> Vector2:
	if not is_processing_unhandled_input():
		return Vector2.ZERO

	var new_direction := Vector2(
		Input.get_action_strength("move_right") - Input.get_action_strength("move_left"), 0
	)
	if new_direction != last_direction:
		ServerConnection.send_direction_update(new_direction.x)
		last_direction = new_direction
	return new_direction


func _on_Timer_timeout() -> void:
	ServerConnection.send_position_update(global_position)
