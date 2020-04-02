extends Character


var input_locked := false
var accel := Vector2.ZERO
var last_direction := Vector2.ZERO


func _ready() -> void:
	$Timer.connect("timeout", self, "_on_Timer_timeout")


func _physics_process(_delta: float) -> void:
	direction = _get_direction()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("jump") and not input_locked:
		jump()


func spawn() -> void:
	input_locked = true
	.spawn()
	yield(self, "spawned")
	input_locked = false


func _get_direction() -> Vector2:
	if input_locked:
		return Vector2.ZERO
	var new_direction := Vector2(Input.get_action_strength("move_right") - Input.get_action_strength("move_left"), 0)
	if new_direction != last_direction:
		emit_signal("direction_changed", new_direction)
		last_direction = new_direction
	return new_direction


func _on_Timer_timeout() -> void:
	if (global_position - last_position).length_squared() != 0:
		Connection.send_position_update(global_position)
		last_position = global_position
